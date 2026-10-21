# Chart.js ADR 0033: Radial scale centers before the first layout

- Status: accepted (2026-10-21)
- Date: 2026-10-21
- Supersedes: [Chart.js ADR 0025](0025-scale-value-parameters.md) §5, the bullet
  `double get xCenter`, `double get yCenter`, only (on acceptance)
- Related: [Chart.js ADR 0003](0003-type-only-dependencies.md) (type libraries, a member with its
  first ported caller, records for inline object types),
  [Chart.js ADR 0006](0006-options-representation-and-resolver.md) ("Values outside scopes":
  Dart `null` for `undefined`; the `undefined` sentinel),
  [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0010](0010-js-numeric-semantics.md) (`ToNumber`, `sin` and `cos` on `dart:math`,
  the reference engine),
  [Chart.js ADR 0017](0017-element-properties.md) §4 and Alternatives (the `undefined` state of an
  element property; "NaN for `undefined` without a nullable field" is rejected),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13 (a gain that only a
  microbenchmark measures),
  [Chart.js ADR 0025](0025-scale-value-parameters.md) §1 and §5 (the value parameters, the
  members of phase 7),
  [Chart.js ADR 0028](0028-controller-interfaces.md) §1 (the interface members of phase 7),
  [Chart.js ADR 0030](0030-controller-test-strategy.md) (the controller tests),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [performance.md](../performance.md) §13,
  [phase7/design/radial-center/judge.md](../../../../.handover/phase7/design/radial-center/judge.md) (the panel
  result), decisions D11, D13 and D14 of [phase7-progress.md](../../../../.handover/phase7-progress.md)

## Context

Accepted Chart.js ADR 0025 §5 gives the members of `types.RadialLinearScale` that the phase 7
controllers read. It gives `double get xCenter` and `double get yCenter`. Decision D11 item (a)
of phase 7 (unit X-fix) changed the two members to `double?`. The reason: upstream has two
different values that are not numbers, and the port lost one of them. An accepted ADR does not
change. Thus this ADR records the change. Decision D14 asks for it.

### Upstream facts at the pin `v4.5.1+7169e651`

All paths are relative to `third_party/Chart.js/src/`. The commit is
`7169e65147a47f3720957a6f156a33c838ab9f57`.

| Fact | Source |
|---|---|
| The constructor sets `xCenter`, `yCenter` and `drawingArea` to `undefined`. | `scales/scale.radialLinear.js:416`, `:418`, `:420` |
| `setDimensions` writes `Math.floor(...)` into the two centers. | `scales/scale.radialLinear.js:431-432` |
| `setCenterPoint` adds to the centers. `undefined + n` is NaN. | `scales/scale.radialLinear.js:477-478` |
| `getPointPosition` adds `this.xCenter` and `this.yCenter` to `Math.cos` and `Math.sin` terms. | `scales/scale.radialLinear.js:520-527` |
| The radar writes `reset ? scale.xCenter : pointPosition.x` raw into the element. `skip` is `isNaN(x) \|\| isNaN(y)`, and `isNaN(undefined)` is true. | `controllers/controller.radar.js:88`, `:90-91`, `:97` |
| The polar area reads the centers once for each update and writes them raw into each arc. | `controllers/controller.polarArea.js:167-168`, `:169`, `:182` |
| `Animation` gets `to = resolve([cfg.to, to, currentValue, cfg.from])` and `from = resolve([cfg.from, currentValue, to])`. `resolve` skips `undefined` and keeps NaN. | `core/core.animation.js:31-32`, `helpers/helpers.options.ts:154-171` |
| A running animation from NaN gives NaN. `tick` writes the target only at the end. | `core/core.animation.js:76-90`, `:88` |
| The reset before the first layout of a scale has one path: an existing controller gets new items in an `update()` that also makes the scale of its `rAxisID`. `_insertElements` resets the new items before `_updateLayout`. A new controller resets after the layout. | `core/core.controller.js:482`, `:503-519`; `core/core.datasetController.js:985`, `:1017-1018` |
| The type file declares `xCenter: number` and `yCenter: number`. It does not show the `undefined` state. | `types/index.d.ts:3676-3688` (`:3677`, `:3678`) |
| The filler of phase 8 tests `if (scale.getPointPositionForValue)`. | `plugins/plugin.filler/filler.target.js:50` |

