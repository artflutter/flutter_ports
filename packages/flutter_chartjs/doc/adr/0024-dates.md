# Chart.js ADR 0024: Dates

- Status: accepted (2026-10-20)
- Date: 2026-10-20
- Related: [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (JS values as Maps,
  the `undefined` sentinel),
  [Chart.js ADR 0008](0008-number-formatting-on-package-intl.md) (`package:intl` and its locale),
  [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (the protected behavior, §5 dates on
  `DateFormat`), [Chart.js ADR 0010](0010-js-numeric-semantics.md) (§6 `jsDateNow`, the
  reference engine), [Chart.js ADR 0011](0011-third-party-sources.md) (no new source),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (paths),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) (§3 class values, §5 errors, §13
  the microbenchmark rule), [Chart.js ADR 0022](0022-chart-test-harness.md) (the harness),
  [Chart.js ADR 0025](0025-scale-value-parameters.md) (the field `adapter` of the time scale),
  [porting-flow.md](../porting-flow.md) §1.1, §2.10 and §3

## Context

Phase 6 ports `scale.time.js` and `scale.timeseries.js`. The time scale reads every date through
a date adapter. Chart.js v4.5.1 has no adapter of its own. This ADR decides the adapter of the
port and the date rules that the ticks depend on. A design panel of three drafts (fidelity,
performance, simplicity), a judge and a synthesis wrote it. The line numbers refer to Chart.js
v4.5.1, chartjs-adapter-moment 1.0.1 (`dist/chartjs-adapter-moment.esm.js`) and moment 2.29.4
(`moment.js` of the npm package).

### Upstream

- `src/core/core.adapters.ts` declares the interface `DateAdapter` (`:12-63`) and the class
  `DateAdapterBase` (`:75-129`).
  - `init` is empty (`:100`). The seven other methods call `abstract()` (`:102-128`). It throws
    `'This method is not implemented: Check that a complete date adapter is provided.'`
    (`:65-67`).
  - `static override(members)` is `Object.assign(DateAdapterBase.prototype, members)` (`:87-91`).
  - The constructor keeps `options || {}` (`:95-97`).
  - The default export is `{_date: DateAdapterBase}` (`:131-138`).
- `docs/axes/cartesian/time.md:7`: "The time scale **requires** both a date library and a
  corresponding adapter to be present." The adapter defines the accepted input (`:17`), the
  format strings (`:94`) and the parser strings (`:127`). `adapters.date` holds the "Options for
  adapter for external date library if that adapter needs or supports options" (`:31`). The docs
  number `isoWeekday` "0 - Sunday, 6 - Saturday" (`:36`).
- An adapter package calls `_adapters._date.override({...})` when the page loads it.
  chartjs-adapter-moment 1.0.1 does this at `:23-63`. Its `formats()` returns the same object
  `FORMATS` at each call (`:10-21`, `:26-28`). It has no `init`. Its `_id: 'moment'` is "DEBUG
  ONLY" (`:24`).
- The specs load `moment.min.js`, `moment-timezone-with-data.min.js`, `src/index.umd.ts` and
  `chartjs-adapter-moment.js` (`karma.conf.cjs:106-111`). The lockfile selects
  chartjs-adapter-moment 1.0.1, moment 2.29.4 and moment-timezone 0.5.42 (`package.json:89`,
  `:114`, `:115`, `pnpm-lock.yaml:48-50`, `:123-128`). `test/index.js:21-23` sets
  `window.moment.tz.setDefault('Etc/UTC')`. Thus the specs run in UTC.
- `scale.time.tests.js:1283-1306` calls `Chart._adapters._date.override({init})`. The case
  compares the argument of `init` with `chart.options`. It never restores `init`.

The time scale calls the adapter at these lines of `scale.time.js`. `scale.timeseries.js` makes no
adapter call of its own. It replaces `_generate` with the data timestamps (`:119-130`).

| Line | Call | Use of the result | Chart.js ADR 0009 class |
|---|---|---|---|
| `:269`, `:271` | `new adapters._date(scaleOpts.adapters.date)`, `adapter.init(opts)` | the adapter of one update | - |
| `:277` | `mergeIf(time.displayFormats, adapter.formats())` | the display formats | resolved option |
| `:62-63` | `parse(value, parser)` or `parse(value)` for a value that is not a finite number | `+value` (`:76`) | data position, ticks, item order |
| `:72-73` | `startOf(value, 'isoWeek', isoWeekday)` or `startOf(value, round)` | `+value` | data position |
| `:114` | `diff(max, min, unit) >= numTicks - 1` | the label unit and the major unit | ticks |
| `:158`, `:162` | `startOf(first, majorUnit)`, `add(major, 1, majorUnit)` | the major flags | ticks |
| `:342-343` | `startOf(Date.now(), unit)`, `endOf(Date.now(), unit) + 1` | min and max without data | ticks |
| `:467`, `:471` | `startOf(first, 'isoWeek', weekday)`, `startOf(first, unit)` | the first tick | ticks |
| `:474-476` | `diff(max, min, minor) > 100000 * stepSize` | `throw new Error(...)` | a throw |
| `:479` | `time = +adapter.add(time, stepSize, minor)` while `time < max` | the tick values, the loop end | ticks |
| `:500`, `:502`, `:515`, `:543` | `format(value, format)` | the label text | display |
| `:610-622` | `format(min, displayFormats.millisecond)` and its width | the label capacity, thus the auto unit (`:457`) | ticks |

- `scale.init` runs in each `chart.update()` (`core.controller.js:367`). Thus `:269-277` run once
  in each update.
- The scale passes raw option values: `ticks.stepSize` (`:458`), `time.unit`, `time.round` and
  `time.isoWeekday`, which can be `true` (`:71`, `:459-460`). A format is `undefined` when
  `displayFormats` has no entry for the unit (`:515`).
- `parse` runs twice for each string label in each update: once for the dataset parse
  (`core.datasetController.js:514`), and once for the label cache, which `beforeLayout` clears
  (`scale.time.js:302-309`, `:651-665`).

### The official adapters give other ticks

The scout probes ran chartjs-adapter-moment 1.0.1, chartjs-adapter-luxon 1.3.1 and
chartjs-adapter-date-fns 3.0.0 in UTC (`scout/dates-evidence.md` §2):
- `startOf(t, 'isoWeek', w)`: moment keeps the result in the ISO week of `t` (Monday to Sunday).
  Thus it moves forward up to 5 days for `w` 2-6. luxon and date-fns move back 0-6 days.
- `startOf(t, 'week')`: Sunday in moment (locale `en`) and date-fns. Monday in luxon.
- `diff`: moment and date-fns truncate toward zero. luxon returns fractions of 30-day months and
  365-day years. At `:474`, the two forms give a throw or no throw for a range of 100000.5 ms.
- `add` with a fractional amount: moment rounds days and months half away from zero. date-fns
  truncates. luxon keeps the fraction.
- A step that does not advance makes `_generate` loop without end. With moment, `stepSize` 0.4
  with `day` or `month`, 0.5 with `millisecond`, and 0 for a range below one unit hang
  (`scout/dates-probe/loop.mjs`).

The specs run on moment. Thus the specs encode the moment results.

### The port after phase 5

`lib/src/core/core.adapters.dart` ports `core.adapters.ts`. It is a pure layer.
- Each member of `DateAdapter` takes and gives `Object?`. `TimeUnit` is the typedef `String`.
- `DateAdapterBase.prototype` is a static Map. It holds the members that `override` assigns. Each
  method calls its member there through `jsCall`, with the adapter as `this`. Without a member, the
  method runs its own body (row `adapt-date-adapter-prototype`).
- `adapters` is `{'_date': DateAdapterBase.jsClass}`.

[Chart.js ADR 0009](0009-no-display-only-js-exactness.md) §5 (accepted) decides: the default date
adapter formats with `DateFormat` of `package:intl`, with ICU pattern tokens. The port has no
moment-compatible formatter or parser. A spec case that asserts moment-token text or parses a
moment format string skips with `'diverges: <row id>'`.

### Measured facts

Machine: Apple M3 Max, macOS 26.5.1, Dart 3.12.2 (Flutter 3.44.9), `package:intl` 0.20.3. AOT is
`dart compile exe`. dart2wasm and dart2js ran in the x64 Node.js v24.12.0 under Rosetta, except
where a fact says otherwise. The figures are medians, in ns for each call. The Evidence section
gives the files.

1. **Dispatch** (judge `dispatch2-*.txt`). The extra cost of a call through
   `DateAdapterBase.prototype`, over a direct call of the same body:

   | Form | AOT | dart2wasm | dart2js |
   |---|---|---|---|
   | The phase 5 path (`jsCall`) | 22-27 | 64-70 | 32-46 |
   | A typed direct call of a member of the exact Dart function type | 7-8 | 21-26 | 15-22 |

2. **UTC calendar** (performance draft F2, judge `calendar-aot.txt`). Integer day arithmetic
   against `DateTime.utc` and the `DateTime` fields: `startOf` day 13.1 against 82.5 ns, `add` 1
   day 7.9 against 87.3 ns, `add` 1 month 44.4 against 138.2 ns on AOT. dart2wasm: 16.0 against
   120.1, 9.5 against 123.5, 38.8 against 232.3 ns. The results were equal in 139,264 checks.
   `DateTime.utc` wraps far outside the Date range: `DateTime.utc(2015, 1, 1 + 1000000000)` gives
   `-5832300298147759` on the VM, without a throw (simplicity `probe_range_vm.txt`). `Date.UTC`
   gives NaN there.
3. **Local time** (performance draft F3, F4). The local `DateTime` constructor costs about
   1,000 ns on AOT and dart2wasm, because it asks the platform for the offset.
   - A cache keeps one interval of instants with one offset. Rule: when the offsets at
     `t - 1 day`, `t` and `t + 1 day` are equal, the offset is constant on that interval. The rule
     is exact when no two offset changes of a zone are less than 48 h apart.
   - The macOS tzdata 2026c has 598 zone files. In 1902-2037, the smallest gap between two offset
     changes of a zone is 167 h.
   - 466 offset changes of 1902-2037 are not at a multiple of 15 minutes. Thus a cache by time
     slot is not exact.
   - The cache gave the `DateTime` result with 0 mismatches: 12 zones and 1,826,796 values on the
     VM, 6 zones on dart2wasm, Kyiv on dart2js. The judge reproduced it in Kyiv (190,480), Apia
     (71,350) and Sao Paulo (152,860) on the VM.
   - Wall time to instant: 52.7 ns with the cache, 678.9 ns with the constructor on AOT. dart2wasm:
     37.7 against 300.2 ns.
   - dart2js gives `timeZoneOffset` in whole minutes. The local fields keep the seconds of a local
     mean time (LMT) offset. A cache on `timeZoneOffset` gave 7,368 mismatches in Kyiv. A cache on
     the local fields gave 0.
4. **Platform offsets** (`scout/dates-evidence.md` §4, fidelity draft).
   - The VM and dart2wasm take the local offset from a substitute year before
     1901-12-13T20:45:52Z and after 2038-01-19T03:14:07Z (±2^31 s). After 2038 the offset is wrong
     by one hour in Moscow, Mexico City, Sao Paulo and Tehran.
   - dart2wasm gives LMT offsets in whole minutes: 4 s off in Kyiv before 1924, 28 s in Sao Paulo
     before 1914 and 44 s in Tehran before 1935.
   - dart2js follows JS `Date`.
   - V8 `getTimezoneOffset()` gives whole minutes: -205 in Tehran in 1910, where the offset is
     +3:25:44. moment computes its offset from it (`moment.js:3294-3298`). Its hour floor
     (`:4135-4141`) uses that offset. Thus moment gives 13:00:44 local in Tehran on 1910-06-01,
     and an exact floor gives 13:00:00. Kyiv: 12:00:04 against 12:00:00 (judge `lmt_hour.txt`).
5. **ISO 8601 parse** (performance draft F5, judge `iso_check-rerun.txt`). A corpus of 7,242
   strings, compared with chartjs-adapter-moment 1.0.1 in UTC. moment used its `new Date(string)`
   fallback for 21 strings. Of the other 7,221 strings:
   - A code-unit scanner of the moment ISO grammar (`moment.js:2314-2345`, `:2364`) with the
     checks of `checkOverflow` (`:2268`) gave the moment result for 7,220. The miss is the RFC 2822
     string `'Thu, 01 Jan 2015 20:00:00 +0000'` (`:2496`).
   - `DateTime.tryParse` gave the moment result for 5,518. It rejects `2015`, `2015-01`, week dates
     and ordinal dates. It accepts `2015-02-30` and `1988-09-31`.
   - The scanner costs 35-54 ns on AOT and 57-140 ns on dart2wasm. `tryParse` costs 745-1,709 ns
     and 796-1,606 ns.
6. **Parse with a format** (fidelity `intl_parse.txt`, performance draft F6).
   `DateFormat.tryParse` accepts text after the date and does not check the field ranges:
   `'2015-13-01 00:00'` gives 2016-01-01. `parseStrict` and `parseLoose` reject text after the
   date. A pattern without a year gives 1970. moment fills the first absent fields of year, month
   and day from the current local date (`create/from-array.js:79-81`, `currentDateArray`). A valid
   parse costs 939 ns on AOT.
   A failed parse costs 2,458 ns on AOT and 16,648 ns on dart2wasm, because intl throws a
   `FormatException` inside.
7. **Format** (performance draft F7, fidelity `formats_check.txt`).
   - The ten ICU patterns of decision 6 gave the moment text for 1,029 of 1,029 timestamps (also the
     years 5, 99 and 10000) and for 80 of 80 samples. Four keys need the lower-case day period.
     Plain `DateFormat` gave 0 of 1,029 for these four keys.
   - A cached `DateFormat` costs 209-509 ns on AOT. A new `DateFormat` for each call costs
     1,839-9,104 ns. The lower-case day period adds 0-82 ns.
8. **The day period changes ticks** (judge `capacity_ampm2.txt`). Moment `a` against `A` in the
   four keys, with the advance widths of Arial and Liberation Sans at 12 px: the label capacity
   differs in 2,240 of 17,920 time-scale charts (1 s to 3 years, 200-1,200 px). The unit, the tick
   count or the tick values differ in 101. Example: 0-6 h at 515 px gives `minute`, 21 ticks with
   `am`, and `hour`, 7 ticks with `AM`.
9. **Locale data** (judge `locale_exists.txt`, fidelity `intl_locale.txt`). Without
   `initializeDateFormatting`, `DateFormat(pattern, locale)`, `DateFormat.localeExists` and
   `Intl.verifiedLocale(locale, DateFormat.localeExists)` throw a `LocaleDataException` for `en`,
   `de`, `de_DE` and `es`. Only `en_US` and `en-US` have data. `package:intl/intl.dart` does not
   export `LocaleDataException`. The en_US `FIRSTDAYOFWEEK` is 6 (Sunday).
10. **Format edges of moment** (fidelity `format_edges.txt`). A falsy format (`undefined`, `null`,
    `''`, `false`, `0`) gives the ISO default text: `2015-01-01T20:00:00Z` in UTC and
    `2015-01-01T15:00:00-05:00` in local time (`moment.js:3923-3924`, `:3988-3996`). A format of
    `5`, `{}` or `['YYYY']` throws a `TypeError`.
11. **The repeated hour** (simplicity fact 5). moment adds no field for an amount of 0 calendar
    units (`moment.js:3617-3622`). A wall-time step of 0 days through the zone gives the earlier of
    the two instants of a repeated hour. moment returns the input.
12. **Calls of one update** (judge `count_labels.txt`, fidelity `count_calls.txt`).
    - 1,000 ISO labels with number data: `init` 1, `formats` 1, `parse` 2,000, `format` 14,
      `startOf` 1, `diff` 1, `add` 12.
    - 1,000 numbers with `time.round: 'day'`: `startOf` 1,001.
    - A `timeseries` scale with 1,000 timestamps: 1,001 `format`.
    - Ten `chart.draw()` calls after an update make 0 adapter calls.
13. **One update** (performance draft F8, ms on AOT / dart2wasm, N ISO labels, no text measure and
    no draw).

    | Form | N = 1,000 | N = 20,000 |
    |---|---|---|
    | Subclass, scanner, integer calendar, cached formats, UTC | 0.15 / 0.39 | 3.34 / 6.28 |
    | The same with the phase 5 dispatch | 0.20 / 0.51 | 4.23 / 11.78 |
    | The same in local time with the offset cache | 0.20 / 0.37 | 5.67 / 8.26 |
    | The same in local time with the `DateTime` constructor | 1.52 / 1.01 | 31.30 / 22.39 |
    | The phase 5 dispatch, `tryParse`, the `DateTime` calendar, a new `DateFormat` for each call | 3.37 / 2.98 | 66.01 / 62.50 |

14. **A moment rule set in Dart** (fidelity draft). A prototype of the moment rules on
    millisecond arithmetic gave the results of chartjs-adapter-moment 1.0.1 in the spec
    environment for 356,180 calls of `startOf`, `endOf`, `add` and `diff`, with 0 differences on
    the VM, dart2js and dart2wasm. In local time, it gave 0 differences inside ±2^31 s in New York,
    Sao Paulo, Kyiv and Tehran (465,908 calls in each zone).

## Decision

### 1. The default adapter: files and installation

- **Files.** Five port-only files in `lib/src/core/` hold the default adapter. Each file starts
  with `// Original code, not ported from Chart.js: <reason>.` No pinned source maps to these
  paths ([Chart.js ADR 0012](0012-dart-file-naming.md)).

  | File | Content |
  |---|---|
  | `date_adapter.dart` | the Map `dateAdapterMembers`, `setDefaultDateZone` and `defaultDateZone` |
  | `date_calendar.dart` | the unit aliases, TimeClip, the day numbers, `startOf`, `endOf`, `add`, `diff` |
  | `date_zone.dart` | the interface `DateZone` and `LocalZone`, the offset cache |
  | `date_parse.dart` | the input rule, the ISO 8601, RFC 2822 and ASP.NET grammars, the parse with a format |
  | `date_format.dart` | the ten patterns, the compiled patterns and their cache, the ISO default text |

- The five files are pure-layer roots (`lib/src/core/date_*.dart`). They import the JS runtime and
  `package:intl/intl.dart`. They do not import `core.adapters.dart`.
- **Installation.** `DateAdapterBase.prototype` starts as `{...dateAdapterMembers}`. This is one
  hunk with the marker of the row `adapt-date-default-adapter`. `adapters['_date']` stays
  `DateAdapterBase.jsClass`.
  - Upstream, the adapter package writes its members into `DateAdapterBase.prototype` at load
    (`chartjs-adapter-moment.esm.js:23`, `core.adapters.ts:90`). Dart has no import side effect.
    The static initializer of `prototype` runs at its first read. Thus the members exist before
    the first adapter call, with no install call and no order rule.
  - The runtime object graph is the one of upstream with an adapter package: `_date` is the base
    class, and its prototype holds the members.
  - A later `override` replaces only its own keys. `scale.time.tests.js:1283` passes: `init` gets
    the chart options, and the default members stay.
  - A cleared `prototype` gives the abstract error again. Thus `core.adapters_test.dart` can test
    the base alone.
- **Members.** `dateAdapterMembers` has the keys `formats`, `parse`, `format`, `add`, `diff`,
  `startOf` and `endOf`. Each value is a top-level Dart function that does not read `this`. The Map
  has no `init`, because chartjs-adapter-moment has none. It has no `_id`, because no upstream code
  reads it.
- **Dispatch.** Each method of `DateAdapterBase` reads its member once. A member that is a Dart
  function of the exact type of the method gets a direct call. Any other value goes through
  `jsCall` with the adapter as `this`, as in phase 5. Both calls give one result. A Dart closure
  cannot read `this`. `jsCall` passes the same arguments to a closure that takes that argument
  count (`js_function.dart:131-144`, `:172-203`). The direct call cuts the extra cost from
  22-27 to 7-8 ns on AOT and from 64-70 to 21-26 ns on dart2wasm (fact 1). It keeps the upstream
  structure. Thus the microbenchmark gain counts
  ([Chart.js ADR 0020](0020-registry-and-component-classes.md) §13).
- **License.** The five files copy no code of moment or of chartjs-adapter-moment. They state
  the moment rules of decisions 3-6 in code of the port, and the reference values of decision 9
  pin each rule. A porter who translates a moment function line by line makes a port of a
  third-party source. [Chart.js ADR 0011](0011-third-party-sources.md) then applies.

### 2. The member types

- Each parameter and each result of `DateAdapter` stays `Object?`. `TimeUnit` stays
  `typedef TimeUnit = String`.
  - These values reach the members (`scout/dates-evidence.md` §5): the raw `ticks.stepSize`, the
    weekday `true`, a `null` timestamp (`:500`), an `undefined` format (`:515`), the raw result of
    a custom `parse` (`:72-73`), and any value of `displayFormats` and `tooltipFormat`.
  - A custom member can return a `DateTime`, as date-fns returns a `Date`. A custom `format` can
    return a List for a label of several lines.
  - A `TimeUnit` enum needs one conversion for each call, at the cost of the `String` switch
    (performance draft F2: up to 8 ns).
- Each default member converts its arguments once at its entry:
  - A time argument goes through the input rule of decision 5, as `moment(time)` does. A `double`
    takes the first branch.
  - An amount goes through `jsToNumber`. NaN gives 0, as the `|| 0` of the moment `Duration`
    (`moment.js:3157-3190`).
  - A unit goes through the alias table of moment (`moment.js:633-644`). For `startOf`, `endOf`
    and `diff`, a value that is not a `String` is an unknown unit. `add` reads its unit with the
    moment rule of decision 4.
- `jsToNumber` of a `DateTime` gives its `millisecondsSinceEpoch` as a `double`. ECMAScript
  `ToNumber` of a `Date` gives its time value. Thus a member that returns a `DateTime` gives the
  right number at `+value` (`scale.time.js:76`). `jsTypeof` of a `DateTime` already gives
  `'object'`.
- A `DateTime` data value is not finite at `scale.time.js:60`. That line calls the helper
  `isFinite` (`isNumberFinite`, `helpers.core.ts:61`), not the global `isFinite`. The helper is
  false for a value that is not of the type `number`, thus false for a JS `Date`. Thus upstream
  gives a `Date` to `adapter.parse`, and the input rule of decision 5 gives its time value.
  `scale.time.dart` calls the helper `isFinite` there. The x64 Node.js v24.12.0 with the chart.js
  4.5.1 dist gives `false` for `helpers.isFinite(new Date(0))` and `true` for
  `isFinite(new Date(0))`.
- The field `adapter` of `TimeScale` ([Chart.js ADR 0025](0025-scale-value-parameters.md) §6) has
  the type `DateAdapter`. `:269` is `jsConstruct(adapters['_date'], [options]) as DateAdapter`.

### 3. Time zones

- **Local by default.** moment without a default zone uses the local zone. Thus an app gets the
  ticks of an upstream app with chartjs-adapter-moment.
- **One global setter.** `setDefaultDateZone(String? name)` of `date_adapter.dart` is the analog of
  `moment.tz.setDefault(name)`. `null` gives the local zone. `'UTC'` and `'Etc/UTC'` give UTC. Any
  other name throws an `ArgumentError`, because the package has no zone data. The getter
  `defaultDateZone` gives the current name.
- **No other selection.** The default members read no `adapters.date` option and no chart
  `locale`. chartjs-adapter-moment reads no option. The specs set a global
  (`test/index.js:23`).
- **The spec harness.** `test/flutter_test_config.dart` ports `test/index.js:23` as
  `setDefaultDateZone('Etc/UTC')`. This line translates the upstream line, as the DPR line does.
  It needs no marker and no row. `setUpSpecs()` of `package:chartjs_test_utils/pure.dart` also
  calls it, for `dart test`. A test that changes the zone restores it with `addTearDown`.
- **One calendar core on wall time.** The calendar functions work on wall milliseconds: the wall
  fields of a zone, coded as UTC milliseconds. A zone gives two functions:
  - `offsetAt(t)`: the offset of the instant `t` in ms. The wall time is `t + offsetAt(t)`.
  - `fromWall(w)`: the instant of the wall time `w`. A repeated wall time gives the earlier
    instant. A skipped wall time uses the offset before the change. This is the rule of JS `Date`.
    The local `DateTime` constructor gave the same results for 18 such wall times on the VM,
    dart2wasm and dart2js (performance draft F4).
- **UTC** has no zone object. The calendar functions get the zone `null` and use integer day
  arithmetic (fact 2).
- **Local** is `LocalZone`.
  - It reads the offset of an instant from the local fields of
    `DateTime.fromMillisecondsSinceEpoch(t)`, not from `timeZoneOffset` (fact 3, dart2js).
  - It keeps one interval of instants with one offset, with the 1-day rule of fact 3.
  - The default `formats` member clears the cache. The time scale calls `formats()` once in each
    update (`scale.time.js:277`), before the parse of that update. Thus the cache holds the
    offsets of one update. A change of the platform zone reaches the next update.
    `setDefaultDateZone` also clears the cache.
- **The hour floor** of `startOf('hour')` and `endOf('hour')` uses the offset in whole minutes,
  truncated toward zero, as V8 `getTimezoneOffset()` gives it (fact 4). `diff` uses the same
  offset for its zone delta (decision 4).
- **Platform offsets.** `LocalZone` gives the offsets of the platform. It does not correct them
  outside ±2^31 s, and it does not correct the whole-minute LMT offsets of dart2wasm (fact 4). Row
  `platform-date-local-offset`, with its marker at the platform read of `LocalZone`. UTC gives the
  same results on every target.
- **Named zones later.** A later optional package can add named zones on `timezone` `^0.11.2`, with
  its own ADR. It implements `DateZone` and extends the names of `setDefaultDateZone`. The calendar
  core does not change. That ADR also decides the rules after 2037 and a zone option for each
  scale.

### 4. Calendar rules

The default members give the results of chartjs-adapter-moment 1.0.1 on moment 2.29.4. The time is
a JS number in ms. Each rule cites its moment source.

- **TimeClip.** A result outside ±8.64e15 ms is NaN, as an invalid JS `Date`. An invalid input
  gives NaN from `add`, `diff`, `startOf` and `endOf`. One moment exception stays: in UTC, `diff`
  with an invalid second argument gives 0 for `month`, `quarter` and `year`. moment
  `cloneWithOffset` keeps the validity of the first value there (`moment.js:3277-3292`), and
  `monthDiff` then gives `NaN || 0` (`:3920`).
- **Units.** The alias table maps `days`, `d`, `M`, `isoweek` and the other aliases to the moment
  unit (`moment.js:633-644`). A string that is not in the table is an unknown unit. `startOf`,
  `endOf` and `add` return the input for it. `diff` returns the difference in ms.
- **`startOf`** (`moment.js:4094-4155`):
  - `millisecond` and an unknown unit give the input.
  - `second` and `minute` floor the instant to 1,000 and 60,000 ms.
  - `hour` floors `t` plus the whole-minute offset to 3,600,000 ms (decision 3). Thus the result
    keeps the offset of the input in a repeated hour.
  - `day`, `week`, `month`, `quarter` and `year` give the start of the unit from the wall fields,
    through `fromWall`.
  - `week` starts on the first day of the intl locale: `FIRSTDAYOFWEEK` of the `DateFormat` of
    decision 6. en_US gives Sunday. The moment week also depends on its locale
    (`moment.js:1420-1426`).
  - Another alias that `startOf` has no case for, for example `weekday`, gives NaN, as
    `setTime(undefined)` does.
- **`isoWeek`** (`chartjs-adapter-moment.esm.js:51-56`, `moment.js:1736-1750`). The member
  compares the unit with `'isoWeek'` exactly. The weekday is
  `trunc(min(max(0, ToNumber(weekday)), 6))`. Thus `true` gives 1, `7` gives 6 and `1.5` gives 1.
  The result is the start of the day with that weekday in the ISO week (Monday to Sunday) of the
  input. Thus a weekday 2-6 can move the date forward. Weekday 0 is the Sunday before that week.
  A NaN weekday (also `undefined`) throws a `TypeError` on Monday to Saturday, and gives the
  Sunday one week before on a Sunday. `time.round: 'isoWeek'` reaches this branch with no weekday
  (`scale.time.js:71-73`).
- **Weekday numbers.** 0 is Sunday, 1 is Monday and 6 is Saturday, as the clamp and `time.md:36`
  give. The comment `core.adapters.ts:53-55` keeps its upstream text.
- **`endOf`** (`moment.js:4157-4224`): `second`, `minute` and `hour` give the floor plus the unit
  minus 1 ms. The other units give the start of the next unit from the wall fields, minus 1 ms.
  The member does not add one unit to the result of `startOf`. After a skipped local midnight,
  that form gives an end that is one hour late (simplicity draft, Kyiv, April 1981).
- **`add`** (`moment.js:3157-3190`, `:3196-3202`, `:3605-3629`):
  - The amount and the unit follow the moment `createAdder` and `createDuration`
    (`moment.js:3580-3597`, `:3463-3483`). When the unit is not `null` and its `ToNumber` is not
    NaN, the member exchanges the amount and the unit. After that, a falsy unit, for example
    `undefined` or `null`, adds the amount in ms. A truthy unit that is not a `String` goes
    through `ToString`, as the key of the moment duration. Thus `['day']` adds days, and `true` is
    an unknown unit. An unknown unit returns the input. The x64 Node.js v24.12.0 with moment
    2.29.4 gives 1 for `moment.utc(0).add(1, undefined)` and 86,400,000 for
    `moment.utc(0).add(1, ['day'])`.
  - `millisecond`, `second`, `minute` and `hour` add `n`, `n * 1e3`, `n * 6e4` and
    `n * 1000 * 60 * 60` ms, in this order of operations. TimeClip truncates the sum. Thus 0.5 ms
    adds 0 ms to a positive time.
  - `day` and `week` add `absRound(n)` and `absRound(n * 7)` days to the wall date. `month`,
    `quarter` and `year` add `absRound(n)`, `absRound(n * 3)` and `absRound(n * 12)` months.
    `absRound` rounds half away from zero. Thus 0.4 day adds 0 days, and 0.5 month adds 1 month.
  - A month step keeps the day of the month, clamped to the last day of the target month
    (`moment.js:1097-1120`).
  - The new wall time goes through `fromWall`. Thus a day step keeps the local wall time across a
    DST change.
  - An amount of 0 calendar units returns the input (fact 11). This also applies to 0.4 day.
- **`diff(a, b, unit)`** (`moment.js:3847-3921`, `absFloor` at `:687-694`):
  - The member truncates the result toward zero. -0 gives 0.
  - `month`, `quarter` and `year` use the moment `monthDiff`: whole months from `b` to `a` with the
    month-end clamp of `add`, plus a linear part of the next month. `quarter` and `year` divide by
    3 and 12 before the truncation.
  - `day` and `week` subtract the zone delta: the whole-minute offset of `b` minus that of `a`.
    Thus a 23-hour DST day counts as one day.
  - `second`, `minute` and `hour` divide the difference of the instants.
- **A loop that does not advance.** The port of `_generate` (`scale.time.js:479`) computes
  `next = +adapter.add(time, stepSize, minor)`. It throws a `StateError` with a new message when
  `next <= time`. A NaN `next` fails this test. Then `time` becomes NaN, and the loop ends, as
  upstream (`NaN < max` is false). Row `adapt-time-generate-no-advance`, category `adapt`.
  - Upstream loops without end there. A synchronous loop without end stops the UI isolate and the
    `flutter test` process.
  - Upstream adds the guard of `:473-476` to "Prevent browser from freezing". The new test costs
    one compare for each step.
  - The stop changes no result that upstream returns.

### 5. `parse`

`parse(value, format)` follows `chartjs-adapter-moment.esm.js:30-37`. A `String` value with a
`String` format goes to the parse with a format. Any other value goes to the input rule. An empty
format also goes to the input rule, because moment tests `if (format)` (`moment.js:2973`). The
member returns `null` for an invalid result.

- **The input rule** (`moment.js:2953-3007`):
  - A `double` or `int`: TimeClip. NaN and ±Infinity give an invalid result.
  - A `DateTime`: its `millisecondsSinceEpoch`.
  - `undefined`: `jsDateNow()`, as `moment(undefined)` reads the current time.
  - `null` and `''`: invalid.
  - A `String`, in the order of `configFromString` (`moment.js:2525-2552`):
    1. The ASP.NET form `/Date(n)/` (`:2346`, `:2526-2530`).
    2. ISO 8601: the code-unit scanner of fact 5 with the checks of `checkOverflow`. A wall time
       without an offset goes through `fromWall`.
    3. RFC 2822 (`:2348-2360`, `:2496-2523`).
    4. Any other string is invalid (row `adapt-date-parse-fallback`). moment calls
       `new Date(string)` there (`:2550-2560`). That result depends on the engine and on the zone
       of the process (fidelity `cmp.mjs`).
  - A `bool`: invalid. moment sends it to the same fallback, and `new Date('true')` is invalid.
  - A List and a Map: invalid (row `adapt-date-parse-fallback`). moment reads them as date fields
    (`:2994-3000`), and an empty one as the current time (`:3022-3027`).
- The scanner reads ISO 8601 strings without a format. It reads no moment token. Thus it is not
  the moment-compatible parser that Chart.js ADR 0009 §5 rejects.
- **The parse with a format.** The format is an ICU pattern (row `adapt-date-moment-format`).
  - The member calls `tryParse(value, true)` of the cached `DateFormat` of decision 6. The result
    gives the wall fields.
  - When the pattern has no year field, the year is the current year. When it has no year and no
    month field, the month is the current month. When it has no year, month and day field, the
    day is the current day. The current date is the local date of `jsDateNow()`: the date in the
    zone of the process, also when the default zone is UTC. This is the moment rule
    `create/from-array.js:79-81`: `currentDateArray` (`moment.js:2574-2585`) reads the local date
    when the moment is not in UTC mode, and `moment.tz.setDefault` does not set UTC mode. With
    `TZ=Pacific/Kiritimati`, `moment.now` at 2026-10-20T12:00Z and the default zone `Etc/UTC`,
    `moment('10:30', 'HH:mm')` gives 2026-10-21T10:30Z (the x64 Node.js v24.12.0, moment 2.29.4,
    moment-timezone 0.5.42, `fill_probe.cjs`). With `TZ=Pacific/Honolulu`, it gives
    2026-10-20T10:30Z.
  - The wall time goes through `fromWall`. A `null` result of `tryParse` gives `null`.
  - intl does not check the field ranges, and it does not skip text before the date. The row
    `adapt-date-moment-format` records these differences.
- The member ignores a format that is not a `String`, as `typeof format === 'string'` is false
  (`chartjs-adapter-moment.esm.js:31`).
- A duration string as an amount of `add` (`'P1D'`) is not a duration. `jsToNumber` gives NaN, thus
  0. moment reads it as a duration (`moment.js:3463-3533`). The row `adapt-date-parse-fallback`
  also records this difference.

### 6. `format` and `formats()`

- **`formats()`** returns one shared Map at each call, as the member returns `FORMATS`. The keys
  are in the order of `FORMATS`, `datetime` first:

  | Key | moment 1.0.1 | ICU pattern | Day period |
  |---|---|---|---|
  | `datetime` | `MMM D, YYYY, h:mm:ss a` | `MMM d, yyyy, h:mm:ss a` | lower case |
  | `millisecond` | `h:mm:ss.SSS a` | `h:mm:ss.SSS a` | lower case |
  | `second` | `h:mm:ss a` | `h:mm:ss a` | lower case |
  | `minute` | `h:mm a` | `h:mm a` | lower case |
  | `hour` | `hA` | `ha` | upper case |
  | `day` | `MMM D` | `MMM d` | - |
  | `week` | `ll` | `MMM d, yyyy` | - |
  | `month` | `MMM YYYY` | `MMM yyyy` | - |
  | `quarter` | `[Q]Q - YYYY` | `'Q'Q - yyyy` | - |
  | `year` | `YYYY` | `yyyy` | - |

  - `yyyy` pads the year to four digits, as `YYYY` does. ICU `y` gives `99` for the year 99.
  - `'Q'Q` is a literal `Q` and the quarter number, as `[Q]Q`. ICU `QQQ` is the localized quarter
    abbreviation.
- **The day period.** moment `a` gives `am` and `pm`. ICU `a` gives `AM` and `PM`, and intl has no
  lower-case token. When the format equals one of the four patterns with "lower case", the member
  writes the day period of the locale in lower case. Any other pattern keeps the ICU text. Thus
  the default labels have the moment text (fact 7), and the capacity label has the moment width
  (fact 8). The spec cases at `:305`, `:390` and `:490` need no skip for the text.
- **Compiled patterns.** A compiled pattern is a list of `DateFormat` parts and day-period
  fields. A static cache keeps the compiled patterns for each pair of locale and pattern. A new
  `DateFormat` for each call costs 4-18 times more (fact 7).
- **`format(time, format)`** (`chartjs-adapter-moment.esm.js:39-41`):
  - A time that the input rule makes invalid gives `'Invalid date'`. `undefined` gives the current
    time.
  - A `String` format is an ICU pattern.
  - A falsy format gives the moment ISO default text of fact 10. intl has no offset field. Thus
    `date_format.dart` writes this text itself.
  - Any other format throws a `TypeError`, as moment does (fact 10).
- **Locale.** The members use `Intl.getCurrentLocale()`, the analog of the global moment locale.
  They do not read the chart option `locale`, as chartjs-adapter-moment reads no option. When intl
  has no date data for that locale, the members use `en_US`. moment also uses `en` for a locale
  without data.
  - Before `initializeDateFormatting`, `Intl.verifiedLocale(locale, DateFormat.localeExists)`
    throws a `LocaleDataException` for each locale other than en_US. The check catches
    `Exception`, because intl does not export `LocaleDataException` (fact 9).
  - After `initializeDateFormatting`, the `DateFormat` constructor throws an `ArgumentError` for a
    locale that intl does not know, for example `xx`. The check gives an `onFailure` to
    `Intl.verifiedLocale`. Thus such a locale also gives `en_US`, and the members do not throw.
  - A static Map keeps the result for each locale string. The default `formats` member removes
    the locales without data from it once in each update. Thus a locale that gets its data later
    applies from the next update. moment also applies a locale that the page defines after a
    failed `moment.locale` call: `defineLocale` sets the global locale (`moment.js:2182-2185`).
    The x64 Node.js v24.12.0 with moment 2.29.4 gives `January` and the week start 0 after
    `moment.locale('zz')`, and the months of `zz` and the week start 1 after
    `moment.defineLocale('zz', ...)` (`locale_probe.cjs`). A locale without data costs one failed
    check in each update.
  - `lib/` does not import `package:intl/date_symbol_data_local.dart`. An app that wants another
    locale calls `initializeDateFormatting` in its own code.
  - A chart with `locale: 'de'` and no date data shows en_US date labels. It does not throw.

### 7. Now

- Every "now" of the date code reads `jsDateNow()`
  ([Chart.js ADR 0010](0010-js-numeric-semantics.md) §6): the port of `scale.time.js:342-343`,
  `undefined` in the input rule and the current date of the parse with a format.
- A spec in `testWidgets` reads the fake clock of the test. The spec value and the scale read the
  same day, as upstream reads the same day. None of the 86 cases of `scale.time.tests.js` needs
  `withClock`.
- A test of the current-date fill sets the time with `withClock` of `package:clock`. It runs on
  the VM only (decision 9).

### 8. Rows and spec skips

New rows of [differences.md](../differences.md):

| Row | Category | Marker | Difference |
|---|---|---|---|
| `adapt-date-default-adapter` | adapt | the initializer of `DateAdapterBase.prototype` | `prototype` starts with the default members. Chart.js alone throws the abstract error (`core.adapters.ts:65-67`). |
| `adapt-date-moment-format` | adapt | the patterns of `date_format.dart`, the parse with a format in `date_parse.dart` | ICU patterns in place of moment tokens. The parse with a format is intl `tryParse`. Also the skip reason of the moment-token cases. |
| `adapt-date-parse-fallback` | adapt | the end of the string grammars and the List and Map branch of `date_parse.dart` | A string that is not ASP.NET, ISO 8601 or RFC 2822, a List and a Map are invalid. A duration string is not an amount. |
| `adapt-time-generate-no-advance` | adapt | the loop of `generate` in `scale.time.dart` | A step that does not advance throws a `StateError`. Upstream loops without end. |
| `platform-date-local-offset` | platform | the platform read of `LocalZone` | The local offsets of the VM and dart2wasm outside ±2^31 s, and the whole-minute LMT offsets of dart2wasm. |

- The row `adapt-date-adapter-prototype` gets two sentences: the typed direct call of decision 1,
  and the initial members of the row `adapt-date-default-adapter`.
- The harness gets no row. The UTC line translates `test/index.js:23`. The defaults restore does
  not cover `DateAdapterBase.prototype`, as upstream restores nothing. A test that calls
  `override` or `setDefaultDateZone` restores the old state with `addTearDown`. The case of `:1283`
  removes its `init` at its end.

The skip reasons of the 86 cases of `scale.time.tests.js` (`scout/classify-time.verified.json`,
with the lower-case day period of decision 6):

| Reason | Count | Lines |
|---|---|---|
| run in phase 6 | 9 | `:51`, `:55`, `:61`, `:130`, `:137`, `:144`, `:151`, `:159`, `:1283` |
| `'diverges: adapt-date-moment-format'` | 59 | the cases with a moment parser, a moment display format, `format(mm, 'YYYY-MM')`, or the moment `FORMATS` values (`:1212`, `:1243`) |
| `'blocked: controller.line'` | 14 | `:84`, `:214`, `:221`, `:305`, `:368`, `:376`, `:390`, `:490`, `:522`, `:548`, `:639`, `:650`, `:744`, `:1308` |
| `'blocked: plugin.legend'` | 3 | `:267`, `:283`, `:287` |
| `'blocked: controller.bar'` | 1 | `:1125` |

- The case `:51` asserts that `window.moment` exists: the date library of the upstream test
  environment. The default adapter is the date library of the port. Thus the case asserts that
  `DateAdapterBase.prototype` holds the `parse` member of the default adapter.

- Each case with `'diverges: adapt-date-moment-format'` gets a port-only twin in
  `test/port/scales/scale.time_test.dart` when an ICU pattern reads the same input: `'YYYY'`
  becomes `'yyyy'`, `'MM/DD HH:mm'` becomes `'MM/dd HH:mm'`, `'YYYY-MM-DD'` becomes
  `'yyyy-MM-dd'`. The twin keeps every assertion of the case. intl has no token for `'WW'`. The
  twin of `:459` asserts the tick values in place of the labels. A twin that needs a module of a
  later phase lands with that module. Thus the 59 cases still test the ticks, the bounds and the
  offsets of the time scale.

### 9. Tests and reference values

- **Pure layer.** The five files are pure. Their tests use `package:test` and run on the VM,
  dart2js and dart2wasm (`test:web`). A test file of the web legs can import only `dart:`
  libraries, pure layers, `package:test` and `package:chartjs_test_utils/pure.dart`
  (`webTestLibraries` of `tool/src/lib_imports.dart`). Thus the cases that need `package:clock` or
  `Intl.defaultLocale` go to a file with `@TestOn('vm')`.
- **Reference values.** `tool/reference/date_adapter_reference.mjs` writes
  `test/port/core/date_adapter_reference.dart`.
  - It runs on the x64 Node.js v24.12.0 ([Chart.js ADR 0010](0010-js-numeric-semantics.md)). It
    stops on another engine.
  - It takes a `node_modules` folder as its argument, as `scale_chart_common.mjs` takes the dist
    path. It stops when the versions of moment, moment-timezone and chartjs-adapter-moment differ
    from the Chart.js lockfile. It records the sha256 of each loaded file.
  - It loads the files in the order of `karma.conf.cjs:106-111`. `_adapters` comes from the pinned
    `third_party/Chart.js/src/core/core.adapters.ts`, with its types stripped by Node.js. Then it
    calls `moment.tz.setDefault('Etc/UTC')`, as `test/index.js:23` does. The process runs with
    `TZ=UTC`, because the moment fallback and the current date read the process zone.
  - It writes about 30,000 UTC cases. The whole file stays below 0.53 MB, the size of
    `scale_reference.dart`. `--full` writes the corpus of 357,576 calls to a file outside the
    repository: the 356,180 calls of `startOf`, `endOf`, `add` and `diff` of fact 14, and 1,396
    parse calls. A Chart.js bump and a change of a `date_*.dart` file run the tests against it once.
  - For local time, it writes the offset changes of America/New_York, Australia/Lord_Howe and
    Pacific/Apia, and the moment results in each zone without a default zone. The tests run these
    cases through a table zone, a test-only `DateZone`. Thus the local cases give the same results
    on each machine and each compiler.
  - The generator runs moment. It copies no moment code into the repository. Thus it needs no
    notice, no `REUSE.toml` table and no `port_sources.yaml` entry.
- **Test files.**
  - `test/port/core/date_adapter_test.dart`: the reference cases of each member, the format texts,
    `formats()`, the `TypeError` cases, the parse with a format of a pattern with a year, and the
    groups of the rows.
  - `test/port/core/date_adapter_vm_test.dart` (`@TestOn('vm')`): the current-date fill and
    `undefined` with `withClock`, the locale fallback with `Intl.defaultLocale`, and the full
    corpus of `--full` when an environment variable names its file.
  - `test/port/core/date_zone_test.dart`: the table zone, and `LocalZone` against the local
    `DateTime` constructor in the zone of the machine.
  - `test/port/core/date_calendar_test.dart`: the integer calendar against `DateTime.utc` on
    random timestamps inside the range where `DateTime.utc` does not wrap.
  - `test/port/core/core.adapters_test.dart` clears the prototype in `setUp` and restores
    `dateAdapterMembers` in `tearDown`. A new group tests the typed direct call.
  - `test/port/js/js_number_test.dart` gets the `DateTime` case of `jsToNumber`.
  - `test/specs/scale.time_test.dart` (phase 6, `@TestOn('vm')`, `flutter_test`): the skip
    reasons of decision 8.

### 10. Performance

- Decisions 1, 3, 4, 5 and 6 take the faster form in each case. The four forms of the port-only
  files (the integer UTC calendar, the offset cache, the ISO scanner and the compiled patterns)
  change no upstream structure. Thus their microbenchmark gains count
  ([Chart.js ADR 0020](0020-registry-and-component-classes.md) §13).
- The calls of one update (fact 12):
  - 2 `parse` calls for each string label, and 1 for each string data value.
  - 1 `startOf` for each value with `time.round`.
  - 1 `add` and 1 `format` for each tick. 1 `add` for each major unit.
  - Up to about 10 `diff` calls, 1-3 `startOf` calls and 1 `format` of the capacity label.
  - 1 `format` for each data point of a `timeseries` scale with `ticks.source: 'data'`.
  - No call in `draw` and no call in an animation frame.
- Fact 13 gives one update with 20,000 ISO labels in UTC: 3.34 ms on AOT and 6.28 ms on dart2wasm
  with direct calls. The slowest plausible form costs 66.01 and 62.50 ms. The typed direct call
  adds about 40,000 times 7-8 ns on AOT and 21-26 ns on dart2wasm: about 0.3 ms and 0.9 ms. This is
  a calculation from fact 1, not a measurement.
- [performance.md](../performance.md) gets a section "Dates (phase 6)" with facts 1, 2, 3, 5, 7
  and 13, and the call counts of fact 12.

## Alternatives considered

The panel scores of the three drafts (judge, 1-10 for each priority of
[porting-flow.md](../porting-flow.md) §1.1, then the evidence):

| Draft | 1. Behavior | 2. Performance | 3. Structure | 4. Less code | Evidence |
|---|---|---|---|---|---|
| Performance (the base of this ADR) | 8 | 9.5 | 5 | 4 | 9 |
| Fidelity | 9 | 5.5 | 6 | 3 | 8.5 |
| Simplicity | 5 | 4.5 | 8.5 | 9 | 7 |

This ADR takes the performance draft. It takes the installation form of the simplicity draft and
the edge rules of the fidelity draft. These grafts cost no measured time. The alternatives below
give the priority that decides and its evidence.

**Installation and dispatch (decision 1).**

| Form | 1. Behavior | 2. Performance | 3. Structure | 4. Less code | Result |
|---|---|---|---|---|---|
| Prototype initializer, typed direct call | equal | +7-8 ns AOT, +21-26 ns wasm for each call | `_date` and its prototype as upstream | one hunk | chosen |
| Prototype initializer, `jsCall` | equal | +22-27 ns AOT, +64-70 ns wasm | as upstream | one hunk less | rejected by 2 |
| Subclass with a prototype check in 8 methods, `_date` = subclass | equal (passes `:1283`) | 0 extra | `_date` changes, 8 copies of the check | a class value more | rejected by 3: ADR 0020 §13 asks for a frame-figure gain, and no time-scale frame figure exists (Open 1) |
| Subclass without the check | `override` does not reach the defaults, `:1283` fails | 0 extra | `_date` changes | less | rejected by 1 |
| Default bodies in `DateAdapterBase` | equal | 0 extra | seven ported bodies change, the abstract error goes | less | rejected by 3 |
| An install call (`override` in the harness, the public entry and the gallery) | equal | as `jsCall` | `core.adapters.dart` unchanged, three call sites, two rows | more | rejected by 2 and 4 |
| A port of moment as a third-party source (20 files into one) | equal to the chosen rules | slower core forms: the regular-expression ISO parse 2.3 µs on AOT | two submodules, LICENSE, REUSE, `js-ok` markers under `check:js-semantics` | most | rejected by 2 and 4 |

**Zone (decision 3).**
- **UTC as the default.** Faster (fact 13: 3.34 against 5.67 ms). It changes the tick values of
  every app against each official adapter. Rejected by 1.
- **A zone option `adapters.date.zone`, a static `defaultZone` and a `zoneResolver`.**
  chartjs-adapter-moment reads no option, and the specs set a global. Two ways to select UTC are
  more code. The later zone package decides a scale option. Rejected by 4.
- **The process zone (`TZ=UTC`) for the specs.** Dart cannot set the zone of an isolate after
  its start. The web legs do not read `TZ`. Rejected by 1.
- **Local time on the `DateTime` constructor with no cache.** Less code. Fact 13: 31.30 against
  5.67 ms on AOT for 20,000 labels. Rejected by 2.
- **A cache by 15-minute slot.** Not exact (fact 3). Rejected by 1.
- **A cache on `timeZoneOffset`.** 7,368 mismatches on dart2js in Kyiv (fact 3). Rejected by 1.
- **An exact hour floor.** It differs from moment by 4-44 s in LMT eras (fact 4). Rejected by 1.
- **A cache for each adapter object.** It needs `this` in each member, thus the `jsCall` path.
  The reset in `formats` gives the same lifetime. Rejected by 2.

**Calendar (decision 4).**
- **The luxon or date-fns rules.** Other ticks than the spec environment (Context). Rejected by 1.
- **`DateTime.utc` and the `DateTime` fields.** Less code. 2.5-13 times slower (fact 2). It wraps
  far outside the range. Rejected by 2 and 1.
- **Keep the endless loop.** No hunk and less code. Priority 1 does not decide: no spec observes
  the hang, and the stop changes no result that upstream returns. Priority 2 decides: the hang
  stops every later frame of the app, because the loop runs on the UI isolate. It also stops the
  `flutter test` process. Upstream guards the same freeze at `:473-476`. Rejected by 2.
- **The literal stop test "`next` is not larger than `time`".** It throws on a NaN step, where
  upstream ends the loop. Rejected by 1.
- **The category `not-followed` for the stop.** `not-followed` is the row of a `diverged` commit
  of the upstream ledger (`upstream-tracking.md`, §3 legend). The stop is an `adapt` hunk.
- **A wall-time step for an amount of 0.** It gives the earlier instant in a repeated hour
  (fact 11). Rejected by 1.
- **A week start fixed on Sunday.** It differs from moment in a locale with another first day.
  Rejected by 1.
- **No alias table.** `time.unit: 'days'` gives a day step in moment. Without the table, `add`
  returns its input and the stop throws. Rejected by 1.

**Parse (decision 5).**
- **`DateTime.tryParse`.** Less code. It differs from moment for 1,703 of 7,221 strings, and it
  is 14-41 times slower than the scanner on AOT (fact 5). Rejected by 1 and 2.
- **The moment regular expressions.** 2.3 µs on AOT for each string, slower than `tryParse`
  (fidelity B4). Rejected by 2.
- **The year 1970 for a pattern without a year.** intl does this. moment uses the current date
  (fact 6). Rejected by 1.
- **`parseStrict` or `parseLoose`.** Both reject text after the date. moment accepts it when the
  parse is not strict. Rejected by 1.
- **The moment array and object forms.** More code for input forms that no spec and no time-scale
  path gives. Rejected by 4. The row `adapt-date-parse-fallback` records them.

**Format (decision 6).**
- **`AM` and `PM` in every pattern.** Less code. It changes the unit or the tick count in 101 of
  17,920 charts (fact 8). Three spec cases then skip. Rejected by 1.
- **Lower-case date symbols through `initializeDateFormattingCustom`.** The library is not on the
  `lib/` allowlist. It replaces the intl date data of the whole app. Rejected by 1.
- **`lib/` loads all locales** (`date_symbol_data_local.dart`, 346 KB of Dart source). A global
  change of the intl data. Rejected by 4.
- **The chart option `locale` through `Intl.verifiedLocale` and `DateFormat.localeExists`.** Both
  throw without date data (fact 9). A chart with `locale: 'de'` then throws in the time scale.
  Rejected by 1.
- **`QQQ - yyyy` for the quarter.** `QQQ` is localized. `[Q]Q` is a literal `Q` in every locale.
  Rejected by 1.
- **A new `DateFormat` for each call.** 4-18 times slower (fact 7). Rejected by 2.
- **A moment-token formatter and parser.** Chart.js ADR 0009 §5 rejects it.

**Types and harness (decisions 2 and 8).**
- **A `TimeUnit` enum or narrow parameter types.** The raw option values reach the members.
  `override` members get the same values from `DateAdapterBase`. No measured gain over one
  conversion at the entry. Rejected by 1 and 4.
- **A harness row for the UTC line, or a restore of `DateAdapterBase.prototype` after each
  test.** The line translates `test/index.js:23`. Upstream restores nothing. The only spec
  override (`:1283`) records its argument and changes no later case. Rejected by 4.

## Consequences

- The time scale works with no extra package. Its ticks equal the ticks of the spec environment in
  UTC for every input that moment parses without its engine fallback.
- `Chart._adapters._date` stays `DateAdapterBase.jsClass`. `override` keeps its upstream effect on
  each default member.
- An app gets local-time ticks by default. An app or a spec gets UTC with
  `setDefaultDateZone('Etc/UTC')`. A single chart cannot select another zone.
- In local time, dates outside 1901-12-13 to 2038-01-19 can get other offsets on the VM and
  dart2wasm than in JS. LMT offsets lose their seconds on dart2wasm. UTC gives the same ticks on
  every target.
- The offset cache depends on one fact of the tz data: no two offset changes of a zone less than
  48 h apart. An app that overrides `formats` keeps the cache until `setDefaultDateZone`.
- A format string has ICU tokens. Samples with moment tokens need ICU tokens. The default labels
  keep the moment text in en_US.
- An app gets other date locales only with its own `initializeDateFormatting` call. A call after
  the first chart applies from the next update.
- The default parse rejects the `new Date(string)` forms, moment arrays and moment objects.
- A step that does not advance throws a `StateError`. Upstream hangs.
- The phase 9 public entry exports `setDefaultDateZone` and `defaultDateZone`. Until then, an app
  imports `package:flutter_chartjs/src/core/date_adapter.dart`.
- The five port-only files hold about 1,400 lines of code (2,200 lines with the doc comments).
- [porting-flow.md](../porting-flow.md) §2.10 and §3, AGENTS.md (Layout, Tests and the generated
  files) and `tool/src/lib_imports.dart` follow this ADR.

## Open

1. **Frame figures.** The gallery Stress tab gets a time-scale scenario with ISO labels. Its
   frame figures on the Pixel 8a, macOS, Chrome with dart2wasm and the iPhone go to
   [performance.md](../performance.md). The calculation of decision 10 gives 0.3 ms on AOT and
   0.9 ms on dart2wasm for an update with 20,000 labels. When the frame figures show a gain of
   0.1 ms or more for direct calls, a new ADR decides between the typed direct call and a
   subclass.
2. **The 48-h fact** on the tz data of Android, iOS, Windows and the ICU data of Chrome. Phase 6
   runs the zone check there.
3. **The Windows VM** was not part of the local-time probes.
4. **The zone package.** Its ADR decides named zones, the rules after 2037 and a zone option for
   each scale.

## Evidence

All files are in the session scratchpad folder
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/ec6419b7-7aa8-4614-a4a2-aaaa926985fd/scratchpad/`.
The paths below are relative to it. Engines: Dart 3.12.2 (Flutter 3.44.9) on macos_arm64, intl
0.20.3, and the x64 Node.js v24.12.0 under Rosetta for the reference values and the web figures.
The fidelity draft took its web figures in an arm64 Node.js v24.12.0. This ADR uses only their
ratios. Packages: chart.js 4.5.1, chartjs-adapter-moment 1.0.1, moment 2.29.4 and moment-timezone
0.5.42 from npm (`scout/adapters/nm/node_modules/`).

- **Upstream** at v4.5.1:
  - `src/core/core.adapters.ts:12-67`, `:75-138`
  - `src/scales/scale.time.js:46-77`, `:114`, `:156-169`, `:266-288`, `:302-309`, `:342-343`,
    `:450-489`, `:495-544`, `:610-622`, `:651-665`
  - `src/scales/scale.timeseries.js:119-130`
  - `src/core/core.controller.js:367`, `src/core/core.datasetController.js:514`, `:981`
  - `test/index.js:21-23`, `test/specs/scale.time.tests.js:51-53`, `:1283-1306`
  - `karma.conf.cjs:106-111`, `package.json:89`, `:114`, `:115`, `pnpm-lock.yaml:48-50`,
    `:123-128`
  - `docs/axes/cartesian/time.md:7`, `:17`, `:31`, `:36`, `:94`, `:127`
- **chartjs-adapter-moment 1.0.1** `dist/chartjs-adapter-moment.esm.js:10-63`.
- **moment 2.29.4** `moment.js`: `absFloor` `:687-694`, the aliases `:633-644`, `setMonth`
  `:1097-1120`, the `en` week `:1420-1426`, `parseIsoWeekday` `:1522-1527`, `getSetDayOfWeek`
  `:1715-1726`, `getSetISODayOfWeek` `:1736-1750`, `cloneWithOffset` `:3277-3292`, `checkOverflow`
  `:2268`, `defineLocale` `:2141-2185`, the ISO grammar `:2314-2345`, the ASP.NET form `:2346`,
  RFC 2822 `:2348-2360`, `:2496-2523`, `configFromString` `:2525-2560`, `currentDateArray`
  `:2574-2585`, `prepareConfig` and `configFromInput` `:2953-3007`, `createLocalOrUTC`
  `:3009-3038`, `Duration` `:3157-3190`, `absRound` `:3196-3202`, `getDateOffset` `:3294-3298`,
  `createDuration` `:3463-3533`, `addSubtract` `:3605-3629`, `diff` and `monthDiff` `:3847-3921`,
  `defaultFormat` `:3923-3924`, `format` `:3988-3996`, `startOf` `:4094-4155`, `endOf`
  `:4157-4224`. `src/lib/create/from-array.js:79-81`.
- **The probes**: `fill_probe.cjs`, the local-date fill of decision 5 in two zones, and
  `locale_probe.cjs`, a moment locale that the page defines after a failed `moment.locale` call
  (decision 6).
- **The scout**: `scout/dates-evidence.md` §1-§6, `scout/classify-time.verified.json`,
  `scout/dates-probe/loop.mjs`, `scout/dates-probe/capacity.mjs`.
- **The judge**: `design/dates-judge.md`, `design/dates-judge/dispatch2-{aot,wasm,js}.txt`
  (`bench/bin/dispatch2.dart`), `calendar-aot.txt`, `zone_check-vm.txt`, `iso_check-rerun.txt`,
  `capacity_ampm2.txt` (`js/capacity_ampm2.mjs`), `count_labels.txt` (`js/count_labels.mjs`),
  `lmt_hour.txt` (`js/lmt_hour.mjs`), `locale_exists.txt` (`bench/bin/locale_exists.dart`).
- **The performance draft**: `design/dates-performance.md` (F1-F8),
  `design/dates-performance/bench/` and `out/`: `dispatch-*.txt`, `calendar-*.txt`, `tzgap.txt`,
  `zone-check-*.txt`, `zone-time-*.txt`, `gapfold.txt`, `parse-*.txt`, `iso_check.txt`,
  `parse_fmt-*.txt`, `format-*.txt`, `fmt_check.txt`, `scenario-*.txt`.
- **The fidelity draft**: `design/dates-fidelity.md`, `design/dates-fidelity/out/`:
  `check_utc_*.txt`, `check_local_*.txt`, `check_utc_datetime_utc_vm.txt`,
  `tryparse_vs_moment.txt`, `intl_parse.txt`, `intl_locale.txt`, `formats_check.txt`,
  `format_edges.txt`, `count_calls.txt`, `bench_table.txt`, and `ref/cmp.mjs`.
- **The simplicity draft**: `design/dates-simplicity.md`, `design/dates-simplicity/out/`:
  `compare_vm_dst_*.txt`, `probe_override.txt`, `probe_locale.txt`, `probe_range_vm.txt`,
  `bench_table.txt`.
