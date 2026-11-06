// Original code, not ported from Chart.js: the scalar control point writes.
import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

List<types.PointElement> _points(int seed) {
  final r = math.Random(seed);
  var x = 0.0;
  return [
    for (var i = 0; i < 2 + r.nextInt(30); i++)
      () {
        final point = PointElement()
          ..x = r.nextInt(20) == 0 ? double.nan : x += r.nextInt(4).toDouble()
          ..y = switch (r.nextInt(20)) {
            0 => double.nan,
            1 => double.infinity,
            2 => 5,
            _ => r.nextDouble() * 100,
          };
        if (r.nextInt(8) == 0) point.skip = true;
        return point;
      }(),
  ];
}

void main() {
  test('the writes equal splineCurve of each point', () {
    for (var seed = 0; seed < 3000; seed++) {
      final points = _points(seed);
      final tension = seed % 5 * .25;
      final loop = seed.isOdd;
      updateBezierControlPoints(
        points,
        <String, Object?>{
          'tension': tension,
          'capBezierPoints': false,
          'spanGaps': false,
          'cubicInterpolationMode': 'default',
        },
        null,
        loop,
        'x',
      );
      var prev = loop ? points.last : points.first;
      final ilen = points.length;
      for (var i = 0; i < ilen; i++) {
        final point = points[i];
        final curve = splineCurve(
          prev,
          point,
          points[math.min<int>(i + 1, ilen - (loop ? 0 : 1)).remainder(ilen)],
          tension,
        );
        void same(double actual, double expected) => expect(
          actual.isNaN && expected.isNaN || actual == expected,
          isTrue,
          reason: 'seed $seed, point $i: $actual and $expected',
        );
        same(point.cp1x, curve.previous.x);
        same(point.cp1y, curve.previous.y);
        same(point.cp2x, curve.next.x);
        same(point.cp2y, curve.next.y);
        prev = point;
      }
    }
  });

  test('a write ends the undefined state of a control point', () {
    final points = <types.PointElement>[
      PointElement()
        ..x = 0
        ..y = 0,
      PointElement()
        ..x = 1
        ..y = 1,
      PointElement()
        ..x = 2
        ..y = 0,
    ];
    expect((points[1] as PointElement)['cp1x'], isNot(isA<double>()));
    updateBezierControlPoints(
      points,
      <String, Object?>{'tension': .4, 'capBezierPoints': false},
      null,
      false,
      'x',
    );
    expect((points[1] as PointElement)['cp1x'], isA<double>());
    expect((points[1] as PointElement)['cp2y'], isA<double>());
  });
}
