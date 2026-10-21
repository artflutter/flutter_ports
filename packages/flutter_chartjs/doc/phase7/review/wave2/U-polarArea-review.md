# Wave 2, unit U-polarArea: adversarial fidelity review

## Result

The port of `controller.polarArea.js` agrees with the pinned lines in each statement that the
review compared. The review found no difference in the ticks, the hit element, the item order or
a resolved option for the configs of the report, the specs and the ADR tables. It found four
low findings. One finding (F1) is a behavior difference that comes from the form of Chart.js ADR
0028 §6. The unit applied that form correctly. The other three findings are text errors (a doc
claim, a citation and the report). No finding blocks the unit.

The paths are relative to `packages/flutter_chartjs/`. `<review>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/U-polarArea-review`.
The Node.js runs used the x64 build of Node.js v24.12.0 (`process.arch` `x64`) and the build of
Chart.js at the pin. The Dart probes ran with `flutter test <review>/<file>` from
`packages/flutter_chartjs`.

## Findings

### F1 (low, confirmed): `_onClick` toggles a data index for a legend item index that upstream does not match

- File: `lib/src/controllers/controller.polarArea.dart:115`
  (`legend.chart.toggleDataVisibility(jsToNumber(jsGet(legendItem, 'index')))`).
- Claim: upstream `toggleDataVisibility(legendItem.index)` (`controller.polarArea.js:66`) writes
  `_hiddenIndices[index]` with the property key `ToString(index)` (`core.controller.js:881-883`).
  The port applies `ToNumber` first and then makes the key of the number. For a value whose
  `ToString` is not the `ToString` of its `ToNumber`, the two keys are different. `null` and `''`
  give the key `'0'` in the port and the keys `'null'` and `''` upstream. `true` and `'01'` give
  the key `'1'` in the port and `'true'` and `'01'` upstream. Chart.js ADR 0028 §6 examines only
  the absent index (`'NaN'` against `'undefined'`). Its sentence "no reader sees the difference"
  is not true for these values.
- Probe: `<review>/onclick_probe.mjs` (output `onclick_node.out`) and
  `<review>/onclick_probe_test.dart` (output `onclick_dart.out`). A polar area chart with the data
  `[1, 2, 3]`, then `onClick({}, {index: v}, {chart})`:

  | `v` | upstream visibility, outer radii | port visibility, outer radii |
  |---|---|---|
  | `null` | `[true, true, true]`, `82.667, 165.333, 248` | `[false, true, true]`, `0, 165.333, 248` |
  | `''` | `[true, true, true]`, the same radii | `[false, true, true]`, `0, 165.333, 248` |
  | `true` | `[true, true, true]`, the same radii | `[true, false, true]`, `82.667, 0, 248` |
  | `'01'` | `[true, true, true]`, the same radii | `[true, false, true]`, `82.667, 0, 248` |
  | `1` | `[true, false, true]`, `82.667, 0, 248` | the same |

- Effect: the visible arcs, thus the hit element and the drawn chart (Chart.js ADR 0009). The
  default `generateLabels` always gives a number index. The difference needs a user
  `generateLabels` with an index that is not a number, and the default `onClick`. The doughnut
  `_onClick` of U-doughnut has the same form (ADR 0028 §6). This review did not probe it there.
- Recommendation: the phase lead decides for both controllers, because the form is in Chart.js
  ADR 0028 §6 (proposed). One form keeps the `double` parameter of `types.Chart`: give
  `jsToNumber(v)` only when `jsToString(v) == jsNumberToString(jsToNumber(v))`, else NaN. NaN
  gives the key `'NaN'`, which matches no data index, as the upstream key does. Or record the
  residual in the text of ADR 0028 §6.

### F2 (low, confirmed): the doc of `getLabelAndValue` says that `Intl.NumberFormat` applies `ToNumber`

