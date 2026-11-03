# Chart.js ADR 0072: Reuse numeric positions within one bar ruler

- Status: rejected; prototypes removed after failing the performance gate.
- Date: 2026-11-03
- Related: ADRs 0068, 0071; performance.md §39.

## Decision

The exact BarController may validate a native metadata array of double
ParsedItem indexes equal to 0..N-1 while filling its existing pixel array. Unknown controllers,
metadata, containers, items and index values retain the original reads. Each
eligible numeric value is projected through the original scale method. A late
unsupported item abandons the private partial result and runs the ordinary
loop; the already-run native numeric projections have no observable effects.

The exact category and linear scales supply all numeric projection inputs:
origin, range, pixel start, length and reversal. Pixel alignment is excluded
because it reads chart state. Nonfinite, degenerate and signed-zero settings
decline; negative-zero index values also decline. No custom scale inherits the
native projection contract. The metadata capability is implemented by final
ChartMeta, whose parsed-array field read is ordinary.

After the original barThickness read and getAllScaleValues collection, compare
the current projection state and every sorted unique scale value with the
known contiguous indexes. Reuse the projected array only on a complete match.
Callbacks that change geometry or indexes, duplicate/unsorted indexes, custom
cached value lists and incompatible visible datasets retain all ordinary value
projections. Value gathering, deduplication and the scale cache are unchanged in
this step. The cache comparison never reads custom list contents to qualify.

The guarded minimum calculation combines complete index validation and numeric
spacing in one loop, retaining zero-distance and truncated-pixel exclusions. The tick-spacing loop still
runs at its original point, including virtual calls. Snapshots are confined to
one ruler calculation; no cross-update cache or invalidation scheme is added.

## Validation

Activation and geometry twins cover both orientations, reversals, resize, linear
ticks, duplicates, unsorted values, clipped pixels, unsupported values/alignment,
custom scales and cached lists, and callbacks changing scale or parsed indexes.
The first implementation's pilot was inconsistent at the full-frame level.
Its evidence is retained. A broader copied-index refinement failed the full
performance gate too. The final candidate uses no extra index buffer and also
removes generic number conversions from the guarded spacing loop. VM and both browser backends pass.
Separate baseline/step-one measurements are in benchmarks/bar-spacing/.

## Outcome

The final fused prototype passed correctness tests and improved its isolated
pilot, but the first full-workload pair regressed 20.511 → 20.898ms. The protocol
requires improvement in both pairs, so remaining measurements were stopped.
The initial broader and allocation-free separate-loop variants also failed.
All production changes and tests for this prototype were removed; their exact
sources, hashes, tests and measurements remain in benchmarks/bar-spacing/.
Proceed with the independent sorted-value duplicate scan on the unchanged
3d10094 baseline. Do not infer a speedup from the position-reuse pilot.
