# Axis pipeline scan evidence

2026-11-02. The complete findings and ranked options are in
[axis-pipeline-options.md](../../axis-pipeline-options.md), summarized in
performance.md §29. No production optimization was applied during this scan.

## Baseline and setup

`8bcbe47` plus `baseline.patch` reconstructs the runtime code: it includes both
previously retained category-layout/font optimizations. `metadata.json` records
SHA-256 hashes, toolchain and platform. Apple M3 Max, macOS 27.0.1, Flutter
3.47.8 / Dart 3.13.7, arm64 profile AOT, Impeller, 800 × 480 at DPR 1, N=20000.

Copy `probe.dart.txt` to `.dart_tool/layout_pipeline_probe.dart` at repository
root. From `apps/chartjs_gallery`:

```
flutter build macos --profile -t ../../.dart_tool/layout_pipeline_probe.dart
```

Keep a throwaway copy of the app. The probe writes `/tmp/pipeline-$PIPELINE_RUN.jsonl`
and exits. As in the preceding experiments, re-sign only that copy with
`../category-layout/probe.entitlements` so the app sandbox does not prevent writing
measurement files. Launch its executable directly; do not alter repository signing.

```
PIPELINE_MODE=measure PIPELINE_RUN=measure1 /tmp/pipeline-expanded.app/Contents/MacOS/chartjs_gallery
PIPELINE_MODE=measure PIPELINE_RUN=measure2 PIPELINE_REVERSE=1 /tmp/pipeline-expanded.app/Contents/MacOS/chartjs_gallery
PIPELINE_MODE=measure PIPELINE_RUN=measure3 /tmp/pipeline-expanded.app/Contents/MacOS/chartjs_gallery
```

Each cell has 800 ms warmup and seven 200 ms batches. Three sweeps use forward,
reverse, forward order. No builds/tests run during timing. All runs are kept.
`PIPELINE_VARIANTS` selects comma-separated cases, `PIPELINE_N` selects counts.

## Files and checks

- `measurements.json.gz`: the three complete sweeps, 20 cases each.
- `summary.json`: median and range across the process results; full call sums
  update, draw and recording completion within each process first.
- `steady-observations.jsonl.gz`: paired baseline/probe observations over eight
  synchronized frames, using `PIPELINE_MODE=verify`.
- `adversarial-observations.jsonl.gz`: three-frame sequences with a long label at
  index 123, y=1e8 at index 123, or resize to 640 × 400, using
  `PIPELINE_MODE=adversarial`.
- `checks.json`: differing fields by case/scenario. Checked fields include all
  x/y tick values and labels, limits, rotation, chart area, and point positions
  at indices 0, N/2 and N-1. These checks are not pixel comparisons.
- `counts.jsonl`: one warmed instrumented update (`PIPELINE_MODE=count`).
  Counts are exact; nested timings include instrumentation overhead and should
  not replace the uninstrumented comparison figures.
- `profile.json.gz` and `profile-summary.json`: 5,782 CPU samples over a fresh
  10.003-second steady-state capture of the current baseline. The profile run is
  separate from timing sweeps. It uses `PIPELINE_MODE=profile`, enabling the VM
  profiler, clearing samples after nine seconds, collecting for ten seconds,
  then calling getCpuSamples before the app exits. Inclusive shares overlap.
- `label_scan.dart.txt` and `label-scan.jsonl`: standalone Dart AOT microbenchmark
  of ordinary List<String> content validation (no chart or dart:ui imports).
  Ten 200 ms measured batches follow a 200 ms warmup. This measures only the
  comparison loop, not the complete proposed cache guard.

The initial count/profile probe had fewer exploratory cases but the same
production library and baseline workload. The stored final probe includes the
additional direct-label and fixed-bound reuse cases.

## Interpretation

The freeze variants deliberately bypass invalidation. They establish a ceiling
for reusing stable geometry, and fail the relevant adversarial checks. The
constant-font and direct-label variants also omit compatibility guards. They are
not production patches. Sampling/fixed bounds are existing explicit options,
but change behavior outside their assumptions. The production design must add
correct invalidation or retain the full compatibility path.

The benchmark excludes input data writes from update time, as the existing
benchmark does. “Full call” includes chart update/draw/recording, not all Flutter
frame, input-preparation or raster work. Do not scale the user's FPS directly by
these ratios, and do not add gains of overlapping optimizations.
