# Wave 2, unit U-radar: report

## Status

Done. The unit made the files of its row in the work plan (§2, row U-radar). Each check of the row
passes. The unit made no commit and ran no git command that changes the index or the tree.

All paths are relative to `packages/flutter_chartjs/`. `<scratch>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad`.

## Files

| File | Change |
|---|---|
| `lib/src/controllers/controller.radar.dart` | New. The port of `src/controllers/controller.radar.js` at the pin `7169e651`, line by line. |
| `tool/reference/controller_radar_reference.mjs` | New. The generator: the 8 cases of Chart.js ADR 0030 §7 (row `radar`), 4 `parsed:` cases and 4 `interfaces:` cases. |
| `test/port/controllers/controller_radar_reference.dart` | New, generated. 16 cases, 65 widths, 1,029,531 bytes (one file: below 2.5 MB). |
| `test/port/controllers/controller.radar_test.dart` | New. The reference tests, the themed twins and the pin tests. |
| `test/specs/controller.radar_test.dart` | New. The spec port of `test/specs/controller.radar.tests.js`. |
| `doc/phase7/review/wave2/U-radar-report.md` | New. This report. |

The unit did not change a shared file.

## The lib file

- `RadarController extends DatasetController`, with the statics `id`, `defaults` and
  `overrides` in the upstream order, and `jsClass` (Chart.js ADR 0020 §3).
- `getLabelAndValue` (`:39`): the label is `jsGetIndex(vScale!.getLabels(), index)`, without
  `'' +` and without `|| ''` (IV §4.6, ADR 0028 §2). The value is `jsToString` of
  `getLabelForValue(jsGetKey(parsed, vScale.axis))` (PD §5.7).
- `parseObjectData` (`:49`): `jsCall(parseObjectDataRadialScale, [meta, data, start, count],
  thisArg: this)! as List<AnyObject>`.
- `update` (`:53`): `final points = meta.data;` for `meta.data || []`. The write `line.points =
  points` is `(line! as types.PropertyAccess)['points'] = points` (IV §4.2). The null check
  throws a `TypeError` for a meta without a dataset element, as the JS write into `undefined`
  does. `options.borderWidth = 0` writes `0.0` into the resolved line options. The properties
  keep the upstream key order (`_loop`, `_fullLoop`, `options`).
- `updateElements` (`:81`): `final scale = cachedMeta.rScale;` stays a `types.Scale?`. The cast
  `scale! as types.RadialLinearScale` stands in the loop after `resolveDataElementOptions`
  (`:87`), at the upstream call of `getPointPositionForValue` (`:88`, IV §4.6). The read
  `this.getParsed(i).r` is `jsGetKey(getParsed(i), 'r')`. The properties keep the upstream key
  order (`x`, `y`, `angle`, `skip`, `options`).
- The option resolution for each point stays literal (ADR 0027 §8, the step 7 list). The file has
  no `final` local of a parsed read, thus the one-read rule has no local to check.
- No `DIVERGES` marker. No new `differences.md` row.
- Checklists: PD §5.8: no `_parsedValue`, no `jsGet(parsed` or `jsGet(item`, no `as Map` or `as
  AnyObject`. IV §4.8: the imports are `core.datasetController.dart`, `helpers.config.dart`, the
  runtime of `lib/src/js/` and `lib/src/types/`. The casts are `types.PropertyAccess`,
  `types.RadialLinearScale` and `List<AnyObject>` (see open item 2). No cast in `update` for a
  member that upstream reads in the draw.

## Tests

### `test/port/controllers/controller.radar_test.dart` (38 tests, all pass)

- `testReferenceOrigin`, `testReferenceWidths`, and the test "the reference has the 8 cases of
  Chart.js ADR 0030 first" (it checks the first name, that the first 8 names have no prefix, and
  that each later name has a prefix; the order defect F1 of the U-bar-tests review does not
  occur).
