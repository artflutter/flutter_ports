# Chart.js ADR 0002: JS numeric semantics

- Status: accepted (2026-10-18)
- Date: 2026-10-17

## Context

The port translates Chart.js v4.5.1 line by line (AGENTS.md rules 1 and 2). The upstream specs and
image fixtures assert exact numbers, strings and pixels. A JavaScript engine computed those values.
Dart number operations give other results in many places. Some Dart results also differ between
the VM, dart2js and dart2wasm. [porting-flow.md](../porting-flow.md) §2.3 proposed this decision.
Its gate is phase 1, because the phase 1 pilot depends on it.

The research of 2026-10-16 and the phase 1 pilot (commit `421fc9f`) compared a naive Dart
translation with V8 13.6 on the VM, dart2wasm and dart2js:

| Builtin | Naive Dart | With `lib/src/js` |
|---|---|---|
| `Math.round` (25 sites) | 116/834 mismatches, throws on NaN | 0 |
| `%` | 150/318 mismatches | 0 |
| `log10` as `log(x)/ln10` | spec loop fails for 168/308 exponents | 0 (fdlibm) |
| `Math.atan2` as `dart:math` `atan2` | 34,032/303,640 mismatches on the VM, browser results on the web | 0 (fdlibm) |
| logarithmic `generateTicks` | 310/613 pairs wrong | 0 |
| `toString` | `'1.0'` on VM and wasm | 0 |

The research also found these differences:
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
- On dart2js, `1.0 is int` is true.
- On Flutter 3.44.9, `List.sort` is unstable above 32 elements on the VM, in dart2wasm and in DDC,
  because they call Dart's `Sort.sort`. dart2js calls the native JS sort. That sort is stable
  (probe). The user comparators of `plugin.legend.js:113` and `plugin.tooltip.js:620` expect a
  stable sort. `mergeSort` of `package:collection` 1.19.1 is stable (`algorithms.dart:212`) and
  pure Dart. Flutter 3.44.9 pins `collection` 1.19.1. The workspace lock resolves it.
- JavaScript tests a number with ToBoolean in `if (x)`, `!x` and `x || d`. The result is false
  for `0`, `-0` and NaN. Dart has no implicit conversion to `bool`.
- `Date.now()` returns the wall clock in whole milliseconds. Dart `DateTime.now()` also reads the
  wall clock. flutter_test runs each `testWidgets` body in a `FakeAsync` zone. That zone fakes
  `clock.now()` of `package:clock`, but not `DateTime.now()`. Thus `tester.pump` moves `clock.now()`
  by the pumped duration.

The first fdlibm result came from a transcription of V8's `ieee754.cc`. The pilot then ported
`helpers.math` on netlib fdlibm 5.3. It found five facts:
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

The 12 cases of `helpers.math.tests.js` pass on the VM, dart2js and dart2wasm.

The next builtins have the same source. The symbol table of the Node.js v24.12.0 binary
(darwin-arm64, V8 13.6.233.17-node.37, `nm`, 2026-10-17) contains `v8::base::ieee754::sin`, `cos`
and `legacy::pow`. It also contains the fdlibm helper `__ieee754_rem_pio2` and no glibc trig
symbols. Phase 2 needs these builtins. `helpers.easing.ts` calls `Math.sin`, `Math.cos` and
`Math.pow` with fractional exponents (`:4-5`, `:47-59`). The easing spec rounds each result to
1e-8 (`helpers.easing.tests.js:43`, `:49`). That rounding hides most last-bit differences, but
not all. Eight expected values lie on a rounding tie or 1 ulp from one. For example,
`easeInElastic(0.2)` gives the expected `-0.00195313` (`:23`) only because `Math.sin` returns
`0.5000000000000001`. A `sin` 1 ulp lower gives `-0.00195312`. Thus the easing spec also needs the
reference bits.

## Decision

**JS runtime.** An unexported library in `packages/flutter_chartjs/lib/src/js/` represents the JS
builtins. Ported files call it where upstream calls a builtin. For example, `helpers.math.dart`
mirrors `helpers.math.ts:18` as `const double Function(double) log10 = jsLog10;`. A port-only file
starts with `// Original code, not ported from Chart.js: <reason>.` An fdlibm file starts with one
`// Ported from fdlibm 5.3 <file> (SunPro, Sun Microsystems, Inc.).` line for each C file.

