// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/gestures.ts (MIT, chartjs-plugin-zoom contributors).

/// The pointer gestures of the plugin: the pan of one pointer and the pinch
/// of two pointers, from the DOM pointer events of the canvas.
///
/// A gesture manager tracks the pointers of one canvas (`pointerdown` on the
/// canvas; `pointermove`, `pointerup` and `pointercancel` on its document)
/// and turns them into the pan and pinch steps that the plugin once got from
/// Hammer.js. The host gives the canvas listeners, the document and the
/// style members through the extensions `CanvasEventTarget` and
/// `CssStyleProperties` (Chart.js ADR 0108), so the upstream lines keep
/// their form.
///
/// - The listeners are method tear-offs. Two tear-offs of one method of one
///   object are `==`, so `removeEventListener` removes the listener that
///   `addEventListener` added, as for the arrow-function fields of upstream.
/// - The active pointers are a `Map<int, ActivePointer>`: a Dart `Map`
///   literal is a `LinkedHashMap`, which keeps the insertion order of a JS
///   `Map`, also when a write replaces the value of a key.
/// - `Math.hypot` is `jsHypot` (Chart.js ADR 0108): the distance decides
///   whether a pan starts.
/// - The `WeakMap` of the managers is an `Expando`.
/// - A user callback gets a typed call when it has the type of its typedef,
///   else the JavaScript call of `callUser` (Zoom ADR 0003, item 9).
library;

import 'package:flutter_chartjs_plugin_zoom_port/src/core.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/options.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/state.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/types.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/utils.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show
        CanvasEventTarget,
        Chart,
        CssStyleProperties,
        HTMLCanvasElement,
        NativeEvent,
        NativeEventTarget,
        undefined;
import 'package:flutter_chartjs_port/helpers.dart'
    show getRelativePosition, isNullOrUndef, valueOrDefault;
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsHypot, jsToNumber, jsTruthy;

/// gestures.ts:13 `GestureEvent`: the normalized gesture event of the pan
/// and pinch callbacks (`onPanStart`, `onPanRejected`).
///
/// It replaces the former Hammer.js event object. It carries only the fields
/// that the plugin reads, all from the native pointer events.
final class GestureEvent {
  /// A gesture event with its fields.
  const GestureEvent({
    required this.center,
    required this.deltaX,
    required this.deltaY,
    required this.distance,
    required this.scale,
    required this.pointers,
    required this.target,
    required this.srcEvent,
    required this.pointerType,
  });

  /// gestures.ts:15 `center`: the gesture centroid in client coordinates,
  /// the midpoint of the active pointers.
  final Point center;

  /// gestures.ts:17 `deltaX`: the cumulative horizontal pan offset in pixels
  /// since the gesture started.
  final double deltaX;

  /// gestures.ts:18 `deltaY`: the cumulative vertical pan offset in pixels
  /// since the gesture started.
  final double deltaY;

  /// gestures.ts:20 `distance`: the straight-line distance in pixels that
  /// the gesture has travelled since it started.
  final double distance;

  /// gestures.ts:22 `scale`: the cumulative pinch scale relative to the
  /// gesture start (1 = unchanged).
  final double scale;

  /// gestures.ts:24 `pointers`: the active pointers, in client coordinates.
  final List<ActivePointer> pointers;

  /// gestures.ts:26 `target`: the canvas that the gesture is bound to.
  final HTMLCanvasElement target;

  /// gestures.ts:28 `srcEvent`: the native pointer event that produced this
  /// gesture event.
  final NativeEvent srcEvent;

  /// gestures.ts:30 `pointerType`: the pointer device type, `mouse`, `touch`
  /// or `pen`.
  final String pointerType;
}

/// gestures.ts:35 `DEFAULT_PAN_THRESHOLD`.
///
/// Hammer's Pan recognizer only fires once the pointer has moved this far,
/// so we keep the same default when the option is left unset.
const double _defaultPanThreshold = 10;

/// The optional read `pan?.enabled` of the pan options [pan].
Object? _enabledOf(PanOptions pan) => pan.isNullish ? undefined : pan.enabled;

