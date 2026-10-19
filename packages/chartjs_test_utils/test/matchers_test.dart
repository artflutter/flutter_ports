// Original code, not ported from Chart.js: tests of the harness matchers.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/helpers/helpers.config.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:test/test.dart';

// The pass and fail results follow chartjs-test-utils 0.4.0
// src/matchers.js and src/matchers.options.js: each case states the JS
// expression that gives the same result.

final class _Point implements Point {
  const _Point(this.x, this.y);

  @override
  final double? x;

  @override
  final double? y;
}

/// The mismatch text of [matcher] for [actual].
String _mismatch(Matcher matcher, Object? actual) {
  final state = <Object?, Object?>{};
  expect(matcher.matches(actual, state), isFalse);
  return matcher
      .describeMismatch(actual, StringDescription(), state, false)
      .toString();
}

void main() {
  group('toBeCloseToPixel', () {
    test('passes within 2 pixels', () {
      expect(100, toBeCloseToPixel(101.9));
      expect(100, toBeCloseToPixel(98.1));
      expect(100, isNot(toBeCloseToPixel(102)));
      expect(0, toBeCloseToPixel(-1.5));
    });

    test('passes within 0.5% of the larger value', () {
      // 1000 * 0.005 = 5.
      expect(1000, toBeCloseToPixel(1005));
      expect(1005, toBeCloseToPixel(1000));
      expect(1000, isNot(toBeCloseToPixel(1005.1)));
      expect(-1000, toBeCloseToPixel(-995));
    });

    test('coerces with ToNumber and fails on NaN', () {
      // isNaN('10') is false, and '10' - 11 is -1.
      expect('10', toBeCloseToPixel(11));
      expect(null, toBeCloseToPixel(1)); // null is 0.
      expect(undefined, isNot(toBeCloseToPixel(0)));
      expect(double.nan, isNot(toBeCloseToPixel(double.nan)));
      expect('a', isNot(toBeCloseToPixel(0)));
      expect(0, isNot(toBeCloseToPixel(undefined)));
    });

    test('compares infinite values as JS', () {
      // Infinity <= Infinity * 0.005 is true.
      expect(double.infinity, toBeCloseToPixel(0));
      // Infinity - Infinity is NaN, and NaN <= x and NaN < 2 are false.
      expect(double.infinity, isNot(toBeCloseToPixel(double.infinity)));
    });

    test('describes the expected value', () {
      expect(
        StringDescription().addDescriptionOf(toBeCloseToPixel(12)).toString(),
        'close to pixel 12 (0.5% or less than 2 px)',
      );
    });
  });

  group('toBeCloseToPoint', () {
    test('compares x and y after rounding to 2 places', () {
      expect(
        const _Point(11.6161, 12.6559),
        toBeCloseToPoint({
          'x': 11.616,
          'y': 12.656,
        }),
      );
      expect(
        const _Point(11.6161, 12.6559),
        toBeCloseToPoint(const _Point(11.62, 12.66)),
      );
      expect(
        const _Point(11.6149, 12.656),
        isNot(toBeCloseToPoint({'x': 11.616, 'y': 12.656})),
      );
    });

    test('reads a Map as an object literal', () {
      expect({'x': 1, 'y': 2, 'z': 3}, toBeCloseToPoint({'x': 1.001, 'y': 2}));
      // {x: 1}.y is undefined: NaN === NaN is false.
      expect({'x': 1}, isNot(toBeCloseToPoint({'x': 1})));
    });

    test('takes a null member as 0', () {
      // Math.round(null * 100) / 100 is 0.
      expect(const _Point(null, 0), toBeCloseToPoint({'x': 0, 'y': null}));
    });

    test('rounds half up as Math.round', () {
      // Math.round(-0.5) is -0 and Math.round(0.5) is 1.
      expect({'x': -0.005, 'y': 0}, toBeCloseToPoint({'x': 0, 'y': 0}));
      expect({'x': 0.005, 'y': 0}, toBeCloseToPoint({'x': 0.01, 'y': 0}));
    });
  });

  group('toEqualOneOf', () {
    test('passes when the value is === to one value', () {
      expect('top', toEqualOneOf(['left', 'top']));
      expect(2, toEqualOneOf([1, 2.0]));
      expect(-0.0, toEqualOneOf([0]));
      expect(undefined, toEqualOneOf([null, undefined]));
    });

    test('fails on another value or type', () {
      expect('2', isNot(toEqualOneOf([2])));
      expect(null, isNot(toEqualOneOf([undefined])));
      expect(double.nan, isNot(toEqualOneOf([double.nan])));
      expect(<Object?>[], isNot(toEqualOneOf([<Object?>[]])));
      expect(1, isNot(toEqualOneOf([])));
    });

    test('compares objects by reference', () {
      final object = <String, Object?>{'a': 1};
      expect(object, toEqualOneOf([object]));
      expect(
        object,
        isNot(
          toEqualOneOf([
            <String, Object?>{'a': 1},
          ]),
        ),
      );
    });
  });

  group('toEqualOptions', () {
    test('compares the keys of the expected object only', () {
      expect(
        {'a': 1, 'b': 'x', 'c': true},
        toEqualOptions({'a': 1, 'b': 'x'}),
      );
      expect({'a': 1}, isNot(toEqualOptions({'a': 1, 'b': 'x'})));
    });

    test('skips the expected keys that start with _', () {
      expect({'a': 1}, toEqualOptions({'a': 1, '_fallback': true}));
    });

    test('compares nested objects and arrays', () {
      expect(
        {
          'a': {'b': 1, 'c': 2},
          'list': [
            1,
            'x',
            <String, Object?>{'d': 3, 'e': 4},
          ],
        },
        toEqualOptions({
          'a': {'b': 1},
          'list': [
            1,
            'x',
            {'d': 3},
          ],
        }),
      );
    });

    test('an absent key is undefined', () {
      expect(<String, Object?>{}, toEqualOptions({'a': undefined}));
      expect(<String, Object?>{}, isNot(toEqualOptions({'a': null})));
      expect({'a': null}, isNot(toEqualOptions({'a': undefined})));
    });

    test('reads a resolver through its get trap', () {
      final resolver = createResolver([
        <String, Object?>{'color': 'red'},
        <String, Object?>{'color': 'blue', 'size': 2},
      ]);
      expect(resolver, toEqualOptions({'color': 'red', 'size': 2}));
      expect(resolver, isNot(toEqualOptions({'color': 'blue'})));
    });

    test('reports each difference with its path', () {
      expect(
        _mismatch(
          toEqualOptions({
            'a': 1,
            'b': {'c': 'x'},
            'd': [1, 2],
            'e': {'f': 1},
            'g': [1],
          }),
          {
            'a': 2,
            'b': {'c': 'y'},
            'd': [1],
            'e': 5,
            'g': 'z',
          },
        ),
        [
          'a: Expected 2 to equal 1',
          'b.c: Expected "y" to equal "x"',
          'd.length: Expected 1 to equal 2',
          'd[1]: Expected undefined to equal 2',
          'e: Expected 5 to be an object',
          'e.f: Expected undefined to equal 1',
          'g: Expected "z" to be an array',
          'g.length: Expected undefined to equal 1',
          'g[0]: Expected undefined to equal 1',
        ].join('\n'),
      );
    });

    test('formats objects and arrays as JSON', () {
      expect(
        _mismatch(
          toEqualOptions({'a': 1}),
          {
            'a': [1, 'x'],
          },
        ),
        'a: Expected [1,"x"] to equal 1',
      );
    });
  });
}
