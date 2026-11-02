# Chart.js ADR 0062: Reuse the element option cache-key string

- Status: implemented; bounded Android validation.
- Date: 2026-11-02
- Related: ADR 0054 (typed internal model), performance.md §13.7 item 10.

## Decision

DatasetController keeps the last element type name, resolved mode and joined
`type-mode` string. Repeated inputs reuse that string instead of allocating and
hashing another equal string. Only three private fields are added. No global
switch, public API or new cache of option results is introduced.

Resolve the element id and run jsToString before checking the memo on every
call. The existing string-keyed _cachedElementOptions map remains unchanged,
including collisions such as (`point`, `default-x`) and (`point-default`, `x`).
Mode/type changes replace the memo. configure still clears option values; a
retained key string never retains a resolved option or bypasses invalidation.
Scriptable callbacks and shared/cloned/frozen option behavior remain unchanged.
The memo has bounded per-controller storage and is safe across reentrant calls:
each invocation retains its own computed key in a local variable.

The decision is narrower than changing the cache to a nested map or tuple key,
which would alter the original joined-string collisions. The prior phase-7 key
memo experiment was rejected by its then-current guard protocol. This is a new
measurement on the typed, direct-Color core and retains the old record intact.

## Evidence and protocol

Baseline 6197449, including the direct Flutter Color core. A Pixel 8a profile of
bubble update at N=5000 collected 11,548 samples. _resolveElementOptions has
12.4% inclusive frame samples. Within that function, String hashCode has 2.59%
self, _concatAll 2.28%, and _interpolate 2.12% of all samples. These are profile
shares, not a measured speedup. Canvas drawing/recording remains a large cost.

The prewritten Android release protocol is in
benchmarks/element-option-cache-key/protocol.md: 15 cells, guards before updates,
A/B/B/A, nine 150 ms batches and 500 ms warmup. The two primary cells are bubble
and unshared scatter updates at N=5000, requiring at least 5% less update CPU
in both pairs. Full-call totals are also reported and guarded against repeatable
increases exceeding both 0.1 ms and 5%. Two pairs provide direction only.

## Correctness

Five new tests first passed on the unchanged baseline, then on the candidate:
mode/type alternation and option identity, effectful id conversion on every
cache hit, joined-key collisions, cache invalidation after configuration changes,
and uncached scriptable callback results. The existing controller reference and
specification tests also remain the behavior oracle.

## Outcome

The predeclared protocol passes. At N=5000, unshared scatter update CPU is
3.685 to 2.2965 ms (-37.7%) and the full call is 5.3965 to 4.006 ms (-25.8%).
Bubble update CPU is 8.506 to 7.136 ms (-16.1%); its full call is 20.127 to
19.520 ms (-3.0%). Both primary update cells exceed the 5% requirement in each
pair. No full-call control has a repeatable increase above both thresholds.

Retain the measured tradeoffs: bubble drawing within its update call increases
10.5% while the full call remains faster. Bar full-update totals increase 2.0%
in aggregate (+4.05% and effectively zero in the two pairs). The causes of those
component/control shifts are not established. These bounded CPU results do not
claim zero regression, GPU/FPS improvement or performance on other devices.
The full report and all raw values are in performance.md chapter 26 and
benchmarks/element-option-cache-key/README.md.
