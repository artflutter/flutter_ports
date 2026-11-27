// Ported from d3-delaunay v6.0.4 test/delaunay-test.js (ISC, Observable, Inc.).

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_delaunay_port/d3_delaunay.dart';
import 'package:test/test.dart';

import 'context.dart';

typedef _PointObj = ({double x, double y});

void main() {
  test('Delaunay.from(array)', () {
    final delaunay = Delaunay.fromCoords(const <(double, double)>[
      (0, 0),
      (1, 0),
      (0, 1),
      (1, 1),
    ]);
    expect(delaunay.points, Float64List.fromList([0, 0, 1, 0, 0, 1, 1, 1]));
    expect(delaunay.triangles, Int32List.fromList([0, 2, 1, 2, 3, 1]));
    expect(delaunay.halfedges, Int32List.fromList([-1, 5, -1, -1, -1, 1]));
    expect(delaunay.inedges, Int32List.fromList([2, 4, 0, 3]));
    expect(delaunay.neighbors(0).toList(), [1, 2]);
    expect(delaunay.neighbors(1).toList(), [3, 2, 0]);
    expect(delaunay.neighbors(2).toList(), [0, 1, 3]);
    expect(delaunay.neighbors(3).toList(), [2, 1]);
  });

  test('Delaunay.from(array) handles coincident points', () {
    final delaunay = Delaunay.fromCoords(const <(double, double)>[
      (0, 0),
      (1, 0),
      (0, 1),
      (1, 0),
    ]);
    expect(delaunay.inedges, Int32List.fromList([2, 1, 0, -1]));
    expect(delaunay.neighbors(0).toList(), [1, 2]);
    expect(delaunay.neighbors(1).toList(), [2, 0]);
    expect(delaunay.neighbors(2).toList(), [0, 1]);
    expect(delaunay.neighbors(3).toList(), <int>[]);
  });

  test('Delaunay.from(iterable)', () {
    Iterable<(double, double)> gen() sync* {
      yield (0, 0);
      yield (1, 0);
      yield (0, 1);
      yield (1, 1);
    }

    final delaunay = Delaunay.from<(double, double)>(gen());
    expect(delaunay.points, Float64List.fromList([0, 0, 1, 0, 0, 1, 1, 1]));
    expect(delaunay.triangles, Int32List.fromList([0, 2, 1, 2, 3, 1]));
    expect(delaunay.halfedges, Int32List.fromList([-1, 5, -1, -1, -1, 1]));
  });

  test('Delaunay.from(iterable, fx, fy)', () {
    Iterable<_PointObj> gen() sync* {
      yield (x: 0, y: 0);
      yield (x: 1, y: 0);
      yield (x: 0, y: 1);
      yield (x: 1, y: 1);
    }

    final delaunay = Delaunay.from<_PointObj>(
      gen(),
      x: (d) => d.x,
      y: (d) => d.y,
    );
    expect(delaunay.points, Float64List.fromList([0, 0, 1, 0, 0, 1, 1, 1]));
    expect(delaunay.triangles, Int32List.fromList([0, 2, 1, 2, 3, 1]));
    expect(delaunay.halfedges, Int32List.fromList([-1, 5, -1, -1, -1, 1]));
  });

  test('Delaunay.from({length}, fx, fy)', () {
    final delaunay = Delaunay.fromLength(
      4,
      (i) => (i & 1).toDouble(),
      (i) => ((i >> 1) & 1).toDouble(),
    );
    expect(delaunay.points, Float64List.fromList([0, 0, 1, 0, 0, 1, 1, 1]));
    expect(delaunay.triangles, Int32List.fromList([0, 2, 1, 2, 3, 1]));
    expect(delaunay.halfedges, Int32List.fromList([-1, 5, -1, -1, -1, 1]));
  });

  test('delaunay.voronoi() uses the default bounds', () {
    final voronoi = Delaunay.fromCoords(const <(double, double)>[
      (0, 0),
      (1, 0),
      (0, 1),
      (1, 1),
    ]).voronoi();
    expect(voronoi.xmin, 0);
    expect(voronoi.ymin, 0);
    expect(voronoi.xmax, 960);
    expect(voronoi.ymax, 500);
  });

  test('delaunay.voronoi([xmin, ymin, xmax, ymax]) uses specified bounds', () {
    final voronoi = Delaunay.fromCoords(const <(double, double)>[
      (0, 0),
      (1, 0),
      (0, 1),
      (1, 1),
    ]).voronoi((-1, -1, 2, 2));
    expect(voronoi.xmin, -1);
    expect(voronoi.ymin, -1);
    expect(voronoi.xmax, 2);
    expect(voronoi.ymax, 2);
  });

  test('delaunay.voronoi() returns the expected diagram', () {
    final voronoi = Delaunay.fromCoords(const <(double, double)>[
      (0, 0),
      (1, 0),
      (0, 1),
      (1, 1),
    ]).voronoi();
    expect(voronoi.circumcenters, Float64List.fromList([0.5, 0.5, 0.5, 0.5]));
    expect(
      voronoi.vectors,
      Float64List.fromList([
        0,
        -1,
        -1,
        0,
        1,
        0,
        0,
        -1,
        -1,
        0,
        0,
        1,
        0,
        1,
        1,
        0,
      ]),
    );
  });

  test('delaunay.voronoi() skips cells for coincident points', () {
    final voronoi = Delaunay.fromCoords(const <(double, double)>[
      (0, 0),
      (1, 0),
      (0, 1),
      (1, 0),
    ]).voronoi((-1, -1, 2, 2));
    expect(voronoi.circumcenters, Float64List.fromList([0.5, 0.5]));
    expect(
      voronoi.vectors,
      Float64List.fromList([
        0,
        -1,
        -1,
        0,
        1,
        1,
        0,
        -1,
        -1,
        0,
        1,
        1,
        0,
        0,
        0,
        0,
      ]),
    );
  });

  test('delaunay.voronoi() for zero point returns expected values', () {
    final voronoi = Delaunay.fromCoords(const []).voronoi((-1, -1, 2, 2));
    expect(voronoi.renderToSvg(), isNull);
  });

  test('delaunay.renderPoints() accepts r', () {
    final delaunay = Delaunay.fromCoords(const <(double, double)>[(0, 0)]);
    expect(delaunay.renderPointsToSvg(), 'M2,0A2,2,0,1,1,-2,0A2,2,0,1,1,2,0');
    expect(delaunay.renderPointsToSvg(5), 'M5,0A5,5,0,1,1,-5,0A5,5,0,1,1,5,0');
    final path = DelaunayPath();
    delaunay.renderPoints(path, 3);
    expect(path.value(), 'M3,0A3,3,0,1,1,-3,0A3,3,0,1,1,3,0');
  });

  test('delaunay.voronoi() for one point returns the bounding rectangle', () {
    final voronoi = Delaunay.fromCoords(const <(double, double)>[(0, 0)])
        .voronoi((-1, -1, 2, 2));
    expect(voronoi.renderCellToSvg(0), 'M2,-1L2,2L-1,2L-1,-1Z');
    expect(voronoi.renderToSvg(), isNull);
  });

  test('delaunay.voronoi() for two points', () {
    final voronoi = Delaunay.fromCoords(const <(double, double)>[
      (0, 0),
      (1, 0),
      (1, 0),
      (1, 0),
    ]).voronoi((-1, -1, 2, 2));
    expect(voronoi.renderCellToSvg(0), 'M-1,2L-1,-1L0.5,-1L0.5,2Z');
    expect(voronoi.delaunay.find(-1, 0), 0);
    expect(voronoi.delaunay.find(2, 0), 1);
  });

  test('delaunay.voronoi() for collinear points', () {
    final voronoi = Delaunay.fromCoords(const <(double, double)>[
      (0, 0),
      (1, 0),
      (-1, 0),
    ]).voronoi((-1, -1, 2, 2));
    expect(voronoi.delaunay.neighbors(0).toList()..sort(), [1, 2]);
    expect(voronoi.delaunay.neighbors(1).toList(), [0]);
    expect(voronoi.delaunay.neighbors(2).toList(), [0]);
  });

  test(
    'delaunay.find(x, y) returns the index of the cell containing the point',
    () {
      final delaunay = Delaunay.fromCoords(const <(double, double)>[
        (0, 0),
        (300, 0),
        (0, 300),
        (300, 300),
        (100, 100),
      ]);
      expect(delaunay.find(49, 49), 0);
      expect(delaunay.find(51, 51), 4);
    },
  );

  test('delaunay.find(x, y) works with one or two points', () {
    const points = <(double, double)>[(0, 1), (0, 2)];
    final delaunay = Delaunay.fromCoords(points);
    expect(points[delaunay.find(0, -1)].$2, 1);
    expect(points[delaunay.find(0, 2.2)].$2, 2);
    delaunay.points.fillRange(0, delaunay.points.length, 0);
    delaunay.update();
    expect(delaunay.find(0, -1), 0);
    expect(delaunay.find(0, 1.2), 0);
  });

  test('delaunay.find(x, y) works with collinear points', () {
    const points = <(double, double)>[
      (0, 1),
      (0, 2),
      (0, 4),
      (0, 0),
      (0, 3),
      (0, 4),
      (0, 4),
    ];
    final delaunay = Delaunay.fromCoords(points);
    expect(points[delaunay.find(0, -1)].$2, 0);
    expect(points[delaunay.find(0, 1.2)].$2, 1);
    expect(points[delaunay.find(1, 1.9)].$2, 2);
    expect(points[delaunay.find(-1, 3.3)].$2, 3);
    expect(points[delaunay.find(10, 10)].$2, 4);
    expect(points[delaunay.find(10, 10)].$2, 4);
  });

  test('delaunay.find(x, y) works with collinear points 2', () {
    final points = List<(double, double)>.generate(
      120,
      (i) => (i * 4.0, i / 3.0 + 100.0),
    );
    final delaunay = Delaunay.fromCoords(points);
    expect(delaunay.neighbors(2).toList(), [1, 3]);
  });

  test('delaunay.find(x, y) works with collinear points 3', () {
    final points = List<(double, double)>.generate(
      120,
      (i) => (i * 4.0, i / 3.0 + 100.0),
    );
    final delaunay = Delaunay.fromCoords(points);
    expect(delaunay.neighbors(2).toList(), [1, 3]);
  });

  test('delaunay.find(x, y) works with collinear points (large)', () {
    final points = List<(double, double)>.generate(
      2000,
      (i) => ((i * i).toDouble(), (i * i).toDouble()),
    );
    final delaunay = Delaunay.fromCoords(points);
    expect(points[delaunay.find(0, -1)].$2, 0);
    expect(points[delaunay.find(0, 1.2)].$2, 1);
    expect(points[delaunay.find(3.9, 3.9)].$2, 4);
    expect(points[delaunay.find(10, 9.5)].$2, 9);
    expect(points[delaunay.find(10, 9.5)].$2, 9);
    expect(points[delaunay.find(1000000, 1000000)].$2, 1000000);
  });

  test('delaunay.update() allows fast updates', () {
    final delaunay = Delaunay.fromCoords(const <(double, double)>[
      (0, 0),
      (300, 0),
      (0, 300),
      (300, 300),
      (100, 100),
    ]);
    final circumcenters1 = delaunay.voronoi((
      -500,
      -500,
      500,
      500,
    )).circumcenters;
    for (var i = 0; i < delaunay.points.length; i++) {
      delaunay.points[i] = -delaunay.points[i];
    }
    delaunay.update();
    final circumcenters2 = delaunay.voronoi((
      -500,
      -500,
      500,
      500,
    )).circumcenters;
    expect(
      circumcenters1,
      Float64List.fromList([150, -50, -50, 150, 250, 150, 150, 250]),
    );
    expect(
      circumcenters2,
      Float64List.fromList([-150, 50, -250, -150, 50, -150, -150, -250]),
    );
  });

  test('delaunay.update() updates collinear points', () {
    final delaunay = Delaunay(Float64List(250));
    expect(delaunay.collinear, isNull);
    for (var i = 0; i < delaunay.points.length; i++) {
      delaunay.points[i] = i.isOdd ? i.toDouble() : 0;
    }
    delaunay.update();
    expect(delaunay.collinear?.length, 125);
    for (var i = 0; i < delaunay.points.length; i++) {
      delaunay.points[i] = math.sin(i);
    }
    delaunay.update();
    expect(delaunay.collinear, isNull);
    for (var i = 0; i < delaunay.points.length; i++) {
      delaunay.points[i] = i.isOdd ? i.toDouble() : 0;
    }
    delaunay.update();
    expect(delaunay.collinear?.length, 125);
    for (var i = 0; i < delaunay.points.length; i++) {
      delaunay.points[i] = 0;
    }
    delaunay.update();
    expect(delaunay.collinear, isNull);
  });

  test('delaunay.find(x, y) with coincident point', () {
    var delaunay = Delaunay.fromCoords(const <(double, double)>[
      (0, 0),
      (0, 0),
      (10, 10),
      (10, -10),
    ]);
    expect(delaunay.find(100, 100), 2);
    expect(delaunay.find(0, 0, 1), greaterThan(-1));
    delaunay = Delaunay.fromCoords(<(double, double)>[
      for (var i = 0; i < 1000; i++) (0, 0),
      (10, 10),
      (10, -10),
    ]);
    expect(delaunay.find(0, 0, 1), greaterThan(-1));
  });

  test('delaunay.find(x, y, i) traverses the convex hull', () {
    final delaunay = Delaunay(
      Float64List.fromList([
        509,
        253,
        426,
        240,
        426,
        292,
        567,
        272,
        355,
        356,
        413,
        392,
        319,
        408,
        374,
        285,
        327,
        303,
        381,
        215,
        475,
        319,
        301,
        352,
        247,
        426,
        532,
        334,
        234,
        366,
        479,
        375,
        251,
        302,
        340,
        170,
        160,
        377,
        626,
        317,
        177,
        296,
        322,
        243,
        195,
        422,
        241,
        232,
        585,
        358,
        666,
        406,
        689,
        343,
        172,
        198,
        527,
        401,
        766,
        350,
        444,
        432,
        117,
        316,
        267,
        170,
        580,
        412,
        754,
        425,
        117,
        231,
        725,
        300,
        700,
        222,
        438,
        165,
        703,
        168,
        558,
        221,
        475,
        211,
        491,
        125,
        216,
        166,
        240,
        108,
        783,
        266,
        640,
        258,
        184,
        77,
        387,
        90,
        162,
        125,
        621,
        162,
        296,
        78,
        532,
        154,
        763,
        199,
        132,
        165,
        422,
        343,
        312,
        128,
        125,
        77,
        450,
        95,
        635,
        106,
        803,
        415,
        714,
        63,
        529,
        87,
        388,
        152,
        575,
        126,
        573,
        64,
        726,
        381,
        773,
        143,
        787,
        67,
        690,
        117,
        813,
        203,
        811,
        319,
      ]),
    );
    expect(delaunay.find(49, 311), 31);
    expect(delaunay.find(49, 311, 22), 31);
  });

  test('delaunay.renderHull(context) is closed', () {
    final delaunay = Delaunay.fromCoords(const <(double, double)>[
      (0, 0),
      (1, 0),
      (0, 1),
      (1, 1),
    ]);
    final context = TestContext();
    delaunay.renderHull(context);
    expect(context.toString(), 'M0,1L1,1L1,0L0,0Z');
  });
}
