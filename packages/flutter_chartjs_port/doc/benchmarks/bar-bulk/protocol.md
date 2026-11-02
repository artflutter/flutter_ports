# Bulk numeric bar update protocol

Baseline: validated ADR 0068, recorded as 1d37d64 + baseline.patch and its new
bar_index_layout.dart. Candidate: guarded update('none') numeric bulk path.
Preserve the first ordinary item, preflight the remaining native arrays, resolved
scalar settings and exact built-in elements/scales before any bulk writes.
No custom/scriptable behavior may be skipped. Preserve fresh skipped-edge objects,
property state, hook ordering, partial ranges, visibility and current options.

Apple M3 Max, macOS profile AOT, Flutter 3.47.8 / Dart 3.13.7, Impeller, 800x480
DPR 1. A/B/B/A, seven 200ms batches after 800ms warmup, N=1000/5000/20000.
Primary: full bar update. Require >=15% improvement in both 20k pairs.
Controls: draw, animation, rounded/inflated bars, line/bubble/doughnut, multiple
datasets, indexed stacks and scriptable colors. No repeatable regression over
both 5% and 0.1ms of the full call. Retain every result and compare identical
harnesses without concurrent tests/builds. Measure foreground update FPS separately.

Correctness twins cover both orientations, shared/raw/typed config, grid/border
options, callbacks and mutations, partial updates, visibility, resets/animations,
float/stacked/non-finite data, custom classes/containers, late unsupported items,
key order/undefined state and an owner-mismatch scale. Run workspace tests,
JS/Wasm targeted checks, fixtures, analysis, format, parity and port checks.
No golden updates on macOS.
