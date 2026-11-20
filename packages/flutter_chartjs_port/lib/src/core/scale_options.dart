// Original code, not ported from Chart.js: the typed scale option classes.

/// The typed scale options (Chart.js ADR 0183).
///
/// `Scale.options` is the `ContextProxy` of the scale upstream, an
/// [OptionView] over the scope list of a typed `ScaleOptionsScope`
/// (`core.config.js:71-113` makes it). Upstream reads each option as a
/// property: `this.options.ticks`, `tickOpts.padding`. In the port,
/// `Scale.options` is an object of a class of this library over that view:
/// [CoreScaleOptions] and its subclasses for the scale types, and one class
/// for each nested option object ([TickOptions], [GridLineOptions], ...).
///
/// Each option is a typed getter. A read reads the key of the view
/// (`readKey`, or [readOption] for a nested object) and applies the
/// conversion of the key: a number is a `double` ([jsToNumber] of a value
/// that is not a number), an on/off key a `bool` ([boolOption]), a keyword
/// an enum, a font a `TextStyle`, a dash a `List<double>`. Dart `null` is
/// an absent option (JS `undefined` or `null`). The view keeps the cache of
/// upstream: a scriptable option runs at the read of upstream, and a write
/// into the view shows at the next read, as upstream.
///
/// The getters that give the raw value say why: a union of types, a live
/// object that the scale writes, or a function whose type names `Scale`,
/// which this core library does not import.
///
/// [CoreScaleOptions.view] (and `view` of a nested class) is the resolver
/// view of the object: `setContext`, the internal plans of the scale and a
/// write by name (`scale.optionsView['min'] = 5`) use it.
///
/// The names are the `index.d.ts` names of the option interfaces. The schema
/// has one scope kind for the options of every scale type
/// (`ScaleOptionsScope`) and one for the ticks of every scale type
/// (`TickOptionsScope`). Thus [CoreScaleOptions] has each key that
/// `core.scale.js` and `scale.linearbase.js` read on every scale type, also
/// a key that `index.d.ts` declares in an interface of a scale type.
///
/// This library imports `helpers.config.dart`, `lib/src/js/` and
/// `lib/src/options/`: a pure layer.
library;

import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// `options.setContext(context)` of a nested option object: a view of the
/// same resolver with the context [context].
///
/// The option objects of a scale are `ContextProxy` resolvers. Another value
/// has no `setContext`. JavaScript then throws a `TypeError` at the call.
/// Here the cast throws it.
ContextProxy _setContext(Object? options, Object context) =>
    (options! as ContextProxy).setContext(context);

/// The number of the option value [value]: the value of a `num`, Dart
/// `null` for an absent value (Dart `null` or [undefined]), else the
/// [jsToNumber] of the value, as the arithmetic of upstream reads it.
double? _number(Object? value) => switch (value) {
  final num number => number.toDouble(),
  null || Undefined() => null,
  _ => jsToNumber(value),
};

/// The font of the option value [value]: a `TextStyle` (Chart.js ADR
/// 0116), or Dart `null` for an absent value. Another value stops a debug
/// build.
TextStyle? _font(Object? value) {
  if (value is TextStyle) return value;
  assert(
    value == null || value is Undefined,
    'A font option holds a TextStyle (Chart.js ADR 0116), not $value.',
  );
  return null;
}

/// The dash of the option value [value]: a `List<double>` (row
/// `adapt-dash-lists`), or Dart `null` for an absent value. Another value
/// stops a debug build.
List<double>? _dash(Object? value) => switch (value) {
  final List<double> dash => dash,
  // A list of a scriptable result: its numbers, NaN for an item that is no
  // number, as `canvasLineDash` reads it.
  final List<Object?> items => [
    for (final item in items)
      if (item is num) item.toDouble() else double.nan,
  ],
  _ => () {
    assert(
      value == null || value is Undefined,
      'A dash option holds a List<double>, not $value.',
    );
    return null;
  }(),
};

/// The lines of the title text [value] (row `adapt-title-text-lines`).
/// Another value stops a debug build.
List<String> _textLines(Object? value) {
  if (value is List<String>) return value;
  assert(
    value == null || value is Undefined,
    'A title text takes a List<String> of its lines, not $value.',
  );
  return const <String>[];
}

