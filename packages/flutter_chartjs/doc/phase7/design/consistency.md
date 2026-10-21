# Phase 7 design: consistency check

- Scope: the five decisions of phase 7, step 2 (Design): Chart.js ADRs
  [0027](../../adr/0027-parsed-data.md), [0028](../../adr/0028-controller-interfaces.md),
  [0029](../../adr/0029-fixture-smoke-runner.md), [0030](../../adr/0030-controller-test-strategy.md)
  and [0031](../../adr/0031-gallery-chart-types.md) (all proposed), and the five implementation
  specs [parsed-data](parsed-data/spec.md), [interfaces-values](interfaces-values/spec.md),
  [fixture-runner](fixture-runner/spec.md), [test-strategy](test-strategy/spec.md) and
  [gallery](gallery/spec.md).
- Date: 2026-10-21. Pin: Chart.js `v4.5.1+7169e651`. The Dart line numbers refer to the working
  tree on that date.
- Method: each ADR and each spec read in full; each cross-reference compared; the claims that
  decide a finding checked in the pinned source, the package, the gallery, `all.json` and the
  manifest (the "Checked" column).
- The plan of the port waves that follows from these decisions is in [work-plan.md](work-plan.md).

Status values: **fixed** (this check changed the named files), **owner** (the item needs a
decision or work outside the ten files; the owner and the trigger are named), **no change** (the
check found no defect).

## 1. Contradictions between the decisions

