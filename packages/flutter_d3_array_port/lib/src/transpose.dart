// Ported from d3-array v3.2.4 src/transpose.js (ISC, Mike Bostock).

/// Port of `src/transpose.js` of d3-array 3.2.4.
library;

/// Transposes the specified [matrix] of lists, truncating to the shortest row.
List<List<T>> transpose<T>(List<List<T>> matrix) {
  final n = matrix.length;
  if (n == 0) return <List<T>>[];
  var m = matrix[0].length;
  for (var j = 1; j < n; ++j) {
    final len = matrix[j].length;
    if (len < m) m = len;
  }
  if (m == 0) return <List<T>>[];
  return List<List<T>>.generate(
    m,
    (i) => List<T>.generate(n, (j) => matrix[j][i]),
  );
}
