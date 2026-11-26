# D3 ADR 0015: Native forms of d3-shape

- Status: accepted (2026-11-26): its code and the tests of section Tests pass.
- Date: 2026-11-26
- Supersedes: [D3 ADR 0006](0006-generators-accessors-and-js-values.md) §1–§5 for d3-shape
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [D3 ADR 0011](0011-interpolate-native-forms.md), [D3 ADR 0014](0014-path-native-forms.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

`d3-shape` 3.2.0 is the first D3 module ported after `d3-path` that introduces D3's generator
pattern: callable closures with chainable dual getter/setter accessors (`arc`, `line`, `lineRadial`,
`area`, `areaRadial`, `link`, `linkHorizontal`, `linkVertical`, `linkRadial`, `pie`, `symbol`,
`stack`), configurable curve factories (`curveBundle.beta`, `curveCardinal*.tension`,
`curveCatmullRom*.alpha`), and array-with-properties results (`stack` series and points).

[D3 ADR 0006](0006-generators-accessors-and-js-values.md) (proposed) translated generators using a
JS runtime (`JsCallable`, `jsInvoke`, `this` forwarding via `apply`, `Object?` accessors, `absent`
sentinels). Following [D3 ADR 0007](0007-native-dart-forms.md) (zero JS runtime),
[D3 ADR 0008](0008-module-packages.md) (one package per D3 module),
[D3 ADR 0011](0011-interpolate-native-forms.md) (const callable factories), and
[D3 ADR 0014](0014-path-native-forms.md) (`CanvasPath` and `UiPathContext`), `d3-shape` 3.2.0 is
ported as its own package `flutter_d3_shape_port` depending only on `flutter_d3_path_port`.

## Decision

1. **Pure Dart core (`d3_shape.dart`) + direct Flutter `Canvas` layer (`flutter_d3_shape_port.dart`).**
   `package:flutter_d3_shape_port/d3_shape.dart` imports only
   `package:flutter_d3_path_port/d3_path.dart` (zero Flutter imports) so it runs on the Dart VM,
   dart2js, and dart2wasm. Every path-emitting generator targets `CanvasPath`, producing an SVG
   string via `Path(digits)` (default `digits = 3`) when `context == null`, or drawing directly
   into any `CanvasPath` — including `UiPathContext` from `flutter_d3_path_port` — with zero SVG
   string allocation when `context != null`.
   `package:flutter_d3_shape_port/flutter_d3_shape_port.dart` additionally exports
   `lib/src/ui/shape_ui.dart` with direct `toUiPath` / `drawToUiPath` extensions on every generator.
2. **Typed generic callable generator classes (`Arc<T>`, `Line<T>`, `LineRadial<T>`, `Area<T>`,
   `AreaRadial<T>`, `Pie<T>`, `Link<L, N>`, `LinkRadial<L, N>`, `ShapeSymbol<T>`, `Stack<D, K>`).**
   Each upstream factory function (`arc`, `line`, `lineRadial`, `area`, `areaRadial`, `pie`, `link`,
   `linkHorizontal`, `linkVertical`, `linkRadial`, `symbol`, `stack`, plus deprecated aliases
   `radialLine` and `radialArea`) constructs the corresponding callable class (`call(...)`).
   The symbol generator class is named `ShapeSymbol<T>` to avoid colliding with `dart:core.Symbol`.
   No JS `this`-binding or variadic `arguments` forwarding exists; accessors have statically typed
   Dart function signatures (`ArcAccessor<T>`, `PointAccessor<T>`, `DefinedAccessor<T>`,
   `PieValueAccessor<T>`, `PieAngleAccessor<T>`, `LinkNodeAccessor<L, N>`,
   `LinkCoordinateAccessor<N>`, `SymbolTypeAccessor<T>`, `SymbolSizeAccessor<T>`,
   `StackKeysAccessor<D, K>`, `StackValueAccessor<D, K>`).
3. **Dual accessor ergonomics: typed getter/setter properties + typed `*Const` constant setters.**
   Each accessor is a typed getter/setter property (e.g. `l.x`, `l.x = (d, i, data) => d.x`),
   supporting Dart cascades (`line<Point>()..x = .....y = ...`). To set a constant value without
   allocating a closure or accepting `Object?`, every dual function/constant accessor also provides
   a typed `*Const` method for Dart cascades (e.g. `arc<PieArc<double>>()..innerRadiusConst(50)..outerRadiusConst(100)`),
   plus optional constant named parameters on `arc`, `pie`, `symbol`, and `stack`. Internally,
   constant accessors store their primitive value directly to eliminate indirect closure calls on
   hot loops while still returning a callable constant function from the getter.
4. **Typed data models and zero-allocation records.**
   - `ArcDatum` interface + immutable `const ArcData` and `const PieArc<T> implements ArcDatum`,
     so `pie<T>()(data)` slices pass directly into `arc<PieArc<T>>()` with zero boilerplate.
   - `LinkDatum<N>` interface + immutable `const LinkData<N>`.
   - `pointRadial(angle, radius)` and `Arc.centroid([d])` return `(double, double)` records.
   - Default point accessors (`x`, `y`, `angle`, `radius`) accept both `(double, double)` records
     and `List<num>` tuples.
   - `StackPoint<D>` holds typed `double y0`, `double y1`, and `final D data` (with `operator []`
     and `operator []=` for `0`/`1` indexing). `StackSeries<D, K>` holds `final K key`, `int index`,
     and `final List<StackPoint<D>> points`. Because `StackPoint<D>` and `StackSeries<D, K>` are
     covariant in `D` and `K`, all `stackOrder*` and `stackOffset*` functions take non-generic
     `List<StackSeries<Object?, Object?>>`.
   - `Pie` and `stackOrder*` preserve JavaScript ES2019 stable sort ordering by breaking ties on
     original index, since Dart's `List.sort` is not guaranteed stable.
5. **Typed `Curve` interface and `const` configurable curve factories.**
   `abstract interface class Curve` declares `areaStart`, `areaEnd`, `lineStart`, `lineEnd`, and
   `point(double x, double y)`, and `typedef CurveFactory = Curve Function(CanvasPath context)`.
   Configurable curves (`curveBundle`, `curveCardinal`, `curveCardinalClosed`, `curveCardinalOpen`,
   `curveCatmullRom`, `curveCatmullRomClosed`, `curveCatmullRomOpen`) are `const final` callable
   classes with typed parameter methods (`.beta(double)`, `.tension(double)`, `.alpha(double)`)
   matching [D3 ADR 0011](0011-interpolate-native-forms.md) §5. `curveRadial(CurveFactory)` returns
   a callable `CurveRadialFactory` exposing `innerCurve`.
6. **Typed `SymbolType` interface and `const` built-in symbols.**
   `abstract interface class SymbolType` declares `void draw(CanvasPath context, double size)`.
   All 13 built-in symbols (`symbolAsterisk`, `symbolCircle`, `symbolCross`, `symbolDiamond`,
   `symbolDiamond2`, `symbolPlus`, `symbolSquare`, `symbolSquare2`, `symbolStar`, `symbolTimes`,
   `symbolTriangle`, `symbolTriangle2`, `symbolWye`, plus `symbolX = symbolTimes`) are `const`
   instances. `symbolsFill` (alias `symbols`) and `symbolsStroke` are `const List<SymbolType>`.
7. **Public exports under ADR 0011.**
   `lib/d3_shape.dart` exports every pure file in `lib/src/` without `show`/`hide` combinators.
   `lib/flutter_d3_shape_port.dart` exports `d3_shape.dart` and `lib/src/ui/shape_ui.dart`.
   `flutter_d3_port` re-exports both.

## Rejected

- Keeping `Object?` accessors and `jsInvoke` from D3 ADR 0006: loses static type safety, forces
  runtime type tests on every datum, and adds JS-runtime overhead on every vertex.
- Returning `List<double>` from `pointRadial` and `Arc.centroid`: allocates a 2-element list on
  every call instead of a stack/register `(double, double)` record.
- Representing `StackSeries` as `List<List<double>>` plus external `Expando` metadata for `key`,
  `index`, and `data`: slow hash-table lookups and untyped metadata.

## Consequences

- Upstream spec cases that test JS `this`-binding propagation (`f.apply(that, args)`), arbitrary
  variadic extra arguments beyond the typed signature, or JS string-to-number coercion (`"0.1"`,
  `"42.0"`, `{valueOf: ...}`) skip with `diverges: adapt-shape-typed-api` (recorded in
  `packages/flutter_d3_shape_port/doc/differences.md`).
- Flutter apps draw curves, arcs, pies, streamgraphs, links, and symbols directly onto `Canvas`
  via `UiPathContext` with zero SVG string formatting or parsing.
- Downstream D3 modules (`d3-chord`, `d3-axis`, `d3-geo`) can build directly on `flutter_d3_shape_port`.

## Tests

- `packages/flutter_d3_shape_port/test/*_test.dart`
- `packages/flutter_d3_shape_port/test/curve/*_test.dart`
- `packages/flutter_d3_shape_port/test/offset/*_test.dart`
- `packages/flutter_d3_shape_port/test/order/*_test.dart`
- `packages/flutter_d3_shape_port/test/port/reference_test.dart`
- `packages/flutter_d3_shape_port/test/port/faster_forms_test.dart`
- `packages/flutter_d3_shape_port/test/port/ui_path_context_test.dart`
- `packages/flutter_d3_shape_port/test/upstream_test.dart`
- `packages/flutter_d3_port/test/port/d3/index_test.dart`
