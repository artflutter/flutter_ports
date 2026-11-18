// Original code, not ported from Chart.js: the splice of a spec port.

/// `array.splice(start, deleteCount, ...items)` of the upstream specs, on a
/// Dart List (Chart.js ADR 0175).
///
/// The library has no such call: its Lists change through `removeRange`,
/// `insertAll` and `add`. A spec port calls [spliceList] where the upstream
/// spec changes a data array or the dataset array with `splice`.
library;

/// Removes [deleteCount] items from [start], inserts [items] there, and
/// gives the removed items. A negative [start] counts from the end. [start]
/// and the count clamp to the List, as `splice` does.
List<T> spliceList<T>(
  List<T> list,
  int start,
  int deleteCount, [
  Iterable<T> items = const [],
]) {
  final length = list.length;
  final from = (start < 0 ? length + start : start).clamp(0, length);
  final to = (from + deleteCount).clamp(from, length);
  final removed = list.sublist(from, to);
  list
    ..removeRange(from, to)
    ..insertAll(from, items);
  return removed;
}
