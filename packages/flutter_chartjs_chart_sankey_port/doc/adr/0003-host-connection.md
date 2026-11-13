# Sankey ADR 0003: The connection to the host port

- Status: proposed
- Date: 2026-11-13
- Gate: sankey phase 1.
- Related: [ADR 0009](../../../../docs/adr/0009-add-on-ports.md) (add-on ports),
  [Chart.js ADR 0132](../../../flutter_chartjs_port/doc/adr/0132-exports-for-add-on-chart-types.md)
  (the host exports for this port),
  [Zoom ADR 0003](../../../flutter_chartjs_plugin_zoom_port/doc/adr/0003-host-connection.md) (the
  connection of the first add-on port), [host-seams.md](../host-seams.md)

## Context

A plugin, as the zoom plugin, reads the chart from the outside. A chart type extends two classes
of the host: `DatasetController` and `Element`. It overrides their methods, gives them static
`defaults`, `overrides` and `descriptors`, and goes into the registry of the host. Thus this port
uses parts of the host API that the zoom port does not use.

## Decision

1. **Public libraries only.** `lib/` and `test/` import only
   `package:flutter_chartjs_port/chartjs.dart`, `helpers.dart`, `js_semantics.dart` and the app
   library, and in tests `package:chartjs_test_utils/flutter.dart` and `pure.dart` (ADR 0009
   item 3). `check:lib-imports` fails on another import of the host.
2. **A gap is a host change.** A part of the host that the public libraries do not give is a host
   change with a Chart.js ADR. Chart.js ADR 0132 is the first one for this port: `ParsedItem`,
   `ElementPoint`, `VisualElementRange` and the whole JS runtime.
3. **A workaround is a seam.** When the port can use a Dart form in place of a host change, it does
   so, and `doc/host-seams.md` records the seam with the state `sankey-side`. The seams are the
   input for the work on the public API of the host. This port makes no design decision for the
   host API.
4. **The class values.** `SankeyController.jsClass` and `Flow.jsClass` are `JsClass` values with
   the statics of upstream. Their `defaults`, `overrides` and `descriptors` are Maps: the typed
   scope classes of the host are internal.
5. **The element.** `Flow` follows the element protocol of the host (Chart.js ADR 0017): a typed
   member for each property, and the access by name of `operator []` and `operator []=`. The
   animations of the host write its properties by name.
6. **The controller.** `SankeyController` overrides `parseObjectData`, `buildOrUpdateElements`,
   `getMinMax`, `update`, `updateElements` and `draw`, as upstream.
7. **The typed API.** The typed `ChartConfig` of the host has a closed set of chart kinds and
   dataset classes. A sankey chart runs through `ChartView.raw` (seam S9).
8. **The JS runtime.** The port takes the JS runtime from
   `package:flutter_chartjs_port/js_semantics.dart`. The layout sorts with `jsSort`, the stable
   sort of `Array.prototype.sort`: the order of two equal nodes decides their positions.
9. **Tests.** The specs that create a chart are `testWidgets` cases with `acquireChart` of the
   harness. The unit tests of the pure modules use `package:test`. Each test file has
   `@TestOn('vm')`.
