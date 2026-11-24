// Original code, not ported from Chart.js: the blocks of a docs page.

import 'dart:async';

import 'package:chartjs_docs/ui/code_block.dart';
import 'package:chartjs_docs/ui/dartpad.dart';
import 'package:chartjs_docs/ui/docs_theme.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// What the blocks of a page read: the source files of the code panels and
/// the section links.
class const DocScope({
  /// The source files of the code panels.
  required final CodeSources sources,

  /// Scrolls to the section with an id.
  required final ValueChanged<String> jumpTo,
  required super.child,
  super.key,
}) extends InheritedWidget {
  /// Creates the scope of a page.
  this;

  /// The scope above [context].
  static DocScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DocScope>()!;

  @override
  bool updateShouldNotify(DocScope oldWidget) => sources != oldWidget.sources;
}

final RegExp _inline = RegExp(
  r'`(?<code>[^`]+)`|\*\*(?<bold>[^*]+)\*\*|\[(?<text>[^\]]+)\]\(#(?<id>[^)]+)\)',
);

/// A text with the inline forms `` `code` ``, `**bold**` and `[text](#id)`.
class const DocText(
  /// The text with its inline forms.
  final String text, {

  /// The style of the plain text. The style of the nearest
  /// [DefaultTextStyle] fills the fields that it does not set.
  final TextStyle? style,
  super.key,
}) extends StatefulWidget {
  /// Creates the text [text].
  this;

  @override
  State<DocText> createState() => _DocTextState();
}

class _DocTextState() extends State<DocText> {
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
        spans.add(TextSpan(text: code, style: _code));
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
  Widget build(BuildContext context) =>
      Text.rich(TextSpan(children: _spans()), style: widget.style);
}

/// The style of the inline form `` `code` ``.
const TextStyle _code = TextStyle(
  fontFamily: monoFont,
  fontSize: 12.5,
  backgroundColor: DocColors.primarySoft,
);

/// The style of the body text: paragraphs and bullets.
const TextStyle _body = TextStyle(fontSize: 15, height: 1.6);

/// A paragraph. The paragraph gives [child] the style of the body text.
class const DocParagraph(
  /// The text of the paragraph, usually a [DocText].
  final Widget child, {
  super.key,
}) extends StatelessWidget {
  /// Creates a paragraph of [child].
  this;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DefaultTextStyle.merge(style: _body, child: child),
  );
}

/// A list with bullets. The list gives each item the style of the body
/// text.
class const DocBullets(
  /// The items, usually [DocText] widgets.
  final List<Widget> items, {
  super.key,
}) extends StatelessWidget {
  /// Creates a list of [items].
  this;

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
                Expanded(
                  child: DefaultTextStyle.merge(style: _body, child: item),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// A tip in a tinted box. The box gives [child] its text style.
class const DocTip(
  /// The text of the tip, usually a [DocText].
  final Widget child, {
  super.key,
}) extends StatelessWidget {
  /// Creates a tip with [child].
  this;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DocColors.primarySoft,
      borderRadius: BorderRadius.circular(10),
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(fontSize: 14, height: 1.55),
      child: child,
    ),
  );
}

/// A white panel with a rounded border around [child].
///
/// The border paints over the child: a child with an opaque color fills the
/// whole rounded box, and the clip at the outer edge does not cut the arc of
/// a border that the child covers.
class const DocPanel({
  /// The content of the panel.
  required final Widget child,
  super.key,
}) extends StatelessWidget {
  /// Creates a panel around [child].
  this;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: DocColors.border),
    ),
    child: child,
  );
}

/// The code of [region]. The first build loads its source file, and a text
/// shows until the file loads.
class const RegionCode(
  /// The code region.
  final CodeRegion region, {
  super.key,
}) extends StatefulWidget {
  /// Creates the code of [region].
  this;

  @override
  State<RegionCode> createState() => _RegionCodeState();
}

