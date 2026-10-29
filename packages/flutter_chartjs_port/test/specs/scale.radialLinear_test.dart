// Ported from Chart.js v4.6.1 test/specs/scale.radialLinear.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec reads the registry, the defaults and the charts of
// flutter_chartjs_port, which does not export lib/src yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/scales/scale.radialLinear.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// `Chart.registry` and `Chart.defaults` are the statics of Chart of
// core.controller.dart. The two cases without a chart read only the
// registry and `Chart.defaults.scales.radialLinear`. They need the built-in
// scales that flutter_test_config.dart registers. Thus the file does not
// call `setUpSpecs()`. It runs on the VM, because core.controller.dart
// reaches the platform layer.
//
// Each chart case has the type `radar` or `polarArea`. The scale `r` gets
// the type `radialLinear` from the overrides of the controller. The chart
// cases are `testWidgets` cases with `acquireChart` (Chart.js ADR 0022,
// section 2). The case "Should ensure that the scale has a max and min that
// are not equal" has no dataset, but it needs the radar overrides too:
// without them, the scale has no radialLinear defaults. Three cases also
// need the legend plugin, which flutter_test_config.dart registers. The
// legend makes the chart area smaller, and the cases compare `drawingArea`
// (215), `yCenter` (280) and the values that come from them. Without the
// legend, these are 231 and 264.
//
// The spec forms:
// - A property chain of the spec, for example `Chart.defaults.scales`, is a
//   chain of `jsGet`.
// - `typeof x` is `jsTypeof(x)`. The class value of a scale is a `JsClass`,
//   and its `typeof` is `'function'` (Chart.js ADR 0020).
// - `toEqual` of an object compares the keys and the values with `equals`.
//   A routed key, for example `ticks.color`, is a key of the RoutedScope
//   and reads its route target. The key `backdropColor` holds the
//   `undefined` sentinel. Functions compare by identity.
// - `jasmine.any(Function)` is [_anyFunction], which uses `jsIsFunction`. A
//   value with `typeof` `'function'` is a Dart `Function`, a `JsFunction`
//   or a `JsClass`. `ticks.callback` is the JsFunction `formatters.numeric`,
//   which reads `this`. Thus `isA<Function>()` does not match it.
//
// - The chart cases read `_pointLabels` and `_pointLabelItems` as
//   `pointLabels` and `pointLabelItems` (Chart.js ADR 0012, Underscore
//   members, and Chart.js ADR 0025, section 6). `chart.scales.r` is
//   `chart.scales['r']!`, or `_r(chart)` for a member of
//   `RadialLinearScale`.
// - `toEqual` of an array is `jasmineEquals`.
// - `chart.scales.r.options.reverse = true` writes through the resolver of
//   the scale options. `chart.options.scales.r.ticks.maxTicksLimit = 11`
//   writes into the resolver of the last read of the chain (`_optionsR`).
// - `index.toString()` of a callback is `jsToString(index)`.
//   `Math.round` is `jsRound`.
// - `expect(...).withContext(text)` is the `reason` of `expect`.
// - `scale.ctx = window.createMockContext()` is
//   `scale.ctx = createMockContext()`, a mock context of
//   package:chartjs_test_utils/pure.dart. A call of `getCalls()` is a Map
//   with the keys `name` and `args`.

/// `jasmine.any(Function)`: a value with `typeof` `'function'`.
final Matcher _anyFunction = predicate(jsIsFunction, 'any Function');

/// scale.radialLinear.tests.js:1-3 `getLabels(scale)`.
List<Object?> _getLabels(Scale scale) => [
  for (final t in scale.ticks!) t.label,
];

/// `chart.scales.r`, the radial linear scale of [chart].
RadialLinearScale _r(Chart chart) => chart.scales['r']! as RadialLinearScale;

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as AnyObject;

/// `chart.options.scales.r`, or `chart.options.scales.r[key]` for a [key]:
/// a resolver of the chart options.
AnyObject _optionsR(Chart chart, [String? key]) {
  final r = jsGet(jsGet(chart.options, 'scales'), 'r');
  return (key == null ? r : jsGet(r, key))! as AnyObject;
}

