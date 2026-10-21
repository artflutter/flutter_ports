# L1 review: the lift of wave 1 (wave 2)

Adversarial fidelity review of unit L1 (work plan §2, TS §4, Chart.js ADR 0030 §12).

## Scope

- `L1-report.md`, with its doc notes for W2-int.
- The git diff against 436663f of the 8 spec files of the row:
  `test/specs/core.animator_test.dart`, `helpers.dom_test.dart`,
  `core.datasetController_test.dart`, `core.layouts_test.dart`, `scale.category_test.dart`,
  `scale.linear_test.dart`, `scale.logarithmic_test.dart` and `scale.time_test.dart`.
- Upstream at the pin 7169e651: the 8 spec files in `third_party/Chart.js/test/specs/`.
- jasmine-core 3.99.1 of the pinned build (`toBe`, `toEqual`, `toBeCloseTo`).

## Result

No confirmed defect. No plausible defect. The 60 records of the wave 1 lift list have bodies
that agree with the upstream cases. Each one passes. The unit changed no `lib/` file and added no
skip. The report agrees with the run of this review. Three observations follow. None of them is
a defect of L1.

## Checks with no defect

1. **Lift list.** A script read `all.json` and the JSON reporter output of the 8 files. It gave
   each record its wave (the rule of `lift_check.py`). 69 records of these files have a wave of 1
   or less: 60 `phase7` and 9 `blocked: plugin.legend`. Each `phase7` record has a test with the
   same full name that is not skipped and passes. Each legend record skips with exactly its
   reason. The result: 0 failures.
2. **Bodies against upstream.** A script found the upstream body of each of the 60 records (at
   its `line` in `all.json`) and the Dart body of the `testWidgets` case with the same name. It
   compared:
   - the number literals, in order;
   - the string literals of upstream (each one must occur in the Dart body);
   - the object keys and the property names;
   - the counts of `expect(`, `update(`, `acquireChart(`, `toBeCloseToPixel`, `toBeCloseTo(`,
     `getPixelForValue`, `getValueForPixel`, `getLabelForValue`, `getDatasetMeta`, `hidden`,
     `reverse`, `toThrow`, `push` and the loops.

   All differences have a cause that is not a defect: the numeric keys of the `_stacks` objects
   are Dart strings; `'very long label ' + i` is an interpolation; the `forEach` of
   `scale.linear.tests.js:1199` is a `for` loop from 0; the shorthand properties `afterDraw()`,
   `labels` and `indexAxis` are keys in Dart; `not`, `helpers`, `datasets` and `_stacks` are
   Jasmine or helper forms (`_dataset`, `chart.stacks`). The 83 data points of the time case at
   `:1125` have the same values in the same order.
3. **First `when` group of `scale.logarithmic` (`:755-904`).** The shared `data`,
   `dataWithEmptyStacks` and `config` are in the group closure, as upstream. `Object.assign` is
   `addAll` (a shallow copy): for the `min: 0` items, `setup.scale.y` replaces the item with
   `beginAtZero: false`, and the write of `type` goes into `setup.scale.y`, as upstream.
   `setup.data || data` is `??`: an array is truthy. The 8 group names agree with upstream, also
   "not stacks are defined and min: 0". Two cases ran alone (`--plain-name`) and passed. Thus no
   case depends on an earlier case of the group.
4. **Matchers.** `_toBeCloseTo` agrees with `toBeCloseTo` of jasmine-core 3.99.1
   (`jasmine.js:6554-6581`): the default precision 2, `Math.round(delta * pow) <= maxDelta *
   pow`, and a false result for a value that is not a number. `toBe` is `===`
   (`jasmine.js:6515-6523`): the Dart `expect(actual, n)` gives the same result for these
   values. `not.toEqual(NaN)` is `isNot(jasmineEquals(double.nan))`: Jasmine `eq` makes NaN equal
   to NaN. `toEqual` of the `_stacks` objects compares `_bottom: null` by identity.
5. **Callbacks.** Probe P2 and P3 (below): a failed `expect` in `onComplete` or in `onProgress`
   of the animator case fails the test. Probe P1: `onProgress` fires 16 times, and `afterDraw`
   fires 16 times. Probe P4: `onHover` of `helpers.dom.tests.js:427` fires once, with `x` 270.
   Thus the assertions of these cases can fail, and they do not pass with the initial values.
6. **JS semantics.** `null` and `undefined` in the data arrays agree with upstream. The
   top-level `plugins: {legend: false}` of the time case goes to `_allPlugins`
   (`core.plugins.dart:251-273`), which reads `length` with `jsGet`, as `core.plugins.js:133-134`.
   `chart.options.scales.y.ticks.maxTicksLimit = 11` writes into the resolver of the last read of
   each chain, and the next labels show the write. No resolver goes into an `expect`.
