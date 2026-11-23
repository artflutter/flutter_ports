// Ported from Chart.js v4.6.1 src/plugins/plugin.legend.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.legend.js`.
///
/// [Legend] is the layout box of the chart legend. [legend] is the plugin
/// object, the default export of the upstream file and `Legend` of
/// `src/plugins/index.js:4` (Chart.js ADR 0038, section 1). It is a typed
/// `Plugin` (Chart.js ADR 0054 §12) with the upstream keys in the upstream
/// order: `id`, `_element`, `start`, `stop`, `beforeUpdate`, `afterUpdate`,
/// `afterEvent`, `defaults` and `descriptors`.
///
/// Each hook is a private function of the hook type `(types.Chart chart,
/// args, LegendOptions options)` (Chart.js ADR 0150, in place of the
/// upstream parameter counts of Chart.js ADR 0038, section 3): the argument
/// class of its hook, and the [LegendOptions] that the plugin service merged
/// from the defaults to the chart (Chart.js ADR 0193). `chart.legend`
/// is a field of `types.Chart`: Dart `null` stands for JS `undefined` and
/// for the `delete` of `plugin.legend.js:609`.
///
/// The box reads the typed fields of [LegendOptions], [LegendLabelOptions]
/// and `LegendTitleOptions` of `plugin_options.dart`. The `beforeUpdate`
/// hook gives the box the options with the fallbacks of upstream
/// ([_resolvedOptions]): the colors of the chart and the result of
/// `scripted`.
///
/// The fields of the box start as the fields of `Scale` start: NaN for the
/// edges, `maxWidth` and `maxHeight`, the `undefined` sentinel for
/// `position` and `weight`, and `false` for `fullSize` (Chart.js ADR 0038,
/// section 7).
///
/// Legend entries and hit boxes use the native extensible [LegendItem] and
/// [LegendHitBox] contracts. A column size is a Flutter [ui.Size].
///
/// A hidden legend of a built-in slice chart leaves its items pending, and
/// the first read of `legendItems` that can run the build runs it (Chart.js
/// ADRs 0092 and 0099).
///
/// Not a pure layer: it imports `helpers.extras`.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'package:flutter_chartjs_port/chartjs.dart';

export 'package:flutter_chartjs_port/src/types/legend_callbacks.dart';
export 'package:flutter_chartjs_port/src/types/legend_hit_box.dart';
export 'package:flutter_chartjs_port/src/types/legend_item.dart';

/// The legend option `labels.generateLabels` (index.d.ts:2502,
/// plugin.legend.js:105-106): the items of the legend for [chart]
/// (Chart.js ADR 0130). Chart.js also gives the legend as `this`.
typedef LegendLabelsGenerator = List<LegendItem> Function(Chart chart);

/// `Math.SQRT2`.
// DIVERGES(chartjs): adapt-native-legend-item, native item fields and identity.
const double _sqrt2 = 1.4142135623730951;

/// plugin.legend.js:24 `getBoxSize(labelOpts, fontSize)`.
///
/// The destructuring defaults of :25 apply only to `undefined`, not to
/// `null`. index.d.ts types the box sizes as numbers. The port reads each
/// with `ToNumber` ([jsToNumber]). A number gives the upstream result. A
/// string joins in the `+` of upstream (:174, :400), and the port adds its
/// number (differences.md `adapt-legend-number-options`).
({double boxWidth, double boxHeight, double itemHeight}) _getBoxSize(
  LegendLabelOptions labelOpts,
  double fontSize,
) {
  // DIVERGES(chartjs): adapt-legend-number-options, a box size is a number.
  var boxHeight = labelOpts.boxHeight ?? fontSize;
  var boxWidth = labelOpts.boxWidth ?? fontSize;

  if (labelOpts.usePointStyle ?? false) {
    boxHeight = math.min(boxHeight, fontSize);
    boxWidth =
        _truthyNumber(labelOpts.pointStyleWidth) ??
        math.min(boxWidth, fontSize);
  }

  return (
    boxWidth: boxWidth,
    boxHeight: boxHeight,
    itemHeight: math.max(fontSize, boxHeight),
  );
}

/// plugin.legend.js:39 `itemsEqual(a, b)`: `a !== null && b !== null &&
/// a.datasetIndex === b.datasetIndex && a.index === b.index`.
///
/// Both indexes are nullable native integers.
bool _itemsEqual(LegendItem? a, LegendItem? b) =>
    a != null &&
    b != null &&
    a.datasetIndex == b.datasetIndex &&
    a.index == b.index;

/// The `padding` label option (`options.labels.padding`, :161, :192, :235,
/// :289) as a number. index.d.ts types it as a number. A string joins in
/// the `+` of upstream (for example :165, :185 and :209; :197 starts
/// `totalWidth` with the raw value), and the port adds its `ToNumber`
/// (differences.md `adapt-legend-number-options`).
double _labelPadding(LegendLabelOptions labelOpts) =>
    // DIVERGES(chartjs): adapt-legend-number-options, the padding is a number.
    labelOpts.padding ?? double.nan;

/// The number option [value] for a test `value || x` of upstream: Dart
/// `null` for an absent value, 0 and NaN.
double? _truthyNumber(double? value) =>
    value == null || value == 0 || value.isNaN ? null : value;

/// The reads of the options of a box with the upstream value of an absent
/// object: `options.labels || {}` (plugin.legend.js:105) and the reads of
/// the members of `undefined`.
extension on LegendOptions {
  /// `labels`, or the label options of `{}`.
  LegendLabelOptions get labelsOrEmpty => labels ?? const LegendLabelOptions();

  /// `title`, or the title options of `{}`.
  LegendTitleOptions get titleOrEmpty =>
      this.title ?? const LegendTitleOptions();
}

/// The JS operator `===` on two raw values: two numbers compare by value
/// (NaN is not equal to itself, and -0 equals +0), two strings by their code
/// units, and other values by identity.
bool _strictEquals(Object? a, Object? b) {
  if (a is num && b is num) return a.toDouble() == b.toDouble();
  if (a is String && b is String) return a == b;
  return identical(a, b);
}

