// Ported from Chart.js v4.6.1 src/controllers/controller.pie.js (MIT, Chart.js Contributors).

/// Port of `src/controllers/controller.pie.js`.
///
/// [PieController] is the dataset controller of the `pie` charts. It is a
/// [DoughnutController] with other `defaults`: the methods, the
/// `descriptors` and the `overrides` come from the doughnut controller.
///
/// - [PieController.component] has the `parent`
///   [DoughnutController.component] (Chart.js ADR 0204). Its own statics are
///   `id` and `defaults`, as in the upstream class body. Upstream reads
///   `descriptors` and `overrides` through the static prototype chain. A
///   typed component inherits no value: it gives
///   [DoughnutController.descriptors] and [DoughnutController.overrides].
///   Thus the legend functions of `overrides['pie']` are the doughnut
///   functions (Chart.js ADR 0028, section 6).
/// - The registry registers the parent class first
///   (core.typedRegistry.js:28-31). The defaults of the scope
///   `datasets.pie` are the merge of the doughnut defaults and of
///   [PieController.defaults] (core.typedRegistry.js:84-92).
///
/// This library imports `controller.doughnut.dart`, which imports
/// `core.datasetController.dart`. Thus it is not a pure layer.
library;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// controller.pie.js:4 `PieController extends DoughnutController`.
///
/// Pie charts are Doughnut chart with different defaults
class PieController(super.chart, super.datasetIndex, [super.elements])
    extends DoughnutController {
  /// The default constructor of the JS class: `constructor(...args) {
  /// super(...args); }` (controller.pie.js:4 has no constructor).
  ///
  /// [elements] are the element types of the chart type (Chart.js ADR
  /// 0204).
  this;

  /// Native support for the explicit data-only lifecycle.
  @override
  // DIVERGES(chartjs): adapt-incremental-data-update, native opt-in.
  bool get supportsDataUpdates => super.runtimeType == PieController;

  /// controller.pie.js:6 `static id = 'pie'`.

  static const String id = 'pie';

  /// controller.pie.js:11 `static defaults`.
  ///
  /// @type {any}
  ///
  /// A typed scope of the kind `DoughnutControllerDatasetOptions` (the kind
  /// of `datasets.pie`, Chart.js ADR 0054 §3).
  static final DoughnutControllerDatasetOptionsScope defaults =
      DoughnutControllerDatasetOptionsScope()
        // The percentage of the chart that we cut out of the middle.
        // DIVERGES(chartjs): adapt-length-objects, the length classes.
        ..cutout = const PixelRadius(0)
        // The rotation of the chart, where the first data arc begins.
        ..rotation = 0.0
        // The total circumference of the chart.
        ..circumference = 360.0
        // The outer radius of the chart
        ..radius = const PercentRadius(100);

  /// The class as a typed component (Chart.js ADR 0204): the statics
  /// `id`, `defaults`, `overrides`, `descriptors`, and the constructor.
  static final ControllerType component = ControllerType(
    id: id,
    defaults: defaults,
    overrides: DoughnutController.overrides,
    descriptors: DoughnutController.descriptors,
    parent: DoughnutController.component,
    create: PieController.new,
  );
}
