# Chart.js ADR 0064: Guarded category label measurement plans

- Status: implemented; bounded native and browser validation.
- Date: 2026-11-02
- Related: ADR 0063, performance.md §29–30, axis-pipeline-options.md.

## Decision

Cache full candidate-label measurements for the exact built-in CategoryScale,
while continuing the ordinary update lifecycle and geometry fitting. A plan owns
one string-label snapshot, one static-font input tuple and the private full label
sizes. It does not retain Tick objects, contexts, resolved option views or fitted
geometry. Only one plan is retained per scale. Small lists (<256) do not populate
it; a smaller candidate set releases the previous plan.

On every measurement pass, compare the current ordered string labels and static
font inputs, the canvas identity and its text-metrics generation. Only an
unsampled, native candidate list with measurement stride 1 qualifies. Dynamic or
foreign fonts, multiline/non-string labels, custom tick lists and scale subclasses
use the original path. The first font resolves normally before probing a hit;
its canvas font write must be accepted and its resolved fields must match the
scalar tuple. Recheck the root context, tick list and options after that first
resolution, and capture only string labels before the remaining pass. No callback is executed merely to qualify
its result for caching.

A hit recreates the remaining fresh tick contexts with the same original indices,
prototype and own-key order, preserving any context a hook already supplied.
A cleared scale context disables the hit, so its reconstruction timing remains
normal. The direct typed tick-context constructor removes temporary key writes
without changing context identity or its mutable face.

All scale callbacks and plugin notifications remain in order. User label callbacks
still run. Rotation, auto-skip, fit and draw items remain live. A resize or changed
y-axis width therefore refits against current geometry using cached measurements;
no frozen-axis workaround or altered stress configuration is introduced.

## Default-label dispatch and source guards

CategoryScale invokes the exact built-in formatter directly, keeping its normal
first read and re-reading the callback for every candidate. Non-default callbacks
retain generic dispatch with the original receiver, index and list.

After that first callback, known-native config/data Maps and a native label List
can supply the remaining default labels directly. Custom containers, custom tick
lists, nonordinary tick option objects, unknown Config/Chart subclasses and custom
callbacks retain per-label reads. The source is borrowed only for that conversion,
never kept across updates. A callback change clears it for the rest of the pass.
The ordinary Chart opts in; the gallery's timing-only wrappers explicitly confirm
that they keep Chart's data/config getter behavior. No chart options are changed.

## Font environment

CanvasTextMetricsSource is an optional internal adapter capability. The native
canvas installs one listener on PaintingBinding.systemFonts and exposes an identity
generation. A font notification disposes cached paragraphs, clears numeric metrics
and parsed fonts, and advances the generation. Scale measurement plans and their
existing width cache notice the change on the next measurement/update.

Without a painting binding the capability returns null and keeps the old path;
using an offscreen canvas does not create a Flutter binding. A custom context must
opt in explicitly to deterministic, side-effect-free font/text measurements. Mock
contexts and other adapters remain uncached by default. The font notification does
not itself call chart.update; existing update scheduling is preserved.

## Evidence

The protocol and raw comparisons are in benchmarks/axis-label-plan/. The final
native-input path reduces 20k category update CPU from 16.331 to 5.425 ms (66.8%)
and the full chart call from 22.571 to 10.724 ms (52.5%). Layout is 13.553 to
2.483 ms. Tick values, labels, rotation and chart bounds agree in every measured
cell. A foreground 30-second macOS profile run reports 60 FPS, 44 ticks at 50°,
10.76 ms average build and 1.02 ms raster.

This is a conservative content/metrics plan, not the frozen full-layout prototype.
Fresh ticks/contexts, label generation and automatic y limits still cost time; the
sub-1ms axis target is not claimed. No sampling, fixed bounds, lower point count or
callback suppression is used to obtain the result.

## Correctness

Cached/uncached twins compare all point coordinates, domains, tick labels/context
indices, rotation and chart bounds after label edits, list replacement/growth,
font/default changes, viewport changes, y-domain expansion and tick-option changes.
Additional cases cover dynamic font/label callbacks, multiline labels, custom
scales and tick lists, context reconstruction, effectful Chart getters and callback
replacement, and font-generation invalidation. Native container probes reject
custom Maps/Lists without invoking their getters. Existing upstream references and
fixture tests remain the output oracle.

ADR 0065 subsequently defers the allocation of unobserved tick contexts on a plan
hit. Fresh identity and the original parent/index remain observable on access;
the original implementation and measurements above remain the baseline record.
