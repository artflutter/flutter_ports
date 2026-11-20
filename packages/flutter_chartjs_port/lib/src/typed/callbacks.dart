// Original code, not ported from Chart.js: the callbacks of the typed API.

/// The callback types of the typed API (Chart.js ADR 0052, section 6).
///
/// - The event callbacks take the function types of the core (Chart.js ADR
///   0130): `ChartEventHandler`, `LegendEventHandler` and
///   `AnimationEventHandler`, as a raw config does.
/// - [ChartScript] is the type of a scriptable option of a dataset. Its
///   context is the typed dataset or data context of the chart,
///   `ScriptableContext` (Chart.js ADR 0054 §11).
library;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// A scriptable option of a dataset: a function of the dataset or the data
/// context that gives the value.
///
/// Chart.js calls it in each resolution of the option, for each element. The
/// value has no fallback: Chart.js takes the value of the function as it is
/// (`helpers.config.ts:255-273`).
///
/// ```dart
/// ChartPaint background(ScriptableContext context) =>
///     (context.dataIndex ?? 1).isEven ? evenPaint : oddPaint;
/// ```
typedef ChartScript<T> = T Function(ScriptableContext context);
