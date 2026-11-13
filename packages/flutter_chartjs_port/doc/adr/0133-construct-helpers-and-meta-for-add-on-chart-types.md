# Chart.js ADR 0133: The construct helpers, the meta and a recording context for add-on chart types

- Status: accepted (2026-11-13): the tests of each package and the port checks pass.
- Date: 2026-11-13
- Related: [ADR 0009](../../../../docs/adr/0009-add-on-ports.md) (add-on ports), Chart.js ADR 0020 (the class
  values), Chart.js ADR 0129 (an index is an int), Chart.js ADR 0132 (exports for add-on chart types),
  [the host seams of the sankey port](../../../flutter_chartjs_chart_sankey_port/doc/host-seams.md) (seams S2, S3,
  S8 and S13).
- Supersedes: of Chart.js ADR 0048 §6, the `@internal` of `DatasetController.cachedMeta`.

## Context

Chart.js ADR 0132 gave a chart type of another package the names that it could not work without. The sankey port
then recorded each Dart form that it used in place of a host change. Four of them have one plain fix each:

- The class value of a controller needs a `construct` closure. Each host controller reads its arguments with
  `controllerArgs`, which was `@internal`. The sankey class value read the List itself. It also found that
  `Chart.buildOrUpdateControllers` gave the dataset index as a `double`, a rest of the time before Chart.js ADR 0129.
- The class value of an element reads its argument with `elementCfgArg`, which was `@internal`. A scale has
  `scaleCfgArg`, which was public but not exported.
- An upstream controller reads the protected `this._cachedMeta`. The Dart member `cachedMeta` was `@internal`, so a
  controller of another package called `getMeta()`, which finds the same object through the chart.
- A spec that spies on a canvas method and then draws (`vi.spyOn(chart.ctx, 'fillRect')`) needs a context that
  records and that `chart.draw()` accepts. The mock context of the harness has no `canvas` and no `resetTransform`.
  The host tests had such a class in their own `test/` folder, and the sankey tests had a copy.

## Decision

1. `lib/chartjs.dart` exports `controllerArgs`, `elementCfgArg` and `scaleCfgArg`. The first two lose `@internal`.

   ```dart
   static final JsClass jsClass = JsClass(
     'SankeyController',
     superclass: DatasetController.jsClass,
     statics: {'id': id, 'defaults': defaults, 'overrides': overrides},
     construct: (newTarget, args) {
       final (:chart, :datasetIndex) = controllerArgs(args);
       return SankeyController(chart, datasetIndex, newTarget);
     },
   );
   ```

2. `Chart.buildOrUpdateControllers` gives the dataset index as an `int` (Chart.js ADR 0129). `controllerArgs`
   takes a `num`, as before.

3. `DatasetController.cachedMeta` is public. `test/tool/public_api_test.dart` lists it in `_publicUnderscore` with
   its reason.

   ```dart
   final data = cachedMeta.data;
   ```

4. `package:chartjs_test_utils/pure.dart` exports `RecordingContext`: a `MockContext` over a real context. It
   records each call and gives `font`, `save`, `restore`, `measureText`, `canvas` and `resetTransform` to the real
   context. The host class of the reference tests extends it (`ReferenceRecordingContext` of
   `test/port/scales/scale_chart_harness.dart`).

   ```dart
   final target = chart.ctx!;
   final recording = RecordingContext(target);
   chart
     ..ctx = recording
     ..draw()
     ..ctx = target;
   ```

## Consequences

- The sankey port loses four workarounds: its two `construct` closures, its seven `getMeta()` calls and its copy
  of the recording context. Its seams S2, S3, S8 and S13 have the state `connects`.
- The seams that stay need a shape from the maintainer: the public names of the interface types in the override
  signatures (S4), the options and the defaults of an add-on (S10, S11, S14), the element properties (S12), the
  typed dataset of another package (S9) and the theme extension (S15).
