// Original code, not ported from Chart.js: JS property read and Object.freeze.

/// The JavaScript property read `object[key]` (`[[Get]]`) over the Dart
/// values that stand for JavaScript values (Chart.js ADR 0043), its forms
/// for a property name and a number index (Chart.js ADR 0036), the frozen
/// state of `Object.freeze` (Chart.js ADR 0021, section 5), and the `typeof`
/// operator (Chart.js ADR 0019, section 1).
library;

import 'dart:collection' show MapBase;

import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsIsFunction;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// The face by name of a typed object of the typed internal model
/// (Chart.js ADR 0054 §5): the typed option scopes, the resolved options,
/// the resolvers and views, the contexts, the props, the parsed items, the
/// plugins, the hook arguments and the other typed objects of `lib/src`.
///
/// The face is the cold API for user code, the raw boundary and the tests.
/// It is never in a hot path. The JS runtime reads a face by name: [jsGet],
/// [jsGetKey], [jsSet], [jsHasOwn], [jsDeleteKey], `jsObjectKeys` and
/// `jsOwnPropertyNames` take it.
///
/// The members have the JS rules:
/// - [jsRead] and [operator []] give the value of a property, or [undefined]
///   for a property that the object does not have (never Dart `null` for an
///   absent key: Dart `null` is the JS `null`).
/// - [jsWrite] and [operator []=] set a property; a frozen object throws a
///   [TypeError].
/// - [jsKeys] gives the own enumerable keys in the order of `Object.keys`:
///   the array-index keys first, in ascending order, then the other keys in
///   their insertion order.
/// - [jsHas] is `hasOwnProperty`, and [jsDelete] is the `delete` operator.
///
/// A typed object of the chart (a resolver view, a context, resolved
/// options, a typed scope, a hook argument object, a legend or tooltip item)
/// is not a `Map`: read it by name through this interface, for example
/// `(context as JsObjectFace)['dataIndex']`. A `Map` of the port is a JS
/// object of the user (a raw config) or a plain object that the port makes.
abstract interface class JsObjectFace {
  /// `object[name]` (`[[Get]]`): the value of [name], or [undefined] when
  /// the object has no such property.
  Object? jsRead(String name);

  /// `object[name] = value` (`[[Set]]`).
  void jsWrite(String name, Object? value);

  /// `object[name]`: [jsRead].
  Object? operator [](String name);

  /// `object[name] = value`: [jsWrite].
  void operator []=(String name, Object? value);

  /// `Object.keys(object)`: the own enumerable keys in their order.
  List<String> jsKeys();

  /// `Object.prototype.hasOwnProperty.call(object, name)`.
  bool jsHas(String name);

  /// `delete object[name]`. Returns whether the object owned [name].
  bool jsDelete(String name);
}

/// Whether [value] is a JS object with properties by name: a `Map` (an
/// object of the user, or a plain object that the port makes) or a
/// [JsObjectFace] (a typed object of Chart.js ADR 0054).
bool jsIsObjectLike(Object? value) =>
    value is Map<dynamic, dynamic> || value is JsObjectFace;

/// [value] as an object argument: Dart `null` for `null` and [undefined],
/// the value for an object ([jsIsObjectLike]), else a [TypeError] (the cast
/// of a member of a config object that the port reads as an object).
Object? jsObjectOrNull(Object? value) => switch (value) {
  null || Undefined() => null,
  _ when jsIsObjectLike(value) => value,
  _ => throw TypeError(),
};

/// `object[key] = value` (`[[Set]]`) for a property name [key].
///
/// - A [JsObjectFace]: [JsObjectFace.jsWrite].
/// - A `Map`: the Map write. A Map with a narrow value type throws a
///   [TypeError] for a value of another type.
/// - A [JsClass]: the static property ([JsClass.operator []=]).
///
/// Throws a [TypeError] for `null` and [undefined], as JavaScript does, and
/// an [ArgumentError] for another value: no ported code writes a property
/// of a primitive.
void jsSet(Object? object, String key, Object? value) {
  switch (object) {
    case null || Undefined():
      // A JavaScript TypeError: a property write of null or undefined.
      throw TypeError();
    case final JsObjectFace face:
      face.jsWrite(key, value);
    case final Map<dynamic, dynamic> map:
      map[key] = value;
    case final JsClass cls:
      cls[key] = value;
    default:
      throw ArgumentError.value(object, 'object', 'is not a JS object');
  }
}

