// Original code, not ported from Chart.js: the JS property read.

/// The JavaScript property read `object[key]` (`[[Get]]`) over the Dart
/// values that stand for JavaScript values (Chart.js ADR 0006).
library;

import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';

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
/// - Any other value: [undefined]. A Dart value has none of the members that
///   a JavaScript primitive or function inherits.
///
/// Throws a [TypeError] for `null` and [undefined], where JavaScript throws
/// a `TypeError`.
// DIVERGES(chartjs): js-semantics-resolver-objects, Map, List, String only.
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
  }
  return undefined;
}

/// The index that [key] names in a List or String of [length]: a canonical
/// array index ([jsArrayIndex]) below [length], or null.
int? _index(String key, int length) {
  final index = jsArrayIndex(key);
  return index != null && index < length ? index : null;
}
