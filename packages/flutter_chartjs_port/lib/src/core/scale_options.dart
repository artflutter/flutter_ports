// Original code, not ported from Chart.js: the scale option facades.

/// The typed facades of the scale options (Chart.js ADR 0054 §4).
///
/// `Scale.options` is the `ContextProxy` of the scale, an [OptionView] over
/// the scope list of a typed `ScaleOptionsScope` (`core.config.js:71-113`
/// makes it). Upstream reads each option as a property: `this.options.ticks`,
/// `tickOpts.padding`. A facade is an extension type over the view (no
/// object, no cost) with one getter for each key that the port reads. A
/// getter is the typed read `readKey` of the key: the `get` trap of upstream
/// with an [OptionKey], no `String` key and no hash lookup.
///
/// The names are the `index.d.ts` names of the option interfaces
/// ([CoreScaleOptions], [CartesianScaleOptions], [TickOptions],
/// [GridLineOptions], [BorderOptions], ...). The schema has one scope kind
/// for the options of every scale type (`ScaleOptionsScope`) and one for
/// the ticks of every scale type (`TickOptionsScope`). Thus a facade has
/// each key that the port reads through it, also a key that `index.d.ts`
/// declares in an interface of a scale type: `core.scale.js` reads
/// `this.options.grid`, `this.options.ticks.mirror` and the other cartesian
/// options on each scale, and `scale.linearbase.js` reads `bounds` and the
/// linear tick options for the radial scale too.
///
/// A getter gives the resolved JS value of the option, as the upstream read
/// does: a scriptable option gives the result of its function, and an
/// option object gives the view of its sub-resolver. A leaf value has the
/// type `Object?`: the user can give a value of another type (a string
/// `padding`, a function result), and each reader applies the upstream JS
/// operator to it (`jsAdd`, `jsToNumber`, `jsTruthy`, a strict compare).
/// The options that the schema keeps foreign for a string (the `startAngle`
/// of the scale, the `size` of a font, the `padding` of the point labels)
/// reach their readers as the string.
///
/// The facade of a nested option object ([TickOptions], [GridLineOptions],
/// ...) holds any JS value ([TickOptions.raw]) and reads its keys with
/// [readOption] of `helpers.config.dart`: `readKey` for a view, else the JS
/// property read. `ticks: false` resolves to `false`, and the read of a key
/// of it gives `undefined`, as the property read of a primitive does. A
/// read of a key of `null` or `undefined` throws a `TypeError`, as
/// upstream. A test that gives a scale plain Map options reads them by
/// name through the same function.
///
/// This library imports `helpers.config.dart`, `lib/src/js/` and
/// `lib/src/options/`: a pure layer.
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show ContextProxy, OptionView, readOption;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsToString;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// `options.setContext(context)` of a nested option object: a view of the
/// same resolver with the context [context].
///
/// The option objects of a scale are `ContextProxy` resolvers. Another value
/// has no `setContext`. JavaScript then throws a `TypeError` at the call.
/// Here the cast throws it.
ContextProxy _setContext(Object? options, AnyObject context) =>
    (options! as ContextProxy).setContext(context);

/// index.d.ts:1200 `CoreScaleOptions`: the options of a scale, the view
/// `Scale.options`.
///
/// It also has the keys of `CartesianScaleOptions` (index.d.ts:3257) and of
/// the linear scale options that `core.scale.js` and `scale.linearbase.js`
/// read through `this.options` of each scale: [axis], [position], [offset],
/// [bounds], [grid], [border], [title], [labels], [beginAtZero], [grace]
/// and [fullSize].
extension type const CoreScaleOptions(OptionView _view) implements OptionView {
  /// index.d.ts:1205 `display: boolean | 'auto'`.
  Object? get display => _view.readKey(OptionKey.display);

  /// index.d.ts:1209 `alignToPixels: boolean`.
  Object? get alignToPixels => _view.readKey(OptionKey.alignToPixels);

  /// index.d.ts:1213 `backgroundColor: Color`.
  Object? get backgroundColor => _view.readKey(OptionKey.backgroundColor);

  /// index.d.ts:1218 `reverse: boolean`.
  Object? get reverse => _view.readKey(OptionKey.reverse);

  /// index.d.ts:1223 `clip: boolean`.
  Object? get clip => _view.readKey(OptionKey.clip);

  /// index.d.ts:1228 `weight: number`.
  Object? get weight => _view.readKey(OptionKey.weight);

  /// index.d.ts:1232 `min: unknown`.
  Object? get min => _view.readKey(OptionKey.min);

