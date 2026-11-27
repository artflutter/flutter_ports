// Original code, not ported from d3-quadtree: the benchmark of the port.

/// The d3-quadtree benchmark of the Dart port: 14 seeded workloads matching
/// `d3_quadtree_bench.mjs` (upstream d3-quadtree v3.0.1 in Node.js) with
/// identical Park-Miller LCG inputs.
///
/// Run as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android, and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';

/// Park-Miller LCG: exact in JS numbers and Dart.
final class Lcg(var int seed) {
  /// Creates an LCG with [seed].
  this;

  /// Next double in `[0, 1)`.
  double nextDouble() {
    seed = seed * 48271 % 2147483647;
    return seed / 2147483647.0;
  }
}

/// Custom typed datum for non-default accessor benchmarks.
typedef BenchNode = ({double x, double y, int id});

/// Seeded benchmark datasets.
final class BenchFixtures._({
  required final List<(double, double)> uniform1000,
  required final List<(double, double)> uniform5000,
  required final List<(double, double)> clustered2000,
  required final List<BenchNode> custom1000,
  required final List<(double, double)> updateA,
  required final List<(double, double)> updateB,
  required final List<(double, double, double)> findQueries256,
  required final List<(double, double, double, double)> rangeBoxes64,
}) {
  factory() {
    final r = Lcg(42);
    List<(double, double)> makeUniform(int n) =>
        List<(double, double)>.generate(
          n,
          (_) => (r.nextDouble() * 1000.0, r.nextDouble() * 1000.0),
          growable: false,
        );

    final uniform1000 = makeUniform(1000);
    final uniform5000 = makeUniform(5000);

    // 5 Gaussian clusters via Box-Muller using the seeded LCG.
    const centers = <(double, double)>[
      (200, 220),
      (780, 240),
      (500, 500),
      (260, 760),
      (760, 780),
    ];
    final clustered2000 = List<(double, double)>.generate(2000, (i) {
      final (cx, cy) = centers[i % centers.length];
      final u1 = math.max(1e-9, r.nextDouble());
      final u2 = r.nextDouble();
      final mag = math.sqrt(-2.0 * math.log(u1)) * 55.0;
      final ang = 2.0 * math.pi * u2;
      return (cx + mag * math.cos(ang), cy + mag * math.sin(ang));
    }, growable: false);

    final custom1000 = List<BenchNode>.generate(
      1000,
      (i) => (x: uniform1000[i].$1, y: uniform1000[i].$2, id: i),
      growable: false,
    );

    final updateA = List<(double, double)>.generate(
      250,
      (i) => uniform1000[i],
      growable: false,
    );
    final updateB = List<(double, double)>.generate(
      250,
      (i) => (
        updateA[i].$1 + (r.nextDouble() - 0.5) * 20.0,
        updateA[i].$2 + (r.nextDouble() - 0.5) * 20.0,
      ),
      growable: false,
    );

    final findQueries256 = List<(double, double, double)>.generate(
      256,
      (_) => (
        r.nextDouble() * 1000.0,
        r.nextDouble() * 1000.0,
        10.0 + r.nextDouble() * 45.0,
      ),
      growable: false,
    );

    final rangeBoxes64 = List<(double, double, double, double)>.generate(64, (
      _,
    ) {
      final x0 = r.nextDouble() * 820.0;
      final y0 = r.nextDouble() * 820.0;
      final w = 40.0 + r.nextDouble() * 140.0;
      final h = 40.0 + r.nextDouble() * 140.0;
      return (x0, y0, x0 + w, y0 + h);
    }, growable: false);

    return BenchFixtures._(
      uniform1000: uniform1000,
      uniform5000: uniform5000,
      clustered2000: clustered2000,
      custom1000: custom1000,
      updateA: updateA,
      updateB: updateB,
      findQueries256: findQueries256,
      rangeBoxes64: rangeBoxes64,
    );
  }
}

double _sink = 0;

