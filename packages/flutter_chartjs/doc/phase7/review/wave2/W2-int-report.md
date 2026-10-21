# Wave 2, unit W2-int (integration): report

## Status

Done. All gates are green. The lift check of wave 1 is green.

- `lib/src/controllers/index.dart` exports `BubbleController`, `DoughnutController`,
  `LineController`, `PolarAreaController` and `RadarController`. The namespace `controllers` of
  `lib/src/index.dart` has them. Thus `flutter_test_config.dart` registers the six controllers of
  waves 1 and 2 with the built-in components.
- The ten temporary `Chart.register` lines of the five controller units are gone.
- The shared docs have the doc notes of U-line, U-bubble, U-doughnut, U-polarArea, U-radar, L1
  and A1, also the notes of their fixes.
- W2-int fixed five shared defects that the units recorded, and one more defect of the same kind.
  Each fix has a probe on the pinned build and a pin test (section "Cross-file fixes").
- No test changed its result when the five controllers became built-in components.

All paths are relative to `packages/flutter_chartjs/`, except where a path starts with `apps/`,
`AGENTS.md` or `REUSE.toml`. `<w2>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/W2-int`.
The logs are in `<w2>/` and the probes in `<w2>/probes/`.

## Registration

| File | Change |
|---|---|
| `lib/src/controllers/index.dart` | The lines `index.js:2-5` and `:7`, and five `export ... show` directives in code unit order (IV §5.1). The library doc names `PieController` and `ScatterController` (`:6`, `:8`) for wave 3. |
| `lib/src/index.dart` | Five imports. The `controllers` Map has `BarController`, `BubbleController`, `DoughnutController`, `LineController`, `PolarAreaController` and `RadarController` (IV §5.2). The `///` text names wave 2. `registerables` does not change. |
| `test/port/index_test.dart` | IV §7.4 for 6 controllers: the keys of `controllers` in code unit order, each value `same` its `jsClass`, the Map unmodifiable. After `Registry()..add(registerables)`, the keys of `registry.controllers.items`, `defaults.datasets` and `Chart.overrides` are `bar, bubble, doughnut, line, polarArea, radar`. `registry.controllers.items['doughnut']` is `DoughnutController.jsClass` (`controller.doughnut.tests.js:4-7`). |
| the 5 spec files and the 5 port test files of the units | The line `Chart.register([<Name>Controller.jsClass]);` is gone. The file comment says that `flutter_test_config.dart` registers the controller (the spec files name `index.umd.ts:28`). The imports that served only that line are gone. The polar area subclass `polarAreaSharing` keeps its `setUp` and `tearDown`. |

The id check of IV §5.3 found no test or gallery controller with the id of a built-in controller.

## Cross-file fixes

L1 recorded no `lib/` defect (L1 report: "No lifted case failed"). The controller units recorded
these defects in shared files. W2-int fixed each one with a probe.

### F1. `_insertElements` keeps no old parsed item (U-bubble R1, open item 6)

- Defect: `core.datasetController.dart` `_insertElements` put `undefined` at each new index. The
  upstream `move` (`core.datasetController.js:1000-1005`) keeps the old parsed item at each new
  index below the old length. The bubble parse reads it through the context of an option.
- Fix: `move` fills the new indexes with the old items below the old length and with the filler
  at or past it.
- Probe: the generated pin case `parsed: an insert below the old length reads the old parsed item`
  of `controller.bubble_test.dart`. With the old `core.datasetController.dart` (from `HEAD`), the
  case fails (`<w2>/probe_dc_before.out`). With the fix, it passes. The `_staleParsed`
  placeholder is gone.

### F2. The JS `+` of string point options (U-bubble open item 1)

- Defect: `PointElement.inRange`, `_inRange` (`inXRange`, `inYRange`) and `getRange` applied
  `ToNumber` to `radius` and `hitRadius` before the `+`. Upstream joins a string
  (`element.point.ts:15`, `:65`, `:105`). The hit element differs.
- Fix: `jsAdd` of the two options, then `ToNumber` for the compare. `getRange` gives the `jsAdd`
  result. `types.VisualElementRange.getRange` now gives an `Object` (a `double` or a `String`).
  `core.interaction.dart` `_binarySearch` applies `ToNumber` in `value - range` and `jsAdd` in
  `value + range`, as upstream (`core.interaction.js:54-57`).
