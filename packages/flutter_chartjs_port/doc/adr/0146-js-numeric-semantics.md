# Chart.js ADR 0146: JS numeric semantics and the reference engine

- Status: accepted (2026-11-14): it restates accepted decisions, and the code passes the tests.
- Date: 2026-11-14
- Supersedes: Chart.js ADRs [0045](0045-reference-engine-arm64.md), [0122](0122-dart-math-without-fdlibm.md),
  [0134](0134-dart-math-max-min.md), [0135](0135-math-hypot-as-sqrt.md), [0136](0136-math-pow-square.md),
  [0138](0138-math-round-as-round-to-double.md) and [0143](0143-clock-now.md), whole. The fdlibm parts of
  [Chart.js ADR 0035](0035-third-party-sources.md): items 2 (the copy `third_party/fdlibm/`), 3 (the source entry),
  4 (the target row), 5 (the version bullet) and 6 (the SunPro notice, `LICENSES/SunPro.txt` and the `REUSE.toml`
  tables), and the fdlibm consequence. The rule of a copy in item 2 stays in force. The `jsHypot` parts of
  [Chart.js ADR 0108](0108-input-surface-and-exports-for-add-on-plugins.md): §2, its test rows and the rejected
  `math.sqrt` form.
- Related: Chart.js ADRs [0034](0034-no-display-only-js-exactness.md), [0119](0119-plain-intl-number-format.md)
  and [0129](0129-int-indexes.md)

## Context

The upstream specs and fixtures assert values that a JavaScript engine computed. Dart number operations give other
results in many places, also between the VM, dart2js and dart2wasm.
[Chart.js ADR 0034](0034-no-display-only-js-exactness.md) limits the emulation of JavaScript to the results that
change behavior.

This ADR restates [Chart.js ADR 0045](0045-reference-engine-arm64.md) and the six ADRs that changed it, with the
section numbers of Chart.js ADR 0045.

## Decision

### 1. JS runtime

`packages/flutter_chartjs_port/lib/src/js/` holds the JS builtins and value operations whose Dart forms give another
behavior. Ported files call it where upstream calls such a builtin or relies on an implicit JS conversion.
`js_math.dart` keeps only `numberEpsilon` and `jsToInt32`.

- A builtin whose plain Dart form gives the JS behavior has no runtime function. Ported code writes the Dart form at
  the call site.
- Each `js_*.dart` file is port-only. The runtime is a core layer and imports no `package:flutter` library. Only
  `js_webidl.dart` imports `dart:ui`.
- Runtime code can use any implementation that gives the JS results on the VM, dart2js and dart2wasm.
- `lib/js_semantics.dart` exports the runtime for the add-on ports
  ([Chart.js ADR 0132](0132-exports-for-add-on-chart-types.md)). An add-on port imports `dart:math` and
  `package:clock` itself.

### 2. Reference engine

The reference engine is V8 13.6.233.17-node.58 in the official Node.js v24.22.1 for darwin-arm64, with ICU 78.3.

- All reference data and expected JS values of the port tests come from this engine, never from a browser. The
  text-metric generator `tool/reference/text_metrics/` measures in headless Chrome, outside this rule.
- Each reference run writes the Node.js version, the V8 version and the architecture into its output. A run that
  reads ICU data also writes the ICU and CLDR versions. Do not edit the generated files by hand.
- Before the commit, the porting lead examines each value that a new run changes and finds its cause. The lead
  writes a last-bit change of a `Math` builtin only where its test compares with a tolerance.
- A change of the reference engine needs a new ADR and new reference data.

### 3. Transcendental builtins