| File | Contents | Phase |
|---|---|---|
| `js_math.dart` (port-only) | `numberEpsilon`, `jsRound`, `jsToInt32`, `jsLog10`, `jsAtan2` | 1 (pilot) |
| `js_number.dart` (port-only) | `jsToNumber`, `jsParseFloat`, `jsIsNaN`, `jsIsFinite` | 1 (pilot) |
| `js_number.dart` (port-only) | `jsNumberToString` | 2 |
| `fdlibm_log.dart` | `e_log.c`, `e_log10.c` | 1 (pilot) |
| `fdlibm_atan.dart` | `s_atan.c`, `e_atan2.c`, plus the V8 line `m &= 1` | 1 (pilot) |
| `fdlibm_*.dart` | `sin`, `cos`, `pow` | 2 |
| `js_array.dart` (port-only) | `jsSort` on `mergeSort` of `package:collection`, the `jsObjectKeys` order | 2 |
| `js_intl.dart` (port-only) | the JS-style number formatter behind `helpers.intl.dart` | 2 |
| `js_date.dart` (port-only) | `jsDateNow` on `clock.now()` of `package:clock` | 5 |

**Reference engine.** The reference engine is V8 13.6 as Node.js v24.12.0 for x64 builds it:
fdlibm 5.3, compiled without fused multiply-add.
- Reference data never come from a browser or from an arm64 Node.js. On Apple silicon, the
  darwin-x64 build runs under Rosetta.
- Each reference run writes the Node.js version, the V8 version and the architecture into its
  output.
- The generators in `packages/flutter_chartjs/tool/reference/` stop unless `process.arch` is `x64`.

**Transcendental builtins.** Each transcendental `Math` builtin that ported code calls is a
pure-Dart port of netlib fdlibm 5.3. Thus the VM, dart2js and dart2wasm give the bits of the
reference engine. Ported code must not call `dart:math` for these builtins.
- The port has `log10` and `atan2` now. `sin`, `cos` and `pow` arrive in phase 2 with
  `helpers.easing`. Each other builtin arrives with its first ported caller.
- Port from the netlib files in `third_party/fdlibm/`
  ([Chart.js ADR 0005](0005-third-party-sources.md)). Do not port from V8's `ieee754.cc`, because
  it adds a V8 BSD notice.
- Where V8 differs from netlib, follow V8. Mark each added line with a comment that names the
  difference. Pin the line with a test. The only such line now is `m &= 1` in `fdlibm_atan.dart`.
- Read `__HI(x)` and `__LO(x)` through a `ByteData`. Call `toSigned(32)` where C relies on a
  signed `>>` or `|` result. Write a C bit test such as `(lx|-lx)>>31` as a comparison
  (`lx != 0`).

**Exact and correctly rounded builtins.** `Math.sqrt`, `Math.abs`, `Math.sign`, `Math.max`,
`Math.min` and the arithmetic operators are exact or correctly rounded. Ported code calls
`dart:math`, the `double` member or the operator for them. Give `math.max` and `math.min` only
`double` operands. With literal operands, write the type argument `<double>`.

**Sort.** `jsSort(list, compare)` is an adapter of a few lines. It changes the result of `compare`
to its sign, with NaN as 0, as `Array.prototype.sort` does. Then it calls `mergeSort`. It gives
the V8 order for a consistent comparator only.
- Phase 2 adds `collection: ^1.19.1` as a direct dependency. Tool 1 then allows
  `package:collection/collection.dart` in `lib/` and in the pure layers. Import it with
  `show mergeSort`.
- Ported files sort only through `jsSort`, because only `jsSort` changes the comparator result as
  `Array.prototype.sort` does. `sorted` calls `List.sort`. `sortBy`, `sortByCompare` and
  `sortRange` call `quickSortBy`. These sorts are not stable. `insertionSort`, `sortedBy` and
  `sortedByCompare` are stable, but they do not change the comparator result.
- From phase 2, tool 3 flags `mergeSort(`, `insertionSort(`, `.sorted(`, `.sortedBy(`,
  `.sortedByCompare(`, `.sortBy(`, `.sortByCompare(` and `.sortRange(` in ported files.

