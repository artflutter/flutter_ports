# Wave 2, unit U-doughnut: fidelity review

## Scope

This review compares the files of U-doughnut with the pinned upstream (`7169e651`), Chart.js ADRs
0009, 0010, 0027, 0028 and 0030, PD §5.1 and §5.5, IV §4.4, §4.7, §4.8 and §7.3, the work plan
(§2, row U-doughnut) and `all.json`. The files are:

- `lib/src/controllers/controller.doughnut.dart`
- `tool/reference/controller_doughnut_reference.mjs` and
  `test/port/controllers/controller_doughnut_reference.dart`
- `test/port/controllers/controller.doughnut_test.dart`
- `test/specs/controller.doughnut_test.dart`

All paths are relative to `packages/flutter_chartjs/`. `<scratch>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/U-doughnut-review/`.
Each Node.js probe ran in the x64 Node.js v24.12.0 on the build at the pin. Each Dart probe ran
with `flutter test <scratch>/<file>` from `packages/flutter_chartjs`. No probe file is in the
repository. No `flutter_tester` process of this review is left. The process 67820 belongs to
another session. This review did not start it and did not stop it.

## Findings

| Id | Verdict | Severity | Short text |
|---|---|---|---|
| R1 | confirmed | low | `_onClick` toggles a data index for a legend item index that is not a number, where upstream toggles no data index |
| R2 | confirmed | low | A wrong citation: `core.datasetController.js:304-305` is `:306-307` |
| R3 | confirmed | low | The ADR 0030 §7 case "`cutout` `'50%'`" is `cutout '25%'` in the generator, and the report does not record the change |
| R4 | confirmed | low (outside the row) | String `data` throws a `TypeError` in the port; upstream draws a chart |

### R1. `_onClick` with a legend item index that is not a number (confirmed, low)

**Upstream.** `controller.doughnut.js:126` calls `legend.chart.toggleDataVisibility(legendItem.index)`.
`core.controller.js:881-883` uses the index as a property key: `ToString(index)`. Thus the index
`'01'` gives the key `'01'`, `true` gives `'true'` and `null` gives `'null'`. No data index has
these keys. `getDataVisibility(i)` reads the key `String(i)`.

**Port.** `controller.doughnut.dart:713` applies `jsToNumber` to the index, and
`Chart.toggleDataVisibility(double index)` makes the key `jsNumberToString(index)`. Thus `'01'`,
`'1.0'`, `' 1'` and `true` give the key `'1'`, and `null` gives the key `'0'`.

**Result.** The port hides a data arc where upstream hides no arc. The arc gets the circumference 0,
the other arcs get more. The hit element and the arcs change (Chart.js ADR 0009). The doc of
`_onClick` (`:709-711`) and ADR 0028 §6 say that only an absent index differs, and that no reader
sees the difference. That statement is not complete.

**Probe.** `<scratch>/probe.mjs` (output `<scratch>/probe.out`) and `<scratch>/probe_test.dart`
(output `<scratch>/probe_dart.out`). A doughnut chart with `data: [1, 2, 3]`, then `onClick({},
{index}, legend)`:

| `index` | upstream `visible` | port `visible` |
|---|---|---|
| `'01'`, `'1.0'`, `' 1'`, `true` | `[true, true, true]` | `[true, false, true]` |
| `null` | `[true, true, true]` | `[false, true, true]` |
| `'1'` (control) | `[true, false, true]` | `[true, false, true]` |

**Impact.** Low. `generateLabels` gives a number index. Only a user legend item or a user
`generateLabels` gives another value.

**Owner.** The phase lead: the interface `types.Chart.toggleDataVisibility(double)` and the text
of ADR 0028 §6 cause the difference. The unit follows the ADR. Possible fixes: a
`differences.md` row and a `DIVERGES` marker at `:713`, or a key form of the interface that takes
`Object?` and applies `jsToString` (the polar area `_onClick` of U-polarArea has the same form).
At a minimum, correct the doc of `_onClick`.

### R2. A wrong citation (confirmed, low)

`test/port/controllers/controller.doughnut_test.dart:146` cites
`core.datasetController.js:304-305` for the writes of `xAxisID` and `yAxisID` in `linkScales`. At
the pin, line 304 is `const chooseId = ...` and line 305 is empty. The writes are at `:306-307`:

```
306:    const xid = meta.xAxisID = valueOrDefault(dataset.xAxisID, getFirstScaleId(chart, 'x'));
307:    const yid = meta.yAxisID = valueOrDefault(dataset.yAxisID, getFirstScaleId(chart, 'y'));
```

Probe: `grep -n "meta.xAxisID = \|meta.yAxisID = " third_party/Chart.js/src/core/core.datasetController.js`.
All other `file:line` citations of the four files agree with the pin (each `///` line of
`controller.doughnut.dart`, `core.datasetController.js:104` and `:367`, `core.controller.js:841-842`,
`platform.basic.js:20-22`, `platform.base.js:80`, `index.umd.ts:35`, and the spec lines `:92-98`,
`:191-197`, `:237-243`, `:313`, `:334`).

### R3. The case "`cutout` `'50%'`" of ADR 0030 §7 (confirmed, low)

ADR 0030 §7, row `doughnut` (`doc/adr/0030-controller-test-strategy.md:290`), gives
"`cutout` `'50%'` and a number". The generator has `runControllerCase("cutout '25%'", two({cutout:
'25%'}, {}))` (`tool/reference/controller_doughnut_reference.mjs:163`). The report lists
`cutout '25%'` as one of "the 15 cases of Chart.js ADR 0030 §7" and does not say that it changed
the value. The work plan says that the ADR wins.

