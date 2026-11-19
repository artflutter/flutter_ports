// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/zoom.wheel.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' hide triggerMouseEvent;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart';

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
          testWidgets('should ${pressed ? '' : 'not '}change '
              '${pressed ? 'with' : 'without'} key ${key.name}', (
            tester,
          ) async {
            // `createSpy('wheelFailed')`: the contexts of the calls.
            final rejectedCalls = <ZoomEventContext<NativeEvent>>[];
            chart = acquireChart(<String, Object?>{
              'type': 'line',
              'data': data(),
              'options': <String, Object?>{
                'scales': <String, Object?>{
                  'x': <String, Object?>{'type': 'linear', 'min': 0, 'max': 10},
                  'y': <String, Object?>{'type': 'linear'},
                },
                'plugins': <String, Object?>{
                  'zoom': ZoomPluginOptions(
                    zoom: ZoomOptions(
                      wheel: WheelOptions(enabled: true, modifierKey: key),
                      mode: Mode.x,
                      onZoomRejected: rejectedCalls.add,
                    ),
                  ),
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
              expect(scaleX.options.min, isNot(equals(oldMinX)));
              expect(scaleX.options.max, isNot(equals(oldMaxX)));
              expect(rejectedCalls, isEmpty);
            } else {
              expect(scaleX.options.min, equals(oldMinX));
              expect(scaleX.options.max, equals(oldMaxX));
              expect(rejectedCalls, isNotEmpty);
            }
          });
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
            'zoom': const ZoomPluginOptions(
              zoom: ZoomOptions(
                wheel: WheelOptions(enabled: true),
                mode: Mode.xy,
                overScaleMode: Mode.y,
              ),
            ),
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

          expect(scaleX.options.min, equals(oldMinX));
          expect(scaleX.options.max, equals(oldMaxX));
          expect(scaleY.options.min, isNot(equals(oldMinY)));
          expect(scaleY.options.max, isNot(equals(oldMaxY)));
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

          expect(scaleX.options.min, isNot(equals(oldMinX)));
          expect(scaleX.options.max, isNot(equals(oldMaxX)));
          expect(scaleY.options.min, equals(oldMinY));
          expect(scaleY.options.max, equals(oldMaxY));
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
            'zoom': const ZoomPluginOptions(
              zoom: ZoomOptions(
                wheel: WheelOptions(enabled: true),
                mode: Mode.xy,
                scaleMode: Mode.y,
              ),
            ),
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

          expect(scaleX.options.min, equals(oldMinX));
          expect(scaleX.options.max, equals(oldMaxX));
          expect(scaleY.options.min, isNot(equals(oldMinY)));
          expect(scaleY.options.max, isNot(equals(oldMaxY)));
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

          expect(scaleX.options.min, isNot(equals(oldMinX)));
          expect(scaleX.options.max, isNot(equals(oldMaxX)));
          expect(scaleY.options.min, isNot(equals(oldMinY)));
          expect(scaleY.options.max, isNot(equals(oldMaxY)));
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
              'zoom': const ZoomPluginOptions(
                zoom: ZoomOptions(
                  mode: Mode.y,
                  wheel: WheelOptions(enabled: true),
                ),
              ),
            },
          },
        };
        final chart = acquireChart(config);
        final scaleY = chart.scales['y']!;

        final zoomIn = (
          x: (scaleY.left + (scaleY.right - scaleY.left) / 2).roundToDouble(),
          y: (scaleY.top + (scaleY.bottom - scaleY.top) / 2).roundToDouble(),
          deltaY: -100,
        );

        final zoomOut = (x: zoomIn.x, y: zoomIn.y, deltaY: 100);

        expect(scaleY.min, equals(1));
        expect(scaleY.max, equals(10000));

        triggerWheelEvent(
          chart,
          x: zoomIn.x,
          y: zoomIn.y,
          deltaY: zoomIn.deltaY,
        );

        expect(scaleY.min, closeTo(1.6, 0.05));
        expect(scaleY.max, closeTo(6310, 5));

        triggerWheelEvent(
          chart,
          x: zoomIn.x,
          y: zoomIn.y,
          deltaY: zoomIn.deltaY,
        );

        expect(scaleY.min, closeTo(2.4, 0.05));
        expect(scaleY.max, closeTo(4170, 5));

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

        expect(scaleY.min, equals(1));
        expect(scaleY.max, equals(10000));

        chart.resetZoom();

        expect(scaleY.min, equals(1));
        expect(scaleY.max, equals(10000));

        triggerWheelEvent(
          chart,
          x: zoomOut.x,
          y: zoomOut.y,
          deltaY: zoomOut.deltaY,
        );

        expect(scaleY.min, closeTo(0.6, 0.05));
        expect(scaleY.max, closeTo(16700, 50));

        triggerWheelEvent(
          chart,
          x: zoomIn.x,
          y: zoomIn.y,
          deltaY: zoomIn.deltaY,
        );

        expect(scaleY.min, closeTo(1, 0.005));
        expect(scaleY.max, closeTo(10000, 0.005));
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
            'zoom': const ZoomPluginOptions(
              zoom: ZoomOptions(
                drag: DragOptions(enabled: true, maintainAspectRatio: true),
                mode: Mode.xy,
              ),
            ),
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

      expect(scaleX.options.min, closeTo(1.5, 0.005));
      expect(scaleX.options.max, closeTo(2.1, 0.005));
      expect(scaleY.options.min, closeTo(1.1, 0.005));
      expect(scaleY.options.max, closeTo(1.7, 0.005));
    });

    group('events', () {
      testWidgets('should call onZoomStart, onZoom and onZoomComplete', (
        tester,
      ) async {
        await waitForDone((done) {
          // `createSpy('start')`: the contexts of the calls.
          final startCalls = <ZoomStartContext<NativeEvent>>[];
          // `createSpy('zoom')`: the contexts of the calls.
          final zoomCalls = <ZoomTriggerContext>[];
          final chart = acquireChart(<String, Object?>{
            'type': 'scatter',
            'data': data(),
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'zoom': ZoomPluginOptions(
                  zoom: ZoomOptions(
                    wheel: const WheelOptions(enabled: true),
                    mode: Mode.xy,
                    onZoomStart: (context) {
                      startCalls.add(context);
                      return true;
                    },
                    onZoom: zoomCalls.add,
                    onZoomComplete: (_) => done(),
                  ),
                ),
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

          expect(startCalls, isNotEmpty);
          expect(
            zoomCalls,
            contains((chart: chart, trigger: ZoomTrigger.wheel)),
          );
          expect(chart.scales['x']!.min, isNot(equals(1)));
        });
      });

      testWidgets('should detect configuration change', (tester) async {
        // `createSpy('started')`: the contexts of the calls.
        final startCalls = <ZoomStartContext<NativeEvent>>[];
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': data(),
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': ZoomPluginOptions(
                zoom: ZoomOptions(
                  wheel: const WheelOptions(enabled: false),
                  mode: Mode.xy,
                  onZoomStart: (context) {
                    startCalls.add(context);
                    return true;
                  },
                ),
              ),
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
        expect(startCalls, isEmpty);
        expect(chart.scales['x']!.min, equals(1));

        // chart.options.plugins.zoom.zoom.wheel.enabled = true: the options
        // are one immutable object (Chart.js ADR 0148), so the write gives
        // the plugins scope of the chart a new object, through the face of
        // the options of the chart.
        // DIVERGES(zoom): adapt-native-zoom-options, a new options object.
        final plugins = chart.options['plugins']! as JsObjectFace;
        plugins['zoom'] = (plugins['zoom']! as ZoomPluginOptions).merge(
          const ZoomPluginOptions(
            zoom: ZoomOptions(wheel: WheelOptions(enabled: true)),
          ),
        );
        chart.update();

        triggerWheelEvent(
          chart,
          x: wheelEv.x,
          y: wheelEv.y,
          deltaY: wheelEv.deltaY,
        );
        expect(startCalls, isNotEmpty);
        expect(chart.scales['x']!.min, isNot(equals(1)));
      });

      testWidgets('should call onZoomRejected when onZoomStart returns false', (
        tester,
      ) async {
        // `createSpy('rejected')`: the contexts of the calls.
        final rejectCalls = <ZoomEventContext<NativeEvent>>[];
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': data(),
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': ZoomPluginOptions(
                zoom: ZoomOptions(
                  wheel: const WheelOptions(enabled: true),
                  mode: Mode.xy,
                  onZoomStart: (_) => false,
                  onZoomRejected: rejectCalls.add,
                ),
              ),
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
        expect(rejectCalls, isNotEmpty);
        expect(chart.scales['x']!.min, equals(1));
      });
    });
  });
}
