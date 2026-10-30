// Original code, not ported from Chart.js: the base of the typed option scopes.

/// The base of the typed option scopes (Chart.js ADR 0054 §3).
///
/// A typed scope is the typed form of one JS options object of the port:
/// `Chart.defaults` and its nested objects, `Chart.overrides`, the
/// descriptors, the statics of the components and the merged scale configs.
/// The generated subclasses of `scopes.g.dart` (one for each kind of
/// `tool/options_schema.yaml`) have one typed field of an [Opt] cell for each
/// key of the kind. This base class keeps the rest of the JS object:
/// - the own-key order, the insertion order of JS (a set of an absent key
///   appends it, a delete removes it);
/// - the extras: the keys that the kind does not declare, by name, in their
///   insertion order;
/// - the face: `jsRead`, `jsWrite`, `jsHas`, `jsDelete` and `jsKeys`, the
///   reads and writes by name of user code, of the raw boundary and of the
///   tests (Chart.js ADR 0054 §5). The face is a cold path.
///
/// A key is an [OptionKey] or a `String`. A `String` that names a key of the
/// kind is that key; any other name is an extra. An [OptionKey] that the kind
/// does not declare is an extra under its JS name.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/opt.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/scope_kinds.g.dart';

export 'package:flutter_chartjs_port/src/options/opt.dart';
export 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
export 'package:flutter_chartjs_port/src/options/scope_kinds.g.dart';

/// A typed option scope: the fields of its kind, the own-key order and the
/// extras (Chart.js ADR 0054 §3).
abstract base class OptionScope implements OptionObject {
  /// An empty scope.
  OptionScope();

  /// The kind of the scope (`tool/options_schema.yaml`).
  ScopeKind get kind;

  /// The cell of the declared key [key], or Dart `null` when the scope does
  /// not own it. A key that the kind does not declare gives Dart `null`.
  Opt<Object?>? cellOf(OptionKey key);

  /// Writes [cell] to the field of the declared key [key]. Dart `null`
  /// clears the field. It does not change the key order: use [store] and
  /// [delete].
  void setCell(OptionKey key, Opt<Object?>? cell);

  /// Whether the kind declares [key].
  bool hasField(OptionKey key);

  /// The cell of the raw JS value [raw] for the declared key [key], by the
  /// shape of the key.
  Opt<Object?> classify(OptionKey key, Object? raw);

  /// The own keys in their order: an [OptionKey] for a declared key, a
  /// `String` for an extra.
  final List<Object> _order = <Object>[];

  /// The names of the extras, in their insertion order. Dart `null` before
  /// the first extra.
  List<String>? _extraNames;

  /// The cells of the extras, at the index of their name in [_extraNames].
  List<Opt<Object?>>? _extraCells;

  /// The key of the name [name] in this scope: its [OptionKey] when the kind
  /// declares it, else [name].
  Object keyOf(String name) {
    final key = optionKeyOf(name);
    return key != null && hasField(key) ? key : name;
  }

  /// [key] in the form of this scope: a declared [OptionKey], or the name of
  /// an extra.
  Object _normalize(Object key) => switch (key) {
    final OptionKey k => hasField(k) ? k : k.jsName,
    final String name => keyOf(name),
    _ => throw ArgumentError.value(key, 'key', 'Not an OptionKey or a String'),
  };

  /// The index of the extra [name], or -1.
  int _extraIndex(String name) => _extraNames?.indexOf(name) ?? -1;

  /// The cell of [key] (an [OptionKey] or a name), or Dart `null` when the
  /// scope does not own it.
  Opt<Object?>? lookup(Object key) {
    final k = _normalize(key);
    if (k is OptionKey) return cellOf(k);
    final index = _extraIndex(k as String);
    return index < 0 ? null : _extraCells![index];
  }

  /// Whether the scope owns [key] (an own property, also with the value
  /// `undefined`).
  bool owns(Object key) => lookup(key) != null;

  /// Stores [cell] for [key] (an [OptionKey] or a name). An absent key goes
  /// to the end of the key order, as a JS property set does.
  void store(Object key, Opt<Object?> cell) {
    final k = _normalize(key);
    if (k is OptionKey) {
      if (cellOf(k) == null) _order.add(k);
      setCell(k, cell);
      return;
    }
    final name = k as String;
    final index = _extraIndex(name);
    if (index >= 0) {
      _extraCells![index] = cell;
      return;
    }
    (_extraNames ??= <String>[]).add(name);
    (_extraCells ??= <Opt<Object?>>[]).add(cell);
    _order.add(name);
  }

  /// Deletes [key] (an [OptionKey] or a name), as the JS `delete` does.
  /// Returns whether the scope owned it.
  bool delete(Object key) {
    final k = _normalize(key);
    if (k is OptionKey) {
      if (cellOf(k) == null) return false;
      setCell(k, null);
      _order.remove(k);
      return true;
    }
    final name = k as String;
    final index = _extraIndex(name);
    if (index < 0) return false;
    _extraNames!.removeAt(index);
    _extraCells!.removeAt(index);
    _order.remove(name);
    return true;
  }

  /// The own keys in their order: an [OptionKey] for a declared key, a
  /// `String` for an extra. The list is a copy.
  List<Object> get ownKeys => List<Object>.of(_order);

  /// The count of the own keys.
  int get ownKeyCount => _order.length;

  /// The own key names in their order (`Object.keys`).
  List<String> jsKeys() => [
    for (final key in _order)
      if (key is OptionKey) key.jsName else key as String,
  ];

  /// The cell of the raw JS value [raw] for the name [name] in this scope:
  /// by the shape of a declared key, else by the shape `others` of the kind.
  Opt<Object?> classifyName(String name, Object? raw) {
    final k = keyOf(name);
    return k is OptionKey ? classify(k, raw) : kind.classifyOther(raw);
  }

  /// `object[name]` (`[[Get]]`): the JS value of [name], or [undefined]
  /// when the scope does not own it.
  Object? jsRead(String name) {
    final cell = lookup(name);
    return cell == null ? undefined : cell.raw;
  }

  /// `object[name] = value` (`[[Set]]`): stores the cell of [value].
  void jsWrite(String name, Object? value) {
    store(name, classifyName(name, value));
  }

  /// `name in object` for an own key (`hasOwnProperty`).
  bool jsHas(String name) => owns(name);

  /// `delete object[name]`. Returns whether the scope owned it.
  bool jsDelete(String name) => delete(name);

  /// A new scope of the same kind with each own key in the same order. A
  /// nested typed scope is cloned, a nested raw Map and an array are copied
  /// deep, as `helpers.clone` does (helpers.core.ts:159); every other value
  /// stays the same object.
  OptionScope cloneScope() {
    final copy = kind.create();
    for (final key in _order) {
      copy.store(key, cloneCell(lookup(key)!));
    }
    return copy;
  }

  @override
  String toString() => '${kind.typeName}Scope(${jsKeys().join(', ')})';
}

