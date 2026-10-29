// Ported from Chart.js v4.5.1+7169e651 src/types/index.d.ts (MIT, Chart.js Contributors).

/// The declarations of `src/types/index.d.ts` as Dart interfaces
/// (Chart.js ADR 0003, porting-flow.md 2.4).
///
/// Each interface gets its members when a ported caller needs them. A
/// TypeScript property becomes an abstract getter, and a setter is added when
/// a ported caller assigns through the type. `number` is `double`, also for
/// an index (Chart.js ADR 0045). An inline object type that ported code only
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
/// Chart.js ADR 0043 makes a JS plain object a Map, and the option resolvers
/// of `helpers.config` take the place of the upstream `Proxy` objects.
///
/// Upstream `_`-prefixed members that other modules read drop the underscore
/// (Chart.js ADR 0012), and the `///` line keeps the upstream name. A type
/// library imports only other type libraries (Chart.js ADR 0003). Thus these
/// members carry no `@internal`. The concrete classes carry it.
///
/// Outside option scopes, Dart `null` stands for one JS value (Chart.js ADR
/// 0043, "Values outside scopes"). The `///` line of each nullable member
/// names that value, or says that the readers treat JS `null` and
/// `undefined` alike.
library;

// The canvas interface and the native event stand in for lib.dom.d.ts, which
// index.d.ts names without an import. Both are pure, port-only interface
// libraries (Chart.js ADR 0013, Chart.js ADR 0037).
import 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show CanvasPath, CanvasRenderingContext2D, HTMLCanvasElement;
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart' show AnyObject;
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/layout.dart';

export 'package:flutter_chartjs_port/src/types/geometric.dart'
    show ChartArea, Point, TRBL;
export 'package:flutter_chartjs_port/src/types/layout.dart' show LayoutItem;

/// index.d.ts:463 `ChartMetaClip`, the type of `ChartMeta._clip`.
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
  /// index.d.ts:464 `left: number | boolean`. See [ChartMetaClip].
  Object? get left;

  /// index.d.ts:465 `top: number | boolean`. See [ChartMetaClip].
  Object? get top;

  /// index.d.ts:466 `right: number | boolean`. See [ChartMetaClip].
  Object? get right;

  /// index.d.ts:467 `bottom: number | boolean`. See [ChartMetaClip].
  Object? get bottom;

  /// index.d.ts:468 `disabled: boolean`.
  bool get disabled;
}

/// index.d.ts:507 `ChartMeta`, with the members of `ChartMetaCommon`
/// (index.d.ts:471).
abstract interface class ChartMeta {
  /// index.d.ts:472 `type: string`, the dataset type.
  /// `getMatchingVisibleMetas` compares it with `===` (core.scale.js:1688).
  String get type;

  /// index.d.ts:473 `controller: DatasetController`. `core.interaction.js:23`
  /// reads it.
  ///
  /// Dart `null` stands for JS `null`, the start value
  /// (core.controller.js:839). `buildOrUpdateControllers` assigns the
  /// controller (core.controller.js:448). A reader that calls a member of a
  /// `null` controller throws a `TypeError`, as in JavaScript.
  DatasetController? get controller;

  /// index.d.ts:477 `index: number`, the dataset index. The interaction
  /// items copy it as `datasetIndex` (core.interaction.js:78, :289).
  double get index;

  /// index.d.ts:478 `visible: boolean`, the result of
  /// `isDatasetVisible` (core.controller.js:436). plugin.legend.js:687
  /// reads it.
  ///
  /// The `hide` animation writes the numbers 1 and 0
  /// (core.animations.defaults.js:64-68), and the readers apply ToBoolean.
  /// The `undefined` sentinel of `lib/src/js/js_undefined.dart` is the
  /// value before `buildOrUpdateControllers`.
  Object? get visible;

  /// index.d.ts:480 `stack: number`, the `stack` option of the dataset
  /// that `buildOrUpdateElements` copies (core.datasetController.js:420).
  ///
  /// The value is the raw option value: the `undefined` sentinel of
  /// `lib/src/js/js_undefined.dart` stands for JS `undefined`, the start
  /// value (the meta of core.controller.js:835 has no `stack`), and Dart
  /// `null` is JS `null`. A JS `null` stack is a stack: `isStacked` tests
  /// `meta.stack !== undefined` (core.datasetController.js:121).
  abstract Object? stack;

  /// index.d.ts:482 `indexAxis: 'x' | 'y'`. `buildOrUpdateControllers`
  /// writes it before it constructs the controller
  /// (core.controller.js:432), and `linkScales` reads it
  /// (core.datasetController.js:309). Dart `null` stands for JS
  /// `undefined`.
  String? get indexAxis;

  /// index.d.ts:484 `data: TElement[]`, the data elements of the dataset.
  ///
  /// `TElement extends Element = Element`. Thus an item is an [Element].
  /// The interaction code reads the members of `VisualElement` and of the
  /// concrete `Element` of `core.element.dart` from it
  /// (core.interaction.js:82-83, :125, :146).
  List<Element> get data;

  /// index.d.ts:485 `dataset?: TDatasetElement`. Dart `null` stands for JS
  /// `null`, the start value (core.controller.js:838), and for `undefined`.
  /// The readers test only its truthiness (helpers.extras.ts:96).
  /// `addElements` assigns it (core.datasetController.js:400).
  abstract Element? dataset;

  /// index.d.ts:487 `hidden: boolean`, the visibility override of the
  /// dataset. Dart `null` stands for JS `null`, the start value
  /// (core.controller.js:840). `createStack` tests its truthiness
  /// (core.datasetController.js:231).
  bool? get hidden;

  /// index.d.ts:489 `xAxisID?: string`, the id of the x scale.
  /// `getMatchingVisibleMetas` reads it as `meta[axis + 'AxisID']`
  /// (core.scale.js:1685-1689). Dart `null` stands for JS `undefined` and
  /// for JS `null`: the start value is `null` (core.controller.js:841), and
  /// a dataset can give `null`. The readers compare it with a scale id, which
  /// neither value equals. `linkScales` assigns it
  /// (core.datasetController.js:306).
  ///
  /// The type is `Object?`: `linkScales` keeps the raw `dataset.xAxisID`,
  /// as upstream does. A number id stays a number. It finds the scale of the
  /// property key `ToString(id)`, but it equals no scale id, as the `===` of
  /// core.scale.js:1688.
  abstract Object? xAxisID;

  /// index.d.ts:490 `yAxisID?: string`, the id of the y scale. Dart `null`
  /// stands for JS `undefined` and `null`, as for [xAxisID]
  /// (core.controller.js:842).
  abstract Object? yAxisID;

  /// index.d.ts:491 `rAxisID?: string`, the id of the radial scale. Dart
  /// `null` stands for JS `undefined`, as for [xAxisID].
  abstract Object? rAxisID;

  /// index.d.ts:492 `iAxisID: string`, the id of the index scale.
  /// `linkScales` assigns it (core.datasetController.js:310). Dart `null`
  /// stands for JS `undefined`, as for [xAxisID].
  abstract Object? iAxisID;

  /// index.d.ts:493 `vAxisID: string`, the id of the value scale.
  /// `linkScales` assigns it (core.datasetController.js:311). Dart `null`
  /// stands for JS `undefined`, as for [xAxisID].
  abstract Object? vAxisID;

  /// index.d.ts:495 `xScale?: Scale`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0043). JS `null` never reaches it.
  /// `linkScales` assigns it and the other four scales
  /// (core.datasetController.js:312-316).
  abstract Scale? xScale;

