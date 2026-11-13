# Host seams: chartjs-chart-sankey on the Chart.js port

This file lists each place where the sankey chart type needs a part of its host,
`flutter_chartjs_port`, that the public libraries of the host do not give in a good form. It is the
input for the work on the public API of the host. [Sankey ADR 0003](adr/0003-host-connection.md)
gives the rules. [ADR 0009](../../../docs/adr/0009-add-on-ports.md) gives the rule for all add-on
ports.

- Upstream: chartjs-chart-sankey `v0.19.1`, the paths of `third_party/chartjs-chart-sankey/`.
- Host: `flutter_chartjs_port` on 2026-11-13, with the exports of
  [Chart.js ADR 0132](../../flutter_chartjs_port/doc/adr/0132-exports-for-add-on-chart-types.md).
- A person writes this file. Each change that closes a seam updates its row in the same commit.

States:

- `connects`: the public libraries of the host give the use now.
- `sankey-side`: the port uses a Dart form in place of a host change. The form works, but it is a
  cost for each add-on chart type. The host API can remove it.
- `gap`: the host needs a change, with a Chart.js ADR.

## Summary

| State | Seams |
|---|---|
| `connects` | S1, S5, S6, S7, S16, S17, S18, S19, S20 |
| `sankey-side` | S2, S3, S4, S8, S10, S11, S12, S13, S14, S21, S22 |
| `gap` | S9, S15 |

## A controller of another package

| Id | Upstream use | Host port | State | Next step |
|---|---|---|---|---|
| S1 | `parseObjectData` returns the parsed items (`src/controller.ts:370-415`). | The parse functions of `DatasetController` return `List<ParsedItem>`. `chartjs.dart` exports `ParsedItem` since Chart.js ADR 0132. The sankey item is a `ParsedItem` with `x`, `y` and a `SankeyParsedCustom` as `custom`. | `connects` | None. |
| S2 | `new SankeyController(chart, datasetIndex)`: the registry constructs the class. | A class value needs a `construct` closure. The host helper `controllerArgs` is internal, and `Chart.buildOrUpdateControllers` gives the dataset index as a `double`. The port reads `args[0] as Chart` and `(args[1] as num).toInt()`. | `sankey-side` | A public form to make the class value of a controller, for example a factory that takes the Dart constructor. |
| S3 | `new Flow(cfg)`: the controller of the host constructs the element class. | The host helper `elementCfgArg` is internal. The port matches the first argument itself. | `sankey-side` | As S2, for an element. |
| S4 | The overrides `updateElements(elems, start, count, mode)` and `getMinMax(scale)`, and the reads `meta.xScale`, `this.chart` (`src/controller.ts:428-484`). | The signatures of `DatasetController` name the interfaces of `lib/src/types/index.dart` (`types.Element`, `types.Scale`, `types.Chart`). `chartjs.dart` hides these names: the classes take them (row `adapt-types-entry` of the host). Thus an override in another package cannot write the parameter types. The port declares `List<Object?> elems` and `Object scale`, and casts `meta.xScale as Scale`, `chart as Chart` and `elems[i] as Element`. | `sankey-side` | One public name for each of these types in the signatures of the classes that an add-on extends. |
| S8 | `this._cachedMeta` (`src/controller.ts:430`, `:438`, `:449`). | `DatasetController.cachedMeta` is `@internal`. The port calls `getMeta()`, which gives the same object through the chart. | `sankey-side` | A protected `cachedMeta` for subclasses. |
| S10 | The options of the dataset: `this.options.nodePadding`, `.orientation`, `.labels` and 14 more (`src/types.ts:64-96`). | The option model of the host is generated from its own schema. An add-on cannot declare option keys. Each sankey option is an extra of a host scope, and the port reads it by name through the facade `SankeyControllerDatasetOptions` (`jsGet`). A Map option (`labels`, `column`, `priority`, a `nodePadding` by node key) comes from the resolver as a view of the Map, not as a `Map`: an `is Map` test is false. `test/specs/node-padding_test.dart` found this. | `sankey-side` | A way for an add-on to declare its option keys with their types, or a documented read API for the options of an add-on. |
| S11 | `static defaults`, `static overrides`, `static descriptors` (`src/controller.ts:242-363`, `src/flow.ts:135-158`). | The typed scope classes of the host (`*Scope`) are internal. The statics are `Map<String, Object?>` literals with nested Maps. The animations name their properties by text (`'properties': ['x2', 'y2']`, `'type': 'color'`). The typed animation classes of the host (`PropertyAnimation`) cover only the properties of the host elements. | `sankey-side` | A typed form for the defaults of a component of another package, and for the animation of a property of another package. |

## An element of another package

| Id | Upstream use | Host port | State | Next step |
|---|---|---|---|---|
| S5 | `tooltipPosition()` returns `{x, y}` (`src/flow.ts:290-292`). | `Element.tooltipPosition` returns `ElementPoint`. `chartjs.dart` exports it since Chart.js ADR 0132. | `connects` | None. |
| S6 | `getRange(axis)` (`src/flow.ts:298-302`). | The interaction of the host tests an element against `VisualElementRange`. `chartjs.dart` exports it since Chart.js ADR 0132. | `connects` | None. |
| S12 | The properties of the element: `flow`, `x2`, `y2`, `width`, `height`, `progress`, `from`, `to` (`src/flow.ts:160-167`), written by `Object.assign` and by the animations. | The element protocol of the host (Chart.js ADR 0017) needs, for each property, a field, a getter, a setter, a case of `operator []`, a case of `operator []=` and a bit of the `undefined` state. `Flow` has about 90 lines for 8 properties. `AnimatedProp` is internal, so the animations write each property by name. | `sankey-side` | A helper or a generator for the properties of an element of another package. |
| S14 | `this.options.colorFrom`, `.flowLabels.display` (`src/flow.ts:51-72`, `:197`). | `Element.options` is an `Object?`. The port reads it by name through the facade `FlowOptionsFace`. | `sankey-side` | As S10. |

