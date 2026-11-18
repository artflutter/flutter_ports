# Chart.js ADR 0177: No number text helper

- Status: accepted (2026-11-18): its code and the tests of section Tests pass.
- Date: 2026-11-18
- Superseded in part by: [Chart.js ADR 0178](0178-no-js-semantics-check.md) (2026-11-18)
- Supersedes: of [Chart.js ADR 0176](0176-number-text-and-string-ids.md), item 1, the second bullet of section
  Consequences and the first two bullets of section Tests.
- Related: [Chart.js ADR 0034](0034-no-display-only-js-exactness.md), [Chart.js ADR 0146](0146-js-numeric-semantics.md)

## Context

Chart.js ADR 0176 moved the V8 text of a number from the JS runtime to the public helper `numberString`. The helper
still copied the JavaScript text, `12` and not `12.0`. Most of its callers did not need that text: an `int` key, an
error message or a debug text.

## Decision

1. **The port has no public number text helper.** `lib/src/helpers/number_string.dart` is removed, and `chartjs.dart`
   and the app library do not export a number text. The V8 text of a number is the private `_numberText` of
   `jsToString` in `lib/src/js/js_number.dart`. It goes with `jsToString`.
2. **A key of an index is the text of an `int`.** The keys of `jsOwnKeys` of a List or a string, the cached index
   keys of the dataset controller and the moved keys of `_moveNumericKeys` are the text of an `int`. `_moveNumericKeys` reads a key
   with `int.tryParse` and keeps a key that is no `int` text.
3. **A chart id is an `int`.** `uid()` gives an `int`, `Chart.id` is an `int`, and `Chart.instances` has the key
   `id.toString()`.
4. **A message has the Dart text of a number.** The errors of the time scale, the warning of the linear scale, the
   `toString` of `ElementPoint` and `SankeyDataPoint`, and the messages of `toBeChartOfSize` write a `double` with
   `toString()`, for example `100.0`. Each site has a `js-ok` comment.

   ```dart
   // Before
   '${numberString(min)} and ${numberString(max)} are too far '
   // After
   // js-ok: the text of an error.
   '$min and $max are too far '
   ```

5. **`jsToString` gives the text where it changes the chart.** The `values` tick formatter, the stack keys, the CSS
   size of the canvas, and the sankey tooltip label and flow label call `jsToString`. The index read of the
   resolver calls `jsGetIndex`.
6. **The gallery formats its readouts.** `jsNumberText` of `demo_common.dart` writes a whole number with no `.0`. It
   does not copy the V8 text.

Row `adapt-string-ids`.

## Rejected

- Keep `numberString` as a public helper: it is the JavaScript text under a new name.

## Consequences

- An app, a plugin or an add-on port that imported `numberString` uses `toString()` or its own format.
- A message that showed `100` shows `100.0` on the VM and with dart2wasm.
- Code that read `Chart.id` as a `double` reads an `int`.

## Tests

- `test/port/js/js_to_string_number_test.dart`: 10,000 inputs of `jsToString` against `String(x)` of Node.js v24.22.1
  on arm64, and the notation boundaries.
- `test/specs/core.helpers_test.dart`: `uid()` gives an `int`.
- `test/tool/check_js_semantics_test.dart`: the advice names no helper.
- The full test list of AGENTS.md before a push.
