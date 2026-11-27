// Ported from d3-quadtree v3.0.1 test/extent-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

void main() {
  test('quadtree.extent(extent) extends the extent', () {
    expect(quadtree().setExtent(((0, 1), (2, 6))).extent, (
      (0.0, 1.0),
      (8.0, 9.0),
    ));
  });

  test('quadtree.extent() can be inferred by quadtree.cover', () {
    final q = quadtree();
    expect(q.cover(0, 0).extent, ((0.0, 0.0), (1.0, 1.0)));
    expect(q.cover(2, 4).extent, ((0.0, 0.0), (8.0, 8.0)));
  });

  test('quadtree.extent() can be inferred by quadtree.add', () {
    final q = quadtree()..add((0, 0));
    expect(q.extent, ((0.0, 0.0), (1.0, 1.0)));
    q.add((2, 4));
    expect(q.extent, ((0.0, 0.0), (8.0, 8.0)));
  });

  test(
    'quadtree.extent(extent) squarifies and centers the specified extent',
    () {
      expect(quadtree().setExtent(((0, 1), (2, 6))).extent, (
        (0.0, 1.0),
        (8.0, 9.0),
      ));
    },
  );

  test('quadtree.extent(extent) ignores invalid extents', () {
    expect(
      quadtree().setExtent(((1, double.nan), (double.nan, 0))).extent,
      isNull,
    );
    expect(
      quadtree().setExtent(((double.nan, 1), (0, double.nan))).extent,
      isNull,
    );
    expect(
      quadtree().setExtent((
        (double.nan, double.nan),
        (double.nan, double.nan),
      )).extent,
      isNull,
    );
  });

  test('quadtree.extent(extent) flips inverted extents', () {
    expect(quadtree().setExtent(((1, 1), (0, 0))).extent, (
      (0.0, 0.0),
      (2.0, 2.0),
    ));
  });

  test('quadtree.extent(extent) tolerates partially-valid extents', () {
    expect(quadtree().setExtent(((double.nan, 0), (1, 1))).extent, (
      (1.0, 1.0),
      (2.0, 2.0),
    ));
    expect(quadtree().setExtent(((0, double.nan), (1, 1))).extent, (
      (1.0, 1.0),
      (2.0, 2.0),
    ));
    expect(quadtree().setExtent(((0, 0), (double.nan, 1))).extent, (
      (0.0, 0.0),
      (1.0, 1.0),
    ));
    expect(quadtree().setExtent(((0, 0), (1, double.nan))).extent, (
      (0.0, 0.0),
      (1.0, 1.0),
    ));
  });

  test('quadtree.extent(extent) allows trivial extents', () {
    expect(quadtree().setExtent(((0, 0), (0, 0))).extent, (
      (0.0, 0.0),
      (1.0, 1.0),
    ));
    expect(quadtree().setExtent(((1, 1), (1, 1))).extent, (
      (1.0, 1.0),
      (2.0, 2.0),
    ));
  });
}
