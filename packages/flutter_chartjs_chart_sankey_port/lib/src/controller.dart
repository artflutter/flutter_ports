// Ported from chartjs-chart-sankey v0.19.1 src/controller.ts (MIT, Jukka Kurkela).

/// Port of `src/controller.ts`: the dataset controller of the `sankey`
/// charts.
///
/// - The controller extends the `DatasetController` of the host and uses
///   only the public libraries of the host (ADR 0009).
/// - A parsed item is a `ParsedItem` of the host with `x`, `y` and a
///   [SankeyParsedCustom] as its `custom` (row `adapt-sankey-parsed-item`).
/// - The static members `defaults`, `overrides` and `descriptors` are Maps.
///   Each option that the host holds as a Dart object has that object: the
///   interaction mode, the easing, the padding, the bounds of a scale, the
///   colors and the tooltip callbacks (row `adapt-sankey-native-defaults`).
/// - [SankeyController.jsClass] is the class as a value (Chart.js ADR
///   0020): the registry of the host takes it.
library;

import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
import 'package:flutter_chartjs_chart_sankey_port/src/flow.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/labels.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/lib/core.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/lib/helpers.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/lib/layout.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/types.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show
        ChartArea,
        ChartClip,
        ChartMeta,
        ChartPaint,
        DatasetController,
        Element,
        JsClass,
        NearestInteractionMode,
        ParsedItem,
        Scale,
        ScaleBounds,
        TooltipCallbacks,
        TooltipItem,
        TooltipModel,
        Undefined,
        XAxis,
        YAxis,
        controllerArgs,
        undefined;
import 'package:flutter_chartjs_port/helpers.dart'
    show isNullOrUndef, toFont, valueOrDefault;
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsGet, jsNumberToString, jsToNumber, jsTruthy;

const ChartPaint _black = ChartPaint.solid(Color(0xFF000000));
const ChartPaint _transparent = ChartPaint.solid(Color(0x00000000));

/// controller.ts:22 `nodeX`.
double _nodeX(SankeyNode node) => node.x ?? 0;

/// controller.ts:26 `nodeY`.
double _nodeY(SankeyNode node) => node.y ?? 0;

/// controller.ts:30 `getNodeSize`.
double _getNodeSize(SankeyNode node, SankeySize size) => nodeSizeOf(node, size);

/// controller.ts:34 `getAutoLabelPosition`.
SankeyLabelPosition _getAutoLabelPosition(
  double x,
  double y,
  ChartArea chartArea,
  SankeyOrientation orientation,
) {
  if (orientation == SankeyOrientation.vertical) {
    return y < (chartArea.top + chartArea.bottom) / 2
        ? SankeyLabelPosition.bottom
        : SankeyLabelPosition.top;
  }
  return x < (chartArea.left + chartArea.right) / 2
      ? SankeyLabelPosition.right
      : SankeyLabelPosition.left;
}

/// controller.ts:46 `getAddY`: the offset of [flow] from the start of its
/// node, or 0 for no flow.
///
/// Upstream scans the flow list of the node for the key and the index of a
/// data point, for each data point. Each list has one flow for each data
/// index of its node, with the key of that data point. Thus the flow at the
/// index ([_flowsByIndex]) is the result of the scan.
// DIVERGES(sankey): adapt-sankey-flow-by-index, no scan for each data point.
double _getAddY(FromToElement? flow) => flow?.addY ?? 0;

/// The flow of each data index: the flow out of its source node
/// (`from.to`), and the flow into its target node (`to.from`).
({List<FromToElement?> into, List<FromToElement?> out}) _flowsByIndex(
  Iterable<SankeyNode> nodes,
  int length,
) {
  final out = List<FromToElement?>.filled(length, null);
  final into = List<FromToElement?>.filled(length, null);
  for (final node in nodes) {
    for (final flow in node.to) {
      out[flow.index] = flow;
    }
    for (final flow in node.from) {
      into[flow.index] = flow;
    }
  }
  return (into: into, out: out);
}

