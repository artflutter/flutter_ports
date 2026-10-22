// Ported from Chart.js v4.5.1+7169e651 test/specs/platform.dom.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/platform/platform.flutter.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// platform.flutter.dart replaces platform.dom.js (Chart.js ADR 0037). Each
// case that creates a chart is a testWidgets case with the harness of
// Chart.js ADR 0022. The spec runs on the VM: a chart reaches the chart host
// and dart:ui.
//
// :1 `const DomPlatform = Chart.platforms.DomPlatform`: `FlutterPlatform`
// replaces `DomPlatform` for a canvas that a chart host shows
// (`platform-detect-host`). `Chart.platforms` of src/index.umd.ts waits for
// phase 9. `window.document.body` is `document.body` of the harness.
//
// The beforeEach of 'context acquisition' appends a canvas to the document.
// Upstream runs it in the task of the case. Thus it is a local function that
// each case calls first in its body: the canvas is in the harness body when
// the case creates the chart. Its afterEach reads no chart, and stays a
// tearDown (Chart.js ADR 0022, section 2). A chart of `Chart(canvas)` on that
// canvas gets FlutterPlatform and starts detached. The mutation checkpoint
// at the end of the task attaches it. Upstream attaches it at construction.
// The cases destroy the chart before the checkpoint, and their expectations
// do not depend on it (Chart.js ADR 0022, Consequences).
//
// The cases of DOM ids, iframes and DOM nodes have no Flutter counterpart.
// test/port/platform/platform.flutter_test.dart and chart_host_test.dart
// test the Flutter platform and the chart host without a chart.

