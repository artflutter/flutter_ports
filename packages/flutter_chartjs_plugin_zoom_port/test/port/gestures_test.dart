// Original code, not ported from chartjs-plugin-zoom: real input to gestures.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/state.dart' show getState;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// The gesture manager of src/gestures.ts on a `ChartView` in a vertical
// `ListView`, driven by the touch events of Flutter through `WidgetTester`
// (design §5 item 5). The manager writes `touch-action: none` into the
// style of the canvas (`src/gestures.ts:198-201`). With it, the chart host
// begins no pan of its own and claims the touch pointers in the gesture
// arena (Chart.js ADR 0108 §8): the pointer events reach the manager, and
// the list does not scroll. The specs dispatch synthetic pointer events on
// the canvas instead (harness-dom-events).
//
// flutter_test_config.dart registers the built-in components and the plugin
// for each chart (harness-register-builtins).

/// The points of the scatter chart.
final List<DataPoint> _points = [
  DataPoint(10, 20),
  DataPoint(30, 60),
  DataPoint(50, 40),
  DataPoint(70, 80),
  DataPoint(90, 30),
];

/// A `ChartView` of a scatter chart on the linear scales `x` and `y` from 0
/// to 100, with no legend, no animation and the zoom options [zoom], at the
/// top of a vertical `ListView` with [controller], above a box of 1000 px.
Widget _listed(
  Map<String, Object?> zoom,
  ScrollController controller,
  ValueChanged<Chart> onChartCreated,
) => Directionality(
  textDirection: TextDirection.ltr,
  child: ListView(
    controller: controller,
    children: [
      SizedBox(
        height: 300,
        child: ChartView(
          config: ChartConfig(
            type: .scatter,
            datasets: [ScatterDataset(points: _points, pointRadius: 4)],
            scales: const {
              'x': LinearAxis(min: 0, max: 100),
              'y': LinearAxis(min: 0, max: 100),
            },
            maintainAspectRatio: false,
            legend: const ChartLegend(display: false),
            animation: ChartAnimation.none,
            extra: {
              'plugins': <String, Object?>{'zoom': zoom},
            },
          ),
          onChartCreated: onChartCreated,
        ),
      ),
      const SizedBox(height: 1000),
    ],
  ),
);

/// Pumps [_listed] and the frame of `onChartCreated`, and gives the chart.
Future<Chart> _start(
  WidgetTester tester,
  Map<String, Object?> zoom,
  ScrollController controller,
) async {
  Chart? created;
  await tester.pumpWidget(
    _listed(zoom, controller, (chart) => created = chart),
  );
  await tester.pump();
  return created!;
}

/// A new scroll controller, disposed at the end of the test.
ScrollController _controller() {
  final controller = ScrollController();
  addTearDown(controller.dispose);
  return controller;
}

/// The range of the scale [id] of [chart].
(double, double) _range(Chart chart, String id) =>
    (chart.scales[id]!.min, chart.scales[id]!.max);

/// The global point of the center of the chart area of [chart].
Offset _center(Chart chart) {
  final area = chart.chartArea!;
  final rect = chart.canvas!.getBoundingClientRect();
  return Offset(
    rect.left + ((area.left + area.right) / 2).roundToDouble(),
    rect.top + ((area.top + area.bottom) / 2).roundToDouble(),
  );
}

