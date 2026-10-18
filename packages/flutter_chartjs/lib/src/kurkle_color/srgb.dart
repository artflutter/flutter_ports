// Ported from @kurkle/color v0.3.2 src/srgb.js (MIT, Jukka Kurkela).

/// Port of `src/srgb.js` of @kurkle/color 0.3.2: the interpolation of two
/// colors in linear light. `index.esm.js` does not export this library.
/// `color.js` imports it.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs/src/kurkle_color/byte.dart';
import 'package:flutter_chartjs/src/kurkle_color/index.esm.dart' show RGBA;

/// srgb.js:7 `to`.
// DIVERGES(chartjs): js-semantics-dart-math, dart:math pow.
double _to(double v) => v <= 0.0031308
    ? v * 12.92
    // js-ok: double operands, dart:math pow (Chart.js ADR 0010).
    : math.pow(v, 1.0 / 2.4) * 1.055 - 0.055;

/// srgb.js:8 `from`.
// DIVERGES(chartjs): js-semantics-dart-math, dart:math pow.
double _from(double v) => v <= 0.04045
    ? v / 12.92
    // js-ok: double operands, dart:math pow (Chart.js ADR 0010).
    : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

/// srgb.js:16 `interpolate`.
///
/// Interpolates from the color [rgb1] to the color [rgb2] by [t] (0..1).
RGBA interpolate(RGBA rgb1, RGBA rgb2, double t) {
  final r = _from(b2n(rgb1.r));
  final g = _from(b2n(rgb1.g));
  final b = _from(b2n(rgb1.b));
  return RGBA(
    r: n2b(_to(r + t * (_from(b2n(rgb2.r)) - r))),
    g: n2b(_to(g + t * (_from(b2n(rgb2.g)) - g))),
    b: n2b(_to(b + t * (_from(b2n(rgb2.b)) - b))),
    a: rgb1.a + t * (rgb2.a - rgb1.a),
  );
}
