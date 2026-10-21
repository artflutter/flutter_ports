# Controller test strategy: judgment

- Panel: "Controller test strategy" of phase 7, step 2 (Design). The synthesis becomes Chart.js ADR
  0030 (proposed).
- Drafts: `draft-fidelity.md` (F), `draft-performance.md` (P), `draft-simplicity.md` (S).
- Decision protocol, in priority order: 1. the behavior that Chart.js ADR 0009 protects; 2.
  performance; 3. the upstream structure (AGENTS.md rule 2); 4. less code of our own.
- Marks in the tables: `++` best, `+` good, `0` equal or not at stake, `-` weaker, `--` a defect.

## 0. Result

- Overall winner: **F (fidelity first)**. It wins questions 1, 2 and 4. It has no defect that
  breaks a protected behavior or an ADR. It has three wrong figures and one comparison rule that
  conflicts with Chart.js ADR 0021 §4 (section 5).
- S wins question 3. P gives the best pixel read of question 2 and the only cross-runtime proof
  that a recorded draw has the element draws.
- Section 6 lists the parts of P and S that the synthesis takes.

## 1. Checks that the judge ran again

| Id | Claim | Command | Result |
|---|---|---|---|
| J1 | F P1b: Node.js without a global `Path2D` gives other line calls than the port | `path2d_probe.mjs <dist> off` and `on`, x64 Node.js v24.12.0 | Confirmed. `off`: 38 calls, `beginPath`, `moveTo`, `lineTo` x 3, `stroke`. `on`: 33 calls, `stroke(Path2D 4 cmds)`. |
| J2 | S has no `Path2D` in its controller generator | `grep -c Path2D` of the S probe `controller_probe.mjs` | 0. The S design has no `Path2D` step. |
| J3 | P P1: a recording context gives the same 879 calls as upstream, 240 of them element draws | Python compare of `js_all_calls.jsonl` with the first 879 lines of `probe/dart_all_calls.jsonl` | Confirmed. Same names in the same order, largest number difference 0, 30 `arc` calls. The 42 other mismatches are only the text form of an empty `setLineDash` list in the probe output. |
| J4 | P P5: the paint over an opaque blue (M3) is exact for `#2050c0`; a read over transparent pixels (M1, M2) is not | `flutter test test/px/pixels_test.dart` in the P probe package | Confirmed. M3: 0 of 262144 pixels differ for `#0000ff` and for `#2050c0`. M1 and M2: 0 of 15311 for `#0000ff`, 2026 of 15311 for `#2050c0`. Red grid leak: 4770 pixels. M3 read 0.9 to 2.9 ms. |
| J5 | A writable `ctx` has no cost against `final` | `ctx_field_bench.exe` of P (AOT) | Confirmed. `final` 1.835 ns, writable 1.770 ns for each element draw. F P3 and S P1 give the same result. |
| J6 | Pure cases of the five pure spec files that move to `@TestOn('vm')` | `grep` of `test(` and `skip:` in `test/specs/` | `core.layouts` 1 (12 tests, 11 skips), `core.ticks` 2, `element.line` 1, the other two 0. F and S are correct. P says 7 for `core.layouts`: wrong. |
| J7 | Duplicate full names in the 7 controller spec files | `doc/upstream/manifest.json` | 0 duplicates. S is correct. The ` #2` rule of F and P does not apply. |
| J8 | Skips that must change from `blocked: controller.*` to a plugin reason | `classification/summary.md` §4 | 0. The 21 legend skips have the plugin reason now. F says 21 cases change: wrong. |

