// Original code, not ported from Chart.js: the value types of the typed API.

/// The value types of the typed API (Chart.js ADR 0052, section 7): the name
/// sets and the lengths of the Chart.js options.
///
/// Each type is an extension type with `const` constants. Thus a dot
/// shorthand works (`position: .top`, `easing: .easeOutQuart`), and a new
/// constant is an addition that breaks no `switch` of an app.
///
/// - [ChartPosition], [ChartAlign], [ChartInteractionMode] and [ChartEasing]
///   are over `String`. The option value is their `name`.
/// - [ChartPointStyle], [ChartFill] and [ChartLength] are over `Object`:
///   they also hold `false`, numbers and records. The internal getter
///   `optionValue` gives the option value. A record holds
///   [ChartFill.value] and [ChartLength.percent], so these constructors are
///   `const`, and two equal values are `==`.
///
/// [ChartInteractionMode] and [ChartEasing] have a public constructor for a
/// custom name. The other types have private constructors: Chart.js has no
/// registry for their names.
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsNumberToString;
import 'package:meta/meta.dart' show internal;

/// The position of a box in the chart layout: the `position` option of the
/// legend, the title, the subtitle and an axis (`LayoutPosition`,
/// `layout.d.ts:3`).
///
/// The title and the subtitle take [top], [left], [bottom] and [right]
/// (`index.d.ts:2594`). The legend also takes [chartArea]. An axis takes
/// [top], [left], [bottom], [right] and [center] (`index.d.ts:3270`). The
/// position of an axis at a value of another axis (`{x: 0}`) goes through
/// the `extra` Map of the axis.
extension type const ChartPosition._(String name) {
  /// `'top'`: above the chart area.
  static const ChartPosition top = ChartPosition._('top');

  /// `'left'`: to the left of the chart area.
  static const ChartPosition left = ChartPosition._('left');

  /// `'bottom'`: below the chart area.
  static const ChartPosition bottom = ChartPosition._('bottom');

  /// `'right'`: to the right of the chart area.
  static const ChartPosition right = ChartPosition._('right');

  /// `'center'`: an axis through the center of the chart area.
  static const ChartPosition center = ChartPosition._('center');

  /// `'chartArea'`: a legend inside the chart area.
  static const ChartPosition chartArea = ChartPosition._('chartArea');
}

/// The alignment of a box or of a text along its side: the `align` option of
/// the legend, the title, the subtitle and an axis title (`Align`,
/// `index.d.ts:1844`).
extension type const ChartAlign._(String name) {
  /// `'start'`: the left or the top end.
  static const ChartAlign start = ChartAlign._('start');

  /// `'center'`: the middle.
  static const ChartAlign center = ChartAlign._('center');

  /// `'end'`: the right or the bottom end.
  static const ChartAlign end = ChartAlign._('end');
}

/// An interaction mode: the `mode` of the `interaction` and `tooltip`
/// options, a key of `Interaction.modes` (`InteractionModeMap`,
/// `index.d.ts:770-799`).
///
/// The constructor names a custom mode that the app adds to
/// `Interaction.modes`.
extension type const ChartInteractionMode(String name) {
  /// `'index'`: the items at the same index.
  static const ChartInteractionMode index = ChartInteractionMode('index');

  /// `'dataset'`: the items of the same dataset.
  static const ChartInteractionMode dataset = ChartInteractionMode('dataset');

  /// `'point'`: the items that intersect the point.
  static const ChartInteractionMode point = ChartInteractionMode('point');

  /// `'nearest'`: the items nearest to the point.
  static const ChartInteractionMode nearest = ChartInteractionMode('nearest');

  /// `'x'`: the items at the x position of the point.
  static const ChartInteractionMode x = ChartInteractionMode('x');

  /// `'y'`: the items at the y position of the point.
  static const ChartInteractionMode y = ChartInteractionMode('y');
}

