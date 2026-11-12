// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/options.ts (MIT, chartjs-plugin-zoom contributors).

/// The option types of the plugin: the string unions, the callback types and
/// the option facades (Zoom ADR 0003, item 9).
///
/// - A union of string literals is an extension type over its `String`, with
///   a constant for each member ([Mode], [ModifierKey], [DrawTime]). A raw
///   `'xy'` in a Map config is the same value.
/// - [ZoomTrigger] is a value that only the plugin makes: an enum. Its
///   `name` is the upstream string.
/// - The callback contexts are records: they compare by value in a spec. A
///   user function gets a typed call when it has the type of its typedef,
///   else the JavaScript call of `jsCall` (`callUser` of `utils.dart`).
///   `null` and `undefined` skip the call, as upstream skips a missing
///   callback.
/// - The options of a hook are a resolver of the host, read by name. A
///   facade is an extension type over the raw value (the resolver, a nested
///   resolver, a Map of a spec, or `undefined`), with no cost. Each getter
///   reads one key with `jsGet`, the plain read `o.k` of upstream: it throws
///   a `TypeError` for `null` and `undefined`, and gives `undefined` for a
///   primitive. A call site of the optional read `o?.k` tests
///   `isNullish` first. The getters give the raw JavaScript value, and the
///   JavaScript operators stay at the upstream read sites. No value is
///   copied: each read is live, as upstream reads the resolver at each use.
library;

import 'package:flutter_chartjs_plugin_zoom_port/src/gestures.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/types.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show Chart;
import 'package:flutter_chartjs_port/helpers.dart' show isNullOrUndef;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsGet, jsTruthy;

/// options.ts:5 `Mode = 'x' | 'y' | 'xy'`: the zoom or pan directions.
extension type const Mode(String name) implements String {
  /// `'x'`: the horizontal scales.
  static const Mode x = Mode('x');

  /// `'y'`: the vertical scales.
  static const Mode y = Mode('y');

  /// `'xy'`: both directions.
  static const Mode xy = Mode('xy');
}

/// options.ts:6 `ModeFn`: a function that gives the [Mode] when the user
/// zooms or pans.
///
/// options.ts:7 `ModeOption = Mode | ModeFn` has no Dart type: the option is
/// the raw value of the getter.
typedef ModeFn = String Function(ZoomChartContext context);

/// options.ts:8 `ModifierKey = 'ctrl' | 'alt' | 'shift' | 'meta'`: a
/// modifier key of an event.
extension type const ModifierKey(String name) implements String {
  /// `'ctrl'`: `ctrlKey`.
  static const ModifierKey ctrl = ModifierKey('ctrl');

  /// `'alt'`: `altKey`.
  static const ModifierKey alt = ModifierKey('alt');

  /// `'shift'`: `shiftKey`.
  static const ModifierKey shift = ModifierKey('shift');

  /// `'meta'`: `metaKey`.
  static const ModifierKey meta = ModifierKey('meta');
}

/// options.ts:9 `DrawTime`: the plugin hook that draws the drag rectangle.
extension type const DrawTime(String name) implements String {
  /// `'afterDraw'`.
  static const DrawTime afterDraw = DrawTime('afterDraw');

  /// `'afterDatasetsDraw'`.
  static const DrawTime afterDatasetsDraw = DrawTime('afterDatasetsDraw');

  /// `'beforeDraw'`.
  static const DrawTime beforeDraw = DrawTime('beforeDraw');

  /// `'beforeDatasetsDraw'`.
  static const DrawTime beforeDatasetsDraw = DrawTime('beforeDatasetsDraw');
}

/// options.ts:10 `ZoomTrigger = 'api' | 'drag' | 'wheel' | 'pinch'`: what
/// started a zoom. [name] is the upstream string.
enum ZoomTrigger {
  /// `'api'`: a call of `zoom`, `zoomRect` or `zoomScale`.
  api,

  /// `'drag'`: the drag rectangle.
  drag,

  /// `'wheel'`: the mouse wheel.
  wheel,

  /// `'pinch'`: a pinch of two pointers.
  pinch,
}

/// The context `{ chart }` of [ModeFn] and [GenericEvent] (options.ts:6,
/// :19).
typedef ZoomChartContext = ({Chart chart});

/// The context `{ chart, trigger }` of `onZoom` (options.ts:126).
typedef ZoomTriggerContext = ({Chart chart, ZoomTrigger trigger});

/// The context `{ chart, event }` of [RejectEvent] (options.ts:17).
typedef ZoomEventContext<E> = ({Chart chart, E event});

/// The context `{ chart, event, point }` of [RejectableStartEvent]
/// (options.ts:12-16). `point` is the position in canvas pixels.
typedef ZoomStartContext<E> = ({Chart chart, E event, Point point});

/// options.ts:12 `RejectableStartEvent<T>`: a start callback. A result
/// `false` rejects the zoom or the pan.
///
/// `E` is the native event (`NativeEvent`) for the zoom and a
/// [GestureEvent] for the pan.
typedef RejectableStartEvent<E> = bool? Function(ZoomStartContext<E> context);

