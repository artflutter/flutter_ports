// Original code, not ported from D3: flutter_d3_time_port interactive demo.

import 'package:flutter_d3_time_port/d3_time.dart' as d3;
import 'package:material_ui/material_ui.dart';

enum _SpanPreset(final String label) {
  minutes('15 Minutes'),
  hours('6 Hours'),
  days('3 Days'),
  weeks('4 Weeks'),
  year('1 Year'),
  fiveYears('5 Years'),
  decades('3 Decades');

  (DateTime, DateTime) bounds({required bool isUtc}) {
    DateTime make(
      int y, [
      int m = 1,
      int d = 1,
      int h = 0,
      int min = 0,
      int s = 0,
    ]) =>
        isUtc ? DateTime.utc(y, m, d, h, min, s) : DateTime(y, m, d, h, min, s);

    return switch (this) {
      _SpanPreset.minutes => (
        make(2024, 3, 10, 1, 50),
        make(2024, 3, 10, 2, 5),
      ),
      _SpanPreset.hours => (make(2024, 3, 10), make(2024, 3, 10, 6)),
      _SpanPreset.days => (make(2024, 3, 9), make(2024, 3, 12)),
      _SpanPreset.weeks => (make(2024, 3), make(2024, 3, 29)),
      _SpanPreset.year => (make(2024), make(2025)),
      _SpanPreset.fiveYears => (make(2020), make(2025)),
      _SpanPreset.decades => (make(1995), make(2025)),
    };
  }
}

enum _IntervalKind(
  final String label,
  final String utcName,
  final String localName,
) {
  second('Second', 'utcSecond', 'timeSecond'),
  minute('Minute', 'utcMinute', 'timeMinute'),
  hour('Hour', 'utcHour', 'timeHour'),
  day('Day', 'utcDay', 'timeDay'),
  week('Week (Sun)', 'utcSunday', 'timeSunday'),
  monday('Monday', 'utcMonday', 'timeMonday'),
  month('Month', 'utcMonth', 'timeMonth'),
  year('Year', 'utcYear', 'timeYear');

  d3.CountableTimeInterval resolve({required bool isUtc}) => switch (this) {
    _IntervalKind.second => isUtc ? d3.utcSecond : d3.timeSecond,
    _IntervalKind.minute => isUtc ? d3.utcMinute : d3.timeMinute,
    _IntervalKind.hour => isUtc ? d3.utcHour : d3.timeHour,
    _IntervalKind.day => isUtc ? d3.utcDay : d3.timeDay,
    _IntervalKind.week => isUtc ? d3.utcSunday : d3.timeSunday,
    _IntervalKind.monday => isUtc ? d3.utcMonday : d3.timeMonday,
    _IntervalKind.month => isUtc ? d3.utcMonth : d3.timeMonth,
    _IntervalKind.year => isUtc ? d3.utcYear : d3.timeYear,
  };

  String apiName({required bool isUtc}) => isUtc ? utcName : localName;
}

