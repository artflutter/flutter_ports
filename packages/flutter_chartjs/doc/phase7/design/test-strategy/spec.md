# Controller test strategy: implementation spec

- Decision: [Chart.js ADR 0030](../../../adr/0030-controller-test-strategy.md) (proposed). This spec
  gives the work for the agents of the port waves. Where this spec and the ADR differ, the ADR
  wins. Report the difference to the phase lead.
- Package root below: `packages/flutter_chartjs/` (`<pkg>`). Upstream: `third_party/Chart.js` at
  `7169e651`.
- Environment: `doc/phase7/env-setup.sh` (the x64 Node.js v24.12.0, the Chart.js build at the pin,
  the moment packages). The generators run as
  `/usr/bin/arch -x86_64 <env>/node-v24.12.0-darwin-x64/bin/node tool/reference/<gen>.mjs <env>/chartjs-build/dist/chart.js`
  from `<pkg>`. The bar generator also needs `MOMENT_NODE_MODULES` and `TZ=UTC`.
- Rules for each agent: do not change an ADR status line or an accepted ADR. Never edit generated
  data by hand. A rerun of a generator gives byte-identical data. Compare resolvers through
  `jsObjectKeys` and `jsGet`, never with `equals` on a resolver. Kill each `flutter_tester` process
  that you leave. Prose in ASD-STE100.

## 0. Order of work

| Unit | When | Owner | Files (disjoint) |
|---|---|---|---|
| U0 test infrastructure | wave 1, after the unit S2 of `../work-plan.md` (S2 owns section 1.1 and the first row of section 1.8) | one agent | section 1 without 1.1 |
| U-bar, U-line, U-bubble, U-doughnut, U-polarArea, U-radar, U-scatter, U-pie | with the unit of the controller in its wave | the unit agent of the controller | section 2 for its controller |
| W-int (each wave) | end of each wave | the integration agent | `lib/src/controllers/index.dart`, `lib/src/index.dart`, the temporary `Chart.register` lines of the unit test files (section 2), the doc notes of section 6 |
| L1, L2, L3 (the lift) | step 4, after the integration of wave 1, 2 or 3 is green | lift agents, one group of spec files each | section 4 |
| T-theme | after wave 3 | one agent | section 3 |

U0 ends green before any unit of wave 1 adds its reference tests. A unit of wave 1 can port its
`lib/` file while U0 runs. The spec file of a controller (section 5) belongs to the unit of that
controller.

## 1. U0: test infrastructure

### 1.1 `lib/src/core/core.datasetController.dart`

This change and its test (the first row of section 1.8) belong to the unit S2 of
`../work-plan.md`: S2 is the only unit that changes DC in that part of wave 1. U0 starts after S2.

Change the field at `:685-689`:

```dart
/// core.datasetController.js:257 `_ctx`, the context of the chart.
/// controller.bar.js:677 reads it. Dart `null` stands for the JS `null` of
/// a chart without a context. It is writable, as the JS property: the
/// reference tests put a recording context here.
@internal
CanvasRenderingContext2D? ctx;
```

The initializer `: ctx = chart.ctx` (`:643`) stays. No `DIVERGES` marker, no `differences.md` row.
Run `dart analyze` on `apps/chartjs_gallery` too.

### 1.2 `tool/reference/scale_chart_common.mjs`

1. `drawCalls(chart)` (`:910-940`) loses the sink and its comment:

   ```js
   /**
    * The calls of one `chart.draw()`, after the layout, with the element
    * draws: the context of the chart is also the context of each scale and
    * of each dataset controller (core.datasetController.js:257). The Dart
    * test (drawCalls of scale_chart_harness.dart) puts its recording context
    * in the same three places.
    */
   export function drawCalls(chart) {
     const ctx = chart.ctx;
     ctx.resetCalls();
     chart.draw();
     const calls = dartCalls(ctx.getCalls());
     ctx.resetCalls();
     return calls;
   }
   ```

2. `dartCalls` (`:896`) and `jsonValue` get a `Path2D` branch: a value with
   `globalThis.Path2D && value instanceof globalThis.Path2D` becomes `{path: <id>, calls: [...]}`.
   The ids start at 1 in each `dartCalls` call, in the order of the first sight. The inner calls
   have the form of `line_reference.mjs` and `element.line_test.dart:145-192`. Export
   `dartCalls`, `jsonValue` and `CallsText`.
3. The header comment names the controller generators as users of the file.
4. Rerun the 8 generators: `scale_chart_harness_reference.mjs`, `scale_category_reference.mjs`,
   `scale_linear_reference.mjs`, `scale_linearbase_reference.mjs`,
   `scale_logarithmic_reference.mjs`, `scale_radial_linear_reference.mjs`,
   `scale_time_reference.mjs`, `scale_timeseries_reference.mjs`. Commit the 8 data files in the
   same change. Expected size: about +7.3 % (9,069,771 bytes in all). Run each twice and compare
   the SHA-256.
5. Run the 8 generators once more with `registerPhase7` in place of `registerPhase6` (a local
   edit, not kept). If the 8 outputs are byte-identical, keep `registerPhase6`. If not, move the 8
   generators to `registerPhase7` from `controller_chart_common.mjs` and commit that output.
   Record the result in `doc/phase7-progress.md`.

### 1.3 `test/port/scales/scale_chart_harness.dart`

Replace `drawCalls` (`:313-347`) and its doc comment:

