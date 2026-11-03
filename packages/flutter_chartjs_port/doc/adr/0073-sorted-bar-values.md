# Chart.js ADR 0073: Linear duplicate removal for sorted bar values

- Status: implemented; macOS performance and VM/browser behavior validated.
- Date: 2026-11-03
- Related: ADRs 0068, 0071, 0072; performance.md §39.

## Decision

After the original visible-dataset enumeration and concatenation, the bar
controller owns a native List of doubles. Scan this list for finite nondecreasing
values and count distinct adjacent values. When all values differ, return the
original list, preserving its identity and any negative zero. When duplicates
exist, create a growable result in the original order and normalize every zero
to positive zero, exactly as arrayUnique's Set-backed branch does. The input is
never mutated by this shortcut.

An unsorted or nonfinite list declines the shortcut and retains the original
sort and arrayUnique behavior. The scan replaces the existing ordered-value
check, rather than adding another complete preflight to the common unique case.
User controller calls and custom container enumeration remain at their original
points before concatenation; the helper examines only the owned result. The
shared generic arrayUnique implementation is unchanged.

This is implemented and measured independently after the position-reuse
prototypes of ADR 0072 were rejected and removed. No projection calls are skipped,
no geometry is cached, and no bar is removed or approximated.

## Validation

Reference twins compare values, identity, zero signs and input mutation against
arrayUnique. They cover empty/single/unique/repeated values, extreme finite
numbers, growable output, dense 20k indexes, and unsorted/nonfinite fallback.
Bar geometry references and specifications run unchanged. VM, JavaScript and
WebAssembly tests cover the new helper; performance evidence is retained in
benchmarks/bar-spacing/ against the unchanged 3d10094 baseline.

Full 20k updates improve 2.4%, 20.100 → 19.620ms, passing the 2% gate in both
pairs (2.3%, 2.5%). Dataset updating improves 11.8%. Foreground updates rise
39.06 → 42.87 FPS; every activity check passes. No control exceeds the declared
repeatable-regression threshold. Workspace tests, both browser backends,
fixtures, analysis, formatting, parity and port checks pass.
