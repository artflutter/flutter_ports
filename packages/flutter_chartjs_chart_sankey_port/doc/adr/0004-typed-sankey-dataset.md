# Sankey ADR 0004: The typed sankey dataset

- Status: accepted (2026-11-20): the gallery and the lab draw typed sankey charts, and the twin tests pass.
- Date: 2026-11-20
- Supersedes: nothing
- Related: [Chart.js ADR 0189](../../../flutter_chartjs_port/doc/adr/0189-open-dataset-class.md), [Sankey ADR 0003](0003-host-connection.md), [host-seams.md](../host-seams.md)

## Context

A sankey chart ran only through `ChartView.raw` with a Map: the typed `ChartConfig` of the host took no
dataset class of another package (seam S9). Each color function got the generic `ScriptableContext` and
cast its `raw` item, and a wrong key or value showed no error. Chart.js ADR 0189 opens the `Dataset`
class of the host.

## Decision

1. `SankeyDataset` of `lib/src/sankey_dataset.dart` extends `Dataset`, with the `kind`
   `ChartKind(SankeyController.id)`. It has one parameter for each option of
   `SankeyControllerDatasetOptions` (`src/types.ts:64`), and takes `key`, `label`, `hidden`, `order`,
   `clip`, `borderColor`, `borderWidth`, `tooltipCallbacks` and `extra` from `Dataset`. It takes no
   `backgroundColor`: upstream declares it `never`.

   ```dart
   SankeyDataset(
     label: 'Energy',
     data: const [SankeyDataPoint(from: 'Solar', to: 'Grid', flow: 12)],
     colorFrom: .byNode(nodeColor),
     colorTo: .byNode(nodeColor),
     nodePadding: .byKey({'Grid': SankeyNodeGap(before: 30)}),
   )
   ```

2. `lowerOwn` writes the values of a raw sankey dataset Map, in the key order of `src/types.ts`. Thus the
   controller reads both forms with the same code.
3. The six color options (`colorFrom`, `colorTo`, `hoverColorFrom`, `hoverColorTo`, `flowColor`,
   `hoverFlowColor`) take a sealed `SankeyColor`: `constant(ChartPaint)`,
   `byNode(Color Function(String node))` and `byFlow(ChartPaint Function(SankeyDataPoint flow))`.
   `byNode` reads the target node for `colorTo` and `hoverColorTo`, and the source node for the others.
   The package reads the data item of the context, so the app has no cast.
4. A node option takes a sealed `SankeyNodeValue<T>`: `all(T)`, `byKey(Map<String, T>)` and
   `byNode(SankeyNodeCallback<T>)`. `nodeMinSize` is a `SankeyNodeValue<double>`, and `nodePadding` a
   `SankeyNodeValue<SankeyNodeGap>`.
5. An option of the flow labels takes a sealed `SankeyFlowValue<T>`: `all(T)` and
   `byFlow(T Function(SankeyDataPoint flow))`.
6. `nodeLabels` is a `SankeyNodeLabels`, and `flowLabels` a `SankeyFlowLabels`.
7. `data` is a `List<SankeyDataPoint>`. `column` is a `Map<String, int>`, `priority` a
   `Map<String, double>` and `labels` a `Map<String, String>`. A Map data item and `parsing` go
   through `extra`.
8. The apps use the typed dataset. The specs and the fixtures keep the raw Maps: they port upstream
   configs.

## Rejected

- `ChartValue<ChartPaint>` for the colors: each function casts `context.raw`.
- A generic `ScriptableContext<D>` in the host: it changes each scriptable option of the host.
- An indexed color form: the sankey controller declares its options not indexable
  (`src/controller.ts:243`).

## Consequences

- A sankey chart uses the typed chart options (`title`, `tooltip`, `animation`) and the `==` and key
  rules of the typed `ChartView`.
- A config still names `type: ChartKind(SankeyController.id)`.
- `copyWith` and `props` list each parameter by hand, as the built-in classes do.

## Tests

- `test/port/sankey_dataset_test.dart`
- `apps/chartjs_gallery/test/sankey_page_test.dart`
