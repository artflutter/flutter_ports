// Ported from d3-array v3.2.4 src/filter.js (ISC, Mike Bostock).

/// Port of `src/filter.js` of d3-array 3.2.4.
library;

/// Returns a new [List] containing the elements of [values] for which [test]
/// returns `true`.
List<T> filter<T>(
  Iterable<T> values,
  bool Function(T value, int index, Iterable<T> values) test,
) {
  final array = <T>[];
  var index = -1;
  for (final value in values) {
    if (test(value, ++index, values)) {
      array.add(value);
    }
  }
  return array;
}
