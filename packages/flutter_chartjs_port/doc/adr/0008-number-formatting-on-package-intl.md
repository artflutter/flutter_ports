# Chart.js ADR 0008: Number formatting on package:intl

- Status: accepted (2026-10-18)
- Date: 2026-10-18
- Superseded by: [Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) (2026-10-20)
- Related: [Chart.js ADR 0010](0010-js-numeric-semantics.md)

## Context

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
engine is V8 13.6 with ICU 77.1 and CLDR 47 in Node.js v24.12.0 on x64. A probe formatted the V8
reference cases of the phase 2 stream with package:intl 0.20.2. It used the closest option
mapping:

| Case group | Cases | Different strings |
|---|---:|---:|
| tick labels (the calls of the upstream `core.ticks.js`) | 4,479 | 212 |
| edge values (digit, notation and grouping options) | 4,971 | 2,049 |
| locales | 4,305 | 502 |

Examples of the differences:
- `maximumSignificantDigits: 3` on `1.994e-7` gives `0.0000002` in the probe mapping. V8 gives
  `0.000000199`. The adapter of this ADR sets only the given bounds and gives `0.000000199`.
- `0.000075` with five fraction digits gives `0.00007`. V8 gives `0.00008`. ICU rounds the
  shortest decimal string of a double. package:intl rounds the binary value.
- Scientific notation of `1e15` with no fraction digits gives `10E14`. V8 gives `1E15`.
- `1e20` with no options gives `92,233,720,368,547,758,070` on the VM. A 64-bit integer
  overflows.
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
   - `notation`: `standard`, `scientific` and `compact` (`NumberFormat.compact`). The percent
     style ignores `notation`. The currency style ignores `scientific` and `compact`.
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
   `NumberFormat` in a `JsNumberFormat` with three guards. Thus `format` does not throw for a
   double:
   - The adapter gives package:intl at most 15 fraction digits on every platform. The percent
     style gets two digits less. package:intl multiplies by `10^digits` in an `int`. On dart2js,
     the low digits go above `2^53` after 15 digits. One cap for all platforms gives the same
     fraction digits on all platforms. With significant digits, package:intl takes the fraction
     digits from the value. Thus the cap applies to them too. A value below about `1e-15` loses its
     digits. For example, `1.5e-100` with three significant digits gives `0`.
   - Compact notation writes NaN and the infinities as the decimal style does. package:intl
     throws for them.
   - Scientific notation writes a subnormal number with `Number.prototype.toString`
     and an upper-case `E`. package:intl divides by `pow(10.0, exponent)`, and that value is
     subnormal or 0 there. The guard ignores the digit options.
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
   strings. Its group `jsNumberFormat guards` tests the guards. Its group
   `adapt-intl-number-format` pins a set of known differences. Where dart2js gives another string
   than the VM and dart2wasm, the test pins each string.
   `test/port/js/js_intl_default_locale_test.dart` tests `Intl.defaultLocale` on the VM only.
   It imports package:intl, and the web test legs do not compile such a file (tool 1).
   `test/port/helpers/helpers.intl_test.dart` tests the cache and the `formatNumber` calls behind
   the labels that the upstream specs assert. The expected V8 strings come only from the x64
   Node.js v24.12.0 of [Chart.js ADR 0010](0010-js-numeric-semantics.md).

## Alternatives considered

- **An ICU-exact formatter.** Rejected. The phase 2 stream wrote it. It had about 1,800 lines of
  Dart: a formatter with a table of 205 locale tags, and a port of four ICU 77.1 files. It needed
  a committed copy of the ICU files and 612 KB of generated reference data. ICU and CLDR are under
  the Unicode License v3. Thus it also needed a notice in the package `LICENSE`,
  `LICENSES/Unicode-3.0.txt`, two `REUSE.toml` tables and a `port_sources.yaml` entry. A change
  of the reference engine moves the ICU pin and regenerates the table and the data. The strings
  are display text, and this cost buys only exact equality with V8.
- **A hybrid: the symbols of package:intl with rounding of the port.** Rejected. The port then
  owns the digit and rounding code. The symbols still change with the intl version. package:intl
  still has no minimum grouping digits. Thus the strings still differ from V8.

## Consequences

- Some labels differ from V8. A different label can change the width of an axis. Then the chart
  area and the positions of the elements change.
- All 146 distinct `formatNumber` calls behind the labels of `core.ticks.tests.js` and the linear,
  logarithmic and radial linear scale specs give the V8 string. This is true on the VM, dart2js and
  dart2wasm with intl 0.20.3. `helpers.intl_test.dart` tests them.
- The strings change with the resolved intl version. The workspace resolves 0.20.3 (CLDR 48). An
  app with `flutter_localizations` resolves 0.20.2 (CLDR 46). The group
  `adapt-intl-number-format` fails when an intl upgrade changes a pinned string. Then the
  maintainers update the pins and the row.
- The VM and dart2wasm give other strings than dart2js above `2^63`. There, the VM and dart2wasm
  overflow a 64-bit integer. For example, `1e20` gives `92,233,720,368,547,758,070`. dart2js
  gives the V8 string there.
- All platforms write at most 15 fraction digits. V8 writes up to 20. `formatters.numeric` asks
  for more than 15 fraction digits only for a tick spacing below `1e-15`.
- Significant digits and compact notation write `0` or too few digits for a value below about
  `1e-15`. V8 writes all the zeros.
- Scientific notation of a subnormal number ignores the digit options and the locale. For
  example, `1e-320` with two fraction digits gives `1E-320`. V8 gives `1.00E-320`.
- `notation: 'engineering'`, `compactDisplay: 'long'` and `currencyDisplay: 'code'` give other
  strings than V8. For example, `123456` in engineering notation gives `1.235E5`. V8 gives
  `123.456E3`.
- The ICU port, the ICU copies, the reference generator, the reference data and the Unicode-3.0
  license text leave the repository.
- An app sets the default locale of chart numbers with `Intl.defaultLocale`. A chart sets its own
  locale with the `locale` option.
