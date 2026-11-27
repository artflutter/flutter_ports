// Ported from d3-geo v3.1.1 src/constant.js (ISC, Mike Bostock).

/// Port of `src/constant.js` of d3-geo 3.1.1.
library;

/// `constant.js:1` default export: returns a function that always returns [x].
// DIVERGES(d3-geo): adapt-geo-typed-api, geo*-prefixed helper avoids bundle
// symbol collisions.
T Function() geoConstant<T>(T x) =>
    () => x;
