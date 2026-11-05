import 'dart:math' as math;

/// An immutable input value shared by every adapter.
class Sample {
  /// One item in the deterministic workload.
  const Sample(this.index, this.x, this.y);

  /// Stable item identity.
  final int index;

  /// Numeric domain position, sorted for line charts.
  final double x;

  /// Positive value in the fixed 0–100 range.
  final double y;
}

/// A frame and its workload step, independent of library throughput.
class DatasetFrame {
  /// A fresh public-widget input.
  const DatasetFrame(this.values, this.step);

  /// All generated items.
  final List<Sample> values;

  /// Completed update steps since reset.
  final int step;
}

/// Seeded phases use integer arithmetic that is exact on native and JavaScript.
class DatasetGenerator {
  /// Prepare one phase per item; lower counts share the same prefix.
  DatasetGenerator(this.count, this.seed) {
    var state = seed & 0x7fffffff;
    _phases = List<double>.generate(count, (_) {
      state = (state * 1664525 + 1013904223) & 0x7fffffff;
      return state / 0x80000000 * math.pi * 2;
    }, growable: false);
  }

  /// Item count.
  final int count;

  /// Dataset seed.
  final int seed;
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
