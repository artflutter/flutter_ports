// Original code, not ported from Chart.js: the micro-benchmark entry.

/// `dart run packages/flutter_chartjs/tool/bench/bench.dart`: the
/// micro-benchmarks of the pure layers (`lib/src/js/`, `lib/src/helpers/`,
/// `lib/src/core/core.defaults.dart` and `core.ticks`, `@kurkle/color`).
///
/// It prints one JSON line per case. The arguments are `--filter=<regexp>`,
/// `--batches=`, `--batch-ms=`, `--warmup-ms=` and `--target=`. The web
/// builds take the same settings as compile-time defines: `-Dfilter=`,
/// `-Dbatches=`, `-Dbatch_ms=`, `-Dwarmup_ms=` and `-Dtarget=`. The file
/// imports no `dart:io`, so `dart compile exe`, `dart compile js` and
/// `dart compile wasm` all build it:
///
/// ```sh
/// B=packages/flutter_chartjs/tool/bench/bench.dart
/// dart run $B --filter=resolver                    # VM JIT
/// dart compile exe $B -o bench && ./bench          # VM AOT
/// dart compile js -O4 -Dtarget=dart2js-O4 $B -o bench.js && node bench.js
/// dart compile wasm -O2 $B -o bench.wasm           # then run bench.mjs
/// ```
///
/// dart2wasm writes `bench.mjs` next to `bench.wasm`. In Node.js, import
/// it, `compile` the bytes, `instantiate` and call `invokeMain(...args)`.
///
/// `_getStartAndCountOfVisiblePoints` (`helpers.extras`) imports
/// `package:flutter`. Its case is in `bench_flutter_test.dart`.
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
