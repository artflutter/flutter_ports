// Original code, not ported from Chart.js: the chart of the stress mode chart.

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chartjs_gallery/demo/gallery_components.dart';
import 'package:flutter_chartjs/src/js/js_number.dart' show jsToNumber;
import 'package:flutter_chartjs/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs/src/types/basic.dart';

/// The duration of the looping animation of the call `animate` of the
/// stress mode chart, in ms.
const int stressAnimateMs = 1000;

/// The background color of the chart points, as in the stress mode
/// `elements`.
const String stressChartBackground = 'rgba(54, 162, 235, 0.45)';

/// The background color of the odd chart points of the scriptable
/// `backgroundColor`.
const String stressChartBackgroundOdd = 'rgba(255, 99, 132, 0.45)';

/// The scriptable `backgroundColor` of case (c). It reads the data index of
/// its context, as the scriptable option of a user does. The option needs
/// the context. Thus the resolver gives `$shared` false, and each update
/// resolves the options of each point (core.config.js:355-356).
Object? stressScriptableBackground(Object? context) =>
    jsToNumber(jsGet(context, 'dataIndex')) % 2 == 0
    ? stressChartBackground
    : stressChartBackgroundOdd;

/// The moving points of the stress tab and of the chart benchmark.
///
/// The positions are fractions of the chart, from 0 to 1. The velocities
/// are fractions of the chart per second. The seed 7 gives the same points
/// in each process. Point `i` gets the same values for each point count
/// larger than `i`. Thus a field of N points has the first N points of the
/// stress tab.
final class StressPointField {
  /// Makes [count] points at random positions, with random directions and
  /// speeds.
  StressPointField(int count)
    : x = Float64List(count),
      y = Float64List(count),
      vx = Float64List(count),
      vy = Float64List(count) {
    final random = math.Random(7);
    for (var i = 0; i < count; i++) {
      x[i] = random.nextDouble();
      y[i] = random.nextDouble();
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 0.05 + random.nextDouble() * 0.25;
      vx[i] = math.cos(angle) * speed;
      vy[i] = math.sin(angle) * speed;
    }
  }

  /// The x positions.
  final Float64List x;

  /// The y positions.
  final Float64List y;

  /// The x velocities.
  final Float64List vx;

  /// The y velocities.
  final Float64List vy;

  /// Moves the first [n] points by their velocities for [dt] seconds. A
  /// point that goes out of the range 0 to 1 stops at the edge and turns
  /// back.
  void step(int n, double dt) {
    for (var i = 0; i < n; i++) {
      var px = x[i] + vx[i] * dt;
      var py = y[i] + vy[i] * dt;
      if (px < 0 || px > 1) {
        vx[i] = -vx[i];
        px = px.clamp(0, 1);
      }
      if (py < 0 || py > 1) {
        vy[i] = -vy[i];
        py = py.clamp(0, 1);
      }
      x[i] = px;
      y[i] = py;
    }
  }

  /// The data objects `{x, y}` of the first [n] points, at their positions.
  List<AnyObject> data(int n) => [
    for (var i = 0; i < n; i++) <String, Object?>{'x': x[i], 'y': y[i]},
  ];

  /// Writes the positions of the points into the data objects [data].
  void write(List<AnyObject> data) {
    for (var i = 0; i < data.length; i++) {
      data[i]
        ..['x'] = x[i]
        ..['y'] = y[i];
    }
  }
}

/// The chart types of the stress mode `chart` (`--dart-define=TYPE=<name>`).
/// The name is the `type` of the chart config.
enum StressChartType {
  /// `LineController` with `showLine: false`: the points of phase 5.
  line(stressPointCounts, sharing: true),

  /// `ScatterController`: the points of phase 5 without option sharing.
  scatter(stressPointCounts, sharing: false),

  /// `BarController`: N bars on a hidden category axis.
  bar(stressPointCounts, sharing: true),

  /// `BubbleController`: N bubbles `{x, y, r}`.
  bubble(stressPointCounts, sharing: true),

  /// `DoughnutController`: N arcs.
  doughnut(stressArcCounts, sharing: true),

  /// `PieController`: N arcs.
  pie(stressArcCounts, sharing: true),

