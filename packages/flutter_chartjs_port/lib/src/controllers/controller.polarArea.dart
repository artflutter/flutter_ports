// Ported from Chart.js v4.6.1 src/controllers/controller.polarArea.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-parsed, the typed data of Chart.js ADR 0054.

/// Port of `src/controllers/controller.polarArea.js`.
///
/// [PolarAreaController] is the dataset controller of the `polarArea`
/// charts. It parses the value `r` of each item, gives each visible item an
/// angle, and writes the properties of each `ArcElement` through
/// `updateElement`. The radius of each arc comes from the radial linear
/// scale `r`.
///
/// - The parsed data is typed (Chart.js ADR 0054 §8): the read `parsed.r`
///   is [parsedValueOf], typed for a [ParsedItem]. A parsed item of
///   `parsing: false` is a data item of the user, read by name (Chart.js
///   ADR 0036). A read with a number index is [jsGetIndex]. The chart, the
///   dataset and the legend options and the [ArcOptions] of an element read
///   typed ([readOption]). The properties of an arc are an
///   [ArcProperties] (Chart.js ADR 0054 §9). The exact controller in a direct
///   mode writes a built-in arc with its typed setters, with no object (row
///   `adapt-direct-element-writes`, Chart.js ADR 0102).
/// - `getMinMax` keeps the raw parsed values of the range and compares them
///   with [jsLessThan], as upstream compares with `<` and `>` (Chart.js ADR
///   0036, section 7). Two string values compare as strings.
/// - The controller reads the members of other modules through
///   `lib/src/types/` and imports no concrete scale, element or chart
///   module (Chart.js ADR 0028, section 1). `updateElements` casts the scale
///   `r` to `types.RadialLinearScale` once, at the first read of a member
///   that only that type has (:167).
/// - `updateElements` ports the hunk of Chart.js #12238 (:204-210) line by
///   line: the Dart `==` is the `===` of upstream here (Chart.js ADR 0028,
///   section 5). The controller never sets `enableOptionSharing`.
/// - `overrides` holds the tear-offs of the two legend functions
///   `_generateLabels` and `_onClick` (Chart.js ADR 0028, section 6). The
///   legend plugin calls them.
/// - [PolarAreaController.jsClass] is the class as a value with the statics
///   `id`, `defaults` and `overrides` (Chart.js ADR 0020, section 3).
///
/// This library imports `core.datasetController.dart`, which imports
/// `core.animations.dart`. Thus it is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/arc_option_preparation.dart'
    show prepareNativeArcColors;
import 'package:flutter_chartjs_port/src/core/arc_options.dart'
    show nativeArcClass, nativeArcElement, nativeArcScale;
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController, controllerArgs, parsedValueOf;
import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show DataUpdateShape, nativeDataUpdateList;
import 'package:flutter_chartjs_port/src/core/legend_item_options.dart';
import 'package:flutter_chartjs_port/src/core/point_options.dart'
    show nativePointChart, nativePointList;
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show ArcOptions, ElementOptions;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show OptionView, parseObjectDataRadialScaleOf, readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.intl.dart'
    show formatNumber, localeOf;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show pi, toRadians;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsMin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsGetIndex;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/options/parsed.dart' show ParsedItem;
import 'package:flutter_chartjs_port/src/options/props.dart' show ArcProperties;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        AngleLineOptionsScope,
        AnimationOptionsScope,
        AnimationsSpecScope,
        ChartOptionsScope,
        GridLineOptionsScope,
        LegendLabelOptionsScope,
        LegendOptionsScope,
        PluginOptionsByTypeScope,
        PointLabelOptionsScope,
        PolarAreaControllerDatasetOptionsScope,
        ScaleOptionsByIdScope,
        ScaleOptionsScope;
import 'package:flutter_chartjs_port/src/types/arc_option_enums.dart'
    show ArcSpacingMode;
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/legend_item.dart';

