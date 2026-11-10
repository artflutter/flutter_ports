// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/fixtures/zoom/update-reset.js (MIT, chartjs-plugin-zoom contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show ZoomChart;
import 'package:flutter_chartjs_port/chartjs.dart' show Chart, JsObjectFace;
import 'package:flutter_chartjs_port/helpers.dart' show clearCanvas;

import '../../observe.dart' as observe;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final labels = <Object?>['a', 'b', 'c', 'd'];
  final data = <Object?>[2, 4, 8, 16];

  // DIVERGES(zoom): harness-fixture-observations, no sprite canvas.
  // The sprite draws the chart and the text [descr] in the next cell.
  void snapshot(Chart chart, String descr) {
    // DIVERGES(zoom): harness-fixture-observations, for the sprite.
    observe.snapshot(chart);
  }

  return <String, Object?>{
    'tolerance': 0.0018,
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'labels': labels,
        'datasets': <Object?>[
          <String, Object?>{
            'data': data,
            'borderColor': 'red',
            'borderWidth': 10,
          },
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{'y': <String, Object?>{}},
        'plugins': <String, Object?>{'legend': false},
      },
    },
    'options': <String, Object?>{
      'spriteText': true,
      'run': (Chart chart) {
        snapshot(chart, 'original');

        chart.zoomScale('y', (min: 3, max: 9));
        snapshot(chart, 'zoom 3..9');

        chart.resetZoom();
        snapshot(chart, 'reset');

        (chart.options['scales']! as JsObjectFace)['y'] = <String, Object?>{
          'min': 0,
          'max': 25,
        };
        chart.update();
        snapshot(chart, 'update 0..25');

        chart.resetZoom();
        snapshot(chart, 'reset');

        chart.zoomScale('y', (min: 5, max: 15));
        snapshot(chart, 'zoom 5..15');

        chart.resetZoom();
        snapshot(chart, 'reset');

        (chart.options['scales']! as JsObjectFace)['y'] = <String, Object?>{
          'min': 1,
          'max': 10,
        };
        chart.update();
        snapshot(chart, 'update 1..10');

        chart.resetZoom();
        snapshot(chart, 'reset');

        clearCanvas(chart.canvas);
        // chart.ctx.drawImage(canvas, 0, 0, 512, 512): image only.
      },
    },
  };
}
