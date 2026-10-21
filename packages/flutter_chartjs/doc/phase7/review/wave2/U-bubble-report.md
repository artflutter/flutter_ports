# Wave 2, unit U-bubble: report

## Status

Done, with 2 open items outside the files of this unit. The port of `controller.bubble.js`, the
generator and its data, the port-only test file and the spec port are complete. All targeted
checks pass.

The bubble port gives the upstream value of each observation of each reference case. 4 of the 16
reference cases (and 1 of the 7 themed twins) are placeholders with a skip reason. These cases
have a string radius. In them, two parts outside this unit differ from upstream (open items 1 and
2): the hit test of `element.point.dart` and the `arc` arguments of the JS call record. A scratch
probe compares these 4 cases without the hit items and with the WebIDL `ToNumber` of the `arc`
arguments: all 4 pass.

All paths are relative to `packages/flutter_chartjs/`. `<scratch>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/U-bubble/`.

## Files that U-bubble changed

| File | Change |
|---|---|
| `lib/src/controllers/controller.bubble.dart` (new) | The port of `src/controllers/controller.bubble.js` at the pin `7169e651`, line by line. `BubbleController`, `BubbleController.jsClass` (statics `id`, `defaults`, `overrides`), `initialize`, the three `parse*Data` overrides, `getMaxOverflow`, `getLabelAndValue`, `update`, `updateElements` and `resolveDataElementOptions`. One `DIVERGES(chartjs): adapt-typed-element-options` marker at the copy of `controller.bubble.js:157`. |
| `tool/reference/controller_bubble_reference.mjs` (new) | The generator: the 7 cases of Chart.js ADR 0030 §7, 7 `parsed:` cases and 2 `interfaces:` cases. |
| `test/port/controllers/controller_bubble_reference.dart` (new, generated) | 16 cases, 62 widths, 769,922 bytes. SHA-256 `77d28d89cdba8aa3f18edec31745a908b2882b987c62181fcf3ab6282777e0b4`. |
| `test/port/controllers/controller.bubble_test.dart` (new) | The reference tests, the themed twins, the groups `parsed data` and `interfaces`. `main()` starts with `Chart.register([BubbleController.jsClass])`. |
| `test/specs/controller.bubble_test.dart` (new) | The spec port: 11 cases, 10 `phase7` cases with bodies, 1 `blocked: plugin.tooltip` placeholder. `main()` starts with `Chart.register([BubbleController.jsClass])`. |
| `doc/phase7/review/wave2/U-bubble-report.md` (new) | This report. |

No other file changed. No shared doc changed.

## The lib port

- The forms of PD §5.4: `jsGet(resolveDataElementOptions(i + start), 'radius')` (`:49`),
  `valueOrDefault(jsGet(item, '2'), ...)` (`:62`), the `&&` chain of `item && item.r && +item.r`
  (`:75`), `jsGetKey(parsed, 'x')`, `'y'` and `'_custom'` in `getLabelAndValue` (`:101-103`),
  `jsGetKey(parsed, iAxis)` and `vAxis` in `updateElements` (`:129-130`), and
  `values['radius'] = jsAdd(jsGet(values, 'radius'), valueOrDefault(jsTruthy(parsed) ?
  jsGetKey(parsed, '_custom') : parsed, radius))` (`:165`).
- The copy of `:157` is `copyOptions(values)..[r'$shared'] = false` (Chart.js ADR 0021 §3, the
  table row of the bubble).
- `getMaxOverflow` casts each data element to `types.PointElement` at `size` (Chart.js ADR 0028
  §4, `controller.bubble.js:88`). `max > 0 && max` gives the number or `false`.
- `getLabelAndValue` returns `({Object? label, String value})`. The label is `labels[index] || ''`
  without `jsToString` (IV §4.1 item 6). The value joins the `jsToString` of `x`, `y` and `r`.
- `!reset && this.getParsed(i)` is `reset ? false : getParsed(i)`. `properties.options.radius = 0`
  writes into the shared options or into the result of the override, as upstream.
- The option copy for each item stays literal (ADR 0027 §8, the step 7 list).
- Imports: `core.datasetController.dart`, `element_options.dart` (`copyOptions`),
  `helpers.core.dart`, the JS runtime, `types/basic.dart` and `types/index.dart`. No import of
  `core.controller.dart`, `core.scale.dart`, `core.element.dart` or an element module.

## Tests that U-bubble added

`test/port/controllers/controller.bubble_test.dart` (`@TestOn('vm')`):

