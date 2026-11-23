// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Dynamic update animation" (column).
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-animation-column
import 'dart:async';
import 'dart:math' as math;

import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

class const SfAnimationColumn({super.key}) extends StatefulWidget {
  @override
  State<SfAnimationColumn> createState() => _SfAnimationColumnState();
}

class _SfAnimationColumnState() extends State<SfAnimationColumn> {
  final math.Random _random = math.Random();
  late List<num> _values = _next();
  Timer? _timer;

  // 7 random values from 0 to 99.
  List<num> _next() => [for (var i = 0; i < 7; i++) _random.nextInt(100)];

  @override
  void initState() {
    super.initState();
    // Each 2 seconds a new data List: the columns grow or shrink to it.
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
        // The x values 1 to 7 on a CategoryAxis.
        labels: const ['1', '2', '3', '4', '5', '6', '7'],
        datasets: [
          BarDataset(
            data: .values(_values),
            backgroundColor: const .constant(.solid(Sf.blue)),
            categoryPercentage: 0.7,
            barPercentage: 1,
          ),
        ],
        maintainAspectRatio: false,
        padding: sfPadding,
        legend: const ChartLegend(display: false),
        tooltip: const ChartTooltip(enabled: false),
        // The default animationDuration of a series.
        animation: const ChartAnimation(duration: Duration(milliseconds: 1500)),
        // The original has no tooltip.
        events: const [],
        scales: [sfCategoryAxis(), sfValueAxis(min: 0, max: 100, stepSize: 20)],
      ),
    ),
  );
}
// #enddocregion sf-animation-column

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SfAnimationColumn(),
        ),
      ),
    ),
  );
}
