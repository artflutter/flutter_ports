# Chart.js ADR 0109: The previous x of the gap test in the line and scatter loops

- Status: accepted (2026-11-10). Its code and its tests pass. The porting lead accepted it by the
  maintainer's rule of 2026-10-31: a record is accepted when its code passes the tests.
- Date: 2026-11-10
- Supersedes, in part: [Chart.js ADR 0036](0036-parsed-data.md) §8, the bullet "A local lives only
  inside one pass. The read `prevParsed[iAxis]` stays a read at each pass", the 3-read form that §8
  adopts for `line.js:98-104` and `scatter.js:127-133`, and the rejected alternative "The 2-read
  form" of its Question 5. Section "What this supersedes" gives each part.
- Related: Chart.js ADRs 0034 (the protected behavior), 0036 (parsed data), 0054 (the typed
  internal model), 0074 (the native data contracts of `data_update.dart`), 0079 and 0080 (the
  prepared plans of indexed colors), 0087 (the shared point predicates), 0088 (the prepared line
  resolution), 0094 (the frozen entry of a scatter), 0101 (the context refresh);
  [differences.md](../differences.md) rows `adapt-native-gap-reads` and
  `adapt-loop-invariant-truthiness`.

## Context

`updateElements` of the line and scatter controllers sets `stop` of each point (`line.js:104`,
`scatter.js:133`):

```js
properties.stop = i > 0 && (Math.abs(parsed[iAxis] - prevParsed[iAxis])) > maxGapLength;
```

`maxGapLength` is `spanGaps` when `isNumber(spanGaps)`, else `Number.POSITIVE_INFINITY`: the
default, `true` and `false`. With +Infinity the test is false for every number, NaN included. With
a finite number, `prevParsed[iAxis]` is the x that the previous pass read as `parsed[iAxis]`, unless
code wrote it between the two reads.

Chart.js ADR 0036 §8 ports the five parsed reads of a pass as three (the 3-read form): `vValue` and
`iValue` of the current item, and the read `prevParsed[iAxis]` at each pass. It keeps that read
because a scriptable option of the previous pass can write `ctx.parsed`, the parsed item: then a
local of the previous pass holds an old value, and the segments change (the pin case `parsed: a
scriptable option writes ctx.parsed` of the controller references). It noted that a 2-read form
only on the paths without user code would need a measurement first.

The profiles of the zoom flows (Pixel 8a, iPhone 17 Pro, Mac; `.handover/zoom-perf/`) show
`parsedValueOf` under `updateElements` at 10.4-17.4% of an input step of 20000 points and 2.4-6.7%
at 1000 points. In the bench config (`parsing: false`, `{x, y}` Maps) each read is a Map lookup.
One of the three reads of a pass is the read of the gap test.

## Decision

Results, key order, user calls and their order and count, thrown errors and pixels stay those of
upstream.

### The parsed reads of a pass

This states the complete decision for the parsed reads of the loops of `line.js:76-121` and
`scatter.js:111-151`.

1. The one-read rule of Chart.js ADR 0036 §8 stays: `vValue` serves the reads of `parsed[vAxis]`
   (`line.js:99`, `:101`; `scatter.js:128`, `:130`), and `iValue` the reads of `parsed[iAxis]`
   (`line.js:100`, `:104`; `scatter.js:129`, `:133`).
2. By default a pass reads `prevParsed[iAxis]` in its gap test, inside the `i > 0 &&` operand, after
   the `ToNumber` of `iValue`, with the `prevParsed` of `line.js:87` and `scatter.js:122`
   (`getParsed(start - 1)` or `false`). This is the 3-read form.
3. When the guards below hold, a pass takes the held x: the `ToNumber` of the `iValue` of the
   previous pass of the same loop. Its gap test is `|x - heldX| > maxGapLength`. With
   `maxGapLength` +Infinity this is `false` for every x; with a finite `maxGapLength` it is the
   upstream comparison of the same two numbers. This is a 2-read form.

