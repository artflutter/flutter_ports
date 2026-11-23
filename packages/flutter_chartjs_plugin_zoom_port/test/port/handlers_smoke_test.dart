// Original code, not ported from chartjs-plugin-zoom: handler smoke tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

/// A scatter chart with the linear scales `x` and `y` from 0 to 100, and no
/// legend. The zoom plugin is not registered: each test sets the state
/// options and adds the listeners itself, and removes them at its end (the
/// document of the canvas outlives the chart).
Chart _acquireChart(ZoomPluginOptions options) {
  final chart = _acquire(
    ChartConfig(
      datasets: [
        ScatterDataset(data: .points([DataPoint(0, 0), DataPoint(100, 100)])),
      ],
      legend: const ChartLegend(display: false),
      scales: const [
        LinearAxis(.x, min: 0, max: 100),
        LinearAxis(.y, min: 0, max: 100),
      ],
    ),
  );
  getState(chart).options = options;
  addListeners(chart, options);
  addTearDown(() => removeListeners(chart));
  return chart;
}

/// A mouse event of [type] at the canvas pixel ([x], [y]) of [chart].
NativeEvent _mouse(
  Chart chart,
  String type,
  double x,
  double y, {
  bool shiftKey = false,
}) {
  final rect = chart.canvas!.getBoundingClientRect();
  return NativeEvent(
    type: type,
    offsetX: x,
    offsetY: y,
    clientX: rect.left + x,
    clientY: rect.top + y,
    bubbles: true,
    cancelable: true,
    shiftKey: shiftKey,
  );
}

/// Acquires a chart through the typed config boundary.
Chart _acquire(ChartConfig config, [Map<String, Object?>? options]) =>
    acquireChartRoot(ChartConfigLowering(config).lower(), options);

