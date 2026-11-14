import 'dart:async';

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:chart_benchmark_lab/charts/chart_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A loader whose loads complete only when the test completes them.
class _Loader() {
  final Map<ChartLibrary, Completer<void>> loads = {};
  final Set<ChartLibrary> ready = {ChartLibrary.chartjs};

  Future<void>? call(ChartLibrary library) => ready.contains(library)
      ? null
      : (loads[library] ??= Completer<void>()).future;

  void complete(ChartLibrary library) {
    ready.add(library);
    loads.remove(library)!.complete();
  }

  void fail(ChartLibrary library) =>
      loads.remove(library)!.completeError(StateError('offline'));
}

BenchmarkController _controller(_Loader loader) =>
    BenchmarkController(const TestVSync(), loadCode: loader.call)
      ..setViewport(const Size(600, 400), 2, 120)
      ..configure(const BenchmarkConfig(count: 100));

void main() {
  testWidgets('a selected library shows after its code loads', (tester) async {
    final loader = _Loader();
    final c = _controller(loader);
    addTearDown(c.dispose);
    c.selectLibrary(ChartLibrary.flChart);
    expect(c.loadingLibrary, ChartLibrary.flChart);
    expect(c.message, 'Loading fl_chart…');
    loader.complete(ChartLibrary.flChart);
    await tester.pump();
    expect(c.loadingLibrary, isNull);
    expect(c.message, startsWith('Ready.'));
    expect(c.running, isFalse);
  });

  testWidgets('a run waits for the code, then starts', (tester) async {
    final loader = _Loader();
    final c = _controller(loader);
    addTearDown(c.dispose);
    c
      ..selectLibrary(ChartLibrary.syncfusion)
      ..start(capture: true);
    expect(c.running, isFalse);
    expect(c.capturing, isFalse);
    loader.complete(ChartLibrary.syncfusion);
    await tester.pump();
    expect(c.loadingLibrary, isNull);
    expect(c.running, isTrue);
    expect(c.capturing, isTrue);
    c.pause();
  });

  testWidgets('a pause during the load keeps the run from starting', (
    tester,
  ) async {
    final loader = _Loader();
    final c = _controller(loader);
    addTearDown(c.dispose);
    c
      ..selectLibrary(ChartLibrary.graphic)
      ..start()
      ..pause();
    loader.complete(ChartLibrary.graphic);
    await tester.pump();
    expect(c.loadingLibrary, isNull);
    expect(c.running, isFalse);
  });

  testWidgets('a batch loads each library before its capture', (tester) async {
    final loader = _Loader();
    final c = _controller(loader);
    addTearDown(c.dispose);
    c.captureAll();
    final first = c.library;
    if (first != ChartLibrary.chartjs) {
      expect(c.running, isFalse);
      expect(c.batchCapturing, isTrue);
      loader.complete(first);
      await tester.pump();
    }
    expect(c.running, isTrue);
    expect(c.capturing, isTrue);
    c.pause();
  });

  testWidgets('a failed load says so and allows a new selection', (
    tester,
  ) async {
    final loader = _Loader();
    final c = _controller(loader);
    addTearDown(c.dispose);
    c
      ..selectLibrary(ChartLibrary.flChart)
      ..start();
    loader.fail(ChartLibrary.flChart);
    await tester.pump();
    expect(c.loadingLibrary, isNull);
    expect(c.running, isFalse);
    expect(c.message, 'Could not load fl_chart. Reload the page.');
    c.selectLibrary(ChartLibrary.chartjs);
    expect(c.message, startsWith('Ready.'));
  });

  testWidgets('the chart shows a note until the code of its library loads', (
    tester,
  ) async {
    Widget chart(ChartLibrary library) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 600,
            height: 400,
            child: BenchmarkChart(
              library: library,
              config: const BenchmarkConfig(count: 10),
              frame: DatasetGenerator(10, 1).frame(0),
              size: const Size(600, 400),
            ),
          ),
        ),
      ),
    );
    expect(BenchmarkChart.isReady(ChartLibrary.chartjs), isTrue);
    for (final library in [
      ChartLibrary.flChart,
      ChartLibrary.graphic,
      ChartLibrary.syncfusion,
    ]) {
      expect(BenchmarkChart.isReady(library), isFalse);
      await tester.pumpWidget(chart(library));
      expect(find.text('Loading ${library.label}…'), findsOneWidget);
    }
    await tester.runAsync(BenchmarkChart.loadAll);
    expect(BenchmarkChart.load(ChartLibrary.syncfusion), isNull);
    for (final library in [
      ChartLibrary.flChart,
      ChartLibrary.graphic,
      ChartLibrary.syncfusion,
    ]) {
      await tester.pumpWidget(chart(library));
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('chart.loading')), findsNothing);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 20));
  });
}
