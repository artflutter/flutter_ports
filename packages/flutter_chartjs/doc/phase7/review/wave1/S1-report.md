# Wave 1, unit S1 (runtime): report

## Status

Done. The four runtime functions of PD §2 are in `lib/src/js/`. Their pure tests (PD §7.1) pass
on the VM, on dart2js and on dart2wasm. The full gate (work-plan §0 item 4) passes.

## Files that changed

All paths are relative to `packages/flutter_chartjs/`.

| File | Change |
|---|---|
| `lib/src/js/js_object.dart` | Adds `jsGetKey` and `jsGetIndex` after `jsGet` (and its helper `_index`), with the code and the docs of PD §2.1. The library doc names the two forms. `jsGet` does not change. No `prefer-inline` pragma. |
| `lib/src/js/js_array.dart` | Adds `jsSetIndex` after `JsProxyObject`, with the doc of PD §2.2. No new import. The library doc names it. |
| `lib/src/js/js_number.dart` | Adds `jsLessThan` and the private `_toPrimitiveNumber` after `jsAdd` (PD §2.3). A `DateTime` gives its time value. The library doc names it. |
| `test/port/js/js_object_test.dart` | Groups `jsGetKey` and `jsGetIndex`. New import: `createResolver` and `attachContext` of `helpers.config.dart` (a pure layer). |
| `test/port/js/js_array_test.dart` | Group `jsSetIndex`. |
| `test/port/js/js_number_test.dart` | Group `jsLessThan`. |
| `doc/phase7/review/wave1/S1-report.md` | This report (new). |

No other file changed. DC still has `_item`, `_getIndex`, `_setAt`, `_lessThan` and `_toPrimitive`.
Unit S2 removes them and calls the new functions (PD §3).

## Tests that were added

- `jsGetKey` (4 tests): a Map (`<String, Object?>` with a value, an absent key, a `null` value and
  an `undefined` value; a `Map<String, double>`; a Map with an inherited value); the `get` trap of
  a resolver of `createResolver` and of a context proxy of `attachContext` (a value, a `null`
  value, an absent key, the prefixed keys `_scopes`, `_cacheable`, `_context`, `_proxy`) and of a
  proxy with a Dart `null` result; a List (`'0'`, `'length'`, `'r'`), a String (`'0'`,
  `'length'`), `5.0`, `true`, a `JsClass` with an inherited static property; the `TypeError` of
  `null` and `undefined` in both functions. Each read also compares the result of `jsGetKey` with
  the result of `jsGet`.
- `jsGetIndex` (4 tests): a List with 0, 1, -0, 1.5, -1, NaN, infinity, -infinity, the length
  and an index past it; a List with `null` and `undefined` items; a `List<double>`; a Map with
  the keys `'1'`, `'1.5'` and `'0'` (index 1, 1.5, -0); a String with 0 and 3; `5.0`; the
  `TypeError` of `null` and `undefined`.
- `jsSetIndex` (4 tests): a write at the length appends (also into an empty List); a write below
  the length replaces; a write past the length throws a `RangeError` and does not change the
  List; a value of another type into a `List<int>` throws a `TypeError`, at the length and below
  it.
- `jsLessThan` (7 tests): 29 comparisons. Two strings (also a code unit order where the code
  point order differs), two numbers (NaN, -0), a string and a number, `null` and `undefined`,
  booleans, `DateTime` values (`DateTime.utc(10000)` against `DateTime.utc(9999)` in both orders,
  a `DateTime` against a number and against a string), arrays and a plain object.

