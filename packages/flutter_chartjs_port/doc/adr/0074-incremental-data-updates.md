# Chart.js ADR 0074: Explicit incremental data updates

- Status: implemented; VM/browser behavior and macOS performance validated.
- Date: 2026-11-03
- Related: ADRs 0052, 0054, 0064, 0069, 0071–0073; performance.md §41.

## Public contract

`Chart.updateData()` declares that only data values have changed. It returns true
when the incremental lifecycle is selected, false when it delegates to
`update('none')`. This reports the selected lifecycle, not hook cancellation.
Existing `Chart.update()` semantics remain the full synchronization operation.

Options/defaults/theme, labels (including in-place edits), dataset identity/order,
stack definitions, component/element metadata and visibility must not change
between the last full update and an incremental call. Call update for those
changes. Within an existing source array, only numeric values/nulls may change: record
implementations, keys and value kinds must stay the same. Replace the array to
validate a new same-length source; call update for structural/type changes.
Supported inputs
are ordinary numeric lists/buffers and native numeric point records, including
typed DataPoint lists lowered by the public facade. Existing parsing:false input
format requirements still apply. Custom containers or conversions fall back.

All eight built-in controllers opt in. Numeric/radial scales require explicit
finite numeric min/max inputs; resolved values of scriptable bounds do not
qualify. Category scales require a guarded native label source. Other scales,
custom components, active animations and non-reusable/indexed/scriptable element
styles use the full lifecycle. Data-dependent scale/configuration callbacks
require full updates; they are not re-evaluated merely because data changed.

## Lifecycle and invalidation

A completed full update records cheap native identity/count tokens and the
size/DPR/font generation. Settings/component eligibility is checked lazily on
the first data call. Each source array is preflighted once per full-update generation or replacement,
using the controller's default field shape. Extra point attributes are untouched;
custom parsing keys use the full path. Subsequent calls validate structure, retain
resolved settings/layout/ticks, run the ordinary parsing and stack paths, and
invoke the ordinary controller geometry updates with mode none. Parsed records
are fresh where parsing normally creates records; parsing:false keeps its aliases.

Data-derived scale caches are cleared even when layout is retained. Overflow is
recomputed, and a changed padding requirement runs the normal layout pass.
Native font-generation changes, size/DPR changes, resize, data/options setters,
visibility APIs, full updates and destruction invalidate eligibility. Notified
array structural mutations select the full path. In-place arbitrary configuration
or metadata mutation is outside the explicit caller contract; no expensive deep
comparison attempts to rediscover those changes each frame.

The hook sequence retains beforeUpdate, beforeElementsUpdate, dataset update
hooks, afterUpdate, event/hover replay and render/draw hooks. Layout/scale hooks
are omitted when layout stays valid. Cancellation preserves the corresponding
full-lifecycle behavior. Exceptions invalidate the plan. Synchronous reentry of
updateData from update hooks, or a full update from incremental hooks, throws
StateError and clears the incremental state rather than recursing indefinitely.

## Plugins and typed boundaries

Plugins must explicitly support the partial lifecycle. Public Map plugins use
`supportsDataUpdates: true`; the internal typed Plugin constructor carries the
same capability outside its JavaScript own-key face, with an optional read-only
options guard. Approved hooks may update plugin-owned derived state but must not
mutate configuration, source/parsed data or structure. Built-in plugins opt in;
enabled decimation declines, since it can change element topology. Unknown
plugins and invalidated descriptor caches require a full update. The gallery
meters and ChartView's internal theme/keyboard observer opt in.

Native data classification is shared with primitive parsing. SDK-sealed numeric
TypedDataList buffers/views qualify without per-platform runtime-type tables.
Typed lowering registers the known native DataPoint containers and immutable
point type through a framework-free helper. Typed root/data scopes also qualify
for category source reuse when they are exact classes with no relevant routes;
unknown subclasses and routes keep ordinary reads. This addresses public-host
representation differences instead of optimizing only raw gallery Maps.

## Controller specialization

Bars retain their index ruler only after incremental updates, only for one
primitive numeric dataset on a stable category layout with skipNull disabled.
Full updates clear it, so users who never opt in do not retain extra pixel
buffers. Structured/stacked/multi-dataset cases recompute the necessary geometry.
The bulk numeric writer accepts preflighted native prepared Maps during this
lifecycle; the normal full-update guards are unchanged. Other controllers reuse
the shared lifecycle while retaining their own geometry algorithms: doughnut/pie
totals/angles, radial radii/angles, line segments and scatter/bubble positions.

## Validation

Reference twins compare parsed state, labels, geometry, stacks, hit tests and
hover/tooltip state for all eight types. They cover typed points, native numeric
buffers/views, array replacement, gaps/nonfinite values, prepared x changes,
custom components/containers, shape/visibility/resize/font invalidation, dynamic
bounds/styles, plugin opt-in/cancellation/errors/reentrancy, decimation fallback
and bubble-radius overflow. Browser probes run on JavaScript and WebAssembly.
Performance evidence and reproduction are in benchmarks/data-update/.

The final native source contract passes 31 lifecycle tests and eight category
source tests on the VM and both browser backends. All 10,812 workspace tests,
full JS/Wasm suites, fixtures, public API, analysis, formatting, parity and port
checks pass. Numeric 20k bar CPU improves 21.8%, prepared Maps 46.4%; all eight
controller types show gains in supported configurations. Full-update controls
remain within the regression gate. After unlocking the desktop, foreground
updates improve 43.17 → 56.29 FPS on the matched 736.0×441.6/DPR2 canvas, with
all activity checks true. Average UI/build falls 20.70 → 16.89ms, but p90 remains
19.68ms, so this does not establish steady 60 FPS. Earlier inactive runs remain
retained and excluded.