- `testReferenceOrigin` and `testReferenceWidths`.
- "the reference has the 7 cases of Chart.js ADR 0030 first".
- "each blocked case is a case of the reference".
- The reference cases (unthemed): `default` (`r` from the data, with `scaleOptions` and the steps
  `update`, `setActive`, `update none`, `push`, `splice`, `reset`, `update`), `a named radius
  function` (`fn:radiusOfIndex`, object data and primitive data), `hoverRadius with the step
  hover` (2 `hover` steps and a `mouseout`), `custom parsing keys` (with `indexAxis: 'y'`),
  `[x, y, r] arrays` (placeholder), `getMaxOverflow` (the result `false` for radius 0 and border
  0), `clip` (`false`, a number, an object); `parsed: parsing false, [x, y, r] arrays`,
  `parsed: parsing false, a null item` (`TypeError` at `initial`), `parsed: object data with a
  null item` (`TypeError` at `initial`), `parsed: the r values of object data` (`'5'`, `0`, `null`,
  `true`, `'abc'`, `-2`, absent, `'0'`), `parsed: radius '4' with primitive data` (placeholder),
  `parsed: radius '4' with object data` (placeholder), `parsed: parsing false, object items with
  _custom` (placeholder); `interfaces: the labels of getLabelAndValue, set 1` and `set 2`.
- The group `theming.md §8 test 3: the light preset`: the 7 cases (6 run, `[x, y, r] arrays` is a
  placeholder) and "the light preset leaves no stale scale key".
- The group `parsed data`: "parsing false and [x, y, r] arrays give x and y NaN, skip true and
  radius 3"; "parsing false and a null item throw a TypeError"; "r '7' of an array gives the
  radius '07' (the + of strings)".
- The group `interfaces`: "getLabelAndValue gives the label value, or an empty string for a falsy
  label" (label 0 is the identical `List`; `5` and `7` are numbers; `0`, `''`, `null`,
  `undefined` and past the end give `''`; `'d'` and `'e'`).

`test/specs/controller.bubble_test.dart`: the 11 `it` cases of `controller.bubble.tests.js` in the
upstream order with the exact names. The `auto` group is a comment (F-int adds the call). The
`beforeEach` of `Interactions` is a local `beforeEach()`.

## Checks

| Command (from `packages/flutter_chartjs` unless stated) | Result |
|---|---|
| `dart analyze --fatal-infos lib/src/controllers/controller.bubble.dart test/port/controllers/controller.bubble_test.dart test/port/controllers/controller_bubble_reference.dart test/specs/controller.bubble_test.dart` | No issues |
| `dart format --set-exit-if-changed` on the same 4 files | 0 changed |
| `flutter test test/port/controllers/controller.bubble_test.dart test/specs/controller.bubble_test.dart` | +37 ~6, all passed (port file: +27 ~5; spec file: +10 ~1) |
| `dart run melos run test:cases` (repository root) | passed, 40 files, 0 errors, 0 warnings. `controller.bubble.tests.js`: 11 cases, 10 passed, 0 failed, 1 skipped, 0 missing |
| `dart run melos run check:lib-imports`, `check:headers`, `check:js-semantics` (repository root) | passed: 318, 355 and 125 files, 0 errors, 0 warnings |
| The generator, 3 runs (`/usr/bin/arch -x86_64 <node-v24.12.0-darwin-x64>/bin/node tool/reference/controller_bubble_reference.mjs <build>/dist/chart.js`, and once with `CHARTJS_DIST`) | the same SHA-256 each time: `77d28d89cdba8aa3f18edec31745a908b2882b987c62181fcf3ab6282777e0b4` |
| `flutter test <scratch>/nohits_probe_test.dart` (with a copy of `test/flutter_test_config.dart` in `<scratch>`) | +4: the 4 placeholder cases give the upstream observations except the hit items, and the upstream draw calls with the `ToNumber` of the `arc` arguments |
| `<scratch>/probe_string_radius.mjs` in the x64 Node.js | `<scratch>/probe_string_radius.out`: a bubble with `radius: '7'` has the option radius `'007'`, `getRange()` `'0071'`, and `inRange` at 10 px is true; with `radius: 7`, `getRange()` 8 and `inRange` false |

The full gate did not run (W2-int runs it). No `flutter_tester` process of U-bubble is left. The
process 67820 belongs to another session; U-bubble did not start it and did not stop it.

## Doc notes for W2-int