/// index.d.ts:1200 `CoreScaleOptions`: the options of a scale, the object
/// `Scale.options` (Chart.js ADR 0183).
///
/// It also has the keys of `CartesianScaleOptions` (index.d.ts:3257) and of
/// the linear scale options that `core.scale.js` and `scale.linearbase.js`
/// read through `this.options` of each scale: [axis], [position], [offset],
/// [bounds], [grid], [border], [title], [labels], [beginAtZero], [grace]
/// and [fullSize]. The layout reads the layout keys through
/// [layoutOption].
///
/// ```dart
/// final options = chart.scales['y']!.options;
/// print(options.reverse); // false
/// print(options.ticks.padding); // 3.0
/// ```
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
base class const CoreScaleOptions(
  /// The resolver view of the options, the `ContextProxy` of upstream.
  final OptionView view,
) implements LayoutBoxOptions {
  /// The options of the resolved value [view].
  this;

  /// index.d.ts:1205 `display: boolean | 'auto'` (row
  /// `adapt-scale-display-enum`).
  ScaleDisplay get display => ScaleDisplay.of(view.readKey(OptionKey.display));

  /// index.d.ts:1209 `alignToPixels: boolean`.
  bool get alignToPixels => boolOption(
    view.readKey(OptionKey.alignToPixels),
    OptionKey.alignToPixels,
  );

  /// index.d.ts:1213 `backgroundColor: Color`. The raw value: the drawing
  /// tests its truthiness and gives it to the canvas.
  Object? get backgroundColor => view.readKey(OptionKey.backgroundColor);

  /// index.d.ts:1218 `reverse: boolean`.
  bool get reverse =>
      boolOption(view.readKey(OptionKey.reverse), OptionKey.reverse);

  /// index.d.ts:1223 `clip: boolean`.
  bool get clip => boolOption(view.readKey(OptionKey.clip), OptionKey.clip);

  /// index.d.ts:1228 `weight: number`.
  double? get weight => _number(view.readKey(OptionKey.weight));

  /// index.d.ts:1232 `min: unknown`. The raw value: the scale parses it
  /// (a number, a date or a label).
  Object? get min => view.readKey(OptionKey.min);

  /// index.d.ts:1236 `max: unknown`, as [min].
  Object? get max => view.readKey(OptionKey.max);

  /// index.d.ts:1240 `suggestedMin: unknown`, as [min].
  Object? get suggestedMin => view.readKey(OptionKey.suggestedMin);

  /// index.d.ts:1244 `suggestedMax: unknown`, as [min].
  Object? get suggestedMax => view.readKey(OptionKey.suggestedMax);

  // The 14 hooks hold a `ScaleHook` of `core.scale.dart`, a function of the
  // `Scale` class, which this core library does not import. Each getter
  // gives the raw value, and the scale calls it through `functionOption`.

  /// index.d.ts:1248 `beforeUpdate(axis: Scale): void`.
  Object? get beforeUpdate => view.readKey(OptionKey.beforeUpdate);

  /// index.d.ts:1252 `beforeSetDimensions(axis: Scale): void`.
  Object? get beforeSetDimensions =>
      view.readKey(OptionKey.beforeSetDimensions);

  /// index.d.ts:1256 `afterSetDimensions(axis: Scale): void`.
  Object? get afterSetDimensions => view.readKey(OptionKey.afterSetDimensions);

  /// index.d.ts:1260 `beforeDataLimits(axis: Scale): void`.
  Object? get beforeDataLimits => view.readKey(OptionKey.beforeDataLimits);

  /// index.d.ts:1264 `afterDataLimits(axis: Scale): void`.
  Object? get afterDataLimits => view.readKey(OptionKey.afterDataLimits);

  /// index.d.ts:1268 `beforeBuildTicks(axis: Scale): void`.
  Object? get beforeBuildTicks => view.readKey(OptionKey.beforeBuildTicks);

  /// index.d.ts:1272 `afterBuildTicks(axis: Scale): void`.
  Object? get afterBuildTicks => view.readKey(OptionKey.afterBuildTicks);

  /// index.d.ts:1276 `beforeTickToLabelConversion(axis: Scale): void`.
  Object? get beforeTickToLabelConversion =>
      view.readKey(OptionKey.beforeTickToLabelConversion);

  /// index.d.ts:1280 `afterTickToLabelConversion(axis: Scale): void`.
  Object? get afterTickToLabelConversion =>
      view.readKey(OptionKey.afterTickToLabelConversion);

  /// index.d.ts:1284 `beforeCalculateLabelRotation(axis: Scale): void`.
  Object? get beforeCalculateLabelRotation =>
      view.readKey(OptionKey.beforeCalculateLabelRotation);

  /// index.d.ts:1288 `afterCalculateLabelRotation(axis: Scale): void`.
  Object? get afterCalculateLabelRotation =>
      view.readKey(OptionKey.afterCalculateLabelRotation);

  /// index.d.ts:1292 `beforeFit(axis: Scale): void`.
  Object? get beforeFit => view.readKey(OptionKey.beforeFit);

  /// index.d.ts:1296 `afterFit(axis: Scale): void`.
  Object? get afterFit => view.readKey(OptionKey.afterFit);

  /// index.d.ts:1300 `afterUpdate(axis: Scale): void`.
  Object? get afterUpdate => view.readKey(OptionKey.afterUpdate);

  /// index.d.ts:3286 `axis: 'x' | 'y' | 'r'` of `CartesianScaleOptions`, a
  /// [ScaleAxis] (row `adapt-axis-objects`). `core.config` gives each scale
  /// an `axis` option. Dart `null` for a value that is not an axis.
  ScaleAxis? get axis => switch (view.readKey(OptionKey.axis)) {
    final ScaleAxis axis => axis,
    _ => null,
  };

  /// index.d.ts:3270 `position` of `CartesianScaleOptions`: a
  /// [ChartPosition] or a [ScaleValuePosition] (row
  /// `adapt-chart-position-enum`), or Dart `null` for no position.
  LayoutPosition? get position => switch (view.readKey(OptionKey.position)) {
    final LayoutPosition position => position,
    _ => null,
  };

  /// index.d.ts:3302 `offset: boolean` of `CartesianScaleOptions`.
  bool get offset =>
      boolOption(view.readKey(OptionKey.offset), OptionKey.offset);

  /// index.d.ts:3265 `bounds: 'ticks' | 'data'` of `CartesianScaleOptions`.
  /// `scale.linearbase.js:182` reads it for the radial scale too. The
  /// option holds a [ScaleBounds] (row `adapt-scale-option-enums`).
  ScaleBounds? get bounds => ScaleBounds.of(view.readKey(OptionKey.bounds));

  /// index.d.ts:3347 `labels` of `CategoryScaleOptions`: a List of labels,
  /// or Dart `null` for none (differences.md row `adapt-scale-option-types`).
  /// `getLabels` (core.scale.js:359) reads it on each scale. Another truthy
  /// value throws a [TypeError].
  List<Object?>? get labels {
    final value = view.readKey(OptionKey.labels);
    if (value is List<Object?>) return value;
    // DIVERGES(chartjs): adapt-scale-option-types, a List of labels only.
    if (jsTruthy(value)) throw TypeError();
    return null;
  }

  /// index.d.ts:3362 `beginAtZero` of `LinearScaleOptions`. `update`
  /// (core.scale.js:394) reads it on each scale.
  bool get beginAtZero =>
      boolOption(view.readKey(OptionKey.beginAtZero), OptionKey.beginAtZero);

  /// index.d.ts:3374 `grace` of `LinearScaleOptions`, a [GraceLength] (row
  /// `adapt-length-objects`). `update` (core.scale.js:394) reads it on each
  /// scale.
  GraceLength? get grace => GraceLength.of(view.readKey(OptionKey.grace));

  /// `fullSize`, the option of the layout box (`layout.d.ts:17`).
  /// `isFullSize` (core.scale.js:768) reads it.
  bool get fullSize =>
      boolOption(view.readKey(OptionKey.fullSize), OptionKey.fullSize);

  /// index.d.ts:3341 `ticks`.
  TickOptions get ticks => TickOptions(view.readKey(OptionKey.ticks));

  /// index.d.ts:3304 `grid: Partial<GridLineOptions>` of
  /// `CartesianScaleOptions`.
  GridLineOptions get grid => GridLineOptions(view.readKey(OptionKey.grid));

  /// index.d.ts:3306 `border: BorderOptions` of `CartesianScaleOptions`:
  /// the [ScaleBorder] of the scopes, merged (Chart.js ADR 0141, row
  /// `adapt-native-scale-border`). An [AxisBorder] for a cartesian scale and
  /// a [RadialAxisBorder] for the radial linear scale. A value that is not a
  /// border stops a debug build; a release build gives Dart `null` for it.
  ScaleBorder? get border => scaleBorderOf(view.readKey(OptionKey.border));

  /// index.d.ts:3309 `title` of `CartesianScaleOptions`.
  ScaleTitleOptions get title =>
      ScaleTitleOptions(view.readKey(OptionKey.title));

  /// index.d.ts:3275 `stack?: string` of `CartesianScaleOptions`: the option
  /// `stack`, not the `_stack` of the cache object of the view
  /// ([OptionView.stack]). The layout reads it on each box.
  String? get stack => switch (view.readKey(OptionKey.stack)) {
    final String stack => stack,
    _ => null,
  };

  /// index.d.ts:3339 `stacked?: boolean | 'single'` of
  /// `CartesianScaleOptions`. The dataset controllers read it on each scale
  /// type (`core.datasetController.js:57`): a [StackMode], or
  /// Dart `null` for no value (row `adapt-stacked-option-enum`).
  StackMode? get stacked {
    final value = view.readKey(OptionKey.stacked);
    if (value is StackMode) return value;
    assert(
      value == null || value is Undefined,
      'The scale option stacked takes a StackMode, not $value.',
    );
    return null;
  }

  /// index.d.ts:3281 `stackWeight?: number` of `CartesianScaleOptions`.
  double? get stackWeight => _number(view.readKey(OptionKey.stackWeight));

  /// The value of the layout option [key] (`layouts.configure` and the
  /// stack reads of `core.layouts.js`): the getter of the key, [undefined]
  /// for an absent value. Another key reads the view.
  @override
  Object? layoutOption(OptionKey key) => switch (key) {
    OptionKey.fullSize => fullSize,
    OptionKey.position => position ?? undefined,
    OptionKey.weight => weight ?? undefined,
    OptionKey.stack => stack ?? undefined,
    OptionKey.stackWeight => stackWeight ?? undefined,
    _ => view.readKey(key),
  };
}

