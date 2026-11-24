// Ported from Chart.js v4.6.1 test/fixtures/controller.line/clip/false.js (MIT, Chart.js Contributors).
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
FixtureConfig fixture() {
  final data = <Object?>[];
  for (var x = 0.95; x < 1.15; x += 0.002) {
    data.add(<String, Object?>{'x': x, 'y': x});
  }

  for (var x = 0.95; x < 1.15; x += 0.001) {
    data.add(<String, Object?>{'x': x, 'y': 2.1 - x});
  }

  return FixtureConfig.typed(
    raw(
      ChartConfig(
        datasets: [
          raw(
            ScatterDataset(
              // DIVERGES(chartjs): adapt-chart-clip-option, the clip class.
              clip: ChartClip.none,
              borderWidth: 0,
              backgroundColor: .resolver(
                (ctx) =>
                    ctx.type != 'data' ||
                        jsToNumber(jsGet(ctx.raw, 'x')) < 1 ||
                        jsToNumber(jsGet(ctx.raw, 'x')) > 1.1
                    ? ChartPaint.solid(Color.fromRGBO(255, 0, 0, 0.7))
                    : ChartPaint.solid(Color.fromRGBO(0, 0, 255, 0.05)),
              ),
            ),
            <String, Object?>{'radius': 8, 'data': data},
          ),
        ],
        scales: [
          LinearAxis(CartesianAxis.x, min: 1, max: 1.1),
          LinearAxis(CartesianAxis.y, min: 1, max: 1.1),
        ],
        padding: const EdgeInsets.all(32),
      ),
      <String, Object?>{'plugins': false},
    ),
    options: AcquireOptions(canvas: HarnessCanvas(width: 320, height: 240)),
  );
}
