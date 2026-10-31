// Original code, not ported from Chart.js: generated from tool/options_schema.yaml by tool/options_gen.dart.
// Do not edit. Edit tool/options_schema.yaml and run
// `dart run melos run options:gen` (Chart.js ADR 0054 §2).

/// The scope kinds of the typed internal model (Chart.js ADR 0054 §2):
/// one entry for each kind of `tool/options_schema.yaml`, with its
/// keys, their shapes and the kinds of the nested scopes.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/options/opt.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';

/// A kind of option scope.
enum ScopeKind {
  /// Port-only kind for index.d.ts:3914 ChartConfiguration, the raw root config
  /// of a chart.
  chartConfiguration('ChartConfiguration'),

  /// index.d.ts:3892 ChartData, the `data` object of the config.
  chartData('ChartData'),

  /// index.d.ts:3843 ChartOptions (index.d.ts:1629 CoreChartOptions with
  /// ParsingOptions and AnimationOptions, ElementChartOptions,
  /// PluginChartOptions, DatasetChartOptions, ScaleChartOptions and the chart
  /// options of each controller), the root options and Chart.defaults
  /// (index.d.ts:706 Defaults).
  chartOptions('ChartOptions'),

  /// index.d.ts:3029 PluginOptionsByType, the scope `plugins` (by plugin id). A
  /// plugin entry can be `false` (the plugin is off).
  pluginOptionsByType('PluginOptionsByType'),

  /// index.d.ts:2201 ElementOptionsByType, the scope `elements` (by element
  /// type id).
  elementOptionsByType('ElementOptionsByType'),

  /// Port-only kind for index.d.ts:1631 CoreChartOptions `datasets` and
  /// index.d.ts:3831 DatasetChartOptions, the scope `datasets` (by chart type,
  /// index.d.ts:3755 ChartTypeRegistry order).
  datasetOptionsByType('DatasetOptionsByType'),

  /// Port-only kind for index.d.ts:740 Overrides, Chart.overrides
  /// (core.defaults.js:7, by chart type).
  overridesByType('OverridesByType'),

  /// Port-only kind for index.d.ts:3837 ScaleChartOptions `scales`, the scope
  /// `scales` (by scale id in the options and the overrides, by scale type in
  /// Chart.defaults.scales).
  scaleOptionsById('ScaleOptionsById'),

  /// index.d.ts:1766 AnimationsSpec, the scope `animations` (by animation
  /// name). An entry can be `false`.
  animationsSpec('AnimationsSpec'),

  /// index.d.ts:1793 TransitionsSpec, the scope `transitions` (by update mode).
  transitionsSpec('TransitionsSpec'),

  /// Port-only name for index.d.ts:1788 TransitionSpec, the options of one
  /// transition mode.
  transitionOptions('TransitionOptions'),

  /// Port-only name over index.d.ts:1741 AnimationSpec, the entry keys of
  /// index.d.ts:1766 AnimationsSpec, the callbacks of index.d.ts:1797
  /// AnimationOptions `animation` and index.d.ts:293 DoughnutAnimationOptions,
  /// the scope `animation` and each entry of `animations`.
  animationOptions('AnimationOptions'),

  /// index.d.ts:1812 FontSpec, a font object (read by toFont,
  /// helpers.options.ts).
  fontSpec('FontSpec'),

  /// Port-only kind for geometric.d.ts Padding (TRBL and Point), the padding
  /// object of toPadding and toTRBL (helpers.options.ts).
  padding('Padding'),

  /// Port-only name for index.d.ts:1735 CoreChartOptions `layout`, the scope
  /// `layout`.
  layoutOptions('LayoutOptions'),

  /// index.d.ts:751 InteractionOptions and index.d.ts:1605
  /// CoreInteractionOptions, the scopes `interaction` and `hover`.
  interactionOptions('InteractionOptions'),

  /// Port-only name for the object form of index.d.ts:54 ParsingOptions
  /// `parsing`, the keys of the parsed data (core.datasetController.js:561,
  /// controller.doughnut.js:158, helpers.config.ts:444).
  parsingOptions('ParsingOptions'),

  /// Port-only name for the object form of index.d.ts:75 `clip` (index.d.ts:463
  /// ChartMetaClip), the clip of each side.
  chartArea('ChartArea'),

  /// index.d.ts:2055 PointOptions and index.d.ts:2083 PointHoverOptions, the
  /// options of a point element.
  pointOptions('PointOptions', element: 'point'),

  /// index.d.ts:1954 LineOptions and index.d.ts:2015 LineHoverOptions, the
  /// options of a line element.
  lineOptions('LineOptions', element: 'line'),

  /// index.d.ts:2148 BarOptions and index.d.ts:2187 BarHoverOptions, the
  /// options of a bar element.
  barOptions('BarOptions', element: 'bar'),

  /// index.d.ts:1882 ArcOptions and index.d.ts:1944 ArcHoverOptions, the
  /// options of an arc element.
  arcOptions('ArcOptions', element: 'arc'),

  /// Port-only kind (Chart.js ADR 0021 section 2), the options of a custom
  /// element type or of an element subclass with its own id.
  genericElementOptions('GenericElementOptions', element: 'generic'),

  /// Port-only kind for index.d.ts:2180 BorderRadius (bar) and index.d.ts:1873
  /// ArcBorderRadius (arc), the radius of each corner.
  borderRadius('BorderRadius'),

  /// index.d.ts:2302 ComplexFillTarget and the object `{value}` of
  /// index.d.ts:2300 FillTarget, the object form of `fill`.
  fillTarget('FillTarget'),

  /// Port-only name for index.d.ts:2004 LineOptions `segment`, the scriptable
  /// styles of a line segment.
  segmentOptions('SegmentOptions'),

  /// index.d.ts:96 BarControllerDatasetOptions (index.d.ts:66
  /// ControllerDatasetOptions, BarOptions, CommonHoverOptions,
  /// AnimationOptions) with index.d.ts:149 BarControllerChartOptions, a bar
  /// dataset and `datasets.bar`.
  barControllerDatasetOptions('BarControllerDatasetOptions'),

  /// index.d.ts:189 LineControllerDatasetOptions (index.d.ts:66
  /// ControllerDatasetOptions, PointPrefixedOptions, PointPrefixedHoverOptions,
  /// LineOptions, LineHoverOptions, AnimationOptions) with index.d.ts:2317
  /// FillerControllerDatasetOptions and index.d.ts:216
  /// LineControllerChartOptions, a line or scatter dataset and `datasets.line`,
  /// `datasets.scatter`.
  lineControllerDatasetOptions('LineControllerDatasetOptions'),

  /// index.d.ts:162 BubbleControllerDatasetOptions (index.d.ts:66
  /// ControllerDatasetOptions, PointOptions, PointHoverOptions), a bubble
  /// dataset and `datasets.bubble`.
  bubbleControllerDatasetOptions('BubbleControllerDatasetOptions'),

  /// index.d.ts:247 DoughnutControllerDatasetOptions (index.d.ts:66
  /// ControllerDatasetOptions, ArcOptions, ArcHoverOptions, AnimationOptions)
  /// with index.d.ts:307 DoughnutControllerChartOptions, a doughnut or pie
  /// dataset and `datasets.doughnut`, `datasets.pie`.
  doughnutControllerDatasetOptions('DoughnutControllerDatasetOptions'),

  /// index.d.ts:390 PolarAreaControllerDatasetOptions (index.d.ts:247
  /// DoughnutControllerDatasetOptions and `angle`) with index.d.ts:400
  /// PolarAreaControllerChartOptions, a polar area dataset and
  /// `datasets.polarArea`.
  polarAreaControllerDatasetOptions('PolarAreaControllerDatasetOptions'),

  /// index.d.ts:430 RadarControllerDatasetOptions (index.d.ts:66
  /// ControllerDatasetOptions, the point options with the prefixed and hover
  /// ones, LineOptions, LineHoverOptions, AnimationOptions) with
  /// index.d.ts:2317 FillerControllerDatasetOptions, a radar dataset and
  /// `datasets.radar`.
  radarControllerDatasetOptions('RadarControllerDatasetOptions'),

  /// index.d.ts:66 ControllerDatasetOptions with index.d.ts:3859
  /// ChartDatasetProperties and the keys that core code reads for each dataset,
  /// a dataset of a chart type without a dataset kind and `datasets.<custom
  /// type>`.
  genericDatasetOptions('GenericDatasetOptions'),

  /// index.d.ts:3829 ScaleOptions, the union of index.d.ts:1200
  /// CoreScaleOptions, :3257 CartesianScaleOptions, :3344 CategoryScaleOptions,
  /// :3356 LinearScaleOptions, :3405 LogarithmicScaleOptions, :3484
  /// TimeScaleOptions and :3563 RadialLinearScaleOptions, one scale and
  /// Chart.defaults.scale.
  scaleOptions('ScaleOptions'),

  /// Port-only kind for the object form of index.d.ts:3270
  /// CartesianScaleOptions `position` (layout.d.ts LayoutPosition), the value
  /// on the scale of each id.
  scalePosition('ScalePosition'),

  /// The union of index.d.ts:3115 TickOptions, :3179 CartesianTickOptions, the
  /// linear ticks of :3376, the logarithmic ticks of :3415, :3466
  /// TimeScaleTickOptions and :3535 RadialTickOptions, the scope `ticks` of a
  /// scale.
  tickOptions('TickOptions'),

  /// Port-only name for index.d.ts:3170 TickOptions `major`, the major ticks
  /// (read at core.scale.autoskip.js:21 and scale.time.js).
  majorTickOptions('MajorTickOptions'),

  /// Port-only kind for core.scale.defaults.js:75 `ticks.minor`, an empty
  /// object that no upstream code reads.
  minorTickOptions('MinorTickOptions'),

  /// index.d.ts:3060 GridLineOptions, the scope `grid` of a scale.
  gridLineOptions('GridLineOptions'),

  /// index.d.ts:3042 BorderOptions, the scope `border` of a scale.
  borderOptions('BorderOptions'),

  /// Port-only name for index.d.ts:3309 CartesianScaleOptions `title`, the
  /// title of a scale.
  scaleTitleOptions('ScaleTitleOptions'),

  /// index.d.ts:3429 TimeScaleTimeOptions, the scope `time` of a time scale.
  timeScaleTimeOptions('TimeScaleTimeOptions'),

  /// Port-only name for index.d.ts:3447 TimeScaleTimeOptions `displayFormats`,
  /// the format of each time unit (the keys of core.adapters.ts:22 formats).
  displayFormats('DisplayFormats'),

  /// Port-only name for index.d.ts:3568 RadialLinearScaleOptions `angleLines`,
  /// the angle lines of a radial scale.
  angleLineOptions('AngleLineOptions'),

  /// Port-only name for index.d.ts:3613 RadialLinearScaleOptions `pointLabels`,
  /// the point labels of a radial scale.
  pointLabelOptions('PointLabelOptions'),

  /// index.d.ts:2422 LegendOptions, the scope `plugins.legend`.
  legendOptions('LegendOptions'),

  /// Port-only name for index.d.ts:2469 LegendOptions `labels`, the labels of
  /// the legend.
  legendLabelOptions('LegendLabelOptions'),

  /// Port-only name for index.d.ts:2552 LegendOptions `title`, the title of the
  /// legend.
  legendTitleOptions('LegendTitleOptions'),

  /// index.d.ts:2579 TitleOptions, the scopes `plugins.title` and
  /// `plugins.subtitle`.
  titleOptions('TitleOptions'),

  /// index.d.ts:2795 TooltipOptions (index.d.ts:1605 CoreInteractionOptions),
  /// the scope `plugins.tooltip`.
  tooltipOptions('TooltipOptions'),

  /// index.d.ts:2739 TooltipCallbacks (index.d.ts:2726
  /// TooltipDatasetCallbacks), the scope `callbacks` of the tooltip and of a
  /// dataset tooltip.
  tooltipCallbacks('TooltipCallbacks'),

  /// index.d.ts:2974 TooltipDatasetOptions, the `tooltip` object of a dataset
  /// (read at plugin.tooltip.js:357).
  tooltipDatasetOptions('TooltipDatasetOptions'),

  /// index.d.ts:2295 FillerOptions, the scope `plugins.filler`.
  fillerOptions('FillerOptions'),

  /// index.d.ts:2292 DecimationOptions (the union of index.d.ts:2283
  /// LttbDecimationOptions and :2288 MinMaxDecimationOptions), the scope
  /// `plugins.decimation`.
  decimationOptions('DecimationOptions'),

  /// plugin.colors.ts:4 ColorsPluginOptions, the scope `plugins.colors`.
  colorsOptions('ColorsOptions'),

  /// Port-only kind, the options of a plugin without a plugin kind (an inline
  /// or a registered user plugin).
  genericPluginOptions('GenericPluginOptions'),

  /// Port-only kind for the descriptor tree of Chart.defaults.describe
  /// (core.defaults.js:165-175) and the `descriptors` statics, by option scope
  /// path.
  descriptors('Descriptors');

  const ScopeKind(this.typeName, {this.element});

  /// The kind name of the schema.
  final String typeName;

  /// The element type id of an element kind (`point`, `line`, `bar`,
  /// `arc` or `generic`), else Dart `null`.
  final String? element;

