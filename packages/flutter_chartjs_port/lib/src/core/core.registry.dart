// Ported from Chart.js v4.5.1+7169e651 src/core/core.registry.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.registry.js`: the registry of the controllers,
/// the elements, the plugins and the scales (Chart.js ADR 0020, section 5).
///
/// A rest parameter `...args` is one `List<Object?>` parameter. The Dart list
/// is the array of the rest parameter (Chart.js ADR 0020, section 6). Thus
/// `registry.add(A, B)` is `registry.add([a, b])`, and
/// `registry.add([A, B])` is `registry.add([[a, b]])`. An item is a class
/// value ([JsClass]), a plugin Map, another value, or a List or a Map of
/// items.
///
/// `new Error(message)` is a [StateError] with the upstream message, as in
/// `core.typedRegistry.dart`.
///
/// This file imports `core.datasetController.dart`, `core.element.dart` and
/// `core.scale.dart` for their class values, as upstream imports the
/// classes (core.registry.js:1-3). `core.scale.dart` imports
/// `helpers.extras`. Thus this file is not a pure layer (Chart.js ADR 0020,
/// section 10).
library;

import 'package:flutter_chartjs_port/src/core/core.datasetController.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/core/core.typedRegistry.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show callback, capitalize, each;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsToString, jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;

/// core.registry.js:11 `Registry`.
///
/// Please use the module's default export which provides a singleton
/// instance
/// Note: class is exported for typedoc
final class Registry {
  /// core.registry.js:12 `constructor()`.
  Registry();

  /// core.registry.js:13 `controllers`: the dataset controllers, with the
  /// scope `datasets` and the overrides.
  final TypedRegistry controllers = TypedRegistry(
    DatasetController.jsClass,
    'datasets',
    true,
  );

  /// core.registry.js:14 `elements`.
  final TypedRegistry elements = TypedRegistry(Element.jsClass, 'elements');

  /// core.registry.js:15 `plugins`: the registry of the type `Object`.
  final TypedRegistry plugins = TypedRegistry(jsObjectClass, 'plugins');

  /// core.registry.js:16 `scales`.
  final TypedRegistry scales = TypedRegistry(Scale.jsClass, 'scales');

  /// core.registry.js:19 `_typedRegistries`.
  // Order is important, Scale has Element in prototype chain,
  // so Scales must be before Elements. Plugins are a fallback, so not listed
  // here.
  late final List<TypedRegistry> _typedRegistries = [
    controllers,
    scales,
    elements,
  ];

  /// core.registry.js:25 `add(...args)`.
  ///
  /// @param  {...any} args
  void add(List<Object?> args) {
    _each('register', args);
  }

  /// core.registry.js:29 `remove(...args)`.
  void remove(List<Object?> args) {
    _each('unregister', args);
  }

  /// core.registry.js:36 `addControllers(...args)`.
  ///
  /// @param  {...typeof DatasetController} args
  void addControllers(List<Object?> args) {
    _each('register', args, controllers);
  }

  /// core.registry.js:43 `addElements(...args)`.
  ///
  /// @param  {...typeof Element} args
  void addElements(List<Object?> args) {
    _each('register', args, elements);
  }

  /// core.registry.js:50 `addPlugins(...args)`.
  ///
  /// @param  {...any} args
  void addPlugins(List<Object?> args) {
    _each('register', args, plugins);
  }

  /// core.registry.js:57 `addScales(...args)`.
  ///
  /// @param  {...typeof Scale} args
  void addScales(List<Object?> args) {
    _each('register', args, scales);
  }

  /// core.registry.js:65 `getController`.
  ///
  /// @param {string} id
  /// @returns {typeof DatasetController}
  ///
  /// The result is the registered value: a class value, or another value
  /// that [addControllers] registered (Chart.js ADR 0020, section 5).
  Object getController(Object? id) {
    return _get(id, controllers, 'controller');
  }

  /// core.registry.js:73 `getElement`.
  ///
  /// @param {string} id
  /// @returns {typeof Element}
  Object getElement(Object? id) {
    return _get(id, elements, 'element');
  }

