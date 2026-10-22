// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.line/issue-8902.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/8902',
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[1, 2, 3, 4, 5, 6, 7, 8],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[65, 59, double.nan, 48, 56, 57, 40],
          'borderColor': 'rgb(75, 192, 192)',
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': false,
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'linear',
          'min': 1,
          'max': 3,
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{
      'height': 256,
      'width': 512,
    },
  },
};
