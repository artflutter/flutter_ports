// Original code, not ported from Chart.js: the JS-semantics check, tool 3.

/// The JS-semantics check of porting-flow.md section 4, tool 3.
///
/// It flags Dart calls and operators whose results differ from the
/// JavaScript that a ported file translates (Chart.js ADR 0002). It examines
/// the files whose header block names a `js` project of
/// `tool/port_sources.yaml`, or a project that the file does not list. A site
/// passes with a `// js-ok: <reason>` comment at the end of its line, or with
/// a `// js-ok: <reason>` line directly before it.
///
/// The lexical rules read code with comments and string contents removed.
/// They do not know types. Thus they flag every `.toString()` call: add
/// `js-ok` when the receiver is not a number. Only the interpolation rule
/// resolves types, with `package:analyzer`.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

import 'check_support.dart';
import 'dart_source.dart';
import 'headers.dart';
import 'port_headers.dart';

/// One pattern of the check.
final class JsSemanticsRule {
  /// A rule that flags [pattern] with [message].
  const JsSemanticsRule(this.name, this.pattern, this.message);

  /// The short name of the flagged construct.
  final String name;

  /// The pattern, applied to the code without comments and strings.
  final String pattern;

  /// Why the construct differs from JavaScript, and what to use.
  final String message;
}

/// The lexical rules of the check. [mathFunctionSites] and
/// [numberInterpolationSites] add two more rules.
const List<JsSemanticsRule> jsSemanticsRules = [
  JsSemanticsRule(
    '.round()',
    r'\.round\(\)',
    'Dart round() returns an int, rounds halves away from zero and throws '
        'on NaN and infinities; JS Math.round rounds halves up. Use jsRound.',
  ),
  JsSemanticsRule(
    '.roundToDouble()',
    r'\.roundToDouble\(\)',
    'roundToDouble() rounds halves away from zero; JS Math.round rounds '
        'halves up. Use jsRound.',
  ),
  JsSemanticsRule(
    '.floor()',
    r'\.floor\(\)',
    'Dart floor() returns an int and throws on NaN and infinities. Use '
        'floorToDouble().',
  ),
  JsSemanticsRule(
    '.ceil()',
    r'\.ceil\(\)',
    'Dart ceil() returns an int and throws on NaN and infinities. Use '
        'ceilToDouble().',
  ),
  JsSemanticsRule(
    '.truncate()',
    r'\.truncate\(\)',
    'Dart truncate() returns an int and throws on NaN and infinities. Use '
        'truncateToDouble().',
  ),
  JsSemanticsRule(
    '.clamp(',
    r'\.clamp\(',
    'num.clamp throws for reversed bounds and orders NaN and -0.0 another '
        'way than Math.max(min, Math.min(max, value)). Port _limitValue.',
  ),
  JsSemanticsRule(
    '%',
    '%',
    'Dart % is the Euclidean modulo; JS % is the remainder, with the sign '
        'of the dividend. Use remainder().',
  ),
  JsSemanticsRule(
    'pow(',
    r'\bpow\s*\(',
    'pow gives the JS Math.pow result only for an integer exponent with '
        'double operands (Chart.js ADR 0002). Add js-ok with the reason, or '
        'use jsPow.',
  ),
  JsSemanticsRule(
    '.toString()',
    r'\.toString\(\)',
    'Dart toString() of a number differs from JS String(x), for example '
        '"1.0" and "1". Use the lib/src/js runtime, or add js-ok when the '
        'receiver is not a number.',
  ),
  JsSemanticsRule(
    'is int',
    r'\bis!?\s+int\b',
    'JS numbers are doubles: on the web 1.0 is int, on the VM it is not. Do '
        'not test numbers for int.',
  ),
  JsSemanticsRule(
    '.sort(',
    r'\.sort\(',
    'List.sort is not stable on the VM, in dart2wasm and in DDC; '
        'Array.prototype.sort is. Use jsSort.',
  ),
];

/// The `dart:math` functions whose results differ from the JS `Math`
/// builtins of the reference engine. `pow` has its own rule.
const List<String> transcendentalFunctions = [
  'sin',
  'cos',
  'tan',
  'asin',
  'acos',
  'atan',
  'atan2',
  'exp',
  'log',
];

final RegExp _jsOk = RegExp(r'^//\s*js-ok:(.*)$');
final RegExp _jsOkCandidate = RegExp(r'^///?\s*js-ok\b');

/// The directories of a package that the check examines.
const List<String> jsSemanticsDirectories = ['lib', 'test'];

/// One flagged site.
final class JsSite {
  /// The construct [name] on [line], with [message].
  const JsSite(this.line, this.name, this.message);

  /// The 1-based line.
  final int line;

  /// The short name of the flagged construct.
  final String name;