/// `scale.parse(value, index) as number`.
double _parse(Scale scale, double value, int index) =>
    jsToNumber(scale.parse(value, index));

/// controller.ts:55 `parseFlow`.
// DIVERGES(sankey): adapt-sankey-parsed-item, a ParsedItem of the host.
ParsedItem _parseFlow(
  SankeyNode from,
  SankeyNode to,
  double fromY,
  double toY,
  double flow,
  int index,
  Scale xScale,
  Scale yScale,
  SankeyOrientation orientation,
) {
  if (orientation == SankeyOrientation.vertical) {
    return ParsedItem.of(
        const XAxis(),
        _parse(xScale, fromY, index),
        const YAxis(),
        _parse(yScale, _nodeX(from), index),
      )
      ..custom = SankeyParsedCustom(
        flow: flow,
        from: from,
        height: _parse(xScale, flow, index),
        to: to,
        x: _parse(xScale, toY, index),
        y: _parse(yScale, _nodeX(to), index),
      );
  }
  return ParsedItem.of(
      const XAxis(),
      _parse(xScale, _nodeX(from), index),
      const YAxis(),
      _parse(yScale, fromY, index),
    )
    ..custom = SankeyParsedCustom(
      flow: flow,
      from: from,
      height: _parse(yScale, flow, index),
      to: to,
      x: _parse(xScale, _nodeX(to), index),
      y: _parse(yScale, toY, index),
    );
}

/// controller.ts:94 `getFlowElementProperties`: the properties of a flow
/// element, in the key order of upstream.
Map<String, Object?> _getFlowElementProperties(
  ParsedItem parsed,
  Scale xScale,
  Scale yScale,
  double maxColumn,
  double nodeWidth,
  double columnPadding,
  double borderSpace,
  SankeyOrientation orientation,
) {
  final custom = parsed.custom! as SankeyParsedCustom;
  final parsedX = jsToNumber(parsed.x);
  final parsedY = jsToNumber(parsed.y);
  final x = xScale.getPixelForValue(parsedX);
  final y = yScale.getPixelForValue(parsedY);
  if (orientation == SankeyOrientation.vertical) {
    return {
      'flow': custom.flow,
      'from': custom.from,
      'height': 0.0,
      'to': custom.to,
      'width': (xScale.getPixelForValue(parsedX + custom.height) - x).abs(),
      'x': x,
      'x2': xScale.getPixelForValue(custom.x),
      'y':
          _getColumnPixel(yScale, parsedY, maxColumn, columnPadding) +
          nodeWidth +
          borderSpace,
      'y2':
          _getColumnPixel(yScale, custom.y, maxColumn, columnPadding) -
          borderSpace,
    };
  }
  return {
    'flow': custom.flow,
    'from': custom.from,
    'height': (yScale.getPixelForValue(parsedY + custom.height) - y).abs(),
    'to': custom.to,
    'width': 0.0,
    'x':
        _getColumnPixel(xScale, parsedX, maxColumn, columnPadding) +
        nodeWidth +
        borderSpace,
    'x2':
        _getColumnPixel(xScale, custom.x, maxColumn, columnPadding) -
        borderSpace,
    'y': y,
    'y2': yScale.getPixelForValue(custom.y),
  };
}

/// controller.ts:133 `getColumnPixel`.
double _getColumnPixel(
  Scale scale,
  double value,
  double maxColumn,
  double padding,
) {
  final pixel = scale.getPixelForValue(value);
  return maxColumn != 0 && !maxColumn.isNaN
      ? pixel - (value / maxColumn) * padding
      : pixel;
}

/// controller.ts:138 `getColumnPadding`.
///
/// Upstream types its third parameter by the members that it reads:
/// `{chartArea: {bottom, right}, height, width}`. The port gives the three
/// values.
double _getColumnPadding(
  double nodeWidth,
  SankeyOrientation orientation,
  ChartArea chartArea,
  double chartWidth,
  double chartHeight,
) {
  final trailingSpace = orientation == SankeyOrientation.vertical
      ? chartHeight - chartArea.bottom
      : chartWidth - chartArea.right;
  return math.max(0, nodeWidth + 3 - trailingSpace);
}