/// The [ScaleBorder] of the border option value [value], or Dart `null` for
/// no border. A value that is not a border stops a debug build.
ScaleBorder? scaleBorderOf(Object? value) {
  assert(
    value is ScaleBorder || value == null || value is Undefined,
    'The scale option border takes a ScaleBorder, not $value.',
  );
  return value is ScaleBorder ? value : null;
}

/// index.d.ts:3257 `CartesianScaleOptions`: the keys that the cartesian
/// scales have beside [CoreScaleOptions].
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
base class const CartesianScaleOptions(super.view) extends CoreScaleOptions {
  /// The options of the resolved value [view].
  this;
}

/// index.d.ts:3344 `CategoryScaleOptions`. Its `labels` is
/// [CoreScaleOptions.labels].
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
final class const CategoryScaleOptions(super.view)
    extends CartesianScaleOptions {
  /// The options of the resolved value [view].
  this;
}

/// index.d.ts:3356 `LinearScaleOptions`. Its keys are in
/// [CoreScaleOptions] and [TickOptions].
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
final class const LinearScaleOptions(super.view) extends CartesianScaleOptions {
  /// The options of the resolved value [view].
  this;
}

/// index.d.ts:3405 `LogarithmicScaleOptions`. Its keys are in
/// [CoreScaleOptions] and [TickOptions].
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
final class const LogarithmicScaleOptions(super.view)
    extends CartesianScaleOptions {
  /// The options of the resolved value [view].
  this;
}

