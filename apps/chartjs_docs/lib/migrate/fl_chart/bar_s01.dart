// Original code, not ported from Chart.js: fl_chart bar sample 1.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-bar-01
import 'dart:async';
import 'dart:math' as math;

import 'package:chartjs_docs/migrate/fl_chart/fl_bar_kit.dart';
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _days = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _values = [5.0, 6.5, 5.0, 7.5, 9.0, 11.5, 6.5];
const List<Color> _playColors = [
  Fl.purple,
  Fl.yellow,
  Fl.blue,
  Fl.orange,
  Fl.pink,
  Fl.red,
];
const _width = 22.0;

/// `Colors.white.darken()` and `Fl.green.darken()` of the sample.
const _grey = Color(0xFF999999);
const _darkGreen = Color(0xFF23992C);
const _touchedBorder = Color(0xFF0C330F);

/// The background rods of fl_chart (`backDrawRodData`): a rounded rect from 0
/// to 20 behind each bar.
final Plugin<Object?> _backRods = Plugin(
  id: 'backRods',
  beforeDatasetsDraw: (chart, args, options) {
    final y = chart.scales['y']!;
    final top = y.getPixelForValue(20);
    final bottom = y.getPixelForValue(0);
    final ctx = chart.ctx!
      ..save()
      ..fillStyle = _grey.withValues(alpha: 0.3);
    for (final element in chart.getDatasetMeta(0).data) {
      final bar = element as BarElement;
      ctx
        ..beginPath()
        ..roundRect(
          bar.x - bar.width / 2,
          top,
          bar.width,
          bottom - top,
          bar.width / 2,
        )
        ..fill();
    }
    ctx.restore();
    return true;
  },
);

class const BarSample1({super.key}) extends StatefulWidget {
  @override
  State<BarSample1> createState() => _BarSample1State();
}

class _BarSample1State() extends State<BarSample1> {
  final _random = math.Random();
  int _touched = -1;
  Timer? _timer;
  List<double> _played = _values;
  List<Color> _playedColors = List.filled(7, Colors.white);

  bool get _playing => _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() => setState(() {
    if (_playing) {
      _timer!.cancel();
      _timer = null;
      return;
    }
    _touched = -1;
    _shuffle();
    _timer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => setState(_shuffle),
    );
  });

  void _shuffle() {
    _played = [for (var i = 0; i < 7; i++) _random.nextInt(15) + 6.0];
    _playedColors = [
      for (var i = 0; i < 7; i++)
        _playColors[_random.nextInt(_playColors.length)],
    ];
  }

  /// The bar under the pointer, as the `touchCallback` of the sample.
  late final Plugin<Object?> _touch = flTouch((bar) {
    final index = _playing ? -1 : bar?.index ?? -1;
    if (index != _touched) setState(() => _touched = index);
  });

  ChartConfig _config() {
    final values = _playing ? _played : _values;
    final fills = _playing
        ? _playedColors
        : [
            for (var i = 0; i < 7; i++)
              if (i == _touched) Fl.green else Colors.white,
          ];
    final colors = [for (final color in fills) ChartPaint.solid(color)];
    final borders = [
      for (final (i, color) in fills.indexed)
        ChartPaint.solid(i == _touched ? _touchedBorder : color),
    ];
    return flBars(
      ChartConfig(
        type: .bar,
        datasets: [
          BarDataset(
            points: [
              for (final (i, value) in values.indexed)
                // The touched bar grows by 1, as in the sample.
                DataPoint(i, i == _touched ? value + 1 : value),
            ],
            backgroundColor: .indexed(colors),
            hoverBackgroundColor: .indexed(colors),
            borderColor: .indexed(borders),
            hoverBorderColor: .indexed(borders),
            borderWidth: _touched < 0 ? 0 : 1,
            barThickness: _width,
            borderRadius: _width / 2,
            extra: const {'borderSkipped': false},
          ),
        ],
        animation: const ChartAnimation(
          duration: Duration(milliseconds: 250),
          easing: Curves.linear,
        ),
        tooltip: ChartTooltip(
          enabled: !_playing,
          backgroundColor: const .solid(Fl.blueGrey),
          displayColors: false,
          cornerRadius: 4,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          // fl_chart puts the tooltip right of the bar, 10 pixels into it.
          xAlign: TooltipXAlign.left,
          yAlign: TooltipYAlign.bottom,
          titleColor: const .solid(Colors.white),
          titleFont: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          bodyColor: const .solid(Colors.white),
          bodyFont: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          callbacks: TooltipCallbacks(
            title: (tooltip, items) => [_days[items.first.dataIndex]],
            label: (tooltip, item) => [
              _values[item.dataIndex].toStringAsFixed(1),
            ],
          ),
          extra: const {
            'caretSize': 0,
            'caretPadding': -10,
            'titleMarginBottom': 4,
            'titleAlign': TextAlign.center,
            'bodyAlign': TextAlign.center,
          },
        ),
        plugins: [_backRods, _touch],
        scales: {
          'x': groupAxis(
            count: 7,
            groupWidth: _width,
            reservedSize: 38,
            ticks: AxisTicks(
              padding: 16,
              color: const .solid(Colors.white),
              font: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              callback: (scale, value, index, ticks) => [_letters[index]],
            ),
          ),
          'y': valueAxis(min: 0, max: 20),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Mingguan',
                style: TextStyle(
                  color: Fl.green,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Grafik konsumsi kalori',
                style: TextStyle(
                  color: _darkGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 38),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ChartView(config: _config()),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(
                _playing ? Icons.pause : Icons.play_arrow,
                color: Fl.green,
              ),
              onPressed: _play,
            ),
          ),
        ),
      ],
    ),
  );
}
// #enddocregion fl_chart-bar-01
