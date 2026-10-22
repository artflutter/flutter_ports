// Ported from Chart.js v4.5.1+7169e651 test/specs/core.interaction.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.interaction.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// The spec calls the modes of Chart.Interaction, which is the Interaction of
// lib/src/core/core.interaction.dart. Each case reads the elements of a
// chart that a dataset controller updates. A chart case is a `testWidgets`
// case, and the file runs on the VM (Chart.js ADR 0030, section 12 item 5).
// It does not call `setUpSpecs()`: its charts need the built-in components.
// test/port/core/core.interaction_test.dart covers the modes with fake
// charts, metas and elements, also on the web legs.
//
// The spec forms:
// - The event object `{type: 'click', chart, native: true, x, y}` is an
//   `_Event`, a `types.ChartEvent`. Upstream `native: true` makes
//   `getRelativePosition` read `x` and `y` of the object
//   (helpers.dom.ts:105, `'native' in event`). The port tests the type
//   `types.ChartEvent` for the same branch. Thus `native` of the `_Event`
//   is Dart `null`.
// - `Chart.Interaction.modes.point(chart, evt, {})` is
//   `Interaction.modes['point']!(chart, evt, {})`.
//   `.map(item => item.element)` is `_elements`.
// - `toEqual` is `jasmineEquals`. Jasmine compares two elements by their
//   properties. The elements of the expected values are the same objects as
//   the actual elements, so the identity of `jasmineEquals` gives the same
//   result.
// - `meta.data[i].x` is `_data(meta, i).x`, an `Element` of
//   core.element.dart.
// - A `beforeEach` that acquires a chart is a local function that each case
//   calls first. `this.chart` is a `late` variable of the group. A `data`
//   object of a `describe` is a variable of the group closure, shared by the
//   charts of its cases, as upstream.
// - `chart.data.datasets[i]` is `_dataset(chart, i)`.
// - `expect(elements).not.toContain(x)` is `isNot(contains(x))`, and
//   `expect(elements).toContain(x)` is `contains(x)`.

/// The event object `{type: 'click', chart, native: true, x, y}` of the
/// spec.
final class _Event implements types.ChartEvent {
  _Event(this.chart, this.x, this.y);

  @override
  String get type => 'click';

  @override
  NativeEvent? get native => null;

  @override
  final types.Chart? chart;

  @override
  final double? x;

  @override
  final double? y;
}

/// `items.map(item => item.element)`.
List<Object?> _elements(List<InteractionItem> items) => [
  for (final item in items) item.element,
];

/// `meta.data[index]` of [meta], an element of core.element.dart.
Element _data(types.ChartMeta meta, int index) => meta.data[index] as Element;

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as AnyObject;

/// The two datasets of the line charts of the spec: `data` of
/// `Dataset 1` and `Dataset 2`, and their `pointRadius` (none for null).
List<Object?> _datasets(
  List<Object?> data1,
  List<Object?> data2, {
  List<Object?>? radius1,
  List<Object?>? radius2,
}) => <Object?>[
  <String, Object?>{
    'label': 'Dataset 1',
    'data': data1,
    'pointRadius': ?radius1,
    'pointHoverBorderColor': 'rgb(255, 0, 0)',
    'pointHoverBackgroundColor': 'rgb(0, 255, 0)',
  },
  <String, Object?>{
    'label': 'Dataset 2',
    'data': data2,
    'pointRadius': ?radius2,
    'pointHoverBorderColor': 'rgb(0, 0, 255)',
    'pointHoverBackgroundColor': 'rgb(0, 255, 255)',
  },
];

/// The labels of the line charts of the spec.
List<Object?> _labels() => <Object?>['Point 1', 'Point 2', 'Point 3'];

/// core.interaction.tests.js:916 `testCases`, the data of the cases of
/// :997-1024.
const List<
  ({List<Object?> data, int clickPointIndex, int expectedNearestPointIndex})
