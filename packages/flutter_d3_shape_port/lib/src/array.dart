// Ported from d3-shape v3.2.0 src/array.js (ISC, Mike Bostock).

/// Port of `src/array.js` of d3-shape 3.2.0.
library;

/// `array.js:3` default export: returns [x] directly when it is already a
/// [List], or materializes a fixed-length [List] copy from any [Iterable].
@pragma('vm:prefer-inline')
List<T> shapeArray<T>(Iterable<T> x) =>
    x is List<T> ? x : List<T>.of(x, growable: false);
