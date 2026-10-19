// Ported from Chart.js v4.5.1 src/types/index.d.ts (MIT, Chart.js Contributors).

/// The declarations of `src/types/index.d.ts` as Dart interfaces
/// (Chart.js ADR 0003, porting-flow.md 2.4).
///
/// Each interface gets its members when a ported caller needs them. A
/// TypeScript property becomes an abstract getter, and a setter is added when
/// a ported caller assigns through the type. `number` is `double`, also for
/// an index (Chart.js ADR 0010). An inline object type that ported code only
/// reads is a record.
///
/// `index.d.ts` also names classes of other modules: `Element`
/// (core.element.ts), `PointElement` (element.point.ts) and the fields of
/// `LineElement` (element.line.js). This library declares their interfaces,
/// so that the pure layers name them without an import of a concrete module.
/// A file that also needs the concrete class of the same name imports this
/// library with the prefix `types`.
///
/// Option objects (`options`, `getContext()`) are `Map<String, Object?>`:
/// Chart.js ADR 0006 makes a JS plain object a Map, and the option resolvers
/// of `helpers.config` take the place of the upstream `Proxy` objects.
///
/// Upstream `_`-prefixed members that other modules read drop the underscore
/// (Chart.js ADR 0012), and the `///` line keeps the upstream name. A type
/// library imports only other type libraries (Chart.js ADR 0003). Thus these
/// members carry no `@internal`. The concrete classes carry it.
///
/// Outside option scopes, Dart `null` stands for one JS value (Chart.js ADR
/// 0006, "Values outside scopes"). The `///` line of each nullable member
/// names that value, or says that the readers treat JS `null` and
/// `undefined` alike.
library;

// The canvas interface and the native event stand in for lib.dom.d.ts, which
// index.d.ts names without an import. Both are pure, port-only interface
// libraries (Chart.js ADR 0013, Chart.js ADR 0014).
import 'package:flutter_chartjs/src/canvas/canvas.dart'
    show CanvasRenderingContext2D, HTMLCanvasElement;
import 'package:flutter_chartjs/src/platform/native_event.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:flutter_chartjs/src/types/layout.dart';

export 'package:flutter_chartjs/src/types/geometric.dart'
    show ChartArea, Point, TRBL;
export 'package:flutter_chartjs/src/types/layout.dart' show LayoutItem;

/// index.d.ts:433 `ChartMetaClip`, the type of `ChartMeta._clip`.
///
/// The four edges are `Object?`. An edge is a `num` (also an `int` from
/// `jsonDecode`), a `bool`, Dart `null` for JS `null`, or the `undefined`
/// sentinel of `lib/src/js/js_undefined.dart`. `toClip`
/// (core.datasetController.js:38) copies the four keys of a clip object, and
/// a key that a partial object leaves out is `undefined`. `toClip` copies any
/// other user value too. `getDatasetClipArea` (helpers.dataset.ts:28-31)
/// subtracts an edge that is not a `bool` with `ToNumber`: `null` gives 0,
/// and `undefined` gives NaN. It adds such an edge as the JavaScript `+`
/// does: a `num`, `null` or `undefined` adds with `ToNumber`, and another
/// value gives `ToNumber` of the joined string.
abstract interface class ChartMetaClip {
  /// index.d.ts:434 `left: number | boolean`. See [ChartMetaClip].
  Object? get left;

  /// index.d.ts:435 `top: number | boolean`. See [ChartMetaClip].
  Object? get top;

  /// index.d.ts:436 `right: number | boolean`. See [ChartMetaClip].
  Object? get right;

  /// index.d.ts:437 `bottom: number | boolean`. See [ChartMetaClip].
  Object? get bottom;

  /// index.d.ts:438 `disabled: boolean`.
  bool get disabled;
}

/// index.d.ts:477 `ChartMeta`, with the members of `ChartMetaCommon`
/// (index.d.ts:441).
abstract interface class ChartMeta {
  /// index.d.ts:455 `dataset?: TDatasetElement`. Dart `null` stands for JS
  /// `null`, the start value (core.controller.js:838), and for `undefined`.
  /// The readers test only its truthiness (helpers.extras.ts:96).
  Element? get dataset;

  /// index.d.ts:465 `xScale?: Scale`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0006). JS `null` never reaches it.
  Scale? get xScale;

