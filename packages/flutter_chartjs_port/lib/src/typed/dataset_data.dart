// Original code, not ported from Chart.js: the data forms of a typed dataset.

/// The `data` parameter of the cartesian datasets of the typed API
/// ([BarDataset], [LineDataset] and [ScatterDataset]): one value for each
/// label of the chart, or items with their own x.
library;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:meta/meta.dart' show immutable;

/// The data of a [BarDataset], a [LineDataset] or a [ScatterDataset]: the
/// `data` option of Chart.js in one of its two forms.
///
/// ```dart
/// LineDataset(data: .values([5, 7, null]))
/// LineDataset(data: .points([DataPoint(1, 2), DataPoint(2.5, null)]))
/// ```
///
/// The List goes to the chart by reference: the chart reads the List of the
/// app, with no copy. For new data, give a new List in a new config. Or
/// change the List and call `chart.update()`.
///
/// `==` compares the List by identity: a new [DatasetData] around the same
/// List in each build is the same value, and the chart does not update.
@immutable
sealed class const DatasetData._() {
  /// One value for each label of the chart: `data: [5, 7, null]`. A `null`
  /// value is a gap.
  const factory values(List<num?> values) = DatasetValues;

  /// The data items in the object form `{x, y}`: `data` with objects
  /// (`docs/general/data-structures.md`).
  const factory points(List<DataPoint> points) = DatasetPoints;
}

/// The [DatasetData] of one value for each label of the chart.
final class const DatasetValues(
  /// The values, one for each label of the chart. A `null` value is a gap.
  final List<num?> values,
) extends DatasetData {
  /// The values of a dataset.
  this : super._();

  @override
  bool operator ==(Object other) =>
      other is DatasetValues && identical(values, other.values);

  @override
  int get hashCode => Object.hash(DatasetValues, identityHashCode(values));

  @override
  String toString() => 'DatasetData.values($values)';
}

/// The [DatasetData] of items with their own x.
final class const DatasetPoints(
  /// The data items in the object form `{x, y}`.
  final List<DataPoint> points,
) extends DatasetData {
  /// The points of a dataset.
  this : super._();

  @override
  bool operator ==(Object other) =>
      other is DatasetPoints && identical(points, other.points);

  @override
  int get hashCode => Object.hash(DatasetPoints, identityHashCode(points));

  @override
  String toString() => 'DatasetData.points($points)';
}
