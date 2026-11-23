// Original code, not ported from Chart.js: the fields of the tooltip options.

/// The fields of a [TooltipOptions] by the name of their upstream option
/// (Chart.js ADR 0192), for the tests that compare the tooltip options with
/// a path of upstream, for example `plugins.tooltip.bodyFont`.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// Each field of [options] by the name of its upstream option, in the order
/// of the constructor of [TooltipOptions] (the order of the upstream
/// defaults, plugin.tooltip.js:1275-1325, then the other options). Dart
/// `null` is a field that the options do not set.
Map<String, Object?> tooltipOptionFields(TooltipOptions options) => {
  'enabled': options.enabled,
  'external': options.external,
  'position': options.position,
  'backgroundColor': options.backgroundColor,
  'titleColor': options.titleColor,
  'titleFont': options.titleFont,
  'titleSpacing': options.titleSpacing,
  'titleMarginBottom': options.titleMarginBottom,
  'titleAlign': options.titleAlign,
  'bodyColor': options.bodyColor,
  'bodySpacing': options.bodySpacing,
  'bodyFont': options.bodyFont,
  'bodyAlign': options.bodyAlign,
  'footerColor': options.footerColor,
  'footerSpacing': options.footerSpacing,
  'footerMarginTop': options.footerMarginTop,
  'footerFont': options.footerFont,
  'footerAlign': options.footerAlign,
  'padding': options.padding,
  'caretPadding': options.caretPadding,
  'caretSize': options.caretSize,
  'cornerRadius': options.cornerRadius,
  'boxHeight': options.boxHeight,
  'boxWidth': options.boxWidth,
  'multiKeyBackground': options.multiKeyBackground,
  'displayColors': options.displayColors,
  'boxPadding': options.boxPadding,
  'borderColor': options.borderColor,
  'borderWidth': options.borderWidth,
  'animation': options.animation,
  'animations': options.animations,
  'callbacks': options.callbacks,
  'xAlign': options.xAlign,
  'yAlign': options.yAlign,
  'itemSort': options.itemSort,
  'filter': options.filter,
  'usePointStyle': options.usePointStyle,
  'rtl': options.rtl,
  'textDirection': options.textDirection,
  'mode': options.mode,
  'intersect': options.intersect,
  'axis': options.axis,
  'includeInvisible': options.includeInvisible,
  'reverse': options.reverse,
  'scripted': options.scripted,
  'events': options.events,
};

/// [paths] with the paths below `plugins.tooltip` sorted at their places:
/// a [TooltipOptions] has no key order, so a test that compares the order of
/// the paths of a theme compares these paths as a set, and the order of each
/// other path.
List<String> tooltipPathsSorted(Iterable<String> paths) {
  const prefix = 'plugins.tooltip.';
  final list = paths.toList();
  final sorted = list.where((path) => path.startsWith(prefix)).toList()..sort();
  var next = 0;
  return [
    for (final path in list)
      if (path.startsWith(prefix)) sorted[next++] else path,
  ];
}

/// The fields of [options] that it sets, in the order of
/// [tooltipOptionFields].
Map<String, Object> setTooltipOptionFields(TooltipOptions options) => {
  for (final MapEntry(:key, :value) in tooltipOptionFields(options).entries)
    key: ?value,
};
