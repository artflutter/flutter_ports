// Original code, not ported from Chart.js: the command of spec-case tracking.

/// `dart run packages/flutter_chartjs/tool/spec_cases.dart`: spec-case
/// tracking, porting-flow.md section 4, tool 5. See `src/spec_cases.dart`
/// for the rules.
library;

import 'dart:io';

import 'src/check_support.dart';
import 'src/spec_cases.dart';

const String _name = 'test:cases';

const String _usage = '''
Usage: dart run tool/spec_cases.dart [options] [<package directory>]

Runs the spec tests of test/specs with `flutter test --reporter json` and
maps each Dart test onto the upstream cases of doc/upstream/manifest.json.
Prints the status of the cases of each upstream spec file. Exits with 1 on
an unknown test name, a failed case, a bad skip reason, or a missing case
of a spec file that parity.md marks ported.

Options:
  --results <file>   Read the JSON reporter output from <file> ("-" for
                     stdin) instead of running flutter test.
  --manifest <file>  The manifest (default: doc/upstream/manifest.json).
  --parity <file>    The parity tracker (default: doc/parity.md).
  --verbose          Also print the status of each case.
  --help             Print this text.''';

Future<void> main(List<String> args) async {
  exitCode = await run(args, out: stdout);
}

/// Runs the command with [args] and returns the exit code: 0 when the cases
/// pass, 1 when the check fails and 2 for a usage error, a manifest that
/// does not parse, or a `flutter` command that does not start.
Future<int> run(List<String> args, {required StringSink out}) async {
  String? results;
  String? manifestPath;
  String? parityPath;
  String? package;
  var verbose = false;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String value() {
      if (i + 1 >= args.length) throw FormatException('$arg needs a value');
      return args[++i];
    }

    try {
      switch (arg) {
        case '--help' || '-h':
          out.writeln(_usage);
          return 0;
        case '--results':
          results = value();
        case '--manifest':
          manifestPath = value();
        case '--parity':
          parityPath = value();
        case '--verbose' || '-v':
          verbose = true;
        default:
          if (arg.startsWith('-') || package != null) {
            throw FormatException('unexpected argument $arg');
          }
          package = posixPath(Directory(arg).absolute.path);
      }
    } on FormatException catch (e) {
      out
        ..writeln('$_name: ${e.message}')
        ..writeln(_usage);
      return 2;
    }
  }
  package ??= scriptPackage();
  manifestPath ??= '$package/doc/upstream/manifest.json';
  parityPath ??= '$package/doc/parity.md';
  for (final path in [manifestPath, parityPath]) {
    if (!File(path).existsSync()) {
      out.writeln('$_name: $path does not exist.');
      return 2;
    }
  }

  final Manifest manifest;
  try {
    manifest = Manifest.parse(File(manifestPath).readAsStringSync());
  } on FormatException catch (e) {
    out.writeln('$_name: $manifestPath: ${e.message}');
    return 2;
  }

  final findings = <Finding>[];
  final String output;
  if (results == '-') {
    output = await stdin.transform(systemEncoding.decoder).join();
  } else if (results != null) {
    output = File(results).readAsStringSync();
  } else {
    final ({String output, List<Finding> findings}) run;
    try {
      run = await _runSpecs(package);
    } on ProcessException catch (e) {
      out.writeln('$_name: cannot run ${e.executable}: ${e.message}');
      return 2;
    }
    output = run.output;
    findings.addAll(run.findings);
  }

  final prefix = relativePath(Directory.current.path, package);
  final parsed = parseReporterOutput(output);
  final result = compareCases(
    manifest,
    parsed,
    parseParityStatuses(File(parityPath).readAsStringSync()),
    displayPrefix: prefix.isEmpty ? '' : '$prefix/',
  );
  findings.addAll(result.findings);
  out
    ..writeln(
      '$_name: ${parsed.tests.length} Dart tests in test/specs, '
      'Chart.js ${manifest.version} manifest.',
    )
    ..write(renderTable(result.reports, verbose: verbose));
  return reportFindings(
    _name,
    findings,
    out: out,
    files: result.reports.where((r) => r.hasDartFile).length,
  );
}

/// Runs `flutter test --reporter json test/specs` in [package]. Returns its
/// standard output, and a finding when it exits with an error and gives no
/// test results.
Future<({String output, List<Finding> findings})> _runSpecs(
  String package,
) async {
  final specs = Directory('$package/test/specs');
  if (!specs.existsSync() ||
      !specs.listSync(recursive: true).any((f) => f.path.endsWith('.dart'))) {
    return (output: '', findings: const <Finding>[]);
  }
  final process = await Process.run(
    'flutter',
    ['test', '--reporter', 'json', 'test/specs'],
    workingDirectory: package,
    runInShell: Platform.isWindows,
  );
  final output = process.stdout as String;
  final findings = <Finding>[];
  if (process.exitCode != 0 && !output.contains('"type":"testDone"')) {
    findings.add(
      Finding(
        'test/specs',
        null,
        'flutter test exited with ${process.exitCode}: '
            '${(process.stderr as String).trim()}',
      ),
    );
  }
  return (output: output, findings: findings);
}