void main() {
  // Tests for the radial linear scale used by the polar area and radar charts
  group('Test the radial linear scale', () {
    group('auto', fixture.specs('scale.radialLinear'));

    test('Should register the constructor with the registry', () {
      final constructor = Chart.registry.getScale('radialLinear');
      expect(constructor, isNot(same(undefined)));
      expect(jsTypeof(constructor), 'function');
    });

    test('Should have the correct default config', () {
      final defaultConfig = jsGet(
        jsGet(Chart.defaults, 'scales'),
        'radialLinear',
      );
      expect(
        defaultConfig,
        equals(<String, Object?>{
          'display': true,
          'animate': true,
          'position': 'chartArea',

          'angleLines': <String, Object?>{
            'display': true,
            'color': 'rgba(0,0,0,0.1)',
            'lineWidth': 1,
            'borderDash': <Object?>[],
            'borderDashOffset': 0.0,
          },

          'grid': <String, Object?>{'circular': false},

          'startAngle': 0,

          'ticks': <String, Object?>{
            'color': jsGet(Chart.defaults, 'color'),
            'showLabelBackdrop': true,
            'callback': jsGet(jsGet(defaultConfig, 'ticks'), 'callback'),
          },

          'pointLabels': <String, Object?>{
            'backdropColor': undefined,
            'backdropPadding': 2,
            'color': jsGet(Chart.defaults, 'color'),
            'display': true,
            'font': <String, Object?>{'size': 10},
            'callback': jsGet(jsGet(defaultConfig, 'pointLabels'), 'callback'),
            'padding': 5,
            'centerPointLabels': false,
          },
        }),
      );

      // Is this actually a function
      expect(jsGet(jsGet(defaultConfig, 'ticks'), 'callback'), _anyFunction);
      expect(
        jsGet(jsGet(defaultConfig, 'pointLabels'), 'callback'),
        _anyFunction,
      );
    });

    testWidgets(
      'Should correctly determine the max & min data values',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, -5, 78, -100],
              },
              <String, Object?>{
                'data': <Object?>[150],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
              'label6',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{},
          },
        });

        expect(chart.scales['r']!.min, -100);
        expect(chart.scales['r']!.max, 150);
      },
    );

    testWidgets(
      'Should correctly determine the max & min of string data values',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>['10', '5', '0', '-5', '78', '-100'],
              },
              <String, Object?>{
                'data': <Object?>['150'],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
              'label6',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{},
          },
        });

        expect(chart.scales['r']!.min, -100);
        expect(chart.scales['r']!.max, 150);
      },
    );

    testWidgets(
      'Should correctly determine the max & min data values when there are '
      'hidden datasets',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>['10', '5', '0', '-5', '78', '-100'],
              },
              <String, Object?>{
                'data': <Object?>['150'],
              },
              <String, Object?>{
                'data': <Object?>[1000],
                'hidden': true,
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
              'label6',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{},
          },
        });

        expect(chart.scales['r']!.min, -100);
        expect(chart.scales['r']!.max, 150);
      },
    );

    testWidgets(
      'Should correctly determine the max & min data values when there is '
      'NaN data',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  50,
                  60,
                  double.nan,
                  70,
                  null,
                  undefined,
                  double.infinity,
                  double.negativeInfinity,
                ],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
              'label6',
              'label7',
              'label8',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{},
          },
        });

        expect(chart.scales['r']!.min, 50);
        expect(chart.scales['r']!.max, 70);
      },
    );

    testWidgets(
      'Should ensure that the scale has a max and min that are not equal',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{'rScale': <String, Object?>{}},
          },
        });

        final scale = chart.scales['rScale']!;

        expect(scale.min, -1);
        expect(scale.max, 1);
      },
    );

    testWidgets(
      'Should use the suggestedMin and suggestedMax options',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 1, 1, 2, 1, 0],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
              'label6',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{'suggestedMin': -10, 'suggestedMax': 10},
            },
          },
        });

        expect(chart.scales['r']!.min, -10);
        expect(chart.scales['r']!.max, 10);
      },
    );

    testWidgets(
      'Should use the min and max options',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 1, 1, 2, 1, 0],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
              'label6',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{'min': -1010, 'max': 1010},
            },
          },
        });

        expect(chart.scales['r']!.min, -1010);
        expect(chart.scales['r']!.max, 1010);
        expect(
          _getLabels(chart.scales['r']!),
          jasmineEquals(<Object?>['-1,010', '-500', '0', '500', '1,010']),
        );
      },
    );

    testWidgets(
      'should forcibly include 0 in the range if the beginAtZero option is '
      'used',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[20, 30, 40, 50],
              },
            ],
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{'beginAtZero': false},
            },
          },
        });

        expect(
          _getLabels(chart.scales['r']!),
          jasmineEquals(<Object?>['20', '25', '30', '35', '40', '45', '50']),
        );

        chart.scales['r']!.options['beginAtZero'] = true;
        chart.update();

        expect(
          _getLabels(chart.scales['r']!),
          jasmineEquals(<Object?>[
            '0', '5', '10', '15', '20', '25', '30', '35', '40', '45', '50', //
          ]),
        );

        _dataset(chart, 0)['data'] = <Object?>[-20, -30, -40, -50];
        chart.update();

        expect(
          _getLabels(chart.scales['r']!),
          jasmineEquals(<Object?>[
            '-50', '-45', '-40', '-35', '-30', '-25', '-20', '-15', '-10', //
            '-5', '0',
          ]),
        );

        chart.scales['r']!.options['beginAtZero'] = false;
        chart.update();

        expect(
          _getLabels(chart.scales['r']!),
          jasmineEquals(<Object?>[
            '-50', '-45', '-40', '-35', '-30', '-25', '-20', //
          ]),
        );
      },
    );

    testWidgets(
      'Should generate tick marks in the correct order in reversed mode',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{'reverse': true},
            },
          },
        });

        expect(
          _getLabels(chart.scales['r']!),
          jasmineEquals(<Object?>[
            '80', '70', '60', '50', '40', '30', '20', '10', '0', //
          ]),
        );
        expect(_r(chart).start, 80);
        expect(_r(chart).end, 0);
      },
    );

    testWidgets(
      'Should correctly limit the maximum number of ticks',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'labels': <Object?>['label1', 'label2', 'label3'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[0.5, 1.5, 2.5],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{
                'pointLabels': <String, Object?>{'display': false},
              },
            },
          },
        });

        expect(
          _getLabels(chart.scales['r']!),
          jasmineEquals(<Object?>['0.5', '1.0', '1.5', '2.0', '2.5']),
        );

        _optionsR(chart, 'ticks')['maxTicksLimit'] = 11;
        chart.update();

        expect(
          _getLabels(chart.scales['r']!),
          jasmineEquals(<Object?>['0.5', '1.0', '1.5', '2.0', '2.5']),
        );

        _optionsR(chart, 'ticks')['stepSize'] = 0.01;
        chart.update();

        expect(
          _getLabels(chart.scales['r']!),
          jasmineEquals(<Object?>['0.5', '1.0', '1.5', '2.0', '2.5']),
        );

        _optionsR(chart)['min'] = 0.3;
        _optionsR(chart)['max'] = 2.8;
        chart.update();

        expect(
          _getLabels(chart.scales['r']!),
          jasmineEquals(<Object?>['0.3', '0.8', '1.3', '1.8', '2.3', '2.8']),
        );
      },
    );

    testWidgets(
      'Should build labels using the user supplied callback',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{
                'ticks': <String, Object?>{
                  'callback': (Object? value, Object? index) =>
                      jsToString(index),
                },
              },
            },
          },
        });

        expect(
          _getLabels(chart.scales['r']!),
          jasmineEquals(<Object?>['0', '1', '2', '3', '4', '5', '6', '7', '8']),
        );
        expect(
          _r(chart).pointLabels,
          jasmineEquals(<Object?>[
            'label1',
            'label2',
            'label3',
            'label4',
            'label5',
          ]),
        );
      },
    );

    testWidgets(
      'Should build point labels using the user supplied callback',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{
                'pointLabels': <String, Object?>{
                  'callback': (Object? value, Object? index) =>
                      jsToString(index),
                },
              },
            },
          },
        });

        expect(
          _r(chart).pointLabels,
          jasmineEquals(<Object?>['0', '1', '2', '3', '4']),
        );
      },
    );

    testWidgets(
      'Should build point labels from falsy values',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, 25, 78, 20],
              },
            ],
            'labels': <Object?>[0, '', undefined, null, double.nan, false],
          },
        });

        expect(
          _r(chart).pointLabels,
          jasmineEquals(<Object?>[0, '', '', '', '', '']),
        );
      },
    );

    testWidgets(
      'Should build point labels considering hidden data',
      (tester) async {
        final chart =
            acquireChart(<String, Object?>{
                'type': 'polarArea',
                'data': <String, Object?>{
                  'datasets': <Object?>[
                    <String, Object?>{
                      'data': <Object?>[10, 5, 0, 25, 78, 20],
                    },
                  ],
                  'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
                },
              })
              ..toggleDataVisibility(3)
              ..update();

        expect(
          _r(chart).pointLabels,
          jasmineEquals(<Object?>['a', 'b', 'c', 'e', 'f']),
        );
      },
    );

    testWidgets(
      'should correctly set the center point',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{
                'pointLabels': <String, Object?>{
                  'callback': (Object? value, Object? index) =>
                      jsToString(index),
                },
              },
            },
          },
        });

        expect(_r(chart).drawingArea, 215);
        expect(_r(chart).xCenter, 256);
        expect(_r(chart).yCenter, 280);
      },
    );

    testWidgets(
      'should correctly get the label for a given data index',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{
                'pointLabels': <String, Object?>{
                  'callback': (Object? value, Object? index) =>
                      jsToString(index),
                },
              },
            },
          },
        });
        expect(chart.scales['r']!.getLabelForValue(5), '5');
      },
    );

    testWidgets(
      'should get the correct distance from the center point',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{
                'pointLabels': <String, Object?>{
                  'callback': (Object? value, Object? index) =>
                      jsToString(index),
                },
              },
            },
          },
        });

        expect(
          _r(chart).getDistanceFromCenterForValue(_r(chart).min),
          0,
        );
        expect(
          _r(chart).getDistanceFromCenterForValue(_r(chart).max),
          215,
        );

        final position = _r(chart).getPointPositionForValue(1, 5);
        expect(position.x, toBeCloseToPixel(269));
        expect(position.y, toBeCloseToPixel(276));

        _r(chart).options['reverse'] = true;
        chart.update();

        expect(
          _r(chart).getDistanceFromCenterForValue(_r(chart).min),
          215,
        );
        expect(
          _r(chart).getDistanceFromCenterForValue(_r(chart).max),
          0,
        );
      },
    );

    testWidgets(
      'should get the correct value for a distance from the center point',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{
                'pointLabels': <String, Object?>{
                  'callback': (Object? value, Object? index) =>
                      jsToString(index),
                },
              },
            },
          },
        });

        expect(_r(chart).getValueForDistanceFromCenter(0), _r(chart).min);
        expect(_r(chart).getValueForDistanceFromCenter(215), _r(chart).max);

        final dist = _r(chart).getDistanceFromCenterForValue(5);
        expect(_r(chart).getValueForDistanceFromCenter(dist), 5);

        _r(chart).options['reverse'] = true;
        chart.update();

        expect(_r(chart).getValueForDistanceFromCenter(0), _r(chart).max);
        expect(_r(chart).getValueForDistanceFromCenter(215), _r(chart).min);
      },
    );

    testWidgets(
      'should correctly get angles for all points',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{
                'startAngle': 15,
                'pointLabels': <String, Object?>{
                  'callback': (Object? value, Object? index) =>
                      jsToString(index),
                },
              },
            },
          },
        });

        double radToNearestDegree(double rad) {
          return jsRound((360 * rad) / (2 * math.pi));
        }

        const slice = 72; // (360 / 5)

        for (var i = 0; i < 5; i++) {
          expect(
            radToNearestDegree(_r(chart).getIndexAngle(i.toDouble())),
            15 + (slice * i),
          );
        }

        _r(chart).options['startAngle'] = 0;
        chart.update();

        for (var x = 0; x < 5; x++) {
          expect(
            radToNearestDegree(_r(chart).getIndexAngle(x.toDouble())),
            slice * x,
          );
        }
      },
    );

    testWidgets(
      'should correctly get the correct label alignment for all points',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{
                'pointLabels': <String, Object?>{
                  'callback': (Object? value, Object? index) =>
                      jsToString(index),
                },
                'ticks': <String, Object?>{'display': false},
              },
            },
          },
        });

        final scale = chart.scales['r']!;

        for (final expected in <Map<String, Object?>>[
          <String, Object?>{
            'startAngle': 30,
            'textAlign': <Object?>['right', 'right', 'left', 'left', 'left'],
          },
          <String, Object?>{
            'startAngle': -30,
            'textAlign': <Object?>['right', 'right', 'left', 'left', 'right'],
          },
          <String, Object?>{
            'startAngle': 750,
            'textAlign': <Object?>['right', 'right', 'left', 'left', 'left'],
          },
        ]) {
          scale.options['startAngle'] = expected['startAngle'];
          chart.update();

          final ctx = createMockContext();
          scale.ctx = ctx;
          chart.draw();

          final calls = ctx
              .getCalls()
              .where((x) => x['name'] == 'setTextAlign')
              .toList();
          for (var i = 0; i < calls.length; i++) {
            expect(
              (calls[i]['args']! as List<Object?>)[0],
              (expected['textAlign']! as List<Object?>)[i],
              reason:
                  'startAngle: ${jsToString(expected['startAngle'])}, '
                  'tick: ${jsToString(i)}',
            );
          }
        }
      },
    );

    testWidgets(
      'should correctly get the point positions in center',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'polarArea',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>[
              'label1',
              'label2',
              'label3',
              'label4',
              'label5',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{
                'pointLabels': <String, Object?>{
                  'display': true,
                  'padding': 5,
                  'centerPointLabels': true,
                },
                'ticks': <String, Object?>{'display': false},
              },
            },
          },
        });

        const pi = math.pi;
        const lavelNum = 5;
        const padding = 5;
        final pointLabelItems = _r(chart).pointLabelItems;
        const additionalAngle = pi / lavelNum;
        final opts = _r(chart).options;
        final outerDistance = _r(chart).getDistanceFromCenterForValue(
          jsTruthy(jsGet(opts['ticks'], 'reverse'))
              ? _r(chart).min
              : _r(chart).max,
        );
        const tickBackdropHeight = 0;
        // The parameter `y` of upstream is the local `result`.
        double yForAngle(double y, double h, double angle) {
          var result = y;
          if (angle == 90 || angle == 270) {
            result -= h / 2;
          } else if (angle > 270 || angle < 90) {
            result -= h;
          }
          return result;
        }

        double toDegrees(double radians) {
          return radians * (180 / pi);
        }

        for (var i = 0; i < 5; i++) {
          final extra = i == 0 ? tickBackdropHeight / 2 : 0;
          final pointLabelItem = pointLabelItems[i];
          final pointPosition = _r(chart).getPointPosition(
            i.toDouble(),
            outerDistance + extra + padding,
            additionalAngle,
          );
          expect(pointLabelItem.x, pointPosition.x);
          expect(
            pointLabelItem.y,
            yForAngle(
              pointPosition.y,
              12,
              toDegrees(pointPosition.angle + pi / 2),
            ),
          );
        }
      },
    );
  });
}
