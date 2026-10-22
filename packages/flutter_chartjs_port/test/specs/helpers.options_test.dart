// Ported from Chart.js v4.5.1+7169e651 test/specs/helpers.options.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart'
    as chart
    show defaults;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:test/test.dart';

import '../support/jasmine.dart';

// A JavaScript object literal is a `Map<String, Object?>` and an array is a
// `List<Object?>` (Chart.js ADR 0006). `Chart.defaults` is the `defaults` Map
// of `core.defaults.dart`. Jasmine `toBe` is `same` for objects and `equals`
// for primitives, and `toBe(undefined)` is `same(undefined)`.
//
// The results of `toTRBLCorners`, `toPadding` and `toFont` are typed objects
// (differences.md row `adapt-options-typed-results`). The spec compares
// their members with the keys of the upstream object, through [_corners],
// [_padding] and [_font].

/// The members of a TRBL corners object, as the keys of the upstream object.
Map<String, Object?> _corners(TRBLCorners o) => {
  'topLeft': o.topLeft,
  'topRight': o.topRight,
  'bottomLeft': o.bottomLeft,
  'bottomRight': o.bottomRight,
};

/// The members of a padding object, as the keys of the upstream object.
Map<String, Object?> _padding(ChartArea o) => {
  'top': o.top,
  'right': o.right,
  'bottom': o.bottom,
  'left': o.left,
  'width': o.width,
  'height': o.height,
};

/// The members of a font object, as the keys of the upstream object.
Map<String, Object?> _font(ParsedFont o) => {
  'family': o.family,
  'lineHeight': o.lineHeight,
  'size': o.size,
  'string': o.string,
  'style': o.style,
  'weight': o.weight,
};

/// The JavaScript property read `context.v` of a scriptable option.
double _v(Object? context) =>
    (context! as Map<String, Object?>)['v']! as double;

