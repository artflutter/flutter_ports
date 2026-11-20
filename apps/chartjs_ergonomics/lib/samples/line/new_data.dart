// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'dart:math';

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// #docregion sample
class const NewData({super.key}) extends StatefulWidget {
  @override
  State<NewData> createState() => _NewDataState();
}

class _NewDataState() extends State<NewData> {
  final _random = Random(7);
  List<num?> _values = sales;

  // A new List gives a new config, and the chart animates to it.
  void _shuffle() => setState(
    () => _values = [for (final _ in months) 20 + _random.nextInt(80)],
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ChartView(
        config: ChartConfig(
          type: .line,
          labels: months,
          datasets: [
            LineDataset(
              label: 'Sales',
              data: _values,
              borderColor: const .constant(.solid(teal)),
            ),
          ],
        ),
      ),
      OutlinedButton(onPressed: _shuffle, child: const Text('New data')),
    ],
  );
}
// #enddocregion sample
