// Ported from d3-interpolate v3.0.1 src/hsl.js (ISC, Mike Bostock).

/// Port of `src/hsl.js` of d3-interpolate 3.0.1: the HSL interpolators
/// [interpolateHsl] (the shortest hue path) and [hslLong].
///
/// The interpolators take d3-color [Color] values and return an [Hsl]: a new
/// object at each call. Upstream returns the CSS text of one color object
/// that each call writes again; here `toString()` of the result gives that
/// text (decisions 1 and 2 of the design).
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';

/// hsl.js:4 `hsl(hue)`: the HSL interpolator from [start] to [end] with the
/// hue interpolation [hue].
///
/// Upstream returns the function of `start` and `end`; here they are the
/// second and third parameters of the same function.
Hsl Function(double t) _hsl(
  Channel Function(double a, double b) hue,
  Color start,
  Color end,
) {
  final s = Hsl.from(start);
  final e = Hsl.from(end);
  final h = hue(s.h, e.h);
  final sat = nogamma(s.s, e.s);
  final l = nogamma(s.l, e.l);
  final opacity = nogamma(s.opacity, e.opacity);
  // DIVERGES(d3-interpolate): adapt-interpolate-color-values, a new Hsl.
  return (t) => Hsl(h(t), sat(t), l(t), opacity(t));
}

/// hsl.js:20 the default export, `hsl(hue)`: the interpolator from [start]
/// to [end] in HSL, on the shortest path between the hues.
///
/// Both colors convert to HSL with `Hsl.from`. Each channel and the opacity
/// interpolate linearly; a NaN hue, saturation or lightness of one color
/// takes the channel of the other. Each call of the interpolator returns a
/// new [Hsl], whose `toString()` is the RGB text of upstream.
Hsl Function(double t) interpolateHsl(Color start, Color end) =>
    _hsl(hue, start, end);

/// hsl.js:21 `hslLong`, exported as `interpolateHslLong` (index.js:16): as
/// [interpolateHsl], but the hue interpolates linearly, not on the shortest
/// path.
Hsl Function(double t) hslLong(Color start, Color end) =>
    _hsl(nogamma, start, end);
