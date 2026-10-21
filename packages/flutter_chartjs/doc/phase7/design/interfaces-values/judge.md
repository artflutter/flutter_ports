# Judge: controller interfaces and values

- Panel: "Controller interfaces and values" (the future Chart.js ADR 0028, proposed). Phase 7,
  step 2 (Design).
- Inputs: [draft-fidelity.md](draft-fidelity.md) (F), [draft-performance.md](draft-performance.md)
  (P) and [draft-simplicity.md](draft-simplicity.md) (S).
- Pin: Chart.js `v4.5.1+7169e651` (`third_party/Chart.js` at `7169e65`). "DC" is
  `lib/src/core/core.datasetController.dart`, "cc" is `lib/src/core/core.controller.dart`.
  `bar.js`, `line.js` and the other short names are files of `src/controllers/`. `index.d.ts` is
  `src/types/index.d.ts`.
- Judge evidence (below: `<j>`):
  `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/interfaces-values-judge/`.
  `<j>/bin/points_judge.dart` is the benchmark of question 3, `<j>/run.sh` the runner,
  `<j>/out/points_aot.out` and `<j>/out/points_wasm.out` the output. `<j>/lintprobe/` is the lint
  probe of question 7. `<j>/out/probe_spacing_simplicity.rerun` is the rerun of the S probe of
  question 5.

## 1. Result

| Question | Winner | Take from the other drafts |
|---|---|---|
| 1. Interface members | P | F: the first-reader table with the concrete Dart lines (F §1.3), and the analyzer probe E1.1 as the compile pin. S and P: the doughnut cast to its own class. |
| 2. `getLabelAndValue` | F (tie on the decision) | P: the `null` and `''` labels of P4. S: the label past the end of the radar labels. ADR 0027: `jsGetIndex` for `labels[index]`. |
| 3. `meta.data` and `line.points` | S (K: a typed copy in the setter) | P: T as the Open item with the frame figures of P §8. F: the line, scatter and radar test of the same items (without its identity assertion). |
| 4. `getDataVisibility` | tie; P has the best evidence | F: the pin test of a `false` entry after two toggles, `1.5` and NaN. P: `-0`, `1e21` and the `_updateHiddenIndices` moves. |
| 5. The #12238 hunk | S (tie on the decision) | P: the sweep of all polar area fixtures (66 configurations, one A/B difference). F: the table of the nine scope rows. |
| 6. Option functions | P | F: `probe_legend_fns` as the reference data of the test. S: the minimal `types.LegendElement` and the doughnut descriptors `_scriptable` and `_indexable`. |
| 7. Registration | S | P: the effect on `flutter_test_config.dart` and the ids of the test controllers. F: the registry tests. |

**Overall winner: S (the simplicity draft).** It wins the question with the largest effect,
question 3: its form K removes the per-draw cost of the cast view of F, and it does not change
the shared core layer as the form T of P does. It is the only draft whose code forms pass
`dart analyze --fatal-infos` (question 7). It finds the one hover row of the hunk that the other
drafts do not test (question 5). Its losses are small: the line writes of question 1 move a throw
from the draw to the update (F has the same problem), its `Object?` parameters of question 6 add
a cast line to each function, and it counts only 2 of the 8 test and tool fakes that the new
members break.

P is a close second. It wins questions 1, 4 and 6. Its answer to question 3 changes a shared
layer with a gain that is below the threshold of Chart.js ADR 0020 §13 (section 3, question 3).
F wins question 2 on its evidence. Its answer to question 3 costs 10 to 19 % of the line draw on
dart2wasm for each frame.

## 2. Judge runs

### 2.1 Question 3: the draw and the update cost of `line.points`

The figure of question 3 decides the score, and the drafts measured different things: F and P
measured the slow copy `List.of(data.cast())`, S measured the fast copy `List.generate` but only
with one update for each draw. The judge run separates the two costs.

