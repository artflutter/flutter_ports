// Ported from Chart.js v4.6.1 test/specs/core.layouts.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.layouts.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/types/layout.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// The spec reads Chart.layouts, which src/index.umd.ts sets to the default
// export of core.layouts.js. Here it is the record `layouts` of
// lib/src/core/core.layouts.dart. The chart cases read the boxes of a chart
// with scales, a legend or a title. flutter_test_config.dart registers the
// legend and the title with the other built-in components. A chart case is a
// `testWidgets` case, and the file runs on the VM (Chart.js ADR 0030,
// section 12 item 5). It does not call `setUpSpecs()`: its charts need the
// built-in components.
// test/port/core/core.layouts_test.dart covers the layout with fake boxes,
// also in the web legs.
//
// The spec forms:
// - `chart.scales.x` is `chart.scales['x']!`. `chart.chartArea` is
//   `chart.chartArea!`.
// - `expect(a < b && b < c).toBe(true)` keeps the boolean expression.
// - `toBeCloseTo` is `_toBeCloseTo`.
// - `chart.legend` and `chart.titleBlock` are layout boxes: `legend.right`
//   reads the member of `LayoutItem` (index.d.ts:2414, `LegendElement`
//   extends `LayoutItem`).

/// core.layouts.tests.js:1-3 `getLabels(scale)`.
List<Object?> _getLabels(Scale scale) => [
  for (final t in scale.ticks!) t.label,
];

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

