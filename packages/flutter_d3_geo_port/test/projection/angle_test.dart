// Ported from d3-geo v3.1.1 test/projection/angle-test.js (ISC, Mike Bostock).
// Upstream test titles exceed 80 chars.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import '../asserts.dart';
import 'asserts.dart';

void main() {
  test('projection.angle(…) defaults to zero', () {
    final projection = geoGnomonic()
      ..scale = 1
      ..translate = const (0, 0);
    expect(projection.angle, 0);
    assertProjectionEqual(projection, const (0, 0), const (0, 0));
    assertProjectionEqual(
      projection,
      const (10, 0),
      const (0.17632698070846498, 0),
    );
    assertProjectionEqual(
      projection,
      const (-10, 0),
      const (-0.17632698070846498, 0),
    );
    assertProjectionEqual(
      projection,
      const (0, 10),
      const (0, -0.17632698070846498),
    );
    assertProjectionEqual(
      projection,
      const (0, -10),
      const (0, 0.17632698070846498),
    );
    assertProjectionEqual(
      projection,
      const (10, 10),
      const (0.17632698070846495, -0.17904710860483972),
    );
    assertProjectionEqual(
      projection,
      const (10, -10),
      const (0.17632698070846495, 0.17904710860483972),
    );
    assertProjectionEqual(
      projection,
      const (-10, 10),
      const (-0.17632698070846495, -0.17904710860483972),
    );
    assertProjectionEqual(
      projection,
      const (-10, -10),
      const (-0.17632698070846495, 0.17904710860483972),
    );
  });

  test('projection.angle(…) rotates by the specified degrees after projecting (30)', () {
    final projection = geoGnomonic()
      ..scale = 1
      ..translate = const (0, 0)
      ..angle = 30;
    assertInDelta(projection.angle, 30);
    assertProjectionEqual(projection, const (0, 0), const (0, 0));
    assertProjectionEqual(
      projection,
      const (10, 0),
      const (0.1527036446661393, -0.08816349035423247),
    );
    assertProjectionEqual(
      projection,
      const (-10, 0),
      const (-0.1527036446661393, 0.08816349035423247),
    );
    assertProjectionEqual(
      projection,
      const (0, 10),
      const (-0.08816349035423247, -0.1527036446661393),
    );
    assertProjectionEqual(
      projection,
      const (0, -10),
      const (0.08816349035423247, 0.1527036446661393),
    );
    assertProjectionEqual(
      projection,
      const (10, 10),
      const (0.06318009036371944, -0.24322283488017502),
    );
    assertProjectionEqual(
      projection,
      const (10, -10),
      const (0.24222719896855913, 0.0668958541717101),
    );
    assertProjectionEqual(
      projection,
      const (-10, 10),
      const (-0.24222719896855913, -0.0668958541717101),
    );
    assertProjectionEqual(
      projection,
      const (-10, -10),
      const (-0.06318009036371944, 0.24322283488017502),
    );
  });

  test('projection.angle(…) rotates by the specified degrees after projecting (-30)', () {
    final projection = geoGnomonic()
      ..scale = 1
      ..translate = const (0, 0)
      ..angle = -30;
    assertInDelta(projection.angle, -30);
    assertProjectionEqual(projection, const (0, 0), const (0, 0));
    assertProjectionEqual(
      projection,
      const (10, 0),
      const (0.1527036446661393, 0.08816349035423247),
    );
    assertProjectionEqual(
      projection,
      const (-10, 0),
      const (-0.1527036446661393, -0.08816349035423247),
    );
    assertProjectionEqual(
      projection,
      const (0, 10),
      const (0.08816349035423247, -0.1527036446661393),
    );
    assertProjectionEqual(
      projection,
      const (0, -10),
      const (-0.08816349035423247, 0.1527036446661393),
    );
    assertProjectionEqual(
      projection,
      const (10, 10),
      const (0.24222719896855913, -0.0668958541717101),
    );
    assertProjectionEqual(
      projection,
      const (10, -10),
      const (0.06318009036371944, 0.24322283488017502),
    );
    assertProjectionEqual(
      projection,
      const (-10, 10),
      const (-0.06318009036371944, -0.24322283488017502),
    );
    assertProjectionEqual(
      projection,
      const (-10, -10),
      const (-0.24222719896855913, 0.0668958541717101),
    );
  });

  test('projection.angle(…) wraps around 360°', () {
    final projection = geoGnomonic()
      ..scale = 1
      ..translate = const (0, 0)
      ..angle = 360;
    expect(projection.angle, 0);
  });

  test('identity.angle(…) rotates geoIdentity', () {
    final projection = geoIdentity()..angle = -45;
    const sqrt2Over2 = math.sqrt2 / 2;
    assertInDelta(projection.angle, -45);
    assertProjectionEqual(projection, const (0, 0), const (0, 0));
    assertProjectionEqual(projection, const (1, 0), (sqrt2Over2, sqrt2Over2));
    assertProjectionEqual(
      projection,
      const (-1, 0),
      (-sqrt2Over2, -sqrt2Over2),
    );
    assertProjectionEqual(projection, const (0, 1), (-sqrt2Over2, sqrt2Over2));
  });
}
