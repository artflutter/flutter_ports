// Native smoke driver: exercise the real UI/session controller, then exit.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/main.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as cj;
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cj.Chart.register(cj.registerables);
  final requestedOutput = Platform.environment['BENCH_OUTPUT'];
  final output = requestedOutput == null
      ? Directory.systemTemp.createTempSync('chart-benchmark-lab-smoke-')
      : (Directory(requestedOutput)..createSync(recursive: true));
  stdout.writeln('BENCH_SMOKE_OUTPUT ${output.path}');
  final errors = <String>[];
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString());
    FlutterError.presentError(details);
  };
  final boundary = GlobalKey();
  Future<void> screenshot(String name) async {
    await WidgetsBinding.instance.endOfFrame;
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${output.path}/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  }

  Future<void> exercise(BenchmarkController controller) async {
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      await screenshot('dashboard');
      var visualCases = 0;
      for (final engine in ChartLibrary.values) {
        controller.selectLibrary(engine);
        for (final type in ChartType.values) {
          if (!engine.supports(type)) continue;
          visualCases++;
          controller.configure(
            BenchmarkConfig(
              type: type,
              count: 100,
              axes: true,
              grid: true,
              markers: true,
              curved: true,
              fill: true,
              alternateColors: true,
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 400));
          if (type != ChartType.bar && type != ChartType.scatter) {
            await screenshot('${engine.name}-${type.name}');
          }
        }
      }
      for (final engine in ChartLibrary.values) {
        controller
          ..selectLibrary(engine)
          ..configure(const BenchmarkConfig(count: 20000));
        await Future<void>.delayed(const Duration(milliseconds: 700));
        final before = controller.results.length;
        controller.start(capture: true);
        final watch = Stopwatch()..start();
        while ((controller.running || controller.finishing) &&
            watch.elapsed.inSeconds < 60) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        if (controller.results.length != before + 1 ||
            controller.results.first.metrics.samples < 2 ||
            controller.results.first.metrics.fps <= 0) {
          throw StateError(
            '${engine.label}: capture failed: ${controller.message}',
          );
        }
        File('${output.path}/captures.json')
            .writeAsStringSync(controller.exportJson());
      }
      controller.selectLibrary(ChartLibrary.chartjs);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await screenshot('comparisons');
      if (errors.isNotEmpty) throw StateError(errors.join('\n'));
      File('${output.path}/result.json').writeAsStringSync(
        jsonEncode({
          'ok': true,
          'visualCases': visualCases,
          'captures': controller.results.length,
          'itemsPerCapture': 20000,
          'errors': errors,
        }),
      );
      exit(0);
    } on Object catch (error, stack) {
      File('${output.path}/result.json').writeAsStringSync(
        jsonEncode({
          'ok': false,
          'error': '$error',
          'stack': '$stack',
          'flutterErrors': errors,
        }),
      );
      exit(1);
    }
  }

  runApp(
    RepaintBoundary(
      key: boundary,
      child: ChartBenchmarkApp(
        onControllerReady: (controller) => unawaited(exercise(controller)),
      ),
    ),
  );
}
