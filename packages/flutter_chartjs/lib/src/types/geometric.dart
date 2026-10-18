// Ported from Chart.js v4.5.1 src/types/geometric.d.ts (MIT, Chart.js Contributors).

/// The declarations of `src/types/geometric.d.ts` as Dart interfaces
/// (Chart.js ADR 0003, porting-flow.md 2.4).
///
/// Each interface gets its members when a ported caller needs them. A
/// TypeScript property becomes an abstract getter, and a setter is added when
/// a ported caller assigns through the type. `number` is `double`.
///
/// TypeScript types match by structure, Dart types by name. Thus two
/// interfaces here implement others where a ported caller passes one type
/// for the other: [ChartArea] is a [TRBL] and [SplinePoint] is a [Point].
///
/// ## The unions
///
/// The type aliases `CornerRadius` (geometric.d.ts:29) and `Padding` (:39)
/// are unions, which Dart cannot declare. Their members and the inline
/// unions of `helpers.options.ts` are option values: `number | TRBL | Point`
/// of `toTRBL` (helpers.options.ts:75), `number | TRBLCorners` of
/// `toTRBLCorners` (:86), `number | TRBL` of `toPadding` (:98) and
/// `number | Record<string, number>` of `_readValueToProps` (:51).
///
/// The Dart form of each of these unions is `Object?`, as for every option
/// value (Chart.js ADR 0006). The value is one of these:
/// - a `num`, also an `int` from `jsonDecode`;
/// - a `Map<String, Object?>`: a JS plain object, or an option resolver;
/// - an empty value: Dart `null` (JS `null`) or the `undefined` sentinel of
///   `lib/src/js/js_undefined.dart`.
///
/// Upstream reads the object members by key (`value[prop]`,
/// helpers.options.ts:57-58), and `isObject` is true only for a Map in the
/// port. Thus a Dart object that implements [TRBL], [TRBLCorners] or [Point]
/// is not an accepted input. The results are typed: `toTRBL` returns a
/// [TRBL], `toTRBLCorners` a [TRBLCorners] and `toPadding` a [ChartArea].
/// The concrete classes of these results are private to
/// `helpers.options.dart`. The object of `toTRBL` also implements
/// [ChartArea], and its `width` and `height` are `late` fields. Thus
/// `toPadding` assigns them as upstream does (helpers.options.ts:99-102).
/// `CornerRadius` and `Padding` get no typedef until a ported signature names
/// them (`RoundedRect.radius` in phase 3, the option types after 0.1.0).
///
/// ## Empty values
///
/// Outside option scopes, Dart `null` stands for one JS value (Chart.js ADR
/// 0006, "Values outside scopes"), and the `///` line of each nullable member
/// names it. In [Point], `null` is JS `null`. In [SplinePoint], `skip` is
/// `null` for JS `undefined`.
///
/// The optional numeric members of [SplinePoint] (`cp1x`, `cp1y`, `cp2x` and
/// `cp2y`) are not nullable. `double.nan` stands for JS `undefined` (row
/// `adapt-spline-control-point-nan` of `doc/differences.md`). Thus the port
/// stores them without a box. `ToNumber` of `undefined` is NaN, and both
/// values are falsy. Only `=== undefined`, `in`, `Object.keys`, `typeof` and
/// `JSON.stringify` tell them apart, and no upstream `src` file applies these
/// to a control point.
library;

/// geometric.d.ts:1 `ChartArea`.
///
/// It implements [TRBL] because ported code uses a chart area as a `TRBL`:
/// `_isPointInArea` (helpers.canvas.ts:319) takes the area of
/// `capBezierPoints` (helpers.curve.ts:163), and `getDatasetArea` returns
/// it (helpers.dataset.ts:17). TypeScript accepts both by structure.
abstract interface class ChartArea implements TRBL {
  /// geometric.d.ts:6 `width: number`.
  double get width;

