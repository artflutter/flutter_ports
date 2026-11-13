// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/handlers.ts (MIT, chartjs-plugin-zoom contributors).

/// The mouse and wheel handlers of the plugin: the drag-to-zoom rectangle
/// and the wheel zoom.
///
/// The listeners go to the canvas and to its document through the DOM
/// members that the host gives each canvas (the extension
/// `CanvasEventTarget`, Chart.js ADR 0108): `canvas.eventTarget` is the
/// canvas as an event target, one object for each canvas, and
/// `canvas.ownerDocument` is the one document of the isolate. `State.targets`
/// keeps the target of each listener (differences.md row
/// `adapt-canvas-event-target`).
///
/// A user callback has its typedef type (`RejectEvent`,
/// `RejectableStartEvent`, `GenericEvent`) and gets a direct call (Zoom ADR
/// 0004).
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_plugin_zoom_port/src/core.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/options.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/state.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/types.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/utils.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show
        CanvasEventTarget,
        Chart,
        ChartArea,
        HTMLCanvasElement,
        NativeEvent,
        NativeEventTarget;
import 'package:flutter_chartjs_port/helpers.dart'
    show
        getRelativePosition,
        isNullOrUndef,
        isPointInArea,
        sign,
        valueOrDefault;
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsMax, jsMin, jsToNumber, jsTruthy;

/// `value ?? {}`: [emptyObject] for `null` and `undefined`.
Object? _orEmpty(Object? value) => isNullOrUndef(value) ? emptyObject : value;

/// handlers.ts:9 `clamp(x, from, to)`.
double _clamp(double x, double from, double to) => jsMin(to, jsMax(from, x));

/// handlers.ts:11 `removeHandler(chart, type)`: removes the listener
/// [type] of [chart] from its target.
///
/// Upstream keeps `targets[type]`.
void _removeHandler(Chart chart, HandlerName type) {
  final State(:handlers, :targets) = getState(chart);
  final handler = handlers[type];
  final target = targets[type];
  if (handler != null && target != null) {
    target.removeEventListener(type.name, handler);
    handlers.remove(type);
  }
}

/// handlers.ts:23 `addHandler(chart, target, type, handler)`: adds the
/// listener [type] of [chart] to [target], unless [target] already has it.
///
/// [target] is `canvas.eventTarget` or `canvas.ownerDocument`, one object
/// for each canvas or document, so the test `targets[type] === target`
/// compares the same objects as upstream.
///
/// [handler] has the type handlers.ts:21 `EventHandler<T>` without its third
/// parameter `options`: the listener of upstream passes the plugin options
/// as a third argument, and each handler of upstream declares two
/// parameters, so JavaScript drops that argument.
// DIVERGES(zoom): adapt-canvas-event-target, a NativeEventTarget target.
void _addHandler(
  Chart chart,
  NativeEventTarget target,
  HandlerName type,
  void Function(Chart chart, NativeEvent event) handler,
) {
  // const { handlers, options, targets } = getState(chart): no handler reads
  // `options`.
  final State(:handlers, :targets) = getState(chart);
  final oldHandler = handlers[type];
  if (oldHandler != null && identical(targets[type], target)) {
    // already attached
    return;
  }
  _removeHandler(chart, type);
  final listener = handlers[type] = (event) => handler(chart, event);
  targets[type] = target;

  // `passive: false` for wheel events, to prevent chrome warnings. Use
  // default value for other events.
  final passive = type == HandlerName.wheel ? false : null;
  target.addEventListener(type.name, listener, passive: passive);
}

/// handlers.ts:44 `mouseMove(chart, event)`: the `mousemove` listener of the
/// document during a drag. It keeps [event] as the end of the drag and draws
/// [chart].
void mouseMove(Chart chart, NativeEvent event) {
  final state = getState(chart);
  if (state.dragStart != null) {
    state
      ..dragging = true
      ..dragEnd = event;
    chart.draw();
  }
}

/// handlers.ts:53 `keyDown(chart, event)`: the `keydown` listener of the
/// document during a drag. Escape cancels the drag.
void _keyDown(Chart chart, NativeEvent event) {
  final state = getState(chart);
  if (state.dragStart == null || event.key != 'Escape') {
    return;
  }

  _removeHandler(chart, HandlerName.keydown);
  state
    ..dragging = false
    ..dragStart = null
    ..dragEnd = null;
  chart.draw();
}

