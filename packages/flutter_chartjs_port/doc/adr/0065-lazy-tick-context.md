# Chart.js ADR 0065: Defer unobserved tick contexts

- Status: implemented; bounded macOS and browser validation.
- Date: 2026-11-02
- Related: ADR 0064; performance.md §31.

## Decision

After a successful static label-measurement plan hit, retain each tick's original
scale-context parent and candidate index. Materialize ScriptableScaleContext only
when Tick.$context is read. Context construction performs no user code; the parent
and index are captured at the original point in the lifecycle, before auto-skip.

The getter returns the same object on subsequent reads. A supplied context takes
precedence; setting the property, including clearing it to null, cancels pending
creation. Repeated preparation preserves the first parent/index. Retained hidden
ticks therefore still expose the parent and index from their own update, even if
the scale's root context is subsequently replaced. Mutating the tick remains
visible through context.tick, exactly as for an eagerly created context.

Ticks remain fresh on each update. No scriptable callback, lifecycle notification,
label measurement, geometry fit or point update is removed. Dynamic font paths and
custom scales continue to materialize contexts through their existing accesses.
Hooks that inspect every context still cause every context to be created.

## Evidence and boundaries

The change is confined to Tick context storage and the existing measurement-plan
hit loop. It adds two small fields per Tick in exchange for avoiding the context
object, key list and boxed index of unobserved ticks. This can add cost to cases
that cannot use the plan, so the comparison includes sampling and a custom-scale
control in addition to the ordinary workload and draw-only case.

The prewritten protocol and raw results are in benchmarks/lazy-tick-context/.
The production result will be recorded in performance.md §31. Tests cover getter
identity, explicit writes/clears, repeated preparation, original parent/index,
retained skipped ticks and observation before/after label sizing. Existing cached/
uncached twins remain the geometry and callback oracle.

## Outcome

The A/B/B/A gate passes. Ordinary 20k category layout improves 22.5%,
2.598 → 2.0125 ms, and the full chart call improves 15.8%,
11.083 → 9.3365 ms. Both primary pairs improve layout by more than 10%.
Control regressions stay below the predeclared combined threshold.

Validation: 10112 VM tests pass, plus all 19 context/layout integration tests on
each of JavaScript and WebAssembly. Fixtures, analysis, formatting, parity and
all port checks pass. Only this focused optimization is retained.
