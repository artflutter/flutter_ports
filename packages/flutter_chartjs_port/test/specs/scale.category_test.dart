// Ported from Chart.js v4.5.1+7169e651 test/specs/scale.category.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// The spec reads Chart.registry and Chart.defaults, the static members
// `Chart.registry` and `Chart.defaults` of core.controller.dart. The
// harness registers the built-in scales before `main()`
// (`harness-register-builtins`). Thus `registry.getScale('category')` gives
// the class value `CategoryScale.jsClass`.
//
// Each chart case of the spec makes a line or a bar chart. Thus it needs a
// controller of phase 7, and it is a `testWidgets` case that calls
// `acquireChart` in its body (Chart.js ADR 0022, sections 1 and 2). The
// file runs on the VM. A case that needs a module of a later phase skips
// with the missing module of the latest phase. The cases that read a pixel
// of a vertical category axis (:287, :330, :406 and :479) also need the
// legend of phase 8: the legend changes the top of the chart area. The
// other cases give the same values without the legend.
//
// Two cases give a label string to `getPixelForValue` (Chart.js ADR 0025,
// scale.category.tests.js:247 and :534).
//
// The spec forms:
// - `chart.scales.x` is `chart.scales['x']!`.
// - A property chain of the spec, for example
//   `Chart.defaults.scales.category`, is a chain of `jsGet`.
// - `typeof Constructor` is `jsTypeof(constructor)`. `not.toBe(undefined)`
//   is `isNot(same(undefined))`.
// - `toEqual` of an object compares the keys and values. Jasmine compares
//   functions by identity. A `JsFunction` has the identity equality of
//   Dart.
// - `toEqual` of a number is `jasmineEquals`: Jasmine `eq` makes `0` and
//   `-0` different, and Dart `==` makes them equal.
// - `toBeLessThan` and `toBeGreaterThan` are `lessThan` and `greaterThan`.
// - `xScale.options.offset = true` writes through the resolver of the scale
//   options: `xScale.options['offset'] = true`.
// - `chart.options.scales.x.bounds = 'ticks'` writes into the resolver of
//   the last read of the chain.

/// scale.category.tests.js:1-3 `getLabels(scale)`.
List<Object?> _getLabels(Scale scale) => [
  for (final t in scale.ticks!) t.label,
];

