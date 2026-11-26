// Ported from d3-path v3.1.0 test/pathRound-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:test/test.dart';

String _precision(String str, int precision) =>
    str.replaceAllMapped(RegExp(r'\d+\.\d+'), (m) {
      final v = double.parse(
        double.parse(m.group(0)!).toStringAsFixed(precision),
      );
      return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
    });

void main() {
  test('pathRound() defaults to three digits of precision', () {
    final p = pathRound()..moveTo(math.pi, math.e);
    expect('$p', 'M3.142,2.718');
  });

  test('pathRound(null) is equivalent to pathRound(0)', () {
    // Upstream coerces +null === 0; Dart pathRound takes non-nullable int
    // (D3 ADR 0014).
  }, skip: 'diverges: adapt-path-typed-args');

  test('pathRound(digits) validates the specified digits', () {
    expect(
      () => pathRound(-1),
      throwsA(
        isA<RangeError>().having(
          (e) => e.toString(),
          'message',
          contains('invalid digits'),
        ),
      ),
    );
  });

  test('pathRound(digits) ignores digits if greater than 15', () {
    final p = pathRound(40)..moveTo(math.pi, math.e);
    expect('$p', 'M3.141592653589793,2.718281828459045');
  });

  test('pathRound.moveTo(x, y) limits the precision', () {
    final p = pathRound(1)..moveTo(123.456, 789.012);
    expect('$p', 'M123.5,789');
  });

  test('pathRound.lineTo(x, y) limits the precision', () {
    final p = pathRound(1)
      ..moveTo(0, 0)
      ..lineTo(123.456, 789.012);
    expect('$p', 'M0,0L123.5,789');
  });

  test('pathRound.arc(x, y, r, a0, a1, ccw) limits the precision', () {
    final p0 = path();
    final p = pathRound(1);
    p0.arc(10.0001, 10.0001, 123.456, 0, math.pi + 0.0001);
    p.arc(10.0001, 10.0001, 123.456, 0, math.pi + 0.0001);
    expect('$p', _precision('$p0', 1));
    p0.arc(10.0001, 10.0001, 123.456, 0, math.pi - 0.0001);
    p.arc(10.0001, 10.0001, 123.456, 0, math.pi - 0.0001);
    expect('$p', _precision('$p0', 1));
    p0.arc(10.0001, 10.0001, 123.456, 0, math.pi / 2, true);
    p.arc(10.0001, 10.0001, 123.456, 0, math.pi / 2, true);
    expect('$p', _precision('$p0', 1));
  });

  test('pathRound.arcTo(x1, y1, x2, y2, r) limits the precision', () {
    final p0 = path()..arcTo(10.0001, 10.0001, 123.456, 456.789, 12345.6789);
    final p = pathRound(1)
      ..arcTo(10.0001, 10.0001, 123.456, 456.789, 12345.6789);
    expect('$p', _precision('$p0', 1));
  });

  test('pathRound.quadraticCurveTo(x1, y1, x, y) limits the precision', () {
    final p0 = path()..quadraticCurveTo(10.0001, 10.0001, 123.456, 456.789);
    final p = pathRound(1)
      ..quadraticCurveTo(10.0001, 10.0001, 123.456, 456.789);
    expect('$p', _precision('$p0', 1));
  });

  test(
    'pathRound.bezierCurveTo(x1, y1, x2, y2, x, y) limits the precision',
    () {
      final p0 = path()
        ..bezierCurveTo(10.0001, 10.0001, 123.456, 456.789, 0.007, 0.006);
      final p = pathRound(1)
        ..bezierCurveTo(10.0001, 10.0001, 123.456, 456.789, 0.007, 0.006);
      expect('$p', _precision('$p0', 1));
    },
  );

  test('pathRound.rect(x, y, w, h) limits the precision', () {
    final p0 = path()..rect(10.0001, 10.0001, 123.456, 456.789);
    final p = pathRound(1)..rect(10.0001, 10.0001, 123.456, 456.789);
    expect('$p', _precision('$p0', 1));
  });
}