```dart
/// The calls of one `chart.draw()`: `drawCalls(chart)` of the generators,
/// with the element draws.
///
/// The function puts a [RecordingContext] over `chart.ctx` in place of
/// `chart.ctx`, of the `ctx` of each scale (core.controller.js:357-362) and
/// of the `ctx` of each dataset controller whose context is the context of
/// the chart (core.datasetController.js:257 `_ctx`). Then it draws once and
/// puts back the old contexts. The layout is done already. Each `Path2D`
/// argument becomes `{path, calls}` (path2d_record.dart).
List<Object?> drawCalls(Chart chart) {
  final target = chart.ctx!;
  final recording = RecordingContext(target);
  final scales = chart.scales.values.toList();
  final scaleContexts = [for (final scale in scales) scale.ctx];
  final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
  final controllers = <DatasetController>[
    for (var i = 0; i < datasets.length; i++)
      if (chart.getDatasetMeta(i.toDouble()).controller
          case final DatasetController c when identical(c.ctx, target))
        c,
  ];
  chart.ctx = recording;
  for (final scale in scales) {
    scale.ctx = recording;
  }
  for (final controller in controllers) {
    controller.ctx = recording;
  }
  try {
    chart.draw();
  } finally {
    chart.ctx = target;
    for (var i = 0; i < scales.length; i++) {
      scales[i].ctx = scaleContexts[i];
    }
    for (final controller in controllers) {
      controller.ctx = target;
    }
  }
  return recordedCalls(recording.getCalls());
}
```

- `expectCalls(List<Object?> actual, Object? expected, {String reason})` takes the mapped calls.
  The existing callers do not change their arguments.
- Keep the other functions.
- Extract the key check and the `chartArea`, `scales`, `points` checks of `expectScaleChart`
  into `void expectScaleObservations(Map<String, Object?> observed, Map<String, Object?> expected)`
  so that the controller harness calls it for the keys `chartArea` and `scales`.

### 1.4 `test/port/canvas/path2d_record.dart` (new)

Line 1: `// Original code, not ported from Chart.js: the record form of Path2D arguments in the tests.`

Move `_PathIds`, `_actual`, `_actualCalls` and `_replay` of
`test/port/elements/element.line_test.dart:152-189` here, public:

```dart
/// The ids of the Path2D objects of one record, in the order of the first
/// sight, as the generators number them.
final class PathIds {
  int? of(Path2D? path);
}

/// The recorded calls [calls] with each Path2D argument as
/// `{'path': id, 'calls': [...]}`, the form of the generators.
List<Object?> recordedCalls(List<ContextCall> calls, [PathIds? ids]);

/// The calls of the commands of [path] on a new mock context.
List<ContextCall> replayPath(Path2D path);
```

`element.line_test.dart` imports it and loses its private copies. The file is not a pure layer if
it imports `chartjs_test_utils/flutter.dart`. Import only `pure.dart` and `lib/src/canvas/canvas.dart`
so that it stays pure.

### 1.5 `tool/reference/controller_chart_common.mjs` (new)

Header: `// Original code, not ported from Chart.js: shared code of the controller reference generators.`
and the usage block of `scale_chart_common.mjs`.

```js
// The Path2D of a browser, as a recorder of its path commands
// (line_reference.mjs:96-105). It must exist before loadChartJs() imports
// the dist: element.line.js:233 reads `typeof Path2D` when the module loads.
class Path2D { constructor() { this.calls = []; } }
for (const name of ['moveTo', 'lineTo', 'bezierCurveTo', 'quadraticCurveTo', 'arc', 'closePath']) {
  Path2D.prototype[name] = function (...args) { this.calls.push([name, args]); };
}
globalThis.Path2D = Path2D;

/** Chart.register(controllers, scales, elements): the built-in components of phase 7. */
export function registerPhase7(C);

/** The modes, intersect values and axes of the hit queries (ADR 0030 §5). */
export function hitQueries(chart); // [[mode, intersect, axis, includeInvisible], ...]

/** The integer query points of the chart (ADR 0030 §5). */
export function hitPoints(chart); // [[x, y], ...]

/** {points, queries, items}: items[p][q] is the list [[datasetIndex, index], ...]. */
export function hits(chart);

/** One observation (ADR 0030 §4). With scaleOptions, each scale has `options`. */
export function observeControllers(chart, {scaleOptions = false} = {});

/** Applies one step (ADR 0030 §6). */
export function applyStep(chart, step);

/**
 * One case: makeChart(config, options), `initial`, each step with its
 * observations, then drawCalls(chart), then the probes of `extras`.
 * Returns {name, config, options, expected: {initial, steps: [{do,
 * observations}], drawCalls, extra?, error?}}. A throw records
 * `error: {at, name}` (`at`: 'initial', 'step <k>' or 'draw'; `name`: the
 * name of the error class) and ends the case (Chart.js ADR 0030 §4).
 */
export function runControllerCase(name, config, {options = {}, steps = [], scaleOptions = false, extras = {}} = {});
```

- `extras` maps a probe name to a function `(chart) => value`. The generator writes each probe
  function as source text in a comment of the data file, so that the Dart test gives a function of
  the same name with the same body.

- The `Path2D` methods are the ones that `lib/src/elements/element.line.dart` and
  `helpers.segment` call on a path. Check the list with `grep -n "path\." src/elements/element.line.js`.
- The chart event of `hits`: `{type: 'mousemove', native: null, x, y}` (Chart.js ADR 0030 §5).
  `getRelativePosition` returns it as it is (`helpers.dom.ts:105-111`), and no mode reads a
  `chart` key of the event.
- `hitPoints`: the center (`Math.round` of `getCenterPoint()`) of each element of each dataset,
  the midpoint (`Math.round`) of each two neighbor centers in a dataset, the 4 corners of the chart
  area 1 px inside (`Math.ceil(left) + 1`, `Math.floor(right) - 1` and so on), and the point
  `[-5, -5]` outside the canvas.
