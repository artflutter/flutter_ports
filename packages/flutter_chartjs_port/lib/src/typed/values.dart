// Original code, not ported from Chart.js: the value types of the typed API.

/// The value types of the typed API (Chart.js ADR 0052, section 7): the name
/// sets and the lengths of the Chart.js options.
///
/// Each type is an extension type with `const` constants. Thus a dot
/// shorthand works (`position: .top`, `align: .center`), and a new
/// constant is an addition that breaks no `switch` of an app.
///
/// - [ChartPosition] is over `String`. The option value is its `name`.
/// - [ChartPointStyle], [ChartFill] and [ChartLength] are over `Object`:
///   they also hold `false`, numbers and records. The internal getter
///   `optionValue` gives the option value. A record holds
///   [ChartFill.value] and [ChartLength.percent], so these constructors are
///   `const`, and two equal values are `==`.
///
/// The types have private constructors: Chart.js has no registry for
/// their names.
///
/// The `easing` option of an animation has no type here: it is a Flutter
/// `Curve`. The `mode` option of the interaction has none either: it is an
/// `InteractionMode` of the core. The `align` option of a box is the enum
/// `ChartAlign` of the core.
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
