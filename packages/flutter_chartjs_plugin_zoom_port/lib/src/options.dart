// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/options.ts (MIT, chartjs-plugin-zoom contributors).

/// The option types of the plugin: the string unions, the callback types and
/// the option classes.
///
/// - A union of string literals is an enum ([Mode], [ModifierKey],
///   [DrawTime], row `adapt-zoom-option-enums`): the name of each value is
///   the upstream string.
/// - [ZoomTrigger] is a value that only the plugin makes: an enum. Its
///   `name` is the upstream string.
/// - The callback contexts are records: they compare by value in a spec. A
///   callback option holds the function of its typedef, and the plugin calls
///   it directly (Zoom ADR 0004).
/// - Each interface of options is an immutable class with one nullable field
///   for each option (row `adapt-native-zoom-options`, Chart.js ADR 0148). A
///   field that is null is not set. [ZoomPluginOptions] is the
///   `PluginOptions` of the host: the plugin service merges the options of
///   the defaults and of the chart with [ZoomPluginOptions.merge], as the
///   resolver of upstream reads them with `scriptable: false` and
///   `indexable: false`. A hook gets the merged object, with no read by
///   name.
///
/// ```dart
/// ChartConfig(
///   type: .line,
///   pluginOptions: const [
///     ZoomPluginOptions(
///       pan: PanOptions(enabled: true, mode: Mode.x),
///       zoom: ZoomOptions(wheel: WheelOptions(enabled: true)),
///     ),
///   ],
/// );
/// ```
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart' hide Point;

/// options.ts:5 `Mode = 'x' | 'y' | 'xy'`: the zoom or pan directions.
///
/// Upstream tests a direction with `mode.indexOf(dir)`. Each value here has
/// the two directions as fields.
// DIVERGES(zoom): adapt-zoom-option-enums, an enum of the modes.
enum Mode({
  /// Whether the mode has the direction `x`.
  required final bool usesX,

  /// Whether the mode has the direction `y`.
  required final bool usesY,
}) {
  /// `'x'`: the horizontal scales.
  x(usesX: true, usesY: false),

  /// `'y'`: the vertical scales.
  y(usesX: false, usesY: true),

  /// `'xy'`: both directions.
  xy(usesX: true, usesY: true);

  /// Whether the mode has the direction of the scale axis [axis]: `'x'` or
  /// `'y'` (the `axis` of a scale of the host). Another axis has none.
  bool hasAxis(String axis) => switch (axis) {
    'x' => usesX,
    'y' => usesY,
    _ => false,
  };
}

/// options.ts:6 `ModeFn`: a function that gives the [Mode] when the user
/// zooms or pans.
typedef ModeFn = Mode Function(ZoomChartContext context);

// options.ts:7 `ModeOption = Mode | ModeFn`: Dart has no union of an enum
// and a function type. A `mode`, `scaleMode` or `overScaleMode` field is an
// `Object?`, and the constructor of its class asserts that it holds a [Mode],
// a [ModeFn] or null. A value of another type, for example a function with
// no parameter, stops a debug build.

/// options.ts:8 `ModifierKey = 'ctrl' | 'alt' | 'shift' | 'meta'`: a
/// modifier key of an event.
///
/// Upstream reads `event[key + 'Key']`. Each value here reads its own field
/// of the event.
// DIVERGES(zoom): adapt-zoom-option-enums, an enum of the keys.
enum ModifierKey() {
  /// `'ctrl'`: `ctrlKey`.
  ctrl,

  /// `'alt'`: `altKey`.
  alt,

  /// `'shift'`: `shiftKey`.
  shift,

  /// `'meta'`: `metaKey`.
  meta;

  /// Whether this key is down in [event].
  bool pressedIn(NativeEvent event) => switch (this) {
    ctrl => event.ctrlKey,
    alt => event.altKey,
    shift => event.shiftKey,
    meta => event.metaKey,
  };
}

