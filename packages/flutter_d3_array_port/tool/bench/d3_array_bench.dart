// Original code, not ported from d3-array: the benchmark of the port.

/// The d3-array benchmark of the Dart port: 20 seeded workloads matching
/// `d3_array_bench.mjs` (upstream d3-array v3.2.4 in Node.js) with identical
/// Park-Miller LCG inputs.
///
/// Run as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android, and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';

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

/// Keyed record used for grouping and rollup benchmarks.
typedef BenchRow = ({String region, String category, double amount});

/// Seeded benchmark datasets.
final class BenchFixtures._({
  required final Float64List f64_1024,
  required final List<double> list1024,
  required final Float64List sorted1024,
  required final Float64List queries64,
  required final Float64List f64_512,
  required final Float64List grid64x64,
  required final List<(double, double, double)> tickDomains32,
  required final List<BenchRow> rows512,
  required final List<int> ints1024,
}) {
  factory() {
    final r = Lcg(42);
    final f64_1024 = Float64List(1024);
    final list1024 = List<double>.filled(1024, 0);
    for (var i = 0; i < 1024; ++i) {
      final v = (r.nextDouble() - 0.35) * 2000.0;
      f64_1024[i] = v;
      list1024[i] = v;
    }
    final sorted1024 = Float64List.fromList(f64_1024)..sort();
    final queries64 = Float64List(64);
    for (var i = 0; i < 64; ++i) {
      queries64[i] = (r.nextDouble() - 0.35) * 2100.0;
    }
    final f64_512 = Float64List(512);
    for (var i = 0; i < 512; ++i) {
      f64_512[i] = (r.nextDouble() * 100.0).roundToDouble();
    }
    final grid64x64 = Float64List(64 * 64);
    for (var i = 0; i < grid64x64.length; ++i) {
      grid64x64[i] = r.nextDouble() * 255.0;
    }
    final tickDomains32 = List<(double, double, double)>.generate(32, (i) {
      final lo = (r.nextDouble() - 0.5) * 1000.0;
      final span = 0.01 + r.nextDouble() * 5000.0;
      final cnt = 3.0 + (i % 10);
      return (lo, lo + span, cnt);
    }, growable: false);
    const regions = <String>['North', 'South', 'East', 'West', 'Central'];
    const cats = <String>['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final rows512 = List<BenchRow>.generate(512, (i) {
      final reg = regions[(r.nextDouble() * regions.length).floor()];
      final cat = cats[(r.nextDouble() * cats.length).floor()];
      final amt = r.nextDouble() * 1000.0;
      return (region: reg, category: cat, amount: amt);
    }, growable: false);
    final ints1024 = List<int>.generate(1024, (i) => i, growable: false);
    return BenchFixtures._(
      f64_1024: f64_1024,
      list1024: list1024,
      sorted1024: sorted1024,
      queries64: queries64,
      f64_512: f64_512,
      grid64x64: grid64x64,
      tickDomains32: tickDomains32,
      rows512: rows512,
      ints1024: ints1024,
    );
  }
}

double _sink = 0;

/// Runs all 20 d3-array benchmark cases and returns `BENCH {json}` lines.
List<String> runBenchmarks({
  String target = 'dart',
  String filter = '',
  int batches = 9,
  int batchMs = 60,
  int warmMs = 300,
}) {
  final f = BenchFixtures();
  final qsBuf = Float64List(1024);
  final blurBuf = Float64List(1024);
  final gridBuf = Float64List(64 * 64);
  final gridData = Blur2Data(data: gridBuf, width: 64, height: 64);
  final shufBuf = List<int>.of(f.ints1024);
  final binSturges = bin<double>();
  final binFD = bin<double>(thresholdsCount: thresholdFreedmanDiaconis);
  final shuffleRng = Lcg(1337);
  final shuf = shuffler(shuffleRng.nextDouble);

  final cases = <String, void Function(int)>{
    'sum.f64_1024': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        s += sum(f.f64_1024);
      }
      _sink += s;
    },
    'fsum.f64_1024': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        s += fsum(f.f64_1024);
      }
      _sink += s;
    },
    'minmax.f64_1024': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final lo = min(f.f64_1024)!;
        final hi = max(f.f64_1024)!;
        final ext = extent(f.f64_1024)!;
        s += lo + hi + ext.$1 + ext.$2;
      }
      _sink += s;
    },
    'mean.f64_1024': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        s += mean(f.f64_1024)!;
      }
      _sink += s;
    },
    'variance.f64_1024': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        s += variance(f.f64_1024)! + deviation(f.f64_1024)!;
      }
      _sink += s;
    },
    'cumsum.f64_1024': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final out = cumsum(f.f64_1024);
        s += out[1023];
      }
      _sink += s;
    },
    'quickselect.f64_1024': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        qsBuf.setAll(0, f.f64_1024);
        quickselect(qsBuf, 512);
        s += qsBuf[512];
      }
      _sink += s;
    },
    'quantile.f64_1024': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        s +=
            quantile(f.f64_1024, 0.25)! +
            quantile(f.f64_1024, 0.5)! +
            quantile(f.f64_1024, 0.75)!;
      }
      _sink += s;
    },
    'bisect.f64_1024': (n) {
      var s = 0;
      final arr = f.sorted1024;
      final qs = f.queries64;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 64; ++j) {
          final q = qs[j];
          s += bisectLeft(arr, q) + bisectRight(arr, q) + bisectCenter(arr, q);
        }
      }
      _sink += s;
    },
    'bin.sturges_1024': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        final bins = binSturges(f.list1024);
        s += bins.length + bins[0].length;
      }
      _sink += s;
    },
    'bin.fd_1024': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        final bins = binFD(f.list1024);
        s += bins.length + bins[0].length;
      }
      _sink += s;
    },
    'ticks.batch32': (n) {
      var s = 0.0;
      final doms = f.tickDomains32;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 32; ++j) {
          final (lo, hi, cnt) = doms[j];
          final t = ticks(lo, hi, cnt);
          final nc = nice(lo, hi, cnt);
          s += t.length + nc.$1 + nc.$2;
        }
      }
      _sink += s;
    },
    'range.1024': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final a = range(0, 1024, 1);
        final b = range(0, 10, 0.05);
        s += a[1023] + b[b.length - 1];
      }
      _sink += s;
    },
    'blur1.1024_r3': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        blurBuf.setAll(0, f.f64_1024);
        blur(blurBuf, 3);
        s += blurBuf[512];
      }
      _sink += s;
    },
    'blur1.1024_r2_5': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        blurBuf.setAll(0, f.f64_1024);
        blur(blurBuf, 2.5);
        s += blurBuf[512];
      }
      _sink += s;
    },
    'blur2.64x64_r2': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        gridBuf.setAll(0, f.grid64x64);
        blur2(gridData, 2);
        s += gridBuf[2080];
      }
      _sink += s;
    },
    'sort.f64_1024': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final out = sort(f.f64_1024);
        s += out[0] + out[1023];
      }
      _sink += s;
    },
    'rank.f64_512': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final out = rank(f.f64_512);
        s += out[0] + out[511];
      }
      _sink += s;
    },
    'group.rollup_512': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final g = group(f.rows512, (r) => r.region);
        final r = rollup<BenchRow, String, double>(
          f.rows512,
          (rows) => sumBy(rows, (x) => x.amount),
          (x) => x.category,
        );
        s += g.length + (r['A'] ?? 0);
      }
      _sink += s;
    },
    'shuffle.1024': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        shuf(shufBuf);
        s += shufBuf[0];
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
