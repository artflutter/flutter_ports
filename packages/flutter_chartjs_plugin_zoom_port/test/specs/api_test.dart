// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/api.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

// The spec keeps the upstream statements: one call on the chart in each.
// ignore_for_file: cascade_invocations

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

// The Dart forms of the spec:
//
// - `chart.zoom(1.5)` is `chart.zoom(const .all(1.5))`, and the object form
//   `chart.zoom({ x: 1.5, y: 1.25 })` is `chart.zoom(const ZoomAmount(x: 1.5,
//   y: 1.25))`; `pan` takes a `PanAmount` the same way
//   (differences.md row `adapt-amount-classes`).
// - The methods of the chart are the extension `ZoomChart`
//   (`adapt-chart-methods-extension`): `typeof chart.pan === 'function'` is
//   the test of a tear-off.
// - `chart.scales.x` is `chart.scales['x']!`, and the `undefined` of a scale
//   with no zoom in `getZoomedScaleBounds()` is Dart `null`.
// - The upstream write to the first point's x becomes a replacement of
//   the immutable DataPoint through `_setFirstX`.
// - The zoom options are a `ZoomPluginOptions` in `options.plugins.zoom`
//   (Chart.js ADR 0148), and a limit is a `ScaleLimit`. The update mode
//   `'default'` is `UpdateMode.defaultMode`.

/// `chart.scales[id].min`.
double _min(Chart chart, String id) => chart.scales[id]!.min;

/// `chart.scales[id].max`.
double _max(Chart chart, String id) => chart.scales[id]!.max;

/// Replaces the first point with [x] and its previous y value.
void _setFirstX(Chart chart, double x) {
  final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
  final points = jsGet(datasets[0], 'data')! as List<DataPoint>;
  points[0] = DataPoint(x, points[0].y);
}

ChartConfig _scatter0to100([ZoomPluginOptions? zoom]) => ChartConfig(
  type: ChartKind.scatter,
  datasets: const [],
  scales: const {
    'x': LinearAxis(min: 0, max: 100),
    'y': LinearAxis(min: 0, max: 100),
  },
  pluginOptions: [?zoom],
);

ChartConfig _scatterFitted() => ChartConfig(
  type: ChartKind.scatter,
  datasets: [
    ScatterDataset(points: [DataPoint(0, 0), DataPoint(100, 100)]),
  ],
);

/// Acquires a chart through the typed config boundary.
Chart _acquire(ChartConfig config, [Map<String, Object?>? options]) =>
    acquireChartRoot(ChartConfigLowering(config).lower(), options);

