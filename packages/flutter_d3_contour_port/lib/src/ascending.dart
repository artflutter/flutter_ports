// Ported from d3-contour v4.0.2 src/ascending.js (ISC, Mike Bostock).

/// Port of `src/ascending.js` of d3-contour 4.0.2.
library;

/// Ascending numeric comparator for contour threshold sorting.
// DIVERGES(d3-contour): adapt-contour-typed-api, contour-prefixed int
// comparator compatible with `List.sort`, avoiding collision with `d3-array`'s
// `ascending`.
@pragma('vm:prefer-inline')
int contourAscending(double a, double b) => a < b ? -1 : (a > b ? 1 : 0);
