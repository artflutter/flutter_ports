// Original code, not ported from Chart.js: fl_chart line sample 1.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-01
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

LineDataset _line(
  Color color,
  double width,
  List<DataPoint> points, {
  double tension = 0.35,
  bool dots = false,
  ChartFill? fill,
  Color? fillColor,
}) => LineDataset(
  points: points,
  borderColor: .constant(color),
  backgroundColor: fillColor == null ? null : .constant(fillColor),
  borderWidth: width,
  tension: tension,
  fill: fill,
  pointRadius: dots ? 4 : 0,
  pointBackgroundColor: color,
  pointHoverRadius: 8,
  pointHoverBackgroundColor: color,
  borderCapStyle: StrokeCap.round,
);

List<DataPoint> _p(List<(num, num)> s) => [
  for (final (x, y) in s) DataPoint(x, y),
];

final List<LineDataset> _first = [
  _line(
    Fl.green,
    8,
    _p([(1, 1), (3, 1.5), (5, 1.4), (7, 3.4), (10, 2), (12, 2.2), (13, 1.8)]),
  ),
  _line(
    Fl.pink,
    8,
    _p([(1, 1), (3, 2.8), (7, 1.2), (10, 2.8), (12, 2.6), (13, 3.9)]),
  ),
  _line(Fl.cyan, 8, _p([(1, 2.8), (3, 1.9), (6, 3), (10, 1.3), (13, 2.5)])),
];

final List<LineDataset> _second = [
  _line(
    Fl.green.withValues(alpha: 0.5),
    4,
    _p([(1, 1), (3, 4), (5, 1.8), (7, 5), (10, 2), (12, 2.2), (13, 1.8)]),
    tension: 0,
  ),
  _line(
    Fl.pink.withValues(alpha: 0.5),
    4,
    _p([(1, 1), (3, 2.8), (7, 1.2), (10, 2.8), (12, 2.6), (13, 3.9)]),
    fill: .origin,
    fillColor: Fl.pink.withValues(alpha: 0.2),
  ),
  _line(
    Fl.cyan.withValues(alpha: 0.5),
    2,
    _p([(1, 3.8), (3, 1.9), (6, 5), (10, 3.3), (13, 4.5)]),
    tension: 0,
    dots: true,
  ),
];

String? _bottom(AxisTickInfo t) => switch (t.value.toInt()) {
  2 => 'SEPT',
  7 => 'OCT',
  12 => 'DEC',
  _ => '',
};

String? _left(AxisTickInfo t) => switch (t.value.toInt()) {
  1 => '1m',
  2 => '2m',
  3 => '3m',
  4 => '5m',
  5 => '6m',
  _ => '',
};

ChartConfig _config(bool main) => fills(
  ChartConfig(
    type: .line,
    datasets: main ? _first : _second,
    animation: const ChartAnimation(duration: Duration(milliseconds: 250)),
    interaction: const ChartInteraction(mode: flX, intersect: false),
    tooltip: main
        ? ChartTooltip(
            backgroundColor: Fl.blueGrey.withValues(alpha: 0.8),
            displayColors: false,
            titleText: (_) => null,
            labelText: (i) => i.formattedValue,
          )
        : const ChartTooltip(enabled: false),
    plugins: [_indicator],
    scales: {
      'x': LinearAxis(
        min: 0,
        max: 14,
        grid: const AxisGrid(display: false),
        extra: {
          'border': {'color': Fl.cyan.withValues(alpha: 0.2), 'width': 4},
        },
        ticks: const AxisTicks(
          stepSize: 1,
          autoSkip: false,
          maxRotation: 0,
          color: Colors.white,
          font: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          format: _bottom,
        ),
      ),
      'y': LinearAxis(
        min: 0,
        max: main ? 4 : 6,
        grid: const AxisGrid(display: false),
        extra: Fl.noBorder,
        ticks: const AxisTicks(
          stepSize: 1,
          autoSkip: false,
          color: Colors.white,
          font: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          format: _left,
        ),
      ),
    },
  ),
);

final Map<String, Object?> _indicator = touchIndicator();
final ChartConfig _mainConfig = _config(true);
final ChartConfig _otherConfig = _config(false);

class Sample1 extends StatefulWidget {
  const Sample1({super.key});
  @override
  State<Sample1> createState() => _Sample1State();
}

class _Sample1State extends State<Sample1> {
  bool _main = true;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.23,
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 37),
            const Text(
              'Monthly Sales',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Fl.cyan,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 37),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16, left: 6),
                child: ChartView(config: _main ? _mainConfig : _otherConfig),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: Colors.white.withValues(alpha: _main ? 1 : 0.5),
          ),
          onPressed: () => setState(() => _main = !_main),
        ),
      ],
    ),
  );
}
// #enddocregion fl_chart-01
