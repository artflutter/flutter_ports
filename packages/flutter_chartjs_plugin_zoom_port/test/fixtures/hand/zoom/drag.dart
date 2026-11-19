// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/fixtures/zoom/drag.js (MIT, chartjs-plugin-zoom contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:math';

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

import '../../../flutter_test_config.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final data = <Object?>[];
  for (var i = 0; i < 100; i++) {
    data.add(<String, Object?>{'x': i, 'y': sin((i / 25) * pi) * 10});
  }

  return <String, Object?>{
    'tolerance': 0.004,
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{'data': data, 'borderColor': 'red'},
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          // DIVERGES(zoom): adapt-host-scale-display, the enum value.
          'x': <String, Object?>{'type': 'linear', 'display': ScaleDisplay.off},
          // DIVERGES(zoom): adapt-host-scale-display, the enum value.
          'y': <String, Object?>{'display': ScaleDisplay.off},
        },
        'plugins': <String, Object?>{
          'legend': false,
          'zoom': ZoomPluginOptions(
            zoom: ZoomOptions(
              drag: DragOptions(
                enabled: true,
                // The CSS color of a native option: a paint of the harness.
                backgroundColor: nativeFixturePaint('yellow'),
                borderColor: nativeFixturePaint('black'),
                borderWidth: 1,
              ),
            ),
          ),
        },
        'layout': <String, Object?>{'padding': const EdgeInsets.all(2)},
      },
    },
    'options': <String, Object?>{
      'run': (Chart chart) {
        final scaleX = chart.scales['x']!;
        final scaleY = chart.scales['y']!;
        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(5),
          y: scaleY.getPixelForValue(10),
        ));
        triggerMouseEvent(chart, 'mousemove', (
          x: scaleX.getPixelForValue(60),
          y: scaleY.getPixelForValue(0),
        ));
        // DIVERGES(zoom): harness-fixture-observations, render stays.
      },
    },
  };
}
