# Chart.js ADR 0190: The chart type comes from the first dataset

- Status: accepted (2026-11-20): `ChartConfig` has no `type`, and the tests, the fixtures and the port checks pass.
- Date: 2026-11-20
- Supersedes: [Chart.js ADR 0052](0052-typed-public-api.md) §1, the parameter `required this.type` of `ChartConfig`
- Related: [Chart.js ADR 0189](0189-open-dataset-class.md), [Sankey ADR 0004](../../../flutter_chartjs_chart_sankey_port/doc/adr/0004-typed-sankey-dataset.md)

## Context

Each typed config repeated its chart type: `type: .line` next to a `LineDataset`. The class of a dataset
already selects its controller, and since Chart.js ADR 0189 a package gives the class of its own chart
type. The chart type selects only the chart-level defaults (`overrides[type]`): the default axes, the
aspect ratio, the legend of a pie chart and the interaction mode.

## Decision

1. `ChartConfig` has no `type` parameter. The getter `ChartConfig.type` gives the `kind` of the first
   dataset.

   ```dart
   ChartConfig(labels: months, datasets: [LineDataset(data: sales)]); // line
   ChartConfig(datasets: [SankeyDataset(data: flows)]);               // sankey
   ```

2. A chart needs one dataset at least. The lowering asserts it: a debug build stops on an empty
   `datasets` List, and a release build takes `ChartKind.line`. A chart with no data yet gives a dataset
   with no data, for example `LineDataset(data: [])`.
3. A mixed chart takes the chart-level defaults of its first dataset. Each other dataset writes its own
   `type`, as before. The option `order` of a dataset still sets the draw, legend and tooltip order.
4. A custom controller has its own dataset class (Chart.js ADR 0189). A config cannot name a chart type
   that no dataset class gives.
5. `ChartView.raw` keeps the `type` of the Chart.js config.

## Rejected

- An optional `type` that overrides the first dataset: two places can then name the type.
- A dataset parameter `type`: the class already names the controller.
- A fallback to line with no assert: a pie chart that starts empty shows axes until its data arrives.

## Consequences

- 761 configs and the doc examples lose their `type` line.
- The upstream specs with no dataset give a dataset with no data of the old chart type.
- The test controllers of the specs take `TestDataset` of `test/support/test_dataset.dart`.
- The mixed sample of the gallery (`docs/charts/mixed.md`) takes the defaults of its first dataset, a bar
  dataset, where upstream gives `type: 'scatter'`.

## Tests

- `packages/flutter_chartjs_port/test/port/typed/value_semantics_test.dart`
- `packages/flutter_chartjs_port/test/port/typed/lower_data_only_test.dart`
- `packages/flutter_chartjs_port/test/port/typed/config_test.dart`