- Bed: Apple M3 Max, macOS 26.5.1, Dart 3.12.2. AOT is `dart compile exe`. wasm is
  `dart compile wasm -O2`, run in the arm64 Node.js v24.12.0 (times only). The load average was 5.7
  to 6.4.
- The benchmark imports the real `LineElement`, `PointElement`, `BarElement` and `ArcElement` of
  `lib/src/` through the workspace package config. The line has `animated` true, so each draw runs
  `updateControlPoints` and builds the path again (`element.line.js` draw). A stub context sums the
  path calls.
- `draw_typed`: one draw of a line whose points are a `List<types.PointElement>` (the draw of T and
  of K). `draw_view`: one draw of a line whose points are `meta.data.cast<types.PointElement>()`
  (V). `set_copy`: the setter of K, `List<types.PointElement>.generate` of a
  `List<types.Element>`. `set_typed`, `set_view`: the setter of T and V.
- Each process runs each op for about 60 ms for each sample, 3 warm-up rounds, then 15 rounds in a
  rotated order. The table gives the range of the medians of 3 processes. µs for each op:

| Case | `draw_typed` | `draw_view` | view extra for each draw | `set_copy` (K, once for each update) |
|---|---|---|---|---|
| AOT, 1000, tension 0 | 19.70-19.91 | 23.68-23.75 | +3.8-4.1 (19-20 %) | 2.18-2.21 |
| AOT, 1000, tension 0.4 | 50.60-51.65 | 54.77-55.63 | +3.2-4.2 (6-8 %) | 2.20-2.22 |
| AOT, 20000, tension 0 | 240.82-245.26 | 252.10-261.87 | +9.5-16.6 (4-7 %) | 42.67-43.55 |
| AOT, 20000, tension 0.4 | 1420.91-1455.53 | 1482.94-1521.95 | +27-71 (2-5 %) | 43.07-43.72 |
| wasm, 1000, tension 0 | 27.60-27.97 | 31.21-31.52 | +3.3-3.9 (12-14 %) | 3.55-3.60 |
| wasm, 1000, tension 0.4 | 93.91-95.97 | 110.58-111.63 | +15.7-16.7 (17-18 %) | 3.63-3.75 |
| wasm, 20000, tension 0 | 424.85-435.59 | 470.62-483.80 | +44-58 (10-14 %) | 94.08-96.82 |
| wasm, 20000, tension 0.4 | 2257.47-2269.19 | 2588.03-2688.28 | +320-431 (14-19 %) | 94.77-95.98 |

`set_typed` and `set_view` are below 0.01 µs.

Reading:
- V costs at each draw. K costs once at each update. K costs less than V from 3 to 5 draws for
  each update on AOT with tension 0, from 2 draws on AOT with tension 0.4 and on wasm with tension
  0, and from 1 draw on wasm with tension 0.4. An animation of the default 1000 ms draws about 60
  frames for each update. A hover draws with no update.
- Only the stress case "one update for each frame, tension 0" favors V: by 26-33 µs (AOT) and
  37-52 µs (wasm) for each frame of 20000 points.
- T against K: T saves `set_copy`, 43 µs (AOT) and 57-97 µs (wasm; S measured 57-67 µs) for each
  update of 20000 points. Both draw at the typed speed.
- The figures agree with the drafts: F E3.2 (wasm view +18.5 to +21.2 ns for each point at
  tension 0.4), P B1 (view +13-15 % of the wasm draw), S `line_view` (wasm view +116-129 µs at
  20000 points, tension 0, with the setter in each frame).

### 2.2 Question 7: the order of the exports

`<j>/lintprobe/`: a package with only the rule `directives_ordering` and two exports in the
source order of `index.js:5-6` (`controller.polarArea.dart`, then `controller.pie.dart`).
`dart analyze` gives `info - Sort directive sections alphabetically - directives_ordering`
(`<j>/lintprobe/analyze.out`). `very_good_analysis` 10.0.0 enables the rule. `melos run analyze`
runs with `--fatal-infos`. Thus the `controllers/index.dart` of F §7.3 and P §Q7.2 fails CI. The
order of S passes. `scales/index.dart` already uses the code unit order.

