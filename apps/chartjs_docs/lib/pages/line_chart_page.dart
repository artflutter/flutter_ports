// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// The adjacent strings keep the lines of the prose short.
// ignore_for_file: no_adjacent_strings_in_list

import 'dart:async';
import 'dart:math' as math;

import 'package:chartjs_docs/examples/line_examples.dart';
import 'package:chartjs_docs/ui/code_block.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/docs_theme.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The rows of the table of dataset properties.
const List<DocProperty> lineProperties = [
  DocProperty(
    'backgroundColor',
    section: 'line-styling',
    type: 'ChartValue<Color>',
    scriptable: true,
    fallback: 'rgba(0, 0, 0, 0.1)',
  ),
  DocProperty(
    'borderCapStyle',
    section: 'line-styling',
    type: 'String',
    extra: true,
    scriptable: true,
    fallback: "'butt'",
  ),
  DocProperty(
    'borderColor',
    section: 'line-styling',
    type: 'ChartValue<Color>',
    scriptable: true,
    fallback: 'rgba(0, 0, 0, 0.1)',
  ),
  DocProperty(
    'borderDash',
    section: 'line-styling',
    type: 'List<double>',
    scriptable: true,
    fallback: '[]',
  ),
  DocProperty(
    'borderDashOffset',
    section: 'line-styling',
    type: 'double',
    extra: true,
    scriptable: true,
    fallback: '0',
  ),
  DocProperty(
    'borderJoinStyle',
    section: 'line-styling',
    type: 'String',
    extra: true,
    scriptable: true,
    fallback: "'miter'",
  ),
  DocProperty(
    'borderWidth',
    section: 'line-styling',
    type: 'double',
    scriptable: true,
    fallback: '3',
  ),
  DocProperty(
    'clip',
    section: 'general',
    type: 'num, bool or Map',
    extra: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'cubicInterpolationMode',
    section: 'cubic-interpolation-mode',
    type: 'String',
    extra: true,
    scriptable: true,
    fallback: "'default'",
  ),
  DocProperty(
    'data',
    section: 'data-structure',
    type: 'List<num?>',
    fallback: 'required',
  ),
  DocProperty(
    'drawActiveElementsOnTop',
    section: 'general',
    type: 'bool',
    extra: true,
    scriptable: true,
    indexable: true,
    fallback: 'true',
  ),
  DocProperty(
    'fill',
    section: 'line-styling',
    type: 'ChartFill',
    scriptable: true,
    fallback: 'false',
  ),
  DocProperty(
    'hoverBackgroundColor',
    section: 'line-styling',
    type: 'Color',
    scriptable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'hoverBorderCapStyle',
    section: 'line-styling',
    type: 'String',
    extra: true,
    scriptable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'hoverBorderColor',
    section: 'line-styling',
    type: 'Color',
    scriptable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'hoverBorderDash',
    section: 'line-styling',
    type: 'List<double>',
    extra: true,
    scriptable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'hoverBorderDashOffset',
    section: 'line-styling',
    type: 'double',
    extra: true,
    scriptable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'hoverBorderJoinStyle',
    section: 'line-styling',
    type: 'String',
    extra: true,
    scriptable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'hoverBorderWidth',
    section: 'line-styling',
    type: 'double',
    scriptable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'indexAxis',
    section: 'general',
    type: 'IndexAxis',
    fallback: "'x'",
  ),
  DocProperty('label', section: 'general', type: 'String', fallback: "''"),
  DocProperty('order', section: 'general', type: 'int', fallback: '0'),
  DocProperty(
    'pointBackgroundColor',
    section: 'point-styling',
    type: 'Color',
    scriptable: true,
    indexable: true,
    fallback: 'rgba(0, 0, 0, 0.1)',
  ),
  DocProperty(
    'pointBorderColor',
    section: 'point-styling',
    type: 'Color',
    scriptable: true,
    indexable: true,
    fallback: 'rgba(0, 0, 0, 0.1)',
  ),
  DocProperty(
    'pointBorderWidth',
    section: 'point-styling',
    type: 'double',
    scriptable: true,
    indexable: true,
    fallback: '1',
  ),
  DocProperty(
    'pointHitRadius',
    section: 'point-styling',
    type: 'double',
    extra: true,
    scriptable: true,
    indexable: true,
    fallback: '1',
  ),
  DocProperty(
    'pointHoverBackgroundColor',
    section: 'interactions',
    type: 'Color',
    scriptable: true,
    indexable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'pointHoverBorderColor',
    section: 'interactions',
    type: 'Color',
    scriptable: true,
    indexable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'pointHoverBorderWidth',
    section: 'interactions',
    type: 'double',
    extra: true,
    scriptable: true,
    indexable: true,
    fallback: '1',
  ),
  DocProperty(
    'pointHoverRadius',
    section: 'interactions',
    type: 'double',
    scriptable: true,
    indexable: true,
    fallback: '4',
  ),
  DocProperty(
    'pointRadius',
    section: 'point-styling',
    type: 'double',
    scriptable: true,
    indexable: true,
    fallback: '3',
  ),
  DocProperty(
    'pointRotation',
    section: 'point-styling',
    type: 'double',
    extra: true,
    scriptable: true,
    indexable: true,
    fallback: '0',
  ),
  DocProperty(
    'pointStyle',
    section: 'point-styling',
    type: 'ChartPointStyle',
    scriptable: true,
    indexable: true,
    fallback: "'circle'",
  ),
  DocProperty(
    'points',
    section: 'data-structure',
    type: 'List<DataPoint>',
    fallback: 'none',
  ),
  DocProperty(
    'segment',
    section: 'segment',
    type: 'Map',
    extra: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'shadow',
    section: 'line-styling',
    type: 'ChartShadow',
    fallback: 'no shadow',
  ),
  DocProperty(
    'showLine',
    section: 'line-styling',
    type: 'bool',
    fallback: 'true',
  ),
  DocProperty(
    'spanGaps',
    section: 'line-styling',
    type: 'bool',
    fallback: 'undefined',
  ),
  DocProperty('stack', section: 'general', type: 'String', fallback: "'line'"),
  DocProperty(
    'stepped',
    section: 'stepped',
    type: 'bool',
    fallback: 'false',
  ),
  DocProperty(
    'tension',
    section: 'line-styling',
    type: 'double',
    fallback: '0',
  ),
  DocProperty(
    'xAxisID',
    section: 'general',
    type: 'String',
    fallback: 'first x axis',
  ),
  DocProperty(
    'yAxisID',
    section: 'general',
    type: 'String',
    fallback: 'first y axis',
  ),
];

