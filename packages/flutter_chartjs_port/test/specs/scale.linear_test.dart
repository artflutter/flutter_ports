// Ported from Chart.js v4.6.1 test/specs/scale.linear.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/scales/scale.linearbase.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// The spec reads Chart.registry and Chart.defaults: the static fields
// `Chart.registry` and `Chart.defaults` of core.controller.dart.
// flutter_test_config.dart registers the built-in components before main().
// Thus the linear scale is in the registry, and its defaults are in
// `Chart.defaults.scales.linear`.
//
// The chart cases call `acquireChart`. Thus they are `testWidgets` cases,
// and the file runs on the VM (Chart.js ADR 0022, sections 1 and 2). The
// cases at :998 and :1041 also need the legend, which
// flutter_test_config.dart registers: the legend changes the top of the
// chart area.
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
// - `toBeCloseTo` is `_toBeCloseTo`. `toEqual` is `jasmineEquals`.
// - `chart.scales.y.options.stacked = true` writes through the resolver of
//   the scale options: `chart.scales['y']!.options['stacked'] = true`.
// - `chart.options.scales.y.ticks.maxTicksLimit = 11` writes into the
//   resolver of the last read of the chain (`_optionsY`).
// - `chart.scales.y.start` and `end` are fields of `LinearScaleBase`.
// - `index.toString()` of a tick callback is `jsToString(index)`.
// - `expect(fn).not.toThrow()` is `expect(fn, returnsNormally)`.

/// scale.linear.tests.js:1-3 `getLabels(scale)`.
List<Object?> _getLabels(Scale scale) => [
  for (final t in scale.ticks!) t.label,
];

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as AnyObject;

/// `chart.options.scales.y`, or `chart.options.scales.y[key]` for a [key]:
/// a resolver of the chart options.
AnyObject _optionsY(Chart chart, [String? key]) {
  final y = jsGet(jsGet(chart.options, 'scales'), 'y');
  return (key == null ? y : jsGet(y, key))! as AnyObject;
}

/// Jasmine `toBeCloseTo(expected, precision)` of jasmine-core 3.99.1:
/// `Math.round(delta * 10^(precision + 1)) <= 10^-precision / 2 *
/// 10^(precision + 1)`, with `delta = |expected - actual|`. The spec also
/// gives a precision that is not an integer, `1e-2` (:1027-1038).
Matcher _toBeCloseTo(num expected, [num precision = 2]) {
  // js-ok: a test tolerance only, as Jasmine's Math.pow.
  final pow = math.pow(10.0, precision + 1);
  // js-ok: a test tolerance only, as Jasmine's Math.pow.
  final maxDelta = math.pow(10.0, -precision) / 2;
  return predicate<Object?>(
    (actual) =>
        actual is num &&
        jsRound(((expected - actual).abs() * pow).toDouble()) <= maxDelta * pow,
    'a number close to ${jsToString(expected)} (Jasmine toBeCloseTo, '
    'precision ${jsToString(precision)})',
  );
}

