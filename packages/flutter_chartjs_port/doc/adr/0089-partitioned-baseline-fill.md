# 0089 — Native compound paths for dense curved baseline fills

- Status: accepted
- Superseded by: [Chart.js ADR 0114](0114-dense-curve-merge.md) (2026-11-11)
- Date: 2026-11-05
- Full text: `git show 2ee913263ba0fad4d08b0e9744c3a86575286268:packages/flutter_chartjs_port/doc/adr/0089-partitioned-baseline-fill.md`

## Summary

After the upstream filler path, an eligible native canvas filled an equivalent compound path over a shared baseline.
Each contour had at most 32 cubic segments, with unchanged control points and no removed point.
A geometry preflight and native canvas checks kept every other fill on the original path.
[Chart.js ADR 0114](0114-dense-curve-merge.md) states the complete decision with one change.
The partitions take the merged vertices of a dense curved line.

## Where each part went

- Decision ¶1 (the compound path after the original path): [Chart.js ADR 0114](0114-dense-curve-merge.md)
  section "The partitioned fill".
- Decision ¶2 (`PartitionedFillCanvas` and the geometry preflight): [Chart.js ADR 0114](0114-dense-curve-merge.md)
  section "The partitioned fill".
- Decision ¶3 (the decline, the color test, no user getters, the test switch):
  [Chart.js ADR 0114](0114-dense-curve-merge.md) section "The partitioned fill".
- Costs and validation (the extra path build and the pixel twins): [Chart.js ADR 0114](0114-dense-curve-merge.md)
  section Tests (`partitioned_baseline_fill_test.dart`). Figures: performance.md §62.
