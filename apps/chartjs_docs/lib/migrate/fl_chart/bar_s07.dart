// Original code, not ported from Chart.js: fl_chart bar sample 7.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-bar-07
import 'package:chartjs_docs/migrate/fl_chart/fl_bar_kit.dart';
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const List<Color> _colors = [
  Fl.yellow,
  Fl.green,
  Fl.orange,
  Fl.pink,
  Fl.blue,
  Fl.red,
];
const List<double> _values = [18, 17, 10, 2.5, 2, 2];
const List<double> _shadows = [18, 8, 15, 5, 2.5, 2];
const _shadowColor = Color(0xFFCCCCCC);
const _width = 6.0;
const _line = AxisGrid(
  drawTicks: false,
  color: ChartPaint.solid(Color(0x33FFFFFF)),
);

class const BarSample7({super.key}) extends StatefulWidget {
  @override
  State<BarSample7> createState() => _BarSample7State();
}

class _BarSample7State() extends State<BarSample7> {
  int _touched = -1;
  int _turns = 1;

  /// The bar under the pointer, as the `touchCallback` of the sample.
  late final Plugin<Object?> _touch = flTouch((bar) {
    final index = bar?.index ?? -1;
    if (index != _touched) setState(() => _touched = index);
  });

  late final Plugin<Object?> _labels = rodLabels(_label);

  /// The face icons of the groups, as glyphs of the icon font.
  List<String>? _icon(Scale scale, double value, int index, List<Tick> t) => [
    String.fromCharCode(
      (index == _touched ? Icons.face_retouching_natural : Icons.face)
          .codePoint,
    ),
  ];

  RodLabel? _label(int dataset, int index) => dataset == 0 && index == _touched
      ? RodLabel(
          _values[index].toString(),
          TextStyle(
            color: _colors[index],
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black26, blurRadius: 12)],
          ),
        )
      : null;

  /// A horizontal bar has its value in x and its group in y. The [order]
  /// sets the place of the bar in its group.
  BarDataset _rods(
    List<double> values,
    List<Color> colors, {
    required bool horizontal,
    required int order,
  }) => BarDataset(
    order: order,
    data: .points([
      for (final (i, value) in values.indexed)
        if (horizontal) DataPoint(value, i) else DataPoint(i, value),
    ]),
    backgroundColor: .indexed([for (final c in colors) .solid(c)]),
    hoverBackgroundColor: .indexed([for (final c in colors) .solid(c)]),
    // Two bars of 6 pixels with 2 pixels between them.
    barThickness: const BarThickness.pixels(_width + 2),
    maxBarThickness: _width,
    borderRadius: _width / 2,
    borderSkipped: BorderSkip.none,
  );

  /// fl_chart turns the chart by quarter turns. In Chart.js, the turn sets
  /// the index axis, the sides of the axes and their directions.
  ChartConfig _config() {
    final turn = _turns % 4;
    final horizontal = turn.isOdd;
    final groups = groupAxis(
      direction: horizontal ? .y : .x,
      count: 6,
      groupWidth: 2 * _width + 2,
      alignment: .spaceBetween,
      reservedSize: 36,
      position: const [
        ChartPosition.bottom,
        ChartPosition.left,
        ChartPosition.top,
        ChartPosition.right,
      ][turn],
      reverse: turn == 1 || turn == 2,
      ticks: AxisTicks(
        padding: 8,
        autoSkip: false,
        maxRotation: 0,
        // Chart.js clips the labels to the axis: the icon keeps its size.
        font: const TextStyle(fontFamily: 'MaterialIcons', fontSize: 28),
        callback: _icon,
        extra: {
          'color': (Object? c) => ChartPaint.solid(_colors[tickOf(c).toInt()]),
        },
      ),
    );
    final values = valueAxis(
      direction: horizontal ? .x : .y,
      min: 0,
      max: 20,
      reservedSize: 30,
      position: const [
        ChartPosition.left,
        ChartPosition.top,
        ChartPosition.right,
        ChartPosition.bottom,
      ][turn],
      reverse: turn == 2 || turn == 3,
      // The grid lines and the border lines at both ends.
      grid: _line,
      ticks: AxisTicks(
        padding: 8,
        autoSkip: false,
        maxRotation: 0,
        color: const .solid(Fl.white38),
        font: const TextStyle(fontSize: 14),
        callback: flTitles(),
      ),
    );
    return flBars(
      ChartConfig(
        indexAxis: horizontal ? const YAxis() : const XAxis(),
        datasets: [
          // A half turn or more puts the shadow bar first in the group.
          _rods(
            _values,
            _colors,
            horizontal: horizontal,
            order: turn < 2 ? 0 : 1,
          ),
          _rods(
            _shadows,
            List.filled(6, _shadowColor),
            horizontal: horizontal,
            order: turn < 2 ? 1 : 0,
          ),
        ],
        tooltip: const ChartTooltip(enabled: false),
        plugins: [_labels, _touch],
        scales: horizontal ? [values, groups] : [groups, values],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 48),
            const Expanded(
              child: Text(
                'Horizontal Bar Chart',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            IconButton(
              tooltip: 'Rotate the chart 90 degrees (cw)',
              onPressed: () => setState(() => _turns++),
              icon: RotatedBox(
                quarterTurns: _turns - 1,
                child: const Icon(
                  Icons.rotate_90_degrees_cw,
                  color: Fl.white70,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AspectRatio(
          aspectRatio: 1.4,
          child: OverflowChart(config: _config(), updateMode: UpdateMode.none),
        ),
      ],
    ),
  );
}
// #enddocregion fl_chart-bar-07

void main() {
  Chart.register(registerables);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Fl.item,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: ChartTheme(
            data: const ChartThemeData.dark(),
            // The fl_chart gallery shows each sample in a card of at most
            // 600 pixels.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: const BarSample7(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
