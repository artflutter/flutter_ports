# chartjs-chart-sankey port performance

This file has the figures of each form of the port that is faster than the translation of the
upstream lines. Each such form has a row in [differences.md](differences.md).

## 1. Test bed

- Pixel 8a, Android 17, a profile build, Impeller on Vulkan, Flutter 3.50.0-0.4.pre.
- The instrument is `apps/chartjs_gallery/lib/main_sankey_bench.dart`. With
  `--dart-define=SERVE=true`, its service extension `ext.sankey.run` runs one case for each call.
- A case makes a real chart on a canvas with no host, on a bitmap of 800 x 480. One step sets new
  flow sizes and calls `chart.update('none')`. The times are the medians of 7 batches of 200 ms.
- The frame cases show a `ChartView.raw` of 400 x 300 logical pixels with new data in each frame.
- The data `lab` has three columns of at most 24 nodes, as the benchmark lab. The data `wide` has
  six columns and 0.4 nodes for each flow.
- "Fixed order" is the option `priority` with the order of the nodes. "Default" is the layout
  without it.

## 2. The four changes of 2026-11-13

"Before" has one run. "After" has two runs. All times are in ms.

| Data | Flows | Layout | Part | Before | After | Row of differences.md |
|---|---:|---|---|---:|---|---|
| lab | 5,000 | default | the layout alone | 21.1 | 4.7, 5.0 | `adapt-sankey-node-count-memo` |
| lab | 20,000 | default | the layout alone | 896.3 | 21.4, 22.3 | `adapt-sankey-node-count-memo` |
| wide | 5,000 | default | the layout alone | 80.3 | 48.9, 50.4 | `adapt-sankey-node-count-memo` |
| lab | 5,000 | fixed order | the parse | 13.6 | 7.9, 8.9 | `adapt-sankey-flow-by-index` |
| lab | 20,000 | fixed order | the parse | 134.2 | 44.0, 41.5 | `adapt-sankey-flow-by-index` |
| lab | 5,000 | fixed order | the element update | 77.8 | 16.3, 20.3 | `adapt-sankey-hover-color-keys` |
| lab | 20,000 | fixed order | the element update | 345.4 | 82.1, 79.7 | `adapt-sankey-hover-color-keys` |
| lab | 5,000 | fixed order | the draw alone | 36.8 | 21.1, 21.4 | `adapt-sankey-shared-gradients` |
| lab | 20,000 | fixed order | the draw alone | 158.0 | 90.0, 91.5 | `adapt-sankey-shared-gradients` |

The update without its draw:

| Data | Flows | Layout | Before | After |
|---|---:|---|---:|---|
| lab | 1,000 | fixed order | 19.6 | 5.0, 4.0 |
| lab | 5,000 | fixed order | 102.9 | 24.9, 30.2 |
| lab | 20,000 | fixed order | 487.0 | 127.1, 122.9 |
| lab | 5,000 | default | 116.6 | 29.7, 28.4 |
| lab | 20,000 | default | 1,356.6 | 141.7, 134.0 |
| wide | 5,000 | default | 194.8 | 89.9, 101.8 |

The frame rate did not change: 33 frames for each second at 1,000 flows and 4 at 5,000 flows. The
raster time sets it: 29.6 ms and 228 ms for each frame (section 3).

The layout change also corrects the layout of a graph with a cycle through a node with 32 or
more flows. On 3,000 random graphs, the layout before the change differed from the layout after it
for 1 graph. For that graph and for the graph of `test/port/lib/layout_test.dart`, the layout of
`src/lib/layout.ts` on Node.js v24.22.1 equals the layout after the change.

## 3. Open

Each item has a measurement and no code.

- **The raster time.** A filled path of a flow costs 26 to 46 µs on the raster thread. A solid
  color in place of the gradient changes nothing, and a flow without its stroke takes 18% less.
  The same flows drawn with `dart:ui` alone, as two paths for each flow and as one
  `Canvas.drawVertices` call for all flows:

  | Flows | Two paths for each flow | One triangle batch |
  |---:|---:|---:|
  | 1,000 | 28.6 | 1.6 |
  | 5,000 | 216.3 | 5.6 |
  | 20,000 | 1,100.2 | 14.8 |

  The batch needs a new optional canvas operation of the host. Its edges get their smoothness
  from multisampling, so it is for Impeller only.
- **The element update.** After the change, the property Map of each flow and its write by name
  take most of the time: `Map.[]=` has 43% of the samples and `Element.assign` 34%. The typed
  setters of the flow with one options object took 0.5 ms for 5,000 flows in a prototype.
- **The default layout with many nodes.** In the layout of `wide` with 5,000 flows and 2,004
  nodes, `_processRest` has 46% of the samples: for each node of a middle column, it reads each
  node. The node counts have 14%.
- **The node labels.** The paragraph cache of the host canvas holds 512 layouts. At 5,000 flows,
  the draw takes 37 ms with 72 nodes and 134 ms with 2,004 nodes.
