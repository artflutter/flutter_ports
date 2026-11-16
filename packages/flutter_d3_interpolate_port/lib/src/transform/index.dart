// Ported from d3-interpolate v3.0.1 src/transform/index.js (ISC, Mike Bostock).

/// Port of `src/transform/index.js` of d3-interpolate 3.0.1: the
/// interpolator of two 2D transforms, [interpolateTransform].
///
/// Upstream parses two CSS or SVG transform texts with `parse.js`, and its
/// interpolator returns a transform text at each t: `interpolateTransformCss`
/// and `interpolateTransformSvg`. The port has no text parse: it takes the
/// [TransformParts] of [decompose], and its interpolator returns the
/// [TransformParts] of the text (the row
/// `adapt-interpolate-typed-transform`).
library;

import 'package:flutter_d3_interpolate_port/src/number.dart'
    show interpolateNumber;
import 'package:flutter_d3_interpolate_port/src/transform/decompose.dart';

/// The list `s` of index.js:55: the six parts of the result. A part that no
/// item of `q` writes keeps the part of the identity or of `b`.
// DIVERGES(d3-interpolate): adapt-interpolate-typed-transform, typed parts.
final class _Parts() {
  /// The translation on x.
  double translateX = identity.translateX;

  /// The translation on y.
  double translateY = identity.translateY;

  /// The rotation in degrees.
  double rotate = identity.rotate;

  /// The skew on x in degrees.
  double skewX = identity.skewX;

  /// The scale on x.
  double scaleX = identity.scaleX;

  /// The scale on y.
  double scaleY = identity.scaleY;
}

/// The list `q` of index.js:56: each item `{i, x}` is the part `i` of `s`
/// that the number interpolator `x` writes.
///
/// An item keeps the two numbers of `x = number(a, b)` in the fields of its
/// part, and [interpolate] has the line of number.js. The items take the
/// parts in their order, so a bit for each part gives the items. A list of
/// records with a function field costs a type test of the record at each
/// `add` on the VM (the creation of a transform interpolator took 1.5 µs),
/// and a typed list of more than 64 bytes is slow to make in JavaScript.
// DIVERGES(d3-interpolate): adapt-interpolate-typed-loops, no closures.
final class _Steps() {
  /// Bit 0 for `translateX`, then `translateY`, `rotate`, `skewX`, `scaleX`
  /// and `scaleY`.
  int mask = 0;

  /// The start of the translation on x.
  double translateX0 = 0;

  /// The end of the translation on x.
  double translateX1 = 0;

  /// The start of the translation on y.
  double translateY0 = 0;

  /// The end of the translation on y.
  double translateY1 = 0;

  /// The start of the rotation.
  double rotate0 = 0;

  /// The end of the rotation.
  double rotate1 = 0;

  /// The start of the skew.
  double skewX0 = 0;

  /// The end of the skew.
  double skewX1 = 0;

  /// The start of the scale on x.
  double scaleX0 = 0;

  /// The end of the scale on x.
  double scaleX1 = 0;

  /// The start of the scale on y.
  double scaleY0 = 0;

  /// The end of the scale on y.
  double scaleY1 = 0;

  /// index.js:63 `s[(o = q[i]).i] = o.x(t)` for each item.
  void interpolate(double t, _Parts s) {
    final m = mask;
    if (m & 1 != 0) s.translateX = translateX0 * (1 - t) + translateX1 * t;
    if (m & 2 != 0) s.translateY = translateY0 * (1 - t) + translateY1 * t;
    if (m & 4 != 0) s.rotate = rotate0 * (1 - t) + rotate1 * t;
    if (m & 8 != 0) s.skewX = skewX0 * (1 - t) + skewX1 * t;
    if (m & 16 != 0) s.scaleX = scaleX0 * (1 - t) + scaleX1 * t;
    if (m & 32 != 0) s.scaleY = scaleY0 * (1 - t) + scaleY1 * t;
  }
}

// index.js:6 `pop(s)` joins the texts of `s` with a space. The parts of a
// transform need no join, so the port has no `pop`.

