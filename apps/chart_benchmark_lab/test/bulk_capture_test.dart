import 'dart:math' show Random;
import 'dart:ui' show FrameTiming, Size;

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void _report(WidgetTester tester, List<int> timestamps) {
  tester.binding.platformDispatcher.onReportTimings!([
    for (final stamp in timestamps)
      FrameTiming(
        vsyncStart: stamp,
        buildStart: stamp,
        buildFinish: stamp + 1000,
        rasterStart: stamp + 1000,
        rasterFinish: stamp + 2000,
        rasterFinishWallTime: stamp + 2000,
      ),
  ]);
}

const _seed = 7;

/// The order that a controller with this random source gives to its next pass.
List<ChartLibrary> _shuffled(Random random) =>
    ChartLibrary.values.toList()..shuffle(random);

/// Runs one engine of a batch through warmup, capture and timing drain.
Future<void> _captureOne(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(seconds: 3));
  final now =
      SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
  _report(tester, [now - 10000, now]);
  await tester.pump(const Duration(seconds: 9));
  await tester.pump(const Duration(milliseconds: 1100));
}

void main() {
  testWidgets('each bulk capture pass shuffles every engine again', (
    tester,
  ) async {
    final expected = Random(_seed);
    final first = _shuffled(expected);
    final second = _shuffled(expected);
    // Guards this test: an unshuffled pass cannot match these two orders.
    expect(first, isNot(ChartLibrary.values));
    expect(second, isNot(first));
    final c = BenchmarkController(const TestVSync(), random: Random(_seed));
    try {
      c
        ..setViewport(const Size(600, 400), 2, 120)
        ..configure(const BenchmarkConfig(count: 100));
      for (final order in [first, second]) {
        c.captureAll();
        for (final engine in order) {
          expect(c.library, engine);
          await _captureOne(tester);
        }
        expect(c.batchCapturing, isFalse);
        expect(
          c.results.take(order.length).map((r) => r.library),
          order.reversed,
        );
      }
      expect(c.results, hasLength(first.length * 2));
    } finally {
      c.dispose();
    }
  });

  testWidgets('bulk capture skips a library without the chart type', (
    tester,
  ) async {
    final c = BenchmarkController(const TestVSync(), random: Random(_seed));
    try {
      c
        ..setViewport(const Size(600, 400), 2, 120)
        ..selectLibrary(ChartLibrary.syncfusion)
        ..configure(const BenchmarkConfig(type: ChartType.radar, count: 100));
      expect(c.canRun, isFalse);
      expect(c.message, contains('has no radar chart'));
      c.start(capture: true);
      expect(c.running, isFalse);
      expect(c.capturing, isFalse);
      expect(c.message, contains('has no radar chart'));
      c.captureAll();
      expect(c.batchCapturing, isTrue);
      expect(c.batchTotal, 3);
      for (var i = 0; i < 3; i++) {
        expect(c.library, isNot(ChartLibrary.syncfusion));
        expect(c.batchPosition, i + 1);
        await _captureOne(tester);
      }
      expect(c.batchCapturing, isFalse);
      expect(
        c.results.map((r) => r.library),
        unorderedEquals([
          ChartLibrary.chartjs,
          ChartLibrary.flChart,
          ChartLibrary.graphic,
        ]),
      );
      expect(c.message, contains('3 captures saved'));
    } finally {
      c.dispose();
    }
  });

  testWidgets('bulk capture saves every engine with isolated timing windows', (
    tester,
  ) async {
    final order = _shuffled(Random(_seed));
    final c = BenchmarkController(const TestVSync(), random: Random(_seed));
    try {
      c
        ..setViewport(const Size(600, 400), 2, 120)
        ..configure(const BenchmarkConfig(count: 100, markers: true))
        ..selectLibrary(ChartLibrary.graphic)
        ..captureAll();
      int? stale;
      for (var i = 0; i < order.length; i++) {
        expect(c.library, order[i]);
        expect(c.batchCapturing, isTrue);
        expect(c.batchPosition, i + 1);
        expect(c.controlsLocked, isTrue);
        expect(c.config.count, 100);
        expect(c.config.markers, isTrue);
        expect(c.frames.value.step, lessThanOrEqualTo(1));
        c
          ..selectLibrary(ChartLibrary.syncfusion)
          ..configure(const BenchmarkConfig(count: 5000));
        expect(c.library, order[i]);
        expect(c.config.count, 100);
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pump(const Duration(seconds: 3));
        final now = SchedulerBinding
            .instance
            .currentSystemFrameTimeStamp
            .inMicroseconds;
        _report(tester, [?stale, now - 10000, now]);
        stale = now;
        await tester.pump(const Duration(seconds: 9));
        expect(c.finishing, isTrue);
        // A valid delayed timing belongs to this engine, even during drain.
        _report(tester, [
          SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds -
              1000000,
        ]);
        await tester.pump(const Duration(milliseconds: 1100));
        expect(c.results.length, i + 1);
        expect(c.results.first.metrics.samples, 3);
        expect(c.results.first.durationSeconds, 10);
        expect(c.results.first.library, order[i]);
      }
      expect(c.batchCapturing, isFalse);
      expect(c.controlsLocked, isFalse);
      expect(c.running, isFalse);
      expect(c.results.map((r) => r.library), order.reversed);
      expect(c.results.map((r) => r.comparisonKey).toSet(), hasLength(1));
      // The "Matching setup" filter compares a result with the controller.
      expect(c.results.first.comparisonKey, c.comparisonKey);
      expect(c.message, contains('Batch complete'));
    } finally {
      c.dispose();
    }
  });

  testWidgets(
    'cancelling while draining preserves prior captures and stops queue',
    (tester) async {
      final order = _shuffled(Random(_seed));
      final c = BenchmarkController(const TestVSync(), random: Random(_seed));
      try {
        c
          ..setViewport(const Size(600, 400), 2, 120)
          ..configure(const BenchmarkConfig(count: 100))
          ..captureAll();
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
        var now = SchedulerBinding
            .instance
            .currentSystemFrameTimeStamp
            .inMicroseconds;
        _report(tester, [now - 10000, now]);
        await tester.pump(const Duration(seconds: 9));
        await tester.pump(const Duration(milliseconds: 1100));
        expect(c.results, hasLength(1));
        expect(c.library, order[1]);
        await tester.pump(const Duration(seconds: 3));
        now = SchedulerBinding
            .instance
            .currentSystemFrameTimeStamp
            .inMicroseconds;
        _report(tester, [now - 10000, now]);
        await tester.pump(const Duration(seconds: 9));
        expect(c.finishing, isTrue);
        c.setWindowVisible(visible: false);
        await tester.pump(const Duration(seconds: 2));
        expect(c.batchCapturing, isFalse);
        expect(c.results, hasLength(1));
        expect(c.library, order[1]);
        expect(c.running, isFalse);
      } finally {
        c.dispose();
      }
    },
  );

  testWidgets('unavailable timings stop a batch instead of saving empty rows', (
    tester,
  ) async {
    final order = _shuffled(Random(_seed));
    final c = BenchmarkController(const TestVSync(), random: Random(_seed));
    try {
      c
        ..setViewport(const Size(600, 400), 2, 120)
        ..configure(const BenchmarkConfig(count: 100))
        ..captureAll();
      await tester.pump();
      await tester.pump(const Duration(seconds: 12));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(c.batchCapturing, isFalse);
      expect(c.results, isEmpty);
      expect(c.library, order.first);
      expect(c.message, contains('Batch stopped'));
    } finally {
      c.dispose();
    }
  });
}
