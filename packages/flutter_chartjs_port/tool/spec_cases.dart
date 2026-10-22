// Original code, not ported from Chart.js: the command of spec-case tracking.

/// `dart run packages/flutter_chartjs_port/tool/spec_cases.dart`: spec-case
/// tracking, porting-flow.md section 4, tool 5. See `src/spec_cases.dart`
/// for the rules.
///
/// The case mode (`test:cases`) runs `flutter test --exclude-tags fixtures`
/// on `test/specs`. The mode `--fixtures` (`test:fixtures`, Chart.js ADR
/// 0029, section 10) runs `flutter test --tags fixtures` on the spec files
/// with a fixture group and on `test/port/fixtures/`, and reports each
/// fixture as passed, failed, skipped or missing.
library;

import 'dart:io';

import 'src/check_support.dart';
import 'src/spec_cases.dart';

const String _name = 'test:cases';

const String _fixturesName = 'test:fixtures';

const String _usage = '''
Usage: dart run tool/spec_cases.dart [options] [<package directory>]

Runs the spec tests of test/specs with `flutter test --exclude-tags
fixtures --reporter json` and maps each Dart test onto the upstream cases of
doc/upstream/manifest.json. Prints the status of the cases of each upstream
spec file. Exits with 1 on an unknown test name, a failed case, a bad skip
reason, or a missing case of a spec file that parity.md marks ported.

With --fixtures, runs `flutter test --tags fixtures --reporter json` on the
Dart spec files whose upstream spec file has a fixture group with fixtures,
and on test/port/fixtures when it exists (tool 7, Chart.js ADR 0029).
Prints the fixtures of each spec file as passed, failed, skipped (by
reason) and missing, the port-only tests, the totals and the 10 slowest
tests. Exits with 1 on a failed test or hook, a missing fixture, a fixture
group that is not called, a test that is not a fixture of its group, a
repeated name or a bad skip reason.

Options:
  --fixtures         Report the fixture smoke tests (test:fixtures).
  --results <file>   Read the JSON reporter output from <file> ("-" for
                     stdin) instead of running flutter test.
  --manifest <file>  The manifest (default: doc/upstream/manifest.json).
  --parity <file>    The parity tracker (default: doc/parity.md). The
                     mode --fixtures does not read it.
  --verbose          Also print the status of each case.
  --help             Print this text.''';

Future<void> main(List<String> args) async {
  exitCode = await run(args, out: stdout);
}

/// Runs the command with [args] and returns the exit code: 0 when the cases
/// (or, with `--fixtures`, the fixtures) pass, 1 when the check fails and 2
/// for a usage error, a manifest that does not parse, or a `flutter` command
/// that does not start.
Future<int> run(List<String> args, {required StringSink out}) async {
  String? results;
  String? manifestPath;
  String? parityPath;
  String? package;
  var verbose = false;
  var fixtures = false;
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
        case '--fixtures':
          fixtures = true;
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
  final name = fixtures ? _fixturesName : _name;
  manifestPath ??= '$package/doc/upstream/manifest.json';
  parityPath ??= '$package/doc/parity.md';
  for (final path in [manifestPath, if (!fixtures) parityPath]) {
    if (!File(path).existsSync()) {
      out.writeln('$name: $path does not exist.');
      return 2;
    }
  }

  final Manifest manifest;
  try {
    manifest = Manifest.parse(File(manifestPath).readAsStringSync());
  } on FormatException catch (e) {
    out.writeln('$name: $manifestPath: ${e.message}');
    return 2;
  }
  if (fixtures) {
    return _runFixtureMode(package, manifest, results, out);
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

/// The mode `--fixtures`: runs the fixture tests of [package] (or reads
/// [results]) and reports each fixture of [manifest].
Future<int> _runFixtureMode(
  String package,
  Manifest manifest,
  String? results,
  StringSink out,
) async {
  final selection = selectFixtureFiles(
    manifest,
    (path) =>
        FileSystemEntity.typeSync('$package/$path') !=
        FileSystemEntityType.notFound,
  );
  final findings = <Finding>[];
  final String output;
  if (results == '-') {
    output = await stdin.transform(systemEncoding.decoder).join();
  } else if (results != null) {
    output = File(results).readAsStringSync();
  } else {
    final ({String output, List<Finding> findings}) run;
    try {
      run = await _runTests(package, fixtureTestArguments(selection.files));
    } on ProcessException catch (e) {
      out.writeln('$_fixturesName: cannot run ${e.executable}: ${e.message}');
      return 2;
    }
    output = run.output;
    findings.addAll(run.findings);
  }

  final prefix = relativePath(Directory.current.path, package);
  final parsed = parseReporterOutput(output);
  final result = compareFixtures(
    manifest,
    parsed,
    selection.specs,
    displayPrefix: prefix.isEmpty ? '' : '$prefix/',
  );
  findings.addAll(result.findings);
  out.writeln(
    '$_fixturesName: ${parsed.tests.length} Dart tests with the tag '
    '$fixturesTag, Chart.js ${manifest.version} manifest.',
  );
  if (selection.absent.isNotEmpty) {
    out.writeln(
      '$_fixturesName: no Dart spec file for ${selection.absent.join(', ')}.',
    );
  }
  out.write(renderFixtureTable(result));
  return reportFindings(
    _fixturesName,
    findings,
    out: out,
    files: selection.files.length,
  );
}

/// Runs `flutter test --exclude-tags fixtures --reporter json test/specs` in
/// [package] ([caseTestArguments]). Returns its standard output, and a
/// finding when it exits with an error and gives no test results.
Future<({String output, List<Finding> findings})> _runSpecs(
  String package,
) async {
  final specs = Directory('$package/test/specs');
  if (!specs.existsSync() ||
      !specs.listSync(recursive: true).any((f) => f.path.endsWith('.dart'))) {
    return (output: '', findings: const <Finding>[]);
  }
  return _runTests(package, caseTestArguments);
}

/// Runs `flutter` with [arguments] in [package]. Returns its standard
/// output, and a finding when it exits with an error and gives no test
/// results.
Future<({String output, List<Finding> findings})> _runTests(
  String package,
  List<String> arguments,
) async {
  if (!arguments.any((a) => a.startsWith('test/'))) {
    return (output: '', findings: const <Finding>[]);
  }
  final process = await Process.run(
    'flutter',
    arguments,
    workingDirectory: package,
    runInShell: Platform.isWindows,
  );
  final output = process.stdout as String;
  final findings = <Finding>[];
  if (process.exitCode != 0 && !output.contains('"type":"testDone"')) {
    findings.add(
      Finding(
        arguments.last,
        null,
        'flutter test exited with ${process.exitCode}: '
        '${(process.stderr as String).trim()}',
      ),
    );
  }
  return (output: output, findings: findings);
}
