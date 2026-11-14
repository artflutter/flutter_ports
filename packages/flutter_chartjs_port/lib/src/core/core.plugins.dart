// Ported from Chart.js v4.6.1 src/core/core.plugins.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-plugins, the plugins of Chart.js ADR 0144.

/// Port of `src/core/core.plugins.js`: the plugin service of a chart
/// (Chart.js ADR 0020, section 7).
///
/// A plugin is a native [Plugin] (Chart.js ADR 0144): the built-in plugins,
/// the registered plugins and the inline plugins of `config.plugins`. A hook
/// is a field of the plugin with the function type of its hook, and
/// [PluginService] reads it at each call through [Plugin.notify], as
/// upstream reads `plugin[hook]`.
///
/// The dispatch is typed: a hook is a [PluginHook], with its argument class
/// and its kind. A hook without arguments gets the `{}` of upstream, a
/// [PluginHookArgs]. A cancelable hook cancels with `false`: the kind of the
/// hook is the `args.cancelable` of upstream. The plugin options of the user
/// are read by name, as upstream.
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
    show DescriptorDefaults, OptionView, attachContext, readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isNullOrUndef, valueOrDefault;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsToNumber, jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart';
import 'package:meta/meta.dart';

/// core.plugins.js:12 the descriptor `{plugin: object, options: object}`
/// of a plugin: the plugin and its options resolver.
///
/// A record, as Chart.js ADR 0003 gives for an inline object type that
/// ported code only reads. `options` is the resolver view of
/// `createResolver`.
typedef PluginDescriptor = ({Plugin<Object?> plugin, Object options});

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
final class PluginService() {
  /// core.plugins.js:21 `constructor()`.
  this;

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

  /// Unknown plugins use the full lifecycle unless they explicitly opt in.
  /// A registry/config invalidation must first rebuild the descriptors normally.
  @internal
  bool get supportsDataUpdates {
    final descriptors = cache;
    if (descriptors == null) return false;
    for (final descriptor in descriptors) {
      if (!descriptor.plugin.allowsDataUpdates(descriptor.options)) {
        return false;
      }
    }
    return true;
  }

  /// Whether each plugin of the cached descriptors keeps the promise of the
  /// partial lifecycles for `Chart.updateRanges` (Chart.js ADR 0111): a
  /// [Plugin] with [Plugin.supportsDataUpdates] and no failed
  /// [Plugin.rangeUpdateGuard]. [Plugin.dataUpdateGuard] states a concern
  /// of the data-only lifecycle, which skips the layout: the range update runs
  /// each hook and the layout, so it does not call it. No cache (a
  /// [invalidate] since the last notify) gives false, and so does the options
  /// object of a descriptor that is not a view of `createResolver`.
  @internal
  // DIVERGES(chartjs): adapt-range-updates, the plugin opt-in of a range.
  bool get supportsRangeUpdates {
    final descriptors = cache;
    if (descriptors == null) return false;
    for (final descriptor in descriptors) {
      final options = descriptor.options;
      if (options is! OptionView) return false;
      if (!descriptor.plugin.allowsRangeUpdates(options)) return false;
    }
    return true;
  }

  /// The descriptors of a range update of [chart] (Chart.js ADR 0111): each
  /// cached descriptor with a new context view over its resolver, with the
  /// descriptor defaults of `pluginOpts` (core.plugins.js:186-189).
  ///
  /// `update` calls [invalidate] (core.plugins.js:73-83), and its next notify
  /// makes new scope lists and new resolvers (`_createDescriptors`,
  /// core.plugins.js:101-111, :175-188). Under the contract of the range
  /// update the plugins, their order and their options did not change, so the
  /// kept resolvers give the values of new ones and `_notifyStateChanges`
  /// would find no change: no `start` or `stop`. The old descriptors become
  /// `_oldCache`, as after [invalidate]. The caller tested
  /// [supportsRangeUpdates].
  @internal
  // DIVERGES(chartjs): adapt-range-updates, new views over kept resolvers.
  void refreshDescriptorViews(types.Chart chart) {
    final cached = cache!;
    final context = chart.getContext();
    _oldCache = cached;
    cache = [
      for (final descriptor in cached)
        (
          plugin: descriptor.plugin,
          options: attachContext(
            (descriptor.options as OptionView).resolver,
            context,
            undefined,
            _pluginDescriptorDefaults,
          ),
        ),
    ];
  }

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
  /// [hook] is a hook of the `Plugin` interface, with the argument class [A]
  /// of its calls (Chart.js ADR 0144). Dart `null` for [args] stands for the
  /// absent argument of a hook without arguments, the `{}` of upstream, and
  /// Dart `null` for [filter] for an absent filter. The result is Dart `null`
  /// for the `undefined` of a notify before the hook `install`
  /// (core.plugins.js:41-43).
  bool? notify<A extends Object>(
    types.Chart chart,
    PluginHook<A> hook, [
    A? args,
    FilterCallback? filter,
  ]) {
    if (hook == PluginHook.beforeInit) {
      final init = _init = _createDescriptors(chart, true);
      _notify(init, chart, PluginHook.install, const PluginHookArgs());
    }

    if (_init == null) {
      // Do not trigger events before install
      return null;
    }

    final descriptors = filter != null
        ? _descriptors(chart).where(filter).toList()
        : _descriptors(chart);
    final result = _notify(descriptors, chart, hook, args ?? _noArgs(hook));

    if (hook == PluginHook.afterDestroy) {
      _notify(descriptors, chart, PluginHook.stop, const PluginHookArgs());
      _notify(_init!, chart, PluginHook.uninstall, const PluginHookArgs());
      _init = null; // Do not trigger events after uninstall
    }
    return result;
  }

