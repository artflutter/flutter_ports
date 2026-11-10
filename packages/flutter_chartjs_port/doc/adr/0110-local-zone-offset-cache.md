# Chart.js ADR 0110: The local-zone offset cache

- Status: accepted (2026-11-10, by the porting lead). The code and the tests of Validation pass. By
  the maintainer's rule of 2026-10-31, a record is accepted when its code passes the tests.
- Date: 2026-11-10
- Supersedes: of [Chart.js ADR 0024](0024-dates.md) decision 3, "Local", the two statements "It
  reads the offset of an instant from the local fields of `DateTime.fromMillisecondsSinceEpoch(t)`,
  not from `timeZoneOffset` (fact 3, dart2js)" and "It keeps one interval of instants with one
  offset, with the 1-day rule of fact 3". The rest of Chart.js ADR 0024 stays: the 1-day rule, the
  clear in `formats()` and `setDefaultDateZone`, the hour floor, the platform offsets and the row
  `platform-date-local-offset`.
- Related: Chart.js ADRs 0024 (dates), 0034 (no display-only JS exactness), 0045 (the JS numeric
  rules). The zoom performance campaign (2026-11-10), item T1.

## Context

A time scale in the local zone asks `LocalZone` for an offset at each wall-time step of the
calendar: `startOf`, `add` and `diff` of the tick generation, then `format` of each label. Chart.js
ADR 0024 made `LocalZone` read the platform through the seven local fields of a `DateTime`, and keep
one interval of instants with one offset, made by the 1-day rule of its fact 3: when the offsets at
`t - 1 day`, `t` and `t + 1 day` are equal, the offset is constant on that interval. The rule is
exact when no two offset changes of a zone are less than 48 h apart (the smallest gap in the tz data
of 1902-2037 is 167 h).

The device profiles of the zoom flows (`.handover/zoom-perf/opportunities.md`, item T1) put
`_platformOffset` at 5.2-8.0% of a wheel step on a 1,000-point chart with a local time axis, and
1.6-2.7% at 20,000 points, on the Pixel 8a, the iPhone 17 Pro and the Mac. The native offset call is
3.2-5.2% of the step; the fields (`_computeUpperPart` of the VM) are 0.6-1.2%. The label pass asks
again for offsets worth 1.5-2.7% of the step.

Two facts:

1. **The label pass misses the one interval.** The tick generation steps through the minor unit
   before the auto skip: 33 month starts in one update of the 1,000-point chart (one point per day
   from 2000-01-01, 17 ticks after the skip), 58 intervals at 20,000 points. Each step makes its own
   interval, which replaces the last one; the label pass then asks for the first tick again, and
   each of its lookups misses. A probe of one update in Europe/Madrid counted 335 platform reads
   with one interval and 227 with 64 (1,000 points), 528 and 348 (20,000 points). With 4 to 32
   intervals, the first-in first-out slots are fewer than the ticks, so the label pass still misses:
   323 and 513 reads.
2. **On the VM, `timeZoneOffset` is the offset of the local fields.** The VM patch of `DateTime`
   (`sdk/lib/_internal/vm_shared/lib/date_patch.dart`) computes the local fields from
   `_value + _timeZoneOffsetInSeconds(_value) * 1000000`, and `timeZoneOffset` is
   `Duration(seconds: _timeZoneOffsetInSeconds(microsecondsSinceEpoch))`: the same function of the
   same instant. The field form recomposes the wall milliseconds from these fields with the day
   number, so it gives that offset in ms exactly, also before 1901-12-13 and after 2038-01-19, where
   both take the substitute year of `_equivalentSeconds`. The `timeZoneOffset` read skips the field
   computation and its list. dart2js gives `timeZoneOffset` in whole minutes, so the web keeps the
   fields (fact 3 of Chart.js ADR 0024). dart2wasm keeps them too: it is a web target, and its
   offsets were not compared.

## Decision

### The platform read

`_platformOffset` reads `DateTime.fromMillisecondsSinceEpoch(t).timeZoneOffset.inMilliseconds` on
the VM (JIT and AOT, every native platform). On the web (`dart.library.js_interop`: dart2js, DDC
and dart2wasm), it keeps the local fields. The instant is still clamped to ±8.64e15 ms first. The
marker of the row `platform-date-local-offset` stays on the function: the offsets are those of the
platform, as before.

### Up to 64 intervals

`LocalZone` keeps up to 64 intervals, each with one offset:

- A miss reads the offsets at `t - 1 day`, `t` and `t + 1 day`. When they are equal, the interval
  from `t - 1 day` to `t + 1 day` goes into the cache, as in Chart.js ADR 0024. Else nothing is
  cached, as before.