/// The optional read `pan?.threshold` of the pan options [pan].
Object? _thresholdOf(PanOptions pan) =>
    pan.isNullish ? undefined : pan.threshold;

/// The optional read `zoom?.pinch?.enabled` of the zoom options [zoom].
Object? _pinchEnabledOf(ZoomOptions zoom) {
  if (zoom.isNullish) {
    return undefined;
  }
  final pinch = zoom.pinch;
  return pinch.isNullish ? undefined : pinch.enabled;
}

/// `f?.(context)` of a [RejectEvent] [f]: a typed call, else [callUser].
void _callReject<E>(Object? f, ZoomEventContext<E> context) {
  if (f is RejectEvent<E>) {
    f(context);
  } else {
    callUser(f, context);
  }
}

/// `f?.(context)` of a [RejectableStartEvent] [f]: its result, `undefined`
/// when [f] is `null` or `undefined`. A typed call, else [callUser].
Object? _callStart<E>(Object? f, ZoomStartContext<E> context) =>
    f is RejectableStartEvent<E> ? f(context) : callUser(f, context);

/// `f?.(context)` of a [GenericEvent] [f]: a typed call, else [callUser].
void _callGeneric(Object? f, ZoomChartContext context) {
  if (f is GenericEvent) {
    f(context);
  } else {
    callUser(f, context);
  }
}

/// gestures.ts:37 `distance(a, b)`: the distance of two pointers.
double _distance(ActivePointer a, ActivePointer b) =>
    jsHypot(a.clientX - b.clientX, a.clientY - b.clientY);

/// gestures.ts:41 `createEnabler(chart, state)`: the test of a pan start.
///
/// The pan needs enabled pan options. A mouse pan also needs the modifier
/// key of the pan, and no modifier key of the drag zoom; else the enabler
/// calls `onPanRejected`.
bool Function(GestureEvent) _createEnabler(Chart chart, State state) {
  return (event) {
    // const { pan: panOptions, zoom: zoomOptions = {} } = state.options
    final options = state.options;
    final panOptions = options.pan;
    final zoomOptions = ZoomOptions(
      valueOrDefault(options.zoom.raw, emptyObject),
    );
    if (!jsTruthy(panOptions.raw) || !jsTruthy(panOptions.enabled)) {
      return false;
    }
    // `const srcEvent = event && event.srcEvent` and `if (!srcEvent) return
    // true`: a GestureEvent always has its srcEvent.
    final srcEvent = event.srcEvent;
    if (!state.panning &&
        event.pointerType == 'mouse' &&
        (keyNotPressed(getModifierKey(panOptions.raw), srcEvent) ||
            keyPressed(getModifierKey(zoomOptions.drag.raw), srcEvent))) {
      _callReject(panOptions.onPanRejected, (chart: chart, event: event));
      return false;
    }
    return true;
  };
}

/// gestures.ts:63 `pinchAxes(p0, p1)`: the axes of a pinch of the pointers
/// [p0] and [p1].
///
/// Upstream leaves an axis that it does not set `undefined`, and each reader
/// tests its truthiness: the port gives `false`.
({bool x, bool y}) _pinchAxes(ActivePointer p0, ActivePointer p1) {
  // fingers position difference
  final pinchX = (p0.clientX - p1.clientX).abs();
  final pinchY = (p0.clientY - p1.clientY).abs();

  // diagonal fingers will change both (xy) axes
  final p = pinchX / pinchY;
  var x = false;
  var y = false;
  if (p > 0.3 && p < 1.7) {
    x = y = true;
  } else if (pinchX > pinchY) {
    x = true;
  } else {
    y = true;
  }
  return (x: x, y: y);
}

/// gestures.ts:81 `handlePinch(chart, state, e)`: one step of a pinch
/// zoom.
void _handlePinch(Chart chart, State state, GestureEvent e) {
  if (jsTruthy(state.scale)) {
    final GestureEvent(:center, :pointers) = e;
    // The event reports the total scaling. We need the incremental amount.
    final zoomPercent = (1 / state.scale!) * e.scale;
    final rect = e.target.getBoundingClientRect();
    final pinch = _pinchAxes(pointers[0], pointers[1]);
    final zoomOptions = state.options.zoom;
    final mode = zoomOptions.isNullish ? undefined : zoomOptions.mode;
    final amount = ZoomAmount(
      x: pinch.x && directionEnabled(mode, 'x', chart) ? zoomPercent : 1,
      y: pinch.y && directionEnabled(mode, 'y', chart) ? zoomPercent : 1,
      focalPoint: (x: center.x - rect.left, y: center.y - rect.top),
    );

    zoom(chart, amount, 'zoom', ZoomTrigger.pinch);

    // Keep track of overall scale
    state.scale = e.scale;
  }
}

