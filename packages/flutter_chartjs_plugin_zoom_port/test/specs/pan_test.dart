// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/pan.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart';

/// Acquires a chart through the typed config boundary.
Chart _acquire(ChartConfig config, [Map<String, Object?>? options]) =>
    acquireChartRoot(ChartConfigLowering(config).lower(), options);

void main() {
  group('pan', () {
    final points = [DataPoint(1, 3), DataPoint(2, 2), DataPoint(3, 1)];

    group('delta', () {
      testWidgets('should be applied cumulatively', (tester) async {
        final chart = _acquire(
          ChartConfig(
            datasets: [LineDataset(points: points)],
            labels: const ['a', 'b', 'c', 'd', 'e'],
            pluginOptions: const [
              ZoomPluginOptions(pan: PanOptions(enabled: true, mode: Mode.x)),
            ],
            scales: const {
              'x': CategoryAxis(extra: {'min': 1, 'max': 2}),
            },
          ),
        );
        final scale = chart.scales['x']!;
        expect(scale.min, equals(1));
        expect(scale.max, equals(2));
        chart.pan(const .all(20));
        expect(scale.min, equals(1));
        expect(scale.max, equals(2));
        chart.pan(const .all(20));
        expect(scale.min, equals(1));
        expect(scale.max, equals(2));
        chart.pan(const .all(20));
        expect(scale.min, equals(0));
        expect(scale.max, equals(1));
      });

      testWidgets('should not give credit', (tester) async {
        final chart = _acquire(
          ChartConfig(
            datasets: [ScatterDataset(points: points)],
            labels: const ['a', 'b', 'c', 'd', 'e'],
            pluginOptions: const [
              ZoomPluginOptions(
                limits: {'x': ScaleLimits(max: ScaleLimit(4))},
                pan: PanOptions(enabled: true, mode: Mode.x),
              ),
            ],
            scales: const {'x': LinearAxis(min: 1, max: 3)},
          ),
        );
        final scale = chart.scales['x']!;
        expect(scale.min, equals(1));
        expect(scale.max, equals(3));
        chart.pan(const .all(-2000));
        expect(scale.min, equals(1));
        expect(scale.max, equals(3));
        chart.pan(const .all(-2000));
        expect(scale.min, equals(1));
        expect(scale.max, equals(3));
        chart.pan(const .all(50));
        expect(scale.min, lessThan(2));
        expect(scale.max, equals(scale.min + 2));
      });

      testWidgets('should handle zero-dimension scales', (tester) async {
        final chart = _acquire(
          ChartConfig(
            datasets: [LineDataset(points: points)],
            labels: const ['a', 'b', 'c', 'd', 'e'],
            pluginOptions: const [
              ZoomPluginOptions(pan: PanOptions(enabled: true, mode: Mode.y)),
            ],
            scales: const {'y': LinearAxis(min: 2, max: 2)},
          ),
        );
        final scale = chart.scales['y']!;
        expect(scale.min, equals(2));
        expect(scale.max, equals(2));
        chart.pan(const .all(50));
        expect(scale.min, equals(2));
        expect(scale.max, equals(2));
        expect(scale.options.min, equals(2));
        expect(scale.options.max, equals(2));
      });

      testWidgets('should respect original limits', (tester) async {
        final chart = _acquire(
          ChartConfig(
            datasets: [LineDataset(points: points)],
            labels: const ['a', 'b', 'c', 'd', 'e'],
            pluginOptions: const [
              ZoomPluginOptions(
                pan: PanOptions(enabled: true, mode: Mode.x),
                limits: {
                  'x': ScaleLimits(
                    min: ScaleLimit.original,
                    max: ScaleLimit.original,
                  ),
                },
              ),
            ],
            scales: const {
              'x': CategoryAxis(extra: {'min': 1, 'max': 2}),
            },
          ),
        );
        final scale = chart.scales['x']!;
        expect(scale.min, equals(1));
        expect(scale.max, equals(2));
        chart.pan(const .all(100));
        expect(scale.min, equals(1));
        expect(scale.max, equals(2));
      });

      testWidgets('should respect original limits for nonlinear scales', (
        tester,
      ) async {
        final chart = _acquire(
          ChartConfig(
            datasets: [LineDataset(points: points)],
            labels: const ['a', 'b', 'c', 'd', 'e'],
            pluginOptions: const [
              ZoomPluginOptions(
                pan: PanOptions(enabled: true, mode: Mode.x),
                limits: {
                  'x': ScaleLimits(
                    min: ScaleLimit.original,
                    max: ScaleLimit.original,
                  ),
                },
              ),
            ],
            scales: const {'x': LogarithmicAxis(min: 1, max: 10)},
          ),
        );
        final scale = chart.scales['x']!;
        expect(scale.min, equals(1));
        expect(scale.max, equals(10));
        chart.pan(const .all(100));
        expect(scale.min, equals(1));
        expect(scale.max, equals(10));
      });
    });

    group('events', () {
      testWidgets('should call onPanStart', (tester) async {
        await waitForDone((done) {
          // `createSpy('started')`: the contexts of the calls.
          final startCalls = <ZoomStartContext<GestureEvent>>[];
          final chart = _acquire(
            ChartConfig(
              datasets: [ScatterDataset(points: points)],
              labels: const ['a', 'b', 'c', 'd', 'e'],
              pluginOptions: [
                ZoomPluginOptions(
                  pan: PanOptions(
                    enabled: true,
                    mode: Mode.xy,
                    onPanStart: (context) {
                      startCalls.add(context);
                      return true;
                    },
                  ),
                ),
              ],
            ),
          );

          simulatePan(
            chart,
            deltaX: -350,
            done: () {
              expect(startCalls, isNotEmpty);
              expect(chart.scales['x']!.min, isNot(equals(1)));
              done();
            },
          );
        });
      });

      testWidgets('should call onPanRejected when onStartPan returns false', (
        tester,
      ) async {
        await waitForDone((done) {
          // `createSpy('rejected')`: the contexts of the calls.
          final rejectCalls = <ZoomEventContext<GestureEvent>>[];
          final chart = _acquire(
            ChartConfig(
              datasets: [ScatterDataset(points: points)],
              labels: const ['a', 'b', 'c', 'd', 'e'],
              pluginOptions: [
                ZoomPluginOptions(
                  pan: PanOptions(
                    enabled: true,
                    mode: Mode.xy,
                    onPanStart: (_) => false,
                    onPanRejected: rejectCalls.add,
                  ),
                ),
              ],
            ),
          );

          simulatePan(
            chart,
            deltaX: -350,
            done: () {
              // The rejection must not be repeated for every move of the
              // same gesture.
              expect(rejectCalls, hasLength(1));
              expect(chart.scales['x']!.min, equals(1));
              done();
            },
          );
        });
      });

      testWidgets(
        'should call onPanRejected when the modifier key is not pressed',
        (tester) async {
          await waitForDone((done) {
            // `createSpy('rejected')`: the contexts of the calls.
            final rejectCalls = <ZoomEventContext<GestureEvent>>[];
            final chart = _acquire(
              ChartConfig(
                datasets: [ScatterDataset(points: points)],
                labels: const ['a', 'b', 'c', 'd', 'e'],
                pluginOptions: [
                  ZoomPluginOptions(
                    pan: PanOptions(
                      enabled: true,
                      mode: Mode.xy,
                      modifierKey: ModifierKey.ctrl,
                      onPanRejected: rejectCalls.add,
                    ),
                  ),
                ],
              ),
            );

            simulatePan(
              chart,
              deltaX: -350,
              init: const EventInit(pointerType: 'mouse'),
              done: () {
                expect(rejectCalls, isNotEmpty);
                expect(chart.scales['x']!.min, equals(1));

                simulatePan(
                  chart,
                  deltaX: -350,
                  init: const EventInit(pointerType: 'mouse', ctrlKey: true),
                  done: () {
                    expect(chart.scales['x']!.min, isNot(equals(1)));
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
          final chart = _acquire(
            ChartConfig(
              datasets: [ScatterDataset(points: points)],
              labels: const ['a', 'b', 'c', 'd', 'e'],
              pluginOptions: const [
                ZoomPluginOptions(
                  pan: PanOptions(enabled: true, mode: Mode.xy),
                ),
              ],
            ),
          );

          simulatePan(
            chart,
            deltaX: -350,
            init: const EventInit(pointerType: 'mouse', button: 2),
            done: () {
              expect(chart.scales['x']!.min, equals(1));
              done();
            },
          );
        });
      });

      testWidgets('should call onPanComplete', (tester) async {
        await waitForDone((done) {
          final chart = _acquire(
            ChartConfig(
              datasets: [ScatterDataset(points: points)],
              labels: const ['a', 'b', 'c', 'd', 'e'],
              pluginOptions: [
                ZoomPluginOptions(
                  pan: PanOptions(
                    enabled: true,
                    mode: Mode.xy,
                    onPanComplete: (ctx) {
                      expect(ctx.chart.scales['x']!.min, isNot(equals(1)));
                      done();
                    },
                  ),
                ),
              ],
            ),
          );
          simulatePan(chart, deltaX: -350);
        });
      });

      testWidgets('should end the pan when a second pointer goes down', (
        tester,
      ) async {
        // `createSpy('completed')`: the contexts of the calls.
        final completeCalls = <ZoomChartContext>[];
        final chart = _acquire(
          ChartConfig(
            datasets: [ScatterDataset(points: points)],
            labels: const ['a', 'b', 'c', 'd', 'e'],
            pluginOptions: [
              ZoomPluginOptions(
                pan: PanOptions(
                  enabled: true,
                  mode: Mode.xy,
                  onPanComplete: completeCalls.add,
                ),
              ),
            ],
          ),
        );

        final node = chart.canvas!;
        final rect = node.getBoundingClientRect();
        final x = rect.left + rect.width / 2;
        final y = rect.top + rect.height / 2;
        const dispatch = dispatchPointer;

        dispatch(node, 'pointerdown', 1, x, y);
        dispatch(node, 'pointermove', 1, x - 50, y);
        expect(chart.scales['x']!.min, isNot(equals(1)));

        // The pan ends even though pinch is disabled and no zoom takes over.
        dispatch(node, 'pointerdown', 2, x + 200, y);
        expect(completeCalls, hasLength(1));

        // Lifting the first pointer must not let the second one resume that
        // pan from the old start position, which would jump the chart.
        final min = chart.scales['x']!.min;
        dispatch(node, 'pointerup', 1, x - 50, y);
        dispatch(node, 'pointermove', 2, x + 200, y);
        expect(chart.scales['x']!.min, equals(min));

        dispatch(node, 'pointerup', 2, x + 200, y);
        expect(completeCalls, hasLength(1));
      });

      testWidgets('should not complete the pan when the gesture is cancelled', (
        tester,
      ) async {
        // `createSpy('completed')`: the contexts of the calls.
        final completeCalls = <ZoomChartContext>[];
        final chart = _acquire(
          ChartConfig(
            datasets: [ScatterDataset(points: points)],
            labels: const ['a', 'b', 'c', 'd', 'e'],
            pluginOptions: [
              ZoomPluginOptions(
                pan: PanOptions(
                  enabled: true,
                  mode: Mode.xy,
                  onPanComplete: completeCalls.add,
                ),
              ),
            ],
          ),
        );

        final node = chart.canvas!;
        final rect = node.getBoundingClientRect();
        final x = rect.left + rect.width / 2;
        final y = rect.top + rect.height / 2;
        const dispatch = dispatchPointer;

        dispatch(node, 'pointerdown', 1, x, y);
        dispatch(node, 'pointermove', 1, x - 50, y);
        dispatch(node, 'pointercancel', 1, x - 50, y);
        expect(completeCalls, isEmpty);

        // The aborted pan must not be resumed by the next one.
        final min = chart.scales['x']!.min;
        dispatch(node, 'pointerdown', 1, x, y);
        dispatch(node, 'pointermove', 1, x - 5, y);
        expect(chart.scales['x']!.min, equals(min));
      });
    });
  });
}
