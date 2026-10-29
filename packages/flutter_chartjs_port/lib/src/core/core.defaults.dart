// Ported from Chart.js v4.5.1+7169e651 src/core/core.defaults.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.defaults.js`.
///
/// Chart.js ADR 0043 ("Global scopes") decides the representation:
/// [defaults], [overrides] and [descriptors] are `Map<String, Object?>`. The
/// option keys of [Defaults] are Map keys, not Dart fields. A JS plain object
/// is a `Map<String, Object?>`, `undefined` is the [undefined] sentinel and
/// `null` is Dart `null`. Numbers are `double` (Chart.js ADR 0045). A function
/// value is a Dart closure (`lib/src/js/js_function.dart`).
///
/// `Object.defineProperties` has no Dart form. [Defaults.route] makes the
/// scope a [RoutedScope], a `MapBase` that reads the route target when the
/// local value is `undefined` (differences.md row `adapt-defaults-route`).
library;

import 'dart:collection';
import 'dart:core';
import 'dart:core' as core show override;

import 'package:flutter_chartjs_port/src/core/core.animations.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.layouts.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.defaults.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.color.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// core.defaults.js:7 `overrides`, `Object.create(null)`.
///
/// JavaScript runs the module body at import, and the constructor of the
/// default export fills [descriptors] and [overrides] then. Dart initializes
/// [defaults] lazily. Thus the getter reads [defaults] first.
AnyObject get overrides {
  _loadModule();
  return _overrides;
}

/// core.defaults.js:8 `descriptors`, `Object.create(null)`.
///
/// The getter reads [defaults] first, as [overrides] does.
AnyObject get descriptors {
  _loadModule();
  return _descriptors;
}

/// The object of [overrides]. The constructor of [Defaults] writes it before
/// [defaults] has a value.
final AnyObject _overrides = <String, Object?>{};

/// The object of [descriptors]. The constructor of [Defaults] writes it
/// before [defaults] has a value.
final AnyObject _descriptors = <String, Object?>{};

/// Initializes [defaults], as the import of the JavaScript module does.
void _loadModule() {
  defaults.length;
}

/// core.defaults.js:15 `getScope`.
///
/// @param {object} node
/// @param {string} key
/// @return {object}
///
/// Each node on the path must be a Map. A node of another type throws a
/// [TypeError] (differences.md row `adapt-defaults-scope-object`).
Object? _getScope(Object? root, String key) {
  var node = root;
  if (key.isEmpty) {
    return node;
  }
  final keys = key.split('.');
  for (var i = 0, n = keys.length; i < n; ++i) {
    final k = keys[i];
    // DIVERGES(chartjs): adapt-defaults-scope-object, a node is a Map.
    final object = node is AnyObject ? node : throw TypeError();
    final value = jsGet(object, k);
    node = jsTruthy(value) ? value : (object[k] = <String, Object?>{});
  }
  return node;
}

/// core.defaults.js:27 `set`.
///
/// The result is the scope object. A scope path that ends at a value that is
/// not a Map throws a [TypeError] (differences.md row
/// `adapt-defaults-scope-object`).
AnyObject _set(AnyObject root, Object? scope, Object? values) {
  if (scope is String) {
    // DIVERGES(chartjs): adapt-defaults-scope-object, the scope is a Map.
    return merge(_getScope(root, scope), values)! as AnyObject;
  }
  return merge(_getScope(root, ''), scope)! as AnyObject;
}

