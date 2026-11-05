# Chart.js ADR 0088: Direct execution of prepared scalar point colors

- Date: 2026-11-05
- Status: implemented; VM, JavaScript, WebAssembly and port checks pass.
- Related: ADRs 0082, 0083, 0087; performance.md §61.

## Decision

A native line resolution plan may capture a direct executor for an existing
scriptable point-color plan. Only the exact native PointOptions template, with
$shared false, an immutable matching key snapshot and context-only callbacks,
qualifies. Context-only means the existing exact one-positional-argument test;
contextual/two-argument callbacks retain the general resolver path.

The executor avoids the general Config resolver setup and the successful
context/result record on every point. It still creates a fresh options clone,
executes every callback in its original order and uses the existing scalar-color
continuation for non-scalar returns or mutation. Nothing memoizes callback
results or changes the callback's arguments, arity, this handling or exceptions.

## Three outcomes and observation order

1. **Decline before context.** Touched resolver slots, a replaced private plan or
   nonmatching keys return null. Config takes its existing general path, which
   creates the context once. An old captured plan cannot authorize a new plan.
2. **Context invalidates the attempt.** After the original/prepared context
   factory runs, check the Config generation, private plan identity and original
   key snapshot, just as the previous helper did. On failure, continue the
   ordinary post-context branch with that same context. Do not retry native
   resolution or invoke either context factory again.
3. **Execute the prepared plan.** Call the existing _resolveScalarColors. It
   clones fresh options, visits varying callbacks in order and checks resolver
   mutation after each callback/store. Non-scalar values and mutation resume
   from the existing original-key continuation with its descriptor snapshot.

NativePointResolution still performs its complete source validation before this
executor. Owner/class checks remain in the controller. The post-context checks
are intentionally the previous post-context checks, not a new full-source scan:
a change during context must retain the old operation's keys and continuation.
The private Config helper accepts an already-observed context/result record only
on this failure path, skipping another native attempt while preserving the
ordinary resolver/view creation and key walk.

All closures and captured references belong to one native line loop. Mutable
resolver state is not shared between calls: contexts and returned options remain
local, including reentrant callbacks. Indexed plans, unsupported colors and
contextual functions retain ordinary resolution. Data-only eligibility and the
canvas layer are unchanged.

## Evidence and validation

Fresh native profiles place about 18% of sampled stacks in Config option
resolution with 200 labels, including about 15% in scriptable resolution and
8% in the scalar callback path. The stress callback itself accounts for about
5%. Inclusive shares overlap. A direct-plan prototype improves matched mean UI
by approximately 1 ms and passes the existing callback/invalidation regressions.

New native-vs-ordinary twins cover context-time clear/write/key changes, prepared
context invalidation, replacement plans, callback-time middle/trailing field
changes, descriptors, deletion, clearing, null/undefined/array/object returns,
exceptions and reentrant resolution. Final VM/browser/port results, frame-time
comparisons and the complete native mode matrix are recorded in
[the verification report](../benchmarks/scriptable-headroom/README.md).
