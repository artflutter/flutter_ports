// Original code, not ported from Chart.js: tests of the typed callbacks.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/foundation.dart' show ValueChanged;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart'
    show AnimationEvent;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show createContext;
import 'package:flutter_chartjs_port/src/js/js_function.dart'
    show JsFunction, jsCall;
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
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
// The group "the lowered callbacks in a chart" runs the lowered typed
// config (Chart.js ADR 0052, section 2, rules 6 and 7): the trampolines of
// `onClick`, `onHover` and the legend give the details with `int` indexes
// and call the callback of the newest config; a tooltip text of Dart `null`
// gives the default text; a tick format gets the scale and gives the
// labels of a raw `JsFunction`; an animation callback gets the details of
// the `AnimationEvent`.
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
  final left = box.left;
  final top = box.top;
  final width = box.width;
  final height = box.height;
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
      expect((dataContext.parsed! as JsObjectFace)['y'], 7);

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
      // The typed context of a data item (Chart.js ADR 0054 §11).
      final context = createContext(null, <String, Object?>{
        'type': 'data',
        'raw': undefined,
        'parsed': undefined,
        'datasetIndex': 1.0,
        'dataIndex': 'x',
        'active': 1,
      }) as ChartContext;
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
      expect(
        (createContext(null, <String, Object?>{}) as ChartContext).type,
        isNull,
      );
      // A chart context has no member of a data context.
      final chartContext = createContext(null, <String, Object?>{
        'type': 'chart',
      }) as ChartContext;
      expect(
        [chartContext.type, chartContext.datasetIndex, chartContext.active],
        ['chart', null, false],
      );
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
      expect((item.parsed! as JsObjectFace)['y'], 7);
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

  group('the lowered callbacks in a chart', () {
    /// A typed bar chart with the labels `a`, `b`, `c` and the datasets `A`
    /// and `B`, with no animation, as [_bar].
    ChartConfig typedBar({
      ValueChanged<ChartEventDetails>? onClick,
      ValueChanged<ChartEventDetails>? onHover,
      ChartLegend? legend,
      ChartTooltip? tooltip,
      Map<String, ChartAxis>? scales,
    }) => ChartConfig(
      type: .bar,
      labels: const ['a', 'b', 'c'],
      datasets: const [
        BarDataset(label: 'A', data: [1, 2, 3]),
        BarDataset(label: 'B', data: [3, 2, 7]),
      ],
      scales: scales,
      legend: legend,
      tooltip: tooltip,
      animation: ChartAnimation.none,
      onClick: onClick,
      onHover: onHover,
    );

    testWidgets('onClick gets int hits, from the newest config', (
      tester,
    ) async {
      final calls = <(String, ChartEventDetails)>[];
      final lowering = ChartConfigLowering(
        typedBar(onClick: (details) => calls.add(('first', details))),
      );
      final chart = acquireChartRoot(lowering.lower());
      final element = chart.getDatasetMeta(1).data[2];
      await triggerMouseEvent(chart, 'click', element);

      final (name, details) = calls.single;
      expect(name, 'first');
      final hit = details.hits.single;
      expect(hit.datasetIndex, isA<int>());
      expect([hit.datasetIndex, hit.index], [1, 2]);
      expect(hit.element, same(element));
      expect(details.chart, same(chart));
      expect(details.event.type, 'click');

      // A new config with another closure: the trampoline of the chart
      // calls it with no new lowering.
      lowering.config = typedBar(
        onClick: (details) => calls.add(('second', details)),
      );
      await triggerMouseEvent(chart, 'click', element);
      expect([for (final (name, _) in calls) name], ['first', 'second']);
    });

    testWidgets('onHover gets the hits of a move', (tester) async {
      final hits = <List<ChartHit>>[];
      final chart = acquireChartRoot(
        ChartConfigLowering(
          typedBar(onHover: (details) => hits.add(details.hits)),
        ).lower(),
      );
      await triggerMouseEvent(
        chart,
        'mousemove',
        chart.getDatasetMeta(0).data[1],
      );
      expect(
        [for (final hit in hits.last) (hit.datasetIndex, hit.index)],
        [(0, 1)],
      );
    });

    testWidgets('a legend onClick replaces the default toggle', (
      tester,
    ) async {
      final items = <ChartLegendItem>[];
      final chart = acquireChartRoot(
        ChartConfigLowering(
          typedBar(
            legend: ChartLegend(onClick: (details) => items.add(details.item)),
          ),
        ).lower(),
      );
      await triggerMouseEvent(chart, 'click', _legendBox(chart, 1));
      expect([items.single.text, items.single.datasetIndex], ['B', 1]);
      expect(chart.isDatasetVisible(1), isTrue);
    });

    testWidgets('a tooltip text of null gives the default text', (
      tester,
    ) async {
      /// The title, the label lines and the footer of the tooltip of a
      /// hover on bar 2 of dataset 1 of [config].
      Future<List<Object?>> tooltipOf(Object config) async {
        final chart = acquireChartRoot(config);
        await triggerMouseEvent(
          chart,
          'mousemove',
          chart.getDatasetMeta(1).data[2],
        );
        final tooltip = chart.tooltip!;
        return [
          tooltip.title,
          [
            for (final item in tooltip.body!) (item! as JsObjectFace)['lines'],
          ],
          tooltip.footer,
        ];
      }

      final defaults = await tooltipOf(
        ChartConfigLowering(typedBar()).lower(),
      );
      expect(defaults, [
        ['c'],
        [
          ['B: 7'],
        ],
        <Object?>[],
      ]);
      final nulls = await tooltipOf(
        ChartConfigLowering(
          typedBar(
            tooltip: ChartTooltip(
              titleText: (items) => null,
              labelText: (item) => null,
              footerText: (items) => null,
            ),
          ),
        ).lower(),
      );
      expect(nulls, defaults);
      final texts = await tooltipOf(
        ChartConfigLowering(
          typedBar(
            tooltip: ChartTooltip(
              titleText: (items) => 'T ${items.length}',
              labelText: (item) => '${item.datasetLabel} ${item.dataIndex}',
              footerText: (items) => 'F ${items.single.formattedValue}',
            ),
          ),
        ).lower(),
      );
      expect(texts, [
        ['T 1'],
        [
          ['B 2'],
        ],
        ['F 7'],
      ]);
    });

    testWidgets('a tick format gets the scale, as a raw JsFunction', (
      tester,
    ) async {
      final infos = <AxisTickInfo>[];
      final typed = acquireChartRoot(
        ChartConfigLowering(
          typedBar(
            scales: {
              'y': LinearAxis(
                ticks: AxisTicks(
                  format: (tick) {
                    infos.add(tick);
                    return tick.index.isEven ? '${tick.value}' : null;
                  },
                ),
              ),
            },
          ),
        ).lower(),
      );
      final twin = acquireChart(
        _bar(<String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{
              'type': 'linear',
              'ticks': <String, Object?>{
                'callback': JsFunction((
                  Object? scale,
                  Object? value,
                  Object? index,
                  Object? ticks,
                ) {
                  return (index! as num).toInt().isEven ? '$value' : null;
                }),
              },
            },
          },
        }),
      );

      final scale = typed.scales['y']!;
      expect(infos.last.scale, same(scale));
      expect([
        for (final info in infos) info.value,
      ], everyElement(isA<double>()));
      List<Object?> labels(Chart chart) => [
        for (final tick in chart.scales['y']!.ticks!) tick.label,
      ];
      expect(labels(typed), labels(twin));
    });

    testWidgets('an animation callback gets the details of the event', (
      tester,
    ) async {
      final details = <ChartAnimationDetails>[];
      final lowering = ChartConfigLowering(
        ChartConfig(
          type: .bar,
          datasets: const [],
          animation: ChartAnimation(onComplete: details.add),
        ),
      );
      final options = lowering.lower()['options']! as JsObjectFace;
      final onComplete = (options['animation']! as JsObjectFace)['onComplete'];
      final chart = acquireChart(_bar(const <String, Object?>{}));
      jsCall(onComplete, [
        AnimationEvent(
          chart: chart,
          initial: true,
          numSteps: 1000,
          currentStep: 250,
        ),
      ]);
      jsCall(onComplete, [AnimationEvent(chart: chart)]);
      expect(
        [
          for (final d in details)
            [
              identical(d.chart, chart),
              d.initial,
              d.numSteps,
              d.currentStep,
            ],
        ],
        [
          [true, true, 1000, 250],
          [true, false, null, null],
        ],
      );
    });
  });
}