- A new interval of the same offset as a cached one that overlaps it or touches it (their union
  has no gap) widens that cached interval to the union. Each instant of the union is in one of the
  two, so it has that offset.
- Else the new interval takes a free slot, or, with 64 in use, the slot of the oldest new interval
  (first in, first out).
- A lookup tests the slot of the last hit, then the slots after it, then the slots before it. The
  calendar asks for close instants in a row, so the next tick is mostly in the next slot.
- `clear()` empties all slots. `formats()` calls it once in each update of a time scale, and
  `setDefaultDateZone` calls it, as Chart.js ADR 0024 decides. A change of the platform zone still
  reaches the next update.

No interval is made by another rule. Two cached intervals of the same offset with a gap between them
stay two: an offset change can sit in the gap. 64 slots cover the minor ticks of one update of the
benchmark charts (33-58) with room; an update that asks for more distinct days than 64 loses the
oldest intervals and reads the platform for them again, as one interval did.

`LocalZone.cachedIntervals` (visible for testing) replaces `cachedInterval`.

## Behavior

Exact. Every offset that `offsetAt` gives is the offset of the platform at that instant:

- on the VM, the `timeZoneOffset` read and the field form are the same function of the same
  instant (fact 2);
- every cached interval comes from the 1-day rule or the union of two touching intervals of one
  offset, so it has one offset under the tz fact that Chart.js ADR 0024 already relies on.

`fromWall`, the hour floor, the `diff` zone delta and the formats read the same offsets, so the
ticks, the labels, the parsed values and the pixels do not change. UTC (`setDefaultDateZone('UTC')`,
the specs and the reference tests) does not use `LocalZone`.

## Alternatives considered

- **Keep one interval.** The label pass and `fromWall` read the platform again for each tick (fact 1).
  Rejected for speed.
- **A cache by day or by 15-minute slot.** Not exact (Chart.js ADR 0024 fact 3: 466 offset changes
  of 1902-2037 are not at a multiple of 15 minutes). Rejected.
- **Join two cached intervals of one offset across a gap.** Not exact: a summer between two winter
  intervals. Rejected.
- **`timeZoneOffset` on every target.** Not exact on dart2js (whole minutes; 7,368 mismatches in
  Kyiv, Chart.js ADR 0024 fact 3). Rejected for the web.
- **8 or 32 slots ("a few").** The probe of fact 1 gave 323 reads for 4 to 32 slots against 227 for
  64: fewer slots than generated ticks give the first-in first-out cache no hit in the label pass.
  Rejected.
- **A sorted list with a binary search.** The lookups come in time order, so the slot after the last
  hit holds the next one; an insert would shift the slots. Not needed at 64.

## Consequences

- A local time axis reads the platform about a third less often in an update, and each read on the
  VM is one native call. A probe in the JIT test runner (Mac, Europe/Madrid) timed the x-scale
  `update` of the 1,000-point chart with a cleared cache at about 250-320 µs before and 135-140 µs
  after; at 20,000 points about 420-665 µs before and 175-180 µs after. The device figures come from
  the old-against-new runs of the campaign.
- `LocalZone` holds three lists of 64 integers.
- The rest of Chart.js ADR 0024 stays: the 1-day rule and its tz fact, the clear in `formats()`, the
  platform offsets of the row `platform-date-local-offset`.

## Validation

- `test/port/core/date_zone_test.dart`: the group `LocalZone on a table` runs the cache on the
  offset changes of the reference zones and of their hour-24 zones, around each change and at 20,000
  random instants in sorted and shuffled order; its group `cached intervals` pins a second pass with
  no platform read, the join of two touching intervals, no join across an offset change, and the
  first-in first-out slots. The group `LocalZone` runs `LocalZone.instance` in the zone of the
  machine against the local fields, and on the VM compares `timeZoneOffset` with the field form at
  25,000 instants over the whole Date range (also outside ±2^31 s) and at each offset change of
  1902-2037.
- `test/port/core/date_adapter_test.dart`: the group `reference local` runs startOf, endOf,
  isoWeek, add, diff, format and the parse near the offset changes of the Node.js reference values
  (America/New_York, Australia/Lord_Howe, Pacific/Apia) on the table zone and on the cache of
  `LocalZone` over the same table.
- Run locally with `TZ=` America/New_York, Europe/Kyiv, Asia/Tehran, Pacific/Apia,
  Australia/Lord_Howe, America/Sao_Paulo, Africa/Casablanca, Asia/Kathmandu, Europe/Moscow and UTC:
  all pass. The CI runners run in UTC; the table groups run there and in Chrome (JavaScript and
  WebAssembly).
- The observation test keeps its digests.
