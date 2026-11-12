# Chart.js ADR 0119: The number format is package:intl as it is

- Status: accepted (2026-11-12): its code and the tests of section Tests pass.
- Date: 2026-11-12
- Supersedes: [Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) (the locale and the options as JS
  values, the guards against package:intl defects, the cache key of the option entries and its tests against V8
  strings).
- Related: Chart.js ADR [0054](0054-typed-internal-model.md) (the typed option model and its typed atoms),
  [0034](0034-no-display-only-js-exactness.md) (no display-only JS exactness) and
  [0116](0116-text-style-fonts.md) (a font is a Flutter `TextStyle`). The row `adapt-intl-number-format`.

## Context

Chart.js formats numbers with `new Intl.NumberFormat(locale, options)` (helpers.intl.ts:4-17). The chart option
`locale` is a BCP 47 tag (index.d.ts:1702). The tick option `format` of the linear, logarithmic and radial scales is an
object of `Intl.NumberFormatOptions` (index.d.ts:3380, 3419, 3539). `formatters.numeric` puts it over the options that
it computes from the tick spacing: `{notation, minimumFractionDigits, maximumFractionDigits}` (core.ticks.js:56-59).
`getLabelForValue` of the linear and logarithmic scales gives it as it is (scale.linearbase.js:311,
scale.logarithmic.js:195).

Before this decision, `lib/src/js/js_intl.dart` (763 lines) took both as JS values. It checked the language tags as
text, read the options from a Map with the ranges of ECMA-402, and corrected the output of package:intl where it is
wrong: the digits of numbers above 2^63, the scientific notation of `1e15` (`10E14`), more than 15 fraction digits
on the web, and the affixes of NaN and the infinities. The maintainer decided that the bugs of package:intl are not
the problem of the port, and that the core takes the native types.

## Decision

1. The chart option `locale` holds a Flutter `Locale`. The tick option `format` holds a `NumberFormat` of package:intl.
   Both are typed atoms of the option schema (`locale` and `numberFormat`). A language tag as text, or an object of
   format options, stops a debug build (`localeOf` and `numberFormatOf` of `helpers.intl.dart`). A release build takes
   Dart `null`.
2. `formatNumber(number, locale, [format])` formats with `format` as it is, else with the decimal pattern of `locale`.
   `formatters.numeric` formats a tick with the `NumberFormat` of `ticks.format` as it is, else with the decimal or
   the scientific pattern of the chart locale and the fraction digits of the tick spacing. Dart cannot copy a
   `NumberFormat`, so the port does not put the computed digits under the format of the app.
3. A `Locale` without intl data, and no locale, give the current locale of package:intl (`Intl.defaultLocale`,
   `'en_US'` by default). The resolved locale is in the cache key, so a change of `Intl.defaultLocale` reaches the
   next label.
4. The port does not correct package:intl. A label in the ranges of its defects shows the text of package:intl.
5. Gone: `lib/src/js/js_intl.dart`, its tests against 6,170 V8 strings and their generator, the String cache key of
   the option entries, and the row `adapt-numeric-tick-format-key`.
6. The data-only update accepts a `Locale` in the chart options, and the native option plans count a `Locale` and a
   `NumberFormat` as plain values.

## Consequences

- An app gives `locale: Locale('de', 'DE')` and `ticks.format: NumberFormat.percentPattern()`. A format with digits
  that depend on the tick spacing is the job of the app: a `NumberFormat` keeps its own digits.
- The labels of the common cases do not change: the reference data of the scales have the same labels. Labels in the
  ranges of the package:intl defects can differ from V8. The open issue
  [dart-lang/i18n#440](https://github.com/dart-lang/i18n/issues/440) is one of them.
- The reference generators write a `Locale` and a `NumberFormat` into the Dart data. A data file with a
  `NumberFormat` has a `final` list, with each part without a `NumberFormat` as `const`.

## Tests

- `test/port/helpers/helpers.intl_test.dart`: the V8 strings of the spec labels, the current locale, a locale without
  intl data, `Intl.defaultLocale`, a `NumberFormat` as it is, both notations, and the debug stops.
- `test/port/core/core.ticks_test.dart`: the locale of the chart and a `NumberFormat` in `formatters.numeric`.
- The specs with a locale (`core.ticks`, `scale.linear`, `scale.logarithmic`, `scale.time`, `core.controller`) and the
  scale reference tests (the cases `locale`, `format` and `percent format`).
- `test/port/options/schema_test.dart`: the census rows of the upstream forms are reviewed foreign values and extras.
