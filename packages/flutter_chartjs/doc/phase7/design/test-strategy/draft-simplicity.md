# Controller test strategy: draft "simplicity first"

Design panel "Controller test strategy" of phase 7 (future Chart.js ADR 0030). This draft uses the
lens SIMPLICITY FIRST: the form with the least code of our own and the fewest new concepts that
still keeps the behavior of Chart.js ADR 0009 (the ticks, the hit element, the item order, the
resolved option, a throw).

Scope: the tests of phase 7 other than the bodies of the spec ports and the fixture runner. The
fixture runner is Chart.js ADR 0029. The parsed read is Chart.js ADR 0027.

Probe folder (below: `<probe>`):
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/test-strategy-simplicity/`.
The probes ran on Flutter 3.44.9 (macOS, Apple silicon), on the tree of `0e0ab93`, and with the
reference environment of `phase7/env-setup.sh` (x64 Node.js v24.12.0 under Rosetta, Chart.js
built at `7169e651`).

## 0. Summary of the choices

| # | Choice | Main reason |
|---|---|---|
| 1a | `DatasetController.ctx` becomes a writable field, as the upstream property `_ctx`. `drawCalls` of both sides records the element draws. | The upstream `_ctx` is a plain property. One line in `lib/`. The JS side loses its sink code. No measured frame cost. |
| 1b | The 8 phase 6 reference files are generated again with the element draws, in the same change. | One `drawCalls` for all reference tests, no flag. The data grows by 7.3 %. |
| 1c | One generic observation for all 8 controllers: `observeControllers` in a new `tool/reference/controller_chart_common.mjs`, and `expectControllerChart` in a new `test/port/controllers/controller_chart_harness.dart`. | The prototype runs all 8 chart types with one function. |
| 1d | One generator and one test file for each controller, with only a case list of its own. 77 cases in all. No time scale cases. | The phase 6 pattern. The 57 time twins already run the line controller on a time scale. |
| 2a | Test 3 = the same reference cases again, with `ChartThemes.light`, against the same upstream data, with the colors parsed. | No new generator and no new data. The probe gives 0 differences after the parse. |
| 2b | Hover tests = a themed chart against an unthemed twin with the replaced values in `defaults`, after `triggerMouseEvent`. | A differential test needs no table of keys for each type. |
| 2c | Test 5 = two `testWidgets` cases in `precedence_test.dart`. | The rest of test 5 exists. |
| 2d | Blue screen = the bitmap of `UiCanvasElement.toImageSource()`, read as premultiplied RGBA. A pixel passes when `r == 0`, `g == 0` and `b == a`. | No golden. The probe finds 0 leaks themed and flags every drawn pixel unthemed. |
| 3 | Lift a skip in the wave that ports the last controller of its `modules`. `_lineTwin` changes in one line. The 5 pure files move to `@TestOn('vm')` as a whole. A failure after the lift is a defect to fix. | The existing rules of AGENTS.md. No new tool. |
| 4 | Exact upstream names. `group('auto', ...)` at the place of the upstream line. Local `beforeEach`/`afterEach` functions. A spy of a Dart method is a private stub subclass in the `items` of the registry. | Tool 5 already accepts the fixture names. The probe proves the spy form. |

## 1. Port-only reference tests for each controller

### 1.1 How to record the element draws

Upstream facts (checked at the pin):
- `core.datasetController.js:257` `this._ctx = chart.ctx;` is a plain property. JavaScript code can
  write it.
- `core.datasetController.js:713` `const ctx = this._ctx;` (the base `draw`) and
  `controller.bar.js:677` `rects[i].draw(this._ctx);` (a read for each bar) draw the elements on
  that property.
- `controller.bar.tests.js:1677-1698` swaps `chart.ctx` only. The elements still draw on `_ctx`.

Port facts:
- `lib/src/core/core.datasetController.dart:685-689`: `final CanvasRenderingContext2D? ctx;`.
- `test/port/scales/scale_chart_harness.dart:313-347` and
  `tool/reference/scale_chart_common.mjs:910-939`: both sides leave out the element draws. The
  JS side moves `_ctx` to a sink context for this purpose.

Options:

| Option | Behavior | Performance | Structure | Code |
|---|---|---|---|---|
| A. Upstream form: a writable `ctx`. `drawCalls` puts the recording context in `chart.ctx`, in each `scale.ctx` and in each `controller.ctx`. | same | AOT +0.07 to +0.10 ns for each bar only in the bar form (below). No frame effect. | same as upstream (`_ctx` is writable) | `lib/`: delete one `final`. Dart harness: +6 lines. JS: -4 lines (no sink). |
| B. Existing form (phase 6): `final ctx`, no element draws. The observations compare the element properties only. | same | same | differs (final) | 0 lines, but the draw order, the clip and the element paint calls stay untested. |
| C. A recording context from the construction of the chart (an `acquireChart` option). | same | same | changes the harness port (`utils.dart`) | a new option in a ported file and a `DIVERGES` row. |
| D. Faster form: keep `final` and hoist the read. | same | best in the AOT micro benchmark | differs | same as B. |

Evidence (probe P1, `<probe>p1_ctx_field/bin/main.dart` and `bin/per_element.dart`, AOT
`dart compile exe` and dart2wasm run in Node.js through `<probe>p1_ctx_field/run_wasm.mjs`,
10000 elements, 2000 draws, 15 alternated rounds, medians, 3 runs):

| Form | AOT final ns/element | AOT writable | Ratio | wasm ratio |
|---|---|---|---|---|
| One read for each draw (`core.datasetController.js:713`) | 1.41, 1.44, 1.43 | 1.47, 1.43, 1.36 | 1.04, 0.99, 0.95 | 1.019, 1.016, 1.016 |
| One read for each element (`controller.bar.js:677`) | 1.28, 1.27, 1.28 | 1.35, 1.37, 1.37 | 1.055, 1.081, 1.072 | 1.001, 0.993, 0.990 |

- The base `draw` reads `ctx` once for each dataset. The ratio is noise in both directions.
- In the bar form, AOT cannot hoist a writable field across the virtual `draw` call. The cost is
  at most 0.10 ns for each bar: 0.1 µs for 1000 bars, 1000 times below the 0.1 ms resolution of
  the frame figures. Chart.js ADR 0020 §13: a form that changes the upstream structure (here
  `final`) needs a frame gain. It has none. The bar wave can read `ctx` into a local before its
  loop. No code in the loop writes `ctx`, so the behavior stays the same.

Choice: **A**. Score: behavior equal for all options; performance equal at frame resolution; A
keeps the upstream structure; A is the least code (it removes the JS sink).

### 1.2 Phase 6 data with the element draws

The change of `drawCalls` changes the calls of the phase 6 test controllers: they draw their
points now. Options: (a) generate the 8 phase 6 files again; (b) a flag `elements: false` for
phase 6 on both sides.

Evidence (probe P2, `<probe>run_phase6_gens.sh`, the mirror tree `<probe>mirror/` with a copy of
the common file that has the switch `ELEMENT_DRAWS`):
- Without the switch, the mirror writes the 8 committed files byte for byte (8 of 8 equal).
- With the element draws: 8,455,931 bytes become 9,069,771 bytes (+7.3 %). Each generator runs
  in 0.7 s to 2.8 s.
- A second run gives the same SHA-256 (checked for linear `c9f1fe016dbe`, radial linear
  `eef2980becb7` and time `e966251e6b71`).

Choice: **(a)**. No flag, no second code path. The phase 6 scale tests then also compare the
point draws of their test controllers. The same change regenerates the 8 files, because the
Dart `drawCalls` and the data must agree.

### 1.3 The observations

One generic observation serves all 8 controllers. It adds three keys to `observe` of
`scale_chart_common.mjs` (`chartArea`, `scales`, `points`, `drawCalls`):

- `metas`: for each dataset, `type`, `indexAxis`, `visible` (`chart.isDatasetVisible(i)`),
  `stack`, `stacked` (`meta._stacked`), `parsed` (`meta._parsed`, with `_custom` and `_stacks`),
  `dataset` (the props and the options of `meta.dataset`, or null) and `data` (the props and the
  options of each element).
  - The props are the own keys of the element without the `$` keys and `options`, with a
    primitive value. The prototype finds: point `x, y, active, parsed, skip, stop`; line
    `x, y, active, animated, _loop, _fullLoop, _decimated, _pointsUpdated, _datasetIndex`; bar
    `x, y, active, horizontal, base, width, height, inflateAmount, enableBorderRadius`; arc
    `x, y, active, circumference, endAngle, fullCircles, innerRadius, outerRadius, pixelMargin,
    startAngle, circular`. The Dart side reads each key with `element[key]`, the JS property read
    of Chart.js ADR 0017.
  - The options are the own keys of the resolved options, also `$shared`. A function is the
    string `'fn'`.
- `stacks`: `chart._stacks` (Dart `chart.stacks`).
- `hits`: for the center (`getCenterPoint()`) of the first, the middle and the last element of
  each dataset, the center of the chart area and the point (1, 1): each mode of `index`,
  `dataset`, `point`, `nearest`, `x`, `y`, each with `intersect` true and false, gives the list
  `[datasetIndex, index]` of `getElementsAtEventForMode(e, mode, {intersect}, false)`. The event
  is `{type: 'mousemove', native: null, x, y}` (`core.interaction.js` reads `e.x` and `e.y` of a
  chart event). The list order is compared exactly: the item order is protected behavior.

Evidence (probe P2b, `<probe>mirror/packages/flutter_chartjs/tool/reference/controller_probe.mjs`,
`<probe>run_controller_probe.sh`, output `<probe>out/controller_run1.json`):
- 17 cases over the 8 chart types (bar grouped, stacked, `indexAxis: 'y'`, floating, hidden
  dataset; line, stacked with gaps, parsing keys; scatter; bubble; doughnut, spacing; pie;
  polarArea, `spacingMode`; radar, null value) in 236 ms.
- 311,957 bytes of JSON: 9.3 KB to 26.1 KB for each case. The draw calls are about half. The hit
  queries are 48 to 96 for each case.
- A second run gives the same SHA-256 (`087d8036c693...`).

### 1.4 Generators and files

Options:

| Option | Code | Note |
|---|---|---|
| A. Upstream form | — | Upstream has no reference test. The specs and fixtures are its only tests. |
| B. Phase 6 form: one generator and one data file for each module, a shared common file. | 8 generators of about 60 lines each (mostly the case list), one common file | test files run in parallel processes; a failure names the controller |
| C. One generator that writes 8 data files. | 1 generator | the `measured` widths of the common file are global: needs a reset for each file |
| D. One generator, one data file, one test file for all controllers. | least files | one serial isolate for about 150 charts; the test path does not map to a `lib/src` file (AGENTS.md: a port-only test sits at the path of the file that it tests) |

Choice: **B**. It adds no new concept. The shared parts:
- `tool/reference/controller_chart_common.mjs` (new): `registerPhase7(C)`,
  `observeControllers(chart)`, `hits(chart)` and `runControllerCase(name, config, {options,
  action})`. It imports `loadChartJs`, `makeChart`, `observe`, `drawCalls`, `named` and
  `writeReference` of `scale_chart_common.mjs`. Thus the generators keep the checks of the pin
  (x64, the build at the pinned commit, a clean checkout).
- `scale_chart_common.mjs`: `drawCalls` loses the sink (section 1.1). The header text names the
  controller generators too.
- `registerPhase7(C)` is `C.Chart.register(C.controllers, C.scales, C.elements)`: the Dart
  registry of `flutter_test_config.dart` after phase 7, without plugins. The Dart tests then
  register nothing.
- An action (for example `setActiveElements` and `update`) is found by the case name, as
  `scale_linear_reference.mjs` does. The case record keeps its 4 fields.

The generators (`tool/reference/controller_<type>_reference.mjs`) write
`test/port/controllers/controller_<type>_reference.dart`. The tests are
`test/port/controllers/controller.<type>_test.dart`, at the path of
`lib/src/controllers/controller.<type>.dart`.

No time scale case: the time scale needs the moment packages and `atNow` on both sides. The 57
time twins and the 15 `scale.time` spec cases already run the line controller on a time scale.

### 1.5 Case sets

Each case has two datasets unless the list says otherwise. Each generator has one case with the
action "active" (`setActiveElements([{datasetIndex: 0, index: 1}])` and `update()`). It gives the
options of the mode `'active'` for test 3 (section 2.1).

| Controller | Cases | Count |
|---|---|---|
| bar | grouped; stacked x and y; `stack` groups `'a'` and `'b'`; `indexAxis: 'y'`; floating `[start, end]`; floating and stacked; a hidden dataset; negative values with `base`; `barThickness: 'flex'`; a number `barThickness` with `maxBarThickness`; `minBarLength` with zero values; `grouped: false`; `skipNull` with null values; `borderSkipped` `'start'`, `'end'`, `'middle'`, `false` with `borderRadius`; `inflateAmount` `'auto'` and a number; object data with `parsing` keys; a linear index axis (`computeMinSampleSize`); a logarithmic value axis; active | 20 |
| line | basic; stacked; `spanGaps` true, false and 1 with nulls; `showLine: false`; `tension` with `cubicInterpolationMode: 'monotone'`; `stepped`; `indexAxis: 'y'`; `parsing` keys; `{x, y}` data on a linear x; a named `segment` function; `pointRadius: 0` with `pointHitRadius`; a hidden dataset; x `min`/`max` that hide points (`_drawStart`, `_drawCount`); active | 15 |
| scatter | basic; `showLine: true`; a null item; x `min`/`max`; active | 5 |
| bubble | basic; array data `[x, y, r]`; a named `radius` function; a hidden dataset; active (`hoverRadius`) | 5 |
| doughnut | basic; two rings; `cutout` as `'50%'` and as px; `rotation` and `circumference`; a hidden index (`toggleDataVisibility`); `spacing` with the default `spacingMode` and with `'proportional'`; `offset` and `hoverOffset`; `borderAlign: 'inner'`; `weight`; `radius`; a zero and a negative value; active | 12 |
| pie | basic; `cutout: '20%'`; a hidden index; active | 4 |
| polarArea | basic; `startAngle`; a hidden index; `spacing` with the default `spacingMode` and with the chart-level `'angular'`; a named `angle` function; r `min`/`max`; active | 8 |
| radar | basic; null with `spanGaps`; one dataset; `tension`; a hidden dataset; r `startAngle`, `min`, `max`; active | 8 |
| Total | | 77 |

The legend overrides of doughnut, pie and polarArea (`generateLabels`, `onClick`) read
`chart.legend` (`controller.doughnut.js:97`). They wait for phase 8.

### 1.6 Code form

Dart harness (`test/port/scales/scale_chart_harness.dart`, the changed `drawCalls`):

```dart
List<ContextCall> drawCalls(Chart chart) {
  final target = chart.ctx!;
  final recording = RecordingContext(target);
  final scales = chart.scales.values.toList();
  final scaleContexts = [for (final scale in scales) scale.ctx];
  final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
  final controllers = [
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
  return recording.getCalls();
}
```

JS side (`tool/reference/scale_chart_common.mjs`, the changed `drawCalls`):

```js
export function drawCalls(chart) {
  const ctx = chart.ctx;
  ctx.resetCalls();
  chart.draw();
  const calls = dartCalls(ctx.getCalls());
  ctx.resetCalls();
  return calls;
}
```

New Dart harness (`test/port/controllers/controller_chart_harness.dart`, not a test file,
`@TestOn('vm')` for its importers):

```dart
/// The observations `metas`, `stacks` and `hits` of `observeControllers`
/// of tool/reference/controller_chart_common.mjs.
Map<String, Object?> observeControllers(Chart chart);

/// expectScaleChart for the keys `chartArea`, `scales`, `points` and
/// `drawCalls`, then the keys of [observeControllers]. [colors] parses each
/// color (an option key that ends in `Color`, the argument of
/// `setFillStyle`, `setStrokeStyle` and `setShadowColor`) on both sides
/// with the ported @kurkle/color before the compare (section 2.1).
void expectControllerChart(
  Chart chart,
  Map<String, Object?> expected, {
  bool colors = false,
});

/// A testWidgets case for each case: acquireChart, the action of the case
/// name, then expectControllerChart. With [theme], the config gets the
/// compiled theme under `$theme`, and the names start with `light: `.
void testControllerChartCases(
  List<ScaleChartCase> cases, {
  Map<String, Object?> functions = const {},
  Map<String, void Function(Chart chart)> actions = const {},
  AnyObject? theme,
});

/// The chart event of the hit queries: `{type: 'mousemove', native: null,
/// x, y}`.
final class ReferenceEvent implements types.ChartEvent { ... }
```

`expectScaleChart` gets a private part `_expectBase` that both checks call. Its key check
becomes "the keys of the expected case are the keys that the checks read", as now.

A controller test file:

```dart
// Original code, not ported from Chart.js: bar controller reference tests.
@TestOn('vm')
library;

import 'package:flutter_chartjs/src/theme/compile.dart';
import 'package:flutter_chartjs/src/theme/presets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
import 'controller_bar_reference.dart';
import 'controller_chart_harness.dart';

void main() {
  testReferenceOrigin(
    node: controllerBarReferenceNode,
    arch: controllerBarReferenceArch,
    dist: controllerBarReferenceDist,
    commit: controllerBarReferenceCommit,
  );
  testReferenceWidths(controllerBarReferenceWidths);
  testControllerChartCases(controllerBarReference, actions: _actions);
  group('theming.md §8 test 3: the light preset', () {
    testControllerChartCases(
      controllerBarReference,
      actions: _actions,
      theme: compileChartTheme(ChartThemes.light),
    );
  });
}
```

## 2. Theme tests of the phase 7 row of theming.md §10

theming.md §8 items 3, 5 and 6 and the hover tests of §3.2 and §6.

### 2.1 Test 3 for elements and scales on the 8 chart types (colors plugin off)

Options:

| Option | Code | Note |
|---|---|---|
| A. Upstream form | — | Upstream has no theme. |
| B. The form of phases 5 and 6: `theme_light_reference.mjs` resolves the options with `Config` for 8 chart types, and `presets_test.dart` compares. | new generator cases, new data | resolves options without a chart: no draw, no scale layout |
| C. Two Dart charts for each config (unthemed and light), compared with each other. | a pair loop | the unthemed side is pinned only through the reference tests |
| D. The reference cases of section 1 again, with `$theme: compileChartTheme(ChartThemes.light)`, against the same upstream data, with the colors parsed. | one `theme` argument and one color matcher | compares the themed chart directly with upstream: options in the modes `'default'` and `'active'`, the scale layout, the fonts (through the `measureText` widths and the `setFont` calls) and every draw call |

Evidence (probe P4, `<probe>p3_flutter/light_test.dart`, the phase 6 harness with real
category, linear and radial linear scales and the test controllers):
- The cartesian chart: the observations are equal. 474 calls on each side. 48 calls differ in the
  color text only (`'rgba(0,0,0,0.1)'` against `'rgba(0, 0, 0, 0.1)'`). After the parse: 0.
- The radial chart: the observations are equal. 314 calls on each side. 30 calls differ in the
  color text only (`'#666'` against `'rgba(102, 102, 102, 1)'`). After the parse: 0.

Choice: **D**. The parse applies only in the themed run. The unthemed run keeps the exact
strings, because the resolved option is protected behavior. The colors plugin is off because the
generators register no plugin. Its "on" run comes with phase 8.

### 2.2 Hover tests

theming.md §3.2: the root functions of `defaults` derive the hover colors from the base color
that won (`core.defaults.js:62-64`). §6: the active state uses `getHoverColor` over the themed
base.

Options:

| Option | Note |
|---|---|
| A. Upstream form: the hover specs, for example `controller.bubble.tests.js:293-299` (`'#3187DD'` from `rgb(100, 150, 200)`). | They run unthemed (theming.md §6). They stay as spec ports. |
| B. Existing form (phase 5): `precedence_test.dart` compares the active options of a test controller with the JS prototype of the hunks. | new prototype cases for 8 types in `theme_precedence_reference.mjs` |
| C. A themed chart against an unthemed twin that has the replaced values in `defaults` (the phase 6 precedent `_tokenReplaced` of `precedence_test.dart`), after `triggerMouseEvent(chart, 'mousemove', element)` and after `'mouseout'`. | no data; no table of keys for each type |

Choice: **C**, for the 8 chart types, in a new file `test/port/theme/hover_test.dart`. Each case
compares: `chart.getActiveElements()` (the hit), the options of the active element with the
colors parsed, and the draw calls with the colors parsed. One absolute pin: the bar with the
theme `backgroundColor` `rgb(200, 0, 0)` gives `'#B40000'` (theming.md §3.2). The overrides of
the 8 controllers set no color (`controller.*.js` `static overrides`), so the theme and the
`defaults` writes give the same base.

### 2.3 Test 5 on a doughnut and a bar chart

`compile_test.dart` already has the emission guard. `precedence_test.dart` has the group
`test 5: a theme scale type creates no axis` without controllers (theming.md §10, phase 6
state). Choice: add two `testWidgets` cases to that group:
- a doughnut with a theme that has `scale` and `scales.linear` keys: `chart.scales` is empty;
- a bar chart with a theme that has `scales.radialLinear` keys: the scale ids are `['x', 'y']`.

### 2.4 The blue screen without plugins

theming.md §8 item 6 needs no golden file. Chart.js ADR 0009 §4 excludes the image comparison
with upstream. This test compares with no image: it checks a property of each pixel.

Options:

| Option | Strength | Time |
|---|---|---|
| A. Goldens | theming.md §8 item 6 says no golden | — |
| B. Faster form: an audit of the color setters in the draw calls | misses a draw in the default state of the canvas (black `fillStyle`), and any color that does not pass through a setter | no raster |
| C. The pixels of the bitmap: `(chart.canvas as UiCanvasElement).toImageSource().image`, read with `image.toByteData()` (premultiplied `rawRgba`) in `tester.runAsync` | sees every pixel, also the antialiased edges and the text | 13 ms to 19 ms for each 512 x 512 chart |

The pass rule: the theme sets every color token to `rgb(0, 0, 255)` (alpha 1). In premultiplied
RGBA, a pure blue pixel of any coverage is `(0, 0, a, a)`. A blend of blue over blue keeps that
form, because the blue and the alpha channels get the same arithmetic. A transparent pixel
`(0, 0, 0, 0)` shows the blue background. Thus a pixel passes when `r == 0`, `g == 0` and
`b == a`. This needs no composite over a background.

Evidence (probe P3, `<probe>p3_flutter/probe_test.dart`):
- Cartesian chart with a scale title: themed 0 leaks of 8284 drawn pixels; unthemed 8281 leaks of
  8281 drawn pixels (first leak `(4, 4, 4, 11)`).
- Radial chart (point labels, the tick backdrop with `surface` at alpha 0.75): themed 0 leaks of
  13262 drawn pixels; unthemed 13262 leaks of 13262.
- The text of Liberation Sans passes: the test engine renders grayscale antialias.
- Time: 116 ms to 128 ms for the first chart (warm-up), then 13 ms to 19 ms.

Choice: **C**, in a new file `test/port/theme/blue_screen_test.dart`:
- 8 chart types, with the scale titles on, without an active element. The active case waits for
  `IdentityChartHover` (theming.md §8 item 6).
- The committed known-leaks list is empty in phase 7. The test fails when the set of leaks
  changes. The failure names the chart type, the leak count and the first pixel.
- A control case: the same chart without the theme has leaks. Thus the check can fail.
- One case: `defaults` is the same before and after the themed charts (theming.md §6).

```dart
/// The pixels of the bitmap of [chart] that are not pure blue.
Future<({int leaks, int drawn, String first})> bluePixels(
  WidgetTester tester,
  Chart chart,
) async {
  final image =
      (chart.canvas! as UiCanvasElement).toImageSource().image;
  final data = (await tester.runAsync(image.toByteData))!;
  // For each pixel: (r, g, b, a) passes when r == 0, g == 0, b == a.
  ...
}
```

## 3. The lift of the skips

Input: `phase7/classification/all.json` (536 records: 503 `phase7`, 21 legend, 11 tooltip, 1
filler, after decision D1).

### 3.1 When and how

| Item | Form |
|---|---|
| The 309 spec tests that skip as `blocked: controller.*` | In the wave that ports the last controller of the `modules` of the record, replace `test(name, () {}, skip: 'blocked: controller.<x>')` with the ported body as `testWidgets(name, (tester) async { ... })`. |
| The 57 time twins | `test/port/scales/scale.time_test.dart:200-201`: the helper changes in one line, in the line wave: `void _lineTwin(String name, void Function() body) => testWidgets(name, (tester) async => body());`. Its comment changes. The 57 call sites stay. |
| The 5 pure-layer spec files with a lifted case (`core.datasetController`, `core.interaction`, `core.layouts`, `core.ticks`, `element.line`) | Each moves as a whole to `@TestOn('vm')`, `flutter_test` and `package:chartjs_test_utils/flutter.dart`, and loses `setUpSpecs()` (AGENTS.md, Tests). The pure cases that then run on the VM only: 1 in `core.layouts`, 2 in `core.ticks`, 1 in `element.line`. The upstream specs run with the built-in components (the UMD entry), so this is nearer to upstream. |
| The 24 + 12 plugin cases | Their skip reason stays `blocked: plugin.<id>` as the classification gives. |

Options for the lift of the twins: (a) the one-line helper change; (b) 57 edits to
`testWidgets` and delete the helper. Choice: (a). The name `_lineTwin` stays true: each twin is a
line chart case.

Options for the check of the lift: (a) tool 5 alone; (b) tool 5 plus a temporary script
`phase7/classification/lift_check.py` that maps each record of `all.json` to the JSON reporter
output by the full name (the method of the critic, summary.md §6) and fails when a `phase7`
record does not pass, or when a `blocked: plugin.<id>` record has another status or reason.
Choice: (b). Tool 5 sees neither the 57 twins (they are in `test/port/`) nor a wrong verdict. The
script goes with the folder `doc/phase7/` in the last commit of the phase.

### 3.2 A case that fails after the lift

1. Confirm the upstream result with the probe:
   `run_spec.mjs $DIST <spec> --mode none --filter '<it name>'` (`phase7/probe/README.md`).
   The classification has `pass` in the mode `none` for 501 of 503 `phase7` records (498 before
   decision D1, plus the 3 bar cases of D1). The other 2 are `unsupported` in the probe. Their
   evidence is a variant spec (`summary.md` §5 items 2 and 3).
2. Find the defect: the Dart port of a module, the spec transcription, or the harness. Fix it in
   the same wave. Re-read the upstream lines of the assertion before a change.
3. Do not change an assertion of a spec port. Map a Jasmine matcher only by the existing rules
   (`toBeCloseToPixel`, `toEqualOptions`, `_objectContaining`).
4. A new skip of a `phase7` record is not allowed with `blocked:` or `n/a:`. The only allowed
   skip is `'diverges: <row id>'`, with a `differences.md` row and a `DIVERGES` marker. The row
   is allowed only for a difference that Chart.js ADR 0009 does not protect (exact digits or
   pixels only).
5. When the probe shows that a verdict is wrong (for example a plugin changes the case), run
   `compare.mjs` on the case. Change the record only with that evidence, as a decision of the
   phase lead in `summary.md` §8.
6. A hung test: kill the `flutter_tester` processes of the run before the next run. Compare
   resolvers through `jsObjectKeys` and `jsGet`, never with `equals` on a resolver.

## 4. Spec port conventions for the 7 controller spec files

| Item | Convention | Evidence |
|---|---|---|
| Path, header | `test/specs/controller.<type>_test.dart`; line 1 `// Ported from Chart.js v4.5.1+7169e651 test/specs/controller.<type>.tests.js (MIT, Chart.js Contributors).`; `@TestOn('vm')` directly below | porting-flow.md §1 step 5 |
| Imports | `flutter_test`, `package:chartjs_test_utils/flutter.dart`, and `pure.dart` for the matchers. No `setUpSpecs()`: the charts need the built-in components. | AGENTS.md, Tests |
| Names | `group` = the `describe` name, `test`/`testWidgets` = the `it` name, exactly. The manifest has no repeated full name in the 7 files (0 duplicates), so no ` #2`. | `doc/upstream/manifest.json` |
| `describe('auto', jasmine.fixture.specs('controller.<type>'))` (line 2 of each file) | `group('auto', specsFromFixtures('controller.<type>'));` at the same place. The name and the form of the runner come from Chart.js ADR 0029. Tool 5 already takes a fixture path as a test name of this group. | `tool/src/spec_cases.dart:24-30`; `test/flutter_test_config.dart` ("`specsFromFixtures` comes in phase 7") |
| A case without a chart (11) | `test` | — |
| A chart case | `testWidgets(name, (tester) async { ... })`. `await jasmine.triggerMouseEvent(chart, type, point)` is `await triggerMouseEvent(chart, type, point)`. | Chart.js ADR 0022 §2 |
| `beforeEach` that acquires a chart (`controller.bubble.tests.js:255`, `controller.doughnut.tests.js:334`, `controller.line.tests.js:757`, `controller.polarArea.tests.js:305`, `controller.radar.tests.js:256`) | A local function `void beforeEach()` in the group closure. Each test calls it first. Jasmine `this.chart` is a `late Chart chart;` of the group closure. | AGENTS.md, Tests |
| `beforeEach`/`afterEach` without a chart (`controller.bar.tests.js:1313-1322` sets `this.data`; `controller.line.tests.js:556-563` clones `Chart.defaults.datasets.line`) | `setUp`/`tearDown`, line by line. The harness restore also runs, which is harmless. | porting-flow.md §1 step 5 |
| `afterEach` that acquires a chart (`controller.bar.tests.js:1325`) | A local function `void afterEach()`. Each test calls it last. | Chart.js ADR 0022 §8 |
| `spyOn(element, 'draw')` (`controller.bar.tests.js:1181-1184`, `controller.bubble.tests.js:79-82`, `controller.doughnut.tests.js:275-278`, `controller.polarArea.tests.js:121-124`, `controller.radar.tests.js:62-66`, `:90-93`, `controller.line.tests.js:125-130`), `spyOn(meta.dataset, 'updateControlPoints')` (`controller.line.tests.js:125`) and `spyOn(controller, '_onDataPush')` (`core.datasetController.tests.js:15-41`) | See section 4.1. | probe P3 |
| `expect(x).toEqual(jasmine.objectContaining({...}))`, `.withContext(i)` | The file-private `_objectContaining` of `core.controller_test.dart`; `reason: '$i'`. | `test/specs/core.controller_test.dart:94-104` |
| `data.push(...)` and the other array methods | `notifyArrayListeners(list, method, args)` after the change. | porting-flow.md §1 step 5 |
| A nested Map literal of a config | `<String, Object?>{...}` | AGENTS.md, Tests |

### 4.1 Jasmine spies on Dart methods

The rule of AGENTS.md ("a recording function value stored in place of the spied property")
needs a property. An element `draw`, `updateControlPoints` and the array listener methods of a
controller are Dart methods. Dart cannot replace a method of one object.

Options:

| Option | Behavior | Performance | Structure | Code |
|---|---|---|---|---|
| A. Upstream form: replace the property of the instance | — | — | — | not possible in Dart |
| B. Method fields in `lib/` (`draw` as a function field), as `Chart.resize` (Chart.js ADR 0022) | same | a closure per element and an indirect call in the hottest loop | differs | changes 4 element classes and the controller |
| C. A recording context that attributes the calls to an element | fragile: the calls carry no element | none | same | parse of call sequences for each element type |
| D. A private stub subclass for each spied class, put in the `items` of the registry before `acquireChart`, with `addTearDown` that puts the original back | same assertions | none in `lib/` | same in `lib/` | about 20 lines for each spied class in the spec file |

Why not `Chart.register` of the subclass: `core.typedRegistry.js:41-44` returns early when the id
is in `items`, and `:28-31` registers the parent first (same id). Thus a subclass with the id
`'point'` cannot replace `PointElement` through `register`. A write of `items` is the plain
JavaScript form `Chart.registry.elements.items.point = Spy`. `core.controller.js:443-446` reads
`registry.getElement(dataElementType)` each time it builds a controller, so the new chart gets
the subclass.

Evidence (probe P3, `<probe>p3_flutter/probe_test.dart`): with `SpyPoint` in
`registry.elements.items['point']`, a `scaleTest` chart has 4 `SpyPoint` elements
(`is PointElement` is true). After `spying = true` and `chart.update()`, the draws are
`[1, 1, 1, 1]`. The next test gets a `PointElement` again.

Choice: **D**. A Jasmine `spyOn` without `and.callThrough()` is a stub. Thus the subclass does
not call `super` while it spies. The line `spyOn(meta.data[0], 'draw')` maps to
`_spyOnDraw(meta.data[0])` at the same place. The install is one more line at the start of the
body, with a comment. The spy classes are private to each spec file, as `_ClearRectSpy` of
`helpers.canvas_test.dart` and `_Spy` of `core.plugin_test.dart`.

```dart
/// `spyOn(point, 'draw')` of Jasmine: a stub that counts the calls.
final class _SpyPoint extends PointElement {
  _SpyPoint([super.cfg]);

  /// Whether `spyOn` ran for this element.
  bool spying = false;

  /// `draw.calls.count()`.
  int drawCalls = 0;

  @override
  void draw(CanvasRenderingContext2D ctx, [types.ChartArea? area]) {
    if (!spying) return super.draw(ctx, area);
    drawCalls++;
  }
}

/// Puts the spy class of the id 'point' in the registry for this test.
void _installPointSpy() {
  final items = registry.elements.items;
  final original = items['point']!;
  items['point'] = JsClass(
    'SpyPoint',
    superclass: PointElement.jsClass,
    construct: (newTarget, args) => _SpyPoint(elementCfgArg(args)),
  );
  addTearDown(() => items['point'] = original);
}

/// `spyOn(element, 'draw')`.
void _spyOnDraw(types.Element element) => (element as _SpyPoint).spying = true;
```

## 5. Files that the implementation changes

`lib/`:
- `lib/src/core/core.datasetController.dart`: `ctx` loses `final`. Its `///` line says that
  `core.datasetController.js:257` `_ctx` is a writable property.

`tool/reference/`:
- `scale_chart_common.mjs`: `drawCalls` without the sink; the header names the controller
  generators.
- `controller_chart_common.mjs` (new).
- `controller_bar_reference.mjs`, `controller_line_reference.mjs`,
  `controller_scatter_reference.mjs`, `controller_bubble_reference.mjs`,
  `controller_doughnut_reference.mjs`, `controller_pie_reference.mjs`,
  `controller_polarArea_reference.mjs`, `controller_radar_reference.mjs` (new).

`test/port/`:
- `scales/scale_chart_harness.dart`: `drawCalls` with the controllers; `_expectBase`.
- `scales/*_reference.dart`: the 8 phase 6 data files, generated again.
- `scales/scale.time_test.dart`: `_lineTwin` (one line and its comment).
- `controllers/controller_chart_harness.dart` (new).
- `controllers/controller.<type>_test.dart` and `controllers/controller_<type>_reference.dart`
  for the 8 controllers (new).
- `theme/hover_test.dart` and `theme/blue_screen_test.dart` (new).
- `theme/precedence_test.dart`: two cases of test 5.
- `core/core.datasetController_test.dart`: the pin of the writable `ctx` (below).

`test/specs/`:
- the 7 controller spec files (new);
- the 15 files with `blocked: controller.*` skips; 5 of them move to `@TestOn('vm')`.

Docs:
- `doc/theming.md` §10: a "Phase 7 state" paragraph that names the test files of section 2.
- `doc/status.yaml`: the port-only rows of the new harness files; then `dart run melos run parity`.
- `AGENTS.md`, Tests: the spy rule of section 4.1, the element draws in the reference tests, and
  the controller generators in the list of generators.
- `doc/phase7/classification/lift_check.py` (temporary, deleted with `doc/phase7/`).
- The new Chart.js ADR 0030 (proposed).

## 6. Tests that pin the decision

1. `test/port/core/core.datasetController_test.dart`: "the elements draw on the context in
   `ctx`": a write of `controller.ctx` sends the next `draw()` to the new context
   (`core.datasetController.js:257`, `:713`).
2. `test/port/scales/scale_chart_harness_test.dart`: `drawCalls` records the point draws of the
   test controller, and puts back `chart.ctx`, each `scale.ctx` and each `controller.ctx`.
3. `testReferenceOrigin` in each of the 8 controller test files: Node.js v24.12.0, x64, the pin
   version and the commit.
4. The 77 reference cases and their 77 `light:` twins (test 3).
5. `test/port/theme/hover_test.dart`: 8 chart types, and the absolute pin `'#B40000'`.
6. `test/port/theme/blue_screen_test.dart`: 8 chart types with 0 leaks, the control case with
   leaks, and the `defaults` snapshot.
7. `precedence_test.dart`: the two cases of test 5.
8. In each spec file with a spy: the original class is in the registry again after the test (a
   `testWidgets` case after the spy case, as probe P3 "the registry has the built-in point
   again").
9. `lift_check.py` and `dart run melos run test:cases`: each `phase7` record passes, and each
   plugin record skips with its verdict.

## 7. Probe files

All in `<probe>`:
- `p1_ctx_field/bin/main.dart`, `p1_ctx_field/bin/per_element.dart`, `p1_ctx_field/run_wasm.mjs`
  (`run_wasm_pe.mjs` for the second): probe P1.
- `run_phase6_gens.sh`, `mirror/` (with the switch `ELEMENT_DRAWS` in
  `mirror/packages/flutter_chartjs/tool/reference/scale_chart_common.mjs`), `out/1/`, `out/2/`:
  probe P2.
- `mirror/packages/flutter_chartjs/tool/reference/controller_probe.mjs`,
  `run_controller_probe.sh`, `out/controller_run1.json`, `out/controller_run2.json`: probe P2b.
- `p3_flutter/probe_test.dart`: probe P3 (blue screen, spy). Run from `packages/flutter_chartjs`
  with `flutter test <probe>p3_flutter/probe_test.dart`. It imports the test config and the
  phase 6 harness of the package by file URI.
- `p3_flutter/light_test.dart`: probe P4 (test 3).
