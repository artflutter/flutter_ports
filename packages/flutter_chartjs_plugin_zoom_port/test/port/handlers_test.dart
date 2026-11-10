// Original code, not ported from chartjs-plugin-zoom: real input to handlers.
@TestOn('vm')
library;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/state.dart'
    show HandlerName, getState;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// The listeners of src/handlers.ts on a `ChartView`, driven by the pointer
// and key events of Flutter through `WidgetTester` (design §5 item 5): the
// chart host turns them into the DOM events of Chart.js ADR 0108. The specs
// dispatch synthetic events on the canvas instead (harness-dom-events).
//
// - A wheel over the chart zooms, and its listener prevents the default: a
//   parent `ListView` does not scroll (`src/handlers.ts:234-236`).
// - A mouse drag that leaves the box and lifts outside it zooms: the
//   `mousemove` and `mouseup` listeners are on the document of the canvas
//   (`src/handlers.ts:109`, `:306`). A press on the legend starts no drag
//   (`src/handlers.ts:88-93`).
// - Escape cancels a drag with no focus on the chart: the `keydown`
//   listener is on the document (`src/handlers.ts:53-63`, `:110`).
// - Enter on a keyboard target of the chart sends `mousedown` and `mouseup`
//   at the target (Chart.js ADR 0051): the drag that the down starts ends at
//   the document `mouseup` of the same key.
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

/// A scatter chart on the linear scales `x` and `y` from 0 to 100, with no
/// animation and the zoom options [zoom], with a legend for [legend].
ChartConfig _config(Map<String, Object?> zoom, {bool legend = false}) =>
    ChartConfig(
      type: .scatter,
      datasets: [ScatterDataset(points: _points, pointRadius: 4)],
      scales: const {
        'x': LinearAxis(min: 0, max: 100),
        'y': LinearAxis(min: 0, max: 100),
      },
      maintainAspectRatio: false,
      legend: ChartLegend(display: legend),
      animation: ChartAnimation.none,
      extra: {
        'plugins': <String, Object?>{'zoom': zoom},
      },
    );

/// A `ChartView` of [_config] in a box of 400 x 300 at the top left of the
/// view, so that the canvas pixels are the global logical pixels.
Widget _view(
  Map<String, Object?> zoom, {
  required ValueChanged<Chart> onChartCreated,
  FocusNode? focusNode,
  bool legend = false,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 400,
      height: 300,
      child: ChartView(
        config: _config(zoom, legend: legend),
        focusNode: focusNode,
        onChartCreated: onChartCreated,
      ),
    ),
  ),
);

/// Pumps [view] and the frame of `onChartCreated`, and gives the chart.
Future<Chart> _start(
  WidgetTester tester,
  Widget Function(ValueChanged<Chart> onChartCreated) view,
) async {
  Chart? created;
  await tester.pumpWidget(view((chart) => created = chart));
  await tester.pump();
  return created!;
}

/// The range of the scale [id] of [chart].
(double, double) _range(Chart chart, String id) =>
    (chart.scales[id]!.min, chart.scales[id]!.max);

/// The global point of the canvas pixel ([x], [y]) of [chart].
Offset _global(Chart chart, double x, double y) {
  final rect = chart.canvas!.getBoundingClientRect();
  return Offset(rect.left + x, rect.top + y);
}

/// The center of the chart area of [chart], in canvas pixels.
({double x, double y}) _center(Chart chart) {
  final area = chart.chartArea!;
  return (
    x: ((area.left + area.right) / 2).roundToDouble(),
    y: ((area.top + area.bottom) / 2).roundToDouble(),
  );
}

