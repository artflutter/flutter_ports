// Original code, not ported from Chart.js: native legend option conversion.

/// Normalization at the built-in legend generator boundary.
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show toTRBLCorners;
import 'package:flutter_chartjs_port/src/helpers/point_style.dart'
    show PointStyle;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart' show TRBLCorners;
import 'package:flutter_chartjs_port/src/types/legend_item.dart';

/// Resolves raw application labels and element options once when generating
/// an item. Custom generators construct [LegendItem] directly.
LegendItem legendItemFromOptions({
  required Object? text,
  Object? fillStyle,
  Object? fontColor,
  bool hidden = false,
  Object? lineCap,
  Object? lineDash,
  Object? lineDashOffset,
  Object? lineJoin,
  Object? lineWidth,
  Object? strokeStyle,
  Object? pointStyle,
  Object? rotation,
  Object? textAlign,
  Object? borderRadius,
  int? datasetIndex,
  int? index,
}) => LegendItem(
  text: text is List
      ? [for (final line in text) jsToString(line)]
      : [jsToString(text)],
  fillStyle: chartPaintOf(fillStyle, strict: false),
  fontColor: chartPaintOf(fontColor, strict: false),
  hidden: hidden,
  lineCap: canvasLineCap(lineCap),
  lineDash: lineDash == null || lineDash is Undefined
      ? null
      : canvasLineDash(lineDash),
  lineDashOffset: _number(lineDashOffset),
  lineJoin: canvasLineJoin(lineJoin),
  lineWidth: _number(lineWidth),
  strokeStyle: chartPaintOf(strokeStyle, strict: false),
  pointStyle: PointStyle.of(pointStyle),
  rotation: _number(rotation),
  textAlign: canvasTextAlign(textAlign),
  borderRadius: borderRadius is TRBLCorners
      ? borderRadius
      : jsTruthy(borderRadius)
      ? toTRBLCorners(borderRadius)
      : null,
  datasetIndex: datasetIndex,
  index: index,
);

double? _number(Object? value) =>
    value == null || value is Undefined ? null : jsToNumber(value);