  /// index.d.ts:466 `yScale?: Scale`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0006). JS `null` never reaches it.
  Scale? get yScale;

  /// index.d.ts:468 `iScale?: Scale`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0006). JS `null` never reaches it.
  Scale? get iScale;

  /// index.d.ts:469 `vScale?: Scale`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0006). JS `null` never reaches it.
  Scale? get vScale;

  /// index.d.ts:471 `_sorted: boolean`.
  bool get sorted;

  /// index.d.ts:473 `_parsed: unknown[]`.
  ///
  /// Each entry is a parsed data object, which ported code reads by an axis
  /// key (helpers.extras.ts:103, :111). Chart.js ADR 0006 makes a JS plain
  /// object a Map.
  List<Map<String, Object?>> get parsed;

  /// index.d.ts:474 `_clip: ChartMetaClip`.
  ChartMetaClip get clip;

  /// helpers.extras.ts:145 `_scaleRanges`. `index.d.ts` does not declare
  /// it. `_scaleRangesChanged` reads it and assigns it (:153). Dart `null`
  /// stands for JS `undefined` (Chart.js ADR 0006). JS `null` never reaches
  /// it.
  abstract ScaleRanges? scaleRanges;
}

/// helpers.extras.ts:146 the type `{xmin, xmax, ymin, ymax}` of
/// `ChartMeta._scaleRanges`. `index.d.ts` does not declare it.
/// `_scaleRangesChanged` writes its fields with `Object.assign` (:161).
abstract interface class ScaleRanges {
  /// helpers.extras.ts:147 `xmin`.
  abstract double xmin;

  /// helpers.extras.ts:148 `xmax`.
  abstract double xmax;

  /// helpers.extras.ts:149 `ymin`.
  abstract double ymin;

  /// helpers.extras.ts:150 `ymax`.
  abstract double ymax;
}

/// index.d.ts:485 `ActiveDataPoint`.
abstract interface class ActiveDataPoint {
  /// index.d.ts:486 `datasetIndex: number`.
  double get datasetIndex;

  /// index.d.ts:487 `index: number`.
  double get index;
}

/// index.d.ts:494 `Chart`.
abstract interface class Chart {
  /// index.d.ts:499 `readonly platform: BasePlatform`.
  BasePlatform get platform;

  /// index.d.ts:501 `readonly canvas: HTMLCanvasElement`.
  ///
  /// Dart `null` stands for JS `null`: the constructor keeps the `null` of a
  /// failed `acquireContext` (core.controller.js:140), and `destroy()` sets
  /// it (core.controller.js:948). `platform.dom.js:104` tests it.
  HTMLCanvasElement? get canvas;

  /// index.d.ts:502 `readonly ctx: CanvasRenderingContext2D`.
  ///
  /// Dart `null` stands for JS `null`, as for [canvas]
  /// (core.controller.js:139, :949). The throttled event proxy tests it
  /// (`platform.dom.js:246`).
  CanvasRenderingContext2D? get ctx;

  /// core.controller.js:168 `$proxies`, the event proxies of
  /// `platform.dom.js` for each event type. `index.d.ts` does not declare
  /// it.
  ///
  /// The `$` prefix marks a property that Chart.js keeps on an object for
  /// another module. The Dart name says whose it is. Dart `null` stands for
  /// JS `undefined`: `platform.dom.js:335` assigns `{}` when it is absent.
  /// A value of the map is a proxy, or `null` for the `undefined` that
  /// `removeEventListener` assigns (`platform.dom.js:365`).
  abstract Map<String, Object?>? platformProxies;

  /// index.d.ts:504 `readonly width: number`. `retinaScale` assigns it
  /// through the `PrivateChart` type (helpers.dom.ts:218), so it has a
  /// setter.
  abstract double width;

  /// index.d.ts:505 `readonly height: number`. `retinaScale` assigns it
  /// through the `PrivateChart` type (helpers.dom.ts:217), so it has a
  /// setter.
  abstract double height;

  /// index.d.ts:508 `readonly currentDevicePixelRatio: number`.
  /// `_alignPixel` reads it (helpers.canvas.ts:126). `retinaScale` assigns
  /// it through the `PrivateChart` type (helpers.dom.ts:233), so it has a
  /// setter.
  abstract double currentDevicePixelRatio;

  /// index.d.ts:509 `readonly chartArea: ChartArea`.
  ChartArea get chartArea;

