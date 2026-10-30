// Original code, not ported from Chart.js: the export list of the typed API.

/// The typed API of Chart.js ADR 0052: the names that the app library
/// `lib/flutter_chartjs_port.dart` exports.
///
/// No name equals a type name of the Chart.js type files, a name of the
/// Flutter libraries or another name of the public libraries of the port
/// (Chart.js ADR 0052, section 8; `test/port/typed/names_test.dart`).
/// `lib/chartjs.dart` does not export the typed API.
library;

export 'package:flutter_chartjs_port/src/typed/axes.dart'
    show
        AxisGrid,
        AxisTicks,
        AxisTitle,
        CategoryAxis,
        ChartAxis,
        LinearAxis,
        LogarithmicAxis,
        RadialLinearAxis,
        TimeAxis,
        TimeSeriesAxis;
export 'package:flutter_chartjs_port/src/typed/callbacks.dart'
    show
        AxisTickInfo,
        ChartAnimationDetails,
        ChartContext,
        ChartEventDetails,
        ChartHit,
        ChartLegendEventDetails,
        ChartLegendItem,
        ChartScript,
        ChartTooltipItem;
export 'package:flutter_chartjs_port/src/typed/config.dart'
    show ChartConfig, ChartKind, IndexAxis;
export 'package:flutter_chartjs_port/src/typed/datasets.dart'
    show
        BarDataset,
        BubbleDataset,
        DataPoint,
        Dataset,
        DoughnutDataset,
        LineDataset,
        PieDataset,
        PolarAreaDataset,
        RadarDataset,
        ScatterDataset;
export 'package:flutter_chartjs_port/src/typed/groups.dart'
    show
        ChartAnimation,
        ChartInteraction,
        ChartLegend,
        ChartTitle,
        ChartTooltip;
export 'package:flutter_chartjs_port/src/typed/values.dart'
    show
        ChartAlign,
        ChartEasing,
        ChartFill,
        ChartInteractionMode,
        ChartLength,
        ChartPointStyle,
        ChartPosition;
