# Phase 7 work plan: the units of steps 3 to 7

- Inputs: Chart.js ADRs [0027](../../adr/0027-parsed-data.md),
  [0028](../../adr/0028-controller-interfaces.md), [0029](../../adr/0029-fixture-smoke-runner.md),
  [0030](../../adr/0030-controller-test-strategy.md) and
  [0031](../../adr/0031-gallery-chart-types.md) (proposed), the five specs of this folder, and
  [consistency.md](consistency.md). Where this plan and an ADR differ, the ADR wins. Where this
  plan and a spec differ on a file owner or an order, this plan wins.
- Short names of the specs: **PD** [parsed-data](parsed-data/spec.md), **IV**
  [interfaces-values](interfaces-values/spec.md), **FR** [fixture-runner](fixture-runner/spec.md),
  **TS** [test-strategy](test-strategy/spec.md), **GA** [gallery](gallery/spec.md).
- `<pkg>` is `packages/flutter_chartjs/`, `<tu>` is `packages/chartjs_test_utils/`, `G/` is
  `apps/chartjs_gallery/`. "DC" is `<pkg>lib/src/core/core.datasetController.dart`.
- The steps are the steps of the Method of [kickstart-prompt.md](../kickstart-prompt.md).

## 0. Rules for each unit

1. A unit changes only the files of its row. The units of one group run in parallel because their
   files are disjoint. A file that two units need goes to the earlier unit, and the later unit
   starts after it.
2. Only the integration agents (W1-int, W2-int, W3-int, F-int, G-U5) change the shared docs:
   `AGENTS.md`, `CONTRIBUTING.md`, the PR template, `<pkg>doc/porting-flow.md`,
   `<pkg>doc/performance.md`, `<pkg>doc/differences.md`, `<pkg>doc/status.yaml`,
   `<pkg>doc/theming.md`, `<pkg>doc/upstream-ledger.md`. Each other unit puts its doc notes into
   its report. The phase lead alone writes `<pkg>doc/phase7-progress.md`.
3. Each unit re-reads a shared file directly before each edit, kills each `flutter_tester` process
   that it leaves, makes no commit and runs no git command that changes the index or the tree.
   Prose in ASD-STE100.
4. "Full gate" is `dart run melos run format:check`, `analyze` (it covers `G/`), `test --no-select`,
   `test:web`, `test:cases` and `check:port`. From F-int on, it also has `test:fixtures`. A commit
   checkpoint adds `gallery:build:web`, `gallery:build:android` and `reuse lint` (kickstart prompt,
   Gates).
5. Each unit that changes `lib/` gets an adversarial fidelity reviewer that proves each defect
   with a probe (Method step 3). A generator rerun gives byte-identical data.
6. The test files of a controller unit register its controller in `main()` until the integration
   agent of its wave registers the wave (Chart.js ADR 0030 §3 item 4, TS §2).

## 1. Wave 1: the shared layer and `controller.bar`

Order: S1, then S2, then S3 and U0 in parallel with U-bar (lib part); U-bar tests after U0; then
W1-int.

