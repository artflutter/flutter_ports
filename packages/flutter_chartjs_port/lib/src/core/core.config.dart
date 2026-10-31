// Ported from Chart.js v4.6.1 src/core/core.config.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.config.js`: the chart configuration and the option
/// scopes of the resolver.
///
/// The JavaScript values map to Dart values as Chart.js ADR 0043 decides: the
/// raw configuration, its `data` and its `options` are
/// `Map<String, Object?>`, an array is a [List], `undefined` is the
/// [undefined] sentinel and `null` is Dart `null`. A property read of a value
/// that the user gives is [jsGet]. A JS `Map` or `Set` is a Dart [Map] or
/// [Set], which compares its keys with `==`. JavaScript compares with
/// SameValueZero. The two agree for every key that Chart.js uses: strings,
/// numbers other than NaN, and objects, which both compare by identity.
///
/// The configuration, its `data` and its `options` must be Maps (row
/// `adapt-config-objects` of differences.md). Upstream also writes the
/// properties of these objects into an array or a function. An array `data`
/// gives a new Map.
///
/// Four hunks add the compiled theme of Chart.js ADR 0050 as an option scope
/// (theming.md §3.1): H0 ([themeConfigKey], the private `_themeOf` and the
/// public [chartThemeOf] of Chart.js ADR 0050), H1 (`mergeScaleConfig`), H2
/// ([Config.getOptionScopes]) and H3
/// ([Config.chartOptionScopes]). The chart widget puts the theme into the raw
/// configuration under [themeConfigKey]. Without a theme, the hunks add no
/// scope and no key, and the results are the upstream results.
///
/// [Config.resolveNamedOptions] takes the result object of the caller
/// (Chart.js ADR 0021, section 1): the dataset controller gives the typed
/// options class of the element type. This file does not import the element
/// options, as upstream imports no element module.
library;

import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    as helpers;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isArray, isFunction, isObject, mergeIf, resolveObjectKey;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    as core
    show valueOrDefault;
import 'package:flutter_chartjs_port/src/js/js_array.dart'
    show JsProxyObject, jsObjectKeys, jsOwnPropertyNames;
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsToString, jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show JsObjectFace, jsGet, jsSet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/element_options_base.dart'
    show ElementOptions;
import 'package:flutter_chartjs_port/src/options/option_scope.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show ScaleOptionsByIdScope, ScaleOptionsScope;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// core.config.js:5 `getIndexAxis`.
///
/// [type] is the chart or dataset type and [options] the chart options: a
/// Map or a resolver. The result is the first truthy `indexAxis` of the
/// dataset type options, the options and the dataset type defaults, else
/// `'x'`. A value that is not a string stays as it is.
Object? getIndexAxis(Object? type, Object? options) {
  final datasetDefaults = _orObject(jsGet(defaults['datasets'], type));
  final datasetOptions = _orObject(
    jsGet(_orObject(jsGet(options, 'datasets')), type),
  );
  Object? indexAxis;
  return jsTruthy(indexAxis = jsGet(datasetOptions, 'indexAxis')) ||
          jsTruthy(indexAxis = jsGet(options, 'indexAxis')) ||
          jsTruthy(indexAxis = jsGet(datasetDefaults, 'indexAxis'))
      ? indexAxis
      : 'x';
}

/// core.config.js:11 `getAxisFromDefaultScaleID`.
///
/// [id] is a key of the `scales` of a dataset type override: `'_index_'`,
/// `'_value_'` or a scale id.
Object? _getAxisFromDefaultScaleID(String id, Object? indexAxis) {
  Object? axis = id;
  if (id == '_index_') {
    axis = indexAxis;
  } else if (id == '_value_') {
    axis = 'x' == indexAxis ? 'y' : 'x';
  }
  return axis;
}

/// core.config.js:21 `getDefaultScaleIDFromAxis`.
///
/// `===` is `==`: it compares strings and numbers by value and other values
/// by identity.
String _getDefaultScaleIDFromAxis(Object? axis, Object? indexAxis) {
  return axis == indexAxis ? '_index_' : '_value_';
}

/// core.config.js:25 `idMatchesAxis`.
///
/// Dart `null` stands for the `undefined` of upstream. The callers test only
/// its truth.
String? _idMatchesAxis(String id) {
  if (id == 'x' || id == 'y' || id == 'r') {
    return id;
  }
  return null;
}