/// The content of the line chart page.
DocPageContent lineChartPage() => DocPageContent(
  title: 'Line Chart',
  navLabel: 'Line chart',
  icon: Icons.show_chart,
  intro: [
    const DocParagraph(
      'A line chart shows data points on a line. '
      'Use a line chart to show a trend or to compare two datasets.',
    ),
    const DocParagraph(
      'Register the chart components one time, before the first chart.',
    ),
    const DocCode('register'),
    const DocParagraph(
      'Then give a `ChartConfig` to a `ChartView`. '
      'The chart below is a live widget.',
    ),
    const LiveExample(
      id: 'basic',
      description: 'A line chart of seven months',
      variants: [
        ExampleVariant(label: 'Basic', config: basicLine, region: 'basic'),
      ],
    ),
  ],
  sections: [
    DocSection(
      id: 'dataset-properties',
      title: 'Dataset Properties',
      body: [
        const DocParagraph('The chart reads an option from these scopes:'),
        const DocTable([
          ('LineDataset(...)', 'The options of this dataset only.'),
          (
            "extra: {'datasets': {'line': ...}}",
            'The options of all line datasets, in `ChartConfig.extra`.',
          ),
          (
            'ChartElements(line: ...)',
            'The options of all line elements, in `ChartConfig.elements`.',
          ),
          (
            'ChartElements(point: ...)',
            'The options of all point elements, in `ChartConfig.elements`.',
          ),
          ('ChartConfig(...)', 'The options of the whole chart.'),
        ]),
        const LiveExample(
          id: 'scopes',
          description: 'A line chart with options in three scopes',
          variants: [
            ExampleVariant(
              label: 'Scopes',
              config: scopedLine,
              region: 'scopes',
            ),
          ],
        ),
        const DocParagraph(
          'Each dataset has properties. These properties set the look of '
          'that dataset. For example, a dataset usually sets the color of '
          'its line.',
        ),
        const DocParagraph(
          'The column **Set with** gives the place of the option in Dart. '
          'A **Parameter** is a named parameter of `LineDataset`. An option '
          'with no parameter goes in the `extra` Map of the dataset, under '
          'its Chart.js name.',
        ),
        const DocPropertyTable(lineProperties),
        const DocParagraph(
          'If a dataset does not set a value, the chart reads the next '
          'scope. A `null` parameter writes no key.',
        ),
      ],
      subsections: [
        DocSection(
          id: 'scriptable-indexable',
          title: 'Scriptable and Indexable Values',
          body: [
            const DocParagraph(
              'A scriptable option takes a function. The chart calls the '
              'function for each data item. An indexable option takes a '
              'list, with one value for each data item.',
            ),
            const DocParagraph(
              '`backgroundColor` and `borderColor` take a `ChartValue`: '
              '`.constant`, `.indexed` or `.resolver`. Each other parameter '
              'takes one fixed value. For a function or a list on another '
              'option, use `extra` with the Chart.js name.',
            ),
            LiveExample(
              id: 'scriptable',
              description: 'A line chart with a color for each point',
              variants: [
                ExampleVariant(
                  label: 'Scriptable',
                  config: oneLine(scriptableLine),
                  region: 'scriptable',
                ),
              ],
            ),
            const DocTip(
              'Use a top-level function or a method tear-off. A new closure '
              'in each build is a new value, and the chart updates again.',
            ),
          ],
        ),
        const DocSection(
          id: 'general',
          title: 'General',
          body: [
            DocTable([
              (
                'clip',
                'How the chart clips the dataset at the chart area. A '
                    'positive value permits overflow. A negative value clips '
                    'that number of pixels inside the chart area. `0` clips '
                    'at the chart area. A Map sets each side, for example '
                    "`{'left': 5, 'top': false, 'right': -2, 'bottom': 0}`.",
              ),
              (
                'drawActiveElementsOnTop',
                'Draws the active points of a dataset over the other points '
                    'of that dataset.',
              ),
              (
                'indexAxis',
                'The base axis of the dataset. `.x` gives horizontal lines. '
                    '`.y` gives vertical lines.',
              ),
              (
                'label',
                'The name of the dataset in the legend and in the tooltip.',
              ),
              (
                'order',
                'The draw order of the dataset. The value also sets the '
                    'order of the stacks, of the tooltip and of the legend.',
              ),
              (
                'stack',
                'The ID of the group of the dataset. On a stacked axis, each '
                    'group is a separate stack. See '
                    '[Stacked Area Chart](#stacked-area-chart).',
              ),
              ('xAxisID', 'The ID of the x axis of this dataset.'),
              ('yAxisID', 'The ID of the y axis of this dataset.'),
            ]),
          ],
        ),
        DocSection(
          id: 'point-styling',
          title: 'Point Styling',
          body: [
            const DocParagraph('These properties set the style of each point.'),
            const DocTable([
              ('pointBackgroundColor', 'The fill color of the points.'),
              ('pointBorderColor', 'The border color of the points.'),
              (
                'pointBorderWidth',
                'The width of the point border in pixels.',
              ),
              (
                'pointHitRadius',
                'The size in pixels of the invisible area that reacts to '
                    'the pointer.',
              ),
              (
                'pointRadius',
                'The radius of the point shape. The chart does not draw a '
                    'point with the radius `0`.',
              ),
              ('pointRotation', 'The rotation of the point in degrees.'),
              ('pointStyle', 'The shape of the point.'),
            ]),
            LiveExample(
              id: 'point-styling',
              description: 'A line chart with a point style',
              variants: [
                for (final (label, style) in const [
                  ('circle', ChartPointStyle.circle),
                  ('rect', ChartPointStyle.rect),
                  ('rectRot', ChartPointStyle.rectRot),
                  ('triangle', ChartPointStyle.triangle),
                  ('star', ChartPointStyle.star),
                  ('cross', ChartPointStyle.cross),
                ])
                  ExampleVariant(
                    label: label,
                    config: pointStyling(style),
                    region: 'point-styling',
                  ),
              ],
            ),
            const DocParagraph(
              'If a value is not set, the chart reads the dataset options, '
              'and then the options of the point elements.',
            ),
          ],
        ),
        const DocSection(
          id: 'line-styling',
          title: 'Line Styling',
          body: [
            DocParagraph('These properties set the style of the line.'),
            DocTable([
              ('backgroundColor', 'The fill color of the line.'),
              (
                'borderCapStyle',
                "The cap style of the line: `'butt'`, `'round'` or "
                    "`'square'`.",
              ),
              ('borderColor', 'The color of the line.'),
              (
                'borderDash',
                'The lengths of the dashes and the gaps, in pixels.',
              ),
              ('borderDashOffset', 'The offset of the dashes, in pixels.'),
              (
                'borderJoinStyle',
                "The style of the line joints: `'round'`, `'bevel'` or "
                    "`'miter'`.",
              ),
              ('borderWidth', 'The width of the line in pixels.'),
              ('fill', 'How the chart fills the area under the line.'),
              (
                'tension',
                'The Bézier curve tension of the line. The value `0` draws '
                    'straight lines. The monotone mode ignores this option.',
              ),
              (
                'shadow',
                'The shadow of the line and its points: a `ChartShadow` with '
                    'a color, a blur and an offset. The area fill has no '
                    'shadow. The shadow is not a Chart.js option.',
              ),
              (
                'showLine',
                'If `false`, the chart does not draw the line of this '
                    'dataset.',
              ),
              (
                'spanGaps',
                'If `true`, the chart draws the line across `null` values. '
                    'If `false`, a `null` value breaks the line. A number '
                    'gives the maximum gap to span, in the unit of the '
                    "scale. A number goes through `extra: {'spanGaps': 2}`.",
              ),
            ]),
            LiveExample(
              id: 'line-styling',
              description: 'A line chart with a line style',
              variants: [
                ExampleVariant(
                  label: 'Solid',
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [solidLine],
                  ),
                  region: 'line-solid',
                ),
                ExampleVariant(
                  label: 'Dashed',
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [dashedLine],
                  ),
                  region: 'line-dashed',
                ),
                ExampleVariant(
                  label: 'Filled',
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [filledLine],
                  ),
                  region: 'line-filled',
                ),
                ExampleVariant(
                  label: 'Points only',
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [pointsOnlyLine],
                  ),
                  region: 'line-points-only',
                ),
                ExampleVariant(
                  label: 'Shadow',
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [shadowLine],
                  ),
                  region: 'line-shadow',
                ),
              ],
            ),
            LiveExample(
              id: 'gaps',
              description: 'A line chart with null values',
              variants: [
                ExampleVariant(
                  label: 'spanGaps: false',
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [brokenLine],
                  ),
                  region: 'gaps-break',
                ),
                ExampleVariant(
                  label: 'spanGaps: true',
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [spannedLine],
                  ),
                  region: 'gaps-span',
                ),
              ],
            ),
            DocParagraph(
              'If a value is not set, the chart reads the options of the '
              'line elements.',
            ),
          ],
        ),
        const DocSection(
          id: 'interactions',
          title: 'Interactions',
          body: [
            DocParagraph(
              'These properties set the look of a point under the pointer.',
            ),
            DocTable([
              (
                'pointHoverBackgroundColor',
                'The fill color of a point under the pointer.',
              ),
              (
                'pointHoverBorderColor',
                'The border color of a point under the pointer.',
              ),
              (
                'pointHoverBorderWidth',
                'The border width of a point under the pointer.',
              ),
              ('pointHoverRadius', 'The radius of a point under the pointer.'),
            ]),
            LiveExample(
              id: 'interactions',
              description: 'A line chart with hover styles',
              hint: 'Move the pointer over a point, or tap a point.',
              variants: [
                ExampleVariant(
                  label: 'Hover',
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [hoverLine],
                  ),
                  region: 'interactions',
                ),
              ],
            ),
          ],
        ),
        const DocSection(
          id: 'cubic-interpolation-mode',
          title: 'cubicInterpolationMode',
          body: [
            DocParagraph('The chart has these interpolation modes:'),
            DocBullets([
              "`'default'` uses a weighted cubic interpolation. This mode "
                  'gives smooth curves for all types of datasets.',
              "`'monotone'` is better for `y = f(x)` datasets. This mode "
                  'keeps the monotonicity of the data. A local extreme '
                  'stays at a data point.',
            ]),
            DocParagraph(
              'If the dataset does not set the mode, the chart uses '
              '`cubicInterpolationMode` of the line elements.',
            ),
            LiveExample(
              id: 'cubic',
              description: 'A line chart of two interpolation modes',
              variants: [
                ExampleVariant(
                  label: 'Modes',
                  config: cubicLines,
                  region: 'cubic',
                ),
              ],
            ),
          ],
        ),
        const DocSection(
          id: 'segment',
          title: 'Segment',
          body: [
            DocParagraph(
              'Scriptable options in the `segment` Map change the style of '
              'a part of the line. All `border*` options and '
              '`backgroundColor` can go in this Map. The chart resolves '
              'the styles for each part of the line between two points. A '
              'function that returns `undefined` keeps the style of the '
              'line.',
            ),
            DocTip(
              'To style a gap, set `spanGaps` to `true`.',
            ),
            DocParagraph('The context of a segment function has these keys:'),
            DocTable([
              ('type', "The string `'segment'`."),
              ('p0', 'The first point element.'),
              ('p1', 'The second point element.'),
              ('p0DataIndex', 'The index of the first point in the data.'),
              ('p1DataIndex', 'The index of the second point in the data.'),
              ('datasetIndex', 'The index of the dataset.'),
            ]),
            DocParagraph(
              'A segment function reads the context by name through '
              '`JsObjectFace`. This example draws a falling part in red. '
              'It draws a gap with a dashed gray line.',
            ),
            LiveExample(
              id: 'segment',
              description: 'A line chart with styled segments',
              variants: [
                ExampleVariant(
                  label: 'Segments',
                  config: segmentLine,
                  region: 'segment',
                ),
              ],
            ),
          ],
        ),
        const DocSection(
          id: 'stepped',
          title: 'Stepped',
          body: [
            DocParagraph('`stepped` takes these values:'),
            DocBullets([
              '`false`: no step interpolation. This value is the default.',
              '`true`: step-before interpolation. It is the same as '
                  "`'before'`.",
              "`'before'`: step-before interpolation.",
              "`'after'`: step-after interpolation.",
              "`'middle'`: step-middle interpolation.",
            ]),
            DocParagraph(
              'The parameter `stepped` takes a `bool`. The three strings go '
              'through `extra`. If `stepped` is not `false`, the chart '
              'ignores `tension`.',
            ),
            LiveExample(
              id: 'stepped',
              description: 'A stepped line chart',
              variants: [
                ExampleVariant(
                  label: 'false',
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [noStep],
                  ),
                  region: 'stepped-false',
                ),
                ExampleVariant(
                  label: 'true',
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [stepTrue],
                  ),
                  region: 'stepped-true',
                ),
                ExampleVariant(
                  label: "'before'",
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [stepBefore],
                  ),
                  region: 'stepped-before',
                ),
                ExampleVariant(
                  label: "'after'",
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [stepAfter],
                  ),
                  region: 'stepped-after',
                ),
                ExampleVariant(
                  label: "'middle'",
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [stepMiddle],
                  ),
                  region: 'stepped-middle',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    const DocSection(
      id: 'default-options',
      title: 'Default Options',
      body: [
        DocParagraph(
          'To apply a setting to all line charts, change the global line '
          'chart settings. A change has an effect only on the charts that '
          'the app creates after the change. Existing charts do not change.',
        ),
        DocParagraph(
          'For example, this call sets `spanGaps` to `true` for all line '
          'charts:',
        ),
        DocCode('defaults'),
      ],
    ),
    DocSection(
      id: 'data-structure',
      title: 'Data Structure',
      body: [
        const DocParagraph(
          'A `LineDataset` takes `data` or `points`, not both. The parameter '
          '`data` holds one value for each label. A `null` value is a gap.',
        ),
        const DocParagraph(
          'The parameter `points` holds `DataPoint` items. Use `DataPoint` '
          'with a number on a `LinearAxis`, `DataPoint.time` with a '
          '`DateTime` on a time axis, and `DataPoint.label` with a '
          'category.',
        ),
        const DocParagraph(
          'The chart reads the List of the app with no copy. For new values, '
          'give a new List in a new `ChartConfig`.',
        ),
        LiveExample(
          id: 'data',
          description: 'A line chart of two data forms',
          variants: [
            const ExampleVariant(
              label: 'data',
              config: valuesLine,
              region: 'data-values',
            ),
            ExampleVariant(
              label: 'points',
              config: pointsLine,
              region: 'data-points',
            ),
          ],
        ),
        const DocParagraph(
          'For the other Chart.js data forms, use `ChartView.raw` with the '
          'config as a Dart `Map`.',
        ),
      ],
    ),
    const DocSection(
      id: 'stacked-area-chart',
      title: 'Stacked Area Chart',
      body: [
        DocParagraph(
          'To make a stacked area chart, set `stacked` on the y axis. A '
          'stacked area chart shows how a number of smaller parts make one '
          'trend.',
        ),
        LiveExample(
          id: 'stacked',
          description: 'A stacked area chart of three datasets',
          variants: [
            ExampleVariant(
              label: 'Stacked',
              config: stackedLines,
              region: 'stacked',
            ),
          ],
        ),
      ],
    ),
    const DocSection(
      id: 'vertical-line-chart',
      title: 'Vertical Line Chart',
      body: [
        DocParagraph(
          'A vertical line chart is a variation of the horizontal line '
          'chart. To make a vertical line chart, set `indexAxis` to `.y`. '
          'The default is `.x`, which gives horizontal lines.',
        ),
        LiveExample(
          id: 'vertical',
          description: 'A vertical line chart',
          variants: [
            ExampleVariant(
              label: 'Vertical',
              config: verticalLine,
              region: 'vertical',
            ),
          ],
        ),
      ],
      subsections: [
        DocSection(
          id: 'config-options',
          title: 'Config Options',
          body: [
            DocParagraph(
              'A vertical line chart has the options of a line chart. '
              'But an option of the x axis in a line chart applies to the '
              'y axis in a vertical line chart.',
            ),
          ],
        ),
      ],
    ),
    const DocSection(
      id: 'internal-data-format',
      title: 'Internal Data Format',
      body: [
        DocParagraph(
          'The chart keeps each parsed item as `{x, y}`. If the data is '
          'already in this form and sorted, set `parsing` to `false`. The '
          'chart then skips the parse step.',
        ),
        DocCode('internal-format'),
      ],
    ),
    const DocSection(
      id: 'live-data',
      title: 'Live Data',
      body: [
        DocParagraph(
          'This section has no Chart.js counterpart. A chart that gets new '
          'data in each frame can skip the layout. Set `dataOnlyUpdates` to '
          "`true`, `updateMode` to `'none'` and `animation` to "
          '`ChartAnimation.none`. Give fixed `min` and `max` values to the '
          'axes.',
        ),
        DocParagraph(
          'The chart then does a data-only update when only the data Lists '
          'of the new config change. Another change does a full update.',
        ),
        LiveLineDemo(),
      ],
    ),
  ],
);

