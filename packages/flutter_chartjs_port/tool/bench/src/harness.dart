// Original code, not ported from Chart.js: the micro-benchmark harness.

/// The timing loop of `tool/bench/`: warm-up, calibration, timed batches,
/// and one JSON line per case.
///
/// The harness imports no `dart:io`, so the VM (JIT and AOT), dart2js and
/// dart2wasm compile it. Each case body runs `n` operations and returns an
/// `int` that the harness keeps in a sink, so that no compiler removes the
/// work.
library;

import 'dart:convert';

/// One benchmark case.
final class BenchCase {
  /// A case [name] in [group]. [setup] runs once, outside the timing, and
  /// returns the body. The body runs `n` operations and returns a checksum.
  /// One operation handles [items] items, for example 1,000 points.
  BenchCase(
    this.group,
    this.name,
    this.setup, {
    this.items = 1,
    this.per = 'op',
  });

  /// The group, for example `resolver`.
  final String group;

  /// The case name, unique in the suite, for example `resolver/warm_10`.
  final String name;

  /// Returns the body. Runs outside the timing.
  final int Function(int n) Function() setup;

  /// The items in one operation.
  final int items;

  /// What one operation does, for the report.
  final String per;
}

/// The settings of one run.
final class BenchSettings {
  /// The settings of one run.
  const BenchSettings({
    required this.target,
    this.filter,
    this.batches = 15,
    this.batchMs = 20,
    this.warmupMs = 300,
  });

  /// The compile target, for example `vm-jit` or `dart2wasm-O2`.
  final String target;

  /// A pattern on the case names. Null runs every case.
  final RegExp? filter;

  /// The timed batches of each case.
  final int batches;

  /// The target duration of one batch, in milliseconds.
  final int batchMs;

  /// The warm-up of each case, in milliseconds.
  final int warmupMs;
}

/// The sink of the checksums.
int _sink = 0;

/// Runs [cases] with [settings] and prints one JSON line for each case, and
/// a first line with the settings.
void runBench(List<BenchCase> cases, BenchSettings settings) {
  final names = <String>{};
  for (final c in cases) {
    if (!names.add(c.name)) throw StateError('duplicate case ${c.name}');
  }
  _emit({
    'meta': 'bench',
    'target': settings.target,
    'batches': settings.batches,
    'batch_ms': settings.batchMs,
    'warmup_ms': settings.warmupMs,
    'filter': settings.filter?.pattern,
    'started': DateTime.now().toUtc().toIso8601String(),
  });
  final filter = settings.filter;
  for (final c in cases) {
    if (filter != null && !filter.hasMatch(c.name)) continue;
    _emit(_measure(c, settings));
  }
  _emit({'meta': 'end', 'target': settings.target, 'sink': _sink & 0xffff});
}

Map<String, Object?> _measure(BenchCase c, BenchSettings settings) {
  final body = c.setup();
  final watch = Stopwatch()..start();

  // Warm-up and calibration: call the body until the warm-up time is over,
  // and double n while one call takes less than a tenth of a batch. The
  // last call, after the warm-up, gives the time of one operation. The
  // first calls include the JIT compilation, so they do not calibrate.
  var n = 1;
  final warmupUs = settings.warmupMs * 1000;
  final batchUs = settings.batchMs * 1000;
  double perOp;
  while (true) {
    final start = watch.elapsedMicroseconds;
    _sink ^= body(n);
    final elapsed = watch.elapsedMicroseconds - start;
    if (elapsed * 10 < batchUs && n < 1 << 30) {
      n *= 2;
    } else if (watch.elapsedMicroseconds >= warmupUs) {
      perOp = elapsed / n;
      break;
    }
  }
  var batchN = (batchUs / perOp).round();
  if (batchN < 1) batchN = 1;

  final samples = <double>[];
  for (var b = 0; b < settings.batches; b++) {
    final start = watch.elapsedMicroseconds;
    _sink ^= body(batchN);
    final elapsed = watch.elapsedMicroseconds - start;
    samples.add(elapsed * 1000 / batchN);
  }
  samples.sort();
  final median = _percentile(samples, 0.5);
  final p90 = _percentile(samples, 0.9);
  return {
    'target': settings.target,
    'group': c.group,
    'case': c.name,
    'per': c.per,
    'items': c.items,
    'n': batchN,
    'batches': settings.batches,
    'median_ns': _round(median),
    'p90_ns': _round(p90),
    'min_ns': _round(samples.first),
    'median_ns_per_item': _round(median / c.items),
  };
}

/// The nearest-rank percentile [p] of the sorted [samples].
double _percentile(List<double> samples, double p) {
  final rank = (p * samples.length).ceil() - 1;
  return samples[rank.clamp(0, samples.length - 1)];
}

/// Three significant decimals.
double _round(double x) => (x * 1000).roundToDouble() / 1000;

void _emit(Map<String, Object?> line) {
  // The harness runs on the web too, where dart:io does not exist.
  // ignore: avoid_print
  print(jsonEncode(line));
}

/// The compile target of this program: `dart2wasm`, `dart2js`, `vm-aot` or
/// `vm-jit`.
String detectTarget() {
  if (const bool.fromEnvironment('dart.tool.dart2wasm')) return 'dart2wasm';
  if (const bool.fromEnvironment('dart.library.js_interop')) return 'dart2js';
  if (const bool.fromEnvironment('dart.vm.product')) return 'vm-aot';
  return 'vm-jit';
}

/// The settings from [args] (`--filter=`, `--batches=`, `--batch-ms=`,
/// `--warmup-ms=`, `--target=`), else from the compile-time defines of the
/// same names (`-Dfilter=`, `-Dbatches=`, `-Dbatch_ms=`, `-Dwarmup_ms=`,
/// `-Dtarget=`).
BenchSettings parseSettings(List<String> args) {
  String? arg(String name) {
    for (final a in args) {
      if (a.startsWith('--$name=')) return a.substring(name.length + 3);
    }
    return null;
  }

  const defineFilter = String.fromEnvironment('filter');
  const defineTarget = String.fromEnvironment('target');
  const defineBatches = int.fromEnvironment('batches', defaultValue: 15);
  const defineBatchMs = int.fromEnvironment('batch_ms', defaultValue: 20);
  const defineWarmupMs = int.fromEnvironment('warmup_ms', defaultValue: 300);

  final filter = arg('filter') ?? defineFilter;
  final target =
      arg('target') ?? (defineTarget.isEmpty ? detectTarget() : defineTarget);
  return BenchSettings(
    target: target,
    filter: filter.isEmpty ? null : RegExp(filter),
    batches: int.tryParse(arg('batches') ?? '') ?? defineBatches,
    batchMs: int.tryParse(arg('batch-ms') ?? '') ?? defineBatchMs,
    warmupMs: int.tryParse(arg('warmup-ms') ?? '') ?? defineWarmupMs,
  );
}
