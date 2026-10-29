// Original code, not ported from Chart.js: the JS-semantics check, tool 3.

/// The JS-semantics check of porting-flow.md section 4, tool 3.
///
/// It flags Dart calls and operators whose results differ from the
/// JavaScript that a ported file translates (Chart.js ADR 0045). It examines
/// the files whose header block names a `js` project of
/// `tool/port_sources.yaml`, or a project that the file does not list. A site
/// passes with a `// js-ok: <reason>` comment at the end of its line, or with
/// a `// js-ok: <reason>` line directly before it.
///
/// The lexical rules read code with comments and string contents removed.
/// They do not know types. Thus they flag every `.toString()` call: add
/// `js-ok` when the receiver is not a number. Only the interpolation rule,
/// the tear-off rule of the `dart:math` functions and the `max`/`min` rule
/// resolve types, with `package:analyzer`.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
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

/// The lexical rules of the check. [mathFunctionSites] and [resolvedSites]
/// add four more rules.
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
    'pow returns an int for int operands, and the int can overflow; JS '
        'Math.pow computes with doubles. Pass double operands and add js-ok '
        'with the reason (Chart.js ADR 0045).',
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
  // The sorts of package:collection (Chart.js ADR 0045, Sort). A type
  // argument can come before the argument list.
  JsSemanticsRule(
    'mergeSort(',
    r'\bmergeSort' + _typeArguments,
    _stableCollectionSort,
  ),
  JsSemanticsRule(
    'insertionSort(',
    r'\binsertionSort' + _typeArguments,
    _stableCollectionSort,
  ),
  JsSemanticsRule(
    '.sorted(',
    r'\.sorted' + _typeArguments,
    'sorted calls List.sort, which is not stable on the VM, in dart2wasm '
        'and in DDC; Array.prototype.sort is (Chart.js ADR 0045, Sort). Use '
        'jsSort.',
  ),
  JsSemanticsRule(
    '.sortedBy(',
    r'\.sortedBy' + _typeArguments,
    _stableCollectionSort,
  ),
  JsSemanticsRule(
    '.sortedByCompare(',
    r'\.sortedByCompare' + _typeArguments,
    _stableCollectionSort,
  ),
  JsSemanticsRule(
    '.sortBy(',
    r'\.sortBy' + _typeArguments,
    _quickSortCollectionSort,
  ),
  JsSemanticsRule(
    '.sortByCompare(',
    r'\.sortByCompare' + _typeArguments,
    _quickSortCollectionSort,
  ),
  JsSemanticsRule(
    '.sortRange(',
    r'\.sortRange' + _typeArguments,
    _quickSortCollectionSort,
  ),
  // The clock of Date.now() from phase 5 (Chart.js ADR 0045, section 6).
  JsSemanticsRule(
    'DateTime.now(',
    r'\bDateTime\s*\.\s*now\s*\(',
    'DateTime.now() reads the system clock: FakeAsync and withClock do not '
        'move it, so animations do not run in fake time. Use jsDateNow, '
        'which reads clock.now() (Chart.js ADR 0045, section 6).',
  ),
];

/// The optional type arguments and the opening parenthesis after the name of
/// a package:collection sort. The type arguments nest one level, as in
/// `sortedBy<int Function()>(`, and stay inside one statement.
const String _typeArguments = r'\s*(?:<(?:[^<>;{}]|<[^<>;{}]*>)*>)?\s*\(';

const String _stableCollectionSort =
    'this package:collection sort is stable, but it does not change the '
    'comparator result to its sign, with NaN as 0, as Array.prototype.sort '
    'does (Chart.js ADR 0045, Sort). Use jsSort.';

const String _quickSortCollectionSort =
    'this package:collection sort calls quickSortBy, which is not stable; '
    'Array.prototype.sort is (Chart.js ADR 0045, Sort). Use jsSort.';

/// The `dart:math` functions whose results differ from the JS `Math`
/// builtins of the reference engine. `pow` has its own rule.
///
/// `sin` and `cos` are in the list: at a site whose result reaches a
/// layout, a scale, an element property or a hit test, ported code calls
/// `jsSin` and `jsCos`. A display-only site keeps `dart:math` with js-ok
/// (Chart.js ADR 0045).
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

/// The [transcendentalFunctions] with a display-only exception (Chart.js ADR
/// 0045).
const Set<String> _trigFunctions = {'sin', 'cos'};

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
/// it flags the bare function names. [resolvedSites] flags the tear-offs.
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
          _mathFunctionMessage(function),
        ),
      );
    }
  }
  return sites;
}

