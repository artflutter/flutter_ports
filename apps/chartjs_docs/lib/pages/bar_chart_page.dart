// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// The adjacent strings keep the lines of the prose short.
// ignore_for_file: no_adjacent_strings_in_list

import 'package:chartjs_docs/examples/bar_examples.dart';
import 'package:chartjs_docs/examples/line_examples.dart' show months;
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The rows of the table of dataset properties.
const List<DocProperty> barProperties = [
  DocProperty(
    'backgroundColor',
    section: 'styling',
    type: 'ChartValue<ChartPaint>',
    scriptable: true,
    indexable: true,
    fallback: 'rgba(0, 0, 0, 0.1)',
  ),
  DocProperty(
    'base',
    section: 'general',
    type: 'double',
    extra: true,
    scriptable: true,
    indexable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'barPercentage',
    section: 'barpercentage',
    type: 'double',
    fallback: '0.9',
  ),
  DocProperty(
    'barThickness',
    section: 'barthickness',
    type: 'double',
    fallback: 'undefined',
  ),
  DocProperty(
    'borderColor',
    section: 'styling',
    type: 'ChartValue<ChartPaint>',
    scriptable: true,
    indexable: true,
    fallback: 'rgba(0, 0, 0, 0.1)',
  ),
  DocProperty(
    'borderSkipped',
    section: 'borderskipped',
    type: 'BorderSkippedEdge or bool',
    extra: true,
    scriptable: true,
    indexable: true,
    fallback: 'BorderSkippedEdge.start',
  ),
  DocProperty(
    'borderWidth',
    section: 'borderwidth',
    type: 'double',
    scriptable: true,
    indexable: true,
    fallback: '0',
  ),
  DocProperty(
    'borderRadius',
    section: 'borderradius',
    type: 'double',
    scriptable: true,
    indexable: true,
    fallback: '0',
  ),
  DocProperty(
    'categoryPercentage',
    section: 'categorypercentage',
    type: 'double',
    fallback: '0.8',
  ),
  DocProperty(
    'clip',
    section: 'general',
    type: 'ChartClip',
    fallback: 'undefined',
  ),
  DocProperty(
    'data',
    section: 'data-structure',
    type: 'List<num?>',
    fallback: 'required',
  ),
  DocProperty('grouped', section: 'general', type: 'bool', fallback: 'true'),
  DocProperty(
    'hoverBackgroundColor',
    section: 'interactions',
    type: 'ChartValue<ChartPaint>',
    scriptable: true,
    indexable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'hoverBorderColor',
    section: 'interactions',
    type: 'ChartValue<ChartPaint>',
    scriptable: true,
    indexable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'hoverBorderWidth',
    section: 'interactions',
    type: 'double',
    scriptable: true,
    indexable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'hoverBorderRadius',
    section: 'interactions',
    type: 'double',
    extra: true,
    scriptable: true,
    indexable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'indexAxis',
    section: 'general',
    type: 'CartesianAxis',
    fallback: 'XAxis()',
  ),
  DocProperty(
    'inflateAmount',
    section: 'inflateamount',
    type: 'double or String',
    extra: true,
    scriptable: true,
    indexable: true,
    fallback: "'auto'",
  ),
  DocProperty(
    'maxBarThickness',
    section: 'maxbarthickness',
    type: 'double',
    fallback: 'undefined',
  ),
  DocProperty(
    'minBarLength',
    section: 'styling',
    type: 'double',
    fallback: 'undefined',
  ),
  DocProperty('label', section: 'general', type: 'String', fallback: "''"),
  DocProperty('order', section: 'general', type: 'int', fallback: '0'),
  DocProperty(
    'pointStyle',
    section: 'styling',
    type: 'PointStyle',
    extra: true,
    scriptable: true,
    fallback: 'undefined',
  ),
  DocProperty(
    'points',
    section: 'data-structure',
    type: 'List<DataPoint>',
    fallback: 'none',
  ),
  DocProperty(
    'shadow',
    section: 'styling',
    type: 'ChartShadow',
    fallback: 'no shadow',
  ),
  DocProperty(
    'skipNull',
    section: 'general',
    type: 'bool',
    extra: true,
    fallback: 'undefined',
  ),
  DocProperty('stack', section: 'general', type: 'String', fallback: "'bar'"),
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

/// A chart with the one dataset [dataset] over [months].
ChartConfig _oneBar(BarDataset dataset) =>
    ChartConfig(type: .bar, labels: months, datasets: [dataset]);

/// The content of the bar chart page.
DocPageContent barChartPage() => DocPageContent(
  title: 'Bar Chart',
  navLabel: 'Bar chart',
  icon: Icons.bar_chart,
  intro: [
    const DocParagraph(
      'A bar chart shows data values as vertical bars. '
      'Use a bar chart to show trend data, or to compare several datasets '
      'side by side.',
    ),
    const DocParagraph(
      'Register the chart components one time, before the first chart.',
    ),
    const DocCode('register'),
    const LiveExample(
      id: 'basic',
      description: 'A bar chart of seven months',
      variants: [
        ExampleVariant(label: 'Basic', config: basicBar, region: 'bar-basic'),
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
          ('BarDataset(...)', 'The options of this dataset only.'),
          (
            "extra: {'datasets': {'bar': ...}}",
            'The options of all bar datasets, in `ChartConfig.extra`.',
          ),
          (
            'ChartElements(bar: ...)',
            'The options of all bar elements, in `ChartConfig.elements`.',
          ),
          ('ChartConfig(...)', 'The options of the whole chart.'),
        ]),
        const LiveExample(
          id: 'scopes',
          description: 'A bar chart with options in three scopes',
          variants: [
            ExampleVariant(
              label: 'Scopes',
              config: scopedBar,
              region: 'bar-scopes',
            ),
          ],
        ),
        const DocParagraph(
          'Each dataset has properties. These properties set the look of '
          'that dataset. For example, a dataset usually sets the color of '
          'its bars. Only `data` or `points` must be in the dataset.',
        ),
        const DocParagraph(
          'The column **Set with** gives the place of the option in Dart. '
          'A **Parameter** is a named parameter of `BarDataset`. An option '
          'with no parameter goes in the `extra` Map of the dataset, under '
          'its Chart.js name.',
        ),
        const DocPropertyTable(barProperties),
        const DocParagraph(
          'If a dataset does not set a value, the chart reads the next '
          'scope. A `null` parameter writes no key.',
        ),
        const DocTip(
          'A scriptable option takes a function, and an indexable option '
          'takes a list. `backgroundColor`, `borderColor`, '
          '`hoverBackgroundColor` and `hoverBorderColor` take a `ChartValue`: '
          '`.constant`, `.indexed` or `.resolver`. For a function or a list '
          'on another option, use `extra` with the Chart.js name.',
        ),
      ],
      subsections: [
        const DocSection(
          id: 'example-dataset-configuration',
          title: 'Example Dataset Configuration',
          body: [
            DocParagraph(
              'This dataset sets the size of its bars. The bars are 6 pixels '
              'wide, and each bar is at least 2 pixels long.',
            ),
            LiveExample(
              id: 'dataset-config',
              description: 'A bar chart with thin bars',
              variants: [
                ExampleVariant(
                  label: 'Thin bars',
                  config: thinBars,
                  region: 'bar-dataset-config',
                ),
              ],
            ),
          ],
        ),
        const DocSection(
          id: 'general',
          title: 'General',
          body: [
            DocTable([
              (
                'base',
                'The base value of the bar, in the units of the value axis. '
                    'If this value is not set, the bar starts at the base '
                    'value of the value axis.',
              ),
              (
                'clip',
                'How the chart clips the dataset at the chart area. A '
                    'positive value permits overflow. A negative value clips '
                    'that number of pixels inside the chart area. '
                    '`ChartClip.all(0)` clips at the chart area, and '
                    '`ChartClip.none` draws with no clip. `ChartClip` also '
                    'sets each side, for example '
                    '`ChartClip(left: 5, right: -2, bottom: 0)`: a side with '
                    'no value has no clip.',
              ),
              (
                'grouped',
                'If `true`, the chart puts the bars of all datasets at one '
                    'index next to each other, around the index value. If '
                    '`false`, the chart puts each bar at its index value.',
              ),
              (
                'indexAxis',
                'The base axis of the dataset. `XAxis()` gives vertical '
                    'bars. `YAxis()` gives horizontal bars.',
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
                'skipNull',
                'If `true`, the chart does not keep space for the `null` '
                    'values when it calculates the size of the bars.',
              ),
              (
                'stack',
                'The ID of the group of the dataset. On a stacked axis, each '
                    'group is a separate stack. See '
                    '[Stacked Bar Chart](#stacked-bar-chart).',
              ),
              ('xAxisID', 'The ID of the x axis of this dataset.'),
              ('yAxisID', 'The ID of the y axis of this dataset.'),
            ]),
            LiveExample(
              id: 'general',
              description: 'A bar chart with general options',
              variants: [
                ExampleVariant(
                  label: 'grouped',
                  config: groupedBars,
                  region: 'bar-grouped',
                ),
                ExampleVariant(
                  label: 'grouped: false',
                  config: ungroupedBars,
                  region: 'bar-ungrouped',
                ),
                ExampleVariant(
                  label: 'skipNull',
                  config: skipNullBars,
                  region: 'bar-skip-null',
                ),
                ExampleVariant(
                  label: 'base',
                  config: baseBars,
                  region: 'bar-base',
                ),
              ],
            ),
          ],
        ),
        const DocSection(
          id: 'styling',
          title: 'Styling',
          body: [
            DocParagraph('These properties set the style of each bar.'),
            DocTable([
              ('backgroundColor', 'The fill color of the bar.'),
              ('borderColor', 'The border color of the bar.'),
              (
                'borderSkipped',
                'The edge of the bar with no border. See '
                    '[borderSkipped](#borderskipped).',
              ),
              (
                'borderWidth',
                'The border width of the bar in pixels. See '
                    '[borderWidth](#borderwidth).',
              ),
              (
                'borderRadius',
                'The border radius of the bar in pixels. See '
                    '[borderRadius](#borderradius).',
              ),
              ('minBarLength', 'The minimum length of a bar in pixels.'),
              ('pointStyle', 'The style of the point of the legend item.'),
              (
                'shadow',
                'The shadow of the bars: a `ChartShadow` with a color, a '
                    'blur and an offset. The shadow is not a Chart.js '
                    'option.',
              ),
            ]),
            LiveExample(
              id: 'styling',
              description: 'A bar chart with a bar style',
              variants: [
                ExampleVariant(
                  label: 'Colors',
                  config: coloredBars,
                  region: 'bar-colors',
                ),
                ExampleVariant(
                  label: 'minBarLength',
                  config: minLengthBars,
                  region: 'bar-min-length',
                ),
                ExampleVariant(
                  label: 'Shadow',
                  config: shadowBars,
                  region: 'bar-shadow',
                ),
              ],
            ),
            DocParagraph(
              'If a value is not set, the chart reads the options of the bar '
              'elements.',
            ),
          ],
        ),
        DocSection(
          id: 'borderskipped',
          title: 'borderSkipped',
          body: [
            const DocParagraph(
              'This option removes the border at the base of the bar, or '
              'removes the border radius. Usually, only a chart type that '
              'extends the bar chart changes it.',
            ),
            const DocTip(
              'For a negative bar in a vertical chart, `top` and `bottom` '
              'change places. For a negative bar in a horizontal chart, '
              '`left` and `right` change places.',
            ),
            const DocParagraph(
              '`borderSkipped` takes these values, through `extra`:',
            ),
            const DocBullets([
              '`BorderSkippedEdge.start`',
              '`BorderSkippedEdge.end`',
              '`BorderSkippedEdge.middle`: only on stacked bars. The chart '
                  'skips the borders between the bars.',
              '`BorderSkippedEdge.bottom`',
              '`BorderSkippedEdge.left`',
              '`BorderSkippedEdge.top`',
              '`BorderSkippedEdge.right`',
              '`false`: the chart skips no border.',
              '`true`: the chart skips all borders.',
            ]),
            LiveExample(
              id: 'border-skipped',
              description: 'A bar chart with a skipped border',
              variants: [
                for (final (label, value) in const [
                  ('.start', BorderSkippedEdge.start),
                  ('.end', BorderSkippedEdge.end),
                  ('false', false),
                  ('true', true),
                ])
                  ExampleVariant(
                    label: label,
                    config: borderSkipped(value),
                    region: 'bar-border-skipped',
                  ),
              ],
            ),
          ],
        ),
        DocSection(
          id: 'borderwidth',
          title: 'borderWidth',
          body: [
            const DocParagraph(
              'A number applies to the four sides of the bar, except the '
              '[borderSkipped](#borderskipped) side. The object form sets '
              'each side: the keys `left`, `top`, `right` and `bottom`. The '
              'object form goes through `extra`. The chart skips an omitted '
              'side and the `borderSkipped` side.',
            ),
            LiveExample(
              id: 'border-width',
              description: 'A bar chart with a border width',
              variants: [
                ExampleVariant(
                  label: 'Number',
                  config: _oneBar(sameBorders),
                  region: 'bar-border-width',
                ),
                ExampleVariant(
                  label: 'Object',
                  config: _oneBar(sideBorders),
                  region: 'bar-border-width-object',
                ),
              ],
            ),
          ],
        ),
        DocSection(
          id: 'borderradius',
          title: 'borderRadius',
          body: [
            const DocParagraph(
              'A number applies to the four corners of the bar, except the '
              'corners at the [borderSkipped](#borderskipped) edge. The '
              'object form sets each corner: the keys `topLeft`, `topRight`, '
              '`bottomLeft` and `bottomRight`. The object form goes through '
              '`extra`. The chart skips an omitted corner and the corners at '
              'the `borderSkipped` edge. For example, if the chart skips the '
              '`top` border, it also skips the corners `topLeft` and '
              '`topRight`.',
            ),
            const DocTip(
              'In a stacked chart, a number rounds only the bars at the ends '
              'of a stack and the floating bars. To round other bars, use '
              'the object form.',
            ),
            LiveExample(
              id: 'border-radius',
              description: 'A bar chart with rounded corners',
              variants: [
                ExampleVariant(
                  label: 'Number',
                  config: _oneBar(roundedBars),
                  region: 'bar-border-radius',
                ),
                ExampleVariant(
                  label: 'All corners',
                  config: _oneBar(roundBars),
                  region: 'bar-border-radius-all',
                ),
                ExampleVariant(
                  label: 'Object',
                  config: _oneBar(cornerBars),
                  region: 'bar-border-radius-object',
                ),
                const ExampleVariant(
                  label: 'Stacked',
                  config: roundedStack,
                  region: 'bar-border-radius-stacked',
                ),
              ],
            ),
          ],
        ),
        const DocSection(
          id: 'inflateamount',
          title: 'inflateAmount',
          body: [
            DocParagraph(
              'This option makes the rectangles of the bars larger, in '
              'pixels. It hides the thin gaps between the bars when '
              '[barPercentage](#barpercentage) multiplied by '
              '[categoryPercentage](#categorypercentage) is 1. The default '
              "value `'auto'` is correct for most charts. A number goes "
              "through `extra: {'inflateAmount': 0.5}`.",
            ),
          ],
        ),
        DocSection(
          id: 'interactions',
          title: 'Interactions',
          body: [
            const DocParagraph(
              'These properties set the look of a bar under the pointer.',
            ),
            const DocTable([
              (
                'hoverBackgroundColor',
                'The fill color of a bar under the pointer.',
              ),
              (
                'hoverBorderColor',
                'The border color of a bar under the pointer.',
              ),
              (
                'hoverBorderWidth',
                'The border width of a bar under the pointer, in pixels.',
              ),
              (
                'hoverBorderRadius',
                'The border radius of a bar under the pointer, in pixels.',
              ),
            ]),
            LiveExample(
              id: 'interactions',
              description: 'A bar chart with hover styles',
              hint: 'Move the pointer over a bar, or tap a bar.',
              variants: [
                ExampleVariant(
                  label: 'Hover',
                  config: _oneBar(hoverBars),
                  region: 'bar-interactions',
                ),
              ],
            ),
            const DocParagraph(
              'If a value is not set, the chart reads the options of the bar '
              'elements.',
            ),
          ],
        ),
        const DocSection(
          id: 'barpercentage',
          title: 'barPercentage',
          body: [
            DocParagraph(
              'The part of the category width that each bar takes, from 0 to '
              '1. The value 1 gives the whole category width to the bars. The '
              'bars then touch. See '
              '[the two percentages](#barpercentage-vs-categorypercentage).',
            ),
          ],
        ),
        const DocSection(
          id: 'categorypercentage',
          title: 'categoryPercentage',
          body: [
            DocParagraph(
              'The part of the sample width that each category takes, from 0 '
              'to 1. See '
              '[the two percentages](#barpercentage-vs-categorypercentage).',
            ),
          ],
        ),
        DocSection(
          id: 'barthickness',
          title: 'barThickness',
          body: [
            const DocParagraph(
              'A number sets the width of each bar, in pixels. The chart '
              'then ignores `barPercentage` and `categoryPercentage`.',
            ),
            const DocParagraph(
              "The value `'flex'` goes through `extra`. The chart then "
              'calculates the width of each sample from the samples before '
              'and after it, so that the bars fill the space with no '
              'overlap. Then `barPercentage` and `categoryPercentage` set the '
              'size of the bars. If the two percentages are 1, the bars have '
              'no gap. If the data is not evenly spaced, the bars have '
              'different widths.',
            ),
            const DocParagraph(
              'If the value is not set, the chart calculates the width of the '
              'samples from the smallest interval with no overlap. Then '
              '`barPercentage` and `categoryPercentage` set the size of the '
              'bars. All bars have the same width.',
            ),
            LiveExample(
              id: 'bar-thickness',
              description: 'A bar chart of unevenly spaced data',
              variants: [
                ExampleVariant(
                  label: 'Not set',
                  config: fitBars,
                  region: 'bar-thickness-default',
                ),
                ExampleVariant(
                  label: '12',
                  config: fixedBars,
                  region: 'bar-thickness-number',
                ),
                ExampleVariant(
                  label: "'flex'",
                  config: flexBars,
                  region: 'bar-thickness-flex',
                ),
              ],
            ),
          ],
        ),
        const DocSection(
          id: 'maxbarthickness',
          title: 'maxBarThickness',
          body: [
            DocParagraph(
              'The maximum width of a bar, in pixels. A bar is never wider '
              'than this value.',
            ),
          ],
        ),
      ],
    ),
    const DocSection(
      id: 'scale-configuration',
      title: 'Scale Configuration',
      body: [
        DocParagraph(
          'The bar chart sets its own default values for these options of '
          'the index axis:',
        ),
        DocTable([
          (
            'offset',
            'Default `true`. If `true`, the chart adds space at the two '
                'edges, and the axis fits in the chart area. A '
                "`CategoryAxis` takes it through `extra: {'offset': false}`.",
          ),
          (
            'grid.offset',
            'Default `true`. If `true`, the bars of a data point are between '
                'the grid lines. Set it with `AxisGrid(offset: ...)`. See '
                '[Offset Grid Lines](#offset-grid-lines).',
          ),
        ]),
      ],
      subsections: [
        DocSection(
          id: 'offset-grid-lines',
          title: 'Offset Grid Lines',
          body: [
            DocParagraph(
              'If `true`, the bars of a data point are between the grid '
              'lines. The grid line moves to the left by one half of the '
              'tick interval, that is the space between the grid lines. If '
              '`false`, the grid line goes through the middle of the bars. '
              'The default is `true` for a category axis in a bar chart. It '
              'is `false` for other axes and for other chart types.',
            ),
            LiveExample(
              id: 'grid-offset',
              description: 'A bar chart with grid lines',
              variants: [
                ExampleVariant(
                  label: 'offset: true',
                  config: offsetGrid,
                  region: 'bar-grid-offset',
                ),
                ExampleVariant(
                  label: 'offset: false',
                  config: centeredGrid,
                  region: 'bar-grid-centered',
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
          'To apply a setting to all bar charts, change the global bar chart '
          'settings. A change has an effect only on the charts that the app '
          'creates after the change. Existing charts do not change.',
        ),
        DocParagraph(
          'For example, this call sets `skipNull` to `true` for all bar '
          'charts:',
        ),
        DocCode('bar-defaults'),
      ],
    ),
    DocSection(
      id: 'barpercentage-vs-categorypercentage',
      title: 'barPercentage vs categoryPercentage',
      body: [
        const DocParagraph(
          'The sample is the space of one index on the axis. '
          '`categoryPercentage` gives the part of the sample that the '
          'category takes. `barPercentage` gives the part of the category '
          'that the bars take. This chart has two datasets: each category '
          'has two bars.',
        ),
        LiveExample(
          id: 'percentages',
          description: 'A bar chart with two percentages',
          variants: [
            for (final (label, category, bar) in const [
              ('category 1.0 · bar 1.0', 1.0, 1.0),
              ('category 1.0 · bar 0.5', 1.0, 0.5),
              ('category 0.5 · bar 1.0', 0.5, 1.0),
            ])
              ExampleVariant(
                label: label,
                config: percentages(category: category, bar: bar),
                region: 'bar-percentages',
              ),
          ],
        ),
      ],
    ),
    DocSection(
      id: 'data-structure',
      title: 'Data Structure',
      body: [
        const DocParagraph(
          'A `BarDataset` takes `data` or `points`, not both. The parameter '
          '`data` holds one value for each label. A `null` value is a gap.',
        ),
        const DocParagraph(
          'The parameter `points` holds `DataPoint` items. Use '
          '`DataPoint.label` with a category, `DataPoint` with a number on a '
          '`LinearAxis`, and `DataPoint.time` with a `DateTime` on a time '
          'axis.',
        ),
        LiveExample(
          id: 'data',
          description: 'A bar chart of two data forms',
          variants: [
            const ExampleVariant(
              label: 'data',
              config: valuesBar,
              region: 'bar-data-values',
            ),
            ExampleVariant(
              label: 'points',
              config: pointsBar,
              region: 'bar-data-points',
            ),
          ],
        ),
        const DocParagraph(
          'A floating bar takes a pair `[start, end]` for each label. For '
          'this form and for the other Chart.js data forms, use '
          '`ChartView.raw` with the config as a Dart `Map`.',
        ),
      ],
    ),
    const DocSection(
      id: 'stacked-bar-chart',
      title: 'Stacked Bar Chart',
      body: [
        DocParagraph(
          'To make a stacked bar chart, set `stacked` on the x axis and on '
          'the y axis. A stacked bar chart shows how a number of smaller '
          'parts make one data series.',
        ),
        DocParagraph(
          'The datasets with the same `stack` make one stack. The second '
          'form has two stacks at each label.',
        ),
        LiveExample(
          id: 'stacked',
          description: 'A stacked bar chart',
          variants: [
            ExampleVariant(
              label: 'Stacked',
              config: stackedBars,
              region: 'bar-stacked',
            ),
            ExampleVariant(
              label: 'Two stacks',
              config: groupedStacks,
              region: 'bar-stack-groups',
            ),
          ],
        ),
      ],
    ),
    const DocSection(
      id: 'horizontal-bar-chart',
      title: 'Horizontal Bar Chart',
      body: [
        DocParagraph(
          'A horizontal bar chart is a variation of the vertical bar chart. '
          'To make a horizontal bar chart, set `indexAxis` to `YAxis()`. '
          'The default is `XAxis()`, which gives vertical bars.',
        ),
        LiveExample(
          id: 'horizontal',
          description: 'A horizontal bar chart',
          variants: [
            ExampleVariant(
              label: 'Horizontal',
              config: horizontalBar,
              region: 'bar-horizontal',
            ),
          ],
        ),
      ],
      subsections: [
        DocSection(
          id: 'horizontal-config-options',
          title: 'Horizontal Bar Chart Config Options',
          body: [
            DocParagraph(
              'A horizontal bar chart has the options of a '
              '[bar chart](#scale-configuration). But an option of the x axis '
              'in a bar chart applies to the y axis in a horizontal bar '
              'chart.',
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
          'The chart keeps each parsed item as `{x, y, _custom}`. `_custom` '
          'is an optional object with the properties of a floating or a '
          'stacked bar: `{start, end, barStart, barEnd, min, max}`.',
        ),
        DocParagraph(
          '`start` and `end` are the input values. The chart copies them to '
          '`barStart` (nearer to the origin), `barEnd` (farther from the '
          'origin), `min` and `max`.',
        ),
      ],
    ),
  ],
);
