// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 docs/samples/basic.md (MIT, chartjs-plugin-zoom contributors).

import 'dart:ui' as ui;

import 'package:chartjs_gallery/docs/zoom/scripts/defaults.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show Mode, ZoomChart, ZoomChartContext;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show Chart, ChartEvent, ChartPosition, JsObjectFace, Scale;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsNumberToString;

/// A sample of the docs of chartjs-plugin-zoom: the `module.exports` of its
/// `chart-editor` block (`{actions, config, output}`).
///
/// - `config`: the chart config, new for each call of the sample.
/// - `actions`: the buttons of the docs page under the chart, in their
///   order.
/// - `output`: the first text of the output pane of the docs page, or
///   `null` for a sample without `output`.
typedef ZoomDocsSample = ({
  Map<String, Object?> config,
  List<ZoomDocsAction> actions,
  String? output,
});

/// An action of a sample (`{name, handler(chart)}`).
///
/// The gallery adds `isOn`: for an action that turns an option on and off,
/// it reads that option, so that the segment of the action shows its state.
/// It is `null` for an action that is a command.
typedef ZoomDocsAction = ({
  String name,
  void Function(Chart chart) handler,
  bool Function(Chart chart)? isOn,
});

/// The console of a docs page: `console.log` of a sample writes a line into
/// the output pane.
typedef ZoomDocsLog = void Function(String line);

/// The sample `Basic` of `docs/samples/basic.md:3-132`: a scatter chart that
/// zooms with the wheel and a pinch, and pans with a drag, in the limits of
/// `:55-58`.
///
/// The gallery changes the sample in these items:
/// - The data is the result of `Utils.points` of `:14` and `:22` with the
///   seed 2026 (`docs/scripts/utils.js:12-47`), in place of the seed
///   `Date.now()` (`utils.js:6`), as [zoomSampleData] says.
/// - Each `Utils.randomColor(alpha)` (`utils.js:49-53`) is a fixed color
///   with that alpha: the red and the blue of the Chart.js docs for the
///   datasets, and grey for the grid border. The colors are `Color` values
///   (Chart.js ADR 0061): `'rgba( 0, 0, 0, 0.1)'` of `:35` is
///   `Color.fromRGBO(0, 0, 0, 0.1)`.
/// - The options get the docs defaults (`setZoomDocsDefaults`).
/// - `console.log(e.type)` of `onClick` (`:98-100`) writes into [log].
ZoomDocsSample zoomBasicSample(ZoomDocsLog log) {
  // <block:data:1>
  final data = zoomSampleData();
  // </block:data>

  // <block:scales:2>
  final scales = zoomSampleScales();
  // </block:scales>

  // <block:zoom:0>
  // `zoomOptions.pan`, `zoomOptions.zoom.wheel` and
  // `zoomOptions.zoom.pinch` are locals, so that the actions read and write
  // them as the upstream handlers do.
  final pan = <String, Object?>{'enabled': true, 'mode': Mode.xy};
  final wheel = <String, Object?>{'enabled': true};
  final pinch = <String, Object?>{'enabled': true};
  final zoomOptions = <String, Object?>{
    'limits': <String, Object?>{
      'x': <String, Object?>{'min': -200.0, 'max': 200.0, 'minRange': 50.0},
      'y': <String, Object?>{'min': -200.0, 'max': 200.0, 'minRange': 50.0},
    },
    'pan': pan,
    'zoom': <String, Object?>{
      'wheel': wheel,
      'pinch': pinch,
      'mode': Mode.xy,
      'onZoomComplete': (ZoomChartContext context) {
        // This update is needed to display up to date zoom level in the
        // title. Without this, previous zoom level is displayed. The reason
        // is: title uses the same beforeUpdate hook, and is evaluated before
        // zoom.
        context.chart.update('none');
      },
    },
  };
  // </block:zoom>

  String panStatus() => pan['enabled'] == true ? 'enabled' : 'disabled';
  // The zoom level is a number in the text: its JS text, as `+` gives it.
  String zoomStatus(Chart chart) =>
      '${wheel['enabled'] == true ? 'enabled' : 'disabled'} '
      '(${jsNumberToString(chart.getZoomLevel())}x)';

  // <block:config:1>
  final config = <String, Object?>{
    'type': 'scatter',
    'data': data,
    'options': <String, Object?>{
      'scales': scales,
      'plugins': <String, Object?>{
        'zoom': zoomOptions,
        'title': <String, Object?>{
          'display': true,
          'position': ChartPosition.bottom,
          'text': (Object? ctx) =>
              'Zoom: ${zoomStatus(_chartOf(ctx))}, Pan: ${panStatus()}',
        },
      },
      'onClick': (Object? e) {
        log((e! as ChartEvent).type);
      },
    },
  };
  // </block:config>
  setZoomDocsDefaults(config['options']! as Map<String, Object?>);

  final actions = <ZoomDocsAction>[
    (
      name: 'Toggle zoom',
      handler: (chart) {
        wheel['enabled'] = wheel['enabled'] != true;
        pinch['enabled'] = pinch['enabled'] != true;
        chart.update();
      },
      isOn: (_) => wheel['enabled'] == true,
    ),
    (
      name: 'Toggle pan',
      handler: (chart) {
        pan['enabled'] = pan['enabled'] != true;
        chart.update();
      },
      isOn: (_) => pan['enabled'] == true,
    ),
    (name: 'Reset zoom', handler: (chart) => chart.resetZoom(), isOn: null),
  ];

  return (actions: actions, config: config, output: 'Clicks are logged here');
}

