// Ported from Chart.js v4.5.1+7169e651 test/specs/controller.polarArea.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs, which does not export lib/src
// yet.
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/elements/element.arc.dart';
import 'package:flutter_chartjs/src/helpers/helpers.core.dart' as helpers;
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// `Chart` is the class of core.controller.dart. The spec runs on the VM: a
// chart reaches the chart host and dart:ui. Each chart case is a
// `testWidgets` case with the harness of Chart.js ADR 0022, section 2. The
// conventions are those of Chart.js ADR 0030, section 13.
//
// flutter_test_config.dart registers the polar area controller with the
// built-in components before main(), as index.umd.ts:28 does (Chart.js ADR
// 0030, section 3 item 4).
//
// The spec forms:
// - `Chart.controllers` is `registry.controllers.items` (index.umd.ts:35):
//   `Chart.registry.controllers.items`.
// - `Chart.elements.ArcElement` is the class ArcElement of
//   element.arc.dart. `instanceof` is `isA`.
// - `Chart.helpers.merge` is `merge` of helpers.core.dart. A write into
//   `chart.options.elements.arc` writes into the resolver of the last
//   `jsGet`.
// - `chart.data.datasets[i]` is `_dataset(chart, i)`. `chart.data.labels =
//   v` writes the key `labels` of `chart.data`.
// - `spyOn(meta.data[i], 'draw')` is `spyOnElementDraw(meta, i)` of
//   test/support/jasmine.dart.
// - `toEqual` of an object is `jasmineEquals`. `jasmine.objectContaining` is
//   `objectContaining`. `.withContext(i)` is `reason: '$i'`.
// - Jasmine `this.chart` is a `late` variable of the group closure. The
//   `beforeEach` of the group `Interactions` acquires a chart. Thus it is a
//   local function `beforeEach()`, and each test calls it first.
//
// One case needs the tooltip plugin of phase 8 (:389).

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as AnyObject;

/// `meta.data[index]` of [meta], an arc.
ArcElement _arc(ChartMeta meta, int index) => meta.data[index] as ArcElement;

/// `element.options` of [element].
AnyObject? _options(Object element) => (element as Element).options;

/// `element.options[key]` of [element].
Object? _option(Object element, String key) => jsGet(_options(element), key);

/// The expected values `{o, s, e}` of an arc: the outer radius, the start
/// angle and the end angle.
typedef _ArcValues = ({double o, double s, double e});

/// The checks of the `forEach` of :182-197 and :236-251: the arc [i] of
/// [meta] against [expected].
void _expectArc(ChartMeta meta, int i, _ArcValues expected) {
  final arc = _arc(meta, i);
  expect(arc.x, toBeCloseToPixel(256), reason: '$i');
  expect(arc.y, toBeCloseToPixel(256), reason: '$i');
  expect(arc.innerRadius, toBeCloseToPixel(0), reason: '$i');
  expect(arc.outerRadius, toBeCloseToPixel(expected.o), reason: '$i');
  expect(arc.startAngle, expected.s, reason: '$i');
  expect(arc.endAngle, expected.e, reason: '$i');
  expect(
    _options(arc),
    objectContaining(<String, Object?>{
      'backgroundColor': 'rgb(255, 0, 0)',
      'borderColor': 'rgb(0, 255, 0)',
      'borderWidth': 1.2,
    }),
    reason: '$i',
  );
}

