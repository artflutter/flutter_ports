# Chart.js ADR 0157: Bars on a time axis and floating bars on the fast paths

- Status: proposed
- Date: 2026-11-17
- Supersedes: of [Chart.js ADR 0068](0068-live-bar-update-layout.md), the sentence "Chart and the built-in
  category/linear scales provide ordinary-read capabilities" for the time and time series scales; of
  [Chart.js ADR 0069](0069-bulk-numeric-bar-updates.md), the words "finite numeric ParsedItems without custom or
  stack slots" for a floating bar; of [Chart.js ADR 0071](0071-numeric-category-parsing.md), the word "Floating
  bars" in the sentence "Floating bars, objects, coercible strings, custom lists and unusual labels keep ordinary
  parsing".
- Related: [Chart.js ADR 0034](0034-no-display-only-js-exactness.md),
  [Chart.js ADR 0149](0149-bar-chart-small-costs.md)

## Context

The bar campaign of 2026-11-16 found two bar charts that take none of the fast paths of a bar update.

- A bar chart on a time axis: the element update of 20,000 bars is 31.4 ms against 2.6 ms on a category axis on
  the macOS app. The bench update is 32.8 ms higher on the iPhone and 73.7 ms higher on the Pixel. With dart2js it
  is 92.5 ms against 8.5 ms.
- Floating bars (`[start, end]` items): the update of 20,000 bars is 22.8 ms higher on the iPhone, and 56.3 ms
  against 12.3 ms on the Pixel.

In the first case, only the exact category and linear scales opt into the proof of one dataset of Chart.js ADR
0068. Each bar on a time axis takes the upstream search of the axes and the stacks, and the bulk update of Chart.js
ADR 0069 declines. The proof reads only `chart`, `options` and `axis` of the index scale, and the bulk loop takes
the index pixels from the ruler.

In the second case, the native parse of Chart.js ADR 0071 takes numbers only, and the bulk update declines a parsed
item with a `_custom` slot.

## Decision

1. **The time axis.** The exact `TimeScale` and the exact `TimeSeriesScale` opt into the reads of the proof of one
   dataset, each with its own exact-class test. A subclass keeps its virtual reads. The proof, the ruler and the
   bulk loop do not change.
2. **The floating parse.** The native category parse of the bar controller also takes an item that is a pair of
   numbers: a native List with at least two items, and a number in each of the first two. The parse result of a
   number is the result of the exact linear scale: the number, or `null` when it is not finite. One function makes
   the `_custom` object of `parseFloatBar` from the two parse results, for the ordinary parse and for the native
   parse. The record gets its index key, its value key (`barEnd`) and `_custom`, in this order. An outer List of
   the classes `List<List<double>>`, `List<List<num>>` or `List<List<Object?>>`, and their nullable, empty and
   constant forms, also qualifies. Another item declines the whole range, as before. The base dataset controller
   (line and the other types) keeps the parse of before: it gives no floating bar function.
3. **The floating bulk update.** The bulk loop also takes a floating bar that is not stacked: a parsed item with a
   `_custom` of the class `FloatingBar` that holds no value that user code wrote by name, a finite `barStart` and
   `barEnd`, and a finite parsed value. The loop computes the start `0 + barStart`, the length
   `barEnd - barStart`, the base pixel of the start, and the head pixel of `start + length` when the bar is
   visible. The `base` option does not apply to such a bar, as upstream. The half grid line, the data visibility,
   the skipped edges and the writes are those of the other bars. Each other `_custom`, a foreign key and a NaN end
   decline the whole range before a write.
4. **The cache rule.** No form keeps a value from one update to the next. Each guard reads the live state at each
   update.

## Not taken

- A native parse of `DateTime` values on a time axis. On the VM the time parse is about a tenth of the update of a
  time chart after item 1. Its guard must prove the date adapter member, the `parser` option and the `round`
  option. It is not in this change.
- A faster qualification of a floating pair. The class test of each pair (`runtimeType`) is about half of the
  native floating parse on the VM. No cheaper test proves that a List runs no code of the program. The native
  floating parse is about a quarter faster than the ordinary parse on the VM, not more.
- The data-only update of a time axis (Chart.js ADR 0074). A time scale has no opt-in, and its ticks change with
  the data.
- Floating bars that are stacked, and the other forms of the bulk update that are not proven (several datasets,
  `flex`, `minBarLength`). Floating bars on a time axis take the bulk loop, but their parse stays the ordinary
  parse of objects: the native parse needs a category axis.

## Consequences

- The bench windows `time` and `floating` take the bulk loop. In a JIT run of the bench windows on the Mac (the
  host of `flutter test`, not a measurement), the update of 20,000 bars fell from 43 to 10 ms on a time axis and
  from 30 to 21 ms for floating bars. The draw of the same bars did not change when it ran alone.
- A pixel of a bar does not change: each value comes from the same arithmetic, in the same order.
- `test/port/controllers/bar_bulk_update_test.dart` had a case that a late floating value declines the bulk loop.
  That case now expects bulk writes and an equal result.

## Open

1. No run timed the production forms on a device.

## Tests

`test/port/controllers/bar_time_floating_test.dart` (twins: a subclass of `Chart` that takes the ordinary path
against the chart, for the parsed records, the scale ticks, the element properties and options, and the label of
each value), `test/port/controllers/bar_bulk_update_test.dart`.