/// core.config.js:31 `axisFromPosition`.
///
/// Dart `null` stands for the `undefined` of upstream. The callers test only
/// its truth.
String? _axisFromPosition(Object? position) {
  if ('top' == position || 'bottom' == position) {
    return 'x';
  }
  if ('left' == position || 'right' == position) {
    return 'y';
  }
  return null;
}

/// core.config.js:40 `determineAxis`.
///
/// The rest parameter `...scaleOptions` is one `List` (Chart.js ADR 0020,
/// section 6). Each item is read with [jsGet]. Thus an `undefined` item that
/// the loop reaches throws a [TypeError], as upstream does. The result is
/// the first truthy `axis` option, the axis of a `position`, or the axis of
/// the first character of [id]. An `axis` that is not a string stays as it
/// is.
///
/// Upstream throws an `Error`. The port throws a [StateError] with the same
/// message (Chart.js ADR 0020, section 5).
///
/// `toLowerCase` is the Dart [String.toLowerCase]. Only `'X'`, `'Y'` and
/// `'R'` give `'x'`, `'y'` and `'r'` with the case mappings of JavaScript and
/// of Dart. Thus the result is the same on every platform.
Object? determineAxis(String id, List<Object?> scaleOptions) {
  if (_idMatchesAxis(id) != null) {
    return id;
  }
  for (final opts in scaleOptions) {
    var axis = jsGet(opts, 'axis');
    if (!jsTruthy(axis)) {
      axis =
          _axisFromPosition(jsGet(opts, 'position')) ??
          (id.length > 1 ? _idMatchesAxis(id[0].toLowerCase()) : null);
    }
    if (jsTruthy(axis)) {
      return axis;
    }
  }
  throw StateError(
    "Cannot determine type of '$id' axis. "
    "Please provide 'axis' or 'position' option.",
  );
}

/// core.config.js:55 `getAxisFromDataset`.
///
/// The result is `{axis}`, or [undefined].
Object? _getAxisFromDataset(String id, String axis, Object? dataset) {
  if (id == jsGet(dataset, '${axis}AxisID')) {
    return <String, Object?>{'axis': axis};
  }
  return undefined;
}

/// core.config.js:61 `retrieveAxisFromDatasets`.
///
/// The result is `{axis}`, [undefined] or `{}`.
Object? _retrieveAxisFromDatasets(String id, Object config) {
  if (jsTruthy(jsGet(config, 'data')) &&
      jsTruthy(jsGet(jsGet(config, 'data'), 'datasets'))) {
    final boundDs = (jsGet(jsGet(config, 'data'), 'datasets')! as List)
        .where(
          (d) => id == jsGet(d, 'xAxisID') || id == jsGet(d, 'yAxisID'),
        )
        .toList();
    if (boundDs.isNotEmpty) {
      final axis = _getAxisFromDataset(id, 'x', boundDs[0]);
      return jsTruthy(axis) ? axis : _getAxisFromDataset(id, 'y', boundDs[0]);
    }
  }
  return <String, Object?>{};
}

