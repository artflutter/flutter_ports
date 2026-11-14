# Chart.js ADR 0136: `Math.pow(x, 2)` is `dart:math` `pow`

- Status: accepted (2026-11-13): its code and the tests of section Tests pass.
- Superseded by: [Chart.js ADR 0146](0146-js-numeric-semantics.md) (2026-11-14)
- Date: 2026-11-13
- Supersedes: the `jsSquare` parts of [Chart.js ADR 0045](0045-reference-engine-arm64.md): the
  `Math.pow(x, 2)` rule of §4, its table row and its tests.
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0136-math-pow-square.md`

## Summary

`Math.pow(x, 2)` became `math.pow(x, 2.0).toDouble()`, with the `js-ok` comment of the `pow` rule. `jsSquare`
left the runtime. V8 and `dart:math` both give the bits of `x * x`, so the port keeps the upstream call.

## Where each part went

- Item 1 (`math.pow(x, 2.0).toDouble()`): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §4, the
  `Math.pow(x, 2)` bullet.
- Item 2 (no `jsSquare` in the runtime or the public API): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §1
  and Rejected.