void main() {
  group('api', () {
    testWidgets('should add methods to chart instance', (tester) async {
      final chart = _acquire(
        const ChartConfig(type: ChartKind.line, datasets: []),
      );

      expect(chart.pan, isA<Function>());
      expect(chart.zoom, isA<Function>());
      expect(chart.zoomScale, isA<Function>());
      expect(chart.zoomRect, isA<Function>());
      expect(chart.resetZoom, isA<Function>());
      expect(chart.getZoomLevel, isA<Function>());
      expect(chart.getInitialScaleBounds, isA<Function>());
      expect(chart.getZoomedScaleBounds, isA<Function>());
      expect(chart.isZoomedOrPanned, isA<Function>());
      expect(chart.isZoomingOrPanning, isA<Function>());
    });

    group('zoom and resetZoom', () {
      testWidgets('should accept zoom percentage as single parameter', (
        tester,
      ) async {
        final chart = _acquire(_scatter0to100());
        expect(_min(chart, 'x'), equals(0));
        expect(_max(chart, 'x'), equals(100));
        expect(_min(chart, 'y'), equals(0));
        expect(_max(chart, 'y'), equals(100));

        chart.zoom(const .all(1.5));
        expect(_min(chart, 'x'), equals(25));
        expect(_max(chart, 'x'), equals(75));
        expect(_min(chart, 'y'), equals(25));
        expect(_max(chart, 'y'), equals(75));

        chart.zoom(const .all(0.5));
        expect(_min(chart, 'x'), equals(12.5));
        expect(_max(chart, 'x'), equals(87.5));
        expect(_min(chart, 'y'), equals(12.5));
        expect(_max(chart, 'y'), equals(87.5));

        chart.resetZoom();
        expect(_min(chart, 'x'), equals(0));
        expect(_max(chart, 'x'), equals(100));
        expect(_min(chart, 'y'), equals(0));
        expect(_max(chart, 'y'), equals(100));
      });

      testWidgets('should accept different percentages per axis', (
        tester,
      ) async {
        final chart = _acquire(_scatter0to100());
        expect(_min(chart, 'x'), equals(0));
        expect(_max(chart, 'x'), equals(100));
        expect(_min(chart, 'y'), equals(0));
        expect(_max(chart, 'y'), equals(100));

        chart.zoom(const ZoomAmount(x: 1.5, y: 1.25));
        expect(_min(chart, 'x'), equals(25));
        expect(_max(chart, 'x'), equals(75));
        expect(_min(chart, 'y'), equals(12.5));
        expect(_max(chart, 'y'), equals(87.5));

        chart.zoom(const ZoomAmount(x: 0.75, y: 0.3));
        expect(_min(chart, 'x'), equals(18.75));
        expect(_max(chart, 'x'), equals(81.25));
        expect(_min(chart, 'y'), equals(-13.75));
        expect(_max(chart, 'y'), equals(113.75));

        chart.resetZoom();
        expect(_min(chart, 'x'), equals(0));
        expect(_max(chart, 'x'), equals(100));
        expect(_min(chart, 'y'), equals(0));
        expect(_max(chart, 'y'), equals(100));
      });

      testWidgets('should honor fitted scale updates on reset', (tester) async {
        final chart = _acquire(_scatterFitted());

        chart.zoom(const .all(1.5));
        _setFirstX(chart, -100);
        chart.update();
        chart.resetZoom();
        expect(_min(chart, 'x'), equals(-100));
        expect(_max(chart, 'x'), equals(100));
      });

      testWidgets('should no-op with fully constrained limits', (tester) async {
        final chart = _acquire(
          _scatter0to100(
            const ZoomPluginOptions(
              limits: {
                'x': ScaleLimits(
                  min: ScaleLimit(0),
                  max: ScaleLimit(100),
                  minRange: 100,
                ),
              },
            ),
          ),
        );

        chart.zoom(const .all(1.5));
        expect(_min(chart, 'x'), equals(0));
        expect(_max(chart, 'x'), equals(100));
      });

      testWidgets('should no-op whan laready at limit', (tester) async {
        final chart = _acquire(
          // The upstream options give `mode: 'x'` at the top level, where
          // `ZoomPluginOptions` has no `mode`: no code reads it.
          // DIVERGES(zoom): adapt-native-zoom-options, no extra key.
          _scatter0to100(
            const ZoomPluginOptions(
              limits: {
                'x': ScaleLimits(
                  min: ScaleLimit(0),
                  max: ScaleLimit(100),
                  minRange: 50,
                ),
              },
            ),
          ),
        );

        // The focal point `{ x }` has no `y`: its `undefined` is NaN in the
        // arithmetic and the compares of the zoom.
        // DIVERGES(zoom): adapt-amount-classes, NaN for the absent y.
        ZoomAmount atValue(double value) => ZoomAmount(
          x: 1.5,
          focalPoint: (
            x: chart.scales['x']!.getPixelForValue(value),
            y: double.nan,
          ),
        );

        chart.zoom(atValue(100));
        expect(_min(chart, 'x'), equals(50));
        expect(_max(chart, 'x'), equals(100));

        chart.zoom(atValue(100));
        expect(_min(chart, 'x'), equals(50));
        expect(_max(chart, 'x'), equals(100));

        chart.zoom(atValue(50));
        expect(_min(chart, 'x'), equals(50));
        expect(_max(chart, 'x'), equals(100));
      });

      testWidgets('should honor zoom changes against a limit', (tester) async {
        final chart = _acquire(
          _scatter0to100(
            const ZoomPluginOptions(
              limits: {
                'x': ScaleLimits(min: ScaleLimit(0), max: ScaleLimit(100)),
              },
            ),
          ),
        );
        chart.zoom(
          ZoomAmount(
            x: 1.99,
            focalPoint: (
              x: chart.scales['x']!.getPixelForValue(0),
              // DIVERGES(zoom): adapt-amount-classes, NaN for the absent y.
              y: double.nan,
            ),
          ),
        );
        expect(_min(chart, 'x'), equals(0));
        expect(_max(chart, 'x'), equals(1));

        chart.zoom(
          ZoomAmount(
            x: -98,
            focalPoint: (
              x: chart.scales['x']!.getPixelForValue(1),
              // DIVERGES(zoom): adapt-amount-classes, NaN for the absent y.
              y: double.nan,
            ),
          ),
        );
        expect(_min(chart, 'x'), equals(0));
        expect(_max(chart, 'x'), equals(100));
      });
    });

    group('zoomScale', () {
      testWidgets('should call onZoom', (tester) async {
        // `createSpy('start')`: a closure that records its context.
        final zoomCalls = <ZoomTriggerContext>[];
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.scatter,
            datasets: [
              ScatterDataset(points: [DataPoint(1, 1), DataPoint(10, 10)]),
            ],
            pluginOptions: [
              ZoomPluginOptions(zoom: ZoomOptions(onZoom: zoomCalls.add)),
            ],
          ),
        );

        chart.zoomScale('x', (min: 2, max: 10), UpdateMode.defaultMode);

        expect(zoomCalls, contains((chart: chart, trigger: ZoomTrigger.api)));
      });
    });

    group('getInitialScaleBounds', () {
      testWidgets(
        'should provide the correct initial scale bounds regardless of the '
        'zoom level',
        (tester) async {
          final chart = _acquire(_scatter0to100());

          chart.zoom(const .all(1));
          expect(chart.getInitialScaleBounds()['x']!.min, equals(0));
          expect(chart.getInitialScaleBounds()['x']!.max, equals(100));
          expect(chart.getInitialScaleBounds()['y']!.min, equals(0));
          expect(chart.getInitialScaleBounds()['y']!.max, equals(100));

          chart.zoom(const ZoomAmount(x: 1.5, y: 1.25));
          expect(chart.getInitialScaleBounds()['x']!.min, equals(0));
          expect(chart.getInitialScaleBounds()['x']!.max, equals(100));
          expect(chart.getInitialScaleBounds()['y']!.min, equals(0));
          expect(chart.getInitialScaleBounds()['y']!.max, equals(100));
        },
      );

      testWidgets('should provide updated scale bounds upon data update', (
        tester,
      ) async {
        final chart = _acquire(_scatterFitted());

        expect(chart.getInitialScaleBounds()['x']!.min, equals(0));
        expect(chart.getInitialScaleBounds()['x']!.max, equals(100));
        expect(chart.getInitialScaleBounds()['y']!.min, equals(0));
        expect(chart.getInitialScaleBounds()['y']!.max, equals(100));

        _setFirstX(chart, -100);
        chart.update();

        expect(chart.getInitialScaleBounds()['x']!.min, equals(-100));
        expect(chart.getInitialScaleBounds()['x']!.max, equals(100));
        expect(chart.getInitialScaleBounds()['y']!.min, equals(0));
        expect(chart.getInitialScaleBounds()['y']!.max, equals(100));
      });
    });

    group('isZoomedOrPanned', () {
      testWidgets('should return whether or not the page is currently zoomed', (
        tester,
      ) async {
        final chart = _acquire(_scatter0to100());

        expect(chart.isZoomedOrPanned(), equals(false));

        chart.zoom(const .all(1));
        expect(chart.isZoomedOrPanned(), equals(false));

        chart.zoom(const ZoomAmount(x: 1.5, y: 1.25));
        expect(chart.isZoomedOrPanned(), equals(true));

        chart.zoom(const ZoomAmount(x: 0.25, y: 0.5));
        expect(chart.isZoomedOrPanned(), equals(true));

        chart.resetZoom();
        expect(chart.isZoomedOrPanned(), equals(false));
      });

      testWidgets('should return whether or not the page is currently panned', (
        tester,
      ) async {
        final chart = _acquire(_scatter0to100());

        expect(chart.isZoomedOrPanned(), equals(false));

        chart.pan(const PanAmount());
        expect(chart.isZoomedOrPanned(), equals(false));

        chart.pan(const PanAmount(x: 10));
        expect(chart.isZoomedOrPanned(), equals(true));

        chart.resetZoom();
        expect(chart.isZoomedOrPanned(), equals(false));
      });

      testWidgets('should work with updated data and fitted scales', (
        tester,
      ) async {
        final chart = _acquire(_scatterFitted());

        // This sequence of operations captures a previous bug.
        chart.zoom(const .all(1.5));
        _setFirstX(chart, -100);
        chart.update();
        chart.resetZoom();
        expect(_min(chart, 'x'), equals(-100));
        expect(_max(chart, 'x'), equals(100));
        expect(chart.isZoomedOrPanned(), equals(false));
      });
    });

    group('getZoomedScaleBounds', () {
      testWidgets('should return the zoom range, or undefined if not zoomed', (
        tester,
      ) async {
        final chart = _acquire(_scatter0to100());
        expect(chart.getZoomedScaleBounds()['x'], isNull);

        chart.zoom(const .all(1.5));
        expect(
          chart.getZoomedScaleBounds()['x'],
          equals((min: 25.0, max: 75.0)),
        );

        chart.resetZoom();
        expect(chart.getZoomedScaleBounds()['x'], isNull);
      });
    });

    group('with category scale', () {
      testWidgets('should zoom up to and out from single category', (
        tester,
      ) async {
        final chart = _acquire(
          const ChartConfig(
            type: ChartKind.bar,
            labels: ['a', 'b', 'c', 'd', 'e'],
            datasets: [
              BarDataset(data: [1, 2, 3, 2, 1]),
            ],
            scales: {'x': CategoryAxis(min: 'b', max: 'd')},
          ),
        );
        expect(_min(chart, 'x'), equals(1));
        expect(_max(chart, 'x'), equals(3));
        chart.zoom(const .all(1.1));
        expect(_min(chart, 'x'), equals(2));
        expect(_max(chart, 'x'), equals(2));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'x'), equals(1));
        expect(_max(chart, 'x'), equals(3));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'x'), equals(0));
        expect(_max(chart, 'x'), equals(4));
        chart.resetZoom();
        expect(_min(chart, 'x'), equals(1));
        expect(_max(chart, 'x'), equals(3));
      });

      testWidgets('should not exceed limits', (tester) async {
        final chart = _acquire(
          const ChartConfig(
            type: ChartKind.bar,
            labels: ['0', '1', '2', '3', '4', '5', '6'],
            datasets: [
              BarDataset(data: [1, 2, 3, 2, 1, 0, 1]),
            ],
            indexAxis: YAxis(),
            scales: {
              'y': CategoryAxis(extra: {'min': 2, 'max': 4}),
            },
            pluginOptions: [
              ZoomPluginOptions(
                limits: {
                  'y': ScaleLimits(
                    min: ScaleLimit(1),
                    max: ScaleLimit(5),
                    minRange: 1,
                  ),
                },
                zoom: ZoomOptions(
                  wheel: WheelOptions(enabled: true),
                  mode: Mode.y,
                ),
              ),
            ],
          ),
        );
        expect(_min(chart, 'y'), equals(2));
        expect(_max(chart, 'y'), equals(4));
        chart.zoom(const .all(1.1));
        expect(_min(chart, 'y'), equals(3));
        expect(_max(chart, 'y'), equals(4));
        chart.pan(const .all(-100));
        expect(_min(chart, 'y'), equals(4));
        expect(_max(chart, 'y'), equals(5));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'y'), equals(3));
        expect(_max(chart, 'y'), equals(5));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'y'), equals(1));
        expect(_max(chart, 'y'), equals(5));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'y'), equals(1));
        expect(_max(chart, 'y'), equals(5));
        chart.pan(const .all(-100));
        expect(_min(chart, 'y'), equals(1));
        expect(_max(chart, 'y'), equals(5));
        chart.pan(const .all(100));
        expect(_min(chart, 'y'), equals(1));
        expect(_max(chart, 'y'), equals(5));
      });
    });

    group('with logarithmic scale', () {
      testWidgets('should zoom in and out', (tester) async {
        final chart = _acquire(
          const ChartConfig(
            type: ChartKind.bar,
            labels: ['a', 'b', 'c', 'd', 'e'],
            datasets: [
              BarDataset(data: [1, 22, 3333, 22, 1]),
            ],
            scales: {'y': LogarithmicAxis()},
          ),
        );
        expect(_min(chart, 'y'), equals(0.1));
        expect(_max(chart, 'y'), equals(4000));
        chart.zoom(const .all(1.1));
        expect(_min(chart, 'y'), closeTo(0.17, 0.005));
        expect(_max(chart, 'y'), closeTo(2355, 0.5));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'y'), closeTo(0.105, 0.0005));
        expect(_max(chart, 'y'), closeTo(3794, 0.5));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'y'), closeTo(0.06, 0.005));
        expect(_max(chart, 'y'), closeTo(6410, 0.5));
        chart.resetZoom();
        expect(_min(chart, 'y'), equals(0.1));
        expect(_max(chart, 'y'), equals(4000));
      });
    });
  });
}
