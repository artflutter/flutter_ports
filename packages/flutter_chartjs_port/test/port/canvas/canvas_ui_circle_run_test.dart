// Original code, not ported from Chart.js: the held run of the circle batch.
@TestOn('vm')
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_batch.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_compare.dart';

const double _tau = 2 * math.pi;

const _red = ui.Color(0xffdd4400);
const _blue = ui.Color(0xff4f6bed);
const _green = ui.Color(0x80119944);
const _wideRed = ui.Color.from(
  alpha: 1,
  red: 0.8,
  green: 0.2,
  blue: 0.2,
  colorSpace: ui.ColorSpace.displayP3,
);

/// An sRGB color equal to [color] that is not identical to it.
ui.Color _copy(ui.Color color) => ui.Color(color.toARGB32());

/// A copy of an argument of a native draw call, at the call: the context
/// changes its paints and its arrays after the call.
String _describe(Object? value) => switch (value) {
  final ui.Paint p =>
    'Paint(${p.color}, ${p.style}, ${p.strokeWidth}, ${p.blendMode}, '
        '${p.filterQuality}, ${p.isAntiAlias}, ${p.strokeCap}, '
        '${p.shader != null}, ${p.maskFilter})',
  final Float32List list => '${List<double>.of(list)}',
  final Int32List list => '${List<int>.of(list)}',
  final Float64List list => '${List<double>.of(list)}',
  final ui.Image image => 'Image(${image.width} x ${image.height})',
  final ui.Path path => 'Path(${path.getBounds()})',
  _ => '$value',
};

/// A canvas that logs each native call with its arguments and draws nothing.
/// It starts the recording of its recorder, which the context ends.
final class _LogCanvas(final List<String> _log, ui.PictureRecorder recorder)
    implements ui.Canvas {
  this {
    ui.Canvas(recorder);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final arguments = [
      for (final argument in invocation.positionalArguments)
        _describe(argument),
      for (final MapEntry(:key, :value) in invocation.namedArguments.entries)
        '$key: ${_describe(value)}',
    ];
    _log.add('${invocation.memberName}(${arguments.join(', ')})');
    return null;
  }
}

/// Draws on a context and calls the mark after each step of interest.
typedef _Scenario = void Function(UiCanvasContext ctx, void Function() mark);

/// What a context did in a scenario.
final class _Observed(
  /// The native draw calls of the recordings, with their arguments.
  final List<String> calls,

  /// The pending circles and the pictures at each mark.
  final List<(int, int)> steps,

  /// Whether the batch held a run at each mark.
  final List<bool> held,
);

_Observed _observe(_Scenario scenario, {required bool hold}) {
  final calls = <String>[];
  final steps = <(int, int)>[];
  final held = <bool>[];
  final holdBefore = UiCanvasContext.debugHoldCircleRuns;
  UiCanvasContext.debugHoldCircleRuns = hold;
  UiCanvasContext.debugRecordingCanvas = (recorder) =>
      _LogCanvas(calls, recorder);
  final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
  try {
    scenario(ctx, () {
      steps.add((ctx.debugPendingCircles, ctx.debugPictureCount));
      held.add(ctx.debugCircleRunHeld);
    });
    // The paint ends the recording: the last batch draws.
    final recorder = ui.PictureRecorder();
    ctx.paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
    recorder.endRecording().dispose();
  } finally {
    ctx.dispose();
    UiCanvasContext.debugRecordingCanvas = null;
    UiCanvasContext.debugHoldCircleRuns = holdBefore;
  }
  return _Observed(calls, steps, held);
}

Future<Render> _render(_Scenario scenario, {required bool hold}) async {
  final holdBefore = UiCanvasContext.debugHoldCircleRuns;
  UiCanvasContext.debugHoldCircleRuns = hold;
  try {
    return await renderContext((ctx) => scenario(ctx, () {}));
  } finally {
    UiCanvasContext.debugHoldCircleRuns = holdBefore;
  }
}

/// Runs [scenario] with the held runs and with a test of each circle, and
/// expects the same native calls, the same pending circles and pictures at
/// each mark and the same pixels. Gives the observation of the held form.
Future<_Observed> _expectSame(_Scenario scenario) async {
  final held = _observe(scenario, hold: true);
  final tested = _observe(scenario, hold: false);
  expect(tested.held, everyElement(isFalse));
  expect(held.steps, tested.steps);
  expect(held.calls.length, tested.calls.length);
  for (var i = 0; i < held.calls.length; i++) {
    expect(held.calls[i], tested.calls[i], reason: 'call $i');
  }
  final a = await _render(scenario, hold: true);
  final b = await _render(scenario, hold: false);
  final diff = comparePixels(a, b);
  expect(diff.differing, 0, reason: '$diff');
  return held;
}

