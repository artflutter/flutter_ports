// Ported from Chart.js v4.6.1 src/helpers/helpers.config.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.config.ts`: the option resolvers.
///
/// Upstream builds the resolvers as `Proxy` objects over a cache object.
/// Dart has no `Proxy`. Chart.js ADR 0043 replaces them with the classes
/// [Resolver] (`_createResolver`) and [ContextResolver] (`_attachContext`).
/// Both classes are a `Map<String, Object?>`, so that `Element.options`,
/// `Scale.options` and `Chart.options` can hold them. They map the traps to
/// the members of [Map]:
///
/// | Trap | Dart member |
/// |---|---|
/// | `get` | `operator []` |
/// | `set` | `operator []=` |
/// | `deleteProperty` | [Map.remove] |
/// | `has` (`in`) | [Map.containsKey] |
/// | `ownKeys` (`Object.getOwnPropertyNames`) | [Map.keys] |
/// | `getOwnPropertyDescriptor` (`hasOwnProperty`) | `hasOwnProperty` |
/// | `getPrototypeOf` | none: a Map has no prototype |
///
/// Both classes are a [JsProxyObject]. `Object.keys` of a resolver is its
/// `objectKeys()`: [Map.keys] without the keys that `hasOwnProperty`
/// rejects, as the JavaScript engine filters the `ownKeys` result through the
/// `getOwnPropertyDescriptor` trap. [jsObjectKeys] gives that result. Thus
/// `each`, `clone` and `merge` of `helpers.core` see the upstream keys.
/// [Map.forEach], [Map.entries], [Map.values], [Map.length] and [Map.of] use
/// [Map.keys], the `ownKeys` trap. Ported code that enumerates a resolver
/// with `Object.keys`, `for-in`, `Object.assign` or the object spread calls
/// [jsObjectKeys].
///
/// A write through a resolver (the `set` traps and `subGetTarget`) goes into
/// a Map of the scopes. That Map takes the value only if its value type
/// allows it. A nested Map literal can have a narrow inferred type, for
/// example `Map<String, int>` for `{'a': 1}`. A write of a `String` into it
/// throws a [TypeError]. JavaScript sets the property. A scope that takes
/// writes has the runtime type `Map<String, Object?>`.
///
/// The cache object of a proxy is a plain Map. The traps and the private
/// functions read it as upstream reads `target`. The other upstream reads of
/// `proxy._scopes`, `resolver._getTarget()` and others go through
/// `operator []`, as they go through the `get` trap upstream. The typed
/// getters ([Resolver.scopes], [ContextResolver.proxy] and the others) read
/// the same keys through `operator []`.
///
/// The three JS states of an option key stay apart (Chart.js ADR 0043): an
/// absent key, the [undefined] sentinel and Dart `null` (JS `null`). The
/// resolution goes to the next scope on an absent key and on the sentinel.
/// `null` is a value. A resolver gives the [undefined] sentinel for a key
/// that it does not resolve. The cache keeps a resolved [undefined] as an
/// own key, as `_cached` does.
///
/// A scriptable option is a function value of `lib/src/js/js_function.dart`.
/// The resolver calls it through [jsCall] with the context and the
/// sub-resolver.
///
/// A scope list is a `List<Object?>`: `createSubResolver` also adds the
/// arrays, functions and other truthy values that a key gives. A JS
/// property read of such a value has the results of [jsGet].
library;

import 'dart:collection';
import 'dart:core';
import 'dart:core' as core;

import 'package:flutter_chartjs_port/src/helpers/helpers.config.types.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show capitalize, isArray, isFunction, isObject, resolveObjectKey;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:meta/meta.dart';

export 'package:flutter_chartjs_port/src/helpers/helpers.config.types.dart';

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
Resolver createResolver(
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
  final cache = <String, Object?>{
    '_cacheable': true,
    '_scopes': scopes,
    '_rootScopes': finalRootScopes,
    '_fallback': fallback,
    '_getTarget': target,
    'override': (AnyObject scope) => createResolver(
      [scope, ...scopes],
      prefixes,
      finalRootScopes,
      fallback,
    ),
  };
  return Resolver._(cache, scopes, prefixes, target);
}

