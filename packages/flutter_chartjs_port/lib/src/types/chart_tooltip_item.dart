// Original code, not ported from Chart.js: the shared tooltip item view.

/// The native callback view of the existing tooltip item (Chart.js ADR 0125).
library;

import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show Undefined;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

Object? _defined(Object? value) => value is Undefined ? null : value;
String? _string(Object? value) => value is String ? value : null;
int? _int(Object? value) =>
    value is num && value.isFinite ? value.toInt() : null;
Object? _byName(Object? object, String key) => switch (object) {
  final Map<Object?, Object?> map => map[key],
  final JsObjectFace face => face.jsRead(key),
  _ => null,
};

/// A tooltip item: the argument of the tooltip text callbacks
/// (`TooltipItem`, `index.d.ts:2978-3023`; `plugin.tooltip.js:127-146`).
///
/// A view of the item object of the tooltip: the typed tooltip item of the
/// plugin ([types.TypedTooltipItem], Chart.js ADR 0054 §12), or an object
/// of user code, read by name.
extension type ChartTooltipItem(Object _item) {
  /// The chart.
  types.Chart get chart => _key(_TooltipKey.chart)! as types.Chart;

  /// The data element of the item.
  types.Element get element => _key(_TooltipKey.element)! as types.Element;

  /// The original dataset object.
  Object? get dataset => _defined(_key(_TooltipKey.dataset));

  /// The label of the data item: the label of `data.labels`, as the app
  /// gave it (a `String`, a `num`, a `DateTime` or a `List` of lines), or
  /// the formatted label of a time axis.
  Object? get label => _defined(_key(_TooltipKey.label));

  /// The parsed values of the data item.
  Object? get parsed => _defined(_key(_TooltipKey.parsed));

  /// The original raw data item.
  Object? get raw => _defined(_key(_TooltipKey.raw));

  /// The value of the data item as the tooltip shows it.
  String get formattedValue => _string(_key(_TooltipKey.formattedValue)) ?? '';

  /// The index of the dataset in `data.datasets`.
  int get datasetIndex => _int(_key(_TooltipKey.datasetIndex))!;

  /// The index of the data item in the dataset.
  int get dataIndex => _int(_key(_TooltipKey.dataIndex))!;

  /// The `label` of the dataset, or `null` for a dataset without a String
  /// label. The dataset is the dataset object of the app: a Map, or the
  /// typed dataset scope of a typed config (Chart.js ADR 0054 §7), read by
  /// name.
  String? get datasetLabel {
    final dataset = _key(_TooltipKey.dataset);
    return dataset == null ? null : _string(_byName(dataset, 'label'));
  }

  /// The value of [key]: the typed field of a [types.TypedTooltipItem],
  /// else the read by name.
  Object? _key(_TooltipKey key) => switch (_item) {
    final types.TypedTooltipItem item => switch (key) {
      _TooltipKey.chart => item.chart,
      _TooltipKey.element => item.element,
      _TooltipKey.label => item.label,
      _TooltipKey.parsed => item.parsed,
      _TooltipKey.raw => item.raw,
      _TooltipKey.formattedValue => item.formattedValue,
      _TooltipKey.dataset => item.dataset,
      _TooltipKey.datasetIndex => item.datasetIndex,
      _TooltipKey.dataIndex => item.dataIndex,
    },
    final item => _byName(item, key.name),
  };
}

/// The keys of a tooltip item that [ChartTooltipItem] reads.
enum _TooltipKey() {
  chart,
  element,
  label,
  parsed,
  raw,
  formattedValue,
  dataset,
  datasetIndex,
  dataIndex,
}
