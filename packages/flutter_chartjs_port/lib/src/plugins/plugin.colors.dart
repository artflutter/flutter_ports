// Ported from Chart.js v4.6.1 src/plugins/plugin.colors.ts (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.colors.ts`.
///
/// [colors] is the plugin object, the default export of the upstream file
/// and `Colors` of `src/plugins/index.js:1` (Chart.js ADR 0038, section 1).
/// It is a typed `Plugin` (Chart.js ADR 0054 §12) with the upstream keys in
/// the upstream order: `id`, `defaults` and the hook `beforeLayout`.
///
/// The TypeScript interface `ColorsPluginOptions` (`plugin.colors.ts:4-7`)
/// is the facade `ColorsPluginOptions` of `plugin_options.dart` over the
/// resolver of `core.plugins.js:175-188`. `ColorsDescriptor` (`:9-12`) is a
/// type only: the descriptors are the datasets and the element options of
/// the user, read by name.
///
/// The colorizers write the colors into the dataset of the user: a typed
/// field for a typed dataset scope, a write by name for a Map of the user
/// (Chart.js ADR 0054 §5).
///
/// Four marked hunks add the theme palette (Chart.js ADR 0050, theming.md
/// §3.5): H4a (the palette keys, two library variables and their reader),
/// H4b and H4c (a theme branch before the unchanged `return` line of each
/// getter) and H5 (the palette of the chart theme before each colorizer
/// run). Without a theme, H5 sets both variables to Dart `null`, and the
/// results are the upstream results. H5 reads the theme map through
/// `chartThemeOf` of `core.config.dart` (hunk H0). This file never imports
/// `lib/src/theme/` (invariant 4).
///
/// `plugin.colors.ts:1` imports `DoughnutController`, `PolarAreaController`
/// and `defaults` from `../index.js`. This file imports the three Dart files
/// that define them. Thus it is not a pure layer: the controllers import
/// `core.datasetController.dart`.
library;

import 'package:flutter_chartjs_port/src/controllers/controller.doughnut.dart'
    show DoughnutController;
import 'package:flutter_chartjs_port/src/controllers/controller.polarArea.dart'
    show PolarAreaController;
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show chartThemeOf;
import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsIsObjectLike, jsSet;
import 'package:flutter_chartjs_port/src/options/option_scope.dart'
    show OptionKey, OptionScope;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show ColorsOptionsScope;
import 'package:flutter_chartjs_port/src/plugins/plugin_options.dart'
    show ColorsPluginOptions, optionOf;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart' show Plugin;
import 'package:meta/meta.dart';

/// plugin.colors.ts:14 `BORDER_COLORS`.
const List<String> _borderColors = [
  'rgb(54, 162, 235)', // blue
  'rgb(255, 99, 132)', // red
  'rgb(255, 159, 64)', // orange
  'rgb(255, 205, 86)', // yellow
  'rgb(75, 192, 192)', // green
  'rgb(153, 102, 255)', // purple
  'rgb(201, 203, 207)', // grey
];

/// plugin.colors.ts:25 `BACKGROUND_COLORS`.
///
/// Border colors with 50% transparency. `String.prototype.replace` with a
/// string pattern replaces the first match only: [String.replaceFirst].
final List<String> _backgroundColors = _borderColors
    .map(
      (color) =>
          color.replaceFirst('rgb(', 'rgba(').replaceFirst(')', ', 0.5)'),
    )
    .toList();

// DIVERGES(chartjs): theme-H4a, the theme palette keys, variables and reader.
/// The key of the border palette under `plugins.colors` of a theme map
/// (Chart.js ADR 0050, theming.md §3.5).
@internal
const String themeBorderColorsKey = r'$borderColors';

/// The key of the background palette under `plugins.colors` of a theme map.
@internal
const String themeBackgroundColorsKey = r'$backgroundColors';

/// The border palette of the theme of the chart of the current colorizer
/// run, or Dart `null` for the upstream palette. Hunk H5 sets it.
List<Object?>? _themeBorderColors;

/// The background palette of the theme of the chart of the current
/// colorizer run, or Dart `null` for the upstream palette.
List<Object?>? _themeBackgroundColors;

/// The palette [key] under `plugins.colors` of the theme map [theme]: a
/// List with at least one item, else Dart `null`. An empty List would give
/// `i % 0` (a throw in Dart), and a String would give one character for
/// each dataset in JavaScript.
List<Object?>? _themePalette(Object? theme, String key) {
  if (theme == null) return null;
  final plugins = jsGet(theme, 'plugins');
  final colors = jsIsObjectLike(plugins) ? jsGet(plugins, 'colors') : null;
  final value = jsIsObjectLike(colors) ? jsGet(colors, key) : null;
  return value is List<Object?> && value.isNotEmpty ? value : null;
}

