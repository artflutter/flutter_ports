# Chart.js ADR 0153: The skipNull search in one pass

- Status: proposed
- Date: 2026-11-17
- Supersedes: of [Chart.js ADR 0036](0036-parsed-data.md) §8, the item "the `skipNull` find" of
  the list "Ported literally, for step 7"; of [Chart.js ADR 0054](0054-typed-internal-model.md) §4, the sentence
  "No memo or cache of our own" for the index of item 3; of [Chart.js ADR 0149](0149-bar-chart-small-costs.md),
  the paragraph on the index of the `skipNull` search in "Not taken".
- Related: [Chart.js ADR 0068](0068-live-bar-update-layout.md), [Chart.js ADR 0034](0034-no-display-only-js-exactness.md)
- Figures: [performance.md](../performance.md) §78

## Context

With `skipNull`, each bar calls `_getStacks` two times, and each call searches the parsed list of each bar dataset
from its start (controller.bar.js:443-450). The count of the visits grows with the square of the bar count. On the
Pixel 8a a prototype that reads one item of a proven list took one full update of 3 x 5,000 bars from 2,991 to
115 ms. Chart.js ADR 0149 did not take it: code of the app that runs between two bars can replace an earlier slot
of a parsed List in place, and then the upstream search finds another item.

## Decision

1. **The index.** One `BarSkipNullIndex` lives for one `BarController.update` call of the exact `BarController` in
   the mode `none` or `reset`, on the exact category or linear scales. A proof walks a parsed list one time and
   proves it positional: item k is a `ParsedItem` whose index value is the number k, `null` or `undefined`. Then the
   first item with the number v can only be item v. Each later search reads item v and tests its length and its
   index value again. A search value that is no number and a list that is not positional take the upstream search.
2. **The test of the chart.** At its first proof the index tests, one time, each class, container and option scope
   that the bar loop reaches. The chart has the native contracts of Chart.js ADR 0068 and of the bulk update. The
   configuration root, the data object, the dataset List and each dataset object are native containers with no
   route on the keys that the loop reads. Each scale is the exact category or linear scale. Each controller of a
   dataset of the same type is the exact `BarController`, and its `grouped` is a scalar in native scopes. The keys
   of this controller that the loop reads, `indexAxis` of the chart, `stacked` of the index scale, `display` of the
   value scale and `display` and `lineWidth` of its cached grid view are scalars in native scopes. Each element is
   the exact `BarElement` in a native List. A failed test keeps the upstream search for the update. The test runs
   no code of the app.
3. **The proof of each list.** Last, the test of item 2 proves the parsed list of each dataset of the same type
   (the lists that the search reads, and the list of `getParsed` of this dataset) in one walk. A list declines the
   index for the update when a read of it can run code of the app: `parsing: false` (the list is the data List of
   the app), a List of another class, an item that is not a `ParsedItem` (for example a Map of the app, whose
   `operator []` runs in `parsedValueOf`), an item with a foreign field, or an index value or a value of the value
   axis that is not a number, `null` or `undefined` (`jsIsNaN` of an object calls its `toString`). A list that the
   walk did not see (a new list) gets a proof at its first search, and a failed proof ends the index. So, after the
   test, no read of a parsed list or of its items runs code of the app.
4. **The count of calls.** `jsCall` and `jsCall1` add one to `JsFunction.calls`. After the tests of items 2 and 3,
   code of the app can enter the bar loop only as a function value through the JS runtime, or as the resolve of the
   options of one bar. A new count ends the index. The resolve of the options of a bar ends it before the resolve.
   The upstream search then takes the rest of the update.
5. **The cache rule.** The index is a cache of our own. It is allowed because it lives inside one `update` call,
   it tests the list and the item at each read, and items 2 to 4 prove that no code writes a parsed List while it
   lives. It holds nothing after the call.

## Rejected

- A write count in `ParsedItem` (the patch of 2026-11-16): it sees a write of a value, not a new object in a slot
  of a plain List.
- A check of the prefix of the list at each search: it keeps the square of the bar count.
- A custom List class for the parsed list: each read of each chart would pay for it.

## Consequences

- A function value in one of the tested options, a custom Map or List, a custom class or a route keeps the
  upstream search for the whole update. So does a bar dataset with `parsing: false`, or a parsed item with an
  object value.
- A chart with an option function for each bar uses the index only until the first resolve of the options of a
  bar.
- A new read in the bar loop of a key, a container or a class that item 2 does not test must add it to the test.
  A new read of a parsed item must read a value that item 3 tests.
- The test of the chart walks each bar list one time for each controller. The walk replaces the first proof of
  each list, so the count of the visits does not change (§78).
- `jsCall` and `jsCall1` cost one more increment of a static field for each call.

## Tests

- `test/port/controllers/bar_skip_null_test.dart`
- `test/port/controllers/bar_skip_null_typed_test.dart`
