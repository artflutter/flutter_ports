// Ported from Chart.js v4.6.1 src/controllers/controller.doughnut.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-parsed, the typed data of Chart.js ADR 0054.

/// Port of `src/controllers/controller.doughnut.js`.
///
/// [DoughnutController] is the dataset controller of the `doughnut` charts.
/// It parses one number for each data item, computes the rings of the
/// visible datasets in the chart area, and writes the properties of each
/// `ArcElement` through `updateElement`. `controller.pie.js` extends it.
///
/// - A parsed item and a data item are any value (Chart.js ADR 0036). A read
///   with a number index is [jsGetIndex], and the write `meta._parsed[i] =`
///   is [jsSetIndex]. The parsed items stay the upstream numbers (Chart.js
///   ADR 0054 §8). The one cast of a data value is the `data` List of
///   [DoughnutController.parse] (Chart.js ADR 0036, section 5 item 4).
/// - The dataset, chart and legend options and the [ElementOptions] of an
///   arc read typed ([OptionView.readKey], [readOption]). The data object
///   and the dataset objects of the user read by name. The properties of an
///   arc are an [ArcProperties] (Chart.js ADR 0054 §9). The exact controller in
///   a direct mode writes a built-in arc with its typed setters, with no object
///   (row `adapt-direct-element-writes`, Chart.js ADR 0102).
/// - A raw option value stays `Object?` until its upstream operator. Then
///   the port applies the runtime form of that operator: [jsToNumber],
///   [jsTruthy], [jsOrZero] before `Math.max`, or [jsAdd] (Chart.js ADR
///   0036, section 7).
/// - The controller reads the members of other modules through
///   `lib/src/types/` and imports no concrete scale, element or chart
///   module. The one cast to a class is `controller as DoughnutController`
///   in `_getRotationExtents` (Chart.js ADR 0028, section 1).
/// - The static `overrides` hold the tear-offs of the legend functions
///   `_generateLabels` and `_onClick` (Chart.js ADR 0028, section 6). The
///   legend plugin calls them.
/// - [DoughnutController.jsClass] is the class as a value with the statics
///   `id`, `defaults`, `descriptors` and `overrides` (Chart.js ADR 0020,
///   section 3).
/// - `getDataVisibility` stays an upstream call for each arc (Chart.js ADR
///   0036, section 8).
///
/// This library imports `core.datasetController.dart`, which imports
/// `core.animations.dart`. Thus it is not a pure layer.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/core/arc_option_preparation.dart'
    show prepareNativeArcColors;
import 'package:flutter_chartjs_port/src/core/arc_options.dart'
    show nativeArcClass, nativeArcElement;
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController, controllerArgs, presizeParsedNumbers;
import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show Defaults;
import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show DataUpdateShape, nativeDataUpdateList;
import 'package:flutter_chartjs_port/src/core/point_options.dart'
    show nativePointChart, nativePointList;
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show ArcOptions, ElementOptions;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show OptionView, readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isObject, resolveObjectKey, valueOrDefault;
import 'package:flutter_chartjs_port/src/helpers/helpers.intl.dart'
    show formatNumber, localeOf;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show angleBetween, halfPi, pi, tau, toRadians;
import 'package:flutter_chartjs_port/src/helpers/radius_length.dart'
    show PercentRadius, PixelRadius, RadiusLength;
import 'package:flutter_chartjs_port/src/js/js_array.dart'
    show JsStringList, jsSetIndex;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsMin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsGetIndex;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/options/props.dart' show ArcProperties;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        AnimationOptionsScope,
        AnimationsSpecScope,
        ChartOptionsScope,
        DescriptorsScope,
        DoughnutControllerDatasetOptionsScope,
        LegendLabelOptionsScope,
        LegendOptionsScope,
        PluginOptionsByTypeScope;
import 'package:flutter_chartjs_port/src/types/arc_option_enums.dart'
    show ArcBorderAlign, ArcSpacingMode;
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// controller.doughnut.js:34 the object `{ratioX, ratioY, offsetX,
/// offsetY}` of `getRatioAndOffset` (Chart.js ADR 0003).
typedef _RatioAndOffset = ({
  double ratioX,
  double ratioY,
  double offsetX,
  double offsetY,
});