/// An easing function by name: the `easing` option of an animation, a key
/// of the easing effects (`helpers.easing.ts:12-122`).
///
/// The animation reads the name (`core.animation.js:36`). A name that is not
/// a key of the effects gives [linear]. The constructor names a custom
/// effect that the app adds to `easingEffects` of `helpers.dart`. A Flutter
/// `Curve` has no name, so the typed API takes the name.
extension type const ChartEasing(String name) {
  /// `'linear'`.
  static const ChartEasing linear = ChartEasing('linear');

  /// `'easeInQuad'`.
  static const ChartEasing easeInQuad = ChartEasing('easeInQuad');

  /// `'easeOutQuad'`.
  static const ChartEasing easeOutQuad = ChartEasing('easeOutQuad');

  /// `'easeInOutQuad'`.
  static const ChartEasing easeInOutQuad = ChartEasing('easeInOutQuad');

  /// `'easeInCubic'`.
  static const ChartEasing easeInCubic = ChartEasing('easeInCubic');

  /// `'easeOutCubic'`.
  static const ChartEasing easeOutCubic = ChartEasing('easeOutCubic');

  /// `'easeInOutCubic'`.
  static const ChartEasing easeInOutCubic = ChartEasing('easeInOutCubic');

  /// `'easeInQuart'`.
  static const ChartEasing easeInQuart = ChartEasing('easeInQuart');

  /// `'easeOutQuart'`, the default of the Chart.js animations.
  static const ChartEasing easeOutQuart = ChartEasing('easeOutQuart');

  /// `'easeInOutQuart'`.
  static const ChartEasing easeInOutQuart = ChartEasing('easeInOutQuart');

  /// `'easeInQuint'`.
  static const ChartEasing easeInQuint = ChartEasing('easeInQuint');

  /// `'easeOutQuint'`.
  static const ChartEasing easeOutQuint = ChartEasing('easeOutQuint');

  /// `'easeInOutQuint'`.
  static const ChartEasing easeInOutQuint = ChartEasing('easeInOutQuint');

  /// `'easeInSine'`.
  static const ChartEasing easeInSine = ChartEasing('easeInSine');

  /// `'easeOutSine'`.
  static const ChartEasing easeOutSine = ChartEasing('easeOutSine');

  /// `'easeInOutSine'`.
  static const ChartEasing easeInOutSine = ChartEasing('easeInOutSine');

  /// `'easeInExpo'`.
  static const ChartEasing easeInExpo = ChartEasing('easeInExpo');

  /// `'easeOutExpo'`.
  static const ChartEasing easeOutExpo = ChartEasing('easeOutExpo');

  /// `'easeInOutExpo'`.
  static const ChartEasing easeInOutExpo = ChartEasing('easeInOutExpo');

  /// `'easeInCirc'`.
  static const ChartEasing easeInCirc = ChartEasing('easeInCirc');

  /// `'easeOutCirc'`.
  static const ChartEasing easeOutCirc = ChartEasing('easeOutCirc');

  /// `'easeInOutCirc'`.
  static const ChartEasing easeInOutCirc = ChartEasing('easeInOutCirc');

  /// `'easeInElastic'`.
  static const ChartEasing easeInElastic = ChartEasing('easeInElastic');

  /// `'easeOutElastic'`.
  static const ChartEasing easeOutElastic = ChartEasing('easeOutElastic');

  /// `'easeInOutElastic'`.
  static const ChartEasing easeInOutElastic = ChartEasing('easeInOutElastic');

  /// `'easeInBack'`.
  static const ChartEasing easeInBack = ChartEasing('easeInBack');

  /// `'easeOutBack'`.
  static const ChartEasing easeOutBack = ChartEasing('easeOutBack');

  /// `'easeInOutBack'`.
  static const ChartEasing easeInOutBack = ChartEasing('easeInOutBack');

  /// `'easeInBounce'`.
  static const ChartEasing easeInBounce = ChartEasing('easeInBounce');

  /// `'easeOutBounce'`.
  static const ChartEasing easeOutBounce = ChartEasing('easeOutBounce');

  /// `'easeInOutBounce'`.
  static const ChartEasing easeInOutBounce = ChartEasing('easeInOutBounce');
}

