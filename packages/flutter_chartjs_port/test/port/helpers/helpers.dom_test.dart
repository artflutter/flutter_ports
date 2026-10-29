// Original code, not ported from Chart.js: helpers.dom tests beyond its spec.
@TestOn('vm')
library;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.dom.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.easing.dart'
    show effects;
import 'package:flutter_chartjs_port/src/helpers/index.dart' as helpers;
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:test/test.dart';

// test/specs/helpers.dom.tests.js tests getMaximumSize with integer sizes
// and needs acquireChart for retinaScale. These tests cover the exports of
// src/helpers/helpers.dom.ts with fake charts, canvases and containers
// (AGENTS.md rule 3), and the differences.md rows platform-dom-no-css,
// platform-dom-container, platform-dom-computed-style,
// platform-dom-supported and platform-relative-position.
//
// The expected values of the reference tables and of the retinaScale cases
// come from the upstream helpers.dom.ts at the pin in Node.js v24.12.0 on x64
// (darwin-x64 under Rosetta), run with type stripping. The DOM of the
// reference is a stub: a computed style with 0px margins, paddings and
// borders, `max-width: none` and `max-height: none`, and a parent node whose
// getBoundingClientRect has the container size. The stub canvas converts an
// assigned width and height with ToUint32, as the DOM does.
//
// The file runs on the VM only: helpers/index.dart exports helpers.extras,
// which imports package:flutter/scheduler.dart.

/// A test container with the content box [contentWidth] x [contentHeight].
final class _Container implements CanvasContainer {
  const _Container(this.contentWidth, this.contentHeight);

  @override
  final double contentWidth;

  @override
  final double contentHeight;

  @override
  bool get isConnected => true;
}

/// A map-backed inline style.
final class _Style implements CSSStyleDeclaration {
  _Style([Map<String, String>? values]) : values = {...?values};

  final Map<String, String> values;

  @override
  String getPropertyValue(String property) => values[property] ?? '';

  @override
  String getPropertyPriority(String property) => '';

  @override
  void setProperty(String property, String? value, [String? priority]) {
    if (value == null || value.isEmpty) {
      values.remove(property);
    } else {
      values[property] = value;
    }
  }
}

/// A canvas element of 300 x 150 device pixels in [parentNode].
final class _Canvas implements HTMLCanvasElement, CanvasNode {
  _Canvas({this.parentNode, _Style? style}) : style = style ?? _Style();

  @override
  CanvasContainer? parentNode;

  @override
  int width = 300;

  @override
  int height = 150;

  @override
  final _Style style;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String> toDataURL([String? type, Object? quality]) =>
      throw UnimplementedError();
}

/// A canvas element that does not implement [CanvasNode]: a canvas that no
/// host can show.
final class _BareCanvas implements HTMLCanvasElement {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String> toDataURL([String? type, Object? quality]) =>
      throw UnimplementedError();
}

/// A context that records its `setTransform` calls as the mock context
/// does: `{'name': 'setTransform', 'args': [...]}`.
final class _Context implements CanvasRenderingContext2D {
  final List<Map<String, Object?>> calls = [];

