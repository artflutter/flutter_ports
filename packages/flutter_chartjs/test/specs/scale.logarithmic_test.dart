// Ported from Chart.js v4.5.1+7169e651 test/specs/scale.logarithmic.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

// The spec reads classes and scopes of flutter_chartjs, which does not
// export lib/src yet.
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.ticks.dart' show ticks;
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_test/flutter_test.dart';

// The spec reads `Chart.registry`, `Chart.defaults` and `Chart.Ticks`.
// `Chart.registry` and `Chart.defaults` are static fields of `Chart`.
// `Chart.Ticks` is `ticks` of core.ticks.dart (src/index.umd.ts:43).
// test/flutter_test_config.dart registers the built-in components before
// `main()` (`harness-register-builtins`). Thus the registry has the class
// value `LogarithmicScale.jsClass`, and the defaults have the scope
// `scales.logarithmic`. The file runs on the VM, because
// core.controller.dart reaches the platform layer.
//
// `typeof x` is `jsTypeof(x)`. The default tick callback is the JsFunction
// `ticks.formatters.logarithmic`, not a Dart Function. Thus
// `jasmine.any(Function)` is `jsIsFunction`, as in core.ticks_test.dart.
//
// Each chart case has a dataset, also the cases with an empty dataset. Thus
// each chart case needs the controller of phase 7 for its chart type or its
// datasets, and skips with the name of that controller. A case that needs
// two controllers names the controller that phase 7 ports last: phase 7
// ports bar first (porting-flow.md section 5). The bodies of phase 7 are
// `testWidgets` cases that call `acquireChart` of
// package:chartjs_test_utils/flutter.dart (Chart.js ADR 0022, section 2).
// The `beforeEach` of the second and the third `when` group, which acquires
// the chart, is a local function that each body calls first. The helper
// `getLabels(scale)` (scale.logarithmic.tests.js:1-3) comes with the bodies
// of the cases that read the labels.

/// The `axis` and `describe` of the eight `config` items of the first
/// `when` group (scale.logarithmic.tests.js:774-839).
const List<({String axis, String describe})> _stackSetups = [
  (axis: 'y', describe: 'all stacks are defined'),
  (axis: 'y', describe: 'not all stacks are defined'),
  (axis: 'y', describe: 'all stacks are defined and min: 0'),
  // The upstream text has no "all" here.
  (axis: 'y', describe: 'not stacks are defined and min: 0'),
  (axis: 'x', describe: 'all stacks are defined'),
  (axis: 'x', describe: 'not all stacks are defined'),
  (axis: 'x', describe: 'all stacks are defined and min: 0'),
  (axis: 'x', describe: 'not all stacks are defined and min: 0'),
];

/// The `describe` and the text of `firstTick` and `lastTick` of the seven
/// `config` items of the second `when` group
/// (scale.logarithmic.tests.js:907-960). The texts are the JS number to
/// string conversions of the upstream values.
const List<({String describe, String firstTick, String lastTick})>
_pixelSetups = [
  (describe: 'empty dataset, without min/max', firstTick: '1', lastTick: '10'),
  (
    describe: 'empty dataset, without min/max, with stacked: true',
    firstTick: '1',
    lastTick: '10',
  ),
  (
    describe: 'empty dataset with stack option, without min/max',
    firstTick: '1',
    lastTick: '10',
  ),
  (
    describe: 'empty dataset, min: 1, without max',
    firstTick: '1',
    lastTick: '10',
  ),
  (
    describe: 'empty dataset, max: 80, without min',
    firstTick: '1',
    lastTick: '80',
  ),
  (
    describe: 'empty dataset, max: 0.8, without min',
    firstTick: '0.01',
    lastTick: '0.8',
  ),
  (
    describe: 'dataset min point {x: 1, y: 1}, max point {x:78, y:78}',
    firstTick: '1',
    lastTick: '80',
  ),
];

/// The `describe` and the text of `lastTick` of the seven `config` items of
/// the third `when` group (scale.logarithmic.tests.js:1041-1082). The fourth
/// and the fifth item have the same `describe`.
const List<({String describe, String lastTick})> _zeroMinSetups = [
  (describe: 'empty dataset, min: 0, without max', lastTick: '10'),
  (describe: 'empty dataset, min: 0, max: 80', lastTick: '80'),
  (describe: 'empty dataset, min: 0, max: 0.8', lastTick: '0.8'),
  (
    describe: 'dataset min point {x: 0, y: 0}, max point {x:78, y:78}',
    lastTick: '80',
  ),
  (
    describe: 'dataset min point {x: 0, y: 0}, max point {x:78, y:78}',
    lastTick: '80',
  ),
  (
    describe:
        'dataset min point {x: 1.2, y: 1.2}, max point {x:78, y:78}, min: 0',
    lastTick: '80',
  ),
  (
    describe:
        'dataset min point {x: 6.3, y: 6.3}, max point {x:78, y:78}, min: 0',
    lastTick: '80',
  ),
];