  /// index.d.ts:1236 `max: unknown`.
  Object? get max => _view.readKey(OptionKey.max);

  /// index.d.ts:1240 `suggestedMin: unknown`.
  Object? get suggestedMin => _view.readKey(OptionKey.suggestedMin);

  /// index.d.ts:1244 `suggestedMax: unknown`.
  Object? get suggestedMax => _view.readKey(OptionKey.suggestedMax);

  /// index.d.ts:1248 `beforeUpdate(axis: Scale): void`.
  Object? get beforeUpdate => _view.readKey(OptionKey.beforeUpdate);

  /// index.d.ts:1252 `beforeSetDimensions(axis: Scale): void`.
  Object? get beforeSetDimensions =>
      _view.readKey(OptionKey.beforeSetDimensions);

  /// index.d.ts:1256 `afterSetDimensions(axis: Scale): void`.
  Object? get afterSetDimensions => _view.readKey(OptionKey.afterSetDimensions);

  /// index.d.ts:1260 `beforeDataLimits(axis: Scale): void`.
  Object? get beforeDataLimits => _view.readKey(OptionKey.beforeDataLimits);

  /// index.d.ts:1264 `afterDataLimits(axis: Scale): void`.
  Object? get afterDataLimits => _view.readKey(OptionKey.afterDataLimits);

  /// index.d.ts:1268 `beforeBuildTicks(axis: Scale): void`.
  Object? get beforeBuildTicks => _view.readKey(OptionKey.beforeBuildTicks);

  /// index.d.ts:1272 `afterBuildTicks(axis: Scale): void`.
  Object? get afterBuildTicks => _view.readKey(OptionKey.afterBuildTicks);

  /// index.d.ts:1276 `beforeTickToLabelConversion(axis: Scale): void`.
  Object? get beforeTickToLabelConversion =>
      _view.readKey(OptionKey.beforeTickToLabelConversion);

  /// index.d.ts:1280 `afterTickToLabelConversion(axis: Scale): void`.
  Object? get afterTickToLabelConversion =>
      _view.readKey(OptionKey.afterTickToLabelConversion);

  /// index.d.ts:1284 `beforeCalculateLabelRotation(axis: Scale): void`.
  Object? get beforeCalculateLabelRotation =>
      _view.readKey(OptionKey.beforeCalculateLabelRotation);

  /// index.d.ts:1288 `afterCalculateLabelRotation(axis: Scale): void`.
  Object? get afterCalculateLabelRotation =>
      _view.readKey(OptionKey.afterCalculateLabelRotation);

  /// index.d.ts:1292 `beforeFit(axis: Scale): void`.
  Object? get beforeFit => _view.readKey(OptionKey.beforeFit);

  /// index.d.ts:1296 `afterFit(axis: Scale): void`.
  Object? get afterFit => _view.readKey(OptionKey.afterFit);

  /// index.d.ts:1300 `afterUpdate(axis: Scale): void`.
  Object? get afterUpdate => _view.readKey(OptionKey.afterUpdate);

  /// index.d.ts:3286 `axis: 'x' | 'y' | 'r'` of `CartesianScaleOptions`.
  /// `core.config` gives each scale an `axis` option.
  Object? get axis => _view.readKey(OptionKey.axis);

  /// index.d.ts:3270 `position` of `CartesianScaleOptions`: a position name
  /// or an object `{[scale]: number}`.
  Object? get position => _view.readKey(OptionKey.position);

  /// index.d.ts:3302 `offset: boolean` of `CartesianScaleOptions`.
  Object? get offset => _view.readKey(OptionKey.offset);

  /// index.d.ts:3265 `bounds: 'ticks' | 'data'` of `CartesianScaleOptions`.
  /// `scale.linearbase.js:182` reads it for the radial scale too.
  Object? get bounds => _view.readKey(OptionKey.bounds);

  /// index.d.ts:3347 `labels` of `CategoryScaleOptions`. `getLabels`
  /// (core.scale.js:359) reads it on each scale.
  Object? get labels => _view.readKey(OptionKey.labels);

  /// index.d.ts:3362 `beginAtZero` of `LinearScaleOptions`. `update`
  /// (core.scale.js:394) reads it on each scale.
  Object? get beginAtZero => _view.readKey(OptionKey.beginAtZero);

  /// index.d.ts:3374 `grace` of `LinearScaleOptions`. `update`
  /// (core.scale.js:394) reads it on each scale.
  Object? get grace => _view.readKey(OptionKey.grace);

