# Chart.js ADR 0010: JS numeric semantics

- Status: accepted (2026-10-19)
- Superseded by: [Chart.js ADR 0032](0032-js-numeric-semantics.md) (2026-10-21)
- Date: 2026-10-19
- Supersedes: [Chart.js ADR 0002](0002-js-numeric-semantics.md)
- Related: [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (the JS values in
  Dart), [Chart.js ADR 0008](0008-number-formatting-on-package-intl.md) (number formatting),
  [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (no display-only JS exactness),
  [Chart.js ADR 0011](0011-third-party-sources.md) (the fdlibm copy)

## Context

The port translates Chart.js v4.5.1 line by line (AGENTS.md rules 1 and 2). The upstream specs and
image fixtures assert exact numbers, strings and pixels. A JavaScript engine computed those values.
Dart number operations give other results in many places. Some Dart results also differ between
the VM, dart2js and dart2wasm.

Chart.js ADR 0002 (accepted 2026-10-18) gave the first set of rules. Three later changes replaced
parts of it:
- [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) moved `Math.sin`, `Math.cos` and
  `Math.pow` to `dart:math`.
- [Chart.js ADR 0008](0008-number-formatting-on-package-intl.md) moved number formatting to
  package:intl.
- The speed work of 2026-10-18 measured two rules again: `Math.max` and `Math.min` on dart2wasm,
  and `Math.pow(x, 2)` with the `ToNumber` of a nullable coordinate.

This ADR states the complete current decision. It supersedes Chart.js ADR 0002.

**Naive translation.** The research of 2026-10-16 and the phase 1 pilot (commit `421fc9f`)
compared a naive Dart translation with V8 13.6 on the VM, dart2wasm and dart2js:

| Builtin | Naive Dart | With `lib/src/js` |
|---|---|---|
| `Math.round` (25 sites) | 116/834 mismatches, throws on NaN | 0 |
| `%` | 150/318 mismatches | 0 |
| `log10` as `log(x)/ln10` | spec loop fails for 168/308 exponents | 0 (fdlibm) |
| `Math.atan2` as `dart:math` `atan2` | 34,032/303,640 mismatches on the VM, browser results on the web | 0 (fdlibm) |
| logarithmic `generateTicks` | 310/613 pairs wrong | 0 |
| `toString` | `'1.0'` on VM and wasm | 0 |

**Other differences.**
- Dart `floor()` and `ceil()` return an `int`. They throw on NaN. On the VM and dart2wasm, they
  saturate at the int64 limit.
- `pow` on two `int` values overflows on the VM and dart2wasm: `pow(10, 19)` is negative.
  `pow(10.0, k)` gives the V8 bits for each integer `k` from -340 to 320 on all three targets.
- `double.nan.clamp(0, 1)` is 1. `Math.max` and `Math.min` return NaN for a NaN argument.
- `dart:math` `max` and `min` give the `Math.max` and `Math.min` results. Their documentation
  states the NaN rule and the order of `-0.0` and `0.0` (`math.dart:119-134`). A probe of
  2026-10-18 compared 16,400 bit-pattern pairs with Node.js. It found 0 mismatches on the VM (JIT
  and AOT), dart2js (`-O1`, `-O4`) and dart2wasm (`-O0`, `-O4`). With an `int` operand, the type
  argument is `num`. Then the result can be an `int`.
- On dart2wasm, the generic `max<T extends num>` and `min<T extends num>` box both `double`
  operands and dispatch through `BoxedDouble`. In the dart2wasm profiles, this boxing took 53% of
  `limitValue/10k`, 29% of `curve/default_10000` and 31% of `segment/bound_10k_gaps`.
- On dart2js, `1.0 is int` is true.
- On Flutter 3.44.9, `List.sort` is not stable above 32 elements on the VM, in dart2wasm and in
  DDC, because they call Dart's `Sort.sort`. dart2js calls the native JS sort. That sort is
  stable (probe). The user comparators of `plugin.legend.js:113` and `plugin.tooltip.js:620`
  expect a stable sort. `mergeSort` of `package:collection` 1.19.1 is stable
  (`algorithms.dart:212`) and pure Dart. Flutter 3.44.9 pins `collection` 1.19.1.
- JavaScript tests a number with ToBoolean in `if (x)`, `!x` and `x || d`. The result is false
  for `0`, `-0` and NaN. Dart has no implicit conversion to `bool`.
- `Date.now()` returns the wall clock in whole milliseconds. Dart `DateTime.now()` also reads the
  wall clock. flutter_test runs each `testWidgets` body in a `FakeAsync` zone. That zone fakes
  `clock.now()` of `package:clock`, but not `DateTime.now()`. Thus `tester.pump` moves
  `clock.now()` by the pumped duration.
- `jsToNumber(Object?)` on the `double?` coordinates of a `Point` boxes each value. Before the
  change of 2026-10-18, it took 30% of the self time of `curve/default_10000` on the VM JIT. On
  dart2wasm, `math.pow(d, 2.0)` costs about 13 ns, and `d * d` costs about 1.6 ns.

**fdlibm.** The first fdlibm result came from a transcription of V8's `ieee754.cc`. The pilot then
ported `helpers.math` on netlib fdlibm 5.3. It found five facts:
1. "V8 semantics" needs one named engine. V8 on arm64 contracts fdlibm to fused multiply-add.
   Chrome 155 computes `Math.log`, `Math.log10` and `Math.atan2` another way. Both differ from V8
   on x64 in the last bit for some inputs.
2. `dart:math` `atan2` calls the host C library on the VM and the browser on the web. On fuzzed
   `getAngleFromPoint` inputs, about one result in ten differed from x64 V8. Below −π/2, a
   last-bit difference changes the angle by 2π (`helpers.math.ts:132-136`).
3. netlib `e_atan2.c` does not have one line that V8 has: `m &= 1` when |y/x| > 2**60. Without
   that line, netlib returns π/2 + 1 ulp for `atan2(1e300, -1e-300)`. V8 returns π/2.
4. dart2js makes the results of `>>` and `|` unsigned. Where the C code relies on a signed `int`,
   the Dart port calls `toSigned(32)`.
5. The netlib ports match x64 V8 bit for bit. The log10 comparison gave 0 mismatches on 5,909
   inputs on all three targets. The `atan2` port matched on 607,280 fuzz inputs on the VM and on
   150,000 inputs on dart2js and dart2wasm.

**Which last bits change behavior.**
- `floor(log10(x))` selects the ticks of a logarithmic scale. Thus the last bit of `Math.log10`
  changes the ticks.
- Below −π/2, the last bit of `Math.atan2` changes the angle by 2π. Thus an arc hit test gives
  another result.
- A last-bit difference of `sin` or `cos` changes no pixel. Chart code uses these values for arcs,
  label angles and easing curves.
- By default, V8 13.6 does not use the fdlibm `pow`. It calls the platform C `pow`
  (`--use-std-math-pow`). Against the default `Math.pow`, an fdlibm port differed on 307 of 6,000
  reference rows, each by 1 ulp or less. Thus no pure-Dart `pow` gives the reference bits.
- Only one upstream spec sees a `sin`, `cos` or `pow` difference: `helpers.easing.tests.js`. It
  rounds each result to 1e-8 (`:43`, `:49`). Eight expected values lie on a rounding tie or 1 ulp
  from one. For example, `easeInElastic(0.2)` gives the expected `-0.00195313` (`:23`) only
  because `Math.sin` returns `0.5000000000000001`.

## Decision

### 1. JS runtime

An unexported library in `packages/flutter_chartjs/lib/src/js/` represents the JS builtins and
the JS value operations. Ported files call it where upstream calls a builtin or relies on an
implicit JS conversion. For example, `helpers.math.dart` mirrors `helpers.math.ts:18` as
`const double Function(double) log10 = jsLog10;`.

| File | Symbols | Purpose |
|---|---|---|
| `js_math.dart` (port-only) | `numberEpsilon`, `jsRound`, `jsToInt32`, `jsMaxMinCompare`, `jsMax`, `jsMin`, `jsSquare`, `jsLog10`, `jsAtan2` | the `Math` and `Number` builtins whose Dart forms give other results |
| `js_number.dart` (port-only) | `jsToNumber`, `jsParseFloat`, `jsIsNaN`, `jsIsFinite`, `jsTruthy`, `jsToString`, `jsNumberToString` | `ToNumber`, `parseFloat`, the global `isNaN` and `isFinite`, `ToBoolean`, `ToString` and `Number::toString` (radix 10) |
| `js_array.dart` (port-only) | `jsSort`, `jsObjectKeys`, `jsArrayIndex`, `JsProxyObject` | `Array.prototype.sort` on `mergeSort`, the key order of `Object.keys`, the canonical array index, and a JS `Proxy` as a `Map` |
| `js_object.dart` (port-only) | `jsGet` | the property read `object[key]`. It carries the marker of the `differences.md` row `js-semantics-resolver-objects` |
| `js_function.dart` (port-only) | `JsFunction`, `jsIsFunction`, `jsCall`, `jsCall1`, `jsMaxArity` | the call of a function value: the argument count, the `undefined` padding and `this` |
| `js_undefined.dart` (port-only) | `Undefined`, `undefined` | the JS value `undefined` ([Chart.js ADR 0006](0006-options-representation-and-resolver.md)) |
| `js_intl.dart` (port-only) | `jsNumberFormat`, `jsNumberFormatLocale`, `JsNumberFormat`, `maxFractionDigits` | `Intl.NumberFormat` on package:intl ([Chart.js ADR 0008](0008-number-formatting-on-package-intl.md)) |
| `fdlibm_log.dart` | `ieee754Log`, `ieee754Log10` | the port of fdlibm 5.3 `e_log.c` and `e_log10.c` |
| `fdlibm_atan.dart` | `atan`, `ieee754Atan2` | the port of fdlibm 5.3 `s_atan.c` and `e_atan2.c`, plus the V8 line `m &= 1` |
| `js_date.dart` (port-only, phase 5) | `jsDateNow` | `Date.now()` on `clock.now()` of `package:clock` |

- A port-only file starts with `// Original code, not ported from Chart.js: <reason>.` An fdlibm
  file starts with one `// Ported from fdlibm 5.3 <file> (SunPro, Sun Microsystems, Inc.).` line
  for each C file.
- The runtime is a pure layer. It imports neither `dart:ui` nor `package:flutter`. It compiles for
  every Flutter platform and for web WebAssembly.
- Port-only runtime code can use any implementation that gives the JS results on the VM, dart2js
  and dart2wasm. For example, `jsNumberToString` has an integer path below 2^53, `jsToNumber` has
  a plain-decimal path before its RegExp, and `jsCall` makes a dynamic call on the VM. Tests pin
  the results on all three targets.

### 2. Reference engine

The reference engine is V8 13.6 as Node.js v24.12.0 for x64 builds it: fdlibm 5.3, compiled
without fused multiply-add.
- Reference data never come from a browser or from an arm64 Node.js. On Apple silicon, the
  darwin-x64 build runs under Rosetta.
- Each reference run writes the Node.js version, the V8 version and the architecture into its
  output.
- The generators in `packages/flutter_chartjs/tool/reference/` stop unless `process.arch` is `x64`.
  `log10_reference.mjs`, `atan2_reference.mjs` and `number_to_string_reference.mjs` write
  `test/port/js/log10_reference.dart`, `atan2_reference.dart` and
  `number_to_string_reference.dart`. Do not edit these files by hand.
- The expected JS values of the other port tests also come only from this engine. Examples are the
  special values of the `jsSquare` test, the `jsNumberToString` boundary cases and the V8 strings
  that `js_intl_test.dart` compares with package:intl.

### 3. Transcendental builtins

- **`Math.log10` and `Math.atan2`** are `jsLog10` and `jsAtan2`. These are pure-Dart ports of
  netlib fdlibm 5.3. The VM, dart2js and dart2wasm give the bits of the reference engine. The
  last bit of these two builtins changes the ticks of a logarithmic scale and the arc hit tests.
  Ported code must not call `dart:math` `log` or `atan2` for them.
- **`Math.sin`, `Math.cos` and `Math.pow`** are `dart:math` `sin`, `cos` and `pow` with `double`
  operands. Their last bit can differ from V8 and between the targets. No pixel and no chart
  behavior depends on it. `dart:math` `pow` gives 1 for `pow(1, NaN)` and `pow(±1, ±Infinity)`.
  JavaScript gives NaN there. The upstream easing spec allows one unit of 1e-8 at the rounding
  ties. The `differences.md` row
  [`js-semantics-dart-math`](../differences.md#js-semantics-dart-math) records this tolerance.
  `Math.pow(x, 2)` is the exception: it is `jsSquare(x)` (section 4).
- **Other transcendental builtins** (`tan`, `asin`, `acos`, `atan`, `exp`, `log`) arrive with
  their first ported caller. If the last bit changes chart behavior, port the builtin from netlib
  fdlibm 5.3, with a reference generator and a bit-for-bit test. If not, call `dart:math` with
  `double` operands and add `// js-ok: <reason>`
  ([Chart.js ADR 0009](0009-no-display-only-js-exactness.md)).
- **fdlibm ports.**
  - Port from the netlib files in `third_party/fdlibm/`
    ([Chart.js ADR 0011](0011-third-party-sources.md)). Do not port from V8's `ieee754.cc`,
    because it adds a V8 BSD notice.
  - Where V8 differs from netlib, follow V8. Mark each added line with a comment that names the
    difference. Pin the line with a test. The only such line now is `m &= 1` in
    `fdlibm_atan.dart`.
  - Read `__HI(x)` and `__LO(x)` through a `ByteData`. Call `toSigned(32)` where C relies on a
    signed `>>` or `|` result. Write a C bit test such as `(lx|-lx)>>31` as a comparison
    (`lx != 0`).

### 4. Exact and correctly rounded builtins

`Math.sqrt`, `Math.abs`, `Math.sign`, `Math.max`, `Math.min` and the arithmetic operators are
exact or correctly rounded.
- For `Math.sqrt`, `Math.abs`, `Math.sign` and the operators, ported code calls `dart:math`, the
  `double` member or the operator.
- **`Math.max` and `Math.min` with `double` operands** are `jsMax` and `jsMin` of
  `lib/src/js/js_math.dart`. They give the `dart:math` `max` and `min` results, thus the JS
  results, on every target: NaN if an operand is NaN, +0 for `jsMax` of +0 and -0 in either
  order, and -0 for `jsMin` of +0 and -0 in either order.
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
  `@pragma('wasm:prefer-inline')`. The product is correctly rounded on every target.
  - A probe of 2026-10-19 on the reference engine compared `Math.pow(x, 2)` with `x * x` by bit
    pattern. The inputs were 10 million random bit patterns, 10 million random values between
    -1e6 and 1e6, 3 million values whose square is subnormal or near the largest finite double,
    and 12 special values. The probe found 0 mismatches. A second run with `--jitless`, where no
    optimizing compiler runs, found 0 mismatches on 7 million inputs of the same kinds.
  - Thus `jsSquare` gives the JS result on every target: NaN for NaN, +0 for -0, and +Infinity
    for ±Infinity and for a square above the largest finite double. This rule is exact. It is not
    a display-only exception.
- **`ToNumber` of a `double?` value whose `null` is JS `null`** is `(e ?? 0)`, not
  `jsToNumber(e)`. `Point.x` and `Point.y` of `geometric.dart` are such values. `ToNumber(null)`
  is 0, and `ToNumber` of a number is the number, so the result is the same double. A copied JS
  `undefined` is already `double.nan` in such a member, and `(e ?? 0)` keeps it NaN.
  - This rule does not apply to a `double?` member whose `null` is JS `undefined`, for example the
    optional members of `SplinePoint`. There, `ToNumber` gives NaN, which `e ?? double.nan`
    writes.
  - It does not apply to an `Object?` value. That value goes through `jsToNumber`.

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

### 6. Clock (phase 5)

`jsDateNow()` returns `clock.now().millisecondsSinceEpoch` as a `double`. It replaces each
`Date.now()` call: `core.animator.js:57`, `:169` and `:201`, `core.animation.js:37` and `:70`,
`core.animations.js:73` and `scale.time.js:342-343`.
- Inside `testWidgets`, `tester.pump` moves this clock. Thus the animation specs run in fake time.
- Chart animations ignore `timeDilation`, as upstream does.
- Phase 5 adds `clock: ^1.1.2` as a direct dependency. Tool 1 then allows
  `package:clock/clock.dart` in `lib/` and in the pure layers. `clock` is Apache-2.0. The package
  uses it as a dependency and copies no code. Thus the package `LICENSE` does not change.

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
| `Math.max(i, j)`, `Math.min(i, j)` with list indexes | `math.max(i, j)`, `math.min(i, j)` with `int` operands; `math.max<int>(0, i)` with a literal |
| `Math.pow(x, 2)` | `jsSquare(x)` |
| `Math.pow(x, y)` with another `y` | `math.pow(x, y)` with `double` operands and `// js-ok` |
| `Math.sin(x)`, `Math.cos(x)` | `math.sin(x)`, `math.cos(x)` |
| `Math.log10(x)`, `Math.atan2(y, x)` | `jsLog10(x)`, `jsAtan2(y, x)` |
| `ToNumber(e)` of a `number \| null` value held as `double?` (JS `null` is Dart `null`) | `(e ?? 0)` |
| `if (x)`, `!x`, `x \|\| d` | `jsTruthy(x)`, `!jsTruthy(x)`, `jsTruthy(x) ? x : d`; for a `double` `x`, `x != 0 && !x.isNaN` is the same test |
| `'' + n`, `String(n)`, a template literal with a number | `jsNumberToString(n)`; `jsToString(v)` for a value of any type |
| `+s`, `Number(s)`, `parseFloat(s)` | `jsToNumber(s)`, `jsParseFloat(s)` |
| global `isNaN(v)`, `isFinite(v)` | `jsIsNaN(v)`, `jsIsFinite(v)` |
| `Number.EPSILON` | `numberEpsilon` |
| `array.sort(compare)` | `jsSort(array, compare)` |
| `Object.keys(o)`, and `for-in`, `Object.assign` or a spread over an object | `jsObjectKeys(o)` |
| `Date.now()` | `jsDateNow()` (phase 5) |

**ToBoolean.** ToBoolean is false for these `Object?` values: `null`, the `undefined` sentinel of
[Chart.js ADR 0006](0006-options-representation-and-resolver.md), `false`, `0`, `-0`, NaN and
`''`. It is true for every other value, also for an empty `List` or `Map`. A test of `x || d` on
such a value tests the raw value, not a converted number. `jsTruthy` gives this result.

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

### 8. Tool 3 and `js-ok`

Tool 3 (`tool/check_js_semantics.dart`, `check:js-semantics`) is the JS-semantics check of
[porting-flow.md](../porting-flow.md) §4. It examines each `lib/` and `test/` file whose header
block names a `js` project of `packages/flutter_chartjs/tool/port_sources.yaml`, or a project
that `port_sources.yaml` does not list. The `js` projects are Chart.js, `@kurkle/color` and
chartjs-test-utils. Tool 3 flags these forms:
- `.round()`, `.roundToDouble()`, `.floor()`, `.ceil()`, `.truncate()`, `.clamp(`, `%`, `is int`
  and `.sort(`
- every `.toString()` call, because the lexical rules do not know the type of the receiver
- `pow(` with any base, because `pow` on two `int` values overflows on the VM and dart2wasm
- the `dart:math` functions `tan`, `asin`, `acos`, `atan`, `atan2`, `exp` and `log`, with the
  prefix of the `dart:math` import. Tool 3 does not flag `sin` and `cos`.
- the interpolation of a value with the static type `double` or `num`
- each call and tear-off of `dart:math` `max` and `min` whose type argument, explicit or inferred,
  is `double` or `num`
- the sorts of `package:collection`: `mergeSort(`, `insertionSort(`, `.sorted(`, `.sortedBy(`,
  `.sortedByCompare(`, `.sortBy(`, `.sortByCompare(` and `.sortRange(`
- from phase 5, `DateTime.now(`, because FakeAsync does not fake it

The lexical rules read the code without comments and strings. The interpolation rule and the
`max`/`min` rule resolve the types with `package:analyzer`.

A flagged form can stay only if it gives the JS result for every input that reaches it. Then the
site carries `// js-ok: <reason>` at the end of its line, or alone on the line before it. For
example, `factorize` in `helpers.math.dart` sorts distinct finite numbers with `List.sort`. Its
line carries `// js-ok: distinct finite numbers`. Tool 3 warns about a `js-ok` comment with no
flagged site.

Tool 3 does not find some conversions of numbers to strings. The reviewer examines these forms:
- the interpolation of a value with another static type that can hold a number, for example an
  `Object?` option value
- `List.join` and `StringBuffer.write` with numbers

### 9. Number formatting

`Intl.NumberFormat` is the `NumberFormat` of package:intl. The port-only adapter
`lib/src/js/js_intl.dart` maps the JS locale and options onto it.
[Chart.js ADR 0008](0008-number-formatting-on-package-intl.md) holds that decision, its guards
and its known differences from V8. The package depends on `intl: ^0.20.2`, the pin of
`flutter_localizations` in Flutter 3.44.9. Library code imports only `package:intl/intl.dart` and
its `number_symbols` files. `intl_standalone.dart` imports `dart:io`. `intl_browser.dart` imports
`dart:js_interop`.

### 10. Tests

- Pure-layer specs and the tests of `lib/src/js` run on the VM (`flutter test`). They also run in
  Chrome with dart2js and dart2wasm (`dart run melos run test:web`).
- The bit-for-bit tests of `jsLog10`, `jsAtan2` and `jsNumberToString` read the generated data of
  section 2.
- `test/port/js/js_math_test.dart` compares `jsMax` and `jsMin` with `dart:math` `max` and `min`
  by bit pattern, over 40 operands in both orders: ±0, NaN, ±Infinity, ±`double.minPositive`,
  ±2.2250738585072014e-308, ±`double.maxFinite` and seeded random finites. It confirms that
  `jsMaxMinCompare` is true on the dart2wasm leg only. Its group `jsSquare` compares 10 special
  values with the results of the reference engine. It also compares `jsSquare` with `dart:math`
  `pow(x, 2.0)` by bit pattern, over the 40 operands, three values near the overflow limit and
  20,000 seeded random bit patterns.
- The port tests of `distanceBetweenPoints`, `getAngleFromPoint`, `isPointInArea`, `pointInLine`
  and `steppedInterpolation` compare the `(e ?? 0)` and `jsSquare` forms with the earlier
  `jsToNumber` and `pow` forms. The inputs include JS `null`, ±0, NaN, ±Infinity, subnormals and
  squares that overflow.
- The ported easing spec allows one unit of 1e-8 at the rounding ties
  ([`js-semantics-dart-math`](../differences.md#js-semantics-dart-math)).

## Alternatives considered

- **Dart number operations as they are.** Rejected. The tables in Context show the mismatches.
- **`dart:math` `max` and `min` on every target.** Chart.js ADR 0002 chose this form. Rejected
  now. The results are correct, but on dart2wasm the generic functions box their `double`
  operands. With `jsMax` and `jsMin` on dart2wasm-O2, `limitValue/10k` went from 190.94 µs to
  12.56 µs (15.2 times faster). `segment/bound_10k_gaps` went from 770.28 µs to 274.00 µs. No
  measured case changed by more than 5% on the VM AOT or dart2js-O4.
- **The comparisons of `jsMax` and `jsMin` on every target.** Rejected. One code path is simpler,
  but the comparisons are slower on the VM AOT and dart2js. `limitValue/10k` was 1.68 times
  slower on the VM AOT and 4.47 times slower on dart2js-O4. `segment/bound_10k_gaps` was 1.21
  times slower on dart2js-O4.
- **`jsToNumber` and `math.pow(x, 2.0)` for the `Point` coordinates.** Chart.js ADR 0002 gave this
  form. Replaced. `(e ?? 0)` and `jsSquare` give the same bits. `curve/default_10000` became 1.97
  times faster on the VM AOT, 1.21 times faster on dart2js-O4 and 2.31 times faster on
  dart2wasm-O2.
- **`dx` and `dy` locals with `dx * dx` in `distanceBetweenPoints`.** Rejected. The speed was the
  same within the noise. The one-statement form reads as the upstream line.
- **fdlibm ports of `sin`, `cos` and `pow`.** Chart.js ADR 0002 chose them, and the phase 2 stream
  wrote them. Rejected ([Chart.js ADR 0009](0009-no-display-only-js-exactness.md)). They cost
  four Dart files (`fdlibm_pow.dart`, `fdlibm_trig.dart`, `fdlibm_rem_pio2.dart`,
  `fdlibm_scalbn.dart`), eight netlib files, two reference generators and their bit-for-bit
  tests. `pow` did not give the default V8 bits: 307 of 6,000 rows differed. A pure-Dart port
  cannot give the bits of each platform C `pow`.
- **An ICU-exact number formatter.** Rejected
  ([Chart.js ADR 0008](0008-number-formatting-on-package-intl.md)). It gave the V8 string for all
  15,889 reference cases. It had about 1,800 lines of Dart, a table of 205 locale tags, a port of
  four ICU 77.1 files, 612 KB of generated reference data and a Unicode-3.0 notice. The strings
  are display text.
- **A sort written in the port.** Rejected. `mergeSort` of `package:collection` is stable and pure
  Dart. Only the comparator sign needs port code.
- **`DateTime.now()` for `Date.now()`.** Rejected. FakeAsync does not fake it. Thus `tester.pump`
  does not move the chart animations. The animation specs then fail in fake time.
- **Frame time stamps for `Date.now()`.** Rejected. `SchedulerBinding.currentFrameTimeStamp`
  fails its assert outside a frame. Five of the six animation sites can run outside a frame
  callback. `core.animation.js:56` and `:77` subtract absolute `_start` values.
- **A clock parameter.** Rejected. Upstream has no clock parameter. A parameter changes the
  signatures of the animation classes. `package:clock` gives the same test control with no
  signature change.
- **Flutter `Curves` for `helpers.easing`.** Rejected. Flutter's `Curves.easeInQuad` is
  `Cubic(0.55, 0.085, 0.68, 0.53)` (`curves.dart:1548`), a cubic approximation. Chart.js
  `easeInQuad` is `t * t` (`helpers.easing.ts:15`).
- **`dart:math` for `log10` and `atan2`.** Rejected. The VM calls the host C library. The web
  calls the browser. Neither gives the reference bits on all inputs, and the two differ from each
  other. The last bit of these two builtins changes chart behavior.
- **A transcription of V8's `ieee754.cc`.** Rejected. It matched V8. But it adds the V8 BSD
  notice. The netlib port gives the same bits under the fdlibm notice only.
- **A browser or an arm64 Node.js as the reference.** Rejected. Both differ from x64 V8 in the last
  bit for some inputs.
- **Correctly rounded results.** Not chosen now. V8 `main` moved `Math.log10` to a correctly
  rounded LLVM libm on 2026-05-11 (commit `08be4445f6`). The engines of the v4.5.1 era computed
  `Math.log10` with fdlibm. Against correctly rounded results, V8 13.6 differs in the last bit on
  7 of 5,909 log10 inputs. It gives the same `floor(log10(x))` on all of them.
  [porting-flow.md](../porting-flow.md) §7 keeps this question open.

## Consequences

- A ported file keeps the upstream lines. Only the builtin calls change. A reviewer can compare
  the two files side by side.
- The pure layers give the same results on the VM, dart2js and dart2wasm. The exceptions are the
  last bits of `sin`, `cos` and `pow`, and the package:intl strings of Chart.js ADR 0008. CI job
  `test-web` runs the pure-layer tests with dart2js and dart2wasm.
- `jsMax` and `jsMin` have two code paths. The test of `jsMaxMinCompare` shows which path each
  test leg runs. If a later Dart SDK stops the boxing on dart2wasm, the switch has no benefit.
  Then a new ADR can remove it.
- Each new fdlibm builtin costs a netlib copy, a Dart port, a reference generator and a
  bit-for-bit test.
- `jsSort` is mandatory for the two upstream sorts with user comparators.
- The pure layers depend on `package:collection` and `package:intl`, and on `package:clock` from
  phase 5.
- A change of the reference engine needs a new ADR that supersedes this ADR. That change
  regenerates all reference data.
- Section 3 of the bump report lists new builtin sites in a bump range
  ([upstream-tracking.md](../upstream-tracking.md) §4.6).
- AGENTS.md cites this ADR for the JS numeric translation rules and the reference engine.
