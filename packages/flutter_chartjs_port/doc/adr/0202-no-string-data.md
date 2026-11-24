# Chart.js ADR 0202: No string data

- Status: accepted (2026-11-24): its code is on main, and the gates of AGENTS.md pass.
- Date: 2026-11-24
- Supersedes: of [Chart.js ADR 0036](0036-parsed-data.md), §5 item 4 for a string `data`
- Related: [Chart.js ADR 0201](0201-remove-extra.md)

## Context

Upstream keeps a string `data` and reads it as an array of its characters
(`core.datasetController.js:386`). The port had `JsStringList` in `lib/src/js/js_array.dart` for this
case. The typed API cannot give a string `data`. Only a raw Map config of a test could reach the class.

## Decision

1. `JsStringList` is gone from the JS runtime.
2. A string `data` throws the `TypeError` of the cast in `_dataCheck`, as each other value that is neither
   a List nor an object does (row `adapt-no-string-data`).

   ```dart
   // Before: the points of [1, 2, 3]
   acquireChartRoot(_lines([{'data': '123'}]));
   // After: a TypeError
   acquireChartRoot(_lines([{'data': '123'}]));
   ```

## Consequences

- `lib/src/js/` has one name less. `_dataCheck` compares the data with `identical` only.
- A raw config with a string `data` fails at the chart creation.

## Tests

`test/port/controllers/controller.line_test.dart`, test `the string data '123' throws a TypeError`.