class _RegionCodeState() extends State<RegionCode> {
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(RegionCode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.region.source != widget.region.source) _load();
  }

  void _load() {
    final sources = DocScope.of(context).sources;
    final source = widget.region.source;
    _failed = false;
    if (sources.loaded(source) != null) return;
    // A file that loads at once needs no new build: this build reads it.
    var loading = true;
    unawaited(
      sources
          .load(source)
          .then<void>(
            (_) {
              if (mounted && !loading) setState(() {});
            },
            onError: (Object _) {
              if (mounted) setState(() => _failed = true);
            },
          ),
    );
    loading = false;
  }

  @override
  Widget build(BuildContext context) {
    final region = widget.region;
    final snippets = DocScope.of(context).sources.loaded(region.source);
    if (snippets != null) return CodeBlock(code: snippets[region.name]);
    return _CodeMessage(
      _failed ? 'The code did not load.' : 'Loading the code…',
    );
  }
}

/// A short muted text on the background of a code panel.
class const _CodeMessage(final String text) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: DocColors.code,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Text(
        text,
        style: const TextStyle(color: DocColors.muted, fontSize: 12),
      ),
    ),
  );
}

/// The lines of the skeleton of a code panel: the indent and the width of
/// each line, as a fraction of the panel width.
const List<(double, double)> _skeletonLines = [
  (0, 0.46),
  (1, 0.62),
  (1, 0.38),
  (0, 0.18),
];

/// The color of the light that sweeps across the skeleton lines.
const Color _sweepColor = Color(0xffc7d2fe);

/// The skeleton of a code panel while its file loads: lines of code with a
/// light that sweeps across them.
class const _CodeSkeleton() extends StatefulWidget {
  @override
  State<_CodeSkeleton> createState() => _CodeSkeletonState();
}

class _CodeSkeletonState()
    extends State<_CodeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Loading the code',
    child: ColoredBox(
      color: DocColors.code,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: AnimatedBuilder(
          animation: _sweep,
          builder: (context, child) => ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              colors: const [DocColors.border, _sweepColor, DocColors.border],
              stops: const [0.3, 0.5, 0.7],
              transform: _Sweep(_sweep.value),
            ).createShader(bounds),
            child: child,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (indent, width) in _skeletonLines)
                  Padding(
                    padding: EdgeInsets.only(left: indent * 18, bottom: 10),
                    child: Container(
                      width: constraints.maxWidth * width,
                      height: 9,
                      decoration: BoxDecoration(
                        color: DocColors.border,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Moves a gradient from the left of its box, out of view, to the right of
/// its box, out of view, as [progress] goes from 0 to 1.
class const _Sweep(final double progress) extends GradientTransform {
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (progress * 2 - 1), 0, 0);
}

/// The state of the code under a [CodeToggle].
enum _CodeState() {
  loading,
  loaded,
  failed,
}

/// A **Code** button, and the code of [region] under it after a tap.
///
/// The first tap loads the source file of [region]. A skeleton of the code
/// shows for at least [minLoading], and the panel then grows to the code. A
/// file that loaded before opens at once.
class const CodeToggle({
  /// The code region.
  required final CodeRegion region,

  /// The start of the key of the button, `<id>.code`.
  required final String id,

  /// The widget at the end of the row of the button.
  final Widget? trailing,
  super.key,
}) extends StatefulWidget {
  /// Creates the button of [region].
  this;

  /// The shortest time that the skeleton shows, so that it does not flash.
  static const Duration minLoading = Duration(milliseconds: 500);

  @override
  State<CodeToggle> createState() => _CodeToggleState();
}

class _CodeToggleState()
    extends State<CodeToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 240),
  )..addStatusListener(_closed);
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _expand,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  bool _open = false;
  _CodeState _state = _CodeState.loading;

  /// The number of the last load: a load with an older number has no
  /// effect.
  int _request = 0;

  @override
  void didUpdateWidget(CodeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_open && oldWidget.region.source != widget.region.source) _load();
  }

  @override
  void dispose() {
    _curve.dispose();
    _expand.dispose();
    super.dispose();
  }

  /// Removes the code from the tree at the end of the close.
  void _closed(AnimationStatus status) {
    if (status.isDismissed && mounted) setState(() {});
  }

  void _toggle() {
    _request++;
    if (_open) {
      setState(() => _open = false);
      _expand.reverse();
      return;
    }
    setState(() {
      _open = true;
      _load();
    });
    _expand.forward();
  }

  /// Loads the source file of the region, and shows the skeleton for at
  /// least [CodeToggle.minLoading]. The caller builds next.
  void _load() {
    final sources = context.getInheritedWidgetOfExactType<DocScope>()!.sources;
    final source = widget.region.source;
    if (sources.loaded(source) != null) {
      _state = _CodeState.loaded;
      return;
    }
    _state = _CodeState.loading;
    final request = ++_request;
    void finish(_CodeState state) {
      if (mounted && request == _request) setState(() => _state = state);
    }

    unawaited(
      Future.wait<Object?>([
        sources.load(source),
        Future<void>.delayed(CodeToggle.minLoading),
      ]).then<void>(
        (_) => finish(_CodeState.loaded),
        onError: (Object _) => finish(_CodeState.failed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = switch (_state) {
      _CodeState.loading => const _CodeSkeleton(),
      _CodeState.failed => const _CodeMessage('The code did not load.'),
      _CodeState.loaded => RegionCode(
        widget.region,
        key: ValueKey(widget.region),
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              TextButton.icon(
                key: ValueKey('${widget.id}.code'),
                onPressed: _toggle,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    _open ? Icons.expand_less : Icons.code,
                    key: ValueKey(_open),
                  ),
                ),
                label: Text(_open ? 'Hide code' : 'Code'),
              ),
              // The rest of the row, so that a trailing Wrap can wrap.
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: widget.trailing,
                ),
              ),
            ],
          ),
        ),
        if (_open || !_expand.isDismissed)
          SizeTransition(
            sizeFactor: _curve,
            alignment: Alignment.topCenter,
            child: FadeTransition(
              opacity: _curve,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: DocColors.border),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topCenter,
                        fit: StackFit.passthrough,
                        children: [...previous, ?current],
                      ),
                      child: code,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A code panel of the region [region], with no chart.
