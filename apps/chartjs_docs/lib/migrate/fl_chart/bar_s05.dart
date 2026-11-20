// Original code, not ported from Chart.js: fl_chart bar sample 5.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-bar-05
import 'package:chartjs_docs/migrate/fl_chart/fl_bar_kit.dart';
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// The four stack items of each day.
const List<List<double>> _items = [
  [2, 3, 2.5, 8],
  [-1.8, -2.7, -3, -6.5],
  [1.5, 2, 3.5, 6],
  [1.5, 1.5, 4, 6.5],
  [-2, -2, -5, -9],
  [-1.2, -1.5, -4.3, -10],
  [1.2, 4.8, 5, 5],
];
const _width = 22.0;
const _shadow = 0.2;
const _white = TextStyle(color: Colors.white, fontSize: 10);

/// `Colors.blueGrey.darken(15)`, the tooltip color of fl_chart.
const _tooltipColor = Color(0xFF526A76);

/// The end of the rod of the hovered day: the end of its last item. The
/// tooltip stands above a rod that grows up, and below one that grows down.
final class const _RodEnd() extends TooltipPositioner {
  @override
  TooltipPosition? positionOf(
    TooltipModel tooltip,
    List<ActiveElement> items,
    Object? eventPosition,
  ) {
    if (items.isEmpty) return null;
    final meta = tooltip.chart.getDatasetMeta(3);
    final end = meta.data[items.first.index] as BarElement;
    return TooltipPosition()
      ..x = end.x
      ..y = end.y
      ..xAlign = TooltipXAlign.center
      ..yAlign = end.y <= end.base ? TooltipYAlign.bottom : TooltipYAlign.top;
  }
}

class const BarSample5({super.key}) extends StatefulWidget {
  @override
  State<BarSample5> createState() => _BarSample5State();
}

class _BarSample5State() extends State<BarSample5> {
  int _touched = -1;

  /// The rod under the pointer. Datasets 0 to 3 are the items of the rod, 4
  /// to 7 its mirror image, which the sample does not select.
  late final Plugin<Object?> _touch = flTouch((bar) {
    final index = bar == null || bar.datasetIndex > 3 ? -1 : bar.index;
    if (index != _touched) setState(() => _touched = index);
  });

  /// The colors of an item. fl_chart paints a gradient in the rect of the
  /// item, from its top left to its bottom right corner.
  ChartPaint _fill(ScriptableContext context) {
    final dataset = context.datasetIndex ?? 0;
    final index = context.dataIndex;
    if (index == null) return const .solid(Fl.blue);
    final item = dataset % 4;
    final mirror = dataset > 3;
    final alpha = index == _touched ? _shadow * 2 : _shadow;
    final colors = <Color>[
      ...switch (item) {
        0 when mirror => [
          for (final c in [Colors.white, Fl.green, Fl.cyan])
            c.withValues(alpha: alpha),
        ],
        0 => [
          Colors.white.withValues(alpha: 0.8),
          Fl.green.withValues(alpha: 0.5),
          Fl.cyan.withValues(alpha: 0.2),
        ],
        2 when mirror => [
          Fl.purple.withValues(alpha: alpha),
          Fl.red.withValues(alpha: index == _touched ? alpha - 0.1 : alpha),
          Fl.orange.withValues(alpha: index == _touched ? alpha - 0.2 : alpha),
        ],
        2 => [
          Fl.purple,
          Fl.red.withValues(alpha: 0.9),
          Fl.orange.withValues(alpha: 0.8),
        ],
        1 => [Fl.yellow.withValues(alpha: mirror ? alpha : 1)],
        _ => [Fl.blue.withValues(alpha: mirror ? alpha : 1)],
      },
    ];
    // fl_chart paints the rod in its own color, cyan, under the items of the
    // rod. The mirror rod is transparent.
    if (!mirror) {
      for (final (i, color) in colors.indexed) {
        colors[i] = Color.alphaBlend(color, Colors.cyan);
      }
    }
    if (colors.length == 1) return .solid(colors.single);
    // The rect of the item: from the sum of the items below it to its end.
    final values = _items[index];
    final sign = mirror ? -1 : 1;
    final from = values.take(item).fold<double>(0, (a, b) => a + b) * sign;
    final to = from + values[item] * sign;
    final x = context.chart.scales['x']!.getPixelForValue(index.toDouble());
    final y = context.chart.scales['y']!;
    final (top, bottom) = (y.getPixelForValue(from), y.getPixelForValue(to));
    return ChartGradient.linear(
      Offset(x - _width / 2, top < bottom ? top : bottom),
      Offset(x + _width / 2, top < bottom ? bottom : top),
      colors,
      stops: item == 0 ? const [0.1, 0.4, 0.9] : const [0, 0.5, 1],
    );
  }

