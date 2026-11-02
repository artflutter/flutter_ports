# Chart.js ADR 0069: Guarded bulk numeric bar updates

- Status: implemented; macOS performance and VM/browser behavior validated.
- Date: 2026-11-02
- Related: ADRs 0054, 0068; performance.md §36.

## Decision

Keep the first ordinary item of updateElements so options and callbacks resolve
at their original points. In mode `none`, preflight the remaining range before
any bulk write. If any condition fails, run the ordinary loop for the remainder.
There is no partial bulk write followed by a fallback.

The fast path requires the exact BarController, a chart explicitly guaranteeing
ordinary context/pixel-ratio/visibility reads, native arrays, exact native bar
writes, finite numeric ParsedItems without custom or stack slots, shared
BarOptions, a uniform grouped category calculation, and a native linear value
scale owned by that chart. It also requires the live single-dataset proof of
ADR 0068. The owner check now rejects an index scale from a different chart.

Only already-cached scalar options qualify. Missing cache entries never resolve
merely to qualify. An absent minBarLength value converts to NaN and disables the
minimum-length branch; null and nonpositive/NaN numbers also leave it inactive.
Positive minimum lengths, flex thickness, indexed stacks, unsupported options,
custom elements/controllers/scales and scriptable element options retain the
ordinary path. Non-representable integer bases are rejected so tick equality
keeps its original behavior.

Native scale grid qualification checks cached display settings and a raw numeric
lineWidth in the underlying resolver. Hidden/disabled grids need no tick reads;
visible grids additionally require ordinary descriptors/setContext and a native
Tick list. Scriptable/indexed grid widths retain their per-item callbacks. The
first bulk item's normal grid lookup still creates/observes its context at the
original point, then its constant result is reused within the callback-free loop.

Preflight captures numeric values in one Float64List. The loop reuses scalar
settings and base projections, retains the original floating-point operation
order (including signed-zero/grid adjustments), computes each center and size,
and writes the native element fields directly in their original order. It still
queries data visibility and gives every bar a fresh BorderSkipped object. Shared
option identity, undefined bits, active state and existing animations are kept.
No data is aggregated or dropped, and parsing/layout/hooks still execute.

The exact-class bulk guards use the superclass runtime type, so qualification
does not call a custom runtimeType getter. Unknown subclasses do not opt in by
default. The final gallery timing wrappers explicitly opt in; custom code that
implements these internal capabilities must satisfy their native-read/write
contracts. Array classification follows the existing native runtime-type guards.

## Evidence and validation

The protocol is benchmarks/bar-bulk/protocol.md. Initial activation tests caught
an overly restrictive guard that rejected the default undefined minBarLength.
That candidate ran no bulk writes; its timings are retained as preliminary.

Twins cover both orientations and visible/hidden axes, border/base/reversal
settings, visibility, fresh edge objects, partial ranges, reset, late unsupported
data/elements, scriptable colors/grids, custom scale/controller interception,
mutation in the first ordinary item and foreign scale ownership. A test-only
native-write opt-in counts writes while delegating to the production writer.
The reference Chart retains ADR 0068 but disables bulk updates.

Final timings, monitored foreground FPS, browser checks and repository validation
are recorded in performance.md §36 and benchmarks/bar-bulk/.

The final full 20k update improves 28.5%, 37.582 → 26.876ms. Update computation
falls 22.872 → 10.382ms and dataset updating 18.212 → 4.704ms. Both A/B pairs
pass the gate; controls remain within limits. Monitored foreground updates rise
23.88 → 31.12 FPS, with every activity check true and 24 windows per process.
All workspace tests, thirteen targeted tests on each browser backend, fixtures,
analysis, formatting, parity and port checks pass. No golden image changed.
