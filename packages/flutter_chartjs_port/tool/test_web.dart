// Original code, not ported from Chart.js: Flutter browser test selection.

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

Future<void> main(List<String> args) async {
  if (args.isNotEmpty) {
    stderr.writeln('Usage: dart run tool/test_web.dart');
    exitCode = 2;
    return;
  }
  final package = scriptPackage();
  final repository = findAncestorWith(package, 'REUSE.toml')!;
  for (final name in ['flutter_chartjs_port', 'chartjs_test_utils']) {
    final directory = '$repository/packages/$name';
    final files = browserTestFiles(directory);
    if (files.isEmpty) throw StateError('No browser tests in $name');
    for (final wasm in [false, true]) {
      stdout.writeln(
        '$name: ${files.length} Flutter browser test files '
        '(${wasm ? 'WebAssembly' : 'JavaScript'})',
      );
      final process = await Process.start(
        'flutter',
        ['test', '--platform', 'chrome', if (wasm) '--wasm', ...files],
        workingDirectory: directory,
        runInShell: Platform.isWindows,
        mode: ProcessStartMode.inheritStdio,
      );
      final code = await process.exitCode;
      if (code != 0) {
        exitCode = code;
        return;
      }
    }
  }
}