  /// The letters of the items of the touched day, when they fit.
  late final Plugin<Object?> _letters = Plugin(
    id: 'stackLabels',
    afterDatasetsDraw: (chart, args, options) {
      if (_touched < 0) return;
      final ctx = chart.ctx!
        ..save()
        ..font = const TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 12,
          fontWeight: FontWeight.bold,
        )
        ..fillStyle = Colors.white
        ..textAlign = TextAlign.center
        ..textBaseline = CanvasTextBaseline.middle;
      for (var dataset = 0; dataset < 8; dataset++) {
        final bar = chart.getDatasetMeta(dataset).data[_touched] as BarElement;
        if ((bar.y - bar.base).abs() <= 14) continue;
        ctx.fillText('ABCD'[dataset % 4], bar.x, (bar.y + bar.base) / 2);
      }
      ctx.restore();
    },
  );

  /// The horizontal grid of fl_chart: a line at each step of the fl_chart
  /// interval that is a multiple of 5, but not at the ends.
  bool _gridAt(Object? context) {
    final value = tickOf(context);
    final scale = (context! as ScriptableScaleContext).scale! as Scale;
    final step = flInterval(scale.height, 40);
    return value.abs() < 20 && value % step == 0 && value % 5 == 0;
  }

  List<String>? _label(Scale scale, double value, int index, List<Tick> t) => [
    if (value == 0) '0' else '${value.toInt()}0k',
  ];

  BarDataset _rod(int item, {required bool mirror}) => BarDataset(
    points: [
      for (final (day, values) in _items.indexed)
        DataPoint(day, mirror ? -values[item] : values[item]),
    ],
    stack: mirror ? 'mirror' : 'rod',
    // The rod and its mirror image share the place of the day.
    grouped: false,
    barThickness: const BarThickness.pixels(_width),
    borderRadius: 6,
    backgroundColor: .resolver(_fill),
    hoverBackgroundColor: .resolver(_fill),
    borderColor: const .constant(.solid(Colors.white)),
    hoverBorderColor: const .constant(.solid(Colors.white)),
    extra: {
      'borderWidth': [
        for (var day = 0; day < 7; day++)
          if (day == _touched && !mirror) 2.0 else 0.0,
      ],
    },
  );

  AxisTicks _titles({double padding = 8, double rotation = 0}) => AxisTicks(
    padding: padding,
    autoSkip: false,
    color: const .solid(Colors.white),
    font: _white,
    crossAlign: rotation == 0 ? null : TickCrossAlign.center,
    callback: _label,
    extra: rotation == 0 ? null : {'minRotation': -rotation},
  );

  ChartConfig _config() {
    final days = AxisTicks(
      padding: 8,
      color: const .solid(Colors.white),
      font: _white,
      callback: (scale, value, index, ticks) => [_days[index]],
    );
    return flBars(
      ChartConfig(
        datasets: [
          for (var item = 0; item < 4; item++) _rod(item, mirror: false),
          for (var item = 0; item < 4; item++) _rod(item, mirror: true),
        ],
        // fl_chart shows the tooltip of the touched rod at its end.
        tooltip: ChartTooltip(
          position: const _RodEnd(),
          backgroundColor: const .solid(_tooltipColor),
          bodyColor: const .solid(Colors.cyan),
          bodyFont: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          displayColors: false,
          cornerRadius: 4,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          filter: (item, index, items, data) => item.datasetIndex < 4,
          callbacks: TooltipCallbacks(
            title: (tooltip, items) => const [],
            label: (tooltip, item) => [
              _items[item.dataIndex].reduce((a, b) => a + b).toString(),
            ],
          ),
          extra: const {
            'caretSize': 0,
            'caretPadding': 16,
            'bodyAlign': TextAlign.center,
          },
        ),
        plugins: [_letters, _touch],
        scales: [
          groupAxis(
            count: 7,
            groupWidth: _width,
            alignment: .center,
            groupsSpace: 12,
            reservedSize: 32,
            ticks: days,
          ),
          groupAxis(
            count: 7,
            groupWidth: _width,
            alignment: .center,
            groupsSpace: 12,
            reservedSize: 32,
            position: .top,
            ticks: days,
          ),
          // The vertical grid of fl_chart: 10 dashed lines over the width.
          valueAxis(
            direction: .x,
            min: 0,
            max: 1,
            position: .bottom,
            grid: flGrid(show: (v) => v > 0 && v < 1),
            border: flGridDash,
            ticks: const AxisTicks(display: false),
          ),
          valueAxis(
            min: -20,
            max: 20,
            interval: 5,
            reservedSize: 42,
            stacked: true,
            grid: AxisGrid(
              drawTicks: false,
              extra: {
                'color': (Object? c) => ChartPaint.solid(
                  !_gridAt(c)
                      ? Colors.transparent
                      : Colors.white.withValues(
                          alpha: tickOf(c) == 0 ? 0.1 : 0.05,
                        ),
                ),
                'lineWidth': (Object? c) => tickOf(c) == 0 ? 3.0 : 0.8,
              },
            ),
            // Chart.js turns all the labels of an axis by one angle.
            ticks: _titles(padding: 4, rotation: 45),
          ),
          valueAxis(
            min: -20,
            max: 20,
            interval: 5,
            reservedSize: 42,
            position: .right,
            ticks: _titles(padding: 0, rotation: 90),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 0.8,
    child: Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ChartView(config: _config()),
    ),
  );
}
// #enddocregion fl_chart-bar-05

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
                child: const BarSample5(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
