// Ported from Chart.js v4.6.1 test/specs/controller.scatter.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// `Chart` is the class of core.controller.dart. The spec runs on the VM: a
// chart reaches the chart host and dart:ui. Each chart case is a
// `testWidgets` case with the harness of Chart.js ADR 0022, section 2. The
// conventions are those of Chart.js ADR 0030, section 13.
//
// flutter_test_config.dart registers the scatter controller with the
// built-in components before main(), as index.umd.ts:28 does (Chart.js ADR
// 0030, section 3 item 4).
//
// The spec forms:
// - `Chart.controllers` is `registry.controllers.items` (index.umd.ts:35):
//   `Chart.registry.controllers.items`.
// - `Chart.elements.LineElement` is the class LineElement of
//   element.line.dart. `x instanceof C` is `x is C`.
// - `toEqual` of an array is `jasmineEquals` of test/support/jasmine.dart.
//
// The tooltip cases (:8, :146) read `chart.tooltip`, the field of `Chart` (a
// `types.TooltipModel?`), through the interface.
// `chart.options.plugins.tooltip = value` writes the key `tooltip` of the
// Map `chart.options['plugins']`.

void main() {
  group('Chart.controllers.scatter', () {
    group('auto', fixture.specs('controller.scatter'));

    test('should be registered as dataset controller', () {
      expect(jsTypeof(Chart.registry.controllers.items['scatter']), 'function');
    });

    // :8
    testWidgets(
      'should only show a single point in the tooltip on multiple datasets',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 10, 'y': 15},
                  <String, Object?>{'x': 12, 'y': 10},
                ],
                'label': 'dataset1',
              },
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 20, 'y': 10},
                  <String, Object?>{'x': 4, 'y': 8},
                ],
                'label': 'dataset2',
              },
            ],
          },
          'options': <String, Object?>{},
        });
        final point = chart.getDatasetMeta(0).data[1];

        await triggerMouseEvent(chart, 'mousemove', point);
        expect(chart.tooltip!.body!.length, 1);
      },
    );

    testWidgets('should not create line element by default', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'scatter',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': 10, 'y': 15},
                <String, Object?>{'x': 12, 'y': 10},
              ],
              'label': 'dataset1',
            },
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': 20, 'y': 10},
                <String, Object?>{'x': 4, 'y': 8},
              ],
              'label': 'dataset2',
            },
          ],
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(meta.dataset is LineElement, false);
    });

    testWidgets(
      'should create line element if showline is true at datasets options',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'showLine': true,
                'data': <Object?>[
                  <String, Object?>{'x': 10, 'y': 15},
                  <String, Object?>{'x': 12, 'y': 10},
                ],
                'label': 'dataset1',
              },
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 20, 'y': 10},
                  <String, Object?>{'x': 4, 'y': 8},
                ],
                'label': 'dataset2',
              },
            ],
          },
        });

        final meta = chart.getDatasetMeta(0);
        expect(meta.dataset is LineElement, true);
      },
    );

    testWidgets(
      'should create line element if showline is true at root options',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 10, 'y': 15},
                  <String, Object?>{'x': 12, 'y': 10},
                ],
                'label': 'dataset1',
              },
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 20, 'y': 10},
                  <String, Object?>{'x': 4, 'y': 8},
                ],
                'label': 'dataset2',
              },
            ],
          },
          'options': <String, Object?>{'showLine': true},
        });

        final meta = chart.getDatasetMeta(0);
        expect(meta.dataset is LineElement, true);
      },
    );

    // :146
    testWidgets('should not override tooltip title and label callbacks', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'scatter',
        'data': <String, Object?>{
          'labels': <Object?>['Label 1', 'Label 2'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': 10, 'y': 15},
                <String, Object?>{'x': 12, 'y': 10},
              ],
              'label': 'Dataset 1',
            },
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': 20, 'y': 10},
                <String, Object?>{'x': 4, 'y': 8},
              ],
              'label': 'Dataset 2',
            },
          ],
        },
        'options': <String, Object?>{
          'responsive': true,
          'maintainAspectRatio': true,
        },
      });
      final tooltip = chart.tooltip!;
      final point = chart.getDatasetMeta(0).data[0];

      await triggerMouseEvent(chart, 'mousemove', point);

      expect(tooltip.title, jasmineEquals(<Object?>['Label 1']));
      expect(
        tooltip.body,
        jasmineEquals(<Object?>[
          <String, Object?>{
            'before': <Object?>[],
            'lines': <Object?>['Dataset 1: (10, 15)'],
            'after': <Object?>[],
          },
        ]),
      );

      (chart.options['plugins']! as JsObjectFace)['tooltip'] =
          <String, Object?>{'mode': 'dataset'};
      chart.update();
      await triggerMouseEvent(chart, 'mousemove', point);

      expect(tooltip.title, jasmineEquals(<Object?>['Dataset 1']));
      expect(
        tooltip.body,
        jasmineEquals(<Object?>[
          <String, Object?>{
            'before': <Object?>[],
            'lines': <Object?>['Label 1: (10, 15)'],
            'after': <Object?>[],
          },
          <String, Object?>{
            'before': <Object?>[],
            'lines': <Object?>['Label 2: (12, 10)'],
            'after': <Object?>[],
          },
        ]),
      );
    });
  });
}
