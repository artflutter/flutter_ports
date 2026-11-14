# Chart.js ADR 0002: JS numeric semantics

- Status: accepted (2026-10-18)
- Date: 2026-10-17
- Superseded by: [Chart.js ADR 0010](0010-js-numeric-semantics.md) (2026-10-19)
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0002-js-numeric-semantics.md`

## Summary

This ADR gave the first JS numeric rules. An unexported runtime in `lib/src/js/` stood for the JS builtins.
Pure-Dart ports of fdlibm 5.3 gave the bits of x64 V8 13.6 for the transcendental builtins. `jsSort` sorted on
`mergeSort`, and `jsDateNow` read `clock.now()`. A table translated each JS form, and tool 3 flagged the Dart
forms with other results.

## Where each part went

- JS runtime (`lib/src/js/`): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §1.
- Reference engine (x64 V8 13.6): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §2.
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) removes the x64 fdlibm data.
- Transcendental builtins (the fdlibm ports): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §3.
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) moves them to `dart:math` and removes the fdlibm
  ports.
- Exact and correctly rounded builtins: [Chart.js ADR 0045](0045-reference-engine-arm64.md) §4.
  [Chart.js ADR 0134](0134-dart-math-max-min.md) gives `Math.max` and `Math.min`, and
  [Chart.js ADR 0136](0136-math-pow-square.md) gives `Math.pow(x, 2)`.
- Sort (`jsSort` on `mergeSort`): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §5.
- Clock (`jsDateNow` on `clock.now()`): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §6.
  [Chart.js ADR 0143](0143-clock-now.md) replaces `jsDateNow` with `clock.now()`.
- Translation rules (the table and the forbidden forms): [Chart.js ADR 0045](0045-reference-engine-arm64.md)
  §7. [Chart.js ADR 0134](0134-dart-math-max-min.md), [Chart.js ADR 0136](0136-math-pow-square.md),
  [Chart.js ADR 0138](0138-math-round-as-round-to-double.md) and [Chart.js ADR 0143](0143-clock-now.md) change
  the rows of `Math.max`, `Math.min`, `Math.pow(x, 2)`, `Math.round` and `Date.now()`.
- The `js-ok` escape (tool 3): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §8.
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) removes the rule of the transcendental functions.
- Number formatting (package:intl): [Chart.js ADR 0045](0045-reference-engine-arm64.md) §9.
  [Chart.js ADR 0119](0119-plain-intl-number-format.md) gives the current number format.
- Tests: [Chart.js ADR 0045](0045-reference-engine-arm64.md) §10.
