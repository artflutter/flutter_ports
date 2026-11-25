## Unreleased

- BREAKING: `sankeyRegisterables` is a `List<ChartComponent>` of `SankeyController.component` and
  `Flow.component` (Chart.js ADR 0204 of flutter_chartjs_port): the `jsClass` of both classes is gone. The
  static `defaults`, `descriptors` and `overrides` are typed scopes of the host.
- BREAKING: `SankeyDataset` has no `extra` (Chart.js ADR 0201 of flutter_chartjs_port): each option is a typed
  parameter.
- The options of a dataset and of a flow are immutable classes with a typed field for each option,
  read once from the host resolver (Sankey ADR 0005). Breaking: `SankeyControllerDatasetOptions`,
  `SankeyNodeLabelsOptions`, `SankeyParsingOptions` and `FlowLabelsOptions` are classes with a
  static `of` and typed fields; `FlowOptionsFace` is `FlowOptions`; `resolveNodeOption` takes a
  `SankeyNodeValue`; `SankeyNode.color` and the colors of `DrawLabelOptions` are `ChartPaint?`;
  `buildNodesFromData` takes a `SankeySize` and the records of `priority` and `column` as
  `Map<String, double>`.
- `Flow.flowOptions` gives the resolved options of a flow, and `Flow.expireFlowOptions` drops them.

## 0.1.0-beta.1

- The first beta release, on `flutter_chartjs_port` 0.1.0-beta.4. The API can still change
  before 0.1.0.
- The typed `SankeyDataset` with its option types `SankeyColor`, `SankeyNodeValue`,
  `SankeyFlowValue`, `SankeyNodeLabels` and `SankeyFlowLabels` (Sankey ADR 0004).

- Ports each module of `src/` at 0.19.1: the sankey controller, the flow element, the node layout
  and the labels, on the public libraries of `flutter_chartjs_port`.
- Ports the upstream unit tests, the specs and the fixtures.
- The animation defaults have no `type`, as the host has no such option.
- The defaults hide the two scales with `ScaleDisplay.off`, the form of the host for `display`.

## 0.0.1

- Initial scaffold. Tracks chartjs-chart-sankey 0.19.1.
