// Ported from @kurkle/color v0.3.2 src/color.js (MIT, Jukka Kurkela).
// DIVERGES(kurkle): adapt-kurkle-color-extension, methods on Flutter Color.

/// Port of `src/color.js` of @kurkle/color 0.3.2: the methods of the class
/// `Color` as the extension [KurkleColor] on the Flutter [Color]
/// (Chart.js ADR 0171).
///
/// Upstream, a `Color` holds an RGBA object, and each method changes that
/// object and returns the color. The port has no second color class. Each
/// method reads the RGBA bytes of the Flutter color, as the upstream
/// constructor stores them, runs the upstream arithmetic on them and
/// returns a new Flutter color. Thus a chain such as
/// `saturate(0.5).darken(0.1)` gives the bytes of upstream.
///
/// The methods `rgbString`, `hexString`, `hslString`, `rotate` and
/// `interpolate` have the names of the module functions that they call. In
/// the extension, a bare name finds the method first. Thus the file also
/// imports the public library with the prefix `kurkle` for these calls.
///
/// @packageDocumentation
/// @module index
library;

import 'dart:math';
import 'dart:ui';

import 'package:flutter_kurkle_color_port/flutter_kurkle_color_port.dart';
import 'package:flutter_kurkle_color_port/flutter_kurkle_color_port.dart'
    as kurkle;

/// color.js:24 `modHSL`.
///
/// Modify HSL properties. [i] is the index [0=h, 1=s, 2=l], and [ratio] the
/// ratio [0..1].
void _modHSL(RGBA? v, int i, double ratio) {
  if (v != null) {
    var tmp = rgb2hsl(v);
    tmp[i] = max(0, min(tmp[i] + tmp[i] * ratio, i == 0 ? 360.0 : 1.0));
    // DIVERGES(kurkle): adapt-kurkle-hue-arrays, performance optimisations.
    tmp = hsl2rgb(tmp[0], tmp[1], tmp[2]);
    v
      ..r = tmp[0]
      ..g = tmp[1]
      ..b = tmp[2];
  }
}

/// color.js:41 `clone`.
///
/// `v ? Object.assign(proto || {}, v) : v`. A falsy [v] (`null`, `false`,
/// 0, NaN or `''`) gives Dart `null`. The callers then throw, as JavaScript
/// throws a `TypeError` when it sets `a` on `undefined` or another falsy
/// primitive in strict mode. A
/// truthy value that is not an [RGBA] or a `Map` has no own `r`, `g`, `b`
/// and `a`, so the copy changes nothing.
RGBA? _clone(Object? v, [RGBA? proto]) {
  if (_falsy(v)) {
    return null;
  }
  // The members of `{}` are undefined, which ToNumber makes NaN.
  final target =
      proto ?? RGBA(r: double.nan, g: double.nan, b: double.nan, a: double.nan);
  // DIVERGES(kurkle): adapt-kurkle-rgba, copy r, g, b and a as numbers.
  if (v is RGBA) {
    target
      ..r = v.r
      ..g = v.g
      ..b = v.b
      ..a = v.a;
  } else if (v is Map) {
    if (v.containsKey('r')) target.r = toNumber(v['r']);
    if (v.containsKey('g')) target.g = toNumber(v['g']);
    if (v.containsKey('b')) target.b = toNumber(v['b']);
    if (v.containsKey('a')) target.a = toNumber(v['a']);
  }
  return target;
}

/// color.js:49 `fromObject`.
///
/// [input] is an RGBA object or a `List` (a JS array).
RGBA _fromObject(Object? input) {
  var v = RGBA(r: 0, g: 0, b: 0, a: 255);
  if (input is List) {
    if (input.length >= 3) {
      v = RGBA(
        // DIVERGES(kurkle): adapt-kurkle-rgba, ToNumber of r, g and b.
        r: toNumber(input[0]),
        g: toNumber(input[1]),
        b: toNumber(input[2]),
        a: 255,
      );
      if (input.length > 3) {
        v.a = n2b(toNumber(input[3]));
      }
    }
  } else {
    // A falsy input throws here, as `v.a` throws a TypeError in JavaScript.
    v = _clone(input, RGBA(r: 0, g: 0, b: 0, a: 1))!;
    v.a = n2b(v.a);
  }
  return v;
}

/// The JS falsy values among the inputs of [_clone]: Dart `null` (JS
/// `undefined`), `false`, 0, NaN and `''`.
bool _falsy(Object? v) => switch (v) {
  null => true,
  final bool b => !b,
  final num n => n == 0 || n.isNaN,
  final String s => s.isEmpty,
  _ => false,
};

