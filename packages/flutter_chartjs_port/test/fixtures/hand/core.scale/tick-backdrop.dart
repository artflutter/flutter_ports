// Ported from Chart.js v4.6.1 test/fixtures/core.scale/tick-backdrop.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart';
import 'package:flutter_chartjs_port/src/types/layout.dart';

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'options': <String, Object?>{
      'events': <Object?>[],
      'scales': <String, Object?>{
        'top': <String, Object?>{
          'type': 'linear',
          'position': ChartPosition.top,
          'ticks': <String, Object?>{
            'display': true,
            'showLabelBackdrop': true,
            'backdropColor': 'red',
            'backdropPadding': const EdgeInsets.all(5),
            'align': TickAlign.start,
            'crossAlign': TickCrossAlign.near,
          },
          'grid': <String, Object?>{'display': false},
          'title': <String, Object?>{'display': false},
        },
        'left': <String, Object?>{
          'type': 'linear',
          'position': ChartPosition.left,
          'ticks': <String, Object?>{
            'display': true,
            'showLabelBackdrop': true,
            'backdropColor': 'green',
            'backdropPadding': const EdgeInsets.all(5),
            'crossAlign': TickCrossAlign.center,
          },
          'grid': <String, Object?>{'display': false},
          'title': <String, Object?>{'display': false},
        },
        'bottom': <String, Object?>{
          'type': 'linear',
          'position': ChartPosition.bottom,
          'ticks': <String, Object?>{
            'display': true,
            'showLabelBackdrop': true,
            'backdropColor': 'blue',
            'backdropPadding': const EdgeInsets.all(5),
            'align': TickAlign.end,
            'crossAlign': TickCrossAlign.far,
          },
          'grid': <String, Object?>{'display': false},
          'title': <String, Object?>{'display': false},
        },
        'right': <String, Object?>{
          'type': 'linear',
          'position': ChartPosition.right,
          'ticks': <String, Object?>{
            'display': true,
            'showLabelBackdrop': true,
            'backdropColor': 'gray',
            'backdropPadding': const EdgeInsets.all(5),
          },
          'grid': <String, Object?>{'display': false},
          'title': <String, Object?>{'display': false},
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256.0, 'width': 256.0},
    'spriteText': true,
  },
};
