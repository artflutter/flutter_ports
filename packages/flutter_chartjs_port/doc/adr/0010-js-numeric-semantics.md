# Chart.js ADR 0010: JS numeric semantics

- Status: accepted (2026-10-19)
- Superseded by: [Chart.js ADR 0032](0032-js-numeric-semantics.md) (2026-10-21)
- Date: 2026-10-19
- Supersedes: [Chart.js ADR 0002](0002-js-numeric-semantics.md)
- Full text: `git show 2ee913263ba0fad4d08b0e9744c3a86575286268:packages/flutter_chartjs_port/doc/adr/0010-js-numeric-semantics.md`

## Summary

This ADR restated the JS numeric rules of [Chart.js ADR 0002](0002-js-numeric-semantics.md). `Math.sin`,
`Math.cos` and `Math.pow` used `dart:math`, and numbers formatted on package:intl. `jsMax` and `jsMin` stopped
the boxing of `max` and `min` on dart2wasm. `jsSquare` and `(e ?? 0)` replaced `pow(x, 2)` and `jsToNumber`
for point coordinates. The fdlibm `log10` and `atan2` stayed, with x64 V8 13.6 as the reference engine.

## Where each part went

- §1 (the JS runtime): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §1.
- §2 (the reference engine): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §2.
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) removes the x64 fdlibm data.
- §3 (the transcendental builtins): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §3.
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) moves `sin`, `cos`, `atan2` and `log` to `dart:math`
  and removes the fdlibm ports.
- §4 (the exact and correctly rounded builtins): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §4.
  [Chart.js ADR 0134](0134-dart-math-max-min.md) removes `jsMax` and `jsMin`.
  [Chart.js ADR 0136](0136-math-pow-square.md) removes `jsSquare`.
- §5 (the sort): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §5.
- §6 (the clock): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §6.
  [Chart.js ADR 0143](0143-clock-now.md) replaces `jsDateNow` with `clock.now()`.
- §7 (the translation rules): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §7.
  [Chart.js ADR 0134](0134-dart-math-max-min.md), [Chart.js ADR 0136](0136-math-pow-square.md),
  [Chart.js ADR 0138](0138-math-round-as-round-to-double.md) and [Chart.js ADR 0143](0143-clock-now.md) change
  the rows of `Math.max`, `Math.min`, `Math.pow(x, 2)`, `Math.round` and `Date.now()`.
- §8 (tool 3 and `js-ok`): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §8.
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) and [Chart.js ADR 0134](0134-dart-math-max-min.md)
  remove the rules of the transcendental functions and of `max` and `min`.
- §9 (number formatting): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §9.
  [Chart.js ADR 0119](0119-plain-intl-number-format.md) gives the current number format.
- §10 (the tests): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §10.