ADR 0025 §5 cites `index.d.ts:3627-3639` and `controller.polarArea.js:165-166`, `:167`, `:180`.
These are the v4.5.1 lines (`git show v4.5.1:<path>`). At the pin, the same lines are
`index.d.ts:3676-3688` and `controller.polarArea.js:167-168`, `:169`, `:182`. The shift comes from
the new `spacing` and `spacingMode` defaults of `controller.polarArea.js` and from other parts of
`index.d.ts`. `git diff v4.5.1 7169e651` shows no change in `scale.radialLinear.js`,
`controller.radar.js`, `core.animation.js`, `helpers.options.ts` or the radial interface. Thus the
three members that this ADR does not change keep their ADR 0025 forms.

### Three states of a center

| State | When | Effect on a new element |
|---|---|---|
| `undefined` | before the first layout of the scale | The reset writes `undefined`. The next animation starts at its target. The element is drawn and hit at once. |
| NaN | after a layout that gives NaN (for example a new scale with `position: 'left'`), or `undefined + n` | The reset writes NaN. The next animation starts at NaN. The element is not drawn and not hit until the animation ends. |
| a number | after a normal layout | The usual case. |

JS `null` never reaches the two fields in Chart.js code. The two states that are not numbers give
different hit elements. Chart.js ADR 0009 protects the hit element.

### The port before and after D11

Before D11, the fields were `double` with the start value NaN. The reset of case A (below) wrote
NaN. The new item was not drawn and not hit for the full animation (1000 ms by default). Upstream
draws and hits it at once. After D11, the fields are `double?`. Dart `null` is `undefined`. The
port gives the upstream values in each probe case below.

## Decision

### 1. The members of `types.RadialLinearScale` in phase 7

`types.RadialLinearScale implements Scale` (`index.d.ts:3676-3688`) has these five members.
`RadialLinearScale` of `lib/src/scales/scale.radialLinear.dart:741` implements it.

| Dart member | Upstream | Readers | Against ADR 0025 §5 |
|---|---|---|---|
| `double? get xCenter` | `index.d.ts:3677`; `scale.radialLinear.js:416`, `:431`, `:477` | `controller.polarArea.js:167`; `controller.radar.js:90` | `double` becomes `double?` |
| `double? get yCenter` | `index.d.ts:3678`; `scale.radialLinear.js:418`, `:432`, `:478` | `controller.polarArea.js:168`; `controller.radar.js:91` | `double` becomes `double?` |
| `double getIndexAngle(double index)` | `index.d.ts:3681` | `controller.polarArea.js:169` | no change |
| `double getDistanceFromCenterForValue(Object? value)` | `index.d.ts:3682` | `controller.polarArea.js:182` | no change |
| `({double x, double y, double angle}) getPointPositionForValue(double index, Object? value)` | `index.d.ts:3685` | `controller.radar.js:88` | no change |

The value parameters are `Object?` (Chart.js ADR 0025 §1). The result of
`getPointPositionForValue` is a record (Chart.js ADR 0003; ADR 0025 Open 5). Another member of
`index.d.ts` (for example `drawingArea`, `setCenterPoint`, `getPointPosition` or
`getBasePosition`) comes with its first ported reader (Chart.js ADR 0003). The filler of phase 8
tests `scale is types.RadialLinearScale` for `if (scale.getPointPositionForValue)`, as ADR 0025 §5
states.

### 2. The states

- Dart `null` in `xCenter` and `yCenter` is the JS `undefined` start value
  (`scale.radialLinear.js:416`, `:418`). Chart.js ADR 0006 ("Values outside scopes") allows it,
  because JS `null` never reaches these fields. The `///` line of each member says so.
