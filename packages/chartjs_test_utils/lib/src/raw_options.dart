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

final Expando<Map<String, Object?>> _rawOptions = Expando('raw options');

/// Attaches the raw options [options] to [object], a part of a typed config:
/// a `ChartConfig`, a dataset, an axis, an axis part, `ChartElements` and
/// its element styles, `ChartAnimation` or `ChartInteraction`. Gives
/// [object].
///
/// [lowerForTest] merges [options] into the lowered scope of [object]. A
/// `const` object is shared: two calls for one object must give equal Maps.
T raw<T extends Object>(T object, Map<String, Object?> options) {
  final previous = _rawOptions[object];
  assert(
    previous == null ||
        identical(previous, options) ||
        _sameKeys(previous, options),
    'raw: $object already has the raw options $previous.',
  );
  _rawOptions[object] = options;
  return object;
}

bool _sameKeys(Map<String, Object?> a, Map<String, Object?> b) =>
    a.length == b.length && a.keys.every(b.containsKey);

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
  final options = jsGet(root, 'options')! as OptionScope;
  final datasets = jsGet(jsGet(root, 'data'), 'datasets');
  for (final (i, dataset) in config.datasets.indexed) {
    if (_rawOptions[dataset] case final map?) {
      scopeFromMap((datasets! as List<Object?>)[i]! as OptionScope, map);
    }
  }
  if (config.datasetDefaults case final defaults?) {
    final byType = jsGet(options, 'datasets');
    for (final dataset in defaults) {
      if (_rawOptions[dataset] case final map?) {
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
        if (part != null && _rawOptions[part] != null) {
          scopeFromMap(jsGet(scope, key)! as OptionScope, _rawOptions[part]);
        }
      }
      if (_rawOptions[axis] case final map?) scopeFromMap(scope, map);
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
      if (style != null && _rawOptions[style] != null) {
        scopeFromMap(jsGet(scope, key)! as OptionScope, _rawOptions[style]);
      }
    }
    if (_rawOptions[elements] case final map?) scopeFromMap(scope, map);
  }
  for (final (group, key) in <(Object?, String)>[
    (config.animation, 'animation'),
    (config.interaction, 'interaction'),
  ]) {
    if (group != null && _rawOptions[group] != null) {
      scopeFromMap(jsGet(options, key)! as OptionScope, _rawOptions[group]);
    }
  }
  if (_rawOptions[config] case final map?) scopeFromMap(options, map);
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
