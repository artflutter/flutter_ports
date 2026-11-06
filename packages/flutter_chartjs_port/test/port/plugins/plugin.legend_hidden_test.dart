// Original code, not ported from Chart.js: the items of a hidden legend.
@TestOn('vm')
library;

import 'dart:collection';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/widgets.dart' hide Element;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as typed;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.doughnut.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.pie.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.polarArea.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart';
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart' show TRBL;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// The tests of Chart.js ADR 0092 and of the row `adapt-hidden-legend-items`
// of differences.md. A hidden legend of a built-in slice chart leaves its
// items pending, and the first read of `legendItems` builds them.
//
// A twin of a chart is the same config with a `filter` that keeps each item:
// that guard fails, so the twin builds at each upstream point, as upstream.

const _kinds = ['pie', 'doughnut', 'polarArea'];

const _red = Color(0xffff0000);
const _green = Color(0xff00ff00);
const _blue = Color(0xff0000ff);
const _black = Color(0xff000000);

/// The config of a hidden legend of the type [type]. [legend], [labels],
/// [dataset] and [options] add keys to the matching objects.
Map<String, Object?> _config(
  String type, {
  Map<String, Object?> legend = const {},
  Map<String, Object?> labels = const {},
  Map<String, Object?> dataset = const {},
  Map<String, Object?> options = const {},
  Object? labelValues,
  Object? datasets,
  List<Object?>? plugins,
}) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{
    'labels': labelValues ?? <Object?>['a', 'b', 'c'],
    'datasets':
        datasets ??
        <Object?>[
          <String, Object?>{
            'label': 'one',
            'data': <Object?>[1, 2, 3],
            'backgroundColor': _red,
            'borderColor': _blue,
            'borderWidth': 2,
            ...dataset,
          },
        ],
  },
  'options': <String, Object?>{
    'plugins': <String, Object?>{
      'legend': <String, Object?>{
        'display': false,
        'labels': <String, Object?>{...labels},
        ...legend,
      },
    },
    ...options,
  },
  'plugins': ?plugins,
};

bool _keepItem(Object? item, Object? data) => true;

/// The twin of a config of [_config]: it adds the `filter` that keeps each
/// item.
Map<String, Object?> _eager(
  String type, {
  Map<String, Object?> labels = const {},
  Map<String, Object?> legend = const {},
  Map<String, Object?> dataset = const {},
  Map<String, Object?> options = const {},
  List<Object?>? plugins,
}) => _config(
  type,
  labels: {'filter': _keepItem, ...labels},
  legend: legend,
  dataset: dataset,
  options: options,
  plugins: plugins,
);

Legend _legendOf(Chart chart) => chart.legend! as Legend;

/// The items of [legend] as plain data: the keys in order and the values.
List<Object?> _items(types.LegendElement legend) => [
  for (final item in legend.legendItems!)
    [
      for (final key in jsObjectKeys(item)) [key, jsGet(item, key)],
    ],
];

/// A list of another class: each read can run user code.
final class _ObservedList extends ListBase<Object?> {
  _ObservedList(this.values);

  final List<Object?> values;
  int reads = 0;

  @override
  int get length {
    reads++;
    return values.length;
  }

  @override
  set length(int value) => values.length = value;

  @override
  Object? operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, Object? value) => values[index] = value;
}

/// A trivial user subclass of the pie controller.
final class _PieChild extends PieController {
  _PieChild(super.chart, super.datasetIndex, [super.newTarget]);
}

final JsClass _pieChild = JsClass(
  'PieChild',
  superclass: PieController.jsClass,
  statics: {'id': 'pieChild'},
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return _PieChild(chart, datasetIndex, newTarget);
  },
);

/// A trivial user subclass of the doughnut controller.
final class _DoughnutChild extends DoughnutController {
  _DoughnutChild(super.chart, super.datasetIndex, [super.newTarget]);
}

final JsClass _doughnutChild = JsClass(
  'DoughnutChild',
  superclass: DoughnutController.jsClass,
  statics: {'id': 'doughnutChild'},
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return _DoughnutChild(chart, datasetIndex, newTarget);
  },
);

/// A trivial user subclass of the polar area controller.
final class _PolarChild extends PolarAreaController {
  _PolarChild(super.chart, super.datasetIndex, [super.newTarget]);
}

final JsClass _polarChild = JsClass(
  'PolarChild',
  superclass: PolarAreaController.jsClass,
  statics: {'id': 'polarChild'},
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return _PolarChild(chart, datasetIndex, newTarget);
  },
);

/// A trivial user subclass of the chart.
final class _ChildChart extends Chart {
  _ChildChart(super.item, [super.userConfig]);
}

