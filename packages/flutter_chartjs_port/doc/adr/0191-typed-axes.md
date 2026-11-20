# Chart.js ADR 0191: Typed axes with no ids

- Status: accepted (2026-11-20): the typed axes, the tests, the fixtures and the port checks pass.
- Date: 2026-11-20
- Supersedes: [Chart.js ADR 0052](0052-typed-public-api.md) §1, the parameter `scales` of `ChartConfig` and the
  parameters `xAxisID` and `yAxisID` of the datasets; §2, the order of `scales`
- Related: [Chart.js ADR 0190](0190-chart-type-from-first-dataset.md), [Zoom ADR 0007](../../../flutter_chartjs_plugin_zoom_port/doc/adr/0007-typed-zoom-limits.md)

## Context

A typed config gave its axes as a `Map<String, ChartAxis>`. The key had two jobs: a dataset named its axis by
the key (`yAxisID: 'right'`), and Chart.js read the direction of the axis from the first letter of the key. A
typo compiled and gave a second axis, and only the key made an axis vertical. A typed config must name an
axis by the axis object and give the direction as a value.

## Decision

1. `ChartConfig.scales` is a `List<ChartAxis>`. The order of the List is the order of `options.scales`.

   ```dart
   ChartConfig(
     datasets: [LineDataset(data: sales)],
     scales: [CategoryAxis(.x), LinearAxis(.y, beginAtZero: true)],
   );
   ```

2. A cartesian axis class takes its direction as its first parameter, a `CartesianAxis`. The static constants
   `CartesianAxis.x` and `CartesianAxis.y` give the dot shorthands `.x` and `.y`. `RadialLinearAxis` has no
   direction: its axis is `RAxis`. `ChartAxis.axis` gives the direction of each axis class.
3. The lowering gives each axis its scale id. The first axis of a direction has the id `x`, `y` or `r`. The
   next ones have the ids `x1`, `x2`, `y1` and so on, and the lowering also writes their option `axis`. A
   controller of another package that sets `overrides[type].scales.x` thus merges with the first x axis of
   the app.
4. The axes of `scales` are distinct by `==`. The lowering asserts it.
5. A cartesian dataset names its axes by the axis objects: `xAxis` and `yAxis` (`ChartAxis?`) replace
   `xAxisID` and `yAxisID`. The axis must be `==` to an item of `scales`, and the lowering asserts it. A null
   axis is the default of Chart.js: the first scale of the direction.

   ```dart
   const right = LinearAxis(.y, position: .right);
   ChartConfig(
     datasets: [LineDataset(data: sales), LineDataset(data: costs, yAxis: right)],
     scales: [LinearAxis(.y), right],
   );
   ```

6. The run time keeps the ids of Chart.js: `chart.scales`, `Scale.id`, `ScaleValuePosition` and the raw configs.
   `chart.scaleOf(axis)` and `chart.scaleIdOf(axis)` give the scale and the id of an axis of the current typed
   config of a `ChartView`, by `==`. A chart with no typed config gives `null`.
7. `ChartView.raw` keeps the `options.scales` Map of Chart.js.

## Rejected

- Named constructors `LinearAxis.y(...)`: each of six classes repeats its parameters twice.
- An `id` parameter: two names for one axis, and the typo stays.
- A default direction: a horizontal bar chart has its category axis on y, so a default is wrong for one form.
- A match by identity: a config that the app builds again at each frame makes new axis objects, so no dataset
  finds its axis.

## Consequences

- Each typed `scales:` Map becomes a List, and each axis constructor gets its direction.
- A dataset on a second axis keeps the axis object in a variable.
- Two equal axes need a field that differs, for example `position`.
- A position at a value of another axis stays in `extra` with the id of item 3:
  `extra: {'position': ScaleValuePosition('x', 0)}`.
- The specs of the upstream ids (`customIDx`, `xavier`) use raw configs.

## Tests

- `packages/flutter_chartjs_port/test/port/typed/axes_test.dart`
- `packages/flutter_chartjs_port/test/port/typed/lowering_test.dart`
- `packages/flutter_chartjs_port/test/port/typed/value_semantics_test.dart`