- NaN is the JS NaN: a layout that gives NaN, or `setCenterPoint` on `undefined`.
- A finite value is the laid-out center.

The port has two precedents for a nullable getter where `index.d.ts` gives `number`:
`types.ChartMeta.total` (`lib/src/types/index.dart:225`, upstream `index.d.ts:374`) and
`types.RadialPointElement.angle` (`lib/src/types/index.dart:1187`).

### 3. The concrete fields and their reads

- `RadialLinearScale` has the fields `double? xCenter` and `double? yCenter` with the start value
  `null` (`scale.radialLinear.dart:843`, `:848`).
- `setDimensions` writes numbers (`:877-878`).
- A read in arithmetic or in a canvas call is `xCenter ?? double.nan`, the `ToNumber` of
  `undefined`: `setCenterPoint` (`:958-962`), `getPointPosition` (`:1044-1045`) and the canvas
  calls (`:613-614`, `:1173`, `:1211`). Thus `undefined + n` gives NaN, as upstream.

### 4. The controller writes

- The radar and polar area controllers write `center ?? undefined` into the element properties
  (`controller.radar.dart:211-212`, `controller.polarArea.dart:403-404`).
- The radar `skip` is `x == null || x.isNaN || y == null || y.isNaN`
  (`controller.radar.dart:214`), because `isNaN(undefined)` is true.
- The polar area reads the two centers once for each update (`controller.polarArea.dart:373-374`),
  as upstream.

### 5. `drawingArea`

`drawingArea` stays `double` with NaN for `undefined` (`scale.radialLinear.dart:852`). No reader
writes it into an element, so the two states give the same result. A later reader that writes it
into an element applies sections 2 to 4 to it.

### 6. No `DIVERGES` row

The port gives the upstream runtime values. The Dart type differs from the declaration
`xCenter: number`, not from the runtime value. Thus no `DIVERGES(chartjs)` marker and no
`differences.md` row.

### 7. The scope of the supersession

On acceptance, this ADR supersedes Chart.js ADR 0025 §5, the bullet `double get xCenter`,
`double get yCenter` (`controller.polarArea.js:165-166`, `controller.radar.js:90-91` in the
v4.5.1 lines), only. The other parts of ADR 0025 stay in force: §1-§4, the `types.Scale` table of
§5, the three other radial members of §5, the `is` test of §5, and §6-§9. This ADR repeats the
three other radial forms without a change. The status line and the text of ADR 0025 do not change.
The maintainer adds the record of the supersession to ADR 0025 when they accept this ADR.

### 8. Tests

Each test below fails under at least one rejected option of Alternatives. Each hit query is more
than 1 px from each border of its element (decision D13). Thus a last-bit difference of `sin` or
`cos` does not change the hit list. After Chart.js ADR 0032 (§10 and Alternatives), D13 is not
necessary, but the pins stay valid. The expected values come from the x64 Node.js v24.12.0 on the
build of Chart.js at the pin (Chart.js ADR 0010). The port gives them (Evidence E3).

Existing pins, kept:
- `test/port/scales/scale.radialLinear_test.dart:284-285`: a new scale has `xCenter` and
  `yCenter` `isNull`, and `drawingArea` NaN.
- `test/port/controllers/controller.radar_test.dart:316`, group
  `the reset on a new radial scale`: the reset writes `undefined`, `skip` is true, the animations
  go from 25 to 25 and from 256 to 256.
- `test/port/controllers/controller.polarArea_test.dart:492`, the same group: the reset writes
  `undefined`, the animations go from 256 to 256; and `a NaN center after a layout animates x to
  NaN`.
- `test/port/types/index_test.dart:195-214`: the laid-out center through the interface is not null
  and is 256.
- `test/port/core/core.animation_test.dart` (4 tests) and `core.animation_cancel_test.dart`
  (2 tests): an animation from NaN keeps NaN.

