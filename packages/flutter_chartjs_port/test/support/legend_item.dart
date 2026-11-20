// Original code, not ported from Chart.js: native legend item comparisons.

/// Typed item comparisons and decoding of frozen upstream expectations.
library;

import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs_core.dart';
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

Matcher _cornersEqual(BorderRadius? expected) => expected == null
    ? isNull
    : isA<BorderRadius>()
          .having(
            (r) => r.topLeft.x,
            'topLeft',
            _numberEquals(expected.topLeft.x),
          )
          .having(
            (r) => r.topRight.x,
            'topRight',
            _numberEquals(expected.topRight.x),
          )
          .having(
            (r) => r.bottomLeft.x,
            'bottomLeft',
            _numberEquals(expected.bottomLeft.x),
          )
          .having(
            (r) => r.bottomRight.x,
            'bottomRight',
            _numberEquals(expected.bottomRight.x),
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

BorderRadius? _referenceCorners(Object? value) => switch (value) {
  final BorderRadius corners => corners,
  final num radius => BorderRadius.all(Radius.circular(radius.toDouble())),
  final Map<String, Object?> corners => BorderRadius.only(
    topLeft: Radius.circular((corners['topLeft'] as num?)?.toDouble() ?? 0),
    topRight: Radius.circular((corners['topRight'] as num?)?.toDouble() ?? 0),
    bottomLeft: Radius.circular(
      (corners['bottomLeft'] as num?)?.toDouble() ?? 0,
    ),
    bottomRight: Radius.circular(
      (corners['bottomRight'] as num?)?.toDouble() ?? 0,
    ),
  ),
  _ => null,
};

/// Recognizes an item in the frozen upstream observations.
bool isLegendItemReference(Map<String, Object?> value) =>
    value.containsKey('text') &&
    (value.containsKey('datasetIndex') || value.containsKey('index')) &&
    value.containsKey('fillStyle');
