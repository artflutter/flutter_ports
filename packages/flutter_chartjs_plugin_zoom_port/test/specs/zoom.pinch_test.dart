// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/zoom.pinch.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart';

/// Acquires a chart through the typed config boundary.
Chart _acquire(ChartConfig config, [AcquireOptions? options]) =>
    acquireChartRoot(lowerForTest(config), options);

void main() {
  group('pinch', () {
    final points = [DataPoint(1, 3), DataPoint(2, 2), DataPoint(3, 1)];

    group('events', () {
      testWidgets('should call onZoomStart', (tester) async {
        await waitForDone((done) {
          // `createSpy('started')`: the contexts of the calls.
          final startCalls = <ZoomStartContext<NativeEvent>>[];
          final chart = _acquire(
            ChartConfig(
              datasets: [ScatterDataset(data: .points(points))],
              pluginOptions: [
                ZoomPluginOptions(
                  zoom: ZoomOptions(
                    mode: Mode.xy,
                    onZoomStart: (context) {
                      startCalls.add(context);
                      return true;
                    },
                    pinch: const PinchOptions(enabled: true),
                  ),
                ),
              ],
            ),
          );

          simulatePinch(
            chart,
            pos: (chart.width / 2, chart.height / 2),
            done: () {
              expect(startCalls, isNotEmpty);
              expect(chart.scales['x']!.min, isNot(equals(1)));
              done();
            },
          );
        });
      });

      testWidgets('should call onZoomRejected when onStartZoom returns false', (
        tester,
      ) async {
        await waitForDone((done) {
          // `createSpy('rejected')`: the contexts of the calls.
          final rejectCalls = <ZoomEventContext<NativeEvent>>[];
          final chart = _acquire(
            ChartConfig(
              datasets: [ScatterDataset(data: .points(points))],
              pluginOptions: [
                ZoomPluginOptions(
                  zoom: ZoomOptions(
                    mode: Mode.xy,
                    onZoomStart: (_) => false,
                    onZoomRejected: rejectCalls.add,
                    pinch: const PinchOptions(enabled: true),
                  ),
                ),
              ],
            ),
          );

          simulatePinch(
            chart,
            done: () {
              expect(rejectCalls, isNotEmpty);
              expect(chart.scales['x']!.min, equals(1));
              done();
            },
          );
        });
      });

      testWidgets('should call onZoomComplete', (tester) async {
        await waitForDone((done) {
          final chart = _acquire(
            ChartConfig(
              datasets: [ScatterDataset(data: .points(points))],
              pluginOptions: [
                ZoomPluginOptions(
                  zoom: ZoomOptions(
                    mode: Mode.xy,
                    onZoomComplete: (ctx) {
                      expect(ctx.chart.scales['x']!.min, isNot(equals(1)));
                      done();
                    },
                    pinch: const PinchOptions(enabled: true),
                  ),
                ),
              ],
            ),
          );
          simulatePinch(chart);
        });
      });

      testWidgets('should ignore a third pointer during a pinch', (
        tester,
      ) async {
        // `createSpy('started')`: the contexts of the calls.
        final startCalls = <ZoomStartContext<NativeEvent>>[];
        // `createSpy('completed')`: the contexts of the calls.
        final completeCalls = <ZoomChartContext>[];
        final chart = _acquire(
          ChartConfig(
            datasets: [ScatterDataset(data: .points(points))],
            pluginOptions: [
              ZoomPluginOptions(
                zoom: ZoomOptions(
                  mode: Mode.xy,
                  onZoomStart: (context) {
                    startCalls.add(context);
                    return true;
                  },
                  onZoomComplete: completeCalls.add,
                  pinch: const PinchOptions(enabled: true),
                ),
              ),
            ],
          ),
        );

        final node = chart.canvas!;
        final rect = node.getBoundingClientRect();
        final cx = rect.left + rect.width / 2;
        final cy = rect.top + rect.height / 2;
        const dispatch = dispatchPointer;

        dispatch(node, 'pointerdown', 1, cx - 40, cy);
        dispatch(node, 'pointerdown', 2, cx + 40, cy);
        expect(startCalls, hasLength(1));

        // A third finger neither restarts the pinch nor ends it when lifted.
        dispatch(node, 'pointerdown', 3, cx, cy + 100);
        expect(startCalls, hasLength(1));
        dispatch(node, 'pointerup', 3, cx, cy + 100);
        expect(completeCalls, isEmpty);

        dispatch(node, 'pointermove', 1, cx - 80, cy);
        dispatch(node, 'pointermove', 2, cx + 80, cy);
        expect(chart.scales['x']!.min, isNot(equals(1)));

        dispatch(node, 'pointerup', 1, cx - 80, cy);
        dispatch(node, 'pointerup', 2, cx + 80, cy);
        expect(completeCalls, hasLength(1));
      });
    });
  });
}
