// Original code, not ported from Chart.js: native data labels in the tests.

/// The data label forms of the tests (differences.md row
/// `adapt-native-tooltip-item`).
library;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/index.dart'
    show TooltipBodyItem, TooltipItem;
import 'package:flutter_chartjs_port/src/types/tooltip_item.dart'
    show dataLabelLinesOf;

/// The native label of the label [upstream] of generated reference data,
/// the `label` of `getLabelAndValue` and of a tooltip item: a string is one
/// line, a List is its lines, a number is the line of its string form, and
/// a falsy value (`''`, JS `null`, `undefined`) is no line.
List<String> nativeDataLabel(Object? upstream) => dataLabelLinesOf(upstream);

/// The `labelAndValue` list of a reference dataset, the objects
/// `{label, value}` of `getLabelAndValue`, with the native label of each
/// upstream label.
Object? nativeLabelAndValue(Object? items) => [
  for (final item in (items! as List<Object?>).cast<Map<String, Object?>>())
    <String, Object?>{...item, 'label': nativeDataLabel(item['label'])},
];

/// The `dataPoints` list of a reference tooltip with the native form of each
/// item: the native label, and Dart `null` for an `undefined` `parsed` or
/// `raw`.
Object? nativeDataPoints(Object? points) => switch (points) {
  final List<Object?> list => [
    for (final point in list.cast<Map<String, Object?>>())
      <String, Object?>{
        for (final MapEntry(:key, :value) in point.entries)
          key: switch (key) {
            'label' => nativeDataLabel(value),
            'parsed' || 'raw' => value is Undefined ? null : value,
            _ => value,
          },
      },
  ],
  _ => points,
};

/// The native tooltip item [item] as the plain object of the reference
/// data: the keys of `observeTooltip` of the generators.
Map<String, Object?> plainTooltipItem(
  TooltipItem item,
  Object? Function(Object? value) plain,
) => <String, Object?>{
  'datasetIndex': item.datasetIndex,
  'dataIndex': item.dataIndex,
  'label': item.label,
  'formattedValue': item.formattedValue,
  'parsed': plain(item.parsed),
  'raw': plain(item.raw),
};

/// The native body item [item] as the object `{before, lines, after}` of
/// the reference data.
Map<String, Object?> plainBodyItem(TooltipBodyItem item) => <String, Object?>{
  'before': item.before,
  'lines': item.lines,
  'after': item.after,
};