/// core.defaults.js:130-157 the scope object of [Defaults.route]: an object
/// with properties that `Object.defineProperties` made.
///
/// Upstream defines two properties on the scope object for each routed name:
/// a hidden `_<name>` that holds the local value, and an enumerable accessor
/// `<name>` that reads it. Dart has no accessor properties on a Map. Thus a
/// [RoutedScope] keeps the local value in [ownValues] under `<name>` and
/// reads the route of [routes] in `operator []`. The hidden `_<name>` is not
/// a key (differences.md row `adapt-defaults-route`).
///
/// A scope without routes behaves as a plain `Map<String, Object?>`.
// DIVERGES(chartjs): adapt-defaults-route, a MapBase for defineProperties.
base class RoutedScope extends MapBase<String, Object?> {
  /// A routed scope over [ownValues]. Without an argument, the scope is
  /// empty.
  ///
  /// [Defaults.route] passes the Map that it replaces. The routed scope then
  /// keeps the keys, the values and the key order of that Map.
  RoutedScope([AnyObject? ownValues])
    : ownValues = ownValues ?? <String, Object?>{};

  /// The own properties of the scope, in key order. For a routed name, the
  /// value is the local value: the upstream hidden property `_<name>`.
  ///
  /// Read the scope through the Map interface. The test harness reads and
  /// restores [ownValues] and [routes] directly
  /// (`package:chartjs_test_utils/pure.dart`).
  final AnyObject ownValues;

  /// The routes of the scope, by routed name.
  final Map<String, DefaultsRoute> routes = <String, DefaultsRoute>{};

  /// The [RoutedScope] that took the place of each plain Map in
  /// [Defaults.route].
  ///
  /// Upstream defines the routed properties on the scope object itself. The
  /// port puts a new [RoutedScope] in the place of a plain Map. A route that
  /// already keeps that Map as its target scope reads the [RoutedScope]
  /// through this table. Thus the two Dart objects stand for one JavaScript
  /// object.
  static final Expando<RoutedScope> _replacements = Expando<RoutedScope>(
    'RoutedScope',
  );

  /// The [RoutedScope] that took the place of [map], or null.
  ///
  /// The test harness saves it and restores it with [setReplacement]
  /// (`package:chartjs_test_utils/pure.dart`).
  static RoutedScope? replacementOf(AnyObject map) => _replacements[map];

  /// Sets the [RoutedScope] that took the place of [map]. Null removes it.
  /// For the test harness only.
  static void setReplacement(AnyObject map, RoutedScope? scope) {
    _replacements[map] = scope;
  }

  /// core.defaults.js:144-151 the getter of a routed property. Any other key
  /// reads [ownValues].
  @override
  Object? operator [](Object? key) {
    final route = routes[key];
    if (route == null) {
      return ownValues[key];
    }
    final local = ownValues[key];
    final target = jsGet(
      _resolveScope(route.targetScope),
      route.targetName,
    );
    if (isObject(local)) {
      return _assign(<String, Object?>{}, [target, local]);
    }
    return valueOrDefault(local, target);
  }

  /// core.defaults.js:152-154 the setter of a routed property. Any other key
  /// sets [ownValues].
  @override
  void operator []=(String key, Object? value) {
    ownValues[key] = value;
  }

  /// `Object.keys`: the own keys, routed names included. The hidden
  /// `_<name>` properties are not keys.
  @override
  Iterable<String> get keys => ownValues.keys;

  @override
  int get length => ownValues.length;

  @override
  bool containsKey(Object? key) => ownValues.containsKey(key);

  /// `delete scope[key]` in strict mode.
  ///
  /// A routed name that the scope did not own before its first route is not
  /// configurable: its delete throws a [TypeError]. The delete of a
  /// configurable routed name removes the route. The result is the value
  /// that the scope gave for [key] before the delete.
  @override
  Object? remove(Object? key) {
    final route = routes[key];
    if (route == null) {
      return ownValues.remove(key);
    }
    if (!route.configurable) {
      // A JavaScript TypeError: "Cannot delete property".
      throw TypeError();
    }
    final value = this[key];
    routes.remove(key);
    ownValues.remove(key);
    return value;
  }

  @override
  void clear() {
    keys.toList().forEach(remove);
  }
}

/// The route of a routed name of a [RoutedScope] (core.defaults.js:130).
///
/// - `targetScope`: the target scope object, `targetScopeObject`. A route
///   keeps the object, not the path, as upstream does.
/// - `targetName`: the property of `targetScope` that the route reads.
/// - `configurable`: whether the scope owned the name before its first route.
///   `Object.defineProperties` keeps the `configurable` attribute of an own
///   property. A new property is not configurable.
typedef DefaultsRoute = ({
  Object? targetScope,
  String targetName,
  bool configurable,
});

