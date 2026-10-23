# Canvas and host cuts plan

- Status: proposed, deferred
- Date: 2026-10-19
- Related: [Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md) (accepted),
  [Chart.js ADR 0013](adr/0013-canvas-model.md), [Chart.js ADR 0014](adr/0014-input-events-and-chart-host.md),
  [Chart.js ADR 0015](adr/0015-text.md), [Chart.js ADR 0016](adr/0016-frame-scheduling.md) (all
  accepted), [performance.md](performance.md), [porting-flow.md](porting-flow.md) §2.2

This plan removes code of the phase 3 canvas layer and of the chart host where Dart or Flutter
already gives the function. It has three cuts and nine work packages. Each work package has one
owner. An owner can take one work package without the history of this plan. All paths are
relative to `packages/flutter_chartjs_port/` unless they start with `apps/` or `third_party/`. The line
numbers are the line numbers on 2026-10-19. Read the file again before an edit, because other
work changes the tree.

## Deferral

The port does not do this plan now ([porting-flow.md](porting-flow.md) §5.1). The revisit point is
after phase 8, before phase 9. Work packages A2 and C2 are done in phase 5 (trigger 1, below).
Until then:
- A change that edits a file that this plan cites updates this plan in the same commit: the file
  and line references, the code inventory (§1.1), the tests that pin the behavior (§2.6, §3.5) and
  the estimates. The cited files are `lib/src/canvas/*.dart`, `lib/src/platform/chart_host.dart`,
  `lib/src/platform/platform.flutter.dart`, `lib/src/helpers/helpers.dom.dart`, the tests of §2.6
  and §3.5, `doc/performance.md`, `doc/parity.md` (the rows of §2.7, §3.7 and §5),
  `doc/porting-flow.md` (§2.2 and the harness table of §3), `doc/adr/0013-canvas-model.md` and
  `doc/adr/0014-input-events-and-chart-host.md` (the lines of §2.7 and §3.7).
- A change that makes a step unnecessary, or adds a new reason for it, says so here.

These triggers bring the plan, or one work package of it, forward:
1. **Phase 5 starts the `acquireChart` harness.** With the current `initCanvas`, the default spec
   canvas of 512 x 512 becomes 512 x 256 (§3.3). Do cut 2 (work packages A2 and C2) then, or give
   the harness a workaround and record it here.
2. **Ported code strokes or clips a path under a skew or a non-uniform scale, or uses a pattern
   shader, on the web.** Do work package W (§2.3) then. Chart.js core does not do this today.
3. **The toolchain pin moves to a stable Flutter release with flutter/flutter#190048, #191014
   and #194139.** Remove the text rotation snap (§4.2).
4. **Flutter batches `drawCircle` calls on Impeller and skwasm.** Measure and remove the circle
   batch (§4.1).

Record each trigger that occurs, and the decision, in this section and in porting-flow.md §5.1.

Triggers that occurred:
- 2026-10-19, trigger 1 occurred: phase 5 starts the `acquireChart` harness. The decision
  protocol of phase 5 compared cut 2 (work packages A2 and C2, option A of §3.3) with a harness
  workaround, for example a 512px style on the default spec canvas. Cut 2 passes the 5 named spec
  cases of §3.6 and gives the 512 x 512 default canvas. A workaround gives only the default size.
  The cases with canvas attributes then need `diverges:` rows. Cut 2 also makes `initCanvas` and
  `releaseContext` line-by-line ports. The decision expected about 10 library lines fewer (the
  estimate of §3.9). The real change added 25 lines net (§3.9), so the fourth priority went
  against cut 2. The first and the third priority still decide for cut 2. The figures of §6.3
  ([performance.md](performance.md) §9) decide the performance criterion. Decision: cut 2. Work
  package W stays deferred, because trigger 2 did not occur. C2 depended on W only because both
  edit `canvas_ui.dart`.

Changes to the cited files:
- 2026-10-19, the rounded rectangle fast paths ([porting-flow.md](porting-flow.md) §1.1,
  [differences.md](differences.md) `adapt-rounded-rect-path` and `adapt-bar-clip`). They add
  `roundRect` to `lib/src/canvas/canvas.dart`, `canvas_ui_path.dart` and `canvas_ui.dart`, and
  the `drawRRect`, `drawDRRect` and `clipRRect` fast paths. They add rows to `doc/parity.md`. §1.1
  lists the new code as kept code. The file, line and row references of this plan are updated.
  §2.6 names the new test file. The estimates do not change: the new code is not in the parts that
  the cuts remove. No trigger occurred. The fast paths take no `Path.transform`, no
  `extendWithPath`, no `ImageShader` and no `_m4`. A `roundRect` under a skew or a rotation adds
  the HTML segments through `_addArc`, so cut 1 changes its arcs under a skew too.
- 2026-10-19, work package A2 (§3.5). It adds the group "display size and bitmap stretch" (7
  tests) to `test/port/platform/chart_host_test.dart`, after the group "resize". The file has 40
  tests now. The library does not change. The lines 126, 149 and 172 of the test file do not move.
  The change updates §3.5, the test estimates of §3.9 and §5, and the `parity.md` row of
  `chart_host_test.dart`. The `parity.md` row numbers do not change.
- 2026-10-19, work package C2 (§3.4, §3.10), in phase 5. It changes `lib/src/canvas/canvas.dart`,
  `canvas_ui.dart`, `lib/src/platform/chart_host.dart` and `platform.flutter.dart`. It changes the
  tests of §3.5 and two test fakes of `HTMLCanvasElement`. It changes Chart.js ADR 0013, Chart.js
  ADR 0014, porting-flow.md (§2.2, §2.7, the harness table of §3 and §5.1) and 7 rows of
  `parity.md`. The library has 134 lines fewer and 159 lines more (net +25, the estimate was -10).
  The `canvas_ui.dart` lines after line 129 move by +20 to +25. The `canvas.dart` lines after
  line 347 move by +16. This plan gives the new line numbers. §3.1 keeps the lines of commit
  69f9d97, the code before C2. The `parity.md` row numbers do not change.
- 2026-10-19, the C2 performance acceptance (§5, §6.3). It adds section 9 to `doc/performance.md`
  and changes its scope line and its section 7. The section numbers that this plan cites do not
  change.
- 2026-10-19, the `bars` 1000 miss of the C2 acceptance on the Pixel 8a. Section 9.5 of
  `doc/performance.md` gives an A/A control and 12 more pairs. On two identical APKs, the 3-pair
  rule of §6.3 also misses. Over 21 pairs, the frame rate and the raster time have no measured
  change. The draw time is 0.18 ms longer, in code that C2 does not change. Decision: cut 2 stays
  (priority 1, the upstream behavior). No library file changed. The line numbers of this plan do
  not change.
- 2026-10-20, the iPhone 17 Pro smoke pairs of the C2 acceptance (§6.3). Both pairs pass, at the
  120 Hz limit on both sides (`doc/performance.md` §9.2 and §9.3). No library file changed.
- 2026-10-19, the gate 5 ADRs of phase 5 in porting-flow.md (§2 table, §2.9, the new §2.16-§2.18).
  The lines of porting-flow.md after line 139 move by +7, and the harness table of §3 moves by +54.
  §3.7 gives the new line numbers. Chart.js ADR 0022 (proposed) also plans two changes of
  `lib/src/platform/chart_host.dart`: the first resize notification at the next layout, and a
  microtask checkpoint for an append or a removal. The work that does them updates this plan.
- 2026-10-19, the two host changes and the canvas attributes of
  [Chart.js ADR 0022](adr/0022-chart-test-harness.md) (proposed) §4 and §10, in phase 5.
  `lib/src/platform/chart_host.dart` gets the first `ResizeObserver` notification at the next
  layout of the host and the mutation checkpoint `flushCanvasMutations`. It has 78 lines more and
  14 lines fewer (966 lines). `lib/src/canvas/canvas_ui.dart` gets the reflection of the `style`
  attribute, `cssText` and the string attributes. It has 131 lines more and 8 lines fewer (1767
  lines). The lines of `chart_host.dart` after line 26 move by +6 to +64. The lines of
  `canvas_ui.dart` after line 96 move by +5 to +123. §1.1, §2.3, §2.5 and §5 give the new line
  numbers. §3.1 keeps the lines of commit 69f9d97. §3.9 and §3.10 keep the lines of the tree
  after C2. `chart_host_test.dart` gets 9 tests (50 tests), and `canvas_ui_test.dart` gets the
  group "the style attribute and the other attributes" (5 tests). The test "a later resize with
  the container height keeps the ratio" of §3.2 and §3.5 now pumps two frames. The first
  notification comes at the next layout, and its throttled resize in the frame after it. The
  test still pins the ratio. Phase 5 adds `parity.md` rows above the rows of this plan. §2.7, §3.7
  and §5 give the new row numbers. The inventory gets two rows. No trigger occurred. The estimates
  do not change, because the cuts do not remove the new code.
- 2026-10-20, the phase 5 docs in porting-flow.md (§1 step 1, §1.1, §2.9, §2.15, §3 and §4). They
  change no text of §2.2 and §2.7, and no cited row of the harness table of §3. The harness table
  gets a row for `dom.dart`, and its `src/context.js` row and `n/a` row change. The lines of §2.2
  and §2.7 move by +10. The cited rows of the harness table move by +19. §3.7 gives the new line
  numbers. No trigger occurred.
- 2026-10-20, the integration of the phase 5 port. It changes porting-flow.md and `parity.md`. In
  porting-flow.md, it changes §1 step 5, §2, §2.5, §2.10, §2.14, §2.16, §3, §4 and §5. The text
  of §2.2 and §2.7 does not change. The
  harness table of §3 marks the `src/matchers.js` row as done, and the `src/utils.js` row names
  the two helpers that exist. The line of §2.2 moves by +10, the lines of §2.7 by +14, and the
  cited rows of the harness table by +30. §3.7 gives the new line numbers. §3.6 gives the new skip
  reasons of its cases. The new rows of `parity.md` are at the end of the port-only table, so no
  cited row number moves. No library file that this plan cites changed. No trigger occurred.
- 2026-10-20, the integration of the harness step, the gallery and tool 6 in porting-flow.md (§1
  steps 3, 5 and 7, §2.9, §3, §4 and §5) and in `parity.md`. The text and the lines of §2.2 and
  §2.7 do not change. §2.9 gets one bullet on the ticker mode. Thus the cited rows of the harness
  table move by +5. The `src/utils.js` row now describes the harness of Chart.js ADR 0022, and a
  new `src/index.js` row follows it. §3.7 gives the new line numbers. Tool 6 now writes
  `parity.md`. Its first run moves two rows inside the chartjs-test-utils table and adds two
  port-only rows at the end. The theme precedence tests added three port-only rows (lines
  439-441). No cited row number of `parity.md` moves. §3.5 and §3.6 give the real spec results of
  the harness step. No library file that this plan cites changed. No trigger occurred.
- 2026-10-20, the fixes of the adversarial review of phase 5. §2.9 of porting-flow.md gets two
  more lines. Thus the cited rows of the harness table of §3 move by +2 (§3.7). The text of the
  `src/matchers.js` row changes. The text and the lines of §2.2 and §2.7 do not change. The gallery
  files of A3 change: `stress_demo.dart` gets the case `CALL=animate` and `events: []` for the mode
  `chart`, and `main_stress.dart` gets two test parameters. The note on A3 names the mode `chart`.
  The CSS subset of `dom.dart` now hides the whole subtree of `display: none`. It also gives a
  canvas with one px style its CSS display size. §3.5 gives the true test lines of
  `canvas_ui_test.dart` and the new web test of `helpers.dom`. §3.6 gives the real result of
  three event cases and of the `data: []` case. The new rows of `parity.md` are at the end of the
  port-only table, so no cited row number moves. No library file that this plan cites changed. No
  trigger occurred.
- 2026-10-20, the font weight review of `lib/src/canvas/canvas_ui_text.dart`. A probe ran in
  Chromium 155 on Linux with the system Liberation Sans. It gave the regular face for the weights 1
  to 549.99 and the bold face for 550 to 1000. The canvas layer gives the same faces. Thus the mapping of a
  weight to the nearest `ui.FontWeight` stays. The review of the fix found that the keywords
  before the size did not follow Chromium. Now `parseCanvasFont` reads a weight as a CSS number
  (`+500` and `5e2` parse, `500.` does not), accepts each keyword one time with at most 4
  keywords, and reads the angle after `oblique` (`oblique 20deg`, a style that
  `helpers.options.ts:8` accepts). `canvas_ui_text.dart` has 66 lines more and 12 lines fewer
  (507 lines). The new test file `test/port/canvas/canvas_ui_text_test.dart` (8 tests) pins the
  faces and the keywords. This plan cites no line of `canvas_ui_text.dart`, and the cuts do not
  remove its code. Thus the references, the inventory (§1.1), the tests of §2.6 and §3.5 and the
  estimates do not change. No trigger occurred.
- 2026-10-20, the phase 6 docs in porting-flow.md (§2, §2.3, §2.5, §2.10, §2.19, §3 and
  §5). The text of §2.2 and §2.7 and of the cited rows of the harness table of §3 does not
  change. The line of §2.2 moves from 210 to 220, the lines of §2.7 from 294-297 to 312-315, and
  the cited rows of the harness table from 583-584 to 610-611. §3.7 gives the new line numbers.
  The new rows of `parity.md` are at the end of the port-only table, and the phase 6 rows of the
  upper tables replace rows that were there, so no cited row number moves. The lines of the
  groups of `canvas_ui_test.dart` in §2.6 were older than the phase 5 tests of the attributes.
  §2.6 now gives the lines of the tree (`transforms` 400-482, `paths` from 667, `rotated text`
  1251-1293, `circle batch` from 1522). No library file that this plan cites changed in phase 6,
  except `canvas_ui_text.dart` (the entry above). No trigger occurred.
- 2026-10-20, the phase 6 gallery. Three gallery files of A3 change. `main_stress.dart` gets the
  mode `axes` with the defines `SCALE`, `YSCALE` and `AUTOSKIP`. `stress_demo.dart` gets the mode
  `axes`: a real chart on the scales of phase 6 (`lib/demo/stress_axes.dart`). The config of the
  mode `chart` moves to the new file `lib/demo/stress_chart_config.dart`. The loop test of
  `stress_elements_test.dart` skips the two modes that run a chart (`StressMode.runsChart`).
  `stress_chart_test.dart` and `stress_axes_test.dart` test these modes. The note on A3 names the
  mode `axes`. The work of A3 (`POINT_STYLE`, the arc scenario and the baselines of §6.3) does not
  change. `demo_chart.dart`, which §3.1 cites, gets `getDataVisibility`. `DemoChart` keeps its
  default `UiCanvasElement()`, so §3.1 does not change. Thus the references and the estimates do
  not change. No trigger occurred.