void main() {
  group('Category scale tests', () {
    group('auto', fixture.specs('scale.category'));

    test('Should register the constructor with the registry', () {
      final constructor = Chart.registry.getScale('category');
      expect(constructor, isNot(same(undefined)));
      expect(jsTypeof(constructor), 'function');
    });

    test('Should have the correct default config', () {
      final defaultConfig = jsGet(jsGet(Chart.defaults, 'scales'), 'category');
      expect(
        defaultConfig,
        equals(<String, Object?>{
          'ticks': <String, Object?>{
            'callback': jsGet(
              jsGet(
                jsGet(Chart.registry.getScale('category'), 'defaults'),
                'ticks',
              ),
              'callback',
            ),
          },
        }),
      );
    });

    testWidgets('Should generate ticks from the data xLabels', (tester) async {
      final labels = <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'];
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'xLabels': labels,
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 5, 0, 25, 78],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category'},
          },
        },
      });

      final scale = chart.scales['x']!;
      expect(_getLabels(scale), jasmineEquals(labels));
    });

    testWidgets('Should generate ticks from the data yLabels', (tester) async {
      final labels = <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'];
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'yLabels': labels,
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 5, 0, 25, 78],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{'type': 'category'},
          },
        },
      });

      final scale = chart.scales['y']!;
      expect(_getLabels(scale), jasmineEquals(labels));
    });

    testWidgets('Should generate ticks from the axis labels', (tester) async {
      final labels = <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'];
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 5, 0, 25, 78],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category', 'labels': labels},
          },
        },
      });

      final scale = chart.scales['x']!;
      expect(_getLabels(scale), jasmineEquals(labels));
    });

    testWidgets('Should generate missing labels', (tester) async {
      final labels = <Object?>['a', 'b', 'c', 'd'];
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <String, Object?>{'a': 1, 'b': 3, 'c': -1, 'd': 10},
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'category',
              'labels': <Object?>['a'],
            },
          },
        },
      });

      final scale = chart.scales['x']!;
      expect(_getLabels(scale), jasmineEquals(labels));
    });

    testWidgets('should parse only to a valid index', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'xAxisID': 'x',
              'yAxisID': 'y',
              'data': <Object?>[10, 5, 0, 25, 78],
            },
          ],
          'labels': <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category', 'position': 'bottom'},
            'y': <String, Object?>{'type': 'linear'},
          },
        },
      });

      final scale = chart.scales['x']!;

      expect(scale.parse(-10), jasmineEquals(0));
      expect(scale.parse(-0.1), jasmineEquals(0));
      expect(scale.parse(4.1), jasmineEquals(4));
      expect(scale.parse(5), jasmineEquals(4));
      expect(scale.parse(1), jasmineEquals(1));
      expect(scale.parse(1.4), jasmineEquals(1));
      expect(scale.parse(1.5), jasmineEquals(2));
      expect(scale.parse('tick2'), jasmineEquals(1));
    });

    testWidgets('should get the correct label for the index', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'xAxisID': 'x',
              'yAxisID': 'y',
              'data': <Object?>[10, 5, 0, 25, 78],
            },
          ],
          'labels': <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category', 'position': 'bottom'},
            'y': <String, Object?>{'type': 'linear'},
          },
        },
      });

      final scale = chart.scales['x']!;

      expect(scale.getLabelForValue(1), 'tick2');
    });

    testWidgets(
      'Should get the correct pixel for a value when horizontal',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'xAxisID': 'x',
                'yAxisID': 'y',
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>[
              'tick1',
              'tick2',
              'tick3',
              'tick4',
              'tick_last',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'category', 'position': 'bottom'},
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        });

        final xScale = chart.scales['x']!;
        expect(
          xScale.getPixelForValue(0),
          toBeCloseToPixel(23 + 6), // plus lineHeight
        );
        expect(xScale.getValueForPixel(23), 0);

        expect(xScale.getPixelForValue(4), toBeCloseToPixel(487));
        expect(xScale.getValueForPixel(487), 4);

        xScale.options['offset'] = true;
        chart.update();

        expect(
          xScale.getPixelForValue(0),
          toBeCloseToPixel(71 + 6), // plus lineHeight
        );
        expect(xScale.getValueForPixel(69), 0);

        expect(xScale.getPixelForValue(4), toBeCloseToPixel(461));
        expect(xScale.getValueForPixel(417), 4);
      },
    );

    testWidgets(
      'Should get the correct pixel for a value when there are repeated '
      'labels',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'xAxisID': 'x',
                'yAxisID': 'y',
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>[
              'tick1',
              'tick2',
              'tick3',
              'tick4',
              'tick_last',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'category', 'position': 'bottom'},
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        });

        final xScale = chart.scales['x']!;
        expect(
          xScale.getPixelForValue('tick1'),
          toBeCloseToPixel(23 + 6), // plus lineHeight
        );
      },
    );

    testWidgets(
      'Should get the correct pixel for a value when horizontal and zoomed',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'xAxisID': 'x',
                'yAxisID': 'y',
                'data': <Object?>[10, 5, 0, 25, 78],
              },
            ],
            'labels': <Object?>[
              'tick1',
              'tick2',
              'tick3',
              'tick4',
              'tick_last',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'category',
                'position': 'bottom',
                'min': 'tick2',
                'max': 'tick4',
              },
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        });

        final xScale = chart.scales['x']!;
        expect(
          xScale.getPixelForValue(1),
          toBeCloseToPixel(23 + 6), // plus lineHeight
        );
        expect(xScale.getPixelForValue(3), toBeCloseToPixel(496));

        xScale.options['offset'] = true;
        chart.update();

        expect(
          xScale.getPixelForValue(1),
          toBeCloseToPixel(103 + 6), // plus lineHeight
        );
        expect(xScale.getPixelForValue(3), toBeCloseToPixel(429));
      },
    );

    test(
      'should get the correct pixel for a value when vertical',
      () {},
      skip: 'blocked: plugin.legend',
    );

    test(
      'should get the correct pixel for a value when vertical and zoomed',
      () {},
      skip: 'blocked: plugin.legend',
    );

    testWidgets(
      'Should get the correct pixel for an object value when horizontal',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'xAxisID': 'x',
                'yAxisID': 'y',
                'data': <Object?>[
                  <String, Object?>{'x': 0, 'y': 10},
                  <String, Object?>{'x': 1, 'y': 5},
                  <String, Object?>{'x': 2, 'y': 0},
                  <String, Object?>{'x': 3, 'y': 25},
                  <String, Object?>{'x': 0, 'y': 78},
                ],
              },
            ],
            'labels': <Object?>[0, 1, 2, 3],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'category', 'position': 'bottom'},
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        });

        final xScale = chart.scales['x']!;
        expect(xScale.getPixelForValue(0), toBeCloseToPixel(29));
        expect(xScale.getPixelForValue(3), toBeCloseToPixel(506));
        expect(xScale.getPixelForValue(4), toBeCloseToPixel(664));
      },
    );

    test(
      'Should get the correct pixel for an object value when vertical',
      () {},
      skip: 'blocked: plugin.legend',
    );

    testWidgets(
      'Should get the correct pixel for an object value in a bar chart',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'xAxisID': 'x',
                'yAxisID': 'y',
                'data': <Object?>[
                  <String, Object?>{'x': 0, 'y': 10},
                  <String, Object?>{'x': 1, 'y': 5},
                  <String, Object?>{'x': 2, 'y': 0},
                  <String, Object?>{'x': 3, 'y': 25},
                  <String, Object?>{'x': 0, 'y': 78},
                ],
              },
            ],
            'labels': <Object?>[0, 1, 2, 3],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'category', 'position': 'bottom'},
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        });

        final xScale = chart.scales['x']!;
        expect(xScale.getPixelForValue(0), toBeCloseToPixel(89));
        expect(xScale.getPixelForValue(3), toBeCloseToPixel(451));
        expect(xScale.getPixelForValue(4), toBeCloseToPixel(572));
      },
    );

    test(
      'Should get the correct pixel for an object value in a horizontal bar '
      'chart',
      () {},
      skip: 'blocked: plugin.legend',
    );

    testWidgets(
      'Should be consistent on pixels and values with autoSkipped ticks',
      (tester) async {
        final labels = <Object?>[];
        for (var i = 0; i < 50; i++) {
          labels.add('very long label $i');
        }
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'labels': labels,
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
              },
            ],
          },
        });

        final scale = chart.scales['x']!;
        expect(scale.ticks!.length, lessThan(50));

        var x = 0.0;
        for (var i = 0; i < 50; i++) {
          final x2 = scale.getPixelForValue(labels[i]);
          final x3 = scale.getPixelForValue(i);
          expect(x2, jasmineEquals(x3));
          expect(x2, greaterThan(x));
          expect(scale.getValueForPixel(x2), i);
          x = x2;
        }
      },
    );

    testWidgets('Should bound to ticks/data', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b', 'c', 'd'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <String, Object?>{'b': 1, 'c': 99},
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category', 'bounds': 'data'},
          },
        },
      });

      expect(chart.scales['x']!.min, jasmineEquals(1));
      expect(chart.scales['x']!.max, jasmineEquals(2));

      (jsGet(jsGet(chart.options, 'scales'), 'x')! as AnyObject)['bounds'] =
          'ticks';
      chart.update();

      expect(chart.scales['x']!.min, jasmineEquals(0));
      expect(chart.scales['x']!.max, jasmineEquals(3));
    });
  });
}
