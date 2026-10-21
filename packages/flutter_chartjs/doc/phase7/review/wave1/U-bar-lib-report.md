# Wave 1, unit U-bar-lib (the lib part of U-bar): report

## Status

Done. `lib/src/controllers/controller.bar.dart` ports `src/controllers/controller.bar.js` at the
pin `7169e651` line by line, with the forms of Chart.js ADR 0027 (parsed reads, raw option values)
and Chart.js ADR 0028 (interface reads, casts). It uses `stacksOf` of DC (S3 landed it during this
unit, decision D5). `dart analyze` finds no issue. A scratch smoke test compares 44 bar charts with
the pinned build in the x64 Node.js. All 44 cases agree.

The tests of the U-bar row (the reference generator, `controller.bar_test.dart`, the spec file)
are not part of this unit. They come after U0 and S3.

## Files that changed

The paths are relative to `packages/flutter_chartjs/`.

| File | Change |
|---|---|
| `lib/src/controllers/controller.bar.dart` (new) | The port of `controller.bar.js`: the module functions, `BarController` with `id`, `defaults`, `overrides` and the class value `jsClass` (superclass `DatasetController.jsClass`), the overrides of `parsePrimitiveData`, `parseArrayData`, `parseObjectData`, `updateRangeFromParsed`, `getMaxOverflow`, `getLabelAndValue`, `initialize`, `update`, `updateElements` and `draw`, the public `getFirstScaleIdForIndexAxis`, and the private `_getStacks`, `_getStackCount`, `_getAxisCount`, `_getAxis`, `_getStackIndex`, `_getRuler`, `_calculateBarValuePixels` and `_calculateBarIndexPixels`. |

No other file of the repository changed. No test file was added to the repository.

## Forms of the port

- Parsed items, data items, `_custom` objects and stack objects: `jsGetKey` for each String key,
  `jsGetIndex` for each number index (`data[i]`, `labels[i]`, `entry[0]`, `entry[1]`), `stacksOf`
  for `parsed._stacks` (`:405`, `:615`). No `_parsedValue`, no `jsGet(parsed` or `jsGet(item`.
- Resolver and option reads: `jsGet`. The raw option values stay `Object?` until their operator
  (ADR 0027 §7): `baseValue || 0`, `jsAdd(start, length)`, `jsToNumber` of `minBarLength` and of
  `maxBarThickness` once at the read, `ruler.min` as `Object?`, `range.ratio` as `Object?` with
  `jsToNumber` at `:652`, `barThickness == 'flex'`, `edge == true`, `edge == 'middle'`,
  `jsOrZero(jsGetKey(stack, '_top')) == index`, `vScale.min >= jsToNumber(actualBase)`.
- `setInflateAmount`: the form of ADR 0027 §6 (`jsToNumber` of a value that is not a `num` and not
  `undefined`).
- The reads of other modules go through `lib/src/types/`. The file imports
  `core.datasetController.dart`, the helpers, the JS runtime and the types only (IV §4.1, §4.8).
- The memo of `_getAxis`, `getFirstScaleIdForIndexAxis` and `_getStacks` for each bar, the
  `skipNull` find and the empty Map of `(parsed._stacks || {})` are literal (the step 7 list).
- `draw` reads `ctx` for each bar and casts the element to `types.VisualElement` at the draw
  (ADR 0030 §1 item 4, ADR 0028 §1).

## Checks

| Command | Result |
|---|---|
| `dart analyze --fatal-infos packages/flutter_chartjs/lib/src/controllers/ packages/flutter_chartjs/lib/src/core/core.datasetController.dart` | No issues found (after S3 landed `stacksOf`). |
| `dart format --output=none --set-exit-if-changed packages/flutter_chartjs/lib/src/controllers/controller.bar.dart` | 0 changed. |
| `dart run melos run check:headers` | passed, 332 files. |
| `dart run melos run check:lib-imports` | passed, 295 files. |
| `dart run melos run check:js-semantics` | passed, 116 files. |
| `dart run melos run port:next:check` | passed, 196 files. |
| `dart run melos run parity:check` | fails as expected: `parity.md:126` needs the Dart target of `controller.bar.js`, and `status.yaml` has the status "not started" for a file that exists. W1-int changes `status.yaml` and runs `parity` (rule 2 of the work plan). The two other warnings (`path2d_record.dart`, `types/index_test.dart`) belong to U0 and S2. |
| Scratch smoke test, see below | 44 of 44 cases pass. |

