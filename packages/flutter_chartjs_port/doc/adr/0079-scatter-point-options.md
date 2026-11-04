# Chart.js ADR 0079: Scatter options prepared within native loops

- Status: implemented; VM/JavaScript/WebAssembly and port checks pass.
- Date: 2026-11-03
- Related: ADRs 0028, 0054, 0076, 0078; performance.md §46 estimates.

## Decision

Prepare indexed point colors within ScatterController's updateElements and
non-line getMaxOverflow loops. Two ordinary resolutions warm the existing
indexed resolver plan. There is one preparation attempt per loop. The plan
contains a private static PointOptions template and native, nonempty indexed
background/border color lists. Each use creates an independent unfrozen options
copy with `$shared: false`, after refreshing the original context.

No plan persists across functions, layout passes, plugin hooks or full updates.
There is no full input scan. Coordinate eligibility is checked at the original
iteration, before a conversion could invoke user code. Overflow only copies raw
and parsed entries into contexts and computes a native point size; it does not
read their coordinate fields, so native containers suffice there.

## Eligibility and observation order

Preparation requires the exact scatter controller and Config, a native JsClass
with id `point`, and native root/data/dataset/source containers with no routes
on skipped reads. Native default-key producers and the warmed resolver's current
key/prefix/descriptor plan must agree. Only colors may vary by index; remaining
fields must be native scalars. Scriptable/custom descriptors and indexed numeric
fields retain ordinary resolution. Multiple datasets are selected by index.

The chart and element capabilities are separate from existing typed-write
capabilities. They promise ordinary data/config/context/DPR reads, point sizes,
and property writes. Unknown subclasses do not inherit eligibility; explicit
test/timing opt-ins must uphold that full contract. The gallery timing wrapper
only records calls and opts in explicitly.

updateElements additionally requires mode none, native numeric scale projections
owned by the chart, x/y axes, no stacking or segments, and integral nonnegative
range indices. It retains its ordinary geometry calculations and write order.
Each point and parsed coordinate item is checked before executing its ordinary
reads/writes. Native object implementation is cached by type, while x/y values
and typed routes stay live. Unknown containers, objects requiring conversion,
custom points or an active point discard the plan before user code can run.
The remainder then uses ordinary resolution, with no second preparation attempt.

getMaxOverflow preserves descending order, casts the receiver before resolving
options, and still invokes each point's size method. A custom point ends reuse
before either its options or size can run user code. Numeric NaN/zero behavior
is retained by the original size/max calculations. Context setters remain the
ordinary setters, preserving deleted/reinserted keys and raw/parsed write order.

Native indexed color contents are checked for each new plan. During the eligible
loop no user code can mutate them; outside it the original resolver observes
mutations and invalidation normally. No color equality cache is introduced.

## Validation and performance

Chart twins disable the native capability on the reference side. Regressions
compare geometry, complete options, selected context fields/key order, callback
traces and activation. They cover multiple datasets, showLine, live data/colors,
custom size mutation, effectful parsed getters, active callbacks, indexed numeric
and scriptable styles, partial ranges, custom projections/class ids and invalid
point cast ordering. Framework-free tests exercise native container/route checks
and point-plan ownership/invalidation on VM, JavaScript and WebAssembly.

Production A/B/B/A measurements and validation logs are retained in
[benchmarks/scatter-options](../benchmarks/scatter-options/README.md). The
implementation avoids the repeated full-input validation that erased prototype
gains in §46. It does not implement the prototype's unchecked context writes.
