# TooltipItem — migration draft

The difference row is [`adapt-native-tooltip-item`](differences.md#adapt-native-tooltip-item).

## The classes

```dart
@immutable
class const TooltipItem({
  required final Chart chart,
  required final int datasetIndex,
  required final int dataIndex,

  // Null for an index with no element, as in ActiveElement.
  final Element? element,

  // The lines of the label of the data item. Empty for no label.
  required final List<String> label,

  // The value as the tooltip shows it.
  required final String formattedValue,

  // The dataset object of the app: a Map, or the dataset scope of a typed
  // config.
  required final Object dataset,

  // A ParsedItem, or the double of a doughnut or pie item.
  required final Object? parsed,

  // The data item of the app, as it is.
  required final Object? raw,
}) {
  // The `label` of the dataset, or null for a dataset without a String label.
  String? get datasetLabel;
}

@immutable
final class const TooltipBodyItem({
  required final List<String> before,
  required final List<String> lines,
  required final List<String> after,
});
```

`TooltipItem` and `TooltipBodyItem` are in `lib/src/types/tooltip_item.dart`. `TooltipItem` is open: a
plugin can extend it. The tooltip makes one item for each active element and keeps its identity
through `filter`, `itemSort`, the 14 callbacks and `dataPoints`.

```dart
// The tooltip model.
List<TooltipItem>? get dataPoints;
List<TooltipBodyItem>? get body;
List<String>? get title; // also beforeBody, afterBody and footer

// A callback of TooltipCallbacks.
title: (tooltip, items) => [items.first.label.join(' '), 'Q3'],
label: (tooltip, item) => ['${item.datasetLabel}: ${item.formattedValue}'],

// A plugin with its own tooltip.
for (final item in chart.tooltip!.dataPoints!) {
  draw(item.element, item.label, item.formattedValue);
}
```

## The callbacks

```dart
typedef TooltipItemFilter =
    bool Function(
      TooltipItem item,
      int index,
      List<TooltipItem> items,
      Object data,
    );

typedef TooltipItemComparator =
    int Function(TooltipItem a, TooltipItem b, Object data);

typedef TooltipExternal = void Function(TooltipModel tooltip, bool replay);
```

The options `filter`, `itemSort` and `external` hold these functions, in a raw config and in the typed
API. The tooltip is the first argument of `external`. Chart.js gives it as `this`. `data` is
`chart.data`, as in the legend callbacks of Chart.js ADR 0127.

```dart
ChartTooltip(
  filter: (item, index, items, data) => item.dataIndex != 0,
  itemSort: (a, b, data) => b.datasetIndex - a.datasetIndex,
  external: (tooltip, replay) => overlay.show(tooltip.dataPoints),
)

// Raw config.
'filter': (TooltipItem item, int index, List<TooltipItem> items, Object data) =>
    item.dataIndex != 0,
```

## The values of Chart.js and their native form

`createTooltipItem` (`plugin.tooltip.js:127-146`) is the only producer of an item. The label comes from
`getLabelAndValue` of the controller:

- Bar, line and the base controller give `'' + iScale.getLabelForValue(...)`: a string. It is a List
  of one line.
- Bubble, doughnut, pie, polar area and scatter give `labels[index] || ''`. Radar gives
  `vScale.getLabels()[index]`. A string label is a List of one line. An array label is the List of
  its lines. A number is the line of its string form.
- `''`, `null`, `undefined` and no label are the empty List. The test `item.label` of the default
  `title` is `label.isNotEmpty`.
- `formattedValue` is a string in each controller.
- `datasetIndex` and `dataIndex` are the indexes of the active element: `int`.
- `parsed`, `raw` and `dataset` are data of the app. They keep their values.
- `getLabelAndValue` returns `({List<String> label, String value})`.

A body item has three arrays of lines (`plugin.tooltip.js:559-563`). `title`, `beforeBody`, `afterBody`
and `footer` are arrays of lines too.

## Differences from Chart.js

- A function of another type in `filter`, `itemSort` or `external` stops a debug build. A release
  build makes no call.
- An item is immutable. In Chart.js, a callback can write into the item object.
- The default `label` of the mode `dataset` joins the lines of the label with a comma, as the string
  form of a JS array does.
- A null line in a label array of the app is not a line. Chart.js shows the text `null`.
- `external` gets no object `{chart, tooltip, replay}`. The chart is `tooltip.chart`.

## Removed

- `TooltipItem` and `TooltipBodyItem` of `plugin.tooltip.dart`: the records with 9 and 3 slots of
  `Object?`, and their access by name.
- `types.TypedTooltipItem`, the interface, and `ChartTooltipItem`, the view.
- The 9 readers `_TooltipItemView` and `_BodyItemView`, and `_readByName`.
- The `jsCall` of `filter`, `itemSort` and `external`, and their `JsFunction` values in the tests.
- The raw label of `getLabelAndValue` (`Object?`).
