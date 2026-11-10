// Original code, not ported from chartjs-plugin-zoom: the observations of the fixture runs.
// The header text is longer than 80 columns and has no URI.
// ignore_for_file: lines_longer_than_80_chars

/// The observation points of the zoom fixtures (row
/// `harness-fixture-observations` of `doc/differences.md`).
///
/// Upstream compares each fixture with a PNG image. The port compares no
/// image (Chart.js ADR 0034, section 4). Each fixture draws its chart into a
/// sprite canvas after each step (`ctx.drawImage(chart.canvas, ...)`). The
/// hand ports call [snapshot] at these points, and `index.dart` adds one
/// observation after `run` and compares the list with the data of
/// `tool/reference/fixtures_reference.mjs` (`fixtures_reference.dart`).
///
/// This file is not a test entry. Only VM test files import it.
library;

import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show ZoomChart;
// The drag rectangle of `draw` (src/plugin.ts:23-36) and the drag of the
// state: the generator reads them from src/handlers.ts and src/state.ts.
import 'package:flutter_chartjs_plugin_zoom_port/src/handlers.dart'
    show computeDragRect;
import 'package:flutter_chartjs_plugin_zoom_port/src/state.dart' show getState;
import 'package:flutter_chartjs_port/chartjs.dart' show Chart;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsObjectKeys;

/// The chart of the running fixture and its observations, or null outside a
/// run.
({Chart chart, List<Object?> observations})? _current;

/// Starts the observations of [chart] for one run of a fixture.
List<Object?> startObservations(Chart chart) {
  final observations = <Object?>[];
  _current = (chart: chart, observations: observations);
  return observations;
}

/// Ends the observations of the run.
void endObservations() => _current = null;

/// `ctx.drawImage(chart.canvas, ...)` into the sprite canvas of a fixture:
/// records an observation of [chart]. The image does not change the chart.
void snapshot(Chart chart) {
  final current = _current;
  if (current != null && identical(current.chart, chart)) {
    current.observations.add(observe(chart));
  }
}

/// A value of the options of a scale: a `DateTime` (a JS `Date`) is
/// `{'date': <time value>}`, and a number is a double, as in the data.
Object? _value(Object? value) => switch (value) {
  final DateTime date => <String, Object?>{
    'date': date.millisecondsSinceEpoch.toDouble(),
  },
  final num number => number.toDouble(),
  _ => value,
};

/// The observation of [chart]: the keys of `observe` of
/// `tool/reference/fixtures_reference.mjs`.
Map<String, Object?> observe(Chart chart) {
  final area = chart.chartArea!;
  final state = getState(chart);
  Object? dragRect;
  if (state.dragStart case final dragStart?) {
    if (state.dragEnd case final dragEnd?) {
      final options = state.options;
      final rect = computeDragRect(
        chart,
        options.zoom.mode,
        (dragStart: dragStart, dragEnd: dragEnd),
        options.zoom.drag.maintainAspectRatio,
      );
      dragRect = <Object?>[rect.left, rect.top, rect.width, rect.height];
    }
  }
  return <String, Object?>{
    'chartArea': <Object?>[area.left, area.top, area.right, area.bottom],
    'scales': <Object?>[
      for (final id in jsObjectKeys(chart.scales))
        if (chart.scales[id] case final scale?)
          <Object?>[
            id,
            scale.min,
            scale.max,
            _value(scale.options.min),
            _value(scale.options.max),
          ],
    ],
    'zoomLevel': chart.getZoomLevel(),
    'zoomedOrPanned': chart.isZoomedOrPanned(),
    'zoomingOrPanning': chart.isZoomingOrPanning(),
    'dragRect': dragRect,
  };
}
