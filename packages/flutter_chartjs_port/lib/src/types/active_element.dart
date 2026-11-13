// Original code, not ported from Chart.js: the native active element.

/// The native active element contract.
library;

import 'package:flutter_chartjs_port/src/types/index.dart' show Element;
import 'package:meta/meta.dart';

/// An active element of a chart: the object `{element, datasetIndex, index}`
/// of Chart.js.
///
/// It is the `InteractionItem` that an interaction mode gives
/// (core.interaction.js:10, index.d.ts:757), the `ActiveElement` of
/// `getActiveElements()` and of the `onHover` and `onClick` callbacks
/// (index.d.ts:520), and the `ActiveDataPoint` that an app gives to
/// `setActiveElements` (index.d.ts:515).
///
/// Apps and plugins may extend this class.
@immutable
class const ActiveElement({
  /// The index of the dataset in `data.datasets`.
  required final int datasetIndex,

  /// The index of the data item in the dataset.
  required final int index,

  /// The data element. Null for an index with no element
  /// (core.controller.js:1106), and for an item that an app gives to
  /// `setActiveElements`.
  final Element? element,
}) {
  /// Creates an active element. An item for `setActiveElements` needs no
  /// [element]: the chart finds it.
  this;

  /// Two items are equal when their indexes are equal and their elements are
  /// the same object, as the `toEqual` of a spec compares two object
  /// literals.
  @override
  bool operator ==(Object other) =>
      other is ActiveElement &&
      identical(element, other.element) &&
      datasetIndex == other.datasetIndex &&
      index == other.index;

  @override
  int get hashCode =>
      Object.hash(identityHashCode(element), datasetIndex, index);

  /// The item as an object literal, for test messages.
  @override
  String toString() =>
      '{element: ${element.runtimeType}, datasetIndex: $datasetIndex, '
      'index: $index}';
}
