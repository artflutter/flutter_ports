// Ported from Chart.js v4.6.1 src/types/color.d.ts (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.

/// The declaration of `src/types/color.d.ts` (Chart.js ADR 0003,
/// porting-flow.md 2.4).
///
/// color.d.ts:1 declares `Color = string | CanvasGradient | CanvasPattern`.
/// Paint options in the port use `ChartPaint`: a `SolidChartPaint` contains
/// a Flutter color, while `ChartGradient` and `ChartPattern` are paints
/// themselves (Chart.js ADR 0128). The renderer interprets the variant.
/// Shadow colors, palette entries and gradient stops remain Flutter colors.
// DIVERGES(chartjs): adapt-chart-paint-objects, no DOM gradient or pattern.
library;

export 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartGradient, ChartPattern, ChartShaderPaint;