/// core.config.js:71 `mergeScaleConfig`.
///
/// `console.error` and `console.warn` are [print], as `deprecated` of
/// `helpers.core` does.
///
/// The result and each merged scale object are typed scopes (Chart.js ADR
/// 0054 §3): a `ScaleOptionsByIdScope` of `ScaleOptionsScope`s. `mergeIf`
/// into a typed scope makes typed children of the kinds of their keys. The
/// keys, the values and their order are the ones of the plain objects.
// DIVERGES(chartjs): adapt-typed-options, typed scale scopes.
ScaleOptionsByIdScope _mergeScaleConfig(Object config, Object options) {
  final overridesOfType = jsGet(overrides, jsGet(config, 'type'));
  final chartDefaults = jsTruthy(overridesOfType)
      ? overridesOfType
      : <String, Object?>{'scales': <String, Object?>{}};
  final configScales = _orObject(jsGet(options, 'scales'));
  final chartIndexAxis = getIndexAxis(jsGet(config, 'type'), options);
  final scales = ScaleOptionsByIdScope();

  // First figure out first scale id's per axis.
  for (final id in _objectKeys(configScales)) {
    final scaleConf = jsGet(configScales, id);
    if (!isObject(scaleConf)) {
      _consoleError('Invalid scale configuration for scale: $id');
      continue;
    }
    if (jsTruthy(jsGet(scaleConf, '_proxy'))) {
      _consoleWarn('Ignoring resolver passed as options for scale: $id');
      continue;
    }
    final axis = determineAxis(id, [
      scaleConf,
      _retrieveAxisFromDatasets(id, config),
      jsGet(defaults.lookup(OptionKey.scales)?.raw, jsGet(scaleConf, 'type')),
    ]);
    final defaultId = _getDefaultScaleIDFromAxis(axis, chartIndexAxis);
    final defaultScaleOptions = _orObject(jsGet(chartDefaults, 'scales'));
    scales[id] = mergeIf(ScaleOptionsScope(), [
      <String, Object?>{'axis': axis},
      scaleConf,
      jsGet(defaultScaleOptions, axis),
      jsGet(defaultScaleOptions, defaultId),
    ]);
  }

  // Then merge dataset defaults to scale configs
  final datasets = jsGet(jsGet(config, 'data'), 'datasets')! as List;
  for (final dataset in datasets) {
    final datasetType = jsGet(dataset, 'type');
    final type = jsTruthy(datasetType) ? datasetType : jsGet(config, 'type');
    final datasetIndexAxis = jsGet(dataset, 'indexAxis');
    final indexAxis = jsTruthy(datasetIndexAxis)
        ? datasetIndexAxis
        : getIndexAxis(type, options);
    final datasetDefaults = _orObject(jsGet(overrides, type));
    final defaultScaleOptions = _orObject(jsGet(datasetDefaults, 'scales'));
    for (final defaultID in _objectKeys(defaultScaleOptions)) {
      final axis = _getAxisFromDefaultScaleID(defaultID, indexAxis);
      final datasetAxisID = jsGet(dataset, '${jsToString(axis)}AxisID');
      final id = jsTruthy(datasetAxisID) ? datasetAxisID : axis;
      final key = jsToString(id);
      final current = jsGet(scales, key);
      scales[key] = jsTruthy(current) ? current : ScaleOptionsScope();
      mergeIf(scales[key], [
        <String, Object?>{'axis': axis},
        jsGet(configScales, id),
        jsGet(defaultScaleOptions, defaultID),
      ]);
    }
  }

  // apply scale defaults, if not overridden by dataset defaults
  for (final key in jsObjectKeys(scales)) {
    final scale = scales[key];
    // DIVERGES(chartjs): theme-H1, theme scale styles fill first.
    final theme = _themeOf(config);
    if (theme != null) {
      final themeScales = jsGet(theme, 'scales');
      mergeIf(scale, [
        if (isObject(themeScales)) jsGet(themeScales, jsGet(scale, 'type')),
        jsGet(theme, 'scale'),
      ]);
    }
    mergeIf(scale, [
      jsGet(defaults.lookup(OptionKey.scales)?.raw, jsGet(scale, 'type')),
      defaults.lookup(OptionKey.scale)?.raw ?? undefined,
    ]);
  }

  return scales;
}

/// core.config.js:115 `initOptions`.
///
/// An options object that is not an object (a Map or a typed scope) throws
/// a [TypeError] (row `adapt-config-objects`). Upstream throws a
/// `TypeError` for a primitive and writes the properties of an array or a
/// function.
void _initOptions(Object config) {
  final current = jsGet(config, 'options');
  final Object? options;
  if (jsTruthy(current)) {
    options = current;
  } else {
    jsSet(config, 'options', options = <String, Object?>{});
  }
  // DIVERGES(chartjs): adapt-config-objects, the options object is an object.
  if (!_isConfigObject(options)) throw TypeError();

  jsSet(
    options,
    'plugins',
    core.valueOrDefault(jsGet(options, 'plugins'), <String, Object?>{}),
  );
  jsSet(options, 'scales', _mergeScaleConfig(config, options!));
}

/// Whether [value] is an object of the config: a Map of the user or a typed
/// scope of the lowering of Chart.js ADR 0054 §7 (a typed object with a
/// face).
bool _isConfigObject(Object? value) =>
    value is AnyObject || value is JsObjectFace;

/// core.config.js:122 `initData`.
///
/// An array [data] gives a new Map (row `adapt-config-objects`). Upstream
/// writes the properties `datasets` and `labels` into the array, and no
/// Chart.js code reads its items. Thus the Map gives the same results, and
/// only the identity of `chart.data` differs. Another truthy [data] that is
/// not an object (a Map or a typed scope) throws a [TypeError]. Upstream
/// throws a `TypeError` for a primitive and writes the properties of a
/// function.
Object _initData(Object? data) {
  // Upstream reassigns its parameter.
  // DIVERGES(chartjs): adapt-config-objects, an array gives a new Map.
  final object = jsTruthy(data) && data is! List ? data : <String, Object?>{};
  // DIVERGES(chartjs): adapt-config-objects, the data object is an object.
  if (!_isConfigObject(object)) throw TypeError();
  jsSet(object, 'datasets', _or(jsGet(object, 'datasets'), <Object?>[]));
  jsSet(object, 'labels', _or(jsGet(object, 'labels'), <Object?>[]));
  return object!;
}

