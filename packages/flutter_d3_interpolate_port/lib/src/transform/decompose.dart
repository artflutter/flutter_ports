// Ported from d3-interpolate v3.0.1 src/transform/decompose.js (ISC, Mike Bostock).

/// Port of `src/transform/decompose.js` of d3-interpolate 3.0.1: the parts
/// of a 2D affine matrix, [decompose], and the parts of the identity matrix,
/// [identity].
///
/// Upstream returns an object with the keys `translateX`, `translateY`,
/// `rotate`, `skewX`, `scaleX` and `scaleY`. The port returns a
/// [TransformParts] (the row `adapt-interpolate-typed-transform`).
library;

import 'dart:math' as math;

/// decompose.js:1 `degrees`: the degrees of one radian.
const double _degrees = 180 / math.pi;

/// The parts of a 2D transform, in the order of the CSS text
/// `translate(translateX, translateY) rotate(rotate) skewX(skewX)
/// scale(scaleX, scaleY)`: the object of decompose.js:3 and decompose.js:18.
///
/// The angles are in degrees. A value is immutable: an interpolator of
/// [TransformParts] returns a new value at each call.
// DIVERGES(d3-interpolate): adapt-interpolate-typed-transform, a class.
final class const TransformParts(
  /// The translation along x: the `e` of the matrix.
  final double translateX,

  /// The translation along y: the `f` of the matrix.
  final double translateY,

  /// The rotation in degrees.
  final double rotate,

  /// The skew along x in degrees.
  final double skewX,

  /// The scale along x. It is negative for a matrix that flips.
  final double scaleX,

  /// The scale along y.
  final double scaleY,
) {
  /// The parts `translate(translateX, translateY) rotate(rotate)
  /// skewX(skewX) scale(scaleX, scaleY)`.
  this;

  @override
  String toString() =>
      'TransformParts(translateX: $translateX, translateY: $translateY, '
      'rotate: $rotate, skewX: $skewX, scaleX: $scaleX, scaleY: $scaleY)';
}

/// decompose.js:3 `identity`: the parts of the identity matrix.
const TransformParts identity = TransformParts(0, 0, 0, 0, 1, 1);

/// decompose.js:12 `decompose(a, b, c, d, e, f)`: the parts of the 2D affine
/// matrix `matrix(a, b, c, d, e, f)` of CSS, that is
///
/// ```text
/// | a c e |
/// | b d f |
/// | 0 0 1 |
/// ```
///
/// A matrix that flips (`a * d < b * c`) gives a negative `scaleX`. A
/// singular matrix gives parts that compose to another matrix: the parts of
/// `matrix(0, 0, 1, 0, 0, 0)` have no skew, as upstream.
TransformParts decompose(
  double a,
  double b,
  double c,
  double d,
  double e,
  double f,
) {
  // Upstream writes the parameters a, b, c and d; the port writes copies.
  var a1 = a;
  var b1 = b;
  var c1 = c;
  var d1 = d;
  var scaleX = math.sqrt(a1 * a1 + b1 * b1);
  if (scaleX != 0 && !scaleX.isNaN) {
    a1 /= scaleX;
    b1 /= scaleX;
  }
  var skewX = a1 * c1 + b1 * d1;
  if (skewX != 0 && !skewX.isNaN) {
    c1 -= a1 * skewX;
    d1 -= b1 * skewX;
  }
  final scaleY = math.sqrt(c1 * c1 + d1 * d1);
  if (scaleY != 0 && !scaleY.isNaN) {
    c1 /= scaleY;
    d1 /= scaleY;
    skewX /= scaleY;
  }
  if (a1 * d1 < b1 * c1) {
    a1 = -a1;
    b1 = -b1;
    skewX = -skewX;
    scaleX = -scaleX;
  }
  // DIVERGES(d3-interpolate): platform-interpolate-math-last-bit, atan.
  return TransformParts(
    e,
    f,
    math.atan2(b1, a1) * _degrees,
    math.atan(skewX) * _degrees,
    scaleX,
    scaleY,
  );
}
