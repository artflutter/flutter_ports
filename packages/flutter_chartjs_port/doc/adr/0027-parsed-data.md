# Chart.js ADR 0027: Parsed data in the controllers

- Status: accepted (2026-10-21)
- Superseded by: [Chart.js ADR 0036](0036-parsed-data.md) (2026-10-21)
- Date: 2026-10-21
- Full text: `git show 2ee913263ba0fad4d08b0e9744c3a86575286268:packages/flutter_chartjs_port/doc/adr/0027-parsed-data.md`

## Summary

The controllers read a parsed item, a data item and a stack object with `jsGetKey`, which gives the `jsGet` result.
The JS runtime got `jsGetIndex`, `jsSetIndex` and `jsLessThan`.
DC got `stacksOf` for the `_stacks` of an item that is not a Map.
A raw option value stayed `Object?` until its upstream operator.
A hot loop read each key of a parsed item once in a pass: the 3-read form of the line and scatter loops.

## Where each part went

Chart.js ADR 0036 keeps the section numbers of this ADR.

- §1 (`jsGetKey`, the parsed read): [Chart.js ADR 0036](0036-parsed-data.md) §1, then
  [Chart.js ADR 0054](0054-typed-internal-model.md) §8.
- §2 (the readers of DC): [Chart.js ADR 0036](0036-parsed-data.md) §2, then
  [Chart.js ADR 0054](0054-typed-internal-model.md) §8.
- §3 (`jsGetIndex` and `jsSetIndex`): [Chart.js ADR 0036](0036-parsed-data.md) §3.
- §4 (the parsing keys and `_parsedValue`): [Chart.js ADR 0036](0036-parsed-data.md) §4.
- §5 (`parsing: false`, the data shapes and `stacksOf`): [Chart.js ADR 0036](0036-parsed-data.md) §5.
- §6 (the writes by name): [Chart.js ADR 0036](0036-parsed-data.md) §6, then
  [Chart.js ADR 0054](0054-typed-internal-model.md) §9.
- §7 (the raw option values, `jsLessThan` and the `Date` text): [Chart.js ADR 0036](0036-parsed-data.md) §7,
  then [Chart.js ADR 0054](0054-typed-internal-model.md) §6. Chart.js ADR 0036 §7 adds the V8 zone name.
- §8 (the hot loops and the one-read rule): [Chart.js ADR 0036](0036-parsed-data.md) §8.
- §8 (the read `prevParsed[iAxis]` at each pass): [Chart.js ADR 0109](0109-previous-x-of-the-gap-test.md).
- §9 (the tests, the rows and the records): [Chart.js ADR 0036](0036-parsed-data.md) §9.
- Open 1 (the measurement of `stacksOf`): closed by [Chart.js ADR 0036](0036-parsed-data.md), Context.
  Figures: performance.md §13.1.
- Open 2 (the early cast of DC `parseObjectData`): closed by [Chart.js ADR 0036](0036-parsed-data.md) §4.
- Open 3 (the step 7 list): [Chart.js ADR 0036](0036-parsed-data.md) Open 1.
- Open 4 (the `prevIValue` local): closed by [Chart.js ADR 0036](0036-parsed-data.md) §8.
  The guarded 2-read form: [Chart.js ADR 0109](0109-previous-x-of-the-gap-test.md).
- Open 5 (`prefer-inline` on `jsGetKey`): [Chart.js ADR 0036](0036-parsed-data.md) Open 2.