  /// A new empty scope of this kind.
  OptionScope create() {
    switch (this) {
      case ScopeKind.chartConfiguration:
        return ChartConfigurationScope();
      case ScopeKind.chartData:
        return ChartDataScope();
      case ScopeKind.chartOptions:
        return ChartOptionsScope();
      case ScopeKind.pluginOptionsByType:
        return PluginOptionsByTypeScope();
      case ScopeKind.elementOptionsByType:
        return ElementOptionsByTypeScope();
      case ScopeKind.datasetOptionsByType:
        return DatasetOptionsByTypeScope();
      case ScopeKind.overridesByType:
        return OverridesByTypeScope();
      case ScopeKind.scaleOptionsById:
        return ScaleOptionsByIdScope();
      case ScopeKind.animationsSpec:
        return AnimationsSpecScope();
      case ScopeKind.transitionsSpec:
        return TransitionsSpecScope();
      case ScopeKind.transitionOptions:
        return TransitionOptionsScope();
      case ScopeKind.animationOptions:
        return AnimationOptionsScope();
      case ScopeKind.fontSpec:
        return FontSpecScope();
      case ScopeKind.padding:
        return PaddingScope();
      case ScopeKind.layoutOptions:
        return LayoutOptionsScope();
      case ScopeKind.interactionOptions:
        return InteractionOptionsScope();
      case ScopeKind.parsingOptions:
        return ParsingOptionsScope();
      case ScopeKind.chartArea:
        return ChartAreaScope();
      case ScopeKind.pointOptions:
        return PointOptionsScope();
      case ScopeKind.lineOptions:
        return LineOptionsScope();
      case ScopeKind.barOptions:
        return BarOptionsScope();
      case ScopeKind.arcOptions:
        return ArcOptionsScope();
      case ScopeKind.genericElementOptions:
        return GenericElementOptionsScope();
      case ScopeKind.borderRadius:
        return BorderRadiusScope();
      case ScopeKind.fillTarget:
        return FillTargetScope();
      case ScopeKind.segmentOptions:
        return SegmentOptionsScope();
      case ScopeKind.barControllerDatasetOptions:
        return BarControllerDatasetOptionsScope();
      case ScopeKind.lineControllerDatasetOptions:
        return LineControllerDatasetOptionsScope();
      case ScopeKind.bubbleControllerDatasetOptions:
        return BubbleControllerDatasetOptionsScope();
      case ScopeKind.doughnutControllerDatasetOptions:
        return DoughnutControllerDatasetOptionsScope();
      case ScopeKind.polarAreaControllerDatasetOptions:
        return PolarAreaControllerDatasetOptionsScope();
      case ScopeKind.radarControllerDatasetOptions:
        return RadarControllerDatasetOptionsScope();
      case ScopeKind.genericDatasetOptions:
        return GenericDatasetOptionsScope();
      case ScopeKind.scaleOptions:
        return ScaleOptionsScope();
      case ScopeKind.scalePosition:
        return ScalePositionScope();
      case ScopeKind.tickOptions:
        return TickOptionsScope();
      case ScopeKind.majorTickOptions:
        return MajorTickOptionsScope();
      case ScopeKind.minorTickOptions:
        return MinorTickOptionsScope();
      case ScopeKind.gridLineOptions:
        return GridLineOptionsScope();
      case ScopeKind.borderOptions:
        return BorderOptionsScope();
      case ScopeKind.scaleTitleOptions:
        return ScaleTitleOptionsScope();
      case ScopeKind.timeScaleTimeOptions:
        return TimeScaleTimeOptionsScope();
      case ScopeKind.displayFormats:
        return DisplayFormatsScope();
      case ScopeKind.angleLineOptions:
        return AngleLineOptionsScope();
      case ScopeKind.pointLabelOptions:
        return PointLabelOptionsScope();
      case ScopeKind.legendOptions:
        return LegendOptionsScope();
      case ScopeKind.legendLabelOptions:
        return LegendLabelOptionsScope();
      case ScopeKind.legendTitleOptions:
        return LegendTitleOptionsScope();
      case ScopeKind.titleOptions:
        return TitleOptionsScope();
      case ScopeKind.tooltipOptions:
        return TooltipOptionsScope();
      case ScopeKind.tooltipCallbacks:
        return TooltipCallbacksScope();
      case ScopeKind.tooltipDatasetOptions:
        return TooltipDatasetOptionsScope();
      case ScopeKind.fillerOptions:
        return FillerOptionsScope();
      case ScopeKind.decimationOptions:
        return DecimationOptionsScope();
      case ScopeKind.colorsOptions:
        return ColorsOptionsScope();
      case ScopeKind.genericPluginOptions:
        return GenericPluginOptionsScope();
      case ScopeKind.descriptors:
        return DescriptorsScope();
    }
  }

