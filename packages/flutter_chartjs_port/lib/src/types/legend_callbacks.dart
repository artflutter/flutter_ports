// Original code, not ported from Chart.js: the typed callbacks of the legend.

/// The function types of the legend options `onClick`, `onHover`,
/// `onLeave`, `labels.filter` and `labels.sort` (Chart.js ADR 0130).
///
/// An option holds a function of its type, also in a raw config. The
/// legend calls it directly, with no `this`. A function of another type
/// stops a debug build. The type of `labels.generateLabels`,
/// `LegendLabelsGenerator`, takes the chart: it is in `plugin.legend.dart`.
library;

import 'package:flutter_chartjs_port/src/types/index.dart' as core;
import 'package:flutter_chartjs_port/src/types/legend_item.dart';

/// The legend options `onClick`, `onHover` and `onLeave`
/// (index.d.ts:2459-2467, plugin.legend.js:539-550): the chart event, the
/// legend item under the event (for `onLeave`, the item that the pointer
/// left) and the legend. Chart.js also gives the legend as `this`.
typedef LegendEventHandler = void Function(
  core.ChartEvent event,
  LegendItem item,
  core.LegendElement legend,
);

/// The legend option `labels.filter` (index.d.ts:2507, plugin.legend.js:
/// 108-110): the legend keeps an item for a true result. [data] is
/// `chart.data`. Chart.js also gives the label options as `this`.
typedef LegendItemFilter = bool Function(LegendItem item, Object data);

/// The legend option `labels.sort` (index.d.ts:2512, plugin.legend.js:
/// 112-114): the order of two items, as a comparator of `List.sort`. The
/// sort is stable. [data] is `chart.data`.
typedef LegendItemComparator = int Function(
  LegendItem a,
  LegendItem b,
  Object data,
);
