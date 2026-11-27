// Original code, not ported from d3-time-format: the benchmark of the port.

/// The d3-time-format benchmark of the Dart port: 14 seeded workloads matching
/// `d3_time_format_bench.mjs` (upstream d3-time-format v4.1.0 in Node.js) with
/// identical Park-Miller LCG timestamps.
///
/// Run as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android, and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'package:flutter_d3_time_format_port/d3_time_format.dart';

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

const List<String> _zoneSuffixes = ['+05:30', '-0800', 'Z', '+02', '-0430'];

/// Seeded benchmark datasets.
final class BenchFixtures._({
  required final List<DateTime> utcDates1000,
  required final List<DateTime> localDates1000,
  required final List<String> isoStrings1000,
  required final List<String> ymdStrings1000,
  required final List<String> zoneStrings1000,
  required final List<String> wordStrings1000,
  required final List<String> localeCStrings1000,
  required final List<String> frWordStrings1000,
}) {
  factory() {
    final r = Lcg(42);
    const spanMs = 80 * 365 * 86400 * 1000;
    final utcDates1000 = List<DateTime>.generate(
      1000,
      (_) => DateTime.fromMillisecondsSinceEpoch(
        (r.nextDouble() * spanMs).floor(),
        isUtc: true,
      ),
      growable: false,
    );
    final localDates1000 = List<DateTime>.generate(
      1000,
      (i) => utcDates1000[i].toLocal(),
      growable: false,
    );

    final fmtIso = utcFormat('%Y-%m-%dT%H:%M:%S.%LZ');
    final fmtYmd = utcFormat('%Y-%m-%d');
    final fmtYmdHms = utcFormat('%Y-%m-%d %H:%M:%S');
    final fmtWords = utcFormat('%a, %d %b %Y %H:%M:%S');
    final fmtC = utcFormat('%c');
    final fr = timeFormatLocale(timeLocaleFrFR);
    final fmtFr = fr.utcFormat('%A %e %B %Y à %X');

    final isoStrings1000 = List<String>.generate(
      1000,
      (i) => fmtIso(utcDates1000[i]),
      growable: false,
    );
    final ymdStrings1000 = List<String>.generate(
      1000,
      (i) => fmtYmd(utcDates1000[i]),
      growable: false,
    );
    final zoneStrings1000 = List<String>.generate(
      1000,
      (i) =>
          '${fmtYmdHms(utcDates1000[i])} '
          '${_zoneSuffixes[i % _zoneSuffixes.length]}',
      growable: false,
    );
    final wordStrings1000 = List<String>.generate(
      1000,
      (i) => fmtWords(utcDates1000[i]),
      growable: false,
    );
    final localeCStrings1000 = List<String>.generate(
      1000,
      (i) => fmtC(utcDates1000[i]),
      growable: false,
    );
    final frWordStrings1000 = List<String>.generate(
      1000,
      (i) => fmtFr(utcDates1000[i]),
      growable: false,
    );

    return BenchFixtures._(
      utcDates1000: utcDates1000,
      localDates1000: localDates1000,
      isoStrings1000: isoStrings1000,
      ymdStrings1000: ymdStrings1000,
      zoneStrings1000: zoneStrings1000,
      wordStrings1000: wordStrings1000,
      localeCStrings1000: localeCStrings1000,
      frWordStrings1000: frWordStrings1000,
    );
  }
}

int _sink = 0;

/// Runs all 14 d3-time-format benchmark cases and returns `BENCH {json}` lines.
List<String> runBenchmarks({
  String target = 'dart',
  String filter = '',
  int batches = 9,
  int batchMs = 60,
  int warmMs = 300,
}) {
  final f = BenchFixtures();
  final utcDates = f.utcDates1000;
  final localDates = f.localDates1000;
  final isoStrs = f.isoStrings1000;
  final ymdStrs = f.ymdStrings1000;
  final zoneStrs = f.zoneStrings1000;
  final wordStrs = f.wordStrings1000;
  final cStrs = f.localeCStrings1000;
  final frStrs = f.frWordStrings1000;

  final fmtIso = utcFormat('%Y-%m-%dT%H:%M:%S.%LZ');
  final fmtYmd = utcFormat('%Y-%m-%d');
  final fmtC = utcFormat('%c');
  final fmtWords = utcFormat('%A, %B %e, %Y');
  final fmtWeeks = utcFormat('%G-W%V-%u %j %U %W');
  final fmtLocal = timeFormat('%Y-%m-%d %H:%M:%S %Z');

  final parseIsoSpec = utcParse('%Y-%m-%dT%H:%M:%S.%LZ');
  final parseYmd = utcParse('%Y-%m-%d');
  final parseZone = utcParse('%Y-%m-%d %H:%M:%S %Z');
  final parseWords = utcParse('%a, %d %b %Y %H:%M:%S');
  final parseC = utcParse('%c');
  final parseFr = timeFormatLocale(timeLocaleFrFR).utcParse('%A %e %B %Y à %X');

  final cases = <String, void Function(int)>{
    'utcFormat.iso_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < utcDates.length; ++j) {
          s += fmtIso(utcDates[j]).codeUnitAt(18);
        }
      }
      _sink += s;
    },
    'utcFormat.ymd_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < utcDates.length; ++j) {
          s += fmtYmd(utcDates[j]).codeUnitAt(9);
        }
      }
      _sink += s;
    },
    'utcFormat.locale_c_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < utcDates.length; ++j) {
          s += fmtC(utcDates[j]).length;
        }
      }
      _sink += s;
    },
    'utcFormat.words_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < utcDates.length; ++j) {
          s += fmtWords(utcDates[j]).length;
        }
      }
      _sink += s;
    },
    'utcFormat.weeks_doy_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < utcDates.length; ++j) {
          s += fmtWeeks(utcDates[j]).length;
        }
      }
      _sink += s;
    },
    'timeFormat.local_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < localDates.length; ++j) {
          s += fmtLocal(localDates[j]).codeUnitAt(24);
        }
      }
      _sink += s;
    },
    'isoFormat.1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < utcDates.length; ++j) {
          s += isoFormat(utcDates[j]).codeUnitAt(18);
        }
      }
      _sink += s;
    },
    'utcParse.iso_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < isoStrs.length; ++j) {
          s += parseIsoSpec(isoStrs[j])!.millisecondsSinceEpoch;
        }
      }
      _sink += s;
    },
    'utcParse.ymd_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < ymdStrs.length; ++j) {
          s += parseYmd(ymdStrs[j])!.millisecondsSinceEpoch;
        }
      }
      _sink += s;
    },
    'utcParse.zone_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < zoneStrs.length; ++j) {
          s += parseZone(zoneStrs[j])!.millisecondsSinceEpoch;
        }
      }
      _sink += s;
    },
    'utcParse.words_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < wordStrs.length; ++j) {
          s += parseWords(wordStrs[j])!.millisecondsSinceEpoch;
        }
      }
      _sink += s;
    },
    'utcParse.locale_c_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < cStrs.length; ++j) {
          s += parseC(cStrs[j])!.millisecondsSinceEpoch;
        }
      }
      _sink += s;
    },
    'utcParse.fr_words_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < frStrs.length; ++j) {
          s += parseFr(frStrs[j])!.millisecondsSinceEpoch;
        }
      }
      _sink += s;
    },
    'isoParse.1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < isoStrs.length; ++j) {
          s += isoParse(isoStrs[j])!.millisecondsSinceEpoch;
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
