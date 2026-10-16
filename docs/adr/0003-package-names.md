# ADR 0003: Package names

- Status: accepted
- Date: 2026-10-16

## Context

pub.dev names are permanent once published. For Chart.js the obvious names are taken by
unrelated packages (checked 2026-10-16):

| Name | Owner and kind |
|---|---|
| `chart` | Dart 1 port of Chart.js 0.2 (2015) |
| `chartjs` | Google's archived JS-interop bindings (discontinued) |
| `chartjs2` | fork of `chartjs` |
| `chartjs_flutter` | WebView/HtmlElementView wrapper (2025) |

`chart_js` is unregistered, but pub.dev may reject it as too similar to `chartjs` (not tested).

## Decision

The Chart.js port is published as **`flutter_chartjs`**. Its gallery app is `chartjs_gallery`
(never published).

Later ports take a free `flutter_<library>` name where possible. Where that name is taken (for
example `flutter_echarts`, an ECharts WebView wrapper), the name is decided in that port's own
ADR.

## Consequences

- Workspace packages stay `publish_to: none` until their first release, so a rename before then
  costs nothing.
- The README and pub.dev description must make clear that `flutter_chartjs` is a native port, as
  the existing `chartjs_flutter` wrapper has an almost identical name.
