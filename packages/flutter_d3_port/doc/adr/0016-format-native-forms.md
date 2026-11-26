# D3 ADR 0016: Native forms of d3-format

- Status: accepted (2026-11-26): its code and the tests of section Tests pass.
- Date: 2026-11-26
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

`d3-format` 3.1.2 formats numbers for human consumption using Python-style format specifiers
(`[[fill]align][sign][symbol][0][width][,][.precision][~][type]`), SI prefixes (`y`..`Y`),
configurable locale definitions (decimal point, thousands separator, grouping pattern, currency
affixes, custom numerals, percent sign, minus sign, and `NaN` string), and precision helpers
(`precisionFixed`, `precisionPrefix`, `precisionRound`), alongside 59 built-in locale JSON files in
`locale/`.

Following [D3 ADR 0007](0007-native-dart-forms.md) (zero JS runtime, native Dart number methods
with local JS-exact fixes where needed), [D3 ADR 0008](0008-module-packages.md) (one package per D3
module), [D3 ADR 0009](0009-native-spec-harness.md) (native `package:test` specs and Node.js
reference tests), and [D3 ADR 0010](0010-native-values-and-factories.md) (typed native parameters),
`d3-format` 3.1.2 is ported as its own standalone package `flutter_d3_format_port` with zero
JavaScript runtime and zero Flutter dependency in its pure Dart library.

## Decision

1. **Pure Dart package (`d3_format.dart` + `flutter_d3_format_port.dart`).**
   `d3-format` transforms numbers and strings without any UI or canvas dependency.
   `package:flutter_d3_format_port/d3_format.dart` exports every pure file in `lib/src/` without
   `show`/`hide` combinators (ADR 0011), and
   `package:flutter_d3_format_port/flutter_d3_format_port.dart` re-exports `d3_format.dart`. The
   package compiles for the Dart VM, AOT, dart2js, and dart2wasm with zero runtime dependencies.
2. **Typed `FormatSpecifier` and single-pass parser (`formatSpecifier`).**
   `FormatSpecifier` holds typed mutable fields matching upstream:
   `String fill` (`' '`), `String align` (`'>'`), `String sign` (`'-'`), `String symbol` (`''`),
   `bool zero` (`false`), `int? width` (`null`), `bool comma` (`false`), `int? precision` (`null`),
   `bool trim` (`false`), and `String type` (`''`). `formatSpecifier(String specifier)` parses the
   specifier string and throws `FormatException('invalid format: $specifier')` on invalid input.
   `FormatSpecifier.toString()` returns the normalized specifier string, clamping `width` to
   `>= 1` and `precision` to `>= 0`.
3. **Callable `NumberFormat` class with `toString()` and typed inputs.**
   `FormatLocale.format` and `FormatLocale.formatPrefix` return a callable `NumberFormat` instance
   with:
   - `String call(num value)` for strongly typed numeric formatting (implicitly tearing off to
     `String Function(num)` and `String Function(double)` for downstream modules such as `d3-scale`
     and `d3-axis`).
   - `String formatChar(String value)` for formatting non-numeric strings with the `'c'` specifier
     (upstream `format("c")("☃")`), avoiding an `Object?` union on the numeric hot path.
   - `final FormatSpecifier specifier` and `toString()` returning the normalized specifier string,
     matching upstream `format("d").toString() == " >-d"`.
   - `FormatLocale.formatFromSpecifier(FormatSpecifier)` and
     `FormatLocale.formatPrefixFromSpecifier(FormatSpecifier, num)` (plus top-level
     `formatFromSpecifier` and `formatPrefixFromSpecifier`) accept pre-parsed `FormatSpecifier`
     objects directly without re-serializing and re-parsing strings.
   - Optional `prefix` and `suffix` named parameters on `format` / `formatFromSpecifier` mirror
     upstream's `options.prefix` / `options.suffix`.
4. **Immutable `const FormatLocaleDefinition` and `FormatLocale`.**
   `FormatLocaleDefinition` is a `const` data class with typed fields:
   `String decimal` (`'.'`), `String? thousands`, `List<int>? grouping`,
   `(String, String)? currency`, `List<String>? numerals`, `String percent` (`'%'`),
   `String minus` (`'\u2212'`), and `String nan` (`'NaN'`), plus a
   `FormatLocaleDefinition.fromJson(Map<String, Object?>)` factory. `formatLocale(definition)`
   constructs a `FormatLocale`; `formatDefaultLocale(definition)` updates the module-level default
   locale used by top-level `format` and `formatPrefix` and returns it (also readable via
   `defaultLocale`).
