# D3 ADR 0003: Number to string and number formatting

- Status: proposed
- Date: 2026-10-20
- Gate: D3 phase 1. The pilot ports d3-path and d3-format. d3-array `ticks.js` of the pilot calls
  `Math.log10`.
- Related: [Chart.js ADR 0026](../../../flutter_chartjs/doc/adr/0026-number-formatting-on-package-intl.md)
  (number formatting as display text),
  [Chart.js ADR 0034](../../../flutter_chartjs/doc/adr/0034-no-display-only-js-exactness.md) (no
  display-only JS exactness),
  [Chart.js ADR 0032](../../../flutter_chartjs/doc/adr/0032-js-numeric-semantics.md) (the JS
  numeric rules and the reference engine),
  [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (the shared runtime
  `js_semantics`), [D3 ADR 0004](0004-spec-harness.md) (reference values and specs),
  [D3 ADR 0006](0006-generators-accessors-and-js-values.md) (JS values),
  [porting-flow.md](../porting-flow.md) §1.1, [prior art](../prior-art/d3-packages.md)

## Context

[Chart.js ADR 0034](../../../flutter_chartjs/doc/adr/0034-no-display-only-js-exactness.md) gives
this principle: the port emulates JavaScript only where the result changes behavior. For the
Chart.js port, the behavior is the ticks, the hit element, the item order, the resolved option, a
throw, and a value that reaches a layout, a scale, an element property, a hit test, a discrete
decision or a public return value. Number strings are display text there. Thus
[Chart.js ADR 0026](../../../flutter_chartjs/doc/adr/0026-number-formatting-on-package-intl.md)
formats numbers with package:intl. A Chart.js ADR binds only the Chart.js port. This ADR states
how D3 applies these rules.

**D3 strings are results.** In these modules, a public function returns a string. The specs
compare it with `assert.strictEqual`.
- **d3-format.** `format(specifier)(value)` builds its string from `toFixed`, `toExponential`,
  `toPrecision`, `toString(radix)`, `x + ""` and `toLocaleString("en")`
  (`d3-format src/formatTypes.js:5-19`, `src/formatDecimal.js:1-19`,
  `src/formatPrefixAuto.js:7`). It is a formatter of its own, not `Intl`. Its 24 test files have
  168 cases with 711 `assert.strictEqual` calls. 6 more calls are in line comments.
- **d3-path.** `Path` appends each coordinate through a tagged template (`d3-path src/path.js:6-11`,
  `:34`). With `digits`, it appends `Math.round(x * k) / k` with `k = 10 ** d` (`:13-24`). An arc
  flag is `${+(da >= pi)}` (`:136`). The d3-shape generators use 3 digits by default
  (`d3-shape src/path.js:4`).
- **d3-geo.** `PathString` follows the same pattern (`d3-geo src/path/string.js:62-86`). `geoPath`
  uses 3 digits by default (`src/path/index.js:11`).
- **d3-color.** `formatHex` writes `value.toString(16)` of a rounded channel
  (`d3-color src/color.js:292-299`). `formatRgb` and `formatHsl` write numbers through templates
  (`:285`, `:377`).
- **d3-time-format.** `pad` writes `value + ""` (`d3-time-format src/locale.js:393-397`).
- d3-delaunay (`src/path.js`), the string interpolators of d3-interpolate and the formatters of
  d3-dsv also write numbers into strings.

A wrong digit there is a wrong result. The d4 port writes the Dart `toString` of a `double` into
its path strings. Thus the VM writes `1.0` where JavaScript writes `1`. An SVG parser rejects
`1.0` as an arc flag ([prior art](../prior-art/d3-packages.md), "How it handles JavaScript
semantics"). The upstream helper `assertPathEqual` normalizes each number to 6 decimals in d3-path
and to 3 decimals in d3-shape and d3-geo (`d3-path test/asserts.js:13-15`). Thus the d4 tests did
not find the defect.

**Probe P1 of the research of 2026-10-20.** It compared Dart with JavaScript for 38 doubles. The
inputs had ±0, ties (0.5, 2.5, −2.5, 1.005, 99.995, 0.045), 1e21, 1.5e21, 1e100, 2^53, the largest
double, 5e-324 and 2.2250738585072014e-308. The JavaScript side ran on an arm64 build of Node.js
v24.12.0. Chart.js ADR 0032 §2 takes reference values only from an x64 build. Thus these results
are indicative only.
- The probe called these methods for each value:
  - `toStringAsFixed(p)` for p in {0, 1, 2, 3, 6, 20}
  - `toStringAsExponential()`, and `toStringAsExponential(p)` for p in {0, 1, 2, 5, 20}
  - `toStringAsPrecision(p)` for p in {1, 2, 3, 6, 21}

  This gave 646 cells. 629 cells were equal to JavaScript on the VM, with dart2js and with
  dart2wasm. The 17 other cells were all for −0. Dart writes `-0.00`, `-0e+0` and `-0.0`.
  JavaScript writes `0.00`, `0e+0` and `0.0`.
- `BigInt.from(x).toRadixString(r)` for r in {16, 8, 2} gave the JavaScript
  `Math.round(x).toString(r)` for all 38 values on the three targets. `x.toInt().toRadixString(16)`
  saturates on the VM and dart2wasm.
- A copy of `jsNumberToString` gave `String(x)` for all 38 values on the three targets. The plain
  `toString()` differed for 9 values on the VM and dart2wasm, and for 1 value with dart2js.
- `x.round()` differed for −2.5 on the three targets. On the VM and dart2wasm, it also saturated
  for 7 values with |x| ≥ 2^63.
- For |x| ≥ 1e21, `Math.round(x).toLocaleString("en")` writes the shortest round-trip digits,
  padded with zeros. For 1e100, the digits are `1` and 100 zeros. `BigInt.from(x).toString()`
  writes the exact binary value. It differed for 1e100 and for the largest double.

**Ranges.** d3-format clamps the precision to [1, 21] for the types `g`, `p`, `r` and `s`, and to
[0, 20] for the other types (`d3-format src/locale.js:61-63`). These are the ranges of the Dart
methods. d3-format formats `Math.abs(value)`. It takes the sign from
`value < 0 || 1 / value < 0` (`:77`, `:80`). Thus −0 does not reach a number method from
`format`.

**Last bits that change D3 behavior.**
- `Math.log10` selects the ticks of d3-array: `power = Math.floor(Math.log10(step))`
  (`d3-array src/ticks.js:7`). This is the case of the Chart.js logarithmic scale.
- The log scale of d3-scale takes `Math.log`, `Math.log10` or `Math.log2` for its base
  (`d3-scale src/log.js:34-37`). A `floor` or `ceil` of the result selects its ticks.
- Containment and hit tests take `Math.atan2`, `Math.asin` and others in d3-geo `contains` and
  d3-delaunay `find`. Most of them compare with an epsilon (`d3-geo src/math.js:1-2`).
- Other geometry values, for example the points of an arc or a projection, are display values.
  A last-bit difference there changes a string only when it changes the printed digits.

## Decision

### 1. Strings are behavior

In the D3 port, a string that a public function returns is behavior. For a given double, its
digits are the digits of the reference engine of Chart.js ADR 0032 §2. This rule applies to these
strings:
- the strings of d3-format
- the path strings of d3-path, d3-geo and d3-delaunay
- the color strings of d3-color
- the strings of d3-time-format
- the string interpolators of d3-interpolate
- the formatters of d3-dsv

The principle of Chart.js ADR 0034 applies to the D3 port with this list of behavior:
- the strings of this section
- the tick values and the interval boundaries of d3-array, d3-scale and d3-time
- the containment and hit results, for example d3-polygon `polygonContains`, d3-geo `contains`,
  d3-delaunay `find` and d3-quadtree `find`
- the item order
- a throw

A difference in the last bit of a value that does not change one of these results is display
only.

### 2. The rules of Chart.js ADR 0032

The D3 port applies these parts of Chart.js ADR 0032. The runtime is `js_semantics`
([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)).
- §1, the JS runtime: ported files call it where upstream calls a builtin or relies on an implicit
  JS conversion.
- §2, the reference engine: an x64 build of Node.js v24.12.0
  ([D3 ADR 0004](0004-spec-harness.md) section 5).
- §3, the transcendental builtins: `Math.log10` is `jsLog10`. `Math.atan2` is `jsAtan2`.
  `Math.sin` and `Math.cos` are `jsSin` and `jsCos` at a site whose result reaches a behavior of
  section 1. At the other sites, they are `dart:math` with `double` operands. `Math.pow` is
  `dart:math` with `double` operands. The other builtins arrive with their first ported caller,
  by the rule of §3 (section 5).
- §4, the exact builtins: `jsMax`, `jsMin`, `jsSquare` and the `(e ?? 0)` rule.
- §5, the sort: `jsSort`. The D3 comparators can return NaN, for example `ascending` for `null`
  (`d3-array src/ascending.js:2`).
- §6, the clock `jsDateNow` on `package:clock`. The gate 6 decision "Timers and frames" applies
  it to d3-timer ([porting-flow.md](../porting-flow.md) §2.14).
- §7, the translation table and the forbidden forms.
- §8, tool 3 and `// js-ok`. Tool 3 examines each D3 file whose header names one of the 34
  repositories.

§9 does not apply. The D3 port uses no package:intl (section 3).

### 3. Number methods

`js_semantics` gets these port-only functions in a new file (ADR 0008 item 6). Each function gives
the string of the reference engine on the VM, with dart2js and with dart2wasm.

| JavaScript | Dart | Rule |
|---|---|---|
| `x.toFixed(p)` | `jsToFixed(x, p)` | `toStringAsFixed(p)`. −0 gives the string of +0 |
| `x.toExponential()`, `x.toExponential(p)` | `jsToExponential(x, [p])` | `toStringAsExponential()` or `toStringAsExponential(p)`. −0 gives the string of +0 |
| `x.toPrecision(p)` | `jsToPrecision(x, p)` | `toStringAsPrecision(p)`. −0 gives the string of +0 |
| `x.toString(radix)` for an integral `x` | `jsToStringRadix(x, radix)` | `BigInt.from(x).toRadixString(radix)`. −0 gives `0`. NaN, Infinity and -Infinity give `NaN`, `Infinity` and `-Infinity` |
| `x.toLocaleString("en")` for an integral or infinite `x` | `jsToLocaleStringEnInteger(x)` | The digits of `jsNumberToString(x)`, padded with zeros to the exponent, with a `,` before each group of three digits. A negative value, −0 included, gets a `-` sign. Infinity gives `∞`. NaN gives `NaN` |
| `x.toString(10)` | `jsNumberToString(x)` | Number::toString (radix 10) |

- **Limits.** JavaScript accepts a precision up to 100. The Dart methods accept [0, 20] for
  `toFixed` and `toExponential`, and [1, 21] for `toPrecision`. Outside these ranges, the
  functions throw a `RangeError`. D3 never passes such a value, because of its clamps
  (`d3-format src/locale.js:61-63`). `jsToStringRadix` and `jsToLocaleStringEnInteger` throw an
  `ArgumentError` for a finite value that is not integral. D3 calls them only with
  `Math.round(x)` (`d3-format src/formatTypes.js:7`, `:13`, `:17-18`, `src/formatDecimal.js:2-4`)
  and with a rounded channel (`d3-color src/color.js:292-299`).
- **One Intl call.** `x.toLocaleString("en").replace(/,/g, "")` (`d3-format src/formatDecimal.js:3`)
  is the only call of an `Intl` function in the D3 sources. Thus the D3 port needs no package:intl.
  The port translates the line as it is: `jsToLocaleStringEnInteger(x).replaceAll(',', '')`.

### 4. Translation rules

These rules add to the table of Chart.js ADR 0032 §7. They are translation rules. They need no
`DIVERGES` marker and no `differences.md` row.

| JavaScript | Dart |
|---|---|
| A number in a template literal, in `x + ""` or in a tagged template | `jsNumberToString(x)` |
| `${+(a > b)}`, a boolean as a number in a string | `${a > b ? 1 : 0}`. An `int` prints with no fraction on each target |
| `cw = 1 ^ ccw` with a boolean `ccw` (`d3-path src/path.js:110`) | `final cw = ccw ? 0 : 1;` |
| `Math.round(x * k) / k` | `jsRound(x * k) / k` |
| `10 ** d` and `Math.pow(10, d)` for an integer `d` | `math.pow(10.0, d)` with `// js-ok: integer exponent`. Chart.js ADR 0032 found the V8 bits for each integer from -340 to 320 on the three targets |
| `+("1e" + x)` (`d3-scale src/log.js:24`) | `jsToNumber('1e${jsNumberToString(x)}')` |
| `x.toFixed(p)`, `x.toExponential(p)`, `x.toPrecision(p)`, `x.toString(radix)`, `x.toLocaleString("en")` | the functions of section 3 |

Ported files must not call `toStringAsFixed`, `toStringAsExponential`, `toStringAsPrecision` or
`toRadixString` on a number. The D3 config of tool 3 flags these calls
([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) item 8). A site that
gives the JS result for each input carries `// js-ok: <reason>`.

### 5. Transcendental builtins in D3

- `Math.log10` is `jsLog10` in d3-array and d3-scale.
- `Math.atan2` is `jsAtan2` at each site. The last bit can change a containment result in d3-geo.
- `Math.log` and `Math.log2` of the d3-scale log scale (phase 3) follow Chart.js ADR 0032 §3 at
  their port. `fdlibm_log.dart` already has `ieee754Log`. Netlib fdlibm 5.3 has no `log2`. Before
  the port of `d3-scale src/log.js`, a probe compares the log-scale ticks of `ieee754Log(x) / ln2`
  with the reference engine. If no tick differs, the site uses that form with `// js-ok`. If a tick
  differs, a new source for `log2` needs its own entry in `port_sources.yaml`
  ([D3 ADR 0001](0001-upstream-sources.md) item 18).
- `Math.exp`, `Math.log1p`, `Math.expm1`, `Math.hypot`, `Math.cbrt`, `Math.tan`, `Math.asin`,
  `Math.acos` and `Math.atan` arrive with their first caller, by the rule of Chart.js ADR 0032 §3.
- A spec case that asserts a geometry string with all digits can fail in its last digit through a
  `dart:math` result. Then the case skips as `'diverges: js-semantics-dart-math'`. The first such
  case adds this row to [differences.md](../differences.md). No such case is known now.

## Alternatives considered

- **Strings as display text,** as Chart.js ADR 0026 does for `Intl.NumberFormat`. Rejected. The
  strings are the return values of public functions. The specs compare them exactly. The 168
  d3-format cases alone compare strings. The wrappers of section 3 are short. The rejected
  ICU-exact formatter of Chart.js had about 1,800 lines
  (Chart.js ADR 0032, Alternatives considered).
- **The Dart number methods with no wrapper.** Rejected. 17 cells of probe P1 differ for −0. The
  plain `toString()` and `round()` differ on the VM and dart2wasm.
- **package:intl for `toLocaleString("en")`.** Rejected. D3 needs only the grouped digits of an
  integral value. A dependency for one call adds a package to every app.
- **`BigInt.from(x).toString()` for `toLocaleString("en")`.** Rejected. It writes the exact binary
  value, for example `10000000000000000159…` for 1e100. JavaScript writes the shortest round-trip
  digits.
- **fdlibm ports of every transcendental builtin.** Rejected, by the reasons of Chart.js ADR 0034,
  decision 1. A bit-for-bit port is due only where a last bit changes a result of section 1.
- **A cross-port ADR for the JS numeric rules now.** Not chosen. ADR 0008 moves the runtime. It
  does not change what a runtime function does (ADR 0008 item 6). This ADR states the D3 use of
  Chart.js ADR 0032. A later cross-port ADR can state the rules for all ports.

## Consequences

- d3-format, d3-path and the other string modules give the JavaScript strings on the VM, with
  dart2js and with dart2wasm. The pilot of phase 1 tests this with the cases of d3-path (64) and
  d3-format (168).
- `js_semantics` gets the functions of section 3, their tests and a reference generator. The
  generator writes the expected strings from an x64 build of Node.js v24.12.0
  ([D3 ADR 0004](0004-spec-harness.md) section 5). On 2026-10-20, the machine of the maintainer had
  no such build ([porting-flow.md](../porting-flow.md) §7, risk 8).
- Phase 1 runs probe P1 again on the x64 reference engine. Its inputs go into the reference data,
  with more ties, the 1e21 boundary, subnormals and random bit patterns for each precision.
- Tool 3 for D3 flags the Dart number-to-string methods of section 4.
- The D3 port has no package:intl dependency. Thus Chart.js ADR 0026 has no D3 counterpart.
- A geometry string can still differ from JavaScript in a last digit through `dart:math`. Such a
  case skips with the reason of section 5 and a row.

## Evidence

- Probe P1: `numbers_probe.mjs` and `probe.dart` of the research of 2026-10-20, outside the
  repository. The JavaScript side ran on Node.js v24.12.0 arm64. The Dart side ran on the VM, with
  dart2js and with dart2wasm. The results are indicative only (Context). A recount of its output
  files gave the same cell counts.
- A second probe on the same arm64 build gave these strings:
  - `Infinity.toLocaleString("en")` is `∞`.
  - `(1e21).toLocaleString("en")` is `1,000,000,000,000,000,000,000`.
  - `(-0).toLocaleString("en")` is `-0`.
  - `(1e21).toFixed(2)` is `1e+21`.
  - `(-0.001).toFixed(2)` is `-0.00`.

  These values are indicative only. The reference generator of section 3 replaces them with x64
  values.
- The counts of the d3-format tests come from a scan of `test/*-test.js` at v3.1.2, with the
  comments removed. [parity.md](../parity.md) has the case count script.
