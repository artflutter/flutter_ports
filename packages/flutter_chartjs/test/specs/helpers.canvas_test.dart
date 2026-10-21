// Ported from Chart.js v4.5.1+7169e651 test/specs/helpers.canvas.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart' show Chart;
import 'package:flutter_chartjs/src/helpers/helpers.canvas.dart' as helpers;
import 'package:flutter_chartjs/src/types/index.dart' hide Chart;
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// The spec reads the functions from Chart.helpers. Here `helpers` is
// helpers.canvas.dart. The upstream `_` exports drop the underscore (Chart.js
// ADR 0012): `_isPointInArea` is `isPointInArea`, `_longestText` is
// `longestText` and `_measureText` is `measureText`. The cache object `{}` of
// `_longestText` is a `LongestTextCache`.
//
// The clearCanvas cases call `acquireChart`. They are `testWidgets` cases
// (Chart.js ADR 0022, sections 1 and 2). Thus the file runs on the VM only,
// although helpers.canvas.dart is a pure layer.

/// The canvas context of a chart after `spyOn(chart.ctx, 'clearRect')`.
///
/// A Dart object cannot replace one of its methods. Thus the spy is a second
/// context that takes the place of `chart.ctx`. Its `clearRect` records each
/// call and does nothing else, as a Jasmine spy without `callThrough`. It
/// forwards the other members that the case and the release of the chart
/// call to the context of the chart: `canvas`, `save`, `restore` and
/// `resetTransform`. Another member throws a `NoSuchMethodError`.
final class _ClearRectSpy implements CanvasRenderingContext2D {
  _ClearRectSpy(this._context);

  final CanvasRenderingContext2D _context;

  /// `chart.ctx.clearRect.calls`.
  final JasmineCalls calls = JasmineCalls();

  @override
  void clearRect(double x, double y, double w, double h) {
    calls.add([x, y, w, h], object: this);
  }

  @override
  HTMLCanvasElement get canvas => _context.canvas;

  @override
  void save() => _context.save();

  @override
  void restore() => _context.restore();

  @override
  void resetTransform() => _context.resetTransform();

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// `spyOn(chart.ctx, 'clearRect')`. Jasmine removes a spy after the spec,
/// after the release of the chart. The spy here stays on the chart.
void _spyOnClearRect(Chart chart) {
  chart.ctx = _ClearRectSpy(chart.ctx!);
}

/// `chart.ctx.clearRect.calls` of a context with a spy.
JasmineCalls _clearRectCalls(CanvasRenderingContext2D? ctx) =>
    (ctx! as _ClearRectSpy).calls;

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

/// The JavaScript font object literal `{string, lineHeight}`, passed as a
/// [CanvasFontSpec]. The other members are absent keys.
final class _Font implements CanvasFontSpec {
  const _Font({required this.string, required this.lineHeight});

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
    this.maxWidth,
    this.rotation,
    this.strikethrough,
    this.strokeColor,
    this.strokeWidth,
    this.textAlign,
    this.textBaseline,
    this.translation,
    this.underline,
  });

  @override
  final Object? color;

  @override
  final double? decorationWidth;

  @override
  final double? maxWidth;

  @override
  final double? rotation;

  @override
  final bool? strikethrough;

  @override
  final Object? strokeColor;

  @override
  final double? strokeWidth;

  @override
  final String? textAlign;

  @override
  final String? textBaseline;

  @override
  final (double, double)? translation;

  @override
  final bool? underline;

  @override
  BackdropOptions? get backdrop => null;
}

