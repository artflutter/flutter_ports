// Original code, not ported from Chart.js: the DartPad archives of the docs.

/// Writes one DartPad archive for each sample of the docs site: each file of
/// `lib/examples` and `lib/migrate` with a `main` function.
///
/// `lib/<path>.dart` becomes `<out_dir>/<path>.tar.gz` with two files:
/// `lib/main.dart`, the sample as one file, and `pubspec.yaml`. The sample
/// keeps line 1 of its header and loses its region markers. The declarations
/// that it uses from other files of the docs app (the kits and the data of
/// the replicas) come after its code, with the imports that they need.
/// DartPad gets the packages from pub.dev, at the versions of their pubspecs
/// in the repository or later.
///
/// Usage, from `apps/chartjs_docs`:
/// `dart tool/dartpad_archives.dart <out_dir>`.
library;

import 'dart:io';

/// The docs site. DartPad has no asset files: a sample reads them here.
const String docsSite = 'https://artflutter.github.io/flutter_ports/docs';

const String _docsPackage = 'package:chartjs_docs/';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('usage: dart tool/dartpad_archives.dart <out_dir>');
    exit(2);
  }
  final docs = File.fromUri(Platform.script).parent.parent;
  final out = Directory(args.single)..createSync(recursive: true);
  final versions = PackageVersions.read(docs);
  final work = Directory.systemTemp.createTempSync('dartpad_archives');
  try {
    final paths = samplePaths(docs);
    for (final path in paths) {
      final rel = path.substring(4, path.length - '.dart'.length);
      final source = bundle(docs, path);
      final project = Directory('${work.path}/$rel');
      final main = File('${project.path}/lib/main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(source);
      File('${project.path}/pubspec.yaml')
          .writeAsStringSync(pubspec(source, versions));
      await _run('dart', ['format', main.path]);
      final archive = File('${out.path}/$rel.tar.gz')
        ..parent.createSync(recursive: true);
      await _run(
        'tar',
        [
          '-czf',
          archive.absolute.path,
          '-C',
          project.path,
          'pubspec.yaml',
          'lib/main.dart',
        ],
        // Keeps the macOS tar from adding ._ files.
        environment: {'COPYFILE_DISABLE': '1'},
      );
    }
    if (paths.isEmpty) throw StateError('no sample with a main function');
    stdout.writeln(
      '${paths.length} archives, flutter_chartjs_port ^${versions.port}.',
    );
  } finally {
    work.deleteSync(recursive: true);
  }
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  Map<String, String>? environment,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    environment: environment,
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      '${result.stdout}${result.stderr}',
      result.exitCode,
    );
  }
}

