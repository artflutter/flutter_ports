// Original code, not ported from Chart.js: the chart of the stress mode chart.

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chartjs_gallery/demo/stress_point_controller.dart';
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

/// The config of the stress mode chart (Chart.js ADR 0021, section 8): one
/// dataset of the data objects [data] (see [StressPointField.data]) of
/// `StressPointController`.
///
/// - [sharing] is the dataset option `optionSharing`: true as in a line
///   chart, false as in a scatter chart.
/// - [scriptable] gives the points the scriptable `backgroundColor`
///   [stressScriptableBackground] (case (c)).
/// - [animate] gives the looping animation of the call `animate`. Without
///   it, the chart has `animation: false`.
/// - [options] adds chart options, after the options of the stress mode.
/// - [plugins] are the inline plugins of the chart.
///
/// The chart listens to no event (`events: []`), as the hosts of the other
/// modes take no pointer input. Otherwise a pointer over the host replays
/// its last event in each `update` (core.controller.js:528-534), which can
/// add a second draw to a frame.
///
/// The dataset has the colors, the border and the radius of the point
/// elements of the stress mode `elements`.
AnyObject stressChartConfig({
  required List<AnyObject> data,
  required bool sharing,
  required bool scriptable,
  bool animate = false,
  AnyObject options = const {},
  List<Object?> plugins = const [],
}) => <String, Object?>{
  'type': StressPointController.id,
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': data,
        'optionSharing': sharing,
        'backgroundColor': scriptable
            ? stressScriptableBackground
            : stressChartBackground,
        'borderColor': '#36A2EB',
        'borderWidth': 1.0,
        'pointStyle': 'circle',
        'radius': 3.0,
      },
    ],
  },
  'options': <String, Object?>{
    'animation': animate
        ? <String, Object?>{'duration': stressAnimateMs, 'loop': true}
        : false,
    'events': <String>[],
    'maintainAspectRatio': false,
    ...options,
  },
  'plugins': <Object?>[...plugins],
};
