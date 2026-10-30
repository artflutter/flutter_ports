// Original code, not ported from Chart.js: generated from tool/options_schema.yaml by tool/options_gen.dart.
// Do not edit. Edit tool/options_schema.yaml and run
// `dart run melos run options:gen` (Chart.js ADR 0054 §2).

/// The option keys of the typed internal model (Chart.js ADR 0054 §2):
/// one entry for each distinct key name of `tool/options_schema.yaml`.
/// A name that is not here stays a `String` (an extra of its scope).
///
/// This library is a pure layer.
library;

/// An option key by its JS name.
enum OptionKey {
  /// The key `$animations`.
  dollarAnimations(r'$animations'),

  /// The key `$backgroundColors`.
  dollarBackgroundColors(r'$backgroundColors'),

  /// The key `$borderColors`.
  dollarBorderColors(r'$borderColors'),

  /// The key `$shared`.
  dollarShared(r'$shared'),

  /// The key `$theme`.
  dollarTheme(r'$theme'),

  /// The key `_allKeys`.
  descAllKeys('_allKeys'),

  /// The key `_fallback`.
  descFallback('_fallback'),

  /// The key `_indexable`.
  descIndexable('_indexable'),

  /// The key `_scriptable`.
  descScriptable('_scriptable'),

  /// The key `above`.
  above('above'),

  /// The key `active`.
  active('active'),

  /// The key `adapters`.
  adapters('adapters'),

  /// The key `afterBody`.
  afterBody('afterBody'),

  /// The key `afterBuildTicks`.
  afterBuildTicks('afterBuildTicks'),

  /// The key `afterCalculateLabelRotation`.
  afterCalculateLabelRotation('afterCalculateLabelRotation'),

  /// The key `afterDataLimits`.
  afterDataLimits('afterDataLimits'),

  /// The key `afterFit`.
  afterFit('afterFit'),

  /// The key `afterFooter`.
  afterFooter('afterFooter'),

  /// The key `afterLabel`.
  afterLabel('afterLabel'),

  /// The key `afterSetDimensions`.
  afterSetDimensions('afterSetDimensions'),

  /// The key `afterTickToLabelConversion`.
  afterTickToLabelConversion('afterTickToLabelConversion'),

  /// The key `afterTitle`.
  afterTitle('afterTitle'),

  /// The key `afterUpdate`.
  afterUpdate('afterUpdate'),

  /// The key `algorithm`.
  algorithm('algorithm'),

  /// The key `align`.
  align('align'),

  /// The key `alignToPixels`.
  alignToPixels('alignToPixels'),

  /// The key `angle`.
  angle('angle'),

  /// The key `angleLines`.
  angleLines('angleLines'),

  /// The key `animate`.
  animate('animate'),

  /// The key `animateRotate`.
  animateRotate('animateRotate'),

  /// The key `animateScale`.
  animateScale('animateScale'),

  /// The key `animation`.
  animation('animation'),

  /// The key `animations`.
  animations('animations'),

  /// The key `arc`.
  arc('arc'),

  /// The key `aspectRatio`.
  aspectRatio('aspectRatio'),

  /// The key `autoPadding`.
  autoPadding('autoPadding'),

  /// The key `autoSkip`.
  autoSkip('autoSkip'),

  /// The key `autoSkipPadding`.
  autoSkipPadding('autoSkipPadding'),

  /// The key `axis`.
  axis('axis'),

  /// The key `backdropColor`.
  backdropColor('backdropColor'),

  /// The key `backdropPadding`.
  backdropPadding('backdropPadding'),

  /// The key `backgroundColor`.
  backgroundColor('backgroundColor'),

  /// The key `bar`.
  bar('bar'),

  /// The key `barPercentage`.
  barPercentage('barPercentage'),

  /// The key `barThickness`.
  barThickness('barThickness'),

  /// The key `base`.
  base('base'),

  /// The key `beforeBody`.
  beforeBody('beforeBody'),

  /// The key `beforeBuildTicks`.
  beforeBuildTicks('beforeBuildTicks'),

  /// The key `beforeCalculateLabelRotation`.
  beforeCalculateLabelRotation('beforeCalculateLabelRotation'),

  /// The key `beforeDataLimits`.
  beforeDataLimits('beforeDataLimits'),

  /// The key `beforeFit`.
  beforeFit('beforeFit'),

  /// The key `beforeFooter`.
  beforeFooter('beforeFooter'),

  /// The key `beforeLabel`.
  beforeLabel('beforeLabel'),

  /// The key `beforeSetDimensions`.
  beforeSetDimensions('beforeSetDimensions'),

  /// The key `beforeTickToLabelConversion`.
  beforeTickToLabelConversion('beforeTickToLabelConversion'),

  /// The key `beforeTitle`.
  beforeTitle('beforeTitle'),

  /// The key `beforeUpdate`.
  beforeUpdate('beforeUpdate'),

  /// The key `beginAtZero`.
  beginAtZero('beginAtZero'),

  /// The key `below`.
  below('below'),

  /// The key `bodyAlign`.
  bodyAlign('bodyAlign'),

