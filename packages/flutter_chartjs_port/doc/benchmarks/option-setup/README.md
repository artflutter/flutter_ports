# Option setup and owned results: estimation and implementation

2026-11-04. [ADR 0081](../../adr/0081-option-resolution-setup.md).
Baseline: the working tree after ADR 0080, including the preceding uncommitted
optimizations. Native Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7,
profile AOT, Impeller MetalSDF. These gains are additional to the preceding pass.

The combined production change reduces scriptable line full-update CPU cost by
approximately **8–10%** in these runs. It does **not** reach 60 FPS for all modes.

## What was estimated

Four variants run in an isolated copy: instrumented baseline, setup only,
allocation only, and both. Setup reuses native default-key snapshots, private
prefix lists and the last joined scope-key string, and matches immutable key
snapshots by identity. Allocation replaces discarded temporary PointOptions/
BarOptions with private read-only type tokens, allocating the final result only.

A separate baseline build contains neither optimization. This matters because
the prototype's runtime switches and additional branches have their own cost.
The estimation order is clean A1, prototype B1, prototype B2 with variant order
reversed, clean A2. Each cell uses 700 ms warmup and seven calibrated batches of
approximately 160 ms. Each result below averages two process medians.

20,000-item scriptable line, full CPU in milliseconds:

| Variant | Disconnected ms | Connected ms |
| --- | ---: | ---: |
| clean baseline | 27.12 | 29.00 |
| instrumented baseline | 28.02 | 29.22 |
| setup | 26.17 | 28.10 |
| allocation | 27.28 | 29.06 |
| both | 24.50 | 26.36 |

Against the clean baseline, setup alone saves about 3–4%; allocation alone has
no clear standalone gain. Together they save about 9–10%. Combined measurements,
not added percentages, justify implementing both. The instrumented baseline
shows the estimation overhead rather than concealing it.

These are CPU timings, not allocation counts. Full CPU means the sum of update,
draw and paint-end component medians, not a percentile of the combined call.
Data movement is outside the CPU stopwatches. No profiler, assistant build or
test runs alongside the measured processes.

## Production implementation

- Exact native PointOptionsScope/BarOptionsScope producers provide immutable
  own-key snapshots. Structural writes/deletes and state restore invalidate
  them; existing public key-list methods still return their normal copies.
- Controllers retain private prefixes only for exact Config instances. Custom
  Configs retain the existing virtual method signature and fresh input lists.
  Custom key producers still enumerate at their original call sites.
- Scope-key string conversion and global lookup remain live; only the last
  joined string is retained, including its original collision behavior.
- Prepared result paths read private frozen point/bar type tokens. They never
  write or return those tokens. A fallback allocates a fresh ordinary result
  and preserves an already-created context, including nested resolution.
- Option values, scope reads, callback execution and ordinary invalidation
  remain live. No sampling, callback-result cache or rendering change is added.

The production build has no experiment switches. Only its new owned-result
entry receives an immutable-key proof; legacy virtual method signatures remain
unchanged. Production was built from an isolated source copy whose four changed
runtime files match the delivered files by SHA-256.

## Production A/B/B/A comparison

800×480/DPR1. Line uses 20,000 items; scatter and bar controls use 5,000.
Each of A1/B1/B2/A2 runs line, then scatter and bar, in separate processes with
the same warmup/batch settings as above. Negative reduction means slower.

| Type / items | Colors | Connected | Before ms | After ms | Reduction |
| --- | --- | --- | ---: | ---: | ---: |
| line / 20000 | static | off | 5.40 | 4.94 | 8.7% |
| line / 20000 | static | on | 6.71 | 6.66 | 0.7% |
| line / 20000 | indexed | off | 13.30 | 13.66 | -2.7% |
| line / 20000 | indexed | on | 15.72 | 15.51 | 1.3% |
| line / 20000 | scriptable | off | 27.13 | 24.45 | 9.9% |
| line / 20000 | scriptable | on | 28.37 | 26.01 | 8.3% |
| scatter / 5000 | static | off | 1.98 | 2.03 | -2.6% |
| scatter / 5000 | indexed | off | 4.31 | 4.21 | 2.3% |
| scatter / 5000 | scriptable | off | 14.26 | 11.99 | 15.9% |
| bar / 5000 | static | off | 3.91 | 3.86 | 1.2% |
| bar / 5000 | indexed | off | 4.73 | 4.80 | -1.6% |
| bar / 5000 | scriptable | off | 11.12 | 10.34 | 7.0% |

The unconnected scriptable line has noticeable process variation; individual
runs and paired reductions are retained in production-summary.json. The table
reports averages, not statistical confidence bounds. Static and indexed rows
are controls; no speed claim is made for them. Scriptable scatter and bar also
benefit from the shared resolver changes.

## Matched frame comparison

Each build runs the same 16 cases: full update/data-only × indexed/scriptable ×
connections off/on × 0/200 labels, all at 20,000 items. The ordinary StressDemo
runs at 1036×520/DPR2 in a temporary 1100×900 native window. Each case runs eight
seconds and excludes readouts from the first two seconds. Runs reject missing
rows, fewer than four readouts, fewer than 25 captured frame timings or a changed
chart size. Caffeinate keeps the display awake only during the runner.