/// core.config.js:129 `initConfig`.
///
/// It returns the same object: the theme map under [themeConfigKey] stays in
/// it (theming.md §3.1). The config is a Map of the user or the typed root
/// of `ChartView` (a `ChartConfigurationScope`, Chart.js ADR 0054 §5). A
/// truthy [config] that is not an object throws a [TypeError] (row
/// `adapt-config-objects`). Upstream throws a `TypeError` for a primitive
/// and writes the properties of an array or a function.
Object _initConfig(Object? config) {
  // Upstream reassigns its parameter.
  final object = jsTruthy(config) ? config : <String, Object?>{};
  // DIVERGES(chartjs): adapt-config-objects, the config is an object.
  if (!_isConfigObject(object)) throw TypeError();
  jsSet(object, 'data', _initData(jsGet(object, 'data')));

  _initOptions(object!);

  return object;
}

/// core.config.js:138 `keyCache`: the scope key lists by cache key.
///
/// The cache keys are strings, or the dataset type of
/// [Config.datasetScopeKeys] as it is.
final Map<Object?, List<List<String>>> _keyCache = {};

/// core.config.js:139 `keysCached`: the key lists of [_keyCache], by
/// identity.
final Set<List<List<String>>> _keysCached = Set.identity();

/// core.config.js:141 `cachedKeys`.
List<List<String>> _cachedKeys(
  Object? cacheKey,
  List<List<String>> Function() generate,
) {
  var keys = _keyCache[cacheKey];
  if (keys == null) {
    keys = generate();
    _keyCache[cacheKey] = keys;
    _keysCached.add(keys);
  }
  return keys;
}

/// core.config.js:151 `addIfFound`.
void _addIfFound(Set<Object?> set, Object? obj, String key) {
  final opts = resolveObjectKey(obj, key);
  if (!identical(opts, undefined)) {
    set.add(opts);
  }
}

/// The key of the compiled theme in the raw chart configuration: `$theme`
/// (Chart.js ADR 0050, theming.md §3.1, hunk H0).
///
/// The chart widget puts the compiled theme map under this key. The theme is
/// a frozen map with the key shape of `Chart.defaults`. [Config] reads it
/// with `_themeOf`. The colors plugin reads it with [chartThemeOf].
// DIVERGES(chartjs): theme-H0, the theme key and its readers.
const String themeConfigKey = r'$theme';

/// The theme of the raw configuration [config]: the value under
/// [themeConfigKey] when it is an object (the frozen typed scope of the
/// compiled theme, or a Map), else Dart `null` (hunk H0).
Object? _themeOf(Object config) {
  final theme = jsGet(config, themeConfigKey);
  return _isConfigObject(theme) ? theme : null;
}

/// The theme of the chart configuration [config]: the value under
/// [themeConfigKey] of its raw configuration when it is an object, else
/// Dart `null` (hunk H0, Chart.js ADR 0050). Hunk H5 of `plugin.colors` reads
/// the palette from it. A configuration that is not a [Config] has no
/// theme.
Object? chartThemeOf(types.ChartConfiguration config) =>
    config is Config ? _themeOf(config._config) : null;

/// core.config.js:158 `class Config`, the default export.
///
/// It implements [types.ChartConfiguration], the type of the configuration
/// that `core.controller.js:137` gives to `platform.updateConfig`.
class Config implements types.ChartConfiguration {
  /// core.config.js:159 `constructor(config)`.
  ///
  /// [config] is the raw configuration: a Map of the user or a typed root
  /// scope. A falsy value gives a new Map. A truthy value that is not an
  /// object throws a [TypeError] (row `adapt-config-objects`).
  Config([Object? config]) : _config = _initConfig(config);

  /// core.config.js:160 `_config`: the raw configuration.
  final Object _config;

  /// core.config.js:161 `_scopeCache`: the scope lists of
  /// [getOptionScopes], by main scope and by key lists.
  final Map<Object?, Map<List<List<String>>, List<Object?>>> _scopeCache = {};

