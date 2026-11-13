// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/state.ts (MIT, chartjs-plugin-zoom contributors).

/// The zoom state of each chart: the original and the updated scale limits,
/// the event listeners, and the drag and pan state.
///
/// The `WeakMap` of upstream is an `Expando`, as the plugins of the host keep
/// their state (Chart.js ADR 0038, section 5): the state of a chart goes with
/// the chart.
library;

import 'package:flutter_chartjs_plugin_zoom_port/src/options.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/types.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show NativeEvent, NativeEventListener, NativeEventTarget, undefined;

export 'package:flutter_chartjs_plugin_zoom_port/src/types.dart'
    show ScaleRange;

/// One side of state.ts:6 `OriginalLimits`: `{ scale?: number; options?:
/// unknown }`, the `min` or the `max` of a scale before the first zoom.
final class const OriginalLimit({
  /// The `min` or `max` of the scale, or `null` for the absent property.
  final double? scale,

  /// The raw `min` or `max` option of the scale: a number, a date string,
  /// `null` or `undefined`.
  final Object? options = undefined,
}) {
  /// An original limit. A missing [scale] is `null`, and a missing [options]
  /// is `undefined`, as the empty object `{}` of upstream gives.
  this;
}

/// state.ts:6 `OriginalLimits`: the original `min` and `max` of a scale.
typedef OriginalLimits = ({OriginalLimit min, OriginalLimit max});

/// state.ts:7 `OriginalScaleLimits`: the [OriginalLimits] by scale id.
typedef OriginalScaleLimits = Map<String, OriginalLimits>;

/// state.ts:8 `UpdatedScaleLimits`: the last range that the plugin wrote,
/// by scale id.
typedef UpdatedScaleLimits = Map<String, ScaleRange>;

/// state.ts:19 `HandlerName = keyof HandlerFunctions`: the event listeners
/// of the plugin, in the key order of state.ts:10 `HandlerFunctions`.
///
/// [name] is the DOM event type of the listener. `onZoomComplete` is the
/// debounced callback of the wheel zoom (`src/handlers.ts:281-289`), which
/// the wheel listener calls.
///
/// The function types of `HandlerFunctions` and state.ts:20
/// `HandlerFunction` have no Dart form: the handler of each name is a
/// function of `handlers.dart`.
enum HandlerName() {
  /// `click`.
  click,

  /// `keydown`.
  keydown,

  /// `mousedown`.
  mousedown,

  /// `mousemove`.
  mousemove,

  /// `mouseup`.
  mouseup,

  /// `onZoomComplete`.
  onZoomComplete,

  /// `wheel`.
  wheel,
}

/// state.ts:21 `Handler = EventListener`: a listener of the canvas or of its
/// document.
typedef Handler = NativeEventListener;

/// state.ts:22 `Handlers`: the [Handler] of each [HandlerName].
typedef Handlers = Map<HandlerName, Handler>;

/// state.ts:24 `HandlerTarget`: the target of the [Handler] of each
/// [HandlerName], the canvas (`canvas.eventTarget`) or its document
/// (`canvas.ownerDocument`).
// DIVERGES(zoom): adapt-canvas-event-target, a NativeEventTarget.
typedef HandlerTarget = Map<HandlerName, NativeEventTarget>;

/// state.ts:26 `State`: the zoom state of one chart.
final class State() {
  /// A new [State].
  this;

  /// state.ts:27 `originalScaleLimits`.
  final OriginalScaleLimits originalScaleLimits = {};

  /// state.ts:28 `updatedScaleLimits`.
  final UpdatedScaleLimits updatedScaleLimits = {};

  /// state.ts:29 `handlers`.
  final Handlers handlers = {};

  /// state.ts:30 `targets`.
  final HandlerTarget targets = {};

  /// state.ts:31 `panDelta`: the pan distance that did not change a scale
  /// yet, by scale id.
  final Map<String, double> panDelta = {};

  /// state.ts:32 `dragging`.
  bool dragging = false;

  /// state.ts:33 `panning`.
  bool panning = false;

  /// state.ts:34 `options`: the plugin options of the last `start` or
  /// `beforeUpdate` hook. The first value is the empty object `{}` of
  /// state.ts:52.
  ZoomPluginOptions options = const ZoomPluginOptions(emptyObject);

  /// state.ts:35 `dragStart`.
  NativeEvent? dragStart;

  /// state.ts:36 `dragEnd`.
  NativeEvent? dragEnd;

  /// state.ts:37 `filterNextClick`. Each read tests its truthiness, so the
  /// absent property of upstream is `false`.
  bool filterNextClick = false;

  /// state.ts:38 `scale`: the pinch scale of the last pinch step. `null`
  /// stands for `null` and `undefined`.
  double? scale;

  /// state.ts:39 `delta`: the pan offset of the last pan step. `null`
  /// stands for `null` and `undefined`.
  Point? delta;

  /// state.ts:40 `panScales`: the ids of the scales of the current pan.
  List<String>? panScales;
}

/// state.ts:43 `chartStates`.
final Expando<State> _chartStates = Expando('chartjs-plugin-zoom state');

/// state.ts:45 `getState(chart)`: the state of [chart], made at the first
/// call.
///
/// [chart] is an `Object`: `scale.chart` of a scale has the internal chart
/// interface of the host, and an `Expando` takes any object as its key, as a
/// `WeakMap` does.
State getState(Object chart) {
  var state = _chartStates[chart];
  if (state == null) {
    state = State();
    _chartStates[chart] = state;
  }
  return state;
}

/// state.ts:63 `removeState(chart)`.
void removeState(Object chart) {
  _chartStates[chart] = null;
}
