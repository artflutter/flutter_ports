// Ported from d3-array v3.2.4 src/some.js (ISC, Mike Bostock).

/// Port of `src/some.js` of d3-array 3.2.4.
library;

/// Returns `true` if [test] returns `true` for at least one element of
/// [values].
bool some<T>(
  Iterable<T> values,
  bool Function(T value, int index, Iterable<T> values) test,
) {
  var index = -1;
  for (final value in values) {
    if (test(value, ++index, values)) return true;
  }
  return false;
}