/// The message of a site of the `dart:math` [function], one of the
/// [transcendentalFunctions].
String _mathFunctionMessage(String function) =>
    _trigFunctions.contains(
      function,
    )
    ? 'dart:math $function calls the host C library on the VM and the '
          'browser on the web. JS Math.$function gives the fdlibm bits of the '
          'reference engine (Chart.js ADR 0045). Call '
          'js${function[0].toUpperCase()}${function.substring(1)}, or add '
          'js-ok when the result reaches only the canvas or an easing value.'
    : 'dart:math $function calls the host C library on the VM and the '
          'browser on the web. JS Math.$function gives the fdlibm bits of the '
          'reference engine (Chart.js ADR 0045). Call the lib/src/js port of '
          'the function, or add js-ok with the reason.';

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
/// [typedSites] are the sites of [resolvedSites] for the file.
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

/// The rules that resolve types, for [files] (absolute paths), by file. A
/// file that does not resolve is not in the result.
///
/// The interpolation rule flags the `${...}` and `$name` interpolations of a
/// `double` or `num` value. Dart writes such a value with `double.toString`,
/// for example `"12.0"` on the VM and on dart2wasm. JS `'' + 12` and
/// template literals give `"12"`. An `int` value is not flagged: ported code
/// uses an `int` only as a list index, and its text is the JS text.
///
/// The tear-off rule flags each tear-off of the [transcendentalFunctions] of
/// `dart:math`, with or without the import prefix, for example `math.sin` or
/// `list.map(cos)`. [mathFunctionSites] flags the calls.
///
/// The `max`/`min` rule flags the calls and tear-offs of `dart:math` `max`
/// and `min` whose type argument is `double` or `num`. Ported code calls
/// `jsMax` and `jsMin` for them (Chart.js ADR 0045): on dart2wasm, the
/// generic functions box their `double` operands. The rule does not flag an
/// `int` type argument.
Future<Map<String, List<JsSite>>> resolvedSites(
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
      final visitor = _ResolvedSitesVisitor(unit);
      unit.unit.accept(visitor);
      result[file] = visitor.sites;
    }
  } finally {
    await collection.dispose();
  }
  return result;
}

final class _ResolvedSitesVisitor extends RecursiveAstVisitor<void> {
  _ResolvedSitesVisitor(this.unit);

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

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    _addMathTearOff(node, element);
    if (element is TopLevelFunctionElement &&
        element.library.uri.toString() == 'dart:math' &&
        (element.name == 'max' || element.name == 'min')) {
      final parent = node.parent;
      // A call gives its instantiated return type. A tear-off, with or
      // without the import prefix, sits in a FunctionReference that gives
      // its instantiated function type.
      final DartType? type;
      if (parent is MethodInvocation && parent.methodName == node) {
        type = parent.staticType;
      } else {
        final Expression expression = parent is PrefixedIdentifier
            ? parent
            : node;
        final reference = expression.parent;
        final function = reference is FunctionReference
            ? reference.staticType
            : expression.staticType;
        type = function is FunctionType ? function.returnType : null;
      }
      if (_isNumber(type)) {
        final name = element.name!;
        final js = name == 'max' ? 'jsMax' : 'jsMin';
        sites.add(
          JsSite(
            unit.lineInfo.getLocation(node.offset).lineNumber,
            '$name(',
            'dart:math $name with ${type!.getDisplayString()} operands '
                'boxes them on dart2wasm. Call $js from '
                'lib/src/js/js_math.dart (Chart.js ADR 0045), or add js-ok '
                'with the reason.',
          ),
        );
      }
    }
    super.visitSimpleIdentifier(node);
  }

  /// Adds a site when [node] tears off one of the [transcendentalFunctions]
  /// of `dart:math`. A call is a site of [mathFunctionSites]. The name in a
  /// `show` or `hide` combinator and a doc comment reference are no sites.
  void _addMathTearOff(SimpleIdentifier node, Element? element) {
    if (element is! TopLevelFunctionElement ||
        element.library.uri.toString() != 'dart:math' ||
        !transcendentalFunctions.contains(element.name)) {
      return;
    }
    final parent = node.parent;
    if ((parent is MethodInvocation && parent.methodName == node) ||
        parent is Combinator ||
        node.thisOrAncestorOfType<CommentReference>() != null) {
      return;
    }
    final prefix = parent is PrefixedIdentifier && parent.identifier == node
        ? '${parent.prefix.name}.'
        : '';
    final function = element.name!;
    sites.add(
      JsSite(
        unit.lineInfo.getLocation(node.offset).lineNumber,
        '$prefix$function',
        'The tear-off of ${_mathFunctionMessage(function)}',
      ),
    );
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
  final typed = await resolvedSites(examined.keys.toList());
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
