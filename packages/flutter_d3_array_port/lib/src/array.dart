// Ported from d3-array v3.2.4 src/array.js (ISC, Mike Bostock).

/// Port of `src/array.js` of d3-array 3.2.4.
library;

/// Returns a shallow copy of [list], optionally sliced from [start] to [end].
@pragma('vm:prefer-inline')
List<T> arraySlice<T>(List<T> list, [int start = 0, int? end]) =>
    list.sublist(start, end);
