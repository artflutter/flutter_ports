# Chart.js ADR 0068: Live single-dataset bar layout and update construction

- Status: implemented; macOS performance and VM/browser behavior validated.
- Date: 2026-11-02
- Related: ADRs 0036, 0054, 0066, 0067; performance.md §35.

## Decision

Accelerate the current single-dataset bar layout when the chart can prove that
its axis count is one and its axis and stack indices are zero. This is a live
proof, not the unchecked per-update memo explored in the earlier investigation.

The exact BarController opts in. Chart and the built-in category/linear scales
provide ordinary-read capabilities; unknown subclasses keep the original calls.
The gallery's final timing wrappers explicitly opt in because they override only
timing/draw notifications, not config, options, scale or metadata reads.

The proof checks the live config/data/dataset containers, one dataset, a string
or absent axis id, a cached cartesian chart index axis, one native ChartMeta in
the current sorted list, its controller/index-scale identity, primitive stack
name, cached boolean grouping and cached boolean/undefined stacking. It also
performs the ordered first-scale search, retaining its short circuit. Unknown
containers, routes, unresolved values, custom classes, multiple datasets and
indexed stack decisions retain the existing path.

The axis count is observed before category-trait resolution, and the axis/stack
position after it. The proof is repeated at the second point unless those trait
reads are already cached primitive values and cannot execute user code. No
scriptable option is resolved merely to qualify. A callback can mutate dataset
count/order, scale keys/axes, options or metadata between observations; the later
proof then falls back or observes the new state. Reentrant updates are included.

Container implementation classifications are cached by identity because their
runtime type cannot change. Data values, list lengths, routes, ids, cache cells,
metadata fields and scale axes remain live. The config object itself is retained
by Config. Scale dictionary key order is cached only after comparing its current
insertion-order keys; value/axis reads are never cached. Replacing a parent data
container invalidates descendant classifications. These caches hold one recent
classification per level, not a growing identity table.

Two additional allocation/algorithm improvements apply independently:

1. After getAllScaleValues has copied controller results into its own numeric
   list, a finite nondecreasing list needs no stable sort. The subtraction
   comparator has no user code. Unsorted/non-finite input retains jsSort;
   arrayUnique and its signed-zero/duplicate behavior are unchanged.
2. BarProperties.geometry initializes the initial seven typed fields and their
   compact key-order/presence representation together. Named arguments evaluate
   in the old literal order. Options, skipped edges and inflation are appended as
   before. Every bar still gets its own property object; no pooling or sharing is
   introduced. TypedRecord.initializeSlots is protected and only initializes a
   fresh compact record's leading slots.

## Why

At 20,000 bars, the remaining update spends most of its time in dataset updating.
The original loop repeatedly constructs axis dictionaries and filtered stack
lists even for one ordinary dataset. An initial live guard was slower because
repeated generic runtimeType inspection dominated it. Its profile and timings
are retained; only immutable implementation classification is now reused, while
all values needed for correctness are still checked.

The original upstream structure remains next to the narrow proof, including
getStackCount/getStackIndex, skipNull's indexed search and all custom behavior.
There is no point-count reduction, skipped parse, frozen layout, asynchronous
update or callback suppression.

## Validation

Twins compare bar geometry against a Chart subclass that disables the capability,
through data/option/visibility/size/dataset-count changes, both orientations,
scriptable mutation between observation points and a reentrant update. Other
checks cover typed scopes/routes, custom maps/lists/scales, cold option caches,
numeric key order, sorted/unsorted/non-finite values, signed zero, and the
property record's keys/present/foreign bits before and after mutation.

The prewritten protocol, failed preliminary guard, profiles, full A/B/B/A series,
fallback controls and foreground FPS are retained in benchmarks/bar-update/.
Performance outcomes are recorded in performance.md §35.

The final full 20k update improves 35.5%, 55.747 → 35.962ms. Update-only work
improves 42.436 → 21.764ms and foreground FPS 16.59 → 23.97. Both primary pairs
pass the gate and no control has a repeatable regression beyond the limits.
All workspace tests, twelve targeted tests on each of JavaScript and WebAssembly,
fixtures, analysis, formatting, parity and port checks pass. No golden changed.
Continuous 20k updates remain below 60 FPS.
