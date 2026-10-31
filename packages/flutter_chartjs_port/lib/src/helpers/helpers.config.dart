// Ported from Chart.js v4.6.1 src/helpers/helpers.config.ts (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-options, typed resolvers of Chart.js ADR 0054.

/// Port of `src/helpers/helpers.config.ts`: the option resolvers.
///
/// Upstream builds the resolvers as `Proxy` objects over a cache object.
/// Dart has no `Proxy`. Chart.js ADR 0054 §4 makes them typed classes:
/// [OptionResolver] (the target of `_createResolver`) and [OptionView] (the
/// target of `_attachContext`). Their fields are the slots of the upstream
/// cache object (`_scopes`, `_rootScopes`, `_fallback`, `_getTarget`,
/// `override`; `_proxy`, `_context`, `_subProxy`, `_stack`, `_descriptors`,
/// `setContext`), and the cached option values are a typed table by
/// `OptionKey` (a `String` for a name that is not a key of the schema). The
/// functions of this file are the upstream functions, in the upstream order,
/// over these typed targets. A scope list is a `List<Object?>` of typed
/// scopes (`OptionScope`), raw Maps and the other values that
/// `createSubResolver` adds; the walk reads a typed scope with
/// `OptionScope.lookup` and any other scope with [jsGet].
///
/// [Resolver] and [ContextResolver] are the names of the two classes for the
/// code of today. Both classes are a [JsProxyObject], the face by name of
/// Chart.js ADR 0054 §5; neither is a `Map`. They map the traps to these
/// members:
///
/// | Trap | Dart member |
/// |---|---|
/// | `get` | `operator []` and `jsRead`, and the typed read `readKey` |
/// | `set` | `operator []=` and `jsWrite` |
/// | `deleteProperty` | `jsDelete` |
/// | `has` (`in`) | `hasProperty` |
/// | `ownKeys` (`Object.getOwnPropertyNames`) | `ownKeys` |
/// | `getOwnPropertyDescriptor` | `hasOwnProperty`, `jsHas` |
/// | `getPrototypeOf` | none |
///
/// `Object.keys` of a resolver is its `objectKeys()`: `ownKeys` without
/// the keys that `hasOwnProperty` rejects, as the JavaScript engine filters
/// the `ownKeys` result through the `getOwnPropertyDescriptor` trap.
/// [jsObjectKeys] gives that result.
///
/// A write through a resolver (the `set` traps and `subGetTarget`) goes into
/// an object of the scopes: a typed scope classifies the value; a raw Map
/// takes the value only if its value type allows it. A nested Map literal
/// can have a narrow inferred type, for example `Map<String, int>` for
/// `{'a': 1}`. A write of a `String` into it throws a [TypeError].
/// JavaScript sets the property. A scope that takes writes has the runtime
/// type `Map<String, Object?>` or is a typed scope.
///
/// The three JS states of an option key stay apart (Chart.js ADR 0054 §1):
/// an absent key, the [undefined] sentinel and Dart `null` (JS `null`). The
/// resolution goes to the next scope on an absent key and on the sentinel.
/// `null` is a value. A resolver gives the [undefined] sentinel for a key
/// that it does not resolve. The cache keeps a resolved [undefined] as an
/// own key, as `_cached` does.
///
/// A scriptable option is a function value of `lib/src/js/js_function.dart`.
/// The resolver calls it through [jsCall] with the context and the
/// sub-resolver.
library;

import 'dart:core';
import 'dart:core' as core;

import 'package:flutter_chartjs_port/src/helpers/helpers.config.types.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show capitalize, isArray, isFunction, isObject, resolveObjectKey;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ContextObject;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/element_options_base.dart'
    show ElementOptions;
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart' show ParsedItem;
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:meta/meta.dart';

export 'package:flutter_chartjs_port/src/helpers/helpers.config.types.dart';

/// The name [Resolver] of the code of today for [OptionResolver].
typedef Resolver = OptionResolver;

/// The name [ContextResolver] of the code of today for [OptionView].
typedef ContextResolver = OptionView;

/// The type of [_absent].
final class _Absent {
  const _Absent();
}

/// The marker of a property that a target does not own.
const Object _absent = _Absent();

/// The key of the option name [name] in a cache: its [OptionKey], or [name]
/// for a name that is not a key of the schema.
Object _keyOf(String name) => optionKeyOf(name) ?? name;

/// The cached option values of a target, by key (an [OptionKey] or a
/// `String`), in the order of their first write: the typed form of the own
/// properties of the upstream cache object.
///
/// A table of a few keys is scanned: an [OptionKey] compares by identity.
/// The resolver of a scale or of the chart options caches dozens of keys,
/// and a scale reads some of them for each point (`startAngle` and
/// `reverse` of the radial scale in the filler of a radar). Thus a table of
/// more than [_scanMax] keys also has a hashed index of the positions, as
/// the properties of the upstream cache object have.
final class _Cache {
  List<Object>? _keys;
  List<Object?>? _values;

  /// The position of each key in [_keys], once the table has more than
  /// [_scanMax] keys. Dart `null` before.
  Map<Object, int>? _positions;

  /// The most keys that [_index] scans.
  static const int _scanMax = 8;

  int _index(Object key) {
    final positions = _positions;
    if (positions != null) return positions[key] ?? -1;
    final keys = _keys;
    if (keys == null) return -1;
    if (key is OptionKey) {
      for (var i = 0; i < keys.length; i++) {
        if (identical(keys[i], key)) return i;
      }
      return -1;
    }
    for (var i = 0; i < keys.length; i++) {
      final k = keys[i];
      if (identical(k, key) || k == key) return i;
    }
    return -1;
  }

  /// The value of [key], or [_absent].
  Object? get(Object key) {
    final index = _index(key);
    return index < 0 ? _absent : _values![index];
  }

  void set(Object key, Object? value) {
    final index = _index(key);
    if (index >= 0) {
      _values![index] = value;
      return;
    }
    final keys = (_keys ??= <Object>[])..add(key);
    (_values ??= <Object?>[]).add(value);
    final positions = _positions;
    if (positions != null) {
      positions[key] = keys.length - 1;
    } else if (keys.length > _scanMax) {
      _buildPositions();
    }
  }

  void remove(Object key) {
    final index = _index(key);
    if (index < 0) return;
    _keys!.removeAt(index);
    _values!.removeAt(index);
    if (_positions != null) _buildPositions();
  }

