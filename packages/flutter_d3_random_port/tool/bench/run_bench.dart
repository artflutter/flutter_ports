// Original code, not ported from d3-random: CLI benchmark runner.

// Tool prints benchmark summaries.
// ignore_for_file: avoid_print

import 'dart:io';

Future<void> _run(
  String exe,
  List<String> args, {
  String? workingDirectory,
  File? stdoutFile,
}) async {
  final res = await Process.run(exe, args, workingDirectory: workingDirectory);
  if (res.exitCode != 0) {
    stderr
      ..writeln('Command failed ($exe ${args.join(' ')}):')
      ..writeln(res.stderr);
    exit(res.exitCode);
  }
  if (stdoutFile != null) {
    stdoutFile.writeAsStringSync(res.stdout as String);
  }
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/bench/run_bench.dart <outDir> [targets]',
    );
    exit(2);
  }
  final outDir = Directory(args[0])..createSync(recursive: true);
  final buildDir = Directory('${outDir.path}/build')
    ..createSync(recursive: true);
  final targets = args.length > 1
      ? args[1].split(',')
      : const ['node', 'aot', 'js', 'wasm'];
  final dartExe = Platform.resolvedExecutable;
  final pkgDir = Directory.current.path;

  for (final t in targets) {
    final outFile = File('${outDir.path}/$t.txt');
    switch (t) {
      case 'node':
        await _run('node', [
          '$pkgDir/tool/bench/d3_random_bench.mjs',
          '--target=node',
        ], stdoutFile: outFile);
      case 'aot':
        final exePath = '${buildDir.path}/bench.exe';
        await _run(dartExe, [
          'compile',
          'exe',
          '-o',
          exePath,
          '$pkgDir/tool/bench/d3_random_bench.dart',
        ]);
        await _run(exePath, ['--target=aot'], stdoutFile: outFile);
      case 'js':
        final jsPath = '${buildDir.path}/bench.js';
        await _run(dartExe, [
          'compile',
          'js',
          '-O4',
          '-o',
          jsPath,
          '$pkgDir/tool/bench/d3_random_bench.dart',
        ]);
        final runner = File('${buildDir.path}/run_js.cjs')
          ..writeAsStringSync(
            'globalThis.self = globalThis;\n'
            'globalThis.window = globalThis;\n'
            'globalThis.dartMainRunner = (m) => m(process.argv.slice(2));\n'
            'require(${_jsString(jsPath)});\n',
          );
        await _run('node', [runner.path, '--target=js'], stdoutFile: outFile);
      case 'wasm':
        final wasmPath = '${buildDir.path}/bench.wasm';
        final mjsPath = '${buildDir.path}/bench.mjs';
        await _run(dartExe, [
          'compile',
          'wasm',
          '-O2',
          '-o',
          wasmPath,
          '$pkgDir/tool/bench/d3_random_bench.dart',
        ]);
        final runner = File('${buildDir.path}/run_wasm.mjs')
          ..writeAsStringSync(
            'import * as m from ${_jsString(mjsPath)};\n'
            'import {readFileSync} from "node:fs";\n'
            'const bytes = readFileSync(${_jsString(wasmPath)});\n'
            'const app = await (await m.compile(bytes)).instantiate({});\n'
            'app.invokeMain(...process.argv.slice(2));\n',
          );
        await _run('node', [runner.path, '--target=wasm'], stdoutFile: outFile);
      default:
        stderr.writeln('Unknown target: $t');
        exit(2);
    }
    final count = outFile
        .readAsLinesSync()
        .where((l) => l.startsWith('BENCH '))
        .length;
    print('$t: $count cases -> ${outFile.path}');
  }
}

String _jsString(String s) =>
    '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
