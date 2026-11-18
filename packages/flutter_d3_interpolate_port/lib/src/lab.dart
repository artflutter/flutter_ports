// Ported from d3-interpolate v3.0.1 src/lab.js (ISC, Mike Bostock).

/// Port of `src/lab.js` of d3-interpolate 3.0.1: the CIELAB interpolator
/// [interpolateLab].
///
/// The interpolator takes d3-color [Color] values and returns a [Lab]: a new
/// object at each call. Upstream returns the CSS text of one color object
/// that each call writes again; here `toString()` of the result gives that
/// text (decisions 1 and 2 of the design).
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';

/// lab.js:4 `lab(start, end)`, exported as `interpolateLab`: the
/// interpolator from [start] to [end] in CIELAB.
///
/// Both colors convert to Lab with `Lab.from`. Each channel and the opacity
/// interpolate linearly; a NaN channel of one color takes the channel of the
/// other. Each call of the interpolator returns a new [Lab], whose
/// `toString()` is the RGB text of upstream.
Lab Function(double t) interpolateLab(Color start, Color end) {
  final s = Lab.from(start);
  final e = Lab.from(end);
  final l = nogamma(s.l, e.l);
  final a = nogamma(s.a, e.a);
  final b = nogamma(s.b, e.b);
  final opacity = nogamma(s.opacity, e.opacity);
  // DIVERGES(d3-interpolate): adapt-interpolate-color-values, a new Lab.
  return (t) => Lab(l(t), a(t), b(t), opacity(t));
}