- The 16 reference cases, unthemed:
  - The 8 cases of ADR 0030 §7: `default` (with `scaleOptions: true` and the steps `update`,
    `setActive`, `update none`, `update resize`, `push`, `splice`, `reset`, `update`; the
    `_fullLoop` value changes from false to true at the push), `spanGaps` (`true`, `2` and
    absent), `tension`, `a hidden dataset` (with `setDatasetVisibility`), `null items`,
    `showLine false`, `scale r options` (with `scaleOptions: true`) and `the step hover` (a hover
    at the center of point 2 of dataset 1, then `mouseout`).
  - `parsed: parsing false with numbers` (PD §7.3: x and y NaN, `skip` true).
  - `parsed: parsing false with a null item` (PD §7.3: `TypeError` at `initial`).
  - `parsed: a label index past the end` (PD §7.3: the label `undefined`).
  - `parsed: object data with the default key and a parsing key` (the path of
    `_parseObjectDataRadialScale` with `parsing: {key: 'v'}`, a string value and an absent key).
  - `interfaces: the labels of getLabelAndValue, set 1` and `set 2` (IV §7.3, row `radar`).
  - `interfaces: an r scale that is not radial, no data` (IV §7.3: no throw upstream; the case
    confirms it first).
  - `interfaces: an r scale that is not radial, with data` (`TypeError` at `initial`).
- The probe `pointAngles` (key `extra`) in `default` and `scale r options`: the `angle` of each
  point. The observations of ADR 0030 §4 have no `angle`, and the filler plugin of phase 8 reads
  it (`plugin.filler/simpleArc.js:20`).
- The group `theming.md §8 test 3: the light preset`: the 8 cases with the light preset, and "the
  light preset leaves no stale scale key".
- The group `parsed data` (relations, no generated value): parsing false with numbers gives NaN
  points that skip; a null item throws a `TypeError`; the label past the end is `undefined`.
- The group `interfaces`: `line.points` after `chart.update()`, after a push and after a splice
  (IV §7.3: same length, `identical` elements in the order of `meta.data`); the raw labels
  (`identical` List, `5`, `0`, Dart `null`, `'e'`, `undefined`); an r scale that is not radial
  and no data (`update` does not throw); with data (a `TypeError`).

Mutation probes (each restored): `_fullLoop` constant true fails `default`; `angle` 0 fails
`default` (after the probe `pointAngles` came in; before it, no case failed); `skip` constant
false fails `null items`; `borderWidth` 1 for `showLine: false` fails `showLine false`.

A probe test (`<scratch>/wave2/U-radar/throw_site_test.dart`) shows that the `TypeError` of the
non-radial case with data comes from the cast in `RadarController.updateElements`
(`controller.radar.dart:195`), the site of the upstream throw (`:88`).

### `test/specs/controller.radar_test.dart` (13 cases: 11 pass, 2 skip)

The names are the `describe` and `it` names, character for character (`Should be constructed`
and `Should create arc elements ...` start with a capital S, as upstream). The verdicts are those
of `classification/all.json`:

- 11 `phase7` cases with bodies: `should be registered as dataset controller` (a `test`), `Should
  be constructed`, `Should create arc elements for each data item during initialization`, `should
  draw all elements` and `... with object notation and default key` (`spyOnDataset` and
  `spyOnElementDraw`), the 3 cases of the group `Interactions` (a local `beforeEach()`; `merge` of
  `helpers.core.dart` into the dataset and into the resolver `chart.options.elements.point`),
  `should allow pointBorderWidth to be set to 0`, `should use the pointRadius setting over the
  radius setting`, `should return id for value scale`.
- `should update elements` (`:103`): `skip: 'blocked: plugin.filler'`.
- `should not override tooltip title and label callbacks` (`:410`): `skip: 'blocked:
  plugin.tooltip'`.
- The `auto` group is a comment at its upstream position (F-int adds the call).

## Checks

| Command (from the repository root or `packages/flutter_chartjs`) | Result |
|---|---|
| `dart analyze --fatal-infos lib/src/controllers/controller.radar.dart test/port/controllers/controller.radar_test.dart test/specs/controller.radar_test.dart` | No issues |
| `dart format` on the 3 Dart files that the unit wrote | 0 changed |
| `flutter test test/port/controllers/controller.radar_test.dart` | +38, all passed |
| `flutter test test/specs/controller.radar_test.dart` | +11 ~2, all passed |
| `dart run melos run test:cases` | exit 0; `controller.radar.tests.js`: 13 cases, 11 passed, 0 failed, 2 skipped, 0 missing |
| `dart run melos run check:headers`, `check:lib-imports`, `check:js-semantics` | exit 0 each |
| `/usr/bin/arch -x86_64 <scratch>/env/node-v24.12.0-darwin-x64/bin/node tool/reference/controller_radar_reference.mjs <scratch>/env/chartjs-build/dist/chart.js`, 3 runs | SHA-256 `7ee4730a338ded69b7419a0f04b11f2d411f86ddfa379decb65fef7d1b3e7ead` each time (byte-identical) |
| The same generator with the arm64 Node.js | stops: "The reference is V8 on x64; this Node.js is arm64." |