- `Math.sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `exp` and `log` are the `dart:math` function as it is,
  with `double` operands. The sites carry no `js-ok` comment. The easing sites of `helpers.easing.dart` carry the
  marker of row `js-semantics-dart-math`.
- `Math.log10` is `log10` of `helpers.math.dart`: `math.log(x) * math.log10e`, and the exponent itself for an exact
  power of ten. Thus a logarithm floor keeps the tick spacing, label decimals and logarithmic ticks
  (row `adapt-log10-powers`).
- The last bit of these results can differ from V8 and between the targets. It changes a decision only for an input
  exactly on a boundary.
- `Math.pow(x, y)` is `math.pow(x, y).toDouble()` with `double` operands and a `js-ok` comment. V8 calls the platform
  C `pow`, so its last bit can differ, but not for `math.pow(10.0, k)` with an integer `k` from -340 to 320.
  `dart:math` gives 1 for `pow(1, NaN)` and `pow(±1, ±Infinity)`, where JavaScript gives NaN.
- The port has no fdlibm code.

### 4. Exact and correctly rounded builtins

- `Math.sqrt`, `Math.abs`, `Math.sign` and the operators are `math.sqrt`, `abs()`, `sign` and the Dart operators.
- **`Math.max(a, b)` and `Math.min(a, b)` with `double` operands** are `dart:math` `max` and `min` with the type
  argument `double`. They give the JS results for NaN and the signed zeros.
  - Write `<double>` where inference gives `num`: an `int` literal operand outside a `double` context, or a call in a
    `num` context, such as an operator operand. Example: `math.max<double>(x, 0)`. A `double` context (an assignment,
    a return or a `double` parameter) infers `double`, and `prefer_int_literals` keeps its literal an `int`. Its fix
    turns `math.max(0.0, x)` into `math.max(0, x)`, so the explicit `<double>` is the safe form.
  - `Math.max(a, b, c)` is `math.max(a, math.max(b, c))`. `Math.max(...xs)` is
    `xs.fold(double.negativeInfinity, math.max)` on a `List<double>`.
  - `_limitValue` is `math.max(min, math.min(max, value))` (`limitValue` of `helpers.math.dart`), never `num.clamp`.
  - With `int` operands (list indexes), they are `max` and `min` on `int`.
- **`Math.pow(x, 2)`** is `math.pow(x, 2.0).toDouble()` with the `js-ok` comment of §3. It gives the bits of `x * x`
  on every target, as V8 does.
- **`Math.hypot(a, b)`** is `math.sqrt(a * a + b * b)` with `double` operands. At pixel sizes, only the last bit
  differs from V8. A caller whose operands can overflow or underflow needs its own decision.
- **`ToNumber` of a `double?` whose `null` is JS `null`** is `(e ?? 0)`. A `double?` whose `null` is JS
  `undefined` takes `e ?? double.nan`. An `Object?` value takes `jsToNumber`.
- These translation rules need no `DIVERGES(chartjs)` marker.

### 5. Sort

`jsSort(list, compare)` changes the result of `compare` to its sign, with NaN as 0, as `Array.prototype.sort` does.
Then it calls the stable `mergeSort`. It gives the V8 order for a consistent comparator.

- `collection: ^1.19.1` is a direct dependency. `check:lib-imports` allows `package:collection/collection.dart` in
  `lib/` and in the core layers only with `show mergeSort`.
- Ported files sort only through `jsSort`. `List.sort` is not stable above 32 elements on the VM, dart2wasm and DDC.
  The other sorts of package:collection are not stable, or keep the raw comparator result.
- A `List.sort` call stays only where every order is the same, with `// js-ok: <reason>`.

### 6. Clock

`Date.now()` is `clock.now().millisecondsSinceEpoch` of package:clock. A caller that computes with `double` values
adds `.toDouble()`. A caller that computes with `int` values keeps the `int`.

- The callers are `core.animation`, `core.animations`, `core.animator`, `date_parse` and `scale.time`. Their comments
  keep the upstream `Date.now()` citations. The benchmark of the gallery also reads `clock.now()`, the clock of the
  chart animations.
- Inside `testWidgets` and `withClock`, the fake clock moves `clock.now()`. Chart animations ignore `timeDilation`, as
  upstream does.
- Ported code never calls `DateTime.now()`: FakeAsync does not move the system clock.
- `clock: ^1.1.2` (Apache-2.0) is a direct dependency of the package and of the gallery. `check:lib-imports` allows
  `package:clock/clock.dart` in `lib/`, in the core layers and in the tests of the web legs.

### 7. Translation rules

Numbers are `double`. An index is an `int` ([Chart.js ADR 0129](0129-int-indexes.md)).

- `a % b`: `a.remainder(b)`
- `Math.floor(x)`, `Math.ceil(x)`, `Math.round(x)`: `x.floorToDouble()`, `x.ceilToDouble()`, `x.roundToDouble()`
- `x | 0`: `jsToInt32(x)`
- `if (x)`, `!x`, `x || d`: `jsTruthy(x)`, `!jsTruthy(x)`, `jsTruthy(x) ? x : d`
- `'' + n`, `String(n)`, a template literal: `jsNumberToString(n)`, or `jsToString(v)` for any value
- `+s`, `Number(s)`, `parseFloat(s)`: `jsToNumber(s)`, `jsParseFloat(s)`
- global `isNaN(v)`, `isFinite(v)`: `jsIsNaN(v)`, `jsIsFinite(v)`
- `Number.EPSILON`: `numberEpsilon`
- `array.sort(compare)`: `jsSort(array, compare)`
- `Object.keys(o)`, `for-in`, `Object.assign`, an object spread: `jsObjectKeys(o)`

**`Math.round`.** `roundToDouble()` differs from `Math.round` only for a negative exact half: `-0.5` gives -1, and
`-2.5` gives -3. Row `adapt-dart-round` covers each `Math.round` site. The result differs at three places:
`alignPixel`, the category `getValueForPixel` and `getRelativePosition`. The zoom port and the matcher
`toBeCloseToPoint` use `roundToDouble()` too.

**ToBoolean.** ToBoolean is false for `null`, the `undefined` sentinel, `false`, `0`, `-0`, NaN and `''`. It is true
for every other value, also for an empty `List` or `Map`. A test of `x || d` tests the raw value. For a `double` `x`,
`x != 0 && !x.isNaN` is the same test.

### 8. Tool 3 and `js-ok`

