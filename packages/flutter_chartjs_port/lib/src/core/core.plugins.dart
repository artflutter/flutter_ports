// Ported from Chart.js v4.6.1 src/core/core.plugins.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-plugins, typed plugins of Chart.js ADR 0054.

/// Port of `src/core/core.plugins.js`: the plugin service of a chart
/// (Chart.js ADR 0020, section 7).
///
/// A plugin is a JavaScript object in the forms of Chart.js ADR 0043: a
/// `Map<String, Object?>` (the built-in plugins, the inline plugins of
/// `config.plugins` and the plugin objects of the specs), or a class value
/// (`JsClass`) that a program registers as a plugin. A hook is a function
/// value of `lib/src/js/js_function.dart`: a Dart `Function`, or a
/// `JsFunction` when the hook reads `this`. [PluginService] reads the hook
/// at each call, as upstream reads `plugin[hook]`.
///
/// The dispatch is typed (Chart.js ADR 0054 §12): a hook name of the
/// `Plugin` interface is a [PluginHook]. A typed [Plugin] (the seven
/// built-in plugins) gives the value of its hook field, and a Map plugin is
/// a [MapPlugin] (`map[hook]`). A hook without arguments gets a new
/// [PluginHookArgs], the `{}` of upstream. The `id` and the `defaults` of a
/// typed plugin are its typed fields ([_idOf], [_defaultsOf]), and the
/// `cancelable` of the typed args is their typed field ([_cancelable]).
/// The other plugin objects (a Map or a class value of user code), the
/// inline plugins of the config and the plugin options of the user are read
/// by name, as upstream.
///
/// The chart is a `types.Chart` (Chart.js ADR 0003). The file reads
/// `chart.config` as the `Config` of `core.config.dart`, as the dataset
/// controller does. This file imports `core.registry.dart`, which is not a
/// pure layer. Thus this file is not a pure layer (Chart.js ADR 0020,
/// section 10).
library;

import 'package:flutter_chartjs_port/src/core/core.config.dart' show Config;
import 'package:flutter_chartjs_port/src/core/core.registry.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show DescriptorDefaults, readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show callback, isNullOrUndef, valueOrDefault;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsIsFunction;
import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsToNumber, jsToString, jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart';
import 'package:meta/meta.dart';

/// core.plugins.js:12 the descriptor `{plugin: object, options: object}`
/// of a plugin: the plugin and its options resolver.
///
/// A record, as Chart.js ADR 0003 gives for an inline object type that
/// ported code only reads. `plugin` is a Map, a class value or another
/// registered value.
typedef PluginDescriptor = ({Object plugin, AnyObject options});

/// core.plugins.js:11 `filterCallback`: the filter of [PluginService.notify].
///
/// @callback filterCallback
/// @param {{plugin: object, options: object}} value
/// @return {boolean}
///
/// `Array.prototype.filter` also passes the index and the array. The one
/// caller, the event filter of `core.controller.js:1170`, reads only the
/// descriptor. `index.d.ts:585` declares `notifyPlugins` without a filter.
/// Thus no user function reaches it (Chart.js ADR 0020, section 7).
typedef FilterCallback = bool Function(PluginDescriptor value);

/// core.plugins.js:20 `PluginService`, the default export.
final class PluginService {
  /// core.plugins.js:21 `constructor()`.
  PluginService();

  /// core.plugins.js:22 `_init`: the descriptors of all plugins, also the
  /// disabled ones, from the hook `beforeInit` to the hook `afterDestroy`.
  /// Dart `null` stands for `undefined`.
  List<PluginDescriptor>? _init;

  /// core.plugins.js:94 `_cache`: the descriptors of the enabled plugins.
  /// Dart `null` stands for `undefined`.
  ///
  /// `isPluginEnabled` reads it (core.controller.js:1139). Thus it drops the
  /// underscore (Chart.js ADR 0012).
  @internal
  List<PluginDescriptor>? cache;

  /// core.plugins.js:80 `_oldCache`: the descriptors before the last
  /// [invalidate]. Dart `null` stands for `undefined`.
  List<PluginDescriptor>? _oldCache;

