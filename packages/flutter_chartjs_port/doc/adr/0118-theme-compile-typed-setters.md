# Chart.js ADR 0118: The theme compile writes typed setters and has no guard

- Status: accepted (2026-11-12): its code and the tests of section Tests pass.
- Superseded in part by: [Chart.js ADR 0141](0141-native-scale-border.md)
- Superseded by: [Chart.js ADR 0147](0147-public-theme-api.md) (2026-11-14)
- Date: 2026-11-12
- Supersedes: item 6 of [Chart.js ADR 0117](0117-typed-theme-tokens.md) (the emission guard stays as the debug
  assert of each emitted key); parts of [Chart.js ADR 0050](0050-public-theme-api.md): the sentence "A debug assert
  and a test enforce this list" of the never-emitted list, and the words "`_put` with its assert" in "No public `raw`
  in 0.1.0"; and the sentence of [Chart.js ADR 0054](0054-typed-internal-model.md) "The frozen Map of the compiled
  theme (an object under a key with no option kind) is `JsFrozenMap` of the JS runtime".
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0118-theme-compile-typed-setters.md`

## Summary

This ADR made the theme compiler write each key with the typed setter of its scope, in the order of the first
writes. The scale id `radialLinear` and the modes `theme` and `themeFrame` stayed keys by name. It removed the
emission guard `themeNeverEmittedReason`, its sets and `JsFrozenMap`. The never-emitted list stayed a design rule.
[Chart.js ADR 0147](0147-public-theme-api.md) now states the complete theme decision.

## Where each part went

- Item 1 (the typed setters in the order of the first writes): [Chart.js ADR 0147](0147-public-theme-api.md) §7.
- Item 2 (the keys by name `radialLinear`, `theme` and `themeFrame`): [Chart.js ADR 0147](0147-public-theme-api.md)
  §7.
- Item 3 (the removed guard, its sets and `JsFrozenMap`): [Chart.js ADR 0147](0147-public-theme-api.md) §7.
- Item 4 (the never-emitted list as a design rule and the guard of a later `raw`):
  [Chart.js ADR 0147](0147-public-theme-api.md) §7 and §12.
- Item 5 (the frozen scopes and palette Lists): [Chart.js ADR 0147](0147-public-theme-api.md) §8 and §10.
- Consequences (the typed-reads baseline and a change of the token table): removed. The baseline is a tool fact. A
  change of the token table follows from [Chart.js ADR 0147](0147-public-theme-api.md) §7.
