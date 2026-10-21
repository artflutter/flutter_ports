# Wave 3, unit L2 (the lift of wave 2): adversarial fidelity review

## Scope

The reviewer read `L2-report.md` and the `git diff` of the 14 files of the unit (13 spec files and
`test/port/scales/scale.time_test.dart`). The reviewer compared each lifted body with the
upstream case at its line in `third_party/Chart.js/test/specs/` (pin `7169e651`), and each
decision with Chart.js ADRs 0009, 0010, 0012 and 0030 §12, the work plan §3 and the decisions
D10-D12.

`<scratch>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad`.
The probes are in `<scratch>/wave3/L2-review/`:

- `cmp.py`, outputs `nums.txt` (literals) and the `order` and `calls` modes: a comparison of
  each lifted body with its upstream body.
- `run.json`, `run.err`: `flutter test --reporter json` on the 14 files.
- `lift.txt`: `lift_check.py ... run.json 2 --list` on that run.
- `p1_probe_test.dart`, output `p1.out`; `p2_probe_test.dart`, output `p2.out`: Dart probes.
  `flutter_test_config.dart` is a copy of the package file, so that the probes run in the
  harness.
- `probe.mjs`, output `probe.out`: x64 Node.js v24.12.0 on the build at the pin
  (`loadChartJs` stops on another arch or commit). The output starts with
  `arch x64 version 4.5.1`.

The reviewer started no `flutter_tester` process that stays. Process 67820 ran before the probes
(`pids_before.txt`). It belongs to another session. The reviewer did not stop it.

## Result

The 291 lifted records with a body agree with upstream. The reviewer found no difference in a
protected behavior (Chart.js ADR 0009) and no wrong JS form (Chart.js ADR 0010) in them. L2
changed no `lib/` file, so D10 and D11 do not apply. The review has 3 findings. Findings 1 and 2
are about the 2 `diverges` skips of `phase7` records. Finding 3 is a format item.

| # | Verdict | File | Finding |
|---|---|---|---|
| 1 | confirmed | `test/specs/core.controller_test.dart:2286`, `test/specs/core.datasetController_test.dart:1170` | 2 `phase7` records skip as `diverges`. `lift_check.py` is not green |
| 2 | confirmed | `test/specs/core.datasetController_test.dart:1170` | The case of `:841` has a Dart form for the cleanup at a reference change. No other test pins that cleanup |
| 3 | plausible | `test/specs/core.controller_test.dart:2286` | The case of `:1936` has a Dart form through `chart.plugins.cache` |

## Findings

### 1. Two `phase7` records skip as `diverges`, and the lift check is red (confirmed)

`core.datasetController.tests.js:841` skips as `diverges: platform-array-events`.
`core.controller.tests.js:1936` skips as `diverges: js-semantics-resolver-objects`. Both records
have the verdict `phase7` in `all.json`.

- Probe: `lift.txt`. Of the files of L2, only these 2 records fail:
  `core.controller_test.dart: 33, 1` and `core.datasetController_test.dart: 40, 1`.
- Chart.js ADR 0030 §12 item 8.6: each wave of the lift ends with `lift_check.py` green. The work
  plan §3 makes "`lift_check.py ... 2` green" a condition of W3-int.
- Item 8.5: a verdict changes only with `compare.mjs` evidence, as a decision of the phase lead in
  `summary.md` §8, and the change updates `all.json`. Neither exists. The report gives
  `run_spec.mjs` output only, and it sends the decision to the phase lead (open items 1 and 2).
- Item 8.4 accepts `diverges` only for a difference that Chart.js ADR 0009 does not protect. The
  hooked methods and the prototype are not protected. But the two cases also assert behavior
  that has a Dart form (findings 2 and 3).

Thus W3-int cannot close the wave until the phase lead decides. The report says this. This
finding records that the unit is not complete by item 8.6.

### 2. The case of `core.datasetController.tests.js:841` has a Dart form for the cleanup (confirmed)

The comment at `core.datasetController_test.dart:1165-1169` and open item 1 of the report say:
"No assertion of the case has a Dart form." The case tests that the controller removes its
listener from the old array when the reference changes (`core.datasetController.js:378-380`,
`unlistenArrayEvents(_data, this)`) and at destroy (`:355`). The `_chartjs` stub and the
`Array.prototype` comparisons have no Dart form. But the effect of the listener has one:

1. Acquire a line chart with `data0`. Set the data of the dataset to `data1` and update.
2. Keep `e2 = meta.data[2]`.
3. Push an item to `data0` (`notifyArrayListeners` in the port), then update.
4. Without a listener on `data0`, `meta.data[2]` is still `e2`. With a stale listener,
   `_onDataPush` queues `_insertElements(2, 1)`, and `_resyncElements` removes the last element.
   Then `meta.data[2]` is a new element.