/// Interactive showcase of `flutter_d3_time_port`: live timeline range explorer
/// with Local vs UTC toggle, date span presets from minutes to decades, target
/// tick-count slider displaying `timeTicks`/`utcTicks` and the chosen
/// `timeTickInterval`/`utcTickInterval`, plus an interactive `floor`/`ceil`/
/// `round`/`offset` interval stepper.
class const TimeDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-time` demo page.
  this;

  @override
  State<TimeDemoPage> createState() => _TimeDemoPageState();
}

class _TimeDemoPageState() extends State<TimeDemoPage> {
  bool _isUtc = true;
  _SpanPreset _preset = _SpanPreset.year;
  int _targetTicks = 8;

  _IntervalKind _intervalKind = _IntervalKind.day;
  int _everyStep = 1;
  int _offsetStep = 1;
  DateTime _anchorUtc = DateTime.utc(2024, 6, 15, 14, 37, 22);

  DateTime get _anchor => _isUtc ? _anchorUtc : _anchorUtc.toLocal();

  String _formatDate(DateTime d, {bool includeTime = true}) {
    String pad2(int v) => v.toString().padLeft(2, '0');
    final y = d.year.toString().padLeft(4, '0');
    final base = '$y-${pad2(d.month)}-${pad2(d.day)}';
    if (!includeTime) return _isUtc ? '${base}Z' : base;
    final time = '${pad2(d.hour)}:${pad2(d.minute)}:${pad2(d.second)}';
    if (d.isUtc) return '$base ${time}Z';
    final off = d.timeZoneOffset;
    final sign = off.isNegative ? '-' : '+';
    final absMin = off.inMinutes.abs();
    final oh = pad2(absMin ~/ 60);
    final om = pad2(absMin % 60);
    return '$base $time $sign$oh:$om';
  }

  String _shortTickLabel(DateTime d, Duration span) {
    String pad2(int v) => v.toString().padLeft(2, '0');
    if (span.inDays >= 730) return '${d.year}';
    if (span.inDays >= 60) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[d.month - 1]} ${d.year % 100}';
    }
    if (span.inDays >= 2) {
      return '${pad2(d.month)}-${pad2(d.day)}';
    }
    if (span.inHours >= 1) {
      return '${pad2(d.hour)}:${pad2(d.minute)}';
    }
    return '${pad2(d.hour)}:${pad2(d.minute)}:${pad2(d.second)}';
  }

  String _describeTickInterval(
    d3.TimeInterval? interval,
    DateTime start,
    DateTime stop,
    bool isUtc,
  ) {
    if (interval == null) return 'none';
    final prefix = isUtc ? 'utc' : 'time';
    final probe = interval.ceil(start);
    final next = interval.offset(probe);
    final diffMs = next.millisecondsSinceEpoch - probe.millisecondsSinceEpoch;
    if (diffMs < d3.durationSecond) {
      return '${prefix}Millisecond.every($diffMs)';
    }
    if (diffMs < d3.durationMinute) {
      final s = (diffMs / d3.durationSecond).round();
      return s == 1 ? '${prefix}Second' : '${prefix}Second.every($s)';
    }
    if (diffMs < d3.durationHour) {
      final m = (diffMs / d3.durationMinute).round();
      return m == 1 ? '${prefix}Minute' : '${prefix}Minute.every($m)';
    }
    if (diffMs < d3.durationDay) {
      final h = (diffMs / d3.durationHour).round();
      return h == 1 ? '${prefix}Hour' : '${prefix}Hour.every($h)';
    }
    if (diffMs < 5 * d3.durationDay) {
      final days = (diffMs / d3.durationDay).round();
      final dayName = isUtc ? 'unixDay' : 'timeDay';
      return days == 1 ? dayName : '$dayName.every($days)';
    }
    if (diffMs < 20 * d3.durationDay) {
      return '${prefix}Sunday';
    }
    if (diffMs < 320 * d3.durationDay) {
      final months = (diffMs / d3.durationMonth).round();
      return months <= 1 ? '${prefix}Month' : '${prefix}Month.every($months)';
    }
    final years = (diffMs / d3.durationYear).round();
    return years <= 1 ? '${prefix}Year' : '${prefix}Year.every($years)';
  }

  void _stepAnchor(int delta) {
    final base = _intervalKind.resolve(isUtc: _isUtc);
    final active = _everyStep == 1 ? base : (base.every(_everyStep) ?? base);
    final stepped = active.offset(_anchor, delta);
    setState(() {
      _anchorUtc = stepped.toUtc();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (start, stop) = _preset.bounds(isUtc: _isUtc);
    final ticks = _isUtc
        ? d3.utcTicks(start, stop, _targetTicks)
        : d3.timeTicks(start, stop, _targetTicks);
    final chosen = _isUtc
        ? d3.utcTickInterval(start, stop, _targetTicks)
        : d3.timeTickInterval(start, stop, _targetTicks);
    final intervalLabel = _describeTickInterval(chosen, start, stop, _isUtc);
    final span = stop.difference(start);

    final showTime = span.inDays < 7;
    final domainText =
        '${_formatDate(start, includeTime: showTime)} → '
        '${_formatDate(stop, includeTime: showTime)}';
    final offsetStepText = _offsetStep >= 0 ? '+$_offsetStep' : '$_offsetStep';

    final baseInterval = _intervalKind.resolve(isUtc: _isUtc);
    final activeInterval = _everyStep == 1
        ? baseInterval
        : (baseInterval.every(_everyStep) ?? baseInterval);
    final anchor = _anchor;
    final floored = activeInterval.floor(anchor);
    final ceiled = activeInterval.ceil(anchor);
    final rounded = activeInterval.round(anchor);
    final offsetted = activeInterval.offset(anchor, _offsetStep);
    final countSinceStart = baseInterval.count(start, anchor);
    final activeName = _everyStep == 1
        ? _intervalKind.apiName(isUtc: _isUtc)
        : '${_intervalKind.apiName(isUtc: _isUtc)}.every($_everyStep)';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Calendar Time Intervals, Ticks & Local/UTC Timeline Explorer',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Native Dart DateTime intervals from '
                'd3-time v${d3.d3TimeVersion}: automatic calendar-aligned '
                'ticks, Local vs UTC boundaries, and interactive floor / '
                'ceil / round / offset stepping.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                            'Timeline Range & Tick Explorer',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
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
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final p in _SpanPreset.values)
                            ChoiceChip(
                              label: Text(p.label),
                              selected: _preset == p,
                              onSelected: (_) => setState(() => _preset = p),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Target ticks: $_targetTicks',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Slider(
                              value: _targetTicks.toDouble(),
                              min: 2,
                              max: 20,
                              divisions: 18,
                              label: '$_targetTicks',
                              onChanged: (v) =>
                                  setState(() => _targetTicks = v.round()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _InfoPill(
                            label: _isUtc
                                ? 'utcTickInterval'
                                : 'timeTickInterval',
                            value: intervalLabel,
                            color: cs.primaryContainer,
                            textColor: cs.onPrimaryContainer,
                          ),
                          _InfoPill(
                            label: _isUtc ? 'utcTicks' : 'timeTicks',
                            value: '${ticks.length} ticks',
                            color: cs.secondaryContainer,
                            textColor: cs.onSecondaryContainer,
                          ),
                          _InfoPill(
                            label: 'Domain',
                            value: domainText,
                            color: cs.surfaceContainerHighest,
                            textColor: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        height: 108,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: CustomPaint(
                          painter: _TimelineRulerPainter(
                            start: start,
                            stop: stop,
                            ticks: ticks,
                            labelFor: (d) => _shortTickLabel(d, span),
                            accent: cs.primary,
                            axisColor: cs.outline,
                            labelColor: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final t in ticks)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatDate(t, includeTime: span.inDays < 7),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interval Stepper (floor / ceil / round / offset)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final k in _IntervalKind.values)
                            ChoiceChip(
                              label: Text(k.label),
                              selected: _intervalKind == k,
                              onSelected: (_) =>
                                  setState(() => _intervalKind = k),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'every(step):',
                            style: theme.textTheme.labelLarge,
                          ),
                          for (final k in const [1, 2, 3, 5, 15])
                            ChoiceChip(
                              label: Text('${k}x'),
                              selected: _everyStep == k,
                              onSelected: (_) => setState(() => _everyStep = k),
                            ),
                          const SizedBox(width: 12),
                          FilledButton.tonalIcon(
                            onPressed: () => _stepAnchor(-1),
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Step −1'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _stepAnchor(1),
                            icon: const Icon(Icons.chevron_right),
                            label: const Text('Step +1'),
                          ),
                          OutlinedButton(
                            onPressed: () => setState(() {
                              _anchorUtc = DateTime.utc(
                                2024,
                                6,
                                15,
                                14,
                                37,
                                22,
                              );
                            }),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'offset step: $offsetStepText',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Slider(
                              value: _offsetStep.toDouble(),
                              min: -5,
                              max: 5,
                              divisions: 10,
                              label: '$_offsetStep',
                              onChanged: (v) =>
                                  setState(() => _offsetStep = v.round()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ResultTile(
                            title: 'Anchor input',
                            value: _formatDate(anchor),
                            highlight: cs.primary,
                          ),
                          _ResultTile(
                            title: '$activeName.floor(anchor)',
                            value: _formatDate(floored),
                          ),
                          _ResultTile(
                            title: '$activeName.ceil(anchor)',
                            value: _formatDate(ceiled),
                          ),
                          _ResultTile(
                            title: '$activeName.round(anchor)',
                            value: _formatDate(rounded),
                          ),
                          _ResultTile(
                            title: '$activeName.offset(anchor, $_offsetStep)',
                            value: _formatDate(offsetted),
                          ),
                          _ResultTile(
                            title:
                                '${_intervalKind.apiName(isUtc: _isUtc)}'
                                '.count(domainStart, anchor)',
                            value: '$countSinceStart intervals',
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

class const _InfoPill({
  required final String label,
  required final String value,
  required final Color color,
  required final Color textColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: style?.copyWith(color: textColor),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _ResultTile({
  required final String title,
  required final String value,
  final Color? highlight,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ?? cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: highlight ?? cs.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRulerPainter({
  required final DateTime start,
  required final DateTime stop,
  required final List<DateTime> ticks,
  required final String Function(DateTime) labelFor,
  required final Color accent,
  required final Color axisColor,
  required final Color labelColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const padX = 28.0;
    final axisY = size.height * 0.44;
    final usableW = (size.width - padX * 2).clamp(1.0, double.infinity);

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(padX, axisY),
      Offset(padX + usableW, axisY),
      axisPaint,
    );

    final startMs = start.millisecondsSinceEpoch;
    final spanMs = (stop.millisecondsSinceEpoch - startMs).toDouble();
    if (spanMs == 0) return;

    final tickPaint = Paint()
      ..color = accent
      ..strokeWidth = 2.0;
    final dotPaint = Paint()..color = accent;

    double? lastLabelRight;
    for (final tick in ticks) {
      final t = ((tick.millisecondsSinceEpoch - startMs) / spanMs).clamp(
        0.0,
        1.0,
      );
      final x = padX + t * usableW;
      canvas
        ..drawLine(Offset(x, axisY - 12), Offset(x, axisY + 12), tickPaint)
        ..drawCircle(Offset(x, axisY), 4, dotPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: labelFor(tick),
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final left = x - tp.width / 2;
      if (lastLabelRight == null || left > lastLabelRight + 8) {
        tp.paint(
          canvas,
          Offset(left.clamp(4.0, size.width - tp.width - 4.0), axisY + 18),
        );
        lastLabelRight = left + tp.width;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineRulerPainter oldDelegate) =>
      oldDelegate.start != start ||
      oldDelegate.stop != stop ||
      oldDelegate.ticks != ticks ||
      oldDelegate.accent != accent;
}
