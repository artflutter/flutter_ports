// Original code, not ported from Chart.js: plain copies of plugin options.

/// The plain Maps of the resolved option classes of the built-in plugins
/// (Chart.js ADR 0182), with the upstream keys, for the comparisons with the
/// reference data.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The plain Map of the title options [options], with the keys of
/// `TitleOptions` of `index.d.ts`. Dart `null` stays Dart `null`.
Map<String, Object?>? plainTitleOptions(TitleOptions? options) =>
    options == null
    ? null
    : <String, Object?>{
        'align': options.align,
        'color': options.color,
        'display': options.display,
        'font': options.font,
        'fullSize': options.fullSize,
        'padding': options.padding,
        'position': options.position,
        'text': options.text,
        'weight': options.weight,
      };