void main() {
  group('wheel', () {
    /// A `ChartView` of [zoom] at the top of a vertical `ListView` with
    /// [controller], above a box of 1000 px.
    Widget listed(
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
              config: _config(zoom),
              onChartCreated: onChartCreated,
            ),
          ),
          const SizedBox(height: 1000),
        ],
      ),
    );

    testWidgets('a wheel over a ChartView in a ListView zooms and does not '
        'scroll the list', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final completed = <ZoomChartContext>[];
      void onZoomComplete(ZoomChartContext context) => completed.add(context);
      final zoom = <String, Object?>{
        'zoom': <String, Object?>{
          'wheel': <String, Object?>{'enabled': true},
          'onZoomComplete': onZoomComplete,
        },
      };
      final chart = await _start(
        tester,
        (onChartCreated) => listed(zoom, controller, onChartCreated),
      );
      final center = _center(chart);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(_global(chart, center.x, center.y)),
      );

      // A scroll down is a wheel with a positive deltaY: it zooms out. The
      // list would scroll down by 60 px.
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 60)));
      await tester.pump();
      expect(controller.offset, 0);
      final (xMin, xMax) = _range(chart, 'x');
      expect(xMin, lessThan(0));
      expect(xMax, greaterThan(100));
      expect(_range(chart, 'y').$1, lessThan(0));
      expect(chart.isZoomedOrPanned(), isTrue);
      expect(chart.getZoomLevel(), lessThan(1));

      // A scroll up, 100 ms later, zooms in again.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -60)));
      await tester.pump();
      expect(controller.offset, 0);
      expect(
        _range(chart, 'x').$2 - _range(chart, 'x').$1,
        lessThan(xMax - xMin),
      );

      // onZoomComplete runs 250 ms after each wheel event, as upstream: the
      // wheel listener calls the debounced handler of the state
      // (`src/handlers.ts:253-256`, `:277`), and the update of its zoom runs
      // `beforeUpdate`, whose `addListeners` puts a new debounced handler
      // into the state (`src/handlers.ts:280-289`, `:300`). Thus the second
      // wheel calls another debounced function than the first.
      expect(completed, isEmpty);
      await tester.pump(const Duration(milliseconds: 149));
      expect(completed, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(completed, [(chart: chart)]);
      await tester.pump(const Duration(milliseconds: 99));
      expect(completed, hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(completed, [(chart: chart), (chart: chart)]);
    });

    testWidgets('without wheel zoom, the wheel scrolls the list', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final zoom = <String, Object?>{
        'zoom': <String, Object?>{
          'drag': <String, Object?>{'enabled': true},
        },
      };
      final chart = await _start(
        tester,
        (onChartCreated) => listed(zoom, controller, onChartCreated),
      );
      final center = _center(chart);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(_global(chart, center.x, center.y)),
      );
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 60)));
      await tester.pump();
      expect(controller.offset, 60);
      expect(_range(chart, 'x'), (0, 100));
      expect(chart.isZoomedOrPanned(), isFalse);
    });
  });

  group('drag', () {
    final dragZoom = <String, Object?>{
      'zoom': <String, Object?>{
        'drag': <String, Object?>{'enabled': true},
      },
    };

    testWidgets('a mouse drag that leaves the box and lifts outside it zooms '
        'to the part of the drag in the chart area', (tester) async {
      final completed = <Chart>[];
      final zoom = <String, Object?>{
        'zoom': <String, Object?>{
          'drag': <String, Object?>{'enabled': true},
          'onZoomComplete': (ZoomChartContext context) =>
              completed.add(context.chart),
        },
      };
      final chart = await _start(
        tester,
        (onChartCreated) => _view(zoom, onChartCreated: onChartCreated),
      );
      final area = chart.chartArea!;
      final x = chart.scales['x']!;
      final y = chart.scales['y']!;
      // Whole pixels: getRelativePosition rounds the offsets of the down.
      final left = area.left.ceilToDouble() + 20;
      final top = area.top.ceilToDouble() + 20;
      final bottom = top + 100;
      final xFrom = x.getValueForPixel(left)!;
      final xTo = x.getValueForPixel(area.right)!;
      final yFrom = y.getValueForPixel(top)!;
      final yTo = y.getValueForPixel(bottom)!;

      final gesture = await tester.startGesture(
        _global(chart, left, top),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(_global(chart, left + 60, top + 40));
      expect(chart.isZoomingOrPanning(), isTrue);
      // Out of the box of 400 px: the document gets the move and the up,
      // with the client point of the mouse.
      await gesture.moveTo(_global(chart, 460, bottom));
      expect(getState(chart).dragEnd!.clientX, 460);
      await gesture.up();
      await tester.pump();

      final state = getState(chart);
      expect(state.dragStart, isNull);
      expect(state.dragging, isFalse);
      expect(x.min, closeTo(xFrom, 1e-9));
      expect(x.max, closeTo(xTo, 1e-9));
      // The y scale grows upward: the top pixel has the larger value.
      expect(y.min, closeTo(yTo, 1e-9));
      expect(y.max, closeTo(yFrom, 1e-9));
      expect(completed, [chart]);
      expect(chart.isZoomedOrPanned(), isTrue);
    });

    testWidgets('a mouse drag that starts on the legend starts no drag', (
      tester,
    ) async {
      // `mouseDown` returns for a point in the legend box
      // (`src/handlers.ts:88-93`, seam H2).
      final chart = await _start(
        tester,
        (onChartCreated) => _view(
          dragZoom,
          legend: true,
          onChartCreated: onChartCreated,
        ),
      );
      final legend = chart.legend!;
      final area = chart.chartArea!;
      expect(legend.bottom, lessThanOrEqualTo(area.top));
      final gesture = await tester.startGesture(
        _global(
          chart,
          ((legend.left + legend.right) / 2).roundToDouble(),
          ((legend.top + legend.bottom) / 2).roundToDouble(),
        ),
        kind: PointerDeviceKind.mouse,
      );
      expect(getState(chart).dragStart, isNull);
      await gesture.moveTo(_global(chart, area.left + 200, area.top + 150));
      expect(chart.isZoomingOrPanning(), isFalse);
      await gesture.up();
      await tester.pump();
      expect(_range(chart, 'x'), (0, 100));
      expect(_range(chart, 'y'), (0, 100));

      // A drag in the chart area below it zooms.
      final left = area.left.ceilToDouble() + 20;
      final top = area.top.ceilToDouble() + 20;
      final inArea = await tester.startGesture(
        _global(chart, left, top),
        kind: PointerDeviceKind.mouse,
      );
      expect(getState(chart).dragStart, isNotNull);
      await inArea.moveTo(_global(chart, left + 100, top + 80));
      await inArea.up();
      await tester.pump();
      expect(chart.isZoomedOrPanned(), isTrue);
    });

    testWidgets('Escape cancels a drag while the chart has no focus', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final chart = await _start(
        tester,
        (onChartCreated) => _view(
          dragZoom,
          focusNode: node,
          onChartCreated: onChartCreated,
        ),
      );
      final area = chart.chartArea!;
      final left = area.left.ceilToDouble() + 20;
      final top = area.top.ceilToDouble() + 20;
      final gesture = await tester.startGesture(
        _global(chart, left, top),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(_global(chart, left + 80, top + 60));
      final state = getState(chart);
      expect(state.dragging, isTrue);
      expect(state.targets[HandlerName.keydown], chart.canvas!.ownerDocument);
      // A drag on the chart does not focus it.
      expect(node.hasFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(state.dragStart, isNull);
      expect(state.dragEnd, isNull);
      expect(state.dragging, isFalse);
      expect(state.handlers.containsKey(HandlerName.keydown), isFalse);

      // The up ends no drag: the range stays.
      await gesture.up();
      await tester.pump();
      expect(_range(chart, 'x'), (0, 100));
      expect(_range(chart, 'y'), (0, 100));
      expect(chart.isZoomingOrPanning(), isFalse);
      expect(chart.isZoomedOrPanned(), isFalse);
    });

    testWidgets('Enter, Enter on a keyboard target leaves no drag state', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final chart = await _start(
        tester,
        (onChartCreated) => _view(
          dragZoom,
          focusNode: node,
          onChartCreated: onChartCreated,
        ),
      );
      node.requestFocus();
      await tester.pump();

      /// Sends [key] and pumps the frame of the throttled chart events.
      Future<void> key(LogicalKeyboardKey key) async {
        await tester.sendKeyEvent(key);
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Down moves the virtual mouse to the first point.
      await key(LogicalKeyboardKey.arrowDown);
      expect(
        [
          for (final active in chart.getActiveElements())
            (active.datasetIndex, active.index),
        ],
        [(0, 0)],
      );

      // Each Enter sends mousedown, mouseup and click at the point: the down
      // starts a drag, and the up on the document ends it with no zoom. A
      // canvas listener after the one of the zoom sees the drag start.
      final state = getState(chart);
      final started = <bool>[];
      void onDown(NativeEvent event) => started.add(state.dragStart == event);
      final canvas = chart.canvas!..addEventListener('mousedown', onDown);
      addTearDown(() => canvas.removeEventListener('mousedown', onDown));
      await key(LogicalKeyboardKey.enter);
      await key(LogicalKeyboardKey.enter);
      expect(started, [true, true]);
      expect(state.dragStart, isNull);
      expect(state.dragEnd, isNull);
      expect(state.dragging, isFalse);
      expect(state.filterNextClick, isFalse);
      expect(state.handlers.containsKey(HandlerName.mousemove), isFalse);
      expect(chart.isZoomingOrPanning(), isFalse);
      expect(chart.isZoomedOrPanned(), isFalse);

      // The next move of the virtual mouse reaches the chart: the zoom does
      // not block its events.
      await key(LogicalKeyboardKey.arrowRight);
      expect(state.dragging, isFalse);
      expect(
        [
          for (final active in chart.getActiveElements())
            (active.datasetIndex, active.index),
        ],
        [(0, 1)],
      );
    });
  });
}