  /// index.d.ts:496 `yScale?: Scale`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0043). JS `null` never reaches it.
  abstract Scale? yScale;

  /// index.d.ts:497 `rScale?: Scale`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0043). JS `null` never reaches it.
  abstract Scale? rScale;

  /// index.d.ts:498 `iScale?: Scale`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0043). JS `null` never reaches it.
  abstract Scale? iScale;

  /// index.d.ts:499 `vScale?: Scale`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0043). JS `null` never reaches it.
  abstract Scale? vScale;

  /// index.d.ts:501 `_sorted: boolean`. `parse` assigns it
  /// (core.datasetController.js:462, :483).
  abstract bool sorted;

  /// index.d.ts:502 `_stacked: boolean | 'single'`, the result of
  /// `isStacked` (core.datasetController.js:119-122).
  ///
  /// The value is the `stacked` option of the value scale when it is
  /// truthy, for example `true` or `'single'`, else a `bool`. Dart `null`
  /// stands for JS `undefined`, the start value. The readers test its
  /// truthiness, and `buildOrUpdateElements` compares it with `!==`
  /// (core.datasetController.js:428).
  abstract Object? stacked;

  /// index.d.ts:503 `_parsed: unknown[]`.
  ///
  /// An entry is any value. The `parse*Data` methods give parsed data
  /// objects, which ported code reads by an axis key (helpers.extras.ts:103,
  /// :111). Chart.js ADR 0043 makes a JS plain object a Map. With `parsing:
  /// false`, `parse` assigns the data array itself
  /// (core.datasetController.js:461), and its items can be primitives. The
  /// doughnut controller writes numbers (controller.doughnut.js:153, :164).
  /// Dart `null` is a JS `null` entry, and the `undefined` sentinel a hole.
  abstract List<Object?> parsed;

  /// index.d.ts:504 `_clip: ChartMetaClip`. `_update` assigns it
  /// (core.datasetController.js:704).
  abstract ChartMetaClip clip;

  /// helpers.extras.ts:145 `_scaleRanges`. `index.d.ts` does not declare
  /// it. `_scaleRangesChanged` reads it and assigns it (:153). Dart `null`
  /// stands for JS `undefined` (Chart.js ADR 0043). JS `null` never reaches
  /// it.
  abstract ScaleRanges? scaleRanges;

  /// core.controller.js:845 `_dataset`, the dataset object of the meta. The
  /// trailing underscore follows Chart.js ADR 0023. controller.line.js:43
  /// reads it.
  Object? get dataset_;

  /// index.d.ts:374 `DoughnutMetaExtensions.total`. Dart `null` stands for
  /// JS `undefined`, the value before controller.doughnut.js:235 writes it.
  abstract double? total;
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

/// index.d.ts:515 `ActiveDataPoint`.
abstract interface class ActiveDataPoint {
  /// index.d.ts:516 `datasetIndex: number`.
  double get datasetIndex;

  /// index.d.ts:517 `index: number`.
  double get index;
}

/// index.d.ts:520 `ActiveElement`, an item of `getActiveElements()`
/// (index.d.ts:576).
///
/// The interaction modes give the `InteractionItem` of `core.interaction.js`
/// (core.interaction.js:10), which has the same members.
/// `setActiveElements` makes the object `{datasetIndex, element, index}`
/// (core.controller.js:1104-1108).
abstract interface class ActiveElement implements ActiveDataPoint {
  /// index.d.ts:521 `element: Element`.
  ///
  /// Dart `null` stands for JS `undefined`: `setActiveElements` copies
  /// `meta.data[index]`, which is `undefined` for an index without an
  /// element (core.controller.js:1106). A reader that calls a member of it
  /// throws a `TypeError`, as in JavaScript.
  Element? get element;
}

/// index.d.ts:524 `Chart`.
abstract interface class Chart {
  /// index.d.ts:529 `readonly platform: BasePlatform`.
  BasePlatform get platform;

  /// index.d.ts:531 `readonly canvas: HTMLCanvasElement`.
  ///
  /// Dart `null` stands for JS `null`: the constructor keeps the `null` of a
  /// failed `acquireContext` (core.controller.js:140), and `destroy()` sets
  /// it (core.controller.js:948). `platform.dom.js:104` tests it.
  HTMLCanvasElement? get canvas;

  /// index.d.ts:532 `readonly ctx: CanvasRenderingContext2D`.
  ///
  /// Dart `null` stands for JS `null`, as for [canvas]
  /// (core.controller.js:139, :949). The throttled event proxy tests it
  /// (`platform.dom.js:246`).
  CanvasRenderingContext2D? get ctx;

  /// index.d.ts:533 `readonly config: ChartConfiguration`.
  ///
  /// The chart of `core.controller.js` keeps its `Config` of
  /// `core.config.js` here (core.controller.js:124). The dataset controller
  /// reads the scope keys, the scopes and the resolvers from it
  /// (core.datasetController.js:439, :813, :851). Those members are not in
  /// `ChartConfiguration`. Thus the reader casts the value to the `Config`
  /// of `lib/src/core/core.config.dart`.
  ChartConfiguration get config;

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

  /// core.controller.js:156 `_stacks`, the stacks of the datasets by stack
  /// key. `index.d.ts` does not declare it.
  ///
  /// The structure is `{stackKey: {indexValue: {datasetIndex: value}}}`
  /// (core.datasetController.js:154). The keys are the `ToString` of the
  /// upstream keys. `updateStacks` assigns `{}` when it is absent. Dart
  /// `null` stands for JS `undefined`, the start value, and for the `delete`
  /// of core.controller.js:406. JS `null` never reaches it.
  abstract Map<String, Object?>? stacks;

  /// core.controller.js:171 `_animationsDisabled`: `!options.animation` of
  /// the last update (core.controller.js:480). `index.d.ts` does not
  /// declare it. `includeOptions` tests its truthiness
  /// (core.datasetController.js:879). Dart `null` stands for JS
  /// `undefined`, the start value.
  bool? get animationsDisabled;

  /// core.controller.js:174 `_dataChanges`, the data changes since the last
  /// update. `index.d.ts` does not declare it.
  ///
  /// Each item is `[datasetIndex, method, start, count]`: `_sync` of the
  /// dataset controller adds it (core.datasetController.js:1048). The
  /// method is `'_insertElements'` or `'_removeElements'`, and the numbers
  /// are `double` values.
  List<List<Object?>> get dataChanges;

  /// index.d.ts:534 `readonly width: number`. `retinaScale` assigns it
  /// through the `PrivateChart` type (helpers.dom.ts:218), so it has a
  /// setter.
  abstract double width;

  /// index.d.ts:535 `readonly height: number`. `retinaScale` assigns it
  /// through the `PrivateChart` type (helpers.dom.ts:217), so it has a
  /// setter.
  abstract double height;

  /// index.d.ts:537 `readonly boxes: LayoutItem[]`, the layout boxes.
  ///
  /// The constructor sets `[]` (core.controller.js:157). An array is always
  /// truthy. Thus the tests of `core.layouts.js:292`, `:319` and `:32` for a
  /// chart without boxes have no Dart form. `layouts.addBox` and
  /// `layouts.removeBox` change the list.
  List<LayoutItem> get boxes;

  /// index.d.ts:538 `readonly currentDevicePixelRatio: number`.
  /// `_alignPixel` reads it (helpers.canvas.ts:126). `retinaScale` assigns
  /// it through the `PrivateChart` type (helpers.dom.ts:235), so it has a
  /// setter.
  abstract double currentDevicePixelRatio;

