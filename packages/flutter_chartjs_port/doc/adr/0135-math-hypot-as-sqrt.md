# Chart.js ADR 0135: `Math.hypot` is `math.sqrt(a * a + b * b)`

- Status: accepted (2026-11-13): its code and the tests of section Tests pass.
- Superseded by: [Chart.js ADR 0146](0146-js-numeric-semantics.md) (2026-11-14)
- Date: 2026-11-13
- Supersedes: parts of [Chart.js ADR 0108](0108-input-surface-and-exports-for-add-on-plugins.md):
  §2 (`jsHypot`, `tool/reference/hypot_reference.mjs` and `test/port/js/hypot_reference.dart`),
  the `jsHypot` rows of its test list, and the rejected alternative "`math.sqrt(a * a + b * b)` for
  `Math.hypot`".
- Full text: `git show 2ee913263ba0fad4d08b0e9744c3a86575286268:packages/flutter_chartjs_port/doc/adr/0135-math-hypot-as-sqrt.md`

## Summary

`Math.hypot(a, b)` became `math.sqrt(a * a + b * b)` with `double` operands, at the call site. `jsHypot`, its
generator, its data and its test left the port. At pixel sizes, the plain form differs from V8 only in the last
bit. The only callers were the pinch and pan sites of the zoom port.

## Where each part went

- Item 1 (`math.sqrt(a * a + b * b)` at the call site): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §4, the
  `Math.hypot` bullet, and §1.
- Item 2 (no `jsHypot` in the runtime or the public API): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §1 (no
  runtime function) and Rejected.
- Item 3 (the generator, the data and the test of `jsHypot`): removed. These files are gone, and no rule replaces
  them.
- Item 4 (a caller with operands that can overflow or underflow): [Chart.js ADR 0146](0146-js-numeric-semantics.md)
  §4, the `Math.hypot` bullet.
- The superseded parts of [Chart.js ADR 0108](0108-input-surface-and-exports-for-add-on-plugins.md) (§2 and the
  rejected `math.sqrt` form): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §4, the `Math.hypot` bullet, and
  Rejected.
