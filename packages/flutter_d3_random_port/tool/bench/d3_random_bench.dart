// Original code, not ported from d3-random: the benchmark of the port.

/// The d3-random benchmark of the Dart port: 16 seeded workloads matching
/// `d3_random_bench.mjs` (upstream d3-random v3.0.1 in Node.js).
///
/// Run as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android, and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter_d3_random_port/d3_random.dart';

double _sink = 0;

/// Runs all 16 d3-random benchmark cases and returns `BENCH {json}` lines.
List<String> runBenchmarks({
  String target = 'dart',
  String filter = '',
  int batches = 9,
  int batchMs = 60,
  int warmMs = 300,
}) {
  final lcg = randomLcg(0.42);
  final uniform = randomUniform.source(randomLcg(0.42))(-5, 10);
  final randInt = randomInt.source(randomLcg(0.42))(10, 42);
  final normal = randomNormal.source(randomLcg(0.42))(100, 15);
  final logNormal = randomLogNormal.source(randomLcg(0.42))(1.5, 0.5);
  final bates = randomBates.source(randomLcg(0.42))(10);
  final exponential = randomExponential.source(randomLcg(0.42))(0.25);
  final pareto = randomPareto.source(randomLcg(0.42))(3);
  final bernoulli = randomBernoulli.source(randomLcg(0.42))(0.35);
  final geometric = randomGeometric.source(randomLcg(0.42))(0.25);
  final gamma = randomGamma.source(randomLcg(0.42))(5, 1.5);
  final beta = randomBeta.source(randomLcg(0.42))(2.7, 0.3);
  final weibull = randomWeibull.source(randomLcg(0.42))(3, 1, 2);
  final binomial = randomBinomial.source(randomLcg(0.42))(200, 0.37);
  final poisson = randomPoisson.source(randomLcg(0.42))(250);
  final normalFactory = randomNormal.source(randomLcg(0.42));
  final fillBuf = Float64List(10000);

  final cases = <String, void Function(int)>{
    'lcg.draw_10000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 10000; ++j) {
          s += lcg();
        }
      }
      _sink += s;
    },
    'uniform.draw_10000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 10000; ++j) {
          s += uniform();
        }
      }
      _sink += s;
    },
    'int.draw_10000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 10000; ++j) {
          s += randInt();
        }
      }
      _sink += s;
    },
    'normal.draw_10000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 10000; ++j) {
          s += normal();
        }
      }
      _sink += s;
    },
    'logNormal.draw_10000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 10000; ++j) {
          s += logNormal();
        }
      }
      _sink += s;
    },
    'bates.draw_10000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 10000; ++j) {
          s += bates();
        }
      }
      _sink += s;
    },
    'exponential.draw_10000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 10000; ++j) {
          s += exponential();
        }
      }
      _sink += s;
    },
    'pareto.draw_10000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 10000; ++j) {
          s += pareto();
        }
      }
      _sink += s;
    },
    'bernoulli.draw_10000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 10000; ++j) {
          s += bernoulli();
        }
      }
      _sink += s;
    },
    'geometric.draw_10000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 10000; ++j) {
          s += geometric();
        }
      }
      _sink += s;
    },
    'gamma.draw_10000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 10000; ++j) {
          s += gamma();
        }
      }
      _sink += s;
    },
    'beta.draw_10000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 10000; ++j) {
          s += beta();
        }
      }
      _sink += s;
    },
    'weibull.draw_10000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 10000; ++j) {
          s += weibull();
        }
      }
      _sink += s;
    },
    'binomial.draw_2000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 2000; ++j) {
          s += binomial();
        }
      }
      _sink += s;
    },
    'poisson.draw_2000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < 2000; ++j) {
          s += poisson();
        }
      }
      _sink += s;
    },
    'normal.fill_10000': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        normalFactory.fill(fillBuf, 100, 15);
        s += fillBuf[0] + fillBuf[9999];
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
