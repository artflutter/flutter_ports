// The zoom and pan toggle (BenchmarkConfig.zoom) on each library: the option
// of each adapter, the plugin of the Chart.js port only with the toggle, and
// the input of a person. The input tests compare the picture of the chart
// before and after a gesture, through the public render tree, and read the
// scales of the Chart.js port.
import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:chart_benchmark_lab/charts/chart_adapter.dart';
import 'package:chart_benchmark_lab/main.dart';
import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    as zp;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as cj;
import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart' as gr;
import 'package:material_ui/material_ui.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as sf;

const _size = Size(600, 350);
final DatasetFrame _frame = DatasetGenerator(100, 7).frame(0);
final GlobalKey _boundary = GlobalKey();

/// The types with an x axis.
final List<ChartType> _zoomTypes = [
  for (final type in ChartType.values)
    if (type.hasZoom) type,
];

/// [library] with [config] in a box of [_size], below a repaint boundary,
/// with the values of [_frame] at the tick [step].
Widget _scene(
  ChartLibrary library,
  BenchmarkConfig config, {
  int step = 0,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: RepaintBoundary(
        key: _boundary,
        child: SizedBox.fromSize(
          size: _size,
          child: BenchmarkChart(
            library: library,
            config: config,
            frame: DatasetFrame(_frame.values, step),
            size: _size,
          ),
        ),
      ),
    ),
  ),
);

Future<void> _pump(WidgetTester tester, Widget scene) async {
  await tester.pumpWidget(scene);
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 20));
}

/// The picture of the chart before a gesture. The first update of a chart of
/// the Chart.js port repaints a part of its first frame, with or without zoom
/// (38,661 bytes of the RGBA picture of a line of 100 items at 600 x 350, on
/// 2026-11-10), and a pan or a pinch updates the chart. Thus the first
/// picture comes after one update.
Future<Uint8List> _baseline(WidgetTester tester, ChartLibrary library) async {
  if (library == ChartLibrary.chartjs) {
    _chart().update('none');
    await tester.pump(const Duration(milliseconds: 20));
  }
  return _pixels(tester);
}

/// The pixels of the chart.
Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary =
      _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

Offset _center(WidgetTester tester) =>
    tester.getCenter(find.byType(BenchmarkChart));