/// The `id` of the two `axes` items of the second and the third `when`
/// group (scale.logarithmic.tests.js:962-973 and :1084-1095).
const List<String> _axisIds = ['x', 'y'];

void main() {
  group('Logarithmic Scale tests', () {
    // describe('auto', jasmine.fixture.specs('scale.logarithmic')): a
    // fixture group of phase 7, not a case.

    test('should register', () {
      final constructor = Chart.registry.getScale('logarithmic');
      expect(constructor, isNot(same(undefined)));
      expect(jsTypeof(constructor), 'function');
    });

    test('should have the correct default config', () {
      final defaultConfig = jsGet(Chart.defaults['scales'], 'logarithmic');
      expect(
        defaultConfig,
        equals(<String, Object?>{
          'ticks': <String, Object?>{
            'callback': jsGet(ticks['formatters'], 'logarithmic'),
            'major': <String, Object?>{'enabled': true},
          },
        }),
      );

      // Is this actually a function
      expect(
        jsIsFunction(jsGet(jsGet(defaultConfig, 'ticks'), 'callback')),
        isTrue,
      );
    });

    test(
      'should correctly determine the max & min data values',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should correctly determine the max & min of string data values',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should correctly determine the max & min data values when there are '
      'hidden datasets',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should correctly determine the max & min data values when there is '
      'NaN data',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should correctly determine the max & min for scatter data',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should correctly determine the max & min for scatter data when 0 '
      'values are present',
      () {},
      skip: 'blocked: controller.line',
    );

    // The chart type is bar, with bar and line datasets.
    test(
      'should correctly determine the min and max data values when stacked '
      'mode is turned on',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should correctly determine the min and max data values when stacked '
      'mode is turned on ignoring hidden datasets',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should ensure that the scale has a max and min that are not equal',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should use the min and max options',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should ignore negative min and max options',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should ignore invalid min and max options',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should generate tick marks',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should generate tick marks when 0 values are present',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should generate tick marks in the correct order in reversed mode',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should generate tick marks in the correct order in reversed mode when '
      '0 values are present',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should build labels using the default template',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should build labels using the user supplied callback',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should correctly get the correct label for a data item',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should correctly use the locale when generating the label',
      () {},
      skip: 'blocked: controller.bar',
    );

    group('when', () {
      for (final setup in _stackSetups) {
        group(
          'dataset has stack option and ${setup.describe} and axis is '
          '"${setup.axis}";',
          () {
            test(
              'should define the correct axis limits',
              () {},
              skip: 'blocked: controller.bar',
            );
          },
        );
      }
    });

    group('when', () {
      for (final setup in _pixelSetups) {
        for (final axisId in _axisIds) {
          final expectation =
              'min = ${setup.firstTick}, max = ${setup.lastTick}';
          group(
            '${setup.describe} and axis is "$axisId"; expect: $expectation;',
            () {
              test(
                'should get the correct pixel value for a point',
                () {},
                skip: 'blocked: controller.line',
              );
            },
          );
        }
      }
    });

    group('when', () {
      // Two items have the same `describe`. Thus the cases of the second
      // item get ` #2` (porting-flow.md section 1, step 5).
      final describes = <String>{};
      for (final setup in _zeroMinSetups) {
        for (final axisId in _axisIds) {
          final expectation = 'min = 0, max = ${setup.lastTick}';
          final describe =
              '${setup.describe} and axis is "$axisId"; expect: '
              '$expectation;';
          const name = 'should get the correct pixel value for a point';
          final isRepeat = !describes.add(describe);
          group(describe, () {
            test(
              isRepeat ? '$name #2' : name,
              () {},
              skip: 'blocked: controller.line',
            );
          });
        }
      }
    });

    test(
      'Should correctly determine the max & min when no values provided and '
      'suggested minimum and maximum are set',
      () {},
      skip: 'blocked: controller.bar',
    );

    test('Should bound to data', () {}, skip: 'blocked: controller.line');
  });
}
