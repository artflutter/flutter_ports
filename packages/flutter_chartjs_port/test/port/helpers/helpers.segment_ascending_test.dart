// Original code, not ported from Chart.js: the proof of an ascending segment.
import 'dart:collection';
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

  test('an index that is not finite gives what the loop gives', () {
    final points = <types.PointElement>[
      for (final x in [1.0, 2.0, 3.0]) PointElement()..x = x,
    ];
    for (final (start, end) in [
      (double.nan, 2.0),
      (0.0, double.nan),
      (double.nan, double.nan),
      (double.infinity, 2.0),
      (0.0, double.negativeInfinity),
      (double.infinity, double.negativeInfinity),
    ]) {
      expect(
        boundSegment(_RawSegment(start, end), points, (
          property: 'x',
          start: 1,
          end: 3,
        )),
        isEmpty,
        reason: '$start $end',
      );
    }
  });

  test('a negative zero index gives what the loop gives', () {
    final zero = double.parse('-0');
    final native = <types.PointElement>[PointElement()..x = 0];
    final user = <types.PointElement>[_UserPoint()..x = 0];
    for (final (start, end) in [(zero, 0.0), (0.0, zero), (zero, zero)]) {
      final segment = _RawSegment(start, end);
      const bounds = (property: 'x', start: 0.0, end: 0.0);
      final a = boundSegment(segment, native, bounds).single;
      final b = boundSegment(segment, user, bounds).single;
      expect(a.start.isNegative, b.start.isNegative);
      expect(a.end.isNegative, b.end.isNegative);
    }
  });

  test('a user list keeps the reads of the loop', () {
    final reads = <int>[];
    final points = _CountingList([
      for (final x in [1.0, 2.0, 2.0, 3.0]) PointElement()..x = x,
    ], reads);
    final segments = boundSegment(createBoundarySegment(0, 3), points, (
      property: 'x',
      start: 1,
      end: 3,
    ));
    expect(segments.single.end, 3);
    expect(reads, [0, 1, 2, 3]);
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

final class _RawSegment implements types.Segment {
  _RawSegment(this.start, this.end);
  @override
  final double start;
  @override
  final double end;
  @override
  bool get loop => false;
  @override
  Object? get style => null;
}

final class _CountingList extends ListBase<types.PointElement> {
  _CountingList(this._items, this._reads);
  final List<types.PointElement> _items;
  final List<int> _reads;
  @override
  int get length => _items.length;
  @override
  set length(int value) => _items.length = value;
  @override
  types.PointElement operator [](int index) {
    _reads.add(index);
    return _items[index];
  }

  @override
  void operator []=(int index, types.PointElement value) =>
      _items[index] = value;
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
