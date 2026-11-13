// Original code, not ported from Chart.js: tests of the pure Path2D.
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:test/test.dart';

// Parse at runtime: some JavaScript constant paths canonicalize negative zero.
final double _negativeZero = double.parse('-0.0');

/// A [CanvasPath] that records the calls, as `{name, args}` maps.
final class _Recorder() implements CanvasPath {
  final List<Map<String, Object?>> calls = [];

  void Function(String)? onCall;

  void _record(String name, List<Object?> args) {
    calls.add({'name': name, 'args': args});
    onCall?.call(name);
  }

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

  @override
  void roundRect(double x, double y, double w, double h, [Object? radii]) =>
      _record('roundRect', [x, y, w, h, radii]);
}

// Original public replay loop, used as an oracle for platform-specific list
// iteration behavior when a callback changes the command count.
final class _ReplayReference() {
  final List<PathCommand> commands = [];

  void moveTo(double x, double y) => commands.add(MoveToCommand(x, y));
  void lineTo(double x, double y) => commands.add(LineToCommand(x, y));

  void replay(CanvasPath target) {
    for (final command in commands) {
      command.applyTo(target);
    }
  }
}

/// The geometry of `roundRect(x, y, w, h, radii)` as a list: left, top,
/// width, height, the upper-left, upper-right, lower-right and lower-left
/// radii, and the direction.
List<Object?>? _geometry(
  double x,
  double y,
  double w,
  double h,
  Object? radii,
) {
  final g = roundRectGeometry(x, y, w, h, radii);
  if (g == null) return null;
  return [
    g.left,
    g.top,
    g.width,
    g.height,
    g.upperLeft,
    g.upperRight,
    g.lowerRight,
    g.lowerLeft,
    g.clockwise,
  ];
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
        ..roundRect(1, 2, 3, 4, [0.5, 1])
        ..roundRect(1, 2, 3, 4)
        ..closePath();
      expect(path.commands, hasLength(12));
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
        {
          'name': 'roundRect',
          'args': [
            1,
            2,
            3,
            4,
            [0.5, 1],
          ],
        },
        {
          'name': 'roundRect',
          'args': [1, 2, 3, 4, null],
        },
        {'name': 'closePath', 'args': <Object?>[]},
      ]);
    });

    test('a long unobserved path materializes one live command list', () {
      final path = Path2D()..moveTo(_negativeZero, 0);
      for (var i = 0; i < 20000; i++) {
        path.lineTo(i.toDouble(), -i.toDouble());
        if (i % 257 == 0) path.closePath();
      }
      final before = path.version;
      final commands = path.commands;
      expect(identical(commands, path.commands), isTrue);
      expect(commands.length, before);
      expect((commands.first as MoveToCommand).x.isNegative, isTrue);
      final firstLine = commands[1];
      path.lineTo(123, 456);
      expect(identical(commands[1], firstLine), isTrue);
      expect((commands.last as LineToCommand).y, 456);
      commands.removeLast();
      expect(path.version, before);
      commands.clear();
      path.moveTo(7, 8);
      expect(identical(commands, path.commands), isTrue);
      expect(path.version, 1);
      expect((commands.single as MoveToCommand).x, 7);
    });

    test('compact coordinates retain non-finite values and signed zero', () {
      final path = Path2D()
        ..moveTo(_negativeZero, double.infinity)
        ..lineTo(double.nan, double.negativeInfinity)
        ..lineTo(0, _negativeZero);
      final a = path.commands[0] as MoveToCommand;
      final b = path.commands[1] as LineToCommand;
      final c = path.commands[2] as LineToCommand;
      expect(a.x.isNegative, isTrue);
      expect(a.y, double.infinity);
      expect(b.x.isNaN, isTrue);
      expect(b.y, double.negativeInfinity);
      expect(c.x.isNegative, isFalse);
      expect(c.y.isNegative, isTrue);
    });

    for (final exposed in [false, true]) {
      test('custom replay reads replacements live: exposed=$exposed', () {
        final path = Path2D();
        if (exposed) expect(path.commands, isEmpty);
        path
          ..moveTo(1, 2)
          ..lineTo(3, 4)
          ..closePath();
        final recorder = _Recorder()
          ..onCall = (name) {
            if (name == 'moveTo') {
              path.commands[1] = const LineToCommand(8, 9);
            }
          };
        path.replay(recorder);
        expect(recorder.calls[1], {
          'name': 'lineTo',
          'args': [8.0, 9.0],
        });
        expect(path.version, 3);
      });
      for (final remove in [false, true]) {
        test(
          'custom replay matches original count mutation: $exposed/$remove',
          () {
            Object observe({required bool reference}) {
              final path = Path2D();
              if (exposed) expect(path.commands, isEmpty);
              final original = _ReplayReference();
              path
                ..moveTo(1, 2)
                ..lineTo(3, 4);
              original
                ..moveTo(1, 2)
                ..lineTo(3, 4);
              var changed = false;
              final recorder = _Recorder()
                ..onCall = (name) {
                  if (changed) return;
                  changed = true;
                  if (remove) {
                    (reference ? original.commands : path.commands).clear();
                  } else if (reference) {
                    original.lineTo(5, 6);
                  } else {
                    path.lineTo(5, 6);
                  }
                };
              Object? error;
              try {
                if (reference) {
                  original.replay(recorder);
                } else {
                  path.replay(recorder);
                }
              } on Object catch (e) {
                error = e.runtimeType.toString();
              }
              return {
                'calls': recorder.calls,
                'error': error,
                'length': reference ? original.commands.length : path.version,
              };
            }

            expect(observe(reference: false), observe(reference: true));
          },
        );
      }
    }

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
      expect(() => path.roundRect(0, 0, 1, 1, -1), throwsRangeError);
      expect(() => path.roundRect(0, 0, 1, 1, [1, -1]), throwsRangeError);
      expect(() => path.roundRect(0, 0, 1, 1, <double>[]), throwsRangeError);
      expect(
        () => path.roundRect(0, 0, 1, 1, [1, 2, 3, 4, 5]),
        throwsRangeError,
      );
      expect(() => path.roundRect(0, 0, 1, 1, 'a'), throwsArgumentError);
      expect(path.commands, isEmpty);
    });

    test('roundRect keeps a copy of the radii list', () {
      final radii = <double>[1, 2];
      final path = Path2D()..roundRect(0, 0, 10, 10, radii);
      radii[0] = 5;
      final recorder = _Recorder();
      path.replay(recorder);
      expect(recorder.calls.single['args'], [
        0,
        0,
        10,
        10,
        [1, 2],
      ]);
    });

    test('roundRect records a call that does nothing', () {
      // The DOM returns before it examines the radii (step 1).
      final path = Path2D()..roundRect(double.nan, 0, 1, 1, [-1]);
      expect(path.commands, hasLength(1));
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

  group('roundRectGeometry', () {
    test('a non-finite x, y, w or h does nothing before the radii', () {
      for (final args in [
        [double.nan, 0.0, 1.0, 1.0],
        [0.0, double.infinity, 1.0, 1.0],
        [0.0, 0.0, double.negativeInfinity, 1.0],
        [0.0, 0.0, 1.0, double.nan],
      ]) {
        expect(
          roundRectGeometry(args[0], args[1], args[2], args[3], [-1, 2, 3]),
          isNull,
        );
        expect(
          roundRectGeometry(args[0], args[1], args[2], args[3], <double>[]),
          isNull,
        );
      }
    });

    test('a list of another length than 1 to 4 throws a RangeError', () {
      expect(() => roundRectGeometry(0, 0, 1, 1, <double>[]), throwsRangeError);
      expect(
        () => roundRectGeometry(0, 0, 1, 1, [1, 1, 1, 1, 1]),
        throwsRangeError,
      );
    });

    test('examines the radii in order: NaN does nothing, -1 throws', () {
      expect(_geometry(0, 0, 10, 10, double.nan), isNull);
      expect(_geometry(0, 0, 10, 10, double.infinity), isNull);
      expect(_geometry(0, 0, 10, 10, [1, double.nan, -1]), isNull);
      expect(
        () => roundRectGeometry(0, 0, 10, 10, [1, -1, double.nan]),
        throwsRangeError,
      );
      expect(() => roundRectGeometry(0, 0, 10, 10, -0.5), throwsRangeError);
    });

    test('DOMPointInit and other values throw an ArgumentError', () {
      expect(
        () => roundRectGeometry(0, 0, 10, 10, {'x': 1, 'y': 2}),
        throwsArgumentError,
      );
      expect(() => roundRectGeometry(0, 0, 10, 10, '1'), throwsArgumentError);
      expect(
        () => roundRectGeometry(0, 0, 10, 10, [1, '1']),
        throwsArgumentError,
      );
    });

    test('null and a null entry are 0, and an int is a number', () {
      expect(_geometry(0, 0, 10, 10, null), [0, 0, 10, 10, 0, 0, 0, 0, true]);
      expect(_geometry(0, 0, 10, 10, [null, 2]), [
        0,
        0,
        10,
        10,
        0,
        2,
        0,
        2,
        true,
      ]);
      expect(_geometry(0, 0, 10, 10, 3), [0, 0, 10, 10, 3, 3, 3, 3, true]);
    });

    test('assigns 1 to 4 radii to the corners (steps 7 to 10)', () {
      // [upperLeft, upperRight, lowerRight, lowerLeft]
      List<Object?> corners(Object radii) =>
          _geometry(0, 0, 100, 100, radii)!.sublist(4, 8);
      expect(corners(1), [1, 1, 1, 1]);
      expect(corners([1]), [1, 1, 1, 1]);
      expect(corners([1, 2]), [1, 2, 1, 2]);
      expect(corners([1, 2, 3]), [1, 2, 3, 2]);
      expect(corners([1, 2, 3, 4]), [1, 2, 3, 4]);
    });

    test('a negative w or h flips the rectangle and the corners', () {
      const radii = [1.0, 2.0, 3.0, 4.0];
      expect(_geometry(10, 20, -60, 80, radii), [
        -50,
        20,
        60,
        80,
        2,
        1,
        4,
        3,
        false,
      ]);
      expect(_geometry(10, 20, 60, -80, radii), [
        10,
        -60,
        60,
        80,
        4,
        3,
        2,
        1,
        false,
      ]);
      expect(_geometry(10, 20, -60, -80, radii), [
        -50,
        -60,
        60,
        80,
        3,
        4,
        1,
        2,
        true,
      ]);
    });

    test('scales all radii so that the corner curves do not overlap', () {
      // top 30 + 30 on a width of 40: 40 / 60.
      expect(_geometry(0, 0, 40, 100, 30), [
        0,
        0,
        40,
        100,
        20,
        20,
        20,
        20,
        true,
      ]);
      // The smallest ratio wins: left 10 + 30 on a height of 20 is 0.5.
      expect(_geometry(0, 0, 100, 20, [10, 5, 5, 30]), [
        0,
        0,
        100,
        20,
        5,
        2.5,
        2.5,
        15,
        true,
      ]);
      // Radii that fit do not scale.
      expect(_geometry(0, 0, 40, 40, [20, 20, 20, 20])!.sublist(4, 8), [
        20,
        20,
        20,
        20,
      ]);
      // A width of 0 scales the radii of its sides to 0.
      expect(_geometry(0, 0, 0, 40, [5, 5, 5, 5])!.sublist(4, 8), [0, 0, 0, 0]);
      // A side whose radii add up to 0 sets no ratio.
      expect(_geometry(0, 0, 0, 40, [0, 0, 0, 0])!.sublist(4, 8), [0, 0, 0, 0]);
      expect(_geometry(0, 0, 10, 40, [0, 0, 8, 0])!.sublist(4, 8), [
        0,
        0,
        8,
        0,
      ]);
    });

    test('the scale uses the flipped width and height', () {
      expect(_geometry(40, 0, -40, 100, 30)!.sublist(0, 8), [
        0,
        0,
        40,
        100,
        20,
        20,
        20,
        20,
      ]);
    });
  });
}