  /// `PolarAreaController`: N arcs on a hidden radial axis.
  polarArea(stressArcCounts, sharing: false),

  /// `RadarController`: one line of N points on a hidden radial axis.
  radar(stressArcCounts, sharing: false);

  const StressChartType(this.counts, {required this.sharing});

  /// The N choices of the type, in ascending order.
  final List<int> counts;

  /// `enableOptionSharing` of the controller (controller.line.js:35-39,
  /// controller.bar.js:380, controller.bubble.js:38,
  /// controller.doughnut.js:136). A test compares it with the controller.
  final bool sharing;

  /// Whether the config is the line and scatter form of Chart.js ADR 0031
  /// section 3: `parsing: false` and the data objects of the field.
  bool get points => this == line || this == scatter;
}

/// The counts of the points: 1000, 5000 and 20000.
const List<int> stressPointCounts = [1000, 5000, 20000];

/// The counts of the radial types, as the stress mode `arcs`.
const List<int> stressArcCounts = [100, 1000, 5000];

/// The data of a chart of the stress mode `chart`: N items of a type, at
/// the values of a `StressPointField`.
final class StressChartScene {
  /// The first [n] items of [type], at the positions of [field].
  StressChartScene(this.type, this.n, StressPointField field)
    : labels = [
        if (_labeled(type))
          for (var i = 0; i < n; i++) 'Point $i',
      ],
      data = _data(type, n, field);

  /// The chart type.
  final StressChartType type;

  /// The item count.
  final int n;

  /// `data.labels`: `Point <i>` for bar, doughnut, pie, polarArea and
  /// radar; empty for line, scatter and bubble.
  final List<Object?> labels;

  /// The dataset data:
  /// - line, scatter: the data objects `{x, y}` of `field.data(n)`;
  /// - bubble: `{x, y, r}` with `r = 2 + 4 * (vx / 0.3)^2`;
  /// - bar, radar: the numbers `y`;
  /// - doughnut, pie, polarArea: the numbers `0.05 + 0.95 * y`.
  final List<Object?> data;

  /// The bubble radius of the x velocity [vx]: `2 + 4 * (vx / 0.3)^2`.
  static double _radius(double vx) {
    final v = vx / 0.3;
    return 2 + 4 * v * v;
  }

  static bool _labeled(StressChartType type) =>
      !type.points && type != StressChartType.bubble;

  /// Whether [type] has the arc values `0.05 + 0.95 * y`: no arc is empty.
  static bool _arcs(StressChartType type) =>
      type == StressChartType.doughnut ||
      type == StressChartType.pie ||
      type == StressChartType.polarArea;

  static List<Object?> _data(
    StressChartType type,
    int n,
    StressPointField field,
  ) {
    if (type.points) return field.data(n);
    if (type == StressChartType.bubble) {
      return [
        for (var i = 0; i < n; i++)
          <String, Object?>{
            'x': field.x[i],
            'y': field.y[i],
            'r': _radius(field.vx[i]),
          },
      ];
    }
    final arcs = _arcs(type);
    return [
      for (var i = 0; i < n; i++)
        if (arcs) 0.05 + 0.95 * field.y[i] else field.y[i],
    ];
  }

  /// Writes the moved values of [field] into [data] in place. bubble
  /// keeps its `r`.
  void write(StressPointField field) {
    final data = this.data;
    final x = field.x;
    final y = field.y;
    if (type.points || type == StressChartType.bubble) {
      for (var i = 0; i < n; i++) {
        (data[i]! as AnyObject)
          ..['x'] = x[i]
          ..['y'] = y[i];
      }
      return;
    }
    if (_arcs(type)) {
      for (var i = 0; i < n; i++) {
        data[i] = 0.05 + 0.95 * y[i];
      }
      return;
    }
    for (var i = 0; i < n; i++) {
      data[i] = y[i];
    }
  }
}

/// A hidden scale with user bounds (Chart.js ADR 0031 section 5).
AnyObject stressHiddenScale(String type, {double? min, double? max}) =>
    <String, Object?>{
      'type': type,
      'display': false,
      'ticks': <String, Object?>{'display': false},
      'min': ?min,
      'max': ?max,
    };

