// Ported from d3-geo v3.1.1 src/math.js (ISC, Mike Bostock).

/// Port of `src/math.js` of d3-geo 3.1.1: spherical math constants and
/// trigonometric helpers.
library;

import 'dart:math' as math;

// DIVERGES(d3-geo): adapt-geo-typed-api, geo*-prefixed math helpers avoid
// bundle symbol collisions with sibling D3 packages.
// DIVERGES(d3-geo): platform-geo-math-last-bit, dart:math libm can differ from
// V8 fdlibm in the last ULP; geoJsRound matches JS Math.round.

/// `math.js:1` `epsilon`: `1e-6`.
const double geoEpsilon = 1e-6;

/// `math.js:2` `epsilon2`: `1e-12`.
const double geoEpsilon2 = 1e-12;

/// `math.js:3` `pi`: `π`.
const double geoPi = math.pi;

/// `math.js:4` `halfPi`: `π / 2`.
const double geoHalfPi = math.pi / 2;

/// `math.js:5` `quarterPi`: `π / 4`.
const double geoQuarterPi = math.pi / 4;

/// `math.js:6` `tau`: `2π`.
const double geoTau = math.pi * 2;

/// `math.js:8` `degrees`: `180 / π`.
const double geoDegrees = 180 / math.pi;

/// `math.js:9` `radians`: `π / 180`.
const double geoRadians = math.pi / 180;

/// `math.js:26` `acos(x)`: clamped inverse cosine in `[0, π]`.
@pragma('vm:prefer-inline')
double geoAcos(double x) => x > 1 ? 0 : (x < -1 ? geoPi : math.acos(x));

/// `math.js:30` `asin(x)`: clamped inverse sine in `[-π/2, π/2]`.
@pragma('vm:prefer-inline')
double geoAsin(double x) =>
    x > 1 ? geoHalfPi : (x < -1 ? -geoHalfPi : math.asin(x));

/// `math.js:34` `haversin(x)`: `sin²(x / 2)`.
@pragma('vm:prefer-inline')
double geoHaversin(double x) {
  final s = math.sin(x / 2);
  return s * s;
}

/// `math.js:18` `hypot(x, y, z)`: 3D Euclidean norm avoiding overflow/underflow.
@pragma('vm:prefer-inline')
double geoHypot3(double x, double y, double z) {
  final ax = x.abs();
  final ay = y.abs();
  final az = z.abs();
  var maxVal = ax > ay ? ax : ay;
  if (az > maxVal) maxVal = az;
  if (maxVal == 0 || !maxVal.isFinite) {
    return math.sqrt(x * x + y * y + z * z);
  }
  final rx = x / maxVal;
  final ry = y / maxVal;
  final rz = z / maxVal;
  return maxVal * math.sqrt(rx * rx + ry * ry + rz * rz);
}

/// `math.js:22` `sign(x)`: `-1`, `0`, or `1` (preserving NaN).
@pragma('vm:prefer-inline')
double geoSign(double x) => x > 0 ? 1 : (x < 0 ? -1 : 0);

/// JavaScript `Math.round(x)` semantics (ties round toward `+∞`).
@pragma('vm:prefer-inline')
double geoJsRound(double x) {
  if (!x.isFinite) return x;
  if (x >= -0.5 && x < 0) return -0;
  return (x + 0.5).floorToDouble();
}
