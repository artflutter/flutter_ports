// Ported from Chart.js v4.6.1 src/controllers/controller.polarArea.js (MIT, Chart.js Contributors).

/// Port of `src/controllers/controller.polarArea.js`.
///
/// [PolarAreaController] is the dataset controller of the `polarArea`
/// charts. It parses the value `r` of each item, gives each visible item an
/// angle, and writes the properties of each `ArcElement` through
/// `updateElement`. The radius of each arc comes from the radial linear
/// scale `r`.
///
/// - A parsed item and a data item are any value (Chart.js ADR 0036). A read
///   with a `String` key is [jsGetKey], and a read with a number index is
///   [jsGetIndex]. A read of a resolver or of an option object is [jsGet]
///   (Chart.js ADR 0017, section 8).
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

import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController, controllerArgs;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show parseObjectDataRadialScale;
import 'package:flutter_chartjs_port/src/helpers/helpers.intl.dart'
    show formatNumber;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show pi, toRadians;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsMin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsGetIndex, jsGetKey;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
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
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// controller.polarArea.js:38 `generateLabels(chart)` of
/// `overrides.plugins.legend.labels` (Chart.js ADR 0028, section 6).
///
/// The read of `chart.legend.options` is inside the test (:41). A Dart
/// `null` legend throws a [TypeError] there, as `undefined.options` does.
/// `data.labels.length` of an absent `labels` throws a [TypeError], as in
/// JavaScript. A `labels` value with a truthy `length` that is not a List
/// throws a [TypeError] at the cast, where upstream throws at `map`.
List<Object?> _generateLabels(types.Chart chart) {
  final data = chart.data;
  if (jsTruthy(jsGet(jsGet(data, 'labels'), 'length')) &&
      jsTruthy(jsGet(jsGet(data, 'datasets'), 'length'))) {
    // `const {labels: {pointStyle, color}} = chart.legend.options;`
    final labelsOptions = jsGet(chart.legend!.options, 'labels');
    final pointStyle = jsGet(labelsOptions, 'pointStyle');
    final color = jsGet(labelsOptions, 'color');

    return [
      for (final (i, label)
          in (jsGet(data, 'labels')! as List<Object?>).indexed)
        _item(chart, label, i.toDouble(), pointStyle, color),
    ];
  }
  return <Object?>[];
}

/// The callback of `data.labels.map` (controller.polarArea.js:43-59).
///
/// The keys keep the order of the upstream literal. A key of `style` that is
/// absent gives [jsGet]'s `undefined`, as the JS property read does. `index`
/// is a `double` (Chart.js ADR 0045).
Map<String, Object?> _item(
  types.Chart chart,
  Object? label,
  double i,
  Object? pointStyle,
  Object? color,
) {
  final meta = chart.getDatasetMeta(0);
  final style = meta.controller!.getStyle(i);

  return <String, Object?>{
    'text': label,
    'fillStyle': jsGet(style, 'backgroundColor'),
    'strokeStyle': jsGet(style, 'borderColor'),
    'fontColor': color,
    'lineWidth': jsGet(style, 'borderWidth'),
    'pointStyle': pointStyle,
    'hidden': !chart.getDataVisibility(i),

    // Extra data used for toggling the correct item
    'index': i,
  };
}

/// controller.polarArea.js:65 `onClick(e, legendItem, legend)` of
/// `overrides.plugins.legend` (Chart.js ADR 0028, section 6).
///
/// `toggleDataVisibility(legendItem.index)` gives the raw item index to
/// `types.Chart.toggleDataVisibility`, which writes the property key
/// `ToString(index)` (core.controller.js:881-883), as upstream.
void _onClick(Object? e, Object? legendItem, types.LegendElement legend) {
  legend.chart.toggleDataVisibility(jsGet(legendItem, 'index'));
  legend.chart.update();
}

/// controller.polarArea.js:4 `PolarAreaController extends
/// DatasetController`.
class PolarAreaController extends DatasetController {
  /// controller.polarArea.js:90 `constructor(chart, datasetIndex)`.
  ///
  /// [newTarget] is `new.target` (Chart.js ADR 0020, section 4). The fields
  /// [innerRadius] and [outerRadius] start as Dart `null`, the `undefined`
  /// of :93-94.
  PolarAreaController(super.chart, super.datasetIndex, [super.newTarget]);

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
        ..indexAxis = 'r'
        ..startAngle = 0.0
        ..spacing = 0.0
        ..spacingMode = 'proportional';

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
    final labelsValue = chart.data['labels'];
    final labels = jsTruthy(labelsValue) ? labelsValue : const <Object?>[];
    final value = formatNumber(
      jsToNumber(jsGetKey(jsGetIndex(meta.parsed, index), 'r')),
      jsGet(chart.options, 'locale'),
    );

