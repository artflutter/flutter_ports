// Original code, not ported from d3-time: the benchmark of the port.

/// The d3-time benchmark of the Dart port: 14 seeded workloads matching
/// `d3_time_bench.mjs` (upstream d3-time v3.1.0 in Node.js) with identical
/// Park-Miller LCG timestamps.
///
/// Run as AOT (`dart compile exe`), JS (`dart compile js -O4`), Wasm
/// (`dart compile wasm -O2`), or inside a Flutter release app on macOS,
/// Android, and iOS. Each case prints `BENCH {json}` with median ns/op.
library;

// The benchmark prints its results.
// ignore_for_file: avoid_print

import 'package:flutter_d3_time_port/d3_time.dart';

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
  required final List<DateTime> utcDates1000,
  required final List<DateTime> utcDatesB1000,
  required final List<(DateTime, DateTime, int)> utcTickSpans,
  required final List<(DateTime, DateTime, int)> localTickSpans,
}) {
  factory() {
    final r = Lcg(42);
    // Span 1970..2050 (~80 years) in epoch milliseconds.
    const spanMs = 80 * 365 * 86400 * 1000;
    final utcDates1000 = List<DateTime>.generate(
      1000,
      (_) => DateTime.fromMillisecondsSinceEpoch(
        (r.nextDouble() * spanMs).floor(),
        isUtc: true,
      ),
      growable: false,
    );
    final utcDatesB1000 = List<DateTime>.generate(
      1000,
      (_) => DateTime.fromMillisecondsSinceEpoch(
        (r.nextDouble() * spanMs).floor(),
        isUtc: true,
      ),
      growable: false,
    );

    final utcTickSpans = <(DateTime, DateTime, int)>[
      (DateTime.utc(2024, 1, 1, 12), DateTime.utc(2024, 1, 1, 12, 0, 1), 5),
      (DateTime.utc(2024, 1, 1, 12), DateTime.utc(2024, 1, 1, 12, 0, 30), 6),
      (DateTime.utc(2024, 1, 1, 12), DateTime.utc(2024, 1, 1, 12, 5), 5),
      (DateTime.utc(2024, 1, 1, 12), DateTime.utc(2024, 1, 1, 12, 45), 6),
      (DateTime.utc(2024, 1, 1, 12), DateTime.utc(2024, 1, 1, 18), 6),
      (DateTime.utc(2024), DateTime.utc(2024, 1, 3), 8),
      (DateTime.utc(2024), DateTime.utc(2024, 1, 15), 7),
      (DateTime.utc(2024), DateTime.utc(2024, 2, 15), 6),
      (DateTime.utc(2024), DateTime.utc(2024, 7), 6),
      (DateTime.utc(2024), DateTime.utc(2025, 6), 6),
      (DateTime.utc(2020), DateTime.utc(2026), 6),
      (DateTime.utc(1990), DateTime.utc(2025), 7),
      (DateTime.utc(1800), DateTime.utc(2025), 8),
      (DateTime.utc(2025), DateTime.utc(2024), 6),
      (DateTime.utc(2024, 6, 15, 10, 30), DateTime.utc(2024, 6, 15, 14, 45), 8),
      (DateTime.utc(2024, 3), DateTime.utc(2024, 3, 31), 10),
    ];

    final localTickSpans = <(DateTime, DateTime, int)>[
      for (final (a, b, c) in utcTickSpans)
        (
          DateTime(a.year, a.month, a.day, a.hour, a.minute, a.second),
          DateTime(b.year, b.month, b.day, b.hour, b.minute, b.second),
          c,
        ),
    ];

    return BenchFixtures._(
      utcDates1000: utcDates1000,
      utcDatesB1000: utcDatesB1000,
      utcTickSpans: utcTickSpans,
      localTickSpans: localTickSpans,
    );
  }
}

int _sink = 0;

