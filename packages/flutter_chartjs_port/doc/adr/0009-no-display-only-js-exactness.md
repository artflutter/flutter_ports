# Chart.js ADR 0009: No display-only JS exactness

- Status: accepted (2026-10-18)
- Superseded by: [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (2026-10-21)
- Date: 2026-10-18
- Full text: `git show 2ee913263ba0fad4d08b0e9744c3a86575286268:packages/flutter_chartjs_port/doc/adr/0009-no-display-only-js-exactness.md`

## Summary

This ADR emulated JavaScript only where the result changes behavior, not for exact digits or pixels. It moved
`Math.sin`, `Math.cos` and `Math.pow` to `dart:math` and kept the fdlibm `log10` and `atan2`. The canvas layer
got no Chromium geometry. The port got no image comparison against the upstream PNGs. Dates used `DateFormat`
with ICU patterns, not moment tokens.

## Where each part went

- The principle (Context): [Chart.js ADR 0034](0034-no-display-only-js-exactness.md), "Principle" and
  "Protected behavior".
- §1 (`sin`, `cos` and `pow` on `dart:math`): [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) §1.
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) moves each transcendental builtin to `dart:math`.
- §2 (`log10`, `atan2` and the other JS rules stay): [Chart.js ADR 0034](0034-no-display-only-js-exactness.md)
  §2. [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) removes the fdlibm ports.
  [Chart.js ADR 0138](0138-math-round-as-round-to-double.md) removes `jsRound`.
- §3 (decision 3, the canvas layer without Chromium geometry):
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) §3. It replaces the DPR base scale with the bitmap
  space.
- §4 (no image comparison): [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) §4.
- §5 (dates on `DateFormat`): [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) §5.
  [Chart.js ADR 0024](0024-dates.md) gives the default date adapter.
