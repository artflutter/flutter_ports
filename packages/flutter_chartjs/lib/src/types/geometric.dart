// Ported from Chart.js v4.5.1 src/types/geometric.d.ts (MIT, Chart.js Contributors).

/// The declarations of `src/types/geometric.d.ts` as Dart interfaces
/// (ADR "Type-only dependencies", porting-flow.md 2.4).
///
/// Each interface gets its members when a ported caller needs them. A
/// TypeScript property becomes an abstract getter, and a setter is added when
/// a ported caller assigns through the type. `number` is `double`.
///
/// The type aliases `CornerRadius` (geometric.d.ts:29) and `Padding` (:39) are
/// unions, which Dart cannot declare. They come with their first ported
/// caller (`helpers.options` or `element.bar`), which decides their Dart form.
library;

/// geometric.d.ts:1 `ChartArea`.
abstract interface class ChartArea {}

/// geometric.d.ts:10 `Point`.
abstract interface class Point {
  /// geometric.d.ts:11 `x: number | null`.
  double? get x;

  /// geometric.d.ts:12 `y: number | null`.
  double? get y;
}

/// geometric.d.ts:15 `TRBL`.
abstract interface class TRBL {}

/// geometric.d.ts:22 `TRBLCorners`.
abstract interface class TRBLCorners {}

/// geometric.d.ts:31 `RoundedRect`.
abstract interface class RoundedRect {}

/// geometric.d.ts:41 `SplinePoint`.
abstract interface class SplinePoint {}
