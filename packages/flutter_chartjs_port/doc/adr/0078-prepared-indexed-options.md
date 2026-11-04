# Chart.js ADR 0078: Prepared indexed styles and color-only bulk bars

- Status: implemented; VM/JavaScript/WebAssembly regressions and port checks pass.
- Date: 2026-11-03
- Related: ADRs 0054, 0069, 0076 and the update-cost estimates in performance.md §44.

## Decision

Extend ADR 0076's already-cached indexed plan with a private static template.
The controller owns its new result and does not expose it to its context factory,
so Config may return a clone of that template with the live indexed fields filled.
Generic Config calls continue filling the supplied result in place. Custom Config
classes retain their virtual option-resolution call.

The template contains only values that the existing native stores accept without
foreign-audit callbacks. It is made from cached raw inputs, never from an options
object returned to a caller. Copies preserve raw integer/double representations,
signed zero, presence bits and canonical key order, and remain independently
mutable and unfrozen. Each selected list entry and length is read after context
refresh. Unsupported selections use the existing ordinary fallback. Resolver
writes/deletes invalidate the enclosing plan; full updates replace the resolver
cache. There is no equality-based cache across updates.

Scope discovery, default-key enumeration and context refresh remain live. The
context factory still runs once, with the original pre-context shared-flag store;
cache/plan/key validation follows it. Scriptable options and custom descriptors
retain their ordinary invocation and dependency behavior.

## Bulk bars

After the first ordinary bar in mode `none`, extend ADR 0069's native remainder
to a color-only indexed plan. Qualification reads already-cached values only.
Only backgroundColor and borderColor may be arrays. They must be nonempty native
lists containing native colors, null or undefined throughout. All remaining
options must be native scalar values, with uniform skipped-edge/inflation inputs.

The existing exact controller, chart, scale, topology, numeric parsed data, native
element/list and static grid guards remain required. The new branch additionally
requires a native JsClass whose id is the string `bar` (custom id getters stay
on the ordinary path). It requires exact Config and native root/data/dataset/source
containers without routes
on the reads it skips, native default-key producers with matching current keys,
an intact warmed resolver plan, and no active element in the remaining range.
Custom element opt-ins must preserve ordinary context and active reads as well
as property writes. No user code can run between qualification and completion.

For each bar, geometry is computed first, then its context is created/refreshed
at the ordinary point, then a fresh color-filled options clone is attached.
Visibility, grid-context creation, arithmetic order and independent skipped-edge
objects retain ADR 0069's behavior. The prepared closure lives only for this
synchronous remainder, never across an update or a plugin hook.

Callbacks, active bars, indexed geometry, unknown containers, routed context
sources, custom components, empty/nested/unsupported colors and invalid ranges
retain the ordinary path. This does not broaden `updateData` eligibility.

## Validation

The indexed-option differential suite compares with a Config subclass that forces
ordinary resolution. It covers mutable/empty/nested lists, multiple indexed
fields, raw numbers, invalidation, context mutation, custom getters/descriptors,
foreign-audit effects and template ownership. Bulk tests compare with a chart
that disables bulk writes, observing geometry, complete options and selected
context fields across data/color changes and visibility changes. They also
require fallback for indexed geometry, active bars, custom data getters and
custom element-class id getters. The native bulk plan itself is exercised on
VM, JavaScript and WebAssembly. The whole workspace passes 10,886 tests; the
focused browser matrix passes 230 tests on each backend.

Production timings and commands are retained in
[benchmarks/prepared-options](../benchmarks/prepared-options/README.md). Prototype
estimates are not used as production measurements.
