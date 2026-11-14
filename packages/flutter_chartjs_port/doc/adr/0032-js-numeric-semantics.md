# Chart.js ADR 0032: JS numeric semantics

- Status: accepted (2026-10-21)
- Superseded by: [Chart.js ADR 0045](0045-reference-engine-arm64.md) (2026-10-29)
- Date: 2026-10-21
- Supersedes: [Chart.js ADR 0010](0010-js-numeric-semantics.md)
- Full text: `git show 2ee913263ba0fad4d08b0e9744c3a86575286268:packages/flutter_chartjs_port/doc/adr/0032-js-numeric-semantics.md`

## Summary

Ported code calls the JS runtime of `lib/src/js/` where upstream relies on a JS builtin or an implicit conversion.
The reference engine was V8 13.6 of the x64 build of Node.js v24.12.0.
`Math.log10`, `Math.atan2` and the protected `Math.sin` and `Math.cos` were fdlibm 5.3 ports with the engine bits.
A protected site was a call whose result can reach a layout, a scale, a hit test or a discrete decision.
A translation table, `jsSort`, `jsDateNow` and tool 3 with `js-ok` comments completed the rules.

## Where each part went

Chart.js ADR 0045 keeps the section numbers of this ADR.

- §1 (the JS runtime): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §1.
- §2 (the reference engine): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §2, with the arm64 engine.
- §2 (the x64 fdlibm data and their generators): removed by [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md).
- §3 (the protected sites and the transcendental builtins): [Chart.js ADR 0045](0045-reference-engine-arm64.md)
  §3.
- §3 (the fdlibm ports `jsLog10`, `jsAtan2`, `jsSin` and `jsCos`): removed by
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md). These builtins are `dart:math` as it is.
- §3 (`Math.pow(x, 2)`): [Chart.js ADR 0136](0136-math-pow-square.md).
- §4 (the exact and correctly rounded builtins, `(e ?? 0)`): [Chart.js ADR 0045](0045-reference-engine-arm64.md)
  §4.
- §4 (`jsMax`, `jsMin` and `jsMaxMinCompare`): removed by [Chart.js ADR 0134](0134-dart-math-max-min.md).
- §4 (`jsSquare`): removed by [Chart.js ADR 0136](0136-math-pow-square.md).
- §5 (the sort, `jsSort`): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §5.
- §6 (the clock): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §6. `jsDateNow`: removed by
  [Chart.js ADR 0143](0143-clock-now.md).
- §7 (the translation rules): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §7.
- §7 (the row of `Math.round`): [Chart.js ADR 0138](0138-math-round-as-round-to-double.md).
- §7 (the rows of `Math.max` and `Math.min`): [Chart.js ADR 0134](0134-dart-math-max-min.md).
- §7 (the index as a number): [Chart.js ADR 0129](0129-int-indexes.md).
- §8 (tool 3 and `js-ok`): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §8.
- §8 (the tool 3 rules of the transcendental functions): removed by
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md).
- §8 (the tool 3 rule of `max` and `min`): [Chart.js ADR 0134](0134-dart-math-max-min.md).
- §9 (the number formatting): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §9, then
  [Chart.js ADR 0119](0119-plain-intl-number-format.md).
- §10 (the tests): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §10. The bit-for-bit tests of the fdlibm
  ports: removed by [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md).
- Alternatives considered: [Chart.js ADR 0045](0045-reference-engine-arm64.md), Alternatives considered.
- Open 1 (the Windows run): resolved on 2026-10-21. [Chart.js ADR 0045](0045-reference-engine-arm64.md) Open 1.
- Open 2 (no frame figure): [Chart.js ADR 0045](0045-reference-engine-arm64.md) Open 2.
  Figures: performance.md §13.8.
- Open 3 (`asin` and `pow` on protected paths): [Chart.js ADR 0045](0045-reference-engine-arm64.md) Open 3.
- Open 4 (correctly rounded results): [Chart.js ADR 0045](0045-reference-engine-arm64.md) Open 4.