/// handlers.ts:65 `getPointPosition(event, chart)`: the position of the
/// mouse [event] in canvas pixels.
///
/// An event of the document (a `mouseup` outside the canvas) gives its
/// client position from the canvas box. An event of the canvas gives the
/// position of `getRelativePosition`, whose `null` coordinates are 0 (the
/// `ToNumber` of `null`).
Point _getPointPosition(NativeEvent event, Chart chart) {
  if (!identical(event.target, chart.canvas)) {
    final canvasArea = chart.canvas!.getBoundingClientRect();
    return (
      x: event.clientX - canvasArea.left,
      y: event.clientY - canvasArea.top,
    );
  }
  final position = getRelativePosition(event, chart);
  return (x: position.x ?? 0, y: position.y ?? 0);
}

/// handlers.ts:76 `zoomStart(chart, event, zoomOptions)`: calls
/// `onZoomStart`, and `onZoomRejected` when `onZoomStart` gives `false`.
///
/// Upstream gives `false` for a rejected zoom, else `undefined`. The port
/// gives `false` and `true`: each caller tests only for `false`.
bool _zoomStart(Chart chart, NativeEvent event, ZoomOptions zoomOptions) {
  final onZoomStart = zoomOptions.onZoomStart;
  final onZoomRejected = zoomOptions.onZoomRejected;
  if (onZoomStart != null) {
    final point = _getPointPosition(event, chart);
    if (!onZoomStart((chart: chart, event: event, point: point))) {
      onZoomRejected?.call((chart: chart, event: event));
      return false;
    }
  }
  return true;
}

/// handlers.ts:87 `mouseDown(chart, event)`: the `mousedown` listener of the
/// canvas. It starts a drag, unless the event is over the legend, is not of
/// the main button, has the modifier key of the pan or misses the modifier
/// key of the drag.
void mouseDown(Chart chart, NativeEvent event) {
  if (chart.legend case final legend?) {
    final point = getRelativePosition(event, chart);
    if (isPointInArea(point, legend)) {
      return;
    }
  }
  final state = getState(chart);
  // const { pan: panOptions, zoom: zoomOptions = {} } = state.options
  final panOptions = state.options.pan;
  final zoomOptions = ZoomOptions(
    valueOrDefault<Object?>(state.options.zoom.raw, emptyObject),
  );
  if (event.button != 0 ||
      keyPressed(getModifierKey(panOptions), event) ||
      keyNotPressed(getModifierKey(zoomOptions.drag), event)) {
    // return zoomOptions.onZoomRejected?.({ chart, event })
    zoomOptions.onZoomRejected?.call((chart: chart, event: event));
    return;
  }

  if (!_zoomStart(chart, event, zoomOptions)) {
    return;
  }
  state.dragStart = event;

  _addHandler(
    chart,
    chart.canvas!.ownerDocument,
    HandlerName.mousemove,
    mouseMove,
  );
  // DIVERGES(zoom): adapt-canvas-event-target, the document of the canvas.
  _addHandler(
    chart,
    chart.canvas!.ownerDocument,
    HandlerName.keydown,
    _keyDown,
  );
}

/// The points `{ begin, end }` of a drag in canvas pixels
/// (handlers.ts:114, :147). `applyAspectRatio` changes [end].
final class _Points({required final Point begin, required var Point end});

/// handlers.ts:113 `applyAspectRatio({ begin, end }, aspectRatio)`: moves
/// the end of [points] so that the drag rectangle has [aspectRatio].
void _applyAspectRatio(_Points points, double aspectRatio) {
  final _Points(:begin, :end) = points;
  var width = end.x - begin.x;
  var height = end.y - begin.y;
  final ratio = (width / height).abs();

  if (ratio > aspectRatio) {
    width = sign(width) * (height * aspectRatio).abs();
  } else if (ratio < aspectRatio) {
    height = sign(height) * (width / aspectRatio).abs();
  }

  points.end = (x: begin.x + width, y: begin.y + height);
}

/// handlers.ts:131 `Rect`: the edges of the drag rectangle while
/// `computeDragRect` builds it.
final class _Rect({
  required var double top,
  required var double left,
  required var double right,
  required var double bottom,
});

