// Ported from d3-array v3.2.4 src/constant.js (ISC, Mike Bostock).

/// Port of `src/constant.js` of d3-array 3.2.4.
library;

/// Returns a function that always returns [x].
T Function() arrayConstant<T>(T x) =>
    () => x;