  /// core.registry.js:81 `getPlugin`.
  ///
  /// @param {string} id
  /// @returns {object}
  Object getPlugin(Object? id) {
    return _get(id, plugins, 'plugin');
  }

  /// core.registry.js:89 `getScale`.
  ///
  /// @param {string} id
  /// @returns {typeof Scale}
  Object getScale(Object? id) {
    return _get(id, scales, 'scale');
  }

  /// core.registry.js:96 `removeControllers(...args)`.
  ///
  /// @param  {...typeof DatasetController} args
  void removeControllers(List<Object?> args) {
    _each('unregister', args, controllers);
  }

  /// core.registry.js:103 `removeElements(...args)`.
  ///
  /// @param  {...typeof Element} args
  void removeElements(List<Object?> args) {
    _each('unregister', args, elements);
  }

  /// core.registry.js:110 `removePlugins(...args)`.
  ///
  /// @param  {...any} args
  void removePlugins(List<Object?> args) {
    _each('unregister', args, plugins);
  }

  /// core.registry.js:117 `removeScales(...args)`.
  ///
  /// @param  {...typeof Scale} args
  void removeScales(List<Object?> args) {
    _each('unregister', args, scales);
  }

  /// core.registry.js:124 `_each`.
  /// @private
  ///
  /// `each` of `helpers.core` gives the items of a List in index order and
  /// the values of a Map in the `Object.keys` order. Its callback does not
  /// recurse.
  void _each(
    String method,
    List<Object?> args, [
    TypedRegistry? typedRegistry,
  ]) {
    for (final arg in [...args]) {
      final reg = typedRegistry ?? _getRegistryForType(arg);
      if (typedRegistry != null ||
          reg.isForType(arg) ||
          (identical(reg, plugins) && jsTruthy(jsGet(arg, 'id')))) {
        _exec(method, reg, arg);
      } else {
        // Handle loopable args
        // Use case:
        //  import * as plugins from './plugins.js';
        //  Chart.register(plugins);
        each(arg, (Object? item) {
          // If there are mixed types in the loopable, make sure those are
          // registered in correct registry
          // Use case: (treemap exporting controller, elements etc)
          //  import * as treemap from 'chartjs-chart-treemap.js';
          //  Chart.register(treemap);

          final itemReg = typedRegistry ?? _getRegistryForType(item);
          _exec(method, itemReg, item);
        });
      }
    }
  }

  /// core.registry.js:151 `_exec`.
  /// @private
  ///
  /// The callbacks get [component] as `this`. The call
  /// `registry[method](component)` is a `switch` on the two method names.
  void _exec(String method, TypedRegistry registry, Object? component) {
    final camelMethod = capitalize(method);
    // beforeRegister / beforeUnregister
    callback(jsGet(component, 'before$camelMethod'), const [], component);
    switch (method) {
      case 'register':
        registry.register(component);
      case 'unregister':
        registry.unregister(component);
    }
    // afterRegister / afterUnregister
    callback(jsGet(component, 'after$camelMethod'), const [], component);
  }

  /// core.registry.js:161 `_getRegistryForType`.
  /// @private
  TypedRegistry _getRegistryForType(Object? type) {
    for (var i = 0; i < _typedRegistries.length; i++) {
      final reg = _typedRegistries[i];
      if (reg.isForType(type)) {
        return reg;
      }
    }
    // plugins is the fallback registry
    return plugins;
  }

  /// core.registry.js:175 `_get`.
  /// @private
  ///
  /// The registry never stores Dart `null`: `register(null)` throws before
  /// the write. Thus Dart `null` from [TypedRegistry.get] is `undefined`.
  Object _get(Object? id, TypedRegistry typedRegistry, String type) {
    final item = typedRegistry.get(id);
    if (item == null) {
      throw StateError('"${jsToString(id)}" is not a registered $type.');
    }
    return item;
  }
}

/// core.registry.js:186 the default export: the singleton instance.
final Registry registry = Registry();
