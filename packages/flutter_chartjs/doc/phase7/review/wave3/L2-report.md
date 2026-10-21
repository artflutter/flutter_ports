# Wave 3, unit L2 (the lift of wave 2): report

## Status

Done, with 2 open records. 291 of the 293 records of the wave 2 lift list have bodies, and each
one passes. 2 records have no Dart form for their assertions. They skip with an existing
`differences.md` row (section "Open items", items 1 and 2). The phase lead decides their verdict.

- Lift check of wave 2: 508 records, 506 pass, 2 fail (the 2 open records), 0 count differences.
- Lift check of wave 1: 122 of 122 records pass, 0 count differences.
- No lifted case failed. Thus L2 found no defect in a `lib/` file that makes a case fail.
- L2 changed no `lib/` file, no harness file, no generated file and no shared doc.
- The unit runs in parallel with U-scatter, U-pie and X-fix. Thus the full gate did not run.
  W3-int runs it.

All paths are relative to `packages/flutter_chartjs/`. `<s>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave3/L2`.
The input list is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/W2-int/lift2_final2.txt`.

## Files that changed

All files are in the row of L2 (work plan section 3). The 14 files:

| File | Change |
|---|---|
| `test/specs/controller.bar_test.dart` | The 3 placeholders of `:70`, `:310` and `:671` are `testWidgets` cases with the upstream bodies. The header comment says that the lift of wave 2 gave them their bodies. |
| `test/specs/core.controller_test.dart` | 29 cases lifted. 1 case (`:1936`) skips as `diverges: js-semantics-resolver-objects` (open item 2). New helpers `_line` (`overrides.line`), `_datasets`, `_activeElements` and `_y`. New notes of the spec forms in the header comment. |
| `test/specs/core.datasetController_test.dart` | 37 cases lifted, also the case of `controller.radar` (`:978`). 1 case (`:841`) skips as `diverges: platform-array-events` (open item 1). New helpers `_element`, `_parsedOf`, `_push`, `_pop`, `_shift`, `_splice`, `_unshift` and `_isExtensible`. The group `labels array synchronization` keeps the shared `data1` and `data2` of upstream in its closure. |
| `test/specs/core.interaction_test.dart` | Moved as a whole to `@TestOn('vm')`, `flutter_test` and `package:chartjs_test_utils/flutter.dart`, without `setUpSpecs()` (TS section 4.2). 43 cases lifted. New class `_Event` (the event object of the spec) and helpers `_elements`, `_data`, `_dataset`, `_datasets` and `_labels`. The 2 scatter cases keep `blocked: controller.scatter`. |
| `test/specs/core.scale_test.dart` | 26 cases lifted. `_gridLineTests` now has the labels and the expected pixels of upstream. New helpers `_arg` and `_toBeCloseTo`. |
| `test/specs/core.ticks_test.dart` | Moved to the VM (as above). 2 cases lifted. New helper `_getLabels`. |
| `test/specs/element.line_test.dart` | Moved to the VM (as above). 1 case lifted (`waitForDone`). |
| `test/specs/platform.dom_test.dart` | 2 cases lifted (the doughnut aspect ratio case and the event case). |
| `test/specs/scale.category_test.dart` | 11 cases lifted. The case "repeated labels" keeps its body and becomes a `testWidgets` case. New helper `_getLabels`. |
| `test/specs/scale.linear_test.dart` | 11 cases lifted. |
| `test/specs/scale.logarithmic_test.dart` | 37 records lifted (36 names, 1 name two times; the second group has the ` #2` case). The second and the third `when` groups keep the `config` of upstream in their closure. The beforeEach is `_acquireWhenChart`. The constants `_pixelSetups`, `_zeroMinSetups` and `_axisIds` are replaced by `_axes`. |
| `test/specs/scale.radialLinear_test.dart` | 18 cases lifted. New helpers `_getLabels`, `_r`, `_dataset` and `_optionsR`. |
| `test/specs/scale.time_test.dart` | 14 cases lifted. New helpers `_adapter`, `_moment`, `_startOf`, `_endOf`, `_add`, `_dateValue`, `_random`, `_labels`, `_scaleOptionsX` and the matcher `_toBeCloseToTime` (`:31-48`, unit `hour` only). |
| `test/port/scales/scale.time_test.dart` | `_lineTwin` is `testWidgets(name, (tester) async => body())` with its new doc comment (Chart.js ADR 0030 section 12 item 4). The comment of the group `adapt-date-moment-format` changed. The 57 call sites did not change. |
| `doc/phase7/review/wave3/L2-report.md` (new) | This report. |

