// Original code, not ported from Chart.js: the micro-benchmark entry.

/// Core micro-benchmarks, including native Flutter Color operations.
/// Run through `flutter test tool/bench/bench_flutter_test.dart` with the
/// `filter`, `batches`, `batch_ms`, `warmup_ms` and `target` Dart defines.
/// Standalone `dart run`/`dart compile` no longer apply (ADR 0061).
/// Release application benchmarks remain in the gallery's main_bench.dart.
library;

import 'src/cases_data.dart';
import 'src/cases_helpers.dart';
import 'src/cases_resolver.dart';
import 'src/cases_runtime.dart';
import 'src/harness.dart';

void main(List<String> args) {
  runBench([
    ...resolverCases(),
    ...runtimeCases(),
    ...helperCases(),
    ...dataCases(),
  ], parseSettings(args));
}