| Operation | Colors | Connected | Labels | FPS before → after | UI p90 before → after ms |
| --- | --- | --- | ---: | ---: | ---: |
| update | indexed | off | 0 | 60.0 → 60.0 | 15.64 → 15.76 |
| update | indexed | off | 200 | 59.8 → 60.0 | 16.48 → 16.07 |
| update | indexed | on | 0 | 58.0 → 58.7 | 19.14 → 18.78 |
| update | indexed | on | 200 | 55.0 → 55.1 | 19.53 → 19.56 |
| update | scriptable | off | 0 | 31.5 → 32.6 | 29.92 → 29.29 |
| update | scriptable | off | 200 | 30.0 → 32.9 | 31.71 → 30.08 |
| update | scriptable | on | 0 | 29.4 → 31.1 | 33.84 → 30.55 |
| update | scriptable | on | 200 | 29.3 → 30.2 | 33.49 → 31.71 |
| data | indexed | off | 0 | 60.0 → 60.0 | 15.64 → 16.42 |
| data | indexed | off | 200 | 60.0 → 60.0 | 16.24 → 16.15 |
| data | indexed | on | 0 | 56.7 → 58.7 | 19.32 → 18.80 |
| data | indexed | on | 200 | 54.3 → 55.9 | 19.80 → 19.44 |
| data | scriptable | off | 0 | 30.7 → 34.6 | 29.91 → 27.17 |
| data | scriptable | off | 200 | 30.2 → 33.6 | 30.50 → 28.87 |
| data | scriptable | on | 0 | 29.7 → 32.8 | 33.02 → 29.48 |
| data | scriptable | on | 200 | 29.7 → 30.9 | 32.91 → 30.74 |

FPS is the mean of readouts; p90 uses captured post-warmup FrameTimings and can
omit late timing batches. These short local runs do not establish sustained or
cross-device FPS. Data-only selected full-update fallback in all these cells.
This pass does not repeat the preceding 96-cell matrix: it targets the update
paths changed here, with static CPU controls and the existing correctness suites.

The scriptable updates retain more frame-budget headroom, but remain above the
16.67 ms target. Live scope/value lookup, context refresh, final option objects,
geometry and drawing still cost time. This implementation deliberately does
not cache arbitrary scope reads across user callbacks. That broader work needs
its own observable-mutation guards and measured gain.

## Validation

- 10,955 workspace VM tests passed; 72 focused option/setup tests passed.
- 164 focused tests passed on each of JavaScript and WebAssembly.
- Workspace analysis and formatting passed; parity regeneration and all seven
  port checks passed.
- New tests cover immutable snapshots, insertion/deletion and integer-key order,
  routes/restore/freeze, point/bar result freshness, unsupported fallbacks,
  context-time and callback mutations, reentrant calls, native default-key
  mutation between points, custom Config dispatch, custom key enumeration,
  live string conversions/collisions and mutable input-key rechecks.

No full browser, fixture, golden or mobile suite was run. Compressed validation
logs and validation.json retain the scope. Production sources were not changed
after the measured build.

## Artifacts and reproduction

Use separate isolated workspace copies, the committed lockfile, and the pinned
Flutter SDK. Do not reuse the shared gallery build directory.

- baseline-overlay.patch reverses only this pass's four runtime changes from
  the delivered tree. The baseline still contains all ADR 0080 changes.
- estimate.patch applies the instrumented prototype on that baseline. Restore
  option_setup_experiment.dart.txt under lib/src/core/ in that isolated package.
  It is a benchmark-only switch module, not production code.
- Restore probe.dart.txt as .dart_tool/line_setup/probe.dart for the estimates.
  Restore production_probe.dart.txt to that path for the production build.
  The production-comparison baseline uses baseline_control_probe.dart.txt
  with VARIANTS=baseline. Its switch module is unused by baseline library code.
- From apps/chartjs_gallery, build with:
  `flutter build macos --profile --no-pub --target ../../.dart_tool/line_setup/probe.dart`.
  The temporary runner's window setup is in MainFlutterWindow.swift.txt. Use it
  only in the isolated copies, before building, to match the frame viewport.
- Save the apps as /tmp/line-setup-baseline.app, /tmp/line-setup-estimate.app and
  /tmp/line-setup-production.app. Sign only these temporary copies using the
  [category-layout recipe](../category-layout/README.md).
- Restore estimate_run.py.txt and production_run.py.txt under .dart_tool/line_setup
  without .txt. Run each with `caffeinate -diu python3 <runner>` while builds and
  tests are idle. Results use an OUTPUT file, independent of macOS log routing.

measurements.json.gz contains every raw accepted row. The summary files separate
estimates, production CPU comparisons and frames. metadata.json records source
and binary hashes. Callback or allocation-count instrumentation is not included
in the timing claims.
