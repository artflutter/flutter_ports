// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Dynamic update animation" (bar).
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-animation-bar
import 'dart:async';
import 'dart:math' as math;

import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

class const SfAnimationBar({super.key}) extends StatefulWidget {
  @override
  State<SfAnimationBar> createState() => _SfAnimationBarState();
}

class _SfAnimationBarState() extends State<SfAnimationBar> {
  final math.Random _random = math.Random();
  late List<num> _values = _next();
  Timer? _timer;

  // 7 random values from 10 to 94.
  List<num> _next() => [for (var i = 0; i < 7; i++) 10 + _random.nextInt(85)];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => setState(() => _values = _next()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 320,
    child: ChartView(
      config: ChartConfig(
        indexAxis: const YAxis(),
        labels: const ['1', '2', '3', '4', '5', '6', '7'],
        datasets: [
          BarDataset(
            data: _values,
            backgroundColor: const .constant(.solid(Sf.blue)),
            categoryPercentage: 0.7,
            barPercentage: 1,
          ),
        ],
        maintainAspectRatio: false,
        padding: sfPadding,
        legend: const ChartLegend(display: false),
        tooltip: const ChartTooltip(enabled: false),
        animation: const ChartAnimation(duration: Duration(milliseconds: 1500)),
        extra: const {'events': <String>[]},
        scales: [
          sfCategoryAxis(direction: .y, reverse: true),
          sfValueAxis(
            direction: .x,
            min: 0,
            max: 100,
            stepSize: 10,
            grid: false,
            line: true,
            ticks: true,
          ),
        ],
      ),
    ),
  );
}
// #enddocregion sf-animation-bar

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SfAnimationBar(),
        ),
      ),
    ),
  );
}
