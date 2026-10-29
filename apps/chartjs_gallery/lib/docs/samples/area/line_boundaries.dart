// Ported from Chart.js v4.6.1 docs/samples/area/line-boundaries.md (MIT, Chart.js Contributors).

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' show Chart;

/// The area chart of `docs/samples/area/line-boundaries.md:3-120` at the
/// fill `'origin'`: the action `Fill: origin` of `:48-56`.
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
/// - The first state of the sample is `fill: false` (`:29`). Each fill
///   action of `:39-74` is a variant of the page, with its fill value in
///   the dataset (Chart.js ADR 0031, Open "The Area `fill` control"). The
///   page has no actions: `Randomize` (`:76-82`) and `Smooth` (`:84-90`)
///   are not variants.
///
/// The options are those of `:95-113`. The gallery registers
/// `registerables`, with the filler and the title: the chart fills the
/// area to the origin, and the title is `Fill: origin`.
Map<String, Object?> areaOriginConfig() => _config('origin');

/// The config of the action `Fill: start` (`line-boundaries.md:57-65`):
/// the chart fills the area to the bottom of the value scale
/// (`src/plugins/plugin.filler/filler.options.js:82-83`).
Map<String, Object?> areaStartConfig() => _config('start');

/// The config of the action `Fill: end` (`line-boundaries.md:66-74`): the
/// chart fills the area to the top of the value scale
/// (`src/plugins/plugin.filler/filler.options.js:84-85`).
Map<String, Object?> areaEndConfig() => _config('end');

/// The config of the action `Fill: false (default)`
/// (`line-boundaries.md:39-47`), the first state of the sample (`:29`):
/// the chart draws the line with no fill.
Map<String, Object?> areaFalseConfig() => _config(false);

/// The config of `line-boundaries.md:95-113` with the data of `:20-33`,
/// where the dataset has the fill value [fill] of an action.
Map<String, Object?> _config(Object fill) => <String, Object?>{
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
        'fill': fill,
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
/// (`line-boundaries.md:106`). The context is a Map, and the fill of each
/// variant is a string or `false`: the interpolation gives the text of the
/// JS `+`.
Object _titleText(Object? ctx) {
  final chart = (ctx! as Map<String, Object?>)['chart']! as Chart;
  final datasets = chart.data['datasets']! as List<Object?>;
  final dataset = datasets.first! as Map<String, Object?>;
  return 'Fill: ${dataset['fill']}';
}