### 2.3 Question 5: rerun of the S probe

`probe_spacing.mjs` of S on the x64 Node.js v24.12.0 against the build at the pin. The output is
byte-identical to `probe_spacing.out` of S. The row `elements.arc spacingMode angular` gives
`[0, "proportional"]` after the update, and `["active", 0, "angular"]` after the hover. Thus the
hover options keep `'angular'`, because `setHoverStyle` does not run the hunk.

### 2.4 The implementers that the new members break

A scan of `packages/*/test`, `packages/*/tool` and `apps/*/lib` for classes that implement
`types.Element`, `types.PointElement`, `types.LineElement`, `types.Chart`, `types.ChartMeta`,
`types.DatasetController` or `types.Scale` without `noSuchMethod`:

| Class | File | New members that it needs |
|---|---|---|
| `_Point implements PointElement` | `test/specs/helpers.segment_test.dart:12` | `active`, `hidden`, `size` |
| `_Point implements PointElement` | `test/port/helpers/helpers.segment_test.dart:22` | the same |
| `_Point implements PointElement` | `test/port/helpers/helpers.extras_test.dart:82` | the same |
| `_Dataset implements Element` | `test/port/helpers/helpers.extras_test.dart:67` | `active`, `hidden` |
| `_Point implements PointElement` | `test/port/helpers/helpers.collection_test.dart:13` | `active`, `hidden`, `size` |
| `_Point implements PointElement` | `tool/bench/bench_flutter_test.dart:45` | the same |
| `_PointElement implements PointElement` | `tool/bench/src/cases_data.dart:70` | the same |
| `_Meta implements types.ChartMeta` | `test/port/core/core.datasetController_test.dart:425` | `total`, `dataset_` |
| `DemoChart implements types.Chart` | `apps/chartjs_gallery/lib/demo/demo_chart.dart:40` | the 5 `types.Chart` members |

F lists 2 of these 9 (`_Meta`, `DemoChart`), S lists 3, P lists 1. The ADR lists all 9.

## 3. Scores per question

Each cell scores the answer of a draft against the protocol: 1. the behavior that Chart.js ADR 0009
protects, 2. performance, 3. the upstream structure, 4. less code of our own. "Ev" is the
evidence.

### Question 1: the interface members

All three drafts choose interface members (Chart.js ADR 0003) and allow a cast only to a `types`
interface or to a class of the own library. All three move the cast of `updateElement` into DC
(`index.d.ts:674`). All three keep the 9 forms of Chart.js ADR 0025 §5 and the record of
`getPointPositionForValue`. The judge checked each first reader at the pin (`bar.js:8`, `:47`,
`:48`, `:396`, `:418`, `:437`, `:440`, `:549-550`, `:606`, `:615`, `:620`, `:676`;
`doughnut.js:97`, `:101`, `:126-127`, `:192`, `:195`, `:235`, `:313`, `:354`;
`polarArea.js:41`, `:45`, `:155`, `:167-169`, `:182`; `radar.js:88`, `:90-91`; `line.js:101`,
`:133`, `:140`) and the `index.d.ts` lines (`:374`, `:543`, `:559`, `:568-571`, `:656`, `:658`,
`:674`, `:688`, `:2025-2026`, `:2414-2418`, `:3676-3685`).

The drafts differ on the four line writes of `line.js:57-60` (also `controller.scatter.js:80-83`
and `controller.radar.js:60`):

