// Original code, not ported from Chart.js: the value types of the typed API.

/// The value types of the typed API (Chart.js ADR 0052, section 7): the name
/// sets and the lengths of the Chart.js options.
///
/// Each type is an extension type with `const` constants. Thus a dot
/// shorthand works (`fill: .origin`), and a new constant is an addition
/// that breaks no `switch` of an app. The position of a box is the enum
/// `ChartPosition` of the core (row `adapt-chart-position-enum`).
///
/// - [ChartFill] and [ChartLength] are over `Object`: they also hold
///   `false`, numbers and records. The internal getter
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
/// `ChartAlign` of the core. The `pointStyle` option is a `PointStyle` of
/// the core.
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsNumberToString;
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart'
    show FillBoundary, RelativeFill;
import 'package:meta/meta.dart' show internal;

/// The fill of a line or a radar dataset: the `fill` option
/// (`FillTarget`, `index.d.ts:2300`; `filler.options.js:120-137`).
///
/// The complex form `{target, above, below}` goes through the `extra` Map
/// of the dataset.
extension type const ChartFill._(Object _value) {
  /// The fill to the dataset at the absolute [index] of `data.datasets`:
  /// the number.
  const ChartFill.dataset(int index) : _value = index;

  /// The fill to the dataset at [offset] from this dataset: a
  /// [RelativeFill], the `'+1'` and `'-1'` of Chart.js (row
  /// `adapt-fill-target-objects`). Not `const`: the target object takes
  /// the offset at run time.
  ChartFill.relative(int offset) : _value = RelativeFill(offset);

  /// The fill to the line at [value] of the value axis: `{value: n}`.
  const ChartFill.value(num value) : _value = (value: value);

  /// [FillBoundary.origin]: the fill to the origin of the value axis.
  /// Chart.js gives it also for `fill: true`.
  static const ChartFill origin = ChartFill._(FillBoundary.origin);

  /// [FillBoundary.start]: the fill to the start of the value axis.
  static const ChartFill start = ChartFill._(FillBoundary.start);

  /// [FillBoundary.end]: the fill to the end of the value axis.
  static const ChartFill end = ChartFill._(FillBoundary.end);

  /// [FillBoundary.stack]: the fill to the dataset below in the stack.
  static const ChartFill stack = ChartFill._(FillBoundary.stack);

  /// [FillBoundary.shape]: the fill of the closed shape, for a radar dataset.
  static const ChartFill shape = ChartFill._(FillBoundary.shape);

  /// `false`: no fill.
  static const ChartFill none = ChartFill._(false);

  /// The option value: a [FillBoundary], `false`, a number, a
  /// [RelativeFill] for [ChartFill.relative], or a new Map `{value: n}` for
  /// [ChartFill.value].
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
