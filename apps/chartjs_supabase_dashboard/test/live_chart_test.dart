// Original code, not ported from Chart.js: the tests of the live chart.

import 'dart:math' as math;

import 'package:chartjs_supabase_dashboard/src/live_chart.dart';
import 'package:chartjs_supabase_dashboard/src/live_series.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_metric_source.dart';

/// A live chart of 2000 rows, one a second, in a view of 1000 x 500, after
/// 20 frames. The series has no realtime row: the live edge is the time of
/// the newest row.
Future<(LiveSeries, Chart Function())> showChart(
  WidgetTester tester, {
  MemoryMetricSource? source,
  Duration pageSpan = const Duration(seconds: 5000),
}) async {
  tester.view
    ..physicalSize = const Size(1000, 500)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final series = LiveSeries(
    source ?? MemoryMetricSource(rows: 2000),
    pageSpan: pageSpan,
  );
  Chart? chart;
  await tester.pumpWidget(
    MaterialApp(
      home: RepaintBoundary(
        key: const ValueKey('test.view'),
        child: Scaffold(
          body: LiveChart(series: series, onChartCreated: (c) => chart = c),
        ),
      ),
    ),
  );
  await series.start(pump: false);
  await frames(tester, 20);
  return (series, () => chart!);
}

/// Pumps [count] frames of 16 ms.
Future<void> frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Unmounts the chart and disposes [series].
Future<void> close(WidgetTester tester, LiveSeries series) async {
  await tester.pumpWidget(const SizedBox());
  series.dispose();
}

/// The color of the pixel at [position] of the view.
Future<Color> colorAt(WidgetTester tester, Offset position) async {
  final view = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('test.view')),
  );
  final bytes = (await tester.runAsync(() async {
    final image = await view.toImage();
    final data = await image.toByteData();
    image.dispose();
    return data;
  }))!;
  final at =
      4 * (position.dy.floor() * view.size.width.toInt() + position.dx.floor());
  return Color.fromARGB(
    bytes.getUint8(at + 3),
    bytes.getUint8(at),
    bytes.getUint8(at + 1),
    bytes.getUint8(at + 2),
  );
}

double edgeOf(LiveSeries series) =>
    series.newest!.millisecondsSinceEpoch.toDouble();

/// The count of chart updates since the last reset.
int updates = 0;

/// A plugin of all charts of this file: it counts the chart updates. It
/// keeps the range updates of the chart (`supportsDataUpdates`).
final Plugin<Object?> updateCounter = Plugin(
  id: 'liveChartTest',
  supportsDataUpdates: true,
  afterUpdate: (chart, args, options) => updates++,
);

/// The factor of the width of the x range for one wheel step of [deltaY]
/// with Ctrl: the step of the wheel zoom of chartjs-plugin-zoom.
double zoomFactor(double deltaY) {
  final amount = 0.1 * math.min(deltaY.abs(), 24) / 24;
  return deltaY < 0 ? 1 - amount : 1 / (1 - amount);
}