| Probe | Without a stale listener | With a stale listener |
|---|---|---|
| Upstream (`probe.out`, N1; the stale hook calls `controller._onDataPush`) | `data[2] same true` | `data[2] same false` |
| Port (`p2.out`, P4; `listenArrayEvents(data0, controller)` after the change) | `data[2] same=true` | `data[2] same=false` |

No test of the package pins the unlisten at a reference change: `grep -rn unlisten test/port/core`
finds nothing. `test/port/helpers/helpers.collection_test.dart` tests `unlistenArrayEvents`
alone, not its call in `_dataCheck`. The skip removes the only pin of
`core.datasetController.dart:940` (`unlistenArrayEvents(oldData, this)`).

Recommendation: give the case a body with the identity check above (and the `undefined` checks
of the stub, if a port-only reader of the stub comes), or keep the skip and add a port-only test
in `test/port/core/` with the identity check. The phase lead decides (Chart.js ADR 0030 §12
item 8.5).

### 3. The case of `core.controller.tests.js:1936` has a Dart form through `chart.plugins.cache` (plausible)

The comment at `core.controller_test.dart:2280-2285` says: "Thus the assertion of the case has no
Dart form." The case has two assertions: `expect(iterateOptions).not.toThrow()` (the bug
chartjs/Chart.js#9368) and `Object.getPrototypeOf(plugin.options)` is `null`.

- `PluginService.cache` is public (`core.plugins.dart:72`, `@internal`). For this chart it holds
  the same descriptors as `_init`: the chart disables no plugin.
- Port (`p2.out`, P3): `cache length = 1`, the options are a `ContextResolver`, a
  `Map<String, Object?>`, with no keys. The loop returns normally.
- Upstream (`probe.out`, N2, with the registration of the reference generators): `init 1`,
  `cache 1`, `protos [ null ]`.

Thus the `not.toThrow` assertion has a Dart form now, without a change of `core.plugins.dart`.
The prototype assertion can take the form "a Map has no prototype" (`isA<Map<String,
Object?>>()`), as the report proposes. The skip reason names only the resolver row. The other
cause in the comment, the underscore of `_init`, is a rename by Chart.js ADR 0012 (a member that
a spec reads drops the underscore), not a difference. The verdict is "plausible": the choice of
`cache` for `_init` and of `isA<Map>` for `toBeNull` is a decision of the phase lead.

## Observation (no defect of behavior)

`test/specs/scale.logarithmic_test.dart:43` is a comment line of 126 characters. The edit of
L2 joined two lines and did not wrap the result. `dart format` and `dart analyze` do not flag
comment lines. The other lines of the comment block are at most 80 characters.

## Checks with no defect

1. **Run and lift check.** `run.json`: exit 0, 610 passed, 99 skipped, 0 failed, as the report.
   `lift.txt`: in the files of L2, each `phase7` record of wave 2 or earlier passes, except the 2
   records of finding 1. The 57 twins pass. The other failures of `lift.txt` are records of files
   outside this run ("now: missing").
2. **Bodies against upstream.** `cmp.py` found the upstream body of each record at its `line` in
   `all.json` and the Dart case with the same name: 169 bodies for 236 spec records (the loops
   make several records from one body). It compared the number literals (as a multiset and in
   order), the upstream string literals, and the counts of `expect(`, `update(`,
   `acquireChart(`, `getPixelForValue`, `getValueForPixel`, `getLabelForValue`,
   `getDatasetMeta`, `hidden`, `reverse`, `destroy`, `splice`, `toThrow`, `toBe(`, `toEqual(`
   and `not.`. Each difference has a cause that is not a defect:
   - `'click'` of the 32 interaction events is the getter `type` of `_Event`.
   - The string pieces of the error message of `:15`, `'before-' + args.index` (`:1913`) and
     `'{' + i + '}'` (`scale.time.tests.js:376`) are interpolations.
   - The 20 tick strings of `core.ticks.tests.js:55` are in the `const expected` list.
   - `data.length = 42` (`core.datasetController.tests.js:632`) adds 40 `undefined` items: a hole
     reads as `undefined`.
   - The keys `0` and `1` of the `_stacks` object (`:932`) are the strings `'0'` and `'1'`.
   - `'MMM DD YYYY'` (`scale.time.tests.js:84`) is the ICU pattern `'MMM dd yyyy'`. Probe P2:
     the parse gives 631152000000 (1990-01-01 UTC), the moment value.
   - `toBe(n)` of a number is `expect(x, n)`. Dart `==` gives the same result as `===` for these
     values, also for `0` and `-0`.
   - The 4 records with generated names (the spanGaps loop of `core.interaction`, the grid line
     loops of `core.scale`, the second `when` group of `scale.logarithmic`) agree by reading: the
     `testCases` data, the 8 `gridLineTests` items with their expected pixels, and the
     `beforeEach` of `:977-1003` (`_acquireWhenChart`: `setup.data || {...}`, the two
     `Object.assign` calls, no read of `setup.type`).
