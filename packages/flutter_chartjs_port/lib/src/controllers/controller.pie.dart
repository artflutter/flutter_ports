// Ported from Chart.js v4.5.1+7169e651 src/controllers/controller.pie.js (MIT, Chart.js Contributors).

/// Port of `src/controllers/controller.pie.js`.
///
/// [PieController] is the dataset controller of the `pie` charts. It is a
/// [DoughnutController] with other `defaults`: the methods, the
/// `descriptors` and the `overrides` come from the doughnut controller.
///
/// - The class value [PieController.jsClass] extends
///   [DoughnutController.jsClass] (Chart.js ADR 0020, section 3). Its own
///   statics are `id` and `defaults`, as in the upstream class body. A read
///   of `descriptors` or `overrides` on the class value follows the
///   superclass chain and gives the doughnut objects, as the static
///   prototype chain of JS does. Thus the legend functions of
///   `overrides['pie']` are the doughnut functions. This file does not copy
///   them (Chart.js ADR 0028, section 6).
/// - Dart does not inherit static members. Thus `PieController.overrides`
///   and `PieController.descriptors` do not exist in Dart: read
///   `PieController.jsClass['overrides']` and
///   `PieController.jsClass['descriptors']`.
/// - The registry registers the parent class first
///   (core.typedRegistry.js:28-31). The defaults of the scope
///   `datasets.pie` are the merge of the doughnut defaults and of
///   [PieController.defaults] (core.typedRegistry.js:84-92).
///
/// This library imports `controller.doughnut.dart`, which imports
/// `core.datasetController.dart`. Thus it is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/controllers/controller.doughnut.dart'
    show DoughnutController;
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show controllerArgs;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// controller.pie.js:4 `PieController extends DoughnutController`.
///
/// Pie charts are Doughnut chart with different defaults
class PieController extends DoughnutController {
  /// The default constructor of the JS class: `constructor(...args) {
  /// super(...args); }` (controller.pie.js:4 has no constructor).
  ///
  /// [newTarget] is `new.target` (Chart.js ADR 0020, section 4).
  PieController(super.chart, super.datasetIndex, [super.newTarget]);

  /// controller.pie.js:6 `static id = 'pie'`.
  static const String id = 'pie';

  /// controller.pie.js:11 `static defaults`.
  ///
  /// @type {any}
  static final AnyObject defaults = {
    // The percentage of the chart that we cut out of the middle.
    'cutout': 0.0,

    // The rotation of the chart, where the first data arc begins.
    'rotation': 0.0,

    // The total circumference of the chart.
    'circumference': 360.0,

    // The outer radius of the chart
    'radius': '100%',
  };

  /// controller.pie.js:4 `class PieController extends DoughnutController`
  /// as a value (Chart.js ADR 0020, section 3).
  ///
  /// It extends [DoughnutController.jsClass]. Its own statics are `id`
  /// (`'pie'`) and [defaults], in the upstream order of declaration
  /// (:6-23). The statics `descriptors` and `overrides` come from the
  /// superclass. Its `construct` calls `PieController(chart, datasetIndex,
  /// newTarget)` with the arguments of [controllerArgs]: without it, the
  /// closure of the superclass constructs a [DoughnutController].
  static final JsClass jsClass = JsClass(
    'PieController',
    superclass: DoughnutController.jsClass,
    statics: {'id': id, 'defaults': defaults},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return PieController(chart, datasetIndex, newTarget);
    },
  );
}