/// gestures.ts:105 `startPinch(chart, state, e)`: the start of a pinch
/// zoom. A result `false` of `onZoomStart` rejects it.
void _startPinch(Chart chart, State state, GestureEvent e) {
  if (jsTruthy(_pinchEnabledOf(state.options.zoom))) {
    // The host `Point` of a native event has two numbers. `?? 0` is the
    // ToNumber of a JS `null`.
    final position = getRelativePosition(e.srcEvent, chart);
    final point = (x: position.x ?? 0, y: position.y ?? 0);
    // state.options.zoom?.onZoomStart?.({ chart, event: e.srcEvent, point })
    final startOptions = state.options.zoom;
    final started = _callStart(
      startOptions.isNullish ? undefined : startOptions.onZoomStart,
      (chart: chart, event: e.srcEvent, point: point),
    );
    if (started == false) {
      state.scale = null;
      // state.options.zoom?.onZoomRejected?.({ chart, event: e.srcEvent })
      final rejectOptions = state.options.zoom;
      _callReject(
        rejectOptions.isNullish ? undefined : rejectOptions.onZoomRejected,
        (chart: chart, event: e.srcEvent),
      );
    } else {
      state.scale = 1;
    }
  }
}

/// gestures.ts:117 `endPinch(chart, state, e)`: the last step of a pinch
/// zoom, then `onZoomComplete`.
void _endPinch(Chart chart, State state, GestureEvent e) {
  if (jsTruthy(state.scale)) {
    _handlePinch(chart, state, e);
    state.scale = null; // reset
    final zoomOptions = state.options.zoom;
    _callGeneric(
      zoomOptions.isNullish ? undefined : zoomOptions.onZoomComplete,
      (chart: chart),
    );
  }
}

/// gestures.ts:125 `handlePan(chart, state, e)`: one step of a pan.
void _handlePan(Chart chart, State state, GestureEvent e) {
  final delta = state.delta;
  if (delta != null) {
    state.panning = true;
    final panScales = state.panScales;
    pan(
      chart,
      PanAmount(x: e.deltaX - delta.x, y: e.deltaY - delta.y),
      // state.panScales && state.panScales.map((i) => chart.scales[i])
      //   .filter(Boolean)
      panScales == null ? null : [for (final i in panScales) ?chart.scales[i]],
    );
    state.delta = (x: e.deltaX, y: e.deltaY);
  }
}

/// gestures.ts:138 `startPan(chart, state, event)`: the start of a pan. A
/// result `false` of `onPanStart` rejects it and calls `onPanRejected`.
void _startPan(Chart chart, State state, GestureEvent event) {
  // const { enabled, onPanStart, onPanRejected } = state.options.pan ?? {}
  final panOptions = state.options.pan;
  final options = panOptions.isNullish
      ? const PanOptions(emptyObject)
      : panOptions;
  final enabled = options.enabled;
  final onPanStart = options.onPanStart;
  final onPanRejected = options.onPanRejected;
  if (!jsTruthy(enabled)) {
    return;
  }
  final rect = event.target.getBoundingClientRect();
  final point = (
    x: event.center.x - rect.left,
    y: event.center.y - rect.top,
  );

  final started = _callStart(onPanStart, (
    chart: chart,
    event: event,
    point: point,
  ));
  if (started == false) {
    // return onPanRejected?.({ chart, event })
    _callReject(onPanRejected, (chart: chart, event: event));
    return;
  }

  state.panScales = [
    for (final i in getEnabledScalesByPoint(
      state.options.pan.raw,
      point,
      chart,
    ))
      i.id,
  ];
  state.delta = (x: 0, y: 0);
  _handlePan(chart, state, event);
}

