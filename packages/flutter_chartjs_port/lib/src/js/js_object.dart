// Original code, not ported from Chart.js: JS property read and Object.freeze.

/// The JavaScript property read `object[key]` (`[[Get]]`) over the Dart
/// values that stand for JavaScript values (Chart.js ADR 0006), its forms
/// for a property name and a number index (Chart.js ADR 0036), the frozen
/// state of `Object.freeze` (Chart.js ADR 0021, section 5), and the `typeof`
/// operator (Chart.js ADR 0019, section 1).
library;

import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsIsFunction;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// `object[key]`: the value of the property [key] of [object].
///
/// A key that is not a `String` is its `ToString` ([jsToString]), as the
/// `ToPropertyKey` of a number or a boolean gives.
///
/// - A [JsProxyObject] (a resolver of `helpers.config`): its `get` trap,
///   `operator []`. Its `has` trap does not know the prefixed keys.
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
    case final JsProxyObject proxy:
      return proxy[name];
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
/// A Map that is not a [JsProxyObject] is read inline: the value of [key],
/// or [undefined] for a key that the Map does not contain. Every other value
/// goes to [jsGet]: a resolver gives its `get` trap, a List or a String its
/// index or `length`, and `null` and [undefined] throw a [TypeError].
///
/// Use it for the reads of parsed items, data items and stack objects. A
/// read of a resolver stays [jsGet] (Chart.js ADR 0017, section 8).
Object? jsGetKey(Object? object, String key) {
  // `<dynamic, dynamic>`: see the comment of jsGet.
  if (object is Map<dynamic, dynamic> && object is! JsProxyObject) {
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
