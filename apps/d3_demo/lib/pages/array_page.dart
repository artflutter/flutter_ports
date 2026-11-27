// Original code, not ported from D3: flutter_d3_array_port interactive demo.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_array_port/flutter_d3_array_port.dart' as d3;
import 'package:flutter_d3_scale_chromatic_port/flutter_d3_scale_chromatic_port.dart'
    as chromatic;
import 'package:material_ui/material_ui.dart';

enum _Distribution(final String label) {
  bimodal('Bimodal'),
  normal('Normal'),
  skewed('Right-skewed'),
  uniform('Uniform'),
}

enum _ThresholdRule(final String label) {
  sturges('Sturges'),
  scott('Scott'),
  freedmanDiaconis('Freedman-Diaconis'),
  custom('Custom'),
}

/// Interactive showcase of `flutter_d3_array_port`: live histogram/binning
/// explorer with Sturges/Scott/Freedman-Diaconis & custom bin count, live
/// box-plot/quantile/statistics readout with `fsum`/mean/median/deviation,
/// interactive `ticks`/`nice` axis-tick preview, and 1D/2D `blur` smoothing.
class const ArrayDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-array` demo page.
  this;

  @override
  State<ArrayDemoPage> createState() => _ArrayDemoPageState();
}

class _ArrayDemoPageState() extends State<ArrayDemoPage> {
  _Distribution _distribution = _Distribution.bimodal;
  _ThresholdRule _rule = _ThresholdRule.freedmanDiaconis;
  int _customBins = 12;
  int _sampleSeed = 7;

  // Ticks / nice explorer state.
  double _tickStart = -13.4;
  double _tickStop = 87.2;
  int _tickCount = 8;
  bool _applyNice = true;

  // 1D / 2D blur state.
  bool _blur2d = false;
  double _blurRx = 1.5;
  double _blurRy = 1.5;

  late List<double> _sample = _generateSample(_distribution, _sampleSeed);
  late final List<double> _signal1d = _generateSignal1d();
  late final Float64List _grid2d = _generateGrid2d();

  static const int _gridW = 24;
  static const int _gridH = 16;

  static List<double> _generateSample(_Distribution dist, int seed) {
    final rng = math.Random(seed * 9973 + dist.index * 31);
    double gaussian() {
      final u1 = math.max(1e-9, rng.nextDouble());
      final u2 = rng.nextDouble();
      return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
    }

    return List<double>.generate(240, (i) {
      return switch (dist) {
        _Distribution.bimodal =>
          i.isEven ? 34.0 + gaussian() * 8.5 : 70.0 + gaussian() * 9.5,
        _Distribution.normal => 50.0 + gaussian() * 14.0,
        _Distribution.skewed => 15.0 + math.exp(gaussian() * 0.65) * 18.0,
        _Distribution.uniform => 10.0 + rng.nextDouble() * 85.0,
      };
    }, growable: false);
  }

  static List<double> _generateSignal1d() {
    final rng = math.Random(42);
    return List<double>.generate(72, (i) {
      final t = i / 71.0;
      final base =
          50.0 +
          26.0 * math.sin(t * math.pi * 2.5) +
          12.0 * math.cos(t * math.pi * 6.0);
      final noise = (rng.nextDouble() - 0.5) * 28.0;
      final spike = (i == 22 || i == 50) ? 24.0 : 0.0;
      return base + noise + spike;
    }, growable: false);
  }

  static Float64List _generateGrid2d() {
    final out = Float64List(_gridW * _gridH);
    for (var y = 0; y < _gridH; ++y) {
      for (var x = 0; x < _gridW; ++x) {
        final dx = x - _gridW / 2.0;
        final dy = y - _gridH / 2.0;
        final dist = math.sqrt(dx * dx + dy * dy);
        final ring = (dist - 5.2).abs() < 1.1 ? 1.0 : 0.0;
        final center = dist < 1.8 ? 1.0 : 0.0;
        final checker = ((x ~/ 3 + y ~/ 3).isEven && x < 7 && y < 7)
            ? 0.75
            : 0.0;
        out[y * _gridW + x] = math.min(1, ring + center + checker);
      }
    }
    return out;
  }

  void _setDistribution(_Distribution dist) {
    setState(() {
      _distribution = dist;
      _sample = _generateSample(dist, _sampleSeed);
    });
  }

  void _resample() {
    setState(() {
      _sampleSeed += 1;
      _sample = _generateSample(_distribution, _sampleSeed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final binGen = switch (_rule) {
      _ThresholdRule.sturges => d3.bin<double>(
        thresholdsCount: d3.thresholdSturges,
      ),
      _ThresholdRule.scott => d3.bin<double>(
        thresholdsCount: d3.thresholdScott,
      ),
      _ThresholdRule.freedmanDiaconis => d3.bin<double>(
        thresholdsCount: d3.thresholdFreedmanDiaconis,
      ),
      _ThresholdRule.custom =>
        d3.bin<double>()..thresholdsCountConst(_customBins),
    };
    final bins = binGen(_sample);

    final ext = d3.extent(_sample)!;
    final sampleMin = ext.$1;
    final sampleMax = ext.$2;
    final q1 = d3.quantile(_sample, 0.25)!;
    final med = d3.median(_sample)!;
    final q3 = d3.quantile(_sample, 0.75)!;
    final avg = d3.mean(_sample)!;
    final sd = d3.deviation(_sample)!;
    final vr = d3.variance(_sample)!;
    final exactSum = d3.fsum(_sample);

    final sturgesCount = d3.thresholdSturges(_sample);
    final scottCount = d3.thresholdScott(_sample, sampleMin, sampleMax);
    final fdCount = d3.thresholdFreedmanDiaconis(_sample, sampleMin, sampleMax);

    // Classic Shewchuk fsum vs IEEE naive sum comparison.
    const cancellationDemo = <double>[1, 1e20, 1, -1e20];
    final naiveCancel = d3.sum(cancellationDemo);
    final exactCancel = d3.fsum(cancellationDemo);

    // Ticks / nice preview.
    final rawStart = math.min(_tickStart, _tickStop - 1.0);
    final rawStop = math.max(_tickStop, rawStart + 1.0);
    final niced = d3.nice(rawStart, rawStop, _tickCount);
    final dispStart = _applyNice ? niced.$1 : rawStart;
    final dispStop = _applyNice ? niced.$2 : rawStop;
    final tickVals = d3.ticks(dispStart, dispStop, _tickCount);
    final step = d3.tickStep(dispStart, dispStop, _tickCount);
    final inc = d3.tickIncrement(dispStart, dispStop, _tickCount);

    // Blur data.
    final blurred1d = d3.blur(List<double>.of(_signal1d), _blurRx);
    final blurred2dData = d3.Blur2Data(
      data: Float64List.fromList(_grid2d),
      width: _gridW,
      height: _gridH,
    );
    d3.blur2(blurred2dData, _blurRx, _blurRy);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Histograms, Quantile Statistics, Axis Ticks & Gaussian Blur',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pure Dart, fully statically typed port of d3-array '
          'v${d3.d3ArrayVersion}: zero dynamic, zero JS runtime — typed '
          'Bin<T>, Shewchuk fsum/Adder, Floyd-Rivest quickselect & quantiles, '
          'nice/ticks, and 1D/2D blur.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // 1. Histogram / Binning Explorer
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Histogram & Binning Explorer',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _resample,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Resample'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final dist in _Distribution.values)
                      ChoiceChip(
                        label: Text(dist.label),
                        selected: _distribution == dist,
                        onSelected: (_) => _setDistribution(dist),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final rule in _ThresholdRule.values)
                      FilterChip(
                        label: Text(rule.label),
                        selected: _rule == rule,
                        onSelected: (_) => setState(() => _rule = rule),
                      ),
                  ],
                ),
                if (_rule == _ThresholdRule.custom) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Target bins: $_customBins'),
                      Expanded(
                        child: Slider(
                          value: _customBins.toDouble(),
                          min: 3,
                          max: 36,
                          divisions: 33,
                          label: '$_customBins',
                          onChanged: (v) =>
                              setState(() => _customBins = v.round()),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _HistogramPainter(
                      bins: bins,
                      barColor: cs.primary,
                      axisColor: cs.outline,
                      labelColor: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${bins.length} bins · n = ${_sample.length} · domain '
                  '[${bins.first.x0.toStringAsFixed(1)}, '
                  '${bins.last.x1.toStringAsFixed(1)}] · '
                  'Sturges=$sturgesCount, Scott=$scottCount, FD=$fdCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Box-plot, Quantile & Statistics Readout
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Box-Plot, Quantiles & Exact fsum Readout',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 76,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _BoxPlotPainter(
                      minVal: sampleMin,
                      q1: q1,
                      median: med,
                      q3: q3,
                      maxVal: sampleMax,
                      mean: avg,
                      deviation: sd,
                      primary: cs.primary,
                      secondary: cs.tertiary,
                      outline: cs.outline,
                      labelColor: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatChip('fsum', exactSum.toStringAsFixed(2), cs),
                    _StatChip('mean', avg.toStringAsFixed(2), cs),
                    _StatChip('median', med.toStringAsFixed(2), cs),
                    _StatChip('deviation (σ)', sd.toStringAsFixed(2), cs),
                    _StatChip('variance (σ²)', vr.toStringAsFixed(2), cs),
                    _StatChip('IQR (Q3−Q1)', (q3 - q1).toStringAsFixed(2), cs),
                    _StatChip(
                      'extent',
                      '${sampleMin.toStringAsFixed(1)} .. '
                          '${sampleMax.toStringAsFixed(1)}',
                      cs,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Shewchuk precision check on [1, 1e20, 1, -1e20]: '
                  'naive sum = $naiveCancel, exact fsum = $exactCancel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Interactive ticks / nice Axis-Tick Preview
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Axis Ticks & nice() Domain Preview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('nice()'),
                        const SizedBox(width: 6),
                        Switch(
                          value: _applyNice,
                          onChanged: (v) => setState(() => _applyNice = v),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text('Start: ${_tickStart.toStringAsFixed(1)}'),
                    ),
                    Expanded(
                      child: Slider(
                        value: _tickStart,
                        min: -120,
                        max: 40,
                        onChanged: (v) => setState(() => _tickStart = v),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text('Stop: ${_tickStop.toStringAsFixed(1)}'),
                    ),
                    Expanded(
                      child: Slider(
                        value: _tickStop,
                        min: 45,
                        max: 240,
                        onChanged: (v) => setState(() => _tickStop = v),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(width: 110, child: Text('Count: $_tickCount')),
                    Expanded(
                      child: Slider(
                        value: _tickCount.toDouble(),
                        min: 2,
                        max: 20,
                        divisions: 18,
                        onChanged: (v) =>
                            setState(() => _tickCount = v.round()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 64,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TicksPainter(
                      start: dispStart,
                      stop: dispStop,
                      ticks: tickVals,
                      axisColor: cs.primary,
                      labelColor: cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Raw [${rawStart.toStringAsFixed(1)}, '
                  '${rawStop.toStringAsFixed(1)}] → nice '
                  '[${niced.$1.toStringAsFixed(1)}, '
                  '${niced.$2.toStringAsFixed(1)}] · '
                  '${tickVals.length} ticks · '
                  'step=${step.toStringAsPrecision(3)} · '
                  'increment=${inc.toStringAsPrecision(3)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. 1D / 2D Blur Smoothing Explorer
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '1D & 2D Gaussian Blur Smoothing',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('1D blur'),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('2D blur2'),
                        ),
                      ],
                      selected: <bool>{_blur2d},
                      onSelectionChanged: (s) =>
                          setState(() => _blur2d = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        _blur2d
                            ? 'rx: ${_blurRx.toStringAsFixed(2)}'
                            : 'Radius r: ${_blurRx.toStringAsFixed(2)}',
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _blurRx,
                        max: 6,
                        divisions: 24,
                        label: _blurRx.toStringAsFixed(2),
                        onChanged: (v) => setState(() => _blurRx = v),
                      ),
                    ),
                  ],
                ),
                if (_blur2d)
                  Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text('ry: ${_blurRy.toStringAsFixed(2)}'),
                      ),
                      Expanded(
                        child: Slider(
                          value: _blurRy,
                          max: 6,
                          divisions: 24,
                          label: _blurRy.toStringAsFixed(2),
                          onChanged: (v) => setState(() => _blurRy = v),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: _blur2d
                      ? CustomPaint(
                          painter: _Blur2Painter(
                            data: blurred2dData.data,
                            width: _gridW,
                            height: _gridH,
                          ),
                        )
                      : CustomPaint(
                          painter: _Blur1Painter(
                            raw: _signal1d,
                            smoothed: blurred1d,
                            rawColor: cs.outline.withValues(alpha: 0.6),
                            smoothColor: cs.primary,
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  _blur2d
                      ? '24×16 scalar field smoothed in-place via blur2() and '
                            'rendered with Viridis.'
                      : 'Raw noisy waveform (gray) vs 3-pass box-blur '
                            'approximation via blur(values, r).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
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

class const _StatChip(
  final String label,
  final String value,
  final ColorScheme cs,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _HistogramPainter({
  required final List<d3.Bin<double>> bins,
  required final Color barColor,
  required final Color axisColor,
  required final Color labelColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (bins.isEmpty) return;
    const padLeft = 12.0;
    const padRight = 12.0;
    const padTop = 18.0;
    const padBottom = 26.0;
    final plotW = size.width - padLeft - padRight;
    final plotH = size.height - padTop - padBottom;
    if (plotW <= 0 || plotH <= 0) return;

    final maxCount = d3.maxBy(bins, (b) => b.length) ?? 1;
    final xMin = bins.first.x0;
    final xMax = bins.last.x1;
    final span = xMax > xMin ? xMax - xMin : 1.0;

    final barPaint = Paint()..color = barColor.withValues(alpha: 0.85);
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    for (final b in bins) {
      final x0 = padLeft + (b.x0 - xMin) / span * plotW;
      final x1 = padLeft + (b.x1 - xMin) / span * plotW;
      final barH = maxCount > 0 ? (b.length / maxCount) * plotH : 0.0;
      final rect = Rect.fromLTRB(
        x0 + 1.0,
        padTop + plotH - barH,
        math.max(x0 + 2.0, x1 - 1.0),
        padTop + plotH,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        barPaint,
      );
    }

    final baseY = padTop + plotH;
    canvas.drawLine(
      Offset(padLeft, baseY),
      Offset(padLeft + plotW, baseY),
      axisPaint,
    );

    final axisTicks = d3.ticks(xMin, xMax, 6);
    for (final t in axisTicks) {
      final x = padLeft + (t - xMin) / span * plotW;
      canvas.drawLine(Offset(x, baseY), Offset(x, baseY + 5), axisPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: t == t.roundToDouble()
              ? t.round().toString()
              : t.toStringAsFixed(1),
          style: TextStyle(fontSize: 11, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, baseY + 7));
    }
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter oldDelegate) =>
      oldDelegate.bins != bins || oldDelegate.barColor != barColor;
}

class _BoxPlotPainter({
  required final double minVal,
  required final double q1,
  required final double median,
  required final double q3,
  required final double maxVal,
  required final double mean,
  required final double deviation,
  required final Color primary,
  required final Color secondary,
  required final Color outline,
  required final Color labelColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const padX = 18.0;
    final w = size.width - padX * 2;
    if (w <= 0) return;
    final span = maxVal > minVal ? maxVal - minVal : 1.0;
    double xOf(double v) => padX + ((v - minVal) / span).clamp(0.0, 1.0) * w;

    final cy = size.height * 0.42;
    final linePaint = Paint()
      ..color = outline
      ..strokeWidth = 2;

    // ±1σ band
    final sdBand = Rect.fromLTRB(
      xOf(mean - deviation),
      cy - 18,
      xOf(mean + deviation),
      cy + 18,
    );
    // IQR Box
    final boxRect = Rect.fromLTRB(xOf(q1), cy - 14, xOf(q3), cy + 14);
    // Mean diamond
    final mx = xOf(mean);
    final diamond = Path()
      ..moveTo(mx, cy - 6)
      ..lineTo(mx + 6, cy)
      ..lineTo(mx, cy + 6)
      ..lineTo(mx - 6, cy)
      ..close();

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(sdBand, const Radius.circular(6)),
        Paint()..color = secondary.withValues(alpha: 0.16),
      )
      ..drawLine(Offset(xOf(minVal), cy), Offset(xOf(maxVal), cy), linePaint)
      ..drawLine(
        Offset(xOf(minVal), cy - 10),
        Offset(xOf(minVal), cy + 10),
        linePaint,
      )
      ..drawLine(
        Offset(xOf(maxVal), cy - 10),
        Offset(xOf(maxVal), cy + 10),
        linePaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(boxRect, const Radius.circular(4)),
        Paint()..color = primary.withValues(alpha: 0.25),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(boxRect, const Radius.circular(4)),
        Paint()
          ..color = primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      )
      ..drawLine(
        Offset(xOf(median), cy - 14),
        Offset(xOf(median), cy + 14),
        Paint()
          ..color = primary
          ..strokeWidth = 3,
      )
      ..drawPath(diamond, Paint()..color = secondary);

    for (final (lbl, val) in <(String, double)>[
      ('min', minVal),
      ('Q1', q1),
      ('med', median),
      ('Q3', q3),
      ('max', maxVal),
    ]) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$lbl ${val.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 10, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final tx = (xOf(val) - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(tx, cy + 22));
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPlotPainter oldDelegate) => true;
}

class _TicksPainter({
  required final double start,
  required final double stop,
  required final List<double> ticks,
  required final Color axisColor,
  required final Color labelColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const padX = 20.0;
    final w = size.width - padX * 2;
    if (w <= 0) return;
    final span = stop > start ? stop - start : 1.0;
    final y = size.height * 0.42;

    final paint = Paint()
      ..color = axisColor
      ..strokeWidth = 2;
    canvas.drawLine(Offset(padX, y), Offset(padX + w, y), paint);

    for (final t in ticks) {
      final x = padX + ((t - start) / span).clamp(0.0, 1.0) * w;
      canvas.drawLine(Offset(x, y - 6), Offset(x, y + 6), paint);
      final tp = TextPainter(
        text: TextSpan(
          text: t == t.roundToDouble()
              ? t.round().toString()
              : t.toStringAsFixed(1),
          style: TextStyle(fontSize: 11, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y + 10));
    }
  }

  @override
  bool shouldRepaint(covariant _TicksPainter oldDelegate) => true;
}

class _Blur1Painter({
  required final List<double> raw,
  required final List<double> smoothed,
  required final Color rawColor,
  required final Color smoothColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (raw.length < 2) return;
    final ext = d3.extent(raw)!;
    final lo = ext.$1 - 4.0;
    final hi = ext.$2 + 4.0;
    final span = hi > lo ? hi - lo : 1.0;

    Path buildPath(List<double> ys) {
      final p = Path();
      for (var i = 0; i < ys.length; ++i) {
        final x = i / (ys.length - 1) * size.width;
        final y = size.height - ((ys[i] - lo) / span) * size.height;
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      return p;
    }

    canvas
      ..drawPath(
        buildPath(raw),
        Paint()
          ..color = rawColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      )
      ..drawPath(
        buildPath(smoothed),
        Paint()
          ..color = smoothColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(covariant _Blur1Painter oldDelegate) => true;
}

class _Blur2Painter({
  required final List<double> data,
  required final int width,
  required final int height,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / width;
    final cellH = size.height / height;
    final paint = Paint();
    for (var y = 0; y < height; ++y) {
      for (var x = 0; x < width; ++x) {
        final v = data[y * width + x].clamp(0.0, 1.0);
        final rgb = chromatic.interpolateViridis(v).rgb();
        paint.color = Color.fromARGB(
          255,
          rgb.r.round().clamp(0, 255),
          rgb.g.round().clamp(0, 255),
          rgb.b.round().clamp(0, 255),
        );
        canvas.drawRect(
          Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.5, cellH + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Blur2Painter oldDelegate) => true;
}
