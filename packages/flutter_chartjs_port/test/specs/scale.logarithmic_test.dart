// Ported from Chart.js v4.6.1 test/specs/scale.logarithmic.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec reads classes and scopes of flutter_chartjs_port, which does not
// export lib/src yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/core/core.ticks.dart' show ticks;
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/scales/scale.logarithmic.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
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
// datasets: the bar or the line controller. The chart cases are
// `testWidgets` cases that call `acquireChart` of
// package:chartjs_test_utils/flutter.dart (Chart.js ADR 0022, section 2).
// The `beforeEach` of the second and the third `when` group, which acquires
// the chart, is a local function that each body calls first
// (`_acquireWhenChart`).
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
JsObjectFace _chartScaleOptions(Chart chart, String id) =>
    jsGet(jsGet(chart.options, 'scales'), id)! as JsObjectFace;

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

/// The two `axes` items of the second and the third `when` group
/// (scale.logarithmic.tests.js:962-973 and :1084-1095).
const List<({String id, String start, String end})> _axes = [
  (id: 'x', start: 'left', end: 'right'), // horizontal scale
  (id: 'y', start: 'bottom', end: 'top'), // vertical scale
];

/// The `beforeEach` of the second and the third `when` group
/// (scale.logarithmic.tests.js:977-1003 and :1099-1125): a line chart with
/// the data of [setup] and two logarithmic scales.
///
/// `setup.data || {datasets: [{data: setup.dataset}]}`: the shared `data` of
/// the item, or a new object with the shared `dataset`. `setup.type` is not
/// read, as upstream.
Chart _acquireWhenChart(Map<String, Object?> setup) {
  final xConfig = <String, Object?>{
    'type': 'logarithmic',
    'position': 'bottom',
  };
  final yConfig = <String, Object?>{'type': 'logarithmic', 'position': 'left'};
  final data =
      (setup['data'] ??
              <String, Object?>{
                'datasets': <Object?>[
                  <String, Object?>{'data': setup['dataset']},
                ],
              })
          as Map<String, Object?>;
  // Object.assign(target, source): an undefined source adds no key.
  if (setup['scale'] case final Map<String, Object?> scale) {
    xConfig.addAll(scale);
    yConfig.addAll(scale);
  }
  if (setup['data'] case final Map<String, Object?> setupData
      when !identical(setupData, data)) {
    data.addAll(setupData);
  }
  return acquireChart(<String, Object?>{
    'type': 'line',
    'data': data,
    'options': <String, Object?>{
      'scales': <String, Object?>{'x': xConfig, 'y': yConfig},
    },
  });
}

