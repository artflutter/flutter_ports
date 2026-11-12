// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/api.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

// The spec keeps the upstream statements: one call on the chart in each.
// ignore_for_file: cascade_invocations

import 'package:chartjs_test_utils/flutter.dart' show acquireChart;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show Chart;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsGet;
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

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
// - `chart.data.datasets[0].data[0].x = -100` writes the data object of the
//   config, which the chart reads (`_firstPoint`).

/// `chart.scales[id].min`.
double _min(Chart chart, String id) => chart.scales[id]!.min;

/// `chart.scales[id].max`.
double _max(Chart chart, String id) => chart.scales[id]!.max;

/// `chart.data.datasets[0].data[0]`: the data object of the config.
Map<String, Object?> _firstPoint(Chart chart) {
  final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
  final data = jsGet(datasets[0], 'data')! as List<Object?>;
  return data[0]! as Map<String, Object?>;
}

/// The options of a scatter chart with the scales `x` and `y` from 0 to 100,
/// and the zoom options [zoom], if any.
Map<String, Object?> _scatter0to100([Map<String, Object?>? zoom]) =>
    <String, Object?>{
      'type': 'scatter',
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{
            'min': 0,
            'max': 100,
          },
          'y': <String, Object?>{
            'min': 0,
            'max': 100,
          },
        },
        if (zoom != null)
          'plugins': <String, Object?>{
            'zoom': zoom,
          },
      },
    };

/// A scatter chart with the two points (0, 0) and (100, 100) and fitted
/// scales.
Map<String, Object?> _scatterFitted() => <String, Object?>{
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
};