**Clock.** `jsDateNow()` returns `clock.now().millisecondsSinceEpoch` as a `double`. It replaces
each `Date.now()` call: `core.animator.js:57`, `:169` and `:201`, `core.animation.js:37` and
`:70`, `core.animations.js:73` and `scale.time.js:342-343`.
- Inside `testWidgets`, `tester.pump` moves this clock. Thus the animation specs run in fake time.
- Chart animations ignore `timeDilation`, as upstream does.
- Phase 5 adds `clock: ^1.1.2` as a direct dependency. Tool 1 then allows
  `package:clock/clock.dart` in `lib/` and in the pure layers. `clock` is Apache-2.0. The package uses it as a
  dependency and copies no code. Thus the package `LICENSE` does not change.

**Translation rules.** Numbers are `double`. An `int` occurs only as a list index, after a
finiteness test.

| JavaScript | Dart |
|---|---|
| `a % b` | `a.remainder(b)` |
| `Math.floor(x)`, `Math.ceil(x)` | `x.floorToDouble()`, `x.ceilToDouble()` |
| `Math.round(x)` | `jsRound(x)` |
| `x \| 0` | `jsToInt32(x)` |
| `Math.max(a, b)`, `Math.min(a, b)` | `math.max(a, b)`, `math.min(a, b)` with `double` operands |
| `Math.max(a, b, c)` | `math.max(a, math.max(b, c))` |
| `Math.max(...xs)`, `Math.min(...xs)` | `xs.fold(double.negativeInfinity, math.max)`, `xs.fold(double.infinity, math.min)` |
| `if (x)`, `!x`, `x \|\| d` for a number `x` | `x != 0 && !x.isNaN`, its negation, `x != 0 && !x.isNaN ? x : d` |
| `Math.pow(x, n)` with an integer `n` | `math.pow(x, n)` with `double` operands |
| `Math.pow(x, y)` with another `y` | `jsPow(x, y)` (fdlibm `e_pow.c`, phase 2) |
| `Math.log10(x)`, `Math.atan2(y, x)` | `jsLog10(x)`, `jsAtan2(y, x)` |
| `'' + n`, `String(n)` | `jsNumberToString(n)` |
| `+s`, `Number(s)`, `parseFloat(s)` | `jsToNumber(s)`, `jsParseFloat(s)` |
| global `isNaN(v)`, `isFinite(v)` | `jsIsNaN(v)`, `jsIsFinite(v)` |
| `Number.EPSILON` | `numberEpsilon` |
| `array.sort(compare)` | `jsSort(array, compare)` |
| `Date.now()` | `jsDateNow()` |

ToBoolean is false for these `Object?` values: `null`, the `undefined` sentinel of
[Chart.js ADR 0006](0006-options-representation-and-resolver.md), `false`, `0`, `-0`, NaN and
`''`. A test of `x || d` on such a value tests the raw value, not a converted number.

Ported files must not use these forms:
- Do not use `num.clamp` for `_limitValue`. Write `math.max(min, math.min(max, value))`, as
  `helpers.math.dart` does.
- Do not call `DateTime.now()`. Call `jsDateNow()`.
- Do not test `is int` on option or data values.
- Do not call the Dart `round()`, `roundToDouble()`, `floor()`, `ceil()`, `truncate()`, `%` or
  `toString()` on numbers.
- Do not interpolate a number into a string, for example `'${size}px'`. On the VM and dart2wasm,
  `'${12.0}'` is `'12.0'`. In JavaScript, `12 + 'px'` is `'12px'`. Use `jsNumberToString`.

**The `js-ok` escape.** Tool 3 is the JS-semantics check of [porting-flow.md](../porting-flow.md)
§4. It examines each file whose header block names a `js` project of
`packages/flutter_chartjs/tool/port_sources.yaml`. These projects are Chart.js, `@kurkle/color`,
chartjs-test-utils and pixelmatch. Tool 3 flags these forms:
- `.round()`, `.roundToDouble()`, `.floor()`, `.ceil()`, `.truncate()`, `.clamp(`, `%`, `is int`
  and `.sort(`
