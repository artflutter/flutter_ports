# Chart.js ADR 0063: Reuse parsed static tick fonts

- Status: implemented; bounded macOS validation.
- Date: 2026-11-02
- Related: ADR 0054 (typed options), performance.md §27–28.

## Decision

Each Scale retains one private parsed-font template and its five scalar inputs.
resolveTickFontOptions still reads options.ticks and calls getContext(index) on
every invocation, preserving context creation, prototype, key order and identity.
A hit returns a fresh ParsedFont because its string field is mutable.

The guard reads only already-cached raw resolver values. It never calls a
scriptable option to decide whether to cache it. Reuse requires ordinary
OptionView/OptionResolver objects with untouched internal slots, no sub-proxy,
inert descriptor defaults and already-cached descriptor properties. Cached
font inputs must be plain strings, a positive finite double size, a positive
finite double or string line height, a recognized literal style, and a string
or null weight. All five fields must be present. Scriptable/indexed, partial,
foreign or invalid-font inputs retain the normal path and its warnings/throws.

An absent ticks.font may instead use the live global default font. On every
call, inspect that it is exactly FontSpecScope with no routes on the root font
or its five fields, then read its scalar cells. This also preserves the eager
fallback reads of toFont: routed/custom/invalid fallbacks always use the normal
path. Absent weight differs from explicit null. Replacing or mutating the global
font changes the next guard result; no update/version counter is required.

The guard rechecks the input tuple every time. Resolver writes and deletes are
visible immediately. Direct raw-map changes retain upstream resolver-cache
behavior; a new resolver sees those changes. No context-bound view or callback
result is retained. The template is copied when remembered and on each hit,
so user mutation of an earlier returned object cannot poison a later result.
The cache is bounded to one entry per scale and is not publicly exported.

## Validation

The previous category-layout optimization is the baseline, including its typed
font reads, numeric parsing and direct tick-context construction. The measured
workload and prewritten gate are in
[the protocol](../benchmarks/static-tick-font/protocol.md). Reproduction and raw
results are recorded beside it; performance.md §28 reports the final decision.

The tests check plain and absent-font hits, live defaults, missing fields,
resolver writes/deletes/replacement, raw-map caching, whole-font and nested
scriptable/indexed options, invalid-style warnings, eager fallback throws and
routes, custom descriptors/setContext, independent font objects and per-tick
context construction. Existing upstream scale references remain the oracle for
layout and drawing. Layout measurements compare both axes' tick values and
labels, rotation and chart bounds exactly.

## Outcome

The prewritten comparison passes: category N=20000 update CPU falls 47.9%,
30.8685 → 16.0745 ms, and the full call falls 38.8%, 35.932 → 21.9905 ms.
Both pairs exceed the 15% target with equal layout outputs. No full-call control
exceeds the regression gate. The draw component inside the update increases
20.4%; the full-call result includes that cost, whose cause is not isolated.
See performance.md §28 for the controls, preliminary probes and limits.

ADR 0064 adds an in-flight mutation guard: a getter that changes an earlier font
field while toFont is reading later fields must not cause the mixed result to be
remembered for the new scalar tuple. A dedicated regression covers that case.
