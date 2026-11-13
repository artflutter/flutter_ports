// Original code, not ported from Chart.js: the guards of the clearStacks walk.
@TestOn('vm')
library;

// Chart.js ADR 0096: `clearStacks` skips its walk over a native List of typed
// data items while no item holds stacks. The state "no item holds stacks" is
// of the isolate: a file has its own isolate, and no other test of this file
// makes a stacked chart of typed items. Thus the first group runs in that
// state, in each shard.

import 'dart:collection';

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as typed;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show axisStackOf, stacksOf;
import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show nativeDataUpdateList;
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_test/flutter_test.dart';

/// A custom List of data points: its iterator is user code.
final class _CountingPoints(final List<typed.DataPoint> points)
    extends ListBase<typed.DataPoint> {
  int walks = 0;
  @override
  int get length => points.length;
  @override
  set length(int value) => points.length = value;
  @override
  typed.DataPoint operator [](int index) => points[index];
  @override
  void operator []=(int index, typed.DataPoint value) => points[index] = value;
  @override
  Iterator<typed.DataPoint> get iterator {
    walks++;
    return super.iterator;
  }
}

Chart _chart(
  List<Object?> first, {
  List<Object?>? second,
  bool stacked = false,
}) {
  final canvas = UiCanvasElement(width: 320, height: 200);
  final chart = Chart(canvas, <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{'data': first},
        if (second != null) <String, Object?>{'data': second},
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'animation': false,
      'parsing': false,
      'plugins': <String, Object?>{
        'legend': false,
        'tooltip': false,
        'colors': false,
        'filler': false,
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{'type': 'linear'},
        'y': <String, Object?>{'type': 'linear', 'stacked': stacked},
      },
    },
  });
  addTearDown(() {
    chart.destroy();
    canvas.getContext2d().dispose();
  });
  return chart;
}

List<typed.DataPoint> _points() => [
  typed.DataPoint(1, 2),
  typed.DataPoint(2, 3),
];

DatasetController _controllerOf(Chart chart) =>
    chart.getDatasetMeta(0).controller!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The first lowering registers the List classes of the typed points.
  ChartConfigLowering(
    typed.ChartConfig(
      type: typed.ChartKind.line,
      datasets: [typed.LineDataset(points: _points())],
    ),
  ).lower();

  // A change of the index runs `clearStacks` (core.datasetController.js:292).
  group('no item holds stacks', () {
    test('a custom List of points keeps the walk', () {
      final data = _CountingPoints(_points());
      final controller = _controllerOf(_chart(data));
      expect(nativeDataUpdateList(data), isFalse);
      final walks = data.walks;
      controller.updateIndex(1);
      expect(data.walks, walks + 1);
      controller.updateIndex(0);
    });

    test('a native List of points has no stacks to clear', () {
      final points = _points();
      final controller = _controllerOf(_chart(points));
      expect(nativeDataUpdateList(points), isTrue);
      controller.updateIndex(1);
      expect(stacksOf(points[0]), isNull);
      controller.updateIndex(0);
    });
  });

  group('a stacked chart of typed items', () {
    test('the walk clears the values of each later List', () {
      // The first stacked chart in this isolate ends the skip of the walk.
      final first = _points();
      final second = _points();
      final controller = _controllerOf(
        _chart(first, second: second, stacked: true),
      );
      final entry =
          axisStackOf(stacksOf(first[0]), const YAxis())! as StackEntry;
      expect(entry.datasetValues.hasIndex(0), isTrue);
      controller.updateIndex(5);
      expect(entry.datasetValues.hasIndex(0), isFalse);
      expect(entry.datasetValues.hasIndex(1), isTrue);
      controller.updateIndex(0);

      // Points of another chart hold no stacks: the walk finds nothing.
      final other = _points();
      final walked = _CountingPoints(other);
      final plain = _controllerOf(_chart(walked));
      final walks = walked.walks;
      plain.updateIndex(1);
      expect(walked.walks, walks + 1);
      expect(stacksOf(other[0]), isNull);
      plain.updateIndex(0);
    });
  });
}
