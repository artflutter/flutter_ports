// Original code, not ported from Chart.js: fl_chart line sample 13.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-13
import 'dart:async';

import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

typedef _Day = ({DateTime date, double max, double min, double temp});

const _names = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class const Sample13({super.key}) extends StatefulWidget {
  @override
  State<Sample13> createState() => _Sample13State();
}

class _Sample13State() extends State<Sample13> {
  List<List<_Day>>? _months;
  int _month = 0;
  int _hovered = -1;
  late double _minTemp;
  late double _maxTemp;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final text = await rootBundle.loadString(
      'assets/flchart/amsterdam_2024_weather.csv',
    );
    if (!mounted) return;
    final days = <_Day>[
      for (final line in text.trim().split('\n').skip(1))
        () {
          final cells = line.split('",')[1].split(',');
          return (
            date: DateTime.parse(cells[0]),
            max: double.parse(cells[1]),
            min: double.parse(cells[2]),
            temp: double.parse(cells[3]),
          );
        }(),
    ];
    setState(() {
      _months = [
        for (var m = 1; m <= 12; m++)
          days.where((d) => d.date.month == m).toList(),
      ];
      final temps = days.map((d) => d.temp);
      _minTemp = temps.reduce((a, b) => a < b ? a : b);
      _maxTemp = temps.reduce((a, b) => a > b ? a : b);
    });
  }

  /// The error bars of the sample, which Chart.js does not have.
  late final Map<String, Object?> _errorBars = {
    'id': 'errorBars',
    'afterDatasetsDraw': (Chart chart, Object? args, Object? options) {
      final days = _months![_month];
      final y = chart.scales['y']!;
      final elements = chart.getDatasetMeta(0).data;
      final ctx = chart.ctx!..save();
      for (var i = 0; i < days.length && i < elements.length; i++) {
        final x = elements[i].x;
        final high = y.getPixelForValue(days[i].max);
        final low = y.getPixelForValue(days[i].min);
        ctx
          ..strokeStyle = i == _hovered ? Colors.white : Fl.white38
          ..lineWidth = 1
          ..beginPath()
          ..moveTo(x, high)
          ..lineTo(x, low)
          ..moveTo(x - 2, high)
          ..lineTo(x + 2, high)
          ..moveTo(x - 2, low)
          ..lineTo(x + 2, low)
          ..stroke();
        if (i == _hovered) {
          ctx
            ..fillStyle = Colors.white
            ..font = const TextStyle(fontFamily: 'sans-serif', fontSize: 12)
            ..textAlign = TextAlign.center
            ..textBaseline = CanvasTextBaseline.bottom
            ..fillText(days[i].max.toString(), x, high - 2)
            ..textBaseline = CanvasTextBaseline.top
            ..fillText(days[i].min.toString(), x, low + 2);
        }
      }
      ctx.restore();
    },
  };

  void _hover(ChartEventDetails details) {
    final next = details.hits.isEmpty ? -1 : details.hits.first.index;
    if (next == _hovered) return;
    _hovered = next;
    details.chart.update('none');
  }

  ChartConfig _config() => fills(
    ChartConfig(
      type: .line,
      datasets: [
        LineDataset(
          points: [
            for (final (i, d) in _months![_month].indexed) DataPoint(i, d.temp),
          ],
          borderWidth: 1,
          pointRadius: 0,
          pointHoverRadius: 0,
          borderColor: const .constant(.solid(Fl.blue)),
        ),
      ],
      onHover: _hover,
      interaction: const ChartInteraction(mode: flX, intersect: false),
      tooltip: const ChartTooltip(enabled: false),
      plugins: [_errorBars],
      scales: {
        'x': LinearAxis(
          min: 0,
          max: 31,
          grid: const AxisGrid(display: false),
          extra: Fl.noBorder,
          title: const AxisTitle(
            display: true,
            text: 'Day of month',
            color: ChartPaint.solid(Fl.green),
            font: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          ticks: AxisTicks(
            stepSize: 1,
            autoSkip: false,
            maxRotation: 0,
            font: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            callback: (scale, value, index, ticks) {
              if (value == 31) return [''];
              final day = value.toInt() + 1;
              return [
                if (day % 5 == 0 || day == 1 || day - 1 == _hovered)
                  '$day'
                else
                  '',
              ];
            },
            extra: {
              'color': (JsObjectFace c) => ChartPaint.solid(
                tickOf(c) == _hovered ? Colors.white : Fl.green,
              ),
            },
          ),
        ),
        'y': LinearAxis(
          min: _minTemp - 5,
          max: _maxTemp + 5,
          grid: AxisGrid(
            drawTicks: false,
            extra: {
              'color': (JsObjectFace c) =>
                  ChartPaint.solid(tickOf(c) == 0 ? Fl.white38 : Fl.blueGrey),
              'lineWidth': (JsObjectFace c) => tickOf(c) == 0 ? 0.8 : 0.4,
            },
          ),
          extra: {
            'border': {
              'display': false,
              'dash': (JsObjectFace c) =>
                  tickOf(c) == 0 ? const <double>[] : const <double>[8, 4],
            },
          },
          ticks: AxisTicks(
            stepSize: 5,
            color: const ChartPaint.solid(Colors.white),
            callback: (scale, value, index, ticks) => ['${value.toInt()}°'],
          ),
        ),
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 18),
      const Text(
        'Amsterdam Weather 2024',
        style: TextStyle(
          color: Fl.orange,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 18),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _month > 0 ? () => setState(() => _month--) : null,
            icon: const Icon(
              Icons.navigate_before_rounded,
              color: Colors.white,
            ),
          ),
          SizedBox(
            width: 92,
            child: Text(
              _names[_month],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Fl.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _month < 11 ? () => setState(() => _month++) : null,
            icon: const Icon(Icons.navigate_next_rounded, color: Colors.white),
          ),
        ],
      ),
      const SizedBox(height: 18),
      AspectRatio(
        aspectRatio: 1.4,
        child: Padding(
          padding: const EdgeInsets.only(right: 18),
          child: _months == null
              ? const Center(child: CircularProgressIndicator())
              : ChartView(config: _config(), updateMode: 'none'),
        ),
      ),
    ],
  );
}
// #enddocregion fl_chart-13
