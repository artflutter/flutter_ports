// Original code, not ported from Chart.js: stack-search drawing equivalence.
@TestOn('vm')
library;

import 'dart:ui';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show
        CategoryAxis,
        ChartAnimation,
        ChartConfig,
        ChartKind,
        ChartValue,
        LineDataset,
        LinearAxis,
        ScaleDisplay;
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/stack_point_search.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_chartjs_port/src/types/chart_meta.dart' show StackMode;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_test/flutter_test.dart';

import '../../scales/scale_chart_harness.dart' show drawCalls;

void main() {
  tearDown(() => stackPointSearchEnabled = true);
  testWidgets('a real aligned stack takes the shortcut and keeps draw calls', (
    tester,
  ) async {
    final config = ChartConfig(
      type: ChartKind.line,
      labels: [for (var i = 0; i < 64; i++) '$i'],
      datasets: [
        for (var k = 0; k < 3; k++)
          LineDataset(
            data: [for (var i = 0; i < 64; i++) 1 + (i + k) % 7],
            fill: FillTarget.toStacked,
            pointRadius: 0,
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
      scales: const {
        'x': CategoryAxis(display: ScaleDisplay.off),
        'y': LinearAxis(display: ScaleDisplay.off, stacked: StackMode.on),
      },
      extra: const {
        'plugins': {'legend': false, 'tooltip': false},
      },
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
