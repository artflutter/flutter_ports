// Ported from Chart.js v4.5.1+7169e651 test/specs/scale.logarithmic.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec reads classes and scopes of flutter_chartjs, which does not
// export lib/src yet.
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/core/core.ticks.dart' show ticks;
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/scales/scale.logarithmic.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

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
// datasets. A case whose controller is not ported yet skips with the name
// of that controller. A case that needs two controllers names the
// controller that phase 7 ports last: phase 7 ports bar first
// (porting-flow.md section 5). The chart cases are `testWidgets` cases that
// call `acquireChart` of package:chartjs_test_utils/flutter.dart (Chart.js
// ADR 0022, section 2). The `beforeEach` of the second and the third `when`
// group, which acquires the chart, is a local function that each body calls
// first.
//
// The spec forms:
// - `chart.scales.y` is `chart.scales['y']!`. `not.toEqual(undefined)` of a
//   scale is `isNotNull`.
// - `toBeCloseTo` is `_toBeCloseTo`. `toEqual` is `jasmineEquals`.
// - `chart.options.scales.y.stacked = true` writes into the resolver of the
//   last read of the chain (`_chartScaleOptions`).
// - `chart.scales[axisID].options.reverse = true` writes through the
//   resolver of the scale options.
// - `chart.chartArea[side]` is `_side(chart.chartArea!, side)`.
// - `scale.start` and `scale.end` are fields of `LogarithmicScale`.
// - A tick callback `function(value) { return value; }` is a Dart function
//   that returns its argument. `index.toString()` is `jsToString(index)`.
// - The first `when` group keeps the shared `data`, `dataWithEmptyStacks`
//   and `config` of :756-839 in the group closure, as upstream.

/// scale.logarithmic.tests.js:1-3 `getLabels(scale)`.
List<Object?> _getLabels(Scale scale) => [
  for (final t in scale.ticks!) t.label,
];

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as AnyObject;

/// `chart.options.scales[id]`: a resolver of the chart options.
AnyObject _chartScaleOptions(Chart chart, String id) =>
    jsGet(jsGet(chart.options, 'scales'), id)! as AnyObject;

/// `chartArea[side]` for the four sides of a chart area.
double _side(ChartArea area, String side) => switch (side) {
  'left' => area.left,
  'right' => area.right,
  'top' => area.top,
  'bottom' => area.bottom,
  _ => throw ArgumentError.value(side, 'side'),
};

