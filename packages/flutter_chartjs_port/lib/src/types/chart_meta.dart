// Original code, not ported from Chart.js: the native dataset meta.

/// The native dataset meta (doc/native-chart-meta-design-draft.md, row
/// `adapt-native-chart-meta`).
library;

import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/index.dart'
    show DatasetController, Element, Scale, ScaleRanges;
import 'package:meta/meta.dart';

/// core.controller.js:835-848 the dataset meta, index.d.ts:471
/// `ChartMetaCommon`: the state of one dataset of a chart.
///
/// `chart.getDatasetMeta(i)` gives it. The chart makes one meta for each
/// dataset object and keeps it while the dataset keeps its type: a new type
/// makes a new meta (core.controller.js:427-430). The controller of the
/// dataset keeps the same meta for its life.
///
/// The class is open. The state of one chart type goes to its controller
/// (`meta.controller`), for example `DoughnutController.total`. A plugin keeps
/// its state for each dataset in its own `Expando`:
///
/// ```dart
/// final _sources = Expando<FillerSource>('filler');
/// _sources[meta] = source;
/// ```
class ChartMeta<C extends DatasetController>({
  /// core.controller.js:844 `index`, the dataset index. Each update writes it
  /// again (core.controller.js:434).
  required var int index,

  /// core.controller.js:845 `_dataset`: the dataset of the app, a Map or the
  /// dataset scope of a typed config. Dart `null` stands for the `undefined`
  /// of an index with no dataset.
  required final Object? datasetConfig,

  /// core.controller.js:431 `type`, `dataset.type || config.type`. The chart
  /// computes it when it makes the meta.
  required final String type,

  /// core.controller.js:435 `label`, `'' + dataset.label`: the text
  /// `'undefined'` for no label. Each update writes it again.
  required var String label,

  /// core.controller.js:432 `indexAxis`. Each update writes it again.
  required var ScaleAxis indexAxis,

  /// core.controller.js:843 `order`, `dataset.order || 0`. Each update writes
  /// it again (core.controller.js:433).
  var double order = 0,
}) {
  /// Creates the meta of a dataset. `getDatasetMeta` calls it.
  this;

  /// core.datasetController.js:704 `_clip`. The first update of the
  /// controller writes it. An earlier read throws, as the upstream readers
  /// throw for a property of `undefined`.
  late ChartClip clip;

  /// core.controller.js:839 `controller`. Null until
  /// `buildOrUpdateControllers` makes it (core.controller.js:448).
  ///
  /// [C] is the class of the controllers: the chart gives each meta with
  /// the public `DatasetController`. This library is a pure layer, so the
  /// bound is the interface of `lib/src/types/`.
  C? controller;

  /// core.controller.js:837 `data`, the data elements.
  final List<Element> data = [];

  /// core.controller.js:838 `dataset`, the dataset element, for example the
  /// line of a line chart. Null for no dataset element.
  Element? dataset;

  /// core.controller.js:840 `hidden`, the visibility of the chart for the
  /// dataset. Null: the dataset option `hidden` decides
  /// (core.controller.js:871-873).
  bool? hidden;

  /// core.controller.js:436 `visible`, the result of `isDatasetVisible`. The
  /// `hide` animation writes the ToBoolean of `v | 0`
  /// (core.animations.defaults.js:64-68): the dataset stays visible to the
  /// end of the animation, as each upstream reader sees it.
  bool visible = false;

  /// core.datasetController.js:420 `stack`, the `stack` option of the
  /// dataset. Null: no stack.
  String? stack;

  /// core.datasetController.js:284 `_stacked`, the result of `isStacked`.
  StackMode stacked = StackMode.off;

  /// core.datasetController.js:306 `xAxisID`. Null: no scale of the axis.
  String? xAxisID;

  /// core.datasetController.js:307 `yAxisID`. Null: no scale of the axis.
  String? yAxisID;

  /// core.datasetController.js:308 `rAxisID`. Null: no scale of the axis.
  String? rAxisID;

  /// core.datasetController.js:310 `iAxisID`, the id of the index scale.
  String? iAxisID;

  /// core.datasetController.js:311 `vAxisID`, the id of the value scale.
  String? vAxisID;

  /// core.datasetController.js:312 `xScale`.
  Scale? xScale;

  /// core.datasetController.js:313 `yScale`.
  Scale? yScale;

  /// core.datasetController.js:314 `rScale`.
  Scale? rScale;

  /// core.datasetController.js:315 `iScale`, the index scale.
  Scale? iScale;

  /// core.datasetController.js:316 `vScale`, the value scale.
  Scale? vScale;

  /// core.controller.js:846 `_parsed`: the parsed items, the numbers of a
  /// doughnut or pie, or the data List of the app itself with
  /// `parsing: false` (core.datasetController.js:461). An add-on controller
  /// writes it in its `parse` override.
  List<Object?> parsed = [];

  /// core.controller.js:847 `_sorted`: whether [parsed] ascends on the index
  /// axis.
  bool sorted = false;

  /// helpers.extras.ts:153 `_scaleRanges`: the scale ranges of the last
  /// update of a line or scatter controller.
  @internal
  ScaleRanges? scaleRanges;

  /// core.animations.js:71 `$animations`: the running animation of
  /// [visible], by property name. Null: no animation ran yet.
  @internal
  Map<String, Object?>? animations;
}

/// core.datasetController.js:119-122 the `_stacked` value of a meta, the
/// result of `isStacked`.
enum StackMode() {
  /// `false`: the dataset does not stack.
  off,

  /// `true`: the dataset stacks.
  on,

  /// `'single'`: the dataset stacks once for each value
  /// (core.datasetController.js:72).
  single,
}

/// core.datasetController.js:28-44 `toClip`, index.d.ts:463
/// `ChartMetaClip`: the clip of a dataset.
///
/// A side holds the pixels outside the area of the dataset. Null is the JS
/// `false` of a side: no clip on that side. JS `true` is 0, and the
/// `undefined` side of a partial clip object is NaN, as the JS arithmetic of
/// `getDatasetClipArea` gives (helpers.dataset.ts:28-31).
@immutable
class const ChartClip({
  /// index.d.ts:464 `left`.
  final double? left,

  /// index.d.ts:465 `top`.
  final double? top,

  /// index.d.ts:466 `right`.
  final double? right,

  /// index.d.ts:467 `bottom`.
  final double? bottom,

  /// index.d.ts:468 `disabled`: the clip option is `false`.
  final bool disabled = false,
}) {
  /// Creates a clip. `toClip` calls it.
  this;
}
