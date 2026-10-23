// Ported from Chart.js v4.5.1+7169e651 test/specs/plugin.decimation.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;

// `Chart` is the class of core.controller.dart. Each case builds a chart, so
// the file runs on the VM, and each case is a `testWidgets` case with the
// harness of Chart.js ADR 0022, section 2.
//
// The spec forms:
// - `chart.data.datasets[0].data` is read with `jsGet`. The decimation
//   plugin keeps `data` as a plain entry with the value of the upstream
//   getter (differences.md row adapt-decimation-data-accessor).
// - `originalData` is a function: each case gets a new List of new item
//   Maps. Upstream shares the one array between the cases. No case changes
//   the array or its items, so the results are the same.
// - `toBe` of a number is `expect` with the number.
// - The first case keeps the upstream `scales` key at the root of the
//   config, where Chart.js does not read it.

/// The data of :6-16.
List<Object?> _originalData() => <Object?>[
  for (var i = 0; i < 10; i++) <String, Object?>{'x': i, 'y': i},
];

/// `chart.data.datasets[0].data`.
List<Object?> _data(Chart chart) =>
    jsGet(
          (jsGet(chart.data, 'datasets')! as List<Object?>)[0],
          'data',
        )!
        as List<Object?>;

/// The acquireChart options of a canvas and a wrapper of [width] x
/// [height].
AnyObject _canvas(int width, int height) => <String, Object?>{
  'canvas': <String, Object?>{'height': height, 'width': width},
  'wrapper': <String, Object?>{'height': height, 'width': width},
};

void main() {
  group('Plugin.decimation', () {
    group('auto', fixture.specs('plugin.decimation'));

    group('lttb', () {
      testWidgets('should draw all element if sample is greater than data '
          'based on canvas width', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': _originalData(),
                'label': 'dataset1',
              },
            ],
          },
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear', 'min': 0, 'max': 9},
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'decimation': <String, Object?>{
                'enabled': true,
                'algorithm': 'lttb',
                'samples': 100,
              },
            },
          },
        }, _canvas(1, 1));

        expect(_data(chart).length, 10);
      });

      testWidgets('should draw the specified number of elements based on '
          'canvas width', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': _originalData(),
                'label': 'dataset1',
              },
            ],
          },
          'options': <String, Object?>{
            'parsing': false,
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear', 'min': 0, 'max': 9},
            },
            'plugins': <String, Object?>{
              'decimation': <String, Object?>{
                'enabled': true,
                'algorithm': 'lttb',
                'samples': 7,
              },
            },
          },
        }, _canvas(1, 1));

        expect(_data(chart).length, 7);
      });

      testWidgets('should draw the specified number of elements based on '
          'threshold', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': _originalData(),
                'label': 'dataset1',
              },
            ],
          },
          'options': <String, Object?>{
            'parsing': false,
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear'},
            },
            'plugins': <String, Object?>{
              'decimation': <String, Object?>{
                'enabled': true,
                'algorithm': 'lttb',
                'samples': 5,
                'threshold': 7,
              },
            },
          },
        }, _canvas(100, 100));

        expect(_data(chart).length, 5);
      });

      testWidgets('should draw all element only in range', (tester) async {
        final originalData = _originalData();
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': originalData, 'label': 'dataset1'},
            ],
          },
          'options': <String, Object?>{
            'parsing': false,
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear', 'min': 3, 'max': 6},
            },
            'plugins': <String, Object?>{
              'decimation': <String, Object?>{
                'enabled': true,
                'algorithm': 'lttb',
                'samples': 7,
              },
            },
          },
        }, _canvas(1, 1));

        // Data range is 4 (3->6) and the first point is added
        const expectedPoints = 5;
        final data = _data(chart);
        expect(data.length, expectedPoints);
        expect(jsGet(data[0], 'x'), jsGet(originalData[2], 'x'));
        expect(jsGet(data[1], 'x'), jsGet(originalData[3], 'x'));
        expect(jsGet(data[2], 'x'), jsGet(originalData[4], 'x'));
        expect(jsGet(data[3], 'x'), jsGet(originalData[5], 'x'));
        expect(jsGet(data[4], 'x'), jsGet(originalData[6], 'x'));
      });

      testWidgets('should not crash with uneven points', (tester) async {
        final data = <Object?>[];
        for (var i = 0; i < 15552; i++) {
          data.add(<String, Object?>{'x': i, 'y': i});
        }

        Chart createChart() => acquireChart(
          <String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{'data': data},
              ],
            },
            'options': <String, Object?>{
              'devicePixelRatio': 1.25,
              'parsing': false,
              'scales': <String, Object?>{
                'x': <String, Object?>{'type': 'linear'},
              },
              'plugins': <String, Object?>{
                'decimation': <String, Object?>{
                  'enabled': true,
                  'algorithm': 'lttb',
                },
              },
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'width': 511, 'height': 511},
          },
        );
        expect(createChart, returnsNormally);
      });
    });
  });
}