void main() {
  group('Platform.dom', () {
    group('context acquisition', () {
      const canvasId = 'chartjs-canvas';

      void beforeEach() {
        final canvas = document.createElement<HTMLCanvasElement>('canvas')
          ..setAttribute('id', canvasId);
        document.body.appendChild(canvas);
      }

      tearDown(() {
        document.getElementById<HTMLCanvasElement>(canvasId)!.remove();
      });

      testWidgets('should use the DomPlatform by default', (tester) async {
        beforeEach();
        final chart = acquireChart(<String, Object?>{'type': 'line'});

        expect(chart.platform, isA<FlutterPlatform>());

        chart.destroy();
      });

      // see https://github.com/chartjs/Chart.js/issues/2807
      testWidgets('should gracefully handle invalid item', (tester) async {
        beforeEach();
        final chart = Chart('foobar');

        expect(chart, isNot(toBeValidChart()));

        chart.destroy();
      });

      test(
        'should accept a DOM element id',
        () {},
        skip: 'n/a: Flutter has no DOM element ids',
      );

      testWidgets('should accept a canvas element', (tester) async {
        beforeEach();
        final canvas = document.getElementById<HTMLCanvasElement>(canvasId)!;
        final chart = Chart(canvas);

        expect(chart, toBeValidChart());
        expect(chart.canvas, same(canvas));
        expect(chart.ctx, same(canvas.getContext('2d')));

        chart.destroy();
      });

      testWidgets('should accept a canvas context2D', (tester) async {
        beforeEach();
        final canvas = document.getElementById<HTMLCanvasElement>(canvasId)!;
        final context = canvas.getContext('2d');
        final chart = Chart(context);

        expect(chart, toBeValidChart());
        expect(chart.canvas, same(canvas));
        expect(chart.ctx, same(context));

        chart.destroy();
      });

      testWidgets('should accept an array containing canvas', (tester) async {
        beforeEach();
        final canvas = document.getElementById<HTMLCanvasElement>(canvasId)!;
        final chart = Chart([canvas]);

        expect(chart, toBeValidChart());
        expect(chart.canvas, same(canvas));
        expect(chart.ctx, same(canvas.getContext('2d')));

        chart.destroy();
      });

      test(
        'should accept a canvas from an iframe',
        () {},
        skip: 'n/a: Flutter has no iframes',
      );
    });

    group('config.options.aspectRatio', () {
      testWidgets(
        'should use default "global" aspect ratio for render and display '
        'sizes',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{'responsive': false},
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': 'width: 620px'},
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 620, 'dh': 310, 'rw': 620, 'rh': 310}),
          );
        },
      );

      testWidgets(
        'should use default "chart" aspect ratio for render and display sizes',
        (tester) async {
          final doughnut = jsGet(Chart.overrides, 'doughnut')! as AnyObject;
          final ratio = jsGet(doughnut, 'aspectRatio');
          doughnut['aspectRatio'] = 1;

          final chart = acquireChart(
            <String, Object?>{
              'type': 'doughnut',
              'options': <String, Object?>{'responsive': false},
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': 'width: 425px'},
            },
          );

          doughnut['aspectRatio'] = ratio;

          expect(
            chart,
            toBeChartOfSize({'dw': 425, 'dh': 425, 'rw': 425, 'rh': 425}),
          );
        },
      );

      testWidgets(
        'should use "user" aspect ratio for render and display sizes',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': false,
                'aspectRatio': 3,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': 'width: 405px'},
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 405, 'dh': 135, 'rw': 405, 'rh': 135}),
          );
        },
      );

      testWidgets('should not apply aspect ratio when height specified', (
        tester,
      ) async {
        final chart = acquireChart(
          <String, Object?>{
            'options': <String, Object?>{
              'responsive': false,
              'aspectRatio': 3,
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'style': 'width: 400px; height: 410px'},
          },
        );

        expect(
          chart,
          toBeChartOfSize({'dw': 400, 'dh': 410, 'rw': 400, 'rh': 410}),
        );
      });
    });

    group('config.options.responsive: false', () {
      testWidgets(
        'should use default canvas size for render and display sizes',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{'responsive': false},
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': ''},
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 300, 'dh': 150, 'rw': 300, 'rh': 150}),
          );
        },
      );

      testWidgets(
        'should use canvas attributes for render and display sizes',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{'responsive': false},
            },
            <String, Object?>{
              'canvas': <String, Object?>{
                'style': '',
                'width': 305,
                'height': 245,
              },
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 305, 'dh': 245, 'rw': 305, 'rh': 245}),
          );
        },
      );

      testWidgets(
        'should use canvas style for render and display sizes (if no '
        'attributes)',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{'responsive': false},
            },
            <String, Object?>{
              'canvas': <String, Object?>{
                'style': 'width: 345px; height: 125px',
              },
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 345, 'dh': 125, 'rw': 345, 'rh': 125}),
          );
        },
      );

      testWidgets(
        'should use attributes for the render size and style for the display '
        'size',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{'responsive': false},
            },
            <String, Object?>{
              'canvas': <String, Object?>{
                'style': 'width: 345px; height: 125px;',
                'width': 165,
                'height': 85,
              },
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 345, 'dh': 125, 'rw': 165, 'rh': 85}),
          );
        },
      );

      // https://github.com/chartjs/Chart.js/issues/3860
      testWidgets('should support decimal display width and/or height', (
        tester,
      ) async {
        final chart = acquireChart(
          <String, Object?>{
            'options': <String, Object?>{'responsive': false},
          },
          <String, Object?>{
            'canvas': <String, Object?>{
              'style': 'width: 345.42px; height: 125.42px;',
            },
          },
        );

        expect(
          chart,
          toBeChartOfSize({'dw': 345, 'dh': 125, 'rw': 345, 'rh': 125}),
        );
      });
    });

    group('config.options.responsive: true (maintainAspectRatio: true)', () {
      // Upstream has no `done`: the global afterEach destroys the chart
      // before its first resize, and the callback never runs. The port keeps
      // this form. test/port/core/core.controller_test.dart waits for the
      // callback (group 'the platform.dom spec cases').
      testWidgets('should fit parent using aspect ratio to calculate size', (
        tester,
      ) async {
        final chart = acquireChart(
          <String, Object?>{
            'options': <String, Object?>{
              'responsive': true,
              'maintainAspectRatio': true,
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'style': 'width: 150px; height: 245px'},
            'wrapper': <String, Object?>{
              'style': 'width: 300px; height: 350px',
            },
          },
        );

        waitForResize(chart, () {
          expect(
            chart,
            toBeChartOfSize({'dw': 214, 'dh': 350, 'rw': 214, 'rh': 350}),
          );
        });
      });
    });

    group('controller.destroy', () {
      // DIVERGES(chartjs): platform-canvas-no-shadow, no shadow attributes.
      test(
        'should reset context to default values',
        () {},
        skip: 'diverges: platform-canvas-no-shadow',
      );

      testWidgets('should restore canvas initial values', (tester) async {
        await waitForDone((done) {
          final wrapper = document.createElement<HarnessElement>('div');
          final canvas = document.createElement<HTMLCanvasElement>('canvas')
            ..setAttribute('width', '180')
            ..setAttribute('style', 'width: 512px; height: 480px');
          wrapper
            ..setAttribute(
              'style',
              'width: 450px; height: 450px; position: relative',
            )
            ..appendChild(canvas);
          document.body.appendChild(wrapper);

          final chart = Chart(canvas.getContext('2d'), <String, Object?>{
            'options': <String, Object?>{
              'responsive': true,
              'maintainAspectRatio': false,
            },
          });

          waitForResize(chart, () {
            expect(
              chart,
              toBeChartOfSize({'dw': 475, 'dh': 450, 'rw': 475, 'rh': 450}),
            );

            chart.destroy();

            expect(canvas.getAttribute('width'), '180');
            expect(canvas.getAttribute('height'), isNull);
            expect(canvas.style.width, '512px');
            expect(canvas.style.height, '480px');
            expect(canvas.style.display, '');

            wrapper.parentNode!.removeChild(wrapper);
            done();
          });
          wrapper.style.width = '475px';
        });
      });
    });

    group('event handling', () {
      testWidgets('should notify plugins about events', (tester) async {
        Object? notifiedEvent = undefined;
        final plugin = <String, Object?>{
          'afterEvent': (Object? chart, Object? args) {
            notifiedEvent = jsGet(args, 'event');
          },
        };
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 100],
              },
            ],
          },
          'options': <String, Object?>{'responsive': true},
          'plugins': <Object?>[plugin],
        });

        await triggerMouseEvent(chart, 'click', <String, Object?>{
          'x': chart.width / 2,
          'y': chart.height / 2,
        });
        // Check that notifiedEvent is correct
        expect(notifiedEvent, isNot(same(undefined)));

        // Is type correctly translated
        final event = notifiedEvent! as types.ChartEvent;
        expect(event.type, 'click');

        // Relative Position
        expect(event.x, toBeCloseToPixel(chart.width / 2));
        expect(event.y, toBeCloseToPixel(chart.height / 2));
      });
    });

    group('isAttached', () {
      test(
        'should detect detached when canvas is attached to DOM',
        () {},
        skip:
            'n/a: the spec builds a DOM tree; '
            'test/port/platform/platform.flutter_test.dart tests isAttached '
            'with a chart host',
      );
    });
  });
}