/// core.defaults.js:38 `Defaults`.
///
/// Please use the module's default export which provides a singleton instance
/// Note: class is exported for typedoc
///
/// The upstream fields are the Map keys of the instance (Chart.js ADR 0043,
/// "Global scopes"). Read them as Map entries, for example
/// `defaults['color']`.
base class Defaults extends RoutedScope implements types.Defaults {
  /// core.defaults.js:39 `constructor(_descriptors, _appliers)`.
  ///
  /// [descriptorValues] is `_descriptors`. [appliers] is `_appliers`.
  Defaults(Object? descriptorValues, List<void Function(Defaults)> appliers) {
    this['animation'] = undefined;
    this['backgroundColor'] = 'rgba(0,0,0,0.1)';
    this['borderColor'] = 'rgba(0,0,0,0.1)';
    this['color'] = '#666';
    this['datasets'] = <String, Object?>{};
    this['devicePixelRatio'] = _fn1(
      (context) => (jsGet(context, 'chart')! as types.Chart).platform
          .getDevicePixelRatio(),
    );
    this['elements'] = <String, Object?>{};
    this['events'] = <Object?>[
      'mousemove',
      'mouseout',
      'click',
      'touchstart',
      'touchmove',
    ];
    this['font'] = <String, Object?>{
      'family': "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
      'size': 12.0,
      'style': 'normal',
      'lineHeight': 1.2,
      'weight': null,
    };
    this['hover'] = <String, Object?>{};
    // getHoverColor gives Dart null for the JavaScript undefined of a color
    // that does not parse. `?? undefined` gives the sentinel back.
    this['hoverBackgroundColor'] = _fn2(
      (ctx, options) =>
          getHoverColor(jsGet(options, 'backgroundColor')) ?? undefined,
    );
    this['hoverBorderColor'] = _fn2(
      (ctx, options) =>
          getHoverColor(jsGet(options, 'borderColor')) ?? undefined,
    );
    this['hoverColor'] = _fn2(
      (ctx, options) => getHoverColor(jsGet(options, 'color')) ?? undefined,
    );
    this['indexAxis'] = 'x';
    this['interaction'] = <String, Object?>{
      'mode': 'nearest',
      'intersect': true,
      'includeInvisible': false,
    };
    this['maintainAspectRatio'] = true;
    this['onHover'] = null;
    this['onClick'] = null;
    this['parsing'] = true;
    this['plugins'] = <String, Object?>{};
    this['responsive'] = true;
    this['scale'] = undefined;
    this['scales'] = <String, Object?>{};
    this['showLine'] = true;
    this['drawActiveElementsOnTop'] = true;

    describe(descriptorValues);
    apply(appliers);
  }

  /// core.defaults.js:90 `set`.
  ///
  /// @param {string|object} scope
  /// @param {object} [values]
  ///
  /// A [scope] that is not a `String` is the values object of the root.
  @core.override
  AnyObject set(Object? scope, [Object? values = undefined]) {
    return _set(this, scope, values);
  }

  /// core.defaults.js:97 `get`.
  ///
  /// @param {string} scope
  ///
  /// A scope path that ends at a value that is not a Map throws a
  /// [TypeError] (differences.md row `adapt-defaults-scope-object`).
  AnyObject get(String scope) {
    // DIVERGES(chartjs): adapt-defaults-scope-object, the scope is a Map.
    return _getScope(this, scope)! as AnyObject;
  }

  /// core.defaults.js:105 `describe`.
  ///
  /// @param {string|object} scope
  /// @param {object} [values]
  @core.override
  AnyObject describe(Object? scope, [Object? values = undefined]) {
    return _set(_descriptors, scope, values);
  }

  /// core.defaults.js:109 `override`.
  AnyObject override(Object? scope, [Object? values = undefined]) {
    return _set(_overrides, scope, values);
  }

  /// core.defaults.js:130 `route`.
  ///
  /// Routes the named defaults to fallback to another scope/name.
  /// This routing is useful when those target values, like defaults.color,
  /// are changed runtime.
  /// If the values would be copied, the runtime change would not take effect.
  /// By routing, the fallback is evaluated at each access, so its always up
  /// to date.
  ///
  /// Example:
  ///
  ///  defaults.route('elements.arc', 'backgroundColor', '', 'color')
  ///   - reads the backgroundColor from defaults.color when undefined locally
  ///
  /// @param {string} scope Scope this route applies to.
  /// @param {string} name Property name that should be routed to different
  /// namespace when not defined here.
  /// @param {string} targetScope The namespace where those properties should
  /// be routed to.
  /// Empty string ('') is the root of defaults.
  /// @param {string} targetName The target name in the target scope the
  /// property should be routed to.
  ///
  /// The routed scope is a [RoutedScope]. A scope object that is a plain Map
  /// becomes a [RoutedScope] over the same entries, in the object that owns
  /// it. The route of a name that the scope already routes throws a
  /// [TypeError] unless that name is configurable, as
  /// `Object.defineProperties` does. A scope object that is not a Map, for
  /// example an array, throws a [TypeError] after the target scope exists
  /// (differences.md row `adapt-defaults-scope-object`).
  @core.override
  void route(String scope, String name, String targetScope, String targetName) {
    final node = _getScope(this, scope);
    final targetScopeObject = _getScope(this, targetScope);
    // DIVERGES(chartjs): adapt-defaults-route, a RoutedScope for the scope.
    final scopeObject = _routedScope(scope, node);
    // The private property `'_' + name` is the local value in
    // [RoutedScope.ownValues].
    final owned = scopeObject.containsKey(name);
    final local = owned ? scopeObject[name] : undefined;
    final previous = scopeObject.routes[name];

    // A private property is defined to hold the actual value, when this
    // property is set in its scope (set in the setter)
    scopeObject.ownValues[name] = local;
    if (previous != null && !previous.configurable) {
      // A JavaScript TypeError: "Cannot redefine property".
      throw TypeError();
    }
    // The actual property is defined as getter/setter so we can do the
    // routing when value is not locally set.
    scopeObject.routes[name] = (
      targetScope: targetScopeObject,
      targetName: targetName,
      configurable: previous?.configurable ?? owned,
    );
  }

  /// The scope object [node] of [route] as a [RoutedScope].
  ///
  /// A plain Map becomes a [RoutedScope] over the same Map. The object that
  /// owns the Map as an own value gets the [RoutedScope] in its place, with
  /// the same key order. When the parent scope reaches [node] through a
  /// route, the owner is the target scope of that route, as upstream
  /// defines the properties on [node] itself. The local value of the parent
  /// does not change. A Map that a [RoutedScope] replaced before gets that
  /// [RoutedScope] back. When the parent gives a new object for each read (a
  /// routed object value), the route goes to that object only, as upstream.
  ///
  /// A [node] that is not a Map throws a [TypeError] (differences.md row
  /// `adapt-defaults-scope-object`).
  RoutedScope _routedScope(String scope, Object? node) {
    if (node is RoutedScope) {
      return node;
    }
    if (node is! AnyObject) {
      // A JavaScript TypeError: "Object.defineProperties called on
      // non-object". Upstream also routes an array or a function scope.
      // DIVERGES(chartjs): adapt-defaults-scope-object, the scope is a Map.
      throw TypeError();
    }
    final routed = RoutedScope._replacements[node] ?? RoutedScope(node);
    RoutedScope._replacements[node] = routed;
    final keys = scope.split('.');
    var name = keys.removeLast();
    var owner = _getScope(this, keys.join('.'));
    // Follow the routes that give [node] to the parent scope.
    while (owner is RoutedScope) {
      final route = owner.routes[name];
      if (route == null || identical(owner.ownValues[name], node)) {
        break;
      }
      owner = _resolveScope(route.targetScope);
      name = route.targetName;
    }
    if (owner is RoutedScope) {
      if (identical(owner.ownValues[name], node)) {
        owner.ownValues[name] = routed;
      }
    } else if (owner is AnyObject && owner is! JsProxyObject) {
      if (identical(jsGet(owner, name), node)) {
        owner[name] = routed;
      }
    }
    return routed;
  }

  /// core.defaults.js:159 `apply`.
  void apply(List<void Function(Defaults)> appliers) {
    for (final apply in appliers) {
      apply(this);
    }
  }
}