/// options.ts:9 `DrawTime`: the plugin hook that draws the drag rectangle.
// DIVERGES(zoom): adapt-zoom-option-enums, an enum of the hooks.
enum DrawTime() {
  /// `'afterDraw'`.
  afterDraw,

  /// `'afterDatasetsDraw'`.
  afterDatasetsDraw,

  /// `'beforeDraw'`.
  beforeDraw,

  /// `'beforeDatasetsDraw'`.
  beforeDatasetsDraw,
}

/// options.ts:10 `ZoomTrigger = 'api' | 'drag' | 'wheel' | 'pinch'`: what
/// started a zoom. [name] is the upstream string.
enum ZoomTrigger() {
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
/// `true` starts the zoom or the pan, and `false` rejects it. Upstream also
/// accepts `undefined`; a Dart callback states its result (Zoom ADR 0004).
///
/// `E` is the native event (`NativeEvent`) for the zoom and a
/// [GestureEvent] for the pan.
// DIVERGES(zoom): adapt-native-callbacks, an explicit bool result.
typedef RejectableStartEvent<E> = bool Function(ZoomStartContext<E> context);

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

/// The options with `enabled` and `modifierKey` that `getModifierKey` of
/// `utils.dart` reads (utils.ts:7): [WheelOptions], [DragOptions] and
/// [PanOptions].
abstract interface class ModifierKeyOptions() {
  /// `enabled`: whether the input is on. Null is not set.
  bool? get enabled;

  /// `modifierKey`: the modifier key that the input needs. Null is not set.
  ModifierKey? get modifierKey;
}

/// The options with `mode`, `scaleMode` and `overScaleMode` that
/// `getEnabledScalesByPoint` of `utils.dart` reads (utils.ts:96):
/// [ZoomOptions] and [PanOptions]. Each is a [Mode], a [ModeFn] or null.
abstract interface class ScaleModeOptions() {
  /// `mode`: the directions. Null is not set.
  Object? get mode;

  /// `scaleMode`: the directions over a scale. Null is not set.
  Object? get scaleMode;

