// Original code, not ported from chartjs-plugin-zoom: the plugin on the host.
@TestOn('vm')
library;

import 'dart:async';

import 'package:chartjs_test_utils/flutter.dart' show acquireChart;
import 'package:flutter/widgets.dart'
    show Align, Alignment, Directionality, SizedBox, TextDirection, Widget;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show Element, undefined;
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
final class _Spy {
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
  final plugin = Plugin(supportsDataUpdates: true)
    ..id = r'$zoomDataOnlySpy'
    ..beforeUpdate = (chart, args, options) {
      spy.updates++;
      return null;
    }
    ..beforeLayout = (chart, args, options) {
      spy.layouts++;
      return null;
    };
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

void main() {
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
            'pan': <String, Object?>{'overScaleMode': 'y'},
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
