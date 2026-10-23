// Ported from Chart.js v4.5.1+7169e651 test/specs/global.defaults.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

// `Chart.overrides` is the static getter of core.controller.dart. `toEqual`
// is jasmineEquals of test/support/jasmine.dart. Each case builds a chart:
// it is a `testWidgets` case with the harness of Chart.js ADR 0022, section
// 2. `chart.legend` is the field of `Chart`, and the spec reads
// `legendItems` through `types.LegendElement` (Chart.js ADR 0038, section
// 6).
//
// `spyOn(chart, 'update').and.callThrough()` (:110, :186) is _spyOnUpdate:
// a plugin whose beforeUpdate records each update of the chart (Chart.js
// ADR 0041, section 11 item 2). `Chart.update` stays a method.
// `expect(chart.update).toHaveBeenCalled()` is `expect(calls, isNotEmpty)`.

/// spyOn(chart, 'update').and.callThrough() (global.defaults.tests.js:110,
/// :186): a plugin whose beforeUpdate (core.controller.js:490) records the
/// mode of each update of [chart]. It unregisters at the end of the test.
List<Object?> _spyOnUpdate(Chart chart) {
  final calls = <Object?>[];
  final plugin = <String, Object?>{
    'id': r'$updateSpy',
    'beforeUpdate': (types.Chart c, AnyObject args, AnyObject options) {
      if (identical(c, chart)) calls.add(jsGet(args, 'mode'));
    },
  };
  Chart.register([plugin]);
  addTearDown(() => Chart.unregister([plugin]));
  return calls;
}

/// `Chart.overrides.<type>.plugins.legend.onClick` (:97, :113, :173, :189).
Object? _overrideOnClick(String type) => jsGet(
  jsGet(jsGet(jsGet(Chart.overrides, type), 'plugins'), 'legend'),
  'onClick',
);

/// The config of the doughnut and polar area cases of [type] (:4-15, :97-109,
/// :125-136, :174-185).
AnyObject _config(String type) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{
    'labels': <Object?>['label1', 'label2', 'label3'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[10, 20, double.nan],
        'backgroundColor': <Object?>['red', 'green', 'blue'],
        'borderWidth': 2,
        'borderColor': '#000',
      },
    ],
  },
};

void main() {
  group('Default Configs', () {
    group('Doughnut Chart', () {
      testWidgets('should return correct legend label objects', (
        tester,
      ) async {
        final chart = acquireChart(_config('doughnut'));

        final expectedCommon = <String, Object?>{
          'fontColor': '#666',
          'hidden': false,
          'strokeStyle': '#000',
          'textAlign': undefined,
          'lineWidth': 2,
          'pointStyle': undefined,
          'lineDash': <Object?>[],
          'lineDashOffset': 0,
          'lineJoin': undefined,
          'borderRadius': undefined,
        };

        final expected = <Object?>[
          <String, Object?>{
            'text': 'label1',
            'fillStyle': 'red',
            'index': 0,
            ...expectedCommon,
          },
          <String, Object?>{
            'text': 'label2',
            'fillStyle': 'green',
            'index': 1,
            ...expectedCommon,
          },
          <String, Object?>{
            'text': 'label3',
            'fillStyle': 'blue',
            'index': 2,
            ...expectedCommon,
          },
        ];
        expect(chart.legend!.legendItems, jasmineEquals(expected));
      });

      testWidgets(
        'should return correct legend label objects with border radius',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'doughnut',
            'data': <String, Object?>{
              'labels': <Object?>['label1'],
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[10],
                  'backgroundColor': <Object?>['red'],
                  'borderWidth': 2,
                  'borderColor': '#000',
                  'borderDash': <Object?>[1, 2, 3],
                  'borderDashOffset': 1,
                  'borderJoinStyle': 'miter',
                  'borderRadius': 3,
                },
              ],
            },
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'legend': <String, Object?>{
                  'labels': <String, Object?>{
                    'useBorderRadius': true,
                    'borderRadius': 5,
                    'textAlign': 'left',
                  },
                },
              },
            },
          });

          final expected = <Object?>[
            <String, Object?>{
              'text': 'label1',
              'fillStyle': 'red',
              'index': 0,
              'fontColor': '#666',
              'hidden': false,
              'strokeStyle': '#000',
              'textAlign': 'left',
              'lineWidth': 2,
              'pointStyle': undefined,
              'lineDash': <Object?>[1, 2, 3],
              'lineDashOffset': 1,
              'lineJoin': 'miter',
              'borderRadius': 5,
            },
          ];
          expect(chart.legend!.legendItems, jasmineEquals(expected));
        },
      );

      testWidgets('should hide the correct arc when a legend item is clicked', (
        tester,
      ) async {
        final onClick = _overrideOnClick('doughnut');
        final chart = acquireChart(_config('doughnut'));
        final calls = _spyOnUpdate(chart);

        final legendItem = chart.legend!.legendItems![0];
        jsCall(onClick, [null, legendItem, chart.legend]);

        expect(chart.getDataVisibility(0), false);
        expect(calls, isNotEmpty);

        jsCall(onClick, [null, legendItem, chart.legend]);
        expect(chart.getDataVisibility(0), true);
      });
    });

    group('Polar Area Chart', () {
      testWidgets('should return correct legend label objects', (
        tester,
      ) async {
        final chart = acquireChart(_config('polarArea'));

        final expected = <Object?>[
          <String, Object?>{
            'text': 'label1',
            'fillStyle': 'red',
            'fontColor': '#666',
            'hidden': false,
            'index': 0,
            'strokeStyle': '#000',
            'textAlign': undefined,
            'lineWidth': 2,
            'pointStyle': undefined,
          },
          <String, Object?>{
            'text': 'label2',
            'fillStyle': 'green',
            'fontColor': '#666',
            'hidden': false,
            'index': 1,
            'strokeStyle': '#000',
            'textAlign': undefined,
            'lineWidth': 2,
            'pointStyle': undefined,
          },
          <String, Object?>{
            'text': 'label3',
            'fillStyle': 'blue',
            'fontColor': '#666',
            'hidden': false,
            'index': 2,
            'strokeStyle': '#000',
            'textAlign': undefined,
            'lineWidth': 2,
            'pointStyle': undefined,
          },
        ];
        expect(chart.legend!.legendItems, jasmineEquals(expected));
      });

      testWidgets('should hide the correct arc when a legend item is clicked', (
        tester,
      ) async {
        final onClick = _overrideOnClick('polarArea');
        final chart = acquireChart(_config('polarArea'));
        final calls = _spyOnUpdate(chart);

        final legendItem = chart.legend!.legendItems![0];
        jsCall(onClick, [null, legendItem, chart.legend]);

        expect(chart.getDataVisibility(0), false);
        expect(calls, isNotEmpty);

        jsCall(onClick, [null, legendItem, chart.legend]);
        expect(chart.getDataVisibility(0), true);
      });
    });
  });
}