/// index.d.ts:3484 `TimeScaleOptions`.
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
final class const TimeScaleOptions(super.view) extends CartesianScaleOptions {
  /// The options of the resolved value [view].
  this;

  /// index.d.ts:3503 `offsetAfterAutoskip: boolean`: the truthiness of the
  /// option value, as `scale.time.js:340` tests it.
  bool get offsetAfterAutoskip =>
      jsTruthy(view.readKey(OptionKey.offsetAfterAutoskip));

  /// index.d.ts:3508 `adapters: {date: unknown}`. The raw value: the
  /// options object of the date adapter, an object of the user that the
  /// adapter reads by name. The resolver makes no sub-resolver for it
  /// (helpers.config.ts:215).
  Object? get adapters => view.readKey(OptionKey.adapters);

  /// index.d.ts:3512 `time: TimeScaleTimeOptions`.
  TimeScaleTimeOptions get time =>
      TimeScaleTimeOptions(view.readKey(OptionKey.time));
}

/// index.d.ts:3563 `RadialLinearScaleOptions`.
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
final class const RadialLinearScaleOptions(super.view)
    extends CoreScaleOptions {
  /// The options of the resolved value [view].
  this;

  /// index.d.ts:3564 `animate: boolean`.
  bool get animate =>
      boolOption(view.readKey(OptionKey.animate), OptionKey.animate);

  /// index.d.ts:3566 `startAngle: number`.
  double? get startAngle => _number(view.readKey(OptionKey.startAngle));

  /// index.d.ts:3568 `angleLines`.
  AngleLineOptions get angleLines =>
      AngleLineOptions(view.readKey(OptionKey.angleLines));

  /// index.d.ts:3613 `pointLabels`.
  PointLabelOptions get pointLabels =>
      PointLabelOptions(view.readKey(OptionKey.pointLabels));
}

