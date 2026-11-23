// Original code, not ported from Chart.js: boundary search chart equivalence.
@TestOn('vm')
library;

import 'dart:ui';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scales/scale_chart_harness.dart' show drawCalls;

class _ObservedLine(LineElement original) extends LineElement {
  this {
    points = original.points;
    options = original.options;
    loop = original.loop ?? false;
  }

  int calls = 0;

  @override
  Object? interpolate(Point point, String property) {
    calls++;
    return super.interpolate(point, property);
  }
}

void main() {
  tearDown(() {
    boundaryPointSearchEnabled = true;
    boundarySegmentSearchEnabled = true;
  });
  testWidgets('a user dataset target keeps its interpolation callbacks', (
    tester,
  ) async {
    final config = ChartConfig(
      labels: [for (var i = 0; i < 64; i++) '$i'],
      datasets: [
        LineDataset(
          data: [for (var i = 0; i < 64; i++) 0],
          fill: FillTarget.none,
          pointRadius: const .constant(0),
        ),
        LineDataset(
          data: [
            for (var i = 0; i < 64; i++)
              if (i % 12 == 5) null else i % 7 - 3,
          ],
          fill: const FillTarget.toDataset(0),
          pointRadius: const .constant(0),
          backgroundColor: const ChartValue.constant(
            ChartPaint.solid(Color(0x88334455)),
          ),
        ),
      ],
      animation: ChartAnimation.none,
      responsive: false,
      disabledPlugins: const [
        PluginOff<LegendPlugin>(),
        PluginOff<TooltipPlugin>(),
      ],
    );
    final chart = acquireChartRoot(ChartConfigLowering(config).lower());
    final meta = chart.getDatasetMeta(0);
    final target = _ObservedLine(meta.dataset! as LineElement);
    meta.dataset = target;
    boundaryPointSearchEnabled = false;
    final original = drawCalls(chart);
    final calls = target.calls;
    expect(calls, greaterThan(0));
    target.calls = 0;
    boundaryPointSearchEnabled = true;
    expect(drawCalls(chart), original);
    expect(target.calls, calls);
  });
  for (final (axis, indexAxis) in const <(String, CartesianAxis)>[
    ('x', XAxis()),
    ('y', YAxis()),
  ]) {
    for (final fill in [
      FillTarget.toOrigin,
      FillTarget.toStart,
      FillTarget.toEnd,
    ]) {
      for (final reverse in [false, true]) {
        testWidgets(
          '$axis $fill reverse=$reverse preserves every draw command',
          (tester) async {
            final data = <List<num?>>[
              for (var k = 0; k < 3; k++)
                [
                  for (var i = 0; i < 64; i++)
                    if (i % 12 == 5) null else (i + k) % 7 - 3,
                ],
            ];
            final config = ChartConfig(
              labels: [for (var i = 0; i < 64; i++) '$i'],
              datasets: [
                for (var k = 0; k < 3; k++)
                  LineDataset(
                    data: data[k],
                    fill: fill.split(
                      above: const ChartPaint.solid(Color(0x88334455)),
                      below: const ChartPaint.solid(Color(0x88778899)),
                    ),
                    pointRadius: const .constant(0),
                    tension: k == 1 ? 0.4 : null,
                    stepped: k == 2 ? SteppedLine.middle : null,
                    borderColor: const ChartValue.constant(
                      ChartPaint.solid(Color(0xff123456)),
                    ),
                  ),
              ],
              indexAxis: indexAxis,
              animation: ChartAnimation.none,
              responsive: false,
              scales: [
                CategoryAxis(
                  axis == 'x' ? .x : .y,
                  display: ScaleDisplay.off,
                  reverse: reverse,
                ),
                LinearAxis(axis == 'x' ? .y : .x, display: ScaleDisplay.off),
              ],
              disabledPlugins: const [
                PluginOff<LegendPlugin>(),
                PluginOff<TooltipPlugin>(),
              ],
            );
            final chart = acquireChartRoot(ChartConfigLowering(config).lower());
            final source = fillerSourceOf(chart.getDatasetMeta(0))!;
            final target = getTarget(source)! as ILineElement;
            final search = BoundaryPointSearch.create(target, axis);
            if (!reverse) {
              expect(search, isNotNull);
              expect(search!.find(target.points[2]), same(target.points[2]));
              expect(
                search.bound((
                  property: axis,
                  start: axis == 'x' ? target.points[0].x : target.points[0].y,
                  end: axis == 'x' ? target.points[1].x : target.points[1].y,
                )),
                isNotNull,
              );
            } else {
              expect(search, isNull);
            }
            boundaryPointSearchEnabled = false;
            final original = drawCalls(chart);
            boundaryPointSearchEnabled = true;
            expect(drawCalls(chart), original);
            boundarySegmentSearchEnabled = false;
            expect(drawCalls(chart), original);
            boundarySegmentSearchEnabled = true;
            // The next update builds a fresh boundary with the new scale range.
            data.first[0] = 20;
            chart.update(UpdateMode.none);
            boundaryPointSearchEnabled = false;
            final changed = drawCalls(chart);
            boundaryPointSearchEnabled = true;
            expect(drawCalls(chart), changed);
          },
        );
      }
    }
  }
}
