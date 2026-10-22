// Ported from Chart.js v4.5.1+7169e651 src/plugins/plugin.title.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.title.js`.
///
/// [Title] is the layout box of the chart title. [title] is the plugin
/// object, the default export of the upstream file and `Title` of
/// `src/plugins/index.js:6` (Chart.js ADR 0038, section 1). It is a mutable
/// Map with the upstream keys in the upstream order: `id`, `_element`,
/// `start`, `stop`, `beforeUpdate`, `defaults`, `defaultRoutes` and
/// `descriptors`.
///
/// Each hook is a closure with the upstream parameter count and the typed
/// parameters `(types.Chart chart, AnyObject args, AnyObject options)`
/// (Chart.js ADR 0038, section 3). `chart.titleBlock` is a field of
/// `types.Chart`: Dart `null` stands for JS `undefined` and for the
/// `delete` of `plugin.title.js:136`.
///
/// The fields of the box start as the fields of `Scale` start: NaN for the
/// edges, the `undefined` sentinel for `position` and `weight`, and `false`
/// for `fullSize` (Chart.js ADR 0038, section 7).
///
/// Not a pure layer: it imports `helpers.extras`.
library;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.layouts.dart' show layouts;
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show renderText;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isArray;
import 'package:flutter_chartjs_port/src/helpers/helpers.extras.dart'
    show alignStartEnd, toLeftRightCenter;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart' show pi;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show toFont, toPadding;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/layout.dart';

/// plugin.title.js:7 `class Title extends Element`.
///
/// The layout box of the chart title. `layouts.addBox` gives it the default
/// layer, which calls [draw] (core.layouts.js:301-308).
class Title extends Element implements LayoutItem {
  /// plugin.title.js:11 `constructor(config)`.
  ///
  /// @param {{ ctx: any; options: any; chart: any; }} config
  ///
  /// The upstream `config` object is a record (Chart.js ADR 0038, section
  /// 4). The `construct` closure of [jsClass] reads it from a JS value.
  Title(
    ({Object? chart, AnyObject? options, CanvasRenderingContext2D? ctx}) config,
  ) : chart = config.chart,
      ctx = config.ctx {
    options = config.options;
  }

  /// plugin.title.js:7 `class Title` as a value (Chart.js ADR 0020, section
  /// 3).
  ///
  /// Its superclass is [Element.jsClass]. It has no static property. Its
  /// `construct` reads the `config` argument with [_titleConfig].
  static final JsClass jsClass = JsClass(
    'Title',
    superclass: Element.jsClass,
    construct: (newTarget, args) => Title(_titleConfig(args)),
  );

  /// plugin.title.js:14 `chart`. Upstream stores it and never reads it.
  /// Thus it keeps any value.
  final Object? chart;

  /// plugin.title.js:16 `ctx`. Dart `null` stands for JS `undefined`.
  CanvasRenderingContext2D? ctx;

  /// plugin.title.js:17 `_padding`, the result of `toPadding` of the last
  /// [update] that displays the title. Dart `null` stands for JS
  /// `undefined`, the start value. [draw] reads it.
  ///
  /// A `late` field would throw a `LateInitializationError` at the read
  /// before the first write. Upstream throws a `TypeError` there, as the
  /// null check of Dart `null` does.
  // ignore: use_late_for_private_fields_and_variables
  ChartArea? _padding;

  /// plugin.title.js:18 `top`. NaN stands for JS `undefined`, the start
  /// value.
  @override
  double top = double.nan;

  /// plugin.title.js:19 `bottom`. NaN stands for JS `undefined`.
  @override
  double bottom = double.nan;

  /// plugin.title.js:20 `left`. NaN stands for JS `undefined`.
  @override
  double left = double.nan;

  /// plugin.title.js:21 `right`. NaN stands for JS `undefined`.
  @override
  double right = double.nan;

  /// plugin.title.js:22 `width`. NaN stands for JS `undefined`.
  @override
  double width = double.nan;

  /// plugin.title.js:23 `height`. NaN stands for JS `undefined`.
  @override
  double height = double.nan;

  /// plugin.title.js:24 `position`. The [undefined] sentinel stands for JS
  /// `undefined`, the start value. `layouts.configure` writes the
  /// `position` option (core.layouts.js:333).
  @override
  Object? position = undefined;

  /// plugin.title.js:25 `weight`. The [undefined] sentinel stands for JS
  /// `undefined`, the start value. `layouts.configure` writes the `weight`
  /// option (core.layouts.js:334).
  @override
  Object? weight = undefined;

