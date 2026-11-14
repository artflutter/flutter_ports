# Chart.js ADR 0106: Canvas shadows

- Status: accepted
- Superseded in part by: [Chart.js ADR 0107](0107-dataset-shadow.md)
- Date: 2026-11-09
- Related: Chart.js ADRs 0013, 0055, 0097, 0103, 0104, 0105.
- Supersedes: the sentence of Chart.js ADR 0055 section 1 "A member arrives when a ported caller or
  the mock needs it".
- Row of `differences.md`: the row `platform-canvas-no-shadow` is removed.

## Context

The canvas layer had no shadow attributes, because no file of Chart.js `src/` uses them. A browser
canvas has them. A JavaScript plugin can set `shadowBlur` and `shadowColor` and get a real blur. A
plugin of the port could not do this. The fl_chart line samples 5 and 12 need a shadow of the line.
It was the only visual feature of the 13 samples that a plugin could not reproduce.

## Decision

1. A member arrives on `CanvasRenderingContext2D` when a ported caller or the mock needs it, or
   when a plugin needs a member of the browser canvas that it cannot replace with other members.
2. The interface has `shadowBlur`, `shadowColor`, `shadowOffsetX` and `shadowOffsetY`. The defaults
   and the ignored values are the HTML rules. `shadowColor` takes a native `Color`, as `fillStyle`
   does. `save()` and `restore()` keep the four values, and a reset of the context clears them.
3. A draw casts a shadow only when the color is not transparent, and the blur or an offset is not 0.
   The field `_State.shadowOn` holds this result, and it is the only cost of a draw with no shadow.
4. A shape draws a second time before itself, with `MaskFilter.blur`. The sigma is half of
   `shadowBlur`. The transform changes neither the blur nor the offset: a draw under the transform
   divides the sigma by the scale, and the offset stays outside the transform.
5. A shadow of a gradient keeps the shader and adds a `srcIn` color filter. A transparent part of a
   gradient thus casts no shadow.
6. Text draws a second paragraph with a foreground paint that has the mask filter. An image draws
   in a layer with a blur image filter, in the bounds of the image and the blur.
7. Each fast path declines while a shadow is on: the circle batch and its runs, the fused bar, the
   fused arc sector, the line fan, the partitioned fill and the web pieces of Chart.js ADR 0105.
8. No typed option exists for a shadow, because Chart.js has no such option. A plugin sets the
   attributes in `beforeDatasetDraw` and restores them in `afterDatasetDraw`.

## Consequences

- The spec case "should reset context to default values" passes and no longer skips.
- `MockContext` has the four attributes as plain fields. It does not record them.
- On the web, a long line with a shadow loses the pieces of Chart.js ADR 0105. This change did not measure
  this cost.
- A chart with visible points and a dataset shadow makes one blurred draw for each point.

## Alternatives considered

- **A `CustomPaint` under `ChartView`.** It needs the geometry of the chart outside the chart, and
  it draws below the grid. Rejected.
- **A layer with a blur image filter for each shape.** It works on each engine, but each point of a
  dataset then needs its own layer. The port uses it only for images.
- **A `shadow` parameter of `LineDataset`.** Chart.js has no such option. A later change can add it
  on top of the attributes.
