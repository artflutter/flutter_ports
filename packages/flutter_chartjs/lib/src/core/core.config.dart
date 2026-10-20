// Ported from Chart.js v4.5.1+7169e651 src/core/core.config.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.config.js`: the chart configuration and the option
/// scopes of the resolver.
///
/// The JavaScript values map to Dart values as Chart.js ADR 0006 decides: the
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
/// Four hunks add the compiled theme of Chart.js ADR 0001 as an option scope
/// (theming.md §3.1): H0 ([themeConfigKey] and the private `_themeOf`), H1
/// (`mergeScaleConfig`), H2 ([Config.getOptionScopes]) and H3
/// ([Config.chartOptionScopes]). The chart widget puts the theme into the raw
/// configuration under [themeConfigKey]. Without a theme, the hunks add no
/// scope and no key, and the results are the upstream results.
///
/// [Config.resolveNamedOptions] takes the result object of the caller
/// (Chart.js ADR 0021, section 1): the dataset controller gives the typed
/// options class of the element type. This file does not import the element
/// options, as upstream imports no element module.
library;

import 'package:flutter_chartjs/src/core/core.defaults.dart';
import 'package:flutter_chartjs/src/helpers/helpers.config.dart' as helpers;
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show isArray, isFunction, isObject, mergeIf, resolveObjectKey;
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    as core
    show valueOrDefault;
import 'package:flutter_chartjs/src/js/js_array.dart'
    show jsObjectKeys, jsOwnPropertyNames;
import 'package:flutter_chartjs/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs/src/js/js_number.dart'
    show jsToString, jsTruthy;
import 'package:flutter_chartjs/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;

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
Object? _retrieveAxisFromDatasets(String id, AnyObject config) {
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
AnyObject _mergeScaleConfig(AnyObject config, AnyObject options) {
  final overridesOfType = jsGet(overrides, jsGet(config, 'type'));
  final chartDefaults = jsTruthy(overridesOfType)
      ? overridesOfType
      : <String, Object?>{'scales': <String, Object?>{}};
  final configScales = _orObject(jsGet(options, 'scales'));
  final chartIndexAxis = getIndexAxis(jsGet(config, 'type'), options);
  final scales = <String, Object?>{};

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
      jsGet(defaults['scales'], jsGet(scaleConf, 'type')),
    ]);
    final defaultId = _getDefaultScaleIDFromAxis(axis, chartIndexAxis);
    final defaultScaleOptions = _orObject(jsGet(chartDefaults, 'scales'));
    scales[id] = mergeIf(<String, Object?>{}, [
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
      scales[key] = _orObject(jsGet(scales, key));
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
      final themeScales = theme['scales'];
      mergeIf(scale, [
        if (themeScales is AnyObject) jsGet(themeScales, jsGet(scale, 'type')),
        theme['scale'],
      ]);
    }
    mergeIf(scale, [
      jsGet(defaults['scales'], jsGet(scale, 'type')),
      defaults['scale'],
    ]);
  }

  return scales;
}

/// core.config.js:115 `initOptions`.
///
/// An options object that is not a Map throws a [TypeError] (row
/// `adapt-config-objects`). Upstream throws a `TypeError` for a primitive
/// and writes the properties of an array or a function.
void _initOptions(AnyObject config) {
  final current = jsGet(config, 'options');
  final options = jsTruthy(current)
      ? current
      : (config['options'] = <String, Object?>{});
  // DIVERGES(chartjs): adapt-config-objects, the options object is a Map.
  if (options is! AnyObject) throw TypeError();

  options['plugins'] = core.valueOrDefault(
    jsGet(options, 'plugins'),
    <String, Object?>{},
  );
  options['scales'] = _mergeScaleConfig(config, options);
}

/// core.config.js:122 `initData`.
///
/// An array [data] gives a new Map (row `adapt-config-objects`). Upstream
/// writes the properties `datasets` and `labels` into the array, and no
/// Chart.js code reads its items. Thus the Map gives the same results, and
/// only the identity of `chart.data` differs. Another truthy [data] that is
/// not a Map throws a [TypeError]. Upstream throws a `TypeError` for a
/// primitive and writes the properties of a function.
AnyObject _initData(Object? data) {
  // Upstream reassigns its parameter.
  // DIVERGES(chartjs): adapt-config-objects, an array gives a new Map.
  final object = jsTruthy(data) && data is! List ? data : <String, Object?>{};
  // DIVERGES(chartjs): adapt-config-objects, the data object is a Map.
  if (object is! AnyObject) throw TypeError();
  object['datasets'] = _or(jsGet(object, 'datasets'), <Object?>[]);
  object['labels'] = _or(jsGet(object, 'labels'), <Object?>[]);
  return object;
}

