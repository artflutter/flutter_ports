// Original code, not ported from Chart.js: tests of lib/src/js/js_webidl.dart.
import 'dart:ui' show Color, Offset, StrokeCap, StrokeJoin;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:test/test.dart';

// The conversions follow the WebIDL types of the DOM setters: ToNumber for
// an unrestricted double and ToNumber of each item for a sequence of
// numbers. An undefined value gives Dart null, which the canvas layer
// ignores, as the DOM ignores the value.

void main() {
  group('canvasStyle', () {
    test('keeps paints and leaves foreign validation to the canvas', () {
      const gradient = ChartGradient.linear(Offset.zero, Offset(1, 1), []);
      const solid = ChartPaint.solid(Color(0xffff0000));
      expect(canvasStyle(undefined), isNull);
      expect(canvasStyle(null), isNull);
      expect(canvasStyle(solid), same(solid));
      expect(canvasStyle(gradient), same(gradient));
      for (final value in ['red', const Color(0xffff0000), Object(), false]) {
        expect(canvasStyle(value), same(value));
      }
    });
  });

  group('canvasNumber', () {
    test('gives null for undefined, else the ToNumber', () {
      expect(canvasNumber(undefined), isNull);
      expect(canvasNumber(null), 0.0);
      expect(canvasNumber(2), 2.0);
      expect(canvasNumber('1.5'), 1.5);
      expect(canvasNumber(true), 1.0);
      expect(canvasNumber('a'), isNaN);
      expect(canvasNumber(double.infinity), double.infinity);
    });
  });

  group('canvasLineCap and canvasLineJoin', () {
    test('a Flutter enum value gives itself', () {
      for (final cap in StrokeCap.values) {
        expect(canvasLineCap(cap), cap);
      }
      for (final join in StrokeJoin.values) {
        expect(canvasLineJoin(join), join);
      }
    });

    test('a value of another type gives null, which the canvas ignores', () {
      expect(canvasLineCap(undefined), isNull);
      expect(canvasLineCap(null), isNull);
      expect(canvasLineCap(1), isNull);
      expect(canvasLineCap(StrokeJoin.round), isNull);
      expect(canvasLineJoin(undefined), isNull);
      expect(canvasLineJoin(null), isNull);
      expect(canvasLineJoin(true), isNull);
      expect(canvasLineJoin(StrokeCap.round), isNull);
    });

    test('a keyword is not an enum value: a debug build stops', () {
      expect(() => canvasLineCap('round'), throwsA(isA<AssertionError>()));
      expect(() => canvasLineJoin('bevel'), throwsA(isA<AssertionError>()));
    });
  });

  group('canvasLineDash', () {
    test('gives the ToNumber of each item of a List', () {
      final segments = <double>[5, 3];
      expect(canvasLineDash(segments), same(segments));
      expect(canvasLineDash(<int>[4]), [4.0]);
      expect(canvasLineDash(<Object?>[1, '2', null, true]), [
        1.0,
        2.0,
        0.0,
        1.0,
      ]);
      expect(canvasLineDash(const <Object?>[]), isEmpty);
    });

    test('throws a TypeError for a value that is not a List', () {
      for (final value in <Object?>[undefined, null, 5, '5,3']) {
        expect(
          () => canvasLineDash(value),
          throwsA(isA<TypeError>()),
          reason: '$value',
        );
      }
    });
  });
}
