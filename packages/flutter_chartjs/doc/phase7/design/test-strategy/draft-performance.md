# Controller test strategy: draft with the lens "performance first"

- Panel: "Controller test strategy" (future Chart.js ADR 0030), phase 7, step 2 (Design).
- Lens: performance first. For each choice, this draft looks for the fastest form that keeps the
  behavior that Chart.js ADR 0009 protects. It measures each form where performance is at stake.
- Scope: the tests of phase 7 other than the spec bodies and the fixtures. The four questions of
  the panel are sections 1 to 4.
- Pin: Chart.js `v4.5.1+7169e651`. All upstream citations are at this pin, read in
  `third_party/Chart.js`.

## 0. Summary of the choices

| Item | Choice | Main evidence |
|---|---|---|
| 1.1 Element draws in the draw calls | A test platform, `RecordingPlatform`, through the upstream extension point `config.platform`. Its context records every call from the construction of the chart. No change in `lib/`. | P1: 879 of 879 calls equal upstream, 240 element calls among them, largest difference 0. B1: every lib form costs the same or more. |
| 1.2 `Path2D` | The Path2D recorder of `line_reference.mjs` in the shared common file, installed before the dist loads. The Dart side replays each `Path2D` argument. | `element.line.js:233`, `element.line.dart:590` |
| 1.3 Generators | One shared file `controller_chart_common.mjs` and one generator for each controller file (8). | Parallel test files; one data file for each `lib/` file |
| 1.4 Data format | Dart `const` literals, as in phase 6. | P2: no measurable compile cost for 2.1 MB; walk 8.6 ms against 45 ms for JSON |
| 1.5 Test granularity | One `testWidgets` case for each reference case. | P3: 6 ms for each case, 2.2 ms for each chart in a batch. 89 cases cost 0.4 s more. |
| 1.6 Comparison | The per-value matchers of `scale_chart_harness.dart`. | P4: 1.3 to 2.6 ms for 879 calls |
| 2.1 Test 3 | The themed Dart chart against the unthemed upstream data of the controller reference files. No new generator. | Same data, less code |
| 2.2 Test 5 | Two more `axes(...)` scenarios (bar, doughnut) in `theme_precedence_reference.mjs`. | `precedence_test.dart:677-698` |
| 2.3 Hover | A `hover` group in `precedence_test.dart`, with the prototype run of `theme_precedence_reference.mjs`. | `core.datasetController.js:919-935` |
| 2.4 Blue screen | The paint call of the chart host over an opaque blue rectangle, `toImageSync`, then exact equality of each pixel. | P5: 0 of 262144 pixels differ for two blues; 1 ms for each chart |
| 3 Lift | Bodies in place of the skips; five pure files move to `@TestOn('vm')`; `_lineTwin` becomes a `testWidgets` wrapper; a lift check against `classification/all.json`. | 366 cases x 6 ms = 2.2 s CPU |
| 4 Spies | A spy replaces the slot that the library reads (a List entry, a listener, a context, a Map entry). No spy hook in `lib/`. | B1: a by-name `draw` read costs 4.4 ns (AOT) and 4.8 ns (wasm) more for each element |

## Evidence index

All probes are in `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/test-strategy-performance/`
(below: `<probe>`). The probe package `<probe>/probe` depends on `flutter_chartjs` and
`chartjs_test_utils` by path. It has copies of `test/flutter_test_config.dart`,
`test/port/scales/scale_chart_harness.dart`, `scale_linear_reference.dart`,
`scale_time_reference.dart` and `test/port/helpers/rounded_rect_upstream.dart`. Flutter 3.44.9,
Dart 3.12.2, macOS arm64. The x64 Node.js v24.12.0 and the Chart.js build at the pin come from
`scratchpad/env/` (`doc/phase7/env-setup.sh`).

| Id | What | Script | Raw output |
|---|---|---|---|
| P1 | The calls of one draw with the element draws: Dart through `RecordingPlatform`, upstream without the sink of `drawCalls` | `<probe>/probe/test/rec/recording_platform_test.dart`, `<probe>/probe_all_calls.mjs` | `<probe>/js_all_calls.jsonl`, `<probe>/probe/dart_all_calls.jsonl`, `<probe>/probe/rec_results.txt` |
| P2 | Reference data as a Dart `const` against JSON: cold compile and walk | `<probe>/probe/test/fmt/*_test.dart`, `<probe>/probe/run_fmt.sh` | `<probe>/probe/fmt_results.txt` (warm), `fmt_results_cold.txt` |
| P3 | The cost of one `testWidgets` case against a batch | `<probe>/probe/test/rec/recording_platform_test.dart` | `<probe>/probe/rec_results.txt` |
| P4 | The cost of the per-value matchers against deep equality | `<probe>/probe/test/rec/match_cost_test.dart` | printed: `MATCH` line, copied in 1.6 |
| P5 | Pixel reads in `flutter_test`: three methods, two blues, one leak | `<probe>/probe/test/px/pixels_test.dart` | `<probe>/probe/px_results.txt` |
| B1 | Micro benchmark of the lib forms that let a test see the element draws, AOT and dart2wasm | `<probe>/bench/bin/ctx_field_bench.dart`, `<probe>/bench/wasm/run.mjs` | `<probe>/bench/aot.txt`, `<probe>/bench/wasm.txt` |

## 1. Port-only reference tests for each controller

### 1.1 The element draws in the draw calls

**Facts at the pin.**
- `core.datasetController.js:257` copies `chart.ctx` into `this._ctx` at the construction of the
  controller. `draw()` (`:712-713`) draws the elements on `this._ctx`.
- `core.controller.js:783-804` (`_drawDataset`) clips on `this.ctx`, the context of the chart.
- `core.controller.js:361` gives `ctx: this.ctx` to a new scale.
- `core.controller.js:136` constructs `new (config.platform || _detectPlatform(initialCanvas))()`.
  `:145` stores the context of `platform.acquireContext` in `this.ctx`. A user platform is an
  upstream extension point of the configuration.
- The upstream spec form `controller.bar.tests.js:1676-1693` swaps `chart.ctx` for a mock and
  draws. The controllers keep `_ctx`. Thus that spec sees the clip calls and no element draw.