- every `.toString()` call, because the lexical rules do not know the type of the receiver
- `pow(` with any base
- the `dart:math` functions `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `exp` and `log`,
  with the prefix of the `dart:math` import
- the interpolation of a value with the static type `double` or `num`. Tool 3 resolves the types
  with `package:analyzer`.
- from phase 2, the sorts of `package:collection` (Sort)
- from phase 5, `DateTime.now(`, because FakeAsync does not fake it (Clock)

A flagged form can stay only if it gives the JS result for every input that reaches it. Then the
site carries `// js-ok: <reason>` at the end of its line, or alone on the line before it. For
example, `factorize` in `helpers.math.dart` sorts distinct finite numbers with `List.sort`. Its
line carries `// js-ok: distinct finite numbers`.

Tool 3 does not find some conversions of numbers to strings. The reviewer examines these forms:
- the interpolation of a value with another static type that can hold a number, for example an
  `Object?` option value
- `List.join` and `StringBuffer.write` with numbers

**Number formatting.** Depend on `intl: ^0.20.2`, the pin of `flutter_localizations` in Flutter
3.44.9. Library code must import only `package:intl/intl.dart` and its `number_symbols` files.
`intl_standalone.dart` imports `dart:io`. `intl_browser.dart` imports `dart:js_interop`.

**Tests.** Pure-layer specs and the tests of `lib/src/js` run on the VM (`flutter test`). They
also run in Chrome with dart2js and dart2wasm (`dart run melos run test:web`). The bit-for-bit
tests read generated data (`test/port/js/*_reference.dart`). Do not edit that data by hand.

## Alternatives considered

- **Dart number operations as they are.** Rejected. The table in Context shows the mismatches.
- **`jsMax` and `jsMin` in `js_math.dart`.** The pilot wrote them. Replaced. `dart:math` `max` and
  `min` give the JS results on the three targets. The port does not write again what the SDK
  gives.
- **A sort written in the port.** Rejected. `mergeSort` of `package:collection` is stable and pure
  Dart. Only the comparator sign needs port code.
- **`DateTime.now()` for `Date.now()`.** Rejected. FakeAsync does not fake it. Thus
  `tester.pump` does not move the chart animations. The animation specs then fail in fake time.
- **Frame time stamps for `Date.now()`.** Rejected.
  `SchedulerBinding.currentFrameTimeStamp` fails its assert outside a frame. Five of the six
  animation sites can run outside a frame callback. `core.animation.js:56` and `:77` subtract
  absolute `_start` values.
- **A clock parameter**, as [porting-flow.md](../porting-flow.md) §2.10 proposed. Rejected.
  Upstream has no clock parameter. A parameter changes the signatures of the animation classes.
  `package:clock` gives the same test control with no signature change.
- **Flutter `Curves` for `helpers.easing`.** Rejected. Flutter's `Curves.easeInQuad` is
  `Cubic(0.55, 0.085, 0.68, 0.53)` (`curves.dart:1548`), a cubic approximation. Chart.js
  `easeInQuad` is `t * t` (`helpers.easing.ts:15`).
- **`dart:math` for transcendental functions.** Rejected. The VM calls the host C library. The web
  calls the browser. Neither gives the reference bits on all inputs. The two also differ from each
  other.
- **A transcription of V8's `ieee754.cc`.** Rejected. It matched V8. But it adds the V8 BSD notice.
  The netlib port gives the same bits under the fdlibm notice only.
- **A browser or an arm64 Node.js as the reference.** Rejected. Both differ from x64 V8 in the last
  bit for some inputs.
- **Correctly rounded results.** Not chosen now. V8 `main` moved `Math.log10` to a correctly
  rounded LLVM libm on 2026-05-11 (commit `08be4445f6`). The research found that the engines of
  the v4.5.1 era computed `Math.log10` with fdlibm. Against correctly rounded results, V8 13.6
  differs in the last bit on 7 of 5,909 log10 inputs. It gives the same `floor(log10(x))` on all
  of them. [porting-flow.md](../porting-flow.md) §7 keeps this question open.

## Consequences

- A ported file keeps the upstream lines. Only the builtin calls change. A reviewer can compare
  the two files side by side.
- The pure layers give the same results on the VM, dart2js and dart2wasm. CI job `test-web` runs
  the pure-layer tests with dart2js and dart2wasm (`dart run melos run test:web`).
- Each new transcendental builtin costs an fdlibm port, a reference generator and a bit-for-bit
  test. Phase 2 needs three: `sin`, `cos` and `pow`.
- `jsSort` is mandatory for the two upstream sorts with user comparators.
- The pure layers depend on `package:collection` from phase 2 and on `package:clock` from
  phase 5.
- A change of the reference engine amends this ADR. That change regenerates all reference data.
- Section 3 of the bump report lists new builtin sites in a bump range
  ([upstream-tracking.md](../upstream-tracking.md) §4.6).
- When the maintainers accept this ADR, AGENTS.md gets a rule for JS numeric semantics
  ([porting-flow.md](../porting-flow.md) §6).