  /// `fullSize`, the option of the layout box (`layout.d.ts:17`).
  /// `isFullSize` (core.scale.js:768) reads it.
  Object? get fullSize => _view.readKey(OptionKey.fullSize);

  /// index.d.ts:3341 `ticks`.
  TickOptions get ticks => TickOptions(_view.readKey(OptionKey.ticks));

  /// index.d.ts:3304 `grid: Partial<GridLineOptions>` of
  /// `CartesianScaleOptions`.
  GridLineOptions get grid => GridLineOptions(_view.readKey(OptionKey.grid));

  /// index.d.ts:3306 `border: BorderOptions` of `CartesianScaleOptions`.
  BorderOptions get border => BorderOptions(_view.readKey(OptionKey.border));

  /// index.d.ts:3309 `title` of `CartesianScaleOptions`.
  ScaleTitleOptions get title =>
      ScaleTitleOptions(_view.readKey(OptionKey.title));
}

/// index.d.ts:3257 `CartesianScaleOptions`: the keys that the cartesian
/// scales have beside [CoreScaleOptions].
extension type const CartesianScaleOptions(OptionView _view)
    implements CoreScaleOptions {
  /// index.d.ts:3275 `stack?: string`.
  ///
  /// It is the option `stack`, not the `_stack` of the cache object of the
  /// view ([OptionView.stack]).
  Object? get stack => _view.readKey(OptionKey.stack);

  /// index.d.ts:3281 `stackWeight?: number`.
  Object? get stackWeight => _view.readKey(OptionKey.stackWeight);

  /// index.d.ts:3339 `stacked?: boolean | 'single'`.
  Object? get stacked => _view.readKey(OptionKey.stacked);
}

/// index.d.ts:3344 `CategoryScaleOptions`. Its `labels` is
/// [CoreScaleOptions.labels].
extension type const CategoryScaleOptions(OptionView _view)
    implements CartesianScaleOptions {}

/// index.d.ts:3356 `LinearScaleOptions`. Its keys are in
/// [CoreScaleOptions] and [TickOptions].
extension type const LinearScaleOptions(OptionView _view)
    implements CartesianScaleOptions {}

/// index.d.ts:3405 `LogarithmicScaleOptions`. Its keys are in
/// [CoreScaleOptions] and [TickOptions].
extension type const LogarithmicScaleOptions(OptionView _view)
    implements CartesianScaleOptions {}

/// index.d.ts:3484 `TimeScaleOptions`.
extension type const TimeScaleOptions(OptionView _view)
    implements CartesianScaleOptions {
  /// index.d.ts:3503 `offsetAfterAutoskip: boolean`.
  Object? get offsetAfterAutoskip =>
      _view.readKey(OptionKey.offsetAfterAutoskip);

  /// index.d.ts:3508 `adapters: {date: unknown}`.
  ///
  /// The resolver gives the raw value: `adapters` makes no sub-resolver
  /// (helpers.config.ts:215). The time scale reads its `date` by name.
  Object? get adapters => _view.readKey(OptionKey.adapters);

  /// index.d.ts:3512 `time: TimeScaleTimeOptions`.
  TimeScaleTimeOptions get time =>
      TimeScaleTimeOptions(_view.readKey(OptionKey.time));
}

/// index.d.ts:3563 `RadialLinearScaleOptions`.
extension type const RadialLinearScaleOptions(OptionView _view)
    implements CoreScaleOptions {
  /// index.d.ts:3564 `animate: boolean`.
  Object? get animate => _view.readKey(OptionKey.animate);

  /// index.d.ts:3566 `startAngle: number`. A string `startAngle` stays a
  /// string (a foreign value of the scope).
  Object? get startAngle => _view.readKey(OptionKey.startAngle);

  /// index.d.ts:3568 `angleLines`.
  AngleLineOptions get angleLines =>
      AngleLineOptions(_view.readKey(OptionKey.angleLines));

  /// index.d.ts:3613 `pointLabels`.
  PointLabelOptions get pointLabels =>
      PointLabelOptions(_view.readKey(OptionKey.pointLabels));
}

/// index.d.ts:3115 `TickOptions`, with the keys of `CartesianTickOptions`
/// (index.d.ts:3179), of the linear and logarithmic ticks (index.d.ts:3376,
/// :3415), of `TimeScaleTickOptions` (index.d.ts:3466) and of
/// `RadialTickOptions` (index.d.ts:3535): the keys of `TickOptionsScope`.
extension type const TickOptions(Object? raw) {
  /// `ticks.setContext(context)`.
  TickOptions setContext(AnyObject context) =>
      TickOptions(_setContext(raw, context));

