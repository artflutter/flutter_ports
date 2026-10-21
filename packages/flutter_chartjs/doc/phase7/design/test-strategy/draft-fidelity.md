# Controller test strategy: draft with the lens "fidelity first"

- Panel: "Controller test strategy" of phase 7, step 2 (Design). The synthesis becomes Chart.js ADR
  0030 (proposed).
- Lens: fidelity first. The upstream behavior and the upstream structure get the most weight. This
  draft accepts a cost only when a probe shows that the cost is small.
- Scope: the tests of phase 7 other than the spec ports and the fixtures: (1) the port-only
  reference tests of the controllers, (2) the theme tests of the phase 7 row of `theming.md` §10,
  (3) the lift of the skips, (4) the conventions of the 7 controller spec files.
- Probes: `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/test-strategy-fidelity/`
  (below: `<probes>`). A command can make each probe again. Section 7 lists them with their
  figures.

## 0. Decisions in short

| Id | Decision | Main evidence |
|---|---|---|
| T1 | The reference tests record the element draws. `DatasetController.ctx` becomes a writable field, as the upstream `_ctx` property. The Dart harness writes it, as the generator writes `controller._ctx`. | `core.datasetController.js:257`, `:713`; `controller.bar.js:677`; P3 (no cost); P1 |
| T2 | The controller generators define a recording `Path2D` before they load the dist. The browser and the port draw a line through `Path2D`. Node.js has none. | `element.line.js:233-236`; `element.line.dart:585-601`; P1b |
| T3 | One shared file `controller_chart_common.mjs` on top of `scale_chart_common.mjs`, and one generator for each of the 8 controllers. One Dart harness `controller_chart_harness.dart`, and one test file for each controller at the mapped path. | AGENTS.md rule 2; phase 6 form; P1 (rerun byte-identical) |
| T4 | A reference case records: the scale observations of phase 6, the meta of each dataset, the element properties, the resolved options (default and active), the dataset options that the controller reads, the parsed items, the stacks, `getLabelAndValue`, the hit elements of `getElementsAtEventForMode` (6 modes, both `intersect` values, each axis), and the draw calls with the element draws. A case can run steps (update, visibility, data changes, reset, hover). | ADR 0009 protected set; P1 |
| T5 | Theme test 3 and the hover tests use a new generator `theme_charts_reference.mjs` on the same dist path. Test 5 on a bar chart and a doughnut chart extends `theme_precedence_reference.mjs` with the real controllers. | `theming.md` §8 items 3, 5; §10 |
| T6 | The blue screen reads the pixels of the chart canvas through `UiCanvasContext.paint` on a blue rectangle, `Picture.toImage` and `Image.toByteData` in `tester.runAsync`. No golden file. A negative control and a draw-call scan go with it. | P2 (blue on blue is exact; a 10 % leak shows) |
| T7 | The lift follows the waves. A case lifts in the wave that ports the last controller of its `modules` (classification `all.json`). A failed case after the lift is a defect. The only other results are a `diverges` row with a probe, or a plugin block with a probe of `without:<id>`. Tool 5 gets a "stale block" error. | classification summary §1-§3 |
| T8 | The 5 pure spec files that get chart cases move to `@TestOn('vm')` and `flutter_test` as a whole (the existing rule). 4 pure cases lose their web legs. Their modules keep web coverage through `test/port/`. | AGENTS.md Tests; tool 5 file mapping |
| T9 | Spec conventions: exact names (dynamic name parts through `jsToString`), the `auto` group at the upstream position, `beforeEach` and `afterEach` with a chart as local functions with a Jasmine `this` record, a spy on a method as a substitute object in the slot of the spied object (P5), and one shared port-only Jasmine support library. | ADR 0022 §2; `helpers.canvas_test.dart:37-79`; P5 |

## 1. Port-only reference tests of the controllers

### 1.1 What the reference tests compare

The protected behavior of Chart.js ADR 0009 is the ticks, the hit element, the item order, the
resolved option and a throw. A controller produces each of them:

- The ticks: the scale range comes from `getMinMax` of the controllers (stacked bars, floating
  bars, hidden datasets).
- The hit element: `getElementsAtEventForMode` reads the element properties that `updateElements`
  writes (`core.controller.js:820`).
- The item order: the draw order of the elements (`core.datasetController.js:730-741`: a hidden
  element does not draw, an active element draws last with `drawActiveElementsOnTop`), the order
  of the hit items, the order of the parsed items and of the stack keys.
- The resolved option: the element options of the modes `default` and `active`
  (`core.datasetController.js:803-835`, `:915-935`).

Options for the observations:

| Option | Content | Fidelity |
|---|---|---|
| A. Phase 6 form | `observe` of `scale_chart_common.mjs:759`: chart area, scales, `[x, y]` of each element; draw calls without element draws | Misses the bar width, base, arc angles, options, stacks, hits and the draw order |
| B. Spec-level values | Only the values that the upstream specs assert | The specs assert few values per chart; the variants of the kickstart are not covered |
| C. Full controller observations (chosen) | A plus the meta, the element properties, the options, the parsed items, the stacks, `getLabelAndValue`, the hit elements and the draw calls with the element draws | Covers each item of the protected set |

Choice: C. P1 shows that one shared `observe` gives all keys for 7 chart types on the pinned dist.

Keys of the expected Map of a case (`expected`):

- `initial`: the observations after `acquireChart`.
- `steps`: for each step, `{do: [...], observations: {...}}` (section 1.6).
- `drawCalls`: the calls of one `chart.draw()` after the last step, with the element draws.

Keys of one observation:

- `chartArea` and `scales`: the keys of `observe` of `scale_chart_common.mjs:759` (reused as they
  are).
- `stacks`: `chart._stacks` (`core.datasetController.js:154-174`; Dart `Chart.stacks`), each stack
  with its index keys, `_top`, `_bottom` and `_visualValues`.
- `datasets`: for each dataset:
  - `type`, `indexAxis`, the axis ids, `stack`, `order`, `visible`, `hidden`, `_clip`, `total`
    (doughnut), `_drawStart` and `_drawCount` (line, scatter: `controller.line.js:46-48`),
    `getMaxOverflow()`.
  - `datasetOptions`: the dataset options that the controller reads through `this.options`
    (bar: `barThickness`, `maxBarThickness`, `categoryPercentage`, `barPercentage`, `grouped`,
    `skipNull`, `stacked`; line: `showLine`, `spanGaps`, `segment`; doughnut: `cutout`,
    `rotation`, `circumference`, `radius`, `offset`, `spacing`, `borderAlign`; polarArea:
    `spacing`, `spacingMode`; radar: `showLine`). A function value is `'[Function]'`.
  - `parsed`: `meta._parsed`. `_custom` stays a value. `_stacks` gives only its keys, because its
    values are the objects of `stacks`.
  - `dataset`: the dataset element (line, radar, scatter with `showLine`): its properties
    (`_loop`, `_fullLoop`, the count of `points`, `segments` as `[start, end, loop]`) and its
    options.
  - `data`: for each data element, the properties of its type (point: `x`, `y`, `skip`, `stop`;
    bar: `x`, `y`, `base`, `horizontal`, `width`, `height`; arc: `x`, `y`, `startAngle`,
    `endAngle`, `innerRadius`, `outerRadius`, `circumference`, `fullCircles`), `active`, `hidden`,
    `getCenterPoint()` and `tooltipPosition()`.
  - `options` and `active`: for each data element, `element.options` and
    `controller.resolveDataElementOptions(i, 'active')`, as the keys of `Object.keys` (Dart
    `jsObjectKeys`) in order, with their values.
  - `labelAndValue`: `getLabelAndValue(i)` for each index (risk R2 of `members-radial.md`).
