// Ported from d3-shape v3.2.0 src/math.js (ISC, Mike Bostock).

/// Port of `src/math.js` of d3-shape 3.2.0: math constants and clamped
/// inverse trigonometric helpers.
library;

import 'dart:math' as math;

/// `math.js:9` `epsilon`: geometric tolerance `1e-12`.
const double shapeEpsilon = 1e-12;

/// `math.js:10` `pi`: `π`.
const double shapePi = math.pi;

/// `math.js:11` `halfPi`: `π / 2`.
const double shapeHalfPi = math.pi / 2;

/// `math.js:12` `tau`: `2π`.
const double shapeTau = 2 * math.pi;

/// `math.js:14` `acos(x)`: clamped inverse cosine in `[0, π]`.
// DIVERGES(d3-shape): platform-shape-math-last-bit, dart:math libm can differ
// from V8 fdlibm in the last ULP.
@pragma('vm:prefer-inline')
double shapeAcos(double x) => x > 1 ? 0 : (x < -1 ? shapePi : math.acos(x));

/// `math.js:18` `asin(x)`: clamped inverse sine in `[-π/2, π/2]`.
@pragma('vm:prefer-inline')
double shapeAsin(double x) =>
    x >= 1 ? shapeHalfPi : (x <= -1 ? -shapeHalfPi : math.asin(x));
