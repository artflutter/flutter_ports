// Original code, not ported from Chart.js: the matcher of an element point.

/// The matcher of the point of `getCenterPoint` and `tooltipPosition`, an
/// [Offset] (Chart.js ADR 0188, row `adapt-offset-points`).
library;

import 'dart:ui';

import 'package:test/test.dart';

/// Matches an [Offset] with the coordinates [dx] and [dy]. NaN matches NaN,
/// as the `toEqual` of the upstream object literal `{x, y}` gives; the `==`
/// of two [Offset] values with NaN is false.
Matcher offsetOf(double dx, double dy) => isA<Offset>()
    .having((o) => o.dx, 'dx', dx.isNaN ? isNaN : dx)
    .having((o) => o.dy, 'dy', dy.isNaN ? isNaN : dy);

/// Matches an [Offset] with the coordinates of [expected], as [offsetOf].
Matcher offsetEquals(Offset expected) => offsetOf(expected.dx, expected.dy);
