# D3 ADR 0014: Native forms of d3-path and CanvasPath

- Status: accepted (2026-11-26): its code and the tests of section Tests pass.
- Date: 2026-11-26
- Supersedes: [D3 ADR 0005](0005-path-context.md), whole
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

[D3 ADR 0005](0005-path-context.md) (proposed) designed `CanvasPath` and `UiPathContext` for a
single monolithic `flutter_d3_port` package using the JS runtime (`Object? ccw` with `jsTruthy`,
`jsNumberToString` from D3 ADR 0003). Following [D3 ADR 0007](0007-native-dart-forms.md) (no JS
runtime), [D3 ADR 0008](0008-module-packages.md) (one package per D3 module), and
[D3 ADR 0010](0010-native-values-and-factories.md) (native typed parameters), `d3-path` 3.1.0 is
ported as its own package `flutter_d3_path_port`.

Upstream `d3-shape` and `d3-chord` already depend on `d3-path`. Placing both the pure `CanvasPath`
interface and the Flutter `UiPathContext` builder in `flutter_d3_path_port` gives every downstream
D3 generator both SVG string serialization (`Path`) and zero-copy native `dart:ui.Path` drawing
(`UiPathContext`) with no extra package and no JS runtime.

## Decision

1. **Pure `CanvasPath` interface in `lib/src/canvas_path.dart`.** Declares the eight Canvas 2D path
   methods that D3 uses (`moveTo`, `closePath`, `lineTo`, `quadraticCurveTo`, `bezierCurveTo`,
   `arcTo`, `arc`, `rect`) with typed `double` coordinates and a typed optional boolean
   `[bool ccw = false]` on `arc` (matching the positional Canvas 2D / D3 call shape without
   `jsTruthy`). `Path` implements `CanvasPath`.
2. **Typed `Path` and `pathRound` arguments.** `Path([int? digits])` takes an optional integer
   digit count (`null` means full precision, `digits > 15` means full precision, `digits < 0`
   throws `RangeError` with message `'invalid digits: $digits'`). `pathRound([int digits = 3])`
   takes a non-nullable `int` defaulting to `3`. Negative radii in `arc` and `arcTo` throw
   `RangeError` with message `'negative radius: $r'`.
3. **JS-exact SVG number texts with no JS runtime.** `Path` formats whole numbers without `.0`,
   formats `-0.0` as `'0'`, and rounds negative halves toward `+∞` in `pathRound` (matching JS
   `Math.round(x * k) / k`) directly in native Dart.
4. **Native `dart:ui.Path` builder (`UiPathContext`) in `lib/src/ui/ui_path_context.dart`.**
   Exported by `package:flutter_d3_path_port/flutter_d3_path_port.dart` (while
   `package:flutter_d3_path_port/d3_path.dart` remains pure Dart with zero Flutter imports).
   `UiPathContext` implements `CanvasPath`, writes directly into a `dart:ui.Path` with full Canvas
   2D path rules (empty-path implicit `moveTo`, `arc` connecting line and full-circle split,
   `arcTo` tangent arc, non-finite argument no-op, negative radius `RangeError`), and avoids any
   SVG string formatting or parsing at draw time.
5. **Public exports under ADR 0011.** `lib/d3_path.dart` exports every pure file in `lib/src/`
   without `show`/`hide` combinators (`canvas_path.dart`, `index.dart`, `path.dart`,
   `upstream.dart`). `lib/flutter_d3_path_port.dart` exports `d3_path.dart` and
   `lib/src/ui/ui_path_context.dart`. `flutter_d3_port` re-exports both.

## Rejected

- Keeping `Object? ccw` + `jsTruthy` from D3 ADR 0005: reintroduces JS coercion into a typed Dart
  API, violating D3 ADR 0007 and D3 ADR 0010.
- Deferring `UiPathContext` to Phase 4 inside `flutter_d3_port`: prevents standalone users of
  `flutter_d3_path_port` (and downstream `flutter_d3_shape_port`) from drawing directly to
  `dart:ui.Path` without pulling the full bundle.
- Drawing on Flutter by parsing the SVG string produced by `Path`: allocates and parses strings on
  every frame instead of writing geometry directly to `dart:ui.Path`.

## Consequences

- Spec cases testing JS truthy/falsy coercions on `ccw` and `pathRound(null)` (`+null === 0`) skip
  as `diverges: adapt-path-typed-args`.
- Downstream ports (`d3-shape`, `d3-chord`, `d3-geo`, `d3-delaunay`) can target `CanvasPath` and
  work with both `Path` (SVG string) and `UiPathContext` (`dart:ui.Path`).

## Tests

- `packages/flutter_d3_path_port/test/path_test.dart`
- `packages/flutter_d3_path_port/test/pathRound_test.dart`
- `packages/flutter_d3_path_port/test/upstream_test.dart`
- `packages/flutter_d3_path_port/test/port/reference_test.dart`
- `packages/flutter_d3_path_port/test/port/faster_forms_test.dart`
- `packages/flutter_d3_path_port/test/port/ui_path_context_test.dart`
- `packages/flutter_d3_port/test/port/d3/index_test.dart`
