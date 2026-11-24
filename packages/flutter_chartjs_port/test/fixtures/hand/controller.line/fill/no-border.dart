// Ported from Chart.js v4.6.1 test/fixtures/controller.line/fill/no-border.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:async';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// The `run` hook (:37-39) gives the Promise of a `setTimeout` of 50 ms. The
/// port is a `Future` that the harness task of `setTimeout` completes
/// (Chart.js ADR 0022, section 7, and Chart.js ADR 0041, section 10 item 5).
/// The runner pumps frames of 16 ms until the `Future` completes: the
/// animation of 1 ms ends in the first frame.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        data: .values(<num?>[12, 19, 3, 5, 2, 3]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderWidth: 0,
        tension: 0.4,
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toOrigin,
      ),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    disabledPlugins: [
      PluginOff<LegendPlugin>(),
      PluginOff<TitlePlugin>(),
      PluginOff<TooltipPlugin>(),
    ],
    extra: <String, Object?>{
      'animation': <String, Object?>{'duration': 1},
      'plugins': <String, Object?>{'filler': true},
    },
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
    'run': () {
      final resolve = Completer<void>();
      setTimeout(resolve.complete, 50);
      return resolve.future;
    },
  },
);