  /// The key `bodyColor`.
  bodyColor('bodyColor'),

  /// The key `bodyFont`.
  bodyFont('bodyFont'),

  /// The key `bodySpacing`.
  bodySpacing('bodySpacing'),

  /// The key `border`.
  border('border'),

  /// The key `borderAlign`.
  borderAlign('borderAlign'),

  /// The key `borderCapStyle`.
  borderCapStyle('borderCapStyle'),

  /// The key `borderColor`.
  borderColor('borderColor'),

  /// The key `borderDash`.
  borderDash('borderDash'),

  /// The key `borderDashOffset`.
  borderDashOffset('borderDashOffset'),

  /// The key `borderJoinStyle`.
  borderJoinStyle('borderJoinStyle'),

  /// The key `borderRadius`.
  borderRadius('borderRadius'),

  /// The key `borderSkipped`.
  borderSkipped('borderSkipped'),

  /// The key `borderWidth`.
  borderWidth('borderWidth'),

  /// The key `bottom`.
  bottom('bottom'),

  /// The key `bottomLeft`.
  bottomLeft('bottomLeft'),

  /// The key `bottomRight`.
  bottomRight('bottomRight'),

  /// The key `bounds`.
  bounds('bounds'),

  /// The key `boxHeight`.
  boxHeight('boxHeight'),

  /// The key `boxPadding`.
  boxPadding('boxPadding'),

  /// The key `boxWidth`.
  boxWidth('boxWidth'),

  /// The key `bubble`.
  bubble('bubble'),

  /// The key `callback`.
  callback('callback'),

  /// The key `callbacks`.
  callbacks('callbacks'),

  /// The key `capBezierPoints`.
  capBezierPoints('capBezierPoints'),

  /// The key `caretPadding`.
  caretPadding('caretPadding'),

  /// The key `caretSize`.
  caretSize('caretSize'),

  /// The key `categoryPercentage`.
  categoryPercentage('categoryPercentage'),

  /// The key `centerPointLabels`.
  centerPointLabels('centerPointLabels'),

  /// The key `circular`.
  circular('circular'),

  /// The key `circumference`.
  circumference('circumference'),

  /// The key `clip`.
  clip('clip'),

  /// The key `color`.
  color('color'),

  /// The key `colors`.
  colors('colors'),

  /// The key `cornerRadius`.
  cornerRadius('cornerRadius'),

  /// The key `count`.
  count('count'),

  /// The key `crossAlign`.
  crossAlign('crossAlign'),

  /// The key `cubicInterpolationMode`.
  cubicInterpolationMode('cubicInterpolationMode'),

  /// The key `cutout`.
  cutout('cutout'),

  /// The key `cutoutPercentage`.
  cutoutPercentage('cutoutPercentage'),

  /// The key `dash`.
  dash('dash'),

  /// The key `dashOffset`.
  dashOffset('dashOffset'),

  /// The key `data`.
  data('data'),

  /// The key `dataElementType`.
  dataElementType('dataElementType'),

  /// The key `datasetElementType`.
  datasetElementType('datasetElementType'),

  /// The key `datasets`.
  datasets('datasets'),

  /// The key `datetime`.
  datetime('datetime'),

  /// The key `day`.
  day('day'),

  /// The key `decimation`.
  decimation('decimation'),

  /// The key `delay`.
  delay('delay'),

  /// The key `devicePixelRatio`.
  devicePixelRatio('devicePixelRatio'),

  /// The key `display`.
  display('display'),

  /// The key `displayColors`.
  displayColors('displayColors'),

  /// The key `displayFormats`.
  displayFormats('displayFormats'),

  /// The key `doughnut`.
  doughnut('doughnut'),

  /// The key `drawActiveElementsOnTop`.
  drawActiveElementsOnTop('drawActiveElementsOnTop'),

  /// The key `drawOnChartArea`.
  drawOnChartArea('drawOnChartArea'),

  /// The key `drawTicks`.
  drawTicks('drawTicks'),

  /// The key `drawTime`.
  drawTime('drawTime'),

  /// The key `duration`.
  duration('duration'),

  /// The key `easing`.
  easing('easing'),

  /// The key `elements`.
  elements('elements'),

  /// The key `enabled`.
  enabled('enabled'),

  /// The key `events`.
  events('events'),

  /// The key `external`.
  external('external'),

  /// The key `family`.
  family('family'),

  /// The key `fill`.
  fill('fill'),

  /// The key `filler`.
  filler('filler'),

  /// The key `filter`.
  filter('filter'),

  /// The key `fn`.
  fn('fn'),

  /// The key `font`.
  font('font'),

  /// The key `footer`.
  footer('footer'),

  /// The key `footerAlign`.
  footerAlign('footerAlign'),

  /// The key `footerColor`.
  footerColor('footerColor'),

  /// The key `footerFont`.
  footerFont('footerFont'),

  /// The key `footerMarginTop`.
  footerMarginTop('footerMarginTop'),

  /// The key `footerSpacing`.
  footerSpacing('footerSpacing'),

  /// The key `forceOverride`.
  forceOverride('forceOverride'),

  /// The key `format`.
  format('format'),

