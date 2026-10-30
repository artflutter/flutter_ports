// Original code, not ported from Chart.js: JS sort and key order as in V8.

/// `Array.prototype.sort` and the key order of `Object.keys` for ported code
/// (Chart.js ADR 0045, "Sort"), `Object.getOwnPropertyNames` (Chart.js
/// ADR 0019, section 1), `Array.prototype.splice` ([jsSplice]), the write
/// `list[index] = value` ([jsSetIndex], Chart.js ADR 0036) and a string as
/// an array-like value ([JsStringList]).
///
/// A JavaScript array is a `List<Object?>` and a plain object is a
/// `Map<String, Object?>` (Chart.js ADR 0043).
library;

import 'dart:collection' show ListBase;

import 'package:collection/collection.dart' show mergeSort;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;

/// `array.sort(compare)`: sorts [list] in place with a stable sort and
/// returns it, as `Array.prototype.sort` does.
///
/// [compare] returns a number, as a JavaScript comparator does. A negative
/// result puts `a` first, a positive result puts `b` first, and `0`, `-0` or
/// NaN keeps the two in their order. Any other number is only its sign, so a
/// comparator such as `(a, b) => a.index - b.index` works unchanged.
///
/// `SortCompare` (ECMAScript 23.1.3.30.2) also moves the `undefined`
/// elements to the end. This function gives an `undefined` element and a
/// hole to [compare] as any other element. A caller whose array can hold
/// them moves them in its comparator: `_holesLast` of `core.controller.dart`
/// (the holes, Dart `null`) and the comparator of `Legend.buildLabels` (an
/// `undefined` item of a user `generateLabels`, `plugin.legend.js:113`).
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
/// `helpers.config` (Chart.js ADR 0043).
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

/// The JS write `list[index] = value` (Chart.js ADR 0036): a write at the
/// length appends.
///
/// JavaScript leaves a hole for an index past the length, and a negative
/// index writes a property (`list[-1] = v` gives the key `'-1'`, and the
/// length does not change). Dart throws a [RangeError] for both
/// (differences.md row `platform-array-events`). `parse` writes the items in
/// order from its start, so its index is never negative. `_resyncElements`
/// gives a start at most the length. `_insertElements` gives the start of
/// the caller of `onDataSplice`, which can be past the length. A negative
/// start fails before the write, at the insert of the elements.
void jsSetIndex<T>(List<T> list, int index, T value) {
  if (index == list.length) {
    list.add(value);
  } else {
    list[index] = value;
  }
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
  if (object case final JsObjectFace face) return face.jsKeys();
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

/// A JavaScript string as an array-like value: the reads `string[i]` and
/// `string.length`.
///
/// `_dataCheck` of the dataset controller keeps a string `data`: a string
/// is not extensible, so it gets no array listener
/// (core.datasetController.js:386). `parse` then reads `data[i]` and
/// `data.length`, and a parsing `false` makes the string the parsed items.
/// This List gives the same reads: the item at index `i` is the UTF-16 code
/// unit `i` of [string] as a String of length 1, and [length] is the count
/// of code units.
///
/// A write throws a [TypeError], as a write into a string in strict mode
/// code does: an index write, a change of the length and each List method
/// that changes the List.
///
/// It stays a `List` for the other checks: `isArray` is true and `typeof` is
/// `'object'`, where JavaScript gives false and `'string'`. No ported reader
/// of `_data` or of the parsed items makes these checks on the List itself.
final class JsStringList extends ListBase<Object?> {
  /// The array-like view of [string].
  JsStringList(this.string);

  /// The JavaScript string.
  final String string;

  @override
  int get length => string.length;

  @override
  set length(int newLength) => throw TypeError();

  @override
  Object? operator [](int index) => string[index];

  @override
  void operator []=(int index, Object? value) => throw TypeError();
}
