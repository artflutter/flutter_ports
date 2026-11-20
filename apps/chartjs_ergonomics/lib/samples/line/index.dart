// Original code, not ported from Chart.js: the list of the line samples.

import 'package:chartjs_ergonomics/sample.dart';
import 'package:chartjs_ergonomics/samples/line/animation.dart';
import 'package:chartjs_ergonomics/samples/line/axis_range.dart';
import 'package:chartjs_ergonomics/samples/line/axis_title.dart';
import 'package:chartjs_ergonomics/samples/line/basic.dart';
import 'package:chartjs_ergonomics/samples/line/colors.dart';
import 'package:chartjs_ergonomics/samples/line/dashed.dart';
import 'package:chartjs_ergonomics/samples/line/elements.dart';
import 'package:chartjs_ergonomics/samples/line/extra.dart';
import 'package:chartjs_ergonomics/samples/line/fill_between.dart';
import 'package:chartjs_ergonomics/samples/line/fill_origin.dart';
import 'package:chartjs_ergonomics/samples/line/fill_split.dart';
import 'package:chartjs_ergonomics/samples/line/gaps.dart';
import 'package:chartjs_ergonomics/samples/line/gradient.dart';
import 'package:chartjs_ergonomics/samples/line/grid_border.dart';
import 'package:chartjs_ergonomics/samples/line/hidden.dart';
import 'package:chartjs_ergonomics/samples/line/hover.dart';
import 'package:chartjs_ergonomics/samples/line/indexed_colors.dart';
import 'package:chartjs_ergonomics/samples/line/interaction.dart';
import 'package:chartjs_ergonomics/samples/line/layout.dart';
import 'package:chartjs_ergonomics/samples/line/legend.dart';
import 'package:chartjs_ergonomics/samples/line/log_axis.dart';
import 'package:chartjs_ergonomics/samples/line/monotone.dart';
import 'package:chartjs_ergonomics/samples/line/new_data.dart';
import 'package:chartjs_ergonomics/samples/line/no_animation.dart';
import 'package:chartjs_ergonomics/samples/line/no_legend.dart';
import 'package:chartjs_ergonomics/samples/line/no_points.dart';
import 'package:chartjs_ergonomics/samples/line/on_click.dart';
import 'package:chartjs_ergonomics/samples/line/order.dart';
import 'package:chartjs_ergonomics/samples/line/point_style.dart';
import 'package:chartjs_ergonomics/samples/line/points_only.dart';
import 'package:chartjs_ergonomics/samples/line/property_animation.dart';
import 'package:chartjs_ergonomics/samples/line/scriptable.dart';
import 'package:chartjs_ergonomics/samples/line/segment.dart';
import 'package:chartjs_ergonomics/samples/line/shadow.dart';
import 'package:chartjs_ergonomics/samples/line/stacked.dart';
import 'package:chartjs_ergonomics/samples/line/stepped.dart';
import 'package:chartjs_ergonomics/samples/line/tension.dart';
import 'package:chartjs_ergonomics/samples/line/tick_format.dart';
import 'package:chartjs_ergonomics/samples/line/time_axis.dart';
import 'package:chartjs_ergonomics/samples/line/title.dart';
import 'package:chartjs_ergonomics/samples/line/tooltip_index.dart';
import 'package:chartjs_ergonomics/samples/line/tooltip_label.dart';
import 'package:chartjs_ergonomics/samples/line/tooltip_style.dart';
import 'package:chartjs_ergonomics/samples/line/two_axes.dart';
import 'package:chartjs_ergonomics/samples/line/two_datasets.dart';
import 'package:chartjs_ergonomics/samples/line/vertical.dart';
import 'package:chartjs_ergonomics/samples/line/xy_points.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The folder of the line samples, an asset folder of `pubspec.yaml`.
const String lineFolder = 'lib/samples/line';

