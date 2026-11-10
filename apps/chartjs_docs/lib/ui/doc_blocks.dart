// Original code, not ported from Chart.js: the blocks of a docs page.

import 'package:chartjs_docs/ui/code_block.dart';
import 'package:chartjs_docs/ui/docs_theme.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// What the blocks of a page read: the code regions and the section links.
class DocScope extends InheritedWidget {
  /// Creates the scope of a page.
  const DocScope({
    required this.snippets,
    required this.jumpTo,
    required super.child,
    super.key,
  });

  /// The code regions.
  final Snippets snippets;

  /// Scrolls to the section with an id.
  final ValueChanged<String> jumpTo;

  /// The scope above [context].
  static DocScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DocScope>()!;

  @override
  bool updateShouldNotify(DocScope oldWidget) => snippets != oldWidget.snippets;
}

final RegExp _inline = RegExp(
  r'`(?<code>[^`]+)`|\*\*(?<bold>[^*]+)\*\*|\[(?<text>[^\]]+)\]\(#(?<id>[^)]+)\)',
);

/// A text with the inline forms `` `code` ``, `**bold**` and `[text](#id)`.
class DocText extends StatefulWidget {
  /// Creates the text [text].
  const DocText(this.text, {this.style, super.key});

  /// The text with its inline forms.
  final String text;

  /// The style of the plain text.
  final TextStyle? style;

  @override
  State<DocText> createState() => _DocTextState();
}

class _DocTextState extends State<DocText> {
  final List<TapGestureRecognizer> _links = [];

  @override
  void dispose() {
    for (final link in _links) {
      link.dispose();
    }
    super.dispose();
  }

  List<InlineSpan> _spans() {
    for (final link in _links) {
      link.dispose();
    }
    _links.clear();
    final spans = <InlineSpan>[];
    final text = widget.text;
    var end = 0;
    for (final match in _inline.allMatches(text)) {
      if (match.start > end) {
        spans.add(TextSpan(text: text.substring(end, match.start)));
      }
      end = match.end;
      if (match.namedGroup('code') case final code?) {
        spans.add(
          TextSpan(
            text: code,
            style: const TextStyle(
              fontFamily: monoFont,
              fontSize: 12.5,
              backgroundColor: DocColors.primarySoft,
            ),
          ),
        );
      } else if (match.namedGroup('bold') case final bold?) {
        spans.add(
          TextSpan(
            text: bold,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else {
        final id = match.namedGroup('id')!;
        final link = TapGestureRecognizer()
          ..onTap = () => DocScope.of(context).jumpTo(id);
        _links.add(link);
        spans.add(
          TextSpan(
            text: match.namedGroup('text'),
            recognizer: link,
            mouseCursor: SystemMouseCursors.click,
            style: const TextStyle(
              color: DocColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
    }
    if (end < text.length) spans.add(TextSpan(text: text.substring(end)));
    return spans;
  }

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(children: _spans()),
    style: widget.style ?? const TextStyle(fontSize: 15, height: 1.6),
  );
}

/// A paragraph.
class DocParagraph extends StatelessWidget {
  /// Creates a paragraph of [text].
  const DocParagraph(this.text, {super.key});

  /// The text with its inline forms.
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DocText(text),
  );
}

/// A list with bullets.
class DocBullets extends StatelessWidget {
  /// Creates a list of [items].
  const DocBullets(this.items, {super.key});

  /// The items with their inline forms.
  final List<String> items;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 9, 10, 0),
                  child: CircleAvatar(
                    radius: 2.5,
                    backgroundColor: DocColors.primary,
                  ),
                ),
                Expanded(child: DocText(item)),
              ],
            ),
          ),
      ],
    ),
  );
}

/// A tip in a tinted box.
class DocTip extends StatelessWidget {
  /// Creates a tip with [text].
  const DocTip(this.text, {super.key});

  /// The text with its inline forms.
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DocColors.primarySoft,
      borderRadius: BorderRadius.circular(10),
    ),
    child: DocText(text, style: const TextStyle(fontSize: 14, height: 1.55)),
  );
}

Widget _panel({required Widget child}) => Container(
  margin: const EdgeInsets.only(bottom: 14),
  clipBehavior: Clip.antiAlias,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: DocColors.border),
  ),
  child: child,
);

/// A code panel of the region [region], with no chart.
class DocCode extends StatelessWidget {
  /// Creates the panel.
  const DocCode(this.region, {super.key});

  /// The name of the code region.
  final String region;

  @override
  Widget build(BuildContext context) => _panel(
    child: SizedBox(
      width: double.infinity,
      child: CodeBlock(code: DocScope.of(context).snippets[region]),
    ),
  );
}

/// One form of a live example.
class ExampleVariant {
  /// Creates a form with the name [label].
  const ExampleVariant({
    required this.label,
    required this.config,
    required this.region,
  });

  /// The name of the form.
  final String label;

  /// The chart of the form.
  final ChartConfig config;

  /// The name of the code region of the form.
  final String region;
}

/// A live chart with its code, and a choice of forms when it has several.
class LiveExample extends StatefulWidget {
  /// Creates the example.
  const LiveExample({
    required this.id,
    required this.description,
    required this.variants,
    this.hint,
    super.key,
  });

  /// The start of the keys of the example.
  final String id;

  /// The text of the chart for a screen reader.
  final String description;