  /// Builds [_positions] from [_keys].
  void _buildPositions() {
    final keys = _keys!;
    _positions = {for (var i = 0; i < keys.length; i++) keys[i]: i};
  }

  /// The names of the cached keys, in their order.
  Iterable<String> get names => (_keys ?? const <Object>[]).map(
    (k) => k is OptionKey ? k.jsName : k as String,
  );
}

/// helpers.config.ts:27 `_createResolver`.
///
/// Creates a Proxy for resolving raw values for options.
/// @param scopes - The option scopes to look for values, in resolution order
/// @param prefixes - The prefixes for values, in resolution order.
/// @param rootScopes - The root option scopes
/// @param fallback - Parent scopes fallback
/// @param getTarget - callback for getting the target for changed values
/// @returns Proxy
/// @private
///
/// A null [rootScopes] or [getTarget] is an absent argument. Dart `null`
/// stands for JS `undefined` there: JS `null` never reaches them. The
/// default of [fallback] is the [undefined] sentinel, because a JS `null`
/// fallback is a value (`typeof fallback === 'undefined'` at :38).
OptionResolver createResolver(
  List<Object?> scopes, [
  List<String> prefixes = const [''],
  List<Object?>? rootScopes,
  Object? fallback = undefined,
  Object? Function()? getTarget,
]) {
  final target = getTarget ?? () => _first(scopes);
  final finalRootScopes = rootScopes ?? scopes;
  if (identical(fallback, undefined)) {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    fallback = _resolve('_fallback', scopes);
  }
  // Upstream also sets `[Symbol.toStringTag]: 'Object'`. A Dart Map is an
  // object for isObject without it.
  return OptionResolver._(scopes, prefixes, finalRootScopes, fallback, target);
}

/// The target of `_createResolver` (helpers.config.ts:41-49) and its
/// `Proxy` (helpers.config.ts:50-107), as one typed class (Chart.js ADR 0054
/// §4).
///
/// The slots of the cache object are fields. The cached option values are a
/// typed table. A write by the `set` trap or a delete by the
/// `deleteProperty` trap of a slot name changes the own property of that
/// name, as upstream does on its cache object. A [OptionResolver] gives the
/// [undefined] sentinel for a key that it does not resolve, and Dart `null`
/// for a JS `null` value.
final class OptionResolver implements ResolverProxy {
  OptionResolver._(
    this._scopes,
    this._prefixes,
    this._rootScopes,
    this._fallback,
    this._getTarget,
  );

  /// The `scopes` parameter of `_createResolver`: `_scopes` of the target.
  final List<Object?> _scopes;

  /// The `prefixes` parameter of `_createResolver`.
  final List<String> _prefixes;

  /// `_rootScopes` of the target.
  final List<Object?> _rootScopes;

  /// `_fallback` of the target.
  final Object? _fallback;

  /// The `getTarget` parameter of `_createResolver`: `_getTarget` of the
  /// target.
  final Object? Function() _getTarget;

  /// `override` of the target (helpers.config.ts:48).
  // One function value for each target, as the upstream cache object
  // holds one.
  // ignore: prefer_function_declarations_over_variables
  late final OptionResolver Function(Object scope) _override = (scope) =>
      createResolver(
        [scope, ..._scopes],
        _prefixes,
        _rootScopes,
        _fallback,
      );

  /// The cached option values, and the own properties of the slot names
  /// that the `set` trap writes.
  final _Cache _cache = _Cache();

  /// `_keys` of the target (helpers.config.ts:419-425), or Dart `null`.
  List<String>? _keys;

  /// `_storage` of the target (helpers.config.ts:103), or [_absent].
  Object? _storage = _absent;

  /// The slot names that the `deleteProperty` trap removed. Dart `null`
  /// before the first such delete.
  Set<String>? _deletedSlots;

  /// Whether a `set` or a `delete` touched a slot name: then each read of a
  /// slot goes through [_own].
  bool _slotsTouched = false;

  /// The own property [name] of the target, or [_absent]: a cached or set
  /// value, else a slot (helpers.config.ts:41-49, `_keys`, `_storage`).
  Object? _own(String name) {
    final cached = _cache.get(_keyOf(name));
    if (!identical(cached, _absent)) return cached;
    if (_deletedSlots?.contains(name) ?? false) return _absent;
    return switch (name) {
      '_cacheable' => true,
      '_scopes' => _scopes,
      '_rootScopes' => _rootScopes,
      '_fallback' => _fallback,
      '_getTarget' => _getTarget,
      'override' => _override,
      '_keys' => _keys ?? _absent,
      '_storage' => _storage,
      _ => _absent,
    };
  }

  /// `target._scopes`, read as `jsGet(target, '_scopes')` upstream.
  Object? get _targetScopes =>
      _slotsTouched ? _ownOrUndefined('_scopes') : _scopes;

  /// `target._rootScopes`.
  Object? get _targetRootScopes =>
      _slotsTouched ? _ownOrUndefined('_rootScopes') : _rootScopes;

  /// `target._fallback`.
  Object? get _targetFallback =>
      _slotsTouched ? _ownOrUndefined('_fallback') : _fallback;

  /// `target._getTarget`.
  Object? get _targetGetTarget =>
      _slotsTouched ? _ownOrUndefined('_getTarget') : _getTarget;

  /// [_own], with [undefined] for a property that the target does not own:
  /// the result of `jsGet(target, name)`.
  Object? _ownOrUndefined(String name) {
    final value = _own(name);
    return identical(value, _absent) ? undefined : value;
  }

  /// helpers.config.ts:64 the `get` trap for the option name [prop]:
  /// `_cached(target, prop, () => _resolveWithPrefixes(...))`.
  Object? _get(String prop) {
    // DIVERGES(chartjs): adapt-resolver-cached-read, _cached inline.
    final own = _own(prop);
    if (!identical(own, _absent)) return own;
    if (prop == 'constructor') {
      // DIVERGES(chartjs): js-semantics-resolver-objects, no constructor.
      return undefined;
    }
    final value = _resolveWithPrefixes(prop, _prefixes, _scopes, this);
    // cache the resolved value
    _cache.set(_keyOf(prop), value);
    return value;
  }

