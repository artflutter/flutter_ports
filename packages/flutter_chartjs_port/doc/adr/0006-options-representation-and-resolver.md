# Chart.js ADR 0006: Options representation and resolver

- Status: accepted (2026-10-18)
- Superseded by: [Chart.js ADR 0043](0043-options-representation-and-resolver.md) (2026-10-23)
- Date: 2026-10-17
- Full text: `git show 2ee913263ba0fad4d08b0e9744c3a86575286268:packages/flutter_chartjs_port/doc/adr/0006-options-representation-and-resolver.md`

## Summary

This ADR made each option scope a `Map<String, Object?>`. The port kept three JS states apart: an absent key,
a stored `undefined` sentinel and JS `null`. The resolver read an absent key and the sentinel alike.
`mergeIf`, `_cached` and the key order tested own-key presence. `Resolver` and `ContextResolver` replaced the
`Proxy` traps. Release 0.1.0 took raw Map configs.

## Where each part went

- Scopes are Maps: [Chart.js ADR 0043](0043-options-representation-and-resolver.md) kept the rule.
  [Chart.js ADR 0054](0054-typed-internal-model.md) §3 and §5 replace it with typed scopes. A Map of the user
  stays at the raw boundary.
- Three states: [Chart.js ADR 0054](0054-typed-internal-model.md) §1.
- The sentinel (`undefined` and the `identical` test): [Chart.js ADR 0054](0054-typed-internal-model.md) §1.
- Resolver rule (the walk skips the sentinel, `mergeIf` sees it):
  [Chart.js ADR 0054](0054-typed-internal-model.md) §1.
- Resolver classes: [Chart.js ADR 0054](0054-typed-internal-model.md) §4 (`OptionResolver` and `OptionView`).
- Global scopes (`defaults`, `overrides`, `descriptors` and the routes):
  [Chart.js ADR 0054](0054-typed-internal-model.md) §3.
- Raw configs in 0.1.0: [Chart.js ADR 0052](0052-typed-public-api.md) adds the typed configs.
  [Chart.js ADR 0054](0054-typed-internal-model.md) §17 keeps the raw configs beside them.
- Values outside scopes: [Chart.js ADR 0054](0054-typed-internal-model.md) §17 keeps the rule.
- Tests: [Chart.js ADR 0043](0043-options-representation-and-resolver.md), "Tests".
  [Chart.js ADR 0054](0054-typed-internal-model.md) §15 gives the checks and the oracles of the typed model.
- A class instance is a leaf (Consequences): [Chart.js ADR 0043](0043-options-representation-and-resolver.md),
  "The leaf rule" and "Merge into an element". [Chart.js ADR 0054](0054-typed-internal-model.md) §17 keeps
  both.
