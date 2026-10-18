// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/core/core.defaults.dart';
import 'package:flutter_chartjs/src/helpers/helpers.canvas.dart'
    show toFontString;
import 'package:flutter_chartjs/src/helpers/helpers.config.dart';
import 'package:flutter_chartjs/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';

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
    label: "{borderColor: '#36A2EB'}",
    scope: <String, Object?>{'borderColor': '#36A2EB'},
  ),
];

/// The font options of the `toFont` card.
final List<({String label, Object? options})> _fonts = [
  (label: '{}  → defaults.font', options: <String, Object?>{}),
  (
    label: "{size: '18px'}",
    options: <String, Object?>{'size': '18px'},
  ),
  (
    label:
        "{size: 16, style: 'italic', weight: 600, family: 'Georgia, "
        "serif', lineHeight: '150%'}",
    options: <String, Object?>{
      'size': 16.0,
      'style': 'italic',
      'weight': 600.0,
      'family': 'Georgia, serif',
      'lineHeight': '150%',
    },
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
/// 0006): an absent key and the `undefined` sentinel go on to the next
/// scope, and JS `null` is a value.
class OptionsDemo extends StatelessWidget {
  /// Creates the options tab.
  const OptionsDemo({super.key});

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
            [
              for (final s in _scopes) _resolveRow(s),
            ],
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
              'helpers.options toFont(options) → '
              'helpers.canvas toFontString(font)',
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
            [
              for (final p in _paddings) _paddingRow(p.label, p.value),
            ],
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
      'backgroundColor': '#36A2EB',
      'font': <String, Object?>{'size': 20.0, 'weight': 'bold'},
    };
    final resolver = createResolver([dataset, defaults]);
    final font = resolver['font']! as Map<String, Object?>;
    final context0 = attachContext(resolver, <String, Object?>{});
    final hover = context0['hoverBackgroundColor'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Mono(
          "dataset = {backgroundColor: '#36A2EB', "
          "font: {size: 20, weight: 'bold'}}",
        ),
        const SizedBox(height: 8),
        _table(
          context,
          const ['read', 'resolved', 'from'],
          [
            ['font.size', showJs(font['size']), 'dataset'],
            ['font.weight', showJs(font['weight']), 'dataset'],
            ['font.family', showJs(font['family']), 'defaults.font'],
            ['font.lineHeight', showJs(font['lineHeight']), 'defaults.font'],
            [
              'hoverBackgroundColor',
              showJs(hover),
              _hoverSource,
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ColorSwatchBox(color: cssColor('#36A2EB'), size: 28),
            const Text('backgroundColor'),
            const SizedBox(width: 10),
            ColorSwatchBox(color: cssColor(hover as String?), size: 28),
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
        jsNumberToString(v),
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
      child: Text(
        text,
        style: head ? theme.textTheme.labelLarge : mono,
      ),
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

/// One `toFont` result: the CSS string, the sizes and a sample text.
class _FontRow extends StatelessWidget {
  const _FontRow({required this.label, required this.font});

  final String label;
  final ParsedFont font;

  /// The Flutter weight of a CSS font weight: `bold`, `normal` or a number.
  static FontWeight? _weight(Object? weight) => switch (weight) {
    'bold' => FontWeight.w700,
    'normal' => FontWeight.w400,
    final num n => FontWeight.values[((n / 100).round() - 1).clamp(0, 8)],
    _ => null,
  };

  /// The first family of a CSS family list, without quotes.
  static String? _family(String? families) =>
      families?.split(',').first.trim().replaceAll(RegExp('[\'"]'), '');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Mono('toFont($label)', style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Mono(
          '${toFontString(font)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Mono(
          'size ${showJs(font.size)} · lineHeight ${showJs(font.lineHeight)}px'
          ' · weight ${showJs(font.weight)} · style ${showJs(font.style)}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          'The quick brown fox · 1,234.56',
          style: TextStyle(
            fontSize: font.size,
            height: font.size == null ? null : font.lineHeight / font.size!,
            fontWeight: _weight(font.weight),
            fontStyle: font.style == 'italic' ? FontStyle.italic : null,
            fontFamily: _family(font.family),
          ),
        ),
      ],
    );
  }
}
