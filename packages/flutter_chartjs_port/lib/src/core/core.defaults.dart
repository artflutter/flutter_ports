// Ported from Chart.js v4.6.1 src/core/core.defaults.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-options, typed scopes of Chart.js ADR 0054.

/// Port of `src/core/core.defaults.js`.
///
/// Chart.js ADR 0054 §3 decides the representation: [defaults],
/// [overrides] and [descriptors] are typed option scopes of
/// `lib/src/options/` (the kinds `ChartOptions`, `OverridesByType` and
/// `Descriptors` of `tool/options_schema.yaml`). Each nested object of the
/// built-in defaults is a typed scope of its kind. A key that the kind does
/// not declare is an extra. The readers by name read the typed scopes
/// through their face (Chart.js ADR 0054 §5). `undefined` is the
/// [undefined] sentinel and `null` is Dart `null`. Numbers are `double`
/// (Chart.js ADR 0045). A function value is a Dart closure
/// (`lib/src/js/js_function.dart`).
///
/// `Object.defineProperties` has no Dart form. [Defaults.route] gives a typed
/// scope a route of the key (`OptionScope.addRoute`): its read gives the
/// local value, the target value or a merge of both objects at each access.
/// A scope object or a target scope object that is a raw Map (a user object
/// of the defaults) becomes a typed scope with the same keys in the same
/// order, in the place of the Map in the object that owns it
/// (differences.md row `adapt-defaults-route`).
library;

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
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// core.defaults.js:7 `overrides`, `Object.create(null)`.
///
/// JavaScript runs the module body at import, and the constructor of the
/// default export fills [descriptors] and [overrides] then. Dart initializes
/// [defaults] lazily. Thus the getter reads [defaults] first.
OverridesByTypeScope get overrides {
  _loadModule();
  return _overrides;
}

/// core.defaults.js:8 `descriptors`, `Object.create(null)`.
///
/// The getter reads [defaults] first, as [overrides] does.
DescriptorsScope get descriptors {
  _loadModule();
  return _descriptors;
}

/// The object of [overrides]. The constructor of [Defaults] writes it before
/// [defaults] has a value.
final OverridesByTypeScope _overrides = OverridesByTypeScope();

/// The object of [descriptors]. The constructor of [Defaults] writes it
/// before [defaults] has a value.
final DescriptorsScope _descriptors = DescriptorsScope();

/// Initializes [defaults], as the import of the JavaScript module does.
void _loadModule() {
  defaults.ownKeyCount;
}

/// core.defaults.js:15 `getScope`.
///
/// @param {object} node
/// @param {string} key
/// @return {object}
///
/// Each node on the path must be an object: a typed scope or a Map. A node
/// of another type throws a [TypeError] (differences.md row
/// `adapt-defaults-scope-object`).
///
/// A new node of a typed scope is a typed scope of the kind of its key
/// (`OptionScope.childKindFor`, Chart.js ADR 0054 §3); another new node is
/// a raw Map, the `{}` of upstream.
Object? _getScope(Object? root, String key) {
  var node = root;
  if (key.isEmpty) {
    return node;
  }
  final keys = key.split('.');
  for (var i = 0, n = keys.length; i < n; ++i) {
    final k = keys[i];
    // DIVERGES(chartjs): adapt-defaults-scope-object, a node is an object.
    final object = _isScopeObject(node) ? node! : throw TypeError();
    final value = jsGet(object, k);
    if (jsTruthy(value)) {
      node = value;
    } else {
      jsSet(object, k, node = _newScope(object, k));
    }
  }
  return node;
}

/// The new empty node [key] of [parent] for [_getScope]: a typed scope of
/// the kind of [key] when [parent] is a typed scope with one, else a raw
/// Map.
Object _newScope(Object parent, String key) =>
    (parent is OptionScope ? parent.childKindFor(key)?.create() : null) ??
    <String, Object?>{};

/// core.defaults.js:27 `set`.
///
/// The result is the scope object. A scope path that ends at a value that is
/// not an object throws a [TypeError] (differences.md row
/// `adapt-defaults-scope-object`).
Object _set(Object root, Object? scope, Object? values) {
  if (scope is String) {
    // DIVERGES(chartjs): adapt-defaults-scope-object, the scope is an object.
    return _scopeObject(merge(_getScope(root, scope), values));
  }
  return _scopeObject(merge(_getScope(root, ''), scope));
}