/// A run of markers as `PointElement.drawCircleRun` makes it: the styles, the
/// start, one circle for each point until the context declines one, and the
/// path of the last drawn circle.
void _run(
  UiCanvasContext ctx,
  void Function() mark, {
  required double radius,
  required ui.Color fill,
  required Iterable<(double, double)> points,
  ui.Color? stroke,
  double width = 1,
}) {
  ctx
    ..strokeStyle = stroke ?? fill
    ..lineWidth = width
    ..fillStyle = fill;
  if (!ctx.tryStartCircleRun(radius, stroke: stroke != null)) {
    mark();
    return;
  }
  (double, double)? last;
  for (final point in points) {
    if (!ctx.tryAddRunCircle(point.$1, point.$2)) break;
    last = point;
    mark();
  }
  if (last != null) {
    ctx
      ..beginPath()
      ..arc(last.$1, last.$2, radius, 0, _tau)
      ..closePath();
  }
}

/// More circles of the run that [_run] started, after a change between them.
void _more(
  UiCanvasContext ctx,
  void Function() mark,
  Iterable<(double, double)> points,
) {
  for (final point in points) {
    if (!ctx.tryAddRunCircle(point.$1, point.$2)) break;
    mark();
  }
}

/// Circles with the ordinary calls of `drawPoint`: a fill, and a stroke for a
/// [stroke] color.
void _circles(
  UiCanvasContext ctx,
  void Function() mark, {
  required List<double> radii,
  required ui.Color fill,
  required Iterable<(double, double)> points,
  ui.Color? stroke,
}) {
  ctx.fillStyle = fill;
  if (stroke != null) {
    ctx
      ..strokeStyle = stroke
      ..lineWidth = 1;
  }
  var i = 0;
  for (final (x, y) in points) {
    ctx
      ..beginPath()
      ..arc(x, y, radii[i++ % radii.length], 0, _tau)
      ..closePath()
      ..fill();
    if (stroke != null) ctx.stroke();
    mark();
  }
}

/// [n] points on a grid inside the canvas, from [seed].
List<(double, double)> _points(int n, [int seed = 0]) {
  final r = math.Random(seed);
  return [
    for (var i = 0; i < n; i++)
      (8 + r.nextDouble() * 144, 8 + r.nextDouble() * 144),
  ];
}

const List<ui.Color> _palette = [_red, _blue, _green];

/// A random mix of runs, ordinary circles, other draws and state changes.
_Scenario _random(int seed) => (ctx, mark) {
  final r = math.Random(seed);
  ui.Color color() {
    final c = _palette[r.nextInt(_palette.length)];
    return r.nextInt(4) == 0 ? _copy(c) : c;
  }

  double radius() => switch (r.nextInt(6)) {
    0 => 1.5,
    1 => 3,
    2 => 4,
    3 => 2 + r.nextDouble() * 8,
    4 => 30,
    _ => 2.5,
  };
  var saved = 0;
  final steps = 4 + r.nextInt(8);
  for (var step = 0; step < steps; step++) {
    switch (r.nextInt(10)) {
      case 0 || 1 || 2 || 3:
        final count = switch (r.nextInt(5)) {
          0 => 1,
          1 => 700,
          _ => 1 + r.nextInt(90),
        };
        final points = _points(count, r.nextInt(1000));
        // A point that the batch does not take ends the run.
        if (r.nextInt(6) == 0) points.insert(r.nextInt(count), (1e9, 3));
        _run(
          ctx,
          mark,
          radius: radius(),
          fill: color(),
          stroke: r.nextBool() ? color() : null,
          width: r.nextBool() ? 1 : 2.5,
          points: points,
        );
      case 4 || 5:
        final kinds = 1 + r.nextInt(3);
        _circles(
          ctx,
          mark,
          radii: [
            for (var i = 0; i < kinds; i++)
              if (r.nextBool()) radius() else 3,
          ],
          fill: color(),
          stroke: r.nextInt(3) == 0 ? color() : null,
          points: _points(1 + r.nextInt(80), r.nextInt(1000)),
        );
      case 6:
        ctx.fillStyle = color();
        final rects = r.nextInt(300);
        for (var i = 0; i < rects; i++) {
          ctx.fillRect((i % 150).toDouble(), (i % 37).toDouble(), 0.75, 20);
        }
        mark();
      case 7:
        ctx
          ..save()
          ..beginPath()
          ..rect(5, 7, 120 + r.nextDouble() * 30, 140)
          ..clip();
        saved++;
        mark();
      case 8:
        if (saved > 0) {
          ctx.restore();
          saved--;
        } else {
          // A scale of one axis is no similarity: the runs decline.
          ctx.setTransform(
            r.nextBool() ? 2 : 1,
            0,
            0,
            1.0 + r.nextInt(2),
            0,
            0,
          );
          if (r.nextInt(3) == 0) ctx.setTransform(2, 0, 0, 2, 1.5, 0.25);
        }
        mark();
      case _:
        // A sector fill between runs.
        ctx
          ..fillStyle = color()
          ..beginPath()
          ..arc(80, 80, 30, 0, 1)
          ..lineTo(80, 80)
          ..closePath()
          ..fill();
        mark();
    }
  }
};