  /// Why the construct differs from JavaScript, and what to use.
  final String message;
}

/// Whether the check examines a file with [header]. [languages] maps each
/// project of `tool/port_sources.yaml` to its `language`.
///
/// A file is examined when a `// Ported from` line of its header block names
/// a `js` project, or a project that is not in [languages].
bool examinesHeader(Header header, Map<String, String> languages) =>
    header.kind == HeaderKind.ported &&
    header.portedFrom.any(
      (line) => (languages[line.project] ?? jsLanguage) == jsLanguage,
    );

/// The sites of the lexical rules and of the `dart:math` rule in [source].
List<JsSite> lexicalSites(DartSource source) => [
  for (final rule in jsSemanticsRules)
    for (final match in RegExp(rule.pattern).allMatches(source.code))
      JsSite(source.lineOf(match.start), rule.name, rule.message),
  ...mathFunctionSites(source),
];

/// The calls of the [transcendentalFunctions] of `dart:math` in [source].
///
/// The rule reads the prefix of each `dart:math` import. Without a prefix,
/// it flags the bare function names.
List<JsSite> mathFunctionSites(DartSource source) {
  final names = transcendentalFunctions.join('|');
  final sites = <JsSite>[];
  for (final directive in source.directives) {
    if (directive.keyword != 'import' || directive.uris.first != 'dart:math') {
      continue;
    }
    final prefix = directive.prefix;
    final qualifier = prefix == null
        ? ''
        : '${RegExp.escape(prefix)}\\s*\\.\\s*';
    final pattern = RegExp('(?<![\\w\$.])$qualifier($names)\\s*\\(');
    for (final match in pattern.allMatches(source.code)) {
      final function = match.group(1)!;
      sites.add(
        JsSite(
          source.lineOf(match.start),
          '${prefix == null ? '' : '$prefix.'}$function(',
          'dart:math $function calls the host C library on the VM and the '
              'browser on the web. JS Math.$function gives the fdlibm bits '
              'of the reference engine (Chart.js ADR 0002). Call the '
              'lib/src/js port of the function.',
        ),
      );
    }
  }
  return sites;
}

/// Adds a finding for each site in [sites] of the file [path] that has no
/// js-ok comment in [source], and a warning for each unused js-ok comment.
void _reportSites(
  DartSource source,
  String path,
  Iterable<JsSite> sites,
  List<Finding> findings,
) {
  // The lines with a js-ok reason, whether the comment is alone on its line,
  // and whether a site used it.
  final allowed = <int, ({bool alone, bool used})>{};
  for (final comment in source.comments) {
    if (!comment.isLineComment || !_jsOkCandidate.hasMatch(comment.text)) {
      continue;
    }
    final reason = _jsOk.firstMatch(comment.text)?.group(1)?.trim() ?? '';
    if (reason.isEmpty) {
      findings.add(
        Finding(path, comment.line, 'write the site as "// js-ok: <reason>".'),
      );
      continue;
    }
    final lineStart = source.code.lastIndexOf('\n', comment.start) + 1;
    final before = source.code.substring(lineStart, comment.start);
    allowed[comment.line] = (alone: before.trim().isEmpty, used: false);
  }

  bool allow(int line, {required bool alone}) {
    final entry = allowed[line];
    if (entry == null || (alone && !entry.alone)) return false;
    allowed[line] = (alone: entry.alone, used: true);
    return true;
  }

  final seen = <(int, String)>{};
  for (final site in sites) {
    if (!seen.add((site.line, site.name))) continue;
    if (allow(site.line, alone: false) || allow(site.line - 1, alone: true)) {
      continue;
    }
    findings.add(Finding(path, site.line, '${site.name}: ${site.message}'));
  }
  for (final MapEntry(key: line, value: entry) in allowed.entries) {
    if (!entry.used) {
      findings.add(
        Finding.warning(
          path,
          line,
          entry.alone
              ? 'js-ok with no flagged site on the next line.'
              : 'js-ok with no flagged site on this line.',
        ),
      );
    }
  }
}

/// Checks the Dart [text] of the file [path] (as reported) and adds the
/// findings to [findings]. Returns whether the check examines the file
/// ([examinesHeader] with [languages]).
///
/// [typedSites] are the sites of [numberInterpolationSites] for the file.
bool checkJsSemanticsText(
  String text,
  String path,
  List<Finding> findings, {
  required Map<String, String> languages,
  Iterable<JsSite> typedSites = const [],
}) {
  final source = DartSource(text);
  if (!examinesHeader(Header.parse(source.lines), languages)) return false;
  _reportSites(source, path, [
    ...lexicalSites(source),
    ...typedSites,
  ], findings);
  return true;
}