/// Whether [node] is a scope object: a typed scope (a typed object with a
/// face) or a Map.
bool _isScopeObject(Object? node) => node is JsObjectFace || node is AnyObject;

/// [node] as a scope object. A value that is not an object throws a
/// [TypeError] (differences.md row `adapt-defaults-scope-object`).
Object _scopeObject(Object? node) =>
    _isScopeObject(node) ? node! : throw TypeError();

/// core.defaults.js:38 `Defaults`.
///
/// Please use the module's default export which provides a singleton instance
/// Note: class is exported for typedoc
///
/// The upstream fields are the keys of the typed scope `ChartOptionsScope`
/// (Chart.js ADR 0054 §3), in the upstream order of the constructor. The
/// typed setters write them; the readers by name read them as Map entries,
/// for example `defaults['color']`.
base class Defaults extends ChartOptionsScope implements types.Defaults {
  /// core.defaults.js:39 `constructor(_descriptors, _appliers)`.
  ///
  /// [descriptorValues] is `_descriptors`. [appliers] is `_appliers`.
  Defaults(Object? descriptorValues, List<void Function(Defaults)> appliers) {
    animationCell = optUndefined;
    backgroundColor = 'rgba(0,0,0,0.1)';
    borderColor = 'rgba(0,0,0,0.1)';
    this.color = '#666';
    datasets = DatasetOptionsByTypeScope();
    devicePixelRatioCell = OptFunction<double>(
      _fn1(
        (context) => (jsGet(context, 'chart')! as types.Chart).platform
            .getDevicePixelRatio(),
      ),
    );
    elements = ElementOptionsByTypeScope();
    events = <Object?>[
      'mousemove',
      'mouseout',
      'click',
      'touchstart',
      'touchmove',
    ];
    font = FontSpecScope()
      ..family = "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif"
      ..size = 12.0
      ..style = 'normal'
      ..lineHeight = 1.2
      ..weightCell = optNull;
    hover = InteractionOptionsScope();
    // getHoverColor gives Dart null for the JavaScript undefined of a color
    // that does not parse. `?? undefined` gives the sentinel back.
    hoverBackgroundColor = _fn2(
      (ctx, options) =>
          getHoverColor(jsGet(options, 'backgroundColor')) ?? undefined,
    );
    hoverBorderColor = _fn2(
      (ctx, options) =>
          getHoverColor(jsGet(options, 'borderColor')) ?? undefined,
    );
    hoverColor = _fn2(
      (ctx, options) => getHoverColor(jsGet(options, 'color')) ?? undefined,
    );
    indexAxis = 'x';
    interaction = InteractionOptionsScope()
      ..mode = 'nearest'
      ..intersect = true
      ..includeInvisible = false;
    maintainAspectRatio = true;
    onHoverCell = optNull;
    onClickCell = optNull;
    parsing = true;
    plugins = PluginOptionsByTypeScope();
    responsive = true;
    scaleCell = optUndefined;
    scales = ScaleOptionsByIdScope();
    showLine = true;
    drawActiveElementsOnTop = true;

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
  Object set(Object? scope, [Object? values = undefined]) {
    return _set(this, scope, values);
  }

  /// core.defaults.js:97 `get`.
  ///
  /// @param {string} scope
  ///
  /// A scope path that ends at a value that is not an object throws a
  /// [TypeError] (differences.md row `adapt-defaults-scope-object`).
  Object get(String scope) {
    // DIVERGES(chartjs): adapt-defaults-scope-object, the scope is an object.
    return _scopeObject(_getScope(this, scope));
  }

  /// core.defaults.js:105 `describe`.
  ///
  /// @param {string|object} scope
  /// @param {object} [values]
  @core.override
  Object describe(Object? scope, [Object? values = undefined]) {
    return _set(_descriptors, scope, values);
  }

  /// core.defaults.js:109 `override`.
  Object override(Object? scope, [Object? values = undefined]) {
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
  /// A typed scope object gets a typed route of [name]
  /// (`OptionScope.addRoute`, Chart.js ADR 0054 §3). A scope object or a
  /// target scope object that is a raw Map (a user object) becomes a typed
  /// scope with the same keys, values and key order, in the place of the Map
  /// in the object that owns it ([_typedScope]). The route of a name that
  /// the scope already routes throws a [TypeError] unless that name is
  /// configurable, as `Object.defineProperties` does. A scope object that is
  /// not an object, for example an array, throws a [TypeError] after the
  /// target scope exists (differences.md row `adapt-defaults-scope-object`).
  @core.override
  void route(String scope, String name, String targetScope, String targetName) {
    final node = _getScope(this, scope);
    var targetScopeObject = _getScope(this, targetScope);
    if (node is! OptionScope && node is! AnyObject) {
      // A JavaScript TypeError: "Object.defineProperties called on
      // non-object". Upstream also routes an array or a function scope.
      // DIVERGES(chartjs): adapt-defaults-scope-object, the scope is an object.
      throw TypeError();
    }
    // DIVERGES(chartjs): adapt-defaults-route, a typed scope for a raw Map.
    final scopeObject = _typedScope(scope, node);
    if (identical(targetScopeObject, node)) {
      targetScopeObject = scopeObject;
    } else if (targetScopeObject is AnyObject) {
      targetScopeObject = _typedScope(targetScope, targetScopeObject);
    }
    final target = targetScopeObject;

    // The getter of core.defaults.js:144-151, read at each access.
    Object? read(Object? local) {
      final value = jsGet(target, targetName);
      if (isObject(local)) {
        return _assign(<String, Object?>{}, [value, local]);
      }
      return valueOrDefault(local, value);
    }

    scopeObject.addRoute(
      name,
      ScopeRoute(read, targetScope: target, targetName: targetName),
    );
  }

  /// The scope object [node] at the path [scope] as a typed scope.
  ///
  /// A typed scope is the result. A raw Map becomes a typed scope with the
  /// same keys and values in the same order: the kind of its name in a typed
  /// owner, else a kind with no declared key, a plain object
  /// (`GenericElementOptions`). The object that owns the Map as an own value
  /// gets the typed scope in its place, with the same key order. When the
  /// parent scope reaches [node] through a route, the owner is the target
  /// scope of that route, as upstream defines the properties on [node]
  /// itself. When the parent gives a new object for each read (a routed
  /// object value), the route goes to that object only, as upstream.
  ///
  /// Upstream defines the properties on the object itself. A route thus
  /// keeps the identity of the object; here a Map of user code that the
  /// defaults hold and a route reaches is no longer the object of the
  /// defaults (differences.md row `adapt-defaults-route`).
  OptionScope _typedScope(String scope, Object? node) {
    if (node is OptionScope) return node;
    final map = node! as AnyObject;
    final keys = scope.split('.');
    var name = keys.removeLast();
    var owner = _getScope(this, keys.join('.'));
    // Follow the routes that give [node] to the parent scope.
    while (owner is OptionScope) {
      final route = owner.routeOf(name);
      if (route == null || identical(owner.ownCell(name)?.raw, map)) {
        break;
      }
      owner = route.targetScope;
      name = route.targetName;
    }
    final kind =
        (owner is OptionScope ? owner.childKindFor(name) : null) ??
        ScopeKind.genericElementOptions;
    final typed = kind.create();
    for (final key in jsObjectKeys(map)) {
      typed.jsWrite(key, map[key]);
    }
    if (owner is OptionScope) {
      if (identical(owner.ownCell(name)?.raw, map)) owner.jsWrite(name, typed);
    } else if (owner is AnyObject) {
      if (identical(jsGet(owner, name), map)) owner[name] = typed;
    }
    return typed;
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
  DescriptorsScope()
    ..descScriptable = _scriptableDefault
    ..descIndexable = _indexableDefault
    ..jsWrite('hover', DescriptorsScope()..descFallback = 'interaction')
    ..jsWrite(
      'interaction',
      DescriptorsScope()
        ..descScriptable = false
        ..descIndexable = false,
    ),
  [applyAnimationsDefaults, applyLayoutsDefaults, applyScaleDefaults],
);

/// core.defaults.js:166 the `_scriptable` descriptor of the root.
bool _scriptableDefault(String name) => !name.startsWith('on');

/// core.defaults.js:167 the `_indexable` descriptor of the root.
bool _indexableDefault(String name) => name != 'events';

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
/// An object source (a Map or a typed scope) gives its own keys in
/// [jsObjectKeys] order. A List or a String source gives its indices.
/// `null`, [undefined] and other values give nothing.
AnyObject _assign(AnyObject target, List<Object?> sources) {
  for (final source in sources) {
    if (source is AnyObject || source is JsObjectFace) {
      for (final key in jsObjectKeys(source)) {
        target[key] = jsGet(source, key);
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