void main() {
  tearDown(() {
    UiCanvasContext.debugHoldCircleRuns = true;
    UiCanvasContext.debugRecordingCanvas = null;
  });

  group('a held run draws what a test of each circle draws', () {
    test('a run in the ladder mode, with a flush in its middle', () async {
      final observed = await _expectSame((ctx, mark) {
        // 70 fills with varying radii: the batch is in the ladder mode.
        _circles(
          ctx,
          mark,
          radii: [2, 3.5, 5.25, 7, 8.5, 9],
          fill: _blue,
          points: _points(70, 1),
        );
        // Its first 16 fills join the ladder. The 17th flushes the ladder,
        // in the middle of the run, and the rest hold.
        _run(ctx, mark, radius: 5, fill: _red, points: _points(60, 2));
      });
      final run = observed.held.sublist(70);
      expect(run.sublist(0, 16), everyElement(isFalse));
      expect(observed.steps[70 + 16].$1, 1, reason: 'the flush');
      expect(run.sublist(16), everyElement(isTrue));
    });

    test('a stroke flushes a short ladder in the first circle', () async {
      final observed = await _expectSame((ctx, mark) {
        _circles(
          ctx,
          mark,
          radii: [3, 4.5, 3.5, 6, 2.5],
          fill: _blue,
          points: _points(5, 3),
        );
        _run(
          ctx,
          mark,
          radius: 4,
          fill: _red,
          stroke: _blue,
          points: _points(40, 4),
        );
      });
      // The fill of the first circle went with the ladder: the second circle
      // takes the tests, and the run holds after it.
      expect(observed.held.sublist(5, 7), [isFalse, isTrue]);
      expect(observed.held.sublist(7), everyElement(isTrue));
    });

    test('direct circles at the end of the budget split the recording '
        'in the first circle', () async {
      final observed = await _expectSame((ctx, mark) {
        ctx.fillStyle = _green;
        for (var i = 0; i < 250; i++) {
          ctx.fillRect((i % 150).toDouble(), 3, 0.5, 30);
        }
        mark();
        _circles(ctx, mark, radii: [3], fill: _blue, points: _points(10, 5));
        _run(
          ctx,
          mark,
          radius: 4,
          fill: _red,
          stroke: _blue,
          points: _points(30, 6),
        );
      });
      expect(observed.steps[10].$2, 1);
      expect(observed.steps[11].$2, 2, reason: 'the split');
      expect(observed.held.last, isTrue);
    });

    test('a run in a batch of another color colors each instance', () async {
      final observed = await _expectSame((ctx, mark) {
        _circles(ctx, mark, radii: [3], fill: _blue, points: _points(10, 7));
        _run(
          ctx,
          mark,
          radius: 3,
          fill: _red,
          stroke: _green,
          points: _points(40, 8),
        );
      });
      expect(observed.held.last, isTrue);
      // No flush: one batch of 10 fills and 80 circles of the run.
      expect(observed.steps.last.$1, 90);
    });

    test('runs back to back: the same colors with another radius, and '
        'equal colors', () async {
      final observed = await _expectSame((ctx, mark) {
        _run(
          ctx,
          mark,
          radius: 3,
          fill: _red,
          stroke: _blue,
          points: _points(20, 9),
        );
        // The identical colors with another radius and width: the start ends
        // the held run.
        _run(
          ctx,
          mark,
          radius: 4,
          fill: _red,
          stroke: _blue,
          width: 2.5,
          points: _points(20, 10),
        );
        _run(
          ctx,
          mark,
          radius: 4,
          fill: _copy(_red),
          stroke: _copy(_blue),
          width: 2.5,
          points: _points(20, 11),
        );
        _run(ctx, mark, radius: 4, fill: _blue, points: _points(20, 12));
      });
      // The first circle of each run takes the tests, and the run holds after
      // it.
      expect(observed.held, everyElement(isTrue));
      expect(observed.steps[20].$1, 2, reason: 'the radius flushes');
      expect(observed.steps[40].$1, 42, reason: 'equal colors join');
    });

    test('a short held run that a ladder takes over', () async {
      final observed = await _expectSame((ctx, mark) {
        _run(ctx, mark, radius: 3, fill: _red, points: _points(5, 28));
        // Fills of other radii and colors: the 5 held fills join a ladder
        // with a color for each instance, which draws each circle directly.
        _circles(
          ctx,
          mark,
          radii: [5, 2.5, 7],
          fill: _blue,
          points: _points(20, 29),
        );
      });
      expect(observed.held.sublist(1, 5), everyElement(isTrue));
      expect(observed.steps.last.$1, 25);
    });

    test('a long run grows the batch and takes several atlas calls', () async {
      final observed = await _expectSame((ctx, mark) {
        _run(
          ctx,
          mark,
          radius: 2.5,
          fill: _red,
          stroke: _blue,
          points: _points(700, 13),
        );
      });
      expect(observed.steps.last.$1, 1400);
      expect(
        observed.calls.where((call) => call.contains('drawRawAtlas')),
        hasLength(3),
      );
    });

    test('a run under a scale and a clip', () async {
      await _expectSame((ctx, mark) {
        ctx
          ..save()
          ..beginPath()
          ..rect(10, 10, 60, 60)
          ..clip()
          ..setTransform(2, 0, 0, 2, 0, 0);
        _run(
          ctx,
          mark,
          radius: 3,
          fill: _green,
          stroke: _red,
          points: _points(50, 14).map((p) => (p.$1 / 2, p.$2 / 2)),
        );
        ctx.restore();
        mark();
        _run(ctx, mark, radius: 3, fill: _green, points: _points(20, 15));
      });
    });

    for (var seed = 0; seed < 160; seed++) {
      test('a random mix, seed $seed', () async {
        await _expectSame(_random(seed));
      });
    }
  });

  group('a change in a run takes the tests again', () {
    test('a new fill color', () async {
      final observed = await _expectSame((ctx, mark) {
        _run(
          ctx,
          mark,
          radius: 3,
          fill: _red,
          stroke: _blue,
          points: _points(20, 16),
        );
        ctx.fillStyle = _copy(_red);
        _more(ctx, mark, _points(20, 17));
        ctx.fillStyle = _green;
        _more(ctx, mark, _points(20, 18));
      });
      expect(observed.held, everyElement(isTrue));
    });

    test('a new stroke color', () async {
      await _expectSame((ctx, mark) {
        _run(
          ctx,
          mark,
          radius: 3,
          fill: _red,
          stroke: _blue,
          points: _points(20, 19),
        );
        ctx.strokeStyle = _green;
        _more(ctx, mark, _points(20, 20));
      });
    });

    test('a color that the batch does not keep', () async {
      final observed = await _expectSame((ctx, mark) {
        _run(
          ctx,
          mark,
          radius: 3,
          fill: _red,
          stroke: _blue,
          points: _points(20, 21),
        );
        ctx.fillStyle = _wideRed;
        _more(ctx, mark, _points(10, 22));
      });
      // The fills in the wide color draw nothing, as before: the run proved
      // the colors of its start.
      expect(observed.held.sublist(20), everyElement(isFalse));
    });

    test('an ordinary circle between two circles of a run', () async {
      final observed = await _expectSame((ctx, mark) {
        _run(ctx, mark, radius: 3, fill: _red, points: _points(20, 23));
        ctx
          ..beginPath()
          ..arc(40, 40, 3, 0, _tau)
          ..closePath()
          ..fill();
        mark();
        ctx
          ..beginPath()
          ..arc(50, 50, 6, 0, _tau)
          ..closePath()
          ..fill();
        mark();
        _more(ctx, mark, _points(20, 24));
      });
      // The ordinary fills end the held run, and the circle of another radius
      // flushes it. The run then joins a ladder for 16 circles and holds.
      expect(observed.held.sublist(20, 22), [isFalse, isFalse]);
      expect(observed.held.sublist(22, 38), everyElement(isFalse));
      expect(observed.held.sublist(38), everyElement(isTrue));
    });

    test('a draw between two circles of a run', () async {
      final observed = await _expectSame((ctx, mark) {
        _run(ctx, mark, radius: 3, fill: _red, points: _points(20, 25));
        ctx.fillRect(1, 1, 5, 5);
        mark();
        _more(ctx, mark, _points(20, 26));
      });
      expect(observed.held[20], isFalse);
      expect(observed.steps[20].$1, 0);
      expect(observed.held.last, isTrue);
    });
  });

  group('CircleBatch.hold', () {
    void fill(CircleBatch b, double r, ui.Color c) =>
        b.add(1, 2, r, c, stroke: false);
    void stroke(CircleBatch b, double r, ui.Color c, double w) =>
        b.add(1, 2, r, c, stroke: true, width: w);

    test('takes a run of one radius and its last colors', () {
      final b = CircleBatch();
      fill(b, 3, _red);
      stroke(b, 3, _blue, 1);
      expect(b.hold(3, _red, _blue, 1), isTrue);
      expect(b.holdsRun, isTrue);
      expect(b.addHeld(5, 6, _red, _blue), isTrue);
      expect(b.length, 4);
      expect(b.holdsRun, isTrue);
    });

    test('takes a run of fills after strokes of another color', () {
      final b = CircleBatch();
      stroke(b, 3, _blue, 1);
      fill(b, 3, _red);
      expect(b.hold(3, _red, null, 0), isTrue);
      expect(b.addHeld(5, 6, _red, null), isTrue);
      expect(b.addHeld(5, 6, _red, _blue), isFalse);
      expect(b.length, 3);
    });

    test('declines what accepts would not take with no change', () {
      final b = CircleBatch();
      expect(b.hold(3, _red, null, 0), isFalse, reason: 'empty');
      fill(b, 3, _red);
      expect(b.hold(4, _red, null, 0), isFalse, reason: 'radius');
      expect(b.hold(3, _copy(_red), null, 0), isFalse, reason: 'identity');
      expect(b.hold(3, _red, _blue, 1), isFalse, reason: 'no stroke yet');
      stroke(b, 3, _blue, 1);
      expect(b.hold(3, _red, _blue, 2), isFalse, reason: 'width');
      expect(b.hold(3, _red, _copy(_blue), 1), isFalse, reason: 'identity');
      expect(b.hold(3, _red, _blue, 1), isTrue);
      fill(b, 3, _red);
      expect(b.holdsRun, isFalse);
      expect(b.hold(3, _red, _blue, 1), isTrue);
      final varying = CircleBatch();
      fill(varying, 3, _red);
      fill(varying, 4, _red);
      expect(varying.hold(4, _red, null, 0), isFalse, reason: 'ladder');
    });

    test('add, flush, clear and release end it', () {
      final b = CircleBatch();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      for (final end in <void Function()>[
        () => fill(b, 3, _red),
        () => b.flush(canvas),
        b.clear,
        b.release,
      ]) {
        if (b.length == 0) fill(b, 3, _red);
        expect(b.hold(3, _red, null, 0), isTrue);
        end();
        expect(b.holdsRun, isFalse);
        expect(b.addHeld(5, 6, _red, null), isFalse);
      }
      recorder.endRecording().dispose();
    });

    test('a held run flushes what accepts and add give', () {
      for (final colored in [false, true]) {
        for (final withStroke in [false, true]) {
          final logs = <List<String>>[];
          for (final held in [false, true]) {
            final b = CircleBatch();
            // A circle of another color below the atlas run colors each
            // instance.
            if (colored) fill(b, 3, _green);
            var holding = false;
            for (final (x, y) in _points(300, 27)) {
              final strokeColor = withStroke ? _blue : null;
              if (holding && b.addHeld(x, y, _red, strokeColor)) continue;
              expect(b.accepts(3, _red, stroke: false), isTrue);
              b.add(x, y, 3, _red, stroke: false);
              if (strokeColor != null) {
                expect(
                  b.accepts(3, strokeColor, stroke: true, width: 1.5),
                  isTrue,
                );
                b.add(x, y, 3, strokeColor, stroke: true, width: 1.5);
              }
              holding = held && b.hold(3, _red, strokeColor, 1.5);
            }
            final log = <String>[];
            b.flush(_LogCanvas(log, ui.PictureRecorder()));
            logs.add(log);
          }
          expect(logs[1], logs[0], reason: 'colored $colored');
          expect(logs[0], isNotEmpty);
        }
      }
    });
  });
}
