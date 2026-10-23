// Ported from Chart.js v4.5.1+7169e651 test/specs/controller.line.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart' as helpers;
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsSin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// `Chart` is the class of core.controller.dart. The spec runs on the VM: a
// chart reaches the chart host and dart:ui. Each chart case is a
// `testWidgets` case with the harness of Chart.js ADR 0022, section 2. The
// conventions are those of Chart.js ADR 0030, section 13.
//
// flutter_test_config.dart registers the line controller with the
// built-in components before main(), as index.umd.ts:28 does (Chart.js ADR
// 0030, section 3 item 4).
//
// The spec forms:
// - `Chart.controllers` is `registry.controllers.items` (index.umd.ts:35):
//   `Chart.registry.controllers.items`.
// - `Chart.elements.LineElement` and `Chart.elements.PointElement` are the
//   classes of element.line.dart and element.point.dart. `instanceof` is
//   `isA`.
// - `Chart.defaults` is the static `Chart.defaults`. A property read is
//   `jsGet`. `Chart.helpers.clone` and `Chart.helpers.merge` are `clone` and
//   `merge` of helpers.core.dart.
// - `chart.data.datasets[i]` is `_dataset(chart, i)`. `meta._parsed` is
//   `meta.parsed`. `controller._drawStart` and `_drawCount` are `drawStart`
//   and `drawCount` of DatasetController (Chart.js ADR 0012).
// - `spyOn(meta.dataset, 'updateControlPoints')` and `spyOn(meta.dataset,
//   'draw')` are `spyOnDataset(meta)`, and `spyOn(meta.data[i], 'draw')` is
//   `spyOnElementDraw(meta, i)` of test/support/jasmine.dart.
// - `toEqual` of an object is `jasmineEquals`. `jasmine.objectContaining` is
//   `objectContaining`.
// - Jasmine `this._defaults` and `this.chart` are `late` variables of the
//   group closure. The `beforeEach` and the `afterEach` of the group
//   `dataset global defaults` read no chart. Thus they are `setUp` and
//   `tearDown`. The `beforeEach` of the group `Interactions` acquires a
//   chart. Thus it is a local function `beforeEach()`, and each test calls it
//   first.
// - `chart._handleEvent(event, false, true)` is `chart.handleEvent` (Chart.js
//   ADR 0012). The event `{type: 'mousemove', native: true, ...point}` is a
//   `_PointEvent` (see there).
//
// The tooltip case (:1161) reads `chart.tooltip`, the field of `Chart` (a
// `types.TooltipModel?`), through the interface.
// `chart.options.plugins.tooltip = value` writes the key `tooltip` of the
// Map `chart.options['plugins']`.

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as AnyObject;

/// `element.options` of [element].
AnyObject? _options(Object element) => (element as Element).options;

/// `element.options[key]` of [element].
Object? _option(Object element, String key) => jsGet(_options(element), key);

/// `Chart.defaults.datasets`.
AnyObject _datasetDefaults() => jsGet(Chart.defaults, 'datasets')! as AnyObject;

/// The `{min, max}` of `getMinMax` as an object for `toEqual`.
AnyObject _minMax(({double min, double max}) range) => <String, Object?>{
  'min': range.min,
  'max': range.max,
};

/// The event `{type: 'mousemove', native: true, ...point}` of :1062-1066.
///
/// The spread copies the properties of the point; `_handleEvent` reads only
/// `type`, `x` and `y` of the event (core.controller.js:1196-1236,
/// helpers.dom.ts:105-111). The port types `native` as a [NativeEvent]. JS
/// `true` has no Dart form there. `getRelativePosition` tests only that the
/// event has a `native` key, which each `types.ChartEvent` has. Thus Dart
/// `null` stands for it.
final class _PointEvent implements types.ChartEvent {
  _PointEvent(types.Point point) : x = point.x, y = point.y;

  @override
  String get type => 'mousemove';

  @override
  NativeEvent? get native => null;

  @override
  final double? x;

  @override
  final double? y;

