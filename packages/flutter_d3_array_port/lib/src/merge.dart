// Ported from d3-array v3.2.4 src/merge.js (ISC, Mike Bostock).

/// Port of `src/merge.js` of d3-array 3.2.4.
library;

/// Merges the specified [iterables] into a single flat [List].
List<T> merge<T>(Iterable<Iterable<T>> iterables) => <T>[
  for (final iterable in iterables) ...iterable,
];
