// Original code, not ported from D3: flutter_d3_random_port interactive demo.

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart' as d3_array;
import 'package:flutter_d3_random_port/d3_random.dart' as d3_random;
import 'package:material_ui/material_ui.dart';

enum _DistKind(final String label, final String apiName) {
  normal('Normal', 'randomNormal'),
  logNormal('LogNormal', 'randomLogNormal'),
  exponential('Exponential', 'randomExponential'),
  pareto('Pareto', 'randomPareto'),
  gamma('Gamma', 'randomGamma'),
  beta('Beta', 'randomBeta'),
  weibull('Weibull', 'randomWeibull'),
  cauchy('Cauchy', 'randomCauchy'),
  binomial('Binomial', 'randomBinomial'),
  poisson('Poisson', 'randomPoisson'),
  bates('Bates', 'randomBates'),
  irwinHall('IrwinHall', 'randomIrwinHall');

  (String, double, double, double) get param1Spec => switch (this) {
    _DistKind.normal => ('Mean μ', -10, 10, 0),
    _DistKind.logNormal => ('Log-mean μ', -1, 2, 0),
    _DistKind.exponential => ('Rate λ', 0.1, 4, 1),
    _DistKind.pareto => ('Shape α', 1.5, 10, 3),
    _DistKind.gamma => ('Shape k', 0.5, 12, 3),
    _DistKind.beta => ('Shape α', 0.3, 8, 2),
    _DistKind.weibull => ('Shape k', -4, 6, 2),
    _DistKind.cauchy => ('Location a', -5, 5, 0),
    _DistKind.binomial => ('Trials n', 5, 100, 30),
    _DistKind.poisson => ('Mean λ', 0.5, 40, 8),
    _DistKind.bates => ('Count n', 1, 12, 4),
    _DistKind.irwinHall => ('Count n', 1, 12, 4),
  };

  (String, double, double, double)? get param2Spec => switch (this) {
    _DistKind.normal => ('Std dev σ', 0.2, 5, 1),
    _DistKind.logNormal => ('Log-dev σ', 0.1, 1.2, 0.5),
    _DistKind.gamma => ('Scale θ', 0.2, 4, 1.5),
    _DistKind.beta => ('Shape β', 0.3, 8, 5),
    _DistKind.weibull => ('Scale b', 0.5, 4, 1),
    _DistKind.cauchy => ('Scale b', 0.2, 3, 1),
    _DistKind.binomial => ('Probability p', 0.05, 0.95, 0.4),
    _ => null,
  };

  bool get isDiscrete =>
      this == _DistKind.binomial || this == _DistKind.poisson;

  bool get isHeavyTailed =>
      this == _DistKind.cauchy ||
      this == _DistKind.pareto ||
      this == _DistKind.logNormal ||
      this == _DistKind.weibull;
}

