# Wave 3, unit U-scatter: report

## Status

Done. The unit ported `src/controllers/controller.scatter.js` at the pin `7169e651` line by line,
with decision D10 in the loop of `updateElements`. The generator, its data, the port-only test
file and the spec port are new. All checks of the unit are green.

All paths are relative to `packages/flutter_chartjs/`. `<s>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave3/U-scatter`.
The logs are in `<s>/` and the probe is in `<s>/probe/`.

## Files

All files are new. The unit changed no other file.

| File | Content |
|---|---|
| `lib/src/controllers/controller.scatter.dart` | `ScatterController`: `id`, `defaults`, `overrides`, `jsClass`, `getLabelAndValue`, `update`, `addElements`, `updateElements`, `getMaxOverflow` (`controller.scatter.js:6-179`) |
| `tool/reference/controller_scatter_reference.mjs` | the generator: the 6 cases of Chart.js ADR 0030 §7 and 10 pin cases |
| `test/port/controllers/controller_scatter_reference.dart` | generated: 16 cases, 80 widths, 1 255 245 bytes, SHA-256 `0585dfeae77851468d2a68f320d02b475293bd48e7cc796380506d2ce31cec91` |
| `test/port/controllers/controller.scatter_test.dart` | the port-only reference tests and the pin tests |
| `test/specs/controller.scatter_test.dart` | the port of `test/specs/controller.scatter.tests.js` |
| `doc/phase7/review/wave3/U-scatter-report.md` | this report |

## The port

- Each statement of `controller.scatter.js:6-179` has a Dart statement in the same order.
- `this.chart.registry.getElement('line')` (`:105`) reads the singleton `registry` of
  `core.registry.dart`. The line has the marker `DIVERGES(chartjs): adapt-chart-registry-getter`.
  The row exists in `doc/differences.md` and names this site. The library doc names the import
  that upstream does not have (IV §4.1 rule 1).
- The four writes of `:80-83` are writes by name through `types.PropertyAccess`, as in
  `controller.line.dart`. `delete meta.dataset` (`:93`) is `meta.dataset = null`.
- D10: a pass of the loop keeps `vValue` (`:128`, `:130`) and `iValue` (`:129`, `:133`). The
  read `prevParsed[iAxis]` of `:133` stays a read at each pass (the 3-read form). No local
  carries a value across passes.
- Scatter does not set `enableOptionSharing`. The loop calls `resolveDataElementOptions`,
  `getSharedOptions`, `includeOptions` and `updateSharedOptions` as upstream (`:114-116`,
  `:150`). It does not call `getSharedOptions_`, because upstream does not call
  `_getSharedOptions`.
- `getMaxOverflow` keeps both branches: `max > 0 && max` (a number or `false`) without
  `showLine`, and the raw `borderWidth` of the line with `showLine`.
- Scatter has no `draw` override, as upstream. Thus a scatter line with `tension` draws its
  Bézier curves with NaN control points. The reference case `showLine true` pins this. The
  canvas of the port skips a `bezierCurveTo` with an argument that is not finite
  (`canvas_ui_path.dart:469`), as a Canvas 2D does.
- No new cast. Casts: `line! as types.PropertyAccess`, `point as types.PropertyAccess` (direct
  update only) and `data[i] as types.PointElement` at `size`, as in the line controller.

Deviation from the work plan: the row of U-scatter says that `controller.scatter.dart` imports
`controller.line.dart`. Upstream `controller.scatter.js` does not import `controller.line.js`
(its imports are `:1-4`). The port does not import it (porting rule 2, IV §4.1 rule 1). The
private helper `_setProperty` is a copy in the scatter library. See open item 1.

## Tests

### `test/port/controllers/controller.scatter_test.dart` (36 tests)

- The origin and width tests of the reference (`testReferenceOrigin`, `testReferenceWidths`).
- "the reference has the 6 cases of Chart.js ADR 0030 first": the first 6 names in the order of
  the ADR row, and each later name with a prefix (the U-bar-tests F1 lesson).
