// Ported from Chart.js v4.6.1 src/helpers/helpers.dataset.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.dataset.ts`.
///
/// `getDatasetClipArea` returns `TRBL | false` upstream. The port returns
/// `TRBL?`, and Dart `null` stands for `false`. Both callers only test the
/// result for truthiness before they read it: `_drawDataset`
/// (core.controller.js:791, :797) and `clipBounds`
/// (filler.drawing.js:13, :188).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/types/index.dart';

/// helpers.dataset.ts:10 and :27 the object literal
/// `{left, right, top, bottom}`.
final class const _Trbl({
  @override required final double left,
  @override required final double right,
  @override required final double top,
  @override required final double bottom,
}) implements TRBL;

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
/// `scale.options.clip` is an option value, read with [readOption] (Chart.js
/// ADR 0054 §4), and the test is its ToBoolean. Dart `null` for [chartArea]
/// stands for the JS `undefined` of a chart before its first layout: the
/// read of its edge throws a `TypeError`, as in JavaScript.
double _getSizeForArea(Scale scale, ChartArea? chartArea, String field) {
  return jsTruthy(readOption(scale.options, OptionKey.clip))
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

/// helpers.dataset.ts:20 `getDatasetClipArea`.
///
/// Returns Dart `null` where upstream returns `false`: when
/// `meta._clip.disabled` is true. A side of Dart `null` (JS `false`) gives
/// the chart edge, and a number moves the dataset area edge outwards by the
/// number: `true` is 0 (row `adapt-native-chart-meta`, [ChartClip]).
TRBL? getDatasetClipArea(Chart chart, ChartMeta meta) {
  final clip = meta.clip;
  if (clip.disabled) {
    return null;
  }
  final area = _getDatasetArea(meta, chart.chartArea);
  final ChartClip(:left, :right, :top, :bottom) = clip;

  return _Trbl(
    left: left == null ? 0 : area!.left - left,
    right: right == null ? chart.width : area!.right + right,
    top: top == null ? 0 : area!.top - top,
    bottom: bottom == null ? chart.height : area!.bottom + bottom,
  );
}