/// Interactive showcase of `flutter_d3_random_port`: live distribution sampler
/// across 12 probability distributions with parameter sliders, sample-size and
/// LCG seed controls, real-time histogram via `flutter_d3_array_port` `bin`,
/// and live mean/median/deviation summary readouts.
class const RandomDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-random` demo page.
  this;

  @override
  State<RandomDemoPage> createState() => _RandomDemoPageState();
}

class _RandomDemoPageState() extends State<RandomDemoPage> {
  _DistKind _dist = _DistKind.normal;
  double _p1 = 0;
  double _p2 = 1;
  int _sampleCount = 4000;
  double _seed = 0.42;

  void _selectDist(_DistKind kind) {
    setState(() {
      _dist = kind;
      _p1 = kind.param1Spec.$4;
      _p2 = kind.param2Spec?.$4 ?? 1;
    });
  }

  List<double> _drawSamples() {
    final src = d3_random.randomLcg(_seed);
    return switch (_dist) {
      _DistKind.normal =>
        d3_random.randomNormal.source(src).sample(_sampleCount, _p1, _p2),
      _DistKind.logNormal =>
        d3_random.randomLogNormal.source(src).sample(_sampleCount, _p1, _p2),
      _DistKind.exponential =>
        d3_random.randomExponential.source(src).sample(_sampleCount, _p1),
      _DistKind.pareto =>
        d3_random.randomPareto.source(src).sample(_sampleCount, _p1),
      _DistKind.gamma =>
        d3_random.randomGamma.source(src).sample(_sampleCount, _p1, _p2),
      _DistKind.beta =>
        d3_random.randomBeta.source(src).sample(_sampleCount, _p1, _p2),
      _DistKind.weibull =>
        d3_random.randomWeibull.source(src).sample(_sampleCount, _p1, 0, _p2),
      _DistKind.cauchy =>
        d3_random.randomCauchy.source(src).sample(_sampleCount, _p1, _p2),
      _DistKind.binomial => [
        for (final v
            in d3_random.randomBinomial
                .source(src)
                .sample(_sampleCount, _p1.round(), _p2))
          v.toDouble(),
      ],
      _DistKind.poisson => [
        for (final v
            in d3_random.randomPoisson.source(src).sample(_sampleCount, _p1))
          v.toDouble(),
      ],
      _DistKind.bates =>
        d3_random.randomBates.source(src).sample(_sampleCount, _p1),
      _DistKind.irwinHall =>
        d3_random.randomIrwinHall.source(src).sample(_sampleCount, _p1),
    };
  }

  String _codeSnippet() {
    final seedStr = _seed.toStringAsFixed(2);
    final p1Str = _dist == _DistKind.binomial
        ? '${_p1.round()}'
        : _p1.toStringAsFixed(2);
    final p2Spec = _dist.param2Spec;
    final args = switch (_dist) {
      _DistKind.weibull => '$p1Str, 0, ${_p2.toStringAsFixed(2)}',
      _ when p2Spec != null => '$p1Str, ${_p2.toStringAsFixed(2)}',
      _ => p1Str,
    };
    return '${_dist.apiName}.source(randomLcg($seedStr))($args)';
  }

  String _fmtStat(double? v) {
    if (v == null || v.isNaN) return '—';
    if (!v.isFinite) return v.isNegative ? '-∞' : '∞';
    if (v.abs() >= 1000) return v.toStringAsFixed(1);
    return v.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final samples = _drawSamples();
    final finiteSamples = [
      for (final v in samples)
        if (v.isFinite) v,
    ];
    final sampleMean = d3_array.mean(finiteSamples);
    final sampleMedian = d3_array.median(finiteSamples);
    final sampleDev = d3_array.deviation(finiteSamples);

    // For heavy-tailed distributions, clip the histogram domain to [q02, q98]
    // so extreme outliers do not collapse the central density into one bin.
    final sorted = List<double>.of(finiteSamples)..sort();
    double domainMin;
    double domainMax;
    if (sorted.isEmpty) {
      domainMin = 0;
      domainMax = 1;
    } else if (_dist.isHeavyTailed && sorted.length >= 20) {
      domainMin = d3_array.quantileSorted(sorted, 0.02) ?? sorted.first;
      domainMax = d3_array.quantileSorted(sorted, 0.98) ?? sorted.last;
      if (domainMax <= domainMin) {
        domainMin = sorted.first;
        domainMax = sorted.last;
      }
    } else {
      domainMin = sorted.first;
      domainMax = sorted.last;
    }
    if (domainMax == domainMin) {
      domainMin -= 0.5;
      domainMax += 0.5;
    }

    final clipped = [
      for (final v in finiteSamples)
        if (v >= domainMin && v <= domainMax) v,
    ];
    final binner = d3_array.bin<double>()
      ..domainConst(domainMin, domainMax)
      ..thresholdsCountConst(28);
    final bins = binner(clipped);

    final (p1Label, p1Min, p1Max, _) = _dist.param1Spec;
    final p2Spec = _dist.param2Spec;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Probability Distributions, Seeded LCG & Live Histogram '
                'Sampler',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Sample any of 12 distributions backed by bit-exact '
                'randomLcg(seed) and inspect the live d3-array bin histogram '
                'and summary statistics.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distribution',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final kind in _DistKind.values)
                            ChoiceChip(
                              label: Text(kind.label),
                              selected: _dist == kind,
                              onSelected: (_) => _selectDist(kind),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 24,
                        runSpacing: 8,
                        children: [
                          SizedBox(
                            width: 300,
                            child: _LabeledSlider(
                              label: p1Label,
                              valueText: _dist == _DistKind.binomial
                                  ? '${_p1.round()}'
                                  : _p1.toStringAsFixed(2),
                              value: _p1.clamp(p1Min, p1Max),
                              min: p1Min,
                              max: p1Max,
                              divisions: _dist == _DistKind.binomial
                                  ? (p1Max - p1Min).round()
                                  : 100,
                              onChanged: (v) => setState(() => _p1 = v),
                            ),
                          ),
                          if (p2Spec != null)
                            SizedBox(
                              width: 300,
                              child: _LabeledSlider(
                                label: p2Spec.$1,
                                valueText: _p2.toStringAsFixed(2),
                                value: _p2.clamp(p2Spec.$2, p2Spec.$3),
                                min: p2Spec.$2,
                                max: p2Spec.$3,
                                divisions: 100,
                                onChanged: (v) => setState(() => _p2 = v),
                              ),
                            ),
                          SizedBox(
                            width: 300,
                            child: _LabeledSlider(
                              label: 'Samples',
                              valueText: '$_sampleCount',
                              value: _sampleCount.toDouble(),
                              min: 500,
                              max: 10000,
                              divisions: 19,
                              onChanged: (v) =>
                                  setState(() => _sampleCount = v.round()),
                            ),
                          ),
                          SizedBox(
                            width: 340,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _LabeledSlider(
                                    label: 'LCG seed',
                                    valueText: _seed.toStringAsFixed(2),
                                    value: _seed,
                                    min: 0,
                                    max: 0.99,
                                    divisions: 99,
                                    onChanged: (v) => setState(() => _seed = v),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonal(
                                  onPressed: () {
                                    setState(() {
                                      _seed =
                                          ((_seed * 100).round() + 17) %
                                          100 /
                                          100.0;
                                    });
                                  },
                                  child: const Text('Reseed'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(label: 'Mean', value: _fmtStat(sampleMean)),
                  _StatCard(label: 'Median', value: _fmtStat(sampleMedian)),
                  _StatCard(label: 'Std dev', value: _fmtStat(sampleDev)),
                  _StatCard(label: 'Bins', value: '${bins.length}'),
                  _StatCard(
                    label: 'Type',
                    value: _dist.isDiscrete ? 'int (discrete)' : 'double',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_dist.label} Histogram (n = $_sampleCount)',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_dist.isHeavyTailed)
                            Text(
                              'View clipped to 2nd–98th percentile',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 280,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _HistogramPainter(
                            bins: bins,
                            domainMin: domainMin,
                            domainMax: domainMax,
                            sampleMean: sampleMean,
                            sampleMedian: sampleMedian,
                            barColor: cs.primary,
                            meanColor: cs.tertiary,
                            medianColor: cs.secondary,
                            gridColor: cs.outlineVariant,
                            textColor: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _codeSnippet(),
                          style: tt.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
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

class const _LabeledSlider({
  required final String label,
  required final String valueText,
  required final double value,
  required final double min,
  required final double max,
  required final int divisions,
  required final ValueChanged<double> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: $valueText',
          style: tt.labelLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class const _StatCard({
  required final String label,
  required final String value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistogramPainter({
  required final List<d3_array.Bin<double>> bins,
  required final double domainMin,
  required final double domainMax,
  required final double? sampleMean,
  required final double? sampleMedian,
  required final Color barColor,
  required final Color meanColor,
  required final Color medianColor,
  required final Color gridColor,
  required final Color textColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const padLeft = 44.0;
    const padRight = 16.0;
    const padTop = 14.0;
    const padBottom = 28.0;
    final plotW = math.max(1, size.width - padLeft - padRight);
    final plotH = math.max(1, size.height - padTop - padBottom);

    var maxCount = 1;
    for (final b in bins) {
      if (b.length > maxCount) maxCount = b.length;
    }

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.45)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; ++i) {
      final y = padTop + plotH * (1.0 - i / 4.0);
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(padLeft + plotW, y),
        gridPaint,
      );
      final label = '${(maxCount * i / 4).round()}';
      _drawText(
        canvas,
        label,
        Offset(padLeft - 6, y - 6),
        textColor,
        alignRight: true,
      );
    }

    final span = math.max(1e-12, domainMax - domainMin);
    double xOf(double v) => padLeft + ((v - domainMin) / span) * plotW;

    final barPaint = Paint()..color = barColor.withValues(alpha: 0.82);
    for (final b in bins) {
      final x0 = xOf(b.x0);
      final x1 = xOf(b.x1);
      final h = (b.length / maxCount) * plotH;
      final left = x0 + 1;
      final right = math.max(left + 1, x1 - 1);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, padTop + plotH - h, right, padTop + plotH),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(rect, barPaint);
    }

    void drawMarker(double? value, Color color, String label, double dy) {
      if (value == null || !value.isFinite) return;
      if (value < domainMin || value > domainMax) return;
      final x = xOf(value);
      final p = Paint()
        ..color = color
        ..strokeWidth = 2;
      canvas.drawLine(Offset(x, padTop), Offset(x, padTop + plotH), p);
      _drawText(canvas, label, Offset(x + 4, padTop + dy), color);
    }

    drawMarker(sampleMean, meanColor, 'μ', 2);
    drawMarker(sampleMedian, medianColor, 'med', 16);

    for (final tick in d3_array.ticks(domainMin, domainMax, 6)) {
      final x = xOf(tick);
      if (x < padLeft - 4 || x > padLeft + plotW + 4) continue;
      final label = tick.abs() >= 100
          ? tick.toStringAsFixed(0)
          : tick.toStringAsFixed(1);
      _drawText(canvas, label, Offset(x - 14, padTop + plotH + 6), textColor);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color, {
    bool alignRight = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight ? offset.dx - tp.width : offset.dx;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter oldDelegate) =>
      oldDelegate.bins != bins ||
      oldDelegate.domainMin != domainMin ||
      oldDelegate.domainMax != domainMax ||
      oldDelegate.barColor != barColor;
}