New pins:
1. Case A, the hit at 500 ms. Radar: `point` and `nearest` at (25, 256) give `[[0, 3]]`, and `x`
   is 25. Polar area: `point`, `nearest`, `nearest` with `axis: 'r'` and `index` with `axis: 'r'`
   at (168.31875913286808, 168.3187591328681) give `[[0, 3]]`, and `x` is 256.
2. Case E2 in both files, a reset at a NaN center, then the dataset goes back to the scale `r`.
   After the reset, `x` and `y` are NaN. After the update, the animation of `x` goes from NaN to
   the target. At 1 ms and 500 ms, `x` is NaN and the query at the final position gives `[]`. At
   1100 ms, the query gives `[[0, 1]]`.
3. Case C, a radar point with `r` `null` that gets a value. The animation of `x` goes from NaN to
   371.5. At 1 ms and 500 ms, `x` is NaN and `point` at (371.5, 256) gives `[]`. At 1100 ms it
   gives `[[0, 1]]`.
4. The static type of `t.xCenter` and `t.yCenter` through `types.RadialLinearScale` is `double?`.

The implementation spec is
[phase7/design/radial-center/spec.md](../../../../.handover/phase7/design/radial-center/spec.md).

### 9. Relation to the `sin` and `cos` decision

`getPointPosition` calls `jsCos` and `jsSin` (Chart.js ADR 0032 §3, proposed). Before Chart.js
ADR 0032, it called `dart:math` `cos` and `sin` (accepted Chart.js ADR 0010 §3). CI run
39544591156 failed on Windows on a doughnut hit query on the border of two symmetric arcs (the
MSVC CRT `sin` and `cos`). U-pie review F2 found a reachable pie hit that differs from V8 by a
1-ulp `sin`. Chart.js ADR 0032 decides that question. This ADR is independent of it: the center
type does not change the `sin` and `cos` calls, and a change of those calls does not change the
center reads. This ADR adds no third-party code.

## Alternatives considered

The probes ran each option in the upstream build (an emulation) and as a `lib/` diff in a scratch
copy of the port (Evidence E2-E4). "U" is the upstream result. The cases:
- **A**: radar or polar area `[1, 2, 3]`, labels `a`-`d`, `animation: {}`. Then
  `rAxisID: 'r2'` and `push(4)` in one `update()`.
- **B**: polar area after its layout; a new scale `r2` with `position: 'left'` gives the center
  NaN (the X-fix case `newAxisId`).
- **C**: radar `[1, null, 3, 2]`; then `data[1] = 2`.
- **E2**: labels `a`-`e`, data `[65, 59, 90, 81, 56]`; a scale `r2` with `position: 'left'`;
  `chart.reset()`; then `rAxisID: 'r'` and `update()`.

| Option | Form | Priority 1 (behavior) | Priority 2 (performance) | Priority 3 (structure) | Verdict |
|---|---|---|---|---|---|
| A (selected) | `double?`, Dart `null` is `undefined` | U in A, B, C and E2 | see the table below | one field with the upstream name and states; the upstream reads at their sites | select |
| N | `double` with the start value NaN, as ADR 0025 §5 states; also a `DIVERGES` row | Fail. Case A: at 500 ms `x` is NaN, not drawn, the hit is `[]` (U `[[0, 3]]`), radar and polar area | fastest by 0.5-0.9 ns for each position call on AOT | the declared type | reject |
| NA | N, and `core.animation` reads a NaN current value as `undefined` | Fail. Case C: hit `[[0, 1]]` at 1 ms and 500 ms (U `[]`). E2: radar hit at 1 ms, polar area hit at 500 ms (U `[]`). 6 existing animation tests fail. Chart.js ADR 0017 rejects the same rule. | n/a | changes a shared layer for all charts | reject |
| V2 | N, and the controllers write `undefined` for a NaN center | Fail. Case B: `x` stays 256 (U NaN). Case C: drawn at (364.28125, 256) at 500 ms (U NaN). E2: hit at 1 ms (radar) or 500 ms (polar area) (U `[]`). | n/a | a guess that upstream does not make | reject |
| V2r | V2 in the reset path only | Fail. E2: the same hits as V2 (U `[]`). | n/a | as V2 | reject |
| S | `Object?` with the `undefined` sentinel | Pass (the same states as A, one to one) | wasm radar item +27 to +33 ns | the `Object?` type and a cast or type test at each reader; Chart.js ADR 0006 keeps the sentinel for raw JS values | reject |
| F | `double` with NaN and a port-only flag, for example `bool get centerDefined` | Pass | at most 1 ns faster than A for each position call on AOT | a member that `index.d.ts` does not have; one upstream value in two members | reject |
| R | `double` getter with NaN and the read by name `scale['xCenter']` at the two controller sites (the pattern of Chart.js ADR 0017 §4) | Pass | as F | moves the two controller reads away from `scale.xCenter` | reject |