- The Dart port: `core.datasetController.dart:643` and `:685-689` (`final CanvasRenderingContext2D?
  ctx`). `core.controller.dart:603-612` constructs the platform of `config.platform` with
  `jsConstruct` and calls `acquireContext`. `platform.flutter.dart:414-456` is the platform of a
  canvas in a chart host.
- Phase 6: `drawCalls` of `scale_chart_harness.dart` puts a `RecordingContext` in place of
  `chart.ctx` and of each `scale.ctx` after the layout. `scale_chart_common.mjs:923-944` gives the
  controllers a second context (the sink). Thus both sides have no element draw.

**Options.**

| Option | Form | Behavior (1) | Performance (2) | Structure (3) | Own code (4) |
|---|---|---|---|---|---|
| R0 | Phase 6: no element draw; compare only the element properties | Misses each canvas call of the elements: the style writes, the paths, the clip of a bar border, the `drawActiveElementsOnTop` order | no lib cost | unchanged | 0 lines |
| R1 | Upstream spec form: swap `chart.ctx` (`controller.bar.tests.js:1687-1691`) | Same gap as R0 | no lib cost | unchanged | 0 lines |
| R2 | Make `DatasetController.ctx` writable (`@visibleForTesting`), and swap it as the JS sink does | Records the elements | B1: equal to the final field (AOT 1.75 against 1.77 ns, wasm 1.65 against 1.66 ns for each element draw) | A change of a shared layer for a test | 1 line in `lib/`, a swap loop in the harness |
| R3 | A static nullable draw hook in `lib/` that a test sets | Records the elements | B1: equal within the noise (AOT 1.81 to 1.86 ns, wasm 1.66 to 1.72 ns) | A port-only hook in a ported file, with a `DIVERGES` marker | about 15 lines in `lib/` |
| **R4** | **A test platform `RecordingPlatform extends FlutterPlatform`. Its `acquireContext` wraps the real context in a `RecordingContext`. The chart gets it through `config.platform`.** | **Records all calls, as the Node.js side records on its one `LiberationContext`. P1: equal.** | **No change in `lib/`, thus no cost by construction** | **Uses the upstream extension point `core.controller.js:136`** | **about 25 lines in the harness** |

**Choice: R4.** R2, R3 and R4 give the same behavior and the same measured cost (B1). R4 changes
no shared layer and no ported file. It also gives the Dart side the same model as the Node.js side:
one recording context for the chart, the scales and the controllers. The reference case drops the
swap of `drawCalls`: it resets the record, draws once and reads the calls.

**P1, the probe.** A chart of the phase 6 test controller `scaleTest` (3 datasets of 10 points) in
both runtimes:
- Upstream: `<probe>/probe_all_calls.mjs` loads the build at the pin through `loadChartJs` of
  `scale_chart_common.mjs`, makes the chart with `makeChart`, resets the calls of its
  `LiberationContext`, draws once, and writes the calls. 879 calls: 639 of the scales and the
  clip, then 240 of the 30 points (`setStrokeStyle`, `setLineWidth`, `setFillStyle`,
  `beginPath`, `arc`, `closePath`, `fill`, `stroke` for each point, `helpers.canvas.ts:204`).
- Dart: `acquireChart` with `'platform': recordingPlatform`. `ctx.resetCalls(); chart.draw();`.
  The first 879 calls have the same names in the same order. Each number argument is equal: the
  largest absolute difference is 0. The only other differences are the trailing optional
  arguments that the Dart mock records (`harness-mock-optional-args`), which `dartCalls` of the
  generator already pads.
- The phase 6 form on the same chart gives 639 calls and 0 `arc` calls.
- Note on the raw file: `rec_results.txt` shows `calls=1277`, because the probe then also ran the
  phase 6 `drawCalls`, which drew a second time into the same live record. The comparison uses
  the first draw only.

**The code form (test side only).**

```dart
// test/port/controllers/controller_chart_harness.dart

/// A [FlutterPlatform] whose context records every call: the context of the
/// chart, of each scale (core.controller.js:361) and of each dataset
/// controller (core.datasetController.js:257).
final class RecordingPlatform extends FlutterPlatform {
  @override
  CanvasRenderingContext2D? acquireContext(Object? canvas, [double? aspectRatio]) {
    final context = super.acquireContext(canvas, aspectRatio);
    return context == null ? null : RecordingContext(context);
  }

  @override
  bool releaseContext(CanvasRenderingContext2D context) => super.releaseContext(
    context is RecordingContext ? context.target : context,
  );
}

/// `config.platform` of a reference chart (core.controller.js:136).
final JsClass recordingPlatform = JsClass(
  'RecordingPlatform',
  superclass: BasePlatform.jsClass,
  construct: (newTarget, args) => RecordingPlatform(),
);

/// The calls of one `chart.draw()` after the layout, with the element draws.
List<Object?> chartDrawCalls(Chart chart) {
  final ctx = chart.ctx! as RecordingContext..resetCalls();
  chart.draw();
  final calls = recordedCalls(ctx.getCalls()); // Path2D arguments replayed (1.2)
  ctx.resetCalls();
  return calls;
}
```

The JS side gets one option with a default that keeps the phase 6 output:

```js
// scale_chart_common.mjs
export function drawCalls(chart, {elements = false} = {}) { ... } // elements: no sink
```

The `RecordingContext` draws nothing on the real context. Thus a reference chart shows no pixels.
The pixel tests of section 2.4 use charts without this platform.

### 1.2 `Path2D`

- `element.line.js:233` tests `typeof Path2D === 'function'` when the module loads. Node.js has
  no `Path2D`. The Dart port always uses `Path2D` (`element.line.dart:585-601`,
  `_usePath2D = true`).
- Phase 4 solved this for one element: `line_reference.mjs:96-107` defines a recording `Path2D`
  on `globalThis` before the import. `element.line_test.dart:152-189` replays each `Path2D`
  argument on a mock context and numbers the paths in the order of first sight.

**Choice.** `controller_chart_common.mjs` defines the same recording `Path2D` on `globalThis` in
its module body, before its first call of `loadChartJs()`. Thus the dist evaluates `usePath2D` to
true, as the port does. `dartCalls` writes a `Path2D` argument as `{"path": <id>, "calls": [...]}`.
The Dart harness maps each `Path2D` argument to the same form with `Path2D.replay`. The helpers
`_PathIds`, `_actual` and `_replay` move from `element.line_test.dart` into a shared helper
`test/port/canvas/path2d_record.dart`, and the line element test imports it (less code: one copy).

