// Original code, not ported from d3-contour: the benchmark of the port.

/// The d3-contour benchmark of the Dart port: 12 seeded workloads matching
/// `d3_contour_bench.mjs` (upstream d3-contour v4.0.2 in Node.js) with
/// identical Park-Miller LCG inputs.
///
/// Run as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android, and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_contour_port/d3_contour.dart';

/// Park-Miller LCG: exact in JS numbers and Dart.
final class Lcg(var int seed) {
  /// Next double in `[0, 1)`.
  double nextDouble() {
    seed = seed * 48271 % 2147483647;
    return seed / 2147483647.0;
  }

  /// Approximate standard normal via Box-Muller.
  double nextGaussian() {
    final u1 = math.max(1e-9, nextDouble());
    final u2 = nextDouble();
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
  }
}

Float64List _makePeaksGrid(int w, int h) {
  final out = Float64List(w * h);
  for (var y = 0; y < h; ++y) {
    final ny = y / h;
    for (var x = 0; x < w; ++x) {
      final nx = x / w;
      final dx1 = (nx - 0.30) / 0.16;
      final dy1 = (ny - 0.35) / 0.16;
      final dx2 = (nx - 0.68) / 0.20;
      final dy2 = (ny - 0.62) / 0.19;
      final dx3 = (nx - 0.66) / 0.08;
      final dy3 = (ny - 0.61) / 0.08;
      out[y * w + x] =
          100.0 * math.exp(-(dx1 * dx1 + dy1 * dy1)) +
          125.0 * math.exp(-(dx2 * dx2 + dy2 * dy2)) -
          70.0 * math.exp(-(dx3 * dx3 + dy3 * dy3)) +
          10.0 * math.sin(nx * 14.0) * math.cos(ny * 12.0);
    }
  }
  return out;
}

Float64List _makeHolesGrid(int w, int h) {
  final out = Float64List(w * h);
  for (var y = 0; y < h; ++y) {
    for (var x = 0; x < w; ++x) {
      final gx = (x % 16) - 7.5;
      final gy = (y % 16) - 7.5;
      final r = math.sqrt(gx * gx + gy * gy);
      // Concentric rings with inner holes in every 16x16 tile.
      out[y * w + x] = math.cos(r * 0.9) * 50.0 + 50.0;
    }
  }
  return out;
}

Float64List _makeGoldsteinGrid(int w, int h) {
  final out = Float64List(w * h);
  for (var j = 0; j < h; ++j) {
    final y = 1.0 - ((j + 0.5) / h) * 3.0;
    for (var i = 0; i < w; ++i) {
      final x = ((i + 0.5) / w) * 4.0 - 2.0;
      final a = x + y + 1.0;
      final b = 2.0 * x - 3.0 * y;
      out[j * w + i] =
          (1.0 +
              a *
                  a *
                  (19.0 -
                      14.0 * x +
                      3.0 * x * x -
                      14.0 * y +
                      6.0 * x * y +
                      3.0 * y * y)) *
          (30.0 +
              b *
                  b *
                  (18.0 -
                      32.0 * x +
                      12.0 * x * x +
                      48.0 * y -
                      36.0 * x * y +
                      27.0 * y * y));
    }
  }
  return out;
}

List<(double, double)> _makeClusters(int count, int seed) {
  final r = Lcg(seed);
  const centers = <(double, double, double, double)>[
    (190, 150, 42, 34),
    (430, 240, 56, 46),
    (320, 110, 32, 28),
  ];
  return List<(double, double)>.generate(count, (i) {
    final (cx, cy, sx, sy) = centers[i % centers.length];
    return (cx + r.nextGaussian() * sx, cy + r.nextGaussian() * sy);
  }, growable: false);
}

List<(double, double, double)> _makeWeightedClusters(int count, int seed) {
  final r = Lcg(seed);
  const centers = <(double, double, double, double)>[
    (190, 150, 42, 34),
    (430, 240, 56, 46),
    (320, 110, 32, 28),
  ];
  return List<(double, double, double)>.generate(count, (i) {
    final (cx, cy, sx, sy) = centers[i % centers.length];
    final w = i % 25 == 0
        ? double.nan
        : (i % 19 == 0 ? 0.0 : 0.5 + r.nextDouble() * 3.0);
    return (cx + r.nextGaussian() * sx, cy + r.nextGaussian() * sy, w);
  }, growable: false);
}

List<(double, double)> _makeFaithfulLike() {
  final r = Lcg(99);
  return List<(double, double)>.generate(272, (i) {
    if (i % 3 == 0) {
      return (220.0 + r.nextGaussian() * 55.0, 340.0 + r.nextGaussian() * 48.0);
    }
    return (680.0 + r.nextGaussian() * 72.0, 130.0 + r.nextGaussian() * 52.0);
  }, growable: false);
}

