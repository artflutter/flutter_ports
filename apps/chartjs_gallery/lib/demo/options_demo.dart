import 'dart:ui' as ui;

import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
// The demo calls pure resolvers without constructing a Chart first.
// Not public: _createResolver and _attachContext, upstream `_` helpers.
import 'package:material_ui/material_ui.dart';

/// One dataset scope of the three-state table.
typedef _Scope = ({String label, Map<String, Object?> scope});

/// The dataset scopes: the key absent, JS `null`, the `undefined` sentinel
/// and a set value.
final List<_Scope> _scopes = [
  (label: '{}  (key absent)', scope: <String, Object?>{}),
  (label: '{borderColor: null}', scope: <String, Object?>{'borderColor': null}),
  (
    label: '{borderColor: undefined}',
    scope: <String, Object?>{'borderColor': undefined},
  ),
  (
    label: '{borderColor: ChartPaint.solid(Color(0xFF36A2EB))}',
    scope: <String, Object?>{
      'borderColor': const ChartPaint.solid(ui.Color(0xFF36A2EB)),
    },
  ),
];

/// The fonts of the `toFont` card: `ChartTextStyle`s (Chart.js ADR 0116).
final List<({String label, TextStyle options})> _fonts = [
  (label: 'ChartTextStyle()  → defaults.font', options: const ChartTextStyle()),
  (
    label: 'ChartTextStyle(fontSize: 18)',
    options: const ChartTextStyle(fontSize: 18),
  ),
  (
    label:
        'ChartTextStyle(fontSize: 16, fontStyle: italic, fontWeight: w600, '
        "fontFamily: 'Georgia', height: 1.5)",
    options: const ChartTextStyle(
      fontSize: 16,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w600,
      fontFamily: 'Georgia',
      fontFamilyFallback: ['serif'],
      height: 1.5,
    ),
  ),
];

/// The scriptable default that gives `hoverBackgroundColor`.
const String _hoverSource =
    'defaults: (ctx, options) => getHoverColor(options.backgroundColor)';

/// The values of the `toPadding` card.
final List<({String label, Object? value})> _paddings = [
  (label: '10', value: 10.0),
  (label: '{x: 5, y: 10}', value: <String, Object?>{'x': 5.0, 'y': 10.0}),
  (
    label: '{top: 1, left: 2}',
    value: <String, Object?>{'top': 1.0, 'left': 2.0},
  ),
];

/// Option resolution through the ported `helpers.config` resolvers over the
/// ported `core.defaults`, and the option helpers `toFont` and `toPadding`
/// of `helpers.options`.
///
/// The first card shows the three states of an option key (Chart.js ADR
/// 0043): an absent key and the `undefined` sentinel go on to the next
/// scope, and JS `null` is a value.
class const OptionsDemo({super.key}) extends StatelessWidget {
  /// Creates the options tab.
  this;

  @override
  Widget build(BuildContext context) {
    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Three states of an option key',
          source:
              "createResolver([dataset, defaults])['borderColor'] · "
              "defaults['borderColor'] = "
              "${showJs(defaults['borderColor'])}",
          child: _table(
            context,
            const ['dataset scope', 'resolved', 'from'],
            [for (final s in _scopes) _resolveRow(s)],
          ),
        ),
        DemoCard(
          title: 'Nested and scriptable options',
          source:
              'sub-resolver of font · attachContext(resolver, {}) for the '
              'scriptable default hoverBackgroundColor',
          child: _nested(context),
        ),
        DemoCard(
          title: 'toFont',
          source:
              'helpers.options toFont(font): the font merged over '
              'defaults.font',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final f in _fonts) ...[
                _FontRow(label: f.label, font: toFont(f.options)),
                if (f != _fonts.last) const Divider(height: 20),
              ],
            ],
          ),
        ),
        DemoCard(
          title: 'toPadding',
          source: 'helpers.options toPadding(value)',
          child: _table(
            context,
            const [
              'value',
              'top',
              'right',
              'bottom',
              'left',
              'width',
              'height',
            ],
            [for (final p in _paddings) _paddingRow(p.label, p.value)],
          ),
        ),
      ],
    );
  }

  List<String> _resolveRow(_Scope s) {
    final resolver = createResolver([s.scope, defaults]);
    final value = resolver['borderColor'];
    final own =
        s.scope.containsKey('borderColor') &&
        !identical(s.scope['borderColor'], undefined);
    return [s.label, showJs(value), if (own) 'dataset' else 'defaults'];
  }

  Widget _nested(BuildContext context) {
    final dataset = <String, Object?>{
      'backgroundColor': const ChartPaint.solid(ui.Color(0xFF36A2EB)),
      'font': const ChartTextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    };
    final resolver = createResolver([dataset, defaults]);
    final font = resolver['font']! as ChartTextStyle;
    final context0 = attachContext(resolver, <String, Object?>{});
    final hover = context0['hoverBackgroundColor'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Mono(
          'dataset = {backgroundColor: Color(0xFF36A2EB), '
          'font: ChartTextStyle(fontSize: 20, fontWeight: bold)}',
        ),
        const SizedBox(height: 8),
        _table(
          context,
          const ['read', 'resolved', 'from'],
          [
            ['font.fontSize', showJs(font.fontSize), 'dataset'],
            ['font.fontWeight', '${font.fontWeight?.value}', 'dataset'],
            ['font.fontFamily', '${font.fontFamily}', 'defaults.font'],
            ['font.lineHeight', showJs(font.lineHeight), 'fontSize × height'],
            ['hoverBackgroundColor', showJs(hover), _hoverSource],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const ColorSwatchBox(color: ui.Color(0xFF36A2EB), size: 28),
            const Text('backgroundColor'),
            const SizedBox(width: 10),
            ColorSwatchBox(color: (hover as SolidChartPaint?)?.color, size: 28),
            const Text('hover'),
          ],
        ),
      ],
    );
  }

  List<String> _paddingRow(String label, Object? value) {
    final p = toPadding(value);
    return [
      label,
      for (final v in [p.top, p.right, p.bottom, p.left, p.width, p.height])
        jsNumberText(v),
    ];
  }

  Widget _table(
    BuildContext context,
    List<String> header,
    List<List<String>> rows,
  ) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Consolas', 'Roboto Mono'],
    );
    Widget cell(String text, {bool head = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(text, style: head ? theme.textTheme.labelLarge : mono),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder(
          horizontalInside: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
            ),
            children: [for (final h in header) cell(h, head: true)],
          ),
          for (final row in rows)
            TableRow(children: [for (final c in row) cell(c)]),
        ],
      ),
    );
  }
}

/// One `toFont` result: the merged font, its line height and a sample text.
class const _FontRow({
  required final String label,
  required final ChartTextStyle font,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Mono('toFont($label)', style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Mono(
          '${font.fontFamily} · size ${showJs(font.fontSize)} · height '
          '${showJs(font.height)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Mono(
          'lineHeight ${showJs(font.lineHeight)}px · weight '
          '${font.fontWeight?.value} · style ${font.fontStyle?.name}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text('The quick brown fox · 1,234.56', style: font),
      ],
    );
  }
}