/// Runs all 14 d3-quadtree benchmark cases and returns `BENCH {json}` lines.
List<String> runBenchmarks({
  String target = 'dart',
  String filter = '',
  int batches = 9,
  int batchMs = 60,
  int warmMs = 300,
}) {
  final f = BenchFixtures();
  final tree5000 = quadtree()
    ..setExtent(((0, 0), (1000, 1000)))
    ..addAll(f.uniform5000);
  final treeClustered = quadtree(f.clustered2000);
  final treeCustom = quadtreeBy<BenchNode>(
    x: (d) => d.x,
    y: (d) => d.y,
    data: f.custom1000,
  );
  final treeUpdate = quadtree()
    ..setExtent(((0, 0), (1000, 1000)))
    ..addAll(f.uniform1000);

  final cases = <String, void Function(int)>{
    'addAll.uniform_1000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final q = quadtree()
          ..setExtent(((0, 0), (1000, 1000)))
          ..addAll(f.uniform1000);
        s += q.extent!.$2.$1;
      }
      _sink += s;
    },
    'addAll.uniform_5000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final q = quadtree()
          ..setExtent(((0, 0), (1000, 1000)))
          ..addAll(f.uniform5000);
        s += q.extent!.$2.$1;
      }
      _sink += s;
    },
    'addAll.clustered_2000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final q = quadtree(f.clustered2000);
        s += q.extent!.$2.$1;
      }
      _sink += s;
    },
    'addAll.custom_1000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final q = quadtreeBy<BenchNode>(
          x: (d) => d.x,
          y: (d) => d.y,
          data: f.custom1000,
        );
        s += q.extent!.$2.$1;
      }
      _sink += s;
    },
    'add.incremental_1000': (n) {
      var s = 0.0;
      final pts = f.uniform1000;
      for (var i = 0; i < n; ++i) {
        final q = quadtree();
        for (var j = 0; j < pts.length; ++j) {
          q.add(pts[j]);
        }
        s += q.extent!.$2.$1;
      }
      _sink += s;
    },
    'find.unbounded_256': (n) {
      var s = 0.0;
      final qs = f.findQueries256;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < qs.length; ++j) {
          final (qx, qy, _) = qs[j];
          final hit = tree5000.find(qx, qy);
          if (hit != null) s += hit.$1 + hit.$2;
        }
      }
      _sink += s;
    },
    'find.radius_256': (n) {
      var s = 0.0;
      final qs = f.findQueries256;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < qs.length; ++j) {
          final (qx, qy, rad) = qs[j];
          final hit = tree5000.find(qx, qy, rad);
          if (hit != null) s += hit.$1 + hit.$2;
        }
      }
      _sink += s;
    },
    'find.custom_256': (n) {
      var s = 0.0;
      final qs = f.findQueries256;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < qs.length; ++j) {
          final (qx, qy, _) = qs[j];
          final hit = treeCustom.find(qx, qy);
          if (hit != null) s += hit.x + hit.y;
        }
      }
      _sink += s;
    },
    'visit.full_5000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        tree5000.visit((_, x0, y0, x1, y1) {
          s += x1 - x0 + y1 - y0;
          return false;
        });
      }
      _sink += s;
    },
    'visit.range_64': (n) {
      var s = 0.0;
      final boxes = f.rangeBoxes64;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < boxes.length; ++j) {
          final (rx0, ry0, rx1, ry1) = boxes[j];
          tree5000.visit((node, x0, y0, x1, y1) {
            if (node is QuadtreeLeafNode<(double, double)>) {
              QuadtreeLeafNode<(double, double)>? leaf = node;
              while (leaf != null) {
                final (px, py) = leaf.data;
                if (px >= rx0 && px < rx1 && py >= ry0 && py < ry1) {
                  s += px + py;
                }
                leaf = leaf.next;
              }
            }
            return x0 >= rx1 || y0 >= ry1 || x1 < rx0 || y1 < ry0;
          });
        }
      }
      _sink += s;
    },
    'visitAfter.full_5000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        tree5000.visitAfter((_, x0, y0, x1, y1) {
          s += x1 - x0 + y1 - y0;
        });
      }
      _sink += s;
    },
    'copy.tree_2000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final c = treeClustered.copy();
        s += c.extent!.$2.$1;
      }
      _sink += s;
    },
    'update.remove_add_500': (n) {
      var s = 0.0;
      final a = f.updateA;
      final b = f.updateB;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < a.length; ++j) {
          treeUpdate
            ..remove(a[j])
            ..add(b[j]);
        }
        for (var j = 0; j < a.length; ++j) {
          treeUpdate
            ..remove(b[j])
            ..add(a[j]);
        }
        s += treeUpdate.extent!.$2.$1;
      }
      _sink += s;
    },
    'data_size.5000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        final d = tree5000.data();
        s += d.length + tree5000.size();
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

    var ops = 4;
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
