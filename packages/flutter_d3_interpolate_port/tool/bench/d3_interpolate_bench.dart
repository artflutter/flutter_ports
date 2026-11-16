// Original code, not ported from d3-interpolate: the benchmark of the port.

/// The d3-interpolate benchmark of the Dart port: the cases of
/// `d3_interpolate_bench.mjs` (upstream d3-interpolate in Node.js) with the
/// same inputs.
///
/// Run it on the VM (`dart run`), as an AOT executable
/// (`dart compile exe`), as JavaScript (`dart compile js`, then Node.js) and
/// as WebAssembly (`dart compile wasm`, then Node.js); `run_bench.sh` does
/// all of them. Each case prints one line `BENCH {json}` with the median time
/// of one operation in nanoseconds over the batches.
///
/// The cases `call.*` call an interpolator that exists before the timing,
/// at another `t` for each operation. The cases `create.*` make an
/// interpolator and call it once. The cases `text.*` call a color
/// interpolator and write the color as CSS text, the upstream result.
///
/// Arguments: `--filter=<text>` runs the cases whose name contains the
/// text, `--batches=<n>` (default 9), `--batch-ms=<n>` (default 60),
/// `--warm-ms=<n>` (default 300) and `--target=<name>` (written into each
/// line).
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter_d3_color_port/d3_color.dart' as d3;
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';

/// The Park-Miller generator: exact in JavaScript numbers and in Dart.
final class Lcg(
  /// The state.
  var int seed,
) {
  /// A generator with the seed [seed].
  this;

  /// The next integer in [0, n).
  int next(int n) {
    seed = seed * 48271 % 2147483647;
    return seed % n;
  }
}

const int _pool = 1024;
const int _m = _pool - 1;

/// The input pools, as the Node file makes them.
final class Inputs() {
  /// Makes the pools from the seed 42.
  this {
    final r = Lcg(42);
    double number() => r.next(200000) / 100 - 1000;
    d3.Rgb rgb() => d3.Rgb(
      r.next(256).toDouble(),
      r.next(256).toDouble(),
      r.next(256).toDouble(),
    );
    List<double> values(int n) => [
      for (var k = 0; k < n; k++) r.next(10000) / 100,
    ];
    for (var i = 0; i < _pool; i++) {
      ts.add(r.next(1001) / 1000);
      numbersA.add(number());
      numbersB.add(number());
      huesA.add(r.next(72000) / 100 - 360);
      huesB.add(r.next(72000) / 100 - 360);
      basis.add(values(8));
      datesA.add(946684800000 + r.next(2000000000) * 100);
      datesB.add(946684800000 + r.next(2000000000) * 100);
      arraysA.add(values(16));
      arraysB.add(values(16));
      colorsA.add(rgb());
      colorsB.add(rgb());
      palettes.add([for (var k = 0; k < 8; k++) rgb()]);
      zoomsA.add((
        r.next(1000).toDouble(),
        r.next(1000).toDouble(),
        r.next(1000) + 1.0,
      ));
      zoomsB.add((
        r.next(1000).toDouble(),
        r.next(1000).toDouble(),
        r.next(1000) + 1.0,
      ));
      matricesA.add(_matrix(r));
      matricesB.add(_matrix(r));
    }
  }

  static List<double> _matrix(Lcg r) => [
    r.next(200) / 100 + 0.5,
    r.next(200) / 100 - 1,
    r.next(200) / 100 - 1,
    r.next(200) / 100 + 0.5,
    r.next(20000) / 100 - 100,
    r.next(20000) / 100 - 100,
  ];

  /// The values of `t`.
  final List<double> ts = [];

  /// The start numbers.
  final List<double> numbersA = [];

  /// The end numbers.
  final List<double> numbersB = [];

  /// The start hues.
  final List<double> huesA = [];

  /// The end hues.
  final List<double> huesB = [];

  /// Lists of 8 numbers for the splines and the discrete interpolator.
  final List<List<double>> basis = [];

  /// The start dates in milliseconds.
  final List<int> datesA = [];

  /// The end dates in milliseconds.
  final List<int> datesB = [];

  /// The start lists of 16 numbers.
  final List<List<double>> arraysA = [];

  /// The end lists of 16 numbers.
  final List<List<double>> arraysB = [];

  /// The start colors.
  final List<d3.Rgb> colorsA = [];

  /// The end colors.
  final List<d3.Rgb> colorsB = [];

  /// Lists of 8 colors.
  final List<List<d3.Rgb>> palettes = [];

  /// The start views of the zoom.
  final List<ZoomView> zoomsA = [];

  /// The end views of the zoom.
  final List<ZoomView> zoomsB = [];

  /// The start matrices `[a, b, c, d, e, f]`.
  final List<List<double>> matricesA = [];

  /// The end matrices.
  final List<List<double>> matricesB = [];
}

/// A value that the cases write, so that no compiler removes their work.
double sink = 0;