  /// The key `from`.
  from('from'),

  /// The key `fullSize`.
  fullSize('fullSize'),

  /// The key `generateLabels`.
  generateLabels('generateLabels'),

  /// The key `grace`.
  grace('grace'),

  /// The key `grid`.
  grid('grid'),

  /// The key `grouped`.
  grouped('grouped'),

  /// The key `hidden`.
  hidden('hidden'),

  /// The key `hide`.
  hide('hide'),

  /// The key `hitRadius`.
  hitRadius('hitRadius'),

  /// The key `hour`.
  hour('hour'),

  /// The key `hover`.
  hover('hover'),

  /// The key `hoverBackgroundColor`.
  hoverBackgroundColor('hoverBackgroundColor'),

  /// The key `hoverBorderCapStyle`.
  hoverBorderCapStyle('hoverBorderCapStyle'),

  /// The key `hoverBorderColor`.
  hoverBorderColor('hoverBorderColor'),

  /// The key `hoverBorderDash`.
  hoverBorderDash('hoverBorderDash'),

  /// The key `hoverBorderDashOffset`.
  hoverBorderDashOffset('hoverBorderDashOffset'),

  /// The key `hoverBorderJoinStyle`.
  hoverBorderJoinStyle('hoverBorderJoinStyle'),

  /// The key `hoverBorderRadius`.
  hoverBorderRadius('hoverBorderRadius'),

  /// The key `hoverBorderWidth`.
  hoverBorderWidth('hoverBorderWidth'),

  /// The key `hoverColor`.
  hoverColor('hoverColor'),

  /// The key `hoverOffset`.
  hoverOffset('hoverOffset'),

  /// The key `hoverRadius`.
  hoverRadius('hoverRadius'),

  /// The key `id`.
  id('id'),

  /// The key `includeBounds`.
  includeBounds('includeBounds'),

  /// The key `includeInvisible`.
  includeInvisible('includeInvisible'),

  /// The key `indexAxis`.
  indexAxis('indexAxis'),

  /// The key `inflateAmount`.
  inflateAmount('inflateAmount'),

  /// The key `innerEnd`.
  innerEnd('innerEnd'),

  /// The key `innerStart`.
  innerStart('innerStart'),

  /// The key `interaction`.
  interaction('interaction'),

  /// The key `intersect`.
  intersect('intersect'),

  /// The key `isoWeekday`.
  isoWeekday('isoWeekday'),

  /// The key `itemSort`.
  itemSort('itemSort'),

  /// The key `key`.
  key('key'),

  /// The key `label`.
  label('label'),

  /// The key `labelColor`.
  labelColor('labelColor'),

  /// The key `labelOffset`.
  labelOffset('labelOffset'),

  /// The key `labelPointStyle`.
  labelPointStyle('labelPointStyle'),

  /// The key `labelTextColor`.
  labelTextColor('labelTextColor'),

  /// The key `labels`.
  labels('labels'),

  /// The key `layout`.
  layout('layout'),

  /// The key `left`.
  left('left'),

  /// The key `legend`.
  legend('legend'),

  /// The key `line`.
  line('line'),

  /// The key `lineHeight`.
  lineHeight('lineHeight'),

  /// The key `lineWidth`.
  lineWidth('lineWidth'),

  /// The key `locale`.
  locale('locale'),

  /// The key `loop`.
  loop('loop'),

  /// The key `maintainAspectRatio`.
  maintainAspectRatio('maintainAspectRatio'),

  /// The key `major`.
  major('major'),

  /// The key `max`.
  max('max'),

  /// The key `maxBarThickness`.
  maxBarThickness('maxBarThickness'),

  /// The key `maxHeight`.
  maxHeight('maxHeight'),

  /// The key `maxRotation`.
  maxRotation('maxRotation'),

  /// The key `maxTicksLimit`.
  maxTicksLimit('maxTicksLimit'),

  /// The key `maxWidth`.
  maxWidth('maxWidth'),

  /// The key `millisecond`.
  millisecond('millisecond'),

  /// The key `min`.
  min('min'),

  /// The key `minBarLength`.
  minBarLength('minBarLength'),

  /// The key `minRotation`.
  minRotation('minRotation'),

  /// The key `minUnit`.
  minUnit('minUnit'),

  /// The key `minor`.
  minor('minor'),

  /// The key `minute`.
  minute('minute'),

  /// The key `mirror`.
  mirror('mirror'),

  /// The key `mode`.
  mode('mode'),

  /// The key `month`.
  month('month'),

  /// The key `multiKeyBackground`.
  multiKeyBackground('multiKeyBackground'),

  /// The key `normalized`.
  normalized('normalized'),

  /// The key `numbers`.
  numbers('numbers'),

  /// The key `offset`.
  offset('offset'),

  /// The key `offsetAfterAutoskip`.
  offsetAfterAutoskip('offsetAfterAutoskip'),

  /// The key `onClick`.
  onClick('onClick'),

  /// The key `onComplete`.
  onComplete('onComplete'),

  /// The key `onHover`.
  onHover('onHover'),

  /// The key `onLeave`.
  onLeave('onLeave'),