double _sink = 0;

int _checksumContours(List<ContourMultiPolygon> list) {
  var total = list.length;
  for (final c in list) {
    total += c.coordinates.length;
    for (final p in c.coordinates) {
      total += p.length;
      for (final r in p) {
        total += r.length;
      }
    }
  }
  return total;
}

/// Runs all 12 d3-contour benchmark cases and returns `BENCH {json}` lines.
List<String> runBenchmarks({
  String target = 'dart',
  String filter = '',
  int batches = 7,
  int batchMs = 60,
  int warmMs = 250,
}) {
  final peaks64 = _makePeaksGrid(64, 64);
  final peaks128 = _makePeaksGrid(128, 128);
  final holes64 = _makeHolesGrid(64, 64);
  final goldstein96 = _makeGoldsteinGrid(96, 96);
  final faithfulPts = _makeFaithfulLike();
  final clusters2000 = _makeClusters(2000, 42);
  final clusters10000 = _makeClusters(10000, 77);
  final weighted2000 = _makeWeightedClusters(2000, 123);

  final cPeaks64 = contours(size: (64, 64), thresholdsCount: 10);
  final cPeaks64Raw = contours(
    size: (64, 64),
    smooth: false,
    thresholdsCount: 10,
  );
  final cPeaks128 = contours(size: (128, 128), thresholdsCount: 10);
  final cSingle128 = contours(size: (128, 128));
  final cHoles64 = contours(
    size: (64, 64),
    thresholdsValues: const <double>[20, 40, 60, 80],
  );
  final cGoldstein96 = contours(
    size: (96, 96),
    thresholdsValues: List<double>.generate(
      12,
      (i) => math.pow(2, i + 2).toDouble(),
      growable: false,
    ),
  );

  final dFaithful = contourDensityPoints(bandwidth: 30, thresholdsCount: 20);
  final dClusters2000Cs4 = contourDensityPoints(
    size: (640, 400),
    bandwidth: 20,
    thresholdsCount: 12,
  );
  final dClusters2000Cs2 = contourDensityPoints(
    size: (640, 400),
    bandwidth: 20,
    cellSize: 2,
    thresholdsCount: 10,
  );
  final dClusters10000Cs4 = contourDensityPoints(
    size: (640, 400),
    bandwidth: 24,
    thresholdsCount: 10,
  );
  final dWeighted2000 = contourDensity<(double, double, double)>(
    x: (d) => d.$1,
    y: (d) => d.$2,
    weight: (d) => d.$3,
    size: (640, 400),
    bandwidth: 20,
    thresholdsCount: 10,
  );

  final cases = <String, void Function(int)>{
    'contours.peaks_64x64_10': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        s += _checksumContours(cPeaks64(peaks64));
      }
      _sink += s;
    },
    'contours.peaks_64x64_raw': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        s += _checksumContours(cPeaks64Raw(peaks64));
      }
      _sink += s;
    },
    'contours.peaks_128x128_10': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        s += _checksumContours(cPeaks128(peaks128));
      }
      _sink += s;
    },
    'contours.single_128x128': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        final mp = cSingle128.contour(peaks128, 55);
        s += mp.coordinates.length;
      }
      _sink += s;
    },
    'contours.holes_64x64': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        s += _checksumContours(cHoles64(holes64));
      }
      _sink += s;
    },
    'contours.goldstein_96x96_12': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        s += _checksumContours(cGoldstein96(goldstein96));
      }
      _sink += s;
    },
    'density.faithful_bw30': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        s += _checksumContours(dFaithful(faithfulPts));
      }
      _sink += s;
    },
    'density.clusters_2000_cs4': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        s += _checksumContours(dClusters2000Cs4(clusters2000));
      }
      _sink += s;
    },
    'density.clusters_2000_cs2': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        s += _checksumContours(dClusters2000Cs2(clusters2000));
      }
      _sink += s;
    },
    'density.clusters_10000_cs4': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        s += _checksumContours(dClusters10000Cs4(clusters10000));
      }
      _sink += s;
    },
    'density.weighted_2000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        s += _checksumContours(dWeighted2000(weighted2000));
      }
      _sink += s;
    },
    'density.contours_query5': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        final q = dClusters2000Cs4.contours(clusters2000);
        final mx = q.max;
        for (var k = 1; k <= 5; ++k) {
          s += q(mx * k / 6.0).coordinates.length;
        }
      }
      _sink += s;
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
  var batches = 7;
  var batchMs = 60;
  var warmMs = 250;
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
