// Ported from @kurkle/color v0.3.2 src/color.js (MIT, Jukka Kurkela).

// The methods of Color return this for chaining, as upstream does.
// ignore_for_file: avoid_returning_this

/// Port of `src/color.js` of @kurkle/color 0.3.2: the class [Color].
///
/// The methods `rgbString`, `hexString`, `hslString`, `rotate` and
/// `interpolate` have the names of the module functions that they call. In a
/// Dart class, a bare name finds the member first. Thus the imports of these
/// functions have a prefix with the name of their upstream module.
///
/// A [Color] whose input does not parse has no color: its `_rgb` is JS
/// `undefined`, Dart `null` here. Dart `null` stands for JS `undefined` in
/// each input and result of the library. The methods that read `_rgb`
/// without a test throw for such a color, as they throw a `TypeError` in
/// JavaScript. A Dart null check throws a `TypeError` too.
///
/// @packageDocumentation
/// @module index
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_kurkle_color_port/src/byte.dart' show b2n, n2b, round;
import 'package:flutter_kurkle_color_port/src/hex.dart'
    as hex_js
    show hexString;
import 'package:flutter_kurkle_color_port/src/hue.dart'
    as hue_js
    show hslString, rotate;
import 'package:flutter_kurkle_color_port/src/hue.dart' show hsl2rgb, rgb2hsl;
import 'package:flutter_kurkle_color_port/src/index.esm.dart' show RGBA;
import 'package:flutter_kurkle_color_port/src/numbers.dart';
import 'package:flutter_kurkle_color_port/src/rgb.dart'
    as rgb_js
    show rgbString;
import 'package:flutter_kurkle_color_port/src/srgb.dart' as srgb_js;