/// The data block of `docs/samples/basic.md:4-25`: two datasets of 20
/// points in -100 to 100.
///
/// `Utils.points(NUMBER_CFG)` with the seed 2026: the probe runs the
/// functions `rand`, `numbers` and `points` of `docs/scripts/utils.js:12-47`
/// at the pin on Node.js v24.22.1 after `srand(2026)`, and the lists below
/// are its values. `Utils.randomColor` does not read the seed (`:49`).
///
/// The samples `drag/linear.md:6-27` and `pan/toggle.md:6-27` have the same
/// block, so they take the same values.
Map<String, Object?> zoomSampleData() => <String, Object?>{
  'datasets': <Object?>[
    <String, Object?>{
      'label': 'My First dataset',
      'borderColor': _red(0.4),
      'backgroundColor': _red(0.1),
      'pointBorderColor': _red(0.7),
      'pointBackgroundColor': _red(0.5),
      'pointBorderWidth': 1.0,
      'data': <Object?>[
        _p(97.80778464, 26.85442387),
        _p(-42.30366941, -18.60682442),
        _p(84.04578189, -7.48371056),
        _p(-46.60065158, 10.84104938),
        _p(-31.77383402, -42.64489026),
        _p(12.47685185, -54.36128258),
        _p(-59.52760631, 37.42026749),
        _p(-0.87362826, -68.53480796),
        _p(-16.4994856, -14.20181756),
        _p(-74.30641289, -26.74125514),
        _p(-82.93638546, -29.60991084),
        _p(63.78343621, -20.33864883),
        _p(-24.27040466, 85.02314815),
        _p(-11.29543896, -59.20353224),
        _p(-80.00771605, -6.10510974),
        _p(-42.75291495, 39.38014403),
        _p(80.71587791, -90.64900549),
        _p(18.79372428, 95.16546639),
        _p(-63.08727709, -97.00360082),
        _p(59.76423182, -57.27966392),
      ],
    },
    <String, Object?>{
      'label': 'My Second dataset',
      'borderColor': _blue(0.4),
      'backgroundColor': _blue(0.1),
      'pointBorderColor': _blue(0.7),
      'pointBackgroundColor': _blue(0.5),
      'pointBorderWidth': 1.0,
      'data': <Object?>[
        _p(-49.86025377, -8.87945816),
        _p(-57.46141975, 38.66340878),
        _p(-92.42884088, -54.74022634),
        _p(25.48439643, -56.99159808),
        _p(24.67335391, -76.73268176),
        _p(70.57013032, -7.79063786),
        _p(-12.13391632, -40.28892318),
        _p(16.06738683, -38.42506859),
        _p(98.38391632, 15.08487654),
        _p(-96.04852538, -92.1047668),
        _p(-16.61265432, 20.25291495),
        _p(57.67918381, 80.55298354),
        _p(40.40723594, 54.22753772),
        _p(-6.70010288, -34.03206447),
        _p(15.12259945, 55.28034979),
        _p(63.90003429, 65.37465706),
        _p(-87.52829218, 65.38665981),
        _p(37.3808299, 5.93364198),
        _p(41.09653635, 8.00325789),
        _p(7.56944444, -14.82424554),
      ],
    },
  ],
};

/// The scales block of `docs/samples/basic.md:27-51`: both axes reversed,
/// x on top and y on the right, with no first and last tick label.
///
/// `Object.assign(scales[scale], scaleOpts)` (`:50`) is `addAll`: both
/// scales share the objects `ticks`, `grid` and `title`, as upstream. The
/// key `grid.borderColor` (`:34`) is an option of Chart.js 3: Chart.js 4
/// draws the axis line with `border.color`, so the key draws nothing, as in
/// the docs. The sample `drag/linear.md:29-53` has the same block.
Map<String, Object?> zoomSampleScales() {
  final scaleOpts = <String, Object?>{
    'reverse': true,
    'ticks': <String, Object?>{
      'callback': (Object? val, Object? index, Object? ticks) =>
          index == 0 || index == (ticks! as List<Object?>).length - 1
          ? null
          : val,
    },
    'grid': <String, Object?>{
      'borderColor': _grey(1),
      'color': const ui.Color.fromRGBO(0, 0, 0, 0.1),
    },
    'title': <String, Object?>{'display': true, 'text': zoomAxisTitle},
  };
  final scales = <String, Object?>{
    'x': <String, Object?>{'position': ChartPosition.top},
    'y': <String, Object?>{'position': ChartPosition.right},
  };
  for (final scale in scales.values) {
    (scale! as Map<String, Object?>).addAll(scaleOpts);
  }
  return scales;
}

/// `(ctx) => ctx.scale.axis + ' axis'`, the scale title of the samples. The
/// context is a typed object, read by name through its face.
String zoomAxisTitle(Object? ctx) =>
    '${((ctx! as JsObjectFace)['scale']! as Scale).axis} axis';

/// `ctx.chart` of a scriptable context: a typed object, read by name
/// through its face.
Chart _chartOf(Object? ctx) => (ctx! as JsObjectFace)['chart']! as Chart;

/// A point `{x, y}` of `Utils.points` (`docs/scripts/utils.js:46`).
Map<String, Object?> _p(double x, double y) => <String, Object?>{
  'x': x,
  'y': y,
};

/// The red of the Chart.js docs, `rgb(255, 99, 132)`, with [alpha].
ui.Color _red(double alpha) => ui.Color.fromRGBO(255, 99, 132, alpha);

/// The blue of the Chart.js docs, `rgb(54, 162, 235)`, with [alpha].
ui.Color _blue(double alpha) => ui.Color.fromRGBO(54, 162, 235, alpha);

/// The grey of the Chart.js docs, `rgb(201, 203, 207)`, with [alpha].
ui.Color _grey(double alpha) => ui.Color.fromRGBO(201, 203, 207, alpha);
