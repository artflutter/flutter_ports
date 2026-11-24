// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/dataset/interpolated.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// The module loop makes the data with `Math.sin` and `Math.cos`. The smoke
/// test of the fixture asserts no value, so `dart:math` is sufficient
/// (Chart.js ADR 0034).
FixtureConfig fixture() {
  final data1 = <Object?>[];
  final data2 = <Object?>[];
  final data3 = <Object?>[];
  for (var i = 0; i < 200; i++) {
    final a = i / math.pi / 10;

    data1.add(<String, Object?>{
      'x': i,
      'y': i < 86 || i > 104 && i < 178 ? math.sin(a) : double.nan,
    });

    if (i % 10 == 0) {
      data2.add(<String, Object?>{'x': i, 'y': math.cos(a)});
    }

    if (i % 15 == 0) {
      data3.add(<String, Object?>{'x': i, 'y': math.cos(a + math.pi / 2)});
    }
  }

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        LineDataset(
          borderColor: .constant(
            ChartPaint.solid(Color.fromRGBO(255, 0, 0, 0.5)),
          ),
          backgroundColor: .constant(
            ChartPaint.solid(Color.fromRGBO(255, 0, 0, 0.25)),
          ),
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          fill: FillTarget.none,
          extra: <String, Object?>{'data': data1},
        ),
        LineDataset(
          borderColor: .constant(
            ChartPaint.solid(Color.fromRGBO(0, 0, 255, 0.5)),
          ),
          backgroundColor: .constant(
            ChartPaint.solid(Color.fromRGBO(0, 0, 255, 0.25)),
          ),
          extra: <String, Object?>{
            'data': data2,
            // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
            'fill': const FillTarget.toDataset(0),
          },
        ),
        LineDataset(
          borderColor: .constant(
            ChartPaint.solid(Color.fromRGBO(0, 255, 0, 0.5)),
          ),
          backgroundColor: .constant(
            ChartPaint.solid(Color.fromRGBO(0, 255, 0, 0.25)),
          ),
          extra: <String, Object?>{
            'data': data3,
            // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
            'fill': const FillTarget.toDataset(1),
          },
        ),
      ],
      animation: ChartAnimation.none,
      responsive: false,
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
      disabledPlugins: [
        PluginOff<LegendPlugin>(),
        PluginOff<TitlePlugin>(),
        PluginOff<TooltipPlugin>(),
      ],
      extra: <String, Object?>{
        'datasets': <String, Object?>{
          'line': <String, Object?>{
            'tension': 0.4,
            'borderWidth': 1,
            'pointRadius': 1.5,
          },
        },
      },
    ),
    options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 512)),
  );
}
