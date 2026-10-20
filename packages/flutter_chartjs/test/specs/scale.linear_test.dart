// Ported from Chart.js v4.5.1 test/specs/scale.linear.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs, which does not export lib/src
// yet.
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_test/flutter_test.dart';

// The spec reads Chart.registry and Chart.defaults: the static fields
// `Chart.registry` and `Chart.defaults` of core.controller.dart.
// flutter_test_config.dart registers the built-in components before main().
// Thus the linear scale is in the registry, and its defaults are in
// `Chart.defaults.scales.linear`.
//
// The chart cases call `acquireChart`. Thus they are `testWidgets` cases,
// and the file runs on the VM (Chart.js ADR 0022, sections 1 and 2). A case
// that needs a module of a later phase skips with the missing module of the
// latest phase. A case that needs the bar and the line controllers skips
// with `controller.line`: phase 7 ports it after `controller.bar`.
//
// The spec forms:
// - `not.toBe(undefined)` is `isNot(same(undefined))`.
// - `chart.scales.y` is `chart.scales['y']!`. `not.toEqual(undefined)` of a
//   scale is `isNotNull`: Dart null stands for JS undefined.
// - A property chain of the spec on an option object is a chain of
//   `jsGet`.
// - `typeof value` is `jsTypeof`. `jasmine.any(Function)` matches a value
//   whose `typeof` is `'function'`.
// - `toBeLessThanOrEqual(x)` is `lessThanOrEqualTo(x)`.
//
// The helper `getLabels(scale)` (scale.linear.tests.js:1-3) comes with the
// bodies of the blocked cases that call it.

void main() {
  group('Linear Scale', () {
    // describe('auto', jasmine.fixture.specs('scale.linear')): a fixture
    // group of phase 7, not a case.

    test('Should register the constructor with the registry', () {
      final constructor = Chart.registry.getScale('linear');
      expect(constructor, isNot(same(undefined)));
      expect(jsTypeof(constructor), 'function');
    });

    test('Should have the correct default config', () {
      final defaultConfig = jsGet(jsGet(Chart.defaults, 'scales'), 'linear');

      final ticks = jsGet(defaultConfig, 'ticks');
      expect(jsTypeof(jsGet(ticks, 'callback')), 'function');
    });

    test(
      'Should correctly determine the max & min data values',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'Should handle when only a min value is provided',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'Should handle when only a max value is provided',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'Should correctly determine the max & min of string data values',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'Should correctly determine the max & min when no values provided and '
      'suggested minimum and maximum are set',
      () {},
      skip: 'blocked: controller.bar',
    );

    testWidgets(
      'Should correctly determine the max & min when no datasets are '
      'associated and suggested minimum and maximum are set',
      (tester) async {
        final chart = acquireChart({
          'type': 'bar',
          'data': <String, Object?>{'datasets': <Object?>[]},
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'linear',
                'suggestedMin': -10,
                'suggestedMax': 0,
              },
            },
          },
        });

        expect(chart.scales['y']!.min, -10);
        expect(chart.scales['y']!.max, 0);
      },
    );

    test(
      'Should correctly determine the max & min data values ignoring hidden '
      'datasets',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'Should correctly determine the max & min data values ignoring data '
      'that is NaN',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'Should correctly determine the max & min data values for small numbers',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'Should correctly determine the max & min for scatter data',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'Should correctly get the label for the given index',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'Should correctly use the locale setting when getting a label',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'Should correctly determine the min and max data values when stacked '
      'mode is turned on',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'Should correctly determine the min and max data values when stacked '
      'mode is turned on and there are hidden datasets',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'Should correctly determine the min and max data values when stacked '
      'mode is turned on there are multiple types of datasets',
      () {},
      skip: 'blocked: controller.line',
    );

    testWidgets(
      'Should ensure that the scale has a max and min that are not equal',
      (tester) async {
        final chart = acquireChart({
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 0);
        expect(chart.scales['y']!.max, 1);
      },
    );

    test(
      'Should ensure that the scale has a max and min that are not equal - '
      'large positive numbers',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'Should ensure that the scale has a max and min that are not equal - '
      'large negative numbers',
      () {},
      skip: 'blocked: controller.line',
    );

    testWidgets(
      'Should ensure that the scale has a max and min that are not equal when '
      'beginAtZero is set',
      (tester) async {
        final chart = acquireChart({
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear', 'beginAtZero': true},
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 0);
        expect(chart.scales['y']!.max, 1);
      },
    );

    test(
      'Should use the suggestedMin and suggestedMax options',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'Should use the min and max options',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'Should use min, max and stepSize to create fixed spaced ticks',
      () {},
      skip: 'blocked: controller.bar',
    );

    testWidgets('Should not generate any ticks > max if max is specified', (
      tester,
    ) async {
      final chart = acquireChart({
        'type': 'line',
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'linear',
              'min': 2.404e-8,
              'max': 2.4143e-8,
              'ticks': <String, Object?>{'includeBounds': false},
            },
          },
        },
      });

      expect(chart.scales['x']!.min, 2.404e-8);
      expect(chart.scales['x']!.max, 2.4143e-8);
      expect(
        chart.scales['x']!.ticks![chart.scales['x']!.ticks!.length - 1].value,
        lessThanOrEqualTo(2.4143e-8),
      );
    });

    testWidgets(
      'Should not generate insane amounts of ticks with small stepSize and '
      'large range',
      (tester) async {
        final chart = acquireChart({
          'type': 'bar',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'linear',
                'min': 1,
                'max': 1E10,
                'ticks': <String, Object?>{'stepSize': 2, 'autoSkip': false},
              },
            },
          },
        });

        expect(chart.scales['y']!.min, 1);
        expect(chart.scales['y']!.max, 1E10);
        expect(chart.scales['y']!.ticks!.length, lessThanOrEqualTo(1000));
      },
    );

    test(
      'Should create decimal steps if stepSize is a decimal number',
      () {},
      skip: 'blocked: controller.bar',
    );

    group('precision', () {
      test(
        'Should create integer steps if precision is 0',
        () {},
        skip: 'blocked: controller.bar',
      );

      test(
        'Should round the step size to the given number of decimal places',
        () {},
        skip: 'blocked: controller.bar',
      );
    });

    test(
      'should forcibly include 0 in the range if the beginAtZero option is '
      'used',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'Should generate tick marks in the correct order in reversed mode',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should use the correct number of decimal places in the default format '
      'function',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'Should correctly limit the maximum number of ticks',
      () {},
      skip: 'blocked: controller.bar',
    );

    test('Should bound to data', () {}, skip: 'blocked: controller.line');

    test(
      'Should build labels using the user supplied callback',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'Should get the correct pixel value for a point',
      () {},
      skip: 'blocked: plugin.legend',
    );

    test('should fit correctly', () {}, skip: 'blocked: plugin.legend');

    test(
      'should fit correctly when display is turned off',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'max and min value should be valid and finite when charts datasets are '
      'hidden',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'max and min value should be valid when min is set and all datasets are '
      'hidden',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'min settings should be used if set to zero',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'max settings should be used if set to zero',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'Should get correct pixel values when horizontal',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'Should get correct pixel values when vertical',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should not throw errors when chart size is negative',
      () {},
      skip: 'blocked: controller.bar',
    );
  });
}