void main() {
  group('Chart.layouts', () {
    group('auto', fixture.specs('core.layouts'));

    test('should be exposed through Chart.layouts', () {
      expect(layouts, isNotNull);
      // `typeof Chart.layouts` is 'object': the export is a record.
      expect(layouts, isA<Record>());
      expect(layouts.addBox, isNotNull);
      expect(layouts.removeBox, isNotNull);
      expect(layouts.configure, isNotNull);
      expect(layouts.update, isNotNull);
    });

    testWidgets('should fit a simple chart with 2 scales', (tester) async {
      final chart = acquireChart(
        <String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, 25, 78, -10],
              },
            ],
            'labels': <Object?>[
              'tick1',
              'tick2',
              'tick3',
              'tick4',
              'tick5',
              'tick6',
            ],
          },
        },
        <String, Object?>{
          'canvas': <String, Object?>{'height': 150, 'width': 250},
        },
      );

      expect(chart.chartArea!.bottom, toBeCloseToPixel(120));
      expect(chart.chartArea!.left, toBeCloseToPixel(31));
      expect(chart.chartArea!.right, toBeCloseToPixel(250));
      expect(chart.chartArea!.top, toBeCloseToPixel(32));

      // Is xScale at the right spot
      expect(chart.scales['x']!.bottom, toBeCloseToPixel(150));
      expect(chart.scales['x']!.left, toBeCloseToPixel(31));
      expect(chart.scales['x']!.right, toBeCloseToPixel(250));
      expect(chart.scales['x']!.top, toBeCloseToPixel(120));
      expect(chart.scales['x']!.labelRotation, _toBeCloseTo(0));

      // Is yScale at the right spot
      expect(chart.scales['y']!.bottom, toBeCloseToPixel(120));
      expect(chart.scales['y']!.left, toBeCloseToPixel(0));
      expect(chart.scales['y']!.right, toBeCloseToPixel(31));
      expect(chart.scales['y']!.top, toBeCloseToPixel(32));
      expect(chart.scales['y']!.labelRotation, _toBeCloseTo(0));
    });

    testWidgets('should fit scales that are in the top and right positions', (
      tester,
    ) async {
      final chart = acquireChart(
        <String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 5, 0, 25, 78, -10],
              },
            ],
            'labels': <Object?>[
              'tick1',
              'tick2',
              'tick3',
              'tick4',
              'tick5',
              'tick6',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'category', 'position': 'top'},
              'y': <String, Object?>{'type': 'linear', 'position': 'right'},
            },
          },
        },
        <String, Object?>{
          'canvas': <String, Object?>{'height': 150, 'width': 250},
        },
      );

      expect(chart.chartArea!.bottom, toBeCloseToPixel(139));
      expect(chart.chartArea!.left, toBeCloseToPixel(0));
      expect(chart.chartArea!.right, toBeCloseToPixel(218));
      expect(chart.chartArea!.top, toBeCloseToPixel(62));

      // Is xScale at the right spot
      expect(chart.scales['x']!.bottom, toBeCloseToPixel(62));
      expect(chart.scales['x']!.left, toBeCloseToPixel(0));
      expect(chart.scales['x']!.right, toBeCloseToPixel(218));
      expect(chart.scales['x']!.top, toBeCloseToPixel(32));
      expect(chart.scales['x']!.labelRotation, _toBeCloseTo(0));

      // Is yScale at the right spot
      expect(chart.scales['y']!.bottom, toBeCloseToPixel(139));
      expect(chart.scales['y']!.left, toBeCloseToPixel(218));
      expect(chart.scales['y']!.right, toBeCloseToPixel(250));
      expect(chart.scales['y']!.top, toBeCloseToPixel(62));
      expect(chart.scales['y']!.labelRotation, _toBeCloseTo(0));
    });

    testWidgets('should fit scales that overlap the chart area', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'radar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 5, 0, 25, 78, -10],
            },
            <String, Object?>{
              'data': <Object?>[-19, -20, 0, -99, -50, 0],
            },
          ],
          'labels': <Object?>[
            'tick1',
            'tick2',
            'tick3',
            'tick4',
            'tick5',
            'tick6',
          ],
        },
      });

      expect(chart.chartArea!.bottom, toBeCloseToPixel(512));
      expect(chart.chartArea!.left, toBeCloseToPixel(0));
      expect(chart.chartArea!.right, toBeCloseToPixel(512));
      expect(chart.chartArea!.top, toBeCloseToPixel(32));

      final scale = chart.scales['r']!;
      expect(scale.bottom, toBeCloseToPixel(512));
      expect(scale.left, toBeCloseToPixel(0));
      expect(scale.right, toBeCloseToPixel(512));
      expect(scale.top, toBeCloseToPixel(32));
      expect(scale.width, toBeCloseToPixel(496));
      expect(scale.height, toBeCloseToPixel(464));
    });

    testWidgets('should fit multiple axes in the same position', (
      tester,
    ) async {
      final chart = acquireChart(
        <String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'yAxisID': 'y',
                'data': <Object?>[10, 5, 0, 25, 78, -10],
              },
              <String, Object?>{
                'yAxisID': 'y2',
                'data': <Object?>[-19, -20, 0, -99, -50, 0],
              },
            ],
            'labels': <Object?>[
              'tick1',
              'tick2',
              'tick3',
              'tick4',
              'tick5',
              'tick6',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'category'},
              'y': <String, Object?>{'type': 'linear'},
              'y2': <String, Object?>{'type': 'linear'},
            },
          },
        },
        <String, Object?>{
          'canvas': <String, Object?>{'height': 150, 'width': 250},
        },
      );

      expect(chart.chartArea!.bottom, toBeCloseToPixel(110));
      expect(chart.chartArea!.left, toBeCloseToPixel(70));
      expect(chart.chartArea!.right, toBeCloseToPixel(250));
      expect(chart.chartArea!.top, toBeCloseToPixel(32));

      // Is xScale at the right spot
      expect(chart.scales['x']!.bottom, toBeCloseToPixel(150));
      expect(chart.scales['x']!.left, toBeCloseToPixel(70));
      expect(chart.scales['x']!.right, toBeCloseToPixel(250));
      expect(chart.scales['x']!.top, toBeCloseToPixel(110));
      expect(chart.scales['x']!.labelRotation, _toBeCloseTo(40, -1));

      // Are yScales at the right spot
      expect(chart.scales['y']!.bottom, toBeCloseToPixel(110));
      expect(chart.scales['y']!.left, toBeCloseToPixel(38));
      expect(chart.scales['y']!.right, toBeCloseToPixel(70));
      expect(chart.scales['y']!.top, toBeCloseToPixel(32));
      expect(chart.scales['y']!.labelRotation, _toBeCloseTo(0));

      expect(chart.scales['y2']!.bottom, toBeCloseToPixel(110));
      expect(chart.scales['y2']!.left, toBeCloseToPixel(0));
      expect(chart.scales['y2']!.right, toBeCloseToPixel(38));
      expect(chart.scales['y2']!.top, toBeCloseToPixel(32));
      expect(chart.scales['y2']!.labelRotation, _toBeCloseTo(0));
    });

    testWidgets('should fit a full width box correctly', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'xAxisID': 'x',
              'data': <Object?>[10, 5, 0, 25, 78, -10],
            },
            <String, Object?>{
              'xAxisID': 'x2',
              'data': <Object?>[-19, -20, 0, -99, -50, 0],
            },
          ],
          'labels': <Object?>[
            'tick1',
            'tick2',
            'tick3',
            'tick4',
            'tick5',
            'tick6',
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category', 'offset': false},
            'x2': <String, Object?>{
              'type': 'category',
              'position': 'top',
              'fullSize': true,
              'offset': false,
            },
            'y': <String, Object?>{'type': 'linear'},
          },
        },
      });

      expect(chart.chartArea!.bottom, toBeCloseToPixel(484));
      expect(chart.chartArea!.left, toBeCloseToPixel(39));
      expect(chart.chartArea!.right, toBeCloseToPixel(496));
      expect(chart.chartArea!.top, toBeCloseToPixel(62));

      // Are xScales at the right spot
      expect(chart.scales['x']!.bottom, toBeCloseToPixel(512));
      expect(chart.scales['x']!.left, toBeCloseToPixel(39));
      expect(chart.scales['x']!.right, toBeCloseToPixel(496));
      expect(chart.scales['x']!.top, toBeCloseToPixel(484));

      expect(chart.scales['x2']!.bottom, toBeCloseToPixel(62));
      expect(chart.scales['x2']!.left, toBeCloseToPixel(0));
      expect(chart.scales['x2']!.right, toBeCloseToPixel(512));
      expect(chart.scales['x2']!.top, toBeCloseToPixel(32));

      // Is yScale at the right spot
      expect(chart.scales['y']!.bottom, toBeCloseToPixel(484));
      expect(chart.scales['y']!.left, toBeCloseToPixel(0));
      expect(chart.scales['y']!.right, toBeCloseToPixel(39));
      expect(chart.scales['y']!.top, toBeCloseToPixel(62));
    });

    group('padding settings', () {
      testWidgets('should apply a single padding to all dimensions', (
        tester,
      ) async {
        final chart = acquireChart(
          <String, Object?>{
            'type': 'bar',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[10, 5, 0, 25, 78, -10],
                },
              ],
              'labels': <Object?>[
                'tick1',
                'tick2',
                'tick3',
                'tick4',
                'tick5',
                'tick6',
              ],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{'type': 'category', 'display': false},
                'y': <String, Object?>{'type': 'linear', 'display': false},
              },
              'plugins': <String, Object?>{'legend': false, 'title': false},
              'layout': <String, Object?>{
                'padding': 10,
              },
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'height': 150, 'width': 250},
          },
        );

        expect(chart.chartArea!.bottom, toBeCloseToPixel(140));
        expect(chart.chartArea!.left, toBeCloseToPixel(10));
        expect(chart.chartArea!.right, toBeCloseToPixel(240));
        expect(chart.chartArea!.top, toBeCloseToPixel(10));
      });

      testWidgets('should apply padding in all positions', (tester) async {
        final chart = acquireChart(
          <String, Object?>{
            'type': 'bar',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[10, 5, 0, 25, 78, -10],
                },
              ],
              'labels': <Object?>[
                'tick1',
                'tick2',
                'tick3',
                'tick4',
                'tick5',
                'tick6',
              ],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{'type': 'category', 'display': false},
                'y': <String, Object?>{'type': 'linear', 'display': false},
              },
              'plugins': <String, Object?>{'legend': false, 'title': false},
              'layout': <String, Object?>{
                'padding': <String, Object?>{
                  'left': 5,
                  'right': 15,
                  'top': 8,
                  'bottom': 12,
                },
              },
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'height': 150, 'width': 250},
          },
        );

        expect(chart.chartArea!.bottom, toBeCloseToPixel(138));
        expect(chart.chartArea!.left, toBeCloseToPixel(5));
        expect(chart.chartArea!.right, toBeCloseToPixel(235));
        expect(chart.chartArea!.top, toBeCloseToPixel(8));
      });

      testWidgets('should default to 0 padding if no dimensions specified', (
        tester,
      ) async {
        final chart = acquireChart(
          <String, Object?>{
            'type': 'bar',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[10, 5, 0, 25, 78, -10],
                },
              ],
              'labels': <Object?>[
                'tick1',
                'tick2',
                'tick3',
                'tick4',
                'tick5',
                'tick6',
              ],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{'type': 'category', 'display': false},
                'y': <String, Object?>{'type': 'linear', 'display': false},
              },
              'plugins': <String, Object?>{'legend': false, 'title': false},
              'layout': <String, Object?>{
                'padding': <String, Object?>{},
              },
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'height': 150, 'width': 250},
          },
        );

        expect(chart.chartArea!.bottom, toBeCloseToPixel(150));
        expect(chart.chartArea!.left, toBeCloseToPixel(0));
        expect(chart.chartArea!.right, toBeCloseToPixel(250));
        expect(chart.chartArea!.top, toBeCloseToPixel(0));
      });
    });

    group('ordering by weight', () {
      testWidgets('should keep higher weights outside', (tester) async {
        final chart = acquireChart(
          <String, Object?>{
            'type': 'bar',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[10, 5, 0, 25, 78, -10],
                },
              ],
              'labels': <Object?>[
                'tick1',
                'tick2',
                'tick3',
                'tick4',
                'tick5',
                'tick6',
              ],
            },
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'legend': <String, Object?>{
                  'display': true,
                  'position': 'left',
                },
                'title': <String, Object?>{
                  'display': true,
                  'position': 'bottom',
                },
              },
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'height': 150, 'width': 250},
          },
        );

        final xAxis = chart.scales['x']!;
        final yAxis = chart.scales['y']!;
        final legend = chart.legend! as LayoutItem;
        final title = chart.titleBlock!;

        expect(yAxis.left, legend.right);
        expect(xAxis.bottom, title.top);
      });

      testWidgets('should correctly set weights of scales and order them', (
        tester,
      ) async {
        final chart = acquireChart(
          <String, Object?>{
            'type': 'bar',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[10, 5, 0, 25, 78, -10],
                },
              ],
              'labels': <Object?>[
                'tick1',
                'tick2',
                'tick3',
                'tick4',
                'tick5',
                'tick6',
              ],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{
                  'type': 'category',
                  'position': 'bottom',
                  'display': true,
                  'weight': 1,
                },
                'x1': <String, Object?>{
                  'type': 'category',
                  'position': 'bottom',
                  'display': true,
                  'weight': 2,
                },
                'x2': <String, Object?>{
                  'type': 'category',
                  'position': 'bottom',
                  'display': true,
                },
                'x3': <String, Object?>{
                  'type': 'category',
                  'display': true,
                  'position': 'top',
                  'weight': 1,
                },
                'x4': <String, Object?>{
                  'type': 'category',
                  'display': true,
                  'position': 'top',
                  'weight': 2,
                },
                'y': <String, Object?>{
                  'type': 'linear',
                  'display': true,
                  'weight': 1,
                },
                'y1': <String, Object?>{
                  'type': 'linear',
                  'position': 'left',
                  'display': true,
                  'weight': 2,
                },
                'y2': <String, Object?>{
                  'type': 'linear',
                  'position': 'left',
                  'display': true,
                },
                'y3': <String, Object?>{
                  'type': 'linear',
                  'display': true,
                  'position': 'right',
                  'weight': 1,
                },
                'y4': <String, Object?>{
                  'type': 'linear',
                  'display': true,
                  'position': 'right',
                  'weight': 2,
                },
              },
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'height': 150, 'width': 250},
          },
        );

        final xScale0 = chart.scales['x']!;
        final xScale1 = chart.scales['x1']!;
        final xScale2 = chart.scales['x2']!;
        final xScale3 = chart.scales['x3']!;
        final xScale4 = chart.scales['x4']!;

        final yScale0 = chart.scales['y']!;
        final yScale1 = chart.scales['y1']!;
        final yScale2 = chart.scales['y2']!;
        final yScale3 = chart.scales['y3']!;
        final yScale4 = chart.scales['y4']!;

        expect(xScale0.weight, 1);
        expect(xScale1.weight, 2);
        expect(xScale2.weight, 0);

        expect(xScale3.weight, 1);
        expect(xScale4.weight, 2);

        expect(yScale0.weight, 1);
        expect(yScale1.weight, 2);
        expect(yScale2.weight, 0);

        expect(yScale3.weight, 1);
        expect(yScale4.weight, 2);

        var isOrderCorrect = false;

        // bottom axes
        isOrderCorrect = xScale2.top < xScale0.top && xScale0.top < xScale1.top;
        expect(isOrderCorrect, true);

        // top axes
        isOrderCorrect = xScale4.top < xScale3.top;
        expect(isOrderCorrect, true);

        // left axes
        isOrderCorrect =
            yScale1.left < yScale0.left && yScale0.left < yScale2.left;
        expect(isOrderCorrect, true);

        // right axes
        isOrderCorrect = yScale3.left < yScale4.left;
        expect(isOrderCorrect, true);
      });
    });

    group('box sizing', () {
      testWidgets('should correctly compute y-axis width to fit labels', (
        tester,
      ) async {
        final chart = acquireChart(
          <String, Object?>{
            'type': 'bar',
            'data': <String, Object?>{
              'labels': <Object?>[
                'tick 1',
                'tick 2',
                'tick 3',
                'tick 4',
                'tick 5',
              ],
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[0, 2.25, 1.5, 1.25, 2.5],
                },
              ],
            },
            'options': <String, Object?>{
              'plugins': <String, Object?>{'legend': false},
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'height': 256, 'width': 256},
          },
        );
        final yAxis = chart.scales['y']!;

        // issue #4441: y-axis labels partially hidden.
        // minimum horizontal space required to fit labels
        expect(yAxis.width, toBeCloseToPixel(30));
        expect(
          _getLabels(yAxis),
          jasmineEquals(<Object?>['0', '0.5', '1.0', '1.5', '2.0', '2.5']),
        );
      });
    });
  });
}
