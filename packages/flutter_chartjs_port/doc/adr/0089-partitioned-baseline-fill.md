# 0089 — Native compound paths for dense curved baseline fills

- Status: accepted
- Date: 2026-11-05

## Decision

Keep the upstream filler path construction. After it closes the original path,
an eligible native canvas can fill an equivalent compound path instead. The
original current path remains available to subsequent strokes, clips and custom
draws. Curve control points are reused unchanged, never fitted per partition.
The alternate path uses at most 32 cubic segments per contour and a shared
horizontal baseline, with one nonzero fill operation. No points are removed.

`PartitionedFillCanvas` is an internal optional capability, following the native
rectangle-bar capability. `UiCanvasContext` owns its alternate builder and native
paint/state checks. The filler helper owns one geometry preflight; it checks
native line/segment/point/list types, resolved ordinary curved-line options,
full source range, finite strictly increasing x coordinates, control points
within each segment's x interval, and a single-sided constant private boundary.
Total vertical variation must exceed 16 times the point y range, excluding
flat, monotone and gently varying curves from the extra path construction.
Only equal-color origin/start/end x-axis fills qualify. Source styles, gaps,
stops, loops, decimation, partial ranges, stepped/straight/foreign options,
dataset/stack/shape targets, gradients, non-source-over blending, rotated or
singular transforms and observable canvas lifecycle hooks retain the old path.

The canvas declines before invoking the alternate writer when unsupported.
The color comparison is evaluated once, at its original observation point.
The plan performs no user point/list/option getters during its preflight.
There is no global cache of chart geometry. The test-only enable switch and draw
counter support differential verification without a new public chart option.

## Costs and validation

The original path is still built to preserve Canvas 2D semantics. This costs an
additional validation walk and alternate path construction, and retains a second
native path builder. The GPU benefit must therefore be measured together with
full chart-update CPU cost, not only Flutter's UI-build timing.

Software Skia pixel twins permit at most 3/255 channel difference at antialiased
pixels, fewer than 200 differing pixels in the 160-square test, no solid-area
differences and relative ink error below 0.0002. Native beta correctness and
performance are recorded separately; this is not a universal pixel-identity or
every-device frame-rate guarantee. These are ordinary differential images, not
updates to the platform-pinned theme goldens.

See performance.md §62 and the benchmark application's diagnostic report.
