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
import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsDeleteKey, jsGet, jsSet;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
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

/// The texts of the items of the box of [chart].
List<Object?> _texts(Chart chart) => [
  for (final item in chart.legend!.legendItems!) jsGet(item, 'text'),
];

/// `data.labels` of [chart].
List<Object?> _labelsOf(Chart chart) =>
    jsGet(chart.data, 'labels')! as List<Object?>;

/// `data.datasets` of [chart].
List<Object?> _datasetsOf(Chart chart) =>
    jsGet(chart.data, 'datasets')! as List<Object?>;

/// `options.plugins.legend.labels` of the config of [chart].
Map<String, Object?> _labelOptionsOf(Chart chart) =>
    ((jsGet(chart.config.options, 'plugins')!
                as Map<String, Object?>)['legend']!
            as Map<String, Object?>)['labels']!
        as Map<String, Object?>;

/// An inline plugin with the hook [hook]. A plugin of a chart has one id for
/// each hook name.
Map<String, Object?> _hook(String hook, Object? Function(Chart chart) run) => {
  'id': 'hook-$hook',
  hook: (Chart chart, Object? args, Object? options) => run(chart),
};

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

      testWidgets('$type: a function in a key of the generator', (
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
        expect(_legendOf(chart).legendItemsPending, type == 'polarArea');
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

  group('a read with a new first dataset', () {
    Map<String, Object?> dataset() => <String, Object?>{
      'label': 'new',
      'data': <Object?>[7, 8, 9],
      'backgroundColor': _green,
    };

    final replacements = <String, void Function(Chart)>{
      'a write at index 0': (chart) => _datasetsOf(chart)[0] = dataset(),
      'a new List': (chart) =>
          (chart.data as Map<String, Object?>)['datasets'] = <Object?>[
            dataset(),
          ],
      'the data setter': (chart) => chart.data = <String, Object?>{
        'labels': <Object?>['p', 'q', 'r'],
        'datasets': <Object?>[dataset()],
      },
      'an insert at index 0': (chart) =>
          _datasetsOf(chart).insert(0, dataset()),
    };

    for (final type in _kinds) {
      for (final MapEntry(key: name, value: replace) in replacements.entries) {
        testWidgets('$type: $name', (tester) async {
          final chart = acquireChart(_config(type));
          final twin = acquireChart(_eager(type));
          expect(_legendOf(chart).legendItemsPending, isTrue);
          final metas = chart.metasets.length;
          replace(chart);
          replace(twin);
          // The last built items: here they are the snapshot of upstream.
          expect(_items(chart.legend!), _items(twin.legend!));
          // The read adds no meta, as the snapshot of upstream does not.
          expect(chart.metasets, hasLength(metas));
          // The build still waits for a read that can run it.
          expect(_legendOf(chart).legendItemsPending, isTrue);
          chart.update();
          twin.update();
          expect(chart.getDatasetMeta(0).controller, isNotNull);
          expect(_items(chart.legend!), _items(twin.legend!));
        });
      }

      testWidgets('$type: a read in beforeUpdate keeps the update', (
        tester,
      ) async {
        var armed = false;
        final seen = <Object?>[];
        final twinSeen = <Object?>[];
        Map<String, Object?> reader(List<Object?> log) =>
            _hook('beforeUpdate', (
              chart,
            ) {
              if (armed) log.add(chart.legend!.legendItems!.length);
              return null;
            });
        final chart = acquireChart(_config(type, plugins: [reader(seen)]));
        final twin = acquireChart(_eager(type, plugins: [reader(twinSeen)]));
        armed = true;
        for (final each in [chart, twin]) {
          _labelsOf(each).add('d');
          _datasetsOf(each)[0] = <String, Object?>{
            'data': <Object?>[1, 2, 3, 4],
          };
          each.update();
          expect(each.getDatasetMeta(0).controller, isNotNull);
          expect(each.getDatasetMeta(0).data, hasLength(4));
          expect(each.legend!.legendItems, hasLength(4));
        }
        expect(seen, [3]);
        expect(seen, twinSeen);
      });
    }
  });

  group('a read after an option change', () {
    /// Runs [change] on a chart and on its twin, with a reader in [hook], and
    /// then the update. [read] gives the value of a read.
    Future<void> compare({
      required String type,
      required String hook,
      required void Function(Chart chart, void Function() count) change,
      Object? Function(Chart chart)? read,
    }) async {
      final seen = <Object?>[];
      final twinSeen = <Object?>[];
      var armed = false;
      Map<String, Object?> reader(List<Object?> log) => _hook(hook, (chart) {
        if (armed) log.add((read ?? _texts)(chart));
        return null;
      });
      var calls = 0;
      var twinCalls = 0;
      final chart = acquireChart(_config(type, plugins: [reader(seen)]));
      final twin = acquireChart(_eager(type, plugins: [reader(twinSeen)]));
      armed = true;
      // An update that the snapshot of upstream has and no build of a read.
      _labelsOf(chart)[0] = 'x';
      _labelsOf(twin)[0] = 'x';
      chart.update();
      twin.update();
      seen.clear();
      twinSeen.clear();
      change(chart, () => calls++);
      change(twin, () => twinCalls++);
      chart.update();
      twin.update();
      expect(seen, twinSeen);
      expect(calls, twinCalls);
      expect(_items(chart.legend!), _items(twin.legend!));
    }

    for (final type in _kinds) {
      for (final hook in const [
        'beforeUpdate',
        'beforeElementsUpdate',
        'beforeLayout',
      ]) {
        testWidgets('$type: $hook: a new filter', (tester) async {
          await compare(
            type: type,
            hook: hook,
            change: (chart, count) =>
                _labelOptionsOf(chart)['filter'] = (item, data) {
                  count();
                  return false;
                },
          );
        });

        testWidgets('$type: $hook: a new generateLabels', (tester) async {
          await compare(
            type: type,
            hook: hook,
            change: (chart, count) =>
                _labelOptionsOf(chart)['generateLabels'] = (chart) {
                  count();
                  return <Object?>[
                    <String, Object?>{'text': 'u'},
                  ];
                },
          );
        });

        testWidgets('$type: $hook: a new plain label option', (tester) async {
          await compare(
            type: type,
            hook: hook,
            change: (chart, count) =>
                _labelOptionsOf(chart)['pointStyle'] = 'star',
            read: (chart) => jsGet(chart.legend!.legendItems![0], 'pointStyle'),
          );
        });

        testWidgets('$type: $hook: a sort that throws at the update', (
          tester,
        ) async {
          Object? atRead;
          var armed = false;
          Map<String, Object?> reader() => _hook(hook, (chart) {
            if (!armed) return null;
            try {
              chart.legend!.legendItems;
            } on Object catch (error) {
              atRead = error;
              rethrow;
            }
            return null;
          });
          final chart = acquireChart(_config(type, plugins: [reader()]));
          final twin = acquireChart(_eager(type, plugins: [reader()]));
          armed = true;
          for (final each in [chart, twin]) {
            _labelsOf(each)[0] = 'x';
            each.update();
            _labelOptionsOf(each)['sort'] = (a, b, data) =>
                throw StateError('sort');
            expect(each.update, throwsStateError);
          }
          expect(atRead, isNull);
          // The snapshot of the last update.
          expect(_texts(chart), ['x', 'b', 'c']);
          expect(_items(chart.legend!), _items(twin.legend!));
        });
      }

      testWidgets('$type: beforeUpdate: a new color of the chart', (
        tester,
      ) async {
        await compare(
          type: type,
          hook: 'beforeUpdate',
          change: (chart, count) =>
              (chart.config.options as Map<String, Object?>)['color'] = _green,
          read: (chart) => jsGet(chart.legend!.legendItems![0], 'fontColor'),
        );
      });

      testWidgets('$type: a read in a hook keeps the options of the update', (
        tester,
      ) async {
        var armed = false;
        Object? before;
        Object? after;
        final chart = acquireChart(
          _config(
            type,
            plugins: [
              _hook('beforeUpdate', (chart) {
                if (armed) {
                  before = chart.legend!.options;
                  chart.legend!.legendItems;
                  after = chart.legend!.options;
                }
                return null;
              }),
            ],
          ),
        );
        armed = true;
        chart.update();
        expect(before, isNotNull);
        expect(after, same(before));
        expect(chart.legend!.options, same(before));
      });

      testWidgets('$type: a read inside a new generateLabels', (tester) async {
        final seen = <Object?>[];
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        for (final each in [chart, twin]) {
          _labelsOf(each)[0] = 'x';
          each.update();
          _labelOptionsOf(each)['generateLabels'] = (legendChart) {
            seen.add(_texts(each));
            return <Object?>[
              <String, Object?>{'text': 'u'},
            ];
          };
          each.update();
          expect(_texts(each), ['u']);
        }
        // Three builds on each chart: the snapshot of the last update, and
        // then the items of the build before.
        expect(seen, hasLength(6));
        expect(seen.sublist(0, 3), seen.sublist(3));
        expect(seen.first, ['x', 'b', 'c']);
      });

      testWidgets('$type: a style read before the first build', (tester) async {
        final chart = acquireChart(
          _config(
            type,
            plugins: [
              _hook('beforeLayout', (chart) {
                chart.getDatasetMeta(0).controller!.getStyle(0);
                return null;
              }),
            ],
          ),
        );
        // The box has items for a read that cannot run the build.
        expect(chart.legend!.legendItems, hasLength(3));
      });

      testWidgets('$type: a cancelled update with a new filter', (
        tester,
      ) async {
        var armed = false;
        Map<String, Object?> cancel() => _hook(
          'beforeUpdate',
          (chart) => armed ? false : null,
        );
        var calls = 0;
        final chart = acquireChart(_config(type, plugins: [cancel()]));
        final twin = acquireChart(_eager(type, plugins: [cancel()]));
        for (final each in [chart, twin]) {
          _labelsOf(each)[0] = 'x';
          each.update();
        }
        armed = true;
        for (final each in [chart, twin]) {
          _labelOptionsOf(each)['filter'] = (item, data) {
            calls++;
            return false;
          };
          each.update();
        }
        expect(_texts(chart), ['x', 'b', 'c']);
        expect(_items(chart.legend!), _items(twin.legend!));
        expect(calls, 0);
      });

      testWidgets('$type: a read leaves an in-place write of a later hook', (
        tester,
      ) async {
        var armed = false;
        Map<String, Object?> reader() => _hook('beforeUpdate', (chart) {
          if (armed) chart.legend!.legendItems;
          return null;
        });
        Map<String, Object?> writer() => _hook('beforeLayout', (chart) {
          if (armed) {
            _labelOptionsOf(chart)['pointStyle'] = 'star';
            (chart.config.options as Map<String, Object?>)['color'] = _green;
          }
          return null;
        });
        final chart = acquireChart(
          _config(type, plugins: [reader(), writer()]),
        );
        final twin = acquireChart(_eager(type, plugins: [reader(), writer()]));
        armed = true;
        for (final each in [chart, twin]) {
          each.update();
          expect(jsGet(each.legend!.legendItems![0], 'pointStyle'), 'star');
          expect(jsGet(each.legend!.legendItems![0], 'fontColor'), _green);
          expect(readOption(each.options, OptionKey.color), _green);
        }
        expect(_items(chart.legend!), _items(twin.legend!));
      });
    }
  });

  group('the guard reads only what the ordinary build reads', () {
    const written = <String, Object?>{
      'pointStyle': 'star',
      'textAlign': 'right',
      'color': _green,
      'useBorderRadius': true,
      'borderRadius': 7,
    };

    /// Writes [key] of the label options in `afterLayout`, and reads it in
    /// `afterUpdate` through the options of the box.
    Map<String, Object?> writeThenRead(
      String key,
      void Function(Object?) keep,
    ) => <String, Object?>{
      'id': 'writeThenRead',
      'afterLayout': (Chart chart, Object? args, Object? options) {
        _labelOptionsOf(chart)[key] = written[key];
        return null;
      },
      'afterUpdate': (Chart chart, Object? args, Object? options) {
        keep(
          readOption(
            readOption(chart.legend!.options, OptionKey.labels),
            optionKeyOf(key)!,
          ),
        );
        return null;
      },
    };

    for (final type in const ['pie', 'polarArea', 'bar', 'line']) {
      for (final display in const [true, false]) {
        for (final key in written.keys) {
          testWidgets('$type: display $display: a user generator: $key', (
            tester,
          ) async {
            Object? seen;
            acquireChart(
              _config(
                type,
                legend: {'display': display},
                labels: {
                  'generateLabels': (Object? chart) => <Object?>[
                    <String, Object?>{'text': 'x'},
                  ],
                },
                plugins: [writeThenRead(key, (value) => seen = value)],
              ),
            );
            expect(seen, written[key]);
          });
        }
      }
    }

    for (final display in const [true, false]) {
      for (final key in const [
        'textAlign',
        'useBorderRadius',
        'borderRadius',
      ]) {
        testWidgets('polarArea: display $display: a key of no read: $key', (
          tester,
        ) async {
          Object? seen;
          acquireChart(
            _config(
              'polarArea',
              legend: {'display': display},
              plugins: [writeThenRead(key, (value) => seen = value)],
            ),
          );
          expect(seen, written[key]);
        });
      }
    }

    testWidgets('a user generator leaves the chart color unread', (
      tester,
    ) async {
      Object? seen;
      acquireChart(
        _config(
          'pie',
          labels: {
            'generateLabels': (Object? chart) => <Object?>[
              <String, Object?>{'text': 'x'},
            ],
          },
          plugins: [
            <String, Object?>{
              'id': 'writeThenRead',
              'afterLayout': (Chart chart, Object? args, Object? options) {
                (chart.config.options as Map<String, Object?>)['color'] =
                    _green;
                return null;
              },
              'afterUpdate': (Chart chart, Object? args, Object? options) {
                seen = readOption(chart.options, OptionKey.color);
                return null;
              },
            },
          ],
        ),
      );
      expect(seen, _green);
    });

    testWidgets('a visible doughnut with a generator that delegates', (
      tester,
    ) async {
      final overrides = DoughnutController.overrides;
      final builtIn = readOption(
        readOption(
          readOption(overrides.jsRead('plugins'), OptionKey.legend),
          OptionKey.labels,
        ),
        OptionKey.generateLabels,
      );
      final chart = acquireChart(
        _config(
          'doughnut',
          legend: {'display': true},
          labels: {
            'generateLabels': (Object? chart) {
              _labelOptionsOf(chart! as Chart)['color'] = _green;
              return jsCall(builtIn, [chart]);
            },
          },
        ),
      );
      expect(jsGet(chart.legend!.legendItems![0], 'fontColor'), _green);
    });
  });

  group('no read and no guard calls an option', () {
    for (final (type, mode) in const [
      ('pie', 'default'),
      ('doughnut', 'default'),
      ('polarArea', 'default'),
      ('polarArea', 'none'),
    ]) {
      testWidgets('$type $mode: a scriptable color at a read', (tester) async {
        var armed = false;
        Map<String, Object?> reader() => _hook('afterDatasetsUpdate', (chart) {
          if (armed) chart.legend!.legendItems;
          return null;
        });
        var calls = 0;
        final chart = acquireChart(_config(type, plugins: [reader()]));
        final twin = acquireChart(_eager(type, plugins: [reader()]));
        armed = true;
        chart.update(mode);
        twin.update(mode);
        Object? script(Object? context, Object? options) {
          calls++;
          return _black;
        }

        (_datasetsOf(chart)[0]! as Map<String, Object?>)['backgroundColor'] =
            script;
        chart.update(mode);
        final seen = calls;
        calls = 0;
        (_datasetsOf(twin)[0]! as Map<String, Object?>)['backgroundColor'] =
            script;
        twin.update(mode);
        expect(seen, calls);
        expect(seen, greaterThan(0));
        expect(_items(chart.legend!), _items(twin.legend!));
      });
    }

    testWidgets('polarArea none: a cache clear and a scriptable color', (
      tester,
    ) async {
      var armed = false;
      var calls = 0;
      Object? script(Object? context, Object? options) {
        calls++;
        return _black;
      }

      Map<String, Object?> clear() => _hook('afterDatasetsUpdate', (chart) {
        if (armed) {
          chart.config.clearCache();
          (_datasetsOf(chart)[0]! as Map<String, Object?>)['backgroundColor'] =
              script;
          armed = false;
        }
        return null;
      });
      final chart = acquireChart(_config('polarArea', plugins: [clear()]));
      final twin = acquireChart(_eager('polarArea', plugins: [clear()]));
      chart.update('none');
      twin.update('none');
      armed = true;
      chart.update('none');
      final seen = calls;
      calls = 0;
      armed = true;
      twin.update('none');
      expect(seen, calls);
      expect(seen, 3);
      expect(_items(chart.legend!), _items(twin.legend!));
    });
  });

  group('a user descriptor function keeps its calls', () {
    for (final (id, parent, child) in [
      ('pieChild', 'pie', _pieChild),
      ('doughnutChild', 'doughnut', _doughnutChild),
      ('polarChild', 'polarArea', _polarChild),
    ]) {
      for (final where in const ['labels', 'dataset']) {
        for (final mode in const ['default', 'none']) {
          testWidgets('$parent: $where: $mode', (tester) async {
            // A subclass of the controller keeps the ordinary path.
            registry.addControllers([child]);
            addTearDown(() => registry.removeControllers([child]));
            var calls = 0;
            bool descriptor(Object? key) {
              calls++;
              return false;
            }

            Map<String, Object?> make(String type) => _config(
              type,
              labels: where == 'labels'
                  ? {'_scriptable': descriptor}
                  : const {},
              dataset: where == 'dataset'
                  ? {'_scriptable': descriptor}
                  : const {},
            );
            final chart = acquireChart(make(parent))
              ..update(mode)
              ..update(mode);
            final seen = calls;
            calls = 0;
            final twin = acquireChart(make(id))
              ..update(mode)
              ..update(mode);
            expect(seen, calls);
            expect(seen, greaterThan(0));
            expect(_items(chart.legend!), _items(twin.legend!));
          });
        }
      }
    }
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
      // The build still waits for a read that can run it.
      expect(legend.legendItemsPending, isTrue);
      expect(other.builds, 0);
      chart.legend = legend;
      expect(legend.legendItems, isNot(same(built)));
      expect(legend.legendItemsPending, isFalse);
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

    for (final type in _kinds) {
      testWidgets('$type: a read after a failed guard: older than upstream', (
        tester,
      ) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        // The last build: a, b and c.
        expect(_texts(chart), ['a', 'b', 'c']);
        for (final each in [chart, twin]) {
          _labelsOf(each)[0] = 'x';
          each.update();
          (each.data as Map<String, Object?>)['labels'] = null;
        }
        // Upstream, and the twin: the snapshot of the last update, each time.
        expect(_texts(twin), ['x', 'b', 'c']);
        expect(_texts(twin), ['x', 'b', 'c']);
        // No throw and no user code: the last built items, each time.
        expect(_texts(chart), ['a', 'b', 'c']);
        expect(_texts(chart), ['a', 'b', 'c']);
        expect(_legendOf(chart).legendItemsPending, isTrue);
        // A string for the labels is no native List either.
        (chart.data as Map<String, Object?>)['labels'] = 'mn';
        expect(_texts(chart), ['a', 'b', 'c']);
        // The build still waits: a read in a good state runs it.
        (chart.data as Map<String, Object?>)['labels'] = <Object?>[
          'y',
          'b',
          'c',
        ];
        expect(_texts(chart), ['y', 'b', 'c']);
        expect(_legendOf(chart).legendItemsPending, isFalse);
      });

      testWidgets('$type: a kept box and a failed guard at stop', (
        tester,
      ) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        final legend = _legendOf(chart);
        final twinLegend = _legendOf(twin);
        expect(legend.legendItems, hasLength(3));
        for (final each in [chart, twin]) {
          _labelsOf(each)[0] = 'x';
          each.update();
          (each.data as Map<String, Object?>)['labels'] = <Object?>[];
        }
        releaseChart(chart);
        releaseChart(twin);
        // Upstream, and the twin: the snapshot of the last update.
        expect(jsGet(twinLegend.legendItems![0], 'text'), 'x');
        // The last built items.
        expect(jsGet(legend.legendItems![0], 'text'), 'a');
        expect(legend.legendItemsPending, isFalse);
      });

      testWidgets(
        '$type: a read between the configure and the dataset update',
        (
          tester,
        ) async {
          var armed = false;
          final seen = <Object?>[];
          final twinSeen = <Object?>[];
          Map<String, Object?> reader(List<Object?> log) => _hook(
            'beforeDatasetUpdate',
            (chart) {
              if (armed) log.add(_texts(chart));
              return null;
            },
          );
          final chart = acquireChart(_config(type, plugins: [reader(seen)]));
          final twin = acquireChart(_eager(type, plugins: [reader(twinSeen)]));
          expect(_texts(chart), ['a', 'b', 'c']);
          armed = true;
          for (final each in [chart, twin]) {
            _labelsOf(each)[0] = 'x';
            each.update();
          }
          // Upstream, and the twin: the layout build of this update.
          expect(twinSeen, [
            ['x', 'b', 'c'],
          ]);
          // The element options of the last update are gone: the last built
          // items. No option runs at this read.
          expect(seen, [
            ['a', 'b', 'c'],
          ]);
          expect(_items(chart.legend!), _items(twin.legend!));
        },
      );

      testWidgets('$type: a read after the first dataset goes', (tester) async {
        Map<String, Object?> two() => _config(
          type,
          datasets: <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 2, 3],
              'backgroundColor': _blue,
            },
            <String, Object?>{
              'data': <Object?>[1, 2, 3],
              'backgroundColor': _green,
            },
          ],
        );
        for (final mode in const ['default', 'none']) {
          final chart = acquireChart(two())..update(mode);
          final expected = jsGet(chart.legend!.legendItems![0], 'fillStyle');
          expect(expected, _blue);
          chart.update(mode);
          expect(_legendOf(chart).legendItemsPending, isTrue);
          _datasetsOf(chart).removeAt(0);
          // The controller of the remaining dataset has another index: the
          // last built items, as the snapshot of upstream here. Never a default
          // color, and never a color of the dataset behind another index.
          expect(jsGet(chart.legend!.legendItems![0], 'fillStyle'), _blue);
          expect(_legendOf(chart).legendItemsPending, isTrue);
          chart.update(mode);
          expect(jsGet(chart.legend!.legendItems![0], 'fillStyle'), _green);
          releaseChart(chart);
        }
      });
    }

    testWidgets('polarArea none: a function added to the element defaults', (
      tester,
    ) async {
      // A hook adds a key after the dataset update. The proof of the mode none
      // does not see a new key, so its getStyle(0) calls the function once more
      // than the ordinary build, which the failed proof then runs.
      registry.addControllers([_polarChild]);
      addTearDown(() => registry.removeControllers([_polarChild]));
      var armed = false;
      var calls = 0;
      Object? function(Object? context, Object? options) {
        calls++;
        return 1;
      }

      final arc = jsGet(jsGet(defaults, 'elements'), 'arc');
      Map<String, Object?> add() => _hook('afterDatasetsUpdate', (chart) {
        if (armed) jsSet(arc, 'pinned', function);
        return null;
      });
      int callsOf(String type) {
        final chart = acquireChart(_config(type, plugins: [add()]))
          ..update('none');
        calls = 0;
        armed = true;
        chart.update('none');
        armed = false;
        jsDeleteKey(arc, 'pinned');
        final seen = calls;
        releaseChart(chart);
        return seen;
      }

      final ordinary = callsOf('polarChild');
      expect(ordinary, 3);
      expect(callsOf('polarArea'), ordinary + 1);
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

    for (final type in _kinds) {
      testWidgets(
        '$type: ChartView.raw: a new config and a beforeUpdate read',
        (
          tester,
        ) async {
          var reads = 0;
          final plugin = _hook('beforeUpdate', (chart) {
            chart.legend!.legendItems;
            reads++;
            return null;
          });
          Map<String, Object?> rawConfig(int count) => _config(
            type,
            labelValues: <Object?>[for (var i = 0; i < count; i++) 'l$i'],
            datasets: <Object?>[
              <String, Object?>{
                'data': <Object?>[for (var i = 0; i < count; i++) 1.0 + i],
                'backgroundColor': _red,
              },
            ],
            plugins: [plugin],
          );
          Widget frame(Map<String, Object?> config) => Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                height: 300,
                child: typed.ChartView.raw(config: config, updateMode: 'none'),
              ),
            ),
          );

          await tester.pumpWidget(frame(rawConfig(3)));
          final chart = chartOf(tester)..update('none');
          expect(_legendOf(chart).legendItemsPending, isTrue);
          await tester.pumpWidget(frame(rawConfig(4)));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(reads, greaterThanOrEqualTo(2));
          final meta = chartOf(tester).getDatasetMeta(0);
          expect(meta.controller, isNotNull);
          expect(meta.data, hasLength(4));
          expect(chartOf(tester).legend!.legendItems, hasLength(4));
        },
      );
    }

    for (final kind in const [
      typed.ChartKind.pie,
      typed.ChartKind.doughnut,
      typed.ChartKind.polarArea,
    ]) {
      testWidgets('$kind: a new dataset key and a beforeUpdate read', (
        tester,
      ) async {
        final plugin = _hook('beforeUpdate', (chart) {
          chart.legend!.legendItems;
          return null;
        });
        typed.ChartConfig keyed(String key, List<double> data) =>
            config(data, kind: kind).copyWith(
              plugins: [plugin],
              datasets: [
                switch (kind) {
                  typed.ChartKind.polarArea => typed.PolarAreaDataset(
                    key: ValueKey(key),
                    data: data,
                    borderWidth: 0,
                  ),
                  typed.ChartKind.doughnut => typed.DoughnutDataset(
                    key: ValueKey(key),
                    data: data,
                    borderWidth: 0,
                  ),
                  _ => typed.PieDataset(
                    key: ValueKey(key),
                    data: data,
                    borderWidth: 0,
                  ),
                },
              ],
            );

        await tester.pumpWidget(view(keyed('a', [1, 2, 3])));
        await tester.pumpWidget(view(keyed('a', [2, 3, 4])));
        expect(_legendOf(chartOf(tester)).legendItemsPending, isTrue);
        await tester.pumpWidget(view(keyed('b', [3, 4, 5])));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final meta = chartOf(tester).getDatasetMeta(0);
        expect(meta.controller, isNotNull);
        expect(meta.data, hasLength(3));
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
