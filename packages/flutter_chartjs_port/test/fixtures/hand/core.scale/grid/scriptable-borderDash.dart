// Ported from Chart.js v4.6.1 test/fixtures/core.scale/grid/scriptable-borderDash.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableScaleContext;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/types/axis_border.dart';
import 'package:flutter_chartjs_port/src/types/layout.dart'
    show ScaleValuePosition;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'scatter',
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          // DIVERGES(chartjs): adapt-chart-position-enum, the object form.
          'position': const ScaleValuePosition('y', 0),
          'min': -10,
          'max': 10,
          // DIVERGES(chartjs): adapt-native-scale-border, one function of
          // the context gives the border object, where upstream gives the
          // dash. The scale calls it with each tick context.
          'border': _border,
          'grid': <String, Object?>{'color': 'lightGray', 'lineWidth': 3},
          'ticks': <String, Object?>{'display': false},
        },
        'y': <String, Object?>{
          // DIVERGES(chartjs): adapt-chart-position-enum, the object form.
          'position': const ScaleValuePosition('x', 0),
          'min': -10,
          'max': 10,
          // DIVERGES(chartjs): adapt-native-scale-border, one function of
          // the context gives the border object, where upstream gives the
          // dash. The scale calls it with each tick context.
          'border': _border,
          'grid': <String, Object?>{'color': 'lightGray', 'lineWidth': 3},
          'ticks': <String, Object?>{'display': false},
        },
      },
    },
  },
};

/// The border of the context [ctx]: `dash: (ctx) => ctx.index % 2 === 0 ?
/// [6, 3] : []`. The scale context has no index: its `undefined % 2` is NaN,
/// which gives the solid dash.
AxisBorder _border(ScriptableScaleContext ctx) => AxisBorder(
  dash: jsToNumber(ctx.index).remainder(2) == 0
      ? const <double>[6, 3]
      : const <double>[],
);
