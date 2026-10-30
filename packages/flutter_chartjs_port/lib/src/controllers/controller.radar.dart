// Ported from Chart.js v4.6.1 src/controllers/controller.radar.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-parsed, the typed data of Chart.js ADR 0054.

/// Port of `src/controllers/controller.radar.js`.
///
/// [RadarController] is the dataset controller of the `radar` charts. It
/// parses the `r` value of each item, puts each `PointElement` at the
/// position of its value on the radial linear scale, and closes the
/// `LineElement` of the dataset through the points.
///
/// - The parsed data is typed (Chart.js ADR 0054 §8): the reads
///   `parsed[vScale.axis]` and `this.getParsed(i).r` are [parsedValueOf],
///   typed for a [ParsedItem]. A parsed item of another class reads by
///   name. The label read `vScale.getLabels()[index]` is [jsGetIndex]. The
///   dataset options read typed ([OptionView.readKey]).
/// - The properties of the line are a [LineProperties], and those of a
///   point a [PointProperties] (Chart.js ADR 0054 §9). The write
///   `line.points = points` is the typed setter of a line of the exact class
///   [LineElement], and a write by name through `types.PropertyAccess` for a
///   line of another class. The scale cast to `types.RadialLinearScale`
///   stands at the upstream call of `getPointPositionForValue` (:88).
/// - The label of [RadarController.getLabelAndValue] is the raw label
///   (Chart.js ADR 0028, section 2).
/// - [RadarController.jsClass] is the class as a value with the statics
///   `id`, `defaults` and `overrides` (Chart.js ADR 0020, section 3).
/// - The option resolution for each point stays literal (Chart.js ADR 0036,
///   section 8: the step 7 list).
///
/// This library imports `core.datasetController.dart`, which imports
/// `core.animations.dart`. Thus it is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController, controllerArgs, parsedValueOf;
import 'package:flutter_chartjs_port/src/elements/element.line.dart'
    show LineElement;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show OptionView, parseObjectDataRadialScaleOf;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGetIndex;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/options/parsed.dart'
    show AxisKey, ParsedItem;
import 'package:flutter_chartjs_port/src/options/props.dart'
    show LineProperties, PointProperties;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        ChartOptionsScope,
        ElementOptionsByTypeScope,
        LineOptionsScope,
        RadarControllerDatasetOptionsScope,
        ScaleOptionsByIdScope,
        ScaleOptionsScope;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// controller.radar.js:4 `RadarController extends DatasetController`.
class RadarController extends DatasetController {
  /// `new RadarController(chart, datasetIndex)`. Upstream declares no
  /// constructor in this class. [newTarget] is `new.target` (Chart.js ADR
  /// 0020, section 4).
  RadarController(super.chart, super.datasetIndex, [super.newTarget]);

  /// controller.radar.js:6 `static id = 'radar'`.
  static const String id = 'radar';

  /// controller.radar.js:11 `static defaults`, a typed scope of the kind
  /// `RadarControllerDatasetOptions` (Chart.js ADR 0054 §3).
  static final RadarControllerDatasetOptionsScope defaults =
      RadarControllerDatasetOptionsScope()
        ..datasetElementType = 'line'
        ..dataElementType = 'point'
        ..indexAxis = 'r'
        ..showLine = true
        ..elements = (ElementOptionsByTypeScope()
          ..line = (LineOptionsScope()..fill = 'start'));

  /// controller.radar.js:26 `static overrides`, a typed scope of the kind
  /// `ChartOptions` (Chart.js ADR 0054 §3).
  static final ChartOptionsScope overrides = ChartOptionsScope()
    ..aspectRatio = 1.0
    ..scales = (ScaleOptionsByIdScope()
      ..jsWrite('r', ScaleOptionsScope()..type = 'radialLinear'));

