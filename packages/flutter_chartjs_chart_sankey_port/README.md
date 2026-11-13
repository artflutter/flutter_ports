# flutter_chartjs_chart_sankey_port

A native Dart port of [chartjs-chart-sankey](https://github.com/kurkle/chartjs-chart-sankey) for
[`flutter_chartjs_port`](https://github.com/artflutter/flutter_ports/tree/main/packages/flutter_chartjs_port),
the native Dart port of Chart.js. The port translates the sankey controller, the flow element and
the node layout to Dart. The chart runs on the Dart chart of `flutter_chartjs_port`. The package
uses no WebView, no JavaScript and no network access at runtime.

> **Status:** work in progress. Each module of the chart type is ported, and the upstream unit
> tests and specs pass. It is not published. The plan, the roadmap and the decisions are in
> [doc/README.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_chart_sankey_port/doc/README.md).

The port also tests the public API of the Chart.js port for a chart type of another package. The
controller and the element use only the public libraries of `flutter_chartjs_port`.
[doc/host-seams.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_chart_sankey_port/doc/host-seams.md)
lists each place where the chart type needs a part of the host port.

## Use

Register the controller and the element once. Then give a chart the type `sankey`.

```dart
Chart.register(sankeyRegisterables);

ChartView.raw(
  config: <String, Object?>{
    'type': 'sankey',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            const SankeyDataPoint(from: 'Coal', to: 'Energy', flow: 25),
            const SankeyDataPoint(from: 'Gas', to: 'Energy', flow: 20),
            const SankeyDataPoint(from: 'Energy', to: 'Heat', flow: 45),
          ],
        },
      ],
    },
  },
);
```

An option that is a keyword in JavaScript is an enum here, for example
`'orientation': SankeyOrientation.vertical`. A color is a `ChartPaint` of the host.

## Upstream

The port tracks chartjs-chart-sankey **0.19.1** (`chartjsChartSankeyVersion`). A git submodule
under `third_party/` pins the repository at the release tag.
[tool/port_sources.yaml](tool/port_sources.yaml) gives the pin with its license and holder.

## License

MIT, the license of chartjs-chart-sankey. [LICENSE](LICENSE) keeps the notice of Jukka Kurkela with
the notice of the port. This project is not affiliated with the Chart.js project.
