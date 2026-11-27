# D3 ADR 0023: Native forms of d3-chord

- Status: accepted (2026-11-27): its code and the tests of section Tests pass.
- Date: 2026-11-27
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [D3 ADR 0014](0014-path-native-forms.md), [D3 ADR 0015](0015-shape-native-forms.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

`d3-chord` 3.0.1 computes circular relationship and directed network-flow chord layouts from an
*n*×*n* flow matrix (`chord`, `chordDirected`, `chordTranspose`) and generates quadratic-Bézier
ribbon paths (`ribbon`, `ribbonArrow`) using `d3-path` (`CanvasPath`).

Upstream JavaScript relies on untyped plain objects (`{index, startAngle, endAngle, value}` and
`{source, target}`), an array with an attached expando property (`chords.groups = groups`),
dual-purpose getter/setter functions that switch on `arguments.length` and `typeof _ === "function"`,
JS `this`-binding and variadic `arguments` forwarding (`apply(this, arguments)`), and sparse arrays
filtered via `Object.values(chords)`.

Following [D3 ADR 0007](0007-native-dart-forms.md) (zero JS runtime),
[D3 ADR 0008](0008-module-packages.md) (one package per D3 module),
[D3 ADR 0009](0009-native-spec-harness.md) (native `package:test` specs and Node.js reference
tests), [D3 ADR 0014](0014-path-native-forms.md) (`CanvasPath` and `UiPathContext`), and
[D3 ADR 0015](0015-shape-native-forms.md) (typed path generators), `d3-chord` 3.0.1 is ported as its
own package `flutter_d3_chord_port` depending only on `flutter_d3_path_port: ^0.1.2`, with
**zero `dynamic`, zero `Object?` escape hatches where generics apply, and zero JS runtime**.

## Decision

1. **Pure Dart core (`d3_chord.dart`) + direct Flutter `Canvas` layer (`flutter_d3_chord_port.dart`).**
   `package:flutter_d3_chord_port/d3_chord.dart` imports only
   `package:flutter_d3_path_port/d3_path.dart` (zero Flutter imports) and exports every pure file in
   `lib/src/` without `show`/`hide` combinators (ADR 0011) so it compiles for the Dart VM, AOT,
   dart2js, and dart2wasm without the Flutter engine.
   Internal helper files (`array.dart`, `constant.dart`, `math.dart`) use `chord*`-prefixed public
   names (`chordArraySlice`, `chordConstant`, `chordEpsilon`, `chordPi`, `chordHalfPi`, `chordTau`)
   so the `flutter_d3_port` bundle re-exports all D3 modules without symbol collisions.
   `package:flutter_d3_chord_port/flutter_d3_chord_port.dart` exports `d3_chord.dart` plus
   `lib/src/ui/chord_ui.dart` with direct Flutter `dart:ui.Path` helpers (`RibbonUiPath.toUiPath`,
   `RibbonUiPath.drawToUiPath`) backed by `UiPathContext` from `flutter_d3_path_port`.

2. **Typed immutable chord value classes and `Chords` collection (`lib/src/chord.dart`).**
   - `final class const ChordSubgroup` with typed fields `final int index`,
     `final double startAngle`, `final double endAngle`, and `final double value`.
   - `final class const Chord` with typed fields `final ChordSubgroup source` and
     `final ChordSubgroup target`.
   - `final class const ChordGroup` with typed fields `final int index`,
     `final double startAngle`, `final double endAngle`, and `final double value`.
   - `final class Chords extends ListBase<Chord>` carrying `final List<ChordGroup> groups`, so
     `chords` is a full `List<Chord>` with typed `.groups` matching upstream `chords.groups` without
     expando properties.
   - `typedef ChordComparator = num Function(double a, double b);` matches `d3.ascending`,
     `d3.descending`, and subtraction comparators `(a, b) => b - a`.

3. **Typed callable chord layout (`ChordLayout`, `chord`, `chordDirected`, `chordTranspose`).**
   - `final class ChordLayout` exposes typed properties:
     - `double get padAngle` / `set padAngle(double value)` (clamped with `max(0, value)`,
       defaulting to `0`).
     - `ChordComparator? sortGroups` (default `null`).
     - `ChordComparator? sortSubgroups` (default `null`).
     - `ChordComparator? sortChords` (default `null`; returns the exact comparator supplied).
     - `Chords call(List<List<num>> matrix)` computing the undirected, directed, or transposed
       layout.
   - Factories `chord(...)`, `chordDirected(...)`, and `chordTranspose(...)` construct a
     `ChordLayout` and accept optional named configuration parameters (`padAngle`, `sortGroups`,
     `sortSubgroups`, `sortChords`), supporting both constructor arguments and Dart cascades.
   - Group, subgroup, and chord sorting preserves JavaScript ES2019 stable sort semantics by
     tie-breaking equal comparator results on original index.

4. **Typed generic ribbon generator (`RibbonGenerator<T, S>`, `ribbon`, `ribbonArrow`, `ribbonBy`,
   `ribbonArrowBy`).**
   - Typed accessor signatures with zero `dynamic` and zero `Object?` casts:
     - `typedef RibbonEndpointAccessor<T, S> = S Function(T d);`
     - `typedef RibbonSubgroupNumberAccessor<S> = double Function(S subgroup);`
     - `typedef RibbonNumberAccessor<T> = double Function(T d);`
   - `final class RibbonGenerator<T, S>` exposes typed getter/setter properties (`source`, `target`,
     `radius`, `sourceRadius`, `targetRadius`, `startAngle`, `endAngle`, `padAngle`, `headRadius`,
     `context`) plus typed `*Const(double value)` setters (`radiusConst`, `sourceRadiusConst`,
     `targetRadiusConst`, `startAngleConst`, `endAngleConst`, `padAngleConst`, `headRadiusConst`)
     that store unboxed constant values to eliminate indirect closure calls in hot loops while
     keeping the getters callable.
   - `String? call(T d)` renders into `context` and returns `null` when `context != null`, or
     allocates a fresh full-precision `Path()` (matching upstream `d3-path` `path()`), draws into
     it, and returns `buffer.toString()` (or `null` if empty).
   - `void draw(T d, CanvasPath context)` emits ribbon path commands directly into [context] (such as
     a reusable `UiPathContext`) with zero intermediate SVG string allocation and without mutating
     `this.context`.
   - Default factories `ribbon(...)` and `ribbonArrow(...)` return
     `RibbonGenerator<Chord, ChordSubgroup>` pre-wired to `Chord.source`, `Chord.target`,
     `ChordSubgroup.startAngle`, and `ChordSubgroup.endAngle` (with `headRadius` defaulting to
     `10.0` for `ribbonArrow` and `null` for `ribbon`), plus optional named constant parameters.
   - Generic factories `ribbonBy<T, S>(...)` and `ribbonArrowBy<T, S>(...)` accept explicit typed
     accessors (or `*Const` values) for arbitrary custom datum types `T` and subgroup types `S`
     without runtime casts.

5. **Direct Flutter `Canvas` rendering (`lib/src/ui/chord_ui.dart`).**
   `extension RibbonUiPath<T, S> on RibbonGenerator<T, S>` provides:
   - `ui.Path toUiPath(T d, [UiPathContext? target])` — draws [d] directly into `target` (or a new
     `UiPathContext`) via `draw(d, ctx)` and returns `ctx.path` with zero SVG string formatting.
   - `void drawToUiPath(T d, UiPathContext target)` — appends [d] directly into a reusable
     `UiPathContext` without allocating a new `ui.Path`.

6. **Hot-path optimizations (row `adapt-chord-fast-forms`).**
   - Unboxed `Float64List` matrix flattening and group sums + reusable `Int32List` group/subgroup
     index buffers and inline stable insertion sort for small `n` in `ChordLayout.call`, replacing
     `Array.from`, `range(...).filter(...)`, and sparse `Object.values(chords)`.
   - Unboxed constant-accessor fast paths in `RibbonGenerator`, single-computation start-point
     coordinates `(sx0, sy0)` reused across `moveTo` and the closing `quadraticCurveTo`, and
     zero-allocation direct `draw(d, CanvasPath)` emission into `UiPathContext`.

## Rejected

- Representing `ChordSubgroup`, `Chord`, or `ChordGroup` as `Map<String, dynamic>` or untyped JS
  records: loses static type safety, forces dynamic lookups, and allocates hash maps per subgroup.
- Returning `List<Chord>` with an `Expando<List<ChordGroup>>` for `.groups`: slow hash lookups and
  unergonomic compared to `Chords extends ListBase<Chord>` with a `final List<ChordGroup> groups`
  field.
- Using `Object?` accessors with `as` casts or `typeof` union checks in `RibbonGenerator`: prevents
  compile-time type checking on custom datum/subgroup types and introduces runtime type checks on
  every ribbon.

## Consequences

- Upstream `ribbon-test.js` tests that pass untyped JS object literals (`{radius: 42}`,
  `{source: {name: "foo"}}`) or test dual-function/number overload coercion are expressed natively
  through typed `ribbon()`, `ribbonBy<T, S>()`, and `*Const` setters, with JS-only untyped cases
  documented under `adapt-chord-typed-api` in `packages/flutter_d3_chord_port/doc/differences.md`.
- Flutter apps render interactive undirected and directed chord diagrams directly onto `Canvas`
  using `ChordLayout`, `RibbonGenerator.draw` / `toUiPath`, `UiPathContext`, and
  `flutter_d3_shape_port`'s `Arc`.
- All pure tests run with zero `dart:io` imports on VM (including `--experimental-faster-testing`),
  Chrome JS, and Chrome Wasm.

## Tests

- `packages/flutter_d3_chord_port/test/chord_test.dart` (2 upstream cases)
- `packages/flutter_d3_chord_port/test/ribbon_test.dart` (6 upstream cases)
- `packages/flutter_d3_chord_port/test/port/chord_unit_test.dart` (directed, transpose, sorting, edge cases, `ribbonArrow`, `ribbonBy`, `padAngle`, `sourceRadius`/`targetRadius`)
- `packages/flutter_d3_chord_port/test/port/reference_test.dart` (Node.js v3.0.1 reference parity)
- `packages/flutter_d3_chord_port/test/port/faster_forms_test.dart` (baseline vs optimized twin tests)
- `packages/flutter_d3_chord_port/test/port/ui_path_context_test.dart` (direct Flutter `UiPathContext` rendering tests)
- `packages/flutter_d3_chord_port/test/upstream_test.dart` (upstream pin & `.gitmodules` tests)
- `packages/flutter_d3_port/test/port/d3/index_test.dart` (bundle re-export test)
