# Chart.js ADR 0165: The held option cache entry of a scatter loop

- Status: accepted
- Date: 2026-11-18
- Supersedes: of [Chart.js ADR 0054](0054-typed-internal-model.md) §4, the sentence "No memo or cache of our own"
  for the one held entry of item 1; of [Chart.js ADR 0109](0109-previous-x-of-the-gap-test.md), the sentence "The
  built-in scatter controller shares no options (`enableOptionSharing` is false), so its loop holds x only inside
  the plan of indexed colors" and the list of the options of the pass that holds its x, for item 3.
- Related: [Chart.js ADR 0062](0062-element-option-cache-key.md), [Chart.js ADR 0151](0151-shared-bar-animation-options.md)

## Context

The scatter controller shares no options. Each point of its loop calls `resolveDataElementOptions`: the id of the
element type, the cache key, a read of the option cache and a clone of the entry. On the scatter night of
2026-11-18 this was 16% of a data-only update of 20,000 points on the macOS app and the iPhone. The clone is the
upstream behavior: each point owns its options. The key and the read are the same for each point of a loop. Each
call gives no-option-sharing results, so the scatter loop also never holds its x for the gap test.

## Decision

1. **The held entry.** `HeldElementOptions` keeps the entry that the last call of one loop read, with its `id`
   string, its mode, its key and the count of the writes and the clears of the cache at the read.
   `resolveHeldDataElementOptions` gives `cloneIfNotShared(entry, sharing)` when `_idOf(dataElementType)` gives the
   same string object, the mode is equal and the count is the same. It writes the last key as `_elementCacheKey`
   does. Each other call is the ordinary one and holds the entry of its key, unless a call inside it wrote another
   key.
2. **The scope.** Only the loop of the exact `ScatterController` makes a hold: a subclass can replace
   `resolveDataElementOptions`. The hold is a local of `updateElements`. No entry outlives the loop.
3. **The gap test.** A point that took the entry of a class value with `PointOptions` (a final class) ran no user
   code after its read of x: the id is a field of the class value, and the clone is ours. It holds its x for the
   gap test of the next point under the other guards of Chart.js ADR 0109.
4. **No change of a result.** The count grows at each write and each clear of the cache, so the entry is the one
   the ordinary read gives. The options of each point, the contexts, the read counts on objects of the user and the
   gap tests are the upstream ones.

## Rejected

- One entry for the whole update, without the count: a scriptable option of a hovered point writes the cache.
- No clone for the next points: the points would share options, unlike upstream.

## Consequences

- A new input of the cache key in `_resolveElementOptions` must become a test of the hold.
- A new write into the option cache must add one to the count.

## Open

1. No run timed the production form. The switch `optkey` of the measurement branch of 2026-11-18 gives the pair.

## Tests

`test/port/controllers/scatter_held_options_test.dart`, `test/port/controllers/native_gap_reads_test.dart`
