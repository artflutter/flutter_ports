// Ported from d3-shape v3.2.0 src/descending.js (ISC, Mike Bostock).

/// Port of `src/descending.js` of d3-shape 3.2.0.
library;

/// `descending.js:1` default export: descending comparator for numbers.
double shapeDescending(double a, double b) =>
    b < a ? -1 : (b > a ? 1 : (b >= a ? 0 : double.nan));
