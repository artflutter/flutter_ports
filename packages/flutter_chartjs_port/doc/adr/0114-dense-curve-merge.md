# Chart.js ADR 0114: The merge of the narrow curves of a dense line

- Status: accepted (2026-11-11, by the porting lead). The code and the tests of section Tests pass. The maintainer
  approved the decision on 2026-11-11, with the two choices of section Decision, item 6.
- Date: 2026-11-11
- Supersedes: [Chart.js ADR 0089](0089-partitioned-baseline-fill.md). This record states the complete decision of the
  partitioned fill, with the merged vertices (section "The partitioned fill").
- Related: Chart.js ADRs [0034](0034-no-display-only-js-exactness.md) (no display-only exactness),
  [0104](0104-line-curve-draw.md) (the draw of a curved line) and [0113](0113-stroke-pieces-by-browser-system.md)
  (paths in pieces on the web). Measurements: [performance.md](../performance.md) §73.
- Rows of `differences.md`: `adapt-dense-curve-merge` (new), `adapt-partitioned-baseline-fill`.

## Context

A line with curves (`tension` above 0, or `cubicInterpolationMode: 'monotone'`) writes one cubic curve between each
two points. At 20,000 points on a chart of 2,000 bitmap pixels, one curve covers a tenth of a pixel. The engine still
does the full work for each curve, and the stroke of these curves is the largest cost of a large line chart on each
target (the night run of 2026-11-11, performance.md §73):

- Impeller tessellates each curve again in each frame: 70.5% of the raster thread of the Mac app and 74.8% on the
  Pixel 8a for the full line chart of the benchmark lab at 20,000 points. A still chart pays the same, because the
  engine keeps no geometry of a retained picture.
- On the web, Skia makes an outline of the stroke on the CPU in each frame, and with dart2js each curve is one call
  into CanvasKit of about 130 ns.

A straight line of the same data is cheap. The upstream `fastPathSegment` (`element.line.js:118`) merges the points of
one pixel column into at most four line commands. Upstream uses it only for a line with no tension, no monotone mode,
no steps and no dash. So upstream has no merge for a dense curve, and a browser canvas pays the same cost there.

## Decision

On a native canvas context, a line with curves writes each narrow curve as lines, and merges the vertices of one
bitmap pixel column. Each other curve goes out as upstream writes it. A chart whose curves are all wider than the
threshold is byte-identical.

1. **A narrow curve.** A curve is narrow when its two ends and its two control points lie within half a bitmap pixel
   in x (`denseCurveThreshold`, 0.5, divided by the x scale of the transform of the context), each of its eight
   numbers is finite, and both of its points are of the class `PointElement` itself. A line of even x steps starts to
   merge at 2 points for each bitmap pixel: at 3,881 points on a chart of 1004 logical pixels at ratio 2, and at 1,666
   points on a chart of 351 logical pixels at ratio 2.625.
2. **The lines of a narrow curve.** The curve goes out as lines through its start, its 0 to 2 extremes in y and its
   end. These points are on the curve. So a peak keeps its height, and an edge moves sideways by at most the
   threshold.
3. **The merge of a column.** The vertices of the narrow curves go into bitmap pixel columns (`floor(x * scale)`).
   A column with more than 3 vertices after its first keeps four: the first, the one with the smallest y, the one
   with the largest y and the last, in the order of the path, each at its own place. The merge never adds a command.
   A curve that is not narrow ends the column: its start is the last vertex.
4. **The ends.** The first and the last curve of a run stay curves, so that the caps of the stroke follow their
   tangents. The path starts and ends on the exact points.
5. **The join.** The stroke of a path with merged curves takes round joins, not `borderJoinStyle`. The curves of a
   line meet with one tangent, so the join style shows nowhere on them, and the turn inside a curve is round. Lines
   in their place have a corner at each vertex: a miter adds a spike, a bevel cuts the peak. With the join of the
   options, 7,824 pixels differ by more than 64 of 255 at 20,000 points, and 8% of them are outside the line.
6. **The guards.** The line keeps the upstream commands, as a whole, when one of these holds:
   - the context is not the native one (a recording context of a test, a context of user code, a `Path2D` that
     user code gives to `path`), has a transform that is not axis aligned or not invertible, or has a shadow
     (`DenseCurveCanvas.denseCurveScale` is null);
   - the line is not of the class `LineElement` itself, or its options are not typed `LineOptions`;
   - the line method is not the cubic curve (a straight or a stepped line);
   - the line has a dash, is decimated, or is a loop;
   - **the line has no border**: `borderWidth` is falsy, the test of `draw`. The fill of such a line has no line over
     its edge. On the Pixel 8a, 25% of the colored pixels of such a fill at 20,000 points change by up to 26 of 255
     with the merge. The maintainer chose to keep the old drawing there (2026-11-11).
   The monotone mode takes the merge. It has about twice the edge difference of the default mode (section Evidence).
   The maintainer chose to accept it (2026-11-11).
