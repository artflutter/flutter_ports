// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/zoom.wheel.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' show acquireChart, waitForDone;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show
        Mode,
        ModifierKey,
        ZoomChart,
        ZoomChartContext,
        ZoomStartContext,
        ZoomTrigger;
import 'package:flutter_chartjs_port/chartjs.dart'
    show Chart, JsObjectFace, NativeEvent, Scale;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsRound;
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart';
import '../support/jasmine.dart';

void main() {
  group('zoom with wheel', () {
    // zoom.wheel.spec.js:2 `const data = {...}`: one object for all the
    // charts of the file. The function gives a new object for each chart,
    // with the same values: a test of a CI shard does not need the charts of
    // the earlier tests of its file.
    Map<String, Object?> data() => <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 1, 'y': 3},
            <String, Object?>{'x': 2, 'y': 2},
            <String, Object?>{'x': 3, 'y': 1},
          ],
        },
      ],
    };

    group('with modifierKey', () {
      for (final key in ModifierKey.values) {
        for (final pressed in [true, false]) {
          late Chart chart;
          late Scale scaleX;
          late Scale scaleY;
          testWidgets(
            'should ${pressed ? '' : 'not '}change '
            '${pressed ? 'with' : 'without'} key ${key.name}',
            (tester) async {
              final rejectedSpy = createSpy('wheelFailed');
              chart = acquireChart(<String, Object?>{
                'type': 'line',
                'data': data(),
                'options': <String, Object?>{
                  'scales': <String, Object?>{
                    'x': <String, Object?>{
                      'type': 'linear',
                      'min': 0,
                      'max': 10,
                    },
                    'y': <String, Object?>{'type': 'linear'},
                  },
                  'plugins': <String, Object?>{
                    'zoom': <String, Object?>{
                      'zoom': <String, Object?>{
                        'wheel': <String, Object?>{
                          'enabled': true,
                          'modifierKey': key,
                        },
                        'mode': Mode.x,
                        'onZoomRejected': rejectedSpy.call,
                      },
                    },
                  },
                },
              });

              scaleX = chart.scales['x']!;
              scaleY = chart.scales['y']!;

              final oldMinX = scaleX.options.min;
              final oldMaxX = scaleX.options.max;

              final wheelEv = (
                x: scaleX.getPixelForValue(1.5),
                y: scaleY.getPixelForValue(1.1),
                deltaY: 100,
              );
              final init = pressed ? EventInit.withKey(key) : const EventInit();

              triggerWheelEvent(
                chart,
                x: wheelEv.x,
                y: wheelEv.y,
                deltaY: wheelEv.deltaY,
                init: init,
              );

              if (pressed) {
                expect(scaleX.options.min, isNot(jasmineEquals(oldMinX)));
                expect(scaleX.options.max, isNot(jasmineEquals(oldMaxX)));
                expect(rejectedSpy, isNot(toHaveBeenCalled()));
              } else {
                expect(scaleX.options.min, jasmineEquals(oldMinX));
                expect(scaleX.options.max, jasmineEquals(oldMaxX));
                expect(rejectedSpy, toHaveBeenCalled());
              }
            },
          );
        }
      }
    });

    group('with overScaleMode = y and mode = xy', () {
      // zoom.wheel.spec.js:89 `const config = {...}`: one object for the two
      // charts of the group. The function gives a new object for each
      // chart, as `data`.
      Map<String, Object?> config() => <String, Object?>{
        'type': 'line',
        'data': data(),
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear', 'min': 1, 'max': 10},
            'y': <String, Object?>{'type': 'linear'},
          },
          'plugins': <String, Object?>{
            'zoom': <String, Object?>{
              'zoom': <String, Object?>{
                'wheel': <String, Object?>{'enabled': true},
                'mode': Mode.xy,
                'overScaleMode': Mode.y,
              },
            },
          },
        },
      };

      group('Wheel under Y scale', () {
        testWidgets('should be applied on Y, but not on X scales.', (
          tester,
        ) async {
          final chart = acquireChart(config());

          final scaleX = chart.scales['x']!;
          final scaleY = chart.scales['y']!;

          final oldMinX = scaleX.options.min;
          final oldMaxX = scaleX.options.max;
          final oldMinY = scaleY.options.min;
          final oldMaxY = scaleY.options.max;

          final wheelEv = (
            x: scaleY.left + (scaleY.right - scaleY.left) / 2,
            y: scaleY.top + (scaleY.bottom - scaleY.top) / 2,
            deltaY: 100,
          );

          triggerWheelEvent(
            chart,
            x: wheelEv.x,
            y: wheelEv.y,
            deltaY: wheelEv.deltaY,
          );

          expect(scaleX.options.min, jasmineEquals(oldMinX));
          expect(scaleX.options.max, jasmineEquals(oldMaxX));
          expect(scaleY.options.min, isNot(jasmineEquals(oldMinY)));
          expect(scaleY.options.max, isNot(jasmineEquals(oldMaxY)));
        });
      });

      group('Wheel not under Y scale', () {
        testWidgets('should be applied on X, but not on Y scales.', (
          tester,
        ) async {
          final chart = acquireChart(config());

          final scaleX = chart.scales['x']!;
          final scaleY = chart.scales['y']!;

          final oldMinX = scaleX.options.min;
          final oldMaxX = scaleX.options.max;
          final oldMinY = scaleY.options.min;
          final oldMaxY = scaleY.options.max;

          final wheelEv = (
            x: scaleX.getPixelForValue(1.5),
            y: scaleY.getPixelForValue(1.1),
            deltaY: 100,
          );

          triggerWheelEvent(
            chart,
            x: wheelEv.x,
            y: wheelEv.y,
            deltaY: wheelEv.deltaY,
          );

          expect(scaleX.options.min, isNot(jasmineEquals(oldMinX)));
          expect(scaleX.options.max, isNot(jasmineEquals(oldMaxX)));
          expect(scaleY.options.min, jasmineEquals(oldMinY));
          expect(scaleY.options.max, jasmineEquals(oldMaxY));
        });
      });
    });

    group('with scaleMode = y and mode = xy', () {
      // zoom.wheel.spec.js:173 `const config = {...}`, as above.
      Map<String, Object?> config() => <String, Object?>{
        'type': 'line',
        'data': data(),
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear', 'min': 1, 'max': 10},
            'y': <String, Object?>{'type': 'linear'},
          },
          'plugins': <String, Object?>{
            'zoom': <String, Object?>{
              'zoom': <String, Object?>{
                'wheel': <String, Object?>{'enabled': true},
                'mode': Mode.xy,
                'scaleMode': Mode.y,
              },
            },
          },
        },
      };

      group('Wheel under Y scale', () {
        testWidgets('should be applied on Y, but not on X scales.', (
          tester,
        ) async {
          final chart = acquireChart(config());

          final scaleX = chart.scales['x']!;
          final scaleY = chart.scales['y']!;

          final oldMinX = scaleX.options.min;
          final oldMaxX = scaleX.options.max;
          final oldMinY = scaleY.options.min;
          final oldMaxY = scaleY.options.max;

          final wheelEv = (
            x: scaleY.left + (scaleY.right - scaleY.left) / 2,
            y: scaleY.top + (scaleY.bottom - scaleY.top) / 2,
            deltaY: 100,
          );

          triggerWheelEvent(
            chart,
            x: wheelEv.x,
            y: wheelEv.y,
            deltaY: wheelEv.deltaY,
          );

          expect(scaleX.options.min, jasmineEquals(oldMinX));
          expect(scaleX.options.max, jasmineEquals(oldMaxX));
          expect(scaleY.options.min, isNot(jasmineEquals(oldMinY)));
          expect(scaleY.options.max, isNot(jasmineEquals(oldMaxY)));
        });
      });

      group('Wheel not under Y scale', () {
        testWidgets('should be applied on X and Y scales.', (tester) async {
          final chart = acquireChart(config());

          final scaleX = chart.scales['x']!;
          final scaleY = chart.scales['y']!;

          final oldMinX = scaleX.options.min;
          final oldMaxX = scaleX.options.max;
          final oldMinY = scaleY.options.min;
          final oldMaxY = scaleY.options.max;

          final wheelEv = (
            x: scaleX.getPixelForValue(1.5),
            y: scaleY.getPixelForValue(1.1),
            deltaY: 100,
          );

          triggerWheelEvent(
            chart,
            x: wheelEv.x,
            y: wheelEv.y,
            deltaY: wheelEv.deltaY,
          );

          expect(scaleX.options.min, isNot(jasmineEquals(oldMinX)));
          expect(scaleX.options.max, isNot(jasmineEquals(oldMaxX)));
          expect(scaleY.options.min, isNot(jasmineEquals(oldMinY)));
          expect(scaleY.options.max, isNot(jasmineEquals(oldMaxY)));
        });
      });
    });

    group('with logarithmic scale', () {
      testWidgets('should zoom correctly when mouse in center of chart', (
        tester,
      ) async {
        final config = <String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 10, 100, 1000, 10000],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'logarithmic'},
            },
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'zoom': <String, Object?>{
                  'mode': Mode.y,
                  'wheel': <String, Object?>{'enabled': true},
                },
              },
            },
          },
        };
        final chart = acquireChart(config);
        final scaleY = chart.scales['y']!;

        final zoomIn = (
          x: jsRound(scaleY.left + (scaleY.right - scaleY.left) / 2),
          y: jsRound(scaleY.top + (scaleY.bottom - scaleY.top) / 2),
          deltaY: -100,
        );

        final zoomOut = (x: zoomIn.x, y: zoomIn.y, deltaY: 100);

        expect(scaleY.min, toBe(1));
        expect(scaleY.max, toBe(10000));

        triggerWheelEvent(
          chart,
          x: zoomIn.x,
          y: zoomIn.y,
          deltaY: zoomIn.deltaY,
        );

        expect(scaleY.min, toBeCloseTo(1.6, 1));
        expect(scaleY.max, toBeCloseTo(6310, -1));

        triggerWheelEvent(
          chart,
          x: zoomIn.x,
          y: zoomIn.y,
          deltaY: zoomIn.deltaY,
        );

        expect(scaleY.min, toBeCloseTo(2.4, 1));
        expect(scaleY.max, toBeCloseTo(4170, -1));

        triggerWheelEvent(
          chart,
          x: zoomOut.x,
          y: zoomOut.y,
          deltaY: zoomOut.deltaY,
        );
        triggerWheelEvent(
          chart,
          x: zoomOut.x,
          y: zoomOut.y,
          deltaY: zoomOut.deltaY,
        );

        expect(scaleY.min, toBe(1));
        expect(scaleY.max, toBe(10000));

        chart.resetZoom();

        expect(scaleY.min, toBe(1));
        expect(scaleY.max, toBe(10000));

        triggerWheelEvent(
          chart,
          x: zoomOut.x,
          y: zoomOut.y,
          deltaY: zoomOut.deltaY,
        );

        expect(scaleY.min, toBeCloseTo(0.6, 1));
        expect(scaleY.max, toBeCloseTo(16700, -2));

        triggerWheelEvent(
          chart,
          x: zoomIn.x,
          y: zoomIn.y,
          deltaY: zoomIn.deltaY,
        );

        expect(scaleY.min, toBeCloseTo(1));
        expect(scaleY.max, toBeCloseTo(10000));
      });
    });

    testWidgets('should respect aspectRatio when mode = xy', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': data(),
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear'},
            'y': <String, Object?>{'type': 'linear'},
          },
          'plugins': <String, Object?>{
            'legend': false,
            'title': false,
            'zoom': <String, Object?>{
              'zoom': <String, Object?>{
                'drag': <String, Object?>{
                  'enabled': true,
                  'maintainAspectRatio': true,
                },
                'mode': Mode.xy,
              },
            },
          },
        },
      });

      final scaleX = chart.scales['x']!;
      final scaleY = chart.scales['y']!;

      triggerMouseEvent(chart, 'mousedown', (
        x: scaleX.getPixelForValue(1.5),
        y: scaleY.getPixelForValue(1.1),
      ));
      triggerMouseEvent(chart, 'mouseup', (
        x: scaleX.getPixelForValue(2.8),
        y: scaleY.getPixelForValue(1.7),
      ));

      expect(scaleX.options.min, toBeCloseTo(1.5));
      expect(scaleX.options.max, toBeCloseTo(2.1));
      expect(scaleY.options.min, toBeCloseTo(1.1));
      expect(scaleY.options.max, toBeCloseTo(1.7));
    });

    group('events', () {
      testWidgets('should call onZoomStart, onZoom and onZoomComplete', (
        tester,
      ) async {
        await waitForDone((done) {
          final startSpy = createSpy('start');
          final zoomSpy = createSpy('zoom');
          final chart = acquireChart(<String, Object?>{
            'type': 'scatter',
            'data': data(),
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'zoom': <String, Object?>{
                  'zoom': <String, Object?>{
                    'wheel': <String, Object?>{'enabled': true},
                    'mode': Mode.xy,
                    'onZoomStart': (ZoomStartContext<NativeEvent> context) {
                      startSpy.call(context);
                      return true;
                    },
                    'onZoom': zoomSpy.call,
                    'onZoomComplete': (ZoomChartContext _) => done(),
                  },
                },
              },
            },
          });
          final wheelEv = (
            x: chart.scales['x']!.getPixelForValue(1.5),
            y: chart.scales['y']!.getPixelForValue(1.1),
            deltaY: 100,
          );

          triggerWheelEvent(
            chart,
            x: wheelEv.x,
            y: wheelEv.y,
            deltaY: wheelEv.deltaY,
          );

          expect(startSpy, toHaveBeenCalled());
          expect(
            zoomSpy,
            toHaveBeenCalledWith([(chart: chart, trigger: ZoomTrigger.wheel)]),
          );
          expect(chart.scales['x']!.min, isNot(toBe(1)));
        });
      });

      testWidgets('should detect configuration change', (tester) async {
        final startSpy = createSpy('started');
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': data(),
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'zoom': <String, Object?>{
                  'wheel': <String, Object?>{'enabled': false},
                  'mode': Mode.xy,
                  'onZoomStart': (ZoomStartContext<NativeEvent> context) {
                    startSpy.call(context);
                    return true;
                  },
                },
              },
            },
          },
        });
        final wheelEv = (
          x: chart.scales['x']!.getPixelForValue(1.5),
          y: chart.scales['y']!.getPixelForValue(1.1),
          deltaY: 100,
        );
        triggerWheelEvent(
          chart,
          x: wheelEv.x,
          y: wheelEv.y,
          deltaY: wheelEv.deltaY,
        );
        expect(startSpy, isNot(toHaveBeenCalled()));
        expect(chart.scales['x']!.min, toBe(1));

        // chart.options.plugins.zoom.zoom.wheel.enabled = true: each read
        // through the face of the options of the chart.
        final plugins = chart.options['plugins']! as JsObjectFace;
        final pluginOptions = plugins['zoom']! as JsObjectFace;
        final zoomOptions = pluginOptions['zoom']! as JsObjectFace;
        (zoomOptions['wheel']! as JsObjectFace)['enabled'] = true;
        chart.update();

        triggerWheelEvent(
          chart,
          x: wheelEv.x,
          y: wheelEv.y,
          deltaY: wheelEv.deltaY,
        );
        expect(startSpy, toHaveBeenCalled());
        expect(chart.scales['x']!.min, isNot(toBe(1)));
      });

      testWidgets('should call onZoomRejected when onZoomStart returns false', (
        tester,
      ) async {
        final rejectSpy = createSpy('rejected');
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': data(),
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'zoom': <String, Object?>{
                  'wheel': <String, Object?>{'enabled': true},
                  'mode': Mode.xy,
                  'onZoomStart': (ZoomStartContext<NativeEvent> _) => false,
                  'onZoomRejected': rejectSpy.call,
                },
              },
            },
          },
        });
        final wheelEv = (
          x: chart.scales['x']!.getPixelForValue(1.5),
          y: chart.scales['y']!.getPixelForValue(1.1),
          deltaY: 100,
        );
        triggerWheelEvent(
          chart,
          x: wheelEv.x,
          y: wheelEv.y,
          deltaY: wheelEv.deltaY,
        );
        expect(rejectSpy, toHaveBeenCalled());
        expect(chart.scales['x']!.min, toBe(1));
      });
    });
  });
}
