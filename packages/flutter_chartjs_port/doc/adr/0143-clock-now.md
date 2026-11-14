# Chart.js ADR 0143: `Date.now()` is `clock.now()`

- Status: accepted (2026-11-14): its code and the tests of section Tests pass.
- Superseded by: [Chart.js ADR 0146](0146-js-numeric-semantics.md) (2026-11-14)
- Date: 2026-11-14
- Supersedes: the `jsDateNow` parts of [Chart.js ADR 0045](0045-reference-engine-arm64.md): the
  first sentence of section 6, the `js_date.dart` row of the runtime table, the `Date.now()` row of
  the translation table and the rule "Call `jsDateNow()`".
- Full text: `git show 2ee913263ba0fad4d08b0e9744c3a86575286268:packages/flutter_chartjs_port/doc/adr/0143-clock-now.md`

## Summary

`Date.now()` became `clock.now().millisecondsSinceEpoch` of package:clock, read at each call site. A caller that
computes with `double` values added `.toDouble()`. `jsDateNow` and `js_date.dart` left the runtime. Tool 3 kept its
failure on `DateTime.now(`, and `check:lib-imports` allowed package:clock in the core layers.

## Where each part went

- Item 1 (`clock.now()` in the number type of the caller): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §6.
- Item 2 (no `jsDateNow` and no `js_date.dart`): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §1 and
  Rejected.
- Item 3 (the callers and the benchmark of the gallery): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §6,
  first bullet.
- Item 4 (tool 3 on `DateTime.now(`): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §6 and §8.
- Item 5 (`check:lib-imports` and the gallery dependency): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §6,
  last bullet.