  /// core.config.js:162 `_resolverCache`: the resolvers of [createResolver]
  /// and [resolveNamedOptions], by scope list and by the joined prefixes.
  final Map<List<Object?>, Map<String, _CachedResolver>> _resolverCache = {};

  /// core.config.js:165 `get platform()`: the `platform` of the raw
  /// configuration, a class value, or [undefined].
  Object? get platform {
    return jsGet(_config, 'platform');
  }

  /// core.config.js:169 `get type()`: the chart type, or [undefined].
  Object? get type {
    return jsGet(_config, 'type');
  }

  /// core.config.js:173 `set type(type)`.
  set type(Object? type) {
    jsSet(_config, 'type', type);
  }

  /// core.config.js:177 `get data()`.
  ///
  /// `initData` makes it an object (a Map or a typed scope). Only a write
  /// into the raw configuration gives it another value. Then the getter
  /// throws a [TypeError] (row `adapt-config-objects`). Upstream returns the
  /// value.
  @override
  Object get data {
    // DIVERGES(chartjs): adapt-config-objects, the data object is an object.
    final data = jsGet(_config, 'data');
    return _isConfigObject(data) ? data! : throw TypeError();
  }

  /// core.config.js:181 `set data(data)`.
  ///
  /// A falsy [data] or an array gives a new Map. Another truthy value that
  /// is not an object throws a [TypeError] (row `adapt-config-objects`).
  set data(Object? data) {
    jsSet(_config, 'data', _initData(data));
  }

  /// core.config.js:185 `get options()`.
  ///
  /// `initOptions` makes it an object (a Map or a typed scope). After a set
  /// of a value that is not an object, the getter throws a [TypeError] until
  /// [update] (row `adapt-config-objects`). Upstream returns the value.
  @override
  Object get options {
    // DIVERGES(chartjs): adapt-config-objects, the options object is an
    // object.
    final options = jsGet(_config, 'options');
    return _isConfigObject(options) ? options! : throw TypeError();
  }

  /// core.config.js:189 `set options(options)`.
  set options(Object? options) {
    jsSet(_config, 'options', options);
  }

  /// core.config.js:193 `get plugins()`: the inline plugins of the raw
  /// configuration, or [undefined].
  Object? get plugins {
    return jsGet(_config, 'plugins');
  }

  /// core.config.js:197 `update()`.
  void update() {
    final config = _config;
    clearCache();
    _initOptions(config);
  }

  /// core.config.js:203 `clearCache()`.
  void clearCache() {
    _scopeCache.clear();
    _resolverCache.clear();
  }

  /// core.config.js:214 `datasetScopeKeys`.
  ///
  /// Returns the option scope keys for resolving dataset options.
  /// These keys do not include the dataset itself, because it is not under
  /// options.
  /// @param {string} datasetType
  /// @return {string[][]}
  ///
  /// The cache key is [datasetType] itself. Thus the type `'bar-point'`
  /// shares its key lists with [datasetElementScopeKeys] of `'bar'` and
  /// `'point'`, as upstream. A template literal is [jsToString].
  List<List<String>> datasetScopeKeys(Object? datasetType) {
    return _cachedKeys(
      datasetType,
      () => [
        ['datasets.${jsToString(datasetType)}', ''],
      ],
    );
  }

  /// core.config.js:229 `datasetAnimationScopeKeys`.
  ///
  /// Returns the option scope keys for resolving dataset animation options.
  /// These keys do not include the dataset itself, because it is not under
  /// options.
  /// @param {string} datasetType
  /// @param {string} transition
  /// @return {string[][]}
  List<List<String>> datasetAnimationScopeKeys(
    Object? datasetType,
    Object? transition,
  ) {
    final type = jsToString(datasetType);
    final mode = jsToString(transition);
    return _cachedKeys(
      '$type.transition.$mode',
      () => [
        ['datasets.$type.transitions.$mode', 'transitions.$mode'],
        // The following are used for looking up the `animations` and
        // `animation` keys
        ['datasets.$type', ''],
      ],
    );
  }

