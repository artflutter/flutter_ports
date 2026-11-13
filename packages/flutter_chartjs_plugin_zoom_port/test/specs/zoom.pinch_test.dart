// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/zoom.pinch.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' show acquireChart, waitForDone;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show Mode, ZoomChartContext, ZoomStartContext;
import 'package:flutter_chartjs_port/chartjs.dart'
    show CanvasEventTarget, NativeEvent;
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart' show dispatchPointer, simulatePinch;
import '../support/jasmine.dart';

void main() {
  group('pinch', () {
    final data = <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{
              'x': 1,
              'y': 3,
            },
            <String, Object?>{
              'x': 2,
              'y': 2,
            },
            <String, Object?>{
              'x': 3,
              'y': 1,
            },
          ],
        },
      ],
    };

    group('events', () {
      testWidgets('should call onZoomStart', (tester) async {
        await waitForDone((done) {
          final startSpy = createSpy('started');
          final chart = acquireChart(<String, Object?>{
            'type': 'scatter',
            'data': data,
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'zoom': <String, Object?>{
                  'zoom': <String, Object?>{
                    'mode': Mode.xy,
                    'onZoomStart': (ZoomStartContext<NativeEvent> context) {
                      startSpy.call(context);
                      return true;
                    },
                    'pinch': <String, Object?>{
                      'enabled': true,
                    },
                  },
                },
              },
            },
          });

          simulatePinch(
            chart,
            pos: (chart.width / 2, chart.height / 2),
            done: () {
              expect(startSpy, toHaveBeenCalled());
              expect(chart.scales['x']!.min, isNot(toBe(1)));
              done();
            },
          );
        });
      });

      testWidgets(
        'should call onZoomRejected when onStartZoom returns false',
        (tester) async {
          await waitForDone((done) {
            final rejectSpy = createSpy('rejected');
            final chart = acquireChart(<String, Object?>{
              'type': 'scatter',
              'data': data,
              'options': <String, Object?>{
                'plugins': <String, Object?>{
                  'zoom': <String, Object?>{
                    'zoom': <String, Object?>{
                      'mode': Mode.xy,
                      'onZoomStart': (ZoomStartContext<NativeEvent> _) => false,
                      'onZoomRejected': rejectSpy.call,
                      'pinch': <String, Object?>{
                        'enabled': true,
                      },
                    },
                  },
                },
              },
            });

            simulatePinch(
              chart,
              done: () {
                expect(rejectSpy, toHaveBeenCalled());
                expect(chart.scales['x']!.min, toBe(1));
                done();
              },
            );
          });
        },
      );

      testWidgets('should call onZoomComplete', (tester) async {
        await waitForDone((done) {
          final chart = acquireChart(<String, Object?>{
            'type': 'scatter',
            'data': data,
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'zoom': <String, Object?>{
                  'zoom': <String, Object?>{
                    'mode': Mode.xy,
                    'onZoomComplete': (ZoomChartContext ctx) {
                      expect(ctx.chart.scales['x']!.min, isNot(toBe(1)));
                      done();
                    },
                    'pinch': <String, Object?>{
                      'enabled': true,
                    },
                  },
                },
              },
            },
          });
          simulatePinch(chart);
        });
      });

      testWidgets('should ignore a third pointer during a pinch', (
        tester,
      ) async {
        final startSpy = createSpy('started');
        final completeSpy = createSpy('completed');
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': data,
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'zoom': <String, Object?>{
                  'mode': Mode.xy,
                  'onZoomStart': (ZoomStartContext<NativeEvent> context) {
                    startSpy.call(context);
                    return true;
                  },
                  'onZoomComplete': completeSpy.call,
                  'pinch': <String, Object?>{
                    'enabled': true,
                  },
                },
              },
            },
          },
        });

        final node = chart.canvas!;
        final rect = node.getBoundingClientRect();
        final cx = rect.left + rect.width / 2;
        final cy = rect.top + rect.height / 2;
        const dispatch = dispatchPointer;

        dispatch(node, 'pointerdown', 1, cx - 40, cy);
        dispatch(node, 'pointerdown', 2, cx + 40, cy);
        expect(startSpy, toHaveBeenCalledTimes(1));

        // A third finger neither restarts the pinch nor ends it when lifted.
        dispatch(node, 'pointerdown', 3, cx, cy + 100);
        expect(startSpy, toHaveBeenCalledTimes(1));
        dispatch(node, 'pointerup', 3, cx, cy + 100);
        expect(completeSpy, isNot(toHaveBeenCalled()));

        dispatch(node, 'pointermove', 1, cx - 80, cy);
        dispatch(node, 'pointermove', 2, cx + 80, cy);
        expect(chart.scales['x']!.min, isNot(toBe(1)));

        dispatch(node, 'pointerup', 1, cx - 80, cy);
        dispatch(node, 'pointerup', 2, cx + 80, cy);
        expect(completeSpy, toHaveBeenCalledTimes(1));
      });
    });
  });
}
