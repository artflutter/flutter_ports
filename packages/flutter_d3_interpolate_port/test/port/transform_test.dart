// Original code, not ported from d3-interpolate: the transform tests.

/// The tests of `src/transform/decompose.js` and `src/transform/index.js`.
///
/// Upstream has no active spec of them: the three cases of
/// `test/transformCss-test.js` are in a comment, because Node.js has no
/// `DOMMatrix`. The group `transformCss` runs them on the matrices of their
/// CSS texts, with the expected parts of their expected texts.
library;

import 'dart:math';

import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

/// Expects the six parts of [actual] within [delta] of [expected].
void _expectParts(
  TransformParts actual,
  TransformParts expected, [
  double delta = 1e-12,
]) {
  expect(actual.translateX, closeTo(expected.translateX, delta), reason: 'x');
  expect(actual.translateY, closeTo(expected.translateY, delta), reason: 'y');
  expect(actual.rotate, closeTo(expected.rotate, delta), reason: 'rotate');
  expect(actual.skewX, closeTo(expected.skewX, delta), reason: 'skewX');
  expect(actual.scaleX, closeTo(expected.scaleX, delta), reason: 'scaleX');
  expect(actual.scaleY, closeTo(expected.scaleY, delta), reason: 'scaleY');
}

/// The six parts of [p] as a List, for an exact compare.
List<double> _list(TransformParts p) => [
  p.translateX,
  p.translateY,
  p.rotate,
  p.skewX,
  p.scaleX,
  p.scaleY,
];

/// The radians of [degrees].
double _rad(double degrees) => degrees * pi / 180;

