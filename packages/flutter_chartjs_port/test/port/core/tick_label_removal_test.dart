// Original code, not ported from Chart.js: the ticks with no label go.
@TestOn('vm')
library;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_test/flutter_test.dart';

/// The state of the x scale of [_chart] at `afterTickToLabelConversion`.
final class _Seen() {
  /// The ticks that `afterBuildTicks` gave the scale.
  late List<Tick> built;

  /// A copy of [built] at that time.
  late List<Tick> all;

  /// Whether the list of the scale at the hook is [built] itself.
  bool sameList = false;

  /// A copy of the ticks of the scale at the hook.
  List<Tick> kept = const [];

  /// The count of calls of the hook.
  int calls = 0;
}

/// A line chart whose x scale gets [count] ticks with the values 0 to
/// [count] - 1 in `afterBuildTicks`. The tick callback gives no label to a
/// value that [keep] rejects.
Chart _chart(
  int count,
  bool Function(int value) keep,
  _Seen seen, {
  int? sampleSize,
}) {
  final canvas = UiCanvasElement(width: 600, height: 300);
  final config = ChartConfig(
    type: ChartKind.line,
    datasets: [
      LineDataset(points: [DataPoint(0, 1), DataPoint(count - 1, 2)]),
    ],
    responsive: false,
    animation: ChartAnimation.none,
    scales: {
      'x': LinearAxis(
        min: 0,
        max: count - 1.0,
        ticks: AxisTicks(
          callback: (scale, value, index, ticks) =>
              keep(value.toInt()) ? ['$value'] : null,
          extra: {'sampleSize': ?sampleSize},
        ),
        extra: {
          'afterBuildTicks': (Scale scale) {
            seen
              ..built = [
                for (var i = 0; i < count; i++) Tick(value: i.toDouble()),
              ]
              ..all = [...seen.built];
            scale.ticks = seen.built;
          },
          'afterTickToLabelConversion': (Scale scale) {
            seen
              ..calls += 1
              ..sameList = identical(scale.ticks, seen.built)
              ..kept = [...scale.ticks!];
          },
        },
      ),
      'y': const LinearAxis(),
    },
    extra: const {
      'events': <String>[],
      'plugins': {'legend': false, 'tooltip': false},
    },
  );
  final chart = Chart(canvas, ChartConfigLowering(config).lower());
  addTearDown(chart.destroy);
  return chart;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // core.scale.js:780-788 removes each tick whose callback gave null with
  // one splice. The port moves the kept ticks down in one pass (row
  // adapt-tick-label-removal): the same list, the same ticks, the same
  // order.
  final cases = <(String, int, bool Function(int))>[
    ('no tick', 300, (value) => false),
    ('each tick', 300, (value) => true),
    ('each third tick', 300, (value) => value % 3 == 0),
    ('the first tick only', 300, (value) => value == 0),
    ('the last tick only', 300, (value) => value == 299),
    ('runs of kept and removed ticks', 300, (value) => (value ~/ 7).isEven),
    ('a scattered set', 300, (value) => (value * 2654435761) % 11 < 4),
    ('one tick of 30,000', 30000, (value) => value % 5000 == 0),
  ];
  for (final (name, count, keep) in cases) {
    test('the scale keeps $name with a label, in the list of the scale', () {
      final seen = _Seen();
      _chart(count, keep, seen);

      expect(seen.calls, 1);
      expect(seen.sameList, isTrue, reason: 'the loop changes the list');
      final expected = [
        for (final tick in seen.all)
          if (keep(tick.value.toInt())) tick,
      ];
      expect(seen.kept, hasLength(expected.length));
      for (var i = 0; i < expected.length; i++) {
        expect(
          identical(seen.kept[i], expected[i]),
          isTrue,
          reason: 'the tick ${expected[i].value} at $i',
        );
      }
      expect(seen.built, hasLength(expected.length));
    });
  }

  test('a sample of the ticks keeps the list of the scale whole', () {
    // core.scale.js:446-447: with `sampleSize`, the first conversion gets a
    // sample, a new list, and the removal changes that list only.
    final seen = _Seen();
    final chart = _chart(300, (value) => value.isEven, seen, sampleSize: 10);

    expect(seen.calls, 2, reason: 'the sample, then the ticks after the skip');
    for (final tick in chart.scales['x']!.ticks!) {
      expect(tick.label, isNotNull);
      expect(tick.value.toInt().isEven, isTrue);
    }
  });
}