  /// core.plugins.js:35 `notify`.
  ///
  /// Calls enabled plugins for `chart` on the specified hook and with the
  /// given args. This method immediately returns as soon as a plugin
  /// explicitly returns false. The returned value can be used, for instance,
  /// to interrupt the current action.
  /// @param {Chart} chart - The chart instance for which plugins should be
  /// called.
  /// @param {string} hook - The name of the plugin method to call (e.g.
  /// 'beforeUpdate').
  /// @param {object} [args] - Extra arguments to apply to the hook call.
  /// @param {filterCallback} [filter] - Filtering function for limiting
  /// which plugins are notified
  /// @returns {boolean} false if any of the plugins return false, else
  /// returns true.
  ///
  /// Dart `null` for [args] and [filter] stands for an absent argument. The
  /// result is Dart `null` for the `undefined` of a notify before the hook
  /// `install` (core.plugins.js:41-43).
  bool? notify(
    types.Chart chart,
    String hook, [
    AnyObject? args,
    FilterCallback? filter,
  ]) {
    final pluginHook = PluginHook.of(hook);
    if (pluginHook == PluginHook.beforeInit) {
      final init = _init = _createDescriptors(chart, true);
      _notify(init, chart, PluginHook.install);
    }

    if (_init == null) {
      // Do not trigger events before install
      return null;
    }

    final descriptors = filter != null
        ? _descriptors(chart).where(filter).toList()
        : _descriptors(chart);
    final result = _notify(descriptors, chart, pluginHook, args, hook);

    if (pluginHook == PluginHook.afterDestroy) {
      _notify(descriptors, chart, PluginHook.stop);
      _notify(_init!, chart, PluginHook.uninstall);
      _init = null; // Do not trigger events after uninstall
    }
    return result;
  }

  /// core.plugins.js:59 `_notify`.
  /// @private
  ///
  /// The lines differ from the upstream lines with the same result for each
  /// input (Chart.js ADR 0020, sections 7 and 13, Chart.js ADR 0054 §12).
  /// [hook] is the [PluginHook] of the name, or Dart `null` for another
  /// [name] (the hook name of a user plugin), which reads the hook by name.
  /// A typed [Plugin] gives the value of its hook field and calls a function
  /// of the type of the hook with typed arguments ([Plugin.invokeHook]). A
  /// Map plugin ([MapPlugin]) reads `plugin[hook]` as a Map read: an absent
  /// key gives Dart `null`, which is not a function, as `undefined` is not.
  /// The `params` list exists only for a function value, where
  /// `callCallback` uses it (helpers.core.ts:108-110). A `JsFunction` hook
  /// gets the plugin as `this`: the plugin object, the Map, or the class
  /// value of a class plugin. A null [args] is the `{}` of upstream, a new
  /// [PluginHookArgs].
  bool _notify(
    List<PluginDescriptor> descriptors,
    types.Chart chart,
    PluginHook? hook, [
    AnyObject? args,
    String? name,
  ]) {
    final hookName = name ?? hook!.jsName;
    args ??= PluginHookArgs();
    for (final descriptor in descriptors) {
      final plugin = descriptor.plugin;
      final options = descriptor.options;
      final Object? result;
      switch (plugin) {
        case final Plugin typed:
          final method = hook != null
              ? typed.hookValue(hook)
              : typed.jsRead(hookName);
          if (method == null || !jsIsFunction(method)) continue;
          result = hook != null
              ? typed.invokeHook(hook, method, chart, args, options)
              : callback(method, [chart, args, options], typed);
        // `<dynamic, dynamic>` is the type test of jsGet: on dart2wasm it
        // costs about 33 ns less for each notify of 7 plugins than
        // `<String, Object?>` (Chart.js ADR 0020, probe 8).
        case final Map<dynamic, dynamic> map:
          final method = MapPlugin(map).hookValue(hookName);
          if (method == null || !jsIsFunction(method)) continue;
          result = MapPlugin(map).invokeHook(method, chart, args, options);
        default:
          // A plugin object of another kind (a class value of user code).
          final method = jsGet(plugin, hookName);
          if (!jsIsFunction(method)) continue;
          result = callback(method, [chart, args, options], plugin);
      }
      if (identical(result, false) && _cancelable(args)) {
        return false;
      }
    }

    return true;
  }