/// `Object.prototype.hasOwnProperty.call(object, key)`: whether [object]
/// owns [key]. A `Map` owns its keys; a [JsObjectFace] gives
/// [JsObjectFace.jsHas]. Any other value gives false.
bool jsHasOwn(Object? object, String key) => switch (object) {
  final JsObjectFace face => face.jsHas(key),
  final Map<dynamic, dynamic> map => map.containsKey(key),
  _ => false,
};

/// `delete object[key]`: removes the own property [key] of [object] and
/// returns whether [object] owned it. A `Map` removes the key; a
/// [JsObjectFace] gives [JsObjectFace.jsDelete]. Any other value gives
/// false.
bool jsDeleteKey(Object? object, String key) {
  switch (object) {
    case final JsObjectFace face:
      return face.jsDelete(key);
    case final Map<dynamic, dynamic> map:
      if (!map.containsKey(key)) return false;
      map.remove(key);
      return true;
  }
  return false;
}

/// `object[key]`: the value of the property [key] of [object].
///
/// A key that is not a `String` is its `ToString` ([jsToString]), as the
/// `ToPropertyKey` of a number or a boolean gives.
///
/// - A [JsObjectFace] (a typed object of Chart.js ADR 0054):
///   [JsObjectFace.jsRead]. A resolver of `helpers.config`
///   ([JsProxyObject]) gives its `get` trap; its `has` trap does not know
///   the prefixed keys.
/// - Another `Map`: the value of [key], or [undefined] for a key that the
///   Map does not contain. A Map that answers `operator []` for a key that
///   it does not contain models an inherited property.
/// - A `List` or a `String`: the element at a canonical array index, as a
///   String of one code unit for a String, and `length` as a `double`. Any
///   other key gives [undefined].
/// - A [JsClass]: the static property `C[key]` through the static prototype
///   chain ([JsClass.operator []], Chart.js ADR 0020, section 2).
/// - Any other value: [undefined]. A Dart value has none of the members that
///   a JavaScript primitive or function inherits.
///
/// Throws a [TypeError] for `null` and [undefined], where JavaScript throws
/// a `TypeError`.
// DIVERGES(chartjs): js-semantics-resolver-objects, Map, List, String, class.
Object? jsGet(Object? object, Object? key) {
  final name = key is String ? key : jsToString(key);
  switch (object) {
    case null || Undefined():
      // A JavaScript TypeError: a property read of null or undefined.
      throw TypeError();
    case final JsObjectFace face:
      return face.jsRead(name);
    // `<dynamic, dynamic>` matches the same values as `<Object?, Object?>`,
    // but dart2wasm tests it without a compare of the type arguments, which
    // is about 10 ns for each read. Do not change it back.
    case final Map<dynamic, dynamic> map:
      final Object? value = map[name];
      return value == null && !map.containsKey(name) ? undefined : value;
    case final List<dynamic> list:
      if (name == 'length') return list.length.toDouble();
      final index = _index(name, list.length);
      return index == null ? undefined : list[index];
    case final String string:
      if (name == 'length') return string.length.toDouble();
      final index = _index(name, string.length);
      return index == null ? undefined : string[index];
    case final JsClass value:
      return value[name];
  }
  return undefined;
}

/// The index that [key] names in a List or String of [length]: a canonical
/// array index ([jsArrayIndex]) below [length], or null.
int? _index(String key, int length) {
  final index = jsArrayIndex(key);
  return index != null && index < length ? index : null;
}

/// `object[key]` for a property name [key]: the result of [jsGet] for every
/// value (Chart.js ADR 0036).
///
/// A Map is read inline: the value of [key], or [undefined] for a key that
/// the Map does not contain. Every other value goes to [jsGet]: a typed
/// object gives its face, a List or a String its index or `length`, and
/// `null` and [undefined] throw a [TypeError].
///
/// Use it for the reads of parsed items, data items and stack objects. A
/// read of a resolver stays [jsGet] (Chart.js ADR 0017, section 8).
Object? jsGetKey(Object? object, String key) {
  // `<dynamic, dynamic>`: see the comment of jsGet.
  if (object is Map<dynamic, dynamic>) {
    final Object? value = object[key];
    return value == null && !object.containsKey(key) ? undefined : value;
  }
  return jsGet(object, key);
}