class const DocCode(
  /// The code region.
  final CodeRegion region, {
  super.key,
}) extends StatelessWidget {
  /// Creates the panel.
  this;

  @override
  Widget build(BuildContext context) => DocPanel(
    child: CodeToggle(id: region.name, region: region),
  );
}

/// One form of a live example.
class const ExampleVariant({
  /// The name of the form: the end of the key of its chip and of the text
  /// of the chart for a screen reader.
  required final String name,

  /// The label of the chip of the form. The chip gives it its text style.
  required final Widget label,

  /// The chart of the form.
  required final ChartConfig config,

  /// The code region of the form. Its source file has a `main` function that
  /// runs [config] alone: the **Try in DartPad** button opens that file.
  required final CodeRegion region,
}) {
  /// Creates a form with the name [name].
  this;
}

/// A button under a live chart: an action on the chart, as an action of a
/// `chart-editor` block of the Chart.js docs.
class const ExampleAction({
  /// The label of the button. The button gives it its text style.
  required final Widget label,

  /// What the button does with the chart.
  required final void Function(Chart chart) onPressed,
}) {
  /// Creates an action.
  this;
}

/// A live chart with its code, and a choice of forms when it has several.
class const LiveExample({
  /// The start of the keys of the example.
  required final String id,

  /// The text of the chart for a screen reader.
  required final String description,

  /// The forms of the example.
  required final List<ExampleVariant> variants,

  /// A short instruction above the chart. The example gives it a small
  /// muted text style.
  final Widget? hint,

  /// The buttons under the chart.
  final List<ExampleAction> actions = const [],
  super.key,
}) extends StatefulWidget {
  /// Creates the example.
  this;

  @override
  State<LiveExample> createState() => _LiveExampleState();
}

class _LiveExampleState() extends State<LiveExample> {
  int _selected = 0;

  /// The chart of the example, for the actions.
  Chart? _chart;

