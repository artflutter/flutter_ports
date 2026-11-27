// Original code, not ported from d3-hierarchy: the benchmark of the port.

/// The d3-hierarchy benchmark of the Dart port: 17 seeded workloads matching
/// `d3_hierarchy_bench.mjs` (upstream d3-hierarchy v3.1.2 in Node.js) with
/// identical Park-Miller LCG inputs.
///
/// Run as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android, and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';

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

/// Nested tree datum for hierarchy and layout benchmarks.
final class BenchNode({
  required final int id,
  required final double size,
  @override final List<BenchNode>? children,
}) implements HierarchyDatum<BenchNode> {
  /// Creates a benchmark tree node.
  this;
}

/// Flat row datum for stratify benchmarks.
final class const BenchRow({
  @override required final String id,
  required final String path,
  required final double size,
  @override final String? parentId,
}) implements StratifyDatum;

({BenchNode nested, List<BenchRow> rows, List<String> leafPaths}) _generateTree(
  int count,
  int seed,
) {
  final r = Lcg(seed);
  final nodes = <BenchNode>[];
  final childLists = List<List<BenchNode>>.generate(
    count,
    (_) => <BenchNode>[],
  );
  final parentIds = List<int>.filled(count, -1);
  final paths = List<String>.filled(count, '');
  final sizes = List<double>.filled(count, 0);

  paths[0] = '/n0';
  for (var i = 1; i < count; ++i) {
    // Skewed branching factor: parents come from earlier internal pool.
    final pool = (i * 0.35).floor();
    final p = pool > 0 ? (r.nextDouble() * (pool + 1)).floor() : 0;
    parentIds[i] = p;
    paths[i] = '${paths[p]}/n$i';
  }
  final isParent = List<bool>.filled(count, false);
  for (var i = 1; i < count; ++i) {
    isParent[parentIds[i]] = true;
  }
  for (var i = 0; i < count; ++i) {
    sizes[i] = isParent[i] ? 0.0 : (10.0 + (r.nextDouble() * 5000.0).floor());
  }
  for (var i = count - 1; i >= 0; --i) {
    final kids = childLists[i];
    final node = BenchNode(
      id: i,
      size: sizes[i],
      children: kids.isEmpty ? null : kids,
    );
    if (nodes.length < count) {
      // Fill after loop
    }
    if (i > 0) {
      childLists[parentIds[i]].add(node);
    } else {
      nodes.add(node);
    }
  }
  final rows = List<BenchRow>.generate(
    count,
    (i) => BenchRow(
      id: 'n$i',
      parentId: i == 0 ? null : 'n${parentIds[i]}',
      path: paths[i],
      size: sizes[i],
    ),
    growable: false,
  );
  final leafPaths = <String>[
    for (var i = 0; i < count; ++i)
      if (!isParent[i]) paths[i],
  ];
  return (nested: nodes.first, rows: rows, leafPaths: leafPaths);
}

double _sink = 0;

