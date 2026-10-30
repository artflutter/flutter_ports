// Original code, not ported from Chart.js: tests of the typed callbacks.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show JsFunction;
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0052, section 6: the views and the details objects of the
// typed callbacks over the objects of a real chart. The raw callbacks of
// these charts cast the arguments of the chart to the views, as the
// lowering of the typed config does: `ChartHit`, `ChartContext`,
// `ChartTooltipItem` and `ChartLegendItem` give `int` indexes and the
// values of the objects, and a `List<ActiveElement>` is a `List<ChartHit>`
// with no copy. The unit cases pin the rule for the JS `undefined`, an
// absent key and a value of another type.
//
// VM only: the chart cases are `testWidgets` cases of the harness.

/// A bar chart with the labels `a`, `b`, `c` and the datasets `A` and `B`,
/// with no animation and the options [options].
Map<String, Object?> _bar(Map<String, Object?> options) => <String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'A',
        'data': <Object?>[1, 2, 3],
      },
      <String, Object?>{
        'label': 'B',
        'data': <Object?>[3, 2, 7],
      },
    ],
  },
  'options': <String, Object?>{'animation': false, ...options},
};

/// The center of the legend hit box [index] of [chart].
Map<String, Object?> _legendBox(Chart chart, int index) {
  final box = chart.legend!.legendHitBoxes[index];
  final left = box['left']! as num;
  final top = box['top']! as num;
  final width = box['width']! as num;
  final height = box['height']! as num;
  return <String, Object?>{'x': left + width / 2, 'y': top + height / 2};
}

/// [hits] as a `List<ActiveElement>`: this compiles because `ChartHit`
/// implements `ActiveElement`.
List<ActiveElement> _asActive(List<ChartHit> hits) => hits;

