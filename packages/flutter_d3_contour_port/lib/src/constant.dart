// Ported from d3-contour v4.0.2 src/constant.js (ISC, Mike Bostock).

/// Port of `src/constant.js` of d3-contour 4.0.2.
library;

/// Returns a constant function that always returns [x].
// DIVERGES(d3-contour): adapt-contour-typed-api, contour-prefixed typed helper.
T Function() contourConstant<T>(T x) =>
    () => x;
