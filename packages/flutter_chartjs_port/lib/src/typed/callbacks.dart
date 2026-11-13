// Original code, not ported from Chart.js: the callbacks of the typed API.

/// The callback types of the typed API (Chart.js ADR 0052, section 6).
///
/// - The event callbacks take the function types of the core (Chart.js ADR
///   0130): `ChartEventHandler`, `LegendEventHandler` and
///   `AnimationEventHandler`, as a raw config does.
/// - [ChartContext] is a view over the context objects of the chart. An
///   active element of an event is the core [ActiveElement].
///   A tooltip item is the core `TooltipItem`. [LegendItem] is the shared
///   native mutable object; legend event details preserve its identity.
/// - [ChartScript] is the type of a scriptable option.
///
/// A view has no public constructor: at run time, a view is the object of
/// the chart, so the typed API casts that object to the view
/// (`context as ChartContext`). A nullable getter of a view gives Dart
/// `null` for the JS `undefined`, for an absent key and for a value of
/// another type.
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart' show Chart;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ContextObject, ScriptableChartContext, ScriptableContext;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/types/index.dart' show ActiveElement;
import 'package:flutter_chartjs_port/src/types/legend_item.dart';

/// A scriptable option: a function of the context of the element, the
/// dataset or the chart that gives the value.
///
/// Chart.js calls it in each resolution of the option, for each element. The
/// value has no fallback: Chart.js takes the value of the function as it is
/// (`helpers.config.ts:255-273`).
typedef ChartScript<T> = T Function(ChartContext context);

/// The context of a scriptable option (`docs/general/options.md`, "Option
/// Context"): the chart context, a dataset context or a data context.
///
/// A view of the typed context object of the chart (Chart.js ADR 0054 §11):
/// the getters read the typed members of the dataset and the data context
/// (`ScriptableContext`) and of the chart context
/// (`ScriptableChartContext`). A context of another type has no dataset
/// member: its getters give `null` and `false`.
extension type ChartContext._(ContextObject _context) {
  /// The chart: the `chart` of the chart context, the first context of the
  /// prototype chain of each context (`createContext`).
  Chart get chart {
    for (
      Object? context = _context;
      context is ContextObject;
      context = context.prototype
    ) {
      if (context is ScriptableChartContext) return context.chart! as Chart;
    }
    // A context without a chart context: the `TypeError` of a missing chart.
    throw TypeError();
  }

  /// The type of the context: `'chart'`, `'dataset'`, `'data'`, `'scale'`,
  /// `'tick'`, `'pointLabel'` or `'tooltip'`.
  String? get type => _string(_context.type);

  /// The dataset or the data context, or Dart `null` for a context of
  /// another type.
  ScriptableContext? get _dataContext => switch (_context) {
    final ScriptableContext context => context,
    _ => null,
  };

  /// The index of the dataset, or `null` in a chart context.
  int? get datasetIndex => _int(_dataContext?.datasetIndex);

  /// The index of the data item, or `null` in a chart or a dataset context.
  int? get dataIndex => _int(_dataContext?.dataIndex);

  /// Whether the element is active (hovered). `false` in a chart context.
  bool get active => _dataContext?.active == true;

  /// The data item of the dataset at [dataIndex], as the app gave it: a
  /// `num`, a `DataPoint` or another value. `null` outside a data context.
  Object? get raw => _defined(_dataContext?.raw);

  /// The parsed values of the data item: an object with a key for each
  /// axis, for example `x` and `y`, or a number for a pie or a doughnut.
  /// `null` outside a data context.
  Object? get parsed => _defined(_dataContext?.parsed);
}

/// [value] as an `int`, or `null` for a value that is not a finite number.
int? _int(Object? value) =>
    value is num && value.isFinite ? value.toInt() : null;

/// [value] when it is a `String`, else `null`.
String? _string(Object? value) => value is String ? value : null;

/// [value], or `null` for the JS `undefined`.
Object? _defined(Object? value) => identical(value, undefined) ? null : value;