  /// The key `onProgress`.
  onProgress('onProgress'),

  /// The key `onResize`.
  onResize('onResize'),

  /// The key `opacity`.
  opacity('opacity'),

  /// The key `options`.
  options('options'),

  /// The key `order`.
  order('order'),

  /// The key `outerEnd`.
  outerEnd('outerEnd'),

  /// The key `outerStart`.
  outerStart('outerStart'),

  /// The key `padding`.
  padding('padding'),

  /// The key `parser`.
  parser('parser'),

  /// The key `parsing`.
  parsing('parsing'),

  /// The key `pie`.
  pie('pie'),

  /// The key `platform`.
  platform('platform'),

  /// The key `plugins`.
  plugins('plugins'),

  /// The key `point`.
  point('point'),

  /// The key `pointBackgroundColor`.
  pointBackgroundColor('pointBackgroundColor'),

  /// The key `pointBorderColor`.
  pointBorderColor('pointBorderColor'),

  /// The key `pointBorderWidth`.
  pointBorderWidth('pointBorderWidth'),

  /// The key `pointHitRadius`.
  pointHitRadius('pointHitRadius'),

  /// The key `pointHoverBackgroundColor`.
  pointHoverBackgroundColor('pointHoverBackgroundColor'),

  /// The key `pointHoverBorderColor`.
  pointHoverBorderColor('pointHoverBorderColor'),

  /// The key `pointHoverBorderWidth`.
  pointHoverBorderWidth('pointHoverBorderWidth'),

  /// The key `pointHoverRadius`.
  pointHoverRadius('pointHoverRadius'),

  /// The key `pointLabels`.
  pointLabels('pointLabels'),

  /// The key `pointRadius`.
  pointRadius('pointRadius'),

  /// The key `pointRotation`.
  pointRotation('pointRotation'),

  /// The key `pointStyle`.
  pointStyle('pointStyle'),

  /// The key `pointStyleWidth`.
  pointStyleWidth('pointStyleWidth'),

  /// The key `polarArea`.
  polarArea('polarArea'),

  /// The key `position`.
  position('position'),

  /// The key `precision`.
  precision('precision'),

  /// The key `propagate`.
  propagate('propagate'),

  /// The key `properties`.
  properties('properties'),

  /// The key `quarter`.
  quarter('quarter'),

  /// The key `rAxisID`.
  rAxisID('rAxisID'),

  /// The key `radar`.
  radar('radar'),

  /// The key `radius`.
  radius('radius'),

  /// The key `reset`.
  reset('reset'),

  /// The key `resize`.
  resize('resize'),

  /// The key `resizeDelay`.
  resizeDelay('resizeDelay'),

  /// The key `responsive`.
  responsive('responsive'),

  /// The key `reverse`.
  reverse('reverse'),

  /// The key `right`.
  right('right'),

  /// The key `rotation`.
  rotation('rotation'),

  /// The key `round`.
  round('round'),

  /// The key `rtl`.
  rtl('rtl'),

  /// The key `sampleSize`.
  sampleSize('sampleSize'),

  /// The key `samples`.
  samples('samples'),

  /// The key `scale`.
  scale('scale'),

  /// The key `scales`.
  scales('scales'),

  /// The key `scatter`.
  scatter('scatter'),

  /// The key `second`.
  second('second'),

  /// The key `segment`.
  segment('segment'),

  /// The key `selfJoin`.
  selfJoin('selfJoin'),

  /// The key `show`.
  show('show'),

  /// The key `showLabelBackdrop`.
  showLabelBackdrop('showLabelBackdrop'),

  /// The key `showLine`.
  showLine('showLine'),

  /// The key `size`.
  size('size'),

  /// The key `skipNull`.
  skipNull('skipNull'),

  /// The key `sort`.
  sort('sort'),

  /// The key `source`.
  source('source'),

  /// The key `spacing`.
  spacing('spacing'),

  /// The key `spacingMode`.
  spacingMode('spacingMode'),

  /// The key `spanGaps`.
  spanGaps('spanGaps'),

  /// The key `stack`.
  stack('stack'),

  /// The key `stackWeight`.
  stackWeight('stackWeight'),

  /// The key `stacked`.
  stacked('stacked'),

  /// The key `startAngle`.
  startAngle('startAngle'),

  /// The key `stepSize`.
  stepSize('stepSize'),

  /// The key `stepped`.
  stepped('stepped'),

  /// The key `strokeColor`.
  strokeColor('strokeColor'),

  /// The key `strokeWidth`.
  strokeWidth('strokeWidth'),

  /// The key `style`.
  style('style'),

  /// The key `subtitle`.
  subtitle('subtitle'),

  /// The key `suggestedMax`.
  suggestedMax('suggestedMax'),

  /// The key `suggestedMin`.
  suggestedMin('suggestedMin'),

  /// The key `target`.
  target('target'),

  /// The key `tension`.
  tension('tension'),

  /// The key `text`.
  text('text'),

  /// The key `textAlign`.
  textAlign('textAlign'),

  /// The key `textDirection`.
  textDirection('textDirection'),