3. **Assertions that can fail.** Probe P1: an absent key of a resolver reads as `undefined`
   through `options[key]` and through `jsGet`. Thus `isNot(same(undefined))` (the `toBeDefined`
   of `core.controller.tests.js:508`) fails on a chart without the key. `line['_path']`
   (`element.line.tests.js:14`) reads the field `_path` of `LineElement` (`element.line.dart:1121`),
   not the extra-property Map. The "should draw" twin of each `display: 'auto'` case shows that
   the scale draws into `scale.ctx`, so the "should not draw" cases are not vacuous. The label
   alignment loop of `scale.radialLinear.tests.js:551` has 5 calls for each start angle (the
   report's probe).
4. **JS semantics.** The event of `core.interaction` is a `types.ChartEvent`.
   `getRelativePosition` tests that type (`helpers.dom.dart:127-128`) where upstream tests
   `'native' in event` (`helpers.dom.ts:109`). `_push` to `_unshift` notify after the change, also
   for an empty array, as the hooked methods of `helpers.collection.ts:130-149`. `_splice` passes
   the raw `start` and `deleteCount`, as upstream. The shared `data1` and `data2` of
   `labels array synchronization` and the shared `setup.dataset` of the `when` groups stay in the
   group closures, as upstream. `jsonEncode` gives the `JSON.stringify` group names. The
   `_toBeCloseToTime` of unit `hour` is the precise moment diff `(this - that) / 36e5`.
5. **Citations.** The new citations are correct: `scale.logarithmic.tests.js:962-973`,
   `:977-1003`, `:1084-1095`, `:1099-1125`; `scale.time.tests.js:31-48`, `:84`, `:305`, `:390`,
   `:490`, `:548`; `core.interaction.tests.js:916`, `:997-1024`; `element.line.tests.js:14`;
   `controller.bar.tests.js:70`, `:310`, `:671`, `:1808`; the `getLabels` lines `:1-3` of 3
   specs. `helpers.dom.ts:105` names the start of `getRelativePosition`, as the doc comment of
   the port does.
6. **Headers, skips and files.** Line 1 of each of the 14 files did not change. No new
   `blocked:` or `n/a:` skip. The remaining skips of the files of L2 are records of a later wave
   (`controller.scatter`, `controller.pie`), of phase 8 (legend, tooltip) or `diverges` rows that
   existed before L2. The files are the row of L2 (work plan §3). `dart analyze --fatal-infos` on
   5 of the files: no issues.
7. **The moved files.** `core.interaction_test.dart`, `core.ticks_test.dart` and
   `element.line_test.dart` have `@TestOn('vm')`, `flutter_test` and
   `package:chartjs_test_utils/flutter.dart`, and no `setUpSpecs()`. The 3 pure cases that lose
   the web legs agree with Chart.js ADR 0030 §12 item 5.
8. **Report.** The counts of the doc notes agree with `all.json` and the run: for example
   `core.scale` 12 + 26 = 38, `scale.linear` 30 + 11 = 41, `scale.logarithmic` 2 + 58 = 60,
   `scale.radialLinear` 2 + 18 = 20, `scale.category` 2 + 13 = 15.

## Probes

| Probe | Result |
|---|---|
| `cmp.py nums`, `order`, `calls` | Only the differences of check 2 |
| `run.json` | exit 0; 610 passed, 99 skipped |
| `lift.txt` | the 2 records of finding 1 fail; no other record of the files of L2 fails |
| P1 (`p1.out`) | `chart.options[absent] = undefined`; the `toBeDefined` form fails without the key |
| P2 (`p2.out`) | `parse = 631152000000.0` |
| P3 (`p2.out`) | `cache length = 1`; `ContextResolver`, `isMap=true`; no throw |
| P4 (`p2.out`) | `relisten=false ... same=true`; `relisten=true ... same=false` |
| N1 (`probe.out`) | `relisten false ... same true`; `relisten true ... same false` |
| N2 (`probe.out`) | `init 1 cache 1 protos [ null ]` |
