// Ported from Chart.js v4.6.1 src/core/core.typedRegistry.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.typedRegistry.js`: the registry of one type of
/// chart component (Chart.js ADR 0204).
///
/// An item is an [IChartComponent]: a typed component of
/// `chart_component.dart` or a plugin. [TypedRegistry.register] reads its
/// typed fields, the `IChartComponent` of core.typedRegistry.js:4-6.
///
/// `new Error(message)` is a [StateError] with the upstream message, as in
/// `helpers.config.dart`.
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
// DIVERGES(chartjs): adapt-typed-components, the items are typed components.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// core.typedRegistry.js:8 `TypedRegistry`, the default export.
///
/// [T] is the type of the items: the `type` of upstream. The registry of
/// `Registry` picks the typed registry of an item by its Dart type, so this
/// class has no `isForType`.
final class TypedRegistry<T extends IChartComponent>(
  /// core.typedRegistry.js:11 `scope`: the scope of the defaults, for
  /// example `'datasets'`.
  final String scope, [

  /// core.typedRegistry.js:12 `override`: whether [register] writes the
  /// `overrides` of a component.
  final bool override = false,
]) {
  /// core.typedRegistry.js:9 `constructor(type, scope, override)`.
  this;

  /// core.typedRegistry.js:13 `items`, `Object.create(null)`: the
  /// registered components by `id`, in the order of registration.
  final Map<String, T> items = <String, T>{};

  /// core.typedRegistry.js:24 `register`.
  ///
  /// @param {IChartComponent} item
  /// @returns {string} The scope where items defaults were registered to.
  ///
  /// The [IChartComponent.parent] of [item] registers first, as the
  /// prototype of a class that is a component
  /// (core.typedRegistry.js:28-32).
  String register(T item) {
    final proto = item.parent;
    String? parentScope;

    if (proto is T) {
      // Make sure the parent is registered and note the scope where its
      // defaults are.
      parentScope = register(proto);
    }

    final items = this.items;
    final id = item.id;
    final scope = '${this.scope}.$id';

    if (id.isEmpty) {
      throw StateError('class does not have id: $item');
    }

    if (items.containsKey(id)) {
      // already registered
      return scope;
    }

    items[id] = item;
    _registerDefaults(item, scope, parentScope);
    if (override) {
      defaults.override(id, item.overrides ?? undefined);
    }

    return scope;
  }

  /// core.typedRegistry.js:59 `get`.
  ///
  /// @param {string} id
  /// @returns {object?}
  ///
  /// Dart `null` stands for `undefined`: no component has the key [id].
  T? get(String id) {
    return items[id];
  }

  /// core.typedRegistry.js:66 `unregister`.
  ///
  /// @param {IChartComponent} item
  ///
  /// Throws a [TypeError] when `defaults[scope]` is not an object (a typed
  /// scope or a Map), as the `in` operator does for a value that is not an
  /// object (core.typedRegistry.js:75).
  void unregister(T item) {
    final items = this.items;
    final key = item.id;
    final scope = this.scope;

    if (items.containsKey(key)) {
      items.remove(key);
    }

    if (scope.isNotEmpty) {
      // DIVERGES(chartjs): adapt-defaults-scope-object, the scope is an object.
      final scopeObject = defaults[scope];
      // A JavaScript TypeError: `in` of a value that is not an object.
      if (!jsIsObjectLike(scopeObject)) throw TypeError();
      // `if (key in scopeObject) delete scopeObject[key]`.
      var owned = false;
      switch (scopeObject) {
        case final JsObjectFace face:
          owned = face.jsDelete(key);
        case final Map<Object?, Object?> map:
          owned = map.containsKey(key);
          map.remove(key);
      }
      if (owned && override) {
        overrides.jsDelete(key);
      }
    }
  }
}

/// core.typedRegistry.js:84 `registerDefaults`.
///
/// `defaults.get` makes each absent scope object on the way (core.defaults.js
/// `getScope`). The merge keeps the key order of the current defaults of
/// [scope]: a value of `item.defaults` replaces the current value of its
/// key, and its new keys follow.
void _registerDefaults(
  IChartComponent item,
  String scope,
  String? parentScope,
) {
  final pluginDefaults = item.defaults;
  if (pluginDefaults is PluginOptions<Object?>) {
    // The options object of an add-on (Chart.js ADR 0148): it merges over
    // the options object of an earlier registration, and goes into its key.
    final dot = scope.lastIndexOf('.');
    final parent = defaults.get(scope.substring(0, dot));
    final key = scope.substring(dot + 1);
    final current = jsGet(parent, key);
    jsSet(
      parent,
      key,
      current is PluginOptions<Object?>
          ? current.mergeOptions(pluginDefaults)
          : pluginDefaults,
    );
    return;
  }
  // Inherit the parent's defaults and keep existing defaults
  final sources = [
    if (parentScope?.isNotEmpty ?? false)
      defaults.get(parentScope!)
    else
      <String, Object?>{},
    defaults.get(scope),
    pluginDefaults,
  ];
  // The object of upstream is a new typed scope of the kind of the scope
  // node (Chart.js ADR 0054 §3), or a raw Map for a raw node.
  // DIVERGES(chartjs): adapt-typed-options, a typed scope of the node kind.
  final node = sources[1];
  final itemDefaults = merge(
    node is OptionScope ? node.kind.create() : <String, Object?>{},
    sources,
  );

  defaults.set(scope, itemDefaults);

  final defaultRoutes = item.defaultRoutes;
  if (defaultRoutes != null) {
    _routeDefaults(scope, defaultRoutes);
  }

  final itemDescriptors = item.descriptors;
  if (itemDescriptors != null) {
    defaults.describe(scope, itemDescriptors);
  }
}

/// core.typedRegistry.js:103 `routeDefaults`.
///
/// A key of [routes] is a dot path under [scope]. Its value is the dot path
/// of the target.
void _routeDefaults(String scope, Map<String, String> routes) {
  for (final MapEntry(key: property, value: target) in routes.entries) {
    final propertyParts = property.split('.');
    final sourceName = propertyParts.removeLast();
    final sourceScope = [scope, ...propertyParts].join('.');
    final parts = target.split('.');
    final targetName = parts.removeLast();
    final targetScope = parts.join('.');
    defaults.route(sourceScope, sourceName, targetScope, targetName);
  }
}
