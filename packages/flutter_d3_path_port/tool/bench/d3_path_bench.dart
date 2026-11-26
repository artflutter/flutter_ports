// Original code, not ported from d3-path: the benchmark of the port.

/// The d3-path benchmark of the Dart port: the cases of `d3_path_bench.mjs`
/// (upstream d3-path in Node.js) with the same seeded inputs.
///
/// Run as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_path_port/d3_path.dart';

/// Park-Miller LCG: exact in JS numbers and Dart.
final class Lcg(var int seed) {
  /// Creates an LCG with [seed].
  this;

  /// Next integer in `[0, n)`.
  int next(int n) {
    seed = seed * 48271 % 2147483647;
    return seed % n;
  }

  /// Next double in `[0, 1)`.
  double nextDouble() {
    seed = seed * 48271 % 2147483647;
    return seed / 2147483647.0;
  }
}

const int _pool = 256;
const int _m = _pool - 1;

int _sink = 0;

int _eatText(String s) => s.length + s.codeUnitAt(s.length - 1);

/// Runs all benchmark cases and returns the formatted `BENCH` lines.
List<String> runBenchmarks({
  String target = 'dart',
  String filter = '',
  int batches = 9,
  int batchMs = 60,
  int warmMs = 300,
}) {
  final r = Lcg(42);
  final xs = Float64List(_pool);
  final ys = Float64List(_pool);
  final ixs = Float64List(_pool);
  final iys = Float64List(_pool);
  final radii = Float64List(_pool);
  final a0s = Float64List(_pool);
  final a1s = Float64List(_pool);
  final ccws = Uint8List(_pool);

  for (var i = 0; i < _pool; i++) {
    xs[i] = r.nextDouble() * 1000.0 - 200.0;
    ys[i] = r.nextDouble() * 600.0 - 100.0;
    ixs[i] = (r.next(1000) - 200).toDouble();
    iys[i] = (r.next(600) - 100).toDouble();
    radii[i] = 5.0 + r.nextDouble() * 95.0;
    a0s[i] = (r.nextDouble() * 2.0 - 1.0) * math.pi;
    a1s[i] = a0s[i] + r.nextDouble() * 2.2 * math.pi;
    ccws[i] = r.next(2);
  }

  String buildPolyline(Path p, Float64List px, Float64List py, int start) {
    p.moveTo(px[start & _m], py[start & _m]);
    for (var j = 1; j < 100; j++) {
      final k = (start + j) & _m;
      p.lineTo(px[k], py[k]);
    }
    return p.toString();
  }

  String buildBezier(Path p, int start) {
    p.moveTo(xs[start & _m], ys[start & _m]);
    for (var j = 0; j < 50; j++) {
      final k0 = (start + j * 3) & _m;
      final k1 = (start + j * 3 + 1) & _m;
      final k2 = (start + j * 3 + 2) & _m;
      p.bezierCurveTo(xs[k0], ys[k0], xs[k1], ys[k1], xs[k2], ys[k2]);
    }
    return p.toString();
  }

  String buildQuad(Path p, int start) {
    p.moveTo(xs[start & _m], ys[start & _m]);
    for (var j = 0; j < 50; j++) {
      final k0 = (start + j * 2) & _m;
      final k1 = (start + j * 2 + 1) & _m;
      p.quadraticCurveTo(xs[k0], ys[k0], xs[k1], ys[k1]);
    }
    return p.toString();
  }

  String buildArcs(Path p, int start) {
    for (var j = 0; j < 20; j++) {
      final k = (start + j) & _m;
      p.arc(xs[k], ys[k], radii[k], a0s[k], a1s[k], ccws[k] != 0);
    }
    return p.toString();
  }

  String buildArcTo(Path p, int start) {
    p.moveTo(xs[start & _m], ys[start & _m]);
    for (var j = 0; j < 20; j++) {
      final k0 = (start + j * 2) & _m;
      final k1 = (start + j * 2 + 1) & _m;
      p.arcTo(xs[k0], ys[k0], xs[k1], ys[k1], radii[k0]);
    }
    return p.toString();
  }

  String buildRects(Path p, int start) {
    for (var j = 0; j < 50; j++) {
      final k = (start + j) & _m;
      p.rect(xs[k], ys[k], radii[k], radii[(k + 1) & _m]);
    }
    return p.toString();
  }

  String buildMixed(Path p, int start) {
    final k0 = start & _m;
    final k1 = (start + 1) & _m;
    final k2 = (start + 2) & _m;
    final k3 = (start + 3) & _m;
    p
      ..moveTo(xs[k0], ys[k0])
      ..lineTo(xs[k1], ys[k1])
      ..quadraticCurveTo(xs[k1], ys[k2], xs[k2], ys[k2])
      ..bezierCurveTo(xs[k0], ys[k1], xs[k2], ys[k3], xs[k3], ys[k3])
      ..arc(xs[k0], ys[k0], radii[k0], a0s[k0], a1s[k0], ccws[k0] != 0)
      ..arcTo(xs[k1], ys[k1], xs[k2], ys[k2], radii[k1])
      ..rect(xs[k2], ys[k2], radii[k2], radii[k3])
      ..closePath();
    return p.toString();
  }

  final cases = <String, void Function(int)>{
    'polyline100.full': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildPolyline(path(), xs, ys, i));
      }
      _sink += s;
    },
    'polyline100.round3': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildPolyline(pathRound(), xs, ys, i));
      }
      _sink += s;
    },
    'polyline100.int': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildPolyline(path(), ixs, iys, i));
      }
      _sink += s;
    },
    'bezier50.full': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildBezier(path(), i));
      }
      _sink += s;
    },
    'bezier50.round3': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildBezier(pathRound(), i));
      }
      _sink += s;
    },
    'quad50.full': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildQuad(path(), i));
      }
      _sink += s;
    },
    'quad50.round3': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildQuad(pathRound(), i));
      }
      _sink += s;
    },
    'arc20.full': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildArcs(path(), i));
      }
      _sink += s;
    },
    'arc20.round3': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildArcs(pathRound(), i));
      }
      _sink += s;
    },
    'arcTo20.full': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildArcTo(path(), i));
      }
      _sink += s;
    },
    'arcTo20.round3': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildArcTo(pathRound(), i));
      }
      _sink += s;
    },
    'rect50.full': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildRects(path(), i));
      }
      _sink += s;
    },
    'rect50.round3': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildRects(pathRound(), i));
      }
      _sink += s;
    },
    'mixed.full': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildMixed(path(), i));
      }
      _sink += s;
    },
    'mixed.round3': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(buildMixed(pathRound(), i));
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

    var ops = 8;
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
    lines.add(
      'BENCH {"target":"$target","case":"${entry.key}", '
      '"ns":${median.toStringAsFixed(2)},"ops":$ops}',
    );
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
