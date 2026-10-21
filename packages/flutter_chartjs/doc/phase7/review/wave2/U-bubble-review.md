# Wave 2, unit U-bubble: fidelity review

## Scope

This review compares the files of U-bubble with the pinned upstream (`7169e651`), Chart.js ADRs
0009, 0010, 0027, 0028 and 0030, PD §5.4, IV §4.1 and §7.3, and `all.json`. The files are:

- `lib/src/controllers/controller.bubble.dart`
- `tool/reference/controller_bubble_reference.mjs` and `test/port/controllers/controller_bubble_reference.dart`
- `test/port/controllers/controller.bubble_test.dart`
- `test/specs/controller.bubble_test.dart`

All paths are relative to `packages/flutter_chartjs/`. `<scratch>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/U-bubble-review/`.
Each Node.js probe ran in the x64 Node.js v24.12.0 on the build at the pin. Each Dart probe ran
with `flutter test <scratch>/<file>` from `packages/flutter_chartjs`. No probe file is in the
repository. No `flutter_tester` process of this review is left.

## Findings

| Id | Verdict | Severity | Short text |
|---|---|---|---|
| R1 | confirmed | high | An insert at a position below the old length gives a different `_custom` (stale parsed item); the defect is in `core.datasetController.dart` |
| R2 | confirmed | medium | The ADR 0030 §7 case `[x, y, r] arrays` never runs, so no running case compares `parseArrayData` with upstream |
| R3 | confirmed | low | 6 wrong `file:line` citations |
| R4 | confirmed | low | The report evidence for the hits of the 4 placeholders counts each non-empty query as a difference |

### R1. The stale parsed item of `_insertElements` (confirmed, high)

**Upstream.** `core.datasetController.js:1000-1005` moves `_parsed` with
`arr.length += count` and a loop that writes only the indexes `>= end`. Thus the indexes
`start .. end - 1` that are below the old length keep the OLD parsed items. Then `parse(start,
count)` (`:1015`) runs. The bubble reads these old items during the parse:
`parsePrimitiveData`, `parseArrayData` and `parseObjectData` call
`resolveDataElementOptions(i + start)` (`controller.bubble.js:49`, `:62`, `:75`). This calls
`getParsed(index)` (`:152`) and adds `parsed._custom` of the old item to the radius (`:165`).
Thus the fallback radius of a new item is the `_custom` of the old item at the same index.

**Port.** `lib/src/core/core.datasetController.dart:1843-1844` and `:1855-1856` fill the indexes
`start .. end - 1` with `undefined`. The comment at `:1855` says that `arr.length += count` leaves
holes. That is correct only for the indexes at or past the old length. Thus `getParsed` gives
`undefined`, and the bubble uses the option radius.

**Result.** The resolved radius (`_custom`, `options.radius`) of the new item differs. Chart.js
ADR 0009 protects the resolved option. The hit element and the draw calls also change, because
the radius changes.

**Probe.** `<scratch>/stale_gen.mjs` writes `<scratch>/stale_reference.dart` with 2 cases;
`<scratch>/stale_probe_test.dart` runs them through `testControllerChartCases`. Output:
`<scratch>/stale_probe.out`.

- Object data `[{r: 5}, {r: 6}, {r: 7}]`, then `splice(0, 0, {x: 9, y: 9})`: upstream `_custom`
  of the new item is `5` (the old item 0). The port gives `3` (the default radius).
- Primitive data `[3, 1, 2]` with `radius: (ctx) => ctx.raw`, then `splice(1, 0, 4)`: upstream
  `_custom` of the new item is `1` (the old item 1). The port gives `4`.

The same defect shows in `<scratch>/arrays_probe.out` at a `splice` step of array data (R2):
upstream `0` (the old item had `item[2]` `null`), port `3`.

**Owner.** `core.datasetController.dart` is a wave 1 file and not a file of U-bubble. Send it to
W2-int or to the phase lead. A possible fix: in `move` of `meta.parsed`, keep the old item at
each index `k` in `start .. end - 1` with `k` below the old length, and put `undefined` at the
other indexes. Then add a bubble reference case with an insert at a position below the old
length (object data and primitive data with a `ctx.raw` radius).

**Gap in the unit tests.** The `default` case does not pin this. Its `push` inserts past the
old length. Its `splice` inserts `{x: 1, y: 1, r: 4}` (the `r` wins) at index 1 and
`{x: 2, y: 8}` at index 2, where upstream also has a hole.

### R2. The case `[x, y, r] arrays` never runs (confirmed, medium)

Chart.js ADR 0030 §7 gives 7 bubble cases. The work plan (§2, U-bubble) asks for the 7 cases and
their twins. The generator puts the item `[5, 5, '7']` in the case `[x, y, r] arrays`
(`tool/reference/controller_bubble_reference.mjs:206`). Thus the test file skips the full case
in the unthemed run and in the themed run (`_blocked`,
`test/port/controllers/controller.bubble_test.dart:69-74`). The run of the two test files shows
`[x, y, r] arrays` and `theming.md §8 test 3: the light preset [x, y, r] arrays` as skipped.