- Probes: `<w2>/probes/point_radius.mjs` (`point_radius.out`): 6 option sets, `getRange` and the
  hits at 7 distances. `<w2>/probes/line_range.mjs` and `line_range_test.dart` (`line_range.out`,
  `line_range_dart.out`): a line chart with `pointRadius: '07'`, mode `point` with
  `intersect: true` at 7 positions. The Dart items equal the upstream items, and `getRange` gives
  `'071'` on both sides.
- Pin tests: `test/port/elements/element.point_test.dart`, group
  `string options join in the JS +` (both option forms).

### F3. `PointElement.size` with a string `borderWidth` (found by W2-int)

- Defect: `size` applied `ToNumber` to `borderWidth` before the `+`. Upstream keeps the raw value
  of `radius && options.borderWidth || 0` and joins (`element.point.ts:84-86`): radius 3 and
  `borderWidth: '1'` give 62 upstream and 8 in the port. `size` reaches the draw margin and the
  `getMaxOverflow` of the line and bubble controllers.
- Fix: `jsToNumber(jsAdd(radius, borderWidth)) * 2` with the raw `borderWidth`.
- Probe: `<w2>/probes/point_size.mjs` (`point_size.out`). Pin tests: the same group of
  `element.point_test.dart` (6 option sets).

### F4. The JS `+` of string arc options (U-doughnut open item 3)

- Defect: `ArcElement.getCenterPoint` applied `ToNumber` to `spacing` and `offset`
  (`element.arc.ts:459`), and `inRange` to `spacing` and `borderWidth` (`rAdjust`, `:439`).
  Upstream joins a string. The center is the point of the `nearest` and `index` modes, and
  `inRange` gives the hit element.
- Fix: `jsAdd` at both sites, then `ToNumber`.
- Probes: `<w2>/probes/arc_center.mjs` (`arc_center.out`, 7 option sets) and
  `<w2>/probes/arc_inrange.mjs` (`arc_inrange.out`, 4 option sets, 8 distances). Pin tests:
  `test/port/elements/element.arc_test.dart`, the two groups `string options join in the JS +`.

### F5. The draw with no chart area (U-line R1, open item 1)

- Defect: `LineController.draw` threw a `TypeError` at `chart.chartArea!` for each chart whose
  plugin cancels the first layout. Upstream throws only when the line caps its control points.
- Fix: `ChartArea?` in `types.LineElement.updateControlPoints`, `LineElement.updateControlPoints`,
  `updateBezierControlPoints` and `_capBezierPoints` (`area!.left` at the first cap,
  `helpers.curve.ts:173`, `:177`), and in `_LineSpy` of `test/support/jasmine.dart`.
  `controller.line.dart` passes `chart.chartArea`. The doc of `draw` is new.
  `controller_chart_harness_test.dart` lost an unnecessary `!`.
- Probe: the 4 skipped cases of `controller.line_test.dart` > `a plugin cancels the first layout`
  (expected values from the U-line fixer probe `probe_no_area.out`). They pass now, and their
  `skip` is gone. The case `tension 0.4: the draw throws a TypeError` still passes.
- Pin tests: also `test/port/helpers/helpers.curve_test.dart`, group
  `_updateBezierControlPoints without an area` (3 pure tests).

### F6. The `ToNumber` of the `arc` and curve arguments (U-bubble open item 2, U-radar open item 1)

- Defect: `dartArgs` of `tool/reference/scale_chart_common.mjs` recorded the raw arguments of
  `arc`, `bezierCurveTo` and `quadraticCurveTo`. A browser applies the WebIDL `ToNumber`, and the
  Dart canvas takes a `double`. The radar generator had a local patch.
- Fix: `bezierCurveTo` and `quadraticCurveTo` are in `NUMBER_METHODS`, and `arc` applies `Number`
  to its first five arguments. The local patch of `controller_radar_reference.mjs` is gone (its
  header names the shared conversion).
- Probe: all 14 generators that use the file ran two times (`<w2>/regen.sh`, logs `regen1.log`,
  `regen2.log`). The 8 phase 6 files and the bar, line, doughnut, polar area and radar files keep
  their SHA-256 (`<w2>/sha_before.txt`, `sha_after1.txt`). Only `controller_bubble_reference.dart`
  changes: SHA-256 `28002027b21356da4be45e39dd5b51fb242cb51333126ae974cbed9ff690d141`, the same in
  both runs (`sha_after2.txt`). The 4 bubble placeholders `_stringRadius` and `_arcArguments`
  pass now. `controller.bubble_test.dart` has no placeholder and no `_blocked` Map.