/// The line samples, in the order of the page. Each one shows one feature.
final List<Sample> lineSamples = [
  const Sample(
    file: 'basic',
    title: 'Minimal line',
    note:
        'Labels and one dataset. With no color, the colors plugin picks '
        'one.',
    child: ChartView(config: basic),
    accepted: true,
  ),
  const Sample(
    file: 'colors',
    title: 'Line color and width',
    note:
        'A color is a ChartValue of a ChartPaint: constant, indexed or a '
        'function.',
    child: ChartView(config: lineColors),
    accepted: true,
  ),
  const Sample(
    file: 'two_datasets',
    title: 'Two datasets',
    note: 'Each dataset is one line and one legend item.',
    child: ChartView(config: twoDatasets),
    accepted: true,
  ),
  const Sample(
    file: 'tension',
    title: 'Curved line',
    note: 'tension from 0 (straight) to 1.',
    child: ChartView(config: tension),
    accepted: true,
  ),
  const Sample(
    file: 'monotone',
    title: 'Monotone curve',
    note: 'The monotone mode keeps the curve inside the data range.',
    child: ChartView(config: monotone),
    accepted: true,
  ),
  const Sample(
    file: 'stepped',
    title: 'Stepped lines',
    note:
        'stepped takes a SteppedLine. The Chart.js form `stepped: true` is '
        '.before.',
    child: ChartView(config: stepped),
    accepted: true,
  ),
  const Sample(
    file: 'dashed',
    title: 'Dashed line',
    note: 'borderDash in pixels, with the Flutter StrokeCap and StrokeJoin.',
    child: ChartView(config: dashed),
    accepted: true,
  ),
  const Sample(
    file: 'fill_origin',
    title: 'Area to the origin',
    note: 'fill takes a FillTarget. backgroundColor is the area color.',
    child: ChartView(config: fillOrigin),
    accepted: true,
  ),
  const Sample(
    file: 'fill_between',
    title: 'Area between two lines',
    note: 'FillTarget.toPrevious fills to the dataset before this one.',
    child: ChartView(config: fillBetween),
    accepted: true,
  ),
  Sample(
    file: 'fill_split',
    title: 'Area above and below a value',
    note:
        'split gives two colors. It is a method, so the config is not '
        'const.',
    child: ChartView(config: fillSplit),
    accepted: true,
  ),
  const Sample(
    file: 'stacked',
    title: 'Stacked areas',
    note:
        'The datasets stack on the y axis, and each area fills to the one '
        'below.',
    child: ChartView(config: stacked),
  ),
  const Sample(
    file: 'gaps',
    title: 'Gaps in the data',
    note: 'A null value breaks the line, unless spanGaps is true.',
    child: ChartView(config: gaps),
  ),
  const Sample(
    file: 'segment',
    title: 'Segment style',
    note: 'A function gives the style of each part of the line.',
    child: ChartView(config: segment),
  ),
  const Sample(
    file: 'point_style',
    title: 'Point style',
    note: 'pointStyle takes a PointStyle object, here a triangle.',
    child: ChartView(config: pointStyle),
  ),
  const Sample(
    file: 'no_points',
    title: 'No points',
    note: 'pointRadius 0 draws the line only.',
    child: ChartView(config: noPoints),
  ),
  const Sample(
    file: 'points_only',
    title: 'Points only',
    note: 'showLine false draws the points only.',
    child: ChartView(config: pointsOnly),
  ),
  const Sample(
    file: 'indexed_colors',
    title: 'A color for each point',
    note: 'ChartValue.indexed gives the colors by data index.',
    child: ChartView(config: indexedColors),
  ),
  const Sample(
    file: 'scriptable',
    title: 'Color from a function',
    note:
        'ChartValue.resolver calls a function of the context for each '
        'point.',
    child: ChartView(config: scriptable),
  ),
  const Sample(
    file: 'gradient',
    title: 'Gradient line',
    note: 'A ChartGradient is a ChartPaint. Its points are canvas pixels.',
    child: ChartView(config: gradient),
  ),
  const Sample(
    file: 'shadow',
    title: 'Line shadow',
    note: 'shadow is not a Chart.js option. It is a port addition.',
    child: ChartView(config: shadow),
  ),
  Sample(
    file: 'xy_points',
    title: 'x and y data',
    note: 'points takes DataPoint items. The x axis is a LinearAxis.',
    child: ChartView(config: xyPoints),
  ),
  Sample(
    file: 'time_axis',
    title: 'Time axis',
    note: 'DataPoint.time takes a DateTime, and TimeAxis takes a TimeUnit.',
    child: ChartView(config: timeAxis),
  ),
  const Sample(
    file: 'log_axis',
    title: 'Logarithmic axis',
    note: 'The key of the scales Map is the axis id.',
    child: ChartView(config: logAxis),
  ),
  const Sample(
    file: 'two_axes',
    title: 'Two y axes',
    note: 'yAxisID links a dataset to an axis id of scales.',
    child: ChartView(config: twoAxes),
  ),
  const Sample(
    file: 'axis_range',
    title: 'Axis range and step',
    note: 'min, max and ticks.stepSize of a LinearAxis.',
    child: ChartView(config: axisRange),
  ),
  const Sample(
    file: 'tick_format',
    title: 'Tick labels',
    note: 'A TickCallback gives the lines of each tick label.',
    child: ChartView(config: tickFormat),
  ),
  const Sample(
    file: 'axis_title',
    title: 'Axis titles',
    note: 'The text of a title is a List, one String for each line.',
    child: ChartView(config: axisTitle),
  ),
  const Sample(
    file: 'grid_border',
    title: 'Grid and axis border',
    note: 'AxisGrid draws the grid lines. AxisBorder draws the axis line.',
    child: ChartView(config: gridBorder),
  ),
  const Sample(
    file: 'vertical',
    title: 'Vertical line',
    note:
        'indexAxis YAxis puts the labels on y. The dataset axis has no '
        'parameter.',
    child: ChartView(config: vertical),
  ),
  const Sample(
    file: 'title',
    title: 'Title and subtitle',
    note: 'ChartTitle for both. display must be true.',
    child: ChartView(config: withTitle),
  ),
  const Sample(
    file: 'legend',
    title: 'Legend position and style',
    note: 'The position and the align are enums.',
    child: ChartView(config: legendStyle),
  ),
  const Sample(
    file: 'no_legend',
    title: 'No legend',
    note: 'display false.',
    child: ChartView(config: noLegend),
  ),
  const Sample(
    file: 'hidden',
    title: 'Hidden dataset',
    note: 'hidden true. A tap on the legend item shows it.',
    child: ChartView(config: hidden),
  ),
  const Sample(
    file: 'order',
    title: 'Draw order',
    note: 'The dataset with the lower order is on top.',
    child: ChartView(config: order),
  ),
  const Sample(
    file: 'tooltip_index',
    title: 'Tooltip for all datasets',
    note: 'The tooltip mode is an InteractionMode object.',
    child: ChartView(config: tooltipIndex),
  ),
  const Sample(
    file: 'tooltip_label',
    title: 'Tooltip text',
    note: 'TooltipCallbacks hooks give the lines of the title and the labels.',
    child: ChartView(config: tooltipLabel),
  ),
  const Sample(
    file: 'tooltip_style',
    title: 'Tooltip style',
    note: 'The colors are ChartPaint values, the font is a TextStyle.',
    child: ChartView(config: tooltipStyle),
  ),
  const Sample(
    file: 'interaction',
    title: 'Interaction mode',
    note: 'ChartInteraction sets the hover and the tooltip together.',
    child: ChartView(config: interaction),
  ),
  const Sample(
    file: 'hover',
    title: 'Hover style',
    note: 'The point hover options of the dataset.',
    child: ChartView(config: hover),
  ),
  const Sample(
    file: 'extra',
    title: 'Options with no parameter',
    note: 'extra is a Map of Chart.js keys. It merges last.',
    child: ChartView(config: extra),
  ),
  const Sample(
    file: 'animation',
    title: 'Animation',
    note:
        'A Duration and a Flutter Curve. The animation runs when the card '
        'comes into view.',
    child: ChartView(config: animation),
  ),
  const Sample(
    file: 'property_animation',
    title: 'Animation of one property',
    note: 'One class for each animated property, here the point radius.',
    child: ChartView(config: propertyAnimation),
  ),
  const Sample(
    file: 'no_animation',
    title: 'No animation',
    note: 'ChartAnimation.none.',
    child: ChartView(config: noAnimation),
  ),
  const Sample(
    file: 'elements',
    title: 'Element defaults',
    note: 'ChartElements sets the style of all lines and points of the chart.',
    child: ChartView(config: elementDefaults),
  ),
  const Sample(
    file: 'layout',
    title: 'Aspect ratio and padding',
    note: 'aspectRatio is the width divided by the height.',
    child: ChartView(config: layout),
  ),
  const Sample(
    file: 'on_click',
    title: 'Click on a point',
    note:
        'onClick gets the event, the elements with int indexes and the '
        'chart.',
    child: ClickedPoint(),
  ),
  const Sample(
    file: 'new_data',
    title: 'New data',
    note: 'A new List in setState updates the chart.',
    child: NewData(),
  ),
];