- 2026-10-20, the metrics cache of `lib/src/canvas/canvas_ui_text.dart` (performance.md §13). The
  bound of the metrics cache goes from 2048 to 32768 entries. The eviction of the metrics cache
  and of the paragraph cache removes the oldest quarter in one pass. The measured widths do not
  change. `canvas_ui_text.dart` has 538 lines. `canvas_ui_text_test.dart` gets the tests of the
  cache (11 tests). This plan cites no line of `canvas_ui_text.dart`, and the cuts do not remove
  its code. Thus the references, the inventory (§1.1), the tests of §2.6 and §3.5 and the
  estimates do not change. No trigger occurred.
- 2026-10-20, the commit pin of Chart.js (`v4.5.1+7169e651`), the port of chartjs/Chart.js#12238
  in `lib/src/elements/element.arc.dart`. It changes `test/port/elements/element.arc_test.dart`,
  which §3.5 cites for its `_Canvas` fake. The fake does not change. The test file gets the tests
  of the new property `circular` and 42 new reference cases of `draw`. `pathArc` gets the option
  `spacingMode`. Its default `'angular'` adds one `asin` and one `sin` to each `pathArc` call with
  a spacing.
  The `arcs` scene of A3 (`stress_demo.dart`) has a spacing of 2. Thus its wedges change a little,
  and the `arcs` figures of performance.md come from the code before the pin. The new
  `pathFullCircle` draws a full circle with `selfJoin` as one full circle, a `moveTo` and one full
  counterclockwise circle. These calls go through `arc` and `_nativeArc` as the other arcs do. A
  scratch probe on the `dart:ui` canvas filled the ring and kept the hole empty. This plan cites
  no line of the two files, and the cuts do not remove their code. Thus the references, the
  inventory (§1.1), the tests of §2.6 and §3.5 and the estimates do not change. No trigger
  occurred.
- 2026-10-20, the commit pin of Chart.js (`v4.5.1+7169e651`), the port of chartjs/Chart.js#12142
  in `lib/src/helpers/helpers.dom.dart`. `retinaScale` gives the canvas the `Math.floor` of the
  device size and compares the canvas with these integers. Thus a fractional device size that
  does not change gives `false`, and `_resize` stops. The tests of §3.5 change:
  `helpers.dom_test.dart` has 10 `retinaScale` tests and `helpers.dom_web_test.dart` has 5. The
  line citations in `demo_chart.dart`, `canvas_demo.dart` and `stress_demo.dart` name the lines
  at the pin. These changes are in comments, so no cited line moves (`canvas_demo.dart:125`
  stays). This plan cites no line of `helpers.dom.dart`, and the cuts do not remove its code.
  Thus the references, the inventory (§1.1) and the estimates do not change. No trigger occurred.
- 2026-10-21, the integration of wave 2 of phase 7. `lib/src/elements/element.arc.dart` adds the
  options of `inRange` (`rAdjust`) and of `getCenterPoint` with the JS `+` (`jsAdd`), as
  upstream. `test/port/elements/element.arc_test.dart`, which §3.5 cites for its `_Canvas` fake,
  gets two groups `string options join in the JS +`. The fake does not change, and the draw path
  of the arc does not change. porting-flow.md gets text in §2.21, §3 and §5. The text of §2.2, of
  §2.7 and of the cited rows of the harness table of §3 does not change. The cited rows of the
  harness table are now at lines 690-691 (§3.7 gives 610-611, the lines of phase 6). The
  `parity.md` row numbers of this plan do not move: the new controller rows replace rows that
  were there, and the new port-only rows are at the end of the table. The two `helpers.dom` event
  cases of §3.6 ("Should not return NaN with a custom event" and "consistent results") pass since
  the lift of wave 1 (L1). This plan cites no line of `element.arc.dart`, and the cuts do not
  remove its code. Thus the references, the inventory (§1.1), the tests of §2.6 and §3.5 and the
  estimates do not change. No trigger occurred.
- 2026-10-21, the integration of wave 3 of phase 7. `apps/chartjs_gallery/lib/demo/demo_chart.dart`,
  which §3.1 cites, gets the signature `toggleDataVisibility(Object? index)` (Chart.js ADR 0028
  §6).
  `DemoChart` keeps its default `UiCanvasElement()`, so §3.1 does not change.
  `lib/src/core/core.controller.dart` changes only `toggleDataVisibility`, not `_resize`. The lift
  of wave 2 (L2) gave the two `platform.dom` cases of §3.6 their bodies: "default chart aspect
  ratio" (the doughnut controller) and "event handling" (the line controller) pass now.
  `test/port/core/core.controller_test.dart` gets one test in the group `getDataVisibility`. The
  group "the platform.dom spec cases" does not change. porting-flow.md gets text in §2.14, §2.19,
  §2.21, §3 and §5. The text of §2.2, of §2.7 and of the cited rows of the harness table of §3 does
  not change. §2.2 stays at line 220 and §2.7 at line 307. The cited rows of the harness table are
  now at lines 697-698. The new rows of `parity.md` (pie, scatter and the scatter spec) are in the
  upper tables and the port-only table. The `parity.md` rows that this plan cites do not change. Thus
  the references, the inventory (§1.1), the tests of §2.6 and §3.5 and the estimates do not change.
  No trigger occurred.
- 2026-10-21, Chart.js ADR 0032 (proposed) and Chart.js ADR 0033 (accepted).
  `lib/src/elements/element.arc.dart` calls `jsSin` and `jsCos` in `getCenterPoint` (lines
  1148-1149) and gets `js-ok` comments on 14 draw lines. The draw path of the arc does not change:
  its calls stay on `dart:math`. `test/port/elements/element.arc_test.dart`, which §3.5 cites for
  its `_Canvas` fake, gets two `getCenterPoint` reference cases and the group `the half angles of
  the sin ties`. The fix of the trig review (R7) changes only the comment of that group. The fake
  does not change. porting-flow.md gets text in §2, §2.19, §3 and §4. This change does not edit the
  text of §2.2, of §2.7 and of the cited rows of the harness table of §3. The entry of the ADR
  numbers and statuses below records the other edits of §2.2 and §2.7. In the work tree after the
  doc fixes of step 4, §2.2 is at line 236, §2.7 at line 326, and the cited rows of the harness
  table at lines 747-748. This plan cites no line of `element.arc.dart`, and the cuts do not remove
  its code. Thus the references, the inventory (§1.1), the tests of §2.6 and §3.5 and the estimates
  do not change. No trigger occurred.
- 2026-10-21, step 4 of phase 7 (F-int, Chart.js ADR 0029, proposed). porting-flow.md gets text
  in §1 step 6, §2 (the new subsection 2.22, the row and the text of Chart.js ADR 0033 and the
  text of Chart.js ADRs 0032, 0034 and 0035), §3 (the harness rows of `src/index.js`, `dom.dart`
  and `src/fixture.js`, the row "Fixture smoke tests" and "Fixture selection"), §4, §5 (the phase
  7 row) and §6. This change does not edit the text of §2.2, of §2.7 and of the cited rows of the
  harness table of §3 (`src/matchers.js` and `src/utils.js`). In the work tree after the doc fixes
  of step 4, §2.2 is at line 236, §2.7 at line 326, and the cited rows of the harness table at
  lines 747-748. `doc/performance.md` §13.8 gets the trigger of its frame figures (Chart.js ADR
  0032, Open 2): an item of step 7 of phase 7. One line of §6 and one line of §13.5 get a new
  wrap. Their content does not change.
  `packages/chartjs_test_utils/lib/src/dom.dart` gets `pumpFrame` and a `pumpFrames` that lets
  only one loop pump at a time. The CSS subset, the harness body and the forced layout do not
  change. The 20 spec files with a fixture group call the fixture runner, and
  `test/specs/helpers.canvas_test.dart` gets the empty group `auto`. `element.point_test.dart`
  moves to the VM. This plan cites none of these lines, and the cuts do not remove their code.
  Thus the references, the inventory (§1.1), the tests of §2.6 and §3.5 and the estimates do not
  change. No trigger occurred.
- 2026-10-21, the ADR numbers and statuses. A parallel session moved the citations of three ADRs:
  Chart.js ADR 0009 to Chart.js ADR 0034, Chart.js ADR 0010 to Chart.js ADR 0032 and Chart.js ADR
  0011 to Chart.js ADR 0035. These three new ADRs are proposed. The porting lead accepted Chart.js
  ADRs 0013-0023 (2026-10-21). The Related line of this plan and §2.7, §3.2 and §3.7 now cite
  Chart.js ADR 0034 in place of Chart.js ADR 0009. The Related line gives Chart.js ADRs 0013-0016 as
  accepted. In porting-flow.md, the arc-math bullet of §2.2 cites Chart.js ADR 0034 in place of
  Chart.js ADR 0009. The first sentences of §2.2 and §2.7 no longer call Chart.js ADRs 0013 and 0014
  proposed. The other text of §2.2 and §2.7 does not change. One bullet of porting-flow.md §2.22
  gets a new wrap, so the cited rows of the harness table moved from lines 746-747 to lines 747-748.
  Their text does not change. §2.7 and §3.7 of this plan tell the owner to edit Chart.js ADRs 0013
  and 0014 in place. These ADRs are accepted now. Thus the owner of each of these work packages
  writes a new ADR that supersedes the changed decision, and does not edit the accepted ADR. The
  references, the inventory (§1.1), the tests of §2.6 and §3.5 and the estimates do not change. No
  trigger occurred.
- 2026-10-21, the acceptance of Chart.js ADRs 0032, 0034 and 0035. The Windows leg of CI run
  39569626698 passes the hit cases of Chart.js ADR 0032, Open 1. The porting lead accepted the
  three ADRs. The Related line of this plan gives Chart.js ADR 0034 as accepted. porting-flow.md
  gets text in §2 (the paragraph and the table), §2.3, §2.13, §3, §4 and §6. This change does not
  edit the text of §2.2, of §2.7 and of the cited rows of the harness table of §3. No line of
  porting-flow.md moves. The `parity.md` rows that this plan cites do not change. Thus the
  references, the inventory (§1.1), the tests of §2.6 and §3.5 and the estimates do not change. No
  trigger occurred.
- 2026-10-21, the toolchain pin moves from Flutter 3.44.9 to the stable release 3.47.7 (Dart
  3.13.5). The pubspecs require Dart `^3.13.0` and Flutter `>=3.47.0`. The 3.13 formatter and
  `dart fix` change these cited files: `lib/src/platform/chart_host.dart` gets one blank line
  after line 69, so its lines after line 69 move by +1 (967 lines). §1.1 gives the new line
  numbers. `apps/chartjs_gallery/lib/demo/canvas_demo.dart` loses the import of `dart:async` at
  line 5, so `UiCanvasElement(width: 32, height: 32)` moves from line 125 to line 124. §3.1 gives
  the new line and the line of 69f9d97. `lib/src/canvas/canvas_ui.dart` changes line 150 (`cssText`) in place, so no line
  moves. `apps/chartjs_gallery/lib/demo/stress_chart_config.dart` gets one line more, and this
  plan cites no line of it. 3.47.7 has none of the three fixes of the text rotation snap (§4.2).
  Thus trigger 3 did not occur. The probes of §1, §2.2 and the figures of performance.md stay the
  results on Flutter 3.44.9: no probe of this plan ran again on 3.47.7. porting-flow.md gets text
  in §2.3, §2.12 and §3. One bullet of §2.3 (line 283) loses one line, so the lines after it move
  by -1: §2.7 moves from line 329 to line 328. §2.12 gets 6 lines more. §2.2 stays at line 239.
  The cited rows of the harness table (`toBeChartOfSize` of `src/matchers.js`, and `src/utils.js`)
  move from lines 756-757 to lines 761-762. The text of §2.2, of §2.7 and of these rows does not
  change. The phase 7 review (`b2049ca`) moved §2.2 from line 236 to line 239, §2.7 from line 326
  to line 329 and the cited rows from lines 747-748 to lines 756-757, and this list has no entry
  for it. Thus the figures 236, 326 and 747-748 of the three entries above are the lines before
  that review. §3.7 now gives the lines of the current porting-flow.md: §2.2 at lines 248-249,
  §2.7 at lines 341-344 and the harness rows at lines 761-762. The inventory (§1.1), the tests of
  §2.6 and §3.5 and the estimates do not change.
- 2026-10-22, the sole shape of a shape pair in step 7 of phase 7 ([performance.md](performance.md)
  §13). `lib/src/canvas/canvas_ui.dart` gets `_soleShape` and `debugSoleShape`. `fill` of a path
  of two `rect` or `roundRect` commands, one of them with a width or a height of 0, draws the
  other shape alone with `drawRect` or `drawRRect`, for both fill rules: the border ring of a bar
  that is narrower than its two borders. `_ring` takes the pair as a parameter. The file has 36
  lines more (1803 lines). Its lines 544 to 1284 move by +12, its lines 1297 to 1300 by +20 and
  its lines after line 1319 by +36. §1.1, §2.3, §2.5 and §5 give the new line numbers. The inventory row of the fast paths of
  the context grows from 72 to 109 lines. `test/port/canvas/canvas_ui_round_rect_test.dart` gets
  two tests. The cuts do not remove the new code, so the estimates do not change. No trigger
  occurred.
- 2026-10-22, the end of phase 7 (step 8). porting-flow.md gets text only in the §5 rows of
  phases 5, 6 and 7. No line of porting-flow.md moves, and the text of §2.2, of §2.7 and of the
  cited rows of the harness table of §3 does not change. `doc/performance.md` §13.6 loses the
  path of the working files in its first paragraph and gets the bullet "Web" in its method list.
  The A/B table gets the column "Web series". Its intro, its macOS column and the item
  `bar-ring-zero-inner` below it get the figures of the ABBA series. The before figures get a description in place of the name of a working
  file. The lines after line 2245 move by -1, and the lines after line 2287 move by +3 to +10
  (the file has 10 lines more). No cited section number changes. The `parity.md` rows that this
  plan cites do not change, and no row of `parity.md` moves. §2.7 and §3.7 of this plan no longer
  call Chart.js ADRs 0013 and 0014 proposed (see the entry of the ADR numbers and statuses
  above). The references, the inventory (§1.1), the tests of §2.6 and §3.5 and the estimates do
  not change. No trigger occurred.
