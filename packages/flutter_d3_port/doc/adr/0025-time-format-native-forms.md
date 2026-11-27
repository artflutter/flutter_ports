# D3 ADR 0025: Native forms of d3-time-format

- Status: accepted (2026-11-27): its code and the tests of section Tests pass.
- Date: 2026-11-27
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [D3 ADR 0016](0016-format-native-forms.md), [D3 ADR 0021](0021-time-native-forms.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

`d3-time-format` 4.1.0 implements locale-aware `strftime` / `strptime` date formatting and parsing
for local and UTC calendars, built on top of `d3-time`:

- Locale factory & default locale: `timeFormatLocale(definition)` returning `{format, parse,
  utcFormat, utcParse}`, `timeFormatDefaultLocale(definition)` updating the default locale used by
  top-level `timeFormat`, `timeParse`, `utcFormat`, and `utcParse`.
- ISO 8601 helpers: `isoFormat(date)` and `isoParse(string)` (with `isoSpecifier`
  `"%Y-%m-%dT%H:%M:%S.%LZ"`).
- All 32 `strftime`/`strptime` directives: `%a`, `%A`, `%b`, `%B`, `%c`, `%d`, `%e`, `%f`, `%g`,
  `%G`, `%H`, `%I`, `%j`, `%L`, `%m`, `%M`, `%p`, `%q`, `%Q`, `%s`, `%S`, `%u`, `%U`, `%V`, `%w`,
  `%W`, `%x`, `%X`, `%y`, `%Y`, `%Z`, and `%%`, plus the three pad modifiers `-` (none), `_`
  (space), and `0` (zero).
- 34 built-in locale JSON definitions in `locale/*.json` (`ar-EG` through `zh-TW`).

Upstream JavaScript relies on untyped locale objects, JS coercion of format inputs (`new Date(+date)`)
and parse inputs (`string += ""`, `specifier += ""`), dynamic `toString` property attachment on
closures, runtime string re-scanning on every format/parse call, and per-directive `RegExp`
execution on sliced substrings.

Following [D3 ADR 0007](0007-native-dart-forms.md) (zero JS runtime),
[D3 ADR 0008](0008-module-packages.md) (one package per D3 module),
[D3 ADR 0009](0009-native-spec-harness.md) (native `package:test` specs and Node.js reference
tests), [D3 ADR 0010](0010-native-values-and-factories.md) (typed native parameters),
[D3 ADR 0016](0016-format-native-forms.md) (const locale definitions matching `d3-format`), and
[D3 ADR 0021](0021-time-native-forms.md) (immutable native `DateTime`), `d3-time-format` 4.1.0 is
ported as a standalone pure-Dart package `flutter_d3_time_format_port` depending only on
`flutter_d3_time_port: ^0.1.0`, with **zero `dynamic`, zero `Object?` escape hatches where generics
apply, zero JS runtime, and zero Flutter dependency**.

## Decision

1. **Pure Dart package (`d3_time_format.dart` + `flutter_d3_time_format_port.dart`).**
   `package:flutter_d3_time_format_port/d3_time_format.dart` exports every pure library in
   `lib/src/` without `show`/`hide` combinators (ADR 0011), and
   `package:flutter_d3_time_format_port/flutter_d3_time_format_port.dart` re-exports
   `d3_time_format.dart`. All 5 upstream `src/*.js` files map 1:1 to `lib/src/*.dart`.

2. **Immutable `const TimeLocaleDefinition` and `TimeLocale`.**
   - `TimeLocaleDefinition` is an immutable `const` data class with statically typed fields:
     - `final String dateTime`
     - `final String date`
     - `final String time`
     - `final List<String> periods` (2 entries: AM, PM)
     - `final List<String> days` (7 entries, Sunday through Saturday)
     - `final List<String> shortDays` (7 entries, Sunday through Saturday)
     - `final List<String> months` (12 entries, January through December)
     - `final List<String> shortMonths` (12 entries, January through December)
     plus `const TimeLocaleDefinition(...)` and `TimeLocaleDefinition.fromJson(Map<String, Object?>)`.
   - `TimeLocale` (constructed via `timeFormatLocale(TimeLocaleDefinition definition)`) exposes
     statically typed factories:
     - `TimeFormat format(String specifier)`
     - `TimeParse parse(String specifier)`
     - `TimeFormat utcFormat(String specifier)`
     - `TimeParse utcParse(String specifier)`
   - `timeFormatDefaultLocale(TimeLocaleDefinition definition)` updates the module-level default
     locale (`defaultTimeLocale`) used by top-level `timeFormat`, `timeParse`, `utcFormat`, and
     `utcParse`, and returns the new `TimeLocale`. Naming the getter `defaultTimeLocale` avoids
     export collision with `defaultLocale` from `flutter_d3_format_port` in the `flutter_d3_port`
     bundle.

3. **Callable `TimeFormat` and `TimeParse` classes.**
   - `final class TimeFormat` implements:
     - `final String specifier`
     - `String call(DateTime date)` (implicitly tearing off to `String Function(DateTime)` for
       downstream modules such as `d3-scale` and `d3-axis`)
     - `@override String toString() => specifier`
   - `final class TimeParse` implements:
     - `final String specifier`
     - `DateTime? call(String input)` (implicitly tearing off to `DateTime? Function(String)`)
     - `@override String toString() => specifier`
   - Local formatters normalize UTC inputs via `date.isUtc ? date.toLocal() : date`; UTC formatters
     normalize local inputs via `date.isUtc ? date : date.toUtc()`.
   - `timeParse` returns local `DateTime` values (`isUtc == false`), converting `%Z`-offset
     timestamps to the equivalent local instant; `utcParse` returns UTC `DateTime` values
     (`isUtc == true`). Both preserve full epoch-millisecond parity with upstream `d3-time-format`.

4. **All 34 upstream locale definitions as `const` Dart objects.**
   `lib/src/locales.dart` ships all 34 upstream `locale/*.json` definitions as tree-shakeable
   `const TimeLocaleDefinition` constants (`timeLocaleArEG`, `timeLocaleArSY`, ...,
   `timeLocaleEnUS`, ..., `timeLocaleZhTW` — prefixed with `timeLocale` to avoid export collisions
   with `locale*` from `flutter_d3_format_port` in `flutter_d3_port`) plus
   `const Map<String, TimeLocaleDefinition> timeFormatLocales` keyed by exact BCP-47 tag
   (`'ar-EG'`, `'en-US'`, `'fr-FR'`, `'zh-TW'`, etc.), requiring zero filesystem I/O or JSON parsing
   at runtime.

5. **Native `isoFormat` and `isoParse`.**
   - `String isoFormat(DateTime date)` formats any `DateTime` as an ISO 8601 UTC string matching
     JavaScript `Date.prototype.toISOString()` (`YYYY-MM-DDTHH:mm:ss.SSSZ` for years `0..9999`,
     6-digit signed expanded years `±YYYYYY-...` outside that range, always 3 millisecond digits
     even when `date.microsecond != 0`).
   - `DateTime? isoParse(String input)` parses ISO 8601 date/time strings with a fast direct
     code-unit path for canonical `YYYY-MM-DDTHH:mm:ss(.sss)?(Z|±HH:MM)` and UTC `YYYY-MM-DD`
     strings, falling back to `DateTime.tryParse` and returning `null` on invalid inputs.

6. **Dart `DateTime` parity details.**
   - Negative years and years `>= 10000` use Dart `.remainder(100)` / `.remainder(10000)` rather
     than Euclidean `%`, matching JavaScript `%y` (`-2 -> "-02"`) and `%Y` (`-2 -> "-0002"`,
     `10002 -> "0002"`).
   - `%s` floors negative epoch milliseconds toward `−∞` (`Math.floor(ms / 1000)`), matching
     upstream for pre-1970 timestamps.
   - `%Z` converts Dart's `timeZoneOffset.inMinutes` (positive east of UTC) to the signed
     `±HHMM` format matching JavaScript's opposite-polarity `getTimezoneOffset()`.
   - Locale name matching (`%a`, `%A`, `%b`, `%B`, `%p`) preserves upstream's exact left-to-right
     alternation precedence (for prefix-overlapping names such as Czech `červen`/`červenec` and
     Turkish `Pazar`/`Pazartesi`) and last-index map resolution (for French-Canadian empty
     `periods: ["", ""]`).

7. **Hot-path optimizations across AOT, Wasm, and dart2js.**
   - Precompiled flat directive instruction lists (`_FormatOp` / `_ParseOp`) in `TimeFormat` and
     `TimeParse` expand recursive `%c`/`%x`/`%X` specifiers once at construction time, eliminating
     runtime specifier re-scanning on every call.
   - Direct UTF-16 / Latin-1 code-unit formatting into reusable scratch buffers (`Uint8List` /
     `Uint16List`) and fast inline calendar arithmetic for `%j`, `%U`, `%W`, `%V`, `%g`, `%G` avoid
     intermediate string lists and `DateTime` allocations.
   - Direct code-unit numeric and timezone parsers eliminate per-directive `RegExp` execution and
     `String.substring` slicing on `%Y`, `%y`, `%m`, `%d`, `%e`, `%H`, `%I`, `%M`, `%S`, `%L`, `%f`,
     `%j`, `%q`, `%Q`, `%s`, `%u`, `%U`, `%V`, `%w`, `%W`, and `%Z`.
   - Pre-indexed case-insensitive lookup tables per `TimeLocale` bucket locale names by folded first
     character while preserving upstream alternation order, matching month, weekday, and period
     names with zero `RegExp` execution or substring allocation.
   - Fast direct `isoFormat` and `isoParse` avoid `DateTime.toIso8601String` and `DateTime.tryParse`
     overhead on canonical ISO 8601 timestamps.

## Rejected

- Taking `Object?` in `TimeFormat.call` (to mimic JS `new Date(+date)` coercion) or `TimeParse.call`
  (to mimic JS `toString()` coercion): forfeits static type safety and adds runtime type dispatch
  on every call.
- Naming locale constants `localeEnUS` or default getter `defaultLocale`: collides with
  `flutter_d3_format_port` when both packages are re-exported by `flutter_d3_port`.
- Shipping `locale/*.json` as Flutter assets or loading them with `dart:io`: breaks pure-Dart and
  browser builds and prevents tree-shaking unused locales.
- Hardcoding `America/Los_Angeles` test assertions without host timezone detection: breaks test
  suites on UTC CI runners and non-Pacific developer machines.

## Consequences

- Upstream spec cases testing JS input coercion (`f(+local(...))`, `p({toString: ...})`,
  `timeParse({toString: ...})`, `utcParse({toString: ...})`) and JS `Object.prototype` pollution
  adapt to native Dart types or skip with `diverges: adapt-time-format-typed-api` (recorded in
  `packages/flutter_d3_time_format_port/doc/differences.md`).
- All 8 upstream test files (146 cases) pass cleanly across macOS, Linux, Windows, Chrome JS, and
  Chrome Wasm, alongside real POSIX `TZ=America/Los_Angeles` verification, Node.js reference parity
  tests, and faster-form equivalence tests.
- Downstream D3 modules (`d3-scale` time scales, `d3-axis`) can depend directly on
  `flutter_d3_time_format_port` with full static typing and zero JS runtime overhead.

## Tests

- `packages/flutter_d3_time_format_port/test/*_test.dart` (all 8 upstream spec files, 146 cases)
- `packages/flutter_d3_time_format_port/test/port/locales_test.dart`
- `packages/flutter_d3_time_format_port/test/port/reference_test.dart`
- `packages/flutter_d3_time_format_port/test/port/faster_forms_test.dart`
- `packages/flutter_d3_time_format_port/test/port/tz_test.dart`
- `packages/flutter_d3_time_format_port/test/upstream_test.dart`
- `packages/flutter_d3_port/test/port/d3/index_test.dart`