The unit did not run `analyze` on `apps/chartjs_gallery`: it changed no interface. No
`flutter_tester` process of this unit is left (the processes 67820 and the children of 82844
belong to other sessions or units).

## Doc notes for W2-int

- Registration: remove `Chart.register([RadarController.jsClass]);` from the start of `main()` in
  `test/port/controllers/controller.radar_test.dart` and in `test/specs/controller.radar_test.dart`
  when `lib/src/controllers/index.dart` registers the wave. Also remove the sentence "main()
  registers the radar controller until ..." from the comment of each file. Then rerun both files.
- `AGENTS.md`:
  - Layout, `lib/src/controllers/`: "`controller.radar.dart` (`RadarController`). The write
    `line.points = points` is a write by name through `types.PropertyAccess`. The scale cast to
    `types.RadialLinearScale` stands in the loop of `updateElements`, at `controller.radar.js:88`.
    The label of `getLabelAndValue` is the raw label (Chart.js ADR 0028)."
  - Tests, the generator list: add `tool/reference/controller_radar_reference.mjs`. "Without the
    filler plugin, a radar line with a tension strokes NaN control points: the generator converts
    the arguments of `Path2D.bezierCurveTo` and `quadraticCurveTo` with `ToNumber`, as a browser
    does (see open item 1)."
- `doc/porting-flow.md` §5, the phase 7 row: "`controller.radar`: ported; 8 reference cases and 8
  themed twins, 8 pin cases; spec 11/13 pass, 1 `blocked: plugin.filler`, 1 `blocked:
  plugin.tooltip`."
- `doc/performance.md` §13.7 (open list, step 7): the radar `updateElements` casts the scale once
  for each point (IV §4.6), and `parseObjectData` calls the helper through `jsCall` with 5
  arguments (`Function.apply` on the VM, once for each parse call). The unit measured neither.
- `doc/differences.md`: no new row. Row `adapt-line-points-elements`, column "Pinning test": add
  `test/port/controllers/controller.radar_test.dart`, group `interfaces` › `line.points`.
- `doc/status.yaml`:
  - New row `src/controllers/controller.radar.js`: ported. Text: "`RadarController`. The line
    points are a write by name; the scale cast stands at `getPointPositionForValue` (Chart.js ADR
    0028). `test/port/controllers/controller.radar_test.dart` compares 8 charts with upstream,
    and 8 more with the light preset, and 8 pin cases (`parsed:` and `interfaces:`)."
  - New row `test/specs/controller.radar.tests.js`: ported. Text: "11/13 cases pass on the VM; 2
    cases skipped: 1 `blocked: plugin.filler` (only the filler computes the control points of a
    radar line) and 1 `blocked: plugin.tooltip`. The fixture group `auto` waits for the fixture
    runner (Chart.js ADR 0029)." Use the `{{skipped:...}}` placeholders of tool 6.
  - `src/controllers/index.js`: add `RadarController` to the partial list.
  - Port-only rows (if the form of W1-int asks for them): `tool/reference/controller_radar_reference.mjs`,
    `test/port/controllers/controller.radar_test.dart`,
    `test/port/controllers/controller_radar_reference.dart`.
  - Then run `dart run melos run parity`.
- `doc/upstream-ledger.md`: no change. The radar file has no ledger row at the pin.
- L2 (work plan §3) lifts the `blocked: controller.radar` skips of the other spec files (16 in
  `scale.radialLinear_test.dart`, 1 in `core.datasetController_test.dart`).

## Open items

1. The recording `Path2D` of `tool/reference/controller_chart_common.mjs` (and `dartArgs` of
   `tool/reference/scale_chart_common.mjs` for the context calls `bezierCurveTo` and
   `quadraticCurveTo`) records the raw arguments. A browser converts them with `ToNumber` (WebIDL
   `unrestricted double`), and the Dart canvas records NaN for `undefined`. The `tension` case
   gave `null` in place of NaN and failed for this reason only. Because the shared files are not
   in the row of this unit, `controller_radar_reference.mjs` converts the arguments of the two
   commands at the record (a documented local patch). The owner of the shared files (W2-int, or
   the phase lead) moves the conversion into the shared recorder and `dartArgs`, removes the
   local patch, and confirms that each controller and scale generator then gives the same SHA-256.
