// Original code, not ported from Chart.js: stack-search drawing equivalence.
@TestOn('vm')
library;

import 'dart:ui';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scales/scale_chart_harness.dart' show drawCalls;

void main() {
  tearDown(() => stackPointSearchEnabled = true);
  testWidgets('a real aligned stack takes the shortcut and keeps draw calls', (
    tester,
  ) async {
    final config = ChartConfig(
      labels: [for (var i = 0; i < 64; i++) '$i'],
      datasets: [
        for (var k = 0; k < 3; k++)
          LineDataset(
            data: .values([for (var i = 0; i < 64; i++) 1 + (i + k) % 7]),
            fill: FillTarget.toStacked,
            pointRadius: const .constant(0),
            backgroundColor: ChartValue.constant(
              ChartPaint.solid(Color.fromARGB(100, 30 + 60 * k, 80, 160)),
            ),
            borderColor: const ChartValue.constant(
              ChartPaint.solid(Color(0xff123456)),
            ),
          ),
      ],
      animation: ChartAnimation.none,
      responsive: false,
      scales: const [
        CategoryAxis(.x, display: ScaleDisplay.off),
        LinearAxis(.y, display: ScaleDisplay.off, stacked: StackMode.on),
      ],
      disabledPlugins: const [
        PluginOff<LegendPlugin>(),
        PluginOff<TooltipPlugin>(),
      ],
    );
    final chart = acquireChartRoot(ChartConfigLowering(config).lower());
    final source = chart.getDatasetMeta(2).dataset! as LineElement;
    final target = chart.getDatasetMeta(1).dataset! as LineElement;
    final search = StackPointSearch.create(
      source,
      source.points,
      source.segments,
      1,
    )!;
    expect(
      search.find(0, target, source.points[20])!.point,
      same(target.points[20]),
    );
    stackPointSearchEnabled = false;
    final original = drawCalls(chart);
    stackPointSearchEnabled = true;
    expect(drawCalls(chart), original);
  });
}