## Gates

| Command | Result |
|---|---|
| `dart run melos run format:check` | 399 files, 0 changed |
| `dart run melos run analyze` | No issues found (covers `apps/chartjs_gallery`) |
| `dart run melos run test --no-select` | All passed: chartjs_gallery +95; chartjs_test_utils +139; flutter_chartjs +6016 ~425; flutter_d3_port +38 |
| `dart run melos run test:web` | All passed: flutter_chartjs +7050 ~98; chartjs_test_utils +98 |
| `dart run melos run test:cases` | passed, 43 files, 0 errors, 0 warnings. Total 1036 cases: 572 passed, 0 failed, 362 skipped, 102 missing (the 11 upstream spec files without Dart tests). Wave 1 gave 434, 0, 415 and 187 in 38 files |
| `dart run melos run check:port` | lib-imports 322 files, headers 359, js-semantics 128, port:next 202, parity 163: all passed, 0 errors, 0 warnings |
| `dart run melos run parity` | wrote `doc/parity.md`; 0 errors, 0 warnings |
| `uvx --from 'reuse[charset-normalizer]' reuse lint` | compliant, 857 / 857 files with copyright and license information (with this report) |
| `flutter test` in `apps/chartjs_gallery` | +95, all passed |
| `dart analyze --fatal-infos` in `apps/chartjs_gallery` | No issues found |
| `dart run melos run gallery:build:web` | built `build/web` |
| `dart run melos run gallery:build:android` | built `app-debug.apk` |

The gates ran again after the last code change (F3). The table gives the last results.

The controller spec files in `test:cases`:

| Spec | Cases | Passed | Skipped | Missing |
|---|---|---|---|---|
| `controller.bar.tests.js` | 55 | 51 | 4 (3 `blocked: controller.line`, 1 `blocked: plugin.tooltip`) | 0 |
| `controller.bubble.tests.js` | 11 | 10 | 1 (`blocked: plugin.tooltip`) | 0 |
| `controller.doughnut.tests.js` | 13 | 11 | 2 (`blocked: controller.pie`, `blocked: plugin.tooltip`) | 0 |
| `controller.line.tests.js` | 34 | 33 | 1 (`blocked: plugin.tooltip`) | 0 |
| `controller.polarArea.tests.js` | 14 | 13 | 1 (`blocked: plugin.tooltip`) | 0 |
| `controller.radar.tests.js` | 13 | 11 | 2 (`blocked: plugin.filler`, `blocked: plugin.tooltip`) | 0 |

No `flutter_tester` process of W2-int is left. The process 67820 belongs to another session
(scratchpad `ec6419b7-...`). W2-int did not start it and did not stop it.

## Lift check

Command (from `packages/flutter_chartjs`):

```
flutter test --reporter json test/specs test/port > <w2>/run_final2.json
python3 -I doc/phase7/tools/lift_check.py doc/phase7/classification/all.json <w2>/run_final2.json 1 --list
```

- Wave 1: exit code 0. Counts of `all.json`: `phase7` 503, legend 21, tooltip 11, filler 1 (as
  `summary.md` §2 with D1). 122 records of wave 1 and earlier: 122 pass, 0 fail, 0 count
  differences. The lift list of wave 1 has 0 records (`<w2>/lift1_final2.txt`).
- Wave 2 (for information, the input of L2): exit code 1, as expected before L2. 508 records:
  215 pass, 293 fail (`<w2>/lift2_final2.txt`). The 5 controller spec files of wave 2 have 0
  failures. The 293 records skip as `blocked: controller.*`. They are the row of L2 in work plan
  §3: `core.controller` 30, `core.datasetController` 38, `core.interaction` 43, `core.scale` 26,
  `core.ticks` 2, `element.line` 1, `platform.dom` 2, `scale.category` 11, `scale.linear` 11,
  `scale.logarithmic` 37, `scale.radialLinear` 18, `scale.time` 14, the 3 placeholders of
  `controller.bar_test.dart` and the 57 twins of `test/port/scales/scale.time_test.dart`.

