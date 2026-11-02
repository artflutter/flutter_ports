# Guarded static tick-font reuse

2026-11-02; Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7,
arm64 profile AOT and Impeller. See performance.md §28 and ADR 0063.

The baseline includes the previous category-layout optimization (§27), which
improved the user's stress chart from 13 FPS to 18–19 FPS. It is not bare HEAD.
`baseline.patch` reconstructs its runtime changes on top of `8bcbe47`.
`candidate.patch` describes this experiment's runtime changes relative to that
baseline. The patches exclude test/documentation changes.

Use the same probe and signing/launch instructions as
[category-layout](../category-layout/README.md). The canvas is 800 × 480;
the earlier report's 450-pixel height was a documentation error, corrected here.
The prewritten [protocol](protocol.md) uses A/B/B/A, all four process results,
1000 ms warmup and nine 250 ms batches per cell. No builds or tests run during
timing. The two axes configurations are category/logarithmic and the
linear/logarithmic control, with N=1000/5000/20000, update and draw.

`measurements.json.gz` stores all final process results, including layout outputs;
`summary.json` gives the comparison and primary gate. Preliminary probes are
retained separately in `preliminary.json.gz`: the first guard inspected descriptor
cache entries by string instead of their typed keys, and the second supported
explicit scalar fonts but not the stress chart's absent ticks.font. Neither
preliminary candidate is the retained implementation. These are implementation
iterations, not discarded runs of the final candidate.

The final path handles both already-cached complete scalar fonts and absent
fonts using live scalar defaults. It rechecks inputs and preserves warnings,
getters, throws, callbacks, context creation and fresh returned objects.
Only parsed scalar results are reused; dynamic or unsupported cases keep the
original resolution path. All labels are still measured and auto-skip is
unchanged. Timing results are local CPU measurements, not predicted user FPS.

`validation.json` records the full package suite, targeted JavaScript/Wasm tests,
fixture smoke runner, import-guard tests and workspace/port checks. The cache is
registered as a framework-free root rather than excluding its tests from web.