### The scratch smoke test

Files (scratch, not in the repository), in
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/U-bar-lib/`:
- `probe.mjs`: builds 44 bar charts with `scale_chart_common.mjs` (`loadChartJs`, `registerPhase6`
  with `BarController`, `makeChart`) in the x64 Node.js v24.12.0 on the build at the pin, and
  writes `probe.json`: for each bar `x`, `y`, `base`, `width`, `height`, `horizontal`,
  `enableBorderRadius`, `borderSkipped`, `inflateAmount`; `getLabelAndValue(i)`; the parsed
  items; the indexes that `draw` draws; the scale `min` and `max`; or the error class.
- `bar_smoke_test.dart`: `flutter test` of this file from `packages/flutter_chartjs` (with a copy
  of `test/flutter_test_config.dart` next to it). `main()` calls
  `Chart.register([BarController.jsClass])`. Each case runs `acquireChart` with the same config and
  compares. `inflateAmount` compares with the `ToNumber` of the upstream raw value (ADR 0027 §6).
  The draw count is the count of `save` calls on a mock `ctx` of each controller.

Commands:
- `/usr/bin/arch -x86_64 <scratchpad>/env/node-v24.12.0-darwin-x64/bin/node probe.mjs <scratchpad>/env/chartjs-build/dist/chart.js probe.json`: "wrote 44 cases".
- `flutter test <scratch>/bar_smoke_test.dart`: "+44: All tests passed!". A run with four changed
  expected values failed at those values, so the comparison is effective.

The cases: a basic bar; stacked bars with `borderSkipped: 'middle'` and `minBarLength`; float
bars (`[start, end]`); `indexAxis: 'y'` with `borderSkipped: true`; object data with
`xAxisKey`/`yAxisKey`; `barThickness: 'flex'` with `skipNull` and `null` values; `grouped:
false` with `maxBarThickness` and `barThickness`; a linear index axis (`computeMinSampleSize`);
stack groups; `base` 5 and `'0'` with `minBarLength`, `inflateAmount` 2 and `'auto'`; two index
axes (`_getAxis`); `minBarLength` on stacked bars (the `_visualValues` write); stacked float bars;
`inflateAmount` `'2'`, `null`, `true`, `'abc'`; `base` 5, `'5'`, with and without
`minBarLength: 20`; `base` `'0'` against 0 with `minBarLength: 10`; `base` `''`, `'abc'`, `true`,
1; `minBarLength: '20'`; `barThickness: '20'`; `barThickness: 'flex'` with `grouped: false`;
`maxBarThickness` `null` and `'30'`; `xAxisKey` `null` and 5 (TypeError); a bad `yAxisKey` on a
category axis (TypeError after the first label parse: labels `['q']`); `parsing: false` with a
string `_custom` (value `'[s, e]'`); `null` values; an absent value key against `null` (draw
`[0]`); `borderSkipped` `'middle'` without a stack, `'start'`, `'end'`, 5; `parsing: false` with
List items on stacked scales (no throw, x NaN, `enableBorderRadius` false, `borderSkipped`
`{bottom: true}`); `parsing: false` with numbers on stacked scales (TypeError).

No `flutter_tester` process of this unit is left. One process of another session
(`ec6419b7-...`) was running; this unit did not touch it.

## Doc notes for W1-int

- `AGENTS.md`, Layout, `packages/flutter_chartjs`: add an item for `lib/src/controllers/`:
  "`lib/src/controllers/`: the dataset controllers of phase 7. `controller.bar.dart` has
  `BarController` and its class value `BarController.jsClass` (statics `id`, `defaults`,
  `overrides`). A controller reads parsed items with `jsGetKey`, `jsGetIndex` and `stacksOf`
  (Chart.js ADR 0027), and the members of other modules through `lib/src/types/` (Chart.js ADR
  0028). The files are not pure layers: each imports `core.datasetController`."
- `doc/porting-flow.md`: no change from this unit.
- `doc/performance.md`: no figures from this unit. No faster form landed. The hot loops of the bar
  are literal (ADR 0027 §8, step 7 list).
- `doc/differences.md`: no new row and no new marker. The file has no `DIVERGES` marker.
- `doc/status.yaml`: the row of `src/controllers/controller.bar.js` gets the status "in progress"
  (the lib file is ported; the reference tests and the spec file come with the test part of
  U-bar), with the Dart target `lib/src/controllers/controller.bar.dart`. Then run `dart run melos
  run parity`.

## Open items

1. The test part of U-bar (after U0 and S3): `tool/reference/controller_bar_reference.mjs`, its
   data, `test/port/controllers/controller.bar_test.dart` and `test/specs/controller.bar_test.dart`
   with the temporary `Chart.register` in `main()`. The cases of `probe.mjs` can seed the `parsed:`
   cases of PD §7.3.
2. Two forms differ from the sketch of PD §5.2, for review:
   - `:581` `length = custom.barEnd - custom.barStart` reads `barStart` again (literal). The
     sketch uses `jsToNumber(value)`. Both give the same result for a Map `_custom`.
   - `:403` `{base, head: base}`: the record type of the two `_calculate*` methods has four
     fields. The reset path gives NaN for `size` and `center`. `Math.abs(undefined)` is NaN
     upstream, and no code reads `center`.
3. Two casts that the checklist of IV §4.8 does not list, for review:
   - `_getAllScaleValues`: `scale.cache[r'$bar']! as List<double>`. Only this function writes the
     key.
   - `_getAxis`: `jsGet(chart.data, 'datasets')! as List<Object?>` for `for...of`. A value that is
     not a List throws a `TypeError`, as the JS iteration does.
4. A residual of the ADR 0027 §7 form `jsOrZero(jsGetKey(stack, '_top')) == index`: `jsOrZero`
   gives the `ToNumber` of a truthy value, where `(stack._top || 0)` keeps the value. A stack
   object of DC holds a number or `null` in `_top` and `_bottom`. Only a user `_stacks` object in a
   `parsing: false` item of an unstacked chart can hold a string there. No change; the reviewer can
   decide.
5. `parity:check` fails until W1-int updates `doc/status.yaml` (see Checks).

## Fixes

The review is `U-bar-lib-review.md` (four findings, all confirmed). The fixes change
`lib/src/controllers/controller.bar.dart` only. Scratch folder of the fixes:
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/U-bar-lib-fix/`.