## Tests that L2 added

The 291 lifted records, each with its upstream name, character for character:

| File | Records | Result |
|---|---|---|
| `controller.bar` | 3 | pass |
| `core.controller` | 30 | 29 pass, 1 `diverges` |
| `core.datasetController` | 38 | 37 pass, 1 `diverges` |
| `core.interaction` | 43 | pass |
| `core.scale` | 26 | pass |
| `core.ticks` | 2 | pass |
| `element.line` | 1 | pass |
| `platform.dom` | 2 | pass |
| `scale.category` | 11 | pass |
| `scale.linear` | 11 | pass |
| `scale.logarithmic` | 37 | pass |
| `scale.radialLinear` | 18 | pass |
| `scale.time` | 14 | pass |
| `scale.time_test.dart` (port, `_lineTwin`) | 57 | pass |

No config, assertion, tolerance or name changed. The changes of form:

- `expect(fn).not.toThrow()` is `expect(fn, returnsNormally)`. `toBe` of an object is `same`.
  `toEqual` is `jasmineEquals`. `jasmine.objectContaining` is `objectContaining`.
  `withContext(text)` is the `reason` of `expect`.
- `data.push(...)`, `pop()`, `shift()`, `splice(...)` and `unshift(...)` on a data array are the
  change of the List and then `notifyArrayListeners` (differences.md row
  `platform-array-events`).
- `spyOn(controller, '_onData<X>')` is `spyOnArrayListener` of `test/support/jasmine.dart`.
- `chart.getActiveElements()` in `toEqual` is `_activeElements(chart)`: the object
  `{element, datasetIndex, index}` of each active element.
- The interaction event `{type: 'click', chart, native: true, x, y}` is `_Event`, a
  `types.ChartEvent`: the port tests the type where upstream tests `'native' in event`.
- `Object.freeze(array)` is `List.unmodifiable`. `Object.seal` and `Object.preventExtensions` are
  a List of fixed length. `Object.isExtensible` is `_isExtensible`.
- `moment(value)` is the parse of the default adapter. `moment()` is `jsDateNow()`. The case of
  `scale.time.tests.js:84` parses 'Jan 01 1990' with the ICU pattern 'MMM dd yyyy' and asserts
  only the unit. The case of `:548` gives timestamps to `ticks.min` and `ticks.max`, which the
  time scale of v4 does not read.
- `data.length = 42` is `addAll` of 40 `undefined` items: a hole reads as `undefined`.
- A `beforeEach` or an `afterEach` that reads a chart is a local function that each case calls
  first or last. A shared `data` object of a `describe` is a variable of the group closure.
- The 16 spanGaps cases of `core.interaction` give a copy of the const `data` to the chart.
- `chart._metasets` is `chart.metasets`. A hole is Dart null, so `[undefined x 4]` is
  `[null x 4]`.

A probe of the label alignment case of `scale.radialLinear.tests.js:551` showed 5
`setTextAlign` calls for each start angle, so the loop of the case is not empty.

## Checks

