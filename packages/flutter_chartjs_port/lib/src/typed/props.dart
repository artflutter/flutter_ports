// Original code, not ported from Chart.js: the equality of the typed config.

/// The value semantics of the config classes of the typed API (Chart.js ADR
/// 0052, section 1): `==`, `hashCode` and the diagnostics of each class come
/// from one property list, so no code generator runs.
///
/// Each config class has a private getter `_props`: the [TypedProperty] of
/// each field, in the order of the constructor parameters. `==` compares the
/// values with `==`. The compare rules of section 9 of the ADR come from
/// the value that the class puts in the list:
/// - a field value: `==`. A List and a Map of the app compare by identity,
///   because Dart `==` of a List or a Map is identity. Thus `data`,
///   `points`, `labels` and `plugins` compare by identity. A function
///   compares with Dart `==`: a tear-off of a method of one object is `==`
///   to the same tear-off.
/// - [byItems]: the items of a List compare by `==`, in order. The small
///   style Lists (`backgroundColors`, `borderDash`) and the dataset List
///   use it.
/// - [byEntries]: the entries of a Map compare by `==`, in key order, and a
///   value that is a Map compares by its entries too. The `scales` Map and
///   the `extra` Maps use it. Lists in the Map compare by identity, as the
///   lowering passes them by reference.
/// - [byPresence]: only `null` or not. The callbacks that the lowering
///   wraps in a trampoline use it: the trampoline reads the newest callback
///   at each call.
///
/// Internal: no public library exports it.
library;

import 'package:flutter/foundation.dart'
    show
        DiagnosticPropertiesBuilder,
        DiagnosticsProperty,
        immutable,
        listEquals;

/// One property of a config class: the name of its field and the value
/// that `==` compares.
typedef TypedProperty = (String name, Object? value);

/// Whether the values of [a] and [b] are `==`, each with each.
bool propsEqual(List<TypedProperty> a, List<TypedProperty> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].$2 != b[i].$2) return false;
  }
  return true;
}

/// The hash code of the values of [props], consistent with [propsEqual].
int propsHash(List<TypedProperty> props) =>
    Object.hashAll([for (final (_, value) in props) value]);

/// Adds a [DiagnosticsProperty] for each property of [props] to
/// [properties]. A `null` value is the default and shows only at the
/// fine level.
void addProps(
  DiagnosticPropertiesBuilder properties,
  List<TypedProperty> props,
) {
  for (final (name, value) in props) {
    properties.add(
      DiagnosticsProperty<Object?>(name, value, defaultValue: null),
    );
  }
}

/// The value of [list] that compares its items by `==`, or `null`.
Object? byItems(List<Object?>? list) => list == null ? null : _Items(list);

/// The value of [map] that compares its entries by `==` in key order, or
/// `null`. A value that is a Map compares by its entries too.
Object? byEntries(Map<Object?, Object?>? map) =>
    map == null ? null : _Entries(map);

/// The value of [callback] that compares only `null` or not: `null` or
/// [_present].
Object? byPresence(Function? callback) => callback == null ? null : _present;

/// The value of a callback that is present.
const Object _present = _Present();

/// The diagnostics form of a callback that is present.
@immutable
final class _Present {
  const _Present();

  @override
  String toString() => 'set';
}

/// A List that compares its items by `==`.
@immutable
final class _Items {
  const _Items(this.list);

  final List<Object?> list;

  @override
  bool operator ==(Object other) =>
      other is _Items && listEquals(list, other.list);

  @override
  int get hashCode => Object.hashAll(list);

  @override
  String toString() => list.toString();
}

/// A Map that compares its entries by `==` in key order. A value that is a
/// Map compares by its entries too.
@immutable
final class _Entries {
  const _Entries(this.map);

  final Map<Object?, Object?> map;

  @override
  bool operator ==(Object other) =>
      other is _Entries && _entriesEqual(map, other.map);

  @override
  int get hashCode => _entriesHash(map);

  @override
  String toString() => map.toString();
}

/// Whether [a] and [b] have the same keys in the same order and `==`
/// values, with the Map values compared by their entries.
bool _entriesEqual(Map<Object?, Object?> a, Map<Object?, Object?> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  final keysA = a.keys.iterator;
  final keysB = b.keys.iterator;
  while (keysA.moveNext() && keysB.moveNext()) {
    final key = keysA.current;
    if (key != keysB.current) return false;
    final valueA = a[key];
    final valueB = b[key];
    if (valueA is Map<Object?, Object?> && valueB is Map<Object?, Object?>) {
      if (!_entriesEqual(valueA, valueB)) return false;
    } else if (valueA != valueB) {
      return false;
    }
  }
  return true;
}

/// The hash code of the entries of [map], consistent with [_entriesEqual].
int _entriesHash(Map<Object?, Object?> map) => Object.hashAll([
  for (final MapEntry(:key, :value) in map.entries) ...[
    key,
    if (value is Map<Object?, Object?>) _entriesHash(value) else value,
  ],
]);
