# Chart.js ADR 0026: Number formatting on package:intl

- Status: accepted (2026-10-20)
- Date: 2026-10-20
- Supersedes: [Chart.js ADR 0008](0008-number-formatting-on-package-intl.md)
- Related: [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (no display-only JS
  exactness), [Chart.js ADR 0010](0010-js-numeric-semantics.md) (the reference engine,
  `Number::toString`)

## Context

Chart.js ADR 0008 (accepted 2026-10-18) decided that `Intl.NumberFormat` is the `NumberFormat` of
package:intl, with a short adapter. Its decision 5 has three guards against package:intl
failures. A review of the adapter found four more defects. Each defect gives a label with
another value than V8, or a throw:
- **Numbers from `2^53`.** On the VM and dart2wasm, package:intl writes the binary value of the
  double, and a 64-bit integer overflows from `2^63`. `formatNumber(1e21, 'en-US')` gives
  `922,337,203,685,477,580,700`. V8 gives `1,000,000,000,000,000,000,000`. `getLabelForValue`
  (`scale.linearbase.js:311`) passes these default options. Below `2^63`, `2^60` gives
  `1,152,921,504,606,846,976`. V8 gives `1,152,921,504,606,847,000`. With three significant
  digits, `1e19` gives `8,400,000,000,000,000,000`. On dart2js, package:intl writes 16 digits and
  zeros: `2^64` gives `18,446,744,073,709,550,000`. V8 gives `18,446,744,073,709,552,000`.
  Compact notation overflows from `2^63` units on the VM: `1e37` gives
  `9223372036854775807000000T`. On dart2js, compact notation throws `Infinity.round()` for
  `±Number.MAX_VALUE` in `de` and `ja`.
- **NaN and the infinities.** package:intl writes NaN without the prefix and the suffix of the
  pattern, and an infinity without the suffix. The percent style gives `NaN`, `∞` and `-∞`. V8
  gives `NaN%`, `∞%` and `-∞%`. The currency style gives `NaN`. V8 gives `$NaN`. In `de-DE`, V8
  gives `NaN %` and `∞ €`, with U+00A0.
- **Scientific notation.** The scientific pattern of package:intl takes the exponent from a
  logarithm. `log(1e15) / ln(10)` is `14.999999999999998`. Thus `1e15` gives `10E14` with any
  digit options. Also, a mantissa that rounds up to 10 keeps its exponent: `9.5e14` with no
  fraction digits gives `10E14`, `9.99e20` gives `10E20` and `9.5e-7` gives `10E-7`. V8 gives
  `1E15`, `1E21` and `1E-6`. `formatters.numeric` uses scientific notation when the largest tick
  is above `1e15` or below `1e-4` (`core.ticks.js:40`). For ticks of `1e15` or more apart, it
  asks for no fraction digits (`core.ticks.js:54`). In some locales, the scientific pattern of
  package:intl has brackets (`hi`: `[1.5E0]`) or no exponent (`lo`: `1,5`). V8 writes the decimal
  pattern and the exponent there.
- **More than 15 fraction digits.** The cap of 15 fraction digits of Chart.js ADR 0008 applies to
  all digit options. `formatters.numeric` asks for up to 20 fraction digits, for a tick spacing
  below `1e-15` (`core.ticks.js:54`). Data with rounding errors gives such ticks. For the data
  `0.3` and `0.1 + 0.2`, upstream makes the ticks `0.3` and `0.30000000000000004`, with 17
  fraction digits. V8 gives the labels `0.30000000000000000` and `0.30000000000000004`. With the
  cap, package:intl gives `0.300000000000000` for both.

A probe compared the adapter of Chart.js ADR 0008 with V8 strings of the reference engine, on the
VM and on dart2js. The cases are the reference data of decision 9:

| Case group | Cases | Different strings on the VM | Different strings on dart2js |
|---|---:|---:|---:|
| numbers from `2^53` | 2,051 | 1,601 | 789 |
| NaN and the infinities | 96 | 34 | 34 |
| scientific notation | 2,985 | 1,293 | 1,293 |
| compact notation from `2^53` units | 418 | 244 | 129 |
| more than 15 fraction digits below `2^53` | 620 | 585 | 585 |

Over the 119 locales of package:intl, scientific notation of six values gave the V8 string for
452 of 714 cases. The percent style gave the V8 string for 4 of 357 cases of NaN and the
infinities.

These differences are not only digits. A label of `1e21` shows another number. `10E14` has a
mantissa of 10. A percent label of NaN has no percent sign. Two different ticks with the same
label show one value two times. A throw stops the chart. Thus
[Chart.js ADR 0009](0009-no-display-only-js-exactness.md) does not exclude these fixes.

This ADR states the complete current decision. It changes decisions 5 (the guards) and 9 (the
tests), and the consequences. It adds decision 10 (the cap of the fraction digits). It keeps the
other decisions of Chart.js ADR 0008. It supersedes Chart.js ADR 0008. The text
below repeats the context of Chart.js ADR 0008, with the references brought up to date.

Chart.js formats numbers with `Intl.NumberFormat` in `helpers.intl.ts`. Five call sites use
`formatNumber`:
- the tick formatters `formatters.numeric` and `formatters.logarithmic` (`core.ticks.js:59`)
- `getLabelForValue` of the linear and logarithmic scales (`scale.linearbase.js:311`,
  `scale.logarithmic.js:195`)
- the label items of the doughnut and polar area controllers (`controller.doughnut.js:321`,
  `controller.polarArea.js:99`)

The strings are text for people. No upstream code parses them back into numbers. But
`core.scale` measures each tick label. The label widths set the axis size, the label rotation and
the auto-skip. Thus another string can move the chart area.

The package depends on `intl: ^0.20.2` ([Chart.js ADR 0010](0010-js-numeric-semantics.md)). The
`NumberFormat` of package:intl does not give the strings of the reference engine. The reference
engine is V8 13.6 with ICU 77.1 and CLDR 47 in Node.js v24.12.0 on x64. A probe of the phase 2
stream formatted the V8 reference cases with package:intl 0.20.2. It used the closest option
mapping:

| Case group | Cases | Different strings |
|---|---:|---:|
| tick labels (the calls of the upstream `core.ticks.js`) | 4,479 | 212 |
| edge values (digit, notation and grouping options) | 4,971 | 2,049 |
| locales | 4,305 | 502 |

Examples of the differences of package:intl:
- `maximumSignificantDigits: 3` on `1.994e-7` gives `0.0000002` in the probe mapping. V8 gives
  `0.000000199`. The adapter sets only the given bounds and gives `0.000000199`.
- `0.000075` with five fraction digits gives `0.00007`. V8 gives `0.00008`. ICU rounds the
  shortest decimal string of a double. package:intl rounds the binary value.
- Scientific notation of `5e-324` throws `Infinity or NaN toInt`.
- package:intl has no minimum grouping digits. `af` with `useGrouping: 'min2'` gives `1 234`. V8
  gives `1234`.
- The CLDR data change with the intl version. intl 0.20.2 has CLDR 46. intl 0.20.3 has CLDR 48.

The phase 2 stream wrote an ICU-exact formatter (the first alternative below). It gave the V8
string for all 15,889 reference cases. The maintainers rejected its cost. Apps already use
package:intl for their own numbers, and their users accept its results.
[Chart.js ADR 0009](0009-no-display-only-js-exactness.md) states the general principle.

## Decision

1. **Formatter.** `Intl.NumberFormat` is the `NumberFormat` of package:intl.
   `lib/src/js/js_intl.dart` is a short port-only adapter. `jsNumberFormat(locale, options)` maps
   the JS locale and the JS options object onto a `NumberFormat` constructor and its fields.
   Library code imports only `package:intl/intl.dart` for this.
2. **Locale.** `jsNumberFormatLocale` maps the locale argument:
   - A String goes through `Intl.verifiedLocale` with `NumberFormat.localeExists`. Thus `'en-US'`
     gives `en_US`, and `'de-DE'` gives `de`.
   - A List is a list of tags. The first String tag with intl data gives the locale. V8 also takes
     the first supported tag. Thus the cache key of `['de']` and of `'de'` gives the same format.
   - `undefined`, JS `null` and any other value give `Intl.getCurrentLocale()`. An app sets this
     locale with `Intl.defaultLocale`. Without it, the locale is `en_US`. `flutter_test` also
     gives `en_US`.
   - A tag without intl data gives the current intl locale. V8 also falls back to its default
     locale. If the current locale has no data, the result is `en_US`.
3. **Options.** The adapter maps these options:
   - `style`: `decimal`, `percent`, and `currency` with `currency`. The currency style selects
     `NumberFormat.simpleCurrency`.
   - `notation`: `standard`, `scientific` and `compact` (`NumberFormat.compact`). Scientific
     notation selects the decimal pattern (decision 5). The percent style ignores `notation`. The
     currency style ignores `scientific` and `compact`.
   - `currency`: the adapter writes the code in upper case. ECMA-402 does the same.
   - `minimumIntegerDigits`, `minimumFractionDigits`, `maximumFractionDigits`,
     `minimumSignificantDigits` and `maximumSignificantDigits`, with the defaults of ECMA-402.
     The significant digits win over the fraction digits.
   - `useGrouping`: a falsy value turns the grouping off. Every other value keeps the grouping of
     the locale.
4. **Unsupported options.** The adapter ignores every other option and value. Examples are
   `style: 'unit'`, `signDisplay`, `roundingMode` and `currency` style without a `currency`. Thus
   an option of a user does not stop a chart. No upstream code, spec or doc example passes
   `notation: 'engineering'`, `compactDisplay` or `currencyDisplay`. Thus the adapter does not map
   them:
   - `engineering` gives scientific notation.
   - `compactDisplay: 'long'` gives the short compact notation.
   - `currencyDisplay: 'code'` gives the simple symbol.

   A digit option outside its ECMA-402 range, or a minimum above its maximum, throws an
   `ArgumentError`. V8 throws a `RangeError` there.
5. **Guards.** package:intl throws or writes wrong digits for some values. The adapter wraps the
   `NumberFormat` in a `JsNumberFormat` with six guards. Thus `format` does not throw for a
   double. Four guards write the digits without package:intl. They take the shortest decimal
   digits of the double from `jsNumberToString` (`Number::toString`), as ICU does. They round
   these digits half away from zero, the `halfExpand` rounding of ECMA-402. They take the
   symbols, the prefixes, the suffixes, the zero digit and the minimum integer digits from the
   `NumberFormat`.
   1. **The cap of the fraction digits.** The adapter gives package:intl at most 15 fraction
      digits on every platform. The percent style gets two digits less. package:intl multiplies
      by `10^digits` in an `int`. On dart2js, the low digits go above `2^53` after 15 digits. One
      cap for all platforms gives the same fraction digits on all platforms. With significant
      digits, package:intl takes the fraction digits from the value. Thus the cap applies to them
      too. A value below about `1e-15` loses its digits. For example, `1.5e-100` with three
      significant digits gives `0`. The cap applies only where package:intl writes the digits:
      the standard notation below `2^53` with significant digits, or with at most 15 fraction
      digits, and compact notation.
   2. **NaN and the infinities.** The adapter writes the NaN or infinity symbol between the
      prefix and the suffix of the pattern: NaN and `+∞` take the positive affixes, `-∞` takes
      the negative affixes. V8 does the same. Compact notation writes the symbols as the decimal
      style does, because package:intl throws for them.
   3. **Numbers from `2^53` in the standard notation.** The adapter writes the shortest digits
      and zeros, as V8 does. The percent style moves the digits by two places. Significant
      digits round the digits. The pattern of the style gives the groups, as package:intl reads
      them: the size of the digits after the last comma, and between the last two commas. The
      fraction has the minimum fraction digits, or the zeros that the minimum significant digits
      ask for. At `2^53`, the adapter gives the string of package:intl for each locale.
   4. **Compact numbers from `2^53` units.** Compact notation formats `1e18` and `-1e18` with
      package:intl one time. `1e18` is above the largest unit of each intl locale. The digits from
      the `1` to the end of the integer give the exponent of the unit that package:intl selects.
      The minimum integer digits can add zeros before the `1`, and the adapter does not count
      them. The text before and after the digits gives the prefix and the suffix. From `2^53`
      units, the adapter writes the shortest digits of the count of units and zeros, with the
      prefix and the suffix. The significant digits round the digits, as in guard 3. The minimum
      significant digits, or else the minimum fraction digits, give the zeros of the fraction.
      The doubles from `2^53` units are more than one unit apart. Thus the count has no fraction
      digits to round. The adapter does not group the digits, as package:intl does not group
      compact numbers.
   5. **Scientific notation.** The adapter takes the exponent from the shortest digits. It rounds
      the digits to the maximum significant digits, or to the maximum fraction digits and 1. A
      round up to 10 increases the exponent. The mantissa gets the minimum fraction digits, or
      the zeros that the minimum significant digits ask for. Then the adapter writes the symbol
      `EXP_SYMBOL`, `MINUS_SIGN` for a negative exponent, and the exponent in the digits of the
      locale. A subnormal number has its digits and the digit options. The cap of guard 1 does
      not apply.
   6. **More than 15 fraction digits below `2^53`.** In the standard notation with fraction
      digits, when the maximum fraction digits are above the cap of guard 1, the adapter writes
      each value below `2^53` without package:intl. It rounds the shortest digits to the maximum
      fraction digits. Digits that are all after the last fraction digit round to 0, or to 1 in
      the last place. The percent style moves the digits by two places. The fraction gets the
      minimum fraction digits. The pattern of the style gives the groups, as in guard 3.
6. **Cache.** `helpers.intl.dart` keeps the upstream cache. The key is not
   `locale + JSON.stringify(options)`. The key is the intl locale of `jsNumberFormatLocale` and
   each option entry as `key: value`. A String value is in quotes, as in JSON. Thus `false` and
   `'false'` give two keys. The key reads the entries of a resolver, as `JSON.stringify` does.
   The key only finds a formatter. It is not display text. Thus a JSON port is not necessary.
   `undefined`, `null` and the tags of one intl locale share a formatter. A later change of
   `Intl.defaultLocale` changes the key of an `undefined` locale. Thus the next label uses the new
   locale.
7. **Difference row.** The cache key line and the `new Intl.NumberFormat` line of
   `helpers.intl.dart` are `DIVERGES` hunks: `// DIVERGES(chartjs): adapt-intl-number-format,
   <reason>`.
   [differences.md](../differences.md) has the row `adapt-intl-number-format`, category `adapt`.
8. **Spec cases.** A ported spec case that asserts a V8 string that package:intl does not give
   skips with the reason `'diverges: adapt-intl-number-format'`. A case that package:intl passes
   runs.
9. **Tests.** `test/port/js/js_intl_test.dart` tests the option and locale mapping against V8
   strings. Its group `jsNumberFormat guards` tests the guards. It also compares the guard of
   numbers from `2^53` with package:intl at `2^53` for 18 locales. Its group
   `adapt-intl-number-format` pins a set of known differences. Where dart2js gives another string
   than the VM and dart2wasm, the test pins each string. Its group `V8 reference data` compares
   each case of `test/port/js/intl_reference.dart` with the port, on the VM, dart2js and
   dart2wasm. The data has five sections: numbers from `2^53`, NaN and the infinities,
   scientific notation, compact notation from `2^53` units, and the standard notation below
   `2^53` with more than 15 fraction digits. The compact sets turn off the grouping, because V8
   groups compact numbers and package:intl does not. `tool/reference/intl_reference.mjs` writes
   that file from the upstream `formatNumber` of `helpers.intl.ts`, in the value ranges of the
   guards. Its option sets are
   the options of the five call sites and some `ticks.format` objects of a user. It leaves out the
   known differences of decision 10 and of the consequences.
   `test/port/js/js_intl_default_locale_test.dart` tests `Intl.defaultLocale` on the VM only. It
   imports package:intl, and the web test legs do not compile such a file (tool 1).
   `test/port/helpers/helpers.intl_test.dart` tests the cache and the `formatNumber` calls behind
   the labels that the upstream specs assert. The expected V8 strings come only from the x64
   Node.js v24.12.0 of [Chart.js ADR 0010](0010-js-numeric-semantics.md).
10. **More than 15 fraction digits below `2^53`.** Guard 6 writes up to 20 fraction digits, as V8
    does. With significant digits, and in compact notation, the port keeps the cap of guard 1.
    The decision follows the order of `porting-flow.md` §1.1:
    - Upstream behavior. `formatters.numeric` gives fraction digits, not significant digits
      (`core.ticks.js:56-57`). It asks for more than 15 fraction digits for a tick spacing below
      `1e-15` (`core.ticks.js:54`). With two or more ticks, the labels use the standard notation
      when the largest tick is from `1e-4` to `1e15` (`core.ticks.js:40`). Data with rounding
      errors gives such ticks (Context). With the cap, two ticks get the same label. Thus guard 6
      writes the digits. Significant digits and compact notation come only from a `ticks.format`
      of a user. They need more than 15 fraction digits only for a value below about `1e-15`.
      That label is display text ([Chart.js ADR 0009](0009-no-display-only-js-exactness.md)).
    - Performance. Guard 6 measured 264 to 356 ns for each label on the VM (AOT), against 417 to
      467 ns for package:intl with the cap. The labels with at most 15 fraction digits cost the
      same time as before (346 to 371 ns).
    - Code. Guard 6 uses the digit code of guards 3 to 5.

## Alternatives considered

- **An ICU-exact formatter.** Rejected. The phase 2 stream wrote it. It had about 1,800 lines of
  Dart: a formatter with a table of 205 locale tags, and a port of four ICU 77.1 files. It needed
  a committed copy of the ICU files and 612 KB of generated reference data. ICU and CLDR are under
  the Unicode License v3. Thus it also needed a notice in the package `LICENSE`,
  `LICENSES/Unicode-3.0.txt`, two `REUSE.toml` tables and a `port_sources.yaml` entry. A change
  of the reference engine moves the ICU pin and regenerates the table and the data. The strings
  are display text, and this cost buys only exact equality with V8.
- **A hybrid: the symbols of package:intl with rounding of the port.** Rejected for all values.
  The port then owns the digit and rounding code. The symbols still change with the intl version.
  package:intl still has no minimum grouping digits. Thus the strings still differ from V8.
  Guards 3 to 6 use this form only where package:intl writes another value or throws.
- **Scientific notation with the mantissa of package:intl.** Rejected. The adapter can round the
  digits, give package:intl the mantissa, and write the exponent. This keeps the cap of 15
  fraction digits in scientific notation. A probe on the VM (AOT) measured 430 to 600 ns for each
  label, against 350 to 475 ns for Chart.js ADR 0008. Guard 5 measured 260 to 315 ns.
- **`toStringAsExponential()` for the shortest digits.** Rejected. It gives the digits of
  `jsNumberToString` on the VM, dart2js and dart2wasm. But a format with it was 6 to 22 % slower
  on the VM (AOT).

## Consequences

- Some labels differ from V8. A different label can change the width of an axis. Then the chart
  area and the positions of the elements change.
- All 146 distinct `formatNumber` calls behind the labels of `core.ticks.tests.js` and the linear,
  logarithmic and radial linear scale specs give the V8 string. This is true on the VM, dart2js and
  dart2wasm with intl 0.20.3. `helpers.intl_test.dart` tests them.
- All 6,170 cases of the reference data give the V8 string on the VM, dart2js and dart2wasm.
  Scientific notation gives the V8 string for 714 of 714 cases over the 119 locales of
  package:intl. The percent style gives it for 357 of 357 cases of NaN and the infinities.
- The strings change with the resolved intl version. The workspace resolves 0.20.3 (CLDR 48). An
  app with `flutter_localizations` resolves 0.20.2 (CLDR 46). The group
  `adapt-intl-number-format` fails when an intl upgrade changes a pinned string. Then the
  maintainers update the pins and the row.
- Below `2^53`, package:intl writes the binary value of a double. `999999999999999.9` gives
  `999,999,999,999,999.875`. V8 gives `999,999,999,999,999.9`.
- Compact notation, and the standard notation below `2^53` with significant digits, write at
  most 15 fraction digits. V8 writes up to 20.
- Significant digits and compact notation write `0` or too few digits for a value below about
  `1e-15`. V8 writes all the zeros.
- Compact notation does not group the digits. `1e18` gives `1000000T`. V8 gives `1,000,000T`.
- Compact notation writes the unit that package:intl selects. With many significant or fraction
  digits, package:intl on the VM and dart2wasm overflows a 64-bit integer when it selects the
  unit. Then it selects a smaller unit than V8, and the count of units has more digits. For
  example, `9.0072e27` with 21 minimum significant digits gives `9007200000000000000000000K`.
  V8 gives `9,007,200,000,000,000.00000T`. dart2js gives `9007200000000000.00000T`. The value is
  the same.
- From 17 significant digits, V8 writes a mantissa below 1 for a value whose shortest digits
  start with fifteen 9s. `9.999999999999998e-13` with 16 fraction digits gives
  `0.1000000000000000E-11` in V8. The port gives `9.9999999999999980E-13`.
- `notation: 'engineering'`, `compactDisplay: 'long'` and `currencyDisplay: 'code'` give other
  strings than V8. For example, `123456` in engineering notation gives `1.235E5`. V8 gives
  `123.456E3`.
- A label in scientific notation costs less time than with Chart.js ADR 0008. A number from
  `2^53` costs about half the time. A compact number from `2^53` units costs about one eighth of
  the time (VM, AOT: 141 to 145 ns, against 1,190 to 1,215 ns). A label with more than 15
  fraction digits costs about two thirds of the time (decision 10). The other labels cost the
  same time.
- An app sets the default locale of chart numbers with `Intl.defaultLocale`. A chart sets its own
  locale with the `locale` option.