- `hits`: section 1.4.

An absent property gives the sentinel `undefined` on both sides (`writeReference` of
`scale_chart_common.mjs:1051` already writes it). The arc fields start as `undefined` before the
first update (risk list of `members-radial.md`). Thus `undefined` is a value to compare, not NaN.

### 1.2 The element draws (T1)

Facts:
- Upstream: `this._ctx = chart.ctx` (`core.datasetController.js:257`). `draw()` reads
  `this._ctx` (`:713`). `controller.bar.js:677` draws each bar on `this._ctx`. `_ctx` is a plain
  JS property. Any code can write it.
- Port: `final CanvasRenderingContext2D? ctx` (`core.datasetController.dart:689`). `draw` reads it
  once into a local (`:1384`).
- Phase 6: the generator draws the elements on a sink context (`scale_chart_common.mjs:923-940`),
  and the Dart harness cannot swap the field (`scale_chart_harness.dart:313-328`). Thus the draw
  calls have no element draws.

Options:

| Option | Form | Fidelity | Cost |
|---|---|---|---|
| A. Upstream form (chosen) | `ctx` is a writable field, as the JS property. The harness writes `controller.ctx = recording` for each controller with `controller.ctx == chart.ctx`. The generator records on the chart context, with no sink. | Records the real draw of the real controller: the order, the skip of hidden elements and of `null` bars (`controller.bar.js:676`), the active elements on top | P3: no measured cost (below) |
| B. Phase 6 form | `final` field, sink in the generator | No element draws: misses the draw order and the skips | none |
| C. Record at construction | `acquireChart` gives the chart a recording context from the start | `DomPlatform.acquireContext` calls `canvas.getContext('2d')`. The recorder must then be the context of a fake canvas. This changes the harness port (chartjs-test-utils `src/utils.js:36-105`) and records the layout too | harness divergence |
| D. Rebuild the controllers | Write `chart.ctx`, drop the controllers, `chart.update()` | New controllers parse again: not the state under test | none |

Evidence for the cost of A (P3, `<probes>/ctxbench/bench.dart`, 1000 elements, 2 contexts and 2
element classes so that no call site is monomorphic, median of 10 rounds after 2 warm-up rounds,
ns for 2 x 1000 draws):

| Form | AOT run 1 | AOT run 2 | dart2wasm (Node.js 24, V8) run 1 | run 2 |
|---|---|---|---|---|
| final field, read once (the port form) | 3430 | 3741 | 18014 | 17991 |
| writable field, read once | 3403 | 3494 | 18135 | 18280 |
| final field, read for each element | 3483 | 3444 | 18617 | 18500 |
| writable field, read for each element | 4199 | 4235 | 17614 | 17686 |

- With the read hoisted (the port form of `draw`, `core.datasetController.dart:1384`), the two forms
  are equal within the noise on AOT and on wasm.
- A read for each element costs about 0.36 ns more for each element on AOT (the bar form,
  `controller.bar.js:677`). For 1000 bars this is 0.36 us for each frame: below the 0.1 ms
  resolution of the frame figures (porting-flow.md §1.1). The bar port can hoist the read into a
  local: same behavior, same structure.

Choice: A. It is the upstream structure (a writable property), it records the protected draw order,
and it has no measured cost. It needs no `differences.md` row: it removes a difference of form.

Dart form (lib):

```dart
/// core.datasetController.js:257 `_ctx`, the context of the chart.
/// controller.bar.js:677 reads it. Dart `null` stands for the JS `null` of
/// a chart without a context. It is writable, as the JS property: the
/// reference tests put a recording context here.
@internal
CanvasRenderingContext2D? ctx;
```

Dart form (harness):

```dart
/// The calls of one `chart.draw()` with the element draws.
List<ContextCall> drawCallsWithElements(Chart chart) {
  final target = chart.ctx!;
  final recording = ControllerRecordingContext(target);
  final scales = chart.scales.values.toList();
  final scaleContexts = [for (final s in scales) s.ctx];
  final controllers = <DatasetController>[
    for (var i = 0; i < _datasetCount(chart); i++)
      if (chart.getDatasetMeta(i.toDouble()).controller
          case final DatasetController c when identical(c.ctx, target))
        c,
  ];
  chart.ctx = recording;
  for (final s in scales) {
    s.ctx = recording;
  }
  for (final c in controllers) {
    c.ctx = recording;
  }
  try {
    chart.draw();
  } finally {
    chart.ctx = target;
    for (var i = 0; i < scales.length; i++) {
      scales[i].ctx = scaleContexts[i];
    }
    for (final c in controllers) {
      c.ctx = target;
    }
  }
  return recording.getCalls();
}
```

The generator side is `drawCalls` without the sink: `ctx.resetCalls(); chart.draw();
ctx.getCalls()` (P1 does this).

### 1.3 `Path2D` in the generator (T2)

- `element.line.js:233` reads `typeof Path2D === 'function'` when the module loads. With
  `Path2D`, a line without `segment` strokes a cached `Path2D` (`:236`).
- The port has `const bool _usePath2D = true` (`element.line.dart:590`): the canvas interface always
  has a `Path2D`, as a browser.
- Node.js has no `Path2D`. P1b (`<probes>/path2d_probe.mjs`) draws one line dataset of 3 points
  on the pinned dist:
  - without a global `Path2D`: 38 calls, the path as `beginPath`, `moveTo`, `lineTo` x 3,
    `stroke`;
  - with a recording `Path2D`: 33 calls, the path as `stroke(Path2D)` with 4 commands.

Thus a generator without `Path2D` gives other draw calls than Karma and than the port. Choice:
`controller_chart_common.mjs` defines the recording `Path2D` of `line_reference.mjs:96-105`
before `loadChartJs()` imports the dist (the precedent of Chart.js ADR 0017 §11). `dartCalls`
writes a `Path2D` argument as `{path: <id>, calls: [...]}`, the form of
`test/port/elements/element.line_test.dart:152-189`. The Dart harness maps a `Path2D` argument in
the same way: the helpers `_PathIds`, `_actual` and `_replay` of `element.line_test.dart` move to a
shared helper library, and both tests import it.

