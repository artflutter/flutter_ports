// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/label-textAlign/rtl-right.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADRs 0115
/// and 0193).
library;

import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The config of the upstream file, as tool 4 decoded it, with the
/// legend options as one object. Each call makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'pie',
    'data': <String, Object?>{
      'labels': <Object?>['aaaa', 'bb', 'c'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[1, 2, 3],
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'legend': const LegendOptions(
          rtl: true,
          position: ChartPosition.right,
          labels: LegendLabelOptions(textAlign: TextAlign.right),
        ),
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 256, 'height': 256},
  },
};
