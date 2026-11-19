// Original code, not ported from Chart.js: draw recorders of the elements.

/// Test doubles that record the draws of the elements of a chart.
///
/// A Dart object cannot replace one of its methods. Thus a recorder is a
/// subclass of the element class that takes the slot that the dataset
/// controller reads: `meta.data[index]` ([recordElementDraws]),
/// `meta.dataset` ([recordLineCalls]), or the listeners of a data array
/// ([recordArrayCalls]). Each recorder copies the typed fields of the
/// element and adds each call to a typed `List`.
///
/// ```dart
/// final draws = recordElementDraws(meta, 0);
/// chart.draw();
/// expect(draws, hasLength(1));
/// expect(draws.single.ctx, same(chart.ctx));
/// ```
///
/// An element with a running animation throws a [StateError]: the animation
/// moves the original element, not the recorder. Use `animation: false`
/// (the default of `acquireChart`) or wait for the end of the animations.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

/// One call of `draw` of an element.
typedef ElementDraw = ({
  IElement element,
  CanvasRenderingContext2D ctx,
  ChartArea? area,
});

/// One call of `draw` of a line.
typedef LineDraw = ({
  LineElement line,
  CanvasRenderingContext2D ctx,
  ChartArea? area,
  int? start,
  int? count,
});

/// One call of `updateControlPoints` of a line.
typedef ControlPointsUpdate = ({ChartArea? chartArea, ScaleAxis? indexAxis});

/// One call of `onDataSplice` of an array listener.
typedef DataSplice = ({int index, int deleteCount, List<Object?> items});

void _copyBase(Element from, Element to) {
  final running = [
    for (final MapEntry(:key, :value) in (from.$animations ?? const {}).entries)
      if (value.active()) key,
  ];
  if (running.isNotEmpty) {
    throw StateError(
      'A draw recorder of an element with running animations of $running: '
      'the animations move the original element, not the recorder.',
    );
  }
  to
    ..active = from.active
    ..options = from.options
    ..hidden = from.hidden
    ..$animations = from.$animations;
  if (!from.x.isNaN) to.x = from.x;
  if (!from.y.isNaN) to.y = from.y;
}

final class _PointRecorder(PointElement of, {required final bool drawThrough})
    extends PointElement {
  this {
    _copyBase(of, this);
    if (of.parsed case final v?) parsed = v;
    if (of.skip case final v?) skip = v;
    if (of.stop case final v?) stop = v;
    if (!of.cp1x.isNaN) cp1x = of.cp1x;
    if (!of.cp1y.isNaN) cp1y = of.cp1y;
    if (!of.cp2x.isNaN) cp2x = of.cp2x;
    if (!of.cp2y.isNaN) cp2y = of.cp2y;
    if (of.angle case final v?) angle = v;
  }

  final List<ElementDraw> draws = [];

  @override
  void draw(CanvasRenderingContext2D ctx, [ChartArea? area]) {
    draws.add((element: this, ctx: ctx, area: area));
    if (drawThrough) super.draw(ctx, area);
  }
}

final class _BarRecorder(BarElement of, {required final bool drawThrough})
    extends BarElement {
  this {
    _copyBase(of, this);
    if (of.horizontal case final v?) horizontal = v;
    if (!of.base.isNaN) base = of.base;
    if (!of.width.isNaN) width = of.width;
    if (!of.height.isNaN) height = of.height;
    if (!of.inflateAmount.isNaN) inflateAmount = of.inflateAmount;
    if (of.borderSkipped case final v?) borderSkipped = v;
    if (of.enableBorderRadius case final v?) enableBorderRadius = v;
  }

  final List<ElementDraw> draws = [];

  @override
  void draw(CanvasRenderingContext2D ctx, [ChartArea? area]) {
    draws.add((element: this, ctx: ctx, area: area));
    if (drawThrough) super.draw(ctx, area);
  }
}

final class _ArcRecorder(ArcElement of, {required final bool drawThrough})
    extends ArcElement {
  this {
    _copyBase(of, this);
    if (!of.circumference.isNaN) circumference = of.circumference;
    if (!of.endAngle.isNaN) endAngle = of.endAngle;
    if (!of.fullCircles.isNaN) fullCircles = of.fullCircles;
    if (!of.innerRadius.isNaN) innerRadius = of.innerRadius;
    if (!of.outerRadius.isNaN) outerRadius = of.outerRadius;
    if (!of.pixelMargin.isNaN) pixelMargin = of.pixelMargin;
    if (!of.startAngle.isNaN) startAngle = of.startAngle;
    if (of.circular case final v?) circular = v;
  }

  final List<ElementDraw> draws = [];

  @override
  void draw(CanvasRenderingContext2D ctx, [ChartArea? area]) {
    draws.add((element: this, ctx: ctx, area: area));
    if (drawThrough) super.draw(ctx, area);
  }
}

