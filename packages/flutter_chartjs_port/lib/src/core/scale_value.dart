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

double _numberOf(IScale scale, double number) =>
    number.isNaN && scale is NullValueScale ? scale.nanValue : number;

/// The label of [value] on [scale], the `'' + scale.getLabelForValue(value)`
/// of upstream for a value of the user.
///
/// A number gives `getLabelForValue`. Upstream gives another value to the
/// label method as it is: the category scale reads the label at the key
/// `ToString(value)` when `ToNumber(value)` is an index, else it gives the
/// value itself; another scale applies `ToNumber` to it. A time scale gives
/// `null` to its adapter, which formats an invalid date: the port gives NaN.
String scaleLabelOf(IScale scale, Object? value) {
  if (value is num) {
    return scale.getLabelForValue(value.toDouble());
  }
  if (value == null && scale is NullValueScale) {
    return scale.getLabelForValue(double.nan);
  }
  if (scale is LabelIndexScale) {
    final labels = scale.getLabels();
    final number = jsToNumber(value);
    if (number >= 0 && number < labels.length) {
      // `labels[value]`: the key `ToString(value)` reads an item only when it
      // is the text of an index, for example `'1'`.
      final key = jsToString(value);
      final index = int.tryParse(key);
      return jsToString(
        index != null && '$index' == key ? labels[index] : undefined,
      );
    }
    return jsToString(value);
  }
  return scale.getLabelForValue(jsToNumber(value));
}
