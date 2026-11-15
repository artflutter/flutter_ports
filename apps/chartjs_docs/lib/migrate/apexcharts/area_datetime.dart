// Original code, not ported from Chart.js: a replica of the apexcharts_flutter demo "Area — Datetime (zoom / pan · range buttons)".
// ignore_for_file: public_member_api_docs
// #docregion apex-area-datetime
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts/area_datetime_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

DateTime _date(String text) => DateTime.parse(text);

double _ms(String text) => _date(text).millisecondsSinceEpoch.toDouble();

/// One annotation: a dashed line at a value of the x or the y axis, with a
/// label of white text on its background color.
typedef _Annotation = ({
  String axis,
  double value,
  String text,
  Color background,
});

const List<_Annotation> _annotations = [
  (axis: 'y', value: 30, text: 'Support', background: Apex.green),
  // 14 Nov 2012.
  (axis: 'x', value: 1352847600000, text: 'Rally', background: Apex.purple),
];

// annotations.yaxis and annotations.xaxis: an inline plugin that draws the
// lines and the labels after the datasets.
final _annotationPlugin = Plugin<Object?>(
  id: 'apexAnnotations',
  afterDatasetsDraw: (chart, args, options) {
    final c = chart as Chart;
    final area = c.chartArea!;
    final ctx = c.ctx!
      ..save()
      ..beginPath()
      ..rect(area.left, 0, area.width, c.height)
      ..clip()
      ..font = toFont(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      )
      ..textBaseline = CanvasTextBaseline.top
      ..textAlign = TextAlign.left;
    for (final note in _annotations) {
      final scale = c.scales[note.axis]!;
      final at = scale.getPixelForValue(note.value);
      final vertical = note.axis == 'x';
      if (vertical
          ? at < area.left || at > area.right
          : at < area.top || at > area.bottom) {
        continue;
      }
      ctx
        ..strokeStyle = const Color(0xFF999999)
        ..lineWidth = 1
        ..setLineDash(const [5, 4])
        ..beginPath()
        ..moveTo(vertical ? at : area.left, vertical ? area.top : at)
        ..lineTo(vertical ? at : area.right, vertical ? area.bottom : at)
        ..stroke()
        ..setLineDash(const []);
      // A pill: on the top of an x line, at the right end of a y line.
      final width = ctx.measureText(note.text).width + 12;
      const height = 13.2 + 6;
      final left = vertical ? at - width / 2 : area.right - 4 - width;
      final top = vertical ? area.top + 2 : at;
      ctx
        ..fillStyle = note.background
        ..beginPath()
        ..roundRect(left, top, width, height, 2)
        ..fill()
        ..fillStyle = Colors.white
        ..fillText(note.text, left + 6, top + 3);
    }
    ctx.restore();
  },
);

ChartConfig _config(ApexZoom zoom) => ChartConfig(
  type: .line,
  datasets: [
    LineDataset(
      label: 'STOCK ABC',
      points: [
        for (final (ms, value) in stockAbc)
          DataPoint.time(DateTime.fromMillisecondsSinceEpoch(ms), value),
      ],
      borderColor: const .constant(.solid(Apex.blue)),
      // fill: {type: 'gradient', gradient: {shadeIntensity: 1,
      // opacityFrom: 0.7, opacityTo: 0.9}}: blue on the top, white on the
      // bottom.
      backgroundColor: apexAreaFill(Apex.blue, from: 0.7, to: 0.9, shade: 1),
      fill: .toStart,
      borderWidth: 2,
      borderJoinStyle: StrokeJoin.round,
      pointRadius: 0,
      pointHoverRadius: 0,
    ),
  ],
  maintainAspectRatio: false,
  padding: apexPadding,
  legend: const ChartLegend(display: false),
  // tooltip.x.format: 'dd MMM yyyy'.
  tooltip: apexTooltip(),
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  animation: apexAnimation,
  plugins: apexZoomPlugins([_annotationPlugin, apexHover, apexTooltipLook]),
  pluginOptions: [zoom.options],
  scales: {
    // xaxis: {type: 'datetime', min: 1 Mar 2012, tickAmount: 6}: at most 7
    // labels at the starts of the days, the months or the years.
    'x': TimeAxis(
      min: _date('2012-03-01'),
      tooltipFormat: 'dd MMM yyyy',
      grid: const AxisGrid(display: false, drawTicks: false),
      ticks: const AxisTicks(
        color: .solid(Apex.label),
        font: apexLabelFont,
        padding: 8,
        maxRotation: 0,
        extra: {'maxTicksLimit': 7},
      ),
      border: const AxisBorder(display: false),
      extra: const {
        'time': {
          'minUnit': TimeUnit.day,
          'displayFormats': {
            'day': 'dd MMM',
            'month': "MMM ''yy",
            'year': 'yyyy',
          },
        },
      },
    ),
    // zoom.autoScaleYaxis: Chart.js fits the y axis to the points in the
    // range of the x axis.
    'y': apexValueAxis(),
  },
);

/// The range buttons of the demo: each one zooms the x axis to a range.
const List<(String, String, String)> _ranges = [
  ('1M', '2013-01-28', '2013-02-27'),
  ('6M', '2012-09-27', '2013-02-27'),
  ('1Y', '2012-02-27', '2013-02-27'),
  ('YTD', '2013-01-01', '2013-02-27'),
  ('ALL', '2012-01-23', '2013-02-27'),
];

class const ApexAreaDatetime({super.key}) extends StatefulWidget {
  @override
  State<ApexAreaDatetime> createState() => _ApexAreaDatetimeState();
}

class _ApexAreaDatetimeState() extends State<ApexAreaDatetime> {
  final ApexZoom _zoom = ApexZoom();
  String _active = '1M';

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        children: [
          for (final (id, from, to) in _ranges)
            TextButton(
              key: ValueKey('apex-area-datetime.$id'),
              onPressed: () {
                setState(() => _active = id);
                _zoom.zoomTo(_ms(from), _ms(to));
              },
              style: TextButton.styleFrom(
                backgroundColor: _active == id ? Apex.blue : Colors.transparent,
                foregroundColor: _active == id ? Colors.white : Apex.text,
                minimumSize: const Size(44, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(id),
            ),
        ],
      ),
      const SizedBox(height: 10),
      ApexZoomChart(
        config: _config,
        zoom: _zoom,
        semanticLabel: 'Area chart of the price of the stock ABC',
      ),
    ],
  );
}
// #enddocregion apex-area-datetime