- **`lib/src/controllers/index.dart`, `lib/src/index.dart`, `test/port/index_test.dart`:** add
  `BubbleController` (`index.js:2`, `export ... show BubbleController`; `'BubbleController':
  BubbleController.jsClass`). Remove the two lines `Chart.register([BubbleController.jsClass]);` in
  `test/port/controllers/controller.bubble_test.dart` and `test/specs/controller.bubble_test.dart`,
  and change their file comments: `flutter_test_config.dart` registers the controller. The spec
  file keeps the import of `controller.bubble.dart` only if a case uses it (no case does now; the
  import serves only the `Chart.register` line). The port test file keeps it for the same reason
  only: remove the import with the line.
- **AGENTS.md, Layout, `lib/src/controllers/`:** "`controller.bubble.dart` (`BubbleController`):
  the parsed radius goes to `_custom`; `resolveDataElementOptions` copies the options with
  `copyOptions(values)..[r'$shared'] = false` (Chart.js ADR 0021 §3) and adds the radius with
  `jsAdd` (a string radius joins, as upstream). `getMaxOverflow` casts each data element to
  `types.PointElement` at `size`."
- **AGENTS.md, Tests:** add `controller_bubble_reference.dart` to the list of the controller
  generators (no moment packages, no `TZ`). The bubble test file runs 4 of its reference cases
  (and 1 themed twin) as placeholders until open items 1 and 2 are closed.
- **porting-flow.md §5, phase 7 row:** `controller.bubble` ported in wave 2: 7 reference cases
  of Chart.js ADR 0030 §7 with themed twins, 7 `parsed:` and 2 `interfaces:` cases; spec 10 of 11
  (1 `blocked: plugin.tooltip`).
- **performance.md §13.7 (open list):** no new figure. The option copy for each bubble item
  (`bubble.js:46-78`, `:151-168`) stays in the step 7 list of ADR 0027 §8.
- **differences.md, `adapt-typed-element-options`:** the code column says "The hunk of phase 7
  comes with its module: `lib/src/controllers/controller.bubble.dart`
  `BubbleController.resolveDataElementOptions`". The hunk is there now: change the text to the
  present ("`lib/src/controllers/controller.bubble.dart` `BubbleController.resolveDataElementOptions`").
  The marker reason is "a copy of the class." (the text of DC "the copy keeps the class." does not
  fit in 80 characters at this indentation). Tests column: add
  `test/port/controllers/controller.bubble_test.dart` (the reference cases with the active and
  default options of each point). No new row.
- **differences.md, open item 1:** if the phase lead accepts the `element.point.dart` behavior
  instead of a fix, a row is necessary (the hit element is protected behavior, Chart.js ADR 0009).
- **status.yaml:**
  - New row `src/controllers/controller.bubble.js`: ported. Text: "`BubbleController`, with the
    forms of Chart.js ADRs 0027 and 0028. `test/port/controllers/controller.bubble_test.dart`
    compares 16 charts with upstream (12 run, 4 wait for open items 1 and 2 of the U-bubble
    report), and 7 more with the light preset (6 run, 1 waits)."
  - New row `test/specs/controller.bubble.tests.js`: ported, with `{{skipped:blocked:
    plugin.tooltip}}`.
  - `src/controllers/index.js`: partial, `BarController` and `BubbleController` (with the other
    controllers of wave 2).
  - New port-only rows: `test/port/controllers/controller.bubble_test.dart`,
    `test/port/controllers/controller_bubble_reference.dart` (generated) and
    `tool/reference/controller_bubble_reference.mjs`.
  - Then `dart run melos run parity`.
- **upstream-ledger.md:** no change.

## Open items

1. **`element.point.dart` (not a file of this unit): the `+` of a string radius.**
   `PointElement.inRange` (`element.point.ts:62-66`), `_inRange` of `inXRange` and `inYRange`
   (`:11-16`) and `getRange` (`:102-106`) apply `jsToNumber` to `radius` and `hitRadius` before
   the `+`. Upstream joins the strings: `options.hitRadius + options.radius` with `1` and `'07'`
   is `'107'`, and `Math.pow('107', 2)` is 11449. Thus the hit element differs (Chart.js ADR 0009
   protects it). A bubble makes a string radius from a string `item[2]`, a string `_custom` with
   `parsing: false`, or a string `radius` option: `values.radius += ...` joins (`bubble.js:165`).
   A string `radius` option of a line or scatter point gives the same difference without the
   bubble. Proposed fix: `jsAdd` at the three sites (then `jsToNumber` of the sum for the
   compare). The owner of `element.point.dart` makes the fix; then remove the 4 names from
   `_blocked` in `controller.bubble_test.dart` (after item 2).