7. **Where it applies.** `_getSegmentMethod` of `element.line.dart` gives `_denseCurveSegment` in place of
   `_pathSegment`. So the stroke, `path`, `pathSegment` and the fill of the filler, which reads `pathSegment`, take
   the same vertices, in both walk directions. The stroke path that the line keeps (`_path`) holds the merge of one
   bitmap scale: a draw on a context with another scale, or with none, builds it again. Hit tests, `interpolate`,
   `getProps` and the tooltip read the points, not the path: they do not change.
8. **The switch.** `denseCurveMergeEnabled` (the define `CHARTJS_DENSE_CURVE_MERGE`, default true) and the counter
   `denseCurvesMerged` serve the twins. They are not chart options.

### The partitioned fill

This is the complete decision of Chart.js ADR 0089, with one change: the partitions take the merged vertices.

Keep the upstream filler path construction. After it closes the original path, an eligible native canvas can fill an
equivalent compound path instead. The original current path remains available to subsequent strokes, clips and custom
draws; it stays out of the engine until a read (Chart.js ADR 0104). The alternate path has contours over a shared
horizontal baseline, with one nonzero fill operation.

- When the line keeps its curves (item 6), each contour has at most 32 cubic segments. Curve control points are
  reused unchanged, never fitted per partition, and no point is removed.
- When the line merges its narrow curves, the contours take the vertices of `writeDenseCurve` for the whole point
  list, the same vertices as the original path. A contour closes after each 32 commands, and the next one starts at
  the same vertex. `denseCurveScaleOfLine` gives the decision of the line, so the fill and the stroke agree.

`PartitionedFillCanvas` is an internal optional capability. `UiCanvasContext` owns its alternate builder and native
paint and state checks. The filler helper owns one geometry preflight; it checks native line, segment, point and list
types, resolved ordinary curved-line options (a finite positive tension, no steps, the default interpolation mode),
the full source range, finite strictly increasing x coordinates, control points within the x interval of each
segment, and a single-sided constant private boundary. Total vertical variation must exceed 16 times the point y
range, which excludes flat, monotone and gently varying curves from the extra path construction. Only equal-color
origin, start and end x-axis fills qualify. Source styles, gaps, stops, loops, decimation, partial ranges, stepped,
straight or foreign options, dataset, stack and shape targets, gradients, non-source-over blending, rotated or
singular transforms and observable canvas lifecycle hooks retain the old path.

The canvas declines before invoking the alternate writer when unsupported. The color comparison is evaluated once, at
its original observation point. The plan performs no user point, list or option getters during its preflight. There
is no global cache of chart geometry. The test-only enable switch and draw counter support differential verification
without a new public chart option.

### What the other records keep

- Chart.js ADR 0104: the packed cubic curves of `Path2D`, the deferred original path of the filler and the circle run
  do not change. A path with merged curves holds line commands in place of most curves.
- Chart.js ADR 0113: on the web, the stroke of the kept `Path2D` and the fill columns take the merged path as they
  take each other path. A merged fill still passes the shape test of `tryFillColumns`.

## Evidence

**Timing.** The benchmark lab, type `line`, live data, the full line (markers, curve with tension 0.35, fill, tick
labels, grid, legend), profile builds, two runs for each side. Raster mean for each frame, and FPS:

| Target | Points | Raster, curves | Raster, merge | FPS, curves | FPS, merge |
| --- | ---: | ---: | ---: | ---: | ---: |
| Pixel 8a (Impeller on Vulkan) | 20,000 | 17.5 ms | 6.4 ms | 55 | 94 |
| Pixel 8a | 10,000 | 9.8 ms | 5.6 ms | 98 | 120 |
| Pixel 8a, a still chart under moving content | 20,000 | 14.5 ms | 5.0 ms | 69 | 120 |
| Chrome 157, dart2wasm (skwasm) | 20,000 | 19.7 ms | 7.9 ms | 51 | 120 |
| Chrome 157, dart2wasm | 10,000 | 12.0 ms | 3.7 ms | 82 | 120 |
| Chrome 157, dart2js (CanvasKit) | 20,000 | 15.2 ms | 3.8 ms | 30 | 68 |
| Chrome 157, dart2js | 10,000 | 9.7 ms | 3.1 ms | 53 | 98 |

The chart draw on the UI thread at 20,000 points falls from 9.2 to 5.7 ms on the Pixel 8a, from 6.9 to 3.7 ms with
dart2wasm and from 12.5 to 5.5 ms with dart2js. The cell with 1,000 points does not move on any target. The stroke
path of 20,000 commands has 7,394 commands with the merge on the desktop chart and 3,278 on the phone chart.

