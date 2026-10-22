// Original code, not ported from Chart.js: the chart of the stress mode axes.

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

/// The chart of the stress mode `axes` and of the `axes` cases of the chart
/// benchmark: the points of the stress mode `chart` on real scales of phase
/// 6.
///
/// - [StressAxisType]: the scale types of the defines `SCALE` and `YSCALE`.
/// - [StressAxesScene]: the data objects of N points, at the positions of a
///   `StressPointField`.
/// - [stressAxesConfig]: the config of the chart, a `LineController` chart
///   of points without a line.
///
/// `StressChartTiming` (`lib/demo/stress_timing.dart`) gives the time of the
/// parts of the chart path.
library;

import 'dart:math' as math;

import 'package:chartjs_gallery/demo/stress_chart_config.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsToNumber;
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// The scale types of the stress mode `axes`.
///
/// The x axis (`SCALE`) takes each type. The y axis (`YSCALE`) takes
/// [linear] and [logarithmic]: [stressAxesValueTypes].
enum StressAxisType {
  /// `LinearScale`: values from 0 to 100.
  linear,

  /// `LogarithmicScale`: values from 1 to 100000.
  logarithmic,

  /// `CategoryScale`: one label for each point.
  category,

  /// `TimeScale` with the default date adapter (Chart.js ADR 0024): one
  /// day for each point.
  time,
}

/// The scale types of the y axis of the stress mode `axes`.
const List<StressAxisType> stressAxesValueTypes = [
  StressAxisType.linear,
  StressAxisType.logarithmic,
];

/// The decades of the values of a logarithmic axis: 1 to 10^5.
const int _decades = 5;

/// The value of the position [fraction] (0 to 1) on an axis of the type
/// [type]: 0 to 100 on a linear axis, 1 to 100000 on a logarithmic axis.
double stressAxesValue(double fraction, StressAxisType type) =>
    type == StressAxisType.logarithmic
    ? math.pow(10, fraction * _decades).toDouble()
    : fraction * 100;

/// The data objects of a chart of the stress mode `axes`.
///
/// The data objects are in the internal format of the scales, the parsed
/// items of `parsing: false` (an option of [stressAxesConfig]): the x of a
/// category point is the index of its label, and the x of a time
/// point is a timestamp in ms. Thus an update does not parse the data.
///
/// With `parsing: false`, the data must be sorted by the index axis
/// (docs/general/data-structures.md:74 of Chart.js). The parse sets
/// `_sorted` (core.datasetController.js:462), and `getMinMax` of the index
/// scale then reads only the first and the last point (:625-655). Thus the
/// x values are fixed, and they increase with the index: equal steps on a
/// linear axis, equal factors on a logarithmic axis, the label index on a
/// category axis, and one day for each point on a time axis. Only the y
/// values move.
final class StressAxesScene {
  /// The first [n] points of [x] and [y] values. [positions] gives the
  /// fractions of the moving y values.
  StressAxesScene(
    this.n, {
    required this.x,
    required this.y,
    required StressPointField positions,
  }) : labels = [
         if (x == StressAxisType.category)
           for (var i = 0; i < n; i++) 'Point $i',
       ],
       data = [
         for (var i = 0; i < n; i++)
           <String, Object?>{
             'x': _xValue(x, i, n),
             'y': stressAxesValue(positions.y[i], y),
           },
       ];

  /// The point count.
  final int n;

  /// The scale type of the x axis.
  final StressAxisType x;

  /// The scale type of the y axis.
  final StressAxisType y;

  /// `data.labels`: the label of each point for a category axis, else
  /// empty.
  final List<Object?> labels;

  /// The data objects `{x, y}`.
  final List<AnyObject> data;

  /// The x of the point [i] of [n] points: it increases with [i].
  static double _xValue(StressAxisType type, int i, int n) => switch (type) {
    StressAxisType.linear || StressAxisType.logarithmic => stressAxesValue(
      n > 1 ? i / (n - 1) : 0,
      type,
    ),
    StressAxisType.category => i.toDouble(),
    // Midnight of the day i after 2000-01-01, in the local zone of the
    // default date adapter.
    StressAxisType.time => DateTime(
      2000,
      1,
      1 + i,
    ).millisecondsSinceEpoch.toDouble(),
  };

  /// Writes the y positions of [positions] into the data objects. The x
  /// values do not change: the data stays sorted.
  void write(StressPointField positions) {
    final ys = positions.y;
    for (var i = 0; i < n; i++) {
      data[i]['y'] = stressAxesValue(ys[i], y);
    }
  }
}

/// The config of a chart of the stress mode `axes` (Chart.js ADR 0031
/// section 4): a `LineController` chart of one dataset of the data objects
/// of [scene], with the scales `x` and `y` of [scene] and the labels of a
/// category axis.
///
/// The dataset has `showLine: false` (the line has `borderWidth: 0`,
/// controller.line.js:63-65, thus it does not draw) and `clip: false`. The
/// chart has `parsing: false` (the data is sorted), `layout.autoPadding:
/// false`, `animation: false`, `events: []` and `maintainAspectRatio:
/// false`. Thus the chart area and the split of `drawMs` are those of
/// phase 6: no overflow padding, and no dataset clip that moves the flush of
/// the circle batch into the dataset draw.
///
/// [autoSkip] is the option `ticks.autoSkip` of the x axis. A category axis
/// without it draws N rotated labels in each frame. [options] adds chart
/// options, and [plugins] are the inline plugins.
AnyObject stressAxesConfig({
  required StressAxesScene scene,
  required bool autoSkip,
  AnyObject options = const {},
  List<Object?> plugins = const [],
}) => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    if (scene.labels.isNotEmpty) 'labels': scene.labels,
    'datasets': <Object?>[
      <String, Object?>{
        'data': scene.data,
        'backgroundColor': stressChartBackground,
        'borderColor': '#36A2EB',
        'borderWidth': 1.0,
        'pointStyle': 'circle',
        'radius': 3.0,
        'showLine': false,
        'clip': false,
      },
    ],
  },
  'options': <String, Object?>{
    'animation': false,
    'events': <String>[],
    'maintainAspectRatio': false,
    'parsing': false,
    'layout': <String, Object?>{'autoPadding': false},
    ...options,
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'type': scene.x.name,
        'ticks': <String, Object?>{'autoSkip': autoSkip},
      },
      'y': <String, Object?>{'type': scene.y.name},
    },
  },
  'plugins': <Object?>[...plugins],
};

/// The tick count after the auto skip and the `labelRotation` of the x scale
/// of [chart], or Dart `null` before the first layout.
///
/// The figures of the stress tab (the STRESS line) and the BENCH line of an
/// `axes` case give them.
({int ticks, double rotation})? stressAxesTicks(Chart chart) {
  final scale = chart.scales['x'];
  final ticks = scale?.ticks;
  if (scale == null || ticks == null) return null;
  return (
    ticks: ticks.length,
    rotation: jsToNumber(scale.labelRotation),
  );
}
