// Ported from Chart.js v4.6.1 src/helpers/helpers.core.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.core.ts`.
///
/// The JavaScript values map to Dart values as Chart.js ADR 0043 decides: a
/// plain object is a `Map<String, Object?>` ([AnyObject]), an array is a
/// [List], `undefined` is the [undefined] sentinel and `null` is Dart `null`.
/// A function value is a Dart [Function] or a [JsFunction], and ported code
/// calls it through [jsCall] (`lib/src/js/js_function.dart`).
///
/// A Map has no prototype. Thus [isObject] is true only for a
/// `Map<String, Object?>`. In JavaScript it is also true for an instance of a
/// class (helpers.core.ts:53-55). Here a class instance in an options tree is
/// a leaf: [clone] and [mergeIf] copy its reference and do not enter it.
/// [merge] skips a class instance as a source, and it copies the reference of
/// a class instance as a source value, also over an element target value.
/// [merge] writes into a `types.PropertyAccess` target, for example an
/// element, through the access by name (Chart.js ADR 0039, section 10).
///
/// @namespace Chart.helpers
library;

import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart'
    show OptionScope, ScopeKind;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';

/// helpers.core.ts:11 `noop`.
///
/// An empty function that can be used, for example, for optional callback.
///
/// It returns the [undefined] sentinel, as a JavaScript function without a
/// `return` returns `undefined`. Ported code calls it through [jsCall], which
/// drops the arguments that it does not take.
Undefined noop() {
  /* noop */
  return undefined;
}

/// The counter of [uid]: the `id` variable of the closure at
/// helpers.core.ts:19.
double _id = 0;

/// helpers.core.ts:18 `uid`.
///
/// Returns a unique id, sequentially generated from a global variable.
double uid() => _id++;

/// helpers.core.ts:28 `isNullOrUndef`.
///
/// Returns true if `value` is neither null nor undefined, else returns false.
/// @param value - The value to test.
/// @since 2.7.0
bool isNullOrUndef(Object? value) {
  return value == null || identical(value, undefined);
}

/// helpers.core.ts:37 `isArray`.
///
/// Returns true if `value` is an array (including typed arrays), else returns
/// false.
/// @param value - The value to test.
/// @function
///
/// A JavaScript array is a [List] (Chart.js ADR 0043). The typed lists of
/// `dart:typed_data`, which stand for the typed arrays, are lists too. Thus
/// one type test replaces `Array.isArray` and the `[object ...Array]` test.
bool isArray(Object? value) {
  return value is List;
}

/// helpers.core.ts:53 `isObject`.
///
/// Returns true if `value` is an object (excluding null), else returns false.
/// @param value - The value to test.
/// @since 2.7.0
///
/// A JavaScript plain object is a `Map<String, Object?>` (Chart.js ADR 0043),
/// so only such a Map is an object here. Each consequence is a difference
/// from JavaScript:
/// - An instance of a Dart class is not an object, although
///   `Object.prototype.toString` gives `'[object Object]'` for an instance of
///   a JavaScript class. [clone] and [mergeIf] treat it as a leaf. [merge]
///   and [merger] treat a `types.PropertyAccess` target as an object (the
///   row `adapt-merge-element-target`).
/// - A Map with other key types, for example the `Map<dynamic, dynamic>` of
///   an untyped `{}` literal, is not an object. Give a Map literal the type
///   `<String, Object?>`.
/// - A Map with a narrower value type, for example `Map<String, int>`, is an
///   object. A [merge] into it throws a [TypeError] when it writes a value of
///   another type.
///
/// A typed option scope of Chart.js ADR 0054 (`OptionScope`) is an object
/// too (§5, the leaf rule).
bool isObject(Object? value) {
  return value != null &&
      (value is Map<String, Object?> || value is OptionScope);
}

/// helpers.core.ts:61 `isNumberFinite`: whether [value] is a finite number.
///
/// Returns true if `value` is a finite number, else returns false
/// @param value  - The value to test.
///
/// Dart has no `Number` wrapper objects, so `value instanceof Number` has no
/// counterpart.
bool _isNumberFinite(Object? value) {
  return value is num && value.isFinite;
}

