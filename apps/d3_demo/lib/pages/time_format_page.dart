// Original code, not ported from D3: flutter_d3_time_format_port demo.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_d3_time_format_port/d3_time_format.dart' as d3tf;
import 'package:flutter_d3_time_port/d3_time.dart' as d3t;
import 'package:material_ui/material_ui.dart';

enum _TickScale(final String label) {
  minutes('15 Minutes'),
  hours('12 Hours'),
  days('5 Days'),
  year('1 Year'),
  fiveYears('5 Years');

  (DateTime, DateTime) bounds({required bool isUtc}) {
    DateTime make(int y, [int m = 1, int d = 1, int h = 0, int min = 0]) =>
        isUtc ? DateTime.utc(y, m, d, h, min) : DateTime(y, m, d, h, min);

    return switch (this) {
      _TickScale.minutes => (make(2024, 6, 15, 14), make(2024, 6, 15, 14, 15)),
      _TickScale.hours => (make(2024, 6, 15, 6), make(2024, 6, 15, 18)),
      _TickScale.days => (make(2024, 6, 12), make(2024, 6, 17)),
      _TickScale.year => (make(2024), make(2025)),
      _TickScale.fiveYears => (make(2021), make(2026)),
    };
  }
}

/// Interactive showcase of `flutter_d3_time_format_port`: live directive
/// playground with editable specifier input & preset chips, dropdown over all
/// 34 built-in locales, Local vs UTC toggle, live formatted output with
/// round-trip `timeParse`/`utcParse` verification readout, and multi-scale
/// tick label preview combining `flutter_d3_time_port` with
/// `flutter_d3_time_format_port`.
class const TimeFormatDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-time-format` demo page.
  this;

  @override
  State<TimeFormatDemoPage> createState() => _TimeFormatDemoPageState();
}

class _TimeFormatDemoPageState() extends State<TimeFormatDemoPage> {
  static const _specPresets = <(String, String)>[
    ('%c', 'Locale'),
    ('%Y-%m-%dT%H:%M:%S.%LZ', 'ISO 8601'),
    ('%A, %B %-d, %Y', 'Long date'),
    ('%a, %d %b %Y %H:%M:%S %Z', 'RFC-style'),
    ('%-I:%M:%S %p', '12h clock'),
    ('%G-W%V-%u', 'ISO week'),
    ('%Y-%j Q%q', 'DOY & Qtr'),
    ('%Q', 'Unix ms'),
  ];

  static const _quickLocales = <String>[
    'en-US',
    'fr-FR',
    'de-DE',
    'ja-JP',
    'es-ES',
    'ar-EG',
    'uk-UA',
    'zh-CN',
    'fi-FI',
    'ko-KR',
  ];

  static final _sampleDatesUtc = <(String, DateTime)>[
    ('2024-06-15 14:37:22.432', DateTime.utc(2024, 6, 15, 14, 37, 22, 432)),
    ('2000-02-29 Leap Day', DateTime.utc(2000, 2, 29, 9, 5, 3, 120)),
    ('2018-12-31 ISO W01', DateTime.utc(2018, 12, 31, 23, 59, 59)),
    ('1990-01-01 Midnight', DateTime.utc(1990)),
  ];

  late final TextEditingController _specController = TextEditingController(
    text: '%c',
  );

  String _specText = '%c';
  String _localeTag = 'en-US';
  bool _isUtc = true;
  int _sampleIndex = 0;
  _TickScale _tickScale = _TickScale.year;
  int _targetTicks = 8;

  @override
  void dispose() {
    _specController.dispose();
    super.dispose();
  }

  void _selectSpec(String spec) {
    setState(() {
      _specText = spec;
      _specController.text = spec;
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

  String _multiScaleLabel(DateTime d, d3tf.TimeLocale locale, bool isUtc) {
    final fmt = isUtc ? locale.utcFormat : locale.format;
    final second = isUtc ? d3t.utcSecond : d3t.timeSecond;
    final minute = isUtc ? d3t.utcMinute : d3t.timeMinute;
    final hour = isUtc ? d3t.utcHour : d3t.timeHour;
    final day = isUtc ? d3t.utcDay : d3t.timeDay;
    final week = isUtc ? d3t.utcWeek : d3t.timeWeek;
    final month = isUtc ? d3t.utcMonth : d3t.timeMonth;
    final year = isUtc ? d3t.utcYear : d3t.timeYear;

    if (second(d).isBefore(d)) return fmt('.%L')(d);
    if (minute(d).isBefore(d)) return fmt(':%S')(d);
    if (hour(d).isBefore(d)) return fmt('%H:%M')(d);
    if (day(d).isBefore(d)) return fmt('%-I %p')(d);
    if (month(d).isBefore(d)) {
      return week(d).isBefore(d) ? fmt('%a %d')(d) : fmt('%b %d')(d);
    }
    if (year(d).isBefore(d)) return fmt('%B')(d);
    return fmt('%Y')(d);
  }

  String _multiScaleSpec(DateTime d, bool isUtc) {
    final second = isUtc ? d3t.utcSecond : d3t.timeSecond;
    final minute = isUtc ? d3t.utcMinute : d3t.timeMinute;
    final hour = isUtc ? d3t.utcHour : d3t.timeHour;
    final day = isUtc ? d3t.utcDay : d3t.timeDay;
    final week = isUtc ? d3t.utcWeek : d3t.timeWeek;
    final month = isUtc ? d3t.utcMonth : d3t.timeMonth;
    final year = isUtc ? d3t.utcYear : d3t.timeYear;

    if (second(d).isBefore(d)) return '.%L';
    if (minute(d).isBefore(d)) return ':%S';
    if (hour(d).isBefore(d)) return '%H:%M';
    if (day(d).isBefore(d)) return '%-I %p';
    if (month(d).isBefore(d)) {
      return week(d).isBefore(d) ? '%a %d' : '%b %d';
    }
    if (year(d).isBefore(d)) return '%B';
    return '%Y';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final def = d3tf.timeFormatLocales[_localeTag] ?? d3tf.timeLocaleEnUS;
    final locale = d3tf.timeFormatLocale(def);
    final allTags = d3tf.timeFormatLocales.keys.toList(growable: false);

    final baseUtc = _sampleDatesUtc[_sampleIndex].$2;
    final sample = _isUtc ? baseUtc : baseUtc.toLocal();

    final formatter = _isUtc
        ? locale.utcFormat(_specText)
        : locale.format(_specText);
    final parser = _isUtc
        ? locale.utcParse(_specText)
        : locale.parse(_specText);

    final formatted = formatter(sample);
    final roundTripped = parser(formatted);
    final parsedIso = roundTripped == null
        ? 'null'
        : d3tf.isoFormat(roundTripped);
    final exactMatch =
        roundTripped != null &&
        roundTripped.millisecondsSinceEpoch == sample.millisecondsSinceEpoch;
    final sameSecond =
        roundTripped != null &&
        (roundTripped.millisecondsSinceEpoch - sample.millisecondsSinceEpoch)
                .abs() <
            1000;

    final (tickStart, tickStop) = _tickScale.bounds(isUtc: _isUtc);
    final ticks = _isUtc
        ? d3t.utcTicks(tickStart, tickStop, _targetTicks)
        : d3t.timeTicks(tickStart, tickStop, _targetTicks);
    final tickLabels = [
      for (final t in ticks) _multiScaleLabel(t, locale, _isUtc),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Directive Playground, 34 Built-In Locales & Multi-Scale Tick '
                'Labels',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pure Dart port of d3-time-format '
                'v${d3tf.d3TimeFormatVersion} with zero JS runtime: all 32 '
                'strftime/strptime directives, pad modifiers, isoFormat / '
                'isoParse, and all 34 upstream locales as const Dart objects.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // 1. Live Directive Playground + Round-Trip Verification
              Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Text(
                            'Live Directive Playground',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: true,
                                label: Text('UTC'),
                                icon: Icon(Icons.public, size: 18),
                              ),
                              ButtonSegment<bool>(
                                value: false,
                                label: Text('Local'),
                                icon: Icon(Icons.schedule, size: 18),
                              ),
                            ],
                            selected: <bool>{_isUtc},
                            onSelectionChanged: (s) =>
                                setState(() => _isUtc = s.first),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 300,
                            child: TextField(
                              controller: _specController,
                              decoration: const InputDecoration(
                                labelText: 'Time format specifier',
                                hintText: 'e.g. %Y-%m-%d %H:%M:%S %Z',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (v) => setState(() => _specText = v),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Locale (all 34)',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: _localeTag,
                                  items: [
                                    for (final tag in allTags)
                                      DropdownMenuItem(
                                        value: tag,
                                        child: Text(tag),
                                      ),
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
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in _quickLocales)
                            ActionChip(
                              label: Text(tag),
                              backgroundColor: _localeTag == tag
                                  ? cs.secondaryContainer
                                  : null,
                              onPressed: () => setState(() => _localeTag = tag),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (var i = 0; i < _sampleDatesUtc.length; ++i)
                            ChoiceChip(
                              label: Text(_sampleDatesUtc[i].$1),
                              selected: _sampleIndex == i,
                              onSelected: (_) =>
                                  setState(() => _sampleIndex = i),
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
                          color: cs.surfaceContainerHighest.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                formatted,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copy formatted output',
                              icon: const Icon(Icons.copy_outlined),
                              onPressed: () => _copy(formatted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: roundTripped == null
                              ? cs.errorContainer.withValues(alpha: 0.45)
                              : exactMatch
                              ? cs.primaryContainer.withValues(alpha: 0.45)
                              : cs.secondaryContainer.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  roundTripped == null
                                      ? Icons.warning_amber_rounded
                                      : exactMatch
                                      ? Icons.verified_outlined
                                      : Icons.check_circle_outline,
                                  size: 18,
                                  color: roundTripped == null
                                      ? cs.error
                                      : cs.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    roundTripped == null
                                        ? 'Round-trip '
                                              '${_isUtc ? 'utc' : 'time'}'
                                              'Parse: returned null'
                                              ' (unparseable specifier)'
                                        : exactMatch
                                        ? 'Round-trip '
                                              '${_isUtc ? 'utc' : 'time'}'
                                              'Parse: exact millisecond match'
                                        : sameSecond
                                        ? 'Round-trip '
                                              '${_isUtc ? 'utc' : 'time'}'
                                              'Parse: parsed'
                                              ' (sub-second truncated)'
                                        : 'Round-trip '
                                              '${_isUtc ? 'utc' : 'time'}'
                                              'Parse: parsed partial fields',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Input isoFormat:  ${d3tf.isoFormat(sample)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'Parsed result:    $parsedIso',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Multi-Scale Tick Label Preview (d3-time + d3-time-format)
              Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multi-Scale Tick Label Preview '
                        '(d3-time + d3-time-format)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Combines ${_isUtc ? 'utcTicks' : 'timeTicks'} from '
                        'flutter_d3_time_port with a conditional multi-scale '
                        'formatter in locale $_localeTag.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final s in _TickScale.values)
                            ChoiceChip(
                              label: Text(s.label),
                              selected: _tickScale == s,
                              onSelected: (_) => setState(() => _tickScale = s),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            'Target ticks: $_targetTicks',
                            style: theme.textTheme.labelMedium,
                          ),
                          SizedBox(
                            width: 160,
                            child: Slider(
                              value: _targetTicks.toDouble(),
                              min: 4,
                              max: 12,
                              divisions: 8,
                              onChanged: (v) =>
                                  setState(() => _targetTicks = v.round()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 82,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _TickAxisPainter(
                            startMs: tickStart.millisecondsSinceEpoch,
                            stopMs: tickStop.millisecondsSinceEpoch,
                            ticks: ticks,
                            labels: tickLabels,
                            axisColor: cs.outline,
                            tickColor: cs.primary,
                            labelColor: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < ticks.length; ++i)
                            Chip(
                              label: Text(
                                '${tickLabels[i]}  '
                                '(${_multiScaleSpec(ticks[i], _isUtc)})',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Locale Spotlight Matrix
              Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Locale Spotlight (%c across 10 locales)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final tag in _quickLocales)
                            Builder(
                              builder: (context) {
                                final loc = d3tf.timeFormatLocale(
                                  d3tf.timeFormatLocales[tag]!,
                                );
                                final text = (_isUtc
                                    ? loc.utcFormat('%c')
                                    : loc.format('%c'))(sample);
                                final selected = tag == _localeTag;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => setState(() => _localeTag = tag),
                                  child: Container(
                                    width: 330,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: selected
                                            ? cs.primary
                                            : cs.outlineVariant,
                                      ),
                                      color: selected
                                          ? cs.primaryContainer.withValues(
                                              alpha: 0.35,
                                            )
                                          : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tag,
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: cs.primary,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          text,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontFamily: 'monospace',
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _TickAxisPainter({
  required final int startMs,
  required final int stopMs,
  required final List<DateTime> ticks,
  required final List<String> labels,
  required final Color axisColor,
  required final Color tickColor,
  required final Color labelColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const padX = 28.0;
    final usable = (size.width - padX * 2).clamp(1.0, double.infinity);
    const axisY = 24.0;

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.5;
    canvas.drawLine(
      const Offset(padX, axisY),
      Offset(size.width - padX, axisY),
      axisPaint,
    );

    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 2;

    final span = (stopMs - startMs).toDouble();
    if (span <= 0) return;

    var lastRight = -1e9;
    for (var i = 0; i < ticks.length; ++i) {
      final t = (ticks[i].millisecondsSinceEpoch - startMs) / span;
      final x = padX + t.clamp(0.0, 1.0) * usable;
      canvas.drawLine(Offset(x, axisY - 6), Offset(x, axisY + 8), tickPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final left = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
      if (left >= lastRight + 6) {
        tp.paint(canvas, Offset(left, axisY + 14));
        lastRight = left + tp.width;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TickAxisPainter old) =>
      old.startMs != startMs ||
      old.stopMs != stopMs ||
      old.ticks.length != ticks.length ||
      old.labels.join('|') != labels.join('|') ||
      old.labelColor != labelColor;
}
