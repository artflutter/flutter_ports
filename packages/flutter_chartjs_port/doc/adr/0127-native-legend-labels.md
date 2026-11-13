# Chart.js ADR 0127: Native legend label generation

- Status: proposed (2026-11-13).
- Date: 2026-11-13
- Related: Chart.js ADR 0054 §12 (the typed legend items), Chart.js ADR 0092 and 0099 (the hidden legend that
  waits), Chart.js ADR 0125 (native tooltip callbacks).
- Difference: `adapt-legend-label-callbacks`.

## Context

`plugins.legend.labels` has three callbacks: `generateLabels(chart)`, `filter(item, data)` and `sort(a, b, data)`
(`plugin.legend.js:104-121`). The port reads each one as `Object?`. `buildLabels` calls `generateLabels` through
`callback`, and `filter` and `sort` through `jsCall` with the label options as `this`. The result of
`generateLabels` can be any List. An item of user code is read and written by name (`_Item`, `_readItem` and
`_writeItem`), and a narrow Map item throws (row `js-semantics-legend-items`). `LegendItem`, the item of the built-in
generators, keeps each of its 16 keys as `Object?`.

Upstream reads these values of an item: `text`, `fillStyle`, `fontColor`, `hidden`, `lineCap`, `lineDash`,
`lineDashOffset`, `lineJoin`, `lineWidth`, `strokeStyle`, `pointStyle`, `rotation`, `textAlign`, `borderRadius`,
`datasetIndex` and `index` (`index.d.ts:2328-2405`). The built-in generator of the legend
(`plugin.legend.js:675-704`) and the doughnut and polar area generators make all of them. `borderRadius` is `false`
without `useBorderRadius`. `text` is the label of the app: a string, an array of lines, or another value.

## Decision

1. The three options hold typed functions, in raw and typed configs:

   ```dart
   typedef LegendLabelsGenerator = List<LegendItem> Function(Chart chart);
   typedef LegendItemFilter = bool Function(LegendItem item, Object data);
   typedef LegendItemComparator = int Function(LegendItem a, LegendItem b, Object data);
   ```

   `Chart` is the public chart class. `data` is `chart.data`, the data object of the app. The legend calls each
   function directly. A null option means no callback (no items for `generateLabels`). A value of another type is a
   foreign value: a debug build stops on it, and a release build makes no call.
2. `generateLabels` returns `List<LegendItem>`. `LegendItem` is public, with a constructor that takes each field.
   Items of another class (a Map, an object read by name) are no longer items. `_Item`, `_readItem`, `_writeItem`
   and the row `js-semantics-legend-items` go. `sort` keeps the stable sort of `Array.prototype.sort`. The List
   has no `undefined` item, so the undefined branch of the comparator goes.
3. The fields of `LegendItem` have exact types where the built-in generators give one type:

   | Field | Type |
   | --- | --- |
   | `hidden` | `bool?` |
   | `lineCap`, `lineJoin` | `StrokeCap?`, `StrokeJoin?` |
   | `lineDash` | `List<num>?` |
   | `lineDashOffset`, `lineWidth`, `rotation` | `double?` |
   | `pointStyle` | `PointStyle?` (the value `false` is null: both draw the default marker) |
   | `textAlign` | `TextAlign?` |
   | `datasetIndex`, `index` | `int?` |

   These fields stay open, with a documented content: `text` is the label of the app, as `ChartTooltipItem.label`
   of Chart.js ADR 0125 (a `String`, or a `List` of lines). `fillStyle`, `strokeStyle` and `fontColor` are canvas
   styles, the type of the canvas setters (a `Color`, a `CanvasGradient` or a `CanvasPattern`). `borderRadius` is
   the option value (a number, a corner object or `false`).
4. A null field is a present key with the JS value `undefined` for the face. Thus the reference tests read the
   items of the built-in generators as before. The face writes a value of another type into the foreign slot of
   the field, as each typed record does (Chart.js ADR 0054 §6).

   ```dart
   final legend = <String, Object?>{
     'labels': <String, Object?>{
       'generateLabels': (Chart chart) => [
         LegendItem(text: 'Total', fillStyle: const Color(0xFF1E88E5), datasetIndex: 0),
       ],
       'filter': (LegendItem item, Object data) => item.hidden != true,
       'sort': (LegendItem a, LegendItem b, Object data) => (b.datasetIndex ?? 0) - (a.datasetIndex ?? 0),
     },
   };
   ```

5. The guards of the hidden legend (Chart.js ADRs 0092 and 0099) keep their identity test of the built-in
   generator. A typed `filter` or `sort` still makes the build eager.

## Tests

- `test/port/plugins/plugin.legend_labels_test.dart`: a typed generator, filter and sort; a foreign value of each
  option stops a debug build; the typed fields of the built-in items.
- The plugin reference tests of the legend and the controllers, the legend spec, the fixtures and the oracle O1.