/// helpers.core.ts:65 `isFinite`, the exported name of `isNumberFinite`.
const bool Function(Object? value) isFinite = _isNumberFinite;

/// helpers.core.ts:73 `finiteOrDefault`.
///
/// Returns `value` if finite, else returns `defaultValue`.
/// @param value - The value to return if defined.
/// @param defaultValue - The value to return if `value` is not finite.
///
/// The result is a `double`, also for an `int` [value] (Chart.js ADR 0045).
double finiteOrDefault(Object? value, double defaultValue) {
  return _isNumberFinite(value) ? (value! as num).toDouble() : defaultValue;
}

/// helpers.core.ts:82 `valueOrDefault`.
///
/// Returns `value` if defined, else returns `defaultValue`.
/// @param value - The value to return if defined.
/// @param defaultValue - The value to return if `value` is undefined.
///
/// Only the [undefined] sentinel is `undefined`. Dart `null` is JavaScript
/// `null`, a defined value. A read of an absent Map key gives Dart `null`, so
/// a caller passes [undefined] for an absent key (Chart.js ADR 0043).
T valueOrDefault<T>(T value, T defaultValue) {
  return identical(value, undefined) ? defaultValue : value;
}

/// helpers.core.ts:86 `toPercentage`.
///
/// [value] is a `number | string` upstream. Here it is any value, coerced as
/// unary `+` coerces it.
double toPercentage(Object? value, double dimension) =>
    value is String && value.endsWith('%')
    ? jsParseFloat(value) / 100
    : jsToNumber(value) / dimension;

/// helpers.core.ts:91 `toDimension`.
///
/// [value] is a `number | string` upstream. Here it is any value, coerced as
/// unary `+` coerces it.
double toDimension(Object? value, double dimension) =>
    value is String && value.endsWith('%')
    ? jsParseFloat(value) / 100 * dimension
    : jsToNumber(value);

/// helpers.core.ts:103 `callback`.
///
/// Calls `fn` with the given `args` in the scope defined by `thisArg` and
/// returns the value returned by `fn`. If `fn` is not a function, this method
/// returns undefined.
/// @param fn - The function to call.
/// @param args - The arguments with which `fn` should be called.
/// @param [thisArg] - The value of `this` provided for the call to `fn`.
///
/// [fn] is a Dart [Function] or a [JsFunction]. Only a [JsFunction] gets
/// [thisArg] ([jsCall]). A null [args] is no argument, as
/// `fn.apply(thisArg, undefined)` is.
Object? callback(
  Object? fn, [
  List<Object?>? args,
  Object? thisArg = undefined,
]) {
  // A function is always truthy, and every function has a `call` method.
  if (jsIsFunction(fn)) {
    return jsCall(fn, args ?? const [], thisArg: thisArg);
  }
  return undefined;
}

/// helpers.core.ts:134 `each`, with the overloads at :122 and :128.
///
/// Note(SB) for performance sake, this method should only be used when
/// loopable type is unknown or in none intensive code (not called often and
/// small loopable). Else it's preferable to use a regular for() loop and save
/// extra function calls.
/// @param loopable - The object or array to be iterated.
/// @param fn - The function to call for each item.
/// @param [thisArg] - The value of `this` provided for the call to `fn`.
/// @param [reverse] - If true, iterates backward on the loopable.
///
/// [fn] is a Dart [Function] or a [JsFunction], called through [jsCall]. For
/// a List it gets the item and its index as a `double`. For a Map it gets the
/// value and the key, in the [jsObjectKeys] order. An item that a call of
/// [fn] removes reads as [undefined], as in JavaScript.
void each(
  Object? loopable,
  Object fn, [
  Object? thisArg = undefined,
  // The upstream signature has a positional `reverse`.
  // ignore: avoid_positional_boolean_parameters
  bool reverse = false,
]) {
  int i;
  int len;
  List<String> keys;
  if (isArray(loopable)) {
    final array = loopable! as List;
    len = array.length;
    if (reverse) {
      for (i = len - 1; i >= 0; i--) {
        jsCall(fn, [_item(array, i), i.toDouble()], thisArg: thisArg);
      }
    } else {
      for (i = 0; i < len; i++) {
        jsCall(fn, [_item(array, i), i.toDouble()], thisArg: thisArg);
      }
    }
  } else if (isObject(loopable)) {
    final object = loopable! as AnyObject;
    keys = jsObjectKeys(object);
    len = keys.length;
    for (i = 0; i < len; i++) {
      jsCall(fn, [jsGet(object, keys[i]), keys[i]], thisArg: thisArg);
    }
  }
}

