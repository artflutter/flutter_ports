// Original code, not ported from chartjs-plugin-zoom: the limits by axis.
@TestOn('vm')
library;

import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Zoom ADR 0007: the limits are an object with the direction keys `x` and
// `y` and the axis key `axes`. The limits of an axis win over the limits of
// its direction, as `limits[scale.id] || limits[scale.axis]` upstream. A
// const Map cannot have an axis key: an axis overrides `==`.

const _right = LinearAxis(.y, position: .right);

void main() {
  group('LimitOptions', () {
    test('merge merges each direction and each axis', () {
      final a = LimitOptions(
        x: const ScaleLimits(min: ScaleLimit(0)),
        axes: {_right: const ScaleLimits(min: ScaleLimit(1))},
      );
      final b = LimitOptions(
        x: const ScaleLimits(max: ScaleLimit(10)),
        y: const ScaleLimits(minRange: 2),
        axes: {_right: const ScaleLimits(max: ScaleLimit(5))},
      );
      expect(
        a.merge(b),
        LimitOptions(
          x: const ScaleLimits(min: ScaleLimit(0), max: ScaleLimit(10)),
          y: const ScaleLimits(minRange: 2),
          axes: {
            _right: const ScaleLimits(min: ScaleLimit(1), max: ScaleLimit(5)),
          },
        ),
      );
    });

    test('== compares the axes in any order', () {
      const top = LinearAxis(.x, position: .top);
      final one = LimitOptions(
        axes: {
          _right: const ScaleLimits(minRange: 1),
          top: const ScaleLimits(minRange: 2),
        },
      );
      final two = LimitOptions(
        axes: {
          top: const ScaleLimits(minRange: 2),
          _right: const ScaleLimits(minRange: 1),
        },
      );
      expect(one, two);
      expect(one.hashCode, two.hashCode);
      expect(one == const LimitOptions(), isFalse);
    });
  });

  testWidgets('the limits of an axis win over the limits of its direction', (
    tester,
  ) async {
    final limits = LimitOptions(
      y: const ScaleLimits(max: ScaleLimit(10)),
      axes: {_right: const ScaleLimits(max: ScaleLimit(500))},
    );
    Chart? chart;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartView(
            config: ChartConfig(
              labels: const ['a', 'b', 'c'],
              datasets: const [
                LineDataset(data: .values([1, 2, 3])),
                LineDataset(data: .values([30, 20, 10]), yAxis: _right),
              ],
              animation: ChartAnimation.none,
              scales: const [LinearAxis(.y), _right],
              pluginOptions: [ZoomPluginOptions(limits: limits)],
            ),
            onChartCreated: (value) => chart = value,
          ),
        ),
      ),
    );
    await tester.pump();
    final y = chart!.scales['y']!;
    final right = chart!.scaleOf(_right)!;
    expect(right.id, 'y1');
    expect(limits.of(y), const ScaleLimits(max: ScaleLimit(10)));
    expect(limits.of(right), const ScaleLimits(max: ScaleLimit(500)));
    expect(limits.of(chart!.scales['x']!), isNull);

    // Each zoom out by 0.01 makes the range about twice as large
    // (`zoomDelta`, scale.types.ts): ten of them pass both limits.
    for (var i = 0; i < 10; i++) {
      chart!.zoom(const .all(0.01));
    }
    await tester.pump();
    expect(y.max, 10);
    expect(right.max, 500);
  });
}