  /// index.d.ts:517 `options: ChartOptions<TType>`.
  Map<String, Object?> get options;

  /// index.d.ts:559 `getContext(): { chart: Chart, type: string }`.
  ///
  /// The context is the parent of `createContext` (helpers.options.ts:204),
  /// so it is an object, not a record. `core.controller` returns
  /// `createContext(null, {...})`, a `ContextObject` of `helpers.options`.
  Map<String, Object?> getContext();
}

/// index.d.ts:592 `DatasetController`.
abstract interface class DatasetController {
  /// core.datasetController.js:443 `_parsing`, the `parsing` option.
  /// `index.d.ts` does not declare it. `_parseObjectDataRadialScale`
  /// (helpers.config.ts:444) reads it as `this._parsing`. Its value is
  /// `false` or an object of the parsing keys (Chart.js ADR 0006).
  Object? get parsing;
}

/// index.d.ts:676 `Defaults`, the type of the `defaults` object of
/// `core.defaults.js`.
///
/// The `apply*Defaults` functions of `core.animations.defaults.js`,
/// `core.layouts.defaults.js` and `core.scale.defaults.js` take it. The option
/// members of `CoreChartOptions`, `ElementChartOptions` and
/// `PluginChartOptions` (index.d.ts:676) wait for their first ported caller.
/// The concrete class of `core.defaults.js` has the same name. Thus that file
/// imports this library with the prefix `types`.
abstract interface class Defaults {
  /// index.d.ts:684 `set(scope: string, values: AnyObject): AnyObject`.
  ///
  /// The overload `set(values)` (index.d.ts:683) has the same name. The
  /// concrete `Defaults` of `core.defaults.dart` takes both forms as
  /// `set(Object? scope, [Object? values = undefined])`.
  Map<String, Object?> set(String scope, Map<String, Object?> values);

  /// index.d.ts:687 `describe(scope: string, values: AnyObject): AnyObject`.
  ///
  /// The `Defaults` constructor also calls `describe(values)` with one
  /// argument (core.defaults.js:82). `describe` at core.defaults.js:102 takes
  /// a `{string|object}` scope and passes it to `set(root, scope, values)` at
  /// :27. index.d.ts declares only the two-argument form. The concrete
  /// `Defaults` of `core.defaults.dart` takes both forms as
  /// `describe(Object? scope, [Object? values = undefined])`.
  Map<String, Object?> describe(String scope, Map<String, Object?> values);

  /// index.d.ts:707 `route(scope, name, targetScope, targetName): void`.
  ///
  /// Routes the named defaults to fallback to another scope/name.
  void route(String scope, String name, String targetScope, String targetName);
}

/// index.d.ts:1164 `Tick`.
abstract interface class Tick {
  /// index.d.ts:1165 `value: number`.
  double get value;

  /// scale.logarithmic.js:55 `significand`. `index.d.ts` does not declare
  /// it. `core.ticks.js:75` reads it. Dart `null` stands for JS `undefined`
  /// (Chart.js ADR 0006): the ticks of other scales do not set it. JS `null`
  /// never reaches it.
  double? get significand;
}

/// index.d.ts:1273 `Scale`.
abstract interface class Scale implements Element, LayoutItem {
  /// index.d.ts:1277 `readonly chart: Chart`.
  Chart get chart;

  /// index.d.ts:1287 `axis: string`.
  String get axis;

  /// index.d.ts:1289 `min: number`.
  double get min;

  /// index.d.ts:1290 `max: number`.
  double get max;

  /// core.element.ts:14 `options: O`, through `Element<unknown, O>`
  /// (index.d.ts:1273).
  @override
  Map<String, Object?> get options;

  /// index.d.ts:1336 `getPixelForValue`.
  double getPixelForValue(double value, [double? index]);

  /// index.d.ts:1355 `parse`.
  Object? parse(Object? raw, [double? index]);

  /// index.d.ts:1356 `getUserBounds`.
  ({double min, double max, bool minDefined, bool maxDefined}) getUserBounds();
}