/// controller.ts:159 `getNodeRect`.
///
/// The node's drawn rectangle. Along the flow axis, the natural (flow-space)
/// span is stretched -- never shrunk -- to at least `minSize` CSS pixels,
/// growing symmetrically around the node's real center so half the stretch
/// lands above/left and half below/right. `minSize` only affects the drawn
/// rectangle here: the flows attached to the node keep their own exact pixel
/// positions (computed independently in `getFlowElementProperties`), so a
/// stretched node bar does not move or resize any data.
({double height, double width, double x, double y}) _getNodeRect(
  SankeyNode node,
  double size,
  Scale xScale,
  Scale yScale,
  double maxColumn,
  double nodeWidth,
  double columnPadding,
  SankeyOrientation orientation,
  double minSize,
) {
  if (orientation == SankeyOrientation.vertical) {
    final x1 = xScale.getPixelForValue(_nodeY(node));
    final x2 = xScale.getPixelForValue(_nodeY(node) + size);
    final left = math.min(x1, x2);
    final naturalWidth = (x2 - x1).abs();
    final width = math.max(naturalWidth, minSize);
    return (
      height: nodeWidth,
      width: width,
      x: left - (width - naturalWidth) / 2,
      y: _getColumnPixel(yScale, _nodeX(node), maxColumn, columnPadding),
    );
  }
  final y1 = yScale.getPixelForValue(_nodeY(node));
  final y2 = yScale.getPixelForValue(_nodeY(node) + size);
  final top = math.min(y1, y2);
  final naturalHeight = (y2 - y1).abs();
  final height = math.max(naturalHeight, minSize);
  return (
    height: height,
    width: nodeWidth,
    x: _getColumnPixel(xScale, _nodeX(node), maxColumn, columnPadding),
    y: top - (height - naturalHeight) / 2,
  );
}

/// controller.ts:196 `resolveNodeGap`.
///
/// The gap of a node is a number or a [SankeyNodeGap]. A gap object of
/// another class is not a gap: a debug build stops on it.
NodeGap _resolveNodeGap(Object? option, SankeyNode node) {
  final resolved =
      resolveNodeOption<Object>(isNullOrUndef(option) ? 10 : option, node) ??
      10;
  if (resolved is num) {
    return (after: resolved.toDouble(), before: resolved.toDouble());
  }
  assert(
    resolved is SankeyNodeGap,
    'A node gap is a number or a SankeyNodeGap, not ${resolved.runtimeType}.',
  );
  if (resolved is! SankeyNodeGap) return (after: 10, before: 10);
  return (after: resolved.after ?? 10, before: resolved.before ?? 10);
}

/// controller.ts:207 `resolveNodeMinSize`.
double _resolveNodeMinSize(Object? option, SankeyNode node) =>
    resolveNodeOption<num>(
      isNullOrUndef(option) ? 0 : option,
      node,
    )?.toDouble() ??
    0;

/// `value = fallback` of a destructuring: [fallback] for `undefined`, else
/// the `ToNumber` of [value].
double _numberOr(Object? value, double fallback) =>
    value is Undefined ? fallback : jsToNumber(value);

/// controller.ts:214 `resolveNodeLabelStyle`.
({
  Object? backgroundColor,
  double borderRadius,
  Object? color,
  bool display,
  Object? font,
  double padding,
  SankeyLabelPosition position,
})
_resolveNodeLabelStyle(
  SankeyControllerDatasetOptions options,
  SankeyNode node,
) {
  final nodeLabels = options.nodeLabels ?? const SankeyNodeLabelsOptions({});
  final datasetColor = options.color;
  return (
    backgroundColor: resolveNodeOption<Object>(
      nodeLabels.backgroundColor,
      node,
    ),
    borderRadius: _numberOr(nodeLabels.borderRadius, 0),
    color:
        resolveNodeOption<Object>(nodeLabels.color, node) ??
        (isNullOrUndef(datasetColor) ? _black : datasetColor),
    display: resolveNodeOption<bool>(nodeLabels.display, node) ?? true,
    font: nodeLabels.font,
    padding: _numberOr(nodeLabels.padding, 4),
    position:
        resolveNodeOption<SankeyLabelPosition>(nodeLabels.position, node) ??
        SankeyLabelPosition.auto,
  );
}

