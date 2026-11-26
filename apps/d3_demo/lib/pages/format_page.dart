// Original code, not ported from D3: flutter_d3_format_port interactive demo.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_d3_format_port/flutter_d3_format_port.dart' as d3;
import 'package:material_ui/material_ui.dart';

/// Interactive showcase of `flutter_d3_format_port`: live format specifier
/// playground, SI prefix / currency / percent / binary / hex preview matrix,
/// precision helpers, and locale switcher across all 59 built-in locales.
class const FormatDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-format` demo page.
  this;

  @override
  State<FormatDemoPage> createState() => _FormatDemoPageState();
}

class _FormatDemoPageState() extends State<FormatDemoPage> {
  static const _specPresets = <(String, String)>[
    (r'+$,.2f', 'Currency'),
    (r'($,.2f', 'Accounting'),
    ('.3s', 'SI prefix'),
    ('~s', 'SI trim'),
    ('.1%', 'Percent'),
    ('.4~e', 'Scientific'),
    ('#010x', 'Hex'),
    ('#b', 'Binary'),
    ('012,d', 'Zero-pad'),
    ('^16,.2f', 'Centered'),
  ];

  static const _quickLocales = <String>[
    'en-US',
    'fr-FR',
    'de-DE',
    'en-GB',
    'en-IN',
    'ja-JP',
    'ar-AE',
    'de-CH',
    'ru-RU',
    'zh-CN',
  ];

  static const _quickValues = <(String, double)>[
    ('1,234,567.89', 1234567.89),
    ('-42.5', -42.5),
    ('0.2345', 0.2345),
    ('0.00042', 0.00042),
    ('145.5M', 145500000),
    ('0xDEADBEEF', 3735928559),
    ('0', 0),
    ('NaN', double.nan),
  ];

  late final TextEditingController _specController = TextEditingController(
    text: r'+$,.2f',
  );
  late final TextEditingController _valueController = TextEditingController(
    text: '1234567.89',
  );

  String _specText = r'+$,.2f';
  double _value = 1234567.89;
  String _localeTag = 'en-US';
  double _step = 0.05;

  @override
  void dispose() {
    _specController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _selectSpec(String spec) {
    setState(() {
      _specText = spec;
      _specController.text = spec;
    });
  }

  void _selectValue(double v, String text) {
    setState(() {
      _value = v;
      _valueController.text = text;
    });
  }

  void _copy(String text) {
    unawaited(Clipboard.setData(ClipboardData(text: text)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "$text"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final def = d3.formatLocales[_localeTag] ?? d3.localeEnUS;
    final locale = d3.formatLocale(def);

    d3.FormatSpecifier? parsed;
    String? formatted;
    String? parseError;
    try {
      parsed = d3.formatSpecifier(_specText);
      formatted = locale.formatFromSpecifier(parsed)(_value);
    } on FormatException catch (e) {
      parseError = e.message;
    }

    final allTags = d3.formatLocales.keys.toList(growable: false);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Number Formatting, Specifier Playground & 59 Built-In Locales',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pure Dart port of d3-format v${d3.d3FormatVersion} with zero JS '
          'runtime: Python-style format specifiers, SI prefixes, currency, '
          'grouping, custom numerals, precision helpers, and all 59 upstream '
          'locales as const Dart objects.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // 1. Live Specifier Playground
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Specifier Playground',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _specController,
                        decoration: InputDecoration(
                          labelText: 'Format specifier',
                          hintText:
                              '[[fill]align][sign][symbol][0][w][,][.p][~][t]',
                          border: const OutlineInputBorder(),
                          errorText: parseError,
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _specText = v),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _valueController,
                        decoration: const InputDecoration(
                          labelText: 'Input number',
                          hintText: 'e.g. 1234567.89 or NaN',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          final trimmed = v.trim().toLowerCase();
                          final parsedNum = switch (trimmed) {
                            'nan' => double.nan,
                            'infinity' || 'inf' => double.infinity,
                            '-infinity' || '-inf' => double.negativeInfinity,
                            '-0' || '-0.0' => -1.0 * 0.0,
                            _ => double.tryParse(trimmed),
                          };
                          if (parsedNum != null) {
                            setState(() => _value = parsedNum);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Locale (all 59)',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            isDense: true,
                            value: _localeTag,
                            items: [
                              for (final tag in allTags)
                                DropdownMenuItem(value: tag, child: Text(tag)),
                            ],
                            onChanged: (tag) {
                              if (tag != null) {
                                setState(() => _localeTag = tag);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (spec, label) in _specPresets)
                      ChoiceChip(
                        label: Text('$label ($spec)'),
                        selected: _specText == spec,
                        onSelected: (_) => _selectSpec(spec),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (label, val) in _quickValues)
                      ActionChip(
                        label: Text(label),
                        onPressed: () =>
                            _selectValue(val, val.isNaN ? 'NaN' : '$val'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          formatted ?? 'Invalid format specifier',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            color: formatted == null ? cs.error : cs.primary,
                          ),
                        ),
                      ),
                      if (formatted != null)
                        IconButton(
                          tooltip: 'Copy formatted output',
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: () => _copy(formatted!),
                        ),
                    ],
                  ),
                ),
                if (parsed != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _SpecPill('normalized', '"$parsed"'),
                      _SpecPill('fill', '"${parsed.fill}"'),
                      _SpecPill('align', parsed.align),
                      _SpecPill('sign', parsed.sign),
                      if (parsed.symbol.isNotEmpty)
                        _SpecPill('symbol', parsed.symbol),
                      if (parsed.zero) const _SpecPill('zero', 'true'),
                      if (parsed.width != null)
                        _SpecPill('width', '${parsed.width}'),
                      if (parsed.comma) const _SpecPill('comma', 'true'),
                      if (parsed.precision != null)
                        _SpecPill('precision', '${parsed.precision}'),
                      if (parsed.trim) const _SpecPill('trim', 'true'),
                      _SpecPill(
                        'type',
                        parsed.type.isEmpty ? '(none)' : parsed.type,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Locale Quick Switcher & Inspector
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Locale Switcher ($_localeTag — 59 Built-In Locales)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in _quickLocales)
                      ChoiceChip(
                        label: Text(tag),
                        selected: _localeTag == tag,
                        onSelected: (_) => setState(() => _localeTag = tag),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _SpecPill('decimal', '"${def.decimal}"'),
                    _SpecPill(
                      'thousands',
                      def.thousands == '\u00a0'
                          ? r'"\u00a0" (NBSP)'
                          : '"${def.thousands ?? ''}"',
                    ),
                    _SpecPill('grouping', '${def.grouping ?? const []}'),
                    _SpecPill(
                      'currency',
                      '("${def.currency?.$1 ?? ''}", '
                          '"${def.currency?.$2 ?? ''}")',
                    ),
                    _SpecPill('percent', '"${def.percent}"'),
                    if (def.numerals != null)
                      _SpecPill('numerals', def.numerals!.join()),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. SI Prefix / Currency / Percent / Binary / Hex Preview Grid
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Multi-Format Preview Matrix',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _PreviewTile(
                      label: 'Currency',
                      spec: r'$,.2f',
                      output: locale.format(r'$,.2f')(_value),
                      onTap: () => _selectSpec(r'$,.2f'),
                    ),
                    _PreviewTile(
                      label: 'Accounting',
                      spec: r'($,.2f',
                      output: locale.format(r'($,.2f')(_value),
                      onTap: () => _selectSpec(r'($,.2f'),
                    ),
                    _PreviewTile(
                      label: 'SI Prefix (3 sig)',
                      spec: '.3s',
                      output: locale.format('.3s')(_value),
                      onTap: () => _selectSpec('.3s'),
                    ),
                    _PreviewTile(
                      label: 'SI Prefix (trim)',
                      spec: '~s',
                      output: locale.format('~s')(_value),
                      onTap: () => _selectSpec('~s'),
                    ),
                    _PreviewTile(
                      label: 'SI Currency',
                      spec: r'$.3s',
                      output: locale.format(r'$.3s')(_value),
                      onTap: () => _selectSpec(r'$.3s'),
                    ),
                    _PreviewTile(
                      label: 'Fixed Mega Prefix',
                      spec: 'formatPrefix(",.2", 1e6)',
                      output: locale.formatPrefix(',.2', 1e6)(_value),
                      onTap: () => _selectSpec(',.2f'),
                    ),
                    _PreviewTile(
                      label: 'Percent',
                      spec: '.1%',
                      output: locale.format('.1%')(_value),
                      onTap: () => _selectSpec('.1%'),
                    ),
                    _PreviewTile(
                      label: 'Percent Rounded',
                      spec: '+.2p',
                      output: locale.format('+.2p')(_value),
                      onTap: () => _selectSpec('+.2p'),
                    ),
                    _PreviewTile(
                      label: 'Binary',
                      spec: '#b',
                      output: locale.format('#b')(_value),
                      onTap: () => _selectSpec('#b'),
                    ),
                    _PreviewTile(
                      label: 'Octal',
                      spec: '#o',
                      output: locale.format('#o')(_value),
                      onTap: () => _selectSpec('#o'),
                    ),
                    _PreviewTile(
                      label: 'Hex (lower)',
                      spec: '#x',
                      output: locale.format('#x')(_value),
                      onTap: () => _selectSpec('#x'),
                    ),
                    _PreviewTile(
                      label: 'Hex (0-pad upper)',
                      spec: '#010X',
                      output: locale.format('#010X')(_value),
                      onTap: () => _selectSpec('#010X'),
                    ),
                    _PreviewTile(
                      label: 'Grouped Integer',
                      spec: ',d',
                      output: locale.format(',d')(_value),
                      onTap: () => _selectSpec(',d'),
                    ),
                    _PreviewTile(
                      label: 'Scientific (trim)',
                      spec: '.4~e',
                      output: locale.format('.4~e')(_value),
                      onTap: () => _selectSpec('.4~e'),
                    ),
                    _PreviewTile(
                      label: 'General (n)',
                      spec: 'n',
                      output: locale.format('n')(_value),
                      onTap: () => _selectSpec('n'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Precision Helpers
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precision Helpers (step = $_step)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final step in const [
                      0.001,
                      0.01,
                      0.05,
                      0.5,
                      5.0,
                      500.0,
                    ])
                      ChoiceChip(
                        label: Text('step = $step'),
                        selected: _step == step,
                        onSelected: (_) => setState(() => _step = step),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _SpecPill(
                      'precisionFixed($_step)',
                      '${d3.precisionFixed(_step)}',
                    ),
                    _SpecPill(
                      'precisionPrefix($_step, $_value)',
                      '${d3.precisionPrefix(_step, _value)}',
                    ),
                    _SpecPill(
                      'precisionRound($_step, $_value)',
                      '${d3.precisionRound(_step, _value)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class const _SpecPill(final String name, final String value)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$name: $value',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(fontFamily: 'monospace', color: cs.onSecondaryContainer),
      ),
    );
  }
}

class const _PreviewTile({
  required final String label,
  required final String spec,
  required final String output,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 215,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    spec,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              output,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