/// index.d.ts:3115 `TickOptions`, with the keys of `CartesianTickOptions`
/// (index.d.ts:3179), of the linear and logarithmic ticks (index.d.ts:3376,
/// :3415), of `TimeScaleTickOptions` (index.d.ts:3466) and of
/// `RadialTickOptions` (index.d.ts:3535): the keys of `TickOptionsScope`.
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
final class const TickOptions(
  /// The resolved value of the option `ticks`: the view of its
  /// sub-resolver, or the raw value of the user (`false`).
  final Object? view,
) {
  /// The options of the resolved value [view].
  this;

  /// `ticks.setContext(context)`: the options of the tick context.
  TickOptions setContext(Object context) =>
      TickOptions(_setContext(view, context));

  /// index.d.ts:3120 `backdropColor`: the paint of the option value, or
  /// [ChartPaint.unchanged] without one.
  ChartPaint get backdropColor =>
      chartPaintOf(readOption(view, OptionKey.backdropColor));

  /// index.d.ts:3125 `backdropPadding: number | ChartArea`.
  EdgeInsets get backdropPadding =>
      paddingOption(readOption(view, OptionKey.backdropPadding));

  /// index.d.ts:3130 `callback`, the tick label callback. The raw value: a
  /// `TickCallback` of `core.scale.dart` takes a `Scale`, which this core
  /// library does not import. `tickCallbackOf` reads it.
  Object? get callback => readOption(view, OptionKey.callback);

  /// index.d.ts:3135 `display: boolean`.
  bool get display =>
      boolOption(readOption(view, OptionKey.display), OptionKey.display);

  /// index.d.ts:3140 `color`: the paint of the option value, or
  /// [ChartPaint.unchanged] without one.
  ChartPaint get color => chartPaintOf(readOption(view, OptionKey.color));

  /// index.d.ts:3144 `font`.
  TextStyle? get font => _font(readOption(view, OptionKey.font));

  /// index.d.ts:3148 `padding: number`.
  double? get padding => _number(readOption(view, OptionKey.padding));

  /// index.d.ts:3153 `showLabelBackdrop`.
  bool get showLabelBackdrop => boolOption(
    readOption(view, OptionKey.showLabelBackdrop),
    OptionKey.showLabelBackdrop,
  );

  /// index.d.ts:3158 `textStrokeColor`: the paint of the option value, or
  /// [ChartPaint.unchanged] without one.
  ChartPaint get textStrokeColor =>
      chartPaintOf(readOption(view, OptionKey.textStrokeColor));

  /// index.d.ts:3163 `textStrokeWidth`.
  double? get textStrokeWidth =>
      _number(readOption(view, OptionKey.textStrokeWidth));

  /// index.d.ts:3168 `z: number`.
  double? get z => _number(readOption(view, OptionKey.z));

  /// index.d.ts:3170 `major`.
  MajorTickOptions get major =>
      MajorTickOptions(readOption(view, OptionKey.major));

  /// index.d.ts:3184 `sampleSize: number`.
  double? get sampleSize => _number(readOption(view, OptionKey.sampleSize));

  /// index.d.ts:3189 `align: Align | 'inner'`, a [TickAlign] (row
  /// `adapt-scale-option-enums`).
  TickAlign? get align => TickAlign.of(readOption(view, OptionKey.align));

  /// index.d.ts:3194 `autoSkip: boolean`.
  bool get autoSkip =>
      boolOption(readOption(view, OptionKey.autoSkip), OptionKey.autoSkip);

  /// index.d.ts:3199 `autoSkipPadding: number`.
  double? get autoSkipPadding =>
      _number(readOption(view, OptionKey.autoSkipPadding));

  /// index.d.ts:3206 `crossAlign: 'near' | 'center' | 'far'`, a
  /// [TickCrossAlign] (row `adapt-scale-option-enums`).
  TickCrossAlign? get crossAlign =>
      TickCrossAlign.of(readOption(view, OptionKey.crossAlign));

  /// index.d.ts:3212 `includeBounds: boolean`.
  // `tickOpts.includeBounds !== false` (scale.linearbase.js:266): an absent
  // value is true.
  bool get includeBounds => boolOption(
    readOption(view, OptionKey.includeBounds),
    OptionKey.includeBounds,
    absent: true,
  );

  /// index.d.ts:3218 `labelOffset: number`.
  double? get labelOffset => _number(readOption(view, OptionKey.labelOffset));

  /// index.d.ts:3224 `minRotation: number`.
  double? get minRotation => _number(readOption(view, OptionKey.minRotation));

  /// index.d.ts:3229 `maxRotation: number`.
  double? get maxRotation => _number(readOption(view, OptionKey.maxRotation));

  /// index.d.ts:3234 `mirror: boolean`.
  bool get mirror =>
      boolOption(readOption(view, OptionKey.mirror), OptionKey.mirror);

  /// index.d.ts:3244 `maxTicksLimit: number`.
  double? get maxTicksLimit =>
      _number(readOption(view, OptionKey.maxTicksLimit));

  /// index.d.ts:3380 `format: Intl.NumberFormatOptions` of the linear,
  /// logarithmic and radial ticks: a `NumberFormat` of package:intl
  /// (Chart.js ADR 0119), or Dart `null` when absent.
  // DIVERGES(chartjs): adapt-intl-number-format, a NumberFormat.
  NumberFormat? get format =>
      numberFormatOf(readOption(view, OptionKey.format));

  /// index.d.ts:3385 `precision: number`.
  double? get precision => _number(readOption(view, OptionKey.precision));

  /// index.d.ts:3390 `stepSize: number`, also of the time ticks
  /// (index.d.ts:3481).
  double? get stepSize => _number(readOption(view, OptionKey.stepSize));

  /// index.d.ts:3395 `count: number`.
  double? get count => _number(readOption(view, OptionKey.count));

  /// index.d.ts:3476 `source: 'labels' | 'auto' | 'data'` of the time
  /// ticks, a [TickSource] (row `adapt-scale-option-enums`).
  TickSource? get source => TickSource.of(readOption(view, OptionKey.source));
}

