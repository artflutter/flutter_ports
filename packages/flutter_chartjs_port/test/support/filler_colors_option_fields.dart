// Original code, not ported from Chart.js: plugin option object fields.

/// The fields of a [FillerOptions], of a [ColorsPluginOptions] (Chart.js ADR
/// 0196) and of a [TitleOptions] or [SubtitleOptions] (Chart.js ADR 0197) by
/// the name of their option, for the tests that compare the options with a
/// path, for example `plugins.colors.borderColors`.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// Each field of [options] by the name of its upstream option, in the order
/// of the constructor of [FillerOptions]. Dart `null` is a field that the
/// options do not set.
Map<String, Object?> fillerOptionFields(FillerOptions options) => {
  'propagate': options.propagate,
  'drawTime': options.drawTime,
  'events': options.events,
};

/// Each field of [options] by the name of its option, in the order of the
/// constructor of [ColorsPluginOptions]: the upstream options, then the
/// palettes of the theme (row `theme-H4a`). Dart `null` is a field that the
/// options do not set.
Map<String, Object?> colorsOptionFields(ColorsPluginOptions options) => {
  'enabled': options.enabled,
  'forceOverride': options.forceOverride,
  'borderColors': options.borderColors,
  'backgroundColors': options.backgroundColors,
  'events': options.events,
};

/// Each field of the title or subtitle options [options] by the name of its
/// upstream option: `color` (the route of plugin.title.js:158-160, the
/// first key that the theme writes), the order of the upstream defaults
/// (:145-156), then the other options. Dart `null` is a field that the
/// options do not set. `scripted` is not read: its type names the class of
/// the options.
Map<String, Object?> titleOptionFields(TitleBoxOptions<Object?> options) => {
  'color': options.color,
  'align': options.align,
  'display': options.display,
  'font': options.font,
  'fullSize': options.fullSize,
  'padding': options.padding,
  'position': options.position,
  'text': options.text,
  'weight': options.weight,
  'events': options.events,
};

/// The fields that the filler, colors, title or subtitle options [value]
/// set, in the order of [fillerOptionFields], [colorsOptionFields] or
/// [titleOptionFields], or Dart `null` for another value.
Map<String, Object>? setFillerColorsOptionFields(
  Object? value,
) => switch (value) {
  final FillerOptions options => {
    for (final MapEntry(:key, :value) in fillerOptionFields(options).entries)
      key: ?value,
  },
  final ColorsPluginOptions options => {
    for (final MapEntry(:key, :value) in colorsOptionFields(options).entries)
      key: ?value,
  },
  final TitleBoxOptions<Object?> options => {
    for (final MapEntry(:key, :value) in titleOptionFields(options).entries)
      key: ?value,
  },
  _ => null,
};