Priority 2 selects only among the options that pass priority 1 (A, S, F, R). F and R are faster
than A only in microbenchmarks, and they change the structure. Chart.js ADR 0020 §13 asks for a
frame gain of at least 0.1 ms for such a form. A gain of at most 1 ns for each call, at tens of
calls for each radar draw, cannot give it.

Microbenchmark of the forms (Apple M3 Max, Dart 3.12.2; ns for each call or item; the range of 3
process medians of 15 samples; the wasm runs on Node.js v24.12.0 arm64, V8 as in Chrome):

| Kernel | A `double?` | N `double` | S `Object?` | F flag | R by name |
|---|---|---|---|---|---|
| `getPointPositionForValue`, AOT | 10.61-11.03 | 10.06-10.18 | 11.08-11.41 | 10.05-10.36 | 10.06-10.17 |
| `getPointPositionForValue`, wasm | 18.43-19.01 | 18.11-18.31 | 18.35-18.97 | 17.96-18.37 | 18.04-18.32 |
| radar properties, default, AOT | 97.08-98.62 | 96.55-96.88 | 96.66-99.09 | 95.77-99.01 | 94.65-97.91 |
| radar properties, default, wasm | 64.71-66.30 | 67.92-69.01 | 93.35-97.48 | 70.11-71.29 | 68.97-70.59 |
| radar properties, reset, AOT | 94.23-97.57 | 92.89-95.44 | 95.34-98.00 | 99.09-102.77 | 92.31-96.39 |
| radar properties, reset, wasm | 63.60-64.75 | 67.18-69.04 | 92.90-96.93 | 68.89-71.45 | 73.53-76.64 |
| polar area properties, AOT | 161.41-163.21 | 161.47-162.95 | 161.72-162.48 | 159.06-161.98 | 158.27-161.51 |
| polar area properties, wasm | 61.29-61.89 | 64.11-64.55 | 61.44-63.16 | 61.60-62.58 | 62.05-62.42 |

- A replica of `getPointPositionForValue` with `getIndexAngle` behind the interface gives
  A 54.2-54.7 ns and N 53.7-53.9 ns on AOT, and A 75.9-77.7 ns and N 68.5-69.5 ns on wasm. A
  re-run under machine load gave A +1.2 to +7.6 ns against N on wasm. Thus the wasm cost of A in
  the position call is +0.2 to +10 ns, by kernel. For one radar item, the Map write on wasm gives 3
  to 5 ns back, because the `double?` value is a box already.
- A real `chart.update()` with 1000 items (JIT, `animation: false`, median of 25) costs 33.58 µs
  for each radar item and 4.33 µs for each polar area item. 5 ns is 0.015 % and 0.12 % of that.

Other alternatives:
- **Read the centers into locals first in `getPointPosition`.** A small inlined AOT kernel showed
  12 ns when `?? double.nan` is inside the record literal (19.2-21.5 ns against 7.7-9.1 ns). The
  replica with `getIndexAngle` (at most 1 ns) and the real code under JIT (60 ns for both forms)
  do not show it. Not taken now (Open 2).