Performance does not decide here: the form keeps the upstream calls on both sides.

### 1.3 The generators

| Option | Form | Score |
|---|---|---|
| G1 | One generator for all 8 controllers, one Dart data file, one test file | One test file runs on one core. A change of one controller writes all data again. |
| **G2** | **A shared `tool/reference/controller_chart_common.mjs` and one generator for each controller file: `controller_bar_reference.mjs`, `controller_line_reference.mjs`, `controller_scatter_reference.mjs`, `controller_bubble_reference.mjs`, `controller_doughnut_reference.mjs`, `controller_pie_reference.mjs`, `controller_polarArea_reference.mjs`, `controller_radar_reference.mjs`** | **8 test files run in parallel (`flutter test` runs one `flutter_tester` for each file, on all cores). One data file for each `lib/` file, as phase 6 does for the scales.** |
| G3 | New cases in the scale generators | Mixes two modules in one file. Rejected. |

**Choice: G2.**

`controller_chart_common.mjs` imports `scale_chart_common.mjs`. It keeps the phase 6 checks: it
stops unless Node.js is x64, the build has the version of the pin and the checkout is at the
pinned commit (`loadChartJs`). It adds:
- the recording `Path2D` (1.2);
- `registerPhase7(C)`: `C.Chart.register(C.controllers, C.scales, C.elements)`, the order of
  `flutter_test_config.dart:100` without the empty `plugins` namespace;
- `runControllerCase(name, config, {options, steps, hits, themeKeys})`: `makeChart`, the
  observations of 1.7 after the layout and after each step, `drawCalls(chart, {elements: true})`,
  and `chart.destroy()`;
- `writeControllerReference(outPath, name, cases)`: the writer of `writeReference`, with the same
  header (Node.js, V8, arch, dist, commit), the cases and the widths.

`scale_chart_common.mjs` gets only two changes: `export` on `dartCalls`, `CallsText` and `dart`,
and the `elements` option of `drawCalls`. A rerun of each phase 6 generator must give
byte-identical files (a check of the implementation, `git diff --exit-code test/port/scales`).

A time-scale case (bar on a `timeseries` axis) loads the moment packages with
`loadMomentAdapter` of `scale_time_common.mjs`. Its Dart test runs that chart in `atNow` of
`scale_time_harness.dart`.

Registration note: when phase 7 adds the controllers to the built-in components, the phase 6
Dart tests run with the controllers registered. The phase 6 generators register only the scales
and the elements (`registerPhase6`). The implementation reruns the phase 6 generators with
`registerPhase7` once. If the output is byte-identical, `registerPhase6` stays. If not, the
phase 6 generators move to `registerPhase7` in the same change.

### 1.4 The format of the reference data

| Option | Form | Measured (P2) |
|---|---|---|
| **D1** | **Dart `const` literals in a generated `*_reference.dart` file (phase 6)** | **Cold compile, 4 rounds, cache deleted before each run: 4.34, 4.60, 4.84, 6.56 s. Walk of all 21242 leaves of `scale_time_reference.dart` (2.1 MB): 8.2 to 12.3 ms.** |
| D2 | A JSON file read with `dart:io` and `jsonDecode` | Cold: 4.44, 4.71, 5.67, 6.47 s. Decode and walk of the same data (1.8 MB of JSON): 42.5 to 72.2 ms. A pure test cannot read it on the web. |
| control | The harness import only, no data | Cold: 4.42, 4.66, 6.12, 5.04 s |

The cold compile times of D1, D2 and the control are equal within the noise of the machine (the
order of the three files changes from round to round). The warm runs (5 rounds, cache kept) give
1.39 to 1.55 s for all three. Thus the size of a `const` file has no measured cost. D1 decodes
4 to 5 times faster than D2.

**Choice: D1**, the phase 6 form. The draw calls stay one raw string of JSON lines for each case
(`CallsText`), as in phase 6: the matchers parse them once (`callMatchers`).

Size budget: the probe chart has 879 calls of about 40 bytes. A case with 1500 calls gives about
60 KB. With the case sets of 1.8 (89 cases), the 8 files hold about 4 MB in total, and no file is
larger than the 2.1 MB of `scale_time_reference.dart`. A case set that grows past 2.5 MB for one
file splits into two generators (for example `controller_bar_stacked_reference.mjs`).

### 1.5 The granularity of the test cases

P3, 40 cases of each form on the probe chart:

| Form | Time |
|---|---|
| One `testWidgets` case for each chart, phase 6 form (`drawCalls` swap, `observeChart`) | median 8 ms, mean 8.7 ms |
| One `testWidgets` case for each chart, `RecordingPlatform` | median 6 ms, mean 6.2 ms |
| 40 charts in one `testWidgets` case (`acquireChart`, draw, observe, `releaseChart`) | 88 ms, 2.2 ms for each chart |

The overhead of one `testWidgets` case is about 4 ms. For 89 cases, a batch saves 0.4 s of CPU on
one core. A batch reports only the first failure of a group and hides the name of the case.

**Choice:** one `testWidgets` case for each reference case, as `testScaleChartCases` does. The
`RecordingPlatform` form is also 2 ms faster for each case than the phase 6 swap, because it
needs no second wrapper and no swap of the scale contexts.

### 1.6 The comparison

P4, the 879 calls of P1, 5 repeats: the per-value matchers of `referenceMatcher` took 8.6, 2.4,
2.6, 1.6 and 1.3 ms. `DeepCollectionEquality` took 4.8, 4.3, 1.9, 1.0 and 1.0 ms. Deep equality
cannot keep the tolerance of `referenceMatcher` (1e-9, or `|n| * 1e-12` above 1e3), which
`dart:math` needs against V8 (Chart.js ADR 0009, `js-semantics-dart-math`). The gain of a fast
path is below 1 ms for each case.

**Choice:** keep `referenceMatcher`, `callMatchers` and `expectCalls` of
`scale_chart_harness.dart`. No fast path.

