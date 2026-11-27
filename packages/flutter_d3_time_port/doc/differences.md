# d3-time port differences

This file lists the hunks of ported code that do not translate the upstream lines. Each hunk
carries the line comment `// DIVERGES(d3-time): <ID>, <reason>`. `check:headers` pairs each
marker with a row of this file. A port-only file is not a row.

The ID starts with its category: `adapt`, `platform`, `js-semantics`, `harness` or `not-followed`,
as in the [D3 port](../../flutter_d3_port/doc/differences.md). The column "Upstream
file@version:lines" names the pin at which the porter last checked the row. Each bump checks every
row.

The port uses no JS runtime ([D3 ADR 0007](../../flutter_d3_port/doc/adr/0007-native-dart-forms.md)).
The rows `adapt-time-*` record the native forms of
[D3 ADR 0021](../../flutter_d3_port/doc/adr/0021-time-native-forms.md).

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
| <a id="adapt-time-typed-api"></a>`adapt-time-typed-api` | `lib/src/*.dart` | d3-time `src/*.js`@v3.1.0 | adapt | Native statically typed Dart APIs with zero `dynamic`, zero `Object?` escape hatches where generics apply, and zero JS runtime ([D3 ADR 0021](../../flutter_d3_port/doc/adr/0021-time-native-forms.md)): immutable Dart `DateTime` (local and UTC via `isUtc`), typed `TimeInterval` / `CountableTimeInterval` classes with `int` `step` parameters, `timeInterval` and `countableTimeInterval` factories, `timeUnixDay`/`timeUnixDays` aliases alongside `unixDay`/`unixDays`, and split `timeTicks`/`timeTicksWith` and `utcTicks`/`utcTicksWith` replacing untyped `count`-or-interval union parameters. | — | `test/*_test.dart`, `test/port/reference_test.dart` | Check signatures and contracts when the pin changes. |
| <a id="adapt-time-fast-forms"></a>`adapt-time-fast-forms` | `lib/src/interval.dart`, `lib/src/millisecond.dart`, `lib/src/second.dart`, `lib/src/minute.dart`, `lib/src/hour.dart`, `lib/src/day.dart`, `lib/src/week.dart`, `lib/src/month.dart`, `lib/src/year.dart`, `lib/src/ticks.dart` | d3-time `src/*.js`@v3.1.0 | adapt | Faster native Dart forms with identical calendar and DST outputs ([performance.md](performance.md)): direct O(1) epoch-millisecond Euclidean arithmetic for fixed-length UTC and timezone-independent intervals (`millisecond`, `second`, `utcMinute`, `utcHour`, `utcDay`, `unixDay`, `utcSunday`..`utcSaturday`, and `millisecond.every(k)`) eliminating calendar field extraction and intermediate `DateTime` allocations; pre-sized `range` allocation for fixed-period and calendar-stepped intervals; zero-allocation `floor`/`ceil`/`round`/`offset`/`count`; and precomputed standard interval table and cached `every(step)` intervals in `timeTicks`/`utcTicks`/`timeTickInterval`/`utcTickInterval`. | — | `test/port/faster_forms_test.dart`, `test/port/reference_test.dart` | Compare upstream algorithms when the pin changes. |
| <a id="platform-time-tz-tests"></a>`platform-time-tz-tests` | `test/day_test.dart`, `test/hour_test.dart`, `test/month_test.dart`, `test/test_time_zones_test.dart` | d3-time `test/day-test.js`, `test/hour-test.js`, `test/month-test.js`, `test/test-time-zones`@v3.1.0 | platform | Upstream tests run with `TZ=America/Los_Angeles`. In Dart tests executed under arbitrary host timezones (macOS, Linux, Windows, Chrome JS/Wasm), LA-specific hardcoded UTC↔local assertions run verbatim when the host timezone matches `America/Los_Angeles` and assert equivalent host-timezone DST/midnight invariants otherwise; `test/test_time_zones_test.dart` also spawns POSIX VM subprocesses under real `TZ=America/Los_Angeles`, `TZ=Asia/Kolkata`, `TZ=Asia/Kathmandu`, and `TZ=America/Sao_Paulo`. | — | `test/day_test.dart`, `test/hour_test.dart`, `test/month_test.dart`, `test/test_time_zones_test.dart` | Re-check TZ assumptions when upstream tests change. |
