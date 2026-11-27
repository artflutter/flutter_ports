// Ported from d3-array v3.2.4 src/group.js (ISC, Mike Bostock).

/// Port of `src/group.js` of d3-array 3.2.4.
///
/// Provides strongly typed 1-, 2-, and 3-level grouping, rollup, indexing, and
/// flattening functions returning native Dart `Map<K, V>` and typed record
/// lists without untyped recursive `Map<dynamic, dynamic>` (D3 ADR 0017).
library;

T _unique<T>(List<T> values) {
  if (values.length != 1) throw StateError('duplicate key');
  return values[0];
}

// ---------------------------------------------------------------------------
// 1-level group / groups / flatGroup
// ---------------------------------------------------------------------------

/// Groups [values] into a [Map] keyed by [key], preserving insertion order.
// DIVERGES(d3-array): adapt-array-typed-api, strongly typed fixed-arity
// group/group2/group3, rollup/rollup2/rollup3, index/index2/index3, and
// flatGroup*/flatRollup* returning native value-equal Dart Map/records.
// DIVERGES(d3-array): adapt-array-fast-forms, direct single-pass map building
// without intermediate wrapper closures.
Map<K, List<T>> group<T, K>(Iterable<T> values, K Function(T value) key) {
  final map = <K, List<T>>{};
  if (values is List<T>) {
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      final k = key(v);
      final bucket = map[k];
      if (bucket != null) {
        bucket.add(v);
      } else {
        map[k] = <T>[v];
      }
    }
    return map;
  }
  for (final v in values) {
    final k = key(v);
    final bucket = map[k];
    if (bucket != null) {
      bucket.add(v);
    } else {
      map[k] = <T>[v];
    }
  }
  return map;
}

/// Groups [values] using an indexed key accessor `(value, index, values)`.
Map<K, List<T>> groupIndexed<T, K>(
  Iterable<T> values,
  K Function(T value, int index, Iterable<T> values) key,
) {
  final map = <K, List<T>>{};
  var index = -1;
  for (final v in values) {
    final k = key(v, ++index, values);
    final bucket = map[k];
    if (bucket != null) {
      bucket.add(v);
    } else {
      map[k] = <T>[v];
    }
  }
  return map;
}

/// Groups [values] by [key] and returns `(key, group)` entries.
List<(K, List<T>)> groups<T, K>(Iterable<T> values, K Function(T value) key) {
  final map = group<T, K>(values, key);
  return <(K, List<T>)>[for (final e in map.entries) (e.key, e.value)];
}

/// Groups [values] by indexed [key] and returns `(key, group)` entries.
List<(K, List<T>)> groupsIndexed<T, K>(
  Iterable<T> values,
  K Function(T value, int index, Iterable<T> values) key,
) {
  final map = groupIndexed<T, K>(values, key);
  return <(K, List<T>)>[for (final e in map.entries) (e.key, e.value)];
}

/// Returns a flat list of `(key, group)` records (1-level [flatGroup]).
List<(K, List<T>)> flatGroup<T, K>(
  Iterable<T> values,
  K Function(T value) key,
) => groups<T, K>(values, key);

// ---------------------------------------------------------------------------
// 2-level group2 / groups2 / flatGroup2
// ---------------------------------------------------------------------------

/// Groups [values] into a 2-level nested [Map] keyed by [key1], then [key2].
Map<K1, Map<K2, List<T>>> group2<T, K1, K2>(
  Iterable<T> values,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
) {
  final outer = group<T, K1>(values, key1);
  return <K1, Map<K2, List<T>>>{
    for (final e in outer.entries) e.key: group<T, K2>(e.value, key2),
  };
}

/// Groups [values] into a 2-level nested entry list keyed by [key1], then
/// [key2].
List<(K1, List<(K2, List<T>)>)> groups2<T, K1, K2>(
  Iterable<T> values,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
) {
  final outer = group<T, K1>(values, key1);
  return <(K1, List<(K2, List<T>)>)>[
    for (final e in outer.entries) (e.key, groups<T, K2>(e.value, key2)),
  ];
}

/// Groups [values] by [key1] and [key2] into flat `(key1, key2, group)`
/// records.
List<(K1, K2, List<T>)> flatGroup2<T, K1, K2>(
  Iterable<T> values,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
) {
  final outer = group<T, K1>(values, key1);
  return <(K1, K2, List<T>)>[
    for (final e1 in outer.entries)
      for (final e2 in group<T, K2>(e1.value, key2).entries)
        (e1.key, e2.key, e2.value),
  ];
}

// ---------------------------------------------------------------------------
// 3-level group3 / groups3 / flatGroup3
// ---------------------------------------------------------------------------

/// Groups [values] into a 3-level nested [Map] keyed by [key1], [key2], [key3].
Map<K1, Map<K2, Map<K3, List<T>>>> group3<T, K1, K2, K3>(
  Iterable<T> values,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
  K3 Function(T value) key3,
) {
  final outer = group<T, K1>(values, key1);
  return <K1, Map<K2, Map<K3, List<T>>>>{
    for (final e in outer.entries)
      e.key: group2<T, K2, K3>(e.value, key2, key3),
  };
}