/// plugin.legend.js:41 `class Legend extends Element`.
///
/// The layout box of the chart legend. `layouts.addBox` gives it the default
/// layer, which calls [draw] (core.layouts.js:301-308).
class Legend(
  ({IChart chart, Object? options, CanvasRenderingContext2D? ctx}) config,
) extends Element implements LegendElement, LayoutItem, TRBL {
  /// plugin.legend.js:46 `constructor(config)`.
  ///
  /// @param {{ ctx: any; options: any; chart: any; }} config
  ///
  /// The upstream `config` object is a record (Chart.js ADR 0038, section
  /// 4). The `construct` closure of [jsClass] reads it from a JS value.
  this {
    final options = config.options;
    assert(
      options == null || options is LegendOptions,
      'The options of the legend are a LegendOptions, not $options.',
    );
    super.options = options is LegendOptions ? options : null;
  }

  /// plugin.legend.js:41 `class Legend` as a value (Chart.js ADR 0020,
  /// section 3).
  ///
  /// Its superclass is [Element.jsClass]. It has no static property. Its
  /// `construct` reads the `config` argument with [_legendConfig].
  static final JsClass jsClass = JsClass(
    'Legend',
    superclass: Element.jsClass,
    construct: (newTarget, args) => Legend(_legendConfig(args)),
  );

  /// plugin.legend.js:49 `_added`. Upstream writes it and never reads it.
  // ignore: unused_field
  final bool _added = false;

  /// plugin.legend.js:52 `legendHitBoxes`: contains hit boxes for each
  /// dataset (in dataset order).
  ///
  /// Each hit box is a native [LegendHitBox] with the geometry: `left`, `top`,
  /// `row`, `width` and `height` for a horizontal legend (:183), `left`,
  /// `top`, `col`, `width` and `height` for a vertical legend (:217).
  /// `index.d.ts` does not declare it. It implements the port-only member
  /// [LegendElement.legendHitBoxes], which the keyboard of `ChartView`
  /// reads (Chart.js ADR 0051, section 2).
  @override
  List<LegendHitBox> legendHitBoxes = [];

  /// plugin.legend.js:57 `_hoveredItem`. Dart `null` stands for JS `null`.
  LegendItem? _hoveredItem;

  /// plugin.legend.js:60 `doughnutMode`: are we in doughnut mode which has
  /// a different data type. Upstream writes it and never reads it.
  bool doughnutMode = false;

  /// plugin.legend.js:62 `chart`. [LegendElement.chart] is a
  /// `types.Chart`, so the constructor takes one (Chart.js ADR 0038,
  /// section 4).
  @override
  final IChart chart = config.chart;

  /// plugin.legend.js:64 `ctx`. Dart `null` stands for JS `undefined`.
  CanvasRenderingContext2D? ctx = config.ctx;

  /// plugin.legend.js:65 `legendItems`. Dart `null` stands for JS
  /// `undefined`, the value before the first [buildLabels].
  ///
  /// The items are native entries, including plugin subclasses.
  ///
  /// [update] and the `afterUpdate` hook can leave the items pending
  /// ([_itemsCanWait], Chart.js ADR 0092). Then the first read that can run
  /// the build runs it ([_buildPendingItems]), and the next reads give the same
  /// List until the next mark. A read that cannot run it gives the last built
  /// items, and the build still waits. A direct [buildLabels] and a write take
  /// the place of a pending build.
  @override
  List<LegendItem>? get legendItems {
    // DIVERGES(chartjs): adapt-hidden-legend-items, the first read builds.
    _buildPendingItems();
    return _legendItems;
  }

  set legendItems(List<LegendItem>? value) {
    // DIVERGES(chartjs): adapt-hidden-legend-items, a write ends the wait.
    _pendingOptions = null;
    _pendingStyles = null;
    _legendItems = value;
  }

  List<LegendItem>? _legendItems;

  /// The options at the mark of a pending build, or Dart `null` when no build
  /// waits. `beforeUpdate` of a next update replaces [options].
  // DIVERGES(chartjs): adapt-hidden-legend-items, no upstream state.
  LegendOptions? _pendingOptions;

  /// The indexed styles of the mark of a pending build, or Dart `null` when
  /// the proof of the mark was a cached entry (Chart.js ADR 0099).
  // DIVERGES(chartjs): adapt-hidden-legend-items, no upstream state.
  _IndexedItemStyles? _pendingStyles;

  /// Whether a build waits for a read of [legendItems] that can run it.
  bool get legendItemsPending => _pendingOptions != null;

  /// plugin.legend.js:66 `columnSizes`: `{width, height}` of each column of
  /// a vertical legend, a Flutter [ui.Size]. Dart `null` stands for JS
  /// `undefined`.
  List<ui.Size>? columnSizes;

  /// plugin.legend.js:67 `lineWidths`: the width of each line of a
  /// horizontal legend. Dart `null` stands for JS `undefined`.
  List<double>? lineWidths;

  /// plugin.legend.js:68 `maxHeight`. NaN stands for JS `undefined`.
  double maxHeight = double.nan;

  /// plugin.legend.js:69 `maxWidth`. NaN stands for JS `undefined`.
  double maxWidth = double.nan;

  /// plugin.legend.js:70 `top`. NaN stands for JS `undefined`.
  @override
  double top = double.nan;

  /// plugin.legend.js:71 `bottom`. NaN stands for JS `undefined`.
  @override
  double bottom = double.nan;

  /// plugin.legend.js:72 `left`. NaN stands for JS `undefined`.
  @override
  double left = double.nan;

  /// plugin.legend.js:73 `right`. NaN stands for JS `undefined`.
  @override
  double right = double.nan;

  /// plugin.legend.js:74 `height`. NaN stands for JS `undefined`.
  @override
  double height = double.nan;

  /// plugin.legend.js:75 `width`. NaN stands for JS `undefined`.
  @override
  double width = double.nan;

  /// plugin.legend.js:76 `_margins`. Dart `null` stands for JS
  /// `undefined`.
  TRBL? _margins;

  /// plugin.legend.js:77 `position`. Dart `null` stands for JS
  /// `undefined`, the start value. `layouts.configure` writes the
  /// `position` option (core.layouts.js:333).
  @override
  LayoutPosition? position;

  /// plugin.legend.js:78 `weight`. Dart `null` stands for JS
  /// `undefined`, the start value.
  @override
  double? weight;

  /// plugin.legend.js:79 `fullSize`. False stands for JS `undefined`, the
  /// start value: the readers test only its truthiness (Chart.js ADR 0038,
  /// section 7).
  @override
  bool fullSize = false;

  /// core.layouts.js:301 `_layers`. Dart `null` stands for JS `undefined`,
  /// the start value: `layouts.addBox` writes the default layer.
  @override
  List<LayoutLayer> Function()? layers;

  /// core.layouts.js:15 `box.axis`. The legend has no axis: Dart `null`
  /// stands for JS `undefined`.
  @override
  ScaleAxis? get axis => null;

  /// plugin.legend.js:63 `options`, the [LegendOptions] of the last hook
  /// (Chart.js ADR 0193): from the `beforeUpdate` hook, with the fallbacks of
  /// [_resolvedOptions].
  ///
  /// [LegendElement.options] is not nullable. Thus the read of a
  /// legend without options throws a [TypeError], as the first member read
  /// of `this.options` throws upstream (Chart.js ADR 0038, section 7).
  // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
  @override
  LegendOptions get options => super.options! as LegendOptions;

  @override
  set options(covariant LegendOptions? value) => super.options = value;

  /// plugin.legend.js:82 `update(maxWidth, maxHeight, margins)`.
  @override
  void update(double maxWidth, double maxHeight, [TRBL? margins]) {
    this.maxWidth = maxWidth;
    this.maxHeight = maxHeight;
    _margins = margins;

    setDimensions();
    // DIVERGES(chartjs): adapt-hidden-legend-items, no build for a hidden box.
    _buildLabelsOrMark(datasetsUpdated: false);
    fit();
  }

  /// The call `this.buildLabels()` of :88 and :625, or the mark of a build that
  /// [legendItems] runs later.
  ///
  /// [datasetsUpdated] is true after `_updateDatasets` of the same update. The
  /// options of the box hold the label color of the update, so a later build
  /// reads no options of the chart.
  // DIVERGES(chartjs): adapt-hidden-legend-items, the build of an unread list.
  void _buildLabelsOrMark({required bool datasetsUpdated}) {
    final options = this.options;
    _markStyles = null;
    final waits = _itemsCanWait(options, datasetsUpdated: datasetsUpdated);
    final styles = _markStyles;
    _markStyles = null;
    // The state that the resolve of each item of the build leaves in its arc.
    if (waits && (styles == null || styles.writeContexts())) {
      _pendingOptions = options;
      _pendingStyles = styles;
    } else {
      // Only the write of a build ends the wait of the last mark. Thus after a
      // build that throws, a read gives the last snapshot of upstream.
      buildLabels();
    }
  }

  /// The indexed styles that the guards of a mark found, for that mark only.
  // DIVERGES(chartjs): adapt-hidden-legend-items, no upstream state.
  _IndexedItemStyles? _markStyles;

  /// Whether a build of the items of this legend with [options] can wait for a
  /// read: nothing in the chart reads the items of a hidden legend ([fit],
  /// [adjustHitBoxes] and [draw] return at `display`), the build runs no user
  /// code, and the box has last built items for a read that cannot run it.
  // DIVERGES(chartjs): adapt-hidden-legend-items, the guards of the mark.
  bool _itemsCanWait(LegendOptions options, {required bool datasetsUpdated}) =>
      _legendItems != null &&
      _buildRunsNoUserCode(
        options,
        atMark: true,
        datasetsUpdated: datasetsUpdated,
      ) &&
      options.display == false;

  /// Whether [buildLabels] with [options] runs no user code and throws nothing.
  ///
  /// The options are one object of values (Chart.js ADR 0193): their reads
  /// run no user code, and they hold the label color of their update. Each
  /// failed test returns at once. The data reads have no cache and add no
  /// meta.
  ///
  /// [atMark] is true at a mark. After it, this function reads no options of
  /// the chart: a new update can have replaced them. See
  /// [_stylesRunNoUserCode] for the style of each item.
  // DIVERGES(chartjs): adapt-hidden-legend-items, the proof of no user code.
  bool _buildRunsNoUserCode(
    LegendOptions options, {
    required bool atMark,
    bool datasetsUpdated = false,
  }) {
    final chart = this.chart;
    if (super.runtimeType != Legend ||
        !nativePointChart(chart) ||
        !identical(chart.legend, this)) {
      return false;
    }
    final labels = options.labels;
    if (labels == null) return false;
    final generator = labels.generateLabels;
    // The generator of this file has one item for each dataset.
    if (identical(generator, _generateLabels)) return false;
    // Native containers: no user getter or List operator runs in a build. The
    // list of the labels is the list of `data.labels`, not of `data.xLabels`.
    final Object labelSource = chart;
    if (labelSource is! CategoryLabelSource) return false;
    final items = labelSource.categoryLabels(null, horizontal: true);
    if (items == null || items.isEmpty) return false;
    final data = chart.data;
    if (!identical(items, optionOf(data, OptionKey.labels))) return false;
    final datasets = optionOf(data, OptionKey.datasets);
    if (!_nativeDatasetLists.contains(datasets.runtimeType) ||
        (datasets! as List<Object?>).isEmpty) {
      return false;
    }
    final Object metaSource = chart;
    if (metaSource is! DatasetMetaSource) return false;
    final controller = metaSource.existingDatasetMeta(0)?.controller;
    // The controller of the first dataset of the last update: after a removal,
    // the controller of another index has its dataset behind it no more.
    if (controller is! DatasetController || controller.index != 0) return false;
    final builtIn = controller.nativeLegendGenerator;
    if (builtIn == null || !identical(builtIn, generator)) return false;
    return _stylesRunNoUserCode(
          controller,
          items.length,
          options,
          atMark: atMark,
          datasetsUpdated: datasetsUpdated,
        ) &&
        labels.filter == null &&
        labels.sort == null;
  }

  /// Whether each `getStyle(i)` of a build with the items of [count] labels
  /// runs no user code. A mark asks for the cached entry of Chart.js ADR 0092,
  /// then for the indexed styles of Chart.js ADR 0099, which it keeps in
  /// [_markStyles]. A read reads no new resolver: it asks the proof of its
  /// mark.
  // DIVERGES(chartjs): adapt-hidden-legend-items, the two proofs.
  bool _stylesRunNoUserCode(
    DatasetController controller,
    int count,
    LegendOptions options, {
    required bool atMark,
    required bool datasetsUpdated,
  }) {
    if (!atMark) {
      final styles = _pendingStyles;
      if (styles != null) return styles.coversRead(controller, count);
    }
    if (_styleReadsRunNoUserCode(
      controller,
      datasetsUpdated: datasetsUpdated,
    )) {
      return true;
    }
    if (!atMark) return false;
    return (_markStyles = _indexedItemStyles(controller, count, options)) !=
        null;
  }

  /// Runs the build that waits, when it can run: with the options of its mark,
  /// as the build of upstream at that point used them, and with the indexed
  /// styles of its mark, as a resolve of that point gives them.
  // DIVERGES(chartjs): adapt-hidden-legend-items, the build at a read.
  void _buildPendingItems() {
    final pending = _pendingOptions;
    if (pending == null || !_buildRunsNoUserCode(pending, atMark: false)) {
      return;
    }
    final current = super.options;
    final styles = _pendingStyles;
    super.options = pending;
    styles?.controller.legendStyles = (
      styles: styles.styles,
      arcCount: styles.arcCount,
    );
    try {
      buildLabels();
    } finally {
      styles?.controller.legendStyles = null;
      super.options = current;
    }
  }

  /// The `stop` hook takes `chart.legend`, which the generators read. A box
  /// that its owner keeps gives the items of the last state: this function
  /// runs a pending build when it can run. Else the box keeps its last built
  /// items.
  // DIVERGES(chartjs): adapt-hidden-legend-items, the last read of a generator.
  void _settleItems() {
    _buildPendingItems();
    _pendingOptions = null;
  }

  /// plugin.legend.js:92 `setDimensions()`.
  ///
  /// Without margins, the read of `_margins.left` throws a [TypeError], as
  /// upstream.
  void setDimensions() {
    if (isHorizontal()) {
      width = maxWidth;
      left = _margins!.left;
      right = width;
    } else {
      height = maxHeight;
      top = _margins!.top;
      bottom = height;
    }
  }

  /// plugin.legend.js:104 `buildLabels()`.
  ///
  /// `generateLabels` gives the List of the items. `filter` and `sort` are
  /// typed functions with no `this` (Chart.js ADR 0130). `sort` is the
  /// stable sort of `Array.prototype.sort` ([jsSort]). `reverse` reverses the
  /// List in place.
  void buildLabels() {
    final opts = options;
    final labelOpts = opts.labelsOrEmpty;
    // DIVERGES(chartjs): adapt-native-callbacks, typed functions.
    final generate = labelOpts.generateLabels;
    assert(
      generate == null || generate is LegendLabelsGenerator,
      'The option generateLabels holds a LegendLabelsGenerator (Chart.js ADR '
      '0130), not $generate.',
    );
    var legendItems = generate is LegendLabelsGenerator
        ? generate(chart as Chart)
        : <LegendItem>[];

    final filter = labelOpts.filter;
    if (filter != null) {
      legendItems = [
        for (final item in legendItems)
          if (filter(item, chart.data)) item,
      ];
    }

    final sort = labelOpts.sort;
    if (sort != null) {
      legendItems = jsSort(legendItems, (a, b) => sort(a, b, chart.data));
    }

    if (opts.reverse ?? false) {
      _reverseInPlace(legendItems);
    }

    this.legendItems = legendItems;
  }

  /// plugin.legend.js:123 `fit()`.
  ///
  /// The legend may not be displayed for a variety of reasons including the
  /// fact that the defaults got set to `false`. When the legend is not
  /// displayed, there are no guarantees that the options are correctly
  /// formatted so we need to bail out as early as possible.
  void fit() {
    final options = this.options;
    final ctx = this.ctx;

    if (!(options.display ?? false)) {
      this.width = this.height = 0;
      return;
    }

    final labelOpts = options.labelsOrEmpty;
    final labelFont = toFont(labelOpts.font);
    final fontSize = labelFont.fontSize!;
    final titleHeight = _computeTitleHeight();
    final (:boxWidth, :boxHeight, :itemHeight) = _getBoxSize(
      labelOpts,
      fontSize,
    );

    double width;
    double height;

    ctx!.font = labelFont;

    if (isHorizontal()) {
      width = maxWidth; // fill all the width
      height = _fitRows(titleHeight, fontSize, boxWidth, itemHeight) + 10;
    } else {
      height = maxHeight; // fill all the height
      width = _fitCols(titleHeight, labelFont, boxWidth, itemHeight) + 10;
    }

    this.width = math.min(width, _truthyNumber(options.maxWidth) ?? maxWidth);
    this.height = math.min(
      height,
      _truthyNumber(options.maxHeight) ?? maxHeight,
    );
  }

  /// plugin.legend.js:160 `_fitRows(titleHeight, fontSize, boxWidth,
  /// itemHeight)`.
  ///
  /// The `padding` label option is a number ([_labelPadding]).
  double _fitRows(
    double titleHeight,
    double fontSize,
    double boxWidth,
    double itemHeight,
  ) {
    final ctx = this.ctx!;
    final maxWidth = this.maxWidth;
    final padding = _labelPadding(options.labelsOrEmpty);
    final hitboxes = legendHitBoxes = [];
    // Width of each line of legend boxes. Labels wrap onto multiple lines
    // when there are too many to fit on one
    final lineWidths = this.lineWidths = [0];
    final lineHeight = itemHeight + padding;
    var totalHeight = titleHeight;

    ctx
      ..textAlign = TextAlign.left
      // DIVERGES(chartjs): adapt-canvas-text-baseline-enum, the enum value.
      ..textBaseline = CanvasTextBaseline.middle;

    var row = -1;
    var top = -lineHeight;
    final legendItems = this.legendItems!;
    for (var i = 0; i < legendItems.length; i++) {
      final legendItem = legendItems[i];
      final itemWidth =
          boxWidth +
          (fontSize / 2) +
          ctx.measureText(jsToString(legendItem.text)).width;

      if (i == 0 || lineWidths.last + itemWidth + 2 * padding > maxWidth) {
        totalHeight += lineHeight;
        if (i > 0) {
          lineWidths.add(0);
        } else {
          lineWidths[lineWidths.length - 1] = 0;
        }
        top += lineHeight;
        row++;
      }

      hitboxes.add(
        LegendHitBox.row(
          left: 0,
          top: top,
          row: row,
          width: itemWidth,
          height: itemHeight,
        ),
      );

      lineWidths[lineWidths.length - 1] += itemWidth + padding;
    }

    return totalHeight;
  }

  /// plugin.legend.js:191 `_fitCols(titleHeight, labelFont, boxWidth,
  /// _itemHeight)`.
  double _fitCols(
    double titleHeight,
    ChartTextStyle labelFont,
    double boxWidth,
    double itemHeight0,
  ) {
    final ctx = this.ctx!;
    final maxHeight = this.maxHeight;
    final padding = _labelPadding(options.labelsOrEmpty);
    final hitboxes = legendHitBoxes = [];
    final columnSizes = this.columnSizes = [];
    final heightLimit = maxHeight - titleHeight;

    var totalWidth = padding;
    var currentColWidth = 0.0;
    var currentColHeight = 0.0;

    var left = 0.0;
    var col = 0;

    final legendItems = this.legendItems!;
    for (var i = 0; i < legendItems.length; i++) {
      final legendItem = legendItems[i];
      final (:itemWidth, :itemHeight) = _calculateItemSize(
        boxWidth,
        labelFont,
        ctx,
        legendItem,
        itemHeight0,
      );

      // If too tall, go to new column
      if (i > 0 && currentColHeight + itemHeight + 2 * padding > heightLimit) {
        totalWidth += currentColWidth + padding;
        // previous column size
        columnSizes.add(ui.Size(currentColWidth, currentColHeight));
        left += currentColWidth + padding;
        col++;
        currentColWidth = currentColHeight = 0;
      }

      // Store the hitbox width and height here. Final position will be
      // updated in `draw`
      hitboxes.add(
        LegendHitBox.col(
          left: left,
          top: currentColHeight,
          col: col,
          width: itemWidth,
          height: itemHeight,
        ),
      );

      // Get max width
      currentColWidth = math.max(currentColWidth, itemWidth);
      currentColHeight += itemHeight + padding;
    }

    totalWidth += currentColWidth;
    // previous column size
    columnSizes.add(ui.Size(currentColWidth, currentColHeight));

    return totalWidth;
  }

  /// plugin.legend.js:230 `adjustHitBoxes()`.
  // DIVERGES(chartjs): adapt-native-legend-hit-box, native mutable geometry.
  void adjustHitBoxes() {
    final options = this.options;
    if (!(options.display ?? false)) {
      return;
    }
    final titleHeight = _computeTitleHeight();
    final hitboxes = legendHitBoxes;
    // DIVERGES(chartjs): adapt-chart-align-enum, the enum value.
    final align = options.align;
    final padding = _labelPadding(options.labelsOrEmpty);
    final rtlHelper = getRtlAdapter(options.rtl ?? false, left, width);
    if (isHorizontal()) {
      var row = 0;
      var left = alignStartEnd(
        align,
        this.left + padding,
        right - _lineWidthAt(row),
      );
      for (final hitbox in hitboxes) {
        final hitboxRow = hitbox.row!;
        if (row != hitboxRow) {
          row = hitboxRow;
          left = alignStartEnd(
            align,
            this.left + padding,
            right - _lineWidthAt(row),
          );
        }
        final hitboxWidth = hitbox.width;
        // `hitbox.top += this.top + titleHeight + padding`: the right side
        // adds first.
        hitbox
          ..top = hitbox.top + (top + titleHeight + padding)
          ..left = rtlHelper.leftForLtr(rtlHelper.x(left), hitboxWidth);
        left += hitboxWidth + padding;
      }
    } else {
      var col = 0;
      var top = alignStartEnd(
        align,
        this.top + titleHeight + padding,
        bottom - _columnHeightAt(col),
      );
      for (final hitbox in hitboxes) {
        final hitboxCol = hitbox.col!;
        if (hitboxCol != col) {
          col = hitboxCol;
          top = alignStartEnd(
            align,
            this.top + titleHeight + padding,
            bottom - _columnHeightAt(col),
          );
        }
        hitbox.top = top;
        final hitboxWidth = hitbox.width;
        // `hitbox.left += this.left + padding`: the right side adds first.
        hitbox
          ..left = hitbox.left + (left + padding)
          ..left = rtlHelper.leftForLtr(rtlHelper.x(hitbox.left), hitboxWidth);
        top += hitbox.height + padding;
      }
    }
  }

  /// `this.lineWidths[row]` as a number: [undefined] gives NaN. Without
  /// line widths, the read throws a [TypeError], as upstream.
  double _lineWidthAt(int row) =>
      jsToNumber(jsGetIndex(lineWidths ?? undefined, row));

  /// `this.columnSizes[col].height` as a number. An absent column throws the
  /// [TypeError] of the read of `height` of `undefined`, as upstream.
  double _columnHeightAt(int col) => _columnAt(col.toDouble()).height;

  /// `this.columnSizes[col]`. Without column sizes, the read throws a
  /// [TypeError], as upstream. An absent column (`undefined`) throws the
  /// [TypeError] of the next property read, as upstream.
  ui.Size _columnAt(double col) {
    final sizes = columnSizes;
    if (sizes == null || !(col >= 0 && col < sizes.length)) {
      // A JavaScript TypeError: a property read of undefined.
      throw TypeError();
    }
    return sizes[col.toInt()];
  }

  /// plugin.legend.js:265 `isHorizontal()`.
  @override
  bool isHorizontal() {
    final position = options.position;
    return position == ChartPosition.top || position == ChartPosition.bottom;
  }

  /// plugin.legend.js:269 `draw()`.
  ///
  /// Upstream takes no argument. The default layer of `layouts.addBox`
  /// passes the chart area (core.layouts.js:305), and the legend ignores it
  /// (Chart.js ADR 0038, section 7).
  @override
  void draw([ChartArea? chartArea]) {
    if (options.display ?? false) {
      final ctx = this.ctx!;
      clipArea(ctx, this);

      _draw();

      unclipArea(ctx);
    }
  }

  /// plugin.legend.js:283 `_draw()`.
  void _draw() {
    final opts = options;
    final lineWidths = this.lineWidths;
    final ctx = this.ctx!;
    // DIVERGES(chartjs): adapt-chart-align-enum, the enum value.
    final align = opts.align;
    final labelOpts = opts.labelsOrEmpty;
    // The singleton read of `defaults.color` (:286): the typed read of the
    // key, with the result of the Map read of the defaults.
    final defaultColor = defaults.lookup(OptionKey.color)?.raw;
    final rtlHelper = getRtlAdapter(opts.rtl ?? false, left, width);
    final labelFont = toFont(labelOpts.font);
    final padding = _labelPadding(labelOpts);
    final fontSize = labelFont.fontSize!;
    final halfFontSize = fontSize / 2;
    ({double x, double y, double line}) cursor;

    drawTitle();

    // Canvas setup
    ctx
      // DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
      ..textAlign = rtlHelper.textAlign(TextAlign.left)
      // DIVERGES(chartjs): adapt-canvas-text-baseline-enum, the enum value.
      ..textBaseline = CanvasTextBaseline.middle
      ..lineWidth = 0.5
      ..font = labelFont;

    final (:boxWidth, :boxHeight, :itemHeight) = _getBoxSize(
      labelOpts,
      fontSize,
    );

    // current position
    void drawLegendBox(double x, double y, LegendItem legendItem) {
      if (boxWidth.isNaN || boxWidth <= 0 || boxHeight.isNaN || boxHeight < 0) {
        return;
      }

      // Set the ctx for the box
      ctx.save();

      final lineWidth = legendItem.lineWidth ?? 1;
      ctx
        ..fillStyle = canvasStyle(
          legendItem.fillStyle is UnchangedChartPaint
              ? defaultColor
              : legendItem.fillStyle,
        )
        // DIVERGES(chartjs): adapt-flutter-stroke-enums, the Flutter enums.
        ..lineCap = canvasLineCap(legendItem.lineCap ?? ui.StrokeCap.butt)
        ..lineDashOffset = canvasNumber(legendItem.lineDashOffset ?? 0)
        ..lineJoin = canvasLineJoin(legendItem.lineJoin ?? ui.StrokeJoin.miter)
        ..lineWidth = canvasNumber(lineWidth)
        ..strokeStyle = canvasStyle(
          legendItem.strokeStyle is UnchangedChartPaint
              ? defaultColor
              : legendItem.strokeStyle,
        )
        ..setLineDash(canvasLineDash(legendItem.lineDash ?? <double>[]));

      if (labelOpts.usePointStyle ?? false) {
        // Recalculate x and y for drawPoint() because its expecting
        // x and y to be center of figure (instead of top left)
        final drawOptions = _LegendPointOptions(
          radius: boxHeight * _sqrt2 / 2,
          pointStyle: legendItem.pointStyle,
          rotation: _rotationOf(legendItem.rotation),
          borderWidth: jsToNumber(lineWidth),
        );
        final centerX = rtlHelper.xPlus(x, boxWidth / 2);
        final centerY = y + halfFontSize;

        // Draw pointStyle as legend symbol
        drawPointLegend(
          ctx,
          drawOptions,
          centerX,
          centerY,
          // `labelOpts.pointStyleWidth && boxWidth`: a falsy value draws the
          // style with the radius alone, as Dart `null` does.
          _truthyNumber(labelOpts.pointStyleWidth) != null ? boxWidth : null,
        );
      } else {
        // Draw box as legend symbol
        // Adjust position when boxHeight < fontSize (want it centered)
        final yBoxTop = y + math.max<double>((fontSize - boxHeight) / 2, 0);
        final xBoxLeft = rtlHelper.leftForLtr(x, boxWidth);
        final borderRadius = legendItem.borderRadius ?? BorderRadius.zero;

        ctx.beginPath();

        // `Object.values(borderRadius).some(v => v !== 0)`, in the key order
        // topLeft, topRight, bottomLeft, bottomRight.
        if (borderRadius.topLeft.x != 0 ||
            borderRadius.topRight.x != 0 ||
            borderRadius.bottomLeft.x != 0 ||
            borderRadius.bottomRight.x != 0) {
          addRoundedRectPath(
            ctx,
            _RoundedRect(
              x: xBoxLeft,
              y: yBoxTop,
              w: boxWidth,
              h: boxHeight,
              radius: borderRadius,
            ),
          );
        } else {
          ctx.rect(xBoxLeft, yBoxTop, boxWidth, boxHeight);
        }

        ctx.fill();
        if (!_strictEquals(lineWidth, 0)) {
          ctx.stroke();
        }
      }

      ctx.restore();
    }

    void fillText(double x, double y, LegendItem legendItem) {
      renderText(
        ctx,
        legendItem.text,
        x,
        y + (itemHeight / 2),
        labelFont,
        RenderTextOpts(
          strikethrough: legendItem.hidden,
          // DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
          textAlign: rtlHelper.textAlign(canvasTextAlign(legendItem.textAlign)),
        ),
      );
    }

    // Horizontal
    final isHorizontal = this.isHorizontal();
    final titleHeight = _computeTitleHeight();
    if (isHorizontal) {
      cursor = (
        x: alignStartEnd(
          align,
          left + padding,
          right - jsToNumber(jsGetIndex(lineWidths ?? undefined, 0)),
        ),
        y: top + padding + titleHeight,
        line: 0,
      );
    } else {
      cursor = (
        x: left + padding,
        y: alignStartEnd(
          align,
          top + titleHeight + padding,
          bottom - _columnAt(0).height,
        ),
        line: 0,
      );
    }

    final originalTextDirection = overrideTextDirection(
      ctx,
      opts.textDirection,
    );
    try {
      final lineHeight = itemHeight + padding;
      final legendItems = this.legendItems!;
      for (var i = 0; i < legendItems.length; i++) {
        final legendItem = legendItems[i];
        final fontColor = canvasStyle(
          legendItem.fontColor is UnchangedChartPaint
              ? labelOpts.color
              : legendItem.fontColor,
        );
        ctx
          ..strokeStyle =
              fontColor // for strikethrough effect
          ..fillStyle = fontColor; // render in correct colour

        final textWidth = ctx.measureText(jsToString(legendItem.text)).width;
        var itemAlign = legendItem.textAlign;
        if (itemAlign == null) {
          itemAlign = labelOpts.textAlign;
          legendItem.textAlign = itemAlign;
        }
        // DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
        final textAlign = rtlHelper.textAlign(canvasTextAlign(itemAlign));
        final width = boxWidth + halfFontSize + textWidth;
        var x = cursor.x;
        var y = cursor.y;

        rtlHelper.setWidth(this.width);

        if (isHorizontal) {
          if (i > 0 && x + width + padding > right) {
            final line = cursor.line + 1;
            y = cursor.y + lineHeight;
            x = alignStartEnd(
              align,
              left + padding,
              right - jsToNumber(jsGetIndex(lineWidths ?? undefined, line)),
            );
            cursor = (x: x, y: y, line: line);
          }
        } else if (i > 0 && y + lineHeight > bottom) {
          x = x + _columnAt(cursor.line).width + padding;
          final line = cursor.line + 1;
          y = alignStartEnd(
            align,
            top + titleHeight + padding,
            bottom - _columnAt(line).height,
          );
          cursor = (x: x, y: y, line: line);
        }

        final realX = rtlHelper.x(x);

        drawLegendBox(realX, y, legendItem);

        x = textX(
          textAlign,
          x + boxWidth + halfFontSize,
          isHorizontal ? x + width : right,
          opts.rtl ?? false,
        );

        // Fill the actual label
        fillText(rtlHelper.x(x), y, legendItem);

        if (isHorizontal) {
          cursor = (
            x: cursor.x + (width + padding),
            y: cursor.y,
            line: cursor.line,
          );
        } else if (legendItem.text.length != 1) {
          final fontLineHeight = labelFont.lineHeight!;
          cursor = (
            x: cursor.x,
            y:
                cursor.y +
                (_calculateLegendItemHeight(legendItem, fontLineHeight) +
                    padding),
            line: cursor.line,
          );
        } else {
          cursor = (x: cursor.x, y: cursor.y + lineHeight, line: cursor.line);
        }
      }
    } finally {
      restoreTextDirection(ctx, originalTextDirection);
    }
  }

  /// plugin.legend.js:443 `drawTitle()`.
  ///
  /// @protected
  void drawTitle() {
    final opts = options;
    final titleOpts = opts.titleOrEmpty;
    final titleFont = toFont(titleOpts.font);
    final titlePadding = titleOpts.padding ?? EdgeInsets.zero;

    if (!(titleOpts.display ?? false)) {
      return;
    }

    final rtlHelper = getRtlAdapter(opts.rtl ?? false, this.left, width);
    final ctx = this.ctx!;
    // DIVERGES(chartjs): adapt-chart-align-enum, the enum value.
    final position = titleOpts.position;
    final halfFontSize = titleFont.fontSize! / 2;
    final topPaddingPlusHalfFontSize = titlePadding.top + halfFontSize;
    double y;

    // These defaults are used when the legend is vertical.
    // When horizontal, they are computed below.
    var left = this.left;
    var maxWidth = width;

    if (isHorizontal()) {
      // Move left / right so that the title is above the legend lines
      maxWidth = lineWidths!.fold(double.negativeInfinity, math.max);
      y = top + topPaddingPlusHalfFontSize;
      left = alignStartEnd(opts.align, left, right - maxWidth);
    } else {
      // Move down so that the title is above the legend stack in every
      // alignment
      final maxHeight = columnSizes!.fold<double>(
        0,
        (acc, size) => math.max(acc, size.height),
      );
      y =
          topPaddingPlusHalfFontSize +
          alignStartEnd(
            opts.align,
            top,
            bottom -
                maxHeight -
                _labelPadding(opts.labelsOrEmpty) -
                _computeTitleHeight(),
          );
    }

    // Now that we know the left edge of the inner legend box, compute the
    // correct X coordinate from the title alignment
    final x = alignStartEnd(position, left, left + maxWidth);

    // Canvas setup
    final color = canvasStyle(titleOpts.color);
    ctx
      ..textAlign = rtlHelper.textAlign(toLeftRightCenter(position))
      // DIVERGES(chartjs): adapt-canvas-text-baseline-enum, the enum value.
      ..textBaseline = CanvasTextBaseline.middle
      ..strokeStyle = color
      ..fillStyle = color
      ..font = titleFont;

    renderText(ctx, titleOpts.text ?? const <String>[], x, y, titleFont);
  }

  /// plugin.legend.js:493 `_computeTitleHeight()`.
  double _computeTitleHeight() {
    final titleOpts = options.titleOrEmpty;
    final titleFont = toFont(titleOpts.font);
    final titlePadding = titleOpts.padding ?? EdgeInsets.zero;
    return (titleOpts.display ?? false)
        ? titleFont.lineHeight! + titlePadding.vertical
        : 0;
  }

  /// plugin.legend.js:503 `_getLegendItemAt(x, y)`.
  ///
  /// `_isBetween` applies `ToNumber` to its value: a JS `null` coordinate
  /// reads as 0, as Dart `null` does here. A NaN coordinate (a `touchend`)
  /// hits no item (Chart.js ADR 0037, section 14 item 3). A hit gives
  /// `this.legendItems[i]`: null when the hit box has no corresponding item.
  LegendItem? _getLegendItemAt(double? x, double? y) {
    final px = x ?? 0;
    final py = y ?? 0;

    if (isBetween(px, left, right) && isBetween(py, top, bottom)) {
      // See if we are touching one of the dataset boxes
      final lh = legendHitBoxes;
      for (var i = 0; i < lh.length; ++i) {
        final hitBox = lh[i];
        if (hitBox.contains(px, py)) {
          // Touching an element
          final items = legendItems;
          return items != null && i < items.length ? items[i] : null;
        }
      }
    }

    return null;
  }

  /// plugin.legend.js:528 `handleEvent(e)`.
  ///
  /// Handle an event
  /// @param {ChartEvent} e - The event to handle
  void handleEvent(ChartEvent e) {
    final opts = options;
    if (!_isListened(e.type, opts)) {
      return;
    }

    // Chart event already has relative position in it
    final hoveredItem = _getLegendItemAt(e.x, e.y);

    if (e.type == 'mousemove' || e.type == 'mouseout') {
      final previous = _hoveredItem;
      final sameItem = _itemsEqual(previous, hoveredItem);
      if (previous != null && !sameItem) {
        opts.onLeave?.call(e, previous, this);
      }

      _hoveredItem = hoveredItem;

      if (hoveredItem != null && !sameItem) {
        opts.onHover?.call(e, hoveredItem, this);
      }
    } else if (hoveredItem != null) {
      opts.onClick?.call(e, hoveredItem, this);
    }
  }
}

