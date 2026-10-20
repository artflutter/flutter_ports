// Original code, not ported from Chart.js: JS sort and key order as in V8.

/// `Array.prototype.sort` and the key order of `Object.keys` for ported code
/// (Chart.js ADR 0010, "Sort"), `Object.getOwnPropertyNames` (Chart.js
/// ADR 0019, section 1), and `Array.prototype.splice` ([jsSplice]).
///
/// A JavaScript array is a `List<Object?>` and a plain object is a
/// `Map<String, Object?>` (Chart.js ADR 0006).
library;

import 'package:collection/collection.dart' show mergeSort;

/// `array.sort(compare)`: sorts [list] in place with a stable sort and
/// returns it, as `Array.prototype.sort` does.
///
/// [compare] returns a number, as a JavaScript comparator does. A negative
/// result puts `a` first, a positive result puts `b` first, and `0`, `-0` or
/// NaN keeps the two in their order. Any other number is only its sign, so a
/// comparator such as `(a, b) => a.index - b.index` works unchanged.
///
/// `SortCompare` (ECMAScript 23.1.3.30.2) also moves the `undefined`
/// elements to the end. No sort of upstream gets an `undefined` element, so
/// this function gives such an element to [compare] as any other element.
///
/// The result is the V8 order for a consistent comparator. For an
/// inconsistent comparator, the order is not the V8 order: ECMAScript leaves
/// it to the implementation.
///
/// `List.sort` is not stable above 32 elements on the VM and on dart2wasm.
/// The comparators of `plugin.legend.js:113` and `plugin.tooltip.js:620`
/// expect a stable sort.
List<T> jsSort<T>(List<T> list, num Function(T a, T b) compare) {
  mergeSort<T>(list, compare: (a, b) => _sign(compare(a, b)));
  return list;
}

/// The sign of [result] as -1, 0 or 1, with NaN as 0, as `SortCompare`
/// (ECMAScript 23.1.3.30.2) reads the comparator result.
int _sign(num result) {
  if (result < 0) return -1;
  if (result > 0) return 1;
  return 0;
}

/// A JavaScript `Proxy` object as a `Map<String, Object?>`: the resolvers of
/// `helpers.config` (Chart.js ADR 0006).
///
/// `operator []` is the `get` trap, [Map.containsKey] is the `has` trap and
/// [Map.keys] is the `ownKeys` trap (`Object.getOwnPropertyNames`). The other
/// members of [Map] that enumerate, for example [Map.forEach] and
/// [Map.length], also use the `ownKeys` trap.
abstract interface class JsProxyObject implements Map<String, Object?> {
  /// `Object.keys(proxy)`: the `ownKeys` trap result without the keys that
  /// the `getOwnPropertyDescriptor` trap rejects.
  ///
  /// The keys keep the order of the `ownKeys` trap. The engine does not move
  /// the array-index keys of a proxy to the front.
  List<String> objectKeys();
}

/// `Object.keys(object)`: the keys of [object] in the ECMAScript
/// `OrdinaryOwnPropertyKeys` order.
///
/// For a [JsProxyObject], the result is [JsProxyObject.objectKeys], as the
/// engine gives for a `Proxy`. Ported code calls this function also for
/// `for-in`, `Object.assign` and the object spread over a JavaScript object.
///
/// The array-index keys come first, in ascending numeric order. An
/// array-index key is the canonical string of an integer from 0 to
/// 2^32 - 2: `'0'`, `'7'` or `'4294967294'`, but not `'01'`, `'-1'`, `'1.0'`
/// or `'4294967295'`. The other keys follow in the iteration order of
/// [object]. For a `LinkedHashMap`, the default `Map`, that order is the
/// insertion order, as in JavaScript.
///
/// `Map.keys` gives the insertion order for every key. Ported code that
/// enumerates a JavaScript object calls this function instead: for the keys
/// `'a'` and `'10'`, in that insertion order, it gives `'10'` first, as
/// JavaScript does.
List<String> jsObjectKeys(Map<String, Object?> object) {
  if (object is JsProxyObject) return object.objectKeys();
  final indices = <(int, String)>[];
  final others = <String>[];
  for (final key in object.keys) {
    final index = jsArrayIndex(key);
    if (index == null) {
      others.add(key);
    } else {
      indices.add((index, key));
    }
  }
  if (indices.isEmpty) return others;
  // The indices are distinct integers, so an unstable sort gives one order.
  indices.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final (_, key) in indices) key, ...others];
}

