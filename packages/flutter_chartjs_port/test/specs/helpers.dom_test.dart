// Ported from Chart.js v4.5.1+7169e651 test/specs/helpers.dom.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.dom.dart' as helpers;
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

// The spec reads the functions from Chart.helpers. Here `helpers` is
// helpers.dom.dart, which lib/src/helpers/index.dart exports.
//
// Flutter has no DOM and no CSS (Chart.js ADR 0014). The parent node of a
// canvas is the box that a chart host lays the canvas out in: a
// [CanvasContainer] with the content-box size of the host constraints. The
// cases that build a fixed-size div and measure an element inside it use a
// test container of the same size. The cases that test only CSS (max-width,
// max-height, percentages, padding) or the shadow DOM skip as n/a.
//
// The cases that call `acquireChart` are `testWidgets` cases (Chart.js ADR
// 0022, sections 1 and 2). Thus the file runs on the VM only, although
// helpers.dom.dart is a pure-layer root. `Math.round` is `jsRound`.
//
// The two `getRelativePosition` cases with a bar chart: the `onHover`
// option is a Dart function of the chart event. `getRelativePosition`
// returns a [Point], not the object of the event: `toEqual({x, y})` of
// the result compares the record `{x, y}` of the point (`_point`).
// `not.toEqual(NaN)` is `isNot(jasmineEquals(double.nan))`: Jasmine `eq`
// makes NaN equal to NaN.

/// A test container: the parent node of a canvas, with the content box
/// [contentWidth] x [contentHeight].
final class _Container implements CanvasContainer {
  const _Container(this.contentWidth, this.contentHeight);

  @override
  final double contentWidth;

  @override
  final double contentHeight;

  @override
  bool get isConnected => true;
}

/// A canvas element in [parentNode]. `getMaximumSize` reads only the parent
/// node.
final class _Canvas implements HTMLCanvasElement, CanvasNode {
  _Canvas(this.parentNode);

  @override
  final CanvasContainer? parentNode;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// `document.createElement('div')` with the style `width` x `height`,
/// appended to `document.body`, and a node inside it: the port gives the
/// inner node as a canvas whose parent node has that size.
_Canvas _nodeIn(double width, double height) =>
    _Canvas(_Container(width, height));

/// The object `{x, y}` of [point], for `toEqual`.
Map<String, Object?> _point(Point point) => <String, Object?>{
  'x': point.x,
  'y': point.y,
};

/// `jasmine.objectContaining({width, height})` for the record of
/// `getMaximumSize`.
Matcher _size(double width, double height) =>
    isA<({double width, double height})>()
        .having((s) => s.width, 'width', width)
        .having((s) => s.height, 'height', height);

void main() {
  group('DOM helpers tests', () {
    test('should get the maximum size for a node', () {
      // A div of 200px x 300px holds the node.
      final innerDiv = _nodeIn(200, 300);

      expect(helpers.getMaximumSize(innerDiv), _size(200, 300));
    });

    test(
      'should get the maximum width and height for a node in a ShadowRoot',
      () {},
      skip: 'n/a: Flutter has no shadow DOM',
    );

    test(
      'should get the maximum width of a node that has a max-width style',
      () {},
      skip: 'n/a: Flutter has no CSS max-width',
    );

    test(
      'should get the maximum height of a node that has a max-height style',
      () {},
      skip: 'n/a: Flutter has no CSS max-height',
    );

    test(
      'should get the maximum width of a node when the parent has a '
      'max-width style',
      () {},
      skip: 'n/a: Flutter has no CSS max-width',
    );

    test(
      'should get the maximum height of a node when the parent has a '
      'max-height style',
      () {},
      skip: 'n/a: Flutter has no CSS max-height',
    );

    test(
      'should get the maximum width of a node that has a percentage '
      'max-width style',
      () {},
      skip: 'n/a: Flutter has no CSS max-width',
    );

    test(
      'should get the maximum height of a node that has a percentage '
      'max-height style',
      () {},
      skip: 'n/a: Flutter has no CSS max-height',
    );

    test(
      'should get the maximum width of a node when the parent has a '
      'percentage max-width style',
      () {},
      skip: 'n/a: Flutter has no CSS max-width',
    );

    test(
      'should get the maximum height of a node when the parent has a '
      'percentage max-height style',
      () {},
      skip: 'n/a: Flutter has no CSS max-height',
    );

    test(
      'Should get padding of parent as number (pixels) when defined as '
      'percent (returns incorrectly in IE11)',
      () {},
      skip: 'n/a: Flutter has no CSS padding',
    );

    testWidgets(
      'should leave styled height and width on canvas if explicitly set',
      (tester) async {
        final chart = acquireChart({}, {
          'canvas': <String, Object?>{
            'height': 200,
            'width': 200,
            'style': 'height: 400px; width: 400px;',
          },
        });

        // retinaScale(chart, true): JavaScript multiplies with the ratio
        // `true`, which ToNumber makes 1. The Dart ratio is a `double?`.
        helpers.retinaScale(chart, 1);

        final canvas = chart.canvas!;

        expect(canvas.style.height, '400px');
        expect(canvas.style.width, '400px');
      },
    );

    testWidgets('should handle devicePixelRatio correctly', (tester) async {
      const chartWidth = 800;
      const chartHeight = 400;
      const devicePixelRatio = 0.8999999761581421; // 1.7999999523162842;
      final chart = acquireChart({}, {
        'canvas': <String, Object?>{
          'width': chartWidth,
          'height': chartHeight,
        },
      });

      helpers.retinaScale(chart, devicePixelRatio, true);

      final canvas = chart.canvas!;
      expect(canvas.width, jsRound(chartWidth * devicePixelRatio));
      expect(canvas.height, jsRound(chartHeight * devicePixelRatio));

      expect(chart.width, chartWidth);
      expect(chart.height, chartHeight);

      expect(canvas.style.width, '${chartWidth}px');
      expect(canvas.style.height, '${chartHeight}px');
    });

    group('getRelativePosition', () {
      // The case also reads canvases with CSS padding, whose position the
      // port does not scale.
      test(
        'should use offsetX/Y when available',
        () {},
        skip: 'diverges: platform-relative-position',
      );

      // The port has no clientX/clientY fallback.
      test(
        'should calculate from clientX/Y as fallback',
        () {},
        skip: 'diverges: platform-relative-position',
      );

      test(
        'should get the correct relative position for a node in a ShadowRoot',
        () {},
        skip: 'n/a: Flutter has no shadow DOM',
      );

      testWidgets('Should not return NaN with a custom event', (
        tester,
      ) async {
        Object? dataX;
        Object? dataY;
        late final Chart chart;
        chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 'first', 'y': 10},
                  <String, Object?>{'x': 'second', 'y': 5},
                  <String, Object?>{'x': 'third', 'y': 15},
                ],
              },
            ],
          },
          'options': <String, Object?>{
            'onHover': (Object e) {
              final canvasPosition = helpers.getRelativePosition(e, chart);

              dataX = canvasPosition.x;
              dataY = canvasPosition.y;
            },
          },
        });