/// `typeof value` for the Dart values that stand for JS values: Dart `null`
/// is `'undefined'`, and every object that is not a function is `'object'`.
String _typeOf(Object? value) => switch (value) {
  null => 'undefined',
  bool() => 'boolean',
  num() => 'number',
  String() => 'string',
  Symbol() => 'symbol',
  Function() => 'function',
  _ => 'object',
};

/// The RGBA bytes of [color], as the upstream constructor stores them: `r`,
/// `g` and `b` are the rounded bytes [0..255] of the extended sRGB channels,
/// and `a` is the unrounded byte [0..255] of the alpha.
RGBA _bytes(Color color) {
  final native = color.withValues(colorSpace: ColorSpace.extendedSRGB);
  return RGBA(
    r: _byte(native.r),
    g: _byte(native.g),
    b: _byte(native.b),
    // Native alpha normalization keeps the former clamping. `clamp`
    // makes NaN the maximum: a NaN alpha, as `hexParse` gives it for a
    // non-hex digit, stays NaN.
    a: native.a.isNaN ? native.a : native.a.clamp(0.0, 1.0) * 255,
  );
}

/// The rounded byte [0..255] of the channel [value]. A channel that is not
/// finite stays as it is: an object input with a NaN member gives it, and
/// `rgbString` prints it, as upstream prints the member.
double _byte(double value) {
  final byte = value * 255;
  return byte.isFinite ? byte.round().clamp(0, 255).toDouble() : byte;
}

/// The Flutter color of the RGBA bytes [v], whose `a` is a byte [0..255].
Color _color(RGBA v) => Color.from(
  alpha: v.a / 255,
  red: v.r / 255,
  green: v.g / 255,
  blue: v.b / 255,
);

/// The Flutter color of the bytes `r`, `g` and `b` of [v], with the alpha of
/// [color]. A method that does not change the alpha keeps it unrounded.
Color _withRgb(Color color, RGBA v) => Color.from(
  alpha: color.a,
  red: v.r / 255,
  green: v.g / 255,
  blue: v.b / 255,
);

/// color.js:76 `Color`, the default export of `color.js`: its methods on the
/// Flutter color.
///
/// Each method returns a new color and leaves this color unchanged. The
/// upstream `clone` has no port, because a Flutter color does not change.
/// The upstream `valid` has no port, because a Flutter color is always a
/// color.
extension KurkleColor on Color {
  /// color.js:81 `constructor` for an object [input]: an [RGBA], a `Map`
  /// with the keys `r`, `g`, `b` and `a`, or a `List` `[r, g, b]` or
  /// `[r, g, b, a]`, where `a` is alpha [0..1]. A Flutter color gives that
  /// color.
  ///
  /// A string throws an `ArgumentError` (Chart.js ADR 0057). Another input
  /// that is not an object gives Dart `null`, a color that is not valid.
  static Color? of(Object? input) {
    if (input is Color) {
      return input;
    }
    // DIVERGES(kurkle): adapt-direct-colors, no string color constructor.
    if (input is String) {
      throw ArgumentError.value(
        input,
        'color',
        'CSS color strings are unsupported; use Flutter Color',
      );
    }
    if (_typeOf(input) == 'object') {
      return _color(_fromObject(input));
    }
    return null;
  }

  /// The Flutter color of the RGBA bytes [value], whose `a` is a byte
  /// [0..255], as the parse functions give it.
  static Color fromRgbaBytes(RGBA value) => _color(value);

  /// The RGBA bytes of this color, with `a` as the unrounded byte [0..255].
  RGBA get rgbaBytes => _bytes(this);

  /// color.js:112 `get rgb`.
  ///
  /// A copy of the color with `a` as alpha [0..1].
  RGBA get rgb {
    // DIVERGES(kurkle): adapt-kurkle-color-copies, performance optimisations.
    final v = _bytes(this);
    return v..a = b2n(v.a);
  }

  /// color.js:131 `rgbString`.
  ///
  /// rgb(a) string.
  String rgbString() {
    return kurkle.rgbString(_bytes(this))!;
  }

  /// color.js:139 `hexString`.
  ///
  /// hex string.
  String hexString() {
    return kurkle.hexString(_bytes(this));
  }

  /// color.js:147 `hslString`.
  ///
  /// hsl(a) string.
  String hslString() {
    return kurkle.hslString(_bytes(this))!;
  }

