# Chart.js ADR 0158: Fused rounded bar

- Status: proposed
- Date: 2026-11-17
- Supersedes: of [Chart.js ADR 0070](0070-native-rectangular-bar-drawing.md), the word "rounding" in the sentence
  "Invalid/unknown colors, gradients/patterns, rotations, non-finite geometry, rounding and inflation use the
  existing path"
- Related: [Chart.js ADR 0149](0149-bar-chart-small-costs.md), [Chart.js ADR 0034](0034-no-display-only-js-exactness.md)

## Context

A bar with a border radius draws through the upstream sequence of `element.bar.js:179-200`: `save`, two
`roundRect` calls, a `fill('evenodd')` of the border ring, one more `roundRect`, a `fill` and `restore`. The
`dart:ui` context already draws that sequence with `drawDRRect` and `drawRRect`. The sequence makes about 25 objects
for each bar with no border and about 55 with a border: three geometry records, three rounded rectangles with their
radii, three radius lists and a copy of the state. A bar with a border and no radius takes the fused path of Chart.js
ADR 0070. The draw of 20,000 rounded bars is 9.5 ms higher on the macOS app, 14.0 ms on the iPhone and 26.4 ms on the
Pixel.

## Decision

1. `BarElement.draw` takes a fused path for a bar with a number as `borderRadius` other than 0, under the conditions of
   the fused rectangular bar: the exact class `BarElement`, `BarOptions`, a `BorderSkipped` and an `inflateAmount` of 0.
   It computes the numbers of `boundingRects` as scalars, with the expressions of `getBarBounds`, `parseBorderWidth`
   and `parseBorderRadius`.
2. When each corner radius is 0 (`enableBorderRadius` is not true, or each corner touches a skipped edge), upstream
   adds plain rectangles. The bar then takes the fused rectangular path of Chart.js ADR 0070.
3. Else the element offers the outer and the inner rectangle, with the four radii of each, to
   `RectBarCanvas.tryDrawRoundedBar`. Another context, and each decline, runs the upstream sequence with the same
   numbers.
4. The native context makes the rounded rectangles with the code of `roundRect`, but with no geometry record:
   `roundRectRadiusScale` (the scale of step 11 of the HTML algorithm) and `UiPathBuilder.mappedRRectOf`. It takes
   only sides of 0 or more, which `roundRect` does not flip. It selects the draw call of `fill`: the sole shape or the
   `drawDRRect` ring for the border, and `drawRRect` for the fill. Thus the engine gets the same calls with the same
   values, and no pixel changes.
5. The context keeps the logical styles, the save depth and the clips. The final path is the inner rounded rectangle,
   with the commands of `roundRect`. Each fill that the sequence counts still counts and notifies, also an empty
   fill.
6. The context declines with no effect for each case that `fill` draws in another way or that code of a program can
   see: a shadow, two shapes that are not nested, a shape or a radius that is not finite, a negative side or radius, a
   transform that is not axis-aligned or not invertible, a color that is not an exact `ui.Color`, a pending
   notification and an observer of a picture or an image. The border color is read only when the bar has a border.
7. A corner object as `borderRadius` and an `inflateAmount` other than 0 keep the upstream sequence.

## Rejected

- A rounded rectangle path made in one pass with no `roundRect` code: it can give radii that differ by one float step
  from the scale of step 11.

## Consequences

- `roundRectGeometry` calls `roundRectCornersGeometry` and `roundRectRadiusScale`, `UiPathBuilder.mappedRRect` calls
  `mappedRRectOf`, and `UiPathBuilder.roundRect` calls `addRoundRect`. A change of the rounded rectangle of the path
  changes the fused bar in the same way.
- The twins compare the pixels of the fused bar with those of a subclass that keeps the upstream sequence.

## Tests

`test/port/canvas/canvas_rounded_bar_test.dart`, `test/port/canvas/canvas_rect_bar_test.dart`