/// controller.doughnut.js:10 `getRatioAndOffset(rotation, circumference,
/// cutout)`.
_RatioAndOffset _getRatioAndOffset(
  double rotation,
  double circumference,
  double cutout,
) {
  var ratioX = 1.0;
  var ratioY = 1.0;
  var offsetX = 0.0;
  var offsetY = 0.0;
  // If the chart's circumference isn't a full circle, calculate size as a
  // ratio of the width/height of the arc
  if (circumference < tau) {
    final startAngle = rotation;
    final endAngle = startAngle + circumference;
    final startX = math.cos(startAngle);
    final startY = math.sin(startAngle);
    final endX = math.cos(endAngle);
    final endY = math.sin(endAngle);
    // `Math.max(a, a * cutout, b, b * cutout)` and `Math.min(...)`.
    double calcMax(double angle, double a, double b) =>
        angleBetween(angle, startAngle, endAngle, true)
        ? 1
        : jsMax(jsMax(jsMax(a, a * cutout), b), b * cutout);
    double calcMin(double angle, double a, double b) =>
        angleBetween(angle, startAngle, endAngle, true)
        ? -1
        : jsMin(jsMin(jsMin(a, a * cutout), b), b * cutout);
    final maxX = calcMax(0, startX, endX);
    final maxY = calcMax(halfPi, startY, endY);
    final minX = calcMin(pi, startX, endX);
    final minY = calcMin(pi + halfPi, startY, endY);
    ratioX = (maxX - minX) / 2;
    ratioY = (maxY - minY) / 2;
    offsetX = -(maxX + minX) / 2;
    offsetY = -(maxY + minY) / 2;
  }
  return (ratioX: ratioX, ratioY: ratioY, offsetX: offsetX, offsetY: offsetY);
}

/// `value.length` of a value of the data object of the user: the length of
/// a List or a String, else the read by name.
Object? _lengthOf(Object? value) => switch (value) {
  final List<Object?> list => list.length.toDouble(),
  final String string => string.length.toDouble(),
  _ => jsGet(value, 'length'),
};

/// controller.doughnut.js:37 `DoughnutController extends DatasetController`.
class DoughnutController extends DatasetController {
  /// controller.doughnut.js:133 `constructor(chart, datasetIndex)`.
  ///
  /// [newTarget] is `new.target` (Chart.js ADR 0020, section 4). The body
  /// runs after the constructor of [DatasetController], as the statements
  /// after `super(chart, datasetIndex)` do.
  DoughnutController(super.chart, super.datasetIndex, [super.newTarget]) {
    enableOptionSharing = true;
    innerRadius = null;
    outerRadius = null;
    offsetX = null;
    offsetY = null;
  }

  /// Native support for the explicit data-only lifecycle.
  @override
  // DIVERGES(chartjs): adapt-incremental-data-update, native opt-in.
  bool get supportsDataUpdates => super.runtimeType == DoughnutController;

  /// The generator of [overrides] for the exact doughnut and pie classes:
  /// [supportsDataUpdates] is the exact class test of both.
  @override
  // DIVERGES(chartjs): adapt-hidden-legend-items, the built-in generator.
  Object? get nativeLegendGenerator =>
      supportsDataUpdates ? _generateLabels : null;

  /// `const {labels: {...}} = chart.legend.options` of [_generateLabels].
  @override
  // DIVERGES(chartjs): adapt-hidden-legend-items, the reads of the generator.
  List<OptionKey> get nativeLegendLabelKeys => const [
    OptionKey.pointStyle,
    OptionKey.textAlign,
    OptionKey.color,
    OptionKey.useBorderRadius,
    OptionKey.borderRadius,
  ];

  @override
  DataUpdateShape get dataUpdateShape => DataUpdateShape.scalar;

  /// controller.doughnut.js:39 `static id = 'doughnut'`.

  static const String id = 'doughnut';

  /// controller.doughnut.js:44 `static defaults`, a typed scope of the kind
  /// `DoughnutControllerDatasetOptions` (Chart.js ADR 0054 §3).
  static final DoughnutControllerDatasetOptionsScope defaults =
      DoughnutControllerDatasetOptionsScope()
        ..datasetElementType = false
        ..dataElementType = 'arc'
        ..animation = (AnimationOptionsScope()
          // Boolean - Whether we animate the rotation of the Doughnut
          ..animateRotate = true
          // Boolean - Whether we animate scaling the Doughnut from the centre
          ..animateScale = false)
        ..animations = (AnimationsSpecScope()
          ..numbers = (AnimationOptionsScope()
            ..type = 'number'
            ..properties = <String>[
              'circumference',
              'endAngle',
              'innerRadius',
              'outerRadius',
              'startAngle',
              'x',
              'y',
              'offset',
              'borderWidth',
              'spacing',
            ]))
        // The percentage of the chart that we cut out of the middle.
        // DIVERGES(chartjs): adapt-length-objects, the length class.
        ..cutout = const PercentRadius(50)
        // The rotation of the chart, where the first data arc begins.
        ..rotation = 0.0
        // The total circumference of the chart.
        ..circumference = 360.0
        // The outer radius of the chart
        ..radius = const PercentRadius(100)
        // Spacing between arcs
        ..spacing = 0.0
        // Geometry used to apply spacing between arcs
        // DIVERGES(chartjs): adapt-arc-option-enums, the enum value.
        ..spacingMode = ArcSpacingMode.angular
        // DIVERGES(chartjs): adapt-axis-objects, the axis class.
        ..indexAxis = const RAxis();

