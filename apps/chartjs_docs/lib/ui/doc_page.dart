// Original code, not ported from Chart.js: the frame of a docs page.

import 'dart:math' as math;

import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/docs_theme.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show chartJsVersion;
import 'package:material_ui/material_ui.dart';

/// A section of a page. A section of level 2 is one card, and its
/// subsections are in that card.
class const DocSection({
  /// The id of the links to the section.
  required final String id,

  /// The heading, usually a [Text]. The page gives it the heading style, and
  /// the outline shows it as a link.
  required final Widget title,

  /// The blocks of the section.
  required final List<Widget> body,

  /// The subsections.
  final List<DocSection> subsections = const [],
}) {
  /// Creates a section.
  this;
}

/// The content of a page.
class const DocPageContent({
  /// The title of the browser tab: the text of [title].
  required final String tabTitle,

  /// The heading of the page, usually a [Text]. The page gives it the style
  /// of the page heading.
  required final Widget title,

  /// The name of the page in the navigation, usually a [Text].
  required final Widget navLabel,

  /// The icon of the page in the navigation.
  required final IconData icon,

  /// The blocks of the first card, below the heading.
  required final List<Widget> intro,

  /// The sections after the first card.
  required final List<DocSection> sections,

  /// The line below the last card: the source of the text. The page gives it
  /// a small muted text style.
  final Widget credit = const Text(
    'The text follows the Chart.js documentation (MIT).',
  ),
}) {
  /// Creates a page.
  this;
}

/// A page of the site in the navigation: its route, its group and how to
/// build it.
class const DocPageLink({
  /// The route name of the page, for example `/migrate/fl_chart`.
  required final String route,

  /// The group of the page in the navigation. The pages with equal groups
  /// share one heading, the group in capitals.
  required final String group,

  /// The name of the page in the navigation, usually a [Text].
  required final Widget navLabel,

  /// The icon of the page in the navigation.
  required final IconData icon,

  /// Builds the content of the page.
  required final DocPageContent Function() build,
}) {
  /// Creates the link of a page.
  this;
}

/// The widest layout of the text and the charts.
const double _contentWidth = 900;

/// The width of the sidebar, its gap and the content.
const double _frameWidth = 292 + 20 + _contentWidth;

/// The id of the first card.
const String _top = 'top';

/// The frame of a docs page: the header, the navigation and the content.
class const DocPage({
  /// The content.
  required final DocPageContent content,

  /// The source files of the code panels.
  required final CodeSources sources,

  /// The pages of the site, in navigation order.
  final List<DocPageLink> pages = const [],

  /// The route of this page.
  final String route = '/',
  super.key,
}) extends StatefulWidget {
  /// Creates the frame of [content], the page with the route [route] of
  /// [pages].
  this;

  @override
  State<DocPage> createState() => _DocPageState();
}

class _DocPageState() extends State<DocPage> {
  final ScrollController _scroll = ScrollController();
  final Map<String, GlobalKey> _keys = {};
  final ValueNotifier<String> _active = ValueNotifier(_top);