/// A user subclass of the box, with a count of its builds.
final class _CountingLegend extends Legend {
  _CountingLegend(super.config);

  int builds = 0;

  @override
  void buildLabels() {
    builds++;
    super.buildLabels();
  }
}

final class _Margins implements TRBL {
  @override
  double get top => 0;

  @override
  double get bottom => 0;

  @override
  double get left => 0;

  @override
  double get right => 0;
}

/// The hook names of an update, in their order, for a plugin that reads the
/// items in each one.
const _hooks = [
  'beforeUpdate',
  'beforeElementsUpdate',
  'beforeLayout',
  'afterLayout',
  'beforeDatasetsUpdate',
  'beforeDatasetUpdate',
  'afterDatasetUpdate',
  'afterDatasetsUpdate',
  'afterUpdate',
  'beforeRender',
  'afterRender',
  'beforeDraw',
  'afterDraw',
];

/// An inline plugin that reads the items in each hook of [_hooks], except
/// when [armed] gives false, and appends them to [log].
Map<String, Object?> _reader(List<Object?> log, bool Function() armed) => {
  'id': 'reader',
  for (final hook in _hooks)
    hook: (Chart chart, Object? args, Object? options) {
      if (armed()) log.add([hook, _items(chart.legend!)]);
      return null;
    },
};