  /// index.d.ts:539 `readonly chartArea: ChartArea`. `layouts.update`
  /// assigns it (core.layouts.js:439), so it has a setter.
  ///
  /// Dart `null` stands for JS `undefined`, the start value
  /// (core.controller.js:159), until the first layout. A reader that reads
  /// an edge of it throws a `TypeError`, as in JavaScript. The setter takes
  /// a [ChartArea]: no ported code assigns `undefined`.
  ChartArea? get chartArea;
  set chartArea(ChartArea value);

  /// index.d.ts:540 `readonly scales: { [key: string]: Scale }`, the scales
  /// by id. `core.scale.js:144`, `:1064` and `:1182` read the scale of an
  /// object position from it.
  Map<String, Scale> get scales;

  /// index.d.ts:546 `data: ChartData`, the data object of the
  /// configuration. A Map (Chart.js ADR 0043). `Scale.getLabels` reads its
  /// `labels`, `xLabels` and `yLabels` (core.scale.js:359-361).
  Map<String, Object?> get data;

  /// index.d.ts:547 `options: ChartOptions<TType>`.
  Map<String, Object?> get options;

  /// index.d.ts:561 `draw(): void`: draws the chart.
  ///
  /// The animator calls it in each frame in which an animation of the chart
  /// ticks (core.animator.js:88-89, Chart.js ADR 0019, section 1).
  void draw();

  /// index.d.ts:563 `isPointInArea(point: Point): boolean`.
  bool isPointInArea(Point point);

  /// index.d.ts:564 `getElementsAtEventForMode(e, mode, options,
  /// useFinalPosition)`. plugin.tooltip.js:1200 calls it.
  ///
  /// [e] is a [ChartEvent] or a `NativeEvent`, as the interaction modes
  /// take it. The concrete result is a `List<InteractionItem>` of
  /// `core.interaction.dart`, a valid covariant override (Chart.js ADR 0038,
  /// section 6). Thus a reader never adds an item to the result: it copies
  /// the list or reorders it in place. Dart `null` for [useFinalPosition]
  /// stands for JS `undefined`.
  List<ActiveElement> getElementsAtEventForMode(
    Object e,
    Object? mode,
    Object? options, [
    // The upstream signature has a positional `useFinalPosition`.
    // ignore: avoid_positional_boolean_parameters
    bool? useFinalPosition,
  ]);

  /// index.d.ts:566 `getSortedVisibleDatasetMetas(): ChartMeta[]`.
  List<ChartMeta> getSortedVisibleDatasetMetas();

  /// index.d.ts:567 `getDatasetMeta(datasetIndex: number): ChartMeta`.
  ChartMeta getDatasetMeta(double datasetIndex);

  /// core.controller.js:737 `_getSortedDatasetMetas(filterVisible)`: the
  /// metas in the drawing order, only the visible ones when [filterVisible]
  /// is true. `index.d.ts` does not declare it. The dataset controller
  /// reads it (core.datasetController.js:61).
  List<ChartMeta> getSortedDatasetMetas(
    // The upstream signature has a positional `filterVisible`.
    // ignore: avoid_positional_boolean_parameters
    bool filterVisible,
  );

  /// index.d.ts:572 `getDataVisibility(index: number): boolean`. The radial
  /// scale calls it (scale.radialLinear.js:463).
  bool getDataVisibility(double index);

  /// index.d.ts:585 `notifyPlugins(hook: string, args?: AnyObject): boolean
  /// | void`. The scale hooks call it (core.scale.js:535).
  ///
  /// Dart `null` for [args] stands for JS `undefined`. The result is the
  /// result of `notify`: false when a plugin cancels the hook. Dart `null`
  /// stands for the `void` result, the `undefined` of a notify before the
  /// hook `install` or after the hook `uninstall` (core.plugins.js:41-43).
  bool? notifyPlugins(String hook, [Map<String, Object?>? args]);

  /// index.d.ts:587 `isPluginEnabled(pluginId: string): boolean`. The
  /// dataset controller calls it for the filler
  /// (core.datasetController.js:287).
  bool isPluginEnabled(String pluginId);

  /// index.d.ts:589 `getContext(): { chart: Chart, type: string }`.
  ///
  /// The context is the parent of `createContext` (helpers.options.ts:204),
  /// so it is an object, not a record. `core.controller` returns
  /// `createContext(null, {...})`, a `ContextObject` of `helpers.options`.
  Map<String, Object?> getContext();

  /// index.d.ts:543 `readonly legend?: LegendElement`. Dart `null` stands
  /// for JS `undefined`. The legend plugin writes it (plugin.legend.js:602)
  /// and deletes it (:609). controller.doughnut.js:97 reads it.
  abstract LegendElement? legend;

  /// index.d.ts:544 `readonly tooltip?: TooltipModel`. Dart `null` stands
  /// for JS `undefined`, the start value. The tooltip plugin writes it
  /// (plugin.tooltip.js:1230). No hook deletes it, so the value stays.
  abstract TooltipModel? tooltip;

  /// plugin.title.js:117 `chart.titleBlock`. index.d.ts does not declare it.
  /// Dart null stands for JS `undefined` and for the `delete` of :136.
  abstract LayoutItem? titleBlock;

  /// index.d.ts:559 `update(mode?)`. controller.doughnut.js:127 calls it.
  void update([Object? mode]);

  /// index.d.ts:568 `getVisibleDatasetCount()`.
  /// controller.polarArea.js:155 calls it.
  double getVisibleDatasetCount();

  /// index.d.ts:569 `isDatasetVisible(datasetIndex)`.
  /// controller.doughnut.js:192 calls it.
  bool isDatasetVisible(double datasetIndex);

  /// index.d.ts:571 `toggleDataVisibility(index)`.
  /// controller.doughnut.js:126 and controller.polarArea.js:66 call it.
  ///
  /// [index] is any JS value (the form of Chart.js ADR 0025, section 1):
  /// the legend item index of a user `generateLabels` can be a value that is
  /// not a number. The key is `ToString(index)` (core.controller.js:882).
  void toggleDataVisibility(Object? index);

  /// index.d.ts:573 `hide(datasetIndex, dataIndex?)`. plugin.legend.js:649
  /// calls it. Dart `null` for [dataIndex] stands for an absent argument.
  void hide(double datasetIndex, [double? dataIndex]);

  /// index.d.ts:574 `show(datasetIndex, dataIndex?)`. plugin.legend.js:652
  /// calls it. Dart `null` for [dataIndex] stands for an absent argument.
  void show(double datasetIndex, [double? dataIndex]);
}

/// index.d.ts:622 `DatasetController`.
abstract interface class DatasetController {
  /// index.d.ts:631 `readonly index: number`, the dataset index.
  /// `clearStacks` reads it from the meta (core.datasetController.js:210).
  double get index;

  /// index.d.ts:632 `readonly _cachedMeta: ChartMeta`, the meta of the
  /// dataset (core.datasetController.js:260). `core.interaction.js:24` and
  /// `:32` read it.
  ChartMeta get cachedMeta;

  /// index.d.ts:637 `supportsDecimation: boolean`. The constructor sets
  /// `false` (core.datasetController.js:271). plugin.decimation.js:225
  /// reads it.
  bool get supportsDecimation;

  /// core.datasetController.js:267 `_sharedOptions`, the options that all
  /// data elements share. `index.d.ts` does not declare it.
  /// `core.interaction.js:49` tests its truthiness.
  ///
  /// Dart `null` stands for JS `undefined`, the start value. JS `null` never
  /// reaches it. An object is always truthy.
  Map<String, Object?>? get sharedOptions;