        final point = chart.getDatasetMeta(0).data[1];
        await triggerMouseEvent(chart, 'mousemove', point);

        expect(dataX, isNot(jasmineEquals(double.nan)));
        expect(dataY, isNot(jasmineEquals(double.nan)));
      });

      testWidgets(
        'Should give consistent results for native and chart events',
        (tester) async {
          Point? chartPosition;
          late final Chart chart;
          chart = acquireChart(<String, Object?>{
            'type': 'bar',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[
                    <String, Object?>{'x': 'first', 'y': 10},
                    <String, Object?>{'x': 'second', 'y': 5},
                    <String, Object?>{'x': 'third', 'y': 15},
                  ],
                },
              ],
            },
            'options': <String, Object?>{
              'onHover': (Object chartEvent) {
                chartPosition = helpers.getRelativePosition(chartEvent, chart);
              },
            },
          });

          final point = chart.getDatasetMeta(0).data[1];
          final nativeEvent = await triggerMouseEvent(
            chart,
            'mousemove',
            point,
          );
          final nativePosition = helpers.getRelativePosition(
            nativeEvent,
            chart,
          );

          expect(chartPosition, isNotNull);
          expect(
            _point(nativePosition),
            jasmineEquals(<String, Object?>{
              'x': chartPosition!.x,
              'y': chartPosition!.y,
            }),
          );
        },
      );
    });

    test('should respect aspect ratio and container width', () {
      // A container of 200px x 500px holds the target.
      final target = _nodeIn(200, 500);

      expect(helpers.getMaximumSize(target, 200, 500, 1), _size(200, 200));
    });

    test('should respect aspect ratio and container height', () {
      // A container of 500px x 200px holds the target.
      final target = _nodeIn(500, 200);

      expect(helpers.getMaximumSize(target, 500, 200, 1), _size(200, 200));
    });

    test('should respect aspect ratio and skip container height', () {
      // A container of 500px x 200px holds the target.
      final target = _nodeIn(500, 200);

      expect(helpers.getMaximumSize(target, null, null, 1), _size(500, 500));
    });

    test('should round non-integer container dimensions', () {
      // A container of 799.999px x 299.999px holds the target.
      final target = _nodeIn(799.999, 299.999);

      expect(helpers.getMaximumSize(target, null, null, 2), _size(800, 400));
    });
  });
}
