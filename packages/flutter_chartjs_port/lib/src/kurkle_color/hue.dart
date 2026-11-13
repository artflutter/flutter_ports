// Ported from @kurkle/color v0.3.2 src/hue.js (MIT, Jukka Kurkela).

/// Port of `src/hue.js` of @kurkle/color 0.3.2: the notations `hsl()`,
/// `hsla()`, `hwb()` and `hsv()`, and the conversions between them and RGB.
///
/// Dart `RegExp` has the syntax and the semantics of JavaScript regular
/// expressions. A group that does not take part in the match is `undefined`
/// in JavaScript and `null` in Dart.
///
/// @packageDocumentation
/// @module utils
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/byte.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart' show RGBA;
import 'package:flutter_chartjs_port/src/kurkle_color/simple_parse.dart';

/// hue.js:15 `HUE_RE`.
final RegExp _hueRe = RegExp(
  r'^(hsla?|hwb|hsv)\(\s*([-+.e\d]+)(?:deg)?[\s,]+([-+.e\d]+)%[\s,]+([-+.e\d]+)%(?:[\s,]+([-+.e\d]+)(%)?)?\s*\)$',
);

/// hue.js:26 `hsl2rgbn`.
///
/// Converts hsl to rgb normalized. [h] is the hue [0..360], [s] the
/// saturation [0..1] and [l] the lightness [0..1]. The result is
/// `[r, g, b]`, each normalized to [0..1].
List<double> _hsl2rgbn(double h, double s, double l) {
  final a = s * math.min<double>(l, 1 - l);
  // Upstream gives f a default parameter k, and no caller passes k.
  double f(double n) {
    final k = (n + h / 30).remainder(12);
    return l -
        a *
            math.max<double>(
              math.min<double>(k - 3, math.min<double>(9 - k, 1)),
              -1,
            );
  }

  return [f(0), f(8), f(4)];
}

/// hue.js:44 `hsv2rgbn`.
///
/// Convert hsv to rgb normalized. [h] is the hue [0..360], [s] the
/// saturation [0..1] and [v] the value [0..1]. The result is `[r, g, b]`,
/// each normalized to [0..1].
List<double> _hsv2rgbn(double h, double s, double v) {
  // Upstream gives f a default parameter k, and no caller passes k.
  double f(double n) {
    final k = (n + h / 60).remainder(6);
    return v -
        v *
            s *
            math.max<double>(
              math.min<double>(k, math.min<double>(4 - k, 1)),
              0,
            );
  }

  return [f(5), f(3), f(1)];
}

/// hue.js:60 `hwb2rgbn`.
///
/// Convert hwb to rgb normalized. [h] is the hue [0..360], [w] the
/// whiteness [0..1] and [b] the blackness [0..1]. The result is
/// `[r, g, b]`, each normalized to [0..1].
List<double> _hwb2rgbn(double h, double w, double b) {
  final rgb = _hsl2rgbn(h, 1, 0.5);
  if (w + b > 1) {
    final i = 1 / (w + b);
    // Upstream reassigns its parameters.
    // ignore: parameter_assignments
    w *= i;
    // Upstream reassigns its parameters.
    // ignore: parameter_assignments
    b *= i;
  }
  for (var i = 0; i < 3; i++) {
    rgb[i] *= 1 - w - b;
    rgb[i] += w;
  }
  return rgb;
}

/// hue.js:75 `hueValue`.
double _hueValue(double r, double g, double b, double d, double max) {
  if (r == max) {
    return ((g - b) / d) + (g < b ? 6 : 0);
  }
  if (g == max) {
    return (b - r) / d + 2;
  }
  return (r - g) / d + 4;
}

/// hue.js:90 `rgb2hsl`.
///
/// Convert rgb to hsl. The result is `[h, s, l]`.
List<double> rgb2hsl(RGBA v) {
  const range = 255;
  final r = v.r / range;
  final g = v.g / range;
  final b = v.b / range;
  final max = math.max(r, math.max(g, b));
  final min = math.min(r, math.min(g, b));
  final l = (max + min) / 2;
  double? h;
  double? s;
  if (max != min) {
    final d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    h = _hueValue(r, g, b, d, max);
    h = h * 60 + 0.5;
  }
  // `h | 0` and `s || 0`: an undefined h is NaN for ToInt32, which gives 0.
  // DIVERGES(chartjs): adapt-kurkle-hue-arrays, performance optimisations.
  // An if-element grows a list; the expression keeps a three-element literal.
  // ignore: prefer_if_elements_to_conditional_expressions
  return [jsToInt32(h ?? double.nan), jsTruthy(s) ? s! : 0, l];
}

/// hue.js:116 `calln`.
///
/// [a] is a number or a list of numbers (`Array.isArray`). A missing [b] or
/// [c], or a missing list element, is JS `undefined`, which arithmetic makes
/// NaN. Each argument of [f] goes through ToNumber, as the JS arithmetic in
/// [f] does: thus an `int`, a `List<num>` or a `List<Object?>` also works.
@pragma('vm:prefer-inline')
List<double> _calln(
  List<double> Function(double, double, double) f,
  Object a,
  num? b,
  num? c,
) {
  final rgb = a is List
      ? f(_at(a, 0), _at(a, 1), _at(a, 2))
      : f(
          jsToNumber(a),
          jsToNumber(b ?? undefined),
          jsToNumber(c ?? undefined),
        );
  // DIVERGES(chartjs): adapt-kurkle-hue-arrays, performance optimisations.
  for (var i = 0; i < 3; i++) {
    rgb[i] = n2b(rgb[i]);
  }
  return rgb;
}