- 2026-10-22, the input host of phase 8
  ([Chart.js ADR 0037](adr/0037-legend-and-tooltip-input-path.md), proposed, sections 6 to 11).
  `lib/src/platform/chart_host.dart` loses the `TapGestureRecognizer`. It gets the touch
  boundary events, the DOM click rule of a mouse, the tap rule with the long press (`_TouchTap`),
  and the compatibility mouse with its global pointer route (`_takeMouse`, `_releaseMouse`,
  `_route`). The library doc of the input changes too. The file has 1276 lines (309 lines more).
  Its lines 60 to 293 move by +20, its lines 294 to 330 by +20 to +23, and its lines 331 to 724
  by +21. §1.1 gives the new line numbers. The new code is input code, not sizing or
  paint code: the inventory gets no row, and the cuts do not remove it.
  `test/port/platform/chart_host_test.dart` gets the group 'compatibility mouse' (21 tests) and
  the two tests of a mouse move and an exit in one frame. Its two tests of a tappable ancestor
  change to 'a tappable ancestor and the chart both get the tap'. The file has 73 tests (§3.5).
  The tests of §3.5 do not change. `lib/src/platform/platform.flutter.dart` and
  `lib/src/helpers/helpers.dom.dart` change only comments in place (the citation of Chart.js
  ADR 0037), so no line of them moves. The `parity.md` rows that this plan cites do not move.
  The estimates do not change. No trigger occurred.
- 2026-10-22, the prelude of wave 1 of phase 8 (Chart.js ADR 0038 §6, proposed).
  `apps/chartjs_gallery/lib/demo/demo_chart.dart`, which §3.1 cites, gets the field `titleBlock`
  of `types.Chart` and the `data` of its configuration (`types.ChartConfiguration.data`).
  `DemoChart` keeps its default `UiCanvasElement()`, so §3.1 does not change.
  `lib/src/core/core.controller.dart` gets only the field `titleBlock`, not a change of
  `_resize`. `lib/src/core/core.layouts.dart` (`removeBox` takes a `LayoutItem?`) and
  `lib/src/types/index.dart` are not cited. This plan cites no line of these files. Thus the
  references, the inventory (§1.1), the tests of §2.6 and §3.5 and the estimates do not change.
  No trigger occurred.
- 2026-10-22, the end of wave 1 of phase 8. `doc/porting-flow.md` §2.7 names Chart.js ADR 0037
  (proposed) in its heading, its first lines and the row 2.7 of the §2 table, and its input
  bullet gets two lines more (no claim in the gesture arena, the compatibility mouse). Thus the
  lines of porting-flow.md after line 338 move by +2: §3.7 now gives §2.7 at lines 343-346 and
  the harness rows at lines 763-764. The text of §2.2 (lines 248-249) and of the cited rows does
  not change. The §5 row of phase 8 and the open question of #7738 in §7 cite Chart.js ADR 0037.
  `doc/parity.md` gets the new status texts of wave 1 (the plugin rows, the citation of Chart.js
  ADR 0037 in the rows of `platform.flutter.dart` and `chart_host.dart`, the test count of
  `chart_host_test.dart`) and new port-only rows of the plugin tests. Tool 6 writes them; the
  rows that this plan cites do not move. The row of `chart_host.dart` gets new input text only.
  `lib/src/core/core.controller.dart` changes
  only three comments in place (the citation of Chart.js ADR 0037), so no line of it moves. The
  references, the inventory (§1.1), the tests of §2.6 and §3.5 and the estimates do not change.
  No trigger occurred.
- 2026-10-22, the prelude of wave 2 of phase 8 (Chart.js ADR 0038 §6 and Chart.js ADR 0040 §4,
  both proposed). `apps/chartjs_gallery/lib/demo/demo_chart.dart`, which §3.1 cites, gets the
  field `legend` (it was a getter that gave `null`) and the no-op methods `hide` and `show` of
  `types.Chart`. `DemoChart` keeps its default `UiCanvasElement()`, so §3.1 does not change.
  `lib/src/core/core.controller.dart` gets only `@override` lines (`ChartMeta.visible`, `hide`,
  `show`), not a change of `_resize`. `lib/src/types/index.dart`, `lib/src/core/core.scale.dart`,
  `lib/src/core/core.datasetController.dart` and `lib/src/elements/element.line.dart` get new
  interface members or `@override` lines. This plan cites no line of these files (filler spec
  risk R8). Thus the references, the inventory (§1.1), the tests of §2.6 and §3.5 and the
  estimates do not change. No trigger occurred.
- 2026-10-22, the end of wave 2 of phase 8. `doc/performance.md` gets section 14 (the filler
  figures of Chart.js ADR 0040) at its end and one sentence more in its scope list. Thus its lines
  after line 14 move by +1. This plan cites sections of `doc/performance.md`, not its lines, and
  no cited section number changes. `doc/parity.md` gets the rows of the plugins of wave 2: the
  rows of the upstream tables change in place, and the new port-only rows come after line 533.
  The `parity.md` rows that this plan cites do not move. The references, the inventory (§1.1),
  the tests of §2.6 and §3.5 and the estimates do not change. No trigger occurred.
- 2026-10-22, the prelude of wave 3 of phase 8 (Chart.js ADR 0038 §6 and Chart.js ADR 0039 §14,
  both proposed). `apps/chartjs_gallery/lib/demo/demo_chart.dart`, which §3.1 cites, gets the
  field `tooltip` and the method `getElementsAtEventForMode` (it gives an empty list) of
  `types.Chart`. `DemoChart` keeps its default `UiCanvasElement()`, so §3.1 does not change.
  `lib/src/core/core.controller.dart` gets only the field `tooltip` and an `@override` line on
  `getElementsAtEventForMode`, not a change of `_resize`. `lib/src/types/index.dart` and
  `lib/src/core/core.datasetController.dart` get new interface members or `@override` lines. This
  plan cites no line of these files. Thus the references, the inventory (§1.1), the tests of
  §2.6 and §3.5 and the estimates do not change. No trigger occurred.
- 2026-10-23, the end of wave 3 of phase 8 (Chart.js ADR 0039, proposed).
  `lib/src/core/core.controller.dart` gets one `DIVERGES` marker line in `setActiveElements`, not
  a change of `_resize`. `doc/parity.md` gets the rows of the tooltip plugin: the rows of the
  upstream tables change in place, and the new rows come after line 445. The `parity.md` rows
  that this plan cites (lines 378-422) do not move. `lib/src/helpers/helpers.core.dart` changes
  `merge`, `merger` and `mergeIf`, not `isNullOrUndef`. The references, the inventory (§1.1), the
  tests of §2.6 and §3.5 and the estimates do not change. No trigger occurred.
- 2026-10-23, wave 4 of phase 8 (Chart.js ADR 0041 §7, Chart.js ADR 0031 Open). The gallery
  files of A3 (`stress_demo.dart`, `main_stress.dart`) do not change.
  `lib/demo/stress_chart_config.dart` gets `stressPluginOptions` (`plugins.legend: false`), and
  `stressChartConfig` and `stressAxesConfig` (`lib/demo/stress_axes.dart`) put it in their
  options. Thus the modes `chart` and `axes` and the frameless benchmark keep the chart area of
  phase 7. The filler of `registerables` fills the radar of the mode `chart`. This plan cites no
  line of these files. `stress_chart_test.dart` gets one test for each chart type.
  `lib/src/core/core.controller.dart` renames the field `_lastEvent` to `lastEvent` with
  `@internal`, not a change of `_resize`. `doc/parity.md` gets new port-only rows after line 422
  (the input reference test of the chart host). The `parity.md` rows that this plan cites (lines
  378-422) do not move. The references, the inventory (§1.1), the tests of §2.6 and §3.5 and the
  estimates do not change. No trigger occurred.

## 1. Why

The maintainer asked to cut the code that implements again what Dart or Flutter already gives.
Phase 3 ports Chart.js line by line onto a Canvas 2D layer over `dart:ui` (porting-flow.md §2.2).
That decision stays. This plan does not rewrite the drawing code for `dart:ui` directly. Inside
that decision, three areas were candidates:

1. **Cut 1.** The arc math and the 2 x 3 affine class `UiTransform` (first estimate: 450 lines).
2. **Cut 2.** The chart host sizing that emulates a CSS replaced element (first estimate: 400
   lines).
3. **Cut 3.** The circle batch and the 2 degree text rotation snap. These stay. The plan records
   only their removal criteria.

Three read-only analyses and scratch probes (Flutter 3.44.9, on the VM, in Chrome with CanvasKit
and in Chrome with skwasm) measured each part. The first estimates were too high. Cut 1 removes
about 45 lines of library code net. Cut 2 removes about 10 lines net, but it fixes the size of the
default spec canvas before phase 5 depends on it. Work package C2 did cut 2 in phase 5. The
library got 25 lines more net, because the attribute model and the interface need more lines than
the estimate (§3.9).

### 1.1 Code inventory

| Part | File:lines | Lines | Flutter API that replaces it | Verdict |
|---|---|---:|---|---|
| `UiPathBuilder._bezierArc` (cubic Béziers for a skew, a non-uniform scale with rotation, a rotated ellipse) | `lib/src/canvas/canvas_ui_path.dart:882-935` | 54 | `ui.Path.arcTo` in user space, then `extendWithPath(arc, Offset.zero, matrix4: m)` | **Remove** (cut 1) |
| `_addArc`, axis-aligned branch with the reflection cases `a < 0`, `d < 0` and both | `canvas_ui_path.dart:806-836` | 31 | The same matrix path | **Remove** (cut 1) |
| `_addArc`, similarity branch (rotation, uniform scale, mirror) | `canvas_ui_path.dart:788-805` | 18 | It already calls `ui.Path.arcTo` in bitmap space | **Keep**. It is the hot path: `retinaScale` and `translate` give a similarity. |
| `_nativeArc` (half arcs for a sweep over pi, sweep 0, `forceMoveTo`) | `canvas_ui_path.dart:840-880` | 41 | None. A sweep of `2 * pi - 1e-12` rounds to 360 degrees and `arcTo` adds nothing. | **Keep**. The matrix path shares its half split. |
| `canvasArcSweep` (Chromium `AdjustEndAngle`) | `canvas_ui_path.dart:243-258` | 16 | None. Skia takes the sweep modulo 360 degrees. | **Keep**. The full sweeps change behavior. |
| `UiTransform` (a-f, the operations, `mapX`/`mapY`, the flags, the matrix writers) | `canvas_ui_path.dart:41-241` | 201 | None. `dart:ui` has no affine type. `Canvas.getTransform` needs a live recording and allocates. `vector_math` `Matrix4` is 4 x 4 and not a dependency. | **Keep** |
| Current point and subpath start (`_lastX`, `_startX`, `hasSubpath`) | `canvas_ui_path.dart:298-305`, `:385-422` | ~25 | None. `ui.Path` has no current point. | **Keep** |
| DOM `arcTo` (tangent arc) math | `canvas_ui_path.dart:705-768` | ~60 | None. `ui.Path.arcToPoint` is the SVG end-point arc. | **Keep**. It calls `_addArc`. |
| `rect()` with four mapped corners | `canvas_ui_path.dart:490-523` | 33 | None. `addRect` sorts the corners and changes the winding when `w < 0` or `h < 0`. | **Keep** |
| Pending full circle (`singleCircle`, `_materializeCircle`) | `canvas_ui_path.dart:278-296`, `:353-383`, `:649-671` | ~50 | None | **Keep** (cut 3) |
| `roundRect` of the path builder: `UiPathBuilder.roundRect` (one `addRRect` under an axis-aligned transform, else the HTML segments through `_addArc`), `_mappedRRect`, `_roundRectSegments` | `canvas_ui_path.dart:525-625` | 101 | None. `ui.Path.addRRect` has no direction and no Canvas 2D checks, flips, scale or subpath at (x, y). | **Keep**. A performance addition (porting-flow.md §1.1), not a cut. |
| The shape tracking of the fast paths (`singleRRect`, `shapePair`, `_trackShape`, the fields `_rrect`, `_shape0`, `_shape1`) | `canvas_ui_path.dart:306-311`, `:321-351` | 37 | None. `ui.Path` does not tell its shapes. | **Keep**. A performance addition (porting-flow.md §1.1). |
| `rrectContains` and `_cornerContains` (the inner rounded rectangle is inside the outer one) | `canvas_ui_path.dart:938-1049` | 112 | None. `RRect.contains` tests one point. | **Keep**. A performance addition (porting-flow.md §1.1): the condition of `drawDRRect`. |
| `roundRect` of the interface: `CanvasPath.roundRect`, `RoundRectGeometry`, `roundRectGeometry` (the HTML steps 1 to 11), `Path2D.roundRect`, `RoundRectCommand` | `lib/src/canvas/canvas.dart:92-104`, `:107-253`, `:698-713`, `:961-983` | 199 | None. The pure layer has no `dart:ui`. | **Keep**. A performance addition (porting-flow.md §1.1). |
| The fast paths of the context: `_RRectClip`, `roundRect`, the `drawRRect`, sole shape and `drawDRRect` branch of `fill`, `_soleShape`, `_ring`, the `clipRRect` branch of `clip`, `debugPath`, `debugRing`, `debugSoleShape` and `debugClips` | `canvas_ui.dart:378-385`, `:533-569`, `:1239-1241`, `:1296-1316`, `:1321-1355`, `:1397-1401` | 109 | None | **Keep**. A performance addition (porting-flow.md §1.1). |
| `CircleBatch` | `lib/src/canvas/canvas_ui_batch.dart` | whole file | None. Flutter does not merge `drawCircle` calls. | **Keep** (cut 3) |
| Text rotation snap of 2 degrees | `lib/src/canvas/canvas_ui.dart:1685-1706` | ~30 | Fixed on Flutter `master`, not in a stable release | **Keep** until a stable release has the fixes (cut 3) |
| `RenderChartHost.displaySize` (was `chartSize`): the two px styles, else the render size. The host has no CSS rule for one style. | `lib/src/platform/chart_host.dart:541-554` | 14 | The harness matcher `toBeChartOfSize` takes the rule for one style | **Done** (C2): the rule for one style moves to the harness of phase 5 |
| `UiCanvasElement.devicePixelRatio` and `logicalSize` | removed (`canvas_ui.dart:142`, `:175-192` at 69f9d97) | 0 | The host gives the paint scale | **Done** (C2): removed |
| The paint mapping: display / bitmap for each axis, exactly 1 / DPR within 1e-3 | `chart_host.dart:691-695`, `:718-729` | 17 | `Canvas.scale` in `UiCanvasContext.paint` | **Done** (C2): the one mapping from the bitmap to the display size |
| `initCanvas` over the attributes (`getAttribute`) | `lib/src/platform/platform.flutter.dart:109-178` | 70 | A small attribute model on `UiCanvasElement` | **Done** (C2): line by line |
| `releaseContext` over the attributes (`removeAttribute`, `setAttribute`) and `_Initial[prop]` | `platform.flutter.dart:458-493`, `:85-86` | 38 | The same attribute model | **Done** (C2): line by line |
| The attribute model: `UiCanvasElement({int? width, int? height})`, `getAttribute`, `setAttribute`, `removeAttribute`, `_setSize`, and the 3 members of `HTMLCanvasElement` | `canvas_ui.dart:234-327`, `canvas.dart:350-362` | 107 | None. `dart:ui` has no attributes. | **Added** (C2). Chart.js ADR 0022 §4 adds the `style` attribute and the string attributes. |
| The reflection of the `style` attribute in `UiCssStyleDeclaration`: `cssText`, `styleAttribute`, the declaration parser and the serialization after a CSSOM write | `canvas_ui.dart:96-222` | ~95 | None. `dart:ui` has no CSS. | **Added** (Chart.js ADR 0022 §4): `acquireChart` sets the canvas attributes with `setAttribute` |
| `getMaximumSize`, `retinaScale`, `readUsedSize` (ported, with `DIVERGES` rows) | `lib/src/helpers/helpers.dom.dart` | — | None. `AspectRatio` and `SizedBox` give other sizes than upstream. | **Keep**, no change |
| The first `ResizeObserver` notification at the next layout (`_pendingFirstResize`) and the mutation checkpoint (`flushCanvasMutations`, `_pendingConnectionChecks`) | `chart_host.dart:213-229`, `:273`, `:421-422`, `:473-490`, `:515-530`, `:634-658`, `:675-684` | ~60 | None. Flutter layout has no rendering step for observers and no microtask checkpoint for the tree. | **Added** (Chart.js ADR 0022 §10): the harness gives the specs the DOM timing |
| Host attach at the first layout, resize observers, host follows the chart size, unbounded rule, clip | `chart_host.dart:159-276`, `:439-526`, `:556-716`; `platform.flutter.dart:559-611` | ~340 | None. Flutter layout cannot know the size that Chart.js picks. | **Keep** |