/// helpers.core.ts:167 `_elementsEqual`.
///
/// Returns true if the `a0` and `a1` arrays have the same content, else
/// returns false.
/// @param a0 - The array to compare
/// @param a1 - The array to compare
/// @private
///
/// A null list stands for a falsy JavaScript value: `null` or `undefined`.
bool elementsEqual(List<ActiveDataPoint>? a0, List<ActiveDataPoint>? a1) {
  if (a0 == null || a1 == null || a0.length != a1.length) {
    return false;
  }

  for (var i = 0, ilen = a0.length; i < ilen; ++i) {
    final v0 = a0[i];
    final v1 = a1[i];

    if (v0.datasetIndex != v1.datasetIndex || v0.index != v1.index) {
      return false;
    }
  }

  return true;
}

/// helpers.core.ts:190 `clone`.
///
/// Returns a deep copy of `source` without keeping references on objects and
/// arrays.
/// @param source - The value to clone.
///
/// A List gives a new `List<Object?>`. A typed list gives a new typed list of
/// the same type, as `TypedArray.prototype.map` does. An object gives a new
/// `Map<String, Object?>` with its keys in the [jsObjectKeys] order. The
/// upstream target has no prototype (`Object.create(null)`), so a
/// `'__proto__'` key becomes an own key, as here. Any other value is the
/// result.
Object? clone(Object? source) {
  // A typed scope gives a typed copy (Chart.js ADR 0054 §3).
  if (source is OptionScope) return source.cloneScope();
  if (isArray(source)) {
    final array = source! as List;
    // Array.prototype.map(clone). clone(v) is v for each number of a typed
    // list, so a copy is the map result.
    if (array is TypedData) return array.sublist(0);
    return <Object?>[for (final value in array) clone(value)];
  }

  if (isObject(source)) {
    final object = source! as AnyObject;
    final target = <String, Object?>{};
    final keys = jsObjectKeys(object);
    final klen = keys.length;
    var k = 0;

    for (; k < klen; ++k) {
      target[keys[k]] = clone(object[keys[k]]);
    }

    return target;
  }

  return source;
}

/// helpers.core.ts:211 `isValidKey`.
bool _isValidKey(String key) {
  return !['__proto__', 'prototype', 'constructor'].contains(key);
}

/// helpers.core.ts:220 `_merger`.
///
/// The default merger when Chart.helpers.merge is called without merger
/// option.
/// Note(SB): also used by mergeConfig and mergeScaleConfig as fallback.
/// @private
///
/// Upstream `isObject` is true for an instance of a class. Thus `_merger`
/// also merges an object into an element value (helpers.core.ts:228-230).
/// Here a [PropertyAccess] value of [target] is an object target too: [merge]
/// writes into it by name (the row `adapt-merge-element-target`). The test
/// of the source value comes first, so a leaf source value costs no
/// interface test. A class instance as a source value is not an object here.
/// Thus its reference replaces the target value, also an element, where
/// upstream merges its own keys into an element target value.
void merger(
  String key,
  AnyObject target,
  AnyObject source,
  MergeOptions options,
) {
  if (!_isValidKey(key)) {
    return;
  }

  final tval = target[key];
  final sval = source[key];

  if (isObject(tval) && isObject(sval)) {
    merge(tval, sval, options);
  } else if (isObject(sval) && tval is PropertyAccess) {
    // DIVERGES(chartjs): adapt-merge-element-target, a by-name target.
    merge(tval, sval, options);
  } else {
    target[key] = _cloneFor(target, key, sval);
  }
}