  /// core.datasetController.js:443 `_parsing`, the `parsing` option.
  /// `index.d.ts` does not declare it. `_parseObjectDataRadialScale`
  /// (helpers.config.ts:444) reads it as `this._parsing`. Its value is
  /// `false` or an object of the parsing keys (Chart.js ADR 0043).
  Object? get parsing;

  /// index.d.ts:640 `getAllParsedValues(scale: Scale): number[]`. The time
  /// scale calls it (scale.time.js:638, :642).
  List<double> getAllParsedValues(Scale scale);

  /// index.d.ts:641 `getLabelAndValue(index)`. plugin.tooltip.js:130 calls
  /// it.
  ///
  /// The result is a record of the object `{label, value}`. index.d.ts
  /// declares a string label, but the controllers return the raw label:
  /// any JS value, Dart `null` for JS `null` or the `undefined` sentinel
  /// (Chart.js ADR 0028, section 2). The tooltip item keeps it.
  ({Object? label, String value}) getLabelAndValue(double index);

  /// index.d.ts:648 `getDataset()`. plugin.tooltip.js:138 calls it.
  ///
  /// The dataset `chart.data.datasets[index]`: a Map, or the `undefined`
  /// sentinel for an index that names no dataset.
  Object? getDataset();

  /// index.d.ts:696 `getMinMax(scale: Scale, canStack?: boolean): { min:
  /// number; max: number }`. `Scale.getMinMax` reads the range of each
  /// visible dataset of the scale (core.scale.js:312).
  ///
  /// Dart `null` for [canStack] stands for JS `undefined`. The result is a
  /// record.
  ({double min, double max}) getMinMax(
    Scale scale, [
    // The upstream signature has a positional `canStack`.
    // ignore: avoid_positional_boolean_parameters
    bool? canStack,
  ]);

  /// core.datasetController.js:262 `options`, the resolver of the dataset
  /// options. index.d.ts does not declare it. controller.bar.js:437 reads it.
  Map<String, Object?> get options;

  /// index.d.ts:688 `getParsed(index)`. controller.bar.js:440 calls it.
  Object? getParsed(double index);

  /// index.d.ts:656 `getStyle(index, active)`. controller.doughnut.js:101
  /// calls it.
  Map<String, Object?> getStyle(
    double? index, [
    // The upstream signature has a positional `active`.
    // ignore: avoid_positional_boolean_parameters
    bool? active,
  ]);

  /// index.d.ts:658 `resolveDataElementOptions(index, mode)`.
  /// controller.doughnut.js:354 calls it.
  Map<String, Object?> resolveDataElementOptions(double index, [String? mode]);
}

/// index.d.ts:706 `Defaults`, the type of the `defaults` object of
/// `core.defaults.js`.
///
/// The `apply*Defaults` functions of `core.animations.defaults.js`,
/// `core.layouts.defaults.js` and `core.scale.defaults.js` take it. The option
/// members of `CoreChartOptions`, `ElementChartOptions` and
/// `PluginChartOptions` (index.d.ts:706) wait for their first ported caller.
/// The concrete class of `core.defaults.js` has the same name. Thus that file
/// imports this library with the prefix `types`.
abstract interface class Defaults {
  /// index.d.ts:714 `set(scope: string, values: AnyObject): AnyObject`.
  ///
  /// The overload `set(values)` (index.d.ts:713) has the same name. The
  /// concrete `Defaults` of `core.defaults.dart` takes both forms as
  /// `set(Object? scope, [Object? values = undefined])`.
  Map<String, Object?> set(String scope, Map<String, Object?> values);

  /// index.d.ts:717 `describe(scope: string, values: AnyObject): AnyObject`.
  ///
  /// The `Defaults` constructor also calls `describe(values)` with one
  /// argument (core.defaults.js:82). `describe` at core.defaults.js:102 takes
  /// a `{string|object}` scope and passes it to `set(root, scope, values)` at
  /// :27. index.d.ts declares only the two-argument form. The concrete
  /// `Defaults` of `core.defaults.dart` takes both forms as
  /// `describe(Object? scope, [Object? values = undefined])`.
  Map<String, Object?> describe(String scope, Map<String, Object?> values);

  /// index.d.ts:737 `route(scope, name, targetScope, targetName): void`.
  ///
  /// Routes the named defaults to fallback to another scope/name.
  void route(String scope, String name, String targetScope, String targetName);
}

/// index.d.ts:1194 `Tick`.
abstract interface class Tick {
  /// index.d.ts:1195 `value: number`.
  double get value;

  /// scale.logarithmic.js:55 `significand`. `index.d.ts` does not declare
  /// it. `core.ticks.js:75` reads it. Dart `null` stands for JS `undefined`
  /// (Chart.js ADR 0043): the ticks of other scales do not set it. JS `null`
  /// never reaches it.
  double? get significand;
}

/// index.d.ts:1303 `Scale`.
abstract interface class Scale implements Element, LayoutItem {
  /// index.d.ts:1304 `readonly id: string`. `getStackKey` reads it
  /// (core.datasetController.js:125).
  String get id;

  /// index.d.ts:1305 `readonly type: string`, the scale type.
  /// plugin.decimation.js:231 reads it.
  String get type;

  /// index.d.ts:1307 `readonly chart: Chart`.
  Chart get chart;

  /// index.d.ts:1317 `axis: string`.
  @override
  String get axis;

  /// index.d.ts:1319 `min: number`.
  double get min;

  /// index.d.ts:1320 `max: number`.
  double get max;

  /// index.d.ts:1322 `getMatchingVisibleMetas(type?: string): ChartMeta[]`.
  /// Dart `null` for [type] stands for JS `undefined`.
  /// `getLastIndexInStack` calls it (core.datasetController.js:142).
  List<ChartMeta> getMatchingVisibleMetas([String? type]);

  /// core.scale.js:240 `_reversePixels`: whether the pixels of the scale run
  /// against its values (core.scale.js:495). `index.d.ts` does not declare
  /// it. `core.interaction.js:28` reads it.
  bool get reversePixels;

  /// core.scale.js:233 `_length`: the length of the scale in pixels.
  /// `index.d.ts` does not declare it. `determineMaxTicks` reads it
  /// (core.scale.autoskip.js:52).
  double get length;

  /// core.scale.js:234 `_maxLength`: the length of the scale with its
  /// margins. `index.d.ts` does not declare it. `determineMaxTicks` reads it
  /// (core.scale.autoskip.js:53).
  double get maxLength;

  /// core.element.ts:14 `options: O`, through `Element<unknown, O>`
  /// (index.d.ts:1303).
  @override
  Map<String, Object?> get options;

  /// index.d.ts:1352 `getLabelForValue(value: number): string`.
  ///
  /// The scale of `core.scale.js:877` returns [value] as it is. Thus the
  /// parameter and the result are any value. `getLabelAndValue` applies
  /// `ToString` to the result (core.datasetController.js:693-694).
  Object? getLabelForValue(Object? value);

  /// index.d.ts:1366 `getPixelForValue(value: number, index?: number):
  /// number`.
  ///
  /// index.d.ts:1366 types [value] as a number. core.scale.js:884 documents
  /// `@param {*} value`, and each scale tests the JS type of the value, for
  /// example `scale.category.js:133-139` and `scale.logarithmic.js:210-220`.
  /// Thus [value] is any JS value: Dart `null` is JS `null`, and the
  /// `undefined` sentinel is JS `undefined` (Chart.js ADR 0025). Dart `null`
  /// for [index] stands for JS `undefined`.
  double getPixelForValue(Object? value, [double? index]);

