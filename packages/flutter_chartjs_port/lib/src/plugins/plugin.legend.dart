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
/// args, AnyObject options)` (Chart.js ADR 0054 §12, in place of the
/// upstream parameter counts of Chart.js ADR 0038, section 3): `afterEvent`
/// takes the typed [EventHookArgs], the other hooks read no args and take
/// any args object. `chart.legend` is a field of `types.Chart`: Dart `null`
/// stands for JS `undefined` and for the `delete` of `plugin.legend.js:609`.
///
/// The box reads its options through the facades [LegendOptions],
/// [LegendLabelOptions] and `LegendTitleOptions` of `plugin_options.dart`
/// (Chart.js ADR 0054 §4), in the upstream order of the reads.
///
/// The fields of the box start as the fields of `Scale` start: NaN for the
/// edges, `maxWidth` and `maxHeight`, the `undefined` sentinel for
/// `position` and `weight`, and `false` for `fullSize` (Chart.js ADR 0038,
/// section 7).
///
/// The legend items of the built-in `generateLabels`, the hit boxes and the
/// column sizes are typed classes with the upstream keys in the upstream
/// order: [LegendItem], [LegendHitBox] and [LegendColumnSize] (Chart.js ADR
/// 0054 §12). Each has the face, so a user callback, a spec and a fixture
/// read them by name (`plugin.legend.tests.js:502-507`,
/// `test/fixtures/plugin.legend/horizontal-rtl-hitbox.js:37-38`), and the
/// extras of a key that user code adds. An item of a `generateLabels` of
/// user code (or of a controller) can be any object: the legend reads a
/// [LegendItem] through its fields and another item by name ([_Item]).
///
/// Not a pure layer: it imports `helpers.extras`.
library;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.layouts.dart' show layouts;
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show
        DrawPointOptions,
        addRoundedRectPath,
        clipArea,
        drawPointLegend,
        renderText,
        unclipArea;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show callback, valueOrDefault;
import 'package:flutter_chartjs_port/src/helpers/helpers.extras.dart'
    show alignStartEnd, textX, toLeftRightCenter;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show isBetween;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ParsedFont, ScriptableChartContext, toFont, toPadding, toTRBLCorners;
import 'package:flutter_chartjs_port/src/helpers/helpers.rtl.dart'
    show getRtlAdapter, overrideTextDirection, restoreTextDirection;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsSort;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsMin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsGetIndex, jsObjectOrNull;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart'
    show canvasKeyword, canvasLineDash, canvasNumber, canvasStyle;
import 'package:flutter_chartjs_port/src/options/opt.dart' show optNull;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        DescriptorsScope,
        LegendLabelOptionsScope,
        LegendOptionsScope,
        LegendTitleOptionsScope;
import 'package:flutter_chartjs_port/src/options/typed_record.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin_options.dart'
    show LegendLabelOptions, LegendOptions, optionOf;
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/layout.dart';
import 'package:flutter_chartjs_port/src/types/plugin.dart'
    show EventHookArgs, Plugin;

/// `Math.SQRT2`.
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
  final rawHeight = labelOpts.boxHeight;
  final rawWidth = labelOpts.boxWidth;
  var boxHeight = identical(rawHeight, undefined)
      ? fontSize
      : jsToNumber(rawHeight);
  var boxWidth = identical(rawWidth, undefined)
      ? fontSize
      : jsToNumber(rawWidth);

  if (jsTruthy(labelOpts.usePointStyle)) {
    boxHeight = jsMin(boxHeight, fontSize);
    final pointStyleWidth = labelOpts.pointStyleWidth;
    boxWidth = jsTruthy(pointStyleWidth)
        ? jsToNumber(pointStyleWidth)
        : jsMin(boxWidth, fontSize);
  }

  return (
    boxWidth: boxWidth,
    boxHeight: boxHeight,
    itemHeight: jsMax(fontSize, boxHeight),
  );
}

/// plugin.legend.js:39 `itemsEqual(a, b)`: `a !== null && b !== null &&
/// a.datasetIndex === b.datasetIndex && a.index === b.index`.
///
/// An item that is [undefined] throws the [TypeError] of the property read,
/// as upstream.
bool _itemsEqual(Object? a, Object? b) =>
    a != null &&
    b != null &&
    _strictEquals(_Item(a).datasetIndex, _Item(b).datasetIndex) &&
    _strictEquals(_Item(a).index, _Item(b).index);

/// The `padding` label option (`options.labels.padding`, :161, :192, :235,
/// :289) as a number. index.d.ts types it as a number. A string joins in
/// the `+` of upstream (for example :165, :185 and :209; :197 starts
/// `totalWidth` with the raw value), and the port adds its `ToNumber`
/// (differences.md `adapt-legend-number-options`).
double _labelPadding(LegendLabelOptions labelOpts) =>
    // DIVERGES(chartjs): adapt-legend-number-options, the padding is a number.
    jsToNumber(labelOpts.padding);

/// The JS operator `===` on two raw values: two numbers compare by value
/// (NaN is not equal to itself, and -0 equals +0), two strings by their code
/// units, and other values by identity.
bool _strictEquals(Object? a, Object? b) {
  if (a is num && b is num) return a.toDouble() == b.toDouble();
  if (a is String && b is String) return a == b;
  return identical(a, b);
}

/// The `align` option or the title `position` as the `String` of the helpers
/// of helpers.extras.ts: `_alignStartEnd`, `_textX` and `_toLeftRightCenter`
/// compare it with `===`. A value that is not a `String` equals no keyword,
/// so it passes as `''` (the form of `plugin.title.dart` `_alignName`).
String _alignName(Object? align) => align is String ? align : '';

/// The `textAlign` of the text options of `renderText` (:370), the result
/// of `rtlHelper.textAlign`. `renderText` sets it only when it is truthy
/// (helpers.canvas.ts:395), and the setter of the DOM applies `ToString`.
String? _textAlignOf(Object? align) => switch (align) {
  final String value => value,
  _ => jsTruthy(align) ? jsToString(align) : null,
};

