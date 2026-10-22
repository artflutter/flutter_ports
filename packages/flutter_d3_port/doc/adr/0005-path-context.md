# D3 ADR 0005: Path context and drawing

- Status: proposed
- Date: 2026-10-20
- Gate: D3 phase 1 for the pure interface, because the d3-path pilot implements it. D3 phase 4
  for the `dart:ui` builder, because d3-shape and the gallery draw with it.
- Related: [Chart.js ADR 0034](../../../flutter_chartjs_port/doc/adr/0034-no-display-only-js-exactness.md)
  (no Chromium geometry),
  [Chart.js ADR 0013](../../../flutter_chartjs_port/doc/adr/0013-canvas-model.md) (proposed: the
  canvas layer of the Chart.js port), [D3 ADR 0002](0002-file-naming-and-layout.md) (port-only
  paths), [D3 ADR 0003](0003-number-to-string.md) (the path strings),
  [D3 ADR 0006](0006-generators-accessors-and-js-values.md) (the `context` accessor and the JS
  values), [porting-flow.md](../porting-flow.md) §2.7 and §5.1,
  [prior art](../prior-art/d3-packages.md)

## Context

**How D3 draws.** A D3 generator returns a path string when its context is `null`. With a context,
it calls the path methods of the context and returns nothing.
- `d3-shape src/line.js:24` makes a d3-path `Path` when the context is `null`. `:34` returns its
  string. `:53-55` is the `context` accessor.
- `d3-shape src/path.js:18` gives `() => new Path(digits)`. Thus the string output is a d3-path
  `Path` that takes the calls.
- `d3-geo src/path/index.js:52` takes a `PathString` for a `null` context, else a `PathContext`.
  `PathContext` calls `moveTo`, `lineTo`, `closePath` and `arc` on the user context
  (`src/path/context.js:23-43`).

**The calls.** A scan of the pinned `src/` files, with the comments removed, found these calls of
`context.<method>(` and `_context.<method>(`:

| Method | Calls |
|---|---:|
| `lineTo` | 82 |
| `moveTo` | 53 |
| `closePath` | 33 |
| `arc` | 17 |
| `bezierCurveTo` | 9 |
| `quadraticCurveTo` | 3 |
| `rect` | 2 |

- 33 files make these calls: 29 in d3-shape, 2 in d3-delaunay, 1 in d3-geo and 1 in d3-chord.
- No D3 module calls `arcTo` or `ellipse` on a context. The d3-path `Path` has `arcTo`
  (`d3-path src/path.js:51`).
- No D3 module calls a transform, a style, `beginPath`, `fill` or `stroke` on a context. The two
  other calls are `context.selection` of d3-axis and d3-selection. These are DOM selections.

**The implementers.**
- d3-path `Path` has `moveTo`, `closePath`, `lineTo`, `quadraticCurveTo`, `bezierCurveTo`,
  `arcTo`, `arc`, `rect` and `toString` (`d3-path src/path.js:33-144`). `arc` and `arcTo` throw for
  a negative radius (`:55`, `:104`).
- d3-delaunay has its own string `Path` with `moveTo`, `closePath`, `lineTo`, `arc(x, y, r)`,
  `rect` and `value` (`d3-delaunay src/path.js:3-37`).
- The test contexts have fewer methods: d3-shape `test/polygonContext.js:3-12`, d3-delaunay
  `test/context.js:1-19` and d3-geo `test/path/test-context.js:1-10`.
- The d3-path specs pass truthy and falsy values as `ccw`: `1`, `"1"`, `true`, `10`, `"3"`,
  `"string"`, `0`, `null` and `undefined` (`d3-path test/path-test.js:231-243`).

**The DOM.** The WHATWG mixin `CanvasPath` has 10 methods: `closePath`, `moveTo`, `lineTo`,
`quadraticCurveTo`, `bezierCurveTo`, `arcTo`, `rect`, `roundRect`, `arc` and `ellipse`. D3 uses 8
of them. WebIDL converts the `optional boolean counterclockwise = false` of `arc` with ToBoolean.