/// options.ts:17 `RejectEvent<T>`: a callback of a rejected zoom or pan.
///
/// `E` is the native event (`NativeEvent`) for the zoom and a
/// [GestureEvent] for the pan.
typedef RejectEvent<E> = void Function(ZoomEventContext<E> context);

/// options.ts:19 `GenericEvent`: a callback that gets the chart.
typedef GenericEvent = void Function(ZoomChartContext context);

/// The type of `onZoom` (options.ts:126): a callback that gets the chart
/// and the [ZoomTrigger].
typedef ZoomCallback = void Function(ZoomTriggerContext context);

/// `{}`: the empty object of a destructuring default (`{ zoom = {} }`) or of
/// `options || {}`. Nothing writes into it.
const Map<String, Object?> emptyObject = <String, Object?>{};

/// options.ts:21 `WheelOptions`: the options of the mouse wheel zoom.
extension type const WheelOptions(Object? raw) {
  /// Whether [raw] is `null` or `undefined`: the test of `?.`.
  bool get isNullish => isNullOrUndef(raw);

  /// options.ts:25 `enabled`: enable the zoom via mouse wheel.
  Object? get enabled => jsGet(raw, 'enabled');

  /// options.ts:32 `speed`: the speed of the zoom via mouse wheel, the
  /// fraction of zoom per notch of a mouse wheel.
  Object? get speed => jsGet(raw, 'speed');

  /// options.ts:37 `modifierKey`: the modifier key that the wheel zoom needs.
  Object? get modifierKey => jsGet(raw, 'modifierKey');
}

/// options.ts:40 `DragOptions`: the options of the drag-to-zoom mode.
extension type const DragOptions(Object? raw) {
  /// Whether [raw] is `null` or `undefined`: the test of `?.`.
  bool get isNullish => isNullOrUndef(raw);

  /// options.ts:44 `enabled`: enable the zoom via drag.
  Object? get enabled => jsGet(raw, 'enabled');

  /// options.ts:49 `threshold`: the minimal drag distance of a zoom.
  Object? get threshold => jsGet(raw, 'threshold');

  /// options.ts:54 `borderColor`: the border color of the drag area.
  Object? get borderColor => jsGet(raw, 'borderColor');

  /// options.ts:59 `borderWidth`: the border width of the drag area.
  Object? get borderWidth => jsGet(raw, 'borderWidth');

  /// options.ts:64 `backgroundColor`: the background color of the drag
  /// area.
  Object? get backgroundColor => jsGet(raw, 'backgroundColor');

  /// options.ts:69 `modifierKey`: the modifier key that drag-to-zoom needs.
  Object? get modifierKey => jsGet(raw, 'modifierKey');

  /// options.ts:74 `drawTime`: the [DrawTime] of the drag area.
  Object? get drawTime => jsGet(raw, 'drawTime');

  /// options.ts:79 `maintainAspectRatio`: keep the aspect ratio of the drag
  /// rectangle.
  Object? get maintainAspectRatio => jsGet(raw, 'maintainAspectRatio');
}

/// options.ts:82 `PinchOptions`: the options of the pinch zoom.
extension type const PinchOptions(Object? raw) {
  /// Whether [raw] is `null` or `undefined`: the test of `?.`.
  bool get isNullish => isNullOrUndef(raw);

  /// options.ts:86 `enabled`: enable the zoom via pinch.
  Object? get enabled => jsGet(raw, 'enabled');
}

/// options.ts:92 `ZoomOptions`: the container of the zoom options.
extension type const ZoomOptions(Object? raw) {
  /// Whether [raw] is `null` or `undefined`: the test of `?.`.
  bool get isNullish => isNullOrUndef(raw);

  /// options.ts:102 `mode`: the zoom directions, a [Mode] or a [ModeFn].
  Object? get mode => jsGet(raw, 'mode');

  /// options.ts:107 `wheel`: the options of the mouse wheel mode.
  WheelOptions get wheel => WheelOptions(jsGet(raw, 'wheel'));

  /// options.ts:112 `drag`: the options of the drag-to-zoom mode.
  DragOptions get drag => DragOptions(jsGet(raw, 'drag'));

  /// options.ts:117 `pinch`: the options of the pinch mode.
  PinchOptions get pinch => PinchOptions(jsGet(raw, 'pinch'));

  /// options.ts:119 `scaleMode`: the directions of a zoom over a scale, a
  /// [Mode] or a [ModeFn].
  Object? get scaleMode => jsGet(raw, 'scaleMode');

  /// options.ts:121 `overScaleMode`, deprecated: use [scaleMode] instead.
  Object? get overScaleMode => jsGet(raw, 'overScaleMode');

  /// options.ts:126 `onZoom`: a [ZoomCallback], called while the user is
  /// zooming.
  Object? get onZoom => jsGet(raw, 'onZoom');

  /// options.ts:131 `onZoomComplete`: a [GenericEvent], called once zooming
  /// is completed.
  Object? get onZoomComplete => jsGet(raw, 'onZoomComplete');

