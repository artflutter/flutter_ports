// Original code, not ported from Chart.js: merged curves of a dense line.
@TestOn('vm')
library;

// The twins of Chart.js ADR 0114: a line chart with the merge of the narrow
// curves off against on. Below the threshold the bytes are the same. Above
// it, each pixel that differs is on the line or next to it, and the count has
// a bound. Each guard keeps the commands of upstream.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
import 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show
        BezierCurveToCommand,
        CanvasRenderingContext2D,
        LineToCommand,
        MoveToCommand,
        Path2D,
        PathCommand;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/line_dense_curve.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart'
    show MonotoneCubicInterpolationMode;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_chartjs_port/src/typed/typed.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_test/flutter_test.dart';

const _blue = ui.Color(0xff4f6bed);
const _green = ui.Color(0xff2e7d32);
const _fill = ui.Color(0x264f6bed);
const _grid = ui.Color(0xffe5e9f1);

/// A chart size: a name, the logical width and height, and the pixel ratio.
typedef _Size = (String, int, int, double);

/// The chart of the benchmark lab on a desktop, and on a phone.
const _Size _mac = ('mac', 1004, 420, 2);
const _Size _phone = ('phone', 351, 300, 2.625);

/// The y values of `DatasetGenerator.frame(0)` of the benchmark lab.
List<double> _ys(int count, int seed) {
  var state = seed & 0x7fffffff;
  return List<double>.generate(count, (i) {
    state = (state * 1664525 + 1013904223) & 0x7fffffff;
    final phase = state / 0x80000000 * math.pi * 2;
    final x = count == 1 ? 50.0 : i * 100 / (count - 1);
    return 50 + 26 * math.sin(x * .075) + 12 * math.sin(phase);
  }, growable: false);
}

/// The line chart of the benchmark lab with tick labels and a grid.
///
/// [variant] changes one thing: `base`, `markers`, `fill`, `markersFill`,
/// `monotone`, `gaps`, `spanGaps`, `horizontal`, `fillTo` (a second line that
/// fills to the first), `segment` (segment colors from a function),
/// `noBorder` (a fill with `borderWidth: 0`), `dash`, or `anim` (the values
/// at the fraction [t] between two data sets).
ChartConfig _config(int count, String variant, double ratio, [double t = 0]) {
  const grid = AxisGrid(color: _grid, drawTicks: false);
  const ticks = AxisTicks(
    stepSize: 25,
    font: TextStyle(fontSize: 10),
    maxRotation: 0,
    autoSkip: true,
    extra: {'maxTicksLimit': 5},
  );
  final a = _ys(count, 7);
  final b = variant == 'anim' ? _ys(count, 8) : a;
  final block = math.max(1, count ~/ 40);
  final gaps = variant == 'gaps' || variant == 'spanGaps';
  final horizontal = variant == 'horizontal';
  final markers = variant == 'markers' || variant == 'markersFill';
  final filled =
      variant == 'fill' || variant == 'markersFill' || variant == 'noBorder';
  double x(int i) => count == 1 ? 50.0 : i * 100 / (count - 1);
  double? y(int i) =>
      gaps && (i ~/ block) % 10 == 3 ? null : a[i] + (b[i] - a[i]) * t;
  final points = List<DataPoint>.generate(
    count,
    (i) => horizontal ? DataPoint(y(i)!, x(i)) : DataPoint(x(i), y(i)),
    growable: false,
  );
  LineDataset line(
    String key,
    List<DataPoint> points, {
    ChartFill fill = ChartFill.none,
    Map<String, Object?>? extra,
  }) => LineDataset(
    key: ValueKey(key),
    label: key,
    points: points,
    borderColor: const ChartValue.constant(_blue),
    borderWidth: variant == 'noBorder' ? 0 : 2,
    borderDash: variant == 'dash' ? const [6, 3] : null,
    backgroundColor: const ChartValue.constant(_fill),
    pointBackgroundColor: _blue,
    pointBorderWidth: 0,
    pointRadius: markers ? 3 : 0,
    pointHoverRadius: 3,
    tension: .35,
    fill: fill,
    spanGaps: variant == 'spanGaps' ? true : null,
    extra: extra,
  );
  final eighth = math.max(1, count ~/ 8);
  final datasets = switch (variant) {
    'monotone' => [
      line(
        'a',
        points,
        extra: {
          'cubicInterpolationMode': const MonotoneCubicInterpolationMode(),
        },
      ),
    ],
    'fillTo' => [
      line('a', points),
      line('b', [
        for (var i = 0; i < count; i++) DataPoint(x(i), a[i] + 8),
      ], fill: ChartFill.relative(-1)),
    ],
    'segment' => [
      line(
        'a',
        points,
        extra: {
          'segment': <String, Object?>{
            'borderColor': (Object? ctx) {
              final i = jsGet(ctx, 'p0DataIndex');
              return i is num && (i ~/ eighth).isOdd ? _green : undefined;
            },
          },
        },
      ),
    ],
    _ => [line('a', points, fill: filled ? ChartFill.origin : ChartFill.none)],
  };
  return ChartConfig(
    type: ChartKind.line,
    datasets: datasets,
    indexAxis: horizontal ? const YAxis() : null,
    scales: const {
      'x': LinearAxis(min: 0, max: 100, grid: grid, ticks: ticks),
      'y': LinearAxis(min: 0, max: 110, grid: grid, ticks: ticks),
    },
    animation: ChartAnimation.none,
    legend: const ChartLegend(display: false),
    tooltip: const ChartTooltip(enabled: false),
    responsive: false,
    maintainAspectRatio: false,
    padding: EdgeInsets.zero,
    extra: {
      'parsing': false,
      'devicePixelRatio': ratio,
      'events': const <String>[],
    },
  );
}

