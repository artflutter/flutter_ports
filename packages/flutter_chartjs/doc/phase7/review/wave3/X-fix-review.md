# Wave 3, unit X-fix: adversarial fidelity review

## Scope

The reviewer read `X-fix-report.md`, the `git diff` of the 17 files of the unit (9 `lib/` and
gallery files, 8 test files) and the pinned upstream lines that each `///` line cites
(`third_party/Chart.js` at `7169e651`). The reviewer compared each decision with Chart.js ADRs
0025, 0027 and 0028, the decisions D10-D12 and the W2-int open items 2, 3 and 4.

`<scratch>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad`.
The probes are in `<scratch>/wave3/X-fix-review/`:

- `probe.mjs`, output `probe.out`: x64 Node.js v24.12.0 on the build at the pin (`loadChartJs`
  stops on another arch or commit). The output starts with `arch x64 version 4.5.1`.
- `review_probe_test.dart`, output `review_probe_dart.out`: the same cases on the port.
- `pin_probe_test.dart`, output `pin_probe_dart.out`: the strength of two pin tests.
- `flutter_test_config.dart`: a copy of the package file, so that the probes run in the harness.

The reviewer started no `flutter_tester` process that stays. Process 67820 ran before the probes
(`pids_before.txt`). The reviewer did not stop it.

## Result

The three items of D11 agree with upstream on each probe case. The reviewer found no difference
in a protected behavior (Chart.js ADR 0009), no wrong JS form (Chart.js ADR 0010), no value that
a loop carries across passes (D10), no missing upstream statement and no wrong citation. The
review has 3 findings: one on an accepted ADR, two on the strength of tests. None of them
changes a result of the port.

## Checks with no defect

| Check | Upstream (`probe.out`) | Port (`review_probe_dart.out`) |
|---|---|---|
| R1: `'123'` gives the same elements as `[1, 2, 3]` for radar (`x`, `y`, `skip`), polar area (`x`, `y`, `outerRadius`, `startAngle`, `endAngle`), bubble and bar (`x`, `y`, `base`, `width`, `height`) | `equal: true` for all 4, values for example radar `356.025934, 321.75` | `equal: true` for all 4, the same values |
| R2: `toggleDataVisibility('01')` 2 times, then `toggleDataVisibility(1)`, then `unshift(9)`. `Object.keys` gives `'1'` before `'01'`, so the last write to the key `'2'` is `false` | `{"2":false}`, visibility `11111` | `11111` (`jsObjectKeys` in `_moveNumericKeys`) |
| R3: stacked line, `parsing: false`, `'12'` | `TypeError` (`Cannot create property '_stacks' on string '1'`) | `TypeError` |
| R4: doughnut `'123'` with `parsing: false`, then `parsing: true`, 1 update | no throw, `_parsed` `'123'` | no throw, `meta.parsed` the `JsStringList` of `'123'` |
| R4b: the same with 2 updates | `TypeError` (`Cannot assign to read only property '0'`) | `TypeError` (the write into `JsStringList`) |
| R5: `getContext(2)` of a line with `'12'` | 2 elements, `raw` `undefined` (dataset context) | 2 elements, `raw` absent (Dart `null`: the Map rule of Chart.js ADR 0006, not a change of this unit) |

Other checks by reading:

- Item (a). Each read of `xCenter` and `yCenter` in `lib/` uses `?? double.nan` in arithmetic and
  canvas calls, or `?? undefined` in an element property (`grep -rn xCenter lib/`). No by-name
  read `'xCenter'` exists. `setCenterPoint` keeps `undefined + n = NaN`. `drawingArea` stays NaN:
  `getDistanceFromCenterForValue` gives NaN for both, and no reader writes `drawingArea` into an
  element. The radar `skip` is `isNaN(x) || isNaN(y)` with `isNaN(undefined)` true. The citations
  `scale.radialLinear.js:416-418`, `core.animation.js:32` and `controller.radar.js:90-91` are
  correct.
- Item (b). `_dataCheck` follows `core.datasetController.js:365-392`: `''` is falsy and gives
  `[]`; `isObject` comes first; `_data !== data` compares strings by value; a string gets no
  listener. `unlistenArrayEvents` on a `JsStringList` finds no stub and returns. Each write into
  a `JsStringList` throws a `TypeError`, as a write into a string in strict mode code. The
  limits (`isArray`, `typeof`, the identity of `meta.parsed` with `parsing: false`) are not
  protected behaviors, and no ported reader sees them (open item 1 of the report).
- Item (c). `toggleDataVisibility` writes `jsToString(index)`: `'undefined'` for `undefined`,
  `'null'`, `'true'`, `'2'` for `[2]` and `jsNumberToString` for a number. The legend `onClick`
  passes `jsGet(legendItem, 'index')`, as `controller.doughnut.js:126` and
  `controller.polarArea.js:66`. The interface rules of Chart.js ADR 0028 §1 stay. No marker and
  no row is necessary.