void main() {
  group('Chart.controllers.polarArea', () {
    group('auto', fixture.specs('controller.polarArea'));

    testWidgets(
      'should update the scale correctly when data visibility is changed',
      (tester) async {
        const expectedScaleMax = 1;
        final chart =
            acquireChart(<String, Object?>{
                'type': 'polarArea',
                'data': <String, Object?>{
                  'datasets': <Object?>[
                    <String, Object?>{
                      'data': <Object?>[100],
                    },
                  ],
                  'labels': <Object?>['x'],
                },
              })
              // :16-17 `chart.toggleDataVisibility(0); chart.update();`
              ..toggleDataVisibility(0)
              ..update();

        expect(chart.scales['r']!.max, expectedScaleMax);
      },
    );

    test('should be registered as dataset controller', () {
      expect(
        jsTypeof(Chart.registry.controllers.items['polarArea']),
        'function',
      );
    });

    testWidgets('should be constructed', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'polarArea',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': <Object?>[]},
            <String, Object?>{'data': <Object?>[]},
          ],
          'labels': <Object?>[],
        },
      });

      final meta = chart.getDatasetMeta(1);
      expect(meta.type, 'polarArea');
      expect(meta.data, jasmineEquals(<Object?>[]));
      expect(meta.hidden, isNull);
      expect(meta.controller, isNot(same(undefined)));
      expect(meta.controller, isNotNull);
      expect(meta.controller!.index, 1);

      meta.controller!.updateIndex(0);
      expect(meta.controller!.index, 0);
    });

    testWidgets(
      'should create arc elements for each data item during initialization',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'polarArea',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{
                'data': <Object?>[10, 15, 0, -4],
              },
            ],
            'labels': <Object?>[],
          },
        });

        final meta = chart.getDatasetMeta(1);
        expect(meta.data.length, 4); // 4 arcs created
        expect(meta.data[0], isA<ArcElement>());
        expect(meta.data[1], isA<ArcElement>());
        expect(meta.data[2], isA<ArcElement>());
        expect(meta.data[3], isA<ArcElement>());
      },
    );

    testWidgets('should default arc spacingMode to proportional', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'polarArea',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 20],
            },
          ],
          'labels': <Object?>['a', 'b'],
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(_option(meta.data[0], 'spacingMode'), 'proportional');
      expect(_option(meta.data[1], 'spacingMode'), 'proportional');
    });

    testWidgets('should respect chart-level spacingMode override', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'polarArea',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 20],
            },
          ],
          'labels': <Object?>['a', 'b'],
        },
        'options': <String, Object?>{
          'spacing': 12,
          'spacingMode': 'parallel',
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(_option(meta.data[0], 'spacingMode'), 'parallel');
      expect(_option(meta.data[1], 'spacingMode'), 'parallel');
      expect(_option(meta.data[0], 'spacing'), 12);
      expect(_option(meta.data[1], 'spacing'), 12);
    });

    testWidgets('should draw all elements', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'polarArea',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset2',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
      });

      final meta = chart.getDatasetMeta(0);

      final draw0 = spyOnElementDraw(meta, 0);
      final draw1 = spyOnElementDraw(meta, 1);
      final draw2 = spyOnElementDraw(meta, 2);
      final draw3 = spyOnElementDraw(meta, 3);

      chart.update();

      expect(draw0.count(), 1);
      expect(draw1.count(), 1);
      expect(draw2.count(), 1);
      expect(draw3.count(), 1);
    });

    testWidgets('should update elements when modifying data', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'polarArea',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset2',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'showLine': true,
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'elements': <String, Object?>{
            'arc': <String, Object?>{
              'backgroundColor': 'rgb(255, 0, 0)',
              'borderColor': 'rgb(0, 255, 0)',
              'borderWidth': 1.2,
            },
          },
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(meta.data.length, 4);

      final expectedValues = <_ArcValues>[
        (o: 174, s: -0.5 * math.pi, e: 0),
        (o: 236, s: 0, e: 0.5 * math.pi),
        (o: 51, s: 0.5 * math.pi, e: math.pi),
        (o: 0, s: math.pi, e: 1.5 * math.pi),
      ];
      for (var i = 0; i < expectedValues.length; i++) {
        _expectArc(meta, i, expectedValues[i]);
      }

      // arc styles
      _dataset(chart, 0)['backgroundColor'] = 'rgb(128, 129, 130)';
      _dataset(chart, 0)['borderColor'] = 'rgb(56, 57, 58)';
      _dataset(chart, 0)['borderWidth'] = 1.123;

      chart.update();

      for (var i = 0; i < 4; ++i) {
        expect(_option(meta.data[i], 'backgroundColor'), 'rgb(128, 129, 130)');
        expect(_option(meta.data[i], 'borderColor'), 'rgb(56, 57, 58)');
        expect(_option(meta.data[i], 'borderWidth'), 1.123);
      }

      chart.update();

      expect(_arc(meta, 0).x, toBeCloseToPixel(256));
      expect(_arc(meta, 0).y, toBeCloseToPixel(256));
      expect(_arc(meta, 0).innerRadius, toBeCloseToPixel(0));
      expect(_arc(meta, 0).outerRadius, toBeCloseToPixel(174));
    });

    testWidgets('should update elements with start angle from options', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'polarArea',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset2',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'showLine': true,
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'scales': <String, Object?>{
            'r': <String, Object?>{
              'startAngle': 90, // default is 0
            },
          },
          'elements': <String, Object?>{
            'arc': <String, Object?>{
              'backgroundColor': 'rgb(255, 0, 0)',
              'borderColor': 'rgb(0, 255, 0)',
              'borderWidth': 1.2,
            },
          },
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(meta.data.length, 4);

      final expectedValues = <_ArcValues>[
        (o: 174, s: 0, e: 0.5 * math.pi),
        (o: 236, s: 0.5 * math.pi, e: math.pi),
        (o: 51, s: math.pi, e: 1.5 * math.pi),
        (o: 0, s: 1.5 * math.pi, e: 2.0 * math.pi),
      ];
      for (var i = 0; i < expectedValues.length; i++) {
        _expectArc(meta, i, expectedValues[i]);
      }
    });

    testWidgets('should handle number of data point changes in update', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'polarArea',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset2',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'showLine': true,
          'elements': <String, Object?>{
            'arc': <String, Object?>{
              'backgroundColor': 'rgb(255, 0, 0)',
              'borderColor': 'rgb(0, 255, 0)',
              'borderWidth': 1.2,
            },
          },
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(meta.data.length, 4);

      // remove 2 items
      chart.data['labels'] = <Object?>['label1', 'label2'];
      _dataset(chart, 0)['data'] = <Object?>[1, 2];
      chart.update();

      expect(meta.data.length, 2);
      expect(meta.data[0], isA<ArcElement>());
      expect(meta.data[1], isA<ArcElement>());

      // add 3 items
      chart.data['labels'] = <Object?>[
        'label1',
        'label2',
        'label3',
        'label4',
        'label5',
      ];
      _dataset(chart, 0)['data'] = <Object?>[1, 2, 3, 4, 5];
      chart.update();

      expect(meta.data.length, 5);
      expect(meta.data[0], isA<ArcElement>());
      expect(meta.data[1], isA<ArcElement>());
      expect(meta.data[2], isA<ArcElement>());
      expect(meta.data[3], isA<ArcElement>());
      expect(meta.data[4], isA<ArcElement>());
    });

    group('Interactions', () {
      late Chart chart;

      // :305 beforeEach: acquires a chart.
      void beforeEach() {
        chart = acquireChart(<String, Object?>{
          'type': 'polarArea',
          'data': <String, Object?>{
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 15, 0, 4],
              },
            ],
          },
          'options': <String, Object?>{
            'cutoutPercentage': 0,
            'elements': <String, Object?>{
              'arc': <String, Object?>{
                'backgroundColor': 'rgb(100, 150, 200)',
                'borderColor': 'rgb(50, 100, 150)',
                'borderWidth': 2,
              },
            },
          },
        });
      }

      testWidgets('should handle default hover styles', (tester) async {
        beforeEach();
        final arc = chart.getDatasetMeta(0).data[0];

        await triggerMouseEvent(chart, 'mousemove', arc);
        expect(_option(arc, 'backgroundColor'), '#3187DD');
        expect(_option(arc, 'borderColor'), '#175A9D');
        expect(_option(arc, 'borderWidth'), 2);

        await triggerMouseEvent(chart, 'mouseout', arc);
        expect(_option(arc, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(arc, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(arc, 'borderWidth'), 2);
      });

      testWidgets('should handle hover styles defined via dataset properties', (
        tester,
      ) async {
        beforeEach();
        final arc = chart.getDatasetMeta(0).data[0];

        helpers.merge(_dataset(chart, 0), <String, Object?>{
          'hoverBackgroundColor': 'rgb(200, 100, 150)',
          'hoverBorderColor': 'rgb(150, 50, 100)',
          'hoverBorderWidth': 8.4,
        });

        chart.update();

        await triggerMouseEvent(chart, 'mousemove', arc);
        expect(_option(arc, 'backgroundColor'), 'rgb(200, 100, 150)');
        expect(_option(arc, 'borderColor'), 'rgb(150, 50, 100)');
        expect(_option(arc, 'borderWidth'), 8.4);

        await triggerMouseEvent(chart, 'mouseout', arc);
        expect(_option(arc, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(arc, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(arc, 'borderWidth'), 2);
      });

      testWidgets('should handle hover styles defined via element options', (
        tester,
      ) async {
        beforeEach();
        final arc = chart.getDatasetMeta(0).data[0];

        helpers.merge(
          jsGet(jsGet(chart.options, 'elements'), 'arc'),
          <String, Object?>{
            'hoverBackgroundColor': 'rgb(200, 100, 150)',
            'hoverBorderColor': 'rgb(150, 50, 100)',
            'hoverBorderWidth': 8.4,
          },
        );

        chart.update();

        await triggerMouseEvent(chart, 'mousemove', arc);
        expect(_option(arc, 'backgroundColor'), 'rgb(200, 100, 150)');
        expect(_option(arc, 'borderColor'), 'rgb(150, 50, 100)');
        expect(_option(arc, 'borderWidth'), 8.4);

        await triggerMouseEvent(chart, 'mouseout', arc);
        expect(_option(arc, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(arc, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(arc, 'borderWidth'), 2);
      });
    });

    // :389 The case reads `chart.tooltip` and writes
    // `chart.options.plugins.tooltip`: it needs the tooltip plugin of
    // phase 8.
    test(
      'should not override tooltip title and label callbacks',
      () {},
      skip: 'blocked: plugin.tooltip',
    );
  });
}
