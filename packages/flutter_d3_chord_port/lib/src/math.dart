// Ported from d3-chord v3.0.1 src/math.js (ISC, Mike Bostock).

/// Port of `src/math.js` of d3-chord 3.0.1: math constants for chord and ribbon
/// geometry.
library;

import 'dart:math' as math;

/// `math.js:4` `pi`: `π`.
// DIVERGES(d3-chord): adapt-chord-typed-api, chord*-prefixed math constants.
const double chordPi = math.pi;

/// `math.js:5` `halfPi`: `π / 2`.
const double chordHalfPi = math.pi / 2;

/// `math.js:6` `tau`: `2π`.
const double chordTau = math.pi * 2;

/// `math.js:8` `epsilon`: geometric tolerance `1e-12`.
const double chordEpsilon = 1e-12;