/// `legendItems.reverse()`: reverses [list] in place.
void _reverseInPlace(List<LegendItem> list) {
  for (var i = 0, j = list.length - 1; i < j; i++, j--) {
    final item = list[i];
    list[i] = list[j];
    list[j] = item;
  }
}

/// The native Lists of `data.datasets` (`SingleBarDatasetSource` has the same
/// form): a List of another class can run user code at each read.
// DIVERGES(chartjs): adapt-hidden-legend-items, no custom List operator runs.
final Set<Type> _nativeDatasetLists = {
  <Object?>[].runtimeType,
  <Object>[].runtimeType,
  <Map<String, Object?>>[].runtimeType,
  List<Object?>.empty().runtimeType,
  const <Object?>[].runtimeType,
};

/// Whether each call `getStyle(i)` of a built-in generator reads a cached
/// entry, with no user code and no context. [Legend._stylesRunNoUserCode] asks
/// this function first.
///
/// The proof is the cached `default` entry of the element options of
/// [controller]: `_resolveElementOptions` answers from it, with no context and
/// no function. Indexed and scriptable options leave no entry.
///
/// The update of a polar area chart in a mode other than `default` has no such
/// entry when the datasets are updated ([datasetsUpdated]). When
/// [DatasetController.defaultDataOptionsNeedNoContext] proves that the first
/// `getStyle` calls no function, this function runs that `getStyle(0)`, the
/// first call of the ordinary build. It writes the `default` entry that a next
/// layout and a next direct `getStyle` read, as the ordinary build does.
// DIVERGES(chartjs): adapt-hidden-legend-items, the proof of Chart.js ADR 0092.
bool _styleReadsRunNoUserCode(
  DatasetController controller, {
  required bool datasetsUpdated,
}) {
  if (controller.hasCachedDefaultDataOptions) return true;
  if (!datasetsUpdated || !controller.defaultDataOptionsNeedNoContext) {
    return false;
  }
  controller.getStyle(0);
  return controller.hasCachedDefaultDataOptions;
}

