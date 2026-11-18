// Original code, not ported from d3-interpolate: the Flutter matrix tests.

/// The tests of `lib/src/ui/transform_matrix.dart`: the `TransformParts` of
/// a `Matrix4` and back.
library;

import 'dart:math';

import 'package:flutter_d3_interpolate_port/flutter_d3_interpolate_port.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

/// The 2D affine matrix `matrix(a, b, c, d, e, f)` of CSS as a [Matrix4].
Matrix4 _css(double a, double b, double c, double d, double e, double f) =>
    Matrix4(a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, e, f, 0, 1);

/// Expects each of the 16 entries of [actual] within [delta] of [expected].
void _expectMatrix(Matrix4 actual, Matrix4 expected, [double delta = 1e-12]) {
  for (var i = 0; i < 16; i++) {
    expect(
      actual.storage[i],
      closeTo(expected.storage[i], delta),
      reason: 'entry $i of $actual',
    );
  }
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

void main() {
  group('toTransformParts', () {
    test('Matrix4.identity().toTransformParts() is the identity', () {
      expect(_list(Matrix4.identity().toTransformParts()), [0, 0, 0, 0, 1, 1]);
    });

    test('toTransformParts() decomposes the entries 0, 1, 4, 5, 12, 13', () {
      expect(
        _list(_css(1, 2, 3, 4, 5, 6).toTransformParts()),
        _list(decompose(1, 2, 3, 4, 5, 6)),
      );
    });

    test('toTransformParts() leaves out the z and perspective entries', () {
      final m = _css(1, 2, 3, 4, 5, 6)
        ..setEntry(2, 2, 7)
        ..setEntry(2, 3, 8)
        ..setEntry(3, 0, 0.5)
        ..setEntry(0, 2, 9);
      expect(_list(m.toTransformParts()), _list(decompose(1, 2, 3, 4, 5, 6)));
    });

    test('toTransformParts() reads the matrices of Flutter', () {
      final m = Matrix4.translationValues(5, 6, 0)
        ..rotateZ(pi / 6)
        ..scaleByDouble(2, 3, 1, 1);
      final p = m.toTransformParts();
      expect(p.translateX, 5);
      expect(p.translateY, 6);
      expect(p.rotate, closeTo(30, 1e-12));
      expect(p.skewX, closeTo(0, 1e-12));
      expect(p.scaleX, closeTo(2, 1e-12));
      expect(p.scaleY, closeTo(3, 1e-12));
    });
  });

  group('toMatrix4', () {
    test('toMatrix4() composes translate, rotate, skewX and scale', () {
      const p = TransformParts(5, 6, 30, 20, 2, 3);
      final expected = Matrix4.translationValues(5, 6, 0)
          .multiplied(Matrix4.rotationZ(pi / 6))
          .multiplied(Matrix4.skewX(20 * pi / 180))
          .multiplied(Matrix4.diagonal3Values(2, 3, 1));
      _expectMatrix(p.toMatrix4(), expected);
    });

    test('toMatrix4() of the identity is Matrix4.identity()', () {
      expect(identity.toMatrix4(), Matrix4.identity());
    });

    test('toMatrix4() of decompose(a, b, c, d, e, f) gives the matrix back '
        'within 1e-12', () {
      final random = Random(42);
      double next(double range) => (random.nextDouble() * 2 - 1) * range;
      var n = 0;
      while (n < 10000) {
        final a = next(10);
        final b = next(10);
        final c = next(10);
        final d = next(10);
        // A matrix with a small determinant has a large skew, whose tangent
        // loses digits.
        if ((a * d - b * c).abs() < 1) continue;
        n++;
        final m = _css(a, b, c, d, next(100), next(100));
        _expectMatrix(m.toTransformParts().toMatrix4(), m);
      }
    });

    test('toMatrix4() of a flip gives the flip back', () {
      final m = _css(-1, 0, 0, 1, 0, 0);
      expect(m.toTransformParts().scaleX, -1);
      _expectMatrix(m.toTransformParts().toMatrix4(), m);
    });
  });

  group('interpolateTransform', () {
    test('interpolateTransform(a, b) between two Matrix4 values', () {
      final a = Matrix4.translationValues(10, 0, 0);
      final b = Matrix4.translationValues(30, 40, 0)
        ..rotateZ(pi / 2)
        ..scaleByDouble(3, 3, 1, 1);
      final i = interpolateTransform(
        a.toTransformParts(),
        b.toTransformParts(),
      );
      _expectMatrix(i(0).toMatrix4(), a);
      _expectMatrix(i(1).toMatrix4(), b);
      final expected = Matrix4.translationValues(20, 20, 0)
        ..rotateZ(pi / 4)
        ..scaleByDouble(2, 2, 1, 1);
      _expectMatrix(i(0.5).toMatrix4(), expected);
    });
  });
}