typedef _Shot = ({Uint8List bytes, int width, int height, int merged});

Future<Uint8List> _read(WidgetTester tester, UiCanvasElement canvas) async {
  final w = canvas.width;
  final h = canvas.height;
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder)
    ..drawRect(
      ui.Rect.fromLTWH(0, 0, w * 1.0, h * 1.0),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
  canvas.getContext2d().paint(c, ui.Offset.zero, 1, 1);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(w, h);
  try {
    final data = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
    ))!;
    return Uint8List.fromList(data.buffer.asUint8List());
  } finally {
    image.dispose();
    picture.dispose();
  }
}

/// Draws the chart with the merge [on] or off and gives its bitmap and the
/// count of the curves that went out as lines.
Future<_Shot> _shot(
  WidgetTester tester,
  _Size size,
  int count,
  String variant, {
  required bool on,
  double t = 0,
}) async {
  final (_, width, height, ratio) = size;
  denseCurveMergeEnabled = on;
  denseCurvesMerged = 0;
  final canvas = UiCanvasElement(width: width, height: height);
  final chart = Chart(
    canvas,
    ChartConfigLowering(_config(count, variant, ratio, t)).lower(),
  );
  final bytes = await _read(tester, canvas);
  final shot = (
    bytes: bytes,
    width: canvas.width,
    height: canvas.height,
    merged: denseCurvesMerged,
  );
  chart.destroy();
  canvas.getContext2d().dispose();
  denseCurveMergeEnabled = true;
  return shot;
}

/// The pixels of [shot] with the color of a line or of a marker (the grid and
/// the fill have a red above 200), grown by two pixels: the faint pixels of
/// an edge are one pixel past the last pixel with such a color.
Uint8List _band(_Shot shot) {
  final w = shot.width;
  final h = shot.height;
  final mask = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (shot.bytes[(y * w + x) * 4] >= 200) continue;
      for (var dy = -2; dy <= 2; dy++) {
        final yy = y + dy;
        if (yy < 0 || yy >= h) continue;
        for (var dx = -2; dx <= 2; dx++) {
          final xx = x + dx;
          if (xx >= 0 && xx < w) mask[yy * w + xx] = 1;
        }
      }
    }
  }
  return mask;
}

typedef _Diff = ({
  int differing,
  int largest,
  int above64,
  int outside,
  int band,
});