/// The second proof of a mark, for the options that leave no cached entry
/// (Chart.js ADR 0099): each option of the arcs of [controller] is a scalar or
/// a native indexed List of native entries, and the arcs and the data are
/// native. Then each `getStyle(i)` for a [count] of labels runs no user code
/// and throws nothing, and its one effect is the state of the context of its
/// arc. Dart `null` leaves the ordinary path at its first reads.
///
/// An ordinary build writes the context of its first resolve before it reads
/// `filter`, `sort` and `reverse`. The options of the box are one object of
/// values (Chart.js ADR 0193), so these reads have no reader, and this proof
/// can come first. A user arc at index 0 reads its context in the first
/// resolve. A visible legend reads its items: it takes no such proof.
// DIVERGES(chartjs): adapt-hidden-legend-items, the proof of Chart.js ADR 0099.
_IndexedItemStyles? _indexedItemStyles(
  DatasetController controller,
  int count,
  LegendOptions options,
) {
  final labels = options.labelsOrEmpty;
  if (options.display != false ||
      labels.filter != null ||
      labels.sort != null) {
    return null;
  }
  final meta = controller.cachedMeta;
  final arcs = meta.data;
  if (!nativeArcClass(controller.dataElementType) ||
      !nativePointList(arcs) ||
      !nativeDataUpdateList(meta.parsed) ||
      !nativePointDatasetIndex(controller.index) ||
      (arcs.isNotEmpty && !nativeArcElement(arcs[0]))) {
    return null;
  }
  final config = controller.chart.config;
  if (config is! Config) return null;
  final styles = config.prepareIndexedArcStyles(
    controller.index,
    controllerType: controller.type,
    count: count,
  );
  return styles == null ? null : _IndexedItemStyles(controller, styles, count);
}