/// The style of a point: the `pointStyle` option of a dataset and of the
/// legend labels (`PointStyle`, `index.d.ts:2040-2053`).
///
/// [none] is `false`: no point. An image goes through the `extra` Map.
extension type const ChartPointStyle._(Object _value) {
  /// `'circle'`.
  static const ChartPointStyle circle = ChartPointStyle._('circle');

  /// `'cross'`.
  static const ChartPointStyle cross = ChartPointStyle._('cross');

  /// `'crossRot'`: a cross turned by 45 degrees.
  static const ChartPointStyle crossRot = ChartPointStyle._('crossRot');

  /// `'dash'`.
  static const ChartPointStyle dash = ChartPointStyle._('dash');

  /// `'line'`.
  static const ChartPointStyle line = ChartPointStyle._('line');

  /// `'rect'`.
  static const ChartPointStyle rect = ChartPointStyle._('rect');

  /// `'rectRounded'`.
  static const ChartPointStyle rectRounded = ChartPointStyle._('rectRounded');

  /// `'rectRot'`: a square turned by 45 degrees.
  static const ChartPointStyle rectRot = ChartPointStyle._('rectRot');

  /// `'star'`.
  static const ChartPointStyle star = ChartPointStyle._('star');

  /// `'triangle'`.
  static const ChartPointStyle triangle = ChartPointStyle._('triangle');

  /// `false`: no point.
  static const ChartPointStyle none = ChartPointStyle._(false);

  /// The option value: the name, or `false` for [none].
  @internal
  Object get optionValue => _value;
}

/// The fill of a line or a radar dataset: the `fill` option
/// (`FillTarget`, `index.d.ts:2300`; `filler.options.js:120-137`).
///
/// The complex form `{target, above, below}` goes through the `extra` Map
/// of the dataset.
extension type const ChartFill._(Object _value) {
  /// The fill to the dataset at the absolute [index] of `data.datasets`:
  /// the number.
  const ChartFill.dataset(int index) : _value = index;

  /// The fill to the dataset at [offset] from this dataset: `'+1'` for 1,
  /// `'-1'` for -1.
  const ChartFill.relative(int offset)
    : _value = offset >= 0 ? '+$offset' : '$offset';

  /// The fill to the line at [value] of the value axis: `{value: n}`.
  const ChartFill.value(num value) : _value = (value: value);

  /// `'origin'`: the fill to the origin of the value axis. Chart.js gives
  /// it also for `fill: true`.
  static const ChartFill origin = ChartFill._('origin');

  /// `'start'`: the fill to the start of the value axis.
  static const ChartFill start = ChartFill._('start');

  /// `'end'`: the fill to the end of the value axis.
  static const ChartFill end = ChartFill._('end');

  /// `'stack'`: the fill to the dataset below in the stack.
  static const ChartFill stack = ChartFill._('stack');

  /// `'shape'`: the fill of the closed shape, for a radar dataset.
  static const ChartFill shape = ChartFill._('shape');

  /// `false`: no fill.
  static const ChartFill none = ChartFill._(false);

  /// The option value: a name, `false`, a number, a `'+n'` or `'-n'`
  /// string, or a new Map `{value: n}` for [ChartFill.value].
  @internal
  Object get optionValue => switch (_value) {
    (value: final num value) => <String, Object?>{'value': value},
    final other => other,
  };
}

/// A length in pixels or in percent: the `cutout` and `radius` options of
/// a pie or a doughnut dataset (`index.d.ts:319`, `:330`).
///
/// A number gives pixels. A string that ends with `%` gives a percent:
/// of the outer radius for `cutout`, of the largest radius for `radius`.
extension type const ChartLength._(Object _value) {
  /// [pixels] pixels: the number.
  const ChartLength.pixels(double pixels) : _value = pixels;

  /// [percent] percent: the string `'<percent>%'`, for example `'50%'`.
  const ChartLength.percent(double percent) : _value = (percent: percent);

  /// The option value: the number of [ChartLength.pixels], or the string of
  /// [ChartLength.percent] with the JS form of the number (`'50%'`, not
  /// `'50.0%'`).
  @internal
  Object get optionValue => switch (_value) {
    (percent: final double percent) => '${jsNumberToString(percent)}%',
    final other => other,
  };
}
