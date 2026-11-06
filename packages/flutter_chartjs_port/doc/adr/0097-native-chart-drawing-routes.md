# Chart.js ADR 0097: Native drawing routes of live charts

- Status: proposed
- Date: 2026-11-06
- Related: Chart.js ADRs 0034, 0055, 0066, 0070, 0084, 0089; [differences.md](../differences.md) rows
  `adapt-native-arc-sector`, `adapt-sector-run-seams`, `adapt-circle-fill-ladder` and
  `adapt-point-style-circle`.

Measurements: performance.md.

## Decision

Five native routes for a chart that redraws each frame. The ordinary canvas calls of the ported
code stay for each case that a route does not take. No route has a switch.

### 1. The pictures as scene pictures

`RenderChartHost` is a repaint boundary, so its ancestors already take a layer of it. On the native
engine, when the content needs no isolating layer, the host adds a small `ChartPicturesLayer`. Its
`addToScene` pushes the transform of the host and the clip to the bitmap, and calls `addPicture` for
each picture of the context. A recording canvas with a spatial index no longer merges the regions
of each picture on the UI thread (`DisplayListBuilder::DrawDisplayList`,
`searchAndConsolidateRects`).

- **Fallback.** A partial clear or another composite operation (`_needsLayer`), a scale or an offset
  that is not finite, a scale of 0 and the web keep `UiCanvasContext.paint` and `drawPicture`. The
  web has no such merge. `paint` keeps its contract.
- **Lifetime.** The layer holds no picture. `addToScene` reads the pictures that the context holds
  at the call, so it never touches a disposed picture. An engine layer keeps its own reference to
  each picture, and a clean layer is retained. The context never needs to retire a picture.
- **Pixels.** The same pictures, transform and anti-aliased clip. They are byte-equal on
  `flutter_tester` at fractional offsets and at device pixel ratios of 1, 2, 2.625 and 3, with one
  and with several pictures. An ancestor `ShaderMask` with a gradient at a fractional offset is the
  exception: pixels under its gradient can differ by 1 of 255. In the cases tried, it needs content
  with an edge on a whole device pixel at that offset. The bounds that the mask gets for its child
  may explain it; the cause is not established. A test pins the bound. 240 snapshots of a real chart
  under 15 kinds of ancestors show no other difference.
- **Raster, from the engine source; not measured here.** The frame dispatches the same nested
  display lists, one level less deep. Each picture adds one layer: a `Preroll`, a save, a zero
  translation and a restore. A partial repaint walks the children once, with a deep compare only for
  a list below 10 KB of equal size and bounds. Impeller has no raster cache.
- **A difference on the Skia backends.** More than one picture sets `willChangeHint`: a raster cache
  entry for each picture would keep one bitmap of the chart for each picture. Thus a chart of at
  least 256 draws that stays static, under other content that animates, is no longer cached as one
  bitmap there. Impeller is not affected. Pixels do not change.

### 2. The scalar arc route

An optional `ArcSectorCanvas`, as `RectBarCanvas` for bars. For the exact `ArcElement` with
`ArcOptions`, a circular arc below a full turn, no offset, no spacing, a numeric `borderRadius` of 0,
a plain `borderWidth` of 0 and not the inner border alignment, the element computes the two end
angles of `pathArc` and offers the sector with scalars. `pixelMargin` and `fullCircles` are written
first, as in the ordinary code.

The native context declines before any state change for: a disposed context; an `onChanged` that the
next draw would call; a picture or image observer; a transform that is no similarity; a color that
is not an exact valid sRGB `Color`, for the fill and for the `strokeStyle` setter; and geometry where
the ordinary path might not be a sector (outside 100000 bitmap pixels or 1000 radians, or a ring
width below 0.001). Thus an accepted arc is a sector on the ordinary path too, and the fused fill has
its numbers.

The ordinary path stays as the current path. A pending sector keeps the arguments and a copy of the
transform. The first later command or read of the path writes the commands of `pathArc`, in order,
with the same values. The logical styles, the save depth, the clips and the transform do not change.

For the exact class, a native canvas also skips `translate` and its trigonometry for an offset of 0
on a finite matrix, through `zeroTranslateIsNoOp`. A recording context keeps the call, and a user
subclass keeps the call and its reads of the angles.

`draw` skips `fix` for an offset of 0, on each context, because `offset * fix` is 0. A circumference
of -Infinity is the exception: `Math.sin` gives NaN, so upstream has a radius offset of NaN and an
arc with no radius. It keeps that computation, and the element offers no sector for it.

### 3. The run of adjacent sectors

Fused sectors of one result color, one center, one pair of radii and one rotation, where each starts
within 1e-9 radians of the end of the last, in the `srcOver` mode, collapse into one `drawArc` below a
full turn. Any other draw, a clip with its restore, the end of a recording and a full clear end the run.
The flush uses paints of its own, so it cannot disturb a fill that waits on `_fillPaint`.

**The difference.** The separate fills of upstream show anti-aliased seams between the slices. The
run has none. At slices above a pixel only the seams differ: at most 74 of 255 at a contrast of 204
on `flutter_tester` (Skia on the CPU). At slices far below a pixel the difference covers the whole
disc: 199 of 204 at 20000 slices, where each separate fill adds little in 8 bits and leaves a pale
disc, and the run draws a solid one. Display-only (Chart.js ADR 0034): hit tests, options and
tooltips read the elements. Slices of different colors keep exact pixels. `drawVertices` stays out:
it has no analytic anti-aliasing on the outer edge.

### 4. Fills with varying radii

