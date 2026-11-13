# ActiveElement — migration draft

```dart
@immutable
class const ActiveElement({
  required final int datasetIndex,
  required final int index,

  // Null for an index with no element, and for an item that the app gives.
  final Element? element,
}) {
  // Equal indexes and the same element object.
  @override
  bool operator ==(Object other) =>
      other is ActiveElement &&
      identical(element, other.element) &&
      datasetIndex == other.datasetIndex &&
      index == other.index;

  @override
  int get hashCode =>
      Object.hash(identityHashCode(element), datasetIndex, index);
}
```

```dart
// The chart.
List<ActiveElement> getActiveElements();
void setActiveElements(List<ActiveElement> activeElements);

chart.setActiveElements(const [ActiveElement(datasetIndex: 0, index: 2)]);

// An interaction mode.
List<ActiveElement> itemsAt(Chart chart, Object e, Object options, [bool? useFinalPosition]);

// The typed API.
onClick: (details) => select(details.hits.first.index), // List<ActiveElement>
```

Removed: `types.ActiveDataPoint`, `types.ActiveElement`, `InteractionItem`, two private
`_ActiveElement` classes, `ChartHit`, and the 5 reads by name of a Map item.

Pass 1 (done): the class. Pass 2 (not started): each index parameter of the chart and of the
dataset controller becomes an `int`.