### 1.4 The hit elements

Options:

| Option | Form | Fidelity |
|---|---|---|
| A. Spec form | `triggerMouseEvent` and the active elements after the hover | Real event path, but one mode (the hover mode) for each event, and frames for each query |
| B. Interaction module only | Fake metas, as `interaction_reference.mjs` | Phase 5 has it. No real controller writes the elements |
| C. `getElementsAtEventForMode` on the real chart (chosen) | A chart event `{type: 'mousemove', native: null, x, y, chart}`; `getRelativePosition` returns it as it is (`helpers.dom.ts:109-111`; Dart: a `types.ChartEvent`, `helpers.dom.dart:105-127`) | All modes on the real elements, no frames |

Choice: C for the full matrix, plus the step `hover` (section 1.6) for the real event path with
the default hover options.

- Modes: `index`, `dataset`, `point`, `nearest`, `x`, `y`. `intersect`: `true` and `false`. Axis:
  `x`, `y` and `xy`; `r` for the radial types. `useFinalPosition`: `false`.
- `includeInvisible: true` in the cases with a hidden dataset or a hidden index.
- Query points: the center of each element (`Math.round` of `getCenterPoint()`), the midpoint of
  each two neighbor centers, the four corners of the chart area (1 px inside), and one point
  outside the chart area. Integer points give the same `x` and `y` on both sides.
- The result is the item list `[datasetIndex, index]` in order. The comparison is exact: the order
  is protected.

P1: 48 to 132 queries for each case with one axis. With 3 axes, about 150 to 400 queries for each
case.

### 1.5 Generators and files (T3)

Options:

| Option | Generators | Dart tests | Fidelity |
|---|---|---|---|
| A. One generator for all | `controller_reference.mjs` | one test file | The name `controller_reference.mjs` already exists (core.controller). One output of 6 to 8 MB. A fix in one controller writes all data again |
| B. One generator for each controller (chosen) | `controller_<name>_reference.mjs` x 8 on `controller_chart_common.mjs` | `test/port/controllers/controller.<name>_test.dart` x 8 | Mirrors the upstream file split (rule 2) and the phase 6 form (one generator for each scale). A rerun writes one file |
| C. Fold pie into doughnut, scatter into line | 6 generators | 6 files | Loses the one-to-one map of the upstream files |

Choice: B. The cost of B over C is two short generators.

Files:

- `tool/reference/controller_chart_common.mjs`: imports `scale_chart_common.mjs`. It adds the
  `Path2D` recorder, `registerPhase7(C)` (`C.Chart.register(C.controllers, C.scales,
  C.elements)`: the order of `index.umd.ts:28` without the plugins, as `flutter_test_config.dart`
  registers them in phase 7), `observeController`, `hits`, `runSteps`, `drawCallsWithElements`
  and `runControllerCase`.
- `scale_chart_common.mjs` exports `dartCalls`, `jsonValue` and the `measured` widths, and takes a
  hook for the `Path2D` arguments. The phase 6 outputs must not change: a rerun of the 8 phase 6
  generators after the change gives byte-identical files (a pin, section 6).
- `tool/reference/controller_{bar,line,scatter,bubble,doughnut,pie,polar_area,radar}_reference.mjs`.
  Each writes `test/port/controllers/controller_<name>_reference.dart` through `writeReference`
  (unchanged). The generators stop unless Node.js is x64 and the dist is at the pin
  (`loadChartJs`, `scale_chart_common.mjs:218-253`).
- `test/port/controllers/controller_chart_harness.dart`: the Dart side of the common file. It
  imports `scale_chart_harness.dart` for `observeChart`, `referenceMatcher`, `copyReference`,
  `expectCalls`, `testReferenceOrigin` and `testReferenceWidths`.
- `test/port/controllers/controller.<name>_test.dart` x 8 (`@TestOn('vm')`): the mapped path of
  `lib/src/controllers/controller.<name>.dart` (AGENTS.md Layout, `test/port/`).

P1 shows the determinism: two runs of `<probes>/controller_probe.mjs` give the same 221501 bytes
(sha256 `0350f523dcdc9e30fe624924be7240834e3c32939ae50e4af57becfb4ebcd0fe`).

### 1.6 Steps

A case can run steps after `acquireChart`. Both sides run the same fixed list. Each step records
the observations again. The draw calls come after the last step only.

| Step | JavaScript | Dart |
|---|---|---|
| `['update']`, `['update', mode]` | `chart.update(mode)` | `chart.update(mode)` |
| `['setDatasetVisibility', d, v]` | then `chart.update()` | same |
| `['toggleDataVisibility', i]` | then `chart.update()` | same |
| `['push', d, ...values]` | `data.push(...)`, `chart.update()` | `add`, `notifyArrayListeners(list, 'push', args)` (row `platform-array-events`), `chart.update()` |
| `['splice', d, start, count, ...items]` | `data.splice(...)`, `chart.update()` | same with `jsSplice` and `notifyArrayListeners` |
| `['reset']` | `chart.reset()` | `chart.reset()` |
| `['hover', x, y]`, `['mouseout']` | `chart._eventHandler({type, chart, native: {type}, x, y})` | `await triggerMouseEvent(chart, type, point)` |

The hover step uses the real event path of the port. The upstream DOM path gives the same chart
event for an integer point (`fromNativeEvent`, `platform.dom.js:108-118`, and `getRelativePosition` with `Math.round`).

### 1.7 Case sets

Each set covers the option branches of the pinned source. The figures are the planned counts.

