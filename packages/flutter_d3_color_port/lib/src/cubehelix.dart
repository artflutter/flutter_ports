// Ported from d3-color v3.1.0 src/cubehelix.js (ISC, Mike Bostock).

/// Port of `src/cubehelix.js` of d3-color 3.1.0: the Cubehelix color space
/// of Dave Green, [Cubehelix].
library;

import 'dart:math' as math;

import 'package:flutter_d3_color_port/src/color.dart';
import 'package:flutter_d3_color_port/src/math.dart';

// The methods `brighter` and `darker` of [Cubehelix] hide the two constants
// of color.dart in the class body.
const double _darker = darker;
const double _brighter = brighter;

/// cubehelix.js:5 `A`.
const double _a = -0.14861;

/// cubehelix.js:6 `B`.
const double _b = 1.78277;

/// cubehelix.js:7 `C`.
const double _c = -0.29227;

/// cubehelix.js:8 `D`.
const double _d = -0.90649;

/// cubehelix.js:9 `E`.
const double _e = 1.97294;

/// cubehelix.js:10 `ED`.
const double _ed = _e * _d;

/// cubehelix.js:11 `EB`.
const double _eb = _e * _b;

/// cubehelix.js:12 `BC_DA`.
const double _bcDa = _b * _c - _d * _a;

/// cubehelix.js:14 `cubehelixConvert(o)`: a new [Cubehelix] with the
/// channels of [o] in Cubehelix. A null [o] gives undefined channels and an
/// undefined opacity.
Cubehelix cubehelixConvert(Color? o) {
  if (o is Cubehelix) return Cubehelix(o.h, o.s, o.l, o.opacity);
  final c = o is Rgb ? o : rgbConvert(o);
  final r = c.r / 255;
  final g = c.g / 255;
  final b = c.b / 255;
  final l = (_bcDa * b + _ed * r - _eb * g) / (_bcDa + _ed - _eb);
  final bl = b - l;
  final k = (_e * (g - l) - _c * bl) / _d;
  // NaN if l = 0 or l = 1.
  final s = math.sqrt(k * k + bl * bl) / (_e * l * (1 - l));
  // `s ? … : NaN`: s is neither 0 nor NaN.
  // DIVERGES(d3-color): platform-color-trig-last-bit, dart:math atan2.
  final h = s != 0 && !s.isNaN ? math.atan2(k, bl) * degrees - 120 : double.nan;
  return Cubehelix(h < 0 ? h + 360 : h, s, l, c.opacity);
}

/// cubehelix.js:32 `Cubehelix` and the factory `cubehelix` (cubehelix.js:28):
/// a color in the Cubehelix space. The hue is in degrees.
// DIVERGES(d3-color): adapt-color-factories, constructors for the overloads.
class Cubehelix(
  /// The hue in degrees.
  var double h,

  /// The saturation.
  var double s,

  /// The lightness.
  var double l, [
  @override var double opacity = 1,
]) extends Color {
  /// `cubehelix(h, s, l[, opacity])`.
  this;

  /// `cubehelix(color)`: a new [Cubehelix] with the channels of [color] in
  /// Cubehelix.
  factory from(Color color) => cubehelixConvert(color);

  /// `cubehelix(specifier)`: the color of the CSS text [specifier] in
  /// Cubehelix. A text that [color] does not read gives undefined channels
  /// and opacity.
  factory parse(String specifier) => cubehelixConvert(color(specifier));

  @override
  Cubehelix copy({double? h, double? s, double? l, double? opacity}) =>
      Cubehelix(h ?? this.h, s ?? this.s, l ?? this.l, opacity ?? this.opacity);

  /// cubehelix.js:40 `brighter(k)`.
  @override
  Cubehelix brighter([double? k]) {
    final f = k == null ? _brighter : math.pow(_brighter, k).toDouble();
    return Cubehelix(h, s, l * f, opacity);
  }

  /// cubehelix.js:44 `darker(k)`.
  @override
  Cubehelix darker([double? k]) {
    final f = k == null ? _darker : math.pow(_darker, k).toDouble();
    return Cubehelix(h, s, l * f, opacity);
  }

  /// cubehelix.js:48 `rgb()`.
  @override
  Rgb rgb() {
    final h = this.h.isNaN ? 0.0 : (this.h + 120) * radians;
    final l = this.l;
    final a = s.isNaN ? 0.0 : s * l * (1 - l);
    // DIVERGES(d3-color): platform-color-trig-last-bit, dart:math cos, sin.
    final cosh = math.cos(h);
    final sinh = math.sin(h);
    return Rgb(
      255 * (l + a * (_a * cosh + _b * sinh)),
      255 * (l + a * (_c * cosh + _d * sinh)),
      255 * (l + a * (_e * cosh)),
      opacity,
    );
  }
}