| # | Finding | Checked | Status and fix |
|---|---|---|---|
| C1 | `DemoChart` gets other bodies in two documents. Interfaces spec §3.8: `toggleDataVisibility` and `update` throw `UnsupportedError`. ADR 0031 §9.2 and gallery spec §3.0: `toggleDataVisibility` does nothing, and `update` calls `render()`. | `apps/chartjs_gallery/lib/demo/demo_chart.dart:245` has `render()`; `:316` `draw()` calls it. | **Fixed.** Interfaces spec §3.8 takes the form of ADR 0031 §9.2. ADR 0028 §1 (implementer table) points to ADR 0031 §9.2. Gallery spec §1 names S2 as the unit of U0. |
| C2 | The early return of `getDataVisibility`. ADR 0027 §8 puts the empty-Map path in the step 7 list ("ported literally"). ADR 0028 §4 adopts it in the port step and closes ADR 0025 Open 4. | `core.controller.js:885-887`; ADR 0025 (accepted) §3 and Open 4. | **Fixed.** ADR 0027 §8 removes the item and names ADR 0028 §4; ADR 0027 Open 3 says that P-B7 is adopted. ADR 0028 §4 adds why the statement is not a structure change of ADR 0027 §8 (it skips no upstream call, only the port-only key string). Parsed-data spec §8.3 moves P-B7 to `performance.md` 13.2. |
| C3 | The label of `getLabelAndValue`. Test-strategy spec §1.6 gives `({String label, String value})`. ADR 0028 §2 gives `({Object? label, String value})`. | ADR 0028 Measurements, question 2. | **Fixed.** Test-strategy spec §1.6 takes the ADR 0028 record and says how the raw label compares. |
| C4 | One line of `line.js:59` in two forms: `jsGet(dataset, '_decimated')` (interfaces spec §4.2) and `jsGetKey(meta.dataset_, '_decimated')` (parsed-data spec §5.3). | Both give the same value (ADR 0027 §1: `jsGetKey` gives the `jsGet` result for each receiver). | **Fixed.** Interfaces spec §4.2 takes `jsGetKey`. |
| C5 | The event of the hit queries. Test-strategy spec §1.5 adds a key `chart`. ADR 0030 §5 has `{type, native: null, x, y}`. | `helpers.dom.ts:105-111` returns the event as it is; `types.ChartEvent` (`lib/src/types/index.dart:685`) has no `chart`. | **Fixed.** Test-strategy spec §1.5 takes the ADR form. |
| C6 | File owner of `lib/src/controllers/index.dart`. Parsed-data spec §1 gives it to the wave agent. Interfaces spec §0 and test-strategy spec §0 give it to the integration agent of the wave only. | — | **Fixed.** Parsed-data spec §1 gives it to the integration agent. |
| C7 | The DC change of four parts: parsed-data steps 2 and 3, interfaces step 1 and test-strategy U0 §1.1 (`ctx`). The interfaces spec says that one agent does parsed-data steps 1 and 2. The test-strategy spec runs U0 "before wave 1" on its own. | — | **Fixed.** Units S2 and S3 of [work-plan.md](work-plan.md) own DC one after the other. Interfaces spec §0 and test-strategy spec §0, §1.1 and §1.8 name them. |
| C8 | Two units change `test/port/elements/element.line_test.dart` (interfaces spec §7.2: the group `adapt-line-points-elements`; test-strategy spec §1.4: the move of the `Path2D` helpers) and `test/specs/helpers.segment_test.dart` (the implementer `_Point`; the move of the Jasmine copies). | — | **Fixed** by order: S2 before U0 ([work-plan.md](work-plan.md), wave 1). |
| C9 | Jasmine support library. ADR 0030 §13.7 says that `test/support/jasmine.dart` imports only pure layers. Test-strategy spec §1.7 types `spyOnArrayListener` with `DatasetController`, which is not a pure layer. `check:lib-imports` follows the imports of each web test into `test/` libraries. | `tool/src/lib_imports.dart:283-309`; `ArrayListener` is in `helpers.collection.dart` (a pure layer). | **Fixed.** Test-strategy spec §1.7 takes `ArrayListener<Object?>`. |
| C10 | Count of the pure cases that leave the web legs. ADR 0030 (Consequences) says "5 more" for `element.point`; ADR 0029 §2.4 says 4. | `test/specs/element.point_test.dart`: 4 `test(` cases. | **Fixed.** ADR 0030 Consequences and test-strategy spec §6 say 4 (8 in all). |
| C11 | ADR 0030 Open 2 (the position of the fixture tests) stays open, but ADR 0029 §2.3 closes it. The table of ADR 0030 §14 also names item 2 for question 2 (the theme tests). | — | **Fixed.** ADR 0030 Open 2 says "Closed"; the table names item 5 for question 2 and no item for question 4. |
| C12 | Wrong references: the parsed-data spec cites ADR 0030 §2 for the generators (it is §3) and writes `controller_<name>_reference.mjs`; the test-strategy spec writes `controller_<snake>_reference.mjs` (`polar_area`). | ADR 0030 §3 item 2. | **Fixed** in the parsed-data spec (§1, §7.4) and the interfaces spec (§1, §7.5). |
| C13 | The lift agents and the controller spec files. The units own the 7 controller spec files (test-strategy spec §0, §5), but `lift_check.py --list` also lists their records for the lift agents. Also, 3 cases of `controller.bar.tests.js` (`:70`, `:310`, `:671`) need `controller.line` (wave 2), but U-bar owns the file in wave 1. | `all.json`: 9 controller-spec records have a later wave than their unit; 6 of them are "should be registered as dataset controller", which pass after the registration. | **Fixed.** ADR 0030 §12.7 and test-strategy spec §4.2: the unit ports its records; U-bar writes the 3 line cases as `'blocked: controller.line'` placeholders, and L2 lifts them. L1, L2 and L3 run one after the other. |
| C14 | The themed run of test 3 runs each case of a generator file, also the pin cases `parsed:` and `interfaces:` of the other specs (throws, test legends). | — | **Fixed.** ADR 0030 §7 and test-strategy spec §1.6, §2: the themed run runs only the 89 cases of §7. |

## 2. Gaps (a question without a decision, a form, or an owner)