final class _LineRecorder(LineElement of, {required final bool callThrough})
    extends LineElement {
  this {
    _copyBase(of, this);
    if (of.chart case final v?) chart = v;
    if (of.datasetIndex case final v?) datasetIndex = v;
    if (of.loop case final v?) loop = v;
    if (of.fullLoop case final v?) fullLoop = v;
    decimated = of.decimated;
    points = of.points;
  }

  final List<LineDraw> draws = [];

  final List<ControlPointsUpdate> updates = [];

  @override
  void draw(
    CanvasRenderingContext2D ctx, [
    ChartArea? area,
    int? start,
    int? count,
  ]) {
    draws.add((line: this, ctx: ctx, area: area, start: start, count: count));
    if (callThrough) super.draw(ctx, area, start, count);
  }

  @override
  void updateControlPoints(ChartArea? chartArea, [ScaleAxis? indexAxis]) {
    updates.add((chartArea: chartArea, indexAxis: indexAxis));
    if (callThrough) super.updateControlPoints(chartArea, indexAxis);
  }
}

/// Puts a recorder of the class of `meta.data[index]` into that slot and
/// returns the list of its draws. With [drawThrough], each draw also draws
/// the element. The element must be a [PointElement], a [BarElement] or an
/// [ArcElement].
List<ElementDraw> recordElementDraws(
  ChartMeta meta,
  int index, {
  bool drawThrough = false,
}) {
  switch (meta.data[index]) {
    case final PointElement point:
      final recorder = _PointRecorder(point, drawThrough: drawThrough);
      meta.data[index] = recorder;
      return recorder.draws;
    case final BarElement bar:
      final recorder = _BarRecorder(bar, drawThrough: drawThrough);
      meta.data[index] = recorder;
      return recorder.draws;
    case final ArcElement arc:
      final recorder = _ArcRecorder(arc, drawThrough: drawThrough);
      meta.data[index] = recorder;
      return recorder.draws;
    case final other:
      throw ArgumentError.value(other, 'meta.data[$index]', 'No recorder');
  }
}

/// Puts a line recorder into `meta.dataset` and returns the lists of its
/// draws and of its control point updates. With [callThrough], each call
/// also runs the method of the line.
({List<LineDraw> draws, List<ControlPointsUpdate> updates}) recordLineCalls(
  ChartMeta meta, {
  bool callThrough = false,
}) {
  final line = meta.dataset;
  if (line is! LineElement) {
    throw ArgumentError.value(line, 'meta.dataset', 'Not a line element');
  }
  final recorder = _LineRecorder(line, callThrough: callThrough);
  meta.dataset = recorder;
  return (draws: recorder.draws, updates: recorder.updates);
}

/// The calls that [recordArrayCalls] records, one list for each method of
/// [ArrayListener].
final class ArrayCalls() {
  /// The items of each `onDataPush`.
  final List<List<Object?>> pushes = [];

  /// The number of `onDataPop` calls.
  int pops = 0;

  /// The number of `onDataShift` calls.
  int shifts = 0;

  /// Each `onDataSplice`.
  final List<DataSplice> splices = [];

  /// The items of each `onDataUnshift`.
  final List<List<Object?>> unshifts = [];
}

final class _ArrayRecorder(
  final ArrayListener<Object?> _of,
  final ArrayCalls _calls, {
  required final bool callThrough,
}) with ArrayListener<Object?> {
  @override
  void onDataPush(List<Object?> items) {
    _calls.pushes.add(items);
    if (callThrough) _of.onDataPush(items);
  }

  @override
  void onDataPop() {
    _calls.pops++;
    if (callThrough) _of.onDataPop();
  }

  @override
  void onDataShift() {
    _calls.shifts++;
    if (callThrough) _of.onDataShift();
  }

  @override
  void onDataSplice(int index, int deleteCount, List<Object?> items) {
    _calls.splices.add((index: index, deleteCount: deleteCount, items: items));
    if (callThrough) _of.onDataSplice(index, deleteCount, items);
  }

  @override
  void onDataUnshift(List<Object?> items) {
    _calls.unshifts.add(items);
    if (callThrough) _of.onDataUnshift(items);
  }
}

/// Puts a recorder in the place of [listener] in the listeners of [data]
/// and returns its calls. `addTearDown` puts [listener] back. With
/// [callThrough], each call also goes to [listener].
ArrayCalls recordArrayCalls(
  List<Object?> data,
  ArrayListener<Object?> listener, {
  bool callThrough = false,
}) {
  final calls = ArrayCalls();
  final recorder = _ArrayRecorder(listener, calls, callThrough: callThrough);
  unlistenArrayEvents(data, listener);
  listenArrayEvents(data, recorder);
  addTearDown(() {
    unlistenArrayEvents(data, recorder);
    listenArrayEvents(data, listener);
  });
  return calls;
}