Upstream lines that the judge read at the pin `7169e651`: `core.datasetController.js:257` (`this._ctx
= chart.ctx`), `:712-741` (`draw`, `drawActiveElementsOnTop`), `controller.bar.js:676-677`
(`rects[i].draw(this._ctx)`), `element.line.js:233-236` (`usePath2D`), `core.controller.js:443-447`
(the element classes come from the registry for each new controller), `controller.line.js:140`
(`meta.dataset.updateControlPoints`), `core.interaction.js:27`, `:142`, `:214-215` (the axis `r`
path), `controller.doughnut.js:75`, `controller.polarArea.js:26`, `:204-210`, `element.arc.ts:147`,
`:182`, `:204` (the `spacingMode` values `angular`, `parallel`, `proportional`),
`controller.bar.js:7-17` (`_cache.$bar`), `controller.bar.tests.js:1165-1191`, `:1463-1464`,
`controller.line.tests.js:110-136`, `core.datasetController.tests.js:10-41`. No upstream spec
writes `_ctx`. The comment of `drawCalls` in `scale_chart_common.mjs:913-919` says that the sink
exists only because the Dart field is `final`.

## 2. Question 1: the reference tests of the controllers

| Item | F | P | S | Winner |
|---|---|---|---|---|
| Element draws | Writable `ctx`, swap in a second harness function | `RecordingPlatform` through `config.platform`, no `lib/` change | Writable `ctx`, one `drawCalls` for all reference tests | S |
| Behavior (1) | `++` all calls (by transfer of J3) | `++` all calls (J3) | `++` all calls (by transfer of J3) | tie |
| Performance (2) | `0` (J5) | `0` | `0` | tie |
| Structure (3) | `++` upstream `_ctx` is a plain property | `-` keeps `final`, the reason of the phase 6 sink | `++` | F, S |
| Code (4) | `+` 1 keyword, a second swap function, phase 6 kept | `-` a platform class, a JS flag, and the phase 6 swap stays: two mechanisms | `++` 1 keyword, one `drawCalls`, the JS sink goes; the 8 phase 6 files are generated again (+7.3 %, byte-identical rerun) | S |
| `Path2D` in the generators | `++` with probe P1b (J1) | `++` | `--` absent (J2): the line, radar and scatter `showLine` calls differ between Node.js and the port | F, P |
| Generators and files | one common file, 8 generators, 8 test files at the mapped path | same | same | tie |
| Observations | `++` meta, element props by type, default and active options, dataset options, parsed, stacks, `getLabelAndValue`, `tooltipPosition`, `getMaxOverflow`, `_drawStart`/`_drawCount` | `+` explicit props by type, options, parsed, stacks, scale option subtrees | `-` props are all JS own keys with a primitive value: this couples the test to internal flags (`animated`, `_decimated`, `_pointsUpdated`) | F |
| Option comparison | `-` key order with `orderedEquals`: Chart.js ADR 0021 §4 records two cases where the typed order differs and no protected behavior changes | `++` options as a Map, item lists in order | `+` | P |
| Hit elements | `++` 6 modes x 2 `intersect` x axes `x`, `y`, `xy` and `r` (`core.interaction.js:214`), `includeInvisible`, corners, outside point | `+` 15 queries on 4 points | `-` 12 queries, no axis option | F |
| Steps | `++` data steps on both sides, also `hover` through `triggerMouseEvent`, `splice`, `reset` | `+` data steps | `-` actions found by case name: code on both sides for each action | F |
| Case sets | `+` 86; the text names a bar on a time axis, the bar list does not | `++` 89, also `spacingMode: 'parallel'`, bar on a `timeseries` axis, `drawActiveElementsOnTop: false` | `-` 77, no time scale case: the line twins do not run `_cache.$bar` of a bar on a time axis | P |
| Data format | phase 6 form | `++` measured (P2: no compile cost, walk 4 to 5 times faster than JSON) | phase 6 form | P (evidence) |
| **Question 1** | **winner** | second | third (`Path2D` defect) | **F** |

## 3. Question 2: the theme tests of the phase 7 row

