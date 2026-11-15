// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 docs/guide/index.md (MIT, chartjs-plugin-zoom contributors).
// The adjacent strings keep the lines of the prose short.

import 'package:chartjs_docs/examples/zoom/usage.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_links.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:material_ui/material_ui.dart';

/// The docs of the zoom plugin: the pages Getting Started, Integration and
/// Usage of the guide of chartjs-plugin-zoom.
DocPageContent zoomPluginPage() => DocPageContent(
  tabTitle: 'Zoom and pan',
  title: const Text('Zoom and pan'),
  navLabel: const Text('Zoom and pan'),
  icon: Icons.zoom_in,
  intro: const [
    DocParagraph(
      DocText(
        'A zoom and pan plugin for `flutter_chartjs_port`: the Dart port of '
        'chartjs-plugin-zoom 2.2.0.',
      ),
    ),
    DocParagraph(
      DocText(
        'Panning can be done with the mouse or with a finger. Zooming is '
        'done with the mouse wheel or with a pinch gesture. The plugin reads '
        'the pointer events of Flutter: it needs no other package.',
      ),
    ),
    DocLinks([
      DocUrlButton(
        url: 'https://pub.dev/packages/flutter_chartjs_plugin_zoom_port',
        label: Text('pub.dev'),
      ),
    ]),
  ],
  sections: [
    const DocSection(
      id: 'installation',
      title: Text('Installation'),
      body: [
        DocParagraph(DocText('Add the package to the app.')),
        DocCommand('flutter pub add flutter_chartjs_plugin_zoom_port'),
      ],
    ),
    const DocSection(
      id: 'integration',
      title: Text('Integration'),
      body: [
        DocParagraph(
          DocText(
            'Register the plugin one time, before the first chart. Then each '
            'chart reads the zoom options of its config.',
          ),
        ),
        DocCode(CodeRegion('$zoomExamples/register.dart', 'zoom-register')),
        DocParagraph(
          DocText(
            'To zoom one chart only, do not register the plugin: give it to '
            'that chart in `ChartConfig.plugins`.',
          ),
        ),
      ],
    ),
    DocSection(
      id: 'usage',
      title: const Text('Usage'),
      body: [
        const DocParagraph(
          DocText(
            'When the plugin is registered, a chart uses the zoom options of '
            'its config: one `ZoomPluginOptions` in `pluginOptions`. In this '
            'example, the mouse wheel and a pinch zoom the chart.',
          ),
        ),
        LiveExample(
          id: 'zoom-usage',
          description: 'A line chart that zooms',
          hint: const Text(
            'Scroll the mouse wheel over the chart, or pinch it, to zoom.',
          ),
          variants: [
            ExampleVariant(
              name: 'Usage',
              label: const Text('Usage'),
              // The page gives the plugin to this chart only.
              config: zoomUsage.copyWith(plugins: [zoomPlugin]),
              region: const CodeRegion(
                '$zoomExamples/usage.dart',
                'zoom-usage',
              ),
            ),
          ],
          actions: [
            ExampleAction(
              label: const Text('Reset zoom'),
              onPressed: (chart) => chart.resetZoom(),
            ),
          ],
        ),
      ],
    ),
    const DocSection(
      id: 'options',
      title: Text('Options'),
      body: [
        DocParagraph(
          DocText(
            'The options are the options of chartjs-plugin-zoom with Dart '
            'types: `ZoomOptions` for `zoom`, `PanOptions` for `pan`, and '
            'a `ScaleLimits` for each axis of `limits`. A mode is a value of '
            'the enum `Mode`, for example `Mode.xy`.',
          ),
        ),
        DocLinks([
          DocUrlButton(
            url: 'https://www.chartjs.org/chartjs-plugin-zoom/latest/guide/options.html',
            label: Text('The options of chartjs-plugin-zoom'),
          ),
        ]),
      ],
    ),
  ],
  credit: const Text(
    'The text follows the chartjs-plugin-zoom documentation (MIT).',
  ),
);
