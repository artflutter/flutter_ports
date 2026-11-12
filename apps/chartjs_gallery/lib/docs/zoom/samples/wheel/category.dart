// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 docs/samples/wheel/category.md (MIT, chartjs-plugin-zoom contributors).

import 'dart:ui' as ui;

import 'package:chartjs_gallery/docs/zoom/samples/basic.dart';
import 'package:chartjs_gallery/docs/zoom/scripts/defaults.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show Mode, ZoomChart;

/// The sample `Category Scale` of `docs/samples/wheel/category.md:3-93`: a
/// bar chart of 20 months that shows the months 5 to 11 first, zooms with
/// the wheel and a pinch, and pans with a drag of more than 5 pixels.
///
/// The gallery changes the sample in these items:
/// - The labels are the strings of `Utils.months({count: 20})`
///   (`docs/scripts/utils.js:70-83`).
/// - The data is the result of `Utils.numbers` of `:13`, `:18` and `:23`
///   with the seed 2026 (`utils.js:12-41`), in place of the seed
///   `Date.now()` (`utils.js:6`): the probe of [zoomSampleData].
/// - Each `Utils.randomColor(alpha)` (`utils.js:49-53`) is a fixed color
///   with that alpha: the red, the blue and the teal of the Chart.js docs
///   for the datasets, and grey for the grid border. The colors are `Color`
///   values (Chart.js ADR 0061).
/// - The options get the docs defaults (`setZoomDocsDefaults`).
///
/// The sample has no `console.log`: [log] gets no line.
ZoomDocsSample zoomWheelCategorySample(ZoomDocsLog log) {
  // <block:data:1>
  final data = <String, Object?>{
    'labels': <Object?>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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
        'label': 'Dataset 1',
        'borderColor': _color(_red, 0.7),
        'backgroundColor': _color(_red, 0.5),
        'data': <Object?>[
          97.80778464,
          -42.30366941,
          84.04578189,
          -46.60065158,
          -31.77383402,
          12.47685185,
          -59.52760631,
          -0.87362826,
          -16.4994856,
          -74.30641289,
          -82.93638546,
          63.78343621,
          -24.27040466,
          -11.29543896,
          -80.00771605,
          -42.75291495,
          80.71587791,
          18.79372428,
          -63.08727709,
          59.76423182,
        ],
      },
      <String, Object?>{
        'label': 'Dataset 2',
        'borderColor': _color(_blue, 0.7),
        'backgroundColor': _color(_blue, 0.5),
        'data': <Object?>[
          26.85442387,
          -18.60682442,
          -7.48371056,
          10.84104938,
          -42.64489026,
          -54.36128258,
          37.42026749,
          -68.53480796,
          -14.20181756,
          -26.74125514,
          -29.60991084,
          -20.33864883,
          85.02314815,
          -59.20353224,
          -6.10510974,
          39.38014403,
          -90.64900549,
          95.16546639,
          -97.00360082,
          -57.27966392,
        ],
      },
      <String, Object?>{
        'label': 'Dataset 3',
        'borderColor': _color(_teal, 0.7),
        'backgroundColor': _color(_teal, 0.5),
        'data': <Object?>[
          -49.86025377,
          -57.46141975,
          -92.42884088,
          25.48439643,
          24.67335391,
          70.57013032,
          -12.13391632,
          16.06738683,
          98.38391632,
          -96.04852538,
          -16.61265432,
          57.67918381,
          40.40723594,
          -6.70010288,
          15.12259945,
          63.90003429,
          -87.52829218,
          37.3808299,
          41.09653635,
          7.56944444,
        ],
      },
    ],
  };
  // </block:data>

  // <block:scales:2>
  final scaleOpts = <String, Object?>{
    'grid': <String, Object?>{
      'borderColor': _color(_grey, 1),
      'color': const ui.Color.fromRGBO(0, 0, 0, 0.1),
    },
    'title': <String, Object?>{'display': true, 'text': zoomAxisTitle},
  };
  final scales = <String, Object?>{
    'x': <String, Object?>{'type': 'category', 'min': 5.0, 'max': 11.0},
    'y': <String, Object?>{'type': 'linear'},
  };
  for (final scale in scales.values) {
    (scale! as Map<String, Object?>).addAll(scaleOpts);
  }
  // </block:scales>

  // <block:config:0>
  final config = <String, Object?>{
    'type': 'bar',
    'data': data,
    'options': <String, Object?>{
      'scales': scales,
      'plugins': <String, Object?>{
        'zoom': <String, Object?>{
          'pan': <String, Object?>{
            'enabled': true,
            'mode': Mode.xy,
            'threshold': 5.0,
          },
          'zoom': <String, Object?>{
            'wheel': <String, Object?>{'enabled': true},
            'pinch': <String, Object?>{'enabled': true},
            'mode': Mode.xy,
          },
        },
      },
    },
  };
  // </block:config>
  setZoomDocsDefaults(config['options']! as Map<String, Object?>);

  final actions = <ZoomDocsAction>[
    (name: 'Reset zoom', handler: (chart) => chart.resetZoom(), isOn: null),
  ];

  return (actions: actions, config: config, output: null);
}

/// The red, the blue, the teal and the grey of the Chart.js docs.
const (int, int, int) _red = (255, 99, 132);
const (int, int, int) _blue = (54, 162, 235);
const (int, int, int) _teal = (75, 192, 192);
const (int, int, int) _grey = (201, 203, 207);

/// The color [rgb] with [alpha].
ui.Color _color((int, int, int) rgb, double alpha) =>
    ui.Color.fromRGBO(rgb.$1, rgb.$2, rgb.$3, alpha);