void main() {
  group('a read gives the items of the eager build', () {
    for (final type in _kinds) {
      testWidgets('$type: after the update and after a second update', (
        tester,
      ) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(_legendOf(twin).legendItemsPending, isFalse);
        expect(_items(chart.legend!), _items(twin.legend!));
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(chart.legend!.legendItems, hasLength(3));

        for (final each in [chart, twin]) {
          (jsGet(each.data, 'labels')! as List<Object?>).add('d');
          final dataset =
              (jsGet(each.data, 'datasets')! as List<Object?>)[0]!
                  as Map<String, Object?>;
          (dataset['data']! as List<Object?>).add(4);
          each.update();
        }
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(_items(chart.legend!), _items(twin.legend!));
        expect(chart.legend!.legendItems, hasLength(4));
      });

      testWidgets('$type: in each mode of an update', (tester) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        for (final mode in ['none', 'resize', 'default', 'active', 'none']) {
          chart.update(mode);
          twin.update(mode);
          expect(_items(chart.legend!), _items(twin.legend!), reason: mode);
        }
      });

      testWidgets('$type: reverse without user code', (tester) async {
        final chart = acquireChart(_config(type, legend: {'reverse': true}));
        final twin = acquireChart(_eager(type, legend: {'reverse': true}));
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(jsGet(chart.legend!.legendItems![0], 'text'), 'c');
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: a plain label option and a theme-free chart color', (
        tester,
      ) async {
        final labels = <String, Object?>{
          'pointStyle': 'star',
          'textAlign': 'right',
          'color': _green,
          'useBorderRadius': true,
          'borderRadius': 3,
        };
        final chart = acquireChart(_config(type, labels: labels));
        final twin = acquireChart(_eager(type, labels: labels));
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: the read of a plugin in each hook', (tester) async {
        var armed = false;
        final log = <Object?>[];
        final twinLog = <Object?>[];
        final chart = acquireChart(
          _config(type, plugins: [_reader(log, () => armed)]),
        );
        final twin = acquireChart(
          _eager(type, plugins: [_reader(twinLog, () => armed)]),
        );
        armed = true;
        chart
          ..update()
          ..draw();
        twin
          ..update()
          ..draw();
        expect(log, isNotEmpty);
        expect(log, twinLog);
      });

      testWidgets('$type: a plugin that reads in afterUpdate', (tester) async {
        Object? seen;
        Object? twinSeen;
        Map<String, Object?> reader(void Function(Object?) keep) => {
          'id': 'afterUpdateReader',
          'afterUpdate': (Chart chart, Object? args, Object? options) {
            keep(_items(chart.legend!));
            return null;
          },
        };
        final chart = acquireChart(
          _config(type, plugins: [reader((items) => seen = items)]),
        );
        final twin = acquireChart(
          _eager(type, plugins: [reader((items) => twinSeen = items)]),
        );
        expect(seen, isNotNull);
        expect(seen, twinSeen);
        // The read in the hook ended the wait. The items stay.
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: a toggle of display', (tester) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        void set(Object? display) {
          for (final each in [chart, twin]) {
            ((jsGet(each.config.options, 'plugins')!
                        as Map<String, Object?>)['legend']!
                    as Map<String, Object?>)['display'] =
                display;
            each.update();
          }
        }

        expect(_legendOf(chart).legendItemsPending, isTrue);
        set(true);
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(chart.legend!.legendHitBoxes, hasLength(3));
        expect(_legendOf(chart).height, greaterThan(0));
        expect(_items(chart.legend!), _items(twin.legend!));
        set(false);
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(_legendOf(chart).height, 0);
        expect(_items(chart.legend!), _items(twin.legend!));
        set(true);
        expect(_legendOf(chart).width, _legendOf(twin).width);
        expect(_legendOf(chart).height, _legendOf(twin).height);
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: a visibility change with an update', (tester) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        for (final each in [chart, twin]) {
          each
            ..toggleDataVisibility(1)
            ..update();
        }
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(jsGet(chart.legend!.legendItems![1], 'hidden'), isTrue);
        expect(_items(chart.legend!), _items(twin.legend!));
      });
    }

    for (final type in _kinds) {
      testWidgets('$type: a data-only update marks and reads', (tester) async {
        Map<String, Object?> make() => _config(
          type,
          options: {
            'responsive': false,
            'animation': false,
            'plugins': <String, Object?>{
              'legend': <String, Object?>{'display': false},
              'tooltip': false,
              'title': false,
              'subtitle': false,
              'colors': false,
              'decimation': false,
              'filler': false,
            },
            if (type == 'polarArea')
              'scales': <String, Object?>{
                'r': <String, Object?>{
                  'type': 'radialLinear',
                  'min': 0.0,
                  'max': 10.0,
                },
              },
          },
          labelValues: <String>['a', 'b', 'c'],
          dataset: {
            'data': <Object?>[1.0, 2.0, 3.0],
          },
        );
        void change(Chart chart) {
          final dataset =
              (jsGet(chart.data, 'datasets')! as List<Object?>)[0]!
                  as Map<String, Object?>;
          final values = dataset['data']! as List<Object?>;
          for (var i = 0; i < values.length; i++) {
            values[i] = 4.0 + i;
          }
        }

        final chart = acquireChart(make());
        final twin = acquireChart(make());
        final legend = _legendOf(chart);
        change(chart);
        change(twin);
        expect(chart.updateData(), isTrue);
        twin
          ..update('none')
          ..legend!.legendItems;
        expect(legend.legendItemsPending, isTrue);
        final items = _items(legend);
        expect(items, _items(twin.legend!));
        // An eager build in the same state is the twin of the deferred build.
        legend.buildLabels();
        expect(_items(legend), items);
      });
    }
  });

  group('the polar area update in the mode none', () {
    testWidgets('it writes the default entry that the ordinary build writes', (
      tester,
    ) async {
      final chart = acquireChart(_config('polarArea'));
      final controller = chart.getDatasetMeta(0).controller!;
      chart.update('none');
      expect(_legendOf(chart).legendItemsPending, isTrue);
      expect(controller.hasCachedDefaultDataOptions, isTrue);
      expect(controller.hasStaticDataUpdateOptions, isTrue);
      final twin = acquireChart(_eager('polarArea'))..update('none');
      expect(
        twin.getDatasetMeta(0).controller!.hasCachedDefaultDataOptions,
        isTrue,
      );
      expect(_items(chart.legend!), _items(twin.legend!));
    });

    testWidgets('the proof holds for the layout of the next update', (
      tester,
    ) async {
      var pendingAfterLayout = false;
      final chart =
          acquireChart(
              _config(
                'polarArea',
                plugins: [
                  {
                    'id': 'layoutProbe',
                    'afterLayout':
                        (Chart chart, Object? args, Object? options) {
                          pendingAfterLayout = _legendOf(chart)
                              .legendItemsPending;
                          return null;
                        },
                  },
                ],
              ),
            )
            ..update('none')
            ..update('none');
      expect(_legendOf(chart).legendItemsPending, isTrue);
      expect(pendingAfterLayout, isTrue);
    });
  });

  group('each guard keeps the ordinary path', () {
    /// Runs one update on the config [config] and on its twin with a [filter],
    /// and compares the calls of a counter and the items.
    Future<void> expectEager(
      Map<String, Object?> Function({
        Map<String, Object?> labels,
        Map<String, Object?> legend,
        Map<String, Object?> dataset,
        Map<String, Object?> options,
      })
      make, {
      required int Function() calls,
      required void Function() reset,
      required String type,
      Map<String, Object?> labels = const {},
      Map<String, Object?> legend = const {},
      Map<String, Object?> dataset = const {},
      Map<String, Object?> options = const {},
    }) async {
      reset();
      final chart = acquireChart(
        make(
          labels: labels,
          legend: legend,
          dataset: dataset,
          options: options,
        ),
      )..update();
      final seen = calls();
      expect(_legendOf(chart).legendItemsPending, isFalse);
      reset();
      final twin = acquireChart(
        _eager(
          type,
          labels: labels,
          legend: legend,
          dataset: dataset,
          options: options,
        ),
      )..update();
      expect(seen, calls());
      expect(seen, greaterThan(0));
      expect(_items(chart.legend!), _items(twin.legend!));
    }

    for (final type in _kinds) {
      Map<String, Object?> make({
        Map<String, Object?> labels = const {},
        Map<String, Object?> legend = const {},
        Map<String, Object?> dataset = const {},
        Map<String, Object?> options = const {},
      }) => _config(
        type,
        labels: labels,
        legend: legend,
        dataset: dataset,
        options: options,
      );

      testWidgets('$type: a user generateLabels: 3 calls for each update', (
        tester,
      ) async {
        var calls = 0;
        final chart = acquireChart(
          _config(
            type,
            labels: {
              'generateLabels': (Object? chart) {
                calls++;
                return <Object?>[
                  <String, Object?>{'text': 'x'},
                ];
              },
            },
          ),
        );
        expect(calls, 3);
        expect(_legendOf(chart).legendItemsPending, isFalse);
        chart.update();
        expect(calls, 6);
        expect(_items(chart.legend!), [
          [
            ['text', 'x'],
          ],
        ]);
      });

      testWidgets('$type: filter: one call for each item of each build', (
        tester,
      ) async {
        var calls = 0;
        final chart = acquireChart(
          _config(
            type,
            labels: {
              'filter': (Object? item, Object? data) {
                calls++;
                return true;
              },
            },
          ),
        );
        expect(calls, 9);
        expect(_legendOf(chart).legendItemsPending, isFalse);
      });

      testWidgets('$type: sort: the comparator runs in each build', (
        tester,
      ) async {
        var calls = 0;
        final chart = acquireChart(
          _config(
            type,
            labels: {
              'sort': (Object? a, Object? b, Object? data) {
                calls++;
                return 0;
              },
            },
          ),
        );
        expect(calls, greaterThan(0));
        final first = calls;
        calls = 0;
        chart.update();
        expect(calls, first);
        expect(_legendOf(chart).legendItemsPending, isFalse);
      });

      testWidgets('$type: display true', (tester) async {
        final chart = acquireChart(_config(type, legend: {'display': true}));
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(chart.legend!.legendHitBoxes, hasLength(3));
      });

      for (final (name, value) in [
        ('null', null),
        ('0', 0),
        ('an empty string', ''),
      ]) {
        testWidgets('$type: a falsy display that is not false: $name', (
          tester,
        ) async {
          final chart = acquireChart(_config(type, legend: {'display': value}));
          expect(_legendOf(chart).legendItemsPending, isFalse);
          expect(_legendOf(chart).height, 0);
        });
      }

      testWidgets('$type: a scriptable display', (tester) async {
        var calls = 0;
        await expectEager(
          make,
          type: type,
          legend: {
            'display': (Object? context, Object? options) {
              calls++;
              return false;
            },
          },
          calls: () => calls,
          reset: () => calls = 0,
        );
      });

      testWidgets('$type: a scriptable reverse', (tester) async {
        var calls = 0;
        await expectEager(
          make,
          type: type,
          legend: {
            'reverse': (Object? context, Object? options) {
              calls++;
              return true;
            },
          },
          calls: () => calls,
          reset: () => calls = 0,
        );
      });

      for (final key in const ['pointStyle', 'color']) {
        testWidgets('$type: a scriptable label option: $key', (tester) async {
          var calls = 0;
          await expectEager(
            make,
            type: type,
            labels: {
              key: (Object? context, Object? options) {
                calls++;
                return key == 'color' ? _red : 'star';
              },
            },
            calls: () => calls,
            reset: () => calls = 0,
          );
        });
      }

      testWidgets('$type: a function in a key of no read is still no proof', (
        tester,
      ) async {
        final chart = acquireChart(
          _config(
            type,
            labels: {
              // A polar area generator does not read it, a doughnut one does.
              'textAlign': (Object? context, Object? options) => 'left',
            },
          ),
        );
        expect(_legendOf(chart).legendItemsPending, isFalse);
      });

      testWidgets('$type: a scriptable color of the chart', (tester) async {
        var calls = 0;
        await expectEager(
          make,
          type: type,
          options: {
            'color': (Object? context, Object? options) {
              calls++;
              return _red;
            },
          },
          calls: () => calls,
          reset: () => calls = 0,
        );
      });

      testWidgets('$type: scriptable colors: the same calls', (tester) async {
        var calls = 0;
        await expectEager(
          make,
          type: type,
          dataset: {
            'backgroundColor': (Object? context, Object? options) {
              calls++;
              return _red;
            },
          },
          calls: () => calls,
          reset: () => calls = 0,
        );
      });

      testWidgets('$type: indexed colors stay eager', (tester) async {
        final chart = acquireChart(
          _config(
            type,
            dataset: {
              'backgroundColor': <Object?>[_red, _green, _blue],
            },
          ),
        );
        final twin = acquireChart(
          _eager(
            type,
            dataset: {
              'backgroundColor': <Object?>[_red, _green, _blue],
            },
          ),
        );
        chart.update('none');
        twin.update('none');
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(jsGet(chart.legend!.legendItems![1], 'fillStyle'), _green);
        expect(_items(chart.legend!), _items(twin.legend!));
        // Each element keeps the context mode of the last build.
        final context = (chart.getDatasetMeta(0).data[1] as dynamic).$context;
        final twinContext =
            (twin.getDatasetMeta(0).data[1] as dynamic).$context;
        expect(jsGet(context, 'mode'), jsGet(twinContext, 'mode'));
      });

      testWidgets('$type: a List of another class for the labels', (
        tester,
      ) async {
        final labels = _ObservedList(['a', 'b', 'c']);
        final chart = acquireChart(_config(type, labelValues: labels));
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(chart.legend!.legendItems, hasLength(3));
      });

      testWidgets('$type: a List of another class for the datasets', (
        tester,
      ) async {
        final datasets = _ObservedList([
          <String, Object?>{
            'data': <Object?>[1, 2, 3],
            'backgroundColor': _red,
          },
        ]);
        final chart = acquireChart(_config(type, datasets: datasets));
        expect(_legendOf(chart).legendItemsPending, isFalse);
      });

      testWidgets('$type: empty labels and no datasets', (tester) async {
        final noLabels = acquireChart(_config(type, labelValues: <Object?>[]));
        expect(_legendOf(noLabels).legendItemsPending, isFalse);
        expect(noLabels.legend!.legendItems, isEmpty);
        final noDatasets = acquireChart(_config(type, datasets: <Object?>[]));
        expect(_legendOf(noDatasets).legendItemsPending, isFalse);
        expect(noDatasets.legend!.legendItems, isEmpty);
      });

      testWidgets('$type: xLabels stand in the list of the category source', (
        tester,
      ) async {
        final config = _config(type);
        (config['data']! as Map<String, Object?>)['xLabels'] = <Object?>[
          'x',
          'y',
          'z',
        ];
        final chart = acquireChart(config);
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(jsGet(chart.legend!.legendItems![0], 'text'), 'a');
      });

      testWidgets('$type: a subclass of the chart', (tester) async {
        final canvas = UiCanvasElement(width: 300, height: 300);
        final chart = _ChildChart(canvas, _config(type));
        addTearDown(chart.destroy);
        final reference = acquireChart(_eager(type));
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(_items(chart.legend!), _items(reference.legend!));
      });
    }

    for (final (key, value) in <(String, Object?)>[
      ('textAlign', 'left'),
      ('useBorderRadius', true),
      ('borderRadius', 2),
    ]) {
      testWidgets('doughnut: a scriptable label option: $key', (tester) async {
        var calls = 0;
        Object? script(Object? context, Object? options) {
          calls++;
          return value;
        }

        final chart = acquireChart(_config('doughnut', labels: {key: script}))
          ..update();
        final seen = calls;
        expect(_legendOf(chart).legendItemsPending, isFalse);
        calls = 0;
        final twin = acquireChart(_eager('doughnut', labels: {key: script}))
          ..update();
        expect(seen, calls);
        // One call for each update, at the first read of the first build.
        expect(seen, 2);
        expect(_items(chart.legend!), _items(twin.legend!));
      });
    }

    for (final (id, parent, child) in [
      ('pieChild', 'pie', _pieChild),
      ('doughnutChild', 'doughnut', _doughnutChild),
      ('polarChild', 'polarArea', _polarChild),
    ]) {
      testWidgets('a subclass of the controller: $id', (tester) async {
        registry.addControllers([child]);
        addTearDown(() => registry.removeControllers([child]));
        // The same input through the exact class and through the subclass.
        final chart = acquireChart(_config(id));
        final exact = acquireChart(_config(parent));
        final controller = chart.getDatasetMeta(0).controller!;
        expect(controller.nativeLegendGenerator, isNull);
        expect(
          exact.getDatasetMeta(0).controller!.nativeLegendGenerator,
          isNotNull,
        );
        for (final mode in ['none', 'default']) {
          chart.update(mode);
          exact.update(mode);
          expect(_legendOf(chart).legendItemsPending, isFalse);
          expect(_legendOf(exact).legendItemsPending, isTrue);
          expect(_items(chart.legend!), _items(exact.legend!));
        }
      });
    }

    testWidgets('a first dataset of another controller', (tester) async {
      final chart = acquireChart(
        _config(
          'polarArea',
          dataset: {'type': 'doughnut'},
          options: {
            'scales': <String, Object?>{
              'r': <String, Object?>{'type': 'radialLinear'},
            },
          },
        ),
      );
      final controller = chart.getDatasetMeta(0).controller!;
      expect(controller.nativeLegendGenerator, isNotNull);
      expect(_legendOf(chart).legendItemsPending, isFalse);
      expect(chart.legend!.legendItems, hasLength(3));
    });

    testWidgets('a line chart has its generator of the file', (tester) async {
      final chart = acquireChart(_config('line'));
      expect(_legendOf(chart).legendItemsPending, isFalse);
      expect(chart.legend!.legendItems, hasLength(1));
    });

    testWidgets('a subclass of the box builds at each update', (tester) async {
      final chart = acquireChart(_config('pie'));
      final box = _CountingLegend((
        chart: chart,
        options: _legendOf(chart).options,
        ctx: chart.ctx,
      ));
      chart.legend = box;
      box.update(100, 100, _Margins());
      expect(box.builds, 1);
      expect(box.legendItemsPending, isFalse);
    });

    testWidgets('a box that is not chart.legend builds at each update', (
      tester,
    ) async {
      final chart = acquireChart(_config('pie'));
      final box = Legend((
        chart: chart,
        options: _legendOf(chart).options,
        ctx: chart.ctx,
      ))..update(100, 100, _Margins());
      expect(box.legendItemsPending, isFalse);
      expect(box.legendItems, hasLength(3));
    });

    testWidgets('a direct buildLabels stays eager', (tester) async {
      final chart = acquireChart(_config('pie'));
      final legend = _legendOf(chart);
      expect(legend.legendItemsPending, isTrue);
      legend.buildLabels();
      expect(legend.legendItemsPending, isFalse);
      final items = legend.legendItems;
      expect(items, hasLength(3));
      expect(legend.legendItems, same(items));
    });

    testWidgets('a write ends the wait', (tester) async {
      final chart = acquireChart(_config('pie'));
      final legend = _legendOf(chart);
      expect(legend.legendItemsPending, isTrue);
      final mine = <Object?>[];
      legend.legendItems = mine;
      expect(legend.legendItemsPending, isFalse);
      expect(legend.legendItems, same(mine));
      // As an upstream build, the next update takes the place of the write.
      chart.update();
      expect(legend.legendItems, hasLength(3));
    });
  });

  group('a box that is not chart.legend any more', () {
    testWidgets('a read gives the last built items and throws nothing', (
      tester,
    ) async {
      final chart = acquireChart(_config('pie'));
      final legend = _legendOf(chart);
      final built = legend.legendItems;
      chart.update();
      expect(legend.legendItemsPending, isTrue);
      final other = _CountingLegend((
        chart: chart,
        options: legend.options,
        ctx: chart.ctx,
      ));
      chart.legend = other;
      expect(legend.legendItems, same(built));
      expect(legend.legendItemsPending, isFalse);
      expect(other.builds, 0);
      chart.legend = legend;
    });
  });

  group('the list of a read', () {
    testWidgets('the same List until the next mark, then a new List', (
      tester,
    ) async {
      final chart = acquireChart(_config('doughnut'));
      final legend = _legendOf(chart);
      final first = legend.legendItems;
      expect(legend.legendItems, same(first));
      chart.update();
      final second = legend.legendItems;
      expect(second, isNot(same(first)));
      expect(legend.legendItems, same(second));
    });
  });

  group('differences.md adapt-hidden-legend-items', () {
    for (final type in _kinds) {
      testWidgets('$type: an in-place change with no update', (tester) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        for (final each in [chart, twin]) {
          (jsGet(each.data, 'labels')! as List<Object?>)[0] = 'changed';
          each.toggleDataVisibility(2);
        }
        // Upstream, and the twin: the snapshot of the last update.
        expect(jsGet(twin.legend!.legendItems![0], 'text'), 'a');
        expect(jsGet(twin.legend!.legendItems![2], 'hidden'), isFalse);
        // A pending build: the values at the first read.
        expect(jsGet(chart.legend!.legendItems![0], 'text'), 'changed');
        expect(jsGet(chart.legend!.legendItems![2], 'hidden'), isTrue);
        // The read is a snapshot until the next mark.
        (jsGet(chart.data, 'labels')! as List<Object?>)[0] = 'again';
        expect(jsGet(chart.legend!.legendItems![0], 'text'), 'changed');
        // The next update gives the values of upstream again.
        chart.update();
        twin.update();
        (jsGet(twin.data, 'labels')! as List<Object?>)[0] = 'again';
        twin.update();
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: an in-place style change keeps the cached entry', (
        tester,
      ) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        for (final each in [chart, twin]) {
          ((jsGet(each.data, 'datasets')! as List<Object?>)[0]!
                  as Map<String, Object?>)['backgroundColor'] =
              _black;
        }
        // The cached entry of the last update answers both builds.
        expect(jsGet(chart.legend!.legendItems![0], 'fillStyle'), _red);
        expect(_items(chart.legend!), _items(twin.legend!));
      });
    }

    testWidgets('a read in a hook after a dataset color change', (
      tester,
    ) async {
      var armed = false;
      final seen = <Object?>[];
      final twinSeen = <Object?>[];
      Map<String, Object?> reader(List<Object?> log) => {
        'id': 'colorReader',
        'afterDatasetsUpdate': (Chart chart, Object? args, Object? options) {
          if (armed) log.add(jsGet(chart.legend!.legendItems![0], 'fillStyle'));
          return null;
        },
      };
      final chart = acquireChart(_config('pie', plugins: [reader(seen)]));
      final twin = acquireChart(_eager('pie', plugins: [reader(twinSeen)]));
      armed = true;
      for (final each in [chart, twin]) {
        ((jsGet(each.data, 'datasets')! as List<Object?>)[0]!
                as Map<String, Object?>)['backgroundColor'] =
            _black;
        each.update();
      }
      // Upstream: the layout build, with the entry of the last update.
      expect(twinSeen, [_red]);
      // A pending build: the entry of this update, at the read.
      expect(seen, [_black]);
      // Both give the value of upstream after the update.
      expect(_items(chart.legend!), _items(twin.legend!));
    });
  });

  group('stop', () {
    for (final type in _kinds) {
      testWidgets('$type: a kept box after destroy gives its items', (
        tester,
      ) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        final legend = _legendOf(chart);
        final twinItems = _items(twin.legend!);
        expect(legend.legendItemsPending, isTrue);
        releaseChart(chart);
        expect(chart.legend, isNull);
        expect(legend.legendItemsPending, isFalse);
        expect(_items(legend), twinItems);
      });

      testWidgets('$type: the plugin goes in an update', (tester) async {
        final chart = acquireChart(_config(type));
        final legend = _legendOf(chart);
        expect(legend.legendItemsPending, isTrue);
        (jsGet(chart.config.options, 'plugins')!
                as Map<String, Object?>)['legend'] =
            false;
        chart.update();
        expect(chart.legend, isNull);
        expect(legend.legendItems, hasLength(3));
      });
    }

    testWidgets('a broken data state at stop keeps the last built items', (
      tester,
    ) async {
      final chart = acquireChart(_config('pie'));
      final legend = _legendOf(chart);
      final built = legend.legendItems;
      chart.update();
      expect(legend.legendItemsPending, isTrue);
      (chart.data as Map<String, Object?>)['labels'] = <String, Object?>{
        'length': 1,
      };
      releaseChart(chart);
      expect(legend.legendItemsPending, isFalse);
      expect(legend.legendItems, same(built));
    });
  });

  group('ChartView', () {
    typed.ChartConfig config(
      List<double> data, {
      typed.ChartKind kind = typed.ChartKind.pie,
      typed.ChartValue<Color> color = const typed.ChartValue.constant(
        Color(0xff4f6bed),
      ),
    }) => typed.ChartConfig(
      type: kind,
      labels: const ['a', 'b', 'c'],
      datasets: [
        switch (kind) {
          typed.ChartKind.polarArea => typed.PolarAreaDataset(
            data: data,
            backgroundColor: color,
            borderWidth: 0,
          ),
          typed.ChartKind.doughnut => typed.DoughnutDataset(
            data: data,
            backgroundColor: color,
            borderWidth: 0,
          ),
          _ => typed.PieDataset(
            data: data,
            backgroundColor: color,
            borderWidth: 0,
          ),
        },
      ],
      animation: typed.ChartAnimation.none,
      legend: const typed.ChartLegend(display: false),
    );

    Widget view(typed.ChartConfig config, [typed.ChartThemeData? theme]) {
      final Widget chart = Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 300,
            child: typed.ChartView(config: config, updateMode: 'none'),
          ),
        ),
      );
      return theme == null
          ? chart
          : typed.ChartTheme(data: theme, child: chart);
    }

    Chart chartOf(WidgetTester tester) => Chart.getChart(
      tester.renderObject<RenderChartHost>(find.byType(ChartHost)).canvas,
    )!;

    // The config of a live slice chart of apps/chart_benchmark_lab: a stable
    // label List, a new data List in each frame and an empty theme.
    for (final kind in const [
      typed.ChartKind.pie,
      typed.ChartKind.doughnut,
      typed.ChartKind.polarArea,
    ]) {
      testWidgets('$kind: the config of a live chart of the lab', (
        tester,
      ) async {
        final labels = <String>[for (var i = 0; i < 200; i++) '$i'];
        const color = typed.ChartValue<Color>.constant(Color(0xff4f6bed));
        const radius = typed.ChartLength.percent(90);
        Widget frame(int step) {
          final data = <double>[for (var i = 0; i < 200; i++) 1.0 + step + i];
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                height: 300,
                child: typed.ChartView(
                  config: typed.ChartConfig(
                    type: kind,
                    labels: labels,
                    datasets: [
                      switch (kind) {
                        typed.ChartKind.polarArea => typed.PolarAreaDataset(
                          key: const ValueKey('series'),
                          label: 'Values',
                          data: data,
                          backgroundColor: color,
                          borderWidth: 0,
                        ),
                        typed.ChartKind.doughnut => typed.DoughnutDataset(
                          key: const ValueKey('series'),
                          label: 'Values',
                          data: data,
                          backgroundColor: color,
                          borderWidth: 0,
                          radius: radius,
                          cutout: const typed.ChartLength.percent(50),
                        ),
                        _ => typed.PieDataset(
                          key: const ValueKey('series'),
                          label: 'Values',
                          data: data,
                          backgroundColor: color,
                          borderWidth: 0,
                          radius: radius,
                        ),
                      },
                    ],
                    scales: kind == typed.ChartKind.polarArea
                        ? const {
                            'r': typed.RadialLinearAxis(
                              min: 0,
                              max: 100,
                              display: false,
                              pointLabelsDisplay: false,
                              angleLinesDisplay: false,
                            ),
                          }
                        : null,
                    animation: typed.ChartAnimation.none,
                    legend: const typed.ChartLegend(display: false),
                    tooltip: const typed.ChartTooltip(enabled: false),
                    responsive: true,
                    maintainAspectRatio: false,
                    extra: const {'events': <String>[]},
                  ),
                  updateMode: 'none',
                  theme: const typed.ChartThemeData(),
                  excludeFromSemantics: true,
                ),
              ),
            ),
          );
        }

        var pendingFrames = 0;
        await tester.pumpWidget(frame(0));
        final chart = chartOf(tester);
        final legend = _legendOf(chart);
        for (var step = 1; step < 4; step++) {
          await tester.pumpWidget(frame(step));
          if (legend.legendItemsPending) pendingFrames++;
        }
        expect(pendingFrames, 3);
        final items = _items(legend);
        expect(items, hasLength(200));
        legend.buildLabels();
        expect(_items(legend), items);
      });
    }

    for (final kind in const [
      typed.ChartKind.pie,
      typed.ChartKind.doughnut,
      typed.ChartKind.polarArea,
    ]) {
      for (final (name, theme) in [
        ('unthemed', null),
        ('light', const typed.ChartThemeData.light()),
        ('dark', const typed.ChartThemeData.dark()),
      ]) {
        testWidgets('$kind $name: a live chart marks and reads', (
          tester,
        ) async {
          await tester.pumpWidget(view(config([1, 2, 3], kind: kind), theme));
          await tester.pumpWidget(view(config([2, 3, 4], kind: kind), theme));
          await tester.pumpWidget(view(config([3, 4, 5], kind: kind), theme));
          final legend = _legendOf(chartOf(tester));
          expect(legend.legendItemsPending, isTrue);
          final items = _items(legend);
          expect(items, hasLength(3));
          legend.buildLabels();
          expect(_items(legend), items);
        });
      }

      testWidgets('$kind: indexed colors stay eager', (tester) async {
        const indexed = typed.ChartValue<Color>.indexed([
          Color(0xff4f6bed),
          Color(0xffed4f6b),
        ]);
        await tester.pumpWidget(
          view(config([1, 2, 3], kind: kind, color: indexed)),
        );
        await tester.pumpWidget(
          view(config([2, 3, 4], kind: kind, color: indexed)),
        );
        final legend = _legendOf(chartOf(tester));
        expect(legend.legendItemsPending, isFalse);
        expect(legend.legendItems, hasLength(3));
      });
    }
  });
}