/// The indexed styles of one mark of a hidden legend: the proof that a build of
/// the items of [count] labels runs no user code, and the source of the styles
/// of a build at a later read (Chart.js ADR 0099).
// DIVERGES(chartjs): adapt-hidden-legend-items, the state of one mark.
final class _IndexedItemStyles(
  /// The controller of dataset 0 at the mark.
  final DatasetController controller,

  /// The resolver plan at the mark.
  final IndexedElementStyles styles,

  /// The count of the labels at the mark.
  final int count,
) {
  /// The count of the arcs at the mark. A build at a read gives the item of a
  /// label at this index or above the style of the dataset context, as the
  /// build of the mark does, also when a next update has rebuilt the arcs.
  final int arcCount = controller.cachedMeta.data.length;

  /// Whether a build at a read with [count] labels can run: [controller] is
  /// still the controller of dataset 0, and the styles cover these items.
  bool coversRead(DatasetController controller, int count) =>
      identical(controller, this.controller) && styles.covers(count);

  /// The effect of each `getStyle(i)` of the build at the mark:
  /// `getContext(i, false, 'default')`, in the order of the items, over the
  /// native arrays of the proof. An arc that has no context takes the ordinary
  /// call, which creates it. From the first index past the arcs, each call
  /// writes the same fields of the dataset context, so one call has the effect
  /// of all of them. A custom arc returns false: the ordinary build then runs
  /// from its first item, and it writes the same values again before that arc.
  bool writeContexts() {
    final meta = controller.cachedMeta;
    final arcs = meta.data;
    final parsed = meta.parsed;
    final dataset = controller.getDataset();
    if (!nativeDataUpdateObject(dataset)) return false;
    final rawData = dataUpdateField(dataset!, 'data');
    if (!nativeDataUpdateList(rawData)) return false;
    final raw = rawData! as List<Object?>;
    final end = count < arcCount ? count : arcCount;
    final parsedLength = parsed.length;
    final rawLength = raw.length;
    for (var i = 0; i < end; i++) {
      final arc = arcs[i];
      if (!nativeArcElement(arc)) return false;
      final context = (arc as Element).$context;
      if (context is ScriptableContext) {
        context.refresh(
          i < parsedLength ? parsed[i] : undefined,
          i < rawLength ? raw[i] : undefined,
          i,
          false,
          UpdateMode.defaultMode,
        );
      } else {
        controller.getContext(i, false, 'default');
      }
    }
    if (count > end) {
      controller.getContext(end, false, 'default');
    }
    return true;
  }
}

