// Original code, not ported from Chart.js: fl_chart line sample 5.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-05
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _hours = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '23:59'];
const _values = [1.0, 2.0, 1.5, 3.0, 3.5, 5.0, 8.0];
const List<Color> _colors = [Fl.blue, Fl.pink, Fl.red];
const _stops = [0.1, 0.4, 0.9];

class const Sample5({super.key}) extends StatefulWidget {
  @override
  State<Sample5> createState() => _Sample5State();
}

class _Sample5State() extends State<Sample5> {
  final List<int> _shown = [1, 3, 5];

  /// fl_chart keeps tooltips open. The Chart.js tooltip shows one group.
  late final Map<String, Object?> _pinned = {
    'id': 'pinned',
    'afterDatasetsDraw': (Chart chart, Object? args, Object? options) {
      final area = chart.chartArea!;
      final elements = chart.getDatasetMeta(0).data;
      final ctx = chart.ctx!..save();
      for (final index in _shown) {
        final e = elements[index];
        ctx
          ..strokeStyle = Colors.pink
          ..lineWidth = 2
          ..beginPath()
          ..moveTo(e.x, e.y)
          ..lineTo(e.x, area.bottom)
          ..stroke()
          ..fillStyle = lerpStops(_colors, _stops, index / 6)
          ..strokeStyle = Colors.white
          ..beginPath()
          ..arc(e.x, e.y, 8, 0, 6.2832)
          ..fill()
          ..stroke();
        final text = _values[index].toString();
        ctx.font = const TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        );
        final width = ctx.measureText(text).width + 32;
        ctx
          ..fillStyle = Colors.pink
          ..beginPath()
          ..roundRect(e.x - width / 2, e.y - 46, width, 34, 8)
          ..fill()
          ..fillStyle = Colors.white
          ..textAlign = TextAlign.center
          ..textBaseline = CanvasTextBaseline.middle
          ..fillText(text, e.x, e.y - 29);
      }
      ctx.restore();
    },
  };

  void _click(ChartEventDetails details) {
    if (details.hits.isEmpty) return;
    final index = details.hits.first.index;
    if (!_shown.remove(index)) _shown.add(index);
    details.chart.render();
  }

  late final ChartConfig _config = fills(
    ChartConfig(
      type: .line,
      labels: _hours,
      datasets: [
        LineDataset(
          data: _values,
          tension: 0.35,
          borderWidth: 4,
          pointRadius: 0,
          fill: .origin,
          extra: {
            'borderColor': horizontalGradient(_colors, _stops),
            'backgroundColor': horizontalGradient([
              for (final c in _colors) c.withValues(alpha: 0.4),
            ]),
          },
        ),
      ],
      padding: const EdgeInsets.only(top: 12),
      onClick: _click,
      interaction: const ChartInteraction(mode: flX, intersect: false),
      tooltip: const ChartTooltip(enabled: false),
      plugins: [_pinned, areaBorder(Fl.white54)],
      scales: const {
        'x': CategoryAxis(
          grid: AxisGrid(display: false),
          extra: Fl.noBorder,
          ticks: AxisTicks(
            maxRotation: 0,
            autoSkip: false,
            color: ChartPaint.solid(Fl.pink),
            font: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        'y': LinearAxis(
          min: 0,
          grid: AxisGrid(display: false),
          extra: Fl.noBorder,
          title: AxisTitle(
            display: true,
            text: 'count',
            color: ChartPaint.solid(Colors.white),
          ),
          ticks: AxisTicks(display: false),
        ),
        'y2': LinearAxis(
          position: .right,
          grid: AxisGrid(display: false),
          extra: Fl.noBorder,
          title: AxisTitle(
            display: true,
            text: 'count',
            color: ChartPaint.solid(Colors.white),
          ),
          ticks: AxisTicks(display: false),
        ),
        'x2': CategoryAxis(
          position: .top,
          grid: AxisGrid(display: false),
          extra: Fl.noBorder,
          title: AxisTitle(
            display: true,
            text: 'Wall clock',
            color: ChartPaint.solid(Colors.white),
          ),
          ticks: AxisTicks(display: false),
        ),
      },
    ),
  );

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 2.5,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: ChartView(config: _config),
    ),
  );
}
// #enddocregion fl_chart-05