Thus no running reference case compares `parseArrayData` with upstream: `item[2]` as a number,
`null`, `0` and absent, and the `radius` of the dataset. The `parsed:` case with arrays uses
`parsing: false`, which does not call `parseArrayData`. The group test "r '7' of an array"
examines only one `options.radius`.

**Probe.** `<scratch>/arrays_gen.mjs` writes the same config without the item `'7'` (item
`[5, 5, 7]`), with the steps `update`, `push`, `splice`, `reset` and `update`, to
`<scratch>/arrays_reference.dart`. `<scratch>/arrays_probe_test.dart` runs it unthemed and with
the light preset. The steps `initial`, `update` and `push` pass. The `splice` step fails
because of R1 (`<scratch>/arrays_probe.out`). Thus a numeric case would run now, and it would
show R1.

**Proposed fix.** Remove `[5, 5, '7']` from the ADR case and put it in a `parsed:` case (it
can stay a placeholder until open items 1 and 2 of the report close). Give the ADR case the
steps `push` and `splice`. After the fix of R1, the case pins R1 too.

### R3. Wrong citations (confirmed, low)

The bar unit and PD §5.4 cite the line of the method declaration. `grep -n` on the pinned files
gives these lines:

| File:line | Cites | Correct |
|---|---|---|
| `lib/src/controllers/controller.bubble.dart:96` | `controller.bubble.js:38` `initialize()` | `:37` |
| `lib/src/controllers/controller.bubble.dart:103` | `controller.bubble.js:47` `parsePrimitiveData` | `:46` |
| `lib/src/controllers/controller.bubble.dart:125` | `controller.bubble.js:59` `parseArrayData` | `:58` |
| `lib/src/controllers/controller.bubble.dart:293` | `controller.bubble.js:146` `resolveDataElementOptions` | `:151` (`:146` is the start of the JSDoc) |
| `test/specs/controller.bubble_test.dart:297` | `:270 beforeEach` | `:255` |
| `test/port/controllers/controller.bubble_test.dart:59` | `element.point.ts:11-14` (the `+` of `_inRange`) | `:11-16`: the `+` is at `:15` |

The report also cites `:50` for `jsGet(resolveDataElementOptions(i + start), 'radius')`. The line
is `:49`.

### R4. The hit evidence of the 4 placeholders (confirmed, low)

The report says that `nohits_probe_test.dart` shows the upstream observations "except the hit
items". That probe compares each hit item as a string. A Dart item has `double` values
(`[0.0, 0.0]`) and a JSON item has `int` values (`[0, 0]`). Thus it counts each non-empty query
as a difference (399, 318, 240 and 255). It does not show which hits differ.

**Probe.** `<scratch>/hits_probe_test.dart` compares the items as numbers:

| Case | Queries that differ | Items in the difference |
|---|---|---|
| `[x, y, r] arrays` | 6 of 612 | `[0, 4]`, the point with the radius `'07'` |
| `parsed: radius '4' with primitive data` (initial and step 0) | 138 of 360 | the 3 points (each has a string radius) |
| `parsed: radius '4' with object data` | 69 of 288 | the 2 points (each has a string radius) |
| `parsed: parsing false, object items with _custom` | 0 of 432 | none |

Thus the hit differences come only from points with a string radius (open item 1). The case
`parsed: parsing false, object items with _custom` waits only for open item 2 (the `arc`
arguments). Its skip reason names both items. Correct the report and the reason, or keep the
reason and note this for W2-int.

## Checks without a finding

- The lib port: each statement of `controller.bubble.js:4-168` has its Dart form in the same
  order. The forms agree with PD §5.4, ADR 0027 §7 (the `&&` chain of `:75`, `jsAdd` at `:165`)
  and ADR 0028 §2 and §4 (the label `labels[index] || ''`, the cast at `size`). The DIVERGES
  marker at `:157` names the row `adapt-typed-element-options`.
- Edge values. `<scratch>/probe.mjs` (output `<scratch>/probe.out`) and
  `<scratch>/probe_test.dart` give the same values in Node.js and in Dart for:
  - the `r` values `[5]`, `['7']`, `[]`, `[1, 2]`, `' 12 '`, `'0x1F'`, `'1e3'`, `'  '`,
    `'Infinity'`, `'-0'`, `{}` and `false`: `_custom`, `options.radius` and the value of
    `getLabelAndValue`;
  - array data with the other items `'abc'`, `5` and `{x, y, r, 2: 9}`;
  - category labels that are arrays (the value `(a,b, 1, 2)`).
- The throws are the same as upstream. `getLabelAndValue` past the parsed items throws a
  `TypeError`. A `null` item throws a `TypeError` from `jsGet` (the JS property read), not from
  a Dart cast: in `getMinMax` with `parsing: false`, and in `parseObjectData` with parsing.
- The generator. A copy of it in `<scratch>/regen.mjs`, with only the output path changed,
  writes data that is equal to the committed data, except the line that names the generator path.
- The spec port. The 11 `it` cases have the upstream names and order. 10 have bodies, and 1 has
  the skip `blocked: plugin.tooltip`. This agrees with the 11 records of `all.json` (10 `phase7`
  and 1 `blocked: plugin.tooltip`). The assertions agree with
  `controller.bubble.tests.js:4-425`.
- The run of the two unit test files: `+37 ~6`, all passed. This agrees with the report.
