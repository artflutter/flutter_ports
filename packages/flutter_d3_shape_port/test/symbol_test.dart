// Ported from d3-shape v3.2.0 test/symbol-test.js (ISC, Mike Bostock).
// Expected SVG path literals stay on single lines for readability.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:math' as math;

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import 'asserts.dart';
import 'polygonContext.dart';

void main() {
  test('symbol() returns a default symbol shape', () {
    final s = symbol<void>();
    expect(s.type(null), symbolCircle);
    expect(s.size(null), 64);
    expect(s.context, isNull);
    assertPathEqual(
      s(),
      'M4.513517,0A4.513517,4.513517,0,1,1,-4.513517,0A4.513517,4.513517,0,1,1,4.513517,0',
    );
  });

  test(
    'symbol().size(f)(…) propagates the context and arguments to the '
    'specified function',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test(
    'symbol().type(f)(…) propagates the context and arguments to the '
    'specified function',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test('symbol.size(size) observes the specified size function', () {
    double size(({double z, int i}) d) => d.z * 2 + d.i;
    final s = symbol<({double z, int i})>()..size = size;
    expect(s.size, size);
    assertPathEqual(s((z: 0, i: 0)), 'M0,0');
    assertPathEqual(
      s((z: math.pi / 2, i: 0)),
      'M1,0A1,1,0,1,1,-1,0A1,1,0,1,1,1,0',
    );
    assertPathEqual(
      s((z: 2 * math.pi, i: 0)),
      'M2,0A2,2,0,1,1,-2,0A2,2,0,1,1,2,0',
    );
    assertPathEqual(
      s((z: math.pi, i: 1)),
      'M1.522600,0A1.522600,1.522600,0,1,1,-1.522600,0A1.522600,1.522600,0,1,1,1.522600,0',
    );
    assertPathEqual(
      s((z: 4 * math.pi, i: 2)),
      'M2.938813,0A2.938813,2.938813,0,1,1,-2.938813,0A2.938813,2.938813,0,1,1,2.938813,0',
    );
  });

  test('symbol.size(size) observes the specified size constant', () {
    final s = symbol<void>()..sizeConst(42);
    expect(s.size(null), 42);
    assertPathEqual((s..sizeConst(0))(), 'M0,0');
    assertPathEqual(
      (s..sizeConst(math.pi))(),
      'M1,0A1,1,0,1,1,-1,0A1,1,0,1,1,1,0',
    );
    assertPathEqual(
      (s..sizeConst(4 * math.pi))(),
      'M2,0A2,2,0,1,1,-2,0A2,2,0,1,1,2,0',
    );
  });

  test('symbol.type(symbolAsterisk) generates the expected path', () {
    final s = symbol<double>(symbolAsterisk)..size = (d) => d;
    assertPathEqual(s(0), 'M0,0L0,0M0,0L0,0M0,0L0,0');
    assertPathEqual(
      s(20),
      'M0,2.705108L0,-2.705108M-2.342692,-1.352554L2.342692,1.352554M-2.342692,1.352554L2.342692,-1.352554',
    );
  });

  test('symbol.type(symbolCircle) generates the expected path', () {
    final s = symbol<double>(symbolCircle)..size = (d) => d;
    assertPathEqual(s(0), 'M0,0');
    assertPathEqual(
      s(20),
      'M2.523133,0A2.523133,2.523133,0,1,1,-2.523133,0A2.523133,2.523133,0,1,1,2.523133,0',
    );
  });

  test(
    'symbol.type(symbolCross) generates a polygon with the specified size',
    () {
      final p = polygonContext();
      final s = symbol<void>(symbolCross)..context = p;
      (s..sizeConst(1))();
      assertInDelta(p.area(), 1);
      (s..sizeConst(240))();
      assertInDelta(p.area(), 240);
    },
  );

  test('symbol.type(symbolCross) generates the expected path', () {
    final s = symbol<double>(symbolCross)..size = (d) => d;
    assertPathEqual(s(0), 'M0,0L0,0L0,0L0,0L0,0L0,0L0,0L0,0L0,0L0,0L0,0L0,0Z');
    assertPathEqual(
      s(20),
      'M-3,-1L-1,-1L-1,-3L1,-3L1,-1L3,-1L3,1L1,1L1,3L-1,3L-1,1L-3,1Z',
    );
  });

  test(
    'symbol.type(symbolDiamond) generates a polygon with the specified size',
    () {
      final p = polygonContext();
      final s = symbol<void>(symbolDiamond)..context = p;
      (s..sizeConst(1))();
      assertInDelta(p.area(), 1);
      (s..sizeConst(240))();
      assertInDelta(p.area(), 240);
    },
  );

  test('symbol.type(symbolDiamond) generates the expected path', () {
    final s = symbol<double>(symbolDiamond)..size = (d) => d;
    assertPathEqual(s(0), 'M0,0L0,0L0,0L0,0Z');
    assertPathEqual(s(10), 'M0,-2.942831L1.699044,0L0,2.942831L-1.699044,0Z');
  });

  test('symbol.type(symbolDiamond2) generates the expected path', () {
    final s = symbol<double>(symbolDiamond2)..size = (d) => d;
    assertPathEqual(s(0), 'M0,0L0,0L0,0L0,0Z');
    assertPathEqual(s(20), 'M0,-2.800675L2.800675,0L0,2.800675L-2.800675,0Z');
  });

  test('symbol.type(symbolPlus) generates the expected path', () {
    final s = symbol<double>(symbolPlus)..size = (d) => d;
    assertPathEqual(s(0), 'M0,0L0,0M0,0L0,0');
    assertPathEqual(s(20), 'M-3.714814,0L3.714814,0M0,3.714814L0,-3.714814');
  });

  test(
    'symbol.type(symbolStar) generates a polygon with the specified size',
    () {
      final p = polygonContext();
      final s = symbol<void>(symbolStar)..context = p;
      (s..sizeConst(1))();
      assertInDelta(p.area(), 1);
      (s..sizeConst(240))();
      assertInDelta(p.area(), 240);
    },
  );

  test('symbol.type(symbolStar) generates the expected path', () {
    final s = symbol<double>(symbolStar)..size = (d) => d;
    assertPathEqual(s(0), 'M0,0L0,0L0,0L0,0L0,0L0,0L0,0L0,0L0,0L0,0Z');
    assertPathEqual(
      s(10),
      'M0,-2.984649L0.670095,-0.922307L2.838570,-0.922307L1.084237,0.352290L1.754333,2.414632L0,1.140035L-1.754333,2.414632L-1.084237,0.352290L-2.838570,-0.922307L-0.670095,-0.922307Z',
    );
  });

  test(
    'symbol.type(symbolSquare) generates a polygon with the specified size',
    () {
      final p = polygonContext();
      final s = symbol<void>(symbolSquare)..context = p;
      (s..sizeConst(1))();
      assertInDelta(p.area(), 1);
      (s..sizeConst(240))();
      assertInDelta(p.area(), 240);
    },
  );

  test('symbol.type(symbolSquare) generates the expected path', () {
    final s = symbol<double>(symbolSquare)..size = (d) => d;
    assertPathEqual(s(0), 'M0,0h0v0h0Z');
    assertPathEqual(s(4), 'M-1,-1h2v2h-2Z');
    assertPathEqual(s(16), 'M-2,-2h4v4h-4Z');
  });

  test('symbol.type(symbolSquare2) generates the expected path', () {
    final s = symbol<double>(symbolSquare2)..size = (d) => d;
    assertPathEqual(s(0), 'M0,0L0,0L0,0L0,0Z');
    assertPathEqual(
      s(20),
      'M1.981603,1.981603L1.981603,-1.981603L-1.981603,-1.981603L-1.981603,1.981603Z',
    );
  });

  test(
    'symbol.type(symbolTriangle) generates a polygon with the specified size',
    () {
      final p = polygonContext();
      final s = symbol<void>(symbolTriangle)..context = p;
      (s..sizeConst(1))();
      assertInDelta(p.area(), 1);
      (s..sizeConst(240))();
      assertInDelta(p.area(), 240);
    },
  );

  test('symbol.type(symbolTriangle) generates the expected path', () {
    final s = symbol<double>(symbolTriangle)..size = (d) => d;
    assertPathEqual(s(0), 'M0,0L0,0L0,0Z');
    assertPathEqual(
      s(10),
      'M0,-2.774528L2.402811,1.387264L-2.402811,1.387264Z',
    );
  });

  test('symbol.type(symbolTriangle2) generates the expected path', () {
    final s = symbol<double>(symbolTriangle2)..size = (d) => d;
    assertPathEqual(s(0), 'M0,0L0,0L0,0Z');
    assertPathEqual(
      s(20),
      'M0,-3.051786L2.642924,1.525893L-2.642924,1.525893Z',
    );
  });

  test(
    'symbol.type(symbolWye) generates a polygon with the specified size',
    () {
      final p = polygonContext();
      final s = symbol<void>(symbolWye)..context = p;
      (s..sizeConst(1))();
      assertInDelta(p.area(), 1);
      (s..sizeConst(240))();
      assertInDelta(p.area(), 240);
    },
  );

  test('symbol.type(symbolWye) generates the expected path', () {
    final s = symbol<double>(symbolWye)..size = (d) => d;
    assertPathEqual(s(0), 'M0,0L0,0L0,0L0,0L0,0L0,0L0,0L0,0L0,0Z');
    assertPathEqual(
      s(10),
      'M0.853360,0.492688L0.853360,2.199408L-0.853360,2.199408L-0.853360,0.492688L-2.331423,-0.360672L-1.478063,-1.838735L0,-0.985375L1.478063,-1.838735L2.331423,-0.360672Z',
    );
  });

  test('symbol.type(symbolTimes) generates the expected path', () {
    final s = symbol<double>(symbolTimes)..size = (d) => d;
    assertPathEqual(s(0), 'M0,0L0,0M0,0L0,0');
    assertPathEqual(
      s(20),
      'M-2.647561,-2.647561L2.647561,2.647561M-2.647561,2.647561L2.647561,-2.647561',
    );
  });

  test(
    'symbol(type, size) is equivalent to symbol().type(type).size(size)',
    () {
      final s0 = symbol<void>()
        ..typeConst(symbolCross)
        ..sizeConst(16);
      final s1 = symbol<void>(symbolCross, 16);
      expect(s0(), s1());
    },
  );
}