  /// index.d.ts:1385 `parse`.
  Object? parse(Object? raw, [double? index]);

  /// index.d.ts:1386 `getUserBounds`.
  ({double min, double max, bool minDefined, bool maxDefined}) getUserBounds();

  /// index.d.ts:1389 `getLabels(): string[]`. A label is a `String`, a
  /// `List` of lines or another value (core.scale.js:358-363).
  /// `parsePrimitiveData` reads it (core.datasetController.js:506).
  List<Object?> getLabels();

  /// core.scale.js:977 `_tickSize()`: the space of one tick label along the
  /// scale. `index.d.ts` does not declare it. `determineMaxTicks` calls it
  /// (core.scale.autoskip.js:51).
  double tickSize();

  /// core.scale.js:247 `_cache`. controller.bar.js:8 reads it.
  Map<String, Object?> get cache;

  /// index.d.ts:1321 `ticks`. controller.bar.js:47 reads it.
  List<Tick>? get ticks;

  /// index.d.ts:1346. controller.bar.js:48 calls it.
  double? getPixelForTick(int index);

  /// index.d.ts:1376 `getBaseValue(): number`. filler.options.js:112 calls
  /// it.
  double getBaseValue();

  /// index.d.ts:1382. controller.bar.js:396 calls it.
  double getBasePixel();

  /// core.scale.js:237 `_startPixel`. controller.bar.js:549 reads it.
  double get startPixel;

  /// core.scale.js:239 `_endPixel`. controller.bar.js:550 reads it.
  double get endPixel;

  /// index.d.ts:1339. controller.bar.js:606 calls it.
  double getPixelForDecimal(double decimal);

  /// index.d.ts:1374. controller.bar.js:615 calls it.
  double? getValueForPixel(double pixel);

  /// index.d.ts:1357. The value is any JS value (Chart.js ADR 0025 §1).
  /// controller.bar.js:620 calls it.
  double getLineWidthForValue(Object? value);
}

/// index.d.ts:3676 `RadialLinearScale`. `RadialLinearScale` of
/// `scale.radialLinear.dart` implements it. The filler tests
/// `scale is RadialLinearScale` for `if (scale.getPointPositionForValue)`
/// (filler.target.js:50, filler.drawing.js:28).
abstract interface class RadialLinearScale implements Scale {
  /// index.d.ts:3677 `xCenter`. controller.polarArea.js:167 and
  /// controller.radar.js:90 read it.
  ///
  /// Dart `null` stands for JS `undefined`, the value before the first
  /// layout of the scale (scale.radialLinear.js:416). The radar and polar
  /// area controllers write it into a new element as `undefined` when they
  /// reset the element before that layout. Chart.js ADR 0033 records this
  /// form.
  double? get xCenter;

  /// index.d.ts:3678 `yCenter`. controller.polarArea.js:168 and
  /// controller.radar.js:91 read it. Dart `null` stands for JS `undefined`,
  /// as for [xCenter].
  double? get yCenter;

  /// index.d.ts:3681. controller.polarArea.js:169 calls it.
  double getIndexAngle(double index);

  /// index.d.ts:3682. The value is any JS value (Chart.js ADR 0025 §1).
  /// controller.polarArea.js:182 calls it.
  double getDistanceFromCenterForValue(Object? value);

  /// index.d.ts:3685. The result is a record (Chart.js ADR 0003).
  /// controller.radar.js:88 calls it.
  ({double x, double y, double angle}) getPointPositionForValue(
    double index,
    Object? value,
  );
}

/// index.d.ts:1530 `LabelItem`, an item of `Scale.getLabelItems`
/// (index.d.ts:1390, core.scale.js:1321-1334).
abstract interface class LabelItem {
  /// index.d.ts:1531 `label: string | string[]`: a `String`, a `List` of
  /// lines or another value of the tick callback.
  Object? get label;

  /// index.d.ts:1532 `font: CanvasFontSpec`.
  CanvasFontSpec get font;

  /// index.d.ts:1533 `textOffset: number`.
  double get textOffset;

  /// index.d.ts:1534 `options: RenderTextOpts`.
  RenderTextOpts get options;
}

/// index.d.ts:1434 `RenderTextOpts`, the options of `renderText`
/// (helpers.canvas.ts:449).
///
/// Every member is optional. Dart `null` stands for an absent key, JS
/// `undefined`. The readers treat JS `null` alike: `renderText` tests the
/// members for truthiness, with `isNullOrUndef`, or with `>`, which makes
/// `null` and `undefined` both fail.
abstract interface class RenderTextOpts {
  /// index.d.ts:1439 `color?: Color`: a CSS color `String`, a
  /// `CanvasGradient` or a `CanvasPattern` (color.d.ts:1). An empty String
  /// is falsy, so `setRenderOpts` leaves the fill style unchanged.
  Object? get color;

  /// index.d.ts:1445 `decorationWidth?: number`. A falsy value gives 2.
  double? get decorationWidth;

  /// index.d.ts:1450 `maxWidth?: number`.
  double? get maxWidth;

  /// index.d.ts:1456 `rotation?: number`, in radians.
  double? get rotation;

  /// index.d.ts:1461 `strikethrough?: boolean`.
  bool? get strikethrough;

  /// index.d.ts:1467 `strokeColor?: Color`, as [color].
  Object? get strokeColor;

  /// index.d.ts:1473 `strokeWidth?: number`.
  double? get strokeWidth;

  /// index.d.ts:1479 `textAlign?: CanvasTextAlign`.
  String? get textAlign;

  /// index.d.ts:1485 `textBaseline?: CanvasTextBaseline`.
  String? get textBaseline;

  /// index.d.ts:1490 `translation?: [number, number]`. The tuple is a
  /// record.
  (double, double)? get translation;

  /// index.d.ts:1495 `underline?: boolean`.
  bool? get underline;

  /// index.d.ts:1500 `backdrop?: BackdropOptions`.
  BackdropOptions? get backdrop;
}

/// index.d.ts:1503 `BackdropOptions`, the label backdrop of
/// [RenderTextOpts.backdrop].
abstract interface class BackdropOptions {
  /// index.d.ts:1507 `left: number`.
  double get left;

  /// index.d.ts:1512 `top: number`.
  double get top;

  /// index.d.ts:1517 `width: number`.
  double get width;

  /// index.d.ts:1522 `height: number`.
  double get height;

  /// index.d.ts:1527 `color: Scriptable<Color, ScriptableScaleContext>`.
  /// `drawBackdrop` assigns it to `fillStyle` as it is
  /// (helpers.canvas.ts:441): the caller resolves a scriptable value first
  /// (`core.scale.js:1307`).
  Object? get color;
}

/// index.d.ts:1574 `ChartEvent`.
///
/// It implements [Point], because ported code passes an event where
/// upstream expects a point: `this.isPointInArea(e)`
/// (core.controller.js:1168). TypeScript accepts it by structure.
abstract interface class ChartEvent implements Point {
  /// index.d.ts:1575 `type`, one of the DOM event names.
  String get type;

  /// index.d.ts:1588 `native: Event | null`. The port-only [NativeEvent]
  /// stands for the DOM event (Chart.js ADR 0037). Dart `null` stands for
  /// JS `null`, for example the `native` of a synthetic event.
  NativeEvent? get native;

  /// index.d.ts:1589 `x: number | null`. `fromNativeEvent` gives JS `null`
  /// for an `undefined` position (`platform.dom.js:116`). Dart `null` stands
  /// for that `null`.
  @override
  double? get x;

  /// index.d.ts:1590 `y: number | null`, as [x].
  @override
  double? get y;