  /// controller.doughnut.js:80 `static descriptors`, in the form of
  /// `core.defaults.dart` (Chart.js ADR 0028, section 6): a typed scope of
  /// the kind `Descriptors` (Chart.js ADR 0054 §3).
  // DIVERGES(chartjs): adapt-arc-native-options, predicates by identity.
  static final DescriptorsScope descriptors = DescriptorsScope()
    ..descScriptable = Defaults.nativeElementPredicate(_scriptableDescriptor)
    ..descIndexable = Defaults.nativeElementPredicate(_indexableDescriptor);

  /// controller.doughnut.js:81 the `_scriptable` descriptor.
  static bool _scriptableDescriptor(String name) =>
      name != 'spacing' && name != 'spacingMode';

  /// controller.doughnut.js:82 the `_indexable` descriptor.
  static bool _indexableDescriptor(String name) =>
      name != 'spacing' &&
      name != 'spacingMode' &&
      !name.startsWith('borderDash') &&
      !name.startsWith('hoverBorderDash');

  /// controller.doughnut.js:88 `static overrides`, a typed scope of the
  /// kind `ChartOptions` (Chart.js ADR 0054 §3).
  ///
  /// The legend functions are the tear-offs of the top-level functions
  /// [_generateLabels] and [_onClick]: each read gives the same function
  /// (Chart.js ADR 0028, section 6).
  static final ChartOptionsScope overrides = ChartOptionsScope()
    ..aspectRatio = 1.0
    // Need to override these to give a nice default
    ..plugins = (PluginOptionsByTypeScope()
      ..legend = (LegendOptionsScope()
        ..labels = (LegendLabelOptionsScope()..generateLabels = _generateLabels)
        ..onClick = _onClick));