  /// core.plugins.js:73 `invalidate()`.
  void invalidate() {
    // When plugins are registered, there is the possibility of a double
    // invalidate situation. In this case, we only want to invalidate once.
    // If we invalidate multiple times, the `_oldCache` is lost and all of the
    // plugins are restarted without being correctly stopped.
    // See https://github.com/chartjs/Chart.js/issues/8147
    if (!isNullOrUndef(cache)) {
      _oldCache = cache;
      cache = null;
    }
  }

  /// core.plugins.js:89 `_descriptors`.
  ///
  /// @param {Chart} chart
  /// @private
  List<PluginDescriptor> _descriptors(types.Chart chart) {
    final cached = cache;
    if (cached != null) {
      return cached;
    }

    final descriptors = cache = _createDescriptors(chart);

    _notifyStateChanges(chart);

    return descriptors;
  }

  /// core.plugins.js:101 `_createDescriptors`.
  ///
  /// An absent [all] is false.
  List<PluginDescriptor> _createDescriptors(
    types.Chart chart, [
    bool all = false,
  ]) {
    final config = chart.config as Config;
    // `config.options && config.options.plugins`: the getter gives a Map,
    // which is truthy.
    // DIVERGES(chartjs): adapt-config-objects, the options getter casts.
    // The options of the config of the user: the typed read of the key, by
    // name for a Map of the user.
    final options = valueOrDefault<Object?>(
      readOption(config.options, OptionKey.plugins),
      <String, Object?>{},
    );
    final plugins = _allPlugins(config);
    // options === false => all plugins are disabled
    return identical(options, false) && !all
        ? []
        : createDescriptors(chart, plugins, options, all);
  }

  /// core.plugins.js:113 `_notifyStateChanges`.
  ///
  /// @param {Chart} chart
  /// @private
  ///
  /// The ids compare with `==`. For the Dart values of JavaScript values, it
  /// gives the result of `===`: strings and numbers compare by value, and
  /// the other values by identity.
  void _notifyStateChanges(types.Chart chart) {
    final previousDescriptors = _oldCache ?? const <PluginDescriptor>[];
    final descriptors = cache!;
    List<PluginDescriptor> diff(
      List<PluginDescriptor> a,
      List<PluginDescriptor> b,
    ) => a
        .where((x) => !b.any((y) => _idOf(x.plugin) == _idOf(y.plugin)))
        .toList();
    _notify(diff(previousDescriptors, descriptors), chart, PluginHook.stop);
    _notify(diff(descriptors, previousDescriptors), chart, PluginHook.start);
  }
}

/// core.plugins.js:125 `allPlugins`.
///
/// @param {import('./core.config.js').default} config
///
/// The registered plugins come in the `Object.keys` order of
/// `registry.plugins.items` ([jsObjectKeys]), then the inline plugins of
/// `config.plugins` in their index order. The test
/// `plugins.indexOf(plugin) === -1` is a test with `identical`. The key of
/// `localIds[plugin.id]` is the `ToString` of the `id`. Thus a local plugin
/// without an `id` gets the key `'undefined'`. The result is the object
/// `{plugins, localIds}` as a record.
({List<Object> plugins, Map<String, bool> localIds}) _allPlugins(
  Config config,
) {
  final localIds = <String, bool>{};
  final plugins = <Object>[];
  final keys = jsObjectKeys(registry.plugins.items);
  for (var i = 0; i < keys.length; i++) {
    plugins.add(registry.getPlugin(keys[i]));
  }

  // The inline plugins of the config of the user, read by index.
  final local = _or(config.plugins, const <Object?>[]);
  final length = jsToNumber(jsGet(local, 'length'));
  for (var i = 0; i < length; i++) {
    final plugin = jsGet(local, i);

    if (!plugins.any((p) => identical(p, plugin))) {
      // A JavaScript TypeError at `plugin.id` below for null.
      plugins.add(plugin ?? (throw TypeError()));
      localIds[_propertyKey(_idOf(plugin))] = true;
    }
  }

  return (plugins: plugins, localIds: localIds);
}