    // `labels[index] || ''`
    final label = jsGetIndex(labels, index);
    return (label: jsTruthy(label) ? label : '', value: value);
  }

  /// controller.polarArea.js:109 `parseObjectData(meta, data, start,
  /// count)`.
  ///
  /// `_parseObjectDataRadialScale.bind(this)(meta, data, start, count)`:
  /// [jsCall] with this controller as `thisArg`. The function returns a
  /// `List` of `{r}` objects, the type of the result of this method.
  @override
  List<AnyObject> parseObjectData(
    types.ChartMeta meta,
    List<Object?> data,
    double start,
    double count,
  ) {
    return jsCall(
          parseObjectDataRadialScale,
          [meta, data, start, count],
          thisArg: this,
        )!
        as List<AnyObject>;
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
      final parsed = jsGetKey(getParsed(index.toDouble()), 'r');

      if (!jsIsNaN(parsed) && chart.getDataVisibility(index.toDouble())) {
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
    final innerRadius = jsMax(
      jsTruthy(jsGet(opts, 'cutoutPercentage'))
          ? (outerRadius / 100) * jsToNumber(jsGet(opts, 'cutoutPercentage'))
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
    final animationOpts = jsGet(opts, 'animation');
    // `const scale = this._cachedMeta.rScale;`
    final scale = cachedMeta.rScale! as types.RadialLinearScale;
    final centerX = scale.xCenter;
    final centerY = scale.yCenter;
    final datasetStartAngle = scale.getIndexAngle(0) - 0.5 * pi;
    var angle = datasetStartAngle;
    double i;

    final defaultAngle = 360 / countVisibleElements();

    for (i = 0; i < start; ++i) {
      angle += _computeAngle(i, mode, defaultAngle);
    }
    for (i = start; i < start + count; i++) {
      final arc = arcs[i.toInt()];
      var startAngle = angle;
      var endAngle = angle + _computeAngle(i, mode, defaultAngle);
      var outerRadius = chart.getDataVisibility(i)
          ? scale.getDistanceFromCenterForValue(jsGetKey(getParsed(i), 'r'))
          : 0.0;
      angle = endAngle;

      if (reset) {
        if (jsTruthy(jsGet(animationOpts, 'animateScale'))) {
          outerRadius = 0;
        }
        if (jsTruthy(jsGet(animationOpts, 'animateRotate'))) {
          startAngle = endAngle = datasetStartAngle;
        }
      }

      final properties = <String, Object?>{
        'x': centerX ?? undefined,
        'y': centerY ?? undefined,
        'innerRadius': 0.0,
        'outerRadius': outerRadius,
        'startAngle': startAngle,
        'endAngle': endAngle,
        'options': resolveDataElementOptions(i, arc.active ? 'active' : mode),
      };

      // Arc defaults (`spacing=0`, `spacingMode='angular'`) can mask
      // polarArea-level values.
      final elementOptions = properties['options']! as AnyObject;
      if (elementOptions['spacing'] == 0) {
        elementOptions['spacing'] = jsGet(options, 'spacing');
      }
      if (elementOptions['spacingMode'] == 'angular') {
        elementOptions['spacingMode'] = jsGet(options, 'spacingMode');
      }

      updateElement(arc, i, properties, mode);
    }
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
      if (!jsIsNaN(jsGetKey(getParsed(index.toDouble()), 'r')) &&
          chart.getDataVisibility(index.toDouble())) {
        count++;
      }
    }

    return count;
  }

  /// controller.polarArea.js:232 `_computeAngle(index, mode, defaultAngle)`.
  /// @private
  ///
  /// `angle || defaultAngle` keeps a truthy raw `angle` option. `toRadians`
  /// applies `ToNumber` to it at the arithmetic.
  double _computeAngle(double index, String mode, double defaultAngle) {
    if (!chart.getDataVisibility(index)) {
      return 0;
    }
    final angle = jsGet(resolveDataElementOptions(index, mode), 'angle');
    return toRadians(jsToNumber(jsTruthy(angle) ? angle : defaultAngle));
  }
}
