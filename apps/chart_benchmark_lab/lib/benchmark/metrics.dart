import 'dart:math' as math;

/// Engine timing for a rendered frame, in one monotonic clock domain.
class FrameSample {
  /// Times use microseconds for timestamps and milliseconds for durations.
  const FrameSample(this.vsyncUs, this.uiMs, this.rasterMs);

  /// Engine vsync timestamp, never a wall-clock date.
  final int vsyncUs;

  /// Flutter UI work for the frame.
  final double uiMs;

  /// Raster-thread work for the frame.
  final double rasterMs;
}

/// Summary of actual engine frames, not ticker callbacks.
class FrameMetrics {
  /// An empty summary uses zero samples; the UI displays dashes.
  const FrameMetrics({
    this.samples = 0,
    this.fps = 0,
    this.intervalP90 = 0,
    this.intervalMax = 0,
    this.cadenceMissPercent = 0,
    this.uiMean = 0,
    this.uiP50 = 0,
    this.uiP90 = 0,
    this.uiMax = 0,
    this.rasterMean = 0,
    this.rasterP90 = 0,
    this.rasterMax = 0,
    this.overBudgetPercent = 0,
  });

  /// Summarize a window without mutating the input list.
  factory FrameMetrics.fromSamples(
    List<FrameSample> frames, {
    double? windowSeconds,
  }) {
    if (frames.isEmpty) return const FrameMetrics();
    final ordered = List<FrameSample>.of(frames)
      ..sort((a, b) => a.vsyncUs.compareTo(b.vsyncUs));
    final ui = frames.map((f) => f.uiMs).toList()..sort();
    final raster = frames.map((f) => f.rasterMs).toList()..sort();
    double mean(List<double> values) =>
        values.reduce((a, b) => a + b) / values.length;
    double percentile(List<double> values, double p) =>
        values[(values.length * p).ceil() - 1];
    final gaps = <double>[
      for (var i = 1; i < ordered.length; i++)
        (ordered[i].vsyncUs - ordered[i - 1].vsyncUs) / 1000,
    ]..sort();
    var misses = 0;
    for (var i = 0; i < ordered.length; i++) {
      final frame = ordered[i];
      final late =
          i > 0 &&
          (frame.vsyncUs - ordered[i - 1].vsyncUs) / 1000 > 1000 / 60 + 1;
      if (late || math.max(frame.uiMs, frame.rasterMs) > 1000 / 60) misses++;
    }
    final span = ordered.last.vsyncUs - ordered.first.vsyncUs;
    return FrameMetrics(
      samples: frames.length,
      fps: windowSeconds != null && windowSeconds > 0
          ? frames.length / windowSeconds
          : span > 0
          ? (frames.length - 1) * 1000000 / span
          : 0,
      intervalP90: gaps.isEmpty ? 0 : percentile(gaps, .9),
      intervalMax: gaps.isEmpty ? 0 : gaps.last,
      cadenceMissPercent: gaps.isEmpty
          ? 0
          : gaps.where((gap) => gap > 1000 / 60 + 1).length * 100 / gaps.length,
      uiMean: mean(ui),
      uiP50: percentile(ui, .5),
      uiP90: percentile(ui, .9),
      uiMax: ui.last,
      rasterMean: mean(raster),
      rasterP90: percentile(raster, .9),
      rasterMax: raster.last,
      overBudgetPercent: misses * 100 / frames.length,
    );
  }

  /// Number of accepted engine timings.
  final int samples;

  /// Delivered frame rate estimated from consecutive vsync timestamps.
  final double fps;

  /// Time between engine frames; includes work outside the build phase.
  final double intervalP90;

  /// Longest observed frame gap.
  final double intervalMax;

  /// Gaps over the 60-Hz budget plus 1 ms scheduling tolerance.
  final double cadenceMissPercent;

  /// Mean UI duration.
  final double uiMean;

  /// Median UI duration.
  final double uiP50;

  /// 90th percentile UI duration.
  final double uiP90;

  /// Maximum UI duration.
  final double uiMax;

  /// Mean raster duration.
  final double rasterMean;

  /// 90th percentile raster duration.
  final double rasterP90;

  /// Maximum raster duration.
  final double rasterMax;

  /// Frames with UI/raster over 16.67 ms or a preceding gap over 17.67 ms.
  final double overBudgetPercent;

  /// Machine-readable result with units in every timing name.
  Map<String, Object> toJson() => {
    'samples': samples,
    'fps': fps,
    'frameIntervalP90Ms': intervalP90,
    'frameIntervalMaxMs': intervalMax,
    'cadenceOver17_67msPercent': cadenceMissPercent,
    'uiMeanMs': uiMean,
    'uiP50Ms': uiP50,
    'uiP90Ms': uiP90,
    'uiMaxMs': uiMax,
    'rasterMeanMs': rasterMean,
    'rasterP90Ms': rasterP90,
    'rasterMaxMs': rasterMax,
    'missedBudgetPercent': overBudgetPercent,
  };
}

/// Filters delayed timing batches by the selected session and measurement
/// window.
class TimingWindow {
  /// Data generation and chart construction settle before measurement.
  TimingWindow({this.warmup = const Duration(seconds: 2)});

  /// Excluded initial duration.
  final Duration warmup;

  /// First vsync of this run, assigned by the ticker.
  int? startUs;

  /// Last accepted vsync, set when the run ends.
  int? endUs;
  final List<FrameSample> _samples = [];

  /// Admit late-delivered frames only when their timestamps belong to this run.
  void add(FrameSample frame) {
    final start = startUs;
    if (start == null ||
        frame.vsyncUs < start + warmup.inMicroseconds ||
        (endUs != null && frame.vsyncUs >= endUs!)) {
      return;
    }
    _samples.add(frame);
  }

  /// Whole capture, after warmup.
  FrameMetrics get summary => FrameMetrics.fromSamples(
    _samples,
    windowSeconds: startUs != null && endUs != null
        ? (endUs! - startUs! - warmup.inMicroseconds) / 1000000
        : null,
  );

  /// Recent engine frames for live readouts.
  FrameMetrics get recent {
    if (_samples.isEmpty) return const FrameMetrics();
    final end = _samples.last.vsyncUs;
    return FrameMetrics.fromSamples(
      _samples.where((f) => f.vsyncUs >= end - 1500000).toList(),
    );
  }

  /// Bound storage in free-running mode; timed captures retain their full
  /// window.
  void trimLive() {
    if (_samples.isEmpty) return;
    final cutoff = _samples.last.vsyncUs - 2000000;
    _samples.removeWhere((f) => f.vsyncUs < cutoff);
  }
}