  /// `platform.dom.js:114` `chart`, the chart of the event.
  /// `index.d.ts` does not declare it. Dart `null` stands for JS
  /// `undefined`, an event that `fromNativeEvent` did not make.
  Chart? get chart;
}

/// index.d.ts:1812 `FontSpec`.
///
/// The members are nullable, unlike upstream. `toFontString` tests
/// `isNullOrUndef(font.size)` and `isNullOrUndef(font.family)`
/// (helpers.canvas.ts:26), and the font object of `toFont` can lack them
/// (helpers.options.ts:119, :131). Dart `null` stands for both empty JS
/// values, because the readers treat them alike.
abstract interface class FontSpec {
  /// index.d.ts:1817 `family: string`.
  String? get family;

  /// index.d.ts:1822 `size: number`.
  double? get size;

  /// index.d.ts:1827 `style`, a CSS `font-style` keyword.
  String? get style;

  /// index.d.ts:1831 `weight`: a CSS `font-weight` keyword `String`, a
  /// `num` or `null`.
  Object? get weight;

  /// index.d.ts:1836 `lineHeight: number | string`: a `num` or a `String`.
  ///
  /// `renderText` reads it as `Number(font.lineHeight)`
  /// (helpers.canvas.ts:487), so a String gives its `ToNumber`. The font
  /// object of `toFont` has a number in pixels (helpers.options.ts:132).
  Object? get lineHeight;
}

/// index.d.ts:1839 `CanvasFontSpec`.
///
/// `toFont` returns it (helpers.options.ts:115). Its `lineHeight` is a
/// number in pixels.
abstract interface class CanvasFontSpec implements FontSpec {
  /// index.d.ts:1840 `string: string`. Dart `null` is JS `null`:
  /// `toFontString` gives `null` when the size or the family is empty
  /// (helpers.canvas.ts:26).
  String? get string;
}

/// index.d.ts:1846 `VisualElement`, the drawing and hit-test members of an
/// element class (Chart.js ADR 0017, section 1).
///
/// The element classes of `lib/src/elements/` extend the concrete `Element`
/// of `core.element.dart` and implement this interface.
///
/// `getRange?(axis)` (index.d.ts:1852) is optional in TypeScript. Dart has no
/// optional member. Thus it is the member of the port-only interface
/// [VisualElementRange] (Chart.js ADR 0020, section 9). The classes with an
/// upstream `getRange` implement that interface.
///
/// `useFinalPosition?: boolean` is `bool?`. Dart `null` stands for JS
/// `undefined`, which is falsy. JS `null` never reaches it.
///
/// A coordinate of [inRange], [inXRange] and [inYRange] is `double?`. Dart
/// `null` stands for JS `null`. The interaction modes pass the coordinate of
/// the event position unchanged (core.interaction.js:125, :174, :234, :236),
/// and an event coordinate can be JS `null` (`Point`). `BarElement` reads a
/// `null` coordinate as "ignore this axis" (element.bar.js:103-111). The
/// other elements do arithmetic on it, where JS `null` is 0.
abstract interface class VisualElement {
  /// index.d.ts:1847 `draw(ctx: CanvasRenderingContext2D, area?:
  /// ChartArea): void`. Dart `null` stands for an absent [area], JS
  /// `undefined`.
  ///
  /// A class whose upstream `draw` takes fewer parameters ignores [area], as
  /// JavaScript ignores an extra argument. A class can add optional
  /// parameters after [area], for example `start` and `count` of
  /// `LineElement.draw` (element.line.js:427).
  void draw(CanvasRenderingContext2D ctx, [ChartArea? area]);

  /// index.d.ts:1848 `inRange(mouseX, mouseY, useFinalPosition?):
  /// boolean`.
  bool inRange(
    double? mouseX,
    double? mouseY, [
    // The upstream signature has a positional `useFinalPosition`.
    // ignore: avoid_positional_boolean_parameters
    bool? useFinalPosition,
  ]);

  /// index.d.ts:1849 `inXRange(mouseX, useFinalPosition?): boolean`.
  bool inXRange(
    double? mouseX, [
    // The upstream signature has a positional `useFinalPosition`.
    // ignore: avoid_positional_boolean_parameters
    bool? useFinalPosition,
  ]);

  /// index.d.ts:1850 `inYRange(mouseY, useFinalPosition?): boolean`.
  bool inYRange(
    double? mouseY, [
    // The upstream signature has a positional `useFinalPosition`.
    // ignore: avoid_positional_boolean_parameters
    bool? useFinalPosition,
  ]);

  /// index.d.ts:1851 `getCenterPoint(useFinalPosition?): Point`.
  ///
  /// The element classes return the `ElementPoint` of `core.element.dart`,
  /// which stands for the object literal `{x, y}` (Chart.js ADR 0017,
  /// section 9).
  Point getCenterPoint([
    // The upstream signature has a positional `useFinalPosition`.
    // ignore: avoid_positional_boolean_parameters
    bool? useFinalPosition,
  ]);
}

/// index.d.ts:1852 the optional member `getRange?(axis: 'x' | 'y'): number`
/// of `VisualElement` (Chart.js ADR 0020, section 9). An element class with
/// an upstream `getRange` implements it.
///
/// `core.interaction.js:54` tests `typeof el.getRange === 'function'`. The
/// port tests the element against this interface. An element without it
/// gives `false`, as upstream. `PointElement` and `BarElement` implement
/// it. `ArcElement` and `LineElement` have no upstream `getRange`.
abstract interface class VisualElementRange implements VisualElement {
  /// index.d.ts:1852 `getRange(axis)`.
  ///
  /// The declared type is `number`, but `PointElement.getRange` gives the JS
  /// `+` of two options (element.point.ts:105): a `String` when an option is
  /// a string. Thus the result is an [Object]: a `double` or a `String`.
  Object getRange(String axis);
}

/// index.d.ts:1867 `Segment`.
abstract interface class Segment {
  /// index.d.ts:1868 `start: number`.
  double get start;

  /// index.d.ts:1869 `end: number`.
  double get end;

  /// index.d.ts:1870 `loop: boolean`.
  bool get loop;

  /// helpers.segment.js:8 `style?: any`. `index.d.ts` does not declare it.
  ///
  /// Dart `null` stands for JS `undefined` (Chart.js ADR 0043): the segments
  /// of `solidSegments` and of a line without segment styles have no style.
  /// JS `null` never reaches it. A style of `doSplitByStyles` is the
  /// `AnyObject` of `readStyle` (helpers.segment.js:337).
  Object? get style;
}

/// index.d.ts:2022 `LineElement`, with the fields of the class
/// (element.line.js:243) that `helpers.segment.js` reads.
abstract interface class LineElement implements Element {
  /// index.d.ts:2026 `points: Point[]`. The port narrows it to point
  /// elements: `helpers.segment.js` reads their `skip` and `stop`, and
  /// `helpers.curve` writes their control points, which the line reads.
  /// Upstream also stores plain points (filler.helper.js:28-33,
  /// filler.target.js:91, filler.segment.js:74-79). The filler wraps each
  /// plain point in a point element (Chart.js ADR 0040, section 1). See the
  /// difference `adapt-line-points-elements`.
  // DIVERGES(chartjs): adapt-line-points-elements, point elements only.
  List<PointElement> get points;

  /// index.d.ts:2027 `readonly segments: Segment[]`.
  List<Segment> get segments;