void main() {
  group('Linear Scale', () {
    group('auto', fixture.specs('scale.linear'));

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

    testWidgets(
      'Should correctly determine the max & min data values',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10, 5, 0, -5, 78, -100],
              },
              <String, Object?>{
                'yAxisID': 'y2',
                'data': <Object?>[-1000, 1000],
              },
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[150],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear'},
              'y2': <String, Object?>{'type': 'linear', 'position': 'right'},
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, -100);
        expect(chart.scales['y']!.max, 150);
      },
    );

    testWidgets('Should handle when only a min value is provided', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'yAxisID': 'y',
              'data': <Object?>[200],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{'type': 'linear', 'min': 250},
          },
        },
      });

      expect(chart.scales['y']!.min, 250);
    });

    testWidgets('Should handle when only a max value is provided', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'yAxisID': 'y',
              'data': <Object?>[200],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{'type': 'linear', 'max': 150},
          },
        },
      });

      expect(chart.scales['y'], isNotNull); // must construct
      expect(chart.scales['y']!.max, 150);
    });

    testWidgets(
      'Should correctly determine the max & min of string data values',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>['10', '5', '0', '-5', '78', '-100'],
              },
              <String, Object?>{
                'yAxisID': 'y2',
                'data': <Object?>['-1000', '1000'],
              },
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>['150'],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear'},
              'y2': <String, Object?>{'type': 'linear', 'position': 'right'},
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, -100);
        expect(chart.scales['y']!.max, 150);
      },
    );

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
                'type': 'linear',
                'suggestedMin': -10,
                'suggestedMax': 15,
              },
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, -10);
        expect(chart.scales['y']!.max, 15);
      },
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

    testWidgets(
      'Should correctly determine the max & min data values ignoring hidden '
      'datasets',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>['10', '5', '0', '-5', '78', '-100'],
              },
              <String, Object?>{
                'yAxisID': 'y2',
                'data': <Object?>['-1000', '1000'],
              },
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>['150'],
                'hidden': true,
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear'},
              'y2': <String, Object?>{'position': 'right', 'type': 'linear'},
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, -100);
        expect(chart.scales['y']!.max, 80);
      },
    );

    testWidgets(
      'Should correctly determine the max & min data values ignoring data '
      'that is NaN',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[
                  null,
                  90,
                  double.nan,
                  undefined,
                  45,
                  30,
                  double.infinity,
                  double.negativeInfinity,
                ],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear', 'beginAtZero': false},
            },
          },
        });

        expect(chart.scales['y']!.min, 30);
        expect(chart.scales['y']!.max, 90);

        // Scale is now stacked
        chart.scales['y']!.options['stacked'] = true;
        chart.update();

        expect(chart.scales['y']!.min, 30);
        expect(chart.scales['y']!.max, 90);

        chart.scales['y']!.options['beginAtZero'] = true;
        chart.update();

        expect(chart.scales['y']!.min, 0);
        expect(chart.scales['y']!.max, 90);
      },
    );

    testWidgets(
      'Should correctly determine the max & min data values for small numbers',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[-1e-8, 3e-8, -4e-8, 6e-8],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min * 1e8, _toBeCloseTo(-4));
        expect(chart.scales['y']!.max * 1e8, _toBeCloseTo(6));
      },
    );

    testWidgets(
      'Should correctly determine the max & min for scatter data',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'xAxisID': 'x',
                'yAxisID': 'y',
                'data': <Object?>[
                  <String, Object?>{'x': 10, 'y': 100},
                  <String, Object?>{'x': -10, 'y': 0},
                  <String, Object?>{'x': 0, 'y': 0},
                  <String, Object?>{'x': 99, 'y': 7},
                ],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear', 'position': 'bottom'},
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        })..update();

        expect(chart.scales['x']!.min, -20);
        expect(chart.scales['x']!.max, 100);
        expect(chart.scales['y']!.min, 0);
        expect(chart.scales['y']!.max, 100);
      },
    );

    testWidgets('Should correctly get the label for the given index', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'xAxisID': 'x',
              'yAxisID': 'y',
              'data': <Object?>[
                <String, Object?>{'x': 10, 'y': 100},
                <String, Object?>{'x': -10, 'y': 0},
                <String, Object?>{'x': 0, 'y': 0},
                <String, Object?>{'x': 99, 'y': 7},
              ],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear', 'position': 'bottom'},
            'y': <String, Object?>{'type': 'linear'},
          },
        },
      })..update();

      expect(chart.scales['y']!.getLabelForValue(7), '7');
    });

    testWidgets(
      'Should correctly use the locale setting when getting a label',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'xAxisID': 'x',
                'yAxisID': 'y',
                'data': <Object?>[
                  <String, Object?>{'x': 10, 'y': 100},
                  <String, Object?>{'x': -10, 'y': 0},
                  <String, Object?>{'x': 0, 'y': 0},
                  <String, Object?>{'x': 99, 'y': 7},
                ],
              },
            ],
          },
          'options': <String, Object?>{
            'locale': 'de-DE',
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear', 'position': 'bottom'},
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        })..update();

        expect(chart.scales['y']!.getLabelForValue(7.07), '7,07');
      },
    );

    testWidgets(
      'Should correctly determine the min and max data values when stacked '
      'mode is turned on',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10, 5, 0, -5, 78, -100],
                'type': 'bar',
              },
              <String, Object?>{
                'yAxisID': 'y2',
                'data': <Object?>[-1000, 1000],
              },
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[150, 0, 0, -100, -10, 9],
                'type': 'bar',
              },
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10, 10, 10, 10, 10, 10],
                'type': 'line',
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear', 'stacked': true},
              'y2': <String, Object?>{'position': 'right', 'type': 'linear'},
            },
          },
        })..update();

        expect(chart.scales['y']!.min, -150);
        expect(chart.scales['y']!.max, 200);
      },
    );

    testWidgets(
      'Should correctly determine the min and max data values when stacked '
      'mode is turned on and there are hidden datasets',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10, 5, 0, -5, 78, -100],
              },
              <String, Object?>{
                'yAxisID': 'y2',
                'data': <Object?>[-1000, 1000],
              },
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[150, 0, 0, -100, -10, 9],
              },
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10, 20, 30, 40, 50, 60],
                'hidden': true,
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear', 'stacked': true},
              'y2': <String, Object?>{'position': 'right', 'type': 'linear'},
            },
          },
        })..update();

        expect(chart.scales['y']!.min, -150);
        expect(chart.scales['y']!.max, 200);
      },
    );

    testWidgets(
      'Should correctly determine the min and max data values when stacked '
      'mode is turned on there are multiple types of datasets',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'type': 'bar',
                'data': <Object?>[10, 5, 0, -5, 78, -100],
              },
              <String, Object?>{
                'type': 'line',
                'data': <Object?>[10, 10, 10, 10, 10, 10],
              },
              <String, Object?>{
                'type': 'bar',
                'data': <Object?>[150, 0, 0, -100, -10, 9],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear', 'stacked': true},
            },
          },
        });

        chart.scales['y']!.determineDataLimits();
        expect(chart.scales['y']!.min, -105);
        expect(chart.scales['y']!.max, 160);
      },
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

    testWidgets(
      'Should ensure that the scale has a max and min that are not equal - '
      'large positive numbers',
      (tester) async {
        // https://github.com/chartjs/Chart.js/issues/9377
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                // Value larger than Number.MAX_SAFE_INTEGER
                'data': <Object?>[10000000000000000],
              },
            ],
            'labels': <Object?>['a'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 10000000000000000 * 0.95);
        expect(chart.scales['y']!.max, 10000000000000000 * 1.05);
      },
    );

    testWidgets(
      'Should ensure that the scale has a max and min that are not equal - '
      'large negative numbers',
      (tester) async {
        // https://github.com/chartjs/Chart.js/issues/9377
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                // Value larger than Number.MAX_SAFE_INTEGER
                'data': <Object?>[-10000000000000000],
              },
            ],
            'labels': <Object?>['a'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.max, -10000000000000000 * 0.95);
        expect(chart.scales['y']!.min, -10000000000000000 * 1.05);
      },
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

    testWidgets(
      'Should use the suggestedMin and suggestedMax options',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[1, 1, 1, 2, 1, 0],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'linear',
                'suggestedMax': 10,
                'suggestedMin': -10,
              },
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, -10);
        expect(chart.scales['y']!.max, 10);
      },
    );

    testWidgets(
      'Should use the min and max options',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[1, 1, 1, 2, 1, 0],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'linear',
                'max': 1010,
                'min': -1010,
              },
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, -1010);
        expect(chart.scales['y']!.max, 1010);
        final labels = _getLabels(chart.scales['y']!);
        expect(labels[0], '-1,010');
        expect(labels[labels.length - 1], '1,010');
      },
    );

    testWidgets(
      'Should use min, max and stepSize to create fixed spaced ticks',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10, 3, 6, 8, 3, 1],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'linear',
                'min': 1,
                'max': 11,
                'ticks': <String, Object?>{'stepSize': 2},
              },
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 1);
        expect(chart.scales['y']!.max, 11);
        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>['1', '3', '5', '7', '9', '11']),
        );
      },
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

    testWidgets(
      'Should create decimal steps if stepSize is a decimal number',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10, 3, 6, 8, 3, 1],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'linear',
                'ticks': <String, Object?>{'stepSize': 2.5},
              },
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 0);
        expect(chart.scales['y']!.max, 10);
        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>['0', '2.5', '5', '7.5', '10']),
        );
      },
    );

    group('precision', () {
      testWidgets(
        'Should create integer steps if precision is 0',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'bar',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'yAxisID': 'y',
                  'data': <Object?>[0, 1, 2, 1, 0, 1],
                },
              ],
              'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'y': <String, Object?>{
                  'type': 'linear',
                  'ticks': <String, Object?>{'precision': 0},
                },
              },
            },
          });

          expect(chart.scales['y'], isNotNull); // must construct
          expect(chart.scales['y']!.min, 0);
          expect(chart.scales['y']!.max, 2);
          expect(
            _getLabels(chart.scales['y']!),
            jasmineEquals(<Object?>['0', '1', '2']),
          );
        },
      );

      testWidgets(
        'Should round the step size to the given number of decimal places',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'bar',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'yAxisID': 'y',
                  'data': <Object?>[0, 0.001, 0.002, 0.003, 0, 0.001],
                },
              ],
              'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'y': <String, Object?>{
                  'type': 'linear',
                  'ticks': <String, Object?>{'precision': 2},
                },
              },
            },
          });

          expect(chart.scales['y'], isNotNull); // must construct
          expect(chart.scales['y']!.min, 0);
          expect(chart.scales['y']!.max, 0.01);
          expect(
            _getLabels(chart.scales['y']!),
            jasmineEquals(<Object?>['0', '0.01']),
          );
        },
      );
    });

    testWidgets(
      'should forcibly include 0 in the range if the beginAtZero option is '
      'used',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[20, 30, 40, 50],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear', 'beginAtZero': false},
            },
          },
        });

        expect(chart.scales['y'], isNotNull); // must construct
        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>['20', '25', '30', '35', '40', '45', '50']),
        );

        chart.scales['y']!.options['beginAtZero'] = true;
        chart.update();
        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>[
            '0',
            '5',
            '10',
            '15',
            '20',
            '25',
            '30',
            '35',
            '40',
            '45',
            '50',
          ]),
        );

        _dataset(chart, 0)['data'] = <Object?>[-20, -30, -40, -50];
        chart.update();
        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>[
            '-50',
            '-45',
            '-40',
            '-35',
            '-30',
            '-25',
            '-20',
            '-15',
            '-10',
            '-5',
            '0',
          ]),
        );

        chart.scales['y']!.options['beginAtZero'] = false;
        chart.update();
        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>[
            '-50',
            '-45',
            '-40',
            '-35',
            '-30',
            '-25',
            '-20',
          ]),
        );
      },
    );

    testWidgets(
      'Should generate tick marks in the correct order in reversed mode',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear', 'reverse': true},
            },
          },
        });

        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>[
            '80',
            '70',
            '60',
            '50',
            '40',
            '30',
            '20',
            '10',
            '0',
          ]),
        );
        expect((chart.scales['y']! as LinearScaleBase).start, 80);
        expect((chart.scales['y']! as LinearScaleBase).end, 0);
      },
    );

    testWidgets(
      'should use the correct number of decimal places in the default format '
      'function',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[0.06, 0.005, 0, 0.025, 0.0078],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        });

        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>[
            '0',
            '0.01',
            '0.02',
            '0.03',
            '0.04',
            '0.05',
            '0.06',
          ]),
        );
      },
    );

    testWidgets(
      'Should correctly limit the maximum number of ticks',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'labels': <Object?>['a', 'b'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[0.5, 2.5],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'beginAtZero': false},
            },
          },
        });

        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>['0.5', '1.0', '1.5', '2.0', '2.5']),
        );

        _optionsY(chart, 'ticks')['maxTicksLimit'] = 11;
        chart.update();

        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>['0.5', '1.0', '1.5', '2.0', '2.5']),
        );

        _optionsY(chart, 'ticks')['maxTicksLimit'] = 21;
        chart.update();

        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>[
            '0.5',
            '0.6',
            '0.7',
            '0.8',
            '0.9',
            '1.0',
            '1.1',
            '1.2',
            '1.3',
            '1.4',
            '1.5',
            '1.6',
            '1.7',
            '1.8',
            '1.9',
            '2.0',
            '2.1',
            '2.2',
            '2.3',
            '2.4',
            '2.5',
          ]),
        );

        _optionsY(chart, 'ticks')['maxTicksLimit'] = 11;
        _optionsY(chart, 'ticks')['stepSize'] = 0.01;
        chart.update();

        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>['0.5', '1.0', '1.5', '2.0', '2.5']),
        );

        _optionsY(chart)['min'] = 0.3;
        _optionsY(chart)['max'] = 2.8;
        chart.update();

        expect(
          _getLabels(chart.scales['y']!),
          jasmineEquals(<Object?>['0.3', '0.8', '1.3', '1.8', '2.3', '2.8']),
        );
      },
    );

    testWidgets('Should bound to data', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 99],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{'bounds': 'data'},
          },
        },
      });

      expect(chart.scales['y']!.min, jasmineEquals(1));
      expect(chart.scales['y']!.max, jasmineEquals(99));
    });

    testWidgets(
      'Should build labels using the user supplied callback',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>['a', 'b', 'c', 'd'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'linear',
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
          jasmineEquals(<Object?>['0', '1', '2', '3', '4', '5', '6', '7', '8']),
        );
      },
    );

    testWidgets('Should get the correct pixel value for a point', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>[-1, 1],
          'datasets': <Object?>[
            <String, Object?>{
              'xAxisID': 'x',
              'yAxisID': 'y',
              'data': <Object?>[-1, 1],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear', 'position': 'bottom'},
            'y': <String, Object?>{'type': 'linear'},
          },
        },
      });

      final xScale = chart.scales['x']!;
      expect(
        xScale.getPixelForValue(1),
        toBeCloseToPixel(501),
      ); // right - paddingRight
      expect(
        xScale.getPixelForValue(-1),
        toBeCloseToPixel(31 + 3),
      ); // left + paddingLeft + tick padding
      expect(
        xScale.getPixelForValue(0),
        toBeCloseToPixel(266 + 3 / 2),
      ); // halfway*/

      expect(xScale.getValueForPixel(501), _toBeCloseTo(1, 1e-2));
      expect(xScale.getValueForPixel(31), _toBeCloseTo(-1, 1e-2));
      expect(xScale.getValueForPixel(266), _toBeCloseTo(0, 1e-2));

      final yScale = chart.scales['y']!;
      expect(
        yScale.getPixelForValue(1),
        toBeCloseToPixel(32),
      ); // right - paddingRight
      expect(
        yScale.getPixelForValue(-1),
        toBeCloseToPixel(484),
      ); // left + paddingLeft
      expect(yScale.getPixelForValue(0), toBeCloseToPixel(258)); // halfway*/

      expect(yScale.getValueForPixel(32), _toBeCloseTo(1, 1e-2));
      expect(yScale.getValueForPixel(484), _toBeCloseTo(-1, 1e-2));
      expect(yScale.getValueForPixel(258), _toBeCloseTo(0, 1e-2));
    });

    testWidgets('should fit correctly', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'xAxisID': 'x',
              'yAxisID': 'y',
              'data': <Object?>[
                <String, Object?>{'x': 10, 'y': 100},
                <String, Object?>{'x': -10, 'y': 0},
                <String, Object?>{'x': 0, 'y': 0},
                <String, Object?>{'x': 99, 'y': 7},
              ],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear', 'position': 'bottom'},
            'y': <String, Object?>{'type': 'linear'},
          },
        },
      });

      final xScale = chart.scales['x']!;
      final yScale = chart.scales['y']!;
      expect(xScale.paddingTop, toBeCloseToPixel(0));
      expect(xScale.paddingBottom, toBeCloseToPixel(0));
      expect(xScale.paddingLeft, toBeCloseToPixel(12));
      expect(xScale.paddingRight, toBeCloseToPixel(13.5));
      expect(xScale.width, toBeCloseToPixel(468 - 3)); // minus tick padding
      expect(xScale.height, toBeCloseToPixel(30));

      expect(yScale.paddingTop, toBeCloseToPixel(10));
      expect(yScale.paddingBottom, toBeCloseToPixel(10));
      expect(yScale.paddingLeft, toBeCloseToPixel(0));
      expect(yScale.paddingRight, toBeCloseToPixel(0));
      expect(yScale.width, toBeCloseToPixel(31 + 3)); // plus tick padding
      expect(yScale.height, toBeCloseToPixel(450));

      // Extra size when scale label showing
      (jsGet(xScale.options, 'title')! as AnyObject)['display'] = true;
      (jsGet(yScale.options, 'title')! as AnyObject)['display'] = true;
      chart.update();

      expect(xScale.paddingTop, toBeCloseToPixel(0));
      expect(xScale.paddingBottom, toBeCloseToPixel(0));
      expect(xScale.paddingLeft, toBeCloseToPixel(12));
      expect(xScale.paddingRight, toBeCloseToPixel(13.5));
      expect(xScale.width, toBeCloseToPixel(442));
      expect(xScale.height, toBeCloseToPixel(50));

      expect(yScale.paddingTop, toBeCloseToPixel(10));
      expect(yScale.paddingBottom, toBeCloseToPixel(10));
      expect(yScale.paddingLeft, toBeCloseToPixel(0));
      expect(yScale.paddingRight, toBeCloseToPixel(0));
      expect(yScale.width, toBeCloseToPixel(58));
      expect(yScale.height, toBeCloseToPixel(429));
    });

    testWidgets('should fit correctly when display is turned off', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'xAxisID': 'x',
              'yAxisID': 'y',
              'data': <Object?>[
                <String, Object?>{'x': 10, 'y': 100},
                <String, Object?>{'x': -10, 'y': 0},
                <String, Object?>{'x': 0, 'y': 0},
                <String, Object?>{'x': 99, 'y': 7},
              ],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear', 'position': 'bottom'},
            'y': <String, Object?>{
              'type': 'linear',
              'grid': <String, Object?>{'drawTicks': false},
              'border': <String, Object?>{'display': false},
              'title': <String, Object?>{'display': false, 'lineHeight': 1.2},
              'ticks': <String, Object?>{'display': false, 'padding': 0},
            },
          },
        },
      });

      final yScale = chart.scales['y']!;
      expect(yScale.width, toBeCloseToPixel(0));
    });

    testWidgets(
      'max and min value should be valid and finite when charts datasets are '
      'hidden',
      (tester) async {
        final barData = <String, Object?>{
          'labels': <Object?>['S1', 'S2', 'S3'],
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'Closed',
              'backgroundColor': '#382765',
              'data': <Object?>[2500, 2000, 1500],
            },
            <String, Object?>{
              'label': 'In Progress',
              'backgroundColor': '#7BC225',
              'data': <Object?>[1000, 2000, 1500],
            },
            <String, Object?>{
              'label': 'Assigned',
              'backgroundColor': '#ffC225',
              'data': <Object?>[1000, 2000, 1500],
            },
          ],
        };

        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': barData,
          'options': <String, Object?>{
            'indexAxis': 'y',
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': true},
              'y': <String, Object?>{'stacked': true},
            },
          },
        });

        // barData.datasets.forEach((data, index) => {...}).
        final datasets = barData['datasets']! as List<Object?>;
        for (var index = 0; index < datasets.length; index++) {
          chart.getDatasetMeta(index).hidden = true;
          chart.update();
        }

        expect(chart.scales['x']!.min, jasmineEquals(0));
        expect(chart.scales['x']!.max, jasmineEquals(1));
      },
    );

    testWidgets(
      'max and min value should be valid when min is set and all datasets are '
      'hidden',
      (tester) async {
        final barData = <String, Object?>{
          'labels': <Object?>['S1', 'S2', 'S3'],
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'dataset 1',
              'backgroundColor': '#382765',
              'data': <Object?>[2500, 2000, 1500],
              'hidden': true,
            },
          ],
        };

        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': barData,
          'options': <String, Object?>{
            'indexAxis': 'y',
            'scales': <String, Object?>{
              'x': <String, Object?>{'min': 20},
            },
          },
        });

        expect(chart.scales['x']!.min, jasmineEquals(20));
        expect(chart.scales['x']!.max, jasmineEquals(21));
      },
    );

    testWidgets(
      'min settings should be used if set to zero',
      (tester) async {
        final barData = <String, Object?>{
          'labels': <Object?>['S1', 'S2', 'S3'],
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'dataset 1',
              'backgroundColor': '#382765',
              'data': <Object?>[2500, 2000, 1500],
            },
          ],
        };

        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': barData,
          'options': <String, Object?>{
            'indexAxis': 'y',
            'scales': <String, Object?>{
              'x': <String, Object?>{'min': 0, 'max': 3000},
            },
          },
        });

        expect(chart.scales['x']!.min, jasmineEquals(0));
      },
    );

    testWidgets(
      'max settings should be used if set to zero',
      (tester) async {
        final barData = <String, Object?>{
          'labels': <Object?>['S1', 'S2', 'S3'],
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'dataset 1',
              'backgroundColor': '#382765',
              'data': <Object?>[-2500, -2000, -1500],
            },
          ],
        };

        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': barData,
          'options': <String, Object?>{
            'indexAxis': 'y',
            'scales': <String, Object?>{
              'x': <String, Object?>{'min': -3000, 'max': 0},
            },
          },
        });

        expect(chart.scales['x']!.max, jasmineEquals(0));
      },
    );

    testWidgets(
      'Should get correct pixel values when horizontal',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[0.05, -25, 10, 15, 20, 25, 30, 35],
              },
            ],
          },
          'options': <String, Object?>{
            'indexAxis': 'y',
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear'},
            },
          },
        });

        var start = chart.chartArea!.left;
        var end = chart.chartArea!.right;
        const min = -30;
        const max = 40;
        final scale = chart.scales['x']!;

        expect(scale.getPixelForValue(max), toBeCloseToPixel(end));
        expect(scale.getPixelForValue(min), toBeCloseToPixel(start));
        expect(scale.getValueForPixel(end), _toBeCloseTo(max, 4));
        expect(scale.getValueForPixel(start), _toBeCloseTo(min, 4));

        scale.options['reverse'] = true;
        chart.update();

        start = chart.chartArea!.left;
        end = chart.chartArea!.right;

        expect(scale.getPixelForValue(max), toBeCloseToPixel(start));
        expect(scale.getPixelForValue(min), toBeCloseToPixel(end));
        expect(scale.getValueForPixel(end), _toBeCloseTo(min, 4));
        expect(scale.getValueForPixel(start), _toBeCloseTo(max, 4));
      },
    );

    testWidgets(
      'Should get correct pixel values when vertical',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[0.05, -25, 10, 15, 20, 25, 30, 35],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        });

        var start = chart.chartArea!.bottom;
        var end = chart.chartArea!.top;
        const min = -30;
        const max = 40;
        final scale = chart.scales['y']!;

        expect(scale.getPixelForValue(max), toBeCloseToPixel(end));
        expect(scale.getPixelForValue(min), toBeCloseToPixel(start));
        expect(scale.getValueForPixel(end), _toBeCloseTo(max, 4));
        expect(scale.getValueForPixel(start), _toBeCloseTo(min, 4));

        scale.options['reverse'] = true;
        chart.update();

        start = chart.chartArea!.bottom;
        end = chart.chartArea!.top;

        expect(scale.getPixelForValue(max), toBeCloseToPixel(start));
        expect(scale.getPixelForValue(min), toBeCloseToPixel(end));
        expect(scale.getValueForPixel(end), _toBeCloseTo(min, 4));
        expect(scale.getValueForPixel(start), _toBeCloseTo(max, 4));
      },
    );

    testWidgets(
      'should not throw errors when chart size is negative',
      (tester) async {
        Chart createChart() {
          return acquireChart(
            <String, Object?>{
              'type': 'bar',
              'data': <String, Object?>{
                'labels': <Object?>[0, 1, 2, 3, 4, 5, 6, 7, '7+'],
                'datasets': <Object?>[
                  <String, Object?>{
                    'data': <Object?>[
                      29.05,
                      4,
                      15.69,
                      11.69,
                      2.84,
                      4,
                      0,
                      3.84,
                      4,
                    ],
                  },
                ],
              },
              'options': <String, Object?>{
                'plugins': false,
                'layout': <String, Object?>{
                  'padding': <String, Object?>{
                    'top': 30,
                    'left': 1,
                    'right': 1,
                    'bottom': 1,
                  },
                },
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'height': 0, 'width': 0},
            },
          );
        }

        expect(createChart, returnsNormally);
      },
    );
  });
}