/// Runs all 17 d3-hierarchy benchmark cases and returns `BENCH {json}` lines.
List<String> runBenchmarks({
  String target = 'dart',
  String filter = '',
  int batches = 9,
  int batchMs = 60,
  int warmMs = 250,
}) {
  final t252 = _generateTree(252, 42);
  final t1000 = _generateTree(1000, 1337);

  final h1000 = hierarchy(t1000.nested)
    ..sum((d) => d.size)
    ..sort((a, b) => (b.value ?? 0) - (a.value ?? 0));
  final h1000Unsorted = hierarchy(t1000.nested)..sum((d) => d.size);

  final h252 = hierarchy(t252.nested)
    ..sum((d) => d.size)
    ..sort((a, b) => (b.value ?? 0) - (a.value ?? 0));

  final rect252Squarify = hierarchyToRectangular(h252.copy());
  final rect252Binary = hierarchyToRectangular(h252.copy());
  final rect252Resquarify = hierarchyToRectangular(h252.copy());
  final rect252Partition = hierarchyToRectangular(h252.copy());
  final circ252Pack = hierarchyToCircular(h252.copy());
  final point252Tree = hierarchyToPoint(h252.copy());
  final point252Cluster = hierarchyToPoint(h252.copy());

  final stratId = stratify<BenchRow>();
  final stratPath = stratify<String>(path: (d) => d);

  final tmSquarify = treemap<BenchNode>(
    size: (960, 500),
    paddingInnerConst: 1,
    paddingTopConst: 12,
  );
  final tmBinary = treemap<BenchNode>(
    tile: treemapBinary,
    size: (960, 500),
    paddingInnerConst: 1,
  );
  final tmResquarify = treemap<BenchNode>(
    tile: treemapResquarify.call,
    size: (960, 500),
  );
  final partLayout = partition<BenchNode>(size: (960, 500), padding: 1);
  final packLayout = pack<BenchNode>(size: (960, 960), paddingConst: 3);
  final treeLayout = tree<BenchNode>(size: (960, 500));
  final clusterLayout = cluster<BenchNode>(size: (960, 500));

  final rng = Lcg(999);
  final radii64 = List<double>.generate(
    64,
    (_) => 2.0 + rng.nextDouble() * 48.0,
    growable: false,
  );
  final sibCircles = List<PackCircle>.generate(
    64,
    (i) => PackCircle(r: radii64[i]),
    growable: false,
  );

  final cases = <String, void Function(int)>{
    'hierarchy.build_252': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final r = hierarchy(t252.nested);
        s += r.height;
      }
      _sink += s;
    },
    'stratify.id_252': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final r = stratId(t252.rows);
        s += r.height;
      }
      _sink += s;
    },
    'stratify.path_252': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final r = stratPath.callPath(t252.leafPaths);
        s += r.height;
      }
      _sink += s;
    },
    'traverse.eachBefore_1k': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        h1000.eachBefore((node) => s += node.depth);
      }
      _sink += s;
    },
    'traverse.eachAfter_1k': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        h1000.eachAfter((node) => s += node.height);
      }
      _sink += s;
    },
    'traverse.bfs_each_1k': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        h1000.each((node) => s += node.depth);
      }
      _sink += s;
    },
    'traverse.desc_leaves_1k': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        s += h1000.descendants().length + h1000.leaves().length;
      }
      _sink += s;
    },
    'aggregate.sum_count_1k': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        h1000.sum((d) => d.size);
        s += h1000.value!;
        h1000.count();
        s += h1000.value!;
      }
      _sink += s;
    },
    'aggregate.sort_1k': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        h1000Unsorted
          ..sort((a, b) => (b.value ?? 0) - (a.value ?? 0))
          ..sort((a, b) => (a.value ?? 0) - (b.value ?? 0));
        s += h1000Unsorted.children!.first.value!;
      }
      _sink += s;
    },
    'treemap.squarify_252': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final r = tmSquarify(rect252Squarify);
        s += r.x1 + r.y1;
      }
      _sink += s;
    },
    'treemap.binary_252': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final r = tmBinary(rect252Binary);
        s += r.x1 + r.y1;
      }
      _sink += s;
    },
    'treemap.resquarify_252': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        rect252Resquarify.resquarifyCache = null;
        tmResquarify
          ..size = (960, 500)
          ..call(rect252Resquarify)
          ..size = (800, 600)
          ..call(rect252Resquarify)
          ..size = (600, 800)
          ..call(rect252Resquarify)
          ..size = (500, 960)
          ..call(rect252Resquarify);
        s += rect252Resquarify.x1;
      }
      _sink += s;
    },
    'partition.252': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final r = partLayout(rect252Partition);
        s += r.x1 + r.y1;
      }
      _sink += s;
    },
    'pack.252': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final r = packLayout(circ252Pack);
        s += r.r;
      }
      _sink += s;
    },
    'packSiblings.64': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 64; ++j) {
          sibCircles[j].r = radii64[j];
        }
        packSiblings(sibCircles);
        final enc = packEnclose(sibCircles)!;
        s += enc.r;
      }
      _sink += s;
    },
    'tree.252': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final r = treeLayout(point252Tree);
        s += r.x + r.y;
      }
      _sink += s;
    },
    'cluster.252': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final r = clusterLayout(point252Cluster);
        s += r.x + r.y;
      }
      _sink += s;
    },
  };

  final out = <String>[];
  for (final entry in cases.entries) {
    final name = entry.key;
    if (filter.isNotEmpty && !name.contains(filter)) continue;
    final fn = entry.value;

    // Warmup & calibrate iterations per batch.
    var iters = 1;
    final warmSw = Stopwatch()..start();
    while (warmSw.elapsedMilliseconds < warmMs) {
      fn(iters);
      if (warmSw.elapsedMilliseconds < 20) iters *= 2;
    }
    var probe = 1;
    while (true) {
      final sw = Stopwatch()..start();
      fn(probe);
      sw.stop();
      if (sw.elapsedMilliseconds >= batchMs || probe >= 1 << 24) break;
      probe = sw.elapsedMilliseconds == 0
          ? probe * 8
          : ((probe * batchMs) / sw.elapsedMilliseconds).ceil().clamp(
              probe + 1,
              probe * 8,
            );
    }

    final samples = <double>[];
    for (var b = 0; b < batches; ++b) {
      final sw = Stopwatch()..start();
      fn(probe);
      sw.stop();
      samples.add(sw.elapsedMicroseconds * 1000.0 / probe);
    }
    samples.sort();
    final median = samples[samples.length ~/ 2];
    final line =
        'BENCH {"target":"$target","case":"$name", '
        '"ns_op":${median.toStringAsFixed(1)},"iters":$probe}';
    out.add(line);
    print(line);
  }
  if (_sink == -1.23456789) print(_sink);
  return out;
}

void main(List<String> args) {
  var target = 'dart';
  var filter = '';
  for (var i = 0; i < args.length; ++i) {
    if (args[i] == '--target' && i + 1 < args.length) {
      target = args[++i];
    } else if (args[i] == '--filter' && i + 1 < args.length) {
      filter = args[++i];
    }
  }
  runBenchmarks(target: target, filter: filter);
}
