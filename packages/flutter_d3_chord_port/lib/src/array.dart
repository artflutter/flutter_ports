// Ported from d3-chord v3.0.1 src/array.js (ISC, Mike Bostock).

/// Port of `src/array.js` of d3-chord 3.0.1.
library;

/// `array.js:1` `slice`: returns a shallow copy of [list] from [start] to
/// [end].
// DIVERGES(d3-chord): adapt-chord-typed-api, typed List slice helper.
List<T> chordArraySlice<T>(List<T> list, [int start = 0, int? end]) =>
    list.sublist(start, end);
