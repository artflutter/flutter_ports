// Original code, not ported from Chart.js: the command of the schema generator.

/// `dart run packages/flutter_chartjs_port/tool/options_gen.dart`: writes
/// the typed option scopes of `lib/src/options/*.g.dart` from
/// `tool/options_schema.yaml` (Chart.js ADR 0054 §2). See
/// `src/options_gen.dart` for the generated files.
library;

import 'dart:io';

import 'src/check_support.dart';
import 'src/options_gen.dart';

const String _usage = '''
Usage: dart run tool/options_gen.dart [--check]

Reads tool/options_schema.yaml and writes the generated files of
lib/src/options/ (option_keys.g.dart, scope_kinds.g.dart and scopes.g.dart),
formatted with dart format (Chart.js ADR 0054 section 2).

Options:
  --check  Write nothing. Generate into .dart_tool/options_gen_check/ of the
           package, format there, and exit with 1 when a committed file
           differs from its output or when lib/src/options/ has a .g.dart
           file that the generator does not write.
  --help   Print this text.''';

void main(List<String> args) {
  exitCode = run(args, out: stdout);
}

/// Runs the command with [args]. Returns the exit code: 0 when the files
/// are written or equal, 1 when the check fails, 2 for a usage error.
int run(List<String> args, {required IOSink out}) {
  var check = false;
  for (final arg in args) {
    switch (arg) {
      case '--check':
        check = true;
      case '--help' || '-h':
        out.writeln(_usage);
        return 0;
      default:
        out.writeln('options_gen: unknown option $arg\n\n$_usage');
        return 2;
    }
  }
  final package = scriptPackage();
  final schemaFile = File('$package/tool/options_schema.yaml');
  final Schema schema;
  try {
    schema = readSchema(schemaFile.readAsStringSync());
  } on FormatException catch (e) {
    out.writeln('options_gen: tool/options_schema.yaml: ${e.message}');
    return 1;
  }
  final files = generate(schema);
  final target = Directory('$package/lib/src/options');
  final dir = check
      ? Directory('$package/.dart_tool/options_gen_check')
      : target;
  if (check && dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  final paths = <String>[];
  for (final MapEntry(key: name, value: text) in files.entries) {
    final file = File('${dir.path}/$name')..writeAsStringSync(text);
    paths.add(file.path);
  }
  final format = Process.runSync(
    Platform.resolvedExecutable,
    ['format', ...paths],
    workingDirectory: package,
  );
  if (format.exitCode != 0) {
    out.writeln('options_gen: dart format failed:\n${format.stderr}');
    return 1;
  }
  if (!check) {
    out.writeln(
      'options_gen: wrote ${files.length} files of lib/src/options/ '
      '(${schema.kinds.length} kinds, ${schema.keyNames.length} keys).',
    );
    return 0;
  }
  var failed = false;
  for (final name in files.keys) {
    final generated = File('${dir.path}/$name').readAsStringSync();
    final committed = File('${target.path}/$name');
    if (!committed.existsSync()) {
      out.writeln('options_gen: lib/src/options/$name is missing.');
      failed = true;
    } else if (committed.readAsStringSync() != generated) {
      out.writeln(
        'options_gen: lib/src/options/$name differs from the output of '
        'tool/options_schema.yaml. Run dart run melos run options:gen.',
      );
      failed = true;
    }
  }
  for (final entity in target.listSync()) {
    final name = entity.uri.pathSegments.last;
    if (name.endsWith('.g.dart') && !files.containsKey(name)) {
      out.writeln('options_gen: lib/src/options/$name is not generated.');
      failed = true;
    }
  }
  dir.deleteSync(recursive: true);
  out.writeln(
    failed
        ? 'options_gen: check failed.'
        : 'options_gen: check passed, ${files.length} files.',
  );
  return failed ? 1 : 0;
}