- **A private unboxed copy of the center for `getPointPosition`.** It saves 0.5-0.9 ns for each
  AOT call, and adds a second state that must stay equal to the first. Rejected.
- **A new ADR that states all of ADR 0025 again.** About 700 lines to change two lines. Each later
  change of an ADR 0025 rule then needs the copy. Rejected.
- **A note in proposed Chart.js ADR 0028 only.** The accepted ADR 0025 then states a form that the
  code does not have, and the rule "a changed decision gets a new ADR" is not met. Rejected.
- **The polar area case E of the simplicity draft** (a reset at a NaN center, then
  `position: 'chartArea'` on `r2`). The probe gives `outerRadius` NaN in the final state. Thus the
  arc is not hit in any option, and the case cannot pin the hit element. Case E2 replaces it.

## Consequences

- No `lib/` code changes. The code of D11 is the decision.
- One null test at each center read: 0.5-0.9 ns for each position call on AOT, +0.2 to +10 ns on
  wasm by kernel, and 3-5 ns less for each radar item on wasm. No frame effect: the largest
  difference reaches 0.1 ms only at 100,000 calls for each frame.
- A user scale that implements `types.RadialLinearScale` declares `double? get xCenter` and
  `double? get yCenter`. A `double` getter is a valid override of `double?`. A reader through the
  interface must handle `null`.
- Proposed Chart.js ADR 0028 §1 and `porting-flow.md` §2.19 refer to this ADR for the record.
- The four new pins of section 8 make each rejected option fail at least one test.
- When the maintainer accepts this ADR, ADR 0025 gets the record of a partial supersession.

## Open

1. **No frame figure.** No unit measured the frame, draw or raster time of a radar or polar area
   chart on the Pixel 8a, macOS, Chrome with dart2wasm or the iPhone for the forms. A is the only
   form that keeps the structure and the behavior, so the microbenchmark is sufficient (Chart.js
   ADR 0020 §13). A frameless radar case of `apps/chartjs_gallery/lib/main_bench.dart` can give
   the figures later.
2. **The locals form of `getPointPosition`.** That frameless radar case can check the 12 ns AOT
   artefact. A measured gain takes the form with a pin test and a record in `performance.md`. It
   needs no new ADR: the form keeps the structure.
3. **The `sin` and `cos` decision** (Chart.js ADR 0032, proposed). Its `jsCos` and `jsSin` change
   the cost of `getPointPosition` for all forms by the same amount. It does not change this decision.
4. **The filler of phase 8.** It reads `getPointPositionForValue` through the interface
   (`filler.target.js:50`, `:82`, `:91`). If it also reads `xCenter`, it handles `null` by
   section 3.

## Evidence