- The pin tests of items (a) and (c) fail before the fix (`<scratch>/wave3/X-fix/before_fix.out`)
  and read the upstream values of the probe of the unit.
- No skip changed. No header or marker changed. The new forms (`?? double.nan`, one type test in
  `_dataCheck`) do not change the structure and need no performance row.

## Findings

### F1. The change of `types.RadialLinearScale` contradicts the accepted Chart.js ADR 0025 (confirmed)

`lib/src/types/index.dart:687` and `:692` are `double? get xCenter` and `double? get yCenter`.
Chart.js ADR 0025 has the status `accepted (2026-10-20)`. Its section 5
(`doc/adr/0025-scale-value-parameters.md:463`) fixes the forms `double get xCenter`,
`double get yCenter` of `types.RadialLinearScale`. An accepted ADR never changes (work plan §0,
AGENTS.md). A changed decision needs a new ADR that supersedes the old one.

The report does not name Chart.js ADR 0025. Its doc notes for W3-int ("Proposed ADR and spec
texts") list only the proposed ADRs 0027, 0028 and 0031 and the specs. Thus W3-int can align
ADR 0028 §1 and the IV spec with the code and leave the accepted ADR 0025 §5 in conflict. Other
texts that keep the old forms and are not in the notes: `doc/phase7/members-radial.md:305`
(`toggleDataVisibility(double)`).

Probe: `sed -n 3p doc/adr/0025-scale-value-parameters.md` gives `- Status: accepted (2026-10-20)`,
and `sed -n 463p` gives `` - `double get xCenter`, `double get yCenter` ``. The code at
`lib/src/types/index.dart:687` is `double? get xCenter;`.

Action for the phase lead: decide whether D11 item (a) needs a new proposed ADR that supersedes
Chart.js ADR 0025 (the complete decision of §5 with the `double?` forms), or another record. Add
Chart.js ADR 0025 and `members-radial.md` to the W3-int alignment list. Do not change the status
line or the text of Chart.js ADR 0025.

### F2. The guard of `test/port/types/index_test.dart:208-210` does not catch the start value now (confirmed)

The test reads `t.xCenter` after the layout and asserts `expect(t.xCenter, scale.xCenter)` and
`expect(t.xCenter, isNot(isNaN))`. Before the unit, the start value was NaN, and `isNot(isNaN)`
failed when the scale had no layout. Now the start value is `null`. Both assertions pass for
`null`: `isNaN` does not match `null`, and `null` equals `null`. `yCenter` has only the equality
assertion. Thus the test no longer shows that the interface reads the laid-out center.

Probe: `pin_probe_test.dart`, test `F2 null passes isNot(isNaN) and equals null`: passes
(`pin_probe_dart.out`).

The file is not in the row of X-fix. W3-int changes it for IV §7.1 (D12). Action for W3-int: in
the moved test, assert `isNotNull` and `isNot(isNaN)` for `xCenter` and `yCenter`, or compare
with the numbers of the polar area chart.

### F3. The test name "adds no listener" is not pinned (confirmed)

`test/port/core/core.datasetController_test.dart:1246`, test
`parses the characters, compares by value and adds no listener`. No assertion of the group
`string data` reads whether the `JsStringList` has a listener. The test runs with parsing, so
`meta.parsed` is not `_data`, and the test cannot reach the list. The assertion
`run.chart.dataChanges` `isEmpty` after `'4321'` is true with or without a listener, because no
code notifies the string list. If `_dataCheck` called `listenArrayEvents` for a string too, each
test of the unit would still pass.

Probe: `pin_probe_test.dart`, tests `F3 ...`. With `parsing: false`, `meta.parsed` is the
`JsStringList` of `_data`. The probe adds a listener to it (the mutation) and runs the
assertions of the unit test: all pass. A notification on the list then gives
`dataChanges=[[0.0, _insertElements, 1.0, 1.0]]` with the listener, and `[]` without it
(`pin_probe_dart.out`).

Action: in the test `with parsing false, the parsed items are the characters` (`:1281`), call
`notifyArrayListeners(meta.parsed, 'push', ['3'])` and expect `run.chart.dataChanges` to stay
empty. This pins `core.datasetController.js:386` for a string.

## Notes (no finding)

- The report open item 2 (a truthy `data` that is a number) is outside the upstream type
  contract. The reviewer agrees: D11 does not name it.
- The line 1 reason of `lib/src/js/js_array.dart` ("JS sort and key order as in V8") does not
  name `jsSplice`, `jsSetIndex` or `JsStringList`. `check:headers` accepts any reason. This was
  already true before the unit.