/// index.d.ts:3170 the `major` object of [TickOptions].
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
final class const MajorTickOptions(
  /// The resolved value of the option `major`.
  final Object? view,
) {
  /// The options of the resolved value [view].
  this;

  /// index.d.ts:3175 `enabled: boolean`.
  bool get enabled =>
      boolOption(readOption(view, OptionKey.enabled), OptionKey.enabled);
}

/// index.d.ts:3060 `GridLineOptions`.
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
final class const GridLineOptions(
  /// The resolved value of the option `grid`: the view of its
  /// sub-resolver, or the raw value of the user.
  final Object? view,
) {
  /// The options of the resolved value [view].
  this;

  /// `grid.setContext(context)`: the options of the tick context.
  GridLineOptions setContext(Object context) =>
      GridLineOptions(_setContext(view, context));

  /// index.d.ts:3064 `display: boolean`.
  bool get display =>
      boolOption(readOption(view, OptionKey.display), OptionKey.display);

  /// index.d.ts:3068 `circular: boolean`.
  bool get circular =>
      boolOption(readOption(view, OptionKey.circular), OptionKey.circular);

  /// index.d.ts:3072 `color`. The raw value: the canvas takes it.
  Object? get color => readOption(view, OptionKey.color);

  /// index.d.ts:3076 `lineWidth`.
  double? get lineWidth => _number(readOption(view, OptionKey.lineWidth));

  /// index.d.ts:3080 `drawOnChartArea: boolean`.
  bool get drawOnChartArea => boolOption(
    readOption(view, OptionKey.drawOnChartArea),
    OptionKey.drawOnChartArea,
  );

  /// index.d.ts:3084 `drawTicks: boolean`.
  bool get drawTicks =>
      boolOption(readOption(view, OptionKey.drawTicks), OptionKey.drawTicks);

  /// index.d.ts:3088 `tickBorderDash` (row `adapt-dash-lists`).
  List<double>? get tickBorderDash =>
      _dash(readOption(view, OptionKey.tickBorderDash));

  /// index.d.ts:3092 `tickBorderDashOffset`.
  double? get tickBorderDashOffset =>
      _number(readOption(view, OptionKey.tickBorderDashOffset));

  /// index.d.ts:3096 `tickColor`. The raw value: the canvas takes it.
  Object? get tickColor => readOption(view, OptionKey.tickColor);

  /// index.d.ts:3100 `tickLength: number`.
  double? get tickLength => _number(readOption(view, OptionKey.tickLength));

  /// index.d.ts:3104 `tickWidth`.
  double? get tickWidth => _number(readOption(view, OptionKey.tickWidth));

  /// index.d.ts:3108 `offset: boolean`.
  bool get offset =>
      boolOption(readOption(view, OptionKey.offset), OptionKey.offset);

  /// index.d.ts:3112 `z: number`.
  double? get z => _number(readOption(view, OptionKey.z));
}

