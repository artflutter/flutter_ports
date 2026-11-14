// Original code, not ported from Chart.js: the block of a migration replica.

import 'package:chartjs_docs/ui/code_block.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/docs_theme.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/link.dart';

/// One demo of another chart library and its replica with the port.
class const ReplicaDemo({
  /// The id of the section of the demo, unique on the site.
  required final String id,

  /// The name of the demo in the other library.
  required final String title,

  /// The address of the original demo.
  required final String original,

  /// The name of the code region of the replica.
  required final String region,

  /// What maps to what, with the inline forms of [DocText].
  required final List<String> notes,

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
/// one.
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
  required String credit,
  String? kit,
}) => DocPageContent(
  title: 'Migrate $chart charts from $library',
  navLabel: 'From $library',
  icon: icon,
  intro: [
    ...intro,
    DocParagraph(
      'Each section below rebuilds one $chart chart demo of $library $version '
      'with the port. The chart is live: hover and tap work as in the '
      'original. Open **Code** to see the code of the replica.',
    ),
    _OriginalLink(url: gallery, label: 'The $library demos'),
  ],
  sections: [
    DocSection(
      id: 'mapping',
      title: 'Names that map',
      body: [
        DocParagraph(
          'The left column is the $library name, the right column is the '
          'port.',
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
        title: 'Shared code',
        body: [
          const DocParagraph(
            'The replicas share these helpers: the colors, the axis look and '
            'the small plugins.',
          ),
          DocCode(kit),
        ],
      ),
  ],
  credit: credit,
);

/// A link that opens [url] in a new tab.
class const _OriginalLink({
  required final String url,
  required final String label,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Link(
      uri: Uri.parse(url),
      target: LinkTarget.blank,
      builder: (context, open) => TextButton.icon(
        onPressed: open,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: Text(label),
      ),
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
}) extends StatefulWidget {
  /// Creates the block of [demo].
  this;

  @override
  State<ReplicaBlock> createState() => _ReplicaBlockState();
}

class _ReplicaBlockState() extends State<ReplicaBlock> {
  bool _code = false;

  @override
  Widget build(BuildContext context) {
    final demo = widget.demo;
    final frame = widget.frame;
    Widget replica = Builder(builder: demo.replica);
    if (frame.dark) {
      replica = ChartTheme(data: const ChartThemeData.dark(), child: replica);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocBullets(demo.notes),
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DocColors.border),
          ),
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
              ColoredBox(
                color: Colors.white,
                child: Row(
                  children: [
                    TextButton.icon(
                      key: ValueKey('${demo.id}.code'),
                      onPressed: () => setState(() => _code = !_code),
                      icon: Icon(_code ? Icons.expand_less : Icons.code),
                      label: Text(_code ? 'Hide code' : 'Code'),
                    ),
                    const Spacer(),
                    _OriginalLink(url: demo.original, label: 'Original'),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
              if (_code) ...[
                const Divider(height: 1, color: DocColors.border),
                CodeBlock(code: DocScope.of(context).snippets[demo.region]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
