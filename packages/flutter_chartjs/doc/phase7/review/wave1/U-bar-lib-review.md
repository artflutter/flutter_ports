# Wave 1, unit U-bar-lib (the lib part of U-bar): adversarial fidelity review

## Result

No blocking finding. `lib/src/controllers/controller.bar.dart` keeps the upstream statements, the
upstream calls and their order. The forms of Chart.js ADR 0027 §4, §6, §7 and §8 and of PD §5.2
are in the file as the ADR and the spec give them. The `///` citations of `controller.bar.js` are
correct at the pin `7169e651`. The header line is correct, and the file has no `DIVERGES` marker.
It needs none. A second probe of 20 more bar charts agrees with the pinned build in each value.

There are four findings of low severity. Three of them come from forms that Chart.js ADR 0027
gives (§4 and §7) or that the ADR does not cover (the `===` of `DateTime` values). No finding
changes a chart with a usual config: each one needs a value that a Chart.js config seldom has.
F2 and F3 change a behavior that Chart.js ADR 0009 protects (the bar position, thus the hit
element, and a throw). F1 changes only `borderSkipped`, thus pixels.

All paths are relative to `packages/flutter_chartjs/`. The probes are in
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/U-bar-lib-review/`.
`probe.mjs` and `probe2.mjs` stop unless the Node.js is x64 (`loadChartJs` of
`tool/reference/scale_chart_common.mjs`). They read the Chart.js build at the pin. Commands:

- `/usr/bin/arch -x86_64 <scratchpad>/env/node-v24.12.0-darwin-x64/bin/node probe.mjs <scratchpad>/env/chartjs-build/dist/chart.js`
  (output: `probe.out`).
- `flutter test <review folder>/review_probe_test.dart` from `packages/flutter_chartjs`
  (output: `review_probe.out`).
- `probe2.mjs` writes `probe2.json`; `flutter test <review folder>/probe2_test.dart` compares it.

## What the review checked

1. Each function and method against `controller.bar.js` at the pin, line by line: the statements,
   the reads of options and parsed items, the order of the reads, the short-circuit operators,
   and the arguments of each `getPixelForValue` call (one argument at :42, :590, :593, :619; two
   arguments at :540 and :655).
2. Each `///` citation of `controller.bar.js` (40 line numbers and ranges), and the citations
   `core.datasetController.js:170-173` and `element.bar.js:127-140, :179-196`. All are correct.
3. The JS forms of ADR 0010:
   - The sentinel: `_getStacks`, `_getStackCount` and `_getStackIndex` use Dart `null` for an
     absent argument. `getParsed(NaN)` gives `undefined`, as `_parsed[undefined]` does. The
     `skipNull` find gives `undefined` through `orElse`.
   - `isNaN` is `jsIsNaN` (the global `isNaN`, with `ToNumber`).
   - `valueOrDefault` replaces only the `undefined` sentinel. Thus `xAxisKey: null` throws, as
     upstream.
   - The `_visualValues` key is `jsNumberToString(datasetIndex)`. It gives the same string as
     `_indexKey` of DC, the key of the DC write.
   - `jsObjectKeys` puts the array-index keys first. Thus `_getAxis` and
     `getFirstScaleIdForIndexAxis` keep the upstream key order.
4. The raw option values against the table of ADR 0027 §7: each row of `bar.js` is in the file in
   the form of the table.
5. `setInflateAmount` against ADR 0027 §6. `inflateRect` (`element.bar.js:127-140`) applies
   `ToNumber` to each use of `amount`. Thus the conversion at the write keeps the draw.
6. The step 7 list of ADR 0027 §8: the memo of `_getAxis`, `getFirstScaleIdForIndexAxis` and
   `_getStacks` for each bar, the `skipNull` find and the new empty Map of `(parsed._stacks || {})`
   are literal. The file merges no read. Thus the one-read rule has no local to check. The two
   values that get one `jsToNumber` at the read (`minBarLength`, `maxBarThickness`) are the forms
   of the ADR. No form changes the structure. Thus no `adapt` row is necessary.
7. IV §4.1 and the checklist of IV §4.8: the imports, the `types.VisualElement` cast at the draw,
   the `ctx` read for each bar (ADR 0030 §1 item 4), the `getLabelAndValue` record type and the
   `updateElement` call without a cast. See F4 for the casts.
8. The report claims. `dart analyze --fatal-infos lib/src/controllers/`: no issues.
   `dart format --set-exit-if-changed`: 0 changed. A new run of the scratch smoke test of the unit
   (`wave1/U-bar-lib/bar_smoke_test.dart`) on the current tree: 44 of 44 pass.
