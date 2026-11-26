// Ported from d3-path v3.1.0 test/path-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('path is an instanceof path', () {
    final p = path();
    expect(p, isA<Path>());
    assertPathEqual(p, '');
  });

  test('path.moveTo(x, y) appends an M command', () {
    final p = path()..moveTo(150, 50);
    assertPathEqual(p, 'M150,50');
    p.lineTo(200, 100);
    assertPathEqual(p, 'M150,50L200,100');
    p.moveTo(100, 50);
    assertPathEqual(p, 'M150,50L200,100M100,50');
  });

  test('path.closePath() appends a Z command', () {
    final p = path()..moveTo(150, 50);
    assertPathEqual(p, 'M150,50');
    p.closePath();
    assertPathEqual(p, 'M150,50Z');
    p.closePath();
    assertPathEqual(p, 'M150,50ZZ');
  });

  test('path.closePath() does nothing if the path is empty', () {
    final p = path();
    assertPathEqual(p, '');
    p.closePath();
    assertPathEqual(p, '');
  });

  test('path.lineTo(x, y) appends an L command', () {
    final p = path()..moveTo(150, 50);
    assertPathEqual(p, 'M150,50');
    p.lineTo(200, 100);
    assertPathEqual(p, 'M150,50L200,100');
    p.lineTo(100, 50);
    assertPathEqual(p, 'M150,50L200,100L100,50');
  });

  test('path.quadraticCurveTo(x1, y1, x, y) appends a Q command', () {
    final p = path()..moveTo(150, 50);
    assertPathEqual(p, 'M150,50');
    p.quadraticCurveTo(100, 50, 200, 100);
    assertPathEqual(p, 'M150,50Q100,50,200,100');
  });

  test('path.bezierCurveTo(x1, y1, x, y) appends a C command', () {
    final p = path()..moveTo(150, 50);
    assertPathEqual(p, 'M150,50');
    p.bezierCurveTo(100, 50, 0, 24, 200, 100);
    assertPathEqual(p, 'M150,50C100,50,0,24,200,100');
  });

  test('path.arc(x, y, radius, startAngle, endAngle) throws an error if the '
      'radius is negative', () {
    final p = path()..moveTo(150, 100);
    expect(
      () => p.arc(100, 100, -50, 0, math.pi / 2),
      throwsA(
        isA<RangeError>().having(
          (e) => e.toString(),
          'message',
          contains('negative radius'),
        ),
      ),
    );
  });

  test('path.arc(x, y, radius, startAngle, endAngle) may append only an M '
      'command if the radius is zero', () {
    final p = path()..arc(100, 100, 0, 0, math.pi / 2);
    assertPathEqual(p, 'M100,100');
  });

  test('path.arc(x, y, radius, startAngle, endAngle) may append only an L '
      'command if the radius is zero', () {
    final p = path()
      ..moveTo(0, 0)
      ..arc(100, 100, 0, 0, math.pi / 2);
    assertPathEqual(p, 'M0,0L100,100');
  });

  test('path.arc(x, y, radius, startAngle, endAngle) may append only an M '
      'command if the angle is zero', () {
    final p = path()..arc(100, 100, 0, 0, 0);
    assertPathEqual(p, 'M100,100');
  });

  test('path.arc(x, y, radius, startAngle, endAngle) may append only an M '
      'command if the angle is near zero', () {
    final p = path()..arc(100, 100, 0, 0, 1e-16);
    assertPathEqual(p, 'M100,100');
  });

  test(
    'path.arc(x, y, radius, startAngle, endAngle) may append an M command if '
    'the path was empty',
    () {
      final p1 = path()..arc(100, 100, 50, 0, math.pi * 2);
      assertPathEqual(p1, 'M150,100A50,50,0,1,1,50,100A50,50,0,1,1,150,100');
      final p2 = path()..arc(0, 50, 50, -math.pi / 2, 0);
      assertPathEqual(p2, 'M0,0A50,50,0,0,1,50,50');
    },
  );

  test(
    'path.arc(x, y, radius, startAngle, endAngle) may append an L command if '
    'the arc doesn’t start at the current point',
    () {
      final p = path()
        ..moveTo(100, 100)
        ..arc(100, 100, 50, 0, math.pi * 2);
      assertPathEqual(
        p,
        'M100,100L150,100A50,50,0,1,1,50,100A50,50,0,1,1,150,100',
      );
    },
  );

  test(
    'path.arc(x, y, radius, startAngle, endAngle) appends a single A command '
    'if the angle is less than π',
    () {
      final p = path()
        ..moveTo(150, 100)
        ..arc(100, 100, 50, 0, math.pi / 2);
      assertPathEqual(p, 'M150,100A50,50,0,0,1,100,150');
    },
  );

  test(
    'path.arc(x, y, radius, startAngle, endAngle) appends a single A command '
    'if the angle is less than τ',
    () {
      final p = path()
        ..moveTo(150, 100)
        ..arc(100, 100, 50, 0, math.pi * 1);
      assertPathEqual(p, 'M150,100A50,50,0,1,1,50,100');
    },
  );

  test('path.arc(x, y, radius, startAngle, endAngle) appends two A commands if '
      'the angle is greater than τ', () {
    final p = path()
      ..moveTo(150, 100)
      ..arc(100, 100, 50, 0, math.pi * 2);
    assertPathEqual(p, 'M150,100A50,50,0,1,1,50,100A50,50,0,1,1,150,100');
  });

  test('path.arc(x, y, radius, 0, π/2, false) draws a small clockwise arc', () {
    final p = path()
      ..moveTo(150, 100)
      ..arc(100, 100, 50, 0, math.pi / 2);
    assertPathEqual(p, 'M150,100A50,50,0,0,1,100,150');
  });

  test(
    'path.arc(x, y, radius, -π/2, 0, false) draws a small clockwise arc',
    () {
      final p = path()
        ..moveTo(100, 50)
        ..arc(100, 100, 50, -math.pi / 2, 0);
      assertPathEqual(p, 'M100,50A50,50,0,0,1,150,100');
    },
  );

  test('path.arc(x, y, radius, 0, ε, true) draws an anticlockwise circle', () {
    final p = path()
      ..moveTo(150, 100)
      ..arc(100, 100, 50, 0, 1e-16, true);
    assertPathEqual(p, 'M150,100A50,50,0,1,0,50,100A50,50,0,1,0,150,100');
  });

  test('path.arc(x, y, radius, 0, ε, false) draws nothing', () {
    final p = path()
      ..moveTo(150, 100)
      ..arc(100, 100, 50, 0, 1e-16);
    assertPathEqual(p, 'M150,100');
  });

  test('path.arc(x, y, radius, 0, -ε, true) draws nothing', () {
    final p = path()
      ..moveTo(150, 100)
      ..arc(100, 100, 50, 0, -1e-16, true);
    assertPathEqual(p, 'M150,100');
  });

  test('path.arc(x, y, radius, 0, -ε, false) draws a clockwise circle', () {
    final p = path()
      ..moveTo(150, 100)
      ..arc(100, 100, 50, 0, -1e-16);
    assertPathEqual(p, 'M150,100A50,50,0,1,1,50,100A50,50,0,1,1,150,100');
  });

  test('path.arc(x, y, radius, 0, τ, true) draws an anticlockwise circle', () {
    final p = path()
      ..moveTo(150, 100)
      ..arc(100, 100, 50, 0, 2 * math.pi, true);
    assertPathEqual(p, 'M150,100A50,50,0,1,0,50,100A50,50,0,1,0,150,100');
  });

  test('path.arc(x, y, radius, 0, τ, false) draws a clockwise circle', () {
    final p = path()
      ..moveTo(150, 100)
      ..arc(100, 100, 50, 0, 2 * math.pi);
    assertPathEqual(p, 'M150,100A50,50,0,1,1,50,100A50,50,0,1,1,150,100');
  });

  test(
    'path.arc(x, y, radius, 0, τ + ε, true) draws an anticlockwise circle',
    () {
      final p = path()
        ..moveTo(150, 100)
        ..arc(100, 100, 50, 0, 2 * math.pi + 1e-13, true);
      assertPathEqual(p, 'M150,100A50,50,0,1,0,50,100A50,50,0,1,0,150,100');
    },
  );

  test('path.arc(x, y, radius, 0, τ - ε, false) draws a clockwise circle', () {
    final p = path()
      ..moveTo(150, 100)
      ..arc(100, 100, 50, 0, 2 * math.pi - 1e-13);
    assertPathEqual(p, 'M150,100A50,50,0,1,1,50,100A50,50,0,1,1,150,100');
  });

  test('path.arc(x, y, radius, τ, 0, true) draws an anticlockwise circle', () {
    final p = path()
      ..moveTo(150, 100)
      ..arc(100, 100, 50, 0, 2 * math.pi, true);
    assertPathEqual(p, 'M150,100A50,50,0,1,0,50,100A50,50,0,1,0,150,100');
  });

  test('path.arc(x, y, radius, τ, 0, false) draws a clockwise circle', () {
    final p = path()
      ..moveTo(150, 100)
      ..arc(100, 100, 50, 0, 2 * math.pi);
    assertPathEqual(p, 'M150,100A50,50,0,1,1,50,100A50,50,0,1,1,150,100');
  });

  test('path.arc(x, y, radius, 0, 13π/2, false) draws a clockwise circle', () {
    final p = path()
      ..moveTo(150, 100)
      ..arc(100, 100, 50, 0, 13 * math.pi / 2);
    assertPathEqual(p, 'M150,100A50,50,0,1,1,50,100A50,50,0,1,1,150,100');
  });

  test('path.arc(x, y, radius, 13π/2, 0, false) draws a big clockwise arc', () {
    final p = path()
      ..moveTo(100, 150)
      ..arc(100, 100, 50, 13 * math.pi / 2, 0);
    assertPathEqual(p, 'M100,150A50,50,0,1,1,150,100');
  });

  test('path.arc(x, y, radius, π/2, 0, false) draws a big clockwise arc', () {
    final p = path()
      ..moveTo(100, 150)
      ..arc(100, 100, 50, math.pi / 2, 0);
    assertPathEqual(p, 'M100,150A50,50,0,1,1,150,100');
  });

  test(
    'path.arc(x, y, radius, 3π/2, 0, false) draws a small clockwise arc',
    () {
      final p = path()
        ..moveTo(100, 50)
        ..arc(100, 100, 50, 3 * math.pi / 2, 0);
      assertPathEqual(p, 'M100,50A50,50,0,0,1,150,100');
    },
  );

  test(
    'path.arc(x, y, radius, 15π/2, 0, false) draws a small clockwise arc',
    () {
      final p = path()
        ..moveTo(100, 50)
        ..arc(100, 100, 50, 15 * math.pi / 2, 0);
      assertPathEqual(p, 'M100,50A50,50,0,0,1,150,100');
    },
  );

  test(
    'path.arc(x, y, radius, 0, π/2, true) draws a big anticlockwise arc',
    () {
      final p = path()
        ..moveTo(150, 100)
        ..arc(100, 100, 50, 0, math.pi / 2, true);
      assertPathEqual(p, 'M150,100A50,50,0,1,0,100,150');
    },
  );

  test(
    'path.arc(x, y, radius, -π/2, 0, true) draws a big anticlockwise arc',
    () {
      final p = path()
        ..moveTo(100, 50)
        ..arc(100, 100, 50, -math.pi / 2, 0, true);
      assertPathEqual(p, 'M100,50A50,50,0,1,0,150,100');
    },
  );

  test(
    'path.arc(x, y, radius, -13π/2, 0, true) draws a big anticlockwise arc',
    () {
      final p = path()
        ..moveTo(100, 50)
        ..arc(100, 100, 50, -13 * math.pi / 2, 0, true);
      assertPathEqual(p, 'M100,50A50,50,0,1,0,150,100');
    },
  );

  test(
    'path.arc(x, y, radius, -13π/2, 0, false) draws a big clockwise arc',
    () {
      final p = path()
        ..moveTo(150, 100)
        ..arc(100, 100, 50, 0, -13 * math.pi / 2);
      assertPathEqual(p, 'M150,100A50,50,0,1,1,100,50');
    },
  );

  test(
    'path.arc(x, y, radius, 0, 13π/2, true) draws a big anticlockwise arc',
    () {
      final p = path()
        ..moveTo(150, 100)
        ..arc(100, 100, 50, 0, 13 * math.pi / 2, true);
      assertPathEqual(p, 'M150,100A50,50,0,1,0,100,150');
    },
  );

  test(
    'path.arc(x, y, radius, π/2, 0, true) draws a small anticlockwise arc',
    () {
      final p = path()
        ..moveTo(100, 150)
        ..arc(100, 100, 50, math.pi / 2, 0, true);
      assertPathEqual(p, 'M100,150A50,50,0,0,0,150,100');
    },
  );

  test(
    'path.arc(x, y, radius, 3π/2, 0, true) draws a big anticlockwise arc',
    () {
      final p = path()
        ..moveTo(100, 50)
        ..arc(100, 100, 50, 3 * math.pi / 2, 0, true);
      assertPathEqual(p, 'M100,50A50,50,0,1,0,150,100');
    },
  );

  test(
    'path.arc(x, y, radius, π/2, 0, truthy) draws a small anticlockwise arc',
    () {
      // Upstream passes [1, "1", true, 10, "3", "string"] to ccw.
      // Dart arc takes a typed bool ccw (D3 ADR 0014).
    },
    skip: 'diverges: adapt-path-typed-args',
  );

  test('path.arc(x, y, radius, 0, π/2, falsy) draws a small clockwise arc', () {
    // Upstream passes [0, null, undefined] to ccw.
    // Dart arc takes a typed bool ccw (D3 ADR 0014).
  }, skip: 'diverges: adapt-path-typed-args');

  test('path.arcTo(x1, y1, x2, y2, radius) throws an error if the radius is '
      'negative', () {
    final p = path()..moveTo(150, 100);
    expect(
      () => p.arcTo(270, 39, 163, 100, -53),
      throwsA(
        isA<RangeError>().having(
          (e) => e.toString(),
          'message',
          contains('negative radius'),
        ),
      ),
    );
  });

  test(
    'path.arcTo(x1, y1, x2, y2, radius) appends an M command if the path was '
    'empty',
    () {
      final p = path()..arcTo(270, 39, 163, 100, 53);
      assertPathEqual(p, 'M270,39');
    },
  );

  test('path.arcTo(x1, y1, x2, y2, radius) does nothing if the previous point '
      'was ⟨x1,y1⟩', () {
    final p = path()
      ..moveTo(270, 39)
      ..arcTo(270, 39, 163, 100, 53);
    assertPathEqual(p, 'M270,39');
  });

  test(
    'path.arcTo(x1, y1, x2, y2, radius) appends an L command if the previous '
    'point, ⟨x1,y1⟩ and ⟨x2,y2⟩ are collinear',
    () {
      final p = path()
        ..moveTo(100, 50)
        ..arcTo(101, 51, 102, 52, 10);
      assertPathEqual(p, 'M100,50L101,51');
    },
  );

  test('path.arcTo(x1, y1, x2, y2, radius) appends an L command if ⟨x1,y1⟩ and '
      '⟨x2,y2⟩ are coincident', () {
    final p = path()
      ..moveTo(100, 50)
      ..arcTo(101, 51, 101, 51, 10);
    assertPathEqual(p, 'M100,50L101,51');
  });

  test('path.arcTo(x1, y1, x2, y2, radius) appends an L command if the radius '
      'is zero', () {
    final p = path()
      ..moveTo(270, 182)
      ..arcTo(270, 39, 163, 100, 0);
    assertPathEqual(p, 'M270,182L270,39');
  });

  test('path.arcTo(x1, y1, x2, y2, radius) appends L and A commands if the arc '
      'does not start at the current point', () {
    final p1 = path()
      ..moveTo(270, 182)
      ..arcTo(270, 39, 163, 100, 53);
    assertPathEqual(
      p1,
      'M270,182L270,130.222686A53,53,0,0,0,190.750991,84.179342',
    );
    final p2 = path()
      ..moveTo(270, 182)
      ..arcTo(270, 39, 363, 100, 53);
    assertPathEqual(
      p2,
      'M270,182L270,137.147168A53,53,0,0,1,352.068382,92.829799',
    );
  });

  test(
    'path.arcTo(x1, y1, x2, y2, radius) appends only an A command if the arc '
    'starts at the current point',
    () {
      final p = path()
        ..moveTo(100, 100)
        ..arcTo(200, 100, 200, 200, 100);
      assertPathEqual(p, 'M100,100A100,100,0,0,1,200,200');
    },
  );

  test('path.arcTo(x1, y1, x2, y2, radius) sets the last point to be the end '
      'tangent of the arc', () {
    final p = path()
      ..moveTo(100, 100)
      ..arcTo(200, 100, 200, 200, 50)
      ..arc(150, 150, 50, 0, math.pi);
    assertPathEqual(
      p,
      'M100,100L150,100A50,50,0,0,1,200,150A50,50,0,1,1,100,150',
    );
  });

  test('path.rect(x, y, w, h) appends M, h, v, h, and Z commands', () {
    final p = path()
      ..moveTo(150, 100)
      ..rect(100, 200, 50, 25);
    assertPathEqual(p, 'M150,100M100,200h50v25h-50Z');
  });
}