  /// The `get` trap for the key [key]: the typed read of the element step
  /// (Chart.js ADR 0054 §4). It gives the result of `this[key.jsName]`.
  Object? readKey(OptionKey key) {
    final cached = _cache.get(key);
    if (!identical(cached, _absent)) return cached;
    final name = key.jsName;
    if (name.startsWith('_') || _slotsTouched) return _get(name);
    final value = _resolveWithPrefixes(name, _prefixes, _scopes, this);
    _cache.set(key, value);
    return value;
  }

  /// helpers.config.ts:54 the `deleteProperty` trap.
  ///
  /// A trap for the delete operator.
  void _deleteTrap(String key) {
    // remove from cache
    _removeOwn(key);
    // remove cached keys
    _removeOwn('_keys');
    _deleteProperty(_first(_scopes), key); // remove from top level scope
  }

  /// `delete target[name]` of the cache object.
  void _removeOwn(String name) {
    _cache.remove(_keyOf(name));
    switch (name) {
      case '_keys':
        _keys = null;
      case '_storage':
        _storage = _absent;
      case '_cacheable' ||
          '_scopes' ||
          '_rootScopes' ||
          '_fallback' ||
          '_getTarget' ||
          'override':
        (_deletedSlots ??= <String>{}).add(name);
        _slotsTouched = true;
    }
  }

  /// helpers.config.ts:64 the `get` trap.
  ///
  /// A trap for getting property values.
  @core.override
  Object? operator [](String name) => _get(name);

  /// helpers.config.ts:73 the `getOwnPropertyDescriptor` trap: whether the
  /// first scope owns [key].
  ///
  /// A trap for Object.getOwnPropertyDescriptor.
  /// Also used by Object.hasOwnProperty.
  ///
  /// The trap returns the descriptor of the first scope. Ported code reads
  /// only whether it exists: `Object.prototype.hasOwnProperty.call(resolver,
  /// key)` is `resolver.hasOwnProperty(key)`.
  bool hasOwnProperty(String key) {
    return _getOwnProperty(jsGet(_targetScopes, '0'), key);
  }

  // helpers.config.ts:80 the `getPrototypeOf` trap has no Dart form.
  // DIVERGES(chartjs): js-semantics-resolver-objects, no getPrototypeOf trap.

  /// helpers.config.ts:87 the `has` trap.
  ///
  /// A trap for the in operator.
  @core.override
  bool hasProperty(String name) {
    return _getKeysFromAllScopes(this).contains(name);
  }

  /// helpers.config.ts:94 the `ownKeys` trap.
  ///
  /// A trap for Object.getOwnPropertyNames and Object.getOwnPropertySymbols.
  @core.override
  List<String> ownKeys() => _getKeysFromAllScopes(this);

  /// `Object.keys(resolver)`: the `ownKeys` result filtered through the
  /// `getOwnPropertyDescriptor` trap ([hasOwnProperty]), in the trap order.
  @core.override
  List<String> objectKeys() => [
    for (final key in ownKeys())
      if (hasOwnProperty(key)) key,
  ];

  // The face of Chart.js ADR 0054 §5: the traps by name.

  /// `resolver[name]`: the `get` trap ([operator []]).
  @core.override
  Object? jsRead(String name) => _get(name);

  /// `resolver[name] = value`: the `set` trap ([operator []=]).
  @core.override
  void jsWrite(String name, Object? value) => this[name] = value;

  /// `Object.keys(resolver)` ([objectKeys]).
  @core.override
  List<String> jsKeys() => objectKeys();

  /// `Object.prototype.hasOwnProperty.call(resolver, name)`
  /// ([hasOwnProperty]).
  @core.override
  bool jsHas(String name) => hasOwnProperty(name);

  /// `delete resolver[name]`: the `deleteProperty` trap. It returns
  /// whether the resolver owned [name] before.
  @core.override
  bool jsDelete(String name) {
    final owned = hasOwnProperty(name);
    _deleteTrap(name);
    return owned;
  }

  /// helpers.config.ts:101 the `set` trap.
  ///
  /// A trap for setting property values.
  @core.override
  void operator []=(String key, Object? value) {
    final current = _ownOrUndefined('_storage');
    final Object? storage;
    if (jsTruthy(current)) {
      storage = current;
    } else {
      storage = _storage = _getTarget();
      _cache.remove(_keyOf('_storage'));
    }
    // set to top level scope + cache
    _set(storage, key, value);
    _cache.set(_keyOf(key), value);
    if (key.startsWith('_') || key == 'override') {
      _deletedSlots?.remove(key);
      _slotsTouched = true;
    }
    _removeOwn('_keys'); // remove cached keys
  }

  /// helpers.config.types.ts:11 `_cacheable`: `true`.
  @internal
  @core.override
  bool get cacheable => jsTruthy(this['_cacheable']);

  /// helpers.config.types.ts:12 `_scopes`.
  @internal
  @core.override
  List<Object?> get scopes => this['_scopes']! as List<Object?>;

  /// helpers.config.types.ts:13 `_rootScopes`.
  @internal
  @core.override
  List<Object?> get rootScopes => this['_rootScopes']! as List<Object?>;

  /// helpers.config.types.ts:14 `_fallback`.
  @internal
  @core.override
  ResolverObjectKey get fallback => this['_fallback'];

  /// helpers.config.types.ts:20 `_getTarget()`.
  @internal
  @core.override
  Object? Function() get getTarget =>
      () => (this['_getTarget']! as Object? Function())();

  /// helpers.config.ts:48 `override(scope)`: a resolver with [scope] in
  /// front of the scopes.
  @core.override
  OptionResolver override(Object scope) {
    return (this['override']! as OptionResolver Function(Object))(scope);
  }

  /// The names of the own properties of the cache object, in their order.
  Iterable<String> get _targetNames sync* {
    final deleted = _deletedSlots;
    for (final name in const [
      '_cacheable',
      '_scopes',
      '_rootScopes',
      '_fallback',
      '_getTarget',
      'override',
    ]) {
      if (deleted == null || !deleted.contains(name)) yield name;
    }
    if (_keys != null) yield '_keys';
    if (!identical(_storage, _absent)) yield '_storage';
    yield* _cache.names;
  }

  /// A description that resolves no option. Upstream has no counterpart.
  /// `String(resolver)` is `jsToString`, which gives `'[object Object]'`.
  @core.override
  String toString() => 'Resolver(cache: ${_targetNames.join(', ')})';
}