>
_testCases = [
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 0,
    expectedNearestPointIndex: 0,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 1,
    expectedNearestPointIndex: 1,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 2,
    expectedNearestPointIndex: 1,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 3,
    expectedNearestPointIndex: 1,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 4,
    expectedNearestPointIndex: 6,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 5,
    expectedNearestPointIndex: 6,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 6,
    expectedNearestPointIndex: 6,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 7,
    expectedNearestPointIndex: 7,
  ),
  (
    data: [12, 0, null, null, null, null, 0, 2],
    clickPointIndex: 3,
    expectedNearestPointIndex: 1,
  ),
  (
    data: [12, 0, null, null, null, null, 0, 2],
    clickPointIndex: 4,
    expectedNearestPointIndex: 6,
  ),
  (
    data: [12, -1, null, null, null, null, -1, 2],
    clickPointIndex: 3,
    expectedNearestPointIndex: 1,
  ),
  (
    data: [12, -1, null, null, null, null, -1, 2],
    clickPointIndex: 4,
    expectedNearestPointIndex: 6,
  ),
  (data: [null, 2], clickPointIndex: 0, expectedNearestPointIndex: 1),
  (data: [2, null], clickPointIndex: 1, expectedNearestPointIndex: 0),
  (data: [null, null, 2], clickPointIndex: 0, expectedNearestPointIndex: 2),
  (data: [2, null, null], clickPointIndex: 2, expectedNearestPointIndex: 0),
];