/// `Object.getOwnPropertyNames(object)`: the own string keys of [object]
/// (Chart.js ADR 0019, section 1).
///
/// - A [JsProxyObject] gives its [Map.keys], the `ownKeys` trap. For a
///   resolver of `helpers.config`, these are the keys of all its scopes
///   (`helpers.config.ts:94-96`). [jsObjectKeys] gives fewer keys there: the
///   `getOwnPropertyDescriptor` trap reads only the first scope
///   (`helpers.config.ts:73-75`).
/// - Another Map gives [jsObjectKeys]. Each key of a Map is an own
///   enumerable property, so the two functions agree on it.
///
/// `Animations.configure` (core.animations.js:21) and `hasFunction`
/// (core.config.js:402-403) call it.
List<String> jsOwnPropertyNames(Map<String, Object?> object) =>
    object is JsProxyObject ? object.keys.toList() : jsObjectKeys(object);

/// The largest array index, 2^32 - 2 (ECMAScript 6.1.7).
const int _maxArrayIndex = 4294967294;

/// The array index that [key] names, or null if [key] is not the canonical
/// string of an integer from 0 to 2^32 - 2 (ECMAScript 6.1.7): `'0'`, `'7'`
/// or `'4294967294'`, but not `'01'`, `'-1'`, `'1.0'` or `'4294967295'`.
///
/// A property read or an `in` test of a List or a String also compares the
/// index with the length.
int? jsArrayIndex(String key) {
  final length = key.length;
  // '4294967294' has 10 digits. A canonical index has no leading zero.
  if (length == 0 || length > 10) return null;
  if (length > 1 && key.codeUnitAt(0) == 0x30) return null;
  var index = 0;
  for (var i = 0; i < length; i++) {
    final digit = key.codeUnitAt(i) - 0x30;
    if (digit < 0 || digit > 9) return null;
    index = index * 10 + digit;
  }
  return index <= _maxArrayIndex ? index : null;
}

/// `array.splice(start, deleteCount, ...items)`: removes [deleteCount]
/// elements of [list] from [start], inserts [items] there, and returns the
/// removed elements (ECMAScript 23.1.3.31).
///
/// [start] and [deleteCount] go through `ToIntegerOrInfinity`: NaN gives 0,
/// and a fraction truncates toward zero. A negative [start] counts from the
/// end of [list]. Both values clamp to [list]. Dart `null` for
/// [deleteCount] stands for an absent argument: the removal runs to the end
/// of [list]. The JavaScript `undefined` gives 0, as NaN does.
///
/// `_removeElements` of `core.datasetController.js:1030` and `:1035` calls
/// it with the `start` of `_onDataPop`, which is -1 for an empty dataset.
List<T> jsSplice<T>(
  List<T> list,
  double start, [
  double? deleteCount,
  List<T> items = const [],
]) {
  final length = list.length;
  final relativeStart = _toIntegerOrInfinity(start);
  final int actualStart;
  if (relativeStart < 0) {
    final fromEnd = length + relativeStart;
    actualStart = fromEnd > 0 ? fromEnd.toInt() : 0;
  } else {
    actualStart = relativeStart < length ? relativeStart.toInt() : length;
  }
  final int actualDeleteCount;
  if (deleteCount == null) {
    actualDeleteCount = length - actualStart;
  } else {
    final count = _toIntegerOrInfinity(deleteCount);
    final rest = length - actualStart;
    actualDeleteCount = count <= 0
        ? 0
        : count < rest
        ? count.toInt()
        : rest;
  }
  final end = actualStart + actualDeleteCount;
  final removed = list.sublist(actualStart, end);
  list.replaceRange(actualStart, end, items);
  return removed;
}

/// `ToIntegerOrInfinity(value)` (ECMAScript 7.1.5) of a number: NaN gives 0,
/// an infinity gives itself, and another value truncates toward zero.
double _toIntegerOrInfinity(double value) =>
    value.isNaN ? 0 : value.truncateToDouble();