/// gestures.ts:158 `endPan(chart, state)`: the end of a pan, then
/// `onPanComplete`.
void _endPan(Chart chart, State state) {
  state.delta = null;
  if (state.panning) {
    state
      ..panning = false
      ..filterNextClick = true;
    final panOptions = state.options.pan;
    _callGeneric(
      panOptions.isNullish ? undefined : panOptions.onPanComplete,
      (chart: chart),
    );
  }
}

/// gestures.ts:167 `ActivePointer`: an active pointer in client
/// coordinates, the logical pixels of the view.
typedef ActivePointer = ({double clientX, double clientY});

/// gestures.ts:169 `pointerFrom(event)`: the client point of [event].
ActivePointer _pointerFrom(NativeEvent event) =>
    (clientX: event.clientX, clientY: event.clientY);

/// gestures.ts:175 `GestureManager`.
///
/// Tracks the native pointers on a single canvas and translates them into
/// the pan/pinch gestures the plugin previously received from Hammer.js.
final class _GestureManager {
  /// gestures.ts:191 `constructor(chart)`: sets the style of the canvas
  /// and adds the listeners.
  _GestureManager(Chart chart)
    : _chart = chart,
      _state = getState(chart),
      _canvas = chart.canvas! {
    _doc = _canvas.ownerDocument;
    _enabler = _createEnabler(chart, _state);

    // Suppress the browser's own scroll/zoom so gestures reach the canvas,
    // mirroring what Hammer configured on its manager.
    _previousTouchAction = _canvas.style.touchAction;
    _canvas.style.touchAction = 'none';

    // Stop a drag from selecting text or other page content, as Hammer did
    // while a manager was active.
    _previousUserSelect = _canvas.style.userSelect;
    _canvas.style.userSelect = 'none';
    _canvas.style.setProperty('-webkit-user-select', 'none');

    _canvas.addEventListener('pointerdown', _onPointerDown);
    _doc.addEventListener('pointermove', _onPointerMove);
    _doc.addEventListener('pointerup', _onPointerUp);
    _doc.addEventListener('pointercancel', _onPointerCancel);
  }

  /// gestures.ts:176 `chart`.
  final Chart _chart;

  /// gestures.ts:177 `state`.
  final State _state;

  /// gestures.ts:178 `canvas`.
  final HTMLCanvasElement _canvas;

  /// gestures.ts:179 `doc`: the document of the canvas.
  late final NativeEventTarget _doc;

  /// gestures.ts:180 `enabler`.
  late final bool Function(GestureEvent event) _enabler;

  /// gestures.ts:181 `previousTouchAction`.
  late final String _previousTouchAction;

  /// gestures.ts:182 `previousUserSelect`.
  late final String _previousUserSelect;

  /// gestures.ts:184 `pointers`: the tracked pointers by `pointerId`, in the
  /// order of their first `pointerdown`.
  final Map<int, ActivePointer> _pointers = {};

  /// gestures.ts:187 `panStart`.
  ///
  /// Set while a pan could still happen; `state.delta` marks a recognized
  /// one.
  Point? _panStart;

  /// gestures.ts:189 `pinchStartDistance`.
  double? _pinchStartDistance;

  /// gestures.ts:215 `destroy()`: removes the listeners, restores the style
  /// of the canvas and drops the gesture.
  void destroy() {
    _canvas.removeEventListener('pointerdown', _onPointerDown);
    _doc.removeEventListener('pointermove', _onPointerMove);
    _doc.removeEventListener('pointerup', _onPointerUp);
    _doc.removeEventListener('pointercancel', _onPointerCancel);
    _canvas.style.touchAction = _previousTouchAction;
    _canvas.style.userSelect = _previousUserSelect;
    _canvas.style.removeProperty('-webkit-user-select');
    _abortGesture();
  }

  /// gestures.ts:230 `abortGesture()`.
  ///
  /// Drops a gesture without committing it. Unlike endPan/endPinch this
  /// fires no completion callback, and it clears the state the manager keeps
  /// in `state`: a leaked `delta` would let the next gesture resume this
  /// one, and a leaked `panning` would keep swallowing the chart's events.
  void _abortGesture() {
    _pointers.clear();
    _panStart = null;
    _pinchStartDistance = null;
    _state
      ..delta = null
      ..scale = null
      ..panning = false;
  }

