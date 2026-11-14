# Chart.js ADR 0013: Canvas model

- Status: accepted (2026-10-21)
- Superseded by: [Chart.js ADR 0055](0055-native-draw-path.md) (2026-10-31)
- Superseded in part by: [Chart.js ADR 0066](0066-bounded-canvas-recordings.md)
- Date: 2026-10-19
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0013-canvas-model.md`

## Summary

The port-only canvas layer of `lib/src/canvas/` gives the Canvas 2D API of the DOM on `dart:ui`.
The pure interface `canvas.dart` serves the helpers and the mock context of the specs.
`UiCanvasContext` keeps the bitmap as a list of pictures in device pixels, and the host scales it to the box.
The layer keeps the Canvas 2D path rules and draws one full circle with `drawCircle`.
A run of full circles draws with one `drawRawAtlas` call of a sub-pixel atlas.

## Where each part went

- §1 (the layers and the interface): [Chart.js ADR 0055](0055-native-draw-path.md) §1.
- §2 (the canvas element and its attributes): [Chart.js ADR 0055](0055-native-draw-path.md) §2.
- §3 (the container interfaces): [Chart.js ADR 0055](0055-native-draw-path.md) §3.
- §4 (the retained bitmap of pictures): [Chart.js ADR 0055](0055-native-draw-path.md) §4.
- §4 (the flatten step above 8 pictures): [Chart.js ADR 0066](0066-bounded-canvas-recordings.md).
- §5 (the bitmap space and the device pixel ratio): [Chart.js ADR 0055](0055-native-draw-path.md) §5.
- §6 (the path semantics): [Chart.js ADR 0055](0055-native-draw-path.md) §6.
- §7 (the paint, the styles and the images): [Chart.js ADR 0055](0055-native-draw-path.md) §7.
- §8 (the cost and the pending full circle): [Chart.js ADR 0055](0055-native-draw-path.md) §6 and §8.
- §8 (the disposal of the paragraphs): [Chart.js ADR 0055](0055-native-draw-path.md) §8.4.
- §8.1 (the circle batch): [Chart.js ADR 0055](0055-native-draw-path.md) §8.5.
- §9 (no Chromium geometry): [Chart.js ADR 0055](0055-native-draw-path.md) §9.
- Open (the DPR base scale of Chart.js ADR 0009): [Chart.js ADR 0034](0034-no-display-only-js-exactness.md).
- Open (no test of the `dart:ui` layer on the web renderers): [Chart.js ADR 0055](0055-native-draw-path.md)
  Open 4.
- Open (a DPR change on a real device): [Chart.js ADR 0055](0055-native-draw-path.md) Open 5.
