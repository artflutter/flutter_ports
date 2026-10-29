// Ported from Chart.js v4.6.1 test/specs/platform.basic.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/platform/platform.basic.dart';
import 'package:flutter_test/flutter_test.dart';

// Each case creates a chart with `acquireChart`. Thus each one is a
// `testWidgets` case, and the file runs on the VM (Chart.js ADR 0022,
// sections 1 and 2). `useOffscreenCanvas: true` gives the chart the context
// of a canvas that no chart host shows. `detectPlatform` then gives
// BasicPlatform, as `platform/index.js:7` does for an `OffscreenCanvas`
// (row `harness-acquire-chart`). `toBeInstanceOf(Chart.platforms.
// BasicPlatform)` is `isA<BasicPlatform>()`. test/port/platform/ tests
// BasicPlatform without a chart.
//
// The two cases of `with offscreenCanvas` also need the legend, which
// flutter_test_config.dart registers: the legend changes the top of the
// chart area. `const canvasElement = chart.canvas` and the two writes are
// a cascade on `chart.canvas!`, the offscreen canvas of the chart. The
// `resize` of the chart reads its size in `getMaximumSize` of BasicPlatform
// (core.controller.js:281, platform.base.js:59-65).

void main() {
  group('Platform.basic', () {
    testWidgets(
      'should automatically choose the BasicPlatform for offscreen canvas',
      (tester) async {
        final chart = acquireChart(
          {'type': 'line'},
          {'useOffscreenCanvas': true},
        );

        expect(chart.platform, isA<BasicPlatform>());

        chart.destroy();
      },
    );

    testWidgets('should disable animations', (tester) async {
      final chart = acquireChart(
        {
          'type': 'line',
          'options': <String, Object?>{'animation': <String, Object?>{}},
        },
        {'useOffscreenCanvas': true},
      );

      expect(chart.options['animation'], false);

      chart.destroy();
    });

    test(
      'supports choosing the BasicPlatform in a web worker',
      () {},
      skip: 'n/a: Flutter has no web worker and no transferControlToOffscreen',
    );

    group('with offscreenCanvas', () {
      testWidgets('supports laying out a simple chart', (tester) async {
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
            'useOffscreenCanvas': true,
          },
        );

        expect(chart.platform, isA<BasicPlatform>());

        expect(chart.chartArea!.bottom, toBeCloseToPixel(120));
        expect(chart.chartArea!.left, toBeCloseToPixel(31));
        expect(chart.chartArea!.right, toBeCloseToPixel(250));
        expect(chart.chartArea!.top, toBeCloseToPixel(32));
      });

      testWidgets('supports resizing a chart', (tester) async {
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
            'useOffscreenCanvas': true,
          },
        );

        expect(chart.platform, isA<BasicPlatform>());

        chart.canvas!
          ..height = 200
          ..width = 300;
        chart.resize();

        expect(chart.chartArea!.bottom, toBeCloseToPixel(150));
        expect(chart.chartArea!.left, toBeCloseToPixel(31));
        expect(chart.chartArea!.right, toBeCloseToPixel(300));
        expect(chart.chartArea!.top, toBeCloseToPixel(32));
      });
    });
  });
}