  /// index.d.ts:3120 `backdropColor`.
  Object? get backdropColor => readOption(raw, OptionKey.backdropColor);

  /// index.d.ts:3125 `backdropPadding: number | ChartArea`.
  Object? get backdropPadding => readOption(raw, OptionKey.backdropPadding);

  /// index.d.ts:3130 `callback`, the tick label callback.
  Object? get callback => readOption(raw, OptionKey.callback);

  /// index.d.ts:3135 `display: boolean`.
  Object? get display => readOption(raw, OptionKey.display);

  /// index.d.ts:3140 `color`.
  Object? get color => readOption(raw, OptionKey.color);

  /// index.d.ts:3144 `font`.
  Object? get font => readOption(raw, OptionKey.font);

  /// index.d.ts:3148 `padding: number`. A string padding stays a string.
  Object? get padding => readOption(raw, OptionKey.padding);

  /// index.d.ts:3153 `showLabelBackdrop`.
  Object? get showLabelBackdrop => readOption(raw, OptionKey.showLabelBackdrop);

  /// index.d.ts:3158 `textStrokeColor`.
  Object? get textStrokeColor => readOption(raw, OptionKey.textStrokeColor);

  /// index.d.ts:3163 `textStrokeWidth`.
  Object? get textStrokeWidth => readOption(raw, OptionKey.textStrokeWidth);

  /// index.d.ts:3168 `z: number`.
  Object? get z => readOption(raw, OptionKey.z);

  /// index.d.ts:3170 `major`.
  MajorTickOptions get major =>
      MajorTickOptions(readOption(raw, OptionKey.major));

  /// index.d.ts:3184 `sampleSize: number`.
  Object? get sampleSize => readOption(raw, OptionKey.sampleSize);

  /// index.d.ts:3189 `align: Align | 'inner'`.
  Object? get align => readOption(raw, OptionKey.align);

  /// index.d.ts:3194 `autoSkip: boolean`.
  Object? get autoSkip => readOption(raw, OptionKey.autoSkip);

  /// index.d.ts:3199 `autoSkipPadding: number`.
  Object? get autoSkipPadding => readOption(raw, OptionKey.autoSkipPadding);

  /// index.d.ts:3206 `crossAlign: 'near' | 'center' | 'far'`.
  Object? get crossAlign => readOption(raw, OptionKey.crossAlign);

  /// index.d.ts:3212 `includeBounds: boolean`.
  Object? get includeBounds => readOption(raw, OptionKey.includeBounds);

  /// index.d.ts:3218 `labelOffset: number`.
  Object? get labelOffset => readOption(raw, OptionKey.labelOffset);

  /// index.d.ts:3224 `minRotation: number`.
  Object? get minRotation => readOption(raw, OptionKey.minRotation);

  /// index.d.ts:3229 `maxRotation: number`.
  Object? get maxRotation => readOption(raw, OptionKey.maxRotation);

  /// index.d.ts:3234 `mirror: boolean`.
  Object? get mirror => readOption(raw, OptionKey.mirror);

  /// index.d.ts:3244 `maxTicksLimit: number`.
  Object? get maxTicksLimit => readOption(raw, OptionKey.maxTicksLimit);

  /// index.d.ts:3380 `format: Intl.NumberFormatOptions` of the linear,
  /// logarithmic and radial ticks.
  Object? get format => readOption(raw, OptionKey.format);

  /// index.d.ts:3385 `precision: number`.
  Object? get precision => readOption(raw, OptionKey.precision);

  /// index.d.ts:3390 `stepSize: number`, also of the time ticks
  /// (index.d.ts:3481).
  Object? get stepSize => readOption(raw, OptionKey.stepSize);

  /// index.d.ts:3395 `count: number`.
  Object? get count => readOption(raw, OptionKey.count);

  /// index.d.ts:3476 `source: 'labels' | 'auto' | 'data'` of the time
  /// ticks.
  Object? get source => readOption(raw, OptionKey.source);
}

/// index.d.ts:1812 `FontSpec`: a font option object, for example the
/// `font` of [TickOptions] or `defaults.font`. The Dart name `FontSpec` is
/// the interface of the parsed font in `lib/src/types/`.
extension type const FontSpecOptions(Object? raw) {
  /// index.d.ts:1822 `size: number`. A string size stays a string (a
  /// foreign value of the scope).
  Object? get size => readOption(raw, OptionKey.size);
}

