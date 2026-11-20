// Original code, not ported from Chart.js: upstream context keys in the tests.

/// The upstream form of a typed context (differences.md row
/// `adapt-typed-contexts`): its own keys in the order of the upstream object
/// literal, and the value of a key as upstream reads it, also through the
/// prototype chain. [contextField] gives the typed member of an upstream
/// name, and [contextRead] the JS result of a reference function.
///
/// ```dart
/// final keys = contextKeys(element.$context!);
/// final mode = upstreamContextValue(element.$context!, 'mode');
/// ```
library;

import 'package:flutter_chartjs_port/chartjs.dart';

/// The own keys of [context] in the order of the upstream object literal of
/// its type.
List<String> contextKeys(ContextObject context) => switch (context) {
  ScriptableChartContext() => const ['chart', 'type'],
  ScriptableContext(type: 'data') => const [
    'active',
    'dataIndex',
    'parsed',
    'raw',
    'element',
    'index',
    'mode',
    'type',
  ],
  ScriptableContext() => const [
    'active',
    'dataset',
    'datasetIndex',
    'index',
    'mode',
    'type',
  ],
  ScriptableScaleContext(type: 'tick') => const ['tick', 'index', 'type'],
  ScriptableScaleContext() => const ['scale', 'type'],
  ScriptableScalePointLabelContext() => const ['label', 'index', 'type'],
  ScriptableTooltipContext() => const ['tooltip', 'tooltipItems', 'type'],
  ScriptableLineSegmentContext() => const [
    'type',
    'p0',
    'p1',
    'p0DataIndex',
    'p1DataIndex',
    'datasetIndex',
  ],
};

/// `context[key]` as upstream reads it: the own value, else the value of the
/// parent, else [undefined]. A Dart null of `mode`, `parsed`, `raw` or
/// `dataset` is the upstream `undefined`.
Object? upstreamContextValue(ContextObject? context, String key) {
  if (context == null) return undefined;
  if (contextKeys(context).contains(key)) {
    final value = _own(context, key);
    return value ?? (key == 'element' ? null : undefined);
  }
  return upstreamContextValue(context.parent, key);
}

Object? _own(ContextObject context, String key) => switch ((context, key)) {
  (_, 'type') => context.type,
  (_, 'chart') => context.chart,
  (final ScriptableContext c, 'active') => c.active,
  (final ScriptableContext c, 'dataset') => c.dataset,
  (final ScriptableContext c, 'datasetIndex') => c.datasetIndex,
  (final ScriptableContext c, 'dataIndex') => c.dataIndex,
  (final ScriptableContext c, 'parsed') => c.parsed,
  (final ScriptableContext c, 'raw') => c.raw,
  (final ScriptableContext c, 'element') => c.element,
  (final ScriptableContext c, 'index') => c.index,
  (final ScriptableContext c, 'mode') => c.mode,
  (final ScriptableScaleContext c, 'scale') => c.scale,
  (final ScriptableScaleContext c, 'tick') => c.tick,
  (final ScriptableScaleContext c, 'index') => c.index,
  (final ScriptableScalePointLabelContext c, 'label') => c.label,
  (final ScriptableScalePointLabelContext c, 'index') => c.index,
  (final ScriptableTooltipContext c, 'tooltip') => c.tooltip,
  (final ScriptableTooltipContext c, 'tooltipItems') => c.tooltipItems,
  (final ScriptableLineSegmentContext c, 'p0') => c.p0,
  (final ScriptableLineSegmentContext c, 'p1') => c.p1,
  (final ScriptableLineSegmentContext c, 'p0DataIndex') => c.p0DataIndex,
  (final ScriptableLineSegmentContext c, 'p1DataIndex') => c.p1DataIndex,
  (final ScriptableLineSegmentContext c, 'datasetIndex') => c.datasetIndex,
  _ => null,
};

/// The typed member [key] of [context]: Dart `null` for a member that the
/// type does not have, and for a null [context].
Object? contextField(ContextObject? context, String key) => switch (key) {
  'type' => context?.type,
  'chart' => context?.chart,
  _ => switch (context) {
    ScriptableContext() => switch (key) {
      'active' => context.active,
      'dataset' => context.dataset,
      'datasetIndex' => context.datasetIndex,
      'dataIndex' => context.dataIndex,
      'parsed' => context.parsed,
      'raw' => context.raw,
      'element' => context.element,
      'index' => context.index,
      'mode' => context.mode,
      _ => null,
    },
    ScriptableScaleContext() => switch (key) {
      'scale' => context.scale,
      'tick' => context.tick,
      'index' => context.index,
      _ => null,
    },
    ScriptableScalePointLabelContext() => switch (key) {
      'label' => context.label,
      'index' => context.index,
      'scale' => context.scale,
      _ => null,
    },
    ScriptableTooltipContext() => switch (key) {
      'tooltip' => context.tooltip,
      'tooltipItems' => context.tooltipItems,
      _ => null,
    },
    _ => null,
  },
};

/// `context[key]` with the JS result of a function of a reference generator:
/// the typed member of a context, with [undefined] for an absent member, or
/// the read by name of a Map context of a spec.
Object? contextRead(Object? context, String key) => switch (context) {
  final ContextObject context => contextField(context, key) ?? undefined,
  _ => jsGet(context, key),
};

/// [contextKeys] of [context], or Dart `null` for a null [context].
List<String>? contextKeysOrNull(ContextObject? context) =>
    context == null ? null : contextKeys(context);