9. 20 more charts (`probe2.mjs`, `probe2_test.dart`): `skipNull` with stack groups and a hidden
   dataset, `skipNull` without stacks and with `indexAxis: 'y'`, horizontal float bars with
   `base` and `minBarLength`, a logarithmic value axis, a reversed stacked axis with each
   `borderSkipped` value, negative horizontal stacks with `minBarLength`, `grouped: false` with
   `skipNull`, float bars with `base`, string `categoryPercentage` and `barPercentage`, the stacks
   `0`, `'0'`, `null` and absent, `stacked: false` on the index axis, `'flex'` on an uneven linear
   axis, one bar with `'flex'`, a linear index axis with a small gap, `order` with stacks,
   `toggleDataVisibility` without and with stacks, `minBarLength` at the base value, and
   `minBarLength` at a clamped base. All 20 agree. A changed expected value (`toggled`, dataset 0,
   bar 1, `height`) fails. Thus the comparison is effective.

## Findings

### F1 (low, confirmed): `jsOrZero` at `(stack._top || 0) === index` changes `borderSkipped`

- File: `lib/src/controllers/controller.bar.dart:383` and `:385`.
- Claim: upstream `(stack._top || 0) === index` keeps a truthy `_top` as it is, then compares it
  with `===`. `jsOrZero` gives the `ToNumber` of a truthy value. Thus `'0'` and `true` become
  numbers and can equal the dataset index, where upstream gives false. The edge of
  `borderSkipped: 'middle'` then changes. The form comes from the table of ADR 0027 §7 and the
  sketch of PD §5.2. AGENTS.md defines `jsOrZero` as `value || 0` before arithmetic. Here no
  arithmetic follows; `===` follows. The unit report gives this residual as open item 4.
- When it occurs: only a user `_stacks` object in a `parsing: false` item of a chart that is not
  stacked. DC writes a number or `null` into `_top` and `_bottom`. Each stacked update replaces
  the user stack object of the value axis.
- Probe (`probe.mjs`, `review_probe_test.dart`):
  - `F1-topString`: one dataset, `parsing: false`, `borderSkipped: 'middle'`, item
    `{x: 'a', y: 5, _stacks: {y: {_top: '0', _bottom: '0'}}}`. Upstream: `borderSkipped`
    `{top: true, bottom: true}`. Port: `{bottom: true}`.
  - `F1-topTrue`: the same with `_top: true` and `_bottom: true` in dataset 1. Upstream:
    `{top: true, bottom: true}`. Port: `{bottom: true}`.
- Effect: the border edges of the bar, thus pixels only. Chart.js ADR 0009 does not protect it.
- Recommendation: use the form of `actualBase` (ADR 0027 §7, `bar.js:565`):
  `(jsTruthy(top) ? top : 0.0) == index`, with `top = jsGetKey(stack, '_top')`, and the same for
  `_bottom`. The cost is the same. The phase lead corrects the row of ADR 0027 §7 (the ADR is
  proposed) and PD §5.2 in the same change, or accepts the residual in the ADR text.

### F2 (low, confirmed): Dart `==` on `DateTime` stack values is not `===`

- File: `lib/src/controllers/controller.bar.dart:770` (`!stacks.contains(meta.stack)`) and `:855`
  (`stacks.indexOf(name)`). The same form is at `:746` (the `skipNull` find) and `:967`
  (`value == actualBase`).
- Claim: upstream `stacks.indexOf(meta.stack) === -1` compares with `===`. Two JS `Date` objects
  are never `===` unless they are the same object. Dart `List.contains` and `List.indexOf`
  compare with `==`, and `DateTime.==` compares the time value. A `DateTime` is a JS `Date`
  (Chart.js ADR 0024). ADR 0027 §7 says "Dart `==` gives the `===` result for `double`,
  `String`, `bool`, `null` and the `undefined` sentinel" and that Maps and Lists compare by
  identity. `DateTime` is not in that list.
- Probe (`F2-dateStack`): two datasets `[1, 2]` and `[3, 4]`, each with `stack` set to its own
  date at time 0 (`new Date(0)`, `DateTime.utc(1970)`). The chart is stacked, because `meta.stack`
  is defined, and DC stacks both datasets on one key (`${meta.stack}`). Upstream `_getStacks`
  gives two stacks. Thus the bars stand side by side: dataset 0 `x` 94.3728 and 340.0358, dataset
  1 `x` 192.638 and 438.3011, `width` 88.4387. The port gives one stack: both datasets at `x`
  143.5054 and 389.1685, `width` 176.8774.
- Effect: the bar positions, thus the hit element (Chart.js ADR 0009). A `DateTime` stack id is
  rare. With `parsing: false`, `DateTime` index values in the `skipNull` find can give the same
  difference. The review did not probe the sites `:746` and `:967` (plausible there).
- Recommendation: a runtime function for `===` (for example `jsStrictEquals`: `==` for `num`,
  `String`, `bool`, `null` and `undefined`, else `identical`). Use it at the four sites, with
  `any` and `indexWhere` in place of `contains` and `indexOf`. Measure the `skipNull` find before
  the change lands, because it is a hot loop (ADR 0027 §8). Or record the residual in ADR 0027
  §7, next to the `DateTime` note of `jsLessThan`.

