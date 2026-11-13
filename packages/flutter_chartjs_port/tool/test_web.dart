// Original code, not ported from Chart.js: Flutter browser test selection.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'src/check_support.dart';
import 'src/dart_source.dart';

/// Tests that can compile for a browser, before Flutter builds the test app.
/// Flutter compiles explicitly supplied files together before applying TestOn,
/// so VM-only files must be excluded before invoking its web runner.
List<String> browserTestFiles(String package) => [
  for (final path in dartFilesUnder('$package/test'))
    if (path.endsWith('_test.dart') &&
        !DartSource(File(path).readAsStringSync()).isVmOnly)
      relativePath(package, path),
]..sort();

/// The summary line of a `flutter test` run that passed. The compact and
/// the expanded reporter print `All tests passed!` (or `All tests
/// skipped.`) after the time and the counts. The GitHub reporter, the
/// default on GitHub Actions, prints `🎉 <n> tests passed.`, with
/// `, <m> skipped` before the period when tests skipped.
final RegExp _passedSummary = RegExp(
  r'^(\d+:\d+ [^:]*: (All tests passed!|All tests skipped\.)'
  r'|🎉 \d+ tests? passed(, \d+ skipped)?\.)$',
);

/// An ANSI color sequence of a reporter.
final RegExp _ansiColor = RegExp('\x1B\\[[0-9;]*m');

/// Whether [line] of the output of `flutter test` is the summary of a run
/// that passed.
bool isPassedSummary(String line) =>
    _passedSummary.hasMatch(line.replaceAll(_ansiColor, '').trim());

/// The failure of one leg of `flutter test`, or null when it passed. The
/// leg passed only when it exited with 0 and printed the summary of a run
/// that passed ([sawSummary]). A negative [exitCode] is the signal that
/// ended the process (POSIX). `flutter test` exits with 0 when a SIGTERM
/// stops it, also in the middle of a run (Flutter 3.50.0-0.4.pre). Thus a
/// leg that stops without its summary fails too.
String? legFailure(int exitCode, {required bool sawSummary}) {
  if (exitCode < 0) return 'ended by the signal ${-exitCode}';
  if (exitCode != 0) return 'exited with $exitCode';
  if (!sawSummary) return 'exited with 0 without the summary of a run';
  return null;
}

/// Runs `flutter test` with [arguments] in [directory]. It forwards the
/// output and returns the exit code and whether the output had the
/// summary of a run that passed.
Future<({int exitCode, bool sawSummary})> _runLeg(
  String directory,
  List<String> arguments,
) async {
  final process = await Process.start(
    'flutter',
    arguments,
    workingDirectory: directory,
    runInShell: Platform.isWindows,
  );
  var sawSummary = false;
  final out = process.stdout
      .transform(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter())
      .listen((line) {
        stdout.writeln(line);
        if (isPassedSummary(line)) sawSummary = true;
      })
      .asFuture<void>();
  final err = stderr.addStream(process.stderr);
  final exitCode = await process.exitCode;
  await Future.wait([out, err]);
  return (exitCode: exitCode, sawSummary: sawSummary);
}

Future<void> main(List<String> args) async {
  if (args.isNotEmpty) {
    stderr.writeln('Usage: dart run tool/test_web.dart');
    exitCode = 2;
    return;
  }
  final package = scriptPackage();
  final repository = findAncestorWith(package, 'REUSE.toml')!;
  for (final name in [
    'flutter_chartjs_port',
    'chartjs_test_utils',
    'flutter_kurkle_color_port',
  ]) {
    final directory = '$repository/packages/$name';
    final files = browserTestFiles(directory);
    if (files.isEmpty) throw StateError('No browser tests in $name');
    for (final wasm in [false, true]) {
      final leg =
          '$name: ${files.length} Flutter browser test files '
          '(${wasm ? 'WebAssembly' : 'JavaScript'})';
      stdout.writeln(leg);
      final result = await _runLeg(directory, [
        'test',
        '--platform',
        'chrome',
        if (wasm) '--wasm',
        ...files,
      ]);
      final failure = legFailure(
        result.exitCode,
        sawSummary: result.sawSummary,
      );
      if (failure != null) {
        stderr.writeln('test:web: $leg $failure.');
        exitCode = result.exitCode > 0 ? result.exitCode : 1;
        return;
      }
    }
  }
}
