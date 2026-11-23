// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Customized column chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-customized-column
import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _vendors = ['HP Inc', 'Lenovo', 'Dell', 'Apple', 'Asus'];
const List<num> _shipments = [12.54, 13.46, 9.18, 4.56, 5.29];
// The colors of the custom painter in the light Material 3 theme.
const List<Color> _colors = [Sf.blue, Sf.purple, Sf.slate, Sf.amber, Sf.plum];

// The custom ColumnSegment: a column with a point of 20 px on top. The
// plugin draws each column of the dataset itself and skips the rectangle.
// The shape follows the animated column.
final _pointedColumns = Plugin<Object?>(
  id: 'pointedColumns',
  beforeDatasetDraw: (chart, args, options) {
    final ctx = chart.ctx!..save();
    for (final (i, element) in args.meta.data.indexed) {
      final bar = element as BarElement;
      final left = bar.x - bar.width / 2;
      final right = bar.x + bar.width / 2;
      ctx
        ..fillStyle = _colors[i]
        ..beginPath()
        ..moveTo(left, bar.y + 20)
        ..lineTo(bar.x, bar.y)
        ..lineTo(right, bar.y + 20)
        ..lineTo(right, bar.base)
        ..lineTo(left, bar.base)
        ..closePath()
        ..fill();
    }
    ctx.restore();
    return false;
  },
);

final ChartConfig _config = ChartConfig(
  labels: _vendors,
  datasets: [
    BarDataset(
      data: const .values(_shipments),
      // The hit area and the tooltip of each column.
      backgroundColor: .indexed([for (final c in _colors) .solid(c)]),
      categoryPercentage: 0.8,
      barPercentage: 1,
    ),
  ],
  maintainAspectRatio: false,
  padding: sfPadding,
  pluginOptions: [
    sfTitle('PC vendor shipments - 2015 Q1'),
    const LegendOptions(display: false),
    sfTooltip(
      text: (item) => '${item.label.join(' ')} : ${sfNumber(sfValue(item))}M',
    ),
  ],
  plugins: [
    sfTooltipLook,
    sfPlotBorder,
    _pointedColumns,
    sfDataLabels(
      [for (final s in _shipments) '${sfNumber(s)}M'],
      align: .middle,
      fills: _colors,
    ),
  ],
  scales: [
    sfCategoryAxis(),
    // labelFormat: '{value}M', an axis title, no grid lines.
    sfValueAxis(
      min: 0,
      max: 20,
      stepSize: 5,
      callback: (scale, value, index, ticks) => ['${sfNumber(value)}M'],
      grid: false,
      line: true,
      title: 'Shipments in million',
    ),
  ],
);

class const SfCustomizedColumn({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-customized-column

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SfCustomizedColumn(),
        ),
      ),
    ),
  );
}