/// index.js:10 `translate(xa, ya, xb, yb, s, q)`: both translations
/// interpolate when one differs, and else the translation of `b` stays.
void _translate(
  double xa,
  double ya,
  double xb,
  double yb,
  _Parts s,
  _Steps q,
) {
  if (xa != xb || ya != yb) {
    q
      ..mask |= 1 | 2
      ..translateX0 = xa
      ..translateX1 = xb
      ..translateY0 = ya
      ..translateY1 = yb;
  } else if ((xb != 0 && !xb.isNaN) || (yb != 0 && !yb.isNaN)) {
    s
      ..translateX = xb
      ..translateY = yb;
  }
}

/// index.js:19 `rotate(a, b, s, q)`: the rotation interpolates along the
/// shortest path when it differs, and else the rotation of `b` stays.
void _rotate(double a, double b, _Parts s, _Steps q) {
  if (a != b) {
    // Upstream writes the parameters a and b; the port writes copies.
    var a1 = a;
    var b1 = b;
    if (a1 - b1 > 180) {
      b1 += 360;
    } else if (b1 - a1 > 180) {
      a1 += 360; // shortest path
    }
    q
      ..mask |= 4
      ..rotate0 = a1
      ..rotate1 = b1;
  } else if (b != 0 && !b.isNaN) {
    s.rotate = b;
  }
}

/// index.js:28 `skewX(a, b, s, q)`: the skew interpolates when it differs,
/// and else the skew of `b` stays.
void _skewX(double a, double b, _Parts s, _Steps q) {
  if (a != b) {
    q
      ..mask |= 8
      ..skewX0 = a
      ..skewX1 = b;
  } else if (b != 0 && !b.isNaN) {
    s.skewX = b;
  }
}

/// index.js:36 `scale(xa, ya, xb, yb, s, q)`: both scales interpolate when
/// one differs, and else the scale of `b` stays.
void _scale(double xa, double ya, double xb, double yb, _Parts s, _Steps q) {
  if (xa != xb || ya != yb) {
    q
      ..mask |= 16 | 32
      ..scaleX0 = xa
      ..scaleX1 = xb
      ..scaleY0 = ya
      ..scaleY1 = yb;
  } else if (xb != 1 || yb != 1) {
    s
      ..scaleX = xb
      ..scaleY = yb;
  }
}

/// index.js:45 the interpolator of `interpolateTransform(parse, ...)`: the
/// transform between the parts [a] and [b].
///
/// For two matrices `a` and `b`, `interpolateTransformCss(a, b)` of upstream
/// is `interpolateTransform(a.toTransformParts(), b.toTransformParts())`
/// with the `Matrix4` of the Flutter layer of the package, or
/// `interpolateTransform(decompose(...), decompose(...))` with the six
/// numbers of each matrix.
///
/// Each part of [a] and [b] interpolates with [interpolateNumber], with
/// these rules of upstream:
///
/// * the two translations interpolate when one of them differs, and else
///   the translation of [b] stays; the same holds for the two scales;
/// * the rotation interpolates along the shortest path: when the two angles
///   are more than 180 degrees apart, the smaller one gains 360 degrees;
/// * a part that is equal in [a] and [b] stays at its value (a part of the
///   identity stays at 0, or 1 for a scale).
///
/// The interpolator returns a new [TransformParts] at each call. Its
/// rotation can be outside (-180, 180], for example 190 degrees.
// DIVERGES(d3-interpolate): adapt-interpolate-typed-transform, typed parts.
TransformParts Function(double t) interpolateTransform(
  TransformParts a,
  TransformParts b,
) {
  final s = _Parts(); // the parts, from the identity
  final q = _Steps(); // number interpolators
  _translate(a.translateX, a.translateY, b.translateX, b.translateY, s, q);
  _rotate(a.rotate, b.rotate, s, q);
  _skewX(a.skewX, b.skewX, s, q);
  _scale(a.scaleX, a.scaleY, b.scaleX, b.scaleY, s, q);
  return (t) {
    q.interpolate(t, s);
    return TransformParts(
      s.translateX,
      s.translateY,
      s.rotate,
      s.skewX,
      s.scaleX,
      s.scaleY,
    );
  };
}
