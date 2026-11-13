// Original code, not ported from chartjs-plugin-zoom: native callbacks.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' show acquireChart;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show Chart, NativeEvent;
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart';

/// A scatter chart from 0 to 100 on both axes with the zoom options [zoom].
Chart _chart(Map<String, Object?> zoom) => acquireChart(<String, Object?>{
  'type': 'scatter',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[
          <String, Object?>{'x': 0, 'y': 0},
          <String, Object?>{'x': 100, 'y': 100},
        ],
      },
    ],
  },
  'options': <String, Object?>{
    'plugins': <String, Object?>{
      'zoom': <String, Object?>{'zoom': zoom},
    },
  },
});

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

void main() {
  group('native zoom callbacks (Zoom ADR 0004)', () {
    testWidgets('a start callback that returns true starts the wheel zoom', (
      tester,
    ) async {
      final starts = <ZoomStartContext<NativeEvent>>[];
      final chart = _chart(<String, Object?>{
        'wheel': <String, Object?>{'enabled': true},
        'mode': Mode.x,
        'onZoomStart': (ZoomStartContext<NativeEvent> context) {
          starts.add(context);
          return true;
        },
      });

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
      final chart = _chart(<String, Object?>{
        'wheel': <String, Object?>{'enabled': true},
        'mode': Mode.x,
        'onZoomStart': (ZoomStartContext<NativeEvent> _) => false,
        'onZoomRejected': rejected.add,
      });

      _wheel(chart);

      expect(rejected, hasLength(1));
      expect(chart.scales['x']!.min, 0);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('a ModeFn selects the zoom directions', (tester) async {
      final calls = <Chart>[];
      final chart = _chart(<String, Object?>{
        'mode': (ZoomChartContext context) {
          calls.add(context.chart);
          return Mode.y;
        },
      })..zoom(const .all(2));

      expect(calls, isNotEmpty);
      expect(calls.every((value) => identical(value, chart)), isTrue);
      expect(chart.scales['x']!.min, 0);
      expect(chart.scales['y']!.min, greaterThan(0));
    });

    testWidgets('a callback of another type stops a debug build', (
      tester,
    ) async {
      final chart = _chart(<String, Object?>{'onZoom': () {}});

      expect(() => chart.zoom(const .all(2)), throwsA(isA<AssertionError>()));
    });

    testWidgets('a mode function of another type stops a debug build', (
      tester,
    ) async {
      final chart = _chart(<String, Object?>{'mode': () => Mode.x});

      expect(() => chart.zoom(const .all(2)), throwsA(isA<AssertionError>()));
    });
  });
}