  @override
  Widget build(BuildContext context) {
    final variant = widget.variants[_selected];
    return DocPanel(
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
                      key: ValueKey('${widget.id}.${item.name}'),
                      label: item.label,
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
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: DocColors.muted, fontSize: 12),
                child: hint,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: RepaintBoundary(
              child: ChartView(
                key: ValueKey('${widget.id}.chart'),
                config: variant.config,
                semanticLabel: '${widget.description}: ${variant.name}',
                onChartCreated: (chart) => _chart = chart,
              ),
            ),
          ),
          if (widget.actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final (index, action) in widget.actions.indexed)
                    OutlinedButton(
                      key: ValueKey('${widget.id}.action.$index'),
                      onPressed: () {
                        if (_chart case final chart?) action.onPressed(chart);
                      },
                      child: action.label,
                    ),
                ],
              ),
            ),
          const Divider(height: 1, color: DocColors.border),
          CodeToggle(
            id: widget.id,
            region: variant.region,
            trailing: DartPadLink(
              variant.region.source,
              key: ValueKey('${widget.id}.dartpad'),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of a description table: the name, usually a [Text], and the
/// description, usually a [DocText].
typedef DocRow = (Widget name, Widget description);

/// A table of option names and their descriptions. The table gives a name
/// the style of the inline form `` `code` ``.
class const DocTable(
  /// The rows.
  final List<DocRow> rows, {

  /// The width of the column of the names on a wide screen.
  final double nameWidth = 210,
  super.key,
}) extends StatelessWidget {
  /// Creates the table of [rows].
  this;

  @override
  Widget build(BuildContext context) => DocPanel(
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
                final nameCell = DefaultTextStyle.merge(
                  style: _nameCell,
                  child: name,
                );
                final textCell = DefaultTextStyle.merge(
                  style: _cell,
                  child: description,
                );
                if (constraints.maxWidth < 560) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [nameCell, const SizedBox(height: 4), textCell],
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

/// The style of a name of a description table: [_code] in a cell.
const TextStyle _nameCell = TextStyle(
  fontFamily: monoFont,
  fontSize: 12.5,
  height: 1.5,
  backgroundColor: DocColors.primarySoft,
);

/// One row of the table of dataset properties.
class const DocProperty(
  /// The name of the Chart.js option.
  final String name, {

  /// The Dart type of the value.
  required final String type,

  /// The default value.
  required final String fallback,

  /// The id of the section that describes the option.
  final String? section,

  /// Whether a function can give the value.
  final bool scriptable = false,

  /// Whether a list can give one value for each data item.
  final bool indexable = false,
}) {
  /// Creates a row for the option [name].
  this;
}

/// The table of the dataset properties of a chart type.
class const DocPropertyTable(
  /// The rows.
  final List<DocProperty> rows, {
  super.key,
}) extends StatelessWidget {
  /// Creates the table of [rows].
  this;

  static const _flex = [24, 18, 9, 9, 17];
  static const _headers = [
    'Name',
    'Dart type',
    'Scriptable',
    'Indexable',
    'Default',
  ];

  @override
  Widget build(BuildContext context) => DocPanel(
    child: LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 720
          ? _NarrowPropertyTable(rows)
          : _WidePropertyTable(rows),
    ),
  );
}

/// The name of the option of [row], a link when a section describes it.
class const _PropertyName(final DocProperty row) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DocText(
    row.section == null ? '`${row.name}`' : '[${row.name}](#${row.section})',
    style: const TextStyle(fontFamily: monoFont, fontSize: 12.5, height: 1.5),
  );
}

/// The property table on a wide screen: one column for each field.
class const _WidePropertyTable(final List<DocProperty> rows)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Table(
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    columnWidths: {
      for (final (index, flex) in DocPropertyTable._flex.indexed)
        index: FlexColumnWidth(flex.toDouble()),
    },
    border: const TableBorder(
      horizontalInside: BorderSide(color: DocColors.border),
    ),
    children: [
      TableRow(
        decoration: const BoxDecoration(color: DocColors.code),
        children: [
          for (final header in DocPropertyTable._headers)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(header.toUpperCase(), style: eyebrow),
            ),
        ],
      ),
      for (final row in rows)
        TableRow(
          children: [
            _Pad(_PropertyName(row)),
            _Pad(DocText('`${row.type}`', style: _small)),
            _Pad(Text(row.scriptable ? 'Yes' : '–', style: _small)),
            _Pad(Text(row.indexable ? 'Yes' : '–', style: _small)),
            _Pad(DocText('`${row.fallback}`', style: _small)),
          ],
        ),
    ],
  );
}

/// The property table on a narrow screen: one block for each row.
class const _NarrowPropertyTable(final List<DocProperty> rows)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
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
              _PropertyName(row),
              const SizedBox(height: 4),
              DocText(
                '`${row.type}` · default `${row.fallback}`'
                '${row.scriptable ? ' · scriptable' : ''}'
                '${row.indexable ? ' · indexable' : ''}',
                style: _small,
              ),
            ],
          ),
        ),
    ],
  );
}

/// The space around a cell of the wide property table.
class const _Pad(final Widget child) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    child: child,
  );
}

const TextStyle _small = TextStyle(fontSize: 12.5, height: 1.45);
