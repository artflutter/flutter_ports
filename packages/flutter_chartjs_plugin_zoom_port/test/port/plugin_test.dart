// Original code, not ported from chartjs-plugin-zoom: the plugin on the host.
@TestOn('vm')
library;

import 'dart:async';

import 'package:chartjs_test_utils/flutter.dart' show acquireChart;
import 'package:flutter/widgets.dart'
    show Align, Alignment, Directionality, SizedBox, TextDirection, Widget;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/state.dart' show getState;
import 'package:flutter_chartjs_port/chartjs.dart'
    show Element, JsObjectFace, undefined;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart';
import '../support/jasmine.dart';

// The tests of the plugin object on the host that no upstream spec has:
//
// - Seam H25 (design D8): the plugin opts into the data-only updates of the
//   host (`Plugin(supportsDataUpdates: true)`, Chart.js ADR 0074). A
//   `ChartView` with `dataOnlyUpdates` then calls `chart.updateData()` for
//   new data, which keeps the layout, the ticks and the scale ranges of the
//   last full update and runs the `beforeUpdate` hook of the plugin. The
//   zoom range, the zoom state and the listeners must stay as a full update
//   leaves them.
// - Seam H17: `start` warns about the removed option `zoom.enabled` when the
//   zoom options own it. The plugin options are a resolver of the host, and
//   `hasOwnProperty` is its face `jsHas`.
// - Seam H14: the zoom writes its range into the `min` and `max` options of
//   the scale, and the next update keeps it.
//
// flutter_test_config.dart registers the built-in components and the
// plugin for each chart (harness-register-builtins).

/// The updates and the layouts of the charts since the last [clear].
final class _Spy() {
  int updates = 0;
  int layouts = 0;

  void clear() {
    updates = 0;
    layouts = 0;
  }
}

/// A registered spy plugin that opts into the data-only updates. A full
/// update runs `beforeLayout`; the data-only lifecycle does not while the
/// layout stays valid. It unregisters at the end of the test.
_Spy _spyOnCharts() {
  final spy = _Spy();
  final plugin = Plugin<Object?>(
    id: r'$zoomDataOnlySpy',
    supportsDataUpdates: true,
    beforeUpdate: (chart, args, options) {
      spy.updates++;
      return true;
    },
    beforeLayout: (chart, args, options) {
      spy.layouts++;
      return true;
    },
  );
  Chart.register([plugin]);
  addTearDown(() => Chart.unregister([plugin]));
  return spy;
}

/// The points of the scatter chart at [step]: new values in a new List.
List<DataPoint> _points(int step) => <DataPoint>[
  for (var i = 0; i < 6; i++)
    DataPoint(10 + i * 16, (10 + (i * 7 + step * 13) % 80).toDouble()),
];

/// A scatter chart on the linear scales `x` and `y` from 0 to 100, with the
/// zoom options [zoomOptions], in a box of 400 x 300.
Widget _view(
  int step,
  Map<String, Object?> zoomOptions, {
  required bool dataOnly,
  required void Function(Chart chart) onChartCreated,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 400,
      height: 300,
      child: ChartView(
        config: ChartConfig(
          type: .scatter,
          datasets: [ScatterDataset(points: _points(step), pointRadius: 3)],
          scales: const {
            'x': LinearAxis(min: 0, max: 100),
            'y': LinearAxis(min: 0, max: 100),
          },
          animation: ChartAnimation.none,
          extra: zoomOptions,
        ),
        updateMode: 'none',
        dataOnlyUpdates: dataOnly,
        onChartCreated: onChartCreated,
      ),
    ),
  ),
);

/// What the zoom and the chart show: the ranges of the scales, the zoom
/// state and the position of each point.
Object _observe(Chart chart) => [
  for (final id in const ['x', 'y']) ...[
    chart.scales[id]!.min,
    chart.scales[id]!.max,
    chart.getZoomedScaleBounds()[id],
    chart.getInitialScaleBounds()[id],
  ],
  chart.getZoomLevel(),
  chart.isZoomedOrPanned(),
  chart.isZoomingOrPanning(),
  for (final element in chart.getDatasetMeta(0).data)
    ((element as Element).x, element.y),
];

/// The resolver of the chart options of [chart]: `update` makes a new one,
/// `updateRanges` keeps it (Chart.js ADR 0111).
Object? _resolver(Chart chart) => chart.options.jsRead('_proxy');