void main() {
  group('Chart.helpers.canvas', () {
    // Chart.js v4.5.1+7169e651 has no `test/fixtures/helpers` directory, so
    // the group has 0 fixtures.
    group('auto', fixture.specs('helpers'));

    group('clearCanvas', () {
      testWidgets('should clear the chart canvas', (tester) async {
        final chart = acquireChart({}, {
          'canvas': <String, Object?>{'style': 'width: 150px; height: 245px'},
        });

        _spyOnClearRect(chart);

        helpers.clearCanvas(chart.canvas, chart.ctx);

        expect(_clearRectCalls(chart.ctx).count(), 1);
        expect(_clearRectCalls(chart.ctx).first().object, same(chart.ctx));
        expect(_clearRectCalls(chart.ctx).first().args, [0, 0, 150, 245]);
      });

      testWidgets('should not throw error when chart is null', (tester) async {
        void createAndClearChart() {
          final chart = acquireChart({}, {'canvas': null})
            // explicitly set canvas and ctx to null since setting it in
            // acquireChart doesn't do anything
            ..canvas = null
            ..ctx = null;

          helpers.clearCanvas(chart.canvas, chart.ctx);
        }

        expect(createAndClearChart, returnsNormally);
      });
    });

    group('isPointInArea', () {
      test('should return true when no area is provided', () {
        expect(helpers.isPointInArea(const _Point(1, 1), null), true);
      });
      test('should determine if a point is in the area', () {
        const isPointInArea = helpers.isPointInArea;
        const area = _Area(left: 0, top: 0, right: 512, bottom: 256);

        expect(isPointInArea(const _Point(0, 0), area), true);
        expect(isPointInArea(const _Point(-1e-12, -1e-12), area), true);
        expect(isPointInArea(const _Point(512, 256), area), true);
        expect(
          isPointInArea(const _Point(512 + 1e-12, 256 + 1e-12), area),
          true,
        );
        expect(isPointInArea(const _Point(-0.5, 0), area), false);
        expect(isPointInArea(const _Point(0, 256.5), area), false);
      });
    });

    test(
      'should return the width of the longest text in an Array and 2D Array',
      () {
        final context = createMockContext();
        const font =
            "normal 12px 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif";
        const arrayOfThings1D = ['FooBar', 'Bar'];
        const arrayOfThings2D = [
          ['FooBar_1', 'Bar_2'],
          'Foo_1',
        ];

        // Regardless 'FooBar' is the longest label it should return
        // (characters * 10)
        expect(
          helpers.longestText(
            context,
            font,
            arrayOfThings1D,
            helpers.LongestTextCache(),
          ),
          60,
        );
        expect(
          helpers.longestText(
            context,
            font,
            arrayOfThings2D,
            helpers.LongestTextCache(),
          ),
          80,
        );
        // We check to make sure we made the right calls to the canvas.
        expect(context.getCalls(), [
          {'name': 'save', 'args': <Object?>[]},
          {
            'name': 'setFont',
            'args': [
              "normal 12px 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
            ],
          },
          {
            'name': 'measureText',
            'args': ['FooBar'],
          },
          {
            'name': 'measureText',
            'args': ['Bar'],
          },
          {'name': 'restore', 'args': <Object?>[]},
          {'name': 'save', 'args': <Object?>[]},
          {
            'name': 'setFont',
            'args': [
              "normal 12px 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
            ],
          },
          {
            'name': 'measureText',
            'args': ['FooBar_1'],
          },
          {
            'name': 'measureText',
            'args': ['Bar_2'],
          },
          {
            'name': 'measureText',
            'args': ['Foo_1'],
          },
          {'name': 'restore', 'args': <Object?>[]},
        ]);
      },
    );

    test('compare text with current longest and update', () {
      final context = createMockContext();
      final data = <String, double>{};
      final gc = <String>[];
      const longest = 70.0;

      expect(helpers.measureText(context, data, gc, longest, 'foobar'), 70);
      expect(helpers.measureText(context, data, gc, longest, 'foobar_'), 70);
      expect(helpers.measureText(context, data, gc, longest, 'foobar_1'), 80);
      // We check to make sure we made the right calls to the canvas.
      expect(context.getCalls(), [
        {
          'name': 'measureText',
          'args': ['foobar'],
        },
        {
          'name': 'measureText',
          'args': ['foobar_'],
        },
        {
          'name': 'measureText',
          'args': ['foobar_1'],
        },
      ]);
    });

    group('renderText', () {
      // The mock records each declared parameter. The absent `maxWidth` of
      // `fillText` and `strokeText` and the absent path of `stroke` are
      // `null` (harness-mock-optional-args).

      test('should render multiple lines of text', () {
        final context = createMockContext();
        const font = _Font(string: '12px arial', lineHeight: 20);
        helpers.renderText(context, ['foo', 'foo2'], 0, 0, font);

        expect(context.getCalls(), [
          {'name': 'save', 'args': <Object?>[]},
          {
            'name': 'setFont',
            'args': ['12px arial'],
          },
          {
            'name': 'fillText',
            'args': ['foo', 0, 0, null],
          },
          {
            'name': 'fillText',
            'args': ['foo2', 0, 20, null],
          },
          {'name': 'restore', 'args': <Object?>[]},
        ]);
      });

      test('should accept the text maxWidth', () {
        final context = createMockContext();
        const font = _Font(string: '12px arial', lineHeight: 20);
        helpers.renderText(
          context,
          'foo',
          0,
          0,
          font,
          const _Opts(maxWidth: 30),
        );
        expect(context.getCalls(), [
          {'name': 'save', 'args': <Object?>[]},
          {
            'name': 'setFont',
            'args': ['12px arial'],
          },
          {
            'name': 'fillText',
            'args': ['foo', 0, 0, 30],
          },
          {'name': 'restore', 'args': <Object?>[]},
        ]);
      });

      test('should underline the text', () {
        final context = createMockContext();
        const font = _Font(string: '12px arial', lineHeight: 20);
        helpers.renderText(
          context,
          'foo',
          0,
          0,
          font,
          const _Opts(decorationWidth: 3, underline: true),
        );

        expect(context.getCalls(), [
          {'name': 'save', 'args': <Object?>[]},
          {
            'name': 'setFont',
            'args': ['12px arial'],
          },
          {
            'name': 'fillText',
            'args': ['foo', 0, 0, null],
          },
          {
            'name': 'measureText',
            'args': ['foo'],
          },
          {
            'name': 'setStrokeStyle',
            'args': [null],
          },
          {'name': 'beginPath', 'args': <Object?>[]},
          {
            'name': 'setLineWidth',
            'args': [3],
          },
          {
            'name': 'moveTo',
            'args': [-15, 8],
          },
          {
            'name': 'lineTo',
            'args': [25, 8],
          },
          {
            'name': 'stroke',
            'args': [null],
          },
          {'name': 'restore', 'args': <Object?>[]},
        ]);
      });

      test('should strikethrough the text', () {
        final context = createMockContext();
        const font = _Font(string: '12px arial', lineHeight: 20);
        helpers.renderText(
          context,
          'foo',
          0,
          0,
          font,
          const _Opts(strikethrough: true),
        );

        expect(context.getCalls(), [
          {'name': 'save', 'args': <Object?>[]},
          {
            'name': 'setFont',
            'args': ['12px arial'],
          },
          {
            'name': 'fillText',
            'args': ['foo', 0, 0, null],
          },
          {
            'name': 'measureText',
            'args': ['foo'],
          },
          {
            'name': 'setStrokeStyle',
            'args': [null],
          },
          {'name': 'beginPath', 'args': <Object?>[]},
          {
            'name': 'setLineWidth',
            'args': [2],
          },
          {
            'name': 'moveTo',
            'args': [-15, 2],
          },
          {
            'name': 'lineTo',
            'args': [25, 2],
          },
          {
            'name': 'stroke',
            'args': [null],
          },
          {'name': 'restore', 'args': <Object?>[]},
        ]);
      });

      test('should set the fill style if supplied', () {
        final context = createMockContext();
        const font = _Font(string: '12px arial', lineHeight: 20);
        helpers.renderText(
          context,
          'foo',
          0,
          0,
          font,
          const _Opts(color: 'red'),
        );

        expect(context.getCalls(), [
          {'name': 'save', 'args': <Object?>[]},
          {
            'name': 'setFont',
            'args': ['12px arial'],
          },
          {
            'name': 'setFillStyle',
            'args': ['red'],
          },
          {
            'name': 'fillText',
            'args': ['foo', 0, 0, null],
          },
          {'name': 'restore', 'args': <Object?>[]},
        ]);
      });

      test('should set the stroke style if supplied', () {
        final context = createMockContext();
        const font = _Font(string: '12px arial', lineHeight: 20);
        helpers.renderText(
          context,
          'foo',
          0,
          0,
          font,
          const _Opts(strokeColor: 'red', strokeWidth: 2),
        );
        expect(context.getCalls(), [
          {'name': 'save', 'args': <Object?>[]},
          {
            'name': 'setFont',
            'args': ['12px arial'],
          },
          {
            'name': 'setStrokeStyle',
            'args': ['red'],
          },
          {
            'name': 'setLineWidth',
            'args': [2],
          },
          {
            'name': 'strokeText',
            'args': ['foo', 0, 0, null],
          },
          {
            'name': 'fillText',
            'args': ['foo', 0, 0, null],
          },
          {'name': 'restore', 'args': <Object?>[]},
        ]);
      });

      test('should set the text alignment', () {
        final context = createMockContext();
        const font = _Font(string: '12px arial', lineHeight: 20);
        helpers.renderText(
          context,
          'foo',
          0,
          0,
          font,
          const _Opts(textAlign: 'left', textBaseline: 'middle'),
        );

        expect(context.getCalls(), [
          {'name': 'save', 'args': <Object?>[]},
          {
            'name': 'setFont',
            'args': ['12px arial'],
          },
          {
            'name': 'setTextAlign',
            'args': ['left'],
          },
          {
            'name': 'setTextBaseline',
            'args': ['middle'],
          },
          {
            'name': 'fillText',
            'args': ['foo', 0, 0, null],
          },
          {'name': 'restore', 'args': <Object?>[]},
        ]);
      });

      test('should translate and rotate text', () {
        final context = createMockContext();
        const font = _Font(string: '12px arial', lineHeight: 20);
        helpers.renderText(
          context,
          'foo',
          0,
          0,
          font,
          const _Opts(rotation: 90, translation: (10, 20)),
        );

        expect(context.getCalls(), [
          {'name': 'save', 'args': <Object?>[]},
          {
            'name': 'setFont',
            'args': ['12px arial'],
          },
          {
            'name': 'translate',
            'args': [10, 20],
          },
          {
            'name': 'rotate',
            'args': [90],
          },
          {
            'name': 'fillText',
            'args': ['foo', 0, 0, null],
          },
          {'name': 'restore', 'args': <Object?>[]},
        ]);
      });
    });
  });
}