/// plugin.colors.ts:27 `getBorderColor(i)`. The TypeScript source declares
/// no return type. A theme palette holds any static JS value.
Object? _getBorderColor(int i) {
  // DIVERGES(chartjs): theme-H4b, the theme palette comes first.
  final themeColors = _themeBorderColors;
  // js-ok: i is an int and never negative, so Dart % equals JS %.
  if (themeColors != null) return themeColors[i % themeColors.length];
  // js-ok: i is an int and never negative, so Dart % equals JS %.
  return _borderColors[i % _borderColors.length];
}

/// plugin.colors.ts:31 `getBackgroundColor(i)`.
Object? _getBackgroundColor(int i) {
  // DIVERGES(chartjs): theme-H4c, the theme palette comes first.
  final themeColors = _themeBackgroundColors;
  // js-ok: i is an int and never negative, so Dart % equals JS %.
  if (themeColors != null) return themeColors[i % themeColors.length];
  // js-ok: i is an int and never negative, so Dart % equals JS %.
  return _backgroundColors[i % _backgroundColors.length];
}

/// The write `dataset[key] = value` of a colorizer into the dataset
/// [dataset] of `chart.config.data.datasets`: the typed field of a typed
/// dataset scope (Chart.js ADR 0054 §5), else the write by name into the
/// Map of the user ([jsSet]). A dataset of `null` or `undefined` throws a
/// [TypeError], as the property write does upstream.
///
/// A Map with a narrow value type, for example `Map<String, List<int>>` for
/// `{'data': [1, 2, 3]}`, throws a [TypeError] at the write of a color
/// String. An unmodifiable Map throws an [UnsupportedError]. JavaScript sets
/// the properties in both cases (differences.md row
/// `js-semantics-narrow-datasets`). The three colorizers have this
/// difference.
void _writeColor(Object? dataset, OptionKey key, Object? value) {
  switch (dataset) {
    case final OptionScope scope when scope.hasField(key):
      scope.store(key, scope.classify(key, value));
    default:
      // DIVERGES(chartjs): js-semantics-narrow-datasets, a narrow or fixed Map.
      jsSet(dataset, key.jsName, value);
  }
}

/// plugin.colors.ts:35 `colorizeDefaultDataset(dataset, i)`.
///
/// The writes go through [_writeColor].
int _colorizeDefaultDataset(Object? dataset, int i) {
  _writeColor(dataset, OptionKey.borderColor, _getBorderColor(i));
  _writeColor(dataset, OptionKey.backgroundColor, _getBackgroundColor(i));

  // The upstream form writes the parameter.
  // ignore: parameter_assignments
  return ++i;
}

/// The `dataset.data` of a doughnut or polar area colorizer, for the call
/// `dataset.data.map(...)`: a [List], else a [TypeError], as the call of
/// the `undefined` member `map` of a string or an object throws upstream.
///
/// The read of the dataset of the user is a read by name: a Map of the
/// user, or the face of a typed dataset scope.
List<Object?> _mapTarget(Object? dataset) {
  final data = jsGet(dataset, 'data');
  if (data is! List<Object?>) {
    // A JavaScript TypeError: `dataset.data.map` is not a function.
    throw TypeError();
  }
  return data;
}

/// plugin.colors.ts:42 `colorizeDoughnutDataset(dataset, i)`.
///
/// `Array.prototype.map` calls the callback one time for each item, in
/// order, over the length at the start of the call. [List.generate] does
/// the same. The write goes through [_writeColor].
int _colorizeDoughnutDataset(Object? dataset, int i) {
  final data = _mapTarget(dataset);
  _writeColor(
    dataset,
    OptionKey.backgroundColor,
    List<Object?>.generate(
      data.length,
      // The upstream form writes the parameter.
      // ignore: parameter_assignments
      (_) => _getBorderColor(i++),
    ),
  );

  return i;
}

/// plugin.colors.ts:48 `colorizePolarAreaDataset(dataset, i)`.
///
/// The write goes through [_writeColor].
int _colorizePolarAreaDataset(Object? dataset, int i) {
  final data = _mapTarget(dataset);
  _writeColor(
    dataset,
    OptionKey.backgroundColor,
    List<Object?>.generate(
      data.length,
      // The upstream form writes the parameter.
      // ignore: parameter_assignments
      (_) => _getBackgroundColor(i++),
    ),
  );

  return i;
}

/// plugin.colors.ts:54 `getColorizer(chart)`: the callback of
/// `datasets.forEach` with one counter `i` for each call.
///
/// `instanceof DoughnutController` is the Dart type test. `PieController`
/// extends [DoughnutController], as upstream.
void Function(Object? dataset, int datasetIndex) _getColorizer(
  types.Chart chart,
) {
  var i = 0;

  return (dataset, datasetIndex) {
    final controller = chart.getDatasetMeta(datasetIndex.toDouble()).controller;

    if (controller is DoughnutController) {
      i = _colorizeDoughnutDataset(dataset, i);
    } else if (controller is PolarAreaController) {
      i = _colorizePolarAreaDataset(dataset, i);
    } else if (controller != null) {
      i = _colorizeDefaultDataset(dataset, i);
    }
  };
}