/// The `rotation` of the draw options of a point style (:329): Dart `null`
/// for JS `undefined` and `null`, else the number. `drawPointLegend` reads
/// it as `(rotation || 0)` (helpers.canvas.ts:178).
double? _rotationOf(Object? rotation) => switch (rotation) {
  final double value => value,
  null || Undefined() => null,
  _ => jsToNumber(rotation),
};

/// plugin.legend.js:555 `calculateItemSize(boxWidth, labelFont, ctx,
/// legendItem, _itemHeight)`.
({double itemWidth, double itemHeight}) _calculateItemSize(
  double boxWidth,
  ChartTextStyle labelFont,
  CanvasRenderingContext2D ctx,
  LegendItem legendItem,
  double itemHeight0,
) {
  final itemWidth = _calculateItemWidth(legendItem, boxWidth, labelFont, ctx);
  final itemHeight = _calculateItemHeight(
    itemHeight0,
    legendItem,
    labelFont.lineHeight!,
  );
  return (itemWidth: itemWidth, itemHeight: itemHeight);
}

/// plugin.legend.js:561 `calculateItemWidth(legendItem, boxWidth,
/// labelFont, ctx)`.
///
/// Uses the longest line by length, with the upstream tie order. An empty
/// list retains the upstream TypeError of vertical label measurement.
double _calculateItemWidth(
  LegendItem legendItem,
  double boxWidth,
  ChartTextStyle labelFont,
  CanvasRenderingContext2D ctx,
) {
  final lines = legendItem.text;
  if (lines.isEmpty) throw TypeError();
  final legendItemText = lines.reduce((a, b) => a.length > b.length ? a : b);
  return boxWidth +
      (labelFont.fontSize! / 2) +
      ctx.measureText(jsToString(legendItemText)).width;
}

