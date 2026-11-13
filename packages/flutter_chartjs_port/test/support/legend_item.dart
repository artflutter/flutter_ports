// Original code, not ported from Chart.js: native legend item comparisons.

/// Typed item comparisons and decoding of frozen upstream expectations.
library;

import 'dart:ui' show StrokeCap, StrokeJoin, TextAlign;

import 'package:flutter_chartjs_port/src/helpers/point_style.dart'
    show PointStyle;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsToString;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart' show TRBLCorners;
import 'package:flutter_chartjs_port/src/types/legend_hit_box.dart';
import 'package:flutter_chartjs_port/src/types/legend_item.dart';
import 'package:flutter_chartjs_port/src/types/tooltip_callbacks.dart'
    show TooltipCornerRadii;
import 'package:test/test.dart';

import 'color_json.dart';

/// Compares the native fields directly, including plugin implementations.
Matcher legendItemEquals(LegendItem expected) => isA<LegendItem>()
    .having((item) => item.text, 'text', expected.text)
    .having(
      (item) => item.fillStyle,
      'fillStyle',
      _paintEquals(expected.fillStyle),
    )
    .having(
      (item) => item.fontColor,
      'fontColor',
      _paintEquals(expected.fontColor),
    )
    .having((item) => item.hidden, 'hidden', expected.hidden)
    .having((item) => item.lineCap, 'lineCap', expected.lineCap)
    .having(
      (item) => item.lineDash,
      'lineDash',
      expected.lineDash == null
          ? isNull
          : orderedEquals(expected.lineDash!.map(_numberEquals)),
    )
    .having(
      (item) => item.lineDashOffset,
      'lineDashOffset',
      _numberEquals(expected.lineDashOffset),
    )
    .having((item) => item.lineJoin, 'lineJoin', expected.lineJoin)
    .having(
      (item) => item.lineWidth,
      'lineWidth',
      _numberEquals(expected.lineWidth),
    )
    .having(
      (item) => item.strokeStyle,
      'strokeStyle',
      _paintEquals(expected.strokeStyle),
    )
    .having((item) => item.pointStyle, 'pointStyle', expected.pointStyle)
    .having(
      (item) => item.rotation,
      'rotation',
      _numberEquals(expected.rotation),
    )
    .having((item) => item.textAlign, 'textAlign', expected.textAlign)
    .having(
      (item) => item.borderRadius,
      'borderRadius',
      _cornersEqual(expected.borderRadius),
    )
    .having((item) => item.datasetIndex, 'datasetIndex', expected.datasetIndex)
    .having((item) => item.index, 'index', expected.index);

Matcher _numberEquals(double? value) => value == null
    ? isNull
    : value.isNaN
    ? isNaN
    : value.isInfinite
    ? equals(value)
    : closeTo(value, value.abs() > 1e3 ? value.abs() * 1e-12 : 1e-9);

Matcher _paintEquals(ChartPaint expected) => switch (expected) {
  SolidChartPaint(:final color) => isA<SolidChartPaint>().having(
    (paint) => nativeColorBytes(paint.color),
    'color',
    nativeColorBytes(color),
  ),
  final ChartShaderPaint paint => same(paint),
  UnchangedChartPaint() => isA<UnchangedChartPaint>(),
};

Matcher _cornersEqual(TRBLCorners? expected) => expected == null
    ? isNull
    : isA<TRBLCorners>()
          .having((r) => r.topLeft, 'topLeft', _numberEquals(expected.topLeft))
          .having(
            (r) => r.topRight,
            'topRight',
            _numberEquals(expected.topRight),
          )
          .having(
            (r) => r.bottomLeft,
            'bottomLeft',
            _numberEquals(expected.bottomLeft),
          )
          .having(
            (r) => r.bottomRight,
            'bottomRight',
            _numberEquals(expected.bottomRight),
          );

/// Matches native items inside an ordered test log without serializing them.
Object? legendObservationMatcher(Object? expected) => switch (expected) {
  final LegendItem item => legendItemEquals(item),
  final LegendHitBox box => predicate<LegendHitBox>(
    (actual) => actual.equalsTo(box),
    'hit box with equal geometry and membership',
  ),
  final List<Object?> values => [
    for (final value in values) legendObservationMatcher(value),
  ],
  _ => expected,
};

/// Decodes only frozen upstream expectations into the native item class.
/// Actual items are never converted into dictionaries or property bags.
LegendItem legendItemFromReference(Map<String, Object?> reference) {
  Object? field(String key) => switch (reference[key]) {
    Undefined() => null,
    final value => value,
  };
  final text = reference.containsKey('text') ? reference['text'] : undefined;
  final dash = field('lineDash') as List<Object?>?;
  return LegendItem(
    text: text is List
        ? [for (final line in text) jsToString(line)]
        : [jsToString(text)],
    fillStyle: chartPaintOf(referenceColorInput(field('fillStyle'))),
    fontColor: chartPaintOf(referenceColorInput(field('fontColor'))),
    hidden: field('hidden') == true,
    lineCap: field('lineCap') as StrokeCap?,
    lineDash: dash == null
        ? null
        : [for (final value in dash) (value! as num).toDouble()],
    lineDashOffset: (field('lineDashOffset') as num?)?.toDouble(),
    lineJoin: field('lineJoin') as StrokeJoin?,
    lineWidth: (field('lineWidth') as num?)?.toDouble(),
    strokeStyle: chartPaintOf(referenceColorInput(field('strokeStyle'))),
    pointStyle: switch (field('pointStyle')) {
      final PointStyle style => style,
      _ => null,
    },
    rotation: (field('rotation') as num?)?.toDouble(),
    textAlign: field('textAlign') as TextAlign?,
    borderRadius: _referenceCorners(field('borderRadius')),
    datasetIndex: (field('datasetIndex') as num?)?.toInt(),
    index: (field('index') as num?)?.toInt(),
  );
}

TRBLCorners? _referenceCorners(Object? value) => switch (value) {
  final TRBLCorners corners => corners,
  final num radius => TooltipCornerRadii.all(radius.toDouble()),
  final Map<String, Object?> corners => TooltipCornerRadii(
    topLeft: (corners['topLeft'] as num?)?.toDouble() ?? 0,
    topRight: (corners['topRight'] as num?)?.toDouble() ?? 0,
    bottomLeft: (corners['bottomLeft'] as num?)?.toDouble() ?? 0,
    bottomRight: (corners['bottomRight'] as num?)?.toDouble() ?? 0,
  ),
  _ => null,
};

/// Recognizes an item in the frozen upstream observations.
bool isLegendItemReference(Map<String, Object?> value) =>
    value.containsKey('text') &&
    (value.containsKey('datasetIndex') || value.containsKey('index')) &&
    value.containsKey('fillStyle');