/// The Dart SDK of the running VM, or of `FLUTTER_ROOT` under
/// `flutter test`, or null to let the analyzer find it. The path is
/// absolute and normalized, as the analyzer requires.
String? dartSdkPath() {
  final executable = File(Platform.resolvedExecutable);
  final name = posixPath(executable.path).split('/').last;
  if (name == 'dart' || name == 'dart.exe') {
    return _normalized(executable.parent.parent.path);
  }
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  return flutterRoot == null
      ? null
      : _normalized('$flutterRoot/bin/cache/dart-sdk');
}

/// The absolute, normalized form of [path] for the analyzer, with the
/// separators of the platform.
String _normalized(String path) {
  final context = PhysicalResourceProvider.INSTANCE.pathContext;
  return context.normalize(context.absolute(path));
}

/// The interpolation rule: the `${...}` and `$name` interpolations of a
/// `double` or `num` value in [files] (absolute paths), by file.
///
/// Dart writes such a value with `double.toString`, for example `"12.0"` on
/// the VM and on dart2wasm. JS `'' + 12` and template literals give `"12"`.
/// An `int` value is not flagged: ported code uses an `int` only as a list
/// index, and its text is the JS text. A file that does not resolve is not
/// in the result.
Future<Map<String, List<JsSite>>> numberInterpolationSites(
  List<String> files,
) async {
  if (files.isEmpty) return const {};
  final collection = AnalysisContextCollection(
    includedPaths: [for (final file in files) _normalized(file)],
    sdkPath: dartSdkPath(),
  );
  final result = <String, List<JsSite>>{};
  try {
    for (final file in files) {
      final path = _normalized(file);
      final unit = await collection
          .contextFor(path)
          .currentSession
          .getResolvedUnit(path);
      if (unit is! ResolvedUnitResult) continue;
      final visitor = _InterpolationVisitor(unit);
      unit.unit.accept(visitor);
      result[file] = visitor.sites;
    }
  } finally {
    await collection.dispose();
  }
  return result;
}

final class _InterpolationVisitor extends RecursiveAstVisitor<void> {
  _InterpolationVisitor(this.unit);

  final ResolvedUnitResult unit;
  final List<JsSite> sites = [];

  static bool _isNumber(DartType? type) =>
      type != null && (type.isDartCoreDouble || type.isDartCoreNum);

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    final type = node.expression.staticType;
    if (_isNumber(type)) {
      sites.add(
        JsSite(
          unit.lineInfo.getLocation(node.offset).lineNumber,
          'number interpolation',
          'Dart writes the ${type!.getDisplayString()} with toString(), for '
              'example "12.0" on the VM and dart2wasm; JS String(12) is '
              '"12". Use the lib/src/js runtime (jsNumberToString), or add '
              'js-ok with the reason.',
        ),
      );
    }
    super.visitInterpolationExpression(node);
  }
}

/// Reads the `language` of each project in `tool/port_sources.yaml` of
/// [home]. Adds a finding when the file cannot be read.
Map<String, String> _readLanguages(
  String home,
  String base,
  List<Finding> findings,
) {
  final file = '$home/$portSourcesPath';
  try {
    return {
      for (final source in parsePortSources(File(file).readAsStringSync()))
        source.header: source.language,
    };
  } on FileSystemException catch (e) {
    findings.add(Finding(relativePath(base, file), null, e.message));
  } on FormatException catch (e) {
    findings.add(Finding(relativePath(base, file), null, e.message));
  }
  return const {};
}

/// Runs the check over the `lib/` and `test/` files of [packages]. The first
/// package holds `tool/port_sources.yaml`. The paths in the findings are
/// relative to [base].
Future<({List<Finding> findings, int files})> checkJsSemantics(
  List<String> packages, {
  required String base,
}) async {
  final findings = <Finding>[];
  final languages = _readLanguages(packages.first, base, findings);
  final examined = <String, String>{};
  for (final package in packages) {
    for (final directory in jsSemanticsDirectories) {
      for (final file in dartFilesUnder('$package/$directory')) {
        final text = File(file).readAsStringSync();
        final header = Header.parse(DartSource(text).lines);
        if (examinesHeader(header, languages)) examined[file] = text;
      }
    }
  }
  final typed = await numberInterpolationSites(examined.keys.toList());
  for (final MapEntry(key: file, value: text) in examined.entries) {
    final path = relativePath(base, file);
    final sites = typed[file];
    if (sites == null) {
      findings.add(
        Finding(path, null, 'the analyzer cannot resolve the file.'),
      );
    }
    checkJsSemanticsText(
      text,
      path,
      findings,
      languages: languages,
      typedSites: sites ?? const [],
    );
  }
  findings.sort((a, b) {
    final byPath = a.path.compareTo(b.path);
    return byPath != 0 ? byPath : (a.line ?? 0) - (b.line ?? 0);
  });
  return (findings: findings, files: examined.length);
}