**Pixels on a phone.** Pixel 8a, a still chart of 351 x 300 logical pixels at ratio 2.625, one screenshot with the
merge off and one with it on, compared in the chart area (1000 x 810 pixels):

| Chart | Pixels that differ | Share of the colored pixels | Largest step of 255 |
| --- | ---: | ---: | ---: |
| 20,000 points, the full line (markers, fill, axes, legend) | 0 | 0% | 0 |
| 20,000 points, the curved line alone | 2,639 | 1.5% | 176 |
| 2,000 points, the curved line alone | 3,075 | 1.8% | 176 |
| 20,000 points, a fill with `borderWidth: 0` (excluded by item 6) | 101,284 | 25% | 26 |

Each pixel that differs in the first three rows is on the edge of the line. Impeller has 4 coverage levels for an edge
pixel, so each difference there is 44 of 255 or more. The rows are from the prototype with no guard for a line with no
border. The shipped code repeats the first two rows with the same counts (0 and 2,639), and the fill with
`borderWidth: 0` then differs in 0 pixels.

**Pixels on the test engine** (software Skia). The curved line alone, the merge off against on; the count of the
pixels that differ, and its share of the pixels with a line color:

| Chart | Desktop size, 5,000 points | Desktop size, 20,000 | Phone size, 5,000 | Phone size, 20,000 |
| --- | ---: | ---: | ---: | ---: |
| Default curve | 11,883 (3.7%) | 3,534 (1.0%) | 2,352 (1.7%) | 1,726 (1.2%) |
| With markers and a fill | 2,210 | 27 | 46 | 0 |
| Monotone mode | 17,122 (5.3%) | 5,993 (1.8%) | 3,298 (2.4%) | 3,210 (2.3%) |
| Gaps in the data | 10,881 (3.7%) | 3,857 (1.2%) | 2,484 (2.0%) | 2,216 (1.7%) |
| Gaps with `spanGaps` | 11,172 (3.8%) | 4,232 (1.4%) | 2,801 (2.2%) | 2,481 (1.9%) |
| A fill to another dataset | 11,931 (2.7%) | 3,654 (0.8%) | 2,416 (1.3%) | 1,957 (1.1%) |
| Segment colors | 12,887 | 4,133 | 3,183 | 2,445 |
| A horizontal chart (`indexAxis: 'y'`) | 57 | 59 | 92 | 55 |

Two frames of an animation between two data sets, 1% of the duration apart: in each of 12 cases, fewer pixels change
from one frame to the next with the merge than with the curves (for example 727 to 1,213 against 820 to 1,266 at
20,000 points on the phone size). So the merge adds no shimmer.

## Tests

`test/port/elements/line_dense_curve_test.dart` (VM): the same bytes below the threshold; the ends, the extremes and
the command count of the merged path; the merged picture against the curves for 9 chart variants at 5,000 and 20,000
points on two chart sizes, with each differing pixel within 2 pixels of a pixel with a line color, fewer than 8% of
the band and fewer than 0.6% above 64 of 255; the same in pieces, the form of the web; the same bytes for a line with
no border and for a dashed line; each guard of the context and of the line; and the two frames of an animation.
`test/port/plugins/plugin.filler/partitioned_baseline_fill_test.dart` compares the partitions with the original path.

## Consequences

- A dense curved line and a dense curved area chart draw 2 to 4 times faster on the raster side from about 2 points
  for each bitmap pixel. Below that count nothing changes.
- The pixels of the edge of such a line differ from the curves of upstream, within the bounds of section Tests.
- A merged line has round joins. An app that sets `borderJoinStyle` sees it only on a line that keeps its curves.
- Code that reads the kept path of the line after a native draw (`line['_path']`) sees line commands.

## Open

1. The iPhone and the Mac app have no screenshot comparison and no timing with the merge. A model of the Impeller
   vertex counts gives about 8.4 to 2.7 ms on the Mac and 7.9 to 2.5 ms on the iPhone for the full line at 20,000
   points: a derived figure.
2. A horizontal chart gets almost no merge: the test of a narrow curve reads x only. A loop (radar), a dashed line,
   a line with a shadow and a rotated chart keep their cost.
3. A line with a transparent border color and a visible width takes the merge. Its fill then has no visible line over
   its edge, as in the excluded case.
4. With skwasm, the fill of a merged path adds about 3 ms of raster time at 20,000 points, where a straight fill adds
   0.1 ms. The cause was not examined.
5. On the web, the round join costs time: the line alone reads 3.5 ms with round joins and 2.1 ms with the join of
   the options at 20,000 points with dart2wasm.
6. The twins do not run in the CI job on Impeller. The evidence for that engine is the screenshots of the Pixel 8a.
