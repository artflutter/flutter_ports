import 'dart:math' as math;

/// The radius of a bubble with the value [y], in logical pixels: 2 at 0 and 8
/// at 100.
double bubbleRadius(double y) => 2 + y * .06;

/// An immutable input value shared by every adapter.
class const Sample(
  /// Stable item identity.
  final int index,

  /// Numeric domain position, sorted for line charts.
  final double x,

  /// Positive value in the fixed 0–100 range.
  final double y,
) {
  /// One item in the deterministic workload.
  this;

  /// Bubble radius in logical pixels, computed only by a bubble chart.
  double get r => bubbleRadius(y);
}

/// One flow of a sankey chart, from the node `from` to the node `to`.
typedef SankeyFlow = ({String from, String to, double flow});

/// The flows of a sankey chart for [values]: one flow for each item, with
/// the value of the item as its size.
///
/// The nodes are in three columns: sources `S`, middle nodes `M` and targets
/// `T`. Each column has about the square root of half of the item count as
/// its node count, at least 2 and at most 24, so the node count grows slowly
/// with the item count. An item with an even index flows from a source to a
/// middle node, and an item with an odd index from a middle node to a
/// target. The same count gives the same nodes and the same flow ends for
/// each step: only the sizes change with the values.
List<SankeyFlow> sankeyFlows(List<Sample> values) {
  final nodes = math.sqrt(values.length / 2).ceil().clamp(2, 24);
  return List<SankeyFlow>.generate(values.length, (i) {
    final k = i ~/ 2;
    final a = k % nodes;
    final b = (k * 7 + k ~/ nodes) % nodes;
    return i.isEven
        ? (from: 'S$a', to: 'M$b', flow: values[i].y)
        : (from: 'M$a', to: 'T$b', flow: values[i].y);
  }, growable: false);
}

/// A frame and its workload step, independent of library throughput.
class const DatasetFrame(
  /// All generated items.
  final List<Sample> values,

  /// Completed update steps since reset.
  final int step,
) {
  /// A fresh public-widget input.
  this;
}

/// Seeded phases use integer arithmetic that is exact on native and JavaScript.
class DatasetGenerator(
  /// Item count.
  final int count,

  /// Dataset seed.
  final int seed,
) {
  /// Prepare one phase per item; lower counts share the same prefix.
  this {
    var state = seed & 0x7fffffff;
    _phases = List<double>.generate(count, (_) {
      state = (state * 1664525 + 1013904223) & 0x7fffffff;
      return state / 0x80000000 * math.pi * 2;
    }, growable: false);
  }

  late final List<double> _phases;

  /// Same step and configuration produce identical data for every library.
  DatasetFrame frame(int step) {
    final time = step / 60;
    return DatasetFrame(
      List<Sample>.generate(count, (i) {
        final x = count == 1 ? 50.0 : i * 100 / (count - 1);
        final y =
            50 +
            26 * math.sin(x * .075 + time) +
            12 * math.sin(_phases[i] + time * .7);
        return Sample(i, x, y);
      }, growable: false),
      step,
    );
  }
}