/// `clone(sval)` for the key [key] of [target]. Into a typed scope, an
/// object under a key of a nested kind gives a typed copy of that kind
/// (Chart.js ADR 0054 §3): the same keys and values in the same order as
/// the plain copy of [clone].
Object? _cloneFor(AnyObject target, String key, Object? sval) {
  if (target is OptionScope && isObject(sval)) {
    final kind = target.childKindFor(key);
    if (kind != null) return _cloneToScope(kind, sval!);
  }
  return clone(sval);
}

/// The deep copy of the object [source] as a typed scope of [kind]: each
/// own key of [source] in the [jsObjectKeys] order, an object under a key of
/// a nested kind as a typed scope of that kind, any other value as [clone]
/// gives it (Chart.js ADR 0054 §3).
OptionScope _cloneToScope(ScopeKind kind, Object source) {
  final scope = kind.create();
  final object = source as AnyObject;
  for (final key in jsObjectKeys(object)) {
    final value = jsGet(object, key);
    final child = scope.childKindFor(key);
    scope.jsWrite(
      key,
      child != null && isObject(value)
          ? _cloneToScope(child, value!)
          : clone(value),
    );
  }
  return scope;
}

/// helpers.core.ts:237 the type of `MergeOptions.merger`: merges `source[key]`
/// into `target`.
typedef Merger = void Function(
  String key,
  AnyObject target,
  AnyObject source,
  MergeOptions options,
);

/// helpers.core.ts:236 `MergeOptions`.
final class MergeOptions {
  /// The options `{merger}`. A null [merger] is an absent one.
  const MergeOptions({this.merger});

  /// helpers.core.ts:237 `merger?`. [merge] passes it the options object as
  /// its last argument.
  final Merger? merger;
}

/// helpers.core.ts:260 `merge`, with the overloads at :249-259.
///
/// Recursively deep copies `source` properties into `target` with the given
/// `options`.
/// IMPORTANT: `target` is not cloned and will be updated with `source`
/// properties.
/// @param target - The target object in which all sources are merged into.
/// @param source - Object(s) to merge into `target`.
/// @param [options] - Merging options:
/// @param `[options.merger]` - The merge method (key, target, source,
/// options)
/// @returns The `target` object.
///
/// Upstream `isObject` is true for an instance of a class, also for an
/// element (helpers.core.ts:53-55, :264). Thus upstream merges into an
/// element target, for example `Chart.helpers.merge(tooltip, view)`
/// (`plugin.tooltip.tests.js:1501`). Here a [PropertyAccess] target is an
/// object target too: the merger reads and writes it through a Map view with
/// the read and the write by name ([PropertyAccess.operator []] and
/// [PropertyAccess.operator []=]). The result is the target, not the view
/// (the row `adapt-merge-element-target`, Chart.js ADR 0039, section 10).
/// The view has no keys. Thus a custom merger that lists the keys of its
/// target, or tests a key with `containsKey`, throws an
/// [UnsupportedError]. The default [merger] does neither.
Object? merge(
  Object? target, [
  Object? source = undefined,
  MergeOptions? options,
]) {
  final sources = isArray(source) ? source! as List : [source];
  final ilen = sources.length;

  final AnyObject object;
  if (isObject(target)) {
    object = target! as AnyObject;
  } else if (target is PropertyAccess) {
    // DIVERGES(chartjs): adapt-merge-element-target, a by-name target.
    object = _PropertyAccessView(target);
  } else {
    return target;
  }

  final mergeOptions = options ?? const MergeOptions();
  // Upstream names it `merger`, the Dart name of `_merger`.
  final keyMerger = mergeOptions.merger ?? merger;
  Object? current;

  for (var i = 0; i < ilen; ++i) {
    current = sources[i];
    if (!isObject(current)) {
      continue;
    }

    final currentObject = current! as AnyObject;
    final keys = jsObjectKeys(currentObject);
    for (var k = 0, klen = keys.length; k < klen; ++k) {
      keyMerger(keys[k], object, currentObject, mergeOptions);
    }
  }

  return target;
}

