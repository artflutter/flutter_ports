// Ported from d3-array v3.2.4 src/every.js (ISC, Mike Bostock).

/// Port of `src/every.js` of d3-array 3.2.4.
library;

/// Returns `true` if [test] returns `true` for every element of [values].
bool every<T>(
  Iterable<T> values,
  bool Function(T value, int index, Iterable<T> values) test,
) {
  var index = -1;
  for (final value in values) {
    if (!test(value, ++index, values)) return false;
  }
  return true;
}
