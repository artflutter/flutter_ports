// Original code, not ported from Chart.js: tests of the gallery ChartCanvas.

import 'package:chartjs_gallery/demo/chart_canvas.dart';
import 'package:chartjs_gallery/demo/stress_point_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs/src/core/core.animator.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/elements/index.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [count] frames of 16 ms, the frame interval of a browser.
Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// A chart with one point at the middle of the chart area. Its first update
/// animates the point from the bottom of the chart area for 1000 ms (the
/// default `animation.duration`).
Chart _create(UiCanvasElement canvas) {
  registerGalleryComponents();
  return Chart(canvas, <String, Object?>{
    'type': StressPointController.id,
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 0.5, 'y': 0.5},
          ],
        },
      ],
    },
    'options': <String, Object?>{'maintainAspectRatio': false},
  });
}

void main() {
  testWidgets('chart canvas: a chart made under a disabled TickerMode is '
      'muted until the TickerMode turns on', (tester) async {
    final enabled = ValueNotifier(false);
    addTearDown(enabled.dispose);
    Chart? created;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (context, value, child) =>
              TickerMode(enabled: value, child: child!),
          child: ChartCanvas(
            height: 200,
            create: _create,
            onChart: (chart) => created = chart,
          ),
        ),
      ),
    );
    // The widget makes the chart after the first frame.
    final chart = created!;
    final point = chart.getDatasetMeta(0).data.single as PointElement;
    final area = chart.chartArea!;
    final start = point.y;
    expect(start, area.bottom);
    expect(animator.has(chart), isTrue);

    // The muted animator gives the chart no tick, and the loop ends: the
    // binding has no frame to show.
    await _frames(tester, 10);
    expect(point.y, start);
    expect(animator.running(chart), isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);

    // The TickerMode turns on: the animator starts again, and the animation
    // goes on to its end.
    enabled.value = true;
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await _frames(tester, 2);
    expect(animator.running(chart), isTrue);
    expect(point.y, lessThan(start));
    for (var i = 0; i < 70 && animator.running(chart); i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(animator.running(chart), isFalse);
    expect(point.y, closeTo(area.bottom - 0.5 * area.height, 1e-9));
    expect(tester.takeException(), isNull);
  });
}
