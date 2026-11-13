// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/zoom.drag.spec.js (MIT, chartjs-plugin-zoom contributors).
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
    show CanvasEventTarget, Chart, NativeEvent, Scale, undefined;
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart';
import '../support/jasmine.dart';

void main() {
  group('zoom with drag', () {
    // zoom.drag.spec.js:2 `const data = {...}`: one object for all the
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

    group('on linear scale', () {
      late Chart chart;
      late Scale scaleX;
      late Scale scaleY;

      testWidgets('should be applied on X scale when mode = x', (tester) async {
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': data(),
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'xScale0': <String, Object?>{'id': 'xScale0', 'type': 'linear'},
              'yScale0': <String, Object?>{'id': 'yScale0', 'type': 'linear'},
            },
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'zoom': <String, Object?>{
                  'drag': <String, Object?>{'enabled': true},
                  'mode': Mode.x,
                },
              },
            },
          },
        });

        scaleX = chart.scales['xScale0']!;
        scaleY = chart.scales['yScale0']!;

        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(1.5),
          y: scaleY.getPixelForValue(1.1),
        ));
        triggerMouseEvent(chart, 'mouseup', (
          x: scaleX.getPixelForValue(2.8),
          y: scaleY.getPixelForValue(1.7),
        ));

        expect(scaleX.options.min, toBeCloseTo(1.5));
        expect(scaleX.options.max, toBeCloseTo(2.8));
        expect(scaleY.options.min, toBe(undefined));
        expect(scaleY.options.max, toBe(undefined));
      });

      testWidgets('should be applied on X scale when mode = f() => x', (
        tester,
      ) async {
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': data(),
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'xScale0': <String, Object?>{'id': 'xScale0', 'type': 'linear'},
              'yScale0': <String, Object?>{'id': 'yScale0', 'type': 'linear'},
            },
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'zoom': <String, Object?>{
                  'drag': <String, Object?>{'enabled': true},
                  'mode': (ZoomChartContext _) {
                    return Mode.x;
                  },
                },
              },
            },
          },
        });

        scaleX = chart.scales['xScale0']!;
        scaleY = chart.scales['yScale0']!;

        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(1.5),
          y: scaleY.getPixelForValue(1.1),
        ));
        triggerMouseEvent(chart, 'mouseup', (
          x: scaleX.getPixelForValue(2.8),
          y: scaleY.getPixelForValue(1.7),
        ));

        expect(scaleX.options.min, toBeCloseTo(1.5));
        expect(scaleX.options.max, toBeCloseTo(2.8));
        expect(scaleY.options.min, toBe(undefined));
        expect(scaleY.options.max, toBe(undefined));
      });

      testWidgets('should be applied on Y scale when mode = y', (tester) async {
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': data(),
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'xScale0': <String, Object?>{'id': 'xScale0', 'type': 'linear'},
              'yScale0': <String, Object?>{'id': 'yScale0', 'type': 'linear'},
            },
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'zoom': <String, Object?>{
                  'drag': <String, Object?>{'enabled': true},
                  'mode': Mode.y,
                },
              },
            },
          },
        });

        scaleX = chart.scales['xScale0']!;
        scaleY = chart.scales['yScale0']!;

        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(1.5),
          y: scaleY.getPixelForValue(1.1),
        ));
        triggerMouseEvent(chart, 'mouseup', (
          x: scaleX.getPixelForValue(2.8),
          y: scaleY.getPixelForValue(1.7),
        ));

        expect(scaleX.options.min, toBe(undefined));
        expect(scaleX.options.max, toBe(undefined));
        expect(scaleY.options.min, toBeCloseTo(1.1));
        expect(scaleY.options.max, toBeCloseTo(1.7));
      });

      testWidgets('should be applied on Y scale when mode = f() => y', (
        tester,
      ) async {
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': data(),
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'xScale0': <String, Object?>{'id': 'xScale0', 'type': 'linear'},
              'yScale0': <String, Object?>{'id': 'yScale0', 'type': 'linear'},
            },
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'zoom': <String, Object?>{
                  'drag': <String, Object?>{'enabled': true},
                  'mode': (ZoomChartContext _) {
                    return Mode.y;
                  },
                },
              },
            },
          },
        });

        scaleX = chart.scales['xScale0']!;
        scaleY = chart.scales['yScale0']!;

        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(1.5),
          y: scaleY.getPixelForValue(1.1),
        ));
        triggerMouseEvent(chart, 'mouseup', (
          x: scaleX.getPixelForValue(2.8),
          y: scaleY.getPixelForValue(1.7),
        ));

        expect(scaleX.options.min, toBe(undefined));
        expect(scaleX.options.max, toBe(undefined));
        expect(scaleY.options.min, toBeCloseTo(1.1));
        expect(scaleY.options.max, toBeCloseTo(1.7));
      });

      testWidgets('should be applied on X and Y scales when mode = xy', (
        tester,
      ) async {
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': data(),
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'xScale0': <String, Object?>{'id': 'xScale0', 'type': 'linear'},
              'yScale0': <String, Object?>{'id': 'yScale0', 'type': 'linear'},
            },
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'zoom': <String, Object?>{
                  'drag': <String, Object?>{'enabled': true},
                  'mode': Mode.xy,
                },
              },
            },
          },
        });

        scaleX = chart.scales['xScale0']!;
        scaleY = chart.scales['yScale0']!;

        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(1.5),
          y: scaleY.getPixelForValue(1.1),
        ));
        triggerMouseEvent(chart, 'mouseup', (
          x: scaleX.getPixelForValue(2.8),
          y: scaleY.getPixelForValue(1.7),
        ));

        expect(scaleX.options.min, toBeCloseTo(1.5));
        expect(scaleX.options.max, toBeCloseTo(2.8));
        expect(scaleY.options.min, toBeCloseTo(1.1));
        expect(scaleY.options.max, toBeCloseTo(1.7));
      });
    });

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
                        'drag': <String, Object?>{
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

              final pt = (
                x: scaleX.getPixelForValue(1.5),
                y: scaleY.getPixelForValue(1.1),
              );
              final pt2 = (x: pt.x + 20, y: pt.y + 20);
              final init = pressed ? EventInit.withKey(key) : const EventInit();

              dispatchEvent(chart, 'mousedown', pt, init);
              dispatchEvent(chart, 'mousemove', pt2, init);
              dispatchEvent(chart, 'mouseup', pt2, init);

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

    group('drag with pan.modifierKey', () {
      for (final key in ModifierKey.values) {
        for (final pressed in [true, false]) {
          late Chart chart;
          late Scale scaleX;
          late Scale scaleY;
          testWidgets(
            'should ${pressed ? 'not ' : ''}change '
            '${pressed ? 'without' : 'with'} key ${key.name}',
            (tester) async {
              final rejectedSpy = createSpy('zoomRejected');
              final clickSpy = createSpy('clicked');
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
                      'pan': <String, Object?>{
                        'enabled': true,
                        'modifierKey': key,
                      },
                      'zoom': <String, Object?>{
                        'drag': <String, Object?>{'enabled': true},
                        'mode': Mode.x,
                        'onZoomRejected': rejectedSpy.call,
                      },
                    },
                  },
                  'onClick': clickSpy.call,
                },
              });

              scaleX = chart.scales['x']!;
              scaleY = chart.scales['y']!;

              final oldMinX = scaleX.options.min;
              final oldMaxX = scaleX.options.max;

              final pt = (
                x: scaleX.getPixelForValue(1.5),
                y: scaleY.getPixelForValue(1.1),
              );
              final pt2 = (x: pt.x + 20, y: pt.y + 20);
              final init = pressed ? EventInit.withKey(key) : const EventInit();

              dispatchEvent(chart, 'mousedown', pt, init);
              dispatchEvent(chart, 'mousemove', pt2, init);
              dispatchEvent(chart, 'mouseup', pt2, init);

              if (pressed) {
                expect(scaleX.options.min, jasmineEquals(oldMinX));
                expect(scaleX.options.max, jasmineEquals(oldMaxX));
                expect(rejectedSpy, toHaveBeenCalled());
              } else {
                expect(scaleX.options.min, isNot(jasmineEquals(oldMinX)));
                expect(scaleX.options.max, isNot(jasmineEquals(oldMaxX)));
                expect(rejectedSpy, isNot(toHaveBeenCalled()));
              }
              expect(clickSpy, isNot(toHaveBeenCalled()));
            },
          );
        }
      }
    });

    group('coordinate handling', () {
      late Chart chart;
      late Scale scaleX;
      late Scale scaleY;

      testWidgets('handles dragging to the right edge of the chart', (
        tester,
      ) async {
        chart = acquireChart(
          <String, Object?>{
            'type': 'line',
            'data': data(),
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'xScale0': <String, Object?>{
                  'id': 'xScale0',
                  'type': 'linear',
                  'min': 0,
                  'max': 4,
                },
                'yScale0': <String, Object?>{
                  'id': 'yScale0',
                  'type': 'linear',
                  'min': 0,
                  'max': 4,
                },
              },
              'plugins': <String, Object?>{
                'zoom': <String, Object?>{
                  'zoom': <String, Object?>{
                    'drag': <String, Object?>{'enabled': true},
                    'mode': Mode.xy,
                  },
                },
              },
            },
          },
          <String, Object?>{
            'wrapper': <String, Object?>{
              'style': 'position: absolute; left: 50px; top: 50px;',
            },
          },
        );

        scaleX = chart.scales['xScale0']!;
        scaleY = chart.scales['yScale0']!;

        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(1.5),
          y: scaleY.getPixelForValue(1.2),
        ));
        triggerMouseEvent(chart, 'mouseup', (
          x: scaleX.getPixelForValue(4) + 5,
          y: scaleY.getPixelForValue(1.7),
        ));

        expect(scaleX.options.min, toBeCloseTo(1.5));
        expect(scaleX.options.max, toBeCloseTo(4));
        expect(scaleY.options.min, toBeCloseTo(1.2));
        expect(scaleY.options.max, toBeCloseTo(1.7));
      });

      testWidgets('handles dragging off the right edge of the chart canvas', (
        tester,
      ) async {
        chart = acquireChart(
          <String, Object?>{
            'type': 'line',
            'data': data(),
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'xScale0': <String, Object?>{
                  'id': 'xScale0',
                  'type': 'linear',
                  'min': 0,
                  'max': 4,
                },
                'yScale0': <String, Object?>{
                  'id': 'yScale0',
                  'type': 'linear',
                  'min': 0,
                  'max': 4,
                },
              },
              'plugins': <String, Object?>{
                'zoom': <String, Object?>{
                  'zoom': <String, Object?>{
                    'drag': <String, Object?>{'enabled': true},
                    'mode': Mode.xy,
                  },
                },
              },
            },
          },
          <String, Object?>{
            'wrapper': <String, Object?>{
              'style': 'position: absolute; left: 50px; top: 50px;',
            },
          },
        );

        scaleX = chart.scales['xScale0']!;
        scaleY = chart.scales['yScale0']!;

        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(1.5),
          y: scaleY.getPixelForValue(1.2),
        ));

        // `document.documentElement.dispatchEvent(new MouseEvent(...))`: the
        // dispatch on the document of the canvas (Chart.js ADR 0108), whose
        // target is the document. The root element of the page has its box
        // at the origin of the view, so its offsets are the client point.
        final rect = chart.canvas!.getBoundingClientRect();
        final clientX = rect.right;
        final clientY = rect.top + scaleY.getPixelForValue(1.7);
        chart.canvas!.ownerDocument.dispatchEvent(
          NativeEvent(
            type: 'mouseup',
            clientX: clientX,
            clientY: clientY,
            offsetX: clientX,
            offsetY: clientY,
            cancelable: true,
            bubbles: true,
          ),
        );

        expect(scaleX.options.min, toBeCloseTo(1.5));
        expect(scaleX.options.max, toBeCloseTo(4));
        expect(scaleY.options.min, toBeCloseTo(1.2));
        expect(scaleY.options.max, toBeCloseTo(1.7));
      });
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
                    'drag': <String, Object?>{'enabled': true},
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

          final pt = (
            x: chart.scales['x']!.getPixelForValue(1.5),
            y: chart.scales['y']!.getPixelForValue(1.1),
          );
          final pt2 = (x: pt.x + 20, y: pt.y + 20);

          expect(chart.isZoomingOrPanning(), toBe(false));

          dispatchEvent(chart, 'mousedown', pt);
          dispatchEvent(chart, 'mousemove', pt2);

          expect(chart.isZoomingOrPanning(), toBe(true));

          dispatchEvent(chart, 'mouseup', pt2);

          // Drag state isn't cleared until a timeout fires (later), so we
          // can't easily test this here.
          // expect(chart.isZoomingOrPanning()).toBe(false);

          expect(startSpy, toHaveBeenCalled());
          expect(
            zoomSpy,
            toHaveBeenCalledWith([(chart: chart, trigger: ZoomTrigger.drag)]),
          );
        });
      });

      testWidgets('should call onZoomRejected when onZoomStart returns false', (
        tester,
      ) async {
        final zoomSpy = createSpy('zoom');
        final rejectSpy = createSpy('reject');
        final doneSpy = createSpy('done');
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': data(),
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'zoom': <String, Object?>{
                  'drag': <String, Object?>{'enabled': true},
                  'mode': Mode.xy,
                  'onZoomStart': (ZoomStartContext<NativeEvent> _) => false,
                  'onZoom': zoomSpy.call,
                  'onZoomComplete': doneSpy.call,
                  'onZoomRejected': rejectSpy.call,
                },
              },
            },
          },
        });

        final pt = (
          x: chart.scales['x']!.getPixelForValue(1.5),
          y: chart.scales['y']!.getPixelForValue(1.1),
        );
        final pt2 = (x: pt.x + 20, y: pt.y + 20);

        expect(chart.isZoomingOrPanning(), toBe(false));

        dispatchEvent(chart, 'mousedown', pt);

        expect(chart.isZoomingOrPanning(), toBe(false));

        dispatchEvent(chart, 'mousemove', pt2);
        dispatchEvent(chart, 'mouseup', pt2);

        expect(chart.isZoomingOrPanning(), toBe(false));

        expect(rejectSpy, toHaveBeenCalled());
        expect(zoomSpy, isNot(toHaveBeenCalled()));
        expect(doneSpy, isNot(toHaveBeenCalled()));
      });
    });
  });
}
