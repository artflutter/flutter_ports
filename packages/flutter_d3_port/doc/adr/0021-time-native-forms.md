# D3 ADR 0021: Native forms of d3-time

- Status: accepted (2026-11-27): its code and the tests of section Tests pass.
- Date: 2026-11-27
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [D3 ADR 0017](0017-array-native-forms.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

`d3-time` 3.1.0 implements calendar time intervals and nice tick generation for local and UTC
calendars, forming the foundation for `d3-time-format` and `d3-scale`'s time scales:

- Interval factories & interfaces: `timeInterval(floor, offset[, count[, field]])`, `interval(date)`,
  `floor`, `ceil`, `round`, `offset`, `range`, `filter`, and (for countable intervals) `count` and
  `every`.
- Millisecond & second intervals (timezone-independent): `timeMillisecond`/`utcMillisecond`,
  `timeSecond`/`utcSecond`.
- Local calendar intervals (DST-aware): `timeMinute`, `timeHour`, `timeDay`, `timeWeek` (alias of
  `timeSunday`), `timeSunday`..`timeSaturday`, `timeMonth`, `timeYear`.
- UTC & Unix calendar intervals (DST-free): `utcMinute`, `utcHour`, `utcDay`, `unixDay` (plus
  `timeUnixDay` alias), `utcWeek` (alias of `utcSunday`), `utcSunday`..`utcSaturday`, `utcMonth`,
  `utcYear`.
- Convenience range aliases: `timeMilliseconds`, `utcMilliseconds`, `timeSeconds`, `utcSeconds`,
  `timeMinutes`, `utcMinutes`, `timeHours`, `utcHours`, `timeDays`, `utcDays`, `unixDays`,
  `timeUnixDays`, `timeWeeks`, `utcWeeks`, `timeSundays`..`timeSaturdays`,
  `utcSundays`..`utcSaturdays`, `timeMonths`, `utcMonths`, `timeYears`, `utcYears`.
- Tick generation (backed by `d3-array`'s `tickStep`): `timeTicks`, `timeTickInterval`, `utcTicks`,
  `utcTickInterval`.

Upstream JavaScript relies on mutable `Date` objects (which carry no `isUtc` flag, have 0-indexed
months, and shift years `0..99` to `1900..1999`), dynamic method attachment (`if (count) { ... }`),
untyped numeric/date coercion (`new Date(+date)`, `Math.floor(step)`), and overloaded `count`
parameters in `timeTicks`/`utcTicks` that accept either a number or an interval object.

Following [D3 ADR 0007](0007-native-dart-forms.md) (zero JS runtime),
[D3 ADR 0008](0008-module-packages.md) (one package per D3 module),
[D3 ADR 0009](0009-native-spec-harness.md) (native `package:test` specs and Node.js reference
tests), and [D3 ADR 0010](0010-native-values-and-factories.md) (typed native parameters),
`d3-time` 3.1.0 is ported as a standalone pure-Dart package `flutter_d3_time_port` depending only
on `flutter_d3_array_port: ^0.1.1`, with **zero `dynamic`, zero `Object?` escape hatches where
generics apply, zero JS runtime, and zero Flutter dependency**.

## Decision

1. **Pure Dart package (`d3_time.dart` + `flutter_d3_time_port.dart`).**
   `package:flutter_d3_time_port/d3_time.dart` exports every pure library in `lib/src/` without
   `show`/`hide` combinators (ADR 0011), and
   `package:flutter_d3_time_port/flutter_d3_time_port.dart` re-exports `d3_time.dart`. All 12
   upstream `src/*.js` files map 1:1 to `lib/src/*.dart`.

2. **Immutable native `DateTime` & Local vs UTC (`isUtc`) semantics.**
   - Every interval operates on immutable Dart `DateTime` values and returns new `DateTime` values;
     inputs are never mutated.
   - Local calendar intervals (`timeMinute`, `timeHour`, `timeDay`, `timeWeek` /
     `timeSunday`..`timeSaturday`, `timeMonth`, `timeYear`) normalize inputs with `date.toLocal()`
     and return local `DateTime` instances (`isUtc == false`).
   - UTC calendar intervals (`utcMinute`, `utcHour`, `utcDay`, `unixDay` / `timeUnixDay`, `utcWeek`
     / `utcSunday`..`utcSaturday`, `utcMonth`, `utcYear`) normalize inputs with `date.toUtc()` and
     return UTC `DateTime` instances (`isUtc == true`).
   - Timezone-independent intervals (`timeMillisecond`/`utcMillisecond` and
     `timeSecond`/`utcSecond`) are shared identical singletons matching upstream
     (`identical(utcMillisecond, timeMillisecond)` and `identical(utcSecond, timeSecond)`) and
     preserve `date.isUtc` on their outputs while truncating sub-millisecond microseconds to match
     millisecond epoch precision across VM, AOT, `dart2js`, and `dart2wasm`.
   - `timeTicks` always returns local `DateTime` values; `utcTicks` always returns UTC `DateTime`
     values.
   - Because Dart `DateTime(y, m, d)` uses 1-indexed months (`1..12`) and does not add 1900 to
     years `0..99`, first-century dates (`year < 100`) work natively without workarounds.

3. **DST transitions and timezone offset polarity.**
   - `timeMinute.floor` and `timeHour.floor` compute `ms - msOffset` from the local millisecond,
     second, and minute components (rather than reconstructing `DateTime(y, m, d, h)`), preserving
     both folds of a DST fall-back repeated hour and correctly handling fractional-hour UTC offsets
     such as `Asia/Kolkata` (`+05:30`) and `Asia/Kathmandu` (`+05:45`).
   - `timeMinute.offset` and `timeHour.offset` advance by exact elapsed milliseconds
     (`step * durationMinute` / `step * durationHour`) so stepping across DST transitions never
     repeats or stalls.
   - `timeDay.floor`, `timeWeek.floor`, `timeMonth.floor`, and `timeYear.floor` construct local
     midnight (`DateTime(y, m, d)`), matching JS `setHours(0, 0, 0, 0)` even when DST begins or
     ends at midnight (e.g., `America/Sao_Paulo`).
   - `timeDay.count` and `timeWeekday.count` compensate for DST offset changes using Dart's
     `timeZoneOffset.inMinutes` (which has the opposite sign of JavaScript's `getTimezoneOffset()`):
     `(endMs - startMs + (end.timeZoneOffset.inMinutes - start.timeZoneOffset.inMinutes) * durationMinute) / duration`.

4. **Typed `TimeInterval` and `CountableTimeInterval` hierarchy.**
   - Typed callback aliases:
     - `typedef TimeFloor = DateTime Function(DateTime date);`
     - `typedef TimeOffset = DateTime Function(DateTime date, int step);`
     - `typedef TimeCount = num Function(DateTime start, DateTime end);`
     - `typedef TimeField = int Function(DateTime date);`
     - `typedef TimeFilter = bool Function(DateTime date);`
     - `typedef TimeRange = List<DateTime> Function(DateTime start, DateTime stop, [int step]);`
   - `class TimeInterval` exposes:
     - `DateTime call([DateTime? date])` (defaults to `DateTime.now()`, equivalent to `floor`)
     - `DateTime floor(DateTime date)`
     - `DateTime ceil(DateTime date)`
     - `DateTime round(DateTime date)`
     - `DateTime offset(DateTime date, [int step = 1])`
     - `List<DateTime> range(DateTime start, DateTime stop, [int step = 1])`
     - `TimeInterval filter(TimeFilter test)`
   - `class CountableTimeInterval extends TimeInterval` adds:
     - `int count(DateTime start, DateTime end)`
     - `TimeInterval? every(int step)` (returns `null` when `step <= 0`, `this` when `step == 1`
       for standard intervals, or a `TimeInterval` for `step > 1`).
   - Factories:
     - `TimeInterval timeInterval(TimeFloor floor, TimeOffset offset, [TimeCount? count, TimeField? field])`
       returns a `CountableTimeInterval` when `count != null` and a plain `TimeInterval` otherwise.
     - `CountableTimeInterval countableTimeInterval(TimeFloor floor, TimeOffset offset, TimeCount count, [TimeField? field])`
       provides a statically typed `CountableTimeInterval` constructor without runtime casts.
   - All built-in intervals (`timeMillisecond`..`utcYear`, plus `unixDay` and `timeUnixDay`) are
     statically typed as `CountableTimeInterval`. All convenience range aliases (`timeSeconds`,
     `timeDays`, `timeMonths`, `timeYears`, etc.) are typed `TimeRange` tear-offs of `.range`.

5. **Typed tick generation (`timeTicks`, `timeTicksWith`, `timeTickInterval`, `utcTicks`, `utcTicksWith`, `utcTickInterval`).**
   - `List<DateTime> timeTicks(DateTime start, DateTime stop, num count)` and
     `List<DateTime> utcTicks(DateTime start, DateTime stop, num count)` take a typed numeric
     target count (`int` or `double`).
   - `List<DateTime> timeTicksWith(DateTime start, DateTime stop, TimeInterval? interval)` and
     `List<DateTime> utcTicksWith(DateTime start, DateTime stop, TimeInterval? interval)` accept an
     explicit (nullable) `TimeInterval`, replacing JS's untyped `count` union with zero `Object?`
     or `dynamic`.
   - `TimeInterval? timeTickInterval(DateTime start, DateTime stop, num count)` and
     `TimeInterval? utcTickInterval(DateTime start, DateTime stop, num count)` select the closest
     standard interval (or multi-year / multi-millisecond step via `d3-array`'s `tickStep`),
     returning `null` when `count` is non-positive or non-finite.

6. **Hot-path optimizations across AOT, Wasm, and dart2js.**
   - Direct O(1) epoch-millisecond Euclidean arithmetic (`ms - ((ms - epochOffset) % period)`) for
     all fixed-length UTC/timezone-independent intervals (`millisecond`, `second`, `utcMinute`,
     `utcHour`, `utcDay`, `unixDay`, `utcSunday`..`utcSaturday`, and `millisecond.every(k)`),
     avoiding `DateTime` calendar field extraction and intermediate allocations in `floor`, `ceil`,
     `round`, `offset`, `count`, and `range`.
   - Pre-sized `List<DateTime>.generate(..., growable: true)` (or direct fixed-capacity growth) in
     `range` for fixed-period and calendar-stepped intervals (`utcMonth`, `utcYear`, `timeYear`,
     `timeMonth`, `timeDay`, `timeHour`, `timeMinute`, and `every(k)` multiples).
   - Direct table-indexed interval selection and cached standard `every(step)` intervals in
     `timeTicks`/`utcTicks`/`timeTickInterval`/`utcTickInterval`, eliminating per-call `bisector`
     closure allocation and `every(step)` object construction.

## Rejected

- Mutable wrapper around `DateTime` to mirror JS `Date.setHours`/`Date.setDate`: adds heap
  indirection and forces users to convert to/from native Dart `DateTime` at every boundary.
- Single `Object? count` parameter in `timeTicks`/`utcTicks` accepting `num` or `TimeInterval`:
  violates strict static typing and requires runtime type switching.
- Accepting `num` (or `double`) steps in `offset`/`range`/`every`: `int` is exact, avoids
  non-finite `.floor()` throws in Dart, and optimizes cleanly in AOT/Wasm.
- Hardcoding `America/Los_Angeles` test assertions without host timezone detection: breaks test
  suites on UTC Linux/Windows CI runners and non-Pacific developer machines.

## Consequences

- All 36 upstream test files (465 cases) port cleanly and pass across macOS, Linux, Windows,
  Chrome JS (`dart2js`/DDC), and Chrome Wasm (`dart2wasm`), with real IANA timezone subprocess
  verification (`America/Los_Angeles`, `Asia/Kolkata`, `Asia/Kathmandu`, `America/Sao_Paulo`)
  covering `test/test-time-zones` on POSIX VMs.
- `d3-time-format` and `d3-scale` time scales can build directly on `flutter_d3_time_port` with
  full static typing and zero JS runtime overhead.

## Tests

- `packages/flutter_d3_time_port/test/*_test.dart` (all 36 upstream spec files, 465 cases, plus
  `test/test_time_zones_test.dart`)
- `packages/flutter_d3_time_port/test/port/reference_test.dart`
- `packages/flutter_d3_time_port/test/port/faster_forms_test.dart`
- `packages/flutter_d3_time_port/test/upstream_test.dart`
- `packages/flutter_d3_port/test/port/d3/index_test.dart`