| Controller | Cases | Branches (pinned source) |
|---|---|---|
| bar | 22 | vertical and `indexAxis: 'y'`; `stacked: true` and `'single'`; stack groups with negative values; floating bars `[a, b]` (`:117-171`), also stacked; hidden dataset and the step `setDatasetVisibility`; `barThickness` number and `'flex'`, `maxBarThickness`; `grouped: false` (`:437`); `skipNull` with `null` items (`:443`); `minBarLength` with 0 and negative values; `base`; `borderSkipped` `'start'`, `'end'`, `'middle'`, an edge, `true`, `false` (`:203-231`); `inflateAmount` `'auto'` and a number (`:252-255`); `borderRadius` (rounded rect calls); a linear index scale (`getAllScaleValues`, `computeMinSampleSize`, `:7-36`); a logarithmic value scale; reversed scales; `clip: false`; object data with `parsing` keys; `parsing: false`; string values; `null` and `NaN`; the steps `push` and `splice` |
| line | 16 | default; `showLine: false`; `spanGaps` `true` and a number (`:82-83`); `stepped` `'before'`, `'after'`, `'middle'`; `tension` with `cubicInterpolationMode: 'monotone'`; `segment` with named functions (`:66`, `:105`); stacked lines; `indexAxis: 'y'`; a linear x scale with `min` and `max` (`_drawStart`, `_drawCount`, `:46-48`); `pointRadius: 0`; hidden dataset; `parsing: false`; `null` items; the step `push` |
| scatter | 6 | default (`showLine: false`: no dataset element, `:71-93`); `showLine: true`; a visible x range (`:61-63`); object data; `getLabelAndValue` with labels |
| bubble | 7 | `r` from the data; the scriptable `radius` (a named function); `hoverRadius` and the step `hover` (`:157-165`); custom parsing keys; `[x, y, r]` arrays (`:62`); `getMaxOverflow`; `clip` |
| doughnut | 14 | default; `cutout` `'50%'` and a number; partial `rotation` and `circumference` (`:10-34`); two datasets with `weight`; the step `toggleDataVisibility`; `spacing` with the default `spacingMode` (`:72-75`, #12238) and `'proportional'`; `offset` and `hoverOffset` with the step `hover`; `borderAlign: 'inner'`; the step `reset` with `animateRotate` and `animateScale` (`:48-51`); `parsing: false`; labels that are arrays |
| pie | 4 | default (`cutout: 0`); the step `toggleDataVisibility`; two datasets; the step `hover` |
| polarArea | 9 | default; `startAngle`; the step `toggleDataVisibility` (`:130`, `:182`); `spacing` with the default `spacingMode: 'proportional'` (`:25-26`) and a chart-level override (`:204-210`); scale `r` `min` and `max`; the step `reset` (`:162-190`); point labels |
| radar | 8 | default; `spanGaps`; `tension`; hidden dataset; `null` items; `showLine: false` (`:64`); scale `r` options; the step `hover` |

A case that needs a time scale (a bar chart on a time axis) uses `scale_time_common.mjs` and the
`atNow` helper of `scale_time_harness.dart`, as the phase 6 time tests do.

### 1.8 Dart test form

```dart
// Original code, not ported from Chart.js: bar controller reference tests.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import 'controller_bar_reference.dart';
import 'controller_chart_harness.dart';

void main() {
  // The built-in components come from flutter_test_config.dart
  // (harness-register-builtins). No test controller is necessary.
  testReferenceOrigin(
    node: controllerBarReferenceNode,
    arch: controllerBarReferenceArch,
    dist: controllerBarReferenceDist,
    commit: controllerBarReferenceCommit,
  );
  testReferenceWidths(controllerBarReferenceWidths);
  testControllerChartCases(controllerBarReference, functions: {
    'base': (Object? ctx) => 2.0,
  });
}
```

```dart
/// A `testWidgets` case for each of [cases]: the chart of `acquireChart`,
/// the observations of `initial`, each step with its observations, then the
/// draw calls with the element draws.
void testControllerChartCases(
  List<ScaleChartCase> cases, {
  Map<String, Object?> functions = const {},
}) {
  for (final c in cases) {
    testWidgets(c.name, (tester) async {
      final chart = acquireChart(
        copyReference(c.config, functions)! as AnyObject,
        copyReference(c.options)! as AnyObject,
      );
      expectControllerObservations(chart, c.expected['initial'], 'initial');
      final steps = c.expected['steps']! as List<Object?>;
      for (var k = 0; k < steps.length; k++) {
        final step = steps[k]! as Map<String, Object?>;
        await runStep(tester, chart, step['do']! as List<Object?>);
        expectControllerObservations(chart, step['observations'], 'step $k');
      }
      expectCalls(
        drawCallsWithElements(chart),
        c.expected['drawCalls'],
        reason: 'draw',
      );
    });
  }
}
```

- `expectControllerObservations` reads exactly the keys of the expected Map. An expected key that
  no check reads fails (the rule of `expectScaleChart`, `scale_chart_harness.dart:521-526`).
- Options compare through `jsObjectKeys` and `jsGet`, never by `equals` on a resolver (lesson of
  phase 6). The key order of the options compares with `orderedEquals`.
- Numbers use `referenceMatcher` (`scale_chart_harness.dart:443-469`): 1e-9 absolute, or 1e-12
  relative above 1e3. Hit items and draw-call names compare exactly.

### 1.9 Cost

- Node.js: P1 runs 7 cases in 123 to 126 ms under Rosetta.
- Dart VM: the phase 6 reference tests of `scale.linear` and `scale.category` (173 tests, 137
  chart cases with draw calls) take 3418 ms in all, median 15 ms for each test (P4, JSON
  reporter). 86 controller cases thus add about 2 to 4 s to `test --no-select`.
- Data: P1 gives about 32 KB of JSON for each case with one axis. With 3 axes and the steps, the 8
  files hold about 4 to 6 MB. Phase 6 holds 8.1 MB in 8 files.

## 2. Theme tests of the phase 7 row

The phase 7 row of `theming.md` §10 asks for: test 3 for elements and scales on the 8 chart types
(the colors plugin off), test 5 on a doughnut and a bar chart, the hover tests, and the blue
screen without plugins. Phase 7 registers no plugin. Thus "the colors plugin off" is the state of
the registry.

### 2.1 Test 3: the light preset equals upstream on 8 chart types (T5)

Options:

| Option | Source of the expected values | Fidelity |
|---|---|---|
| A. Extend `theme_light_reference.mjs` | the pinned sources with type stripping, no chart (`theme_light_reference.mjs:13-40`) | No controller, no element of a real chart. It resolves the scopes by hand |
| B. Reuse the controller reference data | `controller_<name>_reference.dart` | The data has no scale option keys. The cases are not the canonical charts of test 3 |
| C. New generator on the dist (chosen) | `theme_charts_reference.mjs` on `controller_chart_common.mjs` | Real charts of the 8 types on the pinned build: the same path as the reference tests |

Choice: C.

- Cases: one canonical chart for each of `bar`, `line`, `scatter`, `bubble`, `doughnut`, `pie`,
  `polarArea`, `radar`. The cartesian charts have two datasets and the scale titles on. The radial
  charts have point labels.
- Recorded, for each chart: the element options of each element in the modes `default` and
  `active`, the dataset element options, and, for each scale, the values of each scale key that
  the light preset emits. The generator reads the key list from
  `test/port/theme/light_snapshot.json` (the emitted paths under `scale` and `scales.<type>`), so
  that no second list exists.
- Dart: `test/port/theme/presets_charts_test.dart` (`@TestOn('vm')`). Each case runs twice: with
  no theme and with `compileChartTheme(ChartThemes.light)` under `themeConfigKey`. Both runs must
  equal the reference, with the colors parsed (`theming.md` §8 item 3). After each run, the test
  compares `defaults` with its state before the run (`theming.md` §6: a theme does not write
  `defaults`).

### 2.2 Test 5 on a doughnut and a bar chart

- Now: the group `test 5: a theme scale type creates no axis` of `precedence_test.dart:1671-1729`
  uses the test controllers `themeReal` and `themeRadial`.
- Choice: add 4 cases with the real types `bar` and `doughnut`: a bar chart with a themed
  `scales.radialLinear` (axes `x,y` only), a doughnut chart with themed `scales.category` and
  `scales.linear` (no axis), and the light preset on each. `theme_precedence_reference.mjs` registers
  the pinned `src/controllers/controller.bar.js` and `controller.doughnut.js` in both of its modes
  (`upstream` and `prototype`). The test keeps its form: the observations of `_axes`
  (`precedence_test.dart:677-698`) against the prototype, and against upstream for the cases
  without a theme.
- The existing 4 cases with the test controllers stay. They pin the generic path.

### 2.3 Hover tests

`theming.md` §6: the active state resolves with the prefixes `[typeHover, 'hover', type, '']`
(`core.datasetController.js:803-835`), and the hover color is `getHoverColor` over the themed base
color. `_setStyle` puts back the shared options after the hover (`:919-926`).

- Generator: `theme_charts_reference.mjs` runs, for each of the 8 types, the steps `hover` on the
  center of element 0 of dataset 0 and then `mouseout`, in two configurations:
  - no theme;
  - no theme, with the values of a token theme written into `defaults` (`color`, `borderColor`,
    `backgroundColor`), the method of the phase 6 radial group (`theming.md` §10, phase 6 state).
- Dart: the same steps with no theme, and with the token theme under `themeConfigKey`. The second
  run must equal the "values in `defaults`" reference: the options of the hovered element, of a
  second element, and of both after `mouseout`.
- This extends the H0-H3 claim of §3.2 to the real active path of the controllers. It needs no
  palette.

### 2.4 The blue screen without plugins (T6)

`theming.md` §8 item 6: every pixel blue, no golden file. Phase 7 has no title, legend or tooltip.
Thus the test covers the elements and the scales of the 8 chart types.

Options to read the pixels in `flutter_test`:

| Option | Form | Fidelity | Cost |
|---|---|---|---|
| A. Golden file | `matchesGoldenFile` | Excluded by §8 item 6 | — |
| B. Host layer | `RenderChartHost` is a repaint boundary (`chart_host.dart:569`): `OffsetLayer.toImage` | The full host path. The host has no background: transparent pixels need a premultiplied check `r == 0, g == 0, b == a` | needs the harness body |
| C. Canvas bitmap on blue (chosen) | `UiCanvasContext.paint` on a `ui.Canvas` with a blue rectangle, `Picture.toImage`, `Image.toByteData` in `tester.runAsync` (the method of `test/port/canvas/pixel_compare.dart:46-62`) | The bitmap of the chart, "on a blue background" as §8 item 6 says | 6 to 15 ms for each 512 x 512 read (P2) |
| D. Draw-call scan only | each `fillStyle` and `strokeStyle` parses to the blue | No pixel: misses a default color that never reaches a setter, for example a text color through another path | small |

Evidence P2 (`<probes>/blue_blend_probe_test.dart`, `flutter test` on the harness canvas with the
test font):

- An arc, a polyline, a rectangle and bold 13 px text in `rgb(0, 0, 255)` on blue: 0 pixels
  differ, largest channel difference 0.
- The same scene in `rgba(0, 0, 255, 0.5)` on blue: 0 pixels differ.
- The same scene plus one 1 px line of `rgba(0, 0, 0, 0.1)`: 512 pixels differ, largest channel
  difference 26.
- The reason: with premultiplied 8-bit color, blue over blue gives `b = 255a + 255(1 - a) = 255`
  exactly, for any alpha and any rounding. `flutter_tester` renders with
  `--enable-software-rendering --skia-deterministic-rendering`.

Choice: C as the oracle, plus D as the diagnosis, plus a negative control:

- The theme: a test-support raw Map theme that sets each color token to the blue (`(0, 0, 1)`).
  Phase 8 adds the palette.
- The charts: the 8 types with the parts that phase 7 draws: grid, ticks, scale titles, point
  labels, angle lines, lines with points, bars with borders, arcs with borders.
- The check: each pixel is `0x0000FFFF` (RGBA bytes `00 00 FF FF`).
- The negative control: the same chart without the theme has more than 0 pixels that differ. This
  proves that the read sees the chart.
- The diagnosis: on a failure, the test records the draw calls with the element draws
  (`drawCallsWithElements`) and names each style setter whose value does not parse to the blue or to
  alpha 0, with the call index.
- Known leaks: a committed `Map<String, Set<String>>` of chart type to the leaking setter values,
  with the upstream file:line of each value. The test fails when the set changes in either
  direction. The expected content in phase 7 is empty. A leak that the test finds is a theme
  defect, or a row of `differences.md` and an entry of the list.
- The active-element case waits for `IdentityChartHover` (`theming.md` §8 item 6).

```dart
/// The count of pixels of [chart] that are not the opaque blue, with the
/// canvas bitmap drawn on a blue background.
Future<int> _nonBluePixels(WidgetTester tester, Chart chart) async {
  final ctx = chart.ctx! as UiCanvasContext;
  final canvas = chart.canvas! as UiCanvasElement;
  final w = canvas.width;
  final h = canvas.height;
  final recorder = ui.PictureRecorder();
  final background = ui.Canvas(recorder)
    ..drawRect(
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..color = const ui.Color(0xFF0000FF),
    );
  ctx.paint(background, ui.Offset.zero, 1, 1);
  final picture = recorder.endRecording();
  final image = (await tester.runAsync(() => picture.toImage(w, h)))!;
  final bytes = (await tester.runAsync(image.toByteData))!;
  var count = 0;
  for (var i = 0; i < bytes.lengthInBytes; i += 4) {
    if (bytes.getUint32(i) != 0x0000FFFF) count++;
  }
  image.dispose();
  picture.dispose();
  return count;
}
```

## 3. The lift of the skips (T7, T8)

### 3.1 Order

- The classification (`classification/all.json`) gives each record its `modules`. A record with
  the verdict `phase7` lifts in the wave that ports the last module of its `modules`. The waves of
  the kickstart are: bar; line, bubble, doughnut, polarArea, radar; scatter, pie, `index`.
- A chart case of the type `bar` needs the controller in the registry. The `controllers` namespace
  of `lib/src/controllers/index.dart` and the `registerables` entry thus grow with each wave, so
  that `flutter_test_config.dart` registers each ported controller at once
  (`harness-register-builtins`).
- A short script prints the lift list of a wave from `all.json`. The integration agent of the wave
  lifts these cases and no other case.

### 3.2 Form of a lifted case

- A placeholder `test(name, () {}, skip: 'blocked: controller.<x>')` becomes `testWidgets(name,
  (tester) async { ... })` with the body ported from the upstream case at its `line`. The name does
  not change.
- A case that stays blocked by a plugin of phase 8 keeps the placeholder form with the reason
  `'blocked: plugin.<id>'`. `testWidgets` has only a `bool` skip (flutter_test 3.44.9
  `widget_tester.dart:148-158`), and tool 5 needs the reason text.
- A case that the classification marks blocked by a plugin, but whose `blocked: controller.*` skip
  is the current reason, gets the plugin reason in the same change (21 cases, summary §4).

### 3.3 The 57 time twins

- `_lineTwin` (`test/port/scales/scale.time_test.dart:196-201`) wraps each twin as a skipped `test`.
  Its doc comment already names the phase 7 form.
- Options: (a) inline `testWidgets` at the 57 call sites; (b) change the helper body to
  `testWidgets(name, (tester) async => body())` and its doc comment. Fidelity is equal: both run
  the same body in a `testWidgets` test (Chart.js ADR 0022 §2). The decision protocol then chooses
  less code: (b), a change of 1 line and the comment. The name stays: each twin makes a line
  chart.

### 3.4 Pure spec files that get chart cases

These 5 files use `package:test` and `setUpSpecs()` now. Their chart cases lift. The AGENTS.md rule
moves each file to `@TestOn('vm')` and `flutter_test` as a whole.

| File | Pure cases now | Placeholders now |
|---|---|---|
| `core.datasetController_test.dart` | 0 | 35 |
| `core.interaction_test.dart` | 0 | 30 |
| `core.layouts_test.dart` | 1 | 11 |
| `core.ticks_test.dart` | 2 | 2 |
| `element.line_test.dart` | 1 | 1 |

Options:

| Option | Form | Fidelity |
|---|---|---|
| A. Move as a whole (existing rule, chosen) | `@TestOn('vm')`, `flutter_test`, no `setUpSpecs()` | One Dart file for each upstream file. The 4 pure cases run with the built-in components registered, as in Karma |
| B. Split into a pure file and a chart file | a second file `<base>_chart_test.dart` | `check:headers` rejects a second file with the same source; tool 5 maps one Dart file to one upstream file |
| C. Keep the file pure, put the chart cases in `test/port/` | — | The cases leave their spec file: tool 5 reports them missing |

Choice: A. The cost: 4 pure cases lose the dart2js and dart2wasm legs. Their modules keep web
coverage through the pure tests of `test/port/core/` and `test/port/elements/`.

`element.point_test.dart` also moves when its `auto` fixture group arrives (section 4.3): its 4
pure cases then run on the VM only. `test/port/elements/element.point_test.dart` keeps the web
legs of the module.

### 3.5 Rules for a case that fails after the lift

The classification gives each `phase7` case the probe result `pass` in the mode `none` (no plugin)
on the pinned build (summary §6: 498 of 500 by probe, 2 by a static reading with a variant). Thus
a failure after the lift is a defect of the port, not of the classification. The rules:

1. Run the case in the probe: `run_spec.mjs <dist> <spec> --mode none --filter '<it>'`
   (`probe/README.md`). Compare its `values` (each expectation with its actual value) with the Dart
   values. The first value that differs names the defect.
2. Fix the defect in `lib/`. Add a reference case that pins it to the generator of the controller,
   or a port-only test in `test/port/` when no chart shows it.
3. Do not change the config, an assertion, a tolerance or a name of the spec port. A variant goes
   to `test/port/` (kickstart, Scope).
4. Only two other results are valid, each with its evidence in the same change:
   - `'diverges: <row id>'`: a `differences.md` row whose reason is a difference that Chart.js ADR
     0009 does not protect, or a platform limit, with the probe output that shows the difference.
   - `'blocked: plugin.<id>'`: only when `run_spec.mjs --mode without:<id>` fails where `all`
     passes. The change updates the record in `all.json` (verdict, `evidence`, `probe`).
5. Never `'n/a: <reason>'` for a `phase7` verdict. Never a new `'blocked: controller.*'` reason.
6. The integration step of each wave runs `test:cases`. The wave ends with 0 failed cases.

### 3.6 A pin for stale skips

Tool 5 now accepts any `'blocked: <module>'` text. After phase 7 a `'blocked: controller.*'` skip
must not stay. Choice: tool 5 reports an error for a skip `'blocked: <module>'` whose module has
the status `ported` in `doc/status.yaml` ("stale block"). For the time twins in `test/port/`
(tool 5 reads only `test/specs/`), the same check scans the skip literals of `test/port/` source
files.

## 4. Spec port conventions of the 7 controller spec files (T9)

### 4.1 File

- Path: `test/specs/controller.<name>_test.dart` (Chart.js ADR 0012, porting-flow.md §1 step 5).
- Line 1: `// Ported from Chart.js v4.5.1+7169e651 test/specs/controller.<name>.tests.js (MIT,
  Chart.js Contributors).`, then `@TestOn('vm')` and `library;`.
- Imports: `package:flutter_test/flutter_test.dart`, `package:chartjs_test_utils/flutter.dart`,
  `package:chartjs_test_utils/pure.dart`, the support library of section 4.6, and the `lib/src`
  files that the cases read. No `setUpSpecs()`: the charts need the built-in components
  (AGENTS.md Tests).

### 4.2 Names

- `group()` and `testWidgets()` names equal the `describe` and `it` names, character for
  character.
- A name part that upstream joins with `+` uses `jsToString` (or `jsAdd`) of the JS value, never
  Dart interpolation of a `double`: `'When barThickness is ' + barThickness` with `[undefined,
  20]` (`controller.bar.tests.js:1463-1464`) gives `'When barThickness is undefined'` and
  `'When barThickness is 20'`. Dart `'$v'` of `20.0` gives `'20.0'`, and tool 5 then reports an
  unknown name.
- A `forEach` that makes `describe` or `it` blocks becomes a Dart `for` loop over the same list in
  the same order.
- A duplicated full name gets ` #2` and ` #3` (porting-flow.md §1 step 5).

### 4.3 The `auto` fixture group

- Each of the 7 files starts with `describe('auto', jasmine.fixture.specs('controller.<name>'))`
  (line 2).
- Upstream form (chosen): the group stays at its upstream position, `group('auto', () =>
  specsFromFixtures('controller.<name>'))`, with the runner of tool 7. Tool 5 already accepts a
  fixture test in a fixture group of the manifest when its name is the fixture path
  (`tool/src/spec_cases.dart:24-30`, `:144-150`). Tool 5 maps one Dart spec file to one upstream
  spec file. Thus the fixture tests must be in the spec file to match.
- The runner tags each fixture test with `fixtures` (`testWidgets` has `tags`; flutter_test
  `group` has no `tags`, `test_compat.dart:208`). The melos `test` script excludes the tag
  (porting-flow.md §3, "Fixture selection").
- The earlier spec files with the comment "a fixture group of phase 7, not a case" get the same
  call at the same position.
- The details of the runner belong to the fixture runner panel. If that panel puts the fixtures in
  their own files, the spec files keep the comment, and tool 5 needs a map from those files to the
  spec files.

### 4.4 `beforeEach`, `afterEach` and Jasmine `this`

- A `beforeEach` that acquires a chart is a local function. Each test calls it first (Chart.js ADR
  0022 §2). Examples: `controller.bubble.tests.js:255`, `controller.doughnut.tests.js:334`,
  `controller.line.tests.js:757`, `controller.polarArea.tests.js:305`,
  `controller.radar.tests.js:256`, `controller.bar.tests.js:1465`.
- An `afterEach` that acquires a chart is a local function. Each test calls it last
  (`controller.bar.tests.js:1325`, `:1399`).
- Jasmine `this` (shared by `beforeEach`, `it` and `afterEach`: `this.data`, `this.config`,
  `this.chart`) is a local record that the test makes first and gives to each local function:

```dart
/// The Jasmine `this` of the group 'Bar width'.
final class _BarWidthThis {
  Map<String, Object?>? data;
  Map<String, Object?>? config;
}

void _barWidthBeforeEach(_BarWidthThis self) {
  // 2 datasets
  self.data = <String, Object?>{ /* ... */ };
}

void _barWidthAfterEach(_BarWidthThis self) {
  final chart = acquireChart(self.config);
  // ... the assertions of controller.bar.tests.js:1325-1384
}

testWidgets('should correctly set bar width when min and max option is set.', (
  tester,
) async {
  final self = _BarWidthThis();
  _barWidthBeforeEach(self);
  self.config = <String, Object?>{
    'type': 'bar',
    'data': self.data,
    'options': <String, Object?>{ /* scales.x min 'March', max 'May' */ },
  };
  _barWidthAfterEach(self);
});
```

- A `beforeEach` or `afterEach` that saves or writes `Chart.defaults` and reads no chart stays
  `setUp` and `tearDown` (`controller.line.tests.js:555-563`). The harness restore runs after it.

### 4.5 Spies

The upstream form `spyOn(object, 'method')` replaces the method on the instance, without
call-through. A Dart object cannot replace one of its methods. The AGENTS.md rule stores a
recording function value in place of a spied property. A method has no property slot. The existing
precedent for a method is a substitute object in the slot that holds the object:
`helpers.canvas_test.dart:37-79` puts a `_ClearRectSpy` in place of `chart.ctx`.

The spies of the 7 files:

| Upstream | Count | Port |
|---|---|---|
| `spyOn(meta.data[i], 'draw')` | bar `:1181-1184`, bubble `:79-82`, doughnut `:275-278`, line `:127-130`, polarArea `:121-124`, radar `:63-66`, `:91-93` | a substitute element in `meta.data[i]` |
| `spyOn(meta.dataset, 'draw')`, `spyOn(meta.dataset, 'updateControlPoints')` | line `:125-126`, radar `:62`, `:90` | a substitute line in `meta.dataset` |
| `spyOn(controller, '_onData*')` | `core.datasetController.tests.js:25` | a substitute listener in the listener slot of the data array |

Options for the element spies:

| Option | Form | Fidelity | Cost |
|---|---|---|---|
| A. Substitute in the slot (chosen) | a test subclass of the element class with the spied method as a recording stub; it takes the place of the element in `meta.data[i]` | The controller calls the method of the object in the slot, as upstream calls the own property. No call-through, as Jasmine | test code only |
| B. Hook in `lib/` | a port-only static draw hook in `Element` | Test code in the library; a branch in the draw loop of each element | a hot-loop branch |
| C. Count from the draw calls | the recorded calls of each element | Indirect; the real draw runs, unlike the spy | test code only |
| D. Register a spy element class | unregister `bar`, register a subclass | Changes the class of every element of the chart; `TypedRegistry.register` returns early for a known id | test code only |

Evidence P5 (`<probes>/spy_probe_test.dart`, a real chart of the phase 6 test controller):
3 substitute points in `meta.data`; `chart.update()` calls the draw of each once (counts 1, 1, 1);
a second `chart.update()` keeps each substitute in its slot and counts 2, 2, 2. The controller
writes the properties of the substitute in each update, so the substitute needs only `active` and
`options` of the original before the first update.

Choice: A.

```dart
/// `spyOn(element, 'draw')` for a bar: a bar that records each draw and
/// draws nothing (a Jasmine spy without callThrough).
final class _DrawSpyBar extends BarElement {
  _DrawSpyBar(BarElement of) {
    active = of.active;
    options = of.options;
  }

  /// `element.draw.calls`.
  final JasmineCalls calls = JasmineCalls();

  @override
  void draw(CanvasRenderingContext2D ctx, [types.ChartArea? area]) =>
      calls.add([ctx, area]);
}

/// `spyOn(meta.data[index], 'draw')`: the spy takes the slot.
JasmineCalls _spyOnDraw(types.ChartMeta meta, int index) {
  final spy = _DrawSpyBar(meta.data[index] as BarElement);
  meta.data[index] = spy;
  return spy.calls;
}
```

A spy with `.and.callThrough()` calls `super` in the stub. The listener spy of
`core.datasetController.tests.js:25` replaces the controller in the listeners of the data array
(`unlistenArrayEvents(data, controller)`, `listenArrayEvents(data, spy)`) and puts the controller
back in `addTearDown`.

### 4.6 Jasmine support library

- Today each spec file has private copies: `_toEqual` and `_objectContaining`
  (`core.controller_test.dart:62-135`), `_spyOn` and `_Spy` (`core.plugin_test.dart:32-110`),
  `_Calls` (`helpers.canvas_test.dart`). The controller specs use `jasmine.objectContaining` at 13
  sites, most of them in loops over the elements with `withContext(i)`, and the spies above.
- Choice: one port-only library `test/support/jasmine.dart` with `jasmineEquals` (the port of
  `MatchersUtil.eq_` of jasmine-core 3.99.1, the version of the Chart.js lockfile),
  `objectContaining`, `anyFunction`, `JasmineCalls`, `JasmineSpy` and `withContext` as a `reason`.
  One copy of the Jasmine semantics gives one behavior in all files. The private copies move into
  it in the same change.
- The library imports only pure layers and `package:matcher`. Thus a pure spec file can import it
  too. `check:lib-imports` then needs the path in its test allowlist.

### 4.7 Events and `withContext`

- `await jasmine.triggerMouseEvent(chart, type, point)` is `await triggerMouseEvent(chart, type,
  point)` (Chart.js ADR 0022 §6). `point` is a `types.Point` of the element, as upstream passes
  the element.
- `expect(x).withContext(i).toEqual(y)` is `expect(x, jasmineEquals(y), reason: jsToString(i))`.

### 4.8 Blocked cases

The 12 cases that need `plugin.tooltip` or `plugin.filler` (summary §4) are placeholders `test(name,
() {}, skip: 'blocked: plugin.<id>')`, as in the earlier phases. Their bodies come with phase 8.

## 5. Files that the implementation changes

Library:
- `lib/src/core/core.datasetController.dart`: `ctx` writable (T1).

Tools:
- `tool/reference/scale_chart_common.mjs`: export `dartCalls`, `jsonValue` and the widths; a hook
  for `Path2D` arguments. Phase 6 outputs stay byte-identical.
- `tool/reference/controller_chart_common.mjs` (new).
- `tool/reference/controller_{bar,line,scatter,bubble,doughnut,pie,polar_area,radar}_reference.mjs`
  (new, 8).
- `tool/reference/theme_charts_reference.mjs` (new).
- `tool/reference/theme_precedence_reference.mjs`: the real bar and doughnut controllers, 4 cases.
- `tool/src/spec_cases.dart` and `tool/spec_cases.dart`: the stale-block error.
- `tool/src/lib_imports.dart`: the test allowlist entry of `test/support/jasmine.dart`.

Tests:
- `test/port/controllers/controller_chart_harness.dart` (new), `controller.<name>_test.dart`
  (new, 8), `controller_<name>_reference.dart` (generated, 8).
- A shared `Path2D` record helper (moved from `test/port/elements/element.line_test.dart`).
- `test/port/scales/scale_chart_harness.dart`: the doc comment on the element draws.
- `test/port/theme/presets_charts_test.dart` (new), `charts_reference.dart` (generated),
  `blue_screen_test.dart` (new), `precedence_test.dart` and `precedence_reference.dart`
  (regenerated).
- `test/specs/controller.{bar,bubble,doughnut,line,polarArea,radar,scatter}_test.dart` (new, 7).
- The spec files with lifted cases: `core.animator`, `core.controller`, `core.datasetController`,
  `core.interaction`, `core.layouts`, `core.scale`, `core.ticks`, `element.line`, `helpers.dom`,
  `platform.dom`, `scale.category`, `scale.linear`, `scale.logarithmic`, `scale.radialLinear`,
  `scale.time` (`_test.dart`); also `element.point_test.dart` for its `auto` group.
- `test/port/scales/scale.time_test.dart`: `_lineTwin`.
- `test/support/jasmine.dart` (new); `core.controller_test.dart`, `core.plugin_test.dart`,
  `helpers.canvas_test.dart`: the private copies move.
- `test/tool/spec_cases_test.dart`: the stale-block cases.

Docs:
- Chart.js ADR 0030 (new, proposed).
- `porting-flow.md` §3 (element draws in the reference tests; the pure files that moved) and §4
  (tool 5 stale block). `theming.md` §10 (phase 7 state). AGENTS.md Tests (the controller reference
  tests, `Path2D` in the generators, the spy form, the support library). `doc/status.yaml` (the
  port-only rows of the new port-only files). No `differences.md` row: T1 removes a difference of
  form.

## 6. Tests that pin the decision

- `controller_chart_harness_test.dart`:
  - `drawCallsWithElements` records the element draws: a bar chart of 3 visible bars and 1 `null`
    bar records the rectangle calls of 3 bars (`controller.bar.js:676-677`).
  - With the element draws on top: an active element draws last with
    `drawActiveElementsOnTop` (`core.datasetController.js:733-741`).
  - After the call, `chart.ctx`, each `scale.ctx` and each `controller.ctx` are the old contexts.
  - A `Path2D` argument records as `{path, calls}`.
- `test/port/core/core.datasetController_test.dart`: a write of `ctx` makes `draw` draw on the new
  context (`core.datasetController.js:713`).
- Each `controller.<name>_test.dart`: `testReferenceOrigin` (x64, Node.js v24.12.0, the pin) and the
  cases.
- A rerun of each generator gives byte-identical output; a rerun of the 8 phase 6 generators after
  the change of `scale_chart_common.mjs` gives byte-identical output.
- `presets_charts_test.dart`: test 3 on 8 types, with no theme and with the light preset;
  `defaults` unchanged.
- `precedence_test.dart`: the 4 new test 5 cases.
- The hover group: the hovered element, a second element, and both after `mouseout`.
- `blue_screen_test.dart`: 8 types, 0 non-blue pixels; the negative control; the known-leaks list.
- `test/tool/spec_cases_test.dart`: a `'blocked: <module>'` skip of a `ported` module fails.
- `test:cases`: 0 missing and 0 failed cases in the ported spec files; the count of
  `'blocked: controller.'` skips is 0.

## 7. Probes

All paths are under `<probes>` =
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/test-strategy-fidelity/`.

| Id | Script | Command | Result |
|---|---|---|---|
| P1 | `controller_probe.mjs` | `/usr/bin/arch -x86_64 <env>/node-v24.12.0-darwin-x64/bin/node controller_probe.mjs <env>/chartjs-build/dist/chart.js run1.json` (twice) | 7 chart types: element properties, options (default and active), parsed items with `_custom` and `_stacks`, stacks (`x.y.s`, `x.y.bar`), 48 to 132 hit queries, 85 to 689 draw calls with the element draws. Two runs: the same 221501 bytes, sha256 `0350f523…cd0fe`; 123 to 126 ms |
| P1b | `path2d_probe.mjs` | as P1, with `off` and `on` | without `Path2D`: 38 calls (`beginPath`, `moveTo`, `lineTo`); with it: 33 calls (`stroke(Path2D)` with 4 commands) |
| P2 | `blue_blend_probe_test.dart` | `flutter test <probes>/blue_blend_probe_test.dart` from `packages/flutter_chartjs` | opaque blue: 0 pixels differ; alpha 0.5 blue: 0; one 10 % black line: 512 pixels, largest difference 26; 6.4 to 15.3 ms for each read of 512 x 512 |
| P3 | `ctxbench/bench.dart`, `ctxbench/run_wasm.mjs` | `dart compile exe`; `dart compile wasm` and `node run_wasm.mjs` (Node.js v24.12.0 arm64) | section 1.2 table |
| P4 | — | `flutter test --reporter json test/port/scales/scale.linear_test.dart test/port/scales/scale.category_test.dart` | 173 tests, 3418 ms, median 15 ms |
| P5 | `spy_probe_test.dart` | `flutter test <probes>/spy_probe_test.dart` | draw counts 1, 1, 1 after one update; 2, 2, 2 and the same slots after two |

`<env>` is `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/env`
(`doc/phase7/env-setup.sh` makes it). The Dart probes outside `test/` get no
`flutter_test_config.dart`: P5 registers its scales and its element itself.

## 8. Points for the judge

- T1 changes one shared layer by one keyword. It is the upstream form and has no measured cost. A
  draft that keeps the field final loses the draw order of the elements, a protected item.
- T2 is not optional for any draft that records the line draw calls: without it, the generator
  differs from both the browser and the port.
- T8 costs 4 pure cases on the web. A split file is not possible with tools 1 to 5 as they are.
- Section 4.3 depends on the fixture runner panel. This draft prefers the upstream position because
  tool 5 already supports it.