/// controller.polarArea.js:38 `generateLabels(chart)` of
/// `overrides.plugins.legend.labels` (Chart.js ADR 0028, section 6).
///
/// The read of `chart.legend.options` is inside the test (:41). A Dart
/// `null` legend throws a [TypeError] there, as `undefined.options` does.
/// `data.labels.length` of an absent `labels` throws a [TypeError], as in
/// JavaScript. A `labels` value with a truthy `length` that is not a List
/// throws a [TypeError] at the cast, where upstream throws at `map`.
///
/// `chart.data` is the data object of the user: its reads go by name. The
/// legend options read typed ([readOption]).
// DIVERGES(chartjs): adapt-native-legend-item, native legend entries.
List<LegendItem> _generateLabels(types.Chart chart) {
  final data = chart.data;
  final labels = jsGet(data, 'labels');
  if (jsTruthy(_lengthOf(labels)) &&
      jsTruthy(_lengthOf(jsGet(data, 'datasets')))) {
    // `const {labels: {pointStyle, color}} = chart.legend.options;`
    final labelsOptions = readOption(chart.legend!.options, OptionKey.labels);
    final pointStyle = readOption(labelsOptions, OptionKey.pointStyle);
    final color = readOption(labelsOptions, OptionKey.color);

    return [
      for (final (i, label) in (labels! as List<Object?>).indexed)
        _item(chart, label, i.toDouble(), pointStyle, color),
    ];
  }
  return <LegendItem>[];
}

/// `value.length` of a value of the data object of the user: the length of
/// a List or a String, else the read by name.
Object? _lengthOf(Object? value) => switch (value) {
  final List<Object?> list => list.length.toDouble(),
  final String string => string.length.toDouble(),
  _ => jsGet(value, 'length'),
};

/// The callback of `data.labels.map` (controller.polarArea.js:43-59).
///
/// The fields follow the upstream literal. A key of `style` that is absent
/// gives `undefined`, as the JS property read does: the style is an
/// [ElementOptions], and [readOption] gives its raw value. `index` is a
/// `double` (Chart.js ADR 0045).
LegendItem _item(
  types.Chart chart,
  Object? label,
  double i,
  Object? pointStyle,
  Object? color,
) {
  final meta = chart.getDatasetMeta(0);
  final style = meta.controller!.getStyle(i);

  return legendItemFromOptions(
    text: label,
    fillStyle: readOption(style, OptionKey.backgroundColor),
    strokeStyle: readOption(style, OptionKey.borderColor),
    fontColor: color,
    lineWidth: readOption(style, OptionKey.borderWidth),
    pointStyle: pointStyle,
    hidden: !chart.getDataVisibility(i),

    // Extra data used for toggling the correct item
    index: i.toInt(),
  );
}

/// controller.polarArea.js:65 `onClick(e, legendItem, legend)` of
/// `overrides.plugins.legend` (Chart.js ADR 0028, section 6).
///
/// A native item identifies a data entry with an integer. A descriptive
/// item has no index and leaves visibility unchanged.
void _onClick(Object? e, LegendItem legendItem, types.LegendElement legend) {
  final index = legendItem.index;
  if (index == null) return;
  legend.chart.toggleDataVisibility(index);
  legend.chart.update();
}

