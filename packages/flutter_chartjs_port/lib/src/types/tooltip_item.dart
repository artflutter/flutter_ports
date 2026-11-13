// Original code, not ported from Chart.js: the native tooltip item.

/// The native tooltip item contract.
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;
import 'package:flutter_chartjs_port/src/types/index.dart' show Chart, Element;
import 'package:flutter_chartjs_port/src/types/tick.dart' show labelLinesOf;
import 'package:meta/meta.dart';

/// The lines of the label of a data item, the `label` of
/// `getLabelAndValue` (core.datasetController.js:692-695).
///
/// The base controller and the bar controller give a string. Bubble,
/// doughnut, pie, polar area and scatter give `labels[index] || ''`, and
/// radar gives `vScale.getLabels()[index]`: a label of the app. A string is
/// one line, a List is the List of its lines, and another value is the line
/// of its string form ([labelLinesOf]). A falsy value (`''`, `0`, JS `null`,
/// `undefined`) is no label: the empty List.
@internal
List<String> dataLabelLinesOf(Object? label) =>
    jsTruthy(label) ? labelLinesOf(label)! : const <String>[];

/// An item of the tooltip: the object of `createTooltipItem`
/// (plugin.tooltip.js:127-146), `TooltipItem` of index.d.ts:2978.
///
/// The tooltip makes one item for each of its active elements. `filter`,
/// `itemSort`, the callbacks of `TooltipCallbacks` and
/// `TooltipModel.dataPoints` get the same object.
///
/// Apps and plugins may extend this class.
@immutable
class const TooltipItem({
  /// The chart of the tooltip (index.d.ts:2982).
  required final Chart chart,

  /// The index of the dataset in `data.datasets` (index.d.ts:3012).
  required final int datasetIndex,

  /// The index of the data item in the dataset (index.d.ts:3017).
  required final int dataIndex,

  /// The lines of the label of the data item (index.d.ts:2987). Empty for
  /// no label.
  required final List<String> label,

  /// The value of the data item as the tooltip shows it (index.d.ts:3002).
  required final String formattedValue,

  /// The dataset object of the app (index.d.ts:3007): a Map, or the dataset
  /// scope of a typed config.
  required final Object dataset,

  /// The parsed values of the data item (index.d.ts:2992): a parsed item,
  /// or the number of a doughnut or pie item.
  required final Object? parsed,

  /// The data item of the app, as it is (index.d.ts:2997).
  required final Object? raw,

  /// The data element (index.d.ts:3022). Null for an index with no element.
  final Element? element,
}) {
  /// Creates a tooltip item.
  this;

  /// The `label` of the dataset, or null for a dataset without a String
  /// label. The dataset is an object of the app, read by name.
  String? get datasetLabel {
    final label = switch (dataset) {
      final Map<Object?, Object?> map => map['label'],
      final JsObjectFace face => face.jsRead('label'),
      _ => null,
    };
    return label is String ? label : null;
  }

  /// The item as an object literal, for test messages.
  @override
  String toString() =>
      '{label: $label, formattedValue: $formattedValue, '
      'datasetIndex: $datasetIndex, dataIndex: $dataIndex}';
}

/// The lines of one tooltip item in the body of the tooltip: the object
/// `{before, lines, after}` of plugin.tooltip.js:559-563 (index.d.ts:2673).
@immutable
final class const TooltipBodyItem({
  /// The lines of the `beforeLabel` callback.
  required final List<String> before,

  /// The lines of the `label` callback.
  required final List<String> lines,

  /// The lines of the `afterLabel` callback.
  required final List<String> after,
}) {
  /// Creates a body item.
  this;

  /// The item as an object literal, for test messages.
  @override
  String toString() => '{before: $before, lines: $lines, after: $after}';
}