The held x is exact: between the read of `parsed[iAxis]` in the previous pass and the gap test, no
code can run user code, and no code of the port writes a parsed item. Thus `prevParsed[iAxis]`, the
key of the same item, still holds the value that the previous pass read. The read of a native item
has no effect and does not throw, and the `ToNumber` of a number has no effect and gives the held x.
Each `stop`, write, call and throw stays.

### The guards

A loop-wide part, `prepareNativeGapReads` of `point_option_preparation.dart`, before the loop:

- the exact controller (`super.runtimeType == LineController` or `ScatterController`): `getParsed`,
  `applyStack` and `getContext` are those of the port;
- a direct update (`chart._animationsDisabled || reset || mode === 'none'`): no `updateElement`, so
  no animation option resolves in the loop;
- `_stacked` and `segment` falsy: no `applyStack`, no read of `_dataset.data`;
- the axes `x` and `y`;
- a chart whose reads run no user code (`nativePointChart`): `getPixelForDecimal` reads its pixel
  ratio;
- both scales with the native linear projection (`nativePointProjection`, the exact `LinearScale`)
  on that chart (`identical(scale.chart, chart)`);
- a native list of points (`nativePointList`) and a native parsed list (`nativeDataUpdateList`).

The classes do not change in the loop, and the loop reads its locals. Thus these hold for the loop.

A per-pass part, `NativeGapReads.qualify` of `point_options.dart` and the loop. It holds at the pass
that holds its x and at the pass that takes it:

- the point takes the typed writes (`typedWrites`, the exact `PointElement`): its reads and writes
  are those of the port;
- `meta._parsed` is still the list of the start of the loop (an identity test);
- the item is native: a `ParsedItem` (a final class), a registered immutable typed item (the
  `DataPoint` of the typed API, `nativeDataUpdatePoint`), or a Dart SDK `LinkedHashMap` of a
  native class (`nativeDataUpdateObject`). A map with user equality or hash functions, a `MapBase`
  of the user, an identity map, a scope or another value does not qualify. A map of the same class
  as the last native map of the loop qualifies by one class compare;
- `iValue` is a number, and `vValue` is a number, `null` or `undefined`: their `ToNumber` in the
  pixel conversions runs no user code (a value of a user class runs its `toString`).

The pass that holds its x also needs options that run no user code after its read: the shared
options, or the prepared native plan of indexed colors (Chart.js ADRs 0079 and 0080), which reads
cached values only and ends before an active or a custom point. A pass that resolves its options
otherwise holds nothing: a scriptable or indexed option without the plan, the prepared line
resolution of Chart.js ADR 0088 (it can call user callbacks), an active point. The pass whose end
prepares the plans holds nothing. In the scatter loop, a pass where the plan ends and writes its
waiting contexts (Chart.js ADR 0101) takes nothing. A pass out of the range of the line loop holds
nothing. Thus the first pass of a loop, also of a partial or a public call, reads
`getParsed(start - 1)`.

The built-in scatter controller shares no options (`enableOptionSharing` is false), so its loop
holds x only inside the plan of indexed colors.

On dart2wasm only a `ParsedItem` qualifies: there `runtimeType` makes a type object, and the class
compare of a Map or a typed item costs more than the read that it saves (Measurements).

`nativeGapReadsEnabled` (`@visibleForTesting`, and the define `CHARTJS_NATIVE_GAP_READS`) turns
the held x off for the differential tests and A/B runs. `nativeGapReadsTaken` counts the gap tests
that took a held x.

### What stays

- `maxGapLength` and its `ToNumber` before the loop; the read at the first pass of a loop.
- Each case outside the guards reads `prevParsed[iAxis]` at each pass: a user controller, chart,
  scale, point, list or item class; an animated mode; a stack; a `segment`; a category, time,
  logarithmic or radial scale; an x that is not a number; a value with a user `ToNumber`; options
  resolved for each point.
- The pin case of Chart.js ADR 0036 §8, `parsed: a scriptable option writes ctx.parsed`: its
  scriptable `pointRadius` resolves each point, so each pass reads.

