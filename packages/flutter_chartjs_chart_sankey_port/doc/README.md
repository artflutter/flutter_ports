# chartjs-chart-sankey port

`packages/flutter_chartjs_chart_sankey_port` is a native Dart port of
[chartjs-chart-sankey](https://github.com/kurkle/chartjs-chart-sankey), the sankey chart type for
Chart.js. The chart type runs on the Chart.js port `packages/flutter_chartjs_port`. It is the
second add-on port of the repository ([ADR 0009](../../../docs/adr/0009-add-on-ports.md)) and the
first chart type of another package. The port has two goals: the sankey chart for Flutter apps,
and a test of the public API of the Chart.js port for a controller and an element of another
package.

- **Upstream:** chartjs-chart-sankey, MIT, the release `v0.19.1` (2026-09-12)
  ([Sankey ADR 0001](adr/0001-upstream-sources.md)).
  - `third_party/chartjs-chart-sankey` is the shallow git submodule.
    [`tool/port_sources.yaml`](../tool/port_sources.yaml) gives the commit, the license and the
    holder.
  - `chartjsChartSankeyVersion` in `lib/src/upstream.dart` gives the version.
- **Host:** `flutter_chartjs_port`, a path dependency. The port imports only its public libraries
  ([Sankey ADR 0003](adr/0003-host-connection.md)).
  [Chart.js ADR 0132](../../flutter_chartjs_port/doc/adr/0132-exports-for-add-on-chart-types.md) is
  the host change for this port.
- **Host seams:** [host-seams.md](host-seams.md) lists each place where a chart type of another
  package needs a part of the host. 13 seams connect, 7 need a Dart form in this port that the host
  API can remove, and 2 are gaps: the typed config has no dataset class of another package,
  and the theme has no extension for its colors.
- **Progress:** [parity.md](parity.md), one row for each upstream file.
- **Differences:** [differences.md](differences.md), one row for each `DIVERGES` difference.
- **Performance:** [performance.md](performance.md), the figures of each form that is faster than
  the upstream lines, and the open items.
- **Upstream after the pin:** [upstream-ledger.md](upstream-ledger.md).
- **Prior art:** [prior-art/README.md](prior-art/README.md), the survey of the sankey code of
  other Dart and Flutter packages (2026-11-13). No Dart port of this library exists. Prior art is
  never a source (AGENTS.md rule 1).
- **Test harness:** `packages/chartjs_test_utils`, a dev dependency (ADR 0009 item 7).
- **License:** MIT, as upstream ([LICENSE](../LICENSE)).

## Use

```dart
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// Once, before the first sankey chart.
Chart.register(sankeyRegisterables);

final chart = ChartView.raw(
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
          'colorFrom': const ChartPaint.solid(Color(0xFF4E79A7)),
          'colorTo': const ChartPaint.solid(Color(0xFFF28E2B)),
          'orientation': SankeyOrientation.horizontal,
          'nodePadding': <String, Object?>{
            'Energy': const SankeyNodeGap(before: 20),
          },
          'nodeMinSize': (SankeyNode node) => node.inFlow == 0 ? 6 : 0,
        },
      ],
    },
  },
);
```

## Roadmap

| Phase | Content | State |
|---|---|---|
| 0 | The pin, the name, the license, the scaffold, the prior-art survey, Sankey ADRs 0001-0003 | done (2026-11-13) |
| 1 | The pure modules (`types`, `lib/helpers`, `lib/core`, `lib/layout`) with their unit tests | done (2026-11-13) |
| 2 | `labels`, `flow`, `controller` and `index.esm` on the public libraries of the host, with Chart.js ADR 0132; the specs | done (2026-11-13) |
| 3 | The 44 fixtures against the JavaScript chart: each number of the nodes, the flows and the draw calls is equal | done (2026-11-13) |
| 4 | The gallery page | done (2026-11-13) |
| 5 | The typed config (seam S9) and the theme extension (seam S15), each after its Chart.js ADR; the other seams, with the work on the public API of the host | next |