**`dart:ui`.** `ui.Path` has `moveTo`, `lineTo`, `quadraticBezierTo`, `cubicTo`, `arcTo`,
`arcToPoint`, `addRect` and `close`. It does not have these Canvas 2D path rules
([Chart.js ADR 0013](../../../flutter_chartjs_port/doc/adr/0013-canvas-model.md), Context):
- `arc` draws a line from the current point to the start of the arc.
- A sweep of 2π or more draws a full circle. `ui.Path.arcTo` draws nothing for a sweep that is a
  multiple of 2π.
- `arcTo` is the tangent arc of two lines.
- A negative radius throws.
- A path method with a non-finite argument does nothing.
- `lineTo` and the curves on an empty path start a subpath at their first point.

**The Chart.js canvas layer.** `packages/flutter_chartjs_port/lib/src/canvas/` has 6 files with 4,981
lines. It has a retained bitmap, the device pixel ratio, styles, text and a circle batch (Chart.js
ADR 0013). `canvas.dart` declares a `CanvasPath`. It also imports a Chart.js type library
(`canvas.dart:26`). `canvas_ui_path.dart` (1,073 lines) builds the `ui.Path` in bitmap space, with
the transform at the time of each point. `REUSE.toml` gives `packages/flutter_chartjs_port/**` the MIT
notice of Chart.js Contributors.

**Prior art.** No `d4` package has a `dart:ui` adapter. A user writes a `Path` over `dart:ui` or
parses the SVG string. `fluent_2` sends its geometry to a path sink with the d3-path method names.
A `dart:ui` builder implements the sink. In the tests, a string recorder implements it
([prior art](../prior-art/d3-packages.md)).

**Lints.** very_good_analysis 10.3.0 enables `avoid_positional_boolean_parameters` and
`avoid_renaming_method_parameters` (`analysis_options.10.3.0.yaml:42`, `:47`). The first lint
flags a positional `bool` parameter. The second lint flags an override that renames a parameter.

## Decision

### 1. The pure interface (gate 1)

The port-only library `lib/src/canvas/canvas_path.dart` declares the interface. It is a pure
layer. Its header is `// Original code, not ported from D3: the path context of the generators.`

```dart
abstract interface class CanvasPath {
  void moveTo(double x, double y);
  void closePath();
  void lineTo(double x, double y);
  void quadraticCurveTo(double x1, double y1, double x, double y);
  void bezierCurveTo(
      double x1, double y1, double x2, double y2, double x, double y);
  void arcTo(double x1, double y1, double x2, double y2, double r);
  void arc(double x, double y, double r, double a0, double a1,
      [Object? ccw = false]);
  void rect(double x, double y, double w, double h);
}
```

- The 8 methods are the methods of the D3 contexts. The names and the argument order are those of
  the DOM. `roundRect` and `ellipse` are not in the interface. No D3 module calls them.
- The parameter names are those of `d3-path src/path.js`. Thus the port of `Path` keeps them, as
  `avoid_renaming_method_parameters` asks.
- Numbers are `double`, as Chart.js ADR 0032 §7 asks. The D3 callers convert their numbers with
  `+x` before the call.
- `ccw` is an `Object?`. An implementation tests it with `jsTruthy`. This is the ToBoolean of
  WebIDL and the `!!ccw` of `d3-path src/path.js:101`. The form also keeps
  `avoid_positional_boolean_parameters` quiet.
- The generators keep the upstream `context` accessor. Its value is a `CanvasPath?`
  ([D3 ADR 0006](0006-generators-accessors-and-js-values.md)).

### 2. The implementers

- **d3-path `Path`** implements `CanvasPath` (phase 1). It builds the string of
  [D3 ADR 0003](0003-number-to-string.md). `Path.toString()` returns the string.
  - The d3-path specs pass numbers as coordinates. Thus `Path` keeps the `double` parameters. On
    a `double`, the upstream `+x` is the identity. The port writes no code for it.
- **A ported class with fewer methods** implements `CanvasPath` with a `noSuchMethod` override:
  `dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);`. Dart then
  accepts the absent members. A call of an absent member throws a `NoSuchMethodError`, as a JS
  call of an absent method throws a `TypeError`. This is a translation rule. It needs no
  `DIVERGES` marker. Examples are the `Path` of d3-delaunay and the three test contexts.
- **User code** can implement `CanvasPath`, for example to record the calls or to build another
  output.