- File: `lib/src/controllers/controller.polarArea.dart:216-217`, and the same sentence in the
  report (section "The lib file").
- Claim: the doc says "`formatNumber` applies `ToNumber` to the parsed value `r`, as
  `Intl.NumberFormat.prototype.format` does". On the reference engine, `format` applies
  `ToIntlMathematicalValue`. A string is an exact decimal there, not a `ToNumber` result.
- Probe (x64 Node.js, `new Intl.NumberFormat('en-US')`): `format('12345678901234567890')` gives
  `12,345,678,901,234,567,890`. `format(Number('12345678901234567890'))` gives
  `12,345,678,901,234,567,000`.
- Effect: only the digits of the label value, thus no protected behavior (Chart.js ADR 0009). The
  code is correct. The doc text is not.
- Recommendation: change the sentence to "`formatNumber` takes a `double`. Thus the port applies
  `jsToNumber`. For a string with more digits than a `double` keeps, upstream formats the exact
  decimal. The difference is in the digits only (Chart.js ADR 0009)."

### F3 (low, confirmed): a wrong line in the citation of `Scale.getMinMax`

- File: `lib/src/controllers/controller.polarArea.dart:270-271`.
- Claim: the doc says "[scale] and [canStack] of `Scale.getMinMax` (core.scale.js:312) are not
  read". At the pin, `core.scale.js:312` is the `for` line. The call
  `metas[i].controller.getMinMax(this, canStack)` is at `:313`. `Scale.getMinMax` starts at
  `:303`. The parameters of the controller method are at `core.datasetController.js:622`.
- Probe: `sed -n 312,313p third_party/Chart.js/src/core/core.scale.js` gives the `for` line and
  then the call. `grep -n getMinMax` gives `core.scale.js:303`, `:313` and
  `core.datasetController.js:622`.
- Recommendation: cite `core.scale.js:313`, or `core.datasetController.js:622`.

### F4 (low, confirmed): the report names two casts outside `types.`, the grep of IV §4.8 gives three

- File: `doc/phase7/review/wave2/U-polarArea-report.md`, open item 2, and
  `lib/src/controllers/controller.polarArea.dart:72`.
- Claim: open item 2 says "Two casts are not to a `types` interface (the grep of IV §4.8)". The
  grep also gives `(jsGet(data, 'labels')! as List<Object?>)` in `_generateLabels`.
- Probe: `grep -n " as " lib/src/controllers/controller.polarArea.dart` gives the casts at `:72`
  (`List<Object?>`), `:255` (`List<AnyObject>`), `:360` (`types.RadialLinearScale`) and `:402`
  (`AnyObject`).
- Effect: no behavior difference. A `labels` value that is not a List throws a `TypeError` at
  the cast, and upstream throws a `TypeError` at `map` (a String and a Map have no `map`
  function). The lib doc at `:59-60` says this correctly.
- Recommendation: add the cast at `:72` to open item 2, so that the step 6 review and W2-int
  decide the three casts together (the same subject as F4 of the wave 1 review of U-bar-lib).

## Observations (no defect)

- O1: no test runs the branch `opts.cutoutPercentage ? ... : 1` of `controller.polarArea.js:154`
  with a truthy value. The generator, the reference data and the port-only test have no
  `cutoutPercentage`. The spec uses only `cutoutPercentage: 0`. A probe gives the same values in
  both runtimes for `0`, `50` and `'25'` (`<review>/cutout_probe.mjs`,
  `cutout_probe_test.dart`, for example `50` gives `[[192, 256], [128, 192]]` for the two
  datasets). No code at the pin reads `innerRadius` or `outerRadius` of the controller. Thus the
  branch changes no protected behavior, and the gap is not a finding.
- O2: Chart.js ADR 0030 §7 gives 9 polar area cases but names 8 branches. The unit added the
  case `angle` (an indexable `angle` with `0` and `null`, and a scriptable `angle`). This covers
  `angle || defaultAngle` of `:234`. The choice is correct. The report does not say that the
  ninth case is the choice of the unit.
