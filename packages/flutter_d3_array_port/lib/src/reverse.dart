// Ported from d3-array v3.2.4 src/reverse.js (ISC, Mike Bostock).

/// Port of `src/reverse.js` of d3-array 3.2.4.
library;

/// Returns a new [List] containing the elements of [values] in reverse order
/// without mutating [values].
List<T> reverse<T>(Iterable<T> values) {
  if (values is List<T>) {
    final n = values.length;
    return List<T>.generate(n, (i) => values[n - 1 - i]);
  }
  final list = List<T>.of(values);
  final n = list.length;
  for (var i = 0, j = n - 1; i < j; ++i, --j) {
    final t = list[i];
    list[i] = list[j];
    list[j] = t;
  }
  return list;
}
