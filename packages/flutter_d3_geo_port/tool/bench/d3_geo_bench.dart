// Original code, not ported from d3-geo: the benchmark of the port.

/// The d3-geo benchmark of the Dart port: 12 seeded workloads matching
/// `d3_geo_bench.mjs` (upstream d3-geo v3.1.1 in Node.js) with identical
/// Park-Miller LCG inputs.
///
/// Run as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android, and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:flutter_d3_path_port/d3_path.dart';

/// Park-Miller LCG: exact in JS numbers and Dart.
final class Lcg(var int seed) {
  /// Next double in `[0, 1)`.
  double nextDouble() {
    seed = seed * 48271 % 2147483647;
    return seed / 2147483647.0;
  }
}

/// Lightweight [CanvasPath] sink measuring pure geometry emission without
/// SVG string formatting.
final class BenchCanvasSink() implements CanvasPath {
  /// Accumulated coordinate checksum preventing dead-code elimination.
  double acc = 0;

  @override
  void moveTo(double x, double y) => acc += x + y;

  @override
  void closePath() => acc += 1;

  @override
  void lineTo(double x, double y) => acc += x + y;

  @override
  void quadraticCurveTo(double x1, double y1, double x, double y) =>
      acc += x1 + y1 + x + y;

  @override
  void bezierCurveTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x,
    double y,
  ) => acc += x1 + y1 + x2 + y2 + x + y;

  @override
  void arcTo(double x1, double y1, double x2, double y2, double r) =>
      acc += x1 + y1 + x2 + y2 + r;

  @override
  void arc(
    double x,
    double y,
    double r,
    double a0,
    double a1, [
    bool ccw = false,
  ]) => acc += x + y + r + a0 + a1;

  @override
  void rect(double x, double y, double w, double h) => acc += x + y + w + h;
}

/// Seeded benchmark fixtures shared by pure and Flutter UI benchmarks.
final class GeoBenchFixtures._({
  /// 1,000 seeded global `(lon, lat)` points.
  required final List<GeoPosition> globalPts,

  /// 1,000 seeded US / Alaska / Hawaii / Europe points.
  required final List<GeoPosition> usPts,

  /// 20 synthetic landmass polygons (1,220 vertices total).
  required final GeoMultiPolygon worldPolys,

  /// Standard 10° global graticule.
  required final GeoMultiLineString graticule,

  /// Spherical circle with hole for `geoContains`.
  required final GeoPolygon targetPoly,

  /// 500 seeded query points for `geoContains`.
  required final List<GeoPosition> containsPts,
}) {
  /// Builds deterministic seeded fixtures matching `d3_geo_bench.mjs`.
  factory() {
    final r = Lcg(42);
    final globalPts = List<GeoPosition>.generate(1000, (_) {
      final lon = -180 + r.nextDouble() * 360;
      final lat = -80 + r.nextDouble() * 160;
      return (lon, lat);
    }, growable: false);

    final usPts = List<GeoPosition>.generate(1000, (i) {
      final mod = i % 10;
      if (mod == 0) {
        return (-165 + r.nextDouble() * 25, 58 + r.nextDouble() * 10);
      }
      if (mod == 1) {
        return (-160 + r.nextDouble() * 5, 19 + r.nextDouble() * 3);
      }
      if (mod == 2) {
        return (-10 + r.nextDouble() * 40, 35 + r.nextDouble() * 20);
      }
      return (-124 + r.nextDouble() * 55, 25 + r.nextDouble() * 24);
    }, growable: false);

    // 20 synthetic clockwise island/continent polygons (~60 verts each = 1,200)
    final polys = <List<List<GeoPosition>>>[];
    for (var p = 0; p < 20; ++p) {
      final cLon = -160 + (p % 5) * 75.0 + (r.nextDouble() - 0.5) * 15;
      final cLat = -55 + (p ~/ 5) * 35.0 + (r.nextDouble() - 0.5) * 10;
      final rx = 10 + r.nextDouble() * 14;
      final ry = 6 + r.nextDouble() * 10;
      final ring = <GeoPosition>[];
      const verts = 60;
      // Clockwise winding on (lon, lat) sphere (< 2*pi area)
      for (var k = 0; k < verts; ++k) {
        final a = -2 * math.pi * k / verts;
        final wobble =
            0.8 + 0.35 * math.sin(3 * a + p) + 0.15 * math.cos(5 * a);
        final lon = (cLon + rx * wobble * math.cos(a)).clamp(-179.5, 179.5);
        final lat = (cLat + ry * wobble * math.sin(a)).clamp(-84.0, 84.0);
        ring.add((lon, lat));
      }
      ring.add(ring[0]);
      polys.add(<List<GeoPosition>>[ring]);
    }
    final worldPolys = GeoMultiPolygon(polys);
    final graticule = geoGraticule10();

    // Target polygon with hole for geoContains (~240 verts)
    final outer = geoCircle(
      center: const (10, 20),
      radius: 35,
      precision: 2,
    )().coordinates[0];
    final inner = geoCircle(
      center: const (10, 20),
      radius: 10,
      precision: 6,
    )().coordinates[0].reversed.toList();
    final targetPoly = GeoPolygon(<List<GeoPosition>>[outer, inner]);

    final containsPts = List<GeoPosition>.generate(500, (_) {
      final lon = -40 + r.nextDouble() * 100;
      final lat = -30 + r.nextDouble() * 100;
      return (lon, lat);
    }, growable: false);

    return GeoBenchFixtures._(
      globalPts: globalPts,
      usPts: usPts,
      worldPolys: worldPolys,
      graticule: graticule,
      targetPoly: targetPoly,
      containsPts: containsPts,
    );
  }
}

