# Chart.js ADR 0141: The scale option `border` holds a `ScaleBorder`

- Status: accepted
- Date: 2026-11-13
- Related: Chart.js ADRs 0050, 0052, 0054, 0115, 0116, 0118, 0139, 0140. The design draft
  [native-axis-border-design-draft.md](../native-axis-border-design-draft.md).
- Supersedes: the scope kind `BorderOptions` and its facade of Chart.js ADR 0054 §4 for the scale
  option `border`, and the theme key `scale.border.color` as a key of a scope of Chart.js ADRs 0050
  and 0118. The theme now writes the color in a border object (item 6).

## Context

The scale option `border` is an option object of Chart.js: `display`, `color`, `width`, `dash`,
`dashOffset` and `z` (`index.d.ts:3042`). The port held it as the typed scope kind `BorderOptions`.
The scale read each key through the facade `BorderOptions`, with `jsTruthy`, `jsToNumber`,
`canvasNumber`, `canvasStyle` and `canvasLineDash`. The route `scale.border.color` gave the default
`borderColor`. The typed API had no parameter for the border: an app wrote it as a Map in `extra`.
The docs app had 14 such Maps.

The radial linear scale reads only `dash` and `dashOffset` of the border, for its grid circles and
polygons. It got the whole object of `defaults.scale`, with an axis line color, a width and a
`display` that it does not read.

Chart.js ADR 0116 made the font one Flutter `TextStyle`, merged across the scopes with
`TextStyle.merge`. The border is the same kind of value: a small set of fields that the scopes give
field by field.

## Decision

1. The core file `lib/src/types/axis_border.dart` has the open immutable class `ScaleBorder` with
   the method `merge(ScaleBorder? other)`, and two final subclasses:
   - `AxisBorder` (`display`, `color` a `ChartPaint`, `width`, `dash` a `List<double>`,
     `dashOffset`, `z`), the axis line of a cartesian axis;
   - `RadialAxisBorder` (`dash`, `dashOffset`), the grid dash of the radial linear axis.

   Each field is nullable: null is not set. `merge` of a border of the same class merges field by
   field, and a field of `other` that is not null wins. A border of another class replaces this
   one, and null keeps it. Each class has `copyWith`, `==`, `hashCode` and `toString`.
2. The schema has the typed atom `scaleBorder` (`ScaleBorder`), the shape of `border` in
   `ScaleOptions`. The scope kind `BorderOptions` and the keys `dash`, `dashOffset` and `width` of
   `OptionKey` go. A value of the option is a `ScaleBorder` or a function of the context that gives
   one. The descriptors of `scale` make `border` scriptable.
3. The resolver merges the borders of the scopes with `ScaleBorder.merge`, as it merges the fonts
   (the kind 4 of `nativeMergeKind` and `mergeNativeOptionValues` of `helpers.core.dart`): the
   scopes that `createSubResolver` gathers for the `border` object upstream, from the lowest
   priority up. A border that a scriptable option returns merges the same way. A route,
   `helpers.merge` and `mergeIf` merge two borders with `merge`: in `mergeIf`, a field of the target
   stays.
4. The defaults of all scales (`core.scale.defaults.dart`) hold
   `AxisBorder(display: true, dash: [], dashOffset: 0, width: 1)`: the values of
   `core.scale.defaults.js:39-44`. The route `scale.border.color` goes. A cartesian scale reads
   `border.color ?? defaults.borderColor` at its draw, the value that the route gives upstream. The
   default has no `z`; `_layers` reads an absent `z` as 0, as upstream reads `undefined`. Thus the
   defaults equal the upstream inventory.
5. The defaults of the radial linear scale hold `RadialAxisBorder(dash: [], dashOffset: 0)`, the
   values that it gets upstream. The scopes of a radial scale have this border above
   `defaults.scale`, and its class replaces the `AxisBorder`: the shared border never reaches a
   radial scale. The radial scale options have the key `border` after `grid`.
6. The theme writes `scale.border = AxisBorder(color: ChartPaint.solid(borderColor))` for the token
   `borderColor`. It also writes an empty `RadialAxisBorder` in `scales.radialLinear`: hunk H1
   merges the theme scale of the type first, so the radial border of the theme keeps its class over
   the `AxisBorder` of `scale`.
7. The readers take one border object:
   - `_computeGridLineItems`, `drawBorder` and `_layers` of `core.scale.dart` read one
     `AxisBorder` with typed fields. They keep `if (!axisWidth) return` (0 or NaN),
     `border.display ? width : 0`, `dash || []` (`dash ?? []`) and the canvas skip of an absent
     `dashOffset`.
   - `drawGrid` and `_drawRadiusLine` of `scale.radialLinear.dart` read one `RadialAxisBorder`.
   - The border of each tick reads `options.setContext(getContext(i)).border`, where upstream
     reads `border.setContext(getContext(i))`: a border function gets each tick context.

   Their `jsTruthy`, `jsToNumber`, `canvasNumber`, `canvasStyle` and `canvasLineDash` on border
   values go. The facade `BorderOptions` goes; `CoreScaleOptions.border` gives the merged
   `ScaleBorder`.
8. A value that is not a `ScaleBorder`, for example a Map of the keys, stops a debug build in
   `CoreScaleOptions.border`. A cartesian scale that gets a `RadialAxisBorder`, or a radial scale
   that gets an `AxisBorder`, stops a debug build too. A release build draws no axis line and solid
   grid lines for such a value.
9. The typed API: the five cartesian axis classes have `final AxisBorder? border`, and
   `RadialLinearAxis` has `final RadialAxisBorder? border`, with `copyWith`, the diagnostics and
   `==`. `ChartAxis` declares `ScaleBorder? get border`. The lowering stores the object with the
   typed setter `scope.border`, before `extra`. `lib/chartjs.dart` exports `ScaleBorder`,
   `AxisBorder` and `RadialAxisBorder`, as it exports `ChartClip`, so a raw config holds the same
   objects.

## Consequences

- The typed API and a raw config hold the same objects, and a radial axis cannot get a color, a
  width or a `display` that it does not read.
- The upstream function form of a key (`dash: (ctx) => ...`) becomes a function of the whole
  border. The scale calls it with the scale context once for each options view and with each tick
  context, where upstream calls the function of a key with each tick context only. The user calls
  of the fixture `core.scale/grid/scriptable-borderDash` change in that way; its observation
  digest is updated, and the observed values do not change.
- The scale reference data of the generators hold the border classes in their input configs. The
  observed scale options keep the upstream object: the tests compare the upstream form of the
  border of the port (`upstreamBorderOf` and `withPortBorders` of `test/support/scale_border.dart`).
  The controller generators write the border of a radial scale with `dash` and `dashOffset` only.
- The 19 data fixtures with a scale `border` have hand ports (Chart.js ADR 0115): 8 had one, and 11
  are new.
- The key census has no rows of the keys of the border object.

## Alternatives considered

- **Keep the scope kind and add a typed parameter that lowers into it.** The scale still reads
  key by key with the JS operators, and a radial axis still gets the keys that it does not read.
  Rejected.
- **One class for both scale types.** A radial axis then takes an axis line color and width that
  it ignores, and the shared default reaches it. Rejected.
- **Keep the route `scale.border.color` as a route of the border object.** A route of a border to a
  color has no form in `Defaults.route`, which routes a key to a key. The read of the default
  `borderColor` at the draw gives the same value with no route. Rejected.
- **A default `z: 0`.** The draft wrote it. Upstream has no `z` in the default, and the schema test
  compares the defaults with the upstream inventory. `_layers` gives the same 0 for an absent `z`.
  Not done.