  /// controller.radar.js:4 `class RadarController extends
  /// DatasetController` as a value (Chart.js ADR 0020, section 3).
  ///
  /// It extends [DatasetController.jsClass]. Its statics are `id`
  /// (`'radar'`), [defaults] and [overrides], in the upstream order of
  /// declaration (:6-34). Its `construct` calls `RadarController(chart,
  /// datasetIndex, newTarget)` with the arguments of [controllerArgs].
  static final JsClass jsClass = JsClass(
    'RadarController',
    superclass: DatasetController.jsClass,
    statics: {'id': id, 'defaults': defaults, 'overrides': overrides},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return RadarController(chart, datasetIndex, newTarget);
    },
  );

  /// controller.radar.js:39 `getLabelAndValue(index)`.
  /// @protected
  ///
  /// The label is `vScale.getLabels()[index]` without `'' +` and without
  /// `|| ''`: [undefined] past the end of the labels, Dart `null` for a JS
  /// `null` label, and a number or a `List` as it is (Chart.js ADR 0028,
  /// section 2). `'' + value` is [jsToString].
  @override
  ({Object? label, String value}) getLabelAndValue(double index) {
    final vScale = cachedMeta.vScale;
    final parsed = getParsed(index);
    final label = jsGetIndex(vScale!.getLabels(), index);
    final axis = vScale.axis;

    return (
      label: label,
      value: jsToString(
        vScale.getLabelForValue(parsedValueOf(parsed, AxisKey.of(axis), axis)),
      ),
    );
  }

  /// controller.radar.js:49 `parseObjectData(meta, data, start, count)`.
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

  /// controller.radar.js:53 `update(mode)`.
  ///
  /// `meta.data || []`: `meta.data` is always a List. `line.points =
  /// points` is the typed setter of a line of the exact class
  /// [LineElement], and a write by name through `types.PropertyAccess` for
  /// a line of another class (Chart.js ADR 0054 §9): the setter of
  /// `LineElement` copies the elements into a typed list (row
  /// `adapt-line-points-elements`). The null check throws a [TypeError] for
  /// a meta without a dataset element, as the JS write into `undefined`
  /// does.
  @override
  void update(String mode) {
    final meta = cachedMeta;
    final line = meta.dataset;
    final points = meta.data;
    final labels = meta.iScale!.getLabels();

    // Update Line
    final target = line!;
    if (identical(target.runtimeType, LineElement)) {
      (target as LineElement).points = points;
    } else {
      _setProperty(target as types.PropertyAccess, 'points', points);
    }
    // In resize mode only point locations change, so no need to set the
    // points or options.
    if (mode != 'resize') {
      final options = resolveDatasetElementOptions(mode);
      if (!jsTruthy(this.options.readKey(OptionKey.showLine))) {
        options.storeKey(OptionKey.borderWidth, 0.0);
      }

      final properties = LineProperties()
        ..loop = true
        ..fullLoop = labels.length == points.length
        ..options = options;

      updateElement(target, null, properties, mode);
    }

    // Update Points
    updateElements(points, 0, points.length.toDouble(), mode);
  }

  /// controller.radar.js:81 `updateElements(points, start, count, mode)`.
  ///
  /// `scale` stays a `types.Scale?`. The cast to `types.RadialLinearScale`
  /// stands in the loop, after the option resolution of :87, at the
  /// upstream call of `getPointPositionForValue` (:88, Chart.js ADR 0028,
  /// section 1). Thus an update with no point reads no member of the scale
  /// and throws nothing, as upstream. `this.getParsed(i).r` is
  /// [parsedValueOf]: an absent key gives [undefined], and the scale gives
  /// NaN for it (Chart.js ADR 0025, section 1). A JS `null` item throws a
  /// [TypeError], as the JS property read of `null` does.
  ///
  /// In the mode `reset`, `x` and `y` are `xCenter` and `yCenter` of the
  /// scale. Before the first layout of the scale, both are Dart `null`, the
  /// JS `undefined` (scale.radialLinear.js:416-418). The element then gets
  /// `undefined` through the face of the [PointProperties], and
  /// `isNaN(undefined)` is true. Thus the next animation of `x` and `y`
  /// starts at the target, as upstream (core.animation.js:32).
  @override
  void updateElements(
    List<types.Element> points,
    double start,
    double count,
    String mode,
  ) {
    final scale = cachedMeta.rScale;
    final reset = mode == 'reset';

    for (var i = start; i < start + count; i++) {
      final point = points[i.toInt()];
      final options = resolveDataElementOptions(
        i,
        point.active ? 'active' : mode,
      );
      final radial = scale! as types.RadialLinearScale;
      final pointPosition = radial.getPointPositionForValue(
        i,
        parsedValueOf(getParsed(i), AxisKey.r, 'r'),
      );

      final x = reset ? radial.xCenter : pointPosition.x;
      final y = reset ? radial.yCenter : pointPosition.y;

      final properties = PointProperties();
      if (x == null) {
        properties.jsWrite('x', undefined);
      } else {
        properties.x = x;
      }
      if (y == null) {
        properties.jsWrite('y', undefined);
      } else {
        properties.y = y;
      }
      properties
        ..angle = pointPosition.angle
        ..skip = x == null || x.isNaN || y == null || y.isNaN
        ..options = options;

      updateElement(point, i, properties, mode);
    }
  }
}

/// The JS write `element[key] = value` by name into an element of a user
/// element class (Chart.js ADR 0017, section 5).
void _setProperty(types.PropertyAccess element, String key, Object? value) {
  element[key] = value;
}