| | F | P | S |
|---|---|---|---|
| Form | `meta.dataset as types.LineElement` in `update`, 4 setters on `types.LineElement` | by-name writes through `types.PropertyAccess`; the cast to `types.LineElement` only at the draw (`line.js:140`) | as F (`set points(List<Element>)`) |
| 1. Behavior | The cast throws a `TypeError` in `update` for a dataset element without the line API. Upstream throws at `meta.dataset.updateControlPoints` in `draw` (`line.js:140`), in an animation frame. No row records the earlier throw. | Keeps the upstream throw site. | as F |
| 2. Performance | 1.1 ns (AOT), 0.6 ns (wasm) for the 3 writes | 4.7-4.8 ns (AOT), 39.5-40.2 ns (wasm) for each update of a dataset (P B3, `misc_aot_*.out`, `wmisc_wasm_*.out`, read by the judge): below 0.1 µs | as F |
| 3. Structure | the writes look like the upstream lines | `line._chart = …` is an untyped property write upstream; the by-name write is its direct form | as F |
| 4. Code | 4 more interface members | 4 fewer members | as F |
| Ev | analyzer probe E1.1 (`ifaceprobe/analyze.out`: no error, one warning for the `@internal` `dataset_`); E1.2 `active` read | B3 (interface against cast with one class hierarchy: equal); B3 line writes | scans only |
| Score | 2nd | **1st** | 3rd |

P wins on priority 1. The precedent is the row `adapt-component-class-role`: each earlier throw
of a cast has a row, and that row accepts the cast because "both throw a `TypeError` in the same
`update()` call". The cast of F and S does not meet that condition. F has the best evidence (the
analyzer probe and the concrete line of each member). The ADR takes the P form and the F table.

### Question 2: the label of `getLabelAndValue`

All three choose `({Object? label, String value})`. All three probes at the pin agree: the
overrides of scatter, bubble, doughnut, pie, polarArea and radar return the raw label, and
`jsToString` changes the count of the title lines and adds the title `undefined` (radar past the
end) or `0`. `index.d.ts:641` declares `label: string`. The runtime does not follow it.

| | F | P | S |
|---|---|---|---|
| Ev | labels `[['line 1','line 2'], 5, 0, 'd', undefined]` with the tooltip title in both modes; rerun byte-identical | labels with `null` and `''`, `typeof value` | array, number, past the end |
| Code form | `_item` placeholder (the parsed-data panel) | `jsGet(labels, index)` | `jsGet(list, jsNumberToString(index))` |
| Score | **1st** (the only draft with the title table for each mode and the spec `plugin.tooltip.tests.js:918-920`) | 2nd | 2nd |

Chart.js ADR 0027 (proposed) makes each controller read `labels[i]` a `jsGetIndex`. The code forms
of P and S do not follow it. S keeps `getLabelAndValue` off `types.DatasetController` in phase 7:
its first reader through the interface is `plugin.tooltip.js:130` (phase 8). The ADR takes this.

### Question 3: `meta.data` and `line.points`

No spec reads the identity of `line.points` (the judge ran `grep` over `test/specs/*.js`: one
hit, `element.line.tests.js:11`, a line with no meta). The readers of `line.points` at the pin
(`element.line.js`, `helpers.segment.js`, the filler) read the items and the length.

| | F (V, cast view) | P (T, typed meta list) | S (K, copy in the setter) |
|---|---|---|---|
| 1. Behavior | same items, live view; identity differs | same items; identity kept; a non-point element in a point list throws at the insert | same items; identity differs; a copy at each write of a list that is not typed |
| 2. Performance (judge run, 20000 points) | +9.5-71 µs (AOT) and +44-431 µs (wasm) for each draw | 0 for each draw, 0 for each update; +4-12 ns for each inserted element at an insert before the end (P B3) | 0 for each draw; 43 µs (AOT) and 57-97 µs (wasm) for each update |
| 3. Structure | 1 `.cast` and a marker at 3 sites; no shared layer changes | changes the shared core layer: `ChartMeta.data` gets a setter (also on `types.ChartMeta`), `initialize` gets a port-only statement, `_insertElements` is rewritten without `_hole`, and DC imports `element.point.dart`, which `core.datasetController.js:1-5` does not import | the setter of the row `adapt-line-points-elements` gets the copy; `getStartAndCountOfVisiblePoints` takes `List<types.Element>` (its body reads only `length` and `lookupByKey`, which takes `List<Object?>`); the controller lines stay verbatim |
| 4. Code | 3 expressions | about 30 lines in 2 shared files and 1 interface member | 3 lines in the setter, 1 parameter type |
| Ev | E3.2 (copy measured with the slow `List.of(cast)`) | B1 (copy measured with the slow form), P3, B3 | `line_view`, `points_copy` (`generate` is the fastest copy) |
| Score | 3rd | 2nd | **1st** |