/// The typed read `options[key.jsName]` of an options object of another
/// module (Chart.js ADR 0054 §4): `readKey` of an [OptionView] or an
/// [OptionResolver], else the JS property read [jsGet]. The chart options,
/// the scale options, the plugin options and the dataset options are
/// views; a test can give a raw Map. The style object of a controller is a
/// typed [ElementOptions]: its [ElementOptions.valueOf]. Upstream reads the
/// property by name. Port-only.
Object? readOption(Object? options, OptionKey key) => switch (options) {
  final OptionView view => view.readKey(key),
  final OptionResolver resolver => resolver.readKey(key),
  final ElementOptions elementOptions => elementOptions.valueOf(key),
  _ => jsGet(options, key.jsName),
};

/// helpers.config.ts:118 `_attachContext`.
///
/// Returns an Proxy for resolving option values with context.
/// @param proxy - The Proxy returned by `_createResolver`
/// @param context - Context object for scriptable/indexable options
/// @param subProxy - The proxy provided for scriptable options
/// @param descriptorDefaults - Defaults for descriptors
/// @private
///
/// [proxy] is `Object?`. `_resolveArray` can give it the `false` of
/// `createSubResolver`, and `_resolveWithContext` a value that a caller has
/// set. The default of [subProxy] is the [undefined] sentinel. A null
/// [descriptorDefaults] is an absent argument: JS `null` never reaches it.
OptionView attachContext(
  Object? proxy,
  Object context, [
  Object? subProxy = undefined,
  DescriptorDefaults? descriptorDefaults,
]) {
  return OptionView._(
    proxy,
    context,
    subProxy,
    descriptors(proxy, descriptorDefaults),
    descriptorDefaults,
  );
}

/// The target of `_attachContext` (helpers.config.ts:127-136) and its
/// `Proxy` (helpers.config.ts:137-194), as one typed class (Chart.js ADR
/// 0054 §4).
///
/// The slots of the cache object are fields. The cached option values are a
/// typed table. The library documentation lists the trap of each member.
final class OptionView implements ContextProxy {
  OptionView._(
    this._proxy,
    this._context,
    this._subProxy,
    this._descriptors,
    this._descriptorDefaults,
  );

  /// The `proxy` parameter of `_attachContext`: `_proxy` of the target.
  final Object? _proxy;

  /// `_context` of the target.
  final Object _context;

  /// `_subProxy` of the target.
  final Object? _subProxy;

  /// `_stack` of the target.
  final Set<String> _stack = <String>{};

  /// `_descriptors` of the target.
  final Descriptor _descriptors;

  /// The `descriptorDefaults` parameter of `_attachContext`.
  final DescriptorDefaults? _descriptorDefaults;

  /// `setContext` of the target (helpers.config.ts:134).
  // One function value for each target, as the upstream cache object
  // holds one.
  // ignore: prefer_function_declarations_over_variables
  late final OptionView Function(Object ctx) _setContext = (ctx) =>
      attachContext(_proxy, ctx, _subProxy, _descriptorDefaults);

  /// `override` of the target (helpers.config.ts:135).
  // One function value for each target, as the upstream cache object
  // holds one.
  // ignore: prefer_function_declarations_over_variables
  late final OptionView Function(Object scope) _override = (scope) =>
      attachContext(
        jsCall(jsGet(_proxy, 'override'), [scope], thisArg: _proxy),
        _context,
        _subProxy,
        _descriptorDefaults,
      );

  /// The cached option values.
  final _Cache _cache = _Cache();

  /// The slot names that the `set` or `deleteProperty` trap removed from
  /// the cache object. Dart `null` before the first one.
  Set<String>? _removedSlots;

  /// The own property [name] of the target, or [_absent].
  Object? _own(String name) {
    final cached = _cache.get(_keyOf(name));
    if (!identical(cached, _absent)) return cached;
    if (_removedSlots?.contains(name) ?? false) return _absent;
    return switch (name) {
      '_cacheable' => false,
      '_proxy' => _proxy,
      '_context' => _context,
      '_subProxy' => _subProxy,
      '_stack' => _stack,
      '_descriptors' => _descriptors,
      'setContext' => _setContext,
      'override' => _override,
      _ => _absent,
    };
  }

  /// `jsGet(target, name)` of a slot name.
  Object? _slot(String name) {
    if (_removedSlots == null) {
      return switch (name) {
        '_proxy' => _proxy,
        '_context' => _context,
        '_subProxy' => _subProxy,
        '_stack' => _stack,
        '_descriptors' => _descriptors,
        _ => _own(name),
      };
    }
    final value = _own(name);
    return identical(value, _absent) ? undefined : value;
  }

  /// helpers.config.ts:150 the `get` trap for the option name [prop]. The
  /// receiver is this view.
  Object? _get(String prop) {
    // DIVERGES(chartjs): adapt-resolver-cached-read, _cached inline.
    final own = _own(prop);
    if (!identical(own, _absent)) return own;
    if (prop == 'constructor') {
      // DIVERGES(chartjs): js-semantics-resolver-objects, no constructor.
      return undefined;
    }
    final value = _resolveWithContext(this, prop, null);
    // cache the resolved value
    _cache.set(_keyOf(prop), value);
    return value;
  }

  /// The `get` trap for the key [key]: the typed read of the element step
  /// (Chart.js ADR 0054 §4). It gives the result of `this[key.jsName]`.
  Object? readKey(OptionKey key) {
    final cached = _cache.get(key);
    if (!identical(cached, _absent)) return cached;
    final name = key.jsName;
    if (name.startsWith('_')) return _get(name);
    final value = _resolveWithContext(this, name, key);
    _cache.set(key, value);
    return value;
  }

  /// helpers.config.ts:141 the `deleteProperty` trap.
  ///
  /// A trap for the delete operator.
  void _deleteTrap(String key) {
    _removeOwn(key); // remove from cache
    _deleteProperty(_proxy, key); // remove from proxy
  }

  /// `delete target[name]` of the cache object.
  void _removeOwn(String name) {
    _cache.remove(_keyOf(name));
    switch (name) {
      case '_cacheable' ||
          '_proxy' ||
          '_context' ||
          '_subProxy' ||
          '_stack' ||
          '_descriptors' ||
          'setContext' ||
          'override':
        (_removedSlots ??= <String>{}).add(name);
    }
  }

  /// helpers.config.ts:150 the `get` trap. The receiver is this resolver.
  ///
  /// A trap for getting property values.
  @core.override
  Object? operator [](String name) => _get(name);

