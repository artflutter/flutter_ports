# A1 review: the animator members (wave 2)

Adversarial fidelity review of unit A1 (work plan §2, FR §3, Chart.js ADR 0029 §6).

## Scope

- `packages/flutter_chartjs/lib/src/core/core.animator.dart` (git diff against 436663f).
- `packages/flutter_chartjs/test/port/core/core.animator_test.dart` (git diff against 436663f).
- `A1-report.md`, with its doc notes for W2-int.
- Upstream at the pin 7169e651: `src/core/core.animator.js` and the six fixtures that use the
  animator: `controller.bar/bar-animation-hide-show.js`,
  `controller.doughnut/doughnut-animation.js`, `controller.doughnut/doughnut-animation-hide-last.js`,
  `controller.polarArea/polar-area-animation-rotate.js`,
  `controller.polarArea/polar-area-animation-scale.js` and `controller.polarArea/last-slice-animate.js`.

## Result

The code agrees with Chart.js ADR 0029 §6 items 1-3 and with FR §3. No behavior difference was
found. Two findings are about text: one wrong citation in a test comment and one wrong member name
in a doc note of the report. Neither changes behavior.

## Checks with no defect

1. Line-by-line comparison with `core.animator.js`:
   - `_refreshMethod` is `:38-52`. The frame callback calls `update()`, sets `_request` to null,
     and calls the field `refresh()` when `_running` is true (`:45-49`).
   - `start` calls the field (`:171`). `unmute` calls the field (ADR 0029 §6 item 3).
   - `update([double? date])` is `:57-107` with no change to the body. `getAnims` is `:112-128`.
     `listen`, `add` and `has` call `getAnims` (`:136`, `:148`, `:156`).
   - No call of the old method stays: each call reads the field. A capture of the field at the
     entry of `_refreshMethod` does not occur.
2. The `///` citations of the changed lines are correct: `:38`, `:38-52`, `:49`, `:57`, `:112`,
   `:171`, and `doughnut-animation.js:59-60` (the backup and the replacement of `_refresh`).
3. The marker `// DIVERGES(chartjs): harness-method-fields, a fixture replaces it.` has the
   correct form. The row `harness-method-fields` exists in `doc/differences.md`. The marker
   `platform-animation-promise-checkpoint` stays in the body of the frame callback.
4. ADR 0012 and ADR 0023: `Animator` has no other member with the names `update`, `refresh` or
   `getAnims`. The `@internal` members are not exported: `lib/src/core/index.dart` exports
   `animator` only.
5. JS semantics (ADR 0010): the change adds no new form. Dart `null` for `date` stands for the
   omitted argument, as before. The fixtures pass a number (`start + i * 500`, `start + i * 2000`,
   `Date.now() * 2`), never `undefined` or `null`.
6. The tests pin what they claim. The mutations of the report (the frame callback, `start` or
   `unmute` calls `_refreshMethod()`) each make the group fail. Test 3 fails when `update` ignores
   `date`, because the clock does not move. The clamp of `:31` is pinned by `update(start + 1500)`.
7. No skip was added. Thus no case with the verdict `phase7` in `all.json` is skipped by this
   unit.
8. `flutter test --no-pub test/port/core/core.animator_test.dart`: 19 passed. `dart analyze
   --fatal-infos` on the two files: no issues.

### Probe P1: the fixture control flow, Dart against the pinned build

The probe runs the control flow of `doughnut-animation.js:55-78` (6 steps in place of 16) on one
animation of 1000 ms, with the animator frame callback already pending, as after the chart
constructor.

- JS: `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/A1-review/fixture_flow.mjs`,
  on `dist/chart.js` at 7169e651, x64 Node.js v24.12.0, with a fake `requestAnimationFrame` and a
  fake `Date.now`.
- Dart: `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/A1-review/fixture_flow_test.dart`,
  run with `flutter test` from `packages/flutter_chartjs`.

Both give the same log, byte for byte:

```
[["before",0,0,2],["progress",16,1000,true],["progress",0,1000,true],["step",0,0,2,1,true],
["progress",500,1000,true],["step",1,5,3,1,true],["progress",1000,1000,true],["step",2,10,4,1,true],
["complete",1000,1000,true],["step",3,10,4,0,false],["step",4,10,4,0,false],["step",5,10,4,0,false],
["after1",10,4,0,false],["after3",10,4,0,false,false]]
```

The animator frame callback runs first and calls the replaced field. Thus the loop ends, and no
frame callback stays after the restore, as upstream.

## Findings

### F1 (confirmed, low): the test comment names fixtures that do not exist

`test/port/core/core.animator_test.dart:449-452`, the comment of the group
`harness-method-fields`:

> The fixtures doughnut-animation.js, polarArea-animation.js and bar/animation (Chart.js ADR 0029,
> section 6) replace `Chart.animator._refresh`, call `_update(start + i * 500)` and read
> `_getAnims(chart).items[0]._start`.

- `polarArea-animation.js` and `bar/animation` are not files at the pin. The polarArea fixtures
  are `polar-area-animation-rotate.js`, `polar-area-animation-scale.js` and
  `last-slice-animate.js`. The bar fixture is `controller.bar/bar-animation-hide-show.js`.
  `doughnut-animation-hide-last.js` is not named.
- `bar-animation-hide-show.js` calls `_update(start + i * 2000)` and `_update(Date.now() * 2)`
  (`:53`, `:58`, `:65`, `:70`), not `_update(start + i * 500)`.

Probe: `ls third_party/Chart.js/test/fixtures/controller.polarArea/polarArea-animation.js` and
`ls third_party/Chart.js/test/fixtures/bar/animation*` find no file.
`grep -rn "animator\." third_party/Chart.js/test/fixtures` gives the six files above.

Fix: name the six fixtures with their folders, for example "the six fixtures of
`controller.bar`, `controller.doughnut` and `controller.polarArea` that FR Appendix B gives to H1
and H3", and write "`_update(start + i * <step>)`".

### F2 (confirmed, low): a doc note names the wrong Dart member for the checkpoint row

`A1-report.md`, "Doc notes for W2-int", `doc/differences.md`, row
`platform-animation-promise-checkpoint`: "Dart column `Animator._refresh` becomes
`Animator.refresh`."

The marker `platform-animation-promise-checkpoint` is at `core.animator.dart:189`, in the body of
`_refreshMethod` (lines 182-199). The field `refresh` (line 174) holds only the tear-off, and a
fixture replaces it. Thus the Dart column must name `Animator._refreshMethod`. With the note as
written, the row points to the replaceable field and not to the code of the checkpoint.

Probe: `grep -n "DIVERGES" packages/flutter_chartjs/lib/src/core/core.animator.dart` gives line
189 for `platform-animation-promise-checkpoint`. Lines 182-199 are `void _refreshMethod() {…}`.

Fix: W2-int writes `Animator._refreshMethod` in the Dart column of
`platform-animation-promise-checkpoint`. For `harness-method-fields`, `Animator.refresh` is
correct.

## Processes

The probe started one `flutter_tester` process. It ended with the test run. The `flutter_tester`
process 67820 of another session (scratchpad `ec6419b7-…`) runs. This review did not stop it.