- V costs at each draw, 10-19 % of the line draw on wasm. Its draft gives no reason that outranks
  performance: the shared array that it keeps is not a protected behavior (F E3.1).
- T is a structure change in a shared layer. P calls it "the upstream structure"; the judge does
  not accept that claim (the import, the setter and the rewrite above). Chart.js ADR 0020 §13: such
  a form needs a gain in the frame figures, and a gain below 0.1 ms does not count. The gain of T
  over K is 43-97 µs for each update of 20000 points, below 0.1 ms. Thus T goes to Open with the
  frame figures of P §8.
- K keeps the structure. Thus the microbenchmarks are sufficient evidence (Chart.js ADR 0020 §13),
  and the judge run confirms its gain over V.

The F test "after a push and `buildOrUpdateElements` without an update, `line.points.length` is the
new length" pins an internal state that no upstream reader sees between `buildOrUpdateElements` and
the controller `update` (both run in one `chart.update()`). Only a user plugin hook `afterLayout`
can see it. The ADR does not take that assertion. It records the case in the row text.

### Question 4: `getDataVisibility`

All three choose the interface call (Chart.js ADR 0025 §4) and the port-only first statement
`if (_hiddenIndices.isEmpty) return true;`. An empty object gives `undefined` for each key, and
`!undefined` is true. Thus the result is the upstream result for each index. Three independent
benchmarks agree: the upstream body costs 15-19 ns (AOT) and 16-23 ns (wasm) for each call, the
early return 2.6-4.1 ns, and the early return costs nothing measurable with a hidden index. The
cast saves 0-1.8 ns (AOT) and 1.5-3.5 ns (wasm) and needs an import that upstream does not have.
The judge did not rerun these benchmarks: no figure separates the drafts.

| | F | P | S |
|---|---|---|---|
| Decision | IE | `empty_if` | IF; CF to Open |
| Ev | 4 processes, 3 live classes | 3 processes, a loop baseline (the early return costs 0.4-0.9 ns over the loop), 1000 and 20000 indices | 3 classes, 5 forms |
| Score | 2nd | **1st** (tie on the decision) | 2nd |

S Open 2 (CF, a cast to the concrete `Chart`) conflicts with the rule of question 1. The ADR does
not take it.

### Question 5: the #12238 hunk

All three port `polarArea.js:204-210` line by line, with no marker. All three show that polar area
has no option sharing (`polarArea.js:90-95`), that the write meets an object that is not frozen
(`core.datasetController.js:804-833`, the same as DC:1515-1561), and that a frozen object throws a
`TypeError` in both runtimes (Chart.js ADR 0021 §5).

| | F | P | S |
|---|---|---|---|
| Ev | 9 scope rows, three modes; Dart frozen-write probe | 66 configurations: the spec cases, all polar area fixtures, the doughnut spacing fixtures; one A/B difference | 8 rows with the hover state, colors plugin on and off; rerun byte-identical (section 2.3) |
| Code | `spacing is num && spacing == 0` (the `is num` test adds nothing: `'0' == 0` is false in Dart) | `== 0` | `== 0` |
| Score | 3rd | 2nd | **1st** |

