// Ported from Chart.js v4.6.1 src/helpers/helpers.collection.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.collection.ts`.
///
/// A JavaScript array is a [List] and a plain object is a
/// `Map<String, Object?>` (Chart.js ADR 0043). The `{lo, hi}` results of the
/// binary searches are records of two list indices. Thus they are `int`
/// values (Chart.js ADR 0045, "Translation rules").
///
/// A Dart [List] has no methods that a program can redefine. Thus
/// [listenArrayEvents] does not hook `push`, `pop`, `shift`, `splice` and
/// `unshift`. It keeps the listeners of the array, and [notifyArrayListeners]
/// gives them the calls that the hooked methods give upstream
/// (differences.md `platform-array-events`).
library;

import 'dart:collection';

import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show capitalize;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart'
    show AxisKey, ParsedItem;
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:meta/meta.dart';

/// helpers.collection.ts:10 `_lookup`.
///
/// Binary search
///
/// [table] is the table to search. It must be sorted! [value] is the value
/// to find. [cmp] gets an index of [table]. Without [cmp], the search
/// compares the entries of [table] with [value] as the JavaScript `<` does
/// for a number: through ToNumber ([jsToNumber]).
///
/// The result is an immutable record. Upstream returns a new object on each
/// call. A caller that changes a field of the result builds a new record
/// with the changed field, for example `core.interaction.js:46` and `:53`
/// (`result.lo -= …`, `result.hi += …`).
({int lo, int hi}) lookup(
  List<Object?> table,
  double value, [
  bool Function(int index)? cmp,
]) {
  // Upstream reassigns its parameter.
  cmp ??= (index) => jsToNumber(table[index]) < value;
  var hi = table.length - 1;
  var lo = 0;
  int mid;

  while (hi - lo > 1) {
    mid = (lo + hi) >> 1;
    if (cmp(mid)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }

  return (lo: lo, hi: hi);
}

/// The JavaScript read `table[index][key]` of [lookupByKey] and
/// [rlookupByKey].
///
/// The callers search two kinds of tables:
/// - plain objects: `meta._parsed` (helpers.extras.ts:103, :119), the
///   `{time, pos}` table of scale.timeseries.js:18, :24 and the data of
///   plugin.decimation.js:186, :189. An entry is a [Map] (Chart.js ADR 0043
///   gives `Map<String, Object?>`, and user data can have other type
///   arguments). The read gives the value of an own key, else [undefined].
/// - elements: the point elements of helpers.extras.ts:105, :121, and the
///   `meta.data` elements of any type in core.interaction.js:28-59. An entry
///   is an [Element]. The read gives [Element.x] for `'x'` and [Element.y]
///   for `'y'`, else [undefined].
///
/// A parsed item of the typed model ([ParsedItem], Chart.js ADR 0054 §8)
/// gives its typed axis value. [jsGet] reads every other entry that is not
/// an [Element]: an item of the user data (`parsing: false`). An [Element]
/// is a Dart object, not a Map, so it has its own branch. A key of these tables
/// is never `length` or an array index. Thus any other entry gives
/// [undefined]. `null` and [undefined] throw a [TypeError], as JavaScript
/// does.
Object? _readKey(Object? entry, String key) {
  if (entry is ParsedItem) return entry.valueOf(AxisKey.of(key), key);
  if (entry is Element) {
    return switch (key) {
      'x' => entry.x,
      'y' => entry.y,
      _ => undefined,
    };
  }
  return jsGet(entry, key);
}

/// helpers.collection.ts:50 `_lookupByKey`.
///
/// Binary search
///
/// [table] is the table to search. It must be sorted! [key] is the property
/// name for the value in each entry, read as [_readKey] describes. [value]
/// is the value to find. [last] looks up the last index.
///
/// The `<` comparison converts the entry value with [jsToNumber], as the
/// JavaScript `<` does with a number operand. The `===` comparison is `==`
/// of the entry value and [value]: it is false for a value that is not a
/// number, and for NaN.
({int lo, int hi}) lookupByKey(
  List<Object?> table,
  String key,
  double value, [
  // The upstream signature has a positional `last`.
  // ignore: avoid_positional_boolean_parameters
  bool last = false,
]) => lookup(
  table,
  value,
  last
      ? (index) {
          final ti = _readKey(table[index], key);
          return jsToNumber(ti) < value ||
              ti == value && _readKey(table[index + 1], key) == value;
        }
      : (index) => jsToNumber(_readKey(table[index], key)) < value,
);

/// helpers.collection.ts:70 `_rlookupByKey`.
///
/// Reverse binary search
///
/// [table] is the table to search. It must be sorted! [key] is the property
/// name for the value in each entry, read as [_readKey] describes. [value]
/// is the value to find.
({int lo, int hi}) rlookupByKey(
  List<Object?> table,
  String key,
  double value,
) => lookup(
  table,
  value,
  (index) => jsToNumber(_readKey(table[index], key)) >= value,
);

/// helpers.collection.ts:84 `_filterBetween`.
///
/// Return subset of [values] between [min] and [max] inclusive.
/// Values are assumed to be in sorted order.
///
/// It returns [values] itself when no value is outside the range, as
/// upstream does.
List<double> filterBetween(List<double> values, double min, double max) {
  var start = 0;
  var end = values.length;

  while (start < end && values[start] < min) {
    start++;
  }
  while (end > start && values[end - 1] > max) {
    end--;
  }

  return start > 0 || end < values.length ? values.sublist(start, end) : values;
}

/// helpers.collection.ts:100 `arrayEvents`.
const List<String> _arrayEvents = ['push', 'pop', 'shift', 'splice', 'unshift'];

/// helpers.collection.ts:102 `ArrayListener`.
///
/// The members are optional upstream: [notifyArrayListeners] calls a member
/// only when it is a function. Here each member has an empty default body,
/// which gives the same result. Mix this class in and override the members
/// that the listener needs.
abstract mixin class ArrayListener<T> {
  /// helpers.collection.ts:103 `_onDataPush?(...item: T[])`.
  @internal
  void onDataPush(List<T> items) {}

  /// helpers.collection.ts:104 `_onDataPop?()`.
  @internal
  void onDataPop() {}

  /// helpers.collection.ts:105 `_onDataShift?()`.
  @internal
  void onDataShift() {}

  /// helpers.collection.ts:106 `_onDataSplice?(index, deleteCount,
  /// ...items)`.
  @internal
  void onDataSplice(double index, double deleteCount, List<T> items) {}

  /// helpers.collection.ts:107 `_onDataUnshift?(...item: T[])`.
  @internal
  void onDataUnshift(List<T> items) {}
}

/// The `_chartjs` stub of helpers.collection.ts:125-127: the listeners of
/// one array.
final class _ChartjsStub {
  _ChartjsStub(this.listeners);

  /// The `listeners` array of the stub.
  final List<_StubListener> listeners;
}

/// One item of the `listeners` array of the `_chartjs` stub.
///
/// JavaScript calls a listener whatever the element type of the array.
/// Thus the item keeps the element type `T` of the [listenArrayEvents]
/// call in [notify]. [notifyArrayListeners] calls [notify] and does no
/// cast.
final class _StubListener {
  _StubListener(this.listener, this.notify);

  /// The listener object. [unlistenArrayEvents] compares it with
  /// [identical].
  final Object listener;

  /// Calls the `_onData*` member of [listener] for a method with its
  /// arguments.
  final void Function(String method, List<Object?> args) notify;
}

/// The [_StubListener] of [listener], with the element type `T`.
_StubListener _stubListener<T>(ArrayListener<T> listener) => _StubListener(
  listener,
  (method, args) => _callListener<T>(listener, method, args),
);

/// The call `object[method](...args)` of helpers.collection.ts:142.
///
/// A JavaScript number is a [double] (Chart.js ADR 0045). Thus a [num]
/// item becomes a [double], and the `index` and `deleteCount` of
/// `'splice'` go through [jsToNumber]. The VM, dart2js and dart2wasm then
/// give the same items.
void _callListener<T>(
  ArrayListener<T> object,
  String method,
  List<Object?> args,
) {
  List<T> items(Iterable<Object?> values) => List<T>.from(
    values.map((value) => value is num ? value.toDouble() : value),
  );
  switch (method) {
    case 'onDataPush':
      object.onDataPush(items(args));
    case 'onDataPop':
      object.onDataPop();
    case 'onDataShift':
      object.onDataShift();
    case 'onDataSplice':
      object.onDataSplice(
        jsToNumber(args[0]),
        jsToNumber(args[1]),
        items(args.skip(2)),
      );
    case 'onDataUnshift':
      object.onDataUnshift(items(args));
  }
}

/// The non-enumerable property `_chartjs` that helpers.collection.ts:122
/// defines on an array. An [Expando] attaches the stub to the [List]
/// without a change to the list.
final Expando<_ChartjsStub> _chartjs = Expando<_ChartjsStub>('_chartjs');

/// helpers.collection.ts:115 `listenArrayEvents`.
///
/// Hooks the array methods that add or remove values ('push', pop',
/// 'shift', 'splice', 'unshift') and notify the listener AFTER the array has
/// been altered. Listeners are called on the '_onData*' callbacks (e.g.
/// _onDataPush, etc.) with same arguments.
///
/// Dart cannot hook the methods of a [List]. The code that alters [array]
/// calls [notifyArrayListeners] after the change (differences.md
/// `platform-array-events`).
void listenArrayEvents<T>(List<T> array, ArrayListener<T> listener) {
  final stub = _chartjs[array];
  if (stub != null) {
    stub.listeners.add(_stubListener(listener));
    return;
  }

  _chartjs[array] = _ChartjsStub(<_StubListener>[_stubListener(listener)]);

  // DIVERGES(chartjs): platform-array-events, no List method hooks.
}

/// The body of each method that helpers.collection.ts:130-149 hooks, after
/// the call of the original method: the call of each listener of [array].
///
/// Call it AFTER the array has been altered, with the [key] of the method
/// (`'push'`, `'pop'`, `'shift'`, `'splice'` or `'unshift'`) and its
/// arguments [args]. Each listener gets the items with the element type of
/// its [listenArrayEvents] call, whatever the static type of [array] here.
/// An [int] argument is a JavaScript number: the listener gets a [double].
/// It does nothing for an array without listeners, as the original method
/// does not notify.
///
/// A `'splice'` call needs at least two arguments: `index` and
/// `deleteCount`. Upstream also notifies `splice(start)` and `splice()`, and
/// `_onDataSplice` then reads `arguments.length - 2` as a negative count
/// (core.datasetController.js:1064-1071). [ArrayListener.onDataSplice] has
/// no form for that count. Thus fewer than two arguments throw an
/// [ArgumentError] (differences.md `platform-array-events`). The caller
/// passes the `deleteCount` that the change used.
///
/// The loop is `Array.prototype.forEach`: it visits the listeners that the
/// array had at the start, and skips the ones that a listener removed.
void notifyArrayListeners(List<Object?> array, String key, List<Object?> args) {
  // DIVERGES(chartjs): platform-array-events, the hooked method body.
  if (key == 'splice' && args.length < 2) {
    throw ArgumentError.value(
      args,
      'args',
      'A splice notification needs index and deleteCount',
    );
  }
  final stub = _chartjs[array];
  if (stub == null || !_arrayEvents.contains(key)) {
    return;
  }
  final method = 'onData${capitalize(key)}';
  final listeners = stub.listeners;
  final length = listeners.length;
  for (var k = 0; k < length && k < listeners.length; k++) {
    listeners[k].notify(method, args);
  }
}

/// helpers.collection.ts:157 `unlistenArrayEvents`.
///
/// Removes the given array event listener and cleanup extra attached
/// properties (such as the _chartjs stub and overridden methods) if array
/// doesn't have any more listeners.
///
/// `indexOf` compares with `===`: here with [identical].
void unlistenArrayEvents<T>(List<T> array, ArrayListener<T> listener) {
  final stub = _chartjs[array];
  if (stub == null) {
    return;
  }

  final listeners = stub.listeners;
  final index = listeners.indexWhere(
    (object) => identical(object.listener, listener),
  );
  if (index != -1) {
    listeners.removeAt(index);
  }

  if (listeners.isNotEmpty) {
    return;
  }

  // DIVERGES(chartjs): platform-array-events, no List method hooks to delete.

  _chartjs[array] = null;
}

/// helpers.collection.ts:184 `_arrayUnique`.
///
/// `new Set(items)` compares with SameValueZero: a [LinkedHashSet] with
/// [_sameValueZero] does the same. It keeps the first of equal items, in
/// insertion order. `Set.prototype.add` stores `-0` as `+0`: [_setValue]
/// does the same. It returns [items] itself when all items differ, as
/// upstream does. Then a `-0` stays `-0`.
List<T> arrayUnique<T>(List<T> items) {
  final set = LinkedHashSet<T>(
    equals: _sameValueZero,
    hashCode: _sameValueZeroHash,
  )..addAll(items.map(_setValue));

  if (set.length == items.length) {
    return items;
  }

  return set.toList();
}

/// The value that `Set.prototype.add` (ECMAScript 24.2.4.1) stores: `+0`
/// for `-0`, else [value].
T _setValue<T>(T value) =>
    value is double && value == 0 && value.isNegative ? 0.0 as T : value;

/// SameValueZero (ECMAScript 7.2.11) for the Dart values of Chart.js ADR
/// 0043: numbers by value, with NaN equal to NaN and `0` equal to `-0`,
/// strings by content, and every other value by identity.
bool _sameValueZero(Object? a, Object? b) {
  if (a is num && b is num) {
    return a == b || (a.isNaN && b.isNaN);
  }
  if (a is String && b is String) {
    return a == b;
  }
  return identical(a, b);
}

/// A hash code that agrees with [_sameValueZero].
int _sameValueZeroHash(Object? value) {
  if (value is num) {
    return value.isNaN || value == 0 ? 0 : value.toDouble().hashCode;
  }
  if (value is String) {
    return value.hashCode;
  }
  return identityHashCode(value);
}