  /// helpers.config.ts:159 the `getOwnPropertyDescriptor` trap: whether a
  /// descriptor exists for [key].
  ///
  /// A trap for Object.getOwnPropertyDescriptor.
  /// Also used by Object.hasOwnProperty.
  bool hasOwnProperty(String key) {
    final descriptors = _slot('_descriptors')! as Descriptor;
    return jsTruthy(descriptors.allKeys)
        ? _has(_proxy, key)
        : _getOwnProperty(_proxy, key);
  }

  // helpers.config.ts:168 the `getPrototypeOf` trap has no Dart form.
  // DIVERGES(chartjs): js-semantics-resolver-objects, no getPrototypeOf trap.

  /// helpers.config.ts:175 the `has` trap.
  ///
  /// A trap for the in operator.
  @core.override
  bool hasProperty(String name) {
    return _has(_proxy, name);
  }

  /// helpers.config.ts:182 the `ownKeys` trap.
  ///
  /// A trap for Object.getOwnPropertyNames and Object.getOwnPropertySymbols.
  @core.override
  List<String> ownKeys() => _reflectOwnKeys(_proxy);

  /// `Object.keys(resolver)`: the `ownKeys` result filtered through the
  /// `getOwnPropertyDescriptor` trap ([hasOwnProperty]), in the trap order.
  @core.override
  List<String> objectKeys() => [
    for (final key in ownKeys())
      if (hasOwnProperty(key)) key,
  ];

  // The face of Chart.js ADR 0054 §5: the traps by name.

  /// `resolver[name]`: the `get` trap ([operator []]).
  @core.override
  Object? jsRead(String name) => _get(name);

  /// `resolver[name] = value`: the `set` trap ([operator []=]).
  @core.override
  void jsWrite(String name, Object? value) => this[name] = value;

  /// `Object.keys(resolver)` ([objectKeys]).
  @core.override
  List<String> jsKeys() => objectKeys();

  /// `Object.prototype.hasOwnProperty.call(resolver, name)`
  /// ([hasOwnProperty]).
  @core.override
  bool jsHas(String name) => hasOwnProperty(name);

  /// `delete resolver[name]`: the `deleteProperty` trap. It returns
  /// whether the resolver owned [name] before.
  @core.override
  bool jsDelete(String name) {
    final owned = hasOwnProperty(name);
    _deleteTrap(name);
    return owned;
  }

  /// helpers.config.ts:189 the `set` trap.
  ///
  /// A trap for setting property values.
  @core.override
  void operator []=(String key, Object? value) {
    _set(_proxy, key, value); // set to proxy
    _removeOwn(key); // remove from cache
  }

  /// helpers.config.types.ts:47 `_cacheable`: `false`.
  @internal
  @core.override
  bool get cacheable => jsTruthy(this['_cacheable']);

  /// helpers.config.types.ts:48 `_proxy`.
  @internal
  @core.override
  Object? get proxy => this['_proxy'];

  /// helpers.config.types.ts:49 `_context`.
  @internal
  @core.override
  Object get context => this['_context']!;

  /// helpers.config.types.ts:50 `_subProxy`.
  @internal
  @core.override
  Object? get subProxy => this['_subProxy'];

  /// helpers.config.types.ts:51 `_stack`.
  @internal
  @core.override
  Set<String> get stack => this['_stack']! as Set<String>;

  /// helpers.config.types.ts:52 `_descriptors`.
  @internal
  @core.override
  Descriptor get descriptors => this['_descriptors']! as Descriptor;

  /// helpers.config.ts:134 `setContext(ctx)`: a resolver over the same
  /// proxy with the context [ctx].
  @core.override
  OptionView setContext(Object ctx) {
    return (this['setContext']! as OptionView Function(Object))(ctx);
  }

  /// helpers.config.ts:135 `override(scope)`: a resolver with [scope] in
  /// front of the scopes.
  @core.override
  OptionView override(Object scope) {
    return (this['override']! as OptionView Function(Object))(scope);
  }

  /// The names of the own properties of the cache object, in their order.
  Iterable<String> get _targetNames sync* {
    final removed = _removedSlots;
    for (final name in const [
      '_cacheable',
      '_proxy',
      '_context',
      '_subProxy',
      '_stack',
      '_descriptors',
      'setContext',
      'override',
    ]) {
      if (removed == null || !removed.contains(name)) yield name;
    }
    yield* _cache.names;
  }

  /// A description that resolves no option. Upstream has no counterpart.
  /// `String(resolver)` is `jsToString`, which gives `'[object Object]'`.
  @core.override
  String toString() => 'ContextResolver(cache: ${_targetNames.join(', ')})';
}

/// helpers.config.ts:200 `_descriptors`.
/// @private
///
/// The destructuring defaults of upstream apply to the [undefined]
/// sentinel. Dart `null` (JS `null`) is a value. A null [defaults] is an
/// absent argument: JS `null` never reaches it.
Descriptor descriptors(Object? proxy, [DescriptorDefaults? defaults]) {
  final descriptorDefaults =
      defaults ?? const DescriptorDefaults(scriptable: true, indexable: true);
  var scriptable = jsGet(proxy, '_scriptable');
  if (identical(scriptable, undefined)) {
    scriptable = descriptorDefaults.scriptable;
  }
  var indexable = jsGet(proxy, '_indexable');
  if (identical(indexable, undefined)) {
    indexable = descriptorDefaults.indexable;
  }
  var allKeys = jsGet(proxy, '_allKeys');
  if (identical(allKeys, undefined)) {
    allKeys = descriptorDefaults.allKeys;
  }
  return _Descriptor(
    allKeys: allKeys,
    scriptable: scriptable,
    indexable: indexable,
  );
}

/// The object literal that `_descriptors` returns (helpers.config.ts:205).
///
/// `isScriptable` and `isIndexable` call a function value through [jsCall1]
/// with no `this`, as the detached calls of upstream do
/// (`core.config.js:409-410` and helpers.config.ts:283). The method call at
/// :242 is `_isScriptableMethod`. They return the ToBoolean of the result
/// ([jsTruthy]), because every caller tests only its truth.
final class _Descriptor implements Descriptor {
  _Descriptor({
    required this.allKeys,
    required this.scriptable,
    required this.indexable,
  });

  /// helpers.config.ts:206 `allKeys`.
  @override
  final Object? allKeys;

  /// helpers.config.ts:207 `scriptable`.
  @override
  final Object? scriptable;

  /// helpers.config.ts:208 `indexable`.
  @override
  final Object? indexable;

