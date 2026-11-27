// Ported from d3-quadtree v3.0.1 test/addAll-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

import 'port/node_matchers.dart';

void main() {
  test(
    'quadtree.addAll(data) creates new points and adds them to the quadtree',
    () {
      final q = quadtree();
      expectNodeEquals(q.add((0.0, 0.0)).root, leaf((0, 0)));
      expectNodeEquals(
        q.add((0.9, 0.9)).root,
        branch(nw: leaf((0, 0)), se: leaf((0.9, 0.9))),
      );
      expectNodeEquals(
        q.add((0.9, 0.0)).root,
        branch(nw: leaf((0, 0)), ne: leaf((0.9, 0)), se: leaf((0.9, 0.9))),
      );
      expectNodeEquals(
        q.add((0.0, 0.9)).root,
        branch(
          nw: leaf((0, 0)),
          ne: leaf((0.9, 0)),
          sw: leaf((0, 0.9)),
          se: leaf((0.9, 0.9)),
        ),
      );
      expectNodeEquals(
        q.add((0.4, 0.4)).root,
        branch(
          nw: branch(nw: leaf((0, 0)), se: leaf((0.4, 0.4))),
          ne: leaf((0.9, 0)),
          sw: leaf((0, 0.9)),
          se: leaf((0.9, 0.9)),
        ),
      );
    },
  );

  test('quadtree.addAll(data) ignores points with NaN coordinates', () {
    final q = quadtree();
    expect(q.addAll(const [(double.nan, 0), (0, double.nan)]).root, isNull);
    expect(q.extent, isNull);
    expectNodeEquals(
      q.addAll(const [(0, 0), (0.9, 0.9)]).root,
      branch(nw: leaf((0, 0)), se: leaf((0.9, 0.9))),
    );
    expectNodeEquals(
      q.addAll(const [(double.nan, 0), (0, double.nan)]).root,
      branch(nw: leaf((0, 0)), se: leaf((0.9, 0.9))),
    );
    expect(q.extent, ((0.0, 0.0), (1.0, 1.0)));
  });

  test('quadtree.addAll(data) correctly handles the empty array', () {
    final q = quadtree();
    expect(q.addAll(const []).root, isNull);
    expect(q.extent, isNull);
    expectNodeEquals(
      q.addAll(const [(0, 0), (1, 1)]).root,
      branch(nw: leaf((0, 0)), se: leaf((1, 1))),
    );
    expectNodeEquals(
      q.addAll(const []).root,
      branch(nw: leaf((0, 0)), se: leaf((1, 1))),
    );
    expect(q.extent, ((0.0, 0.0), (2.0, 2.0)));
  });

  test(
    'quadtree.addAll(data) computes the extent of the data before adding',
    () {
      final q = quadtree().addAll(const [(0.4, 0.4), (0, 0), (0.9, 0.9)]);
      expectNodeEquals(
        q.root,
        branch(
          nw: branch(nw: leaf((0, 0)), se: leaf((0.4, 0.4))),
          se: leaf((0.9, 0.9)),
        ),
      );
    },
  );
}
