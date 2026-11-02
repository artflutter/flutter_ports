# Chart.js ADR 0066: Bound native canvas recordings

- Status: implemented; macOS performance and VM/browser correctness validated.
- Date: 2026-11-02
- Related: ADR 0055; bar-performance.md; performance.md §33.
- Supersedes the picture-count flattening rule of ADR 0013; other canvas decisions remain.

## Decision

Keep the Canvas 2D API, drawing operations and paint order unchanged. End a native
picture after 256 non-batched paint calls, at the end of the call's native
save/transform/draw/restore sequence. The next recorder replays the logical clip
stack using the existing mechanism. The current path, styles, transform, clip
state and content notifications survive a split. Full-circle runs retain their
existing batching and do not consume the split budget.

A paint generation is the content added since the last paint or snapshot ended
it. All internal picture chunks of that generation count once. Painting without
new content does not create a generation. After more than eight retained
generations, paint rasterizes the content once and retains that image as one
generation. Full clear, resize and disposal reset the counters and release the
retained pictures. Snapshots finish the current generation and rasterize every
chunk in order. The number of drawing operations in one generation was already
unbounded; splitting adds a small picture header per chunk rather than changing
that input bound. Retained history remains limited by the same eight completed
paint/snapshot batches as before.

Partial clears and non-source-over operations still cause the complete bitmap to
paint within one host layer; a picture split does not add an isolation layer or
change blending. Small generations keep a single picture. No bar aggregation,
option/callback cache, change in animation interpolation, frame dropping or
reduction in chart data is introduced.

## Reason

Flutter's native drawPicture consolidates the child picture's spatial-index
bounds when embedding it in another recording. The 20,000-bar workload spends
about 50 ms there, separately from chart update and draw. The independent native
experiment in bar-performance.md reduces that cost to about 3.4 ms with 256-rect
pictures and preserves all tested RGBA pixels. A literal eight-picture limit
would immediately flatten a large split frame, so retention must count logical
generations rather than implementation chunks.

The limit counts completed non-batched paint calls rather than native operation
inspection; a path may hold many primitives and circle batches keep their
existing flush rules. This targets the many separate bar fills without breaking
the efficient point batch. It is not a hard cap on native operations or bytes.

## Validation

The prewritten protocol is benchmarks/bar-implementation/protocol.md. Tests compare
split and unsplit visible operations, including all composite modes, gradients,
patterns, text, images, strokes, clip/transform boundaries and partial clears.
Other tests pin snapshots, resize, full clear, generation flattening, repeated
paints and circle batch order. Existing canvas and bar pixel tests also run.
Performance and foreground FPS outcomes are recorded in performance.md §33.

At 20,000 bars, full update CPU improves 44.5% and animation frame CPU 73.0%.
Foreground FPS improves from 8.33 to 15.00 for updates and 12.72 to 49.42 for
animation. The A/B/B/A gates and control comparisons pass. All workspace tests,
32 targeted cases on each of Chrome JavaScript and WebAssembly, fixtures,
analysis, formatting and port checks pass. No golden image is changed.
