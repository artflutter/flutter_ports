// Ported from Chart.js v4.6.1 src/types/layout.d.ts (MIT, Chart.js Contributors).

/// The declarations of `src/types/layout.d.ts` as Dart interfaces
/// (Chart.js ADR 0003, porting-flow.md 2.4).
///
/// Each interface gets its members when a ported caller needs them. A
/// TypeScript property becomes an abstract getter, and a setter is added when
/// a ported caller assigns through the type. `number` is `double`.
///
/// `Scale` extends `LayoutItem` (index.d.ts:1303). `helpers.dataset.ts:4`
/// reads the edges of a scale through it. `core.layouts.js` reads and writes
/// the members of a box through it.
///
/// ## The union `LayoutPosition`
///
/// `LayoutPosition` (layout.d.ts:3) is the union `'left' | 'top' | 'right' |
/// 'bottom' | 'center' | 'chartArea' | {[scaleId: string]: number}`. Its Dart
/// form is the interface [LayoutPosition] (row `adapt-chart-position-enum`):
/// the enum [ChartPosition] for the names, and the class
/// [ScaleValuePosition] for the object form. `core.layouts` tests the object
/// form with `isObject` (core.layouts.js:121): a [ScaleValuePosition]. It
/// compares a position with `===` (core.layouts.js:11, :15, :52): the enum
/// value. [LayoutItem.position] holds the raw option value.
///
/// ## The optional members
///
/// `beforeLayout?()` (layout.d.ts:46) and `getPadding?()` (layout.d.ts:54)
/// are optional in TypeScript. Dart has no optional member. Thus each is the
/// member of a port-only interface: [LayoutItemBeforeLayout] and
/// [LayoutItemPadding]. `core.layouts.js:132` and `:360` test for the method.
/// The port tests the box against the interface. This is the form of
/// `VisualElementRange` (Chart.js ADR 0020, section 9).
///
/// `core.controller.js:630` also tests a box for a `configure` method, which
/// layout.d.ts does not declare. The port-only interface
/// [LayoutItemConfigure] has the same form.
library;

import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:meta/meta.dart' show immutable;

/// layout.d.ts:3 `LayoutPosition`: the position of a box in the layout of a
/// chart, the `position` option of the legend, the title, the subtitle and
/// a scale (row `adapt-chart-position-enum`).
///
/// [ChartPosition] gives the names of the union, and [ScaleValuePosition]
/// its object form. A box of a plugin takes a [ChartPosition].
abstract interface class LayoutPosition {}

/// The names of layout.d.ts:3 `LayoutPosition`: the side of a box, or the
/// center of the chart area for an axis, or the chart area for a legend.
///
/// The layout closes the set: `core.layouts` places a box by its side, and
/// the other positions are its dynamic boxes. The name of each value is
/// the keyword of Chart.js.
// DIVERGES(chartjs): adapt-chart-position-enum, an enum of the positions.
enum ChartPosition implements LayoutPosition {
  /// `'top'`: above the chart area.
  top,

  /// `'left'`: to the left of the chart area.
  left,

  /// `'bottom'`: below the chart area.
  bottom,

  /// `'right'`: to the right of the chart area.
  right,

  /// `'center'`: an axis through the center of the chart area.
  center,

  /// `'chartArea'`: a box inside the chart area, for example a legend.
  chartArea;

  /// The value of [value], a `position` option, or Dart `null` for a value
  /// that is not a [ChartPosition]. A keyword of Chart.js is not a value: a
  /// debug build stops on it.
  static ChartPosition? of(Object? value) {
    assert(
      value is! String,
      'A position takes a ChartPosition, not the name "$value".',
    );
    return value is ChartPosition ? value : null;
  }
}

/// The object form `{[scaleId]: value}` of layout.d.ts:3 `LayoutPosition`:
/// an axis at the [value] of the scale [scaleId], for example the y axis at
/// the value 0 of the scale `x` (`{x: 0}`).
// DIVERGES(chartjs): adapt-chart-position-enum, a class of the object form.
@immutable
final class ScaleValuePosition implements LayoutPosition {
  /// The position at [value] of the scale [scaleId].
  const ScaleValuePosition(this.scaleId, this.value);

