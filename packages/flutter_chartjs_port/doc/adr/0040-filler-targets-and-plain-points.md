# Chart.js ADR 0040: Filler targets and plain points

- Status: accepted (2026-10-23)
- Date: 2026-10-22
- Related: [Chart.js ADR 0003](0003-type-only-dependencies.md) (type libraries, records for
  inline object types),
  [Chart.js ADR 0043](0043-options-representation-and-resolver.md) (Dart `null` for
  `undefined`, the `undefined` sentinel),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (file names and the `_` rule),
  [Chart.js ADR 0017](0017-element-properties.md) §4, §5 and Open (the `undefined` state, the
  access by name, the plain points of the filler),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13 (a gain that only a
  microbenchmark measures),
  [Chart.js ADR 0025](0025-scale-value-parameters.md) Open 7 (the filler targets),
  [Chart.js ADR 0028](0028-controller-interfaces.md) §1, §3 and Open 2 (interface members and
  casts, the typed `points` list, the members of phase 8),
  [Chart.js ADR 0032](0032-js-numeric-semantics.md) (`ToNumber`, `jsMin` and `jsMax`, the
  reference engine),
  [Chart.js ADR 0033](0033-radial-scale-centers.md) §3 and Open 4 (the `null` center),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0036](0036-parsed-data.md) (the `Expando` precedent of `stacksOf`),
  [Chart.js ADR 0038](0038-plugin-modules-class-values-and-interfaces.md) (the plugin modules,
  the members of `types.LineElement` and the pure roots),
  [Chart.js ADR 0041](0041-plugin-test-strategy.md) (the test strategy of phase 8),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [performance.md](../performance.md) (the phase 8 section),
  [upstream-ledger.md](../upstream-ledger.md) row `b9725745` (#12283),
  [differences.md](../differences.md) rows `adapt-line-points-elements`,
  `adapt-spline-control-point-nan` and `adapt-filler-target-classes` (new)

## Context

Phase 8 ports the 8 files of `src/plugins/plugin.filler/` (808 lines): `index.js`,
`filler.drawing.js`, `filler.helper.js`, `filler.options.js`, `filler.segment.js`,
`filler.target.js`, `filler.target.stack.js` and `simpleArc.js`. The filler makes new lines and
new points in each draw. Upstream JavaScript puts any object into `LineElement.points`. The port
keeps a typed `List<types.PointElement>` (Chart.js ADR 0028 §3, row
`adapt-line-points-elements`). Three accepted ADRs leave the form of the filler points to this
phase:

1. Chart.js ADR 0017 Open: "The plain points of the filler (phase 8)". The port either wraps each
   point in a `PointElement` or widens `points` to `List<Point>`.
2. Chart.js ADR 0025 Open 7: the filler wraps the records of `getPointPositionForValue` as point
   elements.
3. Chart.js ADR 0033 Open 4: the filler reads `getPointPositionForValue` through the interface.
   If it also reads `xCenter`, it handles `null` by section 3 of that ADR.

The line numbers of upstream files refer to Chart.js `v4.5.1+7169e651` (`third_party/Chart.js`
at `7169e65147a4`). Short names such as `index.js` and `filler.drawing.js` are the files of
`src/plugins/plugin.filler/`. "The port" is `packages/flutter_chartjs_port/lib/src/`.

### Upstream objects that are not elements

| Site | Upstream object | Goes to |
|---|---|---|
| `filler.segment.js:65-82` `_pointsFromSegments` | `{x: first.x, y}` and `{x, y: first.y}` | `points` of a boundary line (`filler.helper.js:25`, `:28-33`) |
| `filler.target.js:90-93` `computeCircularBoundary` | the record `{x, y, angle}` of `getPointPositionForValue` | `points` of a loop boundary line (`filler.helper.js:20-23`) |
| `filler.target.stack.js:58-79`, `:88` | the result of `line.interpolate(sourcePoint, 'x')`: a `PointElement` when `p1 === p2`, a plain `{x, y}`, or an Array of them (`element.line.js:351-378`) | `points` of the stack line (`filler.target.stack.js:29`) |
| `filler.segment.js:38-43` `_segments` | the edge objects `{[property]: _getEdge(...)}` | the reference point of `interpolate` (`filler.drawing.js:150`, `:156`, `:201`) and `_getBounds` (`:139`) |
| `simpleArc.js:18-25` `interpolate` | `{x, y, angle}` | `ctx.lineTo` only (`filler.drawing.js:202-204`) |
| `index.js:26-34` | the source `{visible, index, fill, chart, axis, scale, line}` | `meta.$filler` (`index.js:37`) |
| `filler.target.js:83-87` | `new simpleArc({x, y, radius})` | the target of a circular radar grid |

The JSDoc of upstream types the points as `PointElement[]` (`filler.helper.js:12`,
`filler.target.stack.js:54-55`, `:85`).

### The readers of a target line

- `_computeSegments` reads `points[i].skip` and `points[i].stop`.
- `_boundSegment` (`helpers.segment.js:77-129`) reads `point.skip` (`:100`) and
  `point[property]` (`:104`), and compares `value === prevValue` (`:106`).
- `pathSegment` and `fastPathSegment` (`element.line.js:71`, `:118`) read `skip`, `x` and `y`.
  `_getSegmentMethod` (`element.line.js:185-190`) selects the fast path for a line without
  `_decimated`, `_loop`, `tension`, `stepped` and `borderDash`.
- `_findSegmentEnd` (`filler.segment.js:84-92`) reads `isNaN(point.x)` and `isNaN(point.y)`.
- `findPoint` (`filler.target.stack.js:87-109`) reads `point[property]` of the `interpolate`
  result and of the line points.
- `interpolate` (`element.line.js:351-379`) reads `point[property]` of the reference point and
  compares `p1 === p2`.
- `clipVertical` and `clipHorizontal` (`filler.drawing.js:68-126`) read `target.segments`,
  `target.points`, `target.first().x` and `.y`.

### The imports of upstream

- `index.js:7`, `filler.helper.js:7` and `filler.target.stack.js:7` import the class
  `LineElement`.
- `filler.target.js:5` imports `simpleArc`.
- `filler.drawing.js:1-3` and `filler.segment.js:1` import no element module and not
  `simpleArc`. They call `pathSegment`, `interpolate`, `first`, `segments` and `points` of a
  target by name (`filler.drawing.js:69`, `:85`, `:93`, `:99`, `:115`, `:123`, `:153`, `:201`,
  `filler.segment.js:6`, `:15`).

### The port before this ADR

- The setter `LineElement.points` takes `List<types.Element>` and copies it into a
  `List<types.PointElement>`. An element that is not a `types.PointElement` throws
  (row `adapt-line-points-elements`).
- `_pointValue` of `element.line.dart` reads `point[property]` of a `types.PointElement` through
  the extension `PointElementProperty`, which reads `angle` of a `types.RadialPointElement`. For
  another `Point`, it gives NaN for `'angle'`.
- `LineElement.first()` gives Dart `null` for the falsy number 0 of upstream.
- `LineElement.interpolate` gives Dart `null`, one `Point` or a `List<Point>`.
- `ChartMeta` implements `types.PropertyAccess` (`core/core.controller.dart:279`). Its access by
  name keeps extra properties in a Map (`operator []` and `operator []=`).
- `types.Scale` has no `getBaseValue`. `types.LineElement` has no `first`, `interpolate` and
  `pathSegment`.

### Probes

All behavior probes ran the Chart.js build at the pin in the x64 Node.js v24.12.0 under Rosetta,
with `registerables` and `plugins.colors.enabled = false`, as `test/index.js:25-28` does.

- **The list result.** A stack fill above a line with a `segment.borderColor` style, or above a
  line whose `x` goes back, gets an Array from `interpolate`. Two style segments share their end
  point, so `_boundSegments` finds two segments. `findPoint` reads `undefined` for `x`, and
  `addPointsBelow` pushes the Array (`filler.target.stack.js:71`). The stack line then gives
  sub-bounds with an `undefined` edge, and `_boundSegment` gives no fill source. The filler hook
  makes only `save`, `beginPath`, `rect`, `clip`, `save`, `restore` and `restore`. Upstream draws
  no stacked fill in this case. The same chart without the style draws the fill.
- **A bare point against a NaN point.** The stack line of the style case, with three forms of
  the Array item: the Array, an object without `x` and `y`, and `{x: NaN, y: NaN}`. The Array
  and the bare object give the bound segments `[0, 2]` and `[2, 5]`. The NaN object gives
  `[0, 2]` and `[3, 5]`, because `undefined === undefined` is true and `NaN === NaN` is false
  (`helpers.segment.js:106`). A Dart run of the same line gives `[0, 2]` and `[2, 5]` with
  `PointElement()` and `[0, 2]` and `[3, 5]` with `x` and `y` set to NaN.
- **The `_segments` steps in Dart.** A Dart test ran `boundSegments` and `boundSegment` of the
  port on the source and target lines of three charts that a Node.js probe captured: the style
  case, the same chart without the style, and a radar with a gap on a polygon grid. The three
  cases give the segments, the bounds and the fill sources of upstream. In the radar case,
  `interpolate` of an edge object with only `angle` (5.969026041820607 and 2.199114857512855)
  gives the target points 1 and 3 themselves, at (256, 280), as upstream.
- **The `angle` read.** `PointElement()..angle = 1.25` reads 1.25 through
  `PointElementProperty`. Its `x` reads NaN by the getter and `undefined` by name.
- **`first()` of a line without segments.** `fill: {target: 1, above, below}` with dataset 1
  empty: `first()` gives the number 0 twice. The hook calls `lineTo(undefined, 32)` and
  `lineTo(undefined, 483.6)`. With `indexAxis: 'y'`, it calls `lineTo(20.674, undefined)` and
  `lineTo(500.659, undefined)`. No throw.
- **The `shape` throw.** `fill: {target: 'shape', above: 'red', below: 'blue'}` throws
  `TypeError: segments is not iterable` in `new Chart(...)`, after `save()` and `beginPath()`.
  `shape` with one color draws.
- **No layout.** A plugin `beforeLayout` that returns `false`, with the legend off: a radar with
  `fill: 'origin'` on a polygon grid and on a circular grid throws
  `TypeError: Cannot read properties of undefined (reading 'left')` at `clipArea`. The target is
  a list of NaN points or a `simpleArc` with NaN values. Both are truthy. A line with
  `fill: 'origin'` does not throw: its target pixel is NaN, so the target is `null`.
- **`clipToIndexBounds` (#12283).** A category scale with `offset: true`: the hook clips to
  `rect(78.3134765625, 32, 381.0546875, 451.6)` twice, in `clipArea` and in `clipBounds`.
- **The circular grid.** A radar without a gap calls `arc(256, 280, 0, 6.283185307179586, 0,
  true)` and `fill('evenodd')`. With a gap, it calls `arc(256, 280, 0, 5.969026041820607,
  2.199114857512855, true)` and `fill('nonzero')`.
- **The decimation.** 5000 points, `parsing: false`, linear `x`: without the decimation the line
  has 5000 points and the filler hook makes 3450 `lineTo` calls. With `lttb` and 50 samples, it
  has 50 points, `_decimated` is true, and the hook makes 106 `lineTo` calls. With 1000 points on
  a 512-pixel canvas, the decimation does not run (`plugin.decimation.js:241-243`). With two
  datasets of 5000 points and `fill: 'stack'`, min-max and lttb give no Array result.
- **The draw calls of one `chart.draw()`**, 3 datasets of 50 points (calls of the filler hooks,
  rect clips, path clips, `fill` calls): `origin` 213, 6, 0, 3. `origin` with a gap every 12
  points 369, 18, 0, 15. `origin` with `above` and `below` 459, 9, 6, 6. `'-1'` 309, 6, 0, 3.
  `stack` 315, 6, 0, 3. `shape` 192, 3, 0, 3. Radar `origin`, polygon grid 348, 3, 0, 3. Radar
  `origin`, circular grid 198, 3, 0, 3. Only `above` and `below` make path clips.
- **The quadratic stack.** The median time of `chart.draw()` with 3 datasets in V8 grows from
  141-173 µs without a fill to 2402 µs for a 100-point stack fill and 128163 µs for a 1000-point
  stack fill. Each `interpolate` runs `_boundSegments` over all points of the line below
  (`element.line.js:355`).

### Benchmarks

AOT (`dart compile exe`) and dart2wasm (`dart compile wasm -O2`, run in the x64 Node.js
v24.12.0), Dart 3.13.5, Apple M3 Max. Other sessions loaded the Mac (load average 6.4 to 11.8).
The decisions use differences of 5 times or more, or a confirmed series.

- **A second implementer of the point interfaces.** C1 is the hot path of every line chart, 1000
  points, µs for each operation:

  | C1 case | A, AOT | P, AOT | L, AOT | A, wasm | P, wasm | L, wasm |
  |---|---:|---:|---:|---:|---:|---:|
  | `segments` and `path`, fast path | 18.4-19.3 | 22.5-23.3 | 21.6-22.5 | 30.4-38.0 | 48.0-61.8 | 44.4-49.0 |
  | `updateControlPoints` and `path`, bezier | 53.6-54.2 | 88.3-88.7 | 87.6-91.6 | 110.0-135.8 | 235.7-270.2 | 238.9-285.9 |
  | `boundSegments` | 16.7-17.5 | 18.0-18.2 | 18.1-19.0 | 37.6-44.0 | 70.3-90.6 | 45.0-49.2 |

  A is the form of this ADR: `PointElement` is the only class that implements
  `types.PointElement`. L puts a port-only `FillerPoint` class into the filler lines. P allocates
  one `FillerPoint` in `main` that never enters a line. P gives the full slowdown of L: the cause
  is static. The whole-program type analysis of AOT and dart2wasm stops the devirtualization of
  the reads of `skip`, `x`, `y` and the control points. One allocated copy of a gallery class
  that implements `SplinePoint` gives the same effect on the bezier case: 81.3-82.1 µs on AOT
  and 216.4-226.2 µs on dart2wasm against 53.9-54.3 µs and 107.5-112.9 µs.
- **The wrap of one point**, ns: `PointElement()` with the setters 2.2-2.3 (AOT) and 4.1-6.7
  (dart2wasm). `PointElement({'x': .., 'y': ..})` with a cfg Map 143.7-148.8 and 174.3-199.0. A
  record or a plain class 2.2 and 0.3. V8 upstream: `new PointElement()` with 2 writes 21.1,
  `{x, y}` 5.3.
- **The filler lines**, ns for each line: the cfg Map
  `LineElement({'points': .., 'options': .., '_loop': .., '_fullLoop': ..})` 280.8-289.9 (AOT)
  and 394.5-396.3 (dart2wasm). The cascade 42.5-44.6 and 38.8-44.2.
- **`interpolate`** on a line of 1000 points: 14.4-15.5 µs (AOT), 27.7-29.4 µs (dart2wasm),
  13.6 µs (V8). The stack target of one dataset over 2 lines of 1000 points: 15.8 ms (AOT),
  29.7-34.3 ms (dart2wasm).
- **The read of `meta.$filler`**, ns for each read: the access by name 10.6-15.0 (AOT) and
  18.4-28.4 (dart2wasm). A typed field 0.6-4.3 and 0.3-4.3. An `Expando` 10.8-11.2 and 24.2-25.0.
  The filler reads the slot about twice for each visible dataset and draw (`index.js:56`,
  `:84`).

## Decision

### 1. The plain points become point elements

The filler wraps each plain object that goes into `LineElement.points`, or that it passes as a
reference point, in a `PointElement`. The wrap sets only the properties that the upstream object
has. A property that the object does not have stays in the `undefined` state (Chart.js ADR 0017
§4): its getter gives NaN, and its read by name gives `undefined`. `LineElement.points` stays
`List<types.PointElement>`. `element.line.dart`, `helpers.segment.dart`,
`helpers.interpolation.dart` and `types.LineElement.points` do not change.

| Upstream object | Site | Dart |
|---|---|---|
| `{x: first.x, y}`, `{x, y: first.y}` | `filler.segment.js:74-79` | `PointElement()..x = first.x..y = y` |
| the record `{x, y, angle}` | `filler.target.js:91` | `PointElement()..x = p.x..y = p.y..angle = p.angle` |
| `{[property]: edge}` | `filler.segment.js:38-43` | `PointElement()..[property] = edge` (section 3) |
| a plain `{x, y}` result of `interpolate` | `filler.target.stack.js:88` | `PointElement()..x = p.x ?? 0..y = p.y ?? 0` (section 2) |
| an Array result of `interpolate` | `filler.target.stack.js:88` | `PointElement()` (section 2) |

A `PointElement` result of `interpolate` stays the same object, as upstream pushes the same
object (`filler.target.stack.js:69`, `:71`).

The points use the cascade `PointElement()..x = ..`, not a cfg Map: the cfg Map costs about
145 ns for each point (Benchmarks), 0.14 ms for a stack target of 1000 points. The lines use the
literal upstream form, the cfg Map `LineElement({'points': points, 'options': {...}, '_loop':
loop, '_fullLoop': loop})` (`filler.helper.js:28-33`) and `LineElement({'points': points,
'options': {}})` (`filler.target.stack.js:29`). The cascade of a line saves 0.24-0.36 µs for
each target in each frame, which is below the 0.1 ms rule of Chart.js ADR 0020 §13.

Each wrap site carries `// DIVERGES(chartjs): adapt-line-points-elements, <reason>`. The wraps
stay at their upstream lines. No port-only helper file holds them.

### 2. The result of `interpolate` in the stack line

`findPoint` (`filler.target.stack.js:87-109`) wraps the result of `line.interpolate` at `:88`:

- Dart `null` (JS `undefined`) stays `null`. `findPoint` returns no point.
- A `types.PointElement` stays the same object.
- A plain `Point` (an `InterpolatedPoint`) becomes `PointElement()` with its `x` and `y`. A Dart
  `null` member is JS `null`, and `?? 0` is its `ToNumber`. No reader of the port tests a `null`
  member.
- A `List` (the value lies in more than one segment) becomes `PointElement()` with no property
  set. A JS Array has no `x`, `y`, `angle`, `skip` or `stop`. The bare point reads `undefined` by
  name and NaN by getter. `boundSegment` keeps `undefined === undefined` through
  `types.ElementPropertyRead` (`helpers/helpers.segment.dart`). Every other reader converts the
  value to a number, and NaN and `undefined` give the same result there.

Then `findPoint` reads `point[property]` of the wrapped point. For the bare point that is NaN,
and `_isBetween` is false, as for `undefined` upstream. `addPointsBelow` pushes the wrapped
point. Thus the port keeps the upstream result of the style case: no stacked fill. This is a
discrete decision (Chart.js ADR 0034). A `PointElement` with `x` and `y` set to NaN is wrong: it
gives other bound segments (Probes). A wrap that skips the item, or that takes the first item of
the list, draws a fill where upstream draws none.

`interpolatedLineTo` (`filler.drawing.js:200-205`) calls `lineTo(NaN, NaN)` for a `List`
result, the `ToNumber` of `undefined`. The canvas layer ignores a non-finite `lineTo`
(`canvas/canvas_ui_path.dart`), as a browser does. It calls `lineTo(p.x ?? 0, p.y ?? 0)` for a
`Point` result and makes no call for Dart `null`.

### 3. The edge objects of `_segments` and the `angle` read

`_segments` makes the edge objects as `PointElement()..[property] = edge`. The concrete
`PointElement.operator []=` takes `'angle'`, and `Element` takes `'x'`, `'y'` and other names
(`elements/element.point.dart`, `core/core.element.dart`). This keeps the computed key of
upstream. `_pointValue` of `element.line.dart` then reads `angle` through
`PointElementProperty`, with no change. `interpolate` of a radar target line with an edge object
gives the upstream points (Probes).

`_getEdge` (`filler.segment.js:94-99`) keeps `a && b`, `fn(a[prop], b[prop])` and the default 0.
`Math.max` and `Math.min` become `jsMax` and `jsMin` (`js/js_math.dart`). `check:js-semantics`
fails on a `dart:math` `max` or `min` with number operands. The same holds for
`clipToIndexBounds` (section 8) and `clipBounds` (`filler.drawing.js:189-192`).

The bounds record of the port is `({String property, double start, double end})`. `_getBounds`
of a bare point gives NaN where upstream gives `undefined`. `_boundSegment` gives the same result
for both, because each test of a bound is `between` or `compare` (`helpers.segment.js:77-110`).
Dart `null` stands for the `undefined` of a loop and for the `false` of
`notShape && _getBounds(...)` (`filler.drawing.js:139`).

### 4. The target type, the imports and the dispatch

The target of `_getTarget` (`filler.target.js:13-35`) is an `Object?`: a `types.LineElement`
(a boundary line, a stack line, or the `meta.dataset` of another dataset), a `SimpleArc`, `true`
(`'shape'`) or Dart `null`. Each file keeps the imports of its upstream file (Chart.js ADR 0028
§1, as Chart.js ADR 0038 applies it to the plugins):

| Dart file | Imports | Reads |
|---|---|---|
| `index.dart` | `element.line.dart` (`index.js:7`) | `line is LineElement` (`index.js:25`) |
| `filler.helper.dart` | `element.line.dart` (`filler.helper.js:7`, `elements/index.js`) | `LineElement({...})` (`:28`) |
| `filler.target.stack.dart` | `element.line.dart` and `element.point.dart` (`filler.target.stack.js:7`, `elements/index.js`) | `LineElement({...})` (`:29`), the wraps of section 2. The lines below are `types.LineElement` (`:88`) |
| `filler.target.dart` | `simpleArc.dart` (`filler.target.js:5`), and `element.point.dart` for the wrap only | `boundary is SimpleArc` (`:30`), `SimpleArc(...)` (`:83`), the polygon wrap (`:91`) |
| `filler.segment.dart` | `element.point.dart` for the wraps only | `target is! types.LineElement` for `!target.segments` (`filler.segment.js:15`), the wraps of sections 1 and 3 |
| `filler.drawing.dart` | no element module, not `simpleArc.dart` | a type switch over `types.LineElement` and `types.SimpleArc` (`filler.drawing.js:153`, `:201`) |

`filler.segment.js` and `filler.target.js` make object literals and import no element module.
A wrap of section 1 needs the class `PointElement`. Thus the ports of these two files import
`element.point.dart` for the constructor only. Each import line carries the marker of the row
`adapt-line-points-elements`. No other read of these files goes through the class.

The members `first`, `interpolate` and `pathSegment` of `types.LineElement` come from Chart.js
ADR 0038. This ADR uses them in `filler.drawing.dart`, `filler.segment.dart` and
`filler.target.stack.dart`.

`types/index.dart` gets one port-only interface for the duck-typed reads of a `simpleArc` target
(Chart.js ADR 0028 §1 item 1). It is not a declaration of `index.d.ts`:

```dart
/// simpleArc.js:4 `simpleArc`: the members that filler.drawing.js calls by
/// name on a fill target (:153, :201).
abstract interface class SimpleArc {
  /// simpleArc.js:11. Dart `null` for [bounds] is JS `undefined`.
  bool pathSegment(
    CanvasPath ctx,
    ({String property, double start, double end})? bounds,
    AnyObject opts,
  );

  /// simpleArc.js:18. The reader reads only `x` and `y`
  /// (filler.drawing.js:203).
  Point interpolate(PointElement point);
}
```

`SimpleArc` does not implement `types.LineElement`. `_segments` takes the `simpleArc` branch for
each target that is not a `types.LineElement`: a `SimpleArc` and `true`, as upstream.

The dispatch in `filler.drawing.dart`:

- `fill` (`:153`): a `types.LineElement` calls `pathSegment(ctx, tgt! as types.Segment,
  params)`. A `types.SimpleArc` calls `pathSegment(ctx, tgt as bounds record?, params)`. Another
  value throws a `TypeError`.
- `interpolatedLineTo` (`:201`): the same switch over `interpolate`.
- `clipVertical` and `clipHorizontal` (`:68-126`): `segments` and `points` are the members of a
  `types.LineElement`, else Dart `null`. `ctx.beginPath()` runs first. Then the loop over
  `segments!` throws a `TypeError` for `true` and for a `SimpleArc`, after the same calls as
  upstream (`for (const segment of undefined)`, `:74`, `:104`).

A dataset element of a user controller that is not a `LineElement` but has the line API works
upstream as the target of an index fill, and as a line below of a `stack` fill
(`filler.target.stack.js:47`, `:88-95`). In the port it throws a `TypeError` at the dispatch, in
`clipVertical` and `clipHorizontal` (a fill with `above` and `below`), or at the cast of the line
below in `findPoint`. A subclass of `LineElement` works. No built-in controller has such an element. The row
`adapt-filler-target-classes` records this (section 12).

### 5. `SimpleArc`

`simpleArc.dart` has `final class SimpleArc implements types.SimpleArc`, the Dart-cased class
`simpleArc` (AGENTS.md rule 2, Chart.js ADR 0012), with the fields `x`, `y` and `radius`
(`simpleArc.js:5-9`).

- `pathSegment(ctx, bounds, opts)` calls `ctx.arc(x, y, radius, bounds?.end ?? tau,
  bounds?.start ?? 0, true)` and returns `!jsTruthy(jsGet(opts, 'bounds'))`. Each upstream call
  gives `{move, reverse}`, so the result is always `true`.
- `interpolate(point)` reads `point['angle']` through `PointElementProperty` (NaN for
  `undefined`, as `Math.cos(undefined)` is NaN). It returns `InterpolatedPoint(x + cos(angle) *
  radius, y + sin(angle) * radius)`. The upstream result also has `angle`, but its only reader
  reads `x` and `y` (`filler.drawing.js:203`). The `Math.cos` and `Math.sin` of
  `simpleArc.js:22-23` reach only `ctx.lineTo`. They are display-only: `dart:math` with
  `// js-ok` (Chart.js ADR 0034).
- A negative radius throws in a browser (`IndexSizeError` of `arc`). The canvas layer throws a
  `RangeError` (`canvas/canvas_ui_path.dart`). A circular radar with `fill: {value: v}` below
  `min` gets a negative radius from `getDistanceFromCenterForValue`
  (`scale.radialLinear.js:489-499`). The port keeps the throw.

### 6. `meta.$filler` and the source object

`meta.$filler` is an extra property of `ChartMeta`, through `types.PropertyAccess`:
`(meta as types.PropertyAccess)[r'$filler'] = source` (`index.js:37`) and
`(metasets[i] as types.PropertyAccess)[r'$filler']` (`:56`, `:75`, `:84`). `ChartMeta` and
`types.ChartMeta` do not change. A typed field is 10 to 25 ns faster for each read, about
0.3 µs for each frame with 10 datasets. The gain reaches 0.1 ms only at about 1700 datasets. An
`Expando` gives `undefined` for a read by name, and the spec reads `meta.$filler`
(`plugin.filler.tests.js:6-7`).

The source literal (`index.js:26-34`) has a fixed shape, and `_resolveTarget` writes its `fill`
(`index.js:47`). It becomes a class in `index.dart`, where the literal is:

```dart
/// index.js:26-34, the source object of a dataset. The fields keep the
/// upstream key order. `index.js:47` writes [fill].
final class FillerSource {
  FillerSource({required this.visible, required this.index, required this.fill,
      required this.chart, required this.axis, required this.scale, required this.line});
  final bool visible;
  final double index;
  /// `false`, a `double` dataset index, a `String` mode or the option
  /// object `{value}` (filler.options.js:46-73).
  Object fill;
  final types.Chart chart;
  /// `meta.controller.options.indexAxis`: any option value.
  final Object? axis;
  /// `meta.vScale`. Dart `null` is JS `undefined`.
  final types.Scale? scale;
  /// A `LineElement` (`index.js:25`).
  final types.LineElement line;
}
```

`_decodeFill` and `_resolveTarget` never give `null`, so `fill` is `Object`. The other filler
files import `index.dart` with `show FillerSource` only. This is the Dart form of the JSDoc type
of the `source` parameter (`filler.target.stack.js:11-14`): a type-only dependency (Chart.js ADR
0003), not a concrete module that ADR 0028 §1 counts. Dart allows the import cycle.

The reads test `if (source is! FillerSource) continue;` for `if (!source) continue;`
(`index.js:57`), and `source is FillerSource && source.fill != false` for `_shouldApplyFill`
(`filler.helper.js:36-38`). The port writes only `null` and a `FillerSource`, and an absent
property reads `undefined`. For these values the test gives the result of `!source`.

`jsGet` of a `FillerSource` gives `undefined` for each key, as for the typed elements (AGENTS.md,
the hand-port rule). No reader at the pin reads the source by a dynamic key.

### 7. `first()` that can be `null`

`LineElement.first()` gives Dart `null` for the upstream number 0 of a line without segments
(`element.line.js:327-331`). `clipVertical` reads `target.first()?.x ?? double.nan`
(`filler.drawing.js:93`), and `clipHorizontal` reads `target.first()?.y ?? double.nan` (`:123`).
`(0).x` is `undefined`, and `lineTo(undefined, clipY)` is `lineTo(NaN, clipY)` after the WebIDL
conversion. The canvas layer ignores it, as the DOM does.

### 8. `clipToIndexBounds` (#12283) and the clip area

`clipToIndexBounds` (`filler.drawing.js:21-38`) is in the pin. The port ports it with the file,
and the ledger row `b9725745` closes with the port commit.

- `!iScale || iScale.getPointPositionForValue` becomes
  `iScale == null || iScale is types.RadialLinearScale`.
- `Math.min` and `Math.max` become `jsMin` and `jsMax`.
- `{...area, left, right}` and `{...area, top, bottom}` become a private `_Trbl implements TRBL`
  with four final fields. The spread also copies `width` and `height`, but `clipArea` reads only
  `left`, `top`, `right` and `bottom` (`helpers.canvas.ts:328-333`).
- The function takes `ChartArea?` and returns `TRBL?`: Dart `null` is the `undefined` area of a
  chart without a layout. For a cartesian index scale, `area!.left` throws a `TypeError` at the
  upstream site (`filler.drawing.js:36`).
- `_drawfill` calls `clipArea(ctx, clipToIndexBounds(area, meta.iScale)!)`. For a radial index
  scale without a layout, the `!` throws a `TypeError`. Upstream `clipArea` first calls
  `ctx.save()` and `ctx.beginPath()` and then throws at `area.left`. Thus the port records two
  canvas calls less, and upstream keeps an unbalanced `save`. Chart.js ADR 0034 does not protect
  canvas calls. The throw stays. The row `adapt-filler-target-classes` states the difference.

### 9. The radial targets and the `null` center

`computeBoundary` tests `scale is types.RadialLinearScale` for `scale.getPointPositionForValue`
(`filler.target.js:50`). `computeCircularBoundary` (`:73-94`) reads `options`, `max`, `min`,
`getLabels()`, `getPointPositionForValue` and `getDistanceFromCenterForValue` through
`types.RadialLinearScale`, and `getBaseValue()` through `_getTargetValue`
(`filler.options.js:112`). The filler reads no `xCenter` and no `yCenter`. It reads only `x`, `y`
and `angle` of the record. `getPointPosition` reads `xCenter ?? double.nan` (Chart.js ADR 0033
§3). Thus a target before the first layout has NaN points, as upstream. The radar fill without a
layout throws a `TypeError` (section 8), as upstream. Chart.js ADR 0033 Open 4 closes with no
new code.

`types.Scale` gets `double getBaseValue()` (`index.d.ts:1376`, `core.scale.js:950-955`, Chart.js
ADR 0028 Open 2). The test fakes that implement `types.Scale` have a `noSuchMethod`, so they do
not change.

`computeLinearBoundary` keeps `scale = {}` for a missing scale: `_getTargetPixel(fill, null)`
gives `null` for `'start'`, `'end'` and the base pixel, and a `TypeError` for `{value}`, as
`{}.getPixelForValue(...)` throws (`filler.options.js:80-93`).

### 10. The draw calls and the decimation

The draw calls stay one to one with upstream. Each segment of the source line gets its own
`save`, rect clip, path, `fill` and `restore` (`filler.drawing.js:128-165`). The rect clips of
`clipArea` and `clipBounds` become `clipRect` in the canvas layer (`canvas/canvas_ui.dart`,
`singleRect`). Only `clipVertical` and `clipHorizontal` (a fill with `above` and `below`) make
path clips. The target is new in each draw, as upstream: an animation moves the points in each
frame.

The filler has no code for the decimation. The decimation replaces the data in
`beforeElementsUpdate` (`plugin.decimation.js:249-265`), and the line controller writes
`line._decimated` (`controller.line.js:59`). The filler reads `line.points` in
`afterDatasetsUpdate` and in the draw hooks, after that update. A decimated source line takes
`pathSegment`, not `fastPathSegment` (`element.line.js:188`), as upstream. A `stack` fill stays
quadratic in the decimated count.

### 11. One implementer of the point interfaces

No class in `lib/` other than `PointElement` of `elements/element.point.dart` implements,
extends or mixes in `types.PointElement`, `types.RadialPointElement` or `types.SplinePoint`.
The interface declarations of `lib/src/types/` are the only other names. A second implementer
anywhere in the program makes every curved line 64 to 70 % slower on AOT and about 2 times
slower on dart2wasm, also in a chart without a fill (Benchmarks). A test enforces the rule. It
does not cover `types.LineElement` and `types.Segment`: no probe measured them, and their reads
run once for each line and each segment, not for each point.

### 12. Tests, rows and records

- `differences.md`, row `adapt-line-points-elements`: the code column adds
  `filler.segment.dart` (`pointsFromSegments`, `segments`), `filler.target.dart`
  (`computeCircularBoundary`) and `filler.target.stack.dart` (`findPoint`). The upstream column
  adds `filler.segment.js:38-43`, `:65-82`, `filler.target.js:90-93` and
  `filler.target.stack.js:58-109`. The text states the five wraps of section 1, the bare point of
  section 2, the two `element.point.dart` imports and the same results at each reader.
- `differences.md`, new row `adapt-filler-target-classes` (kind `adapt`): the dispatch of
  section 4 and the clip area of section 8.
- No row for `meta.$filler`, `SimpleArc`, `first()`, the edge objects, the radial targets and the
  decimation. Each keeps the upstream results.
- The spec port `test/specs/plugin.filler_test.dart`, a reference generator and test of the
  filler draw calls and targets (Chart.js ADR 0041), unit tests of the bare point, the edge
  objects, `SimpleArc` and the dispatch throws, and the guard test of section 11.
- `performance.md`, the phase 8 section: the Benchmarks of this ADR.
- `upstream-ledger.md`: the row `b9725745` closes with the port commit of
  `filler.drawing.dart`.

## Alternatives considered

A panel wrote three drafts: fidelity first (F), performance first (P) and simplicity first (S).
A judge scored them in the order of the decision protocol and ran its own probe (the second
implementer). F won. The judge took the guard test, `jsMin` and `jsMax` and the `is!` test from
P, and the bare-point pin, the computed-key edge objects and the wrap in `findPoint` from S.

**The plain points.**
- Widen `points` to `List<Point>` (the type of `index.d.ts:2026`). Each reader of `skip`, `stop`
  and the control points then needs a type test for each point of each line, also without a
  fill. A `Point` has no `angle` and no `undefined` state, so the bare point and the radial
  records still need a class. It changes `types`, `element.line`, `helpers.segment`,
  `helpers.curve` and `helpers.extras`.
- A port-only light class `FillerPoint implements types.RadialPointElement`. It saves about
  4 ns for each point on dart2wasm and nothing on AOT. Its existence alone makes every curved
  line 64 to 70 % slower on AOT and 2 times slower on dart2wasm (Benchmarks). It also needs
  about 60 to 80 lines for the members of `types.PointElement`.
- The setter `points` wraps a non-element. A type test for each point at each write in a shared
  layer, and the shared setter must know the filler records.
- A record or a plain class for the stack results. The readers of `points` need point elements.
- A port-only file `filler_point.dart` with the wrap helpers (P). It moves the wraps away from
  their upstream lines. The judge chose the inline wraps for the structure.

**The list result.**
- `PointElement()` with `x` and `y` set to NaN. Other bound segments (Probes).
- Skip the item, or take its first item. Draws a fill where upstream draws none.
- A second list of raw results in `_buildStackLine` and a `_valueOf` helper (F). The wrap in
  `findPoint` gives the same reads with less code.
- A `DIVERGES` row `adapt-filler-interpolate-list` (the scout proposal). Not necessary: the bare
  point keeps the behavior.

**The `angle` read.**
- `_pointValue` reads `angle` of a new port-only point type. Changes `element.line.dart` and
  `helpers.interpolation.dart`.
- A record `({String property, double value})` and a filler copy of `interpolate`. Duplicates
  upstream code.
- A switch over `x`, `y` and `angle` for the edge objects (F). The by-name write keeps the
  computed key with less code.

**The target and the dispatch.**
- The class `LineElement` in `filler.drawing.dart` and `filler.segment.dart` (F). These upstream
  files do not import the class. The plugin panel of Chart.js ADR 0038 rejects this form under
  Chart.js ADR 0028 §1.
- An import of `simpleArc.dart` in `filler.drawing.dart`. No code, but an import that
  `filler.drawing.js` does not have.
- A common port-only interface `FillTarget` for `LineElement` and `SimpleArc`, with an adapter
  object for each line in each draw. The two `pathSegment` signatures differ, and the adapter is
  an object that upstream does not have.
- `SimpleArc extends LineElement`. `_segments` then takes the line branch. Wrong.
- `if (!jsTruthy(source)) continue;` and then a cast (F). It also keeps a `TypeError` for a truthy
  user value in `$filler`, but needs more code. No reader at the pin writes such a value.

**`meta.$filler`.**
- A typed field `ChartMeta.filler` with a case in the access by name. Faster by 10 to 25 ns for
  each read, below any frame figure. It puts a plugin field into a core class and its interface,
  and changes 6 test fakes of `types.ChartMeta`.
- An `Expando`. No gain on AOT, slower on dart2wasm, and a read by name gives `undefined`.
- A Map for the source. A hash read for each of about 10 reads in each draw.

**The draw calls.**
- Merge the fills of the segments of one color into one path. It changes the draw calls, the
  anti-aliased seams and the `evenodd` decision of each segment. No figure shows a gain.
- Skip the `clipBounds` rect when it contains the dataset clip. It changes the draw calls. A
  rect clip is already a `clipRect`.
- Keep the target between draws. The points of a target move in each animation frame.

## Consequences

- The filler gives the upstream segments, bounds, fill sources and draw calls for the plain
  points, the radial records, the list result of `interpolate` and the edge objects. The
  protected throws stay: `shape` with two colors, a radar fill without a layout, `{value}`
  without a scale, and a negative arc radius.
- `element.line.dart`, `helpers.segment.dart`, `helpers.interpolation.dart`,
  `core.controller.dart` and `types.ChartMeta` do not change. `types.Scale` gets
  `getBaseValue`. `types/index.dart` gets the port-only interface `SimpleArc`.
- `PointElement` stays the only implementer of the point interfaces in `lib/`. A test fails on a
  second one.
- A dataset element of a user controller that is not a `LineElement` cannot be a fill target. A
  radar fill without a layout records two canvas calls less than upstream before its throw.
- A user plugin that reads `meta.$filler` by a dynamic key gets `undefined` for each field.
- One new row (`adapt-filler-target-classes`) and one changed row
  (`adapt-line-points-elements`). New `DIVERGES` markers at the five wrap sites, the two
  `element.point.dart` imports, the dispatch sites and the clip-area site.
- Chart.js ADR 0017 Open (the plain points of the filler), Chart.js ADR 0025 Open 7 and Chart.js
  ADR 0033 Open 4 close by this ADR. The accepted ADRs do not change.

## Open

1. **Upstream drops the stacked fill** above a line with segment styles or with an `x` that goes
   back (Probes). It looks like an upstream defect. The port keeps it (AGENTS.md rule 1, Chart.js
   ADR 0034). Owner: the porting lead. Trigger: an upstream report or fix. A note in the Signals
   of `upstream-ledger.md` tracks it.
2. **The frame cost of the filler on the devices.** Owner: step 8 of phase 8. Trigger: the start
   of step 8. Add fill cases to the frameless benchmark before the device runs: a line with gaps
   and `above` and `below` (the path clips), a `stack` fill of 1000 points, and a radar fill.
   Record the frame, draw and raster figures in `performance.md`.
3. **`interpolate` and the quadratic stack.** `interpolate` on dart2wasm costs about 2 times V8.
   The `stack` fill is quadratic, as upstream. Owner: step 8. A cursor or binary-search form of
   `interpolate` changes a shared element and needs its own design and a new ADR.
4. **The gallery implementers of `SplinePoint`.** `apps/chartjs_gallery/lib/demo/demo_chart.dart`
   (`CurvePoint`) and `lib/demo/spline_demo.dart` (`_DemoPoint`) implement `types.SplinePoint`.
   In a gallery build that reaches them, each curved line pays the cost of section 11. Owner: the
   porting lead, before the step 8 frame figures. Check if `main_stress.dart` and
   `main_bench.dart` reach these classes. A change of the gallery is a separate decision.
5. **The members of `types.LineElement`.** This ADR uses the `first`, `interpolate` and
   `pathSegment` of Chart.js ADR 0038. If that ADR changes them, the dispatch of section 4
   follows it.

## Evidence

- **E0, upstream source** at `v4.5.1+7169e651`, `src/`:
  - `plugins/plugin.filler/index.js:7-97`, `filler.helper.js:7-38`, `filler.options.js:10-137`,
    `filler.segment.js:1-99`, `filler.target.js:1-94`, `filler.target.stack.js:7-109`,
    `filler.drawing.js:1-206`, `simpleArc.js:1-27`
  - `plugins/index.js:1-7`, `plugins/plugin.decimation.js:241-265`
  - `elements/element.line.js:71`, `:118`, `:185-190`, `:308-331`, `:351-379`
  - `helpers/helpers.segment.js:77-129`, `helpers/helpers.canvas.ts:328-333`
  - `core/core.scale.js:950-955`, `scales/scale.radialLinear.js:489-499`, `:529-530`
  - `controllers/controller.line.js:59`, `types/index.d.ts:1376`, `:2026`
  - `test/specs/plugin.filler.tests.js:1-11`
- **E1, behavior probes** (Node.js, the pinned build, x64 v24.12.0): the kinds of points that
  reach the `points` setter, the `interpolate` results, `first()`, the `shape` throw, the arc
  calls and the source keys of five fill configs. The filler hook calls of the list result, the
  radar gap, the empty target, `offset: true` and 5000 points with and without the decimation.
  The inputs and results of the `_segments` steps for three charts. The radar fill without a
  layout. The draw-call counts of eight configs. The bare point against the NaN point. The
  decimation with min-max and lttb and `fill: 'stack'`. The cost of `chart.draw()` with a stack
  fill. The results are in Context, Probes.
- **E2, Dart probes:** a temporary test in the package ran `boundSegments` and `boundSegment` of
  the port on the three captured charts (3 of 3 equal to Node.js) and the bare point against the
  NaN point (the same bound segments as Node.js). Both files were deleted after the runs.
- **E3, benchmarks:** the C1 hot path with one implementer, with a second implementer in the
  lines, and with a second implementer that never enters a line (AOT and dart2wasm, three series
  each). The wrap of a point, the filler lines, `interpolate`, the stack target and the read of
  `meta.$filler` (AOT and dart2wasm, two or three runs each). `interpolate` and the point
  allocations in V8. The results are in Context, Benchmarks.
- **E4, the port:** `elements/element.line.dart` (`first`, `interpolate`, `pathSegment`,
  `_pointValue`, the `points` setter), `elements/element.point.dart` (`operator []=`),
  `types/index.dart` (`LineElement`, `PointElement`, `RadialPointElement`,
  `PointElementProperty`, `ElementPropertyRead`, `RadialLinearScale`),
  `core/core.controller.dart` (`ChartMeta`), `helpers/helpers.segment.dart` (`boundSegment`),
  `helpers/helpers.interpolation.dart` (`InterpolatedPoint`), `canvas/canvas_ui_path.dart`
  (`lineTo`, `arc`), `canvas/canvas_ui.dart` (`clip`), `js/js_math.dart` (`jsMax`, `jsMin`),
  `tool/src/js_semantics.dart` (the `max` and `min` check), `js/js_object.dart` (`jsGet`).
- **E5, the rows:** [differences.md](../differences.md) rows `adapt-line-points-elements`,
  `adapt-spline-control-point-nan` and `adapt-filler-target-classes`.
