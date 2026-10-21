# Wave 1, unit U-bar-tests (the test part of U-bar): report

## Status

Done. The tests of the U-bar row are in place: the reference generator and its data, the
reference test file and the spec port. All targeted checks pass:

- `test/port/controllers/controller.bar_test.dart`: 84 tests pass.
- `test/specs/controller.bar_test.dart`: 51 pass, 4 skip.
- `test:cases` for `controller.bar.tests.js`: 55 cases, 51 passed, 0 failed, 4 skipped,
  0 missing.
- Two runs of the generator give the same SHA-256.

The unit runs in parallel with other units. Thus the full gate did not run. W1-int runs it.

## Files that changed

The paths are relative to `packages/flutter_chartjs/`.

| File | Change |
|---|---|
| `tool/reference/controller_bar_reference.mjs` (new) | The bar generator. It writes the 23 cases of Chart.js ADR 0030 §7, then 25 `parsed:` cases (PD §7.3, bar rows) and 2 `interfaces:` cases (IV §7.3, bar row). It loads the moment adapter (`loadMomentAdapter`) for the timeseries case and calls `appendAdapterInfo`. It has two probes of the key `extra`: `barEdges` and `stackKeys`. |
| `test/port/controllers/controller_bar_reference.dart` (new, generated) | 50 cases, 80 widths, 1,786,242 bytes. One file is sufficient, because the limit is 2.5 MB. SHA-256 `5ac89ab80dda534c45c6cfaa331cdc3c5d6ac809bcb240c111cdab2dec450c51`. |
| `test/port/controllers/controller.bar_test.dart` (new) | The reference tests (TS §2): the origin tests, the 50 cases, the themed run of the 23 cases, a stale-key test, the group `parsed data` (5 relation tests) and the group `interfaces` (1 test). `main()` starts with `Chart.register([BarController.jsClass])`. |
| `test/specs/controller.bar_test.dart` (new) | The spec port (TS §5, ADR 0030 §13). It has the exact `describe` and `it` names, 51 cases with bodies, 3 placeholders with the skip reason `'blocked: controller.line'` (`:70`, `:310`, `:671`) and 1 placeholder with the skip reason `'blocked: plugin.tooltip'` (`:1808`). The D1 cases `:1426`, `:1442` and `:1538` have bodies. `main()` starts with `Chart.register([BarController.jsClass])`. |
| `lib/src/controllers/controller.bar.dart` | Fix L1 (see below): `_getStackCount` became `getStackCount`, and `_getStackIndex` became `getStackIndex`, both `@internal`. The file imports `package:meta/meta.dart`. |
| `doc/phase7/review/wave1/U-bar-tests-report.md` (new) | This report. |

## Fixes in `controller.bar.dart`

### L1: the spec reads two private members

The spec calls `meta.controller._getStackCount()` (`:85` to `:307`, `:1803`) and
`meta.controller._getStackIndex(i)` (`:325` to `:575`). The U-bar-lib port kept both members
private to the library. Thus the spec file cannot call them. Chart.js ADR 0012 (underscore
members) says that a `_` member that another module reads drops the underscore and carries
`@internal`. The scales of phase 6 did the same for the members that a spec reads.

The change:

- `double getStackCount([double? index])`, `@internal`.
- `double getStackIndex(double datasetIndex, [Object? name = undefined, double? dataIndex])`,
  `@internal`. The spec calls it with one argument. Upstream then gets `undefined` for `name`
  and `dataIndex`. The `undefined` sentinel is the default of `name`, and Dart `null` stands for
  the `undefined` of `dataIndex`, as before.
- The `///` citations keep the upstream names. The behavior does not change. Most configs of the
  U-bar-lib smoke test are now reference cases, and they pass.

No test found a defect of the computed values.

## The cases of the generator

The 23 cases of ADR 0030 §7, in this order:

1. `default` (with the scale options; steps `update`, `setActive`, `update none`, `push`,
   `splice`, `reset`, `update`)
2. `indexAxis y`
3. `stacked true with borderSkipped middle`
4. `stacked single`
5. `stack groups with negative values`
6. `floating bars`
7. `floating bars, stacked`
8. `a hidden dataset and setDatasetVisibility` (two steps)
9. `barThickness a number and flex, maxBarThickness`
10. `grouped false`
11. `skipNull with null items`
12. `minBarLength with 0 and negative values`
13. `base`
14. `borderSkipped start, end, an edge, true and false` (probe `barEdges`)
15. `inflateAmount auto and a number, borderRadius` (probe `barEdges`)
16. `a linear index axis`
17. `a timeseries index axis` (the `_cache.$bar` path)
18. `a logarithmic value axis`
19. `reversed scales`
20. `clip false` (also `clip: 10` on a second dataset)
21. `object data with parsing keys` (also a nested key `nested.v`)
22. `parsing false` (also a `_custom` object)
23. `string values, null and NaN`