  /// color.js:157 `mix`.
  ///
  /// Mix [color] into this color. [weight] is 0..1. Dart `null` stands for
  /// an `undefined` [color] or [weight]: an absent [color] gives this color.
  Color mix(Color? color, [double? weight]) {
    if (color == null) {
      return this;
    }
    final c1 = rgb;
    final c2 = color.rgb;
    // weight === w2 ? 0.5 : weight, where w2 is still undefined.
    final p = weight ?? 0.5;
    final w = 2 * p - 1;
    final a = c1.a - c2.a;
    final w1 = ((w * a == -1 ? w : (w + a) / (1 + w * a)) + 1) / 2.0;
    final w2 = 1 - w1;
    // 0xFF & x: 255 & ToInt32(x).
    c1
      ..r = _mixByte(w1 * c1.r + w2 * c2.r + 0.5)
      ..g = _mixByte(w1 * c1.g + w2 * c2.g + 0.5)
      ..b = _mixByte(w1 * c1.b + w2 * c2.b + 0.5)
      ..a = p * c1.a + (1 - p) * c2.a;
    // DIVERGES(kurkle): adapt-kurkle-color-copies, performance
    // optimisations.
    return _color(c1..a = n2b(c1.a));
  }

  /// color.js:182 `interpolate`.
  ///
  /// Interpolate a color value between this and [color]. [t] is 0..1.
  Color interpolate(Color? color, double t) {
    if (color == null) {
      return this;
    }
    return _color(kurkle.interpolate(_bytes(this), _bytes(color), t));
  }

  /// color.js:202 `alpha`.
  ///
  /// Set alpha. [a] is the alpha [0..1].
  // DIVERGES(kurkle): adapt-kurkle-color-extension, `alpha` is a getter of
  // the Flutter Color.
  Color withAlphaRatio(double a) {
    return _color(_bytes(this)..a = n2b(a));
  }

  /// color.js:212 `clearer`.
  ///
  /// Make clearer. [ratio] is 0..1.
  Color clearer(double ratio) {
    // const rgb = this._rgb; rgb.a *= 1 - ratio;
    final v = _bytes(this);
    return _color(v..a *= 1 - ratio);
  }

  /// color.js:222 `greyscale`.
  ///
  /// Convert to grayscale.
  Color greyscale() {
    final rgb = _bytes(this);
    // http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
    final val = round(rgb.r * 0.3 + rgb.g * 0.59 + rgb.b * 0.11);
    rgb
      ..r = val
      ..g = val
      ..b = val;
    return _withRgb(this, rgb);
  }

  /// color.js:235 `opaquer`.
  ///
  /// Opaquer. [ratio] is 0..1.
  Color opaquer(double ratio) {
    // const rgb = this._rgb; rgb.a *= 1 + ratio;
    final v = _bytes(this);
    return _color(v..a *= 1 + ratio);
  }

  /// color.js:245 `negate`.
  ///
  /// Negates the rgb value.
  Color negate() {
    final v = _bytes(this);
    v
      ..r = 255 - v.r
      ..g = 255 - v.g
      ..b = 255 - v.b;
    return _withRgb(this, v);
  }

  /// color.js:258 `lighten`.
  ///
  /// Lighten. [ratio] is 0..1.
  Color lighten(double ratio) => _hsl(2, ratio);

  /// color.js:268 `darken`.
  ///
  /// Darken. [ratio] is 0..1.
  Color darken(double ratio) => _hsl(2, -ratio);

  /// color.js:278 `saturate`.
  ///
  /// Saturate. [ratio] is 0..1.
  Color saturate(double ratio) => _hsl(1, ratio);

  /// color.js:288 `desaturate`.
  ///
  /// Desaturate. [ratio] is 0..1.
  Color desaturate(double ratio) => _hsl(1, -ratio);

  /// color.js:298 `rotate`.
  ///
  /// Rotate by [deg] degrees.
  Color rotate(double deg) {
    final v = _bytes(this);
    kurkle.rotate(v, deg);
    return _withRgb(this, v);
  }

  /// `modHSL(this._rgb, i, ratio)` of `lighten`, `darken`, `saturate` and
  /// `desaturate`.
  Color _hsl(int i, double ratio) {
    final v = _bytes(this);
    _modHSL(v, i, ratio);
    return _withRgb(this, v);
  }
}

/// ToInt32 followed by a byte mask, retaining the full fallback for overflow.
@pragma('vm:prefer-inline')
double _mixByte(double value) {
  // DIVERGES(kurkle): adapt-kurkle-byte-bounds, performance optimisations.
  final integer = value > -2147483649.0 && value < 2147483648.0
      ? value.toInt()
      : toInt32(value);
  return (integer & 255) * 1.0;
}
