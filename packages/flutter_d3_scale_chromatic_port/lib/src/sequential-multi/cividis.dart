// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/cividis.js (ISC, Mike Bostock).

/// Port of `src/sequential-multi/cividis.js` of d3-scale-chromatic 3.1.0: the
/// "cividis" perceptually uniform sequential color scheme.
library;

import 'dart:math' as math;

import 'package:flutter_d3_color_port/d3_color.dart';

/// cividis.js:1 the default export (`interpolateCividis` of index.js:39):
/// returns the "cividis" color for [t] in `[0, 1]` as a new [Rgb].
///
/// Out-of-range finite and infinite [t] clamp to `[0, 1]`. A NaN [t] gives
/// `Rgb(NaN, NaN, NaN)`.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-color-values, returns Rgb.
Rgb interpolateCividis(double t) {
  final x = math.max<double>(0, math.min(1, t));
  return Rgb(
    math.max<double>(
      0,
      math.min(
        255,
        (-4.54 -
                x *
                    (35.34 -
                        x *
                            (2381.73 -
                                x * (6402.7 - x * (7024.72 - x * 2710.57)))))
            .roundToDouble(),
      ),
    ),
    math.max<double>(
      0,
      math.min(
        255,
        (32.49 +
                x *
                    (170.73 +
                        x * (52.82 - x * (131.46 - x * (176.58 - x * 67.37)))))
            .roundToDouble(),
      ),
    ),
    math.max<double>(
      0,
      math.min(
        255,
        (81.24 +
                x *
                    (442.36 -
                        x *
                            (2482.43 -
                                x * (6167.24 - x * (6614.94 - x * 2475.67)))))
            .roundToDouble(),
      ),
    ),
  );
}
