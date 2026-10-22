// Original code, not ported from Chart.js: helpers.canvas cases with no spec.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:test/test.dart';

import 'draw_point_reference.dart';
import 'rounded_rect_upstream.dart';

// Upstream behaviour that test/specs/helpers.canvas.tests.js does not check
// (AGENTS.md rule 3). The expected values of toFontString and isPointInArea
// come from the helpers of the chart.js 4.5.1 npm package
// (dist/chart.umd.js) in Node.js v24.12.0 on x64.
//
// The call sequences of the canvas functions come from
// src/helpers/helpers.canvas.ts at v4.5.1, run with type stripping in
// Node.js v24.12.0 on x64 against a recording context with the parameter
// lists of MockContext (harness-mock-optional-args). The drawPointLegend
// sequences are in draw_point_reference.dart, which
// tool/reference/draw_point_reference.mjs writes (Chart.js ADR 0032). The
// tests compare every number with closeTo (Chart.js ADR 0034).

/// A JavaScript font object literal, passed as a [FontSpec]. A null member
/// is an absent key or JS `null`.
final class _Font implements FontSpec {
  const _Font({this.style, this.weight, this.size, this.family});

  @override
  Object? get lineHeight => null;

  @override
  final String? style;

  @override
  final Object? weight;

  @override
  final double? size;

  @override
  final String? family;
}

/// A JavaScript object literal `{x, y}`, passed as a [Point].
final class _Point implements Point {
  const _Point(this.x, this.y);

  @override
  final double? x;

  @override
  final double? y;
}