/// The scales of a type of the stress mode `chart` (Chart.js ADR 0031
/// sections 3 and 5), or Dart `null` for no `scales` option.
AnyObject? _stressScales(StressChartType type) => switch (type) {
  StressChartType.line || StressChartType.scatter => unitScales(
    hideTicks: true,
  ),
  StressChartType.bar => <String, Object?>{
    'x': stressHiddenScale('category'),
    'y': stressHiddenScale('linear', min: 0, max: 1),
  },
  StressChartType.bubble => <String, Object?>{
    'x': stressHiddenScale('linear', min: 0, max: 1),
    'y': stressHiddenScale('linear', min: 0, max: 1),
  },
  StressChartType.doughnut || StressChartType.pie => null,
  StressChartType.polarArea || StressChartType.radar => <String, Object?>{
    'r': stressHiddenScale('radialLinear', min: 0, max: 1),
  },
};

/// The config of the stress mode `chart` (Chart.js ADR 0031 sections 3
/// and 5): one dataset of the items of [scene].
///
/// - [scriptable]: the scriptable `backgroundColor` of case (c),
///   [stressScriptableBackground].
/// - [showLine]: the dataset option `showLine` of line and scatter.
///   Another type throws an [ArgumentError] when it is true.
/// - [animate]: the looping animation of the call `animate`. Without it,
///   the chart has `animation: false`.
/// - [options]: more chart options, after the options of the mode.
/// - [plugins]: the inline plugins.
///
/// line and scatter have `parsing: false`, `layout.autoPadding: false`, the
/// dataset option `clip: false` and two hidden linear scales of the
/// fractions 0 to 1 ([unitScales]). Thus each point is at the pixel of the
/// phase 5 fraction path, the chart area is the canvas, and all points
/// draw, also with the unsorted x of the field (Chart.js ADR 0031 section
/// 3). With `showLine: false`, the line of a line chart has `borderWidth: 0`
/// (controller.line.js:63-65): the draw has only the point calls. The other
/// types use the default parsing of their controller and hidden scales with
/// user bounds (section 5).
///
/// The chart listens to no event (`events: []`), as the hosts of the other
/// modes take no pointer input. Otherwise a pointer over the host replays
/// its last event in each `update` (core.controller.js:528-534), which can
/// add a second draw to a frame.
///
/// The dataset has the colors and the border of the stress mode `elements`.
/// Only line and scatter also get the point style and the radius of phase 5
/// (Chart.js ADR 0031, section 3). The other types keep the upstream
/// defaults (section 5): the dataset option `radius` is also the `radius`
/// of the doughnut and pie controller (controller.doughnut.js:229), and a
/// value of 3 makes each arc 3 px.
AnyObject stressChartConfig({
  required StressChartScene scene,
  required bool scriptable,
  bool showLine = false,
  bool animate = false,
  AnyObject options = const {},
  List<Object?> plugins = const [],
}) {
  final type = scene.type;
  if (showLine && !type.points) {
    throw ArgumentError.value(showLine, 'showLine', 'Not line or scatter');
  }
  final scales = _stressScales(type);
  return <String, Object?>{
    'type': type.name,
    'data': <String, Object?>{
      if (scene.labels.isNotEmpty) 'labels': scene.labels,
      'datasets': <Object?>[
        <String, Object?>{
          'data': scene.data,
          'backgroundColor': scriptable
              ? stressScriptableBackground
              : stressChartBackground,
          'borderColor': '#36A2EB',
          'borderWidth': 1.0,
          if (type.points) ...{
            'pointStyle': 'circle',
            'radius': 3.0,
            'showLine': showLine,
            'clip': false,
          },
        },
      ],
    },
    'options': <String, Object?>{
      'animation': animate
          ? <String, Object?>{'duration': stressAnimateMs, 'loop': true}
          : false,
      'events': <String>[],
      'maintainAspectRatio': false,
      if (type.points) ...{
        'parsing': false,
        'layout': <String, Object?>{'autoPadding': false},
      },
      'scales': ?scales,
      ...options,
    },
    'plugins': <Object?>[...plugins],
  };
}
