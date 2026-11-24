// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/zoom.drag.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' hide triggerMouseEvent;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart';

/// Acquires a chart through the typed config boundary.
Chart _acquire(ChartConfig config, [AcquireOptions? options]) =>
    acquireChartRoot(ChartConfigLowering(config).lower(), options);

void main() {
  group('zoom with drag', () {
    // zoom.drag.spec.js:2 `const data = {...}`: one object for all the
    // charts of the file. The function gives a new object for each chart,
    // with the same values: a test of a CI shard does not need the charts of
    // the earlier tests of its file.
    List<DataPoint> points() => [
      DataPoint(1, 3),
      DataPoint(2, 2),
      DataPoint(3, 1),
    ];

    group('on linear scale', () {
      late Chart chart;
      late Scale scaleX;
      late Scale scaleY;

      testWidgets('should be applied on X scale when mode = x', (tester) async {
        chart = _acquire(
          ChartConfig(
            datasets: [LineDataset(data: .points(points()))],
            scales: const [LinearAxis(.x), LinearAxis(.y)],
            pluginOptions: const [
              ZoomPluginOptions(
                zoom: ZoomOptions(
                  drag: DragOptions(enabled: true),
                  mode: Mode.x,
                ),
              ),
            ],
          ),
        );

        scaleX = chart.scales['x']!;
        scaleY = chart.scales['y']!;

        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(1.5),
          y: scaleY.getPixelForValue(1.1),
        ));
        triggerMouseEvent(chart, 'mouseup', (
          x: scaleX.getPixelForValue(2.8),
          y: scaleY.getPixelForValue(1.7),
        ));

        expect(scaleX.options.min, closeTo(1.5, 0.005));
        expect(scaleX.options.max, closeTo(2.8, 0.005));
        expect(scaleY.options.min, same(undefined));
        expect(scaleY.options.max, same(undefined));
      });

      testWidgets('should be applied on X scale when mode = f() => x', (
        tester,
      ) async {
        chart = _acquire(
          ChartConfig(
            datasets: [LineDataset(data: .points(points()))],
            scales: const [LinearAxis(.x), LinearAxis(.y)],
            pluginOptions: [
              ZoomPluginOptions(
                zoom: ZoomOptions(
                  drag: const DragOptions(enabled: true),
                  mode: ModeFromChart((_) {
                    return Mode.x;
                  }),
                ),
              ),
            ],
          ),
        );

        scaleX = chart.scales['x']!;
        scaleY = chart.scales['y']!;

        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(1.5),
          y: scaleY.getPixelForValue(1.1),
        ));
        triggerMouseEvent(chart, 'mouseup', (
          x: scaleX.getPixelForValue(2.8),
          y: scaleY.getPixelForValue(1.7),
        ));

        expect(scaleX.options.min, closeTo(1.5, 0.005));
        expect(scaleX.options.max, closeTo(2.8, 0.005));
        expect(scaleY.options.min, same(undefined));
        expect(scaleY.options.max, same(undefined));
      });

      testWidgets('should be applied on Y scale when mode = y', (tester) async {
        chart = _acquire(
          ChartConfig(
            datasets: [LineDataset(data: .points(points()))],
            scales: const [LinearAxis(.x), LinearAxis(.y)],
            pluginOptions: const [
              ZoomPluginOptions(
                zoom: ZoomOptions(
                  drag: DragOptions(enabled: true),
                  mode: Mode.y,
                ),
              ),
            ],
          ),
        );

        scaleX = chart.scales['x']!;
        scaleY = chart.scales['y']!;

        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(1.5),
          y: scaleY.getPixelForValue(1.1),
        ));
        triggerMouseEvent(chart, 'mouseup', (
          x: scaleX.getPixelForValue(2.8),
          y: scaleY.getPixelForValue(1.7),
        ));

        expect(scaleX.options.min, same(undefined));
        expect(scaleX.options.max, same(undefined));
        expect(scaleY.options.min, closeTo(1.1, 0.005));
        expect(scaleY.options.max, closeTo(1.7, 0.005));
      });

      testWidgets('should be applied on Y scale when mode = f() => y', (
        tester,
      ) async {
        chart = _acquire(
          ChartConfig(
            datasets: [LineDataset(data: .points(points()))],
            scales: const [LinearAxis(.x), LinearAxis(.y)],
            pluginOptions: [
              ZoomPluginOptions(
                zoom: ZoomOptions(
                  drag: const DragOptions(enabled: true),
                  mode: ModeFromChart((_) {
                    return Mode.y;
                  }),
                ),
              ),
            ],
          ),
        );

        scaleX = chart.scales['x']!;
        scaleY = chart.scales['y']!;

        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(1.5),
          y: scaleY.getPixelForValue(1.1),
        ));
        triggerMouseEvent(chart, 'mouseup', (
          x: scaleX.getPixelForValue(2.8),
          y: scaleY.getPixelForValue(1.7),
        ));

        expect(scaleX.options.min, same(undefined));
        expect(scaleX.options.max, same(undefined));
        expect(scaleY.options.min, closeTo(1.1, 0.005));
        expect(scaleY.options.max, closeTo(1.7, 0.005));
      });

      testWidgets('should be applied on X and Y scales when mode = xy', (
        tester,
      ) async {
        chart = _acquire(
          ChartConfig(
            datasets: [LineDataset(data: .points(points()))],
            scales: const [LinearAxis(.x), LinearAxis(.y)],
            pluginOptions: const [
              ZoomPluginOptions(
                zoom: ZoomOptions(
                  drag: DragOptions(enabled: true),
                  mode: Mode.xy,
                ),
              ),
            ],
          ),
        );

        scaleX = chart.scales['x']!;
        scaleY = chart.scales['y']!;

        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(1.5),
          y: scaleY.getPixelForValue(1.1),
        ));
        triggerMouseEvent(chart, 'mouseup', (
          x: scaleX.getPixelForValue(2.8),
          y: scaleY.getPixelForValue(1.7),
        ));

        expect(scaleX.options.min, closeTo(1.5, 0.005));
        expect(scaleX.options.max, closeTo(2.8, 0.005));
        expect(scaleY.options.min, closeTo(1.1, 0.005));
        expect(scaleY.options.max, closeTo(1.7, 0.005));
      });
    });

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
            chart = _acquire(
              ChartConfig(
                datasets: [LineDataset(data: .points(points()))],
                scales: const [LinearAxis(.x, min: 0, max: 10), LinearAxis(.y)],
                pluginOptions: [
                  ZoomPluginOptions(
                    zoom: ZoomOptions(
                      drag: DragOptions(enabled: true, modifierKey: key),
                      mode: Mode.x,
                      onZoomRejected: rejectedCalls.add,
                    ),
                  ),
                ],
              ),
            );

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

    group('drag with pan.modifierKey', () {
      for (final key in ModifierKey.values) {
        for (final pressed in [true, false]) {
          late Chart chart;
          late Scale scaleX;
          late Scale scaleY;
          testWidgets('should ${pressed ? 'not ' : ''}change '
              '${pressed ? 'without' : 'with'} key ${key.name}', (
            tester,
          ) async {
            // `createSpy('zoomRejected')`: the contexts of the calls.
            final rejectedCalls = <ZoomEventContext<NativeEvent>>[];
            // `createSpy('clicked')`: the events of the calls.
            final clickCalls = <ChartEvent>[];
            chart = _acquire(
              ChartConfig(
                datasets: [LineDataset(data: .points(points()))],
                scales: const [LinearAxis(.x, min: 0, max: 10), LinearAxis(.y)],
                pluginOptions: [
                  ZoomPluginOptions(
                    pan: PanOptions(enabled: true, modifierKey: key),
                    zoom: ZoomOptions(
                      drag: const DragOptions(enabled: true),
                      mode: Mode.x,
                      onZoomRejected: rejectedCalls.add,
                    ),
                  ),
                ],
                onClick: (
                  event,
                  elements,
                  _,
                ) => clickCalls.add(event),
              ),
            );

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
              expect(scaleX.options.min, equals(oldMinX));
              expect(scaleX.options.max, equals(oldMaxX));
              expect(rejectedCalls, isNotEmpty);
            } else {
              expect(scaleX.options.min, isNot(equals(oldMinX)));
              expect(scaleX.options.max, isNot(equals(oldMaxX)));
              expect(rejectedCalls, isEmpty);
            }
            expect(clickCalls, isEmpty);
          });
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
        chart = _acquire(
          ChartConfig(
            datasets: [LineDataset(data: .points(points()))],
            scales: const [
              LinearAxis(.x, min: 0, max: 4),
              LinearAxis(.y, min: 0, max: 4),
            ],
            pluginOptions: const [
              ZoomPluginOptions(
                zoom: ZoomOptions(
                  drag: DragOptions(enabled: true),
                  mode: Mode.xy,
                ),
              ),
            ],
          ),
          const AcquireOptions(
            wrapper: HarnessBox(absolute: true, offset: Offset(50, 50)),
          ),
        );

        scaleX = chart.scales['x']!;
        scaleY = chart.scales['y']!;

        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(1.5),
          y: scaleY.getPixelForValue(1.2),
        ));
        triggerMouseEvent(chart, 'mouseup', (
          x: scaleX.getPixelForValue(4) + 5,
          y: scaleY.getPixelForValue(1.7),
        ));

        expect(scaleX.options.min, closeTo(1.5, 0.005));
        expect(scaleX.options.max, closeTo(4, 0.005));
        expect(scaleY.options.min, closeTo(1.2, 0.005));
        expect(scaleY.options.max, closeTo(1.7, 0.005));
      });

      testWidgets('handles dragging off the right edge of the chart canvas', (
        tester,
      ) async {
        chart = _acquire(
          ChartConfig(
            datasets: [LineDataset(data: .points(points()))],
            scales: const [
              LinearAxis(.x, min: 0, max: 4),
              LinearAxis(.y, min: 0, max: 4),
            ],
            pluginOptions: const [
              ZoomPluginOptions(
                zoom: ZoomOptions(
                  drag: DragOptions(enabled: true),
                  mode: Mode.xy,
                ),
              ),
            ],
          ),
          const AcquireOptions(
            wrapper: HarnessBox(absolute: true, offset: Offset(50, 50)),
          ),
        );

        scaleX = chart.scales['x']!;
        scaleY = chart.scales['y']!;

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

        expect(scaleX.options.min, closeTo(1.5, 0.005));
        expect(scaleX.options.max, closeTo(4, 0.005));
        expect(scaleY.options.min, closeTo(1.2, 0.005));
        expect(scaleY.options.max, closeTo(1.7, 0.005));
      });
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
          final chart = _acquire(
            ChartConfig(
              datasets: [ScatterDataset(data: .points(points()))],
              pluginOptions: [
                ZoomPluginOptions(
                  zoom: ZoomOptions(
                    drag: const DragOptions(enabled: true),
                    mode: Mode.xy,
                    onZoomStart: (context) {
                      startCalls.add(context);
                      return true;
                    },
                    onZoom: zoomCalls.add,
                    onZoomComplete: (_) => done(),
                  ),
                ),
              ],
            ),
          );

          final pt = (
            x: chart.scales['x']!.getPixelForValue(1.5),
            y: chart.scales['y']!.getPixelForValue(1.1),
          );
          final pt2 = (x: pt.x + 20, y: pt.y + 20);

          expect(chart.isZoomingOrPanning(), equals(false));

          dispatchEvent(chart, 'mousedown', pt);
          dispatchEvent(chart, 'mousemove', pt2);

          expect(chart.isZoomingOrPanning(), equals(true));

          dispatchEvent(chart, 'mouseup', pt2);

          // Drag state isn't cleared until a timeout fires (later), so we
          // can't easily test this here.
          // expect(chart.isZoomingOrPanning()).equals(false);

          expect(startCalls, isNotEmpty);
          expect(
            zoomCalls,
            contains((chart: chart, trigger: ZoomTrigger.drag)),
          );
        });
      });

      testWidgets('should call onZoomRejected when onZoomStart returns false', (
        tester,
      ) async {
        // `createSpy('zoom')`: the contexts of the calls.
        final zoomCalls = <ZoomTriggerContext>[];
        // `createSpy('reject')`: the contexts of the calls.
        final rejectCalls = <ZoomEventContext<NativeEvent>>[];
        // `createSpy('done')`: the contexts of the calls.
        final doneCalls = <ZoomChartContext>[];
        final chart = _acquire(
          ChartConfig(
            datasets: [ScatterDataset(data: .points(points()))],
            pluginOptions: [
              ZoomPluginOptions(
                zoom: ZoomOptions(
                  drag: const DragOptions(enabled: true),
                  mode: Mode.xy,
                  onZoomStart: (_) => false,
                  onZoom: zoomCalls.add,
                  onZoomComplete: doneCalls.add,
                  onZoomRejected: rejectCalls.add,
                ),
              ),
            ],
          ),
        );

        final pt = (
          x: chart.scales['x']!.getPixelForValue(1.5),
          y: chart.scales['y']!.getPixelForValue(1.1),
        );
        final pt2 = (x: pt.x + 20, y: pt.y + 20);

        expect(chart.isZoomingOrPanning(), equals(false));

        dispatchEvent(chart, 'mousedown', pt);

        expect(chart.isZoomingOrPanning(), equals(false));

        dispatchEvent(chart, 'mousemove', pt2);
        dispatchEvent(chart, 'mouseup', pt2);

        expect(chart.isZoomingOrPanning(), equals(false));

        expect(rejectCalls, isNotEmpty);
        expect(zoomCalls, isEmpty);
        expect(doneCalls, isEmpty);
      });
    });
  });
}