/// index.d.ts:3170 the `major` object of [TickOptions].
extension type const MajorTickOptions(Object? raw) {
  /// index.d.ts:3175 `enabled: boolean`.
  Object? get enabled => readOption(raw, OptionKey.enabled);
}

/// index.d.ts:3060 `GridLineOptions`.
extension type const GridLineOptions(Object? raw) {
  /// `grid.setContext(context)`.
  GridLineOptions setContext(AnyObject context) =>
      GridLineOptions(_setContext(raw, context));

  /// index.d.ts:3064 `display: boolean`.
  Object? get display => readOption(raw, OptionKey.display);

  /// index.d.ts:3068 `circular: boolean`.
  Object? get circular => readOption(raw, OptionKey.circular);

  /// index.d.ts:3072 `color`.
  Object? get color => readOption(raw, OptionKey.color);

  /// index.d.ts:3076 `lineWidth`.
  Object? get lineWidth => readOption(raw, OptionKey.lineWidth);

  /// index.d.ts:3080 `drawOnChartArea: boolean`.
  Object? get drawOnChartArea => readOption(raw, OptionKey.drawOnChartArea);

  /// index.d.ts:3084 `drawTicks: boolean`.
  Object? get drawTicks => readOption(raw, OptionKey.drawTicks);

  /// index.d.ts:3088 `tickBorderDash`.
  Object? get tickBorderDash => readOption(raw, OptionKey.tickBorderDash);

  /// index.d.ts:3092 `tickBorderDashOffset`.
  Object? get tickBorderDashOffset =>
      readOption(raw, OptionKey.tickBorderDashOffset);

  /// index.d.ts:3096 `tickColor`.
  Object? get tickColor => readOption(raw, OptionKey.tickColor);

  /// index.d.ts:3100 `tickLength: number`. A string `tickLength` stays a
  /// string: `'8' + 0` joins (core.scale.js:649).
  Object? get tickLength => readOption(raw, OptionKey.tickLength);

  /// index.d.ts:3104 `tickWidth`.
  Object? get tickWidth => readOption(raw, OptionKey.tickWidth);

  /// index.d.ts:3108 `offset: boolean`.
  Object? get offset => readOption(raw, OptionKey.offset);

  /// index.d.ts:3112 `z: number`.
  Object? get z => readOption(raw, OptionKey.z);
}

/// index.d.ts:3042 `BorderOptions`.
extension type const BorderOptions(Object? raw) {
  /// `border.setContext(context)`.
  BorderOptions setContext(AnyObject context) =>
      BorderOptions(_setContext(raw, context));

  /// index.d.ts:3046 `display: boolean`.
  Object? get display => readOption(raw, OptionKey.display);

  /// index.d.ts:3050 `dash`.
  Object? get dash => readOption(raw, OptionKey.dash);

  /// index.d.ts:3054 `dashOffset`.
  Object? get dashOffset => readOption(raw, OptionKey.dashOffset);

  /// index.d.ts:3055 `color: Color`.
  Object? get color => readOption(raw, OptionKey.color);

  /// index.d.ts:3056 `width: number`.
  Object? get width => readOption(raw, OptionKey.width);

  /// index.d.ts:3057 `z: number`.
  Object? get z => readOption(raw, OptionKey.z);
}

/// index.d.ts:3309 the `title` object of `CartesianScaleOptions`.
extension type const ScaleTitleOptions(Object? raw) {
  /// index.d.ts:3311 `display: boolean`.
  Object? get display => readOption(raw, OptionKey.display);

  /// index.d.ts:3313 `align: Align`.
  Object? get align => readOption(raw, OptionKey.align);

  /// index.d.ts:3315 `text: string | string[]`.
  Object? get text => readOption(raw, OptionKey.text);

  /// index.d.ts:3317 `color: Color`.
  Object? get color => readOption(raw, OptionKey.color);

  /// index.d.ts:3319 `strokeColor?: Color`.
  Object? get strokeColor => readOption(raw, OptionKey.strokeColor);

  /// index.d.ts:3321 `strokeWidth?: number`.
  Object? get strokeWidth => readOption(raw, OptionKey.strokeWidth);

  /// index.d.ts:3323 `font`.
  Object? get font => readOption(raw, OptionKey.font);

  /// index.d.ts:3325 `padding`.
  Object? get padding => readOption(raw, OptionKey.padding);
}

