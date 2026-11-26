// Original code, not ported from d3-scale-chromatic: the benchmark of the port.

/// The d3-scale-chromatic benchmark of the Dart port: the cases of
/// `d3_scale_chromatic_bench.mjs` (upstream d3-scale-chromatic in Node.js)
/// with the same inputs.
///
/// Run it as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// Park-Miller LCG: exact in JS numbers and Dart.
final class Lcg(var int seed) {
  /// Creates an LCG with [seed].
  this;

  /// Next integer in `[0, n)`.
  int next(int n) {
    seed = seed * 48271 % 2147483647;
    return seed % n;
  }
}

const int _pool = 1024;
const int _m = _pool - 1;

const String _spec10 =
    '1f77b4ff7f0e2ca02cd627289467bd8c564be377c27f7f7fbcbd2217becf';

const String _spec256 =
    '44015444025645045745055946075a46085c460a5d460b5e470d60470e61471063471164'
    '47136548146748166848176948186a481a6c481b6d481c6e481d6f481f70482071482173'
    '482374482475482576482677482878482979472a7a472c7a472d7b472e7c472f7d46307e'
    '46327e46337f463480453581453781453882443983443a83443b84433d84433e85423f85'
    '4240864241864142874144874045884046883f47883f48893e49893e4a893e4c8a3d4d8a'
    '3d4e8a3c4f8a3c508b3b518b3b528b3a538b3a548c39558c39568c38588c38598c375a8c'
    '375b8d365c8d365d8d355e8d355f8d34608d34618d33628d33638d32648e32658e31668e'
    '31678e31688e30698e306a8e2f6b8e2f6c8e2e6d8e2e6e8e2e6f8e2d708e2d718e2c718e'
    '2c728e2c738e2b748e2b758e2a768e2a778e2a788e29798e297a8e297b8e287c8e287d8e'
    '277e8e277f8e27808e26818e26828e26828e25838e25848e25858e24868e24878e23888e'
    '23898e238a8d228b8d228c8d228d8d218e8d218f8d21908d21918c20928c20928c20938c'
    '1f948c1f958b1f968b1f978b1f988b1f998a1f9a8a1e9b8a1e9c891e9d891f9e891f9f88'
    '1fa0881fa1881fa1871fa28720a38620a48621a58521a68522a78522a88423a98324aa83'
    '25ab8225ac8226ad8127ad8128ae8029af7f2ab07f2cb17e2db27d2eb37c2fb47c31b57b'
    '32b67a34b67935b77937b87838b9773aba763bbb753dbc743fbc7340bd7242be7144bf70'
    '46c06f48c16e4ac16d4cc26c4ec36b50c46a52c56954c56856c66758c7655ac8645cc863'
    '5ec96260ca6063cb5f65cb5e67cc5c69cd5b6ccd5a6ece5870cf5773d05675d05477d153'
    '7ad1517cd2507fd34e81d34d84d44b86d54989d5488bd6468ed64590d74393d74195d840'
    '98d83e9bd93c9dd93ba0da39a2da37a5db36a8db34aadc32addc30b0dd2fb2dd2db5de2b'
    'b8de29bade28bddf26c0df25c2df23c5e021c8e020cae11fcde11dd0e11cd2e21bd5e21a'
    'd8e219dae319dde318dfe318e2e418e5e419e7e419eae51aece51befe51cf1e51df4e61e'
    'f6e620f8e621fbe723fde725';

double _sink = 0;

/// Runs all benchmark cases and returns the formatted `BENCH` lines.
List<String> runBenchmarks({
  String target = 'dart',
  String filter = '',
  int batches = 9,
  int batchMs = 60,
  int warmMs = 300,
}) {
  final r = Lcg(42);
  final ts = Float64List(_pool);
  final tsWrap = Float64List(_pool);
  for (var i = 0; i < _pool; i++) {
    final t = r.next(1001) / 1000;
    ts[i] = t;
    tsWrap[i] = t * 5 - 2;
  }

  double eatRgb(Rgb c) => c.r + c.g + c.b;
  double eatCube(Cubehelix c) => c.h + c.s + c.l;
  double eatText(String s) => s.length.toDouble() + s.codeUnitAt(s.length - 1);

  final cases = <String, void Function(int)>{
    'call.viridis': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatRgb(interpolateViridis(ts[(i * 7) & _m]));
      }
      _sink += s;
    },
    'call.magma': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatRgb(interpolateMagma(ts[(i * 7) & _m]));
      }
      _sink += s;
    },
    'call.turbo': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatRgb(interpolateTurbo(ts[(i * 7) & _m]));
      }
      _sink += s;
    },
    'call.cividis': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatRgb(interpolateCividis(ts[(i * 7) & _m]));
      }
      _sink += s;
    },
    'call.sinebow': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatRgb(interpolateSinebow(ts[(i * 7) & _m]));
      }
      _sink += s;
    },
    'call.rainbow': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatCube(interpolateRainbow(ts[(i * 7) & _m]));
      }
      _sink += s;
    },
    'call.rainbowWrap': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatCube(interpolateRainbow(tsWrap[(i * 7) & _m]));
      }
      _sink += s;
    },
    'call.warm': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatCube(interpolateWarm(ts[(i * 7) & _m]));
      }
      _sink += s;
    },
    'call.cubehelixDefault': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatCube(interpolateCubehelixDefault(ts[(i * 7) & _m]));
      }
      _sink += s;
    },
    'call.brBG': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatRgb(interpolateBrBG(ts[(i * 7) & _m]));
      }
      _sink += s;
    },
    'call.blues': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatRgb(interpolateBlues(ts[(i * 7) & _m]));
      }
      _sink += s;
    },
    'text.viridis': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatText(interpolateViridis(ts[(i * 7) & _m]).formatHex());
      }
      _sink += s;
    },
    'text.turbo': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatText(interpolateTurbo(ts[(i * 7) & _m]).toString());
      }
      _sink += s;
    },
    'text.sinebow': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatText(interpolateSinebow(ts[(i * 7) & _m]).toString());
      }
      _sink += s;
    },
    'text.rainbow': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatText(interpolateRainbow(ts[(i * 7) & _m]).toString());
      }
      _sink += s;
    },
    'text.brBG': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += eatText(interpolateBrBG(ts[(i * 7) & _m]).toString());
      }
      _sink += s;
    },
    'parse.colors10': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        final list = colors(_spec10);
        s += list[i & 7].r;
      }
      _sink += s;
    },
    'parse.colors256': (n) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        final list = colors(_spec256);
        s += list[i & 255].r;
      }
      _sink += s;
    },
  };

  final lines = <String>[];
  final sw = Stopwatch()..start();
  final targetUs = batchMs * 250; // batchMs / 4 in us -> 15..30 ms per batch

  for (final entry in cases.entries) {
    if (filter.isNotEmpty && !entry.key.contains(filter)) continue;
    final fn = entry.value;

    // Warmup & auto-calibrate ops per batch.
    var ops = 64;
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
  if (_sink == -1.23456789) print(_sink);
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