/// A JavaScript object literal `{left, top, right, bottom}`, passed as a
/// [TRBL].
final class _Area implements TRBL {
  const _Area({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;
}

/// Point coordinates for the tests that compare a function with its earlier
/// `jsToNumber` form: JS `null`, the signed zeros, NaN (a copied
/// `undefined`), the infinities, a subnormal, large values and finites.
const List<double?> _coordinates = [
  null,
  0,
  -0,
  double.nan,
  double.infinity,
  double.negativeInfinity,
  double.minPositive,
  -double.minPositive,
  1.4e154,
  -1.4e154,
  -0.6,
  -0.4,
  1,
  255.75,
  512.4,
  512.5,
];

/// A [MockContext] that also records the members that `src/context.js`
/// lacks and that the canvas helpers call: `ellipse`, `drawImage` and
/// `resetTransform`. The upstream run used the same recording context.
final class _RecordingContext extends MockContext {
  @override
  void ellipse(
    double x,
    double y,
    double radiusX,
    double radiusY,
    double rotation,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) {
    record('ellipse', [
      x,
      y,
      radiusX,
      radiusY,
      rotation,
      startAngle,
      endAngle,
      counterclockwise,
    ]);
  }

  @override
  void drawImage(
    CanvasImageSource image,
    double dx,
    double dy, [
    double? dw,
    double? dh,
  ]) {
    record('drawImage', [image, dx, dy, dw, dh]);
  }

  @override
  void resetTransform() {
    record('resetTransform', const []);
  }
}

/// A canvas element with a fixed size, whose `getContext('2d')` gives
/// [context].
final class _Canvas implements HTMLCanvasElement {
  _Canvas(this.context, this.width, this.height);

  final CanvasRenderingContext2D? context;

  @override
  int width;

  @override
  int height;

  @override
  CanvasRenderingContext2D? getContext(String contextId) =>
      contextId == '2d' ? context : null;

  @override
  CSSStyleDeclaration get style => throw UnimplementedError();

  @override
  String? getAttribute(String name) => throw UnimplementedError();

  @override
  void setAttribute(String name, String value) => throw UnimplementedError();

  @override
  void removeAttribute(String name) => throw UnimplementedError();
}

/// An image point style, the `{width, height}` of an `HTMLImageElement`.
final class _Image implements CanvasImageSource {
  const _Image();

  @override
  double get width => 8;

  @override
  double get height => 6;
}

const _image = _Image();

/// An object point style that is not an image: the JS object `{}`.
const Object _object = <String, Object?>{};

/// The JavaScript object literal `{pointStyle, rotation, radius,
/// borderWidth}`, passed as [DrawPointOptions].
final class _PointOptions implements DrawPointOptions {
  const _PointOptions({
    required this.pointStyle,
    required this.rotation,
    required this.radius,
    required this.borderWidth,
  });

  @override
  final Object? pointStyle;

  @override
  final double? rotation;

  @override
  final double radius;

  @override
  final double borderWidth;
}

/// A chart that has only a device pixel ratio.
final class _Chart implements Chart {
  _Chart(this.currentDevicePixelRatio);

  @override
  double currentDevicePixelRatio;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A JavaScript object literal `{x, y, cp1x, cp1y, cp2x, cp2y}`, passed as a
/// [SplinePoint].
final class _SplinePoint implements SplinePoint {
  _SplinePoint(this.x, this.y, this.cp1x, this.cp1y, this.cp2x, this.cp2y);

  @override
  final double x;

  @override
  final double y;

  @override
  double cp1x;

  @override
  double cp1y;

  @override
  double cp2x;

  @override
  double cp2y;

  @override
  bool? get skip => null;
}

/// The JavaScript object literal `{x, y, w, h, radius}`, passed as a
/// [RoundedRect].
final class _RoundedRect implements RoundedRect {
  const _RoundedRect(this.x, this.y, this.w, this.h, this.radius);

  @override
  final double x;

  @override
  final double y;

  @override
  final double w;

  @override
  final double h;

  @override
  final Object? radius;
}

/// A JavaScript object literal `{topLeft, topRight, bottomLeft,
/// bottomRight}`, passed as [TRBLCorners].
final class _Corners implements TRBLCorners {
  const _Corners(
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
  );

  @override
  final double topLeft;

  @override
  final double topRight;

  @override
  final double bottomLeft;

  @override
  final double bottomRight;
}

/// The JavaScript font object literal `{string, lineHeight}`, passed as a
/// [CanvasFontSpec].
final class _CanvasFont implements CanvasFontSpec {
  const _CanvasFont(this.string, this.lineHeight);

  @override
  final String string;

  @override
  final Object? lineHeight;

  @override
  String? get family => null;

  @override
  double? get size => null;

  @override
  String? get style => null;

  @override
  Object? get weight => null;
}

/// A JavaScript object literal of render options, passed as a
/// [RenderTextOpts]. A null member is an absent key.
final class _Opts implements RenderTextOpts {
  const _Opts({
    this.color,
    this.decorationWidth,
    this.rotation,
    this.strokeColor,
    this.strokeWidth,
    this.underline,
    this.backdrop,
  });

  @override
  final Object? color;

  @override
  final double? decorationWidth;

  @override
  double? get maxWidth => null;

  @override
  final double? rotation;

  @override
  bool? get strikethrough => null;

  @override
  final Object? strokeColor;

  @override
  final double? strokeWidth;

  @override
  String? get textAlign => null;

  @override
  String? get textBaseline => null;

  @override
  (double, double)? get translation => null;

  @override
  final bool? underline;

  @override
  final BackdropOptions? backdrop;
}

/// The JavaScript object literal `{left, top, width, height, color}`, passed
/// as [BackdropOptions].
final class _Backdrop implements BackdropOptions {
  const _Backdrop(this.left, this.top, this.width, this.height, this.color);

  @override
  final double left;

  @override
  final double top;

  @override
  final double width;

  @override
  final double height;

  @override
  final Object? color;
}

/// The expected calls as matchers: the names exactly, numbers with
/// [closeTo], other values with `==`.
List<Object?> _calls(List<(String, List<Object?>)> calls) => [
  for (final (name, args) in calls)
    {
      'name': name,
      'args': [
        for (final arg in args)
          if (arg is num) closeTo(arg, 1e-9) else arg,
      ],
    },
];

/// The name of a point style in a test name.
String _styleName(Object? style) => switch (style) {
  final String name => "'$name'",
  _Image() => 'an image',
  Map<String, Object?>() => '{}',
  _ => '$style',
};

/// [value] with the markers of draw_point_reference.dart replaced by the
/// test values.
Object? _fromReference(Object? value) => switch (value) {
  drawPointImage => _image,
  drawPointObject => _object,
  _ => value,
};

/// The drawPointLegend calls with `x` 50 and `y` 40, and their calls on
/// the context, from the upstream run.
final List<DrawPointReferenceCase> _drawPointCases = [
  for (final c in drawPointReference)
    (
      style: _fromReference(c.style),
      rotation: c.rotation,
      w: c.w,
      radius: c.radius,
      borderWidth: c.borderWidth,
      calls: [
        for (final (name, args) in c.calls)
          (name, [for (final arg in args) _fromReference(arg)]),
      ],
    ),
];

void main() {
  group('toFontString', () {
    test('returns null without a font, a size or a family', () {
      expect(toFontString(null), isNull);
      expect(toFontString(const _Font(family: 'Arial')), isNull);
      expect(toFontString(const _Font(size: 12)), isNull);
    });

    test('joins style, weight, size and family', () {
      expect(
        toFontString(const _Font(size: 12, family: 'Arial')),
        '12px Arial',
      );
      expect(
        toFontString(
          const _Font(
            style: 'italic',
            weight: 'bold',
            size: 12,
            family: 'Arial',
          ),
        ),
        'italic bold 12px Arial',
      );
      expect(
        toFontString(
          const _Font(
            style: 'normal',
            weight: 300.5,
            size: 1 / 3,
            family: "'Helvetica Neue', sans-serif",
          ),
        ),
        "normal 300.5 0.3333333333333333px 'Helvetica Neue', sans-serif",
      );
    });

    test('leaves out a falsy style or weight', () {
      expect(
        toFontString(
          const _Font(style: '', weight: 0, size: 12, family: 'Arial'),
        ),
        '12px Arial',
      );
      expect(
        toFontString(
          const _Font(weight: double.nan, size: 1e21, family: 'Arial'),
        ),
        '1e+21px Arial',
      );
    });

    test('writes the weight and the size with Number::toString', () {
      expect(
        toFontString(const _Font(weight: 600, size: 12.5, family: 'Arial')),
        '600 12.5px Arial',
      );
      expect(
        toFontString(const _Font(size: -0, family: 'Arial')),
        '0px Arial',
      );
      expect(
        toFontString(const _Font(size: double.nan, family: 'Arial')),
        'NaNpx Arial',
      );
      expect(
        toFontString(const _Font(size: 1e-7, family: 'Arial')),
        '1e-7px Arial',
      );
    });

    test('keeps an empty family', () {
      expect(toFontString(const _Font(size: 12, family: '')), '12px ');
    });
  });

  group('isPointInArea', () {
    const area = _Area(left: 0, top: 0, right: 512, bottom: 256);

    test('uses a margin of 0.5 for a falsy margin', () {
      expect(isPointInArea(const _Point(-0.4, 0), area, 0), true);
      expect(isPointInArea(const _Point(-0.4, 0), area, double.nan), true);
      expect(isPointInArea(const _Point(-0.4, 0), area), true);
      expect(isPointInArea(const _Point(-0.6, 0), area), false);
      expect(isPointInArea(const _Point(512.4, 256.4), area), true);
      expect(isPointInArea(const _Point(512.5, 0), area), false);
      expect(isPointInArea(const _Point(0, -0.5), area), false);
    });

    test('uses a given margin', () {
      expect(isPointInArea(const _Point(-1.5, 0), area, 2), true);
      expect(isPointInArea(const _Point(-2, 0), area, 2), false);
      expect(isPointInArea(const _Point(0, 0), area, 0.1), true);
      expect(isPointInArea(const _Point(-0.1, 0), area, 0.1), false);
    });

    test('reads a null coordinate as 0 and a NaN coordinate as outside', () {
      expect(isPointInArea(const _Point(null, 0), area), true);
      expect(
        isPointInArea(
          const _Point(null, 0),
          const _Area(left: 1, top: 0, right: 512, bottom: 256),
        ),
        false,
      );
      expect(isPointInArea(const _Point(double.nan, 0), area), false);
      expect(isPointInArea(const _Point(0, double.nan), area), false);
    });

    test('gives the result of the jsToNumber form', () {
      // The form before Chart.js ADR 0010: ToNumber through jsToNumber.
      bool before(Point point, TRBL area, double margin) =>
          jsToNumber(point.x) > area.left - margin &&
          jsToNumber(point.x) < area.right + margin &&
          jsToNumber(point.y) > area.top - margin &&
          jsToNumber(point.y) < area.bottom + margin;
      const areas = [
        area,
        _Area(left: -0, top: 0, right: 0, bottom: -0),
        _Area(left: 1, top: 1, right: 2, bottom: 2),
      ];
      for (final testArea in areas) {
        for (final margin in const [0.5, 2.0, double.infinity]) {
          for (final x in _coordinates) {
            for (final y in _coordinates) {
              final point = _Point(x, y);
              expect(
                isPointInArea(point, testArea, margin),
                before(point, testArea, margin),
                reason: '($x, $y), margin $margin',
              );
            }
          }
        }
      }
    });

    group('adapt-point-in-area-bool', () {
      test('is false without a point and true without an area', () {
        // Upstream returns the falsy point itself: `undefined` or `null`.
        expect(isPointInArea(null, area), false);
        expect(isPointInArea(null, null), true);
        expect(isPointInArea(const _Point(600, 600), null), true);
      });
    });
  });

  group('measureText', () {
    test('measures a text once and lists it in gc', () {
      final ctx = createMockContext();
      final data = <String, double>{};
      final gc = <String>[];
      expect(measureText(ctx, data, gc, 0, 'abc'), 30);
      expect(measureText(ctx, data, gc, 0, 'abc'), 30);
      expect(data, {'abc': 30});
      expect(gc, ['abc']);
      expect(ctx.getCalls(), [
        {
          'name': 'measureText',
          'args': ['abc'],
        },
      ]);
    });

    test('measures and lists an empty text again: its width 0 is falsy', () {
      final ctx = createMockContext();
      final data = <String, double>{};
      final gc = <String>[];
      expect(measureText(ctx, data, gc, 5, ''), 5);
      expect(measureText(ctx, data, gc, 5, ''), 5);
      expect(gc, ['', '']);
      expect(ctx.getCalls().length, 2);
    });

    group('adapt-measure-text-proto', () {
      test('measures the names of Object.prototype members', () {
        // Upstream reads data['constructor'] and data['toString'] from
        // Object.prototype: both are truthy functions, so upstream measures
        // neither and gives 30 for this array.
        final ctx = createMockContext();
        expect(
          longestText(ctx, 'f', ['constructor', 'toString', 'ab']),
          110,
        );
        expect(ctx.getCalls().map((call) => call['args']), [
          <Object?>[],
          ['f'],
          ['constructor'],
          ['toString'],
          ['ab'],
          <Object?>[],
        ]);
      });
    });
  });

  group('longestText', () {
    test('skips null, undefined and nested arrays, and measures numbers', () {
      final ctx = createMockContext();
      final things = <Object?>[
        null,
        'ab',
        [
          null,
          'abc',
          ['zzzzzzzz'],
          undefined,
        ],
        undefined,
        5,
      ];
      expect(longestText(ctx, 'f', things), 30);
      // Upstream passes the number 5 to ctx.measureText, which converts it
      // to '5'.
      expect(ctx.getCalls().map((call) => call['args']), [
        <Object?>[],
        ['f'],
        ['ab'],
        ['abc'],
        ['5'],
        <Object?>[],
      ]);
    });

    test('collects garbage as upstream, also for an odd gc length', () {
      final ctx = createMockContext();
      final cache = LongestTextCache();
      longestText(ctx, 'f', ['a', 'b', 'c', 'd'], cache);
      expect(cache.data, {'a': 10, 'b': 10, 'c': 10, 'd': 10});
      expect(cache.garbageCollect, ['a', 'b', 'c', 'd']);
      expect(cache.font, 'f');

      // gc.length / 2 is 2.5: the loop deletes 'a', 'b' and 'c', and
      // splice removes 2 entries.
      longestText(ctx, 'f', ['eeeee'], cache);
      expect(cache.data, {'d': 10, 'eeeee': 50});
      expect(cache.garbageCollect, ['c', 'd', 'eeeee']);

      longestText(ctx, 'f', ['c'], cache);
      expect(cache.data, {'eeeee': 50});
      expect(cache.garbageCollect, ['eeeee', 'c']);
    });

    test('drops the cache when the font changes', () {
      final ctx = createMockContext();
      final cache = LongestTextCache();
      longestText(ctx, 'f', ['a', 'b', 'c', 'd'], cache);
      expect(longestText(ctx, 'g', ['xy'], cache), 20);
      expect(cache.data, {'xy': 20});
      expect(cache.garbageCollect, ['xy']);
      expect(cache.font, 'g');
    });

    test('reuses the widths of the cache', () {
      final ctx = createMockContext();
      final cache = LongestTextCache();
      longestText(ctx, 'f', ['abc'], cache);
      ctx.resetCalls();
      expect(longestText(ctx, 'f', ['abc'], cache), 30);
      expect(ctx.getCalls().map((call) => call['name']), [
        'save',
        'setFont',
        'restore',
      ]);
    });
  });

  group('alignPixel', () {
    test('aligns to the device pixel grid', () {
      expect(alignPixel(_Chart(1), 10.3, 1), 10.5);
      expect(alignPixel(_Chart(2), 10.3, 1), 10.5);
      expect(alignPixel(_Chart(2), 10.3, 0), 10.5);
      expect(alignPixel(_Chart(1), 10.3, 0), 10);
      // A width below 1 gives the half width 0.5.
      expect(alignPixel(_Chart(1), 10.3, 0.4), 10.5);
      expect(alignPixel(_Chart(1), 10.3, 4), 10);
    });

    test('rounds halves up, as Math.round', () {
      expect(alignPixel(_Chart(2), 10.25, 0), 10.5);
      // -20.5 rounds to -20: Math.round, not roundToDouble.
      expect(alignPixel(_Chart(2), -10.25, 0), -10);
    });

    test('gives NaN for a NaN width', () {
      expect(alignPixel(_Chart(1), 10, double.nan), isNaN);
    });
  });

  group('clearCanvas', () {
    test('does nothing without a canvas and a context', () {
      expect(clearCanvas, returnsNormally);
      // The spec passes the null canvas and context of a chart.
      // ignore: avoid_redundant_argument_values
      expect(() => clearCanvas(null, null), returnsNormally);
    });

    test('clears the canvas size without the transform', () {
      final ctx = _RecordingContext();
      clearCanvas(_Canvas(null, 150, 245), ctx);
      expect(ctx.getCalls(), [
        {'name': 'save', 'args': <Object?>[]},
        {'name': 'resetTransform', 'args': <Object?>[]},
        {
          'name': 'clearRect',
          'args': [0, 0, 150, 245],
        },
        {'name': 'restore', 'args': <Object?>[]},
      ]);
    });

    test("takes the context of getContext('2d') without a context", () {
      final ctx = _RecordingContext();
      clearCanvas(_Canvas(ctx, 300, 150));
      expect(ctx.getCalls()[2], {
        'name': 'clearRect',
        'args': [0, 0, 300, 150],
      });
    });

    test('throws for a context without a canvas, as upstream', () {
      expect(
        () => clearCanvas(null, _RecordingContext()),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('drawPointLegend', () {
    test('has the reference of Node.js v24.12.0 on x64', () {
      expect(drawPointReferenceNode, 'v24.12.0');
      expect(drawPointReferenceArch, 'x64');
      expect(drawPointReference, hasLength(64));
    });

    for (final c in _drawPointCases) {
      test(
        'draws ${_styleName(c.style)}, rotation ${c.rotation}, w ${c.w}, '
        'radius ${c.radius}, borderWidth ${c.borderWidth}',
        () {
          final ctx = _RecordingContext();
          drawPointLegend(
            ctx,
            _PointOptions(
              pointStyle: c.style,
              rotation: c.rotation,
              radius: c.radius,
              borderWidth: c.borderWidth,
            ),
            50,
            40,
            c.w,
          );
          expect(ctx.getCalls(), _calls(c.calls));
        },
      );
    }

    test('treats a w of 0 or NaN as no w', () {
      for (final w in const [0.0, double.nan]) {
        final ctx = _RecordingContext();
        drawPointLegend(
          ctx,
          const _PointOptions(
            pointStyle: 'circle',
            rotation: null,
            radius: 10,
            borderWidth: 1,
          ),
          50,
          40,
          w,
        );
        expect(ctx.getCalls()[1]['name'], 'arc', reason: '$w');
      }
    });

    test('treats a NaN rotation as no rotation', () {
      final ctx = _RecordingContext();
      drawPointLegend(
        ctx,
        const _PointOptions(
          pointStyle: 'rect',
          rotation: double.nan,
          radius: 10,
          borderWidth: 1,
        ),
        50,
        40,
        null,
      );
      expect(ctx.getCalls()[1]['name'], 'rect');
    });
  });

  group('drawPoint', () {
    test('is drawPointLegend without w', () {
      for (final c in _drawPointCases.where((c) => c.w == null)) {
        final ctx = _RecordingContext();
        drawPoint(
          ctx,
          _PointOptions(
            pointStyle: c.style,
            rotation: c.rotation,
            radius: c.radius,
            borderWidth: c.borderWidth,
          ),
          50,
          40,
        );
        expect(ctx.getCalls(), _calls(c.calls), reason: '${c.style}');
      }
    });
  });

  group('platform-canvas-point-style', () {
    // Upstream draws an HTMLCanvasElement point style as an image. In the
    // port a canvas element is not a CanvasImageSource, so it draws the
    // default circle. Its toImageSource() snapshot draws as an image.
    List<Object?> names(_RecordingContext ctx) => [
      for (final call in ctx.getCalls()) call['name'],
    ];

    test('a canvas element draws the default circle', () {
      final ctx = _RecordingContext();
      drawPointLegend(
        ctx,
        _PointOptions(
          pointStyle: _Canvas(null, 8, 6),
          rotation: null,
          radius: 10,
          borderWidth: 1,
        ),
        50,
        40,
        null,
      );
      expect(names(ctx), ['beginPath', 'arc', 'closePath', 'fill', 'stroke']);
    });

    test('a CanvasImageSource draws as an image', () {
      final ctx = _RecordingContext();
      drawPointLegend(
        ctx,
        const _PointOptions(
          pointStyle: _image,
          rotation: null,
          radius: 10,
          borderWidth: 1,
        ),
        50,
        40,
        null,
      );
      expect(names(ctx), [
        'save',
        'translate',
        'rotate',
        'drawImage',
        'restore',
      ]);
    });
  });

  group('clipArea and unclipArea', () {
    test('clip to the area and restore', () {
      final ctx = createMockContext();
      clipArea(ctx, const _Area(left: 10, top: 20, right: 110, bottom: 70));
      unclipArea(ctx);
      expect(ctx.getCalls(), [
        {'name': 'save', 'args': <Object?>[]},
        {'name': 'beginPath', 'args': <Object?>[]},
        {
          'name': 'rect',
          'args': [10, 20, 100, 50],
        },
        {
          'name': 'clip',
          'args': [null, null],
        },
        {'name': 'restore', 'args': <Object?>[]},
      ]);
    });
  });

  group('steppedLineTo', () {
    const previous = _Point(10, 20);
    const target = _Point(30, 60);

    List<Object?> lines(void Function(MockContext ctx) draw) {
      final ctx = createMockContext();
      draw(ctx);
      return ctx.getCalls().map((call) => call['args']).toList();
    }

    test('draws a line without a previous point', () {
      expect(lines((ctx) => steppedLineTo(ctx, null, target)), [
        [30, 60],
      ]);
    });

    test("steps in the middle for 'middle'", () {
      expect(
        lines((ctx) => steppedLineTo(ctx, previous, target, null, 'middle')),
        [
          [20, 20],
          [20, 60],
          [30, 60],
        ],
      );
    });

    test("steps before for 'before' and true, after for 'after'", () {
      for (final mode in const [true, 'before']) {
        expect(
          lines((ctx) => steppedLineTo(ctx, previous, target, null, mode)),
          [
            [30, 20],
            [30, 60],
          ],
        );
      }
      expect(
        lines((ctx) => steppedLineTo(ctx, previous, target, false, 'after')),
        [
          [10, 60],
          [30, 60],
        ],
      );
    });

    test('flip swaps before and after', () {
      expect(
        lines((ctx) => steppedLineTo(ctx, previous, target, true, 'before')),
        [
          [10, 60],
          [30, 60],
        ],
      );
      expect(
        lines((ctx) => steppedLineTo(ctx, previous, target, true, 'after')),
        [
          [30, 20],
          [30, 60],
        ],
      );
    });

    test('draws on a Path2D', () {
      final path = Path2D();
      steppedLineTo(path, previous, target, null, 'middle');
      expect(path.commands.length, 3);
    });
  });

  group('bezierCurveTo', () {
    final previous = _SplinePoint(10, 20, 1, 2, 3, 4);
    final target = _SplinePoint(30, 60, 5, 6, 7, 8);

    test('draws a line without a previous point', () {
      final ctx = createMockContext();
      bezierCurveTo(ctx, null, target);
      expect(ctx.getCalls(), [
        {
          'name': 'lineTo',
          'args': [30, 60],
        },
      ]);
    });

    test('takes cp2 of previous and cp1 of target', () {
      final ctx = createMockContext();
      bezierCurveTo(ctx, previous, target);
      bezierCurveTo(ctx, previous, target, false);
      expect(ctx.getCalls().map((call) => call['args']), [
        [3, 4, 5, 6, 30, 60],
        [3, 4, 5, 6, 30, 60],
      ]);
    });

    test('takes cp1 of previous and cp2 of target when flipped', () {
      final ctx = createMockContext();
      bezierCurveTo(ctx, previous, target, true);
      expect(ctx.getCalls().single['args'], [1, 2, 7, 8, 30, 60]);
    });
  });

  group('renderText', () {
    test('draws the backdrop of each line and restores the fill style', () {
      final ctx = createMockContext()
        ..fillStyle = 'blue'
        ..resetCalls();
      renderText(
        ctx,
        ['a', 'b'],
        1,
        2,
        const _CanvasFont('9px x', '15'),
        const _Opts(
          backdrop: _Backdrop(1, 2, 3, 4, 'red'),
          // An empty stroke color stops the stroke, and an empty color
          // leaves the fill style.
          strokeColor: '',
          strokeWidth: 2,
          color: '',
          rotation: 0,
          decorationWidth: 0,
          underline: true,
        ),
      );
      final backdrop = [
        {
          'name': 'setFillStyle',
          'args': ['red'],
        },
        {
          'name': 'fillRect',
          'args': [1, 2, 3, 4],
        },
        {
          'name': 'setFillStyle',
          'args': ['blue'],
        },
      ];
      List<Object?> underline(double y) => [
        {
          'name': 'setStrokeStyle',
          'args': ['blue'],
        },
        {'name': 'beginPath', 'args': <Object?>[]},
        // A falsy decorationWidth gives 2.
        {
          'name': 'setLineWidth',
          'args': [2],
        },
        {
          'name': 'moveTo',
          'args': [-14, y],
        },
        {
          'name': 'lineTo',
          'args': [26, y],
        },
        {
          'name': 'stroke',
          'args': [null],
        },
      ];
      expect(ctx.getCalls(), [
        {'name': 'save', 'args': <Object?>[]},
        {
          'name': 'setFont',
          'args': ['9px x'],
        },
        // A rotation of 0 is not null or undefined.
        {
          'name': 'rotate',
          'args': [0],
        },
        ...backdrop,
        {
          'name': 'fillText',
          'args': ['a', 1, 2, null],
        },
        {
          'name': 'measureText',
          'args': ['a'],
        },
        ...underline(10),
        ...backdrop,
        // Number('15') is 15.
        {
          'name': 'fillText',
          'args': ['b', 1, 17, null],
        },
        {
          'name': 'measureText',
          'args': ['b'],
        },
        ...underline(25),
        {'name': 'restore', 'args': <Object?>[]},
      ]);
    });

    test('strokes without a stroke color when the stroke width is set', () {
      final ctx = createMockContext();
      renderText(
        ctx,
        'a',
        1,
        2,
        const _CanvasFont('9px x', 20),
        const _Opts(strokeWidth: 3),
      );
      expect(ctx.getCalls().map((call) => call['name']), [
        'save',
        'setFont',
        'setLineWidth',
        'strokeText',
        'fillText',
        'restore',
      ]);
    });

    test('does not stroke for a zero or NaN stroke width', () {
      for (final width in const [0.0, double.nan, -1.0]) {
        final ctx = createMockContext();
        renderText(
          ctx,
          'a',
          1,
          2,
          const _CanvasFont('9px x', 20),
          _Opts(strokeColor: 'red', strokeWidth: width),
        );
        expect(
          ctx.getCalls().map((call) => call['name']),
          ['save', 'setFont', 'fillText', 'restore'],
          reason: '$width',
        );
      }
    });

    test("gives NaN lines for a line height of '1.2em'", () {
      final ctx = createMockContext();
      renderText(ctx, ['a', 'b'], 1, 2, const _CanvasFont('9px x', '1.2em'));
      final second = ctx.getCalls()[3]['args']! as List<Object?>;
      expect(second[0], 'b');
      expect(second[2], isNaN);
    });

    test('draws a number text as its ToString', () {
      final ctx = createMockContext();
      renderText(ctx, [5, 0.5], 0, 0, const _CanvasFont('9px x', 10));
      expect(ctx.getCalls()[2]['args'], ['5', 0, 0, null]);
      expect(ctx.getCalls()[3]['args'], ['0.5', 0, 10, null]);
    });
  });

  group('addRoundedRectPath', () {
    // adapt-rounded-rect-path: the port makes one roundRect call in place of
    // the four upstream arcs and lines. test/port/helpers/
    // helpers.canvas_ui_test.dart compares the pixels of the two forms.
    test('makes one roundRect call with the radii in the DOM order', () {
      final ctx = createMockContext();
      addRoundedRectPath(
        ctx,
        const _RoundedRect(10, 20, 100, 50, _Corners(1, 2, 3, 4)),
      );
      // [topLeft, topRight, bottomRight, bottomLeft]
      expect(ctx.getCalls(), [
        {
          'name': 'roundRect',
          'args': [
            10,
            20,
            100,
            50,
            [1, 2, 4, 3],
          ],
        },
      ]);
    });

    test('the roundRect call replays as the upstream arcs and lines', () {
      // The translation of adapt-rounded-rect-path back into the upstream
      // calls gives the calls of helpers.canvas.ts at v4.5.1.
      final ctx = UpstreamRoundedRectContext();
      addRoundedRectPath(
        ctx,
        const _RoundedRect(10, 20, 100, 50, _Corners(1, 2, 3, 4)),
      );
      expect(
        ctx.getCalls(),
        _calls([
          (
            'arc',
            [11, 21, 1, 1.5 * 3.141592653589793, 3.141592653589793, true],
          ),
          ('lineTo', [10, 67]),
          ('arc', [13, 67, 3, 3.141592653589793, 1.5707963267948966, true]),
          ('lineTo', [106, 70]),
          ('arc', [106, 66, 4, 1.5707963267948966, 0, true]),
          ('lineTo', [110, 22]),
          ('arc', [108, 22, 2, 0, -1.5707963267948966, true]),
          ('lineTo', [11, 20]),
        ]),
      );
    });

    test('passes the radii that upstream passes to arc unchanged', () {
      // roundRect throws for a negative radius and does nothing for NaN, as
      // the upstream arcs do (an IndexSizeError, a call that adds nothing).
      final ctx = createMockContext();
      addRoundedRectPath(
        ctx,
        const _RoundedRect(0, 0, 10, 10, _Corners(-1, double.nan, 99, 0)),
      );
      final args = ctx.getCalls().single['args']! as List<Object?>;
      expect(args[4], [-1, isNaN, 0, 99]);
    });
  });
}
