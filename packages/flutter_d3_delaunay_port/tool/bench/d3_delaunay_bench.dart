// Original code, not ported from d3-delaunay: the benchmark of the port.

/// The d3-delaunay benchmark of the Dart port: 14 seeded workloads matching
/// `d3_delaunay_bench.mjs` (upstream d3-delaunay v6.0.4 + delaunator v5.1.0 +
/// robust-predicates v3.0.3 in Node.js) with identical Park-Miller LCG inputs.
///
/// Run as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android, and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_delaunay_port/d3_delaunay.dart';
import 'package:flutter_d3_path_port/d3_path.dart';

/// Park-Miller LCG: exact in JS numbers and Dart.
final class Lcg(var int seed) {
  /// Next double in `[0, 1)`.
  double nextDouble() {
    seed = seed * 48271 % 2147483647;
    return seed / 2147483647.0;
  }
}

/// Zero-SVG counting [CanvasPath] sink matching direct Flutter `UiPathContext`
/// dispatch (without SVG formatting/parsing).
final class _CountingCanvasPath() implements CanvasPath {
  double acc = 0;

  @override
  void moveTo(double x, double y) => acc += x + y;

  @override
  void lineTo(double x, double y) => acc += x + y;

  @override
  void closePath() => acc += 1;

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
  ]) => acc += x + y + r;

  @override
  void rect(double x, double y, double w, double h) => acc += x + y + w + h;
}

final class _BenchFixtures._({
  required final Float64List orientCoords,
  required final Float64List uniform1000,
  required final List<(double, double)> uniform1000Pairs,
  required final Float64List uniform5000,
  required final Float64List clustered2000,
  required final Float64List findQueries512,
}) {
  factory() {
    final r = Lcg(42);

    Float64List makeUniform(int n) {
      final out = Float64List(n * 2);
      for (var i = 0; i < n; ++i) {
        out[2 * i] = r.nextDouble() * 1000.0;
        out[2 * i + 1] = r.nextDouble() * 1000.0;
      }
      return out;
    }

    final uniform1000 = makeUniform(1000);
    final uniform1000Pairs = List<(double, double)>.generate(
      1000,
      (i) => (uniform1000[2 * i], uniform1000[2 * i + 1]),
      growable: false,
    );
    final uniform5000 = makeUniform(5000);

    // 5 Gaussian clusters via Box-Muller using the seeded LCG.
    const centers = <(double, double)>[
      (200, 220),
      (780, 240),
      (500, 500),
      (260, 760),
      (760, 780),
    ];
    final clustered2000 = Float64List(4000);
    for (var i = 0; i < 2000; ++i) {
      final (cx, cy) = centers[i % centers.length];
      final u1 = math.max(1e-9, r.nextDouble());
      final u2 = r.nextDouble();
      final mag = math.sqrt(-2.0 * math.log(u1)) * 55.0;
      final ang = 2.0 * math.pi * u2;
      clustered2000[2 * i] = cx + mag * math.cos(ang);
      clustered2000[2 * i + 1] = cy + mag * math.sin(ang);
    }

    final findQueries512 = makeUniform(512);

    // 10,000 orient2d triples: 90% general position, 10% near-collinear.
    final orientCoords = Float64List(10000 * 6);
    final tiny = math.pow(2, -43).toDouble();
    for (var i = 0; i < 10000; ++i) {
      final base = i * 6;
      if (i % 10 == 0) {
        orientCoords[base] = 0.95 + tiny * (i % 128) / 128.0;
        orientCoords[base + 1] = 0.95 + tiny * ((i * 7) % 128) / 128.0;
        orientCoords[base + 2] = 18.0;
        orientCoords[base + 3] = 18.0;
        orientCoords[base + 4] = 16.8;
        orientCoords[base + 5] = 16.8;
      } else {
        orientCoords[base] = r.nextDouble() * 1000.0;
        orientCoords[base + 1] = r.nextDouble() * 1000.0;
        orientCoords[base + 2] = r.nextDouble() * 1000.0;
        orientCoords[base + 3] = r.nextDouble() * 1000.0;
        orientCoords[base + 4] = r.nextDouble() * 1000.0;
        orientCoords[base + 5] = r.nextDouble() * 1000.0;
      }
    }

    return _BenchFixtures._(
      orientCoords: orientCoords,
      uniform1000: uniform1000,
      uniform1000Pairs: uniform1000Pairs,
      uniform5000: uniform5000,
      clustered2000: clustered2000,
      findQueries512: findQueries512,
    );
  }
}

