// Original code, not ported from Chart.js: the fl_chart bar replica parts.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-bar-kit
import 'dart:math' as math;

import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// `BarChartAlignment` of fl_chart: how the bar groups share the axis.
enum FlAlignment() {
  start,
  end,
  center,
  spaceBetween,
  spaceAround,
  spaceEvenly,
}

/// The center of the first group and the distance between two groups, in
/// pixels, as fl_chart places [count] groups of [width] pixels on an axis
/// of [length] pixels.
(double, double) groupPlacement(
  FlAlignment alignment,
  int count,
  double width,
  double length,
  double groupsSpace,
) {
  final free = length - count * width;
  final packed = count * width + (count - 1) * groupsSpace;
  final evenly = (free / (count + 1) + width / 2, width + free / (count + 1));
  return switch (alignment) {
    _ when packed > length && alignment.index < 3 => evenly,
    .start => (width / 2, width + groupsSpace),
    .end => (length - packed + width / 2, width + groupsSpace),
    .center => ((length - packed) / 2 + width / 2, width + groupsSpace),
    .spaceBetween => (width / 2, width + free / (count - 1)),
    .spaceAround => (free / (2 * count) + width / 2, width + free / count),
    .spaceEvenly => evenly,
  };
}

/// `reservedSize` of the fl_chart titles: the axis takes this size, and the
/// labels at its ends do not shrink the chart area.
ScaleHook reserve(double size) => (scale) {
  if (scale.isHorizontal()) {
    scale
      ..height = size
      ..paddingLeft = 0
      ..paddingRight = 0;
  } else {
    scale
      ..width = size
      ..paddingTop = 0
      ..paddingBottom = 0;
  }
};

/// The axis of the bar groups. Group i has the value i. A scale hook sets
/// the range of the axis from its length, so that the groups stand where
/// fl_chart places them.
LinearAxis groupAxis({
  required int count,
  required double groupWidth,
  FlAlignment alignment = .spaceEvenly,
  double groupsSpace = 16,
  double reservedSize = 0,
  AxisTicks? ticks,
  ChartPosition? position,
  bool reverse = false,
}) => LinearAxis(
  display: reservedSize > 0,
  position: position,
  reverse: reverse,
  grid: const AxisGrid(display: false, drawTicks: false),
  border: const AxisBorder(display: false),
  ticks: ticks,
  extra: {
    'offset': false,
    'afterBuildTicks': (Scale scale) {
      final length = scale.isHorizontal() ? scale.width : scale.height;
      final (first, pitch) = groupPlacement(
        alignment,
        count,
        groupWidth,
        length,
        groupsSpace,
      );
      scale
        ..min = -first / pitch
        ..max = (length - first) / pitch
        ..ticks = [for (var i = 0; i < count; i++) Tick(value: i.toDouble())];
    },
    'afterFit': reserve(reservedSize),
  },
);

/// The value axis of fl_chart: from [min] to [max], with a title at [min],
/// at each step of [interval] and at [max]. A null [interval] takes the
/// interval of fl_chart for the length of the axis.
LinearAxis valueAxis({
  required double min,
  required double max,
  double? interval,
  double reservedSize = 0,
  AxisTicks? ticks,
  AxisGrid grid = const AxisGrid(display: false, drawTicks: false),
  AxisBorder border = const AxisBorder(display: false),
  ChartPosition? position,
  bool reverse = false,
  bool stacked = false,
}) => LinearAxis(
  display: reservedSize > 0 || grid.display != false,
  min: min,
  max: max,
  position: position,
  reverse: reverse,
  stacked: stacked,
  grid: grid,
  border: border,
  ticks: ticks,
  extra: {
    // The bar chart gives offset to each axis of the index direction.
    'offset': false,
    'grid': const {'offset': false},
    'afterBuildTicks': (Scale scale) {
      final length = scale.isHorizontal() ? scale.width : scale.height;
      final step = interval ?? flInterval(length, max - min);
      scale.ticks = [
        for (final value in flAxisValues(min, max, step)) Tick(value: value),
      ];
    },
    'afterFit': reserve(reservedSize),
  },
);

/// The values of the titles of fl_chart: [min], the multiples of [step]
/// between, and [max].
List<double> flAxisValues(double min, double max, double step) {
  final mod = (0 - min) % step;
  final start = mod == 0 || (max - min).abs() <= mod ? min : min + mod;
  return [
    if (start != min) min,
    for (var i = 0; start + i * step < max - step / 100000; i++)
      start + i * step,
    max,
  ];
}

/// The interval of fl_chart for an axis of [length] pixels: about one title
/// for each 40 pixels, rounded to 1, 2, 5 or 10 times a power of ten.
double flInterval(double length, double range) {
  final count = math.max(length ~/ 40, 1);
  if (range == 0) return 1;
  final interval = range / count;
  if (count <= 2) return interval;
  var digits = interval.toInt().toString().length - 1;
  var scaled = interval / math.pow(10, digits);
  if (interval < 1) {
    digits = (math.log(interval) / math.ln10).floor();
    scaled = interval / math.pow(10, digits);
  }
  final unit = math.pow(10, digits).toDouble();
  return switch (scaled) {
    >= 7.6 => 10 * unit,
    >= 2.6 => 5 * unit,
    >= 1.6 => 2 * unit,
    _ => unit,
  };
}