### F1: `(stack._top || 0) === index` (`:220`, `:222`)

Fixed. The port compares `_strictEquals(_orZero(jsGetKey(stack, '_top')), index)`, and the same
for `_bottom` in the `else if`. `_orZero` is `value || 0` without `ToNumber`: a truthy value stays
as it is. `jsOrZero` is not used in the file now. The order of the reads is the upstream order.
The ADR 0027 §7 row (`jsOrZero(...) == index`) and PD §5.2 now differ from the code. The phase
lead corrects them (open item 4 above is closed).

### F2: `===` on two `Date` values

Fixed at the four sites. A new private `_strictEquals` (the same function as in
`scale.category.dart` and `core.layouts.dart`) gives `===`: numbers and strings by value, every
other value by identity. The sites:

- `:462` `stacks.indexOf(meta.stack) === -1`: `!stacks.any((s) => _strictEquals(s, meta.stack))`.
- `:521` `stacks.indexOf(name)`: `stacks.indexWhere((s) => _strictEquals(s, name))`.
- `:444` the `skipNull` find (plausible in the review): `_strictEquals(jsGetKey(item, axis),
  iScaleValue)`. Confirmed by the probe below.
- `:603` `value === actualBase` (plausible in the review): `_strictEquals(value, actualBase)`.
  Confirmed by the probe below.

The other `==` sites of the file have one operand that is a `double`, a String literal or `null`.
Dart `==` gives `===` for them.

Probes (x64 Node.js v24.12.0, build at the pin; `probe.mjs`, `probe.out`, `fix_probe_test.dart`,
`before.out`, `after.out`):