/// The JS read `a[i]` of an array, through ToNumber. An index past the end
/// is `undefined`, which gives NaN.
double _at(List<Object?> a, int i) =>
    jsToNumber(i < a.length ? a[i] : undefined);

/// hue.js:131 `hsl2rgb`.
///
/// Convert hsl to rgb. [h] is the hue, or the list `[h, s, l]`.
@pragma('vm:prefer-inline')
List<double> hsl2rgb(Object h, [num? s, num? l]) {
  return _calln(_hsl2rgbn, h, s, l);
}

/// hue.js:142 `hwb2rgb`.
///
/// Convert hwb to rgb. [h] is the hue, or the list `[h, w, b]`.
@pragma('vm:prefer-inline')
List<double> hwb2rgb(Object h, [num? w, num? b]) {
  return _calln(_hwb2rgbn, h, w, b);
}

/// hue.js:153 `hsv2rgb`.
///
/// Convert hsv to rgb. [h] is the hue, or the list `[h, s, v]`.
@pragma('vm:prefer-inline')
List<double> hsv2rgb(Object h, [num? s, num? v]) {
  return _calln(_hsv2rgbn, h, s, v);
}

/// hue.js:161 `hue`.
double _hue(double h) {
  return (h.remainder(360) + 360).remainder(360);
}

/// hue.js:170 `hueParse`.
///
/// Parse hsl/hsv/hwb color string. Dart `null` stands for the JS
/// `undefined` result.
RGBA? hueParse(String str) {
  // DIVERGES(chartjs): adapt-kurkle-simple-colors, performance optimisations.
  final start = _hueStart(str);
  if (start != 0) {
    final simple = simpleColor(str, start, percentages: true);
    if (simple != null) {
      final h = _hue(simple.r);
      final p1 = simple.g / 100;
      final p2 = simple.b / 100;
      final rgb = str.codeUnitAt(1) == 119
          ? hwb2rgb(h, p1, p2)
          : str.codeUnitAt(2) == 118
          ? hsv2rgb(h, p1, p2)
          : hsl2rgb(h, p1, p2);
      simple
        ..r = rgb[0]
        ..g = rgb[1]
        ..b = rgb[2]
        ..a = n2b(simple.a);
      return simple;
    }
  }
  final m = _hueRe.firstMatch(str);
  var a = 255.0;
  List<double> v;
  if (m == null) {
    return null;
  }
  // v is undefined
  // DIVERGES(chartjs): adapt-kurkle-decimal-groups, performance optimisations.
  if (m[5] != null) {
    a = m[6] != null
        ? p2b(double.tryParse(m[5]!) ?? double.nan)
        : n2b(double.tryParse(m[5]!) ?? double.nan);
  }
  final h = _hue(double.tryParse(m[2]!) ?? double.nan);
  final p1 = (double.tryParse(m[3]!) ?? double.nan) / 100;
  final p2 = (double.tryParse(m[4]!) ?? double.nan) / 100;
  if (m[1] == 'hwb') {
    v = hwb2rgb(h, p1, p2);
  } else if (m[1] == 'hsv') {
    v = hsv2rgb(h, p1, p2);
  } else {
    v = hsl2rgb(h, p1, p2);
  }
  return RGBA(r: v[0], g: v[1], b: v[2], a: a);
}

/// hue.js:204 `rotate`.
///
/// Rotate the [v] color by [deg] degrees.
void rotate(RGBA v, double deg) {
  var h = rgb2hsl(v);
  h[0] = _hue(h[0] + deg);
  h = hsl2rgb(h);
  v
    ..r = h[0]
    ..g = h[1]
    ..b = h[2];
}

/// hue.js:218 `hslString`.
///
/// Return hsl(a) string from color components. Dart `null` stands for the
/// JS `undefined` color and result.
String? hslString(RGBA? v) {
  if (v == null) {
    return null;
  }
  final a = rgb2hsl(v);
  final h = a[0];
  final s = n2p(a[1]);
  final l = n2p(a[2]);
  return v.a < 255
      ? 'hsla(${jsNumberToString(h)}, ${jsNumberToString(s)}%, '
            '${jsNumberToString(l)}%, ${jsNumberToString(b2n(v.a))})'
      : 'hsl(${jsNumberToString(h)}, ${jsNumberToString(s)}%, '
            '${jsNumberToString(l)}%)';
}

int _hueStart(String s) {
  if (s.length < 4 || s.codeUnitAt(0) != 104) return 0;
  final c1 = s.codeUnitAt(1);
  final c2 = s.codeUnitAt(2);
  final c3 = s.codeUnitAt(3);
  if (c1 == 115 && c2 == 108) {
    if (c3 == 40) return 4;
    if (s.length >= 5 && c3 == 97 && s.codeUnitAt(4) == 40) return 5;
  } else if (((c1 == 115 && c2 == 118) || (c1 == 119 && c2 == 98)) &&
      c3 == 40) {
    return 4;
  }
  return 0;
}
