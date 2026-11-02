# Bulk numeric bar update evidence

2026-11-02. ADR 0069; performance.md §36. Baseline includes ADR 0068 and the earlier
canvas/drawing optimizations. This comparison measures only the additional bulk
update work.

## Reproduction

Baseline: `1d37d64` plus `baseline.patch`, with `baseline.bar_index_layout.dart.txt`
at `packages/flutter_chartjs_port/lib/src/core/bar_index_layout.dart`.
Candidate: `1d37d64` plus `candidate.patch`, with `bar_index_layout.dart.txt` and
`bar_bulk_update.dart.txt` at their corresponding `lib/src/core/` paths.
The full candidate patch includes changes shared by both variants.

Copy `probe.dart.txt`, `native.dart.txt` and `controller.dart.txt` to
`.dart_tool/bar_update/`, removing `.txt`. The legacy prototype controller is
imported but not selected by any reported case. From `apps/chartjs_gallery`:

```
flutter build macos --profile -t ../../.dart_tool/bar_update/probe.dart --dart-define=SECONDS=25
```

Keep separate app copies, signed with the temporary-app recipe in
../category-layout/README.md. The scripts use `/tmp/bar-update-b.app` as baseline
(the preceding change's candidate) and `/tmp/bar-bulk-d.app` as candidate. Use
explicit selectors in `measure.py.txt`. Repository signing is unchanged.

## Timing

Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, arm64 profile AOT,
Impeller, 800x480 DPR 1. A/B/B/A, seven 200ms batches after 800ms warmup, without
concurrent builds/tests. Full calls sum update, draw and paint/completion within
each process before aggregating its two results. `summary.json` retains both
pairs and components; `measurements.json.gz` contains every run.

The 20k full update improves 28.5% (31.1% and 25.5% in the pairs), exceeding the
15% gate. No rounded/inflated, multiple-dataset, indexed-stack, scriptable-color,
line/bubble/doughnut, draw or animation control has a repeatable regression above
both 5% and 0.1ms. Drawing and element-preparation components inside updates are
higher in this series; the full-call sum includes them. Their shifts have not
been isolated and are not described as zero.

The initial quick candidate did not activate: its guard incorrectly required a
numeric minBarLength, while the default is undefined (ToNumber gives NaN, making
the comparison false). Activation tests caught this. Both the inactive and
corrected quick comparisons are retained as preliminary, not acceptance data.

## Foreground FPS

The 25-second StressProfileApp runs use N=20000/M=0 and `CALL=update`, with exact
process activation. The initial candidate produced fewer complete windows, so a
fresh comparison additionally checked process activity about every three seconds.
Every monitored check reports `true`, and both monitored runs have 24 complete
one-second windows. The final result is 23.88 → 31.12 FPS, average update
21.86 → 9.89ms and average build 37.54 → 27.22ms. These are one process per cell
on this Mac, not a sustained 60 FPS or cross-device claim.

`stress-monitored-*.log`, `foreground-monitor.log` and `stress.json` retain these
figures, window coverage and activation state. The initial `stress-fg-*.log` runs
remain in the evidence but are not the final FPS comparison.

## Validation

The 13 permanent tests in `test/port/controllers/bar_bulk_update_test.dart`
compare with a Chart that retains ADR 0068 while disabling bulk writes. A
counter-only native-write opt-in proves activation. Tests cover hidden/visible
axes, both orientations, base/border/reversal settings, visibility, fresh edge
objects, partial ranges/reset, late invalid inputs, custom classes, callback
counts, first-item mutation and foreign scale ownership. Existing bar references
and workspace tests also run.

Copy `browser_probe.dart.txt` temporarily to
`test/port/controllers/bar_bulk_browser_probe_test.dart`, run it with
`flutter test --platform chrome` and `--platform chrome --wasm`, and remove it
before repository checks. `validation.json` and compressed logs record final
results. No golden image is changed. Only a divergence-marker comment differs
between the measured and final runtime sources; both hash sets are retained.