/// [cell] as a cell of the type `T` of a field: [cell] itself when it is an
/// `Opt<T>`, else the cell of its raw value by [classify] (a cell of another
/// kind with another type for the same key name). Dart `null` stays null.
Opt<T>? fitCell<T>(
  Opt<Object?>? cell,
  Opt<T> Function(Object? raw) classify,
) => switch (cell) {
  null => null,
  final Opt<T> fit => fit,
  _ => classify(cell.raw),
};

/// The deep copy of [cell] for [OptionScope.cloneScope].
Opt<T> cloneCell<T>(Opt<T> cell) => switch (cell) {
  OptScope(:final scope) => OptScope<T>(cloneValue(scope)!),
  OptList(:final items) => OptList<T>(cloneValue(items)! as List<Object?>),
  _ => cell,
};

/// `helpers.clone` (helpers.core.ts:159) for the values of a scope: a typed
/// scope gives its [OptionScope.cloneScope], an array a new array of the
/// clones of its items, a raw Map a new Map of the clones of its values in
/// key order, and any other value itself.
Object? cloneValue(Object? value) => switch (value) {
  final OptionScope scope => scope.cloneScope(),
  final List<Object?> list => <Object?>[
    for (final item in list) cloneValue(item),
  ],
  final Map<String, Object?> map => <String, Object?>{
    for (final MapEntry(:key, :value) in map.entries) key: cloneValue(value),
  },
  _ => value,
};
