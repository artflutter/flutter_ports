// Ported from robust-predicates v3.0.3 test/test.js (Unlicense, Vladimir Agafonkin).
@TestOn('vm')
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_d3_delaunay_port/d3_delaunay.dart';
import 'package:test/test.dart';

Directory? _repositoryRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File('${dir.path}/.gitmodules').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

void main() {
  final root = _repositoryRoot();
  final orient2dFixture = root == null
      ? null
      : File(
          '${root.path}/third_party/robust-predicates/test/fixtures/orient2d.txt',
        );

  test('orient2d', () {
    expect(orient2d(0, 0, 1, 1, 0, 1), lessThan(0), reason: 'clockwise');
    expect(
      orient2d(0, 0, 0, 1, 1, 1),
      greaterThan(0),
      reason: 'counterclockwise',
    );
    expect(orient2d(0, 0, 0.5, 0.5, 1, 1), 0, reason: 'collinear');

    // 128x128 near-collinear grid along the diagonal y = x through (18, 18)
    // and (16.8, 16.8): exact sign is sign(y - x) since q > p.
    const r = 0.95;
    const q = 18.0;
    const p = 16.8;
    final w = math.pow(2, -43).toDouble();

    for (var i = 0; i < 128; i++) {
      for (var j = 0; j < 128; j++) {
        final x = r + w * i / 128;
        final y = r + w * j / 128;

        final o = orient2d(x, y, q, q, p, p);
        // Exact analytical determinant:
        // (y - p)*(q - p) - (x - p)*(q - p) = (y - x)*(q - p), with q - p > 0.
        final expectedSign = y == x ? 0.0 : (y > x ? 1.0 : -1.0);
        expect(o.sign, expectedSign, reason: '$x,$y, $q,$q, $p,$p: $o');
      }
    }

    if (orient2dFixture != null && orient2dFixture.existsSync()) {
      final lines = orient2dFixture.readAsStringSync().trim().split(
        RegExp(r'\r?\n'),
      );
      expect(lines, hasLength(1000));
      for (final line in lines) {
        final parts = line.split(' ').map(double.parse).toList();
        final result = orient2d(
          parts[1],
          parts[2],
          parts[3],
          parts[4],
          parts[5],
          parts[6],
        );
        final expected = -parts[7];
        expect(
          result.sign == expected || (result == 0 && expected == 0),
          isTrue,
          reason: '$line: $result vs $expected',
        );
      }
    }
  });

  test('orient2dfast', () {
    expect(orient2dfast(0, 0, 1, 1, 0, 1), lessThan(0));
    expect(orient2dfast(0, 0, 0, 1, 1, 1), greaterThan(0));
    expect(orient2dfast(0, 0, 0.5, 0.5, 1, 1), 0);
  });

  // DIVERGES(d3-delaunay): not-followed-robust-predicates-3d, only orient2d.
  test(
    'incircle',
    () {},
    skip: 'n/a: D3 ADR 0001 item 17 (only orient2d is ported)',
  );
  test(
    'incirclefast',
    () {},
    skip: 'n/a: D3 ADR 0001 item 17 (only orient2d is ported)',
  );
  test(
    'orient3d',
    () {},
    skip: 'n/a: D3 ADR 0001 item 17 (only orient2d is ported)',
  );
  test(
    'orient3dfast',
    () {},
    skip: 'n/a: D3 ADR 0001 item 17 (only orient2d is ported)',
  );
  test(
    'insphere',
    () {},
    skip: 'n/a: D3 ADR 0001 item 17 (only orient2d is ported)',
  );
  test(
    'inspherefast',
    () {},
    skip: 'n/a: D3 ADR 0001 item 17 (only orient2d is ported)',
  );
}
