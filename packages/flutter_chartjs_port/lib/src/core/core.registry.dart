// Ported from Chart.js v4.6.1 src/core/core.registry.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.registry.js`: the registry of the controllers,
/// the elements, the plugins and the scales (Chart.js ADR 0204).
///
/// An item is an [IChartComponent]: a [ControllerType], a [ScaleType], an
/// [ElementType] or a plugin. A rest parameter `...args` is one `Iterable`:
/// `registry.add(A, B)` is `registry.add([a, b])`. Upstream also takes an
/// array or a module namespace of items in place of an item; the port takes
/// items only.
///
/// `new Error(message)` is a [StateError] with the upstream message, as in
/// `core.typedRegistry.dart`.
///
/// This file imports `core.datasetController.dart` and `core.scale.dart` for
/// [ControllerType] and [ScaleType], as upstream imports the classes
/// (core.registry.js:1-3). `core.scale.dart` imports `helpers.extras`. Thus
/// this file is not a pure layer.
// DIVERGES(chartjs): adapt-typed-components, typed items, no nested items.
library;

import 'package:flutter_chartjs_port/chartjs.dart';

/// core.registry.js:11 `Registry`.
///
/// Please use the module's default export which provides a singleton
/// instance
/// Note: class is exported for typedoc
final class Registry() {
  /// core.registry.js:12 `constructor()`.
  this;

  /// core.registry.js:13 `controllers`: the dataset controllers, with the
  /// scope `datasets` and the overrides.
  final TypedRegistry<ControllerType> controllers =
      TypedRegistry<ControllerType>('datasets', true);

  /// core.registry.js:14 `elements`.
  final TypedRegistry<ElementType> elements = TypedRegistry<ElementType>(
    'elements',
  );

  /// core.registry.js:15 `plugins`.
  final TypedRegistry<Plugin<Object?>> plugins = TypedRegistry<Plugin<Object?>>(
    'plugins',
  );

  /// core.registry.js:16 `scales`.
  final TypedRegistry<ScaleType> scales = TypedRegistry<ScaleType>('scales');

  /// core.registry.js:25 `add(...args)`.
  ///
  /// @param  {...any} args
  void add(Iterable<IChartComponent> args) {
    for (final item in [...args]) {
      _execAny(register: true, item);
    }
  }

  /// core.registry.js:29 `remove(...args)`.
  void remove(Iterable<IChartComponent> args) {
    for (final item in [...args]) {
      _execAny(register: false, item);
    }
  }

  /// core.registry.js:36 `addControllers(...args)`.
  ///
  /// @param  {...typeof DatasetController} args
  void addControllers(Iterable<ControllerType> args) {
    _each(register: true, args, controllers);
  }

  /// core.registry.js:43 `addElements(...args)`.
  ///
  /// @param  {...typeof Element} args
  void addElements(Iterable<ElementType> args) {
    _each(register: true, args, elements);
  }

  /// core.registry.js:50 `addPlugins(...args)`.
  ///
  /// @param  {...any} args
  void addPlugins(Iterable<Plugin<Object?>> args) {
    _each(register: true, args, plugins);
  }

  /// core.registry.js:57 `addScales(...args)`.
  ///
  /// @param  {...typeof Scale} args
  void addScales(Iterable<ScaleType> args) {
    _each(register: true, args, scales);
  }

  /// core.registry.js:65 `getController`.
  ///
  /// @param {string} id
  /// @returns {typeof DatasetController}
  ControllerType getController(String id) {
    return _get(id, controllers, 'controller');
  }

  /// core.registry.js:73 `getElement`.
  ///
  /// @param {string} id
  /// @returns {typeof Element}
  ElementType getElement(String id) {
    return _get(id, elements, 'element');
  }

