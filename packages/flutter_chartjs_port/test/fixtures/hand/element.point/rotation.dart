// Ported from Chart.js v4.6.1 test/fixtures/element.point/rotation.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  CanvasGradient? gradient;

  final datasets =
      <Object?>[
        'circle',
        'cross',
        'crossRot',
        'dash',
        'line',
        'rect',
        'rectRounded',
        'rectRot',
        'star',
        'triangle',
        false,
      ].indexed.map((entry) {
        final (y, style) = entry;
        return <String, Object?>{
          'pointStyle': style,
          // Upstream: Array.apply(null, Array(17)).map(function(v, x) {...}).
          'data': List<Object?>.generate(17, (x) {
            return <String, Object?>{'x': x, 'y': 11 - y};
          }),
        };
      }).toList();

  // Upstream: Array.apply(null, Array(17)).map(function(v, i) {...}).
  final angles = List<Object?>.generate(17, (i) {
    return -180 + i * 22.5;
  });

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'bubble',
      'data': <String, Object?>{
        'datasets': datasets,
      },
      'options': <String, Object?>{
        'responsive': false,
        'elements': <String, Object?>{
          'point': <String, Object?>{
            'rotation': angles,
            'radius': 10,
            'backgroundColor': (Object? context) {
              if (gradient == null) {
                final created = (jsGet(context, 'chart')! as Chart).ctx!
                    .createLinearGradient(0, 0, 512, 256);
                gradient = created;
                created
                  ..addColorStop(0, '#ff0000')
                  ..addColorStop(1, '#0000ff');
              }
              return gradient;
            },
            'borderColor': '#cccccc',
          },
        },
        'layout': <String, Object?>{
          'padding': 20,
        },
        'scales': <String, Object?>{
          'x': <String, Object?>{'display': false},
          'y': <String, Object?>{'display': false},
        },
      },
    },
    'options': <String, Object?>{
      'canvas': <String, Object?>{
        'height': 256,
        'width': 512,
      },
    },
  };
}