double _sink = 0;

/// Runs all 14 d3-delaunay benchmark cases and returns `BENCH {json}` lines.
List<String> runBenchmarks({
  String target = 'dart',
  String filter = '',
  int batches = 9,
  int batchMs = 60,
  int warmMs = 300,
}) {
  final f = _BenchFixtures();

  final d1000 = Delaunay(Float64List.fromList(f.uniform1000));
  final d5000 = Delaunay(Float64List.fromList(f.uniform5000));
  final v1000 = d1000.voronoi((0, 0, 1000, 1000));

  final updDelaunator = Delaunator(Float64List.fromList(f.uniform1000));
  final updDelaunay = Delaunay(Float64List.fromList(f.uniform1000));
  final updVoronoi = Delaunay(Float64List.fromList(f.uniform1000))
      .voronoi((0, 0, 1000, 1000));

  final cases = <String, void Function(int)>{
    'orient2d.exact_10k': (n) {
      var s = 0.0;
      final c = f.orientCoords;
      for (var k = 0; k < n; ++k) {
        for (var i = 0; i < 60000; i += 6) {
          s += orient2d(c[i], c[i + 1], c[i + 2], c[i + 3], c[i + 4], c[i + 5]);
        }
      }
      _sink += s;
    },
    'delaunator.uniform_1000': (n) {
      var s = 0;
      for (var k = 0; k < n; ++k) {
        final d = Delaunator(f.uniform1000);
        s += d.trianglesLen;
      }
      _sink += s;
    },
    'delaunator.uniform_5000': (n) {
      var s = 0;
      for (var k = 0; k < n; ++k) {
        final d = Delaunator(f.uniform5000);
        s += d.trianglesLen;
      }
      _sink += s;
    },
    'delaunator.clustered_2000': (n) {
      var s = 0;
      for (var k = 0; k < n; ++k) {
        final d = Delaunator(f.clustered2000);
        s += d.trianglesLen;
      }
      _sink += s;
    },
    'delaunator.update_1000': (n) {
      var s = 0;
      final coords = updDelaunator.coords;
      for (var k = 0; k < n; ++k) {
        final delta = k.isEven ? 0.25 : -0.25;
        for (var i = 0; i < 200; i += 2) {
          coords[i] += delta;
        }
        updDelaunator.update();
        s += updDelaunator.trianglesLen;
      }
      _sink += s;
    },
    'delaunay.from_1000': (n) {
      var s = 0;
      for (var k = 0; k < n; ++k) {
        final d = Delaunay.fromCoords(f.uniform1000Pairs);
        s += d.triangles.length;
      }
      _sink += s;
    },
    'delaunay.update_1000': (n) {
      var s = 0;
      final pts = updDelaunay.points;
      for (var k = 0; k < n; ++k) {
        final delta = k.isEven ? 0.25 : -0.25;
        for (var i = 0; i < 200; i += 2) {
          pts[i] += delta;
        }
        updDelaunay.update();
        s += updDelaunay.triangles.length;
      }
      _sink += s;
    },
    'delaunay.find_512': (n) {
      var s = 0;
      final q = f.findQueries512;
      for (var k = 0; k < n; ++k) {
        var last = 0;
        for (var i = 0; i < 1024; i += 2) {
          last = d5000.find(q[i], q[i + 1], last);
          s += last;
        }
      }
      _sink += s;
    },
    'delaunay.neighbors_1000': (n) {
      var s = 0;
      for (var k = 0; k < n; ++k) {
        for (var i = 0; i < 1000; ++i) {
          for (final nb in d1000.neighbors(i)) {
            s += nb;
          }
        }
      }
      _sink += s;
    },
    'voronoi.build_1000': (n) {
      var s = 0.0;
      for (var k = 0; k < n; ++k) {
        final v = d1000.voronoi((0, 0, 1000, 1000));
        s += v.circumcenters[0];
      }
      _sink += s;
    },
    'voronoi.update_1000': (n) {
      var s = 0.0;
      final pts = updVoronoi.delaunay.points;
      for (var k = 0; k < n; ++k) {
        final delta = k.isEven ? 0.25 : -0.25;
        for (var i = 0; i < 200; i += 2) {
          pts[i] += delta;
        }
        updVoronoi.update();
        s += updVoronoi.circumcenters[0];
      }
      _sink += s;
    },
    'voronoi.cellPolygons_1000': (n) {
      var s = 0;
      for (var k = 0; k < n; ++k) {
        for (var i = 0; i < 1000; ++i) {
          final poly = v1000.cellPolygon(i);
          if (poly != null) s += poly.length;
        }
      }
      _sink += s;
    },
    'voronoi.renderSvg_1000': (n) {
      var s = 0;
      for (var k = 0; k < n; ++k) {
        final svg = v1000.renderToSvg();
        if (svg != null) s += svg.length;
      }
      _sink += s;
    },
    'voronoi.renderCanvas_1000': (n) {
      final ctx = _CountingCanvasPath();
      for (var k = 0; k < n; ++k) {
        v1000.render(ctx);
        d1000.render(ctx);
      }
      _sink += ctx.acc;
    },
  };

  final lines = <String>[];
  final sw = Stopwatch()..start();
  final targetUs = batchMs * 250;

  for (final entry in cases.entries) {
    if (filter.isNotEmpty && !entry.key.contains(filter)) continue;
    final fn = entry.value;

    var ops = 1;
    final warmEnd = sw.elapsedMicroseconds + warmMs * 1000;
    while (sw.elapsedMicroseconds < warmEnd) {
      final t0 = sw.elapsedMicroseconds;
      fn(ops);
      final dt = sw.elapsedMicroseconds - t0;
      if (dt < targetUs) {
        ops *= 2;
      }
    }

    final samples = <double>[];
    for (var b = 0; b < batches; b++) {
      final t0 = sw.elapsedMicroseconds;
      fn(ops);
      final dt = sw.elapsedMicroseconds - t0;
      samples.add(dt * 1000.0 / ops);
    }
    samples.sort();
    final median = samples[samples.length >> 1];
    final line =
        'BENCH {"target":"$target","case":"${entry.key}", '
        '"ns":${median.toStringAsFixed(2)},"ops":$ops}';
    lines.add(line);
  }
  if (_sink == -123456789) print(_sink);
  return lines;
}

void main(List<String> args) {
  var target = 'dart';
  var filter = '';
  var batches = 9;
  var batchMs = 60;
  var warmMs = 300;
  for (final arg in args) {
    if (arg.startsWith('--target=')) {
      target = arg.substring('--target='.length);
    } else if (arg.startsWith('--filter=')) {
      filter = arg.substring('--filter='.length);
    } else if (arg.startsWith('--batches=')) {
      batches = int.parse(arg.substring('--batches='.length));
    } else if (arg.startsWith('--batch-ms=')) {
      batchMs = int.parse(arg.substring('--batch-ms='.length));
    } else if (arg.startsWith('--warm-ms=')) {
      warmMs = int.parse(arg.substring('--warm-ms='.length));
    }
  }
  runBenchmarks(
    target: target,
    filter: filter,
    batches: batches,
    batchMs: batchMs,
    warmMs: warmMs,
  ).forEach(print);
}