  /// helpers.config.ts:209 `isScriptable`.
  @override
  bool isScriptable(String key) => jsTruthy(
    isFunction(scriptable) ? jsCall1(scriptable, key) : scriptable,
  );

  /// helpers.config.ts:210 `isIndexable`.
  @override
  bool isIndexable(String key) =>
      jsTruthy(isFunction(indexable) ? jsCall1(indexable, key) : indexable);
}

/// helpers.config.ts:214 `readKey`.
String _readKey(String prefix, String name) =>
    prefix.isNotEmpty ? prefix + capitalize(name) : name;

/// helpers.config.ts:215 `needsSubResolver`.
///
/// Upstream also requires `Object.getPrototypeOf(value) === null ||
/// value.constructor === Object`. [isObject] is true only for a Map and a
/// typed scope, and both stand for a plain object (Chart.js ADR 0054 §5). A
/// resolver is a Map too: upstream finds `Object` as its constructor
/// through `_cached`.
bool _needsSubResolver(String prop, Object? value) =>
    isObject(value) && prop != 'adapters';

/// helpers.config.ts:233 `_resolveWithContext`. The receiver is [view].
/// [key] is the [OptionKey] of [prop] for the typed read of the proxy, or
/// Dart `null`.
Object? _resolveWithContext(OptionView view, String prop, OptionKey? key) {
  final proxy = view._slot('_proxy');
  final context = view._slot('_context');
  final subProxy = view._slot('_subProxy');
  final descriptors = view._slot('_descriptors')! as Descriptor;
  // resolve from proxy
  var value = key != null && proxy is OptionResolver
      ? proxy.readKey(key)
      : jsGet(proxy, prop);

  // resolve with context
  if (isFunction(value) && _isScriptableMethod(descriptors, prop)) {
    value = _resolveScriptable(prop, value, view, view);
  }
  if (isArray(value) && (value! as List<Object?>).isNotEmpty) {
    value = _resolveArray(
      prop,
      value as List<Object?>,
      view,
      descriptors.isIndexable,
    );
  }
  if (_needsSubResolver(prop, value)) {
    // if the resolved value is an object, create a sub resolver for it
    value = attachContext(
      value,
      context!,
      jsTruthy(subProxy) ? jsGet(subProxy, prop) : subProxy,
      descriptors,
    );
  }
  return value;
}

/// `descriptors.isScriptable(prop)` at helpers.config.ts:242: a method call.
///
/// A function `_scriptable` gets [descriptors] as `this`, as upstream gives
/// the descriptor object. The result is the ToBoolean of its result.
bool _isScriptableMethod(Descriptor descriptors, String prop) {
  final scriptable = descriptors.scriptable;
  return jsTruthy(
    isFunction(scriptable)
        ? jsCall1(scriptable, prop, thisArg: descriptors)
        : scriptable,
  );
}

/// helpers.config.ts:255 `_resolveScriptable`.
///
/// [getValue] is a function value. It gets the context and the
/// sub-resolver, or the [receiver], through [jsCall]. Upstream throws an
/// `Error` on recursion. The port throws a [StateError] with the same
/// message.
Object? _resolveScriptable(
  String prop,
  Object? getValue,
  OptionView target,
  OptionView receiver,
) {
  final proxy = target._slot('_proxy');
  final context = target._slot('_context');
  final subProxy = target._slot('_subProxy');
  final stack = target._slot('_stack')! as Set<String>;
  if (stack.contains(prop)) {
    throw StateError('Recursion detected: ${stack.join('->')}->$prop');
  }
  stack.add(prop);
  var value = jsCall(getValue, [
    context,
    if (jsTruthy(subProxy)) subProxy else receiver,
  ]);
  stack.remove(prop);
  if (_needsSubResolver(prop, value)) {
    // When scriptable option returns an object, create a resolver on that.
    value = _createSubResolver(
      jsGet(proxy, '_scopes')! as List<Object?>,
      proxy,
      prop,
      value,
    );
  }
  return value;
}

/// helpers.config.ts:275 `_resolveArray`.
///
/// `value[_context.index % value.length]` is a property read with the
/// ToString of the remainder. Thus an index that is not an integer from 0
/// gives the [undefined] sentinel, as in JavaScript.
Object? _resolveArray(
  String prop,
  List<Object?> value,
  OptionView target,
  bool Function(String key) isIndexable,
) {
  final proxy = target._slot('_proxy');
  final context = target._slot('_context');
  final subProxy = target._slot('_subProxy');
  final descriptors = target._slot('_descriptors')! as Descriptor;

  final index = jsGet(context, 'index');
  if (!identical(index, undefined) && isIndexable(prop)) {
    final remainder = jsToNumber(index).remainder(value.length);
    return jsGet(value, jsNumberToString(remainder));
  } else if (isObject(value[0])) {
    // Array of objects, return array or resolvers
    final arr = value;
    final scopes = (jsGet(proxy, '_scopes')! as List<Object?>)
        .where((s) => !identical(s, arr))
        .toList();
    final resolvers = <Object?>[];
    for (final item in arr) {
      final resolver = _createSubResolver(scopes, proxy, prop, item);
      resolvers.add(
        attachContext(
          resolver,
          context!,
          jsTruthy(subProxy) ? jsGet(subProxy, prop) : subProxy,
          descriptors,
        ),
      );
    }
    return resolvers;
  }
  return value;
}

/// helpers.config.ts:298 `resolveFallback`.
ResolverObjectKey _resolveFallback(
  Object? fallback,
  ResolverObjectKey prop,
  Object? value,
) {
  return isFunction(fallback) ? jsCall(fallback, [prop, value]) : fallback;
}

/// helpers.config.ts:306 `getScope`.
Object? _getScope(ResolverObjectKey key, Object? parent) => key == true
    ? parent
    : key is String
    ? resolveObjectKey(parent, key)
    : undefined;

/// helpers.config.ts:309 `addScopes`.
///
/// `===` and `!==` are `==` and `!=`: the keys are strings and booleans.
ResolverObjectKey _addScopes(
  Set<Object?> set,
  List<Object?> parentScopes,
  ResolverObjectKey key,
  ResolverObjectKey parentFallback,
  Object? value,
) {
  for (final parent in parentScopes) {
    final scope = _getScope(key, parent);
    if (jsTruthy(scope)) {
      set.add(scope);
      final fallback = _resolveFallback(jsGet(scope, '_fallback'), key, value);
      if (!identical(fallback, undefined) &&
          fallback != key &&
          fallback != parentFallback) {
        // When we reach the descriptor that defines a new _fallback, return
        // that. The fallback will resume to that new scope.
        return fallback;
      }
    } else if (scope == false &&
        !identical(parentFallback, undefined) &&
        key != parentFallback) {
      // Fallback to `false` results to `false`, when falling back to
      // different key. For example `interaction` from `hover` or
      // `plugins.tooltip` and `animation` from `animations`
      return null;
    }
  }
  return false;
}

