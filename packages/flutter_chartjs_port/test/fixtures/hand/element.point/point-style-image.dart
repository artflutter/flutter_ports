// Ported from Chart.js v4.6.1 test/fixtures/element.point/point-style-image.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native paint inputs.
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() {
  // The type argument is the canvas class of the canvas layer: the point
  // style below needs its `toImageSource()`.
  final imageCanvas = document.createElement<UiCanvasElement>('canvas');
  final imageContext = imageCanvas.getContext('2d')!;

  imageCanvas
    ..width = 40
    ..height = 40;

  imageContext
    ..fillStyle = const native_ui.Color(0xffff0000)
    ..beginPath()
    ..moveTo(20, 0)
    ..lineTo(10, 40)
    ..lineTo(20, 30)
    ..closePath()
    ..fill()
    ..fillStyle = const native_ui.Color(0xffaa0000)
    ..beginPath()
    ..moveTo(20, 0)
    ..lineTo(30, 40)
    ..lineTo(20, 30)
    ..closePath()
    ..fill();

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        LineDataset(
          data: .values(<num?>[0, 0, 0, 0, 0, 0, 0, 0]),
          showLine: false,
        ),
      ],
      labels: <Object>[0, 1, 2, 3, 4, 5, 6, 7],
      responsive: false,
      elements: ChartElements(
        point: raw(
          PointElementStyle(
            // Upstream: pointStyle: imageCanvas. The DOM draws the bitmap of
            // the canvas element. The canvas layer draws an image source:
            // the snapshot of the bitmap, which does not change after this
            // line (FR section 4.1 rule 7).
            // DIVERGES(chartjs): adapt-point-style-objects, the image style.
            pointStyle: ImagePointStyle(imageCanvas.toImageSource()),
          ),
          <String, Object?>{
            'rotation': <Object?>[0, 45, 90, 135, 180, 225, 270, 315],
          },
        ),
      ),
      padding: const EdgeInsets.all(20),
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
    ),
    options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
  );
}
