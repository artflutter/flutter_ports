// Ported from chartjs-chart-sankey v0.19.1 src/index.esm.ts (MIT, Jukka Kurkela).

/// Port of `src/index.esm.ts`: the module entry. It exports the controller,
/// the element and the public types, and registers nothing.
///
/// `src/index.ts`, the entry that registers the two components at its
/// import, has no Dart file: a Dart import runs no code (Sankey ADR 0002).
/// An app registers them once, before its first sankey chart, with
/// `Chart.register(sankeyRegisterables)` of the public library.
library;

export 'controller.dart' show SankeyController;
export 'flow.dart' show Flow;
export 'types.dart'
    show
        FromToElement,
        SankeyColorMode,
        SankeyDataPoint,
        SankeyLabelPosition,
        SankeyModeX,
        SankeyNode,
        SankeyNodeCallback,
        SankeyNodeGap,
        SankeyNodeLabelPosition,
        SankeyNodePaddingMode,
        SankeyOrientation,
        SankeyParsedCustom,
        SankeySize;
