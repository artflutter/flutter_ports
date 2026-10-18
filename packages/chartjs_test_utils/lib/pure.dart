// Original code, not ported from Chart.js: the spec set-up for dart test.

/// The spec set-up of the pure-layer specs (porting-flow.md section 3,
/// "`test/index.js` equivalent").
///
/// porting-flow.md section 3 puts the `flutter test` port of Chart.js
/// `test/index.js` in `test/flutter_test_config.dart`. That file does not
/// exist yet. Phase 3 adds it. `dart test` does not read that file. Thus each
/// pure-layer spec file calls [setUpSpecs] first in its `main()`, and runs the
/// same set-up on the VM, dart2js and dart2wasm.
///
/// This library is a pure layer: it imports only `package:test` and the pure
/// layers of `flutter_chartjs` (porting-flow.md section 3).
library;

import 'dart:collection';

// The harness reads the global scopes of core.defaults. flutter_chartjs does
// not export lib/src.
// ignore: implementation_imports
import 'package:flutter_chartjs/src/core/core.defaults.dart';
import 'package:test/test.dart';

/// Sets up the specs of one pure-layer spec file. Call it first in `main()`.
///
/// ```dart
/// void main() {
///   setUpSpecs();
///   group('Chart.helpers.math', () { /* ... */ });
/// }
/// ```
///
/// The set-up restores the global scopes of `core.defaults.js` after each
/// test (porting-flow.md section 1 step 5 and section 3):
/// - A `setUpAll` takes a snapshot of [defaults], [overrides] and
///   [descriptors] after the harness set-up, before the first test of the
///   file.
/// - A `tearDown` restores the snapshot after each test. It runs after the
///   `tearDown` functions of the groups.
///
/// Upstream `test/index.js` restores nothing. A spec that changes the
/// defaults deletes its keys itself. The restore is a port-only addition, so
/// that the order of the spec files does not change their results.
///
/// The snapshot keeps the identity of each object and array in the scopes.
/// The restore puts back the entries of each one in place, in key order. It
/// keeps the `undefined` sentinel, Dart `null` and absent keys apart, and it
/// puts back the routes of each [RoutedScope] and the [RoutedScope] that took
/// the place of each plain object (`Defaults.route`). An object that a test
/// adds leaves the scopes. An object that a test removes or replaces comes
/// back.
void setUpSpecs() {
  late _Snapshot snapshot;
  setUpAll(() {
    snapshot = _Snapshot.take([defaults, overrides, descriptors]);
  });
  tearDown(() {
    snapshot.restore();
  });
}

/// The saved state of the objects and arrays that the global scopes reach.
final class _Snapshot {
  _Snapshot._(this._saved);

  /// Saves each object and array that [roots] reach, once.
  factory _Snapshot.take(List<Object> roots) {
    final saved = <_Saved>[];
    final seen = HashSet<Object>.identity();
    final queue = Queue<Object?>.of(roots);
    while (queue.isNotEmpty) {
      final value = queue.removeFirst();
      if (value == null || !seen.add(value)) continue;
      switch (value) {
        case final RoutedScope scope:
          final entries = scope.ownValues.entries.toList();
          final routes = Map.of(scope.routes);
          saved.add(_SavedRoutedScope(scope, entries, routes));
          queue
            ..addAll(entries.map((entry) => entry.value))
            ..addAll(routes.values.map((route) => route.targetScope));
        case final LinkedHashMap<String, Object?> map:
          final entries = map.entries.toList();
          final replacement = RoutedScope.replacementOf(map);
          saved.add(_SavedMap(map, entries, replacement));
          queue
            ..addAll(entries.map((entry) => entry.value))
            ..add(replacement);
        case final List<Object?> list:
          final items = List.of(list);
          saved.add(_SavedList(list, items));
          queue.addAll(items);
      }
    }
    return _Snapshot._(saved);
  }

  final List<_Saved> _saved;

  /// Puts back the saved state of each object and array.
  void restore() {
    for (final saved in _saved) {
      saved.restore();
    }
  }
}

/// The saved state of one object or array.
sealed class _Saved {
  /// Puts back the saved state, if it changed.
  void restore();
}

/// The own values and routes of a [RoutedScope].
final class _SavedRoutedScope implements _Saved {
  _SavedRoutedScope(this.scope, this.entries, this.routes);

  final RoutedScope scope;
  final List<MapEntry<String, Object?>> entries;
  final Map<String, DefaultsRoute> routes;

  @override
  void restore() {
    if (!_sameEntries(scope.ownValues, entries)) {
      scope.ownValues
        ..clear()
        ..addEntries(entries);
    }
    if (!_sameRoutes(scope.routes, routes)) {
      scope.routes
        ..clear()
        ..addAll(routes);
    }
  }
}

/// The entries of a plain object (a [LinkedHashMap] with `String` keys), and
/// the [RoutedScope] that took its place ([RoutedScope.replacementOf]). A
/// Map with other key types is not an object (Chart.js ADR 0006).
final class _SavedMap implements _Saved {
  _SavedMap(this.map, this.entries, this.replacement);

  final LinkedHashMap<String, Object?> map;
  final List<MapEntry<String, Object?>> entries;
  final RoutedScope? replacement;

  @override
  void restore() {
    if (!identical(RoutedScope.replacementOf(map), replacement)) {
      RoutedScope.setReplacement(map, replacement);
    }
    if (_sameEntries(map, entries)) return;
    map
      ..clear()
      ..addEntries(entries);
  }
}

/// The items of an array.
final class _SavedList implements _Saved {
  _SavedList(this.list, this.items);

  final List<Object?> list;
  final List<Object?> items;

  @override
  void restore() {
    if (list.length == items.length) {
      for (var i = 0; i < items.length; i++) {
        if (!identical(list[i], items[i])) list[i] = items[i];
      }
      return;
    }
    list
      ..clear()
      ..addAll(items);
  }
}

/// Whether [map] holds [entries], in key order, with identical values.
bool _sameEntries<K, V>(Map<K, V> map, List<MapEntry<K, V>> entries) {
  if (map.length != entries.length) return false;
  var i = 0;
  for (final entry in map.entries) {
    final saved = entries[i++];
    if (entry.key != saved.key || !identical(entry.value, saved.value)) {
      return false;
    }
  }
  return true;
}

/// Whether [routes] equal [saved], in key order.
bool _sameRoutes(
  Map<String, DefaultsRoute> routes,
  Map<String, DefaultsRoute> saved,
) {
  if (routes.length != saved.length) return false;
  final keys = saved.keys.iterator;
  for (final MapEntry(:key, :value) in routes.entries) {
    keys.moveNext();
    final route = saved[keys.current];
    if (key != keys.current ||
        route == null ||
        !identical(route.targetScope, value.targetScope) ||
        route.targetName != value.targetName ||
        route.configurable != value.configurable) {
      return false;
    }
  }
  return true;
}