- `hitQueries`: the modes `index`, `dataset`, `point`, `nearest`, `x`, `y`; `intersect` `true` and
  `false`; the axes `x`, `y`, `xy`, and `r` for `polarArea` and `radar`; `includeInvisible`
  `false`, and also `true` when a dataset or an index is hidden.
- `observeControllers` gives `{chartArea, scales, stacks, datasets, hits}`. `chartArea` and
  `scales` come from `observe` of `scale_chart_common.mjs:759`. With `scaleOptions`, each scale
  also has `options`: the plain copy (keys of `Object.keys`, a function as `'<fn>'`) of `grid`,
  `border`, `ticks` without `callback`, `title`, and for `radialLinear` also `angleLines` and
  `pointLabels`.
- The `datasets` keys, for each dataset index `i` with `meta = chart.getDatasetMeta(i)` and
  `controller = meta.controller`:

  | Key | Value |
  |---|---|
  | `type`, `indexAxis`, `xAxisID`, `yAxisID`, `rAxisID`, `stack`, `order`, `visible`, `hidden`, `_clip` | the meta fields; `visible` is `chart.isDatasetVisible(i)` |
  | `total` | `meta.total` (doughnut, pie; else absent) |
  | `_drawStart`, `_drawCount` | `controller._drawStart`, `controller._drawCount` (line, scatter; else absent) |
  | `maxOverflow` | `controller.getMaxOverflow()` |
  | `datasetOptions` | the plain copy of the listed keys of `controller.options` (bar: `barThickness`, `maxBarThickness`, `categoryPercentage`, `barPercentage`, `grouped`, `skipNull`, `stacked`, `minBarLength`; line and scatter: `showLine`, `spanGaps`, `segment`, `drawActiveElementsOnTop`; doughnut and pie: `cutout`, `rotation`, `circumference`, `radius`, `offset`, `spacing`, `spacingMode`, `borderAlign`, `animateRotate`, `animateScale`; polarArea: `spacing`, `spacingMode`, `startAngle`; radar: `showLine`, `spanGaps`; bubble: `radius`) |
  | `parsed` | `meta._parsed`: each item a plain copy; `_custom` as a value; `_stacks` as its keys only |
  | `dataset` | the line element or `null`: `_loop`, `_fullLoop`, `pointCount` (`points.length`), `segments` as `[start, end, loop]`, `options` |
  | `data` | for each element: the properties of its type (ADR 0030 §4), `active`, `hidden`, `center` (`getCenterPoint()`), `tooltipPosition` (`tooltipPosition()`) |
  | `options` | for each element: the plain copy of `element.options` |
  | `active` | for each element: the plain copy of `controller.resolveDataElementOptions(index, 'active')` |
  | `labelAndValue` | for each index: `controller.getLabelAndValue(index)` as `{label, value}` |

- `applyStep` runs the table of ADR 0030 §6. `hover` calls
  `chart._eventHandler({type: 'mousemove', chart, native: {type: 'mousemove'}, x, y})`.
  `mouseout` calls it with the type `mouseout` and the last point.

### 1.6 `test/port/controllers/controller_chart_harness.dart` (new)

Line 1: `// Original code, not ported from Chart.js: the Dart side of controller_chart_common.mjs.`
It is a library, not a test file. Its importers have `@TestOn('vm')`.

