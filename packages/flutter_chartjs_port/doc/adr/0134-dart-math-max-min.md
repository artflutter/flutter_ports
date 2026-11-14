# Chart.js ADR 0134: `Math.max` and `Math.min` are `dart:math` `max` and `min` on doubles

- Status: accepted (2026-11-13): its code and the tests of section Tests pass.
- Superseded by: [Chart.js ADR 0146](0146-js-numeric-semantics.md) (2026-11-14)
- Date: 2026-11-13
- Supersedes: parts of [Chart.js ADR 0045](0045-reference-engine-arm64.md): in §4 the bullet of `Math.max` and
  `Math.min` with `double` operands (`jsMax`, `jsMin`, `jsMaxMinCompare` and their two code paths), the three rows of
  `Math.max` and `Math.min` with numbers in the translation table, the `_limitValue` form and the `max`/`min` item of
  the forbidden forms; in §8 the `max`/`min` item of tool 3; the `jsMax` and `jsMin` part of its test list; the
  alternative "`dart:math` `max` and `min` on every target"; and the consequence of the two code paths.
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0134-dart-math-max-min.md`

## Summary

`Math.max` and `Math.min` with `double` operands became `dart:math` `max` and `min` with the type argument
`double`. `jsMax`, `jsMin` and `jsMaxMinCompare` left the runtime. On dart2wasm, a call that infers `num` takes
the slow generic path. Thus the code writes `<double>` at such a call. Tool 3 flagged each call with the type
argument `num`.

## Where each part went

- Item 1 (`dart:math` `max` and `min` on doubles): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §4, the
  `Math.max` and `Math.min` bullet. The add-on ports import `dart:math` themselves: §1.
- Item 2 (the type argument `double`, three operands and the spread form):
  [Chart.js ADR 0146](0146-js-numeric-semantics.md) §4, the first and the second sub-bullets of the `Math.max` and
  `Math.min` bullet.
- Item 3 (`int` operands): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §4, the sub-bullet of `int` operands.
- Item 4 (`_limitValue`, no `num.clamp`): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §4, the `_limitValue`
  sub-bullet.
- Item 5 (tool 3 flags the type argument `num`): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §8.