void main() {
  group('Logarithmic Scale tests', () {
    group('auto', fixture.specs('scale.logarithmic'));

    test('should register', () {
      final constructor = Chart.registry.getScale('logarithmic');
      expect(constructor, isNot(same(undefined)));
      expect(jsTypeof(constructor), 'function');
    });

    test('should have the correct default config', () {
      final defaultConfig = jsGet(Chart.defaults['scales'], 'logarithmic');
      expect(
        defaultConfig,
        jasmineEquals(<String, Object?>{
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

    testWidgets(
      'should correctly determine the max & min of string data values',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>['42', '1000', '64', '100'],
              },
              <String, Object?>{
                'yAxisID': 'y1',
                'data': <Object?>['10', '5', '5000', '78', '450'],
              },
              <String, Object?>{
                'yAxisID': 'y1',
                'data': <Object?>['150'],
              },
              <String, Object?>{
                'yAxisID': 'y2',
                'data': <Object?>['20', '0', '150', '1800', '3040'],
              },
              <String, Object?>{
                'yAxisID': 'y3',
                'data': <Object?>['67', '0.0004', '0', '820', '0.001'],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'logarithmic'},
              'y1': <String, Object?>{
                'position': 'right',
                'type': 'logarithmic',
              },
              'y2': <String, Object?>{
                'position': 'right',
                'type': 'logarithmic',
              },
              'y3': <String, Object?>{
                'position': 'right',
                'type': 'logarithmic',
              },
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 40);
        expect(chart.scales['y']!.max, 1000);

        expect(chart.scales['y1'], isNotNull); // must construct
        expect(chart.scales['y1']!.min, 5);
        expect(chart.scales['y1']!.max, 5000);

        expect(chart.scales['y2'], isNotNull); // must construct
        expect(chart.scales['y2']!.min, 10);
        expect(chart.scales['y2']!.max, 4000);

        expect(chart.scales['y3'], isNotNull); // must construct
        expect(chart.scales['y3']!.min, _toBeCloseTo(0.0001, 4));
        expect(chart.scales['y3']!.max, 900);
      },
    );

    testWidgets(
      'should correctly determine the max & min data values when there are '
      'hidden datasets',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y1',
                'data': <Object?>[10, 5, 5000, 78, 450],
              },
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[42, 1000, 64, 100],
              },
              <String, Object?>{
                'yAxisID': 'y1',
                'data': <Object?>[50000],
                'hidden': true,
              },
              <String, Object?>{
                'yAxisID': 'y2',
                'data': <Object?>[20, 0, 7400, 14, 291],
              },
              <String, Object?>{
                'yAxisID': 'y2',
                'data': <Object?>[6, 0.0007, 9, 890, 60000],
                'hidden': true,
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'logarithmic'},
              'y1': <String, Object?>{
                'position': 'right',
                'type': 'logarithmic',
              },
              'y2': <String, Object?>{
                'position': 'right',
                'type': 'logarithmic',
              },
            },
          },
        });

        expect(chart.scales['y1'], isNotNull); // must construct
        expect(chart.scales['y1']!.min, 5);
        expect(chart.scales['y1']!.max, 5000);

        expect(chart.scales['y2'], isNotNull); // must construct
        expect(chart.scales['y2']!.min, 10);
        expect(chart.scales['y2']!.max, 8000);
      },
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

    testWidgets(
      'should correctly determine the max & min for scatter data',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 10, 'y': 100},
                  <String, Object?>{'x': 2, 'y': 6},
                  <String, Object?>{'x': 65, 'y': 121},
                  <String, Object?>{'x': 99, 'y': 7},
                ],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'logarithmic',
                'position': 'bottom',
              },
              'y': <String, Object?>{'type': 'logarithmic'},
            },
          },
        });

        expect(chart.scales['x']!.min, 2);
        expect(chart.scales['x']!.max, 100);

        expect(chart.scales['y']!.min, 6);
        expect(chart.scales['y']!.max, 150);
      },
    );

    testWidgets(
      'should correctly determine the max & min for scatter data when 0 '
      'values are present',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 7, 'y': 950},
                  <String, Object?>{'x': 289, 'y': 0},
                  <String, Object?>{'x': 0, 'y': 8},
                  <String, Object?>{'x': 23, 'y': 0.04},
                ],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'logarithmic',
                'position': 'bottom',
              },
              'y': <String, Object?>{'type': 'logarithmic'},
            },
          },
        });

        expect(chart.scales['x']!.min, 1);
        expect(chart.scales['x']!.max, 30);

        expect(chart.scales['y']!.min, 0.01);
        expect(chart.scales['y']!.max, 1000);
      },
    );

    testWidgets(
      'should correctly determine the min and max data values when stacked '
      'mode is turned on',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'type': 'bar',
                'yAxisID': 'y',
                'data': <Object?>[10, 5, 1, 5, 78, 100],
              },
              <String, Object?>{
                'yAxisID': 'y1',
                'data': <Object?>[0, 1000],
              },
              <String, Object?>{
                'type': 'bar',
                'yAxisID': 'y',
                'data': <Object?>[150, 10, 10, 100, 10, 9],
              },
              <String, Object?>{
                'type': 'line',
                'yAxisID': 'y',
                'data': <Object?>[100, 100, 100, 100, 100, 100],
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

    testWidgets(
      'should generate tick marks in the correct order in reversed mode',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 1, 25, 78],
              },
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'logarithmic',
                'reverse': true,
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
            80, 70, 60, 50, 40, 30, 20, 15, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, //
          ]),
        );
        expect(scale.start, jasmineEquals(80));
        expect(scale.end, jasmineEquals(1));
      },
    );

    testWidgets(
      'should generate tick marks in the correct order in reversed mode when '
      '0 values are present',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[21, 9, 0, 10, 25],
              },
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'logarithmic',
                'reverse': true,
                'ticks': <String, Object?>{
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
            30, 20, 15, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, //
          ]),
        );
        expect(scale.start, jasmineEquals(30));
        expect(scale.end, jasmineEquals(1));
      },
    );

    testWidgets('should build labels using the default template', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 5, 1.1, 25, 0, 78],
            },
          ],
          'labels': <Object?>[],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{
              'type': 'logarithmic',
              'ticks': <String, Object?>{'autoSkip': false},
            },
          },
        },
      });

      expect(
        _getLabels(chart.scales['y']!),
        jasmineEquals(<Object?>[
          '1', '2', '3', '', '5', '', '', '', '', '10', '15', '20', '30', //
          '', '50', '60', '70', '80',
        ]),
      );
    });

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
      final config = <Map<String, Object?>>[
        <String, Object?>{
          'dataset': <Object?>[],
          'firstTick': 1, // value of the first tick
          'lastTick': 10, // value of the last tick
          'describe': 'empty dataset, without min/max',
        },
        <String, Object?>{
          'dataset': <Object?>[],
          'scale': <String, Object?>{'stacked': true},
          'firstTick': 1,
          'lastTick': 10,
          'describe': 'empty dataset, without min/max, with stacked: true',
        },
        <String, Object?>{
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'stack': 'stack'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack'},
            ],
          },
          'type': 'bar',
          'firstTick': 1,
          'lastTick': 10,
          'describe': 'empty dataset with stack option, without min/max',
        },
        <String, Object?>{
          'dataset': <Object?>[],
          'scale': <String, Object?>{'min': 1},
          'firstTick': 1,
          'lastTick': 10,
          'describe': 'empty dataset, min: 1, without max',
        },
        <String, Object?>{
          'dataset': <Object?>[],
          'scale': <String, Object?>{'max': 80},
          'firstTick': 1,
          'lastTick': 80,
          'describe': 'empty dataset, max: 80, without min',
        },
        <String, Object?>{
          'dataset': <Object?>[],
          'scale': <String, Object?>{'max': 0.8},
          'firstTick': 0.01,
          'lastTick': 0.8,
          'describe': 'empty dataset, max: 0.8, without min',
        },
        <String, Object?>{
          'dataset': <Object?>[
            <String, Object?>{'x': 10, 'y': 10},
            <String, Object?>{'x': 5, 'y': 5},
            <String, Object?>{'x': 1, 'y': 1},
            <String, Object?>{'x': 25, 'y': 25},
            <String, Object?>{'x': 78, 'y': 78},
          ],
          'firstTick': 1,
          'lastTick': 80,
          'describe': 'dataset min point {x: 1, y: 1}, max point {x:78, y:78}',
        },
      ];
      for (final setup in config) {
        for (final axis in _axes) {
          final expectation =
              'min = ${jsToString(setup['firstTick'])}, '
              'max = ${jsToString(setup['lastTick'])}';
          group(
            '${setup['describe']} and axis is "${axis.id}"; expect: '
            '$expectation;',
            () {
              late Chart chart;

              // The beforeEach acquires a chart: a local function that the
              // case calls first.
              void beforeEach() {
                chart = _acquireWhenChart(setup);
              }

              testWidgets('should get the correct pixel value for a point', (
                tester,
              ) async {
                beforeEach();
                final axisID = axis.id;
                final scale = chart.scales[axisID]!;
                final firstTick = setup['firstTick']! as num;
                final lastTick = setup['lastTick']! as num;
                var start = _side(chart.chartArea!, axis.start);
                var end = _side(chart.chartArea!, axis.end);

                expect(
                  scale.getPixelForValue(firstTick),
                  toBeCloseToPixel(start),
                );
                expect(scale.getPixelForValue(lastTick), toBeCloseToPixel(end));
                expect(
                  scale.getPixelForValue(0),
                  toBeCloseToPixel(start),
                ); // 0 is invalid, put it at the start.

                expect(
                  scale.getValueForPixel(start),
                  _toBeCloseTo(firstTick, 4),
                );
                expect(scale.getValueForPixel(end), _toBeCloseTo(lastTick, 4));

                chart.scales[axisID]!.options['reverse'] = true; // Reverse mode
                chart.update();

                // chartArea might have been resized in update
                start = _side(chart.chartArea!, axis.end);
                end = _side(chart.chartArea!, axis.start);

                expect(
                  scale.getPixelForValue(firstTick),
                  toBeCloseToPixel(start),
                );
                expect(scale.getPixelForValue(lastTick), toBeCloseToPixel(end));

                expect(
                  scale.getValueForPixel(start),
                  _toBeCloseTo(firstTick, 4),
                );
                expect(scale.getValueForPixel(end), _toBeCloseTo(lastTick, 4));
              });
            },
          );
        }
      }
    });

    group('when', () {
      final config = <Map<String, Object?>>[
        <String, Object?>{
          'dataset': <Object?>[],
          'scale': <String, Object?>{'min': 0},
          'lastTick': 10, // value of the last tick
          'describe': 'empty dataset, min: 0, without max',
        },
        <String, Object?>{
          'dataset': <Object?>[],
          'scale': <String, Object?>{'min': 0, 'max': 80},
          'lastTick': 80,
          'describe': 'empty dataset, min: 0, max: 80',
        },
        <String, Object?>{
          'dataset': <Object?>[],
          'scale': <String, Object?>{'min': 0, 'max': 0.8},
          'lastTick': 0.8,
          'describe': 'empty dataset, min: 0, max: 0.8',
        },
        <String, Object?>{
          'dataset': <Object?>[
            <String, Object?>{'x': 0, 'y': 0},
            <String, Object?>{'x': 10, 'y': 10},
            <String, Object?>{'x': 1.2, 'y': 1.2},
            <String, Object?>{'x': 25, 'y': 25},
            <String, Object?>{'x': 78, 'y': 78},
          ],
          'lastTick': 80,
          'describe': 'dataset min point {x: 0, y: 0}, max point {x:78, y:78}',
        },
        <String, Object?>{
          'dataset': <Object?>[
            <String, Object?>{'x': 0, 'y': 0},
            <String, Object?>{'x': 10, 'y': 10},
            <String, Object?>{'x': 6.3, 'y': 6.3},
            <String, Object?>{'x': 25, 'y': 25},
            <String, Object?>{'x': 78, 'y': 78},
          ],
          'lastTick': 80,
          'describe': 'dataset min point {x: 0, y: 0}, max point {x:78, y:78}',
        },
        <String, Object?>{
          'dataset': <Object?>[
            <String, Object?>{'x': 10, 'y': 10},
            <String, Object?>{'x': 1.2, 'y': 1.2},
            <String, Object?>{'x': 25, 'y': 25},
            <String, Object?>{'x': 78, 'y': 78},
          ],
          'scale': <String, Object?>{'min': 0},
          'lastTick': 80,
          'describe':
              'dataset min point {x: 1.2, y: 1.2}, max point {x:78, y:78}, '
              'min: 0',
        },
        <String, Object?>{
          'dataset': <Object?>[
            <String, Object?>{'x': 10, 'y': 10},
            <String, Object?>{'x': 6.3, 'y': 6.3},
            <String, Object?>{'x': 25, 'y': 25},
            <String, Object?>{'x': 78, 'y': 78},
          ],
          'scale': <String, Object?>{'min': 0},
          'lastTick': 80,
          'describe':
              'dataset min point {x: 6.3, y: 6.3}, max point {x:78, y:78}, '
              'min: 0',
        },
      ];
      // Two items have the same `describe`. Thus the cases of the second
      // item get ` #2` (porting-flow.md section 1, step 5).
      final describes = <String>{};
      for (final setup in config) {
        for (final axis in _axes) {
          final expectation = 'min = 0, max = ${jsToString(setup['lastTick'])}';
          final describe =
              '${setup['describe']} and axis is "${axis.id}"; expect: '
              '$expectation;';
          const name = 'should get the correct pixel value for a point';
          final isRepeat = !describes.add(describe);
          group(describe, () {
            late Chart chart;

            // The beforeEach acquires a chart: a local function that the
            // case calls first.
            void beforeEach() {
              chart = _acquireWhenChart(setup);
            }

            testWidgets(isRepeat ? '$name #2' : name, (tester) async {
              beforeEach();
              final axisID = axis.id;
              final scale = chart.scales[axisID]!;
              final lastTick = setup['lastTick']! as num;
              var start = _side(chart.chartArea!, axis.start);
              var end = _side(chart.chartArea!, axis.end);

              expect(scale.getPixelForValue(0), toBeCloseToPixel(start));
              expect(scale.getPixelForValue(lastTick), toBeCloseToPixel(end));

              expect(
                scale.getValueForPixel(start),
                _toBeCloseTo(scale.min, 4),
              );
              expect(scale.getValueForPixel(end), _toBeCloseTo(lastTick, 4));

              chart.scales[axisID]!.options['reverse'] = true; // Reverse mode
              chart.update();

              // chartArea might have been resized in update
              start = _side(chart.chartArea!, axis.end);
              end = _side(chart.chartArea!, axis.start);

              expect(scale.getPixelForValue(0), toBeCloseToPixel(start));
              expect(scale.getPixelForValue(lastTick), toBeCloseToPixel(end));

              expect(
                scale.getValueForPixel(start),
                _toBeCloseTo(scale.min, 4),
              );
              expect(scale.getValueForPixel(end), _toBeCloseTo(lastTick, 4));
            });
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

    testWidgets('Should bound to data', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1.1, 99],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{'type': 'logarithmic', 'bounds': 'data'},
          },
        },
      });

      expect(chart.scales['y']!.min, jasmineEquals(1.1));
      expect(chart.scales['y']!.max, jasmineEquals(99));
    });
  });
}