double _sink = 0;

int _eatText(String? s) =>
    s == null || s.isEmpty ? 0 : s.length + s.codeUnitAt(s.length - 1);

/// Builds the 12 pure benchmark cases matching `d3_geo_bench.mjs`.
Map<String, void Function(int n)> buildGeoBenchCases(GeoBenchFixtures f) {
  final ortho = geoOrthographic()..rotate = const (-10, -25, 5);
  final merc = geoMercator();
  final eqEarth = geoEqualEarth();
  final natEarth = geoNaturalEarth1();
  final albersUsa = geoAlbersUsa();

  final canvasSink = BenchCanvasSink();
  final pathOrthoCanvas = geoPath(
    geoOrthographic()..rotate = const (-10, -25, 0),
    canvasSink,
  );
  final pathMercCanvas = geoPath(geoMercator(), canvasSink);
  final pathNatSvg = geoPath(geoNaturalEarth1());
  final pathEqCanvas = geoPath(geoEqualEarth(), canvasSink);

  return <String, void Function(int n)>{
    'project.orthographic_1k': (n) {
      var s = 0.0;
      final pts = f.globalPts;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < pts.length; ++j) {
          final p = ortho(pts[j]);
          if (p != null) s += p.$1 + p.$2;
        }
      }
      _sink += s;
    },
    'project.mercator_1k': (n) {
      var s = 0.0;
      final pts = f.globalPts;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < pts.length; ++j) {
          final p = merc(pts[j]);
          if (p != null) s += p.$1 + p.$2;
        }
      }
      _sink += s;
    },
    'project.equalEarth_1k': (n) {
      var s = 0.0;
      final pts = f.globalPts;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < pts.length; ++j) {
          final p = eqEarth(pts[j])!;
          final inv = eqEarth.invert(p)!;
          s += p.$1 + inv.$2;
        }
      }
      _sink += s;
    },
    'project.naturalEarth1_1k': (n) {
      var s = 0.0;
      final pts = f.globalPts;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < pts.length; ++j) {
          final p = natEarth(pts[j])!;
          final inv = natEarth.invert(p)!;
          s += p.$1 + inv.$2;
        }
      }
      _sink += s;
    },
    'project.albersUsa_1k': (n) {
      var s = 0.0;
      final pts = f.usPts;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < pts.length; ++j) {
          final p = albersUsa(pts[j]);
          if (p != null) s += p.$1 + p.$2;
        }
      }
      _sink += s;
    },
    'path.ortho_canvas': (n) {
      canvasSink.acc = 0;
      for (var i = 0; i < n; ++i) {
        pathOrthoCanvas(f.worldPolys);
        pathOrthoCanvas(f.graticule);
      }
      _sink += canvasSink.acc;
    },
    'path.mercator_canvas': (n) {
      canvasSink.acc = 0;
      for (var i = 0; i < n; ++i) {
        pathMercCanvas(f.worldPolys);
        pathMercCanvas(f.graticule);
      }
      _sink += canvasSink.acc;
    },
    'path.naturalEarth1_svg': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        s += _eatText(pathNatSvg(f.worldPolys));
      }
      _sink += s;
    },
    'path.equalEarth_canvas': (n) {
      canvasSink.acc = 0;
      for (var i = 0; i < n; ++i) {
        pathEqCanvas(f.worldPolys);
        pathEqCanvas(f.graticule);
      }
      _sink += canvasSink.acc;
    },
    'geoArea.world': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        s += geoArea(f.worldPolys);
      }
      _sink += s;
    },
    'geoBounds.world': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final b = geoBounds(f.worldPolys);
        s += b.$1.$1 + b.$2.$2;
      }
      _sink += s;
    },
    'geoContains.500': (n) {
      var s = 0;
      final pts = f.containsPts;
      final poly = f.targetPoly;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < pts.length; ++j) {
          if (geoContains(poly, pts[j])) ++s;
        }
      }
      _sink += s;
    },
  };
}

/// Times [fn] after warmup, returning median ns/op across [batches] timed runs.
double measureCase(
  void Function(int n) fn, {
  int warmupMs = 250,
  int batchMs = 60,
  int batches = 9,
}) {
  final sw = Stopwatch()..start();
  var batch = 1;
  while (sw.elapsedMilliseconds < warmupMs) {
    final t0 = sw.elapsedMicroseconds;
    fn(batch);
    final dt = sw.elapsedMicroseconds - t0;
    if (dt < 5000) {
      batch *= 2;
    } else if (dt < batchMs * 1000 ~/ 2) {
      batch = (batch * (batchMs * 1000) / dt).ceil().clamp(1, 10000000);
    }
  }
  final samples = <double>[];
  for (var b = 0; b < batches; ++b) {
    final t0 = sw.elapsedMicroseconds;
    fn(batch);
    final dt = sw.elapsedMicroseconds - t0;
    samples.add(dt * 1000.0 / batch);
  }
  samples.sort();
  return samples[samples.length ~/ 2];
}

void main(List<String> args) {
  final filter = args.isNotEmpty ? args.first : null;
  final fixtures = GeoBenchFixtures();
  final cases = buildGeoBenchCases(fixtures);
  for (final entry in cases.entries) {
    if (filter != null && !entry.key.contains(filter)) continue;
    final ns = measureCase(entry.value);
    print('BENCH {"case":"${entry.key}","ns_per_op":${ns.toStringAsFixed(1)}}');
  }
  if (_sink == 1e308) print(_sink);
}
