// Original code, not ported from d3-color: the benchmark of the Dart port.

/// The d3-color benchmark of the Dart port: the cases of
/// `d3_color_bench.mjs` (upstream d3-color in Node.js) with the same inputs.
///
/// Run it on the VM (`dart run`), as an AOT executable
/// (`dart compile exe`), as JavaScript (`dart compile js`, then Node.js) and
/// as WebAssembly (`dart compile wasm`, then Node.js); `run_bench.sh` does
/// all of them. Each case prints one line `BENCH {json}` with the median time
/// of one operation in nanoseconds over the batches.
///
/// Arguments: `--filter=<text>` runs the cases whose name contains the
/// text, `--batches=<n>` (default 9), `--batch-ms=<n>` (default 60),
/// `--warm-ms=<n>` (default 300) and `--target=<name>` (written into each
/// line).
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'package:flutter_d3_color_port/d3_color.dart';

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

const List<String> _names = [
  'steelblue', 'aliceblue', 'rebeccapurple', 'moccasin', 'red', 'tomato',
  'darkslategray', 'lightgoldenrodyellow', 'navy', 'teal', 'gold', 'white',
  'black', 'orange', 'mediumspringgreen', 'transparent', 'cornflowerblue',
  'SteelBlue', 'GRAY', 'peru', //
];

const String _hexDigits = '0123456789abcdef';

/// The text `<n ~/ 10>.<n % 10>`, as JavaScript writes it in the Node file.
String _tenths(int n) => '${n ~/ 10}.${n % 10}';

/// [n] in [0, 99] with two digits.
String _twoDigits(int n) => n < 10 ? '0$n' : '$n';

String _hex(Lcg r, int n) => String.fromCharCodes([
  for (var i = 0; i < n; i++) _hexDigits.codeUnitAt(r.next(16)),
]);

/// The input pools, as the Node file makes them.
final class Inputs() {
  /// Makes the pools from the seed 42.
  this {
    final r = Lcg(42);
    for (var i = 0; i < _pool; i++) {
      hex6.add('#${_hex(r, 6)}');
      hex3.add('#${_hex(r, 3)}');
      named.add(_names[r.next(_names.length)]);
      rgb.add('rgb(${r.next(256)}, ${r.next(256)}, ${r.next(256)})');
      rgbaPercent.add(
        'rgba(${_tenths(r.next(1001))}%, ${_tenths(r.next(1001))}%, '
        '${_tenths(r.next(1001))}%, 0.${_twoDigits(r.next(100))})',
      );
      hsl.add('hsl(${r.next(360)}, ${r.next(101)}%, ${r.next(101)}%)');
      invalid.add(
        const ['bostock', '#ab', 'rgb(1,2)', 'hsl(1 2 3)', '#abcdefg'][r.next(
          5,
        )],
      );
      rgbColors.add(
        Rgb(
          r.next(25600) / 100,
          r.next(25600) / 100,
          r.next(25600) / 100,
          r.next(2) == 0 ? 1 : r.next(100) / 100,
        ),
      );
      hslColors.add(
        Hsl(r.next(36000) / 100, r.next(1000) / 1000, r.next(1000) / 1000, 1),
      );
      labColors.add(
        Lab(
          r.next(10000) / 100,
          r.next(16000) / 100 - 80,
          r.next(16000) / 100 - 80,
          1,
        ),
      );
      hclColors.add(
        Hcl(r.next(36000) / 100, r.next(10000) / 100, r.next(10000) / 100, 1),
      );
      cubehelixColors.add(
        Cubehelix(
          r.next(36000) / 100,
          r.next(1000) / 1000,
          r.next(1000) / 1000,
          1,
        ),
      );
    }
    for (var i = 0; i < _pool; i++) {
      final k = i % 6;
      mixed.add(switch (k) {
        0 => hex6[i],
        1 => hex3[i],
        2 => named[i],
        3 => rgb[i],
        4 => rgbaPercent[i],
        _ => hsl[i],
      });
    }
  }

