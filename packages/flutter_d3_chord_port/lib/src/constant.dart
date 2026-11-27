// Ported from d3-chord v3.0.1 src/constant.js (ISC, Mike Bostock).

/// Port of `src/constant.js` of d3-chord 3.0.1.
library;

/// `constant.js:1` default export: returns a function that always returns [x].
// DIVERGES(d3-chord): adapt-chord-typed-api, chord*-prefixed constant helper.
T Function() chordConstant<T>(T x) =>
    () => x;