/// The title text of fl_chart: a number with K, M or B, with the digits of
/// the interval.
String flNumber(double min, double max, double value, double interval) {
  final step = math.min((max - min).abs(), interval);
  final size = value.abs();
  final (unit, symbol) = switch (size) {
    >= 1e9 => (1e9, 'B'),
    >= 1e6 => (1e6, 'M'),
    >= 1e3 => (1e3, 'K'),
    _ => (1.0, ''),
  };
  // One digit for a step of 1 or more, one more for each power of ten below.
  var digits = 1;
  for (var limit = 1.0; step > 0 && step / unit < limit && digits < 10;) {
    digits++;
    limit /= 10;
  }
  var text = (size / unit).toStringAsFixed(digits);
  if (text.contains('.')) text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  if (value < 0 && text != '0') text = '-$text';
  return text + symbol;
}

/// The default titles of fl_chart: the number of each tick, with the digits
/// of the [interval] of the axis. A null [interval] is the interval of
/// fl_chart for the length of the axis.
TickCallback flTitles({double? interval, bool hideMax = false}) =>
    (scale, value, index, ticks) {
      if (hideMax && value == scale.max) return const [];
      final length = scale.isHorizontal() ? scale.width : scale.height;
      final range = scale.max - scale.min;
      final step = interval ?? flInterval(length, range);
      return [flNumber(scale.min, scale.max, value, step)];
    };

/// The font family of the texts that the plugins draw.
const _sans = TextStyle(fontFamily: 'sans-serif');

/// `BarChartRodLabel` of fl_chart: a text at the tip of a bar.
class const RodLabel(
  final String text,
  final TextStyle style, {
  final double angle = 0,
  final double offset = 8,
});

/// Draws a [RodLabel] at the tip of each bar that has one. Chart.js has no
/// labels on the bars: a small plugin draws them.
Plugin<Object?> rodLabels(RodLabel? Function(int dataset, int index) labelOf) =>
    Plugin(
      id: 'rodLabels',
      afterDatasetsDraw: (chart, args, options) {
        final ctx = chart.ctx!..save();
        for (final meta in chart.getSortedVisibleDatasetMetas()) {
          for (final (index, element) in meta.data.indexed) {
            final label = labelOf(meta.index, index);
            if (label == null) continue;
            final bar = element as BarElement;
            final horizontal = bar.horizontal ?? false;
            // The center of the text is the offset and half the text height
            // away from the tip, along the bar.
            final away = label.offset + (label.style.fontSize ?? 14) * 0.6;
            final (x, y) = horizontal
                ? (bar.x + (bar.x >= bar.base ? away : -away), bar.y)
                : (bar.x, bar.y + (bar.y <= bar.base ? -away : away));
            ctx
              ..save()
              ..translate(x, y)
              ..rotate(label.angle * math.pi / 180)
              ..font = _sans.merge(label.style)
              ..fillStyle = label.style.color ?? Colors.white
              ..textAlign = TextAlign.center
              ..textBaseline = CanvasTextBaseline.middle
              ..fillText(label.text, 0, 0)
              ..restore();
          }
        }
        ctx.restore();
      },
    );

/// `touchCallback` of fl_chart: [touched] gets the bar under the pointer,
/// or null, after each event of the chart. Chart.js calls `onHover` only
/// inside the chart area: the plugin also sees the pointer leave.
Plugin<Object?> flTouch(void Function(ActiveElement? bar) touched) => Plugin(
  id: 'touch',
  afterEvent: (chart, args, options) {
    final active = (chart as Chart).getActiveElements();
    touched(active.isEmpty ? null : active.first);
  },
);

/// fl_chart draws the titles and the labels over the edges of its box. The
/// canvas of Chart.js clips them: the canvas takes [overflow] more on each
/// side, and the chart takes it back as `padding`.
class const OverflowChart({
  required final ChartConfig config,
  final EdgeInsets overflow = const EdgeInsets.all(16),
  final UpdateMode? updateMode,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => OverflowBox(
      alignment: Alignment.topLeft,
      maxWidth: constraints.maxWidth + overflow.horizontal,
      maxHeight: constraints.maxHeight + overflow.vertical,
      child: Transform.translate(
        offset: Offset(-overflow.left, -overflow.top),
        child: ChartView(
          config: config.copyWith(padding: overflow),
          updateMode: updateMode,
        ),
      ),
    ),
  );
}

/// The defaults of fl_chart: the chart fills its box, no legend, and an
/// animation of 150 milliseconds with a linear curve. Chart.js clips the
/// bars at the edges of the chart area, and fl_chart does not.
ChartConfig flBars(ChartConfig config) => config.copyWith(
  maintainAspectRatio: false,
  legend: config.legend ?? noLegend,
  animation:
      config.animation ??
      const ChartAnimation(
        duration: Duration(milliseconds: 150),
        easing: Curves.linear,
      ),
  extra: {
    ...?config.extra,
    'datasets': {
      'bar': {'clip': ChartClip.none},
    },
  },
);
// #enddocregion fl_chart-bar-kit