| Unit | Files it owns | Spec sections | Tests | Gates |
|---|---|---|---|---|
| **S1** runtime | `<pkg>lib/src/js/js_object.dart`, `js_array.dart`, `js_number.dart`; `<pkg>test/port/js/js_object_test.dart`, `js_array_test.dart`, `js_number_test.dart` | PD §2, §7.1 | the pure groups `jsGetKey`, `jsGetIndex`, `jsSetIndex`, `jsLessThan` (each expected value checked in the x64 Node.js) | full gate |
| **S2** core layer (after S1) | DC (PD §3 reads, the index helpers, `jsLessThan`; IV §3.3; TS §1.1 writable `ctx`); `<pkg>lib/src/core/core.controller.dart`, `core.element.dart`, `core.scale.dart`; `<pkg>lib/src/scales/*.dart` (the `@override`s, `RadialLinearScale implements`); `<pkg>lib/src/types/index.dart`; `<pkg>lib/src/elements/element.point.dart`, `element.line.dart`; `<pkg>lib/src/helpers/helpers.extras.dart`, `helpers.config.dart`; the 9 implementers of IV §3.8 (`<pkg>test/specs/helpers.segment_test.dart`, `<pkg>test/port/helpers/helpers.segment_test.dart`, `helpers.extras_test.dart`, `helpers.collection_test.dart`, `<pkg>tool/bench/bench_flutter_test.dart`, `<pkg>tool/bench/src/cases_data.dart`, `<pkg>test/port/core/core.datasetController_test.dart`, `G/lib/demo/demo_chart.dart` with the code of GA §3.0); `<pkg>test/port/types/index_test.dart` (new), `<pkg>test/port/core/core.controller_test.dart`, `<pkg>test/port/elements/element.line_test.dart` (group `adapt-line-points-elements` only), `<pkg>test/port/core/core.datasetController_chart_test.dart` (the `ctx` case of TS §1.8) | PD §3; IV §2, §3, §7.1, §7.2; TS §1.1; GA §3.0 (U0 of GA) | IV §7.1, §7.2; the `ctx` case; all existing tests pass with no change except the implementers | full gate; `flutter test` in `G/` |
| **S3** `stacksOf` (after S2) | DC (PD §4); `<pkg>test/port/core/core.datasetController_test.dart` (group `js-semantics-resolver-objects`, the unit cases of `stacksOf`); `<pkg>test/port/core/core.datasetController_chart_test.dart` (the List items through a test controller) | PD §4, §7.2 | PD §7.2 | the measurement of PD §4.3 first: a paired loss above 0.5 ns for each item goes to the maintainer, who chooses PD §4.1 or the fallback §4.4; then the full gate |
| **U0** test infrastructure (after S2, parallel with S3) | `<pkg>tool/reference/scale_chart_common.mjs`; the 8 phase 6 data files `<pkg>test/port/scales/scale_{chart_harness,category,linear,linearbase,logarithmic,radial_linear,time,timeseries}_reference.dart`; `<pkg>test/port/scales/scale_chart_harness.dart`, `scale_chart_harness_test.dart`; `<pkg>test/port/canvas/path2d_record.dart` (new); `<pkg>test/port/elements/element.line_test.dart` (the move of the `Path2D` helpers); `<pkg>tool/reference/controller_chart_common.mjs` (new); `<pkg>test/port/controllers/controller_chart_harness.dart` and `controller_chart_harness_test.dart` (new); `<pkg>test/support/jasmine.dart` (new); the spec files with private Jasmine copies: `<pkg>test/specs/core.controller_test.dart`, `core.plugin_test.dart`, `helpers.canvas_test.dart`, `core.element_test.dart`, `helpers.segment_test.dart`, `helpers.interpolation_test.dart`, `helpers.easing_test.dart`, `helpers.options_test.dart` (a scan on 2026-10-21 found no copy in `helpers.curve_test.dart`) | TS §1 without §1.1 | TS §1.8 rows 2-5; `test:cases` counts equal before and after; the 8 regenerated files twice with the same SHA-256; the `registerPhase7` check of TS §1.2 item 5 (result in the report) | full gate |
| **U-bar** (lib after S2; tests after U0 and S3) | `<pkg>lib/src/controllers/controller.bar.dart`; `<pkg>test/port/controllers/controller.bar_test.dart`; `<pkg>tool/reference/controller_bar_reference.mjs`; `<pkg>test/port/controllers/controller_bar_reference.dart` (and `_2`); `<pkg>test/specs/controller.bar_test.dart` | PD §5.1, §5.2, §5.8, §7.3 (bar rows), §7.4; IV §4.1, §4.8, §7.3 (bar rows); TS §2, §5; ADR 0030 §7 (23 cases) | 23 reference cases and their themed twins; the `parsed:` and `interfaces:` cases; the spec file: 54 `phase7` records with bodies (the 3 cases of `:70`, `:310`, `:671` as `'blocked: controller.line'` placeholders, TS §4.2), 1 `blocked: plugin.tooltip`, the D1 cases `:1426`, `:1442`, `:1538` with bodies | `analyze`; the unit test files; `test:cases`: 0 missing and 0 failed in `controller.bar_test.dart`; generator rerun byte-identical; fidelity review |
| **W1-int** (after U-bar) | `<pkg>lib/src/controllers/index.dart` (new, `BarController`); `<pkg>lib/src/index.dart` (export and `controllers` Map); `<pkg>test/port/index_test.dart`; the temporary `Chart.register` lines of the U-bar test files; the shared docs (rule 2) | IV §5, §7.4, §8; PD §8; TS §6; the reports of S1-S3, U0, U-bar | IV §7.4 for `bar` | full gate; `lift_check.py <all.json> <out> 1` lists the wave 1 records; commit checkpoint |