/// The sample files of [docs], relative to it and sorted: each file of
/// `lib/examples` and `lib/migrate` with a `main` function.
List<String> samplePaths(Directory docs) => [
  for (final folder in ['lib/examples', 'lib/migrate'])
    for (final file
        in Directory('${docs.path}/$folder')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      if (file.readAsStringSync().contains('\nvoid main() {'))
        file.path.substring(docs.path.length + 1),
];

/// The versions of the packages that a sample can import.
final class PackageVersions._({
  /// The version of `flutter_chartjs_port`.
  required final String port,

  /// The version of `flutter_chartjs_plugin_zoom_port`.
  required final String zoom,

  /// The lower bound of `material_ui` in the pubspec of the docs app.
  required final String materialUi,
}) {
  /// The versions of the pubspecs of the repository around [docs].
  factory read(Directory docs) {
    String version(String pubspec) => RegExp(
      r'^version: (\S+)$',
      multiLine: true,
    ).firstMatch(File(pubspec).readAsStringSync())![1]!;
    final materialUi = RegExp(
      r'^  material_ui: \^(\S+)$',
      multiLine: true,
    ).firstMatch(File('${docs.path}/pubspec.yaml').readAsStringSync())![1]!;
    final packages = '${docs.path}/../../packages';
    return PackageVersions._(
      port: version('$packages/flutter_chartjs_port/pubspec.yaml'),
      zoom: version('$packages/flutter_chartjs_plugin_zoom_port/pubspec.yaml'),
      materialUi: materialUi,
    );
  }

  /// The version of [package], or null for a package with no entry.
  String? of(String package) => switch (package) {
    'flutter_chartjs_port' => port,
    'flutter_chartjs_plugin_zoom_port' => zoom,
    'material_ui' => materialUi,
    _ => null,
  };
}

/// The pubspec of the bundled [source]: Flutter and each package that it
/// imports, from pub.dev.
String pubspec(String source, PackageVersions versions) {
  final packages = {
    for (final match in RegExp(
      r"^import 'package:(\w+)/",
      multiLine: true,
    ).allMatches(source))
      match[1]!,
  }..remove('flutter');
  String version(String package) =>
      versions.of(package) ??
      (throw StateError('no version of package:$package'));
  final dependencies = [
    for (final package in packages.toList()..sort())
      '  $package: ^${version(package)}',
  ];
  return [
    'name: chartjs_sample',
    'publish_to: none',
    '',
    'environment:',
    '  sdk: ^3.13.0',
    '  flutter: ">=3.47.0"',
    '',
    'dependencies:',
    '  flutter:',
    '    sdk: flutter',
    ...dependencies,
    '',
  ].join('\n');
}

/// The sample [path] of [docs] as one file: its code, then the declarations
/// that it uses from the files of the docs app that it imports.
String bundle(Directory docs, String path) {
  final sample = DartFile.read(docs, path);
  // The files of the docs app that the sample reaches through its imports.
  final libraries = <DartFile>[];
  final queue = [...sample.docsImports];
  final seen = <String>{};
  while (queue.isNotEmpty) {
    final next = queue.removeAt(0);
    if (!seen.add(next)) continue;
    final file = DartFile.read(docs, next);
    libraries.add(file);
    queue.addAll(file.docsImports);
  }
  final own = {for (final unit in sample.declarations) unit.name};
  final declarations = <String, Unit>{};
  for (final file in libraries) {
    for (final unit in file.declarations) {
      final name = unit.name!;
      if (own.contains(name) || declarations.containsKey(name)) {
        throw StateError('$path: two declarations of $name');
      }
      declarations[name] = unit;
    }
  }
  final used = {for (final unit in sample.declarations) ...unit.identifiers};
  final included = <Unit>{};
  for (var grew = true; grew;) {
    grew = false;
    for (final MapEntry(key: name, value: unit) in declarations.entries) {
      if (!included.contains(unit) && used.contains(name)) {
        included.add(unit);
        used.addAll(unit.identifiers);
        grew = true;
      }
    }
  }

  // The imports of the sample, then the ones of the included declarations
  // that their code uses.
  final imports = <String>{...sample.packageImports};
  for (final file in libraries) {
    if (!file.declarations.any(included.contains)) continue;
    for (final directive in file.packageImports) {
      if (imports.contains(directive)) continue;
      final prefix = RegExp(r' as (\w+)').firstMatch(directive)?[1];
      final shown = RegExp(r' show ([\w, ]+)').firstMatch(directive)?[1];
      final needed = prefix != null
          ? used.contains(prefix)
          : shown == null ||
                shown.split(',').any((name) => used.contains(name.trim()));
      if (needed) imports.add(directive);
    }
  }
  final dartImports = imports.where((i) => i.contains("'dart:")).toList()
    ..sort();
  final packageImports = imports.where((i) => !i.contains("'dart:")).toList()
    ..sort();

  final out = StringBuffer()
    ..writeln(sample.text.split('\n').first)
    ..writeln();
  if (dartImports.isNotEmpty) {
    out
      ..writeln(dartImports.join('\n'))
      ..writeln();
  }
  out.writeln(packageImports.join('\n'));
  // Each unit holds the white space before it.
  for (final unit in sample.declarations) {
    out.write(unit.cleanText);
  }
  for (final file in libraries) {
    final units = file.declarations.where(included.contains).toList();
    if (units.isEmpty) continue;
    out.write('\n\n// The code that this sample uses from ${file.path}.\n');
    for (final unit in units) {
      out.write(unit.cleanText);
    }
  }
  out.writeln();
  return out
      .toString()
      .replaceAll(
        'rootBundle.loadString(',
        "NetworkAssetBundle(Uri.parse('$docsSite/assets/')).loadString(",
      )
      .replaceAll(RegExp(r'\n{3,}'), '\n\n');
}

/// A Dart file of the docs app, split into its top-level units.
final class DartFile._(
  /// The path of the file, relative to the docs app.
  final String path,

  /// The text of the file.
  final String text,

  /// The top-level units of the file, in order.
  final List<Unit> units,
) {
  /// Reads the file [path] of [docs], relative to it.
  factory read(Directory docs, String path) {
    final text = File('${docs.path}/$path').readAsStringSync();
    return DartFile._(path, text, [
      for (final unit in splitUnits(text)) Unit(unit),
    ]);
  }

  /// The declarations of the file, in order.
  Iterable<Unit> get declarations => units.where((unit) => unit.name != null);

  /// The paths of the files of the docs app that the file imports.
  Iterable<String> get docsImports => [
    for (final unit in units)
      if (unit.importUri case final uri? when uri.startsWith(_docsPackage))
        'lib/${uri.substring(_docsPackage.length)}',
  ];

  /// The import directives of the file, other than of the docs app, on one
  /// line each.
  Iterable<String> get packageImports => [
    for (final unit in units)
      if (unit.importUri case final uri? when !uri.startsWith(_docsPackage))
        unit.code.replaceAll(RegExp(r'\s+'), ' '),
  ];
}

/// A top-level unit of a Dart file: a directive or a declaration, with the
/// comments above it, or the comments at the end of the file.
final class Unit(
  /// The text of the unit.
  final String text,
) {
  /// Classifies the unit [text].
  this {
    final words = code.replaceFirst(_annotations, '');
    if (code.isEmpty ||
        RegExp(r'^(import|export|library|part)\b').hasMatch(code)) {
      name = null;
    } else if (RegExp(r'^extension\b(?!\s+type)').hasMatch(words)) {
      throw UnsupportedError('an extension is not bundled: $words');
    } else {
      name =
          (_typeName.firstMatch(words) ?? _typedefName.firstMatch(words))?[1] ??
          _memberName(words);
    }
    _scanCode(code, 0, identifiers);
  }

  static final _annotations = RegExp(r'^(@[\w.]+(\([^)]*\))?\s*)*');
  static final _typeName = RegExp(
    r'^(?:(?:abstract|final|sealed|base|interface|mixin)\s+)*'
    r'(?:class|enum|mixin|extension\s+type)\s+(?:const\s+)?([\w$]+)',
  );
  static final _typedefName = RegExp(r'^typedef\s+([\w$]+)');

  /// The text without the comments and the white space before the code.
  final String code = _code(text);

  /// The name of the declaration, or null for a directive or a comment.
  late final String? name;

  /// The identifiers of the code and of its string interpolations.
  final Set<String> identifiers = {};

  /// The URI of an import directive, or null.
  String? get importUri => RegExp("^import '([^']+)'").firstMatch(code)?[1];

  /// The text without the region markers and the `ignore_for_file` lines.
  String get cleanText => text
      .split('\n')
      .where(
        (line) =>
            !RegExp(r'^\s*// (#(end)?docregion |ignore_for_file:)')
                .hasMatch(line),
      )
      .join('\n');

  static String _code(String text) {
    var i = 0;
    while (i < text.length) {
      if (text[i].trim().isEmpty) {
        i++;
        continue;
      }
      final skipped = _skipNonCode(text, i, null);
      if (skipped == i || !text.startsWith('/', i)) break;
      i = skipped;
    }
    return text.substring(i);
  }

  /// The name of a function, a getter, a setter or a variable: the last
  /// identifier of its header outside of parentheses and type arguments.
  static String? _memberName(String code) {
    String? last;
    var depth = 0;
    for (var i = 0; i < code.length; i++) {
      final c = code[i];
      if (c == '(' && depth == 0 && last != null && _endsWithName(code, i)) {
        return last;
      }
      if (c == '(' || c == '[' || c == '<') {
        depth++;
      } else if (c == ')' || c == ']' || c == '>') {
        depth--;
      } else if (depth == 0 && (c == '=' || c == ';' || c == '{')) {
        return last;
      } else if (depth == 0 && _identifierStart.hasMatch(c)) {
        final match = _identifier.matchAsPrefix(code, i)!;
        last = match[0];
        i = match.end - 1;
      }
    }
    return last;
  }

  /// Whether an identifier comes right before the parenthesis at [i].
  static bool _endsWithName(String code, int i) {
    var j = i - 1;
    while (j >= 0 && code[j].trim().isEmpty) {
      j--;
    }
    return j >= 0 && _identifierPart.hasMatch(code[j]);
  }
}

final _identifier = RegExp(r'[A-Za-z_$][\w$]*');
final _identifierStart = RegExp(r'[A-Za-z_$]');
final _identifierPart = RegExp(r'[\w$]');

/// The top-level units of the Dart source [s]: each ends at a `;` or at the
/// `}` of a body, outside of brackets, comments and strings. A unit holds the
/// comments and the white space before it.
List<String> splitUnits(String s) {
  final units = <String>[];
  var depth = 0;
  var start = 0;
  // A `=` or a `=>` of the unit outside brackets: then a `}` does not end
  // it, its `;` does.
  var assigned = false;
  var i = 0;
  while (i < s.length) {
    final skipped = _skipNonCode(s, i, null);
    if (skipped != i) {
      i = skipped;
      continue;
    }
    final c = s[i];
    if (c == '{' || c == '(' || c == '[') {
      depth++;
    } else if (c == '}' || c == ')' || c == ']') {
      depth--;
      if (depth == 0 && c == '}' && !assigned) {
        units.add(s.substring(start, i + 1));
        start = i + 1;
      }
    } else if (depth == 0 && c == ';') {
      units.add(s.substring(start, i + 1));
      start = i + 1;
      assigned = false;
    } else if (depth == 0 && c == '=') {
      final next = i + 1 < s.length ? s[i + 1] : '';
      final previous = i > 0 ? s[i - 1] : '';
      if (next != '=' && !'=!<>'.contains(previous)) {
        assigned = true;
      }
    }
    i++;
  }
  if (s.substring(start).trim().isNotEmpty) units.add(s.substring(start));
  return units;
}

/// The index after the comment or the string literal at [i] of [s], or [i]
/// when none starts there. Adds the identifiers of the string
/// interpolations to [identifiers].
int _skipNonCode(String s, int i, Set<String>? identifiers) {
  if (s.startsWith('//', i)) {
    final end = s.indexOf('\n', i);
    return end < 0 ? s.length : end;
  }
  if (s.startsWith('/*', i)) {
    var depth = 0;
    var j = i;
    while (j < s.length) {
      if (s.startsWith('/*', j)) {
        depth++;
        j += 2;
      } else if (s.startsWith('*/', j)) {
        depth--;
        j += 2;
        if (depth == 0) return j;
      } else {
        j++;
      }
    }
    return s.length;
  }
  var j = i;
  var raw = false;
  if (s[j] == 'r' &&
      j + 1 < s.length &&
      (s[j + 1] == "'" || s[j + 1] == '"') &&
      (j == 0 || !_identifierPart.hasMatch(s[j - 1]))) {
    raw = true;
    j++;
  }
  if (s[j] != "'" && s[j] != '"') return i;
  final quote = s[j];
  final close = s.startsWith(quote * 3, j) ? quote * 3 : quote;
  j += close.length;
  while (j < s.length) {
    if (s.startsWith(close, j)) return j + close.length;
    final c = s[j];
    if (!raw && c == r'\') {
      j += 2;
    } else if (!raw && c == r'$' && j + 1 < s.length && s[j + 1] == '{') {
      j = _scanCode(s, j + 2, identifiers ?? {}, closingBrace: true);
    } else if (!raw && c == r'$') {
      final match = RegExp(r'[A-Za-z_][\w]*').matchAsPrefix(s, j + 1);
      if (match != null) identifiers?.add(match[0]!);
      j = match?.end ?? j + 1;
    } else {
      j++;
    }
  }
  return s.length;
}

/// Adds the identifiers of the code of [s] from [i] to [identifiers], and
/// returns the index where it stops: the end of [s], or with [closingBrace]
/// the index after the `}` that closes the code.
int _scanCode(
  String s,
  int i,
  Set<String> identifiers, {
  bool closingBrace = false,
}) {
  var depth = 0;
  var j = i;
  while (j < s.length) {
    final skipped = _skipNonCode(s, j, identifiers);
    if (skipped != j) {
      j = skipped;
      continue;
    }
    final c = s[j];
    if (c == '{') {
      depth++;
    } else if (c == '}') {
      if (closingBrace && depth == 0) return j + 1;
      depth--;
    } else if (_identifierStart.hasMatch(c) &&
        (j == 0 || !_identifierPart.hasMatch(s[j - 1]))) {
      final match = _identifier.matchAsPrefix(s, j)!;
      identifiers.add(match[0]!);
      j = match.end;
      continue;
    }
    j++;
  }
  return j;
}
