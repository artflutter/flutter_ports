// Original code, not ported from d3-format: the benchmark of the port.

/// The d3-format benchmark of the Dart port: the 20 cases of
/// `d3_format_bench.mjs` (upstream d3-format in Node.js) with identical seeded
/// inputs.
///
/// Run as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flutter_d3_format_port/d3_format.dart';

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

/// Seeded benchmark datasets.
final class BenchFixtures._({
  /// 16 diverse specifier strings.
  required final List<String> specifiers16,

  /// 64 signed integers/doubles up to 1e9.
  required final List<double> ints64,

  /// 64 financial/decimal doubles up to ±1e7.
  required final List<double> floats64,

  /// 64 scientific/SI doubles spanning 1e-12 to 1e12.
  required final List<double> wide64,

  /// 64 values near exact powers/multiples for trimming.
  required final List<double> trim64,

  /// 64 ratio values in [-1.5, 1.5].
  required final List<double> ratios64,

  /// 64 unsigned 32-bit integers.
  required final List<double> hex64,

  /// 64 megascale values for `formatPrefix`.
  required final List<double> mega64,
}) {
  /// Builds the seeded fixtures.
  factory() {
    final r = Lcg(42);
    const specifiers16 = [
      '',
      'd',
      ',d',
      '+012,d',
      '.2f',
      r'+$,.2f',
      r'($,.2f',
      '.3e',
      '.4~e',
      '.6g',
      ',~g',
      'n',
      '.3s',
      '~s',
      '.1%',
      '#010x',
    ];
    final ints64 = List<double>.generate(64, (i) {
      final sign = (i & 3) == 0 ? -1.0 : 1.0;
      return sign * (r.nextDouble() * 1e9).roundToDouble();
    });
    final floats64 = List<double>.generate(64, (i) {
      final sign = (i & 3) == 0 ? -1.0 : 1.0;
      return sign * (r.nextDouble() * 1e7);
    });
    final wide64 = List<double>.generate(64, (i) {
      final exp = -12 + (i % 25);
      final sign = (i & 7) == 0 ? -1.0 : 1.0;
      return sign * (1.0 + r.nextDouble() * 9.0) * math.pow(10.0, exp);
    });
    final trim64 = List<double>.generate(64, (i) {
      final exp = -6 + (i % 13);
      final coeff = (1 + (i % 9)) * (i.isEven ? 1.0 : 1.25);
      return coeff * math.pow(10.0, exp);
    });
    final ratios64 = List<double>.generate(
      64,
      (_) => (r.nextDouble() - 0.3) * 2.0,
    );
    final hex64 = List<double>.generate(
      64,
      (_) => (r.nextDouble() * 0xffffffff).floorToDouble(),
    );
    final mega64 = List<double>.generate(
      64,
      (i) => ((i & 3) == 0 ? -1.0 : 1.0) * r.nextDouble() * 5e7,
    );

    return BenchFixtures._(
      specifiers16: specifiers16,
      ints64: ints64,
      floats64: floats64,
      wide64: wide64,
      trim64: trim64,
      ratios64: ratios64,
      hex64: hex64,
      mega64: mega64,
    );
  }
}

int _sink = 0;

@pragma('vm:prefer-inline')
int _eatText(String s) => s.length + s.codeUnitAt(s.length - 1);

/// Runs all 20 benchmark cases and returns `BENCH {json}` lines.
List<String> runBenchmarks({
  String target = 'dart',
  String filter = '',
  int batches = 9,
  int batchMs = 60,
  int warmMs = 300,
}) {
  final f = BenchFixtures();

  final dPlain = format('d');
  final dGrouped = format(',d');
  final dZeroPadGroup = format('+012,d');
  final fFixed2 = format('.2f');
  final fCurrency = format(r'+$,.2f');
  final fAccounting = format(r'($,.2f');
  final eExp = format('.3e');
  final eTrim = format('.4~e');
  final gGeneral = format('.6g');
  final noneDefault = format('');
  final sSiPrefix = format('.3s');
  final sSiTrim = format('~s');
  final prefixFixedM = formatPrefix(',.2', 1e6);
  final pctPercent = format('.1%');
  final hexPrefix = format('#010x');
  final locFr = formatLocale(localeFrFR).format(r'$,.2f');
  final locIn = formatLocale(localeEnIN).format(r'$,.2f');
  final locAr = formatLocale(localeArAE).format(r'$,.2f');

  final cases = <String, void Function(int n)>{
    'parse.specifier16': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final spec in f.specifiers16) {
          final parsed = formatSpecifier(spec);
          s +=
              (parsed.width ?? 0) +
              (parsed.precision ?? 0) +
              parsed.type.length;
        }
      }
      _sink += s;
    },
    'compile.format16': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final spec in f.specifiers16) {
          final fn = format(spec);
          s += fn.specifier.align.codeUnitAt(0);
        }
      }
      _sink += s;
    },
    'd.plain64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.ints64) {
          s += _eatText(dPlain(v));
        }
      }
      _sink += s;
    },
    'd.grouped64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.ints64) {
          s += _eatText(dGrouped(v));
        }
      }
      _sink += s;
    },
    'd.zeroPadGroup64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.ints64) {
          s += _eatText(dZeroPadGroup(v));
        }
      }
      _sink += s;
    },
    'f.fixed2_64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.floats64) {
          s += _eatText(fFixed2(v));
        }
      }
      _sink += s;
    },
    'f.currency64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.floats64) {
          s += _eatText(fCurrency(v));
        }
      }
      _sink += s;
    },
    'f.accounting64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.floats64) {
          s += _eatText(fAccounting(v));
        }
      }
      _sink += s;
    },
    'e.exp64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.wide64) {
          s += _eatText(eExp(v));
        }
      }
      _sink += s;
    },
    'e.trim64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.trim64) {
          s += _eatText(eTrim(v));
        }
      }
      _sink += s;
    },
    'g.general64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.wide64) {
          s += _eatText(gGeneral(v));
        }
      }
      _sink += s;
    },
    'none.default64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.trim64) {
          s += _eatText(noneDefault(v));
        }
      }
      _sink += s;
    },
    's.siPrefix64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.wide64) {
          s += _eatText(sSiPrefix(v));
        }
      }
      _sink += s;
    },
    's.siTrim64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.trim64) {
          s += _eatText(sSiTrim(v));
        }
      }
      _sink += s;
    },
    'prefix.fixedM64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.mega64) {
          s += _eatText(prefixFixedM(v));
        }
      }
      _sink += s;
    },
    'pct.percent64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.ratios64) {
          s += _eatText(pctPercent(v));
        }
      }
      _sink += s;
    },
    'hex.prefix64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.hex64) {
          s += _eatText(hexPrefix(v));
        }
      }
      _sink += s;
    },
    'locale.frFR64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.floats64) {
          s += _eatText(locFr(v));
        }
      }
      _sink += s;
    },
    'locale.enIN64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.floats64) {
          s += _eatText(locIn(v));
        }
      }
      _sink += s;
    },
    'locale.arAE64': (n) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        for (final v in f.floats64) {
          s += _eatText(locAr(v));
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