  /// The forms of the example.
  final List<ExampleVariant> variants;

  /// A short instruction above the chart.
  final String? hint;

  @override
  State<LiveExample> createState() => _LiveExampleState();
}

class _LiveExampleState extends State<LiveExample> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final variant = widget.variants[_selected];
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.variants.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final (index, item) in widget.variants.indexed)
                    ChoiceChip(
                      key: ValueKey('${widget.id}.${item.label}'),
                      label: Text(item.label),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      selected: index == _selected,
                      onSelected: (_) => setState(() => _selected = index),
                    ),
                ],
              ),
            ),
          if (widget.hint case final hint?)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Text(
                hint,
                style: const TextStyle(color: DocColors.muted, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: RepaintBoundary(
              child: ChartView(
                key: ValueKey('${widget.id}.chart'),
                config: variant.config,
                semanticLabel: '${widget.description}: ${variant.label}',
              ),
            ),
          ),
          const Divider(height: 1, color: DocColors.border),
          CodeBlock(code: DocScope.of(context).snippets[variant.region]),
        ],
      ),
    );
  }
}

/// One row of a description table.
typedef DocRow = (String name, String description);

/// A table of option names and their descriptions.
class DocTable extends StatelessWidget {
  /// Creates the table of [rows].
  const DocTable(this.rows, {this.nameWidth = 210, super.key});

  /// The rows, with the inline forms in the cells.
  final List<DocRow> rows;

  /// The width of the column of the names on a wide screen.
  final double nameWidth;

  @override
  Widget build(BuildContext context) => _panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, (name, description)) in rows.indexed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: index == 0
                ? null
                : const BoxDecoration(
                    border: Border(top: BorderSide(color: DocColors.border)),
                  ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final nameCell = DocText('`$name`', style: _cell);
                final textCell = DocText(description, style: _cell);
                if (constraints.maxWidth < 560) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      nameCell,
                      const SizedBox(height: 4),
                      textCell,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: nameWidth, child: nameCell),
                    const SizedBox(width: 12),
                    Expanded(child: textCell),
                  ],
                );
              },
            ),
          ),
      ],
    ),
  );
}

const TextStyle _cell = TextStyle(fontSize: 13.5, height: 1.5);

/// One row of the table of dataset properties.
class DocProperty {
  /// Creates a row for the option [name].
  const DocProperty(
    this.name, {
    required this.type,
    required this.fallback,
    this.section,
    this.extra = false,
    this.scriptable = false,
    this.indexable = false,
  });

  /// The name of the Chart.js option.
  final String name;

  /// The Dart type of the value.
  final String type;

  /// The default value.
  final String fallback;

  /// The id of the section that describes the option.
  final String? section;

  /// Whether the option goes through `extra`, because it has no parameter.
  final bool extra;

  /// Whether a function can give the value.
  final bool scriptable;

  /// Whether a list can give one value for each data item.
  final bool indexable;
}

/// The table of the dataset properties of a chart type.
class DocPropertyTable extends StatelessWidget {
  /// Creates the table of [rows].
  const DocPropertyTable(this.rows, {super.key});

  /// The rows.
  final List<DocProperty> rows;

  static const _flex = [24, 9, 18, 9, 9, 17];
  static const _headers = [
    'Name',
    'Set with',
    'Dart type',
    'Scriptable',
    'Indexable',
    'Default',
  ];

  Widget _name(DocProperty row) => DocText(
    row.section == null ? '`${row.name}`' : '[${row.name}](#${row.section})',
    style: const TextStyle(fontFamily: monoFont, fontSize: 12.5, height: 1.5),
  );

  Widget _wide() => Table(
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    columnWidths: {
      for (final (index, flex) in _flex.indexed)
        index: FlexColumnWidth(flex.toDouble()),
    },
    border: const TableBorder(
      horizontalInside: BorderSide(color: DocColors.border),
    ),
    children: [
      TableRow(
        decoration: const BoxDecoration(color: DocColors.code),
        children: [
          for (final header in _headers)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(header.toUpperCase(), style: eyebrow),
            ),
        ],
      ),
      for (final row in rows)
        TableRow(
          children: [
            _pad(_name(row)),
            _pad(DocText(row.extra ? '`extra`' : 'Parameter', style: _small)),
            _pad(DocText('`${row.type}`', style: _small)),
            _pad(Text(row.scriptable ? 'Yes' : '–', style: _small)),
            _pad(Text(row.indexable ? 'Yes' : '–', style: _small)),
            _pad(DocText('`${row.fallback}`', style: _small)),
          ],
        ),
    ],
  );

  Widget _narrow() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, row) in rows.indexed)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: index == 0
              ? null
              : const BoxDecoration(
                  border: Border(top: BorderSide(color: DocColors.border)),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _name(row),
              const SizedBox(height: 4),
              DocText(
                '`${row.type}` · ${row.extra ? 'through `extra`' : 'parameter'}'
                ' · default `${row.fallback}`'
                '${row.scriptable ? ' · scriptable' : ''}'
                '${row.indexable ? ' · indexable' : ''}',
                style: _small,
              ),
            ],
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => _panel(
    child: LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < 720 ? _narrow() : _wide(),
    ),
  );
}

Widget _pad(Widget child) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
  child: child,
);

const TextStyle _small = TextStyle(fontSize: 12.5, height: 1.45);
