// Ported from d3-array v3.2.4 src/pairs.js (ISC, Mike Bostock).

/// Port of `src/pairs.js` of d3-array 3.2.4.
library;

/// Returns the 2-tuple record `(a, b)`.
// DIVERGES(d3-array): adapt-array-typed-api, returns a typed (T, T) record
// instead of a 2-element JS array.
@pragma('vm:prefer-inline')
(T, T) pair<T>(T a, T b) => (a, b);

/// Returns a list of adjacent pairs `(previous, current)` from [values].
List<(T, T)> pairs<T>(Iterable<T> values) {
  final result = <(T, T)>[];
  late T previous;
  var hasPrevious = false;
  for (final value in values) {
    if (hasPrevious) result.add((previous, value));
    previous = value;
    hasPrevious = true;
  }
  return result;
}

/// Returns a list of adjacent pairs from [values] combined using [pairof].
List<R> pairsWith<T, R>(Iterable<T> values, R Function(T a, T b) pairof) {
  final result = <R>[];
  late T previous;
  var hasPrevious = false;
  for (final value in values) {
    if (hasPrevious) result.add(pairof(previous, value));
    previous = value;
    hasPrevious = true;
  }
  return result;
}