void main() {
  setUpSpecs();
  group('Chart.helpers.options', () {
    group('toLineHeight', () {
      test('should support keyword values', () {
        expect(toLineHeight('normal', 16), 16 * 1.2);
      });
      test('should support unitless values', () {
        expect(toLineHeight(1.4, 16), 16 * 1.4);
        expect(toLineHeight('1.4', 16), 16 * 1.4);
      });
      test('should support length values', () {
        expect(toLineHeight('42px', 16), 42);
        expect(toLineHeight('1.4em', 16), 16 * 1.4);
      });
      test('should support percentage values', () {
        expect(toLineHeight('140%', 16), 16 * 1.4);
      });
      test('should fallback to default (1.2) for invalid values', () {
        expect(toLineHeight(null, 16), 16 * 1.2);
        expect(toLineHeight(undefined, 16), 16 * 1.2);
        expect(toLineHeight('foobar', 16), 16 * 1.2);
      });
    });

    group('toTRBLCorners', () {
      test('should support number values', () {
        expect(
          _corners(toTRBLCorners(4.0)),
          jasmineEquals({
            'topLeft': 4,
            'topRight': 4,
            'bottomLeft': 4,
            'bottomRight': 4,
          }),
        );
        expect(
          _corners(toTRBLCorners(4.5)),
          jasmineEquals({
            'topLeft': 4.5,
            'topRight': 4.5,
            'bottomLeft': 4.5,
            'bottomRight': 4.5,
          }),
        );
      });
      test('should support string values', () {
        expect(
          _corners(toTRBLCorners('4')),
          jasmineEquals({
            'topLeft': 4,
            'topRight': 4,
            'bottomLeft': 4,
            'bottomRight': 4,
          }),
        );
        expect(
          _corners(toTRBLCorners('4.5')),
          jasmineEquals({
            'topLeft': 4.5,
            'topRight': 4.5,
            'bottomLeft': 4.5,
            'bottomRight': 4.5,
          }),
        );
      });
      test('should support object values', () {
        expect(
          _corners(
            toTRBLCorners(<String, Object?>{
              'topLeft': 1.0,
              'topRight': 2.0,
              'bottomLeft': 3.0,
              'bottomRight': 4.0,
            }),
          ),
          jasmineEquals({
            'topLeft': 1,
            'topRight': 2,
            'bottomLeft': 3,
            'bottomRight': 4,
          }),
        );
        expect(
          _corners(
            toTRBLCorners(<String, Object?>{
              'topLeft': 1.5,
              'topRight': 2.5,
              'bottomLeft': 3.5,
              'bottomRight': 4.5,
            }),
          ),
          jasmineEquals({
            'topLeft': 1.5,
            'topRight': 2.5,
            'bottomLeft': 3.5,
            'bottomRight': 4.5,
          }),
        );
        expect(
          _corners(
            toTRBLCorners(<String, Object?>{
              'topLeft': '1',
              'topRight': '2',
              'bottomLeft': '3',
              'bottomRight': '4',
            }),
          ),
          jasmineEquals({
            'topLeft': 1,
            'topRight': 2,
            'bottomLeft': 3,
            'bottomRight': 4,
          }),
        );
      });
      test('should fallback to 0 for invalid values', () {
        const zero = <String, Object?>{
          'topLeft': 0,
          'topRight': 0,
          'bottomLeft': 0,
          'bottomRight': 0,
        };
        expect(
          _corners(
            toTRBLCorners(<String, Object?>{
              'topLeft': 'foo',
              'topRight': 'foo',
              'bottomLeft': 'foo',
              'bottomRight': 'foo',
            }),
          ),
          jasmineEquals(zero),
        );
        expect(
          _corners(
            toTRBLCorners(<String, Object?>{
              'topLeft': null,
              'topRight': null,
              'bottomLeft': null,
              'bottomRight': null,
            }),
          ),
          jasmineEquals(zero),
        );
        expect(
          _corners(toTRBLCorners(<String, Object?>{})),
          jasmineEquals(zero),
        );
        expect(_corners(toTRBLCorners('foo')), jasmineEquals(zero));
        expect(_corners(toTRBLCorners(null)), jasmineEquals(zero));
        expect(_corners(toTRBLCorners(undefined)), jasmineEquals(zero));
      });
    });

    group('toPadding', () {
      test('should support number values', () {
        expect(
          _padding(toPadding(4.0)),
          jasmineEquals({
            'top': 4,
            'right': 4,
            'bottom': 4,
            'left': 4,
            'height': 8,
            'width': 8,
          }),
        );
        expect(
          _padding(toPadding(4.5)),
          jasmineEquals({
            'top': 4.5,
            'right': 4.5,
            'bottom': 4.5,
            'left': 4.5,
            'height': 9,
            'width': 9,
          }),
        );
      });
      test('should support string values', () {
        expect(
          _padding(toPadding('4')),
          jasmineEquals({
            'top': 4,
            'right': 4,
            'bottom': 4,
            'left': 4,
            'height': 8,
            'width': 8,
          }),
        );
        expect(
          _padding(toPadding('4.5')),
          jasmineEquals({
            'top': 4.5,
            'right': 4.5,
            'bottom': 4.5,
            'left': 4.5,
            'height': 9,
            'width': 9,
          }),
        );
      });
      test('should support object values', () {
        expect(
          _padding(
            toPadding(<String, Object?>{
              'top': 1.0,
              'right': 2.0,
              'bottom': 3.0,
              'left': 4.0,
            }),
          ),
          jasmineEquals({
            'top': 1,
            'right': 2,
            'bottom': 3,
            'left': 4,
            'height': 4,
            'width': 6,
          }),
        );
        expect(
          _padding(
            toPadding(<String, Object?>{
              'top': 1.5,
              'right': 2.5,
              'bottom': 3.5,
              'left': 4.5,
            }),
          ),
          jasmineEquals({
            'top': 1.5,
            'right': 2.5,
            'bottom': 3.5,
            'left': 4.5,
            'height': 5,
            'width': 7,
          }),
        );
        expect(
          _padding(
            toPadding(<String, Object?>{
              'top': '1',
              'right': '2',
              'bottom': '3',
              'left': '4',
            }),
          ),
          jasmineEquals({
            'top': 1,
            'right': 2,
            'bottom': 3,
            'left': 4,
            'height': 4,
            'width': 6,
          }),
        );
      });
      test('should fallback to 0 for invalid values', () {
        const zero = <String, Object?>{
          'top': 0,
          'right': 0,
          'bottom': 0,
          'left': 0,
          'height': 0,
          'width': 0,
        };
        expect(
          _padding(
            toPadding(<String, Object?>{
              'top': 'foo',
              'right': 'foo',
              'bottom': 'foo',
              'left': 'foo',
            }),
          ),
          jasmineEquals(zero),
        );
        expect(
          _padding(
            toPadding(<String, Object?>{
              'top': null,
              'right': null,
              'bottom': null,
              'left': null,
            }),
          ),
          jasmineEquals(zero),
        );
        expect(_padding(toPadding(<String, Object?>{})), jasmineEquals(zero));
        expect(_padding(toPadding('foo')), jasmineEquals(zero));
        expect(_padding(toPadding(null)), jasmineEquals(zero));
        // The spec passes undefined explicitly.
        // ignore: avoid_redundant_argument_values
        expect(_padding(toPadding(undefined)), jasmineEquals(zero));
      });
      test('should support x / y shorthands', () {
        expect(
          _padding(toPadding(<String, Object?>{'x': 1.0, 'y': 2.0})),
          jasmineEquals({
            'top': 2,
            'right': 1,
            'bottom': 2,
            'left': 1,
            'height': 4,
            'width': 2,
          }),
        );
        expect(
          _padding(toPadding(<String, Object?>{'x': 1.0, 'left': 0.0})),
          jasmineEquals({
            'top': 0,
            'right': 1,
            'bottom': 0,
            'left': 0,
            'height': 0,
            'width': 1,
          }),
        );
        expect(
          _padding(toPadding(<String, Object?>{'y': 5.0, 'bottom': 0.0})),
          jasmineEquals({
            'top': 5,
            'right': 0,
            'bottom': 0,
            'left': 0,
            'height': 5,
            'width': 0,
          }),
        );
      });
    });

    group('toFont', () {
      test('should return a font with default values', () {
        final font = chart.defaults['font']! as Map<String, Object?>;
        // Object.assign({}, Chart.defaults.font)
        final defaultFont = Map<String, Object?>.of(font);

        // Object.assign(Chart.defaults.font, {...})
        font.addAll({
          'family': 'foobar',
          'size': 42.0,
          'style': 'oblique 9deg',
          'lineHeight': 1.5,
        });

        expect(
          _font(toFont(<String, Object?>{})),
          jasmineEquals({
            'family': 'foobar',
            'lineHeight': 63,
            'size': 42,
            'string': 'oblique 9deg 42px foobar',
            'style': 'oblique 9deg',
            'weight': null,
          }),
        );

        font.addAll(defaultFont);
      });
      test('should return a font with given values', () {
        expect(
          _font(
            toFont(<String, Object?>{
              'family': 'bla',
              'lineHeight': 8.0,
              'size': 21.0,
              'style': 'oblique -90deg',
            }),
          ),
          jasmineEquals({
            'family': 'bla',
            'lineHeight': 8 * 21,
            'size': 21,
            'string': 'oblique -90deg 21px bla',
            'style': 'oblique -90deg',
            'weight': null,
          }),
        );
      });
      test('should handle a string font size', () {
        expect(
          _font(
            toFont(<String, Object?>{
              'family': 'bla',
              'lineHeight': 8.0,
              'size': '21',
              'style': 'italic',
            }),
          ),
          jasmineEquals({
            'family': 'bla',
            'lineHeight': 8 * 21,
            'size': 21,
            'string': 'italic 21px bla',
            'style': 'italic',
            'weight': null,
          }),
        );
      });
      test(
        'should return null as a font string if size or family are missing',
        () {
          final font = chart.defaults['font']! as Map<String, Object?>;
          final fontFamily = font['family'];
          final fontSize = font['size'];
          font
            ..remove('family')
            ..remove('size');

          expect(
            toFont(<String, Object?>{'style': 'italic', 'size': 12.0}).string,
            isNull,
          );
          expect(
            toFont(<String, Object?>{
              'style': 'italic',
              'family': 'serif',
            }).string,
            isNull,
          );

          font['family'] = fontFamily;
          font['size'] = fontSize;
        },
      );
      test('font.style should be optional for font strings', () {
        final font = chart.defaults['font']! as Map<String, Object?>;
        final fontStyle = font['style'];
        font.remove('style');

        expect(
          toFont(<String, Object?>{'size': 12.0, 'family': 'serif'}).string,
          '12px serif',
        );

        font['style'] = fontStyle;
      });
    });

    group('resolve', () {
      test('should fallback to the first defined input', () {
        expect(resolve([42.0]), 42);
        expect(resolve([42.0, 'foo']), 42);
        expect(resolve([undefined, 42.0, 'foo']), 42);
        expect(resolve([42.0, 'foo', undefined]), 42);
        expect(resolve([undefined]), same(undefined));
      });
      test('should correctly handle empty values (null, 0, "")', () {
        expect(resolve([0.0, 'foo']), 0);
        expect(resolve(['', 'foo']), '');
        expect(resolve([null, 'foo']), isNull);
      });
      test('should support indexable options if index is provided', () {
        final input = <Object?>[42.0, 'foo', 'bar'];
        expect(resolve([input], undefined, 0), 42);
        expect(resolve([input], undefined, 1), 'foo');
        expect(resolve([input], undefined, 2), 'bar');
      });
      test('should fallback if an indexable option value is undefined', () {
        final input = <Object?>[42.0, undefined, 'bar'];
        expect(resolve([input], undefined, 1), same(undefined));
        expect(resolve([input, 'foo'], undefined, 1), 'foo');
      });
      test('should loop if an indexable option index is out of bounds', () {
        final input = <Object?>[42.0, undefined, 'bar'];
        expect(resolve([input], undefined, 3), 42);
        expect(resolve([input, 'foo'], undefined, 4), 'foo');
        expect(resolve([input, 'foo'], undefined, 5), 'bar');
      });
      test('should not handle indexable options if index is undefined', () {
        final array = <Object?>[42.0, 'foo', 'bar'];
        expect(resolve([array]), same(array));
        // Dart null is the undefined index (helpers.options.dart). The spec
        // passes undefined explicitly.
        // ignore: avoid_redundant_argument_values
        expect(resolve([array], undefined, null), same(array));
      });
      test('should support scriptable options if context is provided', () {
        double input(Object? context) {
          return _v(context) * 2;
        }

        expect(resolve([42.0], <String, Object?>{'v': 42.0}), 42);
        expect(resolve([input], <String, Object?>{'v': 42.0}), 84);
      });
      test('should fallback if a scriptable option returns undefined', () {
        Object? input() => undefined;
        expect(
          resolve([input], <String, Object?>{'v': 42.0}),
          same(undefined),
        );
        expect(resolve([input, 'foo'], <String, Object?>{'v': 42.0}), 'foo');
        expect(
          resolve([input, undefined, 'foo'], <String, Object?>{'v': 42.0}),
          'foo',
        );
      });
      test('should not handle scriptable options if context is undefined', () {
        double input(Object? context) {
          return _v(context) * 2;
        }

        expect(resolve([input]), same(input));
        // The spec passes undefined explicitly.
        // ignore: avoid_redundant_argument_values
        expect(resolve([input], undefined), same(input));
      });
      test('should handle scriptable and indexable option', () {
        List<Object?> input(Object? context) {
          return [_v(context), undefined, 'bar'];
        }

        expect(resolve([input, 'foo'], <String, Object?>{'v': 42.0}, 0), 42);
        expect(
          resolve([input, 'foo'], <String, Object?>{'v': 42.0}, 1),
          'foo',
        );
        expect(
          resolve([input, 'foo'], <String, Object?>{'v': 42.0}, 5),
          'bar',
        );
        expect(
          resolve(
            [
              input,
              <Object?>['foo', 'bar'],
            ],
            <String, Object?>{'v': 42.0},
            1,
          ),
          'bar',
        );
      });
    });
  });
}