  /// gestures.ts:239 `pointerList()`: the tracked pointers, as a new list.
  List<ActivePointer> _pointerList() => [..._pointers.values];

  /// gestures.ts:243 `buildEvent(srcEvent)`: the [GestureEvent] of the
  /// tracked pointers at the pointer event [srcEvent].
  GestureEvent _buildEvent(NativeEvent srcEvent) {
    final pointers = _pointerList();
    final count = pointers.isEmpty ? 1 : pointers.length;
    // The sum of `p.clientX / count`, in the order of upstream, not the sum
    // divided by the count.
    final center = pointers.fold<Point>(
      (x: 0, y: 0),
      (acc, p) => (x: acc.x + p.clientX / count, y: acc.y + p.clientY / count),
    );
    final panStart = _panStart;
    final deltaX = panStart != null ? center.x - panStart.x : 0.0;
    final deltaY = panStart != null ? center.y - panStart.y : 0.0;
    final pinchStartDistance = _pinchStartDistance;
    final scale =
        pinchStartDistance != null &&
            jsTruthy(pinchStartDistance) &&
            pointers.length >= 2
        ? _distance(pointers[0], pointers[1]) / pinchStartDistance
        : 1.0;
    return GestureEvent(
      center: center,
      deltaX: deltaX,
      deltaY: deltaY,
      distance: jsHypot(deltaX, deltaY),
      scale: scale,
      pointers: pointers,
      target: _canvas,
      srcEvent: srcEvent,
      pointerType: srcEvent.pointerType,
    );
  }

  /// gestures.ts:267 `onPointerDown`: the listener of `pointerdown` on the
  /// canvas.
  void _onPointerDown(NativeEvent event) {
    // Hammer's mouse input only started a gesture on the primary button.
    if (event.pointerType == 'mouse' && event.button != 0) {
      return;
    }
    // At most two pointers take part in a gesture. Extra ones are never
    // tracked so they cannot skew the centroid or end an ongoing pinch when
    // lifted.
    if (_pointers.length >= 2) {
      return;
    }
    _pointers[event.pointerId] = _pointerFrom(event);

    // const { pan: panOptions, zoom: zoomOptions } = this.state.options
    final options = _state.options;
    final panOptions = options.pan;
    final zoomOptions = options.zoom;

    if (_pointers.length > 1) {
      // A second pointer always ends a pan, whether or not it starts a
      // pinch: the centroid would otherwise jump when either pointer is
      // lifted.
      _endPan(_chart, _state);
      _panStart = null;

      if (jsTruthy(_pinchEnabledOf(zoomOptions))) {
        final pts = _pointerList();
        _pinchStartDistance = _distance(pts[0], pts[1]);
        _startPinch(_chart, _state, _buildEvent(event));
      }
    } else if (jsTruthy(_enabledOf(panOptions))) {
      // Begin tracking a possible pan; it is only recognized once it passes
      // the threshold (see onPointerMove).
      _panStart = (x: event.clientX, y: event.clientY);
    }
  }

  /// gestures.ts:299 `onPointerMove`: the listener of `pointermove` on the
  /// document.
  void _onPointerMove(NativeEvent event) {
    if (!_pointers.containsKey(event.pointerId)) {
      return;
    }
    _pointers[event.pointerId] = _pointerFrom(event);

    if (_pinchStartDistance != null && _pointers.length > 1) {
      _handlePinch(_chart, _state, _buildEvent(event));
      return;
    }

    if (_panStart != null && _pointers.length == 1) {
      final gesture = _buildEvent(event);
      if (_state.delta != null) {
        _handlePan(_chart, _state, gesture);
      } else if (gesture.distance >= _panThreshold() && _enabler(gesture)) {
        _startPan(_chart, _state, gesture);
        if (_state.delta == null) {
          // onPanStart rejected the pan; don't offer it again this gesture.
          _panStart = null;
        }
      }
    }
  }