  /// controller.doughnut.js:37 `class DoughnutController extends
  /// DatasetController` as a value (Chart.js ADR 0020, section 3).
  ///
  /// It extends [DatasetController.jsClass]. Its statics are `id`
  /// (`'doughnut'`), [defaults], [descriptors] and [overrides], in the
  /// upstream order of declaration (:39-131). Its `construct` calls
  /// `DoughnutController(chart, datasetIndex, newTarget)` with the arguments
  /// of [controllerArgs].
  static final JsClass jsClass = JsClass(
    'DoughnutController',
    superclass: DatasetController.jsClass,
    statics: {
      'id': id,
      'defaults': defaults,
      'descriptors': descriptors,
      'overrides': overrides,
    },
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return DoughnutController(chart, datasetIndex, newTarget);
    },
  );

  /// controller.doughnut.js:137 `innerRadius`. Dart `null` stands for the
  /// JS `undefined` of the constructor. [update] writes a number.
  double? innerRadius;

  /// controller.doughnut.js:138 `outerRadius`. Dart `null` stands for the
  /// JS `undefined` of the constructor. [update] writes a number.
  double? outerRadius;

  /// controller.doughnut.js:139 `offsetX`. Dart `null` stands for the JS
  /// `undefined` of the constructor. [update] writes a number.
  double? offsetX;

  /// controller.doughnut.js:140 `offsetY`. Dart `null` stands for the JS
  /// `undefined` of the constructor. [update] writes a number.
  double? offsetY;

  /// Whether [update] runs [getMaxBorderWidth] and [getMaxOffset] now, in the
  /// mode `none`. Dart `false` for a call of user code (Chart.js ADR 0093).
  // DIVERGES(chartjs): adapt-arc-native-options, state of one update.
  bool _scansMayStop = false;

  /// The one read of the circumference of a loop in which no user code runs,
  /// or Dart `null` for the read at each call of [_circumference].
  // DIVERGES(chartjs): adapt-arc-native-options, state of one loop.
  double? _loopCircumference;

  /// controller.doughnut.js:143 `linkScales() {}`.
  @override
  void linkScales() {}

  /// controller.doughnut.js:148 `parse(start, count)`.
  ///
  /// Override data parsing, since we are not using scales
  ///
  /// `data` is a List or a String after `_dataCheck` of the port: a falsy
  /// `data` is `[]` (core.datasetController.js:367), and object data throws
  /// at `meta.iScale!` of `_convertObjectDataToArray` in
  /// core.datasetController.dart, as upstream throws at
  /// core.datasetController.js:104. `_dataCheck` keeps a string `data`
  /// (core.datasetController.js:386), and this function reads its
  /// characters with [jsGetIndex]. Any other truthy `data` throws the
  /// [TypeError] of the cast in `_dataCheck`. Thus the cast here cannot fail
  /// in the port (Chart.js ADR 0036, section 5 item 4). With parsing
  /// `false`, `meta._parsed = data` gives a string the [JsStringList] of its
  /// characters: the parsed items are a List in the port.
  ///
  /// The default `key = 'value'` of the destructuring is [valueOrDefault]:
  /// only `undefined` gives it. The key goes to `resolveObjectKey` with the
  /// cast `as String` (Chart.js ADR 0036, section 4): a key that is not a
  /// string throws a [TypeError] at the first item.
  @override
  void parse(double start, double count) {
    // `this._cachedMeta`'s dataset: the dataset object of the user.
    final data = jsGet(getDataset(), 'data');
    final meta = cachedMeta;

    if (parsing == false) {
      // The same List: `meta._parsed === dataset.data`. A string gives the
      // List of its characters.
      meta.parsed = data is String
          ? JsStringList(data)
          : data! as List<Object?>;
    } else {
      var getter = (double i) => jsToNumber(jsGetIndex(data, i));

      if (isObject(jsGetIndex(data, start))) {
        final key = valueOrDefault(readOption(parsing, OptionKey.key), 'value');
        getter = (i) =>
            jsToNumber(resolveObjectKey(jsGetIndex(data, i), key! as String));
      }

      // DIVERGES(chartjs): adapt-parse-presize, one growth for numbers.
      presizeParsedNumbers(meta.parsed, data, start, count);
      for (var i = start, ilen = start + count; i < ilen; ++i) {
        jsSetIndex<Object?>(meta.parsed, i.toInt(), getter(i));
      }
    }
  }

  /// controller.doughnut.js:172 `_getRotation()`.
  /// @private
  ///
  /// `this.options.rotation - 90` applies `ToNumber` to the raw option.
  double _getRotation() {
    return toRadians(jsToNumber(options.readKey(OptionKey.rotation)) - 90);
  }

  /// controller.doughnut.js:179 `_getCircumference()`.
  /// @private
  ///
  /// `toRadians` multiplies the raw option: `ToNumber`.
  double _getCircumference() {
    return toRadians(jsToNumber(options.readKey(OptionKey.circumference)));
  }

  /// controller.doughnut.js:187 `_getRotationExtents()`.
  ///
  /// Get the maximal rotation & circumference extents
  /// across all visible datasets.
  ///
  /// The result is a record of the object `{rotation, circumference}`.
  /// `_getRotation` and `_getCircumference` are private members of this
  /// library. Thus the controller of another dataset of the same type is
  /// cast to [DoughnutController] (Chart.js ADR 0028, section 1). A pie
  /// controller is a [DoughnutController].
  ({double rotation, double circumference}) _getRotationExtents() {
    var min = tau;
    var max = -tau;

    for (var i = 0.0; i < _datasetCount(); ++i) {
      if (chart.isDatasetVisible(i) && chart.getDatasetMeta(i).type == type) {
        final controller =
            chart.getDatasetMeta(i).controller! as DoughnutController;
        final rotation = controller._getRotation();
        final circumference = controller._getCircumference();

        min = jsMin(min, rotation);
        max = jsMax(max, rotation + circumference);
      }
    }

    return (rotation: min, circumference: max - min);
  }

  /// `this.chart.data.datasets.length`, read again at each call as the loop
  /// conditions of upstream read it. The data object of the user.
  double _datasetCount() =>
      jsToNumber(_lengthOf(jsGet(chart.data, 'datasets')));

  /// controller.doughnut.js:211 `update(mode)`.
  ///
  /// @param {string} mode
  ///
  /// `getMaxBorderWidth() + getMaxOffset(arcs) + this.options.spacing` is
  /// [jsAdd]: a string option joins. Each later use applies `ToNumber` to
  /// the sum.
  @override
  void update(String mode) {
    final chart = this.chart;
    // `const {chartArea} = chart`: the chart area exists after the layout of
    // the chart, before the update of the datasets.
    final chartArea = chart.chartArea!;
    final meta = cachedMeta;
    final arcs = meta.data;
    // DIVERGES(chartjs): adapt-arc-native-options, the scans of this update in
    // the mode `none` may leave contexts that `updateElements` writes again.
    final double scans;
    _scansMayStop = mode == 'none';
    try {
      scans = getMaxBorderWidth() + getMaxOffset(arcs);
    } finally {
      _scansMayStop = false;
    }
    final spacing = jsAdd(scans, options.readKey(OptionKey.spacing));
    final maxSize = jsMax(
      (jsMin(chartArea.width, chartArea.height) - jsToNumber(spacing)) / 2,
      0,
    );
    // DIVERGES(chartjs): adapt-length-objects, the length computes itself.
    final cutout = jsMin(
      _radiusLength(options.readKey(OptionKey.cutout)).fractionOf(maxSize),
      1,
    );
    final chartWeight = _getRingWeight(index);

    // Compute the maximal rotation & circumference limits.
    // If we only consider our dataset, this can cause problems when two
    // datasets are both less than a circle with different rotations
    // (starting angles)
    final (:circumference, :rotation) = _getRotationExtents();
    final (:ratioX, :ratioY, :offsetX, :offsetY) = _getRatioAndOffset(
      rotation,
      circumference,
      cutout,
    );
    final maxWidth = (chartArea.width - jsToNumber(spacing)) / ratioX;
    final maxHeight = (chartArea.height - jsToNumber(spacing)) / ratioY;
    final maxRadius = jsMax(jsMin(maxWidth, maxHeight) / 2, 0);
    // DIVERGES(chartjs): adapt-length-objects, the length computes itself.
    final outerRadius = _radiusLength(
      options.readKey(OptionKey.radius),
    ).pixelsOf(maxRadius);
    final innerRadius = jsMax(outerRadius * cutout, 0);
    final radiusLength =
        (outerRadius - innerRadius) / _getVisibleDatasetWeightTotal();
    this.offsetX = offsetX * outerRadius;
    this.offsetY = offsetY * outerRadius;

    meta.total = calculateTotal();

    this.outerRadius = outerRadius - radiusLength * _getRingWeightOffset(index);
    this.innerRadius = jsMax(
      this.outerRadius! - radiusLength * chartWeight,
      0,
    );

    updateElements(arcs, 0, arcs.length.toDouble(), mode);
  }

  /// controller.doughnut.js:246 `_circumference(i, reset)`.
  /// @private
  ///
  /// `meta._parsed[i] === null` is Dart `== null`: the [undefined] sentinel
  /// is not `null`. `meta._parsed[i] * circumference` applies `ToNumber`.
  double _circumference(double i, bool reset) {
    final opts = options;
    final meta = cachedMeta;
    // DIVERGES(chartjs): adapt-arc-native-options, one read for a native loop.
    final circumference = _loopCircumference ?? _getCircumference();
    if ((reset &&
            jsTruthy(
              readOption(
                opts.readKey(OptionKey.animation),
                OptionKey.animateRotate,
              ),
            )) ||
        !chart.getDataVisibility(i) ||
        jsGetIndex(meta.parsed, i) == null ||
        jsTruthy(meta.data[i.toInt()].hidden)) {
      return 0;
    }
    return calculateCircumference(
      jsToNumber(jsGetIndex(meta.parsed, i)) * circumference / tau,
    );
  }

  /// controller.doughnut.js:256 `updateElements(arcs, start, count, mode)`.
  ///
  /// `reset && animationOpts.animateScale` reads the option only in the
  /// mode `'reset'`. `this.innerRadius` and `this.outerRadius` are Dart
  /// `null` for JS `undefined` before the first [update]: the property gets
  /// [undefined], and `centerX + this.offsetX` is NaN.
  @override
  void updateElements(
    List<types.Element> arcs,
    double start,
    double count,
    String mode,
  ) {
    final reset = mode == 'reset';
    final chart = this.chart;
    final chartArea = chart.chartArea!;
    final opts = chart.options;
    final animationOpts = readOption(opts, OptionKey.animation);
    final centerX = (chartArea.left + chartArea.right) / 2;
    final centerY = (chartArea.top + chartArea.bottom) / 2;
    final animateScale =
        reset && jsTruthy(readOption(animationOpts, OptionKey.animateScale));
    // Dart `null` is the `undefined` of the radius before the first update.
    final innerRadius = animateScale ? 0.0 : this.innerRadius;
    final outerRadius = animateScale ? 0.0 : this.outerRadius;
    final (:sharedOptions, :includeOptions) = getSharedOptions_(start, mode);
    var startAngle = _getRotation();
    double i;
    // DIVERGES(chartjs): adapt-direct-element-writes, `updateElement` of the
    // exact controller only assigns in these modes, with its options.
    final direct = supportsDataUpdates && (reset || mode == 'none');

    _loopCircumference = null;
    for (i = 0; i < start; ++i) {
      startAngle += _circumference(i, reset);
    }

    // DIVERGES(chartjs): adapt-arc-native-options, plans of this synchronous
    // loop only. No user code runs while one holds, and a custom or active arc
    // ends them for good before its first read.
    var nativeLoop = start == 0 && _nativeArcLoop(arcs, mode);
    ArcOptions Function(int)? colors;
    final tryColors =
        nativeLoop &&
        includeOptions &&
        sharedOptions == null &&
        count > 2 &&
        cachedDataElementOptions(mode) == null;
    _loopCircumference = nativeLoop && sharedOptions != null && count > 0
        ? _getCircumference()
        : null;

    for (i = start; i < start + count; ++i) {
      if (nativeLoop) {
        final next = arcs[i.toInt()];
        if (!nativeArcElement(next) || (colors != null && next.active)) {
          nativeLoop = false;
          colors = null;
          _loopCircumference = null;
        }
      }
      final circumference = _circumference(i, reset);
      final arc = arcs[i.toInt()];
      // The literal of :278-286, in locals: the options run user code after it.
      final x = centerX + (offsetX ?? double.nan);
      final y = centerY + (offsetY ?? double.nan);
      final arcStart = startAngle;
      final arcEnd = startAngle + circumference;
      ElementOptions? elementOptions;
      if (includeOptions) {
        // DIVERGES(chartjs): adapt-arc-native-options, the context refresh and
        // a fresh copy of the template, as the resolve of this plan gives.
        final prepared = colors;
        if (prepared != null) {
          getContext(i, false, mode);
          elementOptions = prepared(i.toInt());
        } else {
          // `sharedOptions || ...`: Dart `null` is the JS `undefined` of no
          // shared options.
          elementOptions =
              sharedOptions ??
              resolveDataElementOptions(i, arc.active ? 'active' : mode);
        }
      }
      startAngle += circumference;

      // DIVERGES(chartjs): adapt-direct-element-writes, the assign of the
      // literal with no object: the writes stay after the resolve above.
      if (arc case final types.ArcElementWrites target
          when direct &&
              outerRadius != null &&
              innerRadius != null &&
              elementOptions != null &&
              target.typedWrites) {
        target
          ..x = x
          ..y = y
          ..startAngle = arcStart
          ..endAngle = arcEnd
          ..circumference = circumference
          ..outerRadius = outerRadius
          ..innerRadius = innerRadius
          ..options = elementOptions;
      } else {
        final properties = ArcProperties()
          ..x = x
          ..y = y
          ..startAngle = arcStart
          ..endAngle = arcEnd
          ..circumference = circumference;
        if (outerRadius == null) {
          properties.jsWrite('outerRadius', undefined);
        } else {
          properties.outerRadius = outerRadius;
        }
        if (innerRadius == null) {
          properties.jsWrite('innerRadius', undefined);
        } else {
          properties.innerRadius = innerRadius;
        }
        if (elementOptions != null) properties.options = elementOptions;

        updateElement(arc, i, properties, mode);
      }

      // Two ordinary resolutions warm the cached plan. One attempt.
      if (tryColors && nativeLoop && i == start + 1) {
        colors = prepareNativeArcColors(this, arcs);
        if (colors != null) _loopCircumference = _getCircumference();
      }
    }
    _loopCircumference = null;
  }

  /// The reads of an arc loop in the mode `none` run no user code: the exact
  /// controller and chart, native arrays, and parsed numbers. The arcs stay a
  /// live check at their own iteration.
  // DIVERGES(chartjs): adapt-arc-native-options, the guard of the native loops.
  bool _nativeArcLoop(List<types.Element> arcs, String mode) =>
      mode == 'none' &&
      supportsDataUpdates &&
      nativePointChart(chart) &&
      identical(arcs, cachedMeta.data) &&
      nativePointList(arcs) &&
      nativeDataUpdateList(cachedMeta.parsed) &&
      parsing != false;

  /// The dataset options that [update] reads between its scans and the arcs.
  static const List<OptionKey> _updateOptions = [
    OptionKey.spacing,
    OptionKey.cutout,
    OptionKey.rotation,
    OptionKey.circumference,
    OptionKey.radius,
  ];

  /// Whether a scan can end after the result [options] of [controller]: each
  /// later call has no other effect on the scan. The caller asks for the first
  /// two items only.
  ///
  /// - A frozen cached entry: each later call is a hit that gives this object.
  ///   A hit runs no user code and changes nothing, so `Math.max` of the same
  ///   inputs gives the same number. This holds for any exact controller.
  /// - A plan where only native colors vary: each later call differs from this
  ///   one in the colors, which no scan reads, and in the refresh of the
  ///   context of its arc. The update stops that refresh only for its own
  ///   arcs, in the mode `none`, when `updateElements` writes each of these
  ///   contexts again with no user code before it. An active arc breaks that:
  ///   its resolve can write no context, can run a hover callback and can
  ///   throw, so each scan keeps its refresh.
  // DIVERGES(chartjs): adapt-arc-native-options, the result that must repeat.
  bool _scanRepeats(Object? controller, Object options) {
    if (options is! ElementOptions ||
        controller is! DoughnutController ||
        !controller.supportsDataUpdates ||
        !nativeArcClass(controller.dataElementType)) {
      return false;
    }
    if (controller.isCachedElementOptions(options)) return true;
    if (!_scansMayStop || !identical(controller, this)) return false;
    final arcs = cachedMeta.data;
    return _nativeArcLoop(arcs, 'none') &&
        prepareNativeArcColors(this, arcs) != null &&
        // The rings read each other dataset and its controller.
        _datasetCount() == 1 &&
        this.options.rawOptionsAreScalar(_updateOptions) &&
        arcs.every((arc) => nativeArcElement(arc) && !arc.active);
  }

  /// controller.doughnut.js:296 `calculateTotal()`.
  ///
  /// `Math.abs(value)` applies `ToNumber`: the total is a number.
  double calculateTotal() {
    final meta = cachedMeta;
    final metaData = meta.data;
    var total = 0.0;
    int i;

    for (i = 0; i < metaData.length; i++) {
      final value = jsGetIndex(meta.parsed, i * 1.0);
      if (value != null &&
          !jsIsNaN(value) &&
          chart.getDataVisibility(i * 1.0) &&
          !jsTruthy(metaData[i].hidden)) {
        total += jsToNumber(value).abs();
      }
    }

    return total;
  }

  /// controller.doughnut.js:312 `calculateCircumference(value)`.
  ///
  /// Dart `null` for `meta.total` is the JS `undefined` of `total > 0`:
  /// false.
  double calculateCircumference(double value) {
    final total = cachedMeta.total;
    if (total != null && total > 0 && !value.isNaN) {
      return tau * (value.abs() / total);
    }
    return 0;
  }

  /// controller.doughnut.js:320 `getLabelAndValue(index)`.
  ///
  /// The label is `labels[index] || ''`: any value (Chart.js ADR 0028,
  /// section 2). `formatNumber` applies `ToNumber` to the parsed item.
  @override
  ({Object? label, String value}) getLabelAndValue(double index) {
    final meta = cachedMeta;
    final chart = this.chart;
    // `chart.data.labels || []`
    final labelsValue = jsGet(chart.data, 'labels');
    final labels = jsTruthy(labelsValue) ? labelsValue : const <Object?>[];
    final value = formatNumber(
      jsToNumber(jsGetIndex(meta.parsed, index)),
      localeOf(readOption(chart.options, OptionKey.locale)),
    );

    // `labels[index] || ''`
    final label = jsGetIndex(labels, index);
    return (label: jsTruthy(label) ? label : '', value: value);
  }

  /// controller.doughnut.js:332 `getMaxBorderWidth(arcs)`.
  ///
  /// Without [arcs], the arcs and the controller are those of the first
  /// visible dataset. With [arcs], `controller` stays `undefined`, and the
  /// first arc throws a [TypeError] at `controller.resolveDataElementOptions`,
  /// as upstream. `options.borderWidth || 0` in `Math.max` is [jsOrZero].
  double getMaxBorderWidth([List<types.Element>? arcs]) {
    var max = 0.0;
    final chart = this.chart;
    types.DatasetController? controller;

    if (arcs == null) {
      // Find the outmost visible dataset
      for (var i = 0.0, ilen = _datasetCount(); i < ilen; ++i) {
        if (chart.isDatasetVisible(i)) {
          final meta = chart.getDatasetMeta(i);
          // `arcs = meta.data`: the upstream write of the parameter.
          // ignore: parameter_assignments
          arcs = meta.data;
          controller = meta.controller;
          break;
        }
      }
    }

    if (arcs == null) {
      return 0;
    }

    for (var i = 0.0, ilen = arcs.length.toDouble(); i < ilen; ++i) {
      final options = controller!.resolveDataElementOptions(i);
      // DIVERGES(chartjs): adapt-arc-option-enums, the enum value.
      if (ArcBorderAlign.of(readOption(options, OptionKey.borderAlign)) !=
          ArcBorderAlign.inner) {
        max = jsMax(
          jsMax(max, jsOrZero(readOption(options, OptionKey.borderWidth))),
          jsOrZero(readOption(options, OptionKey.hoverBorderWidth)),
        );
      }
      // DIVERGES(chartjs): adapt-arc-native-options, the rest must repeat.
      if (i <= 1 && _scanRepeats(controller, options)) break;
    }
    return max;
  }

  /// controller.doughnut.js:362 `getMaxOffset(arcs)`.
  ///
  /// `options.offset || 0` in `Math.max` is [jsOrZero] of the raw value
  /// ([ElementOptions.valueOf]).
  double getMaxOffset(List<types.Element> arcs) {
    var max = 0.0;

    for (var i = 0.0, ilen = arcs.length.toDouble(); i < ilen; ++i) {
      final options = resolveDataElementOptions(i);
      max = jsMax(
        jsMax(max, jsOrZero(options.valueOf(OptionKey.offset))),
        jsOrZero(options.valueOf(OptionKey.hoverOffset)),
      );
      // DIVERGES(chartjs): adapt-arc-native-options, the rest must repeat.
      if (i <= 1 && _scanRepeats(this, options)) break;
    }
    return max;
  }

  /// controller.doughnut.js:376 `_getRingWeightOffset(datasetIndex)`.
  ///
  /// Get radius length offset of the dataset in relation to the visible
  /// datasets weights. This allows determining the inner and outer radius
  /// correctly
  /// @private
  double _getRingWeightOffset(double datasetIndex) {
    var ringWeightOffset = 0.0;

    for (var i = 0.0; i < datasetIndex; ++i) {
      if (chart.isDatasetVisible(i)) {
        ringWeightOffset += _getRingWeight(i);
      }
    }

    return ringWeightOffset;
  }

  /// controller.doughnut.js:391 `_getRingWeight(datasetIndex)`.
  /// @private
  ///
  /// `Math.max(valueOrDefault(weight, 1), 0)` applies `ToNumber` to the raw
  /// `weight`. An absent dataset throws a [TypeError], as the property read
  /// of `undefined` does.
  double _getRingWeight(double datasetIndex) {
    return jsMax(
      jsToNumber(
        valueOrDefault(
          // The dataset object of the user, in the data object of the user.
          jsGet(
            jsGetIndex(jsGet(chart.data, 'datasets'), datasetIndex),
            'weight',
          ),
          1.0,
        ),
      ),
      0,
    );
  }

  /// controller.doughnut.js:399 `_getVisibleDatasetWeightTotal()`.
  ///
  /// Returns the sum of all visible data set weights.
  /// @private
  ///
  /// `|| 1`: a total of 0 or NaN gives 1.
  double _getVisibleDatasetWeightTotal() {
    final total = _getRingWeightOffset(_datasetCount());
    return jsTruthy(total) ? total : 1;
  }
}

