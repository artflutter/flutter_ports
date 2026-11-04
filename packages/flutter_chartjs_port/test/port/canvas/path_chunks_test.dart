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

void main() {
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
