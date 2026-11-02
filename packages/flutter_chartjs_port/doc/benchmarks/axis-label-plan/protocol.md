# Axis label-plan protocol

Baseline: retained static tick-font implementation (performance.md §28), before
this implementation. Candidate: reuse complete scalar/string label measurements,
with live geometry fitting, fresh Tick/context objects, default category callback
dispatch, and native font-generation invalidation. Do not alter stress options.

macOS profile AOT, same category_probe.dart and 800 × 480 canvas, N=1000/5000/20000,
category/logarithmic and linear/logarithmic, update and draw. Nine 250 ms batches
follow 1000 ms warmup. A/B/B/A, all results retained, no builds/tests while timing.
The primary N=20000 category update must improve by 40% in both pairs; full-call
cost must improve by 30%. Compare x/y tick values, labels, rotation and chart bounds
exactly. Investigate repeatable control regressions above both 5% and 0.1 ms.
Correctness additionally requires invalidation and cached/uncached twin tests.