  /// options.ts:136 `onZoomRejected`: a [RejectEvent] of the native event,
  /// called when wheel input occurs without the modifier key.
  Object? get onZoomRejected => jsGet(raw, 'onZoomRejected');

  /// options.ts:138 `onZoomStart`: a [RejectableStartEvent] of the native
  /// event.
  Object? get onZoomStart => jsGet(raw, 'onZoomStart');
}

/// options.ts:144 `PanOptions`: the container of the pan options.
extension type const PanOptions(Object? raw) {
  /// Whether [raw] is `null` or `undefined`: the test of `?.`.
  bool get isNullish => isNullOrUndef(raw);

  /// options.ts:148 `enabled`: enable panning.
  Object? get enabled => jsGet(raw, 'enabled');

  /// options.ts:159 `mode`: the pan directions, a [Mode] or a [ModeFn].
  Object? get mode => jsGet(raw, 'mode');

  /// options.ts:164 `modifierKey`: the modifier key that a mouse pan needs.
  Object? get modifierKey => jsGet(raw, 'modifierKey');

  /// options.ts:166 `scaleMode`: the directions of a pan over a scale, a
  /// [Mode] or a [ModeFn].
  Object? get scaleMode => jsGet(raw, 'scaleMode');

  /// options.ts:168 `overScaleMode`, deprecated: use [scaleMode] instead.
  Object? get overScaleMode => jsGet(raw, 'overScaleMode');

  /// options.ts:173 `threshold`: the minimal pan distance of a pan.
  Object? get threshold => jsGet(raw, 'threshold');

  /// options.ts:178 `onPan`: a [GenericEvent], called while the user is
  /// panning.
  Object? get onPan => jsGet(raw, 'onPan');

  /// options.ts:183 `onPanComplete`: a [GenericEvent], called once panning
  /// is completed.
  Object? get onPanComplete => jsGet(raw, 'onPanComplete');

  /// options.ts:189 `onPanRejected`: a [RejectEvent] of the [GestureEvent],
  /// called when a pan fails because the modifier key was not pressed.
  Object? get onPanRejected => jsGet(raw, 'onPanRejected');

  /// options.ts:191 `onPanStart`: a [RejectableStartEvent] of the
  /// [GestureEvent].
  Object? get onPanStart => jsGet(raw, 'onPanStart');
}

/// options.ts:194 `ScaleLimits`: the limits of one scale.
extension type const ScaleLimits(Object? raw) {
  /// Whether [raw] is `null` or `undefined`: the test of `?.`.
  bool get isNullish => isNullOrUndef(raw);

  /// options.ts:195 `min`: a number or `'original'`.
  Object? get min => jsGet(raw, 'min');

  /// options.ts:196 `max`: a number or `'original'`.
  Object? get max => jsGet(raw, 'max');

  /// options.ts:197 `minRange`: the smallest range of a zoom.
  Object? get minRange => jsGet(raw, 'minRange');
}

/// options.ts:200 `LimitOptions`: the [ScaleLimits] by the id of a scale or
/// by its axis (`x` or `y`).
extension type const LimitOptions(Object? raw) {
  /// Whether [raw] is `null` or `undefined`: the test of `?.`.
  bool get isNullish => isNullOrUndef(raw);

  /// options.ts:202 `[axisId: string]: ScaleLimits`: the limits of the
  /// scale id or the axis [axisId].
  ScaleLimits operator [](String axisId) => ScaleLimits(jsGet(raw, axisId));
}

/// options.ts:205 `ZoomPluginOptions`: the options of the plugin,
/// `options.plugins.zoom`.
extension type const ZoomPluginOptions(Object? raw) {
  /// Whether [raw] is `null` or `undefined`: the test of `?.`.
  bool get isNullish => isNullOrUndef(raw);

  /// options.ts:206 `pan`: the pan options.
  PanOptions get pan => PanOptions(jsGet(raw, 'pan'));

  /// options.ts:207 `limits`: the scale limits.
  LimitOptions get limits => LimitOptions(jsGet(raw, 'limits'));

  /// options.ts:208 `zoom`: the zoom options.
  ZoomOptions get zoom => ZoomOptions(jsGet(raw, 'zoom'));

  /// `rangeOnlyUpdates`, a port-only option with no default: whether each
  /// zoom and pan updates the chart with `chart.updateRanges(transition)` of
  /// the host in place of `chart.update(transition)` (Chart.js ADR 0111). The
  /// ToBoolean of the read: an absent key is false.
  ///
  /// The app keeps the contract of `updateRanges`: between the full updates
  /// of the chart, nothing changes an option, a default, the theme, a
  /// dataset, a scale or a plugin in place, except the `min` and `max` that
  /// the plugin writes. New data values, data Lists and labels are allowed.
  /// The host takes `update` when one of its checks fails.
  // DIVERGES(zoom): adapt-range-only-updates, the port-only opt-in.
  bool get rangeOnlyUpdates => jsTruthy(jsGet(raw, 'rangeOnlyUpdates'));
}
