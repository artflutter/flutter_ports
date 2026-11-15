// Original code, not ported from d3-color: the twin test of a faster form.

/// The twin test of the row `adapt-color-convert-locals`: `labConvert`,
/// `hclConvert` and `cubehelixConvert` read `o.rgb()` with no `rgbConvert`
/// copy, `hclConvert` keeps the Lab channels in locals, and `Hcl.rgb()`
/// keeps the channels of `hcl2lab` in locals. The test keeps the plain
/// translation of the upstream lines and compares each channel with the
/// port, bit for bit, on colors of each space.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_color_port/src/cubehelix.dart' show cubehelixConvert;
import 'package:flutter_d3_color_port/src/lab.dart' show hclConvert, labConvert;
import 'package:flutter_d3_color_port/src/math.dart';
import 'package:test/test.dart';

// lab.js:6-13.
const double _xn = 0.96422;
const double _yn = 1;
const double _zn = 0.82521;
const double _t0 = 4 / 29;
const double _t1 = 6 / 29;
const double _t2 = 3 * _t1 * _t1;
const double _t3 = _t1 * _t1 * _t1;

// cubehelix.js:5-12.
const double _a = -0.14861;
const double _b = 1.78277;
const double _c = -0.29227;
const double _d = -0.90649;
const double _e = 1.97294;
const double _ed = _e * _d;
const double _eb = _e * _b;
const double _bcDa = _b * _c - _d * _a;

const double _nan = double.nan;

/// color.js:229 `rgbConvert(o)`.
Rgb _rgbConvert(Color? o) {
  if (o == null) return Rgb(_nan, _nan, _nan, _nan);
  final c = o.rgb();
  return Rgb(c.r, c.g, c.b, c.opacity);
}

/// lab.js:15 `labConvert(o)`.
Lab _labConvert(Color? o) {
  if (o is Lab) return Lab(o.l, o.a, o.b, o.opacity);
  if (o is Hcl) return _hcl2lab(o);
  final c = o is Rgb ? o : _rgbConvert(o);
  final r = _rgb2lrgb(c.r);
  final g = _rgb2lrgb(c.g);
  final b = _rgb2lrgb(c.b);
  final y = _xyz2lab((0.2225045 * r + 0.7168786 * g + 0.0606169 * b) / _yn);
  double x;
  double z;
  if (r == g && g == b) {
    x = z = y;
  } else {
    x = _xyz2lab((0.4360747 * r + 0.3850649 * g + 0.1430804 * b) / _xn);
    z = _xyz2lab((0.0139322 * r + 0.0971045 * g + 0.7141733 * b) / _zn);
  }
  return Lab(116 * y - 16, 500 * (x - y), 200 * (y - z), c.opacity);
}

/// lab.js:52 `Lab.rgb()`.
Rgb _labRgb(Lab o) {
  var y = (o.l + 16) / 116;
  var x = o.a.isNaN ? y : y + o.a / 500;
  var z = o.b.isNaN ? y : y - o.b / 200;
  x = _xn * _lab2xyz(x);
  y = _yn * _lab2xyz(y);
  z = _zn * _lab2xyz(z);
  return Rgb(
    _lrgb2rgb(3.1338561 * x - 1.6168667 * y - 0.4906146 * z),
    _lrgb2rgb(-0.9787684 * x + 1.9161415 * y + 0.0334540 * z),
    _lrgb2rgb(0.0719453 * x - 0.2289914 * y + 1.4052427 * z),
    o.opacity,
  );
}

/// lab.js:68 `xyz2lab(t)`.
double _xyz2lab(double t) =>
    t > _t3 ? math.pow(t, 1 / 3).toDouble() : t / _t2 + _t0;

/// lab.js:72 `lab2xyz(t)`.
double _lab2xyz(double t) => t > _t1 ? t * t * t : _t2 * (t - _t0);

/// lab.js:76 `lrgb2rgb(x)`.
double _lrgb2rgb(double x) =>
    255 *
    (x <= 0.0031308
        ? 12.92 * x
        : 1.055 * math.pow(x, 1 / 2.4).toDouble() - 0.055);

/// lab.js:80 `rgb2lrgb(x)`.
double _rgb2lrgb(double x) {
  final v = x / 255;
  return v <= 0.04045
      ? v / 12.92
      : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}

/// lab.js:84 `hclConvert(o)`.
Hcl _hclConvert(Color? o) {
  if (o is Hcl) return Hcl(o.h, o.c, o.l, o.opacity);
  final c = o is Lab ? o : _labConvert(o);
  if (c.a == 0 && c.b == 0) {
    return Hcl(_nan, 0 < c.l && c.l < 100 ? 0 : _nan, c.l, c.opacity);
  }
  final h = math.atan2(c.b, c.a) * degrees;
  return Hcl(
    h < 0 ? h + 360 : h,
    math.sqrt(c.a * c.a + c.b * c.b),
    c.l,
    c.opacity,
  );
}

/// lab.js:107 `hcl2lab(o)`.
Lab _hcl2lab(Hcl o) {
  if (o.h.isNaN) return Lab(o.l, 0, 0, o.opacity);
  final h = o.h * radians;
  return Lab(o.l, math.cos(h) * o.c, math.sin(h) * o.c, o.opacity);
}

/// lab.js:120 `Hcl.rgb()`.
Rgb _hclRgb(Hcl o) => _labRgb(_hcl2lab(o));

