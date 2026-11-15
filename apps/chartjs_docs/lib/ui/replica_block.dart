// Original code, not ported from Chart.js: the block of a migration replica.

import 'package:chartjs_docs/ui/dartpad.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/link.dart';

/// One demo of another chart library and its replica with the port.
class const ReplicaDemo({
  /// The id of the section of the demo, unique on the site.
  required final String id,

  /// The name of the demo in the other library, the heading of its section.
  required final Widget title,

  /// The address of the original demo.
  required final String original,

  /// The code region of the replica.
  required final CodeRegion region,

  /// What maps to what, one widget for each bullet, usually a [DocText].
  required final List<Widget> notes,

  /// Builds the live replica.
  required final WidgetBuilder replica,
}) {
  /// Creates a demo.
  this;
}

/// The look of the frame of the replicas of a library.
class const ReplicaFrame({
  /// The color behind the replica: the page color of the original demo.
  required final Color background,

  /// Whether the replica shows under the dark chart theme.
  final bool dark = false,

  /// The space around the replica.
  final EdgeInsets padding = const EdgeInsets.all(12),
}) {
  /// Creates the look of a frame.
  this;
}

/// The page of a migration of the [chart] charts of another library: an
/// introduction, a table of the names that map, one section for each demo,
/// and the code region [kit] of the shared helpers when the replicas have
/// one. [navName] is the short name of the library in the navigation, by
/// default [library].
DocPageContent migrationPage({
  required String chart,
  required String library,
  required String version,
  required String gallery,
  required IconData icon,
  required List<Widget> intro,
  required List<DocRow> mapping,
  required List<ReplicaDemo> demos,
  required ReplicaFrame frame,
  required Widget credit,
  CodeRegion? kit,
  String? navName,
}) => DocPageContent(
  tabTitle: 'Migrate $chart charts from $library',
  title: Text('Migrate $chart charts from $library'),
  navLabel: Text('From ${navName ?? library}'),
  icon: icon,
  intro: [
    ...intro,
    DocParagraph(
      DocText(
        'Each section below rebuilds one $chart chart demo of $library '
        '$version with the port. The chart is live: hover and tap work as in '
        'the original. Open **Code** to see the code of the replica.',
      ),
    ),
    Align(
      alignment: Alignment.centerLeft,
      child: _OriginalLink(url: gallery, label: Text('The $library demos')),
    ),
  ],
  sections: [
    DocSection(
      id: 'mapping',
      title: const Text('Names that map'),
      body: [
        DocParagraph(
          DocText(
            'The left column is the $library name, the right column is the '
            'port.',
          ),
        ),
        DocTable(mapping, nameWidth: 280),
      ],
    ),
    for (final demo in demos)
      DocSection(
        id: demo.id,
        title: demo.title,
        body: [ReplicaBlock(demo: demo, frame: frame)],
      ),
    if (kit != null)
      DocSection(
        id: 'kit',
        title: const Text('Shared code'),
        body: [
          const DocParagraph(
            DocText(
              'The replicas share these helpers: the colors, the axis look '
              'and the small plugins.',
            ),
          ),
          DocCode(kit),
        ],
      ),
  ],
  credit: credit,
);

/// A link that opens [url] in a new tab. The button gives [label] its text
/// style.
class const _OriginalLink({
  required final String url,
  required final Widget label,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Link(
    uri: Uri.parse(url),
    target: LinkTarget.blank,
    builder: (context, open) => TextButton.icon(
      onPressed: open,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
      ),
      icon: const Icon(Icons.open_in_new, size: 16),
      label: label,
    ),
  );
}

/// A demo with its notes, its live replica and its code on demand.
class const ReplicaBlock({
  /// The demo.
  required final ReplicaDemo demo,

  /// The look of the frame of the replica.
  required final ReplicaFrame frame,
  super.key,
}) extends StatelessWidget {
  /// Creates the block of [demo].
  this;

  @override
  Widget build(BuildContext context) {
    Widget replica = Builder(builder: demo.replica);
    if (frame.dark) {
      replica = ChartTheme(data: const ChartThemeData.dark(), child: replica);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocBullets(demo.notes),
        DocPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: frame.background,
                child: Padding(
                  padding: frame.padding,
                  child: RepaintBoundary(
                    key: ValueKey('${demo.id}.replica'),
                    child: replica,
                  ),
                ),
              ),
              CodeToggle(
                id: demo.id,
                region: demo.region,
                trailing: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DartPadLink(
                      demo.region.source,
                      key: ValueKey('${demo.id}.dartpad'),
                    ),
                    _OriginalLink(
                      url: demo.original,
                      label: const Text('Original'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
