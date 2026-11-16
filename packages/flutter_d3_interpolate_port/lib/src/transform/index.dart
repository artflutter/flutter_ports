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

import 'dart:typed_data';

import 'package:flutter_d3_interpolate_port/src/number.dart';
import 'package:flutter_d3_interpolate_port/src/transform/decompose.dart';

/// The slot of `translateX` in `s`.
const int _slotTranslateX = 0;

/// The slot of `translateY` in `s`.
const int _slotTranslateY = 1;

/// The slot of `rotate` in `s`.
const int _slotRotate = 2;

/// The slot of `skewX` in `s`.
const int _slotSkewX = 3;

/// The slot of `scaleX` in `s`.
const int _slotScaleX = 4;

/// The slot of `scaleY` in `s`.
const int _slotScaleY = 5;

/// An item `{i, x}` of `q` (index.js:13): the slot `i` of `s` that the
/// number interpolator `x` writes.
typedef _Step = ({int i, double Function(double t) x});

// index.js:6 `pop(s)` joins the texts of `s` with a space. The parts of a
// transform need no join, so the port has no `pop`.

/// index.js:10 `translate(xa, ya, xb, yb, s, q)`: both translations
/// interpolate when one differs, and else the translation of `b` stays.
void _translate(
  double xa,
  double ya,
  double xb,
  double yb,
  Float64List s,
  List<_Step> q,
) {
  if (xa != xb || ya != yb) {
    q
      ..add((i: _slotTranslateX, x: interpolateNumber(xa, xb)))
      ..add((i: _slotTranslateY, x: interpolateNumber(ya, yb)));
  } else if ((xb != 0 && !xb.isNaN) || (yb != 0 && !yb.isNaN)) {
    s[_slotTranslateX] = xb;
    s[_slotTranslateY] = yb;
  }
}

/// index.js:19 `rotate(a, b, s, q)`: the rotation interpolates along the
/// shortest path when it differs, and else the rotation of `b` stays.
void _rotate(double a, double b, Float64List s, List<_Step> q) {
  if (a != b) {
    // Upstream writes the parameters a and b; the port writes copies.
    var a1 = a;
    var b1 = b;
    if (a1 - b1 > 180) {
      b1 += 360;
    } else if (b1 - a1 > 180) {
      a1 += 360; // shortest path
    }
    q.add((i: _slotRotate, x: interpolateNumber(a1, b1)));
  } else if (b != 0 && !b.isNaN) {
    s[_slotRotate] = b;
  }
}

/// index.js:28 `skewX(a, b, s, q)`: the skew interpolates when it differs,
/// and else the skew of `b` stays.
void _skewX(double a, double b, Float64List s, List<_Step> q) {
  if (a != b) {
    q.add((i: _slotSkewX, x: interpolateNumber(a, b)));
  } else if (b != 0 && !b.isNaN) {
    s[_slotSkewX] = b;
  }
}

/// index.js:36 `scale(xa, ya, xb, yb, s, q)`: both scales interpolate when
/// one differs, and else the scale of `b` stays.
void _scale(
  double xa,
  double ya,
  double xb,
  double yb,
  Float64List s,
  List<_Step> q,
) {
  if (xa != xb || ya != yb) {
    q
      ..add((i: _slotScaleX, x: interpolateNumber(xa, xb)))
      ..add((i: _slotScaleY, x: interpolateNumber(ya, yb)));
  } else if (xb != 1 || yb != 1) {
    s[_slotScaleX] = xb;
    s[_slotScaleY] = yb;
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
  // The constants and the slots that `q` writes, from the identity: upstream
  // leaves out a part of the identity from its text.
  final s = Float64List(6)
    ..[_slotTranslateX] = identity.translateX
    ..[_slotTranslateY] = identity.translateY
    ..[_slotRotate] = identity.rotate
    ..[_slotSkewX] = identity.skewX
    ..[_slotScaleX] = identity.scaleX
    ..[_slotScaleY] = identity.scaleY;
  final q = <_Step>[]; // number interpolators
  _translate(a.translateX, a.translateY, b.translateX, b.translateY, s, q);
  _rotate(a.rotate, b.rotate, s, q);
  _skewX(a.skewX, b.skewX, s, q);
  _scale(a.scaleX, a.scaleY, b.scaleX, b.scaleY, s, q);
  return (t) {
    for (var i = 0, n = q.length; i < n; i++) {
      final o = q[i];
      s[o.i] = o.x(t);
    }
    return TransformParts(
      s[_slotTranslateX],
      s[_slotTranslateY],
      s[_slotRotate],
      s[_slotSkewX],
      s[_slotScaleX],
      s[_slotScaleY],
    );
  };
}