/// `object[index]` for a number [index] (Chart.js ADR 0036): for a List,
/// the item at a whole [index] below the length, else [undefined]; for
/// another value, [jsGet].
///
/// The `ToPropertyKey` of a number gives an array index only for a whole
/// number in range. -0 gives the key `'0'`. NaN, a fraction, a negative
/// number and a number past the end give [undefined].
Object? jsGetIndex(Object? object, double index) {
  if (object is List<Object?>) {
    if (index >= 0 && index < object.length) {
      final i = index.toInt();
      if (i == index) return object[i];
    }
    return undefined;
  }
  return jsGet(object, index);
}

/// A Dart object that `Object.freeze` can freeze (Chart.js ADR 0021,
/// section 5).
///
/// In the frozen state, the object behaves as a frozen object in strict
/// mode, the mode of an ES module: a write throws a [TypeError]. The
/// options objects of `lib/src/elements/element_options.dart` implement it.
abstract interface class JsFreezable {
  /// `Object.isFrozen(this)`.
  bool get isFrozen;

  /// `Object.freeze(this)`. A later write throws a [TypeError]. No member
  /// clears the frozen state.
  void freeze();
}

/// A plain object with the frozen state of `Object.freeze` (Chart.js ADR
/// 0021, section 5): a `Map<String, Object?>`, the plain object of the
/// runtime.
///
/// The compiled theme keeps an object under a key with no option kind in
/// it (Chart.js ADR 0054 §18). In the frozen state, a write throws a
/// [TypeError], as a write into a frozen object in strict mode does. The
/// reads do not change.
final class JsFrozenMap extends MapBase<String, Object?>
    implements JsFreezable {
  /// A plain object with the entries of [map], in its key order. The object
  /// keeps [map] and is not frozen yet.
  JsFrozenMap(this._map);

  /// The entries, in insertion order.
  final Map<String, Object?> _map;

  bool _frozen = false;

  @override
  bool get isFrozen => _frozen;

  @override
  void freeze() {
    _frozen = true;
  }

  @override
  Object? operator [](Object? key) => _map[key];

  @override
  void operator []=(String key, Object? value) {
    // A JavaScript TypeError: a write into a frozen object.
    if (_frozen) throw TypeError();
    _map[key] = value;
  }

  @override
  bool containsKey(Object? key) => _map.containsKey(key);

  @override
  Object? remove(Object? key) {
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen && _map.containsKey(key)) throw TypeError();
    return _map.remove(key);
  }

  @override
  Iterable<String> get keys => _map.keys;

  @override
  int get length => _map.length;

  @override
  void clear() {
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen && _map.isNotEmpty) throw TypeError();
    _map.clear();
  }
}

/// `Object.freeze(value)`: freezes a [JsFreezable], then returns [value].
/// Another value returns with no change (core.datasetController.js:831).
///
/// JavaScript freezes each object. The port freezes only a [JsFreezable].
/// No upstream code writes into the objects of the other `Object.freeze`
/// sites after the freeze (core.datasetController.js:858,
/// core.layouts.js:395, plugin.tooltip.js:519).
// DIVERGES(chartjs): js-semantics-object-freeze, only a JsFreezable freezes.
T jsObjectFreeze<T>(T value) {
  if (value is JsFreezable) value.freeze();
  return value;
}

/// `Object.isFrozen(value)` (core.datasetController.tests.js:975, :997,
/// :1018).
///
/// The frozen state of a [JsFreezable]. True for Dart `null`, [undefined], a
/// number, a string and a boolean, as for a JavaScript primitive. False for
/// each other value, also for a `Map.unmodifiable`.
// DIVERGES(chartjs): js-semantics-object-freeze, only a JsFreezable freezes.
bool jsObjectIsFrozen(Object? value) => switch (value) {
  final JsFreezable object => object.isFrozen,
  null || Undefined() || num() || String() || bool() => true,
  _ => false,
};

/// `typeof value`: the type name of [value] (ECMAScript 13.5.3).
///
/// - The [undefined] sentinel gives `'undefined'`.
/// - A `bool` gives `'boolean'`, a `num` gives `'number'` and a `String`
///   gives `'string'`.
/// - A value for which [jsIsFunction] is true gives `'function'`: a Dart
///   `Function`, a `JsFunction` and a class value ([JsClass], Chart.js ADR
///   0020, section 2).
/// - Dart `null` (JS `null`) and every other value give `'object'`.
///
/// `new Animation` selects its interpolator by this name
/// (core.animation.js:35).
String jsTypeof(Object? value) => switch (value) {
  Undefined() => 'undefined',
  bool() => 'boolean',
  num() => 'number',
  String() => 'string',
  _ when jsIsFunction(value) => 'function',
  _ => 'object',
};
