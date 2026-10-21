// Original code, not ported from Chart.js: the command of the parity generator.

/// `dart run packages/flutter_chartjs/tool/parity.dart`: the parity
/// generator of porting-flow.md section 4, tool 6. See `src/parity.dart` for
/// the rules.
library;

import 'dart:io';

import 'src/check_support.dart';
import 'src/parity.dart';
import 'src/spec_cases.dart';

const String _usage = '''
Usage: dart run tool/parity.dart [options] [<package directory>]

Writes doc/parity.md from doc/status.yaml, the files of the pinned
third_party/ copies, the headers of the Dart files, the case results of the
spec tests (tool 5) and doc/differences.md. The default package is the
package of this tool. It runs `flutter test --exclude-tags fixtures
--reporter json test/specs` for the case results. It needs the submodules
(melos run upstream).

Through melos, put the options after "--":
dart run melos run parity -- --dry-run

Options:
  --check            Write nothing. Exit with 1 when doc/parity.md differs
                     from the output, or on an error.
  --dry-run          Print the output and write nothing. The findings go to
                     the standard error.
  --import           Read the cells of doc/parity.md into doc/status.yaml.
                     An entry whose output equals its cell stays. The
                     derived counts of a changed cell become placeholders.
                     With --dry-run, print the new doc/status.yaml.
  --base <file>      With --import: the doc/parity.md that doc/status.yaml
                     came from. A cell that equals its cell in <file> keeps
                     the entry of doc/status.yaml, so the edits of both
                     files stay.
  --results <file>   Read the JSON reporter output of the spec tests from
                     <file> ("-" for stdin) instead of running flutter test.
  --help             Print this text.

Exits with 0, with 1 for a difference or an error, and with 2 for a usage
error or a missing input.''';

Future<void> main(List<String> args) async {
  exitCode = await run(args, out: stdout, err: stderr);
}