## 2. Cut 1: arcs and transforms on dart:ui

### 2.1 Current code

`lib/src/canvas/canvas_ui_path.dart` has 1073 lines.

- 1-31: the library doc. It says that arcs become cubic Béziers under other transforms.
- 41-241: `UiTransform`. The flags are `isAxisAligned` (68), `isSimilarity` (73), `scaleFactor`
  (76), `angle` (79), `isReflected` (82), `isInvertible` (85) and `isTranslation` (88).
  `writeMatrix4` is at 192-204 and `writeInverseMatrix4` is at 208-221.
- 243-258: `canvasArcSweep`.
- 266-936: `UiPathBuilder`.
  - 306-311 and 321-351: the shape tracking of the rounded rectangle fast paths (`singleRRect`,
    `shapePair`).
  - 525-625: `roundRect`, `_mappedRRect` and `_roundRectSegments`. The segments call `_addArc`.
  - 628-674: `arc`, with the full-circle fast path at 649-671.
  - 677-703: `ellipse`.
  - 706-768: `arcTo` (the DOM tangent arc).
  - 774-838: `_addArc`. The similarity branch is 788-805. The axis-aligned branch with the
    reflection cases is 806-836. The Bézier fall-back is 837.
  - 844-880: `_nativeArc`.
  - 884-935: `_bezierArc`.
- 938-1049: `rrectContains` and `_cornerContains`.
- 1051-1073: `_CachedPath` and `uiPathOf`.

`lib/src/canvas/canvas_ui.dart` uses `UiTransform` for the state (275, 299), the shared matrix
buffer `_m4` (370), the transform setters (836-874), the shader matrix (637-641), the strokes
(692-763), the rectangles (777-1035), `fill` (1109-1176), `stroke` (1199-1217), `clip`
(1221-1249), the text (1485-1547) and `drawImage` (1622-1641). `canvas_ui_batch.dart` gets
centers that are already in bitmap space. It does not use `UiTransform`.

### 2.2 What dart:ui does (Flutter 3.44.9, probed)

The results were the same on the VM, on CanvasKit and on skwasm.

| API | Behavior |
|---|---|
| `arcTo(rect, start, sweep, forceMoveTo)` | It converts the angles to float degrees. A sweep of 2 pi adds nothing. A sweep of `2 * pi - 1e-12` adds nothing. A sweep of 3 pi adds a half circle. With `forceMoveTo: false` on an empty path, Skia starts with a move. After `close()`, Skia draws a line from the start of the closed subpath to the arc start. |
| `addArc`, `addOval` | They start a new contour, and a full sweep gives a closed contour. Do not use them: they have no connecting line. |
| `extendWithPath(src, offset, matrix4:)` | Skia `addPath` in extend mode. On an empty path, the first point is a move. Otherwise, a line connects the current point to the first point of `src`, also after `close()`. Conic segments map with their weights, so a skewed arc is exact (radius error 1e-5 user units at radius 100). |
| `addPath(..., matrix4:)` | It always starts a new contour. Do not use it: `moveTo(c)`, `arc`, `closePath` would close to the arc start and not to `c`. |
| `transform(matrix4)` | It returns a copy and keeps the fill type. |

**The web renderers read the source path and the matrix late.** On CanvasKit and on skwasm,
`LazyPath` (`engine/src/flutter/lib/web_ui/lib/src/engine/lazy_path.dart:316-340, 375-381,
423-443`) keeps a reference to the source path of `extendWithPath` and to the `Float64List` of
`extendWithPath` and `Path.transform`. It builds the native path at draw time. The frame arena
discards the built path at the end of a frame, and the next use builds it again from the same
references. The probe reset the source path and wrote a new matrix after the call. On the VM the
path ended at (50, 60), which is correct. On CanvasKit and on skwasm it ended at (115, 15), which
is wrong. Thus each `extendWithPath` call and each `Path.transform` call must get its own `ui.Path`
and its own `Float64List`. Never reuse a scratch path or `_m4` for them.

### 2.3 A web defect in the current code

The same aliasing is a defect today, on the web only. Work package W fixes it before cut 1.

- `canvas_ui.dart:1374`: `stroke()` under a transform that is not a similarity calls
  `_strokeUser(_path.path.transform(t.writeInverseMatrix4(_m4)))`. `_strokeUser` then writes the
  forward matrix into `_m4` (`:894`) before `drawPath` builds the lazy path. The probe was
  `transform(1, 0, 0, 3, 0, 0)`, a line at y = 10 and `stroke()`. On the VM, rows 27 to 32 had ink.
  On CanvasKit and on skwasm, nothing was drawn.
- `canvas_ui.dart:1392`: a `Path2D` clip calls `uiPathOf(path2d).transform(s.transform.writeMatrix4(_m4))`.
  The state keeps the clip and replays it into later recordings. After the frame arena discards
  the built path, the path builds again with the value that `_m4` has then. The probe did not show
  it, because the probe rendered no second frame.
- `canvas_ui_paint.dart:136` and `:373-377`: `shaderFor` keeps a copy in `_lastMatrix`, but
  `_build(matrix)` gives the caller's matrix (the shared `_m4`, from `canvas_ui.dart:775`) to
  `ui.ImageShader`. CanvasKit keeps that reference (`canvaskit/shader.dart:252`) and builds the
  shader again from it when the filter quality changes. The risk is low.

The canvas tests are `@TestOn('vm')`. `test:web` runs `dart test -p chrome` and cannot compile
`dart:ui`. Thus no repository test sees these defects.

### 2.4 Target design

- **The direct path stays.** When `rx == ry` and `t.isSimilarity`, `_addArc` keeps the current
  similarity branch: a `ui.Path.arcTo` on a circle in bitmap space, with `t.angle` and
  `t.isReflected` in the start angle. This covers every arc of Chart.js core (`retinaScale` plus
  `translate`), the point styles, `rectRounded`, the doughnut and the polar area.
- **The matrix path replaces the rest.** For every other case (a skew, a non-uniform scale, a
  mirror with a non-uniform scale, an ellipse with `rx != ry`, a rotated ellipse), a new method
  `_matrixArc(cx, cy, rx, ry, rotation, start, sweep)` does these steps:
  1. It builds a **new** `ui.Path` and adds the arc in user space on
     `Rect.fromLTRB(-rx, -ry, rx, ry)` with the half split of `_nativeArc` (one `arcTo`, or two
     half arcs when the absolute sweep is more than pi).
  2. It builds a **new** `Float64List(16)` for `T * [cos(rotation), -sin(rotation), cx;
     sin(rotation), cos(rotation), cy]`, column-major. `T` is the current `UiTransform`.
  3. It calls `path.extendWithPath(arc, Offset.zero, matrix4: m)`.
  4. It computes the user-space start point and end point (rotated by `rotation`, moved to
     (cx, cy)) and maps them with `t.mapX` and `t.mapY`. When `hasSubpath` is false, it sets
     `_startX`, `_startY` and `hasSubpath` from the start point. It sets `_lastX` and `_lastY`
     from the end point.
  5. A sweep of 0 does a line (or a move on an empty subpath) to the mapped start point, as
     `_nativeArc` does today. Do not depend on the Skia rule for a sweep of 0.
- **The rule "a point maps at add time" stays.** The arc maps with the transform of the call. A
  later transform change does not move it, and the path survives `save` and `restore`.
- **`UiTransform` does not change.** The similarity branch, the pending circle and
  `_snappedTextMatrix` read `angle`, `isReflected` and `scaleFactor`. The skwasm race of
  performance.md §5.5 depends on the snap. A later change can compute `angle` at its users, but it
  is not part of this plan.
- **Everything else stays:** `canvasArcSweep`, the half split, the current point, the DOM `arcTo`
  math, `rect()`, the pending circle, `CircleBatch` and `uiPathOf`.

### 2.5 Change list

Do step 0 in work package W. Do steps 1 to 6 in work package C1.

0. **Fix the web aliasing** (work package W, its own commit,
   `fix(flutter_chartjs_port): copy the matrices that the web paths read late`):
   - `canvas_ui.dart:1374`: `t.writeInverseMatrix4(Float64List(16))`.
   - `canvas_ui.dart:1392`: `s.transform.writeMatrix4(Float64List(16))`.
   - `canvas_ui_paint.dart` `shaderFor`: call `_build(_lastMatrix)`, so that the shader keeps the
     copy and not the buffer of the caller.
   - Add a comment at each place: the web renderers read the path and the matrix when they build
     the path.
   - The VM pixels do not change. Prove the fix in Chrome (§6.4).
1. Add `_matrixArc` as §2.4 describes. Give the half split one shared helper, for example
   `_appendArc(ui.Path p, ui.Rect oval, double start, double sweep, bool forceMoveTo)`, and call
   it from `_nativeArc` and from `_matrixArc`.
2. In `_addArc`, keep the zero-radius case and the similarity branch. Send every other case to
   `_matrixArc`.
3. Delete the axis-aligned branch (`:806-836`) and `_bezierArc` (`:882-935`).
4. Do not change `arc`, `ellipse`, `arcTo`, the pending circle, `UiTransform`, `canvas_ui.dart`
   or `canvas_ui_batch.dart`.
5. Update the library doc (`canvas_ui_path.dart:1-31`) and the doc of `_addArc`: the direct path,
   the matrix path, and the rule of §2.2 (a new path and a new matrix for each call).
6. If a threshold of the new test file (work package A1) fails only on antialiased edges, adjust
   the threshold in the same commit and say why in the commit message.

Rejected options:
- **Send the similarity branch through the matrix path too** (about 50 more lines out). The matrix
  path is about 3 times slower (§2.8), and on the web it adds one lazy command chain and two
  allocations for each arc. Doughnut slices and rounded bars would pay that cost.
- **Replace `UiTransform` with `vector_math` `Matrix4`.** It removes at most 20 lines, adds a
  dependency and keeps every flag.
- **Map the whole path at draw time with `Canvas.transform`.** A path whose points were added
  under different transforms has no single transform.

### 2.6 Tests