The 25 `parsed:` cases: an absent value key and a `null` value with `parsing: false`;
`inflateAmount` `'2'`, `null`, `true`, `'abc'`; `base` `5`, `'5'`, both with `minBarLength: 20`;
`base` `'0'` and `0` with `minBarLength: 10`; `base` `''`, `'abc'`, `true`; `minBarLength: '20'`;
`barThickness: '20'`; `barThickness: 'flex'` with `grouped: false` (width NaN);
`maxBarThickness` `null` (width 0) and `'30'` (width 30); `base: 'b'` on a category value axis;
`xAxisKey` `null` and `5` (`TypeError` at `initial`); a bad `yAxisKey` on a category index axis
(`TypeError`); stacked List items with `parsing: false` (probes `barEdges` and `stackKeys`);
stacked numbers with `parsing: false` (`TypeError`).

The 2 `interfaces:` cases: the two label sets of IV §7.3 with 6 data items. The observation
`labelAndValue` compares each label, also the label past the end.

The probe `barEdges` gives `[enableBorderRadius, borderSkipped, Number(inflateAmount)]` of each
bar. It compares `Number(inflateAmount)`, because the port converts a raw `inflateAmount` at the
write (ADR 0027 §6) and its only reader applies `ToNumber`.

## Tests that were added

`test/port/controllers/controller.bar_test.dart` (84 tests):

- `the reference comes from Node.js v24.12.0 on x64 and a build of the pinned Chart.js`, the
  adapter origin test, 1 width test (`testReferenceWidths`).
- `the reference has the 23 cases of Chart.js ADR 0030 first`.
- The 50 reference cases (`testControllerChartCases`, `now: controllerBarReferenceNow`).
- Group `theming.md §8 test 3: the light preset`: the 23 cases with the light preset, and `the
  light preset leaves no stale scale key` (`expectNoStaleScaleKeys` on `default`).
- Group `parsed data`: `inflateAmount '2', null, true and 'abc' give the rect and clip calls of
  2, 0, 1 and NaN`; `base true gives the bars of base 1`; `minBarLength '20' gives the bars of
  20`; `barThickness '20' gives the bars of 20`; `a bad yAxisKey on a category index axis throws
  after the first label parse` (the labels hold `'q'`); `stacked List items with parsing false
  take a stack object with the key of the value axis` (`stacksOf` keys `['y']`,
  `enableBorderRadius` false, `borderSkipped` `{bottom: true}`, `x` NaN).
- Group `interfaces`: `getLabelAndValue gives a String label`.

`test/specs/controller.bar_test.dart`: 55 tests (51 bodies, 4 placeholders). The `auto` fixture
group is a comment at its upstream position, as in the other spec files. F-int adds the call of
Chart.js ADR 0029.

Spec forms (also in the comment block of the file): `Chart.controllers.bar` is
`Chart.registry.controllers.items['bar']` (index.umd.ts:35); `removeHoverStyle(bar)` passes NaN
for the two absent numbers (the same results as `undefined`: `getStyle` reads `index || 0`);
`ctx.resetTransform = function() {}` is a subclass of `MockContext`; the afterEach of `Bar width`
and `Bar height (horizontal type)` is a local `afterEach()` that each test calls last; the
beforeEach of the `barThickness` loop is a local `beforeEach()` that each test calls first;
`getMinMax()` without an argument is `getMinMax(false)`.

Evidence that the compare is effective: a scratch test
(`<scratch>/wave1/U-bar-tests/mutation_test.dart`) ran the case `default` with 6 changed expected
values (a bar `x`, a `rect` argument, a hit item, an option, a label, a stacks key). All 6 failed.

## Checks

| Command | Result |
|---|---|
| `TZ=UTC /usr/bin/arch -x86_64 <scratch>/env/node-v24.12.0-darwin-x64/bin/node tool/reference/controller_bar_reference.mjs <scratch>/env/chartjs-build/dist/chart.js <scratch>/env/moment/node_modules`, two runs | rc 0; the same SHA-256 `5ac89ab8...0c51` for both runs |
| `flutter test test/port/controllers/` | +106, all passed (84 in `controller.bar_test.dart`, 22 in the harness self-test) |
| `flutter test test/specs/controller.bar_test.dart` | +51 ~4, all passed |
| `dart run packages/flutter_chartjs/tool/spec_cases.dart` (`test:cases`) | passed, 38 files; `controller.bar.tests.js` 55 cases, 51 passed, 0 failed, 4 skipped, 0 missing; total 1036 cases, 434 passed, 0 failed, 415 skipped, 187 missing |
| `dart analyze --fatal-infos` of `lib/src/controllers`, `test/port/controllers`, `test/specs/controller.bar_test.dart`, `apps/chartjs_gallery` | No issues |
| `dart format --output=none --set-exit-if-changed` of the 4 changed Dart files | 0 changed |
| `check:headers` | passed, 338 files |
| `check:lib-imports` | passed, 301 files |
| `check:js-semantics` | passed, 117 files |
| `parity:check` | failed as expected: 3 errors and 9 warnings for `doc/status.yaml` and `doc/parity.md` (the rows of `controller.bar.js` and `controller.bar.tests.js`, and the port-only rows). W1-int changes `status.yaml` and runs `parity` (rule 2 of the work plan). |

