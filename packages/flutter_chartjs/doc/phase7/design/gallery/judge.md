# Gallery chart types and the stress controller: judge

- Panel: "Gallery chart types and the stress controller" (the future Chart.js ADR 0031, proposed).
- Drafts: [draft-fidelity.md](draft-fidelity.md) (F), [draft-performance.md](draft-performance.md)
  (P), [draft-simplicity.md](draft-simplicity.md) (S).
- Pin: Chart.js `v4.5.1+7169e651`. Gallery tree at `4eda459`.
- Decision protocol, in priority order: 1. the behavior that Chart.js ADR 0009 protects; 2.
  performance; 3. the upstream structure; 4. less code of our own. A lower rank decides only when
  the higher ranks tie.
- Judge evidence folder (below: `$JG`):
  `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/gallery-judge/`.

## 0. Evidence of the judge

### 0.1 Upstream lines that the judge read at the pin

| Source | What it shows |
|---|---|
| `src/helpers/helpers.extras.ts:88-133` | `_getStartAndCountOfVisiblePoints` searches `_parsed` only for a user `min` or `max` (`minDefined`, `maxDefined`) of the index scale. Without user bounds, start is 0 and count is N. |
| `src/helpers/helpers.collection.ts:20-61` | `_lookup` is a binary search. The `last` compare is `ti < value \|\| ti === value && table[index + 1][key] === value`. |
| `src/core/core.datasetController.js:280-289` | `initialize` warns once when `options.fill` is set and the filler is not enabled. No throw. |
| `docs/charts/bar.md:45-54` | The docs chart blocks have `actions: []`. |
| `apps/chartjs_gallery/lib/demo/stress_chart_config.dart:77-91` | `StressPointField.step` clamps a position to exactly 0 or 1 at each bounce. |
| `packages/flutter_chartjs/lib/src/canvas/canvas_ui.dart:948-955` | `restore` flushes the circle batch. Thus a dataset clip moves the circle draw into `draw()` (P, G6). |
| `packages/flutter_chartjs/lib/src/platform/platform.flutter.dart:560-605` | With an unbounded height and a truthy aspect ratio, the bounded width and the ratio give the height (Chart.js ADR 0014). F's page sizing works. |
| `packages/flutter_chartjs/lib/src/core/core.datasetController.dart:784` | The port prints the fill warning (S's claim holds). |
| `apps/chartjs_gallery/lib/demo/core_demo.dart:350, :366, :432` | The Core tab uses `ChoiceChip`, `SliderControl` and `ToggleChips` today, below the chart. |
| `packages/flutter_chartjs/doc/performance.md` §6 | The define `SHARING` and the acceptance "mode `chart` (a) against `elements` with `LINE=0`" of Chart.js ADR 0021 §8. |

### 0.2 Re-runs and a new probe

| Id | Command | Output | Result |
|---|---|---|---|
| J1 | S's `p1_stress_configs.mjs <dist> count` (x64 Node.js v24.12.0, Rosetta) | `$JG/p1_count.rerun.out` | The trap lines equal S's `p1_trap.out`: user `min`/`max` on x with `parsing: false` and unsorted data draws 3 of 6 points; `suggestedMin`/`suggestedMax` on x (`lineMixed`, `scatterMixed`) draws 6 of 6, x range `[0, 1]`. |
| J2 | `$JG/judge_form.mjs <dist>` (x64 Node.js) | `$JG/judge_form.out` | 5000 points, 600 frames with bounces, `update('none')` each frame. See the table below. |
| J3 | P's `probe_chart_mode2_test.dart --plain-name bench`, `ROUND=9` (JIT) | `$JG/probe_chart_mode2_jit.rerun.txt` | Same ranks as P's G3: at 20000 points with sharing, update `frac` 0.94, `eps` 1.59, `parsed` 6.99 ms; the draw after a `parsed` update 4.80 ms against 3.93 ms. Without sharing: `eps` 3.58, `parsed` 8.34, `epsOverflow` 8.38 ms. |

J2 (line; the scatter rows give the same values):

| Form | Chart area | Dataset clip | x range | Points not drawn (worst frame) | Largest pixel error against the fraction path |
|---|---|---|---|---:|---:|
| Judge: x `suggestedMin`/`suggestedMax`, y `min`/`max`, `parsing: false`, `autoPadding: false`, `clip: false`, `ticks.display: false` | 0, 0, 800, 480 | disabled | 0, 1 | 0 | 5.7e-14 |
| P: x `max: 1 + 2^-20` | 0, 0, 800, 480 | disabled | 0, 1.00000095 | 0 | 7.6e-4 |
| S: suggested x, bounds y, default padding and clip | 5, 5, 795, 475 | left and right 5 | 0, 1 | 0 | 5.7e-14 |
| F: bounds on x and y, `parsing` on | 5, 5, 795, 475 | 0 on each side | 0, 1 | 0 | 5.7e-14 |
| Trap: bounds on x and y, `parsing: false` | 0, 0, 800, 480 | disabled | 0, 1 | 5000 (line), 2500 (scatter) | — |

The judge left no `flutter_tester` process. One `flutter_tester` of another session ran before J3
and was not touched.

## 1. Question 1: each chart type renders

| Draft | 1 Behavior | 2 Performance | 3 Structure | 4 Own code | Evidence | Rank |
|---|---|---|---|---|---|---|
| F | The docs blocks unchanged. Area at `fill: false`: the same pixels as upstream with the filler, but not an area chart. | Not at stake (at most 8 elements). | Best: one file for each docs file with a rule-2 header; the upstream `maintainAspectRatio` (2, or 1 for doughnut, pie, polarArea and radar) through the unbounded height (checked, §0.1). | Most for a static page: a port of `docs/scripts/utils.js` (about 120 lines) and the Area actions. | E6 (`docs.out`), E9. | 2 |
| P | The docs blocks plus sample actions. The Area `fill` control changes nothing in phase 7 (S's P2: `area.origin` and `area.false` give the same canvas calls). | The update path for each tap: not at stake on small charts. | Mixes `docs/charts` blocks with `docs/samples` actions that the blocks do not have (`actions: []`). | Most: `SampleChoice`, `SampleAction`, `SegmentActions`, actions and choices for 9 pages. | U1 only; no probe of the pages. | 3 |
| S | The docs blocks unchanged. Area at `fill: 'origin'`: upstream without the filler draws the line and warns once for each dataset (checked, §0.1). Phase 8 fills it with no gallery change. | Not at stake. | Docs blocks as variants. A fixed `maintainAspectRatio: false` and a clamp height replace the upstream aspect. | Least: one page, 13 config functions, fixed Area numbers. | P2 (`p2_none.out`, `p2_all.out`), P4. | **1** |

Winner: **S**. Ranks 1 and 2 tie. F has the best structure, but S keeps the docs structure for the
configs with less code, and its Area shows the area config that phase 8 completes. Take from F
the page sizing (no `maintainAspectRatio` override: the docs aspect through the unbounded host
height) and the rule-2 headers of the config files. Take from P the hover readout through a
`ValueNotifier` and `getLabelAndValue` of the active elements: it shows the text of the phase 8
tooltip and runs a member that phase 7 ports.

Keys: `gallery.type.<stem>` with the stem of the docs file (`area`, `bar`, `bubble`, `doughnut`,
`line`, `mixed`, `polar`, `radar`, `scatter`), `type.<stem>.variant.<variant>`,
`type.<stem>.host`, `type.<stem>.readout`. List mark: S's form (an icon and the note of a partial
type; Area is partial until phase 8).

## 2. Question 2: the replacement of `StressPointController`

All three drafts delete the class (Chart.js ADR 0021 §8), move `registerGalleryComponents` to a new
file, and reject user `min`/`max` on x with `parsing: false` (J1, J2 trap row). They differ in the
config of the modes `chart` and `axes`.

| Draft | 1 Behavior | 2 Performance | 3 Structure | 4 Own code | Evidence | Rank |
|---|---|---|---|---|---|---|
| F (P2: `parsing` on, bounds on x and y) | All points drawn (J2). The only form inside `data-structures.md:74`. | Worst. Dart: the parse costs 4.4 times the `eps` update at 20000 points and moves garbage collection into the next draw (J3). F gives only Node figures (+0.93 ms), which understate the Dart cost. | Upstream config. Adds a parse that the before scene does not have, a 5 px inset and a dataset clip: the before figures do not compare. | Small. Removes the define `SHARING`. | E1-E4 (Node). | 3 |
| P (option 5: `parsing: false`, x `max: 1 + 2^-20`, `autoPadding: false`, `clip: false`, `ticks.display: false`) | All points drawn (G2, J2). Pixel offset up to 7.6e-4 px (J2): not a protected item. | Best: the draw equals phase 5; the update adds 0.14-0.6 ms (G3, J3). | Upstream options only. The chart area and the draw split equal phase 5 and phase 6 (G1, G6, J2): the before figures and the ADR 0021 §8 acceptance stay comparable. | Config, plus a constant `stressUnitMaxX` and an optional bridge patch for the A/A'/B protocol. | G1-G7 (Dart JIT and wasm), G8 (Node); J3 confirms G3. | **1** |
| S (E: `parsing: false`, x suggested, y bounds) | All points drawn, exact pixels (J1, J2). | Near P on the update. The default clip moves the circle flush into `draw()`: `drawMs` +24 % at 20000 points (G6, mechanism checked in `canvas_ui.dart:948-955`). | Upstream config. Chart area 790 x 470: the after `drawMs` and the ADR 0021 §8 acceptance do not compare. | Least: config only, keeps `SHARING`. | P1 (Node only; no Dart probe). | 2 |

Winner: **P**, with S's x bounds. The combined form (J2, first row) gives exact pixels, the
phase 5 chart area, no clip and all points:

- Modes `chart` (`SHARING=1` gives `type: 'line'`, `showLine: false`; `SHARING=0` gives
  `type: 'scatter'`) and the bench cases `chart.a`, `chart.b`, `chart.c`: `parsing: false`,
  `layout.autoPadding: false`, dataset `clip: false`, x `{type: 'linear', display: false,
  ticks: {display: false}, suggestedMin: 0, suggestedMax: 1}`, y the same with `min: 0, max: 1`.
- Mode `axes`: P's form (`type: 'line'`, `showLine: false`, `parsing: false`,
  `autoPadding: false`, `clip: false`). The phase 6 chart area and draw split stay (G6; F's E8
  shows the 5 px change of the category area without them).
