// Ported from d3-geo v3.1.1 src/identity.js (ISC, Mike Bostock).

/// Port of `src/identity.js` of d3-geo 3.1.1.
library;

/// `identity.js:1` default export: returns [x] unchanged.
// DIVERGES(d3-geo): adapt-geo-typed-api, geo*-prefixed helper avoids bundle
// symbol collisions.
@pragma('vm:prefer-inline')
T geoIdentityValue<T>(T x) => x;
