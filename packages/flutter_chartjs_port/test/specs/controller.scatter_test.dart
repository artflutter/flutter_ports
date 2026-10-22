// Ported from Chart.js v4.5.1+7169e651 test/specs/controller.scatter.tests.js (MIT, Chart.js Contributors).
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
//
// Two cases need the tooltip plugin of phase 8 (:8, :146).

void main() {
  group('Chart.controllers.scatter', () {
    group('auto', fixture.specs('controller.scatter'));

    test('should be registered as dataset controller', () {
      expect(jsTypeof(Chart.registry.controllers.items['scatter']), 'function');
    });

    // :8 The case reads `chart.tooltip.body` after a mousemove: it needs the
    // tooltip plugin of phase 8.
    test(
      'should only show a single point in the tooltip on multiple datasets',
      () {},
      skip: 'blocked: plugin.tooltip',
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

    // :146 The case reads `chart.tooltip` and writes
    // `chart.options.plugins.tooltip`: it needs the tooltip plugin of phase
    // 8.
    test(
      'should not override tooltip title and label callbacks',
      () {},
      skip: 'blocked: plugin.tooltip',
    );
  });
}
