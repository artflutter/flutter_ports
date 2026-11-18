# Chart.js ADR 0175: Typed Dart forms in place of six JS helpers

- Status: accepted (2026-11-18): its code and the tests of section Tests pass.
- Date: 2026-11-18
- Related: [Chart.js ADR 0036](0036-parsed-data.md), [Chart.js ADR 0173](0173-option-function-types.md),
  [Chart.js ADR 0174](0174-canvas-option-values.md), [Chart.js ADR 0034](0034-no-display-only-js-exactness.md)

## Context

The JS runtime of `lib/src/js/` had six helpers with few callers: `jsSplice` (`Array.prototype.splice`),
`jsSetIndex` (the write `list[index] = value`), `jsHasOwn` and `jsDeleteKey` (`key in object` and `delete
object[key]`), `jsParseFloat` and `jsIsFinite`. Each caller already holds a typed List or a typed scope, except
`isNumber` of `helpers.math`, which takes any value.

## Decision

1. **Lists.** A removal is `removeRange` on the typed List, with the start and the end clamped to the List
   (`_removeRange` of `core.datasetController.dart`). `labels.removeAt(index)` and
   `metasets.removeRange(numData, numMeta)` need no clamp. A write of a parsed item appends at the length, else it
   writes the index:

   ```dart
   if (i == parsed.length) {
     parsed.add(value);
   } else {
     parsed[i] = value;
   }
   ```

2. **Keys.** The unregister of a component switches on the type of the scope: a typed scope deletes through its
   face, and a `Map` checks `containsKey` and calls `remove`.
3. **`isNumber` takes a `num` only.** `isNumber(n)` is `n is num && n.isFinite`. Upstream also takes a string that
   reads as a number, for example `'12'`. Data and options written as strings are no number in the port. Row
   `adapt-typed-number-test`.
4. **The runtime loses the six functions.** `js_semantics.dart` and the app library no longer export them. The
   tests that port an upstream `splice` call `spliceList` of `test/support/list_splice.dart`. The tests that read
   own keys call `hasOwnKey` and `deleteOwnKey` of `test/support/object_keys.dart`.

## Rejected

- Keep the string form of `isNumber`: the maintainer chose the typed form on 2026-11-18.

## Consequences

- A chart with data written as strings, for example `data: ['10', '20']`, has no points where upstream draws
  them. The spec expect `isNumber('123')` of `helpers.math.tests.js` gives false, with a `DIVERGES` marker.
- An add-on port that imported one of the six functions from `js_semantics.dart` does not compile. The zoom and
  sankey ports do not import them.

## Tests

- `test/specs/helpers.math_test.dart` (`isNumber`)
- The specs and tests that remove data and datasets: `core.datasetController_test.dart`,
  `core.controller_test.dart` and the controller reference harness.
- The full test list of AGENTS.md before a push.