/// core.defaults.js:165 the default export: the singleton instance.
final Defaults defaults = Defaults(
  <String, Object?>{
    '_scriptable': (String name) => !name.startsWith('on'),
    '_indexable': (String name) => name != 'events',
    'hover': <String, Object?>{
      '_fallback': 'interaction',
    },
    'interaction': <String, Object?>{
      '_scriptable': false,
      '_indexable': false,
    },
  },
  [applyAnimationsDefaults, applyLayoutsDefaults, applyScaleDefaults],
);

/// The target scope object of a route: the [RoutedScope] that took the
/// place of a plain Map, else [scope].
Object? _resolveScope(Object? scope) =>
    scope is AnyObject && scope is! RoutedScope
    ? RoutedScope._replacements[scope] ?? scope
    : scope;

/// A function value of one parameter. It gives the closure of a field its
/// parameter type.
Object? Function(Object? a) _fn1(Object? Function(Object? a) function) =>
    function;

/// A function value of two parameters. It gives the closure of a field its
/// parameter types.
Object? Function(Object? a, Object? b) _fn2(
  Object? Function(Object? a, Object? b) function,
) => function;

/// `Object.assign(target, ...sources)` for the sources of a routed getter
/// (core.defaults.js:148).
///
/// A Map source gives its own keys in [jsObjectKeys] order. A List or a
/// String source gives its indices. `null`, [undefined] and other values
/// give nothing.
AnyObject _assign(AnyObject target, List<Object?> sources) {
  for (final source in sources) {
    if (source is AnyObject) {
      for (final key in jsObjectKeys(source)) {
        target[key] = source[key];
      }
    } else if (source is List || source is String) {
      final length = source is List
          ? source.length
          : (source! as String).length;
      for (var i = 0; i < length; i++) {
        target['$i'] = source is List ? source[i] : (source! as String)[i];
      }
    }
  }
  return target;
}