/// Jasmine `toBeCloseTo(expected, precision)` of jasmine-core 3.99.1:
/// `Math.round(delta * 10^(precision + 1)) <= 10^-precision / 2 *
/// 10^(precision + 1)`, with `delta = |expected - actual|`.
Matcher _toBeCloseTo(num expected, [int precision = 2]) {
  // js-ok: the exponents are ints, as in Jasmine's Math.pow.
  final pow = math.pow(10.0, precision + 1);
  // js-ok: the exponent is an int, as in Jasmine's Math.pow.
  final maxDelta = math.pow(10.0, -precision) / 2;
  return predicate<Object?>(
    (actual) =>
        actual is num &&
        jsRound(((expected - actual).abs() * pow).toDouble()) <= maxDelta * pow,
    'a number close to ${jsToString(expected)} (Jasmine toBeCloseTo, '
    'precision ${jsToString(precision)})',
  );
}

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

    testWidgets(
      'should correctly determine the max & min data values',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[42, 1000, 64, 100],
              },
              <String, Object?>{
                'yAxisID': 'y1',
                'data': <Object?>[10, 5, 5000, 78, 450],
              },
              <String, Object?>{
                'yAxisID': 'y1',
                'data': <Object?>[150],
              },
              <String, Object?>{
                'yAxisID': 'y2',
                'data': <Object?>[20, 0, 150, 1800, 3040],
              },
              <String, Object?>{
                'yAxisID': 'y3',
                'data': <Object?>[67, 0.0004, 0, 820, 0.001],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'id': 'y', 'type': 'logarithmic'},
              'y1': <String, Object?>{
                'type': 'logarithmic',
                'position': 'right',
              },
              'y2': <String, Object?>{
                'type': 'logarithmic',
                'position': 'right',
              },
              'y3': <String, Object?>{
                'position': 'right',
                'type': 'logarithmic',
              },
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 10);
        expect(chart.scales['y']!.max, 1000);

        expect(chart.scales['y1'], isNotNull); // must construct
        expect(chart.scales['y1']!.min, 1);
        expect(chart.scales['y1']!.max, 5000);

        expect(chart.scales['y2'], isNotNull); // must construct
        expect(chart.scales['y2']!.min, 10);
        expect(chart.scales['y2']!.max, 4000);

        expect(chart.scales['y3'], isNotNull); // must construct
        expect(chart.scales['y3']!.min, _toBeCloseTo(0.0001, 4));
        expect(chart.scales['y3']!.max, 900);
      },
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

    testWidgets(
      'should correctly determine the max & min data values when there is '
      'NaN data',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[
                  undefined,
                  10,
                  null,
                  5,
                  5000,
                  double.nan,
                  78,
                  450,
                ],
              },
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[
                  undefined,
                  28,
                  null,
                  1000,
                  500,
                  double.nan,
                  50,
                  42,
                  double.infinity,
                  double.negativeInfinity,
                ],
              },
              <String, Object?>{
                'yAxisID': 'y1',
                'data': <Object?>[
                  undefined,
                  30,
                  null,
                  9400,
                  0,
                  double.nan,
                  54,
                  836,
                ],
              },
              <String, Object?>{
                'yAxisID': 'y1',
                'data': <Object?>[
                  undefined,
                  0,
                  null,
                  800,
                  9,
                  double.nan,
                  894,
                  21,
                ],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'logarithmic'},
              'y1': <String, Object?>{
                'position': 'right',
                'type': 'logarithmic',
              },
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 1);
        expect(chart.scales['y']!.max, 5000);

        // Turn on stacked mode since it uses it's own
        _chartScaleOptions(chart, 'y')['stacked'] = true;
        chart.update();

        expect(chart.scales['y']!.min, 1);
        expect(chart.scales['y']!.max, 6000);

        expect(chart.scales['y1'], isNotNull); // must construct
        expect(chart.scales['y1']!.min, 1);
        expect(chart.scales['y1']!.max, 10000);
      },
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

    testWidgets(
      'should correctly determine the min and max data values when stacked '
      'mode is turned on ignoring hidden datasets',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10, 5, 1, 5, 78, 100],
                'type': 'bar',
              },
              <String, Object?>{
                'yAxisID': 'y1',
                'data': <Object?>[0, 1000],
                'type': 'bar',
              },
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[150, 10, 10, 100, 10, 9],
                'type': 'bar',
              },
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10000, 10000, 10000, 10000, 10000, 10000],
                'hidden': true,
                'type': 'bar',
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'logarithmic', 'stacked': true},
              'y1': <String, Object?>{
                'position': 'right',
                'type': 'logarithmic',
              },
            },
          },
        });

        expect(chart.scales['y']!.min, 0.1);
        expect(chart.scales['y']!.max, 200);
      },
    );

    testWidgets(
      'should ensure that the scale has a max and min that are not equal',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'logarithmic'},
            },
          },
        });

        expect(chart.scales['y']!.min, 1);
        expect(chart.scales['y']!.max, 10);

        _dataset(chart, 0)['data'] = <Object?>[0.15, 0.15];
        chart.update();

        expect(chart.scales['y']!.min, 0.1);
        expect(chart.scales['y']!.max, 0.15);
      },
    );

    testWidgets(
      'should use the min and max options',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 1, 1, 2, 1, 0],
              },
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'logarithmic',
                'min': 10,
                'max': 1010,
                'ticks': <String, Object?>{
                  'callback': (Object? value) => value,
                },
              },
            },
          },
        });

        final yScale = chart.scales['y']!;
        final tickCount = yScale.ticks!.length;
        expect(yScale.min, 10);
        expect(yScale.max, 1010);
        expect(yScale.ticks![0].value, 10);
        expect(yScale.ticks![tickCount - 1].value, 1010);
      },
    );

    testWidgets(
      'should ignore negative min and max options',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 1, 1, 2, 1, 0],
              },
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'logarithmic',
                'min': -10,
                'max': -1010,
                'ticks': <String, Object?>{
                  'callback': (Object? value) => value,
                },
              },
            },
          },
        });

        final y = chart.scales['y']!;
        expect(y.min, 0.1);
        expect(y.max, 2);
      },
    );

    testWidgets(
      'should ignore invalid min and max options',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 1, 1, 2, 1, 0],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'logarithmic',
                'min': 'zero',
                'max': null,
                'ticks': <String, Object?>{
                  'callback': (Object? value) => value,
                },
              },
            },
          },
        });

        final y = chart.scales['y']!;
        expect(y.min, 0.1);
        expect(y.max, 2);
      },
    );

    testWidgets(
      'should generate tick marks',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 2, 25, 78],
              },
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'logarithmic',
                'ticks': <String, Object?>{
                  'autoSkip': false,
                  'callback': (Object? value) => value,
                },
              },
            },
          },
        });

        final scale = chart.scales['y']! as LogarithmicScale;
        expect(
          _getLabels(scale),
          jasmineEquals(<Object?>[
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            15,
            20,
            30,
            40,
            50,
            60,
            70,
            80,
          ]),
        );
        expect(scale.start, jasmineEquals(1));
        expect(scale.end, jasmineEquals(80));
      },
    );

    testWidgets(
      'should generate tick marks when 0 values are present',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[11, 0.8, 0, 28, 7],
              },
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'logarithmic',
                'ticks': <String, Object?>{
                  'callback': (Object? value) => value,
                },
              },
            },
          },
        });

        final scale = chart.scales['y']! as LogarithmicScale;
        // Counts down because the lines are drawn top to bottom
        expect(
          _getLabels(scale),
          jasmineEquals(<Object?>[
            0.1,
            0.2,
            0.3,
            0.4,
            0.5,
            0.6,
            0.7,
            0.8,
            0.9,
            1,
            1.5,
            2,
            3,
            4,
            5,
            6,
            7, //
            8, 9, 10, 15, 20, 30,
          ]),
        );
        expect(scale.start, jasmineEquals(0.1));
        expect(scale.end, jasmineEquals(30));
      },
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

    testWidgets(
      'should build labels using the user supplied callback',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 2, 25, 78],
              },
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'logarithmic',
                'ticks': <String, Object?>{
                  'callback': (Object? value, Object? index) =>
                      jsToString(index),
                },
              },
            },
          },
        });

        // Just the index
        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>[
            '0',
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '10',
            '11',
            '12', //
            '13', '14', '15', '16', '17',
          ]),
        );
      },
    );

    testWidgets(
      'should correctly get the correct label for a data item',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10, 5, 5000, 78, 450],
              },
              <String, Object?>{
                'yAxisID': 'y1',
                'data': <Object?>[1, 1000, 10, 100],
              },
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[150],
              },
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'logarithmic'},
              'y1': <String, Object?>{
                'position': 'right',
                'type': 'logarithmic',
              },
            },
          },
        });

        expect(chart.scales['y']!.getLabelForValue(150), '150');
      },
    );

    testWidgets(
      'should correctly use the locale when generating the label',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10, 5, 5000, 78, 450],
              },
              <String, Object?>{
                'yAxisID': 'y1',
                'data': <Object?>[1, 1000, 10, 100],
              },
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[150],
              },
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'locale': 'de-DE',
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'logarithmic'},
              'y1': <String, Object?>{
                'position': 'right',
                'type': 'logarithmic',
              },
            },
          },
        });

        expect(chart.scales['y']!.getLabelForValue(10.25), '10,25');
      },
    );

    group('when', () {
      final data = <Object?>[
        <String, Object?>{
          'data': <Object?>[1, 39],
          'stack': 'stack',
        },
        <String, Object?>{
          'data': <Object?>[1, 39],
          'stack': 'stack',
        },
      ];
      final dataWithEmptyStacks = <Object?>[
        <String, Object?>{'data': <Object?>[]},
        <String, Object?>{'data': <Object?>[]},
        ...data,
      ];
      final config = <Map<String, Object?>>[
        <String, Object?>{
          'axis': 'y',
          'firstTick': 1, // start of the axis (minimum)
          'describe': 'all stacks are defined',
        },
        <String, Object?>{
          'axis': 'y',
          'data': dataWithEmptyStacks,
          'firstTick': 1,
          'describe': 'not all stacks are defined',
        },
        <String, Object?>{
          'axis': 'y',
          'scale': <String, Object?>{
            'y': <String, Object?>{'min': 0},
          },
          'firstTick': 0.1,
          'describe': 'all stacks are defined and min: 0',
        },
        <String, Object?>{
          'axis': 'y',
          'data': dataWithEmptyStacks,
          'scale': <String, Object?>{
            'y': <String, Object?>{'min': 0},
          },
          'firstTick': 0.1,
          'describe': 'not stacks are defined and min: 0',
        },
        <String, Object?>{
          'axis': 'x',
          'firstTick': 1,
          'describe': 'all stacks are defined',
        },
        <String, Object?>{
          'axis': 'x',
          'data': dataWithEmptyStacks,
          'firstTick': 1,
          'describe': 'not all stacks are defined',
        },
        <String, Object?>{
          'axis': 'x',
          'scale': <String, Object?>{
            'x': <String, Object?>{'min': 0},
          },
          'firstTick': 0.1,
          'describe': 'all stacks are defined and min: 0',
        },
        <String, Object?>{
          'axis': 'x',
          'data': dataWithEmptyStacks,
          'scale': <String, Object?>{
            'x': <String, Object?>{'min': 0},
          },
          'firstTick': 0.1,
          'describe': 'not all stacks are defined and min: 0',
        },
      ];
      for (final setup in config) {
        final scaleConfig = <String, Object?>{};
        final String indexAxis;
        final String chartStart;
        final String chartEnd;
        final axis = setup['axis']! as String;

        if (axis == 'x') {
          indexAxis = 'y';
          chartStart = 'left';
          chartEnd = 'right';
        } else {
          indexAxis = 'x';
          chartStart = 'bottom';
          chartEnd = 'top';
        }
        scaleConfig[axis] = <String, Object?>{
          'type': 'logarithmic',
          'beginAtZero': false,
        };
        // Object.assign(scaleConfig, setup.scale): an undefined source adds
        // no key.
        if (setup['scale'] case final Map<String, Object?> scale) {
          scaleConfig.addAll(scale);
        }
        (scaleConfig[axis]! as Map<String, Object?>)['type'] = 'logarithmic';

        final description =
            'dataset has stack option and ${setup['describe']}'
            ' and axis is "$axis";';
        group(description, () {
          testWidgets('should define the correct axis limits', (
            tester,
          ) async {
            final chart = acquireChart(<String, Object?>{
              'type': 'bar',
              'data': <String, Object?>{
                'labels': <Object?>['category 1', 'category 2'],
                'datasets': setup['data'] ?? data,
              },
              'options': <String, Object?>{
                'indexAxis': indexAxis,
                'scales': scaleConfig,
              },
            });

            final axisID = axis;
            final scale = chart.scales[axisID]!;
            final firstTick = setup['firstTick']! as num;
            // last tick (should be first available tick after: 2 * 39)
            const lastTick = 80;
            var start = _side(chart.chartArea!, chartStart);
            var end = _side(chart.chartArea!, chartEnd);

            expect(scale.getPixelForValue(firstTick), toBeCloseToPixel(start));
            expect(scale.getPixelForValue(lastTick), toBeCloseToPixel(end));

            expect(scale.getValueForPixel(start), _toBeCloseTo(firstTick, 4));
            expect(scale.getValueForPixel(end), _toBeCloseTo(lastTick, 4));

            chart.scales[axisID]!.options['reverse'] = true; // Reverse mode
            chart.update();

            // chartArea might have been resized in update
            start = _side(chart.chartArea!, chartEnd);
            end = _side(chart.chartArea!, chartStart);

            expect(scale.getPixelForValue(firstTick), toBeCloseToPixel(start));
            expect(scale.getPixelForValue(lastTick), toBeCloseToPixel(end));

            expect(scale.getValueForPixel(start), _toBeCloseTo(firstTick, 4));
            expect(scale.getValueForPixel(end), _toBeCloseTo(lastTick, 4));
          });
        });
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

    testWidgets(
      'Should correctly determine the max & min when no values provided and '
      'suggested minimum and maximum are set',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'yAxisID': 'y', 'data': <Object?>[]},
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'logarithmic',
                'suggestedMin': 10,
                'suggestedMax': 100,
              },
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 10);
        expect(chart.scales['y']!.max, 100);
      },
    );

    test('Should bound to data', () {}, skip: 'blocked: controller.line');
  });
}