  /// The id of the scale that gives the place, the key of the object form.
  final String scaleId;

  /// The value on the scale [scaleId]: a number, or a value that the scale
  /// parses, for example a label of a category scale.
  final Object? value;

  @override
  bool operator ==(Object other) =>
      other is ScaleValuePosition &&
      other.scaleId == scaleId &&
      other.value == value;

  @override
  int get hashCode => Object.hash(scaleId, value);

  @override
  String toString() => 'ScaleValuePosition($scaleId, $value)';
}

/// layout.d.ts:5 `LayoutItem`.
///
/// `core.layouts.js` also reads three members that layout.d.ts does not
/// declare: [options], [axis] and [layers].
abstract interface class LayoutItem {
  /// layout.d.ts:9 `position: LayoutPosition`: a `String` or a
  /// `Map<String, Object?>` (see the library documentation).
  ///
  /// `layouts.configure` writes the `position` option (core.layouts.js:333).
  /// `layouts.addBox` writes `'top'` for a falsy value
  /// (core.layouts.js:298). Dart `null` stands for JS `null`. The
  /// `undefined` sentinel stands for JS `undefined`, the start value of the
  /// legend and the title (plugin.legend.js:77, plugin.title.js:24).
  abstract Object? position;

  /// layout.d.ts:13 `weight: number`, the order of the boxes on one side.
  ///
  /// `layouts.configure` writes the `weight` option as it is
  /// (core.layouts.js:334). Thus the Dart type is `Object?`, as for every
  /// option value (Chart.js ADR 0043): a number, or another value of the
  /// option. Dart `null` stands for JS `null`. The `undefined` sentinel
  /// stands for JS `undefined`. `sortByWeight` compares two values with
  /// `===` (core.layouts.js:18-26): `undefined === undefined` is true, and
  /// `null === 0` is false. A `double` cannot keep these two results.
  /// `layouts.addBox` writes 0 for a falsy value (core.layouts.js:299).
  abstract Object? weight;

  /// layout.d.ts:17 `fullSize: boolean`.
  ///
  /// `layouts.configure` writes the truthiness of the `fullSize` option
  /// (core.layouts.js:332, the difference `adapt-layout-configure-types`).
  /// The readers test only the truthiness (core.layouts.js:75, :87, :201,
  /// :232, :246).
  abstract bool fullSize;

  /// layout.d.ts:21 `width: number`. `setBoxDims` and the boxes of the
  /// position `'chartArea'` write it (core.layouts.js:214, :451).
  abstract double width;

  /// layout.d.ts:25 `height: number`. `setBoxDims` and the boxes of the
  /// position `'chartArea'` write it (core.layouts.js:215, :451).
  abstract double height;

  /// layout.d.ts:29 `left: number`. `setBoxDims` writes it
  /// (core.layouts.js:211).
  abstract double left;

  /// layout.d.ts:33 `top: number`. `setBoxDims` writes it
  /// (core.layouts.js:210).
  abstract double top;

  /// layout.d.ts:37 `right: number`. `setBoxDims` writes it
  /// (core.layouts.js:212).
  abstract double right;

  /// layout.d.ts:41 `bottom: number`. `setBoxDims` writes it
  /// (core.layouts.js:213).
  abstract double bottom;

  /// layout.d.ts:50 `draw(chartArea: ChartArea): void`. The default layer of
  /// `layouts.addBox` calls it (core.layouts.js:305).
  void draw(ChartArea chartArea);

  /// layout.d.ts:58 `isHorizontal(): boolean`.
  bool isHorizontal();

  /// layout.d.ts:64 `update(width, height, margins?): void`.
  ///
  /// layout.d.ts types [margins] as a `ChartArea`. The objects that
  /// `core.layouts.js` passes have only the four edges (core.layouts.js:167,
  /// :452). Thus the Dart type is [TRBL]. Dart `null` stands for an absent
  /// argument, JS `undefined`.
  void update(double width, double height, [TRBL? margins]);

