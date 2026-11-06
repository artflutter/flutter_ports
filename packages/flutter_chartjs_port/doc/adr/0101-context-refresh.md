# Chart.js ADR 0101: One write of a data context, and one refresh less in a scatter update

- Status: accepted
- Date: 2026-11-06
- Related: Chart.js ADRs 0054, 0079, 0080, 0082, 0087, 0093, 0094; `differences.md` rows
  `adapt-context-bulk-refresh` and `adapt-scatter-overflow-refresh`.
- Measurements: performance.md §65.

## Context

An indexed color needs the context of its item, so upstream refreshes the context of each item in each
resolve. In one update of a scatter chart that is three passes: `getMaxOverflow` before the layout,
`updateElements`, and `getMaxOverflow` in `_update`. A bubble chart has a fourth, in its parse. The
size does not need the context: Chart.js ADR 0094 takes one size from one plan result. The refresh
stays because a resolve is what writes the contexts, and user code can read them.

Each refresh went through six setters with their own test of the membership mask, two generic reads of
a list, one box for the index, and a capability read that its loop had just made.

## Decision

Results, key order, user-callback order and count, thrown errors and pixels stay those of the ordinary
path.

### One write

`ScriptableContext.refresh` writes `parsed`, `raw`, `dataIndex`, `index`, `active` and `mode` with one
test of the mask. With the six keys present, no write adds a key, so their order cannot be observed.
Otherwise the setters run in the order of `getContext`, so that a key that user code deleted goes back
to the end of the own keys, in that order (Chart.js ADR 0080). An index with the same value keeps its
box; -0 is another value.

`getContext` keeps its write of `parsed` before its read of `raw`, because that read can run user code
for a custom dataset. `refreshAfterParsed` is the same write of the other five keys. It keeps a `delete`
of `parsed` in that read. Each caller of `getContext` gains: the arc loops, a resolve, a scan.

`NativePointContextReader` reads its lists directly: `prepare` proved their classes, and an index past
the end gives `undefined`, as `getParsed` and `jsGetIndex` do. `readQualified` serves a loop that has
read the capability of the element at this iteration, so that no second read runs. The scatter, line and
bubble loops use it, and so does the bulk bar loop with indexed colors. The element class does not
matter there: the writes are those of `getContext` on a data context.

This supersedes these statements: "the original typed setter sequence" of the reader in Chart.js ADR 0082,
"Context setters remain the ordinary setters" in Chart.js ADR 0079, and "Setter order and values do not
change" in Chart.js ADR 0094.

The arc loops keep `getContext` here. Their lines belong to another change, and the bulk write already
reaches them.

### One refresh less

The refresh in the overflow pass before the layout stays. A layout runs tick callbacks and layout hooks,
and they can read any context. Proving a layout free of user code would need each scale, box and plugin
of the config: this is not simple, so nothing is deferred across it.

The refresh of `updateElements` is left out in one window. In the mode `none`, the prepared loop of the
exact scatter controller leaves the refresh of each point to the overflow pass of the same `update_`,
which writes each of these contexts again. For that loop this supersedes "No context writes are skipped"
of Chart.js ADR 0080 and, of Chart.js ADR 0094, "A prepared update or overflow loop refreshes each context" and "Each point keeps its
`as types.PointElement` cast and its capability read".
The rest of those ADRs stays. The window needs:

- a color plan (Chart.js ADR 0079), so that no point of the loop runs user code while the plan holds;
- a loop over the whole dataset. Then each point has qualified as native at its own iteration or, for
  the first two, when the window opens, so that the pass has no cast to throw and no `size` of a user;
- no `showLine`: with it, the overflow pass reads only two points;
- a scalar raw `clip` in native scopes, because its read stands between the loop and the pass;
- the caller. `update_` names its `update`, and that `update` names its loop. Each takes the name at its
  first statement, so that a public call of `update` or `updateElements`, also from user code inside
  another update, keeps each write. No overflow pass follows a public call.
- plain `radius`, `hoverRadius` and `borderWidth` in a result of the plan (`NativePointSizeFields.of`), and a
  context reader of the mode `default` (`prepareNativePointContexts`). Without them the loop keeps each write.

A plan that ends in the window, at a custom or an active point or a foreign value, first writes the
waiting contexts, in their order, with the values of the mode `none`. Thus code that runs after that
point reads what it reads in the ordinary path.

With the window open, the overflow pass writes each context in descending order, and takes its size from
one plan result, as Chart.js ADR 0094 does. It reads no options object and calls no `size`, also for
the two items that it would resolve ordinarily, because the plan holds and no user code ran. A context
that is missing takes `getContext`.

Each other loop keeps each write. That includes the bubble loop, where the same window exists: its
`updateElements` belongs to another change.

### Smaller items

- `ScriptableContext.hasIndexKey` replaces the name lookup of `jsHas('index')` in the indexed plan, which
  was up to eight string compares for each item.
- A loop-local color plan holds its one or two varying colors in fields, with no record and no iterator.
- `PointElement.supportsNativePointOptions` reads the bit of `typedWrites`, made once from
  `super.runtimeType`, in place of a `Type` compare at each read.
- The scatter loop tests `stacked` and `segment` once. `parsedValueOf` is inlined.
- `OptionView.rawOptionsAreScalar` (Chart.js ADR 0093) now reads the raw value with no sub resolver. Making
  one for an object value calls its `_fallback`, which can be a function of the user, ahead of its
  original point. An object still declines. This also corrects that order for the arc scans.

## Fallback

A user subclass of a controller, a chart, a Config or a point, a scriptable or indexed numeric option, a
foreign value, a custom list or Map, a custom scale, an active point, another mode, a part of a dataset,
`showLine`, a function or object `clip`, a custom Map scope and a public call take the ordinary writes at
their original point.

## Differences

None that user code can read. The rows name the changed hunks.

## Validation

`test/port/helpers/context_refresh_test.dart` compares the bulk writes with the setters for each subset of
deleted keys. `test/port/controllers/context_refresh_twins_test.dart` compares scatter, bubble, line, bar,
doughnut, pie and polar area with a trivial controller subclass, with indexed colors: the contexts of all
items with their key order at each hook and each tick callback, and the results, across new data Lists and
length changes, with two datasets, and with deletion and reinsertion of keys by user code at the hooks. The
scatter group reads the contexts from a scriptable `clip`, a user point, an active point with a hover
callback, a Map item, a public `update` or `updateElements` in the middle of a loop, and a partial range. It
counts the context reads of a probe to show that the window opens, and that a user `getContext` still gets
each refresh. Removing any guard of the window fails a test of this group, except `start != 0`, which the
test of the count already implies. The observation test keeps its digests.
