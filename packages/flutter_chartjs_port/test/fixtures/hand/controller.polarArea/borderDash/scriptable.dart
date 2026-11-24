// Ported from Chart.js v4.6.1 test/fixtures/controller.polarArea/borderDash/scriptable.js (MIT, Chart.js Contributors).
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
      PolarAreaDataset(
        // option in dataset
        data: <num?>[5, 2, 4, 7, 6, 8],
      ),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5],
    elements: ChartElements(
      arc: raw(
        ArcElementStyle(
          backgroundColor: ChartPaint.solid(Color(0x00000000)),
          borderColor: ChartPaint.solid(Color(0xFF000000)),
          borderWidth: 1,
        ),
        <String, Object?>{
          'borderDash': (ScriptableContext ctx) {
            final value = jsOrZero(ctx.dataIndex ?? undefined).remainder(2);
            return value == 0 ? <Object?>[3, 3] : <Object?>[];
          },
        },
      ),
    ),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      RadialLinearAxis(display: ScaleDisplay.off),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