### F3 (low, confirmed): the `as String` cast of a parsing key throws where upstream does not

- File: `lib/src/controllers/controller.bar.dart:555` and `:560`.
- Claim: upstream `resolveObjectKey(obj, key)` (`helpers.core.ts:378-380`) first reads
  `keyResolvers[key]`, with the property key `ToString(key)`. The cache has `''`, `'x'` and `'y'`
  from the start, and each string key that a chart used before. Only on a miss does
  `_getKeyResolver(key)` call `key.split` and throw for a key that is not a string. The port
  casts each key to `String` (ADR 0027 §4) and throws a `TypeError` for each such key. The
  doc of `parseObjectData` says that the cast throws "at the `resolveObjectKey` call that throws
  upstream". That is not true for these keys.
- Probe (`F3-emptyArrayKey`, `F3-nestedArrayKey`): `parsing: {yAxisKey: []}` and
  `parsing: {yAxisKey: [['y']]}`. The resolver keeps an empty array and gives the item `['y']` of
  the indexable array `[['y']]`. Upstream: no throw. `[]` gives the key `''`, thus the item
  itself (`y` NaN). `['y']` gives the key `'y'` (`y` 128.55 and 10.2). Port:
  `TypeError: type 'List<Object?>' is not a subtype of type 'String' in type cast` for both.
  (`parsing: {yAxisKey: ['y']}` gives no difference: the resolver picks `'y'` from the array.)
- Effect: a throw (Chart.js ADR 0009). The key values are unusual.
- Recommendation: the form belongs to ADR 0027 §4. It is also in `helpers.config.dart:922` and
  in `_keyOr` of DC. Thus the phase lead decides it for all three sites. One option: a key that
  is not a `String` gives `jsToString(key)` when the key cache of `resolveObjectKey` has that
  string, else the `TypeError`. At least, correct the doc of `parseObjectData` and the text of
  ADR 0027 §4 to name the residual.

### F4 (low, confirmed): two casts that the checklist of IV §4.8 does not allow

- File: `lib/src/controllers/controller.bar.dart:94` (`scale.cache[r'$bar']! as List<double>`) and
  `:827` (`jsGet(chart.data, 'datasets')! as List<Object?>`).
- Claim: IV §4.8 says "Each `as` names a `types.` interface or `DoughnutController`", and IV
  §4.1 item 2 allows a cast to a `types` interface or to a class of the own library or of an
  imported library only. These two casts name `List` types. The unit report lists them as open
  item 3.
- Probe: `grep -n " as " lib/src/controllers/controller.bar.dart` gives the lines 94, 827, 984
  (`as AnyObject`, PD §5.2), 1084 (`as types.VisualElement`), and the `as String` casts at 555
  and 560 (ADR 0027 §4).
- Effect: no behavior difference was found. Only `_getAllScaleValues` writes the key `$bar`.
  The `datasets` value is a List after `initData` in each config that the review tried. The
  doc of `_getAxis` says that a value that is not a List throws, "as the cast does". In
  JavaScript, `for...of` also iterates a String. This text is not exact, but no ported path gives
  a String there.
- Recommendation: W1-int adds the two casts to the allowed list of IV §4.8, with the reason of
  each, or the unit replaces them. No code change is necessary for behavior.

## Not findings

- `{base, head: base}` at `:403`: the record gives NaN for `size` and `center`. Upstream
  `Math.abs(undefined)` is NaN, and no code reads `center` (report, open item 2). Correct.
- `:581` reads `custom.barStart` again, as upstream does. PD §5.2 shows `jsToNumber(value)`. Both
  give the same result, because no statement between the reads writes `_custom`. The literal
  form is the safer one.
- `_isFloatBar` returns a `bool`. Upstream returns the value of `&&`. At `:410` the result goes
  into `enableBorderRadius`. A falsy result of `isFloatBar` makes `||` go to the next operand,
  and a truthy result is `true`. Thus `enableBorderRadius` is a boolean in both.
- `getMaxOverflow` returns `0.0` as `Object?`; `getFirstScaleIdForIndexAxis` returns `String?`
  with Dart `null` for the `undefined` of `shift()`. Each caller passes `?? undefined` to
  `valueOrDefault`, as upstream passes `undefined`.
- The static `defaults` have `<String>['x', 'y', 'base', 'width', 'height']`. The registry copies
  it at the merge, and `core.animations.dart` reads it as a List. `core.animations.defaults.dart`
  uses the same `List<String>` form.
- `inflateAmount` with an `int` (a Dart config literal): `is num` keeps it, and the
  `toNumberProp` setter of `BarElement` takes a `num`.
- This review left no `flutter_tester` process.
