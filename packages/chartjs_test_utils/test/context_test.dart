// Original code, not ported from Chart.js: tests of the mock context.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:test/test.dart';

// The recordings follow chartjs-test-utils 0.4.0 src/context.js. Where Dart
// records an argument that a JS caller leaves out, the case names the
// harness-mock-optional-args row (differences.md).

void main() {
  group('createMockContext', () {
    test('returns a new MockContext with no calls', () {
      final first = createMockContext();
      final second = createMockContext();
      expect(first, isA<MockContext>());
      expect(identical(first, second), isFalse);
      expect(first.getCalls(), isEmpty);
    });
  });

  group('MockContext', () {
    test('records methods and property writes in order', () {
      final ctx = createMockContext()
        ..save()
        ..fillStyle = 'red'
        ..lineWidth = 2
        ..beginPath()
        ..moveTo(1, 2)
        ..lineTo(3, 4)
        ..stroke()
        ..restore();
      expect(ctx.getCalls(), [
        {'name': 'save', 'args': <Object?>[]},
        {
          'name': 'setFillStyle',
          'args': ['red'],
        },
        {
          'name': 'setLineWidth',
          'args': [2],
        },
        {'name': 'beginPath', 'args': <Object?>[]},
        {
          'name': 'moveTo',
          'args': [1, 2],
        },
        {
          'name': 'lineTo',
          'args': [3, 4],
        },
        {
          'name': 'stroke',
          'args': [null],
        },
        {'name': 'restore', 'args': <Object?>[]},
      ]);
    });

    test('records each property setter under its set name', () {
      final ctx = createMockContext()
        ..fillStyle = 'a'
        ..font = '12px Arial'
        ..lineCap = 'round'
        ..lineDashOffset = 1.5
        ..lineJoin = 'bevel'
        ..lineWidth = 3
        ..strokeStyle = 'b'
        ..textAlign = 'center'
        ..textBaseline = 'middle';
      expect(
        [for (final call in ctx.getCalls()) call['name']],
        [
          'setFillStyle',
          'setFont',
          'setLineCap',
          'setLineDashOffset',
          'setLineJoin',
          'setLineWidth',
          'setStrokeStyle',
          'setTextAlign',
          'setTextBaseline',
        ],
      );
      expect(ctx.fillStyle, 'a');
      expect(ctx.font, '12px Arial');
      expect(ctx.lineCap, 'round');
      expect(ctx.lineDashOffset, 1.5);
      expect(ctx.lineJoin, 'bevel');
      expect(ctx.lineWidth, 3);
      expect(ctx.strokeStyle, 'b');
      expect(ctx.textAlign, 'center');
      expect(ctx.textBaseline, 'middle');
    });

    test('the recorded properties start as null', () {
      final ctx = createMockContext();
      expect(ctx.fillStyle, isNull);
      expect(ctx.font, isNull);
      expect(ctx.lineCap, isNull);
      expect(ctx.lineDashOffset, isNull);
      expect(ctx.lineJoin, isNull);
      expect(ctx.lineWidth, isNull);
      expect(ctx.strokeStyle, isNull);
      expect(ctx.textAlign, isNull);
      expect(ctx.textBaseline, isNull);
    });

    test('resetCalls clears the recordings', () {
      final ctx = createMockContext()..save();
      final before = ctx.getCalls();
      ctx.resetCalls();
      expect(ctx.getCalls(), isEmpty);
      // JS assigns a new array: the old one keeps its calls.
      expect(before, hasLength(1));
    });

    group('harness-mock-optional-args', () {
      test('records null for an absent optional argument', () {
        final ctx = createMockContext()
          ..fillText('a', 1, 2)
          ..fillText('b', 1, 2, 30)
          ..strokeText('c', 1, 2)
          ..fill()
          ..clip()
          ..stroke();
        expect(ctx.getCalls(), [
          {
            'name': 'fillText',
            'args': ['a', 1, 2, null],
          },
          {
            'name': 'fillText',
            'args': ['b', 1, 2, 30],
          },
          {
            'name': 'strokeText',
            'args': ['c', 1, 2, null],
          },
          {
            'name': 'fill',
            'args': [null, null],
          },
          {
            'name': 'clip',
            'args': [null, null],
          },
          {
            'name': 'stroke',
            'args': [null],
          },
        ]);
      });

      test('records the default of a non-nullable optional argument', () {
        // JS records 5 arguments for arc(1, 2, 3, 0, 1). Dart records the
        // default `counterclockwise` value, false.
        final ctx = createMockContext()
          ..arc(1, 2, 3, 0, 1)
          ..arc(1, 2, 3, 0, 1, true);
        expect(ctx.getCalls(), [
          {
            'name': 'arc',
            'args': [1, 2, 3, 0, 1, false],
          },
          {
            'name': 'arc',
            'args': [1, 2, 3, 0, 1, true],
          },
        ]);
      });

      test('records a path and a fill rule', () {
        final path = Path2D()..rect(0, 0, 1, 1);
        final ctx = createMockContext()
          ..fill(path)
          ..fill('evenodd')
          ..clip(path, 'nonzero')
          ..stroke(path);
        expect(ctx.getCalls(), [
          {
            'name': 'fill',
            'args': [path, null],
          },
          {
            'name': 'fill',
            'args': ['evenodd', null],
          },
          {
            'name': 'clip',
            'args': [path, 'nonzero'],
          },
          {
            'name': 'stroke',
            'args': [path],
          },
        ]);
      });
    });

    test('records the other methods with their arguments', () {
      final ctx = createMockContext()
        ..arcTo(1, 2, 3, 4, 5)
        ..bezierCurveTo(1, 2, 3, 4, 5, 6)
        ..clearRect(0, 0, 10, 20)
        ..closePath()
        ..fillRect(1, 2, 3, 4)
        ..quadraticCurveTo(1, 2, 3, 4)
        ..rect(1, 2, 3, 4)
        ..rotate(0.5)
        ..setLineDash([2, 3])
        ..strokeRect(1, 2, 3, 4)
        ..setTransform(1, 0, 0, 1, 5, 6)
        ..translate(7, 8);
      expect(ctx.getCalls(), [
        {
          'name': 'arcTo',
          'args': [1, 2, 3, 4, 5],
        },
        {
          'name': 'bezierCurveTo',
          'args': [1, 2, 3, 4, 5, 6],
        },
        {
          'name': 'clearRect',
          'args': [0, 0, 10, 20],
        },
        {'name': 'closePath', 'args': <Object?>[]},
        {
          'name': 'fillRect',
          'args': [1, 2, 3, 4],
        },
        {
          'name': 'quadraticCurveTo',
          'args': [1, 2, 3, 4],
        },
        {
          'name': 'rect',
          'args': [1, 2, 3, 4],
        },
        {
          'name': 'rotate',
          'args': [0.5],
        },
        {
          'name': 'setLineDash',
          'args': [
            [2, 3],
          ],
        },
        {
          'name': 'strokeRect',
          'args': [1, 2, 3, 4],
        },
        {
          'name': 'setTransform',
          'args': [1, 0, 0, 1, 5, 6],
        },
        {
          'name': 'translate',
          'args': [7, 8],
        },
      ]);
    });

    test('setLineDash records the segments array', () {
      // context.js:156-160 slices the argument list, not the array: the
      // record holds the caller's array.
      final segments = <double>[1, 2];
      final ctx = createMockContext()..setLineDash(segments);
      final args = ctx.getCalls().single['args']! as List<Object?>;
      expect(identical(args[0], segments), isTrue);
      segments.add(3);
      expect(ctx.getCalls().single['args'], [
        [1, 2, 3],
      ]);
    });

    test('measureText gives 10 per code unit and fixed boxes', () {
      final ctx = createMockContext();
      final metrics = ctx.measureText('abc');
      expect(metrics.width, 30);
      expect(metrics.actualBoundingBoxAscent, 4);
      expect(metrics.actualBoundingBoxDescent, 8);
      expect(metrics.actualBoundingBoxLeft, 15);
      expect(metrics.actualBoundingBoxRight, 25);
      // 'é' as e + U+0301 and an emoji count UTF-16 code units, as JS
      // `text.length`.
      expect(ctx.measureText('é').width, 20);
      expect(ctx.measureText('\u{1F600}').width, 20);
      expect(ctx.getCalls().first, {
        'name': 'measureText',
        'args': ['abc'],
      });
    });

    test('measureText of an empty text gives zeros', () {
      final metrics = createMockContext().measureText('');
      expect(metrics.width, 0);
      expect(metrics.actualBoundingBoxAscent, 0);
      expect(metrics.actualBoundingBoxDescent, 0);
      expect(metrics.actualBoundingBoxLeft, 0);
      expect(metrics.actualBoundingBoxRight, 0);
    });

    test('members that context.js lacks throw or store silently', () {
      final ctx = createMockContext();
      expect(() => ctx.canvas, throwsUnsupportedError);
      expect(() => ctx.scale(1, 1), throwsUnsupportedError);
      expect(() => ctx.ellipse(0, 0, 1, 1, 0, 0, 1), throwsUnsupportedError);
      expect(
        () => ctx.transform(1, 0, 0, 1, 0, 0),
        throwsUnsupportedError,
      );
      expect(ctx.resetTransform, throwsUnsupportedError);
      expect(
        () => ctx.createLinearGradient(0, 0, 1, 1),
        throwsUnsupportedError,
      );
      expect(ctx.getLineDash, throwsUnsupportedError);
      ctx
        ..globalAlpha = 0.5
        ..globalCompositeOperation = 'source-over'
        ..miterLimit = 4
        ..direction = 'rtl';
      expect(ctx.globalAlpha, 0.5);
      expect(ctx.globalCompositeOperation, 'source-over');
      expect(ctx.miterLimit, 4);
      expect(ctx.direction, 'rtl');
      expect(ctx.getCalls(), isEmpty);
    });
  });
}