/// A chart of 1,000 points that changes in each frame while it runs.
class LiveLineDemo extends StatefulWidget {
  /// Creates the demo.
  const LiveLineDemo({super.key});

  @override
  State<LiveLineDemo> createState() => _LiveLineDemoState();
}

class _LiveLineDemoState extends State<LiveLineDemo> {
  Timer? _timer;
  int _tick = 0;

  bool get _running => _timer != null;

  List<DataPoint> _points() => List.generate(1000, (index) {
    final x = index * 0.02;
    final y =
        math.sin(x + _tick * 0.05) + 0.4 * math.sin(3.1 * x - _tick * 0.11);
    return DataPoint(index, y);
  }, growable: false);

  late List<DataPoint> _current = _points();

  void _toggle() => setState(() {
    if (_running) {
      _timer!.cancel();
      _timer = null;
    } else {
      _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        setState(() {
          _tick++;
          _current = _points();
        });
      });
    }
  });

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: DocColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              FilledButton.icon(
                key: const ValueKey('live.toggle'),
                onPressed: _toggle,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? 'Pause' : 'Run'),
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  '1,000 points, new data in each frame',
                  style: TextStyle(color: DocColors.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: RepaintBoundary(
            child: liveLineChart(_current),
          ),
        ),
        const Divider(height: 1, color: DocColors.border),
        CodeBlock(code: DocScope.of(context).snippets['live']),
      ],
    ),
  );
}
