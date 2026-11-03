# Sequential bar spacing protocol

Baseline 3d10094 (numeric category parsing). Step 1 reuses already-projected
bar positions under complete native projection/value guards. Step 2 replaces
hash deduplication only for the already-proven finite sorted owned value list.
Implement and measure step 1 before editing step 2. Keep separate binaries and
A/B/B/A comparisons (baseline vs step 1, then step 1 vs step 2).

Same bar-native probe, M3 Max / macOS profile AOT / Flutter 3.47.8 / Dart 3.13.7 /
Impeller / 800x480 DPR1. Seven 200ms batches, 800ms warmup, no tests/builds during
measurement. Primary updates at 1k/5k/20k; draw/animation and other-chart,
multi-dataset, scriptable/indexed controls. Retain each stage only with a full
20k update improvement of at least 2% in both pairs; reject repeatable controls
worse by both 5% and 0.1ms. Preserve every attempt, including failures.

Test ordinary geometry twins, both orientations, reversed scales, tick spacing,
truncation, callbacks mutating scale/data between passes, custom scales/getters,
nonfinite/unsorted/duplicate values, signed zero and unique-list identity.
Run targeted VM/browser tests per stage, then workspace, fixtures, analyzer,
format, parity and port checks on the final source. No golden updates.

## Decision after step 1

Position-reuse candidates failed the full-workload gate and were removed.
Therefore step 2 compares the unchanged original baseline with sorted duplicate
removal alone. The original acceptance thresholds and controls remain unchanged.