  /// gestures.ts:324 `onPointerUp`: the listener of `pointerup` on the
  /// document.
  void _onPointerUp(NativeEvent event) {
    if (!_pointers.containsKey(event.pointerId)) {
      return;
    }
    // Record the pointer's final position before removing it so the closing
    // gesture event is built from an accurate centroid.
    _pointers[event.pointerId] = _pointerFrom(event);

    if (_pinchStartDistance != null && _pointers.length > 1) {
      _endPinch(_chart, _state, _buildEvent(event));
      _pinchStartDistance = null;
    }

    _pointers.remove(event.pointerId);

    if (_pointers.isEmpty) {
      _endPan(_chart, _state);
      _panStart = null;
      _pinchStartDistance = null;
    } else {
      // One pointer is left, either from a pinch or from a pan that the
      // lifted pointer ended: let it start a fresh pan from where it is now.
      final remaining = _pointerList()[0];
      _panStart = jsTruthy(_enabledOf(_state.options.pan))
          ? (x: remaining.clientX, y: remaining.clientY)
          : null;
    }
  }

  /// gestures.ts:351 `onPointerCancel`: the listener of `pointercancel` on
  /// the document.
  void _onPointerCancel(NativeEvent event) {
    if (_pointers.containsKey(event.pointerId)) {
      _abortGesture();
    }
  }

  /// gestures.ts:357 `panThreshold()`: the `threshold` of the pan options,
  /// else the default of Hammer.
  ///
  /// Upstream gives the raw option, and its one reader compares
  /// `gesture.distance >= threshold`, which converts the option with
  /// ToNumber. The port gives that number ([jsToNumber]).
  double _panThreshold() {
    // this.state.options.pan?.threshold ?? DEFAULT_PAN_THRESHOLD
    final threshold = _thresholdOf(_state.options.pan);
    return isNullOrUndef(threshold)
        ? _defaultPanThreshold
        : jsToNumber(threshold);
  }
}

/// gestures.ts:362 `managers`: the gesture manager of each chart.
final Expando<_GestureManager> _managers = Expando(
  'chartjs-plugin-zoom gesture manager',
);

/// gestures.ts:364 `startGestures(chart, options)`: starts the pan and
/// pinch gestures of [chart] when [options] enable the pan or the pinch.
///
/// As upstream, it does not stop an earlier manager of [chart]: the plugin
/// calls [stopGestures] first.
void startGestures(Chart chart, ZoomPluginOptions options) {
  // const { pan: panOptions, zoom: zoomOptions } = options
  final panOptions = options.pan;
  final zoomOptions = options.zoom;
  if (!jsTruthy(_enabledOf(panOptions)) &&
      !jsTruthy(_pinchEnabledOf(zoomOptions))) {
    return;
  }
  _managers[chart] = _GestureManager(chart);
}

/// gestures.ts:372 `stopGestures(chart)`: stops the gestures of [chart]:
/// removes the listeners, restores the style of the canvas and drops a
/// gesture in progress with no callback.
void stopGestures(Chart chart) {
  final manager = _managers[chart];
  if (manager != null) {
    manager.destroy();
    _managers[chart] = null;
  }
}

/// gestures.ts:380 `gestureOptionsChanged(oldOptions, newOptions)`: whether
/// the options that the gestures read at their start changed: the pinch
/// `enabled`, the pan `enabled` or the pan `threshold`.
///
/// The compares take the raw values: `!=` gives the result of `!==` for
/// them, also for `undefined`, NaN and the two zeros.
bool gestureOptionsChanged(
  ZoomPluginOptions oldOptions,
  ZoomPluginOptions newOptions,
) {
  // const { pan: oldPan, zoom: oldZoom } = oldOptions
  final oldPan = oldOptions.pan;
  final oldZoom = oldOptions.zoom;
  // const { pan: newPan, zoom: newZoom } = newOptions
  final newPan = newOptions.pan;
  final newZoom = newOptions.zoom;

  if (_pinchEnabledOf(oldZoom) != _pinchEnabledOf(newZoom)) {
    return true;
  }
  if (_enabledOf(oldPan) != _enabledOf(newPan)) {
    return true;
  }
  if (_thresholdOf(oldPan) != _thresholdOf(newPan)) {
    return true;
  }

  return false;
}