The tests that pin the current behavior are in `test/port/canvas/canvas_ui_test.dart`
(`@TestOn('vm')`): the group `transforms` (400-482), the group `paths` (667 and later, with "a
full circle and a negative radius", "a sweep just under a full turn fills a circle", the group "a
full circle on an empty path", "arc connects to the current point with a line", "a rotated
ellipse and arcTo draw", "fill and stroke a Path2D under the transform"), the group `rotated text`
(1251-1293) and the group `circle batch` (1522 and later, 28 tests). They must stay green without
a change. The `helpers.canvas` specs use `MockContext`. They record calls and never reach
`dart:ui`, so they are no evidence for cut 1.

Only two current tests reach the code that goes: "a rotated ellipse and arcTo draw" (ink probes
only) and the last part of "a sweep just under a full turn fills a circle" (`scale(1, 0.5)`, the
positive axis-aligned case). No test covers a partial arc under a mirror, a skew or a non-uniform
scale. Thus work package A1 adds a new file before the cut.

`test/port/canvas/canvas_ui_round_rect_test.dart` (`@TestOn('vm')`) also reaches `_addArc`.
`roundRect` under a rotation or a skew adds the HTML segments, and their arcs go through
`_addArc`. The test "the path under a rotation and a skew" compares them with the upstream arcs.
Under a skew both paths have Bézier arcs that go round in opposite directions, so its edge
tolerance is 48 of 255. It must stay green after C1. If C1 makes the edges closer, C1 can lower
that tolerance. The other tests of the file pin the rounded rectangle fast paths and do not reach
the code that goes.

**New file `test/port/canvas/canvas_ui_path_test.dart`.** It starts with the port-only header
line and `@TestOn('vm')`. It copies the small `_render` and pixel helpers of `canvas_ui_test.dart`.
Each pixel test compares with a reference that plain `dart:ui` draws: `canvas.transform(M)` and a
user-space `Path.arcTo` or `addOval` of the same shape. The thresholds:
- The probes inside and outside the shape are exact.
- The worst channel differs by at most 24 of 255, on antialiased edge pixels only.
- The ink count is within 1 %.
- Each probe is at least 2 pixels from an edge.

The test list:
1. A partial arc (sweep 3 pi / 2), clockwise and counterclockwise, under the skew
   `transform(1, 0, 0.5, 1, 0, 0)`.
2. Partial arcs under `scale(2, 0.5)`, `scale(-2, 0.5)`, `scale(2, -0.5)` and `scale(-2, -0.5)`,
   clockwise and counterclockwise. The wedge is in the mirrored quadrant. These pin the four
   reflection cases that go.
3. Partial arcs (0 to pi / 2 wedges from the center) under `scale(-1, 1)`, `scale(1, -1)` and
   `scale(-1, -1)`. These stay on the direct path and pin it.
4. A partial arc under `rotate(pi / 3)` and `scale(2)`: the start point, through a `lineTo` back
   to the center.
5. A rotated ellipse (rx 40, ry 15, rotation pi / 6) under the identity, under `rotate(pi / 5)`
   and under `scale(2, 1)`, with start and end angles, clockwise and counterclockwise.
6. A full sweep and a sweep of `2 * pi - 1e-9` under a skew: a near-full ellipse (two halves).
7. A sweep of 0 under a skew: only the connecting line. The current point is the arc start.
8. `moveTo(c)`, a skewed arc, `closePath`, `fill`: the wedge closes to `c`. This guards against
   `addPath`.
9. `closePath`, then a skewed arc: the line starts at the start of the closed subpath.
10. Map at add time: a skewed arc, then `setTransform(1, 0, 0, 1, 0, 0)`, then `lineTo`. The arc
    does not move, and the line starts at the bitmap end point of the arc.
11. The path survives `save` and `restore`: `save`, skew, `arc`, `restore`, `stroke`.
12. A DOM `arcTo` after a skewed arc. It reads the current point back through the inverse.
13. An `ellipse` with one radius of 0 under a skew: a line when stroked, nothing when filled.
    Both radii 0 under a skew: a line or a move to the center.
14. A dashed stroke of a skewed arc: the count of dash runs on one probe row.
15. A clip with a skewed arc path.
16. A `Path2D` with a rotated ellipse, with `fill(path2d)` and `stroke(path2d)` under a skew.
17. A nonzero ring: an outer circle under the identity and an inner circle under a mirror about
    its center.
18. Unit checks without pixels: `singleCircle` is `null` for a full circle under a skew or a
    non-uniform scale, and not `null` under a similarity. `hasSubpath`, `isEmpty` and `singleRect`
    after arcs.
19. The order of argument errors under a singular transform: a negative radius throws before the
    invertibility test. A non-finite rotation does nothing.
20. Rotated text under a mirror (the snap reads `UiTransform`).

All tests must be green on the current code before C1 starts.

**Web probes (work package A1, and again in W and C1).** No repository suite runs the `dart:ui`
layer on the web. Use a scratch package outside the repository, with a path dependency on
`packages/flutter_chartjs_port`, and run `flutter test --platform chrome` and
`flutter test --platform chrome --wasm` on a copy of tests 1, 8 and 10 and of these two probes:
- A stroke under `transform(1, 0, 0, 3, 0, 0)` of a line at y = 10 must ink y = 30.
- A `Path2D` clip under `translate`, replayed after at least one more rendered frame with other
  draws.

Run each probe in the first frame and again after at least one more frame, so that the frame arena
builds the path again. Record the result in the Evidence section of Chart.js ADR 0013. Before W,
the stroke probe fails on CanvasKit and on skwasm. Work package I can put the same probes in a
gallery integration test.

### 2.7 ADR and doc changes

Chart.js ADR 0013 is accepted (2026-10-21), so the owner does not edit its text. A new ADR states
the complete decision with the changes below and supersedes Chart.js ADR 0013.
- §6 (lines 150-165): replace "An arc uses `ui.Path.arcTo` when ... cubic Béziers of 90 degrees
  or less" with the direct path and the matrix path of §2.4. State that each `extendWithPath` call
  and each `Path.transform` call gets its own `ui.Path` and `Float64List`, because the web
  renderers read them when they build the path.
- §7 or §8: one sentence on step 0, and one sentence on the cost of the matrix path.
- Evidence: the new test file, the probe figures of §2.8 and the web runs.
- Open: no repository suite runs the `dart:ui` layer on the web. Name the scratch-package method.
- `parity.md`: row 376 (`canvas_ui_path.dart`), "else cubic Béziers" becomes "else a user-space
  `ui.Path.arcTo` that `extendWithPath(matrix4:)` appends". Row 375 and row 377 get the matrix
  copies of step 0. Add a row for `test/port/canvas/canvas_ui_path_test.dart`.
- `performance.md`: a new section with the arc figures (§2.8 and §6.3).
- Chart.js ADR 0034 does not change. Conics in place of Béziers give a display-only
  difference. Thus there is no `DIVERGES` row and no superseding ADR.
- `porting-flow.md` §2.2 and `differences.md` do not change.

### 2.8 Speed of the matrix path

Scratch probe, debug build (JIT), 20000 partial arcs:

| Case | VM | skwasm |
|---|---:|---:|
| Current code, retina scale (direct arc) | 4.8 ms | 6.0 ms |
| Current code, rotation (direct arc) | 4.9 ms | 6.2 ms |
| Current code, skew (Bézier arc) | 5.2 ms | 6.5 ms |
| Matrix path, a new path and a new matrix for each arc | 13.5 ms | 23.4 ms |

The matrix path is about 2.8 times slower on the VM and 3.6 times slower on skwasm (about 0.7
microseconds for each arc on the VM). Chart.js core draws no arc under a skew or a non-uniform
scale, so a chart keeps its current speed.

### 2.9 Risks

1. **The web reads the path and the matrix late** (proven, high). The VM tests cannot see a reuse
   of a scratch path or of `_m4`. Step 0, the rule of §2.4 and the web probes cover it.
2. **Extend-mode rules are engine behavior** (medium). The line after `close()` and the skipped
   line of length 0 come from Skia. Impeller (`DlPath`, Metal and Vulkan) can differ. Tests 7, 9
   and 17 pin them on the VM. The Canvas tab of the gallery on macOS and on the Pixel 8a, or work
   package I, checks Impeller.
3. **No current test pins the code that goes** (high). Work package A1 lands first and is green
   on the current code.
4. **Precision** (low, display-only). Exact conics replace Béziers of 90 degrees. Dash positions
   on a skewed arc move by sub-pixels. Use the edge thresholds and the run counts of §2.6, not
   exact pixels.
5. **Speed of the matrix path** (low). It is about 3 times slower for each arc, and only off the
   Chart.js core paths.

### 2.10 Estimated lines

| Item | Removed | Added | Net |
|---|---:|---:|---:|
| `canvas_ui_path.dart` | ~95 (`_bezierArc` 54, axis-aligned branch 31, doc 10) | ~50 (`_matrixArc`, the matrix, `_appendArc`, doc) | about -45 |
| Step 0 (`canvas_ui.dart`, `canvas_ui_paint.dart`) | 0 | ~6 | about +6 |
| `canvas_ui_path_test.dart` (new) | 0 | ~350 to 400 | — |
| Docs (ADR 0013, `parity.md`, `performance.md`) | — | ~40 changed | — |

## 3. Cut 2: host sizing on Flutter layout

### 3.1 Code before C2

This section gives the code at commit 69f9d97, before work package C2. The line numbers are the
lines of that commit. §3.10 gives the code after C2.

`lib/src/platform/chart_host.dart` (916 lines, port-only):

| Lines | Part | Kind | Verdict |
|---|---|---|---|
| 21-35 | Library doc, "Sizing" | doc | Rewrite lines 31-33 |
| 129-181 | `CanvasMutationObserver`, `_notifyConnection` | Flutter adaptation | Keep |
| 183-225 | `ContainerResizeObserver` (`ResizeObserver` and DPR change) | Flutter adaptation | Keep |
| 252-255 | `_devicePixelRatio(context)` | Flutter | Keep |
| 323-338 | `devicePixelRatio` setter. Line 332 writes `_canvas.devicePixelRatio`. | mixed | Delete line 332 |
| 354-373 | `_show`. Line 371 writes `..devicePixelRatio`. | mixed | Delete line 371 |
| 385-459 | Container: `contentWidth`, `contentHeight`, `isConnected` | Flutter adaptation | Keep |
| 461-468 | `_pixels`, `_readPixels` | style parse | Keep. The style that `retinaScale` writes carries the display size. |
| 470-491 | `chartSize`: px styles, else the render size. One style keeps the render aspect (480-489). | CSS emulation | Simplify and rename to `displaySize` |
| 493-523 | `_laidOutChartSize`, `_handleCanvasChanged`, the `_checkChartSize` microtask | Flutter adaptation | Keep |
| 527-550 | Repaint boundary, `computeDryLayout`, intrinsics | Flutter | Keep, rename |
| 552-590 | `performLayout`: first attach, observers, `size = constrain(chartSize)` | Flutter adaptation | Keep |
| 592-605 | `_scheduleRelayout`, paint fall-back | Flutter adaptation | Keep |
| 609-631 | `paint`: clip of a larger chart | Flutter | Keep |
| 633-658 | `_paintCanvas`: the DOM bitmap stretch, with a fast path within 1e-3 | stretch emulation | Keep as the one mapping from the bitmap to the display size |
| 914 | `debugFillProperties` `chartSize` | debug | Rename |

`lib/src/platform/platform.flutter.dart` (624 lines, port-only, replaces `platform.dom.js`):

| Lines | Part | Verdict |
|---|---|---|
| 49-82 | `_expando`, `_ChartjsExpando`, `_Initial` | Keep |
| 104-117 | `initCanvas` doc, "A Flutter canvas has no attributes ..." | Delete lines 111-117 |
| 121-123 | `const String? renderHeight = null` and `renderWidth = null` | Read `canvas.getAttribute('height')` and `getAttribute('width')` (`platform.dom.js:45-46`) |
| 138-147 | `display: block`, `box-sizing: border-box` | Keep (upstream lines, no effect in Flutter) |
| 149-172 | Render size from `readUsedSize(style)` or the aspect ratio | Keep (upstream lines) |
| 177-187 | `_toUint32` | Keep |
| 455-495 | `releaseContext`: an absent attribute gives 300 x 150 (470-477), styles restored, `canvas.width = canvas.width` | Port `platform.dom.js:300-307` line by line with `removeAttribute` and `setAttribute` |
| 545-559 | `getDevicePixelRatio` from the host | Keep |
| 561-613 | `getMaximumSize` with the rule for unbounded constraints | Keep |
| 615-623 | `isAttached` from the host | Keep |

`lib/src/canvas/canvas.dart` (pure interface): `HTMLCanvasElement` (326-347) gets
`getAttribute`, `setAttribute` and `removeAttribute`. `CSSStyleDeclaration`, `CanvasNode` and
`CanvasContainer` do not change.

`lib/src/canvas/canvas_ui.dart`:
- `UiCssStyleDeclaration` (94-127) stays. `retinaScale` writes it, and `direction` reads it.
- `UiCanvasElement` (129-216): the constructor (136-138), the `width` and `height` setters
  (145-165), `_devicePixelRatio` (142), the `devicePixelRatio` getter and setter (175-187) and
  `logicalSize` (189-192).
- `UiCanvasContext.paint` (415-435) draws with `scale(1 / dpr)` at 425 and 429.
- The library doc at 25-31 describes that scale.

`lib/src/helpers/helpers.dom.dart` does not change. `getMaximumSize`, `retinaScale` and
`readUsedSize` are ported, and their rows `platform-dom-no-css`, `platform-dom-container` and
`platform-dom-computed-style` stay valid.

Users outside the package: `apps/chartjs_gallery/lib/demo/demo_chart.dart` (`DemoChart` with a
default `UiCanvasElement()`, responsive only) and `apps/chartjs_gallery/lib/demo/canvas_demo.dart:124`
(`UiCanvasElement(width: 32, height: 32)` for `toImageSource`). This line number is the line of
2026-10-21. At 69f9d97, the line is 125. No gallery code reads `devicePixelRatio`, `logicalSize`
or `chartSize`.

### 3.2 Why Flutter layout does not replace the Chart.js sizing

Chart.js must stay the one source of the chart size. The ported `getMaximumSize` and
`retinaScale`, and `core.controller._resize` of phase 5, give sizes that `AspectRatio` or
`SizedBox` do not give:
- The attach resize ignores the container height. Later observer resizes cap by it
  (`maintainHeight`, `helpers.dom.ts:191-197`). The test "a later resize with the container
  height keeps the ratio" of `chart_host_test.dart` pins it.
- `round1`, `Math.floor` and the default ratio of 2 (#4659) shape the size.
- `onResize`, the `resize` plugin hook and `resizeDelay` run from `_resize`.
- A change of `options.aspectRatio` and then `chart.resize()` runs inside Chart.js.
- The size changes the ticks and the hit tests, so Chart.js ADR 0034 requires the upstream size.

Flutter layout still has a role. The parent widgets (`SizedBox`, `AspectRatio`, `Expanded`,
`Padding`) set the constraints, and the constraints are the container of `getMaximumSize`.

The bitmap stretch also stays. It shows `options.devicePixelRatio` at the right size. Without
it, a chart with `devicePixelRatio: 1` on a DPR 3 view paints at one third of its box, the
pointer positions do not agree with the drawn elements, and the hit element changes.

### 3.3 Target design (option A)

- **An attribute model.** `UiCanvasElement({int? width, int? height})`. A size given at creation
  is the `width` or `height` attribute. A `null` side has no attribute and the DOM default (300 or
  150). The `width` and `height` setters also set the attribute, as the DOM reflects the IDL
  attribute. `removeAttribute('width')` sets 300 and resets the context.
  `removeAttribute('height')` sets 150. `setAttribute` parses a non-negative integer and falls
  back to the default. Other attribute names give `null` or do nothing.
- **`initCanvas` and `releaseContext` become line-by-line ports** over the attributes.
- **One paint mapping.** The host computes `sx = display.width / canvas.width` and
  `sy = display.height / canvas.height` (with guards for a size of 0). When `|sx * dpr - 1|` and
  `|sy * dpr - 1|` are both less than 1e-3, it uses exactly `1 / dpr`. Then it calls
  `ctx.paint(canvas, offset, sx, sy)`. `UiCanvasContext.paint` applies that scale. The canvas has
  no `devicePixelRatio` and no `logicalSize`.
- **The display size** is the two px styles that `retinaScale` writes, when both are px, else the
  render size (`canvas.width`, `canvas.height`). The CSS rule for one style moves to the harness
  matcher `toBeChartOfSize` of phase 5.
- **Everything else stays:** the attach at the first layout, the observers, the microtask check
  and the paint fall-back, the unbounded rule, the clip, `getMaximumSize` and `retinaScale`.

This fixes the default spec canvas. `acquireChart` makes a 512 x 512 canvas through its attributes
(chartjs-test-utils `utils.js:43`). Before C2, `UiCanvasElement(width: 512, height: 512)` went
through `initCanvas` with no attribute and no style, and `initCanvas` set the height to 512 / 2 =
256 (`platform.flutter.dart:121-172` at 69f9d97). The test "acquireContext initializes the canvas"
shows the same rule. Every spec that uses the default canvas would get a 512 x 256 chart.

Rejected options:
- **Option B: no attributes, no style reads in `initCanvas`, no style restore.** It removes about
  150 lines and adds 30. Upstream gives a non-responsive doughnut, pie, polar area or radar chart
  on a canvas without a height 300 x 300. The port would give 300 x 150. It needs a new
  `differences.md` row (for example `platform-canvas-css-size`), a `DIVERGES` marker, about 11
  phase 5 spec cases skipped as `diverges:`, and a new mechanism for `options.devicePixelRatio`.
- **Remove the stretch and paint at `1 / dpr` only.** `options.devicePixelRatio` breaks (§3.2).
- **Host size from `AspectRatio` or `SizedBox` in place of `getMaximumSize`.** It is a second
  source of truth, it caps the attach resize by the height, it has no `round1`, and `onResize`
  and the hook need `_resize`.
- **A size listener on `UiCanvasElement` in place of the microtask and the paint fall-back.** A
  `markNeedsLayout` from chart code that runs inside the layout of another render object (for
  example a `LayoutBuilder`) trips the layout assertions of Flutter. The microtask design is the
  evidence base of Chart.js ADR 0014 §4 and Chart.js ADR 0016.

### 3.4 Change list

Work package C2 does these steps. The plan put it after W, because both edit `canvas_ui.dart`.
C2 ran in phase 5 without W (Deferral, trigger 1). The line numbers below are the lines of commit
69f9d97. §3.10 gives the result and the differences from these steps.

1. `lib/src/canvas/canvas.dart`: add `String? getAttribute(String name)`,
   `void setAttribute(String name, String value)` and `void removeAttribute(String name)` to
   `HTMLCanvasElement`, with docs for `width` and `height` (about 18 lines). The test fakes use
   `noSuchMethod`, so they do not break.
2. `lib/src/canvas/canvas_ui.dart`, `UiCanvasElement`: the constructor `{int? width, int? height}`,
   the fields `_widthAttribute` and `_heightAttribute`, the reflection in the setters, and the
   three attribute methods (about 35 lines).
3. `lib/src/canvas/canvas_ui.dart`, the context: delete `_devicePixelRatio`, the
   `devicePixelRatio` getter and setter, and `logicalSize` (142, 175-192).
   `UiCanvasContext.paint(ui.Canvas canvas, ui.Offset offset, double scaleX, double scaleY)`
   replaces `if (dpr != 1) canvas.scale(1 / dpr)` with `canvas.scale(scaleX, scaleY)`. Rewrite the
   library doc at 25-31: the host gives the scale from bitmap pixels to logical pixels.
4. `lib/src/platform/platform.flutter.dart`: read `canvas.getAttribute('height')` and
   `getAttribute('width')` at 121-123. Delete the doc at 111-117. Port `releaseContext` (455-477)
   as the `['height', 'width'].forEach` of `platform.dom.js:300-307`, with `removeAttribute` and
   `setAttribute`. Delete the hard-coded 300 x 150 branch and its doc. Keep `_Initial`, the
   `display` and `box-sizing` writes and the `readUsedSize` lines.
5. `lib/src/platform/chart_host.dart`: rename `chartSize` to `displaySize` and delete the
   one-style branches (480-489). Rewrite `_paintCanvas` (633-658) as the one mapping of §3.3.
   Delete lines 332 and 371. Rename in 914, in the intrinsics and in the dry layout. Rewrite the
   library doc at 31-33.
6. Change the tests (§3.5).
7. Update the docs (§3.7).

### 3.5 Tests

Tests that pin the current behavior (run them before and after):
- `test/port/platform/chart_host_test.dart`: 40 tests, 41 after C2, 50 after Chart.js ADR
  0022 and 73 after Chart.js ADR 0037 (proposed). The tests are "first layout" (2) and the group
  "resize". The group "resize" tests the throttle, a DPR change, content drawn before the host
  at the display size, the clip and a later resize that keeps the ratio. Then come the group
  "display size and bitmap stretch" (7, from work package A2, 8 after C2), "unbounded
  constraints" (4), "dry layout" and the group "attach and detach".
- `test/port/platform/platform.flutter_test.dart` (18 tests, 21 after C2): `initCanvas` (5, 7
  after C2), "acquireContext initializes the canvas", "releaseContext restores the canvas",
  "releaseContext restores the initial attributes" (after C2), `getDevicePixelRatio`,
  `getMaximumSize` (4).
- `test/port/helpers/helpers.dom_test.dart`: `getMaximumSize`, `retinaScale` (10, with the
  `Math.floor` of the canvas size of ledger row #12142), `readUsedSize` (10),
  `platform-dom-computed-style`.
- `test/port/canvas/canvas_ui_test.dart`: "device pixel ratio" (2), "toImageSource snapshots the
  bitmap in device pixels" (836, 926 after C2, 1016 after Chart.js ADR 0022), "the pictures are
  in bitmap space at a device pixel ratio" (2.625, 1972, 2061 after C2, 2151 after Chart.js ADR
  0022). The `_render` helper at line 89 reads `logicalSize` and has about 88 callers. After C2,
  `_render` is at line 84 and takes `dpr`.
- `test/specs/helpers.dom_test.dart` (7 cases pass. The 2 `retinaScale` cases run through
  `acquireChart`. Thus the file runs on the VM only.)
- `test/port/helpers/helpers.dom_web_test.dart` (since the review of phase 5): the 5
  `getMaximumSize` cases of the spec and `retinaScale` (5), on the VM, dart2js and dart2wasm.
- `apps/chartjs_gallery/test/` (`canvas_host_demo_test.dart` line 94 expects a non-empty
  `canvas.style` width).

Before work package A2, only the test "shows content drawn before the host at the display size"
reached the stretch. It did not pin the stretch of a chart, the exact paint scale or the one-style
rule. Work package A2 added these tests to the group "display size and bitmap stretch" of
`chart_host_test.dart`. They were green on the code before C2:
1. `FakeChart(devicePixelRatio: 1)` on a DPR 2 view: bitmap 400 x 200, host 400 x 200, and a
   `fillRect` of the left half of the chart covers the left half of the `RepaintBoundary` image.
   The test is "a chart at devicePixelRatio 1 on a view at 2 fills its display size".
2. `FakeChart(devicePixelRatio: 3)` on a DPR 1 view: bitmap 1200 x 600, host 400 x 200, ink at the
   display size. The test is "a chart at devicePixelRatio 3 on a view at 1 fills its display
   size".
3. A pointer at the center of the host under test 1 gives a chart event at
   (`chart.width / 2`, `chart.height / 2`). The test is "a pointer at the center of a stretched
   chart gives the center of the chart".
4. DPR 1.5 and width 101 give bitmap 151 and a factor of 1.0033: the stretch applies. DPR 2.625
   and a box 387.43 wide (the Pixel 8a Stress tab) give a factor within 1e-3: the paint scale is
   exactly 1 / 2.625. The host paint has no `TransformLayer`. Thus the test reads the
   `Canvas.scale` calls of the host paint with a `TestRecordingCanvas`. The test is "a factor
   within 1e-3 paints at exactly 1 / devicePixelRatio".
5. A non-responsive chart with styles 345 x 125 and a bitmap of 165 x 85: the host is 345 x 125.
   The current `initCanvas` takes the render size from the styles. Thus the test sets the bitmap
   and the chart size to 165 x 85 after the construction. The test is "a non-responsive chart
   shows its bitmap at the size of its styles". C2 changed the test to
   `UiCanvasElement(width: 165, height: 85)`. The test then needs no workaround.
6. One style only (`width: 600px`): the host keeps the render aspect. A bitmap of 200 x 100 gives
   a host of 600 x 300. The style `height: 50px` alone gives 100 x 50. Work package C2 changes this
   expectation, because the rule moves to the harness. The test is "one style keeps the aspect
   ratio of the render size". C2 renamed the test to "one style alone shows the render size".
7. After `releaseContext`, the host shows 300 x 150. The test is "releaseContext gives the host the
   default 300 x 150".

Work package C2 changed these tests (the line numbers of commit 69f9d97):
- `canvas_ui_test.dart`: `_render` takes an optional `dpr` (default 1), computes the size from
  `canvas.width / dpr` and paints with `1 / dpr`. The group "device pixel ratio" becomes "paint
  maps the bitmap pixels with the given scale". The assertion "`onChanged` on a DPR write" goes.
  Delete `..devicePixelRatio = 2` at 837. The 2.625 test paints with `1 / dpr`.
- `chart_host_test.dart`: delete `expect(canvas.devicePixelRatio, 2)` (126, 149). `chartSize`
  becomes `displaySize` (172). "clips a chart that is larger than the box" uses
  `UiCanvasElement(width: 600, height: 300)`. In the group "display size and bitmap stretch",
  test 4 expects one `scale` call of (101 / 151, 50.5 / 75) at DPR 1.5. Test 6 expects the render
  size 200 x 100 for both canvases.
- Not in the list above, also changed by C2: test 5 of A2 (see above). The `paint` calls of
  `canvas_ui_test.dart` "the points stay in place under the transform of the host",
  `canvas_ui_round_rect_test.dart` "an RRect clip replays into a new recording" and
  `pixel_compare.dart` `renderContext` give the scale (1, 1). The `_Canvas` fakes of
  `test/port/elements/element.arc_test.dart` and `test/port/helpers/helpers.canvas_test.dart` do
  not use `noSuchMethod`. They get the 3 attribute members.

Work package C2 added these tests. They fail on the code before C2:
1. `canvas_ui_test.dart`, group "attributes": no attribute gives `null` and 300 x 150. The
   constructor sizes give `'512'`. A setter reflects into the attribute. `removeAttribute`
   restores the default and clears the bitmap. `setAttribute` parses, and a bad value gives the
   default. The tests are "a canvas without attributes has the default size", "a write of width
   or height sets the attribute", "removeAttribute gives the default size and clears the bitmap"
   and "setAttribute parses a non-negative integer, else the default". The group "paint maps the
   bitmap pixels with the given scale" also gets "a scale for each axis stretches the bitmap".
2. `platform.flutter_test.dart`: `initCanvas` keeps a 512 x 512 canvas. A width attribute of 400
   with ratio 1 gives 400 x 400. Attributes 165 x 85 with styles 345 x 125 keep the render size
   165 x 85. `releaseContext` restores a given attribute (180) and removes an absent one (height
   back to 150) after `retinaScale` changed both. The tests are "keeps the render size of the
   attributes", "applies the aspect ratio to a width attribute alone" and "releaseContext
   restores the initial attributes".
3. `chart_host_test.dart`: a non-responsive chart on `UiCanvasElement(width: 320, height: 240)`
   at DPR 3 gives a chart of 320 x 240, a canvas of 960 x 720 and a host of 320 x 240. The paint
   scale is exactly 1 / 3. The test is "a non-responsive chart on canvas attributes at
   devicePixelRatio 3 keeps its display size".

### 3.6 Spec case impact (phase 5)

On 2026-10-19, every case below was `blocked: core.controller`, except the 5 `helpers.dom` cases
that pass. Since 2026-10-20, the cases that need only ported modules skip as `blocked: harness`.
The others skip with the module of the latest phase that they need: the two `helpers.dom` event
cases as `blocked: controller.bar`, and the `platform.dom` event case as
`blocked: controller.line`.
Since the harness step of 2026-10-20, no case skips as `blocked: harness`. The cases of this table
give the results of the column "After option A". Where a real result differs from the prediction,
the column "After option A" gives the real result. The two
`helpers.dom` cases "leave styled height and width" and "handle devicePixelRatio correctly" pass
through `acquireChart`. The 31 `core.controller` cases of the port step pass. The Retina and
`devicePixelRatio` cases with the attributes 320 x 240 pass. The case with `data: []` passes
since the review fix of 2026-10-20: an array data gives a new Map (row `adapt-config-objects`).
"Current code" means the result that the current code would give when phase 5 runs the case.
It is the code before C2. After C2, the column "After option A" applies.
`toBeChartOfSize` (chartjs-test-utils `matchers.js:131-171`) reads the display size from the style.
The specs never see `chartSize` (`displaySize` after C2) or the stretch. Only `initCanvas`,
`releaseContext` and the attributes reach them.

| Spec file | Case | Depends on | Current code | After option A | Option B (rejected) |
|---|---|---|---|---|---|
| `platform.dom` | Context acquisition (5 cases) | — | pass | pass | pass |
| `platform.dom` | aspectRatio "default global" (620), "user" (405), "not apply when height specified" (400 x 410) | `initCanvas` style read, one-style rule | pass | pass (rule in `toBeChartOfSize`) | `diverges:` |
| `platform.dom` | aspectRatio "default chart aspect ratio" (425) | doughnut controller | `blocked: controller.doughnut` | pass after the doughnut port | `diverges:` |
| `platform.dom` | responsive false, "default canvas size" | — | pass | pass | pass |
| `platform.dom` | responsive false, "canvas attributes" (305 x 245) | attributes | **fail** (305 x 152) | **pass** | `diverges:` |
| `platform.dom` | responsive false, "canvas style" (345 x 125), "decimal display" (345.42) | `initCanvas` style read | pass | pass | `diverges:` |
| `platform.dom` | responsive false, "attributes for the render size and style for the display size" (165 x 85, 345 x 125) | attributes, stretch | **fail** (render from the style) | **pass** | `diverges:` |
| `platform.dom` | responsive true, "fit parent using aspect ratio" (150 x 245 to 214 x 350) | `initCanvas` style read | pass | pass. The callback never runs, as upstream. The construction gives 300 x 490, the first observer resize 214 x 350. `test/port/core/core.controller_test.dart`, group "the platform.dom spec cases", pins both sizes | fail or `diverges:` |
| `platform.dom` | destroy, "reset context to default values" | `canvas.width = canvas.width`, the shadow attributes | `diverges: platform-canvas-no-shadow` | `diverges: platform-canvas-no-shadow`. The canvas layer has no shadow attributes. Cut 2 does not change this result | `diverges: platform-canvas-no-shadow` |
| `platform.dom` | destroy, "restore canvas initial values" (attribute 180) | attributes, style restore | `n/a` | **pass** | `diverges:` |
| `platform.dom` | event handling | — | pass | `blocked: controller.line` (pass after the controller port) | pass |
| `platform.dom` | isAttached | — | `n/a` | `n/a` | `n/a` |
| `helpers.dom` | "leave styled height and width" (attributes 200, style 400) | style read | pass | pass | pass |
| `helpers.dom` | "handle devicePixelRatio correctly" (attributes 800 x 400) | attributes | pass by chance (800 / 2 = 400) | pass | pass by chance |
| `helpers.dom` | "Should not return NaN with a custom event", "consistent results" | — | pass | `blocked: controller.bar` (pass after the controller port) | pass |
| `helpers.dom` | 2 cases `diverges: platform-relative-position` | — | unchanged | unchanged | unchanged |
| `core.controller` | `maintainAspectRatio: false` group: fill parent, onResize, parent width, parent height, invisible (`SizedBox.shrink`), RTL, parent padding (`Padding`), wrapper `display: none` to block | constraints | pass | pass | pass |
| `core.controller` | `maintainAspectRatio: false`, DPR option change (render width 800, display width 400) | stretch | pass | pass | spec passes, the visible chart has the wrong scale |
| `core.controller` | canvas `display: none` to block | harness | pass or `n/a: Flutter has no CSS display on the canvas` | pass, through the first notification of the resize observer | same |
| `core.controller` | `max-width` and `max-height` with `display: none` | CSS | `n/a: Flutter has no CSS max-width` | pass. The harness CSS subset has `max-width` and `max-height`. `getMaximumSize` gives the height width / 2 for a zero height (`helpers.dom.ts:186-190`) | same |
| `core.controller` | `maintainAspectRatio: true` (2 cases, `canvas: {style: ''}`) | ratio 2 | pass | pass | pass |
| `core.controller` | Retina scale and `config.options.devicePixelRatio`, "implicit display size" (2 cases, attributes 320 x 240) | attributes | **fail** (320 x 160) | **pass** | fail |
| `core.controller` | Retina scale and `config.options.devicePixelRatio`, "explicit display size" (2 cases, style 320 x 240) | `initCanvas` style read | pass | pass | `diverges:` |
| `core.controller` | `config.options.aspectRatio` (attribute width 400, ratio 1, then 2) | harness wrapper | pass if the default wrapper is a box of the canvas display size | same | same |
| `core.controller` | attach and detach cases, "re-creating the chart" | — | unchanged | unchanged | unchanged |
| 14 of the 23 core, element and scale spec files | every case on the `acquireChart` default canvas | attributes | 512 x 256 | 512 x 512 | 512 x 256 |

Net for option A: 5 named cases and the default 512 x 512 canvas go from fail or `n/a` to pass. No
new `differences.md` row. No skip reason changes now, because every affected case is still
`blocked: core.controller`. Thus `test:cases` gives the same output. The integration of
2026-10-20 changed these reasons to `blocked: harness` and to the modules above. The counts of
`test:cases` did not change. The harness step changed the counts of `test:cases`.

### 3.7 ADR and doc changes

Chart.js ADR 0013 and Chart.js ADR 0014 were proposed in phase 5, so work package C2 edited them
in place. The porting lead accepted them on 2026-10-21. Thus a later change of these decisions
gets a new ADR that supersedes the old ADR. Chart.js ADR 0034 and Chart.js ADR 0016 do not change.

Work package C2 made these changes in phase 5, except the `performance.md` figures. These figures
are for work package P. The line numbers below are the lines after C2. The porting-flow.md line
numbers are the lines of 2026-10-21, after the toolchain change.
- **Chart.js ADR 0014:**
  - §2 (lines 86-93): "the display size of the canvas" is the px styles that `retinaScale` writes,
    else the render size.
  - §5 (lines 146-170): the display size rule, "paint maps the bitmap to the display size with one
    scale, exactly 1 / DPR within 1e-3" in place of the stretch bullet, why the stretch stays
    (`options.devicePixelRatio`), and the attribute model.
  - Alternatives (lines 288-299): add option B, the paint at `1 / dpr` only, and the host size
    from Flutter layout, with the reasons of §3.3.
  - Evidence (lines 319-369): the new tests and their counts.
- **Chart.js ADR 0013:** §2 (lines 81-87): the `devicePixelRatio` and `logicalSize` bullet becomes
  the attributes bullet. §4 (lines 119-120): the `paint` signature. §5 (lines 128-146): `paint`
  applies the scale that the host gives. Delete the bullet on the `UiCanvasElement.devicePixelRatio`
  write. "The content keeps bitmap pixels across a DPR change" stays. The stretch bullet points to
  Chart.js ADR 0014 §5. Evidence: the test names.
- **`porting-flow.md`** (proposed): §2.2 (lines 248-249), "`paint` applies
  `scale(1 / devicePixelRatio)`" becomes "`paint` maps the bitmap pixels with the scale of the
  host". §2.7 (lines 343-346): one bullet on the canvas attributes. §3, harness table (lines
  763-764), `acquireChart`: 512 x 512 as attributes (`UiCanvasElement(width: 512, height: 512)`),
  the `canvas.style` option fills the inline style, a wrapper style becomes a `SizedBox`,
  `ConstrainedBox` or `Padding`, and the default wrapper is a box of the canvas display size. `toBeChartOfSize`: the display size rule of
  Chart.js ADR 0022 §9 (the inline px styles, else the render size, with the CSS rule for one
  style), in a pure layer. The harness step of
  2026-10-20 changed the wrapper part: a wrapper style goes through the CSS subset of `dom.dart`.
- **`parity.md`:** row 375 (`canvas_ui.dart`: no `devicePixelRatio` and no `logicalSize`, the
  attributes, the paint scale), row 382 (`platform.flutter.dart`: `initCanvas` and
  `releaseContext` line by line over the attributes), row 383 (`chart_host.dart`: "the DOM bitmap
  stretch" becomes "paint maps the bitmap to the display size"), row 389 (`canvas_ui_test.dart`)
  and row 419 (`chart_host_test.dart`). The spec rows do not change. C2 also changed row 380
  (`canvas.dart`: the 3 attribute members) and row 418 (`platform.flutter_test.dart`: the new
  tests).
- **`differences.md`:** no row for option A.
- **`performance.md`:** record the figures after the change (§6.3). C2 did not record them.

### 3.8 Risks

1. **Sharpness** (medium). The paint mapping must keep the exact 1 / DPR snap. Without it,
   fractional `round1` sizes resample the flattened images and the atlas of the circle batch. Test
   4 of A2 pins it. Check the Stress tab on the Pixel 8a by eye.
2. **The attributes change the initial ratio** (low). A responsive chart on a canvas that has
   explicit `width` and `height` now takes its initial `_aspectRatio` from them. That is the
   upstream behavior. The gallery uses default canvases and does not change.
3. **The interface grows** (low). `HTMLCanvasElement` gets 3 members. Most fakes use
   `noSuchMethod`. Two fakes did not use it: C2 gave them the 3 members (§3.5).
   `MockContext.canvas` does not change.
4. **The one-style rule moves to the harness** (medium, phase 5). If the harness does not carry
   it, the 3 aspectRatio cases of `platform.dom` fail.
5. **The saving is small.** About 90 lines go and about 80 lines come. The gain is correctness and
   one paint mapping in place of two. C2 removed 134 library lines and added 159 (§3.9).

### 3.9 Estimated lines

| Area | Removed | Added | Removed by C2 | Added by C2 |
|---|---:|---:|---:|---:|
| `chart_host.dart` (`chartSize` branches, stretch block, DPR writes, doc) | ~45 | ~15 | 65 | 51 |
| `canvas_ui.dart` (DPR field and accessors, `logicalSize`, paint, doc) | ~25 | ~3 | 50 | 75 |
| `UiCanvasElement` attributes | 0 | ~35 | (in `canvas_ui.dart`) | (in `canvas_ui.dart`) |
| `canvas.dart` interface | 0 | ~18 | 0 | 16 |
| `platform.flutter.dart` (doc, the `null` constants, the 300 x 150 branch) | ~20 | ~8 | 19 | 17 |
| **Library total** | **~90** | **~80** (net about -10) | **134** | **159** (net +25) |
| Tests (A2 and C2) | ~45 | ~340 (A2: 241) | 67 (C2) | 223 (C2), 241 (A2) |

The counts of C2 are the `git diff --numstat` lines against commit 69f9d97 (for the library) and
against the tree after A2 (for the tests). `canvas_ui.dart` is 1644 lines after C2: the attribute
model is 68 lines (137-204). The two test fakes and the 3 other `paint` callers of §3.5 are in the
test counts.

### 3.10 Result of work package C2

Work package C2 landed in phase 5 on 2026-10-19 (Deferral, trigger 1). The code after C2:
- `lib/src/canvas/canvas.dart` (983 lines): `HTMLCanvasElement` (326-363) has `getAttribute`,
  `setAttribute` and `removeAttribute` (350-362).
- `lib/src/canvas/canvas_ui.dart` (1644 lines): the library doc of the paint scale (25-33).
  `UiCanvasElement` (131-237) has the constructor `{int? width, int? height}` (137-143), the
  reflection in the `width` and `height` setters (157, 165), `getAttribute`, `setAttribute` and
  `removeAttribute` (167-180), and `_setSize` (182-204). `UiCanvasContext.paint(canvas, offset,
  scaleX, scaleY)` is at 435-460.
- `lib/src/platform/chart_host.dart` (902 lines): the library doc (31-36), the DPR setter with
  `markNeedsPaint` (331-342), `displaySize` (473-486), `_laidOutDisplaySize` and
  `_checkDisplaySize` (488-518), the paint doc and the one mapping (606-610, 633-644), and
  `debugFillProperties` (900).
- `lib/src/platform/platform.flutter.dart` (622 lines): `_Initial[prop]` (85-86), `initCanvas`
  (109-178, the `getAttribute` reads at 125-126) and `releaseContext` (458-493, the attribute loop
  at 468-475).

Differences from §3.4:
- Step 1: §3.4 said that all test fakes use `noSuchMethod`. Two fakes do not use it (§3.5).
- Step 2: the attribute model has 68 lines, not 35. The setters, `setAttribute` and
  `removeAttribute` share `_setSize`. `_setSize` applies the HTML rules for parsing non-negative
  integers, except for `-0`. The removal of an absent attribute does nothing, as in the DOM. The
  attribute names are ASCII case-insensitive.
- Step 3: `paint` calls `canvas.scale` only when a scale is not 1.
- Step 4: the doc of `initCanvas` keeps the sentence on `display` and `box-sizing`. `_Initial` gets
  `operator []` for `initial[prop]`. `releaseContext` calls `isNullOrUndef` of `helpers.core`, as
  upstream does.
- Step 5: line 332 (the DPR write to the canvas) becomes `markNeedsPaint()`, because the snap to
  `1 / DPR` reads the DPR of the host. A bitmap side of 0 gives a scale of 1. `_laidOutChartSize`
  and `_checkChartSize` become `_laidOutDisplaySize` and `_checkDisplaySize`. C2 did not add
  `debugPaintScale`: the tests read the `Canvas.scale` calls.
- The gallery code did not change. `apps/chartjs_gallery` builds for the web (wasm) and for
  Android. Its tests pass.

Not done in C2: the figures of §6.3 (work package P), the cut 2 checks of §6.4 (the browser zoom,
a move between displays) and the look at the Stress tab on the Pixel 8a (§3.8, risk 1). The
figures of §6.3 for C2 are now in [performance.md](performance.md) §9 (§5).

## 4. Cut 3: record only

Cut 3 changes no code.

### 4.1 Circle batch

`CircleBatch` (`lib/src/canvas/canvas_ui_batch.dart`, Chart.js ADR 0013 §8.1, performance.md
§5.4) stays. On the Pixel 8a it raised 20000 + 0 from 11.4 to 55.2 FPS and cut the raster time
from 82.7 ms to 9.8 ms (performance.md §4.2). Flutter does not merge `drawCircle` calls on
Impeller. Chrome's Skia does.

- **Upstream report.** Work package P drafts a Flutter feature request: "Impeller: batch
  consecutive `drawCircle` calls with one paint". It gives the baseline A scene of performance.md
  §4.4 (a `CustomPainter` with `drawCircle`) and the Pixel 8a figures. The maintainer files it.
  Then P records the issue link in performance.md §7.
- **Removal criterion.** Remove the batch when a stable Flutter release batches or merges
  `drawCircle` calls on Impeller (Vulkan and Metal) and on skwasm, so that baseline A reaches the
  figures of the batch within noise on the Pixel 8a at 20000 + 0. Then run the six scenarios of
  §6.3 with and without the batch, and remove the batch with its test group "circle batch" and
  Chart.js ADR 0013 §8.1 (a new ADR if 0013 is accepted by then).

### 4.2 Text rotation snap

The 2 degree snap of text rotation (Chart.js ADR 0015 §3, performance.md §5.5) stays. It avoids
the skwasm strike-cache race. The fixes are on Flutter `master`:
- [flutter/flutter#190048](https://github.com/flutter/flutter/pull/190048) gives each thread its
  own strike cache.
- [flutter/flutter#191014](https://github.com/flutter/flutter/pull/191014) makes that flag
  official.
- [flutter/flutter#194139](https://github.com/flutter/flutter/pull/194139) makes the semaphores
  of the FreeType locks work.

On 2026-10-19, the stable release 3.47.7 has none of the three.

On 2026-10-21, the toolchain pin (`.fvmrc`) is the stable release 3.47.7 (Dart 3.13.5, engine
`deb287481e`). It has none of the three changes. Its release branch `flutter-3.47-candidate.0`
left `master` on 2026-07-08, before the three merges. The cherry-pick of #190048 to that branch
(flutter/flutter#192115) closed without a merge. The engine sources of 3.47.7 have no
`skwasm/wasm_worker_semaphore.cc`, and `skwasm/surface.cc` does not set a strike cache for each
thread. #190048 is in the beta releases from 3.48.0-0.1.pre, and #191014 is in the beta releases
from 3.49.0-0.1.pre. #194139 merged on 2026-10-17. Only `master` has it: the beta release
3.50.0-0.1.pre does not. Thus trigger 3 did not occur.

**Removal criterion:** the toolchain pin (`.fvmrc`) is a stable release with all three changes.
Then remove the snap and its test group "rotated text", and run the crash case of performance.md
§5.5 (20000 + 200, `SPIN=true`) 6 times with 0 crashes.

## 5. Work packages

Each work package has one owner and its own commit (or commits) on `main`, signed off, in
Conventional Commits form. Each work package updates its own rows of `parity.md` in the same
commit. The rows differ, so the edits do not overlap. Run the gates of §6.2 before each commit.

| ID | Title | Files touched | Depends on | Parallel with | Deliverable | Acceptance | Estimate |
|---|---|---|---|---|---|---|---|
| A1 | Cut 1 tests | `test/port/canvas/canvas_ui_path_test.dart` (new), `doc/parity.md` (new row) | — | A2, A3, I | The 20 tests of §2.6. The web probe results of the current code, in the commit message. | Green on the current code. Gates of §6.2. | ~400 test lines, 1 day |
| A2 | Cut 2 tests | `test/port/platform/chart_host_test.dart`, `test/port/platform/platform.flutter_test.dart`, `doc/parity.md` (row 419) | — | A1, A3, I | The 7 tests of §3.5 that pin the stretch and the display size | Green on the current code. Gates. | 241 test lines, 0.5 day. **Done in phase 5** (2026-10-19, trigger 1) |
| A3 | Arc scenario and new baselines | `apps/chartjs_gallery/lib/demo/stress_demo.dart`, `apps/chartjs_gallery/lib/main_stress.dart`, `apps/chartjs_gallery/test/canvas_host_demo_test.dart` (if needed), `apps/chartjs_gallery/test/stress_elements_test.dart` (if needed), `doc/performance.md` (new baseline section) | — | A1, A2, I | `--dart-define=POINT_STYLE=<style>` in the stress entry. The baseline of §6.3 on 3 platforms. A scratch micro-benchmark of 5000 wedges (not committed). See the note on A3 below. | Baseline recorded with the commit hash. Old tables marked stale. | ~40 lines, 1 day of runs |
| I | Renderer probes (optional) | `apps/chartjs_gallery/integration_test/canvas_paths_test.dart` (new), `apps/chartjs_gallery/pubspec.yaml`, root `pubspec.lock` | — | A1, A2, A3 | The web probes of §2.6 as a gallery integration test | Runs on the Pixel 8a, on macOS and in Chrome (dart2js and `--wasm`). Merge alone (lock file). | ~150 lines, 1 day |
| W | Web matrix aliasing fix | `lib/src/canvas/canvas_ui.dart` (1374, 1392), `lib/src/canvas/canvas_ui_paint.dart` (`shaderFor`), `doc/parity.md` (rows 375, 377) | A1 | A2, A3 | Step 0 of §2.5 | VM pixels unchanged. The stroke probe and the clip probe pass on CanvasKit and on skwasm. | ~6 lines, 0.5 day |
| C1 | Cut 1 code | `lib/src/canvas/canvas_ui_path.dart`, `test/port/canvas/canvas_ui_path_test.dart` (thresholds only), `doc/parity.md` (row 376) | A1, W | C2 | Steps 1 to 6 of §2.5 | All tests green. Web probes pass. Perf of §6.3 within the thresholds. | ~-45 net library lines, 1 day |
| C2 | Cut 2 code (option A) | `lib/src/canvas/canvas.dart`, `lib/src/canvas/canvas_ui.dart`, `lib/src/platform/platform.flutter.dart`, `lib/src/platform/chart_host.dart`, `test/port/canvas/canvas_ui_test.dart`, `test/port/platform/chart_host_test.dart`, `test/port/platform/platform.flutter_test.dart`, `doc/parity.md` (rows 375, 382, 383, 389, 419) | A2, W | C1 | Steps 1 to 6 of §3.4 and the test changes of §3.5 | All tests green. Gallery unchanged on web, macOS and the Pixel 8a. Perf within the thresholds. | ~-10 net library lines, ~+100 test lines, 1.5 days. **Done in phase 5** (2026-10-19, trigger 1) without W, with steps 1 to 7 of §3.4: net +25 library lines, +223 and -67 test lines (§3.9, §3.10). It also changed `canvas_ui_round_rect_test.dart`, `pixel_compare.dart`, `element.arc_test.dart`, `helpers.canvas_test.dart`, Chart.js ADR 0013, Chart.js ADR 0014, `porting-flow.md` and the `parity.md` rows 380 and 418. Its perf runs are in [performance.md](performance.md) §9 (the C2 acceptance below this table). |
| D | Docs | `doc/adr/0013-canvas-model.md`, `doc/adr/0014-input-events-and-chart-host.md`, `doc/porting-flow.md` | C1, C2 | P | §2.7 and §3.7 (ADR and porting-flow parts), and a "Removal" bullet in Chart.js ADR 0013 §8.1 (§4.1). C2 did the §3.7 part in phase 5. | Status lines unchanged. Links resolve. | ~60 changed lines, 0.5 day |
| P | Perf results and cut 3 notes | `doc/performance.md` (results section, §7), this plan (status of each work package) | A3, C1, C2 | D | The figures of §6.3 after C1 and after C2. The removal criteria of §4. The draft of the Flutter feature request. | Every scenario within the thresholds of §6.3, or the miss explained | ~60 lines, 1 day of runs. The figures after C2 are done in phase 5 ([performance.md](performance.md) §9). |

**C2 performance acceptance** (2026-10-19, [performance.md](performance.md) §9). All scenarios
pass on macOS and in Chrome. On the Pixel 8a, 9 of 10 scenarios pass: `bars` 1000 fails the FPS
criterion of §6.3 in the first series and in the rerun, with draw and raster in the limits.
Section 9.5 of `performance.md` gives an A/A control: on two identical APKs, the 3-pair rule also
misses. Over 21 pairs, the frame rate and the raster time have no measured change. Decision: cut 2
stays (priority 1, the upstream behavior). The two iPhone 17 Pro smoke pairs pass, at the 120 Hz
limit on both sides (§9.2 and §9.3 of `performance.md`).

**Note on A3 (phase 4).** Phase 4 added the scene modes of the stress tab (§6.3). The stress
entry takes `--dart-define=MODE=<primitives|elements|bars|arcs|chart|axes>`, and the default is
`primitives`. Phase 5 added the mode `chart`: a real chart path with the typed options of the
resolver. Phase 6 added the mode `axes`: the points of the mode `chart` on the real scales of
phase 6. For A3, this means:
- The `arcs` mode draws `ArcElement` wedges under the retina scale. Thus `MODE=arcs` at 5000 + 0
  can serve the arc micro-benchmark (a) on all three platforms.
- The micro-benchmark (b), under a skew, still needs the scratch package. No mode draws under a
  skew.
- `POINT_STYLE` is still absent.
- `apps/chartjs_gallery/test/stress_elements_test.dart` tests the modes, their N choices and
  their controls. A change of the stress controls can need a change of that test.
- `performance.md` §1 and §6 describe the modes and `MODE`. Each `STRESS {json}` line of the stress
  entry starts with the key `mode`.
- `performance.md` §8.1 has the first figures of the four modes on the three platforms. They are
  not the baseline of §6.3, because each mode ran in one process, not in 3 fresh processes for
  each scenario. They show the scale of the arc cost before A3: at 1000 arcs, about 13.5 ms of
  draw time on the Pixel 8a. §8.2 shows that the native `Path.arcTo` calls are most of that cost.
- On macOS, a stress process with several scenarios stopped to give frames after about 28
  seconds in the phase 4 runs (`performance.md` §6). Run one scenario in each process, as §6.3
  asks.

### 5.1 Merge order

1. A1, A2 and A3 in any order. Each is green on the unchanged library.
2. I, if it is done. Merge it alone, because it changes the root `pubspec.lock`.
3. W, with the web probes.
4. C1, with its perf runs against the A3 baseline.
5. C2, with its own perf runs, so that a regression has one cause.
6. D.
7. P.

A2 and C2 landed in phase 5, before the other work packages (Deferral, trigger 1). The other
work packages stay deferred.

C1 and C2 touch different library files and can merge in either order. Run the perf checks after
each. Other work commits to the same tree. Before each commit, run `git status` and stage only the
files of the work package.

Commit message examples:
- `test(flutter_chartjs_port): pin arcs under skew, mirror and non-uniform scale`
- `fix(flutter_chartjs_port): copy the matrices that the web paths read late`
- `refactor(flutter_chartjs_port): build arcs under other transforms with dart:ui`
- `refactor(flutter_chartjs_port): give the canvas attributes and one paint scale`

## 6. Verification and acceptance

### 6.1 Tests

- The tests of §2.6 and §3.5 that exist now stay green without a change, except the changes that
  §3.5 names.
- The new tests of A1 and A2 are green on the current code before C1 and C2 start.
- `check:headers` needs the port-only line-1 marker on the new test files. `check:lib-imports`
  needs `@TestOn('vm')` on each test file that imports `dart:ui` or `flutter_test`.

### 6.2 Gates

Run these from the repository root before each commit (AGENTS.md):
- `dart run melos run format:check`
- `dart run melos run analyze`
- `dart run melos run test --no-select`
- `dart run melos run test:web`
- `dart run melos run test:cases`
- `dart run melos run check:port`
- `dart run melos run gallery:build:web` (wasm)

Before a push, also run the dart2js and dart2wasm tests and the gallery on wasm in the VS Code
integrated browser. `test:web` does not compile `dart:ui`, so it gives no web coverage for these
cuts. The web probes of §2.6 and the checks of §6.4 give it.

### 6.3 Performance

Use `apps/chartjs_gallery/lib/main_stress.dart` (performance.md §6): profile build, fresh process,
7 seconds for each scenario, the figures of the first seconds.

- **Scenarios:** 1000 + 0, 1000 + 50, 5000 + 50, 20000 + 0, 1000 + 200 and 20000 + 200. Add
  `POINT_STYLE=rectRounded` at 5000 + 0 and 20000 + 0 (four quarter arcs for each point, on the
  direct arc path).
- **Arc micro-benchmark:** 5000 wedges with `arc` and `closePath`, (a) under the retina scale and
  (b) under a skew, in the scratch package (VM and skwasm). (a) must not change. (b) costs about
  3 times more (§2.8).
- **Modes (phase 4):** `--dart-define=MODE=<primitives|elements|bars|arcs>` selects the scene of
  the stress entry. The default is `primitives`, the scene of the six scenarios above. `elements`
  draws the same scene with `PointElement` and `LineElement`. `bars` draws N `BarElement` objects
  with rounded corners. `arcs` draws N `ArcElement` wedges, in doughnuts of 2 rings with 5 slices,
  under the retina scale. Its default scenarios are 100 + 0, 1000 + 0 and 5000 + 0. Thus
  `MODE=arcs` at 5000 + 0 can serve the arc micro-benchmark (a) on all three platforms. Each of
  these wedges has rounded corners and a border, so its figures do not compare with the figures
  of §2.8. The micro-benchmark (b) still needs the scratch package, because no mode draws under a
  skew. `POINT_STYLE` is still absent. In the element modes, the draw figure also has the writes
  of the element properties.
- **Runs:** 3 fresh processes for each scenario. Take the median FPS, draw (ms) and raster (ms).
  The spread from the minimum to the maximum is the noise.
- **Platforms:** the Pixel 8a (Impeller on Vulkan, 60 Hz), Chrome with dart2wasm and skwasm (raster
  time on the worker), macOS (Apple M3 Max). A CanvasKit smoke run at 5000 + 50 and with
  `rectRounded`.

**A new baseline is necessary.** The figures in performance.md cannot serve as the baseline: §2
(macOS) and §3 (Chrome) are from before the circle batch, and §4.2 (Pixel 8a) used nearest
sampling of the atlas. Work package A3 measures the baseline on the commit before W, in the same
session and the same device state. The current figures are for orientation only:

| Scenario | macOS FPS / draw / raster (§2.2, before the batch) | Chrome draw / raster (§3, before the batch) | Pixel 8a FPS / draw / raster (§4.2, after the batch, nearest sampling) |
|---|---|---|---|
| 1000 + 0 | 60 / 0.9 / 2.8 | 0.8 / 5.9 | 58.2 / 4.9 / 4.8 |
| 1000 + 50 | 60 / 0.9 / 2.7 | — | 57.7 / 5.0 / 5.5 |
| 5000 + 50 | 60 / 3.1 / 9.5 | 2.4 / 16.3 | 58.9 / 6.7 / 6.3 |
| 20000 + 0 | 39.9 / 11.9 / 23.9 | 9.3 / 38.6 | 55.2 / 11.4 / 9.8 |
| 1000 + 200 | 60 / 1.2 / 2.7 | — | 58.2 / 6.9 / 7.5 |
| 20000 + 200 | 39.9 / 12.1 / 23.8 | 10.0 / 42.1 | 54.9 / 12.0 / 11.0 |

**Acceptance for each scenario and platform:**
- The median FPS is at least the baseline median minus the larger of 1 FPS and 2 %.
- The median draw and the median raster are at most the baseline median times 1.05 plus 0.2 ms.
- No single run is outside the baseline range widened by the same margins.

A miss runs 3 more times. A miss that stays fails the work package. On the Pixel 8a, the FPS is
at the 60 Hz limit at 1000 points, so draw and raster are the main figures there. The batch
figure on the phone must hold (about 55 FPS at 20000 + 0).

Expected results: W, C1 and C2 are neutral. The `primitives` and `elements` scenes draw full
circles (the pending circle and the batch), lines and text. The `bars` and `arcs` scenes also draw
arcs, but only under the retina scale. No scene reaches the matrix path. `rectRounded` stays on
the direct path. C2 changes only the transform of the host paint.

### 6.4 Web checks

- **The aliasing probes** (§2.6) on CanvasKit (`flutter test --platform chrome`) and on skwasm
  (`--wasm`), in the first frame and after at least one more frame. Before W the stroke probe
  fails. After W and C1 all probes pass.
- **Skwasm `drawRawAtlas` cap:** run 20000 + 0 for 60 seconds with no `memory access out of
  bounds`. `git diff --stat` shows no change in `canvas_ui_batch.dart`.
- **Strike-cache race:** run 20000 + 200 with `SPIN=true` 6 times with 0 crashes (performance.md
  §5.5).
- **CanvasKit:** `flutter run -d chrome --profile` without `--wasm`. Check the Canvas tab (arcs,
  `rectRounded`, the dashed arc, the `Path2D` card) and the stress run at 5000 + 50.
- **Memory:** a `rectRounded` stress scene for 60 seconds. The heap stays flat.
- **Cut 2:** browser zoom at 90 %, 110 % and 125 % (fractional DPR), and a move of the window from
  a Retina display to a non-Retina display. Check the Events tab readout (`canvas.width x height`
  against the display size), no blur, and the sizes. This also closes the Chart.js ADR 0014 Open
  item "A DPR change on a real device is not verified".
