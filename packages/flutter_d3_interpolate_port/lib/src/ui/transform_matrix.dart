// Original code, not ported from d3-interpolate: the Flutter matrices.

/// The conversions between the [Matrix4] of the Flutter `Transform` widget
/// and the [TransformParts] of `interpolateTransform` (D3 ADR 0008 §6).
///
/// They take the place of the CSS and SVG texts of upstream `parse.js`:
///
/// ```dart
/// final i = interpolateTransform(
///   from.toTransformParts(),
///   to.toTransformParts(),
/// );
/// Transform(transform: i(t).toMatrix4(), child: child);
/// ```
library;

import 'dart:math' as math;

import 'package:flutter_d3_interpolate_port/src/transform/decompose.dart';
import 'package:vector_math/vector_math_64.dart';

/// The radians of one degree.
const double _radians = math.pi / 180;

/// The [TransformParts] of a [Matrix4].
extension Matrix4ToTransformParts on Matrix4 {
  /// The parts of the 2D affine part of this matrix, as `parseCss` of
  /// upstream reads a `DOMMatrix`: [decompose] of `a = m[0]`, `b = m[1]`,
  /// `c = m[4]`, `d = m[5]`, `e = m[12]` and `f = m[13]` of the column-major
  /// [storage]. The other entries (z and perspective) do not count.
  ///
  /// The identity matrix gives [identity].
  TransformParts toTransformParts() {
    if (isIdentity()) return identity;
    final m = storage;
    return decompose(m[0], m[1], m[4], m[5], m[12], m[13]);
  }
}

/// The [Matrix4] of a [TransformParts].
extension TransformPartsToMatrix4 on TransformParts {
  /// The 2D affine matrix of these parts, composed in the order of the CSS
  /// text `translate(translateX, translateY) rotate(rotate) skewX(skewX)
  /// scale(scaleX, scaleY)`, in a [Matrix4] with no z part.
  ///
  /// `toMatrix4()` of the [decompose] of a matrix that is not singular gives
  /// that matrix back, within the rounding of the angles.
  Matrix4 toMatrix4() {
    final r = rotate * _radians;
    final cos = math.cos(r);
    final sin = math.sin(r);
    final tan = math.tan(skewX * _radians);
    // translate · rotate · skewX · scale:
    // | cos -sin |   | 1 tan |   | scaleX 0      |
    // | sin  cos | · | 0 1   | · | 0      scaleY |
    return Matrix4(
      cos * scaleX,
      sin * scaleX,
      0,
      0,
      (cos * tan - sin) * scaleY,
      (sin * tan + cos) * scaleY,
      0,
      0,
      0,
      0,
      1,
      0,
      translateX,
      translateY,
      0,
      1,
    );
  }
}