/// controller.doughnut.js:95 `generateLabels(chart)` of
/// `overrides.plugins.legend.labels` (Chart.js ADR 0028, section 6).
///
/// `const {labels: {pointStyle, textAlign, color, useBorderRadius,
/// borderRadius}} = chart.legend.options;` reads the keys in this order. A
/// Dart `null` legend throws a [TypeError], as `undefined.options` does. A
/// legend item is a Map with the keys in the order of the upstream literal.
List<Object?> _generateLabels(types.Chart chart) {
  final data = chart.data;
  final labelsOptions = readOption(chart.legend!.options, OptionKey.labels);
  final pointStyle = readOption(labelsOptions, OptionKey.pointStyle);
  final textAlign = readOption(labelsOptions, OptionKey.textAlign);
  final color = readOption(labelsOptions, OptionKey.color);
  final useBorderRadius = readOption(labelsOptions, OptionKey.useBorderRadius);
  final borderRadius = readOption(labelsOptions, OptionKey.borderRadius);
  // The data object of the user. Upstream reads `data.labels` twice: a read
  // of the data object has no side effect.
  final labelsValue = jsGet(data, 'labels');
  if (jsTruthy(_lengthOf(labelsValue)) &&
      jsTruthy(_lengthOf(jsGet(data, 'datasets')))) {
    // `data.labels.map(...)`: a value without `map` throws a TypeError, as
    // the cast does.
    final labels = labelsValue! as List<Object?>;
    return [
      for (final (i, label) in labels.indexed)
        _labelItem(
          chart,
          label,
          i.toDouble(),
          pointStyle,
          textAlign,
          color,
          useBorderRadius,
          borderRadius,
        ),
    ];
  }
  return <Object?>[];
}

