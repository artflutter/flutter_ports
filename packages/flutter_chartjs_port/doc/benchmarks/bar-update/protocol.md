# Live bar update optimization protocol

Baseline: all validated changes through ADR 0067 (1d37d64 + baseline.patch).
Target the actual bar update workload. First candidate: a live single-dataset
index-layout proof that bypasses repeated topology construction, plus skipping
numeric sorting only for an already ordered, owned finite list. Revalidate at
both upstream observation points; do not carry a topology result over callbacks.

Apple M3 Max, macOS profile AOT, Flutter 3.47.8, Impeller, 800x480 DPR 1.
A/B/B/A: 800ms warmup, seven 200ms batches, N=1000/5000/20000, update/draw/animation.
Controls include rounded and inflated bars, line/bubble updates and doughnut draw.
No tests/builds alongside timing. Require >=20% full 20k update improvement in
both pairs, no repeatable control regression above both 5% and 0.1ms. If the
candidate misses the gate, profile the remaining update work before retaining it.
Report real foreground update FPS independently, with exact process activation.

Validate raw and typed configs, mutation within scriptable options, state changes
between updates, unknown/custom containers and methods, indexed stack behavior,
reentrant updates, geometry and hook traces against a subclass taking the original
path. Sorted-list guards preserve duplicate/signed-zero order and fall back for
unsorted/non-finite data. Run workspace tests, targeted JS/Wasm tests, fixtures,
analysis, formatting, public API and port checks; do not write macOS goldens.