/// A trackpad pinch at [position]: [steps] frames, each with one step of
/// the scale by [step]. The host gives the chart one `wheel` with Ctrl and
/// the `deltaY` -100 ln([step]) for each step.
Future<void> pinch(
  WidgetTester tester,
  Offset position, {
  required int steps,
  required double step,
}) async {
  const pointer = 7;
  tester.binding.handlePointerEvent(
    PointerPanZoomStartEvent(pointer: pointer, position: position),
  );
  var scale = 1.0;
  for (var i = 0; i < steps; i++) {
    scale *= step;
    tester.binding.handlePointerEvent(
      PointerPanZoomUpdateEvent(
        pointer: pointer,
        position: position,
        scale: scale,
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  tester.binding.handlePointerEvent(
    PointerPanZoomEndEvent(pointer: pointer, position: position),
  );
}

void main() {
  setUpAll(() {
    Chart.register(registerables);
    Chart.register([updateCounter]);
  });
  tearDownAll(() => Chart.unregister([updateCounter]));

  testWidgets('the chart area keeps its size while ticks pass the edges', (
    tester,
  ) async {
    final (series, chart) = await showChart(tester);

    // 7 pixels a frame for 150 frames: about 15 ticks of 10 seconds pass the
    // edges, and the y labels change.
    final center = tester.getCenter(
      find.byKey(const ValueKey('dashboard.chart')),
    );
    final areas = <(double, double, double, double)>{};
    final labels = <String>{};
    for (var i = 0; i < 150; i++) {
      tester.binding.handlePointerEvent(
        PointerScrollEvent(position: center, scrollDelta: const Offset(0, 7)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final area = chart().chartArea!;
      areas.add((area.left, area.top, area.right, area.bottom));
      labels.add(chart().scales['x']!.ticks!.first.label!.first);
    }

    expect(labels.length, greaterThan(5), reason: 'the ticks moved');
    expect(areas, hasLength(1));

    await close(tester, series);
  });

  testWidgets('Live moves to the live edge on a curve, not in one frame', (
    tester,
  ) async {
    final (series, chart) = await showChart(tester);
    final center = tester.getCenter(
      find.byKey(const ValueKey('dashboard.chart')),
    );
    for (var i = 0; i < 10; i++) {
      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: center,
          scrollDelta: const Offset(0, 1000),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    await frames(tester, 60);
    final width = chart().scales['x']!.max - chart().scales['x']!.min;
    final from = chart().scales['x']!.max;
    final distance = edgeOf(series) - from;
    expect(distance, greaterThan(5 * width), reason: 'far in the history');

    await tester.tap(find.byKey(const ValueKey('dashboard.live')));
    final steps = <double>[];
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      steps.add(chart().scales['x']!.max);
    }

    // Each frame moves forward, and no frame moves more than a small part of
    // the way: on the curve of 1.4 s, the largest step is about 2 %.
    var previous = from;
    for (final step in steps) {
      expect(step, greaterThanOrEqualTo(previous));
      expect(step - previous, lessThan(distance * 0.05));
      previous = step;
    }
    expect(steps.last, closeTo(edgeOf(series), 1));
    expect(
      chart().scales['x']!.max - chart().scales['x']!.min,
      closeTo(width, 1),
      reason: 'the move keeps the width',
    );
    expect(find.byKey(const ValueKey('dashboard.live')), findsNothing);

    await close(tester, series);
  });

  testWidgets('zoom in halves the width and keeps the live edge', (
    tester,
  ) async {
    final (series, chart) = await showChart(tester);
    double width() => chart().scales['x']!.max - chart().scales['x']!.min;
    final before = width();

    await tester.tap(find.byKey(const ValueKey('dashboard.zoom.in')));
    await frames(tester, 3);
    expect(width(), lessThan(before));
    expect(width(), greaterThan(before / 2), reason: 'a move, not a jump');

    await frames(tester, 40);
    expect(width(), closeTo(before / 2, 1));
    expect(chart().scales['x']!.max, closeTo(edgeOf(series), 1));

    await close(tester, series);
  });

  testWidgets('the time labels are at least 5 seconds apart', (tester) async {
    final (series, chart) = await showChart(tester);

    await tester.tap(find.byKey(const ValueKey('dashboard.range.30s')));
    await frames(tester, 40);
    await tester.tap(find.byKey(const ValueKey('dashboard.zoom.in')));
    await frames(tester, 40);

    final x = chart().scales['x']!;
    expect(x.max - x.min, closeTo(15 * 1000, 1));
    final ticks = x.ticks!;
    expect(ticks.length, greaterThanOrEqualTo(2));
    for (var i = 1; i < ticks.length; i++) {
      expect(ticks[i].value - ticks[i - 1].value, greaterThanOrEqualTo(5000));
    }

    await close(tester, series);
  });

  testWidgets('the x axis makes only the ticks of its grid', (tester) async {
    final (series, chart) = await showChart(tester);

    // 30 seconds, then 15 seconds: the ticks are those of the grid of 5
    // seconds, each with a label.
    for (final key in ['dashboard.range.30s', 'dashboard.zoom.in']) {
      await tester.tap(find.byKey(ValueKey(key)));
      await frames(tester, 40);
      final x = chart().scales['x']!;
      final grid = [
        for (
          var value = (x.min / 5000).ceilToDouble() * 5000;
          value <= x.max;
          value += 5000
        )
          value,
      ];
      expect([for (final tick in x.ticks!) tick.value], grid, reason: key);
      for (final tick in x.ticks!) {
        expect(tick.label, hasLength(1), reason: key);
      }
    }

    await close(tester, series);
  });

  testWidgets('a pinch in the live view does one chart update in a frame', (
    tester,
  ) async {
    final (series, chart) = await showChart(tester);
    final x = chart().scales['x']!;
    final center = tester.getCenter(
      find.byKey(const ValueKey('dashboard.chart')),
    );
    final before = x.max - x.min;
    final points = chart().getDatasetMeta(0).data.length;

    updates = 0;
    await pinch(tester, center, steps: 10, step: 1.1);

    // The ticker applies the zoom: the zoom plugin does no update of its
    // own, and the chart keeps its data List, so the widget does none.
    expect(updates, 10);
    final factor = zoomFactor(-100 * math.log(1.1));
    expect(x.max - x.min, closeTo(before * math.pow(factor, 10), 1));
    expect(x.max, closeTo(edgeOf(series), 1), reason: 'the live edge stays');
    expect(chart().getDatasetMeta(0).data.length, points);

    await close(tester, series);
  });

  testWidgets('a pinch in the history view keeps the time at the pointer', (
    tester,
  ) async {
    final (series, chart) = await showChart(tester);
    final box = find.byKey(const ValueKey('dashboard.chart'));
    final center = tester.getCenter(box);
    for (var i = 0; i < 10; i++) {
      tester.binding.handlePointerEvent(
        PointerScrollEvent(position: center, scrollDelta: const Offset(0, 300)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    await frames(tester, 60);
    expect(find.byKey(const ValueKey('dashboard.live')), findsOneWidget);

    final x = chart().scales['x']!;
    final at = center + const Offset(200, 0);
    final pixel = at.dx - tester.getTopLeft(box).dx;
    final time = x.getValueForPixel(pixel)!;
    final before = x.max - x.min;

    updates = 0;
    await pinch(tester, at, steps: 5, step: 1 / 1.1);

    expect(updates, 5);
    final factor = zoomFactor(100 * math.log(1.1));
    expect(x.max - x.min, closeTo(before * math.pow(factor, 5), 1));
    expect(x.getValueForPixel(pixel), closeTo(time, 1));
    expect(find.byKey(const ValueKey('dashboard.live')), findsOneWidget);

    await close(tester, series);
  });

  testWidgets('a zoom changes the data List only when the view needs it', (
    tester,
  ) async {
    final (series, chart) = await showChart(tester);
    final x = chart().scales['x']!;
    final center = tester.getCenter(
      find.byKey(const ValueKey('dashboard.chart')),
    );
    int points() => chart().getDatasetMeta(0).data.length;
    int rowsInView() => ((x.max - x.min) / 1000).floor();
    final start = points();
    expect(start, greaterThanOrEqualTo(2 * rowsInView()));

    // Out to more than two widths: the List of two widths does not hold the
    // view, and the chart gets the older rows.
    await pinch(tester, center, steps: 40, step: 1 / 1.1);
    await frames(tester, 5);
    expect(rowsInView(), greaterThan(start));
    expect(points(), greaterThanOrEqualTo(rowsInView()));

    // In to less than a quarter of the width of the List: a shorter List.
    final wide = points();
    await pinch(tester, center, steps: 80, step: 1.1);
    await frames(tester, 5);
    expect(points(), lessThan(wide / 4));
    expect(points(), greaterThanOrEqualTo(rowsInView()));

    await close(tester, series);
  });

  testWidgets('the y labels are whole numbers', (tester) async {
    // A flat line from 50.0 to 50.3: without precision 0, the axis takes
    // steps of 0.2 or 0.5.
    final (series, chart) = await showChart(
      tester,
      source: MemoryMetricSource(
        rows: 2000,
        valueOf: (id) => 50 + (id % 4) * 0.1,
      ),
    );

    final ticks = chart().scales['y']!.ticks!;
    expect(ticks.length, greaterThanOrEqualTo(2));
    for (final tick in ticks) {
      expect(tick.value, tick.value.roundToDouble());
    }

    await close(tester, series);
  });

  /// Shows a chart of 100 rows a second apart, then no row for [gap], then
  /// 21 rows a second apart at the live edge, each with the value 50. The
  /// view is the 2 minutes before the newest row, so the line between the
  /// two rows of the gap crosses its left part.
  ///
  /// The result tells whether two pixels near the left edge have the color
  /// of the line: the place of a dash and the place of the space after it,
  /// for dashes of 4 pixels and spaces of 4 pixels from the row before the
  /// gap.
  Future<(bool dash, bool space)> lineAcross(
    WidgetTester tester,
    Duration gap,
  ) async {
    const line = Color(0xFF3ECF8E);
    final source = MemoryMetricSource(rows: 100, valueOf: (_) => 50);
    final after = MemoryMetricSource.start.add(
      const Duration(seconds: 100) + gap,
    );
    for (var i = 0; i <= 20; i++) {
      source.addRow(101 + i, after.add(Duration(seconds: i)), 50);
    }
    final (series, chart) = await showChart(tester, source: source);

    final x = chart().scales['x']!;
    final from = x.getPixelForValue(
      source.rows[99].ts.millisecondsSinceEpoch.toDouble(),
    );
    final left = chart().chartArea!.left;
    expect(from, lessThan(left - 1000), reason: 'far before the view');
    expect(
      chart().getDatasetMeta(0).data.length,
      lessThan(series.points.length),
      reason: 'the chart has the rows of the live view only',
    );
    expect(
      chart().updateRanges(UpdateMode.none),
      isTrue,
      reason: 'the plugin of the dashed lines keeps the range updates',
    );

    final origin = tester.getTopLeft(
      find.byKey(const ValueKey('dashboard.chart')),
    );
    final y = chart().scales['y']!.getPixelForValue(50);
    final dash = from + ((left + 20 - from) / 8).ceil() * 8;
    final result = (
      await colorAt(tester, origin + Offset(dash + 2, y)) == line,
      await colorAt(tester, origin + Offset(dash + 6, y)) == line,
    );
    await close(tester, series);
    return result;
  }

  testWidgets('the solid line joins rows at most 1 hour apart', (tester) async {
    expect(await lineAcross(tester, const Duration(hours: 1)), (true, true));
  });

  testWidgets('a dashed line joins rows from 1 hour to 2 hours apart', (
    tester,
  ) async {
    expect(await lineAcross(tester, const Duration(hours: 1, seconds: 1)), (
      true,
      false,
    ));
    expect(await lineAcross(tester, const Duration(hours: 2)), (true, false));
  });

  testWidgets('rows more than 2 hours apart have no line between them', (
    tester,
  ) async {
    expect(await lineAcross(tester, const Duration(hours: 2, seconds: 1)), (
      false,
      false,
    ));
  });

  testWidgets('a vertical line marks the start of each page', (tester) async {
    // Pages of 60 s in a view of 120 s: the view loads the pages before it,
    // and the splits of page 1 (1980 s) and page 2 (1920 s) are in view. A
    // flat line at 50 keeps the line and its fill below the pixels of the
    // test.
    final source = MemoryMetricSource(rows: 2000, valueOf: (_) => 50);
    final (series, chart) = await showChart(
      tester,
      source: source,
      pageSpan: const Duration(seconds: 60),
    );
    DateTime at(int seconds) =>
        MemoryMetricSource.start.add(Duration(seconds: seconds));
    expect(series.pageStarts.take(2), [at(1980), at(1920)]);

    final x = chart().scales['x']!;
    final area = chart().chartArea!;
    final origin = tester.getTopLeft(
      find.byKey(const ValueKey('dashboard.chart')),
    );
    final y = area.top + area.height / 4;
    for (final start in series.pageStarts.take(2)) {
      final pixel = x
          .getPixelForValue(start.millisecondsSinceEpoch.toDouble())
          .floorToDouble();
      expect(pixel, inInclusiveRange(area.left, area.right));
      expect(
        await colorAt(tester, origin + Offset(pixel, y)),
        isNot(await colorAt(tester, origin + Offset(pixel + 10, y))),
        reason: 'the split of $start',
      );
    }

    await close(tester, series);
  });

  testWidgets('a range button sets the width', (tester) async {
    final (series, chart) = await showChart(tester);

    await tester.tap(find.byKey(const ValueKey('dashboard.range.10m')));
    await frames(tester, 40);

    final x = chart().scales['x']!;
    expect(x.max - x.min, closeTo(10 * 60 * 1000, 1));
    expect(x.max, closeTo(edgeOf(series), 1));

    await close(tester, series);
  });
}