- O3: open item 1 (the `updateConfig` of `BasePlatform` on `BasicPlatform` for the case `reset`)
  is acceptable. `platform.basic.js:20-22` is the only platform that writes `animation: false`.
  `platform.dom.js` has no `updateConfig`, thus the browser of the upstream specs keeps the
  option, as `platform.flutter.dart` does. `runControllerCase` is synchronous, so the `finally`
  restores the method after the case and before the next case.

## What the review checked

- Each statement of `controller.polarArea.dart` against `controller.polarArea.js:1-237` at the
  pin: the statics and their key order (`:6-88`), the constructor (`:90-95`),
  `getLabelAndValue` (`:97-107`, the read of `_parsed`), `parseObjectData` (`:109-111`),
  `update` (`:113-118`), `getMinMax` (`:123-142`, one read of `getParsed(index).r`, the raw
  values, `jsLessThan` for `<` and `>`), `_updateRadius` (`:147-159`, two reads of
  `cutoutPercentage`), `updateElements` (`:161-214`, the cast, the reset branches, the property
  order, the #12238 hunk with `== 0` and `== 'angular'`), `countVisibleElements` (`:216-227`)
  and `_computeAngle` (`:232-236`). Each `///` line cites the correct upstream line, except F3.
- The JS forms: `jsIsNaN` applies `ToNumber` (`isNaN(undefined)` true, `isNaN(null)` false);
  `jsLessThan` compares two strings by code units and other values by `ToNumber`; `jsGet` throws
  a `TypeError` for `null` and `undefined` and gives `undefined` for a property of `false`
  (`animation: false`); `getDistanceFromCenterForValue` gives NaN for `undefined`; Dart `==` is
  `===` for the hunk operands (`0`, `0.0`, `-0.0`, a String). The return record of `getMinMax`
  holds the `ToNumber` of each end. The only caller (`core.scale.js:313-319`) applies
  `Math.min` and `Math.max`, which apply `ToNumber`. Thus the record gives the upstream scale
  range.
- The decisions against Chart.js ADRs 0027, 0028 and 0030, PD §5.6 and IV §4.5 and §4.7: the
  cast at `:166` (every path reaches `getIndexAngle` at `:169`), no `enableOptionSharing`, no
  marker on the hunk, the legend functions as tear-offs of top-level functions, the read of
  `chart.legend.options` inside the `if` (`:41`), the item keys in the order of `:47-58`, and
  `'index'` as a `double`.
- The spec port `test/specs/controller.polarArea_test.dart`: the 14 `it` cases in the upstream
  order with the exact names. The 13 cases with the verdict `phase7` in
  `doc/phase7/classification/all.json` have bodies with the upstream expectations. The case
  `:389` has the verdict `blocked: plugin.tooltip` and the same skip reason.
- The generator and the test file: the 44 cases (9 + 7 `parsed:` + 28 `interfaces:`), the
  probes `polarState` and `legend` with the same bodies in both languages, the subclass
  `polarAreaSharing` registered only around its 11 cases, and the themed run (the harness skips
  the `parsed:` and `interfaces:` cases). The test "the 9 cases first" checks each name.
- A copy of the generator (`<review>/regen.mjs`, with an absolute import and the output in
  `<review>`) wrote data that differs from the committed file only in the line that names the
  generator. The SHA-256 of the committed file is `dd5bc7b5...ba487136`, as the report says.
- `flutter test test/port/controllers/controller.polarArea_test.dart
  test/specs/controller.polarArea_test.dart`: +76 ~1, all passed.
- The headers of the five new files, `@TestOn('vm')` of the two test files, and the imports of
  the lib file (no concrete scale, element or chart module).
- The review changed no file of the repository except this file. It left no `flutter_tester`
  process. The process 67820 belongs to another session.