7. **Citations.** The new citations are correct: `scale.category.tests.js:247` and `:534`,
   `scale.logarithmic.tests.js:756-839` and `:1-3`, `scale.linear.tests.js:1-3` and `:1199`,
   `core.layouts.tests.js:1-3`, Chart.js ADR 0019 §12 and Chart.js ADR 0022 §7.
8. **The two moved files.** `core.datasetController_test.dart` and `core.layouts_test.dart` have
   `@TestOn('vm')`, `flutter_test` and `package:chartjs_test_utils/flutter.dart`, and no
   `setUpSpecs()` (TS §4.2, Chart.js ADR 0030 §12 item 5). Before the move, `core.layouts` had
   1 pure case that ran ("should be exposed through Chart.layouts"), and
   `core.datasetController` had 0. This agrees with the report and with the ADR.
9. **Report.** The counts of the report agree with this run: +89 ~200 on the 8 files. The
   counts of the `status.yaml` notes agree with `all.json` and with the number of `testWidgets`
   cases in each file. The placeholders `{{skipped:blocked|case}}` and
   `{{skipped:<reason>}}` are valid for tool 6 (`tool/src/parity.dart:35`).
10. **Headers and checks.** Line 1 of each file did not change. `dart format`, `dart analyze
    --fatal-infos` on the 8 files, `check:headers`, `check:lib-imports` and `check:js-semantics`
    pass.

## Observations (no defect of L1)

### O1: two placeholders of `core.interaction_test.dart` keep the reason `blocked: controller.bar`

`test/specs/core.interaction_test.dart:133` and `:167` (`core.interaction.tests.js:153` and
`:274`) skip with `blocked: controller.bar`. Their records in `all.json` also need
`controller.line` (wave 2). Thus the reason is out of date after wave 1, but the case must still
skip. The file is in the row of L2, not L1. L2 lifts the two cases. If W2-int writes the
`status.yaml` text of `core.interaction.tests.js` before L2, the text keeps
`{{skipped:blocked: controller.bar}}`.

### O2: `toEqual` of a number is `equals`

In `scale.category.tests.js:514`, `expect(x2).toEqual(x3)` is `expect(x2, x3)`. Jasmine `eq`
makes `0` and `-0` different, and Dart `==` makes them equal. Here `x2` is larger than the
earlier pixel, which starts at 0, so `x2` is never `-0`. The wave 1 review of U-bar-tests
accepted the same form. Elsewhere L1 uses `jasmineEquals` for `toEqual` of a number
(`scale.linear.tests.js:1205-1206`, `:1233-1234`, `:1261`, `:1288`).

### O3: some pixel cases give a `double` where upstream gives an integer literal

`scale.linear.tests.js:1311-1312` and `:1351-1352` (`var min = -30; var max = 40;`) are
`const min = -30.0; const max = 40.0;`. The `when` group gives `firstTick` as a `double`. The JS
value is the same number. On the VM, a `double` goes to the port-only `value is double` path of
`getPixelForValue` (Chart.js ADR 0025), and an `int` goes to the general path. These cases test
only the first path on the VM. Other spec cases (for example `scale.category.tests.js:443` and
`:514`) give an `int`. Both paths give the upstream result in the passing cases.

## Probes

The probe folder is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/L1-review/`.

| Probe | Result |
|---|---|
| `cmp.py`: the literal, key, property and call comparison of the 60 bodies with upstream | Only the differences of check 2 |
| `run.json`: `flutter test --reporter json` on the 8 files | exit 0. 89 passed, 200 skipped. The 60 wave 1 `phase7` records pass. The 9 legend records skip with their reason |
| `l1_probe_test.dart` P1 (it runs the file through `testExecutable` of `flutter_test_config.dart`) | `count=16 drawCount=16`, `currentStep` 16 to 250 |
| `l1_probe_test.dart` P2: `expect(count, drawCount + 1000)` in `onComplete` | The test fails (TestFailure, then the `waitForDone` timeout) |
| `l1_probe_test.dart` P3: `expect(a.numSteps, 251)` in `onProgress` | The test fails |
| `l1_probe_test.dart` P4: `onHover` of `helpers.dom.tests.js:427` | `calls=1 dataX=270.0` |
| `--plain-name` of 2 cases of the first `when` group of `scale.logarithmic` | Each passes alone |

No `flutter_tester` process of this review is left. The process 67820 belongs to another
session. This review did not start it and did not stop it.
