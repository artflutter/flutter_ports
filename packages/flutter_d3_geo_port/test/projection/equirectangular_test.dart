// Ported from d3-geo v3.1.1 test/projection/equirectangular-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'asserts.dart';

const double _pi = math.pi;

void main() {
  test('equirectangular(point) returns the expected result', () {
    final equirectangular = geoEquirectangular()
      ..translate = const (0, 0)
      ..scale = 1;
    assertProjectionEqual(equirectangular, const (0, 0), const (0, 0));
    assertProjectionEqual(equirectangular, const (-180, 0), const (-_pi, 0));
    assertProjectionEqual(equirectangular, const (180, 0), const (_pi, 0));
    assertProjectionEqual(equirectangular, const (0, 30), const (0, -_pi / 6));
    assertProjectionEqual(equirectangular, const (0, -30), const (0, _pi / 6));
    assertProjectionEqual(
      equirectangular,
      const (30, 30),
      const (_pi / 6, -_pi / 6),
    );
    assertProjectionEqual(
      equirectangular,
      const (30, -30),
      const (_pi / 6, _pi / 6),
    );
    assertProjectionEqual(
      equirectangular,
      const (-30, 30),
      const (-_pi / 6, -_pi / 6),
    );
    assertProjectionEqual(
      equirectangular,
      const (-30, -30),
      const (-_pi / 6, _pi / 6),
    );
  });

  test(
    'equirectangular.rotate([30, 0])(point) returns the expected result',
    () {
      final equirectangular = geoEquirectangular()
        ..rotate = const (30, 0, 0)
        ..translate = const (0, 0)
        ..scale = 1;
      assertProjectionEqual(equirectangular, const (0, 0), const (_pi / 6, 0));
      assertProjectionEqual(
        equirectangular,
        const (-180, 0),
        const (-5 / 6 * _pi, 0),
      );
      assertProjectionEqual(
        equirectangular,
        const (180, 0),
        const (-5 / 6 * _pi, 0),
      );
      assertProjectionEqual(
        equirectangular,
        const (0, 30),
        const (_pi / 6, -_pi / 6),
      );
      assertProjectionEqual(
        equirectangular,
        const (0, -30),
        const (_pi / 6, _pi / 6),
      );
      assertProjectionEqual(
        equirectangular,
        const (30, 30),
        const (_pi / 3, -_pi / 6),
      );
      assertProjectionEqual(
        equirectangular,
        const (30, -30),
        const (_pi / 3, _pi / 6),
      );
      assertProjectionEqual(
        equirectangular,
        const (-30, 30),
        const (0, -_pi / 6),
      );
      assertProjectionEqual(
        equirectangular,
        const (-30, -30),
        const (0, _pi / 6),
      );
    },
  );

  test(
    'equirectangular.rotate([30, 30])(point) returns the expected result',
    () {
      final equirectangular = geoEquirectangular()
        ..rotate = const (30, 30, 0)
        ..translate = const (0, 0)
        ..scale = 1;
      assertProjectionEqual(
        equirectangular,
        const (0, 0),
        const (0.5880026035475674, -0.44783239692893245),
      );
      assertProjectionEqual(
        equirectangular,
        const (-180, 0),
        const (-2.5535900500422257, 0.44783239692893245),
      );
      assertProjectionEqual(
        equirectangular,
        const (180, 0),
        const (-2.5535900500422257, 0.44783239692893245),
      );
      assertProjectionEqual(
        equirectangular,
        const (0, 30),
        const (0.8256075561643480, -0.9407711951705208),
      );
      assertProjectionEqual(
        equirectangular,
        const (0, -30),
        const (0.4486429615608479, 0.05804529130778048),
      );
      assertProjectionEqual(
        equirectangular,
        const (30, 30),
        const (1.4056476493802694, -0.7069517278872177),
      );
      assertProjectionEqual(
        equirectangular,
        const (30, -30),
        const (0.8760580505981933, 0.21823451436745955),
      );
      assertProjectionEqual(
        equirectangular,
        const (-30, 30),
        const (0.0, -1.0471975511965976),
      );
      assertProjectionEqual(
        equirectangular,
        const (-30, -30),
        const (0.0, 0.0),
      );
    },
  );

  test(
    'equirectangular.rotate([0, 0, 30])(point) returns the expected result',
    () {
      final equirectangular = geoEquirectangular()
        ..rotate = const (0, 0, 30)
        ..translate = const (0, 0)
        ..scale = 1;
      assertProjectionEqual(equirectangular, const (0, 0), const (0, 0));
      assertProjectionEqual(equirectangular, const (-180, 0), const (-_pi, 0));
      assertProjectionEqual(equirectangular, const (180, 0), const (_pi, 0));
      assertProjectionEqual(
        equirectangular,
        const (0, 30),
        const (-0.2810349015028135, -0.44783239692893245),
      );
      assertProjectionEqual(
        equirectangular,
        const (0, -30),
        const (0.2810349015028135, 0.44783239692893245),
      );
      assertProjectionEqual(
        equirectangular,
        const (30, 30),
        const (0.1651486774146268, -0.7069517278872176),
      );
      assertProjectionEqual(
        equirectangular,
        const (30, -30),
        const (0.6947382761967031, 0.21823451436745964),
      );
      assertProjectionEqual(
        equirectangular,
        const (-30, 30),
        const (-0.6947382761967031, -0.21823451436745964),
      );
      assertProjectionEqual(
        equirectangular,
        const (-30, -30),
        const (-0.1651486774146268, 0.7069517278872176),
      );
    },
  );

  test(
    'equirectangular.rotate([30, 30, 30])(point) returns the expected result',
    () {
      final equirectangular = geoEquirectangular()
        ..rotate = const (30, 30, 30)
        ..translate = const (0, 0)
        ..scale = 1;
      assertProjectionEqual(
        equirectangular,
        const (0, 0),
        const (0.2810349015028135, -0.6751315329370317),
      );
      assertProjectionEqual(
        equirectangular,
        const (-180, 0),
        const (-2.860557752086980, 0.6751315329370317),
      );
      assertProjectionEqual(
        equirectangular,
        const (180, 0),
        const (-2.860557752086980, 0.6751315329370317),
      );
      assertProjectionEqual(
        equirectangular,
        const (0, 30),
        const (-0.0724760059270816, -1.1586567708659772),
      );
      assertProjectionEqual(
        equirectangular,
        const (0, -30),
        const (0.4221351552567053, -0.16704161863132252),
      );
      assertProjectionEqual(
        equirectangular,
        const (30, 30),
        const (1.2033744221750944, -1.2153751251046732),
      );
      assertProjectionEqual(
        equirectangular,
        const (30, -30),
        const (0.8811235701944905, -0.18861638617540410),
      );
      assertProjectionEqual(
        equirectangular,
        const (-30, 30),
        const (-0.7137243789447654, -0.84806207898148100),
      );
      assertProjectionEqual(equirectangular, const (-30, -30), const (0, 0));
    },
  );
}
