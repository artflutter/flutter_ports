// Original code, not ported from chartjs-chart-sankey: a test context.

/// The canvas context of the unit tests `labels_test.dart` and
/// `flow_test.dart`: the mock context of the harness with one fixed text
/// width, as the object of `vi.fn()` members of upstream has
/// (`measureText: vi.fn().mockReturnValue({ width })`).
library;

import 'package:chartjs_test_utils/pure.dart' show MockContext;
import 'package:flutter_chartjs_port/chartjs.dart' show TextMetrics;

final class const _FixedMetrics(@override final double width)
    implements TextMetrics {
  @override
  double get actualBoundingBoxAscent => 0;

  @override
  double get actualBoundingBoxDescent => 0;

  @override
  double get actualBoundingBoxLeft => 0;

  @override
  double get actualBoundingBoxRight => 0;
}

/// A recording context whose `measureText` gives [textWidth] for each text.
final class FakeContext(
  /// The width of each text.
  final double textWidth,
) extends MockContext {
  @override
  TextMetrics measureText(String text) => _FixedMetrics(textWidth);

  /// The arguments of each recorded call of the method [name].
  List<List<Object?>> callsOf(String name) => [
    for (final call in getCalls())
      if (call['name'] == name) call['args']! as List<Object?>,
  ];
}
