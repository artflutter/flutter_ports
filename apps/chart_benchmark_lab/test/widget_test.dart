import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:chart_benchmark_lab/charts/chart_adapter.dart';
import 'package:chart_benchmark_lab/main.dart';
import 'package:chart_benchmark_lab/ui/change_log.dart';
import 'package:chart_benchmark_lab/ui/page_note.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as cj;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() => cj.Chart.register(cj.registerables));
  for (final library in ChartLibrary.values) {
    for (final type in ChartType.values) {
      testWidgets(
        '${library.name} ${type.name} renders and updates all features',
        (tester) async {
          final generator = DatasetGenerator(12, 7);
          final config = BenchmarkConfig(
            type: type,
            count: 12,
            axes: true,
            grid: true,
            markers: true,
            curved: true,
            fill: true,
            alternateColors: true,
            tooltips: true,
          );
          Widget scene(int step) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 600,
                  height: 350,
                  child: BenchmarkChart(
                    library: library,
                    config: config,
                    frame: generator.frame(step),
                    size: const Size(600, 350),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpWidget(scene(0));
          await tester.pump(const Duration(milliseconds: 20));
          await tester.pumpWidget(scene(1));
          await tester.pump(const Duration(milliseconds: 20));
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const ValueKey('chart.unsupported')),
            library.supports(type) ? findsNothing : findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(milliseconds: 20));
        },
      );
    }
  }

  testWidgets('the header opens the change log, newest entry first', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ChartBenchmarkApp());
    await tester.pump();
    expect(find.text('• ${changeLog.first.items.first}'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('changelog')));
    await tester.pumpAndSettle();
    expect(find.text('• ${changeLog.first.items.first}'), findsOneWidget);
    final dates = [for (final entry in changeLog) entry.date];
    expect(dates, [...dates]..sort((a, b) => b.compareTo(a)));
    await tester.tap(find.byKey(const ValueKey('changelog.close')));
    await tester.pumpAndSettle();
    expect(find.text('• ${changeLog.first.items.first}'), findsNothing);
  });

  testWidgets('a page note shows its text and closes', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: PageNote(
            title: 'WASM · 1 THREAD',
            text: 'The reason.',
            onClose: () => closed = true,
          ),
        ),
      ),
    );
    expect(find.text('WASM · 1 THREAD'), findsOneWidget);
    expect(find.text('The reason.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('page.note.close')));
    expect(closed, isTrue);
  });

  testWidgets('a native build has no web mode note', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ChartBenchmarkApp());
    await tester.pump();
    expect(find.byType(PageNote), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 20));
  });

  testWidgets('a scroll stops a test, and a note that stays says why', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late BenchmarkController c;
    await tester.pumpWidget(
      ChartBenchmarkApp(onControllerReady: (value) => c = value),
    );
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tap(find.byKey(const ValueKey('run')));
    await tester.pump(const Duration(milliseconds: 20));
    expect(c.running, isTrue);
    expect(find.byType(PageNote), findsNothing);

    await tester.dragFrom(const Offset(800, 220), const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 20));
    // This frame builds the note. The next one ends the scale of the floating
    // slot.
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(seconds: 1));
    expect(c.running, isFalse);
    expect(find.text('TEST STOPPED'), findsOneWidget);
    expect(find.textContaining('You scrolled during the test'), findsWidgets);
    final place = tester.getTopLeft(find.byKey(const ValueKey('page.note')));

    await tester.dragFrom(const Offset(800, 400), const Offset(0, 100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(find.byKey(const ValueKey('page.note'))), place);

    await tester.tap(find.byKey(const ValueKey('page.note.close')));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(seconds: 1));
    expect(c.stopReason, isNull);
    expect(find.text('TEST STOPPED'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 20));
  });

  testWidgets('a test with the chart out of view stops and says why', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late BenchmarkController c;
    await tester.pumpWidget(
      ChartBenchmarkApp(onControllerReady: (value) => c = value),
    );
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tap(find.byKey(const ValueKey('run')));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.running, isFalse);
    expect(c.stopReason, contains('out of view'));
    expect(find.text('TEST STOPPED'), findsOneWidget);

    c.start();
    expect(c.stopReason, isNull);
    c.pause();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 20));
  });

  testWidgets('a type without a public chart stops only that library', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late BenchmarkController c;
    await tester.pumpWidget(
      ChartBenchmarkApp(onControllerReady: (value) => c = value),
    );
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tap(find.byKey(const ValueKey('type.radar')));
    await tester.pump(const Duration(milliseconds: 20));
    expect(c.config.type, ChartType.radar);
    expect(find.byKey(const ValueKey('chart.unsupported')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('library.syncfusion')));
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byKey(const ValueKey('chart.unsupported')), findsOneWidget);
    expect(find.text('No radar chart'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('run')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('capture')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('capture.all')));
    await tester.pump(const Duration(milliseconds: 20));
    expect(c.library, isNot(ChartLibrary.syncfusion));
    expect(find.text('Cancel all (1/3)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('capture.all')));
    await tester.pump(const Duration(milliseconds: 20));
    expect(c.batchCapturing, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 20));
  });

  for (final size in [
    const Size(1400, 1000),
    const Size(412, 915),
    const Size(360, 640),
  ]) {
    testWidgets('dashboard controls fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ChartBenchmarkApp());
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Chart benchmark lab'), findsOneWidget);
      expect(find.byKey(const ValueKey('flutter.version')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 20));
    });
  }

  testWidgets(
    'library switch retains count and features and clears live metrics',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ChartBenchmarkApp());
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(find.byKey(const ValueKey('dataset.100')));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(find.byKey(const ValueKey('feature.markers')));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(find.byKey(const ValueKey('library.flChart')));
      await tester.pump(const Duration(milliseconds: 20));
      final chart = tester.widget<BenchmarkChart>(find.byType(BenchmarkChart));
      expect(chart.library, ChartLibrary.flChart);
      expect(chart.config.count, 100);
      expect(chart.config.markers, isTrue);
      await tester.tap(find.byKey(const ValueKey('run')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Pause'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('run')));
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 20));
    },
  );
  testWidgets(
    'captures lock settings and cancel on hidden or changed viewport',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late BenchmarkController controller;
      await tester.pumpWidget(
        ChartBenchmarkApp(onControllerReady: (c) => controller = c),
      );
      await tester.pump(const Duration(milliseconds: 20));
      controller.configure(const BenchmarkConfig(count: 100));
      await tester.pump(const Duration(milliseconds: 20));
      controller.start(capture: true);
      await tester.pump(const Duration(milliseconds: 20));
      expect(controller.capturing, isTrue);
      controller
        ..configure(const BenchmarkConfig(count: 5000))
        ..selectLibrary(ChartLibrary.flChart);
      expect(controller.config.count, 100);
      expect(controller.library, ChartLibrary.chartjs);
      controller.setWindowVisible(visible: false);
      expect(controller.running, isFalse);
      expect(controller.capturing, isFalse);
      expect(controller.results, isEmpty);
      controller.start(capture: true);
      expect(controller.running, isFalse);
      controller
        ..setWindowVisible(visible: true)
        ..start(capture: true);
      await tester.pump(const Duration(milliseconds: 20));
      controller.setViewport(const Size(300, 200), 2, 120);
      expect(controller.capturing, isFalse);
      expect(controller.results, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 20));
    },
  );
  testWidgets('Capture all button starts and cancels the batch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late BenchmarkController c;
    await tester.pumpWidget(
      ChartBenchmarkApp(onControllerReady: (value) => c = value),
    );
    await tester.pump(const Duration(milliseconds: 20));
    c.configure(const BenchmarkConfig(count: 100));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tap(find.byKey(const ValueKey('capture.all')));
    await tester.pump(const Duration(milliseconds: 20));
    expect(c.batchCapturing, isTrue);
    expect(find.text('Cancel all (1/4)'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('library.flChart')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('capture.all')));
    await tester.pump(const Duration(milliseconds: 20));
    expect(c.batchCapturing, isFalse);
    expect(c.results, isEmpty);
    expect(find.text('Capture all 10s'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 20));
  });
}