_Diff _compare(_Shot a, _Shot b, Uint8List band) {
  expect(b.bytes.length, a.bytes.length);
  var differing = 0;
  var largest = 0;
  var above64 = 0;
  var outside = 0;
  for (var p = 0, i = 0; i < a.bytes.length; p++, i += 4) {
    var worst = 0;
    for (var c = 0; c < 4; c++) {
      final d = (a.bytes[i + c] - b.bytes[i + c]).abs();
      if (d > worst) worst = d;
    }
    if (worst == 0) continue;
    differing++;
    if (worst > largest) largest = worst;
    if (worst > 64) above64++;
    if (band[p] == 0) outside++;
  }
  var pixels = 0;
  for (final v in band) {
    pixels += v;
  }
  return (
    differing: differing,
    largest: largest,
    above64: above64,
    outside: outside,
    band: pixels,
  );
}

class _UserLine extends LineElement {}

void main() {
  setUp(() => denseCurveMergeEnabled = true);
  tearDown(() {
    denseCurveMergeEnabled = true;
    UiCanvasContext.debugDrawLongPathsInPieces = false;
  });

  test('the switch is on unless the define turns it off', () {
    expect(
      denseCurveMergeEnabled,
      const bool.fromEnvironment(
        'CHARTJS_DENSE_CURVE_MERGE',
        defaultValue: true,
      ),
    );
    expect(denseCurveThreshold, .5);
  });

  testWidgets('below the threshold: the same bytes and no merged curve', (
    tester,
  ) async {
    // 2 points for each bitmap pixel start the merge: 3,881 points on the
    // desktop chart and 1,666 on the phone chart.
    for (final (size, counts) in const [
      (_mac, [500, 2000]),
      (_phone, [500, 1000]),
    ]) {
      for (final count in counts) {
        for (final variant in const ['base', 'markersFill', 'monotone']) {
          final off = await _shot(tester, size, count, variant, on: false);
          final on = await _shot(tester, size, count, variant, on: true);
          final reason = '${size.$1} $count $variant';
          expect(on.merged, 0, reason: reason);
          expect(on.bytes, off.bytes, reason: reason);
        }
      }
    }
  });

  testWidgets('the merged path keeps the ends and the extremes', (
    tester,
  ) async {
    final (_, width, height, ratio) = _mac;
    Future<List<PathCommand>> commands(int count, {required bool on}) async {
      denseCurveMergeEnabled = on;
      final canvas = UiCanvasElement(width: width, height: height);
      final chart = Chart(
        canvas,
        ChartConfigLowering(_config(count, 'base', ratio)).lower(),
      );
      final line = chart.getDatasetMeta(0).dataset! as LineElement;
      final list = List.of((line['_path']! as Path2D).commands);
      chart.destroy();
      canvas.getContext2d().dispose();
      denseCurveMergeEnabled = true;
      return list;
    }

    // The y range of a path: each curve by 64 samples.
    (double, double) range(List<PathCommand> list) {
      var lo = double.infinity;
      var hi = double.negativeInfinity;
      var py = 0.0;
      void at(double y) {
        lo = math.min(lo, y);
        hi = math.max(hi, y);
      }

      for (final command in list) {
        switch (command) {
          case MoveToCommand(:final y) || LineToCommand(:final y):
            at(y);
            py = y;
          case final BezierCurveToCommand c:
            for (var k = 1; k <= 64; k++) {
              final t = k / 64;
              final m = 1 - t;
              at(
                m * m * m * py +
                    3 * m * m * t * c.cp1y +
                    3 * m * t * t * c.cp2y +
                    t * t * t * c.y,
              );
            }
            py = c.y;
          default:
            fail('an unknown command: $command');
        }
      }
      return (lo, hi);
    }

    final off = await commands(20000, on: false);
    final on = await commands(20000, on: true);
    expect(off.length, 20000);
    expect(off.whereType<BezierCurveToCommand>().length, 19999);
    // The first and the last curve stay: the caps follow their tangents.
    expect(on.whereType<BezierCurveToCommand>().length, 2);
    expect(on[1], isA<BezierCurveToCommand>());
    expect(on.last, isA<BezierCurveToCommand>());
    final firstOff = off.first as MoveToCommand;
    final firstOn = on.first as MoveToCommand;
    expect((firstOn.x, firstOn.y), (firstOff.x, firstOff.y));
    final lastOff = off.last as BezierCurveToCommand;
    final lastOn = on.last as BezierCurveToCommand;
    expect((lastOn.x, lastOn.y), (lastOff.x, lastOff.y));
    // At most 4 vertices for each bitmap pixel column, and never more
    // commands than the curves.
    final area = lastOff.x - firstOff.x;
    expect(on.length, lessThanOrEqualTo(4 * (area * ratio).ceil() + 8));
    expect(on.length, lessThan(off.length));
    // The x of the path never goes back by more than the threshold.
    var px = firstOn.x;
    for (final command in on.skip(1)) {
      final x = switch (command) {
        LineToCommand(:final x) => x,
        BezierCurveToCommand(:final x) => x,
        _ => fail('an unknown command: $command'),
      };
      expect(x, greaterThanOrEqualTo(px - denseCurveThreshold / ratio));
      px = x;
    }
    // A peak keeps its height: the samples of the curves are below the exact
    // extremes by less than a hundredth of a pixel.
    final (offLo, offHi) = range(off);
    final (onLo, onHi) = range(on);
    expect(onLo, closeTo(offLo, .01));
    expect(onHi, closeTo(offHi, .01));
    expect(onLo, lessThanOrEqualTo(offLo));
    expect(onHi, greaterThanOrEqualTo(offHi));
  });

  // The bounds come from the tables of Chart.js ADR 0114: the largest share
  // of the band is 5.3% (the monotone mode at 5,000 points on the desktop
  // chart), and the largest share above 64 of 255 is 0.4%.
  for (final size in const [_mac, _phone]) {
    for (final count in const [5000, 20000]) {
      testWidgets(
        'merged against the curves: ${size.$1}, $count points',
        (tester) async {
          for (final variant in const [
            'base',
            'markers',
            'fill',
            'markersFill',
            'monotone',
            'gaps',
            'spanGaps',
            'fillTo',
            'segment',
          ]) {
            final off = await _shot(tester, size, count, variant, on: false);
            final on = await _shot(tester, size, count, variant, on: true);
            final d = _compare(off, on, _band(off));
            final reason = '${size.$1} $count $variant: $d';
            expect(off.merged, 0, reason: reason);
            expect(on.merged, greaterThan(count ~/ 2), reason: reason);
            // Each pixel that differs is on a line or within 2 pixels of it.
            expect(d.outside, 0, reason: reason);
            expect(d.differing, lessThan(d.band * .08), reason: reason);
            expect(d.above64, lessThan(d.band * .006), reason: reason);
          }
        },
        timeout: const Timeout(Duration(minutes: 5)),
      );
    }
  }

  testWidgets('the merged curves in pieces, the form of the web', (
    tester,
  ) async {
    UiCanvasContext.debugDrawLongPathsInPieces = true;
    for (final variant in const ['base', 'markersFill']) {
      final off = await _shot(tester, _mac, 20000, variant, on: false);
      final on = await _shot(tester, _mac, 20000, variant, on: true);
      final d = _compare(off, on, _band(off));
      final reason = '$variant: $d';
      expect(on.merged, greaterThan(10000), reason: reason);
      expect(d.outside, 0, reason: reason);
      expect(d.differing, lessThan(d.band * .08), reason: reason);
      expect(d.above64, lessThan(d.band * .006), reason: reason);
    }
  });

  testWidgets('a line with no border keeps its curves: the same bytes', (
    tester,
  ) async {
    // The fill of a line with `borderWidth: 0` has no line over its edge.
    for (final pieces in const [false, true]) {
      UiCanvasContext.debugDrawLongPathsInPieces = pieces;
      for (final size in const [_mac, _phone]) {
        final off = await _shot(tester, size, 20000, 'noBorder', on: false);
        final on = await _shot(tester, size, 20000, 'noBorder', on: true);
        final reason = '${size.$1}, pieces $pieces';
        expect(on.merged, 0, reason: reason);
        expect(on.bytes, off.bytes, reason: reason);
      }
    }
  });

  testWidgets('a dashed line keeps its curves: the same bytes', (
    tester,
  ) async {
    final off = await _shot(tester, _phone, 20000, 'dash', on: false);
    final on = await _shot(tester, _phone, 20000, 'dash', on: true);
    expect(on.merged, 0);
    expect(on.bytes, off.bytes);
  });

  testWidgets('a horizontal chart is drawn, and almost does not change', (
    tester,
  ) async {
    // The test of a narrow curve reads x. The x of a horizontal chart is the
    // value, so only a curve between two near values merges.
    final off = await _shot(tester, _mac, 20000, 'horizontal', on: false);
    final on = await _shot(tester, _mac, 20000, 'horizontal', on: true);
    final d = _compare(off, on, _band(off));
    expect(d.outside, 0, reason: '$d');
    expect(d.differing, lessThan(d.band * .002), reason: '$d');
  });

  testWidgets('each guard of the context and of the line', (tester) async {
    final (_, width, height, ratio) = _mac;
    final canvas = UiCanvasElement(width: width, height: height);
    final chart = Chart(
      canvas,
      ChartConfigLowering(_config(20000, 'base', ratio)).lower(),
    );
    final line = chart.getDatasetMeta(0).dataset! as LineElement;
    final other = UiCanvasElement(width: canvas.width, height: canvas.height);

    // The count of the merged curves of one draw of [target] on a context
    // that [prepare] changed.
    int merged(
      LineElement target, [
      void Function(CanvasRenderingContext2D ctx)? prepare,
    ]) {
      final ctx = other.getContext2d()
        ..save()
        ..setTransform(ratio, 0, 0, ratio, 0, 0);
      prepare?.call(ctx);
      target['_path'] = undefined;
      denseCurvesMerged = 0;
      target.draw(ctx, chart.chartArea);
      ctx.restore();
      return denseCurvesMerged;
    }

    expect(merged(line), greaterThan(10000));

    // A context that is not the native one gets the commands of upstream.
    final recorded = Path2D();
    denseCurvesMerged = 0;
    line.path(recorded);
    expect(denseCurvesMerged, 0);
    expect(recorded.commands.whereType<BezierCurveToCommand>().length, 19999);

    // The cached path of a native draw does not reach another context.
    expect(merged(line), greaterThan(10000));
    final again = Path2D();
    line.path(again);
    expect(again.commands.whereType<BezierCurveToCommand>().length, 19999);

    // A rotation, a skew and a shadow.
    expect(merged(line, (ctx) => ctx.rotate(.1)), 0);
    expect(merged(line, (ctx) => ctx.transform(1, 0, .2, 1, 0, 0)), 0);
    expect(
      merged(
        line,
        (ctx) => ctx
          ..shadowColor = const ui.Color(0x80000000)
          ..shadowBlur = 4,
      ),
      0,
    );

    // A decimated line and a loop.
    line['_decimated'] = true;
    expect(merged(line), 0);
    line['_decimated'] = false;
    line['_loop'] = true;
    expect(merged(line), 0);
    line['_loop'] = false;
    expect(merged(line), greaterThan(10000));

    // A subclass of the line of user code.
    final user = _UserLine()
      ..options = line.options
      ..points = line.points;
    expect(merged(user), 0);

    // The switch.
    denseCurveMergeEnabled = false;
    expect(merged(line), 0);
    denseCurveMergeEnabled = true;

    line['_path'] = undefined;
    chart.destroy();
    canvas.getContext2d().dispose();
    other.getContext2d().dispose();
  });

  testWidgets('two frames of an animation: no more pixels change', (
    tester,
  ) async {
    // Two frames 1% of an animation apart. A merge that takes other points
    // in each frame would change more pixels from one frame to the next than
    // the curves do.
    for (final (size, count) in const [(_mac, 5000), (_phone, 20000)]) {
      for (final t in const [.1, .5, .9]) {
        final off1 = await _shot(tester, size, count, 'anim', on: false, t: t);
        final off2 = await _shot(
          tester,
          size,
          count,
          'anim',
          on: false,
          t: t + .01,
        );
        final on1 = await _shot(tester, size, count, 'anim', on: true, t: t);
        final on2 = await _shot(
          tester,
          size,
          count,
          'anim',
          on: true,
          t: t + .01,
        );
        final band = _band(off1);
        final curves = _compare(off1, off2, band).differing;
        final lines = _compare(on1, on2, band).differing;
        expect(
          lines,
          lessThan(curves * 1.1),
          reason: '${size.$1} $count at $t: $lines against $curves',
        );
      }
    }
  });
}
