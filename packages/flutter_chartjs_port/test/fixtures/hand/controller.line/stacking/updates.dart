// Ported from Chart.js v4.6.1 test/fixtures/controller.line/stacking/updates.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native colors in fixture updates.
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

import '../../../../support/list_splice.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        data: .values(<num?>[1, 1, 1]),
        stack: 's1',
        extra: <String, Object?>{
          'borderColor': const ChartPaint.solid(ui.Color(0xFFFF0000)),
        },
      ),
      LineDataset(
        data: .values(<num?>[2, 2, 2]),
        stack: 's1',
        extra: <String, Object?>{
          'borderColor': const ChartPaint.solid(ui.Color(0xFF00FF00)),
        },
      ),
      LineDataset(
        data: .values(<num?>[3, 3, 3]),
        stack: 's1',
        extra: <String, Object?>{
          'borderColor': const ChartPaint.solid(ui.Color(0xFF0000FF)),
        },
      ),
    ],
    labels: <Object>[0, 1, 2],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(
        CartesianAxis.y,
        display: ScaleDisplay.on,
        stacked: StackMode.on,
      ),
    ],
    extra: <String, Object?>{'borderWidth': 5},
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/9424',
  options: <String, Object?>{
    'spriteText': true,
    'run': (Chart chart) {
      // Upstream: chart.data.datasets.splice(1, 0, {...}). The splice, then
      // the body of the hooked method (differences.md row
      // platform-array-events).
      final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
      final dataset = <String, Object?>{
        'data': <Object?>[1.5, 1.5, 1.5],
        'stack': 's2',
        'borderColor': const ChartPaint.solid(ui.Color(0xFF000000)),
      };
      spliceList(datasets, 1, 0, <Object?>[dataset]);
      notifyArrayListeners(datasets, 'splice', <Object?>[1, 0, dataset]);
      chart.update();
    },
  },
);
