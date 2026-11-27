// Ported from d3-array v3.2.4 src/permute.js (ISC, Mike Bostock).

/// Port of `src/permute.js` of d3-array 3.2.4.
library;

/// Returns a permutation of [source] using the specified integer [keys].
// DIVERGES(d3-array): adapt-array-typed-api, split typed List permute,
// out-of-bounds permuteNullable, and Map-keyed permuteMap.
List<T> permute<T>(List<T> source, Iterable<int> keys) {
  if (keys is List<int>) {
    final n = keys.length;
    return List<T>.generate(n, (i) => source[keys[i]]);
  }
  return <T>[for (final key in keys) source[key]];
}

/// Returns a permutation of [source] using integer [keys], producing `null`
/// for out-of-range indices (matching JavaScript array indexing).
List<T?> permuteNullable<T>(List<T> source, Iterable<int> keys) {
  final len = source.length;
  return <T?>[
    for (final key in keys)
      if (key >= 0 && key < len) source[key] else null,
  ];
}

/// Returns a permutation of values from [source] map for the specified [keys].
List<V?> permuteMap<K, V>(Map<K, V> source, Iterable<K> keys) => <V?>[
  for (final key in keys) source[key],
];