/// The `Proxy` of `_createResolver` (helpers.config.ts:50-107), as a
/// `Map<String, Object?>` (Chart.js ADR 0043).
///
/// The library documentation lists the trap of each member. A
/// [Resolver] gives the [undefined] sentinel for a key that it does not
/// resolve, and Dart `null` for a JS `null` value.
final class Resolver extends MapBase<String, Object?>
    implements ResolverProxy, JsProxyObject {
  Resolver._(this._target, this._scopes, this._prefixes, this._getTarget);

  /// The cache object, `target` of the traps.
  final AnyObject _target;

  /// The `scopes` parameter of `_createResolver`.
  final List<Object?> _scopes;

  /// The `prefixes` parameter of `_createResolver`.
  final List<String> _prefixes;

  /// The `getTarget` parameter of `_createResolver`.
  final Object? Function() _getTarget;

  /// helpers.config.ts:54 the `deleteProperty` trap.
  ///
  /// A trap for the delete operator.
  ///
  /// It returns Dart `null`. The trap returns `true`.
  @core.override
  Object? remove(Object? key) {
    if (key is! String) return null;
    _target
      ..remove(key) // remove from cache
      ..remove('_keys'); // remove cached keys
    _deleteProperty(_first(_scopes), key); // remove from top level scope
    return null;
  }

  /// helpers.config.ts:64 the `get` trap.
  ///
  /// A trap for getting property values.
  ///
  /// A cached value that is not Dart `null` is owned, and [_cached] returns
  /// it. Thus the trap returns it with one lookup. Else [_cached] gets the
  /// arrow function of upstream as [_resolveResolver] and this resolver, so
  /// a read makes no closure.
  @core.override
  Object? operator [](Object? key) {
    if (key is! String) return undefined;
    // DIVERGES(chartjs): adapt-resolver-cached-read, one lookup for a hit.
    final cached = _target[key];
    if (cached != null) return cached;
    return _cached(_target, key, this, _resolveResolver);
  }

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
    return _getOwnProperty(jsGet(jsGet(_target, '_scopes'), '0'), key);
  }

  // helpers.config.ts:80 the `getPrototypeOf` trap has no Dart form.
  // DIVERGES(chartjs): js-semantics-resolver-objects, no getPrototypeOf trap.

  /// helpers.config.ts:87 the `has` trap.
  ///
  /// A trap for the in operator.
  @core.override
  bool containsKey(Object? key) {
    return key is String && _getKeysFromAllScopes(_target).contains(key);
  }

  /// helpers.config.ts:94 the `ownKeys` trap.
  ///
  /// A trap for Object.getOwnPropertyNames and Object.getOwnPropertySymbols.
  @core.override
  Iterable<String> get keys => _getKeysFromAllScopes(_target);

  /// `Object.keys(resolver)`: the `ownKeys` result filtered through the
  /// `getOwnPropertyDescriptor` trap ([hasOwnProperty]), in the trap order.
  @core.override
  List<String> objectKeys() => [
    for (final key in keys)
      if (hasOwnProperty(key)) key,
  ];

  /// helpers.config.ts:101 the `set` trap.
  ///
  /// A trap for setting property values.
  @core.override
  void operator []=(String key, Object? value) {
    final current = jsGet(_target, '_storage');
    final storage = jsTruthy(current)
        ? current
        : (_target['_storage'] = _getTarget());
    // set to top level scope + cache
    _set(storage, key, value);
    _target[key] = value;
    _target.remove('_keys'); // remove cached keys
  }

  /// [Map.clear]. Upstream has no counterpart. It deletes each key of
  /// [keys] through the `deleteProperty` trap ([remove]).
  @core.override
  void clear() {
    keys.toList().forEach(remove);
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
  Resolver override(AnyObject scope) {
    return (this['override']! as Resolver Function(AnyObject))(scope);
  }

  /// A description that resolves no option. Upstream has no counterpart.
  /// `String(resolver)` is `jsToString`, which gives `'[object Object]'`.
  @core.override
  String toString() => 'Resolver(cache: ${_target.keys.join(', ')})';
}

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
ContextResolver attachContext(
  Object? proxy,
  AnyObject context, [
  Object? subProxy = undefined,
  DescriptorDefaults? descriptorDefaults,
]) {
  final cache = <String, Object?>{
    '_cacheable': false,
    '_proxy': proxy,
    '_context': context,
    '_subProxy': subProxy,
    '_stack': <String>{},
    '_descriptors': descriptors(proxy, descriptorDefaults),
    'setContext': (AnyObject ctx) =>
        attachContext(proxy, ctx, subProxy, descriptorDefaults),
    'override': (AnyObject scope) => attachContext(
      jsCall(jsGet(proxy, 'override'), [scope], thisArg: proxy),
      context,
      subProxy,
      descriptorDefaults,
    ),
  };
  return ContextResolver._(cache, proxy);
}