Tool 3 (`check:js-semantics`) examines `flutter_chartjs_port`, the two add-on ports
([ADR 0009](../../../../docs/adr/0009-add-on-ports.md) item 6) and `chartjs_test_utils`. It reads each `lib/` and
`test/` file whose header names a `js` project of a `tool/port_sources.yaml`, or a project that no such file lists.
It flags these forms:

- `.round()` (the advice names `roundToDouble()`), `.floor()`, `.ceil()`, `.truncate()`, `.clamp(`, `%`, `is int`
  and `.sort(`
- every `.toString()` call, and `pow(` with any base
- the interpolation of a `double` or `num` value
- each call and tear-off of `dart:math` `max` and `min` with the type argument `num`, explicit or inferred
- the sorts of package:collection
- `DateTime.now(`, with advice that names `clock.now()`

It does not flag the transcendental `dart:math` functions or `.roundToDouble()`. The lexical rules read the code
without comments and string contents. The interpolation and `max`/`min` rules resolve types with `package:analyzer`.

A flagged form stays only where it gives the JS result for each input, or where this ADR keeps it (`pow`). The
site then carries `// js-ok: <reason>` at the end of its line, or alone on the line before it. Tool 3 fails on a
`js-ok` without a reason, and warns about a `js-ok` with no flagged site. The reviewer examines an `Object?`
interpolation, `List.join` and `StringBuffer.write` with numbers.

### 9. Number formatting

`Intl.NumberFormat` is the `NumberFormat` of package:intl as it is
([Chart.js ADR 0119](0119-plain-intl-number-format.md)). `lib/src/js/` has no number format code. The package
depends on `intl: ^0.20.2`. Library code imports only `package:intl/intl.dart`, `number_symbols.dart` and
`number_symbols_data.dart`, never `intl_standalone.dart` or `intl_browser.dart`.

### 10. Tests

- The core-layer specs and the tests of `lib/src/js/` run on the VM, dart2js and dart2wasm.
- The test of `jsNumberToString` compares bit for bit with the generated data, with NaN as NaN.
- Each test that reads a generated data file pins `v24.22.1` and `arm64`.
- A value that depends on the last bit of a `dart:math` result compares with a tolerance.
- The port tests of `distanceBetweenPoints`, `getAngleFromPoint`, `isPointInArea`, `pointInLine` and
  `steppedInterpolation` compare the `(e ?? 0)` form with the `jsToNumber` and `Math.pow` form, also for JS `null`,
  ±0, NaN, ±Infinity, subnormals and squares that overflow. `js_math_test.dart` pins `max`, `min` and `pow(x, 2.0)`
  bit for bit against the JS results.
- Each hit query stays checked. A generator moves a sample exactly on a tie of two arcs by a fraction of a pixel.
  The doughnut generator moves the opposite-center midpoint in `parsed: object items with the default key`. It also
  moves the hidden-arc seam in `legend: click` and `legend: click twice`. A regression shifts the arc centers by
  ±1e-10 px and requires the same hits.
- The ported easing spec allows one unit of 1e-8 at the rounding ties (row `js-semantics-dart-math`).
- For row `adapt-dart-round`, the 11 grid-line cases of `core.scale.tests.js` with a line at 0 skip. The reference
  harnesses accept -1 or -0.5 where the reference has 0 or 0.5. The probe `valueForPixel` of a category scale
  records `Math.round` of a raw negative exact half (`_jsValueForPixel` of `scale_chart_harness.dart`).

## Rejected

- Dart number operations as they are: they change ticks, hit elements, labels and the item order.
- fdlibm ports of `sin`, `cos`, `atan2` and `log10`: their data needed a frozen x64 engine.
- `jsMax`, `jsMin`, `jsSquare`, `jsRound`, `jsHypot` and `jsDateNow`: the plain Dart form gives the same behavior.

## Consequences

- A ported file keeps the upstream lines, except the builtin calls and the conversions.
- A click exactly on the border of two arcs can hit one arc where Chart.js hits both.
- A line at the left or top edge of the canvas draws one pixel off.

## Tests

- `test/port/js/js_math_test.dart`, `js_number_test.dart`, `js_array_test.dart`
- `test/port/helpers/helpers.math_test.dart`, `helpers.canvas_test.dart`, `helpers.dom_test.dart`,
  `helpers.interpolation_test.dart`
- `test/port/controllers/controller.doughnut_test.dart`, `test/specs/helpers.easing_test.dart`,
  `test/port/options/observation_test.dart`
- `test/tool/check_js_semantics_test.dart`, `check_lib_imports_test.dart`, `public_api_test.dart`

## Open

1. **The Windows run.** Resolved (2026-10-21): the Windows leg of CI run 39569626698 passed the doughnut and pie
   tie cases. §10 gives the current handling of a tie.
2. Removed: the frame figure of `jsSin` and `jsCos`.
3. Removed: `asin` and `pow` on protected paths.
4. **Correctly rounded results.** [porting-flow.md](../porting-flow.md) §7 keeps this question open. A move of the
   reference engine to a correctly rounded library needs a new ADR.
5. Removed: an x64 engine for the fdlibm data.
6. **The cross-port rule.** [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (proposed)
   plans a shared runtime package. Its ADR then supersedes this ADR and keeps §2.