Two rules from the lessons of phase 6:
- Never pass a resolver to `expect`. The observations copy each option object into a plain Map
  through `jsObjectKeys` and `jsGet` first.
- A Map of options compares as a Map (`equals` ignores the key order). A List compares in
  order. The item order that Chart.js ADR 0009 protects is in Lists: the parsed items, the
  elements, the hit items, the calls.

### 1.7 The observations

Each case gives `expected` with these keys. The JS and the Dart observation functions have the
same keys and the same order.

| Key | Content | Upstream source |
|---|---|---|
| `chartArea` | `[left, top, right, bottom]` | `core.controller.js` layout |
| `scales` | for each scale id: `type`, `axis`, `min`, `max`, `box`. With `themeKeys: true` also `options`: the plain copy of the subtrees `grid`, `border`, `ticks` (without `callback`), `title`, and for `radialLinear` `angleLines` and `pointLabels`, with each `toFont` result (`core.scale.js:1702`, `scale.radialLinear.js:96`) | phase 6 has the ticks and the pixels already: the scale reference tests keep them |
| `metas` | for each dataset index: `type`, `controller` (the `id` of the class), `indexAxis`, `xAxisID`, `yAxisID`, `rAxisID`, `visible`, `stack`, `order`, `total` (doughnut, pie), `parsed` (each item of `_parsed` as a plain copy, with `_custom` and `_stacks`), `dataset` (the line or `null`: `getProps` of its keys, `points.length`, `options`), `data` (each element: `getProps(keys, true)` of the keys of its type, `options`, `active`, `hidden`) | `core.datasetController.js` |
| `stacks` | the plain copy of `chart._stacks` | `core.datasetController.js:331` `_updateStacks` |
| `hits` | for each event point of the case and each query: `[datasetIndex, index]` items in order | `core.controller.js:820` `getElementsAtEventForMode` |
| `drawCalls` | the calls of one `chart.draw()` with the element draws (1.1) | — |
| `steps` | for each step: the same keys after the step | — |

The keys of `getProps` for each element type: point `x`, `y`, `skip`, `stop`; bar `x`, `y`, `base`,
`horizontal`, `width`, `height`; arc `x`, `y`, `startAngle`, `endAngle`, `circumference`,
`innerRadius`, `outerRadius`, `pixelMargin`, `fullCircles`; line `_loop`, `_fullLoop` and the
`segments` as `[start, end, loop]`. A function value in an option is the string `'<fn>'` on both
sides. `undefined` is the `undefined` sentinel (phase 6 writer). NaN and the infinities use the
`{'num': ...}` form.

The hit queries for each event point: `point`, `nearest`, `index`, `dataset`, `x`, `y`, each with
`intersect` true and false, and `nearest` with `intersect: false` and `axis` `x`, `y` and `xy`
(15 queries, as `controller_reference.mjs:661-674`). The event points come from the generator:
the `tooltipPosition()` of the elements 0 and 1 of the dataset 0, one point between two elements,
and one point outside the chart area. The Dart test reads them from the reference, so both sides
query the same points. The event is the `_Event` form of `test/port/core/core.controller_test.dart`
with `type: 'mousemove'`.

The steps of a case are data, not functions: `{'setActive': [[datasetIndex, index], ...]}`
(`core.controller.js:1096`), `{'hideDataset': i}` (`setDatasetVisibility(i, false)` then
`update()`), `{'toggleData': i}` (`toggleDataVisibility(i)` then `update()`), `{'push': [d, value]}`
(a push on the data of dataset `d`, `notifyArrayListeners` on the Dart side, then `update()`) and
`{'update': <mode>}`.

### 1.8 The case sets

Each case is small: at most 3 datasets and 12 values. A case set covers the options of the
controller, the parsing modes and the visibility. The first case of each generator is `default`,
with `themeKeys: true` and a `setActive` step: section 2.1 reuses it.

| Controller | Cases (name: what it varies) | Count |
|---|---|---|
| bar | `default`; `indexAxis y`; `stacked`; `stacked negative`; `stacked single`; `two stacks` (`dataset.stack`); `grouped false`; `floating` (`[start, end]`); `floating stacked`; `objects` (`{x, y}`); `parsing keys` (`parsing.xAxisKey`, `yAxisKey`); `parsing false`; `skipNull` with nulls and uneven datasets; `barThickness flex`; `barThickness 12, maxBarThickness 8`; `minBarLength`; `base`; `borderSkipped middle` and `borderRadius` (round rect replay); `inflateAmount auto` and `borderWidth`; `linear index axis`; `logarithmic value axis`; `timeseries index axis`; `hidden dataset` (step); `clip false` | 24 |
| line | `default`; `showLine false`; `spanGaps true`; `spanGaps 2`; `stepped`; `tension 0.4`; `cubicInterpolationMode monotone`; `stacked`; `segment` (`'fn:'` styles); `pointStyle` variants; `indexAxis y`; `objects`; `parsing false`; `nulls`; `drawActiveElementsOnTop false` with `setActive`; `hidden dataset` (step); `push` (step) | 17 |
| scatter | `default` (no line); `showLine true`; `negative values`; `objects with parsing keys`; `hidden dataset` | 5 |
| bubble | `default` (`{x, y, r}`); `radius option`; `hoverRadius` with `setActive`; `parsing keys`; `borderWidth`; `r undefined`; `clip`; `hidden dataset` | 8 |
| doughnut | `default`; `cutout 50%`; `cutout 40`; `rotation and circumference` (a half doughnut); `two datasets with weight`; `toggleData` (step); `spacing angular` (default `spacingMode`, `controller.doughnut.js:75`); `spacing proportional`; `spacing parallel`; `borderRadius`; `offset`; `borderAlign inner`; `zero and negative values`; `parsing key`; `parsing false` | 15 |
| pie | `default`; `rotation`; `toggleData` (step); `two datasets` | 4 |
| polarArea | `default` (`spacingMode: 'proportional'`, `controller.polarArea.js:26`); `spacing` with the chart-level `spacingMode` override (`:204-210`); `startAngle`; `angle` per item; `toggleData` (step); `scale r reverse`; `scale r min max`; `two datasets` | 8 |
| radar | `default`; `showLine false`; `spanGaps`; `tension`; `objects {r}`; `scale r beginAtZero false`; `pointLabels display false`; `hidden dataset` (step) | 8 |
| Total | | 89 |