- The 16 generated cases. The 6 cases of ADR 0030 §7: `default` (no dataset element, with the
  scale options; steps `update`, `setActive`, `update none`, `push`, `splice`, `reset`,
  `update`), `showLine true` (the dataset option and the root option, `spanGaps 2`, `segment`,
  `tension 0.4`, a dataset with `showLine: false`; steps `update`, `push`, `splice`),
  `a visible x range` (`_drawStart`, `_drawCount`, an update with `start > 0`),
  `object data` (`parsing` keys, nested keys, `null`, absent keys, string values, NaN),
  `getLabelAndValue with labels`, `a hidden dataset` (steps `setDatasetVisibility`).
- The pin cases: `parsed: parsing false, a null item` (a `TypeError`),
  `parsed: parsing false, a logarithmic x, an item without x` and `... with x null` (PD §7.3),
  `parsed: the one-read rule with segment, spanGaps 2 and start > 0`, `parsed: spanGaps '2'`,
  `parsed: a scriptable option writes ctx.parsed` (D10), `parsed: stacked object data`
  (`applyStack`, `:130`), `parsed: showLine with no data returns the borderWidth '3'`
  (`:169-173`), `interfaces: the labels of getLabelAndValue, set 1` and `set 2` (IV §7.3).
- The group `theming.md §8 test 3: the light preset`: the 6 cases again, and the stale-key test.
- The group `parsed data`: the `TypeError` of a `null` item with `parsing: false`; the
  logarithmic x relation (`getPixelForDecimal(0)` and `skip` false, against NaN and `skip` true);
  an animated update ends at the points of an update without animation (the path of `:144`, and
  the writes `raw` and `parsed` of `:135-136`).
- The group `interfaces`: `line.points` with `showLine: true` after `update`, after `push` and
  after `splice` (IV §7.3); the group `showLine` (the switch of `:71-95`, Chart.js issue
  #11333: on, off and on; the root option; on at the creation, then off; the dataset element,
  `datasetElementType` `same` `registry.getElement('line')` and `LineElement.jsClass`, or
  `false`; `getMaxOverflow()`); the labels of `getLabelAndValue` and its value `'(1, 6)'`.

The expected values of the group `showLine` come from the probe `<s>/probe/probe_showline.mjs`
on the pinned build in the x64 Node.js v24.12.0 (output `<s>/probe/probe_showline.out`). The
generator has no step that writes an option. The results: the dataset element is a
`LineElement` exactly while `showLine` is truthy, a new element after each switch on, no
`dataset` key after a switch off, and `getMaxOverflow()` 8 (with `borderWidth: 4`) and 5 (the
defaults).

Mutation evidence (each mutation of `controller.scatter.dart`, then the restore; `cmp` with the
backup `<s>/controller.scatter.dart.bak` gave no difference):

| Mutation | Failed tests |
|---|---|
| a local of the previous pass for `prevParsed[iAxis]` (the D6 form) | `parsed: a scriptable option writes ctx.parsed` |
| no `delete meta.dataset` and no `datasetElementType = false` | the 2 `showLine` switch-off tests |
| no `options.segment` (`:86`) | 10 (6 unthemed, the themed twins) |
| `ToNumber` of the returned border (`:172`) | `parsed: showLine with no data returns the borderWidth '3'` |
| `raw` from the parsed item (`:136`) | the animated update test |
| no `datasetElementType` from the registry (`:105`) | the 2 spec cases `should create line element ...` |

### `test/specs/controller.scatter_test.dart` (6 cases)

The names and the order agree with upstream character for character. The verdicts agree with
`doc/phase7/classification/all.json`:

| Line | Case | Verdict | Dart |
|---|---|---|---|
| `:4` | should be registered as dataset controller | `phase7` | `test`, passes |
| `:8` | should only show a single point in the tooltip on multiple datasets | `blocked: plugin.tooltip` | `test(..., () {}, skip: ...)` |
| `:43` | should not create line element by default | `phase7` | `testWidgets`, passes |
| `:76` | should create line element if showline is true at datasets options | `phase7` | `testWidgets`, passes |
| `:110` | should create line element if showline is true at root options | `phase7` | `testWidgets`, passes |
| `:146` | should not override tooltip title and label callbacks | `blocked: plugin.tooltip` | `test(..., () {}, skip: ...)` |