/// The own property [name] of the target of the resolver [resolver]: a
/// field of an [OptionResolver], else the result of [jsGet] (the target of
/// upstream is the cache object, helpers.config.ts:66).
Object? _targetGet(Object? resolver, String name) {
  if (resolver is OptionResolver) {
    return switch (name) {
      '_rootScopes' => resolver._targetRootScopes,
      '_fallback' => resolver._targetFallback,
      '_getTarget' => resolver._targetGetTarget,
      '_scopes' => resolver._targetScopes,
      _ => resolver._ownOrUndefined(name),
    };
  }
  return jsGet(resolver, name);
}

/// helpers.config.ts:335 `createSubResolver`.
///
/// It returns an [OptionResolver], or `false`.
Object _createSubResolver(
  List<Object?> parentScopes,
  Object? resolver,
  String prop,
  Object? value,
) {
  final rootScopes = _targetGet(resolver, '_rootScopes')! as List<Object?>;
  final fallback = _resolveFallback(
    _targetGet(resolver, '_fallback'),
    prop,
    value,
  );
  final allScopes = [...parentScopes, ...rootScopes];
  final set = <Object?>{value};
  var key = _addScopesFromKey(
    set,
    allScopes,
    prop,
    jsTruthy(fallback) ? fallback : prop,
    value,
  );
  if (key == null) {
    return false;
  }
  if (!identical(fallback, undefined) && fallback != prop) {
    key = _addScopesFromKey(set, allScopes, fallback, key, value);
    if (key == null) {
      return false;
    }
  }
  return createResolver(
    set.toList(),
    [''],
    rootScopes,
    fallback,
    () => _subGetTarget(resolver, prop, value),
  );
}

/// helpers.config.ts:360 `addScopesFromKey`.
ResolverObjectKey _addScopesFromKey(
  Set<Object?> set,
  List<Object?> allScopes,
  ResolverObjectKey key,
  ResolverObjectKey fallback,
  Object? item,
) {
  var scopeKey = key;
  while (jsTruthy(scopeKey)) {
    scopeKey = _addScopes(set, allScopes, scopeKey, fallback, item);
  }
  return scopeKey;
}

/// helpers.config.ts:373 `subGetTarget`.
///
/// A new nested object of a typed scope is a typed scope of the kind of
/// [prop] (Chart.js ADR 0054 §3); another one is the `{}` of upstream.
Object? _subGetTarget(Object? resolver, String prop, Object? value) {
  // The port's own `_getTarget` closure reads neither `this` nor arguments.
  final parent = (_targetGet(resolver, '_getTarget')! as Object? Function())();
  if (!_has(parent, prop)) {
    _set(parent, prop, _newObject(parent, prop));
  }
  final target = jsGet(parent, prop);
  if (isArray(target) && isObject(value)) {
    // For array of objects, the object is used to store updated values
    return value;
  }
  return jsTruthy(target) ? target : <String, Object?>{};
}

/// A new empty object under [prop] of [parent]: a typed scope of the kind
/// of [prop] for a typed [parent] with one, else a raw Map.
Object _newObject(Object? parent, String prop) =>
    (parent is OptionScope ? parent.childKindFor(prop)?.create() : null) ??
    <String, Object?>{};

/// helpers.config.ts:390 `_resolveWithPrefixes`.
Object? _resolveWithPrefixes(
  String prop,
  List<String> prefixes,
  List<Object?> scopes,
  Object? proxy,
) {
  Object? value;
  for (final prefix in prefixes) {
    value = _resolve(_readKey(prefix, prop), scopes);
    if (!identical(value, undefined)) {
      return _needsSubResolver(prop, value)
          ? _createSubResolver(scopes, proxy, prop, value)
          : value;
    }
  }
  return undefined;
}

/// helpers.config.ts:407 `_resolve`.
///
/// An absent key and the [undefined] sentinel go to the next scope. Dart
/// `null` (JS `null`) is the result. A typed scope is read by the typed
/// lookup of its kind (Chart.js ADR 0054 §4); any other scope with [jsGet].
Object? _resolve(String key, List<Object?> scopes) {
  Object? scopeKey;
  for (final scope in scopes) {
    if (!jsTruthy(scope)) {
      continue;
    }
    final Object? value;
    if (scope is OptionScope) {
      final cell = scope.lookup(scopeKey ??= _keyOf(key));
      value = cell == null ? undefined : cell.raw;
    } else {
      value = jsGet(scope, key);
    }
    if (!identical(value, undefined)) {
      return value;
    }
  }
  return undefined;
}

/// helpers.config.ts:419 `getKeysFromAllScopes`.
List<String> _getKeysFromAllScopes(OptionResolver target) {
  var keys = target._ownOrUndefined('_keys');
  if (!jsTruthy(keys)) {
    keys = target._keys = _resolveKeysFromAllScopes(
      target._targetScopes! as List<Object?>,
    );
  }
  return keys! as List<String>;
}

/// helpers.config.ts:427 `resolveKeysFromAllScopes`.
///
/// `Object.keys` of a scope is `_objectKeys`. A key that a scope owns with
/// the [undefined] sentinel or Dart `null` is a key.
List<String> _resolveKeysFromAllScopes(List<Object?> scopes) {
  final set = <String>{};
  for (final scope in scopes) {
    set.addAll(_objectKeys(scope).where((k) => !k.startsWith('_')));
  }
  return set.toList();
}

/// helpers.config.ts:437 `_parseObjectDataRadialScale`.
///
/// The function reads `this`, the dataset controller that
/// `controller.polarArea.js:110` binds. Thus it is a [JsFunction]
/// (`lib/src/js/js_function.dart`). Its closure takes `this` (a
/// [DatasetController]), `meta` (a [ChartMeta]), `data` (a `List<Object?>`),
/// `start` and `count` (`double`s). Call it with [jsCall] and the controller
/// as `thisArg`. It returns a `List<ParsedItem>`: each item is the object
/// `{r}` of upstream, a typed parsed item (Chart.js ADR 0054 §8) with the
/// one key `r`.
const JsFunction parseObjectDataRadialScale = JsFunction(
  _parseObjectDataRadialScale,
);