/// color.js:24 `modHSL`.
///
/// Modify HSL properties. [i] is the index [0=h, 1=s, 2=l], and [ratio] the
/// ratio [0..1].
void _modHSL(RGBA? v, int i, double ratio) {
  if (v != null) {
    var tmp = rgb2hsl(v);
    tmp[i] = math.max(
      0,
      math.min(tmp[i] + tmp[i] * ratio, i == 0 ? 360.0 : 1.0),
    );
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

/// color.js:76 `Color`, the default export of `color.js`.
///
/// The color is mutable. Each manipulation method changes this color and
/// returns it.
class Color._(
  /// color.js:96 `_rgb`. The [RGBA] with `a` as a byte [0..255]. Dart `null`
  /// stands for JS `undefined`: the input did not parse.
  var RGBA? _rgb,
) {
  /// color.js:81 `constructor`.
  ///
  /// [input] is a [Color], an RGBA object (an [RGBA] or a `Map` with the keys
  /// `r`, `g`, `b` and `a`), or a `List` `[r, g, b]` or `[r, g, b, a]`.
  /// The constructor also accepts Flutter Color. Strings throw
  /// (ADR 0057). The `a` of an object or a list is alpha [0..1].
  ///
  /// A [Color] input gives that instance, as the JS constructor returns it.
  /// Another input that is not an object or a string gives a color that is
  /// not [valid], also Dart `null` (JS `undefined`).
  factory(Object? input) {
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
    if (input is ui.Color) {
      final native = input.withValues(colorSpace: ui.ColorSpace.extendedSRGB);
      return Color.fromRgbaBytes(
        RGBA(
          // js-ok: native Color normalization preserves byte rounding.
          r: (native.r * 255).round().clamp(0, 255).toDouble(),
          // js-ok: native Color normalization preserves byte rounding.
          g: (native.g * 255).round().clamp(0, 255).toDouble(),
          // js-ok: native Color normalization preserves byte rounding.
          b: (native.b * 255).round().clamp(0, 255).toDouble(),
          // js-ok: native alpha normalization keeps the former clamping.
          a: native.a.clamp(0.0, 1.0) * 255,
        ),
      );
    }
    RGBA? v;
    if (_typeOf(input) == 'object') {
      v = _fromObject(input);
    }
    return Color._(v);
  }

  /// Internal numerical construction with alpha in byte units. Native inputs
  /// do not require parsing or premature alpha rounding.
  factory fromRgbaBytes(RGBA value) =>
      Color._(RGBA(r: value.r, g: value.g, b: value.b, a: value.a));

  /// A copy of the numerical channels, including the unrounded byte alpha.
  RGBA? get rgbaBytes {
    final value = _rgb;
    return value == null
        ? null
        : RGBA(r: value.r, g: value.g, b: value.b, a: value.a);
  }

  /// color.js:98 `_valid`.
  final bool _valid = _rgb != null;

  /// color.js:105 `valid`.
  ///
  /// `true` if this is a valid color
  bool get valid {
    return _valid;
  }

  /// color.js:112 `get rgb`.
  ///
  /// A copy of the color with `a` as alpha [0..1]. Dart `null` stands for JS
  /// `undefined`, the color of an input that did not parse.
  RGBA? get rgb {
    // DIVERGES(kurkle): adapt-kurkle-color-copies, performance optimisations.
    final v = _rgb;
    return v == null ? null : RGBA(r: v.r, g: v.g, b: v.b, a: b2n(v.a));
  }

  /// color.js:123 `set rgb`.
  ///
  /// [obj] is an RGBA object or a `List`, with `a` as alpha [0..1]. It
  /// does not change [valid].
  set rgb(Object? obj) {
    _rgb = _fromObject(obj);
  }

  /// color.js:131 `rgbString`.
  ///
  /// rgb(a) string. Dart `null` stands for JS `undefined`.
  String? rgbString() {
    return _valid ? rgb_js.rgbString(_rgb) : null;
  }

  /// color.js:139 `hexString`.
  ///
  /// hex string. Dart `null` stands for JS `undefined`.
  String? hexString() {
    return _valid ? hex_js.hexString(_rgb) : null;
  }

  /// color.js:147 `hslString`.
  ///
  /// hsl(a) string. Dart `null` stands for JS `undefined`.
  String? hslString() {
    return _valid ? hue_js.hslString(_rgb) : null;
  }

  /// color.js:157 `mix`.
  ///
  /// Mix another color to this color. [weight] is 0..1. Dart `null` stands
  /// for an `undefined` [color] or [weight]. Chart.js passes a number.
  Color mix(Color? color, [double? weight]) {
    if (color != null) {
      final c1 = rgb;
      final c2 = color.rgb;
      // weight === w2 ? 0.5 : weight, where w2 is still undefined.
      final p = weight ?? 0.5;
      final w = 2 * p - 1;
      final a = c1!.a - c2!.a;
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
      _rgb = c1..a = n2b(c1.a);
    }
    return this;
  }

  /// color.js:182 `interpolate`.
  ///
  /// Interpolate a color value between this and [color]. [t] is 0..1.
  Color interpolate(Color? color, double t) {
    if (color != null) {
      _rgb = srgb_js.interpolate(_rgb!, color._rgb!, t);
    }
    return this;
  }

  /// color.js:193 `clone`.
  Color clone() {
    // DIVERGES(kurkle): adapt-kurkle-color-copies, performance optimisations.
    final v = _rgb;
    return v == null
        ? Color._(null)
        : Color._(RGBA(r: v.r, g: v.g, b: v.b, a: n2b(b2n(v.a))));
  }

  /// color.js:202 `alpha`.
  ///
  /// Set aplha. [a] is the alpha [0..1].
  Color alpha(double a) {
    _rgb!.a = n2b(a);
    return this;
  }

  /// color.js:212 `clearer`.
  ///
  /// Make clearer. [ratio] is 0..1.
  Color clearer(double ratio) {
    // const rgb = this._rgb; rgb.a *= 1 - ratio;
    _rgb!.a *= 1 - ratio;
    return this;
  }

  /// color.js:222 `greyscale`.
  ///
  /// Convert to grayscale.
  Color greyscale() {
    final rgb = _rgb!;
    // http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
    final val = round(rgb.r * 0.3 + rgb.g * 0.59 + rgb.b * 0.11);
    rgb
      ..r = val
      ..g = val
      ..b = val;
    return this;
  }

  /// color.js:235 `opaquer`.
  ///
  /// Opaquer. [ratio] is 0..1.
  Color opaquer(double ratio) {
    // const rgb = this._rgb; rgb.a *= 1 + ratio;
    _rgb!.a *= 1 + ratio;
    return this;
  }

  /// color.js:245 `negate`.
  ///
  /// Negates the rgb value.
  Color negate() {
    final v = _rgb!;
    v
      ..r = 255 - v.r
      ..g = 255 - v.g
      ..b = 255 - v.b;
    return this;
  }

  /// color.js:258 `lighten`.
  ///
  /// Lighten. [ratio] is 0..1.
  Color lighten(double ratio) {
    _modHSL(_rgb, 2, ratio);
    return this;
  }

  /// color.js:268 `darken`.
  ///
  /// Darken. [ratio] is 0..1.
  Color darken(double ratio) {
    _modHSL(_rgb, 2, -ratio);
    return this;
  }

  /// color.js:278 `saturate`.
  ///
  /// Saturate. [ratio] is 0..1.
  Color saturate(double ratio) {
    _modHSL(_rgb, 1, ratio);
    return this;
  }

  /// color.js:288 `desaturate`.
  ///
  /// Desaturate. [ratio] is 0..1.
  Color desaturate(double ratio) {
    _modHSL(_rgb, 1, -ratio);
    return this;
  }

  /// color.js:298 `rotate`.
  ///
  /// Rotate by [deg] degrees.
  Color rotate(double deg) {
    hue_js.rotate(_rgb!, deg);
    return this;
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