### 1.9 The Dart files and signatures

```dart
// test/port/controllers/controller_chart_harness.dart (port-only, not a test file)

/// One case of a controller reference file. The generated typedef of each
/// file has this record type.
typedef ControllerChartCase = ({
  String name,
  Map<String, Object?> config,
  Map<String, Object?> options,
  List<Object?> steps,
  List<Object?> points, // the event points of the hit queries
  Map<String, Object?> expected,
});

/// The observations of [chart] with the keys of `observe` of
/// controller_chart_common.mjs (section 1.7).
Map<String, Object?> observeControllerChart(
  Chart chart, {
  required List<Object?> points,
  bool themeKeys = false,
});

/// Applies one step of a case to [chart].
void applyStep(Chart chart, Map<String, Object?> step);

/// Expects [chart] to give [expected], key by key, with the matchers of
/// scale_chart_harness.dart. A failure names the key path.
void expectControllerChart(Chart chart, ControllerChartCase c);

/// A `testWidgets` case for each of [cases]: `acquireChart` with the config
/// of the case plus `'platform': recordingPlatform`, then the observations,
/// then each step and its observations.
void testControllerChartCases(
  List<ControllerChartCase> cases, {
  Map<String, Object?> functions = const {},
});
```

Each test file, for example `test/port/controllers/controller.bar_test.dart`:

```dart
// Original code, not ported from Chart.js: reference tests of the bar controller.
@TestOn('vm')
library;

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
  testControllerChartCases(controllerBarReference);
}
```

The built-in components register the controllers (`flutter_test_config.dart`,
`harness-register-builtins`). Thus a controller test file registers nothing in `main()`.

## 2. The theme tests (theming.md §10, phase 7 row)

### 2.1 Test 3 for elements and scales on the 8 chart types

Test 3 (theming.md §8): the light preset equals upstream. Phase 5 and phase 6 compare the
resolver output without a chart (`presets_test.dart`, `presets_radial_test.dart`,
`theme_light_reference.mjs`). Phase 7 has real controllers. The colors plugin does not exist in
phase 7, so "colors plugin off" holds for each chart.

| Option | Form | Score |
|---|---|---|
| T1 | Extend `theme_light_reference.mjs` with a model of `_resolveElementOptions` for each chart type, without a chart (the phase 5 form) | A model of the resolution, not the resolution. New generator code. |
| T2 | A new generator `theme_chart_reference.mjs` with 8 charts | Real charts, but a second copy of data that the controller references already hold |
| **T3** | **Reuse the `default` case of each controller reference file. The test builds the same config with the compiled light theme (`themeConfigKey: compileChartTheme(ChartThemes.light)`) and compares the element options (default and, after the `setActive` step, active) and the scale `options` subtrees with the unthemed upstream values, with each color parsed (`Color(value).rgbString()`, as `presets_test.dart` does)** | **Real charts, the resolved values of the upstream build at the pin, no new generator and no new data** |

**Choice: T3.** Performance is equal (8 charts). T3 has the least code and the strongest
evidence. A file `test/port/theme/presets_chart_test.dart` (`@TestOn('vm')`) imports the 8
reference files. The theme keys that the light preset emits come from `light_snapshot.json`. The
test compares only the keys that the snapshot emits, and it fails when an emitted key is absent
from the observed options (a stale key).

### 2.2 Test 5 on a doughnut and a bar chart

Phase 6 has the part of test 5 without controllers (`precedence_test.dart:1671`, the scenarios
`axes(...)` of `theme_precedence_reference.mjs:1294-1360`). Phase 7 adds 4 scenarios:
- `axes of a doughnut chart without a theme` and `axes of a doughnut chart with cartesian theme
  keys` (`scale.*`, `scales.x` in the theme Map): a themed `scales.<id>` fails the emission guard
  and creates no axis (theming.md §3.3).
- `axes of a bar chart without a theme` and `axes of a bar chart with a radialLinear theme key`:
  no `r` axis.

The generator registers the pinned `src/controllers/controller.bar.js` and
`controller.doughnut.js` (type stripping, the existing resolve hook), and the arc and bar elements
that it registers already. The Dart side calls `_axes('bar', theme)` and `_axes('doughnut',
theme)` with the real types. Cost: 4 charts.

### 2.3 The hover tests

theming.md §6: the state `active` resolves with the prefixes `[typeHover, 'hover', type, '']`
(`core.datasetController.js:804-835`, `:919-935`), and the default hover colors come from
`getHoverColor` over the base color (`helpers.color.ts:28`, `core.defaults.js:62`). A theme
changes the base. Thus the hover color of a themed chart is `getHoverColor(<theme base>)`.

**Form.** A group `hover` in `precedence_test.dart`, one case for each of the 6 controllers with
an `Interactions` group upstream (line, bar, bubble, doughnut, polarArea, radar), with the
sentinel theme of test 2 (base colors that no default has):
1. `triggerMouseEvent(chart, 'mousemove', element)` on element 0 of dataset 0.
2. The observation: `backgroundColor`, `borderColor`, `borderWidth` and `radius` (point) of
   `element.options`.
3. `triggerMouseEvent(chart, 'mouseout', element)`, the same observation.
4. The same with a user `hoverBackgroundColor` in the dataset: the user value wins.

The expected values come from the `prototype` run of `theme_precedence_reference.mjs` (hunks
H0-H3 on the pinned `core.config.js`). Node.js has no events on `BasicPlatform`. The generator
calls `chart._eventHandler(e)` (`core.controller.js:1163`) with the event of the same point, the
call that the Dart platform listener makes after `triggerMouseEvent`. Both reach
`_handleEvent` (`:1196`) and `_updateHoverStyles` (`:1145`).

Cost: 6 charts, 12 mouse events of one frame each (16 ms of fake time, no real wait).

### 2.4 The blue screen without plugins

theming.md §8 test 6: a test-support theme sets every token to one blue. Every pixel must be
blue, in 8 chart types, without a golden file. Phase 7 has no plugin, so the titles of the legend
and the tooltip wait for phase 8. The scale titles are on (`title.display: true`).