  /// The key `textStrokeColor`.
  textStrokeColor('textStrokeColor'),

  /// The key `textStrokeWidth`.
  textStrokeWidth('textStrokeWidth'),

  /// The key `threshold`.
  threshold('threshold'),

  /// The key `tickBorderDash`.
  tickBorderDash('tickBorderDash'),

  /// The key `tickBorderDashOffset`.
  tickBorderDashOffset('tickBorderDashOffset'),

  /// The key `tickColor`.
  tickColor('tickColor'),

  /// The key `tickLength`.
  tickLength('tickLength'),

  /// The key `tickWidth`.
  tickWidth('tickWidth'),

  /// The key `ticks`.
  ticks('ticks'),

  /// The key `time`.
  time('time'),

  /// The key `title`.
  title('title'),

  /// The key `titleAlign`.
  titleAlign('titleAlign'),

  /// The key `titleColor`.
  titleColor('titleColor'),

  /// The key `titleFont`.
  titleFont('titleFont'),

  /// The key `titleMarginBottom`.
  titleMarginBottom('titleMarginBottom'),

  /// The key `titleSpacing`.
  titleSpacing('titleSpacing'),

  /// The key `to`.
  to('to'),

  /// The key `tooltip`.
  tooltip('tooltip'),

  /// The key `tooltipFormat`.
  tooltipFormat('tooltipFormat'),

  /// The key `top`.
  top('top'),

  /// The key `topLeft`.
  topLeft('topLeft'),

  /// The key `topRight`.
  topRight('topRight'),

  /// The key `transitions`.
  transitions('transitions'),

  /// The key `type`.
  type('type'),

  /// The key `unit`.
  unit('unit'),

  /// The key `useBorderRadius`.
  useBorderRadius('useBorderRadius'),

  /// The key `usePointStyle`.
  usePointStyle('usePointStyle'),

  /// The key `value`.
  value('value'),

  /// The key `visible`.
  visible('visible'),

  /// The key `week`.
  week('week'),

  /// The key `weight`.
  weight('weight'),

  /// The key `width`.
  width('width'),

  /// The key `x`.
  x('x'),

  /// The key `xAlign`.
  xAlign('xAlign'),

  /// The key `xAxisID`.
  xAxisID('xAxisID'),

  /// The key `xAxisKey`.
  xAxisKey('xAxisKey'),

  /// The key `xLabels`.
  xLabels('xLabels'),

  /// The key `y`.
  y('y'),

  /// The key `yAlign`.
  yAlign('yAlign'),

  /// The key `yAxisID`.
  yAxisID('yAxisID'),

  /// The key `yAxisKey`.
  yAxisKey('yAxisKey'),

  /// The key `yLabels`.
  yLabels('yLabels'),

  /// The key `year`.
  year('year'),

  /// The key `z`.
  z('z');

  const OptionKey(this.jsName);

  /// The JS property name.
  final String jsName;
}

