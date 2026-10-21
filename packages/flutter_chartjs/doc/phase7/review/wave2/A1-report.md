# A1 report: the animator members (wave 2)

## Status

Done. The unit implements FR §3 and Chart.js ADR 0029 §6 items 1-3. The targeted checks pass.
The full gate is for W2-int (task rule: run only the targeted tests).

## Changed files

1. `packages/flutter_chartjs/lib/src/core/core.animator.dart`
   - Import `package:meta/meta.dart`.
   - `final class _Anims` is now `@internal final class Anims`. The field docs did not change.
   - `_getAnims` is now `@internal Anims getAnims(types.Chart chart)`. The doc keeps
     `core.animator.js:112 \`_getAnims(chart)\``. `listen`, `add` and `has` call it.
   - `_update` is now `@internal void update([double? date])`. The doc keeps
     `core.animator.js:57`.
   - `_refresh` is now the field `@internal late void Function() refresh = _refreshMethod;` with
     the marker `// DIVERGES(chartjs): harness-method-fields, a fixture replaces it.`. The private
     method `_refreshMethod` has the upstream body (`:38-52`). The frame callback calls `update()`
     and then the field `refresh()` (`:45`, `:49`). `start` (`:171`) and `unmute` call the field.
     The marker `platform-animation-promise-checkpoint` stays in the body.
   - The library doc has a new bullet for the three members. The comments that named `_update`
     and `_getAnims` as Dart members now name `update` and `getAnims`.
   - No other file in `lib/` changed. `lib/src/core/index.dart` exports `animator` only. Thus
     `Anims` is not part of the public API.
2. `packages/flutter_chartjs/test/port/core/core.animator_test.dart`
   - The file comment names the new members.
   - New group `harness-method-fields` (4 cases).
   - The names of the existing groups and cases did not change. Chart.js ADR 0019 (line 818)
     names the group `jsMapForEach in _update`. Thus that name stays.

## Added tests (group `harness-method-fields`)

1. `a replaced refresh ends the loop, and the restore resumes`: a running animation of 1000 ms.
   After `start`, `animator.refresh = () => calls++`. The next frame runs `update` (1 draw) and
   then the replaced field (`calls == 1`). No frame callback is left. 3 more frames: the draws
   stay 1. The restore and `start` register one frame callback. 2 frames give 2 more draws at
   the value of 96 ms. The field is restored in `addTearDown` too.
2. `start and unmute call the field`: with a replaced field, `start` and `unmute` each call the
   field one time and register no frame callback.
3. `update(date) ticks the items of getAnims at the date`: the field is replaced before `start`
   (the control flow of `doughnut-animation.js:56-75`). `getAnims(chart).items` holds the
   animation, and `items[0].start` equals `anims.start`. `update(start + 250)` sets the value to
   2.5 and gives the progress event `(currentStep 250, numSteps 1000)`. `update(start + 1500)`
   gives `currentStep` 1000, clamped as `Math.min` (`:31`). `update(start + 2000)` removes the
   ended item and gives one complete event with `currentStep` 1000. Then `running` is false and
   `initial` is false.
4. `getAnims of a new chart gives a new record`: `running == false`, `initial == true`, empty
   `items`, listener keys `complete` and `progress`, `start` and `duration` null. A second call
   gives the same record. After `remove`, a new record.

Mutation probe (in the scratch folder, the file was restored and compared with `diff`): each of
these three changes makes the group fail: the frame callback calls `_refreshMethod()`, `unmute`
calls `_refreshMethod()`, `start` calls `_refreshMethod()`.

## Checks

