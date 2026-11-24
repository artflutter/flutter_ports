// Original code, not ported from Chart.js: the dataset of a test controller.

/// The dataset of a test controller: a registered controller id that has no
/// dataset class of its own (Chart.js ADR 0190).
///
/// A config has no chart type: the class of its first dataset gives it. A
/// test of a custom controller gives the controller id as the `kind` of
/// this class, as a package gives the dataset class of its chart type.
library;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// A dataset of the controller [kind], with [data] or [points] and the
/// other options in `extra`.
final class const TestDataset(
  /// The id of the test controller.
  @override final ChartKind kind, {
  super.key,
  super.label,

  /// The values, one for each label.
  final List<num?>? data,

  /// The items, an x and a y for each.
  final List<DataPoint>? points,
  super.hidden,
  super.order,
  super.borderColor,
  super.backgroundColor,
  super.borderWidth,
}) extends Dataset {
  /// A dataset of the test controller [kind].
  this : assert(data == null || points == null, 'Give data or points.');

  @override
  List<Object?>? get chartData => data ?? points;

  @override
  void lowerOwn(OptionScope scope) {}

  @override
  List<TypedProperty> get props => [
    ('key', key),
    ('kind', kind),
    ('label', label),
    ('data', data),
    ('points', points),
    ...styleProps,
  ];
}