S wins on the hover row: the hunk changes the resolved option after `update`, but the hover
options keep `'angular'`. That is a protected resolved option, and only S pins it.

### Question 6: the option functions

All three port the four functions now (`doughnut.js:95-128`, `polarArea.js:38-68`), add the
minimal `types.LegendElement` (`index.d.ts:2414-2418`) and `types.Chart.legend`
(`index.d.ts:543`), and find no tooltip callback in `src/controllers/` at the pin. The defaults
inventory lists the eight keys (`doc/upstream/manifest.json`: `doughnut`, `pie`, `polarArea` and
the base `plugins.legend.labels.generateLabels` and `plugins.legend.onClick`). Thus a placeholder
changes the inventory. `jsCall` tests the arity with `Object? Function(Never, …)`
(`js_function.dart:241-246`). A closure with typed parameters passes that test, and a dynamic call
with a wrong argument throws a `TypeError`, as the upstream property read of `undefined` does.

| | F | P | S |
|---|---|---|---|
| Form | typed closures in the Map literal | typed top-level private functions; their tear-offs are canonical, so each read gives the same object | `Object?` parameters and a cast at the entry |
| 4. Code | as P | least | one cast line for each function |
| Ev | `probe_legend_fns.out` (item keys in order, the `onClick` effect, the throw without a legend) | `jsGet` gives `undefined` for a Dart object (`js_object.dart:36-62`), thus by-name reads fail; the manifest keys | the precedent `core.scale.defaults.dart:50-52` |
| Score | 2nd | **1st** | 3rd |

### Question 7: the registration

All three: `controllers/index.dart` with 8 `export … show` lines, the `controllers` Map in code
unit order (Chart.js ADR 0020 §6), `registerables` unchanged.

| | F | P | S |
|---|---|---|---|
| Export order | source order of `index.js` | source order | code unit order (lint), the upstream order in the `///` doc |
| Lint | fails `directives_ordering` (section 2.2) | fails | passes |
| Score | 3rd | 2nd (it adds the effect on `flutter_test_config.dart`) | **1st** |

## 4. Flags

Claims without evidence, wrong claims, and answers that break a rule:

1. **P, question 3:** "This keeps the upstream structure: no new member". T adds a setter to
   `types.ChartMeta.data` and to the concrete `ChartMeta.data` (cc:298 is `final`), rewrites
   `_insertElements`, removes `_hole`, and adds an import of `element.point.dart` to DC. That is a
   structure change of a shared layer. Its gain over K is below 0.1 ms (section 2.1). Thus it
   needs frame figures (Chart.js ADR 0020 §13).
2. **F and P, question 3:** the copy column uses `List.of(data.cast())`, which S measures as 4 times
   slower on AOT and 6 times slower on wasm than `List.generate`. Thus "copy" in F E3.2 and P B1
   does not measure the best copy form.
3. **F, question 3:** the score keeps V although its own figures show +14-16 % of the wasm line
   draw. The protocol ranks performance above the structure. The shared array identity is not a
   protected behavior (F E3.1).
4. **F and S, question 1:** the cast `meta.dataset as types.LineElement` in `update` throws earlier
   than upstream (`line.js:140`, in `draw`) for a dataset element without the line API. Neither
   draft names a row. P avoids it.
5. **F, P and S, question 1:** the lists of the implementers to change are incomplete (section
   2.4). F E1.4 says that only `_Meta` lacks `noSuchMethod`; 6 fake point classes and `_Dataset`
   also lack it.
6. **F, E1.1:** "dart analyze gives no error". True, but the output has a warning
   (`invalid_use_of_internal_member` for `dataset_`). The concrete `ChartMeta.dataset_` is
   `@internal` (cc:332). The ADR decides whether `types.ChartMeta.dataset_` is `@internal` too.
7. **F and P, question 7:** the `controllers/index.dart` code form fails `analyze --fatal-infos`
   (section 2.2).
