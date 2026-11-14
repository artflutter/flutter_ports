// Ported from d3-color v3.1.0 src/lab.js (ISC, Mike Bostock).

/// Port of `src/lab.js` of d3-color 3.1.0: the CIELAB color space [Lab]
/// and its cylindrical form [Hcl], with the D50 white point of
/// <https://observablehq.com/@mbostock/lab-and-rgb>.
library;

import 'dart:math' as math;

import 'package:flutter_d3_color_port/src/color.dart';
import 'package:flutter_d3_color_port/src/math.dart';

/// lab.js:6 `K`: the lightness step of `brighter()` and `darker()`.
const double _k = 18;

/// lab.js:7 `Xn`.
const double _xn = 0.96422;

/// lab.js:8 `Yn`.
const double _yn = 1;

/// lab.js:9 `Zn`.
const double _zn = 0.82521;

/// lab.js:10 `t0`.
const double _t0 = 4 / 29;

/// lab.js:11 `t1`.
const double _t1 = 6 / 29;

/// lab.js:12 `t2`.
const double _t2 = 3 * _t1 * _t1;

/// lab.js:13 `t3`.
const double _t3 = _t1 * _t1 * _t1;

/// lab.js:15 `labConvert(o)`: a new [Lab] with the channels of [o] in Lab.
/// A null [o] gives undefined channels and an undefined opacity.
Lab labConvert(Color? o) {
  if (o is Lab) return Lab(o.l, o.a, o.b, o.opacity);
  if (o is Hcl) return hcl2lab(o);
  final c = o is Rgb ? o : rgbConvert(o);
  final r = rgb2lrgb(c.r);
  final g = rgb2lrgb(c.g);
  final b = rgb2lrgb(c.b);
  final y = xyz2lab((0.2225045 * r + 0.7168786 * g + 0.0606169 * b) / _yn);
  double x;
  double z;
  if (r == g && g == b) {
    x = z = y;
  } else {
    x = xyz2lab((0.4360747 * r + 0.3850649 * g + 0.1430804 * b) / _xn);
    z = xyz2lab((0.0139322 * r + 0.0971045 * g + 0.7141733 * b) / _zn);
  }
  return Lab(116 * y - 16, 500 * (x - y), 200 * (y - z), c.opacity);
}

/// lab.js:30 `gray(l, opacity)`: the gray of the lightness [l], a [Lab] with
/// `a` and `b` 0.
Lab gray(double l, [double opacity = 1]) => Lab(l, 0, 0, opacity);

/// lab.js:38 `Lab` and the factory `lab` (lab.js:34): a color in the CIELAB
/// space. The lightness [l] is in [0, 100] for a color in the gamut.
// DIVERGES(d3-color): adapt-color-factories, constructors for the overloads.
class Lab(
  /// The lightness.
  var double l,

  /// The green-red axis.
  var double a,

  /// The blue-yellow axis.
  var double b, [
  @override var double opacity = 1,
]) extends Color {
  /// `lab(l, a, b[, opacity])`. The channels do not clamp.
  this;

  /// `lab(color)`: a new [Lab] with the channels of [color] in Lab.
  factory from(Color color) => labConvert(color);

  /// `lab(specifier)`: the color of the CSS text [specifier] in Lab. A text
  /// that [color] does not read gives undefined channels and opacity.
  factory parse(String specifier) => labConvert(color(specifier));

  @override
  Lab copy({double? l, double? a, double? b, double? opacity}) =>
      Lab(l ?? this.l, a ?? this.a, b ?? this.b, opacity ?? this.opacity);

  /// lab.js:46 `brighter(k)`.
  @override
  Lab brighter([double? k]) => Lab(l + _k * (k ?? 1), a, b, opacity);

  /// lab.js:49 `darker(k)`.
  @override
  Lab darker([double? k]) => Lab(l - _k * (k ?? 1), a, b, opacity);

  /// lab.js:52 `rgb()`.
  @override
  Rgb rgb() {
    var y = (l + 16) / 116;
    var x = a.isNaN ? y : y + a / 500;
    var z = b.isNaN ? y : y - b / 200;
    x = _xn * lab2xyz(x);
    y = _yn * lab2xyz(y);
    z = _zn * lab2xyz(z);
    return Rgb(
      lrgb2rgb(3.1338561 * x - 1.6168667 * y - 0.4906146 * z),
      lrgb2rgb(-0.9787684 * x + 1.9161415 * y + 0.0334540 * z),
      lrgb2rgb(0.0719453 * x - 0.2289914 * y + 1.4052427 * z),
      opacity,
    );
  }
}