  /// The declared keys, in schema order.
  List<OptionKey> get keys {
    switch (this) {
      case ScopeKind.chartConfiguration:
        return const [
          OptionKey.type,
          OptionKey.data,
          OptionKey.options,
          OptionKey.plugins,
          OptionKey.platform,
          OptionKey.dollarTheme,
        ];
      case ScopeKind.chartData:
        return const [
          OptionKey.labels,
          OptionKey.xLabels,
          OptionKey.yLabels,
          OptionKey.datasets,
        ];
      case ScopeKind.chartOptions:
        return const [
          OptionKey.parsing,
          OptionKey.normalized,
          OptionKey.animation,
          OptionKey.animations,
          OptionKey.transitions,
          OptionKey.datasets,
          OptionKey.indexAxis,
          OptionKey.clip,
          OptionKey.color,
          OptionKey.backgroundColor,
          OptionKey.hoverBackgroundColor,
          OptionKey.borderColor,
          OptionKey.hoverBorderColor,
          OptionKey.font,
          OptionKey.responsive,
          OptionKey.maintainAspectRatio,
          OptionKey.resizeDelay,
          OptionKey.aspectRatio,
          OptionKey.locale,
          OptionKey.onResize,
          OptionKey.devicePixelRatio,
          OptionKey.interaction,
          OptionKey.hover,
          OptionKey.events,
          OptionKey.onHover,
          OptionKey.onClick,
          OptionKey.layout,
          OptionKey.elements,
          OptionKey.plugins,
          OptionKey.scales,
          OptionKey.skipNull,
          OptionKey.spanGaps,
          OptionKey.showLine,
          OptionKey.circumference,
          OptionKey.cutout,
          OptionKey.offset,
          OptionKey.radius,
          OptionKey.rotation,
          OptionKey.spacing,
          OptionKey.spacingMode,
          OptionKey.startAngle,
          OptionKey.scale,
          OptionKey.hoverColor,
          OptionKey.drawActiveElementsOnTop,
          OptionKey.label,
          OptionKey.order,
          OptionKey.stack,
          OptionKey.hidden,
          OptionKey.base,
          OptionKey.borderSkipped,
          OptionKey.borderRadius,
          OptionKey.inflateAmount,
          OptionKey.borderWidth,
          OptionKey.hoverBorderWidth,
          OptionKey.xAxisID,
          OptionKey.yAxisID,
          OptionKey.barPercentage,
          OptionKey.categoryPercentage,
          OptionKey.barThickness,
          OptionKey.maxBarThickness,
          OptionKey.minBarLength,
          OptionKey.pointStyle,
          OptionKey.grouped,
          OptionKey.tooltip,
          OptionKey.type,
          OptionKey.data,
          OptionKey.hoverBorderRadius,
          OptionKey.rAxisID,
          OptionKey.fill,
          OptionKey.datasetElementType,
          OptionKey.dataElementType,
          OptionKey.pointBackgroundColor,
          OptionKey.pointBorderColor,
          OptionKey.pointBorderWidth,
          OptionKey.pointHitRadius,
          OptionKey.pointRadius,
          OptionKey.pointRotation,
          OptionKey.pointHoverBackgroundColor,
          OptionKey.pointHoverBorderColor,
          OptionKey.pointHoverBorderWidth,
          OptionKey.pointHoverRadius,
          OptionKey.borderCapStyle,
          OptionKey.borderDash,
          OptionKey.borderDashOffset,
          OptionKey.borderJoinStyle,
          OptionKey.capBezierPoints,
          OptionKey.cubicInterpolationMode,
          OptionKey.tension,
          OptionKey.stepped,
          OptionKey.segment,
          OptionKey.hoverBorderCapStyle,
          OptionKey.hoverBorderDash,
          OptionKey.hoverBorderDashOffset,
          OptionKey.hoverBorderJoinStyle,
          OptionKey.hitRadius,
          OptionKey.hoverRadius,
          OptionKey.selfJoin,
          OptionKey.borderAlign,
          OptionKey.circular,
          OptionKey.hoverOffset,
          OptionKey.weight,
          OptionKey.angle,
          OptionKey.cutoutPercentage,
        ];
      case ScopeKind.pluginOptionsByType:
        return const [
          OptionKey.colors,
          OptionKey.decimation,
          OptionKey.filler,
          OptionKey.legend,
          OptionKey.subtitle,
          OptionKey.title,
          OptionKey.tooltip,
        ];
      case ScopeKind.elementOptionsByType:
        return const [
          OptionKey.arc,
          OptionKey.bar,
          OptionKey.line,
          OptionKey.point,
        ];
      case ScopeKind.datasetOptionsByType:
        return const [
          OptionKey.bar,
          OptionKey.line,
          OptionKey.scatter,
          OptionKey.bubble,
          OptionKey.pie,
          OptionKey.doughnut,
          OptionKey.polarArea,
          OptionKey.radar,
        ];
      case ScopeKind.overridesByType:
        return const [
          OptionKey.bar,
          OptionKey.line,
          OptionKey.scatter,
          OptionKey.bubble,
          OptionKey.pie,
          OptionKey.doughnut,
          OptionKey.polarArea,
          OptionKey.radar,
        ];
      case ScopeKind.scaleOptionsById:
        return const [];
      case ScopeKind.animationsSpec:
        return const [
          OptionKey.colors,
          OptionKey.numbers,
          OptionKey.visible,
          OptionKey.opacity,
        ];
      case ScopeKind.transitionsSpec:
        return const [
          OptionKey.active,
          OptionKey.resize,
          OptionKey.show,
          OptionKey.hide,
          OptionKey.reset,
        ];
      case ScopeKind.transitionOptions:
        return const [OptionKey.animation, OptionKey.animations];
      case ScopeKind.animationOptions:
        return const [
          OptionKey.duration,
          OptionKey.easing,
          OptionKey.delay,
          OptionKey.loop,
          OptionKey.properties,
          OptionKey.type,
          OptionKey.fn,
          OptionKey.from,
          OptionKey.to,
          OptionKey.onProgress,
          OptionKey.onComplete,
          OptionKey.animateRotate,
          OptionKey.animateScale,
        ];
      case ScopeKind.fontSpec:
        return const [
          OptionKey.family,
          OptionKey.size,
          OptionKey.style,
          OptionKey.weight,
          OptionKey.lineHeight,
        ];
      case ScopeKind.padding:
        return const [
          OptionKey.top,
          OptionKey.right,
          OptionKey.bottom,
          OptionKey.left,
          OptionKey.x,
          OptionKey.y,
        ];
      case ScopeKind.layoutOptions:
        return const [OptionKey.autoPadding, OptionKey.padding];
      case ScopeKind.interactionOptions:
        return const [
          OptionKey.mode,
          OptionKey.intersect,
          OptionKey.axis,
          OptionKey.includeInvisible,
        ];
      case ScopeKind.parsingOptions:
        return const [OptionKey.key, OptionKey.xAxisKey, OptionKey.yAxisKey];
      case ScopeKind.chartArea:
        return const [
          OptionKey.left,
          OptionKey.top,
          OptionKey.right,
          OptionKey.bottom,
        ];
      case ScopeKind.pointOptions:
        return const [
          OptionKey.borderWidth,
          OptionKey.borderColor,
          OptionKey.backgroundColor,
          OptionKey.radius,
          OptionKey.hitRadius,
          OptionKey.pointStyle,
          OptionKey.rotation,
          OptionKey.drawActiveElementsOnTop,
          OptionKey.hoverBorderWidth,
          OptionKey.hoverBorderColor,
          OptionKey.hoverBackgroundColor,
          OptionKey.hoverRadius,
          OptionKey.dollarShared,
          OptionKey.dollarAnimations,
        ];
      case ScopeKind.lineOptions:
        return const [
          OptionKey.borderWidth,
          OptionKey.borderColor,
          OptionKey.backgroundColor,
          OptionKey.borderCapStyle,
          OptionKey.borderDash,
          OptionKey.borderDashOffset,
          OptionKey.borderJoinStyle,
          OptionKey.capBezierPoints,
          OptionKey.cubicInterpolationMode,
          OptionKey.tension,
          OptionKey.stepped,
          OptionKey.fill,
          OptionKey.spanGaps,
          OptionKey.segment,
          OptionKey.hoverBorderWidth,
          OptionKey.hoverBorderColor,
          OptionKey.hoverBackgroundColor,
          OptionKey.hoverBorderCapStyle,
          OptionKey.hoverBorderDash,
          OptionKey.hoverBorderDashOffset,
          OptionKey.hoverBorderJoinStyle,
          OptionKey.dollarShared,
          OptionKey.dollarAnimations,
        ];
      case ScopeKind.barOptions:
        return const [
          OptionKey.borderColor,
          OptionKey.backgroundColor,
          OptionKey.base,
          OptionKey.borderSkipped,
          OptionKey.borderRadius,
          OptionKey.inflateAmount,
          OptionKey.borderWidth,
          OptionKey.hoverBorderWidth,
          OptionKey.hoverBorderColor,
          OptionKey.hoverBackgroundColor,
          OptionKey.hoverBorderRadius,
          OptionKey.pointStyle,
          OptionKey.dollarShared,
          OptionKey.dollarAnimations,
        ];
      case ScopeKind.arcOptions:
        return const [
          OptionKey.borderWidth,
          OptionKey.borderColor,
          OptionKey.backgroundColor,
          OptionKey.selfJoin,
          OptionKey.borderAlign,
          OptionKey.borderDash,
          OptionKey.borderDashOffset,
          OptionKey.borderJoinStyle,
          OptionKey.borderRadius,
          OptionKey.offset,
          OptionKey.circular,
          OptionKey.spacing,
          OptionKey.spacingMode,
          OptionKey.hoverBorderWidth,
          OptionKey.hoverBorderColor,
          OptionKey.hoverBackgroundColor,
          OptionKey.hoverBorderDash,
          OptionKey.hoverBorderDashOffset,
          OptionKey.hoverOffset,
          OptionKey.angle,
          OptionKey.dollarShared,
          OptionKey.dollarAnimations,
        ];
      case ScopeKind.genericElementOptions:
        return const [];
      case ScopeKind.borderRadius:
        return const [
          OptionKey.topLeft,
          OptionKey.topRight,
          OptionKey.bottomLeft,
          OptionKey.bottomRight,
          OptionKey.outerStart,
          OptionKey.outerEnd,
          OptionKey.innerStart,
          OptionKey.innerEnd,
        ];
      case ScopeKind.fillTarget:
        return const [
          OptionKey.target,
          OptionKey.above,
          OptionKey.below,
          OptionKey.value,
        ];
      case ScopeKind.segmentOptions:
        return const [
          OptionKey.backgroundColor,
          OptionKey.borderColor,
          OptionKey.borderCapStyle,
          OptionKey.borderDash,
          OptionKey.borderDashOffset,
          OptionKey.borderJoinStyle,
          OptionKey.borderWidth,
        ];
      case ScopeKind.barControllerDatasetOptions:
        return const [
          OptionKey.parsing,
          OptionKey.normalized,
          OptionKey.indexAxis,
          OptionKey.clip,
          OptionKey.label,
          OptionKey.order,
          OptionKey.stack,
          OptionKey.hidden,
          OptionKey.borderColor,
          OptionKey.backgroundColor,
          OptionKey.base,
          OptionKey.borderSkipped,
          OptionKey.borderRadius,
          OptionKey.inflateAmount,
          OptionKey.borderWidth,
          OptionKey.hoverBorderWidth,
          OptionKey.hoverBorderColor,
          OptionKey.hoverBackgroundColor,
          OptionKey.animation,
          OptionKey.animations,
          OptionKey.transitions,
          OptionKey.xAxisID,
          OptionKey.yAxisID,
          OptionKey.barPercentage,
          OptionKey.categoryPercentage,
          OptionKey.barThickness,
          OptionKey.maxBarThickness,
          OptionKey.minBarLength,
          OptionKey.pointStyle,
          OptionKey.grouped,
          OptionKey.tooltip,
          OptionKey.type,
          OptionKey.data,
          OptionKey.skipNull,
          OptionKey.hoverBorderRadius,
          OptionKey.rAxisID,
          OptionKey.fill,
          OptionKey.drawActiveElementsOnTop,
          OptionKey.elements,
          OptionKey.datasetElementType,
          OptionKey.dataElementType,
          OptionKey.descData,
          OptionKey.descDecimated,
        ];
      case ScopeKind.lineControllerDatasetOptions:
        return const [
          OptionKey.parsing,
          OptionKey.normalized,
          OptionKey.indexAxis,
          OptionKey.clip,
          OptionKey.label,
          OptionKey.order,
          OptionKey.stack,
          OptionKey.hidden,
          OptionKey.pointBackgroundColor,
          OptionKey.pointBorderColor,
          OptionKey.pointBorderWidth,
          OptionKey.pointHitRadius,
          OptionKey.pointRadius,
          OptionKey.pointRotation,
          OptionKey.pointStyle,
          OptionKey.pointHoverBackgroundColor,
          OptionKey.pointHoverBorderColor,
          OptionKey.pointHoverBorderWidth,
          OptionKey.pointHoverRadius,
          OptionKey.borderCapStyle,
          OptionKey.borderDash,
          OptionKey.borderDashOffset,
          OptionKey.borderJoinStyle,
          OptionKey.capBezierPoints,
          OptionKey.cubicInterpolationMode,
          OptionKey.tension,
          OptionKey.stepped,
          OptionKey.fill,
          OptionKey.spanGaps,
          OptionKey.segment,
          OptionKey.borderWidth,
          OptionKey.borderColor,
          OptionKey.backgroundColor,
          OptionKey.hoverBorderCapStyle,
          OptionKey.hoverBorderDash,
          OptionKey.hoverBorderDashOffset,
          OptionKey.hoverBorderJoinStyle,
          OptionKey.hoverBorderWidth,
          OptionKey.hoverBorderColor,
          OptionKey.hoverBackgroundColor,
          OptionKey.animation,
          OptionKey.animations,
          OptionKey.transitions,
          OptionKey.xAxisID,
          OptionKey.yAxisID,
          OptionKey.showLine,
          OptionKey.tooltip,
          OptionKey.type,
          OptionKey.data,
          OptionKey.rAxisID,
          OptionKey.drawActiveElementsOnTop,
          OptionKey.elements,
          OptionKey.datasetElementType,
          OptionKey.dataElementType,
          OptionKey.descData,
          OptionKey.descDecimated,
        ];
      case ScopeKind.bubbleControllerDatasetOptions:
        return const [
          OptionKey.parsing,
          OptionKey.normalized,
          OptionKey.indexAxis,
          OptionKey.clip,
          OptionKey.label,
          OptionKey.order,
          OptionKey.stack,
          OptionKey.hidden,
          OptionKey.borderWidth,
          OptionKey.borderColor,
          OptionKey.backgroundColor,
          OptionKey.radius,
          OptionKey.hitRadius,
          OptionKey.pointStyle,
          OptionKey.rotation,
          OptionKey.drawActiveElementsOnTop,
          OptionKey.hoverBorderWidth,
          OptionKey.hoverBorderColor,
          OptionKey.hoverBackgroundColor,
          OptionKey.hoverRadius,
          OptionKey.xAxisID,
          OptionKey.yAxisID,
          OptionKey.tooltip,
          OptionKey.type,
          OptionKey.data,
          OptionKey.animation,
          OptionKey.animations,
          OptionKey.transitions,
          OptionKey.rAxisID,
          OptionKey.fill,
          OptionKey.elements,
          OptionKey.datasetElementType,
          OptionKey.dataElementType,
          OptionKey.descData,
          OptionKey.descDecimated,
        ];
      case ScopeKind.doughnutControllerDatasetOptions:
        return const [
          OptionKey.parsing,
          OptionKey.normalized,
          OptionKey.indexAxis,
          OptionKey.clip,
          OptionKey.label,
          OptionKey.order,
          OptionKey.stack,
          OptionKey.hidden,
          OptionKey.borderWidth,
          OptionKey.borderColor,
          OptionKey.backgroundColor,
          OptionKey.selfJoin,
          OptionKey.borderAlign,
          OptionKey.borderDash,
          OptionKey.borderDashOffset,
          OptionKey.borderJoinStyle,
          OptionKey.borderRadius,
          OptionKey.offset,
          OptionKey.circular,
          OptionKey.spacing,
          OptionKey.spacingMode,
          OptionKey.hoverBorderWidth,
          OptionKey.hoverBorderColor,
          OptionKey.hoverBackgroundColor,
          OptionKey.hoverBorderDash,
          OptionKey.hoverBorderDashOffset,
          OptionKey.hoverOffset,
          OptionKey.animation,
          OptionKey.animations,
          OptionKey.transitions,
          OptionKey.circumference,
          OptionKey.rotation,
          OptionKey.weight,
          OptionKey.tooltip,
          OptionKey.type,
          OptionKey.data,
          OptionKey.cutout,
          OptionKey.radius,
          OptionKey.xAxisID,
          OptionKey.yAxisID,
          OptionKey.rAxisID,
          OptionKey.fill,
          OptionKey.drawActiveElementsOnTop,
          OptionKey.elements,
          OptionKey.datasetElementType,
          OptionKey.dataElementType,
          OptionKey.descData,
          OptionKey.descDecimated,
        ];
      case ScopeKind.polarAreaControllerDatasetOptions:
        return const [
          OptionKey.parsing,
          OptionKey.normalized,
          OptionKey.indexAxis,
          OptionKey.clip,
          OptionKey.label,
          OptionKey.order,
          OptionKey.stack,
          OptionKey.hidden,
          OptionKey.borderWidth,
          OptionKey.borderColor,
          OptionKey.backgroundColor,
          OptionKey.selfJoin,
          OptionKey.borderAlign,
          OptionKey.borderDash,
          OptionKey.borderDashOffset,
          OptionKey.borderJoinStyle,
          OptionKey.borderRadius,
          OptionKey.offset,
          OptionKey.circular,
          OptionKey.spacing,
          OptionKey.spacingMode,
          OptionKey.hoverBorderWidth,
          OptionKey.hoverBorderColor,
          OptionKey.hoverBackgroundColor,
          OptionKey.hoverBorderDash,
          OptionKey.hoverBorderDashOffset,
          OptionKey.hoverOffset,
          OptionKey.animation,
          OptionKey.animations,
          OptionKey.transitions,
          OptionKey.circumference,
          OptionKey.rotation,
          OptionKey.weight,
          OptionKey.angle,
          OptionKey.tooltip,
          OptionKey.type,
          OptionKey.data,
          OptionKey.startAngle,
          OptionKey.cutoutPercentage,
          OptionKey.xAxisID,
          OptionKey.yAxisID,
          OptionKey.rAxisID,
          OptionKey.fill,
          OptionKey.drawActiveElementsOnTop,
          OptionKey.elements,
          OptionKey.datasetElementType,
          OptionKey.dataElementType,
          OptionKey.descData,
          OptionKey.descDecimated,
        ];
      case ScopeKind.radarControllerDatasetOptions:
        return const [
          OptionKey.parsing,
          OptionKey.normalized,
          OptionKey.indexAxis,
          OptionKey.clip,
          OptionKey.label,
          OptionKey.order,
          OptionKey.stack,
          OptionKey.hidden,
          OptionKey.borderWidth,
          OptionKey.borderColor,
          OptionKey.backgroundColor,
          OptionKey.radius,
          OptionKey.hitRadius,
          OptionKey.pointStyle,
          OptionKey.rotation,
          OptionKey.drawActiveElementsOnTop,
          OptionKey.hoverBorderWidth,
          OptionKey.hoverBorderColor,
          OptionKey.hoverBackgroundColor,
          OptionKey.hoverRadius,
          OptionKey.pointBackgroundColor,
          OptionKey.pointBorderColor,
          OptionKey.pointBorderWidth,
          OptionKey.pointHitRadius,
          OptionKey.pointRadius,
          OptionKey.pointRotation,
          OptionKey.pointHoverBackgroundColor,
          OptionKey.pointHoverBorderColor,
          OptionKey.pointHoverBorderWidth,
          OptionKey.pointHoverRadius,
          OptionKey.borderCapStyle,
          OptionKey.borderDash,
          OptionKey.borderDashOffset,
          OptionKey.borderJoinStyle,
          OptionKey.capBezierPoints,
          OptionKey.cubicInterpolationMode,
          OptionKey.tension,
          OptionKey.stepped,
          OptionKey.fill,
          OptionKey.spanGaps,
          OptionKey.segment,
          OptionKey.hoverBorderCapStyle,
          OptionKey.hoverBorderDash,
          OptionKey.hoverBorderDashOffset,
          OptionKey.hoverBorderJoinStyle,
          OptionKey.animation,
          OptionKey.animations,
          OptionKey.transitions,
          OptionKey.xAxisID,
          OptionKey.yAxisID,
          OptionKey.showLine,
          OptionKey.tooltip,
          OptionKey.type,
          OptionKey.data,
          OptionKey.rAxisID,
          OptionKey.elements,
          OptionKey.datasetElementType,
          OptionKey.dataElementType,
          OptionKey.descData,
          OptionKey.descDecimated,
        ];
      case ScopeKind.genericDatasetOptions:
        return const [
          OptionKey.parsing,
          OptionKey.normalized,
          OptionKey.indexAxis,
          OptionKey.clip,
          OptionKey.label,
          OptionKey.order,
          OptionKey.stack,
          OptionKey.hidden,
          OptionKey.tooltip,
          OptionKey.type,
          OptionKey.data,
          OptionKey.xAxisID,
          OptionKey.yAxisID,
          OptionKey.rAxisID,
          OptionKey.fill,
          OptionKey.drawActiveElementsOnTop,
          OptionKey.animation,
          OptionKey.animations,
          OptionKey.transitions,
          OptionKey.elements,
          OptionKey.datasetElementType,
          OptionKey.dataElementType,
          OptionKey.descData,
          OptionKey.descDecimated,
        ];
      case ScopeKind.scaleOptions:
        return const [
          OptionKey.display,
          OptionKey.alignToPixels,
          OptionKey.backgroundColor,
          OptionKey.reverse,
          OptionKey.clip,
          OptionKey.weight,
          OptionKey.min,
          OptionKey.max,
          OptionKey.suggestedMin,
          OptionKey.suggestedMax,
          OptionKey.beforeUpdate,
          OptionKey.beforeSetDimensions,
          OptionKey.afterSetDimensions,
          OptionKey.beforeDataLimits,
          OptionKey.afterDataLimits,
          OptionKey.beforeBuildTicks,
          OptionKey.afterBuildTicks,
          OptionKey.beforeTickToLabelConversion,
          OptionKey.afterTickToLabelConversion,
          OptionKey.beforeCalculateLabelRotation,
          OptionKey.afterCalculateLabelRotation,
          OptionKey.beforeFit,
          OptionKey.afterFit,
          OptionKey.afterUpdate,
          OptionKey.bounds,
          OptionKey.position,
          OptionKey.stack,
          OptionKey.stackWeight,
          OptionKey.axis,
          OptionKey.offset,
          OptionKey.grid,
          OptionKey.border,
          OptionKey.title,
          OptionKey.stacked,
          OptionKey.ticks,
          OptionKey.labels,
          OptionKey.beginAtZero,
          OptionKey.grace,
          OptionKey.offsetAfterAutoskip,
          OptionKey.adapters,
          OptionKey.time,
          OptionKey.animate,
          OptionKey.startAngle,
          OptionKey.angleLines,
          OptionKey.pointLabels,
          OptionKey.type,
          OptionKey.id,
          OptionKey.fullSize,
        ];
      case ScopeKind.scalePosition:
        return const [];
      case ScopeKind.tickOptions:
        return const [
          OptionKey.backdropColor,
          OptionKey.backdropPadding,
          OptionKey.callback,
          OptionKey.display,
          OptionKey.color,
          OptionKey.font,
          OptionKey.padding,
          OptionKey.showLabelBackdrop,
          OptionKey.textStrokeColor,
          OptionKey.textStrokeWidth,
          OptionKey.z,
          OptionKey.major,
          OptionKey.sampleSize,
          OptionKey.align,
          OptionKey.autoSkip,
          OptionKey.autoSkipPadding,
          OptionKey.crossAlign,
          OptionKey.includeBounds,
          OptionKey.labelOffset,
          OptionKey.minRotation,
          OptionKey.maxRotation,
          OptionKey.mirror,
          OptionKey.maxTicksLimit,
          OptionKey.format,
          OptionKey.precision,
          OptionKey.stepSize,
          OptionKey.count,
          OptionKey.source,
          OptionKey.minor,
        ];
      case ScopeKind.majorTickOptions:
        return const [OptionKey.enabled];
      case ScopeKind.minorTickOptions:
        return const [];
      case ScopeKind.gridLineOptions:
        return const [
          OptionKey.display,
          OptionKey.circular,
          OptionKey.color,
          OptionKey.lineWidth,
          OptionKey.drawOnChartArea,
          OptionKey.drawTicks,
          OptionKey.tickBorderDash,
          OptionKey.tickBorderDashOffset,
          OptionKey.tickColor,
          OptionKey.tickLength,
          OptionKey.tickWidth,
          OptionKey.offset,
          OptionKey.z,
        ];
      case ScopeKind.borderOptions:
        return const [
          OptionKey.display,
          OptionKey.dash,
          OptionKey.dashOffset,
          OptionKey.color,
          OptionKey.width,
          OptionKey.z,
        ];
      case ScopeKind.scaleTitleOptions:
        return const [
          OptionKey.display,
          OptionKey.align,
          OptionKey.text,
          OptionKey.color,
          OptionKey.strokeColor,
          OptionKey.strokeWidth,
          OptionKey.font,
          OptionKey.padding,
        ];
      case ScopeKind.timeScaleTimeOptions:
        return const [
          OptionKey.parser,
          OptionKey.round,
          OptionKey.isoWeekday,
          OptionKey.displayFormats,
          OptionKey.tooltipFormat,
          OptionKey.unit,
          OptionKey.minUnit,
        ];
      case ScopeKind.displayFormats:
        return const [
          OptionKey.datetime,
          OptionKey.millisecond,
          OptionKey.second,
          OptionKey.minute,
          OptionKey.hour,
          OptionKey.day,
          OptionKey.week,
          OptionKey.month,
          OptionKey.quarter,
          OptionKey.year,
        ];
      case ScopeKind.angleLineOptions:
        return const [
          OptionKey.display,
          OptionKey.color,
          OptionKey.lineWidth,
          OptionKey.borderDash,
          OptionKey.borderDashOffset,
        ];
      case ScopeKind.pointLabelOptions:
        return const [
          OptionKey.backdropColor,
          OptionKey.backdropPadding,
          OptionKey.borderRadius,
          OptionKey.display,
          OptionKey.color,
          OptionKey.font,
          OptionKey.callback,
          OptionKey.padding,
          OptionKey.centerPointLabels,
        ];
      case ScopeKind.legendOptions:
        return const [
          OptionKey.display,
          OptionKey.position,
          OptionKey.align,
          OptionKey.maxHeight,
          OptionKey.maxWidth,
          OptionKey.fullSize,
          OptionKey.reverse,
          OptionKey.onClick,
          OptionKey.onHover,
          OptionKey.onLeave,
          OptionKey.labels,
          OptionKey.rtl,
          OptionKey.textDirection,
          OptionKey.title,
          OptionKey.weight,
          OptionKey.events,
        ];
      case ScopeKind.legendLabelOptions:
        return const [
          OptionKey.boxWidth,
          OptionKey.boxHeight,
          OptionKey.color,
          OptionKey.font,
          OptionKey.padding,
          OptionKey.pointStyleWidth,
          OptionKey.generateLabels,
          OptionKey.filter,
          OptionKey.sort,
          OptionKey.pointStyle,
          OptionKey.textAlign,
          OptionKey.usePointStyle,
          OptionKey.useBorderRadius,
          OptionKey.borderRadius,
        ];
      case ScopeKind.legendTitleOptions:
        return const [
          OptionKey.display,
          OptionKey.color,
          OptionKey.font,
          OptionKey.position,
          OptionKey.padding,
          OptionKey.text,
        ];
      case ScopeKind.titleOptions:
        return const [
          OptionKey.align,
          OptionKey.display,
          OptionKey.position,
          OptionKey.color,
          OptionKey.font,
          OptionKey.fullSize,
          OptionKey.padding,
          OptionKey.text,
          OptionKey.weight,
          OptionKey.events,
        ];
      case ScopeKind.tooltipOptions:
        return const [
          OptionKey.mode,
          OptionKey.intersect,
          OptionKey.axis,
          OptionKey.includeInvisible,
          OptionKey.enabled,
          OptionKey.external,
          OptionKey.position,
          OptionKey.xAlign,
          OptionKey.yAlign,
          OptionKey.itemSort,
          OptionKey.filter,
          OptionKey.backgroundColor,
          OptionKey.boxPadding,
          OptionKey.titleColor,
          OptionKey.titleFont,
          OptionKey.titleSpacing,
          OptionKey.titleMarginBottom,
          OptionKey.titleAlign,
          OptionKey.bodySpacing,
          OptionKey.bodyColor,
          OptionKey.bodyFont,
          OptionKey.bodyAlign,
          OptionKey.footerSpacing,
          OptionKey.footerMarginTop,
          OptionKey.footerColor,
          OptionKey.footerFont,
          OptionKey.footerAlign,
          OptionKey.padding,
          OptionKey.caretPadding,
          OptionKey.caretSize,
          OptionKey.cornerRadius,
          OptionKey.multiKeyBackground,
          OptionKey.displayColors,
          OptionKey.boxWidth,
          OptionKey.boxHeight,
          OptionKey.usePointStyle,
          OptionKey.borderColor,
          OptionKey.borderWidth,
          OptionKey.rtl,
          OptionKey.textDirection,
          OptionKey.animation,
          OptionKey.animations,
          OptionKey.callbacks,
          OptionKey.reverse,
          OptionKey.events,
        ];
      case ScopeKind.tooltipCallbacks:
        return const [
          OptionKey.beforeLabel,
          OptionKey.label,
          OptionKey.afterLabel,
          OptionKey.labelColor,
          OptionKey.labelTextColor,
          OptionKey.labelPointStyle,
          OptionKey.beforeTitle,
          OptionKey.title,
          OptionKey.afterTitle,
          OptionKey.beforeBody,
          OptionKey.afterBody,
          OptionKey.beforeFooter,
          OptionKey.footer,
          OptionKey.afterFooter,
        ];
      case ScopeKind.tooltipDatasetOptions:
        return const [OptionKey.callbacks];
      case ScopeKind.fillerOptions:
        return const [
          OptionKey.drawTime,
          OptionKey.propagate,
          OptionKey.events,
        ];
      case ScopeKind.decimationOptions:
        return const [
          OptionKey.enabled,
          OptionKey.threshold,
          OptionKey.algorithm,
          OptionKey.samples,
          OptionKey.events,
        ];
      case ScopeKind.colorsOptions:
        return const [
          OptionKey.enabled,
          OptionKey.forceOverride,
          OptionKey.events,
          OptionKey.dollarBorderColors,
          OptionKey.dollarBackgroundColors,
        ];
      case ScopeKind.genericPluginOptions:
        return const [OptionKey.events];
      case ScopeKind.descriptors:
        return const [
          OptionKey.descScriptable,
          OptionKey.descIndexable,
          OptionKey.descFallback,
          OptionKey.descAllKeys,
        ];
    }
  }

