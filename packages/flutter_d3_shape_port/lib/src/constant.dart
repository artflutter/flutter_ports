// Ported from d3-shape v3.2.0 src/constant.js (ISC, Mike Bostock).

/// Port of `src/constant.js` of d3-shape 3.2.0.
library;

/// `constant.js:1` default export: returns a function that always returns [x].
T Function() shapeConstant<T>(T x) =>
    () => x;
