// Ported from d3-quadtree v3.0.1 test/visit-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

void main() {
  test('quadtree.visit(callback) visits each node in a quadtree', () {
    final results = <(double, double, double, double)>[];
    final q = quadtree().addAll(const [(0, 0), (1, 0), (0, 1), (1, 1)]);
    expect(
      q.visit((_, x0, y0, x1, y1) {
        results.add((x0, y0, x1, y1));
        return false;
      }),
      same(q),
    );
    expect(results, const [
      (0.0, 0.0, 2.0, 2.0),
      (0.0, 0.0, 1.0, 1.0),
      (1.0, 0.0, 2.0, 1.0),
      (0.0, 1.0, 1.0, 2.0),
      (1.0, 1.0, 2.0, 2.0),
    ]);
  });

  test('quadtree.visit(callback) applies pre-order traversal', () {
    final results = <(double, double, double, double)>[];
    final q = quadtree().setExtent(((0, 0), (960, 960))).addAll(const [
      (100, 100),
      (200, 200),
      (300, 300),
    ]);
    expect(
      q.visit((_, x0, y0, x1, y1) {
        results.add((x0, y0, x1, y1));
        return false;
      }),
      same(q),
    );
    expect(results, const [
      (0.0, 0.0, 1024.0, 1024.0),
      (0.0, 0.0, 512.0, 512.0),
      (0.0, 0.0, 256.0, 256.0),
      (0.0, 0.0, 128.0, 128.0),
      (128.0, 128.0, 256.0, 256.0),
      (256.0, 256.0, 512.0, 512.0),
    ]);
  });

  test(
    'quadtree.visit(callback) does not recurse if the callback returns truthy',
    () {
      final results = <(double, double, double, double)>[];
      final q = quadtree().setExtent(((0, 0), (960, 960))).addAll(const [
        (100, 100),
        (700, 700),
        (800, 800),
      ]);
      expect(
        q.visit((_, x0, y0, x1, y1) {
          results.add((x0, y0, x1, y1));
          return x0 > 0;
        }),
        same(q),
      );
      expect(results, const [
        (0.0, 0.0, 1024.0, 1024.0),
        (0.0, 0.0, 512.0, 512.0),
        (512.0, 512.0, 1024.0, 1024.0),
      ]);
    },
  );

  test(
    'quadtree.visit(callback) on an empty quadtree with no bounds does nothing',
    () {
      final results = <(double, double, double, double)>[];
      final q = quadtree();
      expect(
        q.visit((_, x0, y0, x1, y1) {
          results.add((x0, y0, x1, y1));
          return false;
        }),
        same(q),
      );
      expect(results, isEmpty);
    },
  );

  test(
    'quadtree.visit(callback) on an empty quadtree with bounds does nothing',
    () {
      final results = <(double, double, double, double)>[];
      final q = quadtree().setExtent(((0, 0), (960, 960)));
      expect(
        q.visit((_, x0, y0, x1, y1) {
          results.add((x0, y0, x1, y1));
          return false;
        }),
        same(q),
      );
      expect(results, isEmpty);
    },
  );
}
