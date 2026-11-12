// Original code, not ported from Chart.js: the walk of a curved line.
import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart'
    show DefaultCubicInterpolationMode, MonotoneCubicInterpolationMode;
import 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

List<types.PointElement> _points(int seed) {
  final r = math.Random(seed);
  return [
    for (var i = 0; i < 2 + r.nextInt(40); i++)
      () {
        final point = PointElement()
          ..x = i.toDouble()
          ..y = r.nextDouble() * 50
          ..cp1x = i - .3
          ..cp1y = r.nextDouble() * 50
          ..cp2x = i + .3
          ..cp2y = r.nextDouble() * 50;
        if (r.nextInt(9) == 0) point.skip = true;
        return point;
      }(),
  ];
}

List<Object?> _trace(Path2D path) => [
  for (final command in path.commands)
    switch (command) {
      final MoveToCommand c => ('move', c.x, c.y),
      final LineToCommand c => ('line', c.x, c.y),
      final BezierCurveToCommand c => (
        c.cp1x,
        c.cp1y,
        c.cp2x,
        c.cp2y,
        c.x,
        c.y,
      ),
      _ => command,
    },
];

void main() {
  test('typed options walk as options of a plain object', () {
    for (var seed = 0; seed < 600; seed++) {
      final points = _points(seed);
      final values = <String, Object?>{
        'tension': seed % 3 == 0 ? 0.0 : .4,
        'stepped': seed % 7 == 0,
        'cubicInterpolationMode': seed % 5 == 0
            ? const MonotoneCubicInterpolationMode()
            : const DefaultCubicInterpolationMode(),
        'borderDash': const <double>[],
        'spanGaps': false,
      };
      Path2D walk(Object options, Map<String, Object?>? params) {
        final line = LineElement()
          ..options = options
          ..points = points;
        final path = Path2D();
        line.pathSegment(
          path,
          createBoundarySegment(0, points.length - 1),
          params,
        );
        return path;
      }

      for (final params in <Map<String, Object?>?>[
        null,
        <String, Object?>{'reverse': true},
        <String, Object?>{'move': false},
        <String, Object?>{'start': 1, 'end': points.length - 1},
      ]) {
        expect(
          _trace(walk(LineOptions(values), params)),
          _trace(walk(values, params)),
          reason: 'seed $seed, params $params',
        );
      }
    }
  });
}