Expected values: each expected value comes from `/usr/bin/arch -x86_64` Node.js v24.12.0 (x64).
The resolver reads come from `_createResolver` and `_attachContext` of the build of Chart.js at
the pin (`dist/helpers.js`, commit `7169e65147a47f3720957a6f156a33c838ab9f57`). The probe script:
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/S1/probe.mjs`.
It stops unless Node.js is x64 v24.12.0. Each test value agrees with its output.

Two differences from the text of PD §7.1:
1. `jsSetIndex`: the test writes `3.5`, not a whole double, into the `List<int>`. On dart2js a
   whole double is an `int`, and the write then does not throw. The test comment says so.
2. `jsGetKey`: the identity check of the two results accepts two equal Strings. On dart2wasm,
   each read of a String index (`'ab'['0']`) makes a new String, so `identical` is false there.

## Checks

| Command | Result |
|---|---|
| `dart analyze --fatal-infos packages/flutter_chartjs/lib/src/js packages/flutter_chartjs/test/port/js` | No issues |
| `dart test -p vm -p chrome -c kernel -c dart2js -c dart2wasm test/port/js/js_object_test.dart test/port/js/js_array_test.dart test/port/js/js_number_test.dart` (in `packages/flutter_chartjs`) | +573, all passed |
| `dart run melos run format:check` | 369 files, 0 changed |
| `dart run melos run analyze` | No issues (covers `apps/chartjs_gallery`) |
| `dart run melos run test --no-select` | All passed: chartjs_gallery +95; chartjs_test_utils +139; flutter_chartjs +5342 ~473; flutter_d3_port +38 |
| `dart run melos run test:web` | All passed: flutter_chartjs +6942 ~204; chartjs_test_utils +98 |
| `dart run melos run test:cases` | passed, 37 files, 0 errors, 0 warnings (total 1036 cases: 383 passed, 0 failed, 411 skipped, 242 missing in the 17 files without Dart tests) |
| `dart run melos run check:port` | lib-imports 292 files, headers 329 files, js-semantics 115 files, port:next 195 files, parity 163 files: all passed, 0 errors, 0 warnings |

## Doc notes for W1-int

These are the notes of PD §8 that concern S1. W1-int adds them with the notes of S2 and S3.

`AGENTS.md`, the list "The JS runtime in `lib/src/js/`", after `jsAdd`:

> `jsGetKey` (the read `object[key]` of a parsed item, a data item or a stack object, with the
> `jsGet` result; a read of a resolver stays `jsGet`), `jsGetIndex` (the read `object[index]`
> with a number index: a List gives the item at a whole index in range, else `undefined`),
> `jsSetIndex` (the write `list[index] = value`: a write at the length appends, a write past it
> throws a `RangeError`) and `jsLessThan` (the operator `a < b` on raw values: two strings
> compare by their code units, a `DateTime` by its time value) (Chart.js ADR 0027, proposed).

`doc/porting-flow.md`: no note from S1. The notes of PD §8.2 (the one-read line of §1.1 and the
section §2.20) come from the ADR, not from this unit.

`doc/performance.md`: no figure from S1. S1 did not measure. The index read figures of §13.1
come from ADR 0027 (Benchmarks).

`doc/differences.md`, row `platform-array-events`: the code column adds
`lib/src/js/js_array.dart` `jsSetIndex`. Add it when S2 removes `_setAt` of DC, because the doc
of `jsSetIndex` names the row.

`doc/status.yaml`: no change from S1. The `lib/src/js/` files have no status row of their own.
The sentence of PD §8.5 for `core.datasetController` comes after S2 and S3.

## Open items

1. S2 removes the private copies `_item`, `_getIndex`, `_setAt`, `_lessThan` and `_toPrimitive`
   of DC, `_item` of `core.controller.dart`, and switches `helpers.config.dart:920` (PD §3). Until
   then the runtime and DC have two copies of the same bodies. The DC copy `_toPrimitive` gives
   the `toString()` of a `DateTime`. Thus `DateTime.utc(10000) < DateTime.utc(9999)` is true in
   DC today and false in `jsLessThan` and in JavaScript (ADR 0027 §7).
2. Work-plan §0 item 5: S1 changes `lib/`, so it gets an adversarial fidelity reviewer. No reviewer
   ran in this unit.
3. A `flutter_tester` process (pid 67820) ran before this unit started. Its parent is pid 1, and
   its package config is in the scratchpad of another session
   (`ec6419b7-…/scratchpad/review/tests-judge/probe`). This unit did not start it and did not
   kill it. This unit leaves no `flutter_tester` process of its own.
4. `doc/phase7-progress.md` has a change in the working tree that this unit did not make (the
   phase lead owns the file).

## Fixes

The findings are in `S1-review.md`. Both are "confirmed". The probes of this section are in
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/S1-fix/`
(`date.mjs`, `date.dart`, the outputs `date_node.txt` and `date_dart.txt`). `date.mjs` stops
unless Node.js is x64 v24.12.0.

