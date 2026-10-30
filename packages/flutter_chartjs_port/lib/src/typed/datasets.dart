// Original code, not ported from Chart.js: the datasets of the typed API.

/// The datasets of the typed API (Chart.js ADR 0052, sections 1 and 3):
/// [DataPoint], the object form of a data item.
///
/// A data List goes to the chart by reference: the chart reads the List of
/// the app. The chart does not write into a data List or into a
/// [DataPoint].
library;

/// A data item in the object form `{x, y}` or `{x, y, r}`
/// (`docs/general/data-structures.md`, "Object[]").
///
/// At run time, a data point is the `Map<String, Object?>` of that object:
/// each constructor makes one Map, as the raw `{'x': x, 'y': y}` does, and
/// the chart reads its keys. Thus a `List<DataPoint>` goes to the chart with
/// no copy. A data point does not implement `Map`.
///
/// A `null` [y] is a gap in the line.
extension type DataPoint._(Map<String, Object?> _item) {
  /// `{x, y}` with a number [x]: a value of a linear or a logarithmic x
  /// axis, or an index of a category x axis.
  DataPoint(num x, num? y) : _item = <String, Object?>{'x': x, 'y': y};

  /// `{x, y}` with a time [x], for a time or a time series x axis.
  DataPoint.time(DateTime x, num? y)
    : _item = <String, Object?>{'x': x, 'y': y};

  /// `{x, y}` with a label [x], for a category x axis. A label that is not
  /// in the labels of the chart becomes a new label: the category scale adds
  /// it to `data.labels`.
  DataPoint.label(String x, num? y) : _item = <String, Object?>{'x': x, 'y': y};

  /// `{x, y, r}`: a bubble at ([x], [y]) with the radius [r] in pixels.
  DataPoint.bubble(num x, num y, num r)
    : _item = <String, Object?>{'x': x, 'y': y, 'r': r};

  /// The x value: a `num`, a `DateTime` or a `String`.
  Object get x => _item['x']!;

  /// The y value. `null` is a gap.
  num? get y => _item['y'] as num?;

  /// The bubble radius in pixels, or `null` for a data point that is not a
  /// bubble.
  num? get r => _item['r'] as num?;
}
