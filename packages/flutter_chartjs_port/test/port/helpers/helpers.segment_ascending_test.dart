// Original code, not ported from Chart.js: the proof of an ascending segment.
import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

/// A point of a user class: it takes the loop of `boundSegment`.
class _UserPoint extends PointElement {}

List<Object?> _trace(List<types.Segment> segments) => [
  for (final s in segments) (s.start, s.end, s.loop, s.style),
];

void _compare(
  List<double> xs,
  double start,
  double end, {
  bool skip = false,
  int? from,
  int? to,
}) {
  final native = <types.PointElement>[
    for (final x in xs) PointElement()..x = x,
  ];
  final user = <types.PointElement>[for (final x in xs) _UserPoint()..x = x];
  if (skip && xs.length > 2) {
    (native[1] as PointElement).skip = true;
    (user[1] as PointElement).skip = true;
  }
  final segment = createBoundarySegment(from ?? 0, to ?? xs.length - 1);
  final bounds = (property: 'x', start: start, end: end);
  expect(
    _trace(boundSegment(segment, native, bounds)),
    _trace(boundSegment(segment, user, bounds)),
    reason: 'xs $xs, bounds $start $end, skip $skip, from $from, to $to',
  );
}

void main() {
  test('exact bounds of ascending points', () {
    _compare([1, 2, 3, 4], 1, 4);
    _compare([1], 1, 1);
    _compare([1, 2], 1, 2);
    _compare([0, 1e-7, 2e-7], 0, 2e-7);
  });

  test('a point within the epsilon of the end bound', () {
    _compare([1, 2, 4 - 1e-7, 4], 1, 4);
    _compare([1, 2, 4 - 1e-6, 4], 1, 4);
    _compare([1, 4 - 9e-7, 4 - 1e-7, 4], 1, 4);
    _compare([1, 2, 4 - 2e-6, 4], 1, 4);
  });

  test('equal, falling and missing values', () {
    _compare([1, 1, 2, 3], 1, 3);
    _compare([1, 2, 2, 3], 1, 3);
    _compare([1, 3, 2, 4], 1, 4);
    _compare([1, double.nan, 3], 1, 3);
    _compare([double.nan, 2, 3], double.nan, 3);
    _compare([1, 2, double.infinity], 1, double.infinity);
  });

  test('other bounds and parts', () {
    _compare([1, 2, 3, 4], 2, 3);
    _compare([1, 2, 3, 4], 0, 5);
    _compare([1, 2, 3, 4], 4, 1);
    _compare([1, 2, 3, 4], 1, 4, skip: true);
    _compare([1, 2, 3, 4, 5], 2, 4, from: 1, to: 3);
    _compare([1, 2, 3, 4, 5], 1, 5, from: 1, to: 3);
  });

  test('seeded sequences', () {
    for (var seed = 0; seed < 4000; seed++) {
      final r = math.Random(seed);
      final count = 1 + r.nextInt(12);
      var x = r.nextDouble() * 4;
      final xs = <double>[
        for (var i = 0; i < count; i++)
          x += switch (r.nextInt(9)) {
            0 => 0,
            1 => 1e-7,
            2 => 1e-6,
            3 => -r.nextDouble(),
            _ => r.nextDouble(),
          },
      ];
      final exact = r.nextInt(3) != 0;
      final from = exact ? 0 : r.nextInt(count);
      final to = exact ? count - 1 : from + r.nextInt(count - from);
      _compare(
        xs,
        exact ? xs[from] : xs[from] - r.nextDouble(),
        exact ? xs[to] : xs[to] + r.nextDouble() * .5,
        from: from,
        to: to,
        skip: r.nextInt(6) == 0,
      );
    }
  });

  test('a point of a user class reads no coordinate in the proof', () {
    var reads = 0;
    final points = <types.PointElement>[
      _CountingPoint(() => reads++, 1),
      _CountingPoint(() => reads++, 2),
    ];
    boundSegment(createBoundarySegment(0, 1), points, (
      property: 'x',
      start: 1,
      end: 2,
    ));
    // Only the read of the loop of `boundSegment` for each point.
    expect(reads, 2);
  });
}

class _CountingPoint extends PointElement {
  _CountingPoint(this._read, this._x);
  final void Function() _read;
  final double _x;
  @override
  double get x {
    _read();
    return _x;
  }
}