| Item | F | P | S | Winner |
|---|---|---|---|---|
| Test 3 | `+` new generator `theme_charts_reference.mjs`, 8 canonical charts, scale keys from `light_snapshot.json` | `+` the `default` case of each reference file, themed; scale option subtrees; a stale emitted key fails | `++` all 77 reference cases again with the light preset against the same upstream data, colors parsed; probe P4: 0 differences after the parse; no new generator | S, with the scale subtrees of P |
| Test 5 | `++` 4 cases with the real `bar` and `doughnut` in `theme_precedence_reference.mjs`, also the light preset; the existing form | `+` 4 scenarios, same form | `+` 2 cases with hand-written expectations | F |
| Hover | `++` oracle: upstream with the replaced values in `defaults`, the method of the existing radial group (`precedence_test.dart:1550-1570` compares with `themePrecedenceUpstream`); 8 types; a second element and `mouseout` | `+` oracle: the prototype run; 6 types | `-` Dart themed chart against a Dart twin. The draft says that this is the `_tokenReplaced` precedent. It is not: the precedent compares with the upstream run. Good part: the absolute pin `#B40000` (theming.md:132) | F |
| Blue screen read | `+` paint over blue, pure blue, exact (P2) | `++` paint over blue, `toImageSync`, a blue with channels that are not 0 or 255 (`#2050c0`), exact (J4) | `+` premultiplied rule `r == 0`, `g == 0`, `b == a`: valid only for pure blue (J4: the straight read gives 2026 false leaks for another blue) | P |
| Blue screen extras | `++` negative control, automatic draw-call diagnosis of each setter that is not blue, known-leaks list | `+` control, manual diagnosis | `+` control, `defaults` snapshot | F (diagnosis) |
| `defaults` unchanged (theming.md §6) | `++` | `-` not stated | `++` | F, S |
| **Question 2** | **winner** | second | third | **F** |

## 4. Question 3: the lift of the skips

| Item | F | P | S | Winner |
|---|---|---|---|---|
| Order | `++` the wave of the last controller of `modules` | `-` no wave order | `++` same as F | F, S |
| `_lineTwin` | one-line helper change | same | same | tie |
| Pure files | `++` 1, 2, 1 pure cases (J6); also names `element.point_test.dart` for its `auto` group | `--` 7 pure cases in `core.layouts` (J6: 1) | `++` 1, 2, 1 | F, S |
| Counts | `-` "498 of 500" (before decision D1); "21 cases get the plugin reason" (J8: 0) | `+` 503, 21 with D1 | `++` 501 of 503 by probe with D1, 2 `unsupported` | S |
| Lift check | `+` tool 5 "stale block" error: permanent, but more tool code and a scan of `test/port/` literals | `+` temporary `lift_check.py` | `++` temporary `lift_check.py` against `all.json`, tool 5 for the rest; also sees the 57 twins | S |
| Failure rule | `++` probe first; fix in `lib/`; never a new `blocked:` or `n/a:`; `blocked: plugin.<id>` only with a `without:<id>` probe and an `all.json` change | `-` step 3 is unclear about tolerances | `++` probe first; only `diverges:` with a row; a verdict changes only with `compare.mjs` evidence and a phase lead decision | F, S |
| **Question 3** | second | third | **winner** | **S** |

## 5. Question 4: the spec port conventions

| Item | F | P | S | Winner |
|---|---|---|---|---|
| Names | `++` exact; a name part that upstream joins with `+` uses `jsToString` (`controller.bar.tests.js:1464`: `'When barThickness is 20'`, not `20.0`) | `-` the snippet interpolates `$barThickness`: `check:js-semantics` risk | `+` exact; checked 0 duplicates (J7) | F |
| `auto` group | `+` upstream position, tag `fixtures`, depends on Chart.js ADR 0029 | `+` same | `+` same | tie |
| `beforeEach`, `afterEach`, Jasmine `this` | `-` a record class for each group: more code | `++` `late Chart chart` in the group closure | `++` same, `setUp` for a hook without a chart | P, S |
| Spies on methods | `++` a stub subclass in the slot of `meta.data[i]` or `meta.dataset`; one line at the place of `spyOn`; no global state (probe P5) | `++` same form (S4) | `-` a stub subclass in `registry.elements.items` with a flag and `addTearDown`: global state and one more line before `acquireChart` | F, P |
| Array listener spies | listener swap | same | same | tie |
| Jasmine matchers | `++` one shared support library (`jasmineEquals` of jasmine-core 3.99.1, the lockfile version; `objectContaining` for the 13 sites of the 7 files) | `0` | `-` copies of the private `_objectContaining` | F |
| **Question 4** | **winner** | second | third | **F** |

