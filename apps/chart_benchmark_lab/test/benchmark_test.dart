import 'dart:convert';

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:chart_benchmark_lab/benchmark/metrics.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'seeded input is stable, sorted, finite and changes only with step or seed',
    () {
      final a = DatasetGenerator(20000, 7).frame(10);
      final b = DatasetGenerator(20000, 7).frame(10);
      final next = DatasetGenerator(20000, 7).frame(11);
      expect(a.values.length, 20000);
      expect(a.values.map((p) => p.y), b.values.map((p) => p.y));
      expect(a.values.map((p) => p.y), isNot(next.values.map((p) => p.y)));
      for (var i = 0; i < a.values.length; i++) {
        expect(a.values[i].y, inInclusiveRange(0, 100));
        if (i > 0) expect(a.values[i].x, greaterThan(a.values[i - 1].x));
      }
    },
  );
  test(
    'capture excludes warmup, stale batches and frames at/after the end',
    () {
      final window = TimingWindow()
        ..startUs = 10000000
        ..endUs = 22000000;
      for (final t in [
        9999999,
        11999999,
        12000000,
        13000000,
        21999999,
        22000000,
      ]) {
        window.add(FrameSample(t, 10, 2));
      }
      expect(window.summary.samples, 3);
      expect(
        window.summary.fps,
        .3,
      ); // Three frames / ten full measured seconds.
    },
  );
  test('metrics preserve stalls and compare stages independently', () {
    final metrics = FrameMetrics.fromSamples([
      const FrameSample(0, 10, 9),
      const FrameSample(10000, 20, 1),
      const FrameSample(1010000, 2, 18),
    ]);
    expect(metrics.fps, closeTo(1.98, .01));
    expect(metrics.uiP90, 20);
    expect(metrics.rasterP90, 18);
    expect(metrics.overBudgetPercent, closeTo(200 / 3, .001));
    expect(const FrameMetrics().samples, 0);
  });
  test(
    'comparability includes effective settings and viewport, not library',
    () {
      BenchmarkResult result(
        ChartLibrary library,
        Size size,
        BenchmarkConfig config,
      ) => BenchmarkResult(
        library: library,
        config: config,
        viewport: size,
        dpr: 2,
        refreshRate: 120,
        metrics: const FrameMetrics(),
        durationSeconds: 10,
        createdAt: DateTime.utc(2026),
      );
      const settings = BenchmarkConfig(type: ChartType.pie);
      final a = result(ChartLibrary.chartjs, const Size(600, 400), settings);
      final b = result(
        ChartLibrary.flChart,
        const Size(600, 400),
        settings.copyWith(curved: true),
      );
      expect(a.comparisonKey, b.comparisonKey);
      expect(
        a.comparisonKey,
        isNot(
          result(
            ChartLibrary.graphic,
            const Size(601, 400),
            settings,
          ).comparisonKey,
        ),
      );
      final json = jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>;
      expect((json['settings'] as Map<String, dynamic>)['items'], 1000);
      expect(json['warmupSeconds'], 2);
      expect(json['version'], ChartLibrary.chartjs.version);
      expect(json['sdk'], benchmarkSdk);
    },
  );
  test(
    'deferred work appears in cadence while 60 Hz rounding is tolerated',
    () {
      final deferred = FrameMetrics.fromSamples([
        const FrameSample(0, 1, 1),
        const FrameSample(100000, 1, 1),
      ]);
      expect(deferred.intervalP90, 100);
      expect(deferred.cadenceMissPercent, 100);
      expect(deferred.overBudgetPercent, 50);
      final normal = FrameMetrics.fromSamples([
        const FrameSample(0, 1, 1),
        const FrameSample(16666, 1, 1),
        const FrameSample(33333, 1, 1),
        const FrameSample(50000, 1, 1),
      ]);
      expect(normal.cadenceMissPercent, 0);
      expect(normal.overBudgetPercent, 0);
    },
  );
}
