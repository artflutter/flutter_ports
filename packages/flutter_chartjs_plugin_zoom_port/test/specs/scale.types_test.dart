// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/scale.types.test.ts (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' show acquireChart;
import 'package:flutter_chartjs_plugin_zoom_port/src/options.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/scale.types.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/state.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show Scale, undefined;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsToString;
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

/// scale.types.test.ts:5 `createCategoryScale({ categories, min, max,
/// width })`: a category scale of [categories] labels `'0'`, `'1'`, ...
/// with the range [min] to [max] and the [width] in pixels.
///
/// Upstream makes a fake scale, an object literal with the members that the
/// pan reads, and `options: {}`. A Dart `Scale` has typed members, and its
/// options are a resolver of the host that a test cannot make. Thus the
/// scale is the x scale of a real bar chart with these labels, a canvas of
/// [width] pixels and no padding, the axes and the legend hidden: the
/// checks below hold the members of the fake. Call it in a `testWidgets`
/// body.
// DIVERGES(zoom): harness-category-scale-fake, a scale of a real chart.
Scale createCategoryScale({
  required int categories,
  required double min,
  required double max,
  required double width,
}) {
  final labels = <Object?>[for (var i = 0; i < categories; i++) '$i'];
  final chart = acquireChart(
    <String, Object?>{
      'type': 'bar',
      'data': <String, Object?>{
        'labels': labels,
        'datasets': <Object?>[],
      },
      'options': <String, Object?>{
        'layout': <String, Object?>{'padding': 0},
        'plugins': <String, Object?>{
          'legend': <String, Object?>{'display': false},
        },
        'scales': <String, Object?>{
          'x': <String, Object?>{
            'type': 'category',
            'display': false,
            'min': min,
            'max': max,
          },
          'y': <String, Object?>{'display': false},
        },
      },
    },
    <String, Object?>{
      'canvas': <String, Object?>{'width': width, 'height': 100},
    },
  );
  final scale = chart.scales['x']!;
  expect(scale.id, 'x');
  expect(scale.axis, 'x');
  expect(scale.type, 'category');
  expect(scale.min, min);
  expect(scale.max, max);
  expect(scale.width, width);
  expect(scale.getLabels(), labels);
  expect(scale.isHorizontal(), isTrue);
  expect(scale.options.min, min);
  expect(scale.options.max, max);

  // `fixRange` reads the original limits for the scale, so they have to
  // exist.
  getState(chart).originalScaleLimits[scale.id] = (
    min: const OriginalLimit(),
    max: const OriginalLimit(),
  );

  return scale;
}

/// `ToNumber` of a JavaScript value of the table: NaN for `undefined`.
double _toNumber(Object? value) =>
    identical(value, undefined) ? double.nan : value! as double;

/// A number or `undefined` of the table as a `double?`.
double? _orNull(Object? value) =>
    identical(value, undefined) ? null : value! as double;

void main() {
  group('utils', () {
    group('zoomDelta', () {
      // The JavaScript values of the cases: `undefined` or a number. The
      // test name prints them as JavaScript does; `${expected}` of an object
      // is '[object Object]'.
      for (final (:val, :min, :range, :newRange, :expected)
          in <
            ({
              Object? val,
              Object? min,
              Object? range,
              Object? newRange,
              ({double min, double max}) expected,
            })
          >[
            (
              val: undefined,
              min: 100.0,
              range: 100.0,
              newRange: -10.0,
              expected: (min: -0.0, max: -10.0),
            ),
            (
              val: undefined,
              min: undefined,
              range: 1.0,
              newRange: 1.0,
              expected: (min: 0.0, max: 1.0),
            ),
            (
              val: undefined,
              min: undefined,
              range: undefined,
              newRange: 1.0,
              expected: (min: 0.0, max: 1.0),
            ),
            (
              val: undefined,
              min: undefined,
              range: undefined,
              newRange: undefined,
              expected: (min: double.nan, max: double.nan),
            ),

            (
              val: 0.0,
              min: 0.0,
              range: 0.0,
              newRange: 1.0,
              expected: (min: 0.0, max: 1.0),
            ),

            (
              val: 0.0,
              min: 0.0,
              range: 2.0,
              newRange: -1.0,
              expected: (min: -0.0, max: -1.0),
            ),

            (
              val: 0.0,
              min: 0.0,
              range: 1.0,
              newRange: 2.0,
              expected: (min: 0.0, max: 2.0),
            ),
            (
              val: 1.0,
              min: 0.0,
              range: 1.0,
              newRange: 2.0,
              expected: (min: 2.0, max: 0.0),
            ),
            (
              val: 1.0,
              min: 1.0,
              range: 1.0,
              newRange: 2.0,
              expected: (min: 0.0, max: 2.0),
            ),

            (
              val: 1.0,
              min: 0.0,
              range: 2.0,
              newRange: 4.0,
              expected: (min: 2.0, max: 2.0),
            ),
          ]) {
        test(
          'returns [object Object] for ${jsToString(val)}, ${jsToString(min)}, '
          '${jsToString(range)}, ${jsToString(newRange)},',
          () {
            // The table passes invalid values, as the @ts-expect-error of
            // upstream: `undefined` is `null` for the optional numbers and
            // its ToNumber NaN for the others.
            expect(
              zoomDelta(
                _orNull(val),
                _orNull(min),
                _toNumber(range),
                _toNumber(newRange),
              ),
              jasmineEquals(expected),
            );
          },
        );
      }
    });

    group('panFunctions.category', () {
      testWidgets(
        'pans by a proportional number of categories when they are wider '
        'than a pixel',
        (tester) async {
          // 400px / 20 visible categories = 20px per category, so a 25px drag
          // moves one category.
          final scale = createCategoryScale(
            categories: 100,
            min: 40,
            max: 59,
            width: 400,
          );

          panFunctions['category']!(scale, 25, const LimitOptions(emptyObject));

          expect(scale.options.min, toBe(39));
          expect(scale.options.max, toBe(58));
        },
      );

      testWidgets(
        'pans by a proportional number of categories when they are narrower '
        'than a pixel',
        (tester) async {
          // 400px / 5000 visible categories = 0.08px per category, so a 10px
          // drag moves 125 of them. Rounding that step down to a whole pixel
          // makes it 0, and panning then jumps to the end.
          final scale = createCategoryScale(
            categories: 10000,
            min: 4000,
            max: 8999,
            width: 400,
          );

          panFunctions['category']!(scale, 10, const LimitOptions(emptyObject));

          expect(scale.options.min, toBe(3875));
          expect(scale.options.max, toBe(8874));
        },
      );

      testWidgets('does not pan past the first category', (tester) async {
        final scale = createCategoryScale(
          categories: 10000,
          min: 50,
          max: 5049,
          width: 400,
        );

        panFunctions['category']!(scale, 10, const LimitOptions(emptyObject));

        expect(scale.options.min, toBe(0));
        expect(scale.options.max, toBe(4999));
      });

      testWidgets('does not pan past the last category', (tester) async {
        final scale = createCategoryScale(
          categories: 10000,
          min: 4950,
          max: 9949,
          width: 400,
        );

        panFunctions['category']!(
          scale,
          -10,
          const LimitOptions(emptyObject),
        );

        expect(scale.options.min, toBe(5000));
        expect(scale.options.max, toBe(9999));
      });
    });
  });
}