  /// core.registry.js:81 `getPlugin`: the registered plugin of the type
  /// [T], with no id.
  ///
  /// ```dart
  /// final zoom = registry.getPlugin<ZoomPlugin>();
  /// ```
  ///
  /// Each plugin is a class of its own, so its type selects it. No plugin of
  /// [T] throws a [StateError]. Two plugins of [T] stop a debug build.
  // DIVERGES(chartjs): adapt-typed-plugins, the plugin type is the key.
  T getPlugin<T extends Plugin<Object?>>() {
    final found = plugins.items.values.whereType<T>();
    if (found.isEmpty) {
      throw StateError('$T is not a registered plugin.');
    }
    assert(found.length == 1, 'More than one registered plugin is a $T.');
    return found.first;
  }

  /// core.registry.js:89 `getScale`.
  ///
  /// @param {string} id
  /// @returns {typeof Scale}
  ScaleType getScale(String id) {
    return _get(id, scales, 'scale');
  }

  /// core.registry.js:96 `removeControllers(...args)`.
  ///
  /// @param  {...typeof DatasetController} args
  void removeControllers(Iterable<ControllerType> args) {
    _each(register: false, args, controllers);
  }

  /// core.registry.js:103 `removeElements(...args)`.
  ///
  /// @param  {...typeof Element} args
  void removeElements(Iterable<ElementType> args) {
    _each(register: false, args, elements);
  }

  /// core.registry.js:110 `removePlugins(...args)`.
  ///
  /// @param  {...any} args
  void removePlugins(Iterable<Plugin<Object?>> args) {
    _each(register: false, args, plugins);
  }

  /// core.registry.js:117 `removeScales(...args)`.
  ///
  /// @param  {...typeof Scale} args
  void removeScales(Iterable<ScaleType> args) {
    _each(register: false, args, scales);
  }

  /// core.registry.js:124 `_each`, for one typed registry.
  /// @private
  void _each<T extends IChartComponent>(
    Iterable<T> args,
    TypedRegistry<T> typedRegistry, {
    required bool register,
  }) {
    for (final arg in [...args]) {
      _exec(register: register, typedRegistry, arg);
    }
  }

  /// core.registry.js:124 `_each` without a typed registry: the registry of
  /// the type of [item] (`_getRegistryForType`, core.registry.js:161).
  ///
  /// The registry of the plugins is the fallback, as upstream. An item of
  /// another class stops a debug build, and a release build skips it.
  void _execAny(IChartComponent item, {required bool register}) {
    switch (item) {
      case final ControllerType controller:
        _exec(register: register, controllers, controller);
      case final ScaleType scale:
        _exec(register: register, scales, scale);
      case final ElementType element:
        _exec(register: register, elements, element);
      case final Plugin<Object?> plugin:
        _exec(register: register, plugins, plugin);
      default:
        assert(false, 'A chart component or a Plugin, not $item.');
    }
  }

  /// core.registry.js:151 `_exec`.
  /// @private
  ///
  /// A hook gets [component] as its parameter, in place of `this` (Chart.js
  /// ADR 0173). A plugin has no register hooks.
  void _exec<T extends IChartComponent>(
    TypedRegistry<T> registry,
    T component, {
    required bool register,
  }) {
    final hooks = component is ChartComponent ? component : null;
    // beforeRegister / beforeUnregister
    if (register) {
      hooks?.beforeRegister?.call(hooks);
      registry.register(component);
      // afterRegister / afterUnregister
      hooks?.afterRegister?.call(hooks);
    } else {
      hooks?.beforeUnregister?.call(hooks);
      registry.unregister(component);
      hooks?.afterUnregister?.call(hooks);
    }
  }

  /// core.registry.js:175 `_get`.
  /// @private
  T _get<T extends IChartComponent>(
    String id,
    TypedRegistry<T> typedRegistry,
    String type,
  ) {
    final item = typedRegistry.get(id);
    if (item == null) {
      throw StateError('"$id" is not a registered $type.');
    }
    return item;
  }
}

/// core.registry.js:186 the default export: the singleton instance.
final Registry registry = Registry();