/// A line chart of 24 points on the linear scales `x` and `y` with the zoom
/// options [zoom], and the port-only option `rangeOnlyUpdates` of
/// [rangeOnly]. The title text is scriptable: it reads the zoom level and
/// adds each text to [titles].
Map<String, Object?> _rangeConfig(
  Map<String, Object?> zoom, {
  required bool rangeOnly,
  required List<String> titles,
}) => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'a',
        'data': <Object?>[
          for (var i = 0; i < 24; i++)
            <String, Object?>{'x': i * 4.0, 'y': 10.0 + (i * 37) % 80},
        ],
        'pointRadius': 3.0,
      },
    ],
  },
  'options': <String, Object?>{
    'animation': false,
    'scales': <String, Object?>{
      'x': <String, Object?>{'type': 'linear', 'min': 0.0, 'max': 100.0},
      'y': <String, Object?>{'type': 'linear'},
    },
    'plugins': <String, Object?>{
      'title': <String, Object?>{
        'display': true,
        'text': (Object? ctx) {
          final chart = (ctx! as JsObjectFace).jsRead('chart')! as Chart;
          final level = 'Zoom level ${chart.getZoomLevel()}';
          titles.add(level);
          return level;
        },
      },
      'zoom': <String, Object?>{
        ...zoom,
        // An explicit false: the run with the option in the defaults keeps
        // the full path for this chart.
        'rangeOnlyUpdates': rangeOnly,
      },
    },
  },
};

/// What a zoom step leaves: the ranges and the ticks of the scales, the zoom
/// state, the chart area and the position of each point.
Object _rangeObserve(Chart chart) => [
  for (final id in const ['x', 'y']) ...[
    chart.scales[id]!.min,
    chart.scales[id]!.max,
    [
      for (final t in chart.scales[id]!.ticks!) [t.value, t.label],
    ],
    chart.getZoomedScaleBounds()[id],
    chart.getInitialScaleBounds()[id],
  ],
  chart.getZoomLevel(),
  chart.isZoomedOrPanned(),
  chart.isZoomingOrPanning(),
  [
    chart.chartArea!.left,
    chart.chartArea!.top,
    chart.chartArea!.right,
    chart.chartArea!.bottom,
  ],
  for (final element in chart.getDatasetMeta(0).data)
    ((element as Element).x, element.y),
];

