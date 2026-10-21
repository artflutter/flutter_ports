// Ported from Chart.js v4.5.1+7169e651 test/specs/core.layouts.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs, which does not export lib/src
// yet.
import 'package:flutter_chartjs/src/core/core.layouts.dart';
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// The spec reads Chart.layouts, which src/index.umd.ts sets to the default
// export of core.layouts.js. Here it is the record `layouts` of
// lib/src/core/core.layouts.dart. The chart cases read the boxes of a chart
// with scales, a legend or a title. A case that needs the legend skips with
// `blocked: plugin.legend`. A chart case is a `testWidgets` case, and the
// file runs on the VM (Chart.js ADR 0030, section 12 item 5). It does not
// call `setUpSpecs()`: its charts need the built-in components.
// test/port/core/core.layouts_test.dart covers the layout with fake boxes,
// also in the web legs.
//
// The spec forms:
// - `chart.scales.x` is `chart.scales['x']!`. `chart.chartArea` is
//   `chart.chartArea!`.
// - `expect(a < b && b < c).toBe(true)` keeps the boolean expression.

/// core.layouts.tests.js:1-3 `getLabels(scale)`.
List<Object?> _getLabels(Scale scale) => [
  for (final t in scale.ticks!) t.label,
];

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

    test(
      'should fit a simple chart with 2 scales',
      () {},
      skip: 'blocked: plugin.legend',
    );

    test(
      'should fit scales that are in the top and right positions',
      () {},
      skip: 'blocked: plugin.legend',
    );

    test(
      'should fit scales that overlap the chart area',
      () {},
      skip: 'blocked: plugin.legend',
    );

    test(
      'should fit multiple axes in the same position',
      () {},
      skip: 'blocked: plugin.legend',
    );

    test(
      'should fit a full width box correctly',
      () {},
      skip: 'blocked: plugin.legend',
    );

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
      test(
        'should keep higher weights outside',
        () {},
        skip: 'blocked: plugin.legend',
      );

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
