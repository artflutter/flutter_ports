import 'dart:convert';

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:chart_benchmark_lab/benchmark/metrics.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show chartjsPluginZoomVersion;
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
  test('bubble radius grows with the value in a fixed range', () {
    expect(bubbleRadius(0), 2);
    expect(bubbleRadius(100), 8);
    final frame = DatasetGenerator(100, 7).frame(0);
    for (final p in frame.values) {
      expect(p.r, inInclusiveRange(2, 8));
    }
  });
  test('effective settings keep only what applies to each chart type', () {
    Map<String, Object> effective(ChartType type) => BenchmarkConfig(
      type: type,
      markers: true,
      curved: true,
      fill: true,
      axes: true,
      grid: true,
      alternateColors: true,
    ).toJson();
    for (final type in ChartType.values) {
      final json = effective(type);
      final expected = switch (type) {
        ChartType.line => (true, true, true, true, false),
        ChartType.bar ||
        ChartType.scatter ||
        ChartType.bubble => (false, false, false, true, true),
        ChartType.pie ||
        ChartType.doughnut ||
        ChartType.polarArea => (false, false, false, false, true),
        ChartType.radar => (true, false, true, true, false),
      };
      expect(
        (
          json['markers'],
          json['curved'],
          json['fill'],
          json['axes'],
          json['alternateColors'],
        ),
        expected,
        reason: type.name,
      );
      expect(json['grid'], json['axes'], reason: type.name);
    }
  });
  test('the shadow runs only where the public API draws it', () {
    for (final type in ChartType.values) {
      for (final blur in [false, true]) {
        final config = BenchmarkConfig(
          type: type,
          shadow: true,
          shadowBlur: blur,
        );
        final reason = '${type.name} blur $blur';
        expect(ChartLibrary.chartjs.runs(config), isTrue, reason: reason);
        expect(
          ChartLibrary.flChart.runs(config),
          type == ChartType.line,
          reason: reason,
        );
        expect(
          ChartLibrary.graphic.runs(config),
          blur && !type.drawsLine,
          reason: reason,
        );
        expect(ChartLibrary.syncfusion.runs(config), isFalse, reason: reason);
      }
    }
    expect(const BenchmarkConfig().toJson().containsKey('shadow'), isFalse);
    expect(
      const BenchmarkConfig(shadow: true, shadowBlur: true).toJson()['shadow'],
      'blurred',
    );
  });
  test('zoom applies to the types with an x axis, on each library', () {
    for (final type in ChartType.values) {
      final xAxis = switch (type) {
        ChartType.line ||
        ChartType.bar ||
        ChartType.scatter ||
        ChartType.bubble => true,
        _ => false,
      };
      expect(type.hasZoom, xAxis, reason: type.name);
      final config = BenchmarkConfig(type: type, zoom: true);
      expect(config.zooms, xAxis, reason: type.name);
      for (final library in ChartLibrary.values) {
        final reason = '${library.name} ${type.name}';
        expect(library.zoomsWith(type), xAxis, reason: reason);
        // Zoom stops no library: each has it on each type with an x axis.
        expect(library.runs(config), library.supports(type), reason: reason);
      }
    }
  });
  test('each library names why it cannot run a config', () {
    // No radar on Syncfusion.
    const radar = BenchmarkConfig(type: ChartType.radar);
    expect(ChartLibrary.syncfusion.runs(radar), isFalse);
    expect(
      ChartLibrary.syncfusion.reasonFor(radar),
      'Syncfusion 35.1.43 has no radar chart.',
    );
    expect(ChartLibrary.syncfusion.shortReasonFor(radar), 'No radar chart');
    // A missing chart wins over a missing shadow.
    expect(
      ChartLibrary.syncfusion.shortReasonFor(radar.copyWith(shadow: true)),
      'No radar chart',
    );
    // No shadow on a Syncfusion line, nor a sharp one on a Graphic bar.
    const line = BenchmarkConfig(shadow: true);
    expect(ChartLibrary.syncfusion.runs(line), isFalse);
    expect(
      ChartLibrary.syncfusion.reasonFor(line),
      'Syncfusion 35.1.43 has no sharp shadow on a line chart.',
    );
    expect(ChartLibrary.syncfusion.shortReasonFor(line), 'No shadow here');
    const bar = BenchmarkConfig(type: ChartType.bar, shadow: true);
    expect(ChartLibrary.graphic.runs(bar), isFalse);
    expect(
      ChartLibrary.graphic.reasonFor(bar),
      'Graphic 2.7.0 has no sharp shadow on a bar chart.',
    );
    expect(ChartLibrary.graphic.runs(bar.copyWith(shadowBlur: true)), isTrue);
    // A zoom stops no library.
    expect(
      ChartLibrary.syncfusion.runs(line.copyWith(shadow: false, zoom: true)),
      isTrue,
    );
  });
  test('a set zoom adds a key, so earlier saved runs keep theirs', () {
    const off = BenchmarkConfig();
    const on = BenchmarkConfig(zoom: true);
    expect(off.toJson().containsKey('zoom'), isFalse);
    expect(on.toJson()['zoom'], isTrue);
    expect(on, isNot(off));
    expect(off.copyWith(zoom: true), on);
    expect(off.copyWith(zoom: true).hashCode, on.hashCode);
    expect(on.copyWith(count: 500).zoom, isTrue);
    // A type without an x axis drops the hidden toggle from its key.
    const pie = BenchmarkConfig(type: ChartType.pie);
    expect(pie.copyWith(zoom: true).toJson(), pie.toJson());

    BenchmarkResult result(ChartLibrary library, BenchmarkConfig config) =>
        BenchmarkResult(
          library: library,
          config: config,
          viewport: const Size(600, 400),
          dpr: 2,
          refreshRate: 120,
          metrics: const FrameMetrics(),
          durationSeconds: 10,
          createdAt: DateTime.utc(2026),
        );
    expect(
      result(ChartLibrary.chartjs, on).comparisonKey,
      isNot(result(ChartLibrary.chartjs, off).comparisonKey),
    );
    expect(
      result(ChartLibrary.chartjs, on).comparisonKey,
      result(ChartLibrary.syncfusion, on).comparisonKey,
    );
    expect(
      result(ChartLibrary.chartjs, pie.copyWith(zoom: true)).comparisonKey,
      result(ChartLibrary.chartjs, pie).comparisonKey,
    );
    Map<String, Object?> engineOptions(
      ChartLibrary library,
      BenchmarkConfig config,
    ) =>
        result(library, config).toJson()['engineOptions']!
            as Map<String, Object?>;
    expect(
      engineOptions(ChartLibrary.chartjs, on)['zoomPlugin'],
      chartjsPluginZoomVersion,
    );
    expect(engineOptions(ChartLibrary.chartjs, off)['zoomPlugin'], isNull);
    expect(
      engineOptions(
        ChartLibrary.chartjs,
        pie.copyWith(zoom: true),
      )['zoomPlugin'],
      isNull,
    );
    expect(engineOptions(ChartLibrary.flChart, on)['zoomPlugin'], isNull);
  });
  test('only the radar of Syncfusion has no public chart', () {
    for (final library in ChartLibrary.values) {
      for (final type in ChartType.values) {
        expect(
          library.supports(type),
          !(library == ChartLibrary.syncfusion && type == ChartType.radar),
          reason: '${library.name} ${type.name}',
        );
      }
    }
  });
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
      expect(json.containsKey('webMode'), isFalse);
    },
  );
  test('a capture records the parsing of each Chart.js type', () {
    Map<String, Object?> engineOptions(ChartLibrary library, ChartType type) =>
        BenchmarkResult(
              library: library,
              config: BenchmarkConfig(type: type),
              viewport: const Size(600, 400),
              dpr: 2,
              refreshRate: 120,
              metrics: const FrameMetrics(),
              durationSeconds: 10,
              createdAt: DateTime.utc(2026),
            ).toJson()['engineOptions']!
            as Map<String, Object?>;
    for (final type in ChartType.values) {
      final prepared =
          type == ChartType.line ||
          type == ChartType.scatter ||
          type == ChartType.bubble;
      expect(
        engineOptions(ChartLibrary.chartjs, type)['parsing'],
        prepared ? isFalse : isNull,
        reason: '$type',
      );
      expect(engineOptions(ChartLibrary.flChart, type)['parsing'], isNull);
    }
  });
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
