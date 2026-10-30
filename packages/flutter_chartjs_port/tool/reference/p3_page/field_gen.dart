// Original code, not ported from Chart.js: the field of the P3 upstream page.

/// Writes `field.json`, the start values of the moving points of the
/// upstream page of the P3 comparison (`README.md` of this folder).
///
/// The values are those of `StressPointField(20000)` of
/// `apps/chartjs_gallery/lib/demo/stress_chart_config.dart`: seed 7 of
/// `dart:math` `Random`, in the order of its constructor. The loop below is a
/// copy of that constructor: this package does not import the gallery. A
/// change of `StressPointField` needs the same change here. The first `k`
/// values do not depend on the count, so a field of 20000 points also holds
/// the fields of the smaller cases.
///
/// The file also holds a check: the sums of x and y after 120 steps of 1/60 s
/// of the first 5000 points, with the loop of `StressPointField.step`. The
/// page runs the same steps in JavaScript and prints both sums in its line
/// `FIELD`: they must be equal.
///
/// Usage, from `packages/flutter_chartjs_port`:
///
/// ```sh
/// dart run tool/reference/p3_page/field_gen.dart tool/reference/p3_page/field.json
/// ```
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// The count of the points: the largest N of the cases.
const int fieldCount = 20000;

/// Writes the field to the path of the first argument.
void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run field_gen.dart <field.json>');
    exitCode = 64;
    return;
  }
  final x = List<double>.filled(fieldCount, 0);
  final y = List<double>.filled(fieldCount, 0);
  final vx = List<double>.filled(fieldCount, 0);
  final vy = List<double>.filled(fieldCount, 0);
  // The constructor of StressPointField.
  final random = math.Random(7);
  for (var i = 0; i < fieldCount; i++) {
    x[i] = random.nextDouble();
    y[i] = random.nextDouble();
    final angle = random.nextDouble() * 2 * math.pi;
    final speed = 0.05 + random.nextDouble() * 0.25;
    vx[i] = math.cos(angle) * speed;
    vy[i] = math.sin(angle) * speed;
  }
  // The check: StressPointField.step of the first 5000 points, 120 times.
  const steps = 120;
  const n = 5000;
  final cx = List.of(x);
  final cy = List.of(y);
  final cvx = List.of(vx);
  final cvy = List.of(vy);
  for (var s = 0; s < steps; s++) {
    for (var i = 0; i < n; i++) {
      var px = cx[i] + cvx[i] * (1 / 60);
      var py = cy[i] + cvy[i] * (1 / 60);
      if (px < 0 || px > 1) {
        cvx[i] = -cvx[i];
        px = px.clamp(0, 1).toDouble();
      }
      if (py < 0 || py > 1) {
        cvy[i] = -cvy[i];
        py = py.clamp(0, 1).toDouble();
      }
      cx[i] = px;
      cy[i] = py;
    }
  }
  var sumX = 0.0;
  var sumY = 0.0;
  for (var i = 0; i < n; i++) {
    sumX += cx[i];
    sumY += cy[i];
  }
  File(args.single).writeAsStringSync(
    jsonEncode({
      'seed': 7,
      'count': fieldCount,
      'x': x,
      'y': y,
      'vx': vx,
      'vy': vy,
      'check': {'steps': steps, 'n': n, 'sumX': sumX, 'sumY': sumY},
    }),
  );
  stdout.writeln('check sumX=$sumX sumY=$sumY');
}
