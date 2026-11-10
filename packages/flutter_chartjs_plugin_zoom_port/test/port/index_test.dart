// Original code, not ported from chartjs-plugin-zoom: zoom across rebuilds.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// The methods of src/index.ts (`ZoomChart`) on the chart of a `ChartView`,
// and what a rebuild of the widget does to the zoomed range (seam H20,
// design D9). The zoom writes its range into the `min` and `max` options of
// each scale (`src/scale.types.ts:163-164`). The widget keeps them while it
// does not replace these options:
//
// - A new config that is `==` to the last one gives no update. A config
//   with new data updates the datasets and keeps the options.
// - A config with another option field replaces the options, as an
//   upstream app that sets `chart.options` and calls `chart.update()`: the
//   range goes back to the options of the app.
// - A theme switch writes the recorded scale options of the app back
//   (Chart.js ADR 0050), and the range goes with them (row
//   `theme-switch-zoom-range` of doc/differences.md).
//
// flutter_test_config.dart registers the built-in components and the plugin
// for each chart (harness-register-builtins).

/// The points of the scatter chart.
final List<DataPoint> _points = [
  DataPoint(10, 20),
  DataPoint(30, 60),
  DataPoint(50, 40),
  DataPoint(70, 80),
  DataPoint(90, 30),
];

/// New zoom options that enable the wheel.
Map<String, Object?> _wheelZoom() => <String, Object?>{
  'zoom': <String, Object?>{
    'wheel': <String, Object?>{'enabled': true},
  },
};

/// A new `ChartView` of a scatter chart on the linear scales `x` and `y`
/// from 0 to 100, in a box of 400 x 300, with the theme [theme]. Each call
/// makes new config objects; the configs of two calls with the same
/// arguments are `==`. The zoom options enable the wheel: a Map of plain
/// values, built in each call, as an app builds its config in `build`.
Widget _view({
  required ValueChanged<Chart> onChartCreated,
  List<DataPoint>? points,
  String? title,
  ChartThemeData? theme,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 400,
      height: 300,
      child: ChartView(
        config: ChartConfig(
          type: .scatter,
          datasets: [ScatterDataset(points: points ?? _points)],
          scales: const {
            'x': LinearAxis(min: 0, max: 100),
            'y': LinearAxis(min: 0, max: 100),
          },
          maintainAspectRatio: false,
          title: title == null ? null : ChartTitle(display: true, text: title),
          animation: ChartAnimation.none,
          extra: {
            'plugins': <String, Object?>{'zoom': _wheelZoom()},
          },
        ),
        theme: theme,
        onChartCreated: onChartCreated,
      ),
    ),
  ),
);

/// The count of the `beforeUpdate` hooks of all charts: a spy plugin,
/// unregistered at the end of the test.
List<int> _spyOnUpdates() {
  final updates = [0];
  final plugin = Plugin()
    ..id = r'$zoomUpdateSpy'
    ..beforeUpdate = (chart, args, options) {
      updates[0]++;
      return null;
    };
  Chart.register([plugin]);
  addTearDown(() => Chart.unregister([plugin]));
  return updates;
}

/// The range of the scale [id] of [chart].
(double, double) _range(Chart chart, String id) =>
    (chart.scales[id]!.min, chart.scales[id]!.max);

void main() {
  testWidgets('a rebuild with an equal config keeps the range, and new data '
      'keeps it too', (tester) async {
    final updates = _spyOnUpdates();
    final created = <Chart>[];
    Widget view({List<DataPoint>? points}) =>
        _view(onChartCreated: created.add, points: points);
    await tester.pumpWidget(view());
    await tester.pump();
    final chart = created.single..zoom(const .all(1.5));
    expect(_range(chart, 'x'), (25, 75));
    expect(_range(chart, 'y'), (25, 75));

    // An equal config: no update.
    updates[0] = 0;
    await tester.pumpWidget(view());
    await tester.pump();
    expect(updates[0], 0);
    expect(_range(chart, 'x'), (25, 75));
    expect(_range(chart, 'y'), (25, 75));
    expect(chart.isZoomedOrPanned(), isTrue);
    expect(chart.getZoomedScaleBounds()['x'], (min: 25.0, max: 75.0));

    // New data: a full update that keeps the options of the chart.
    await tester.pumpWidget(
      view(points: [DataPoint(20, 20), DataPoint(80, 80)]),
    );
    await tester.pump();
    expect(updates[0], 1);
    expect(_range(chart, 'x'), (25, 75));
    expect(_range(chart, 'y'), (25, 75));
    expect(chart.isZoomedOrPanned(), isTrue);

    chart.resetZoom();
    expect(_range(chart, 'x'), (0, 100));
    expect(created, [chart]);
  });

  testWidgets('a config with another option loses the range, as new upstream '
      'options do', (tester) async {
    final created = <Chart>[];
    await tester.pumpWidget(_view(onChartCreated: created.add));
    await tester.pump();
    final chart = created.single..zoom(const .all(1.5));
    expect(_range(chart, 'x'), (25, 75));

    await tester.pumpWidget(_view(onChartCreated: created.add, title: 'Zoom'));
    await tester.pump();
    expect(_range(chart, 'x'), (0, 100));
    expect(_range(chart, 'y'), (0, 100));
    expect(chart.isZoomedOrPanned(), isFalse);
    expect(created, [chart]);
  });

  testWidgets('a theme switch loses the range', (tester) async {
    final created = <Chart>[];
    await tester.pumpWidget(
      _view(onChartCreated: created.add, theme: const ChartThemeData.light()),
    );
    await tester.pump();
    final chart = created.single..zoom(const .all(1.5));
    expect(_range(chart, 'x'), (25, 75));
    expect(_range(chart, 'y'), (25, 75));

    // DIVERGES(zoom): theme-switch-zoom-range, the switch writes the scale
    // options of the app back.
    await tester.pumpWidget(
      _view(onChartCreated: created.add, theme: const ChartThemeData.dark()),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(created, [chart]);
    expect(_range(chart, 'x'), (0, 100));
    expect(_range(chart, 'y'), (0, 100));
    expect(chart.isZoomedOrPanned(), isFalse);
    // The state of the zoom keeps the range that it wrote last.
    expect(chart.getZoomedScaleBounds()['x'], (min: 25.0, max: 75.0));

    // A reset and a new zoom work after the switch.
    chart.resetZoom();
    expect(_range(chart, 'x'), (0, 100));
    expect(chart.getZoomedScaleBounds()['x'], isNull);
    chart.zoom(const .all(1.5));
    expect(_range(chart, 'x'), (25, 75));
  });
}
