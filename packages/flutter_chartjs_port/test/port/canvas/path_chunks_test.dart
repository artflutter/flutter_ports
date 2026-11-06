// Original code, not ported from Chart.js: chunked path storage contracts.
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:test/test.dart';

void _fill(Path2D path, int count, [double shift = 0]) {
  if (count == 0) return;
  path.moveTo(shift, 0);
  for (var i = 1; i < count; i++) {
    path.lineTo(shift + i % 503, (i % 17).toDouble());
  }
}

List<Object> _trace(Path2D path) => [
  for (final command in path.commands)
    switch (command) {
      final MoveToCommand c => ('move', c.x, c.y),
      final LineToCommand c => ('line', c.x, c.y),
      ClosePathCommand() => 'close',
      final BezierCurveToCommand c => (
        'curve',
        c.cp1x,
        c.cp1y,
        c.cp2x,
        c.cp2y,
        c.x,
        c.y,
      ),
      _ => throw StateError('Unexpected command in the test'),
    },
];

void _fillCurves(Path2D path, int count, int seed) {
  path.moveTo(1, 2);
  for (var i = 1; i <= count; i++) {
    final v = (i * 7 + seed) % 13 + .5;
    if (seed > 0 && i % seed == 0) {
      path.lineTo(v, -v);
    } else if (seed > 0 && i % (seed * 3) == 1) {
      path.closePath();
    } else {
      path.bezierCurveTo(v, i + .25, -v, i + .5, v * 2, i + .75);
    }
  }
}

void main() {
  for (final seed in [0, 1, 2, 5]) {
    for (final count in [
      1,
      4,
      5,
      6,
      15,
      340,
      341,
      342,
      343,
      681,
      682,
      683,
      1022,
      1023,
      1024,
      5000,
      20000,
    ]) {
      test('curves in compact storage, $count entries, seed $seed', () {
        final compact = Path2D();
        final eager = Path2D();
        final eagerList = eager.commands;
        _fillCurves(compact, count, seed);
        _fillCurves(eager, count, seed);
        expect(compact.version, eager.version);
        final replayed = Path2D();
        compact.replayNative(replayed);
        expect(replayed.version, eager.version);
        expect(_trace(replayed), _trace(eager));
        // The first read materializes one stable list.
        expect(_trace(compact), _trace(eager));
        expect(identical(compact.commands, compact.commands), isTrue);
        compact.bezierCurveTo(1, 2, 3, 4, 5, 6);
        eager.bezierCurveTo(1, 2, 3, 4, 5, 6);
        expect(_trace(compact), _trace(eager));
        expect(identical(eager.commands, eagerList), isTrue);
      });
    }
  }

  test('a curve keeps NaN, an infinity and a signed zero', () {
    final zero = double.parse('-0');
    final path = Path2D()
      ..bezierCurveTo(double.nan, zero, double.infinity, 1, 2, zero);
    final copy = Path2D();
    path.replayNative(copy);
    for (final target in [path, copy]) {
      final curve = target.commands.single as BezierCurveToCommand;
      expect(curve.cp1x.isNaN, isTrue);
      expect(curve.cp1y.isNegative, isTrue);
      expect(curve.cp2x, double.infinity);
      expect(curve.y.isNegative, isTrue);
    }
  });

  test('an old path keeps its curves after a new one', () {
    final old = Path2D();
    _fillCurves(old, 1000, 0);
    final expected = Path2D();
    _fillCurves(expected, 1000, 0);
    final newer = Path2D();
    _fillCurves(newer, 1000, 3);
    expect(_trace(old), _trace(expected));
  });

  for (final count in [
    0,
    1,
    15,
    16,
    17,
    1023,
    1024,
    1025,
    2047,
    2048,
    2049,
    20000,
    50000,
  ]) {
    test('command order and exposure at $count entries', () {
      final compact = Path2D();
      final eager = Path2D();
      final eagerList = eager.commands;
      _fill(compact, count);
      _fill(eager, count);
      expect(compact.version, count);
      compact
        ..closePath()
        ..moveTo(9, 8);
      eager
        ..closePath()
        ..moveTo(9, 8);
      expect(_trace(compact), _trace(eager));
      final retained = compact.commands;
      compact.lineTo(7, 6);
      eager.lineTo(7, 6);
      expect(identical(retained, compact.commands), isTrue);
      expect(identical(eagerList, eager.commands), isTrue);
      expect(_trace(compact), _trace(eager));
      retained.clear();
      compact.lineTo(5, 4);
      expect(compact.version, 1);
      expect(identical(retained, compact.commands), isTrue);
      expect(_trace(compact), [('line', 5.0, 4.0)]);
    });
  }

  test('old unobserved paths retain independent coordinates', () {
    final old = Path2D();
    _fill(old, 5000, 1);
    for (var i = 0; i < 20; i++) {
      final next = Path2D();
      _fill(next, 6000, i + 100.0);
      expect((next.commands.first as MoveToCommand).x, i + 100);
    }
    final reference = Path2D();
    reference.commands.clear();
    _fill(reference, 5000, 1);
    expect(_trace(old), _trace(reference));
  });

  for (final count in [1023, 1024, 1025, 5000]) {
    test('complex commands materialize $count entries in order', () {
      final compact = Path2D();
      final eager = Path2D();
      eager.commands.clear();
      for (final path in [compact, eager]) {
        _fill(path, count);
        path
          ..bezierCurveTo(1, 2, 3, 4, 5, 6)
          ..lineTo(8, 9);
      }
      expect(compact.version, count + 2);
      expect(_trace(compact), _trace(eager));
    });
  }
}
