// Ported from Chart.js v4.6.1 src/core/core.typedRegistry.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.typedRegistry.js`: the registry of one type of
/// chart component (Chart.js ADR 0020, section 5).
///
/// A component is a class value ([JsClass]), a plugin Map or another value.
/// The JSDoc type of a component is `IChartComponent`
/// (core.typedRegistry.js:4-6), `{id: string, defaults: any, overrides?: any,
/// defaultRoutes: any}`. [TypedRegistry.register] reads these properties
/// with [jsGet]. Thus a class value, a Map and any other value give the
/// upstream result. A class value reads them through its static prototype
/// chain.
///
/// `new Error(message)` is a [StateError] with the upstream message, as in
/// `helpers.config.dart`.
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart' show merge;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsNumberToString, jsToString, jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// core.typedRegistry.js:8 `TypedRegistry`, the default export.
final class TypedRegistry {
  /// core.typedRegistry.js:9 `constructor(type, scope, override)`.
  ///
  /// An absent [override] is false: upstream tests only its truthiness
  /// (core.typedRegistry.js:48, :77).
  TypedRegistry(
    this.type,
    this.scope, [
    // The upstream signature has a positional `override`.
    // ignore: avoid_positional_boolean_parameters
    this.override = false,
  ]);

  /// core.typedRegistry.js:10 `type`: the class value of the base class of
  /// the components, or [jsObjectClass] for the plugins.
  final JsClass type;

  /// core.typedRegistry.js:11 `scope`: the scope of the defaults, for
  /// example `'datasets'`.
  final String scope;

  /// core.typedRegistry.js:12 `override`: whether [register] writes the
  /// `overrides` of a component.
  final bool override;

  /// core.typedRegistry.js:13 `items`, `Object.create(null)`: the
  /// registered components by `id`.
  ///
  /// A key is the `ToString` of an `id` ([jsToString]), the `ToPropertyKey`
  /// of `id in items` and of `items[id] = item`. Read the keys in the
  /// upstream order with [jsObjectKeys].
  final Map<String, Object> items = <String, Object>{};

  /// core.typedRegistry.js:16 `isForType`.
  ///
  /// `Object.prototype.isPrototypeOf.call(this.type.prototype,
  /// type.prototype)`: true for a class value whose superclass chain has
  /// [type] ([JsClass.isSubclassOf]). The test is strict: [type] itself is
  /// not for its own registry. Each other value has no `prototype` that a
  /// class prototype can be the prototype of: a Map, a string, a number, a
  /// Dart `Function` (an arrow function or a method) and a `JsFunction` give
  /// false.
  ///
  /// Throws a [TypeError] for Dart `null` and [undefined], as the read
  /// `type.prototype` does.
  bool isForType(Object? type) {
    if (type == null || type is Undefined) {
      // A JavaScript TypeError: a property read of null or undefined.
      throw TypeError();
    }
    return type is JsClass && type.isSubclassOf(this.type);
  }

  /// core.typedRegistry.js:24 `register`.
  ///
  /// @param {IChartComponent} item
  /// @returns {string} The scope where items defaults were registered to.
  ///
  /// `Object.getPrototypeOf(item)` is the superclass of a class value. Each
  /// other value has a built-in prototype, which is never a component. Throws
  /// a [TypeError] for Dart `null` and [undefined], and a [StateError] for an
  /// item without a truthy `id`.
  String register(Object? item) {
    final proto = _getPrototypeOf(item);
    String? parentScope;

    if (_isIChartComponent(proto)) {
      // Make sure the parent is registered and note the scope where its
      // defaults are.
      parentScope = register(proto);
    }

    final items = this.items;
    final id = jsGet(item, 'id');
    final scope = '${this.scope}.${jsToString(id)}';

    if (!jsTruthy(id)) {
      throw StateError('class does not have id: ${jsToString(item)}');
    }

    final key = _propertyKey(id);
    if (items.containsKey(key)) {
      // already registered
      return scope;
    }

    items[key] = item!;
    _registerDefaults(item, scope, parentScope);
    if (override) {
      defaults.override(jsGet(item, 'id'), jsGet(item, 'overrides'));
    }

    return scope;
  }

  /// core.typedRegistry.js:59 `get`.
  ///
  /// @param {string} id
  /// @returns {object?}
  ///
  /// Dart `null` stands for `undefined`: no component has the key of [id].
  Object? get(Object? id) {
    return items[_propertyKey(id)];
  }

