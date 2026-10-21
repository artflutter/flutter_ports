# ECharts ADR 0008: Dates, time zones, locales and formatting

- Status: proposed
- Date: 2026-10-21
- Gate: ECharts phase 4. Phase 4 ports `util/time.ts`, `util/format.ts`, `scale/Time.ts`,
  `core/locale.ts`, `i18n/langEN.ts` and `i18n/langZH.ts`. Phase 1 needs the subset of item 3
  before the gate. The pilot ports `parseDate` of `util/number.ts`. The zrender spec
  `core/util` makes a `new Date()` (`zrender@6.1.0 test/ut/spec/core/util.test.ts:74`).
- Related: [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (the shared
  runtime `js_semantics`, item 6),
  [Chart.js ADR 0024](../../../flutter_chartjs/doc/adr/0024-dates.md) (`DateTime` as a JS `Date`,
  `DateZone`, `LocalZone`, the table zone),
  [Chart.js ADR 0026](../../../flutter_chartjs/doc/adr/0026-number-formatting-on-package-intl.md)
  (package:intl, not used here),
  [Chart.js ADR 0032](../../../flutter_chartjs/doc/adr/0032-js-numeric-semantics.md) (accepted
  2026-10-21: §6 `jsDateNow`, the reference engine),
  [Chart.js ADR 0034](../../../flutter_chartjs/doc/adr/0034-no-display-only-js-exactness.md)
  (accepted 2026-10-21: the protected behavior),
  [D3 porting-flow.md](../../../flutter_d3_port/doc/porting-flow.md) §2.11 (the D3 dates and
  zones), [ECharts ADR 0002](0002-file-naming-and-layout.md) (paths and file names),
  [ECharts ADR 0003](0003-numbers-and-js-semantics.md) (number strings and new runtime symbols),
  [ECharts ADR 0004](0004-js-values-classes-and-options.md) (JS values, the two-state null rule),
  [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) (`setUpSpecs()`, the reference
  generators), [ECharts ADR 0007](0007-environment-host-and-input-events.md) (`env.domSupported`,
  the platform API, the host)

## Context

A Chart.js ADR binds only the Chart.js port. A D3 decision binds only the D3 port. This ADR states
the rules that the ECharts port takes from them. All paths are at the pins `echarts@6.1.0` and
`zrender@6.1.0` (ECharts ADR 0001).

### 1. `parseDate`

`parseDate` (`echarts@6.1.0 src/util/number.ts:502-561`) turns an option value into a `Date`.
- A `Date` passes through as the same object (`:503-505`).
- A string must match `TIME_REG` (`:484`). Else the result is `new Date(NaN)` (`:512-517`).
- A string without an offset gives the local `new Date(y, m, d, h, mi, s, ms)` (`:520-531`).
- A string with `Z` or an offset gives `new Date(Date.UTC(...))` (`:540-553`). The code subtracts
  only the hours of the offset (`:543`). The minutes of `+05:45` do not count.
- Only the first three digits of the fraction count (`:530`). Thus `'07.12'` gives 12 ms. The
  spec pins this (`test/ut/spec/util/number.test.ts:267-269`).
- `null` and `undefined` give `new Date(NaN)` (`:556-558`). Any other value gives
  `new Date(Math.round(value))` (`:560`).
- The empty string matches `TIME_REG`. Then `match[1]` is `undefined`. `+match[1]` gives NaN.
  Thus `parseDate('')` gives an Invalid Date. `+null` is 0 in JavaScript.
- The constructor and `Date.UTC` map the years 0-99 to 1900-1999. A probe gave
  `1950-01-01T00:00:00.000Z` for `parseDate('0050-01-01')` in `TZ=UTC` (Evidence).

Four sites test `instanceof Date`: `util/number.ts:503`, `util/format.ts:79`,
`util/model.ts:154` and `util/log.ts:88`. zrender `clone` and `merge` keep a `Date` as one value,
because `BUILTIN_OBJECT` lists `'Date'` (`zrender@6.1.0 src/core/util.ts:8-21`). The spec case
`built-in` asserts that `clone` returns the same `Date`
(`zrender test/ut/spec/core/util.test.ts:72-89`).

### 2. Dates change in place through setters chosen by name

- `util/time.ts:76-93` types the names of the 14 getters and 14 setters as string unions.
  `util/time.ts:471-525` has one function for each name, for example `monthSetterName(isUTC)`.
- `roundTime` (`util/time.ts:453-469`) falls through a `switch`. It calls `setMonth(0)`,
  `setDate(1)`, `setHours(0)` and the other setters in local or UTC form.
- The time scale steps a `Date` with `date[setMethodName](date[getMethodName]() + interval)`
  (`scale/Time.ts:523`, `:529`). `createEstimateNiceMultiple` calls a setter on `new Date(0)`
  (`scale/Time.ts:456-459`).
- `format` of `util/time.ts:277-329` reads the seven fields and `getDay` in local or UTC form
  (`:283-292`). `formatTime` of `util/format.ts:249-288` builds the names as
  `getUTC + 'FullYear'` (`:264-271`).
- `coord/calendar/Calendar.ts:173-181`, `:202-203` and `component/calendar/CalendarView.ts:152`
  read and change local fields only.
- An ECMAScript setter normalizes an overflow, for example `setUTCMonth(13)`. A local setter
  applies `LocalTime` and `UTC(t)` with the offsets of the zone. The results are tick values. Thus
  they are protected behavior (Chart.js ADR 0034).
- The understand notes (`jsvalues.md` §1) counted 134 getter and setter sites. A recount at the
  pin found 126 source lines in 5 files: `util/time.ts` 64, `scale/Time.ts` 40,
  `coord/calendar/Calendar.ts` 14, `util/format.ts` 7 and `CalendarView.ts` 1 (Evidence).

A Dart `DateTime` is immutable. It has no Invalid Date. Its constructor does not map the years
0-99. Chart.js ADR 0024 keeps `DateTime` for the date adapter, because moment works on copies.
ECharts needs a mutable `Date` with the ECMAScript field algorithms.

### 3. Local time is the default

- `useUTC: false` is the default (`model/globalDefault.ts:127`). The design note of
  `scale/Time.ts:30-38` gives the reason: a date string shows its own wall time.
- `scale/Time.ts:750-751` reads `new Date()`. For an empty extent, it takes the local midnight
  `new Date(d.getFullYear(), d.getMonth(), d.getDate())`.
- Clock reads: `platformApi.getTime` (`zrender src/core/platform.ts:105-108`),
  `getTime` of `zrender src/animation/Animation.ts:14-16`, `util/throttle.ts:60` and `:66`,
  `component/dataZoom/SliderZoomView.ts:994` and `:1014`, and the instance id bases of
  `core/echarts.ts:2911-2912`. `zrender src/contain/text.ts:64-75` measures its own run time.
  After slow runs, it stops the ASCII width cache. Thus a clock read changes behavior there.

### 4. The specs and their zone

- The jest config sets no `TZ` (`test/ut/jest.config.cjs:20-55`). The upstream CI runs
  `npm run test` on `ubuntu-latest` (`.github/workflows/ci.yml:61`, `:87`). That runner is in UTC.
- `util/time.test.ts:29-31` parses `'2003-04-09 01:04:02.300 UTC'` with V8 `Date.parse`. This
  form is not in the ISO grammar of ECMAScript. It is a legacy form of V8.
- `util/number.test.ts:251-290` compares `parseDate` results with `new Date('2012-03-04')` (UTC
  by ECMAScript) and with `new Date('2012-03-04T05:06:07')` (local by ECMAScript).
- The case `roundTime_locale` (`util/time.test.ts:159-177`) builds its expected values with
  `getISOTimezone()` (`:182-190`). That helper reads the offset at the epoch. In
  `America/Los_Angeles`, 1970-01-01 has the offset -08:00. The date 1986-10-06 has -07:00.
  A probe ran the case in four zones. It passed in `UTC`, `Asia/Shanghai` and `Europe/Berlin`. In
  `America/Los_Angeles`, the `month` and `day` steps differed by 3,600,000 ms (Evidence). Thus the
  upstream case is not zone-agnostic.
- `data/dataValueHelper.test.ts:229`, `:312` and `util/number.test.ts:1002` use
  `new Date(2012, 5, 12)`.

### 5. Number and date text

- `grep` finds no `Intl.` and no `toLocaleString` in `echarts src/` or `zrender src/`. The only
  `toLocale` call is `toLocaleLowerCase` on an SVG node name (`zrender src/tool/parseSVG.ts:613`).
  ECharts builds number and date text by hand.
- `addCommas` (`util/format.ts:32-39`) splits `x + ''` at `.`. It inserts commas with the lookahead
  regex `/(\d{1,3})(?=(?:\d{3})+(?!\d))/g` and the replacement `'$1,'` (`:37`).
- `formatTpl` and `formatTplSimple` (`util/format.ts:124-166`) call `String.prototype.replace`
  with a string pattern (`:140`, `:145-148`, `:160-163`). The replacement is a user value. JS
  applies `GetSubstitution` to a string replacement. Thus `$&`, `$$` and `` $` `` in a value
  change the result. A function value is called as a replacer. Another value goes through
  `ToString`, for example `undefined` gives `'undefined'`.
- `format` of `util/time.ts:304-328` applies 24 global regex replacements. Their replacements are
  numbers through `+ ''`, padded numbers and the month and day names of the locale.
- `formatTime` (`util/format.ts:273-285`) replaces the first match of a string pattern with a
  number. `pad` (`util/time.ts:238-241`) calls `'0000'.substr(0, len - str.length)`. A negative
  length gives `''`.

### 6. Locales

- `src/i18n/` has 27 locale files with 3,901 lines: AR, CS, DE, EL, EN, ES, FA, FI, FR, HU, IT,
  JA, KO, LV, nb-NO, NL, PL, PT-br, RO, RU, SI, SV, TH, TR, UK, VI and ZH. Each file has the
  18-line ASF license block and `export default` of a plain object (`src/i18n/langEN.ts:1-24`).
- The root folder `i18n/` has 55 files: 54 build outputs and `package.json`.
  `build/build-i18n.js:75-107` wraps each source in UMD twice. `lang<X>.js` calls
  `echarts.registerLocale`. `lang<X>-obj.js` exports the object.
- `core/locale.ts:39-44` computes `SYSTEM_LANG` once, at load. With `env.domSupported` false, it
  is `EN`. Else it reads `document.documentElement.lang` or `navigator.language`. It gives `ZH`
  when the upper-case tag contains `ZH` (`:43`). Else it gives `EN`.
- `registerLocale` (`:46-50`) upper-cases the key. It keeps the object and a `Model`.
  `createLocaleObject` (`:56-69`) clones `EN` and `ZH`. It merges other locales with `EN`.
  `:80-81` registers `EN` and `ZH` at load.
- `core/echarts.ts:586` gives `createLocaleObject(opts.locale || SYSTEM_LANG)` to each instance.
  `util/time.ts:297` falls back to `SYSTEM_LANG` when the caller gives no locale. Two callers give
  none: `util/format.ts:83` and `component/tooltip/TooltipView.ts:854`.
- `model/globalDefault.ts:23-27` reads `navigator.platform` at load. `:90` selects
  `'Microsoft YaHei'` for a platform that starts with `Win`, else `'sans-serif'`. Under jsdom, the
  value is `''`.

### 7. Precedents

- **Chart.js ADR 0024.** A `DateTime` is the JS `Date` value of the adapter (§2). Local time goes
  through `DateZone` with `offsetAt(t)` and `fromWall(w)` (§3). `LocalZone` reads the platform and
  caches one interval of instants. `setDefaultDateZone` selects local time or UTC. The tests run
  local cases through a table zone, a test-only `DateZone` on offset changes from the reference
  generator (§9). Every "now" reads `jsDateNow()` (§7).
- **D3 porting-flow.md §2.11.** D3 phase 3 proposes a port-only mutable `JsDate` with a `double`
  time value. Four D3 repositories run their tests with `TZ=America/Los_Angeles`. The D3 harness
  installs that zone on all legs. A probe found no local mean time on the VM and dart2wasm for
  dates before the first zone rule (D3 porting-flow.md §7, risk 4).
- **ADR 0008 item 6.** New runtime code goes into new files of `js_semantics`. A file with a
  Chart.js copy changes in both copies in one commit. `LocalZone` lives in
  `packages/flutter_chartjs/lib/src/core/date_zone.dart`. It is not in the 11 files of stage 1.

## Decision

### 1. Scope

This ADR decides the JS `Date` runtime, the time zones, the date and number text and the locales
of the ECharts port. The number strings of `util/number.ts` follow ECharts ADR 0003. Clocks and
timers follow ECharts ADR 0007.

### 2. Placement

- `JsDate`, `jsDateUtc`, `JsDateField` and the zone code are generic JS runtime. D3 phase 3 needs
  the same runtime (D3 porting-flow.md §2.11). Thus they go into new files of `js_semantics` by
  ADR 0008 item 6:
  - `js_date_object.dart`: `JsDate`, `jsDateUtc`, `JsDateField` and `jsIsDate`.
  - `js_date_zone.dart`: a copy of `DateZone` and `LocalZone` of the Chart.js `date_zone.dart`,
    with the one function that it imports from `date_calendar.dart`.
  - `js_table_zone.dart`: `TableZone`, a `DateZone` on a list of offset changes.
  - `js_string.dart`: `jsStringReplace`, `jsRegExpReplace` and `jsSubstr`.
- `js_date_zone.dart` joins the drift check `check:js-runtime-drift` of ADR 0008 item 5.6. Its
  copy rule is the rule of the 11 stage 1 files. Stage 2 of ADR 0008 can move the Chart.js adapter
  onto the shared file. This ADR changes no Chart.js file.
- If ECharts phase 1 comes before stage 1 of ADR 0008, these files wait in
  `packages/flutter_echarts_port/lib/src/js/`. Stage 1 moves them. ECharts ADR 0003 states the
  same rule for the other new runtime symbols.

### 3. `JsDate`

`JsDate` is a mutable JS `Date`. Its time value is a `double`. NaN is the Invalid Date.

| JavaScript | Dart |
|---|---|
| `new Date()` | `JsDate.now()`. It reads `jsDateNow()` (Chart.js ADR 0032 §6) |
| `new Date(value)` with a number | `JsDate(value)`. TimeClip applies |
| `new Date(y, m, [d, h, mi, s, ms])` | `JsDate.local(y, m, [d, h, mi, s, ms])`. MakeFullYear maps 0-99 to 1900-1999 |
| `Date.UTC(y, [m, d, h, mi, s, ms])` | `jsDateUtc(y, [m, d, h, mi, s, ms])`. It returns a `double` |
| `d.getTime()`, `+d`, `d.valueOf()` | `d.getTime()`. `jsToNumber(d)` gives the same value |
| `d.getFullYear()` to `d.getMilliseconds()`, `d.getDay()` | the getters of the same names |
| `d.getUTCFullYear()` to `d.getUTCMilliseconds()`, `d.getUTCDay()` | the getters of the same names |
| `d.setFullYear(...)` to `d.setMilliseconds(...)` | the setters of the same names, with the optional arguments of ECMAScript |
| `d.setUTCFullYear(...)` to `d.setUTCMilliseconds(...)` | the setters of the same names |
| `d.setTime(t)` | `d.setTime(t)` |
| `d.getTimezoneOffset()` | `d.getTimezoneOffset()`, in minutes, as ECMAScript gives it |
| `d.toISOString()` | `d.toISOString()`. It throws a `JsRangeError` for an Invalid Date |
| `String(d)`, `'' + d` | `jsToString(d)`. An Invalid Date gives `'Invalid Date'` |

- **Algorithms.** The methods follow ECMAScript 2025 §21.4: Day, TimeWithinDay, MakeTime, MakeDay,
  MakeDate, TimeClip, LocalTime and UTC(t). Each argument goes through `jsToNumber` and
  ToIntegerOrInfinity as ECMAScript says. A setter normalizes an overflow. A NaN or an infinite
  argument gives the Invalid Date. A setter returns the new time value.
- **Zone.** A local method calls the current zone of item 5. LocalTime is `t + offsetAt(t)`.
  UTC(t) is `fromWall(t)`. A repeated wall time gives the earlier instant. A skipped wall time
  uses the offset before the change.
- **Not in the API.** `Date.parse`, `toString` with a zone name, `toDateString`, `toUTCString` and
  the `toLocale*` methods. ECharts calls none of them. A later caller adds a method with its own
  tests.
- **Phase 1 subset.** Phase 1 adds `JsDate.now()`, `JsDate(value)`, `JsDate.local`, `jsDateUtc`,
  `getTime`, `jsToNumber` of a `JsDate`, `jsToString` of an Invalid Date and `jsIsDate`. The local
  constructor needs `fromWall`. Thus the zone files of item 2 also come in phase 1. Phase 4 adds
  the other methods.
- **Tests.** `js_semantics` gets the tests of each method on the VM, dart2js and dart2wasm. A
  reference generator writes the expected values from x64 Node.js v24.12.0 with `TZ=UTC`. It also
  writes the local cases of item 6.

### 4. `JsDateField`, `jsIsDate` and `DateTime` inputs

- **Names built at run time.** The 14 getter and 14 setter names become one Dart enum
  `JsDateField` with the values `fullYear`, `month`, `date`, `hours`, `minutes`, `seconds` and
  `milliseconds`. Its two methods are `get(JsDate d, {required bool utc})` and
  `set(JsDate d, num value, {required bool utc})`.
- The helpers of `util/time.ts:471-525` keep their names and their parameter. A helper returns a
  record of the field and the UTC flag in place of a string. The types `JSDateGetterNames` and
  `JSDateSetterNames` (`util/time.ts:76-93`) become this record type. Thus
  `date[monthSetterName(isUTC)](0)` becomes `monthSetterName(isUTC).set(date, 0)`.
- `formatTime` builds `getUTC + 'FullYear'` (`util/format.ts:264-271`). The port gives the field
  and the flag `getUTC != ''`. `getDay` and `getUTCDay` at `util/time.ts:287` call the two getters
  directly.
- These are translation rules. They need no `DIVERGES` marker and no row.
- **`jsIsDate(value)`.** It is true for a `JsDate` and for a `DateTime`. The four
  `instanceof Date` sites of Context §1 call it. `isBuiltInObject` of zrender `util.ts` is true for
  both (ECharts ADR 0004). Thus `clone` and `merge` keep a date as one value.
- **A user `DateTime`.** An option can hold a `DateTime` (Chart.js ADR 0024 §2). It counts as a JS
  `Date` with its `millisecondsSinceEpoch`. `parseDate` returns a new `JsDate` with that time
  value. A `JsDate` passes through as the same object, as upstream. No ECharts caller changes the
  result of `parseDate`. Thus the new object for a `DateTime` changes no result.

### 5. Zones

- **The current zone.** `js_date_zone.dart` has the getter `jsLocalZone` and the function
  `setJsLocalZone(DateZone? zone)`. `null` gives `LocalZone.instance`, the zone of the platform.
  The constant `utcZone` is a `DateZone` with the offset 0.
- **Apps.** An app gets `LocalZone.instance`, as a browser page gets the zone of the browser. The
  platform limits of `LocalZone` stay: the offsets outside ±2^31 s and the local mean time of the
  VM and dart2wasm (Chart.js ADR 0024 §3, row `platform-date-local-offset`). The shared row lives
  in `packages/js_semantics/doc/differences.md` (ADR 0008 item 4). The ECharts row
  `platform-date-local-offset` links it in phase 4.
- **The cache.** `LocalZone` keeps one interval of instants with one offset. Chart.js clears it
  once in each chart update. ECharts has no such hook in `src/`. The Flutter layer clears it
  before each update that it starts. ECharts ADR 0007 names the call site in phase 5.
- **`TableZone`.** It takes a name, the offset before the first change and a sorted list of
  instants with their new offsets. It gives the results of the ECMAScript rules for that table on
  every target. The tests install it with `setJsLocalZone`.
- **No named zones.** The port adds no `timezone` package. A later ADR can add one. It then
  implements `DateZone`.

### 6. The zones of the specs and the generators

- **Specs.** `setUpSpecs()` (ECharts ADR 0005) installs the zone of the harness variable
  `specDateZone`. Its default is `utcZone`, the zone of the upstream CI. The tool 5 run and the
  manifest counts use this zone.
- **The second zone.** Each spec file with local-time cases gets a zone twin in
  `test/port/<repo>/`, for example `test/port/echarts/util/time_los_angeles_test.dart`. The twin
  sets `specDateZone` to the `TableZone` of `America/Los_Angeles`. Then it calls the `main()` of
  the spec file. Thus the cases run in a zone with a negative offset and DST, on the VM, dart2js
  and dart2wasm. In phase 4, the twins are `util/number` and `util/time`. A later phase adds a twin
  for each spec file of a time axis.
- **The case `roundTime_locale`.** In a zone twin, it skips with
  `'n/a: the expected values take the offset of 1970-01-01 (time.test.ts:182-190)'`. Context §4
  shows that the upstream case also fails in that zone. The case runs in `Etc/UTC`.
- **Table data.** `tool/reference/zone_table_reference.mjs` of the ECharts package writes
  `test/support/zone_los_angeles.dart`. It writes the offset changes of `America/Los_Angeles` from
  1900 to 2100 from the ICU data of x64 Node.js v24.12.0. The tool records the ICU tz version.
- **Generators.** Each reference generator runs with `TZ=UTC` (ECharts ADR 0005). A generator of
  local-time cases also runs its cases with `TZ=America/Los_Angeles` in a second process. The Dart
  test runs these cases with the `TableZone`.

### 7. The translation of spec literals

V8 `Date.parse` accepts forms outside the ECMAScript grammar. Thus a spec literal becomes an
explicit constructor. These are translation rules of the spec harness. They need no row.

| Spec literal | Dart |
|---|---|
| `new Date('2012-03-04')`, a date-only ISO form | `JsDate(jsDateUtc(2012, 2, 4))` |
| `new Date('2012-03-04T05:06:07.123')`, an ISO date-time without an offset | `JsDate.local(2012, 2, 4, 5, 6, 7, 123)` |
| `new Date('2012-03-04T05:06:07.123Z')` | `JsDate(jsDateUtc(2012, 2, 4, 5, 6, 7, 123))` |
| `new Date('2003-04-09 01:04:02.300 UTC')`, the V8 legacy form | `JsDate(jsDateUtc(2003, 3, 9, 1, 4, 2, 300))` |
| `` new Date(`1986-10-06T11:25:45.678${timezoneStr}`) `` | `JsDate(jsDateUtc(1986, 9, 6, 11, 25, 45, 678) + offsetMinutes * 60000)` |
| `new Date(2012, 5, 12)` | `JsDate.local(2012, 5, 12)` |

- `getISOTimezone()` ports as a local helper of the spec. It reads `JsDate(0).getTimezoneOffset()`.
  The twin gets the offset of the table zone.
- A runtime `jsDateParse` comes only when a ported spec or a ported source parses a string at run
  time. At the pin, no source calls `Date.parse` or `new Date(string)`. If it comes, it accepts only
  the ISO grammar of ECMAScript.

### 8. `parseDate`

- `parseDate` ports line by line. `TIME_REG` is a Dart `RegExp` with the same source. Each
  `new Date(...)` becomes a `JsDate` constructor of item 3.
- A group that does not take part in the match is JS `undefined`. At `util/number.ts:524` and
  `:546`, `+match[1]` reaches ToNumber. The port writes `jsToNumber(match[1] ?? undefined)`. Thus
  `parseDate('')` gives the Invalid Date, as upstream. This is one more site of the `undefined`
  sentinel of ECharts ADR 0004: an absent value reaches ToNumber. The other groups read `|| 1` or
  `|| 0`. There `null` and `undefined` give the same result.
- `Math.round(value)` at `:560` becomes `jsRound(jsToNumber(value))` (Chart.js ADR 0032).
- A port-only test pins `parseDate('')`, `parseDate('0050-01-01')` and an offset with minutes.

### 9. Number and date text without package:intl

- ECharts uses no `Intl`. Thus the port needs no package:intl. Chart.js ADR 0026 does not apply.
  `js_intl.dart` stays in the Chart.js port (ADR 0008 item 3).
- Number text follows ECharts ADR 0003. `x + ''` is `jsNumberToString(x)`. A raw value goes
  through `jsToString(v)`.
- `addCommas` ports line by line. The regex replacement with the constant `'$1,'` becomes
  `replaceAllMapped` with `'${m[1]},'`. A constant replacement without a dynamic part translates
  to Dart `replaceAll`, `replaceFirst` or `replaceAllMapped` by hand.
- A `replace` with a dynamic replacement calls the runtime:
  - `jsStringReplace(s, pattern, replacement)`: a string pattern. It replaces the first match. A
    `String` replacement goes through `GetSubstitution`. A function value is called with the
    match, the position and the string. Another value goes through `jsToString`.
  - `jsRegExpReplace(s, regExp, replacement, {global})`: a regex pattern with the same rules.
    `global` stands for the flag `g`.
- `formatTpl`, `formatTplSimple` and `formatTime` call `jsStringReplace`. The 24 replacements of
  `util/time.ts:304-328` call `jsRegExpReplace`, because a locale name can contain `$`.
- `pad` calls `jsSubstr`, the Annex B `String.prototype.substr`. A negative length gives `''`.
- The date text of `format` and `leveledFormat` is behavior. The tick labels come from it
  (Chart.js ADR 0034, ECharts ADR 0003).

### 10. Locales

- **Data files.** Each `src/i18n/lang<X>.ts` ports to `lib/src/echarts/i18n/lang<X>.dart`
  (ECharts ADR 0002). The file has the rule-2 header, the `file_names` ignore line and the ASF
  license block. The default export becomes the top-level `final` Map `lang<X>`, an
  insertion-ordered `Map<String, Object?>` (ECharts ADR 0004). The names keep the hyphen:
  `langPT-br.dart` and `langnb-NO.dart` stay files. The Dart identifiers are `langPTbr` and
  `langnbNO`.
- **Phases.** `langEN` and `langZH` come in phase 4, because `core/locale.ts` imports them. The
  other 25 files come in phase 10. Until then, an app can call `registerLocale` with its own Map.
- **Build outputs.** The root `i18n/*.js` files get `n/a: build output of src/i18n`.
- **`core/locale.ts`** ports line by line. `SYSTEM_LANG` is a top-level `final`. With
  `env.domSupported` false (ECharts ADR 0007), it is `EN`. The DOM branch is dead code. It stays
  as a comment with the upstream line numbers.
- **The Flutter rule.** The Flutter layer gives `opts.locale` to `init` when the app gives no
  locale. It takes the tag of `Localizations.maybeLocaleOf(context)`, or of
  `PlatformDispatcher.locale`. It applies the rule of `core/locale.ts:43`: an upper-case tag that
  contains `ZH` gives `ZH`, else `EN`. The rule is port-only code in the Flutter layer. It needs no
  row.
- **Calls without a locale.** `util/format.ts:83` and `TooltipView.ts:854` read `SYSTEM_LANG`.
  They get `EN`, as upstream gets in a run without a DOM. The default pattern of
  `util/format.ts:69` has no month or day name.
- **The platform string.** `model/globalDefault.ts:23-27` becomes a read of a port-only settable
  string `navigatorPlatform` in `lib/src/js/js_navigator.dart`. Its default is `''`, the jsdom
  value. The specs keep `''`. The Flutter layer sets `'Win32'` on Windows before the first `init`.
  Thus the default font follows the upstream rule of `:90`. The read happens once, at the first use
  of `globalDefault`. The hunk replaces a host read. Its marker names the row
  `platform-navigator-platform` of `differences.md`. Phase 4 adds the row.

## Alternatives considered

- **An immutable `DateTime` with a copy at each setter.** Rejected. ECharts changes a `Date` in
  place (`scale/Time.ts:505-531`). A copy needs a rewrite of each call site. `DateTime` has no
  Invalid Date. It maps the years 0-99 to other dates than JavaScript.
- **package:intl `DateFormat` for the time templates.** Rejected. ECharts has its own template
  language and its own locale data. `DateFormat` gives ICU names and patterns, not the strings of
  `src/i18n/`. The spec `util/time` compares exact strings.
- **The `timezone` package now.** Rejected. It adds a dependency and a database to every app. The
  apps need only the platform zone. The tests need one fixed zone. A table from the reference
  engine gives it.
- **Generated JSON assets from the root `i18n/*.js` files.** Rejected. These files are build
  outputs. Rule 1 of AGENTS.md says to port from the source. Assets need an asset bundle. The
  pure layer has no asset bundle.
- **Force `useUTC: true` in the port.** Rejected. It changes the ticks and labels of every time
  axis. The upstream design note (`scale/Time.ts:30-38`) asks for local time.
- **One zone for the specs (`Etc/UTC` only).** Rejected. Then no spec runs the local setters with
  DST. The upstream CI runs in UTC only. Thus a defect of the local setters stays hidden.
- **A zone where every upstream case passes, for example `Europe/Berlin`.** Rejected. Its offset is
  positive. D3 uses `America/Los_Angeles`. One table zone can serve both ports.
- **`JsDate` in the ECharts package only.** Rejected. D3 phase 3 needs the same runtime. ADR 0008
  item 6 puts new generic runtime into `js_semantics`.
- **A port of V8 `Date.parse` for the spec literals.** Rejected. The legacy V8 grammar has no
  specification. Explicit constructors give the same time values.

## Consequences

- `js_semantics` gets four new files: `js_date_object.dart`, `js_date_zone.dart`,
  `js_table_zone.dart` and `js_string.dart`. The drift check gets one more pair.
- Phase 1 brings the `JsDate` subset and the zone files. This is earlier than the gate of the
  rest of this ADR.
- D3 phase 3 can use `JsDate` and `TableZone`. D3 porting-flow.md §2.11 then decides its zone
  source with this runtime in place. If D3 needs a time-zone database, its ADR adds it.
- The spec runs grow: each zone twin runs its spec file again in `America/Los_Angeles`.
- The ECharts `differences.md` gets the rows `platform-date-local-offset` and
  `platform-navigator-platform` in phase 4.
- An app with a Chinese locale gets `ZH` texts through `opts.locale`. The two callers without a
  locale stay `EN`.
- `lib/src/echarts/i18n/` holds 27 Dart data files after phase 10, about 3,900 lines.

## Evidence

- The recount of Context §2: `git ls-files src` at the pin, then a `grep -nE` for the getter and
  setter names, the `*GetterName` and `*SetterName` helpers, `MethodName]` and `getUTC +`. Comment
  lines were removed. Three false matches were removed: `data/DataDiffer.ts:281`, `:287` and
  `component/timeline/SliderTimelineView.ts:137`.
- The zone probe of Context §4 and the year probe of Context §1: a copy of `roundTime` and
  `getISOTimezone`, run with `TZ=UTC`, `TZ=America/Los_Angeles`, `TZ=Asia/Shanghai` and
  `TZ=Europe/Berlin` on Node.js v24.12.0 arm64 on 2026-10-21. The zone results depend on the ICU
  tz data, not on the CPU. The x64 generator of Decision §6 replaces them.
- The probe also gave `'ax{a}y'` for `'a{a}'.replace('{a}', 'x$&y')`, `'a5'` for
  `'ab'.replace('b', 5)` and `'aundefined'` for `'ab'.replace('b', undefined)`.
- `grep -rn "Intl\.\|toLocale"` over `echarts/src` and `zrender/src` at the pins: one hit,
  `zrender src/tool/parseSVG.ts:613`.
- The understand notes `jsvalues.md` (§2.7, §2.8, §4.7, §5.3), `dom.md` (§3.8) and `tests.md`
  (§1.2) of the phase 0 research.
