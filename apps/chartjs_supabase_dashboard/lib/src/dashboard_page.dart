// Original code, not ported from Chart.js: the page of the dashboard.

import 'dart:async';
import 'dart:ui' show FramePhase;

import 'package:chartjs_supabase_dashboard/src/live_chart.dart';
import 'package:chartjs_supabase_dashboard/src/live_series.dart';
import 'package:chartjs_supabase_dashboard/src/metric_source.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The app: the dashboard page on [source], in the brightness of the
/// platform. The builder puts a [ChartTheme] above the page.
class const DashboardApp({
  /// The table of the chart.
  required final MetricSource source,

  /// Whether the pump starts with the page.
  final bool pump = true,

  /// The id of the anonymous session, or Dart `null` with no session.
  final String? session,
  super.key,
}) extends StatelessWidget {
  /// Creates the app.
  this;

  static final _light = ThemeData(colorSchemeSeed: const Color(0xFF3ECF8E));
  static final _dark = ThemeData(
    colorSchemeSeed: const Color(0xFF3ECF8E),
    brightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Live dashboard',
    debugShowCheckedModeBanner: false,
    theme: _light,
    darkTheme: _dark,
    builder: (context, child) => ChartTheme(
      data: Theme.of(context).brightness == Brightness.dark
          ? const ChartThemeData.dark().copyWith(
              surface: Theme.of(context).colorScheme.surface,
            )
          : const ChartThemeData.light(),
      child: child!,
    ),
    home: DashboardPage(source: source, pump: pump, session: session),
  );
}

/// The dashboard: the status of the data and the live chart.
class const DashboardPage({
  /// The table of the chart.
  required final MetricSource source,

  /// Whether the pump starts with the page.
  final bool pump = true,

  /// The id of the anonymous session, or Dart `null` with no session.
  final String? session,
  super.key,
}) extends StatefulWidget {
  /// Creates the page.
  this;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState() extends State<DashboardPage> {
  late final LiveSeries _series = LiveSeries(widget.source);

  @override
  void initState() {
    super.initState();
    unawaited(_series.start(pump: widget.pump));
  }

  @override
  void dispose() {
    _series.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('metric_points · live'),
      actions: [
        ListenableBuilder(
          listenable: _series,
          builder: (context, _) => IconButton(
            key: const ValueKey('dashboard.pump'),
            tooltip: _series.pumping ? 'Stop the inserts' : 'Start the inserts',
            onPressed: () => _series.pumping = !_series.pumping,
            icon: Icon(_series.pumping ? Icons.pause : Icons.play_arrow),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListenableBuilder(
              listenable: _series,
              builder: (context, _) =>
                  _StatusBar(series: _series, session: widget.session),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LiveChart(series: _series),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drag, scroll or swipe the chart to go back in time: the '
              'older rows load from Supabase one page at a time. Zoom with '
              'the buttons, a pinch, or Ctrl and the wheel.',
              key: const ValueKey('dashboard.help'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

/// The status of the series: the realtime channel, the rows in memory, the
/// inserts of this client and the time from an insert to its row.
class const _StatusBar({
  required final LiveSeries series,
  final String? session,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (statusText, statusColor) = switch (series.status) {
      LinkStatus.connecting => ('Connecting', scheme.tertiary),
      LinkStatus.live => ('Realtime on', const Color(0xFF3ECF8E)),
      LinkStatus.down => ('Realtime off', scheme.error),
    };
    final roundTrip = series.roundTrip;
    final error = series.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          key: const ValueKey('dashboard.status'),
          spacing: 8,
          runSpacing: 8,
          children: [
            if (session case final session?)
              _Stat(
                key: const ValueKey('dashboard.session'),
                icon: Icons.person_outline,
                label: 'Session ${session.substring(0, 8)}',
              ),
            _Stat(
              icon: Icons.circle,
              iconColor: statusColor,
              label: statusText,
            ),
            _Stat(
              icon: Icons.storage,
              label:
                  '${series.rowCount} rows · ${series.pages} '
                  '${series.pages == 1 ? 'page' : 'pages'}',
            ),
            _Stat(
              icon: Icons.upload,
              label: series.pumping
                  ? '${series.sent} sent · every '
                        '${series.pumpInterval.inMilliseconds} ms'
                  : '${series.sent} sent · paused',
            ),
            _Stat(icon: Icons.download, label: '${series.received} received'),
            _Stat(
              icon: Icons.timer_outlined,
              label: roundTrip == null
                  ? 'Round trip —'
                  : 'Round trip ${roundTrip.inMilliseconds} ms',
            ),
            const _FrameRate(),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error,
              key: const ValueKey('dashboard.error'),
              style: TextStyle(color: scheme.error),
            ),
          ),
      ],
    );
  }
}

class const _Stat({
  required final IconData icon,
  required final String label,
  final Color? iconColor,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 16, color: iconColor),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

/// The frame rate of the last second and the 90th percentile of the frame
/// time (build and raster), from the frame timings of the engine. It shows
/// "idle" with fewer than 10 frames in the last second.
class const _FrameRate() extends StatefulWidget {
  @override
  State<_FrameRate> createState() => _FrameRateState();
}

class _FrameRateState() extends State<_FrameRate> {
  /// The raster end (microseconds of the engine clock) and the time of
  /// each frame of the last 2 seconds.
  final List<(int, Duration)> _frames = [];
  DateTime _lastReport = DateTime(0);
  late final Timer _timer;
  String _text = '— fps';

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _show());
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _timer.cancel();
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    _lastReport = DateTime.now();
    for (final timing in timings) {
      _frames.add((
        timing.timestampInMicroseconds(FramePhase.rasterFinish),
        timing.totalSpan,
      ));
    }
    final newest = _frames.last.$1;
    _frames.removeWhere((frame) => frame.$1 < newest - 2000000);
  }

  void _show() {
    final String text;
    final newest = _frames.isEmpty ? 0 : _frames.last.$1;
    final second = [
      for (final (end, span) in _frames)
        if (end > newest - 1000000) span.inMicroseconds,
    ]..sort();
    // The chart draws no frame while nothing moves: fewer than 10 frames in
    // a second is an idle chart, not a slow one.
    if (second.length < 10 ||
        DateTime.now().difference(_lastReport) > const Duration(seconds: 2)) {
      text = 'idle';
    } else {
      final p90 =
          second[(second.length * 0.9).floor().clamp(0, second.length - 1)];
      text = '${second.length} fps · p90 ${(p90 / 1000).toStringAsFixed(1)} ms';
    }
    if (text != _text) setState(() => _text = text);
  }

  @override
  Widget build(BuildContext context) => _Stat(icon: Icons.speed, label: _text);
}
