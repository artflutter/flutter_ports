// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/pan.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' show acquireChart, waitForDone;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show
        GestureEvent,
        Mode,
        ModifierKey,
        ZoomChart,
        ZoomChartContext,
        ZoomStartContext;
import 'package:flutter_chartjs_port/chartjs.dart' show CanvasEventTarget;
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart'
    show EventInit, dispatchPointer, simulatePan;
import '../support/jasmine.dart';

void main() {
  group('pan', () {
    final data = <String, Object?>{
      'labels': <Object?>['a', 'b', 'c', 'd', 'e'],
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

    group('delta', () {
      testWidgets('should be applied cumulatively', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': data,
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'pan': <String, Object?>{'enabled': true, 'mode': Mode.x},
              },
            },
            'scales': <String, Object?>{
              'x': <String, Object?>{'min': 1, 'max': 2},
            },
          },
        });
        final scale = chart.scales['x']!;
        expect(scale.min, toBe(1));
        expect(scale.max, toBe(2));
        chart.pan(const .all(20));
        expect(scale.min, toBe(1));
        expect(scale.max, toBe(2));
        chart.pan(const .all(20));
        expect(scale.min, toBe(1));
        expect(scale.max, toBe(2));
        chart.pan(const .all(20));
        expect(scale.min, toBe(0));
        expect(scale.max, toBe(1));
      });

      testWidgets('should not give credit', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': data,
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'limits': <String, Object?>{
                  'x': <String, Object?>{'max': 4},
                },
                'pan': <String, Object?>{'enabled': true, 'mode': Mode.x},
              },
            },
            'scales': <String, Object?>{
              'x': <String, Object?>{'min': 1, 'max': 3},
            },
          },
        });
        final scale = chart.scales['x']!;
        expect(scale.min, toBe(1));
        expect(scale.max, toBe(3));
        chart.pan(const .all(-2000));
        expect(scale.min, toBe(1));
        expect(scale.max, toBe(3));
        chart.pan(const .all(-2000));
        expect(scale.min, toBe(1));
        expect(scale.max, toBe(3));
        chart.pan(const .all(50));
        expect(scale.min, lessThan(2));
        expect(scale.max, toBe(scale.min + 2));
      });

      testWidgets('should handle zero-dimension scales', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': data,
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'pan': <String, Object?>{'enabled': true, 'mode': Mode.y},
              },
            },
            'scales': <String, Object?>{
              'y': <String, Object?>{'type': 'linear', 'min': 2, 'max': 2},
            },
          },
        });
        final scale = chart.scales['y']!;
        expect(scale.min, toBe(2));
        expect(scale.max, toBe(2));
        chart.pan(const .all(50));
        expect(scale.min, toBe(2));
        expect(scale.max, toBe(2));
        expect(scale.options.min, toBe(2));
        expect(scale.options.max, toBe(2));
      });

      testWidgets('should respect original limits', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': data,
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'pan': <String, Object?>{'enabled': true, 'mode': Mode.x},
                'limits': <String, Object?>{
                  'x': <String, Object?>{'min': 'original', 'max': 'original'},
                },
              },
            },
            'scales': <String, Object?>{
              'x': <String, Object?>{'min': 1, 'max': 2},
            },
          },
        });
        final scale = chart.scales['x']!;
        expect(scale.min, toBe(1));
        expect(scale.max, toBe(2));
        chart.pan(const .all(100));
        expect(scale.min, toBe(1));
        expect(scale.max, toBe(2));
      });

      testWidgets('should respect original limits for nonlinear scales', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': data,
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'pan': <String, Object?>{'enabled': true, 'mode': Mode.x},
                'limits': <String, Object?>{
                  'x': <String, Object?>{'min': 'original', 'max': 'original'},
                },
              },
            },
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'logarithmic',
                'min': 1,
                'max': 10,
              },
            },
          },
        });
        final scale = chart.scales['x']!;
        expect(scale.min, toBe(1));
        expect(scale.max, toBe(10));
        chart.pan(const .all(100));
        expect(scale.min, toBe(1));
        expect(scale.max, toBe(10));
      });
    });

    group('events', () {
      testWidgets('should call onPanStart', (tester) async {
        await waitForDone((done) {
          final startSpy = createSpy('started');
          final chart = acquireChart(<String, Object?>{
            'type': 'scatter',
            'data': data,
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'zoom': <String, Object?>{
                  'pan': <String, Object?>{
                    'enabled': true,
                    'mode': Mode.xy,
                    'onPanStart': (ZoomStartContext<GestureEvent> context) {
                      startSpy.call(context);
                      return true;
                    },
                  },
                },
              },
            },
          });

          simulatePan(
            chart,
            deltaX: -350,
            done: () {
              expect(startSpy, toHaveBeenCalled());
              expect(chart.scales['x']!.min, isNot(toBe(1)));
              done();
            },
          );
        });
      });

      testWidgets('should call onPanRejected when onStartPan returns false', (
        tester,
      ) async {
        await waitForDone((done) {
          final rejectSpy = createSpy('rejected');
          final chart = acquireChart(<String, Object?>{
            'type': 'scatter',
            'data': data,
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'zoom': <String, Object?>{
                  'pan': <String, Object?>{
                    'enabled': true,
                    'mode': Mode.xy,
                    'onPanStart': (ZoomStartContext<GestureEvent> _) => false,
                    'onPanRejected': rejectSpy.call,
                  },
                },
              },
            },
          });

          simulatePan(
            chart,
            deltaX: -350,
            done: () {
              // The rejection must not be repeated for every move of the
              // same gesture.
              expect(rejectSpy, toHaveBeenCalledTimes(1));
              expect(chart.scales['x']!.min, toBe(1));
              done();
            },
          );
        });
      });

      testWidgets(
        'should call onPanRejected when the modifier key is not pressed',
        (tester) async {
          await waitForDone((done) {
            final rejectSpy = createSpy('rejected');
            final chart = acquireChart(<String, Object?>{
              'type': 'scatter',
              'data': data,
              'options': <String, Object?>{
                'plugins': <String, Object?>{
                  'zoom': <String, Object?>{
                    'pan': <String, Object?>{
                      'enabled': true,
                      'mode': Mode.xy,
                      'modifierKey': ModifierKey.ctrl,
                      'onPanRejected': rejectSpy.call,
                    },
                  },
                },
              },
            });

            simulatePan(
              chart,
              deltaX: -350,
              init: const EventInit(pointerType: 'mouse'),
              done: () {
                expect(rejectSpy, toHaveBeenCalled());
                expect(chart.scales['x']!.min, toBe(1));

                simulatePan(
                  chart,
                  deltaX: -350,
                  init: const EventInit(pointerType: 'mouse', ctrlKey: true),
                  done: () {
                    expect(chart.scales['x']!.min, isNot(toBe(1)));
                    done();
                  },
                );
              },
            );
          });
        },
      );

      testWidgets('should not pan with a non-primary mouse button', (
        tester,
      ) async {
        await waitForDone((done) {
          final chart = acquireChart(<String, Object?>{
            'type': 'scatter',
            'data': data,
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'zoom': <String, Object?>{
                  'pan': <String, Object?>{'enabled': true, 'mode': Mode.xy},
                },
              },
            },
          });

          simulatePan(
            chart,
            deltaX: -350,
            init: const EventInit(pointerType: 'mouse', button: 2),
            done: () {
              expect(chart.scales['x']!.min, toBe(1));
              done();
            },
          );
        });
      });

      testWidgets('should call onPanComplete', (tester) async {
        await waitForDone((done) {
          final chart = acquireChart(<String, Object?>{
            'type': 'scatter',
            'data': data,
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'zoom': <String, Object?>{
                  'pan': <String, Object?>{
                    'enabled': true,
                    'mode': Mode.xy,
                    'onPanComplete': (ZoomChartContext ctx) {
                      expect(ctx.chart.scales['x']!.min, isNot(toBe(1)));
                      done();
                    },
                  },
                },
              },
            },
          });
          simulatePan(chart, deltaX: -350);
        });
      });

      testWidgets('should end the pan when a second pointer goes down', (
        tester,
      ) async {
        final completeSpy = createSpy('completed');
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': data,
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'pan': <String, Object?>{
                  'enabled': true,
                  'mode': Mode.xy,
                  'onPanComplete': completeSpy.call,
                },
              },
            },
          },
        });

        final node = chart.canvas!;
        final rect = node.getBoundingClientRect();
        final x = rect.left + rect.width / 2;
        final y = rect.top + rect.height / 2;
        const dispatch = dispatchPointer;

        dispatch(node, 'pointerdown', 1, x, y);
        dispatch(node, 'pointermove', 1, x - 50, y);
        expect(chart.scales['x']!.min, isNot(toBe(1)));

        // The pan ends even though pinch is disabled and no zoom takes over.
        dispatch(node, 'pointerdown', 2, x + 200, y);
        expect(completeSpy, toHaveBeenCalledTimes(1));

        // Lifting the first pointer must not let the second one resume that
        // pan from the old start position, which would jump the chart.
        final min = chart.scales['x']!.min;
        dispatch(node, 'pointerup', 1, x - 50, y);
        dispatch(node, 'pointermove', 2, x + 200, y);
        expect(chart.scales['x']!.min, toBe(min));

        dispatch(node, 'pointerup', 2, x + 200, y);
        expect(completeSpy, toHaveBeenCalledTimes(1));
      });

      testWidgets('should not complete the pan when the gesture is cancelled', (
        tester,
      ) async {
        final completeSpy = createSpy('completed');
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': data,
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'pan': <String, Object?>{
                  'enabled': true,
                  'mode': Mode.xy,
                  'onPanComplete': completeSpy.call,
                },
              },
            },
          },
        });

        final node = chart.canvas!;
        final rect = node.getBoundingClientRect();
        final x = rect.left + rect.width / 2;
        final y = rect.top + rect.height / 2;
        const dispatch = dispatchPointer;

        dispatch(node, 'pointerdown', 1, x, y);
        dispatch(node, 'pointermove', 1, x - 50, y);
        dispatch(node, 'pointercancel', 1, x - 50, y);
        expect(completeSpy, isNot(toHaveBeenCalled()));

        // The aborted pan must not be resumed by the next one.
        final min = chart.scales['x']!.min;
        dispatch(node, 'pointerdown', 1, x, y);
        dispatch(node, 'pointermove', 1, x - 5, y);
        expect(chart.scales['x']!.min, toBe(min));
      });
    });
  });
}
