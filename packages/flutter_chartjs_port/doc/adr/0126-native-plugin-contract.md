# Chart.js ADR 0126 proposal: A native plugin contract

- Status: superseded (2026-11-14) by [Chart.js ADR 0144](0144-native-plugins.md), which states the decision as built.
- Superseded by: [Chart.js ADR 0144](0144-native-plugins.md) (2026-11-14)
- Date: 2026-11-13
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0126-native-plugin-contract.md`

## Summary

It proposed one class `Plugin<O>` with a typed field for each hook, with no slot List and no Map plugins.
A cancelable hook returns `bool`, and each other hook returns `void`. The arguments and the metadata get exact types.
No code implemented the proposal as written. [Chart.js ADR 0144](0144-native-plugins.md) states the built decision.
It corrects two points. A cancel ends the notify at once, and a named hook of an add-on still casts its chart.

## Where each part went

- Item 1 (one class with typed hook fields): [Chart.js ADR 0144](0144-native-plugins.md) item 1.
- Item 2 (the two hook kinds and the hook table): [Chart.js ADR 0144](0144-native-plugins.md) items 2 and 3,
  with the arguments in item 4.
- Item 3 (the typed arguments): [Chart.js ADR 0144](0144-native-plugins.md) item 4.
- Item 4 (the plugin options `O`): [Chart.js ADR 0144](0144-native-plugins.md) item 5.
- Item 5 (the typed metadata): [Chart.js ADR 0144](0144-native-plugins.md) item 6.
- Item 6 (no Map plugins): [Chart.js ADR 0144](0144-native-plugins.md) item 7.
- Item 7 (a final class with function fields): [Chart.js ADR 0144](0144-native-plugins.md) item 1.
  `Plugin` is a `final class` in `lib/src/types/plugin.dart`.
- Item 8 (the order and the identity): [Chart.js ADR 0144](0144-native-plugins.md) item 8. The first `false`
  ends the notify at once, as upstream.
- Migration (the six steps): done. [Chart.js ADR 0144](0144-native-plugins.md) section Tests lists the tests.
  Item 10 states the cast of the chart in a zoom hook.
- Open 1 (the specs that read a plugin by name): [Chart.js ADR 0144](0144-native-plugins.md) item 9 and
  Consequences.
- Open 2 (the update mode as an enum): [Chart.js ADR 0144](0144-native-plugins.md) Open 1.
- Open 3 (the cost of the `O` view): [Chart.js ADR 0144](0144-native-plugins.md) item 5. The `options` function
  makes `O` at each hook call, with no cached view.
