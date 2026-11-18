# Chart.js ADR 0176: The number text and the string ids

- Status: accepted (2026-11-18): its code and the tests of section Tests pass.
- Date: 2026-11-18
- Supersedes: of [Chart.js ADR 0146](0146-js-numeric-semantics.md), in §7 the bullet of `'' + n` and the bullets of
  `parseFloat` and `isFinite`, and in §10 the bullet of the `jsNumberToString` test.
- Related: [Chart.js ADR 0175](0175-typed-list-and-key-helpers.md), [Chart.js ADR 0034](0034-no-display-only-js-exactness.md)

## Context

The JS runtime of `lib/src/js/` had `jsNumberToString`, the text of a number as V8 writes it. Its argument is a `num`:
it is a format of a number, not a coercion of an untyped value. `jsToString` is the coercion `ToString` of any
value. Some of its callers already held a `String` or gave the text only to an error message.

## Decision

1. **`numberString` replaces `jsNumberToString`.** The port-only `lib/src/helpers/number_string.dart` has
   `String numberString(num x)`, with the same text: `'12'`, `'1e+21'`, and `'0'` for -0. `chartjs.dart` and the app
   library export it. The JS runtime no longer has the function. `check:js-semantics` names `numberString` in its
   advice for a number in a string.

   ```dart
   // Before
   instances[jsNumberToString(id)] = this;
   // After
   instances[numberString(id)] = this;
   ```

2. **A scale id is a `String`.** `DatasetController.getScaleForId` takes a `String?`. A number id does not find the
   scale of its text. The decimation plugin reads `chart.scales[meta.xAxisID]`.
3. **An event name and an update mode are a `String`.** An item of `options.events` that is not a `String` adds no
   listener. An update mode that is not a `String` is no mode, and the controller update takes `'default'`.
4. **A dataset id of another type is no id in a release build.** `metaStringOf` stops a debug build, as before, and
   gives Dart `null` in a release build. Row `adapt-native-chart-meta`.
5. **`jsToString` stays** for the labels, the legend and tooltip text, the stack keys of the data, the element type
   ids, the chart type and the error messages that show a value of the user, as upstream writes them. These values
   are still untyped. The options step and the data step give them types.

Row `adapt-string-ids`.

## Rejected

- Use `numberText` of `flutter_kurkle_color_port`: it keeps the `.0` of an integral value at 2^53 or more on the VM.

## Consequences

- An app or a plugin that calls `getScaleForId` with a number does not compile.
- An add-on port that imported `jsNumberToString` from `js_semantics.dart` imports `numberString` from
  `chartjs.dart`. The sankey port, the gallery and the harness do this.

## Tests

- `test/port/helpers/number_string_test.dart`: 10,000 inputs against `String(x)` of Node.js v24.22.1 on arm64, and
  the notation boundaries.
- `test/tool/check_js_semantics_test.dart`: the advice names `numberString`.
- The full test list of AGENTS.md before a push.