void main() {
  testWidgets('a one-finger pan with touch-action none in a vertical ListView '
      'pans and does not scroll the list', (tester) async {
    final controller = _controller();
    final completed = <Chart>[];
    final chart = await _start(tester, <String, Object?>{
      'pan': <String, Object?>{
        'enabled': true,
        'onPanComplete': (ZoomChartContext context) =>
            completed.add(context.chart),
      },
    }, controller);
    expect(chart.canvas!.style.touchAction, 'none');
    final y = chart.scales['y']!;
    final pixelsPerValue =
        (y.getPixelForValue(0) - y.getPixelForValue(100)) / 100;

    // Five moves of 20 px up: the list would scroll by about 100 px.
    final gesture = await tester.startGesture(_center(chart));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, -20));
    }
    expect(chart.isZoomingOrPanning(), isTrue);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.offset, 0);
    // The pan follows the finger by 100 px: the range of y moves down by
    // 100 px of values and keeps its size. x does not move.
    final (yMin, yMax) = _range(chart, 'y');
    expect(yMin, closeTo(-100 / pixelsPerValue, 1e-6));
    expect(yMax - yMin, closeTo(100, 1e-9));
    expect(_range(chart, 'x'), (0, 100));
    expect(chart.isZoomedOrPanned(), isTrue);
    expect(getState(chart).panning, isFalse);
    expect(completed, [chart]);
  });

  testWidgets('without pan and pinch, the same drag scrolls the list', (
    tester,
  ) async {
    final controller = _controller();
    final chart = await _start(tester, <String, Object?>{
      'zoom': <String, Object?>{
        'wheel': <String, Object?>{'enabled': true},
      },
    }, controller);
    expect(chart.canvas!.style.touchAction, isNot('none'));
    final gesture = await tester.startGesture(_center(chart));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, -20));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    expect(_range(chart, 'y'), (0, 100));
    expect(chart.isZoomedOrPanned(), isFalse);
  });

  testWidgets('a two-finger pinch zooms', (tester) async {
    final controller = _controller();
    final triggers = <ZoomTrigger>[];
    final completed = <Chart>[];
    final chart = await _start(tester, <String, Object?>{
      'zoom': <String, Object?>{
        'pinch': <String, Object?>{'enabled': true},
        'onZoom': (ZoomTriggerContext context) => triggers.add(context.trigger),
        'onZoomComplete': (ZoomChartContext context) =>
            completed.add(context.chart),
      },
    }, controller);
    expect(chart.canvas!.style.touchAction, 'none');
    final center = _center(chart);

    // Two fingers on a diagonal move apart to twice their distance: both
    // axes zoom in (`pinchAxes`, `src/gestures.ts:63-79`).
    final first = await tester.startGesture(center - const Offset(40, 30));
    final second = await tester.startGesture(center + const Offset(40, 30));
    for (var i = 0; i < 4; i++) {
      await first.moveBy(const Offset(-10, -7.5));
      await second.moveBy(const Offset(10, 7.5));
    }
    expect(triggers, everyElement(ZoomTrigger.pinch));
    expect(triggers, isNotEmpty);
    await first.up();
    expect(completed, [chart]);
    await second.up();
    await tester.pumpAndSettle();

    expect(controller.offset, 0);
    final (xMin, xMax) = _range(chart, 'x');
    final (yMin, yMax) = _range(chart, 'y');
    expect(xMax - xMin, lessThan(100));
    expect(yMax - yMin, lessThan(100));
    expect(xMin, greaterThan(0));
    expect(yMin, greaterThan(0));
    expect(chart.getZoomLevel(), greaterThan(1));
    expect(getState(chart).scale, isNull);
    expect(completed, [chart]);
  });

  testWidgets('two fingers in a row zoom only x', (tester) async {
    final controller = _controller();
    final chart = await _start(tester, <String, Object?>{
      'zoom': <String, Object?>{
        'pinch': <String, Object?>{'enabled': true},
      },
    }, controller);
    final center = _center(chart);
    final first = await tester.startGesture(center - const Offset(40, 0));
    final second = await tester.startGesture(center + const Offset(40, 0));
    for (var i = 0; i < 4; i++) {
      await first.moveBy(const Offset(-10, 0));
      await second.moveBy(const Offset(10, 0));
    }
    await first.up();
    await second.up();
    await tester.pumpAndSettle();

    expect(controller.offset, 0);
    final (xMin, xMax) = _range(chart, 'x');
    expect(xMax - xMin, lessThan(100));
    expect(_range(chart, 'y'), (0, 100));
  });
}