  /// plugin.title.js:26 `fullSize`. False stands for JS `undefined`, the
  /// start value: the readers test only its truthiness (Chart.js ADR 0038,
  /// section 7).
  @override
  bool fullSize = false;

  /// core.layouts.js:301 `_layers`. Dart `null` stands for JS `undefined`,
  /// the start value: `layouts.addBox` writes the default layer.
  @override
  List<LayoutLayer> Function()? layers;

  /// core.layouts.js:15 `box.axis`. The title has no axis: Dart `null`
  /// stands for JS `undefined`.
  @override
  String? get axis => null;

  /// plugin.title.js:29 `update(maxWidth, maxHeight)`.
  ///
  /// Upstream has no third parameter. `core.layouts.js:187-191` passes the
  /// margins, and the title ignores them (Chart.js ADR 0038, section 7).
  @override
  void update(double maxWidth, double maxHeight, [TRBL? margins]) {
    final opts = options;

    left = 0;
    top = 0;

    if (!jsTruthy(jsGet(opts, 'display'))) {
      width = height = right = bottom = 0;
      return;
    }

    width = right = maxWidth;
    height = bottom = maxHeight;

    final text = jsGet(opts, 'text');
    final lineCount = isArray(text) ? (text! as List<Object?>).length : 1;
    final padding = _padding = toPadding(jsGet(opts, 'padding'));
    final textSize =
        lineCount * toFont(jsGet(opts, 'font')).lineHeight + padding.height;

    if (isHorizontal()) {
      height = textSize;
    } else {
      width = textSize;
    }
  }

  /// plugin.title.js:54 `isHorizontal()`.
  @override
  bool isHorizontal() {
    final pos = jsGet(options, 'position');
    return pos == 'top' || pos == 'bottom';
  }

  /// plugin.title.js:59 `_drawArgs(offset)`: the object `{titleX, titleY,
  /// maxWidth, rotation}`, a record.
  ///
  /// `_alignStartEnd` takes the `align` option through [_alignName].
  ({double titleX, double titleY, double maxWidth, double rotation}) _drawArgs(
    double offset,
  ) {
    final Title(:top, :left, :bottom, :right, :options) = this;
    final alignName = _alignName(jsGet(options, 'align'));
    var rotation = 0.0;
    double maxWidth;
    double titleX;
    double titleY;

    if (isHorizontal()) {
      titleX = alignStartEnd(alignName, left, right);
      titleY = top + offset;
      maxWidth = right - left;
    } else {
      if (jsGet(options, 'position') == 'left') {
        titleX = left + offset;
        titleY = alignStartEnd(alignName, bottom, top);
        rotation = pi * -0.5;
      } else {
        titleX = right - offset;
        titleY = alignStartEnd(alignName, top, bottom);
        rotation = pi * 0.5;
      }
      maxWidth = bottom - top;
    }
    return (
      titleX: titleX,
      titleY: titleY,
      maxWidth: maxWidth,
      rotation: rotation,
    );
  }

  /// plugin.title.js:84 `draw()`.
  ///
  /// Upstream takes no argument. The default layer of `layouts.addBox`
  /// passes the chart area (core.layouts.js:305), and the title ignores it
  /// (Chart.js ADR 0038, section 7).
  ///
  /// Before the first [update] that displays the title, `_padding` is Dart
  /// `null`, and the read of its `top` throws a [TypeError], as the read of
  /// `this._padding.top` throws upstream. A title without a context throws
  /// the [TypeError] of `ctx.save()` in `renderText` after the reads of the
  /// options, as upstream.
  @override
  void draw([ChartArea? chartArea]) {
    final ctx = this.ctx;
    final opts = options;

    if (!jsTruthy(jsGet(opts, 'display'))) {
      return;
    }

    final fontOpts = toFont(jsGet(opts, 'font'));
    final lineHeight = fontOpts.lineHeight;
    final offset = lineHeight / 2 + _padding!.top;
    final (:titleX, :titleY, :maxWidth, :rotation) = _drawArgs(offset);

    // The arguments of renderText, in the upstream order of their reads.
    final text = jsGet(opts, 'text');
    final textOpts = _TitleTextOpts(
      color: jsGet(opts, 'color'),
      maxWidth: maxWidth,
      rotation: rotation,
      textAlign: toLeftRightCenter(_alignName(jsGet(opts, 'align'))),
      textBaseline: 'middle',
      translation: (titleX, titleY),
    );
    renderText(ctx!, text, 0, 0, fontOpts, textOpts);
  }
}

/// The `align` option as the `String` of the helpers of helpers.extras.ts:
/// `_toLeftRightCenter` and `_alignStartEnd` compare it with `'start'` and
/// `'end'`. A value that is not a `String` equals neither, so it passes as
/// `''`.
String _alignName(Object? align) => align is String ? align : '';