No `flutter_tester` process of this unit is left. The process 67820 belongs to another session
(`ec6419b7-...`). This unit did not touch it.

## Doc notes for W1-int

`AGENTS.md`:

- Layout, `lib/src/controllers/`: add "`BarController.getStackCount` and `getStackIndex` are the
  `_getStackCount` and `_getStackIndex` of upstream: the spec reads them, thus they drop the
  underscore (Chart.js ADR 0012)."
- Layout, `test/port/controllers/`: "`controller.bar_test.dart` compares the bar charts of
  `tool/reference/controller_bar_reference.mjs` (data `controller_bar_reference.dart`)."
- Tests, the generator list: "`tool/reference/controller_bar_reference.mjs` writes
  `test/port/controllers/controller_bar_reference.dart`. It also needs the moment packages
  (`MOMENT_NODE_MODULES` or the second argument) and `TZ=UTC`, for the timeseries case. The test
  file runs each case at the fixed `Date.now()` of the generator."
- Tests: remove the temporary `Chart.register([BarController.jsClass])` lines of
  `test/port/controllers/controller.bar_test.dart` and `test/specs/controller.bar_test.dart`
  when `flutter_test_config.dart` registers the wave (Chart.js ADR 0030 §3 item 4).

`doc/porting-flow.md`: no change from this unit (the text of TS §6 covers it).

`doc/performance.md`: no figures from this unit.

`doc/differences.md`: no row and no marker.

`doc/status.yaml`:

- `src/controllers/controller.bar.js`: the Dart target `lib/src/controllers/controller.bar.dart`;
  status text: "`test/port/controllers/controller.bar_test.dart` compares 23 charts with
  upstream, and 23 more with the light preset; 27 pin cases (25 `parsed:` of Chart.js ADR 0027, 2
  `interfaces:` of Chart.js ADR 0028) and 6 relation tests."
- `test/specs/controller.bar.tests.js`: the Dart target `test/specs/controller.bar_test.dart`;
  status text: "51/55 cases pass on the VM; 4 cases skipped: 3 `blocked: controller.line` (wave
  2) and 1 `blocked: plugin.tooltip`. The fixture group `auto` waits for the fixture runner
  (Chart.js ADR 0029)." Use the `{{passed}}` and `{{skipped:...}}` placeholders where the other
  rows use them.
- Port-only rows: `test/port/controllers/controller.bar_test.dart`,
  `test/port/controllers/controller_bar_reference.dart` (and the generator if the table lists
  generators).
- Then run `dart run melos run parity`.

## Open items

1. W1-int: remove the two `Chart.register` lines (see above) and run the full gate.
2. L2 lifts the 3 `'blocked: controller.line'` placeholders of the spec file (TS §4.2).
3. The fidelity reviewer can check the rename L1 against Chart.js ADR 0012 and IV §4.8.
4. The probe `barEdges` compares `Number(inflateAmount)`. A read by name of `bar.inflateAmount`
   gives the number in the port and the raw value upstream (ADR 0027 §6, no `DIVERGES` row). The
   probe reads the value that the draw uses.

## Fixes

The fixes of the review findings in `U-bar-tests-review.md`.

### F1 (confirmed): the test of the case order did not check the order

The test "the reference has the 23 cases of Chart.js ADR 0030 first" in
`test/port/controllers/controller.bar_test.dart` checked only the first name and the count of the
names without a prefix. A list with a plain case after a `parsed:` case also passed.

Fix: the test keeps its name and now checks the order. It expects that:

- the first name is `default`;
- the list has 23 names or more;
- `names.take(23)` has no name with the prefix `parsed:` or `interfaces:`;
- each name of `names.skip(23)` has one of the two prefixes.

Probe:
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/U-bar-tests-fix/order_probe_test.dart`
(run with `flutter test` from `packages/flutter_chartjs`). The new check passes on the reference
and fails on the reordered list of review probe P2 (case 23 moved to position 31). Result: 2/2
probe tests pass.

### Checks after the fixes

- `dart format --set-exit-if-changed test/port/controllers/controller.bar_test.dart`: 0 changed.
- `dart analyze --fatal-infos test/port/controllers/controller.bar_test.dart`: no issues.
- `flutter test test/port/controllers/controller.bar_test.dart`: 85/85 pass.
- No flutter_tester process of this unit is left.
