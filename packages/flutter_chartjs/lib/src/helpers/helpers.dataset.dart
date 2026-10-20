// Ported from Chart.js v4.5.1 src/helpers/helpers.dataset.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.dataset.ts`.
///
/// `getDatasetClipArea` returns `TRBL | false` upstream. The port returns
/// `TRBL?`, and Dart `null` stands for `false`. Both callers only test the
/// result for truthiness before they read it: `_drawDataset`
/// (core.controller.js:791, :797) and `clipBounds`
/// (filler.drawing.js:13, :169).
library;

import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/index.dart';

/// helpers.dataset.ts:10 and :27 the object literal
/// `{left, right, top, bottom}`.
final class _Trbl implements TRBL {
  const _Trbl({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  @override
  final double left;

  @override
  final double right;

  @override
  final double top;

  @override
  final double bottom;
}

/// The member `item[field]` of a scale or of a chart area, for a `field` of
/// `keyof ChartArea`. helpers.dataset.ts passes only the four edge names.
double _edgeOf(Object item, String field) => switch ((item, field)) {
  (final LayoutItem scale, 'left') => scale.left,
  (final LayoutItem scale, 'right') => scale.right,
  (final LayoutItem scale, 'top') => scale.top,
  (final LayoutItem scale, 'bottom') => scale.bottom,
  (final TRBL area, 'left') => area.left,
  (final TRBL area, 'right') => area.right,
  (final TRBL area, 'top') => area.top,
  (final TRBL area, 'bottom') => area.bottom,
  _ => throw ArgumentError.value(field, 'field', 'not an edge of $item'),
};

/// helpers.dataset.ts:3 `getSizeForArea`.
///
/// `scale.options.clip` is an option value (Chart.js ADR 0006), and the
/// test is its ToBoolean. Dart `null` for [chartArea] stands for the JS
/// `undefined` of a chart before its first layout: the read of its edge
/// throws a `TypeError`, as in JavaScript.
double _getSizeForArea(Scale scale, ChartArea? chartArea, String field) {
  return jsTruthy(scale.options['clip'])
      ? _edgeOf(scale, field)
      : _edgeOf(chartArea!, field);
}

/// helpers.dataset.ts:7 `getDatasetArea`.
///
/// Dart `null` for [chartArea] and for the result stands for JS
/// `undefined`, as in [_getSizeForArea].
TRBL? _getDatasetArea(ChartMeta meta, ChartArea? chartArea) {
  final ChartMeta(:xScale, :yScale) = meta;
  if (xScale != null && yScale != null) {
    return _Trbl(
      left: _getSizeForArea(xScale, chartArea, 'left'),
      right: _getSizeForArea(xScale, chartArea, 'right'),
      top: _getSizeForArea(yScale, chartArea, 'top'),
      bottom: _getSizeForArea(yScale, chartArea, 'bottom'),
    );
  }
  return chartArea;
}

/// The JavaScript `area - edge` for an edge of [ChartMetaClip] that is not a
/// `bool`: the subtraction applies `ToNumber` to [edge].
double _subtract(double area, Object? edge) => area - jsToNumber(edge);

/// The JavaScript `area + edge` for an edge of [ChartMetaClip] that is not a
/// `bool`.
///
/// For a number, Dart `null` (JS `null`) and [undefined], the addition
/// applies `ToNumber` to [edge]. For a string, an array or an object, `+`
/// joins the strings, and the JS result is a string such as `'1005'`. The
/// port returns `ToNumber` of that string. Each reader of the area applies
/// `ToNumber` to it: `ctx.rect` and `-` in `clipArea`
/// (helpers.canvas.ts:331), and `Math.min` in `clipBounds`
/// (filler.drawing.js:171, :173).
double _add(double area, Object? edge) => switch (edge) {
  null || num() || Undefined() => area + jsToNumber(edge),
  _ => jsToNumber(jsNumberToString(area) + jsToString(edge)),
};

/// helpers.dataset.ts:20 `getDatasetClipArea`.
///
/// Returns Dart `null` where upstream returns `false`: when
/// `meta._clip.disabled` is true. An edge of `false` gives the chart edge,
/// `true` gives the dataset area edge, and any other value moves the
/// dataset area edge outwards by the value. See [ChartMetaClip] for the
/// edge values.
TRBL? getDatasetClipArea(Chart chart, ChartMeta meta) {
  final clip = meta.clip;
  if (clip.disabled) {
    return null;
  }
  final area = _getDatasetArea(meta, chart.chartArea);

  return _Trbl(
    left: clip.left == false
        ? 0
        : _subtract(area!.left, clip.left == true ? 0 : clip.left),
    right: clip.right == false
        ? chart.width
        : _add(area!.right, clip.right == true ? 0 : clip.right),
    top: clip.top == false
        ? 0
        : _subtract(area!.top, clip.top == true ? 0 : clip.top),
    bottom: clip.bottom == false
        ? chart.height
        : _add(area!.bottom, clip.bottom == true ? 0 : clip.bottom),
  );
}
