// Ported from Chart.js v4.6.1 src/plugins/plugin.legend.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.legend.js`.
///
/// [Legend] is the layout box of the chart legend. [legend] is the plugin
/// object, the default export of the upstream file and `Legend` of
/// `src/plugins/index.js:4` (Chart.js ADR 0038, section 1). It is a mutable
/// Map with the upstream keys in the upstream order: `id`, `_element`,
/// `start`, `stop`, `beforeUpdate`, `afterUpdate`, `afterEvent`, `defaults`
/// and `descriptors`.
///
/// Each hook is a closure with the upstream parameter count and the typed
/// parameters `(types.Chart chart, AnyObject args, AnyObject options)`
/// (Chart.js ADR 0038, section 3). `chart.legend` is a field of
/// `types.Chart`: Dart `null` stands for JS `undefined` and for the
/// `delete` of `plugin.legend.js:609`.
///
/// The fields of the box start as the fields of `Scale` start: NaN for the
/// edges, `maxWidth` and `maxHeight`, the `undefined` sentinel for
/// `position` and `weight`, and `false` for `fullSize` (Chart.js ADR 0038,
/// section 7).
///
/// The legend items, the hit boxes and the column sizes are plain Maps with
/// the upstream keys, as upstream. A user callback, a spec and a fixture
/// read them by name (`plugin.legend.tests.js:502-507`,
/// `test/fixtures/plugin.legend/horizontal-rtl-hitbox.js:37-38`). The hit
/// test reads at most one hit box for each item of an event, so a typed
/// class gives no gain that a frame can show (Chart.js ADR 0037, Open 9).
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
    show ParsedFont, toFont, toPadding, toTRBLCorners;
