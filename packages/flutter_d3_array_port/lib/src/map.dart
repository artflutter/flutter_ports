// Ported from d3-array v3.2.4 src/map.js (ISC, Mike Bostock).

/// Port of `src/map.js` of d3-array 3.2.4.
library;

/// Returns a new [List] containing the mapped values of [values] produced by
/// [mapper].
List<R> map<T, R>(
  Iterable<T> values,
  R Function(T value, int index, Iterable<T> values) mapper,
) {
  final array = <R>[];
  var index = -1;
  for (final value in values) {
    array.add(mapper(value, ++index, values));
  }
  return array;
}