The group `auto` (`:2`) is a comment at its upstream position.

Registration: both test files call `Chart.register([ScatterController.jsClass]);` first in
`main()`, before the snapshot of the defaults restore (work plan §0 rule 6, TS §2).

## Checks

| Command | Result |
|---|---|
| `dart run melos run analyze` | No issues found (the whole workspace, with `apps/chartjs_gallery`; no gallery interface changed) |
| `dart format --output=none --set-exit-if-changed` on the 4 Dart files | 0 changed |
| `flutter test test/port/controllers/controller.scatter_test.dart` | +36, all passed (`<s>/run1.log`) |
| `flutter test test/specs/controller.scatter_test.dart` | +4 ~2, all passed |
| `dart run melos run test:cases` | passed, 44 files, 0 errors, 0 warnings. `controller.scatter.tests.js`: 6 cases, 4 passed, 0 failed, 2 skipped, 0 missing (`<s>/test_cases.log`) |
| `dart run melos run check:headers` | passed, 366 files, 0 errors, 0 warnings |
| `dart run melos run check:js-semantics` | passed, 131 files, 0 errors, 0 warnings |
| `dart run melos run check:lib-imports` | passed, 329 files, 0 errors, 0 warnings |
| the generator, 2 runs (`/usr/bin/arch -x86_64 <env>/node-v24.12.0-darwin-x64/bin/node tool/reference/controller_scatter_reference.mjs <env>/chartjs-build/dist/chart.js`) | both runs: SHA-256 `0585dfeae77851468d2a68f320d02b475293bd48e7cc796380506d2ce31cec91` (`<s>/sha1.txt`, `<s>/sha2.txt`): byte-identical |

The other checks of the full gate are for W3-int. No `flutter_tester` process of this unit is
left. The process 67820 belongs to another session (scratchpad `ec6419b7-...`). This unit did not
start it and did not stop it.

## Doc notes for W3-int

- **AGENTS.md, Layout**, the item `lib/src/controllers/`: add a sub-item: "`controller.scatter.dart`
  has `ScatterController`. It imports `core.registry.dart`: `this.chart.registry` is the
  singleton `registry` (row `adapt-chart-registry-getter`). Its `updateElements` keeps the
  parsed values only inside one pass (the 3-read form, decision D10). `delete meta.dataset` is
  `meta.dataset = null`. It has no `draw` override, as upstream."
- **AGENTS.md, Tests**: add `controller_scatter_reference.mjs` to the list of controller
  generators (`test/port/controllers/*_reference.dart`). It needs no moment packages.
- **AGENTS.md, Tests** (optional): "The controller generators have no step that writes an
  option. A pin test of an option change takes its expected values from a probe on the pinned
  build, and the test comment names the probe (`controller.scatter_test.dart`, group
  `showLine`)."
- **porting-flow.md §5**, the phase 7 row: wave 3 adds `controller.scatter` (6 reference cases,
  10 pin cases, 6 themed twins; spec 4 of 6 pass, 2 `blocked: plugin.tooltip`).
- **porting-flow.md §3** (optional): a scatter line with `tension` draws Bézier curves with NaN
  control points upstream (no `updateControlPoints` call); the canvas skips them, as a Canvas 2D
  does.
- **performance.md §13.4**: the size of `controller_scatter_reference.dart` is 1 255 245 bytes
  (16 cases), below the 2.5 MB limit of TS §2. **§13.7**: the scatter loop has the 3-read form
  (D10), as the line loop; no measurement in this unit.
- **differences.md**, row `adapt-chart-registry-getter`: in the column of the Dart site, remove
  "(phase 7)" from `ScatterController.addElements`. In the test column, replace the sentence
  "In phase 7, a scatter chart with `showLine` gets a `LineElement` as its dataset element." with
  "`test/port/controllers/controller.scatter_test.dart`, group `interfaces` > `showLine`: the
  dataset element type is `registry.getElement('line')`, `LineElement.jsClass`." No new row. No
  new marker beyond the existing row.