  /// core.element.ts:14 `options: O`, through `Element<T, O>`
  /// (index.d.ts:2023).
  ///
  /// Dart `null` stands for JS `undefined`, the start value
  /// (element.line.js:283), as in [Element.options]. `helpers.segment.js`
  /// reads it through `jsGet`, which throws a `TypeError` for `null`, as a
  /// JavaScript property read of `undefined` does. JS `null` never reaches
  /// it.
  @override
  Map<String, Object?>? get options;

  /// element.line.js:284 `_chart`. Dart `null` stands for JS `undefined`,
  /// the start value. `controller.line.js:57` sets it. JS `null` never
  /// reaches it.
  Chart? get chart;

  /// element.line.js:285 `_loop`. Dart `null` stands for JS `undefined`, the
  /// start value. JS `null` never reaches it.
  bool? get loop;

  /// element.line.js:286 `_fullLoop`. Dart `null` stands for JS
  /// `undefined`, the start value. JS `null` never reaches it.
  bool? get fullLoop;

  /// element.line.js:292 `_datasetIndex`. Dart `null` stands for JS
  /// `undefined`, the start value. `controller.line.js:58` sets it. JS `null`
  /// never reaches it.
  ///
  /// `doSplitByStyles` copies it into the segment context
  /// (helpers.segment.js:282, :315-321), where an own `undefined` key and an
  /// absent key are two states. The port copies `null` as the `undefined`
  /// sentinel of `lib/src/js/js_undefined.dart`.
  double? get datasetIndex;

  /// index.d.ts:2025 `updateControlPoints(chartArea, indexAxis)`.
  /// controller.line.js:140 calls it.
  ///
  /// Dart `null` for [chartArea] is JS `undefined`: the `chartArea` of a
  /// chart whose plugin cancels the first layout (`beforeLayout` returns
  /// `false`).
  void updateControlPoints(ChartArea? chartArea, [String? indexAxis]);

  /// index.d.ts:2028 `first()`: the first point that is not skipped.
  /// filler.drawing.js:93 and :123 call it.
  ///
  /// Dart `null` stands for the upstream `0` of a line without segments
  /// (element.line.js:327-331), which `index.d.ts` declares as `false`.
  PointElement? first();

  /// index.d.ts:2030 `interpolate(point, property)`. filler.drawing.js:201
  /// calls it.
  ///
  /// The result is Dart `null` for JS `undefined` (no segment in the
  /// bounds), one [Point] for one segment, or a `List<Point>`.
  Object? interpolate(Point point, String property);

  /// index.d.ts:2031 `pathSegment(ctx, segment, params)`.
  /// filler.drawing.js:85, :115, :143 and :153 call it.
  ///
  /// [ctx] is a context or a `Path2D`. [params] is the plain object `{move,
  /// reverse, start, end}`. Dart `null` stands for JS `undefined`, for
  /// [params] and for the result.
  bool? pathSegment(
    CanvasPath ctx,
    Segment segment, [
    Map<String, Object?>? params,
  ]);
}

/// simpleArc.js:4 `simpleArc`: the members that filler.drawing.js calls by
/// name on a fill target (:153, :201). It is not a declaration of
/// `index.d.ts`. The class `SimpleArc` of `plugin.filler/simpleArc.dart`
/// implements it (Chart.js ADR 0040, sections 4 and 5).
///
/// It does not implement [LineElement]. Thus `_segments`
/// (filler.segment.js:15) takes the `simpleArc` branch for each target that
/// is not a [LineElement].
// DIVERGES(chartjs): adapt-filler-target-classes, a port-only target interface.
abstract interface class SimpleArc {
  /// simpleArc.js:11 `pathSegment(ctx, bounds, opts)`. Dart `null` for
  /// [bounds] is JS `undefined`.
  bool pathSegment(
    CanvasPath ctx,
    ({String property, double start, double end})? bounds,
    AnyObject opts,
  );

  /// simpleArc.js:18 `interpolate(point)`. The reader reads only `x` and
  /// `y` of the result (filler.drawing.js:203).
  Point interpolate(PointElement point);
}

/// index.d.ts:2414 `LegendElement`, with the members that the option
/// functions of the controllers (controller.doughnut.js:97, :126) and the
/// legend specs (global.defaults.tests.js:46) read.
///
/// `index.d.ts` declares it with `extends Element, LayoutItem`. No ported
/// module reads a member of these interfaces through this interface. Thus
/// it does not implement them. The `Legend` class of `plugin.legend.dart`
/// extends the `Element` of `core.element.dart` and implements
/// [LayoutItem] itself (Chart.js ADR 0038, section 6).
abstract interface class LegendElement {
  /// index.d.ts:2415 `chart`.
  Chart get chart;

  /// index.d.ts:2417 `legendItems?: LegendItem[]`. Dart `null` stands for
  /// JS `undefined`, the value before the first `buildLabels`
  /// (plugin.legend.js:65).
  List<Object?>? get legendItems;

  /// index.d.ts:2418 `options`, the resolver of the legend options.
  Map<String, Object?> get options;
}

/// index.d.ts:2648 `TooltipModel`, with the members of Chart.js ADR 0039,
/// section 14. The `Tooltip` class of `plugin.tooltip.dart` implements it.
///
/// [x], [y] and [options] come from [Element]. A line of text can be any JS
/// value, so each list is a `List<Object?>`. The items of [dataPoints] and
/// [body] are plain objects (Maps). The constructor sets `undefined` for
/// these members, and `0` for [opacity] (plugin.tooltip.js:467-494). Dart
/// `null` for a list or an alignment stands for JS `undefined`. A number
/// getter gives NaN for JS `undefined` (Chart.js ADR 0039, section 2).
abstract interface class TooltipModel implements Element {
  /// index.d.ts:2649 `readonly chart`.
  Chart get chart;

  /// index.d.ts:2652 `dataPoints`: the tooltip items, plain objects.
  List<Object?>? get dataPoints;

  /// index.d.ts:2655 `xAlign`.
  String? get xAlign;

  /// index.d.ts:2656 `yAlign`.
  String? get yAlign;

  /// index.d.ts:2661 `width`.
  double get width;

  /// index.d.ts:2662 `height`.
  double get height;

  /// index.d.ts:2664 `caretX`.
  double get caretX;

  /// index.d.ts:2665 `caretY`.
  double get caretY;

  /// index.d.ts:2673 `body`: the plain objects `{before, lines, after}`.
  List<Object?>? get body;

  /// index.d.ts:2675 `beforeBody`.
  List<Object?>? get beforeBody;

  /// index.d.ts:2677 `afterBody`.
  List<Object?>? get afterBody;

  /// index.d.ts:2681 `title`.
  List<Object?>? get title;

  /// index.d.ts:2685 `footer`.
  List<Object?>? get footer;

  /// index.d.ts:2688 `labelColors`.
  List<Object?>? get labelColors;

  /// index.d.ts:2689 `labelTextColors`.
  List<Object?>? get labelTextColors;

  /// index.d.ts:2690 `labelPointStyles`.
  List<Object?>? get labelPointStyles;

  /// index.d.ts:2693 `opacity`. 0 is a hidden tooltip.
  double get opacity;

  /// index.d.ts:2698 `getActiveElements()`.
  List<ActiveElement> getActiveElements();

  /// index.d.ts:2699 `setActiveElements(active, eventPosition)`.
  ///
  /// Each item of [activeElements] is an [ActiveDataPoint] or a Map with
  /// the keys `datasetIndex` and `index`, as for `Chart.setActiveElements`.
  /// [eventPosition] is any JS value: the tooltip stores it
  /// (plugin.tooltip.js:1126). The `Tooltip` class gives an absent
  /// argument the `undefined` sentinel (Chart.js ADR 0039, section 12).
  void setActiveElements(List<Object?> activeElements, [Object? eventPosition]);
}

/// index.d.ts:2212 `BasePlatform`.
abstract interface class BasePlatform {
  /// index.d.ts:2219 `acquireContext(canvas, options?)`.
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

