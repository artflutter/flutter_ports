// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/borderSkipped/scriptable.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      raw(
        BarDataset(
          // option in dataset
          data: .values(<num?>[0, 5, 10, null, -10, -5]),
        ),
        <String, Object?>{
          // DIVERGES(chartjs): adapt-border-skipped-enum, the enum value.
          'borderSkipped': (ScriptableContext ctx) {
            final value = jsOrZero(
              jsGet(jsGet(ctx.dataset, 'data'), ctx.dataIndex),
            );
            return value > 8
                ? BorderSkippedEdge.left
                : value > 0
                ? BorderSkippedEdge.right
                : value > -8
                ? BorderSkippedEdge.top
                : BorderSkippedEdge.bottom;
          },
        },
      ),
      BarDataset(
        // option in element (fallback)
        data: .values(<num?>[0, 5, 10, null, -10, -5]),
      ),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5],
    elements: ChartElements(
      bar: raw(
        BarElementStyle(
          backgroundColor: ChartPaint.solid(Color(0x00000000)),
          borderColor: ChartPaint.solid(Color(0xFF888888)),
          borderWidth: 8,
        ),
        <String, Object?>{
          // DIVERGES(chartjs): adapt-border-skipped-enum, the enum value.
          'borderSkipped': (ScriptableContext ctx) {
            final index = jsToNumber(ctx.dataIndex ?? undefined);
            return index > 4
                ? BorderSkippedEdge.left
                : index > 3
                ? BorderSkippedEdge.right
                : index > 1
                ? BorderSkippedEdge.top
                : BorderSkippedEdge.bottom;
          },
        },
      ),
    ),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off, beginAtZero: true),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