/// core.plugins.js:146 `getOpts`.
///
/// Dart `null` is the `null` result: the plugin has no descriptor.
Object? _getOpts(Object? options, bool all) {
  if (!all && identical(options, false)) {
    return null;
  }
  if (identical(options, true)) {
    return <String, Object?>{};
  }
  return options;
}

/// core.plugins.js:156 `createDescriptors`.
///
/// Upstream does not export it. Its name has no underscore, because the
/// method `_createDescriptors` of [PluginService] (core.plugins.js:101)
/// hides a private library function with the same name.
List<PluginDescriptor> createDescriptors(
  types.Chart chart,
  ({List<Object> plugins, Map<String, bool> localIds}) allPlugins,
  Object? options,
  // The upstream signature has a positional `all`.
  // ignore: avoid_positional_boolean_parameters
  bool all,
) {
  final (:plugins, :localIds) = allPlugins;
  final result = <PluginDescriptor>[];
  final context = chart.getContext();

  for (final plugin in plugins) {
    final id = _idOf(plugin);
    // The plugin options of the user, read by the plugin id.
    final opts = _getOpts(jsGet(options, id), all);
    if (opts == null) {
      continue;
    }
    result.add((
      plugin: plugin,
      options: _pluginOpts(
        chart.config as Config,
        (plugin: plugin, local: localIds[_propertyKey(id)] ?? false),
        opts,
        context,
      ),
    ));
  }

  return result;
}

/// core.plugins.js:175 `pluginOpts`.
///
/// `scopes.push` changes the scope list of `getOptionScopes`, which the
/// config keeps in its cache, as upstream does.
AnyObject _pluginOpts(
  Config config,
  ({Object plugin, bool local}) pluginAndLocal,
  Object? opts,
  AnyObject context,
) {
  final (:plugin, :local) = pluginAndLocal;
  final keys = config.pluginScopeKeys(plugin);
  final scopes = config.getOptionScopes(opts, keys);
  if (local && jsTruthy(_defaultsOf(plugin))) {
    // make sure plugin defaults are in scopes for local (not registered)
    // plugins
    scopes.add(_defaultsOf(plugin));
  }
  return config.createResolver(
    scopes,
    context,
    [''],
    // These are just defaults that plugins can override
    const DescriptorDefaults(
      scriptable: false,
      indexable: false,
      allKeys: true,
    ),
  );
}

/// `plugin.id`: the typed field of a [Plugin], else the read by name of a
/// plugin object of user code (a Map or a class value). `null` and
/// `undefined` throw the [TypeError] of the read.
Object? _idOf(Object? plugin) =>
    plugin is Plugin ? plugin.id : jsGet(plugin, 'id');

/// `plugin.defaults`: the typed field of a [Plugin], else the read by name
/// of a plugin object of user code.
Object? _defaultsOf(Object? plugin) =>
    plugin is Plugin ? plugin.defaults : jsGet(plugin, 'defaults');

/// `args.cancelable` with ToBoolean (core.plugins.js:66): the typed field of
/// a hook argument class, else the read by name of an args object of user
/// code (the public `notifyPlugins`).
bool _cancelable(AnyObject args) => switch (args) {
  final CancelableHookArgs typed => typed.cancelable,
  final UpdateHookArgs typed => typed.cancelable,
  final DatasetUpdateHookArgs typed => typed.cancelable,
  final DatasetDrawHookArgs typed => typed.cancelable,
  final EventHookArgs typed => typed.cancelable,
  final TooltipDrawHookArgs typed => typed.cancelable,
  _ => jsTruthy(jsGet(args, 'cancelable')),
};

/// `value || other`: [value] when it is truthy, else [other].
Object? _or(Object? value, Object? other) => jsTruthy(value) ? value : other;

/// The `ToPropertyKey` of [id]: [id] itself for a string, else its
/// `ToString` ([jsToString]).
String _propertyKey(Object? id) => id is String ? id : jsToString(id);
