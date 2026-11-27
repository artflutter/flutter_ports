// Original code, not ported from d3-chord: the benchmark of the port.

/// The d3-chord benchmark of the Dart port: 12 seeded workloads matching
/// `d3_chord_bench.mjs` (upstream d3-chord v3.0.1 in Node.js) with identical
/// Park-Miller LCG inputs.
///
/// Run as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android, and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'package:flutter_d3_chord_port/d3_chord.dart';
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
final class ChordBenchFixtures._({
  /// Classic 4x4 Circos matrix.
  required final List<List<double>> matrix4,

  /// Dense 16x16 matrix.
  required final List<List<double>> matrix16,

  /// Sparse 16x16 directed matrix (~70% non-zero).
  required final List<List<double>> sparse16,

  /// Dense 32x32 matrix.
  required final List<List<double>> matrix32,

  /// Precomputed undirected 16x16 chords (136 chords).
  required final Chords chords16,

  /// Precomputed directed 16x16 chords (~180 chords).
  required final Chords directed16,
}) {
  /// Builds the deterministic seeded fixtures.
  factory() {
    const m4 = <List<double>>[
      [11975, 5871, 8916, 2868],
      [1951, 10048, 2060, 6171],
      [8010, 16145, 8090, 8045],
      [1013, 990, 940, 6907],
    ];
    final r = Lcg(42);
    List<List<double>> makeMatrix(int n, {double zeroProb = 0}) =>
        List<List<double>>.generate(
          n,
          (_) => List<double>.generate(n, (_) {
            final u = r.nextDouble();
            if (zeroProb > 0 && u < zeroProb) return 0;
            return (10 + r.nextDouble() * 990).floorToDouble();
          }, growable: false),
          growable: false,
        );
    final m16 = makeMatrix(16);
    final s16 = makeMatrix(16, zeroProb: 0.3);
    final m32 = makeMatrix(32);
    final c16 = chord(padAngle: 0.03)(m16);
    final d16 = chordDirected(padAngle: 0.03)(s16);
    return ChordBenchFixtures._(
      matrix4: m4,
      matrix16: m16,
      sparse16: s16,
      matrix32: m32,
      chords16: c16,
      directed16: d16,
    );
  }
}

double _sink = 0;

int _eatText(String s) => s.length + s.codeUnitAt(s.length - 1);

/// Runs all 12 d3-chord benchmark cases and returns `BENCH {json}` lines.
List<String> runBenchmarks({
  String target = 'dart',
  String filter = '',
  int batches = 9,
  int batchMs = 60,
  int warmMs = 250,
}) {
  final f = ChordBenchFixtures();
  double desc(double a, double b) => b - a;
  double asc(double a, double b) => a - b;

  final chordPlain = chord(padAngle: 0.04);
  final chordSorted = chord(
    padAngle: 0.04,
    sortGroups: desc,
    sortSubgroups: desc,
    sortChords: desc,
  );
  final chordDir = chordDirected(padAngle: 0.04);
  final chordDirSorted = chordDirected(
    padAngle: 0.04,
    sortGroups: desc,
    sortSubgroups: desc,
    sortChords: asc,
  );
  final chordTrans = chordTranspose(padAngle: 0.04);

  final ribSvg = ribbon(radius: 240);
  final ribPadded = ribbon(
    sourceRadius: 240,
    targetRadius: 225,
    padAngle: 0.01,
  );
  final ribArrowSvg = ribbonArrow(
    sourceRadius: 240,
    targetRadius: 230,
    headRadius: 12,
  );
  final canvasSink = BenchCanvasSink();

  final cases = <String, void Function(int)>{
    'chord.4x4': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final res = chordPlain(f.matrix4);
        s += res.length + res.groups[0].endAngle;
      }
      _sink += s;
    },
    'chord.16x16': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final res = chordPlain(f.matrix16);
        s += res.length + res.groups[0].endAngle;
      }
      _sink += s;
    },
    'chord.32x32': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final res = chordPlain(f.matrix32);
        s += res.length + res.groups[0].endAngle;
      }
      _sink += s;
    },
    'chord.32x32_sorted': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final res = chordSorted(f.matrix32);
        s += res.length + res.groups[0].endAngle;
      }
      _sink += s;
    },
    'chordDirected.16x16': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final res = chordDir(f.sparse16);
        s += res.length + res.groups[0].endAngle;
      }
      _sink += s;
    },
    'chordDirected.32x32_sorted': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final res = chordDirSorted(f.matrix32);
        s += res.length + res.groups[0].endAngle;
      }
      _sink += s;
    },
    'chordTranspose.16x16': (n) {
      var s = 0.0;
      for (var i = 0; i < n; ++i) {
        final res = chordTrans(f.matrix16);
        s += res.length + res.groups[0].endAngle;
      }
      _sink += s;
    },
    'ribbon.svg_136': (n) {
      var s = 0;
      final list = f.chords16;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < list.length; ++j) {
          s += _eatText(ribSvg(list[j])!);
        }
      }
      _sink += s;
    },
    'ribbon.padded_136': (n) {
      var s = 0;
      final list = f.chords16;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < list.length; ++j) {
          s += _eatText(ribPadded(list[j])!);
        }
      }
      _sink += s;
    },
    'ribbonArrow.svg_180': (n) {
      var s = 0;
      final list = f.directed16;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < list.length; ++j) {
          s += _eatText(ribArrowSvg(list[j])!);
        }
      }
      _sink += s;
    },
    'ribbon.canvas_136': (n) {
      final list = f.chords16;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < list.length; ++j) {
          ribSvg.draw(list[j], canvasSink);
        }
      }
      _sink += canvasSink.acc;
      canvasSink.acc = 0;
    },
    'ribbonArrow.canvas_180': (n) {
      final list = f.directed16;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < list.length; ++j) {
          ribArrowSvg.draw(list[j], canvasSink);
        }
      }
      _sink += canvasSink.acc;
      canvasSink.acc = 0;
    },
  };

  final out = <String>[];
  for (final entry in cases.entries) {
    final name = entry.key;
    if (filter.isNotEmpty && !name.contains(filter)) continue;
    final fn = entry.value;

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
