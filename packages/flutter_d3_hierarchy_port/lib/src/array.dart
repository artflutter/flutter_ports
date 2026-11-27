// Ported from d3-hierarchy v3.1.2 src/array.js (ISC, Mike Bostock).

/// Port of `src/array.js` of d3-hierarchy 3.1.2.
library;

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, generic typed list
// conversion and Fisher-Yates shuffle without JS dynamic array-like checks.

/// Returns [x] if it is already a [List<T>], otherwise copies it into a new
/// growable [List<T>].
@pragma('vm:prefer-inline')
List<T> hierarchyArray<T>(Iterable<T> x) => x is List<T> ? x : List<T>.of(x);

/// Shuffles [array] in-place using [random] and returns [array].
List<T> hierarchyShuffle<T>(List<T> array, double Function() random) {
  var m = array.length;
  while (m > 0) {
    final i = (random() * m--).toInt();
    final t = array[m];
    array[m] = array[i];
    array[i] = t;
  }
  return array;
}
