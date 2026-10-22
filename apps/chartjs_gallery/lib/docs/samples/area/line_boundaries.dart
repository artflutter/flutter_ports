// Ported from Chart.js v4.5.1+7169e651 docs/samples/area/line-boundaries.md (MIT, Chart.js Contributors).

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The gallery imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsAdd;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// The area chart of `docs/samples/area/line-boundaries.md:3-120`, at the
/// fill `'origin'`.
///
/// The gallery changes the sample in these items (Chart.js ADR 0031,
/// section 1.2):
/// - The labels are the strings of `Utils.months({count: 8})`
///   (`docs/scripts/utils.js:91-104`).
/// - The data is the result of `Utils.numbers` of `:4-17` with the seed
///   2026 (`utils.js:13-43`, probe P4 of Chart.js ADR 0031), in place of
///   the seed `Date.now()` (`utils.js:7`).
/// - The colors are the values of `Utils.CHART_COLORS.red` and
///   `Utils.transparentize(Utils.CHART_COLORS.red)` (`utils.js:122-135`).
/// - The first state of the sample is `fill: false` (`:29`). The gallery
///   shows the state of the action `Fill: origin` (`:48-56`). The page has
///   no actions.
///
/// The options are those of `:95-113`. Phase 7 registers no plugin: the
/// chart draws the line, and `initialize` prints the `fill` warning once
/// (core.datasetController.js:280-289). Phase 8 registers the filler and
/// the title, and this config then fills the area with no change.
AnyObject areaOriginConfig() => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'labels': <Object?>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
    ],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Dataset',
        'data': <Object?>[
          97.81,
          -42.3,
          84.05,
          -46.6,
          -31.77,
          12.48,
          -59.53,
          -0.87,
        ],
        'borderColor': 'rgb(255, 99, 132)',
        'backgroundColor': 'rgba(255, 99, 132, 0.5)',
        'fill': 'origin',
      },
    ],
  },
  'options': <String, Object?>{
    'plugins': <String, Object?>{
      'filler': <String, Object?>{'propagate': false},
      'title': <String, Object?>{'display': true, 'text': _titleText},
    },
    'interaction': <String, Object?>{'intersect': false},
  },
};

/// `(ctx) => 'Fill: ' + ctx.chart.data.datasets[0].fill`
/// (`line-boundaries.md:106`).
Object _titleText(Object? ctx) {
  final chart = jsGet(ctx, 'chart')! as Chart;
  final dataset = jsGet(jsGet(chart.data, 'datasets'), 0);
  return jsAdd('Fill: ', jsGet(dataset, 'fill'));
}
