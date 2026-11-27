// Ported from d3-array v3.2.4 src/reduce.js (ISC, Mike Bostock).

/// Port of `src/reduce.js` of d3-array 3.2.4.
library;

/// Applies [reducer] against an accumulator initialized to [initialValue] and
/// each element of [values] to reduce it to a single value of type `R`.
// DIVERGES(d3-array): adapt-array-typed-api, split typed reduce (with
// initialValue) and reduceFirst (without initialValue, returning T?).
R reduce<T, R>(
  Iterable<T> values,
  R Function(R accumulator, T value, int index, Iterable<T> values) reducer,
  R initialValue,
) {
  var value = initialValue;
  var index = -1;
  for (final next in values) {
    value = reducer(value, next, ++index, values);
  }
  return value;
}

/// Applies [reducer] to [values] using the first element as initial
/// accumulator, or returns `null` if [values] is empty.
T? reduceFirst<T>(
  Iterable<T> values,
  T Function(T accumulator, T value, int index, Iterable<T> values) reducer,
) {
  final iterator = values.iterator;
  if (!iterator.moveNext()) return null;
  var value = iterator.current;
  var index = 0;
  while (iterator.moveNext()) {
    value = reducer(value, iterator.current, ++index, values);
  }
  return value;
}