/// core.config.js:129 `initConfig`.
///
/// It returns the same object: the theme map under [themeConfigKey] stays in
/// it (theming.md §3.1). A truthy [config] that is not a Map throws a
/// [TypeError] (row `adapt-config-objects`). Upstream throws a `TypeError`
/// for a primitive and writes the properties of an array or a function.
AnyObject _initConfig(Object? config) {
  // Upstream reassigns its parameter.
  final object = jsTruthy(config) ? config : <String, Object?>{};
  // DIVERGES(chartjs): adapt-config-objects, the config is a Map.
  if (object is! AnyObject) throw TypeError();
  object['data'] = _initData(jsGet(object, 'data'));

  _initOptions(object);

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
/// (Chart.js ADR 0001, theming.md §3.1, hunk H0).
///
/// The chart widget puts the compiled theme map under this key. The theme is
/// a frozen map with the key shape of `Chart.defaults`. [Config] reads it
/// with `_themeOf`.
// DIVERGES(chartjs): theme-H0, the theme key and its reader.
const String themeConfigKey = r'$theme';

/// The theme map of the raw configuration [config]: the value under
/// [themeConfigKey] when it is a Map, else Dart `null` (hunk H0).
AnyObject? _themeOf(AnyObject config) {
  final theme = config[themeConfigKey];
  return theme is AnyObject ? theme : null;
}

/// core.config.js:158 `class Config`, the default export.
///
/// It implements [types.ChartConfiguration], the type of the configuration
/// that `core.controller.js:137` gives to `platform.updateConfig`.
class Config implements types.ChartConfiguration {
  /// core.config.js:159 `constructor(config)`.
  ///
  /// [config] is the raw configuration. A falsy value gives a new Map. A
  /// truthy value that is not a Map throws a [TypeError] (row
  /// `adapt-config-objects`).
  Config([Object? config]) : _config = _initConfig(config);

  /// core.config.js:160 `_config`: the raw configuration.
  final AnyObject _config;

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
    _config['type'] = type;
  }

  /// core.config.js:177 `get data()`.
  ///
  /// `initData` makes it a Map. Only a write into the raw configuration
  /// gives it another value. Then the getter throws a [TypeError] (row
  /// `adapt-config-objects`). Upstream returns the value.
  AnyObject get data {
    // DIVERGES(chartjs): adapt-config-objects, the data object is a Map.
    return _config['data']! as AnyObject;
  }

  /// core.config.js:181 `set data(data)`.
  ///
  /// A falsy [data] or an array gives a new Map. Another truthy value that
  /// is not a Map throws a [TypeError] (row `adapt-config-objects`).
  set data(Object? data) {
    _config['data'] = _initData(data);
  }

  /// core.config.js:185 `get options()`.
  ///
  /// `initOptions` makes it a Map. After a set of a value that is not a Map,
  /// the getter throws a [TypeError] until [update] (row
  /// `adapt-config-objects`). Upstream returns the value.
  @override
  AnyObject get options {
    // DIVERGES(chartjs): adapt-config-objects, the options object is a Map.
    return _config['options']! as AnyObject;
  }

  /// core.config.js:189 `set options(options)`.
  set options(Object? options) {
    _config['options'] = options;
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
  /// 0021, section 1). Dart `null` gives a new plain Map, as the object
  /// literal of upstream gives. The dataset controller gives the typed
  /// options class of the element type (`createElementOptions` of
  /// `element_options.dart`).
  ///
  /// [context] is a function value or an object. The context that it gives
  /// must be a Map when an option needs it (row `adapt-config-objects`).
  /// Upstream also attaches another value.
  AnyObject resolveNamedOptions(
    List<Object?> scopes,
    List<String> names,
    Object? context, [
    List<String> prefixes = const [''],
    AnyObject? into,
  ]) {
    assert(into == null || into.isEmpty, 'into must be empty');
    // DIVERGES(chartjs): adapt-typed-element-options, the caller gives result.
    final result = (into ?? <String, Object?>{})..[r'$shared'] = true;
    final (:resolver, :subPrefixes) = _getResolver(
      _resolverCache,
      scopes,
      prefixes,
    );
    AnyObject options = resolver;
    if (_needContext(resolver, names)) {
      result[r'$shared'] = false;
      // Upstream reassigns its parameter.
      // ignore: parameter_assignments
      context = isFunction(context) ? jsCall(context, const []) : context;
      // subResolver is passed to scriptable options. It should not resolve to
      // hover options.
      final subResolver = createResolver(scopes, context, subPrefixes);
      // DIVERGES(chartjs): adapt-config-objects, the context is a Map.
      options = helpers.attachContext(
        resolver,
        context! as AnyObject,
        subResolver,
      );
    }

    for (final prop in names) {
      result[prop] = options[prop];
    }
    return result;
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
  AnyObject createResolver(
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
            context! as AnyObject,
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
  final object = value! as AnyObject;
  return jsOwnPropertyNames(object).any((key) => isFunction(object[key]));
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

/// `value || {}`: [value] when it is truthy, else a new Map.
Object? _orObject(Object? value) =>
    jsTruthy(value) ? value : <String, Object?>{};

/// `value || other`: [value] when it is truthy, else [other].
Object? _or(Object? value, Object? other) => jsTruthy(value) ? value : other;

/// `Object.keys(value)` for the `scales` objects of the options and of the
/// overrides.
///
/// A Map gives [jsObjectKeys]. A List or a String gives its indices. Any
/// other value gives no key. Throws a [TypeError] for `null` and
/// [undefined], as JavaScript does.
List<String> _objectKeys(Object? value) {
  if (value == null || identical(value, undefined)) {
    throw TypeError();
  }
  if (value is AnyObject) {
    return jsObjectKeys(value);
  }
  if (value is List || value is String) {
    final length = value is List ? value.length : (value as String).length;
    return [for (var i = 0; i < length; i++) '$i'];
  }
  return const [];
}

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