- **status.yaml**:
  - the row of `src/controllers/controller.scatter.js`: ported; "`test/port/controllers/controller.scatter_test.dart`
    compares 16 charts with upstream, and 6 more with the light preset".
  - the row of `test/specs/controller.scatter.tests.js`: ported, 4 of 6 cases pass, 2 skip as
    `blocked: plugin.tooltip` (`{{skipped:...}}`); the group `auto` waits for the fixture runner.
  - a port-only row for `tool/reference/controller_scatter_reference.mjs` (and its data file)
    and for `test/port/controllers/controller.scatter_test.dart`, as the rows of wave 2.
  - `src/controllers/index.js` and `src/index.ts`: the scatter export (W3-int's own files).
  Then run `dart run melos run parity`.

## Open items

1. **The import of `controller.line.dart`.** Work plan §3, row U-scatter, says that
   `controller.scatter.dart` imports `controller.line.dart`. The upstream file does not import
   `controller.line.js`. The unit did not add the import. The phase lead or W3-int corrects the
   plan text.
2. **The registration lines.** W3-int removes `Chart.register([ScatterController.jsClass]);` from
   `main()` of `test/port/controllers/controller.scatter_test.dart` and
   `test/specs/controller.scatter_test.dart`, and the comment paragraph "Until the integration
   agent of wave 3 registers ..." in both files. In the spec file, the import of
   `controller.scatter.dart` then has no use: remove it. In the port test file, the import stays
   (the group `showLine` casts to `ScatterController`).
3. **The lift of the scatter records (L3).** The records with `blocked: controller.scatter` in
   `core.datasetController_test.dart` (2), `core.interaction_test.dart` (2) and
   `core.scale_test.dart` (5) need the registered scatter controller. They are in the row of L3,
   after W3-int.
4. **IV §7.4.** `test/port/index_test.dart` gets `scatter` in the key lists (W3-int).
5. **The proposed ADR texts (D12).** Chart.js ADR 0027 §8 and Open 4, and PD §5.3, still show the
   cross-pass local `prevIValue` for line and scatter. The scatter loop has the 3-read form of
   D10. W3-int aligns the texts. IV §4.1 rule 1 already names the `core.registry.dart` import.
6. **A generator step that writes an option.** `controller_chart_common.mjs` has no step for an
   option change. The pins of the `showLine` switch therefore come from a probe. If a later unit
   adds such a step, the probe cases can move into the generator. The probe and its output are in
   the scratch folder `<s>/probe/`; the expected values are also in the test file and in this
   report.

## Fixes

The fixes answer the two findings of `U-scatter-review.md`. Both have the verdict "confirmed".
`<f>` is `<s>/fix/`. The fixes changed only these files of the unit:

- `tool/reference/controller_scatter_reference.mjs`
- `test/port/controllers/controller_scatter_reference.dart` (generated again)
- `test/port/controllers/controller.scatter_test.dart` (one comment)
- `doc/phase7/review/wave3/U-scatter-report.md` (this section)

`lib/src/controllers/controller.scatter.dart` and `test/specs/controller.scatter_test.dart` did
not change.

### U-scatter-R1: no test pins the override `interaction.mode: 'point'` (fixed)

The fix is a new pin case of the generator, not a test with values from a probe. The generator
already has the steps `hover` and `mouseout` (`controller_chart_common.mjs`, `applyStep`), and the
observations record `active` of each element. Thus the expected active elements come from the
pinned build, and a rerun of the generator gives them again.

- The case `interfaces: the hover with the override interaction.mode 'point'` has the chart of
  the review probe: two datasets, the points 0 at `(1, 1)` and `(1.03, 1)` (1.3 px apart), `x`
  and `y` from 0 to 10. The steps are `['hover', 75, 436]` (the center of the point 0 of the
  dataset 0, from the new helper `centerOf` of the generator, as in
  `controller_bubble_reference.mjs`) and `['mouseout']`.
- The reference data after the `hover` step: `active` is `true` for the point 0 of the dataset 0
  and the point 0 of the dataset 1, and `false` for the other points. This agrees with
  `probe_hover.out` of the review (mode `point`: `[[0, 0], [1, 0]]`).
- The name starts with `interfaces:`. Thus the test "the reference has the 6 cases of Chart.js
  ADR 0030 first" accepts it, and the themed run does not run it.
- The generator header names the override in the list of the pin cases.

Mutation evidence: `<f>/mutate_probe_test.dart` (a copy of the review probe
`interaction_probe_test.dart`) with `MUTATE=1` removes `interaction` from
`ScatterController.overrides` before the registration and runs both test files of the unit. Only
two tests fail: the new case `interfaces: the hover with the override interaction.mode 'point'`
(the element `active` differs) and the hover test of the probe (`[[0.0, 0.0]]`). Output:
`<f>/mutate.log`.

### U-scatter-R2: the probe of the group `showLine` is only in a scratch folder (fixed)

The fix records the probe source and its output in this section, below. The comment of the group
`showLine` in `test/port/controllers/controller.scatter_test.dart` now names this report, section
"Fixes", finding U-scatter-R2. The fix does not add a generator step that writes an option: that
step is a change of `controller_chart_common.mjs`, which is not a file of this unit (open item 6
stays open for a later unit or W3-int).

Run, from `packages/flutter_chartjs`, with the probe saved as `probe_showline.mjs`:

```sh
CHARTJS_DIST=<build at the pin>/dist/chart.js \
  /usr/bin/arch -x86_64 <node-v24.12.0-darwin-x64>/bin/node probe_showline.mjs
```

`probe_showline.mjs`:

```js
// Probe: the showLine switch of controller.scatter.js:71-95 (issue #11333)
// on the pinned build. Run from packages/flutter_chartjs.
import {pathToFileURL} from 'node:url';
const common = await import(pathToFileURL(process.cwd() + '/tool/reference/controller_chart_common.mjs'));
const C = await common.loadChartJs();
common.registerPhase7(C);
const out = [];
const log = (k, v) => out.push(`${k}: ${JSON.stringify(v)}`);
function state(tag, chart) {
  const meta = chart.getDatasetMeta(0);
  const ctrl = meta.controller;
  log(tag + ' dataset is LineElement', meta.dataset instanceof C.LineElement);
  log(tag + ' dataset undefined', meta.dataset === undefined);
  log(tag + ' "dataset" in meta', 'dataset' in meta);
  log(tag + ' datasetElementType', ctrl.datasetElementType === C.LineElement ? 'LineElement' : ctrl.datasetElementType);
  log(tag + ' points', meta.dataset ? meta.dataset.points.length : null);
  log(tag + ' points same', meta.dataset ? meta.dataset.points.every((p, i) => p === meta.data[i]) : null);
  log(tag + ' maxOverflow', ctrl.getMaxOverflow());
  log(tag + ' clip', meta._clip);
}
const data = () => [{x: 1, y: 2}, {x: 2, y: 4}, {x: 3, y: 1}];
// 1. dataset showLine switched on, then off, then on.
{
  const chart = common.makeChart({type: 'scatter', data: {datasets: [{data: data(), borderWidth: 4}]}});
  state('A0', chart);
  chart.data.datasets[0].showLine = true; chart.update();
  state('A1', chart);
  const first = chart.getDatasetMeta(0).dataset;
  chart.data.datasets[0].showLine = false; chart.update();
  state('A2', chart);
  chart.data.datasets[0].showLine = true; chart.update();
  state('A3', chart);
  log('A3 new element', chart.getDatasetMeta(0).dataset !== first);
  chart.destroy();
}
// 2. root options showLine switched on.
{
  const chart = common.makeChart({type: 'scatter', data: {datasets: [{data: data()}]}});
  chart.options.showLine = true; chart.update();
  state('B1', chart);
  chart.destroy();
}
// 3. showLine at creation, then off.
{
  const chart = common.makeChart({type: 'scatter', data: {datasets: [{data: data(), showLine: true}]}});
  state('C0', chart);
  chart.data.datasets[0].showLine = false; chart.update();
  state('C1', chart);
  chart.destroy();
}
console.log(out.join('\n'));
```

`probe_showline.out` (x64 Node.js v24.12.0, the build at the pin `7169e651`):

```text
A0 dataset is LineElement: false
A0 dataset undefined: false
A0 "dataset" in meta: true
A0 datasetElementType: false
A0 points: null
A0 points same: null
A0 maxOverflow: 8
A0 clip: {"top":8,"right":8,"bottom":8,"left":8,"disabled":false}
A1 dataset is LineElement: true
A1 dataset undefined: false
A1 "dataset" in meta: true
A1 datasetElementType: "LineElement"
A1 points: 3
A1 points same: true
A1 maxOverflow: 8
A1 clip: {"top":8,"right":8,"bottom":8,"left":8,"disabled":false}
A2 dataset is LineElement: false
A2 dataset undefined: true
A2 "dataset" in meta: false
A2 datasetElementType: false
A2 points: null
A2 points same: null
A2 maxOverflow: 8
A2 clip: {"top":8,"right":8,"bottom":8,"left":8,"disabled":false}
A3 dataset is LineElement: true
A3 dataset undefined: false
A3 "dataset" in meta: true
A3 datasetElementType: "LineElement"
A3 points: 3
A3 points same: true
A3 maxOverflow: 8
A3 clip: {"top":8,"right":8,"bottom":8,"left":8,"disabled":false}
A3 new element: true
B1 dataset is LineElement: true
B1 dataset undefined: false
B1 "dataset" in meta: true
B1 datasetElementType: "LineElement"
B1 points: 3
B1 points same: true
B1 maxOverflow: 5
B1 clip: {"top":5,"right":5,"bottom":5,"left":5,"disabled":false}
C0 dataset is LineElement: true
C0 dataset undefined: false
C0 "dataset" in meta: true
C0 datasetElementType: "LineElement"
C0 points: 3
C0 points same: true
C0 maxOverflow: 5
C0 clip: {"top":5,"right":5,"bottom":5,"left":5,"disabled":false}
C1 dataset is LineElement: false
C1 dataset undefined: true
C1 "dataset" in meta: false
C1 datasetElementType: false
C1 points: null
C1 points same: null
C1 maxOverflow: 5
C1 clip: {"top":5,"right":5,"bottom":5,"left":5,"disabled":false}
```

The test values agree with this output: the dataset element and `datasetElementType` of A0-A3,
B1, C0 and C1, the new element of A3, and `getMaxOverflow()` 8 (A) and 5 (B, C). JS `null` (A0)
and `undefined` (A2, C1) of `meta.dataset` are Dart `null` in the port (see "Checks with no
finding" of the review).

### Checks of the fixes

| Command | Result |
|---|---|
| the generator, 2 runs (x64 Node.js v24.12.0, the build at the pin) | both runs: 17 cases, 80 widths, 1 324 744 bytes, SHA-256 `56ae493396b0689454549d5efe23104b177ceff6ebe8b9cd0a0b0206bfd8c495`: byte-identical (`cmp`). The diff against the data before the fix: the case count in the header, and the new case only |
| `flutter test test/port/controllers/controller.scatter_test.dart test/specs/controller.scatter_test.dart` | +41 ~2, all passed (37 port tests, 4 spec cases; `<f>/run_fix.log`) |
| `MUTATE=1 flutter test <f>/mutate_probe_test.dart` | the new case and the probe hover test fail, all other tests pass (`<f>/mutate.log`) |
| `dart format --output=none --set-exit-if-changed` on the 4 Dart files | 0 changed |
| `dart analyze --fatal-infos` on the test file and the data file | No issues found |
| `dart run melos run check:headers` | passed, 366 files, 0 errors, 0 warnings |

Updates to the notes for W3-int: the reference now has 17 cases (11 pin cases), 1 324 744 bytes,
below the 2.5 MB limit of TS §2 (performance.md §13.4). The status text of
`src/controllers/controller.scatter.js` gives "17 charts with upstream, and 6 more with the light
preset". No `flutter_tester` process of this fix is left. The process 67820 belongs to another
session. This fix did not start it and did not stop it.
