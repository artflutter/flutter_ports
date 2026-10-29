// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/dataset/interpolated.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:math' as math;

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// The module loop makes the data with `Math.sin` and `Math.cos`. The smoke
/// test of the fixture asserts no value, so `dart:math` is sufficient
/// (Chart.js ADR 0034).
Map<String, Object?> fixture() {
  final data1 = <Object?>[];
  final data2 = <Object?>[];
  final data3 = <Object?>[];
  for (var i = 0; i < 200; i++) {
    final a = i / math.pi / 10;

    data1.add(<String, Object?>{
      'x': i,
      // js-ok: fixture data only, the smoke test asserts no value.
      'y': i < 86 || i > 104 && i < 178 ? math.sin(a) : double.nan,
    });

    // js-ok: i is an int and never negative, so Dart % equals JS %.
    if (i % 10 == 0) {
      // js-ok: fixture data only, the smoke test asserts no value.
      data2.add(<String, Object?>{'x': i, 'y': math.cos(a)});
    }

    // js-ok: i is an int and never negative, so Dart % equals JS %.
    if (i % 15 == 0) {
      // js-ok: fixture data only, the smoke test asserts no value.
      data3.add(<String, Object?>{'x': i, 'y': math.cos(a + math.pi / 2)});
    }
  }

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'borderColor': 'rgba(255, 0, 0, 0.5)',
            'backgroundColor': 'rgba(255, 0, 0, 0.25)',
            'data': data1,
            'fill': false,
          },
          <String, Object?>{
            'borderColor': 'rgba(0, 0, 255, 0.5)',
            'backgroundColor': 'rgba(0, 0, 255, 0.25)',
            'data': data2,
            'fill': 0,
          },
          <String, Object?>{
            'borderColor': 'rgba(0, 255, 0, 0.5)',
            'backgroundColor': 'rgba(0, 255, 0, 0.25)',
            'data': data3,
            'fill': 1,
          },
        ],
      },
      'options': <String, Object?>{
        'animation': false,
        'responsive': false,
        'datasets': <String, Object?>{
          'line': <String, Object?>{
            'tension': 0.4,
            'borderWidth': 1,
            'pointRadius': 1.5,
          },
        },
        'plugins': <String, Object?>{
          'legend': false,
          'title': false,
          'tooltip': false,
        },
        'scales': <String, Object?>{
          'x': <String, Object?>{'type': 'linear', 'display': false},
          'y': <String, Object?>{'type': 'linear', 'display': false},
        },
      },
    },
    'options': <String, Object?>{
      'canvas': <String, Object?>{'height': 512, 'width': 512},
    },
  };
}