## Doc notes that W2-int applied

| Doc | Change |
|---|---|
| `AGENTS.md` | Layout: the `lib/src/controllers/` item with a sub-item for each of the six controllers and the cast rule; `index.dart` and the namespace text of wave 2; `core.animator.dart` members (A1); `_insertElements`; `getRange` gives an `Object`, the `jsAdd` of point and arc options, `updateControlPoints(ChartArea?)`; the `test/port/controllers/` file pattern. Tests: the test-only subclass registration; the `BasicPlatform` patch of the doughnut and polar area generators; the six controller generators; the `ToNumber` of `dartArgs`. |
| `doc/porting-flow.md` | §2.21: the casts that stay. §3: the subclass registration, the `ToNumber` of `dartArgs`, the `BasicPlatform` patch, the doughnut axis ids, the hit ties of symmetric arcs. §5: the result of wave 2 in the phase 7 row. |
| `doc/performance.md` | §13.1: the 3-read form of the line loop. §13.3 (new heading): the `refresh` field of A1 (ADR 0029 Evidence E6). §13.4: the sizes of the wave 2 data files. §13.7: item 6 (the 2-read form, ADR 0027 Open 4) and item 7 (the wave 2 forms of the step 7 list). |
| `doc/differences.md` | `harness-method-fields`: `Animator.refresh`, `core.animator.js:38-52, 171`, the reason, the pin group, the re-check. `platform-animation-promise-checkpoint`: `Animator._refreshMethod`. `platform-animator-skip-muted`: `Animator.update`. `adapt-typed-element-options`: the bubble hunk in the present tense and the bubble tests. `adapt-line-points-elements`: the pin groups of the line and radar tests. No new row, no new marker. |
| `doc/status.yaml` | New rows: the 5 controllers, the 5 controller specs and 15 port-only rows. New text: `core.animator.js`, `core.datasetController.js`, `core.interaction.js`, `element.arc.ts`, `element.line.js`, `element.point.ts`, `helpers.curve.ts`, `index.d.ts`, `controllers/index.js`, `index.ts`, the 8 spec rows of L1, and the port-only rows of `scale_chart_common.mjs`, `controller_chart_common.mjs`, `element.point_test.dart`, `element.arc_test.dart`, `helpers.curve_test.dart`, `core.animator_test.dart` and `index_test.dart`. The text of `core.interaction.tests.js` keeps `blocked: controller.bar` until L2 (L1 O1). |
| `doc/parity.md` | Written by tool 6. |
| `doc/upstream-ledger.md` | `ab79c3bf` (#12238): the doughnut and polar area parts (IV §8.6). `714b48cd` (#12328): ported, still `absorbed`, the fixture waits for F-int. `cb02e1d2` (#12155): `controller.line` is ported, the fixture waits for the runner. |
| `doc/canvas-cuts-plan.md` | A dated entry for wave 2 (work plan §0, deferred plans): `element.arc.dart` and `element.arc_test.dart` changed, no trigger, the current lines of the cited harness rows, the two `helpers.dom` cases of §3.6 that pass since L1. |

## Open items for the phase lead

1. **Decision D6 and the line loop.** The U-line fixer removed the cross-pass local `prevIValue`
   (U-line R2): a scriptable option can write `ctx.parsed` between two passes, and ADR 0027 §8
   then forbids the local. `updateElements` keeps `vValue` and `iValue` in a pass (the 3-read
   form). D6 says that the one-read rule lands. The phase lead decides ADR 0027 Open 4: a 2-read
   form only on the paths without user code needs a microbenchmark (performance.md §13.7 item 6).
   The scatter loop has the same item.
2. **The reset position of a new radar or polar area point (U-radar F2).** `xCenter` and
   `yCenter` of `RadialLinearScale` start at NaN, where upstream has `undefined`. The animation
   then starts at NaN. Not fixed: the fix changes `types.RadialLinearScale` and the phase 6 scale,
   or adds a `DIVERGES` row. The reviewer's probes are in
   `<scratchpad>/wave2/U-radar-review/xcenter_probe.mjs` and `xcenter_probe_test.dart`.
3. **The legend `onClick` index (U-doughnut R1, U-polarArea F1).** Both controllers give
   `_legendIndex(index)` to `toggleDataVisibility`. Chart.js ADR 0028 §6 (proposed) still gives
   `jsToNumber(index)` and "no reader sees the difference". A residual stays: after a data insert
   or remove, `moveNumericKeys` moves a key such as `''` or `'01'`, and the port has the key
   `'NaN'`. The exact form needs a key parameter in `types.Chart.toggleDataVisibility`. The phase
   lead decides a new ADR text, the key parameter, or a `differences.md` row (with a marker).
4. **String `data` (U-doughnut R4).** The cast in `_dataCheck` of `core.datasetController.dart`
   throws a `TypeError` for a string `data`. Upstream parses the characters
   (`core.datasetController.js:386`). A fix or a `differences.md` row is a decision.
5. **The axis ids of a doughnut meta (U-doughnut open item 2).** The doughnut test file maps an
   expected `null` of `xAxisID` and `yAxisID` to `undefined`. U-pie needs the same map, or the
   rule moves into `controller_chart_harness.dart`.
6. **The angle of a radar point (U-radar open item 3).** The observations of ADR 0030 §4 have no
   `angle`. The radar test file reads it with the probe `pointAngles`. The shared harness can add
   it later.
7. **IV §7.1.** `test/port/types/index_test.dart` still reads `types.RadialLinearScale` on a chart
   of the `RadialTestController`. IV §7.1 says a polar area chart after the polar area wave. The
   file is not in the row of W2-int.
8. **`controller.doughnut.tests.js:4`.** The case also reads `Chart.controllers.pie`. It keeps its
   body and skips as `blocked: controller.pie`. W3-int or U-pie removes the `skip`.
9. **Proposed ADR and spec texts that differ from the code.** The ADRs and specs are not files of
   W2-int:
   - Chart.js ADR 0028 §6: the `onClick` form (item 3).
   - Chart.js ADR 0027 §8 and Open 4: the line has the 3-read form (item 1).
   - Chart.js ADR 0030 §7: the doughnut case is `cutout '50%'` (U-doughnut R3), and the ADR does
     not name the `BasicPlatform` patch of the doughnut and polar area generators.
   - IV §4.8: the checklist allows only `types` casts. The code also has `List`, `String` and
     `AnyObject` casts (porting-flow.md §2.21 now names them).
   - IV §4.3: "the chart draw reads `chartArea` first" is not true. F5 follows upstream.
   - Chart.js ADR 0019 line 818: the test group name `jsMapForEach in _update` (A1 open item 2).
10. **Hit ties of symmetric arcs (U-doughnut open item 4).** porting-flow.md §3 records the limit.
    No case of wave 2 has such a tie.
11. **The commit checkpoint.** All gates of the checkpoint are green (full gate, `reuse lint`,
    `gallery:build:web`, `gallery:build:android`). The wasm build in the VS Code integrated
    browser before the push is for the phase lead (memory note "Web test before push"). W2-int
    made no commit.
12. **`doc/phase7-progress.md`** has a change in the working tree that no unit of wave 2 made. It
    is not in the list below.

## Files changed in wave 2 (all units)

The paths are relative to the repository root. "(new)" marks a new file.

| Unit | Files |
|---|---|
| U-line | `packages/flutter_chartjs/lib/src/controllers/controller.line.dart` (new); `packages/flutter_chartjs/tool/reference/controller_line_reference.mjs` (new); `packages/flutter_chartjs/test/port/controllers/controller_line_reference.dart` (new, generated); `packages/flutter_chartjs/test/port/controllers/controller.line_test.dart` (new); `packages/flutter_chartjs/test/specs/controller.line_test.dart` (new) |
| U-bubble | `packages/flutter_chartjs/lib/src/controllers/controller.bubble.dart` (new); `packages/flutter_chartjs/tool/reference/controller_bubble_reference.mjs` (new); `packages/flutter_chartjs/test/port/controllers/controller_bubble_reference.dart` (new, generated); `packages/flutter_chartjs/test/port/controllers/controller.bubble_test.dart` (new); `packages/flutter_chartjs/test/specs/controller.bubble_test.dart` (new) |
| U-doughnut | `packages/flutter_chartjs/lib/src/controllers/controller.doughnut.dart` (new); `packages/flutter_chartjs/tool/reference/controller_doughnut_reference.mjs` (new); `packages/flutter_chartjs/test/port/controllers/controller_doughnut_reference.dart` (new, generated); `packages/flutter_chartjs/test/port/controllers/controller.doughnut_test.dart` (new); `packages/flutter_chartjs/test/specs/controller.doughnut_test.dart` (new) |
| U-polarArea | `packages/flutter_chartjs/lib/src/controllers/controller.polarArea.dart` (new); `packages/flutter_chartjs/tool/reference/controller_polar_area_reference.mjs` (new); `packages/flutter_chartjs/test/port/controllers/controller_polar_area_reference.dart` (new, generated); `packages/flutter_chartjs/test/port/controllers/controller.polarArea_test.dart` (new); `packages/flutter_chartjs/test/specs/controller.polarArea_test.dart` (new) |
| U-radar | `packages/flutter_chartjs/lib/src/controllers/controller.radar.dart` (new); `packages/flutter_chartjs/tool/reference/controller_radar_reference.mjs` (new); `packages/flutter_chartjs/test/port/controllers/controller_radar_reference.dart` (new, generated); `packages/flutter_chartjs/test/port/controllers/controller.radar_test.dart` (new); `packages/flutter_chartjs/test/specs/controller.radar_test.dart` (new) |
| L1 | `packages/flutter_chartjs/test/specs/core.animator_test.dart`, `core.datasetController_test.dart`, `core.layouts_test.dart`, `helpers.dom_test.dart`, `scale.category_test.dart`, `scale.linear_test.dart`, `scale.logarithmic_test.dart`, `scale.time_test.dart` |
| A1 | `packages/flutter_chartjs/lib/src/core/core.animator.dart`; `packages/flutter_chartjs/test/port/core/core.animator_test.dart` |
| W2-int | `packages/flutter_chartjs/lib/src/controllers/index.dart`; `packages/flutter_chartjs/lib/src/index.dart`; `packages/flutter_chartjs/test/port/index_test.dart`; the 10 controller test files of the units (registration lines; also `controller.bubble_test.dart` without placeholders and `controller.line_test.dart` without the skip of the no-area group); `packages/flutter_chartjs/lib/src/controllers/controller.line.dart` (F5); `packages/flutter_chartjs/lib/src/core/core.datasetController.dart` (F1); `packages/flutter_chartjs/lib/src/elements/element.point.dart` (F2, F3); `packages/flutter_chartjs/lib/src/core/core.interaction.dart` and `packages/flutter_chartjs/lib/src/types/index.dart` (F2, F5); `packages/flutter_chartjs/lib/src/elements/element.arc.dart` (F4); `packages/flutter_chartjs/lib/src/elements/element.line.dart` and `packages/flutter_chartjs/lib/src/helpers/helpers.curve.dart` (F5); `packages/flutter_chartjs/test/support/jasmine.dart` (F5); `packages/flutter_chartjs/test/port/controllers/controller_chart_harness_test.dart` (F5); `packages/flutter_chartjs/test/port/elements/element.point_test.dart` (F2, F3); `packages/flutter_chartjs/test/port/elements/element.arc_test.dart` (F4); `packages/flutter_chartjs/test/port/helpers/helpers.curve_test.dart` (F5); `packages/flutter_chartjs/tool/reference/scale_chart_common.mjs` and `packages/flutter_chartjs/tool/reference/controller_radar_reference.mjs` (F6); `packages/flutter_chartjs/test/port/controllers/controller_bubble_reference.dart` (regenerated, F6); `AGENTS.md`; `packages/flutter_chartjs/doc/porting-flow.md`, `performance.md`, `differences.md`, `status.yaml`, `parity.md` (generated), `upstream-ledger.md`, `canvas-cuts-plan.md` |
| Reports and reviews | `packages/flutter_chartjs/doc/phase7/review/wave2/` (new): `A1-report.md`, `A1-review.md`, `L1-report.md`, `L1-review.md`, `U-bubble-report.md`, `U-bubble-review.md`, `U-doughnut-report.md`, `U-doughnut-review.md`, `U-line-report.md`, `U-line-review.md`, `U-polarArea-report.md`, `U-polarArea-review.md`, `U-radar-report.md`, `U-radar-review.md`, `W2-int-report.md` |

The 8 phase 6 reference files and the bar, line, doughnut, polar area and radar data files did
not change in the F6 rerun. `REUSE.toml` and the `LICENSE` files did not change: wave 2 takes no
code from a new project.