void main() {
  testWidgets('computeDragRect clamps the drag to the enabled directions', (
    tester,
  ) async {
    final chart = _acquireChart(const ZoomPluginOptions());
    final area = chart.chartArea!;
    final left = area.left.ceilToDouble() + 10;
    final top = area.top.ceilToDouble() + 10;
    final start = _mouse(chart, 'mousedown', left, top);
    final end = _mouse(chart, 'mousemove', left + 50, top + 30);
    chart.canvas!.dispatchEvent(start);
    chart.canvas!.dispatchEvent(end);

    final xy = computeDragRect(chart, Mode.xy, (
      dragStart: start,
      dragEnd: end,
    ), false);
    expect(xy.left, left);
    expect(xy.right, left + 50);
    expect(xy.top, top);
    expect(xy.bottom, top + 30);
    expect(xy.width, 50);
    expect(xy.height, 30);
    expect(xy.zoomX, 1 + (area.width - 50) / area.width);
    expect(xy.zoomY, 1 + (area.height - 30) / area.height);

    final x = computeDragRect(chart, Mode.x, (
      dragStart: start,
      dragEnd: end,
    ), false);
    expect(x.top, area.top);
    expect(x.bottom, area.bottom);
    expect(x.width, 50);
    expect(x.zoomY, 1);
  });

  testWidgets('a drag zooms to its rectangle and calls onZoomComplete', (
    tester,
  ) async {
    final calls = <ZoomChartContext>[];
    final chart = _acquireChart(
      ZoomPluginOptions(
        zoom: ZoomOptions(
          drag: const DragOptions(enabled: true),
          onZoomComplete: calls.add,
        ),
      ),
    );
    final area = chart.chartArea!;
    final left = area.left.ceilToDouble() + 10;
    final top = area.top.ceilToDouble() + 10;
    final scale = chart.scales['x']!;
    final from = scale.getValueForPixel(left)!;
    final to = scale.getValueForPixel(left + 50)!;
    final canvas = chart.canvas!;
    final state = getState(chart);

    canvas.dispatchEvent(_mouse(chart, 'mousedown', left, top));
    expect(state.dragStart, isNotNull);
    canvas.dispatchEvent(_mouse(chart, 'mousemove', left + 50, top + 30));
    expect(state.dragging, isTrue);
    canvas.dispatchEvent(_mouse(chart, 'mouseup', left + 50, top + 30));

    expect(state.dragStart, isNull);
    expect(state.dragging, isFalse);
    expect(state.filterNextClick, isTrue);
    expect(scale.min, closeTo(from, 1e-9));
    expect(scale.max, closeTo(to, 1e-9));
    expect(calls, [(chart: chart)]);
  });

  testWidgets('Escape on the document cancels a drag', (tester) async {
    final chart = _acquireChart(
      const ZoomPluginOptions(
        zoom: ZoomOptions(drag: DragOptions(enabled: true)),
      ),
    );
    final area = chart.chartArea!;
    final canvas = chart.canvas!;
    final document = canvas.ownerDocument;
    canvas.dispatchEvent(
      _mouse(chart, 'mousedown', area.left + 10, area.top + 10),
    );
    expect(getState(chart).targets[HandlerName.keydown], document);

    document.dispatchEvent(
      NativeEvent(
        type: 'keydown',
        offsetX: double.nan,
        offsetY: double.nan,
        key: 'Escape',
      ),
    );

    final state = getState(chart);
    expect(state.dragStart, isNull);
    expect(state.dragging, isFalse);
    expect(state.handlers.containsKey(HandlerName.keydown), isFalse);
  });

  testWidgets('a drag without the modifier key calls onZoomRejected', (
    tester,
  ) async {
    final rejected = <ZoomEventContext<NativeEvent>>[];
    final chart = _acquireChart(
      ZoomPluginOptions(
        zoom: ZoomOptions(
          drag: const DragOptions(
            enabled: true,
            modifierKey: ModifierKey.shift,
          ),
          onZoomRejected: rejected.add,
        ),
      ),
    );
    final area = chart.chartArea!;
    final event = _mouse(chart, 'mousedown', area.left + 10, area.top + 10);
    chart.canvas!.dispatchEvent(event);

    expect(getState(chart).dragStart, isNull);
    expect(rejected, [(chart: chart, event: event)]);

    chart.canvas!.dispatchEvent(
      _mouse(chart, 'mousedown', area.left + 10, area.top + 10, shiftKey: true),
    );
    expect(getState(chart).dragStart, isNotNull);
  });

  testWidgets('a wheel notch up zooms in and cancels the event', (
    tester,
  ) async {
    final chart = _acquireChart(
      const ZoomPluginOptions(
        zoom: ZoomOptions(wheel: WheelOptions(enabled: true)),
      ),
    );
    final area = chart.chartArea!;
    final rect = chart.canvas!.getBoundingClientRect();
    final x = area.left + area.width / 2;
    final y = area.top + area.height / 2;
    final event = NativeEvent(
      type: 'wheel',
      offsetX: x,
      offsetY: y,
      clientX: rect.left + x,
      clientY: rect.top + y,
      cancelable: true,
      deltaY: -24,
    );

    chart.canvas!.dispatchEvent(event);

    expect(event.defaultPrevented, isTrue);
    final scale = chart.scales['x']!;
    expect(scale.max - scale.min, lessThan(100));
    expect(scale.min, greaterThan(0));
    expect(scale.max, lessThan(100));
  });

  testWidgets('removeListeners removes the listeners of addListeners', (
    tester,
  ) async {
    final chart = _acquireChart(
      const ZoomPluginOptions(
        zoom: ZoomOptions(
          wheel: WheelOptions(enabled: true),
          drag: DragOptions(enabled: true),
        ),
      ),
    );
    final state = getState(chart);
    expect(state.handlers.keys, [
      HandlerName.wheel,
      HandlerName.mousedown,
      HandlerName.mouseup,
    ]);
    expect(state.targets[HandlerName.wheel], chart.canvas!.eventTarget);
    expect(state.targets[HandlerName.mouseup], chart.canvas!.ownerDocument);

    removeListeners(chart);

    expect(state.handlers, isEmpty);
    final area = chart.chartArea!;
    chart.canvas!.dispatchEvent(
      _mouse(chart, 'mousedown', area.left + 10, area.top + 10),
    );
    expect(state.dragStart, isNull);
  });
}