/// index.d.ts:3309 the `title` object of `CartesianScaleOptions`.
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
final class const ScaleTitleOptions(
  /// The resolved value of the option `title`.
  final Object? view,
) {
  /// The options of the resolved value [view].
  this;

  /// index.d.ts:3311 `display: boolean`.
  bool get display =>
      boolOption(readOption(view, OptionKey.display), OptionKey.display);

  /// index.d.ts:3313 `align: Align`, a [ChartAlign] (row
  /// `adapt-chart-align-enum`).
  ChartAlign? get align => ChartAlign.of(readOption(view, OptionKey.align));

  /// index.d.ts:3315 `text: string | string[]`: its lines (row
  /// `adapt-title-text-lines`). Another value stops a debug build.
  List<String> get text => _textLines(readOption(view, OptionKey.text));

  /// index.d.ts:3317 `color: Color`: the paint of the option value, or
  /// [ChartPaint.unchanged] without one.
  ChartPaint get color => chartPaintOf(readOption(view, OptionKey.color));

  /// index.d.ts:3319 `strokeColor?: Color`, as [color].
  ChartPaint get strokeColor =>
      chartPaintOf(readOption(view, OptionKey.strokeColor));

  /// index.d.ts:3321 `strokeWidth?: number`.
  double? get strokeWidth => _number(readOption(view, OptionKey.strokeWidth));

  /// index.d.ts:3323 `font`.
  TextStyle? get font => _font(readOption(view, OptionKey.font));

  /// index.d.ts:3325 `padding`.
  EdgeInsets get padding => paddingOption(readOption(view, OptionKey.padding));
}

/// index.d.ts:3429 `TimeScaleTimeOptions`.
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
final class const TimeScaleTimeOptions(
  /// The resolved value of the option `time`.
  final Object? view,
) {
  /// The options of the resolved value [view].
  this;

  /// index.d.ts:3433 `parser`. The raw value: a format text of the adapter
  /// or a `TimeParser`, which `scale.time.dart` tells apart.
  Object? get parser => readOption(view, OptionKey.parser);

  /// index.d.ts:3437 `round: false | TimeUnit`, a [TimeUnit] (row
  /// `adapt-time-unit-enum`), or Dart `null` for no rounding.
  TimeUnit? get round => TimeUnit.of(readOption(view, OptionKey.round));

  /// index.d.ts:3443 `isoWeekday: boolean | number`. The raw value: the
  /// adapter tests it as a boolean or a weekday number.
  Object? get isoWeekday => readOption(view, OptionKey.isoWeekday);

  /// index.d.ts:3447 `displayFormats`. A wrapper of the live object: the
  /// time scale merges the formats of the adapter into it
  /// (`scale.time.js:273`).
  DisplayFormats get displayFormats =>
      DisplayFormats(readOption(view, OptionKey.displayFormats));

  /// index.d.ts:3453 `tooltipFormat: string`.
  String? get tooltipFormat =>
      switch (readOption(view, OptionKey.tooltipFormat)) {
        final String format => format,
        _ => null,
      };

  /// index.d.ts:3458 `unit: false | TimeUnit`, a [TimeUnit] (row
  /// `adapt-time-unit-enum`), or Dart `null` for no unit.
  TimeUnit? get unit => TimeUnit.of(readOption(view, OptionKey.unit));

  /// index.d.ts:3463 `minUnit: TimeUnit`.
  TimeUnit? get minUnit => TimeUnit.of(readOption(view, OptionKey.minUnit));
}