2. **`tool/reference/scale_chart_common.mjs` (a U0 file): the `arc` arguments.** `dartArgs`
   records the `arc` arguments as they are. The canvas applies the WebIDL `ToNumber` to `x`, `y`,
   `radius`, `startAngle` and `endAngle` (`unrestricted double`), and the Dart `arc` gets a
   `double`. Thus the reference holds `'07'` where the port records 7. Proposed fix: `Number` for
   the first five `arc` arguments, as `NUMBER_METHODS` does. Then run each controller generator
   and each phase 6 generator again (the phase 6 data should not change: their radii are
   numbers), and remove the placeholders of item 1.
3. The checklist grep of PD §5.8 (`jsGet(item`) finds `jsGet(item, '2')` at `bubble.js:62`. PD §5.4
   and ADR 0027 §5 item 1 give this form. It is not a defect.
4. "should be registered as dataset controller" is a record of wave 3 in `all.json` (module
   `controllers/index`). It passes now, because the spec reads `Chart.registry.controllers.items`
   and `main()` registers the controller.
5. The fidelity review of this unit (work-plan §0 item 5) did not run in this unit.

## Fixes

The fixer of U-bubble applied the findings of `doc/phase7/review/wave2/U-bubble-review.md`. All
four findings are confirmed. `<fix>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/U-bubble-fix/`.
No probe file is in the repository.

### R1. The stale parsed item of `_insertElements` (high): no fix in this unit, open item 6

`lib/src/core/core.datasetController.dart` is a wave 1 file. It is not a file of U-bubble
(work-plan §0 item 1). Thus this unit did not change it. Send it to W2-int or to the phase lead.

- **Open item 6 (new).** `_insertElements` (`core.datasetController.dart:1843-1844` and
  `:1855-1856`) puts `undefined` at the indexes `start .. end - 1` of `meta.parsed`. Upstream
  `move` (`core.datasetController.js:1000-1005`) keeps the old parsed items at the indexes below
  the old length. Only the indexes at or past the old length are holes. The bubble parse reads
  the old items through `getParsed` (`controller.bubble.js:49`, `:62`, `:75`, `:152`, `:165`).
  Proposed fix: in the `move` of `meta.parsed`, keep the old item at each index `k` of
  `start .. end - 1` with `k` below the old length, and put `undefined` only at the other
  indexes.
- **The pin case (new).** The generator has the case `parsed: an insert below the old length
  reads the old parsed item`: object data, array data and primitive data with
  `radius: rawRadius` (`(ctx) => ctx.raw`), each with a `splice` that inserts an item without
  `r` below the old length. The test file runs it as a placeholder with the reason
  `_staleParsed` ("blocked: core.datasetController _insertElements keeps no old parsed item
  (U-bubble report, open item 6)"). `<fix>/cases_probe_test.dart` (output
  `<fix>/cases_probe.out`) runs it: step 0 fails at `datasets.0.parsed`, `_custom` of the new
  item is 3 in the port and 5 upstream. This is the defect of R1 and no other difference.
- **After the fix of open item 6.** Remove the entry of the case from `_blocked` in
  `test/port/controllers/controller.bubble_test.dart`. The case then pins R1.

### R2. The case `[x, y, r] arrays` never ran (medium): fixed

- `tool/reference/controller_bubble_reference.mjs`: the ADR case `[x, y, r] arrays` has only
  numeric items now (`[5, 5, 7]` in place of `[5, 5, '7']`). It has the steps `update`,
  `push` (`[6, 2, 3]` and `[7, 6]`, past the old length), `splice` of dataset 0 (delete 1,
  insert `[1, 1, 4]`, `[2, 2, null]` and `[3, 3, 0]` below the old length), `splice` of
  dataset 1 (insert `[5, 4]` and `[6, 5, 1.5]` at the old length, thus the dataset `radius` 6),
  `reset` and `update`. Each item that the splices insert below the old length has an
  `item[2]`. Thus the case does not depend on open item 6. It examines `item[2]` as a number,
  `null`, `0` and absent, and the `radius` of the dataset, at the initial parse and at the
  inserts.
- The string item moves to the new case `parsed: a string r of an array` (`[1, 2, 5]` and
  `[5, 5, '7']`). It is a placeholder with the reason `_stringRadius` (open items 1 and 2).
- `test/port/controllers/controller.bubble_test.dart`: `[x, y, r] arrays` runs unthemed and
  with the light preset. All 7 cases of Chart.js ADR 0030 §7 run in the two runs now.

### R3. Wrong citations (low): fixed

- `lib/src/controllers/controller.bubble.dart`: `initialize()` `:38` to `:37`,
  `parsePrimitiveData` `:47` to `:46`, `parseArrayData` `:59` to `:58`,
  `resolveDataElementOptions` `:146` to `:151`. The fixer also found the range of the statics
  in the doc comment of `jsClass`: `:6-37` to `:6-35` (line 35 is the `};` of `overrides`).