import 'package:flutter_chartjs_port/src/helpers/helpers.rtl.dart'
    show getRtlAdapter, overrideTextDirection, restoreTextDirection;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsSort;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsMin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsGetIndex;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart'
    show canvasKeyword, canvasLineDash, canvasNumber, canvasStyle;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/layout.dart';

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
  Object? labelOpts,
  double fontSize,
) {
  // DIVERGES(chartjs): adapt-legend-number-options, a box size is a number.
  final rawHeight = jsGet(labelOpts, 'boxHeight');
  final rawWidth = jsGet(labelOpts, 'boxWidth');
  var boxHeight = identical(rawHeight, undefined)
      ? fontSize
      : jsToNumber(rawHeight);
  var boxWidth = identical(rawWidth, undefined)
      ? fontSize
      : jsToNumber(rawWidth);

  if (jsTruthy(jsGet(labelOpts, 'usePointStyle'))) {
    boxHeight = jsMin(boxHeight, fontSize);
    final pointStyleWidth = jsGet(labelOpts, 'pointStyleWidth');
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
    _strictEquals(jsGet(a, 'datasetIndex'), jsGet(b, 'datasetIndex')) &&
    _strictEquals(jsGet(a, 'index'), jsGet(b, 'index'));

/// The `padding` label option (`options.labels.padding`, :161, :192, :235,
/// :289) as a number. index.d.ts types it as a number. A string joins in
/// the `+` of upstream (for example :165, :185 and :209; :197 starts
/// `totalWidth` with the raw value), and the port adds its `ToNumber`
/// (differences.md `adapt-legend-number-options`).
double _labelPadding(Object? labelOpts) =>
    // DIVERGES(chartjs): adapt-legend-number-options, the padding is a number.
    jsToNumber(jsGet(labelOpts, 'padding'));

/// The JS operator `===` on two raw values: two numbers compare by value
/// (NaN is not equal to itself, and -0 equals +0), two strings by their code
/// units, and other values by identity.
bool _strictEquals(Object? a, Object? b) {
  if (a is num && b is num) return a.toDouble() == b.toDouble();
  if (a is String && b is String) return a == b;
  return identical(a, b);
}

/// A number of a legend Map (a hit box or a column size), as an arithmetic
/// read of upstream gives it: the value itself for a `double`, else its
/// `ToNumber`.
double _num(Object? value) => value is double ? value : jsToNumber(value);

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
    ({types.Chart chart, AnyObject? options, CanvasRenderingContext2D? ctx})
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
  /// Each hit box is a Map with the upstream keys: `left`, `top`, `row`,
  /// `width` and `height` for a horizontal legend (:183), `left`, `top`,
  /// `col`, `width` and `height` for a vertical legend (:217).
  /// `index.d.ts` does not declare it, so it is not a member of
  /// `types.LegendElement`: a reader casts to [Legend] (Chart.js ADR 0038,
  /// section 6).
  List<AnyObject> legendHitBoxes = [];

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
  /// The items are the values of `generateLabels`, as upstream. Each read
  /// of an item member is a [jsGet].
  @override
  List<Object?>? legendItems;

  /// plugin.legend.js:66 `columnSizes`: `{width, height}` of each column of
  /// a vertical legend. Dart `null` stands for JS `undefined`.
  List<AnyObject>? columnSizes;

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
  Map<String, Object?> get options => super.options!;

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
    final labels = jsGet(options, 'labels');
    final labelOpts = jsTruthy(labels) ? labels : <String, Object?>{};
    final generated = callback(jsGet(labelOpts, 'generateLabels'), [
      chart,
    ], this);
    // DIVERGES(chartjs): adapt-legend-items-list, the items are a List.
    var legendItems = jsTruthy(generated)
        ? generated! as List<Object?>
        : <Object?>[];

    final filter = jsGet(labelOpts, 'filter');
    if (jsTruthy(filter)) {
      legendItems = [
        for (final item in legendItems)
          if (jsTruthy(
            jsCall(filter, [item, chart.data], thisArg: labelOpts),
          ))
            item,
      ];
    }

    final sort = jsGet(labelOpts, 'sort');
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

    if (jsTruthy(jsGet(options, 'reverse'))) {
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

    if (!jsTruthy(jsGet(options, 'display'))) {
      this.width = this.height = 0;
      return;
    }

    final labelOpts = jsGet(options, 'labels');
    final labelFont = toFont(jsGet(labelOpts, 'font'));
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

    final maxWidthOption = jsGet(options, 'maxWidth');
    final maxHeightOption = jsGet(options, 'maxHeight');
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
    final padding = _labelPadding(jsGet(options, 'labels'));
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
          ctx.measureText(jsToString(jsGet(legendItem, 'text'))).width;

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

      hitboxes.add(<String, Object?>{
        'left': 0.0,
        'top': top,
        'row': row,
        'width': itemWidth,
        'height': itemHeight,
      });

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
    final padding = _labelPadding(jsGet(options, 'labels'));
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
        columnSizes.add(<String, Object?>{
          'width': currentColWidth,
          'height': currentColHeight,
        });
        left += currentColWidth + padding;
        col++;
        currentColWidth = currentColHeight = 0;
      }

      // Store the hitbox width and height here. Final position will be
      // updated in `draw`
      hitboxes.add(<String, Object?>{
        'left': left,
        'top': currentColHeight,
        'col': col,
        'width': itemWidth,
        'height': itemHeight,
      });

      // Get max width
      currentColWidth = jsMax(currentColWidth, itemWidth);
      currentColHeight += itemHeight + padding;
    }

    totalWidth += currentColWidth;
    // previous column size
    columnSizes.add(<String, Object?>{
      'width': currentColWidth,
      'height': currentColHeight,
    });

    return totalWidth;
  }

  /// plugin.legend.js:230 `adjustHitBoxes()`.
  void adjustHitBoxes() {
    final options = this.options;
    if (!jsTruthy(jsGet(options, 'display'))) {
      return;
    }
    final titleHeight = _computeTitleHeight();
    final hitboxes = legendHitBoxes;
    final align = _alignName(jsGet(options, 'align'));
    final padding = _labelPadding(jsGet(options, 'labels'));
    final rtlHelper = getRtlAdapter(jsGet(options, 'rtl'), left, width);
    if (isHorizontal()) {
      var row = 0.0;
      var left = alignStartEnd(
        align,
        this.left + padding,
        right - _lineWidthAt(row),
      );
      for (final hitbox in hitboxes) {
        final hitboxRow = _num(hitbox['row']);
        if (row != hitboxRow) {
          row = hitboxRow;
          left = alignStartEnd(
            align,
            this.left + padding,
            right - _lineWidthAt(row),
          );
        }
        final hitboxWidth = _num(hitbox['width']);
        // `hitbox.top += this.top + titleHeight + padding`: the right side
        // adds first.
        hitbox['top'] = _num(hitbox['top']) + (top + titleHeight + padding);
        hitbox['left'] = rtlHelper.leftForLtr(rtlHelper.x(left), hitboxWidth);
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
        final hitboxCol = _num(hitbox['col']);
        if (hitboxCol != col) {
          col = hitboxCol;
          top = alignStartEnd(
            align,
            this.top + titleHeight + padding,
            bottom - _columnHeightAt(col),
          );
        }
        hitbox['top'] = top;
        final hitboxWidth = _num(hitbox['width']);
        // `hitbox.left += this.left + padding`: the right side adds first.
        hitbox['left'] = _num(hitbox['left']) + (left + padding);
        hitbox['left'] = rtlHelper.leftForLtr(
          rtlHelper.x(_num(hitbox['left'])),
          hitboxWidth,
        );
        top += _num(hitbox['height']) + padding;
      }
    }
  }

  /// `this.lineWidths[row]` as a number: [undefined] gives NaN. Without
  /// line widths, the read throws a [TypeError], as upstream.
  double _lineWidthAt(double row) =>
      jsToNumber(jsGetIndex(lineWidths ?? undefined, row));

  /// `this.columnSizes[col].height` as a number. An absent column throws the
  /// [TypeError] of the read of `height` of `undefined`, as upstream.
  double _columnHeightAt(double col) =>
      _num(jsGet(jsGetIndex(columnSizes ?? undefined, col), 'height'));

  /// plugin.legend.js:265 `isHorizontal()`.
  @override
  bool isHorizontal() {
    final position = jsGet(options, 'position');
    return position == 'top' || position == 'bottom';
  }

  /// plugin.legend.js:269 `draw()`.
  ///
  /// Upstream takes no argument. The default layer of `layouts.addBox`
  /// passes the chart area (core.layouts.js:305), and the legend ignores it
  /// (Chart.js ADR 0038, section 7).
  @override
  void draw([ChartArea? chartArea]) {
    if (jsTruthy(jsGet(options, 'display'))) {
      final ctx = this.ctx!;
      clipArea(ctx, this);

      _draw();

      unclipArea(ctx);
    }
  }

  /// plugin.legend.js:283 `_draw()`.
  void _draw() {
    final opts = options;
    final columnSizes = this.columnSizes;
    final lineWidths = this.lineWidths;
    final ctx = this.ctx!;
    final align = _alignName(jsGet(opts, 'align'));
    final labelOpts = jsGet(opts, 'labels');
    // The singleton read of `defaults.color` (:286).
    final defaultColor = defaults['color'];
    final rtlHelper = getRtlAdapter(jsGet(opts, 'rtl'), left, width);
    final labelFont = toFont(jsGet(labelOpts, 'font'));
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
    void drawLegendBox(double x, double y, Object? legendItem) {
      if (boxWidth.isNaN || boxWidth <= 0 || boxHeight.isNaN || boxHeight < 0) {
        return;
      }

      // Set the ctx for the box
      ctx.save();

      final lineWidth = valueOrDefault(jsGet(legendItem, 'lineWidth'), 1);
      ctx
        ..fillStyle = canvasStyle(
          valueOrDefault(jsGet(legendItem, 'fillStyle'), defaultColor),
        )
        ..lineCap = canvasKeyword(
          valueOrDefault(jsGet(legendItem, 'lineCap'), 'butt'),
        )
        ..lineDashOffset = canvasNumber(
          valueOrDefault(jsGet(legendItem, 'lineDashOffset'), 0),
        )
        ..lineJoin = canvasKeyword(
          valueOrDefault(jsGet(legendItem, 'lineJoin'), 'miter'),
        )
        ..lineWidth = canvasNumber(lineWidth)
        ..strokeStyle = canvasStyle(
          valueOrDefault(jsGet(legendItem, 'strokeStyle'), defaultColor),
        )
        ..setLineDash(
          canvasLineDash(
            valueOrDefault(jsGet(legendItem, 'lineDash'), <Object?>[]),
          ),
        );

      if (jsTruthy(jsGet(labelOpts, 'usePointStyle'))) {
        // Recalculate x and y for drawPoint() because its expecting
        // x and y to be center of figure (instead of top left)
        final drawOptions = _LegendPointOptions(
          radius: boxHeight * _sqrt2 / 2,
          pointStyle: jsGet(legendItem, 'pointStyle'),
          rotation: _rotationOf(jsGet(legendItem, 'rotation')),
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
          jsTruthy(jsGet(labelOpts, 'pointStyleWidth')) ? boxWidth : null,
        );
      } else {
        // Draw box as legend symbol
        // Adjust position when boxHeight < fontSize (want it centered)
        final yBoxTop = y + jsMax((fontSize - boxHeight) / 2, 0);
        final xBoxLeft = rtlHelper.leftForLtr(x, boxWidth);
        final borderRadius = toTRBLCorners(jsGet(legendItem, 'borderRadius'));

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

    void fillText(double x, double y, Object? legendItem) {
      renderText(
        ctx,
        jsGet(legendItem, 'text'),
        x,
        y + (itemHeight / 2),
        labelFont,
        _LegendTextOpts(
          strikethrough: jsTruthy(jsGet(legendItem, 'hidden')),
          textAlign: _textAlignOf(
            rtlHelper.textAlign(jsGet(legendItem, 'textAlign')),
          ),
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
          bottom -
              _num(jsGet(jsGetIndex(columnSizes ?? undefined, 0), 'height')),
        ),
        line: 0,
      );
    }

    overrideTextDirection(ctx, jsGet(opts, 'textDirection'));

    final lineHeight = itemHeight + padding;
    final legendItems = this.legendItems!;
    for (var i = 0; i < legendItems.length; i++) {
      final legendItem = legendItems[i];
      final fontColor = canvasStyle(jsGet(legendItem, 'fontColor'));
      ctx
        ..strokeStyle =
            fontColor // for strikethrough effect
        ..fillStyle = fontColor; // render in correct colour

      final textWidth = ctx
          .measureText(jsToString(jsGet(legendItem, 'text')))
          .width;
      var itemAlign = jsGet(legendItem, 'textAlign');
      if (!jsTruthy(itemAlign)) {
        itemAlign = jsGet(labelOpts, 'textAlign');
        // A write into an item that is not an object throws a TypeError, as
        // the write of strict mode does. A narrow or unmodifiable Map throws
        // too (differences.md `js-semantics-legend-items`).
        // DIVERGES(chartjs): js-semantics-legend-items, a narrow or fixed Map.
        (legendItem! as Map<String, Object?>)['textAlign'] = itemAlign;
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
        x =
            x +
            _num(
              jsGet(jsGetIndex(columnSizes ?? undefined, cursor.line), 'width'),
            ) +
            padding;
        final line = cursor.line + 1;
        y = alignStartEnd(
          align,
          top + titleHeight + padding,
          bottom -
              _num(jsGet(jsGetIndex(columnSizes ?? undefined, line), 'height')),
        );
        cursor = (x: x, y: y, line: line);
      }

      final realX = rtlHelper.x(x);

      drawLegendBox(realX, y, legendItem);

      x = textX(
        _alignName(textAlign),
        x + boxWidth + halfFontSize,
        isHorizontal ? x + width : right,
        jsTruthy(jsGet(opts, 'rtl')),
      );

      // Fill the actual label
      fillText(rtlHelper.x(x), y, legendItem);

      if (isHorizontal) {
        cursor = (
          x: cursor.x + (width + padding),
          y: cursor.y,
          line: cursor.line,
        );
      } else if (jsGet(legendItem, 'text') is! String) {
        final fontLineHeight = labelFont.lineHeight;
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

    restoreTextDirection(ctx, jsGet(opts, 'textDirection'));
  }

  /// plugin.legend.js:443 `drawTitle()`.
  ///
  /// @protected
  void drawTitle() {
    final opts = options;
    final titleOpts = jsGet(opts, 'title');
    final titleFont = toFont(jsGet(titleOpts, 'font'));
    final titlePadding = toPadding(jsGet(titleOpts, 'padding'));

    if (!jsTruthy(jsGet(titleOpts, 'display'))) {
      return;
    }

    final rtlHelper = getRtlAdapter(jsGet(opts, 'rtl'), this.left, width);
    final ctx = this.ctx!;
    final position = _alignName(jsGet(titleOpts, 'position'));
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
      left = alignStartEnd(
        _alignName(jsGet(opts, 'align')),
        left,
        right - maxWidth,
      );
    } else {
      // Move down so that the title is above the legend stack in every
      // alignment
      final maxHeight = columnSizes!.fold<double>(
        0,
        (acc, size) => jsMax(acc, _num(jsGet(size, 'height'))),
      );
      y =
          topPaddingPlusHalfFontSize +
          alignStartEnd(
            _alignName(jsGet(opts, 'align')),
            top,
            bottom -
                maxHeight -
                jsToNumber(jsGet(jsGet(opts, 'labels'), 'padding')) -
                _computeTitleHeight(),
          );
    }

    // Now that we know the left edge of the inner legend box, compute the
    // correct X coordinate from the title alignment
    final x = alignStartEnd(position, left, left + maxWidth);

    // Canvas setup
    final color = canvasStyle(jsGet(titleOpts, 'color'));
    ctx
      ..textAlign = _textAlignOf(
        rtlHelper.textAlign(toLeftRightCenter(position)),
      )
      ..textBaseline = 'middle'
      ..strokeStyle = color
      ..fillStyle = color
      ..font = titleFont.string;

    renderText(ctx, jsGet(titleOpts, 'text'), x, y, titleFont);
  }

  /// plugin.legend.js:493 `_computeTitleHeight()`.
  double _computeTitleHeight() {
    final titleOpts = jsGet(options, 'title');
    final titleFont = toFont(jsGet(titleOpts, 'font'));
    final titlePadding = toPadding(jsGet(titleOpts, 'padding'));
    return jsTruthy(jsGet(titleOpts, 'display'))
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
        final hitLeft = _num(hitBox['left']);
        final hitTop = _num(hitBox['top']);

        if (isBetween(px, hitLeft, hitLeft + _num(hitBox['width'])) &&
            isBetween(py, hitTop, hitTop + _num(hitBox['height']))) {
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
    final opts = options;
    if (!_isListened(e.type, opts)) {
      return;
    }

    // Chart event already has relative position in it
    final hoveredItem = _getLegendItemAt(e.x, e.y);

    if (e.type == 'mousemove' || e.type == 'mouseout') {
      final previous = _hoveredItem;
      final sameItem = _itemsEqual(previous, hoveredItem);
      if (jsTruthy(previous) && !sameItem) {
        callback(jsGet(opts, 'onLeave'), [e, previous, this], this);
      }

      _hoveredItem = hoveredItem;

      if (jsTruthy(hoveredItem) && !sameItem) {
        callback(jsGet(opts, 'onHover'), [e, hoveredItem, this], this);
      }
    } else if (jsTruthy(hoveredItem)) {
      callback(jsGet(opts, 'onClick'), [e, hoveredItem, this], this);
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
  var legendItemText = jsGet(legendItem, 'text');
  if (jsTruthy(legendItemText) && legendItemText is! String) {
    final list = legendItemText! as List<Object?>;
    // plugin.legend.js:564 `[].reduce(fn)` with no initial value throws a
    // TypeError. Dart `List.reduce` throws a StateError.
    if (list.isEmpty) {
      throw TypeError();
    }
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
  if (jsGet(legendItem, 'text') is! String) {
    itemHeight = _calculateLegendItemHeight(legendItem, fontLineHeight);
  }
  return itemHeight;
}

/// plugin.legend.js:577 `calculateLegendItemHeight(legendItem,
/// fontLineHeight)`.
double _calculateLegendItemHeight(Object? legendItem, double fontLineHeight) {
  final text = jsGet(legendItem, 'text');
  final labelHeight = jsTruthy(text) ? jsToNumber(jsGet(text, 'length')) : 0;
  return fontLineHeight * labelHeight;
}

/// plugin.legend.js:582 `isListened(type, opts)`.
bool _isListened(String type, Object? opts) {
  if ((type == 'mousemove' || type == 'mouseout') &&
      (jsTruthy(jsGet(opts, 'onHover')) || jsTruthy(jsGet(opts, 'onLeave')))) {
    return true;
  }
  if (jsTruthy(jsGet(opts, 'onClick')) &&
      (type == 'click' || type == 'mouseup')) {
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
/// `options` that is not a Map and a `ctx` that is not a context throw a
/// [TypeError]. Upstream stores such a value and reads its members later.
// DIVERGES(chartjs): adapt-component-class-role, a non-Chart chart throws.
({types.Chart chart, AnyObject? options, CanvasRenderingContext2D? ctx})
_legendConfig(List<Object?> args) {
  final config = args.isEmpty ? undefined : args[0];
  return (
    chart: _orNull(jsGet(config, 'chart'))! as types.Chart,
    options: _orNull(jsGet(config, 'options')) as AnyObject?,
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
  final index = _datasetIndexKey(jsGet(legendItem, 'datasetIndex'));
  final ci = legend.chart;
  if (ci.isDatasetVisible(index)) {
    ci.hide(index);
    // DIVERGES(chartjs): js-semantics-legend-items, a narrow or fixed Map.
    (legendItem! as Map<String, Object?>)['hidden'] = true;
  } else {
    ci.show(index);
    // DIVERGES(chartjs): js-semantics-legend-items, a narrow or fixed Map.
    (legendItem! as Map<String, Object?>)['hidden'] = false;
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
Object? _chartColor(Object? ctx) =>
    jsGet((jsGet(ctx, 'chart')! as types.Chart).options, 'color');

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
/// Each style value is a read [jsGet]: an absent key gives [undefined]. The
/// upstream call `_getSortedDatasetMetas()` has no argument, a falsy
/// `filterVisible`.
List<Object?> _generateLabels(types.Chart chart) {
  final datasets = jsGet(chart.data, 'datasets');
  final labels = jsGet(chart.legend!.options, 'labels');
  final usePointStyle = jsGet(labels, 'usePointStyle');
  final pointStyle = jsGet(labels, 'pointStyle');
  final textAlign = jsGet(labels, 'textAlign');
  final color = jsGet(labels, 'color');
  final useBorderRadius = jsGet(labels, 'useBorderRadius');
  final borderRadius = jsGet(labels, 'borderRadius');

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

/// The item of [meta] of `generateLabels` (:680-701), in the upstream key
/// order.
AnyObject _datasetItem(
  Object? datasets,
  types.ChartMeta meta,
  Map<String, Object?> style,
  Object? pointStyle,
  Object? textAlign,
  Object? color,
  Object? useBorderRadius,
  Object? borderRadius,
) {
  final borderWidth = toPadding(jsGet(style, 'borderWidth'));
  final stylePointStyle = jsGet(style, 'pointStyle');
  final styleTextAlign = jsGet(style, 'textAlign');

  return <String, Object?>{
    'text': jsGet(jsGetIndex(datasets, meta.index), 'label'),
    'fillStyle': jsGet(style, 'backgroundColor'),
    'fontColor': color,
    'hidden': !jsTruthy(meta.visible),
    'lineCap': jsGet(style, 'borderCapStyle'),
    'lineDash': jsGet(style, 'borderDash'),
    'lineDashOffset': jsGet(style, 'borderDashOffset'),
    'lineJoin': jsGet(style, 'borderJoinStyle'),
    'lineWidth': (borderWidth.width + borderWidth.height) / 4,
    'strokeStyle': jsGet(style, 'borderColor'),
    'pointStyle': jsTruthy(pointStyle) ? pointStyle : stylePointStyle,
    'rotation': jsGet(style, 'rotation'),
    'textAlign': jsTruthy(textAlign) ? textAlign : styleTextAlign,
    // `useBorderRadius && (borderRadius || style.borderRadius)`
    'borderRadius': jsTruthy(useBorderRadius)
        ? (jsTruthy(borderRadius) ? borderRadius : jsGet(style, 'borderRadius'))
        : useBorderRadius,

    // Below is extra data used for toggling the datasets
    'datasetIndex': meta.index,
  };
}

/// plugin.legend.js:592 the default export, `Legend` of
/// `src/plugins/index.js:4` (Chart.js ADR 0038, section 1).
///
/// A mutable Map with the upstream keys in the upstream order. The hooks
/// are closures with the upstream parameter count (Chart.js ADR 0038,
/// section 3).
final AnyObject legend = <String, Object?>{
  'id': 'legend',

  // For tests
  // @private
  '_element': Legend.jsClass,

  // plugin.legend.js:601 `start(chart, _args, options)`.
  'start': (types.Chart chart, AnyObject _, AnyObject options) {
    final legend = Legend((ctx: chart.ctx, options: options, chart: chart));
    chart.legend = legend;
    layouts
      ..configure(chart, legend, options)
      ..addBox(chart, legend);
  },

  // plugin.legend.js:607 `stop(chart)`. core.layouts.js:318-323 compares
  // identities only. A value that is not a LayoutItem is never in
  // chart.boxes. `delete chart.legend` is the write of Dart `null`.
  'stop': (types.Chart chart) {
    final legend = chart.legend;
    layouts.removeBox(chart, switch (legend) {
      final LayoutItem item => item,
      _ => null,
    });
    chart.legend = null;
  },

  // plugin.legend.js:615 `beforeUpdate(chart, _args, options)`. During the
  // beforeUpdate step, the layout configuration needs to run. This ensures
  // that if the legend position changes (via an option update) the layout
  // system respects the change. See
  // https://github.com/chartjs/Chart.js/issues/7527
  //
  // A legend that is not a Legend throws the TypeError of the cast. Upstream
  // throws a TypeError in the same update, at `buildLabels` of afterUpdate
  // (Chart.js ADR 0038, section 6).
  'beforeUpdate': (types.Chart chart, AnyObject _, AnyObject options) {
    final legend = chart.legend! as Legend;
    layouts.configure(chart, legend, options);
    legend.options = options;
  },

  // plugin.legend.js:623 `afterUpdate(chart)`. The labels need to be built
  // after datasets are updated to ensure that colors and other styling are
  // correct. See https://github.com/chartjs/Chart.js/issues/6968
  'afterUpdate': (types.Chart chart) {
    (chart.legend! as Legend)
      ..buildLabels()
      ..adjustHitBoxes();
  },

  // plugin.legend.js:630 `afterEvent(chart, args)`.
  'afterEvent': (types.Chart chart, AnyObject args) {
    if (!jsTruthy(jsGet(args, 'replay'))) {
      (chart.legend! as Legend).handleEvent(
        jsGet(args, 'event')! as types.ChartEvent,
      );
    }
  },

  // plugin.legend.js:636-712.
  'defaults': <String, Object?>{
    'display': true,
    'position': 'top',
    'align': 'center',
    'fullSize': true,
    'reverse': false,
    'weight': 1000.0,

    // a callback that will handle
    'onClick': _onClick,

    'onHover': null,
    'onLeave': null,

    'labels': <String, Object?>{
      'color': _chartColor,
      'boxWidth': 40.0,
      'padding': 10.0,
      // Generates labels shown in the legend
      'generateLabels': _generateLabels,
    },

    'title': <String, Object?>{
      'color': _chartColor,
      'display': false,
      'position': 'center',
      'text': '',
    },
  },

  // plugin.legend.js:714-719.
  'descriptors': <String, Object?>{
    '_scriptable': (String name) => !name.startsWith('on'),
    'labels': <String, Object?>{
      '_scriptable': (String name) =>
          !const ['generateLabels', 'filter', 'sort'].contains(name),
    },
  },
};
