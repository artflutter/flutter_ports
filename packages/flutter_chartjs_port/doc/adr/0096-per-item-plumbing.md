# Chart.js ADR 0096: Direct reads and one growth in the per-item plumbing

- Status: accepted
- Date: 2026-11-06
- Related: Chart.js ADRs 0054, 0071, 0087; `differences.md` rows `adapt-clear-stacks-guard` and
  `adapt-parse-presize`.
- Measurements: performance.md §65.

## Context

Each chart type reads the same few values for each item of each update: `chart.data`,
`data.datasets[index]`, `dataset.data[index]` and the parsed item. A typed config kept these reads on
the face by name: `jsGet`, `OptionScope.jsRead`, a lookup of the name in the table of keys, and the
cell. A data point of `parsing: false` read its `x` and `y` through a switch on the name. The parse
functions grew two Lists by doubling, where upstream writes `new Array(count)`, and each parsed item
appended its two keys one by one. A new data List walked the old items for stacks that they cannot
have.

## Decision

The values and the order of the reads stay. Only the way to the value changes.

1. `OptionScope.readKey(OptionKey)` is `jsRead` by key. A scope without routes gives the own cell of
   a declared key. An absent key, an extra and a routed key take `lookup`, as `jsRead` does.
   `readOption` takes this path for a typed scope. A Map and each other value still read by name, and
   an absent key still gives `undefined`.
2. `Config.data`, `DatasetController.getDataset` and the read of `dataset.data` in `getContext` use
   `readOption`. Thus `Chart._datasets` and `Chart.getDatasetMeta` use it too. `getContext` calls no
   closure for `raw`. `getParsed` and the item reads of the parse functions have a List by their
   static type, so they skip the type test of `jsGetIndex`.
3. `parsedValueOf` gives the field of a `TypedDataItem` for the axis `x` or `y`, as `dataItemValue`
   does. The axis `r`, a user axis name and each other class read by name.
4. `stacksOf` tests the present bit of `_stacks` of a `ParsedItem` first. An absent key gives
   `undefined`, as the read by name does.
5. `parsePrimitiveData`, `parseArrayData`, `parseObjectData` and `tryParseNumericCategories` make
   their growable List at its final length, with `List.generate`. This is `new Array(count)`. A count
   below 0 stays an empty range.
6. `ParsedItem.of` writes the fields of the axes `x`, `y` and `r` at once, with the key order of the
   two writes. Two equal keys are one key with the second value. A user axis name goes by name,
   because it can name a field.
7. The typed writes of a `ScriptableContext` test the present bit before the call of `_claim`.
8. `jsTruthy` compares a `double` with a `double`, and `getContext` reads `active ?? false` from its
   `bool?`.

Two hunks do not translate upstream.

### `clearStacks` skips a walk that finds nothing (`adapt-clear-stacks-guard`)

The function returns before its walk when all of these hold:

- no item has an entry in `_objectStacks`, the `Expando` of the `_stacks` of an item without a
  property Map. A file-level flag records the first entry and stays true;
- the items are a `List<TypedDataItem>`. Such an item holds stacks only through that `Expando`;
- the List is native (`nativeDataUpdateList`), so its iterator is not user code.

The walk would read each item and find no stacks. A plain List of points, a List of Maps, a custom
List and each List after the first entry keep the walk.

### `meta._parsed` grows once (`adapt-parse-presize`)

`parse` gives `meta._parsed` its final length before the copy of the items, when all of these hold:

- `start` is 0 and `count` is above 0 and at most the length of the parsed result. A shorter result
  throws in the loop with the same partial List;
- the parsed result is a native List, so that its reads are not user code;
- `meta._parsed` has the exact class of the List of `_dataCheck` and is empty.

The length is observable only by user code that runs in the loop. The only such code is the `toString`
of a value that `jsLessThan` compares. Thus `parse` gives the List its upstream length, and goes on
with growth by one, before the comparison of a value that is not a number or `null`.

`DoughnutController.parse` does the same for a native `List<num?>`, where the loop runs no user code.
Another `data` keeps the growth by one.

## Fallback

| Case | Path |
| --- | --- |
| A Map or another value as data, dataset or options | the read by name of `jsGet` |
| An absent key, an extra, a routed key of a scope | `lookup` |
| A `Chart` subclass with its own `data`, a controller subclass with its own `getDataset` or `getParsed` | their getter or method, at the same point |
| A data item that is not a `TypedDataItem`; the axis `r` or a user axis name | the read by name |
| A user axis name in `ParsedItem.of` | the write by name |
| A plain or custom List of items, or an entry in `_objectStacks` | the walk of `clearStacks` |
| A partial parse, a List with items, another List class, a short or custom result | the writes by index, with growth by one |
| A value that can run user code in the comparison | the upstream length before that code runs |

## Difference

No result, order, count of a user call, thrown error or pixel changes.

`OptionScope` is not public. A subclass that overrides `jsRead` also has to override `readKey`. The
test double of `tick_font_cache_test.dart` does so.

## Not done

- `elements` of `_resolveElementOptions` still reads by name: the resolution belongs to another
  change.
- The bar controller keeps its own parse Lists, and `parseObjectDataRadialScaleOf` keeps its growth.
  The bar path of primitive data goes through `tryParseNumericCategories`, and no benchmark reaches
  the radial object parse.

## Tests

`test/port/core/core.datasetController_plumbing_test.dart` compares the typed path with its Map twin,
and each presize with a List of another class, a custom List and the upstream length in a `toString`.
`test/port/core/core.datasetController_walk_test.dart` holds the state of the flag of `clearStacks`.
`test/port/options/read_key_test.dart` compares `readKey` with `jsRead` for each key of each kind, with
each state of a cell, an extra and a route. `test/port/options/parsed_test.dart` compares `ParsedItem.of`
with its two writes for each pair of axes.