### F1: `jsLessThan` on an array that contains a `DateTime`

Fix: the cause is the `DateTime` text of `jsToString` (`lib/src/js/js_number.dart`, a file of the
S1 row). `jsToString` gets a `DateTime` branch, the private `_dateToString`. It gives the text of
`Date.prototype.toString` (ECMAScript 21.4.4.41): the local time in the zone of the platform, as
the engine uses its local zone, for example `'Thu Jan 01 1970 00:00:00 GMT+0000'`. The year has 4
digits or more, with `-` for a negative year (`'-0001'`, `'10000'`). The seconds of an offset
fall away, as in V8. The text of `jsLessThan` (ADR 0027 §7) does not change: its array branch
calls `jsToString`, so `[new Date(0)] < 'A'` is now false, as in JavaScript. The doc of
`_toPrimitiveNumber` says so.

The zone name: V8 adds the long ICU name, for example `' (Coordinated Universal Time)'`.
ECMAScript lets the implementation give an empty name, and no Dart platform gives the ICU name.
Thus the text ends after the offset. The name changes only the text, not the order of two texts
with the same time and offset (Chart.js ADR 0009). The doc of `_dateToString` says so. There is
no `DIVERGES` marker, because `doc/differences.md` is not in the S1 row (see "Open items of the
fixes").

The same fix also reaches the other `jsToString` callers with a `DateTime`: `jsAdd(date, '')`
gives `String(date)`, and `jsParseFloat(date)` gives NaN (before: 1970 from the Dart text
`'1970-01-01 ...'`). A `DateTime` label of a category scale now gets the JS text in its tick
label. The category reference cases with Date labels use the tick callback `indexLabel`, so no
reference value changes.

Probe: `date.mjs` in the x64 Node.js and `date.dart` on the VM, each under `TZ=UTC`,
`Europe/Berlin`, `Asia/Kolkata`, `America/St_Johns` and `Europe/Amsterdam`, for 14 times
(from -8.64e15 to 8.64e15 ms) and the comparisons. Without the zone name, the texts are the same
for each time from 1901-12-14 in each zone, and for each time in UTC. The comparisons
`[d0] < 'A'` (false), `[d1e12] < [d0]` (true), `[d0] < [d1e12]` (false), `d0 + ''` and
`parseFloat(d0)` (NaN) are the same in each zone. The other texts (before 1901-12-14 in the four
zones that are not UTC) differ by the local mean time offset: the VM takes a substitute year
there (differences.md row `platform-date-local-offset`).

New tests (`test/port/js/js_number_test.dart`):
- `jsLessThan`, `compares an array of dates through the Date text`: the three comparisons above.
  Each result is the same in each zone of the probe.
- `jsToString`, group `a DateTime`:
  - `gives the Date.prototype.toString text in UTC`: nine texts of the probe with `TZ=UTC`, for a
    local and a UTC `DateTime`. The test skips when the platform zone has an offset other than 0
    at one of the times ("the platform zone is not UTC"). The CI runners are in UTC.
  - `gives the local time of the platform zone`: in each zone, the text has the form of
    `ToDateString`, and its fields are the fields of `toLocal()`.
  - `reaches the arrays, the operator + and parseFloat`: `String([d, null, d])`, `d + ''` and
    `parseFloat(d)`.

### F2: the doc of `jsSetIndex` does not name a negative index

Fix: the doc of `jsSetIndex` (`lib/src/js/js_array.dart`) now says that a negative index writes
a property in JavaScript (`list[-1] = v` gives the key `'-1'`, and the length does not change),
and that Dart throws a `RangeError` for it as for an index past the length. It also says that
`parse` never gives a negative index, and that a negative splice start fails at the insert of the
elements, before the write. The code does not change.

New test (`test/port/js/js_array_test.dart`): `jsSetIndex`, `throws a RangeError for a negative
index`: the `RangeError`, and the List does not change.

The notes for W1-int change (they replace the notes in "Doc notes for W1-int" above):

`AGENTS.md`, the list "The JS runtime in `lib/src/js/`", after `jsAdd`:

> `jsGetKey` (the read `object[key]` of a parsed item, a data item or a stack object, with the
> `jsGet` result; a read of a resolver stays `jsGet`), `jsGetIndex` (the read `object[index]`
> with a number index: a List gives the item at a whole index in range, else `undefined`),
> `jsSetIndex` (the write `list[index] = value`: a write at the length appends, a write past it
> or at a negative index throws a `RangeError`) and `jsLessThan` (the operator `a < b` on raw
> values: two strings compare by their code units, a `DateTime` by its time value) (Chart.js
> ADR 0027, proposed). `jsToString` of a `DateTime` gives the `Date.prototype.toString` text in
> the platform zone, without the zone name.

`doc/differences.md`, row `platform-array-events`: the code column adds
`lib/src/js/js_array.dart` `jsSetIndex`, and the text adds: "`jsSetIndex` also throws a
`RangeError` for a negative index, where JavaScript writes the property `'-1'`. No caller gives
a negative index: a negative splice start fails before the write, at the insert of the
elements." Add it when S2 removes `_setAt` of DC.

### Open items of the fixes

1. The zone name of `Date.prototype.toString` (F1) has no row in `doc/differences.md`. That file
   is not in the S1 row. W1-int or the phase lead decides on a row, for example
   `js-semantics-date-zone-name` (`lib/src/js/js_number.dart` `_dateToString`), with a
   `DIVERGES` marker at the `DateTime` branch of `jsToString`.
2. Before the fix, the DC copy `_toPrimitive` (DC:583) also gave the Dart text. S2 removes it and
   calls `jsLessThan` (PD §3), so DC then gets the fixed text.

### Checks of the fixes

| Command | Result |
|---|---|
| `dart analyze --fatal-infos packages/flutter_chartjs/lib/src/js packages/flutter_chartjs/test/port/js` | No issues |
| `dart format packages/flutter_chartjs/lib/src/js packages/flutter_chartjs/test/port/js` | 32 files, 1 changed (a test line), then no change |
| `dart test -p vm -p chrome -c kernel -c dart2js -c dart2wasm` with the three S1 test files (host zone CEST) | +585 ~3, all passed (the UTC text test skips on each of the three platforms) |
| The same command with `TZ=UTC` | +588, all passed (no skip) |
| `TZ=America/St_Johns dart test -p vm` with the three S1 test files | +195 ~1, all passed |
| `flutter test test/port/scales test/port/core/date_adapter_test.dart test/port/core/date_adapter_vm_test.dart test/port/core/date_zone_test.dart test/port/core/core.ticks_test.dart test/specs/core.ticks_test.dart test/specs/helpers.core_test.dart test/port/js` (the other `jsToString` paths with dates) | +1163 ~61, all passed |
| `dart run melos run check:js-semantics` | passed, 115 files, 0 errors, 0 warnings |
| `dart run melos run check:lib-imports` | passed, 292 files, 0 errors, 0 warnings |
| `dart run melos run check:headers` | passed, 329 files, 0 errors, 0 warnings |

The full gate did not run in the fixes (this prompt does not ask for it). The fixes started no
`flutter_tester` process that stays. The process 67820 of the other session is still there. The
fixes did not start it and did not kill it.