  /// core.typedRegistry.js:66 `unregister`.
  ///
  /// @param {IChartComponent} item
  ///
  /// Throws a [TypeError] for Dart `null` and [undefined], as the read
  /// `item.id` does. Also throws a [TypeError] when `defaults[scope]` is not
  /// a Map, as the `in` operator does for a value that is not an object
  /// (core.typedRegistry.js:75).
  void unregister(Object? item) {
    final items = this.items;
    final id = jsGet(item, 'id');
    final scope = this.scope;
    final key = _propertyKey(id);

    if (items.containsKey(key)) {
      items.remove(key);
    }

    if (scope.isNotEmpty) {
      // DIVERGES(chartjs): adapt-defaults-scope-object, the scope is a Map.
      final scopeObject = switch (defaults[scope]) {
        final Map<dynamic, dynamic> map => map,
        // A JavaScript TypeError: `in` of a value that is not an object.
        _ => throw TypeError(),
      };
      if (scopeObject.containsKey(key)) {
        scopeObject.remove(key);
        if (override) {
          overrides.remove(key);
        }
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
void _registerDefaults(Object item, String scope, String? parentScope) {
  // Inherit the parent's defaults and keep existing defaults
  final itemDefaults = merge(<String, Object?>{}, [
    if (jsTruthy(parentScope))
      defaults.get(parentScope!)
    else
      <String, Object?>{},
    defaults.get(scope),
    jsGet(item, 'defaults'),
  ]);

  defaults.set(scope, itemDefaults);

  final defaultRoutes = jsGet(item, 'defaultRoutes');
  if (jsTruthy(defaultRoutes)) {
    _routeDefaults(scope, defaultRoutes);
  }

  final itemDescriptors = jsGet(item, 'descriptors');
  if (jsTruthy(itemDescriptors)) {
    defaults.describe(scope, itemDescriptors);
  }
}

/// core.typedRegistry.js:103 `routeDefaults`.
///
/// A key of [routes] is a dot path under [scope]. Its value is the dot path
/// of the target. A value that is not a string throws a [TypeError], as the
/// call `routes[property].split('.')` does.
void _routeDefaults(String scope, Object? routes) {
  for (final property in _objectKeys(routes)) {
    final propertyParts = property.split('.');
    final sourceName = propertyParts.removeLast();
    final sourceScope = [scope, ...propertyParts].join('.');
    final target = jsGet(routes, property);
    // A JavaScript TypeError: `split` of a value that is not a string.
    final parts = target is String ? target.split('.') : throw TypeError();
    final targetName = parts.removeLast();
    final targetScope = parts.join('.');
    defaults.route(sourceScope, sourceName, targetScope, targetName);
  }
}

/// core.typedRegistry.js:115 `isIChartComponent`: `'id' in proto &&
/// 'defaults' in proto`.
///
/// [proto] is the result of [_getPrototypeOf]: a class value, or Dart `null`
/// for a built-in prototype, which has neither key.
bool _isIChartComponent(JsClass? proto) {
  return proto != null && proto.has('id') && proto.has('defaults');
}

/// `Object.getPrototypeOf(item)` where it can be a chart component: the
/// superclass of a class value ([JsClass.superclass]).
///
/// Dart `null` stands for each other prototype: `Function.prototype` of a
/// base class, and the built-in prototype of a Map, a List, a string or a
/// number. Throws a [TypeError] for Dart `null` and [undefined], as
/// `Object.getPrototypeOf` does.
JsClass? _getPrototypeOf(Object? item) => switch (item) {
  // A JavaScript TypeError: ToObject of null or undefined.
  null || Undefined() => throw TypeError(),
  final JsClass value => value.superclass,
  _ => null,
};

/// The `ToPropertyKey` of [id]: [id] itself for a string, else its
/// `ToString` ([jsToString]).
String _propertyKey(Object? id) => id is String ? id : jsToString(id);

/// `Object.keys(value)` for the truthy `defaultRoutes` value [value]: a Map
/// gives [jsObjectKeys], a List or a String gives its indices, and another
/// value gives no key.
List<String> _objectKeys(Object? value) {
  switch (value) {
    case final AnyObject object:
      return jsObjectKeys(object);
    case final List<Object?> list:
      return [for (var i = 0; i < list.length; i++) jsNumberToString(i)];
    case final String string:
      return [for (var i = 0; i < string.length; i++) jsNumberToString(i)];
  }
  return const [];
}