/// The values `descriptors[k]` of the loop `for (k in descriptors)` of
/// plugin.colors.ts:75, in the order of the loop.
///
/// The descriptors are option objects of the user (the datasets, the
/// `elements` of the options): a Map is read by name.
///
/// A List or a String gives its items at the indices. A Map gives the
/// values of its keys in the order of `Object.keys`: a plain Map has no
/// inherited enumerable key. `null`, `undefined` and the other values give
/// no item, as `for...in` does.
Iterable<Object?> _forInValues(Object? descriptors) sync* {
  switch (descriptors) {
    case final List<Object?> list:
      for (var k = 0; k < list.length; k++) {
        yield list[k];
      }
    case final String string:
      for (var k = 0; k < string.length; k++) {
        yield string[k];
      }
    case final Object object when jsIsObjectLike(object):
      for (final k in jsObjectKeys(object)) {
        yield jsGet(object, k);
      }
  }
}

/// plugin.colors.ts:70 `containsColorsDefinitions(descriptors)`.
///
/// A descriptor of `null` or `undefined` throws a [TypeError], as the
/// property read does upstream.
bool _containsColorsDefinitions(Object? descriptors) {
  for (final descriptor in _forInValues(descriptors)) {
    if (jsTruthy(optionOf(descriptor, OptionKey.borderColor)) ||
        jsTruthy(optionOf(descriptor, OptionKey.backgroundColor))) {
      return true;
    }
  }

  return false;
}

/// plugin.colors.ts:84 `containsColorsDefinition(descriptor)`.
///
/// Upstream returns the value of the `&&` and `||` chain. Its only caller
/// tests its truthiness. Thus this function gives that truthiness.
bool _containsColorsDefinition(Object? descriptor) {
  return jsTruthy(descriptor) &&
      (jsTruthy(optionOf(descriptor, OptionKey.borderColor)) ||
          jsTruthy(optionOf(descriptor, OptionKey.backgroundColor)));
}

/// plugin.colors.ts:90 `containsDefaultColorsDefenitions()`. The strict
/// inequality of a value and a string is the Dart `!=`. The reads are the
/// typed reads of the keys of `defaults` (with their routes).
bool _containsDefaultColorsDefenitions() {
  return defaults.lookup(OptionKey.borderColor)?.raw != 'rgba(0,0,0,0.1)' ||
      defaults.lookup(OptionKey.backgroundColor)?.raw != 'rgba(0,0,0,0.1)';
}

/// plugin.colors.ts:102 `beforeLayout(chart, _args, options)`.
///
/// `chart.config.data.datasets` is a read of the data of the user, by name.
/// The options of the config are read through their typed keys
/// ([optionOf]), by name for a Map of the user.
void _beforeLayout(types.Chart chart, Object _, Object options) {
  final opts = ColorsPluginOptions(options);
  if (!jsTruthy(opts.enabled)) {
    return;
  }

  final config = chart.config;
  final datasets = jsGet(config.data, 'datasets');
  final chartOptions = config.options;
  final elements = optionOf(chartOptions, OptionKey.elements);

  final containsColorDefenition =
      _containsColorsDefinitions(datasets) ||
      _containsColorsDefinition(chartOptions) ||
      (jsTruthy(elements) && _containsColorsDefinitions(elements)) ||
      _containsDefaultColorsDefenitions();

  if (!jsTruthy(opts.forceOverride) && containsColorDefenition) {
    return;
  }

  // DIVERGES(chartjs): theme-H5, the palette of the chart theme for this run.
  final theme = chartThemeOf(config);
  _themeBorderColors = _themePalette(theme, themeBorderColorsKey);
  _themeBackgroundColors = _themePalette(theme, themeBackgroundColorsKey);

  final colorizer = _getColorizer(chart);

  // `datasets.forEach(colorizer)`: a value that is not an array throws a
  // TypeError. forEach visits the indices below the length at its start.
  final list = datasets! as List<Object?>;
  for (var k = 0, length = list.length; k < length; k++) {
    colorizer(list[k], k);
  }
}

/// plugin.colors.ts:94 the default export, `Colors` of
/// src/plugins/index.js:1.
///
/// A typed [Plugin] with the upstream keys in the upstream order.
final Plugin colors = Plugin()
  ..id = 'colors'
  // A typed scope of the kind `ColorsOptions` (Chart.js ADR 0054 §3).
  ..defaults = (ColorsOptionsScope()
    ..enabled = true
    ..forceOverride = false)
  ..beforeLayout = _beforeLayout;
