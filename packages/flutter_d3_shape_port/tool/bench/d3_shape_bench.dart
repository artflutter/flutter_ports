// Original code, not ported from d3-shape: the benchmark of the port.

/// The d3-shape benchmark of the Dart port: the cases of `d3_shape_bench.mjs`
/// (upstream d3-shape in Node.js) with the same seeded inputs.
///
/// Run as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flutter_d3_shape_port/d3_shape.dart';

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

/// Seeded 2D point datum.
final class BenchPoint(
  /// X coordinate.
  final double x,

  /// Lower Y coordinate.
  final double y0,

  /// Upper Y coordinate.
  final double y1,

  /// Radial angle.
  final double angle,

  /// Radial distance.
  final double radius,
) {
  /// Creates a [BenchPoint].
  this;
}

/// Seeded benchmark fixtures shared by pure and Flutter UI benchmarks.
final class BenchFixtures._({
  /// 20 pie slice values.
  required final List<double> pieValues,

  /// 20 unpadded pie arcs.
  required final List<PieArc<double>> arcsPlain,

  /// 20 padded pie arcs.
  required final List<PieArc<double>> arcsPadded,

  /// 100 sequential points for line/area/radial benchmarks.
  required final List<BenchPoint> points100,

  /// 50 Cartesian links.
  required final List<LinkData<(double, double)>> links50,

  /// 50 radial links.
  required final List<LinkData<(double, double)>> radialLinks50,

  /// 50 symbol areas.
  required final List<double> symbolSizes,

  /// 8 stack keys.
  required final List<String> stackKeys,

  /// 50 rows × 8 numeric series values.
  required final List<List<double>> stackRows,
}) {
  /// Internal constructor.
  this;

  /// Builds the seeded fixtures.
  factory() {
    final r = Lcg(42);

    final pieValues = List<double>.generate(
      20,
      (_) => 5.0 + r.nextDouble() * 95.0,
    );
    final arcsPlain = pie<double>()(pieValues);
    final arcsPadded = (pie<double>()..padAngleConst(0.03))(pieValues);

    final points100 = List<BenchPoint>.generate(100, (i) {
      final y0 = 10.0 + r.nextDouble() * 120.0;
      final y1 = y0 + 20.0 + r.nextDouble() * 150.0;
      return BenchPoint(
        i * 8.0,
        y0,
        y1,
        (i / 100.0) * math.pi * 2,
        40.0 + r.nextDouble() * 120.0,
      );
    });

    final links50 = List<LinkData<(double, double)>>.generate(
      50,
      (_) => LinkData(
        source: (r.nextDouble() * 100.0, r.nextDouble() * 400.0),
        target: (250.0 + r.nextDouble() * 200.0, r.nextDouble() * 400.0),
      ),
    );

    final radialLinks50 = List<LinkData<(double, double)>>.generate(
      50,
      (_) => LinkData(
        source: (r.nextDouble() * math.pi * 2, 30.0 + r.nextDouble() * 40.0),
        target: (r.nextDouble() * math.pi * 2, 100.0 + r.nextDouble() * 80.0),
      ),
    );

    final symbolSizes = List<double>.generate(
      50,
      (_) => 32.0 + r.nextDouble() * 192.0,
    );

    const stackKeys = ['s0', 's1', 's2', 's3', 's4', 's5', 's6', 's7'];
    final stackRows = List<List<double>>.generate(
      50,
      (_) => List<double>.generate(8, (_) => 5.0 + r.nextDouble() * 45.0),
    );

    return BenchFixtures._(
      pieValues: pieValues,
      arcsPlain: arcsPlain,
      arcsPadded: arcsPadded,
      points100: points100,
      links50: links50,
      radialLinks50: radialLinks50,
      symbolSizes: symbolSizes,
      stackKeys: stackKeys,
      stackRows: stackRows,
    );
  }
}

int _sink = 0;

int _eatText(String s) => s.length + s.codeUnitAt(s.length - 1);

