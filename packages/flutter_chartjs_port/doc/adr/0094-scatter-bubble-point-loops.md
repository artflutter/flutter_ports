# Chart.js ADR 0094: One size in scatter overflow and native bubble loops

- Status: proposed
- Date: 2026-11-06
- Related: Chart.js ADRs 0054, 0074, 0078, 0079, 0082, 0087; `differences.md` rows
  `adapt-native-point-size`, `adapt-bubble-point-options` and `adapt-bubble-typed-radius`.
- Measurements: performance.md.

## Context

A live scatter chart computes the same point size for each point, twice in each update, from one
clone for each point. Its indexed loops refresh each context through the by-name reads of
`getContext`. A live bubble chart resolves its options four times for each item: in the parse, in the
two overflow passes and in the update.

## Decision

Each change below stays inside one synchronous loop. No plan survives a hook, a function or an update.
Results, key order, thrown errors, context writes, callback order and callback count stay those of the
ordinary path. A plan ends for good before user code can run, and the rest of the loop takes the
ordinary path from that item on. This ADR supersedes one sentence of Chart.js ADR 0079: a native point
in a prepared overflow loop no longer gets a call of `size` for each point. The rest of ADR 0079 stays.

### Scatter

- **One size in overflow.** `PointElement.size` reads three fields of the options. In a non-line
  `getMaxOverflow` of the exact controller, a native point takes one size, from the frozen
  `point-default` entry or from one result of the indexed color plan, where only colors vary. Each
  point keeps its `as types.PointElement` cast and its capability read, in descending order. Without
  an entry at the start, the first item resolves ordinarily, which makes the entry for constant
  options. Two ordinary resolves precede the one attempt at the indexed plan. An entry of plain
  options is required: an absent or foreign `radius`, `hoverRadius` or `borderWidth` keeps the options
  object and `size`.
- **The context reader.** A prepared update or overflow loop refreshes each context through
  `NativePointContextReader` (Chart.js ADR 0082), prepared by `prepareNativePointContexts`. It works
  for a raw and for a typed root. It reads the native data chain once, without routes. A missing
  context, or a context of another class, takes `getContext`. Setter order and values do not change.
- The update loop keeps a fresh options object for each point: upstream does not share them here.

### Bubble

- **Parse.** `valueOrDefault(item.r, this.resolveDataElementOptions(i).radius)` evaluates the resolve
  for each item, and an item with its own radius drops the result. Under the exact controller, a native
  point class and native data and parsed lists, the resolve stays out while it has no other effect:
  when the `point-default` entry exists it only copies the entry, and with a prepared indexed color
  plan it only refreshes the context of the item. That context refresh stays. An item with no radius
  keeps its resolve. A data item that is not native, or an `r` that is not a number, `null` or
  `undefined`, ends the skip before its read or conversion. `parsePrimitiveData` keeps its resolve,
  which gives its value. The `+=` of that resolve converts the `radius` of the entry or the `_custom`
  of the old parsed item, and the `toString` of an object is user code. Thus a `radius` of the entry
  that is not a primitive ends the skip, and so does a truthy old parsed item that is not native or
  has a `_custom` that is not a number or `undefined`. The old item is checked before the resolve of
  each item, also of an item with no radius. A primitive `radius`, for example a string, keeps the skip:
  its conversion runs no user code. A new `item[2]` of any kind also keeps it: the parse only stores the value.
- **Overflow.** Under the exact controller and a native point, `size` comes from the own radius of the
  item and the `hoverRadius` and `borderWidth` of the entry or of one plan result, through
  `nativePointSize`, the helper that `PointElement.size` also calls for plain options. The radius
  follows `controller.bubble.js:163-165`: `0 + custom`, or `0 + radius` for an `undefined` custom. A
  `_custom` that is not a number or `undefined`, or a parsed item that is not native, ends the plan.
  With indexed options, each point keeps its context refresh: the post-update pass is the last writer.
  Constant options write no context, here or in the ordinary path. An active point stays in this path:
  overflow reads the default options of each point in both.
- **Update.** The exact controller in the mode `none`, with no sharing, no stacks and native scales of
  the chart, prepares after two ordinary resolves: the copy of the `point-none` entry for constant
  options, else `prepareNativePointColors(controllerType: 'bubble')`. The prerequisites are
  `canPrepareNativePointUpdate`. The constant copy also needs a primitive `radius` of the entry,
  because the `+=` of an absent `_custom` converts it inside the loop; the indexed plan takes only a
  number. Each iteration checks its native point, activity, coordinates and `_custom` first. The
  radius stores of `resolveDataElementOptions` apply to a fresh copy for each point. A plan ends for
  good at a custom or an active point or a value with user code.
  Each result is fresh, unfrozen and has `$shared` false.

## Difference from upstream

`_customOf` reads the typed `r` of a `TypedDataItem` when `parsing` is `false`, because
`DataPoint.bubble` has a radius and no `_custom`. Thus `parsing: false` with `DataPoint.bubble` gives the
radius of the item, in the options, in the overflow and in `getLabelAndValue`. The same config with a
plain `{x, y, r}` object gives the default radius in upstream and in this port, because neither reads
`r` under `parsing: false`. `DataPoint` is a port-only type, so no upstream config changes result. A raw
Map still needs its own `_custom`. A `DataPoint` with no radius gives the default radius. The row
`adapt-bubble-typed-radius` pins this. The face of `DataPoint` does not answer `_custom`.

## Guards and fallback

The guards are the shared predicates of `point_options.dart` (Chart.js ADR 0087): `nativePointChart`,
`nativePointElement`, `nativePointClass`, `nativePointProjection`, `canPrepareNativePointUpdate`,
`NativePointCoordinates`, and `nativeDataUpdateList`. A guard stays at the observation point of the
ordinary read. A user subclass of a controller, a point or a chart, a custom `Config`, a scriptable
option, an indexed numeric option, a foreign value, a custom scale, a custom list or item, and another
mode take the ordinary path. A primitive `radius`, for example a string, is the one foreign value that
stays in the parse skip and in the constant copy, because its `+=` runs no user code. The constant paths read no chart, because their
ordinary resolve reads none.

`DatasetController.cachedPointOptions` exposes the entry to the two controllers. It is one line, in a
file outside this change, with the marker of its row.

## Validation

`test/port/controllers/scatter_point_size_test.dart` and `bubble_point_options_test.dart` compare each
fast path with a trivial user subclass, whose exact-class guard fails: geometry, complete options,
contexts, overflow, callback order and count. They cover indexed and constant colors, parsing on and
off, `DataPoint` and Map items, length changes, two datasets, a user `PointElement` with `size`, a
scriptable radius, an indexed radius and border width, active points, items with no radius, a null item,
foreign values, effectful items and custom scales. They count the conversions of a `radius` and of an old
`_custom` with a `toString` of the user, also one that changes the options in the middle of a loop. They
also run a queued animation on a platform that keeps the option. Counters on a test point show that the
fast path ran and that each guard falls back. `point_options_test.dart` compares `nativePointSize` with
both branches of `size` on a table of numbers, on all targets. The observation test keeps its digests.
