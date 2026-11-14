# Chart.js ADR 0105: Long paths in pieces on the web

- Status: accepted
- Superseded by: [Chart.js ADR 0113](0113-stroke-pieces-by-browser-system.md) (2026-11-10)
- Date: 2026-11-06
- Row of `differences.md`: `adapt-web-long-path-pieces`.
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0105-web-long-paths-in-pieces.md`

## Summary

On the web only, `UiCanvasContext` drew a long path in pieces with small bounds. Skia on WebGL draws a large path slowly.
A piece had at most 512 commands and 40,000 bitmap pixels. A path needed at least 128 commands.
The stroke of a `Path2D` and a one-color line fill to a horizontal base took pieces. Native engines kept one draw.
[Chart.js ADR 0113](0113-stroke-pieces-by-browser-system.md) states the complete decision with two changes.
A desktop browser strokes in pieces from 2 commands, and the overlap at a cut divides a curve.

## Where each part went

- Context (the slow route of Skia on WebGL, the piece limits): [Chart.js ADR 0113](0113-stroke-pieces-by-browser-system.md)
  Context. Figures: performance.md §68.
- Decision intro (the web only, the limits, the minimum of 128 commands, the test switch):
  [Chart.js ADR 0113](0113-stroke-pieces-by-browser-system.md) Decision, intro and item 1.
- Item 1 (the stroke of a `Path2D`): [Chart.js ADR 0113](0113-stroke-pieces-by-browser-system.md) item 1, with the
  desktop rule and the cut of a curve.
- Item 2 (the fill of the current path): [Chart.js ADR 0113](0113-stroke-pieces-by-browser-system.md) item 2.
- Item 3 (no compound fill on the web): [Chart.js ADR 0113](0113-stroke-pieces-by-browser-system.md) item 3.
- Pixels (the true area of a dense fill, a difference of the display only):
  [Chart.js ADR 0113](0113-stroke-pieces-by-browser-system.md) section Pixels.
- Review (the four differences that stay, among them the loss of 16 pixels that Chart.js ADR 0113 cites):
  [Chart.js ADR 0113](0113-stroke-pieces-by-browser-system.md) section Pixels.
- Consequences (one `ui.Path` for each piece, the fills that keep one draw):
  [Chart.js ADR 0113](0113-stroke-pieces-by-browser-system.md) Consequences.