/// handlers.ts:132 `applyMinMaxProps(rect, chartArea, points, { min, max,
/// prop })`: sets two edges of [rect] to the drag [points], inside
/// [chartArea].
///
/// The names of upstream come in two sets: `{ min: 'left', max: 'right',
/// prop: 'x' }` and `{ min: 'top', max: 'bottom', prop: 'y' }`. The port
/// takes the axis [prop] of the set.
void _applyMinMaxProps(
  _Rect rect,
  ChartArea chartArea,
  _Points points,
  String prop,
) {
  final _Points(:begin, :end) = points;
  if (prop == 'x') {
    rect
      ..left = _clamp(jsMin(begin.x, end.x), chartArea.left, chartArea.right)
      ..right = _clamp(jsMax(begin.x, end.x), chartArea.left, chartArea.right);
  } else {
    rect
      ..top = _clamp(jsMin(begin.y, end.y), chartArea.top, chartArea.bottom)
      ..bottom = _clamp(jsMax(begin.y, end.y), chartArea.top, chartArea.bottom);
  }
}

/// handlers.ts:142 `getRelativePoints(chart, pointEvents,
/// maintainAspectRatio)`: the drag points of the start and end events, in
/// canvas pixels.
_Points _getRelativePoints(
  Chart chart,
  ({NativeEvent dragStart, NativeEvent dragEnd}) pointEvents,
  bool maintainAspectRatio,
) {
  final points = _Points(
    begin: _getPointPosition(pointEvents.dragStart, chart),
    end: _getPointPosition(pointEvents.dragEnd, chart),
  );

  if (maintainAspectRatio) {
    final chartArea = chart.chartArea!;
    final aspectRatio = chartArea.width / chartArea.height;
    _applyAspectRatio(points, aspectRatio);
  }

  return points;
}

/// The result of [computeDragRect] (handlers.ts:183-190): the drag
/// rectangle in canvas pixels, and the zoom factor of each axis.
final class const DragRect({
  /// The top edge.
  required final double top,

  /// The left edge.
  required final double left,

  /// The right edge.
  required final double right,

  /// The bottom edge.
  required final double bottom,

  /// `right - left`.
  required final double width,

  /// `bottom - top`.
  required final double height,

  /// The zoom factor of the x axis: 1 when the x direction is off or the
  /// rectangle has no width.
  required final double zoomX,

  /// The zoom factor of the y axis: 1 when the y direction is off or the
  /// rectangle has no height.
  required final double zoomY,
}) {
  /// A drag rectangle.
  this;
}

/// handlers.ts:160 `computeDragRect(chart, mode, pointEvents,
/// maintainAspectRatio)`: the rectangle of a drag from
/// `pointEvents.dragStart` to `pointEvents.dragEnd`, inside the chart area
/// of [chart].
///
/// A direction that the [Mode] or the `ModeFn` [mode] does not enable spans
/// the chart area. [maintainAspectRatio] keeps the aspect ratio of the chart
/// area when both directions are enabled.
DragRect computeDragRect(
  Chart chart,
  Object? mode,
  ({NativeEvent dragStart, NativeEvent dragEnd}) pointEvents,
  Object? maintainAspectRatio,
) {
  final xEnabled = directionEnabled(mode, 'x', chart);
  final yEnabled = directionEnabled(mode, 'y', chart);
  final ChartArea(
    :top,
    :left,
    :right,
    :bottom,
    width: chartWidth,
    height: chartHeight,
  ) = chart.chartArea!;
  final rect = _Rect(top: top, left: left, right: right, bottom: bottom);

  final points = _getRelativePoints(
    chart,
    pointEvents,
    jsTruthy(maintainAspectRatio) && xEnabled && yEnabled,
  );

  if (xEnabled) {
    _applyMinMaxProps(rect, chart.chartArea!, points, 'x');
  }

  if (yEnabled) {
    _applyMinMaxProps(rect, chart.chartArea!, points, 'y');
  }

  final width = rect.right - rect.left;
  final height = rect.bottom - rect.top;

  return DragRect(
    top: rect.top,
    left: rect.left,
    right: rect.right,
    bottom: rect.bottom,
    width: width,
    height: height,
    zoomX: xEnabled && jsTruthy(width)
        ? 1 + (chartWidth - width) / chartWidth
        : 1,
    zoomY: yEnabled && jsTruthy(height)
        ? 1 + (chartHeight - height) / chartHeight
        : 1,
  );
}