/// Groups [values] into a 3-level nested entry list keyed by [key1], [key2],
/// [key3].
List<(K1, List<(K2, List<(K3, List<T>)>)>)> groups3<T, K1, K2, K3>(
  Iterable<T> values,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
  K3 Function(T value) key3,
) {
  final outer = group<T, K1>(values, key1);
  return <(K1, List<(K2, List<(K3, List<T>)>)>)>[
    for (final e in outer.entries)
      (e.key, groups2<T, K2, K3>(e.value, key2, key3)),
  ];
}

/// Groups [values] by [key1], [key2], [key3] into flat
/// `(key1, key2, key3, group)` records.
List<(K1, K2, K3, List<T>)> flatGroup3<T, K1, K2, K3>(
  Iterable<T> values,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
  K3 Function(T value) key3,
) {
  final outer = group<T, K1>(values, key1);
  return <(K1, K2, K3, List<T>)>[
    for (final e1 in outer.entries)
      for (final e2 in group<T, K2>(e1.value, key2).entries)
        for (final e3 in group<T, K3>(e2.value, key3).entries)
          (e1.key, e2.key, e3.key, e3.value),
  ];
}

// ---------------------------------------------------------------------------
// 1-, 2-, 3-level rollup / rollups / flatRollup
// ---------------------------------------------------------------------------

/// Groups [values] by [key] and reduces each group with [reduce].
Map<K, R> rollup<T, K, R>(
  Iterable<T> values,
  R Function(List<T> group) reduce,
  K Function(T value) key,
) {
  final grouped = group<T, K>(values, key);
  return <K, R>{for (final e in grouped.entries) e.key: reduce(e.value)};
}

/// Groups [values] by indexed [key] and reduces each group with [reduce].
Map<K, R> rollupIndexed<T, K, R>(
  Iterable<T> values,
  R Function(List<T> group) reduce,
  K Function(T value, int index, Iterable<T> values) key,
) {
  final grouped = groupIndexed<T, K>(values, key);
  return <K, R>{for (final e in grouped.entries) e.key: reduce(e.value)};
}

/// Groups [values] by [key], reduces each group with [reduce], and returns
/// `(key, value)` entries.
List<(K, R)> rollups<T, K, R>(
  Iterable<T> values,
  R Function(List<T> group) reduce,
  K Function(T value) key,
) {
  final grouped = group<T, K>(values, key);
  return <(K, R)>[for (final e in grouped.entries) (e.key, reduce(e.value))];
}

/// Groups [values] by indexed [key], reduces each group with [reduce], and
/// returns `(key, value)` entries.
List<(K, R)> rollupsIndexed<T, K, R>(
  Iterable<T> values,
  R Function(List<T> group) reduce,
  K Function(T value, int index, Iterable<T> values) key,
) {
  final grouped = groupIndexed<T, K>(values, key);
  return <(K, R)>[for (final e in grouped.entries) (e.key, reduce(e.value))];
}

/// Returns a flat list of `(key, reduced)` records (1-level [flatRollup]).
List<(K, R)> flatRollup<T, K, R>(
  Iterable<T> values,
  R Function(List<T> group) reduce,
  K Function(T value) key,
) => rollups<T, K, R>(values, reduce, key);

/// Groups [values] by [key1] and [key2] and reduces each leaf group with
/// [reduce].
Map<K1, Map<K2, R>> rollup2<T, K1, K2, R>(
  Iterable<T> values,
  R Function(List<T> group) reduce,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
) {
  final outer = group<T, K1>(values, key1);
  return <K1, Map<K2, R>>{
    for (final e in outer.entries)
      e.key: rollup<T, K2, R>(e.value, reduce, key2),
  };
}

/// Groups [values] by [key1] and [key2], reduces each leaf group with [reduce],
/// and returns nested entry lists.
List<(K1, List<(K2, R)>)> rollups2<T, K1, K2, R>(
  Iterable<T> values,
  R Function(List<T> group) reduce,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
) {
  final outer = group<T, K1>(values, key1);
  return <(K1, List<(K2, R)>)>[
    for (final e in outer.entries)
      (e.key, rollups<T, K2, R>(e.value, reduce, key2)),
  ];
}

/// Groups [values] by [key1] and [key2], reduces each leaf group with [reduce],
/// and returns flat `(key1, key2, reduced)` records.
List<(K1, K2, R)> flatRollup2<T, K1, K2, R>(
  Iterable<T> values,
  R Function(List<T> group) reduce,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
) {
  final outer = group<T, K1>(values, key1);
  return <(K1, K2, R)>[
    for (final e1 in outer.entries)
      for (final e2 in group<T, K2>(e1.value, key2).entries)
        (e1.key, e2.key, reduce(e2.value)),
  ];
}