/// index.d.ts:1404 `RenderTextOpts`, the options of `renderText`
/// (helpers.canvas.ts:449).
///
/// Every member is optional. Dart `null` stands for an absent key, JS
/// `undefined`. The readers treat JS `null` alike: `renderText` tests the
/// members for truthiness, with `isNullOrUndef`, or with `>`, which makes
/// `null` and `undefined` both fail.
abstract interface class RenderTextOpts {
  /// index.d.ts:1409 `color?: Color`: a CSS color `String`, a
  /// `CanvasGradient` or a `CanvasPattern` (color.d.ts:1). An empty String
  /// is falsy, so `setRenderOpts` leaves the fill style unchanged.
  Object? get color;

  /// index.d.ts:1415 `decorationWidth?: number`. A falsy value gives 2.
  double? get decorationWidth;

  /// index.d.ts:1420 `maxWidth?: number`.
  double? get maxWidth;

  /// index.d.ts:1426 `rotation?: number`, in radians.
  double? get rotation;

  /// index.d.ts:1431 `strikethrough?: boolean`.
  bool? get strikethrough;

  /// index.d.ts:1437 `strokeColor?: Color`, as [color].
  Object? get strokeColor;

  /// index.d.ts:1443 `strokeWidth?: number`.
  double? get strokeWidth;

  /// index.d.ts:1449 `textAlign?: CanvasTextAlign`.
  String? get textAlign;

  /// index.d.ts:1455 `textBaseline?: CanvasTextBaseline`.
  String? get textBaseline;

  /// index.d.ts:1460 `translation?: [number, number]`. The tuple is a
  /// record.
  (double, double)? get translation;

  /// index.d.ts:1465 `underline?: boolean`.
  bool? get underline;

  /// index.d.ts:1470 `backdrop?: BackdropOptions`.
  BackdropOptions? get backdrop;
}

/// index.d.ts:1473 `BackdropOptions`, the label backdrop of
/// [RenderTextOpts.backdrop].
abstract interface class BackdropOptions {
  /// index.d.ts:1477 `left: number`.
  double get left;

  /// index.d.ts:1482 `top: number`.
  double get top;

  /// index.d.ts:1487 `width: number`.
  double get width;

  /// index.d.ts:1492 `height: number`.
  double get height;

  /// index.d.ts:1497 `color: Scriptable<Color, ScriptableScaleContext>`.
  /// `drawBackdrop` assigns it to `fillStyle` as it is
  /// (helpers.canvas.ts:441): the caller resolves a scriptable value first
  /// (`core.scale.js:1307`).
  Object? get color;
}

/// index.d.ts:1544 `ChartEvent`.
abstract interface class ChartEvent {
  /// index.d.ts:1545 `type`, one of the DOM event names.
  String get type;

  /// index.d.ts:1558 `native: Event | null`. The port-only [NativeEvent]
  /// stands for the DOM event (Chart.js ADR 0014). Dart `null` stands for
  /// JS `null`, for example the `native` of a synthetic event.
  NativeEvent? get native;

  /// index.d.ts:1559 `x: number | null`. `fromNativeEvent` gives JS `null`
  /// for an `undefined` position (`platform.dom.js:116`). Dart `null` stands
  /// for that `null`.
  double? get x;

  /// index.d.ts:1560 `y: number | null`, as [x].
  double? get y;

  /// `platform.dom.js:114` `chart`, the chart of the event.
  /// `index.d.ts` does not declare it. Dart `null` stands for JS
  /// `undefined`, an event that `fromNativeEvent` did not make.
  Chart? get chart;
}

/// index.d.ts:1782 `FontSpec`.
///
/// The members are nullable, unlike upstream. `toFontString` tests
/// `isNullOrUndef(font.size)` and `isNullOrUndef(font.family)`
/// (helpers.canvas.ts:26), and the font object of `toFont` can lack them
/// (helpers.options.ts:119, :131). Dart `null` stands for both empty JS
/// values, because the readers treat them alike.
abstract interface class FontSpec {
  /// index.d.ts:1787 `family: string`.
  String? get family;

  /// index.d.ts:1792 `size: number`.
  double? get size;

  /// index.d.ts:1797 `style`, a CSS `font-style` keyword.
  String? get style;

  /// index.d.ts:1801 `weight`: a CSS `font-weight` keyword `String`, a
  /// `num` or `null`.
  Object? get weight;

  /// index.d.ts:1806 `lineHeight: number | string`: a `num` or a `String`.
  ///
  /// `renderText` reads it as `Number(font.lineHeight)`
  /// (helpers.canvas.ts:487), so a String gives its `ToNumber`. The font
  /// object of `toFont` has a number in pixels (helpers.options.ts:132).
  Object? get lineHeight;
}

