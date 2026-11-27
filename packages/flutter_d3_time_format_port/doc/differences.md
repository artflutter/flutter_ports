# d3-time-format port differences

This file lists the hunks of ported code that do not translate the upstream lines. Each hunk
carries the line comment `// DIVERGES(d3-time-format): <ID>, <reason>`. `check:headers` pairs each
marker with a row of this file. A port-only file is not a row.

The ID starts with its category: `adapt`, `platform`, `js-semantics`, `harness` or `not-followed`,
as in the [D3 port](../../flutter_d3_port/doc/differences.md). The column "Upstream
file@version:lines" names the pin at which the porter last checked the row. Each bump checks every
row.

The port uses no JS runtime ([D3 ADR 0007](../../flutter_d3_port/doc/adr/0007-native-dart-forms.md)).
The rows `adapt-time-format-*` record the native forms of
[D3 ADR 0025](../../flutter_d3_port/doc/adr/0025-time-format-native-forms.md).

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
| <a id="adapt-time-format-typed-api"></a>`adapt-time-format-typed-api` | `lib/src/locale.dart`, `lib/src/defaultLocale.dart`, `lib/src/isoFormat.dart`, `lib/src/isoParse.dart`, `lib/src/index.dart`, `test/defaultLocale_test.dart`, `test/format_test.dart`, `test/parse_test.dart`, `test/utcParse_test.dart` | d3-time-format `src/*.js`@v4.1.0, `test/*-test.js`@v4.1.0 | adapt | Native statically typed Dart APIs with zero `dynamic`, zero `Object?` escape hatches where generics apply, and zero JS runtime ([D3 ADR 0025](../../flutter_d3_port/doc/adr/0025-time-format-native-forms.md)): immutable `const TimeLocaleDefinition`, typed `TimeLocale`, callable `TimeFormat` (`String call(DateTime)`) and `TimeParse` (`DateTime? call(String)`), `defaultTimeLocale` getter, top-level delegating functions (`timeFormat`, `timeParse`, `utcFormat`, `utcParse`), and `isoFormat`/`isoParse` over native Dart `DateTime` without JS input coercion or `Object.prototype` pollution. | — | `test/*_test.dart`, `test/port/locales_test.dart`, `test/port/reference_test.dart` | Check signatures and contracts when the pin changes. |
| <a id="adapt-time-format-fast-forms"></a>`adapt-time-format-fast-forms` | `lib/src/locale.dart`, `lib/src/isoFormat.dart`, `lib/src/isoParse.dart` | d3-time-format `src/locale.js`, `src/isoFormat.js`, `src/isoParse.js`@v4.1.0 | adapt | Faster native Dart forms with identical outputs ([performance.md](performance.md)): precompiled flat directive instruction lists expanding recursive `%c`/`%x`/`%X` specifiers once at construction time; direct UTF-16/Latin-1 code-unit formatting into reusable scratch buffers with inline `%j`/`%U`/`%W`/`%V`/`%g`/`%G` calendar math; direct code-unit numeric and `%Z` parsers eliminating per-directive `RegExp` and substring allocations; pre-indexed case-insensitive locale name lookup tables preserving upstream alternation order; and direct code-unit `isoFormat`/`isoParse`. | — | `test/port/faster_forms_test.dart`, `test/port/reference_test.dart` | Compare upstream algorithms when the pin changes. |
| <a id="platform-time-format-tz-tests"></a>`platform-time-format-tz-tests` | `test/format_test.dart`, `test/parse_test.dart`, `test/utcParse_test.dart` | d3-time-format `test/format-test.js`, `test/parse-test.js`, `test/utcParse-test.js`@v4.1.0 | platform | Upstream tests run with `TZ=America/Los_Angeles`. In Dart tests executed under arbitrary host timezones (macOS, Linux, Windows, Chrome JS/Wasm), LA-specific hardcoded `%Z` and offset-to-local assertions run verbatim when the host timezone matches `America/Los_Angeles` and assert equivalent host-timezone/UTC-instant invariants otherwise; `test/port/tz_test.dart` also runs a POSIX VM subprocess under real `TZ=America/Los_Angeles`. | — | `test/format_test.dart`, `test/parse_test.dart`, `test/utcParse_test.dart`, `test/port/tz_test.dart` | Re-check TZ assumptions when upstream tests change. |
