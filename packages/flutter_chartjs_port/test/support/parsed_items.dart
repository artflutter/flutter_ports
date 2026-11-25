// Original code, not ported from Chart.js: the parsed items of plain test data.

/// The data items of `parsing: false` in the tests (differences.md row
/// `adapt-parsed-data-items`): each one is a [ParsedItem], where a spec or a
/// generator of upstream gives a plain object.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The [ParsedItem] of the plain data object [item] of upstream: the own
/// keys of a Map in their order, with their values. A [ParsedItem] and Dart
/// `null` stay as they are. Another value is a data item that the port does
/// not take with `parsing: false`: a [StateError].
ParsedItem? parsedItemOf(Object? item) {
  if (item == null || item is ParsedItem) return item as ParsedItem?;
  if (item is Map) {
    final parsed = ParsedItem();
    for (final MapEntry(:key, :value) in item.entries) {
      if (key is String) parsed.jsWrite(key, value);
    }
    return parsed;
  }
  throw StateError('No parsed item of $item');
}

/// The parsed value of the raw value [value] of a reference case: a number,
/// or Dart `null` for `null` and `undefined`. A parsed value is a number or
/// null (Chart.js ADR 0205): another value is a [StateError].
double? parsedNumber(Object? value) => switch (value) {
  final num number => number.toDouble(),
  null || Undefined() => null,
  _ => throw StateError('No parsed value of $value'),
};

/// The parsed items of the plain data objects [items] ([parsedItemOf]).
List<ParsedItem?> parsedItemsOf(List<Object?> items) => [
  for (final item in items) parsedItemOf(item),
];

/// The config [config] with the data items of each dataset of `parsing:
/// false` as parsed items ([parsedItemOf]): a dataset with its own
/// `parsing: false`, or each dataset of a chart with `options.parsing: false`
/// and no `parsing` of its own. A plain List of `Object?` items changes in
/// place, so that a test that holds it sees the chart data. A List of a
/// narrower item type, for example of Maps, becomes a new List. Another
/// config, for example a typed root scope, stays as it is.
T withParsedDataItems<T>(T config) {
  if (config is! Map && config is! JsObjectFace) return config;
  final options = jsGet(config, 'options');
  final chartParsing = options == null || options is Undefined
      ? undefined
      : jsGet(options, 'parsing');
  final data = jsGet(config, 'data');
  final datasets = data == null || data is Undefined
      ? null
      : jsGet(data, 'datasets');
  if (datasets is! List) return config;
  for (final dataset in datasets) {
    if (dataset is! Map && dataset is! JsObjectFace) continue;
    final own = jsGet(dataset, 'parsing');
    final parsing = own is Undefined ? chartParsing : own;
    final items = jsGet(dataset, 'data');
    if (parsing != false || items is! List || items is List<ParsedItem?>) {
      continue;
    }
    // A value that is not a Map stays: the chart stops a debug build on it.
    final parsed = <Object?>[
      for (final item in items)
        if (item is Map) parsedItemOf(item) else item,
    ];
    if (_widePlainLists.contains(items.runtimeType)) {
      for (var i = 0; i < parsed.length; i++) {
        items[i] = parsed[i];
      }
    } else {
      jsSet(dataset, 'data', parsed);
    }
  }
  return config;
}

/// The classes of the growable Lists that can hold a [ParsedItem].
final Set<Type> _widePlainLists = {
  <Object?>[].runtimeType,
  <Object>[].runtimeType,
  <dynamic>[].runtimeType,
};