/// One case: its name, and a function that does one operation on the input
/// `i` of a pool.
typedef Case = (String, void Function(int i));

TransformParts _parts(List<double> m) =>
    decompose(m[0], m[1], m[2], m[3], m[4], m[5]);

/// The cases, in the order of the Node file.
List<Case> cases(Inputs p) {
  List<T> make<T>(T Function(int i) f) => [
    for (var i = 0; i < _pool; i++) f(i),
  ];
  double t(int i) => p.ts[(i * 7) & _m];

  final number = make((i) => interpolateNumber(p.numbersA[i], p.numbersB[i]));
  final round = make((i) => interpolateRound(p.numbersA[i], p.numbersB[i]));
  final hue = make((i) => interpolateHue(p.huesA[i], p.huesB[i]));
  final basis = make((i) => interpolateBasis(p.basis[i]));
  final basisClosed = make((i) => interpolateBasisClosed(p.basis[i]));
  final discrete = make((i) => interpolateDiscrete<double>(p.basis[i]));
  final date = make(
    (i) => interpolateDate(
      DateTime.fromMillisecondsSinceEpoch(p.datesA[i], isUtc: true),
      DateTime.fromMillisecondsSinceEpoch(p.datesB[i], isUtc: true),
    ),
  );
  final numberArray = make(
    (i) => interpolateNumberArray(
      Float64List.fromList(p.arraysA[i]),
      Float64List.fromList(p.arraysB[i]),
    ),
  );
  final array = make(
    (i) => interpolateArray<double>(p.arraysA[i], p.arraysB[i]),
  );
  final rgb = make((i) => interpolateRgb(p.colorsA[i], p.colorsB[i]));
  final rgbGamma = make(
    (i) => interpolateRgb.gamma(2.2)(p.colorsA[i], p.colorsB[i]),
  );
  final rgbBasis = make((i) => interpolateRgbBasis(p.palettes[i]));
  final hsl = make((i) => interpolateHsl(p.colorsA[i], p.colorsB[i]));
  final hslLong = make((i) => interpolateHslLong(p.colorsA[i], p.colorsB[i]));
  final lab = make((i) => interpolateLab(p.colorsA[i], p.colorsB[i]));
  final hcl = make((i) => interpolateHcl(p.colorsA[i], p.colorsB[i]));
  final hclLong = make((i) => interpolateHclLong(p.colorsA[i], p.colorsB[i]));
  final cubehelix = make(
    (i) => interpolateCubehelix(p.colorsA[i], p.colorsB[i]),
  );
  final cubehelixGamma = make(
    (i) => interpolateCubehelixLong.gamma(3)(p.colorsA[i], p.colorsB[i]),
  );
  final piecewiseRgb = make(
    (i) => piecewise<d3.Color>(
      p.palettes[i].sublist(0, 4),
      interpolate: interpolateRgb.call,
    ),
  );
  final zoom = make((i) => interpolateZoom(p.zoomsA[i], p.zoomsB[i]));
  final transform = make(
    (i) => interpolateTransform(_parts(p.matricesA[i]), _parts(p.matricesB[i])),
  );
  // The six numbers of each matrix in one typed list, as the .mjs file
  // does: `decompose` reads them, not the growable lists.
  final flat = Float64List(6 * _pool);
  for (var i = 0; i < _pool; i++) {
    flat.setAll(6 * i, p.matricesA[i]);
  }
  final partsA = make((i) => _parts(p.matricesA[i]));
  final partsB = make((i) => _parts(p.matricesB[i]));

  return [
    ('call.number', (i) => sink += number[i & _m](t(i))),
    ('call.round', (i) => sink += round[i & _m](t(i))),
    ('call.hue', (i) => sink += hue[i & _m](t(i))),
    ('call.basis', (i) => sink += basis[i & _m](t(i))),
    ('call.basisClosed', (i) => sink += basisClosed[i & _m](t(i))),
    ('call.discrete', (i) => sink += discrete[i & _m](t(i))),
    ('call.date', (i) => sink += date[i & _m](t(i)).millisecondsSinceEpoch),
    ('call.numberArray', (i) => sink += numberArray[i & _m](t(i))[3]),
    ('call.array', (i) => sink += array[i & _m](t(i))[3]),
    ('call.rgb', (i) => sink += rgb[i & _m](t(i)).r),
    ('call.rgbGamma', (i) => sink += rgbGamma[i & _m](t(i)).r),
    ('call.rgbBasis', (i) => sink += rgbBasis[i & _m](t(i)).r),
    ('call.hsl', (i) => sink += hsl[i & _m](t(i)).l),
    ('call.hslLong', (i) => sink += hslLong[i & _m](t(i)).l),
    ('call.lab', (i) => sink += lab[i & _m](t(i)).l),
    ('call.hcl', (i) => sink += hcl[i & _m](t(i)).l),
    ('call.hclLong', (i) => sink += hclLong[i & _m](t(i)).l),
    ('call.cubehelix', (i) => sink += cubehelix[i & _m](t(i)).l),
    ('call.cubehelixGamma', (i) => sink += cubehelixGamma[i & _m](t(i)).l),
    ('call.piecewise', (i) => sink += piecewiseRgb[i & _m](t(i)).opacity),
    ('call.zoom', (i) => sink += zoom[i & _m](t(i)).$3),
    ('call.transform', (i) => sink += transform[i & _m](t(i)).rotate),
    ('text.rgb', (i) => sink += rgb[i & _m](t(i)).toString().length),
    ('text.hsl', (i) => sink += hsl[i & _m](t(i)).toString().length),
    ('text.lab', (i) => sink += lab[i & _m](t(i)).toString().length),
    ('text.hcl', (i) => sink += hcl[i & _m](t(i)).toString().length),
    (
      'text.cubehelix',
      (i) => sink += cubehelix[i & _m](t(i)).toString().length,
    ),
    (
      'create.number',
      (i) => sink += interpolateNumber(p.numbersA[i & _m], p.numbersB[i & _m])(
        0.5,
      ),
    ),
    (
      'create.rgb',
      (i) =>
          sink += interpolateRgb(p.colorsA[i & _m], p.colorsB[i & _m])(0.5).r,
    ),
    (
      'create.hcl',
      (i) =>
          sink += interpolateHcl(p.colorsA[i & _m], p.colorsB[i & _m])(0.5).l,
    ),
    (
      'create.valueNumber',
      (i) => sink += interpolate<double>(
        p.numbersA[i & _m],
        p.numbersB[i & _m],
      )(0.5),
    ),
    (
      'create.valueColor',
      (i) => sink += interpolate<d3.Color>(
        p.colorsA[i & _m],
        p.colorsB[i & _m],
      )(0.5).opacity,
    ),
    (
      'create.valueArray',
      (i) => sink += interpolate<List<double>>(
        p.arraysA[i & _m],
        p.arraysB[i & _m],
      )(0.5)[3],
    ),
    (
      'create.zoom',
      (i) =>
          sink += interpolateZoom(p.zoomsA[i & _m], p.zoomsB[i & _m])(0.5).$3,
    ),
    (
      'create.transform',
      (i) =>
          sink += interpolateTransform(partsA[i & _m], partsB[i & _m])(0.5)
              .rotate,
    ),
    (
      'decompose',
      (i) {
        final k = 6 * (i & _m);
        sink += decompose(
          flat[k],
          flat[k + 1],
          flat[k + 2],
          flat[k + 3],
          flat[k + 4],
          flat[k + 5],
        ).rotate;
      },
    ),
    (
      'quantize.rgb',
      (i) => sink += quantize(
        interpolateRgb(p.colorsA[i & _m], p.colorsB[i & _m]),
        8,
      ).length,
    ),
  ];
}

