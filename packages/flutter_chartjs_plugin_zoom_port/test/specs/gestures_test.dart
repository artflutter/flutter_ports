// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/gestures.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

/// Acquires a chart through the typed config boundary.
Chart _acquire(ChartConfig config, [Map<String, Object?>? options]) =>
    acquireChartRoot(ChartConfigLowering(config).lower(), options);

void main() {
  group('gesture manager', () {
    final points = [DataPoint(1, 3), DataPoint(2, 2), DataPoint(3, 1)];

    testWidgets('should disable text selection and browser touch actions while '
        'gestures are enabled', (tester) async {
      final chart = _acquire(
        ChartConfig(
          type: ChartKind.scatter,
          datasets: [ScatterDataset(points: points)],
          pluginOptions: const [
            ZoomPluginOptions(pan: PanOptions(enabled: true)),
          ],
        ),
      );

      expect(chart.canvas!.style.touchAction, equals('none'));
      expect(chart.canvas!.style.userSelect, equals('none'));
    });

    testWidgets(
      'should leave canvas styles untouched when neither pan nor pinch is '
      'enabled',
      (tester) async {
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.scatter,
            datasets: [ScatterDataset(points: points)],
            pluginOptions: const [
              ZoomPluginOptions(
                zoom: ZoomOptions(wheel: WheelOptions(enabled: true)),
              ),
            ],
          ),
        );

        expect(chart.canvas!.style.userSelect, equals(''));
        expect(chart.canvas!.style.touchAction, equals(''));
      },
    );
  });
}
