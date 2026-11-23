// Original code, not ported from Chart.js: plain copies of plugin options.

/// The plain Maps of the option objects of the title and the subtitle
/// (Chart.js ADR 0197), with the upstream keys, for the comparisons with the
/// reference data.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The plain Map of the title or subtitle options [options] of a box, with
/// the keys of `TitleOptions` of `index.d.ts` and `weight`. Dart `null`
/// stays Dart `null`.
Map<String, Object?>? plainTitleOptions(TitleBoxOptions<Object?>? options) =>
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
