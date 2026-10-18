// Ported from Chart.js v4.5.1 src/types/layout.d.ts (MIT, Chart.js Contributors).

/// The declarations of `src/types/layout.d.ts` as Dart interfaces
/// (Chart.js ADR 0003, porting-flow.md 2.4).
///
/// Each interface gets its members when a ported caller needs them. A
/// TypeScript property becomes an abstract getter, and a setter is added when
/// a ported caller assigns through the type. `number` is `double`.
///
/// `Scale` extends `LayoutItem` (index.d.ts:1273). `helpers.dataset.ts:4`
/// reads the edges of a scale through it.
///
/// The union `LayoutPosition` (layout.d.ts:3) waits for its first ported
/// caller (`core.layouts`).
library;

/// layout.d.ts:5 `LayoutItem`.
abstract interface class LayoutItem {
  /// layout.d.ts:29 `left: number`.
  double get left;

  /// layout.d.ts:33 `top: number`.
  double get top;

  /// layout.d.ts:37 `right: number`.
  double get right;

  /// layout.d.ts:41 `bottom: number`.
  double get bottom;
}
