// Ported from d3-contour v4.0.2 src/array.js (ISC, Mike Bostock).

/// Port of `src/array.js` of d3-contour 4.0.2.
library;

/// Returns a shallow copy of [list], optionally sliced from [start] to [end].
// DIVERGES(d3-contour): adapt-contour-typed-api, contour-prefixed typed helper.
@pragma('vm:prefer-inline')
List<T> contourArraySlice<T>(List<T> list, [int start = 0, int? end]) =>
    list.sublist(start, end);