  /// core.config.js:252 `datasetElementScopeKeys`.
  ///
  /// Returns the options scope keys for resolving element options that
  /// belong to an dataset. These keys do not include the dataset itself,
  /// because it is not under options.
  /// @param {string} datasetType
  /// @param {string} elementType
  /// @return {string[][]}
  ///
  /// [elementType] is the `id` of an element class value (Chart.js ADR
  /// 0020, section 4): any value.
  List<List<String>> datasetElementScopeKeys(
    Object? datasetType,
    Object? elementType,
  ) {
    final type = jsToString(datasetType);
    final element = jsToString(elementType);
    return _cachedKeys(
      '$type-$element',
      () => [
        [
          'datasets.$type.elements.$element',
          'datasets.$type',
          'elements.$element',
          '',
        ],
      ],
    );
  }

  /// core.config.js:267 `pluginScopeKeys`.
  ///
  /// Returns the options scope keys for resolving plugin options.
  /// @param {{id: string, additionalOptionScopes?: string[]}} plugin
  /// @return {string[][]}
  ///
  /// [plugin] is a plugin object (a Map) or a class value (Chart.js ADR
  /// 0020, section 7). A truthy `additionalOptionScopes` must be a `List` of
  /// strings. Another value throws a [TypeError] when the key lists are made
  /// (row `adapt-config-objects`). Upstream spreads any iterable value, and
  /// a key that is not a string throws a `TypeError` in [getOptionScopes].
  List<List<String>> pluginScopeKeys(Object? plugin) {
    final id = jsToString(jsGet(plugin, 'id'));
    final type = jsToString(this.type);
    return _cachedKeys(
      '$type-plugin-$id',
      () => [
        [
          'plugins.$id',
          // DIVERGES(chartjs): adapt-config-objects, a List of strings.
          for (final scope
              in _or(jsGet(plugin, 'additionalOptionScopes'), const [])!
                  as List)
            scope as String,
        ],
      ],
    );
  }

  /// core.config.js:280 `_cachedScopes`.
  /// @private
  Map<List<List<String>>, List<Object?>> _cachedScopes(
    Object? mainScope,
    bool resetCache,
  ) {
    final scopeCache = _scopeCache;
    var cache = scopeCache[mainScope];
    if (cache == null || resetCache) {
      cache = {};
      scopeCache[mainScope] = cache;
    }
    return cache;
  }

  /// core.config.js:296 `getOptionScopes`.
  ///
  /// Resolves the objects from options and defaults for option value
  /// resolution.
  /// @param {object} mainScope - The main scope object for options
  /// @param {string[][]} keyLists - The arrays of keys in resolution order
  /// @param {boolean} [resetCache] - reset the cache for this mainScope
  ///
  /// The result is a growable list: `core.plugins.js:180` adds a scope to
  /// it. A cached result is the same list. With a theme, the theme scopes
  /// come between the scopes of `overrides[type]` and of `defaults` (hunk
  /// H2, theming.md §3.2).
  List<Object?> getOptionScopes(
    Object? mainScope,
    List<List<String>> keyLists, [
    // The upstream signature has a positional `resetCache`.
    // ignore: avoid_positional_boolean_parameters
    bool resetCache = false,
  ]) {
    final options = this.options;
    final type = this.type;
    final cache = _cachedScopes(mainScope, resetCache);
    final cached = cache[keyLists];
    if (cached != null) {
      return cached;
    }

    final scopes = <Object?>{};

    for (final keys in keyLists) {
      if (jsTruthy(mainScope)) {
        scopes.add(mainScope);
        for (final key in keys) {
          _addIfFound(scopes, mainScope, key);
        }
      }
      for (final key in keys) {
        _addIfFound(scopes, options, key);
      }
      for (final key in keys) {
        _addIfFound(scopes, _orObject(jsGet(overrides, type)), key);
      }
      // DIVERGES(chartjs): theme-H2, the theme scopes before the defaults.
      final theme = _themeOf(_config);
      if (theme != null) {
        for (final key in keys) {
          _addIfFound(scopes, theme, key);
        }
      }
      for (final key in keys) {
        _addIfFound(scopes, defaults, key);
      }
      for (final key in keys) {
        _addIfFound(scopes, descriptors, key);
      }
    }

    final array = scopes.toList();
    if (array.isEmpty) {
      array.add(<String, Object?>{});
    }
    if (_keysCached.contains(keyLists)) {
      cache[keyLists] = array;
    }
    return array;
  }

  /// core.config.js:331 `chartOptionScopes`.
  ///
  /// Returns the option scopes for resolving chart options
  /// @return {object[]}
  ///
  /// With a theme, the theme comes after `overrides[type]` (hunk H3,
  /// theming.md §3.2).
  List<Object?> chartOptionScopes() {
    final options = this.options;
    final type = this.type;

    return [
      options,
      _orObject(jsGet(overrides, type)),
      // DIVERGES(chartjs): theme-H3, the theme scope after the type overrides.
      ?_themeOf(_config),
      // https://github.com/chartjs/Chart.js/issues/8531
      _orObject(jsGet(defaults['datasets'], type)),
      <String, Object?>{'type': type},
      defaults,
      descriptors,
    ];
  }

