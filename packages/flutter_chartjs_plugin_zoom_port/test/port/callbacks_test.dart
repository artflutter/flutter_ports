// Original code, not ported from chartjs-plugin-zoom: native callbacks.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart';

/// A scatter chart from 0 to 100 on both axes with the zoom options [zoom].
Chart _chart(ZoomOptions zoom) => _acquire(
  ChartConfig(
    type: ChartKind.scatter,
    datasets: [
      ScatterDataset(points: [DataPoint(0, 0), DataPoint(100, 100)]),
    ],
    pluginOptions: [ZoomPluginOptions(zoom: zoom)],
  ),
);

/// A wheel zoom in at the center of the chart area of [chart].
void _wheel(Chart chart) {
  final area = chart.chartArea!;
  triggerWheelEvent(
    chart,
    x: (area.left + area.right) / 2,
    y: (area.top + area.bottom) / 2,
    deltaY: -100,
  );
}

/// Acquires a chart through the typed config boundary.
Chart _acquire(ChartConfig config, [Map<String, Object?>? options]) =>
    acquireChartRoot(ChartConfigLowering(config).lower(), options);

void main() {
  group('native zoom callbacks (Zoom ADR 0004)', () {
    testWidgets('a start callback that returns true starts the wheel zoom', (
      tester,
    ) async {
      final starts = <ZoomStartContext<NativeEvent>>[];
      final chart = _chart(
        ZoomOptions(
          wheel: const WheelOptions(enabled: true),
          mode: Mode.x,
          onZoomStart: (context) {
            starts.add(context);
            return true;
          },
        ),
      );

      _wheel(chart);

      expect(starts, hasLength(1));
      expect(starts.single.chart, same(chart));
      expect(chart.scales['x']!.min, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('a start callback that returns false rejects the zoom', (
      tester,
    ) async {
      final rejected = <ZoomEventContext<NativeEvent>>[];
      final chart = _chart(
        ZoomOptions(
          wheel: const WheelOptions(enabled: true),
          mode: Mode.x,
          onZoomStart: (_) => false,
          onZoomRejected: rejected.add,
        ),
      );

      _wheel(chart);

      expect(rejected, hasLength(1));
      expect(chart.scales['x']!.min, 0);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('a ModeFn selects the zoom directions', (tester) async {
      final calls = <Chart>[];
      final chart = _chart(
        ZoomOptions(
          mode: (ZoomChartContext context) {
            calls.add(context.chart);
            return Mode.y;
          },
        ),
      )..zoom(const .all(2));

      expect(calls, isNotEmpty);
      expect(calls.every((value) => identical(value, chart)), isTrue);
      expect(chart.scales['x']!.min, 0);
      expect(chart.scales['y']!.min, greaterThan(0));
    });

    // A callback field has the type of its callback (Chart.js ADR 0148): a
    // function of another type does not compile, so the case cannot exist.
    test(
      'a callback of another type stops a debug build',
      () {},
      skip: 'diverges: adapt-native-zoom-options',
    );

    test('a mode function of another type stops a debug build', () {
      // `mode` is a Mode or a ModeFn (an Object? field): the constructor
      // asserts it.
      Object? noParameter() => Mode.x;
      expect(
        () => ZoomOptions(mode: noParameter),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PanOptions(scaleMode: noParameter),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