### 3. The `dart:ui` builder (gate 4)

The port-only library `lib/src/canvas/ui_path_context.dart` declares the class `UiPathContext`.
It implements `CanvasPath`. It builds a `ui.Path`. It is not a pure layer. Phase 4 adds it with
d3-shape and the gallery.
- It applies the WHATWG path rules that change the geometry: the six rules of the Context.
- A negative radius in `arc` or `arcTo` throws a `RangeError`, as Chart.js ADR 0013 does for the
  DOM `IndexSizeError`.
- It has no transform, no style, no text and no device pixel ratio. D3 calls none of them on a
  context. Transforms belong to the Flutter canvas of the caller.
- It has no Chromium-exact arc geometry. The principle of Chart.js ADR 0034 (decision 3) applies:
  the arc points are display values.
- The implementation is new code of this package. It does not copy `canvas_ui_path.dart`.
- Port-only tests in `test/port/canvas/` compare the path of each rule with the expected geometry
  (`@TestOn('vm')`).

A painter helper and a widget layer come in phase 4 and phase 8. They draw the `ui.Path` with a
`ui.Paint` of the caller. Phase 4 records their frame figures in `doc/performance.md`.

### 4. No shared canvas layer now

The port does not extract the Chart.js canvas layer into a shared package now. A deferred plan
keeps the question ([porting-flow.md](../porting-flow.md) §5.1). Its trigger is a D3 caller that
needs styles, text or transforms on a context, for example the DOM layer of phase 7.

## Alternatives considered

- **Extract the Chart.js canvas layer into a shared package.** Rejected for now. It reuses tested
  arc code. But it moves 4,981 lines of the other port during its phases. Most of the layer
  (styles, text, the bitmap and the device pixel ratio) has no D3 caller. The deferred plan of
  section 4 keeps the option.
- **Import `canvas.dart` of `flutter_chartjs_port`.** Rejected. The `implementation_imports` lint flags
  the import. `canvas.dart` imports a Chart.js type library. Each D3 user then gets the Chart.js
  port.
- **Copy `canvas_ui_path.dart`.** Rejected. The file applies the transform when it adds a point.
  It also works in bitmap space (Chart.js ADR 0013 §5-6). D3 needs neither. A copy also carries the
  MIT notice of Chart.js Contributors into an ISC package.
- **Draw from the SVG string.** Rejected as the drawing path. The painter then formats and parses
  each coordinate in each frame. The port then also has no context API. A port-only test can use the
  string as an oracle.
- **A `bool` parameter for `ccw`.** Rejected. The d3-path specs pass strings, numbers, `null` and
  `undefined`. `avoid_positional_boolean_parameters` also flags it.
- **Stub methods that throw, in place of `noSuchMethod`.** Rejected. Each class then needs one stub
  for each absent method. `noSuchMethod` gives the same throw with one member.
- **The 10 methods of the WHATWG mixin.** Rejected. No D3 module calls `roundRect` or `ellipse`.
  Each implementer then needs two more members.

## Consequences

- Each generator stays a pure layer. Its specs run with a context that records the calls, on the
  VM, with dart2js and with dart2wasm.
- A Flutter app draws a generator through `UiPathContext` from phase 4. Before phase 4, it can use
  the path string.
- The interface has 8 methods. A later D3 caller of another method needs a new member and a new D3
  ADR.
- The arc geometry of the builder can differ from Chrome in the last pixel. Such a difference is
  display only. It needs no row.
- The deferred plan of a shared canvas layer stays open ([porting-flow.md](../porting-flow.md)
  §5.1).

## Evidence

- The call counts: a scan of the pinned `src/**/*.js` files with the comments removed, for the
  pattern `\b_?context\.<method>\(`. delaunator is at v5.1.0 and robust-predicates at v3.0.3.
- The lint probe: a package with very_good_analysis 10.3.0 and Dart 3.12.2 declared the interface
  of section 1. It also declared a class with fewer methods and a `noSuchMethod` override.
  `dart analyze --fatal-infos` gave no issue for the parameter `[Object? ccw = false]` or for the
  class.
- The size of the Chart.js canvas layer: `wc -l packages/flutter_chartjs_port/lib/src/canvas/*.dart`
  at commit `75178b5`.