/// index.d.ts:1809 `CanvasFontSpec`.
///
/// `toFont` returns it (helpers.options.ts:115). Its `lineHeight` is a
/// number in pixels.
abstract interface class CanvasFontSpec implements FontSpec {
  /// index.d.ts:1810 `string: string`. Dart `null` is JS `null`:
  /// `toFontString` gives `null` when the size or the family is empty
  /// (helpers.canvas.ts:26).
  String? get string;
}

/// index.d.ts:1837 `Segment`.
abstract interface class Segment {
  /// index.d.ts:1838 `start: number`.
  double get start;

  /// index.d.ts:1839 `end: number`.
  double get end;

  /// index.d.ts:1840 `loop: boolean`.
  bool get loop;

  /// helpers.segment.js:8 `style?: any`. `index.d.ts` does not declare it.
  ///
  /// Dart `null` stands for JS `undefined` (Chart.js ADR 0006): the segments
  /// of `solidSegments` and of a line without segment styles have no style.
  /// JS `null` never reaches it. A style of `doSplitByStyles` is the
  /// `AnyObject` of `readStyle` (helpers.segment.js:337).
  Object? get style;
}

/// index.d.ts:1977 `LineElement`, with the fields of the class
/// (element.line.js:243) that `helpers.segment.js` reads.
abstract interface class LineElement implements Element {
  /// index.d.ts:1981 `points: Point[]`. The class keeps point elements
  /// (element.line.js:315), and `helpers.segment.js` reads their `skip` and
  /// `stop`.
  List<PointElement> get points;

  /// index.d.ts:1982 `readonly segments: Segment[]`.
  List<Segment> get segments;

  /// core.element.ts:14 `options: O`, through `Element<T, O>`
  /// (index.d.ts:1978).
  @override
  Map<String, Object?> get options;

  /// element.line.js:284 `_chart`. Dart `null` stands for JS `undefined`,
  /// the start value. `controller.line.js:56` sets it. JS `null` never
  /// reaches it.
  Chart? get chart;

  /// element.line.js:285 `_loop`. Dart `null` stands for JS `undefined`, the
  /// start value. JS `null` never reaches it.
  bool? get loop;

  /// element.line.js:286 `_fullLoop`. Dart `null` stands for JS
  /// `undefined`, the start value. JS `null` never reaches it.
  bool? get fullLoop;

  /// element.line.js:292 `_datasetIndex`. Dart `null` stands for JS
  /// `undefined`, the start value. `controller.line.js:57` sets it. JS `null`
  /// never reaches it.
  ///
  /// `doSplitByStyles` copies it into the segment context
  /// (helpers.segment.js:282, :315-321), where an own `undefined` key and an
  /// absent key are two states. The port copies `null` as the `undefined`
  /// sentinel of `lib/src/js/js_undefined.dart`.
  double? get datasetIndex;
}

/// index.d.ts:2167 `BasePlatform`.
abstract interface class BasePlatform {
  /// index.d.ts:2174 `acquireContext(canvas, options?)`.
  ///
  /// The JS code passes `options.aspectRatio` as the second argument
  /// (core.controller.js:139, platform.base.js:16), not the
  /// `CanvasRenderingContext2DSettings` of index.d.ts. Thus the Dart
  /// parameter is the aspect ratio. Dart `null` stands for JS `undefined`.
  /// [canvas] is the item of `getCanvas` (core.controller.js:85): a canvas
  /// element, or any other value, which gives `null`.
  CanvasRenderingContext2D? acquireContext(
    Object? canvas, [
    double? aspectRatio,
  ]);

  /// index.d.ts:2185 `releaseContext(context): boolean`.
  bool releaseContext(CanvasRenderingContext2D context);

  /// index.d.ts:2193 `addEventListener(chart, type, listener)`.
  ///
  /// [listener] is a JS function value of three shapes
  /// (core.controller.js:976-1049): `void Function(ChartEvent)` for an
  /// event of `options.events`, `void Function([double? width,
  /// double? height])` for `'resize'`, and `void Function()` for
  /// `'attach'` and `'detach'`.
  void addEventListener(Chart chart, String type, Function listener);