/// Runs all pure-Dart benchmark cases and returns the formatted `BENCH` lines.
List<String> runBenchmarks({
  String target = 'dart',
  String filter = '',
  int batches = 9,
  int batchMs = 60,
  int warmMs = 300,
}) {
  final f = BenchFixtures();

  final arcPlainGen = arc<PieArc<double>>()
    ..innerRadiusConst(40)
    ..outerRadiusConst(100)
    ..startAngle = ((d) => d.startAngle)
    ..endAngle = ((d) => d.endAngle)
    ..padAngle = ((d) => d.padAngle);

  final arcRoundedGen = arc<PieArc<double>>()
    ..innerRadiusConst(40)
    ..outerRadiusConst(100)
    ..cornerRadiusConst(8)
    ..startAngle = ((d) => d.startAngle)
    ..endAngle = ((d) => d.endAngle)
    ..padAngle = ((d) => d.padAngle);

  final pieGen = pie<double>();

  Line<BenchPoint> makeLine(CurveFactory curve) => line<BenchPoint>()
    ..x = ((d, _, _) => d.x)
    ..y = ((d, _, _) => d.y1)
    ..curve = curve;

  final lineLinear = makeLine(curveLinear);
  final lineBasis = makeLine(curveBasis);
  final lineCardinal = makeLine(curveCardinal.call);
  final lineCatmullRom = makeLine(curveCatmullRom.call);
  final lineMonotoneX = makeLine(curveMonotoneX);
  final lineNatural = makeLine(curveNatural);
  final lineStep = makeLine(curveStep);

  Area<BenchPoint> makeArea(CurveFactory curve) => area<BenchPoint>()
    ..x = ((d, _, _) => d.x)
    ..y0 = ((d, _, _) => d.y0)
    ..y1 = ((d, _, _) => d.y1)
    ..curve = curve;

  final areaLinear = makeArea(curveLinear);
  final areaMonotoneX = makeArea(curveMonotoneX);
  final areaBasis = makeArea(curveBasis);

  final radialLineGen = lineRadial<BenchPoint>()
    ..angle = ((d, _, _) => d.angle)
    ..radius = ((d, _, _) => d.radius)
    ..curve = curveLinearClosed;

  final linkH = linkHorizontal<LinkData<(double, double)>, (double, double)>();
  final linkR = linkRadial<LinkData<(double, double)>, (double, double)>();

  final symCircle = symbol<double>(symbolCircle)..size = ((d) => d);
  final symStar = symbol<double>(symbolStar)..size = ((d) => d);

  final stackNone = stack<List<double>, int>()
    ..keysConst([0, 1, 2, 3, 4, 5, 6, 7])
    ..value = ((d, k, _, _) => d[k]);

  final stackWiggle = stack<List<double>, int>()
    ..keysConst([0, 1, 2, 3, 4, 5, 6, 7])
    ..value = ((d, k, _, _) => d[k])
    ..order = stackOrderInsideOut
    ..offset = stackOffsetWiggle;

  final cases = <String, void Function(int)>{
    'arc.plain20': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final a in f.arcsPlain) {
          s += _eatText(arcPlainGen(a)!);
        }
      }
      _sink += s;
    },
    'arc.roundedPad20': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final a in f.arcsPadded) {
          s += _eatText(arcRoundedGen(a)!);
        }
      }
      _sink += s;
    },
    'pie.20': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        final res = pieGen(f.pieValues);
        s += res.length + res[0].endAngle.round();
      }
      _sink += s;
    },
    'line.linear100': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(lineLinear(f.points100)!);
      }
      _sink += s;
    },
    'line.basis100': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(lineBasis(f.points100)!);
      }
      _sink += s;
    },
    'line.cardinal100': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(lineCardinal(f.points100)!);
      }
      _sink += s;
    },
    'line.catmullRom100': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(lineCatmullRom(f.points100)!);
      }
      _sink += s;
    },
    'line.monotoneX100': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(lineMonotoneX(f.points100)!);
      }
      _sink += s;
    },
    'line.natural100': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(lineNatural(f.points100)!);
      }
      _sink += s;
    },
    'line.step100': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(lineStep(f.points100)!);
      }
      _sink += s;
    },
    'area.linear100': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(areaLinear(f.points100)!);
      }
      _sink += s;
    },
    'area.monotoneX100': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(areaMonotoneX(f.points100)!);
      }
      _sink += s;
    },
    'area.basis100': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(areaBasis(f.points100)!);
      }
      _sink += s;
    },
    'lineRadial.100': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += _eatText(radialLineGen(f.points100)!);
      }
      _sink += s;
    },
    'linkHorizontal.50': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final l in f.links50) {
          s += _eatText(linkH(l)!);
        }
      }
      _sink += s;
    },
    'linkRadial.50': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final l in f.radialLinks50) {
          s += _eatText(linkR(l)!);
        }
      }
      _sink += s;
    },
    'symbol.circle50': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final sz in f.symbolSizes) {
          s += _eatText(symCircle(sz)!);
        }
      }
      _sink += s;
    },
    'symbol.star50': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final sz in f.symbolSizes) {
          s += _eatText(symStar(sz)!);
        }
      }
      _sink += s;
    },
    'stack.none': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        final res = stackNone(f.stackRows);
        s += res.length + res[0][49].y1.round();
      }
      _sink += s;
    },
    'stack.wiggle': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        final res = stackWiggle(f.stackRows);
        s += res.length + res[0][49].y1.round();
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