```dart
/// The chart event of the hit queries: `{type: 'mousemove', native: null,
/// x, y}`. getRelativePosition returns it as it is (helpers.dom.ts:109-111).
final class ReferenceEvent implements types.ChartEvent { ... }

/// The `hits` observation for the points and the queries of [expected]:
/// `getElementsAtEventForMode(e, mode, {intersect, axis, includeInvisible},
/// false)` for each point and each query.
Map<String, Object?> observeHits(Chart chart, Map<String, Object?> expected);

/// The observation of [chart] with the keys of `observeControllers` of
/// controller_chart_common.mjs. [scaleOptions] adds `scales.<id>.options`.
Map<String, Object?> observeControllers(
  Chart chart, {
  required Map<String, Object?> expectedHits,
  bool scaleOptions = false,
});

/// Expects [chart] to give [expected], an observation of the generator.
/// [label] names the observation in each reason: `initial` or `step <k>`.
/// With [parseColors], each color (section 3.1) compares in its parsed
/// form on both sides.
void expectControllerObservations(
  Chart chart,
  Object? expected,
  String label, {
  bool parseColors = false,
});

/// Applies one step of a case ([step] is the `do` list of the generator).
Future<void> runStep(WidgetTester tester, Chart chart, List<Object?> step);

/// A `testWidgets` case for each of [cases]: `acquireChart` with the config
/// and the options of the case ([copyReference] with [functions]), the
/// observations of `initial`, each step and its observations, then the
/// draw calls, then the probes of `extra` through [extras]. An `error` of
/// the case expects a throw at its place (Chart.js ADR 0030 §4). With
/// [theme], the config gets `themeConfigKey: theme`, the colors compare
/// parsed, `defaults` must be the same after the case, and the cases whose
/// names start with `parsed:` or `interfaces:` do not run. With [now], each
/// case runs in `atNow(now, ...)`.
void testControllerChartCases(
  List<ScaleChartCase> cases, {
  Map<String, Object?> functions = const {},
  Map<String, Object? Function(Chart chart)> extras = const {},
  AnyObject? theme,
  double? now,
});

/// The emitted paths of `light_snapshot.json` under `scale.` and
/// `scales.<type>.` must be in the observed `scales.<id>.options` of a
/// scale of that type. A path that is not there fails as a stale key.
void expectNoStaleScaleKeys(Chart chart, Map<String, Object?> lightSnapshot);
```

Code forms:

- The check reads exactly the keys of the expected Map. It fails on an expected key that no check
  reads, as `expectScaleChart` does (`scale_chart_harness.dart:521-526`).
- An options object becomes a plain Map through `jsObjectKeys` and `jsGet`. Never pass a resolver
  to `expect`.
- A Map compares as a Map (`referenceMatcher` of a Map: key order does not count). A List
  compares in order.
- Numbers: `referenceMatcher`. Hit items: `equals` (exact).
- A function value: `'<fn>'`. An absent property: the `undefined` sentinel.
- `getLabelAndValue` returns the record `({Object? label, String value})` (Chart.js ADR 0028 §2).
  The observation is `{'label': r.label, 'value': r.value}`. The label is the raw value: a
  string, a number, a List, Dart `null` or the `undefined` sentinel. It compares as any other
  value (a List in order, a number with `referenceMatcher`).
- An `error` `{at, name}`: the case runs to `at` and expects a throw there. `'TypeError'` expects
  a Dart `TypeError`. Another name fails the case unless the test file maps it to a Dart type
  with a `differences.md` row.
- `runStep`:

  ```dart
  Future<void> runStep(WidgetTester tester, Chart chart, List<Object?> step) async {
    switch (step) {
      case ['update']:
        chart.update();
      case ['update', final String mode]:
        chart.update(mode);
      case ['setDatasetVisibility', final num d, final bool v]:
        chart.setDatasetVisibility(d.toDouble(), v);
        chart.update();
      case ['toggleDataVisibility', final num i]:
        chart.toggleDataVisibility(i.toDouble());
        chart.update();
      case ['setActive', final List<Object?> items]:
        chart.setActiveElements([for (final [d, i] in items.cast<List<Object?>>())
          <String, Object?>{'datasetIndex': d, 'index': i}]);
        chart.update();
      case ['push', final num d, ...final values]:
        final data = _data(chart, d);
        data.addAll(values);
        notifyArrayListeners(data, 'push', values);
        chart.update();
      case ['splice', final num d, final num start, final num count, ...final items]:
        final data = _data(chart, d);
        jsSplice(data, start, count, items);
        notifyArrayListeners(data, 'splice', [start, count, ...items]);
        chart.update();
      case ['reset']:
        chart.reset();
      case ['hover', final num x, final num y]:
        await triggerMouseEvent(chart, 'mousemove', <String, Object?>{'x': x, 'y': y});
      case ['mouseout', final num x, final num y]:
        await triggerMouseEvent(chart, 'mouseout', <String, Object?>{'x': x, 'y': y});
      default:
        throw ArgumentError.value(step, 'step', 'Not a reference step');
    }
  }
  ```

  Check the real signatures of `setActiveElements`, `jsSplice` and `notifyArrayListeners` before
  you write the code. Follow the row `platform-array-events` for the order of the change and the
  notification. The generator writes the `mouseout` step with the last point, so that both sides
  have the same arguments.

### 1.7 `test/support/jasmine.dart` (new)

Line 1: `// Original code, not ported from Chart.js: the Jasmine matchers and spies of the spec ports.`
It copies no jasmine-core source. The doc comments name the Jasmine semantics of jasmine-core
3.99.1 (`third_party/Chart.js/pnpm-lock.yaml:9733`). Imports: pure layers of `lib/src`,
`package:chartjs_test_utils/pure.dart` if needed, and `package:test/test.dart` (as
`packages/chartjs_test_utils/lib/src/matchers.dart:42`). No `flutter_test`. Tool 1 needs no change:
it follows `test/` imports and checks their edges.

```dart
/// Jasmine `toEqual(expected)`: the `MatchersUtil.eq` semantics.
Matcher jasmineEquals(Object? expected);

/// `jasmine.objectContaining(expected)`.
Matcher objectContaining(Map<String, Object?> expected);

/// `jasmine.any(Function)`.
const Matcher anyFunction;

/// `spy.calls` of Jasmine.
final class JasmineCalls {
  void add(List<Object?> args);
  int count();
  List<Object?> argsFor(int index);
  List<List<Object?>> allArgs();
  ({Object? object, List<Object?> args}) mostRecent();
  ({Object? object, List<Object?> args}) first();
  void reset();
}

/// `spyOn(meta.data[index], 'draw')`: a draw spy of the class of the
/// element takes the slot. [callThrough] is `.and.callThrough()`.
JasmineCalls spyOnElementDraw(
  types.ChartMeta meta,
  int index, {
  bool callThrough = false,
});

/// `spyOn(meta.dataset, method)` for `'draw'` and `'updateControlPoints'`:
/// one line spy takes the slot `meta.dataset`. The calls of each method.
({JasmineCalls draw, JasmineCalls updateControlPoints}) spyOnDataset(
  types.ChartMeta meta, {
  bool callThrough = false,
});

/// `spyOn(controller, '_onData<X>')` for the 5 array methods: a listener
/// takes the place of [controller] in the listeners of [data]. The calls
/// by method name (`'_onDataPush'` and so on). `addTearDown` puts the
/// controller back.
Map<String, JasmineCalls> spyOnArrayListener(
  List<Object?> data,
  ArrayListener<Object?> controller,
);
```

The parameter type is `ArrayListener` of `lib/src/helpers/helpers.collection.dart` (a pure
layer), not `DatasetController`: `core.datasetController.dart` is not a pure layer, and
`check:lib-imports` follows the imports of this library from each web test. Check the type
argument that `DatasetController` gives to the mixin before you write the code.

The draw spies are four private subclasses: `_PointDrawSpy extends PointElement`,
`_BarDrawSpy extends BarElement`, `_ArcDrawSpy extends ArcElement` and
`_LineSpy extends LineElement`. Each copies `active` and `options` of the original element in its
constructor. The spied method records `[ctx, area, ...]` and returns. With `callThrough`, it
calls `super` after the record:

```dart
final class _BarDrawSpy extends BarElement {
  _BarDrawSpy(BarElement of, {required this.callThrough}) {
    active = of.active;
    options = of.options;
  }

  final bool callThrough;

  /// `element.draw.calls`.
  final JasmineCalls calls = JasmineCalls();

  @override
  void draw(CanvasRenderingContext2D ctx, [types.ChartArea? area]) {
    calls.add([ctx, area]);
    if (callThrough) super.draw(ctx, area);
  }
}
```

Check the constructors of the 4 element classes and the type of `meta.data` (`List<types.Element>`,
`core.controller.dart:298`) before you write the code. `DatasetController.draw` calls the draw of
the object in the slot (`core.datasetController.dart:1399-1415`).

Move these private copies into the library in the same change and import it:
`_toEqual`, `_JasmineEquals`, `_objectContaining`, `_JasmineObjectContaining` and their helpers of
`test/specs/core.controller_test.dart:62-200`; `_Calls`, `_Spy`, `_SpyStrategy` and `_spyOn` of
`core.plugin_test.dart:32-110`; `_Calls` of `helpers.canvas_test.dart`; and the other spec files
with `_objectContaining`, `_JasmineEquals` or `_toEqual` (`core.element`, `helpers.segment`,
`helpers.interpolation`, `helpers.easing`, `helpers.options`, `helpers.curve`). A helper that only
one file needs and that reads a file-private type (for example `_Options` of
`core.controller_test.dart`) stays in its file. The spec results must not change: run
`test:cases` before and after and compare the counts.

### 1.8 Tests of U0

| File | Test |
|---|---|
| `test/port/core/core.datasetController_chart_test.dart` (unit S2, with section 1.1) | "a write of ctx changes the context of the next draw": a chart, `controller.ctx = recording`, `chart.draw()`, the element calls are on `recording` (`core.datasetController.js:257`, `:713`) |
| `test/port/scales/scale_chart_harness_test.dart` | `drawCalls` records the point draws of the test controller; after the call, `chart.ctx`, each `scale.ctx` and each `controller.ctx` are the old contexts |
| `test/port/controllers/controller_chart_harness_test.dart` (new, `@TestOn('vm')`) | a `Path2D` argument records as `{path, calls}`; `ReferenceEvent` gives the hit of a point center with the mode `point`; each step of `runStep` on a chart of the phase 6 test controller (no real controller yet); an unknown expected key fails |
| `test/port/elements/element.line_test.dart` | passes with the shared helper |
| the spec files of 1.7 | the same `test:cases` counts |

Gates of U0: `format:check`, `analyze` (also `apps/chartjs_gallery`), `test --no-select`,
`test:web`, `check:port`.

## 2. U-<controller>: the reference tests of one controller

Files of the unit for the controller `<name>` (`bar`, `line`, `scatter`, `bubble`, `doughnut`,
`pie`, `polarArea`, `radar`; the snake form `<snake>` is `polar_area` for `polarArea`):

- `tool/reference/controller_<snake>_reference.mjs` (new). Header: the port-only marker and the
  usage. It imports `controller_chart_common.mjs` first, then calls `loadChartJs()`,
  `registerPhase7(C)`, the cases, and `writeReference(outPath, 'controller<Name>Reference', cases)`.
  The bar generator also calls `loadMomentAdapter(C)` and `appendAdapterInfo` of
  `scale_time_common.mjs`.
- `test/port/controllers/controller_<snake>_reference.dart` (generated).
- `test/port/controllers/controller.<name>_test.dart` (new):

```dart
// Original code, not ported from Chart.js: <name> controller reference tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_chartjs/src/theme/compile.dart';
import 'package:flutter_chartjs/src/theme/presets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
import 'controller_<snake>_reference.dart';
import 'controller_chart_harness.dart';

void main() {
  testReferenceOrigin(
    node: controller<Name>ReferenceNode,
    arch: controller<Name>ReferenceArch,
    dist: controller<Name>ReferenceDist,
    commit: controller<Name>ReferenceCommit,
  );
  testReferenceWidths(controller<Name>ReferenceWidths);
  testControllerChartCases(
    controller<Name>Reference,
    functions: _functions,
    extras: _extras,
  );
  group('theming.md §8 test 3: the light preset', () {
    testControllerChartCases(
      controller<Name>Reference,
      functions: _functions,
      theme: compileChartTheme(ChartThemes.light),
    );
  });
  // The pin tests without generated values (parsed-data spec §7.3,
  // interfaces spec §7.3): groups `parsed data` and `interfaces`.
}
```

- `_extras` maps each probe name of the generator (Chart.js ADR 0030 §4, key `extra`) to a Dart
  function with the same body.
- Registration: until the integration agent of the wave registers the controller, `main()` starts
  with `Chart.register([<Name>Controller.jsClass])` (Chart.js ADR 0030 §3 item 4). The same line
  stands at the start of `main()` of `test/specs/controller.<name>_test.dart`. Pie and scatter
  register their parent class too, if the parent is not registered yet. The integration agent
  removes these lines.

- The bar test adds `testAdapterOrigin(...)` and passes `now: controllerBarReferenceNow` to both
  calls.
- `_functions` maps each `'fn:<name>'` of the generator to a Dart function with the same body.
- The case list follows ADR 0030 §7 exactly (names and branches). The first case is `default`, with
  `scaleOptions: true`.
- A data file above 2.5 MB: the generator writes `controller_<snake>_reference.dart` and
  `controller_<snake>_reference_2.dart` from one case list, and the test file calls
  `testControllerChartCases` for both.
- A failed reference case is a defect of the port. Fix it in `lib/`. Never change the generator to
  match the port. One exception: a hit query at a point on the axis of symmetry of two arc centers
  can tie at the last bit of `Math.sin` or `Math.cos`, which differ by 1 ulp between V8 and
  `dart:math` (porting-flow.md §3). The generator then changes the data to remove the symmetry and
  records the reason in its doc (wave 3: the pie case `two datasets` has `[5, 15, 12, 20]`).
- The doughnut and pie test files map an expected JS `null` of `xAxisID` and `yAxisID` to
  `undefined` (`_undefinedAxisIds`, decision D12). Their empty `linkScales` keeps the JS `null`,
  and the Dart field `ChartMeta.xAxisID` is a `String?`.
- The generators have no step that writes an option. A pin test of an option change takes its
  expected values from a probe on the pinned build. The unit report records the probe source and
  its output, and the test comment names the report (wave 3: the group `showLine` of
  `controller.scatter_test.dart`).

The status text of the controller row in `doc/status.yaml` names the test file and the count:
"`test/port/controllers/controller.<name>_test.dart` compares N charts with upstream, and N more
with the light preset".

## 3. T-theme: theme tests 3, 5, hover and the blue screen

### 3.1 Test 3

Test 3 runs in the controller test files (section 2). T-theme checks that each of the 8 files has
the themed group. The color parse of `expectControllerObservations`:

- an option key that ends in `Color` or is `color`, at any depth of `options`, `active`,
  `datasetOptions`, `dataset.options` and `scales.<id>.options`;
- the argument of the calls `setFillStyle` and `setStrokeStyle`.

The parse is `Color(value).rgbString()` (`package:flutter_chartjs/src/kurkle_color/...`, as
`test/port/theme/presets_test.dart:39`). A value that does not parse compares as it is.
`expectNoStaleScaleKeys` runs in the themed `default` case of each file.

### 3.2 Test 5 and hover: `tool/reference/theme_precedence_reference.mjs`

- Register the pinned `src/controllers/controller.{bar,bubble,doughnut,line,pie,polarArea,radar,scatter}.js`
  in both modes, with the existing resolve hook. Update the header comment.
- 6 new `axes` scenarios (theming.md §8 item 5):
  - `axes of a bar chart without a theme`;
  - `axes of a bar chart with a radialLinear theme key` (a theme with `scales.radialLinear` keys);
  - `axes of a bar chart with the light preset`;
  - `axes of a doughnut chart without a theme`;
  - `axes of a doughnut chart with cartesian theme keys` (a theme with `scale`, `scales.category`
    and `scales.linear` keys);
  - `axes of a doughnut chart with the light preset`.
- The hover scenarios, for each of the 8 types:
  - the hover theme: `colors.backgroundColor` `rgb(200, 0, 0)`, `colors.borderColor`
    `rgba(0, 128, 0, 0.5)`, `colors.color` `rgba(51, 102, 153, 1)`;
  - the upstream run writes the replaced values `backgroundColor`, `borderColor` and `color` into
    `defaults` and removes them after the scenario;
  - the steps: `_eventHandler` `mousemove` at the rounded center of element 0 of dataset 0, then
    at the rounded center of element 1, then `mouseout`;
  - after each step, the lines: `active: <[[d, i], ...]>`, `element 0: <options>`,
    `element 1: <options>` (the options of `backgroundColor`, `borderColor`, `borderWidth`,
    `hoverBackgroundColor`, `hoverBorderColor`, and `radius` for a point).
  - The prototype run with the hover theme under `$theme` gives the same lines. The generator
    stops if the two runs differ.
- Run it with the x64 Node.js and commit `test/port/theme/precedence_reference.dart`.

### 3.3 `test/port/theme/precedence_test.dart`

- Group `test 5: a theme scale type creates no axis`: the 6 new scenarios through `_axes('bar',
  theme)` and `_axes('doughnut', theme)`, in the form of `:1700-1729`.
- New group `hover`: one `testWidgets` case for each of the 8 types. It builds the chart with
  `themeConfigKey: compileChartTheme(_hoverTheme)`, runs the 3 steps with
  `await triggerMouseEvent(chart, type, point)`, and compares the lines of each step with
  `themePrecedenceUpstream['hover <type>']`. It also compares `chart.getActiveElements()` with the
  `active` line.
- One absolute pin in the group: the active `backgroundColor` of the bar element 0 is `'#B40000'`.

### 3.4 `test/port/theme/blue_screen_test.dart` (new, `@TestOn('vm')`)

Line 1: `// Original code, not ported from Chart.js: theming.md §8 test 6 without plugins.`

```dart
/// The blue of the theme and of the background: #2050c0, alpha 1.
const int _blue = 0xFF2050C0;

/// A raw Map theme that sets each color token to [_blue].
const AnyObject _blueTheme = { /* each color token of compile.dart: (32/255, 80/255, 192/255) */ };

/// The bytes of the bitmap of [chart] over an opaque [background], as the
/// chart host paints it (chart_host.dart:706).
Future<ByteData> chartPixelsOver(WidgetTester tester, Chart chart, ui.Color background) async {
  final canvas = chart.canvas! as UiCanvasElement;
  final w = canvas.width;
  final h = canvas.height;
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder)
    ..drawRect(
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..color = background,
    );
  canvas.getContext2d().paint(c, ui.Offset.zero, 1, 1);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(w, h);
  try {
    return (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
    ))!;
  } finally {
    image.dispose();
    picture.dispose();
  }
}

/// The count of pixels of [data] that are not the RGBA [rgba].
int offPixels(ByteData data, int rgba);

/// The style setters of the draw calls of [chart] whose value does not
/// parse to [_blue] or to alpha 0, with the call index.
List<String> leakingSetters(Chart chart);

/// The known leaks of phase 7: chart type to the leaking setter values,
/// each with its upstream file:line. Empty in phase 7.
const Map<String, Set<String>> knownLeaks = {};
```

- Check the paint signature of `UiCanvasContext` (`lib/src/canvas/canvas_ui.dart:562`) and how
  the host gets the context (`chart_host.dart:706`).
- A first case: the compiled `_blueTheme` emits each color as a string that parses to
  `rgb(32, 80, 192)` with alpha 1.
- The 8 chart types: 2 datasets, labels, `scales.<id>.title.display: true`, borders on bars and
  arcs, point labels and angle lines on the radial types, `themeConfigKey: compileChartTheme(_blueTheme)`.
  No active element.
- Each case: `offPixels(..., 0x2050C0FF) == 0`, or the set of `leakingSetters` equals
  `knownLeaks[type]`. On a failure, the reason lists `leakingSetters(chart)`.
- A control case: the bar chart without the theme gives `offPixels > 0`.
- A last case: `defaults` (a deep plain copy through `jsObjectKeys`) is the same before and after
  the 8 themed charts.

## 4. L1-L3: the lift of the skips (step 4)

### 4.1 `doc/phase7/classification/lift_check.py` (new, temporary)

Python 3, run with `python3 -I`. Arguments: the path of `all.json`, the path of the JSON reporter
output, and an optional wave number.

- It reads the JSON reporter events (`testStart`, `testDone`, `group`, and the `skip` reason of
  `testStart`). It builds the full name: the group names and the test name, joined with spaces, as
  tool 5 does.
- For each record of `all.json` (the field `test`, the full name; the field `dartFile`):
  - `phase7` and its wave is at most the given wave: the test exists, is not skipped, and has the
    result `success`;
  - `blocked: plugin.<id>`: the test exists and skips with exactly that reason.
- The wave of a record: the largest wave of the modules of its `modules`
  (`controller.bar` 1; `controller.line`, `controller.bubble`, `controller.doughnut`,
  `controller.polarArea`, `controller.radar` 2; `controller.scatter`, `controller.pie`,
  `controllers/index` 3; other modules 0).
- With a wave number, it prints the lift list of that wave (the file, the full name and the
  current skip) with `--list`.
- It prints each record that fails a rule, and the counts by spec file against `summary.md` §2
  with D1 (`phase7` 503, legend 21, tooltip 11, filler 1). The exit code is 1 on a failure.

Command: `flutter test --reporter json test/specs test/port > /tmp/... ; python3 -I lift_check.py all.json out.json <wave>`
(use the scratchpad, not `/tmp`).

### 4.2 The lift

- L1 after wave 1, L2 after wave 2, L3 after wave 3. Each lift agent takes the list of
  `lift_check.py --list <wave>` for its group of spec files.
- The unit of each controller ports the records of its controller spec file (section 5). A lift
  agent edits a controller spec file only for a record that needs a module of a later wave than
  the unit of that file. At the pin, these are 3 cases of `controller.bar_test.dart` that need
  `controller.line` ("should correctly count the number of stacks ignoring datasets of other
  types and hidden datasets", "should correctly get the stack index accounting for datasets of
  other types and hidden datasets", "should get the correct bar points when datasets of different
  types exist"). U-bar writes them as placeholders with `skip: 'blocked: controller.line'`, and
  L2 lifts them. The 6 cases "should be registered as dataset controller" name the module
  `controllers/index` (wave 3), but they pass when the controller is registered (section 2,
  registration). Thus each unit writes their bodies. `lift_check.py` checks all records, and a
  failure of a unit record goes to that unit.
- L1, L2 and L3 change the same spec files. L1 ends before L2 starts, and L2 ends before L3
  starts.
- A placeholder becomes `testWidgets(name, (tester) async { ... })` with the body of the upstream
  case at its line. The name does not change. A case without a chart stays `test`.
- L2 changes `_lineTwin` (`test/port/scales/scale.time_test.dart:196-201`):

  ```dart
  /// A twin of a spec case that makes a chart of the type `line` with a
  /// dataset: a `testWidgets` case with the line controller of phase 7.
  void _lineTwin(String name, void Function() body) =>
      testWidgets(name, (tester) async => body());
  ```

- The first lift of a case in one of these files moves the whole file to `@TestOn('vm')`,
  `flutter_test` and `package:chartjs_test_utils/flutter.dart`, and removes `setUpSpecs()`:
  `core.datasetController_test.dart`, `core.interaction_test.dart`, `core.layouts_test.dart`,
  `core.ticks_test.dart`, `element.line_test.dart`. `check:lib-imports` must pass.
- The 3 cases of decision D1 are in the controller spec file (section 5), not in a lift list.
- The failure rule of ADR 0030 §12 item 8 applies. In short: probe first
  (`doc/phase7/probe/run_spec.mjs <dist> <spec> --mode none --filter '<it>'`), fix in `lib/` or in
  the harness, never change an assertion, never a new `blocked:` or `n/a:` skip, only a
  `diverges:` skip with a row and evidence, and a verdict change only with `compare.mjs` evidence
  and a decision of the phase lead.
- Gates of each lift: `test --no-select`, `test:cases` (0 failed, 0 missing in the ported spec
  files), `lift_check.py <wave>` green, `check:port`, `test:web`.

## 5. The 7 controller spec files

`test/specs/controller.{bar,bubble,doughnut,line,polarArea,radar,scatter}_test.dart`, one for each
unit of the controller (pie has no spec file).

```dart
// Ported from Chart.js v4.5.1+7169e651 test/specs/controller.bar.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

void main() {
  group('Chart.controllers.bar', () {
    // :2 describe('auto', jasmine.fixture.specs('controller.bar')): the form
    // of Chart.js ADR 0029.

    // Each `it` in the upstream order: `test` for a case without a chart,
    // `testWidgets` for a chart case.
    // ...
  });
}
```

- Names: character for character. A `+` with a JS value uses `jsToString`:

  ```dart
  group('Bar thickness with a category scale', () {
    for (final barThickness in <Object?>[undefined, 20]) {
      group('When barThickness is ${jsToString(barThickness)}', () {
        late Chart chart;
        void beforeEach() {
          chart = acquireChart(<String, Object?>{ /* :1466-... */ });
        }
        // ...
      });
    }
  });
  ```

- Jasmine `this`: `late` variables of the group closure. A `beforeEach` with a chart is
  `void beforeEach()`, called first by each test. An `afterEach` with a chart is
  `void afterEach()`, called last. A hook without a chart is `setUp` or `tearDown`.
- Spies: `final calls = spyOnElementDraw(meta, 0);` at the place of `spyOn(meta.data[0], 'draw')`.
  `expect(calls.count(), 1)` for `expect(meta.data[0].draw.calls.count()).toBe(1)`.
- `jasmine.objectContaining({...})` is `objectContaining(<String, Object?>{...})`.
  `.withContext(i)` is `reason: jsToString(i)`.
- `await jasmine.triggerMouseEvent(chart, 'mousemove', point)` is
  `await triggerMouseEvent(chart, 'mousemove', point)`.
- A nested Map literal of a config has the type `<String, Object?>`.
- The 9 plugin cases: `test(name, () {}, skip: 'blocked: plugin.tooltip')` (8) and
  `'blocked: plugin.filler'` (1, `controller.radar` "should update elements"). Put the upstream
  line in a comment above each placeholder.
- The 11 cases without a chart are `test` cases.
- Gate: `test:cases` reports 0 missing and 0 failed cases in the file.

The earlier spec files with the comment of a fixture group of phase 7 get the `auto` call when the
fixture runner of Chart.js ADR 0029 exists. That change belongs to the fixture runner work, not to
this spec. If it puts the group into `element.point_test.dart`, that file moves to `@TestOn('vm')`
in the same change.

## 6. Doc notes for the integration agent

- **AGENTS.md, Tests:**
  - Replace "The draw calls have no element draws, because `DatasetController.ctx` is final." with:
    "The draw calls have the element draws: `drawCalls` puts the recording context in `chart.ctx`,
    in each `scale.ctx` and in the writable `DatasetController.ctx` (Chart.js ADR 0030)."
  - Add a bullet: the controller reference tests in `test/port/controllers/` build each chart of
    their generator with `acquireChart`, run its steps, and compare the observations, the hit
    queries and the draw calls through `controller_chart_harness.dart`. Each file also runs its
    cases with the light preset (theming.md §8 test 3).
  - Add the controller generators to the generator list: `test/port/controllers/*_reference.dart`
    (the 8 controllers). They define a recording `Path2D` before the dist loads. The bar generator
    also needs the moment packages and `TZ=UTC`.
  - Replace the spy bullet: "A chart spec ports a Jasmine spy of a function value as a recording
    function value of the test file. A spy of a method is a spy object in the slot that the
    library reads (`meta.data[i]`, `meta.dataset`, the listeners of a data array, `chart.ctx`).
    `test/support/jasmine.dart` holds the shared matchers and spies (Chart.js ADR 0030)."
  - Jasmine `this`: `late` variables of the group closure.
- **AGENTS.md, Layout:** `test/port/controllers/` (the reference tests and their harness),
  `test/support/jasmine.dart`, `test/port/canvas/path2d_record.dart`.
- **porting-flow.md:** §2 gets a row in the table of decisions and "§2.23 Chart.js ADR 0030:
  Controller test strategy (gate 7)" with a short summary (the numbers of `../work-plan.md`,
  "Doc numbering"). §3 gets a paragraph "Reference tests of the controllers" (sections 1-7 of the
  ADR in short). §5, the phase 7 row: the counts of the lift, and the 8 pure cases (4 of them in
  `element.point`, for its `auto` group) that lost the web legs.
- **performance.md:** in the phase 7 section, the subsection "13.4 The writable
  `DatasetController.ctx`": the figures of ADR 0030 Evidence E3 (no frame effect, AOT and wasm),
  and Open item 3.
- **theming.md §10:** a "Phase 7 state" paragraph: test 3 in the 8 controller test files
  (themed groups), test 5 and the hover group in `precedence_test.dart`, the blue screen in
  `blue_screen_test.dart`, the empty known-leaks list. Remove "Test 3 for the 8 chart types, and
  test 5 on a doughnut and a bar chart, come with the controllers in phase 7." from "These parts
  wait".
- **doc/status.yaml:** the rows of the 7 controller spec files; the texts of the 15 spec files with
  lifted cases (remove the `blocked: controller.*` placeholders, keep `{{skipped:...}}` for the
  plugin reasons); the 5 moved files lose `on {{platforms}}` where they have it; the
  `core.datasetController.js` row: "`ctx` is writable, as the JS property `_ctx` (Chart.js ADR
  0030)"; each controller row names its reference test. Then `dart run melos run parity`.
- **doc/phase7-progress.md:** the decision line "Chart.js ADR 0030: controller test strategy"
  and the U0 result of section 1.2 item 5.
- No `differences.md` row.

## 7. DIVERGES rows

None. The writable `ctx` removes a difference of form. The tests and the tools add no hunk to a
ported file.

## 8. Checks before the end of each unit

- `dart run melos run format:check`, `analyze` (with `apps/chartjs_gallery`), `test --no-select`,
  `test:web`, `test:cases`, `check:port`.
- A rerun of each generator that the unit changed gives byte-identical data.
- No `flutter_tester` process stays.
