// Ported from d3-geo v3.1.1 src/noop.js (ISC, Mike Bostock).

/// Port of `src/noop.js` of d3-geo 3.1.1.
library;

/// `noop.js:1` default export: does nothing.
// DIVERGES(d3-geo): adapt-geo-typed-api, geo*-prefixed helper avoids bundle
// symbol collisions.
void geoNoop() {}