| Command | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed` on the 2 files | 0 changed |
| `dart analyze --fatal-infos packages/flutter_chartjs packages/chartjs_test_utils apps/chartjs_gallery` | No issues found |
| `flutter test test/port/core/core.animator_test.dart` | 19 passed |
| `flutter test` on `test/port/core/core.{animations,animator,controller,datasetController,animation}_test.dart`, `test/port/flutter_test_config_test.dart`, `test/port/index_test.dart`, `test/specs/core.{animations,animator,controller,animation}_test.dart` | 234 passed, 43 skipped, 0 failed |
| `dart run melos run check:lib-imports` | passed, 302 files |
| `dart run melos run check:js-semantics` | passed, 118 files |
| `dart run melos run check:headers` | passed, 339 files |

Not run (W2-int runs the full gate): `test --no-select`, `test:web`, `test:cases`, `check:port`
as a whole. `test:web` does not compile the changed files: `core.animator.dart` is not a pure
layer, and the test file has `@TestOn('vm')`.

No `flutter_tester` process of this unit is left. One `flutter_tester` process of another
session (scratchpad `ec6419b7-…`) runs. This unit did not stop it.

## Doc notes for W2-int

### `AGENTS.md`

In Layout, `lib/src/core/`, the bullet of `core.animation.dart`: add this sentence:
"`core.animator.dart` has `getAnims`, `update`, the `@internal` class `Anims` and the field
`refresh` (Chart.js ADR 0029 §6). A fixture replaces `refresh` on the singleton
(`harness-method-fields`)."

### `doc/differences.md`

- Row `harness-method-fields`:
  - Dart column: add `` `lib/src/core/core.animator.dart` `Animator.refresh` ``.
  - Upstream column: add `src/core/core.animator.js`@v4.5.1+7169e651:38-52, 171.
  - Reason: add "The fixtures of `controller.bar`, `controller.doughnut` and
    `controller.polarArea` replace `Chart.animator._refresh` (Chart.js ADR 0029 §6). Thus
    `refresh` is a field too, and `start`, the frame callback and `unmute` call the field."
  - Pinning test column: add `test/port/core/core.animator_test.dart`, group
    `harness-method-fields`.
  - Re-check column: add "and the calls of `_refresh` in `core.animator.js`".
- Row `platform-animation-promise-checkpoint`: Dart column `Animator._refresh` becomes
  `Animator._refreshMethod`. The marker is in the body of `_refreshMethod`
  (`core.animator.dart:189`). The field `refresh` holds only the tear-off that a fixture can
  replace. The re-check text "`_refresh`" names the upstream member. It can stay.
- Row `platform-animator-skip-muted`: Dart column `Animator._update` becomes `Animator.update`.
  The reason starts with "`_update` skips a muted chart": the upstream name, it can stay.

### `doc/status.yaml`

`src/core/core.animator.js`: replace "`_update` walks the charts with `jsMapForEach`" with
"`update` walks the charts with `jsMapForEach`", and add "`getAnims`, `update` and the field
`refresh` drop the underscore for the fixtures ([Chart.js ADR 0029](adr/0029-fixture-smoke-runner.md)
§6)". Then run `dart run melos run parity`.

### `doc/performance.md`

Phase 7 section, "13.3 The fixture runner (Chart.js ADR 0029)", first bullet: the `refresh`
field of the animator is one field call for each frame. AOT 0.82-0.89 ns for the field call
against 0.82-0.85 ns for the method call, dart2wasm 0.337 against 0.336 ns (ADR 0029 Evidence
E6). No frame effect. This unit took no new measurement.

### `doc/porting-flow.md`, `doc/upstream-ledger.md`

No note from A1.

## Open items

1. The hand ports of H1 and H3 (FR §4) import `package:flutter_chartjs/src/core/core.animator.dart`
   for `animator.getAnims`, `animator.refresh` and `animator.update`. `@internal` permits this
   in the tests of the same package. `anims.items[0]._start` is `anims.items[0].start`.
2. Chart.js ADR 0019 (proposed) line 818 names the test group `jsMapForEach in _update`. The
   group keeps that name. The phase lead can decide if a later ADR renames it.

## Fixes

Findings of `A1-review.md`. Both have the verdict "confirmed".

1. F1 (`test/port/core/core.animator_test.dart`, comment of the group `harness-method-fields`):
   fixed. The comment named fixtures that do not exist at the pin (`polarArea-animation.js`,
   `bar/animation`). The probe `grep -rln 'animator\.' third_party/Chart.js/test/fixtures` gives
   six files. The comment now names the six fixtures:
   `controller.doughnut/doughnut-animation.js`, `doughnut-animation-hide-last.js`,
   `controller.polarArea/polar-area-animation-rotate.js`, `polar-area-animation-scale.js`,
   `last-slice-animate.js` and `controller.bar/bar-animation-hide-show.js`. All six replace
   `_refresh` and read `_getAnims(chart).items[0]._start`. The doughnut and polar area fixtures
   call `_update(start + i * 500)`. `bar-animation-hide-show.js` calls `_update(Date.now() * 2)`
   and `_update(start + i * 2000)` (`:53-70`). The comment now says this. No code changed.
2. F2 (this report, doc note for the row `platform-animation-promise-checkpoint` of
   `doc/differences.md`): fixed. The note now says that the Dart column becomes
   `Animator._refreshMethod`, because the marker is in the body of `_refreshMethod`
   (`core.animator.dart:189`). The field `refresh` holds only the tear-off.

### Checks after the fixes

| Command | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed test/port/core/core.animator_test.dart` | 0 changed |
| `dart analyze --fatal-infos` on `core.animator_test.dart` and `core.animator.dart` | No issues found |
| `flutter test test/port/core/core.animator_test.dart` | 19 passed |
| `dart run melos run check:headers` | passed, 348 files |

No `flutter_tester` process of this unit is left. One `flutter_tester` process of another
session (scratchpad `ec6419b7-…`) runs. This unit did not stop it.