void main() {
  group('ChartHit and ChartEventDetails', () {
    testWidgets('onClick gets the hits with int indexes and no copy', (
      tester,
    ) async {
      Object? active;
      ChartEventDetails? details;
      final chart = acquireChart(
        _bar(<String, Object?>{
          'onClick': (Object? event, Object? elements, Object? chart) {
            active = elements;
            details = ChartEventDetails(
              event: event! as ChartEvent,
              hits: elements! as List<ChartHit>,
              chart: chart! as Chart,
            );
          },
        }),
      );
      final element = chart.getDatasetMeta(1).data[2];
      await triggerMouseEvent(chart, 'click', element);

      final hit = details!.hits.single;
      expect(hit.datasetIndex, isA<int>());
      expect([hit.datasetIndex, hit.index], [1, 2]);
      expect(hit.element, same(element));
      expect(details!.hits, same(active));
      expect(details!.event.type, 'click');
      expect(details!.chart, same(chart));
    });

    testWidgets('the hits go back to setActiveElements', (tester) async {
      List<ChartHit>? hits;
      final chart = acquireChart(
        _bar(<String, Object?>{
          'onHover': (Object? event, Object? elements, Object? chart) {
            hits = elements! as List<ChartHit>;
          },
        }),
      );
      await triggerMouseEvent(
        chart,
        'mousemove',
        chart.getDatasetMeta(0).data[1],
      );
      final hovered = List<ChartHit>.of(hits!);
      chart.setActiveElements(<Object?>[]);
      expect(chart.getActiveElements(), isEmpty);
      chart.setActiveElements(_asActive(hovered));
      expect(
        [
          for (final element in chart.getActiveElements())
            [element.datasetIndex, element.index],
        ],
        [
          [0, 1],
        ],
      );
    });
  });

  group('ChartContext', () {
    testWidgets('a scriptable option gets the chart, dataset and data '
        'contexts', (tester) async {
      final contexts = <ChartContext>[];
      // Chart.js keeps one context object for each element and sets its
      // `active` at each resolution: the state at the call.
      final activeAtCall = <(int?, bool)>[];
      String record(Object? context, Object? options) {
        final view = context! as ChartContext;
        contexts.add(view);
        activeAtCall.add((view.dataIndex, view.active));
        return 'rgba(255, 0, 0, 1)';
      }

      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[5, 7],
              'borderColor': record,
              'hoverBorderColor': record,
            },
          ],
        },
        'options': <String, Object?>{
          'animation': false,
          'layout': <String, Object?>{
            'padding': (Object? context, Object? options) {
              contexts.add(context! as ChartContext);
              return 0;
            },
          },
        },
      });

      final chartContext = contexts.firstWhere((c) => c.type == 'chart');
      expect(chartContext.chart, same(chart));
      expect(
        [
          chartContext.datasetIndex,
          chartContext.dataIndex,
          chartContext.active,
          chartContext.raw,
          chartContext.parsed,
        ],
        [null, null, false, null, null],
      );

      final datasetContext = contexts.firstWhere((c) => c.type == 'dataset');
      expect(datasetContext.chart, same(chart));
      expect(
        [
          datasetContext.datasetIndex,
          datasetContext.dataIndex,
          datasetContext.active,
          datasetContext.raw,
        ],
        [0, null, false, null],
      );

      final dataContext = contexts.lastWhere(
        (c) => c.type == 'data' && c.dataIndex == 1,
      );
      expect(dataContext.chart, same(chart));
      expect(dataContext.datasetIndex, isA<int>());
      expect(dataContext.dataIndex, isA<int>());
      expect(
        [
          dataContext.datasetIndex,
          dataContext.dataIndex,
          dataContext.active,
          dataContext.raw,
        ],
        [0, 1, false, 7],
      );
      expect((dataContext.parsed! as Map<String, Object?>)['y'], 7);

      activeAtCall.clear();
      await triggerMouseEvent(
        chart,
        'mousemove',
        chart.getDatasetMeta(0).data[1],
      );
      expect(
        activeAtCall,
        contains((1, true)),
        reason: 'the hover style resolves in an active context',
      );
    });

    test('undefined, an absent key and another type give null', () {
      final context = <String, Object?>{
        'type': 'data',
        'raw': undefined,
        'parsed': undefined,
        'datasetIndex': 1.0,
        'dataIndex': 'x',
        'active': 1,
      } as ChartContext;
      expect(
        [
          context.type,
          context.raw,
          context.parsed,
          context.datasetIndex,
          context.dataIndex,
          context.active,
        ],
        ['data', null, null, 1, null, false],
      );
      expect((<String, Object?>{} as ChartContext).type, isNull);
    });
  });

  group('ChartTooltipItem', () {
    testWidgets('a tooltip label callback gets the item of the hit', (
      tester,
    ) async {
      final items = <ChartTooltipItem>[];
      final chart = acquireChart(
        _bar(<String, Object?>{
          'plugins': <String, Object?>{
            'tooltip': <String, Object?>{
              'callbacks': <String, Object?>{
                'label': (Object? item) {
                  items.add(item! as ChartTooltipItem);
                  return 'L';
                },
              },
            },
          },
        }),
      );
      await triggerMouseEvent(
        chart,
        'mousemove',
        chart.getDatasetMeta(1).data[2],
      );

      final item = items.last;
      expect(item.chart, same(chart));
      expect(item.datasetIndex, isA<int>());
      expect(item.dataIndex, isA<int>());
      expect(
        [
          item.label,
          item.formattedValue,
          item.datasetIndex,
          item.dataIndex,
          item.raw,
          item.datasetLabel,
        ],
        ['c', '7', 1, 2, 7, 'B'],
      );
      expect((item.parsed! as Map<String, Object?>)['y'], 7);
    });

    test('a dataset without a String label gives no datasetLabel', () {
      final item = <String, Object?>{
        'dataset': <String, Object?>{'label': 3},
        'raw': undefined,
        'formattedValue': '1',
        'datasetIndex': 0.0,
        'dataIndex': 2.0,
      } as ChartTooltipItem;
      expect([item.datasetLabel, item.raw, item.label], [null, null, null]);
      expect([item.datasetIndex, item.dataIndex], [0, 2]);
      expect(
        (<String, Object?>{
          'dataset': undefined,
        } as ChartTooltipItem).datasetLabel,
        isNull,
      );
    });
  });

  group('ChartLegendItem and ChartLegendEventDetails', () {
    testWidgets('a legend onClick gets a dataset item', (tester) async {
      ChartLegendEventDetails? details;
      final chart = acquireChart(
        _bar(<String, Object?>{
          'plugins': <String, Object?>{
            'legend': <String, Object?>{
              'onClick': (Object? event, Object? item, Object? legend) {
                details = ChartLegendEventDetails(
                  event: event! as ChartEvent,
                  item: item! as ChartLegendItem,
                  legend: legend! as LegendElement,
                );
              },
            },
          },
        }),
      );
      await triggerMouseEvent(chart, 'click', _legendBox(chart, 1));

      final item = details!.item;
      expect(item.datasetIndex, isA<int>());
      expect(
        [item.text, item.datasetIndex, item.index, item.hidden],
        ['B', 1, null, false],
      );
      expect(details!.legend, same(chart.legend));
      expect(details!.event.type, 'click');
      // The onClick of the app replaces the default toggle.
      expect(chart.isDatasetVisible(1), isTrue);
    });

    testWidgets('a doughnut legend item has the data index', (tester) async {
      ChartLegendItem? clicked;
      final chart =
          acquireChart(<String, Object?>{
              'type': 'doughnut',
              'data': <String, Object?>{
                'labels': <Object?>['a', 'b', 'c'],
                'datasets': <Object?>[
                  <String, Object?>{
                    'data': <Object?>[1, 2, 3],
                  },
                ],
              },
              'options': <String, Object?>{
                'animation': false,
                'plugins': <String, Object?>{
                  'legend': <String, Object?>{
                    'onClick': (Object? event, Object? item, Object? legend) {
                      clicked = item! as ChartLegendItem;
                    },
                  },
                },
              },
            })
            ..toggleDataVisibility(2)
            ..update();
      await triggerMouseEvent(chart, 'click', _legendBox(chart, 2));

      expect(clicked!.index, isA<int>());
      expect(
        [clicked!.text, clicked!.datasetIndex, clicked!.index, clicked!.hidden],
        ['c', null, 2, true],
      );
    });

    test('another type gives null', () {
      final item = <Object?, Object?>{
        'text': <Object?>['two', 'lines'],
        'datasetIndex': undefined,
        'index': double.nan,
        'hidden': 'yes',
      } as ChartLegendItem;
      expect(
        [item.text, item.datasetIndex, item.index, item.hidden],
        [null, null, null, false],
      );
    });
  });

  group('AxisTickInfo', () {
    testWidgets('a tick callback with the scale as this gets the tick', (
      tester,
    ) async {
      final infos = <AxisTickInfo>[];
      final chart = acquireChart(
        _bar(<String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{
              'ticks': <String, Object?>{
                'callback': JsFunction((
                  Object? scale,
                  Object? value,
                  Object? index,
                  Object? ticks,
                ) {
                  infos.add(
                    AxisTickInfo(
                      value: value! as double,
                      index: (index! as num).toInt(),
                      ticks: ticks! as List<Tick>,
                      scale: scale! as Scale,
                    ),
                  );
                  return 'T';
                }),
              },
            },
          },
        }),
      );

      final scale = chart.scales['y']!;
      final last = infos.where((info) => identical(info.scale, scale)).last;
      expect(last.index, last.ticks.length - 1);
      expect(last.value, last.ticks[last.index].value);
      expect(last.value, isA<double>());
    });
  });
}
