# D3 ADR 0007: Native Dart forms, no JS runtime

- Status: accepted (2026-11-15): its code and the tests of section Tests pass.
- Date: 2026-11-15
- Supersedes: [D3 ADR 0003](0003-number-to-string.md), whole
- Related: [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [Chart.js ADR 0146](../../../flutter_chartjs_port/doc/adr/0146-js-numeric-semantics.md)

## Context

D3 ADR 0003 (proposed) translates the numbers and the number texts of D3 through a JS runtime:
`jsNumberToString`, `jsToFixed`, `jsRound`, `jsAtan2` and the shared package `js_semantics`. On
2026-11-15 the maintainer decided that the D3 port uses only native Dart and Flutter forms.
d3-color 3.1.0 is the first ported module. This ADR keeps the section numbers of D3 ADR 0003.

## Decision

### 1. Texts are behavior

- A text that a public function of a D3 module returns is behavior. Examples are the texts of
  d3-format, the path texts of d3-path, d3-geo and d3-delaunay, the color texts of d3-color, the
  texts of d3-time-format, the string interpolators of d3-interpolate and the formatters of
  d3-dsv. Its digits are the digits of upstream on the reference engine.
- These results are behavior too: the tick values and the interval boundaries of d3-array,
  d3-scale and d3-time, a containment or hit result, the item order and a throw.
- A last-bit difference of a number that changes none of these results is display only. It needs
  no fix.

### 2. No JS runtime

- No `js_semantics`: a D3 package depends on no JS runtime and on no other port. Ported code has
  no `undefined` sentinel, no `jsCall`, no `jsGet` and no emulated builtin.
- Where upstream relies on an implicit JS conversion, the ported line writes the native Dart form
  of §4 at the site.

### 3. Number methods

- `x.toStringAsFixed(p)`, `x.toStringAsExponential(p)` and `x.toStringAsPrecision(p)` translate
  `x.toFixed(p)`, `x.toExponential(p)` and `x.toPrecision(p)` at the call site.
- `x.toInt().toRadixString(radix)` translates `x.toString(radix)` of a whole number.
- A module whose texts differ from the reference engine through these methods, for example for
  -0, writes the fix at the site. Its reference test finds the difference, and the fix gets a row
  of `differences.md`.

### 4. Translation rules

- `${x}` and `x + ""` of a number: the shortest text of the double, as `double.toString` gives
  it, with no `.0` for a whole number and `0` for -0.
- `a > b ? 1 : 0` translates `+(a > b)`.
- `x != 0 && !x.isNaN` translates the test `if (x)` of a number.
- `x.isNaN || x == 0 ? 0.0 : x` translates `x || 0` of a number.
- `x.remainder(y)` translates `x % y`.
- `x.roundToDouble()` translates `Math.round(x)`. A negative half rounds away from zero, where
  JavaScript rounds up. A site where this changes a result writes a form that gives the upstream
  result, for example `clampi` of d3-color.
- `math.max` and `math.min` of `dart:math`, with `double` operands, translate `Math.max` and
  `Math.min` of two numbers.
- `math.pow(10.0, d)` translates `10 ** d`.
- `double.parse(text)` translates `+text` of a decimal number text.
- `x is C` translates `x instanceof C`.
- These translations need no `DIVERGES` marker and no row.

### 5. Transcendental builtins

- `math.sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `exp`, `log` and `pow` of
  `dart:math`, with `double` operands, translate the `Math` functions of the same names.
- `math.log(x) * math.log10e` translates `Math.log10(x)`, with the exponent itself for an exact
  power of ten, so a tick choice stays the same.
- The last bit of these results can differ from V8 and between platforms. A spec case that fails
  only through such a bit skips as `'diverges: <row id>'`, with a `platform` row in
  `differences.md`. A reference test compares these results with a tolerance.

## Rejected

- The JS runtime of the shared package `js_semantics`: it keeps the JS object model in Dart and
  costs speed.
- Copies of fdlibm for bit-exact transcendental results: in the specs of d3-color, the last bits
  change no behavior of §1.

## Consequences

- A D3 module needs no shared runtime package.
- The reference test of each module compares its texts with upstream on the reference engine.
- D3 ADR 0006 §1 to §5, §8 and §9 (proposed) still translate accessors, function values, `this`
  and errors through the runtime. The port of the first module that needs them gets a new ADR with
  native forms for them.
- ECharts ADRs 0003 and 0004 (proposed) cite sections of D3 ADRs 0003 and 0006 that no longer
  hold for the D3 port.

## Tests

- `packages/flutter_d3_color_port/test/port/reference_test.dart`
- `packages/flutter_d3_color_port/test/port/number_text_test.dart`
- `packages/flutter_d3_color_port/test/port/clamp_compare_test.dart`