/// The [OptionKey] of the JS name [name], or Dart `null` for a name
/// that is not a key of the schema.
OptionKey? optionKeyOf(String name) => switch (name) {
  r'$animations' => OptionKey.dollarAnimations,
  r'$backgroundColors' => OptionKey.dollarBackgroundColors,
  r'$borderColors' => OptionKey.dollarBorderColors,
  r'$shared' => OptionKey.dollarShared,
  r'$theme' => OptionKey.dollarTheme,
  '_allKeys' => OptionKey.descAllKeys,
  '_fallback' => OptionKey.descFallback,
  '_indexable' => OptionKey.descIndexable,
  '_scriptable' => OptionKey.descScriptable,
  'above' => OptionKey.above,
  'active' => OptionKey.active,
  'adapters' => OptionKey.adapters,
  'afterBody' => OptionKey.afterBody,
  'afterBuildTicks' => OptionKey.afterBuildTicks,
  'afterCalculateLabelRotation' => OptionKey.afterCalculateLabelRotation,
  'afterDataLimits' => OptionKey.afterDataLimits,
  'afterFit' => OptionKey.afterFit,
  'afterFooter' => OptionKey.afterFooter,
  'afterLabel' => OptionKey.afterLabel,
  'afterSetDimensions' => OptionKey.afterSetDimensions,
  'afterTickToLabelConversion' => OptionKey.afterTickToLabelConversion,
  'afterTitle' => OptionKey.afterTitle,
  'afterUpdate' => OptionKey.afterUpdate,
  'algorithm' => OptionKey.algorithm,
  'align' => OptionKey.align,
  'alignToPixels' => OptionKey.alignToPixels,
  'angle' => OptionKey.angle,
  'angleLines' => OptionKey.angleLines,
  'animate' => OptionKey.animate,
  'animateRotate' => OptionKey.animateRotate,
  'animateScale' => OptionKey.animateScale,
  'animation' => OptionKey.animation,
  'animations' => OptionKey.animations,
  'arc' => OptionKey.arc,
  'aspectRatio' => OptionKey.aspectRatio,
  'autoPadding' => OptionKey.autoPadding,
  'autoSkip' => OptionKey.autoSkip,
  'autoSkipPadding' => OptionKey.autoSkipPadding,
  'axis' => OptionKey.axis,
  'backdropColor' => OptionKey.backdropColor,
  'backdropPadding' => OptionKey.backdropPadding,
  'backgroundColor' => OptionKey.backgroundColor,
  'bar' => OptionKey.bar,
  'barPercentage' => OptionKey.barPercentage,
  'barThickness' => OptionKey.barThickness,
  'base' => OptionKey.base,
  'beforeBody' => OptionKey.beforeBody,
  'beforeBuildTicks' => OptionKey.beforeBuildTicks,
  'beforeCalculateLabelRotation' => OptionKey.beforeCalculateLabelRotation,
  'beforeDataLimits' => OptionKey.beforeDataLimits,
  'beforeFit' => OptionKey.beforeFit,
  'beforeFooter' => OptionKey.beforeFooter,
  'beforeLabel' => OptionKey.beforeLabel,
  'beforeSetDimensions' => OptionKey.beforeSetDimensions,
  'beforeTickToLabelConversion' => OptionKey.beforeTickToLabelConversion,
  'beforeTitle' => OptionKey.beforeTitle,
  'beforeUpdate' => OptionKey.beforeUpdate,
  'beginAtZero' => OptionKey.beginAtZero,
  'below' => OptionKey.below,
  'bodyAlign' => OptionKey.bodyAlign,
  'bodyColor' => OptionKey.bodyColor,
  'bodyFont' => OptionKey.bodyFont,
  'bodySpacing' => OptionKey.bodySpacing,
  'border' => OptionKey.border,
  'borderAlign' => OptionKey.borderAlign,
  'borderCapStyle' => OptionKey.borderCapStyle,
  'borderColor' => OptionKey.borderColor,
  'borderDash' => OptionKey.borderDash,
  'borderDashOffset' => OptionKey.borderDashOffset,
  'borderJoinStyle' => OptionKey.borderJoinStyle,
  'borderRadius' => OptionKey.borderRadius,
  'borderSkipped' => OptionKey.borderSkipped,
  'borderWidth' => OptionKey.borderWidth,
  'bottom' => OptionKey.bottom,
  'bottomLeft' => OptionKey.bottomLeft,
  'bottomRight' => OptionKey.bottomRight,
  'bounds' => OptionKey.bounds,
  'boxHeight' => OptionKey.boxHeight,
  'boxPadding' => OptionKey.boxPadding,
  'boxWidth' => OptionKey.boxWidth,
  'bubble' => OptionKey.bubble,
  'callback' => OptionKey.callback,
  'callbacks' => OptionKey.callbacks,
  'capBezierPoints' => OptionKey.capBezierPoints,
  'caretPadding' => OptionKey.caretPadding,
  'caretSize' => OptionKey.caretSize,
  'categoryPercentage' => OptionKey.categoryPercentage,
  'centerPointLabels' => OptionKey.centerPointLabels,
  'circular' => OptionKey.circular,
  'circumference' => OptionKey.circumference,
  'clip' => OptionKey.clip,
  'color' => OptionKey.color,
  'colors' => OptionKey.colors,
  'cornerRadius' => OptionKey.cornerRadius,
  'count' => OptionKey.count,
  'crossAlign' => OptionKey.crossAlign,
  'cubicInterpolationMode' => OptionKey.cubicInterpolationMode,
  'cutout' => OptionKey.cutout,
  'cutoutPercentage' => OptionKey.cutoutPercentage,
  'dash' => OptionKey.dash,
  'dashOffset' => OptionKey.dashOffset,
  'data' => OptionKey.data,
  'dataElementType' => OptionKey.dataElementType,
  'datasetElementType' => OptionKey.datasetElementType,
  'datasets' => OptionKey.datasets,
  'datetime' => OptionKey.datetime,
  'day' => OptionKey.day,
  'decimation' => OptionKey.decimation,
  'delay' => OptionKey.delay,
  'devicePixelRatio' => OptionKey.devicePixelRatio,
  'display' => OptionKey.display,
  'displayColors' => OptionKey.displayColors,
  'displayFormats' => OptionKey.displayFormats,
  'doughnut' => OptionKey.doughnut,
  'drawActiveElementsOnTop' => OptionKey.drawActiveElementsOnTop,
  'drawOnChartArea' => OptionKey.drawOnChartArea,
  'drawTicks' => OptionKey.drawTicks,
  'drawTime' => OptionKey.drawTime,
  'duration' => OptionKey.duration,
  'easing' => OptionKey.easing,
  'elements' => OptionKey.elements,
  'enabled' => OptionKey.enabled,
  'events' => OptionKey.events,
  'external' => OptionKey.external,
  'family' => OptionKey.family,
  'fill' => OptionKey.fill,
  'filler' => OptionKey.filler,
  'filter' => OptionKey.filter,
  'fn' => OptionKey.fn,
  'font' => OptionKey.font,
  'footer' => OptionKey.footer,
  'footerAlign' => OptionKey.footerAlign,
  'footerColor' => OptionKey.footerColor,
  'footerFont' => OptionKey.footerFont,
  'footerMarginTop' => OptionKey.footerMarginTop,
  'footerSpacing' => OptionKey.footerSpacing,
  'forceOverride' => OptionKey.forceOverride,
  'format' => OptionKey.format,
  'from' => OptionKey.from,
  'fullSize' => OptionKey.fullSize,
  'generateLabels' => OptionKey.generateLabels,
  'grace' => OptionKey.grace,
  'grid' => OptionKey.grid,
  'grouped' => OptionKey.grouped,
  'hidden' => OptionKey.hidden,
  'hide' => OptionKey.hide,
  'hitRadius' => OptionKey.hitRadius,
  'hour' => OptionKey.hour,
  'hover' => OptionKey.hover,
  'hoverBackgroundColor' => OptionKey.hoverBackgroundColor,
  'hoverBorderCapStyle' => OptionKey.hoverBorderCapStyle,
  'hoverBorderColor' => OptionKey.hoverBorderColor,
  'hoverBorderDash' => OptionKey.hoverBorderDash,
  'hoverBorderDashOffset' => OptionKey.hoverBorderDashOffset,
  'hoverBorderJoinStyle' => OptionKey.hoverBorderJoinStyle,
  'hoverBorderRadius' => OptionKey.hoverBorderRadius,
  'hoverBorderWidth' => OptionKey.hoverBorderWidth,
  'hoverColor' => OptionKey.hoverColor,
  'hoverOffset' => OptionKey.hoverOffset,
  'hoverRadius' => OptionKey.hoverRadius,
  'id' => OptionKey.id,
  'includeBounds' => OptionKey.includeBounds,
  'includeInvisible' => OptionKey.includeInvisible,
  'indexAxis' => OptionKey.indexAxis,
  'inflateAmount' => OptionKey.inflateAmount,
  'innerEnd' => OptionKey.innerEnd,
  'innerStart' => OptionKey.innerStart,
  'interaction' => OptionKey.interaction,
  'intersect' => OptionKey.intersect,
  'isoWeekday' => OptionKey.isoWeekday,
  'itemSort' => OptionKey.itemSort,
  'key' => OptionKey.key,
  'label' => OptionKey.label,
  'labelColor' => OptionKey.labelColor,
  'labelOffset' => OptionKey.labelOffset,
  'labelPointStyle' => OptionKey.labelPointStyle,
  'labelTextColor' => OptionKey.labelTextColor,
  'labels' => OptionKey.labels,
  'layout' => OptionKey.layout,
  'left' => OptionKey.left,
  'legend' => OptionKey.legend,
  'line' => OptionKey.line,
  'lineHeight' => OptionKey.lineHeight,
  'lineWidth' => OptionKey.lineWidth,
  'locale' => OptionKey.locale,
  'loop' => OptionKey.loop,
  'maintainAspectRatio' => OptionKey.maintainAspectRatio,
  'major' => OptionKey.major,
  'max' => OptionKey.max,
  'maxBarThickness' => OptionKey.maxBarThickness,
  'maxHeight' => OptionKey.maxHeight,
  'maxRotation' => OptionKey.maxRotation,
  'maxTicksLimit' => OptionKey.maxTicksLimit,
  'maxWidth' => OptionKey.maxWidth,
  'millisecond' => OptionKey.millisecond,
  'min' => OptionKey.min,
  'minBarLength' => OptionKey.minBarLength,
  'minRotation' => OptionKey.minRotation,
  'minUnit' => OptionKey.minUnit,
  'minor' => OptionKey.minor,
  'minute' => OptionKey.minute,
  'mirror' => OptionKey.mirror,
  'mode' => OptionKey.mode,
  'month' => OptionKey.month,
  'multiKeyBackground' => OptionKey.multiKeyBackground,
  'normalized' => OptionKey.normalized,
  'numbers' => OptionKey.numbers,
  'offset' => OptionKey.offset,
  'offsetAfterAutoskip' => OptionKey.offsetAfterAutoskip,
  'onClick' => OptionKey.onClick,
  'onComplete' => OptionKey.onComplete,
  'onHover' => OptionKey.onHover,
  'onLeave' => OptionKey.onLeave,
  'onProgress' => OptionKey.onProgress,
  'onResize' => OptionKey.onResize,
  'opacity' => OptionKey.opacity,
  'options' => OptionKey.options,
  'order' => OptionKey.order,
  'outerEnd' => OptionKey.outerEnd,
  'outerStart' => OptionKey.outerStart,
  'padding' => OptionKey.padding,
  'parser' => OptionKey.parser,
  'parsing' => OptionKey.parsing,
  'pie' => OptionKey.pie,
  'platform' => OptionKey.platform,
  'plugins' => OptionKey.plugins,
  'point' => OptionKey.point,
  'pointBackgroundColor' => OptionKey.pointBackgroundColor,
  'pointBorderColor' => OptionKey.pointBorderColor,
  'pointBorderWidth' => OptionKey.pointBorderWidth,
  'pointHitRadius' => OptionKey.pointHitRadius,
  'pointHoverBackgroundColor' => OptionKey.pointHoverBackgroundColor,
  'pointHoverBorderColor' => OptionKey.pointHoverBorderColor,
  'pointHoverBorderWidth' => OptionKey.pointHoverBorderWidth,
  'pointHoverRadius' => OptionKey.pointHoverRadius,
  'pointLabels' => OptionKey.pointLabels,
  'pointRadius' => OptionKey.pointRadius,
  'pointRotation' => OptionKey.pointRotation,
  'pointStyle' => OptionKey.pointStyle,
  'pointStyleWidth' => OptionKey.pointStyleWidth,
  'polarArea' => OptionKey.polarArea,
  'position' => OptionKey.position,
  'precision' => OptionKey.precision,
  'propagate' => OptionKey.propagate,
  'properties' => OptionKey.properties,
  'quarter' => OptionKey.quarter,
  'rAxisID' => OptionKey.rAxisID,
  'radar' => OptionKey.radar,
  'radius' => OptionKey.radius,
  'reset' => OptionKey.reset,
  'resize' => OptionKey.resize,
  'resizeDelay' => OptionKey.resizeDelay,
  'responsive' => OptionKey.responsive,
  'reverse' => OptionKey.reverse,
  'right' => OptionKey.right,
  'rotation' => OptionKey.rotation,
  'round' => OptionKey.round,
  'rtl' => OptionKey.rtl,
  'sampleSize' => OptionKey.sampleSize,
  'samples' => OptionKey.samples,
  'scale' => OptionKey.scale,
  'scales' => OptionKey.scales,
  'scatter' => OptionKey.scatter,
  'second' => OptionKey.second,
  'segment' => OptionKey.segment,
  'selfJoin' => OptionKey.selfJoin,
  'show' => OptionKey.show,
  'showLabelBackdrop' => OptionKey.showLabelBackdrop,
  'showLine' => OptionKey.showLine,
  'size' => OptionKey.size,
  'skipNull' => OptionKey.skipNull,
  'sort' => OptionKey.sort,
  'source' => OptionKey.source,
  'spacing' => OptionKey.spacing,
  'spacingMode' => OptionKey.spacingMode,
  'spanGaps' => OptionKey.spanGaps,
  'stack' => OptionKey.stack,
  'stackWeight' => OptionKey.stackWeight,
  'stacked' => OptionKey.stacked,
  'startAngle' => OptionKey.startAngle,
  'stepSize' => OptionKey.stepSize,
  'stepped' => OptionKey.stepped,
  'strokeColor' => OptionKey.strokeColor,
  'strokeWidth' => OptionKey.strokeWidth,
  'style' => OptionKey.style,
  'subtitle' => OptionKey.subtitle,
  'suggestedMax' => OptionKey.suggestedMax,
  'suggestedMin' => OptionKey.suggestedMin,
  'target' => OptionKey.target,
  'tension' => OptionKey.tension,
  'text' => OptionKey.text,
  'textAlign' => OptionKey.textAlign,
  'textDirection' => OptionKey.textDirection,
  'textStrokeColor' => OptionKey.textStrokeColor,
  'textStrokeWidth' => OptionKey.textStrokeWidth,
  'threshold' => OptionKey.threshold,
  'tickBorderDash' => OptionKey.tickBorderDash,
  'tickBorderDashOffset' => OptionKey.tickBorderDashOffset,
  'tickColor' => OptionKey.tickColor,
  'tickLength' => OptionKey.tickLength,
  'tickWidth' => OptionKey.tickWidth,
  'ticks' => OptionKey.ticks,
  'time' => OptionKey.time,
  'title' => OptionKey.title,
  'titleAlign' => OptionKey.titleAlign,
  'titleColor' => OptionKey.titleColor,
  'titleFont' => OptionKey.titleFont,
  'titleMarginBottom' => OptionKey.titleMarginBottom,
  'titleSpacing' => OptionKey.titleSpacing,
  'to' => OptionKey.to,
  'tooltip' => OptionKey.tooltip,
  'tooltipFormat' => OptionKey.tooltipFormat,
  'top' => OptionKey.top,
  'topLeft' => OptionKey.topLeft,
  'topRight' => OptionKey.topRight,
  'transitions' => OptionKey.transitions,
  'type' => OptionKey.type,
  'unit' => OptionKey.unit,
  'useBorderRadius' => OptionKey.useBorderRadius,
  'usePointStyle' => OptionKey.usePointStyle,
  'value' => OptionKey.value,
  'visible' => OptionKey.visible,
  'week' => OptionKey.week,
  'weight' => OptionKey.weight,
  'width' => OptionKey.width,
  'x' => OptionKey.x,
  'xAlign' => OptionKey.xAlign,
  'xAxisID' => OptionKey.xAxisID,
  'xAxisKey' => OptionKey.xAxisKey,
  'xLabels' => OptionKey.xLabels,
  'y' => OptionKey.y,
  'yAlign' => OptionKey.yAlign,
  'yAxisID' => OptionKey.yAxisID,
  'yAxisKey' => OptionKey.yAxisKey,
  'yLabels' => OptionKey.yLabels,
  'year' => OptionKey.year,
  'z' => OptionKey.z,
  _ => null,
};
