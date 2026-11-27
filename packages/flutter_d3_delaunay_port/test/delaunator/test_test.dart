// Ported from delaunator v5.1.0 test/test.js (ISC, Mapbox).
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

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

List<(double, double)>? _loadFixture(Directory? root, String name) {
  if (root == null) return null;
  final file = File('${root.path}/third_party/delaunator/test/fixtures/$name');
  if (!file.existsSync()) return null;
  final raw = jsonDecode(file.readAsStringSync()) as List<Object?>;
  return [
    for (final item in raw)
      if (item! as List<Object?> case final pair)
        ((pair[0]! as num).toDouble(), (pair[1]! as num).toDouble()),
  ];
}

double _orient((double, double) p, (double, double) r, (double, double) q) {
  final l = (r.$2 - p.$2) * (q.$1 - p.$1);
  final ri = (r.$1 - p.$1) * (q.$2 - p.$2);
  return (l - ri).abs() >= 3.3306690738754716e-16 * (l + ri).abs() ? l - ri : 0;
}

bool _convex((double, double) r, (double, double) q, (double, double) p) {
  final o1 = _orient(p, r, q);
  if (o1 != 0) return o1 >= 0;
  final o2 = _orient(r, q, p);
  if (o2 != 0) return o2 >= 0;
  return _orient(q, p, r) >= 0;
}

// Kahan–Babuška–Neumaier summation.
double _kahanSum(List<double> x) {
  var sum = x[0];
  var err = 0.0;
  for (var i = 1; i < x.length; i++) {
    final k = x[i];
    final m = sum + k;
    err += sum.abs() >= k.abs() ? sum - m + k : k - m + sum;
    sum = m;
  }
  return sum + err;
}

void _validate(List<(double, double)> points, [Delaunator? existing]) {
  final d = existing ?? Delaunator.fromCoords(points);

  // validate halfedges
  for (var i = 0; i < d.halfedges.length; i++) {
    expect(
      d.halfedges[i] == -1 || d.halfedges[d.halfedges[i]] == i,
      isTrue,
      reason: 'valid halfedge connection at $i',
    );
  }

  // validate hull convexity and area
  final hullAreas = <double>[];
  final len = d.hull.length;
  for (var i = 0, j = len - 1; i < len; j = i++) {
    final (x0, y0) = points[d.hull[j]];
    final (x, y) = points[d.hull[i]];
    hullAreas.add((x - x0) * (y + y0));
    expect(
      _convex(
        points[d.hull[j]],
        points[d.hull[(j + 1) % len]],
        points[d.hull[(j + 3) % len]],
      ),
      isTrue,
      reason: 'hull should be convex at $j',
    );
  }
  final hullArea = _kahanSum(hullAreas);

  final triangleAreas = <double>[];
  for (var i = 0; i < d.triangles.length; i += 3) {
    final (ax, ay) = points[d.triangles[i]];
    final (bx, by) = points[d.triangles[i + 1]];
    final (cx, cy) = points[d.triangles[i + 2]];
    triangleAreas.add(((by - ay) * (cx - bx) - (bx - ax) * (cy - by)).abs());
  }
  final trianglesArea = _kahanSum(triangleAreas);

  final err = ((hullArea - trianglesArea) / hullArea).abs();
  expect(
    err,
    lessThanOrEqualTo(math.pow(2, -51)),
    reason: 'triangulation should be valid; $err error',
  );
}

typedef _CustomPoint = ({double x, double y});

