# Chart.js ADR 0189: An open dataset class

- Status: accepted (2026-11-20): `Dataset` is open, `SankeyDataset` extends it, and the tests and the port checks pass.
- Date: 2026-11-20
- Supersedes: [Chart.js ADR 0052](0052-typed-public-api.md) §1, the item "`Dataset` is `abstract final`, not `sealed`"
- Related: [ADR 0009](../../../../docs/adr/0009-add-on-ports.md), [Sankey ADR 0004](../../../flutter_chartjs_chart_sankey_port/doc/adr/0004-typed-sankey-dataset.md)

## Context

Upstream, a dataset is a plain object, and an add-on package adds its chart type to the TypeScript
interface `ChartTypeRegistry` by declaration merging. The typed API had `abstract final class Dataset`:
the lowering read four private members, so no package could add a dataset class. A chart type of
another package ran only through `ChartView.raw` with a Map (seam S9 of the sankey port), although
`ChartKind` already takes the id of any registered controller.

## Decision

1. `Dataset` is an `abstract base class`. A package extends it with a `final` class. No class can
   implement it, so each dataset takes the shared lowering and the `==` rules.

   ```dart
   final class const SankeyDataset({super.label, final List<SankeyDataPoint>? data})
       extends Dataset { ... }
   ```

2. The lowering reads five public members, each `@protected`: `kind` (the controller id), `chartData`
   (the `data` List, by reference), `lowerOwn(OptionScope scope)`, `props` (the parameters for `==`,
   `hashCode` and the diagnostics) and `styleProps` (the parameters of `Dataset` for `props`).
3. `lowerDataset` keeps its order: `type` when `kind` differs from the chart type, `label`, `data`, the
   parameters of `Dataset`, then `lowerOwn`, `shadow`, the tooltip callbacks and `extra`. A key with no
   `OptionKey` goes by its name (`scope['colorFrom'] = value`), so the chart reads the same cells as
   from a raw dataset Map.
4. `Dataset` has no `copyWith`. Each class declares its own `copyWith` with its own parameters.
5. A subclass takes only the parameters of `Dataset` that its chart type reads, with `super.<name>`.

## Rejected

- A closed class, with add-on chart types through `ChartView.raw`: an add-on chart type then has no typed
  API, which upstream gives through `ChartTypeRegistry`.
- An `interface` class: an implementation could skip the shared lowering and the `==` rules.
- An abstract `copyWith` with the parameters of `Dataset`: it forces each add-on to take the colors of
  the built-in classes, for example the `backgroundColor` that the sankey options do not have.
- The color parameters in the 8 built-in classes and not in `Dataset`: a larger change with no gain for
  an add-on now.

## Consequences

- The five members are a contract with the add-on packages: a change of them breaks an add-on.
- A wrong `props` in an add-on gives missed or extra updates of its own charts only.
- Code that called `copyWith` on a value of the static type `Dataset` calls it on the concrete class.
- A subclass keeps the inherited color fields of `Dataset`, with `null` when it does not take them.

## Tests

- `packages/flutter_chartjs_port/test/port/typed/lowering_test.dart`
- `packages/flutter_chartjs_port/test/port/typed/value_semantics_test.dart`
- `packages/flutter_chartjs_port/test/port/typed/chart_value_test.dart`
- `packages/flutter_chartjs_chart_sankey_port/test/port/sankey_dataset_test.dart`
