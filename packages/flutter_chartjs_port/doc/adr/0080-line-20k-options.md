# Chart.js ADR 0080: Line option costs at 20k items

- Date: 2026-11-03
- Status: implemented; validation and measurements recorded with the evidence.
- Related: ADRs 0054, 0074, 0076, 0078, 0079.

## Target

Native macOS, 20,000 points, all Stress Charts/Line combinations of redraw,
full update, explicit data update and looping animation; connected points on/off;
static/indexed/scriptable colors; 0/50/200 overlay labels. A 60 Hz target gives
16.67 ms per frame. Meeting it in one cell does not establish it in every cell,
on every device, or for arbitrary user callbacks. All 20,000 points remain.

## Changes

1. Line's direct mode-none loop prepares native indexed color options after two
   ordinary resolutions. The existing point contracts guard chart, config,
   source containers, point classes, numeric coordinates and scale projections.
   The preparation ends before custom reads, active callbacks or custom points.
   It never persists across updates or plugin hooks. Partial ranges retain their
   original skip behavior and absolute indices.
2. An exact Config with owned native point/bar resolution inputs can copy a
   private static template when only color callbacks vary. Plans use cached raw
   scalars, native built-in descriptors, current keys and the result class. They
   never cache a callback result. Context creation still occurs once at its
   original point. Every resolver write/delete invalidates the plan; remaining
   keys use ordinary reads and the original per-element descriptor snapshots.
   Results stay fresh, unfrozen and unshared. Retained subviews stay independent.
3. When every varying callback accepts exactly one positional argument, proven
   using the JS runtime's function-type arity rule, the unused second-argument
   views are constructed lazily. The call still uses jsCall1. Optional second
   arguments and JsFunction retain normal views and calls. A non-scalar return
   enters the original post-call array/subresolver handling without calling the
   callback twice. Descriptor inputs are snapshotted before callbacks; fallback
   views use fresh descriptor objects with those values, including undefined.
4. Resolver prefixes owned by the controller build their cache key once per
   resolution. Custom prefix lists retain ordinary join traversal.
5. ContextObject tracks membership of ten frequent names with an integer mask.
   The ordered name list remains the enumeration source. Constructors, claims,
   writes and deletes synchronize membership; reinsertions append normally.
   Typed data-context setters use constant bits. No context writes are skipped.

No dataset sampling, callback memoization, raster substitution, renderer changes,
public API changes or reduction in point count is introduced. Full update retains
its complete lifecycle. Data-only eligibility and its full-update fallback remain
unchanged. General callbacks have no bounded execution cost.

## Validation and results

See [line-20k evidence](../benchmarks/line-20k/README.md) and performance.md §48.
Independent ordinary-path twins exercise scriptable template activation, fresh
results and retained views, mutation via current/retained resolvers, deletes,
context-time invalidation, nested/array/function returns, optional second
arguments, custom descriptors, recursion and call counts. Indexed line twins
cover connections, multiple datasets, partial ranges, active points, effectful
parsed reads, custom classes/scales and live data/options. Context tests cover
membership, own-key order, deletion/reinsertion, extras and inherited fields.
