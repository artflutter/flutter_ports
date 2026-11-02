# Chart.js ADR 0067: Scalar geometry for ordinary bar drawing

- Status: implemented; macOS performance and VM/browser equivalence validated.
- Date: 2026-11-02
- Related: ADRs 0017, 0054 and 0066; performance.md §34.

## Decision

For the exact built-in BarElement with final BarOptions and BorderSkipped
objects, a numeric zero border radius, positive-zero inflation, a finite scalar
border width and finite positive outer bounds, calculate the outer/inner rectangle
coordinates with scalar locals. Clamp each non-skipped border to half its side,
in the original arithmetic order. Read current animated coordinates afresh on
every draw. The unused dimension may remain undefined/NaN, as it does during a
vertical bar's looping animation; only the computed bounds must be valid.

Keep the existing canvas calls and their order: save, the optional border path
and even-odd fill, the inner path and fill, then restore. Retain the empty inner
fill, the final current path, the color-setter timing and the signed-zero outer
coordinate arithmetic of inflateRect. No fillRect substitution, batching,
aggregation, culling, option cache or new canvas capability is introduced.

The type guards precede comparisons of raw values, so a user object cannot gain
an extra equality/getter call. Typed option and edge fields have ordinary getters
in final classes. Subclasses, raw/custom option or edge objects, non-scalar border
widths, absent values, radii, inflation (including negative zero), non-finite or
degenerate outer geometry retain the original boundingRects/draw path. Negative
finite scalar border widths still clamp to zero. No user callback is skipped.

## Reason

After ADR 0066, ordinary bar drawing still costs about 14 ms at 20,000 bars.
A fresh CPU profile attributes 13.4% of the full draw call to boundingRects,
with further cost in radius checks, inflateRect and allocation. This ordinary
case does not need corner objects, two RoundedRects, inflated copies, or repeated
numeric conversion and final-property dispatch. Scalar calculations remove those
costs while leaving the renderer's operation contract intact.

Keep the generic upstream structure beside the narrow branch so bumps and
unsupported behavior remain reviewable. The adaptation is tracked by
`adapt-rectangular-bar-draw`. On an upstream bump, recheck getBarBounds,
parseBorderWidth, parseBorderRadius, boundingRects, inflateRect and draw.

## Validation

The original path is the reference for exact canvas-call and pixel comparisons:
a subclass deliberately fails the exact-class guard. Traces cover both
orientations, every skipped-edge mask, clamped/negative borders, thin and zero
sizes, reversed values, signed zeros, non-finite/overflow inputs and fallbacks.
Tests also check custom getter order and an object with effectful equality.
Pixel twins cover opaque/translucent colors, fractional transforms, clipping,
styles after draw and a stroke of the retained current path.

The prewritten A/B/B/A protocol and all measurements are in benchmarks/bar-draw/.
The preliminary scalar version is retained separately from the final guards for
degenerate geometry and negative-zero inflation. Performance and foreground FPS
outcomes are recorded in performance.md §34.

At 20k, draw-only calls improve 15.3% and animation frame CPU 15.1%; both pairs
meet the predeclared gate and controls remain within limits. Foreground animation
improves 48.88 → 58.43 FPS, approaching but not sustaining 60 FPS. All workspace
tests, the ten targeted cases on each of JavaScript and WebAssembly, fixtures,
analysis, formatting, parity and port checks pass. No golden image is changed.