/// lab.js:68 `xyz2lab(t)`.
double xyz2lab(double t) =>
    t > _t3 ? math.pow(t, 1 / 3).toDouble() : t / _t2 + _t0;

/// lab.js:72 `lab2xyz(t)`.
double lab2xyz(double t) => t > _t1 ? t * t * t : _t2 * (t - _t0);

/// lab.js:76 `lrgb2rgb(x)`: a linear channel in [0, 1] as an sRGB channel in
/// [0, 255].
double lrgb2rgb(double x) =>
    255 *
    (x <= 0.0031308
        ? 12.92 * x
        : 1.055 * math.pow(x, 1 / 2.4).toDouble() - 0.055);

/// lab.js:80 `rgb2lrgb(x)`: an sRGB channel in [0, 255] as a linear channel
/// in [0, 1].
double rgb2lrgb(double x) {
  final v = x / 255;
  return v <= 0.04045
      ? v / 12.92
      : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}

/// lab.js:84 `hclConvert(o)`: a new [Hcl] with the channels of [o] in HCL. A
/// null [o] gives undefined channels and an undefined opacity.
Hcl hclConvert(Color? o) {
  if (o is Hcl) return Hcl(o.h, o.c, o.l, o.opacity);
  final c = o is Lab ? o : labConvert(o);
  if (c.a == 0 && c.b == 0) {
    return Hcl(
      double.nan,
      0 < c.l && c.l < 100 ? 0 : double.nan,
      c.l,
      c.opacity,
    );
  }
  // DIVERGES(d3-color): platform-color-trig-last-bit, dart:math atan2.
  final h = math.atan2(c.b, c.a) * degrees;
  return Hcl(
    h < 0 ? h + 360 : h,
    math.sqrt(c.a * c.a + c.b * c.b),
    c.l,
    c.opacity,
  );
}

/// lab.js:92 `lch(l, c, h, opacity)`: the [Hcl] of the lightness [l], the
/// chroma [c] and the hue [h]. The upstream form `lch(color)` is
/// [Hcl.from].
Hcl lch(double l, double c, double h, [double opacity = 1]) =>
    Hcl(h, c, l, opacity);

/// lab.js:100 `Hcl` and the factory `hcl` (lab.js:96): a color in the
/// cylindrical form of CIELAB. The hue is in degrees.
// DIVERGES(d3-color): adapt-color-factories, constructors for the overloads.
class Hcl(
  /// The hue in degrees.
  var double h,

  /// The chroma.
  var double c,

  /// The lightness.
  var double l, [
  @override var double opacity = 1,
]) extends Color {
  /// `hcl(h, c, l[, opacity])`. The hue does not wrap and the channels do
  /// not clamp.
  this;

  /// `hcl(color)` and `lch(color)`: a new [Hcl] with the channels of
  /// [color] in HCL.
  factory from(Color color) => hclConvert(color);

  /// `hcl(specifier)` and `lch(specifier)`: the color of the CSS text
  /// [specifier] in HCL. A text that [color] does not read gives undefined
  /// channels and opacity.
  factory parse(String specifier) => hclConvert(color(specifier));

  @override
  Hcl copy({double? h, double? c, double? l, double? opacity}) =>
      Hcl(h ?? this.h, c ?? this.c, l ?? this.l, opacity ?? this.opacity);

  /// lab.js:114 `brighter(k)`.
  @override
  Hcl brighter([double? k]) => Hcl(h, c, l + _k * (k ?? 1), opacity);

  /// lab.js:117 `darker(k)`.
  @override
  Hcl darker([double? k]) => Hcl(h, c, l - _k * (k ?? 1), opacity);

  /// lab.js:120 `rgb()`.
  @override
  Rgb rgb() => hcl2lab(this).rgb();
}

/// lab.js:107 `hcl2lab(o)`.
Lab hcl2lab(Hcl o) {
  if (o.h.isNaN) return Lab(o.l, 0, 0, o.opacity);
  final h = o.h * radians;
  // DIVERGES(d3-color): platform-color-trig-last-bit, dart:math cos, sin.
  return Lab(o.l, math.cos(h) * o.c, math.sin(h) * o.c, o.opacity);
}