  /// `overScaleMode`, deprecated. Null is not set.
  Object? get overScaleMode;
}

/// `a?.merge(b) ?? b`: the merge of two nested option objects, where null
/// is not set.
T? _mergeNullable<T extends Object>(T? a, T? b, T Function(T a, T b) merge) =>
    a == null ? b : (b == null ? a : merge(a, b));

/// options.ts:21 `WheelOptions`: the options of the mouse wheel zoom.
///
/// ```dart
/// const WheelOptions(enabled: true, modifierKey: ModifierKey.ctrl);
/// ```
@immutable
final class const WheelOptions({
  /// options.ts:25 `enabled`: enable the zoom via mouse wheel. The default
  /// is `false`.
  @override final bool? enabled,

  /// options.ts:32 `speed`: the speed of the zoom via mouse wheel, the
  /// fraction of zoom per notch of a mouse wheel. The default is 0.1.
  final double? speed,

  /// options.ts:37 `modifierKey`: the modifier key that the wheel zoom
  /// needs. The default is none.
  @override final ModifierKey? modifierKey,
}) implements ModifierKeyOptions {
  /// The options of the wheel zoom.
  this;

  /// Whether the wheel zoom is on: [enabled], else `false`.
  bool get isEnabled => enabled ?? false;

  /// The speed of a wheel zoom: [speed], else 0.1 (handlers.ts:270
  /// `zoomOptions?.wheel?.speed ?? 0.1`).
  double get speedOrDefault => speed ?? 0.1;

  /// These options with each field that [over] sets.
  WheelOptions merge(WheelOptions over) => WheelOptions(
    enabled: over.enabled ?? enabled,
    speed: over.speed ?? speed,
    modifierKey: over.modifierKey ?? modifierKey,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WheelOptions &&
          other.enabled == enabled &&
          other.speed == speed &&
          other.modifierKey == modifierKey;

  @override
  int get hashCode => Object.hash(enabled, speed, modifierKey);

  @override
  String toString() =>
      'WheelOptions(enabled: $enabled, speed: $speed, '
      'modifierKey: $modifierKey)';
}

/// options.ts:40 `DragOptions`: the options of the drag-to-zoom mode.
///
/// ```dart
/// const DragOptions(enabled: true, borderWidth: 1);
/// ```
@immutable
final class const DragOptions({
  /// options.ts:44 `enabled`: enable the zoom via drag. The default is
  /// `false`.
  @override final bool? enabled,

  /// options.ts:49 `threshold`: the minimal drag distance of a zoom, in
  /// pixels. The default is 0.
  final double? threshold,

  /// options.ts:54 `borderColor`: the border color of the drag area. The
  /// default is `Color.fromRGBO(225, 225, 225, 1)`.
  final ChartPaint? borderColor,

  /// options.ts:59 `borderWidth`: the border width of the drag area. The
  /// default is no border.
  final double? borderWidth,

  /// options.ts:64 `backgroundColor`: the background color of the drag
  /// area. The default is `Color.fromRGBO(225, 225, 225, 0.3)`.
  final ChartPaint? backgroundColor,

  /// options.ts:69 `modifierKey`: the modifier key that drag-to-zoom needs.
  /// The default is none.
  @override final ModifierKey? modifierKey,

  /// options.ts:74 `drawTime`: the [DrawTime] of the drag area. The default
  /// is [DrawTime.beforeDatasetsDraw].
  final DrawTime? drawTime,

  /// options.ts:79 `maintainAspectRatio`: keep the aspect ratio of the drag
  /// rectangle. The default is `false`.
  final bool? maintainAspectRatio,
}) implements ModifierKeyOptions {
  /// The options of the drag zoom.
  this;

  /// Whether the drag zoom is on: [enabled], else `false`.
  bool get isEnabled => enabled ?? false;

  /// The minimal drag distance: [threshold], else 0 (handlers.ts:200
  /// `const { threshold = 0 } = drag ?? {}`).
  double get thresholdOrDefault => threshold ?? 0;

  /// These options with each field that [over] sets.
  DragOptions merge(DragOptions over) => DragOptions(
    enabled: over.enabled ?? enabled,
    threshold: over.threshold ?? threshold,
    borderColor: over.borderColor ?? borderColor,
    borderWidth: over.borderWidth ?? borderWidth,
    backgroundColor: over.backgroundColor ?? backgroundColor,
    modifierKey: over.modifierKey ?? modifierKey,
    drawTime: over.drawTime ?? drawTime,
    maintainAspectRatio: over.maintainAspectRatio ?? maintainAspectRatio,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DragOptions &&
          other.enabled == enabled &&
          other.threshold == threshold &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.backgroundColor == backgroundColor &&
          other.modifierKey == modifierKey &&
          other.drawTime == drawTime &&
          other.maintainAspectRatio == maintainAspectRatio;

  @override
  int get hashCode => Object.hash(
    enabled,
    threshold,
    borderColor,
    borderWidth,
    backgroundColor,
    modifierKey,
    drawTime,
    maintainAspectRatio,
  );

  @override
  String toString() =>
      'DragOptions(enabled: $enabled, threshold: $threshold, '
      'borderColor: $borderColor, borderWidth: $borderWidth, '
      'backgroundColor: $backgroundColor, modifierKey: $modifierKey, '
      'drawTime: $drawTime, maintainAspectRatio: $maintainAspectRatio)';
}

/// options.ts:82 `PinchOptions`: the options of the pinch zoom.
///
/// ```dart
/// const PinchOptions(enabled: true);
/// ```
@immutable
final class const PinchOptions({
  /// options.ts:86 `enabled`: enable the zoom via pinch. The default is
  /// `false`.
  final bool? enabled,
}) {
  /// The options of the pinch zoom.
  this;

  /// Whether the pinch zoom is on: [enabled], else `false`.
  bool get isEnabled => enabled ?? false;

  /// These options with each field that [over] sets.
  PinchOptions merge(PinchOptions over) =>
      PinchOptions(enabled: over.enabled ?? enabled);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PinchOptions && other.enabled == enabled;

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'PinchOptions(enabled: $enabled)';
}

/// options.ts:92 `ZoomOptions`: the container of the zoom options.
///
/// A callback compares by identity (the `==` of a function: the same
/// closure, or a tear-off of the same function).
///
/// ```dart
/// ZoomOptions(
///   wheel: const WheelOptions(enabled: true),
///   mode: Mode.x,
///   onZoomComplete: (context) => print(context.chart.getZoomLevel()),
/// );
/// ```
@immutable
final class const ZoomOptions({
  /// options.ts:102 `mode`: the zoom directions, a [Mode] or a [ModeFn].
  /// The default is [Mode.xy].
  @override final Object? mode,

  /// options.ts:107 `wheel`: the options of the mouse wheel mode.
  final WheelOptions? wheel,

  /// options.ts:112 `drag`: the options of the drag-to-zoom mode.
  final DragOptions? drag,

  /// options.ts:117 `pinch`: the options of the pinch mode.
  final PinchOptions? pinch,

  /// options.ts:119 `scaleMode`: the directions of a zoom over a scale, a
  /// [Mode] or a [ModeFn]. The default is none.
  @override final Object? scaleMode,

  /// options.ts:121 `overScaleMode`, deprecated: use [scaleMode] instead.
  @override final Object? overScaleMode,

  /// options.ts:126 `onZoom`: called while the user is zooming.
  final ZoomCallback? onZoom,

  /// options.ts:131 `onZoomComplete`: called once zooming is completed.
  final GenericEvent? onZoomComplete,

  /// options.ts:136 `onZoomRejected`: called when wheel input occurs
  /// without the modifier key, or when [onZoomStart] gives `false`.
  final RejectEvent<NativeEvent>? onZoomRejected,

  /// options.ts:138 `onZoomStart`: called at the start of a zoom by the
  /// wheel, a drag or a pinch: `false` rejects the zoom.
  final RejectableStartEvent<NativeEvent>? onZoomStart,
}) implements ScaleModeOptions {
  /// The zoom options.
  this
    : assert(
        mode == null || mode is Mode || mode is ModeFn,
        'The zoom mode is a Mode or a ModeFn.',
      ),
      assert(
        scaleMode == null || scaleMode is Mode || scaleMode is ModeFn,
        'The zoom scaleMode is a Mode or a ModeFn.',
      ),
      assert(
        overScaleMode == null ||
            overScaleMode is Mode ||
            overScaleMode is ModeFn,
        'The zoom overScaleMode is a Mode or a ModeFn.',
      );

  /// These options with each field that [over] sets. A nested object merges
  /// its own fields.
  ZoomOptions merge(ZoomOptions over) => ZoomOptions(
    mode: over.mode ?? mode,
    wheel: _mergeNullable(wheel, over.wheel, (a, b) => a.merge(b)),
    drag: _mergeNullable(drag, over.drag, (a, b) => a.merge(b)),
    pinch: _mergeNullable(pinch, over.pinch, (a, b) => a.merge(b)),
    scaleMode: over.scaleMode ?? scaleMode,
    overScaleMode: over.overScaleMode ?? overScaleMode,
    onZoom: over.onZoom ?? onZoom,
    onZoomComplete: over.onZoomComplete ?? onZoomComplete,
    onZoomRejected: over.onZoomRejected ?? onZoomRejected,
    onZoomStart: over.onZoomStart ?? onZoomStart,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZoomOptions &&
          other.mode == mode &&
          other.wheel == wheel &&
          other.drag == drag &&
          other.pinch == pinch &&
          other.scaleMode == scaleMode &&
          other.overScaleMode == overScaleMode &&
          other.onZoom == onZoom &&
          other.onZoomComplete == onZoomComplete &&
          other.onZoomRejected == onZoomRejected &&
          other.onZoomStart == onZoomStart;

  @override
  int get hashCode => Object.hash(
    mode,
    wheel,
    drag,
    pinch,
    scaleMode,
    overScaleMode,
    onZoom,
    onZoomComplete,
    onZoomRejected,
    onZoomStart,
  );

  @override
  String toString() =>
      'ZoomOptions(mode: $mode, wheel: $wheel, drag: $drag, pinch: $pinch, '
      'scaleMode: $scaleMode, overScaleMode: $overScaleMode)';
}

/// options.ts:144 `PanOptions`: the container of the pan options.
///
/// A callback compares by identity (the `==` of a function).
///
/// ```dart
/// const PanOptions(enabled: true, mode: Mode.x, threshold: 5);
/// ```
@immutable
final class const PanOptions({
  /// options.ts:148 `enabled`: enable panning. The default is `false`.
  @override final bool? enabled,

  /// options.ts:159 `mode`: the pan directions, a [Mode] or a [ModeFn].
  /// The default is [Mode.xy].
  @override final Object? mode,

  /// options.ts:164 `modifierKey`: the modifier key that a mouse pan needs.
  /// The default is none.
  @override final ModifierKey? modifierKey,

  /// options.ts:166 `scaleMode`: the directions of a pan over a scale, a
  /// [Mode] or a [ModeFn]. The default is none.
  @override final Object? scaleMode,

  /// options.ts:168 `overScaleMode`, deprecated: use [scaleMode] instead.
  @override final Object? overScaleMode,

  /// options.ts:173 `threshold`: the minimal pan distance of a pan, in
  /// pixels. The default is 10.
  final double? threshold,

  /// options.ts:178 `onPan`: called while the user is panning.
  final GenericEvent? onPan,

  /// options.ts:183 `onPanComplete`: called once panning is completed.
  final GenericEvent? onPanComplete,

  /// options.ts:189 `onPanRejected`: called when a pan fails because the
  /// modifier key was not pressed, or when [onPanStart] gives `false`.
  final RejectEvent<GestureEvent>? onPanRejected,

  /// options.ts:191 `onPanStart`: called at the start of a pan: `false`
  /// rejects the pan.
  final RejectableStartEvent<GestureEvent>? onPanStart,
}) implements ModifierKeyOptions, ScaleModeOptions {
  /// The pan options.
  this
    : assert(
        mode == null || mode is Mode || mode is ModeFn,
        'The pan mode is a Mode or a ModeFn.',
      ),
      assert(
        scaleMode == null || scaleMode is Mode || scaleMode is ModeFn,
        'The pan scaleMode is a Mode or a ModeFn.',
      ),
      assert(
        overScaleMode == null ||
            overScaleMode is Mode ||
            overScaleMode is ModeFn,
        'The pan overScaleMode is a Mode or a ModeFn.',
      );

  /// Whether the pan is on: [enabled], else `false`.
  bool get isEnabled => enabled ?? false;

  /// These options with each field that [over] sets.
  PanOptions merge(PanOptions over) => PanOptions(
    enabled: over.enabled ?? enabled,
    mode: over.mode ?? mode,
    modifierKey: over.modifierKey ?? modifierKey,
    scaleMode: over.scaleMode ?? scaleMode,
    overScaleMode: over.overScaleMode ?? overScaleMode,
    threshold: over.threshold ?? threshold,
    onPan: over.onPan ?? onPan,
    onPanComplete: over.onPanComplete ?? onPanComplete,
    onPanRejected: over.onPanRejected ?? onPanRejected,
    onPanStart: over.onPanStart ?? onPanStart,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanOptions &&
          other.enabled == enabled &&
          other.mode == mode &&
          other.modifierKey == modifierKey &&
          other.scaleMode == scaleMode &&
          other.overScaleMode == overScaleMode &&
          other.threshold == threshold &&
          other.onPan == onPan &&
          other.onPanComplete == onPanComplete &&
          other.onPanRejected == onPanRejected &&
          other.onPanStart == onPanStart;

  @override
  int get hashCode => Object.hash(
    enabled,
    mode,
    modifierKey,
    scaleMode,
    overScaleMode,
    threshold,
    onPan,
    onPanComplete,
    onPanRejected,
    onPanStart,
  );

  @override
  String toString() =>
      'PanOptions(enabled: $enabled, mode: $mode, modifierKey: $modifierKey, '
      'scaleMode: $scaleMode, overScaleMode: $overScaleMode, '
      'threshold: $threshold)';
}

/// options.ts:195 `number | 'original'`: the `min` or the `max` limit of a
/// scale.
///
/// A limit is a number, or [original]: the limit that the scale had when
/// the chart was first displayed.
///
/// ```dart
/// const ScaleLimits(min: ScaleLimit(0), max: ScaleLimit.original);
/// ```
// DIVERGES(zoom): adapt-native-zoom-options, a class for number | 'original'.
@immutable
final class const ScaleLimit._(
  /// The number of the limit, or null for [original].
  final double? value,
) {
  /// The limit [value].
  const new(double value) : this._(value);

  /// `'original'`: the limit of the scale when the chart was first
  /// displayed.
  static const ScaleLimit original = ScaleLimit._(null);

  /// Whether this limit is [original].
  bool get isOriginal => value == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScaleLimit && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() =>
      isOriginal ? 'ScaleLimit.original' : 'ScaleLimit($value)';
}

/// options.ts:194 `ScaleLimits`: the limits of one scale.
///
/// ```dart
/// const ScaleLimits(min: ScaleLimit(0), max: ScaleLimit(100), minRange: 10);
/// ```
@immutable
final class const ScaleLimits({
  /// options.ts:195 `min`: the smallest value of `scale.min`.
  final ScaleLimit? min,

  /// options.ts:196 `max`: the largest value of `scale.max`.
  final ScaleLimit? max,

  /// options.ts:197 `minRange`: the smallest range (`max - min`) of a zoom.
  /// The default is 0.
  final double? minRange,
}) {
  /// The limits of a scale.
  this;

  /// The smallest range of a zoom: [minRange], else 0 (scale.types.ts:144
  /// `valueOrDefault(scaleLimits.minRange, 0)`).
  double get minRangeOrDefault => minRange ?? 0;

  /// These limits with each field that [over] sets.
  ScaleLimits merge(ScaleLimits over) => ScaleLimits(
    min: over.min ?? min,
    max: over.max ?? max,
    minRange: over.minRange ?? minRange,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScaleLimits &&
          other.min == min &&
          other.max == max &&
          other.minRange == minRange;

  @override
  int get hashCode => Object.hash(min, max, minRange);

  @override
  String toString() => 'ScaleLimits(min: $min, max: $max, minRange: $minRange)';
}

/// options.ts:200 `LimitOptions`: the [ScaleLimits] by the id of a scale or
/// by its axis (`x` or `y`).
///
/// ```dart
/// const LimitOptions limits = {'x': ScaleLimits(min: ScaleLimit(0))};
/// ```
typedef LimitOptions = Map<String, ScaleLimits>;

/// The limits [a] with the limits of [over]: the limits of each scale id
/// merge (`ScaleLimits.merge`).
LimitOptions _mergeLimits(LimitOptions a, LimitOptions over) => {
  ...a,
  for (final MapEntry(:key, :value) in over.entries)
    key: a[key]?.merge(value) ?? value,
};

/// Whether the limits [a] and [b] have the same scale ids and equal limits.
bool _limitsEqual(LimitOptions? a, LimitOptions? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (final MapEntry(:key, :value) in a.entries) {
    if (!b.containsKey(key) || b[key] != value) return false;
  }
  return true;
}

/// The hash of the limits [limits], from their entries in any order.
int _limitsHash(LimitOptions? limits) => limits == null
    ? null.hashCode
    : Object.hashAllUnordered([
        for (final MapEntry(:key, :value) in limits.entries)
          Object.hash(key, value),
      ]);

/// options.ts:205 `ZoomPluginOptions`: the options of the plugin,
/// `options.plugins.zoom` (Chart.js ADR 0148).
///
/// A field that is null is not set: the plugin takes the field of the
/// defaults (`lib/src/defaults.dart`). The hooks get the options of the
/// defaults merged with the options of the chart ([merge]). A typed config
/// gives the options in `ChartConfig.pluginOptions`, and a raw config holds
/// the object itself:
///
/// ```dart
/// ChartConfig(
///   type: .line,
///   pluginOptions: const [
///     ZoomPluginOptions(pan: PanOptions(enabled: true)),
///   ],
/// );
/// <String, Object?>{
///   'type': 'line',
///   'options': {
///     'plugins': {'zoom': ZoomPluginOptions(pan: PanOptions(enabled: true))},
///   },
/// };
/// ```
// DIVERGES(zoom): adapt-native-zoom-options, a PluginOptions of the host.
@immutable
final class const ZoomPluginOptions({
  /// options.ts:206 `pan`: the pan options.
  final PanOptions? pan,

  /// options.ts:207 `limits`: the scale limits. The default is none.
  final LimitOptions? limits,

  /// options.ts:208 `zoom`: the zoom options.
  final ZoomOptions? zoom,

  /// `rangeOnlyUpdates`, a port-only option with no default: whether each
  /// zoom and pan updates the chart with `chart.updateRanges(transition)` of
  /// the host in place of `chart.update(transition)` (Chart.js ADR 0111).
  /// Null is `false`.
  ///
  /// The app keeps the contract of `updateRanges`: between the full updates
  /// of the chart, nothing changes an option, a default, the theme, a
  /// dataset, a scale or a plugin in place, except the `min` and `max` that
  /// the plugin writes. New data values, data Lists and labels are allowed.
  /// The host takes `update` when one of its checks fails.
  // DIVERGES(zoom): adapt-range-only-updates, the port-only opt-in.
  final bool? rangeOnlyUpdates,

  /// `events`: the event types of the plugin, the option that the event
  /// filter of Chart.js reads for each plugin (`core.controller.js:1170`,
  /// Chart.js ADR 0150). Null gives the `events` of the chart. The listeners
  /// of the plugin on the canvas do not read it, as upstream.
  @override final List<String>? events,
}) extends PluginOptions<ZoomPluginOptions> {
  /// The options of the zoom plugin.
  this;

  @override
  String get pluginId => 'zoom';

  /// The limits: [limits], else `{}` (core.ts:73 `limits = {}`).
  LimitOptions get limitsOrDefault => limits ?? const {};

  /// These options with each field that [over] sets. A nested object merges
  /// its own fields, and [limits] merges the limits of each scale id.
  @override
  ZoomPluginOptions merge(ZoomPluginOptions over) => ZoomPluginOptions(
    pan: _mergeNullable(pan, over.pan, (a, b) => a.merge(b)),
    limits: _mergeNullable(limits, over.limits, _mergeLimits),
    zoom: _mergeNullable(zoom, over.zoom, (a, b) => a.merge(b)),
    rangeOnlyUpdates: over.rangeOnlyUpdates ?? rangeOnlyUpdates,
    events: over.events ?? events,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZoomPluginOptions &&
          other.pan == pan &&
          _limitsEqual(other.limits, limits) &&
          other.zoom == zoom &&
          other.rangeOnlyUpdates == rangeOnlyUpdates &&
          listEquals(other.events, events);

  @override
  int get hashCode => Object.hash(
    pan,
    _limitsHash(limits),
    zoom,
    rangeOnlyUpdates,
    events == null ? null : Object.hashAll(events!),
  );

  @override
  String toString() =>
      'ZoomPluginOptions(pan: $pan, limits: $limits, zoom: $zoom, '
      'rangeOnlyUpdates: $rangeOnlyUpdates, events: $events)';
}
