# Chart.js ADR 0095: Guarded static plans of the radial scale and the radar loop

- Status: accepted
- Superseded in part by: [Chart.js ADR 0130](0130-native-callback-options.md) (2026-11-13)
- Date: 2026-11-06
- Related: Chart.js ADRs 0025, 0036, 0063, 0064, 0071, 0078, 0087. Measurements: performance.md §65.
- Rows of `differences.md`: `adapt-radial-static-plans`, `adapt-radial-label-dispatch`,
  `adapt-radial-numeric-parse`, `adapt-radar-direct-updates`, `adapt-normalize-angle-range`,
  `adapt-line-points-identity`, `adapt-point-label-context-construction`.

## Context

A dense radar makes a point label context, a resolver view, a font and a text options object for
each label in each fit, for each label in each draw and for each angle line in each draw, although
most labels are often empty and all these options are often one static value. The radar update
re-reads the position options for each point and makes a property object for each point.

## Decision

Each plan is local to one synchronous loop, starts after one ordinary pass of its first index and
keeps nothing for a later loop. A plan never decides from a value that it resolved itself: it reads
only what the ordinary pass left in the resolver cache.

**Common guards.** `RadialLinearScale` itself, and a context with a non-null
`CanvasTextMetricsSource.textMetricsGeneration`. Only the native canvas has that capability in the
library; its setters and text measures have no effect beyond its state. A recording context keeps
each call. A cached value qualifies through `OptionView.cachedStaticValue`, under the conditions of
`cachedStaticFont` (no slot removal, no sub proxy, ordinary descriptors, untouched resolver slots,
cached descriptors), and only as a plain value: a number, a string, a boolean, `null`, `undefined`
or the exact class `Color`. The font uses `TickFontCache.staticInputs` and `matchesResolved`.

**Fit.** After index 0, with a static font and a number padding, the other indexes make no context,
view or font. One `save`, `font` and `restore` wrap all their measures. An empty label measures once
and keeps the height of one line. The padding, the size and the limit arithmetic stay per index.
`Math.sin` and `Math.cos` of `updateLimits` run only in the branch that divides by them.

**Label draw.** After the last visible label, with a static font and color and no backdrop, the other
labels take `renderText` with that font and color. An empty string draws nothing: on the native
canvas its `fillText` returns at once. `item.visible` and the reverse order stay.

**Angle lines.** After the last line, with a static color, line width, dash offset and an empty dash
list, the state of that line stays the state of the others, and each line keeps `beginPath`,
`moveTo`, `lineTo` and `stroke`. Lines are not merged: a translucent line still blends over the
others. A static falsy color or line width ends the loop, because no line draws.

**`generateTickLabels`.** See the row `adapt-radial-label-dispatch`. The exact built-in callback
over a native list takes the labels directly. A closure of the shape
`Object? Function(Object?, double)` is called with no argument list, and each new closure gets one
shape test. The option stays a read for each label while a user closure runs. On the exact chart,
the visibility is read after all callbacks; no hidden index keeps the list of the callbacks.

**Radar.** In the modes `none` and `reset`, the exact controller writes a point of the built-in class
through its typed setters, in the key order of the literal. In the mode `none`, after the first
point, the cached `point-none` options entry shows that no user code runs in the rest of the loop.
Each other point gets a fresh copy of it, and a position from `RadialPositions`, the inputs of the
position methods read once. `Math.cos` and `Math.sin` stay `jsCos` and `jsSin`, so each result has
the bits of the methods. This decides the radar item of the step 7 list of Chart.js ADR 0036 §8 for
this guarded loop. The value methods of the scale keep Chart.js ADR 0025 Open 1: they have no fast
path.

**Smaller forms.** A single-scale numeric parse with the whole-range preflight of Chart.js ADR 0071.
`normalizeAngle` with no remainder in range and the same bits. A direct constructor of the point
label context with the own-key order of the literal, as the tick context has. One object `itemOpts`
in `buildPointLabelItems`, as upstream has. `LineElement.points` keeps its typed copy when a write
gives the same elements in the same order.

## Fallback

The ordinary reads stay at their original observation point for: a user subclass of the scale, the
controller, the point or the chart; a scriptable or indexed option; a foreign value; a backdrop; a
non-empty dash; a `Color` subclass; a gradient or pattern; an active point; a parsed value that is no
number, `null` or `undefined`; other modes than `none` for the rest of the radar loop. A label that is
no `String` ends a label plan at its index, and the ordinary loop continues there. No user callback
runs fewer or more times, or in another order.

## Differences

Each one is a row of `differences.md`.

- On the native canvas, the plans make fewer state and `save` calls. The state at each stroke and text
  draw and the pixels are equal. No other context sees this.
- `LineElement.points` keeps one typed list across updates with the same elements. A reader that keeps
  the list sees one list, as upstream, where `line.points` is `meta.data`. The derived state still
  drops at each write.

## Tests

`test/port/scales/scale.radialLinear_plans_test.dart` compares each plan with the ordinary loops on
the same chart through a recording context with and without the capability (the effective state at
each paint and the order of the path operations), and with a trivial user subclass in pixels. Its
cases cover text, empty and multi-line labels, a backdrop, a scriptable font, color and padding,
hidden data points, `display: 'auto'`, reverse, a start angle and centered labels, for radar and
polar area. It also pins that the typed config of a dense radar takes each plan.
`test/port/controllers/controller.radar_plans_test.dart`,
`test/port/core/primitive_parse_single_scale_test.dart`, `test/port/elements/element.line_points_test.dart`
and `test/port/helpers/helpers.math_normalize_angle_test.dart` have the other twins.