/// Runs all 14 d3-time benchmark cases and returns `BENCH {json}` lines.
List<String> runBenchmarks({
  String target = 'dart',
  String filter = '',
  int batches = 9,
  int batchMs = 60,
  int warmMs = 300,
}) {
  final f = BenchFixtures();
  final dates = f.utcDates1000;
  final datesB = f.utcDatesB1000;
  final utcSpans = f.utcTickSpans;
  final localSpans = f.localTickSpans;

  final u2024 = DateTime.utc(2024);
  final u2025 = DateTime.utc(2025);
  final u2024Feb = DateTime.utc(2024, 2);
  final u2024Jan2 = DateTime.utc(2024, 1, 2);
  final u2015 = DateTime.utc(2015);
  final u1975 = DateTime.utc(1975);
  final l2024 = DateTime(2024);
  final l2025 = DateTime(2025);

  final cases = <String, void Function(int)>{
    'utcSecond.fcr_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < dates.length; ++j) {
          final d = dates[j];
          s +=
              utcSecond.floor(d).millisecondsSinceEpoch +
              utcSecond.ceil(d).millisecondsSinceEpoch +
              utcSecond.round(d).millisecondsSinceEpoch;
        }
      }
      _sink += s;
    },
    'utcMinute.fcr_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < dates.length; ++j) {
          final d = dates[j];
          s +=
              utcMinute.floor(d).millisecondsSinceEpoch +
              utcMinute.ceil(d).millisecondsSinceEpoch +
              utcMinute.round(d).millisecondsSinceEpoch;
        }
      }
      _sink += s;
    },
    'utcHour.fcr_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < dates.length; ++j) {
          final d = dates[j];
          s +=
              utcHour.floor(d).millisecondsSinceEpoch +
              utcHour.ceil(d).millisecondsSinceEpoch +
              utcHour.round(d).millisecondsSinceEpoch;
        }
      }
      _sink += s;
    },
    'utcDay.fcr_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < dates.length; ++j) {
          final d = dates[j];
          s +=
              utcDay.floor(d).millisecondsSinceEpoch +
              utcDay.ceil(d).millisecondsSinceEpoch +
              utcDay.round(d).millisecondsSinceEpoch;
        }
      }
      _sink += s;
    },
    'utcWeek.fcr_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < dates.length; ++j) {
          final d = dates[j];
          s +=
              utcWeek.floor(d).millisecondsSinceEpoch +
              utcWeek.ceil(d).millisecondsSinceEpoch +
              utcWeek.round(d).millisecondsSinceEpoch;
        }
      }
      _sink += s;
    },
    'utcDay.range_366': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        final r = utcDay.range(u2024, u2025);
        s += r.length + r.last.millisecondsSinceEpoch;
      }
      _sink += s;
    },
    'utcHour.range_744': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        final r = utcHour.range(u2024, u2024Feb);
        s += r.length + r.last.millisecondsSinceEpoch;
      }
      _sink += s;
    },
    'utcMinute.range_1440': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        final r = utcMinute.range(u2024, u2024Jan2);
        s += r.length + r.last.millisecondsSinceEpoch;
      }
      _sink += s;
    },
    'utcWeek.range_522': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        final r = utcWeek.range(u2015, u2025);
        s += r.length + r.last.millisecondsSinceEpoch;
      }
      _sink += s;
    },
    'utcMonth.range_600': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        final r = utcMonth.range(u1975, u2025);
        s += r.length + r.last.millisecondsSinceEpoch;
      }
      _sink += s;
    },
    'timeDay.range_366': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        final r = timeDay.range(l2024, l2025);
        s += r.length + r.last.millisecondsSinceEpoch;
      }
      _sink += s;
    },
    'utc.count_offset_1000': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < dates.length; ++j) {
          final a = dates[j];
          final b = datesB[j];
          s +=
              utcDay.count(a, b) +
              utcWeek.count(a, b) +
              utcHour.offset(a, 5).millisecondsSinceEpoch;
        }
      }
      _sink += s;
    },
    'utcTicks.batch_16': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < utcSpans.length; ++j) {
          final (a, b, c) = utcSpans[j];
          final t = utcTicks(a, b, c);
          s += t.length;
        }
      }
      _sink += s;
    },
    'timeTicks.batch_16': (n) {
      var s = 0;
      for (var i = 0; i < n; ++i) {
        for (var j = 0; j < localSpans.length; ++j) {
          final (a, b, c) = localSpans[j];
          final t = timeTicks(a, b, c);
          s += t.length;
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
