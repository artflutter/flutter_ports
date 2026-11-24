# Chart.js ADR 0203: A typed date adapter

- Status: accepted (2026-11-25): its code is on main, and the gates of AGENTS.md pass.
- Date: 2026-11-25
- Supersedes: of [Chart.js ADR 0024](0024-dates.md), §1 the items "Installation", "Members" and
  "Dispatch", and §2 the member types and the `jsConstruct` of `:269`; of
  [Chart.js ADR 0173](0173-option-function-types.md), item 4 for the date adapter members
- Related: [Chart.js ADR 0202](0202-no-string-data.md)

## Context

The date adapter took and gave JS values (`Object?`). An app changed it with
`DateAdapterBase.override(Map)`, which wrote the members into the static Map `DateAdapterBase.prototype`
with `jsAssign`. Each method of `DateAdapterBase` read its member by name and switched over two function
forms. The time scale made the adapter with `jsConstruct(adapters['_date'], ...)` and read each result with
`jsToNumber` or `jsToString`.

## Decision

1. `DateAdapter` has typed members: a timestamp is a `double`, an amount a `double`, a format a
   `String?`, an ISO weekday an `int` and a unit a `TimeUnit`. `parse` takes the raw data value and gives a
   `double?`. `formats` gives a `Map<String, String>`.

   ```dart
   // Before
   Object? add(Object? timestamp, Object? amount, TimeUnit unit);
   // After
   double add(double timestamp, double amount, TimeUnit unit);
   ```

2. `DateAdapterBase` is the abstract base class with `options` and an empty `init`. `DefaultDateAdapter`
   of `date_adapter.dart` extends it with the rules of chartjs-adapter-moment 1.0.1. `prototype`,
   `override` and `dateAdapterMembers` are gone (row `adapt-date-adapter-class`).
3. `adapters` is a `ChartAdapters`. Its field `date` holds the constructor of the adapter, the upstream
   `_adapters._date`. An app writes the constructor of its subclass into it.

   ```dart
   // Before
   DateAdapterBase.override({'parse': (Object? self, Object? value, Object? format) => 42.0});
   // After
   final class MyDateAdapter([super.options]) extends DefaultDateAdapter {
     @override
     double? parse(Object? value, [String? format]) => 42;
   }
   adapters.date = MyDateAdapter.new;
   ```

4. The time scale gives the adapter typed values: NaN for the JS `null` value of a tick, 1 for the option
   `time.isoWeekday` `true` and the whole part of a number, and Dart `null` for a falsy display format. A
   display format that is neither a `String` nor falsy throws a `TypeError` in the scale, as moment throws
   in `format`.

## Consequences

- `lib/src/core/core.adapters.dart` has no `jsAssign`, no `jsConstruct` and no read by name. The time scale
  reads no adapter result with `jsToNumber` or `jsToString`.
- A method that a subclass leaves out of `DateAdapterBase` is a compile error, not the `Error` of
  `abstract()`.
- A member set to `undefined` has no form. Upstream then throws a `TypeError` at the call.
- A custom `format` gives one line. Upstream, a `format` that returns an array gives a label of several
  lines.
- The tests of the moment rules with JS-only inputs (a string amount, a `DateTime` time, a NaN weekday) call
  the helpers of `date_calendar.dart`, `date_parse.dart` and `date_format.dart`.

## Tests

`test/port/core/core.adapters_test.dart`, `test/port/core/date_adapter_test.dart`,
`test/port/scales/scale.time_test.dart` (group `the date adapter`), `test/specs/scale.time_test.dart` (test
`should pass chart options to date adapter`).