  /// core.config.js:351 `resolveNamedOptions`.
  ///
  /// @param {object[]} scopes
  /// @param {string[]} names
  /// @param {function|object} context
  /// @param {string[]} [prefixes]
  /// @return {object}
  ///
  /// [into] is the empty object that receives the options (Chart.js ADR
  /// 0021, section 1): a Map or a typed object with a face. Dart `null`
  /// gives a new plain Map, as the object literal of upstream gives.
  ///
  /// [context] is a function value or an object. The context that it gives
  /// must be an object when an option needs it (row `adapt-config-objects`).
  /// Upstream also attaches another value.
  Object resolveNamedOptions(
    List<Object?> scopes,
    List<String> names,
    Object? context, [
    List<String> prefixes = const [''],
    Object? into,
  ]) {
    assert(into == null || jsObjectKeys(into).isEmpty, 'into must be empty');
    // DIVERGES(chartjs): adapt-typed-element-options, the caller gives result.
    final result = into ?? <String, Object?>{};
    jsSet(result, r'$shared', true);
    final (:resolver, :subPrefixes) = _getResolver(
      _resolverCache,
      scopes,
      prefixes,
    );
    Object options = resolver;
    if (_needContext(resolver, names)) {
      jsSet(result, r'$shared', false);
      // Upstream reassigns its parameter.
      // ignore: parameter_assignments
      context = isFunction(context) ? jsCall(context, const []) : context;
      // subResolver is passed to scriptable options. It should not resolve to
      // hover options.
      final subResolver = createResolver(scopes, context, subPrefixes);
      // DIVERGES(chartjs): adapt-config-objects, the context is an object.
      if (!isObject(context)) throw TypeError();
      options = helpers.attachContext(resolver, context!, subResolver);
    }

    for (final prop in names) {
      jsSet(result, prop, jsGet(options, prop));
    }
    return result;
  }

  /// core.config.js:351 `resolveNamedOptions` for the element step of
  /// `_resolveElementOptions` (Chart.js ADR 0054 §4).
  ///
  /// [keys] are the own keys of `defaults.elements[elementType]` in their
  /// order: an [OptionKey], or the name of an extra. [into] is the new typed
  /// options object of the element type. The reads and the writes are typed
  /// for a key of the schema: `readKey` of the resolver or of the view, and
  /// `storeKey` of the options. The order of the user calls and the results
  /// are the ones of [resolveNamedOptions].
  // DIVERGES(chartjs): adapt-typed-options, the typed element step.
  ElementOptions resolveElementNamedOptions(
    List<Object?> scopes,
    List<Object> keys,
    Object Function() context,
    List<String> prefixes,
    ElementOptions into,
  ) {
    into.storeKey(OptionKey.dollarShared, true);
    final (:resolver, :subPrefixes) = _getResolver(
      _resolverCache,
      scopes,
      prefixes,
    );
    helpers.OptionView? view;
    if (_needContextKeys(resolver, keys)) {
      into.storeKey(OptionKey.dollarShared, false);
      final ctx = context();
      // subResolver is passed to scriptable options. It should not resolve to
      // hover options.
      final subResolver = createResolver(scopes, ctx, subPrefixes);
      view = helpers.attachContext(resolver, ctx, subResolver);
    }

    for (final key in keys) {
      final Object? value;
      if (key is OptionKey) {
        value = view == null ? resolver.readKey(key) : view.readKey(key);
      } else {
        final name = key as String;
        value = view == null ? resolver[name] : view[name];
      }
      into.storeKey(key, value);
    }
    return into;
  }

  /// core.config.js:375 `createResolver`.
  ///
  /// @param {object[]} scopes
  /// @param {object} [context]
  /// @param {string[]} [prefixes]
  /// @param {{scriptable: boolean, indexable: boolean, allKeys?: boolean}}
  /// [descriptorDefaults]
  ///
  /// The result is the cached resolver of [scopes] and [prefixes]. A
  /// [context] that is an object gives a new context resolver over it. A
  /// null [descriptorDefaults] is an absent argument.
  JsProxyObject createResolver(
    List<Object?> scopes, [
    Object? context,
    List<String> prefixes = const [''],
    helpers.DescriptorDefaults? descriptorDefaults,
  ]) {
    final (:resolver, subPrefixes: _) = _getResolver(
      _resolverCache,
      scopes,
      prefixes,
    );
    return isObject(context)
        ? helpers.attachContext(
            resolver,
            context!,
            undefined,
            descriptorDefaults,
          )
        : resolver;
  }
}