/// index.d.ts:3429 `TimeScaleTimeOptions`.
extension type const TimeScaleTimeOptions(Object? raw) {
  /// index.d.ts:3433 `parser`.
  Object? get parser => readOption(raw, OptionKey.parser);

  /// index.d.ts:3437 `round: false | TimeUnit`.
  Object? get round => readOption(raw, OptionKey.round);

  /// index.d.ts:3443 `isoWeekday: boolean | number`.
  Object? get isoWeekday => readOption(raw, OptionKey.isoWeekday);

  /// index.d.ts:3447 `displayFormats`.
  DisplayFormats get displayFormats =>
      DisplayFormats(readOption(raw, OptionKey.displayFormats));

  /// index.d.ts:3453 `tooltipFormat: string`.
  Object? get tooltipFormat => readOption(raw, OptionKey.tooltipFormat);

  /// index.d.ts:3458 `unit: false | TimeUnit`.
  Object? get unit => readOption(raw, OptionKey.unit);

  /// index.d.ts:3463 `minUnit: TimeUnit`.
  Object? get minUnit => readOption(raw, OptionKey.minUnit);
}

/// index.d.ts:3447 the `displayFormats` object of [TimeScaleTimeOptions]:
/// a format string for each time unit and for `datetime`.
extension type const DisplayFormats(Object? raw) {
  /// `displayFormats[unit]` for a unit that the program computes ([unit]
  /// is any JS value, a property key after `ToPropertyKey`): the typed read
  /// for a name of the schema, else the JS property read by name.
  ///
  /// The time scale reads it with the unit of the scale
  /// (`scale.time.js:417-418`), a name that the user can choose.
  Object? formatOf(Object? unit) {
    final key = optionKeyOf(unit is String ? unit : jsToString(unit));
    if (key != null) return readOption(raw, key);
    // A name outside the schema, for example a unit of a custom date
    // adapter: the JS property read by name.
    return jsGet(raw, unit);
  }

  /// `displayFormats.datetime`.
  Object? get datetime => readOption(raw, OptionKey.datetime);

  /// `displayFormats.millisecond`.
  Object? get millisecond => readOption(raw, OptionKey.millisecond);
}

/// index.d.ts:3568 the `angleLines` object of `RadialLinearScaleOptions`.
extension type const AngleLineOptions(Object? raw) {
  /// `angleLines.setContext(context)`.
  AngleLineOptions setContext(AnyObject context) =>
      AngleLineOptions(_setContext(raw, context));

  /// index.d.ts:3573 `display: boolean`.
  Object? get display => readOption(raw, OptionKey.display);

  /// index.d.ts:3578 `color`.
  Object? get color => readOption(raw, OptionKey.color);

  /// index.d.ts:3583 `lineWidth`.
  Object? get lineWidth => readOption(raw, OptionKey.lineWidth);

  /// index.d.ts:3588 `borderDash`.
  Object? get borderDash => readOption(raw, OptionKey.borderDash);

  /// index.d.ts:3593 `borderDashOffset`.
  Object? get borderDashOffset => readOption(raw, OptionKey.borderDashOffset);
}

/// index.d.ts:3613 the `pointLabels` object of `RadialLinearScaleOptions`.
extension type const PointLabelOptions(Object? raw) {
  /// `pointLabels.setContext(context)`.
  PointLabelOptions setContext(AnyObject context) =>
      PointLabelOptions(_setContext(raw, context));

  /// index.d.ts:3618 `backdropColor`.
  Object? get backdropColor => readOption(raw, OptionKey.backdropColor);

  /// index.d.ts:3623 `backdropPadding`.
  Object? get backdropPadding => readOption(raw, OptionKey.backdropPadding);

  /// index.d.ts:3630 `borderRadius`.
  Object? get borderRadius => readOption(raw, OptionKey.borderRadius);

  /// index.d.ts:3636 `display: boolean | 'auto'`.
  Object? get display => readOption(raw, OptionKey.display);

  /// index.d.ts:3641 `color`.
  Object? get color => readOption(raw, OptionKey.color);

  /// index.d.ts:3644 `font`.
  Object? get font => readOption(raw, OptionKey.font);

  /// index.d.ts:3649 `callback`.
  Object? get callback => readOption(raw, OptionKey.callback);

  /// index.d.ts:3655 `padding`. A string padding stays a string (a
  /// foreign value of the scope).
  Object? get padding => readOption(raw, OptionKey.padding);

  /// index.d.ts:3661 `centerPointLabels: boolean`.
  Object? get centerPointLabels => readOption(raw, OptionKey.centerPointLabels);
}