8. **P and S, question 2:** the code forms read `labels[index]` with `jsGet`. Chart.js ADR 0027
   (proposed) gives `jsGetIndex`.
9. **F, question 2:** cites `plugin.tooltip.tests.js:920`; the `typeof` line is `:919`. **S,
   question 1:** cites `index.d.ts:676` for `updateElement`; the line is `:674`.
10. **S, question 6:** `jsToNumber(undefined)` gives the key `'NaN'` where upstream gives
    `'undefined'`. S says that the visible result is the same. That is true for the data indices,
    but the key differs in `_hiddenIndices`. All three drafts have this form (the `double`
    parameter of `toggleDataVisibility`). The ADR records it with no marker: no protected behavior
    reads the key.
11. No draft breaks an accepted ADR. All three keep the forms of Chart.js ADR 0025 §4 and §5
    (accepted) and the record of Chart.js ADR 0003.

## 5. The decision for Chart.js ADR 0028

S is the base. The ADR states these decisions:

1. **Interface members.** The members of F §1.3 with their concrete lines, without the four
   setters of `types.LineElement`: `types.Scale` 9, `types.Chart` 5 (`isDatasetVisible`,
   `getVisibleDatasetCount`, `toggleDataVisibility`, `update([Object? mode])`, `legend`),
   `types.ChartMeta` 2 (`dataset_`, `abstract double? total` as a typed field with its by-name
   keys; P B3: 0.7 ns against 11-19 ns), `types.DatasetController` 4, `types.Element` 2 (`active`,
   `hidden`), `types.PointElement` 1 (`size`), `types.LineElement` 1 (`updateControlPoints`), and
   the new `types.RadialLinearScale` (5) and `types.LegendElement` (2). A controller casts only to
   a `types` interface or to a class of its own library (`meta.controller as DoughnutController`,
   `doughnut.js:193-195`). `updateElement` takes `types.Element` and casts in DC. The line writes
   of `line.js:57-60`, `controller.scatter.js:80-83` and `controller.radar.js:60` are by-name
   writes (P §Q1.4). The cast to `types.LineElement` is at the draw (`line.js:140`). The 9
   implementers of section 2.4 get the members.
2. **Label.** `({Object? label, String value})`. `labels[index]` is `jsGetIndex` (Chart.js ADR
   0027). Radar keeps `undefined` past the end. `getLabelAndValue` stays off
   `types.DatasetController` until phase 8.
3. **`line.points`.** Form K: `set points(List<types.Element>)` keeps a
   `List<types.PointElement>` and copies another list with `List<types.PointElement>.generate`.
   The by-name `points` write takes the same path. `getStartAndCountOfVisiblePoints` takes
   `List<types.Element>`. The row `adapt-line-points-elements` gets one sentence on the copy and the
   identity. Open: T, with the frame figures of P §8 (stress mode `chart`, `LineController`, 20000
   points, `CALL=update` and `CALL=draw`, Pixel 8a and Chrome dart2wasm).
4. **`getDataVisibility`.** The interface call and the port-only early return, with no marker
   (the precedent of Chart.js ADR 0025 §3). `performance.md` gets the figures.
5. **The hunk.** The literal port with `== 0` and `== 'angular'`. The tests pin the rows of S
   (also the hover row), the spec cases `controller.polarArea.tests.js:69`, `:85` and
   `controller.doughnut.tests.js:49`, the one A/B difference of P, and the `TypeError` of a subclass
   with `enableOptionSharing = true`.
6. **Option functions.** Typed top-level private functions (P): `List<Object?>
   _generateLabels(types.Chart chart)` and `void _onClick(Object? e, Object? legendItem,
   types.LegendElement legend)`. The reference test uses the items of F `probe_legend_fns.out`.
7. **Registration.** The exports of S in code unit order, the `controllers` Map in code unit
   order, `registerables` unchanged.
