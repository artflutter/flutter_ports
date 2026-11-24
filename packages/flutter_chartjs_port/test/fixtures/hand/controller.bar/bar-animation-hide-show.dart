// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/bar-animation-hide-show.js (MIT, Chart.js Contributors).
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
import 'package:clock/clock.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `drawImage(canvas, ...)` takes the image source of the canvas layer,
/// read at the place of the upstream call (`toImageSource()` of
/// `UiCanvasElement`).
FixtureConfig fixture() {
  final canvas = document.createElement<HTMLCanvasElement>('canvas')
    ..width = 512
    ..height = 512;
  final ctx = canvas.getContext('2d')!;

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        BarDataset(
          data: .values(<num?>[1]),
          backgroundColor: .constant(
            ChartPaint.solid(Color.fromRGBO(255, 0, 0, 0.5)),
          ),
        ),
        BarDataset(
          data: .values(<num?>[2]),
          backgroundColor: .constant(
            ChartPaint.solid(Color.fromRGBO(0, 0, 255, 0.5)),
          ),
        ),
        BarDataset(
          data: .values(<num?>[3]),
          backgroundColor: .constant(
            ChartPaint.solid(Color.fromRGBO(0, 255, 0, 0.5)),
          ),
        ),
      ],
      labels: <Object>[0],
      events: <String>[],
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off, max: 4),
      ],
      extra: <String, Object?>{
        'animation': <String, Object?>{
          'duration': 14000,
          // DIVERGES(chartjs): adapt-flutter-curves, the curve.
          'easing': Curves.linear,
        },
      },
    ),
    options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 512)),
    run: (chart) {
      // `const animator = Chart.animator`: the singleton `animator` of
      // core.animator.dart.
      final anims = animator.getAnims(chart);
      // disable animator
      final backup = animator.refresh;
      animator.refresh = () {};

      final completer = Completer<void>();
      requestAnimFrame(() {
        // make sure previous animation is finished
        animator.update(clock.now().millisecondsSinceEpoch * 2.0);

        chart.hide(1);
        var start = anims.items[0].start;
        for (var i = 0.0; i < 8; i++) {
          animator.update(start + i * 2000);
          final x = i.remainder(4) * 128;
          final y = (i / 4).floorToDouble() * 128;
          ctx.drawImage(
            (chart.canvas! as UiCanvasElement).toImageSource(),
            x,
            y,
            128,
            128,
          );
        }

        // make sure previous animation is finished
        animator.update(clock.now().millisecondsSinceEpoch * 2.0);

        chart.show(1);
        start = anims.items[0].start;
        for (var i = 0.0; i < 8; i++) {
          animator.update(start + i * 2000);
          final x = i.remainder(4) * 128;
          final y = (2 + i / 4).floorToDouble() * 128;
          ctx.drawImage(
            (chart.canvas! as UiCanvasElement).toImageSource(),
            x,
            y,
            128,
            128,
          );
        }
        clearCanvas(chart.canvas);
        chart.ctx!.drawImage((canvas as UiCanvasElement).toImageSource(), 0, 0);

        animator.refresh = backup;
        completer.complete();
      });
      return completer.future;
    },
  );
}