/// helpers.core.ts:301 `mergeIf`, with the overloads at :294-300.
///
/// Recursively deep copies `source` properties into `target` *only* if not
/// defined in target.
/// IMPORTANT: `target` is not cloned and will be updated with `source`
/// properties.
/// @param target - The target object in which all sources are merged into.
/// @param source - Object(s) to merge into `target`.
/// @returns The `target` object.
///
/// Upstream also merges into an element target, because its `isObject` is
/// true for an instance of a class. Here [mergeIf] keeps an element target
/// as it is: [mergerIf] tests the own keys of its target, and an element has
/// no list of own keys (the row `adapt-merge-element-target`). The test
/// gives the result of [merge] for every other target, because [merge]
/// returns a target that is not an object at once.
Object? mergeIf(Object? target, [Object? source = undefined]) {
  // DIVERGES(chartjs): adapt-merge-element-target, no by-name target.
  if (!isObject(target)) {
    return target;
  }
  return merge(target, source, const MergeOptions(merger: mergerIf));
}

/// helpers.core.ts:310 `_mergerIf`.
///
/// Merges source[key] in target[key] only if target[key] is undefined.
/// @private
///
/// "Undefined" here means that [target] does not own [key]
/// (`hasOwnProperty`). A key that holds the [undefined] sentinel is owned, so
/// it keeps its value (Chart.js ADR 0043, "Resolver rule").
///
/// Upstream takes three parameters, and JavaScript drops the fourth argument
/// of [merge]. The optional [options] parameter makes the function a
/// [Merger]. It is not read.
void mergerIf(
  String key,
  AnyObject target,
  AnyObject source, [
  MergeOptions? options,
]) {
  if (!_isValidKey(key)) {
    return;
  }

  final tval = target[key];
  final sval = source[key];

  if (isObject(tval) && isObject(sval)) {
    mergeIf(tval, sval);
  } else if (!target.containsKey(key)) {
    target[key] = _cloneFor(target, key, sval);
  }
}

/// The Map view of a [PropertyAccess] target of [merge] (the row
/// `adapt-merge-element-target`).
///
/// [operator []] is the read by name of the target: the [undefined] sentinel
/// for an absent name. [operator []=] is the write by name. An element has no
/// list of its own keys. Thus [keys], [remove] and [clear] throw an
/// [UnsupportedError], and so do the other Map members that use them, for
/// example `containsKey` and `length`.
final class _PropertyAccessView extends MapBase<String, Object?> {
  _PropertyAccessView(this._target);

  final PropertyAccess _target;

  @override
  Object? operator [](Object? key) => _target[key! as String];

  @override
  void operator []=(String key, Object? value) => _target[key] = value;

  @override
  Iterable<String> get keys => throw UnsupportedError(
    'The keys of a merge target that is not a Map',
  );

  @override
  Object? remove(Object? key) => throw UnsupportedError(
    'A remove from a merge target that is not a Map',
  );

  @override
  void clear() => throw UnsupportedError(
    'A clear of a merge target that is not a Map',
  );
}

/// helpers.core.ts:328 `_deprecated`.
/// @private
///
/// `console.warn` is [print]: the Dart console output on every platform.
void deprecated(String scope, Object? value, String previous, String current) {
  if (!identical(value, undefined)) {
    // console.warn has no other counterpart in the pure layers.
    // ignore: avoid_print
    print(
      '$scope: "$previous" is deprecated. Please use "$current" instead',
    );
  }
}

/// helpers.core.ts:336 `keyResolvers`: the `resolveObjectKey` resolver cache.
///
/// Upstream is an object literal, so it also has the members of
/// `Object.prototype`. A Map does not: see [resolveObjectKey].
final Map<String, Object? Function(Object? obj)> _keyResolvers = {
  // Chart.helpers.core resolveObjectKey should resolve empty key to root
  // object
  '': (v) => v,
  // default resolvers
  'x': (o) => jsGet(o, 'x'),
  'y': (o) => jsGet(o, 'y'),
};