// Node-scoped options resolve per node (value | Record | (node) => value), so
// Chart.js must not call their function form with its own scriptable context.
const Set<String> _nodeScopedOptions = {'nodeMinSize', 'nodePadding'};

/// The hover colors of a flow. Their defaults are functions of the resolved
/// colors of the flow (flow.ts:148-149).
///
/// With upstream, each update calls both functions for each flow, and a
/// function value keeps the options of the flows out of the shared cache of
/// the host. No code reads the two keys by their own names: the active mode
/// reads them as `colorFrom` and `colorTo` through its hover prefix, and
/// those names are scriptable. Thus the two keys are not scriptable: an
/// update calls no hover function, and the options of the flows of a
/// dataset with plain values resolve one time. In the default mode,
/// `hoverColorFrom` and `hoverColorTo` of the options of a flow hold the
/// function.
// DIVERGES(sankey): adapt-sankey-hover-color-keys, not scriptable by name.
const Set<String> _hoverColorOptions = {'hoverColorFrom', 'hoverColorTo'};

/// The axis of the progress animation: `ctx.dataset.orientation ===
/// 'vertical' ? 'y' : 'x'` (controller.ts:264-270).
bool _verticalDataset(Object? ctx) =>
    jsGet(jsGet(ctx, 'dataset'), 'orientation') == SankeyOrientation.vertical;

/// controller.ts:262 the `delay` of the animation `progress`.
Object? _progressDelay(Object? ctx) {
  if (jsGet(ctx, 'type') != 'data') return undefined;
  final parsed = jsGet(ctx, 'parsed')! as ParsedItem;
  final start = jsToNumber(_verticalDataset(ctx) ? parsed.y : parsed.x);
  return start * 500 + jsToNumber(jsGet(ctx, 'dataIndex')) * 20;
}

/// controller.ts:267 the `duration` of the animation `progress`.
Object? _progressDuration(Object? ctx) {
  if (jsGet(ctx, 'type') != 'data') return undefined;
  final parsed = jsGet(ctx, 'parsed')! as ParsedItem;
  final custom = parsed.custom! as SankeyParsedCustom;
  final vertical = _verticalDataset(ctx);
  return ((vertical ? custom.y : custom.x) -
          jsToNumber(vertical ? parsed.y : parsed.x)) *
      200;
}

/// controller.ts:336 the tooltip callback `label`.
List<String>? _tooltipLabel(TooltipModel tooltip, TooltipItem context) {
  final parsedCustom =
      (context.parsed! as ParsedItem).custom! as SankeyParsedCustom;
  final flow = jsNumberToString(parsedCustom.flow);
  return ['${parsedCustom.from.key} -> ${parsedCustom.to.key}: $flow'];
}

/// controller.ts:340 the tooltip callback `title`: no title line.
List<String>? _tooltipTitle(TooltipModel tooltip, List<TooltipItem> items) =>
    const [];

