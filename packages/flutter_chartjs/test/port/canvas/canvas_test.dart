// Original code, not ported from Chart.js: tests of the pure Path2D.
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:test/test.dart';

/// A [CanvasPath] that records the calls, as `{name, args}` maps.
final class _Recorder implements CanvasPath {
  final List<Map<String, Object?>> calls = [];

  void _record(String name, List<Object?> args) =>
      calls.add({'name': name, 'args': args});

  @override
  void closePath() => _record('closePath', []);

  @override
  void moveTo(double x, double y) => _record('moveTo', [x, y]);

  @override
  void lineTo(double x, double y) => _record('lineTo', [x, y]);

  @override
  void bezierCurveTo(
    double cp1x,
    double cp1y,
    double cp2x,
    double cp2y,
    double x,
    double y,
  ) => _record('bezierCurveTo', [cp1x, cp1y, cp2x, cp2y, x, y]);

  @override
  void quadraticCurveTo(double cpx, double cpy, double x, double y) =>
      _record('quadraticCurveTo', [cpx, cpy, x, y]);

  @override
  void arc(
    double x,
    double y,
    double radius,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) => _record('arc', [x, y, radius, startAngle, endAngle, counterclockwise]);

  @override
  void arcTo(double x1, double y1, double x2, double y2, double radius) =>
      _record('arcTo', [x1, y1, x2, y2, radius]);

  @override
  void ellipse(
    double x,
    double y,
    double radiusX,
    double radiusY,
    double rotation,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) => _record('ellipse', [
    x,
    y,
    radiusX,
    radiusY,
    rotation,
    startAngle,
    endAngle,
    counterclockwise,
  ]);

  @override
  void rect(double x, double y, double w, double h) =>
      _record('rect', [x, y, w, h]);
}

void main() {
  group('Path2D', () {
    test('records the commands and replays them in order', () {
      final path = Path2D()
        ..moveTo(1, 2)
        ..lineTo(3, 4)
        ..bezierCurveTo(1, 2, 3, 4, 5, 6)
        ..quadraticCurveTo(1, 2, 3, 4)
        ..arc(1, 2, 3, 0, 1)
        ..arc(1, 2, 3, 0, 1, true)
        ..arcTo(1, 2, 3, 4, 5)
        ..ellipse(1, 2, 3, 4, 0.5, 0, 1)
        ..rect(1, 2, 3, 4)
        ..closePath();
      expect(path.commands, hasLength(10));
      final recorder = _Recorder();
      path.replay(recorder);
      expect(recorder.calls, [
        {
          'name': 'moveTo',
          'args': [1, 2],
        },
        {
          'name': 'lineTo',
          'args': [3, 4],
        },
        {
          'name': 'bezierCurveTo',
          'args': [1, 2, 3, 4, 5, 6],
        },
        {
          'name': 'quadraticCurveTo',
          'args': [1, 2, 3, 4],
        },
        {
          'name': 'arc',
          'args': [1, 2, 3, 0, 1, false],
        },
        {
          'name': 'arc',
          'args': [1, 2, 3, 0, 1, true],
        },
        {
          'name': 'arcTo',
          'args': [1, 2, 3, 4, 5],
        },
        {
          'name': 'ellipse',
          'args': [1, 2, 3, 4, 0.5, 0, 1, false],
        },
        {
          'name': 'rect',
          'args': [1, 2, 3, 4],
        },
        {'name': 'closePath', 'args': <Object?>[]},
      ]);
    });

    test('the version counts the changes', () {
      final path = Path2D();
      expect(path.version, 0);
      path.moveTo(0, 0);
      final version = path.version;
      path.lineTo(1, 1);
      expect(path.version, greaterThan(version));
    });

    test('the cache slot keeps a value', () {
      final path = Path2D()..cache = 'converted';
      expect(path.cache, 'converted');
    });

    test('a negative radius throws and records nothing', () {
      final path = Path2D();
      expect(() => path.arc(0, 0, -1, 0, 1), throwsRangeError);
      expect(() => path.arcTo(0, 0, 1, 1, -1), throwsRangeError);
      expect(() => path.ellipse(0, 0, -1, 1, 0, 0, 1), throwsRangeError);
      expect(() => path.ellipse(0, 0, 1, -1, 0, 0, 1), throwsRangeError);
      expect(path.commands, isEmpty);
    });

    test('replays onto another Path2D', () {
      final source = Path2D()
        ..moveTo(0, 0)
        ..lineTo(1, 0)
        ..closePath();
      final copy = Path2D();
      source.replay(copy);
      final a = _Recorder();
      final b = _Recorder();
      source.replay(a);
      copy.replay(b);
      expect(b.calls, a.calls);
    });
  });
}
