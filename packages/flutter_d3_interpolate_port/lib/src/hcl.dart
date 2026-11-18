// Ported from d3-interpolate v3.0.1 src/hcl.js (ISC, Mike Bostock).

/// Port of `src/hcl.js` of d3-interpolate 3.0.1: the HCL interpolators
/// [interpolateHcl] (the shortest hue path) and [hclLong].
///
/// The interpolators take d3-color [Color] values and return an [Hcl]: a new
/// object at each call. Upstream returns the CSS text of one color object
/// that each call writes again; here `toString()` of the result gives that
/// text (decisions 1 and 2 of the design).
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';

/// hcl.js:4 `hcl(hue)`: the HCL interpolator from [start] to [end] with the
/// hue interpolation [hue].
///
/// Upstream returns the function of `start` and `end`; here they are the
/// second and third parameters of the same function.
Hcl Function(double t) _hcl(
  Channel Function(double a, double b) hue,
  Color start,
  Color end,
) {
  final s = Hcl.from(start);
  final e = Hcl.from(end);
  final h = hue(s.h, e.h);
  final c = nogamma(s.c, e.c);
  final l = nogamma(s.l, e.l);
  final opacity = nogamma(s.opacity, e.opacity);
  // DIVERGES(d3-interpolate): adapt-interpolate-color-values, a new Hcl.
  return (t) => Hcl(h(t), c(t), l(t), opacity(t));
}

/// hcl.js:20 the default export, `hcl(hue)`: the interpolator from [start]
/// to [end] in HCL, on the shortest path between the hues.
///
/// Both colors convert to HCL with `Hcl.from`. Each channel and the opacity
/// interpolate linearly; a NaN hue, chroma or luminance of one color takes
/// the channel of the other. Each call of the interpolator returns a new
/// [Hcl], whose `toString()` is the RGB text of upstream.
Hcl Function(double t) interpolateHcl(Color start, Color end) =>
    _hcl(hue, start, end);

/// hcl.js:21 `hclLong`, exported as `interpolateHclLong` (index.js:18): as
/// [interpolateHcl], but the hue interpolates linearly, not on the shortest
/// path.
Hcl Function(double t) hclLong(Color start, Color end) =>
    _hcl(nogamma, start, end);
