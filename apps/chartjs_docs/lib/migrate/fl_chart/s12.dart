// Original code, not ported from Chart.js: fl_chart line sample 12.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-12
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

class Sample12 extends StatefulWidget {
  const Sample12({super.key});
  @override
  State<Sample12> createState() => _Sample12State();
}

class _Sample12State extends State<Sample12> {
  List<(DateTime, double)>? _history;
  List<DataPoint> _points = const [];
  bool _pan = true;
  bool _scale = true;
  double _start = 0;
  double _end = 1;
  double _gestureScale = 1;
  final List<Map<String, Object?>> _plugins = [
    touchIndicator(
      color: Fl.red,
      width: 1.5,
      dash: const [8, 2],
      fullHeight: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final text = await rootBundle.loadString(
      'assets/flchart/btc_last_year_price.json',
    );
    if (!mounted) return;
    final json = jsonDecode(text) as Map<String, dynamic>;
    final prices = [
      for (final item in (json['prices'] as List).cast<List<Object?>>())
        (
          DateTime.fromMillisecondsSinceEpoch(item[0]! as int),
          (item[1]! as num).toDouble(),
        ),
    ];
    setState(() {
      _history = prices;
      _points = [for (final (i, p) in prices.indexed) DataPoint(i, p.$2)];
      _end = prices.length - 1;
    });
  }

  double get _last => (_history?.length ?? 2) - 1.0;

  void _zoom(double factor, [double? anchor]) {
    final width = (_end - _start) / factor;
    final clamped = width.clamp(_last / 25, _last);
    final center = anchor ?? (_start + _end) / 2;
    final ratio = anchor == null ? 0.5 : (anchor - _start) / (_end - _start);
    final start = center - clamped * ratio;
    _setWindow(start, start + clamped);
  }

  void _move(double delta) => _setWindow(_start + delta, _end + delta);

  void _setWindow(double start, double end) {
    final width = end - start;
    final s = start.clamp(0.0, math.max(0.0, _last - width)).toDouble();
    setState(() {
      _start = s;
      _end = s + width;
    });
  }

  ChartConfig _config() => fills(
    clip: true,
    ChartConfig(
      type: .line,
      datasets: [
        LineDataset(
          points: _points,
          borderWidth: 1,
          pointRadius: 0,
          pointHoverRadius: 6,
          pointHoverBackgroundColor: Fl.yellow,
          borderColor: const .constant(Fl.yellow),
          fill: .start,
          extra: {
            'backgroundColor': verticalGradient(
              [
                Fl.yellow.withValues(alpha: 0.2),
                Fl.yellow.withValues(alpha: 0),
              ],
              const [0.5, 1],
            ),
          },
        ),
      ],
      animation: ChartAnimation.none,
      interaction: const ChartInteraction(
        mode: NearestInteractionMode(),
        intersect: false,
        axis: .x,
      ),
      tooltip: ChartTooltip(
        backgroundColor: Colors.black,
        displayColors: false,
        titleColor: const Color(0xFF2FCC3A),
        titleFont: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        bodyColor: Fl.yellow,
        bodyFont: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        titleText: (items) {
          final date =
              _history![((items.first.parsed! as JsObjectFace)['x']! as num)
                      .toInt()]
                  .$1;
          return '${date.year}/${date.month}/${date.day}';
        },
        labelText: (i) => '\$${i.formattedValue.split('.').first}',
      ),
      plugins: _plugins,
      scales: {
        'x': LinearAxis(
          min: _start,
          max: _end,
          grid: const AxisGrid(display: false),
          extra: Fl.noBorder,
          ticks: AxisTicks(
            maxRotation: 45,
            color: Fl.green,
            font: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            format: (t) {
              final index = t.value.toInt();
              if (_history == null || index >= _history!.length) return '';
              final date = _history![index].$1;
              return '${date.month}/${date.day}';
            },
            extra: const {'minRotation': 45},
          ),
        ),
        'y': LinearAxis(
          grid: flGrid(),
          extra: flGridDash,
          ticks: const AxisTicks(color: Colors.white),
        ),
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final step = (_end - _start) / 20;
    return Column(
      children: [
        Row(
          children: [
            const Flexible(
              child: Padding(
                padding: EdgeInsets.only(left: 52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bitcoin Price History',
                      style: TextStyle(
                        color: Fl.yellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '2023/12/19 - 2024/12/17',
                      style: TextStyle(
                        color: Fl.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  onPressed: () => _zoom(1.1),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        size: 16,
                        color: Colors.white,
                      ),
                      onPressed: () => _move(-step),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        size: 16,
                        color: Colors.white,
                      ),
                      onPressed: () => _setWindow(0, _last),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white,
                      ),
                      onPressed: () => _move(step),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.minimize,
                    size: 16,
                    color: Colors.white,
                  ),
                  onPressed: () => _zoom(0.9),
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Pan', style: TextStyle(color: Colors.white)),
            Switch(value: _pan, onChanged: (v) => setState(() => _pan = v)),
            const Text('Scale', style: TextStyle(color: Colors.white)),
            Switch(value: _scale, onChanged: (v) => setState(() => _scale = v)),
          ],
        ),
        AspectRatio(
          aspectRatio: 1.4,
          child: Padding(
            padding: const EdgeInsets.only(right: 18),
            child: LayoutBuilder(
              builder: (context, box) => Listener(
                onPointerSignal: (event) {
                  if (!_scale || event is! PointerScrollEvent) return;
                  GestureBinding.instance.pointerSignalResolver.register(
                    event,
                    (e) {
                      final d = (e as PointerScrollEvent).scrollDelta.dy;
                      _zoom(
                        d < 0 ? 1.1 : 0.9,
                        _start +
                            (_end - _start) * e.localPosition.dx / box.maxWidth,
                      );
                    },
                  );
                },
                child: GestureDetector(
                  onScaleStart: (_) => _gestureScale = 1,
                  onScaleUpdate: (d) {
                    if (_scale &&
                        d.pointerCount > 1 &&
                        d.horizontalScale != _gestureScale) {
                      _zoom(d.horizontalScale / _gestureScale);
                      _gestureScale = d.horizontalScale;
                    } else if (_pan) {
                      _move(
                        -d.focalPointDelta.dx * (_end - _start) / box.maxWidth,
                      );
                    }
                  },
                  child: _history == null
                      ? const SizedBox.expand()
                      : ChartView(config: _config(), updateMode: 'none'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion fl_chart-12