  /// index.d.ts:2200 `removeEventListener(chart, type, listener)`. The
  /// upstream platforms ignore [listener] (`platform.dom.js:350`).
  void removeEventListener(Chart chart, String type, [Function? listener]);

  /// index.d.ts:2203 `getDevicePixelRatio`.
  double getDevicePixelRatio();

  /// index.d.ts:2211 `getMaximumSize(canvas, width?, height?,
  /// aspectRatio?)`. Dart `null` stands for JS `undefined`.
  ///
  /// core.controller.js:263 passes `options.maintainAspectRatio &&
  /// this.aspectRatio` as [aspectRatio]: a falsy value is `null` or 0.
  ({double width, double height}) getMaximumSize(
    HTMLCanvasElement canvas, [
    double? width,
    double? height,
    double? aspectRatio,
  ]);

  /// index.d.ts:2216 `isAttached(canvas): boolean`. Dart `null` stands for
  /// the JS `null` of a chart that has no canvas (core.controller.js:1044).
  bool isAttached(HTMLCanvasElement? canvas);

  /// index.d.ts:2221 `updateConfig(config): void`.
  void updateConfig(ChartConfiguration config);
}

/// index.d.ts:3865 `ChartConfiguration`.
///
/// core.controller.js:137 passes the `Config` of core.config.js to
/// `updateConfig`. Its `options` getter returns the options object of the
/// configuration, which `initOptions` always creates
/// (core.config.js:47-52).
abstract interface class ChartConfiguration {
  /// index.d.ts:3872 `options?: ChartOptions<TType>`. A Map
  /// (Chart.js ADR 0006).
  Map<String, Object?> get options;
}

/// core.element.ts:6 `Element`, which index.d.ts:10 imports.
abstract interface class Element {
  /// core.element.ts:11 `x: number`.
  double get x;

  /// core.element.ts:12 `y: number`.
  double get y;

  /// core.element.ts:14 `options: O`. The constructors leave it undefined
  /// (element.point.ts:52), and helpers.extras.ts:96 tests it. Dart `null`
  /// stands for JS `undefined` (Chart.js ADR 0006). JS `null` never reaches
  /// it.
  Map<String, Object?>? get options;
}

/// element.point.ts:20 `PointElement`, which index.d.ts:17 re-exports.
abstract interface class PointElement implements Element {
  /// element.point.ts:25 `skip?: boolean`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0006). JS `null` never reaches it.
  bool? get skip;

  /// element.point.ts:26 `stop?: boolean`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0006). JS `null` never reaches it.
  bool? get stop;
}

/// controller.radar.js:96 the property `angle` of a radar [PointElement].
///
/// The radar controller assigns `angle` to its point elements with the
/// other properties (controller.radar.js:93-99). `index.d.ts` does not
/// declare it. `helpers.segment.js` and `plugin.filler` read it by name as
/// `point[property]` (see [PointElementProperty]). A [PointElement] that is
/// not a [RadialPointElement] has no `angle`.
abstract interface class RadialPointElement implements PointElement {
  /// controller.radar.js:96 `angle: pointPosition.angle`. Dart `null` stands
  /// for JS `undefined`, the value before the first update. JS `null` never
  /// reaches it.
  double? get angle;
}

/// The JS property read `point[property]` of a [PointElement] with the
/// property name `'x'`, `'y'` or `'angle'`.
///
/// `helpers.segment.js` reads `points[i][property]` (:47, :104), and the
/// `property` of the bounds is `'x'`, `'y'` or `'angle'` (:72). This
/// extension keeps that read as one expression. It is not a declaration of
/// `index.d.ts`.
extension PointElementProperty on PointElement {
  /// `point[property]` for `'x'`, `'y'` and `'angle'`.
  ///
  /// `'angle'` gives NaN when the point is not a [RadialPointElement] or has
  /// no angle. JS gives `undefined`, and every reader passes the value to a
  /// number function, which makes it NaN (`_normalizeAngle`,
  /// helpers.math.ts:160). Any other name also gives NaN. JS gives
  /// `undefined` for an absent property, and the readers handle NaN as they
  /// handle `undefined`: `between` is false, so the bounded result is empty.
  double operator [](String property) => switch (property) {
    'x' => x,
    'y' => y,
    'angle' => switch (this) {
      final RadialPointElement point => point.angle ?? double.nan,
      _ => double.nan,
    },
    _ => double.nan,
  };
}
