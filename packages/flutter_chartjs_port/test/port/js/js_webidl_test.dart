// Original code, not ported from Chart.js: tests of lib/src/js/js_webidl.dart.
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart';
import 'package:test/test.dart';

// The conversions follow the WebIDL types of the DOM setters: ToNumber for
// an unrestricted double, ToString for a DOMString, and ToNumber of each item
// for a sequence of numbers. An undefined value gives Dart null, which the
// canvas layer ignores, as the DOM ignores the value.

void main() {
  group('canvasStyle', () {
    test('gives null for undefined, else the value', () {
      final gradient = Object();
      expect(canvasStyle(undefined), isNull);
      expect(canvasStyle(null), isNull);
      expect(canvasStyle('red'), 'red');
      expect(canvasStyle(gradient), same(gradient));
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

  group('canvasKeyword', () {
    test('gives null for undefined and null, else the ToString', () {
      expect(canvasKeyword(undefined), isNull);
      expect(canvasKeyword(null), isNull);
      expect(canvasKeyword('round'), 'round');
      expect(canvasKeyword(''), '');
      expect(canvasKeyword(1), '1');
      expect(canvasKeyword(true), 'true');
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