  /// geometric.d.ts:7 `height: number`.
  double get height;
}

/// geometric.d.ts:10 `Point`.
abstract interface class Point {
  /// geometric.d.ts:11 `x: number | null`. Dart `null` is JS `null`, which
  /// `ToNumber` makes 0 (`distanceBetweenPoints`, helpers.math.ts:144).
  /// Ported code writes this `ToNumber` as `x ?? 0`, not `jsToNumber(x)`
  /// (Chart.js ADR 0010).
  ///
  /// JS `undefined` is not a value of the type. A caller that copies an
  /// `undefined` into a point passes `double.nan`, its `ToNumber` value. An
  /// example is `{x: p1.cp2x}` at helpers.interpolation.ts:33, when the
  /// control point is not set.
  double? get x;

  /// geometric.d.ts:12 `y: number | null`. Dart `null` is JS `null`, as for
  /// [x], and a copied `undefined` is `double.nan`.
  double? get y;
}

/// geometric.d.ts:15 `TRBL`.
abstract interface class TRBL {
  /// geometric.d.ts:16 `top: number`.
  double get top;

  /// geometric.d.ts:17 `right: number`.
  double get right;

  /// geometric.d.ts:18 `bottom: number`.
  double get bottom;

  /// geometric.d.ts:19 `left: number`.
  double get left;
}

/// geometric.d.ts:22 `TRBLCorners`.
abstract interface class TRBLCorners {
  /// geometric.d.ts:23 `topLeft: number`.
  double get topLeft;

  /// geometric.d.ts:24 `topRight: number`.
  double get topRight;

  /// geometric.d.ts:25 `bottomLeft: number`.
  double get bottomLeft;

  /// geometric.d.ts:26 `bottomRight: number`.
  double get bottomRight;
}

/// geometric.d.ts:31 `RoundedRect`.
abstract interface class RoundedRect {}

/// geometric.d.ts:41 `SplinePoint`.
///
/// It implements [Point] because ported code passes a spline point where a
/// `Point` goes: `distanceBetweenPoints` (helpers.curve.ts:29),
/// `_isPointInArea` (:163) and `_pointInLine` (helpers.interpolation.ts:35).
/// TypeScript accepts it by structure.
abstract interface class SplinePoint implements Point {
  /// geometric.d.ts:42 `x: number`.
  @override
  double get x;

  /// geometric.d.ts:43 `y: number`.
  @override
  double get y;

  /// geometric.d.ts:44 `skip?: boolean`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0006). JS `null` never reaches it.
  bool? get skip;

  /// geometric.d.ts:48 `cp1x?: number`. `helpers.curve.ts` assigns it.
  /// `double.nan` stands for JS `undefined`, the value before the first
  /// assignment. JS `null` never reaches it.
  // DIVERGES(chartjs): adapt-spline-control-point-nan, NaN is undefined.
  abstract double cp1x;

  /// geometric.d.ts:49 `cp1y?: number`. `helpers.curve.ts` assigns it.
  /// `double.nan` stands for JS `undefined`, the value before the first
  /// assignment. JS `null` never reaches it.
  // DIVERGES(chartjs): adapt-spline-control-point-nan, NaN is undefined.
  abstract double cp1y;

  /// geometric.d.ts:50 `cp2x?: number`. `helpers.curve.ts` assigns it.
  /// `double.nan` stands for JS `undefined`, the value before the first
  /// assignment. JS `null` never reaches it.
  // DIVERGES(chartjs): adapt-spline-control-point-nan, NaN is undefined.
  abstract double cp2x;

  /// geometric.d.ts:51 `cp2y?: number`. `helpers.curve.ts` assigns it.
  /// `double.nan` stands for JS `undefined`, the value before the first
  /// assignment. JS `null` never reaches it.
  // DIVERGES(chartjs): adapt-spline-control-point-nan, NaN is undefined.
  abstract double cp2y;
}