| Case | Upstream | Port before | Port after |
|---|---|---|---|
| `F2-dateStack`: two separate `Date(0)` stacks | ds0 x 94.3728/340.0358, ds1 x 192.6380/438.3011, width 88.4387 | both x 143.5054/389.1685, width 176.8774 | as upstream |
| `F2-sameDateStack`: one `Date` object as both stacks | x 143.5054/389.1685, width 176.8774 | as upstream | as upstream |
| `F2-skipNullDate`: `parsing: false`, `skipNull`, linear x, separate equal `Date` x values | width 31.5045, x 32767 | width 15.7522, x 32758.2488/32775.7512 | as upstream |
| `F2-baseDateHidden`: `y` and `base` separate `Date(5)`, `minBarLength: 10`, index 0 hidden | y 375.25, base 365.25 | y 370.25, base 360.25 | as upstream |
| `F2-baseSameDateHidden`: one `Date` object as `y` and `base` | y 370.25, base 360.25 | as upstream | as upstream |
| `F1-topString`, `F1-topTrue` (the review cases) | `{top: true, bottom: true}` | `{bottom: true}` | as upstream |

Without the hidden index, a `Date` value gives `start + length` as a string join upstream, thus a
NaN size, and `:603` is not reached (`F2-baseDate`: y and base NaN in both).

Performance of the `skipNull` find (`bench_skipnull.dart`, AOT `dart compile exe`, 1000 parsed
Maps, 20000 finds, three rounds): Dart `==` 10.32-11.12 ns for each compared item,
`_strictEquals` 11.21-11.36 ns. The cost is 2-9 % of the find; `jsGetKey` is most of the time.
`_strictEquals` is the only form that gives the upstream behavior. W1-int can record the figures
in `performance.md`.

### F3: `! as String` of the parsing keys (`:555`, `:560`)

Doc fixed, code not changed. The doc of `parseObjectData` now states the residual: upstream
throws only when its resolver cache has no entry for the `ToString` of the key. The keys `[]` and
`[['y']]` do not throw upstream but throw in the port. Reasons for no code change: the cache of
`resolveObjectKey` is private to `helpers.core.dart` (not a file of this unit), it holds each
string key of earlier calls (process state), and the cast is the form of ADR 0027 §4 (also in
`helpers.config.dart:922` and DC `_keyOr`). The phase lead decides, and corrects the ADR text.

### F4: the two List casts (`:94`, `:827`)

Fixed: the casts are gone. `grep -n " as " controller.bar.dart` now gives the ADR 0027 §4 casts
(`:601`, `:606`), the PD §5.2 cast (`:1043`) and the `types.VisualElement` cast (`:1143`) only.

- `_getAllScaleValues`: `final cached = scale.cache[r'$bar']; if (cached is List<double>) return
  cached;`, else it computes, writes and returns the local List. Only this function writes the
  key, and an array is truthy, so the test gives the result of `!scale._cache.$bar`.
- `_getAxis`: `if (datasets is! List) throw TypeError();`, then `for (final dataset in
  datasets)`. The doc now gives the correct reason: `mergeScaleConfig` of each `initOptions`
  (core.config.js:93) calls `datasets.forEach` before a controller update. A String fails there
  first, thus the `for...of` of a String does not occur here.

Open item 3 above is closed.

### Checks after the fixes

| Command | Result |
|---|---|
| `dart analyze --fatal-infos packages/flutter_chartjs/lib/src/controllers/` | No issues found. |
| `dart format --output=none --set-exit-if-changed .../controller.bar.dart` | 0 changed. |
| `dart run melos run check:js-semantics` | passed, 116 files. |
| `dart run melos run check:lib-imports` | passed, 298 files. |
| `dart run melos run check:headers` | passed, 335 files. |
| `flutter test <scratch>/U-bar-lib/bar_smoke_test.dart` (44 cases of the unit) | +44, all passed. |
| `flutter test <scratch>/U-bar-lib-review/probe2_test.dart` (20 cases of the review) | +20, all passed. |
| `flutter test <scratch>/U-bar-lib-fix/fix_probe_test.dart` | 9 cases; each output line is equal to the upstream line (table above). |

No `flutter_tester` process of this unit is left. One process of another session (`ec6419b7-...`)
was running; the fixer did not touch it.
