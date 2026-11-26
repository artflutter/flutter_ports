// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/turbo.js (ISC, Mike Bostock).

/// Port of `src/sequential-multi/turbo.js` of d3-scale-chromatic 3.1.0: Anton
/// Mikhailov's "turbo" rainbow color scheme.
library;

import 'dart:math' as math;

import 'package:flutter_d3_color_port/d3_color.dart';

/// turbo.js:1 the default export (`interpolateTurbo` of index.js:43):
/// returns the "turbo" color for [t] in `[0, 1]` as a new [Rgb].
///
/// Out-of-range finite and infinite [t] clamp to `[0, 1]`. A NaN [t] gives
/// `Rgb(NaN, NaN, NaN)`.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-color-values, returns Rgb.
Rgb interpolateTurbo(double t) {
  final x = math.max<double>(0, math.min(1, t));
  return Rgb(
    math.max<double>(
      0,
      math.min(
        255,
        (34.61 +
                x *
                    (1172.33 -
                        x *
                            (10793.56 -
                                x *
                                    (33300.12 -
                                        x * (38394.49 - x * 14825.05)))))
            .roundToDouble(),
      ),
    ),
    math.max<double>(
      0,
      math.min(
        255,
        (23.31 +
                x *
                    (557.33 +
                        x *
                            (1225.33 -
                                x * (3574.96 - x * (1073.77 + x * 707.56)))))
            .roundToDouble(),
      ),
    ),
    math.max<double>(
      0,
      math.min(
        255,
        (27.2 +
                x *
                    (3211.1 -
                        x *
                            (15327.97 -
                                x * (27814 - x * (22569.18 - x * 6838.66)))))
            .roundToDouble(),
      ),
    ),
  );
}