/// The object `{resolver, subPrefixes}` of the resolver cache
/// (core.config.js:393-396).
typedef _CachedResolver = ({
  helpers.Resolver resolver,
  List<String> subPrefixes,
});

/// core.config.js:383 `getResolver`.
///
/// `prefixes.join()` joins with `','`. `toLowerCase` is the Dart
/// [String.toLowerCase]: only ASCII letters give the ASCII letters of
/// `'hover'` with the case mappings of JavaScript and of Dart.
_CachedResolver _getResolver(
  Map<List<Object?>, Map<String, _CachedResolver>> resolverCache,
  List<Object?> scopes,
  List<String> prefixes,
) {
  var cache = resolverCache[scopes];
  if (cache == null) {
    cache = {};
    resolverCache[scopes] = cache;
  }
  final cacheKey = prefixes.join(',');
  var cached = cache[cacheKey];
  if (cached == null) {
    final resolver = helpers.createResolver(scopes, prefixes);
    cached = (
      resolver: resolver,
      subPrefixes: prefixes
          .where((p) => !p.toLowerCase().contains('hover'))
          .toList(),
    );
    cache[cacheKey] = cached;
  }
  return cached;
}

/// core.config.js:402 `hasFunction`.
///
/// `Object.getOwnPropertyNames(value)` is [jsOwnPropertyNames]: the
/// `ownKeys` trap of a resolver, and the keys of a Map.
bool _hasFunction(Object? value) {
  if (!isObject(value)) return false;
  return jsOwnPropertyNames(value).any((key) => isFunction(jsGet(value, key)));
}

/// core.config.js:405 `needContext`.
///
/// `isScriptable` and `isIndexable` give the ToBoolean of their result
/// (`helpers.config.dart`). The callers test only its truth.
bool _needContext(helpers.Resolver proxy, List<String> names) {
  final descriptors = helpers.descriptors(proxy);

  for (final prop in names) {
    final scriptable = descriptors.isScriptable(prop);
    final indexable = descriptors.isIndexable(prop);
    final value = (indexable || scriptable) ? proxy[prop] : false;
    if ((scriptable && (isFunction(value) || _hasFunction(value))) ||
        (indexable && isArray(value))) {
      return true;
    }
  }
  return false;
}

/// core.config.js:405 `needContext` over the typed keys of the element
/// step: the result of `needContext` for their names, with the typed read
/// `readKey` of a key of the schema.
bool _needContextKeys(helpers.OptionResolver proxy, List<Object> keys) {
  final descriptors = helpers.descriptors(proxy);

  for (final key in keys) {
    final prop = key is OptionKey ? key.jsName : key as String;
    final scriptable = descriptors.isScriptable(prop);
    final indexable = descriptors.isIndexable(prop);
    final value = (indexable || scriptable)
        ? (key is OptionKey ? proxy.readKey(key) : proxy[prop])
        : false;
    if ((scriptable && (isFunction(value) || _hasFunction(value))) ||
        (indexable && isArray(value))) {
      return true;
    }
  }
  return false;
}

/// `value || {}`: [value] when it is truthy, else a new Map.
Object? _orObject(Object? value) =>
    jsTruthy(value) ? value : <String, Object?>{};

/// `value || other`: [value] when it is truthy, else [other].
Object? _or(Object? value, Object? other) => jsTruthy(value) ? value : other;

/// `Object.keys(value)` for the `scales` objects of the options and of the
/// overrides: [jsObjectKeys]. A Map or a typed object gives its keys, a List
/// or a String its indices, any other value no key. Throws a [TypeError]
/// for `null` and [undefined], as JavaScript does.
List<String> _objectKeys(Object? value) => jsObjectKeys(value);

/// `console.error(message)`.
void _consoleError(String message) {
  // console.error has no other counterpart in the pure layers.
  // ignore: avoid_print
  print(message);
}

/// `console.warn(message)`.
void _consoleWarn(String message) {
  // console.warn has no other counterpart in the pure layers.
  // ignore: avoid_print
  print(message);
}
