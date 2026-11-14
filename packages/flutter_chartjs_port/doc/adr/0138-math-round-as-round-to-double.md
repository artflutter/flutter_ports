# Chart.js ADR 0138: `Math.round` is `roundToDouble()`

- Status: accepted (2026-11-13): its code and the tests of section Tests pass.
- Superseded by: [Chart.js ADR 0146](0146-js-numeric-semantics.md) (2026-11-14)
- Date: 2026-11-13
- Supersedes: the `jsRound` parts of [Chart.js ADR 0045](0045-reference-engine-arm64.md): the
  `Math.round` rule, its table rows and its tests.
- Full text: `git show 2ee913263ba0fad4d08b0e9744c3a86575286268:packages/flutter_chartjs_port/doc/adr/0138-math-round-as-round-to-double.md`

## Summary

`Math.round(x)` became `x.roundToDouble()`, and `jsRound` left the runtime. The two forms differ only for a
negative exact half. Row `adapt-dart-round` lists the three places where that input occurs: `alignPixel`, the
category `getValueForPixel` and `getRelativePosition`.

## Where each part went

- Item 1 (`roundToDouble()`, row `adapt-dart-round`): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §7, the
  `Math.round` paragraph.
- Item 2 (no `jsRound`, the zoom port and the matcher `toBeCloseToPoint`):
  [Chart.js ADR 0146](0146-js-numeric-semantics.md) §1, §7 and Rejected.
- Item 3 (the tool 3 rules of `.round()` and `.roundToDouble()`): [Chart.js ADR 0146](0146-js-numeric-semantics.md)
  §8.
- Item 4 (the tests of the three places): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §10, last bullet.