`<sp>` is the session scratchpad
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad`.
The Node.js probes ran on the x64 build of Node.js v24.12.0 under Rosetta, on the build of
Chart.js at the pin, from `packages/flutter_chartjs`:
`/usr/bin/arch -x86_64 <sp>/env/node-v24.12.0-darwin-x64/bin/node <probe> <sp>/env/chartjs-build/dist/chart.js`.
Each output starts with `arch x64 node v24.12.0 version 4.5.1`. `loadChartJs` of
`tool/reference/controller_chart_common.mjs` stops on another arch or commit. The Dart probes ran
with `flutter test <file>` from `packages/flutter_chartjs`.

- **E1, upstream source** at `7169e651`: `scales/scale.radialLinear.js:416-420`, `:426-433`,
  `:476-480`, `:520-531`; `controllers/controller.radar.js:82-100`;
  `controllers/controller.polarArea.js:160-213`; `core/core.animation.js:29-32`, `:76-90`;
  `helpers/helpers.options.ts:154-171`; `core/core.controller.js:482`, `:495-519`;
  `core/core.datasetController.js:985`, `:994-1018`; `types/index.d.ts:374`, `:3676-3688`;
  `plugins/plugin.filler/filler.target.js:50`. The line shift against v4.5.1:
  `git show v4.5.1:src/types/index.d.ts` (`:3627`) and
  `git show v4.5.1:src/controllers/controller.polarArea.js` (`:165`, `:167`, `:180`);
  `git diff v4.5.1 7169e651 -- src/scales/scale.radialLinear.js src/controllers/controller.radar.js src/core/core.animation.js`
  is empty.
- **E2, V8 probes:**
  - `<sp>/trig/radial-center-synthesis/pins_probe.mjs`, output `pins_probe.out`: the values of
    pins 1 and 3 (case A at 1, 500, 999 and 1100 ms; case C).
  - `<sp>/trig/radial-center-synthesis/pin_e2_probe.mjs`, output `pin_e2_probe.out`: case E2 for
    the radar (final position (389.4495078835456, 251.62998998399627), `xCenter` 376) and the
    polar area (query (411.91189405530497, 267.668481707598), final `x` 376).
  - `<sp>/trig/radial-center-simplicity/upstream_probe.mjs`, output `upstream_probe.out`: cases
    A-E. `<sp>/trig/radial-center-performance/probe_options.mjs`, output `probe_options.out`: the
    emulation of N and NA. `<sp>/trig/radial-center-fidelity/probe_options.mjs`, output
    `probe_options.out`: the emulation of N, C1 (= NA) and C2 (= V2). The judge re-ran the first
    two with identical output (`<sp>/trig/radial-center-judge/upstream_simprobe.out`,
    `upstream_perfprobe.out`).
  - The X-fix probes `<sp>/wave3/X-fix/probe.mjs` and `<sp>/wave3/X-fix-fix/probe_f1c.mjs`
    (case B).
- **E3, the port (option A):** `<sp>/trig/radial-center-synthesis/port_pins_test.dart`, output
  `port_pins.out` (`+4: All tests passed!`): pin 1 (polar area at 500 ms: `startAngle`
  2.84706834231575, `endAngle` 4.319689898685965, `outerRadius` 232.5, the four hits `[[0, 3]]`),
  E2 (radar and polar area) and pin 3 give the E2 values to the last digit.
  `<sp>/trig/radial-center-performance/port_probe.out` and
  `<sp>/trig/radial-center-fidelity/port_hits.out` give cases A, B and C.
- **E4, the options as `lib/` diffs:** the scratch copy `<sp>/trig/radial-center-simplicity/repo`,
  `variant.sh <V>` and `variant_<V>.diff`. `port_variants.out` (cases A-E and the pin groups),
  `V3_suites.out` (the 6 animation tests that NA breaks) and
  `<sp>/trig/radial-center-synthesis/port_pins_variants.out` (pins 1-3 under N (`V1`), V2, V2r,
  NA (`V3`) and F (`V5`)): N fails pin 1; V2 fails E2 and pin 3; V2r fails E2; NA fails E2 and
  pin 3; F passes all three.
- **E5, benchmarks:** `<sp>/trig/radial-center-performance/bench/bench.dart` with `aot.out` and
  `wasm.out`; `update_cost_test.dart` with `update_cost.out`;
  `<sp>/trig/radial-center-simplicity/bench/bin/bench_replica.dart` and `bench_pos.dart` with
  `aot_replica.out`, `wasm_replica.out` and `aot_pos.out`; `jit_bench.out`; the judge re-runs
  `<sp>/trig/radial-center-judge/aot_perf.out`, `wasm_perf.out`, `aot_replica*.out`,
  `wasm_replica.out` and `aot_pos.out`.
- **E6, the panel:** `.handover/phase7/design/radial-center/draft-fidelity.md`,
  `draft-performance.md`, `draft-simplicity.md` and `judge.md`;
  `.handover/phase7/review/wave3/X-fix-report.md` and `X-fix-review.md` (finding F1);
  `.handover/phase7/review/wave3/W3-int-report.md` (open item 1).