void main(List<String> args) {
  String? filter;
  var batches = 9;
  var batchMs = 60;
  var warmMs = 300;
  var target = 'dart';
  for (final arg in args) {
    final eq = arg.indexOf('=');
    final key = eq < 0 ? arg : arg.substring(0, eq);
    final value = eq < 0 ? '' : arg.substring(eq + 1);
    switch (key) {
      case '--filter':
        filter = value;
      case '--batches':
        batches = int.parse(value);
      case '--batch-ms':
        batchMs = int.parse(value);
      case '--warm-ms':
        warmMs = int.parse(value);
      case '--target':
        target = value;
    }
  }
  final inputs = Inputs();
  final watch = Stopwatch()..start();
  for (final (name, run) in cases(inputs)) {
    if (filter != null && !name.contains(filter)) continue;
    // Warm up, and find the count of operations of one batch.
    var ops = 64;
    var i = 0;
    final warmEnd = watch.elapsedMicroseconds + warmMs * 1000;
    while (watch.elapsedMicroseconds < warmEnd) {
      final start = watch.elapsedMicroseconds;
      for (var k = 0; k < ops; k++) {
        run(i++);
      }
      final took = watch.elapsedMicroseconds - start;
      if (took < batchMs * 1000 ~/ 4) ops *= 2;
    }
    final perOp = <double>[];
    for (var b = 0; b < batches; b++) {
      final start = watch.elapsedMicroseconds;
      for (var k = 0; k < ops; k++) {
        run(i++);
      }
      final took = watch.elapsedMicroseconds - start;
      perOp.add(took * 1000 / ops);
    }
    perOp.sort();
    final median = perOp[perOp.length ~/ 2];
    print(
      'BENCH {"target":"$target","case":"$name","nsPerOp":'
      '${median.toStringAsFixed(2)},"ops":$ops,"batches":['
      '${perOp.map((v) => v.toStringAsFixed(2)).join(',')}]}',
    );
  }
  print('SINK $sink');
}
