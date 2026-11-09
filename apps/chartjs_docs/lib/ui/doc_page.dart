// Original code, not ported from Chart.js: the frame of a docs page.

import 'dart:math' as math;

import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/docs_theme.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show chartJsVersion;
import 'package:material_ui/material_ui.dart';

/// A section of a page. A section of level 2 is one card, and its
/// subsections are in that card.
class DocSection {
  /// Creates a section.
  const DocSection({
    required this.id,
    required this.title,
    required this.body,
    this.subsections = const [],
  });

  /// The id of the links to the section.
  final String id;

  /// The heading.
  final String title;

  /// The blocks of the section.
  final List<Widget> body;

  /// The subsections.
  final List<DocSection> subsections;
}

/// The content of a page.
class DocPageContent {
  /// Creates a page.
  const DocPageContent({
    required this.title,
    required this.navLabel,
    required this.icon,
    required this.intro,
    required this.sections,
  });

  /// The heading of the page.
  final String title;

  /// The name of the page in the navigation.
  final String navLabel;

  /// The icon of the page in the navigation.
  final IconData icon;

  /// The blocks of the first card, below the heading.
  final List<Widget> intro;

  /// The sections after the first card.
  final List<DocSection> sections;
}

/// The widest layout of the text and the charts.
const double _contentWidth = 900;

/// The width of the sidebar, its gap and the content.
const double _frameWidth = 292 + 20 + _contentWidth;

/// The id of the first card.
const String _top = 'top';

/// The frame of a docs page: the header, the navigation and the content.
class DocPage extends StatefulWidget {
  /// Creates the frame of [content].
  const DocPage({required this.content, required this.snippets, super.key});

  /// The content.
  final DocPageContent content;

  /// The code regions of the content.
  final Snippets snippets;

  @override
  State<DocPage> createState() => _DocPageState();
}

class _DocPageState extends State<DocPage> {
  final ScrollController _scroll = ScrollController();
  final Map<String, GlobalKey> _keys = {};
  final ValueNotifier<String> _active = ValueNotifier(_top);

  /// The ids of the sections in page order.
  late final List<(String id, String title, int level)> _outline = [
    for (final section in widget.content.sections) ...[
      (section.id, section.title, 2),
      for (final sub in section.subsections) (sub.id, sub.title, 3),
    ],
  ];

  GlobalKey _keyOf(String id) => _keys[id] ??= GlobalKey(debugLabel: id);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_syncActive);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _active.dispose();
    super.dispose();
  }

  /// Marks the last section with a heading above the middle of the top band.
  void _syncActive() {
    final viewport = _scroll.position.context.storageContext.findRenderObject();
    if (viewport is! RenderBox) return;
    final limit = viewport.localToGlobal(Offset.zero).dy + 96;
    var active = _top;
    for (final (id, _, _) in _outline) {
      final box = _keys[id]?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      if (box.localToGlobal(Offset.zero).dy > limit) break;
      active = id;
    }
    if (_scroll.position.extentAfter < 1 && _outline.isNotEmpty) {
      active = _outline.last.$1;
    }
    _active.value = active;
  }

  void _jumpTo(String id) {
    final target = _keys[id]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.02,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    ).ignore();
  }

  Widget _heading(DocSection section, {required bool top}) => Padding(
    key: _keyOf(section.id),
    padding: const EdgeInsets.only(bottom: 10),
    child: Builder(
      builder: (context) {
        final text = Theme.of(context).textTheme;
        return Text(
          section.title,
          style: (top ? text.headlineSmall : text.titleMedium)?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        );
      },
    ),
  );

  Widget _card(List<Widget> children, double pad) => Card(
    child: Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );

  Widget _content(double pad, {Widget? outline}) {
    final content = widget.content;
    return SelectionArea(
      child: SingleChildScrollView(
        controller: _scroll,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (outline != null) ...[outline, const SizedBox(height: 12)],
                _card([
                  Text(
                    content.title,
                    key: const ValueKey('page.title'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...content.intro,
                ], pad),
                for (final section in content.sections) ...[
                  const SizedBox(height: 16),
                  _card([
                    _heading(section, top: true),
                    ...section.body,
                    for (final sub in section.subsections) ...[
                      const SizedBox(height: 10),
                      _heading(sub, top: false),
                      ...sub.body,
                    ],
                  ], pad),
                ],
                const SizedBox(height: 14),
                const Text(
                  'The text follows the Chart.js documentation (MIT).',
                  style: TextStyle(color: DocColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _link(String id, String title, int level, {VoidCallback? after}) =>
      ValueListenableBuilder<String>(
        valueListenable: _active,
        builder: (context, active, _) {
          final selected = active == id;
          return InkWell(
            key: ValueKey('nav.$id'),
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              after?.call();
              _jumpTo(id);
            },
            child: Container(
              padding: EdgeInsets.fromLTRB(level == 2 ? 10 : 24, 6, 10, 6),
              decoration: BoxDecoration(
                color: selected ? DocColors.primarySoft : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: level == 2 ? 13.5 : 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? DocColors.primary : DocColors.ink,
                ),
              ),
            ),
          );
        },
      );

  Widget _pageTile() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: DocColors.primary,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(widget.content.icon, size: 18, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          widget.content.navLabel,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget get _sidebar => Card(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('CHART TYPES', style: eyebrow),
          const SizedBox(height: 10),
          _pageTile(),
          const SizedBox(height: 10),
          for (final (id, title, level) in _outline) _link(id, title, level),
        ],
      ),
    ),
  );

  Widget get _phoneOutline => Card(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      key: const ValueKey('nav.phone'),
      shape: const Border(),
      collapsedShape: const Border(),
      leading: Icon(widget.content.icon, color: DocColors.primary),
      title: Text(widget.content.navLabel),
      subtitle: const Text('On this page'),
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (id, title, level) in _outline) _link(id, title, level),
      ],
    ),
  );

  Widget _header({required bool narrow}) => Row(
    children: [
      Container(
        width: narrow ? 36 : 46,
        height: narrow ? 36 : 46,
        decoration: BoxDecoration(
          color: DocColors.primary,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.menu_book_outlined, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chart.js for Flutter',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Text(
              'flutter_chartjs_port · based on Chart.js $chartJsVersion',
              style: TextStyle(color: DocColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: DocScope(
        snippets: widget.snippets,
        jumpTo: _jumpTo,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final side = wide
                ? math.max<double>(24, (constraints.maxWidth - _frameWidth) / 2)
                : null;
            final narrow = constraints.maxWidth < 600;
            final pad = narrow ? 14.0 : 22.0;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                side ?? (narrow ? 12 : 24),
                narrow ? 12 : 20,
                side ?? (narrow ? 12 : 24),
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(narrow: narrow),
                  SizedBox(height: narrow ? 10 : 18),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 292, child: _sidebar),
                              const SizedBox(width: 20),
                              Expanded(child: _content(pad)),
                            ],
                          )
                        : _content(pad, outline: _phoneOutline),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
