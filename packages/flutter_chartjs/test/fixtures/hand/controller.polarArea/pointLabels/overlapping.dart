// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.polarArea/pointLabels/overlapping.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/core/core.controller.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'polarArea',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': List<Object?>.filled(50, 5, growable: true),
          'backgroundColor': <Object?>['#f003', '#0f03', '#00f3', '#0003'],
        },
      ],
      // `new Array(50).fill(0).map((el, i) => ...)`: `indexed` gives `i`.
      'labels': <Object?>[
        for (final (i, _) in List<Object?>.filled(50, 0).indexed)
          <Object?>['label $i', 'line 2'],
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'r': <String, Object?>{
          'pointLabels': <String, Object?>{
            'display': true,
          },
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'run': (Chart chart) {
      // Avoid browser-specific interpolation of the overlapping text sprites.
      // DIVERGES(chartjs): harness-fixture-sources, no imageSmoothingEnabled.
      // `chart.ctx.imageSmoothingEnabled = false`: the canvas layer has no
      // `imageSmoothingEnabled`. The port draws no text sprite
      // (`spriteText` is n/a, Chart.js ADR 0022 section 4 item 5) and
      // compares no image (Chart.js ADR 0034), so the write has no effect.
      chart.draw();
    },
  },
};
