// Original code, not ported from Chart.js: the pure helpers.dom cases on web.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.dom.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:test/test.dart';

// test/specs/helpers.dom_test.dart runs on the VM only: its retinaScale and
// event cases call acquireChart (Chart.js ADR 0022). helpers.dom.dart is a
// pure layer (porting-flow.md section 3). Thus this file runs its pure
// arithmetic on the VM, dart2js and dart2wasm (`test:web`): the five
// getMaximumSize cases of the spec without CSS (helpers.dom.tests.js:8,
// :481, :498, :515, :532), and retinaScale with a fake chart and a recording
// context (helpers.dom.tests.js:240, :257). test/port/helpers/helpers.dom_test.dart has
// more cases on the VM. It imports helpers/index.dart, which exports the
// helpers.extras of package:flutter.

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
}

/// A context that records its `setTransform` calls as the mock context
/// does.
final class _Context implements CanvasRenderingContext2D {
  final List<List<double>> transforms = [];

  @override
  void setTransform(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  ) {
    transforms.add([a, b, c, d, e, f]);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A chart of [width] x [height] with a [_Canvas] and a [_Context].
/// `currentDevicePixelRatio` starts as NaN, the `ToNumber` of the
/// `undefined` of a new chart.
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

/// A canvas in a container of [width] x [height].
_Canvas _nodeIn(double width, double height) =>
    _Canvas(parentNode: _Container(width, height));

/// `jasmine.objectContaining({width, height})` for the record of
/// `getMaximumSize`.
Matcher _size(double width, double height) =>
    isA<({double width, double height})>()
        .having((s) => s.width, 'width', width)
        .having((s) => s.height, 'height', height);

void main() {
  setUpSpecs();

  group('getMaximumSize', () {
    test('should get the maximum size for a node', () {
      expect(getMaximumSize(_nodeIn(200, 300)), _size(200, 300));
    });

    test('should respect aspect ratio and container width', () {
      expect(getMaximumSize(_nodeIn(200, 500), 200, 500, 1), _size(200, 200));
    });

    test('should respect aspect ratio and container height', () {
      expect(getMaximumSize(_nodeIn(500, 200), 500, 200, 1), _size(200, 200));
    });

    test('should respect aspect ratio and skip container height', () {
      expect(
        getMaximumSize(_nodeIn(500, 200), null, null, 1),
        _size(500, 500),
      );
    });

    test('should round non-integer container dimensions', () {
      expect(
        getMaximumSize(_nodeIn(799.999, 299.999), null, null, 2),
        _size(800, 400),
      );
    });
  });

  group('retinaScale', () {
    test('should handle devicePixelRatio correctly', () {
      // helpers.dom.tests.js:257 with a fake chart.
      final chart = _Chart(800, 400);
      expect(retinaScale(chart, 0.8999999761581421, true), isTrue);
      expect([chart.canvas.width, chart.canvas.height], [720, 360]);
      expect([chart.width, chart.height], [800, 400]);
      expect(chart.currentDevicePixelRatio, 0.8999999761581421);
      expect(chart.canvas.style.values, {'height': '400px', 'width': '800px'});
      expect(chart.ctx.transforms, [
        [0.8999999761581421, 0, 0, 0.8999999761581421, 0, 0],
      ]);
    });

    test('should leave styled height and width on canvas if explicitly '
        'set', () {
      // helpers.dom.tests.js:240 with a fake chart.
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

    test('rounds the sizes to one decimal and floors the bitmap', () {
      // The reference rows of helpers.dom_test.dart, from the upstream
      // helpers.dom.ts in Node.js v24.12.0 on x64.
      final chart = _Chart(300.05, 149.95);
      expect(retinaScale(chart, 1.5), isTrue);
      expect([chart.width, chart.height], [300.1, 150]);
      expect([chart.canvas.width, chart.canvas.height], [450, 224]);
      expect(chart.canvas.style.values, {
        'height': '150px',
        'width': '300.1px',
      });
    });

    test('returns false when nothing changes', () {
      final chart = _Chart(800, 400);
      expect(retinaScale(chart, 2), isTrue);
      expect(retinaScale(chart, 2), isFalse);
      expect(chart.ctx.transforms, hasLength(1));
    });

    test('a fractional device size that does not change gives false', () {
      // The canvas gets Math.floor of the device size (helpers.dom.ts:230-231,
      // ledger row #12142), from the reference of helpers.dom_test.dart.
      final chart = _Chart(300.04, 150.06);
      expect(retinaScale(chart, 2), isTrue);
      expect(retinaScale(chart, 2), isFalse);
      expect([chart.canvas.width, chart.canvas.height], [600, 300]);
      expect(chart.ctx.transforms, hasLength(1));
    });
  });
}