/// The text options of the title (plugin.title.js:97-104), the object
/// literal of the `renderText` call. The members that the literal leaves
/// out are Dart `null`, JS `undefined`.
final class _TitleTextOpts implements types.RenderTextOpts {
  _TitleTextOpts({
    required this.color,
    required this.maxWidth,
    required this.rotation,
    required this.textAlign,
    required this.textBaseline,
    required this.translation,
  });

  @override
  final Object? color;

  @override
  final double? maxWidth;

  @override
  final double? rotation;

  @override
  final String? textAlign;

  @override
  final String? textBaseline;

  @override
  final (double, double)? translation;

  @override
  types.BackdropOptions? get backdrop => null;

  @override
  double? get decorationWidth => null;

  @override
  bool? get strikethrough => null;

  @override
  Object? get strokeColor => null;

  @override
  double? get strokeWidth => null;

  @override
  bool? get underline => null;
}

/// The `config` of `new Title(config)` from the arguments [args] of the
/// `construct` closure of [Title.jsClass]: the reads `config.chart`,
/// `config.options` and `config.ctx` of plugin.title.js:14-16.
///
/// An absent argument, [undefined] and JS `null` throw the [TypeError] of
/// the read `config.chart`, as upstream. A member with the value
/// [undefined] gives Dart `null`. The `chart` keeps any value, because
/// `Title` never reads it. An `options` that is not a Map and a `ctx` that
/// is not a context throw a [TypeError]. Upstream stores such a value.
// DIVERGES(chartjs): adapt-component-class-role, a non-Map options throws.
({Object? chart, AnyObject? options, CanvasRenderingContext2D? ctx})
_titleConfig(List<Object?> args) {
  final config = args.isEmpty ? undefined : args[0];
  return (
    chart: _orNull(jsGet(config, 'chart')),
    options: _orNull(jsGet(config, 'options')) as AnyObject?,
    ctx: _orNull(jsGet(config, 'ctx')) as CanvasRenderingContext2D?,
  );
}

/// Dart `null` for the [undefined] sentinel, else [value].
Object? _orNull(Object? value) => identical(value, undefined) ? null : value;

/// plugin.title.js:108 `createTitle(chart, titleOpts)`.
void _createTitle(types.Chart chart, AnyObject titleOpts) {
  final title = Title((ctx: chart.ctx, options: titleOpts, chart: chart));

  layouts
    ..configure(chart, title, titleOpts)
    ..addBox(chart, title);
  chart.titleBlock = title;
}

/// plugin.title.js:120 the default export, `Title` of
/// `src/plugins/index.js:6` (Chart.js ADR 0038, section 1).
///
/// A mutable Map with the upstream keys in the upstream order. The hooks
/// are closures with the upstream parameter count (Chart.js ADR 0038,
/// section 3).
final AnyObject title = <String, Object?>{
  'id': 'title',

  // For tests
  // @private
  '_element': Title.jsClass,

  // plugin.title.js:129 `start(chart, _args, options)`.
  'start': (types.Chart chart, AnyObject _, AnyObject options) {
    _createTitle(chart, options);
  },

  // plugin.title.js:133 `stop(chart)`. Dart `null` stands for the
  // `undefined` of a chart without a title block: `removeBox` then changes
  // nothing (core.layouts.js:318-323). `delete chart.titleBlock` is the
  // write of Dart `null`.
  'stop': (types.Chart chart) {
    final titleBlock = chart.titleBlock;
    layouts.removeBox(chart, titleBlock);
    chart.titleBlock = null;
  },

  // plugin.title.js:139 `beforeUpdate(chart, _args, options)`. Without a
  // title block, the null check throws the TypeError of the write into
  // `undefined` in `layouts.configure` (core.layouts.js:332).
  'beforeUpdate': (types.Chart chart, AnyObject _, AnyObject options) {
    final title = chart.titleBlock! as Title;
    layouts.configure(chart, title, options);
    title.options = options;
  },

  // plugin.title.js:145-156.
  'defaults': <String, Object?>{
    'align': 'center',
    'display': false,
    'font': <String, Object?>{'weight': 'bold'},
    'fullSize': true,
    'padding': 10.0,
    'position': 'top',
    'text': '',
    // by default greater than legend (1000) to be above
    'weight': 2000.0,
  },

  // plugin.title.js:158-160.
  'defaultRoutes': <String, Object?>{'color': 'color'},

  // plugin.title.js:162-165.
  'descriptors': <String, Object?>{'_scriptable': true, '_indexable': false},
};