/// Runs the command with [args] and returns the exit code. The output of
/// `--dry-run` goes to [out], and its findings go to [err].
Future<int> run(
  List<String> args, {
  required StringSink out,
  StringSink? err,
}) async {
  var check = false;
  var dryRun = false;
  var import = false;
  String? results;
  String? base;
  String? package;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--help' || '-h':
        out.writeln(_usage);
        return 0;
      case '--check':
        check = true;
      case '--dry-run':
        dryRun = true;
      case '--import':
        import = true;
      case '--results' when i + 1 < args.length:
        results = args[++i];
      case '--base' when i + 1 < args.length:
        base = args[++i];
      default:
        if (arg.startsWith('-') || package != null) {
          out
            ..writeln('$parityName: unexpected argument $arg')
            ..writeln(_usage);
          return 2;
        }
        package = posixPath(Directory(arg).absolute.path);
    }
  }
  if (check && (dryRun || import) || (base != null && !import)) {
    out
      ..writeln(
        '$parityName: --check takes no --dry-run and no --import, and '
        '--base needs --import.',
      )
      ..writeln(_usage);
    return 2;
  }
  package ??= scriptPackage();
  if (!File('$package/pubspec.yaml').existsSync()) {
    out.writeln('$parityName: $package has no pubspec.yaml');
    return 2;
  }
  final repository = findAncestorWith(package, 'REUSE.toml');
  if (repository == null) {
    out.writeln('$parityName: no REUSE.toml in a parent folder of $package');
    return 2;
  }
  String rel(String path) => relativePath(repository, '$package/$path');

  final ReporterOutput specResults;
  try {
    final run = switch (results) {
      '-' => (
        output: await stdin.transform(systemEncoding.decoder).join(),
        error: '',
      ),
      final String file => (output: File(file).readAsStringSync(), error: ''),
      null => await _runSpecs(package),
    };
    specResults = parseReporterOutput(run.output);
    if (specResults.tests.isEmpty && _hasSpecs(package)) {
      out.writeln(
        '$parityName: no results of the spec tests in test/specs. '
                '${run.error}'
            .trim(),
      );
      return 2;
    }
  } on FileSystemException catch (e) {
    out.writeln('$parityName: ${e.path}: ${e.message}');
    return 2;
  } on ProcessException catch (e) {
    out.writeln('$parityName: cannot run ${e.executable}: ${e.message}');
    return 2;
  }

  final ParityModel model;
  final StatusFile status;
  final statusFile = File('$package/$statusPath');
  try {
    model = computeParity(
      ParityInput(
        repository: repository,
        package: package,
        results: specResults,
      ),
    );
    status = statusFile.existsSync()
        ? parseStatusFile(statusFile.readAsStringSync())
        : import && base == null
        ? StatusFile()
        : throw ParityInputError(
            '${rel(statusPath)} does not exist. Make it with --import.',
          );
  } on ParityInputError catch (e) {
    out.writeln('$parityName: ${e.message}');
    return 2;
  } on FormatException catch (e) {
    out.writeln('$parityName: ${rel(statusPath)}: ${e.message}');
    return 2;
  }

  final parityFile = File('$package/$parityPath');
  if (import) {
    if (!parityFile.existsSync()) {
      out.writeln('$parityName: ${rel(parityPath)} does not exist.');
      return 2;
    }
    final String? baseText;
    try {
      baseText = base == null ? null : File(base).readAsStringSync();
    } on FileSystemException catch (e) {
      out.writeln('$parityName: ${e.path}: ${e.message}');
      return 2;
    }
    final result = importParity(
      parityFile.readAsStringSync(),
      model,
      status,
      markdownPath: rel(parityPath),
      base: baseText,
    );
    final text = writeStatusFile(result.status);
    final rendered = renderParity(model, result.status);
    final findings = [...result.findings, ...rendered.findings];
    if (dryRun) {
      out.write(text);
      return reportFindings(
        '$parityName --import',
        findings,
        out: err ?? out,
        files: model.rows.length,
      );
    }
    statusFile.writeAsStringSync(text);
    out.writeln('$parityName: wrote ${rel(statusPath)}.');
    return reportFindings(
      '$parityName --import',
      findings,
      out: out,
      files: model.rows.length,
    );
  }

  final rendered = renderParity(model, status);
  final findings = [...rendered.findings];
  if (dryRun) {
    out.write(rendered.text);
    return reportFindings(
      parityName,
      findings,
      out: err ?? out,
      files: model.rows.length,
    );
  }
  if (check) {
    findings.addAll(
      compareText(
        rendered.text,
        parityFile.existsSync() ? parityFile.readAsStringSync() : '',
        rel(parityPath),
      ),
    );
    return reportFindings(
      '$parityName --check',
      findings,
      out: out,
      files: model.rows.length,
    );
  }
  if (findings.any((f) => f.isError)) {
    out.writeln('$parityName: ${rel(parityPath)} is not written.');
  } else if (parityFile.existsSync() &&
      parityFile.readAsStringSync() == rendered.text) {
    out.writeln('$parityName: ${rel(parityPath)} is up to date.');
  } else {
    parityFile.writeAsStringSync(rendered.text);
    out.writeln('$parityName: wrote ${rel(parityPath)}.');
  }
  return reportFindings(
    parityName,
    findings,
    out: out,
    files: model.rows.length,
  );
}

/// Whether [package] has Dart files in `test/specs`.
bool _hasSpecs(String package) {
  final specs = Directory('$package/test/specs');
  return specs.existsSync() &&
      specs.listSync(recursive: true).any((f) => f.path.endsWith('.dart'));
}

/// The JSON reporter output of `flutter test --exclude-tags fixtures
/// --reporter json test/specs` ([caseTestArguments]) in [package] and its
/// standard error, or empty texts without spec files. The fixture smoke
/// tests do not run (Chart.js ADR 0029, section 10).
Future<({String output, String error})> _runSpecs(String package) async {
  if (!_hasSpecs(package)) return (output: '', error: '');
  final process = await Process.run(
    'flutter',
    caseTestArguments,
    workingDirectory: package,
    runInShell: Platform.isWindows,
  );
  return (
    output: process.stdout as String,
    error: (process.stderr as String).trim(),
  );
}
