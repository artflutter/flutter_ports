// Ported from Chart.js v4.6.1 test/fixtures/element.point/point-style-image.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  // The type argument is the canvas class of the canvas layer: the point
  // style below needs its `toImageSource()`.
  final imageCanvas = document.createElement<UiCanvasElement>('canvas');
  final imageContext = imageCanvas.getContext('2d')!;

  imageCanvas
    ..width = 40
    ..height = 40;

  imageContext
    ..fillStyle = '#f00'
    ..beginPath()
    ..moveTo(20, 0)
    ..lineTo(10, 40)
    ..lineTo(20, 30)
    ..closePath()
    ..fill()
    ..fillStyle = '#a00'
    ..beginPath()
    ..moveTo(20, 0)
    ..lineTo(30, 40)
    ..lineTo(20, 30)
    ..closePath()
    ..fill();

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'labels': <Object?>[0, 1, 2, 3, 4, 5, 6, 7],
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[0, 0, 0, 0, 0, 0, 0, 0],
            'showLine': false,
          },
        ],
      },
      'options': <String, Object?>{
        'responsive': false,
        'elements': <String, Object?>{
          'point': <String, Object?>{
            // Upstream: pointStyle: imageCanvas. The DOM draws the bitmap of
            // the canvas element. The canvas layer draws an image source:
            // the snapshot of the bitmap, which does not change after this
            // line (FR section 4.1 rule 7).
            'pointStyle': imageCanvas.toImageSource(),
            'rotation': <Object?>[0, 45, 90, 135, 180, 225, 270, 315],
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
