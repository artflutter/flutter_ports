// Original code, not ported from Chart.js: the scale number of a value.

/// The number that a value method of a scale gets for a value of the user
/// (row `adapt-native-scale-values`).
///
/// The value methods of a scale take a `double`. A parsed item, a data item
/// of `parsing: false` and a stack value can hold another value: this
/// library converts it at the call.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// A scale whose `getPixelForValue` takes a label upstream and parses it:
/// the category scale (scale.category.js:133-139). [scaleValueOf] gives a
/// value of the user to its `parse`.
abstract interface class LabelIndexScale() implements IScale;

/// A scale with its own numbers for a JS `null` value and for a value whose
/// `ToNumber` is NaN: the time scales, where the `-` operator of upstream
/// applies `ToNumber` to `null`, and the logarithmic scale, where NaN is the
/// parse of a 0.
abstract interface class NullValueScale() implements IScale {
  /// The number of a JS `null` value.
  double get nullValue;

  /// The number of a value of the user whose `ToNumber` is NaN.
  double get nanValue;
}

/// The number of [value] for the value methods of [scale].
///
/// A number gives itself. Dart `null` gives the `nullValue` of a
/// [NullValueScale], else NaN, the pixel of upstream. The [undefined]
/// sentinel gives NaN. Another value gives the result of `scale.parse` for a
/// [LabelIndexScale], as the category scale does upstream, and its
/// `ToNumber` ([jsToNumber]) for another scale, as the arithmetic of
/// upstream does: the `nanValue` of a [NullValueScale] for NaN.
double scaleValueOf(IScale scale, Object? value) => switch (value) {
  final double number => number,
  final num number => number.toDouble(),
  null => scale is NullValueScale ? scale.nullValue : double.nan,
  _ when identical(value, undefined) => double.nan,
  _ when scale is LabelIndexScale => scale.parse(value) ?? double.nan,
  _ => _numberOf(scale, jsToNumber(value)),
};

/// The number of the parsed value [value] for the value methods of [scale]
/// (Chart.js ADR 0205): [value] itself, or for Dart `null` the `nullValue` of
/// a [NullValueScale], else NaN, as [scaleValueOf] gives.
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
double scaleNumberOf(IScale scale, double? value) =>
    value ?? (scale is NullValueScale ? scale.nullValue : double.nan);

double _numberOf(IScale scale, double number) =>
    number.isNaN && scale is NullValueScale ? scale.nanValue : number;

/// The label of the parsed value [value] on [scale], the `'' +
/// scale.getLabelForValue(value)` of upstream (Chart.js ADR 0205).
///
/// A number gives `getLabelForValue`. For Dart `null` (the JS `null`),
/// upstream gives `null` to the label method: a time scale formats an
/// invalid date (the port gives NaN), the category scale reads
/// `labels['null']` when `ToNumber(null)`, 0, is an index, else it gives the
/// text `'null'`, and another scale applies `ToNumber`, which gives 0.
String scaleLabelOf(IScale scale, double? value) {
  if (value != null) return scale.getLabelForValue(value);
  if (scale is NullValueScale) return scale.getLabelForValue(double.nan);
  if (scale is LabelIndexScale) {
    return scale.getLabels().isNotEmpty ? 'undefined' : 'null';
  }
  return scale.getLabelForValue(0);
}
