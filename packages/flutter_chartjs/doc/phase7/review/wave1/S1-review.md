# Wave 1, unit S1 (runtime): adversarial fidelity review

## Result

No blocking finding. The four functions (`jsGetKey`, `jsGetIndex` in `js_object.dart`,
`jsSetIndex` in `js_array.dart`, `jsLessThan` with `_toPrimitiveNumber` in `js_number.dart`) have
the text of PD §2.1-§2.3 and of Chart.js ADR 0027 §1, §3 and §7 without a change. `jsGet` does not
change (only the library doc changes). There is no `prefer-inline` pragma (ADR 0027 Open 5). The
headers on line 1 of the six files do not change. There are two findings of low severity. Neither
finding is a change of a ported line, and the DC callers of S2 cannot reach either one with chart
data today.

All paths are relative to `packages/flutter_chartjs/`. Probes are in
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/S1-review/`.
Each Node.js probe stops unless the Node.js is x64 (v24.12.0, `/usr/bin/arch -x86_64`).

## What the review checked

1. The lib diff against PD §2 and ADR 0027 §1, §3, §7: the same text. The bodies are the bodies
   of `_item`, `_getIndex`, `_setAt`, `_lessThan` and `_toPrimitive` of DC (DC:509-584). The only
   change is the `DateTime` branch of ADR 0027 §7.
2. `jsLessThan` against JavaScript `a < b`: a matrix of 30 values (`null`, `undefined`, the
   booleans, 0, -0, 1, NaN, infinity, 13 strings with `''`, `' '`, `'0x10'`, `'-0x10'`,
   `'Infinity'`, `' 1'`, `'﻿1'`, `'1e3'`, `'.5'`, 5 arrays, `{}` and two dates), 900
   pairs (`lt.mjs`, `lt.dart`). The Dart results and the x64 Node.js results are the same for all
   900 pairs.
3. The S1 probe `wave1/S1/probe.mjs` again in the x64 Node.js: each expected value of the new
   tests agrees with its output.
4. The test `jsGetIndex(list, -0)`: the literal `-0` in a `double` context is -0.0 on the VM
   (`lt.dart` prints `isNegative=true`). Thus the test pins -0.
5. The test `jsGetKey` of `_NullProxy`: `_NullProxy` has no keys, so a Map read gives
   `undefined`. The test expects Dart `null`. Thus the test fails if `jsGetKey` reads a
   `JsProxyObject` as a plain Map. The test pins the `is! JsProxyObject` test.
6. The `jsLessThan` tests pin the code unit order (`'\u{1F600}' < '￿'`) and the new
   `DateTime` branch (`DateTime.utc(10000)` against `DateTime.utc(9999)`; the old DC copy gives
   the reverse result).
7. The citations: the row `platform-array-events` exists in `doc/differences.md`. Chart.js
   ADR 0017 §8 (options and object values) gives the `jsGet` rule for an option or resolver read.

## Findings

### F1 (low, confirmed): `jsLessThan` on an array that contains a `DateTime`

- File: `lib/src/js/js_number.dart`, `_toPrimitiveNumber` (the branch `_ => jsToString(value)`).
- Claim: for an array, `ToPrimitive` gives the join of the `ToString` of its items. JavaScript
  gives the `Date.prototype.toString` text for a `Date` item. `jsToString` gives the Dart
  `DateTime.toString()` text. Thus a comparison of such an array with a string can give the
  other result.
- Probe (`edge.mjs`, `edge.dart`): `[new Date(0)] < 'A'` is `false` in the x64 Node.js
  (`'Thu Jan 01 1970 ...'`). `jsLessThan([DateTime(0 ms, UTC)], 'A')` is `true`
  (`'1970-01-01 00:00:00.000Z'`).
- Effect: the sorted test of DC `parse` (dc.js:473) only. A parsed index value is an array of
  dates only for a custom scale `parse`. No built-in scale gives one. The cause is in
  `jsToString` (it was there before S1; no `differences.md` row names the `DateTime` text). The
  `jsAdd` doc has the same cause (`date + ''`).
- Recommendation: no change in S1. The owner of `jsToString` adds a row (or a `DateTime` form)
  when a spec needs the text of a `Date`.

### F2 (low, confirmed): the doc of `jsSetIndex` does not name a negative index

- File: `lib/src/js/js_array.dart`, the doc of `jsSetIndex`. Also the `AGENTS.md` note that the
  S1 report gives to W1-int.
- Claim: the doc says that a write past the length throws a `RangeError`. A negative index also
  throws a `RangeError`. JavaScript does not throw there: `list[-1] = 9` writes the property
  `'-1'` and the length does not change.
- Probe (`edge.mjs`, `edge.dart`): Node.js gives "threw: false, length: 2". `jsSetIndex(l, -1,
  9.0)` throws a `RangeError`, length 2.
- Effect: none today. The only caller (DC `parse`, S2) gets `i + offset >= 0`. A negative
  `splice` start fails before that: `_insertElements` calls `insertAll(start.toInt(), ...)`,
  which throws a `RangeError` (DC:1820). The row `platform-array-events` names only a start past
  the length.
- Recommendation: W1-int (or the owner of the row) adds "or a negative index" to the doc of
  `jsSetIndex`, to the `AGENTS.md` note and to the row `platform-array-events` when S2 adds
  `jsSetIndex` to its code column.

## Not findings

- `jsGetKey` gives the `jsGet` result for each receiver: the inline Map branch is the `Map` case
  of `jsGet`, and `jsGet` tests `JsProxyObject` before `Map`, as `jsGetKey` does.
- `jsGetIndex` gives the `jsGet` result for a List: `jsToString` of a whole double below the
  length is the canonical array index. An index of 2^32 or more is past the length of each Dart
  List, so the array-index limit of ECMAScript does not change a result.
- The two differences from the text of PD §7.1 in the S1 report (the value 3.5 in the
  `List<int>` test and the String equality in `expectKey`) are correct. They do not weaken a
  claim of a test.
- This review started no `flutter_tester` process. It used `dart run` only.
