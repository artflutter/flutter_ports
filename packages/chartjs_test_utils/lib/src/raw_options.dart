// Original code, not ported from Chart.js: the raw options of typed configs.

/// The raw options of a typed config in the tests: the option values that a
/// typed parameter cannot hold, because only JavaScript has their form (a
/// string number in `data`, a date text as `min`, a parsing key object, a key
/// that Chart.js does not declare).
///
/// [raw] attaches a Map to an object of a typed config, and [lowerForTest]
/// lowers the config and merges each Map into the lowered scope of its
/// object with [scopeFromMap], last, as the `extra` Map of Chart.js ADR 0052
/// merged. The library has no Map path: the typed API takes typed values
/// only.
library;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The raw options of each object, in the order of the calls of [raw] since
/// the last lowering.
final Expando<List<Map<String, Object?>>> _rawOptions = Expando('raw options');

/// The count of the lowerings at the last attach of each object.
final Expando<int> _attachedAt = Expando('raw options lowering');

/// The count of the lowerings of [applyRawOptions].
int _lowerings = 0;

/// Attaches the raw options [options] to [object], a part of a typed config:
/// a `ChartConfig`, a dataset, an axis, an axis part, `ChartElements` and
/// its element styles, `ChartAnimation` or `ChartInteraction`. Gives
/// [object]. A null [options] attaches nothing.
///
/// [lowerForTest] merges [options] into the lowered scope of [object]. A
/// `const` object is shared: when one config holds it twice, each call of
/// [raw] since the last lowering gives the Map of the next place of the
/// object in the config, in the order of the config.
T raw<T extends Object>(T object, Map<String, Object?>? options) {
  if (options == null) return object;
  final list = _rawOptions[object];
  if (list == null || _attachedAt[object] != _lowerings) {
    _rawOptions[object] = [options];
  } else {
    list.add(options);
  }
  _attachedAt[object] = _lowerings;
  return object;
}

/// The raw options of the last call of [raw] for [object], or Dart `null`.
Map<String, Object?>? rawOptionsOf(Object object) => _rawOptions[object]?.last;

/// The root scope of [config], with the raw options of [raw] merged into
/// the scopes of their objects.
ChartConfigurationScope lowerForTest(ChartConfig config) =>
    applyRawOptions(ChartConfigLowering(config).lower(), config);

/// Merges the raw options of the objects of [config] into [root], the
/// lowered root scope of [config]. Gives [root].
///
/// The order is the order of the lowering: each dataset, each axis with its
/// ticks, grid and title, the element styles, the animation and the
/// interaction, and the options of [config] last.
ChartConfigurationScope applyRawOptions(
  ChartConfigurationScope root,
  ChartConfig config,
) {
  // A merge can throw, as the merge of `extra` did: the next config takes new
  // raw options also then.
  try {
    return _applyRawOptions(root, config);
  } finally {
    _lowerings++;
  }
}

ChartConfigurationScope _applyRawOptions(
  ChartConfigurationScope root,
  ChartConfig config,
) {
  // The next Map of each object: the k-th place of an object in the config
  // takes its k-th Map (the last one for a later place).
  final taken = Map<Object, int>.identity();
  Map<String, Object?>? take(Object? object) {
    if (object == null) return null;
    final list = _rawOptions[object];
    // Only the Maps of the calls since the last lowering: a const object of
    // an earlier config keeps no raw options.
    if (list == null || _attachedAt[object] != _lowerings) return null;
    final k = taken[object] ?? 0;
    taken[object] = k + 1;
    return list[k < list.length ? k : list.length - 1];
  }

  final options = jsGet(root, 'options')! as OptionScope;
  final datasets = jsGet(jsGet(root, 'data'), 'datasets');
  for (final (i, dataset) in config.datasets.indexed) {
    if (take(dataset) case final map?) {
      scopeFromMap((datasets! as List<Object?>)[i]! as OptionScope, map);
    }
  }
  if (config.datasetDefaults case final defaults?) {
    final byType = jsGet(options, 'datasets');
    for (final dataset in defaults) {
      if (take(dataset) case final map?) {
        // The one item of its type: find its scope by the type id.
        for (final key in jsObjectKeys(byType)) {
          final scope = jsGet(byType, key);
          if (scope is OptionScope && _sameDefault(dataset, key)) {
            scopeFromMap(scope, map);
          }
        }
      }
    }
  }
  final scales = config.scales;
  if (scales != null && scales.isNotEmpty) {
    final byId = jsGet(options, 'scales');
    for (final MapEntry(key: axis, value: id) in scaleIdsOf(scales).entries) {
      final scope = jsGet(byId, id)! as OptionScope;
      for (final (part, key) in <(Object?, String)>[
        (axis.ticks, 'ticks'),
        (axis.grid, 'grid'),
        (axis.title, 'title'),
      ]) {
        if (take(part) case final map?) {
          scopeFromMap(jsGet(scope, key)! as OptionScope, map);
        }
      }
      if (take(axis) case final map?) scopeFromMap(scope, map);
    }
  }
  if (config.elements case final elements?) {
    final scope = jsGet(options, 'elements')! as OptionScope;
    for (final (style, key) in <(Object?, String)>[
      (elements.point, 'point'),
      (elements.line, 'line'),
      (elements.bar, 'bar'),
      (elements.arc, 'arc'),
    ]) {
      if (take(style) case final map?) {
        scopeFromMap(jsGet(scope, key)! as OptionScope, map);
      }
    }
    if (take(elements) case final map?) scopeFromMap(scope, map);
  }
  for (final (group, key) in <(Object?, String)>[
    (config.animation, 'animation'),
    (config.interaction, 'interaction'),
  ]) {
    if (take(group) case final map?) {
      scopeFromMap(jsGet(options, key)! as OptionScope, map);
    }
  }
  if (take(config) case final map?) scopeFromMap(options, map);
  return root;
}

/// Whether [dataset] is the item of `datasetDefaults` of the type [key].
bool _sameDefault(Dataset dataset, String key) => switch (dataset) {
  BarDataset() => key == 'bar',
  LineDataset() => key == 'line',
  ScatterDataset() => key == 'scatter',
  BubbleDataset() => key == 'bubble',
  PieDataset() => key == 'pie',
  DoughnutDataset() => key == 'doughnut',
  PolarAreaDataset() => key == 'polarArea',
  RadarDataset() => key == 'radar',
  _ => false,
};