The change does not lose coverage: `'50%'` is the default, and the `default` case resolves it.
`'25%'` adds a value. Thus the case can stay. But the report, the doc notes for W2-int (the
status text says "15 charts" of ADR 0030) and the phase record must state the change, or the case
must use `'50%'`. The phase lead decides.

### R4. String `data` (confirmed, low, outside the row)

**Upstream.** `_dataCheck` (`core.datasetController.js:365-392`) keeps a string `data`:
`Object.isExtensible('abc')` is false (`:386`), so `listenArrayEvents` does not run. The doughnut `parse`
reads `data[i]`, a character. With `data: '123'` and `parsing: false`, the chart has 3 arcs with
`total` 6.

**Port.** `core.datasetController.dart:940` casts `data` to `List<Object?>` and throws a
`TypeError`. The doc at `:914-915` says that a string is outside the upstream type contract.
`differences.md` has no row. Thus the claim of `controller.doughnut.dart:247-252` ("`data` is a
List after `_dataCheck` ... Thus the cast cannot fail") is true in the port, but upstream accepts
the string.

**Probe.** `<scratch>/probe.mjs` and `<scratch>/probe_test.dart`:

| Config | upstream | port |
|---|---|---|
| `data: 'abc'` | 3 arcs, `parsed` NaN, `total` 0 | `TypeError` (the cast of `core.datasetController.dart:940`) |
| `data: '123', parsing: false` | 3 arcs, `total` 6, circumferences `π/3`, `2π/3`, `π` | `TypeError` (the same cast) |

**Impact.** Low. A string is not a documented `data` value. Chart.js ADR 0009 protects a throw.

**Owner.** Not U-doughnut: `core.datasetController.dart` is a wave 1 file. Send it to the phase
lead for a `differences.md` row (or a decision that no row is necessary).

## Checks without a finding

- Each method, function and static of `controller.doughnut.js` has its port, in the upstream order
  of statements and calls: `getRatioAndOffset`, the constructor body, `linkScales`, `parse`,
  `_getRotation`, `_getCircumference`, `_getRotationExtents`, `update`, `_circumference`,
  `updateElements`, `calculateTotal`, `calculateCircumference`, `getLabelAndValue`,
  `getMaxBorderWidth`, `getMaxOffset`, the three ring weight functions, `defaults` (with
  `spacingMode`), `descriptors`, `overrides` and the two legend functions. No upstream statement
  is missing.
- JS semantics: `this._parsing === false` is `parsing == false`; `=== null` is `== null` (the
  `undefined` sentinel is not `null`); `+data[i]` and each arithmetic on a raw option apply
  `jsToNumber`; the global `isNaN` is `jsIsNaN` (it applies `ToNumber`); `|| 0` before
  `Math.max` is `jsOrZero`; `|| 1` and `labels || []` and `labels[index] || ''` use `jsTruthy`;
  the `spacing` sum is `jsAdd` (a string and an array operand join, as upstream);
  `valueOrDefault` replaces only `undefined`. `jsGet` throws a `TypeError` for a `null` or
  `undefined` receiver, as the upstream property read does (`chart.legend.options.labels`
  undefined, `data.labels` null).
- The loop bounds read `datasets.length`, `arcs.length` and `metaData.length` at the same times as
  upstream.
- The legend item keys have the order of the upstream literal. `overrides` holds tear-offs of
  top-level functions. The test "the legend functions are the same function in each read" pins
  the identity.
- The generator reruns to byte-identical data: `<scratch>/regen.mjs` (the generator with only the
  output path and the import path changed) writes `<scratch>/regen_reference.dart`. The only
  difference to the committed file is the line `// Generated by <path>`.
- The two test files pass: `flutter test test/port/controllers/controller.doughnut_test.dart
  test/specs/controller.doughnut_test.dart` gives `+62 ~2: All tests passed!`
  (`<scratch>/unit_tests.out`).
- The skips: `:418` has the verdict `blocked: plugin.tooltip` in `all.json` and skips with that
  reason. `:4` has the verdict `phase7`, but its modules include `controller.pie` (wave 3). ADR
  0030 §12 item 7 keeps such a record blocked until its wave. The full body with
  `skip: 'blocked: controller.pie'` is correct. The 11 other `phase7` records have bodies and pass.
- The BasicPlatform patch of the generator (`:56`) makes the JS charts keep an animation object,
  as a chart of the DOM platform does. `makeChart` still writes `animation: false` when the config
  has no `animation`. The Dart harness does the same. Thus each case has the same animation
  options on both sides. The `reset` cases pin `innerRadius` and `outerRadius` 0 (animateScale)
  and the circumference 0 (animateRotate).
- The hit difference of the edge probe of the unit, "hoverBorderWidth and borderAlign inner"
  (`wave2/U-doughnut/probe_edges.log`), is the tie of open item 4 of the report: the two arcs of
  `[1, 2]` have opposite centers, so their midpoint is the chart center.
- The themed group skips the `parsed:` and `interfaces:` cases (`controller_chart_harness.dart:823`),
  as the test file states.
- `_undefinedAxisIds` changes only the expected `null` of `xAxisID` and `yAxisID`. No port code
  reads the axis ids of a doughnut meta (`binarySearch` reads `iScale`, which is undefined).
- No `DIVERGES` marker. No performance form that changes the structure.