  /// The shape bits (`ShapeBits`) of the declared key [key], or 0 for a
  /// key that the kind does not declare.
  int shapeOf(OptionKey key) {
    switch (this) {
      case ScopeKind.chartConfiguration:
        switch (key) {
          case OptionKey.type:
            return 4;
          case OptionKey.data:
            return 32;
          case OptionKey.options:
            return 32;
          case OptionKey.plugins:
            return 16;
          case OptionKey.platform:
            return 64;
          case OptionKey.dollarTheme:
            return 64;
          default:
            return 0;
        }
      case ScopeKind.chartData:
        switch (key) {
          case OptionKey.labels:
            return 16;
          case OptionKey.xLabels:
            return 16;
          case OptionKey.yLabels:
            return 16;
          case OptionKey.datasets:
            return 16;
          default:
            return 0;
        }
      case ScopeKind.chartOptions:
        switch (key) {
          case OptionKey.parsing:
            return 34;
          case OptionKey.normalized:
            return 2;
          case OptionKey.animation:
            return 34;
          case OptionKey.animations:
            return 34;
          case OptionKey.transitions:
            return 32;
          case OptionKey.datasets:
            return 32;
          case OptionKey.indexAxis:
            return 4;
          case OptionKey.clip:
            return 35;
          case OptionKey.color:
            return 64;
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.hoverBackgroundColor:
            return 64;
          case OptionKey.borderColor:
            return 64;
          case OptionKey.hoverBorderColor:
            return 64;
          case OptionKey.font:
            return 32;
          case OptionKey.responsive:
            return 2;
          case OptionKey.maintainAspectRatio:
            return 2;
          case OptionKey.resizeDelay:
            return 1;
          case OptionKey.aspectRatio:
            return 1;
          case OptionKey.locale:
            return 4;
          case OptionKey.onResize:
            return 8;
          case OptionKey.devicePixelRatio:
            return 1;
          case OptionKey.interaction:
            return 32;
          case OptionKey.hover:
            return 32;
          case OptionKey.events:
            return 16;
          case OptionKey.onHover:
            return 8;
          case OptionKey.onClick:
            return 8;
          case OptionKey.layout:
            return 32;
          case OptionKey.elements:
            return 32;
          case OptionKey.plugins:
            return 32;
          case OptionKey.scales:
            return 32;
          case OptionKey.skipNull:
            return 2;
          case OptionKey.spanGaps:
            return 3;
          case OptionKey.showLine:
            return 2;
          case OptionKey.circumference:
            return 1;
          case OptionKey.cutout:
            return 5;
          case OptionKey.offset:
            return 1;
          case OptionKey.radius:
            return 5;
          case OptionKey.rotation:
            return 1;
          case OptionKey.spacing:
            return 1;
          case OptionKey.spacingMode:
            return 4;
          case OptionKey.startAngle:
            return 1;
          case OptionKey.scale:
            return 32;
          case OptionKey.hoverColor:
            return 64;
          case OptionKey.drawActiveElementsOnTop:
            return 2;
          case OptionKey.label:
            return 4;
          case OptionKey.order:
            return 1;
          case OptionKey.stack:
            return 4;
          case OptionKey.hidden:
            return 2;
          case OptionKey.base:
            return 1;
          case OptionKey.borderSkipped:
            return 6;
          case OptionKey.borderRadius:
            return 33;
          case OptionKey.inflateAmount:
            return 5;
          case OptionKey.borderWidth:
            return 33;
          case OptionKey.hoverBorderWidth:
            return 1;
          case OptionKey.xAxisID:
            return 4;
          case OptionKey.yAxisID:
            return 4;
          case OptionKey.barPercentage:
            return 1;
          case OptionKey.categoryPercentage:
            return 1;
          case OptionKey.barThickness:
            return 5;
          case OptionKey.maxBarThickness:
            return 1;
          case OptionKey.minBarLength:
            return 1;
          case OptionKey.pointStyle:
            return 64;
          case OptionKey.grouped:
            return 2;
          case OptionKey.tooltip:
            return 32;
          case OptionKey.type:
            return 4;
          case OptionKey.data:
            return 16;
          case OptionKey.hoverBorderRadius:
            return 33;
          case OptionKey.rAxisID:
            return 4;
          case OptionKey.fill:
            return 39;
          case OptionKey.datasetElementType:
            return 6;
          case OptionKey.dataElementType:
            return 6;
          case OptionKey.pointBackgroundColor:
            return 64;
          case OptionKey.pointBorderColor:
            return 64;
          case OptionKey.pointBorderWidth:
            return 1;
          case OptionKey.pointHitRadius:
            return 1;
          case OptionKey.pointRadius:
            return 1;
          case OptionKey.pointRotation:
            return 1;
          case OptionKey.pointHoverBackgroundColor:
            return 64;
          case OptionKey.pointHoverBorderColor:
            return 64;
          case OptionKey.pointHoverBorderWidth:
            return 1;
          case OptionKey.pointHoverRadius:
            return 1;
          case OptionKey.borderCapStyle:
            return 4;
          case OptionKey.borderDash:
            return 16;
          case OptionKey.borderDashOffset:
            return 1;
          case OptionKey.borderJoinStyle:
            return 4;
          case OptionKey.capBezierPoints:
            return 2;
          case OptionKey.cubicInterpolationMode:
            return 4;
          case OptionKey.tension:
            return 1;
          case OptionKey.stepped:
            return 6;
          case OptionKey.segment:
            return 32;
          case OptionKey.hoverBorderCapStyle:
            return 4;
          case OptionKey.hoverBorderDash:
            return 16;
          case OptionKey.hoverBorderDashOffset:
            return 1;
          case OptionKey.hoverBorderJoinStyle:
            return 4;
          case OptionKey.hitRadius:
            return 1;
          case OptionKey.hoverRadius:
            return 1;
          case OptionKey.selfJoin:
            return 2;
          case OptionKey.borderAlign:
            return 4;
          case OptionKey.circular:
            return 2;
          case OptionKey.hoverOffset:
            return 1;
          case OptionKey.weight:
            return 1;
          case OptionKey.angle:
            return 1;
          case OptionKey.cutoutPercentage:
            return 1;
          default:
            return 0;
        }
      case ScopeKind.pluginOptionsByType:
        switch (key) {
          case OptionKey.colors:
            return 34;
          case OptionKey.decimation:
            return 34;
          case OptionKey.filler:
            return 34;
          case OptionKey.legend:
            return 34;
          case OptionKey.subtitle:
            return 34;
          case OptionKey.title:
            return 34;
          case OptionKey.tooltip:
            return 34;
          default:
            return 0;
        }
      case ScopeKind.elementOptionsByType:
        switch (key) {
          case OptionKey.arc:
            return 32;
          case OptionKey.bar:
            return 32;
          case OptionKey.line:
            return 32;
          case OptionKey.point:
            return 32;
          default:
            return 0;
        }
      case ScopeKind.datasetOptionsByType:
        switch (key) {
          case OptionKey.bar:
            return 32;
          case OptionKey.line:
            return 32;
          case OptionKey.scatter:
            return 32;
          case OptionKey.bubble:
            return 32;
          case OptionKey.pie:
            return 32;
          case OptionKey.doughnut:
            return 32;
          case OptionKey.polarArea:
            return 32;
          case OptionKey.radar:
            return 32;
          default:
            return 0;
        }
      case ScopeKind.overridesByType:
        switch (key) {
          case OptionKey.bar:
            return 32;
          case OptionKey.line:
            return 32;
          case OptionKey.scatter:
            return 32;
          case OptionKey.bubble:
            return 32;
          case OptionKey.pie:
            return 32;
          case OptionKey.doughnut:
            return 32;
          case OptionKey.polarArea:
            return 32;
          case OptionKey.radar:
            return 32;
          default:
            return 0;
        }
      case ScopeKind.scaleOptionsById:
        return 0;
      case ScopeKind.animationsSpec:
        switch (key) {
          case OptionKey.colors:
            return 34;
          case OptionKey.numbers:
            return 34;
          case OptionKey.visible:
            return 34;
          case OptionKey.opacity:
            return 34;
          default:
            return 0;
        }
      case ScopeKind.transitionsSpec:
        switch (key) {
          case OptionKey.active:
            return 32;
          case OptionKey.resize:
            return 32;
          case OptionKey.show:
            return 32;
          case OptionKey.hide:
            return 32;
          case OptionKey.reset:
            return 32;
          default:
            return 0;
        }
      case ScopeKind.transitionOptions:
        switch (key) {
          case OptionKey.animation:
            return 34;
          case OptionKey.animations:
            return 34;
          default:
            return 0;
        }
      case ScopeKind.animationOptions:
        switch (key) {
          case OptionKey.duration:
            return 1;
          case OptionKey.easing:
            return 4;
          case OptionKey.delay:
            return 1;
          case OptionKey.loop:
            return 2;
          case OptionKey.properties:
            return 16;
          case OptionKey.type:
            return 4;
          case OptionKey.fn:
            return 8;
          case OptionKey.from:
            return 64;
          case OptionKey.to:
            return 64;
          case OptionKey.onProgress:
            return 8;
          case OptionKey.onComplete:
            return 8;
          case OptionKey.animateRotate:
            return 2;
          case OptionKey.animateScale:
            return 2;
          default:
            return 0;
        }
      case ScopeKind.fontSpec:
        switch (key) {
          case OptionKey.family:
            return 4;
          case OptionKey.size:
            return 1;
          case OptionKey.style:
            return 4;
          case OptionKey.weight:
            return 5;
          case OptionKey.lineHeight:
            return 5;
          default:
            return 0;
        }
      case ScopeKind.padding:
        switch (key) {
          case OptionKey.top:
            return 1;
          case OptionKey.right:
            return 1;
          case OptionKey.bottom:
            return 1;
          case OptionKey.left:
            return 1;
          case OptionKey.x:
            return 1;
          case OptionKey.y:
            return 1;
          default:
            return 0;
        }
      case ScopeKind.layoutOptions:
        switch (key) {
          case OptionKey.autoPadding:
            return 2;
          case OptionKey.padding:
            return 33;
          default:
            return 0;
        }
      case ScopeKind.interactionOptions:
        switch (key) {
          case OptionKey.mode:
            return 4;
          case OptionKey.intersect:
            return 2;
          case OptionKey.axis:
            return 4;
          case OptionKey.includeInvisible:
            return 2;
          default:
            return 0;
        }
      case ScopeKind.parsingOptions:
        switch (key) {
          case OptionKey.key:
            return 4;
          case OptionKey.xAxisKey:
            return 4;
          case OptionKey.yAxisKey:
            return 4;
          default:
            return 0;
        }
      case ScopeKind.chartArea:
        switch (key) {
          case OptionKey.left:
            return 3;
          case OptionKey.top:
            return 3;
          case OptionKey.right:
            return 3;
          case OptionKey.bottom:
            return 3;
          default:
            return 0;
        }
      case ScopeKind.pointOptions:
        switch (key) {
          case OptionKey.borderWidth:
            return 1;
          case OptionKey.borderColor:
            return 64;
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.radius:
            return 1;
          case OptionKey.hitRadius:
            return 1;
          case OptionKey.pointStyle:
            return 64;
          case OptionKey.rotation:
            return 1;
          case OptionKey.drawActiveElementsOnTop:
            return 2;
          case OptionKey.hoverBorderWidth:
            return 1;
          case OptionKey.hoverBorderColor:
            return 64;
          case OptionKey.hoverBackgroundColor:
            return 64;
          case OptionKey.hoverRadius:
            return 1;
          case OptionKey.dollarShared:
            return 2;
          case OptionKey.dollarAnimations:
            return 64;
          default:
            return 0;
        }
      case ScopeKind.lineOptions:
        switch (key) {
          case OptionKey.borderWidth:
            return 1;
          case OptionKey.borderColor:
            return 64;
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.borderCapStyle:
            return 4;
          case OptionKey.borderDash:
            return 16;
          case OptionKey.borderDashOffset:
            return 1;
          case OptionKey.borderJoinStyle:
            return 4;
          case OptionKey.capBezierPoints:
            return 2;
          case OptionKey.cubicInterpolationMode:
            return 4;
          case OptionKey.tension:
            return 1;
          case OptionKey.stepped:
            return 6;
          case OptionKey.fill:
            return 39;
          case OptionKey.spanGaps:
            return 3;
          case OptionKey.segment:
            return 32;
          case OptionKey.hoverBorderWidth:
            return 1;
          case OptionKey.hoverBorderColor:
            return 64;
          case OptionKey.hoverBackgroundColor:
            return 64;
          case OptionKey.hoverBorderCapStyle:
            return 4;
          case OptionKey.hoverBorderDash:
            return 16;
          case OptionKey.hoverBorderDashOffset:
            return 1;
          case OptionKey.hoverBorderJoinStyle:
            return 4;
          case OptionKey.dollarShared:
            return 2;
          case OptionKey.dollarAnimations:
            return 64;
          default:
            return 0;
        }
      case ScopeKind.barOptions:
        switch (key) {
          case OptionKey.borderColor:
            return 64;
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.base:
            return 1;
          case OptionKey.borderSkipped:
            return 6;
          case OptionKey.borderRadius:
            return 33;
          case OptionKey.inflateAmount:
            return 5;
          case OptionKey.borderWidth:
            return 33;
          case OptionKey.hoverBorderWidth:
            return 1;
          case OptionKey.hoverBorderColor:
            return 64;
          case OptionKey.hoverBackgroundColor:
            return 64;
          case OptionKey.hoverBorderRadius:
            return 33;
          case OptionKey.pointStyle:
            return 64;
          case OptionKey.dollarShared:
            return 2;
          case OptionKey.dollarAnimations:
            return 64;
          default:
            return 0;
        }
      case ScopeKind.arcOptions:
        switch (key) {
          case OptionKey.borderWidth:
            return 1;
          case OptionKey.borderColor:
            return 64;
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.selfJoin:
            return 2;
          case OptionKey.borderAlign:
            return 4;
          case OptionKey.borderDash:
            return 16;
          case OptionKey.borderDashOffset:
            return 1;
          case OptionKey.borderJoinStyle:
            return 4;
          case OptionKey.borderRadius:
            return 33;
          case OptionKey.offset:
            return 1;
          case OptionKey.circular:
            return 2;
          case OptionKey.spacing:
            return 1;
          case OptionKey.spacingMode:
            return 4;
          case OptionKey.hoverBorderWidth:
            return 1;
          case OptionKey.hoverBorderColor:
            return 64;
          case OptionKey.hoverBackgroundColor:
            return 64;
          case OptionKey.hoverBorderDash:
            return 16;
          case OptionKey.hoverBorderDashOffset:
            return 1;
          case OptionKey.hoverOffset:
            return 1;
          case OptionKey.angle:
            return 1;
          case OptionKey.dollarShared:
            return 2;
          case OptionKey.dollarAnimations:
            return 64;
          default:
            return 0;
        }
      case ScopeKind.genericElementOptions:
        return 0;
      case ScopeKind.borderRadius:
        switch (key) {
          case OptionKey.topLeft:
            return 1;
          case OptionKey.topRight:
            return 1;
          case OptionKey.bottomLeft:
            return 1;
          case OptionKey.bottomRight:
            return 1;
          case OptionKey.outerStart:
            return 1;
          case OptionKey.outerEnd:
            return 1;
          case OptionKey.innerStart:
            return 1;
          case OptionKey.innerEnd:
            return 1;
          default:
            return 0;
        }
      case ScopeKind.fillTarget:
        switch (key) {
          case OptionKey.target:
            return 39;
          case OptionKey.above:
            return 64;
          case OptionKey.below:
            return 64;
          case OptionKey.value:
            return 1;
          default:
            return 0;
        }
      case ScopeKind.segmentOptions:
        switch (key) {
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.borderColor:
            return 64;
          case OptionKey.borderCapStyle:
            return 4;
          case OptionKey.borderDash:
            return 16;
          case OptionKey.borderDashOffset:
            return 1;
          case OptionKey.borderJoinStyle:
            return 4;
          case OptionKey.borderWidth:
            return 1;
          default:
            return 0;
        }
      case ScopeKind.barControllerDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return 34;
          case OptionKey.normalized:
            return 2;
          case OptionKey.indexAxis:
            return 4;
          case OptionKey.clip:
            return 35;
          case OptionKey.label:
            return 4;
          case OptionKey.order:
            return 1;
          case OptionKey.stack:
            return 4;
          case OptionKey.hidden:
            return 2;
          case OptionKey.borderColor:
            return 64;
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.base:
            return 1;
          case OptionKey.borderSkipped:
            return 6;
          case OptionKey.borderRadius:
            return 33;
          case OptionKey.inflateAmount:
            return 5;
          case OptionKey.borderWidth:
            return 33;
          case OptionKey.hoverBorderWidth:
            return 1;
          case OptionKey.hoverBorderColor:
            return 64;
          case OptionKey.hoverBackgroundColor:
            return 64;
          case OptionKey.animation:
            return 34;
          case OptionKey.animations:
            return 34;
          case OptionKey.transitions:
            return 32;
          case OptionKey.xAxisID:
            return 4;
          case OptionKey.yAxisID:
            return 4;
          case OptionKey.barPercentage:
            return 1;
          case OptionKey.categoryPercentage:
            return 1;
          case OptionKey.barThickness:
            return 5;
          case OptionKey.maxBarThickness:
            return 1;
          case OptionKey.minBarLength:
            return 1;
          case OptionKey.pointStyle:
            return 64;
          case OptionKey.grouped:
            return 2;
          case OptionKey.tooltip:
            return 32;
          case OptionKey.type:
            return 4;
          case OptionKey.data:
            return 16;
          case OptionKey.skipNull:
            return 2;
          case OptionKey.hoverBorderRadius:
            return 33;
          case OptionKey.rAxisID:
            return 4;
          case OptionKey.fill:
            return 39;
          case OptionKey.drawActiveElementsOnTop:
            return 2;
          case OptionKey.elements:
            return 32;
          case OptionKey.datasetElementType:
            return 6;
          case OptionKey.dataElementType:
            return 6;
          case OptionKey.descData:
            return 64;
          case OptionKey.descDecimated:
            return 64;
          default:
            return 0;
        }
      case ScopeKind.lineControllerDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return 34;
          case OptionKey.normalized:
            return 2;
          case OptionKey.indexAxis:
            return 4;
          case OptionKey.clip:
            return 35;
          case OptionKey.label:
            return 4;
          case OptionKey.order:
            return 1;
          case OptionKey.stack:
            return 4;
          case OptionKey.hidden:
            return 2;
          case OptionKey.pointBackgroundColor:
            return 64;
          case OptionKey.pointBorderColor:
            return 64;
          case OptionKey.pointBorderWidth:
            return 1;
          case OptionKey.pointHitRadius:
            return 1;
          case OptionKey.pointRadius:
            return 1;
          case OptionKey.pointRotation:
            return 1;
          case OptionKey.pointStyle:
            return 64;
          case OptionKey.pointHoverBackgroundColor:
            return 64;
          case OptionKey.pointHoverBorderColor:
            return 64;
          case OptionKey.pointHoverBorderWidth:
            return 1;
          case OptionKey.pointHoverRadius:
            return 1;
          case OptionKey.borderCapStyle:
            return 4;
          case OptionKey.borderDash:
            return 16;
          case OptionKey.borderDashOffset:
            return 1;
          case OptionKey.borderJoinStyle:
            return 4;
          case OptionKey.capBezierPoints:
            return 2;
          case OptionKey.cubicInterpolationMode:
            return 4;
          case OptionKey.tension:
            return 1;
          case OptionKey.stepped:
            return 6;
          case OptionKey.fill:
            return 39;
          case OptionKey.spanGaps:
            return 3;
          case OptionKey.segment:
            return 32;
          case OptionKey.borderWidth:
            return 1;
          case OptionKey.borderColor:
            return 64;
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.hoverBorderCapStyle:
            return 4;
          case OptionKey.hoverBorderDash:
            return 16;
          case OptionKey.hoverBorderDashOffset:
            return 1;
          case OptionKey.hoverBorderJoinStyle:
            return 4;
          case OptionKey.hoverBorderWidth:
            return 1;
          case OptionKey.hoverBorderColor:
            return 64;
          case OptionKey.hoverBackgroundColor:
            return 64;
          case OptionKey.animation:
            return 34;
          case OptionKey.animations:
            return 34;
          case OptionKey.transitions:
            return 32;
          case OptionKey.xAxisID:
            return 4;
          case OptionKey.yAxisID:
            return 4;
          case OptionKey.showLine:
            return 2;
          case OptionKey.tooltip:
            return 32;
          case OptionKey.type:
            return 4;
          case OptionKey.data:
            return 16;
          case OptionKey.rAxisID:
            return 4;
          case OptionKey.drawActiveElementsOnTop:
            return 2;
          case OptionKey.elements:
            return 32;
          case OptionKey.datasetElementType:
            return 6;
          case OptionKey.dataElementType:
            return 6;
          case OptionKey.descData:
            return 64;
          case OptionKey.descDecimated:
            return 64;
          default:
            return 0;
        }
      case ScopeKind.bubbleControllerDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return 34;
          case OptionKey.normalized:
            return 2;
          case OptionKey.indexAxis:
            return 4;
          case OptionKey.clip:
            return 35;
          case OptionKey.label:
            return 4;
          case OptionKey.order:
            return 1;
          case OptionKey.stack:
            return 4;
          case OptionKey.hidden:
            return 2;
          case OptionKey.borderWidth:
            return 1;
          case OptionKey.borderColor:
            return 64;
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.radius:
            return 1;
          case OptionKey.hitRadius:
            return 1;
          case OptionKey.pointStyle:
            return 64;
          case OptionKey.rotation:
            return 1;
          case OptionKey.drawActiveElementsOnTop:
            return 2;
          case OptionKey.hoverBorderWidth:
            return 1;
          case OptionKey.hoverBorderColor:
            return 64;
          case OptionKey.hoverBackgroundColor:
            return 64;
          case OptionKey.hoverRadius:
            return 1;
          case OptionKey.xAxisID:
            return 4;
          case OptionKey.yAxisID:
            return 4;
          case OptionKey.tooltip:
            return 32;
          case OptionKey.type:
            return 4;
          case OptionKey.data:
            return 16;
          case OptionKey.animation:
            return 34;
          case OptionKey.animations:
            return 34;
          case OptionKey.transitions:
            return 32;
          case OptionKey.rAxisID:
            return 4;
          case OptionKey.fill:
            return 39;
          case OptionKey.elements:
            return 32;
          case OptionKey.datasetElementType:
            return 6;
          case OptionKey.dataElementType:
            return 6;
          case OptionKey.descData:
            return 64;
          case OptionKey.descDecimated:
            return 64;
          default:
            return 0;
        }
      case ScopeKind.doughnutControllerDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return 34;
          case OptionKey.normalized:
            return 2;
          case OptionKey.indexAxis:
            return 4;
          case OptionKey.clip:
            return 35;
          case OptionKey.label:
            return 4;
          case OptionKey.order:
            return 1;
          case OptionKey.stack:
            return 4;
          case OptionKey.hidden:
            return 2;
          case OptionKey.borderWidth:
            return 1;
          case OptionKey.borderColor:
            return 64;
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.selfJoin:
            return 2;
          case OptionKey.borderAlign:
            return 4;
          case OptionKey.borderDash:
            return 16;
          case OptionKey.borderDashOffset:
            return 1;
          case OptionKey.borderJoinStyle:
            return 4;
          case OptionKey.borderRadius:
            return 33;
          case OptionKey.offset:
            return 1;
          case OptionKey.circular:
            return 2;
          case OptionKey.spacing:
            return 1;
          case OptionKey.spacingMode:
            return 4;
          case OptionKey.hoverBorderWidth:
            return 1;
          case OptionKey.hoverBorderColor:
            return 64;
          case OptionKey.hoverBackgroundColor:
            return 64;
          case OptionKey.hoverBorderDash:
            return 16;
          case OptionKey.hoverBorderDashOffset:
            return 1;
          case OptionKey.hoverOffset:
            return 1;
          case OptionKey.animation:
            return 34;
          case OptionKey.animations:
            return 34;
          case OptionKey.transitions:
            return 32;
          case OptionKey.circumference:
            return 1;
          case OptionKey.rotation:
            return 1;
          case OptionKey.weight:
            return 1;
          case OptionKey.tooltip:
            return 32;
          case OptionKey.type:
            return 4;
          case OptionKey.data:
            return 16;
          case OptionKey.cutout:
            return 5;
          case OptionKey.radius:
            return 5;
          case OptionKey.xAxisID:
            return 4;
          case OptionKey.yAxisID:
            return 4;
          case OptionKey.rAxisID:
            return 4;
          case OptionKey.fill:
            return 39;
          case OptionKey.drawActiveElementsOnTop:
            return 2;
          case OptionKey.elements:
            return 32;
          case OptionKey.datasetElementType:
            return 6;
          case OptionKey.dataElementType:
            return 6;
          case OptionKey.descData:
            return 64;
          case OptionKey.descDecimated:
            return 64;
          default:
            return 0;
        }
      case ScopeKind.polarAreaControllerDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return 34;
          case OptionKey.normalized:
            return 2;
          case OptionKey.indexAxis:
            return 4;
          case OptionKey.clip:
            return 35;
          case OptionKey.label:
            return 4;
          case OptionKey.order:
            return 1;
          case OptionKey.stack:
            return 4;
          case OptionKey.hidden:
            return 2;
          case OptionKey.borderWidth:
            return 1;
          case OptionKey.borderColor:
            return 64;
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.selfJoin:
            return 2;
          case OptionKey.borderAlign:
            return 4;
          case OptionKey.borderDash:
            return 16;
          case OptionKey.borderDashOffset:
            return 1;
          case OptionKey.borderJoinStyle:
            return 4;
          case OptionKey.borderRadius:
            return 33;
          case OptionKey.offset:
            return 1;
          case OptionKey.circular:
            return 2;
          case OptionKey.spacing:
            return 1;
          case OptionKey.spacingMode:
            return 4;
          case OptionKey.hoverBorderWidth:
            return 1;
          case OptionKey.hoverBorderColor:
            return 64;
          case OptionKey.hoverBackgroundColor:
            return 64;
          case OptionKey.hoverBorderDash:
            return 16;
          case OptionKey.hoverBorderDashOffset:
            return 1;
          case OptionKey.hoverOffset:
            return 1;
          case OptionKey.animation:
            return 34;
          case OptionKey.animations:
            return 34;
          case OptionKey.transitions:
            return 32;
          case OptionKey.circumference:
            return 1;
          case OptionKey.rotation:
            return 1;
          case OptionKey.weight:
            return 1;
          case OptionKey.angle:
            return 1;
          case OptionKey.tooltip:
            return 32;
          case OptionKey.type:
            return 4;
          case OptionKey.data:
            return 16;
          case OptionKey.startAngle:
            return 1;
          case OptionKey.cutoutPercentage:
            return 1;
          case OptionKey.xAxisID:
            return 4;
          case OptionKey.yAxisID:
            return 4;
          case OptionKey.rAxisID:
            return 4;
          case OptionKey.fill:
            return 39;
          case OptionKey.drawActiveElementsOnTop:
            return 2;
          case OptionKey.elements:
            return 32;
          case OptionKey.datasetElementType:
            return 6;
          case OptionKey.dataElementType:
            return 6;
          case OptionKey.descData:
            return 64;
          case OptionKey.descDecimated:
            return 64;
          default:
            return 0;
        }
      case ScopeKind.radarControllerDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return 34;
          case OptionKey.normalized:
            return 2;
          case OptionKey.indexAxis:
            return 4;
          case OptionKey.clip:
            return 35;
          case OptionKey.label:
            return 4;
          case OptionKey.order:
            return 1;
          case OptionKey.stack:
            return 4;
          case OptionKey.hidden:
            return 2;
          case OptionKey.borderWidth:
            return 1;
          case OptionKey.borderColor:
            return 64;
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.radius:
            return 1;
          case OptionKey.hitRadius:
            return 1;
          case OptionKey.pointStyle:
            return 64;
          case OptionKey.rotation:
            return 1;
          case OptionKey.drawActiveElementsOnTop:
            return 2;
          case OptionKey.hoverBorderWidth:
            return 1;
          case OptionKey.hoverBorderColor:
            return 64;
          case OptionKey.hoverBackgroundColor:
            return 64;
          case OptionKey.hoverRadius:
            return 1;
          case OptionKey.pointBackgroundColor:
            return 64;
          case OptionKey.pointBorderColor:
            return 64;
          case OptionKey.pointBorderWidth:
            return 1;
          case OptionKey.pointHitRadius:
            return 1;
          case OptionKey.pointRadius:
            return 1;
          case OptionKey.pointRotation:
            return 1;
          case OptionKey.pointHoverBackgroundColor:
            return 64;
          case OptionKey.pointHoverBorderColor:
            return 64;
          case OptionKey.pointHoverBorderWidth:
            return 1;
          case OptionKey.pointHoverRadius:
            return 1;
          case OptionKey.borderCapStyle:
            return 4;
          case OptionKey.borderDash:
            return 16;
          case OptionKey.borderDashOffset:
            return 1;
          case OptionKey.borderJoinStyle:
            return 4;
          case OptionKey.capBezierPoints:
            return 2;
          case OptionKey.cubicInterpolationMode:
            return 4;
          case OptionKey.tension:
            return 1;
          case OptionKey.stepped:
            return 6;
          case OptionKey.fill:
            return 39;
          case OptionKey.spanGaps:
            return 3;
          case OptionKey.segment:
            return 32;
          case OptionKey.hoverBorderCapStyle:
            return 4;
          case OptionKey.hoverBorderDash:
            return 16;
          case OptionKey.hoverBorderDashOffset:
            return 1;
          case OptionKey.hoverBorderJoinStyle:
            return 4;
          case OptionKey.animation:
            return 34;
          case OptionKey.animations:
            return 34;
          case OptionKey.transitions:
            return 32;
          case OptionKey.xAxisID:
            return 4;
          case OptionKey.yAxisID:
            return 4;
          case OptionKey.showLine:
            return 2;
          case OptionKey.tooltip:
            return 32;
          case OptionKey.type:
            return 4;
          case OptionKey.data:
            return 16;
          case OptionKey.rAxisID:
            return 4;
          case OptionKey.elements:
            return 32;
          case OptionKey.datasetElementType:
            return 6;
          case OptionKey.dataElementType:
            return 6;
          case OptionKey.descData:
            return 64;
          case OptionKey.descDecimated:
            return 64;
          default:
            return 0;
        }
      case ScopeKind.genericDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return 34;
          case OptionKey.normalized:
            return 2;
          case OptionKey.indexAxis:
            return 4;
          case OptionKey.clip:
            return 35;
          case OptionKey.label:
            return 4;
          case OptionKey.order:
            return 1;
          case OptionKey.stack:
            return 4;
          case OptionKey.hidden:
            return 2;
          case OptionKey.tooltip:
            return 32;
          case OptionKey.type:
            return 4;
          case OptionKey.data:
            return 16;
          case OptionKey.xAxisID:
            return 4;
          case OptionKey.yAxisID:
            return 4;
          case OptionKey.rAxisID:
            return 4;
          case OptionKey.fill:
            return 39;
          case OptionKey.drawActiveElementsOnTop:
            return 2;
          case OptionKey.animation:
            return 34;
          case OptionKey.animations:
            return 34;
          case OptionKey.transitions:
            return 32;
          case OptionKey.elements:
            return 32;
          case OptionKey.datasetElementType:
            return 6;
          case OptionKey.dataElementType:
            return 6;
          case OptionKey.descData:
            return 64;
          case OptionKey.descDecimated:
            return 64;
          default:
            return 0;
        }
      case ScopeKind.scaleOptions:
        switch (key) {
          case OptionKey.display:
            return 6;
          case OptionKey.alignToPixels:
            return 2;
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.reverse:
            return 2;
          case OptionKey.clip:
            return 2;
          case OptionKey.weight:
            return 1;
          case OptionKey.min:
            return 64;
          case OptionKey.max:
            return 64;
          case OptionKey.suggestedMin:
            return 64;
          case OptionKey.suggestedMax:
            return 64;
          case OptionKey.beforeUpdate:
            return 8;
          case OptionKey.beforeSetDimensions:
            return 8;
          case OptionKey.afterSetDimensions:
            return 8;
          case OptionKey.beforeDataLimits:
            return 8;
          case OptionKey.afterDataLimits:
            return 8;
          case OptionKey.beforeBuildTicks:
            return 8;
          case OptionKey.afterBuildTicks:
            return 8;
          case OptionKey.beforeTickToLabelConversion:
            return 8;
          case OptionKey.afterTickToLabelConversion:
            return 8;
          case OptionKey.beforeCalculateLabelRotation:
            return 8;
          case OptionKey.afterCalculateLabelRotation:
            return 8;
          case OptionKey.beforeFit:
            return 8;
          case OptionKey.afterFit:
            return 8;
          case OptionKey.afterUpdate:
            return 8;
          case OptionKey.bounds:
            return 4;
          case OptionKey.position:
            return 36;
          case OptionKey.stack:
            return 4;
          case OptionKey.stackWeight:
            return 1;
          case OptionKey.axis:
            return 4;
          case OptionKey.offset:
            return 2;
          case OptionKey.grid:
            return 32;
          case OptionKey.border:
            return 32;
          case OptionKey.title:
            return 32;
          case OptionKey.stacked:
            return 6;
          case OptionKey.ticks:
            return 32;
          case OptionKey.labels:
            return 16;
          case OptionKey.beginAtZero:
            return 2;
          case OptionKey.grace:
            return 5;
          case OptionKey.offsetAfterAutoskip:
            return 2;
          case OptionKey.adapters:
            return 64;
          case OptionKey.time:
            return 32;
          case OptionKey.animate:
            return 2;
          case OptionKey.startAngle:
            return 1;
          case OptionKey.angleLines:
            return 32;
          case OptionKey.pointLabels:
            return 32;
          case OptionKey.type:
            return 4;
          case OptionKey.id:
            return 4;
          case OptionKey.fullSize:
            return 2;
          default:
            return 0;
        }
      case ScopeKind.scalePosition:
        return 0;
      case ScopeKind.tickOptions:
        switch (key) {
          case OptionKey.backdropColor:
            return 64;
          case OptionKey.backdropPadding:
            return 33;
          case OptionKey.callback:
            return 10;
          case OptionKey.display:
            return 2;
          case OptionKey.color:
            return 64;
          case OptionKey.font:
            return 32;
          case OptionKey.padding:
            return 1;
          case OptionKey.showLabelBackdrop:
            return 2;
          case OptionKey.textStrokeColor:
            return 64;
          case OptionKey.textStrokeWidth:
            return 1;
          case OptionKey.z:
            return 1;
          case OptionKey.major:
            return 32;
          case OptionKey.sampleSize:
            return 1;
          case OptionKey.align:
            return 4;
          case OptionKey.autoSkip:
            return 2;
          case OptionKey.autoSkipPadding:
            return 1;
          case OptionKey.crossAlign:
            return 4;
          case OptionKey.includeBounds:
            return 2;
          case OptionKey.labelOffset:
            return 1;
          case OptionKey.minRotation:
            return 1;
          case OptionKey.maxRotation:
            return 1;
          case OptionKey.mirror:
            return 2;
          case OptionKey.maxTicksLimit:
            return 1;
          case OptionKey.format:
            return 64;
          case OptionKey.precision:
            return 1;
          case OptionKey.stepSize:
            return 1;
          case OptionKey.count:
            return 1;
          case OptionKey.source:
            return 4;
          case OptionKey.minor:
            return 32;
          default:
            return 0;
        }
      case ScopeKind.majorTickOptions:
        switch (key) {
          case OptionKey.enabled:
            return 2;
          default:
            return 0;
        }
      case ScopeKind.minorTickOptions:
        return 0;
      case ScopeKind.gridLineOptions:
        switch (key) {
          case OptionKey.display:
            return 2;
          case OptionKey.circular:
            return 2;
          case OptionKey.color:
            return 64;
          case OptionKey.lineWidth:
            return 1;
          case OptionKey.drawOnChartArea:
            return 2;
          case OptionKey.drawTicks:
            return 2;
          case OptionKey.tickBorderDash:
            return 16;
          case OptionKey.tickBorderDashOffset:
            return 1;
          case OptionKey.tickColor:
            return 64;
          case OptionKey.tickLength:
            return 1;
          case OptionKey.tickWidth:
            return 1;
          case OptionKey.offset:
            return 2;
          case OptionKey.z:
            return 1;
          default:
            return 0;
        }
      case ScopeKind.borderOptions:
        switch (key) {
          case OptionKey.display:
            return 2;
          case OptionKey.dash:
            return 16;
          case OptionKey.dashOffset:
            return 1;
          case OptionKey.color:
            return 64;
          case OptionKey.width:
            return 1;
          case OptionKey.z:
            return 1;
          default:
            return 0;
        }
      case ScopeKind.scaleTitleOptions:
        switch (key) {
          case OptionKey.display:
            return 2;
          case OptionKey.align:
            return 4;
          case OptionKey.text:
            return 20;
          case OptionKey.color:
            return 64;
          case OptionKey.strokeColor:
            return 64;
          case OptionKey.strokeWidth:
            return 1;
          case OptionKey.font:
            return 32;
          case OptionKey.padding:
            return 33;
          default:
            return 0;
        }
      case ScopeKind.timeScaleTimeOptions:
        switch (key) {
          case OptionKey.parser:
            return 14;
          case OptionKey.round:
            return 6;
          case OptionKey.isoWeekday:
            return 3;
          case OptionKey.displayFormats:
            return 32;
          case OptionKey.tooltipFormat:
            return 4;
          case OptionKey.unit:
            return 6;
          case OptionKey.minUnit:
            return 4;
          default:
            return 0;
        }
      case ScopeKind.displayFormats:
        switch (key) {
          case OptionKey.datetime:
            return 4;
          case OptionKey.millisecond:
            return 4;
          case OptionKey.second:
            return 4;
          case OptionKey.minute:
            return 4;
          case OptionKey.hour:
            return 4;
          case OptionKey.day:
            return 4;
          case OptionKey.week:
            return 4;
          case OptionKey.month:
            return 4;
          case OptionKey.quarter:
            return 4;
          case OptionKey.year:
            return 4;
          default:
            return 0;
        }
      case ScopeKind.angleLineOptions:
        switch (key) {
          case OptionKey.display:
            return 2;
          case OptionKey.color:
            return 64;
          case OptionKey.lineWidth:
            return 1;
          case OptionKey.borderDash:
            return 16;
          case OptionKey.borderDashOffset:
            return 1;
          default:
            return 0;
        }
      case ScopeKind.pointLabelOptions:
        switch (key) {
          case OptionKey.backdropColor:
            return 64;
          case OptionKey.backdropPadding:
            return 33;
          case OptionKey.borderRadius:
            return 33;
          case OptionKey.display:
            return 6;
          case OptionKey.color:
            return 64;
          case OptionKey.font:
            return 32;
          case OptionKey.callback:
            return 8;
          case OptionKey.padding:
            return 1;
          case OptionKey.centerPointLabels:
            return 2;
          default:
            return 0;
        }
      case ScopeKind.legendOptions:
        switch (key) {
          case OptionKey.display:
            return 2;
          case OptionKey.position:
            return 36;
          case OptionKey.align:
            return 4;
          case OptionKey.maxHeight:
            return 1;
          case OptionKey.maxWidth:
            return 1;
          case OptionKey.fullSize:
            return 2;
          case OptionKey.reverse:
            return 2;
          case OptionKey.onClick:
            return 8;
          case OptionKey.onHover:
            return 8;
          case OptionKey.onLeave:
            return 8;
          case OptionKey.labels:
            return 32;
          case OptionKey.rtl:
            return 2;
          case OptionKey.textDirection:
            return 4;
          case OptionKey.title:
            return 32;
          case OptionKey.weight:
            return 1;
          case OptionKey.events:
            return 16;
          default:
            return 0;
        }
      case ScopeKind.legendLabelOptions:
        switch (key) {
          case OptionKey.boxWidth:
            return 1;
          case OptionKey.boxHeight:
            return 1;
          case OptionKey.color:
            return 64;
          case OptionKey.font:
            return 32;
          case OptionKey.padding:
            return 1;
          case OptionKey.pointStyleWidth:
            return 1;
          case OptionKey.generateLabels:
            return 8;
          case OptionKey.filter:
            return 8;
          case OptionKey.sort:
            return 8;
          case OptionKey.pointStyle:
            return 64;
          case OptionKey.textAlign:
            return 4;
          case OptionKey.usePointStyle:
            return 2;
          case OptionKey.useBorderRadius:
            return 2;
          case OptionKey.borderRadius:
            return 1;
          default:
            return 0;
        }
      case ScopeKind.legendTitleOptions:
        switch (key) {
          case OptionKey.display:
            return 2;
          case OptionKey.color:
            return 64;
          case OptionKey.font:
            return 32;
          case OptionKey.position:
            return 4;
          case OptionKey.padding:
            return 33;
          case OptionKey.text:
            return 4;
          default:
            return 0;
        }
      case ScopeKind.titleOptions:
        switch (key) {
          case OptionKey.align:
            return 4;
          case OptionKey.display:
            return 2;
          case OptionKey.position:
            return 4;
          case OptionKey.color:
            return 64;
          case OptionKey.font:
            return 32;
          case OptionKey.fullSize:
            return 2;
          case OptionKey.padding:
            return 33;
          case OptionKey.text:
            return 20;
          case OptionKey.weight:
            return 1;
          case OptionKey.events:
            return 16;
          default:
            return 0;
        }
      case ScopeKind.tooltipOptions:
        switch (key) {
          case OptionKey.mode:
            return 4;
          case OptionKey.intersect:
            return 2;
          case OptionKey.axis:
            return 4;
          case OptionKey.includeInvisible:
            return 2;
          case OptionKey.enabled:
            return 2;
          case OptionKey.external:
            return 8;
          case OptionKey.position:
            return 4;
          case OptionKey.xAlign:
            return 4;
          case OptionKey.yAlign:
            return 4;
          case OptionKey.itemSort:
            return 8;
          case OptionKey.filter:
            return 8;
          case OptionKey.backgroundColor:
            return 64;
          case OptionKey.boxPadding:
            return 1;
          case OptionKey.titleColor:
            return 64;
          case OptionKey.titleFont:
            return 32;
          case OptionKey.titleSpacing:
            return 1;
          case OptionKey.titleMarginBottom:
            return 1;
          case OptionKey.titleAlign:
            return 4;
          case OptionKey.bodySpacing:
            return 1;
          case OptionKey.bodyColor:
            return 64;
          case OptionKey.bodyFont:
            return 32;
          case OptionKey.bodyAlign:
            return 4;
          case OptionKey.footerSpacing:
            return 1;
          case OptionKey.footerMarginTop:
            return 1;
          case OptionKey.footerColor:
            return 64;
          case OptionKey.footerFont:
            return 32;
          case OptionKey.footerAlign:
            return 4;
          case OptionKey.padding:
            return 33;
          case OptionKey.caretPadding:
            return 1;
          case OptionKey.caretSize:
            return 1;
          case OptionKey.cornerRadius:
            return 33;
          case OptionKey.multiKeyBackground:
            return 64;
          case OptionKey.displayColors:
            return 2;
          case OptionKey.boxWidth:
            return 1;
          case OptionKey.boxHeight:
            return 1;
          case OptionKey.usePointStyle:
            return 2;
          case OptionKey.borderColor:
            return 64;
          case OptionKey.borderWidth:
            return 1;
          case OptionKey.rtl:
            return 2;
          case OptionKey.textDirection:
            return 4;
          case OptionKey.animation:
            return 34;
          case OptionKey.animations:
            return 34;
          case OptionKey.callbacks:
            return 32;
          case OptionKey.reverse:
            return 2;
          case OptionKey.events:
            return 16;
          default:
            return 0;
        }
      case ScopeKind.tooltipCallbacks:
        switch (key) {
          case OptionKey.beforeLabel:
            return 8;
          case OptionKey.label:
            return 8;
          case OptionKey.afterLabel:
            return 8;
          case OptionKey.labelColor:
            return 8;
          case OptionKey.labelTextColor:
            return 8;
          case OptionKey.labelPointStyle:
            return 8;
          case OptionKey.beforeTitle:
            return 8;
          case OptionKey.title:
            return 8;
          case OptionKey.afterTitle:
            return 8;
          case OptionKey.beforeBody:
            return 8;
          case OptionKey.afterBody:
            return 8;
          case OptionKey.beforeFooter:
            return 8;
          case OptionKey.footer:
            return 8;
          case OptionKey.afterFooter:
            return 8;
          default:
            return 0;
        }
      case ScopeKind.tooltipDatasetOptions:
        switch (key) {
          case OptionKey.callbacks:
            return 32;
          default:
            return 0;
        }
      case ScopeKind.fillerOptions:
        switch (key) {
          case OptionKey.drawTime:
            return 4;
          case OptionKey.propagate:
            return 2;
          case OptionKey.events:
            return 16;
          default:
            return 0;
        }
      case ScopeKind.decimationOptions:
        switch (key) {
          case OptionKey.enabled:
            return 2;
          case OptionKey.threshold:
            return 1;
          case OptionKey.algorithm:
            return 4;
          case OptionKey.samples:
            return 1;
          case OptionKey.events:
            return 16;
          default:
            return 0;
        }
      case ScopeKind.colorsOptions:
        switch (key) {
          case OptionKey.enabled:
            return 2;
          case OptionKey.forceOverride:
            return 2;
          case OptionKey.events:
            return 16;
          case OptionKey.dollarBorderColors:
            return 16;
          case OptionKey.dollarBackgroundColors:
            return 16;
          default:
            return 0;
        }
      case ScopeKind.genericPluginOptions:
        switch (key) {
          case OptionKey.events:
            return 16;
          default:
            return 0;
        }
      case ScopeKind.descriptors:
        switch (key) {
          case OptionKey.descScriptable:
            return 64;
          case OptionKey.descIndexable:
            return 64;
          case OptionKey.descFallback:
            return 64;
          case OptionKey.descAllKeys:
            return 64;
          default:
            return 0;
        }
    }
  }

  /// The kind of the nested scope of the declared key [key], when its
  /// shape has a `scope` atom, else Dart `null`.
  ScopeKind? childKind(OptionKey key) {
    switch (this) {
      case ScopeKind.chartConfiguration:
        switch (key) {
          case OptionKey.data:
            return ScopeKind.chartData;
          case OptionKey.options:
            return ScopeKind.chartOptions;
          default:
            return null;
        }
      case ScopeKind.chartData:
        return null;
      case ScopeKind.chartOptions:
        switch (key) {
          case OptionKey.parsing:
            return ScopeKind.parsingOptions;
          case OptionKey.animation:
            return ScopeKind.animationOptions;
          case OptionKey.animations:
            return ScopeKind.animationsSpec;
          case OptionKey.transitions:
            return ScopeKind.transitionsSpec;
          case OptionKey.datasets:
            return ScopeKind.datasetOptionsByType;
          case OptionKey.clip:
            return ScopeKind.chartArea;
          case OptionKey.font:
            return ScopeKind.fontSpec;
          case OptionKey.interaction:
            return ScopeKind.interactionOptions;
          case OptionKey.hover:
            return ScopeKind.interactionOptions;
          case OptionKey.layout:
            return ScopeKind.layoutOptions;
          case OptionKey.elements:
            return ScopeKind.elementOptionsByType;
          case OptionKey.plugins:
            return ScopeKind.pluginOptionsByType;
          case OptionKey.scales:
            return ScopeKind.scaleOptionsById;
          case OptionKey.scale:
            return ScopeKind.scaleOptions;
          case OptionKey.borderRadius:
            return ScopeKind.borderRadius;
          case OptionKey.borderWidth:
            return ScopeKind.padding;
          case OptionKey.tooltip:
            return ScopeKind.tooltipDatasetOptions;
          case OptionKey.hoverBorderRadius:
            return ScopeKind.borderRadius;
          case OptionKey.fill:
            return ScopeKind.fillTarget;
          case OptionKey.segment:
            return ScopeKind.segmentOptions;
          default:
            return null;
        }
      case ScopeKind.pluginOptionsByType:
        switch (key) {
          case OptionKey.colors:
            return ScopeKind.colorsOptions;
          case OptionKey.decimation:
            return ScopeKind.decimationOptions;
          case OptionKey.filler:
            return ScopeKind.fillerOptions;
          case OptionKey.legend:
            return ScopeKind.legendOptions;
          case OptionKey.subtitle:
            return ScopeKind.titleOptions;
          case OptionKey.title:
            return ScopeKind.titleOptions;
          case OptionKey.tooltip:
            return ScopeKind.tooltipOptions;
          default:
            return null;
        }
      case ScopeKind.elementOptionsByType:
        switch (key) {
          case OptionKey.arc:
            return ScopeKind.arcOptions;
          case OptionKey.bar:
            return ScopeKind.barOptions;
          case OptionKey.line:
            return ScopeKind.lineOptions;
          case OptionKey.point:
            return ScopeKind.pointOptions;
          default:
            return null;
        }
      case ScopeKind.datasetOptionsByType:
        switch (key) {
          case OptionKey.bar:
            return ScopeKind.barControllerDatasetOptions;
          case OptionKey.line:
            return ScopeKind.lineControllerDatasetOptions;
          case OptionKey.scatter:
            return ScopeKind.lineControllerDatasetOptions;
          case OptionKey.bubble:
            return ScopeKind.bubbleControllerDatasetOptions;
          case OptionKey.pie:
            return ScopeKind.doughnutControllerDatasetOptions;
          case OptionKey.doughnut:
            return ScopeKind.doughnutControllerDatasetOptions;
          case OptionKey.polarArea:
            return ScopeKind.polarAreaControllerDatasetOptions;
          case OptionKey.radar:
            return ScopeKind.radarControllerDatasetOptions;
          default:
            return null;
        }
      case ScopeKind.overridesByType:
        switch (key) {
          case OptionKey.bar:
            return ScopeKind.chartOptions;
          case OptionKey.line:
            return ScopeKind.chartOptions;
          case OptionKey.scatter:
            return ScopeKind.chartOptions;
          case OptionKey.bubble:
            return ScopeKind.chartOptions;
          case OptionKey.pie:
            return ScopeKind.chartOptions;
          case OptionKey.doughnut:
            return ScopeKind.chartOptions;
          case OptionKey.polarArea:
            return ScopeKind.chartOptions;
          case OptionKey.radar:
            return ScopeKind.chartOptions;
          default:
            return null;
        }
      case ScopeKind.scaleOptionsById:
        return null;
      case ScopeKind.animationsSpec:
        switch (key) {
          case OptionKey.colors:
            return ScopeKind.animationOptions;
          case OptionKey.numbers:
            return ScopeKind.animationOptions;
          case OptionKey.visible:
            return ScopeKind.animationOptions;
          case OptionKey.opacity:
            return ScopeKind.animationOptions;
          default:
            return null;
        }
      case ScopeKind.transitionsSpec:
        switch (key) {
          case OptionKey.active:
            return ScopeKind.transitionOptions;
          case OptionKey.resize:
            return ScopeKind.transitionOptions;
          case OptionKey.show:
            return ScopeKind.transitionOptions;
          case OptionKey.hide:
            return ScopeKind.transitionOptions;
          case OptionKey.reset:
            return ScopeKind.transitionOptions;
          default:
            return null;
        }
      case ScopeKind.transitionOptions:
        switch (key) {
          case OptionKey.animation:
            return ScopeKind.animationOptions;
          case OptionKey.animations:
            return ScopeKind.animationsSpec;
          default:
            return null;
        }
      case ScopeKind.animationOptions:
        return null;
      case ScopeKind.fontSpec:
        return null;
      case ScopeKind.padding:
        return null;
      case ScopeKind.layoutOptions:
        switch (key) {
          case OptionKey.padding:
            return ScopeKind.padding;
          default:
            return null;
        }
      case ScopeKind.interactionOptions:
        return null;
      case ScopeKind.parsingOptions:
        return null;
      case ScopeKind.chartArea:
        return null;
      case ScopeKind.pointOptions:
        return null;
      case ScopeKind.lineOptions:
        switch (key) {
          case OptionKey.fill:
            return ScopeKind.fillTarget;
          case OptionKey.segment:
            return ScopeKind.segmentOptions;
          default:
            return null;
        }
      case ScopeKind.barOptions:
        switch (key) {
          case OptionKey.borderRadius:
            return ScopeKind.borderRadius;
          case OptionKey.borderWidth:
            return ScopeKind.padding;
          case OptionKey.hoverBorderRadius:
            return ScopeKind.borderRadius;
          default:
            return null;
        }
      case ScopeKind.arcOptions:
        switch (key) {
          case OptionKey.borderRadius:
            return ScopeKind.borderRadius;
          default:
            return null;
        }
      case ScopeKind.genericElementOptions:
        return null;
      case ScopeKind.borderRadius:
        return null;
      case ScopeKind.fillTarget:
        switch (key) {
          case OptionKey.target:
            return ScopeKind.fillTarget;
          default:
            return null;
        }
      case ScopeKind.segmentOptions:
        return null;
      case ScopeKind.barControllerDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return ScopeKind.parsingOptions;
          case OptionKey.clip:
            return ScopeKind.chartArea;
          case OptionKey.borderRadius:
            return ScopeKind.borderRadius;
          case OptionKey.borderWidth:
            return ScopeKind.padding;
          case OptionKey.animation:
            return ScopeKind.animationOptions;
          case OptionKey.animations:
            return ScopeKind.animationsSpec;
          case OptionKey.transitions:
            return ScopeKind.transitionsSpec;
          case OptionKey.tooltip:
            return ScopeKind.tooltipDatasetOptions;
          case OptionKey.hoverBorderRadius:
            return ScopeKind.borderRadius;
          case OptionKey.fill:
            return ScopeKind.fillTarget;
          case OptionKey.elements:
            return ScopeKind.elementOptionsByType;
          default:
            return null;
        }
      case ScopeKind.lineControllerDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return ScopeKind.parsingOptions;
          case OptionKey.clip:
            return ScopeKind.chartArea;
          case OptionKey.fill:
            return ScopeKind.fillTarget;
          case OptionKey.segment:
            return ScopeKind.segmentOptions;
          case OptionKey.animation:
            return ScopeKind.animationOptions;
          case OptionKey.animations:
            return ScopeKind.animationsSpec;
          case OptionKey.transitions:
            return ScopeKind.transitionsSpec;
          case OptionKey.tooltip:
            return ScopeKind.tooltipDatasetOptions;
          case OptionKey.elements:
            return ScopeKind.elementOptionsByType;
          default:
            return null;
        }
      case ScopeKind.bubbleControllerDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return ScopeKind.parsingOptions;
          case OptionKey.clip:
            return ScopeKind.chartArea;
          case OptionKey.tooltip:
            return ScopeKind.tooltipDatasetOptions;
          case OptionKey.animation:
            return ScopeKind.animationOptions;
          case OptionKey.animations:
            return ScopeKind.animationsSpec;
          case OptionKey.transitions:
            return ScopeKind.transitionsSpec;
          case OptionKey.fill:
            return ScopeKind.fillTarget;
          case OptionKey.elements:
            return ScopeKind.elementOptionsByType;
          default:
            return null;
        }
      case ScopeKind.doughnutControllerDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return ScopeKind.parsingOptions;
          case OptionKey.clip:
            return ScopeKind.chartArea;
          case OptionKey.borderRadius:
            return ScopeKind.borderRadius;
          case OptionKey.animation:
            return ScopeKind.animationOptions;
          case OptionKey.animations:
            return ScopeKind.animationsSpec;
          case OptionKey.transitions:
            return ScopeKind.transitionsSpec;
          case OptionKey.tooltip:
            return ScopeKind.tooltipDatasetOptions;
          case OptionKey.fill:
            return ScopeKind.fillTarget;
          case OptionKey.elements:
            return ScopeKind.elementOptionsByType;
          default:
            return null;
        }
      case ScopeKind.polarAreaControllerDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return ScopeKind.parsingOptions;
          case OptionKey.clip:
            return ScopeKind.chartArea;
          case OptionKey.borderRadius:
            return ScopeKind.borderRadius;
          case OptionKey.animation:
            return ScopeKind.animationOptions;
          case OptionKey.animations:
            return ScopeKind.animationsSpec;
          case OptionKey.transitions:
            return ScopeKind.transitionsSpec;
          case OptionKey.tooltip:
            return ScopeKind.tooltipDatasetOptions;
          case OptionKey.fill:
            return ScopeKind.fillTarget;
          case OptionKey.elements:
            return ScopeKind.elementOptionsByType;
          default:
            return null;
        }
      case ScopeKind.radarControllerDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return ScopeKind.parsingOptions;
          case OptionKey.clip:
            return ScopeKind.chartArea;
          case OptionKey.fill:
            return ScopeKind.fillTarget;
          case OptionKey.segment:
            return ScopeKind.segmentOptions;
          case OptionKey.animation:
            return ScopeKind.animationOptions;
          case OptionKey.animations:
            return ScopeKind.animationsSpec;
          case OptionKey.transitions:
            return ScopeKind.transitionsSpec;
          case OptionKey.tooltip:
            return ScopeKind.tooltipDatasetOptions;
          case OptionKey.elements:
            return ScopeKind.elementOptionsByType;
          default:
            return null;
        }
      case ScopeKind.genericDatasetOptions:
        switch (key) {
          case OptionKey.parsing:
            return ScopeKind.parsingOptions;
          case OptionKey.clip:
            return ScopeKind.chartArea;
          case OptionKey.tooltip:
            return ScopeKind.tooltipDatasetOptions;
          case OptionKey.fill:
            return ScopeKind.fillTarget;
          case OptionKey.animation:
            return ScopeKind.animationOptions;
          case OptionKey.animations:
            return ScopeKind.animationsSpec;
          case OptionKey.transitions:
            return ScopeKind.transitionsSpec;
          case OptionKey.elements:
            return ScopeKind.elementOptionsByType;
          default:
            return null;
        }
      case ScopeKind.scaleOptions:
        switch (key) {
          case OptionKey.position:
            return ScopeKind.scalePosition;
          case OptionKey.grid:
            return ScopeKind.gridLineOptions;
          case OptionKey.border:
            return ScopeKind.borderOptions;
          case OptionKey.title:
            return ScopeKind.scaleTitleOptions;
          case OptionKey.ticks:
            return ScopeKind.tickOptions;
          case OptionKey.time:
            return ScopeKind.timeScaleTimeOptions;
          case OptionKey.angleLines:
            return ScopeKind.angleLineOptions;
          case OptionKey.pointLabels:
            return ScopeKind.pointLabelOptions;
          default:
            return null;
        }
      case ScopeKind.scalePosition:
        return null;
      case ScopeKind.tickOptions:
        switch (key) {
          case OptionKey.backdropPadding:
            return ScopeKind.padding;
          case OptionKey.font:
            return ScopeKind.fontSpec;
          case OptionKey.major:
            return ScopeKind.majorTickOptions;
          case OptionKey.minor:
            return ScopeKind.minorTickOptions;
          default:
            return null;
        }
      case ScopeKind.majorTickOptions:
        return null;
      case ScopeKind.minorTickOptions:
        return null;
      case ScopeKind.gridLineOptions:
        return null;
      case ScopeKind.borderOptions:
        return null;
      case ScopeKind.scaleTitleOptions:
        switch (key) {
          case OptionKey.font:
            return ScopeKind.fontSpec;
          case OptionKey.padding:
            return ScopeKind.padding;
          default:
            return null;
        }
      case ScopeKind.timeScaleTimeOptions:
        switch (key) {
          case OptionKey.displayFormats:
            return ScopeKind.displayFormats;
          default:
            return null;
        }
      case ScopeKind.displayFormats:
        return null;
      case ScopeKind.angleLineOptions:
        return null;
      case ScopeKind.pointLabelOptions:
        switch (key) {
          case OptionKey.backdropPadding:
            return ScopeKind.padding;
          case OptionKey.borderRadius:
            return ScopeKind.borderRadius;
          case OptionKey.font:
            return ScopeKind.fontSpec;
          default:
            return null;
        }
      case ScopeKind.legendOptions:
        switch (key) {
          case OptionKey.position:
            return ScopeKind.scalePosition;
          case OptionKey.labels:
            return ScopeKind.legendLabelOptions;
          case OptionKey.title:
            return ScopeKind.legendTitleOptions;
          default:
            return null;
        }
      case ScopeKind.legendLabelOptions:
        switch (key) {
          case OptionKey.font:
            return ScopeKind.fontSpec;
          default:
            return null;
        }
      case ScopeKind.legendTitleOptions:
        switch (key) {
          case OptionKey.font:
            return ScopeKind.fontSpec;
          case OptionKey.padding:
            return ScopeKind.padding;
          default:
            return null;
        }
      case ScopeKind.titleOptions:
        switch (key) {
          case OptionKey.font:
            return ScopeKind.fontSpec;
          case OptionKey.padding:
            return ScopeKind.padding;
          default:
            return null;
        }
      case ScopeKind.tooltipOptions:
        switch (key) {
          case OptionKey.titleFont:
            return ScopeKind.fontSpec;
          case OptionKey.bodyFont:
            return ScopeKind.fontSpec;
          case OptionKey.footerFont:
            return ScopeKind.fontSpec;
          case OptionKey.padding:
            return ScopeKind.padding;
          case OptionKey.cornerRadius:
            return ScopeKind.borderRadius;
          case OptionKey.animation:
            return ScopeKind.animationOptions;
          case OptionKey.animations:
            return ScopeKind.animationsSpec;
          case OptionKey.callbacks:
            return ScopeKind.tooltipCallbacks;
          default:
            return null;
        }
      case ScopeKind.tooltipCallbacks:
        return null;
      case ScopeKind.tooltipDatasetOptions:
        switch (key) {
          case OptionKey.callbacks:
            return ScopeKind.tooltipCallbacks;
          default:
            return null;
        }
      case ScopeKind.fillerOptions:
        return null;
      case ScopeKind.decimationOptions:
        return null;
      case ScopeKind.colorsOptions:
        return null;
      case ScopeKind.genericPluginOptions:
        return null;
      case ScopeKind.descriptors:
        return null;
    }
  }

  /// The shape bits of a key that the kind does not declare (`others`
  /// of the schema; `any` when the schema gives none).
  int get othersShape {
    switch (this) {
      case ScopeKind.chartConfiguration:
        return 64;
      case ScopeKind.chartData:
        return 64;
      case ScopeKind.chartOptions:
        return 64;
      case ScopeKind.pluginOptionsByType:
        return 34;
      case ScopeKind.elementOptionsByType:
        return 32;
      case ScopeKind.datasetOptionsByType:
        return 32;
      case ScopeKind.overridesByType:
        return 32;
      case ScopeKind.scaleOptionsById:
        return 32;
      case ScopeKind.animationsSpec:
        return 34;
      case ScopeKind.transitionsSpec:
        return 32;
      case ScopeKind.transitionOptions:
        return 64;
      case ScopeKind.animationOptions:
        return 64;
      case ScopeKind.fontSpec:
        return 64;
      case ScopeKind.padding:
        return 64;
      case ScopeKind.layoutOptions:
        return 64;
      case ScopeKind.interactionOptions:
        return 64;
      case ScopeKind.parsingOptions:
        return 64;
      case ScopeKind.chartArea:
        return 64;
      case ScopeKind.pointOptions:
        return 64;
      case ScopeKind.lineOptions:
        return 64;
      case ScopeKind.barOptions:
        return 64;
      case ScopeKind.arcOptions:
        return 64;
      case ScopeKind.genericElementOptions:
        return 64;
      case ScopeKind.borderRadius:
        return 64;
      case ScopeKind.fillTarget:
        return 64;
      case ScopeKind.segmentOptions:
        return 64;
      case ScopeKind.barControllerDatasetOptions:
        return 64;
      case ScopeKind.lineControllerDatasetOptions:
        return 64;
      case ScopeKind.bubbleControllerDatasetOptions:
        return 64;
      case ScopeKind.doughnutControllerDatasetOptions:
        return 64;
      case ScopeKind.polarAreaControllerDatasetOptions:
        return 64;
      case ScopeKind.radarControllerDatasetOptions:
        return 64;
      case ScopeKind.genericDatasetOptions:
        return 64;
      case ScopeKind.scaleOptions:
        return 64;
      case ScopeKind.scalePosition:
        return 1;
      case ScopeKind.tickOptions:
        return 64;
      case ScopeKind.majorTickOptions:
        return 64;
      case ScopeKind.minorTickOptions:
        return 64;
      case ScopeKind.gridLineOptions:
        return 64;
      case ScopeKind.borderOptions:
        return 64;
      case ScopeKind.scaleTitleOptions:
        return 64;
      case ScopeKind.timeScaleTimeOptions:
        return 64;
      case ScopeKind.displayFormats:
        return 4;
      case ScopeKind.angleLineOptions:
        return 64;
      case ScopeKind.pointLabelOptions:
        return 64;
      case ScopeKind.legendOptions:
        return 64;
      case ScopeKind.legendLabelOptions:
        return 64;
      case ScopeKind.legendTitleOptions:
        return 64;
      case ScopeKind.titleOptions:
        return 64;
      case ScopeKind.tooltipOptions:
        return 64;
      case ScopeKind.tooltipCallbacks:
        return 64;
      case ScopeKind.tooltipDatasetOptions:
        return 64;
      case ScopeKind.fillerOptions:
        return 64;
      case ScopeKind.decimationOptions:
        return 64;
      case ScopeKind.colorsOptions:
        return 64;
      case ScopeKind.genericPluginOptions:
        return 64;
      case ScopeKind.descriptors:
        return 32;
    }
  }

  /// The kind of the nested scope of a key that the kind does not
  /// declare (the `scope` atom of `others`), else Dart `null`.
  ScopeKind? get othersKind {
    switch (this) {
      case ScopeKind.chartConfiguration:
        return null;
      case ScopeKind.chartData:
        return null;
      case ScopeKind.chartOptions:
        return null;
      case ScopeKind.pluginOptionsByType:
        return ScopeKind.genericPluginOptions;
      case ScopeKind.elementOptionsByType:
        return ScopeKind.genericElementOptions;
      case ScopeKind.datasetOptionsByType:
        return ScopeKind.genericDatasetOptions;
      case ScopeKind.overridesByType:
        return ScopeKind.chartOptions;
      case ScopeKind.scaleOptionsById:
        return ScopeKind.scaleOptions;
      case ScopeKind.animationsSpec:
        return ScopeKind.animationOptions;
      case ScopeKind.transitionsSpec:
        return ScopeKind.transitionOptions;
      case ScopeKind.transitionOptions:
        return null;
      case ScopeKind.animationOptions:
        return null;
      case ScopeKind.fontSpec:
        return null;
      case ScopeKind.padding:
        return null;
      case ScopeKind.layoutOptions:
        return null;
      case ScopeKind.interactionOptions:
        return null;
      case ScopeKind.parsingOptions:
        return null;
      case ScopeKind.chartArea:
        return null;
      case ScopeKind.pointOptions:
        return null;
      case ScopeKind.lineOptions:
        return null;
      case ScopeKind.barOptions:
        return null;
      case ScopeKind.arcOptions:
        return null;
      case ScopeKind.genericElementOptions:
        return null;
      case ScopeKind.borderRadius:
        return null;
      case ScopeKind.fillTarget:
        return null;
      case ScopeKind.segmentOptions:
        return null;
      case ScopeKind.barControllerDatasetOptions:
        return null;
      case ScopeKind.lineControllerDatasetOptions:
        return null;
      case ScopeKind.bubbleControllerDatasetOptions:
        return null;
      case ScopeKind.doughnutControllerDatasetOptions:
        return null;
      case ScopeKind.polarAreaControllerDatasetOptions:
        return null;
      case ScopeKind.radarControllerDatasetOptions:
        return null;
      case ScopeKind.genericDatasetOptions:
        return null;
      case ScopeKind.scaleOptions:
        return null;
      case ScopeKind.scalePosition:
        return null;
      case ScopeKind.tickOptions:
        return null;
      case ScopeKind.majorTickOptions:
        return null;
      case ScopeKind.minorTickOptions:
        return null;
      case ScopeKind.gridLineOptions:
        return null;
      case ScopeKind.borderOptions:
        return null;
      case ScopeKind.scaleTitleOptions:
        return null;
      case ScopeKind.timeScaleTimeOptions:
        return null;
      case ScopeKind.displayFormats:
        return null;
      case ScopeKind.angleLineOptions:
        return null;
      case ScopeKind.pointLabelOptions:
        return null;
      case ScopeKind.legendOptions:
        return null;
      case ScopeKind.legendLabelOptions:
        return null;
      case ScopeKind.legendTitleOptions:
        return null;
      case ScopeKind.titleOptions:
        return null;
      case ScopeKind.tooltipOptions:
        return null;
      case ScopeKind.tooltipCallbacks:
        return null;
      case ScopeKind.tooltipDatasetOptions:
        return null;
      case ScopeKind.fillerOptions:
        return null;
      case ScopeKind.decimationOptions:
        return null;
      case ScopeKind.colorsOptions:
        return null;
      case ScopeKind.genericPluginOptions:
        return null;
      case ScopeKind.descriptors:
        return ScopeKind.descriptors;
    }
  }

  /// The cell of the raw JS value [raw] for a key that the kind does not
  /// declare, by the shape `others`.
  Opt<Object?> classifyOther(Object? raw) {
    switch (this) {
      case ScopeKind.chartConfiguration:
        return classifyUnion(raw, 64);
      case ScopeKind.chartData:
        return classifyUnion(raw, 64);
      case ScopeKind.chartOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.pluginOptionsByType:
        return classifyUnion(raw, 34);
      case ScopeKind.elementOptionsByType:
        return classifyScope<GenericElementOptionsScope>(raw);
      case ScopeKind.datasetOptionsByType:
        return classifyScope<GenericDatasetOptionsScope>(raw);
      case ScopeKind.overridesByType:
        return classifyScope<ChartOptionsScope>(raw);
      case ScopeKind.scaleOptionsById:
        return classifyScope<ScaleOptionsScope>(raw);
      case ScopeKind.animationsSpec:
        return classifyUnion(raw, 34);
      case ScopeKind.transitionsSpec:
        return classifyScope<TransitionOptionsScope>(raw);
      case ScopeKind.transitionOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.animationOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.fontSpec:
        return classifyUnion(raw, 64);
      case ScopeKind.padding:
        return classifyUnion(raw, 64);
      case ScopeKind.layoutOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.interactionOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.parsingOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.chartArea:
        return classifyUnion(raw, 64);
      case ScopeKind.pointOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.lineOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.barOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.arcOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.genericElementOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.borderRadius:
        return classifyUnion(raw, 64);
      case ScopeKind.fillTarget:
        return classifyUnion(raw, 64);
      case ScopeKind.segmentOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.barControllerDatasetOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.lineControllerDatasetOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.bubbleControllerDatasetOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.doughnutControllerDatasetOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.polarAreaControllerDatasetOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.radarControllerDatasetOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.genericDatasetOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.scaleOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.scalePosition:
        return classifyNumber(raw);
      case ScopeKind.tickOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.majorTickOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.minorTickOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.gridLineOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.borderOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.scaleTitleOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.timeScaleTimeOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.displayFormats:
        return classifyString(raw);
      case ScopeKind.angleLineOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.pointLabelOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.legendOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.legendLabelOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.legendTitleOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.titleOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.tooltipOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.tooltipCallbacks:
        return classifyUnion(raw, 64);
      case ScopeKind.tooltipDatasetOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.fillerOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.decimationOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.colorsOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.genericPluginOptions:
        return classifyUnion(raw, 64);
      case ScopeKind.descriptors:
        return classifyScope<DescriptorsScope>(raw);
    }
  }
}