void main() {
  group('api', () {
    testWidgets('should add methods to chart instance', (tester) async {
      final chart = acquireChart(<String, Object?>{'type': 'line'});

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
        final chart = acquireChart(_scatter0to100());
        expect(_min(chart, 'x'), toBe(0));
        expect(_max(chart, 'x'), toBe(100));
        expect(_min(chart, 'y'), toBe(0));
        expect(_max(chart, 'y'), toBe(100));

        chart.zoom(const .all(1.5));
        expect(_min(chart, 'x'), toBe(25));
        expect(_max(chart, 'x'), toBe(75));
        expect(_min(chart, 'y'), toBe(25));
        expect(_max(chart, 'y'), toBe(75));

        chart.zoom(const .all(0.5));
        expect(_min(chart, 'x'), toBe(12.5));
        expect(_max(chart, 'x'), toBe(87.5));
        expect(_min(chart, 'y'), toBe(12.5));
        expect(_max(chart, 'y'), toBe(87.5));

        chart.resetZoom();
        expect(_min(chart, 'x'), toBe(0));
        expect(_max(chart, 'x'), toBe(100));
        expect(_min(chart, 'y'), toBe(0));
        expect(_max(chart, 'y'), toBe(100));
      });

      testWidgets('should accept different percentages per axis', (
        tester,
      ) async {
        final chart = acquireChart(_scatter0to100());
        expect(_min(chart, 'x'), toBe(0));
        expect(_max(chart, 'x'), toBe(100));
        expect(_min(chart, 'y'), toBe(0));
        expect(_max(chart, 'y'), toBe(100));

        chart.zoom(const ZoomAmount(x: 1.5, y: 1.25));
        expect(_min(chart, 'x'), toBe(25));
        expect(_max(chart, 'x'), toBe(75));
        expect(_min(chart, 'y'), toBe(12.5));
        expect(_max(chart, 'y'), toBe(87.5));

        chart.zoom(const ZoomAmount(x: 0.75, y: 0.3));
        expect(_min(chart, 'x'), toBe(18.75));
        expect(_max(chart, 'x'), toBe(81.25));
        expect(_min(chart, 'y'), toBe(-13.75));
        expect(_max(chart, 'y'), toBe(113.75));

        chart.resetZoom();
        expect(_min(chart, 'x'), toBe(0));
        expect(_max(chart, 'x'), toBe(100));
        expect(_min(chart, 'y'), toBe(0));
        expect(_max(chart, 'y'), toBe(100));
      });

      testWidgets('should honor fitted scale updates on reset', (tester) async {
        final chart = acquireChart(_scatterFitted());

        chart.zoom(const .all(1.5));
        _firstPoint(chart)['x'] = -100;
        chart.update();
        chart.resetZoom();
        expect(_min(chart, 'x'), toBe(-100));
        expect(_max(chart, 'x'), toBe(100));
      });

      testWidgets('should no-op with fully constrained limits', (tester) async {
        final chart = acquireChart(
          _scatter0to100(<String, Object?>{
            'limits': <String, Object?>{
              'x': <String, Object?>{
                'min': 0,
                'max': 100,
                'minRange': 100,
              },
            },
          }),
        );

        chart.zoom(const .all(1.5));
        expect(_min(chart, 'x'), toBe(0));
        expect(_max(chart, 'x'), toBe(100));
      });

      testWidgets('should no-op whan laready at limit', (tester) async {
        final chart = acquireChart(
          _scatter0to100(<String, Object?>{
            'mode': Mode.x,
            'limits': <String, Object?>{
              'x': <String, Object?>{
                'min': 0,
                'max': 100,
                'minRange': 50,
              },
            },
          }),
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
        expect(_min(chart, 'x'), toBe(50));
        expect(_max(chart, 'x'), toBe(100));

        chart.zoom(atValue(100));
        expect(_min(chart, 'x'), toBe(50));
        expect(_max(chart, 'x'), toBe(100));

        chart.zoom(atValue(50));
        expect(_min(chart, 'x'), toBe(50));
        expect(_max(chart, 'x'), toBe(100));
      });

      testWidgets('should honor zoom changes against a limit', (tester) async {
        final chart = acquireChart(
          _scatter0to100(<String, Object?>{
            'limits': <String, Object?>{
              'x': <String, Object?>{
                'min': 0,
                'max': 100,
              },
            },
          }),
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
        expect(_min(chart, 'x'), toBe(0));
        expect(_max(chart, 'x'), toBe(1));

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
        expect(_min(chart, 'x'), toBe(0));
        expect(_max(chart, 'x'), toBe(100));
      });
    });

    group('zoomScale', () {
      testWidgets('should call onZoom', (tester) async {
        final zoomSpy = createSpy('start');
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 1, 'y': 1},
                  <String, Object?>{'x': 10, 'y': 10},
                ],
              },
            ],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'zoom': <String, Object?>{
                  'onZoom': zoomSpy.call,
                },
              },
            },
          },
        });

        chart.zoomScale('x', (min: 2, max: 10), 'default');

        expect(
          zoomSpy,
          toHaveBeenCalledWith([(chart: chart, trigger: ZoomTrigger.api)]),
        );
      });
    });

    group('getInitialScaleBounds', () {
      testWidgets(
        'should provide the correct initial scale bounds regardless of the '
        'zoom level',
        (tester) async {
          final chart = acquireChart(_scatter0to100());

          chart.zoom(const .all(1));
          expect(chart.getInitialScaleBounds()['x']!.min, toBe(0));
          expect(chart.getInitialScaleBounds()['x']!.max, toBe(100));
          expect(chart.getInitialScaleBounds()['y']!.min, toBe(0));
          expect(chart.getInitialScaleBounds()['y']!.max, toBe(100));

          chart.zoom(const ZoomAmount(x: 1.5, y: 1.25));
          expect(chart.getInitialScaleBounds()['x']!.min, toBe(0));
          expect(chart.getInitialScaleBounds()['x']!.max, toBe(100));
          expect(chart.getInitialScaleBounds()['y']!.min, toBe(0));
          expect(chart.getInitialScaleBounds()['y']!.max, toBe(100));
        },
      );

      testWidgets('should provide updated scale bounds upon data update', (
        tester,
      ) async {
        final chart = acquireChart(_scatterFitted());

        expect(chart.getInitialScaleBounds()['x']!.min, toBe(0));
        expect(chart.getInitialScaleBounds()['x']!.max, toBe(100));
        expect(chart.getInitialScaleBounds()['y']!.min, toBe(0));
        expect(chart.getInitialScaleBounds()['y']!.max, toBe(100));

        _firstPoint(chart)['x'] = -100;
        chart.update();

        expect(chart.getInitialScaleBounds()['x']!.min, toBe(-100));
        expect(chart.getInitialScaleBounds()['x']!.max, toBe(100));
        expect(chart.getInitialScaleBounds()['y']!.min, toBe(0));
        expect(chart.getInitialScaleBounds()['y']!.max, toBe(100));
      });
    });

    group('isZoomedOrPanned', () {
      testWidgets('should return whether or not the page is currently zoomed', (
        tester,
      ) async {
        final chart = acquireChart(_scatter0to100());

        expect(chart.isZoomedOrPanned(), toBe(false));

        chart.zoom(const .all(1));
        expect(chart.isZoomedOrPanned(), toBe(false));

        chart.zoom(const ZoomAmount(x: 1.5, y: 1.25));
        expect(chart.isZoomedOrPanned(), toBe(true));

        chart.zoom(const ZoomAmount(x: 0.25, y: 0.5));
        expect(chart.isZoomedOrPanned(), toBe(true));

        chart.resetZoom();
        expect(chart.isZoomedOrPanned(), toBe(false));
      });

      testWidgets('should return whether or not the page is currently panned', (
        tester,
      ) async {
        final chart = acquireChart(_scatter0to100());

        expect(chart.isZoomedOrPanned(), toBe(false));

        chart.pan(const PanAmount());
        expect(chart.isZoomedOrPanned(), toBe(false));

        chart.pan(const PanAmount(x: 10));
        expect(chart.isZoomedOrPanned(), toBe(true));

        chart.resetZoom();
        expect(chart.isZoomedOrPanned(), toBe(false));
      });

      testWidgets('should work with updated data and fitted scales', (
        tester,
      ) async {
        final chart = acquireChart(_scatterFitted());

        // This sequence of operations captures a previous bug.
        chart.zoom(const .all(1.5));
        _firstPoint(chart)['x'] = -100;
        chart.update();
        chart.resetZoom();
        expect(_min(chart, 'x'), toBe(-100));
        expect(_max(chart, 'x'), toBe(100));
        expect(chart.isZoomedOrPanned(), toBe(false));
      });
    });

    group('getZoomedScaleBounds', () {
      testWidgets('should return the zoom range, or undefined if not zoomed', (
        tester,
      ) async {
        final chart = acquireChart(_scatter0to100());
        expect(chart.getZoomedScaleBounds()['x'], isNull);

        chart.zoom(const .all(1.5));
        expect(
          chart.getZoomedScaleBounds()['x'],
          jasmineEquals((min: 25, max: 75)),
        );

        chart.resetZoom();
        expect(chart.getZoomedScaleBounds()['x'], isNull);
      });
    });

    group('with category scale', () {
      testWidgets('should zoom up to and out from single category', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'labels': <Object?>['a', 'b', 'c', 'd', 'e'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2, 3, 2, 1],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'min': 'b',
                'max': 'd',
              },
            },
          },
        });
        expect(_min(chart, 'x'), toBe(1));
        expect(_max(chart, 'x'), toBe(3));
        chart.zoom(const .all(1.1));
        expect(_min(chart, 'x'), toBe(2));
        expect(_max(chart, 'x'), toBe(2));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'x'), toBe(1));
        expect(_max(chart, 'x'), toBe(3));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'x'), toBe(0));
        expect(_max(chart, 'x'), toBe(4));
        chart.resetZoom();
        expect(_min(chart, 'x'), toBe(1));
        expect(_max(chart, 'x'), toBe(3));
      });

      testWidgets('should not exceed limits', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'labels': <Object?>['0', '1', '2', '3', '4', '5', '6'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2, 3, 2, 1, 0, 1],
              },
            ],
          },
          'options': <String, Object?>{
            'indexAxis': 'y',
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'min': 2,
                'max': 4,
              },
            },
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'limits': <String, Object?>{
                  'y': <String, Object?>{
                    'min': 1,
                    'max': 5,
                    'minRange': 1,
                  },
                },
                'zoom': <String, Object?>{
                  'wheel': <String, Object?>{
                    'enabled': true,
                  },
                  'mode': Mode.y,
                },
              },
            },
          },
        });
        expect(_min(chart, 'y'), toBe(2));
        expect(_max(chart, 'y'), toBe(4));
        chart.zoom(const .all(1.1));
        expect(_min(chart, 'y'), toBe(3));
        expect(_max(chart, 'y'), toBe(4));
        chart.pan(const .all(-100));
        expect(_min(chart, 'y'), toBe(4));
        expect(_max(chart, 'y'), toBe(5));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'y'), toBe(3));
        expect(_max(chart, 'y'), toBe(5));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'y'), toBe(1));
        expect(_max(chart, 'y'), toBe(5));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'y'), toBe(1));
        expect(_max(chart, 'y'), toBe(5));
        chart.pan(const .all(-100));
        expect(_min(chart, 'y'), toBe(1));
        expect(_max(chart, 'y'), toBe(5));
        chart.pan(const .all(100));
        expect(_min(chart, 'y'), toBe(1));
        expect(_max(chart, 'y'), toBe(5));
      });
    });

    group('with logarithmic scale', () {
      testWidgets('should zoom in and out', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'labels': <Object?>['a', 'b', 'c', 'd', 'e'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 22, 3333, 22, 1],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'logarithmic',
              },
            },
          },
        });
        expect(_min(chart, 'y'), toBe(0.1));
        expect(_max(chart, 'y'), toBe(4000));
        chart.zoom(const .all(1.1));
        expect(_min(chart, 'y'), toBeCloseTo(0.17));
        expect(_max(chart, 'y'), toBeCloseTo(2355, 0));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'y'), toBeCloseTo(0.105, 3));
        expect(_max(chart, 'y'), toBeCloseTo(3794, 0));
        chart.zoom(const .all(0.9));
        expect(_min(chart, 'y'), toBeCloseTo(0.06));
        expect(_max(chart, 'y'), toBeCloseTo(6410, 0));
        chart.resetZoom();
        expect(_min(chart, 'y'), toBe(0.1));
        expect(_max(chart, 'y'), toBe(4000));
      });
    });
  });
}