## 6. Claims without evidence and conflicts

- F: `orderedEquals` on option keys conflicts with Chart.js ADR 0021 §4 (two recorded order cases,
  no protected behavior). F P1 is a Node.js run only. The Dart side of the swap form is not
  probed. J3 covers it by transfer, because the element draw code is the same. "21 cases" and
  "498 of 500" are wrong (J8, summary §8). The bar case list has no time axis case.
- P: "7 pure cases in `core.layouts`" is wrong (J6). The draft does not state the `defaults`
  check of theming.md §6. The lift has no wave order.
- S: no `Path2D` (J1, J2): its line, radar and scatter `showLine` reference data would not match
  the port. "No time scale cases" has no evidence for the bar path (`controller.bar.js:7-17`). The
  hover precedent claim is wrong (section 3). The own-key props have no probe on the Dart side.
- No draft breaks a protected behavior or an accepted ADR. The writable `ctx` returns to the
  upstream structure, so Chart.js ADR 0020 §13 asks for no frame figures. J5 and the three drafts
  show no cost.

## 7. The synthesis: F, plus these parts

From S:
1. One `drawCalls` with the element draws for all reference tests, on both sides. The JS sink
   goes. The 8 phase 6 files are generated again in the same change (+7.3 %, byte-identical
   rerun, S P2).
2. Test 3 as the themed twin of each controller reference case, against the same upstream data,
   with the colors parsed only in the themed run. This replaces the new generator of F.
3. The lift procedure: the counts with decision D1, the temporary `lift_check.py` against
   `all.json` and the JSON reporter, and the rule that a verdict changes only with `compare.mjs`
   evidence and a phase lead decision.
4. The absolute hover pin `rgb(200, 0, 0)` to `#B40000` and the `getActiveElements()` check.

From P:
5. The blue screen read: the paint of the canvas over an opaque blue, `toImageSync`,
   `rawStraightRgba`, a blue with channels that are not 0 or 255 (`#2050c0`), exact equality.
6. Options compare as a Map. Lists (parsed items, elements, hits, calls) compare in order.
7. The extra cases: `spacingMode: 'parallel'`, a bar on a `timeseries` axis (with `atNow`),
   `drawActiveElementsOnTop: false` with an active element.
8. The scale option subtrees in the `default` case for test 3, and the stale-key failure from
   `light_snapshot.json`.
9. The hover and test 5 cases go into `theme_precedence_reference.mjs` (one generator change for
   both).
10. The phase 6 generators rerun once with `registerPhase7`. If the output is the same,
    `registerPhase6` stays.
11. The data format and the case granularity of phase 6, with the P2 and P3 figures as the record.

From P and S:
12. Jasmine `this` as `late` variables of the group closure, and `setUp` or `tearDown` for a hook
    that reads no chart.

Keep from F: `Path2D` in `controller_chart_common.mjs` and a shared `Path2D` replay helper; the
observation keys; the hit matrix with the axis `r` and `includeInvisible`; the data steps with
`hover` through `triggerMouseEvent`; the hover oracle of upstream with the replaced values in
`defaults`; the automatic draw-call diagnosis of the blue screen; the slot spies; the
`jsToString` name rule; the shared Jasmine support library (check its path with `check:headers`
and add it to the test allowlist of `check:lib-imports`). The "stale block" error of tool 5 is
optional: the temporary lift check covers phase 7.