**Options for the pixel read in `flutter_test`** (P5, a 512 x 512 chart of 30 points with scale
titles, 3 repeats):

| Option | Form | Time (warm) | Result for `#0000ff` | Result for `#2050c0` |
|---|---|---|---|---|
| M1 | `captureImage` of the `ChartHost` element (the layer of the view), `toByteData` in `tester.runAsync` | 0.7 to 1.5 ms | 0 of 15311 drawn pixels differ | 2026 of 15311 drawn pixels differ |
| M2 | `UiCanvasElement.toImageSource()` (`canvas_ui.dart:354-358`), `toByteData` | 0.8 to 2.6 ms | 0 of 15311 | 2026 of 15311 |
| **M3** | **The paint call of the chart host (`chart_host.dart:706`, `UiCanvasContext.paint`) into a `PictureRecorder` over an opaque blue rectangle, `toImageSync`, `toByteData(rawStraightRgba)`** | **0.9 to 1.4 ms** | **0 of 262144 pixels differ** | **0 of 262144 pixels differ** |
| M4 | No raster: check the styles of the recorded calls | about 1 ms | no pixels: misses a default style that no setter writes | — |
| goldens | `matchesGoldenFile` | — | forbidden by theming.md §8 | — |

M1 and M2 read the canvas over transparent pixels. An edge pixel with a partial alpha loses
precision when the format removes the premultiplied alpha, so a blue with channels that are not
0 or 255 gives 2026 false leaks. M3 composites over the opaque blue background that the theme
describes, so each edge pixel blends blue with blue, and the result is exact. A red grid line
(the leak probe) gives 4770 pixels that differ under M3. The scan of 262144 pixels takes 0.8 to
2.7 ms.

**Choice: M3 with exact equality, no tolerance.** All forms cost about 1 ms for each chart; M3 is
the only exact one. The circle batch of the canvas layer (`canvas_ui_batch.dart`) draws the
points of the probe; the result stays exact.

**Code form.**

```dart
// test/port/theme/blue_screen_test.dart (@TestOn('vm'))

/// The pixels of the bitmap of [chart] over an opaque [background], as the
/// chart host paints it (chart_host.dart:706).
Future<ByteData> chartPixelsOver(
  WidgetTester tester,
  Chart chart,
  ui.Color background,
) async {
  final canvas = chart.canvas! as UiCanvasElement;
  final w = canvas.width, h = canvas.height;
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder)
    ..drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        ui.Paint()..color = background);
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

/// The count of pixels of [data] that are not [rgb].
int offPixels(ByteData data, int rgb);

/// The known leaks of phase 7, by chart type, each with its upstream
/// file:line. Empty at the start. The test fails when a type has a leak
/// that the list does not name, and when a listed leak is gone.
const Map<String, List<String>> knownLeaks = {};
```

The 8 chart types: `bar`, `line`, `scatter`, `bubble`, `doughnut`, `pie`, `polarArea`, `radar`.
Each chart: 2 datasets, labels, scale titles on, `themeConfigKey` with the blue theme, one
`tester.pump()`, then `chartPixelsOver`. The blue theme is a raw Map theme of the test file: each
color token and the background are one blue with alpha 1. The test uses a blue with channels
that are not 0 or 255 (for example `#2050c0`), so that a rounding fault shows. Cost: 8 charts at
about 3 ms each.

A leak is a defect of the theme emission (a token that does not reach a visual key) or an upstream
read that the theme cannot reach (theming.md §9 lists `scale.radialLinear.js:14`). The second kind
gets an entry in `knownLeaks` with its file:line. The `pixels` count does not name the source.
When a leak shows, the implementer runs the same chart with `RecordingPlatform` and lists the
calls with a style that is not blue: that list names the option.

## 3. The lift of the skips

### 3.1 The forms

- A spec case that skips as `'blocked: controller.*'` and has the verdict `phase7` gets its body
  and loses the skip. The form of the body follows section 4. 366 Dart tests: 309 in `test/specs/`
  and the 57 time twins.
- A case that skips as `'blocked: plugin.<id>'` keeps its skip. The 3 cases of decision D1
  (`controller.bar.tests.js:1426`, `:1442`, `:1538`) get bodies.
- The time twins: `_lineTwin` (`scale.time_test.dart:200-201`) changes to a `testWidgets`
  wrapper, and the 57 call sites stay as they are:

  ```dart
  void _lineTwin(String name, void Function() body) =>
      testWidgets(name, (tester) async => body());
  ```

  The name of the helper stays. A rename touches 57 lines for no behavior.
- Five pure-layer spec files get chart cases: `core.datasetController_test.dart`,
  `core.interaction_test.dart`, `core.layouts_test.dart`, `core.ticks_test.dart` and
  `element.line_test.dart`. Each moves as a whole (AGENTS.md, Tests): `@TestOn('vm')`,
  `flutter_test` in place of `package:test`, `package:chartjs_test_utils/flutter.dart`, and no
  `setUpSpecs()` call. The pure cases of these files lose the web legs: 7 in `core.layouts`, 2 in
  `core.ticks` and 1 in `element.line` (the other two files have no pure case). The pure-layer
  tests of `test/port/` keep the web coverage of these modules. `check:lib-imports` enforces the
  move.

Runtime: P3 gives 6 to 8 ms for each chart case. 366 cases add about 2.2 to 2.9 s of CPU, spread
over the parallel test files.

### 3.2 The lift check

One run gives all data: `flutter test --reporter json test/specs test/port` (tool 5 and tool 6
read the same output through `--results`). A working script `doc/phase7/lift_check.py` (deleted at
the end of the phase with `doc/phase7/`) maps each record of `classification/all.json` to its Dart
test by the full name (the field `test`), as the critic of the classification did, and checks:

| Verdict | The Dart test must |
|---|---|
| `phase7` | have the result `success` and no skip |
| `blocked: plugin.<id>` | skip with exactly that reason |

It prints each record that fails a rule, and the count by spec file against
`classification/summary.md` §2 (with decision D1: `phase7` 503, `blocked: plugin.legend` 21).
`test:cases` then reports 0 missing cases.

### 3.3 A case that fails after the lift