## 2. Wave 2: line, bubble, doughnut, polar area, radar

Start: after W1-int. The five controller units, L1 and A1 run in parallel. W2-int ends the wave.

| Unit | Files it owns | Spec sections | Tests | Gates |
|---|---|---|---|---|
| **U-line** | `<pkg>lib/src/controllers/controller.line.dart`; `<pkg>test/port/controllers/controller.line_test.dart`; `<pkg>tool/reference/controller_line_reference.mjs`; `<pkg>test/port/controllers/controller_line_reference.dart`; `<pkg>test/specs/controller.line_test.dart` | PD §5.3 (with the one-read rule; the maintainer reviews `prevIValue`, ADR 0027 Open 4); IV §4.2, §4.3, §7.3 (line rows); TS §2, §5; ADR 0030 §7 (17 cases) | 17 cases and twins; the pin cases (`line.points`, a dataset element of another class, the one-read rule, the List stacks); spec: 33 `phase7`, 1 tooltip skip | as U-bar |
| **U-bubble** | `controller.bubble.dart`; `controller.bubble_test.dart`; `controller_bubble_reference.mjs` and its data; `<pkg>test/specs/controller.bubble_test.dart` | PD §5.4; IV §4.1, §7.3 (labels); TS §2, §5; ADR 0030 §7 (7 cases) | 7 cases and twins; pin cases; spec: 10 `phase7`, 1 tooltip skip | as U-bar |
| **U-doughnut** | `controller.doughnut.dart`; `controller.doughnut_test.dart`; `controller_doughnut_reference.mjs` and its data; `<pkg>test/specs/controller.doughnut_test.dart` | PD §5.5; IV §4.4, §4.7 (the legend functions and descriptors), §7.3; TS §2, §5; ADR 0030 §7 (15 cases) | 15 cases and twins; `meta.total`, rotation extents, legend items, `onClick`; spec: 12 `phase7`, 1 tooltip skip | as U-bar |
| **U-polarArea** | `controller.polarArea.dart`; `controller.polarArea_test.dart`; `controller_polar_area_reference.mjs` and its data; `<pkg>test/specs/controller.polarArea_test.dart` | PD §5.6; IV §4.5 (the cast, the #12238 hunk), §4.7, §7.3; TS §2, §5; ADR 0030 §7 (9 cases) | 9 cases and twins; the 11 hunk rows, the hover row, the option-sharing subclass; spec: 13 `phase7`, 1 tooltip skip | as U-bar |
| **U-radar** | `controller.radar.dart`; `controller.radar_test.dart`; `controller_radar_reference.mjs` and its data; `<pkg>test/specs/controller.radar_test.dart` | PD §5.7; IV §4.2, §4.6, §7.3; TS §2, §5; ADR 0030 §7 (8 cases) | 8 cases and twins; pin cases; spec: 11 `phase7`, 1 tooltip skip, 1 filler skip | as U-bar |
| **L1** lift of wave 1 (step 4) | the records of wave 1 outside the controller spec files: `<pkg>test/specs/core.animator_test.dart` (1), `core.datasetController_test.dart` (3), `core.layouts_test.dart` (5), `helpers.dom_test.dart` (2), `scale.category_test.dart` (2), `scale.linear_test.dart` (25), `scale.logarithmic_test.dart` (21), `scale.time_test.dart` (1); the move of `core.datasetController_test.dart` and `core.layouts_test.dart` to the VM (TS §4.2) | TS §4; ADR 0030 §12 | the lifted bodies | `test --no-select`; `test:cases`; `lift_check.py ... 1` green; `check:port`; `test:web` |
| **A1** animator members | `<pkg>lib/src/core/core.animator.dart`; `<pkg>test/port/core/core.animator_test.dart` | FR §3 | group `harness-method-fields` | full gate |
| **W2-int** (after the five units and L1) | `lib/src/controllers/index.dart` (+5); `lib/src/index.dart`; `test/port/index_test.dart`; the temporary `Chart.register` lines of the five units; the shared docs, with `upstream-ledger.md` row #12238 (IV §8.6) | as W1-int; the reports of the wave, L1 and A1 | IV §7.4 for 6 controllers | full gate; `lift_check.py ... 1` green; commit checkpoint |

## 3. Wave 3: scatter, pie, `index.js` and `registerables`

Start: after W2-int. U-scatter, U-pie and L2 run in parallel. W3-int ends the wave.

| Unit | Files it owns | Spec sections | Tests | Gates |
|---|---|---|---|---|
| **U-scatter** | `controller.scatter.dart` (imports `controller.line.dart` and `core.registry.dart`); `controller.scatter_test.dart`; `controller_scatter_reference.mjs` and its data; `<pkg>test/specs/controller.scatter_test.dart` | PD §5.3; IV §4.1-§4.3, §7.3; TS §2, §5; ADR 0030 §7 (6 cases) | 6 cases and twins; pin cases; spec: 4 `phase7`, 2 tooltip skips | as U-bar |
| **U-pie** | `controller.pie.dart` (imports `controller.doughnut.dart`); `controller.pie_test.dart`; `controller_pie_reference.mjs` and its data (pie has no spec file) | IV §4.7 (inherited functions, no copy), §7.3; TS §2; ADR 0030 §7 (4 cases) | 4 cases and twins; the identical option functions in `overrides['pie']` | as U-bar, without a spec file |
| **L2** lift of wave 2 (after L1) | the records of wave 2 outside the controller spec files: `core.controller_test.dart` (30), `core.datasetController_test.dart` (38), `core.interaction_test.dart` (43), `core.scale_test.dart` (26), `core.ticks_test.dart` (2), `element.line_test.dart` (1), `platform.dom_test.dart` (2), `scale.category_test.dart` (11), `scale.linear_test.dart` (11), `scale.logarithmic_test.dart` (37), `scale.radialLinear_test.dart` (18), `scale.time_test.dart` (14); the 3 placeholders of `controller.bar_test.dart`; `<pkg>test/port/scales/scale.time_test.dart` (`_lineTwin`, 57 twins); the moves of `core.interaction_test.dart`, `core.ticks_test.dart` and `element.line_test.dart` to the VM | TS §4; ADR 0030 §12 | the lifted bodies and twins | as L1, with wave 2 |
| **W3-int** (after U-scatter, U-pie, L2) | `lib/src/controllers/index.dart` (the final content of IV §5.1); `lib/src/index.dart` (the final `controllers` Map; `registerables` does not change); `test/port/index_test.dart` (the test "the namespaces of later phases are empty" keeps only `plugins`); the temporary lines; the shared docs | IV §5, §7.4, §8; TS §6 | IV §7.4 for 8 controllers | full gate; `lift_check.py ... 2` green; commit checkpoint |

## 4. Step 4: spec bodies, the lift and the fixtures

Start: after W3-int. L3, R0, T-theme, T1 and H1-H4 run as below. F-int is the last unit.

| Unit | When | Files it owns | Spec sections | Tests | Gates |
|---|---|---|---|---|---|
| **L3** lift of wave 3 | after L2 | `core.controller_test.dart` (7), `core.datasetController_test.dart` (2), `core.interaction_test.dart` (2), `core.scale_test.dart` (5) | TS §4 | the lifted bodies | as L1, with wave 3: all 503 `phase7` records pass, 21 legend, 11 tooltip and 1 filler records skip with their reason |
| **R0** runner | after W3-int | the files of FR §0, row R0 (`<tu>lib/src/fixture.dart`, `dom.dart`, `index.dart`, `<tu>lib/flutter.dart`, both `dart_test.yaml`, `<tu>test/fixture_test.dart`, `<tu>test/fixture_probe/**`, `<tu>test/dom_test.dart`, `<pkg>test/fixtures/index.dart` (first form), `<pkg>tool/spec_cases.dart`, `<pkg>tool/src/spec_cases.dart`, `<pkg>tool/parity.dart`, `<pkg>test/tool/spec_cases_test.dart`, `<pkg>tool/port_sources.yaml`, `<pkg>test/tool/check_port_headers_test.dart`, `<pkg>test/flutter_test_config.dart` (one comment)); root `pubspec.yaml` and `.github/workflows/ci.yaml` only if R0 lands with F-int | FR §2 | FR §2.9 | full gate; `port_sources.yaml` first (the H gates need it) |
| **H1**, **H2**, **H3**, **H4** hand ports | parallel with R0; H1 and H3 also after A1 | `<pkg>test/fixtures/hand/<prefixes of the unit>/**` (FR Appendix B: 26, 31, 40 and 20 files) | FR §4 | the temporary local test of FR §4.2 (not kept) | `analyze`, `format:check`, `check:headers` (after the R0 change of `port_sources.yaml`), `check:js-semantics`; a report line with the 12 hex digits for each file |
| **T1** twins | after R0 | `<pkg>test/port/fixtures/moment_twins_test.dart` | FR §5 | 36 twins | `analyze`; the file under `--tags fixtures` |
| **T-theme** | after W3-int | `<pkg>tool/reference/theme_precedence_reference.mjs`; `<pkg>test/port/theme/precedence_reference.dart` (generated); `<pkg>test/port/theme/precedence_test.dart`; `<pkg>test/port/theme/blue_screen_test.dart` (new). It reads the 8 controller test files and reports a missing themed group to the owner unit. | TS §3; ADR 0030 §8-§11 | test 5 (6 new scenarios), the group `hover` (8 types, the `#B40000` pin), the blue screen (8 types, the control, the empty known leaks, `defaults` unchanged) | full gate; generator rerun byte-identical |
| **F-int** integration | after R0, H1-H4, T1, L1-L3 and T-theme | `<pkg>test/fixtures/index.dart` (the 117 hand entries); the 20 spec files of FR §6.2 (the `auto` call; `element.point_test.dart` moves to the VM); `<pkg>test/specs/mixed_test.dart` (new; its 2 chart cases probed first); `<pkg>test/port/fixtures/index_test.dart`; root `pubspec.yaml` (`test`, `test:fixtures`) and `ci.yaml` (job `fixtures`) if R0 did not add them; the shared docs of FR §8 and the theming notes of TS §6 | FR §6, §7, §8 | FR §6.3; FR §6.4: 457 fixtures pass, 72 skip with the reasons of Appendix A, 36 twins pass, 0 missing, 0 unknown | full gate with `test:fixtures`; `lift_check.py` green; `test:cases` 0 missing (also the 2 mixed cases); commit checkpoint |

## 5. Step 5: the gallery

Start: after W3-int (GA §1: U2 needs the eight controllers in `registerables`). It can run in
parallel with step 4: its files are in `G/` and in the shared docs, which only G-U5 changes.

| Unit | When | Files it owns | Spec sections | Tests | Gates |
|---|---|---|---|---|---|
| **G-U1** `SegmentChoiceItem.icon` | first | `G/lib/demo/demo_controls.dart`; `icon: null` in `G/lib/demo/stress_demo.dart` and `G/test/stress_controls.dart` | GA §3.1 | the existing gallery tests | `format:check`, `analyze`, `flutter test` in `G/` |
| **G-U2** stress chart, timing, benchmark | after G-U1 | `G/lib/demo/stress_point_controller.dart` (deleted), `gallery_components.dart` (new), `stress_chart_config.dart`, `stress_timing.dart` (new), `stress_axes.dart`, `stress_demo.dart`, `G/lib/main_stress.dart`, `G/lib/bench/chart_bench.dart`, `G/lib/main_bench.dart`, `G/lib/canvas_host_demo.dart`, `G/README.md`; `G/test/stress_chart_test.dart`, `stress_axes_test.dart`, `chart_bench_test.dart`, `chart_canvas_test.dart`, `canvas_host_demo_test.dart` | GA §3.2-§3.8, §5.3-§5.5, §5.7 | as listed | as G-U1 |
| **G-U3** chart type pages | after G-U2 | `G/lib/charts/chart_types.dart`, `chart_type_page.dart` (new); `G/lib/docs/charts/*.dart`, `G/lib/docs/samples/area/line_boundaries.dart` (new); `G/lib/main.dart`; `G/test/chart_types_test.dart` (new), `gallery_test.dart` | GA §3.9-§3.12, §5.1, §5.2 | 13 charts; in view at 412 x 915 and 360 x 640 | as G-U1 |
| **G-U4** Core and Axes tabs | after G-U2 (parallel with G-U3) | `G/lib/demo/core_demo.dart`, `axes_demo.dart`; `G/test/core_demo_test.dart`, `axes_demo_test.dart` | GA §3.13, §3.14, §5.6 | as listed | as G-U1 |
| **G-U5** gallery docs | after G-U2-G-U4 | the shared docs of GA §7 | GA §7 | — | full gate; `gallery:build:web`, `gallery:build:android`; the wasm build in the VS Code integrated browser before the push; commit checkpoint |

## 6. Step 6 and step 7

- **Step 6 (review):** the finder groups of the Method. The ADR open items with the owner
  "step 6": ADR 0027 Open 2 (the early cast of DC `parseObjectData`).
- **Step 7 (performance):** G-U6 (the A, A' and B sides of GA §6 on the Pixel 8a); ADR 0027 Open 3
  (the step 7 list) and Open 5; ADR 0028 Open 1 (form T, and the record of the early return in the
  mode `axes`); ADR 0030 Open 3 (the read of `ctx` for each bar); ADR 0025 Open 1 and Open 2 (a
  `timeseries` variant of the mode `axes` in a worktree, and the logarithmic value axis,
  consistency.md G8); the items of `performance.md` §11.8 that no ADR decided (the tick font for
  each tick, the fdlibm `log10`, consistency.md G9). Each change follows the performance rule and
  the measurement method of the kickstart prompt.

## 7. Doc numbering

The integration agents use these numbers, in ADR order:

| File | Section | Content | Writer |
|---|---|---|---|
| `porting-flow.md` §2 | 2.20 | Chart.js ADR 0027: Parsed data in the controllers (gate 7) | W1-int |
| | 2.21 | Chart.js ADR 0028: Controller interfaces and values (gate 7) | W1-int |
| | 2.22 | Chart.js ADR 0029: Fixture smoke runner (gate 7) | F-int |
| | 2.23 | Chart.js ADR 0030: Controller test strategy (gate 7) | W1-int |
| `performance.md` | 13 | Controllers (phase 7) | W1-int (creates it) |
| | 13.1 | The parsed read (Chart.js ADR 0027), with the `stacksOf` figures of S3 | W1-int |
| | 13.2 | The interfaces and values (Chart.js ADR 0028), with P-B7 | W1-int |
| | 13.3 | The fixture runner (Chart.js ADR 0029) | F-int |
| | 13.4 | The writable `DatasetController.ctx` (Chart.js ADR 0030) | W1-int |
| | 13.5 | The stress chart of phase 7 (Chart.js ADR 0031) | G-U5 |
| | 13.6 | The controller paths on the phones (step 7), next to `phase7/perf/before/` | step 7 |
| | 13.7 | Open: the step 7 list of ADR 0027 §8, ADR 0028 Open 1, ADR 0030 Open 3 | W1-int, then each owner |
| `AGENTS.md` | the `doc/adr/` item | Chart.js ADRs 0001-0031; 0027-0031 proposed | W1-int (0027, 0028, 0030), F-int (0029), G-U5 (0031) |

ADR 0031 gets no section in `porting-flow.md` §2: GA §7 changes no rule of the porting flow.