/// handlers.ts:193 `mouseUp(chart, event)`: the `mouseup` listener of the
/// document. It ends a drag: a drag longer than `drag.threshold` zooms to
/// its rectangle.
void mouseUp(Chart chart, NativeEvent event) {
  final state = getState(chart);
  final dragStart = state.dragStart;
  if (dragStart == null) {
    return;
  }

  _removeHandler(chart, HandlerName.mousemove);
  // const { mode, onZoomComplete, drag } = state.options.zoom ?? {}
  final zoomOptions = ZoomOptions(_orEmpty(state.options.zoom.raw));
  final mode = zoomOptions.mode;
  final onZoomComplete = zoomOptions.onZoomComplete;
  final drag = zoomOptions.drag;
  // const { threshold = 0, maintainAspectRatio } = drag ?? {}
  final dragOptions = DragOptions(_orEmpty(drag.raw));
  final threshold = valueOrDefault<Object?>(dragOptions.threshold, 0);
  final maintainAspectRatio = dragOptions.maintainAspectRatio;
  final rect = computeDragRect(chart, mode, (
    dragStart: dragStart,
    dragEnd: event,
  ), maintainAspectRatio);
  final distanceX = directionEnabled(mode, 'x', chart) ? rect.width : 0.0;
  final distanceY = directionEnabled(mode, 'y', chart) ? rect.height : 0.0;
  final distance = math.sqrt(distanceX * distanceX + distanceY * distanceY);

  // Remove drag start and end before chart render to stop drawing selected
  // area
  state
    ..dragStart = null
    ..dragEnd = null;

  if (distance <= jsToNumber(threshold)) {
    state.dragging = false;
    chart.draw();
    return;
  }

  zoomRect(
    chart,
    (x: rect.left, y: rect.top),
    (x: rect.right, y: rect.bottom),
    'zoom',
    ZoomTrigger.drag,
  );

  state
    ..dragging = false
    ..filterNextClick = true;
  onZoomComplete?.call((chart: chart));
}

/// handlers.ts:223 `wheelPreconditions(chart, event, zoomOptions)`: whether
/// the wheel [event] zooms. It calls `onZoomRejected` without the modifier
/// key, calls `onZoomStart`, and cancels the default of the event.
///
/// Upstream gives `true` or `undefined`.
bool _wheelPreconditions(
  Chart chart,
  NativeEvent event,
  ZoomOptions zoomOptions,
) {
  // Before preventDefault, check if the modifier key required and pressed
  if (keyNotPressed(getModifierKey(zoomOptions.wheel), event)) {
    zoomOptions.onZoomRejected?.call((chart: chart, event: event));
    return false;
  }

  if (!_zoomStart(chart, event, zoomOptions)) {
    return false;
  }

  // Prevent the event from triggering the default behavior (e.g. content
  // scrolling).
  if (event.cancelable) {
    event.preventDefault();
  }

  // Firefox always fires the wheel event twice:
  // First without the delta and right after that once with the delta
  // properties.
  //
  // `if (event.deltaY === undefined) return`: `deltaY` of a native event is
  // a number, never `undefined`.
  return true;
}

/// handlers.ts:250 `MAX_DELTA`.
///
/// Scrolled distance that zooms by the full `speed`, which is about what one
/// notch of a physical mouse wheel reports. Longer distances are capped to
/// it, so that a single event cannot zoom the chart away.
const double _maxDelta = 24;