/// The callback of `data.labels.map((label, i) => ...)`
/// (controller.doughnut.js:99-119), with the values that it reads from
/// `_generateLabels`.
///
/// Each style value is a raw read of the [ElementOptions] of the style
/// ([readOption]): an absent key gives [undefined], for example `lineJoin`
/// of the default `borderJoinStyle`. `index` is a number (Chart.js ADR
/// 0045). The legend item stays a Map: the legend plugin reads Map items.
Map<String, Object?> _labelItem(
  types.Chart chart,
  Object? label,
  double i,
  Object? pointStyle,
  Object? textAlign,
  Object? color,
  Object? useBorderRadius,
  Object? borderRadius,
) {
  final meta = chart.getDatasetMeta(0);
  final style = meta.controller!.getStyle(i);

  return <String, Object?>{
    'text': label,
    'fillStyle': readOption(style, OptionKey.backgroundColor),
    'fontColor': color,
    'hidden': !chart.getDataVisibility(i),
    'lineDash': readOption(style, OptionKey.borderDash),
    'lineDashOffset': readOption(style, OptionKey.borderDashOffset),
    'lineJoin': readOption(style, OptionKey.borderJoinStyle),
    'lineWidth': readOption(style, OptionKey.borderWidth),
    'strokeStyle': readOption(style, OptionKey.borderColor),
    'textAlign': textAlign,
    'pointStyle': pointStyle,
    // `useBorderRadius && (borderRadius || style.borderRadius)`
    'borderRadius': jsTruthy(useBorderRadius)
        ? (jsTruthy(borderRadius)
              ? borderRadius
              : readOption(style, OptionKey.borderRadius))
        : useBorderRadius,
    // Extra data used for toggling the correct item
    'index': i,
  };
}

/// controller.doughnut.js:125 `onClick(e, legendItem, legend)` of
/// `overrides.plugins.legend` (Chart.js ADR 0028, section 6).
///
/// `toggleDataVisibility(legendItem.index)` gives the raw item index to
/// `types.Chart.toggleDataVisibility`, which writes the property key
/// `ToString(index)` (core.controller.js:881-883), as upstream.
void _onClick(Object? e, Object? legendItem, types.LegendElement legend) {
  legend.chart.toggleDataVisibility(jsGet(legendItem, 'index'));
  legend.chart.update();
}

/// The length of the option value [value] (`cutout`, `radius`): the
/// [RadiusLength] itself. Upstream converts another value with the unary
/// `+` (helpers.core.ts:86-95): JS `null` gives 0, and another value NaN.
// DIVERGES(chartjs): adapt-length-objects, no text parse.
RadiusLength _radiusLength(Object? value) =>
    RadiusLength.of(value) ??
    (value == null ? const PixelRadius(0) : const PixelRadius(double.nan));