void main() {
  group('range-only updates (Chart.js ADR 0111)', () {
    /// The zoom options of the flows: each input on.
    Map<String, Object?> zoomOptions({
      Object? mode = Mode.xy,
      Object? onZoomComplete,
    }) => <String, Object?>{
      'zoom': <String, Object?>{
        'wheel': <String, Object?>{'enabled': true},
        'drag': <String, Object?>{'enabled': true},
        'pinch': <String, Object?>{'enabled': true},
        'mode': mode,
        'onZoomComplete': ?onZoomComplete,
      },
      'pan': <String, Object?>{
        'enabled': true,
        'mode': Mode.xy,
        'threshold': 0.0,
      },
    };

    /// The flows of the ADR: each runs on one chart.
    final flows = <String, void Function(Chart chart)>{
      'wheel': (chart) {
        final area = chart.chartArea!;
        triggerWheelEvent(
          chart,
          x: area.left + area.width * 0.3,
          y: area.top + area.height * 0.6,
          deltaY: -100,
        );
      },
      'drag box': (chart) {
        final area = chart.chartArea!;
        dispatchEvent(chart, 'mousedown', (
          x: (area.left + 40).roundToDouble(),
          y: (area.top + 30).roundToDouble(),
        ));
        dispatchEvent(chart, 'mousemove', (
          x: (area.left + 160).roundToDouble(),
          y: (area.top + 150).roundToDouble(),
        ));
        dispatchEvent(chart, 'mouseup', (
          x: (area.left + 160).roundToDouble(),
          y: (area.top + 150).roundToDouble(),
        ));
      },
      'pinch': (chart) => simulatePinch(chart, scale: 1.5),
      'mouse pan': (chart) => simulatePan(
        chart,
        deltaX: 60,
        deltaY: -20,
        init: const EventInit(pointerType: 'mouse'),
      ),
      'zoom': (chart) => chart.zoom(const .all(1.2)),
      'zoomRect': (chart) =>
          chart.zoomRect((x: 120.0, y: 90.0), (x: 300.0, y: 260.0)),
      'zoomScale': (chart) => chart.zoomScale('x', (min: 10, max: 60)),
      'pan': (chart) => chart.pan(const PanAmount(x: -30, y: 15)),
      'resetZoom': (chart) => chart.resetZoom(),
    };

    testWidgets('each flow takes updateRanges and ends as without the '
        'option', (tester) async {
      final fullTitles = <String>[];
      final rangeTitles = <String>[];
      final full = acquireChart(
        _rangeConfig(zoomOptions(), rangeOnly: false, titles: fullTitles),
      );
      final ranges = acquireChart(
        _rangeConfig(zoomOptions(), rangeOnly: true, titles: rangeTitles),
      );
      final levels = <String>{};
      for (final MapEntry(key: name, value: flow) in flows.entries) {
        final fullResolver = _resolver(full);
        final rangeResolver = _resolver(ranges);
        fullTitles.clear();
        rangeTitles.clear();
        flow(full);
        flow(ranges);
        expect(
          _resolver(ranges),
          same(rangeResolver),
          reason: '$name: the range path',
        );
        expect(
          _resolver(full),
          isNot(same(fullResolver)),
          reason: '$name: the full path',
        );
        expect(_rangeObserve(ranges), _rangeObserve(full), reason: name);
        expect(rangeTitles, fullTitles, reason: '$name: the title');
        expect(rangeTitles, isNotEmpty, reason: '$name: the title runs');
        levels.addAll(rangeTitles);
        final pixels = await tester.runAsync(
          () => Future.wait([full.toBase64Image(), ranges.toBase64Image()]),
        );
        expect(pixels![1], pixels[0], reason: '$name: the pixels');
      }
      // The scriptable title shows the level of the steps.
      expect(levels.length, greaterThan(3));
      // The debounced onZoomComplete of the wheel.
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('onZoomComplete and a mode function keep the range path', (
      tester,
    ) async {
      final completed = <Chart>[];
      final modes = <Chart>[];
      final options = zoomOptions(
        mode: (ZoomChartContext context) {
          modes.add(context.chart);
          return Mode.x;
        },
        onZoomComplete: (ZoomChartContext context) =>
            completed.add(context.chart),
      );
      final chart = acquireChart(
        _rangeConfig(options, rangeOnly: true, titles: <String>[]),
      );
      final resolver = _resolver(chart);
      final area = chart.chartArea!;
      chart.zoom(const .all(1.5));
      triggerWheelEvent(
        chart,
        x: area.left + area.width / 2,
        y: area.top + area.height / 2,
        deltaY: -100,
      );
      chart.resetZoom();
      expect(_resolver(chart), same(resolver));
      expect(modes, isNotEmpty);
      expect(completed, [chart]);
      await tester.pump(const Duration(milliseconds: 300));
      expect(completed, [chart, chart]);
      expect(_resolver(chart), same(resolver));
    });

    testWidgets('the option in the defaults reaches the plugin options', (
      tester,
    ) async {
      // The suite with --dart-define=ZOOM_RANGE_ONLY_UPDATES=true writes it
      // into Chart.defaults.plugins.zoom (flutter_test_config.dart).
      final chart = acquireChart(<String, Object?>{'type': 'line'});
      expect(getState(chart).options.rangeOnlyUpdates, zoomRangeOnlyUpdates);
    });

    testWidgets('with the option off, a zoom takes update', (tester) async {
      expect(
        const ZoomPluginOptions(<String, Object?>{}).rangeOnlyUpdates,
        isFalse,
      );
      final chart = acquireChart(
        _rangeConfig(zoomOptions(), rangeOnly: false, titles: <String>[]),
      );
      final resolver = _resolver(chart);
      chart.zoom(const .all(1.5));
      expect(_resolver(chart), isNot(same(resolver)));
    });

    testWidgets('a ChartView with dataOnlyUpdates takes updateData for the '
        'data tick after a zoom step', (tester) async {
      final spy = _spyOnCharts();
      final zoom = <String, Object?>{
        'plugins': <String, Object?>{
          'zoom': <String, Object?>{
            'zoom': <String, Object?>{
              'wheel': <String, Object?>{'enabled': true},
            },
            'rangeOnlyUpdates': true,
          },
        },
      };
      Chart? created;
      Widget view(int step) => _view(
        step,
        zoom,
        dataOnly: true,
        onChartCreated: (chart) => created = chart,
      );
      await tester.pumpWidget(view(0));
      await tester.pump();
      await tester.pumpWidget(view(1));
      final chart = created!;
      final resolver = _resolver(chart);
      spy.clear();
      chart.zoom(const .all(1.5));
      // The range update: its hooks and its layout run.
      expect(spy.updates, 1);
      expect(spy.layouts, 1);
      expect(_resolver(chart), same(resolver));
      spy.clear();
      await tester.pumpWidget(view(2));
      expect(spy.updates, 1);
      expect(spy.layouts, 0);
      expect(chart.scales['x']!.min, toBe(25));
      expect(chart.scales['x']!.max, toBe(75));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('data-only updates (seam H25)', () {
    test('the plugin opts in', () {
      expect(zoomPlugin.supportsDataUpdates, isTrue);
    });

    testWidgets('a zoom, a pan, a wheel zoom and a reset stay through new '
        'data, as with a full update', (tester) async {
      final spy = _spyOnCharts();
      // The options are one Map for the life of the view, as an app keeps
      // them: a Map with other values is a full update.
      final zoomOptions = <String, Object?>{
        'plugins': <String, Object?>{
          'zoom': <String, Object?>{
            'pan': <String, Object?>{'enabled': true},
            'zoom': <String, Object?>{
              'wheel': <String, Object?>{'enabled': true},
            },
          },
        },
      };

      Future<List<Object>> run({required bool dataOnly}) async {
        Chart? created;
        Widget view(int step) => _view(
          step,
          zoomOptions,
          dataOnly: dataOnly,
          onChartCreated: (chart) => created = chart,
        );
        final seen = <Object>[];
        var step = 0;

        // The start and the first new config are full updates.
        await tester.pumpWidget(view(step++));
        await tester.pump();
        await tester.pumpWidget(view(step++));
        final chart = created!;

        /// A new config with new data: `updateData` with the parameter.
        Future<void> tick() async {
          spy.clear();
          await tester.pumpWidget(view(step));
          expect(spy.updates, 1, reason: 'step $step');
          expect(spy.layouts, dataOnly ? 0 : 1, reason: 'step $step');
          seen.add(_observe(chart));
          step++;
        }

        await tick();

        chart.zoom(const .all(1.5));
        expect(chart.scales['x']!.min, toBe(25));
        expect(chart.scales['x']!.max, toBe(75));
        seen.add(_observe(chart));
        await tick();
        expect(chart.scales['x']!.min, toBe(25));
        expect(chart.scales['x']!.max, toBe(75));
        expect(chart.getZoomedScaleBounds()['x'], (min: 25.0, max: 75.0));
        expect(chart.isZoomedOrPanned(), isTrue);

        chart.pan(const PanAmount(x: 40));
        seen.add(_observe(chart));
        await tick();

        // The wheel listener of the canvas stays, with the options of the
        // last `beforeUpdate`.
        final area = chart.chartArea!;
        final before = chart.scales['x']!.max - chart.scales['x']!.min;
        triggerWheelEvent(
          chart,
          x: (area.left + area.right) / 2,
          y: (area.top + area.bottom) / 2,
          deltaY: -100,
        );
        expect(
          chart.scales['x']!.max - chart.scales['x']!.min,
          lessThan(before),
        );
        seen.add(_observe(chart));
        await tick();

        chart.resetZoom();
        expect(chart.scales['x']!.min, toBe(0));
        expect(chart.scales['x']!.max, toBe(100));
        seen.add(_observe(chart));
        await tick();
        expect(chart.isZoomedOrPanned(), isFalse);
        expect(chart.getZoomLevel(), 1);

        await tester.pumpWidget(const SizedBox());
        return seen;
      }

      expect(await run(dataOnly: true), await run(dataOnly: false));
    });

    testWidgets('a function in the zoom options keeps the full update', (
      tester,
    ) async {
      // The data-only path of the host takes static user options only: a
      // function of the options other than `onClick` and `onHover` makes each
      // new config a full update (Chart.js ADR 0074). The range stays.
      final spy = _spyOnCharts();
      final completed = <Chart>[];
      final zoomOptions = <String, Object?>{
        'plugins': <String, Object?>{
          'zoom': <String, Object?>{
            'zoom': <String, Object?>{
              'wheel': <String, Object?>{'enabled': true},
              'onZoomComplete': (ZoomChartContext context) =>
                  completed.add(context.chart),
            },
          },
        },
      };
      Chart? created;
      Widget view(int step) => _view(
        step,
        zoomOptions,
        dataOnly: true,
        onChartCreated: (chart) => created = chart,
      );
      await tester.pumpWidget(view(0));
      await tester.pump();
      await tester.pumpWidget(view(1));
      final chart = created!..zoom(const .all(1.5));

      spy.clear();
      await tester.pumpWidget(view(2));
      expect(spy.updates, 1);
      expect(spy.layouts, 1);
      expect(chart.scales['x']!.min, toBe(25));
      expect(chart.scales['x']!.max, toBe(75));

      chart.resetZoom();
      expect(completed, [chart]);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the warnings of start (seams H12, H17)', () {
    /// The lines that [body] prints.
    List<String> printed(void Function() body) {
      final lines = <String>[];
      runZoned(
        body,
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => lines.add(line),
        ),
      );
      return lines;
    }

    /// A line chart with the zoom options [zoom].
    Map<String, Object?> config(Map<String, Object?> zoom) => <String, Object?>{
      'type': 'line',
      'options': <String, Object?>{
        'plugins': <String, Object?>{'zoom': zoom},
      },
    };

    testWidgets('an own zoom.enabled prints the warning once', (tester) async {
      final lines = printed(
        () => acquireChart(
          config(<String, Object?>{
            'zoom': <String, Object?>{'enabled': true},
          }),
        ),
      );
      const warning =
          'The option `zoom.enabled` is no longer supported. Please use '
          '`zoom.wheel.enabled`, `zoom.drag.enabled`, or '
          '`zoom.pinch.enabled`.';
      expect(lines, [warning]);
    });

    testWidgets('an own zoom.enabled of undefined prints the warning', (
      tester,
    ) async {
      // `hasOwnProperty` tests the key, not its value.
      final lines = printed(
        () => acquireChart(
          config(<String, Object?>{
            'zoom': <String, Object?>{'enabled': undefined},
          }),
        ),
      );
      expect(lines, hasLength(1));
      expect(lines.single, startsWith('The option `zoom.enabled`'));
    });

    testWidgets('the default options print nothing', (tester) async {
      final lines = printed(
        () => acquireChart(
          config(<String, Object?>{
            'zoom': <String, Object?>{
              'wheel': <String, Object?>{'enabled': true},
            },
          }),
        ),
      );
      expect(lines, isEmpty);
    });

    testWidgets('an own overScaleMode prints the deprecation', (tester) async {
      final lines = printed(
        () => acquireChart(
          config(<String, Object?>{
            'pan': <String, Object?>{'overScaleMode': Mode.y},
          }),
        ),
      );
      const warning =
          'The option `overScaleMode` is deprecated. Please use `scaleMode` '
          'instead (and update `mode` as desired).';
      expect(lines, [warning]);
    });
  });

  group('the range in the scale options (seam H14)', () {
    testWidgets('a zoom writes min and max, an update keeps them, and a reset '
        'writes back the original options', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'scatter',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': 0, 'y': 0},
                <String, Object?>{'x': 100, 'y': 100},
              ],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'min': 0, 'max': 100},
          },
        },
      });
      final x = chart.scales['x']!;
      final y = chart.scales['y']!;
      expect(y.options.min, same(undefined));

      chart.zoom(const .all(1.5));
      expect(x.options.min, toBe(25));
      expect(x.options.max, toBe(75));
      expect(y.options.min, toBe(y.min));
      expect(y.options.max, toBe(y.max));

      chart.update();
      expect(x.min, toBe(25));
      expect(x.max, toBe(75));
      expect(x.options.min, toBe(25));

      chart.resetZoom();
      expect(x.options.min, toBe(0));
      expect(x.options.max, toBe(100));
      expect(x.min, toBe(0));
      expect(x.max, toBe(100));
      expect(y.options.min, same(undefined));
      expect(y.options.max, same(undefined));
    });
  });
}
