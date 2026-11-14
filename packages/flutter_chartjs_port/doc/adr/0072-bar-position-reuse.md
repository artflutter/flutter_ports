# Chart.js ADR 0072: Reuse numeric positions within one bar ruler

- Status: rejected; prototypes removed after failing the performance gate.
- Date: 2026-11-03
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0072-bar-position-reuse.md`

## Summary

It proposed to reuse the projected numeric positions within one bar ruler calculation of the exact `BarController`.
Guards on the metadata, the scales and the indexes kept each other case on the ordinary reads.
The final prototype passed the tests, but its first full-workload pair regressed from 20.511 to 20.898 ms.
The protocol needed a gain in both pairs. Thus the prototypes and their tests left the tree.
The independent sorted-value duplicate scan of [Chart.js ADR 0073](0073-sorted-bar-values.md) went ahead.

## Where each part went

- Decision ¶1 (the check of contiguous indexes in the exact `BarController`): rejected, not in the code.
- Decision ¶2 (the native projection inputs of the exact category and linear scales): rejected, not in the
  code.
- Decision ¶3 (the reuse of the projected array after a complete match): rejected, not in the code.
- Decision ¶4 (the fused loop of the index check and the minimum spacing): rejected, not in the code.
- Validation (the twins and the pilot): rejected, not in the code. The sources, the tests and the figures
  are in `doc/benchmarks/bar-spacing/`.
- Outcome (the next step): [Chart.js ADR 0073](0073-sorted-bar-values.md), the sorted-value duplicate scan.