/// plugin.legend.js:569 `calculateItemHeight(_itemHeight, legendItem,
/// fontLineHeight)`.
double _calculateItemHeight(
  double itemHeight0,
  LegendItem legendItem,
  double fontLineHeight,
) {
  var itemHeight = itemHeight0;
  if (legendItem.text.length != 1) {
    itemHeight = _calculateLegendItemHeight(legendItem, fontLineHeight);
  }
  return itemHeight;
}

/// plugin.legend.js:577 `calculateLegendItemHeight(legendItem,
/// fontLineHeight)`.
double _calculateLegendItemHeight(
  LegendItem legendItem,
  double fontLineHeight,
) {
  final text = legendItem.text;
  // Native labels carry their lines directly.
  final labelHeight = text.length;
  return fontLineHeight * labelHeight;
}

/// plugin.legend.js:582 `isListened(type, opts)`.
bool _isListened(String type, LegendOptions opts) {
  if ((type == 'mousemove' || type == 'mouseout') &&
      (opts.onHover != null || opts.onLeave != null)) {
    return true;
  }
  if (opts.onClick != null && (type == 'click' || type == 'mouseup')) {
    return true;
  }
  return false;
}

/// The draw options of a legend point style (:326-331), the object literal
/// of the `drawPointLegend` call.
final class _LegendPointOptions({
  @override required final double radius,
  @override required final Object? pointStyle,
  @override required final double? rotation,
  @override required final double borderWidth,
}) implements DrawPointOptions;

/// The rounded box of a legend item (:347-353), the object literal
/// `{x, y, w, h, radius}` of the `addRoundedRectPath` call.
final class _RoundedRect({
  @override required final double x,
  @override required final double y,
  @override required final double w,
  @override required final double h,
  @override required final BorderRadius radius,
}) implements RoundedRect;

/// The `config` of `new Legend(config)` from the arguments [args] of the
/// `construct` closure of [Legend.jsClass]: the reads `config.chart`,
/// `config.options` and `config.ctx` of plugin.legend.js:62-64.
///
/// An absent argument, [undefined] and JS `null` throw the [TypeError] of
/// the read `config.chart`, as upstream. A member with the value
/// [undefined] gives Dart `null`. A `chart` that is not a `types.Chart`, an
/// `options` that is not a [LegendOptions] (Chart.js ADR 0193) and a `ctx`
/// that is not a context throw a [TypeError]. Upstream stores such a value
/// and reads its members later.
// DIVERGES(chartjs): adapt-component-class-role, a non-Chart chart throws.
({IChart chart, Object? options, CanvasRenderingContext2D? ctx}) _legendConfig(
  List<Object?> args,
) {
  final config = args.isEmpty ? undefined : args[0];
  return (
    chart: _orNull(jsGet(config, 'chart'))! as IChart,
    options: _orNull(jsGet(config, 'options')) as LegendOptions?,
    ctx: _orNull(jsGet(config, 'ctx')) as CanvasRenderingContext2D?,
  );
}

/// Dart `null` for the [undefined] sentinel, else [value].
Object? _orNull(Object? value) => identical(value, undefined) ? null : value;

/// plugin.legend.js:645 the default `onClick(e, legendItem, legend)`: a
/// callback that will handle.
///
/// The native integer index selects the dataset. Descriptive entries have
/// no index and leave visibility unchanged.
void _onClick(Object? e, LegendItem item, LegendElement legend) {
  final index = item.datasetIndex;
  if (index == null) return;
  final ci = legend.chart;
  if (ci.isDatasetVisible(index)) {
    ci.hide(index);
    item.hidden = true;
  } else {
    ci.show(index);
    item.hidden = false;
  }
}

/// plugin.legend.js:661 and :707 `color: (ctx) => ctx.chart.options.color`:
/// the `color` of the options of [chart] as a paint, or Dart `null` for a
/// value that is no color.
// DIVERGES(chartjs): adapt-native-plugin-options, the default in Dart.
ChartPaint? _chartColor(IChart chart) =>
    switch (optionOf(chart.options, OptionKey.color)) {
      final ChartPaint paint => paint,
      final ui.Color color => ChartPaint.solid(color),
      _ => null,
    };

/// The options [source] of the hooks with the fallbacks of upstream
/// (Chart.js ADR 0193), and the result of [LegendOptions.scripted] merged
/// over them:
///
/// - The label and title colors that [source] does not set are the `color`
///   of the chart options, the default functions of plugin.legend.js:661 and
///   :707.
/// - [LegendOptions.scripted] gets the chart context and these options, once
///   for each update, where upstream calls each scriptable option at its
///   first read in the update. Its result merges over [source], and the
///   colors that it does not set fall back again.
///
/// The fonts stay as the options give them: each reader merges them over
/// `Chart.defaults.font` with `toFont`, as upstream.
// DIVERGES(chartjs): adapt-legend-scripted, one function for the options.
LegendOptions _resolvedOptions(IChart chart, LegendOptions source) {
  LegendOptions withColors(LegendOptions options) {
    final labels = options.labels;
    final title = options.title;
    if (labels?.color != null && title?.color != null) return options;
    final color = _chartColor(chart);
    return options.merge(
      LegendOptions(
        labels: labels?.color == null ? LegendLabelOptions(color: color) : null,
        title: title?.color == null ? LegendTitleOptions(color: color) : null,
      ),
    );
  }

  final base = withColors(source);
  final script = source.scripted;
  if (script == null) return base;
  final scripted = script(chart.getContext(), base);
  return scripted == null ? base : withColors(source.merge(scripted));
}

/// plugin.legend.js:675 `generateLabels(chart)`: generates labels shown in
/// the legend.
///
/// Valid properties to return:
/// text : text to display
/// fillStyle : fill of coloured box
/// strokeStyle: stroke of coloured box
/// hidden : if this legend item refers to a hidden item
/// lineCap : cap style for line
/// lineDash
/// lineDashOffset :
/// lineJoin :
/// lineWidth :
///
/// Each style value is the read of its key ([optionOf]): an absent key
/// gives [undefined]. The upstream call `_getSortedDatasetMetas()` has no
/// argument, a falsy `filterVisible`. The items are [LegendItem]s. The
/// datasets of the user are read by name.
List<LegendItem> _generateLabels(IChart chart) {
  final datasets = jsGet(chart.data, 'datasets');
  final labels = (chart.legend!.options as LegendOptions).labelsOrEmpty;
  final usePointStyle = labels.usePointStyle ?? false;
  final pointStyle = labels.pointStyle;
  final textAlign = labels.textAlign;
  final color = labels.color;
  final useBorderRadius = labels.useBorderRadius ?? false;
  final borderRadius = labels.borderRadius;

  return [
    for (final meta in chart.getSortedDatasetMetas(false))
      _datasetItem(
        datasets,
        meta,
        meta.controller!.getStyle(usePointStyle ? 0 : null),
        pointStyle,
        textAlign,
        color,
        useBorderRadius,
        borderRadius,
      ),
  ];
}

