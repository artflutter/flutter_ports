# Chart.js ADR 0045: Reference engine on arm64

- Status: accepted (2026-10-29)
- Superseded in part by: [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) (2026-11-12), [Chart.js ADR 0134](0134-dart-math-max-min.md) (2026-11-13), [Chart.js ADR 0136](0136-math-pow-square.md) (2026-11-13), [Chart.js ADR 0138](0138-math-round-as-round-to-double.md) (2026-11-13), [Chart.js ADR 0143](0143-clock-now.md) (2026-11-14)
- Superseded by: [Chart.js ADR 0146](0146-js-numeric-semantics.md) (2026-11-14)
- Date: 2026-10-28
- Supersedes: [Chart.js ADR 0032](0032-js-numeric-semantics.md)
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0045-reference-engine-arm64.md`

## Summary

This ADR restated [Chart.js ADR 0032](0032-js-numeric-semantics.md) with the darwin-arm64 build of Node.js
v24.22.1 as the reference engine. Ported code called the JS runtime of `lib/src/js/` where a Dart form gave
another result. `Math.log10`, `Math.atan2` and the protected `Math.sin` and `Math.cos` were fdlibm 5.3 ports
with frozen x64 data. `jsMax`, `jsMin`, `jsSquare`, `jsRound`, `jsSort` and `jsDateNow` gave the JS results.
Tool 3 flagged the Dart forms with other results, and a `js-ok` comment kept a checked site.

## Where each part went

[Chart.js ADR 0146](0146-js-numeric-semantics.md) restates this ADR and keeps its section numbers.

- §1 (the JS runtime of `lib/src/js/`): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §1. The runtime has
  no `jsMax`, `jsMin`, `jsSquare`, `jsRound`, `jsDateNow` or fdlibm file now.
- §2 (the reference engine): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §2. All reference data come from
  the arm64 engine now. The frozen x64 fdlibm data are gone.
- §3 (the transcendental builtins and the protected sites): [Chart.js ADR 0146](0146-js-numeric-semantics.md)
  §3. `sin`, `cos`, `atan2` and `log` are `dart:math` as it is, and the port has no fdlibm code.
- §4 (the exact and correctly rounded builtins, `Math.pow(x, 2)` and `(e ?? 0)`):
  [Chart.js ADR 0146](0146-js-numeric-semantics.md) §4.
- §5 (the sort, `jsSort`): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §5.
- §6 (the clock): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §6. `Date.now()` is `clock.now()` there.
- §7 (the translation rules, ToBoolean and the forbidden forms): [Chart.js ADR 0146](0146-js-numeric-semantics.md)
  §7. [Chart.js ADR 0129](0129-int-indexes.md) makes each index an `int`.
- §8 (tool 3 and `js-ok`): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §8.
- §9 (the number formatting): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §9, with
  [Chart.js ADR 0119](0119-plain-intl-number-format.md).
- §10 (the tests): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §10.
- §10, last bullet (the hit queries on a border, the pie tie): [Chart.js ADR 0146](0146-js-numeric-semantics.md)
  §10, the bullet that starts with "Each hit query stays checked".
- Alternatives considered: [Chart.js ADR 0146](0146-js-numeric-semantics.md), Rejected.
- Consequences: [Chart.js ADR 0146](0146-js-numeric-semantics.md), Consequences.
- Open 1 (the Windows run, resolved on 2026-10-21): [Chart.js ADR 0146](0146-js-numeric-semantics.md) Open 1.
- Open 2 (no frame figure): removed by [Chart.js ADR 0146](0146-js-numeric-semantics.md). The `jsSin` and
  `jsCos` ports are gone, so no frame figure applies.
- Open 3 (`asin` and `pow` on protected paths): removed by [Chart.js ADR 0146](0146-js-numeric-semantics.md).
  The protected paths went with the fdlibm ports. Chart.js ADR 0146 §3 has the probe result of
  `math.pow(10.0, k)`.
- Open 4 (correctly rounded results): [Chart.js ADR 0146](0146-js-numeric-semantics.md) Open 4.
- Open 5 (an x64 engine for the fdlibm data): removed by [Chart.js ADR 0146](0146-js-numeric-semantics.md). No
  fdlibm data remain, so the port needs no x64 engine.
- Open 6 (the cross-port rule): [Chart.js ADR 0146](0146-js-numeric-semantics.md) Open 6.