5. **All 59 upstream locale definitions as `const` Dart objects.**
   `lib/src/locales.dart` ships all 59 upstream `locale/*.json` definitions as tree-shakeable
   `const FormatLocaleDefinition` constants (`localeEnUS`, `localeFrFR`, `localeDeDE`,
   `localeEnIN`, `localeAr001`, ..., `localeZhCN`) plus a `const Map<String, FormatLocaleDefinition>`
   `formatLocales` keyed by exact BCP-47 tag (`'en-US'`, `'fr-FR'`, `'ar-001'`, etc.), so apps and
   browser builds need zero filesystem I/O or JSON parsing at runtime.
6. **Nullable `int?` return type for precision helpers and `exponent`.**
   `precisionFixed(num step)`, `precisionPrefix(num step, num value)`,
   `precisionRound(num step, num max)`, and `exponent(num x)` return `int?`: a non-negative `int`
   (or signed `int` exponent) for valid finite non-zero inputs, and `null` where upstream returns
   `NaN` (`0`, `NaN`, `±Infinity`, or `|max| == |step|` in `precisionRound`). Returning `int?`
   plugs directly into `FormatSpecifier(precision: ...)` and string interpolation
   `'.${p}f'` across VM, dart2js, and dart2wasm (where a `double` would format as `'2.0'`).
7. **JS-exact number formatting with zero JS runtime.**
   - `formatDecimal` uses fast `int` formatting for `|x| < 2^53`, JS half-toward-`+∞` rounding, and
     shortest round-trip exponential expansion for `|x| >= 2^52` (matching JS
     `x.toLocaleString("en").replace(/,/g, "")` for `|x| >= 1e21` without `package:intl` or
     exact-binary `BigInt` drift).
   - Binary/octal/hex types (`b`, `o`, `x`, `X`) use `int.toRadixString` for `|x| < 2^53` and
     `BigInt.from(rounded).toRadixString` for larger finite integers, and `'Infinity'` for infinite
     inputs.
   - `formatDecimalParts(double x, [int? p])` treats `p == null || p <= 0` as unrounded
     `toStringAsExponential()`, preserving upstream's `Number.MIN_VALUE` yocto behavior.
   - `formatRounded` formats `0.0` as `'0'` (not `'0.0'`).
   - Negative-zero suppression checks formatted digits directly without re-parsing floats,
     preserving `-0xeee -> "−eee"` while suppressing `−0.00` unless `sign == '+'`.
8. **Hot-path optimizations without regex allocations.**
   `formatSpecifier` parses specifiers in a single code-unit pass; `NumberFormat` precomputes
   clamped precision, affixes, grouping/numeral dispatch, and fast unpadded/ungrouped paths at
   creation time; `formatGroup`, `formatTrim`, `formatNumerals`, and `formatPrefixAuto` operate
   directly on UTF-16 code units and `StringBuffer` with zero per-call `RegExp` or list
   allocations.

## Rejected

- Taking `Object?` in `NumberFormat.call`: forfeits static type safety for the 99.9% numeric path
  and adds runtime type dispatch on every call, solely to accommodate `'c'` strings and JS
  `undefined` coercion.
- Returning `double` from `precisionFixed` / `precisionPrefix` / `precisionRound`: breaks string
  interpolation (`'.${2.0}f'`) on VM and Wasm and requires `.toInt()` casts before assigning to
  `FormatSpecifier.precision`.
- Shipping `locale/*.json` as Flutter assets or loading them with `dart:io`: breaks pure Dart /
  browser usage and prevents tree-shaking unused locales.
- Using `package:intl` for `>= 1e21` integer strings: pulls an external dependency for a single
  shortest-round-trip zero-padding step.

## Consequences

- Upstream spec cases testing JS input coercion in `new FormatSpecifier({fill: 1, ...})`, JS
  `undefined` coerced to `NaN`, `format("c")("☃")` called with a string, or `NaN` returns from
  `precision*` adapt to native Dart types (`FormatSpecifier` typed fields, `double.nan`,
  `formatChar`, `isNull`) or skip with `diverges: adapt-format-typed-api` (recorded in
  `packages/flutter_d3_format_port/doc/differences.md`).
- Downstream D3 modules (`d3-scale`, `d3-axis`, `d3-time-format`) can depend directly on
  `flutter_d3_format_port` across VM, Flutter, dart2js, and dart2wasm.

## Tests

- `packages/flutter_d3_format_port/test/*_test.dart` (all 24 upstream spec files, 168 cases)
- `packages/flutter_d3_format_port/test/port/reference_test.dart`
- `packages/flutter_d3_format_port/test/port/faster_forms_test.dart`
- `packages/flutter_d3_format_port/test/port/locales_test.dart`
- `packages/flutter_d3_format_port/test/upstream_test.dart`
- `packages/flutter_d3_port/test/port/d3/index_test.dart`
