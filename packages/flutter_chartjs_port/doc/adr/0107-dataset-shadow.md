# Chart.js ADR 0107: The dataset shadow

- Status: accepted
- Superseded in part by: [Chart.js ADR 0139](0139-typed-dataset-shadow.md)
- Date: 2026-11-10
- Related: Chart.js ADRs 0049, 0052, 0054, 0074, 0100, 0106.
- Supersedes: item 8 of Chart.js ADR 0106 ("No typed option exists for a shadow").

## Context

Chart.js ADR 0106 gave the canvas the four shadow attributes. An app could use them only through
its own plugin, with `save()` in `beforeDatasetDraw` and `restore()` in `afterDatasetDraw`. Chart.js
has no shadow option, so the typed API had none. An app that wants a shadow under a line must write
the plugin each time. fl_chart has the shadow as a parameter of the line.

## Decision

1. `Dataset` has the parameter `shadow`, a `ChartShadow`. Each of the eight dataset classes has it.
   `ChartShadow` has `color` (a `Color`, required), `blur` (the `shadowBlur` of the canvas, default
   0) and `offset` (an `Offset`, default `Offset.zero`). It is not a Chart.js option.
2. The lowering writes four plain keys into the dataset: `shadowColor`, `shadowBlur`,
   `shadowOffsetX` and `shadowOffsetY`. The names are the names of the canvas attributes. The keys
   are extras of the typed dataset scope: no `OptionKey` names them, and Chart.js reads none of
   them. `Dataset.extra` merges after them, so an entry of `extra` wins.
3. Plain values keep the data-only path of Chart.js ADRs 0074 and 0100. A nested object would
   send each update of the dataset to the full path.
4. A `ChartView.raw` dataset sets the same four keys. `shadowColor` takes a `Color`, as the other
   colors of the port do. The config check rejects another value.
5. The inline plugin `$chartView` of `ChartView` draws the shadow. Its `beforeDatasetDraw` reads the
   four keys of the dataset of the hook. When `shadowColor` is a `Color`, it calls `save()` and sets
   the attributes. Its `afterDatasetDraw` calls `restore()`. A number key with another value keeps
   the value of the context.
6. The plugin is the last inline plugin. The filler draws the area fill of a line in its own
   `beforeDatasetDraw`, before the shadow starts. Thus the fill has no shadow, as in fl_chart. The
   lines, the points, the bars and the arcs of the dataset cast the shadow.
7. The plugin reads the dataset only. The shadow does not cascade from `options.datasets` or from
   `options`.

## Consequences

- An app gets a shadow with one parameter: `LineDataset(shadow: ChartShadow(color: ...))`.
- A `Chart` with no `ChartView` has no dataset shadow. `plugins.$chartView: false` also turns the
  shadow off.
- The `afterDatasetDraw` of an inline plugin of the app runs while the shadow is still on.
- The four reads by name have a reason line in the baseline of `check:typed-reads`.
- `public_api.txt` has the new name `ChartShadow`.

## Alternatives considered

- **A nested `shadow` object in the dataset.** It reads well in a raw config. But a nested object
  is not a plain value, and each update of the dataset then takes the full path. Rejected.
- **New keys in the option schema.** The schema holds the keys of Chart.js, and its drift test
  compares them with the upstream inventory. Rejected.
- **A registered plugin.** The widget registers no component (Chart.js ADR 0048 §3), and an app
  would have to register it. Rejected.
- **Option resolution with the cascade of Chart.js.** It needs scope keys for the shadow and a
  resolver read for each dataset draw. A later change can add it if apps need it.