/// Groups [values] by [key1], [key2], and [key3] and reduces each leaf group
/// with [reduce].
Map<K1, Map<K2, Map<K3, R>>> rollup3<T, K1, K2, K3, R>(
  Iterable<T> values,
  R Function(List<T> group) reduce,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
  K3 Function(T value) key3,
) {
  final outer = group<T, K1>(values, key1);
  return <K1, Map<K2, Map<K3, R>>>{
    for (final e in outer.entries)
      e.key: rollup2<T, K2, K3, R>(e.value, reduce, key2, key3),
  };
}

/// Groups [values] by [key1], [key2], and [key3], reduces each leaf group with
/// [reduce], and returns nested entry lists.
List<(K1, List<(K2, List<(K3, R)>)>)> rollups3<T, K1, K2, K3, R>(
  Iterable<T> values,
  R Function(List<T> group) reduce,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
  K3 Function(T value) key3,
) {
  final outer = group<T, K1>(values, key1);
  return <(K1, List<(K2, List<(K3, R)>)>)>[
    for (final e in outer.entries)
      (e.key, rollups2<T, K2, K3, R>(e.value, reduce, key2, key3)),
  ];
}

/// Groups [values] by [key1], [key2], and [key3], reduces each leaf group with
/// [reduce], and returns flat `(key1, key2, key3, reduced)` records.
List<(K1, K2, K3, R)> flatRollup3<T, K1, K2, K3, R>(
  Iterable<T> values,
  R Function(List<T> group) reduce,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
  K3 Function(T value) key3,
) {
  final outer = group<T, K1>(values, key1);
  return <(K1, K2, K3, R)>[
    for (final e1 in outer.entries)
      for (final e2 in group<T, K2>(e1.value, key2).entries)
        for (final e3 in group<T, K3>(e2.value, key3).entries)
          (e1.key, e2.key, e3.key, reduce(e3.value)),
  ];
}

// ---------------------------------------------------------------------------
// 1-, 2-, 3-level index / indexes
// ---------------------------------------------------------------------------

/// Indexes [values] into a [Map] by unique [key], throwing [StateError] on
/// duplicate keys.
Map<K, T> index<T, K>(Iterable<T> values, K Function(T value) key) {
  final map = <K, T>{};
  for (final v in values) {
    final k = key(v);
    if (map.containsKey(k)) throw StateError('duplicate key');
    map[k] = v;
  }
  return map;
}

/// Indexes [values] into a [Map] by unique indexed [key].
Map<K, T> indexIndexed<T, K>(
  Iterable<T> values,
  K Function(T value, int index, Iterable<T> values) key,
) {
  final map = <K, T>{};
  var i = -1;
  for (final v in values) {
    final k = key(v, ++i, values);
    if (map.containsKey(k)) throw StateError('duplicate key');
    map[k] = v;
  }
  return map;
}

/// Indexes [values] by unique [key] and returns `(key, value)` entries.
List<(K, T)> indexes<T, K>(Iterable<T> values, K Function(T value) key) {
  final map = index<T, K>(values, key);
  return <(K, T)>[for (final e in map.entries) (e.key, e.value)];
}

/// Indexes [values] by unique indexed [key] and returns `(key, value)` entries.
List<(K, T)> indexesIndexed<T, K>(
  Iterable<T> values,
  K Function(T value, int index, Iterable<T> values) key,
) {
  final map = indexIndexed<T, K>(values, key);
  return <(K, T)>[for (final e in map.entries) (e.key, e.value)];
}

/// Indexes [values] into a 2-level [Map] keyed by [key1], then unique [key2].
Map<K1, Map<K2, T>> index2<T, K1, K2>(
  Iterable<T> values,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
) => rollup2<T, K1, K2, T>(values, _unique<T>, key1, key2);

/// Indexes [values] into a 2-level entry list keyed by [key1], then unique
/// [key2].
List<(K1, List<(K2, T)>)> indexes2<T, K1, K2>(
  Iterable<T> values,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
) => rollups2<T, K1, K2, T>(values, _unique<T>, key1, key2);

/// Indexes [values] into a 3-level [Map] keyed by [key1], [key2], and unique
/// [key3].
Map<K1, Map<K2, Map<K3, T>>> index3<T, K1, K2, K3>(
  Iterable<T> values,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
  K3 Function(T value) key3,
) => rollup3<T, K1, K2, K3, T>(values, _unique<T>, key1, key2, key3);

/// Indexes [values] into a 3-level entry list keyed by [key1], [key2], and
/// unique [key3].
List<(K1, List<(K2, List<(K3, T)>)>)> indexes3<T, K1, K2, K3>(
  Iterable<T> values,
  K1 Function(T value) key1,
  K2 Function(T value) key2,
  K3 Function(T value) key3,
) => rollups3<T, K1, K2, K3, T>(values, _unique<T>, key1, key2, key3);