/// handlers.ts:252 `wheel(chart, event)`: the `wheel` listener of the canvas.
/// It zooms [chart] around the mouse by `wheel.speed` for a full notch
/// ([_maxDelta]), and schedules the debounced `onZoomComplete`.
void wheel(Chart chart, NativeEvent event) {
  // const { handlers: { onZoomComplete }, options: { zoom: zoomOptions = {} } }
  //   = getState(chart)
  final state = getState(chart);
  final onZoomComplete = state.handlers[HandlerName.onZoomComplete];
  final zoomOptions = ZoomOptions(
    valueOrDefault<Object?>(state.options.zoom.raw, emptyObject),
  );

  if (!_wheelPreconditions(chart, event, zoomOptions)) {
    return;
  }

  // `event.target?.getBoundingClientRect()`: the target of a canvas
  // listener is the canvas. Another target has no such method, and the read
  // of `rect.left` throws.
  final rect = switch (event.target) {
    final HTMLCanvasElement target => target.getBoundingClientRect(),
    _ => null,
  };
  final delta = sign(event.deltaY) * jsMin(_maxDelta, event.deltaY.abs());
  // zoomOptions?.wheel?.speed ?? 0.1
  final wheelOptions = zoomOptions.isNullish ? null : zoomOptions.wheel;
  final speedOption = wheelOptions == null || wheelOptions.isNullish
      ? null
      : wheelOptions.speed;
  final speed =
      jsToNumber(isNullOrUndef(speedOption) ? 0.1 : speedOption) *
      (delta.abs() / _maxDelta);
  final percentage = delta >= 0 ? 2 - 1 / (1 - speed) : 1 + speed;
  final amount = ZoomAmount(
    x: percentage,
    y: percentage,
    focalPoint: (x: event.clientX - rect!.left, y: event.clientY - rect.top),
  );

  zoom(chart, amount, 'zoom', ZoomTrigger.wheel);

  onZoomComplete?.call(event);
}

/// handlers.ts:280 `addDebouncedHandler(chart, name, handler, delay)`:
/// stores a debounced call of the user [handler] as the handler [name].
///
/// The stored value is a listener, as the wheel listener calls it with its
/// event (handlers.ts:277). The debounced function takes no argument.
void _addDebouncedHandler(
  Chart chart,
  HandlerName name,
  GenericEvent? handler,
  double delay,
) {
  if (handler != null) {
    final debounced = debounce(() => handler((chart: chart)), delay);
    getState(chart).handlers[name] = (_) => debounced();
  }
}

/// handlers.ts:291 `addListeners(chart, options)`: adds the wheel and drag
/// listeners that [options] enable, and removes the others.
void addListeners(Chart chart, ZoomPluginOptions options) {
  final canvas = chart.canvas;
  // const { wheel: wheelOptions, drag: dragOptions, onZoomComplete } =
  //   options.zoom ?? {}
  final zoomOptions = ZoomOptions(_orEmpty(options.zoom.raw));
  final wheelOptions = zoomOptions.wheel;
  final dragOptions = zoomOptions.drag;
  final onZoomComplete = zoomOptions.onZoomComplete;

  // Install listeners. Do this dynamically based on options so that we can
  // turn zoom on and off We also want to make sure listeners aren't always
  // on. E.g. if you're scrolling down a page and the mouse goes over a chart
  // you don't want it intercepted unless the plugin is enabled
  if (!wheelOptions.isNullish && jsTruthy(wheelOptions.enabled)) {
    // DIVERGES(zoom): adapt-canvas-event-target, the canvas as a target.
    _addHandler(chart, canvas!.eventTarget, HandlerName.wheel, wheel);
    _addDebouncedHandler(
      chart,
      HandlerName.onZoomComplete,
      onZoomComplete,
      250,
    );
  } else {
    _removeHandler(chart, HandlerName.wheel);
  }
  if (!dragOptions.isNullish && jsTruthy(dragOptions.enabled)) {
    // DIVERGES(zoom): adapt-canvas-event-target, the canvas as a target.
    _addHandler(chart, canvas!.eventTarget, HandlerName.mousedown, mouseDown);
    _addHandler(chart, canvas.ownerDocument, HandlerName.mouseup, mouseUp);
  } else {
    _removeHandler(chart, HandlerName.mousedown);
    _removeHandler(chart, HandlerName.mousemove);
    _removeHandler(chart, HandlerName.mouseup);
    _removeHandler(chart, HandlerName.keydown);
  }
}

/// handlers.ts:315 `removeListeners(chart)`: removes each listener of
/// [chart].
void removeListeners(Chart chart) {
  _removeHandler(chart, HandlerName.mousedown);
  _removeHandler(chart, HandlerName.mousemove);
  _removeHandler(chart, HandlerName.mouseup);
  _removeHandler(chart, HandlerName.wheel);
  _removeHandler(chart, HandlerName.click);
  _removeHandler(chart, HandlerName.keydown);
}
