// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// The adjacent strings keep the lines of the prose short.

import 'dart:async';
import 'dart:math' as math;

import 'package:chartjs_docs/examples/line_examples.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/docs_theme.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The rows of the table of dataset properties.
const List<DocProperty> lineProperties = [
  DocProperty(
    'backgroundColor',
    section: 'line-styling',
    type: 'ChartValue<ChartPaint>',
    scriptable: true,
    fallback: 'rgba(0, 0, 0, 0.1)',
  ),
  DocProperty(
    'borderCapStyle',
    section: 'line-styling',
    type: 'StrokeCap',
    fallback: 'StrokeCap.butt',
  ),
  DocProperty(
    'borderColor',
    section: 'line-styling',
    type: 'ChartValue<ChartPaint>',
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
    type: 'StrokeJoin',
    fallback: 'StrokeJoin.miter',
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
    type: 'ChartClip',
    fallback: 'undefined',
  ),
  DocProperty(
    'cubicInterpolationMode',
    section: 'cubic-interpolation-mode',
    type: 'CubicInterpolationMode',
    scriptable: true,
    fallback: 'DefaultCubicInterpolationMode()',
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
    type: 'FillTarget',
    scriptable: true,
    fallback: 'FillTarget.none',
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
    type: 'CartesianAxis',
    fallback: 'XAxis()',
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
    type: 'PointStyle',
    scriptable: true,
    indexable: true,
    fallback: 'CirclePointStyle()',
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
    type: 'LineSegmentStyle',
    fallback: 'none',
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
    type: 'SteppedLine or bool',
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
  tabTitle: 'Line Chart',
  title: const Text('Line Chart'),
  navLabel: const Text('Line chart'),
  icon: Icons.show_chart,
  intro: [
    const DocParagraph(
      DocText(
        'A line chart shows data points on a line. '
        'Use a line chart to show a trend or to compare two datasets.',
      ),
    ),
    const DocParagraph(
      DocText(
        'Register the chart components one time, before the first chart.',
      ),
    ),
    const DocCode(CodeRegion(examplesAsset, 'register')),
    const DocParagraph(
      DocText(
        'Then give a `ChartConfig` to a `ChartView`. '
        'The chart below is a live widget.',
      ),
    ),
    const LiveExample(
      id: 'basic',
      description: 'A line chart of seven months',
      variants: [
        ExampleVariant(
          name: 'Basic',
          label: Text('Basic'),
          config: basicLine,
          region: CodeRegion(examplesAsset, 'basic'),
        ),
      ],
    ),
  ],
  sections: [
    DocSection(
      id: 'dataset-properties',
      title: const Text('Dataset Properties'),
      body: [
        const DocParagraph(
          DocText('The chart reads an option from these scopes:'),
        ),
        const DocTable([
          (
            Text('LineDataset(...)'),
            DocText('The options of this dataset only.'),
          ),
          (
            Text("extra: {'datasets': {'line': ...}}"),
            DocText(
              'The options of all line datasets, in `ChartConfig.extra`.',
            ),
          ),
          (
            Text('ChartElements(line: ...)'),
            DocText(
              'The options of all line elements, in `ChartConfig.elements`.',
            ),
          ),
          (
            Text('ChartElements(point: ...)'),
            DocText(
              'The options of all point elements, in `ChartConfig.elements`.',
            ),
          ),
          (
            Text('ChartConfig(...)'),
            DocText('The options of the whole chart.'),
          ),
        ]),
        const LiveExample(
          id: 'scopes',
          description: 'A line chart with options in three scopes',
          variants: [
            ExampleVariant(
              name: 'Scopes',
              label: Text('Scopes'),
              config: scopedLine,
              region: CodeRegion(examplesAsset, 'scopes'),
            ),
          ],
        ),
        const DocParagraph(
          DocText(
            'Each dataset has properties. These properties set the look of '
            'that dataset. For example, a dataset usually sets the color of '
            'its line.',
          ),
        ),
        const DocParagraph(
          DocText(
            'The column **Set with** gives the place of the option in Dart. '
            'A **Parameter** is a named parameter of `LineDataset`. An option '
            'with no parameter goes in the `extra` Map of the dataset, under '
            'its Chart.js name.',
          ),
        ),
        const DocPropertyTable(lineProperties),
        const DocParagraph(
          DocText(
            'If a dataset does not set a value, the chart reads the next '
            'scope. A `null` parameter writes no key.',
          ),
        ),
      ],
      subsections: [
        DocSection(
          id: 'scriptable-indexable',
          title: const Text('Scriptable and Indexable Values'),
          body: [
            const DocParagraph(
              DocText(
                'A scriptable option takes a function. The chart calls the '
                'function for each data item. An indexable option takes a '
                'list, with one value for each data item.',
              ),
            ),
            const DocParagraph(
              DocText(
                '`backgroundColor` and `borderColor` take a `ChartValue`: '
                '`.constant`, `.indexed` or `.resolver`. Each other parameter '
                'takes one fixed value. For a function or a list on another '
                'option, use `extra` with the Chart.js name.',
              ),
            ),
            LiveExample(
              id: 'scriptable',
              description: 'A line chart with a color for each point',
              variants: [
                ExampleVariant(
                  name: 'Scriptable',
                  label: const Text('Scriptable'),
                  config: oneLine(scriptableLine),
                  region: const CodeRegion(examplesAsset, 'scriptable'),
                ),
              ],
            ),
            const DocTip(
              DocText(
                'Use a top-level function or a method tear-off. A new closure '
                'in each build is a new value, and the chart updates again.',
              ),
            ),
          ],
        ),
        const DocSection(
          id: 'general',
          title: Text('General'),
          body: [
            DocTable([
              (
                Text('clip'),
                DocText(
                  'How the chart clips the dataset at the chart area. A '
                  'positive value permits overflow. A negative value clips '
                  'that number of pixels inside the chart area. '
                  '`ChartClip.all(0)` clips at the chart area, and '
                  '`ChartClip.none` draws with no clip. `ChartClip` also '
                  'sets each side, for example '
                  '`ChartClip(left: 5, right: -2, bottom: 0)`: a side with '
                  'no value has no clip.',
                ),
              ),
              (
                Text('drawActiveElementsOnTop'),
                DocText(
                  'Draws the active points of a dataset over the other points '
                  'of that dataset.',
                ),
              ),
              (
                Text('indexAxis'),
                DocText(
                  'The base axis of the dataset. `XAxis()` gives horizontal '
                  'lines. `YAxis()` gives vertical lines.',
                ),
              ),
              (
                Text('label'),
                DocText(
                  'The name of the dataset in the legend and in the tooltip.',
                ),
              ),
              (
                Text('order'),
                DocText(
                  'The draw order of the dataset. The value also sets the '
                  'order of the stacks, of the tooltip and of the legend.',
                ),
              ),
              (
                Text('stack'),
                DocText(
                  'The ID of the group of the dataset. On a stacked axis, each '
                  'group is a separate stack. See '
                  '[Stacked Area Chart](#stacked-area-chart).',
                ),
              ),
              (
                Text('xAxisID'),
                DocText('The ID of the x axis of this dataset.'),
              ),
              (
                Text('yAxisID'),
                DocText('The ID of the y axis of this dataset.'),
              ),
            ]),
          ],
        ),
        DocSection(
          id: 'point-styling',
          title: const Text('Point Styling'),
          body: [
            const DocParagraph(
              DocText('These properties set the style of each point.'),
            ),
            const DocTable([
              (
                Text('pointBackgroundColor'),
                DocText('The fill color of the points.'),
              ),
              (
                Text('pointBorderColor'),
                DocText('The border color of the points.'),
              ),
              (
                Text('pointBorderWidth'),
                DocText('The width of the point border in pixels.'),
              ),
              (
                Text('pointHitRadius'),
                DocText(
                  'The size in pixels of the invisible area that reacts to '
                  'the pointer.',
                ),
              ),
              (
                Text('pointRadius'),
                DocText(
                  'The radius of the point shape. The chart does not draw a '
                  'point with the radius `0`.',
                ),
              ),
              (
                Text('pointRotation'),
                DocText('The rotation of the point in degrees.'),
              ),
              (Text('pointStyle'), DocText('The shape of the point.')),
            ]),
            LiveExample(
              id: 'point-styling',
              description: 'A line chart with a point style',
              variants: [
                for (final (label, style) in const [
                  ('circle', CirclePointStyle()),
                  ('rect', RectPointStyle()),
                  ('rectRot', RectRotPointStyle()),
                  ('triangle', TrianglePointStyle()),
                  ('star', StarPointStyle()),
                  ('cross', CrossPointStyle()),
                ])
                  ExampleVariant(
                    name: label,
                    label: Text(label),
                    config: pointStyling(style),
                    region: const CodeRegion(examplesAsset, 'point-styling'),
                  ),
              ],
            ),
            const DocParagraph(
              DocText(
                'If a value is not set, the chart reads the dataset options, '
                'and then the options of the point elements.',
              ),
            ),
          ],
        ),
        const DocSection(
          id: 'line-styling',
          title: Text('Line Styling'),
          body: [
            DocParagraph(
              DocText('These properties set the style of the line.'),
            ),
            DocTable([
              (Text('backgroundColor'), DocText('The fill color of the line.')),
              (
                Text('borderCapStyle'),
                DocText(
                  'The cap style of the line: a Flutter `StrokeCap` (`butt`, '
                  '`round` or `square`).',
                ),
              ),
              (Text('borderColor'), DocText('The color of the line.')),
              (
                Text('borderDash'),
                DocText('The lengths of the dashes and the gaps, in pixels.'),
              ),
              (
                Text('borderDashOffset'),
                DocText('The offset of the dashes, in pixels.'),
              ),
              (
                Text('borderJoinStyle'),
                DocText(
                  'The style of the line joints: a Flutter `StrokeJoin` '
                  '(`round`, `bevel` or `miter`).',
                ),
              ),
              (
                Text('borderWidth'),
                DocText('The width of the line in pixels.'),
              ),
              (
                Text('fill'),
                DocText('How the chart fills the area under the line.'),
              ),
              (
                Text('tension'),
                DocText(
                  'The Bézier curve tension of the line. The value `0` draws '
                  'straight lines. The monotone mode ignores this option.',
                ),
              ),
              (
                Text('shadow'),
                DocText(
                  'The shadow of the line and its points: a `ChartShadow` with '
                  'a color, a blur and an offset. The area fill has no '
                  'shadow. The shadow is not a Chart.js option.',
                ),
              ),
              (
                Text('showLine'),
                DocText(
                  'If `false`, the chart does not draw the line of this '
                  'dataset.',
                ),
              ),
              (
                Text('spanGaps'),
                DocText(
                  'If `true`, the chart draws the line across `null` values. '
                  'If `false`, a `null` value breaks the line. A number '
                  'gives the maximum gap to span, in the unit of the '
                  "scale. A number goes through `extra: {'spanGaps': 2}`.",
                ),
              ),
            ]),
            LiveExample(
              id: 'line-styling',
              description: 'A line chart with a line style',
              variants: [
                ExampleVariant(
                  name: 'Solid',
                  label: Text('Solid'),
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [solidLine],
                  ),
                  region: CodeRegion(examplesAsset, 'line-solid'),
                ),
                ExampleVariant(
                  name: 'Dashed',
                  label: Text('Dashed'),
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [dashedLine],
                  ),
                  region: CodeRegion(examplesAsset, 'line-dashed'),
                ),
                ExampleVariant(
                  name: 'Filled',
                  label: Text('Filled'),
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [filledLine],
                  ),
                  region: CodeRegion(examplesAsset, 'line-filled'),
                ),
                ExampleVariant(
                  name: 'Points only',
                  label: Text('Points only'),
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [pointsOnlyLine],
                  ),
                  region: CodeRegion(examplesAsset, 'line-points-only'),
                ),
                ExampleVariant(
                  name: 'Shadow',
                  label: Text('Shadow'),
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [shadowLine],
                  ),
                  region: CodeRegion(examplesAsset, 'line-shadow'),
                ),
              ],
            ),
            LiveExample(
              id: 'gaps',
              description: 'A line chart with null values',
              variants: [
                ExampleVariant(
                  name: 'spanGaps: false',
                  label: Text('spanGaps: false'),
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [brokenLine],
                  ),
                  region: CodeRegion(examplesAsset, 'gaps-break'),
                ),
                ExampleVariant(
                  name: 'spanGaps: true',
                  label: Text('spanGaps: true'),
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [spannedLine],
                  ),
                  region: CodeRegion(examplesAsset, 'gaps-span'),
                ),
              ],
            ),
            DocParagraph(
              DocText(
                'If a value is not set, the chart reads the options of the '
                'line elements.',
              ),
            ),
          ],
        ),
        const DocSection(
          id: 'interactions',
          title: Text('Interactions'),
          body: [
            DocParagraph(
              DocText(
                'These properties set the look of a point under the pointer.',
              ),
            ),
            DocTable([
              (
                Text('pointHoverBackgroundColor'),
                DocText('The fill color of a point under the pointer.'),
              ),
              (
                Text('pointHoverBorderColor'),
                DocText('The border color of a point under the pointer.'),
              ),
              (
                Text('pointHoverBorderWidth'),
                DocText('The border width of a point under the pointer.'),
              ),
              (
                Text('pointHoverRadius'),
                DocText('The radius of a point under the pointer.'),
              ),
            ]),
            LiveExample(
              id: 'interactions',
              description: 'A line chart with hover styles',
              hint: Text('Move the pointer over a point, or tap a point.'),
              variants: [
                ExampleVariant(
                  name: 'Hover',
                  label: Text('Hover'),
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [hoverLine],
                  ),
                  region: CodeRegion(examplesAsset, 'interactions'),
                ),
              ],
            ),
          ],
        ),
        const DocSection(
          id: 'cubic-interpolation-mode',
          title: Text('cubicInterpolationMode'),
          body: [
            DocParagraph(DocText('The chart has these interpolation modes:')),
            DocBullets([
              DocText(
                '`DefaultCubicInterpolationMode()` uses a weighted cubic '
                'interpolation. This mode gives smooth curves for all '
                'types of datasets.',
              ),
              DocText(
                '`MonotoneCubicInterpolationMode()` is better for `y = f(x)` '
                'datasets. This mode keeps the monotonicity of the data. '
                'A local extreme stays at a data point.',
              ),
            ]),
            DocParagraph(
              DocText(
                'If the dataset does not set the mode, the chart uses '
                '`cubicInterpolationMode` of the line elements.',
              ),
            ),
            DocParagraph(
              DocText(
                'An app or a plugin can give its own mode: a subclass of '
                '`CubicInterpolationMode` with the methods `drawsCurves` and '
                '`updateControlPoints`.',
              ),
            ),
            LiveExample(
              id: 'cubic',
              description: 'A line chart of two interpolation modes',
              variants: [
                ExampleVariant(
                  name: 'Modes',
                  label: Text('Modes'),
                  config: cubicLines,
                  region: CodeRegion(examplesAsset, 'cubic'),
                ),
              ],
            ),
          ],
        ),
        const DocSection(
          id: 'segment',
          title: Text('Segment'),
          body: [
            DocParagraph(
              DocText(
                'The functions of a `LineSegmentStyle` in `segment` change the '
                'style of a part of the line. It has a function for each '
                '`border*` option and for `backgroundColor`. The chart calls '
                'them for each part of the line between two points. A '
                'function that returns `null` keeps the style of the line.',
              ),
            ),
            DocTip(DocText('To style a gap, set `spanGaps` to `true`.')),
            DocParagraph(
              DocText(
                'A segment function takes a `ScriptableLineSegmentContext`, '
                'with these fields:',
              ),
            ),
            DocTable([
              (Text('p0'), DocText('The first point element.')),
              (Text('p1'), DocText('The second point element.')),
              (
                Text('p0DataIndex'),
                DocText('The index of the first point in the data.'),
              ),
              (
                Text('p1DataIndex'),
                DocText('The index of the second point in the data.'),
              ),
              (Text('datasetIndex'), DocText('The index of the dataset.')),
            ]),
            DocParagraph(
              DocText(
                'This example draws a falling part in red. It draws a gap '
                'with a dashed gray line.',
              ),
            ),
            LiveExample(
              id: 'segment',
              description: 'A line chart with styled segments',
              variants: [
                ExampleVariant(
                  name: 'Segments',
                  label: Text('Segments'),
                  config: segmentLine,
                  region: CodeRegion(examplesAsset, 'segment'),
                ),
              ],
            ),
          ],
        ),
        const DocSection(
          id: 'stepped',
          title: Text('Stepped'),
          body: [
            DocParagraph(DocText('`stepped` takes these values:')),
            DocBullets([
              DocText(
                '`false`: no step interpolation. This value is the default.',
              ),
              DocText(
                '`true`: step-before interpolation. It is the same as '
                '`SteppedLine.before`.',
              ),
              DocText('`SteppedLine.before`: step-before interpolation.'),
              DocText('`SteppedLine.after`: step-after interpolation.'),
              DocText('`SteppedLine.middle`: step-middle interpolation.'),
            ]),
            DocParagraph(
              DocText(
                'The parameter `stepped` takes a `SteppedLine`. The value '
                '`true` goes through `extra`. If `stepped` is not `false`, the '
                'chart ignores `tension`.',
              ),
            ),
            LiveExample(
              id: 'stepped',
              description: 'A stepped line chart',
              variants: [
                ExampleVariant(
                  name: 'false',
                  label: Text('false'),
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [noStep],
                  ),
                  region: CodeRegion(examplesAsset, 'stepped-false'),
                ),
                ExampleVariant(
                  name: 'true',
                  label: Text('true'),
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [stepTrue],
                  ),
                  region: CodeRegion(examplesAsset, 'stepped-true'),
                ),
                ExampleVariant(
                  name: '.before',
                  label: Text('.before'),
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [stepBefore],
                  ),
                  region: CodeRegion(examplesAsset, 'stepped-before'),
                ),
                ExampleVariant(
                  name: '.after',
                  label: Text('.after'),
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [stepAfter],
                  ),
                  region: CodeRegion(examplesAsset, 'stepped-after'),
                ),
                ExampleVariant(
                  name: '.middle',
                  label: Text('.middle'),
                  config: ChartConfig(
                    type: .line,
                    labels: months,
                    datasets: [stepMiddle],
                  ),
                  region: CodeRegion(examplesAsset, 'stepped-middle'),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    const DocSection(
      id: 'default-options',
      title: Text('Default Options'),
      body: [
        DocParagraph(
          DocText(
            'To apply a setting to all line charts, change the global line '
            'chart settings. A change has an effect only on the charts that '
            'the app creates after the change. Existing charts do not change.',
          ),
        ),
        DocParagraph(
          DocText(
            'For example, this call sets `spanGaps` to `true` for all line '
            'charts:',
          ),
        ),
        DocCode(CodeRegion(examplesAsset, 'defaults')),
      ],
    ),
    DocSection(
      id: 'data-structure',
      title: const Text('Data Structure'),
      body: [
        const DocParagraph(
          DocText(
            'A `LineDataset` takes `data` or `points`, not both. The parameter '
            '`data` holds one value for each label. A `null` value is a gap.',
          ),
        ),
        const DocParagraph(
          DocText(
            'The parameter `points` holds `DataPoint` items. Use `DataPoint` '
            'with a number on a `LinearAxis`, `DataPoint.time` with a '
            '`DateTime` on a time axis, and `DataPoint.label` with a '
            'category.',
          ),
        ),
        const DocParagraph(
          DocText(
            'The chart reads the List of the app with no copy. For new values, '
            'give a new List in a new `ChartConfig`.',
          ),
        ),
        LiveExample(
          id: 'data',
          description: 'A line chart of two data forms',
          variants: [
            const ExampleVariant(
              name: 'data',
              label: Text('data'),
              config: valuesLine,
              region: CodeRegion(examplesAsset, 'data-values'),
            ),
            ExampleVariant(
              name: 'points',
              label: const Text('points'),
              config: pointsLine,
              region: const CodeRegion(examplesAsset, 'data-points'),
            ),
          ],
        ),
        const DocParagraph(
          DocText(
            'For the other Chart.js data forms, use `ChartView.raw` with the '
            'config as a Dart `Map`.',
          ),
        ),
      ],
    ),
    const DocSection(
      id: 'stacked-area-chart',
      title: Text('Stacked Area Chart'),
      body: [
        DocParagraph(
          DocText(
            'To make a stacked area chart, set `stacked` on the y axis. A '
            'stacked area chart shows how a number of smaller parts make one '
            'trend.',
          ),
        ),
        LiveExample(
          id: 'stacked',
          description: 'A stacked area chart of three datasets',
          variants: [
            ExampleVariant(
              name: 'Stacked',
              label: Text('Stacked'),
              config: stackedLines,
              region: CodeRegion(examplesAsset, 'stacked'),
            ),
          ],
        ),
      ],
    ),
    const DocSection(
      id: 'vertical-line-chart',
      title: Text('Vertical Line Chart'),
      body: [
        DocParagraph(
          DocText(
            'A vertical line chart is a variation of the horizontal line '
            'chart. To make a vertical line chart, set `indexAxis` to '
            '`YAxis()`. The default is `XAxis()`, which gives horizontal '
            'lines.',
          ),
        ),
        LiveExample(
          id: 'vertical',
          description: 'A vertical line chart',
          variants: [
            ExampleVariant(
              name: 'Vertical',
              label: Text('Vertical'),
              config: verticalLine,
              region: CodeRegion(examplesAsset, 'vertical'),
            ),
          ],
        ),
      ],
      subsections: [
        DocSection(
          id: 'config-options',
          title: Text('Config Options'),
          body: [
            DocParagraph(
              DocText(
                'A vertical line chart has the options of a line chart. '
                'But an option of the x axis in a line chart applies to the '
                'y axis in a vertical line chart.',
              ),
            ),
          ],
        ),
      ],
    ),
    const DocSection(
      id: 'internal-data-format',
      title: Text('Internal Data Format'),
      body: [
        DocParagraph(
          DocText(
            'The chart keeps each parsed item as `{x, y}`. If the data is '
            'already in this form and sorted, set `parsing` to `false`. The '
            'chart then skips the parse step.',
          ),
        ),
        DocCode(CodeRegion(examplesAsset, 'internal-format')),
      ],
    ),
    const DocSection(
      id: 'live-data',
      title: Text('Live Data'),
      body: [
        DocParagraph(
          DocText(
            'This section has no Chart.js counterpart. A chart that gets new '
            'data in each frame can skip the layout. Set `dataOnlyUpdates` to '
            "`true`, `updateMode` to `'none'` and `animation` to "
            '`ChartAnimation.none`. Give fixed `min` and `max` values to the '
            'axes.',
          ),
        ),
        DocParagraph(
          DocText(
            'The chart then does a data-only update when only the data Lists '
            'of the new config change. Another change does a full update.',
          ),
        ),
        LiveLineDemo(),
      ],
    ),
  ],
);

/// A chart of 1,000 points that changes in each frame while it runs.
class const LiveLineDemo({super.key}) extends StatefulWidget {
  /// Creates the demo.
  this;

  @override
  State<LiveLineDemo> createState() => _LiveLineDemoState();
}

class _LiveLineDemoState() extends State<LiveLineDemo> {
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
  Widget build(BuildContext context) => DocPanel(
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
          child: RepaintBoundary(child: LiveLineChart(points: _current)),
        ),
        const Divider(height: 1, color: DocColors.border),
        const CodeToggle(id: 'live', region: CodeRegion(examplesAsset, 'live')),
      ],
    ),
  );
}