void main() {
  group('Core.Interaction', () {
    group('auto', fixture.specs('core.interaction'));

    group('point mode', () {
      late Chart chart;

      void beforeEach() {
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': _datasets(<Object?>[10, 20, 30], <Object?>[40, 20, 40]),
            'labels': _labels(),
          },
        });
      }

      testWidgets('should return all items under the point', (tester) async {
        beforeEach();
        final meta0 = chart.getDatasetMeta(0);
        final meta1 = chart.getDatasetMeta(1);
        final point = _data(meta0, 1);

        final evt = _Event(chart, point.x, point.y);

        final elements = _elements(
          Interaction.modes['point']!(chart, evt, <String, Object?>{}),
        );
        expect(elements, jasmineEquals(<Object?>[point, meta1.data[1]]));
      });

      testWidgets('should return an empty array when no items are found', (
        tester,
      ) async {
        beforeEach();
        final evt = _Event(chart, 0, 0);

        final elements = _elements(
          Interaction.modes['point']!(chart, evt, <String, Object?>{}),
        );
        expect(elements, jasmineEquals(<Object?>[]));
      });
    });

    group('index mode', () {
      group('intersect: true', () {
        late Chart chart;

        void beforeEach() {
          chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': _datasets(
                <Object?>[10, 20, 30],
                <Object?>[40, 40, 40],
              ),
              'labels': _labels(),
            },
          });
        }

        testWidgets('gets correct items', (tester) async {
          beforeEach();
          final meta0 = chart.getDatasetMeta(0);
          final meta1 = chart.getDatasetMeta(1);
          final point = _data(meta0, 1);

          final evt = _Event(chart, point.x, point.y);

          final elements = _elements(
            Interaction.modes['index']!(chart, evt, <String, Object?>{
              'intersect': true,
            }),
          );
          expect(elements, jasmineEquals(<Object?>[point, meta1.data[1]]));
        });

        testWidgets('returns empty array when nothing found', (tester) async {
          beforeEach();
          final evt = _Event(chart, 0, 0);

          final elements = _elements(
            Interaction.modes['index']!(chart, evt, <String, Object?>{
              'intersect': true,
            }),
          );
          expect(elements, jasmineEquals(<Object?>[]));
        });
      });

      group('intersect: false', () {
        final data = <String, Object?>{
          'datasets': _datasets(<Object?>[10, 20, 30], <Object?>[40, 40, 40]),
          'labels': _labels(),
        };

        late Chart chart;

        void beforeEach() {
          chart = acquireChart(<String, Object?>{'type': 'line', 'data': data});
        }

        testWidgets('axis: x gets correct items', (tester) async {
          beforeEach();
          final meta0 = chart.getDatasetMeta(0);
          final meta1 = chart.getDatasetMeta(1);

          final evt = _Event(
            chart,
            chart.chartArea!.left,
            chart.chartArea!.top,
          );

          final elements = _elements(
            Interaction.modes['index']!(chart, evt, <String, Object?>{
              'intersect': false,
            }),
          );
          expect(
            elements,
            jasmineEquals(<Object?>[meta0.data[0], meta1.data[0]]),
          );
        });

        testWidgets('axis: y gets correct items', (tester) async {
          beforeEach();
          final chart = acquireChart(<String, Object?>{
            'type': 'bar',
            'data': data,
            'options': <String, Object?>{'indexAxis': 'y'},
          });

          final meta0 = chart.getDatasetMeta(0);
          final meta1 = chart.getDatasetMeta(1);
          final center = (meta0.data[0] as types.VisualElement)
              .getCenterPoint();

          final evt = _Event(chart, center.x, center.y! + 30);

          final elements = _elements(
            Interaction.modes['index']!(chart, evt, <String, Object?>{
              'axis': 'y',
              'intersect': false,
            }),
          );
          expect(
            elements,
            jasmineEquals(<Object?>[meta0.data[0], meta1.data[0]]),
          );
        });

        testWidgets('axis: xy gets correct items', (tester) async {
          beforeEach();
          final meta0 = chart.getDatasetMeta(0);
          final meta1 = chart.getDatasetMeta(1);

          final evt = _Event(
            chart,
            chart.chartArea!.left,
            chart.chartArea!.top,
          );

          final elements = _elements(
            Interaction.modes['index']!(chart, evt, <String, Object?>{
              'axis': 'xy',
              'intersect': false,
            }),
          );
          expect(
            elements,
            jasmineEquals(<Object?>[meta0.data[0], meta1.data[0]]),
          );
        });
      });
    });

    group('dataset mode', () {
      group('intersect: true', () {
        late Chart chart;

        void beforeEach() {
          chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': _datasets(
                <Object?>[10, 20, 30],
                <Object?>[40, 40, 40],
              ),
              'labels': _labels(),
            },
          });
        }

        testWidgets(
          'should return all items in the dataset of the first item found',
          (tester) async {
            beforeEach();
            final meta = chart.getDatasetMeta(0);
            final point = _data(meta, 1);

            final evt = _Event(chart, point.x, point.y);

            final elements = _elements(
              Interaction.modes['dataset']!(chart, evt, <String, Object?>{
                'intersect': true,
              }),
            );
            expect(elements, jasmineEquals(meta.data));
          },
        );

        testWidgets('should return an empty array if nothing found', (
          tester,
        ) async {
          beforeEach();
          final evt = _Event(chart, 0, 0);

          final elements = Interaction.modes['dataset']!(
            chart,
            evt,
            <String, Object?>{'intersect': true},
          );
          expect(elements, jasmineEquals(<Object?>[]));
        });
      });

      group('intersect: false', () {
        final data = <String, Object?>{
          'datasets': _datasets(<Object?>[10, 20, 30], <Object?>[40, 40, 40]),
          'labels': _labels(),
        };

        late Chart chart;

        void beforeEach() {
          chart = acquireChart(<String, Object?>{'type': 'line', 'data': data});
        }

        testWidgets('axis: x gets correct items', (tester) async {
          beforeEach();
          final chart = acquireChart(<String, Object?>{
            'type': 'bar',
            'data': data,
            'options': <String, Object?>{'indexAxis': 'y'},
          });

          final evt = _Event(
            chart,
            chart.chartArea!.left,
            chart.chartArea!.top,
          );

          final elements = _elements(
            Interaction.modes['dataset']!(chart, evt, <String, Object?>{
              'axis': 'x',
              'intersect': false,
            }),
          );
          expect(elements, jasmineEquals(chart.getDatasetMeta(0).data));
        });

        testWidgets('axis: y gets correct items', (tester) async {
          beforeEach();
          final evt = _Event(
            chart,
            chart.chartArea!.left,
            chart.chartArea!.top,
          );

          final elements = _elements(
            Interaction.modes['dataset']!(chart, evt, <String, Object?>{
              'axis': 'y',
              'intersect': false,
            }),
          );
          expect(elements, jasmineEquals(chart.getDatasetMeta(1).data));
        });

        testWidgets('axis: xy gets correct items', (tester) async {
          beforeEach();
          final evt = _Event(
            chart,
            chart.chartArea!.left,
            chart.chartArea!.top,
          );

          final elements = _elements(
            Interaction.modes['dataset']!(chart, evt, <String, Object?>{
              'intersect': false,
            }),
          );
          expect(elements, jasmineEquals(chart.getDatasetMeta(1).data));
        });
      });
    });

    group('nearest mode', () {
      group('intersect: false', () {
        late Chart lineChart;
        late Chart polarChart;

        void beforeEach() {
          lineChart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': _datasets(
                <Object?>[10, 40, 30],
                <Object?>[40, 40, 40],
                radius1: <Object?>[5, 5, 5],
                radius2: <Object?>[10, 10, 10],
              ),
              'labels': _labels(),
            },
          });
          polarChart = acquireChart(<String, Object?>{
            'type': 'polarArea',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[1, 9, 5],
                },
              ],
              'labels': _labels(),
            },
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'legend': <String, Object?>{'display': false},
              },
            },
          });
        }

        group('axis: xy', () {
          testWidgets('should return the nearest item', (tester) async {
            beforeEach();
            final chart = lineChart;
            final evt = _Event(
              chart,
              chart.chartArea!.left,
              chart.chartArea!.top,
            );

            // Nearest to 0,0 (top left) will be first point of dataset 2
            final elements = _elements(
              Interaction.modes['nearest']!(chart, evt, <String, Object?>{
                'intersect': false,
              }),
            );
            final meta = chart.getDatasetMeta(1);
            expect(elements, jasmineEquals(<Object?>[meta.data[0]]));
          });

          testWidgets('should return all items at the same nearest distance', (
            tester,
          ) async {
            beforeEach();
            final chart = lineChart;
            final meta0 = chart.getDatasetMeta(0);
            final meta1 = chart.getDatasetMeta(1);

            // Halfway between 2 mid points
            final pt = (
              x: _data(meta0, 1).x,
              y: (_data(meta0, 1).y + _data(meta1, 1).y) / 2,
            );

            final evt = _Event(chart, pt.x, pt.y);

            // Both points are nearest
            final elements = _elements(
              Interaction.modes['nearest']!(chart, evt, <String, Object?>{
                'intersect': false,
              }),
            );
            expect(
              elements,
              jasmineEquals(<Object?>[meta0.data[1], meta1.data[1]]),
            );
          });
        });

        group('axis: x', () {
          testWidgets('should return all items at current x', (tester) async {
            beforeEach();
            final chart = lineChart;
            final meta0 = chart.getDatasetMeta(0);
            final meta1 = chart.getDatasetMeta(1);

            // At 'Point 2', 10
            final pt = (x: _data(meta0, 1).x, y: _data(meta0, 0).y);

            final evt = _Event(chart, pt.x, pt.y);

            // Middle point from both series are nearest
            final elements = _elements(
              Interaction.modes['nearest']!(chart, evt, <String, Object?>{
                'axis': 'x',
                'intersect': false,
              }),
            );
            expect(
              elements,
              jasmineEquals(<Object?>[meta0.data[1], meta1.data[1]]),
            );
          });

          testWidgets('should return all items at nearest x-distance', (
            tester,
          ) async {
            beforeEach();
            final chart = lineChart;
            final meta0 = chart.getDatasetMeta(0);
            final meta1 = chart.getDatasetMeta(1);

            // Haflway between 'Point 1' and 'Point 2', y=10
            final pt = (
              x: (_data(meta0, 0).x + _data(meta0, 1).x) / 2,
              y: _data(meta0, 0).y,
            );

            final evt = _Event(chart, pt.x, pt.y);

            // Should return all (4) points from 'Point 1' and 'Point 2'
            final elements = _elements(
              Interaction.modes['nearest']!(chart, evt, <String, Object?>{
                'axis': 'x',
                'intersect': false,
              }),
            );
            expect(
              elements,
              jasmineEquals(<Object?>[
                meta0.data[0],
                meta0.data[1],
                meta1.data[0],
                meta1.data[1],
              ]),
            );
          });
        });

        group('axis: y', () {
          testWidgets('should return item with value 30', (tester) async {
            beforeEach();
            final chart = lineChart;
            final meta0 = chart.getDatasetMeta(0);

            // 'Point 1', y = 30
            final pt = (x: _data(meta0, 0).x, y: _data(meta0, 2).y);

            final evt = _Event(chart, pt.x, pt.y);

            // Middle point from both series are nearest
            final elements = _elements(
              Interaction.modes['nearest']!(chart, evt, <String, Object?>{
                'axis': 'y',
                'intersect': false,
              }),
            );
            expect(elements, jasmineEquals(<Object?>[meta0.data[2]]));
          });

          testWidgets('should return all items at value 40', (tester) async {
            beforeEach();
            final chart = lineChart;
            final meta0 = chart.getDatasetMeta(0);
            final meta1 = chart.getDatasetMeta(1);

            // 'Point 1', y = 40
            final pt = (x: _data(meta0, 0).x, y: _data(meta0, 1).y);

            final evt = _Event(chart, pt.x, pt.y);

            // Should return points with value 40
            final elements = _elements(
              Interaction.modes['nearest']!(chart, evt, <String, Object?>{
                'axis': 'y',
                'intersect': false,
              }),
            );
            expect(
              elements,
              jasmineEquals(<Object?>[
                meta0.data[1],
                meta1.data[0],
                meta1.data[1],
                meta1.data[2],
              ]),
            );
          });
        });

        group('axis: r', () {
          testWidgets('should return item with value 9', (tester) async {
            beforeEach();
            final chart = polarChart;
            final meta0 = chart.getDatasetMeta(0);

            final evt = _Event(chart, chart.width / 2, chart.height / 2 + 5);

            final elements = _elements(
              Interaction.modes['nearest']!(chart, evt, <String, Object?>{
                'axis': 'r',
              }),
            );
            expect(elements, jasmineEquals(<Object?>[meta0.data[1]]));
          });

          testWidgets(
            'should return item with value 1 when clicked outside of it',
            (tester) async {
              beforeEach();
              final chart = polarChart;
              final meta0 = chart.getDatasetMeta(0);

              final evt = _Event(chart, chart.width, 0);

              final elements = _elements(
                Interaction.modes['nearest']!(chart, evt, <String, Object?>{
                  'axis': 'r',
                  'intersect': false,
                }),
              );
              expect(elements, jasmineEquals(<Object?>[meta0.data[0]]));
            },
          );
        });
      });

      group('intersect: true', () {
        late Chart chart;

        void beforeEach() {
          chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': _datasets(
                <Object?>[10, 20, 30],
                <Object?>[40, 40, 40],
              ),
              'labels': _labels(),
            },
          });
        }

        group('axis=xy', () {
          testWidgets('should return the nearest item', (tester) async {
            beforeEach();
            final meta = chart.getDatasetMeta(1);
            final point = _data(meta, 1);

            var evt = _Event(chart, point.x + 15, point.y);

            // Nothing intersects so find nothing
            var elements = _elements(
              Interaction.modes['nearest']!(chart, evt, <String, Object?>{
                'intersect': true,
              }),
            );
            expect(elements, jasmineEquals(<Object?>[]));

            evt = _Event(chart, point.x, point.y);
            elements = _elements(
              Interaction.modes['nearest']!(chart, evt, <String, Object?>{
                'intersect': true,
              }),
            );
            expect(elements, jasmineEquals(<Object?>[point]));
          });

          testWidgets('should return the nearest item even if 2 intersect', (
            tester,
          ) async {
            beforeEach();
            _dataset(chart, 0)['pointRadius'] = <Object?>[5, 30, 5];
            (_dataset(chart, 0)['data']! as List<Object?>)[1] = 39;

            _dataset(chart, 1)['pointRadius'] = <Object?>[10, 10, 10];

            chart.update();

            // Trigger an event over top of the
            final meta0 = chart.getDatasetMeta(0);

            // Halfway between 2 mid points
            final pt = (x: _data(meta0, 1).x, y: _data(meta0, 1).y);

            final evt = _Event(chart, pt.x, pt.y);

            final elements = _elements(
              Interaction.modes['nearest']!(chart, evt, <String, Object?>{
                'intersect': true,
              }),
            );
            expect(elements, jasmineEquals(<Object?>[meta0.data[1]]));
          });

          testWidgets(
            'should return the all items if more than 1 are at the same '
            'distance',
            (tester) async {
              beforeEach();
              _dataset(chart, 0)['pointRadius'] = <Object?>[5, 5, 5];
              (_dataset(chart, 0)['data']! as List<Object?>)[1] = 40;

              _dataset(chart, 1)['pointRadius'] = <Object?>[10, 10, 10];

              chart.update();

              final meta0 = chart.getDatasetMeta(0);
              final meta1 = chart.getDatasetMeta(1);

              // Halfway between 2 mid points
              final pt = (x: _data(meta0, 1).x, y: _data(meta0, 1).y);

              final evt = _Event(chart, pt.x, pt.y);

              final elements = _elements(
                Interaction.modes['nearest']!(chart, evt, <String, Object?>{
                  'intersect': true,
                }),
              );
              expect(
                elements,
                jasmineEquals(<Object?>[meta0.data[1], meta1.data[1]]),
              );
            },
          );
        });
      });
    });

    group('x mode', () {
      late Chart chart;

      void beforeEach() {
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': _datasets(
              <Object?>[10, 40, 30],
              <Object?>[40, 40, 40],
              radius1: <Object?>[5, 10, 5],
              radius2: <Object?>[10, 10, 10],
            ),
            'labels': _labels(),
          },
        });
      }

      testWidgets(
        'should return items at the same x value when intersect is false',
        (tester) async {
          beforeEach();
          final meta0 = chart.getDatasetMeta(0);
          final meta1 = chart.getDatasetMeta(1);

          // Halfway between 2 mid points
          final pt = (x: _data(meta0, 1).x, y: _data(meta0, 1).y);

          var evt = _Event(chart, pt.x, 0);

          var elements = _elements(
            Interaction.modes['x']!(chart, evt, <String, Object?>{
              'intersect': false,
            }),
          );
          expect(
            elements,
            jasmineEquals(<Object?>[meta0.data[1], meta1.data[1]]),
          );

          evt = _Event(chart, pt.x + 20, 0);

          elements = _elements(
            Interaction.modes['x']!(chart, evt, <String, Object?>{
              'intersect': false,
            }),
          );
          expect(elements, jasmineEquals(<Object?>[]));
        },
      );

      testWidgets(
        'should return items at the same x value when intersect is true',
        (tester) async {
          beforeEach();
          final meta0 = chart.getDatasetMeta(0);
          final meta1 = chart.getDatasetMeta(1);

          // Halfway between 2 mid points
          final pt = (x: _data(meta0, 1).x, y: _data(meta0, 1).y);

          var evt = _Event(chart, pt.x, 0);

          var elements = _elements(
            Interaction.modes['x']!(chart, evt, <String, Object?>{
              'intersect': true,
            }),
          );
          expect(
            elements,
            jasmineEquals(<Object?>[]),
          ); // we don't intersect anything

          evt = _Event(chart, pt.x, pt.y);

          elements = _elements(
            Interaction.modes['x']!(chart, evt, <String, Object?>{
              'intersect': true,
            }),
          );
          expect(
            elements,
            jasmineEquals(<Object?>[meta0.data[1], meta1.data[1]]),
          );
        },
      );
    });

    group('y mode', () {
      late Chart chart;

      void beforeEach() {
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': _datasets(
              <Object?>[10, 40, 30],
              <Object?>[40, 40, 40],
              radius1: <Object?>[5, 10, 5],
              radius2: <Object?>[10, 10, 10],
            ),
            'labels': _labels(),
          },
        });
      }

      testWidgets(
        'should return items at the same y value when intersect is false',
        (tester) async {
          beforeEach();
          final meta0 = chart.getDatasetMeta(0);
          final meta1 = chart.getDatasetMeta(1);

          // Halfway between 2 mid points
          final pt = (x: _data(meta0, 1).x, y: _data(meta0, 1).y);

          var evt = _Event(chart, 0, pt.y);

          var elements = _elements(
            Interaction.modes['y']!(chart, evt, <String, Object?>{
              'intersect': false,
            }),
          );
          expect(
            elements,
            jasmineEquals(<Object?>[
              meta0.data[1],
              meta1.data[0],
              meta1.data[1],
              meta1.data[2],
            ]),
          );

          evt = _Event(chart, pt.x, pt.y + 20); // out of range

          elements = _elements(
            Interaction.modes['y']!(chart, evt, <String, Object?>{
              'intersect': false,
            }),
          );
          expect(elements, jasmineEquals(<Object?>[]));
        },
      );

      testWidgets(
        'should return items at the same y value when intersect is true',
        (tester) async {
          beforeEach();
          final meta0 = chart.getDatasetMeta(0);
          final meta1 = chart.getDatasetMeta(1);

          // Halfway between 2 mid points
          final pt = (x: _data(meta0, 1).x, y: _data(meta0, 1).y);

          var evt = _Event(chart, 0, pt.y);

          var elements = _elements(
            Interaction.modes['y']!(chart, evt, <String, Object?>{
              'intersect': true,
            }),
          );
          expect(
            elements,
            jasmineEquals(<Object?>[]),
          ); // we don't intersect anything

          evt = _Event(chart, pt.x, pt.y);

          elements = _elements(
            Interaction.modes['y']!(chart, evt, <String, Object?>{
              'intersect': true,
            }),
          );
          expect(
            elements,
            jasmineEquals(<Object?>[
              meta0.data[1],
              meta1.data[0],
              meta1.data[1],
              meta1.data[2],
            ]),
          );
        },
      );
    });

    group('tooltip element of scatter chart', () {
      testWidgets('out-of-range datapoints are not shown in tooltip', (
        tester,
      ) async {
        final data = <Object?>[];
        for (var i = 0; i < 1000; i++) {
          data.add(<String, Object?>{'x': i, 'y': i});
        }

        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': data},
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'min': 2},
            },
          },
        });

        final meta0 = chart.getDatasetMeta(0);
        final firstElement = _data(meta0, 0);

        final evt = _Event(chart, firstElement.x, firstElement.y);

        final elements = _elements(
          Interaction.modes['point']!(chart, evt, <String, Object?>{
            'intersect': true,
          }),
        );
        expect(elements, isNot(contains(firstElement)));
      });

      testWidgets('out-of-range datapoints are shown in tooltip if included', (
        tester,
      ) async {
        final data = <Object?>[];
        for (var i = 0; i < 1000; i++) {
          data.add(<String, Object?>{'x': i, 'y': i});
        }

        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': data},
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'min': 2},
            },
          },
        });

        final meta0 = chart.getDatasetMeta(0);
        final firstElement = _data(meta0, 0);

        final evt = _Event(chart, firstElement.x, firstElement.y);

        final elements = _elements(
          Interaction.modes['point']!(chart, evt, <String, Object?>{
            'intersect': true,
            'includeInvisible': true,
          }),
        );
        expect(elements, contains(firstElement));
      });
    });

    for (var i = 0; i < _testCases.length; i++) {
      final (:data, :clickPointIndex, :expectedNearestPointIndex) =
          _testCases[i];
      testWidgets(
        'should select nearest non-null element with index '
        '$expectedNearestPointIndex when clicking on element with index '
        '$clickPointIndex in test case ${i + 1} if spanGaps=true',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'labels': <Object?>[1, 2, 3, 4, 5, 6, 7, 8, 9],
              'datasets': <Object?>[
                <String, Object?>{
                  // The `data` of a const record cannot change. The chart
                  // listens to the array of its dataset, and a chart writes
                  // no item into it here. Thus a copy gives the same result.
                  'data': List<Object?>.of(data),
                  'spanGaps': true,
                },
              ],
            },
          })..update();
          final meta = chart.getDatasetMeta(0);
          final point = _data(meta, clickPointIndex);

          final evt = _Event(chart, point.x, point.y);

          final elements = _elements(
            Interaction.modes['nearest']!(chart, evt, <String, Object?>{
              'axis': 'x',
              'intersect': false,
            }),
          );
          expect(
            elements,
            jasmineEquals(<Object?>[meta.data[expectedNearestPointIndex]]),
          );
        },
      );
    }
  });
}
