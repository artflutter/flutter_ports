# chartjs-plugin-zoom port differences

This file lists the hunks of ported code that do not translate the upstream lines. Each hunk
carries the line comment `// DIVERGES(zoom): <ID>, <reason>`
([Zoom ADR 0002](adr/0002-file-naming-and-layout.md) item 10). A port-only file is not a row. A
hunk of a port-only file that gives a difference of a row carries the marker of that row. A skip
reason `'diverges: <ID>'` names a row.

The ID starts with its category: `adapt`, `platform`, `theme`, `js-semantics`, `harness` or
`not-followed`, as in the [Chart.js port](../../flutter_chartjs_port/doc/differences.md). The
column "Upstream file@version:lines" names the pin at which the porter last checked the row, for
example `src/handlers.ts`@v2.2.0+fb81d331:41. Each bump checks every row.

The table has no rows in phase 0. [Zoom ADR 0003](adr/0003-host-connection.md) reserves these
IDs. A row with the ID comes with the change that ports the hunk.

| ID | The difference | Seam |
|---|---|---|
| `adapt-canvas-event-listener` | `addCanvasEventListener(canvas, type, listener)` and `removeCanvasEventListener` of the host in place of `canvas.addEventListener` and `removeEventListener`, also on the document target | H3, H4, H5 |
| `adapt-chart-methods-extension` | The extension `ZoomChart on Chart` in place of the ten run-time methods of `bindApi` | H9 |
| `adapt-style-properties` | `getPropertyValue('touch-action')`, `setProperty('touch-action', 'none')` and `setProperty(name, null)` in place of `style.touchAction`, `style.userSelect` and `removeProperty` | H8 |
| `harness-date-adapter` | The time-scale specs run on the default date adapter of the host, not on chartjs-adapter-date-fns | Zoom ADR 0003 item 10 |

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