/// helpers.core.ts:347 `_splitKey`.
/// @private
List<String> splitKey(String key) {
  final parts = key.split('.');
  final keys = <String>[];
  var tmp = '';
  for (final part in parts) {
    // Upstream concatenates.
    // ignore: use_string_buffers
    tmp += part;
    if (tmp.endsWith(r'\')) {
      tmp = '${tmp.substring(0, tmp.length - 1)}.';
    } else {
      keys.add(tmp);
      tmp = '';
    }
  }
  return keys;
}

/// helpers.core.ts:363 `_getKeyResolver`.
Object? Function(Object? obj) _getKeyResolver(String key) {
  final keys = splitKey(key);
  return (obj) {
    for (final k in keys) {
      if (k == '') {
        // For backward compatibility:
        // Chart.helpers.core resolveObjectKey should break at empty key
        break;
      }
      // Upstream reassigns its parameter.
      // ignore: parameter_assignments
      obj = jsTruthy(obj) ? jsGet(obj, k) : obj;
    }
    return obj;
  };
}

/// helpers.core.ts:378 `resolveObjectKey`.
///
/// Reads the dot-separated path [key] in [obj]. A key that [obj] does not own
/// reads as the [undefined] sentinel. A falsy value on the path is the
/// result. [obj] is any value: the parsed data items of a dataset are not
/// always objects.
///
/// A key that names a member of `Object.prototype`, for example
/// `constructor` or `toString`, resolves here as any other key. Upstream
/// finds that member in its resolver cache: `resolveObjectKey({constructor:
/// 5}, 'constructor')` returns the object, and `resolveObjectKey({toString:
/// 5}, 'toString')` returns `'[object Undefined]'` in the reference engine. A
/// Map has no prototype (Chart.js ADR 0043, differences.md
/// `js-semantics-resolver-cache`).
///
/// A read of `x` or `y` in `null` or [undefined] throws a [TypeError], as in
/// JavaScript.
Object? resolveObjectKey(Object? obj, String key) {
  // DIVERGES(chartjs): js-semantics-resolver-cache, a Map has no prototype.
  final resolver = _keyResolvers[key] ??= _getKeyResolver(key);
  return resolver(obj);
}

/// helpers.core.ts:386 `_capitalize`.
/// @private
///
/// `charAt(0)` and `slice(1)` of an empty string are `''`.
///
/// `toUpperCase` is the Dart [String.toUpperCase] of the platform. On the
/// Dart VM it uses only one-to-one case mappings from an older Unicode
/// table: `capitalize('ßa')` is `'ßa'` there and `'SSa'` in JavaScript.
/// ASCII names, the names of Chart.js options and methods, give the same
/// result on every platform (differences.md `js-semantics-to-upper-case`).
String capitalize(String str) {
  // DIVERGES(chartjs): js-semantics-to-upper-case, Dart toUpperCase.
  return (str.isEmpty ? '' : str[0]).toUpperCase() +
      (str.isEmpty ? '' : str.substring(1));
}

/// helpers.core.ts:391 `defined`: whether [value] is not the [undefined]
/// sentinel.
bool defined(Object? value) => !identical(value, undefined);

/// helpers.core.ts:393 `isFunction`: `typeof value === 'function'`, which is
/// [jsIsFunction]: a Dart [Function], a [JsFunction] or a class value
/// (`JsClass`, Chart.js ADR 0020).
bool isFunction(Object? value) => jsIsFunction(value);

/// helpers.core.ts:396 `setsEqual`.
///
/// Adapted from https://stackoverflow.com/questions/31128855/comparing-ecma6-sets-for-equality#31129384
///
/// A Dart [Set] stands for a JavaScript `Set`. A Dart Set compares its
/// elements with `==`, a JavaScript `Set` with SameValueZero. The two agree
/// on strings, the element type of the upstream callers
/// (core.controller.js:559, :597). They differ on NaN: `setsEqual({NaN},
/// {NaN})` is true in JavaScript (differences.md
/// `js-semantics-set-equality`).
bool setsEqual<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) {
    return false;
  }

  for (final item in a) {
    // DIVERGES(chartjs): js-semantics-set-equality, == not SameValueZero.
    if (!b.contains(item)) {
      return false;
    }
  }

  return true;
}

/// helpers.core.ts:414 `_isClickEvent`.
/// @param e - The event
/// @private
bool isClickEvent(ChartEvent e) {
  return e.type == 'mouseup' || e.type == 'click' || e.type == 'contextmenu';
}

/// The element of [array] at [i], or [undefined] if a call of `each` made
/// [array] shorter (helpers.core.ts:145, :149).
Object? _item(List<Object?> array, int i) =>
    i < array.length ? array[i] : undefined;
