# Chart.js ADR 0166: The bulk point loop of a scatter update

- Status: accepted
- Date: 2026-11-18
- Supersedes: nothing
- Related: [Chart.js ADR 0109](0109-previous-x-of-the-gap-test.md), [Chart.js ADR 0152](0152-fast-bar-loop-modes-datasets-stacks.md), [Chart.js ADR 0165](0165-held-element-options.md)

## Context

A data-only update of a scatter chart runs `updateElements` for each point: about eight calls of the property
writer, two reads of the parsed item through the item interface, two virtual pixel calls of the scales and the
qualifier of the gap test. The scatter profile of 2026-11-18 put `updateElements` at 32-38% of the data-only update
of 20,000 points on the macOS app, the iPhone and the Pixel. The bar controller has a fast loop for the same case
(Chart.js ADR 0152). It needs the rule that no app code runs inside the loop.

## Decision

1. **The run.** In a direct update of the exact `ScatterController`, after the first two passes, a pass whose
   previous pass held its x (Chart.js ADR 0109) and whose loop holds an option cache entry (Chart.js ADR 0165)
   starts a bulk run. The loop-wide guards are those of the gap reads (the exact chart, the native linear projection
   of both scales, native lists, no stack, no segment), unshared options and the axes `x` and `y`.
2. **One pass.** Each pass of the run is a pass of the loop: the same reads, pixels, writes, options call and gap
   test, in the same order. The writes are the typed setters of the exact point. The pixel of a number is the
   expression of `getPixelForValue` of `LinearScale` and of `getPixelForDecimal`, with the inputs of the scale read
   once for the run (`LinearPixels`); an aligned pixel calls `getPixelForDecimal`.
3. **No app code.** A pass starts only for an exact point that is not active and a native parsed item: its reads
   and its pixels run no app code. A value that is not a number ends the run before any write, and the pass of the
   loop reads it again: the reads of a native item are not observable. An options call that does not take the held
   entry of a class value can run app code: its pass is the last of the run, as the pass of the loop holds no x
   after it. Thus no input that the run read once can change inside the run.
4. **No change of a result.** The points, the options objects, the contexts, the gap tests and the reads of the
   objects of the app are the upstream ones. No value outlives the run.

## Rejected

- A preflight pass over the range: the per-pass tests before the writes give the same proof with one pass.
- The bulk run in an animated update: each point calls the animations, which can run app code.

## Consequences

- A new statement in the pass of the scatter loop must be in the run, or end it.
- A change of `getPixelForValue` of `LinearScale` or of `getPixelForDecimal` must change `LinearPixels` in step.

## Open

1. No run timed the production form. The switch `ptbulk` of the measurement branch of 2026-11-18 gives the pair.

## Tests

`test/port/controllers/scatter_bulk_points_test.dart`
