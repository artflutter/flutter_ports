# Chart.js ADR 0198: Remove the raw ChartView config

- Status: accepted (2026-11-24): its code is on main, and the gates of AGENTS.md pass.
- Date: 2026-11-24
- Supersedes: [Chart.js ADR 0195](0195-deprecate-raw-chart-view.md)
- Related: [Chart.js ADR 0052](0052-typed-public-api.md), [Chart.js ADR 0049](0049-chart-view-widget.md)

## Context

Chart.js ADR 0195 deprecated `ChartView.raw(config: Map)` and planned its removal in its own ADR, after the
remaining users moved to typed configs. Since then no app and no test calls `ChartView.raw`: the gallery zoom page,
the stress and axes demos, the input probe and the widget tests pump typed views. The widget still carries a second
config form, a second change test (identity of the Map) and a data path for the raw data Map.

## Decision

1. `ChartView` takes only a typed `ChartConfig`. `ChartView.raw`, its field `rawConfig` and the raw branch of each
   member of the widget are gone.

   ```dart
   // Before
   const new({required ChartConfig this.config, ...}) : rawConfig = null;
   @Deprecated('Use ChartView(config: ChartConfig(...)). ...')
   const new raw({required Map<String, Object?> config, ...})
     : rawConfig = config, config = null, dataOnlyUpdates = false;
   final ChartConfig? config;
   final Map<String, Object?>? rawConfig;

   // After
   const new({required this.config, ...});
   final ChartConfig config;
   ```

2. The change test is the `==` of two typed configs (Chart.js ADR 0052 §9). The state lowers each config through
   one `ChartConfigLowering` for its life.

   ```dart
   // Before
   if (config != null) { ... } else if (oldWidget.config != null ||
       !identical(oldWidget.rawConfig, widget.rawConfig)) { _scheduleUpdate(); }

   // After
   _lowering.config = widget.config;
   if (oldWidget.config != widget.config) _scheduleUpdate();
   ```

3. A new data object of a config goes to the chart as the `ChartDataScope` of the lowering. `Config.dataScopeOf`,
   the boundary of the raw data Map of `ChartView.raw`, is gone. `recordScaleIds` takes the non-null scale ids.

   ```dart
   // Before
   chart.data = Config.dataScopeOf(data);
   recordScaleIds(_canvas, typed == null ? null : _lowering!.scaleIds);

   // After
   chart.data = data! as ChartDataScope;
   recordScaleIds(_canvas, _lowering.scaleIds);
   ```

4. The Map form of a config stays for `new Chart(canvas, config)`: the specs, the fixtures, the reference tests,
   the frameless benchmark and the stress host of the gallery build charts from Map configs. The Map paths of the
   core and of `ChartThemeSwitch` that such a chart reaches stay.

## Rejected

- Keep `ChartView.raw` until 0.1.0: no user remains, and each review of the raw path found new edge cases.

## Consequences

- A breaking change of the beta: an app with `ChartView.raw` moves to `ChartView(config: ChartConfig(...))`, with
  `extra` for an option that `ChartConfig` does not have.
- The widget has one config form, so the docs of `ChartView` state one set of update rules.

## Tests

- `test/port/widgets/chart_view_test.dart`
- `test/tool/public_api_test.dart`