/// controller.ts:239 `class SankeyController extends DatasetController`.
class SankeyController(super.chart, super.datasetIndex, [super.newTarget])
    extends DatasetController {
  /// `new SankeyController(chart, datasetIndex)`. Upstream declares no
  /// constructor in this class. `newTarget` is `new.target` (Chart.js ADR
  /// 0020).
  this;

  /// controller.ts:240 `static readonly id = 'sankey'`.
  static const String id = 'sankey';

  /// controller.ts:242 `static readonly descriptors`.
  static final Map<String, Object?> descriptors = <String, Object?>{
    '_indexable': false,
    '_scriptable': (Object? name) =>
        !_nodeScopedOptions.contains(name) &&
        !_hoverColorOptions.contains(name),
    'nodeLabels': <String, Object?>{'_indexable': false, '_scriptable': false},
  };

  /// controller.ts:251 `static readonly defaults`.
  // DIVERGES(sankey): adapt-sankey-native-defaults, the objects of the host.
  static final Map<String, Object?> defaults = <String, Object?>{
    'animations': <String, Object?>{
      'colors': <String, Object?>{
        'properties': <String>['colorFrom', 'colorTo'],
        'type': 'color',
      },
      'numbers': <String, Object?>{
        'properties': <String>['x', 'y', 'x2', 'y2', 'height', 'width'],
        'type': 'number',
      },
      'progress': <String, Object?>{
        'delay': _progressDelay,
        'duration': _progressDuration,
        'easing': Curves.linear,
      },
    },
    'borderColor': _black,
    'borderWidth': 1.0,
    'color': _black,
    'dataElementType': 'flow',
    'modeX': SankeyModeX.edge,
    'nodeMinSize': 0.0,
    'nodePadding': 10.0,
    'nodePaddingMode': SankeyNodePaddingMode.auto,
    'nodeWidth': 10.0,
    'orientation': SankeyOrientation.horizontal,
    'transitions': <String, Object?>{
      'hide': <String, Object?>{
        'animations': <String, Object?>{
          'colors': <String, Object?>{
            'properties': <String>['colorFrom', 'colorTo'],
            'to': _transparent,
            'type': 'color',
          },
        },
      },
      'resize': <String, Object?>{
        'animations': <String, Object?>{
          'progress': <String, Object?>{'delay': 0.0, 'duration': 0.0},
        },
      },
      'show': <String, Object?>{
        'animations': <String, Object?>{
          'colors': <String, Object?>{
            'from': _transparent,
            'properties': <String>['colorFrom', 'colorTo'],
            'type': 'color',
          },
        },
      },
    },
  };

  /// controller.ts:313 `static readonly overrides`.
  // DIVERGES(sankey): adapt-sankey-native-defaults, the objects of the host.
  static final Map<String, Object?> overrides = <String, Object?>{
    'datasets': <String, Object?>{
      'clip': ChartClip.none,
      'parsing': <String, Object?>{'flow': 'flow', 'from': 'from', 'to': 'to'},
    },
    'interaction': <String, Object?>{
      'intersect': true,
      'mode': const NearestInteractionMode(),
    },
    'layout': <String, Object?>{
      'padding': const EdgeInsets.only(bottom: 3, left: 3, right: 13, top: 3),
    },
    'plugins': <String, Object?>{
      'legend': <String, Object?>{'display': false},
      'tooltip': <String, Object?>{
        'callbacks': const TooltipCallbacks(
          label: _tooltipLabel,
          title: _tooltipTitle,
        ),
      },
    },
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'bounds': ScaleBounds.data,
        'display': false,
        'min': 0.0,
        'offset': false,
        'type': 'linear',
      },
      'y': <String, Object?>{
        'bounds': ScaleBounds.data,
        'display': false,
        'min': 0.0,
        'offset': false,
        'reverse': true,
        'type': 'linear',
      },
    },
  };

  /// controller.ts:239 `class SankeyController extends DatasetController`
  /// as a value (Chart.js ADR 0020).
  ///
  /// It extends [DatasetController.jsClass]. Its statics are [id],
  /// [descriptors], [defaults] and [overrides], in the upstream order of
  /// declaration. Its `construct` calls [SankeyController.new] with the
  /// chart and the dataset index of the arguments.
  static final JsClass jsClass = JsClass(
    'SankeyController',
    superclass: DatasetController.jsClass,
    statics: {
      'id': id,
      'descriptors': descriptors,
      'defaults': defaults,
      'overrides': overrides,
    },
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return SankeyController(chart, datasetIndex, newTarget);
    },
  );

  /// controller.ts:365 `declare options: SankeyControllerDatasetOptions`:
  /// the options of the dataset through their facade.
  SankeyControllerDatasetOptions get _options =>
      SankeyControllerDatasetOptions(options);

  Map<String, SankeyNode> _nodes = <String, SankeyNode>{};
  double _maxX = 0;
  double _maxY = 0;

  /// The nodes of the last parse, by their key, in the order of the layout.
  ///
  /// Upstream keeps them in the private `_nodes` (controller.ts:366). The
  /// specs and a plugin read the positions of the nodes from it.
  Map<String, SankeyNode> get nodes => _nodes;

  /// controller.ts:370 `parseObjectData(meta, data, start, count)`.
  @override
  List<ParsedItem> parseObjectData(
    ChartMeta meta,
    List<Object?> data,
    int start,
    int count,
  ) {
    final options = _options;
    final sankeyData = getParsedData(data, options.parsing);
    final xScale = meta.xScale;
    final yScale = meta.yScale;
    final parsed = <ParsedItem>[];
    final nodes = buildNodesFromData(
      sankeyData,
      size: options.size,
      priority: options.priority,
      column: options.column,
    );
    final orientation = options.orientation ?? SankeyOrientation.horizontal;
    _nodes = nodes;

    final nodeGaps = <String, NodeGap>{};
    final nodeMinSizes = <String, double>{};
    for (final node in nodes.values) {
      nodeGaps[node.key] = _resolveNodeGap(options.nodePadding, node);
      nodeMinSizes[node.key] = _resolveNodeMinSize(options.nodeMinSize, node);
    }

    final (:maxX, :maxY) = layout(
      nodes,
      sankeyData,
      height: orientation == SankeyOrientation.vertical
          ? chart.width
          : chart.height,
      modeX: options.modeX,
      nodeMinSize: nodeMinSizes,
      nodePadding: nodeGaps,
      nodePaddingMode: options.nodePaddingMode,
      priority: jsTruthy(options.priority),
    );

    _maxX = maxX;
    _maxY = maxY;

    if (xScale == null || yScale == null) return [];

    final flows = _flowsByIndex(nodes.values, sankeyData.length);
    for (var i = 0, ilen = sankeyData.length; i < ilen; ++i) {
      final dataPoint = sankeyData[i];
      final from = nodes[dataPoint.from];
      final to = nodes[dataPoint.to];
      if (from == null || to == null) continue;

      final fromY = _nodeY(from) + _getAddY(flows.out[i]);
      final toY = _nodeY(to) + _getAddY(flows.into[i]);
      parsed.add(
        _parseFlow(
          from,
          to,
          fromY,
          toY,
          dataPoint.flow,
          i,
          xScale as Scale,
          yScale as Scale,
          orientation,
        ),
      );
    }
    // `parsed.slice(start, start + count)`.
    final first = start < parsed.length ? start : parsed.length;
    final end = start + count < parsed.length ? start + count : parsed.length;
    return parsed.sublist(first, end < first ? first : end);
  }

  /// The parse of a data List whose first item is not a Map: a List of
  /// [SankeyDataPoint] objects takes [parseObjectData]. Upstream has no
  /// such item.
  // DIVERGES(sankey): adapt-sankey-data-point, typed data points.
  @override
  List<ParsedItem> parsePrimitiveData(
    ChartMeta meta,
    List<Object?> data,
    int start,
    int count,
  ) => parseObjectData(meta, data, start, count);

  /// controller.ts:417 `buildOrUpdateElements(resetNewElements)`.
  @override
  void buildOrUpdateElements([bool? resetNewElements]) {
    // Chart.js only rebuilds `this.options` inside `configure()`, which it
    // calls from `_updateDatasets` -- after `buildOrUpdateElements` (and the
    // parsing it triggers) has already run. The sankey layout is computed
    // while parsing, so without this, a runtime option change (nodePadding,
    // nodePaddingMode, nodeMinSize, modeX, priority, parsing, ...) would only
    // take effect on the *next* update, using the previous update's resolved
    // options in the meantime.
    configure();
    super.buildOrUpdateElements(resetNewElements);
  }

  /// controller.ts:428 `getMinMax(scale)`.
  ///
  /// The parameter has the type `Object`: the scale interface of the host
  /// signature has no public name (host-seams.md, seam S4).
  @override
  ({double min, double max}) getMinMax(Object scale, [bool? canStack]) {
    final vertical = _options.orientation == SankeyOrientation.vertical;
    final meta = cachedMeta;
    final columnScale = vertical ? meta.yScale : meta.xScale;
    return (max: identical(scale, columnScale) ? _maxX : _maxY, min: 0);
  }

  /// controller.ts:437 `update(mode)`.
  @override
  void update(String mode) {
    final data = cachedMeta.data;

    updateElements(data, 0, data.length, mode);
  }

  /// controller.ts:443 `updateElements(elems, start, count, mode)`.
  ///
  /// The parameter [elems] has the type `List<Object?>`: the element
  /// interface of the host signature has no public name (host-seams.md,
  /// seam S4).
  @override
  void updateElements(List<Object?> elems, int start, int count, String mode) {
    final meta = cachedMeta;
    final xScale = meta.xScale as Scale?;
    final yScale = meta.yScale as Scale?;
    if (xScale == null || yScale == null) return;

    final firstOpts = resolveDataElementOptions(start, mode);
    final sharedOptions = getSharedOptions(firstOpts);
    final options = _options;
    final borderWidth = options.borderWidth;
    final nodeWidth = _numberOr(options.nodeWidth, 10);
    final orientation = options.orientation ?? SankeyOrientation.horizontal;
    final columnPadding = _getColumnPadding(
      nodeWidth,
      orientation,
      chart.chartArea!,
      chart.width,
      chart.height,
    );
    final borderSpace = jsTruthy(borderWidth)
        ? jsToNumber(borderWidth) / 2 + 0.5
        : 0.0;

    for (var i = start; i < start + count; i++) {
      final parsed = getParsed(i)! as ParsedItem;
      updateElement(elems[i]! as Element, i, <String, Object?>{
        'options': resolveDataElementOptions(i, mode),
        'progress': mode == 'reset' ? 0.0 : 1.0,
        ..._getFlowElementProperties(
          parsed,
          xScale,
          yScale,
          _maxX,
          nodeWidth,
          columnPadding,
          borderSpace,
          orientation,
        ),
      }, mode);
    }

    if (sharedOptions != null) {
      updateSharedOptions(sharedOptions, mode, firstOpts);
    }
  }

  /// controller.ts:486 `_drawLabels()`.
  void _drawLabels() {
    final ctx = chart.ctx!;
    final options = _options;
    final nodes = _nodes;
    final size = validateSizeValue(options.size);
    final labels = options.labels;
    final borderWidth = _numberOr(options.borderWidth, 1);
    final nodeWidth = _numberOr(options.nodeWidth, 10);
    final orientation = options.orientation ?? SankeyOrientation.horizontal;
    final columnPadding = _getColumnPadding(
      nodeWidth,
      orientation,
      chart.chartArea!,
      chart.width,
      chart.height,
    );
    // `options.font ?? this.chart.options.font ?? Chart.defaults.font`:
    // `toFont` of the host takes `defaults.font` for a value that is no font.
    final datasetFont = options.font;
    final defaultFont = datasetFont is TextStyle
        ? datasetFont
        : jsGet(chart.options, 'font');
    final meta = cachedMeta;
    final xScale = meta.xScale as Scale?;
    final yScale = meta.yScale as Scale?;

    if (xScale == null || yScale == null) return;

    ctx.save();
    final chartArea = chart.chartArea!;
    for (final node in nodes.values) {
      final max = _getNodeSize(node, size);
      final minSize = _resolveNodeMinSize(options.nodeMinSize, node);
      final (:height, :width, :x, :y) = _getNodeRect(
        node,
        max,
        xScale,
        yScale,
        _maxX,
        nodeWidth,
        columnPadding,
        orientation,
        minSize,
      );
      // `labels?.[node.key]`: a Map, or its view from the resolver.
      final mapped = isNullOrUndef(labels) ? null : jsGet(labels, node.key);
      final label = isNullOrUndef(mapped) ? node.key : mapped;
      final labelStyle = _resolveNodeLabelStyle(options, node);
      if (labelStyle.display) {
        final labelFont = labelStyle.font;
        final font = toFont(labelFont is TextStyle ? labelFont : defaultFont);
        drawLabel(
          ctx,
          label,
          DrawLabelOptions(
            autoPosition: _getAutoLabelPosition(x, y, chartArea, orientation),
            backgroundColor: labelStyle.backgroundColor,
            borderRadius: labelStyle.borderRadius,
            borderWidth: borderWidth,
            color: labelStyle.color,
            font: font,
            height: height,
            lineOffset: jsToNumber(
              valueOrDefault(
                options.padding,
                (font.lineHeight ?? double.nan) / 2,
              ),
            ),
            padding: labelStyle.padding,
            position: labelStyle.position,
            width: width,
            x: x,
            y: y,
          ),
        );
      }
    }
    ctx.restore();
  }

  /// controller.ts:539 `_drawNodes()`.
  void _drawNodes() {
    final ctx = chart.ctx!;
    final nodes = _nodes;
    final options = _options;
    final borderColor = options.borderColor;
    final borderWidth = _numberOr(options.borderWidth, 0);
    final nodeWidth = _numberOr(options.nodeWidth, 10);
    final orientation = options.orientation ?? SankeyOrientation.horizontal;
    final columnPadding = _getColumnPadding(
      nodeWidth,
      orientation,
      chart.chartArea!,
      chart.width,
      chart.height,
    );
    final sizeMethod = validateSizeValue(options.size);
    final meta = cachedMeta;
    final xScale = meta.xScale as Scale?;
    final yScale = meta.yScale as Scale?;
    final hasBorder = borderWidth != 0 && !borderWidth.isNaN;

    ctx.save();
    if (jsTruthy(borderColor) && hasBorder) {
      ctx
        ..strokeStyle = borderColor
        ..lineWidth = borderWidth;
    }

    for (final node in nodes.values) {
      ctx.fillStyle = node.color ?? _black;
      if (xScale == null || yScale == null) return;

      final max = nodeSizeOf(node, sizeMethod);
      final minSize = _resolveNodeMinSize(options.nodeMinSize, node);
      final (:height, :width, :x, :y) = _getNodeRect(
        node,
        max,
        xScale,
        yScale,
        _maxX,
        nodeWidth,
        columnPadding,
        orientation,
        minSize,
      );
      if (hasBorder) {
        ctx.strokeRect(x, y, width, height);
      }
      ctx.fillRect(x, y, width, height);
    }
    ctx.restore();
  }

  /// controller.ts:587 `draw()`.
  ///
  /// That's where the drawing process happens
  @override
  void draw() {
    final ctx = chart.ctx!;
    final data = cachedMeta.data;

    // Set node colors
    final active = <Flow>[];
    for (var i = 0, ilen = data.length; i < ilen; ++i) {
      final flow = data[i] as Flow; /* Flow at index i */
      final from = flow.from;
      final to = flow.to;
      if (from == null || to == null) {
        continue;
      }
      from.color = _colorOf(flow, 'colorFrom');
      to.color = _colorOf(flow, 'colorTo');
      if (flow.active) {
        active.add(flow);
      }
    }

    // Make sure nodes connected to hovered flows are using hover colors.
    for (final flow in active) {
      final from = flow.from;
      final to = flow.to;
      if (from == null || to == null) {
        continue;
      }
      from.color = _colorOf(flow, 'colorFrom');
      to.color = _colorOf(flow, 'colorTo');
    }

    _drawNodes();

    for (var i = 0, ilen = data.length; i < ilen; ++i) {
      (data[i] as Flow).draw(ctx);
    }

    _drawLabels();
  }

  /// `flow.options[key]`: `undefined` is no color, as for `node.color ??
  /// 'black'`.
  static Object? _colorOf(Flow flow, String key) {
    final color = jsGet(flow.options, key);
    return color is Undefined ? null : color;
  }
}