  @override
  types.Chart? get chart => null;
}

void main() {
  group('Chart.controllers.line', () {
    group('auto', fixture.specs('controller.line'));

    test('should be registered as dataset controller', () {
      expect(jsTypeof(Chart.registry.controllers.items['line']), 'function');
    });

    testWidgets('should be constructed', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': <Object?>[]},
          ],
          'labels': <Object?>[],
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(meta.type, 'line');
      expect(meta.controller, isNot(same(undefined)));
      expect(meta.controller, isNotNull);
      expect(meta.controller!.index, 0);
      expect(meta.data, jasmineEquals(<Object?>[]));

      meta.controller!.updateIndex(1);
      expect(meta.controller!.index, 1);
    });

    testWidgets(
      'Should use the first scale IDs if the dataset does not specify them',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
        });

        final meta = chart.getDatasetMeta(0);
        expect(meta.xAxisID, 'x');
        expect(meta.yAxisID, 'y');
      },
    );

    testWidgets(
      'Should not throw with empty dataset when tension is non-zero',
      (tester) async {
        // https://github.com/chartjs/Chart.js/issues/8676
        Chart createChart() {
          return acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{'data': <Object?>[], 'tension': 0.5},
              ],
              'labels': <Object?>[],
            },
          });
        }

        expect(createChart, returnsNormally);
      },
    );

    testWidgets('should find min and max for stacked chart', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 11, 12, 13],
            },
            <String, Object?>{
              'data': <Object?>[1, 2, 3, 4],
            },
          ],
          'labels': <Object?>['a', 'b', 'c', 'd'],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{'stacked': true},
          },
        },
      });
      final y = chart.scales['y']!;
      expect(
        _minMax(chart.getDatasetMeta(0).controller!.getMinMax(y, true)),
        jasmineEquals(<String, Object?>{'min': 10, 'max': 13}),
      );
      expect(
        _minMax(chart.getDatasetMeta(1).controller!.getMinMax(y, true)),
        jasmineEquals(<String, Object?>{'min': 11, 'max': 17}),
      );
      chart.hide(0);
      expect(
        _minMax(chart.getDatasetMeta(0).controller!.getMinMax(y, true)),
        jasmineEquals(<String, Object?>{'min': 10, 'max': 13}),
      );
      expect(
        _minMax(chart.getDatasetMeta(1).controller!.getMinMax(y, true)),
        jasmineEquals(<String, Object?>{'min': 1, 'max': 4}),
      );
    });

    testWidgets(
      'Should create line elements and point elements for each data item '
      'during initialization',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 15, 0, -4],
                'label': 'dataset1',
              },
            ],
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
          },
        });

        final meta = chart.getDatasetMeta(0);
        expect(meta.data.length, 4); // 4 points created
        expect(meta.data[0], isA<PointElement>());
        expect(meta.data[1], isA<PointElement>());
        expect(meta.data[2], isA<PointElement>());
        expect(meta.data[3], isA<PointElement>());
        expect(meta.dataset, isA<LineElement>()); // 1 line element
      },
    );

    testWidgets('should draw all elements', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset1',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{'showLine': true},
      });

      final meta = chart.getDatasetMeta(0);
      final dataset = spyOnDataset(meta);
      final draw0 = spyOnElementDraw(meta, 0);
      final draw1 = spyOnElementDraw(meta, 1);
      final draw2 = spyOnElementDraw(meta, 2);
      final draw3 = spyOnElementDraw(meta, 3);

      chart.update();

      expect(dataset.updateControlPoints.count(), greaterThanOrEqualTo(1));
      expect(dataset.draw.count(), 1);
      expect(draw0.count(), 1);
      expect(draw1.count(), 1);
      expect(draw2.count(), 1);
      expect(draw3.count(), 1);
    });

    testWidgets('should update elements when modifying data', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset',
              'xAxisID': 'x',
              'yAxisID': 'y',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'showLine': true,
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'elements': <String, Object?>{
            'point': <String, Object?>{
              'backgroundColor': 'red',
              'borderColor': 'blue',
            },
          },
          'scales': <String, Object?>{
            'x': <String, Object?>{'display': false},
            'y': <String, Object?>{'display': false},
          },
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(meta.data.length, 4);

      _dataset(chart, 0)['data'] = <Object?>[1, 2]; // remove 2 items
      _dataset(chart, 0)['borderWidth'] = 1;
      chart.update();

      expect(meta.data.length, 2);
      expect(meta.parsed.length, 2);

      final expectedValues = [(x: 5, y: 507), (x: 171, y: 5)];
      for (var i = 0; i < expectedValues.length; i++) {
        final expected = expectedValues[i];
        expect(meta.data[i].x, toBeCloseToPixel(expected.x));
        expect(meta.data[i].y, toBeCloseToPixel(expected.y));
        expect(
          _options(meta.data[i]),
          objectContaining(<String, Object?>{
            'backgroundColor': 'red',
            'borderColor': 'blue',
          }),
        );
      }

      _dataset(chart, 0)['data'] = <Object?>[1, 2, 3]; // add 1 items
      chart.update();

      expect(meta.data.length, 3); // should add a new meta data item
    });

    testWidgets('should correctly calculate x scale for label and point', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['One'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1],
            },
          ],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'hover': <String, Object?>{'mode': 'nearest', 'intersect': true},
          'scales': <String, Object?>{
            'x': <String, Object?>{'display': false},
            'y': <String, Object?>{'display': false, 'beginAtZero': true},
          },
        },
      });

      final meta = chart.getDatasetMeta(0);
      // 1 point
      final point = meta.data[0];
      expect(point.x, toBeCloseToPixel(5));

      // 2 points
      chart.data['labels'] = <Object?>['One', 'Two'];
      _dataset(chart, 0)['data'] = <Object?>[1, 2];
      chart.update();

      var points = meta.data;

      expect(points[0].x, toBeCloseToPixel(5));
      expect(points[1].x, toBeCloseToPixel(507));

      // 3 points
      chart.data['labels'] = <Object?>['One', 'Two', 'Three'];
      _dataset(chart, 0)['data'] = <Object?>[1, 2, 3];
      chart.update();

      points = meta.data;

      expect(points[0].x, toBeCloseToPixel(5));
      expect(points[1].x, toBeCloseToPixel(256));
      expect(points[2].x, toBeCloseToPixel(507));

      // 4 points
      chart.data['labels'] = <Object?>['One', 'Two', 'Three', 'Four'];
      _dataset(chart, 0)['data'] = <Object?>[1, 2, 3, 4];
      chart.update();

      points = meta.data;

      expect(points[0].x, toBeCloseToPixel(5));
      expect(points[1].x, toBeCloseToPixel(171));
      expect(points[2].x, toBeCloseToPixel(340));
      expect(points[3].x, toBeCloseToPixel(507));
    });

    /// The pixels of the four stacked cases (:304-326 and the same values
    /// at :369-391, :449-471 and :505-527).
    void expectStackedPixels(Chart chart) {
      final meta0 = chart.getDatasetMeta(0);

      final values0 = [
        (x: 5, y: 148),
        (x: 171, y: 435),
        (x: 341, y: 148),
        (x: 507, y: 435),
      ];
      for (var i = 0; i < values0.length; i++) {
        expect(meta0.data[i].x, toBeCloseToPixel(values0[i].x));
        expect(meta0.data[i].y, toBeCloseToPixel(values0[i].y));
      }

      final meta1 = chart.getDatasetMeta(1);

      final values1 = [
        (x: 5, y: 5),
        (x: 171, y: 76),
        (x: 341, y: 148),
        (x: 507, y: 492),
      ];
      for (var i = 0; i < values1.length; i++) {
        expect(meta1.data[i].x, toBeCloseToPixel(values1[i].x));
        expect(meta1.data[i].y, toBeCloseToPixel(values1[i].y));
      }
    }

    testWidgets('should update elements when the y scale is stacked', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, -10, 10, -10],
              'label': 'dataset1',
            },
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset2',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'scales': <String, Object?>{
            'x': <String, Object?>{'display': false},
            'y': <String, Object?>{'display': false, 'stacked': true},
          },
        },
      });

      expectStackedPixels(chart);
    });

    testWidgets(
      'should update elements when the y scale is stacked with multiple axes',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, -10, 10, -10],
                'label': 'dataset1',
              },
              <String, Object?>{
                'data': <Object?>[10, 15, 0, -4],
                'label': 'dataset2',
              },
              <String, Object?>{
                'data': <Object?>[10, 10, -10, -10],
                'label': 'dataset3',
                'yAxisID': 'y2',
              },
            ],
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{'legend': false, 'title': false},
            'scales': <String, Object?>{
              'x': <String, Object?>{'display': false},
              'y': <String, Object?>{'display': false, 'stacked': true},
              'y2': <String, Object?>{
                'type': 'linear',
                'position': 'right',
                'display': false,
              },
            },
          },
        });

        expectStackedPixels(chart);
      },
    );

    testWidgets(
      'should update elements when the y scale is stacked and datasets is '
      'scatter data',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 0, 'y': 10},
                  <String, Object?>{'x': 1, 'y': -10},
                  <String, Object?>{'x': 2, 'y': 10},
                  <String, Object?>{'x': 3, 'y': -10},
                ],
                'label': 'dataset1',
              },
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 0, 'y': 10},
                  <String, Object?>{'x': 1, 'y': 15},
                  <String, Object?>{'x': 2, 'y': 0},
                  <String, Object?>{'x': 3, 'y': -4},
                ],
                'label': 'dataset2',
              },
            ],
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{'legend': false, 'title': false},
            'scales': <String, Object?>{
              'x': <String, Object?>{'display': false},
              'y': <String, Object?>{'display': false, 'stacked': true},
            },
          },
        });

        expectStackedPixels(chart);
      },
    );

    testWidgets(
      'should update elements when the y scale is stacked and data is strings',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>['10', '-10', '10', '-10'],
                'label': 'dataset1',
              },
              <String, Object?>{
                'data': <Object?>['10', '15', '0', '-4'],
                'label': 'dataset2',
              },
            ],
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{'legend': false, 'title': false},
            'scales': <String, Object?>{
              'x': <String, Object?>{'display': false},
              'y': <String, Object?>{'display': false, 'stacked': true},
            },
          },
        });

        expectStackedPixels(chart);
      },
    );

    testWidgets('should fall back to the line styles for points', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[0, 0],
              'label': 'dataset1',

              // line styles
              'backgroundColor': 'rgb(98, 98, 98)',
              'borderColor': 'rgb(8, 8, 8)',
              'borderWidth': 0.55,
            },
          ],
          'labels': <Object?>['label1', 'label2'],
        },
      });

      final meta = chart.getDatasetMeta(0);

      expect(_option(meta.dataset!, 'backgroundColor'), 'rgb(98, 98, 98)');
      expect(_option(meta.dataset!, 'borderColor'), 'rgb(8, 8, 8)');
      expect(_option(meta.dataset!, 'borderWidth'), 0.55);
    });

    group('dataset global defaults', () {
      late Object? defaults;

      setUp(() {
        defaults = helpers.clone(jsGet(_datasetDefaults(), 'line'));
      });

      tearDown(() {
        _datasetDefaults()['line'] = defaults;
        defaults = undefined;
      });

      testWidgets('should utilize the dataset global default options', (
        tester,
      ) async {
        helpers.merge(jsGet(_datasetDefaults(), 'line'), <String, Object?>{
          'spanGaps': true,
          'tension': 0.231,
          'backgroundColor': '#add',
          'borderWidth': '#daa',
          'borderColor': '#dad',
          'borderCapStyle': 'round',
          'borderDash': <Object?>[0],
          'borderDashOffset': 0.871,
          'borderJoinStyle': 'miter',
          'fill': 'start',
          'cubicInterpolationMode': 'monotone',
        });

        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[0, 0],
                'label': 'dataset1',
              },
            ],
            'labels': <Object?>['label1', 'label2'],
          },
        });

        final options = chart.getDatasetMeta(0).dataset!.options;

        expect(jsGet(options, 'spanGaps'), true);
        expect(jsGet(options, 'tension'), 0.231);
        expect(jsGet(options, 'backgroundColor'), '#add');
        expect(jsGet(options, 'borderWidth'), '#daa');
        expect(jsGet(options, 'borderColor'), '#dad');
        expect(jsGet(options, 'borderCapStyle'), 'round');
        expect(jsGet(options, 'borderDash'), jasmineEquals(<Object?>[0]));
        expect(jsGet(options, 'borderDashOffset'), 0.871);
        expect(jsGet(options, 'borderJoinStyle'), 'miter');
        expect(jsGet(options, 'fill'), 'start');
        expect(jsGet(options, 'cubicInterpolationMode'), 'monotone');
      });

      testWidgets('should be overridden by user-supplied values', (
        tester,
      ) async {
        helpers.merge(jsGet(_datasetDefaults(), 'line'), <String, Object?>{
          'spanGaps': true,
          'tension': 0.231,
        });

        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[0, 0],
                'label': 'dataset1',
                'spanGaps': true,
                'backgroundColor': '#dad',
              },
            ],
            'labels': <Object?>['label1', 'label2'],
          },
          'options': <String, Object?>{
            'datasets': <String, Object?>{
              'line': <String, Object?>{
                'tension': 0.345,
                'backgroundColor': '#add',
              },
            },
          },
        });

        final options = chart.getDatasetMeta(0).dataset!.options;

        // dataset-level option overrides global default
        expect(jsGet(options, 'spanGaps'), true);
        // chart-level default overrides global default
        expect(jsGet(options, 'tension'), 0.345);
        // dataset-level option overrides chart-level default
        expect(jsGet(options, 'backgroundColor'), '#dad');
      });
    });

    /// The options of :657-667 and :695-705, and of the expectations at
    /// :675-685 and :713-723.
    const lineOptions = <String, Object?>{
      'spanGaps': true,
      'tension': 0.231,
      'backgroundColor': '#add',
      'borderWidth': '#daa',
      'borderColor': '#dad',
      'borderCapStyle': 'round',
      'borderDash': <Object?>[0],
      'borderDashOffset': 0.871,
      'borderJoinStyle': 'miter',
      'fill': 'start',
      'cubicInterpolationMode': 'monotone',
    };

    /// The expectations of :675-685 and :713-723.
    void expectLineOptions(AnyObject? options) {
      expect(jsGet(options, 'spanGaps'), true);
      expect(jsGet(options, 'tension'), 0.231);
      expect(jsGet(options, 'backgroundColor'), '#add');
      expect(jsGet(options, 'borderWidth'), '#daa');
      expect(jsGet(options, 'borderColor'), '#dad');
      expect(jsGet(options, 'borderCapStyle'), 'round');
      expect(jsGet(options, 'borderDash'), jasmineEquals(<Object?>[0]));
      expect(jsGet(options, 'borderDashOffset'), 0.871);
      expect(jsGet(options, 'borderJoinStyle'), 'miter');
      expect(jsGet(options, 'fill'), 'start');
      expect(jsGet(options, 'cubicInterpolationMode'), 'monotone');
    }

    testWidgets('should obey the chart-level dataset options', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[0, 0],
              'label': 'dataset1',
            },
          ],
          'labels': <Object?>['label1', 'label2'],
        },
        'options': <String, Object?>{
          'datasets': <String, Object?>{
            'line': <String, Object?>{
              ...lineOptions,
              'borderDash': <Object?>[0],
            },
          },
        },
      });

      expectLineOptions(chart.getDatasetMeta(0).dataset!.options);
    });

    testWidgets('should obey the dataset options', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[0, 0],
              'label': 'dataset1',
              ...lineOptions,
              'borderDash': <Object?>[0],
            },
          ],
          'labels': <Object?>['label1', 'label2'],
        },
      });

      expectLineOptions(chart.getDatasetMeta(0).dataset!.options);
    });

    testWidgets('should handle number of data point changes in update', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset1',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
      });

      final meta = chart.getDatasetMeta(0);

      _dataset(chart, 0)['data'] = <Object?>[1, 2]; // remove 2 items
      chart.update();
      expect(meta.data.length, 2);
      expect(meta.data[0], isA<PointElement>());
      expect(meta.data[1], isA<PointElement>());

      _dataset(chart, 0)['data'] = <Object?>[1, 2, 3, 4, 5]; // add 3 items
      chart.update();
      expect(meta.data.length, 5);
      expect(meta.data[0], isA<PointElement>());
      expect(meta.data[1], isA<PointElement>());
      expect(meta.data[2], isA<PointElement>());
      expect(meta.data[3], isA<PointElement>());
      expect(meta.data[4], isA<PointElement>());
    });

    group('Interactions', () {
      late Chart chart;

      void beforeEach() {
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 15, 0, -4],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'offset': true},
            },
            'elements': <String, Object?>{
              'point': <String, Object?>{
                'backgroundColor': 'rgb(100, 150, 200)',
                'borderColor': 'rgb(50, 100, 150)',
                'borderWidth': 2,
                'radius': 3,
              },
            },
          },
        });
      }

      testWidgets('should handle default hover styles', (tester) async {
        beforeEach();
        final point = chart.getDatasetMeta(0).data[0];

        await triggerMouseEvent(chart, 'mousemove', point);
        expect(_option(point, 'backgroundColor'), '#3187DD');
        expect(_option(point, 'borderColor'), '#175A9D');
        expect(_option(point, 'borderWidth'), 1);
        expect(_option(point, 'radius'), 4);

        await triggerMouseEvent(chart, 'mouseout', point);
        expect(_option(point, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(point, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(point, 'borderWidth'), 2);
        expect(_option(point, 'radius'), 3);
      });

      testWidgets('should handle hover styles defined via dataset properties', (
        tester,
      ) async {
        beforeEach();
        final point = chart.getDatasetMeta(0).data[0];

        helpers.merge(_dataset(chart, 0), <String, Object?>{
          'hoverBackgroundColor': 'rgb(200, 100, 150)',
          'hoverBorderColor': 'rgb(150, 50, 100)',
          'hoverBorderWidth': 8.4,
          'hoverRadius': 4.2,
        });

        chart.update();

        await triggerMouseEvent(chart, 'mousemove', point);
        expect(_option(point, 'backgroundColor'), 'rgb(200, 100, 150)');
        expect(_option(point, 'borderColor'), 'rgb(150, 50, 100)');
        expect(_option(point, 'borderWidth'), 8.4);
        expect(_option(point, 'radius'), 4.2);

        await triggerMouseEvent(chart, 'mouseout', point);
        expect(_option(point, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(point, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(point, 'borderWidth'), 2);
        expect(_option(point, 'radius'), 3);
      });

      testWidgets('should handle hover styles defined via element options', (
        tester,
      ) async {
        beforeEach();
        final point = chart.getDatasetMeta(0).data[0];

        helpers.merge(
          jsGet(jsGet(chart.options, 'elements'), 'point'),
          <String, Object?>{
            'hoverBackgroundColor': 'rgb(200, 100, 150)',
            'hoverBorderColor': 'rgb(150, 50, 100)',
            'hoverBorderWidth': 8.4,
            'hoverRadius': 4.2,
          },
        );

        chart.update();

        await triggerMouseEvent(chart, 'mousemove', point);
        expect(_option(point, 'backgroundColor'), 'rgb(200, 100, 150)');
        expect(_option(point, 'borderColor'), 'rgb(150, 50, 100)');
        expect(_option(point, 'borderWidth'), 8.4);
        expect(_option(point, 'radius'), 4.2);

        await triggerMouseEvent(chart, 'mouseout', point);
        expect(_option(point, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(point, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(point, 'borderWidth'), 2);
        expect(_option(point, 'radius'), 3);
      });

      testWidgets(
        'should handle dataset hover styles defined via dataset properties',
        (tester) async {
          beforeEach();
          final point = chart.getDatasetMeta(0).data[0];
          final dataset = chart.getDatasetMeta(0).dataset!;

          helpers.merge(_dataset(chart, 0), <String, Object?>{
            'backgroundColor': '#AAA',
            'borderColor': '#BBB',
            'borderWidth': 6,
            'hoverBackgroundColor': '#000',
            'hoverBorderColor': '#111',
            'hoverBorderWidth': 12,
          });

          chart.options['hover'] = <String, Object?>{'mode': 'dataset'};
          chart.update();

          await triggerMouseEvent(chart, 'mousemove', point);
          expect(_option(dataset, 'backgroundColor'), '#000');
          expect(_option(dataset, 'borderColor'), '#111');
          expect(_option(dataset, 'borderWidth'), 12);

          await triggerMouseEvent(chart, 'mouseout', point);
          expect(_option(dataset, 'backgroundColor'), '#AAA');
          expect(_option(dataset, 'borderColor'), '#BBB');
          expect(_option(dataset, 'borderWidth'), 6);
        },
      );
    });

    testWidgets('should allow 0 as a point border width', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset1',
              'pointBorderWidth': 0,
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
      });

      final meta = chart.getDatasetMeta(0);
      final point = meta.data[0];

      expect(_option(point, 'borderWidth'), 0);
    });

    testWidgets('should allow an array as the point border width setting', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset1',
              'pointBorderWidth': <Object?>[1, 2, 3, 4],
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(_option(meta.data[0], 'borderWidth'), 1);
      expect(_option(meta.data[1], 'borderWidth'), 2);
      expect(_option(meta.data[2], 'borderWidth'), 3);
      expect(_option(meta.data[3], 'borderWidth'), 4);
    });

    testWidgets('should render a million points', (tester) async {
      final data = <Object?>[];
      for (var x = 0; x < 1e6; x++) {
        data.add(<String, Object?>{'x': x, 'y': jsSin(x / 10000)});
      }
      void createChart() {
        acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': data, 'borderWidth': 1, 'radius': 0},
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear'},
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        });
      }

      expect(createChart, returnsNormally);
    });

    testWidgets('should set skipped points to the reset state', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, null, 0, -4],
              'label': 'dataset1',
              'pointBorderWidth': <Object?>[1, 2, 3, 4],
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
      });

      final meta = chart.getDatasetMeta(0);
      final point = meta.data[1] as PointElement;
      final props = point.getProps(const ['x', 'y'], true);
      expect(point.skip, true);
      expect(jsIsNaN(props['x']), false);
      expect(jsIsNaN(props['y']), false);
    });

    testWidgets('should honor spangap interval forwards', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'spanGaps': 10,
              'data': <Object?>[
                <String, Object?>{'x': 10, 'y': 123},
                <String, Object?>{'x': 15, 'y': 124},
                <String, Object?>{'x': 26, 'y': 125},
                <String, Object?>{'x': 30, 'y': 126},
                <String, Object?>{'x': 35, 'y': 127},
              ],
              'label': 'dataset1',
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear'},
          },
        },
      });

      final meta = chart.getDatasetMeta(0);
      for (var i = 0; i < meta.data.length; ++i) {
        final point = meta.data[i] as PointElement;
        expect(point.stop, i == 2);
      }
    });

    testWidgets('should honor spangap interval backwards', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'spanGaps': 10,
              'data': <Object?>[
                <String, Object?>{'x': 35, 'y': 123},
                <String, Object?>{'x': 30, 'y': 124},
                <String, Object?>{'x': 26, 'y': 125},
                <String, Object?>{'x': 15, 'y': 126},
                <String, Object?>{'x': 10, 'y': 127},
              ],
              'label': 'dataset1',
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear'},
          },
        },
      });

      final meta = chart.getDatasetMeta(0);
      for (var i = 0; i < meta.data.length; ++i) {
        final point = meta.data[i] as PointElement;
        expect(point.stop, i == 3);
      }
    });

    testWidgets('should correctly calc visible points on update', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': 10, 'y': 20},
                <String, Object?>{'x': 15, 'y': 19},
              ],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{'type': 'linear', 'min': 0, 'max': 25},
            'x': <String, Object?>{'type': 'linear', 'min': 0, 'max': 50},
          },
        },
      });

      _dataset(chart, 0)['data'] = <Object?>[
        <String, Object?>{'x': 10, 'y': 20},
        <String, Object?>{'x': 15, 'y': 19},
        <String, Object?>{'x': 17, 'y': 12},
        <String, Object?>{'x': 50, 'y': 9},
        <String, Object?>{'x': 50, 'y': 9},
        <String, Object?>{'x': 50, 'y': 9},
        <String, Object?>{'x': 51, 'y': 9},
        <String, Object?>{'x': 52, 'y': 9},
        <String, Object?>{'x': 52, 'y': 9},
      ];
      chart.update();

      final point = chart.getDatasetMeta(0).data[0];
      final event = _PointEvent(point);

      chart.handleEvent(event, false, true);

      final visiblePoints = chart
          .getSortedVisibleDatasetMetas()[0]
          .data
          .where((p) => !jsTruthy((p as types.PointElement).skip))
          .toList();

      expect(visiblePoints.length, 6);
    });

    testWidgets(
      'should correctly calc _drawStart and _drawCount when first points '
      'beyond scale limits are null and spanGaps=true',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>[0, 10, 20, 30, 40, 50],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[3, null, 2, 3, null, 1.5],
                'spanGaps': true,
                'tension': 0.4,
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear', 'min': 11, 'max': 40},
            },
          },
        })..update();

        final controller = chart.getDatasetMeta(0).controller!;

        expect(controller.drawStart, 0);
        expect(controller.drawCount, 6);
      },
    );

    testWidgets(
      'should correctly calc _drawStart and _drawCount when all points '
      'beyond scale limits are null and spanGaps=true',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>[0, 10, 20, 30, 40, 50],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[null, null, 2, 3, null, null],
                'spanGaps': true,
                'tension': 0.4,
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear', 'min': 11, 'max': 40},
            },
          },
        })..update();

        final controller = chart.getDatasetMeta(0).controller!;

        expect(controller.drawStart, 1);
        expect(controller.drawCount, 4);
      },
    );

    testWidgets(
      'should correctly calc _drawStart and _drawCount when spanGaps=false',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>[0, 10, 20, 30, 40, 50],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[3, null, 2, 3, null, 1.5],
                'spanGaps': false,
                'tension': 0.4,
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear', 'min': 11, 'max': 40},
            },
          },
        })..update();

        final controller = chart.getDatasetMeta(0).controller!;

        expect(controller.drawStart, 1);
        expect(controller.drawCount, 4);
      },
    );

    // :1161
    testWidgets('should not override tooltip title and label callbacks', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['Label 1', 'Label 2'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[21, 79],
              'label': 'Dataset 1',
            },
            <String, Object?>{
              'data': <Object?>[33, 67],
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
            'lines': <Object?>['Dataset 1: 21'],
            'after': <Object?>[],
          },
        ]),
      );

      (chart.options['plugins']! as Map<String, Object?>)['tooltip'] =
          <String, Object?>{'mode': 'dataset'};
      chart.update();
      await triggerMouseEvent(chart, 'mousemove', point);

      expect(tooltip.title, jasmineEquals(<Object?>['Dataset 1']));
      expect(
        tooltip.body,
        jasmineEquals(<Object?>[
          <String, Object?>{
            'before': <Object?>[],
            'lines': <Object?>['Label 1: 21'],
            'after': <Object?>[],
          },
          <String, Object?>{
            'before': <Object?>[],
            'lines': <Object?>['Label 2: 79'],
            'after': <Object?>[],
          },
        ]),
      );
    });
  });
}
