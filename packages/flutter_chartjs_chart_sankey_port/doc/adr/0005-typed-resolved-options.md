# Sankey ADR 0005: The typed resolved options

- Status: accepted (2026-11-23): its code is on main, and the tests of section Tests, the sankey fixtures and the gallery and lab tests pass.
- Date: 2026-11-23
- Supersedes: [Sankey ADR 0002](0002-file-naming-and-layout.md) item 10
- Related: [Sankey ADR 0004](0004-typed-sankey-dataset.md), [host-seams.md](../host-seams.md), [Chart.js ADR 0182](../../../flutter_chartjs_port/doc/adr/0182-resolved-plugin-option-classes.md)

## Context

The options of a sankey dataset and of a flow are objects of the host resolver. Their sankey keys are
extras of the host scopes, with no typed read of the host (seams S10 and S14). Extension-type facades
read each key by name with `jsGet` at each use, most as `Object?`, and the controller, the labels and the
flow cast or convert the value at each use. A Map option comes from the resolver as a view of the Map,
so each node read went through `jsGet` too.

## Decision

1. Each option interface of `src/types.ts` is an immutable final class of `lib/src/types.dart` with its
   upstream name and a typed field for each option: `SankeyControllerDatasetOptions`,
   `SankeyNodeLabelsOptions`, `SankeyParsingOptions`, `FlowOptions` and `FlowLabelsOptions`
   (`FlowOptionsFace` is gone).

   ```dart
   final options = SankeyControllerDatasetOptions.of(resolver);
   final gap = resolveNodeOption(options.nodePadding, node); // SankeyNodeGap?
   ```

2. The static method `of(Object? options)` of each class reads each key once by name and converts its
   value. No other code of the port reads these options by name. A field holds the default of its use
   for `undefined`, or Dart `null` where the uses differ.
3. A node option field is a `SankeyNodeValue<T>` of Sankey ADR 0004: `of` makes a `byNode` of a
   function, a `byKey` of a record and an `all` of another value. A record is a Map or a resolver view:
   `of` reads each key of all its scopes (`jsOwnPropertyNames`) once. `resolveNodeOption<T>` takes the
   `SankeyNodeValue<T>`. A number of `nodePadding` is a `SankeyNodeGap` with both sides.
4. A color field is a `ChartPaint?`: a `Color` of a raw config is its solid paint. `SankeyNode.color`
   and the colors of `DrawLabelOptions` are `ChartPaint?`. `FlowOptions.flowColor` is Dart `null` for
   the JavaScript `null` (the color mode applies) and `ChartPaint.unchanged()` for `undefined`.
5. `FlowOptions.flowLabels` is Dart `null` when `flowLabels.display` is falsy: upstream reads no other
   label key then.
6. The controller reads `SankeyControllerDatasetOptions.of` again after each `configure` (a new
   resolver). `Flow.flowOptions` keeps its result while `options` is the same object;
   `Flow.expireFlowOptions` drops it unless the host froze the options, and the controller calls it
   after each update of a flow and before each draw: an update or an animation writes into the options
   of one flow.
7. `priority` and `column` are `Map<String, double>?`, `labels` a `Map<String, Object>?` and `parsing` a
   `SankeyParsingOptions?`; `buildNodesFromData` and `getParsedData` take these types.
8. Two reads by name stay outside `of`: the hover color defaults of `Flow` read `colorFrom` and `colorTo`
   of the resolver that the host gives them, and the progress animation reads `orientation` of the
   dataset object of the app (controller.ts:264-270), as upstream.

## Rejected

- A read at each use through a cache of the host resolver: the values stay `Object?`.
- A host change for typed add-on option keys: the host has no such API yet (seam S10); this decision
  needs none.
- A cache of the flow options keyed on the options object alone: the options of one flow change in
  place.

## Consequences

- Public API: the facade getters give typed values, `FlowOptionsFace` is `FlowOptions`,
  `resolveNodeOption` takes a `SankeyNodeValue`, and `SankeyNode.color` and the colors of
  `DrawLabelOptions` are `ChartPaint?`.
- A scriptable dataset option that reads the `mode` or `active` of the dataset context sees the context
  of the first read after `configure`.
- A foreign value (CSS text, a callback of another type) stops a debug build at the read.

## Tests

- `test/specs/labels_test.dart`
- `test/port/controller_test.dart`
- `test/port/flow_test.dart`
- `test/specs/fixtures_test.dart`
