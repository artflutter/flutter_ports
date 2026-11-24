// Ported from Chart.js v4.6.1 test/fixtures/element.point/rotation.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native paint inputs.
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() {
  ChartGradient? gradient;

  // DIVERGES(chartjs): adapt-point-style-objects, the style classes.
  final datasets = [
    for (final (y, style) in const <Object?>[
      CirclePointStyle(),
      CrossPointStyle(),
      CrossRotPointStyle(),
      DashPointStyle(),
      LinePointStyle(),
      RectPointStyle(),
      RectRoundedPointStyle(),
      RectRotPointStyle(),
      StarPointStyle(),
      TrianglePointStyle(),
      false,
    ].indexed)
      raw(
        BubbleDataset(
          // Upstream: Array.apply(null, Array(17)).map(function(v, x) {...}).
          data: [for (var x = 0; x < 17; x++) DataPoint(x, 11 - y)],
          // A PointStyle, or `false` (no point style) in the raw options.
          pointStyle: style is PointStyle ? style : null,
        ),
        style is PointStyle ? null : <String, Object?>{'pointStyle': style},
      ),
  ];

  // Upstream: Array.apply(null, Array(17)).map(function(v, i) {...}).
  final angles = List<Object?>.generate(17, (i) {
    return -180 + i * 22.5;
  });

  return FixtureConfig.typed(
    ChartConfig(
      datasets: datasets,
      responsive: false,
      elements: ChartElements(
        point: raw(
          PointElementStyle(
            radius: 10,
            borderColor: ChartPaint.solid(Color(0xFFCCCCCC)),
          ),
          <String, Object?>{
            'rotation': angles,
            'backgroundColor': (Object? context) {
              return gradient ??= const ChartGradient.linear(
                native_ui.Offset.zero,
                native_ui.Offset(512, 256),
                [native_ui.Color(0xffff0000), native_ui.Color(0xff0000ff)],
              );
            },
          },
        ),
      ),
      padding: const EdgeInsets.all(20),
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
    ),
    options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
  );
}