void main() {
  final root = _repositoryRoot();
  final ukraine = _loadFixture(root, 'ukraine.json');
  final issue13 = _loadFixture(root, 'issue13.json');
  final issue43 = _loadFixture(root, 'issue43.json');
  final issue44 = _loadFixture(root, 'issue44.json');
  final robustness1 = _loadFixture(root, 'robustness1.json');
  final robustness2 = _loadFixture(root, 'robustness2.json');
  final robustness3 = _loadFixture(root, 'robustness3.json');
  final robustness4 = _loadFixture(root, 'robustness4.json');
  final skipFixtures = ukraine == null
      ? 'third_party/delaunator submodule is not checked out'
      : false;

  test('triangulates flat list', () {
    final flat = Float64List.fromList([
      for (final (x, y) in ukraine!) ...[x, y],
    ]);
    final d = Delaunator(flat);
    expect(d.triangles, Delaunator.fromCoords(ukraine).triangles);
  }, skip: skipFixtures);

  test('triangulates typed array', () {
    final flat = Float64List(ukraine!.length * 2);
    for (var i = 0; i < ukraine.length; i++) {
      flat[2 * i] = ukraine[i].$1;
      flat[2 * i + 1] = ukraine[i].$2;
    }
    final d = Delaunator(flat);
    expect(d.triangles, Delaunator.fromCoords(ukraine).triangles);
  }, skip: skipFixtures);

  test('constructor is statically typed for Float64List', () {
    // DIVERGES(d3-delaunay): adapt-delaunay-typed-api, Float64List param.
    expect(() => Delaunator(Float64List(0)), returnsNormally);
  });

  test('produces correct triangulation', () {
    _validate(ukraine!);
  }, skip: skipFixtures);

  test('produces correct triangulation after modifying coords in place', () {
    final pts = ukraine!;
    final d = Delaunator.fromCoords(pts);

    _validate(pts, d);
    expect(d.trianglesLen, 5133);

    const p = (80.0, 220.0);
    d.coords[0] = p.$1;
    d.coords[1] = p.$2;
    final newPoints = <(double, double)>[p, ...pts.sublist(1)];

    d.update();
    _validate(newPoints, d);
    expect(d.trianglesLen, 5139);
  }, skip: skipFixtures);

  test('issue #11', () {
    _validate(const <(double, double)>[
      (516, 661),
      (369, 793),
      (426, 539),
      (273, 525),
      (204, 694),
      (747, 750),
      (454, 390),
    ]);
  });

  test('issue #13', () {
    _validate(issue13!);
  }, skip: skipFixtures);

  test('issue #24', () {
    _validate(const <(double, double)>[
      (382, 302),
      (382, 328),
      (382, 205),
      (623, 175),
      (382, 188),
      (382, 284),
      (623, 87),
      (623, 341),
      (141, 227),
    ]);
  });

  test('issue #43', () {
    _validate(issue43!);
  }, skip: skipFixtures);

  test('issue #44', () {
    _validate(issue44!);
  }, skip: skipFixtures);

  test('robustness', () {
    final r1 = robustness1!;
    _validate(r1);
    _validate([for (final (x, y) in r1) (x / 1e9, y / 1e9)]);
    _validate([for (final (x, y) in r1) (x / 100, y / 100)]);
    _validate([for (final (x, y) in r1) (x * 100, y * 100)]);
    _validate([for (final (x, y) in r1) (x * 1e9, y * 1e9)]);
    _validate(robustness2!.sublist(0, 100));
    _validate(robustness2);
    _validate(robustness3!);
    _validate(robustness4!);
  }, skip: skipFixtures);

  test('returns empty triangulation for small number of points', () {
    var d = Delaunator.fromCoords(const []);
    expect(d.triangles, isEmpty);
    expect(d.hull, isEmpty);
    d = Delaunator.fromCoords(const [(31.0, 50.0)]);
    expect(d.triangles, isEmpty);
    expect(d.hull, [0]);
    d = Delaunator.fromCoords(const [(31.0, 50.0), (30.5, 50.2)]);
    expect(d.triangles, isEmpty);
    expect(d.hull, anyOf(equals([1, 0]), equals([0, 1])));
  });

  test('returns empty triangulation for all-collinear input', () {
    final d = Delaunator.fromCoords(const <(double, double)>[
      (0, 0),
      (1, 0),
      (3, 0),
      (2, 0),
    ]);
    expect(d.triangles, isEmpty);
    expect(d.hull, [0, 1, 3, 2]);
  });

  test('supports custom point format', () {
    final d = Delaunator.from<_CustomPoint>(
      const <_CustomPoint>[(x: 5, y: 5), (x: 7, y: 5), (x: 7, y: 6)],
      getX: (p) => p.x,
      getY: (p) => p.y,
    );
    expect(d.triangles, [0, 2, 1]);
  });
}
