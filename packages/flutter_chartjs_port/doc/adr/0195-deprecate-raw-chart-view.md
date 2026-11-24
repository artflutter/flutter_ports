# Chart.js ADR 0195: Deprecate the raw ChartView config

- Status: accepted (2026-11-23): the deprecation is on `ChartView.raw`, and analyze and the port checks pass.
- Superseded by: [Chart.js ADR 0198](0198-remove-raw-chart-view.md) (2026-11-24)
- Date: 2026-11-23
- Supersedes: [Chart.js ADR 0052](0052-typed-public-api.md) §9, the item that makes `ChartView.raw` the escape
  hatch that stays
- Related: [Chart.js ADR 0192](0192-tooltip-options-object.md)

## Context

`ChartView.raw(config: Map)` takes the Chart.js config as a Map. Chart.js ADR 0052 §9 kept it as the escape
hatch for the options that `ChartConfig` did not have. The typed API now has most options, and the plugin
options are typed objects (Chart.js ADR 0192). A Map config has no compile-time check: a wrong key, a wrong
value type or a `null` in place of an object fails only at run time, and each review of the raw path finds new
edge cases.

## Decision

1. `ChartView.raw` has `@Deprecated`. Its message names the typed entry, `ChartView(config: ChartConfig(...))`,
   and says that the 0.1.0 release removes `ChartView.raw` and the raw Map config.
2. The behavior of `ChartView.raw` does not change in the beta.
3. A file that still uses `ChartView.raw` has a file-level ignore of `deprecated_member_use_from_same_package`
   (in `flutter_chartjs_port`) or `deprecated_member_use` (in another package or an app), with a comment line
   that names this ADR. New code does not use `ChartView.raw`.
4. The internal Map form of a config (the lowering output, `new Chart(canvas, config)`, the specs and the
   fixtures) is not part of this decision.

## Consequences

- The analyzer shows the deprecation to each app that uses `ChartView.raw`.
- The removal is a later change, with its own ADR: it moves the remaining users (the gallery zoom page, the
  stress and axes demos, the input probe and the widget tests) to typed configs first.