The classification gives `pass` in the mode `none` for 498 of the 500 `phase7` records (2 are
`unsupported` in the probe, `summary.md` §5 items 2 and 3). Thus a failure after the lift is a
defect of the port until a probe shows otherwise. The rule, in this order:

1. Run the upstream case in the probe harness, mode `none` (`doc/phase7/probe/README.md`), with
   `--filter '<it name>'`. Compare the asserted values with the Dart values.
2. If the Dart value differs from upstream, the defect is in `lib/` or in the harness. Fix it in
   the same unit. Add a port-only test in `test/port/` when the case does not pin the cause alone.
3. If the difference is only in exact digits or pixels of a value that Chart.js ADR 0009 does not
   protect, and the upstream matcher is exact, the case keeps its assertion with the tolerance of
   `toBeCloseToPixel` only where upstream uses that matcher. Otherwise the case skips as
   `'diverges: <row id>'` with a `differences.md` row and a `DIVERGES` marker at the Dart site.
4. Never a new `'blocked: ...'` skip for a `phase7` record, never a changed assertion, never a
   removed case. A case that the probe cannot run (`unsupported`) uses the static evidence of its
   record; a failure there follows steps 2 and 3.

## 4. The spec port conventions for the 7 controller spec files

### 4.1 Files and names

- `test/specs/controller.<name>_test.dart` for `bar`, `bubble`, `doughnut`, `line`, `polarArea`,
  `radar` and `scatter`. Line 1: `// Ported from Chart.js v4.5.1+7169e651
  test/specs/controller.<name>.tests.js (MIT, Chart.js Contributors).` Then `@TestOn('vm')`.
- Imports: `flutter_test` and `package:chartjs_test_utils/flutter.dart`. No `setUpSpecs()`.
- `group()` and `testWidgets()` names equal the `describe` and `it` name strings, character for
  character. The duplicated names get ` #2` and ` #3` (porting-flow.md §1 step 5).
- The 11 cases without a chart stay `test()` cases in the same file.
- A case blocked by a plugin of phase 8 keeps its name and body text in a comment and skips as
  `'blocked: plugin.<id>'` (12 cases, `summary.md` §4).

### 4.2 The `auto` group

`describe('auto', jasmine.fixture.specs('controller.bar'))` (line 2 of each file) is a fixture
group, not a case. Its form comes from the fixture runner ADR (another panel of step 2). The
requirement of this draft: the `auto` group registers its tests with the tag `fixtures`, so that
`--exclude-tags fixtures` of the melos `test` script excludes them, and it lists the fixture
folder only once per file at load time.

### 4.3 `beforeEach`, `afterEach` and `this`

- A `beforeEach` that acquires a chart is a local function of the group, and each `testWidgets`
  body calls it first (Chart.js ADR 0022 §2). Jasmine `this.chart` is a `late Chart chart;` of the
  group closure that the local function writes.

  ```dart
  group('Interactions', () {
    late Chart chart;
    void beforeEach() {
      chart = acquireChart(<String, Object?>{ ... });
    }

    testWidgets('should handle default hover styles', (tester) async {
      beforeEach();
      final point = chart.getDatasetMeta(0).data[0];
      await triggerMouseEvent(chart, 'mousemove', point);
      ...
    });
  });
  ```

- An `afterEach` that reads a chart is a local function that each body calls last
  (`controller.bar.tests.js:1325`, `:1399`).
- `controller.bar.tests.js:1464` makes one `describe` for each `barThickness` in a loop. The Dart
  form is a `for` loop over the same values that calls `group('When barThickness is
  $barThickness', ...)`, with the JS string of the value (`jsToString`).
- A nested Map literal of a config has the type `<String, Object?>` (AGENTS.md, Tests).

### 4.4 Jasmine spies

Upstream spies on methods: `spyOn(meta.data[i], 'draw')` (bar :1181, bubble :79, doughnut
:275, line :125-130, polarArea, radar :62-66 and :90-93) and `spyOn(meta.dataset,
'updateControlPoints')` (line :125). The phase 7 lifts add `spyOn(controller, '_onDataPush')`
and the other array methods (`core.datasetController.tests.js:15-40`).

A Dart object cannot replace one of its methods. The options:

| Option | Form | Performance (B1, for each element draw) | Score |
|---|---|---|---|
| S1 | A by-name read in `lib/`: the controller reads an own `draw` property of the element (the extras Map of Chart.js ADR 0017) before the method | AOT +4.4 ns (6.17 against 1.77 ns), wasm +4.8 ns (6.44 against 1.66 ns) | Slower in the hottest loop of a frame. Rejected. |
| S2 | The method field form of Chart.js ADR 0022 for `draw` (a field that holds the function) | AOT +1.4 ns (3.1 to 3.2 against 1.7 to 1.8 ns), wasm +0.1 to 0.2 ns | A structure change of every element for a test. Rejected. |
| S3 | A spy hook in `lib/` (a static nullable function) | equal within the noise | A port-only hook in a ported file. Rejected: S4 needs no lib change. |
| **S4** | **The spy replaces the slot that the library reads. The spy object is a test subclass of the concrete class. It records each call and does nothing else, as a Jasmine spy without `callThrough`.** | **no lib cost** | **The upstream semantics of the assertions; the existing form of `helpers.canvas_test.dart:37-76` (the context slot) and `core.plugin_test.dart:62-110` (a Map entry)** |

**Choice: S4.** The slots:

| Upstream spy | The slot that the library reads | The Dart spy |
|---|---|---|
| `spyOn(meta.data[i], 'draw')` | the entry `i` of `meta.data`, read by `DatasetController.draw` (`core.datasetController.dart:1402-1416`) | `meta.data[i] = SpyPointElement()` (or `SpyBarElement`, `SpyArcElement`): a subclass with `int drawCount` whose `draw` records and returns |
| `spyOn(meta.dataset, 'draw')`, `spyOn(meta.dataset, 'updateControlPoints')` | `meta.dataset` | `meta.dataset = SpyLineElement()`: `draw` and `updateControlPoints` record and return |
| `spyOn(controller, '_onDataPush')` and the other 4 | the listener of the data array (`helpers.collection.dart:273`, `:334`) | `unlistenArrayEvents(data, controller); listenArrayEvents(data, spy)`: a listener that records each `onData*` call and does nothing else |
| `spyOn(chart.ctx, ...)` | `chart.ctx` | the existing form of `helpers.canvas_test.dart` |

