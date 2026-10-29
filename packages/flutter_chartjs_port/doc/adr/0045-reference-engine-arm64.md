# Chart.js ADR 0045: Reference engine on arm64

- Status: proposed
- Date: 2026-10-28
- Supersedes: [Chart.js ADR 0032](0032-js-numeric-semantics.md) on acceptance
- Related: [Chart.js ADR 0002](0002-js-numeric-semantics.md) (the first numeric rules),
  [Chart.js ADR 0010](0010-js-numeric-semantics.md) (the numeric rules that Chart.js ADR 0032
  superseded),
  [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (the JS values in Dart, the
  `undefined` sentinel),
  [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (the first rule of no display-only
  JS exactness),
  [Chart.js ADR 0017](0017-element-properties.md) (`jsOrZero`, the WebIDL conversions),
  [Chart.js ADR 0019](0019-animation.md) (`jsOwnPropertyNames`, `jsTypeof`, `jsMapForEach`,
  the promise jobs),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) (the class values),
  [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) (the frozen options),
  [Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) (the number formatter, its
  guards and its known differences from V8),
  [Chart.js ADR 0027](0027-parsed-data.md) (`jsAdd`, `jsLessThan`, `jsGetKey`, `jsGetIndex`,
  `jsSetIndex`, `JsStringList`),
  [Chart.js ADR 0030](0030-controller-test-strategy.md) (`jsSplice`, the hit queries of the
  controller tests),
  [Chart.js ADR 0033](0033-radial-scale-centers.md) (the center reads of `getPointPosition`),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (no display-only JS exactness, the
  protected behavior),
  [Chart.js ADR 0035](0035-third-party-sources.md) (the fdlibm copy and its notice),
  [Chart.js ADR 0032](0032-js-numeric-semantics.md) (the decision that this ADR restates with the
  arm64 engine),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [performance.md](../performance.md) §13.8 (the figures of `jsSin` and `jsCos`)

## Context

The port translates Chart.js v4.5.1+7169e651 line by line (AGENTS.md rules 1 and 2). The
upstream specs and image fixtures assert exact numbers, strings and pixels. A JavaScript engine
computed those values. Dart number operations give other results in many places. Some Dart
results also differ between the VM, dart2js and dart2wasm.

Chart.js ADR 0002 gave the first set of rules. Chart.js ADR 0010 (accepted 2026-10-19) superseded
it. Chart.js ADR 0010 put `Math.sin` and `Math.cos` on `dart:math`, because no chart behavior
depended on their last bit. Phase 7 (controllers) found two cases where the last bit of
`Math.sin` changes the hit element. The hit element is protected behavior (Chart.js ADR 0009,
and its successor Chart.js ADR 0034). Chart.js ADR 0032 (accepted 2026-10-21) stated the
complete decision with `jsSin` and `jsCos`, and superseded Chart.js ADR 0010.

Chart.js ADR 0032 §2 named one reference engine: the x64 build of Node.js v24.12.0, on Apple
silicon under Rosetta 2. On 2026-10-24, the Mac of the port runs macOS 27 without Rosetta 2. The
maintainer says that Rosetta 2 will not come back, and asks to move the reference engine to the
arm64 build of Node.js. Commit `1d271cd` (2026-10-28) removed the x64 checks of the generators.
This ADR states the complete decision of Chart.js ADR 0032 with the arm64 engine, and supersedes
Chart.js ADR 0032 on acceptance. The Decision keeps the section numbers and titles of Chart.js
ADR 0032. These parts change:
- Section 2 names the arm64 engine, and keeps the x64 data of the fdlibm builtins (the fdlibm
  data).
- Section 3 gives the bits of the fdlibm data as the target of the fdlibm ports, and the `js-ok`
  texts name this ADR. A new fdlibm port needs an x64 engine.
- Section 10 adds the engine pins of the tests.
- Context adds the check of the arm64 engine. Alternatives, Consequences, Open (items 5 and 6)
  and Evidence add the engine items.
The other text is the text of Chart.js ADR 0032.

Other ADRs decide some parts of the JS runtime of section 1:
- the `undefined` sentinel: Chart.js ADR 0006
- `jsOrZero` and the WebIDL conversions of `js_webidl.dart`: Chart.js ADR 0017
- `jsOwnPropertyNames`, `jsTypeof`, `jsMapForEach` and the promise jobs: Chart.js ADR 0019
- the class values of `js_class.dart`: Chart.js ADR 0020
- `JsFreezable`, `jsObjectFreeze` and `jsObjectIsFrozen`: Chart.js ADR 0021
- `jsAdd`, `jsLessThan`, `jsGetKey`, `jsGetIndex`, `jsSetIndex` and `JsStringList`: Chart.js ADR
  0027
- `jsSplice`: Chart.js ADR 0030
- the number formatter of `js_intl.dart`, its guards and its known differences from V8: Chart.js
  ADR 0026

**Naive translation.** The research of 2026-10-16 and the phase 1 pilot compared a naive Dart
translation with V8 13.6 on the VM, dart2wasm and dart2js:

| Builtin | Naive Dart | With `lib/src/js` |
|---|---|---|
| `Math.round` (25 sites) | 116/834 mismatches, throws on NaN | 0 |
| `%` | 150/318 mismatches | 0 |
| `log10` as `log(x)/ln10` | spec loop fails for 168/308 exponents | 0 (fdlibm) |
| `Math.atan2` as `dart:math` `atan2` | 34,032/303,640 mismatches on the VM, browser results on the web | 0 (fdlibm) |
| logarithmic `generateTicks` | 310/613 pairs wrong | 0 |
| `toString` | `'1.0'` on VM and wasm | 0 |

**Other differences.**
- Dart `floor()` and `ceil()` return an `int` and throw on NaN. `pow` on two `int` values
  overflows on the VM and dart2wasm. `double.nan.clamp(0, 1)` is 1. On dart2js, `1.0 is int` is
  true.
- `dart:math` `max` and `min` give the JS results for `double` operands (0 mismatches on 16,400
  bit-pattern pairs). On dart2wasm, the generic functions box both operands. In the dart2wasm
  profiles, this boxing took 29-53% of three benchmark cases.
- On Flutter 3.44.9, `List.sort` is not stable above 32 elements on the VM, in dart2wasm and in
  DDC. The user comparators of the legend and tooltip plugins expect a stable sort.
- JavaScript tests a number with ToBoolean in `if (x)`, `!x` and `x || d`. Dart has no implicit
  conversion to `bool`.
- The `FakeAsync` zone of flutter_test fakes `clock.now()` of `package:clock`, but not
  `DateTime.now()`.
- On dart2wasm, `math.pow(d, 2.0)` costs about 13 ns, and `d * d` costs about 1.6 ns.

**fdlibm.** "V8 semantics" needs one named engine. V8 on arm64 contracts fdlibm to fused
multiply-add. Chrome 155 computes `Math.log`, `Math.log10`, `Math.atan2`, `Math.sin` and
`Math.cos` another way. `dart:math` calls the host C library on the VM and the browser on the web.
All of these differ from V8 on x64 in the last bit for some inputs. The netlib fdlibm 5.3 ports
of the pilot match x64 V8 bit for bit on all three targets. netlib `e_atan2.c` does not have the
V8 line `m &= 1`. dart2js makes the results of `>>` and `|` unsigned.

**`Math.sin` and `Math.cos` in Node.js.** Node.js v24.12.0 builds V8 with gyp, without the
define `V8_USE_LIBM_TRIG_FUNCTIONS`. Thus its `Math.sin` and `Math.cos` are `base::ieee754::sin`
and `cos`, with the statements and constants of netlib fdlibm 5.3. On x64, the compiler makes no
fused multiply-add of them. On arm64, it contracts them to fused multiply-add, and the last bit
differs for some inputs. The GN
build of Chrome and d8 uses a copy of the glibc `s_sin.c` (LGPL-2.1). V8 is not correctly
rounded. It differs from the correctly rounded result on 3.1% of 60,000 random inputs. Against
x64 V8, `dart:math` `sin` and `cos` differ by 1 ulp on a part of the inputs:
- about 4% on AOT macOS arm64
- 0.5% in dart2wasm and dart2js
- 3.3% of chart angles in Chrome 155
- 0.7% on the Pixel 8a

Each target of the port has a different library.

**The arm64 engine.** The check of 2026-10-28 ran the generators of
`packages/flutter_chartjs_port/tool/reference/` at commit `1d271cd` on Node.js v24.22.1 for
darwin-arm64 (V8 13.6.233.17-node.58, ICU 78.3, CLDR 48.0). It did not run
`log10_reference.mjs` and `trig_reference.mjs`: on arm64, their data differ from the committed x64
data in the last bits and in the signs of NaN results. It did not run `text_metrics/`, which uses
headless Chrome and not Node.js. The other 45 generators wrote 46 data files:
- Each generator gave the same bytes in a second run.
- 42 files are equal to the committed x64 data, apart from the header lines that name the Node.js
  version, the V8 version and the architecture. `atan2_reference.dart` is one of them: V8 on
  arm64 gave the x64 bits of `Math.atan2` for all 3000 inputs.
- `intl_reference.dart` has equal data. Its header also names ICU and CLDR (ICU 77.1 and CLDR
  47.0 on x64, ICU 78.3 and CLDR 48.0 on arm64). No formatted string changed.
- 3 files have a 1-ulp difference in a value. The doughnut and the pie data each have one `lineTo`
  y value of the arc path, a display-only site of `Math.sin` and `Math.cos` (for example
  `106.43887951120573` becomes `106.43887951120576`). The probable cause is the fused
  multiply-add of the arm64 fdlibm. The logarithmic data have two results of `getValueForPixel`,
  which calls `Math.pow(10, x)` with a fractional `x` (`3000.000000000001` becomes
  `3000.0000000000014`). V8 calls the platform C `pow` there, and the probable cause is the
  `pow` of the platform. No x64 run isolated the two causes.
- With the 46 arm64 files, the 53 test files that read them gave 4595 passes and 1 skip. The 47
  failures were the engine pins of the tests (`'v24.12.0'` against `'v24.22.1'`). Each data
  comparison passed: the tests compare draw-call numbers and scale values with a tolerance of
  1e-9, or a relative 1e-12 above 1e3.

**Which last bits change behavior.**
- `floor(log10(x))` selects the ticks of a logarithmic scale. Below −π/2, the last bit of
  `Math.atan2` changes the angle by 2π, and thus the result of an arc hit test.
- The last bit of `Math.sin` can change the hit element. A query without `intersect` reads the
  center of each arc (`getCenterPoint`: `x + Math.cos(halfAngle) * halfRadius`). On an equal
  distance, the first element wins. A 1-ulp change of one sine breaks such a tie. Two cases
  showed this:
  - CI run 39544591156 failed on Windows only. The chart is a doughnut with the data `[1, '3']`.
    The query is `index` with axis `y` at the midpoint of two arc centers. The arcs have the
    half angles `-0.7853981633974483` and `2.356194490192345`. V8 gives
    `sin(-0.7853981633974483)` = `-0.7071067811865475`. The only 1-ulp change that gives the CI
    result is `-0.7071067811865476`. This is the inferred MSVC UCRT value.
  - The U-pie review found a pie with the index 3 hidden where `sin(3.665191429188092)` decides
    the tie. V8 gives `-0.4999999999999997`. The macOS libm gives `-0.4999999999999998`.
- `lib/` (without the port-only canvas layer) had 72 calls of `sin` and `cos`. A mirror of the
  port moved each result by 1 ulp. A move of the 52 calls that reach only a canvas call or an
  easing value failed 0 of 6,184 cases. A move of the other 20 calls failed 15 or 16 cases
  (doughnut, pie, polar area, radar, `scale.radialLinear`).
- By default, V8 13.6 calls the platform C `pow` (`--use-std-math-pow`). Thus no pure-Dart
  `pow` gives the reference bits.
- `math.pow(10.0, k)` gives the V8 bits for each integer `k` from -340 to 320 on the VM, dart2js
  and dart2wasm.
- `helpers.easing.tests.js` rounds each result to 1e-8. Eight expected values lie on a rounding
  tie or 1 ulp from one. For example, `easeInElastic(0.2)` gives the expected `-0.00195313` only
  because `Math.sin` returns `0.5000000000000001`.

## Decision

### 1. JS runtime

An unexported library in `packages/flutter_chartjs_port/lib/src/js/` represents the JS builtins and
the JS value operations. Ported files call it where upstream calls a builtin or relies on an
implicit JS conversion. For example, `helpers.math.dart` mirrors the upstream
`export const log10 = Math.log10` as `const double Function(double) log10 = jsLog10;`.

| File | What it gives |
|---|---|
| `js_math.dart` | `numberEpsilon`, `jsRound`, `jsToInt32`, `jsMax`, `jsMin` (with `jsMaxMinCompare`), `jsSquare`, `jsLog10`, `jsAtan2`, `jsSin`, `jsCos`: the `Math` and `Number` builtins whose Dart forms give other results |
| `js_number.dart` | `jsToNumber`, `jsParseFloat`, `jsIsNaN`, `jsIsFinite`, `jsTruthy`, `jsToString`, `jsNumberToString`: `ToNumber`, `parseFloat`, the global `isNaN` and `isFinite`, `ToBoolean`, `ToString` and `Number::toString` (radix 10). Also `jsOrZero`, `jsAdd` and `jsLessThan` |
| `js_array.dart` | `jsSort`, `jsObjectKeys`, `jsArrayIndex`, `JsProxyObject`: `Array.prototype.sort` on `mergeSort`, the key order of `Object.keys`, the canonical array index, a JS `Proxy` as a `Map`. Also `jsOwnPropertyNames`, `jsSetIndex`, `JsStringList` and `jsSplice` |
| `js_object.dart` | `jsGet`, the property read `object[key]`, with the marker of the `differences.md` row `js-semantics-resolver-objects`. Also `jsGetKey`, `jsGetIndex`, `JsFreezable`, `jsObjectFreeze`, `jsObjectIsFrozen` and `jsTypeof` |
| `js_function.dart` | `JsFunction`, `jsIsFunction`, `jsCall`, `jsCall1`, `jsMaxArity`: the call of a function value with the argument count, the `undefined` padding and `this` |
| `js_undefined.dart` | `Undefined`, `undefined`: the JS value `undefined` |
| `js_date.dart` | `jsDateNow`: `Date.now()` on `clock.now()` of `package:clock` (section 6) |
| `js_intl.dart` | `jsNumberFormat`, `jsNumberFormatLocale`, `JsNumberFormat`, `maxFractionDigits`: `Intl.NumberFormat` on package:intl (section 9) |
| `js_class.dart` | `JsClass`, `jsConstruct`, `jsAssign`, `jsObjectClass`: a JS class as a value |
| `js_map.dart` | `jsMapForEach`: `Map.prototype.forEach` while the callback changes the Map |
| `js_promise.dart` | `jsEnqueuePromiseJob`, `jsRunWithMicrotaskCheckpoint`, `jsPromiseAll`: the promise jobs and `Promise.all` |
| `js_webidl.dart` | `canvasStyle`, `canvasNumber`, `canvasKeyword`, `canvasLineDash`: the WebIDL conversions of the Canvas 2D setters |
| `fdlibm_log.dart` | `ieee754Log`, `ieee754Log10`: the port of fdlibm 5.3 `e_log.c` and `e_log10.c` |
| `fdlibm_atan.dart` | `atan`, `ieee754Atan2`: the port of fdlibm 5.3 `s_atan.c` and `e_atan2.c`, plus the V8 line `m &= 1` |
| `fdlibm_trig.dart` | `ieee754Sin`, `ieee754Cos`: the port of fdlibm 5.3 `s_sin.c`, `s_cos.c`, `k_sin.c`, `k_cos.c`, `e_rem_pio2.c`, `k_rem_pio2.c` and `s_scalbn.c` |

- Each `js_*.dart` file is port-only. It starts with
  `// Original code, not ported from Chart.js: <reason>.` An fdlibm file starts with one
  `// Ported from fdlibm 5.3 <file> (SunPro, Sun Microsystems, Inc.).` line for each C file.
- The runtime is a pure layer. It imports neither `dart:ui` nor `package:flutter`. It compiles for
  every Flutter platform and for web WebAssembly.
- Port-only runtime code can use any implementation that gives the JS results on the VM, dart2js
  and dart2wasm. For example, `jsNumberToString` has an integer path below 2^53, `jsToNumber` has
  a plain-decimal path before its RegExp, and `jsCall` makes a dynamic call on the VM. Tests pin
  the results on all three targets.

### 2. Reference engine

The reference engine is V8 13.6 (13.6.233.17-node.58) as Node.js v24.22.1 for darwin-arm64
builds it, with ICU 78.3. Use the official darwin-arm64 build of Node.js v24.22.1 (from
nodejs.org, or installed by nvm).

The **fdlibm data** are an exception. `log10_reference.dart`, `atan2_reference.dart` and
`trig_reference.dart` in `test/port/js/` are the bit target of `jsLog10`, `jsAtan2`, `jsSin` and
`jsCos`. Their target is fdlibm 5.3 compiled without fused multiply-add: V8 13.6
(13.6.233.17-node.37) as Node.js v24.12.0 for x64 builds it.
- The committed fdlibm data stay as they are. They name Node.js v24.12.0, V8
  13.6.233.17-node.37 and `x64`.
- `log10_reference.mjs`, `atan2_reference.mjs` and `trig_reference.mjs` are frozen. They stop
  unless `process.arch` is `x64`. Only an x64 build of Node.js v24.12.0 writes these files again.
  An x64 build runs on an x64 machine (for example an x64 runner of CI) or under an x86-64
  emulator.
- The arm64 engine is not a source for these files, also where its output is equal today
  (`atan2`, see Context).
- In this ADR, "the reference bits" of `Math.log10`, `Math.atan2`, `Math.sin` and `Math.cos` are
  the bits of the fdlibm data.

The other rules:
- Reference data never come from a browser.
- Each reference run writes the Node.js version, the V8 version and the architecture into its
  output. A run that reads ICU data also writes the ICU and CLDR versions.
- The other generators in `packages/flutter_chartjs_port/tool/reference/` run on the reference
  engine. They do not stop on another architecture. The test of each data file pins the Node.js
  version and the architecture of its data (section 10).
- `number_to_string_reference.mjs` writes `number_to_string_reference.dart` in `test/port/js/`
  on the reference engine. Do not edit the generated files by hand.
- The expected JS values of the other port tests also come only from the reference engine.
  Examples are the special values of the `jsSquare` test, the `jsNumberToString` boundary cases
  and the V8 strings that `js_intl_test.dart` compares with package:intl. An expected value of
  `Math.log`, `Math.log10`, `Math.atan2`, `Math.sin` or `Math.cos` at a protected site (section
  3) has the bits of the fdlibm data, not of the arm64 engine. Take it from the fdlibm data or
  from the Dart fdlibm port, which equals them.
- **A changed value.** A generator that runs again on the reference engine can give data that
  differ from the committed data in a value, not only in the header lines. Before the commit,
  the porting lead examines each changed value:
  - The value comes only from a display-only site (section 3), or from the last bit of
    `Math.pow`, and its test compares it with a tolerance: write the new data.
  - The value reaches protected behavior, or its test compares it exactly, and the cause is the
    fused multiply-add of the arm64 fdlibm: keep the committed data of that file, freeze its
    generator as the fdlibm generators, and record the case in Open 5.
  - Another cause: find it before the commit. A changed value that is not explained is not
    written.
- The text-metric generator (`tool/reference/text_metrics/`) measures in headless Chrome. This
  section does not apply to it.

### 3. Transcendental builtins

**Protected sites.** A protected site is a ported call site whose result can reach protected
behavior. Protected behavior is a layout, a scale (its size, its ticks, its label capacity), an
element property, a hit test, a value that a public member returns or a discrete decision. A
call whose result reaches both the canvas and protected behavior is a protected site. A draw
position (a pixel) is not protected, also when a public member returns it.

- **`Math.log10` and `Math.atan2`** are `jsLog10` and `jsAtan2` at every site. These are
  pure-Dart ports of netlib fdlibm 5.3. Ported code must not call `dart:math` `log` or `atan2`
  for them.
- **`Math.sin` and `Math.cos` at a protected site** are `jsSin` and `jsCos`. They call
  `ieee754Sin` and `ieee754Cos` of `fdlibm_trig.dart`. The VM (JIT and AOT), dart2js and
  dart2wasm give the bits of the fdlibm data of section 2. At the pin, the protected sites are
  the ports of these upstream functions:
  - `fit` and `_tickSize` of `core.scale`: the axis size of rotated labels, the layout boxes, the
    chart area and the ticks that `autoSkip` shows.
  - `relativeLabelSize` of `scale.linearbase`: the tick spacing of `generateTicks`.
  - `computeTickLimit` of `scale.linear`: the tick limit.
  - `_getLabelSize` of `scale.time`: the label capacity, thus the time unit and the step.
  - `updateLimits` (in `fitWithPointLabels`) and `getPointPosition` of `scale.radialLinear`:
    `drawingArea`, `xCenter`, `yCenter`, the radar point positions and the radial hit tests.
  - `getRatioAndOffset` of `controller.doughnut`: the radius and the offsets of the arcs when the
    circumference is below 2π.
  - `getCenterPoint` of `element.arc`: the queries without `intersect` and the tooltip position.
- **`Math.sin` and `Math.cos` at a display-only site** are `dart:math` `sin` and `cos` with a
  `double` operand. The result of a display-only site reaches only a canvas call or an easing
  value of `helpers.easing`. A canvas call is, for example, a path point, a translate or a label
  draw position. The site carries `// js-ok: display only (Chart.js ADR 0045)`. At the pin, these
  are the arc path and draw code of `element.arc` (`clipSelf`, `rThetaToXY`, `pathFullCircle`,
  `pathArc`, `draw`), `drawPointLegend` of `helpers.canvas` (through `drawPoint`), the easing
  functions of `helpers.easing`, and the rotated label position of `_computeLabelItems` of
  `core.scale`.
  - The label position is a pixel that `getLabelItems()` returns. Its comment is
    `// js-ok: a label pixel of getLabelItems (Chart.js ADR 0045)`.
  - A line that also has a `Math.pow` call names both reasons in one `js-ok` comment.
  - The easing sites also carry the marker of the row
    [`js-semantics-dart-math`](../differences.md#js-semantics-dart-math). The ported easing spec
    allows one unit of 1e-8 at the rounding ties.
  - The port-only canvas layer (`lib/src/canvas/`) calls `dart:math` without a comment.
- **Ported test code** follows the same rule. A spec that computes an input or an expected value
  of a protected function with `Math.sin` or `Math.cos` calls `jsSin` or `jsCos`. At the pin,
  these are the `inRange` points of `test/specs/element.arc_test.dart` and the data values of
  `test/specs/controller.line_test.dart`. A port-only test that mirrors a protected function,
  for example `test/port/scales/scale.linearbase_test.dart`, also calls `jsSin` or `jsCos`.
- **`Math.pow`** is `dart:math` `pow` with `double` operands and a `js-ok` comment. Its last bit
  can differ from V8 and between the targets. `dart:math` `pow` gives 1 for `pow(1, NaN)` and
  `pow(±1, ±Infinity)`. JavaScript gives NaN there. `Math.pow(x, 2)` is the exception: it is
  `jsSquare(x)` (section 4).
  - `pow` also stays on `dart:math` at a protected site. The tick code of the logarithmic scale,
    `niceNum` of `helpers.math` and the factors of `scale.linearbase` call `pow(10.0, k)` with an
    integer `k`. By the probe of Context, these calls give the reference bits on every target.
- **Other transcendental builtins** (`tan`, `asin`, `acos`, `atan`, `exp`, `log`) arrive with
  their first ported caller. At a protected site, port the builtin from netlib fdlibm 5.3, with a
  reference generator and a bit-for-bit test. At a display-only site, call `dart:math` with
  `double` operands and add `// js-ok: <reason>`. The one exception at the pin is `asin` of
  `calculateLabelRotation`. It keeps `dart:math` with `js-ok`, because the label sizes that it
  reads come from the text layout of the platform (Open 3).

**fdlibm ports.**
- A new fdlibm port gets its reference data from an x64 build of Node.js v24.12.0 (section 2).
  Until an x64 engine is available, a new fdlibm builtin has no reference generator, and its
  port waits (Open 5).
- Port from the netlib files in `third_party/fdlibm/`. Do not port from V8's `ieee754.cc`,
  because it adds a V8 BSD notice.
- Where V8 differs from netlib, follow V8. Mark each added line with a comment that names the
  difference. Pin the line with a test. The only such line now is `m &= 1` in
  `fdlibm_atan.dart`. V8 has no added line in `sin`, `cos` and their kernels.
- Every arithmetic statement of netlib stays, in its order. Each C function stays a function, for
  example `sin` and `cos` stay two functions with the four `switch (n & 3)` cases.
- Read `__HI(x)` and `__LO(x)` through a `ByteData`. Call `toSigned(32)` where C relies on a
  signed `>>` or `|` result. Write a C bit test such as `(lx|-lx)>>31` as `lx != 0`.
- On a common path, a test of the high word `ix` against a constant `H` can be an exact
  comparison of `|x|` with `D(H)`, the double whose high word is `H` and whose low word is 0
  (`ix < H` is `|x| < D(H)`). A cleared low word can be an exact `floorToDouble` with a power of
  two. A NaN fails each comparison, so the code tests `!(|x| <= double.maxFinite)` first. Each
  such form has the C test as a comment, and the bit-for-bit test covers each bound. The cold
  paths keep the `ByteData` reads.
- A C helper with an exact Dart form is not ported. `s_floor.c`, `s_fabs.c` and `s_copysign.c`
  are `floorToDouble()`, `abs()` and a sign test. A port note says so.

### 4. Exact and correctly rounded builtins

`Math.sqrt`, `Math.abs`, `Math.sign`, `Math.max`, `Math.min` and the arithmetic operators are
exact or correctly rounded.
- For `Math.sqrt`, `Math.abs`, `Math.sign` and the operators, ported code calls `dart:math`, the
  `double` member or the operator.
- **`Math.max` and `Math.min` with `double` operands** are `jsMax` and `jsMin` of
  `lib/src/js/js_math.dart`. They give the JS results on every target: NaN if an operand is NaN,
  +0 for `jsMax` of +0 and -0 in either order, and -0 for `jsMin` of +0 and -0 in either order.
  - On dart2wasm (`const bool.fromEnvironment('dart.tool.dart2wasm')`, exported as
    `jsMaxMinCompare`), they compare the operands in their own code:
    - max: `a > b ? a : a < b ? b : a == b ? (a == 0 ? a + b : a) : NaN`
    - min: `a < b ? a : a > b ? b : a == b ? (a == 0 && b.isNegative ? b : a) : NaN`
  - On the VM and dart2js, they return `math.max(a, b)` and `math.min(a, b)`.
  - Both functions carry `@pragma('vm:prefer-inline')` and `@pragma('wasm:prefer-inline')`.
- **`Math.max` and `Math.min` with `int` operands** (list indexes) are `dart:math` `max` and
  `min`. With a literal operand, write the type argument `<int>`, for example
  `math.max<int>(0, distance)`.
- **`Math.pow(x, 2)`** is `jsSquare(x)` of `lib/src/js/js_math.dart`. `jsSquare(x)` returns
  `x * x`. It carries `@pragma('vm:prefer-inline')`, `@pragma('dart2js:prefer-inline')` and
  `@pragma('wasm:prefer-inline')`. On the x64 engine of Chart.js ADR 0032, `Math.pow(x, 2)` and
  `x * x` gave the same bits on 23 million inputs. This rule is exact. It is not a display-only
  exception.
- **`ToNumber` of a `double?` value whose `null` is JS `null`** is `(e ?? 0)`, not
  `jsToNumber(e)`. `Point.x` and `Point.y` of `geometric.dart` are such values. A copied JS
  `undefined` is already `double.nan` there, and `(e ?? 0)` keeps it NaN. The rule does not apply
  to a `double?` member whose `null` is JS `undefined` (the optional members of `SplinePoint` use
  `e ?? double.nan`), or to an `Object?` value (`jsToNumber`).

The sites of `jsSquare` and `(e ?? 0)` are `distanceBetweenPoints` and `getAngleFromPoint`
(`helpers.math.dart`), `isPointInArea` (`helpers.canvas.dart`), `pointInLine` and
`steppedInterpolation` (`helpers.interpolation.dart`) and `_monotoneAdjust` (`helpers.curve.dart`).
`jsMax`, `jsMin`, `jsSquare` and `(e ?? 0)` are translation rules. They need no
`DIVERGES(chartjs)` marker and no `differences.md` row.

### 5. Sort

`jsSort(list, compare)` is an adapter of a few lines. It changes the result of `compare` to its
sign, with NaN as 0, as `Array.prototype.sort` does. Then it calls `mergeSort`. It gives the V8
order for a consistent comparator only.
- `collection: ^1.19.1` is a direct dependency. Tool 1 allows
  `package:collection/collection.dart` in `lib/` and in the pure layers only with
  `show mergeSort`.
- Ported files sort only through `jsSort`, because only `jsSort` changes the comparator result as
  `Array.prototype.sort` does. `sorted` calls `List.sort`. `sortBy`, `sortByCompare` and
  `sortRange` call `quickSortBy`. These sorts are not stable. `insertionSort`, `sortedBy` and
  `sortedByCompare` are stable, but they do not change the comparator result.
- A `List.sort` call stays only where every order is the same, for example on distinct finite
  numbers. The site carries `// js-ok: <reason>`.

### 6. Clock

`jsDateNow()` returns `clock.now().millisecondsSinceEpoch` as a `double`. It replaces each
`Date.now()` call of `core.animator`, `core.animation`, `core.animations` and `scale.time`.
- Inside `testWidgets`, `tester.pump` moves this clock. Thus the animation specs run in fake time.
- Chart animations ignore `timeDilation`, as upstream does.
- `clock: ^1.1.2` (Apache-2.0) is a direct dependency, and the package copies no code of it. Tool
  1 allows `package:clock/clock.dart` in `lib/` and in the pure layers.

### 7. Translation rules

Numbers are `double`. An `int` occurs only as a list index, after a finiteness test.

| JavaScript | Dart |
|---|---|
| `a % b` | `a.remainder(b)` |
| `Math.floor(x)`, `Math.ceil(x)` | `x.floorToDouble()`, `x.ceilToDouble()` |
| `Math.round(x)` | `jsRound(x)` |
| `x \| 0` | `jsToInt32(x)` |
| `Math.sqrt(x)`, `Math.abs(x)`, `Math.sign(x)` | `math.sqrt(x)`, `x.abs()`, `x.sign` |
| `Math.max(a, b)`, `Math.min(a, b)` (numbers) | `jsMax(a, b)`, `jsMin(a, b)` |
| `Math.max(a, b, c)` | `jsMax(a, jsMax(b, c))` |
| `Math.max(...xs)`, `Math.min(...xs)` | `xs.fold(double.negativeInfinity, jsMax)`, `xs.fold(double.infinity, jsMin)` |
| `Math.max(i, j)`, `Math.min(i, j)` with list indexes | `math.max(i, j)`, `math.min(i, j)` with `int` operands, `math.max<int>(0, i)` with a literal |
| `Math.pow(x, 2)` | `jsSquare(x)` |
| `Math.pow(x, y)` with another `y` | `math.pow(x, y)` with `double` operands and `// js-ok` |
| `Math.sin(x)`, `Math.cos(x)` at a protected site | `jsSin(x)`, `jsCos(x)` |
| `Math.sin(x)`, `Math.cos(x)` at a display-only site | `math.sin(x)`, `math.cos(x)` with `// js-ok: display only (Chart.js ADR 0045)` |
| `Math.log10(x)`, `Math.atan2(y, x)` | `jsLog10(x)`, `jsAtan2(y, x)` |
| `ToNumber(e)` of a `number \| null` value held as `double?` (JS `null` is Dart `null`) | `(e ?? 0)` |
| `if (x)`, `!x`, `x \|\| d` | `jsTruthy(x)`, `!jsTruthy(x)`, `jsTruthy(x) ? x : d` (for a `double` `x`, `x != 0 && !x.isNaN` is the same test) |
| `'' + n`, `String(n)`, a template literal with a number | `jsNumberToString(n)`, or `jsToString(v)` for a value of any type |
| `+s`, `Number(s)`, `parseFloat(s)` | `jsToNumber(s)`, `jsParseFloat(s)` |
| global `isNaN(v)`, `isFinite(v)` | `jsIsNaN(v)`, `jsIsFinite(v)` |
| `Number.EPSILON` | `numberEpsilon` |
| `array.sort(compare)` | `jsSort(array, compare)` |
| `Object.keys(o)`, and `for-in`, `Object.assign` or a spread over an object | `jsObjectKeys(o)` |
| `Date.now()` | `jsDateNow()` |

**ToBoolean.** ToBoolean is false for these `Object?` values: `null`, the `undefined` sentinel,
`false`, `0`, `-0`, NaN and `''`. It is true for every other value, also for an empty `List` or
`Map`. A test of `x || d` on such a value tests the raw value, not a converted number. `jsTruthy`
gives this result.

**Forbidden forms.** Ported files must not use these forms:
- Do not use `num.clamp` for `_limitValue`. Write `jsMax(min, jsMin(max, value))`, as
  `helpers.math.dart` does.
- Do not call `DateTime.now()`. Call `jsDateNow()`.
- Do not test `is int` on option or data values.
- Do not call the Dart `round()`, `roundToDouble()`, `floor()`, `ceil()`, `truncate()`, `%` or
  `toString()` on numbers.
- Do not interpolate a number into a string, for example `'${size}px'`. On the VM and dart2wasm,
  `'${12.0}'` is `'12.0'`. In JavaScript, `12 + 'px'` is `'12px'`. Use `jsNumberToString`.
- Do not call `dart:math` `max` or `min` with `double` or `num` operands. Call `jsMax` or `jsMin`.
- Do not call `dart:math` `sin` or `cos` at a protected site. Call `jsSin` or `jsCos`.

### 8. Tool 3 and `js-ok`

Tool 3 (`tool/check_js_semantics.dart`, `check:js-semantics`) is the JS-semantics check of
[porting-flow.md](../porting-flow.md) §4. It examines each `lib/` and `test/` file whose header
block names a `js` project of `packages/flutter_chartjs_port/tool/port_sources.yaml`, or a project
that `port_sources.yaml` does not list. The `js` projects are Chart.js, `@kurkle/color` and
chartjs-test-utils. Tool 3 does not examine the port-only files and the fdlibm ports. Tool 3 flags
these forms:
- `.round()`, `.roundToDouble()`, `.floor()`, `.ceil()`, `.truncate()`, `.clamp(`, `%`, `is int`
  and `.sort(`
- every `.toString()` call, because the lexical rules do not know the type of the receiver
- `pow(` with any base, because `pow` on two `int` values overflows on the VM and dart2wasm
- the `dart:math` functions `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `exp` and
  `log`, with the prefix of the `dart:math` import. A new port is not a bump, and no bump report
  examines it. Thus only tool 3 finds a protected `sin` or `cos` on `dart:math` in a new port.
- the interpolation of a value with the static type `double` or `num`
- each call and tear-off of `dart:math` `max` and `min` whose type argument, explicit or inferred,
  is `double` or `num`
- the sorts of `package:collection`: `mergeSort(`, `insertionSort(`, `.sorted(`, `.sortedBy(`,
  `.sortedByCompare(`, `.sortBy(`, `.sortByCompare(` and `.sortRange(`
- `DateTime.now(`, because FakeAsync does not fake it

The lexical rules read the code without comments and strings. The interpolation rule and the
`max`/`min` rule resolve the types with `package:analyzer`.

A flagged form can stay only if it gives the JS result for every input that reaches it, or if
section 3 keeps `dart:math` at the site. Then the site carries `// js-ok: <reason>` at the end of
its line, or alone on the line before it. For example, `factorize` in `helpers.math.dart` sorts
distinct finite numbers with `List.sort`, with `// js-ok: distinct finite numbers`. Tool 3 fails
on a `js-ok` comment without a reason. It warns about a `js-ok` comment with no flagged site.

Tool 3 does not find some conversions of numbers to strings, and it does not examine port-only
tests. The reviewer examines these forms:
- the interpolation of a value with another static type that can hold a number, for example an
  `Object?` option value
- `List.join` and `StringBuffer.write` with numbers
- a port-only test that mirrors a protected function with `dart:math` `sin` or `cos`

### 9. Number formatting

`Intl.NumberFormat` is the `NumberFormat` of package:intl, through the port-only adapter
`lib/src/js/js_intl.dart` with its guards. Another ADR decides the formatter, its guards and its
known differences from V8 (see Related).
- The package depends on `intl: ^0.20.2`, the pin of `flutter_localizations` in Flutter 3.44.9.
- Library code imports only `package:intl/intl.dart`, `package:intl/number_symbols.dart` and
  `package:intl/number_symbols_data.dart`.
- `intl_standalone.dart` imports `dart:io`, and `intl_browser.dart` imports `dart:js_interop`.
  Thus library code does not import them.

### 10. Tests

- Pure-layer specs and the tests of `lib/src/js` run on the VM (`flutter test`). They also run in
  Chrome with dart2js and dart2wasm (`dart run melos run test:web`).
- The bit-for-bit tests of `jsLog10`, `jsAtan2`, `jsSin`, `jsCos` and `jsNumberToString` read the
  generated data of section 2. NaN compares as NaN.
- Each test that reads a generated data file pins the engine of its data: the Node.js version and
  the architecture (and the ICU version for `intl_reference.dart`). The tests of the fdlibm data
  pin `v24.12.0` and `x64`. The tests of the other data pin the reference engine (`v24.22.1`,
  `arm64`). A data file from another engine thus fails its test.
- The inputs of `trig_reference.mjs` include these values:
  - each branch bound of `s_sin.c`, `s_cos.c`, `k_sin.c`, `k_cos.c` and `e_rem_pio2.c`, ±k ulp
  - the 32 `npio2_hw` values and values next to `n·π/2`
  - the `__kernel_rem_pio2` range up to `double.maxFinite`
  - chart angles and the special values
  - the three tie arguments `-0.7853981633974483`, `2.356194490192345` and `3.665191429188092`
  - values `n·π/2 + d` with `2^-27 <= |d| < 2^-26`. These values give a reduced argument with a
    tail next to the `2^-27` bound of `__kernel_sin`.
- `test/port/js/js_math_test.dart` compares `jsMax`, `jsMin` and `jsSquare` by bit pattern with
  `dart:math` `max`, `min` and `pow(x, 2.0)`, over the special values (±0, NaN, ±Infinity, the
  subnormal and overflow bounds) and seeded random values. It confirms that `jsMaxMinCompare` is
  true on the dart2wasm leg only.
- The port tests of `distanceBetweenPoints`, `getAngleFromPoint`, `isPointInArea`, `pointInLine`
  and `steppedInterpolation` compare the `(e ?? 0)` and `jsSquare` forms with the `jsToNumber`
  and `pow` forms. The inputs include JS `null`, ±0, NaN, ±Infinity, subnormals and squares that
  overflow.
- The ported easing spec allows one unit of 1e-8 at the rounding ties
  ([`js-semantics-dart-math`](../differences.md#js-semantics-dart-math)).
- The controller tests keep their hit queries on the border of two elements. These queries are
  the only tests of the tie order, and they find a 1-ulp error at a protected site. The pie
  reference keeps the data `[5, 15, 10, 20]` with its hit tie. If a CI leg shows a border
  difference, find the builtin that gives another last bit and port it by section 3. Do not drop
  the query.

## Alternatives considered

- **Dart number operations as they are.** Rejected. The tables in Context show the mismatches.
- **`dart:math` `max` and `min` on every target** (Chart.js ADR 0002). Rejected. On dart2wasm
  the generic functions box their operands. `jsMax` and `jsMin` made `limitValue/10k` go from
  190.94 µs to 12.56 µs on dart2wasm-O2. The comparisons on every target were 1.68 times slower
  on the VM AOT and 4.47 times slower on dart2js-O4.
- **`jsToNumber` and `math.pow(x, 2.0)` for the `Point` coordinates** (Chart.js ADR 0002).
  Replaced. `(e ?? 0)` and `jsSquare` give the same bits, and `curve/default_10000` became 1.97
  times faster on the VM AOT. `dx` and `dy` locals gave no gain and read less like upstream.
- **`dart:math` `sin` and `cos` at every site** (Chart.js ADRs 0009 and 0010). Rejected. The two
  hit ties of Context give another hit element than upstream, and the result differs between the
  CI legs. A `DIVERGES(chartjs)` row for these ties is also rejected: the hit element is
  protected behavior.
- **`jsSin` and `jsCos` at all 72 sites.** Rejected. No protected result gains. The draw paths
  call `sin` and `cos` about 60,000 times in each frame of a 10,000-point `triangle` line. With
  form C of the next entry (+13.7 ns for each call), that adds about 0.82 ms on the Pixel 8a. No
  one measured the selected form a2 on the phone.
- **Other forms of the fdlibm `sin` and `cos`.** Rejected. A port with a `ByteData` read for each
  high-word test (a1 and v2) is slower. A port with one shared body for `sin` and `cos` (C)
  changes the structure of `s_cos.c`. Only a microbenchmark measures its gain. The selected form
  of section 3 is a2. [performance.md](../performance.md) §13.8 has the figures.
- **Other sources for `sin` and `cos`.** Rejected. CORE-MATH is correctly rounded, and V8 is not.
  FreeBSD msun and musl have other kernel revisions (3,751 sines of 532,663 inputs differed). The
  glibc `s_sin.c` is the code of Chrome, not of Node.js, and it is LGPL-2.1. A transcription of
  V8's `ieee754.cc` adds the V8 BSD notice.
- **Tool 3 without `sin` and `cos`, with the bump report to find new sites.** Rejected. A new
  port is not a bump, and no bump report examines it.
- **Drop each ill-conditioned hit query (decision D13 of phase 7).** Rejected. D13 asked the
  controller generators to drop each hit query whose hit list changes when the point moves by
  ±1e-6 px. With this ADR, the inputs of an arc or radial hit have the reference bits on every
  target. `sin`, `cos`, `atan2` and `log10` come from the fdlibm ports. `sqrt`, `x * x` and the
  operators are correctly rounded. Thus a V8 tie is a tie on each target, and it keeps the same
  item. D13 removes the tests that find a 1-ulp error at a protected site. Section 10 keeps
  these queries.
- **An fdlibm port of `pow`** (Chart.js ADR 0002). Rejected. V8 calls the platform C `pow` by
  default, so the port did not give the reference bits: 307 of 6,000 rows differed.
- **An ICU-exact number formatter.** Rejected (Chart.js ADR 0026). It cost about 1,800 lines of
  Dart, a port of four ICU files and a Unicode-3.0 notice for display text.
- **A sort written in the port.** Rejected. `mergeSort` is stable and pure Dart. Only the
  comparator sign needs port code.
- **`DateTime.now()`, frame time stamps or a clock parameter for `Date.now()`.** Rejected.
  FakeAsync does not fake `DateTime.now()`. `SchedulerBinding.currentFrameTimeStamp` fails its
  assert outside a frame. Upstream has no clock parameter.
- **Flutter `Curves` for `helpers.easing`.** Rejected. `Curves.easeInQuad` is a cubic
  approximation. Chart.js `easeInQuad` is `t * t`.
- **`dart:math` for `log10` and `atan2`, or a browser as the reference.** Rejected. Each differs
  from x64 V8 in the last bit for some inputs.
- **Keep the x64 engine of Chart.js ADR 0032 for all data.** Not possible on the Mac of the port:
  macOS 27 has no Rosetta 2, and the maintainer says that it will not come back. An x64 machine
  or an x64 CI runner can run it, but each generator change then needs a push and a CI run, and
  the scale and controller generators also need the Chart.js build and the moment folder there.
  Not chosen for the daily work. It stays the way to write the fdlibm data again (Open 5).
- **An x86-64 emulator (for example QEMU in a container) on the Mac.** Not chosen now. Nobody
  measured its speed, or checked that it gives the x64 bits of V8. Open 5 keeps it as a way to
  write the fdlibm data again.
- **The arm64 engine also for the fdlibm data.** Rejected. V8 on arm64 contracts fdlibm to fused
  multiply-add. The `log10` and `trig` data then differ in the last bits and in the signs of NaN
  results, and the Dart fdlibm ports (which follow netlib without fused multiply-add) fail. Also
  a port of the arm64 contraction is not netlib fdlibm, and its bits depend on the compiler.
- **Regenerate only the files that changed.** Rejected. The engine of each data file must be
  clear from its header and its pin test. The data equal to x64 get the arm64 header when they
  are written again at acceptance.
- **Correctly rounded results.** Not chosen now. V8 `main` moved `Math.log10` to a correctly
  rounded LLVM libm on 2026-05-11. The engines of the v4.5.1 era use fdlibm. Against correctly
  rounded results, V8 13.6 differs in the last bit on 7 of 5,909 log10 inputs. It gives the same
  `floor(log10(x))` on all of them.

## Consequences

- A ported file keeps the upstream lines. Only the builtin calls change. A reviewer can compare
  the two files side by side.
- The pure layers give the same results on the VM, dart2js and dart2wasm. The exceptions are the
  last bits of `pow` and of the display-only `sin` and `cos`, and the package:intl strings. CI job
  `test-web` runs the pure-layer tests with dart2js and dart2wasm.
- The arc and radial hit tests, the radial layout and the doughnut layout give the reference bits
  on the VM (Linux, macOS, Windows, Android, iOS), dart2js and dart2wasm.
- For a rotation from the options, the `sin` and `cos` factors of the rotated label box give the
  reference bits. The text widths come from the text layout of the platform. A rotation that
  `calculateLabelRotation` calculates comes from `dart:math` `asin` (Open 3).
- A `jsSin` or `jsCos` call costs about 6 ns more than `dart:math` on AOT and about 4 ns more in
  Chrome with dart2wasm. One hit query over 1000 arcs costs about 12 µs more on AOT. One radial
  scale draw costs at most 4.4 µs more. The line and bar charts make about 14 protected calls
  for each update and none for each frame.
- `jsMax` and `jsMin` have two code paths. If a later Dart SDK stops the boxing on dart2wasm, a
  new ADR can remove the switch.
- Each new fdlibm builtin costs a netlib copy, a Dart port, a reference generator and a
  bit-for-bit test.
- The pure layers depend on `package:collection`, `package:intl` and `package:clock`.
- A change of the reference engine needs a new ADR, and it regenerates all reference data, apart
  from the frozen fdlibm data of section 2.
- At acceptance, the generators of section 2 (all but `log10`, `atan2`, `trig` and
  `text_metrics`) write their data again on the reference engine: 44 generators, 45 files. 41
  files change only in their header lines, `intl_reference.dart` also in its ICU and CLDR lines,
  and 3 files in 1-ulp values that their tests accept (Context). The engine pins of the tests
  move to `v24.22.1` and `arm64`, and the ICU pin of `js_intl_test.dart` to `78.3`. The fdlibm
  generators get the x64 check again.
- The reference data have two engines: the fdlibm data come from x64, all other data from arm64.
  A new fdlibm builtin waits for an x64 engine (Open 5).
- ICU 78.3 replaces ICU 77.1 for the V8 strings of `js_intl_test.dart`. The known differences of
  package:intl from V8 (Chart.js ADR 0026) stay the same on the check of 2026-10-28.
- Section 3 of the bump report lists new builtin sites in a bump range
  ([upstream-tracking.md](../upstream-tracking.md) §4.6).
- AGENTS.md cites this ADR for the JS numeric translation rules and the reference engine. The
  docs and the code that cite Chart.js ADR 0032 for a current rule cite this ADR after the
  acceptance. This includes the `js-ok` texts of section 3 and the messages of tool 3.
- The D3 and ECharts ADRs that take their reference engine from Chart.js ADR 0032 §2 (D3 ADRs
  0003 and 0004, ECharts ADRs 0005 and 0006, and the two porting flows) still ask for the x64
  build. They are proposed. Their ports change them in the same way before their first generator
  runs.

## Open

1. **The Windows run.** Resolved (2026-10-21): the Windows leg of CI run 39569626698 passes the
   doughnut case `parsed: object items with the default key` and the pie and doughnut cases
   `the step toggleDataVisibility`. Thus the inferred UCRT value `-0.7071067811865476` no longer
   matters.
2. **No frame figure.** The claim "no frame figure moves" rests on the call counts. The phase
   lead runs the gallery bench after the change, and [performance.md](../performance.md) §13.8
   records it.
3. **`asin` and `pow` on protected paths.** `math.asin` of `calculateLabelRotation` (with
   `js-ok`) feeds the label rotation and thus `fit` and `_tickSize`. On macOS arm64, 157 of 3,044
   label rotations differ from x64 V8. The label sizes come from the text layout of the platform,
   which differs from the browser by more than 1 ulp. Thus the rotation keeps `dart:math`.
   `math.pow(10.0, n)` of the tick code calls the platform C `pow`, as V8 does. The probe of
   Context covers `n` from -340 to 320 on the three targets. A phase 7 probe on macOS confirmed
   the V8 value for `n` from -340 to 310. No probe covers a `pow` call with another base or a
   fractional exponent on a protected path. If a CI leg shows a difference there, a new ADR
   decides the form.
4. **Correctly rounded results.** [porting-flow.md](../porting-flow.md) §7 keeps this question
   open. A move of the reference engine to a correctly rounded library needs a new ADR.
5. **An x64 engine for the fdlibm data.** No x64 engine is available to the port now. A new fdlibm
   builtin, a new input of the fdlibm generators, or a changed value at a protected site
   (section 2) needs one. The candidates are an x64 CI runner with the official
   linux-x64 build of Node.js v24.12.0, and an x86-64 emulator on the Mac. Before the first use,
   a candidate writes the three fdlibm files again, and they must be byte-equal to the committed
   files apart from the platform name in the header. A second candidate is a transcription of
   netlib fdlibm 5.3 into JavaScript in `tool/reference/`: JavaScript arithmetic is not
   contracted to fused multiply-add, so such code gives the x64 bits on arm64. It needs the
   SunPro notice of the fdlibm copy (Chart.js ADR 0035) and a check against the committed data.
   A new ADR decides the choice.
6. **The cross-port rule.** ADR 0008 (shared JS runtime, proposed) plans a new ADR that
   supersedes Chart.js ADR 0032 in its stage 2. When ADR 0008 runs, that ADR supersedes this ADR
   in its place, and keeps section 2.

## Evidence

- The panel: the drafts and the judge (`design/trig/judge.md`), the implementation spec
  (`design/trig/spec.md`). These are working files of phase 7, not committed.
- The cases: `review/wave3/U-pie-review.md` (F2), `review/wave3/W3-int-report.md`, and the phase
  7 progress file (D13, D14). These are working files of phase 7, not committed.
- The figures: [performance.md](../performance.md) §13.8.
- The arm64 engine (Context, "The arm64 engine"): the engine check of 2026-10-28 of phase 8, with
  the run and compare scripts, the table of the 46 data files, the 4 diffs and the test log. These
  are working files of phase 8, not committed.
- Commit `1d271cd`: the generators without the x64 check, and the AGENTS.md note on `log10` and
  `trig`.