/// The item of [meta] of `generateLabels` (:680-701), a [LegendItem] with
/// the upstream key order. The reads of the style keep the upstream order:
/// the destructuring of :678 first, then the object literal. The label is
/// a read of the dataset of the user, by name.
LegendItem _datasetItem(
  Object? datasets,
  ChartMeta meta,
  Object style,
  Object? pointStyle,
  Object? textAlign,
  Object? color,
  bool useBorderRadius,
  BorderRadius? borderRadius,
) {
  final borderWidth = toPadding(optionOf(style, OptionKey.borderWidth));
  final stylePointStyle = optionOf(style, OptionKey.pointStyle);
  // No built-in element option is `textAlign`: the read by name gives an
  // option of a user element, else `undefined`.
  final styleTextAlign = jsGet(style, 'textAlign');

  return legendItemFromOptions(
    text: jsGet(jsGetIndex(datasets, meta.index), 'label'),
    fillStyle: optionOf(style, OptionKey.backgroundColor),
    fontColor: color,
    hidden: !meta.visible,
    lineCap: optionOf(style, OptionKey.borderCapStyle),
    lineDash: optionOf(style, OptionKey.borderDash),
    lineDashOffset: optionOf(style, OptionKey.borderDashOffset),
    lineJoin: optionOf(style, OptionKey.borderJoinStyle),
    lineWidth: (borderWidth.width + borderWidth.height) / 4,
    strokeStyle: optionOf(style, OptionKey.borderColor),
    pointStyle: jsTruthy(pointStyle) ? pointStyle : stylePointStyle,
    rotation: optionOf(style, OptionKey.rotation),
    textAlign: jsTruthy(textAlign) ? textAlign : styleTextAlign,
    // `useBorderRadius && (borderRadius || style.borderRadius)`
    borderRadius: useBorderRadius
        ? (borderRadius ?? optionOf(style, OptionKey.borderRadius))
        : null,
    // Below is extra data used for toggling the datasets
    datasetIndex: meta.index,
  );
}

/// plugin.legend.js:601 `start(chart, _args, options)`. The box keeps the
/// [LegendOptions] of the hook until `beforeUpdate` of the same update gives
/// it the options with their fallbacks: the layout reads only `display`,
/// `fullSize`, `position` and `weight` between the two hooks.
void _start(IChart chart, PluginHookArgs _, LegendOptions options) {
  final legend = Legend((ctx: chart.ctx, options: options, chart: chart));
  chart.legend = legend;
  layouts
    ..configure(chart, legend, options)
    ..addBox(chart, legend);
}

/// plugin.legend.js:607 `stop(chart)`. core.layouts.js:318-323 compares
/// identities only. A value that is not a LayoutItem is never in
/// chart.boxes. `delete chart.legend` is the write of Dart `null`.
void _stop(IChart chart, PluginHookArgs _, LegendOptions _) {
  final legend = chart.legend;
  // DIVERGES(chartjs): adapt-hidden-legend-items, before the box goes.
  if (legend is Legend) legend._settleItems();
  layouts.removeBox(chart, switch (legend) {
    final LayoutItem item => item,
    _ => null,
  });
  chart.legend = null;
}

/// plugin.legend.js:615 `beforeUpdate(chart, _args, options)`. During the
/// beforeUpdate step, the layout configuration needs to run. This ensures
/// that if the legend position changes (via an option update) the layout
/// system respects the change. See
/// https://github.com/chartjs/Chart.js/issues/7527
///
/// A legend that is not a Legend throws the TypeError of the cast. Upstream
/// throws a TypeError in the same update, at `buildLabels` of afterUpdate
/// (Chart.js ADR 0038, section 6).
///
/// The hook continues the update: `true` is the `undefined` result of
/// upstream.
///
/// The box gets the options with the fallbacks of upstream
/// ([_resolvedOptions], Chart.js ADR 0193), so `scripted` runs once for each
/// update.
bool _beforeUpdate(IChart chart, UpdateHookArgs _, LegendOptions options) {
  final legend = chart.legend! as Legend;
  final resolved = _resolvedOptions(chart, options);
  layouts.configure(chart, legend, resolved);
  legend.options = resolved;
  return true;
}

/// plugin.legend.js:623 `afterUpdate(chart)`. The labels need to be built
/// after datasets are updated to ensure that colors and other styling are
/// correct. See https://github.com/chartjs/Chart.js/issues/6968
///
/// `adjustHitBoxes` adds the position of the legend to the hit boxes of the
/// last `fit`. A data update that keeps the layout runs no `fit`, so its hit
/// boxes already have that position.
void _afterUpdate(IChart chart, UpdateHookArgs args, LegendOptions _) {
  final legend = chart.legend! as Legend
    // DIVERGES(chartjs): adapt-hidden-legend-items, the first read builds.
    .._buildLabelsOrMark(datasetsUpdated: true);
  // DIVERGES(chartjs): adapt-incremental-data-update, no `fit` in this update.
  if (args.layoutKept) return;
  legend.adjustHitBoxes();
}

/// plugin.legend.js:630 `afterEvent(chart, args)`: the typed `replay` and
/// `event` of [EventHookArgs]. An event of Dart `null` throws the
/// [TypeError] of the null check, as `handleEvent` throws at `e.type` of
/// `undefined` upstream.
void _afterEvent(IChart chart, EventHookArgs args, LegendOptions _) {
  if (!args.replay) {
    (chart.legend! as Legend).handleEvent(args.event);
  }
}

/// plugin.legend.js:592 the default export, `Legend` of
/// `src/plugins/index.js:4` (Chart.js ADR 0038, section 1).
///
/// A native [Plugin] with the upstream keys in the upstream order (Chart.js
/// ADR 0144). The key `_element: Legend` of plugin.legend.js:599 is for the
/// tests: they read `Legend.jsClass`.
// DIVERGES(chartjs): adapt-typed-plugins, no key `_element`.
final legend = LegendPlugin();

/// The legend plugin: a class of its own, so
/// `registry.getPlugin<LegendPlugin>()`
/// finds it by its type.
// DIVERGES(chartjs): adapt-typed-plugins, a class for each plugin.
final class LegendPlugin() extends Plugin<LegendOptions> {
  /// The legend plugin.
  this
    : super(
        id: 'legend',
        // The hooks get the merged LegendOptions (Chart.js ADR 0193).
        start: _start,
        stop: _stop,
        beforeUpdate: _beforeUpdate,
        afterUpdate: _afterUpdate,
        afterEvent: _afterEvent,
        // plugin.legend.js:636-712: one LegendOptions with each default
        // (Chart.js ADR 0193). `onHover` and `onLeave` are `null` upstream:
        // no field. The label and title `color` are the `color` of the chart
        // when no options set them (:661, :707): the legend gives that color
        // ([_resolvedOptions]).
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        defaults: const LegendOptions(
          display: true,
          position: ChartPosition.top,
          // DIVERGES(chartjs): adapt-chart-align-enum, the enum value.
          align: ChartAlign.center,
          fullSize: true,
          reverse: false,
          weight: 1000,
          // a callback that will handle
          onClick: _onClick,
          labels: LegendLabelOptions(
            boxWidth: 40,
            padding: 10,
            // Generates labels shown in the legend
            generateLabels: _generateLabels,
          ),
          title: LegendTitleOptions(
            display: false,
            // DIVERGES(chartjs): adapt-chart-align-enum, the enum value.
            position: ChartAlign.center,
            // DIVERGES(chartjs): adapt-title-text-lines, the lines of `''`.
            text: [''],
          ),
        ),
        // plugin.legend.js:714-719: the descriptors make each option but the
        // functions scriptable; the options are not resolved, and the one
        // function `scripted` takes the place of the scriptable options (row
        // adapt-legend-scripted).
        // DIVERGES(chartjs): adapt-native-plugin-options, no descriptors.
        // DIVERGES(chartjs): adapt-incremental-data-update, partial-lifecycle
        // opt-in.
        supportsDataUpdates: true,
      );
}