- `test/specs/controller.bubble_test.dart`: `:270 beforeEach` to `:255 beforeEach`.
- `test/port/controllers/controller.bubble_test.dart`: `element.point.ts:11-14` to `:11-16`,
  with the lines of the `+`: `:15`, `:65` and `:105`.
- This report: `:50` to `:49` (section "The lib port") and `:11-14` to `:11-16` (open item 1).
- A grep of the other citations in the three files against the pinned files found no other
  wrong line.

### R4. The hit evidence of the placeholders (low): fixed

The probe `nohits_probe_test.dart` of section "Checks" compared the hit items as strings
(`[0.0, 0.0]` against `[0, 0]`). Thus its counts of different hits are not valid.
`<fix>/hits_probe_test.dart` (output `<fix>/hits_probe.out`) compares the items as numbers:

| Case | Queries that differ | Items in the difference |
|---|---|---|
| `parsed: a string r of an array` | 3 of 288 | `[0, 1]`, the point with the radius `'07'` |
| `parsed: radius '4' with primitive data` (initial and step 0) | 138 of 360 | the 3 points (each has a string radius) |
| `parsed: radius '4' with object data` | 69 of 288 | the 2 points (each has a string radius) |
| `parsed: parsing false, object items with _custom` | 0 of 432 | none |

Thus the hit differences come only from points with a string radius (open item 1). The case
`parsed: parsing false, object items with _custom` waits only for open item 2. In
`<fix>/cases_probe.out` its only failure is the draw call `arc` (`args[2]` is 2 in the port and
`'02'` in the reference). The test file now gives it the reason `_arcArguments` ("blocked: the
arc arguments of scale_chart_common.mjs (U-bubble report, open item 2)"). `_blocked` is a Map
from the case name to its reason.

### The placeholders after the fixes

| Case | Reason | Open items |
|---|---|---|
| `parsed: a string r of an array` | `_stringRadius` | 1 and 2 |
| `parsed: radius '4' with primitive data` | `_stringRadius` | 1 and 2 |
| `parsed: radius '4' with object data` | `_stringRadius` | 1 and 2 |
| `parsed: parsing false, object items with _custom` | `_arcArguments` | 2 |
| `parsed: an insert below the old length reads the old parsed item` | `_staleParsed` | 6 |

No themed twin is a placeholder now.

### Changes to the doc notes for W2-int

- **status.yaml**, the row `src/controllers/controller.bubble.js`: "`test/port/controllers/controller.bubble_test.dart`
  compares 18 charts with upstream (13 run, 5 wait for open items 1, 2 and 6 of the U-bubble
  report), and 7 more with the light preset (all 7 run)."
- **AGENTS.md, Tests:** the bubble test file runs 5 of its reference cases as placeholders until
  open items 1, 2 and 6 are closed. No themed twin is a placeholder.
- **differences.md:** if the phase lead accepts the behavior of open item 6 in place of a fix, a
  row is necessary (the resolved option is protected behavior, Chart.js ADR 0009).

### Checks after the fixes

| Command (from `packages/flutter_chartjs` unless stated) | Result |
|---|---|
| The generator, 3 runs (2 with the build path as the argument, 1 with `CHARTJS_DIST`) in the x64 Node.js v24.12.0 | 18 cases, 62 widths, 1,148,693 bytes; the same SHA-256 each time: `8544f02c9b4da97cfd374325efb4aacc0a13e5599bc7d8db203c800ee6879bf3` |
| `dart format --set-exit-if-changed` on the 4 Dart files of the unit | 0 changed |
| `dart analyze --fatal-infos` on the 4 Dart files of the unit | No issues |
| `flutter test test/port/controllers/controller.bubble_test.dart test/specs/controller.bubble_test.dart` | +39 ~6, all passed (port file: +29 ~5; spec file: +10 ~1) |
| `flutter test <fix>/cases_probe_test.dart` (the 5 placeholder cases and `[x, y, r] arrays`, unthemed and themed) | `[x, y, r] arrays` passes in the two runs; each placeholder case fails only at the difference of its open items |
| `flutter test <fix>/hits_probe_test.dart` | the table of R4 |
| `dart run melos run check:headers`, `check:js-semantics` (repository root) | passed: 359 and 128 files, 0 errors, 0 warnings |

The full gate did not run (W2-int runs it). After the unit test run, one orphan `flutter_tester`
process (PID 21357, working folder `packages/flutter_chartjs`, started at the end of that run,
with no `flutter` tool process) was left. The fixer stopped it. The process 67820 belongs to
another session; the fixer did not stop it.
