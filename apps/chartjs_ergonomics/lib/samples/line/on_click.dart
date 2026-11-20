// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
class const ClickedPoint({super.key}) extends StatefulWidget {
  @override
  State<ClickedPoint> createState() => _ClickedPointState();
}

class _ClickedPointState() extends State<ClickedPoint> {
  String _clicked = 'Click a point.';

  late final ChartConfig _config = ChartConfig(
    labels: months,
    datasets: const [
      LineDataset(
        label: 'Sales',
        data: sales,
        borderColor: .constant(.solid(teal)),
        pointRadius: 6,
      ),
    ],
    onClick: _showClicked,
  );

  void _showClicked(
    ChartEvent event,
    List<ActiveElement> elements,
    Chart chart,
  ) {
    if (elements.isEmpty) return;
    final index = elements.first.index;
    setState(() => _clicked = '${months[index]}: ${sales[index]}');
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ChartView(config: _config),
      Text(_clicked),
    ],
  );
}
// #enddocregion sample