/// A mouse wheel over the center of the chart: a negative [dy] zooms in.
Future<void> _wheel(WidgetTester tester, double dy) async {
  final pointer = TestPointer(1, PointerDeviceKind.mouse);
  await tester.sendEventToBinding(pointer.hover(_center(tester)));
  await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

/// Two fingers that move apart along x, around the center of the chart.
Future<void> _pinch(WidgetTester tester) async {
  final center = _center(tester);
  final a = await tester.startGesture(center - const Offset(40, 0));
  final b = await tester.startGesture(center + const Offset(40, 0));
  await tester.pump(const Duration(milliseconds: 16));
  for (var i = 1; i <= 6; i++) {
    await a.moveTo(center - Offset(40 + 20.0 * i, 0));
    await b.moveTo(center + Offset(40 + 20.0 * i, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await a.up();
  await b.up();
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

/// One finger that drags along x from the center of the chart.
Future<void> _drag(WidgetTester tester, double dx) async {
  final center = _center(tester);
  final gesture = await tester.startGesture(center);
  await tester.pump(const Duration(milliseconds: 16));
  for (var i = 1; i <= 6; i++) {
    await gesture.moveTo(center + Offset(dx * i / 6, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

/// The one live chart of the Chart.js port.
cj.Chart _chart() => cj.Chart.instances.values.single;

/// The range of the scale [id] of the live chart of the Chart.js port.
(double, double) _range(String id) {
  final scale = _chart().scales[id]!;
  return (scale.min, scale.max);
}

bool get _zoomRegistered => cj.registry.plugins.get(zp.zoomPlugin.id) != null;

void main() {
  setUpAll(() => cj.Chart.register(cj.registerables));

  for (final library in ChartLibrary.values) {
    for (final type in _zoomTypes) {
      testWidgets('${library.name} ${type.name} builds with zoom on and off', (
        tester,
      ) async {
        for (final zoom in [true, false]) {
          final config = BenchmarkConfig(
            type: type,
            count: 100,
            axes: true,
            grid: true,
            tooltips: true,
            zoom: zoom,
          );
          await _pump(tester, _scene(library, config));
          expect(tester.takeException(), isNull);
          expect(find.byKey(const ValueKey('chart.unsupported')), findsNothing);
          final reason = '${library.name} ${type.name} zoom $zoom';
          switch (library) {
            case ChartLibrary.chartjs:
              final view = tester.widget<cj.ChartView>(
                find.byType(cj.ChartView),
              );
              final plugins = view.config!.extra!['plugins'];
              expect(
                plugins is Map && plugins['zoom'] is Map,
                zoom,
                reason: reason,
              );
              expect(_zoomRegistered, zoom, reason: reason);
              expect(_chart().isPluginEnabled('zoom'), zoom, reason: reason);
            case ChartLibrary.flChart:
              final transformation = switch (type) {
                ChartType.line =>
                  tester
                      .widget<fl.LineChart>(find.byType(fl.LineChart))
                      .transformationConfig,
                ChartType.bar =>
                  tester
                      .widget<fl.BarChart>(find.byType(fl.BarChart))
                      .transformationConfig,
                _ =>
                  tester
                      .widget<fl.ScatterChart>(find.byType(fl.ScatterChart))
                      .transformationConfig,
              };
              expect(
                transformation.scaleAxis,
                zoom ? fl.FlScaleAxis.horizontal : fl.FlScaleAxis.none,
                reason: reason,
              );
              if (zoom) {
                expect(transformation.maxScale, chartMaxZoom, reason: reason);
              }
            case ChartLibrary.graphic:
              final coord = tester
                  .widget<gr.Chart<Sample>>(find.byType(gr.Chart<Sample>))
                  .coord;
              if (zoom) {
                expect(coord, isA<gr.RectCoord>(), reason: reason);
                final rect = coord! as gr.RectCoord;
                expect(rect.horizontalRangeUpdater, isNotNull);
                expect(rect.verticalRangeUpdater, isNull);
              } else {
                expect(coord, isNull, reason: reason);
              }
            case ChartLibrary.syncfusion:
              final behavior = tester
                  .widget<sf.SfCartesianChart>(
                    find.byType(sf.SfCartesianChart),
                  )
                  .zoomPanBehavior;
              if (zoom) {
                expect(behavior, isNotNull, reason: reason);
                expect(behavior!.zoomMode, sf.ZoomMode.x);
                expect(behavior.enablePinching, isTrue);
                expect(behavior.enablePanning, isTrue);
                expect(behavior.enableMouseWheelZooming, isTrue);
              } else {
                expect(behavior, isNull, reason: reason);
              }
          }
        }
        await _end(tester);
        expect(_zoomRegistered, isFalse);
      });
    }
  }

  testWidgets('the Chart.js port has the zoom plugin only with the toggle', (
    tester,
  ) async {
    const off = BenchmarkConfig(count: 100);
    await _pump(tester, _scene(ChartLibrary.chartjs, off));
    expect(_zoomRegistered, isFalse);
    expect(_chart().isPluginEnabled('zoom'), isFalse);

    // The toggle mounts a new chart, with the plugin.
    await _pump(tester, _scene(ChartLibrary.chartjs, off.copyWith(zoom: true)));
    expect(_zoomRegistered, isTrue);
    expect(_chart().isPluginEnabled('zoom'), isTrue);

    // A new chart with zoom keeps it.
    await _pump(tester, const SizedBox());
    await _pump(tester, _scene(ChartLibrary.chartjs, off.copyWith(zoom: true)));
    expect(_chart().isPluginEnabled('zoom'), isTrue);

    // A type without an x axis runs no hook of the plugin.
    await _pump(
      tester,
      _scene(
        ChartLibrary.chartjs,
        off.copyWith(type: ChartType.pie, zoom: true),
      ),
    );
    expect(_zoomRegistered, isFalse);
    expect(_chart().isPluginEnabled('zoom'), isFalse);

    // Back to a chart without zoom.
    await _pump(tester, _scene(ChartLibrary.chartjs, off.copyWith(zoom: true)));
    await _pump(tester, _scene(ChartLibrary.chartjs, off));
    expect(_zoomRegistered, isFalse);
    expect(_chart().isPluginEnabled('zoom'), isFalse);
    await _end(tester);
  });

  testWidgets('the Chart.js port zooms and pans only x, inside the data', (
    tester,
  ) async {
    await _pump(
      tester,
      _scene(
        ChartLibrary.chartjs,
        const BenchmarkConfig(count: 100, zoom: true),
      ),
    );
    expect(_range('x'), (0, 100));
    final y = _range('y');

    // A zoom out or a drag at the full range changes nothing.
    await _wheel(tester, 60);
    expect(_range('x'), (0, 100));
    await _drag(tester, 150);
    expect(_range('x'), (0, 100));

    await _wheel(tester, -60);
    var (min, max) = _range('x');
    expect(min, greaterThan(0));
    expect(max, lessThan(100));
    expect(_range('y'), y);

    // A pinch along x zooms in more.
    final width = max - min;
    await _pinch(tester);
    (min, max) = _range('x');
    expect(max - min, lessThan(width));
    expect(_range('y'), y);

    // A drag to the right shows smaller values, with the same width.
    final zoomed = (min, max);
    await _drag(tester, 120);
    (min, max) = _range('x');
    expect(min, lessThan(zoomed.$1));
    expect(max - min, closeTo(zoomed.$2 - zoomed.$1, 1e-9));
    expect(_range('y'), y);

    // A drag never goes past the data: the step that would stops short.
    for (var i = 0; i < 8; i++) {
      await _drag(tester, 300);
    }
    expect(_range('x').$1, inInclusiveRange(0, min));

    // The zoom stops at 1/chartMaxZoom of the range.
    for (var i = 0; i < 80; i++) {
      await _wheel(tester, -60);
    }
    (min, max) = _range('x');
    expect(max - min, closeTo(100 / chartMaxZoom, 1e-9));
    expect(_range('y'), y);
    await _end(tester);
  });

  // The same gestures on each library, by the picture of the chart. Without
  // the toggle, the same gesture leaves the picture alone.
  for (final library in ChartLibrary.values) {
    testWidgets('${library.name}: the wheel zooms only with the toggle', (
      tester,
    ) async {
      for (final zoom in [true, false]) {
        await _pump(
          tester,
          _scene(library, BenchmarkConfig(count: 100, axes: true, zoom: zoom)),
        );
        final before = await _baseline(tester, library);
        // A zoom out at the full range changes nothing.
        await _wheel(tester, 60);
        expect(
          listEquals(await _pixels(tester), before),
          isTrue,
          reason: 'zoom out, zoom $zoom',
        );
        await _wheel(tester, -60);
        final zoomed = await _pixels(tester);
        expect(
          listEquals(zoomed, before),
          !zoom,
          reason: 'zoom in, zoom $zoom',
        );
        // A tick of a live run builds the chart again with new data, here
        // the same values, and keeps the zoom.
        await _pump(
          tester,
          _scene(
            library,
            BenchmarkConfig(count: 100, axes: true, zoom: zoom),
            step: 1,
          ),
        );
        expect(
          listEquals(await _pixels(tester), zoomed),
          isTrue,
          reason: 'tick, zoom $zoom',
        );
        await _end(tester);
      }
    });

    testWidgets('${library.name}: a pinch zooms and a drag pans', (
      tester,
    ) async {
      await _pump(
        tester,
        _scene(library, const BenchmarkConfig(count: 100, zoom: true)),
      );
      final full = await _baseline(tester, library);
      // A drag at the full range changes nothing.
      await _drag(tester, 150);
      expect(listEquals(await _pixels(tester), full), isTrue, reason: 'drag');
      await _pinch(tester);
      final zoomed = await _pixels(tester);
      expect(listEquals(zoomed, full), isFalse, reason: 'pinch');
      await _drag(tester, 150);
      expect(
        listEquals(await _pixels(tester), zoomed),
        isFalse,
        reason: 'pan',
      );
      await _end(tester);
    });
  }

  testWidgets('a zoom stays through live data, and a run starts at the full '
      'range', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late BenchmarkController c;
    await tester.pumpWidget(
      ChartBenchmarkApp(onControllerReady: (value) => c = value),
    );
    await tester.pump(const Duration(milliseconds: 20));
    await tester.ensureVisible(find.byKey(const ValueKey('feature.zoom')));
    await tester.tap(find.byKey(const ValueKey('feature.zoom')));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    expect(c.config.zoom, isTrue);
    expect(_range('x'), (0, 100));

    await _wheel(tester, -60);
    final zoomed = _range('x');
    expect(zoomed.$2 - zoomed.$1, lessThan(100));

    // New data keeps the range.
    final frame = c.frames.value;
    c.frames.value = DatasetGenerator(c.config.count, 8).frame(frame.step + 1);
    await tester.pump(const Duration(milliseconds: 20));
    expect(_range('x'), zoomed);

    final chart = _chart();
    c.start();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    expect(c.running, isTrue, reason: c.message);
    expect(_chart(), isNot(same(chart)));
    expect(_range('x'), (0, 100));
    expect(zp.ZoomChart(_chart()).isZoomedOrPanned(), isFalse);
    c.pause();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 20));
    expect(_zoomRegistered, isFalse);
  });
}