  /// The ids of the sections in page order.
  late final _Outline _outline = [
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

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: DocScope(
        sources: widget.sources,
        jumpTo: _jumpTo,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final side = wide
                ? math.max<double>(24, (constraints.maxWidth - _frameWidth) / 2)
                : null;
            final narrow = constraints.maxWidth < 600;
            final pad = narrow ? 14.0 : 22.0;
            final content = _Content(
              content: widget.content,
              scroll: _scroll,
              keyOf: _keyOf,
              pad: pad,
              outline: wide
                  ? null
                  : _PhoneOutline(
                      content: widget.content,
                      pages: widget.pages,
                      route: widget.route,
                      outline: _outline,
                      active: _active,
                    ),
            );
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
                  _Header(narrow: narrow),
                  SizedBox(height: narrow ? 10 : 18),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 292,
                                child: _Sidebar(
                                  content: widget.content,
                                  pages: widget.pages,
                                  route: widget.route,
                                  outline: _outline,
                                  active: _active,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(child: content),
                            ],
                          )
                        : content,
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

/// The sections of a page in page order: the id, the heading and the level.
typedef _Outline = List<(String id, Widget title, int level)>;

/// The heading of [section], larger at the top of a card.
class const _Heading({
  required final DocSection section,
  required final bool top,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DefaultTextStyle.merge(
        style: (top ? text.headlineSmall : text.titleMedium)?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        child: section.title,
      ),
    );
  }
}

/// A card with [children] in a column, [pad] from its edges.
class const _Card({
  required final double pad,
  required final List<Widget> children,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

/// The cards of [content] in a scroll view, with [outline] above them on a
/// narrow screen. [keyOf] gives the key of the heading of a section.
class const _Content({
  required final DocPageContent content,
  required final ScrollController scroll,
  required final GlobalKey Function(String id) keyOf,
  required final double pad,
  final Widget? outline,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SelectionArea(
    child: SingleChildScrollView(
      controller: scroll,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (outline case final outline?) ...[
                outline,
                const SizedBox(height: 12),
              ],
              _Card(
                pad: pad,
                children: [
                  DefaultTextStyle.merge(
                    key: const ValueKey('page.title'),
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    child: content.title,
                  ),
                  const SizedBox(height: 12),
                  ...content.intro,
                ],
              ),
              for (final section in content.sections) ...[
                const SizedBox(height: 16),
                _Card(
                  pad: pad,
                  children: [
                    _Heading(
                      key: keyOf(section.id),
                      section: section,
                      top: true,
                    ),
                    ...section.body,
                    for (final sub in section.subsections) ...[
                      const SizedBox(height: 10),
                      _Heading(key: keyOf(sub.id), section: sub, top: false),
                      ...sub.body,
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 14),
              DefaultTextStyle.merge(
                style: const TextStyle(color: DocColors.muted, fontSize: 11),
                child: content.credit,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The link to the section [id] in an outline, marked while [active] names
/// the section.
class const _OutlineLink({
  required final String id,
  required final Widget title,
  required final int level,
  required final ValueListenable<String> active,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: active,
    builder: (context, current, _) {
      final selected = current == id;
      return InkWell(
        key: ValueKey('nav.$id'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => DocScope.of(context).jumpTo(id),
        child: Container(
          padding: EdgeInsets.fromLTRB(level == 2 ? 10 : 24, 6, 10, 6),
          decoration: BoxDecoration(
            color: selected ? DocColors.primarySoft : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: level == 2 ? 13.5 : 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? DocColors.primary : DocColors.ink,
            ),
            child: title,
          ),
        ),
      );
    },
  );
}

/// The tile of this page in the navigation.
class const _PageTile({
  required final IconData icon,
  required final Widget label,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: DocColors.primary,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 8),
        // A long label wraps: the row never overflows the sidebar.
        Flexible(
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            child: label,
          ),
        ),
      ],
    ),
  );
}

/// A link to the other page [page].
class const _PageLink(final DocPageLink page) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('page.${page.route}'),
    borderRadius: BorderRadius.circular(10),
    onTap: () => Navigator.of(context).pushReplacementNamed(page.route),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(page.icon, size: 18, color: DocColors.muted),
          const SizedBox(width: 8),
          Flexible(
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontWeight: FontWeight.w600),
              child: page.navLabel,
            ),
          ),
        ],
      ),
    ),
  );
}

/// The navigation on a wide screen: each group of [pages] with its pages,
/// and the [outline] of the page [route] under its tile.
class const _Sidebar({
  required final DocPageContent content,
  required final List<DocPageLink> pages,
  required final String route,
  required final _Outline outline,
  required final ValueListenable<String> active,
}) extends StatelessWidget {
  /// The groups of [pages], in navigation order.
  List<(String group, List<DocPageLink> pages)> get _groups {
    final groups = <(String, List<DocPageLink>)>[];
    for (final page in pages) {
      if (groups.isEmpty || groups.last.$1 != page.group) {
        groups.add((page.group, []));
      }
      groups.last.$2.add(page);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    final tile = _PageTile(icon: content.icon, label: content.navLabel);
    final links = [
      for (final (id, title, level) in outline)
        _OutlineLink(id: id, title: title, level: level, active: active),
    ];
    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: groups.isEmpty
              ? [
                  const Text('CHART TYPES', style: eyebrow),
                  const SizedBox(height: 10),
                  tile,
                  const SizedBox(height: 10),
                  ...links,
                ]
              : [
                  for (final (index, (group, pages)) in groups.indexed) ...[
                    if (index > 0) const SizedBox(height: 16),
                    Text(group.toUpperCase(), style: eyebrow),
                    const SizedBox(height: 10),
                    for (final page in pages)
                      if (page.route == route) ...[
                        tile,
                        const SizedBox(height: 10),
                        ...links,
                      ] else
                        _PageLink(page),
                  ],
                ],
        ),
      ),
    );
  }
}

/// The navigation on a narrow screen: the [outline] of this page and the
/// links to the other [pages], in a tile that opens.
class const _PhoneOutline({
  required final DocPageContent content,
  required final List<DocPageLink> pages,
  required final String route,
  required final _Outline outline,
  required final ValueListenable<String> active,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      key: const ValueKey('nav.phone'),
      shape: const Border(),
      collapsedShape: const Border(),
      leading: Icon(content.icon, color: DocColors.primary),
      title: content.navLabel,
      subtitle: const Text('On this page'),
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (id, title, level) in outline)
          _OutlineLink(id: id, title: title, level: level, active: active),
        for (final page in pages)
          if (page.route != route) _PageLink(page),
      ],
    ),
  );
}

/// The header of the site: its icon, its name and the version of Chart.js.
class const _Header({required final bool narrow}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
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
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
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
}
