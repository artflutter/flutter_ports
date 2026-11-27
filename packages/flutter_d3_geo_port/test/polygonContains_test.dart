// Ported from d3-geo v3.1.1 test/polygonContains-test.js (ISC, Mike Bostock).
// Upstream filename and test titles exceed 80 chars.
// ignore_for_file: file_names, lines_longer_than_80_chars

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

GeoPosition _pointRadians(GeoPosition point) =>
    (point.$1 * math.pi / 180, point.$2 * math.pi / 180);

List<GeoPosition> _ringRadians(List<GeoPosition> ring) => <GeoPosition>[
  for (var i = 0; i < ring.length - 1; ++i) _pointRadians(ring[i]),
];

bool _polygonContains(List<List<GeoPosition>> polygon, GeoPosition point) =>
    geoPolygonContains(<List<GeoPosition>>[
      for (final r in polygon) _ringRadians(r),
    ], _pointRadians(point));

void main() {
  test('geoPolygonContains(empty, point) returns false', () {
    expect(
      _polygonContains(const <List<GeoPosition>>[], const (0, 0)),
      isFalse,
    );
  });

  test('geoPolygonContains(simple, point) returns the expected value', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[(0, 0), (0, 1), (1, 1), (1, 0), (0, 0)],
    ];
    expect(_polygonContains(polygon, const (0.1, 2)), isFalse);
    expect(_polygonContains(polygon, const (0.1, 0.1)), isTrue);
  });

  test('geoPolygonContains(smallCircle, point) returns the expected value', () {
    final polygon = geoCircle(radius: 60)().coordinates;
    expect(_polygonContains(polygon, const (-180, 0)), isFalse);
    expect(_polygonContains(polygon, const (1, 1)), isTrue);
  });

  test('geoPolygonContains wraps longitudes', () {
    final polygon = geoCircle(center: const (300, 0))().coordinates;
    expect(_polygonContains(polygon, const (300, 0)), isTrue);
    expect(_polygonContains(polygon, const (-60, 0)), isTrue);
    expect(_polygonContains(polygon, const (-420, 0)), isTrue);
  });

  test('geoPolygonContains(southPole, point) returns the expected value', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[(-60, -80), (60, -80), (180, -80), (-60, -80)],
    ];
    expect(_polygonContains(polygon, const (0, 0)), isFalse);
    expect(_polygonContains(polygon, const (0, -85)), isTrue);
    expect(_polygonContains(polygon, const (0, -90)), isTrue);
  });

  test('geoPolygonContains(northPole, point) returns the expected value', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[(60, 80), (-60, 80), (-180, 80), (60, 80)],
    ];
    expect(_polygonContains(polygon, const (0, 0)), isFalse);
    expect(_polygonContains(polygon, const (0, 85)), isTrue);
    expect(_polygonContains(polygon, const (0, 90)), isTrue);
    expect(_polygonContains(polygon, const (-100, 90)), isTrue);
    expect(_polygonContains(polygon, const (0, -90)), isFalse);
  });

  test('geoPolygonContains(touchingPole, Pole) returns true (issue #105)', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[(0, -30), (120, -30), (0, -90), (0, -30)],
    ];
    expect(_polygonContains(polygon, const (0, -90)), isFalse);
    expect(_polygonContains(polygon, const (-60, -90)), isFalse);
    expect(_polygonContains(polygon, const (60, -90)), isFalse);
    const polygon2 = <List<GeoPosition>>[
      <GeoPosition>[(0, 30), (-120, 30), (0, 90), (0, 30)],
    ];
    expect(_polygonContains(polygon2, const (0, 90)), isFalse);
    expect(_polygonContains(polygon2, const (-60, 90)), isFalse);
    expect(_polygonContains(polygon2, const (60, 90)), isFalse);
  });

  test(
    'geoPolygonContains(southHemispherePoly) returns the expected value',
    () {
      const polygon = <List<GeoPosition>>[
        <GeoPosition>[(0, 0), (10, -40), (-10, -40), (0, 0)],
      ];
      expect(_polygonContains(polygon, const (0, -40.2)), isTrue);
      expect(_polygonContains(polygon, const (0, -40.5)), isFalse);
    },
  );

  test(
    'geoPolygonContains(largeNearOrigin, point) returns the expected value',
    () {
      const polygon = <List<GeoPosition>>[
        <GeoPosition>[(0, 0), (1, 0), (1, 1), (0, 1), (0, 0)],
      ];
      expect(_polygonContains(polygon, const (0.1, 0.1)), isFalse);
      expect(_polygonContains(polygon, const (2, 0.1)), isTrue);
    },
  );

  test(
    'geoPolygonContains(largeNearSouthPole, point) returns the expected value',
    () {
      const polygon = <List<GeoPosition>>[
        <GeoPosition>[(-60, 80), (60, 80), (180, 80), (-60, 80)],
      ];
      expect(_polygonContains(polygon, const (0, 85)), isFalse);
      expect(_polygonContains(polygon, const (0, 0)), isTrue);
    },
  );

  test(
    'geoPolygonContains(largeNearNorthPole, point) returns the expected value',
    () {
      const polygon = <List<GeoPosition>>[
        <GeoPosition>[(60, -80), (-60, -80), (-180, -80), (60, -80)],
      ];
      expect(_polygonContains(polygon, const (0, -85)), isFalse);
      expect(_polygonContains(polygon, const (0, 0)), isTrue);
    },
  );

  test('geoPolygonContains(largeCircle, point) returns the expected value', () {
    final polygon = geoCircle(radius: 120)().coordinates;
    expect(_polygonContains(polygon, const (-180, 0)), isFalse);
    expect(_polygonContains(polygon, const (-90, 0)), isTrue);
  });

  test('geoPolygonContains(largeNarrowStripHole, point) returns the expected value', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[
        (-170, -1),
        (0, -1),
        (170, -1),
        (170, 1),
        (0, 1),
        (-170, 1),
        (-170, -1),
      ],
    ];
    expect(_polygonContains(polygon, const (0, 0)), isFalse);
    expect(_polygonContains(polygon, const (0, 20)), isTrue);
  });

  test('geoPolygonContains(largeNarrowEquatorialHole, point) returns the expected value', () {
    final circle = geoCircle(center: const (0, -90));
    final ring0 = (circle..radius = 90 - 0.01)().coordinates[0];
    final ring1 = (circle..radius = 90 + 0.01)().coordinates[0].reversed
        .toList();
    final polygon = <List<GeoPosition>>[ring0, ring1];
    expect(_polygonContains(polygon, const (0, 0)), isFalse);
    expect(_polygonContains(polygon, const (0, -90)), isTrue);
  });

  test('geoPolygonContains(largeNarrowEquatorialStrip, point) returns the expected value', () {
    final circle = geoCircle(center: const (0, -90));
    final ring0 = (circle..radius = 90 + 0.01)().coordinates[0];
    final ring1 = (circle..radius = 90 - 0.01)().coordinates[0].reversed
        .toList();
    final polygon = <List<GeoPosition>>[ring0, ring1];
    expect(_polygonContains(polygon, const (0, -90)), isFalse);
    expect(_polygonContains(polygon, const (0, 0)), isTrue);
  });

  test(
    'geoPolygonContains(ringNearOrigin, point) returns the expected value',
    () {
      const polygon = <List<GeoPosition>>[
        <GeoPosition>[(0, 0), (0, 1), (1, 1), (1, 0), (0, 0)],
        <GeoPosition>[
          (0.4, 0.4),
          (0.6, 0.4),
          (0.6, 0.6),
          (0.4, 0.6),
          (0.4, 0.4),
        ],
      ];
      expect(_polygonContains(polygon, const (0.5, 0.5)), isFalse);
      expect(_polygonContains(polygon, const (0.1, 0.5)), isTrue);
    },
  );

  test(
    'geoPolygonContains(ringEquatorial, point) returns the expected value',
    () {
      const polygon = <List<GeoPosition>>[
        <GeoPosition>[(0, -10), (-120, -10), (120, -10), (0, -10)],
        <GeoPosition>[(0, 10), (120, 10), (-120, 10), (0, 10)],
      ];
      expect(_polygonContains(polygon, const (0, 20)), isFalse);
      expect(_polygonContains(polygon, const (0, 0)), isTrue);
    },
  );

  test('geoPolygonContains(ringExcludingBothPoles, point) returns the expected value', () {
    final ring0 = const <GeoPosition>[
      (10, 10),
      (-10, 10),
      (-10, -10),
      (10, -10),
      (10, 10),
    ].reversed.toList();
    final ring1 = const <GeoPosition>[
      (170, 10),
      (170, -10),
      (-170, -10),
      (-170, 10),
      (170, 10),
    ].reversed.toList();
    final polygon = <List<GeoPosition>>[ring0, ring1];
    expect(_polygonContains(polygon, const (0, 90)), isFalse);
    expect(_polygonContains(polygon, const (0, 0)), isTrue);
  });

  test('geoPolygonContains(ringContainingBothPoles, point) returns the expected value', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[(10, 10), (-10, 10), (-10, -10), (10, -10), (10, 10)],
      <GeoPosition>[(170, 10), (170, -10), (-170, -10), (-170, 10), (170, 10)],
    ];
    expect(_polygonContains(polygon, const (0, 0)), isFalse);
    expect(_polygonContains(polygon, const (0, 20)), isTrue);
  });

  test('geoPolygonContains(ringContainingSouthPole, point) returns the expected value', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[(10, 10), (-10, 10), (-10, -10), (10, -10), (10, 10)],
      <GeoPosition>[(0, 80), (120, 80), (-120, 80), (0, 80)],
    ];
    expect(_polygonContains(polygon, const (0, 90)), isFalse);
    expect(_polygonContains(polygon, const (0, -90)), isTrue);
  });

  test('geoPolygonContains(ringContainingNorthPole, point) returns the expected value', () {
    final ring0 = const <GeoPosition>[
      (10, 10),
      (-10, 10),
      (-10, -10),
      (10, -10),
      (10, 10),
    ].reversed.toList();
    final ring1 = const <GeoPosition>[
      (0, 80),
      (120, 80),
      (-120, 80),
      (0, 80),
    ].reversed.toList();
    final polygon = <List<GeoPosition>>[ring0, ring1];
    expect(_polygonContains(polygon, const (0, -90)), isFalse);
    expect(_polygonContains(polygon, const (0, 90)), isTrue);
  });

  test('geoPolygonContains(selfIntersectingNearOrigin, point) returns the expected value', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[(0, 0), (1, 0), (1, 3), (3, 3), (3, 1), (0, 1), (0, 0)],
    ];
    expect(_polygonContains(polygon, const (15, 0.5)), isFalse);
    expect(_polygonContains(polygon, const (12, 2)), isFalse);
    expect(_polygonContains(polygon, const (0.5, 0.5)), isTrue);
    expect(_polygonContains(polygon, const (2, 2)), isTrue);
  });

  test('geoPolygonContains(selfIntersectingNearSouthPole, point) returns the expected value', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[
        (-10, -80),
        (120, -80),
        (-120, -80),
        (10, -85),
        (10, -75),
        (-10, -75),
        (-10, -80),
      ],
    ];
    expect(_polygonContains(polygon, const (0, 0)), isFalse);
    expect(_polygonContains(polygon, const (0, -76)), isTrue);
    expect(_polygonContains(polygon, const (0, -89)), isTrue);
  });

  test('geoPolygonContains(selfIntersectingNearNorthPole, point) returns the expected value', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[
        (-10, 80),
        (-10, 75),
        (10, 75),
        (10, 85),
        (-120, 80),
        (120, 80),
        (-10, 80),
      ],
    ];
    expect(_polygonContains(polygon, const (0, 0)), isFalse);
    expect(_polygonContains(polygon, const (0, 76)), isTrue);
    expect(_polygonContains(polygon, const (0, 89)), isTrue);
  });

  test('geoPolygonContains(hemisphereTouchingTheSouthPole, point) returns the expected value', () {
    final polygon = geoCircle(radius: 90)().coordinates;
    expect(_polygonContains(polygon, const (0, 0)), isTrue);
  });

  test('geoPolygonContains(triangleTouchingTheSouthPole, point) returns the expected value', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[(180, -90), (-45, 0), (45, 0), (180, -90)],
    ];
    expect(_polygonContains(polygon, const (-46, 0)), isFalse);
    expect(_polygonContains(polygon, const (0, 1)), isFalse);
    expect(_polygonContains(polygon, const (-90, -80)), isFalse);
    expect(_polygonContains(polygon, const (-44, 0)), isTrue);
    expect(_polygonContains(polygon, const (0, 0)), isTrue);
    expect(_polygonContains(polygon, const (0, -30)), isTrue);
    expect(_polygonContains(polygon, const (30, -80)), isTrue);
  });

  test('geoPolygonContains(triangleTouchingTheSouthPole2, point) returns the expected value', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[(-45, 0), (45, 0), (180, -90), (-45, 0)],
    ];
    expect(_polygonContains(polygon, const (-46, 0)), isFalse);
    expect(_polygonContains(polygon, const (0, 1)), isFalse);
    expect(_polygonContains(polygon, const (-90, -80)), isFalse);
    expect(_polygonContains(polygon, const (-44, 0)), isTrue);
    expect(_polygonContains(polygon, const (0, 0)), isTrue);
    expect(_polygonContains(polygon, const (0, -30)), isTrue);
    expect(_polygonContains(polygon, const (30, -80)), isTrue);
  });

  test('geoPolygonContains(triangleTouchingTheSouthPole3, point) returns the expected value', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[(180, -90), (-135, 0), (135, 0), (180, -90)],
    ];
    expect(_polygonContains(polygon, const (180, 0)), isFalse);
    expect(_polygonContains(polygon, const (150, 0)), isFalse);
    expect(_polygonContains(polygon, const (180, -30)), isFalse);
    expect(_polygonContains(polygon, const (150, -80)), isFalse);
    expect(_polygonContains(polygon, const (0, 0)), isTrue);
    expect(_polygonContains(polygon, const (180, 1)), isTrue);
    expect(_polygonContains(polygon, const (-90, -80)), isTrue);
  });

  test('geoPolygonContains(triangleTouchingTheNorthPole, point) returns the expected value', () {
    const polygon = <List<GeoPosition>>[
      <GeoPosition>[(180, 90), (45, 0), (-45, 0), (180, 90)],
    ];
    expect(_polygonContains(polygon, const (-90, 0)), isFalse);
    expect(_polygonContains(polygon, const (0, -1)), isFalse);
    expect(_polygonContains(polygon, const (0, -80)), isFalse);
    expect(_polygonContains(polygon, const (-90, 1)), isFalse);
    expect(_polygonContains(polygon, const (-90, 80)), isFalse);
    expect(_polygonContains(polygon, const (-44, 10)), isTrue);
    expect(_polygonContains(polygon, const (0, 10)), isTrue);
    expect(_polygonContains(polygon, const (30, 80)), isTrue);
  });
}