void main() {
  group('decompose', () {
    test('identity has the parts of the identity matrix', () {
      expect(_list(identity), [0, 0, 0, 0, 1, 1]);
      expect(_list(decompose(1, 0, 0, 1, 0, 0)), _list(identity));
    });

    test('decompose(a, b, c, d, e, f) reads e and f as the translation', () {
      expect(_list(decompose(1, 0, 0, 1, 5, -6)), [5, -6, 0, 0, 1, 1]);
    });

    test('decompose(a, b, c, d, e, f) reads a scale', () {
      expect(_list(decompose(2, 0, 0, 3, 0, 0)), [0, 0, 0, 0, 2, 3]);
    });

    test('decompose(a, b, c, d, e, f) reads a rotation in degrees', () {
      expect(_list(decompose(0, 1, -1, 0, 0, 0)), [0, 0, 90, 0, 1, 1]);
    });

    test('decompose(a, b, c, d, e, f) reads a skew in degrees', () {
      expect(_list(decompose(1, 0, 1, 1, 0, 0)), [0, 0, 0, 45, 1, 1]);
    });

    test('decompose(a, b, c, d, e, f) gives a flip a negative scaleX', () {
      final p = decompose(-1, 0, 0, 1, 0, 0);
      expect(_list(p), [0, 0, 0, 0, -1, 1]);
      // atan2(-0, 1): the flip negates b.
      expect(p.rotate.isNegative, isTrue);
    });

    test('decompose(1, 2, 3, 4, 5, 6) flips, rotates and skews', () {
      // The parts of the expected text of the second transformCss case.
      _expectParts(
        decompose(1, 2, 3, 4, 5, 6),
        const TransformParts(
          5,
          6,
          -116.56505117707799,
          -79.69515353123397,
          -2.23606797749979,
          0.8944271909999159,
        ),
      );
    });

    test('decompose(a, b, c, d, e, f) of a singular matrix has no skew', () {
      // scaleX is 0, so a and b stay 0 and skewX is 0.
      expect(_list(decompose(0, 0, 1, 0, 0, 0)), [0, 0, 0, 0, 0, 1]);
    });

    test('decompose(a, b, c, d, e, f) keeps a NaN', () {
      final p = decompose(double.nan, 0, 0, 1, 0, 0);
      expect(p.rotate.isNaN, isTrue);
      expect(p.scaleX.isNaN, isTrue);
      expect(p.translateX, 0);
    });
  });

  group('transformCss', () {
    test('translateY(12px) scale(2) to translateX(3em) rotate(5deg)', () {
      // "translate(24px, 6px) rotate(2.5deg) scale(1.5,1.5)"; 3em is 48px.
      final r = _rad(5);
      final i = interpolateTransform(
        decompose(2, 0, 0, 2, 0, 12),
        decompose(cos(r), sin(r), -sin(r), cos(r), 48, 0),
      );
      _expectParts(i(0.5), const TransformParts(24, 6, 2.5, 0, 1.5, 1.5));
    });

    test('matrix(1.0, 2.0, 3.0, 4.0, 5.0, 6.0) to translate(3px,90px)', () {
      // "translate(4px, 48px) rotate(-58.282525588538995deg)
      // skewX(-39.847576765616985deg)
      // scale(-0.6180339887498949,0.9472135954999579)"
      final i = interpolateTransform(
        decompose(1, 2, 3, 4, 5, 6),
        decompose(1, 0, 0, 1, 3, 90),
      );
      _expectParts(
        i(0.5),
        const TransformParts(
          4,
          48,
          -58.282525588538995,
          -39.847576765616985,
          -0.6180339887498949,
          0.9472135954999579,
        ),
      );
    });

    test('skewX(-60) to skewX(60) translate(280,0)', () {
      // "translate(140, 0) skewX(0)"
      final i = interpolateTransform(
        decompose(1, 0, tan(_rad(-60)), 1, 0, 0),
        decompose(1, 0, tan(_rad(60)), 1, 280, 0),
      );
      _expectParts(i(0.5), const TransformParts(140, 0, 0, 0, 1, 1));
    });
  });

  group('interpolateTransform', () {
    test('interpolateTransform(a, b) gives a at 0 and b at 1', () {
      const a = TransformParts(1, 2, 30, 10, 2, 3);
      const b = TransformParts(5, -6, 60, -20, 0.5, 4);
      final i = interpolateTransform(a, b);
      expect(_list(i(0)), _list(a));
      expect(_list(i(1)), _list(b));
      expect(_list(i(0.5)), [3, -2, 45, -5, 1.25, 3.5]);
    });

    test('interpolateTransform(a, b) keeps a part that is equal', () {
      // 0.2 * (1 - 0.3) + 0.2 * 0.3 is 0.19999999999999998: an equal part
      // does not interpolate, so it keeps its value.
      const a = TransformParts(0.2, 0.2, 0.2, 0.2, 1.3, 1.3);
      const b = TransformParts(0.2, 0.2, 0.2, 0.2, 1.3, 1.3);
      expect(_list(interpolateTransform(a, b)(0.3)), _list(b));
    });

    test('interpolateTransform(a, b) interpolates both translations '
        'when one differs', () {
      const a = TransformParts(0, 0.2, 0, 0, 1, 1);
      const b = TransformParts(10, 0.2, 0, 0, 1, 1);
      final p = interpolateTransform(a, b)(0.3);
      expect(p.translateX, 3);
      expect(p.translateY, 0.2 * (1 - 0.3) + 0.2 * 0.3);
      expect(p.translateY, isNot(0.2));
    });

    test('interpolateTransform(a, b) interpolates both scales '
        'when one differs', () {
      const a = TransformParts(0, 0, 0, 0, 1.3, 2);
      const b = TransformParts(0, 0, 0, 0, 1.3, 4);
      final p = interpolateTransform(a, b)(0.3);
      expect(p.scaleY, 2 * (1 - 0.3) + 4 * 0.3);
      expect(p.scaleX, 1.3 * (1 - 0.3) + 1.3 * 0.3);
      expect(p.scaleX, isNot(1.3));
    });

    test('interpolateTransform(a, b) keeps the parts of the identity', () {
      expect(_list(interpolateTransform(identity, identity)(0.5)), [
        0,
        0,
        0,
        0,
        1,
        1,
      ]);
    });

    test('interpolateTransform(a, b) gives 0 for an equal part of -0', () {
      // Upstream leaves out rotate(-0deg) and skewX(-0deg) from its text.
      // A -0 of a run time value: DDC folds the constant -0.0 to 0.
      final negativeZero = double.parse('-0');
      expect(negativeZero.isNegative, isTrue);
      final a = TransformParts(0, 0, negativeZero, negativeZero, 1, 1);
      final p = interpolateTransform(a, a)(0.5);
      expect(p.rotate.isNegative, isFalse);
      expect(p.skewX.isNegative, isFalse);
    });

    test('interpolateTransform(a, b) rotates along the shortest path', () {
      const a = TransformParts(0, 0, 170, 0, 1, 1);
      const b = TransformParts(0, 0, -170, 0, 1, 1);
      final i = interpolateTransform(a, b);
      expect(i(0).rotate, 170);
      expect(i(0.5).rotate, 180);
      expect(i(1).rotate, 190);
      final j = interpolateTransform(b, a);
      expect(j(0).rotate, 190);
      expect(j(0.5).rotate, 180);
      expect(j(1).rotate, 170);
    });

    test('interpolateTransform(a, b) keeps a rotation of 180 degrees', () {
      const a = TransformParts(0, 0, 0, 0, 1, 1);
      const b = TransformParts(0, 0, 180, 0, 1, 1);
      expect(interpolateTransform(a, b)(0.5).rotate, 90);
      expect(interpolateTransform(b, a)(0.5).rotate, 90);
    });

    test('interpolateTransform(a, b) returns a new value at each call', () {
      final i = interpolateTransform(
        identity,
        const TransformParts(1, 2, 3, 4, 5, 6),
      );
      final p = i(0.5);
      expect(identical(p, i(0.5)), isFalse);
      expect(_list(p), _list(i(0.5)));
    });
  });
}