| # | Finding | Status and fix or owner |
|---|---|---|
| G1 | The pin cases that the parsed-data and interfaces specs put into the generators need a throw record (for example `TypeError` in `update` or in the draw) and values outside the observations of ADR 0030 §4 (`countVisibleElements()`, `getMinMax()`, the legend items, the identity of `meta._parsed`). ADR 0030 §4 had no form for them. | **Fixed.** ADR 0030 §4 gets the optional keys `error` (`{at, name}`) and `extra` (named probes with one body on each side). Test-strategy spec §1.5, §1.6 and §2, parsed-data spec §7.4 and interfaces spec §7.5 use them. |
| G2 | Registration before the integration of a wave. ADR 0030 §3.4 said that the Dart tests register nothing, and the integration agent registers the controllers at the end of the wave. Thus no unit can run its own reference and pin tests, which are its gates (parsed-data spec §0 step 4, interfaces spec §0 step 2). | **Fixed.** ADR 0030 §3.4 and test-strategy spec §0, §2: each test file of a unit registers its controller in `main()` until the integration agent registers the wave (`core.typedRegistry.js:41-44` ignores a second registration of an id); the integration agent removes the lines. |
| G3 | Parsed-data step 3 tests a stacked line and a stacked bar chart, but step 3 runs before the bar and line waves. The named file `test/port/core/core.datasetController_test.dart` has no charts ("DatasetController without a chart"). | **Fixed.** Parsed-data spec §1 and §7.2: step 3 tests `stacksOf` alone and the List write through a test controller in `core.datasetController_chart_test.dart`; the line and bar probe rows (F-P1, F-P4) go to §7.3 for the bar and line units. |
| G4 | `mixed.tests.js` has 2 chart cases (`:4`, `:25`). `all.json` does not classify them, so `lift_check.py` does not see them. ADR 0029 and the fixture spec put them into `mixed_test.dart` without a probe step. | **Fixed.** ADR 0029 §2.3 and fixture spec §6.2: F-int probes them first, and `test:cases` must report them as passed; F-int adds the `status.yaml` row. |
| G5 | `doc/upstream-ledger.md` rows `ab79c3bf` (#12238), `cb02e1d2` (#12155) and `714b48cd` (#12328) say that their controller part and fixtures wait for phase 7. No spec updated them. | **Fixed.** Interfaces spec §8.6 (W2-int: #12238) and fixture spec §8.5 (F-int: the three rows). |
| G6 | The numbers of the new doc sections. The test-strategy spec claims `porting-flow.md` §2.20 for ADR 0030, the interfaces and fixture specs give no number, the parsed-data spec gives no §2 section for ADR 0027, and four specs add parts of `performance.md` §13 without numbers. | **Fixed.** [work-plan.md](work-plan.md) ("Doc numbering") gives the numbers; the five specs cite them. |
| G7 | The `check:headers` gate of the hand-port units H1-H4 needs the target `test/fixtures/` of `tool/port_sources.yaml`, which R0 adds. | **Fixed.** Fixture spec §0: R0 lands that change before the H gates. |
| G8 | ADR 0025 (accepted) Open 1 asks phase 7 to measure `TimeSeriesScale.getDecimalForValue` in the stress mode `chart` with a `timeseries` axis. No config of ADR 0031 has a `timeseries` axis (mode `chart`: hidden linear and radial scales; mode `axes`: linear, logarithmic, category, time). ADR 0025 Open 2 (a logarithmic value axis, `CALL=update`) maps to the mode `axes` with `y` logarithmic. | **Owner:** step 7 of phase 7. Trigger: the start of step 7. Form: a variant of the mode `axes` with the x type `timeseries`, made in a worktree (kickstart prompt, "Measurement method"). The radar part of Open 1 maps to the type `radar` of ADR 0031 §5. |
| G9 | Kickstart scope: the open work of `performance.md` §11.8 (the tick font for each tick, the fdlibm `log10` of the logarithmic scale). No design panel decided them. The third item (the Map reads of `getMinMax`) is ADR 0027 §2 (form T). | **Owner:** step 7 of phase 7, with an A/B for each (kickstart prompt, Scope). |
| G10 | ADR 0031 Open (the Axes tab split) and ADR 0028 Open 3 (the label reads after the acceptance of ADR 0027). | **Owner:** the maintainer, as the ADRs say. No change. |

## 3. Conflicts with the existing ADRs 0001-0026

| # | Check | Result |
|---|---|---|
| A1 | ADR 0025 (accepted) §8 asks for a parsed read with the `jsGet` result; ADR 0027 §1 fills it with `jsGetKey` and keeps §8. ADR 0025 §5 lists `getBaseValue` with a first reader in phase 8; ADR 0028 defers it to phase 8 by the rule of ADR 0003 (accepted). ADR 0025 Open 4 asks phase 7 to decide `getDataVisibility` with the performance rule; ADR 0028 §4 decides it. | **No change.** No text of ADR 0025 changes. |
| A2 | ADR 0009 (accepted) §4: a smoke test passes when no exception occurs. ADR 0029 §7 adds no other assertion and keeps the canvas size check as Open 3, which needs a superseding ADR. | **No change.** |
| A3 | ADR 0003 (accepted): records for inline object types, a member with its first ported caller. ADR 0027 (the bar ruler), ADR 0028 (the members, `getLabelAndValue` record, `getPointPositionForValue` record) follow it. | **No change.** |
| A4 | ADR 0001 (accepted for its four invariants): no `lib/src/theme/` import in ported files, specs unthemed, no `Chart.defaults` writes for theming. ADR 0030 §8-§11 run the themed cases only in port-only test files and check `defaults` after each themed run. | **No change.** |
| A5 | ADRs 0017, 0019, 0020, 0021 and 0022 are proposed. ADR 0029 §6 decides the Open item of ADR 0019, and §1-§2 decide the Open item of ADR 0022, without a change of their text. ADR 0031 completes ADR 0021 §8. | **No change.** |
| A6 | The kickstart prompt (not an ADR) names the CI job `fixtures` "with the submodule checkout and `FIXTURES_REQUIRED=1`". ADR 0029 §11.5 drops both and says so. The prompt also lists `test:fixtures` as a gate before each commit, but the script exists only from the runner commit (ADR 0029 §11.6). | **Owner:** the maintainer, at the review of ADR 0029. Trigger: before R0 lands. Until then, R0 and F-int follow ADR 0029. |

## 4. Performance claims and their evidence

| # | Claim | Status |
|---|---|---|
| P1 | ADR 0028 Consequences: "0.24-0.35 ms for each update of 20000 bars" from the early return of `getDataVisibility`. It is a product of the ns figures, not a measurement. | **Fixed.** The text says that it is a calculation, not a frame figure, and points to Open 1, which records the frame figure. |
| P2 | ADR 0030 Consequences: "about 4-6 MB" of data and "about 3-5 s of CPU". No probe measured these values for the 8 controllers. | **Fixed.** The text says that both are estimates from E5 and E6; each unit records the real size and time. |
| P3 | ADR 0028 §4: the early return lands with microbenchmark figures only. ADR 0020 §13 asks for frame figures for a form that changes the structure. | **Fixed** (C2): ADR 0028 §4 states why it keeps the structure. |
| P4 | ADR 0027 §8: the gain of the one-read rule (22-36 ns for each point) is labeled as a calculation from the microbenchmark. ADR 0029 §6 (the `refresh` field), ADR 0030 §1 (the writable `ctx`) and ADR 0028 §3 (the copy of `points`) keep the structure and give AOT and wasm figures. ADR 0031 gives JIT and wasm `flutter test` figures for a gallery config, not for a library form. | **No change.** |

## 5. Simplified Technical English in the ADRs

| # | Finding | Status |
|---|---|---|
| S1 | A scan of the five ADRs for `should`, `may`, `might`, `would`, `could`, contractions, `e.g.`, `i.e.` and `etc.` found no hit (the one hit is the zone name `Etc/UTC`). | **No change.** |
| S2 | Long descriptive sentences: ADR 0029 Open 1 (40 words, two triggers in one sentence), ADR 0030 §11 (the diagnosis), ADR 0031 (the alternative "Suggested x and bounded y"). | **Fixed:** each is now two or three sentences. The other long items are lists or tables. |
| S3 | ADR 0027 §8, the one-read rule: "it reads `getParsed(start - 1)` inside the `i > 0 &&` operand" does not match `line.js:87`, which calls `getParsed(start - 1)` before the loop. | **Fixed.** The text names the read `jsGetKey(prevParsed, iAxis)` of the `prevParsed` of `line.js:87`. |
| S4 | The Related lists of ADRs 0028, 0030 and 0031 named a parallel ADR without a link. | **Fixed.** Links added in ADRs 0027, 0028, 0030 and 0031. |

## 6. Files changed by this check

- `doc/adr/0027-parsed-data.md`: Related; §8 (the one-read rule text, the step 7 list); Open 3.
- `doc/adr/0028-controller-interfaces.md`: Related; §1 (the `DemoChart` row); §4; Consequences.
- `doc/adr/0029-fixture-smoke-runner.md`: §2.3 (the mixed cases); Open 1.
- `doc/adr/0030-controller-test-strategy.md`: Related; §3 item 4; §4; §7; §11; §12 item 7; §14;
  Consequences; Open 2.
- `doc/adr/0031-gallery-chart-types.md`: Related; one alternative.
- `doc/phase7/design/parsed-data/spec.md`: §1, §7.2, §7.3, §7.4, §8.2, §8.3.
- `doc/phase7/design/interfaces-values/spec.md`: §0, §1, §3.8, §4.2, §7.5, §8.2, §8.3, §8.6.
- `doc/phase7/design/fixture-runner/spec.md`: §0, §6.2, §8.2, §8.3, §8.5.
- `doc/phase7/design/test-strategy/spec.md`: §0, §1.1, §1.5, §1.6, §1.7, §1.8, §2, §4.2, §6.
- `doc/phase7/design/gallery/spec.md`: §1, §7.

No ADR status line changed. No accepted ADR changed. No file outside `doc/adr/0027`-`0031` and
`doc/phase7/design/` changed.
