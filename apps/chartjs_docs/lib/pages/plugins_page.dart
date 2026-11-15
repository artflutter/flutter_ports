// Original code, not ported from Chart.js: the list of the plugins of the port.

import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_links.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:material_ui/material_ui.dart';

/// The page of the plugins: one section for each plugin, with its package
/// and its docs page.
DocPageContent awesomePluginsPage() => const DocPageContent(
  tabTitle: 'Awesome plugins',
  title: Text('Awesome plugins'),
  navLabel: Text('Overview'),
  icon: Icons.extension,
  intro: [
    DocParagraph(
      DocText(
        'A plugin adds a feature to the charts. Each plugin on this page is '
        'a Dart port of a Chart.js plugin, in a package of its own on '
        'pub.dev.',
      ),
    ),
    DocParagraph(
      DocText(
        'A plugin uses only the public libraries of `flutter_chartjs_port`. '
        'Add its package to the app. Then register the plugin for each '
        'chart, or give it to one chart in `ChartConfig.plugins`.',
      ),
    ),
  ],
  sections: [
    DocSection(
      id: 'zoom',
      title: Text('Zoom and pan'),
      body: [
        DocParagraph(
          DocText(
            'Zoom with the mouse wheel, a drag or a pinch, and pan with the '
            'mouse or a finger. The plugin can keep each axis in limits.',
          ),
        ),
        DocTable([
          (Text('Package'), DocText('`flutter_chartjs_plugin_zoom_port`')),
          (Text('Port of'), DocText('chartjs-plugin-zoom 2.2.0')),
          (Text('License'), DocText('MIT')),
        ]),
        DocParagraph(
          DocText('After `flutter pub add`, register the plugin one time.'),
        ),
        DocCode(CodeRegion('$zoomExamples/register.dart', 'zoom-register')),
        DocLinks([
          DocPageButton(route: '/plugins/zoom', label: Text('Read the docs')),
          DocUrlButton(
            url: 'https://pub.dev/packages/flutter_chartjs_plugin_zoom_port',
            label: Text('pub.dev'),
          ),
        ]),
      ],
    ),
  ],
  credit: Text('The plugins are Dart ports of Chart.js plugins (MIT).'),
);