## The app

| Id | Upstream use | Host port | State | Next step |
|---|---|---|---|---|
| S9 | `new Chart(ctx, {type: 'sankey', data: {datasets: [{data: [{from, to, flow}]}]}})`. | The typed `ChartConfig` has a closed set of chart kinds (`ChartKind`) and dataset classes (`Dataset`). A sankey chart runs only through `ChartView.raw` with a Map config. This is seam H18 of the zoom port for a chart type. | `gap` | A Chart.js ADR for a chart kind and a dataset class of another package. |
| S15 | The default colors of the nodes, the flows and the labels (`'black'`, `'red'`, `'green'`). | The theme of the host compiles the tokens of the host options. It has no extension for the options of an add-on. The sankey defaults are fixed colors under each theme. This is seam H19 of the zoom port. | `gap` | The theme extension of the host (`theming.md` §5.2). |
| S16 | `Chart.register(SankeyController, Flow)` (`src/index.ts:6`). | `Chart.register` takes the two class values. The registry merges the Map `defaults`, `overrides` and `descriptors`, with the Dart objects of the host options in them. | `connects` | None. |
| S21 | `export { Flow, SankeyController }` (`src/index.esm.ts:20-21`). | `Flow` is also the name of a widget of `package:flutter/widgets.dart`. A library that imports Flutter and this port, and names `Flow`, has an ambiguous import. The host has this case for `Element` and `Animation`, and its app library leaves the two names out. The port keeps the upstream name and gives `sankeyRegisterables`, so an app registers the chart type with no use of the name. `apps/chartjs_gallery/test/sankey_page_test.dart` imports the port with a prefix. | `sankey-side` | A rule for the names of an add-on that collide with Flutter names, as the host has for its app library. |

## The runtime and the canvas

| Id | Upstream use | Host port | State | Next step |
|---|---|---|---|---|
| S7 | `Array.prototype.sort`, a stable sort, in the layout (`src/lib/layout.ts`, 9 calls) and in `src/lib/core.ts`. | `js_semantics.dart` exports each library of `lib/src/js/` since Chart.js ADR 0132, `jsSort` among them. | `connects` | None. |
| S17 | `ctx.createLinearGradient(...)` with two color stops (`src/flow.ts:61-66`). | The canvas of the host has no `createLinearGradient`. A `ChartGradient.linear` is the value of `fillStyle`. | `connects` | None. |
| S18 | `toFont`, `valueOrDefault`, `color(...).alpha(...)`, `getHoverColor` of `chart.js/helpers`. | `helpers.dart` exports `toFont`, `valueOrDefault` and `getHoverColor`. A color is a Flutter `Color` in a `ChartPaint`: `withValues(alpha:)` is the `alpha` of upstream. | `connects` | None. |
| S19 | The scriptable defaults `hoverColorFrom(ctx, options)` and the descriptor function `_scriptable(name)` (`src/flow.ts:148-149`, `src/controller.ts:244`). | The resolver calls a Dart function of two positional parameters for a scriptable option, and a function of one parameter for `_scriptable`. | `connects` | None. |
| S20 | The animation `progress` with a scriptable `delay` and `duration`, and the transitions `show`, `hide` and `resize` (`src/controller.ts:252-310`). | The animations of the host animate a property of another package by its name. `test/specs/resize_test.dart` pins the animation and the `resize` transition. | `connects` | None. |
| S13 | `vi.spyOn(chart.ctx, 'fillRect')`, then `chart.draw()` (`test/specs/node-min-size.spec.js:87`). | `chart.ctx` is writable, but the mock context of the harness has no `resetTransform` and no `canvas`, which `chart.draw()` reads. `test/specs/node-min-size_test.dart` draws the controller on the mock context. `test/fixtures/observe.dart` has a `RecordingContext` that extends the mock context and sends `font`, `save`, `restore`, `measureText`, `canvas` and `resetTransform` to the context of the chart. The host has such a class only in its own `test/` folder. | `sankey-side` | A public recording context in the harness that `chart.draw()` accepts. |
| S22 | `layout: {padding: {right: 53}}` in a config, over the override `padding: {bottom: 3, left: 3, right: 13, top: 3}` of the chart type (`test/fixtures/nodeWidth.js`, `src/controller.ts:322-329`). | A padding of the host is an `EdgeInsets`, and a supplied `EdgeInsets` replaces all four sides (Chart.js ADR 0123). Upstream merges the sides. A user who changes one side of the padding of a sankey chart must give the other three sides of the override again: the hand port of the fixture has `EdgeInsets.only(bottom: 3, left: 3, right: 53, top: 3)`. | `sankey-side` | A decision for the padding override of a chart type: a merge by side, or a doc note for each add-on. |