  /// core.layouts.js:34 and :393 `box.options`, the options of the box.
  /// layout.d.ts does not declare it.
  ///
  /// `wrapBoxes` reads its `stack` and `stackWeight` (core.layouts.js:34). A
  /// destructuring of JS `undefined` throws a `TypeError`. Dart `null` stands
  /// for JS `undefined`, and `jsGet` throws the `TypeError`. The options
  /// are a view of the resolver or a typed object (Chart.js ADR 0054 §5).
  Object? get options;

  /// core.layouts.js:15 `box.axis`, the axis of a scale. layout.d.ts does not
  /// declare it. Dart `null` stands for JS `undefined`, for example the axis
  /// of a legend. `filterDynamicPositionByAxis` compares it with `===`.
  /// The axis is a class (row `adapt-axis-objects`).
  ScaleAxis? get axis;

  /// core.layouts.js:301 `_layers`, the function that gives the drawing
  /// layers of the box. layout.d.ts does not declare it.
  /// `core.controller.js:633` calls it.
  ///
  /// A JavaScript method is a property with a function value. Thus the Dart
  /// member is a field of a function type. Dart `null` stands for JS
  /// `undefined`. `layouts.addBox` writes a function with one layer of
  /// [draw] when it is absent (core.layouts.js:301-308). A scale gives its
  /// own layers (core.scale.js:1639).
  abstract List<LayoutLayer> Function()? layers;
}

/// layout.d.ts:46 the optional member `beforeLayout?(): void` of
/// [LayoutItem]. A box class with a `beforeLayout` method implements it
/// (see the library documentation).
///
/// `core.layouts.js:360` tests `typeof box.beforeLayout === 'function'`. A
/// box without the interface gets no call, as upstream.
abstract interface class LayoutItemBeforeLayout implements LayoutItem {
  /// layout.d.ts:46 `beforeLayout()`.
  void beforeLayout();
}

/// core.controller.js:630 the method `configure()` of a box, which
/// layout.d.ts does not declare. A box class with a `configure` method
/// implements it (see the library documentation).
///
/// `_updateLayout` tests `box.configure` and calls it
/// (core.controller.js:630-632). A box without the interface gets no call,
/// as upstream. `Scale.configure` (core.scale.js:480) implements it.
abstract interface class LayoutItemConfigure implements LayoutItem {
  /// core.controller.js:631 `configure()`.
  void configure();
}

/// layout.d.ts:54 the optional member `getPadding?(): ChartArea` of
/// [LayoutItem]. A box class with a `getPadding` method implements it (see
/// the library documentation).
///
/// `core.layouts.js:132` tests `box.getPadding`. A box without the
/// interface adds no padding, as upstream. layout.d.ts types the result as a
/// `ChartArea`. `updateMaxPadding` reads only its four edges
/// (core.layouts.js:110-113), and `Scale.getPadding` returns only these
/// (core.scale.js:337-344). Thus the Dart type is [TRBL].
abstract interface class LayoutItemPadding implements LayoutItem {
  /// layout.d.ts:54 `getPadding()`.
  TRBL getPadding();
}

/// core.layouts.js:302-307 and core.scale.js:1647-1669 the layer object
/// `{z, draw}` of [LayoutItem.layers]. layout.d.ts does not declare it.
///
/// `core.controller.js` collects the layers of all boxes, sorts them by [z]
/// and [idx] (:526), and draws each layer (:719-729).
abstract interface class LayoutLayer {
  /// `z`: the drawing order. `core.controller.js:720` draws the layers with
  /// `z <= 0` before the datasets.
  double get z;

  /// `draw(chartArea)`: draws the layer. A layer function that takes no
  /// argument ignores [chartArea] (core.scale.js:1664).
  void draw(ChartArea chartArea);

  /// core.controller.js:637 `_idx`: the index of the layer in the layers of
  /// the chart. `_updateLayout` writes it, and the sort of
  /// core.controller.js:526 reads it. NaN stands for JS `undefined`, the
  /// value before the first write.
  abstract double idx;
}