  @override
  void setTransform(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  ) {
    calls.add({
      'name': 'setTransform',
      'args': [a, b, c, d, e, f],
    });
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A chart of [width] x [height] with a [_Canvas] and a [_Context].
/// `currentDevicePixelRatio` starts as NaN, the `ToNumber` of the
/// `undefined` of a new chart: it differs from every pixel ratio.
final class _Chart implements Chart {
  _Chart(this.width, this.height, {_Style? style})
    : canvas = _Canvas(style: style);

  @override
  double width;

  @override
  double height;

  @override
  double currentDevicePixelRatio = double.nan;

  @override
  final _Canvas canvas;

  @override
  final _Context ctx = _Context();

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A chart event `{type, native, x, y}`.
final class _ChartEvent implements ChartEvent {
  const _ChartEvent(this.x, this.y);

  @override
  String get type => 'mousemove';

  @override
  final double? x;

  @override
  final double? y;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Matches the record of `getMaximumSize`.
Matcher _size(double width, double height) =>
    isA<({double width, double height})>()
        .having((s) => s.width, 'width', width)
        .having((s) => s.height, 'height', height);

/// Matches a [Point] at ([x], [y]).
Matcher _point(Object? x, Object? y) =>
    isA<Point>().having((p) => p.x, 'x', x).having((p) => p.y, 'y', y);

/// Matches -0.
final Matcher _negativeZero = predicate<double?>(
  (v) => v == 0 && v!.isNegative,
  '-0',
);

void main() {
  group('getMaximumSize', () {
    // [container width, container height, bbWidth, bbHeight, aspectRatio,
    // expected width, expected height]. A null size is JS undefined. A null
    // container is a canvas without a parent node.
    const table = <List<double?>>[
      [333.33, 211.17, null, null, null, 333.3, 211.2],
      [333.33, 211.17, null, null, 1.7, 333.3, 196.1],
      [333.37, 100.04, 333.37, 100.04, 2, 200, 100.04],
      [799.999, 299.999, null, null, 2, 800, 400],
      [0, 0, null, null, null, 0, 0],
      [640.55, 0, null, null, null, 640.6, 320.3],
      [100.26, 480.5, 100.26, 480.5, 0.75, 100.3, 133.7],
      [
        1234.5678,
        987.654,
        1234.5678,
        987.654,
        1.3333333333333333,
        1234.6,
        925.9,
      ],
      [400, 300, 400, null, 2, 400, 200],
      [250.05, 125.025, null, null, null, 250.1, 125],
      [0.05, 0.25, null, null, null, 0.1, 0.3],
      [-10, 50, null, null, null, 0, 50],
      [300.15, 1000, 300.15, 1000, 0.3, 300, 1000],
      [null, null, null, null, 2, 0, 0],
      [500, 200, 123.45, 67.891, null, 123.5, 67.9],
      [500, 200, 123.45, 67.891, 1.5, 101, 67.891],
    ];
    for (final row in table) {
      test('reference: $row', () {
        final [cw, ch, bbWidth, bbHeight, aspectRatio, width, height] = row;
        final canvas = _Canvas(
          parentNode: cw == null ? null : _Container(cw, ch!),
        );
        expect(
          getMaximumSize(canvas, bbWidth, bbHeight, aspectRatio),
          _size(width!, height!),
        );
      });
    }

    group('platform-dom-container', () {
      test('a canvas that is not a CanvasNode has no parent node', () {
        final canvas = _BareCanvas();
        expect(getParentNode(canvas), isNull);
        expect(getMaximumSize(canvas), _size(0, 0));
      });

      test('the parent node is the container of the canvas', () {
        const container = _Container(10, 20);
        expect(getParentNode(_Canvas(parentNode: container)), container);
        expect(getParentNode(_Canvas()), isNull);
      });

      test('given sizes do not read the container', () {
        final canvas = _Canvas(parentNode: const _Container(10, 20));
        expect(getMaximumSize(canvas, 640, 480), _size(640, 480));
      });

      test('an unbounded container gives an infinite size', () {
        final canvas = _Canvas(
          parentNode: const _Container(double.infinity, 200),
        );
        expect(
          getMaximumSize(canvas),
          _size(double.infinity, 200),
        );
      });
    });

    group('platform-dom-no-css', () {
      test('falsy aspect ratios use the container height', () {
        final canvas = _Canvas(parentNode: const _Container(300, 120));
        for (final aspectRatio in [null, 0.0, double.nan]) {
          expect(
            getMaximumSize(canvas, null, null, aspectRatio),
            _size(300, 120),
          );
        }
      });
    });
  });

  group('retinaScale', () {
    test('reference: should handle devicePixelRatio correctly', () {
      // The case of helpers.dom.tests.js:257 with a fake chart.
      final chart = _Chart(800, 400);
      expect(retinaScale(chart, 0.8999999761581421, true), isTrue);
      expect(chart.canvas.width, 720);
      expect(chart.canvas.height, 360);
      expect(chart.width, 800);
      expect(chart.height, 400);
      expect(chart.currentDevicePixelRatio, 0.8999999761581421);
      expect(chart.canvas.style.getPropertyValue('width'), '800px');
      expect(chart.canvas.style.getPropertyValue('height'), '400px');
      expect(chart.ctx.calls, [
        {
          'name': 'setTransform',
          'args': [0.8999999761581421, 0, 0, 0.8999999761581421, 0, 0],
        },
      ]);
    });

    // [width, height, forceRatio, forceStyle, chart width, chart height,
    // canvas width, canvas height, style width, style height].
    const table = <List<Object?>>[
      [300.04, 150.06, 2.0, false, 300, 150.1, 600, 300, '300px', '150.1px'],
      [300.05, 149.95, 1.5, null, 300.1, 150, 450, 224, '300.1px', '150px'],
      [100.5, 50.25, 3.0, true, 100.5, 50.3, 301, 150, '100.5px', '50.3px'],
    ];
    for (final row in table) {
      test('reference: $row', () {
        final [
          width as double,
          height as double,
          forceRatio as double,
          forceStyle as bool?,
          chartWidth,
          chartHeight,
          canvasWidth,
          canvasHeight,
          styleWidth,
          styleHeight,
        ] = row;
        final chart = _Chart(width, height);
        expect(retinaScale(chart, forceRatio, forceStyle), isTrue);
        expect([chart.width, chart.height], [chartWidth, chartHeight]);
        expect(chart.currentDevicePixelRatio, forceRatio);
        expect(
          [chart.canvas.width, chart.canvas.height],
          [canvasWidth, canvasHeight],
        );
        expect(
          chart.canvas.style.values,
          {'height': styleHeight, 'width': styleWidth},
        );
        expect(chart.ctx.calls, [
          {
            'name': 'setTransform',
            'args': [forceRatio, 0, 0, forceRatio, 0, 0],
          },
        ]);
      });
    }

    test('keeps a style that is set', () {
      // The case of helpers.dom.tests.js:240 with a fake chart.
      final chart = _Chart(
        200,
        100,
        style: _Style({'height': '400px', 'width': '400px'}),
      );
      expect(retinaScale(chart, null, false), isTrue);
      expect(chart.canvas.style.values, {'height': '400px', 'width': '400px'});
      expect(chart.currentDevicePixelRatio, 1);
      expect([chart.canvas.width, chart.canvas.height], [200, 100]);
    });

    test('a falsy ratio is 1', () {
      for (final ratio in [null, 0.0, double.nan]) {
        final chart = _Chart(300, 150);
        expect(retinaScale(chart, ratio), isTrue);
        expect(chart.currentDevicePixelRatio, 1);
        expect(chart.ctx.calls.single['args'], [1, 0, 0, 1, 0, 0]);
      }
    });

    test('returns false when nothing changes', () {
      final chart = _Chart(800, 400);
      expect(retinaScale(chart, 2), isTrue);
      expect(retinaScale(chart, 2), isFalse);
      expect(chart.ctx.calls, hasLength(1));
    });

    test('a fractional device size that does not change gives false', () {
      // The canvas gets Math.floor(600.1) = 600 and Math.floor(300.1) = 300
      // (helpers.dom.ts:230-231, ledger row #12142). The second call
      // compares 600 with 600 and 300 with Math.floor(300.2) = 300. v4.5.1
      // compares the canvas with the fractional device size and gives true.
      final chart = _Chart(300.04, 150.06);
      expect(retinaScale(chart, 2), isTrue);
      expect(retinaScale(chart, 2), isFalse);
      expect([chart.width, chart.height], [300, 150.1]);
      expect([chart.canvas.width, chart.canvas.height], [600, 300]);
      expect(chart.ctx.calls, hasLength(1));
    });

    test('a resize inside one device pixel gives false', () {
      // `_resize` stops when retinaScale gives false (core.controller.js:288).
      // The style takes the new size, and the canvas keeps its size.
      final chart = _Chart(300.3, 150.2);
      expect(retinaScale(chart, 1, true), isTrue);
      expect([chart.canvas.width, chart.canvas.height], [300, 150]);
      chart
        ..width = 300.6
        ..height = 150.7;
      expect(retinaScale(chart, 1, true), isFalse);
      expect([chart.width, chart.height], [300.6, 150.7]);
      expect([chart.canvas.width, chart.canvas.height], [300, 150]);
      expect(chart.canvas.style.values, {
        'height': '150.7px',
        'width': '300.6px',
      });
      expect(chart.ctx.calls, hasLength(1));
      chart.width = 301.2;
      expect(retinaScale(chart, 1, true), isTrue);
      expect([chart.canvas.width, chart.canvas.height], [301, 150]);
      expect(chart.ctx.calls, hasLength(2));
    });

    test('a non-finite device size gives 0', () {
      // Math.floor keeps NaN and Infinity. The canvas converts them to 0,
      // and 0 is not equal to NaN or Infinity: each call gives true.
      final chart = _Chart(double.nan, double.infinity);
      expect(retinaScale(chart, 1), isTrue);
      expect(retinaScale(chart, 1), isTrue);
      expect([chart.canvas.width, chart.canvas.height], [0, 0]);
      expect(chart.canvas.style.values, {
        'height': 'Infinitypx',
        'width': 'NaNpx',
      });
    });
  });

  group('readUsedSize', () {
    // [style value, expected]. From the reference engine.
    const table = <List<Object?>>[
      ['300px', 300],
      ['300.75px', 300],
      ['12.5em', null],
      ['', null],
      ['auto', null],
      ['007px', 7],
      ['-5px', null],
      ['5.px', null],
      ['1e3px', null],
      [' 30px', null],
    ];
    for (final [value as String, expected] in table) {
      test('reference: "$value"', () {
        final canvas = _Canvas(style: _Style({'width': value}));
        expect(readUsedSize(canvas, 'width'), expected);
      });
    }
  });

  group('platform-dom-computed-style', () {
    test('getStyle reads the inline style', () {
      final canvas = _Canvas(style: _Style({'width': '120px'}));
      expect(getStyle(canvas, 'width'), '120px');
      expect(getStyle(canvas, 'height'), '');
      expect(readUsedSize(canvas, 'height'), isNull);
    });
  });

  group('platform-dom-supported', () {
    test('there is no DOM', () {
      expect(isDomSupported(), isFalse);
      expect(supportsEventListenerOptions, isFalse);
    });
  });

  group('platform-relative-position', () {
    final chart = _Chart(400, 200);

    test('a chart event gives its own position', () {
      expect(
        getRelativePosition(const _ChartEvent(10.25, 20.75), chart),
        _point(10.25, 20.75),
      );
      expect(
        getRelativePosition(const _ChartEvent(null, null), chart),
        _point(isNull, isNull),
      );
    });

    test('a mouse event gives the rounded offset', () {
      for (final (offset, expected) in [
        (12.0, 12.0),
        (10.5, 11.0),
        (10.49, 10.0),
        (-2.5, -2.0),
        (399.6, 400.0),
      ]) {
        final event = NativeEvent(
          type: 'mousemove',
          offsetX: offset,
          offsetY: offset,
        );
        expect(
          getRelativePosition(event, chart),
          _point(expected, expected),
        );
      }
      final event = NativeEvent(
        type: 'mousemove',
        offsetX: -0.25,
        offsetY: 0,
      );
      final position = getRelativePosition(event, chart);
      expect(position.x, _negativeZero);
      expect(position.y, 0);
    });

    test('the scale of the canvas does not change the position', () {
      // Upstream multiplies by canvas.width / (chart.width * ratio), 1 here.
      final scaled = _Chart(400, 200);
      retinaScale(scaled, 2.5);
      final event = NativeEvent(
        type: 'mousemove',
        offsetX: 100.4,
        offsetY: 50.6,
      );
      expect(getRelativePosition(event, scaled), _point(100, 51));
    });

    test('a fractional device width can differ from upstream by 1 px', () {
      // retinaScale gives the canvas floor(round1(300.5 * 1)) = 300 device
      // pixels. Upstream gives Math.round(150.6 / 300.5 * 300) = 150. The
      // port drops the factor 300 / 300.5 and gives Math.round(150.6) = 151.
      final fractional = _Chart(300.5, 150);
      retinaScale(fractional, 1);
      expect(fractional.canvas.width, 300);
      final event = NativeEvent(
        type: 'mousemove',
        offsetX: 150.6,
        offsetY: 75,
      );
      expect(getRelativePosition(event, fractional), _point(151, 75));
    });

    test('a touch event gives the first touch', () {
      final event = NativeEvent(
        type: 'touchmove',
        offsetX: double.nan,
        offsetY: double.nan,
        touches: const [
          (identifier: 1, x: 30.5, y: 40.4),
          (identifier: 2, x: 300, y: 100),
        ],
      );
      expect(getRelativePosition(event, chart), _point(31, 40));
    });

    test('a touchend after the last finger lifts gives NaN', () {
      final event = NativeEvent(
        type: 'touchend',
        offsetX: double.nan,
        offsetY: double.nan,
      );
      expect(getRelativePosition(event, chart), _point(isNaN, isNaN));
    });

    test('another event object throws', () {
      expect(
        () => getRelativePosition(Object(), chart),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('helpers/index', () {
    test('easingEffects is the default export of helpers.easing', () {
      expect(identical(helpers.easingEffects, effects), isTrue);
    });

    test('exports helpers.dom', () {
      expect(helpers.getMaximumSize, same(getMaximumSize));
      expect(helpers.retinaScale, same(retinaScale));
    });
  });
}