| Command (from `packages/flutter_chartjs` unless noted) | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed` on the 14 files | 0 changed |
| `dart analyze --fatal-infos` on the 14 files | No issues found |
| `flutter test` on the 14 files (last run, after the last edit) | +610 ~99, all passed |
| `flutter test --reporter json test/specs test/port > <s>/run1.json` | exit 0; 6139 passed, 0 failed, 136 skipped |
| `python3 -I doc/phase7/tools/lift_check.py doc/phase7/classification/all.json <s>/run1.json 2 --list` | exit 1. Counts `phase7` 503, legend 21, tooltip 11, filler 1. Wave 2 and earlier: 508 records, 506 pass, 2 fail, 0 count differences. Lift list (`<s>/lift2_run1.txt`): the 2 open records |
| `python3 -I doc/phase7/tools/lift_check.py doc/phase7/classification/all.json <s>/run1.json 1` | 122 records, 122 pass, 0 fail, 0 count differences |
| `dart run melos run test:cases` (repository root) | passed, 44 files, 0 errors, 0 warnings. Total 1036: 810 passed, 0 failed, 130 skipped, 96 missing (10 files without Dart tests). W2-int had 572, 0, 362, 102 |
| `dart run melos run check:lib-imports` | passed, 329 files |
| `dart run melos run check:headers` | passed, 366 files |
| `dart run melos run check:js-semantics` | passed, 131 files |

The test:cases figures of the files of L2: `controller.bar` 54/55, `core.controller` 72/85,
`core.datasetController` 40/43, `core.interaction` 43/45, `core.scale` 39/44, `core.ticks` 4/4,
`element.line` 2/2, `platform.dom` 17/21, `scale.category` 15/19, `scale.linear` 43/45,
`scale.logarithmic` 60/60, `scale.radialLinear` 20/23, `scale.time` 24/86. 0 failed and 0 missing
in each.

The full run and test:cases ran on the tree of that moment. X-fix, U-scatter and U-pie changed
`lib/` files in parallel. The last run of the 14 files came after these changes.

`test:web` did not run. The 3 moved files have `@TestOn('vm')`. Thus the web legs do not compile
them. They lose 3 pure cases: `core.ticks` "Should expose formatters api" and "should not fail on
empty or 1 item array", and `element.line` "should be constructed" (Chart.js ADR 0030 section 12
item 5). `core.interaction_test.dart` had no pure case that ran.

No `flutter_tester` process of L2 is left. The process 67820 belongs to another session
(scratchpad `ec6419b7-...`). L2 did not start it and did not stop it.

## Probes

| Probe | Result |
|---|---|
| `run_spec.mjs <dist> core.datasetController --mode none --filter 'should cleanup attached properties'` (`<s>/probe_dc_cleanup.json`) | pass upstream. The values compare `data0[hook]` with `Array.prototype.push`, `pop`, `shift`, `splice` and `unshift`, and test `data0._chartjs` with `toBeDefined` |
| `run_spec.mjs <dist> core.controller --mode none --filter 'blank inline plugin'` (`<s>/probe_cc_blank.json`) | pass upstream. 1 value: `toBeNull` of `Object.getPrototypeOf(plugin.options)` |

## Doc notes for W3-int

### `doc/status.yaml`

Replace the texts of these spec rows. Then run `dart run melos run parity`. The 3 moved files
lose `on {{platforms}}` where they have it (TS section 6). If the phase lead removes the 2
`diverges` skips (open items 1 and 2), remove their items from the texts.

- `test/specs/controller.bar.tests.js`: replace
  `{{skipped|case}} skipped: {{skipped:blocked: controller.line}} `blocked: controller.line` (wave 2 of phase 7) and {{skipped:blocked: plugin.tooltip}} `blocked: plugin.tooltip``
  with `{{skipped:blocked: plugin.tooltip|case}} skipped, `blocked: plugin.tooltip``. After the D1
  sentence, add: "The 3 cases with a dataset of the type `line` (`:70`, `:310`, `:671`) got their
  bodies in the lift of wave 2."
- `test/specs/core.controller.tests.js`: the skip list becomes
  `{{skipped|case}} skipped: {{skipped:blocked: controller.pie}} `blocked: controller.pie`, {{skipped:blocked: plugin.tooltip}} `blocked: plugin.tooltip`, {{skipped:blocked: plugin.legend}} `blocked: plugin.legend`, {{skipped:n/a}} `n/a` (DOM element ids) and {{skipped:diverges: js-semantics-resolver-objects}} `diverges: js-semantics-resolver-objects` (the blank inline plugin of :1936: a resolver has no `getPrototypeOf` trap); {{differences}}`.
  Add: "The 29 cases of the line controller are `testWidgets` cases. A data array change of a
  spec calls `notifyArrayListeners` after the change."
- `test/specs/core.datasetController.tests.js`:
  `"ported ({{passed}}/{{cases}} cases pass; {{skipped|case}} skipped: {{skipped:blocked: controller.scatter}} `blocked: controller.scatter` and {{skipped:diverges: platform-array-events}} `diverges: platform-array-events` (:841 compares the hooked array methods with `Array.prototype`); {{differences}}. Each case builds a chart with a controller of phase 7 and the scales of phase 6. Each chart case is a `testWidgets` case, and the file runs on the VM only ([Chart.js ADR 0030](adr/0030-controller-test-strategy.md) §12 item 5). A data array change of a case calls `notifyArrayListeners` after the change ([differences.md](differences.md#platform-array-events)). The fixture group `auto` waits for phase 7. `test/port/core/core.datasetController_test.dart` covers the controller, also on the web legs)"`
- `test/specs/core.interaction.tests.js`:
  `"ported ({{passed}}/{{cases}} cases pass; {{skipped:blocked: controller.scatter|case}} skipped, `blocked: controller.scatter`. Each case reads the elements of a chart that a dataset controller updates. Each chart case is a `testWidgets` case, and the file runs on the VM only ([Chart.js ADR 0030](adr/0030-controller-test-strategy.md) §12 item 5). The event object of the spec is a `ChartEvent`. The fixture group `auto` waits for phase 7. `test/port/core/core.interaction_test.dart` covers the modes, also on the web legs)"`
- `test/specs/core.scale.tests.js`: the skip list becomes
  `{{skipped:blocked: controller.scatter|case}} skipped, `blocked: controller.scatter``. Replace
  "The 12 chart cases that pass" with "The 38 chart cases that pass".
- `test/specs/core.ticks.tests.js`:
  `"ported ({{passed}}/{{cases}} cases pass. The 2 tick generator cases are `testWidgets` cases with a line chart, and the file runs on the VM only ([Chart.js ADR 0030](adr/0030-controller-test-strategy.md) §12 item 5))"`
- `test/specs/element.line.tests.js`:
  `"ported ({{passed}}/{{cases}} cases pass. The case of :14 is a `testWidgets` case with `waitForDone`, and the file runs on the VM only ([Chart.js ADR 0030](adr/0030-controller-test-strategy.md) §12 item 5); the fixture group `auto` waits for phase 7)"`
- `test/specs/platform.dom.tests.js`: remove
  `{{skipped:blocked|case}} skipped: {{skipped:blocked: controller.doughnut}} `blocked: controller.doughnut` and {{skipped:blocked: controller.line}} `blocked: controller.line`. They create a chart of that type; `.
- `test/specs/scale.category.tests.js`: the skip list becomes
  `{{skipped:blocked: plugin.legend|case}} skipped, `blocked: plugin.legend``. Replace the text
  from "2 cases that pass have no chart." to "waits for `controller.line`." with: "2 cases that
  pass have no chart. The other 13 are `testWidgets` cases with a line or a bar chart. The cases
  at :222 and :514 give the raw label values to `getPixelForValue` ([Chart.js ADR
  0025](adr/0025-scale-value-parameters.md))."
- `test/specs/scale.linear.tests.js`: the skip list becomes
  `{{skipped:blocked: plugin.legend|case}} skipped, `blocked: plugin.legend``. Remove "A case that
  needs the bar and the line controllers skips as `blocked: controller.line`." Replace "The other
  30 are `testWidgets` cases with `acquireChart`: 25 bar charts with datasets and 5 charts without
  datasets" with "The other 41 are `testWidgets` cases with `acquireChart`".
- `test/specs/scale.logarithmic.tests.js`: replace
  `{{skipped|case}} skipped: {{skipped:blocked: controller.line}} `blocked: controller.line`. 2 cases that pass have no chart. The other 21 are `testWidgets` cases with a bar chart. A case with bar and line datasets skips as `blocked: controller.line`.`
  with "2 cases that pass have no chart. The other 58 are `testWidgets` cases with a line or a bar
  chart."
- `test/specs/scale.radialLinear.tests.js`: the skip list becomes
  `{{skipped:blocked: plugin.legend|case}} skipped, `blocked: plugin.legend``. Replace "The 2
  cases that pass have no chart. The `plugin.legend` cases also need `controller.radar`." with
  "2 cases that pass have no chart. The other 18 are `testWidgets` cases with a radar or a polar
  area chart."
- `test/specs/scale.time.tests.js`: remove
  `, {{skipped:blocked: controller.line}} `blocked: controller.line`` (put "and" before the
  `plugin.legend` item). Replace "The other 7 are `testWidgets` cases" with "The other 21 are
  `testWidgets` cases". Replace "2 twins pass. The other 57 twins keep their bodies and skip as
  `blocked: controller.line`." with "Each twin passes. The 57 twins with a dataset are
  `testWidgets` cases."
- The port-only row `test/port/scales/scale.time_test.dart`: replace "2 twins pass. The other 57
  keep their bodies and skip as `blocked: controller.line`." with "Each twin passes."

### `doc/porting-flow.md`

Section 5, the phase 7 row (result of wave 3): "L2 lifted the records of wave 2 outside the
controller spec files: `core.controller` 30, `core.datasetController` 38, `core.interaction` 43,
`core.scale` 26, `core.ticks` 2, `element.line` 1, `platform.dom` 2, `scale.category` 11,
`scale.linear` 11, `scale.logarithmic` 37, `scale.radialLinear` 18, `scale.time` 14, the 3
placeholders of `controller.bar_test.dart` and the 57 twins of `test/port/scales/scale.time_test.dart`.
291 pass in the first run, with no change in `lib/`. 2 records have no Dart form and skip as
`diverges` (the decision of the phase lead). `core.interaction_test.dart`, `core.ticks_test.dart`
and `element.line_test.dart` moved to the VM: 3 pure cases lost the web legs (`core.ticks` 2,
`element.line` 1)."

### `AGENTS.md`

Tests section, add a bullet: "A spec that changes a data array of a chart (`push`, `pop`,
`shift`, `splice`, `unshift`) changes the `List` and then calls `notifyArrayListeners`, the body of
the hooked method (differences.md row `platform-array-events`; the helpers `_push` to `_unshift` of
`test/specs/core.datasetController_test.dart`). `chart.getActiveElements()` in a Jasmine
`toEqual` is the list of the objects `{element, datasetIndex, index}`. The event object
`{type, chart, native: true, x, y}` of `core.interaction.tests.js` is a `types.ChartEvent` with
`native` null."

### `doc/differences.md`

Only if the phase lead keeps the 2 `diverges` skips (open items 1 and 2):

- Row `platform-array-events`, column of the tests: add "`test/specs/core.datasetController_test.dart`
  skips the case of `core.datasetController.tests.js:841` (the stub `_chartjs` and the hooked
  methods)."
- Row `js-semantics-resolver-objects`, column of the tests: add "`test/specs/core.controller_test.dart`
  skips the case of `core.controller.tests.js:1936` (`Object.getPrototypeOf` of the plugin
  options)."

### `doc/performance.md`, `doc/upstream-ledger.md`

No change. L2 adds no performance figure and no ledger item.

## Open items

1. **`core.datasetController.tests.js:841` "should cleanup attached properties when the
   reference changes or when the chart is destroyed".** The case reads the stub `_chartjs` of
   each data array and compares the 5 array methods with `Array.prototype`. The port keeps the
   stub in a private `Expando` of `lib/src/helpers/helpers.collection.dart` and hooks no method
   (row `platform-array-events`). No assertion has a Dart form. The case skips as
   `diverges: platform-array-events`, with the probe above as evidence. `lift_check.py` counts the
   record as a failure. Chart.js ADR 0030 section 12 item 8.5 makes a verdict change a decision of
   the phase lead, with `compare.mjs` evidence. The other way: a port-only reader of the stub in
   `helpers.collection.dart` (for example `hasArrayListeners(list)`). Then the `_chartjs`
   assertions have a Dart form, but the comparisons with `Array.prototype` still have none.
2. **`core.controller.tests.js:1936` "should not crash when accessing options of a blank inline
   plugin".** The case iterates `chart._plugins._init` and reads `Object.getPrototypeOf(plugin.options)`.
   Two causes: (a) `PluginService._init` in `lib/src/core/core.plugins.dart` keeps its underscore,
   so a spec cannot read it (Chart.js ADR 0012: a member that a spec reads drops the underscore);
   (b) a resolver has no `getPrototypeOf` trap (row `js-semantics-resolver-objects`). The case
   skips as `diverges: js-semantics-resolver-objects`. A fix of (a) is a change of
   `core.plugins.dart` (not in the row of L2). After it, the body can be this, if the phase lead
   accepts "a Map has no prototype" (the table of helpers.config.dart, line 20) as the form of
   `toBeNull`:

   ```dart
   testWidgets(
     'should not crash when accessing options of a blank inline plugin',
     (tester) async {
       final chart = acquireChart(<String, Object?>{
         'type': 'line',
         'data': <String, Object?>{
           'datasets': <Object?>[<String, Object?>{}],
         },
         'plugins': <Object?>[<String, Object?>{}],
       });

       void iterateOptions() {
         for (final plugin in chart.plugins.init!) {
           // triggering bug https://github.com/chartjs/Chart.js/issues/9368
           // A resolver has no prototype (js-semantics-resolver-objects).
           expect(plugin.options, isA<Map<String, Object?>>());
         }
       }

       expect(iterateOptions, returnsNormally);
     },
   );
   ```

3. **Copies of Jasmine `toBeCloseTo`.** `scale.linear_test.dart`, `scale.logarithmic_test.dart`
   and now `core.scale_test.dart` have the same private `_toBeCloseTo` (jasmine-core 3.99.1).
   `element.arc_test.dart` has another form. A unit that owns `test/support/jasmine.dart` can move
   one copy there (L1 open item 1).
4. **`_toBeCloseToTime`** of `scale.time_test.dart` supports only the unit `hour`, the only unit
   of the lifted cases. A case with another unit (the moment `diff` with `true`) needs more code.
5. **The lift list of wave 3 (L3)** keeps its placeholders: `core.controller` 7 (`blocked:
   controller.pie`), `core.datasetController` 2, `core.interaction` 2 and `core.scale` 5
   (`blocked: controller.scatter`). L2 did not change them.
6. **`status.yaml` and `parity.md`** (above) are for W3-int. L2 did not run `parity`.

## Fixes

The fixer read `L2-review.md` (3 findings). `<f>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave3/L2-fix`.
The fixes changed 3 files of the row of L2 and this report. No `lib/` file, no harness file, no
generated file and no shared doc changed.

| File | Change |
|---|---|
| `test/specs/core.datasetController_test.dart` | The case of `:841` is a `testWidgets` case with a body (finding 2). The skip `diverges: platform-array-events` is removed. |
| `test/specs/core.controller_test.dart` | The case of `:1936` is a `testWidgets` case with a body (finding 3). The skip `diverges: js-semantics-resolver-objects` is removed. |
| `test/specs/scale.logarithmic_test.dart` | The comment line of 126 characters at `:43` is wrapped (the observation of the review). No code changed. |

### L2-R2 (confirmed): the case of `core.datasetController.tests.js:841`

Fixed. The case has the config of upstream. The Dart form of each `_chartjs` and hook check is
the effect of the listener on the elements of the meta:

1. "data0 has the listener" (`toBeDefined` and the hooks of data0): `_unshift(data0, [-1])` and
   an update put a new element at index 0. The old element of index 0 moves to index 1
   (`_onDataUnshift`, `core.datasetController.js:1074`).
2. "data0 has no listener" after the reference change (`core.datasetController.js:378-380`):
   `_push(data0, [9])` and an update keep `meta.data[2]` (the form of the review).
3. "data1 has the listener" after the change: `_unshift(data1, [5])` and an update put a new
   element at index 0. This check is also the positive control of check 2: the form sees a
   listener.

The checks of data1 before the change and after `destroy` (`core.datasetController.js:355`) have
no Dart form: data1 is not the data of a chart, and a destroyed chart does not update. The
comment of the case says this.

| Probe | Result |
|---|---|
| `<f>/probe.mjs` (x64 Node.js v24.12.0, the build at the pin), `<f>/probe.out` | `arch x64 version 4.5.1`. Check 1: `data[0] new true`, `data[1] same true`. Check 2: `same true` without a stale hook, `same false` with a stale hook that calls `_onDataPush`. Check 3: `data[0] new true`, `data[1] same true` |
| `<f>/mut_dc_test.dart` (a copy of the spec with `listenArrayEvents(data0, controller)` after the change), `<f>/mut.out` | The case fails at check 2 (`Expected: same instance as <Instance of 'PointElement'>`). Thus the case finds a stale listener |
| The case in the spec | pass |

### L2-R3 (plausible): the case of `core.controller.tests.js:1936`

Confirmed by the probes of the fixer, and fixed. `chart._plugins._init` is
`chart.plugins.cache!`: `PluginService._init` is private in `core.plugins.dart` (a file outside
the row of L2), and `cache` (`core.plugins.js:94` `_cache`) is public (`@internal`).
`Object.getPrototypeOf(plugin.options)` `toBeNull` is `isA<Map<String, Object?>>()`: the options
are a resolver of helpers.config, and a Map has no prototype (the trap table of
`helpers.config.dart`). The body is the body of open item 2, with `cache` in place of `init`.

| Probe | Result |
|---|---|
| `<f>/r3_probe.mjs`, `<f>/r3_probe.out` (upstream) | `init 1 cache 1`, the same plugin in both, `options same false`, no keys in both, both prototypes `null` |
| `<f>/r3_probe_test.dart`, `<f>/r3_probe.out` (port) | R3a: `cache length=1`, the same plugin, a `ContextResolver` without keys. R3b: the options of the `install` hook (the `_init` descriptor) and the options of `cache` are 2 `ContextResolver` objects without keys, not the same object, `isMap=true`. This agrees with upstream |
| The case in the spec | pass |

Thus `cache` holds the same descriptors as `_init` for this chart, in the port and upstream. The
substitution keeps the behavior that the case tests (the iteration of the options of a blank
inline plugin, bug #9368).

### L2-R1 (confirmed): the 2 `diverges` skips and the lift check

Fixed by the fixes of L2-R2 and L2-R3. The 2 `phase7` records pass. No verdict of `all.json`
changed, so Chart.js ADR 0030 section 12 item 8.5 does not apply. Open items 1 and 2 are closed.

### Changes to the doc notes for W3-int

- `doc/status.yaml`: the texts of `core.controller.tests.js` and `core.datasetController.tests.js`
  do not get the `diverges` items. The skip list of `core.controller.tests.js` is
  `{{skipped|case}} skipped: {{skipped:blocked: controller.pie}} `blocked: controller.pie`, {{skipped:blocked: plugin.tooltip}} `blocked: plugin.tooltip`, {{skipped:blocked: plugin.legend}} `blocked: plugin.legend` and {{skipped:n/a}} `n/a` (DOM element ids); {{differences}}`.
  The skip list of `core.datasetController.tests.js` is
  `{{skipped:blocked: controller.scatter|case}} skipped, `blocked: controller.scatter``.
- `doc/differences.md`: no change. The 2 items of the section "`doc/differences.md`" above do not
  apply.
- The phase 7 row of `doc/porting-flow.md`: replace "2 records have no Dart form and skip as
  `diverges` (the decision of the phase lead)." with "The 2 records that read `_chartjs` and
  `Object.getPrototypeOf` check the effect of the array listener and the resolver type."
  The count "291 pass" becomes "293 pass".

### Checks after the fixes

| Command (from `packages/flutter_chartjs` unless noted) | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed` on the 3 changed files | 0 changed |
| `dart analyze --fatal-infos` on the 3 changed files | No issues found |
| `flutter test --reporter json` on the 14 files of L2 (`<f>/run.json`) | exit 0; 612 passed, 0 failed, 97 skipped (before: 610, 0, 99) |
| `python3 -I doc/phase7/tools/lift_check.py doc/phase7/classification/all.json <f>/run.json 2 --list` (`<f>/lift.txt`) | In the files of L2, 0 failures: `core.controller` 34, 0; `core.datasetController` 41, 0; each other file of L2 as before. The other failures are records of files outside this run (`missing`) |
| `dart run melos run check:headers` (repository root) | passed, 366 files |
| `dart run melos run check:js-semantics` (repository root) | passed, 131 files |
| `dart run melos run check:lib-imports` (repository root) | passed, 329 files |

`test:cases` and the full run did not run again: the units run in parallel, and W3-int runs the
full gate. No `flutter_tester` process of the fixer is left. The process 67820 belongs to another
session (`<f>/pids_before.txt`). The fixer did not stop it.