/// index.d.ts:3447 the `displayFormats` object of [TimeScaleTimeOptions]:
/// a format string for each time unit and for `datetime`. It reads the
/// live object at each read: the time scale merges the formats of the
/// adapter into it after the first read.
extension type const DisplayFormats(Object? raw) {
  /// `displayFormats[unit]` (`scale.time.js:417-418`): the format of the
  /// time unit [unit], the key of the scope with the name of the unit.
  // DIVERGES(chartjs): adapt-time-unit-enum, the enum value.
  Object? formatOf(TimeUnit unit) => readOption(raw, switch (unit) {
    TimeUnit.millisecond => OptionKey.millisecond,
    TimeUnit.second => OptionKey.second,
    TimeUnit.minute => OptionKey.minute,
    TimeUnit.hour => OptionKey.hour,
    TimeUnit.day => OptionKey.day,
    TimeUnit.week => OptionKey.week,
    TimeUnit.month => OptionKey.month,
    TimeUnit.quarter => OptionKey.quarter,
    TimeUnit.year => OptionKey.year,
  });

  /// `displayFormats.datetime`.
  Object? get datetime => readOption(raw, OptionKey.datetime);

  /// `displayFormats.millisecond`.
  Object? get millisecond => readOption(raw, OptionKey.millisecond);
}

/// index.d.ts:3568 the `angleLines` object of `RadialLinearScaleOptions`.
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
final class const AngleLineOptions(
  /// The resolved value of the option `angleLines`.
  final Object? view,
) {
  /// The options of the resolved value [view].
  this;

  /// `angleLines.setContext(context)`: the options of the tick context.
  AngleLineOptions setContext(Object context) =>
      AngleLineOptions(_setContext(view, context));

  /// index.d.ts:3573 `display: boolean`.
  bool get display =>
      boolOption(readOption(view, OptionKey.display), OptionKey.display);

  /// index.d.ts:3578 `color`. The raw value: the canvas takes it.
  Object? get color => readOption(view, OptionKey.color);

  /// index.d.ts:3583 `lineWidth`.
  double? get lineWidth => _number(readOption(view, OptionKey.lineWidth));

  /// index.d.ts:3588 `borderDash` (row `adapt-dash-lists`).
  List<double>? get borderDash => _dash(readOption(view, OptionKey.borderDash));

  /// index.d.ts:3593 `borderDashOffset`.
  double? get borderDashOffset =>
      _number(readOption(view, OptionKey.borderDashOffset));
}

/// index.d.ts:3613 the `pointLabels` object of `RadialLinearScaleOptions`.
// DIVERGES(chartjs): adapt-native-scale-options, typed getters.
final class const PointLabelOptions(
  /// The resolved value of the option `pointLabels`.
  final Object? view,
) {
  /// The options of the resolved value [view].
  this;

  /// `pointLabels.setContext(context)`: the options of the label context.
  PointLabelOptions setContext(Object context) =>
      PointLabelOptions(_setContext(view, context));

  /// index.d.ts:3618 `backdropColor`. The raw value: the drawing tests its
  /// truthiness and gives it to the canvas.
  Object? get backdropColor => readOption(view, OptionKey.backdropColor);

  /// index.d.ts:3623 `backdropPadding`.
  EdgeInsets get backdropPadding =>
      paddingOption(readOption(view, OptionKey.backdropPadding));

  /// index.d.ts:3630 `borderRadius: number | BorderRadius`. The raw value:
  /// `toTRBLCorners` reads a number or an object of corners.
  Object? get borderRadius => readOption(view, OptionKey.borderRadius);

  /// index.d.ts:3636 `display: boolean | 'auto'` (row
  /// `adapt-scale-display-enum`).
  ScaleDisplay get display =>
      ScaleDisplay.of(readOption(view, OptionKey.display));

  /// index.d.ts:3641 `color`: the paint of the option value, or
  /// [ChartPaint.unchanged] without one.
  ChartPaint get color => chartPaintOf(readOption(view, OptionKey.color));

  /// index.d.ts:3644 `font`.
  TextStyle? get font => _font(readOption(view, OptionKey.font));

  /// index.d.ts:3649 `callback`. The raw value: a `PointLabelCallback` of
  /// `core.scale.dart` takes a `Scale`, which this core library does not
  /// import.
  Object? get callback => readOption(view, OptionKey.callback);

  /// index.d.ts:3655 `padding`.
  double? get padding => _number(readOption(view, OptionKey.padding));

  /// index.d.ts:3661 `centerPointLabels: boolean`.
  bool get centerPointLabels => boolOption(
    readOption(view, OptionKey.centerPointLabels),
    OptionKey.centerPointLabels,
  );
}
