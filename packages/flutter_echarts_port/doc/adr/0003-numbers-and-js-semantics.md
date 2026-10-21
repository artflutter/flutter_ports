# ECharts ADR 0003: Numbers, number strings and JS semantics

- Status: proposed
- Date: 2026-10-21
- Gate: ECharts phase 1. The pilot `util/number.ts` formats numbers with `toFixed`, reads the
  precision from number strings and takes logarithms. The zrender files `core/vector.ts` and
  `core/matrix.ts` of the pilot compute coordinates.
- Related: [Chart.js ADR 0032](../../../flutter_chartjs/doc/adr/0032-js-numeric-semantics.md)
  (the JS numeric rules, the runtime, fdlibm and the reference engine),
  [Chart.js ADR 0034](../../../flutter_chartjs/doc/adr/0034-no-display-only-js-exactness.md) (no
  display-only JS exactness, the protected behavior),
  [Chart.js ADR 0035](../../../flutter_chartjs/doc/adr/0035-third-party-sources.md) (the fdlibm
  copy and its notice),
  [Chart.js ADR 0026](../../../flutter_chartjs/doc/adr/0026-number-formatting-on-package-intl.md)
  (the number text of Chart.js on package:intl, not applied here),
  [D3 ADR 0003](../../../flutter_d3_port/doc/adr/0003-number-to-string.md) (number strings are
  behavior), [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (the
  shared runtime `js_semantics` and the port tools),
  [ECharts ADR 0001](0001-upstream-sources.md) (the pins, `language: js`),
  [ECharts ADR 0002](0002-file-naming-and-layout.md) (paths and port-only folders),
  [ECharts ADR 0004](0004-js-values-classes-and-options.md) (JS values, `null` and `undefined`),
  [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) (the spec harness, the reference
  generators, the text widths of the specs),
  [ECharts ADR 0006](0006-renderer-and-canvas-layer.md) (the renderer, the hit tests),
  [ECharts ADR 0007](0007-environment-host-and-input-events.md) (the device pixel ratio),
  [ECharts ADR 0008](0008-dates-locales-and-formatting.md) (dates and the text of numbers),
  [ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md) (the GeoJSON decode, the heatmap
  pixels), [porting-flow.md](../porting-flow.md) §1.1 and §2.5

## Context

The port translates Apache ECharts 6.1.0 and zrender 6.1.0 line by line (AGENTS.md rules 1 and
2, [ECharts ADR 0001](0001-upstream-sources.md)). The specs, the reference tests and the users
expect the numbers and the strings of a JavaScript engine. Dart number operations give other
results in many places. Some Dart results also differ between the VM, dart2js and dart2wasm.

Three earlier decisions give the rules:
- [Chart.js ADR 0032](../../../flutter_chartjs/doc/adr/0032-js-numeric-semantics.md) gives the
  JS runtime, the fdlibm ports, the reference engine, the sort, the clock, the translation table
  and tool 3.
- [Chart.js ADR 0034](../../../flutter_chartjs/doc/adr/0034-no-display-only-js-exactness.md)
  gives the principle. The port emulates JavaScript only where the result changes protected
  behavior.
- [D3 ADR 0003](../../../flutter_d3_port/doc/adr/0003-number-to-string.md) (proposed) makes a
  string that a public function returns into behavior. It adds `jsToFixed`, `jsToStringRadix` and
  other number methods to `js_semantics`.

A Chart.js ADR or a D3 ADR binds only its own port. This ADR states how the ECharts port applies
them. It also names the new runtime symbols that ECharts needs.

**Method of the counts.** The counts below are occurrences of a pattern in `src/**/*.ts` at the
pins (`grep -o`). They include comments. "E" is ECharts. "Z" is zrender. The understand notes of
phase 0 hold the script (Evidence).

### Number strings

ECharts builds its number text by hand. It calls the number methods of JavaScript and joins
strings.
- **`toFixed`** has 13 occurrences: 10 E in 7 files, 3 Z in 1 file. The 10 E occurrences are 9
  calls and the comment `util/number.ts:234`. The 3 Z occurrences are calls:

  | Site | What the string reaches |
  |---|---|
  | `echarts src/util/number.ts:235` (`round`) | `+x` of the string. The ticks of the interval scale pass through it (`scale/Interval.ts:257`, `scale/helper.ts:113-114`) |
  | `echarts src/chart/funnel/FunnelSeries.ts:149` | `params.percent` of the label formatter |
  | `echarts src/component/marker/markerHelper.ts:86` | a marker coordinate |
  | `echarts src/component/marker/MarkLineView.ts:117` | a mark line value |
  | `echarts src/component/visualMap/PiecewiseModel.ts:453,457` | the precision loop and the split step of the pieces |
  | `echarts src/component/visualMap/VisualMapModel.ts:401` | the text of a visual map label |
  | `echarts src/component/tooltip/TooltipHTMLContent.ts:129-130` | CSS pixel strings of the HTML tooltip |
  | `zrender src/svg/helper.ts:92-94` | the shadow values of the SVG output |

  Each computed precision has a clamp. `round` clamps it to [0, 20]
  (`echarts src/util/number.ts:233`, `TO_FIXED_SUPPORTED_PRECISION_MAX` at `:37`).
  `markerHelper.ts:84`, `MarkLineView.ts:117`, `PiecewiseModel.ts:445` and
  `VisualMapModel.ts:401` clamp it to at most 20. The visual map precision is a user option
  (`VisualMapModel.ts:352`). Thus it can be negative or not integral.
- **`x + ''` and `'' + x`** have 98 occurrences: 78 E in 42 files, 20 Z in 8 files. An example is
  `addCommas` (`echarts src/util/format.ts:32-39`, `x + ''` at `:36`). Its comma regex then
  works on the digits.
- **`toString`.** `getPrecisionSafe` reads the precision from `val.toString()`, also in the
  exponent form `3.4e-12` (`echarts src/util/number.ts:297-308`). `toHex` writes
  `(...).toString(16)` (`zrender src/tool/color.ts:391`). `Calendar.ts:408` writes
  `range.toString()` of a number or a string.
- **The text widths reach the layout.** zrender measures each label string. The bounding rect of
  a text is its measured width times its line height. Label layout and the axis label interval
  read these rects. Thus a different digit can hide another label.
  [ECharts ADR 0006](0006-renderer-and-canvas-layer.md) gives the measure route.
  [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) gives the widths of the specs.

**Dart number text.** Probe P1 of D3 ADR 0003 compared Dart and JavaScript for 38 doubles. It ran
on an arm64 Node.js, thus it is indicative only. `toStringAsFixed`, `toStringAsExponential` and
`toStringAsPrecision` gave the JS strings, except for −0. The plain `toString()` gave `1.0` where
JavaScript gives `1`. For `round`, JavaScript gives `(-0).toFixed(2)` as `'0.00'`. Thus `round`
returns +0. Dart gives `(-0.0).toStringAsFixed(2)` as `'-0.00'`. Its parse gives −0. The ported
spec `util/number` compares with Jest `toEqual`. `toEqual` tells +0 from −0
([ECharts ADR 0005](0005-spec-harness-and-reference-tests.md)). The `addSafe` cases take −0 as an
input (`echarts test/ut/spec/util/number.test.ts:438-455`).

### Parse, coercion and equality

- `parseFloat` has 71 occurrences: 12 E in 5 files, 59 Z in 6 files. zrender parses colors and
  SVG attributes with it.
- `parseInt` has 17 occurrences: 2 E, 15 Z. One E occurrence is a comment
  (`echarts src/chart/bar/BarView.ts:818`). The E call is
  `parseInt(splitNumber, 10)` (`PiecewiseModel.ts:448`). The Z calls take the radix 10 or 16.
  Examples are `zrender src/tool/color.ts:101,191,201,207,216`, `src/canvas/helper.ts:102` (a CSS
  size such as `'500px'`) and `src/graphic/helper/parseText.ts:576`.
- The global `isNaN` has 178 occurrences: 156 E in 69 files, 22 Z in 12 files. The
  global `isFinite` has 60: 48 E in 25 files, 12 Z in 4 files.
- `numericToNumber` (`echarts src/util/number.ts:774-780`) compares `parseFloat(val)` with `val`
  through the loose `valFloat == val` (`:777`). This is the only loose equality of both trees
  other than the `== null` tests. JavaScript applies `ToNumber` to a string operand and
  `ToPrimitive` to an array operand there. The spec `util/number` tests many raw values against it
  (`number.test.ts:966-`).
- ECharts and zrender test `== null` or `!= null` at 1,062 sites. These tests are not loose
  equality in this sense. [ECharts ADR 0004](0004-js-values-classes-and-options.md) maps them.

### Typed arrays

- `Float32Array` has 59 occurrences: 37 E in 11 files, 22 Z in 5 files.
  - `createFloat32Array` (`echarts src/util/vendor.ts:62`) gives the point buffers of
    `layout/points.ts:65`, of the large bars (`layout/barGrid.ts:418-420`) and of
    `chart/line/LineView.ts:132`. `barGrid.ts:420` also stores the data indices of the large bars
    as float32.
  - `PathProxy` stores the path commands in a `Float32Array` (`zrender src/core/PathProxy.ts:375`,
    `:400`). `toStatic` turns a plain array of more than 11 values into a `Float32Array`
    (`:473-488`).
  - The hit tests read these values. `Path.contain` reads the `PathProxy` data
    (`zrender src/graphic/Path.ts:393-424`). The winding-number tests of `contain/path.ts`
    follow the path commands. Thus the conversion of a coordinate to float32 can change the hit
    element.
- `Float64Array` (22), `Int32Array` (20), `Uint32Array` (20), `Uint16Array` (13) and
  `Uint8Array` or `Uint8ClampedArray` (17) occur only in ECharts.
  - `DataStore` selects the chunk class by the dimension type
    (`echarts src/data/DataStore.ts:43-56`). `float` and `time` give `Float64Array`. `int` gives
    `Int32Array`. `ordinal` and `number` give a plain `Array`.
  - The index arrays are `Uint16Array` up to a raw count of 65535, else `Uint32Array`
    (`DataStore.ts:119-121`). `cloneChunk` copies a chunk with its own constructor (`:123-129`).
  - A write of a number into an integer typed array applies `ToInt32`, `ToUint32` or
    `ToUint16`. NaN gives 0. A value outside the range wraps modulo 2^32 or 2^16.
  - `HeatmapLayer` writes pixel values into a `Uint8ClampedArray`
    (`echarts src/chart/heatmap/HeatmapLayer.ts:113-116,169-172`).
- Two sorts have no comparator. `axisStatisticsMetricsImpl.ts:135` sorts a `Float64Array` view
  (`subarray`, `:128`) in numeric order. `universalTransition.ts:526` sorts an array of string
  keys in the default string order.

**Dart typed lists.** `Float32List`, `Float64List`, `Int32List`, `Uint32List`, `Uint16List` and
`Uint8ClampedList` of `dart:typed_data` store values as the JS typed arrays do on the VM, dart2js
and dart2wasm. A store into an integer list takes an `int`. `double.toInt()` throws on NaN and on
the infinities. On the VM and dart2wasm, it saturates at 2^63 − 1 for a large value (D3 ADR 0003,
probe P1). `ToInt32` takes the value modulo 2^32.

### Transcendental and other `Math` builtins

| Builtin | Occurrences (E / Z) | Notes |
|---|---|---|
| `Math.sin`, `mathSin` | 107 (49 / 58) | |
| `Math.cos`, `mathCos` | 105 (51 / 54) | `zrender src/core/matrix.ts:95-96` (`rotate`) is in the pilot |
| `Math.atan2`, `mathAtan2` | 21 (13 / 8) | `zrender src/contain/path.ts:192` (arc winding) |
| `Math.log`, `mathLog` | 15 (11 / 4) | `mathLog(x) / mathLN10` is the ECharts `log10` (`echarts src/util/number.ts:317-318,359-360,588`). `mathLog(val) / mathLog(base)` gives the log scale ticks (`scale/helper.ts:184`) |
| `Math.log10` | 1 (1 / 0) | a comment only (`scale/helper.ts:183`) |
| `Math.pow`, `mathPow` | 43 (25 / 18) | integer exponents in `util/number.ts`. `Math.pow(x, 1/3)` in the cubic roots (`zrender src/core/curve.ts:97-106`) |
| `Math.acos` | 4 calls | `zrender src/core/curve.ts:115` (cubic roots), `graphic/helper/roundSector.ts:240` (through `mathACos`, `:8`), `tool/path.ts:27`, `echarts src/label/labelGuideHelper.ts:499` |
| `Math.asin` | 5 calls | `echarts src/util/symbol.ts:113` (the `pin` symbol path), `chart/graph/circularLayoutHelper.ts:166` (layout), `zrender src/animation/easing.ts:224,248,272` |
| `Math.tan` | 7 calls | `zrender src/core/Transformable.ts:315,317` (skew), `tool/convertPath.ts:40`, `tool/parseSVG.ts:865,869`, `echarts src/label/labelGuideHelper.ts:443,507` |
| `Math.atan` | 2 calls | `echarts src/util/layout.ts:413`, a comparison with `1e-9` |
| `Math.exp`, `log2`, `hypot`, `cbrt`, the hyperbolic functions | 0 | |

- `cubicRootAt` (`zrender src/core/curve.ts:54-134`) takes `Math.pow` with the exponent 1/3 and
  `Math.acos`. `windingCubic` calls it for the fill hit test (`contain/path.ts:39`).
- `Transformable.ts:315-317` takes `Math.tan` of the skew angles. The transform of an element
  maps the hit point into the local space (`Path.ts:394`, `graphic/Displayable.ts:295-313`).
- `matrix.rotate` (`zrender src/core/matrix.ts:95-96`) builds each rotated transform.
- `Math.LN10` and `Math.PI` are the doubles of `math.ln10` and `math.pi`.

### `Math.random`

`Math.random` occurs on 18 lines of 11 files: 12 E lines in 7 files, 6 Z lines in 4 files. One E
line is a comment (`echarts src/util/component.ts:37`). `echarts src/util/number.ts:58` exports
the builtin as `mathRandom`. `getRandomIdBase` calls that alias (`:795`).
- **Layouts.** `jitter.ts:97,101` moves scatter points. `forceHelper.ts:102-103,200` gives the
  start positions and the push of the force layout. `axisBreakHelperImpl.ts:263` gives the
  zigzag of an axis break.
- **Draws at load.** Six module-level initializers draw a value when the bundle loads:
  `util/component.ts:27`, `util/clazz.ts:161`, `util/model.ts:756,1321` (through
  `getRandomIdBase`), `zrender src/core/WeakMap.ts:1` and `src/graphic/Displayable.ts:18`. The
  values name ids and hidden keys.
- **Other draws.** `zrender src/canvas/Painter.ts:380` draws a token at each refresh.
  `TooltipView.ts:649,787` draws ticket strings. `tooltipMarkup.ts:521` draws an id base for each
  instance. `zrender src/tool/color.ts:571-573` is the public `random()` color.
- The spec case `getPrecision_equal_random` draws 1,500 values in the spec itself
  (`number.test.ts:388-400`).

### Other facts

- **No `Intl`.** Both trees have 0 occurrences of `Intl.` and of `toLocaleString`. The only
  `toLocale` call is `toLocaleLowerCase` of an XML node name (`zrender src/tool/parseSVG.ts:613`).
  It is a case map of a string, not a number format.
- **Sorts.** 26 calls of `.sort` take a comparator. V8 sorts them with a stable TimSort. The
  display list does not use a builtin sort. `Storage` sorts it with the zrender port of
  node-timsort (`zrender src/Storage.ts:84`, `src/core/timsort.ts`).
- **`HashMap`.** `maybeNativeMap` gives a native `Map` in every reference engine
  (`zrender src/core/util.ts:737-743`). `Map` compares keys with SameValueZero. Thus NaN is one
  key. +0 and −0 are also one key. `'1'` and `1` are two keys. Dart `==` is false for two NaN.
- **`JSON.parse`** occurs once (`echarts src/coord/geo/GeoJSONResource.ts:167`). It gives each
  number as a JS number. Dart `jsonDecode` gives an `int` for an integer literal. `JSON.stringify`
  writes log text (`util/log.ts:105`), an error message (`chart/lines/LinesSeries.ts:218`) and a
  cache key (`zrender src/svg/cssEmphasis.ts:65`).
- **The reference build.** `third_party/echarts` tracks `dist/echarts.js` at the pin. The build
  targets ES3 (`echarts tsconfig.json:3`). The dist exposes `echarts.number` with 18 functions of
  `util/number.ts` (`src/export/api/number.ts:20-40`, `src/export/api.ts:48`).

### The shared runtime

[ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (proposed) puts the JS
runtime of two or more ports into the pure package `js_semantics`. Stage 1 copies the closure of
the generic files of `packages/flutter_chartjs/lib/src/js/` (item 5). At `75178b5`, the closure had
11 files. Now `js_math.dart:30-32` also imports `fdlibm_trig.dart`, the source of `jsSin` and
`jsCos` (Chart.js ADR 0032 §3). ADR 0008 names only the D3 and Chart.js ports. Its item 6 rule
"New runtime code for D3 goes into new files of `js_semantics`" does not name ECharts.
[ECharts ADR 0008](0008-dates-locales-and-formatting.md) already adds four new files to
`js_semantics` by that rule.

## Decision

### 1. Protected behavior in ECharts terms

The principle of Chart.js ADR 0034 applies to the ECharts port. For the same platform inputs,
these results must equal the results of the reference engine on every target:
- the ticks: their values, their count and the labels that show after the overlap rules
- the display-list order of `Storage.getDisplayList` (`zrender src/Storage.ts:84`). This order is
  the draw order and the hit order.
- the hit element of an event, of `containPixel` or of a query
- the layouts: the box layout, the series layouts and the label layout
- the item order, for example of the legend, the tooltip and a `HashMap`
- the merged option that `getOption()` returns (`echarts src/core/echarts.ts:893`)
- a throw: whether code throws, and where
- the values that public members return. Examples are `convertToPixel`
  (`echarts.ts:1138-1175`), `convertFromPixel` (`:1176-1188`), `containPixel` (`:1189`),
  `getOption` and, once ported, `renderToSVGString` (`:939`).
- any other value that reaches one of these results or a discrete decision

The platform inputs are the text measures, the clock, the time zone and the device pixel ratio.
[ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) gives the text measures of the specs.
[ECharts ADR 0007](0007-environment-host-and-input-events.md) gives the device pixel ratio.

**The zrender geometry.** zrender draws and hit-tests the same data. Chart.js keeps its hit tests
apart from its draw code. Thus the rule of a protected site of Chart.js ADR 0032 §3 gives a
longer list in zrender:
- A value is protected when it reaches the `PathProxy` data, a shape property, a transform or a
  bounding rect of an element. The `buildPath` code of each shape, `Transformable`, `matrix` and
  the `contain/` files are protected sites.
- A value is display only when it reaches only a canvas call, a gradient, a pattern, a shadow, a
  line dash or an `easing` value. The canvas painter files (`zrender src/canvas/`) are display
  only, except for the values that they also give to `PathProxy`.
- The `easing` functions are display only by the precedent of Chart.js ADR 0032 §3. Phase 3
  classifies each site of `zrender src/animation/easing.ts` at its port.
- An element can be `silent`. The port does not classify a site by such a run-time state.

**Number strings are behavior.** The rule of D3 ADR 0003 section 1 applies to every number string
of ECharts and zrender:
- The tick values pass through `toFixed` in `round` (`util/number.ts:235`).
- A label string gives a measured width. The width reaches the label layout and the label
  interval.
- `getOption()` returns the values of `round`.
- Ids and `HashMap` keys contain number strings.
- `renderToSVGString` returns the number strings of the SVG painter (phase 10).

A display-only value can still change a digit of a protected string. Such a spec case skips with
`'diverges: js-semantics-dart-math'`, as D3 ADR 0003 section 5 states. The first such case adds the
row to [differences.md](../differences.md). No such case is known now.

### 2. The rules of Chart.js ADR 0032

The ECharts port applies these sections of Chart.js ADR 0032. The runtime is `js_semantics`
(section 10).
- §1, the JS runtime: ported files call it where upstream calls a builtin or relies on an
  implicit JS conversion.
- §2, the reference engine: an x64 build of Node.js v24.12.0. Reference data never come from a
  browser or from an arm64 Node.js.
- §3, the transcendental builtins, with the protected sites of section 1 (section 6).
- §4, the exact builtins: `jsMax`, `jsMin`, `jsSquare` and the `(e ?? 0)` rule.
- §5, the sort: `jsSort` for each comparator sort (section 8).
- §6, the clock `jsDateNow`. [ECharts ADR 0008](0008-dates-locales-and-formatting.md) gives the
  clock sites.
- §7, the translation table and the forbidden forms.
- §8, tool 3 and `// js-ok` (section 11).

§9 and Chart.js ADR 0026 do not apply. Chart.js ADR 0026 formats the numbers of
`Intl.NumberFormat` with package:intl, as display text. ECharts calls no `Intl` function. It
writes its number text with `toFixed`, `x + ''` and string operations. The runtime gives these
strings exactly. The strings are behavior (section 1). Thus the ECharts port has no
package:intl dependency and no copy of `js_intl.dart`.

### 3. Number strings

| JavaScript | Dart |
|---|---|
| `x + ''`, `'' + x`, `String(x)`, a template literal with a number | `jsNumberToString(x)` for a number. `jsToString(v)` for a value of any type |
| `x.toFixed(p)` | `jsToFixed(x, p)` of D3 ADR 0003 section 3 |
| `x.toString(16)` of an integral number | `jsToStringRadix(x, 16)` of D3 ADR 0003 section 3 |
| `val.toString()` of a value that can be a number | `jsToString(val)` |
| `+s` of a number string | `jsToNumber(s)` |

- `jsToFixed` must take the digit count as a JS number. It applies `ToIntegerOrInfinity`, as
  `Number.prototype.toFixed` does. Thus NaN gives 0. 1.7 gives 1. A count below 0 throws a
  `RangeError`, as in V8. `VisualMapModel.ts:401` can pass such counts from a user option.
- A count from 21 to 100 throws a `RangeError` in the port. V8 gives a string. Each computed count
  of ECharts has a clamp to 20 (Context). The other sites pass a literal.
- `round` keeps its upstream form: `jsToNumber(jsToFixed(jsToNumber(x), precision))`. Thus
  `round(-0, 2)` returns +0, as in V8.
- Ported files must not call `toStringAsFixed`, `toStringAsExponential`, `toStringAsPrecision`,
  `toRadixString` or `toString()` on a number (D3 ADR 0003 section 4).

### 4. Parse, coercion and equality

| JavaScript | Dart |
|---|---|
| `parseFloat(s)` | `jsParseFloat(s)` |
| `parseInt(s, radix)` | `jsParseInt(s, radix)` (new) |
| `Number(v)`, `+v` | `jsToNumber(v)` |
| global `isNaN(v)`, `isFinite(v)` | `jsIsNaN(v)`, `jsIsFinite(v)` |
| `zrUtil.eqNaN(v)` (`v !== v`) | `v is double && v.isNaN` |
| `a == b` with a number operand and another value (`util/number.ts:777`) | `jsLooseEquals(a, b)` (new) |
| `a == null`, `a != null` | `a == null`, `a != null` ([ECharts ADR 0004](0004-js-values-classes-and-options.md)) |

- `jsParseInt(Object? value, [Object? radix])` gives the result of the global `parseInt` as a
  `double`. It applies `ToString` to `value` and `ToInt32` to `radix`. It skips the white space at
  the start and reads a sign. It strips `0x` or `0X` for the radix 0 or 16. It reads the longest
  prefix of digits. A radix outside [2, 36] and a string with no digit give NaN.
- `jsLooseEquals(Object? a, Object? b)` is the abstract operation `IsLooselyEqual`. Two numbers
  compare as numbers. NaN is not equal to NaN. +0 equals −0. A number and a string compare
  after `ToNumber` of the string. A boolean converts to a number first. A `List`, a `Map`, a
  function or a date converts with `ToPrimitive`. For these Dart values, `ToPrimitive` gives
  `jsToString` of the value. `null` and the `undefined` sentinel equal each other and no other
  value. Two objects compare by identity.

### 5. Typed arrays

- Ported code uses `dart:typed_data` for each JS typed array: `Float32List`, `Float64List`,
  `Int32List`, `Uint32List`, `Uint16List` and `Uint8ClampedList`. `createFloat32Array` gives a
  `Float32List`. `PathProxy.data` is a `Float32List` after `toStatic`, as upstream.
- A store of a `double` into an integer list goes through `jsToInt32`, `jsToUint32` or
  `jsToUint16`, then `toInt()`. `jsToUint32` and `jsToUint16` are new. They return the integral
  `double` of `ToUint32` and `ToUint16`, as `jsToInt32` does. A store of a Dart `int` that is in
  range writes it as it is.
- A read from an integer list gives an `int`. Ported code calls `toDouble()` where upstream uses
  the value as a number. An index stays an `int`.
- A `Uint8ClampedArray` holds pixel values only. These values are display only.
  [ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md) gives the form of the heatmap
  pixels. A store there converts with `clamp` and `round()` and carries
  `// js-ok: display only (ECharts ADR 0003)`.
- `subarray` is `sublistView`. The view shares the buffer, as upstream.
- `cloneChunk` and `clone` (`zrender src/core/util.ts:100-111`) keep the class of a typed list.
  The `Ctor === Array` tests become type tests. Test the typed classes first. A `Float64List` is
  also a `List<double>`.
- `typedArray.sort()` with no comparator is `jsTypedArraySort(list)` (new). It gives the numeric
  order, with −0 before +0 and NaN last.

### 6. Transcendental builtins

- **`Math.log`** is `jsLog` at every site (new). `jsLog` calls `ieee754Log` of `fdlibm_log.dart`
  (a part of the stage 1 copy). Thus `mathLog(x) / mathLN10` and `mathLog(val) / mathLog(base)`
  give the bits of the reference engine. `mathLN10` is `math.ln10`. The alias
  `export const mathLog = Math.log` becomes `const double Function(double) mathLog = jsLog;`, as
  Chart.js ports `log10`.
- **`Math.atan2`** is `jsAtan2` at every site, as in Chart.js ADR 0032 §3.
- **`Math.sin` and `Math.cos`** are `jsSin` and `jsCos` at a protected site of section 1. At a
  display-only site, they are `dart:math` `sin` and `cos` with a `double` operand and
  `// js-ok: display only (ECharts ADR 0003)`. `matrix.rotate` of the pilot is a protected site.
- **`Math.acos`, `Math.asin` and `Math.tan`** arrive as fdlibm ports with their first protected
  caller:

  | Builtin | Dart | Netlib files | First protected caller | Phase |
  |---|---|---|---|---|
  | `Math.acos` | `jsAcos` | `e_acos.c` | `zrender src/core/curve.ts:115` | 2 |
  | `Math.tan` | `jsTan` | `s_tan.c`, `k_tan.c` | `zrender src/core/Transformable.ts:315-317` | 2 |
  | `Math.asin` | `jsAsin` | `e_asin.c` | `echarts src/util/symbol.ts:113` | 4 |

  - The change that ports the caller copies the netlib fdlibm 5.3 files unchanged into
    `third_party/fdlibm/`. It annotates them in the fdlibm table of `REUSE.toml`. The SunPro
    notice stays in the `LICENSE` of the package that holds the Dart port. After stage 1, that
    package is `js_semantics` (ADR 0008 item 2). The fdlibm entry of its `tool/port_sources.yaml`
    gets the new targets (Chart.js ADR 0035).
  - `s_tan.c` calls `__ieee754_rem_pio2`. The port calls the port of `e_rem_pio2.c` in
    `fdlibm_trig.dart`.
  - The port follows the rules of Chart.js ADR 0032 §3 for fdlibm ports. Each port has a
    reference generator and a bit-for-bit test. The test compares with the reference engine. If a
    line of V8 differs from netlib, the port follows V8 and marks the line.
  - A display-only site before the port, for example `easing.ts:224`, calls `dart:math` with
    `// js-ok: display only (ECharts ADR 0003)`.
- **`Math.atan`** is `jsAtan` (new) at a protected site. `jsAtan` calls `atan` of
  `fdlibm_atan.dart`. `util/layout.ts:413` compares two angles with `1e-9`. This is a discrete
  decision.
- **`Math.pow`** follows Chart.js ADR 0032 §3. It is `math.pow` with `double` operands and
  `// js-ok: <reason>`. `Math.pow(x, 2)` is `jsSquare(x)`. The integer exponents of
  `util/number.ts` (`:410`, `:465`, `:570`, `:594`, `:629`) give the reference bits on each target.
  The exponent 1/3 of `curve.ts:97-106` is a protected site with no reference bits (Open 1).
- `Math.sqrt`, `Math.abs`, `Math.floor`, `Math.ceil`, `Math.round`, `Math.max` and `Math.min`
  follow the table of Chart.js ADR 0032 §7.
- Bit operators follow Chart.js ADR 0032 §7. `x | 0` is `jsToInt32(x)`. The zrender dirty flags
  (`REDRAW_BIT` and others) are `int` fields with `int` constants. dart2js gives unsigned results
  for `|`, `&`, `>>` and `~`. Where the sign of a result matters, call `toSigned(32)`.

### 7. `Math.random`

- Every run-time `Math.random()` call is `jsMathRandom()` (new). The six draws at load of the
  Context are the exception ([ECharts ADR 0004](0004-js-values-classes-and-options.md) §12). No
  other ported site calls `dart:math` `Random`. The alias `mathRandom` (`util/number.ts:58`)
  becomes `const double Function() mathRandom = jsMathRandom;`.
- `jsMathRandom()` returns the next value of the current source. A value is in [0, 1).
- `setJsMathRandomSource(double Function()? source)` (new) replaces the source. `null` restores
  the default source. The default source is `Random().nextDouble` of `dart:math`.
- `JsSeededRandom` (new) is a port-only generator with a seed. It is xorshift32 with the shifts
  13, 17 and 5 (Marsaglia 2003). Each step masks the state to 32 bits. A value is the state
  divided by 2^32. Thus each target gives the same values. A seed of 0 becomes 1.
- The tests and the reference generators install a `JsSeededRandom`.
  [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) gives the seed and the reseed
  points. The generators define the same algorithm in JavaScript. They replace `Math.random`
  before the dist loads, because `util/number.ts:58` keeps the builtin that it reads at load.
- **The draws at load.** The six module-level draws (ECharts ADR 0004 §12) do not read
  `jsMathRandom` in Dart. The generator installs the seeded source before the dist loads. The
  dist makes the six draws from it at load. The generator reseeds after the load. Thus both
  sides start the seeded sequence at the reseed.
- These rules are translation rules. They need no `DIVERGES` marker and no row.

### 8. Sorts and Map keys

- A sort with a comparator is `jsSort(list, compare)` (Chart.js ADR 0032 §5).
- `array.sort()` with no comparator is `jsDefaultSort(list)` (new). It sorts by the code units of
  `jsToString` of each item. It is stable. The `undefined` sentinel goes last. Dart `null`
  compares as `'null'`. The only site sorts strings (`universalTransition.ts:526`).
- The display list keeps the zrender port of `timsort.ts`. It is not a builtin sort.
  [ECharts ADR 0001](0001-upstream-sources.md) gives its notice.
- **Map keys.** The port of `new Map()` in `maybeNativeMap` (`zrender src/core/util.ts:741`) is a
  `LinkedHashMap` with `equals: jsSameValueZero` and `hashCode: jsSameValueZeroHash` (new). Both
  functions apply SameValueZero. NaN equals NaN. +0 equals −0. A `String` and a number are never
  equal. This is a rule, not a class. Each port of a JS `Map` with number keys uses it.

### 9. JSON

- `JSON.parse` is `jsJsonDecode` (new). It gives each JSON number as a `double`. The literal
  `-0` gives −0. Keys keep their source order in the `Map`. `jsObjectKeys` gives the JS order at
  each read (Chart.js ADR 0032 §7). The first caller is `GeoJSONResource.ts:167` (phase 8,
  [ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md)).
- `JSON.stringify` stays `jsonEncode` with `// js-ok: <reason>` at the three sites of Context.
  Their strings are log text, an error message and a cache key. No protected result reads their
  digits.

### 10. Runtime placement and the new symbols

- The ECharts port depends on `js_semantics`. It is the third port of ADR 0008. The rules of ADR
  0008 item 6 apply to ECharts as to D3. New generic runtime code goes into new files of
  `js_semantics`. A change to a file with a Chart.js copy changes both copies in one commit.
- ECharts-only runtime goes into `packages/flutter_echarts_port/lib/src/js/`. ECharts-only runtime
  models a value or an API that only ECharts reads. Each symbol of this ADR is an ECMAScript
  builtin. Thus each one goes into `js_semantics`.
- If ECharts phase 1 comes before stage 1 of ADR 0008, the new files wait in
  `packages/flutter_echarts_port/lib/src/js/`. Stage 1 moves them. This is the rule of
  [ECharts ADR 0008](0008-dates-locales-and-formatting.md).
- The file names below are the proposal. The change that adds the first symbol of a file can
  select another name. It does not use a name of ECharts ADR 0008 (`js_date_object.dart`,
  `js_date_zone.dart`, `js_table_zone.dart` and `js_string.dart`).

| Symbol | JavaScript | File | First ECharts caller (phase) |
|---|---|---|---|
| `jsToFixed`, `jsToStringRadix` | `toFixed`, `toString(radix)` | the number-method file of D3 ADR 0003 section 3 | `util/number.ts:235` (1), `zrender src/tool/color.ts:391` (2) |
| `jsParseInt` | `parseInt` | `js_conversions.dart` | `zrender src/tool/color.ts:101` (2) |
| `jsLooseEquals` | `IsLooselyEqual` (`==`) | `js_conversions.dart` | `util/number.ts:777` (1) |
| `jsToUint32`, `jsToUint16` | `ToUint32`, `ToUint16` | `js_conversions.dart` | `data/DataStore.ts` (2), the canvas size of ECharts ADR 0006 (3) |
| `jsTypedArraySort` | `%TypedArray%.prototype.sort()` | `js_sort_extra.dart` | `coord/axisStatisticsMetricsImpl.ts:135` (6) |
| `jsDefaultSort` | `Array.prototype.sort()` | `js_sort_extra.dart` | `animation/universalTransition.ts:526` (9) |
| `jsSameValueZero`, `jsSameValueZeroHash` | SameValueZero of `Map` keys | `js_same_value.dart` | `zrender src/core/util.ts:741` (1) |
| `jsLog`, `jsAtan` | `Math.log`, `Math.atan` | `js_math_extra.dart` | `util/number.ts:317` (1), `util/layout.ts:413` (4) |
| `jsAcos`, `jsAsin`, `jsTan` | `Math.acos`, `Math.asin`, `Math.tan` | `js_math_extra.dart`, with the ports `fdlibm_asin_acos.dart` and `fdlibm_tan.dart` | section 6 (2, 4, 2) |
| `jsMathRandom`, `setJsMathRandomSource`, `JsSeededRandom` | `Math.random` | `js_random.dart` | `util/number.ts:795` (1) |
| `jsJsonDecode` | `JSON.parse` | `js_json.dart` | `coord/geo/GeoJSONResource.ts:167` (8) |

- Each new file starts with the port-only marker of `js_semantics`:
  `// Original code, not ported from any project: <reason>.` (ADR 0008 item 4). Each fdlibm port
  starts with one `// Ported from fdlibm 5.3 <file> (SunPro, Sun Microsystems, Inc.).` line for
  each C file.
- A symbol arrives with its first caller. A symbol with no ECharts caller in a phase waits.
- The stage 1 copy gives the other symbols of this ADR: `jsToNumber`, `jsParseFloat`, `jsIsNaN`,
  `jsIsFinite`, `jsToString`, `jsNumberToString`, `jsRound`, `jsToInt32`, `jsMax`, `jsMin`,
  `jsSquare`, `jsLog10`, `jsAtan2`, `jsSin`, `jsCos`, `numberEpsilon`, `jsSort` and
  `jsObjectKeys`.

### 11. Tool 3 and the review

- The ECharts config of tool 3 (ADR 0008 item 8) has two `js` projects: `Apache ECharts` and
  `zrender`. [ECharts ADR 0001](0001-upstream-sources.md) sets `language: js` for both entries.
  Tool 3 examines only the files of a `js` project
  (`packages/flutter_chartjs/tool/src/js_semantics.dart:236-240` at commit `4d50cd8`). Thus it
  examines the ported files of both trees and the ported specs.
- Tool 3 flags the forms of Chart.js ADR 0032 §8 and the number methods of D3 ADR 0003 section 4.
  Its messages name ECharts ADR 0003 (item 8, value 7).
- The reviewer examines these forms, because tool 3 does not find them:
  - a call of `dart:math` `Random` in a ported file, other than the two draws at load of
    ECharts ADR 0004 §12
  - a call of `jsonDecode` in a ported file
  - a store of a `double` into an integer typed list without the conversion of section 5
  - a `List<double>` in place of a `Float32Array` or a `Float64Array`
  - the class of each `sin`, `cos`, `acos`, `asin` and `tan` site: protected or display only
  - the interpolation of an `Object?` value that can hold a number, `List.join` and
    `StringBuffer.write` with numbers (Chart.js ADR 0032 §8)
- The module status text in `doc/status.yaml` (from phase 2) names the display-only `sin` and
  `cos` sites of the module.

### 12. Tests and reference data

- The pure ported specs run on the VM, with dart2js and with dart2wasm from phase 1
  ([ECharts ADR 0005](0005-spec-harness-and-reference-tests.md)).
- The phase 1 exit compares the number strings of `util/number.ts` with the reference engine. A
  generator in `packages/flutter_echarts_port/tool/reference/` runs `echarts.number` of the dist.
  It writes `round`, `getPrecision`, `getPrecisionSafe`, `quantityExponent`, `nice` and
  `numericToNumber` results for many inputs. The inputs include ±0, NaN, ±Infinity, ties, the
  1e21 bound, subnormals and the `e` notation. `addSafe` and `getAcceptableTickPrecision` are not
  in `echarts.number`. ECharts ADR 0005 decides how a generator reaches them.
- Each new `js_semantics` symbol has a test in `js_semantics`. The expected values come only from
  the reference engine. The generators stop unless `process.arch` is `x64`.
- `JsSeededRandom` has a test that compares its first values with the JavaScript twin of the
  generators.
- The tests of `jsSameValueZero` use NaN, ±0, `int` and `double` keys of equal value, and `'1'`
  against `1`.

## Alternatives considered

- **`List<double>` for `Float32Array`.** Rejected. A `double` keeps 53 bits. The path data, the
  large point buffers and the large data indices then hold other values than upstream. The hit
  tests read these values (`Path.ts:393-424`). Thus a point near an edge can hit another element.
- **package:intl for the number text (Chart.js ADR 0026).** Rejected. ECharts calls no `Intl`
  function. Its number text comes from `toFixed` and `Number::toString`. The runtime gives these
  strings exactly. A package:intl formatter gives other strings. The tick values pass through
  `toFixed` (`util/number.ts:235`).
- **`dart:math` for every builtin.** Rejected. Chart.js ADR 0032, Context, shows the mismatches
  of `log10`, `atan2`, `sin` and `cos`. A plain `toStringAsFixed` in `round` gives −0 where V8
  gives +0. The ticks of `quantityExponent` take `floor` of `mathLog(val) / mathLN10`
  (`util/number.ts:588`). The difference between targets also breaks the reference tests on some
  CI legs.
- **The fdlibm `sin` and `cos` at every zrender site.** Not chosen. The canvas painter and the
  `easing` functions give no protected result. Chart.js ADR 0032 measured about 6 ns more for
  each call on AOT.
- **A port of seedrandom.** Rejected. No upstream image is compared
  ([ECharts ADR 0005](0005-spec-harness-and-reference-tests.md)). Thus the port does not need the
  sequence of the upstream visual tests. A port adds an MIT notice and code that no user needs.
- **The V8 `Math.random` with `--random-seed`.** Rejected. The Dart side then needs the V8
  xorshift128+ generator, its seed hash and the order of its value cache. These are internals of
  V8 13.6. They can change with the engine.
- **A `JsHashMap` class.** Rejected. A `LinkedHashMap` with two functions gives the key rules of
  `Map`. The port of `HashMap` keeps its upstream structure around it.
- **The new runtime in `packages/flutter_echarts_port/lib/src/js/` only.** Rejected for the
  generic symbols. ADR 0008 item 1 puts the runtime of two or more ports into `js_semantics`. D3
  also needs `Math.random`, `parseInt` and the inverse trigonometric builtins.
- **No `Math.random` hook.** Rejected. The jitter and force layouts read it. A reference test of
  these layouts needs the same values on both sides.

## Consequences

- A ported file keeps the upstream lines. Only the builtin calls change.
- The ticks, the labels and the number strings of ECharts give the V8 strings on the VM, dart2js
  and dart2wasm. The phase 1 pilot tests this with the 24 cases of `util/number` and the reference
  strings.
- zrender hit tests read float32 path data on all three targets, as upstream does.
- More zrender sites call `jsSin` and `jsCos` than in Chart.js. The phase 3 benchmark records
  their cost in `doc/performance.md`, which phase 3 creates.
- `js_semantics` gets the new files of section 10 with their tests and generators. The fdlibm copy
  gets four C files in phases 2 and 4.
- The ECharts port has no package:intl dependency.
- The specs and the reference tests of random layouts get the same values in Dart and in Node.js.
  Both sides start the seeded sequence at the reseed (section 7).
- [porting-flow.md](../porting-flow.md) §2.5 summarizes this ADR. Its list of new symbols names
  each symbol of section 10.

## Open

1. **`Math.pow` with the exponent 1/3.** `cubicRootAt` (`curve.ts:97-106`) feeds the fill hit
   test. V8 calls the platform C `pow`. No pure-Dart form gives its bits on every target
   (Chart.js ADR 0032, Open 3). The port keeps `math.pow` with `js-ok`. A 1-ulp root can change a
   hit only for a point on the curve. Phase 2 probes this site against the reference engine.
2. **The V8 forms of `acos`, `asin` and `tan`.** The port expects V8 13.6 to compute them with
   the fdlibm code of `base::ieee754`. The bit-for-bit test of each port confirms or refutes this.
   A refuted case needs a new decision before the port lands.
3. **The reference engine.** On 2026-10-21, the machine of the maintainer has only an arm64
   Node.js v24.12.0. The darwin-x64 build must be installed before the first generator runs.
4. **`jsToFixed` and D3.** D3 ADR 0003 does not state the type of the digit count. Section 3 needs
   a JS number with `ToIntegerOrInfinity`. Stage 1 of ADR 0008 or the first ECharts caller adds
   this form in `js_semantics`. The D3 work agrees to it.

## Evidence

- The counts come from `count.sh` of the phase 0 understand notes
  (`scratchpad/echarts-phase0/understand/`, outside the repository) and from a recount with
  `grep -o` over `src/**/*.ts` of `third_party/echarts` at `c5a48f5f` and `third_party/zrender` at
  `32b66867`. The notes `jsvalues.md` and `renderer.md` hold the site lists.
- The sites of this ADR were read at the pins. The line numbers are the lines at the pins.
- Probe P1 and its limits: D3 ADR 0003, Context and Evidence.
- The protected `sin` and `cos` sites and their cost in the Chart.js port: Chart.js ADR 0032,
  Context and Consequences.
