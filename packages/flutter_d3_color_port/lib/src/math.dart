// Ported from d3-color v3.1.0 src/math.js (ISC, Mike Bostock).

/// Port of `src/math.js` of d3-color 3.1.0: the factors between degrees and
/// radians.
library;

import 'dart:math';

/// math.js:1 `radians`: the radians of one degree.
const double radians = pi / 180;

/// math.js:2 `degrees`: the degrees of one radian.
const double degrees = 180 / pi;
