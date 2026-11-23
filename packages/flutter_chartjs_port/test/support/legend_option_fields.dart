// Original code, not ported from Chart.js: the fields of the legend options.

/// The fields of a [LegendOptions], a [LegendLabelOptions] and a
/// [LegendTitleOptions] by the name of their upstream option (Chart.js ADR
/// 0193), for the tests that compare the legend options with a path of
/// upstream, for example `plugins.legend.labels.font`.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// Each field of [options] by the name of its upstream option, in the order
/// of the upstream defaults (plugin.legend.js:636-712), then the other
/// options. Dart `null` is a field that the options do not set.
Map<String, Object?> legendOptionFields(LegendOptions options) => {
  'display': options.display,
  'position': options.position,
  'align': options.align,
  'fullSize': options.fullSize,
  'reverse': options.reverse,
  'weight': options.weight,
  'onClick': options.onClick,
  'onHover': options.onHover,
  'onLeave': options.onLeave,
  'labels': options.labels,
  'title': options.title,
  'maxHeight': options.maxHeight,
  'maxWidth': options.maxWidth,
  'rtl': options.rtl,
  'textDirection': options.textDirection,
  'scripted': options.scripted,
  'events': options.events,
};

/// Each field of the label options [options] by the name of its upstream
/// option, in the order of the upstream defaults (plugin.legend.js:660-705),
/// then the other options.
Map<String, Object?> legendLabelOptionFields(LegendLabelOptions options) => {
  'color': options.color,
  'boxWidth': options.boxWidth,
  'padding': options.padding,
  'generateLabels': options.generateLabels,
  'boxHeight': options.boxHeight,
  'font': options.font,
  'pointStyleWidth': options.pointStyleWidth,
  'filter': options.filter,
  'sort': options.sort,
  'pointStyle': options.pointStyle,
  'textAlign': options.textAlign,
  'usePointStyle': options.usePointStyle,
  'useBorderRadius': options.useBorderRadius,
  'borderRadius': options.borderRadius,
};

/// Each field of the title options [options] by the name of its upstream
/// option, in the order of the upstream defaults (plugin.legend.js:706-711),
/// then the other options.
Map<String, Object?> legendTitleOptionFields(LegendTitleOptions options) => {
  'color': options.color,
  'display': options.display,
  'position': options.position,
  'text': options.text,
  'font': options.font,
  'padding': options.padding,
};

/// Whether [value] is one of the legend option classes.
bool isLegendOptionObject(Object? value) =>
    value is LegendOptions ||
    value is LegendLabelOptions ||
    value is LegendTitleOptions;

/// The fields that the legend option object [value] sets, in the order of
/// [legendOptionFields], [legendLabelOptionFields] or
/// [legendTitleOptionFields].
Map<String, Object> setLegendOptionFields(Object value) => {
  for (final MapEntry(:key, :value) in switch (value) {
    final LegendOptions options => legendOptionFields(options),
    final LegendLabelOptions options => legendLabelOptionFields(options),
    final LegendTitleOptions options => legendTitleOptionFields(options),
    _ => throw ArgumentError.value(value, 'value', 'No legend option object'),
  }.entries)
    key: ?value,
};
