// Original code, not ported from Chart.js: the label of a raw value.

/// The label of a raw JS value on a scale, for the reference tests that
/// probe the label method of upstream with any value (Chart.js ADR 0205).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The label of [value] on [scale], the `'' + scale.getLabelForValue(value)`
/// of upstream for any JS value.
///
/// A number gives `getLabelForValue`. The category scale reads the label at
/// the key `ToString(value)` when `ToNumber(value)` is an index, else it
/// gives the value itself; another scale applies `ToNumber`. A time scale
/// gives `null` to its adapter, which formats an invalid date: NaN here. A
/// parsed value of the library is a number or null: `scaleLabelOf` takes
/// only these.
String rawScaleLabelOf(IScale scale, Object? value) {
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
