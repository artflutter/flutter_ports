// Ported from d3-color v3.1.0 src/lab.js (ISC, Mike Bostock).

/// Port of `src/lab.js` of d3-color 3.1.0: the CIELAB color space [Lab]
/// and its cylindrical form [Hcl], with the D50 white point of
/// <https://observablehq.com/@mbostock/lab-and-rgb>.
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_d3_color_port/d3_color.dart';

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
  // DIVERGES(d3-color): adapt-color-convert-locals, o.rgb() with no copy.
  final c = o is Rgb ? o : (o == null ? rgbConvert(o) : o.rgb());
  final (l, a, b) = _rgb2lab(c.r, c.g, c.b);
  return Lab(l, a, b, c.opacity);
}

/// The lines lab.js:19-28 of `labConvert`: the Lab channels `(l, a, b)` of
/// the RGB channels [cr], [cg] and [cb], with no [Rgb] or [Lab] object.
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
(double, double, double) _rgb2lab(double cr, double cg, double cb) {
  final r = rgb2lrgb(cr);
  final g = rgb2lrgb(cg);
  final b = rgb2lrgb(cb);
  final y = xyz2lab((0.2225045 * r + 0.7168786 * g + 0.0606169 * b) / _yn);
  double x;
  double z;
  if (r == g && g == b) {
    x = z = y;
  } else {
    x = xyz2lab((0.4360747 * r + 0.3850649 * g + 0.1430804 * b) / _xn);
    z = xyz2lab((0.0139322 * r + 0.0971045 * g + 0.7141733 * b) / _zn);
  }
  return (116.0 * y - 16.0, 500.0 * (x - y), 200.0 * (y - z));
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
  Lab brighter([double? k]) => Lab(l + _k * (k ?? 1.0), a, b, opacity);

  /// lab.js:49 `darker(k)`.
  @override
  Lab darker([double? k]) => Lab(l - _k * (k ?? 1.0), a, b, opacity);

  /// lab.js:52 `rgb()`.
  @override
  Rgb rgb() => _lab2rgb(l, a, b, opacity);
}

/// The lines lab.js:53-63 of `Lab.rgb()`: the [Rgb] of the Lab channels [l],
/// [a] and [b] and the opacity [opacity], with no [Lab] object.
Rgb _lab2rgb(double l, double a, double b, double opacity) {
  final (r, g, bb) = _lab2channels(l, a, b);
  return Rgb(r, g, bb, opacity);
}

/// The lines lab.js:53-62 of `Lab.rgb()`: the RGB channels `(r, g, b)` of
/// the Lab channels [l], [a] and [b], for [_lab2rgb] and [Hcl.formatRgb].
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
(double, double, double) _lab2channels(double l, double a, double b) {
  var y = (l + 16.0) / 116.0;
  var x = a.isNaN ? y : y + a / 500.0;
  var z = b.isNaN ? y : y - b / 200.0;
  x = _xn * lab2xyz(x);
  y = _yn * lab2xyz(y);
  z = _zn * lab2xyz(z);
  return (
    lrgb2rgb(3.1338561 * x - 1.6168667 * y - 0.4906146 * z),
    lrgb2rgb(-0.9787684 * x + 1.9161415 * y + 0.0334540 * z),
    lrgb2rgb(0.0719453 * x - 0.2289914 * y + 1.4052427 * z),
  );
}

/// lab.js:68 `xyz2lab(t)`.
@pragma('vm:prefer-inline')
double xyz2lab(double t) =>
    t > _t3 ? pow(t, 1.0 / 3.0).toDouble() : t / _t2 + _t0;

/// lab.js:72 `lab2xyz(t)`.
@pragma('vm:prefer-inline')
double lab2xyz(double t) => t > _t1 ? t * t * t : _t2 * (t - _t0);

/// lab.js:76 `lrgb2rgb(x)`: a linear channel in [0, 1] as an sRGB channel in
/// [0, 255].
@pragma('vm:prefer-inline')
double lrgb2rgb(double x) =>
    255.0 *
    (x <= 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1.0 / 2.4).toDouble() - 0.055);

