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

import 'dart:collection' show MapBase;

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsArrayIndex;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/opt.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/scope_kinds.g.dart';

export 'package:flutter_chartjs_port/src/options/opt.dart';
export 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
export 'package:flutter_chartjs_port/src/options/scope_kinds.g.dart';

/// A typed option scope: the fields of its kind, the own-key order and the
/// extras (Chart.js ADR 0054 §3).
///
/// It implements [JsObjectFace], the face by name. During the migration it
/// also extends `MapBase<String, Object?>` (the scaffolding of Chart.js ADR
/// 0054 §5), so that the readers by name of today read it as a Map: the
/// Map members follow the Map rules (`operator []` gives Dart `null` for an
/// absent key, as a Map read) over the same own keys. The close step of the
/// migration removes the scaffolding.
abstract base class OptionScope extends MapBase<String, Object?>
    implements OptionObject, JsObjectFace {
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
  /// scope does not own it. A routed key gives the cell of its routed value
  /// ([addRoute]).
  Opt<Object?>? lookup(Object key) {
    final k = _normalize(key);
    final own = _own(k);
    final names = _routeNames;
    if (names == null) return own;
    final name = k is OptionKey ? k.jsName : k as String;
    final index = names.indexOf(name);
    if (index < 0) return own;
    return classifyName(name, _routes![index].read(own?.raw ?? undefined));
  }

  /// The own cell of the normalized key [k], without its route.
  Opt<Object?>? _own(Object k) {
    if (k is OptionKey) return cellOf(k);
    final index = _extraIndex(k as String);
    return index < 0 ? null : _extraCells![index];
  }

  /// The own cell of [key] (an [OptionKey] or a name), without its route:
  /// the local value of a routed key (the hidden `_<name>` of
  /// core.defaults.js:136-140).
  Opt<Object?>? ownCell(Object key) => _own(_normalize(key));

  /// The names of the routed keys. Dart `null` before the first route.
  List<String>? _routeNames;

  /// The routes, at the index of their name in [_routeNames].
  List<ScopeRoute>? _routes;

  /// The route of the key [name], or Dart `null`.
  ScopeRoute? routeOf(String name) {
    final index = _routeNames?.indexOf(name) ?? -1;
    return index < 0 ? null : _routes![index];
  }

  /// core.defaults.js:130-157 `route`, on this scope object: the key [name]
  /// reads [route] at each access (Chart.js ADR 0054 §3).
  ///
  /// The local value is the value of [name] at the call (also through an
  /// earlier route), or `undefined` when the scope does not own it. It stays
  /// the own cell of [name]: a set of [name] sets it, as the setter of the
  /// routed property does. A name that the scope did not own goes to the end
  /// of the keys. A name that already has a route that is not configurable
  /// throws a [TypeError] (`Object.defineProperties`), after the local value
  /// is stored, as `Defaults.route` does. A route of a name that the scope
  /// did not own before its first route is not configurable.
  void addRoute(String name, ScopeRoute route) {
    final owned = owns(name);
    final local = owned ? jsRead(name) : undefined;
    final previous = routeOf(name);
    store(name, classifyName(name, local));
    if (previous != null && !previous.configurable) {
      // A JavaScript TypeError: "Cannot redefine property".
      throw TypeError();
    }
    final configured = ScopeRoute(
      route.read,
      targetScope: route.targetScope,
      targetName: route.targetName,
      configurable: previous?.configurable ?? owned,
    );
    final names = _routeNames ??= <String>[];
    final routes = _routes ??= <ScopeRoute>[];
    final index = names.indexOf(name);
    if (index < 0) {
      names.add(name);
      routes.add(configured);
    } else {
      routes[index] = configured;
    }
  }

  /// Removes the route of [name].
  void _removeRoute(String name) {
    final index = _routeNames?.indexOf(name) ?? -1;
    if (index < 0) return;
    _routeNames!.removeAt(index);
    _routes!.removeAt(index);
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
  ///
  /// A routed key that is not configurable throws a [TypeError] ("Cannot
  /// delete property", strict mode). The delete of a configurable routed key
  /// removes its route.
  bool delete(Object key) {
    final k = _normalize(key);
    if (_routeNames != null) {
      final name = k is OptionKey ? k.jsName : k as String;
      final route = routeOf(name);
      if (route != null) {
        // A JavaScript TypeError: "Cannot delete property".
        if (!route.configurable) throw TypeError();
        _removeRoute(name);
      }
    }
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

  /// The own key names in their order (`Object.keys`): the array-index
  /// names first, in ascending order, then the other names in their
  /// insertion order, as JS orders the own keys of an object.
  @override
  List<String> jsKeys() {
    final names = [
      for (final key in _order)
        if (key is OptionKey) key.jsName else key as String,
    ];
    final extras = _extraNames;
    if (extras == null || !extras.any((name) => jsArrayIndex(name) != null)) {
      return names;
    }
    final indices = [
      for (final name in names)
        if (jsArrayIndex(name) case final int index) (index, name),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [
      for (final (_, name) in indices) name,
      for (final name in names)
        if (jsArrayIndex(name) == null) name,
    ];
  }

  /// The kind of a nested scope under the name [name]: the `scope` atom of
  /// a declared key, else the `scope` atom of `others`, else Dart `null`.
  ScopeKind? childKindFor(String name) {
    final k = keyOf(name);
    return k is OptionKey ? kind.childKind(k) : kind.othersKind;
  }

  /// The cell of the raw JS value [raw] for the name [name] in this scope:
  /// by the shape of a declared key, else by the shape `others` of the kind.
  Opt<Object?> classifyName(String name, Object? raw) {
    final k = keyOf(name);
    return k is OptionKey ? classify(k, raw) : kind.classifyOther(raw);
  }

  /// `object[name]` (`[[Get]]`): the JS value of [name], or [undefined]
  /// when the scope does not own it.
  @override
  Object? jsRead(String name) {
    final cell = lookup(name);
    return cell == null ? undefined : cell.raw;
  }

  /// `object[name] = value` (`[[Set]]`): stores the cell of [value].
  @override
  void jsWrite(String name, Object? value) {
    store(name, classifyName(name, value));
  }

  /// `name in object` for an own key (`hasOwnProperty`).
  @override
  bool jsHas(String name) => owns(name);

  /// `delete object[name]`. Returns whether the scope owned it.
  @override
  bool jsDelete(String name) => delete(name);

  // The Map scaffolding of Chart.js ADR 0054 §5.

  /// The Map read: the JS value of an own key ([undefined] for an own key
  /// with the value `undefined`), else Dart `null`.
  @override
  Object? operator [](Object? key) => key is String ? lookup(key)?.raw : null;

  /// The Map write: [jsWrite].
  @override
  void operator []=(String key, Object? value) => jsWrite(key, value);

  /// The own keys ([jsKeys]).
  @override
  Iterable<String> get keys => jsKeys();

  @override
  int get length => _order.length;

  @override
  bool get isEmpty => _order.isEmpty;

  @override
  bool get isNotEmpty => _order.isNotEmpty;

  @override
  bool containsKey(Object? key) => key is String && owns(key);

  /// Deletes [key] and returns its value, or Dart `null` for an absent key.
  @override
  Object? remove(Object? key) {
    if (key is! String) return null;
    final value = this[key];
    delete(key);
    return value;
  }

  /// Deletes each own key.
  @override
  void clear() => ownKeys.forEach(delete);

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

  /// The state of the scope for the defaults restore of the test harness
  /// (`setUpDefaultsRestore` of `chartjs_test_utils`): the key order, the
  /// own cells and the routes.
  ScopeState saveState() => ScopeState._(
    List<Object>.of(_order),
    [for (final key in _order) _own(key)!],
    List<String>.of(_routeNames ?? const []),
    List<ScopeRoute>.of(_routes ?? const []),
  );

  /// Whether the scope holds [state]: the same keys in the same order, the
  /// same cells and the same routes.
  bool hasState(ScopeState state) {
    if (_order.length != state._order.length) return false;
    for (var i = 0; i < _order.length; i++) {
      if (_order[i] != state._order[i]) return false;
      final cell = _own(_order[i]);
      final saved = state._cells[i];
      if (!identical(cell, saved) &&
          !(cell.runtimeType == saved.runtimeType &&
              identical(cell?.raw, saved.raw))) {
        return false;
      }
    }
    final names = _routeNames ?? const <String>[];
    final routes = _routes ?? const <ScopeRoute>[];
    if (names.length != state._routeNames.length) return false;
    for (var i = 0; i < names.length; i++) {
      if (names[i] != state._routeNames[i] ||
          !identical(routes[i], state._routes[i])) {
        return false;
      }
    }
    return true;
  }

  /// Puts back [state] ([saveState]).
  void restoreState(ScopeState state) {
    for (final key in _order) {
      if (key is OptionKey) setCell(key, null);
    }
    _order.clear();
    _extraNames = null;
    _extraCells = null;
    for (var i = 0; i < state._order.length; i++) {
      final key = state._order[i];
      final cell = state._cells[i];
      _order.add(key);
      if (key is OptionKey) {
        setCell(key, cell);
      } else {
        (_extraNames ??= <String>[]).add(key as String);
        (_extraCells ??= <Opt<Object?>>[]).add(cell);
      }
    }
    _routeNames = state._routeNames.isEmpty
        ? null
        : List<String>.of(state._routeNames);
    _routes = state._routes.isEmpty ? null : List<ScopeRoute>.of(state._routes);
  }

  @override
  String toString() => '${kind.typeName}Scope(${jsKeys().join(', ')})';
}

/// A route of a key of a typed scope (core.defaults.js:130-157).
final class ScopeRoute {
  /// A route that gives the routed value of a local value with [read].
  const ScopeRoute(
    this.read, {
    required this.targetScope,
    required this.targetName,
    this.configurable = false,
  });

  /// The getter of the routed property: the routed value of the local
  /// value (the local value, the target value, or a merge of both objects).
  final Object? Function(Object? local) read;

  /// The target scope object of the route.
  final Object? targetScope;

  /// The key of the target scope that the route reads.
  final String targetName;

  /// Whether the scope owned the key before its first route: then a delete
  /// of the key removes the route. Else the delete throws.
  final bool configurable;
}

/// The saved state of a typed scope ([OptionScope.saveState]).
final class ScopeState {
  ScopeState._(this._order, this._cells, this._routeNames, this._routes);

  final List<Object> _order;
  final List<Opt<Object?>> _cells;
  final List<String> _routeNames;
  final List<ScopeRoute> _routes;

  /// The raw values of the own cells, for the walk of the snapshot.
  Iterable<Object?> get values => _cells.map((cell) => cell.raw);

  /// The target scopes of the routes, for the walk of the snapshot.
  Iterable<Object?> get routeTargets => _routes.map((r) => r.targetScope);
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