/// plugin.legend.js:41 `class Legend extends Element`.
///
/// The layout box of the chart legend. `layouts.addBox` gives it the default
/// layer, which calls [draw] (core.layouts.js:301-308).
class Legend extends Element implements types.LegendElement, LayoutItem, TRBL {
  /// plugin.legend.js:46 `constructor(config)`.
  ///
  /// @param {{ ctx: any; options: any; chart: any; }} config
  ///
  /// The upstream `config` object is a record (Chart.js ADR 0038, section
  /// 4). The `construct` closure of [jsClass] reads it from a JS value.
  Legend(
    ({types.Chart chart, Object? options, CanvasRenderingContext2D? ctx})
    config,
  ) : chart = config.chart,
      ctx = config.ctx {
    super.options = config.options;
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
  /// Each hit box is a [LegendHitBox] with the upstream keys: `left`, `top`,
  /// `row`, `width` and `height` for a horizontal legend (:183), `left`,
  /// `top`, `col`, `width` and `height` for a vertical legend (:217).
  /// `index.d.ts` does not declare it. It implements the port-only member
  /// [types.LegendElement.legendHitBoxes], which the keyboard of `ChartView`
  /// reads (Chart.js ADR 0051, section 2).
  @override
  List<LegendHitBox> legendHitBoxes = [];

  /// plugin.legend.js:57 `_hoveredItem`. Dart `null` stands for JS `null`.
  Object? _hoveredItem;

  /// plugin.legend.js:60 `doughnutMode`: are we in doughnut mode which has
  /// a different data type. Upstream writes it and never reads it.
  bool doughnutMode = false;

  /// plugin.legend.js:62 `chart`. [types.LegendElement.chart] is a
  /// `types.Chart`, so the constructor takes one (Chart.js ADR 0038,
  /// section 4).
  @override
  final types.Chart chart;

  /// plugin.legend.js:64 `ctx`. Dart `null` stands for JS `undefined`.
  CanvasRenderingContext2D? ctx;

  /// plugin.legend.js:65 `legendItems`. Dart `null` stands for JS
  /// `undefined`, the value before the first [buildLabels].
  ///
  /// The items are the values of `generateLabels`, as upstream: a
  /// [LegendItem] of the built-in `generateLabels`, or any object of user
  /// code, read through [_Item].
  @override
  List<Object?>? legendItems;

  /// plugin.legend.js:66 `columnSizes`: `{width, height}` of each column of
  /// a vertical legend, a [LegendColumnSize]. Dart `null` stands for JS
  /// `undefined`.
  List<LegendColumnSize>? columnSizes;

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

  /// plugin.legend.js:77 `position`. The [undefined] sentinel stands for JS
  /// `undefined`, the start value. `layouts.configure` writes the
  /// `position` option (core.layouts.js:333).
  @override
  Object? position = undefined;

  /// plugin.legend.js:78 `weight`. The [undefined] sentinel stands for JS
  /// `undefined`, the start value.
  @override
  Object? weight = undefined;

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
  String? get axis => null;

  /// plugin.legend.js:63 `options`, the resolver of the legend options.
  ///
  /// [types.LegendElement.options] is not nullable. Thus the read of a
  /// legend without options throws a [TypeError], as the first member read
  /// of `this.options` throws upstream (Chart.js ADR 0038, section 7).
  @override
  Object get options => super.options!;

  /// plugin.legend.js:82 `update(maxWidth, maxHeight, margins)`.
  @override
  void update(double maxWidth, double maxHeight, [TRBL? margins]) {
    this.maxWidth = maxWidth;
    this.maxHeight = maxHeight;
    _margins = margins;

    setDimensions();
    buildLabels();
    fit();
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
  /// `generateLabels` gives the array of the items. A truthy value that is
  /// not a `List` throws a [TypeError] at the List cast. Upstream stores the
  /// value and throws only at its first array read (differences.md
  /// `adapt-legend-items-list`). `filter` and `sort` get the labels options
  /// as `this`, as the method calls of :109 and :113 do. `sort` is the
  /// stable sort of `Array.prototype.sort` ([jsSort]). An `undefined` item
  /// goes to the end and never reaches `sort`, as in
  /// `Array.prototype.sort`. `reverse` reverses the List in place.
  void buildLabels() {
    final opts = LegendOptions(options);
    final labels = opts.labelsValue;
    final labelOpts = jsTruthy(labels) ? labels : <String, Object?>{};
    final generated = callback(LegendLabelOptions(labelOpts).generateLabels, [
      chart,
    ], this);
    // DIVERGES(chartjs): adapt-legend-items-list, the items are a List.
    var legendItems = jsTruthy(generated)
        ? generated! as List<Object?>
        : <Object?>[];

    final filter = LegendLabelOptions(labelOpts).filter;
    if (jsTruthy(filter)) {
      legendItems = [
        for (final item in legendItems)
          if (jsTruthy(
            jsCall(filter, [item, chart.data], thisArg: labelOpts),
          ))
            item,
      ];
    }

    final sort = LegendLabelOptions(labelOpts).sort;
    if (jsTruthy(sort)) {
      legendItems = jsSort(legendItems, (a, b) {
        // SortCompare of Array.prototype.sort: an undefined element goes
        // after each other element, and the comparator never gets it. JS
        // null reaches the comparator.
        if (identical(a, undefined)) return identical(b, undefined) ? 0 : 1;
        if (identical(b, undefined)) return -1;
        return jsToNumber(
          jsCall(sort, [a, b, chart.data], thisArg: labelOpts),
        );
      });
    }

    if (jsTruthy(opts.reverse)) {
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
    final options = LegendOptions(this.options);
    final ctx = this.ctx;

    if (!jsTruthy(options.display)) {
      this.width = this.height = 0;
      return;
    }

    final labelOpts = options.labels;
    final labelFont = toFont(labelOpts.font);
    final fontSize = labelFont.size ?? double.nan;
    final titleHeight = _computeTitleHeight();
    final (:boxWidth, :boxHeight, :itemHeight) = _getBoxSize(
      labelOpts,
      fontSize,
    );

    double width;
    double height;

    ctx!.font = labelFont.string;

    if (isHorizontal()) {
      width = maxWidth; // fill all the width
      height = _fitRows(titleHeight, fontSize, boxWidth, itemHeight) + 10;
    } else {
      height = maxHeight; // fill all the height
      width = _fitCols(titleHeight, labelFont, boxWidth, itemHeight) + 10;
    }

    final maxWidthOption = options.maxWidth;
    final maxHeightOption = options.maxHeight;
    this.width = jsMin(
      width,
      jsTruthy(maxWidthOption) ? jsToNumber(maxWidthOption) : maxWidth,
    );
    this.height = jsMin(
      height,
      jsTruthy(maxHeightOption) ? jsToNumber(maxHeightOption) : maxHeight,
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
    final padding = _labelPadding(LegendOptions(options).labels);
    final hitboxes = legendHitBoxes = [];
    // Width of each line of legend boxes. Labels wrap onto multiple lines
    // when there are too many to fit on one
    final lineWidths = this.lineWidths = [0];
    final lineHeight = itemHeight + padding;
    var totalHeight = titleHeight;

    ctx
      ..textAlign = 'left'
      ..textBaseline = 'middle';

    var row = -1.0;
    var top = -lineHeight;
    final legendItems = this.legendItems!;
    for (var i = 0; i < legendItems.length; i++) {
      final legendItem = legendItems[i];
      final itemWidth =
          boxWidth +
          (fontSize / 2) +
          ctx.measureText(jsToString(_Item(legendItem).text)).width;

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
    ParsedFont labelFont,
    double boxWidth,
    double itemHeight0,
  ) {
    final ctx = this.ctx!;
    final maxHeight = this.maxHeight;
    final padding = _labelPadding(LegendOptions(options).labels);
    final hitboxes = legendHitBoxes = [];
    final columnSizes = this.columnSizes = [];
    final heightLimit = maxHeight - titleHeight;

    var totalWidth = padding;
    var currentColWidth = 0.0;
    var currentColHeight = 0.0;

    var left = 0.0;
    var col = 0.0;

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
        columnSizes.add(
          LegendColumnSize(width: currentColWidth, height: currentColHeight),
        );
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
      currentColWidth = jsMax(currentColWidth, itemWidth);
      currentColHeight += itemHeight + padding;
    }

    totalWidth += currentColWidth;
    // previous column size
    columnSizes.add(
      LegendColumnSize(width: currentColWidth, height: currentColHeight),
    );

    return totalWidth;
  }

  /// plugin.legend.js:230 `adjustHitBoxes()`.
  void adjustHitBoxes() {
    final options = LegendOptions(this.options);
    if (!jsTruthy(options.display)) {
      return;
    }
    final titleHeight = _computeTitleHeight();
    final hitboxes = legendHitBoxes;
    final align = _alignName(options.align);
    final padding = _labelPadding(options.labels);
    final rtlHelper = getRtlAdapter(options.rtl, left, width);
    if (isHorizontal()) {
      var row = 0.0;
      var left = alignStartEnd(
        align,
        this.left + padding,
        right - _lineWidthAt(row),
      );
      for (final hitbox in hitboxes) {
        final hitboxRow = hitbox.row;
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
      var col = 0.0;
      var top = alignStartEnd(
        align,
        this.top + titleHeight + padding,
        bottom - _columnHeightAt(col),
      );
      for (final hitbox in hitboxes) {
        final hitboxCol = hitbox.col;
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
  double _lineWidthAt(double row) =>
      jsToNumber(jsGetIndex(lineWidths ?? undefined, row));

  /// `this.columnSizes[col].height` as a number. An absent column throws the
  /// [TypeError] of the read of `height` of `undefined`, as upstream.
  double _columnHeightAt(double col) => _columnAt(col).height;

  /// `this.columnSizes[col]`. Without column sizes, the read throws a
  /// [TypeError], as upstream. An absent column (`undefined`) throws the
  /// [TypeError] of the next property read, as upstream.
  LegendColumnSize _columnAt(double col) {
    final column = jsGetIndex(columnSizes ?? undefined, col);
    if (column is! LegendColumnSize) {
      // A JavaScript TypeError: a property read of undefined.
      throw TypeError();
    }
    return column;
  }

  /// plugin.legend.js:265 `isHorizontal()`.
  @override
  bool isHorizontal() {
    final position = LegendOptions(options).position;
    return position == 'top' || position == 'bottom';
  }

  /// plugin.legend.js:269 `draw()`.
  ///
  /// Upstream takes no argument. The default layer of `layouts.addBox`
  /// passes the chart area (core.layouts.js:305), and the legend ignores it
  /// (Chart.js ADR 0038, section 7).
  @override
  void draw([ChartArea? chartArea]) {
    if (jsTruthy(LegendOptions(options).display)) {
      final ctx = this.ctx!;
      clipArea(ctx, this);

      _draw();

      unclipArea(ctx);
    }
  }

  /// plugin.legend.js:283 `_draw()`.
  void _draw() {
    final opts = LegendOptions(options);
    final lineWidths = this.lineWidths;
    final ctx = this.ctx!;
    final align = _alignName(opts.align);
    final labelOpts = opts.labels;
    // The singleton read of `defaults.color` (:286): the typed read of the
    // key, with the result of the Map read of the defaults.
    final defaultColor = defaults.lookup(OptionKey.color)?.raw;
    final rtlHelper = getRtlAdapter(opts.rtl, left, width);
    final labelFont = toFont(labelOpts.font);
    final padding = _labelPadding(labelOpts);
    final fontSize = labelFont.size ?? double.nan;
    final halfFontSize = fontSize / 2;
    ({double x, double y, double line}) cursor;

    drawTitle();

    // Canvas setup
    ctx
      ..textAlign = _textAlignOf(rtlHelper.textAlign('left'))
      ..textBaseline = 'middle'
      ..lineWidth = 0.5
      ..font = labelFont.string;

    final (:boxWidth, :boxHeight, :itemHeight) = _getBoxSize(
      labelOpts,
      fontSize,
    );

    // current position
    void drawLegendBox(double x, double y, _Item legendItem) {
      if (boxWidth.isNaN || boxWidth <= 0 || boxHeight.isNaN || boxHeight < 0) {
        return;
      }

      // Set the ctx for the box
      ctx.save();

      final lineWidth = valueOrDefault(legendItem.lineWidth, 1);
      ctx
        ..fillStyle = canvasStyle(
          valueOrDefault(legendItem.fillStyle, defaultColor),
        )
        ..lineCap = canvasKeyword(valueOrDefault(legendItem.lineCap, 'butt'))
        ..lineDashOffset = canvasNumber(
          valueOrDefault(legendItem.lineDashOffset, 0),
        )
        ..lineJoin = canvasKeyword(
          valueOrDefault(legendItem.lineJoin, 'miter'),
        )
        ..lineWidth = canvasNumber(lineWidth)
        ..strokeStyle = canvasStyle(
          valueOrDefault(legendItem.strokeStyle, defaultColor),
        )
        ..setLineDash(
          canvasLineDash(valueOrDefault(legendItem.lineDash, <Object?>[])),
        );

      if (jsTruthy(labelOpts.usePointStyle)) {
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
          jsTruthy(labelOpts.pointStyleWidth) ? boxWidth : null,
        );
      } else {
        // Draw box as legend symbol
        // Adjust position when boxHeight < fontSize (want it centered)
        final yBoxTop = y + jsMax((fontSize - boxHeight) / 2, 0);
        final xBoxLeft = rtlHelper.leftForLtr(x, boxWidth);
        final borderRadius = toTRBLCorners(legendItem.borderRadius);

        ctx.beginPath();

        // `Object.values(borderRadius).some(v => v !== 0)`, in the key order
        // topLeft, topRight, bottomLeft, bottomRight.
        if (borderRadius.topLeft != 0 ||
            borderRadius.topRight != 0 ||
            borderRadius.bottomLeft != 0 ||
            borderRadius.bottomRight != 0) {
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

    void fillText(double x, double y, _Item legendItem) {
      renderText(
        ctx,
        legendItem.text,
        x,
        y + (itemHeight / 2),
        labelFont,
        _LegendTextOpts(
          strikethrough: jsTruthy(legendItem.hidden),
          textAlign: _textAlignOf(rtlHelper.textAlign(legendItem.textAlign)),
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

    overrideTextDirection(ctx, opts.textDirection);

    final lineHeight = itemHeight + padding;
    final legendItems = this.legendItems!;
    for (var i = 0; i < legendItems.length; i++) {
      final legendItem = _Item(legendItems[i]);
      final fontColor = canvasStyle(legendItem.fontColor);
      ctx
        ..strokeStyle =
            fontColor // for strikethrough effect
        ..fillStyle = fontColor; // render in correct colour

      final textWidth = ctx.measureText(jsToString(legendItem.text)).width;
      var itemAlign = legendItem.textAlign;
      if (!jsTruthy(itemAlign)) {
        itemAlign = labelOpts.textAlign;
        legendItem.textAlign = itemAlign;
      }
      final textAlign = rtlHelper.textAlign(itemAlign);
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
        _alignName(textAlign),
        x + boxWidth + halfFontSize,
        isHorizontal ? x + width : right,
        jsTruthy(opts.rtl),
      );

      // Fill the actual label
      fillText(rtlHelper.x(x), y, legendItem);

      if (isHorizontal) {
        cursor = (
          x: cursor.x + (width + padding),
          y: cursor.y,
          line: cursor.line,
        );
      } else if (legendItem.text is! String) {
        final fontLineHeight = labelFont.lineHeight;
        cursor = (
          x: cursor.x,
          y:
              cursor.y +
              (_calculateLegendItemHeight(legendItem.item, fontLineHeight) +
                  padding),
          line: cursor.line,
        );
      } else {
        cursor = (x: cursor.x, y: cursor.y + lineHeight, line: cursor.line);
      }
    }

    restoreTextDirection(ctx, opts.textDirection);
  }

  /// plugin.legend.js:443 `drawTitle()`.
  ///
  /// @protected
  void drawTitle() {
    final opts = LegendOptions(options);
    final titleOpts = opts.title;
    final titleFont = toFont(titleOpts.font);
    final titlePadding = toPadding(titleOpts.padding);

    if (!jsTruthy(titleOpts.display)) {
      return;
    }

    final rtlHelper = getRtlAdapter(opts.rtl, this.left, width);
    final ctx = this.ctx!;
    final position = _alignName(titleOpts.position);
    final halfFontSize = (titleFont.size ?? double.nan) / 2;
    final topPaddingPlusHalfFontSize = titlePadding.top + halfFontSize;
    double y;

    // These defaults are used when the legend is vertical.
    // When horizontal, they are computed below.
    var left = this.left;
    var maxWidth = width;

    if (isHorizontal()) {
      // Move left / right so that the title is above the legend lines
      maxWidth = lineWidths!.fold(double.negativeInfinity, jsMax);
      y = top + topPaddingPlusHalfFontSize;
      left = alignStartEnd(_alignName(opts.align), left, right - maxWidth);
    } else {
      // Move down so that the title is above the legend stack in every
      // alignment
      final maxHeight = columnSizes!.fold<double>(
        0,
        (acc, size) => jsMax(acc, size.height),
      );
      y =
          topPaddingPlusHalfFontSize +
          alignStartEnd(
            _alignName(opts.align),
            top,
            bottom -
                maxHeight -
                jsToNumber(opts.labels.padding) -
                _computeTitleHeight(),
          );
    }

    // Now that we know the left edge of the inner legend box, compute the
    // correct X coordinate from the title alignment
    final x = alignStartEnd(position, left, left + maxWidth);

    // Canvas setup
    final color = canvasStyle(titleOpts.color);
    ctx
      ..textAlign = _textAlignOf(
        rtlHelper.textAlign(toLeftRightCenter(position)),
      )
      ..textBaseline = 'middle'
      ..strokeStyle = color
      ..fillStyle = color
      ..font = titleFont.string;

    renderText(ctx, titleOpts.text, x, y, titleFont);
  }

  /// plugin.legend.js:493 `_computeTitleHeight()`.
  double _computeTitleHeight() {
    final titleOpts = LegendOptions(options).title;
    final titleFont = toFont(titleOpts.font);
    final titlePadding = toPadding(titleOpts.padding);
    return jsTruthy(titleOpts.display)
        ? titleFont.lineHeight + titlePadding.height
        : 0;
  }

  /// plugin.legend.js:503 `_getLegendItemAt(x, y)`.
  ///
  /// `_isBetween` applies `ToNumber` to its value: a JS `null` coordinate
  /// reads as 0, as Dart `null` does here. A NaN coordinate (a `touchend`)
  /// hits no item (Chart.js ADR 0037, section 14 item 3). A hit gives
  /// `this.legendItems[i]`: [undefined] for an index past the items.
  Object? _getLegendItemAt(double? x, double? y) {
    final px = x ?? 0;
    final py = y ?? 0;

    if (isBetween(px, left, right) && isBetween(py, top, bottom)) {
      // See if we are touching one of the dataset boxes
      final lh = legendHitBoxes;
      for (var i = 0; i < lh.length; ++i) {
        final hitBox = lh[i];
        final hitLeft = hitBox.left;
        final hitTop = hitBox.top;

        if (isBetween(px, hitLeft, hitLeft + hitBox.width) &&
            isBetween(py, hitTop, hitTop + hitBox.height)) {
          // Touching an element
          return jsGetIndex(legendItems ?? undefined, i.toDouble());
        }
      }
    }

    return null;
  }

  /// plugin.legend.js:528 `handleEvent(e)`.
  ///
  /// Handle an event
  /// @param {ChartEvent} e - The event to handle
  void handleEvent(types.ChartEvent e) {
    final opts = LegendOptions(options);
    if (!_isListened(e.type, opts)) {
      return;
    }

    // Chart event already has relative position in it
    final hoveredItem = _getLegendItemAt(e.x, e.y);

    if (e.type == 'mousemove' || e.type == 'mouseout') {
      final previous = _hoveredItem;
      final sameItem = _itemsEqual(previous, hoveredItem);
      if (jsTruthy(previous) && !sameItem) {
        callback(opts.onLeave, [e, previous, this], this);
      }

      _hoveredItem = hoveredItem;

      if (jsTruthy(hoveredItem) && !sameItem) {
        callback(opts.onHover, [e, hoveredItem, this], this);
      }
    } else if (jsTruthy(hoveredItem)) {
      callback(opts.onClick, [e, hoveredItem, this], this);
    }
  }
}

/// `legendItems.reverse()`: reverses [list] in place.
void _reverseInPlace(List<Object?> list) {
  for (var i = 0, j = list.length - 1; i < j; i++, j--) {
    final item = list[i];
    list[i] = list[j];
    list[j] = item;
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
  ParsedFont labelFont,
  CanvasRenderingContext2D ctx,
  Object? legendItem,
  double itemHeight0,
) {
  final itemWidth = _calculateItemWidth(legendItem, boxWidth, labelFont, ctx);
  final itemHeight = _calculateItemHeight(
    itemHeight0,
    legendItem,
    labelFont.lineHeight,
  );
  return (itemWidth: itemWidth, itemHeight: itemHeight);
}

/// plugin.legend.js:561 `calculateItemWidth(legendItem, boxWidth,
/// labelFont, ctx)`.
///
/// The text of a truthy value that is not a `String` is an array: the
/// longest line by `length`. A value that is not a `List` throws the
/// [TypeError] of `reduce` at the List cast, and an empty `List` throws the
/// [TypeError] of `reduce` with no initial value. `measureText` applies
/// `ToString` to its argument.
double _calculateItemWidth(
  Object? legendItem,
  double boxWidth,
  ParsedFont labelFont,
  CanvasRenderingContext2D ctx,
) {
  var legendItemText = _Item(legendItem).text;
  if (jsTruthy(legendItemText) && legendItemText is! String) {
    final list = legendItemText! as List<Object?>;
    // plugin.legend.js:564 `[].reduce(fn)` with no initial value throws a
    // TypeError. Dart `List.reduce` throws a StateError.
    if (list.isEmpty) {
      throw TypeError();
    }
    // The lines of the text of the user: any value, read by name.
    legendItemText = list.reduce(
      (a, b) => jsLessThan(jsGet(b, 'length'), jsGet(a, 'length')) ? a : b,
    );
  }
  return boxWidth +
      ((labelFont.size ?? double.nan) / 2) +
      ctx.measureText(jsToString(legendItemText)).width;
}

/// plugin.legend.js:569 `calculateItemHeight(_itemHeight, legendItem,
/// fontLineHeight)`.
double _calculateItemHeight(
  double itemHeight0,
  Object? legendItem,
  double fontLineHeight,
) {
  var itemHeight = itemHeight0;
  if (_Item(legendItem).text is! String) {
    itemHeight = _calculateLegendItemHeight(legendItem, fontLineHeight);
  }
  return itemHeight;
}

/// plugin.legend.js:577 `calculateLegendItemHeight(legendItem,
/// fontLineHeight)`.
double _calculateLegendItemHeight(Object? legendItem, double fontLineHeight) {
  final text = _Item(legendItem).text;
  // The text of the user: an array or another value, read by name.
  final labelHeight = jsTruthy(text) ? jsToNumber(jsGet(text, 'length')) : 0;
  return fontLineHeight * labelHeight;
}

/// plugin.legend.js:582 `isListened(type, opts)`.
bool _isListened(String type, LegendOptions opts) {
  if ((type == 'mousemove' || type == 'mouseout') &&
      (jsTruthy(opts.onHover) || jsTruthy(opts.onLeave))) {
    return true;
  }
  if (jsTruthy(opts.onClick) && (type == 'click' || type == 'mouseup')) {
    return true;
  }
  return false;
}

/// The draw options of a legend point style (:326-331), the object literal
/// of the `drawPointLegend` call.
final class _LegendPointOptions implements DrawPointOptions {
  _LegendPointOptions({
    required this.radius,
    required this.pointStyle,
    required this.rotation,
    required this.borderWidth,
  });

  @override
  final double radius;

  @override
  final Object? pointStyle;

  @override
  final double? rotation;

  @override
  final double borderWidth;
}

/// The rounded box of a legend item (:347-353), the object literal
/// `{x, y, w, h, radius}` of the `addRoundedRectPath` call.
final class _RoundedRect implements RoundedRect {
  _RoundedRect({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.radius,
  });

  @override
  final double x;

  @override
  final double y;

  @override
  final double w;

  @override
  final double h;

  @override
  final TRBLCorners radius;
}

/// The text options of a legend item (:368-371), the object literal of the
/// `renderText` call. The members that the literal leaves out are Dart
/// `null`, JS `undefined`.
final class _LegendTextOpts implements types.RenderTextOpts {
  _LegendTextOpts({required this.strikethrough, required this.textAlign});

  @override
  final bool? strikethrough;

  @override
  final String? textAlign;

  @override
  Object? get color => null;

  @override
  double? get maxWidth => null;

  @override
  double? get rotation => null;

  @override
  String? get textBaseline => null;

  @override
  (double, double)? get translation => null;

  @override
  types.BackdropOptions? get backdrop => null;

  @override
  double? get decorationWidth => null;

  @override
  Object? get strokeColor => null;

  @override
  double? get strokeWidth => null;

  @override
  bool? get underline => null;
}

/// The `config` of `new Legend(config)` from the arguments [args] of the
/// `construct` closure of [Legend.jsClass]: the reads `config.chart`,
/// `config.options` and `config.ctx` of plugin.legend.js:62-64.
///
/// An absent argument, [undefined] and JS `null` throw the [TypeError] of
/// the read `config.chart`, as upstream. A member with the value
/// [undefined] gives Dart `null`. A `chart` that is not a `types.Chart`, an
/// `options` that is not an object (a Map or a typed object) and a `ctx`
/// that is not a context throw a [TypeError]. Upstream stores such a value
/// and reads its members later.
// DIVERGES(chartjs): adapt-component-class-role, a non-Chart chart throws.
({types.Chart chart, Object? options, CanvasRenderingContext2D? ctx})
_legendConfig(List<Object?> args) {
  final config = args.isEmpty ? undefined : args[0];
  return (
    chart: _orNull(jsGet(config, 'chart'))! as types.Chart,
    options: jsObjectOrNull(jsGet(config, 'options')),
    ctx: _orNull(jsGet(config, 'ctx')) as CanvasRenderingContext2D?,
  );
}

/// Dart `null` for the [undefined] sentinel, else [value].
Object? _orNull(Object? value) => identical(value, undefined) ? null : value;

/// plugin.legend.js:645 the default `onClick(e, legendItem, legend)`: a
/// callback that will handle.
///
/// `hide` and `show` take a `double`. The raw `legendItem.datasetIndex`
/// goes through [_datasetIndexKey]: the number of its property key. For a
/// number index, this is the upstream result. The `hidden` write into a
/// narrow or unmodifiable Map throws after `hide` or `show` (differences.md
/// `js-semantics-legend-items`).
// DIVERGES(chartjs): adapt-legend-dataset-index, the index is a number.
void _onClick(Object? e, Object? legendItem, types.LegendElement legend) {
  final item = _Item(legendItem);
  final index = _datasetIndexKey(item.datasetIndex);
  final ci = legend.chart;
  if (ci.isDatasetVisible(index)) {
    ci.hide(index);
    item.hidden = true;
  } else {
    ci.show(index);
    item.hidden = false;
  }
}

/// The number index of the read `this.data.datasets[index]` with the raw
/// legend item index [value] (core.controller.js:864 and :830).
///
/// The read uses the property key `ToString(value)` ([jsToString]). Only a
/// canonical number string can be an array index. Thus the key gives its
/// number when `ToString(ToNumber(key))` is the key, else NaN. NaN finds no
/// dataset, and `show(NaN)` throws the [TypeError] of upstream at the
/// controller of the new meta (core.controller.js:895). Examples: `'1'` and
/// `[1]` give 1, and `null`, `true`, `''`, `'01'`, `'1.0'` and `' 1'` give
/// NaN.
double _datasetIndexKey(Object? value) {
  if (value is num) return value.toDouble();
  final key = jsToString(value);
  final number = jsToNumber(key);
  return jsNumberToString(number) == key ? number : double.nan;
}

/// plugin.legend.js:661 and :707 `color: (ctx) => ctx.chart.options.color`.
///
/// A chart context gives its typed `chart`, and another context its read
/// by name (a child context reads the chart of its parent). The chart
/// options give their typed read of `color`.
Object? _chartColor(Object? ctx) {
  final chart = ctx is ScriptableChartContext
      ? ctx.chart
      // A context of another class: the read by name of user code.
      : jsGet(ctx, 'chart');
  return optionOf((chart! as types.Chart).options, OptionKey.color);
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
List<Object?> _generateLabels(types.Chart chart) {
  final datasets = jsGet(chart.data, 'datasets');
  final labels = LegendOptions(chart.legend!.options).labels;
  final usePointStyle = labels.usePointStyle;
  final pointStyle = labels.pointStyle;
  final textAlign = labels.textAlign;
  final color = labels.color;
  final useBorderRadius = labels.useBorderRadius;
  final borderRadius = labels.borderRadius;

  return [
    for (final meta in chart.getSortedDatasetMetas(false))
      _datasetItem(
        datasets,
        meta,
        meta.controller!.getStyle(jsTruthy(usePointStyle) ? 0 : null),
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
  types.ChartMeta meta,
  Object style,
  Object? pointStyle,
  Object? textAlign,
  Object? color,
  Object? useBorderRadius,
  Object? borderRadius,
) {
  final borderWidth = toPadding(optionOf(style, OptionKey.borderWidth));
  final stylePointStyle = optionOf(style, OptionKey.pointStyle);
  final styleTextAlign = optionOf(style, OptionKey.textAlign);

  return LegendItem()
    ..text = jsGet(jsGetIndex(datasets, meta.index), 'label')
    ..fillStyle = optionOf(style, OptionKey.backgroundColor)
    ..fontColor = color
    ..hidden = !jsTruthy(meta.visible)
    ..lineCap = optionOf(style, OptionKey.borderCapStyle)
    ..lineDash = optionOf(style, OptionKey.borderDash)
    ..lineDashOffset = optionOf(style, OptionKey.borderDashOffset)
    ..lineJoin = optionOf(style, OptionKey.borderJoinStyle)
    ..lineWidth = (borderWidth.width + borderWidth.height) / 4
    ..strokeStyle = optionOf(style, OptionKey.borderColor)
    ..pointStyle = jsTruthy(pointStyle) ? pointStyle : stylePointStyle
    ..rotation = optionOf(style, OptionKey.rotation)
    ..textAlign = jsTruthy(textAlign) ? textAlign : styleTextAlign
    // `useBorderRadius && (borderRadius || style.borderRadius)`
    ..borderRadius = jsTruthy(useBorderRadius)
        ? (jsTruthy(borderRadius)
              ? borderRadius
              : optionOf(style, OptionKey.borderRadius))
        : useBorderRadius
    // Below is extra data used for toggling the datasets
    ..datasetIndex = meta.index;
}

/// plugin.legend.js:601 `start(chart, _args, options)`.
void _start(types.Chart chart, Object _, Object options) {
  final legend = Legend((ctx: chart.ctx, options: options, chart: chart));
  chart.legend = legend;
  layouts
    ..configure(chart, legend, options)
    ..addBox(chart, legend);
}

/// plugin.legend.js:607 `stop(chart)`. core.layouts.js:318-323 compares
/// identities only. A value that is not a LayoutItem is never in
/// chart.boxes. `delete chart.legend` is the write of Dart `null`.
void _stop(types.Chart chart, Object _, Object _) {
  final legend = chart.legend;
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
void _beforeUpdate(types.Chart chart, Object _, Object options) {
  final legend = chart.legend! as Legend;
  layouts.configure(chart, legend, options);
  legend.options = options;
}

/// plugin.legend.js:623 `afterUpdate(chart)`. The labels need to be built
/// after datasets are updated to ensure that colors and other styling are
/// correct. See https://github.com/chartjs/Chart.js/issues/6968
void _afterUpdate(types.Chart chart, Object _, Object _) {
  (chart.legend! as Legend)
    ..buildLabels()
    ..adjustHitBoxes();
}

/// plugin.legend.js:630 `afterEvent(chart, args)`: the typed `replay` and
/// `event` of [EventHookArgs]. An event of Dart `null` throws the
/// [TypeError] of the null check, as `handleEvent` throws at `e.type` of
/// `undefined` upstream.
void _afterEvent(types.Chart chart, EventHookArgs args, Object _) {
  if (!jsTruthy(args.replay)) {
    (chart.legend! as Legend).handleEvent(args.event!);
  }
}

/// plugin.legend.js:592 the default export, `Legend` of
/// `src/plugins/index.js:4` (Chart.js ADR 0038, section 1).
///
/// A typed [Plugin] with the upstream keys in the upstream order.
final Plugin legend = Plugin()
  ..id = 'legend'
  // For tests
  // @private
  ..jsWrite('_element', Legend.jsClass)
  ..start = _start
  ..stop = _stop
  ..beforeUpdate = _beforeUpdate
  ..afterUpdate = _afterUpdate
  ..afterEvent = _afterEvent
  // plugin.legend.js:636-712. A typed scope of the kind `LegendOptions`
  // (Chart.js ADR 0054 §3).
  ..defaults = (LegendOptionsScope()
    ..display = true
    ..position = 'top'
    ..align = 'center'
    ..fullSize = true
    ..reverse = false
    ..weight = 1000.0
    // a callback that will handle
    ..onClick = _onClick
    ..onHoverCell = optNull
    ..onLeaveCell = optNull
    ..labels = (LegendLabelOptionsScope()
      ..color = _chartColor
      ..boxWidth = 40.0
      ..padding = 10.0
      // Generates labels shown in the legend
      ..generateLabels = _generateLabels)
    ..title = (LegendTitleOptionsScope()
      ..color = _chartColor
      ..display = false
      ..position = 'center'
      ..text = ''))
  // plugin.legend.js:714-719. A typed scope of the kind `Descriptors`.
  ..descriptors = (DescriptorsScope()
    ..descScriptable = _scriptableDescriptor
    ..jsWrite(
      'labels',
      DescriptorsScope()..descScriptable = _labelsScriptableDescriptor,
    ));

/// plugin.legend.js:715 the `_scriptable` descriptor of the plugin.
bool _scriptableDescriptor(String name) => !name.startsWith('on');

/// plugin.legend.js:717 the `_scriptable` descriptor of `labels`.
bool _labelsScriptableDescriptor(String name) =>
    !const ['generateLabels', 'filter', 'sort'].contains(name);

/// A legend item of any class: a [LegendItem] gives its fields, and another
/// item (an object of a `generateLabels` of user code or of a controller)
/// gives the reads and writes by name of upstream ([_readItem]).
extension type const _Item(Object? item) {
  /// `item.text`.
  Object? get text => switch (item) {
    final LegendItem typed => typed.text,
    _ => _readItem(item, 'text'),
  };

  /// `item.fillStyle`.
  Object? get fillStyle => switch (item) {
    final LegendItem typed => typed.fillStyle,
    _ => _readItem(item, 'fillStyle'),
  };

  /// `item.fontColor`.
  Object? get fontColor => switch (item) {
    final LegendItem typed => typed.fontColor,
    _ => _readItem(item, 'fontColor'),
  };

  /// `item.hidden`.
  Object? get hidden => switch (item) {
    final LegendItem typed => typed.hidden,
    _ => _readItem(item, 'hidden'),
  };

  /// `item.hidden = value`.
  set hidden(Object? value) {
    switch (item) {
      case final LegendItem typed:
        typed.hidden = value;
      default:
        _writeItem(item, 'hidden', value);
    }
  }

  /// `item.lineCap`.
  Object? get lineCap => switch (item) {
    final LegendItem typed => typed.lineCap,
    _ => _readItem(item, 'lineCap'),
  };

  /// `item.lineDash`.
  Object? get lineDash => switch (item) {
    final LegendItem typed => typed.lineDash,
    _ => _readItem(item, 'lineDash'),
  };

  /// `item.lineDashOffset`.
  Object? get lineDashOffset => switch (item) {
    final LegendItem typed => typed.lineDashOffset,
    _ => _readItem(item, 'lineDashOffset'),
  };

  /// `item.lineJoin`.
  Object? get lineJoin => switch (item) {
    final LegendItem typed => typed.lineJoin,
    _ => _readItem(item, 'lineJoin'),
  };

  /// `item.lineWidth`.
  Object? get lineWidth => switch (item) {
    final LegendItem typed => typed.lineWidth,
    _ => _readItem(item, 'lineWidth'),
  };

  /// `item.strokeStyle`.
  Object? get strokeStyle => switch (item) {
    final LegendItem typed => typed.strokeStyle,
    _ => _readItem(item, 'strokeStyle'),
  };

  /// `item.pointStyle`.
  Object? get pointStyle => switch (item) {
    final LegendItem typed => typed.pointStyle,
    _ => _readItem(item, 'pointStyle'),
  };

  /// `item.rotation`.
  Object? get rotation => switch (item) {
    final LegendItem typed => typed.rotation,
    _ => _readItem(item, 'rotation'),
  };

  /// `item.textAlign`.
  Object? get textAlign => switch (item) {
    final LegendItem typed => typed.textAlign,
    _ => _readItem(item, 'textAlign'),
  };

  /// `item.textAlign = value`.
  set textAlign(Object? value) {
    switch (item) {
      case final LegendItem typed:
        typed.textAlign = value;
      default:
        _writeItem(item, 'textAlign', value);
    }
  }

  /// `item.borderRadius`.
  Object? get borderRadius => switch (item) {
    final LegendItem typed => typed.borderRadius,
    _ => _readItem(item, 'borderRadius'),
  };

  /// `item.datasetIndex`.
  Object? get datasetIndex => switch (item) {
    final LegendItem typed => typed.datasetIndex,
    _ => _readItem(item, 'datasetIndex'),
  };

  /// `item.index`.
  Object? get index => switch (item) {
    final LegendItem typed => typed.index,
    _ => _readItem(item, 'index'),
  };
}

/// The read by name `item[name]` of a legend item of user code: [jsGet].
/// An item of `undefined` or JS `null` throws its [TypeError], as upstream.
Object? _readItem(Object? item, String name) => jsGet(item, name);

/// The write by name `item[name] = value` of a legend item of user code. A
/// write into an item that is not an object throws a [TypeError], as the
/// write of strict mode does. A narrow or unmodifiable Map throws too
/// (differences.md `js-semantics-legend-items`).
void _writeItem(Object? item, String name, Object? value) {
  // DIVERGES(chartjs): js-semantics-legend-items, a narrow or fixed Map.
  (item! as Map<String, Object?>)[name] = value;
}

/// `LegendItem` (`index.d.ts`): an item of the legend, the object of the
/// built-in `generateLabels` (plugin.legend.js:680-701), with the upstream
/// keys in the upstream key order. `index` is the key of the items of the
/// doughnut and polar area controllers (`index.d.ts` `LegendItem.index`).
///
/// Each field holds any JS value: a user callback (`filter`, `sort`,
/// `onClick`) reads and writes the item by name through the face, and a key
/// that user code adds is an extra (Chart.js ADR 0054 §12).
final class LegendItem extends TypedRecord implements types.TypedLegendItem {
  /// An object without own keys.
  LegendItem();

  static const List<String> _fieldNames = [
    'text',
    'fillStyle',
    'fontColor',
    'hidden',
    'lineCap',
    'lineDash',
    'lineDashOffset',
    'lineJoin',
    'lineWidth',
    'strokeStyle',
    'pointStyle',
    'rotation',
    'textAlign',
    'borderRadius',
    'datasetIndex',
    'index',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'text' => 0,
    'fillStyle' => 1,
    'fontColor' => 2,
    'hidden' => 3,
    'lineCap' => 4,
    'lineDash' => 5,
    'lineDashOffset' => 6,
    'lineJoin' => 7,
    'lineWidth' => 8,
    'strokeStyle' => 9,
    'pointStyle' => 10,
    'rotation' => 11,
    'textAlign' => 12,
    'borderRadius' => 13,
    'datasetIndex' => 14,
    'index' => 15,
    _ => -1,
  };

  Object? _text;

  Object? _fillStyle;

  Object? _fontColor;

  Object? _hidden;

  Object? _lineCap;

  Object? _lineDash;

  Object? _lineDashOffset;

  Object? _lineJoin;

  Object? _lineWidth;

  Object? _strokeStyle;

  Object? _pointStyle;

  Object? _rotation;

  Object? _textAlign;

  Object? _borderRadius;

  Object? _datasetIndex;

  Object? _index;

  /// `text`, or [undefined] when absent.
  @override
  Object? get text => hasSlot(0) ? _text : undefined;

  set text(Object? value) {
    _text = value;
    touchSlot(0);
  }

  /// `fillStyle`, or [undefined] when absent.
  Object? get fillStyle => hasSlot(1) ? _fillStyle : undefined;

  set fillStyle(Object? value) {
    _fillStyle = value;
    touchSlot(1);
  }

  /// `fontColor`, or [undefined] when absent.
  Object? get fontColor => hasSlot(2) ? _fontColor : undefined;

  set fontColor(Object? value) {
    _fontColor = value;
    touchSlot(2);
  }

  /// `hidden`, or [undefined] when absent.
  @override
  Object? get hidden => hasSlot(3) ? _hidden : undefined;

  set hidden(Object? value) {
    _hidden = value;
    touchSlot(3);
  }

  /// `lineCap`, or [undefined] when absent.
  Object? get lineCap => hasSlot(4) ? _lineCap : undefined;

  set lineCap(Object? value) {
    _lineCap = value;
    touchSlot(4);
  }

  /// `lineDash`, or [undefined] when absent.
  Object? get lineDash => hasSlot(5) ? _lineDash : undefined;

  set lineDash(Object? value) {
    _lineDash = value;
    touchSlot(5);
  }

  /// `lineDashOffset`, or [undefined] when absent.
  Object? get lineDashOffset => hasSlot(6) ? _lineDashOffset : undefined;

  set lineDashOffset(Object? value) {
    _lineDashOffset = value;
    touchSlot(6);
  }

  /// `lineJoin`, or [undefined] when absent.
  Object? get lineJoin => hasSlot(7) ? _lineJoin : undefined;

  set lineJoin(Object? value) {
    _lineJoin = value;
    touchSlot(7);
  }

  /// `lineWidth`, or [undefined] when absent.
  Object? get lineWidth => hasSlot(8) ? _lineWidth : undefined;

  set lineWidth(Object? value) {
    _lineWidth = value;
    touchSlot(8);
  }

  /// `strokeStyle`, or [undefined] when absent.
  Object? get strokeStyle => hasSlot(9) ? _strokeStyle : undefined;

  set strokeStyle(Object? value) {
    _strokeStyle = value;
    touchSlot(9);
  }

  /// `pointStyle`, or [undefined] when absent.
  Object? get pointStyle => hasSlot(10) ? _pointStyle : undefined;

  set pointStyle(Object? value) {
    _pointStyle = value;
    touchSlot(10);
  }

  /// `rotation`, or [undefined] when absent.
  Object? get rotation => hasSlot(11) ? _rotation : undefined;

  set rotation(Object? value) {
    _rotation = value;
    touchSlot(11);
  }

  /// `textAlign`, or [undefined] when absent.
  Object? get textAlign => hasSlot(12) ? _textAlign : undefined;

  set textAlign(Object? value) {
    _textAlign = value;
    touchSlot(12);
  }

  /// `borderRadius`, or [undefined] when absent.
  Object? get borderRadius => hasSlot(13) ? _borderRadius : undefined;

  set borderRadius(Object? value) {
    _borderRadius = value;
    touchSlot(13);
  }

  /// `datasetIndex`, or [undefined] when absent.
  @override
  Object? get datasetIndex => hasSlot(14) ? _datasetIndex : undefined;

  set datasetIndex(Object? value) {
    _datasetIndex = value;
    touchSlot(14);
  }

  /// `index`, or [undefined] when absent.
  @override
  Object? get index => hasSlot(15) ? _index : undefined;

  set index(Object? value) {
    _index = value;
    touchSlot(15);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _text,
    1 => _fillStyle,
    2 => _fontColor,
    3 => _hidden,
    4 => _lineCap,
    5 => _lineDash,
    6 => _lineDashOffset,
    7 => _lineJoin,
    8 => _lineWidth,
    9 => _strokeStyle,
    10 => _pointStyle,
    11 => _rotation,
    12 => _textAlign,
    13 => _borderRadius,
    14 => _datasetIndex,
    _ => _index,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _text = value;
      case 1:
        _fillStyle = value;
      case 2:
        _fontColor = value;
      case 3:
        _hidden = value;
      case 4:
        _lineCap = value;
      case 5:
        _lineDash = value;
      case 6:
        _lineDashOffset = value;
      case 7:
        _lineJoin = value;
      case 8:
        _lineWidth = value;
      case 9:
        _strokeStyle = value;
      case 10:
        _pointStyle = value;
      case 11:
        _rotation = value;
      case 12:
        _textAlign = value;
      case 13:
        _borderRadius = value;
      case 14:
        _datasetIndex = value;
      default:
        _index = value;
    }
    return true;
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _text = null;
      case 1:
        _fillStyle = null;
      case 2:
        _fontColor = null;
      case 3:
        _hidden = null;
      case 4:
        _lineCap = null;
      case 5:
        _lineDash = null;
      case 6:
        _lineDashOffset = null;
      case 7:
        _lineJoin = null;
      case 8:
        _lineWidth = null;
      case 9:
        _strokeStyle = null;
      case 10:
        _pointStyle = null;
      case 11:
        _rotation = null;
      case 12:
        _textAlign = null;
      case 13:
        _borderRadius = null;
      case 14:
        _datasetIndex = null;
      default:
        _index = null;
    }
  }
}

/// A hit box of a legend item (plugin.legend.js:183 and :217): `{left,
/// top, row, width, height}` of a horizontal legend and `{left, top, col,
/// width, height}` of a vertical legend, in this key order. `index.d.ts`
/// does not declare it.
///
/// The fields are numbers. A write by name of another value keeps the raw
/// value for the face and its `ToNumber` in the field, the number that each
/// arithmetic read of upstream gives (Chart.js ADR 0054 §6).
final class LegendHitBox extends TypedRecord
    implements types.TypedLegendHitBox {
  /// The hit box `{left, top, row, width, height}` of a horizontal legend
  /// (:183).
  LegendHitBox.row({
    required double left,
    required double top,
    required double row,
    required double width,
    required double height,
  }) {
    this
      ..left = left
      ..top = top
      ..row = row
      ..width = width
      ..height = height;
  }

  /// The hit box `{left, top, col, width, height}` of a vertical legend
  /// (:217).
  LegendHitBox.col({
    required double left,
    required double top,
    required double col,
    required double width,
    required double height,
  }) {
    this
      ..left = left
      ..top = top
      ..col = col
      ..width = width
      ..height = height;
  }

  static const List<String> _fieldNames = [
    'left',
    'top',
    'row',
    'col',
    'width',
    'height',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'left' => 0,
    'top' => 1,
    'row' => 2,
    'col' => 3,
    'width' => 4,
    'height' => 5,
    _ => -1,
  };

  double _left = double.nan;

  double _top = double.nan;

  double _row = double.nan;

  double _col = double.nan;

  double _width = double.nan;

  double _height = double.nan;

  /// `left`: NaN when absent, the `ToNumber` of a value that is not a
  /// number.
  @override
  double get left => _left;

  set left(double value) {
    _left = value;
    touchSlot(0);
  }

  /// `top`: NaN when absent, the `ToNumber` of a value that is not a
  /// number.
  @override
  double get top => _top;

  set top(double value) {
    _top = value;
    touchSlot(1);
  }

  /// `row`: NaN when absent, the `ToNumber` of a value that is not a
  /// number.
  double get row => _row;

  set row(double value) {
    _row = value;
    touchSlot(2);
  }

  /// `col`: NaN when absent, the `ToNumber` of a value that is not a
  /// number.
  double get col => _col;

  set col(double value) {
    _col = value;
    touchSlot(3);
  }

  /// `width`: NaN when absent, the `ToNumber` of a value that is not a
  /// number.
  @override
  double get width => _width;

  set width(double value) {
    _width = value;
    touchSlot(4);
  }

  /// `height`: NaN when absent, the `ToNumber` of a value that is not a
  /// number.
  @override
  double get height => _height;

  set height(double value) {
    _height = value;
    touchSlot(5);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _left,
    1 => _top,
    2 => _row,
    3 => _col,
    4 => _width,
    _ => _height,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    final number = value is double ? value : jsToNumber(value);
    switch (slot) {
      case 0:
        _left = number;
      case 1:
        _top = number;
      case 2:
        _row = number;
      case 3:
        _col = number;
      case 4:
        _width = number;
      default:
        _height = number;
    }
    return value is double;
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _left = double.nan;
      case 1:
        _top = double.nan;
      case 2:
        _row = double.nan;
      case 3:
        _col = double.nan;
      case 4:
        _width = double.nan;
      default:
        _height = double.nan;
    }
  }
}

/// The size `{width, height}` of a column of a vertical legend
/// (plugin.legend.js:209 and :224). The fields are numbers, as in
/// [LegendHitBox].
final class LegendColumnSize extends TypedRecord {
  /// The column size `{width, height}`.
  LegendColumnSize({required double width, required double height}) {
    this
      ..width = width
      ..height = height;
  }

  static const List<String> _fieldNames = [
    'width',
    'height',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'width' => 0,
    'height' => 1,
    _ => -1,
  };

  double _width = double.nan;

  double _height = double.nan;

  /// `width`: NaN when absent, the `ToNumber` of a value that is not a
  /// number.
  double get width => _width;

  set width(double value) {
    _width = value;
    touchSlot(0);
  }

  /// `height`: NaN when absent, the `ToNumber` of a value that is not a
  /// number.
  double get height => _height;

  set height(double value) {
    _height = value;
    touchSlot(1);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _width,
    _ => _height,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    final number = value is double ? value : jsToNumber(value);
    switch (slot) {
      case 0:
        _width = number;
      default:
        _height = number;
    }
    return value is double;
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _width = double.nan;
      default:
        _height = double.nan;
    }
  }
}