  /// index.d.ts:2229 `releaseContext(context): boolean`.
  bool releaseContext(CanvasRenderingContext2D context);

  /// index.d.ts:2237 `addEventListener(chart, type, listener)`.
  ///
  /// [listener] is a JS function value of three shapes
  /// (core.controller.js:976-1049): `void Function(ChartEvent)` for an
  /// event of `options.events`, `void Function([double? width,
  /// double? height])` for `'resize'`, and `void Function()` for
  /// `'attach'` and `'detach'`.
  void addEventListener(Chart chart, String type, Function listener);

  /// index.d.ts:2244 `removeEventListener(chart, type, listener)`. The
  /// upstream platforms ignore [listener] (`platform.dom.js:350`).
  void removeEventListener(Chart chart, String type, [Function? listener]);

  /// index.d.ts:2248 `getDevicePixelRatio`.
  double getDevicePixelRatio();

  /// index.d.ts:2256 `getMaximumSize(canvas, width?, height?,
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

  /// index.d.ts:2261 `isAttached(canvas): boolean`. Dart `null` stands for
  /// the JS `null` of a chart that has no canvas (core.controller.js:1044).
  bool isAttached(HTMLCanvasElement? canvas);

  /// index.d.ts:2266 `updateConfig(config): void`.
  void updateConfig(ChartConfiguration config);
}

/// index.d.ts:3914 `ChartConfiguration`.
///
/// core.controller.js:137 passes the `Config` of core.config.js to
/// `updateConfig`. Its `options` getter returns the options object of the
/// configuration, which `initOptions` always creates
/// (core.config.js:115-120).
abstract interface class ChartConfiguration {
  /// index.d.ts:3921 `options?: ChartOptions<TType>`. A Map
  /// (Chart.js ADR 0043).
  Map<String, Object?> get options;

  /// core.config.js:177 `get data()`. plugin.colors.ts:107-110 reads it.
  Map<String, Object?> get data;
}

/// core.element.ts:6 `Element`, which index.d.ts:10 imports.
///
/// It implements [Point], because ported code passes an element where
/// upstream expects a point, for example `_isPointInArea(this, …)`
/// (element.point.ts:92). TypeScript accepts it by structure (Chart.js ADR
/// 0017, section 1).
///
/// The access by name (`element[prop]`) is a member of the concrete
/// `Element` of `core.element.dart`, not of this interface. Thus the
/// extension [PointElementProperty] stays the property read of a
/// [PointElement] here. A helper that must tell `undefined` from NaN tests
/// the element against [ElementPropertyRead].
abstract interface class Element implements Point {
  /// core.element.ts:11 `x: number`. The concrete classes give NaN, the
  /// `ToNumber` of JS `undefined`, before the first write (Chart.js ADR
  /// 0017, section 4).
  @override
  double get x;

  /// core.element.ts:12 `y: number`. NaN before the first write, as [x].
  @override
  double get y;

  /// core.element.ts:14 `options: O`. The constructors leave it undefined
  /// (element.point.ts:52), and helpers.extras.ts:96 tests it. Dart `null`
  /// stands for JS `undefined` (Chart.js ADR 0043). JS `null` never reaches
  /// it.
  Map<String, Object?>? get options;

  /// core.element.ts:13 `active = false`. controller.bar.js:418 reads it.
  bool get active;

  /// The `hidden` property: core.controller.js:898 writes it,
  /// core.datasetController.js:730 reads it. core.element.ts does not
  /// declare it. Any JS value: the `undefined` sentinel in the start state.
  /// controller.bar.js:676 reads it.
  Object? get hidden;
}

/// element.point.ts:20 `PointElement`, which index.d.ts:17 re-exports.
///
/// It implements [SplinePoint], as [Element] implements [Point]:
/// `_updateBezierControlPoints` takes `SplinePoint[]`
/// (helpers.curve.ts:186-187), and `updateControlPoints` passes the point
/// elements of the line (element.line.js:303). TypeScript accepts them by
/// structure. Thus ported code passes a list of point elements to
/// `helpers.curve` without a cast. The control points `cp1x`, `cp1y`,
/// `cp2x` and `cp2y` are the members of [SplinePoint]: NaN stands for JS
/// `undefined`, the value before `helpers.curve` writes them (Chart.js ADR
/// 0017, section 3).
abstract interface class PointElement implements Element, SplinePoint {
  /// element.point.ts:25 `skip?: boolean`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0043). JS `null` never reaches it.
  @override
  bool? get skip;

  /// element.point.ts:26 `stop?: boolean`. Dart `null` stands for JS
  /// `undefined` (Chart.js ADR 0043). JS `null` never reaches it.
  bool? get stop;

  /// element.point.ts:81 `size(options)`. controller.line.js:133 calls it.
  double size([Map<String, Object?>? options]);
}

/// controller.radar.js:96 the property `angle` of a radar [PointElement].
///
/// The radar controller assigns `angle` to its point elements with the
/// other properties (controller.radar.js:93-99). `index.d.ts` does not
/// declare it. `helpers.segment.js` and `plugin.filler` read it by name as
/// `point[property]` (see [PointElementProperty]). A [PointElement] that is
/// not a [RadialPointElement] has no `angle`.
///
/// The concrete `PointElement` of `element.point.dart` implements this
/// interface. Its `angle` stays Dart `null` until the radar controller
/// assigns it (Chart.js ADR 0017, sections 3 and 4).
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
  ///
  /// `'x'` and `'y'` give the getters, which give NaN in the `undefined`
  /// state (Chart.js ADR 0017, section 4). `_boundSegment` keeps the
  /// `undefined` of `'x'` and `'y'` (helpers.segment.js:22), and
  /// `undefined === undefined` is true where `NaN === NaN` is false. Thus it
  /// tests the point with [ElementPropertyRead].
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

/// The JS property read `element[prop]` of an element (Chart.js ADR 0017,
/// section 5). It is not a declaration of `index.d.ts`.
///
/// The concrete `Element` of `core.element.dart` implements it. The read
/// gives the `undefined` sentinel for a property in the `undefined` state,
/// where the numeric getter gives NaN. A ported helper that must tell
/// `undefined` from NaN tests a point against this interface. Thus it does
/// not import `core.element.dart` (Chart.js ADR 0003). An example is
/// `boundSegment` of `helpers.segment.dart`.
// The access by name has one member, the property read.
// ignore: one_member_abstracts
abstract interface class ElementPropertyRead {
  /// The JS property read `element[prop]`. It gives the `undefined`
  /// sentinel for a property in the `undefined` state and for an unknown
  /// name.
  Object? operator [](String prop);
}

/// The JS property read `target[prop]` and the JS property write
/// `target[prop] = value` of an object that is not a Map (Chart.js ADR 0019,
/// section 2). It is not a declaration of `index.d.ts`.
///
/// The animations read and write their targets by name
/// (core.animation.js:29, :88, :94, :102; core.animations.js:71, :101,
/// :121). A target is a Map or a [PropertyAccess]. The concrete `Element` of
/// `core.element.dart` implements it with its access by name (Chart.js ADR
/// 0017, section 5).
abstract interface class PropertyAccess implements ElementPropertyRead {
  /// The JS property write `target[prop] = value`.
  void operator []=(String prop, Object? value);
}