/// The `Proxy` of `_attachContext` (helpers.config.ts:137-194), as a
/// `Map<String, Object?>` (Chart.js ADR 0043).
///
/// The library documentation lists the trap of each member.
final class ContextResolver extends MapBase<String, Object?>
    implements ContextProxy, JsProxyObject {
  ContextResolver._(this._target, this._proxy);

  /// The cache object, `target` of the traps.
  final AnyObject _target;

  /// The `proxy` parameter of `_attachContext`.
  final Object? _proxy;

  /// helpers.config.ts:141 the `deleteProperty` trap.
  ///
  /// A trap for the delete operator.
  ///
  /// It returns Dart `null`. The trap returns `true`.
  @core.override
  Object? remove(Object? key) {
    if (key is! String) return null;
    _target.remove(key); // remove from cache
    _deleteProperty(_proxy, key); // remove from proxy
    return null;
  }

  /// helpers.config.ts:150 the `get` trap. The receiver is this resolver.
  ///
  /// A trap for getting property values.
  ///
  /// A cached value that is not Dart `null` is owned, and [_cached] returns
  /// it. Thus the trap returns it with one lookup. Else [_cached] gets the
  /// arrow function of upstream as [_resolveContext] and this resolver, so a
  /// read makes no closure.
  @core.override
  Object? operator [](Object? key) {
    if (key is! String) return undefined;
    // DIVERGES(chartjs): adapt-resolver-cached-read, one lookup for a hit.
    final cached = _target[key];
    if (cached != null) return cached;
    return _cached(_target, key, this, _resolveContext);
  }

  /// helpers.config.ts:159 the `getOwnPropertyDescriptor` trap: whether a
  /// descriptor exists for [key].
  ///
  /// A trap for Object.getOwnPropertyDescriptor.
  /// Also used by Object.hasOwnProperty.
  bool hasOwnProperty(String key) {
    final descriptors = jsGet(_target, '_descriptors')! as Descriptor;
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
  bool containsKey(Object? key) {
    return key is String && _has(_proxy, key);
  }

  /// helpers.config.ts:182 the `ownKeys` trap.
  ///
  /// A trap for Object.getOwnPropertyNames and Object.getOwnPropertySymbols.
  @core.override
  Iterable<String> get keys => _reflectOwnKeys(_proxy);

  /// `Object.keys(resolver)`: the `ownKeys` result filtered through the
  /// `getOwnPropertyDescriptor` trap ([hasOwnProperty]), in the trap order.
  @core.override
  List<String> objectKeys() => [
    for (final key in keys)
      if (hasOwnProperty(key)) key,
  ];

  /// helpers.config.ts:189 the `set` trap.
  ///
  /// A trap for setting property values.
  @core.override
  void operator []=(String key, Object? value) {
    _set(_proxy, key, value); // set to proxy
    _target.remove(key); // remove from cache
  }

  /// [Map.clear]. Upstream has no counterpart. It deletes each key of
  /// [keys] through the `deleteProperty` trap ([remove]).
  @core.override
  void clear() {
    keys.toList().forEach(remove);
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
  AnyObject get context => this['_context']! as AnyObject;

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
  ContextResolver setContext(AnyObject ctx) {
    return (this['setContext']! as ContextResolver Function(AnyObject))(ctx);
  }

  /// helpers.config.ts:135 `override(scope)`: a resolver with [scope] in
  /// front of the scopes.
  @core.override
  ContextResolver override(AnyObject scope) {
    return (this['override']! as ContextResolver Function(AnyObject))(scope);
  }

  /// A description that resolves no option. Upstream has no counterpart.
  /// `String(resolver)` is `jsToString`, which gives `'[object Object]'`.
  @core.override
  String toString() => 'ContextResolver(cache: ${_target.keys.join(', ')})';
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
/// value.constructor === Object`. [isObject] is true only for a Map, and a
/// Map stands for a plain object (Chart.js ADR 0043). A resolver is a Map
/// too: upstream finds `Object` as its constructor through `_cached`.
bool _needsSubResolver(String prop, Object? value) =>
    isObject(value) && prop != 'adapters';

/// The arrow function of the `get` trap of `_createResolver`
/// (helpers.config.ts:66) for [resolver] and [prop].
Object? _resolveResolver(Resolver resolver, String prop) =>
    _resolveWithPrefixes(
      prop,
      resolver._prefixes,
      resolver._scopes,
      resolver._target,
    );

/// The arrow function of the `get` trap of `_attachContext`
/// (helpers.config.ts:152) for [resolver] and [prop]. The receiver is
/// [resolver].
Object? _resolveContext(ContextResolver resolver, String prop) =>
    _resolveWithContext(resolver._target, prop, resolver);

/// helpers.config.ts:218 `_cached`.
///
/// [target] is the cache object of a resolver. An owned key gives its value,
/// also an owned [undefined] sentinel.
///
/// Upstream gets `resolve` as a new arrow function for each read. The port
/// gets the [resolver] and a top-level [resolve] function, and calls
/// `resolve(resolver, prop)` for a key that the cache does not own. Thus a
/// read makes no closure. The calls and the results are the same.
Object? _cached<R>(
  AnyObject target,
  String prop,
  R resolver,
  Object? Function(R resolver, String prop) resolve,
) {
  if (target.containsKey(prop) || prop == 'constructor') {
    // DIVERGES(chartjs): js-semantics-resolver-objects, no Object constructor.
    return jsGet(target, prop);
  }

  // DIVERGES(chartjs): adapt-resolver-cached-read, no closure for a read.
  final value = resolve(resolver, prop);
  // cache the resolved value
  target[prop] = value;
  return value;
}

/// helpers.config.ts:233 `_resolveWithContext`.
Object? _resolveWithContext(
  AnyObject target,
  String prop,
  AnyObject receiver,
) {
  final proxy = jsGet(target, '_proxy');
  final context = jsGet(target, '_context');
  final subProxy = jsGet(target, '_subProxy');
  final descriptors = jsGet(target, '_descriptors')! as Descriptor;
  var value = jsGet(proxy, prop); // resolve from proxy

  // resolve with context
  if (isFunction(value) && _isScriptableMethod(descriptors, prop)) {
    value = _resolveScriptable(prop, value, target, receiver);
  }
  if (isArray(value) && (value! as List<Object?>).isNotEmpty) {
    value = _resolveArray(
      prop,
      value as List<Object?>,
      target,
      descriptors.isIndexable,
    );
  }
  if (_needsSubResolver(prop, value)) {
    // if the resolved value is an object, create a sub resolver for it
    value = attachContext(
      value,
      context! as AnyObject,
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
  AnyObject target,
  AnyObject receiver,
) {
  final proxy = jsGet(target, '_proxy');
  final context = jsGet(target, '_context');
  final subProxy = jsGet(target, '_subProxy');
  final stack = jsGet(target, '_stack')! as Set<String>;
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
  AnyObject target,
  bool Function(String key) isIndexable,
) {
  final proxy = jsGet(target, '_proxy');
  final context = jsGet(target, '_context');
  final subProxy = jsGet(target, '_subProxy');
  final descriptors = jsGet(target, '_descriptors')! as Descriptor;

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
          context! as AnyObject,
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

/// helpers.config.ts:335 `createSubResolver`.
///
/// It returns a [Resolver], or `false`.
Object _createSubResolver(
  List<Object?> parentScopes,
  Object? resolver,
  String prop,
  Object? value,
) {
  final rootScopes = jsGet(resolver, '_rootScopes')! as List<Object?>;
  final fallback = _resolveFallback(jsGet(resolver, '_fallback'), prop, value);
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
Object? _subGetTarget(Object? resolver, String prop, Object? value) {
  // The port's own `_getTarget` closure reads neither `this` nor arguments.
  final parent = (jsGet(resolver, '_getTarget')! as Object? Function())();
  if (!_has(parent, prop)) {
    _set(parent, prop, <String, Object?>{});
  }
  final target = jsGet(parent, prop);
  if (isArray(target) && isObject(value)) {
    // For array of objects, the object is used to store updated values
    return value;
  }
  return jsTruthy(target) ? target : <String, Object?>{};
}

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
/// `null` (JS `null`) is the result.
Object? _resolve(String key, List<Object?> scopes) {
  for (final scope in scopes) {
    if (!jsTruthy(scope)) {
      continue;
    }
    final value = jsGet(scope, key);
    if (!identical(value, undefined)) {
      return value;
    }
  }
  return undefined;
}

/// helpers.config.ts:419 `getKeysFromAllScopes`.
List<String> _getKeysFromAllScopes(AnyObject target) {
  var keys = jsGet(target, '_keys');
  if (!jsTruthy(keys)) {
    keys = target['_keys'] = _resolveKeysFromAllScopes(
      jsGet(target, '_scopes')! as List<Object?>,
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
/// as `thisArg`. It returns a `List<Map<String, Object?>>` of `{r}` objects.
const JsFunction parseObjectDataRadialScale = JsFunction(
  _parseObjectDataRadialScale,
);

/// The closure of [parseObjectDataRadialScale].
List<Map<String, Object?>> _parseObjectDataRadialScale(
  DatasetController self,
  ChartMeta meta,
  List<Object?> data,
  double start,
  double count,
) {
  final iScale = meta.iScale;
  final parsingKey = jsGet(self.parsing, 'key');
  final key = identical(parsingKey, undefined) ? 'r' : parsingKey;
  final parsed = <Map<String, Object?>>[];

  for (var i = 0.0, ilen = count; i < ilen; ++i) {
    final index = i + start;
    final item = jsGetIndex(data, index);
    parsed.add({
      'r': iScale!.parse(resolveObjectKey(item, key! as String), index),
    });
  }
  return parsed;
}

// The JavaScript object operations of the traps, for the Dart values of
// Chart.js ADR 0043. Upstream has no counterpart: the JavaScript engine
// does them.

/// The first scope, `scopes[0]`: the [undefined] sentinel for an empty
/// list.
Object? _first(List<Object?> scopes) => scopes.isEmpty ? undefined : scopes[0];

/// Whether [object] is a JS `Proxy`: a resolver of this library.
bool _isProxy(Object? object) => object is JsProxyObject;

/// The property write `object[key] = value` (`[[Set]]`) in strict mode.
///
/// Only a Map takes a property. Every other value throws a [TypeError].
/// JavaScript also adds a property to an array or a function. A Map whose
/// value type does not allow [value] also throws a [TypeError] (see the
/// library documentation).
// DIVERGES(chartjs): js-semantics-resolver-objects, set on a Map only.
void _set(Object? object, String key, Object? value) {
  if (object is Map) {
    object[key] = value;
    return;
  }
  // A JavaScript TypeError for null, undefined and the primitives.
  throw TypeError();
}

/// The property delete `delete object[key]`.
///
/// It calls the `deleteProperty` trap of a resolver. It removes an own [key]
/// from another Map. It does nothing for other values. Throws a [TypeError]
/// for `null` and [undefined], as JavaScript does.
///
/// A delete of an absent key succeeds also on a frozen object, as in strict
/// mode. Thus an unmodifiable Map (`Object.freeze`) throws only for a key
/// that it contains.
void _deleteProperty(Object? object, String key) {
  if (object == null || identical(object, undefined)) {
    throw TypeError();
  }
  if (object is JsProxyObject) {
    object.remove(key);
  } else if (object is Map && object.containsKey(key)) {
    object.remove(key);
  }
}

/// The `in` operator and `Reflect.has` (`[[HasProperty]]`).
///
/// A resolver gives its `has` trap. A List has its array indices and
/// `length`. A function value has no property here. Throws a [TypeError] for
/// a value that is not an object, as JavaScript does.
bool _has(Object? object, String key) {
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
/// A resolver gives its `ownKeys` trap. A Map gives its keys in the
/// [jsObjectKeys] order. A List gives its indices and `length`. A function
/// value has no key here. Throws a [TypeError] for a value that is not an
/// object, as JavaScript does.
List<String> _reflectOwnKeys(Object? object) {
  if (_isProxy(object)) {
    return (object! as Map<String, Object?>).keys.toList();
  }
  if (object is Map<String, Object?>) {
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
/// A Map gives [jsObjectKeys]: `objectKeys()` for a resolver. A List or a
/// String gives its indices. Any other value gives no key. Throws a
/// [TypeError] for `null` and [undefined], as JavaScript does.
List<String> _objectKeys(Object? object) {
  if (object == null || identical(object, undefined)) {
    throw TypeError();
  }
  if (object is Map<String, Object?>) {
    return jsObjectKeys(object);
  }
  if (object is List || object is String) {
    final length = object is List ? object.length : (object as String).length;
    return [for (var i = 0; i < length; i++) '$i'];
  }
  return [];
}