A run of fills takes another radius while it has no stroke, when it is below 16 fills or already
varies. It keeps a radius for each instance. Below 64 fills it draws `drawCircle` with the exact
color of each fill: the pixels of separate fills. At 64 fills and more it draws one atlas with a
color for each instance, in order.

The atlas holds white masters for a fixed ladder of radii, each 1.1 times the last, from 2 to 48
bitmap pixels, at two master pixels for each bitmap pixel. A radial gradient paints the coverage of
a master: a ramp of one bitmap pixel across its radius. The transform of each instance has the exact
radius in its scale and the exact center. The atlas is about 2 MB and is built once.

A rasterized edge in a master was rejected: a scaled copy at one master pixel for each bitmap pixel
blurs the edge by the phase of the sampling, and at two master pixels the edge is too sharp.

**The colors.** A batch reads a color as 32 bits of sRGB (`toARGB32`). A color in another color
space, or with a channel that is not finite, joins no batch: `_batchCircle` declines it, and the
fill or the stroke draws `drawCircle` with its exact values. This holds for each run, also for a run
of one radius, which before this decision drew a wide-gamut color with its raw channels as sRGB.
Thus only an sRGB color reaches the atlas. There it has its 8-bit form: for a color with more bits,
such as an alpha of 0.5, a solid pixel differs by at most 1 of 255.

**The radii.** The ramp of a master is one bitmap pixel wide at each radius, so the area of a master
is pi (r^2 + 1/12): 2 % over the area of the circle at a radius of 2, and 23 % at a radius of 0.6.
Thus a radius below 2 keeps `drawCircle`, in runs of one radius. A chart with such radii has no gain
from the ladder.

**The bound.** The figure of 46 of 255 of Chart.js ADR 0055 belongs to its one radius of 3 in its
color. The accepted form of §8.5 reaches much more on other radii, because Skia on the CPU has its
own error for a circle. Thus the test compares both forms with `drawCircle` on the same random
radii, at full contrast. Each row gives the worst of 12 grids on `flutter_tester` (Skia on the CPU):

| Radii | Ladder: max, p99 | Form for one radius: max, p99 | Ink of the ladder against `drawCircle` |
|---|---|---|---|
| 2 to 2.5 | 82, 48 | 88, 68 | +4.3 % to +5.4 % |
| 2.5 to 4 | 101, 63 | 91, 68 | -1.6 % to -2.8 % |
| 4 to 8 | 90, 57 | 160, 72 | +1.1 % to +2.4 % |
| 8 to 16 | 114, 67 | 178, 74 | +0.3 % to +1.5 % |
| 16 to 48 | 111, 71 | 176, 75 | +0.3 % to +0.6 % |
| 2 to 8, mixed | 92, 57 | 152, 71 | +1.5 % to +1.7 % |
| 4 to 16, mixed | 108, 60 | 174, 73 | +0.7 % to +0.9 % |

The largest difference reaches at least 114 of 255; another grid can reach more. The ladder is closer
than the accepted form at the 99th percentile on each row, and at the largest difference from a
radius of 4 up. Below a radius of 4 its largest difference is up to 10 above that form. A chart color
on white gives 63 of 255. It does not reach 46. No solid pixel flips.

The ink is not within 2 % on each row. The ink of `drawCircle` on this backend is itself 3.2 % below
to 3.7 % above the area of the circle, and that error jumps with the radius. The ladder keeps the
area of its master at each radius, so a narrow range of radii differs by up to 5.4 %, and a mixed
range by less than 2 %. Other backends are not measured.

**Strokes stay on `drawCircle`.** A stroke of 1 pixel does not pass. In a probe that is not kept as a
test, a ladder of the same kind gave about 120 of 255, 99th percentile about 89, where the form for
one radius gave 80 and 46 on radii from 2 to 16. A stroke ends a varying run, and a run
with a stroke keeps one radius, so a stroked bubble keeps today's draw. A radius below 2 or above 48
bitmap pixels, a shader, and another composite operation also keep `drawCircle`. A varying run ends
after 16 fills of one radius, for the sprites of that radius.

**Direct circles count.** A run that ends in `_batchCircle` and draws one by one adds its length to
the split budget of Chart.js ADR 0066. A run that ends in `_endRecording`, a `restore` or a clip does
not split.

### 5. Two small routes

- `drawPointLegend` tests `identical(style, 'circle')` before its `switch`. Another string with the
  same text takes the `switch` and the same default.
- A stroke of exactly one `moveTo` and one `lineTo`, under a similarity transform with no dash, uses
  `drawLine`, with no `ui.Path`. The commands stay deferred, so a later read sees them. A line with
  no length or with a coordinate that is not finite keeps the path. Impeller already turns such a
  path into `DrawLine` (`SimplifyOrDrawPath`), and Skia strokes `drawLine` as such a path. The bytes
  are equal on `flutter_tester` for each cap, width, transform and composite mode. No other backend
  is tested.

## Tests

`test/port/platform/chart_host_scene_test.dart`, `test/port/elements/element.arc_sector_test.dart`,
`element.arc_sector_chart_test.dart`, `test/port/canvas/canvas_arc_sector_test.dart`,
`canvas_ui_ladder_test.dart`, `canvas_ui_line_test.dart` and
`test/port/helpers/helpers.canvas_point_style_test.dart`. Each fused route has a twin through the
ordinary path, and each guard a fallback test. All pixel bounds are from `flutter_tester`: Skia on
the CPU. Impeller and the web are not measured.

## Out of scope

Bars as vertices. Radius classes of a quarter pixel (R5 of Chart.js ADR 0055). A direct circle entry.
Static angle-line plans of the radial scale.