The spy element replaces the instance before the `chart.update()` of the case. The update then
writes its properties as it writes them on the original element. The assertions read the counts
of the spy (`spy.drawCount` for `draw.calls.count()`). The spy classes are file-local in each spec
file, or one shared port-only helper `test/specs/support/spies.dart` when two files need the same
class. A `callThrough` spy calls the super method after the record.

## 5. Files that the implementation changes

New files:
- `packages/flutter_chartjs/tool/reference/controller_chart_common.mjs`
- `packages/flutter_chartjs/tool/reference/controller_{bar,line,scatter,bubble,doughnut,pie,polarArea,radar}_reference.mjs`
- `packages/flutter_chartjs/test/port/controllers/controller_chart_harness.dart`
- `packages/flutter_chartjs/test/port/controllers/controller_{bar,line,scatter,bubble,doughnut,pie,polarArea,radar}_reference.dart` (generated)
- `packages/flutter_chartjs/test/port/controllers/controller.{bar,line,scatter,bubble,doughnut,pie,polarArea,radar}_test.dart`
- `packages/flutter_chartjs/test/port/canvas/path2d_record.dart`
- `packages/flutter_chartjs/test/port/theme/presets_chart_test.dart`
- `packages/flutter_chartjs/test/port/theme/blue_screen_test.dart`
- `packages/flutter_chartjs/test/specs/controller.{bar,bubble,doughnut,line,polarArea,radar,scatter}_test.dart`
- `packages/flutter_chartjs/doc/phase7/lift_check.py` (working file of the phase)

Changed files:
- `packages/flutter_chartjs/tool/reference/scale_chart_common.mjs`: the exports and the `elements`
  option of `drawCalls`. The phase 6 data stays byte-identical.
- `packages/flutter_chartjs/tool/reference/theme_precedence_reference.mjs`: the controllers bar
  and doughnut and the line, bubble, polarArea and radar controllers for the hover scenarios, 4
  `axes` scenarios, the hover scenarios.
- `packages/flutter_chartjs/test/port/theme/precedence_reference.dart` (generated) and
  `precedence_test.dart`: test 5 rows and the `hover` group.
- `packages/flutter_chartjs/test/port/elements/element.line_test.dart`: imports
  `path2d_record.dart`.
- `packages/flutter_chartjs/test/port/scales/scale.time_test.dart`: `_lineTwin`.
- The 15 spec files with `'blocked: controller.*'` skips (bodies), five of them moved to
  `@TestOn('vm')`.
- `packages/flutter_chartjs/doc/theming.md` §10: a "Phase 7 state" paragraph (at the end of the
  phase).
- `packages/flutter_chartjs/doc/status.yaml`: the port-only rows of the new test files.
- `AGENTS.md`, Tests: the generator list, `RecordingPlatform`, the spy slot rule, the blue screen
  read.
- No file in `lib/`.

## 6. Tests that pin the decision

- `controller_chart_harness` self-test, in `controller.bar_test.dart`: a chart with
  `recordingPlatform` records element calls (`arc` count equal to the point count for a line,
  `fillRect` or the round-rect replay for a bar) and the context of each scale and of each
  controller is the `RecordingContext` of the chart (`identical(chart.scales['x']!.ctx,
  chart.ctx)`).
- `testReferenceOrigin` in each controller test: Node.js v24.12.0, x64, the dist version and the
  commit of the pin.
- `testReferenceWidths` in each controller test: the Liberation Sans widths.
- The 89 reference cases (1.8).
- `presets_chart_test.dart`: test 3 on 8 chart types; a stale emitted key fails.
- `precedence_test.dart`: test 5 on `bar` and `doughnut`; the `hover` group.
- `blue_screen_test.dart`: 8 chart types, 0 pixels that differ, and a control case: a red grid
  color gives more than 0 pixels that differ (the read finds a leak).
- The lift check (`doc/phase7/lift_check.py`): 503 `phase7` cases pass, 21 legend, 11 tooltip and
  1 filler cases skip with their reasons.
- A rerun of each phase 6 generator after the change of `scale_chart_common.mjs` gives
  byte-identical files.

## 7. Raw figures

P2 (cold, `<probe>/probe/fmt_results_cold.txt`):

```
round=1 a_const 4.34 s walk 8665 us | b_json 4.44 s decode 39066 us total 45957 us | control 4.42 s
round=2 a_const 4.60 s walk 9634 us | b_json 4.71 s decode 42869 us total 49561 us | control 4.66 s
round=3 a_const 4.84 s walk 9267 us | b_json 5.67 s decode 63755 us total 72213 us | control 6.12 s
round=4 a_const 6.56 s walk 12259 us | b_json 6.47 s decode 42760 us total 49986 us | control 5.04 s
```

B1 (`<probe>/bench/aot.txt`, `wasm.txt`; 300 elements, 20000 draws, 11 rounds in ABBA order,
median ns for each element draw; two processes each):

| Form | AOT run 1 | AOT run 2 | wasm run 1 | wasm run 2 |
|---|---|---|---|---|
| A final `ctx` (lib now) | 1.767 | 1.742 | 1.653 | 1.656 |
| B mutable `ctx` (R2) | 1.750 | 1.756 | 1.653 | 1.647 |
| C static hook (R3, S3) | 1.807 | 1.856 | 1.661 | 1.659 |
| E draw in a field (S2) | 3.226 | 3.114 | 1.749 | 1.822 |
| F by-name `draw` read (S1) | 6.169 | 6.160 | 6.435 | 6.463 |

P5 (`<probe>/probe/px_results.txt`):

```
PX #0000ff 512x512
 rep1 M1 us=854 off=0/15311 | M2 us=911 off=0/15311 | M3 us=899 off=0/262144 scan_us=2708
PX #2050c0 512x512
 rep1 M1 us=712 off=2026/15311 | M2 us=823 off=2026/15311 | M3 us=923 off=0/262144 scan_us=790
LEAK off=4770
```

P3 (`<probe>/probe/rec_results.txt`): one case, phase 6 form: median 8 ms; one case,
`RecordingPlatform`: median 6 ms; 40 charts in one case: 88 ms.
