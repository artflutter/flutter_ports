# Bar update, animation and native picture investigation

2026-11-02. See [the findings](../../bar-performance.md). This directory contains
investigation harnesses and evidence; no production optimization is installed.

Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, arm64 profile AOT,
Impeller, 800 × 480, DPR 1. `metadata.json` records the baseline and source hashes.
The runtime baseline is commit `1d37d64`, including the previously implemented
axis optimizations. There were no runtime changes relative to that commit.

## Reproduction

At repository root, copy `probe.dart.txt`, `native.dart.txt` and `profile.dart.txt`
to `.dart_tool/bar_scan/`, removing `.txt`. Copy the production
`lib/src/controllers/controller.bar.dart` to `.dart_tool/bar_scan/controller.dart`
and apply `controller.patch` to that copy. The patched controller is an explicitly
unsafe investigation prototype: it has no guard for mutations during an update.
It is registered only for `index_memo`, under a separate component id.

From `apps/chartjs_gallery`:

```
flutter build macos --profile -t ../../.dart_tool/bar_scan/probe.dart
```

Copy the resulting app to `/tmp/bar-scan-final.app` and ad-hoc sign that temporary
copy using `../category-layout/probe.entitlements`, as described in the
[category benchmark](../category-layout/README.md). Repository signing is unchanged.

Launch the app executable directly with these environment variables:

```
BAR_RUN=final1
BAR_N=1000,5000,20000
BAR_VARIANTS=baseline,index_memo,ungrouped,draw,anim,native_rects,native_chunk,native_verify
```

The results are appended to `/tmp/bar-$BAR_RUN.jsonl`; use a fresh run name.
The app exits when finished. For the second sweep, set `BAR_RUN=final2` and
`BAR_REVERSE=1`, and omit `native_verify`. Seven 200 ms batches follow 800 ms
warmup per cell. Final sweeps ran forward/reverse, without concurrent builds or
tests. These are exploratory two-process measurements, not acceptance tests for
an optimization or a measurement of gallery FPS.

`scan` uses the default case list, additionally exploring `thickness`,
`ungrouped_thickness`, `no_border`, `draw_no_border`, `anim_no_border`,
`anim_y_only` and `anim_settled`. Animation preparation changes the data once and
starts the existing looping animation; each measured iteration advances its
clock by one frame and calls the animator. `anim_settled` first ends startup and
writes final geometry without animation. The default animation retains startup
NaN height endpoints, matching the vertical bar reset representation.

## Interpretation of measurements

- Chart `updateMedianMs` excludes drawing. In `anim`, it is animator tick time.
  `endMedianMs` includes canvas painting into a host recorder and its completion.
  In particular it includes **drawPicture**, not only `endRecording`.
- Data mutation and initial chart construction are outside timed chart calls.
  Each full-call number sums update, draw and end in one process first.
- Native cases bypass Chart.js entirely and draw the same deterministic rectangle
  sequence. `native_chunk` makes successive pictures of at most 256 rectangles.
  Its `record` includes intermediate picture endings; `innerEnd` ends only the
  final chunk. Compare the sum of all five fields, not individual recording fields.
- `native_path` is a prebuilt combined path ceiling, outside the final comparison.
  Path construction is excluded, and antialiasing/overdraw equivalence is not
  established. It is not a proposed drop-in replacement.
- `native_verify` compares raw RGBA bytes of one picture versus chunks for each N,
  opaque/translucent paint, overlapping/disjoint rectangles, fractional translation
  and clipping. All 12 checks pass exactly on this local Impeller runner. These
  checks do not cover the full Canvas 2D state/compositing API.

## Evidence

`measurements.json.gz` retains the initial incomplete scan (JSON serialization
failed on a NaN animation height), the corrected full configuration scan, the
preliminary native scan, and both final sweeps. In the preliminary native build,
`native_chunk` was compiled before the chunk implementation was added: those rows
are plain-rectangle controls and are **excluded** from all chunk comparisons.
`summary.json` uses only the two final sweeps for baseline/prototype comparisons.
The configuration-only alternatives use the single full scan and are labeled so.

`profile-baseline.json.gz` and `profile-anim.json.gz` each contain a fresh
10-second CPU capture. `profiles-summary.json` lists their inclusive shares,
which overlap. Enable the VM profiler, wait nine seconds, clear its samples,
collect for ten seconds, then call `getCpuSamples`. `profile.dart.txt` and
`capture.py.txt` reproduce that sequence; the latter uses fixed local paths
which should be adapted to the checkout. Profiling is separate from timing.
The native engine frames are not symbolized in these Dart captures: the native
algorithm attribution additionally comes from the pinned local Flutter source
and the independent rectangle experiment.

To reproduce the geometry checks, also copy `verify_test.dart.txt` into the
harness directory as `verify_test.dart`. From `apps/chartjs_gallery`, run:

```
flutter test ../../.dart_tool/bar_scan/verify_test.dart --reporter expanded
```

`validation.json` records the two geometry tests, twelve native pixel comparisons
and unchanged library hashes. `geometry-validation.log` retains the test output.