  /// core.plugins.js:59 `_notify`.
  /// @private
  ///
  /// The lines differ from the upstream lines with the same result for each
  /// input (Chart.js ADR 0020, sections 7 and 13, Chart.js ADR 0144).
  /// [Plugin.notify] reads the hook field of [hook] and calls it with
  /// `(chart, args, options)`: an absent hook continues. A cancelable hook
  /// cancels with `false`, which is the `false` result with the
  /// `args.cancelable` of upstream: the kind of the hook is that flag.
  bool _notify<A extends Object>(
    List<PluginDescriptor> descriptors,
    types.Chart chart,
    PluginHook<A> hook,
    A args,
  ) {
    for (final descriptor in descriptors) {
      final plugin = descriptor.plugin;
      if (!plugin.notify(hook, chart, args, descriptor.options) &&
          hook.cancelable) {
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
    ) => a.where((x) => !b.any((y) => x.plugin.id == y.plugin.id)).toList();
    _notify(
      diff(previousDescriptors, descriptors),
      chart,
      PluginHook.stop,
      const PluginHookArgs(),
    );
    _notify(
      diff(descriptors, previousDescriptors),
      chart,
      PluginHook.start,
      const PluginHookArgs(),
    );
  }
}

/// The `{}` of a notify without arguments (core.plugins.js:60): a
/// [PluginHookArgs] for a hook whose argument class is [PluginHookArgs]. A
/// hook with another argument class needs its arguments.
A _noArgs<A extends Object>(PluginHook<A> hook) =>
    switch (const PluginHookArgs()) {
      final A args => args,
      _ => throw ArgumentError.notNull('args of ${hook.jsName}'),
    };

/// core.plugins.js:125 `allPlugins`.
///
/// @param {import('./core.config.js').default} config
///
/// The registered plugins come in the `Object.keys` order of
/// `registry.plugins.items` ([jsObjectKeys]), then the inline plugins of
/// `config.plugins` in their index order. The test
/// `plugins.indexOf(plugin) === -1` is a test with `identical`. The result
/// is the object `{plugins, localIds}` as a record.
///
/// An inline plugin is a [Plugin] (Chart.js ADR 0144). A value of another
/// type stops a debug build, and a release build skips it. Dart `null`
/// throws the JavaScript `TypeError` of `plugin.id`.
({List<Plugin<Object?>> plugins, Map<String, bool> localIds}) _allPlugins(
  Config config,
) {
  final localIds = <String, bool>{};
  final plugins = <Plugin<Object?>>[];
  final keys = jsObjectKeys(registry.plugins.items);
  for (var i = 0; i < keys.length; i++) {
    plugins.add(registry.getPlugin(keys[i]) as Plugin<Object?>);
  }

  // The inline plugins of the config of the user, read by index.
  final local = _or(config.plugins, const <Object?>[]);
  final length = jsToNumber(jsGet(local, 'length'));
  for (var i = 0; i < length; i++) {
    final plugin = jsGet(local, i);
    // A JavaScript TypeError at `plugin.id` below for null.
    if (plugin == null || identical(plugin, undefined)) throw TypeError();
    if (plugin is! Plugin<Object?>) {
      assert(false, 'An inline plugin is a Plugin, not $plugin.');
      continue;
    }

    if (!plugins.any((p) => identical(p, plugin))) {
      plugins.add(plugin);
      localIds[plugin.id] = true;
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
  ({List<Plugin<Object?>> plugins, Map<String, bool> localIds}) allPlugins,
  Object? options,
  bool all,
) {
  final (:plugins, :localIds) = allPlugins;
  final result = <PluginDescriptor>[];
  final context = chart.getContext();

  for (final plugin in plugins) {
    final id = plugin.id;
    // The plugin options of the user, read by the plugin id.
    final opts = _getOpts(jsGet(options, id), all);
    if (opts == null) {
      continue;
    }
    result.add((
      plugin: plugin,
      options: _pluginOpts(
        chart.config as Config,
        (plugin: plugin, local: localIds[id] ?? false),
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
Object _pluginOpts(
  Config config,
  ({Plugin<Object?> plugin, bool local}) pluginAndLocal,
  Object? opts,
  Object context,
) {
  final (:plugin, :local) = pluginAndLocal;
  final keys = config.pluginScopeKeys(plugin);
  final scopes = config.getOptionScopes(opts, keys);
  if (local && jsTruthy(plugin.defaults)) {
    // make sure plugin defaults are in scopes for local (not registered)
    // plugins
    scopes.add(plugin.defaults);
  }
  return config.createResolver(
    scopes,
    context,
    [''],
    // These are just defaults that plugins can override
    _pluginDescriptorDefaults,
  );
}

/// The descriptor defaults of `pluginOpts` (core.plugins.js:186-189).
const DescriptorDefaults _pluginDescriptorDefaults = DescriptorDefaults(
  scriptable: false,
  indexable: false,
  allKeys: true,
);

/// `value || other`: [value] when it is truthy, else [other].
Object? _or(Object? value, Object? other) => jsTruthy(value) ? value : other;
