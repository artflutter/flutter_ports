// Ported from d3-color v3.1.0 test/asserts.js (ISC, Mike Bostock).

/// Port of `test/asserts.js` of d3-color 3.1.0: the channel assertions of
/// the specs, with the matchers of `package:test` (D3 ADR 0007).
///
/// An expected NaN asks for a NaN channel. The other channels compare
/// exactly, by `Math.round` or within 1e-6, as upstream.
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

/// asserts.js:4 `assertRgbEqual`: [actual] is an [Rgb] with exactly these
/// channels.
void assertRgbEqual(
  Object? actual,
  double r,
  double g,
  double b,
  double opacity,
) {
  expect(actual, isA<Rgb>());
  final c = actual! as Rgb;
  expect(
    _exact(c.r, r) &&
        _exact(c.g, g) &&
        _exact(c.b, b) &&
        _exact(c.opacity, opacity),
    isTrue,
    reason:
        'expected rgb($r, $g, $b, $opacity), '
        'actual rgb(${c.r}, ${c.g}, ${c.b}, ${c.opacity})',
  );
}

/// asserts.js:13 `assertRgbApproxEqual`: [actual] is an [Rgb] whose
/// channels round to the rounded expected channels, with exactly this
/// opacity.
void assertRgbApproxEqual(
  Object? actual,
  double r,
  double g,
  double b,
  double opacity,
) {
  expect(actual, isA<Rgb>());
  final c = actual! as Rgb;
  expect(
    _rounded(c.r, r) &&
        _rounded(c.g, g) &&
        _rounded(c.b, b) &&
        _exact(c.opacity, opacity),
    isTrue,
    reason:
        'expected rgb($r, $g, $b, $opacity), '
        'actual rgb(${c.r}, ${c.g}, ${c.b}, ${c.opacity})',
  );
}

/// asserts.js:21 `assertHclEqual`: [actual] is an [Hcl] with these channels
/// within 1e-6, with exactly this opacity.
void assertHclEqual(
  Object? actual,
  double h,
  double c,
  double l,
  double opacity,
) {
  expect(actual, isA<Hcl>());
  final x = actual! as Hcl;
  expect(
    _near(x.h, h) &&
        _near(x.c, c) &&
        _near(x.l, l) &&
        _exact(x.opacity, opacity),
    isTrue,
    reason:
        'expected hcl($h, $c, $l, $opacity), '
        'actual hcl(${x.h}, ${x.c}, ${x.l}, ${x.opacity})',
  );
}

/// asserts.js:30 `assertHslEqual`: [actual] is an [Hsl] with these channels
/// within 1e-6, with exactly this opacity.
void assertHslEqual(
  Object? actual,
  double h,
  double s,
  double l,
  double opacity,
) {
  expect(actual, isA<Hsl>());
  final x = actual! as Hsl;
  expect(
    _near(x.h, h) &&
        _near(x.s, s) &&
        _near(x.l, l) &&
        _exact(x.opacity, opacity),
    isTrue,
    reason:
        'expected hsl($h, $s, $l, $opacity), '
        'actual hsl(${x.h}, ${x.s}, ${x.l}, ${x.opacity})',
  );
}

/// asserts.js:39 `assertLabEqual`: [actual] is a [Lab] with these channels
/// within 1e-6, with exactly this opacity.
void assertLabEqual(
  Object? actual,
  double l,
  double a,
  double b,
  double opacity,
) {
  expect(actual, isA<Lab>());
  final x = actual! as Lab;
  expect(
    _near(x.l, l) &&
        _near(x.a, a) &&
        _near(x.b, b) &&
        _exact(x.opacity, opacity),
    isTrue,
    reason:
        'expected lab($l, $a, $b, $opacity), '
        'actual lab(${x.l}, ${x.a}, ${x.b}, ${x.opacity})',
  );
}

/// The test `isNaN(e) ? isNaN(a) : a === e`.
bool _exact(double actual, double expected) =>
    expected.isNaN ? actual.isNaN : actual == expected;

/// The test `isNaN(e) ? isNaN(a) : Math.round(a) === Math.round(e)`.
bool _rounded(double actual, double expected) =>
    expected.isNaN ? actual.isNaN : _round(actual) == _round(expected);

/// The test `isNaN(e) ? isNaN(a) : e - 1e-6 <= a && a <= e + 1e-6`.
bool _near(double actual, double expected) => expected.isNaN
    ? actual.isNaN
    : expected - 1e-6 <= actual && actual <= expected + 1e-6;

/// `Math.round`: the nearest whole number, a half rounds up.
double _round(double x) => (x + 0.5).floorToDouble();