/// controller.polarArea.js:4 `PolarAreaController extends
/// DatasetController`.
class PolarAreaController(super.chart, super.datasetIndex, [super.newTarget])
    extends DatasetController {
  /// controller.polarArea.js:90 `constructor(chart, datasetIndex)`.
  ///
  /// `newTarget` is `new.target` (Chart.js ADR 0020, section 4). The fields
  /// [innerRadius] and [outerRadius] start as Dart `null`, the `undefined`
  /// of :93-94.
  this;

  /// Native support for the explicit data-only lifecycle.
  @override
  // DIVERGES(chartjs): adapt-incremental-data-update, native opt-in.
  bool get supportsDataUpdates => super.runtimeType == PolarAreaController;

  /// The generator of [overrides] for the exact class: [supportsDataUpdates]
  /// is its exact class test.
  @override
  // DIVERGES(chartjs): adapt-hidden-legend-items, the built-in generator.
  Object? get nativeLegendGenerator =>
      supportsDataUpdates ? _generateLabels : null;

  /// `const {labels: {...}} = chart.legend.options` of [_generateLabels].
  @override
  // DIVERGES(chartjs): adapt-hidden-legend-items, the reads of the generator.
  List<OptionKey> get nativeLegendLabelKeys => const [
    OptionKey.pointStyle,
    OptionKey.color,
  ];

  @override
  DataUpdateShape get dataUpdateShape => DataUpdateShape.radial;

  /// controller.polarArea.js:6 `static id = 'polarArea'`.

  static const String id = 'polarArea';

  /// controller.polarArea.js:11 `static defaults`, a typed scope of the kind
  /// `PolarAreaControllerDatasetOptions` (Chart.js ADR 0054 §3).
  static final PolarAreaControllerDatasetOptionsScope defaults =
      PolarAreaControllerDatasetOptionsScope()
        ..dataElementType = 'arc'
        ..animation = (AnimationOptionsScope()
          ..animateRotate = true
          ..animateScale = true)
        ..animations = (AnimationsSpecScope()
          ..numbers = (AnimationOptionsScope()
            ..type = 'number'
            ..properties = <String>[
              'x',
              'y',
              'startAngle',
              'endAngle',
              'innerRadius',
              'outerRadius',
            ]))
        // DIVERGES(chartjs): adapt-axis-objects, the axis class.
        ..indexAxis = const RAxis()
        ..startAngle = 0.0
        ..spacing = 0.0
        // DIVERGES(chartjs): adapt-arc-option-enums, the enum value.
        ..spacingMode = ArcSpacingMode.proportional;

  /// controller.polarArea.js:32 `static overrides`, a typed scope of the
  /// kind `ChartOptions` (Chart.js ADR 0054 §3).
  ///
  /// The two legend functions are tear-offs of top-level functions: each
  /// read gives the same function (Chart.js ADR 0028, section 6).
  static final ChartOptionsScope overrides = ChartOptionsScope()
    ..aspectRatio = 1.0
    ..plugins = (PluginOptionsByTypeScope()
      ..legend = (LegendOptionsScope()
        ..labels = (LegendLabelOptionsScope()..generateLabels = _generateLabels)
        ..onClick = _onClick))
    ..scales = (ScaleOptionsByIdScope()
      ..jsWrite(
        'r',
        ScaleOptionsScope()
          ..type = 'radialLinear'
          ..angleLines = (AngleLineOptionsScope()..display = false)
          ..beginAtZero = true
          ..grid = (GridLineOptionsScope()..circular = true)
          ..pointLabels = (PointLabelOptionsScope()..display = false)
          ..startAngle = 0.0,
      ));

  /// controller.polarArea.js:4 `class PolarAreaController extends
  /// DatasetController` as a value (Chart.js ADR 0020, section 3).
  ///
  /// It extends [DatasetController.jsClass]. Its statics are `id`
  /// (`'polarArea'`), [defaults] and [overrides], in the upstream order of
  /// declaration (:6-88). Its `construct` calls `PolarAreaController(chart,
  /// datasetIndex, newTarget)` with the arguments of [controllerArgs].
  static final JsClass jsClass = JsClass(
    'PolarAreaController',
    superclass: DatasetController.jsClass,
    statics: {'id': id, 'defaults': defaults, 'overrides': overrides},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return PolarAreaController(chart, datasetIndex, newTarget);
    },
  );

  /// controller.polarArea.js:93 `innerRadius`. `_updateRadius` writes it.
  /// Dart `null` stands for JS `undefined`, the start value. No code of the
  /// pin reads it.
  double? innerRadius;

  /// controller.polarArea.js:94 `outerRadius`. `_updateRadius` writes it.
  /// Dart `null` stands for JS `undefined`, the start value. No code of the
  /// pin reads it.
  double? outerRadius;

  /// controller.polarArea.js:97 `getLabelAndValue(index)`.
  ///
  /// `chart.data.labels || []` and `labels[index] || ''` keep the label
  /// value: a List, a number or another truthy value stays as it is
  /// (Chart.js ADR 0028, section 2). `formatNumber` takes a `double`. Thus
  /// the port applies `jsToNumber` to the parsed value `r`.
  /// `Intl.NumberFormat.prototype.format` applies `ToIntlMathematicalValue`:
  /// for a string with more digits than a `double` keeps, upstream formats
  /// the exact decimal. The difference is in the digits only (Chart.js ADR
  /// 0034). A parsed item that is `null` or `undefined` throws a [TypeError]
  /// at the read of `r`, as upstream.
  @override
  ({Object? label, String value}) getLabelAndValue(double index) {
    final meta = cachedMeta;
    final chart = this.chart;
    // `chart.data.labels || []`
    // The data object of the user.
    final labelsValue = jsGet(chart.data, 'labels');
    final labels = jsTruthy(labelsValue) ? labelsValue : const <Object?>[];
    final value = formatNumber(
      jsToNumber(parsedValueOf(jsGetIndex(meta.parsed, index), const RAxis())),
      localeOf(readOption(chart.options, OptionKey.locale)),
    );

    // `labels[index] || ''`
    final label = jsGetIndex(labels, index);
    return (label: jsTruthy(label) ? label : '', value: value);
  }

  /// controller.polarArea.js:109 `parseObjectData(meta, data, start,
  /// count)`.
  ///
  /// `_parseObjectDataRadialScale.bind(this)(meta, data, start, count)` is
  /// the typed body [parseObjectDataRadialScaleOf] with the two values that
  /// it reads from `meta` and `this`: `meta.iScale` first, then
  /// `this._parsing`, in the upstream order. Each item is a [ParsedItem]
  /// `{r}`.
  @override
  List<ParsedItem> parseObjectData(
    types.ChartMeta meta,
    List<Object?> data,
    double start,
    double count,
  ) {
    return parseObjectDataRadialScaleOf(
      meta.iScale,
      parsing,
      data,
      start,
      count,
    );
  }

  /// controller.polarArea.js:113 `update(mode)`.
  @override
  void update(String mode) {
    final arcs = cachedMeta.data;

    _updateRadius();
    updateElements(arcs, 0, arcs.length.toDouble(), mode);
  }

  /// controller.polarArea.js:123 `getMinMax()`.
  /// @protected
  ///
  /// Upstream declares no parameter: [scale] and [canStack], the parameters
  /// of `DatasetController.getMinMax` (core.datasetController.js:622), are
  /// not read. The caller is `Scale.getMinMax` (core.scale.js:303), at
  /// core.scale.js:313.
  ///
  /// `range = {min: +Infinity, max: -Infinity}` keeps the raw parsed values,
  /// as upstream stores `parsed` unchanged. `parsed < range.min` and
  /// `parsed > range.max` are [jsLessThan]. Thus `[{r: '10'}, {r: '9'},
  /// {r: '30'}]` gives the range `'10'..'9'` (Chart.js ADR 0036, section 7).
  /// The record holds the `ToNumber` of each end: the only caller,
  /// core.scale.js:315 and :318, applies `Math.min` and `Math.max` to them.
  @override
  ({double min, double max}) getMinMax(types.Scale scale, [bool? canStack]) {
    final meta = cachedMeta;
    // :125 `range = {min: Number.POSITIVE_INFINITY, max:
    // Number.NEGATIVE_INFINITY}`.
    Object? min = double.infinity;
    Object? max = double.negativeInfinity;

    // `meta.data.forEach((element, index) => ...)`: the callback has no
    // `return` that stops the loop.
    for (var index = 0; index < meta.data.length; index++) {
      // One read of `this.getParsed(index).r` (:128), as upstream.
      final parsed = parsedValueOf(getParsed(index * 1.0), const RAxis());

      if (!jsIsNaN(parsed) && chart.getDataVisibility(index * 1.0)) {
        if (jsLessThan(parsed, min)) {
          min = parsed;
        }

        // :135 `parsed > range.max`.
        if (jsLessThan(max, parsed)) {
          max = parsed;
        }
      }
    }

    return (min: jsToNumber(min), max: jsToNumber(max));
  }

  /// controller.polarArea.js:147 `_updateRadius()`.
  /// @private
  ///
  /// A chart without a layout has no `chartArea`: the read of an edge
  /// throws a [TypeError], as in JavaScript. `Math.min` and `Math.max` are
  /// [jsMin] and [jsMax]. The raw option `cutoutPercentage` takes
  /// `ToNumber` at the arithmetic.
  void _updateRadius() {
    final chart = this.chart;
    final chartArea = chart.chartArea!;
    final opts = chart.options;
    final minSize = jsMin(
      chartArea.right - chartArea.left,
      chartArea.bottom - chartArea.top,
    );

    final outerRadius = jsMax(minSize / 2, 0);
    final cutoutPercentage = readOption(opts, OptionKey.cutoutPercentage);
    final innerRadius = jsMax(
      // Upstream reads `opts.cutoutPercentage` twice: a read of the options
      // has no side effect.
      jsTruthy(cutoutPercentage)
          ? (outerRadius / 100) * jsToNumber(cutoutPercentage)
          : 1.0,
      0,
    );
    final radiusLength =
        (outerRadius - innerRadius) / chart.getVisibleDatasetCount();

    this.outerRadius = outerRadius - (radiusLength * index);
    this.innerRadius = this.outerRadius! - radiusLength;
  }

  /// controller.polarArea.js:161 `updateElements(arcs, start, count, mode)`.
  ///
  /// The cast of the scale `r` stands for the reads of :167-169 (Chart.js
  /// ADR 0028, section 1). Every path from the cast reaches
  /// `scale.getIndexAngle(0)` at :169. A scale that is not a radial linear
  /// scale, or no scale, throws a [TypeError] there, as the read of
  /// `xCenter` and the call of `getIndexAngle` do upstream.
  ///
  /// `opts.animation` is the raw option: `false` of the harness gives
  /// `undefined` for `animateScale` and `animateRotate`, as in JavaScript.
  ///
  /// Before the first layout of the scale, `xCenter` and `yCenter` are Dart
  /// `null`, the JS `undefined` (scale.radialLinear.js:416-418). The reset
  /// of a new arc then writes `undefined` into `x` and `y`, and the next
  /// animation of `x` and `y` starts at the target, as upstream
  /// (core.animation.js:32).
  @override
  void updateElements(
    List<types.Element> arcs,
    double start,
    double count,
    String mode,
  ) {
    final reset = mode == 'reset';
    final chart = this.chart;
    final opts = chart.options;
    final animationOpts = readOption(opts, OptionKey.animation);
    // `const scale = this._cachedMeta.rScale;`
    final scale = cachedMeta.rScale! as types.RadialLinearScale;
    final centerX = scale.xCenter;
    final centerY = scale.yCenter;
    final datasetStartAngle = scale.getIndexAngle(0) - 0.5 * pi;
    var angle = datasetStartAngle;
    double i;

    final defaultAngle = 360 / countVisibleElements();
    // DIVERGES(chartjs): adapt-arc-native-options, an exact controller reads
    // the angle of a hit from its frozen entry, with no copy for one read.
    final exact = supportsDataUpdates && nativeArcClass(dataElementType);
    // DIVERGES(chartjs): adapt-direct-element-writes, `updateElement` of the
    // exact controller only assigns in these modes.
    final direct = supportsDataUpdates && (reset || mode == 'none');

    for (i = 0; i < start; ++i) {
      angle += _computeAngle(i, mode, defaultAngle, cachedAngle: exact);
    }
    // DIVERGES(chartjs): adapt-arc-native-options, a plan of this synchronous
    // loop only. A custom or active arc ends it for good before its first read.
    ArcOptions Function(int)? colors;
    var plannedAngle = 0.0;
    // DIVERGES(chartjs): adapt-polar-constant-options, the plan is the copy of
    // a frozen entry: a hit writes no context, and the copy has the fix-ups.
    var constant = false;
    final tryPlan =
        exact &&
        mode == 'none' &&
        start == 0 &&
        count > 2 &&
        parsing != false &&
        _nativeRadialScale(scale);
    // An existing entry stands before a color plan. It is the premise of the
    // copy: each tick of `Chart.updateData` starts with the entry.
    final tryColors = tryPlan && cachedDataElementOptions(mode) == null;
    for (i = start; i < start + count; i++) {
      final arc = arcs[i.toInt()];
      if (colors != null && (!nativeArcElement(arc) || arc.active)) {
        colors = null;
      }
      final prepared = colors;
      var startAngle = angle;
      // With a plan, the context refresh of `_computeAngle` is not observable:
      // the resolve below writes each of its fields, and only the exact scale
      // runs between the two.
      var endAngle =
          angle +
          (prepared == null
              ? _computeAngle(i, mode, defaultAngle, cachedAngle: exact)
              : chart.getDataVisibility(i)
              ? plannedAngle
              : 0.0);
      var outerRadius = chart.getDataVisibility(i)
          ? scale.getDistanceFromCenterForValue(
              parsedValueOf(getParsed(i), const RAxis()),
            )
          : 0.0;
      angle = endAngle;

      if (reset) {
        if (jsTruthy(readOption(animationOpts, OptionKey.animateScale))) {
          outerRadius = 0;
        }
        if (jsTruthy(readOption(animationOpts, OptionKey.animateRotate))) {
          startAngle = endAngle = datasetStartAngle;
        }
      }

      // DIVERGES(chartjs): adapt-arc-native-options, the context refresh and a
      // fresh copy of the template, as the resolve of this plan gives.
      final ElementOptions elementOptions;
      if (prepared != null) {
        if (!constant) getContext(i, false, mode);
        elementOptions = prepared(i.toInt());
      } else {
        elementOptions = resolveDataElementOptions(
          i,
          arc.active ? 'active' : mode,
        );
      }

      if (prepared == null || !constant) {
        _fixSpacing(elementOptions);
      }

      // DIVERGES(chartjs): adapt-direct-element-writes, the assign of the
      // literal with no object: the writes stay after the resolve above.
      if (arc case final types.ArcElementWrites target
          when direct &&
              centerX != null &&
              centerY != null &&
              target.typedWrites) {
        target
          ..x = centerX
          ..y = centerY
          ..innerRadius = 0.0
          ..outerRadius = outerRadius
          ..startAngle = startAngle
          ..endAngle = endAngle
          ..options = elementOptions;
      } else {
        // `x` and `y` are `undefined` before the first layout of the scale:
        // the face of the properties keeps it.
        final properties = ArcProperties();
        if (centerX == null) {
          properties.jsWrite('x', undefined);
        } else {
          properties.x = centerX;
        }
        if (centerY == null) {
          properties.jsWrite('y', undefined);
        } else {
          properties.y = centerY;
        }
        properties
          ..innerRadius = 0.0
          ..outerRadius = outerRadius
          ..startAngle = startAngle
          ..endAngle = endAngle
          ..options = elementOptions;

        updateElement(arc, i, properties, mode);
      }

      // Two ordinary resolutions warm the cached plan. One attempt.
      if (tryPlan && i == start + 1 && nativeArcElement(arc)) {
        colors = tryColors ? prepareNativeArcColors(this, arcs) : null;
        if (colors != null) {
          plannedAngle = _angleOf(
            colors(0).valueOf(OptionKey.angle),
            defaultAngle,
          );
        } else if (_frozenEntryTemplate(arc, arcs, mode) case final template?) {
          colors = (_) => template.clone();
          plannedAngle = _angleOf(
            template.valueOf(OptionKey.angle),
            defaultAngle,
          );
          constant = true;
        }
      }
    }
  }

  /// controller.polarArea.js:204-210: arc defaults (`spacing=0`,
  /// `spacingMode='angular'`) can mask polarArea-level values.
  // DIVERGES(chartjs): adapt-polar-constant-options, shared with the template.
  void _fixSpacing(ElementOptions elementOptions) {
    if (elementOptions.valueOf(OptionKey.spacing) == 0) {
      elementOptions.storeKey(
        OptionKey.spacing,
        options.readKey(OptionKey.spacing),
      );
    }
    // DIVERGES(chartjs): adapt-arc-option-enums, the enum value.
    if (elementOptions.valueOf(OptionKey.spacingMode) ==
        ArcSpacingMode.angular) {
      elementOptions.storeKey(
        OptionKey.spacingMode,
        options.readKey(OptionKey.spacingMode),
      );
    }
  }

  /// The fresh result of each later resolve of this loop, when each is a hit of
  /// the frozen entry: the exact chart, native arrays, a not shared result, and
  /// an `angle` and dataset options whose reads run no user code. Each later
  /// fix-up then stores the same values. Else Dart `null`.
  ///
  /// [arc] is the arc of this iteration. When it is not active, its result was
  /// a copy of the entry, so its fix-ups read each dataset option that a fix-up
  /// reads. A key whose fix-up does not fire on the entry has no read, as in
  /// the ordinary loop: a read stays in the resolver until the next
  /// `configure`.
  // DIVERGES(chartjs): adapt-polar-constant-options, the guard of the plan.
  ArcOptions? _frozenEntryTemplate(
    types.Element arc,
    List<types.Element> arcs,
    String mode,
  ) {
    final entry = cachedDataElementOptions(mode);
    if (entry is! ArcOptions ||
        arc.active ||
        enableOptionSharing ||
        !nativePointChart(chart) ||
        !identical(arcs, cachedMeta.data) ||
        !nativePointList(arcs) ||
        !nativeDataUpdateList(cachedMeta.parsed)) {
      return null;
    }
    final fixesSpacing = entry.valueOf(OptionKey.spacing) == 0;
    final fixesMode =
        entry.valueOf(OptionKey.spacingMode) == ArcSpacingMode.angular;
    if ((fixesSpacing || fixesMode) &&
        !options.rawOptionsAreScalar([
          if (fixesSpacing) OptionKey.spacing,
          if (fixesMode) OptionKey.spacingMode,
        ])) {
      return null;
    }
    final angle = entry.angleValue;
    if (angle is! num && angle is! Undefined) return null;
    final template = entry.clone();
    _fixSpacing(template);
    return template;
  }

  /// The exact radial scale with a scalar `reverse`: its value projection runs
  /// no user code. Port-only.
  // DIVERGES(chartjs): adapt-arc-native-options, the guard of the plan.
  bool _nativeRadialScale(types.RadialLinearScale scale) {
    if (!nativeArcScale(scale)) return false;
    final view = scale.options;
    return view is OptionView &&
        view.rawOptionsAreScalar(const [OptionKey.reverse]);
  }

  /// controller.polarArea.js:216 `countVisibleElements()`.
  ///
  /// `!isNaN(this.getParsed(index).r)`: an absent `r` is `undefined`, thus
  /// NaN, and a `null` `r` is 0. A parsed item that is `null` throws a
  /// [TypeError] at the read, as upstream.
  double countVisibleElements() {
    final meta = cachedMeta;
    var count = 0.0;

    // `meta.data.forEach((element, index) => ...)`.
    for (var index = 0; index < meta.data.length; index++) {
      if (!jsIsNaN(parsedValueOf(getParsed(index * 1.0), const RAxis())) &&
          chart.getDataVisibility(index * 1.0)) {
        count++;
      }
    }

    return count;
  }

  /// controller.polarArea.js:232 `_computeAngle(index, mode, defaultAngle)`.
  /// @private
  ///
  /// `angle || defaultAngle` keeps a truthy raw `angle` option. `toRadians`
  /// applies `ToNumber` to it at the arithmetic. The raw value is
  /// [ElementOptions.valueOf], typed for an [ArcOptions]. With [cachedAngle],
  /// a hit of the options cache reads its entry: a call would only copy it.
  double _computeAngle(
    double index,
    String mode,
    double defaultAngle, {
    bool cachedAngle = false,
  }) {
    if (!chart.getDataVisibility(index)) {
      return 0;
    }
    // DIVERGES(chartjs): adapt-arc-native-options, no copy for one read.
    final cached = cachedAngle ? cachedDataElementOptions(mode) : null;
    final angle = (cached ?? resolveDataElementOptions(index, mode)).valueOf(
      OptionKey.angle,
    );
    return _angleOf(angle, defaultAngle);
  }

  /// `toRadians(angle || defaultAngle)` of `_computeAngle`.
  double _angleOf(Object? angle, double defaultAngle) =>
      toRadians(jsToNumber(jsTruthy(angle) ? angle : defaultAngle));
}