### What this supersedes

Of Chart.js ADR 0036 §8:

- the bullet "A local lives only inside one pass. The read `prevParsed[iAxis]` stays a read at each
  pass", for the passes of the guards above. Its reason, a scriptable option that writes
  `ctx.parsed`, stays the reason of the guard on the options;
- "the one-read rule (the 3-read form) in `line.js:98-104` and `scatter.js:127-133`" of "Adopted in
  the port step": the 3-read form stays the default form, and the 2-read form of item 3 holds under
  the guards;
- of its alternatives, the bullet "The 2-read form" of Question 5, which §8 left to a measurement:
  this decision takes it on the paths without user code.

The rest of Chart.js ADR 0036 stays.

## Alternatives

- Skip the read only when `maxGapLength` is +Infinity. The skipped `ToNumber` of a value of a user
  class is user code, so it needs the same guards, and it leaves a finite `spanGaps` with three
  reads. The held x serves both with one rule.
- Take the frozen cached entry of the mode as a third proof of options with no user code (as the
  scatter size of Chart.js ADR 0094 does). It would give the held x to a scatter chart with
  constant options. Not taken here: it widens the guards that the maintainer confirmed for this
  change (Open 1).
- Qualify each map item by `nativeDataUpdateObject` alone. Its `runtimeType` read and Set lookup cost
  about 117 ns for each item on AOT, ten times the read that the held x saves. The class compare
  `item.runtimeType == lastMap.runtimeType` of an SDK map costs 2.4 ns.
- The 2-read form with no guards: rejected by Chart.js ADR 0036 for the pin case, and still wrong.

## Measurements

A microbenchmark of the per-item costs (2026-11-10, a Mac on arm64, Dart 3.14.0-315.3.beta, Node.js
v24.22.1 for dart2js and dart2wasm, 20000 `<String, double>` maps): the read `jsGetKey(item, 'x')`
with its `ToNumber` costs 8.6-9.1 ns on AOT, 10-12 ns on dart2js and about 5 ns above the loop on
dart2wasm. The class compare costs 2.4 ns on AOT, 3.3-4.0 ns on dart2js and about 17 ns above the
loop on dart2wasm, hence the dart2wasm rule. The profile estimate of the gain is 3.5-5.8% of an
input step at 20000 points and 0.8-2.2% at 1000 points
(`.handover/zoom-perf/opportunities.md`, rank 2). The frame figures come from the old-against-new
runs of the zoom campaign (the switch `CHARTJS_NATIVE_GAP_READS`).

## Validation

`test/port/controllers/native_gap_reads_test.dart` runs each case on twins, the held x on and off,
and compares x, y, `skip` and `stop` of each point, and the count of held tests:

- line and scatter, each item class (`ParsedItem`, a map, a map with `int` x, `DataPoint`) and each
  kind of `spanGaps` (absent, `true`, `false`, 1.5, 3, 2.5, `'2'`), with the expected stops;
- NaN and infinite x values; the plan of indexed colors; a partial `updateElements`;
- the cases that keep the reads: a scriptable option that writes `ctx.parsed`, options resolved for
  each point, a user scale that writes the previous item in `getPixelForValue`, a y value whose
  `toString` writes it, a point of a user class whose write of `y` writes it, a `MapBase` item that
  logs its reads (the same log), a map with user equality (the same calls), a category axis, a
  stack and a `segment`;
- `NativeGapReads` alone: the item classes, a new parsed list, a parsed list of a user class, the
  gap test with +Infinity and NaN, and the loop-wide guards.

Removing the guard on the options, the projection, the item class, the value or the typed point
fails a test of this file. The controller references and specs of line and scatter,
`context_refresh_twins_test.dart`, `line_point_options_test.dart`,
`scatter_point_options_test.dart` and the observation test (its digests unchanged) pass.

## Open

1. The frozen cached entry as a proof of options with no user code, for the scatter loop with
   constant options (Alternatives).
2. A native projection for the exact time and category scales: the zoom cases with a time x axis
   keep the read.