2. The cast `as List<AnyObject>` of the result of `jsCall` in `parseObjectData` is not in the
   allowed list of IV §4.8 ("Each `as` names a `types.` interface or `DoughnutController`"). The
   closure of `parseObjectDataRadialScale` returns `List<Map<String, Object?>>`, so the cast
   cannot throw. `controller.polarArea.dart` needs the same form (`controller.polarArea.js:110`).
   W2-int adds the cast to the allowed list with this reason, as W1-int did for the two List casts
   of the bar (U-bar-lib review, F4).
3. The point observation of ADR 0030 §4 has no `angle`. This unit pins it with the probe
   `pointAngles`. The phase lead can add `angle` to the point properties of the shared harness
   (both sides) later. Then the probe is not necessary.
4. The relation test "an r scale that is not radial with data" expects only a `TypeError`. The
   throw site (the cast at `:88`) is shown by the probe test of this report, not by a kept test.

## Fixes

The review `U-radar-review.md` has 2 findings. Both have the verdict "confirmed".

### F1: wrong line citation in `controller_radar_reference.mjs`

Fixed. The comment of the probe `pointAngles` now cites `(:96)`, the line
`angle: pointPosition.angle,` of `controller.radar.js` at the pin. No other file of the unit cites
`:95`. The comment is not in the generated data. The generator gives the same SHA-256 as before
(see the checks below).

### F2: the reset position of a new point is NaN where upstream gives `undefined`

Not fixed in this unit. The finding is correct, but its cause is outside the row of this unit:

- `RadialLinearScale.xCenter` and `yCenter` are `double` (`lib/src/types/index.dart:677`,
  Chart.js ADR 0028 §1). `scale.radialLinear.dart:831` and `:836` start them at NaN for the JS
  `undefined` state (phase 6). Thus the controller cannot see the `undefined` state.
- `controller.radar.dart:201-202` is a literal port of `controller.radar.js:90-91`. The element
  write by name keeps NaN as a number. `Animation` then takes NaN as `from`, where upstream skips
  `undefined` (`core.animation.js:32`).
- A local change in the controller (NaN to the `undefined` sentinel at the reset write) is
  possible, because `Element['x'] = undefined` restores the `undefined` state. This unit does not
  do it: it puts the meaning of a scale value into one controller, and
  `controller.polarArea.dart:361` (another unit) reads `xCenter` in the same way and keeps the
  defect. The fix must go into the shared files, so that both controllers get it.

Escalation to W2-int or the phase lead. Select one of the two fixes of the review:

1. Make `xCenter` and `yCenter` nullable (the `undefined` state) in `types.RadialLinearScale` and
   `scale.radialLinear.dart`. Then `controller.radar.dart:201-202` and `:208` (`skip`) and
   `controller.polarArea.dart:361` change to the nullable form. Add a pin case: an existing radar
   chart gets a new radial scale and a pushed item in one animated `update()`. The reviewer's
   probes (`<scratch>/wave2/U-radar-review/xcenter_probe.mjs` and `xcenter_probe_test.dart`) give
   the expected values.
2. Add a `DIVERGES` row to `doc/differences.md`, a marker at `controller.radar.dart:201` and at
   `controller.polarArea.dart:361`, and a pin test of the NaN result.

### Checks after the fixes

| Command (from `packages/flutter_chartjs`) | Result |
|---|---|
| `dart analyze --fatal-infos lib/src/controllers/controller.radar.dart test/port/controllers/controller.radar_test.dart test/specs/controller.radar_test.dart` | No issues |
| `flutter test test/port/controllers/controller.radar_test.dart test/specs/controller.radar_test.dart` | +49 ~2, all passed |
| `/usr/bin/arch -x86_64 <scratch>/env/node-v24.12.0-darwin-x64/bin/node tool/reference/controller_radar_reference.mjs <scratch>/env/chartjs-build/dist/chart.js` | SHA-256 `7ee4730a338ded69b7419a0f04b11f2d411f86ddfa379decb65fef7d1b3e7ead`, the same as before the fix (byte-identical) |

No `flutter_tester` process of this fixer is left (the process 67820 belongs to another session).