  /// `#rrggbb` texts.
  final List<String> hex6 = [];

  /// `#rgb` texts.
  final List<String> hex3 = [];

  /// Color names, some with capitals.
  final List<String> named = [];

  /// `rgb(r, g, b)` texts.
  final List<String> rgb = [];

  /// `rgba(r%, g%, b%, a)` texts.
  final List<String> rgbaPercent = [];

  /// `hsl(h, s%, l%)` texts.
  final List<String> hsl = [];

  /// Texts that are not colors.
  final List<String> invalid = [];

  /// The six kinds of texts in turn.
  final List<String> mixed = [];

  /// RGB colors, half of them with an opacity below 1.
  final List<Rgb> rgbColors = [];

  /// HSL colors.
  final List<Hsl> hslColors = [];

  /// Lab colors.
  final List<Lab> labColors = [];

  /// HCL colors.
  final List<Hcl> hclColors = [];

  /// Cubehelix colors.
  final List<Cubehelix> cubehelixColors = [];
}

/// A value that the cases write, so that no compiler removes their work.
double sink = 0;

/// One case: its name, and a function that does one operation on the input
/// `i` of a pool.
typedef Case = (String, void Function(int i));

/// The cases, in the order of the Node file.
List<Case> cases(Inputs p) {
  const m = _pool - 1;
  void parse(List<String> pool, int i) {
    final c = color(pool[i & m]);
    sink += c == null ? 1 : c.opacity;
  }

  return [
    ('parse.hex6', (i) => parse(p.hex6, i)),
    ('parse.hex3', (i) => parse(p.hex3, i)),
    ('parse.named', (i) => parse(p.named, i)),
    ('parse.rgb', (i) => parse(p.rgb, i)),
    ('parse.rgbaPercent', (i) => parse(p.rgbaPercent, i)),
    ('parse.hsl', (i) => parse(p.hsl, i)),
    ('parse.invalid', (i) => parse(p.invalid, i)),
    ('parse.mixed', (i) => parse(p.mixed, i)),
    ('rgb.parse', (i) => sink += Rgb.parse(p.mixed[i & m]).r),
    ('format.hex', (i) => sink += p.rgbColors[i & m].formatHex().length),
    ('format.hex8', (i) => sink += p.rgbColors[i & m].formatHex8().length),
    ('format.rgb', (i) => sink += p.rgbColors[i & m].formatRgb().length),
    ('format.hsl', (i) => sink += p.hslColors[i & m].formatHsl().length),
    ('format.rgbOfHsl', (i) => sink += p.hslColors[i & m].toString().length),
    ('convert.rgbToHsl', (i) => sink += Hsl.from(p.rgbColors[i & m]).l),
    ('convert.hslToRgb', (i) => sink += p.hslColors[i & m].rgb().r),
    ('convert.rgbToLab', (i) => sink += Lab.from(p.rgbColors[i & m]).l),
    ('convert.labToRgb', (i) => sink += p.labColors[i & m].rgb().r),
    ('convert.rgbToHcl', (i) => sink += Hcl.from(p.rgbColors[i & m]).c),
    ('convert.hclToRgb', (i) => sink += p.hclColors[i & m].rgb().r),
    (
      'convert.rgbToCubehelix',
      (i) => sink += Cubehelix.from(p.rgbColors[i & m]).l,
    ),
    ('convert.cubehelixToRgb', (i) => sink += p.cubehelixColors[i & m].rgb().r),
    ('op.brighterRgb', (i) => sink += p.rgbColors[i & m].brighter(0.5).r),
    ('op.darkerHcl', (i) => sink += p.hclColors[i & m].darker().l),
    (
      'pipe.hclTick',
      (i) {
        // The tick of an HCL interpolator: a new hue, then print.
        final c = p.hclColors[i & m];
        sink += c.copyWith(h: c.h + 0.5).toString().length;
      },
    ),
    (
      'pipe.parseHex',
      (i) => sink += Rgb.parse(p.mixed[i & m]).formatHex().length,
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
