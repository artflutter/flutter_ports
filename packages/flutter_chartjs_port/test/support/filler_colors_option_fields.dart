// Original code, not ported from Chart.js: the filler and colors option fields.

/// The fields of a [FillerOptions] and of a [ColorsPluginOptions] by the
/// name of their option (Chart.js ADR 0196), for the tests that compare the
/// options with a path, for example `plugins.colors.borderColors`.
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

/// The fields that the filler or colors options [value] set, in the order of
/// [fillerOptionFields] or [colorsOptionFields], or Dart `null` for another
/// value.
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
  _ => null,
};