/// cubehelix.js:14 `cubehelixConvert(o)`.
Cubehelix _cubehelixConvert(Color? o) {
  if (o is Cubehelix) return Cubehelix(o.h, o.s, o.l, o.opacity);
  final c = o is Rgb ? o : _rgbConvert(o);
  final r = c.r / 255;
  final g = c.g / 255;
  final b = c.b / 255;
  final l = (_bcDa * b + _ed * r - _eb * g) / (_bcDa + _ed - _eb);
  final bl = b - l;
  final k = (_e * (g - l) - _c * bl) / _d;
  final s = math.sqrt(k * k + bl * bl) / (_e * l * (1 - l));
  final h = s != 0 && !s.isNaN ? math.atan2(k, bl) * degrees - 120 : _nan;
  return Cubehelix(h < 0 ? h + 360 : h, s, l, c.opacity);
}

/// A color of no space of d3-color: its `rgb()` counts the calls.
final class _Counting() extends Color {
  /// The count of the calls of [rgb].
  int calls = 0;

  @override
  double opacity = 0.25;

  @override
  Rgb rgb() {
    calls++;
    return Rgb(12, 134, 56, 0.4);
  }

  @override
  Color copy({double? opacity}) => throw UnimplementedError();

  @override
  Color brighter([double? k]) => throw UnimplementedError();

  @override
  Color darker([double? k]) => throw UnimplementedError();
}

/// Whether [a] and [b] are the same double: NaN equals NaN, and -0 differs
/// from +0.
bool _same(double a, double b) =>
    a.isNaN ? b.isNaN : a == b && a.isNegative == b.isNegative;

List<double> _channels(Color c) => switch (c) {
  Rgb() => [c.r, c.g, c.b, c.opacity],
  Hsl() => [c.h, c.s, c.l, c.opacity],
  Lab() => [c.l, c.a, c.b, c.opacity],
  Hcl() => [c.h, c.c, c.l, c.opacity],
  Cubehelix() => [c.h, c.s, c.l, c.opacity],
  _ => throw ArgumentError(c),
};

/// The test values of one channel.
final class _Values(final math.Random random) {
  final ByteData _bytes = ByteData(8);

  static const List<double> edges = [
    0, -0.0, 0.5, 1, 10, 10.5, 11, 254.5, 255, 255.5, 256, -1, -255, 100, //
    1e-300, -1e-300, 5e-324, -5e-324, 1e300, -1e300, double.maxFinite,
    -double.maxFinite, double.infinity, double.negativeInfinity, double.nan,
  ];

  /// One value: an edge, a whole channel, a channel in a range, or random
  /// bits.
  double next(double min, double max) => switch (random.nextInt(8)) {
    0 => edges[random.nextInt(edges.length)],
    1 || 2 => random.nextInt(256).toDouble(),
    3 => _bits(),
    _ => min + random.nextDouble() * (max - min),
  };

  double _bits() {
    _bytes
      ..setUint32(0, random.nextInt(1 << 16) << 16 | random.nextInt(1 << 16))
      ..setUint32(4, random.nextInt(1 << 16) << 16 | random.nextInt(1 << 16));
    return _bytes.getFloat64(0);
  }
}

/// The colors of the test: RGB (also grays), HSL, Lab, HCL and Cubehelix.
List<Color> _colors() {
  final v = _Values(math.Random(20261115));
  final r = v.random;
  final colors = <Color>[];
  for (var i = 0; i < 4000; i++) {
    final opacity = r.nextInt(10) == 0 ? _nan : r.nextDouble();
    final red = v.next(-20, 280);
    colors.add(
      r.nextInt(6) == 0
          ? Rgb(red, red, red, opacity)
          : Rgb(red, v.next(-20, 280), v.next(-20, 280), opacity),
    );
  }
  for (var i = 0; i < 1500; i++) {
    final opacity = r.nextDouble();
    colors
      ..add(Hsl(v.next(-400, 400), v.next(0, 1), v.next(0, 1), opacity))
      ..add(Lab(v.next(-10, 110), v.next(-120, 120), v.next(-120, 120)))
      ..add(Hcl(v.next(-400, 400), v.next(0, 150), v.next(-10, 110), opacity))
      ..add(Cubehelix(v.next(-400, 400), v.next(0, 2), v.next(0, 1)));
  }
  return colors;
}

void main() {
  test('the conversions give the channels of the plain translation', () {
    final mismatches = <String>[];
    void compare(String label, Color actual, Color expected) {
      expect(actual.runtimeType, expected.runtimeType, reason: label);
      final a = _channels(actual);
      final e = _channels(expected);
      for (var k = 0; k < 4; k++) {
        if (!_same(a[k], e[k])) {
          mismatches.add('$label[$k]: ${a[k]} != ${e[k]}');
        }
      }
    }

    final colors = _colors();
    for (final o in [...colors, null]) {
      final text = '${_channels(o ?? Rgb(0, 0, 0))} ${o.runtimeType}';
      compare('labConvert($text)', labConvert(o), _labConvert(o));
      compare('hclConvert($text)', hclConvert(o), _hclConvert(o));
      compare(
        'cubehelixConvert($text)',
        cubehelixConvert(o),
        _cubehelixConvert(o),
      );
      if (o is Lab) compare('$text.rgb()', o.rgb(), _labRgb(o));
      if (o is Hcl) compare('$text.rgb()', o.rgb(), _hclRgb(o));
    }
    expect(colors.length, greaterThan(9000));
    expect(mismatches.take(20), isEmpty);
  });

  test('each conversion calls rgb() of another color once', () {
    for (final convert in <Color Function(Color)>[
      Rgb.from,
      Hsl.from,
      Lab.from,
      Hcl.from,
      Cubehelix.from,
    ]) {
      final o = _Counting();
      final expected = convert(Rgb(12, 134, 56, 0.4));
      final actual = convert(o);
      expect(o.calls, 1);
      expect(_channels(actual), _channels(expected));
    }
  });
}