/// The closure of [parseObjectDataRadialScale]: the typed body with the
/// reads of `this` and `meta`, in the upstream order.
List<ParsedItem> _parseObjectDataRadialScale(
  DatasetController self,
  ChartMeta meta,
  List<Object?> data,
  double start,
  double count,
) => parseObjectDataRadialScaleOf(
  meta.iScale,
  self.parsing,
  data,
  start,
  count,
);

/// helpers.config.ts:437 `_parseObjectDataRadialScale`, the typed body for
/// the radar and polar area controllers: no [jsCall].
///
/// [iScale] is `meta.iScale` and [parsing] is `this._parsing` of the
/// controller, the two values that upstream reads from `meta` and `this`. A
/// caller reads them in that order, as the argument order is. The result
/// is the one of [parseObjectDataRadialScale].
@internal
List<ParsedItem> parseObjectDataRadialScaleOf(
  Scale? iScale,
  Object? parsing,
  List<Object?> data,
  double start,
  double count,
) {
  final parsingKey = jsGet(parsing, 'key');
  final key = identical(parsingKey, undefined) ? 'r' : parsingKey;
  final parsed = <ParsedItem>[];

  for (var i = 0.0, ilen = count; i < ilen; ++i) {
    final index = i + start;
    final item = jsGetIndex(data, index);
    parsed.add(
      ParsedItem()
        ..r = iScale!.parse(resolveObjectKey(item, key! as String), index),
    );
  }
  return parsed;
}

// The JavaScript object operations of the traps, for the Dart values of
// Chart.js ADR 0054 §5: a raw Map, a typed object with a face, a List, a
// function value. Upstream has no counterpart: the JavaScript engine does
// them.

/// The first scope, `scopes[0]`: the [undefined] sentinel for an empty
/// list.
Object? _first(List<Object?> scopes) => scopes.isEmpty ? undefined : scopes[0];

/// The property write `object[key] = value` (`[[Set]]`) in strict mode.
///
/// Only an object takes a property: a typed object through its face (a
/// resolver through its `set` trap) and a Map. Every other value throws a
/// [TypeError]. JavaScript also adds a property to an array or a function. A
/// Map whose value type does not allow [value] also throws a [TypeError]
/// (see the library documentation).
// DIVERGES(chartjs): js-semantics-resolver-objects, set on an object only.
void _set(Object? object, String key, Object? value) {
  if (object is JsObjectFace) {
    object.jsWrite(key, value);
    return;
  }
  if (object is Map) {
    object[key] = value;
    return;
  }
  // A JavaScript TypeError for null, undefined and the primitives.
  throw TypeError();
}

/// The property delete `delete object[key]`.
///
/// It calls the `deleteProperty` trap of a resolver, and the face of
/// another typed object. It removes an own [key] from a Map. It does nothing
/// for other values. Throws a [TypeError] for `null` and [undefined], as
/// JavaScript does.
///
/// A delete of an absent key succeeds also on a frozen object, as in strict
/// mode. Thus an unmodifiable Map (`Object.freeze`) throws only for a key
/// that it contains.
void _deleteProperty(Object? object, String key) {
  if (object == null || identical(object, undefined)) {
    throw TypeError();
  }
  if (object is JsObjectFace) {
    object.jsDelete(key);
  } else if (object is Map && object.containsKey(key)) {
    object.remove(key);
  }
}

/// The `in` operator and `Reflect.has` (`[[HasProperty]]`).
///
/// A resolver gives its `has` trap, and a context its prototype chain. Another
/// typed object and a Map give their own keys. A List has its array indices
/// and `length`. A function value has no property here. Throws a [TypeError]
/// for a value that is not an object, as JavaScript does.
bool _has(Object? object, String key) {
  if (object is JsProxyObject) {
    return object.hasProperty(key);
  }
  if (object is ContextObject) {
    return object.hasProperty(key);
  }
  if (object is JsObjectFace) {
    return object.jsHas(key);
  }
  if (object is Map) {
    return object.containsKey(key);
  }
  if (object is List) {
    if (key == 'length') return true;
    final index = jsArrayIndex(key);
    return index != null && index < object.length;
  }
  if (jsIsFunction(object)) {
    return false;
  }
  throw TypeError();
}

/// `Reflect.getOwnPropertyDescriptor(object, key) !== undefined`
/// (`[[GetOwnProperty]]`).
///
/// A resolver gives its `getOwnPropertyDescriptor` trap. Throws a
/// [TypeError] for a value that is not an object, as JavaScript does.
bool _getOwnProperty(Object? object, String key) {
  if (object is Resolver) {
    return object.hasOwnProperty(key);
  }
  if (object is ContextResolver) {
    return object.hasOwnProperty(key);
  }
  return _has(object, key);
}

/// `Reflect.ownKeys(object)` (`[[OwnPropertyKeys]]`).
///
/// A resolver gives its `ownKeys` trap. Another typed object and a Map give
/// their keys in the [jsObjectKeys] order. A List gives its indices and
/// `length`. A function value has no key here. Throws a [TypeError] for a
/// value that is not an object, as JavaScript does.
List<String> _reflectOwnKeys(Object? object) {
  if (object is JsProxyObject) {
    return object.ownKeys();
  }
  if (object is JsObjectFace || object is Map<String, Object?>) {
    return jsObjectKeys(object);
  }
  if (object is List) {
    return [for (var i = 0; i < object.length; i++) '$i', 'length'];
  }
  if (jsIsFunction(object)) {
    return [];
  }
  throw TypeError();
}

/// `Object.keys(object)`.
///
/// A typed object and a Map give [jsObjectKeys]: `objectKeys()` for a
/// resolver. A List or a String gives its indices. Any other value gives no
/// key. Throws a [TypeError] for `null` and [undefined], as JavaScript does.
List<String> _objectKeys(Object? object) {
  if (object == null || identical(object, undefined)) {
    throw TypeError();
  }
  if (object is JsObjectFace || object is Map<String, Object?>) {
    return jsObjectKeys(object);
  }
  if (object is List || object is String) {
    final length = object is List ? object.length : (object as String).length;
    return [for (var i = 0; i < length; i++) '$i'];
  }
  return [];
}