- Core and Axes tabs: S's form. `type: 'line'` with the line shown (the default), default
  `parsing` (their data is sorted). These tabs are demos, not figure sources.
- Step 7: P's three sides (A `0e0ab93`, A' `0e0ab93` with the hidden scales, B the phase 7 tree)
  and the new timing part `elements` (F and P).

## 3. Question 3: stress cases of the other controllers

| Draft | 1 Behavior | 2 Performance (use for step 7) | 3 Structure | 4 Own code | Evidence | Rank |
|---|---|---|---|---|---|---|
| F (`TYPE` in mode `chart`, 8 types with pie, default parsing, hidden bounded scales, one color) | Correct ranges: each radial scale has `min`/`max`. | Measures the parse of each controller, which Chart.js ADR 0027 (parsed data) changes in phase 7; the part `elements` shows it apart. One color keeps the per-element resolve out (E5b: doughnut 1000, 12.5 ms with the docs colors, 1.0 ms with one); `SCRIPTABLE=1` gives that path. The bar x axis hides its ticks (E5b: 24.0 against 9.4 ms at 5000). | User data shapes of each type. | One scene class, per-type counts, `SHOWLINE`. Removes `SHARING`. | E5b, E5c (Node). | **1** |
| P (`TYPE`, 7 types, `parsing: false` internal format) | Finds that radar with `parsing: false` needs `min`/`max` on `r`, else the range is wrong (G8). | Skips the parse that phase 7 ports. The doughnut case uses the indexable 5 colors: the resolver cost hides the controller cost (F's E5b). | Follows `docs/general/performance.md`. | More data code for each type. Keeps `SHARING=0` as an alias. | G7, G8. | 2 |
| S (new mode `type`, docs shapes, default visible scales) | Correct. | The label work of the scales dominates (P3: radar 5020 `measureText` calls at 5000, bar and line 2500). The mode `axes` measures that work already (`performance.md` §11.6). One global `N`. | Docs data shapes. | One enum, one scene, one mode. | P3 (Node). | 3 |

Winner: **F**. Take from P: `min`/`max` on `r` for radar and polar area (G8), the timing plugin in
every chart mode and bench case (G7: no measurable cost), `SHARING=0` kept as the alias of
`TYPE=scatter` (the before command lines stay valid), and `ChartBenchCase.counts`. Take from S:
the type cases come last in `chartBenchCases`, so a default run times the before cases first.

## 4. Question 4: `types.Chart` and the analyzer

| Draft | 1 | 2 | 3 | 4 | Evidence | Rank |
|---|---|---|---|---|---|---|
| F | Explicit members in `DemoChart`, added in the same unit as the interface member. | = | = | = | `demo_chart.dart:40` | 1 (tie) |
| P | Same. Lists the empty results. | = | = | = | `members-radial.md` §2.5 | 1 (tie) |
| S | Same. Gives the code of each stub. | = | = | = | `pubspec.yaml:12`, `:27-29` | 1 (tie) |

Tie. The member list comes from the interfaces-values panel, not from this panel. The workspace
`analyze` gate covers `apps/chartjs_gallery`. Each port-wave prompt names
`apps/chartjs_gallery/lib/demo/demo_chart.dart` (F).

## 5. Question 5: the layout rule

| Draft | Rule kept | Evidence and gaps | Rank |
|---|---|---|---|
| F | Type pages: at most one line above the chart. Stress: a `type` line of icons. Core: all controls above the chart as segment lines (the rule order). Axes: open item for the maintainer. | In-view tests at 412 x 915 and 360 x 640. The fit of 5 Core lines at 360 x 640 is arithmetic only. | 2 |
| P | At most four lines above the chart on every page that phase 7 touches. Core and Axes: other parameters after the readout. | Tests at 360 x 640 that also assert no `ChoiceChip`, `FilterChip`, `PopupMenuButton`, `DropdownButton` or horizontal `Scrollable`, and full-width segments. "After the readout" departs from the rule order. | **1** |
| S | New pages only. Core and Axes keep their chips and sliders. | The Core tab keeps `ChoiceChip`, `SliderControl` and `ToggleChips` (§0.1): "each parameter is a full-width SegmentedButton" fails on a page that phase 7 changes. | 3 |

Winner: **P**, with F's Core order (controls above the chart) and F's two test sizes. The Axes tab
keeps P's split (`x`, `y` and `N` above the chart, the rest after the readout), as an open item
for the maintainer: its parameters do not fit above an in-view chart. Use P's
`SegmentChoiceItem.icon` (the form of `SegmentToggleItem`), not F's `iconOf`. `SegmentActions` is
not needed: the type pages have no actions (question 1).

## 6. Flags

Claims without evidence:
- F §3.3: "a doughnut case at 20000 holds the UI thread for many seconds". No figure. E5c gives
  1.68 ms update and 10.1 ms draw at 5000 in Node. The counts stand on the counts of the mode
  `arcs` alone.
- F §2.3: the cost of P2 rests on Node figures. The Dart cost is 4.4 times larger at 20000 (J3).
- F §5: the fit of five Core lines at 360 x 640 dp has no test result.
- P §6: Baseline C (the same configs in Chart.js in Chrome on the Pixel 8a) has no harness and no
  figure. It is a plan.
- S §5: "the Axes tab has about 24 controls"; F counts 15 parameters. No count is shown.
- S §2.1 and §3.2: Node figures only; S ran no Dart probe.

Answers that break a rule or a protected behavior:
- No chosen form breaks a behavior of Chart.js ADR 0009, and each draft rejects the trap form.
  No draft changes an ADR. Each follows Chart.js ADR 0021 §8 (delete the class).
- S §1.4: the config file has the marker "Original code, not ported from Chart.js", but it holds
  copies of `docs/charts/*.md` blocks. AGENTS.md rule 2 gives the marker only to a file with no
  upstream source. Use F's rule-2 headers.
- S §5: the deferral of the Core restyle keeps chips on a page that phase 7 changes (user rule of
  2026-10-21).
- P §8: "after the readout" departs from the order of the user rule (controls, chart, readouts).
  Keep it only for the Axes tab, as an open item.
- P §4: the Area `fill` control has no effect until phase 8.
- F §3.3: the removal of `SHARING` breaks the before command lines of `performance.md` §6.

## 7. Overall winner and parts to take

**Overall winner: P (performance)**. It wins the questions that decide comparability (2) and the
layout rule (5), and it has the strongest evidence (Dart JIT and wasm probes, confirmed by J3).

Parts to take into the synthesis:
1. S, question 1: the docs blocks as variants of one `ChartTypePage`, no actions, Area as
   `line-boundaries.md` with `fill: 'origin'` and fixed numbers, the static note and icon of the
   list mark, keys from the docs stems.
2. F, question 1: no `maintainAspectRatio` override (the docs aspect through the unbounded host
   height), and rule-2 headers on the copied docs configs.
3. P, question 1: the hover readout with `getLabelAndValue` through a `ValueNotifier`.
4. S, question 2: x `suggestedMin: 0, suggestedMax: 1` in place of `max: 1 + 2^-20` (J2: exact
   pixels, all points); the Core and Axes tabs as line charts with the line shown.
5. F, question 3: `TYPE` in the mode `chart` with the 8 types, default parsing, one color,
   hidden bar ticks, per-type counts and `SHOWLINE`.
6. P, question 3: `r` bounds (G8), the timing plugin with the part `elements` in every chart mode,
   `SHARING=0` as an alias; S: the type cases last in the bench list.
7. F, question 5: the Core controls above the chart and the in-view tests at 412 x 915 and
   360 x 640 dp.
8. Open items for the maintainer: the Axes tab split (question 5), and the phase 8 opt-out of the
   plugins in the stress configs (F §8, S §2.3).