/// lab.js:80 `rgb2lrgb(x)`: an sRGB channel in [0, 255] as a linear channel
/// in [0, 1].
@pragma('vm:prefer-inline')
double rgb2lrgb(double x) {
  final v = x / 255.0;
  if (v <= 0.04045) return v / 12.92;
  // DIVERGES(d3-color): adapt-color-lrgb-table, whole channels in a table.
  // Past the linear branch, x is above 10 or NaN. Adding and taking away
  // 2^52 rounds x to a whole number.
  if (x <= 255.0 && (x + _p52) - _p52 == x) return _lrgbTable[x.toInt()];
  return _lrgbPow(v);
}

/// 2^52: from 2^52 to 2^53, the doubles are the whole numbers.
const double _p52 = 4503599627370496;

/// The power branch of lab.js:81 `rgb2lrgb` for the channel [v] in [0, 1].
double _lrgbPow(double v) => pow((v + 0.055) / 1.055, 2.4).toDouble();

/// The [_lrgbPow] of each whole channel 0 to 255, from the formula itself, so
/// that a read gives the double of the formula on each platform. A parsed
/// CSS color has whole channels. [rgb2lrgb] reads only the entries above 10:
/// the channels 0 to 10 take the linear branch.
final Float64List _lrgbTable = Float64List.fromList([
  for (var i = 0; i < 256; i++) _lrgbPow(i / 255.0),
]);

/// lab.js:84 `hclConvert(o)`: a new [Hcl] with the channels of [o] in HCL. A
/// null [o] gives undefined channels and an undefined opacity.
Hcl hclConvert(Color? o) {
  if (o is Hcl) return Hcl(o.h, o.c, o.l, o.opacity);
  double l;
  double a;
  double b;
  double opacity;
  if (o is Lab) {
    (l, a, b, opacity) = (o.l, o.a, o.b, o.opacity);
  } else {
    // DIVERGES(d3-color): adapt-color-convert-locals, Lab in locals.
    final c = o is Rgb ? o : (o == null ? rgbConvert(o) : o.rgb());
    (l, a, b) = _rgb2lab(c.r, c.g, c.b);
    opacity = c.opacity;
  }
  if (a == 0.0 && b == 0.0) {
    return Hcl(double.nan, 0.0 < l && l < 100.0 ? 0.0 : double.nan, l, opacity);
  }
  // DIVERGES(d3-color): platform-color-trig-last-bit, dart:math atan2.
  final h = atan2(b, a) * degrees;
  return Hcl(h < 0.0 ? h + 360.0 : h, sqrt(a * a + b * b), l, opacity);
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
  Hcl brighter([double? k]) => Hcl(h, c, l + _k * (k ?? 1.0), opacity);

  /// lab.js:117 `darker(k)`.
  @override
  Hcl darker([double? k]) => Hcl(h, c, l - _k * (k ?? 1.0), opacity);

  /// lab.js:120 `rgb()`.
  @override
  Rgb rgb() {
    // DIVERGES(d3-color): adapt-color-convert-locals, hcl2lab in locals.
    if (this.h.isNaN) return _lab2rgb(l, 0, 0, opacity);
    final h = this.h * radians;
    // DIVERGES(d3-color): platform-color-trig-last-bit, dart:math cos, sin.
    return _lab2rgb(l, cos(h) * c, sin(h) * c, opacity);
  }

  /// color.js:181 `formatRgb()`: `this.rgb().formatRgb()`, with the lines
  /// of lab.js:120 `rgb()`.
  ///
  /// A subclass can override [rgb], so only an [Hcl] of this exact class
  /// takes the form in locals.
  @override
  String formatRgb() {
    if (!formatRgbInLocals || runtimeType != Hcl) return rgb().formatRgb();
    // DIVERGES(d3-color): adapt-color-format-locals, no temporary Rgb.
    double a;
    double b;
    if (h.isNaN) {
      a = 0;
      b = 0;
    } else {
      final h = this.h * radians;
      // DIVERGES(d3-color): platform-color-trig-last-bit, dart:math cos, sin.
      a = cos(h) * c;
      b = sin(h) * c;
    }
    final (r, g, bb) = _lab2channels(l, a, b);
    return rgbText(r, g, bb, opacity);
  }
}

/// lab.js:107 `hcl2lab(o)`.
Lab hcl2lab(Hcl o) {
  if (o.h.isNaN) return Lab(o.l, 0, 0, o.opacity);
  final h = o.h * radians;
  // DIVERGES(d3-color): platform-color-trig-last-bit, dart:math cos, sin.
  return Lab(o.l, cos(h) * o.c, sin(h) * o.c, o.opacity);
}
