# Chart.js ADR 0130: Native callback options

- Status: accepted (2026-11-13): its code passes the tests, the specs, the fixtures, the oracle O1 and the port checks.
- Date: 2026-11-13
- Related: Chart.js ADR 0125 (native tooltip callbacks), Chart.js ADR 0129 (an index is an int), Zoom ADR 0004
  (native zoom and pan callbacks), Chart.js ADR 0052 §6 (the callbacks of the typed API), Chart.js ADR 0054 §5
  (the raw boundary).
- Difference: `adapt-native-callbacks`.
- Supersedes: of Chart.js ADR 0052 §6, the details objects (its first paragraph and the bullets of the chart
  `onClick` and `onHover`, the legend handlers and the animation callbacks); of Chart.js ADR 0095, the call of a
  point-label closure of the shape `Object? Function(Object?, double)` with no argument list; the difference row
  `adapt-legend-items-list`.

## Context

Chart.js has 29 callback options outside the tooltip and the plugins. The port read each one as `Object?`. It called
the value through `callback` of `helpers.core.dart`, and that helper called `jsCall`. Thus a callback had JS arity:
a function with fewer parameters got fewer arguments, and a `JsFunction` got the upstream `this`. The animation
option `fn`, the time option `parser` and the legend options `filter` and `sort` called `jsCall` directly.

These are the options:

| Option | Upstream call |
| --- | --- |
| `onClick`, `onHover` of the chart | `core.controller.js:1222-1226` |
| `onResize` of the chart | `core.controller.js:294` |
| `animation.onProgress`, `animation.onComplete` | `core.controller.js:33-46` |
| `animation.fn` | `core.animation.js:35`, `:102` |
| The 14 scale hooks, `beforeUpdate` to `afterFit` | `core.scale.js:534` and the hook calls |
| `plugins.legend.onClick`, `onHover`, `onLeave` | `plugin.legend.js:539-550` |
| `plugins.legend.labels.generateLabels`, `filter`, `sort` | `plugin.legend.js:104-121` |
| `time.parser` of a time scale (the function form) | `scale.time.js:46-63` |
| `pointLabels.callback` of a radial scale | `scale.radialLinear.js:454-464` |

The typed API had its own types for three groups: `ChartEventDetails`, `ChartLegendEventDetails` and
`ChartAnimationDetails`. A trampoline changed the raw arguments into these objects.

## Decision

1. Each option holds a Dart function of one type, in raw and typed configs. The port calls the function directly,
   with no `this` and no JS arity. The value that upstream gives as `this` is an argument where upstream also gives
   it as an argument. Else the port does not give it.

   ```dart
   typedef ChartEventHandler = void Function(
     ChartEvent event,
     List<ActiveElement> elements,
     Chart chart,
   );
   typedef ChartResizeHandler = void Function(Chart chart, Size size);
   typedef AnimationEventHandler = void Function(AnimationEvent event);
   typedef Interpolator = Object? Function(Object? from, Object? to, double factor);
   typedef ScaleHook = void Function(Scale scale);
   typedef LegendEventHandler = void Function(
     ChartEvent event,
     LegendItem item,
     LegendElement legend,
   );
   typedef LegendLabelsGenerator = List<LegendItem> Function(Chart chart);
   typedef LegendItemFilter = bool Function(LegendItem item, Object data);
   typedef LegendItemComparator = int Function(LegendItem a, LegendItem b, Object data);
   typedef TimeParser = Object? Function(Object? value);
   typedef PointLabelCallback = Object? Function(Object? label, int index);
   ```

   `Chart` and `Scale` are the public classes. `Size` is the Flutter `Size`: upstream gives `{width, height}`.
   `AnimationEvent` is the interface of `animation.d.ts:13`. `data` is `chart.data`.
2. A function of another type stops a debug build, also a function with another parameter count or with a narrower
   parameter type. A release build makes no call: that is the result of upstream `callback` for a value that is not
   a function. An absent value, `null` and `false` are no callback. The shared read is `functionOption` of
   `helpers.config.dart`. The animation option `fn` has its own check, because the animation module does not import
   the resolver: a truthy `fn` that is not an `Interpolator` stops a debug build. Upstream throws at the first
   interpolation.
3. The text form of `time.parser` stays: it is a format of the date adapter, not a callback.
4. `generateLabels` gives a `List<LegendItem>`. The List cast of the result and the late throw of a value that is
   not an array go. The difference row `adapt-legend-items-list` goes.
5. The built-in functions take the new types. The `fn` of the `visible` animation (`v => v | 0`) takes the three
   parameters and reads `from`. The default point-label callback takes the label and the index. The built-in legend
   functions keep their signatures, which are subtypes of the new types.
6. The typed API takes the same types: `ChartConfig.onClick` and `onHover`, `ChartLegend.onClick`, `onHover` and
   `onLeave`, and `ChartAnimation.onProgress` and `onComplete`. `ChartEventDetails`, `ChartLegendEventDetails` and
   `ChartAnimationDetails` go. Chart.js ADR 0052 §6 chose one details object, so that a new upstream argument does
   not break a callback. This ADR takes one function type for the raw and the typed config: a details object was a
   second form of the same arguments, and the raw config could not use it. A new upstream argument is a new ADR. The trampolines stay: a trampoline calls the callback of the newest config, so that a
   new closure in an equal config gives no update (Chart.js ADR 0052 §6).
7. The public library exports the eleven function types and `AnimationEvent`.

```dart
final config = <String, Object?>{
  'type': 'bar',
  'data': data,
  'options': <String, Object?>{
    'onClick': (ChartEvent event, List<ActiveElement> elements, Chart chart) {
      if (elements.isNotEmpty) print(elements.first.index);
    },
    'scales': <String, Object?>{
      'y': <String, Object?>{'afterFit': (Scale scale) => scale.width = 60},
    },
    'plugins': <String, Object?>{
      'legend': <String, Object?>{
        'labels': <String, Object?>{
          'filter': (LegendItem item, Object data) => item.hidden != true,
        },
      },
    },
  },
};
```

## Consequences

- No ported code calls `jsCall` for these options. `callback` of `helpers.core.dart` stays for the plugin hooks of
  the registry and the plugin service (Chart.js ADR 0126).
- An app that wrote a closure with fewer parameters must write all parameters. A closure with `Object?` parameters
  stays valid.
- The result of `PointLabelCallback`, `TimeParser` and `Interpolator` stays `Object?`: the point labels, the time
  values and the animated values keep their upstream forms.
- The oracle O1 gives the same digests.

## Tests

- `test/port/typed/callbacks_test.dart`: the typed and the raw event callbacks, the trampolines and the animation
  event.
- `test/port/plugins/plugin.legend_test.dart`, group `adapt-native-callbacks`: a generator of another type stops a
  debug build.
- `test/port/scales/scale.radialLinear_plans_test.dart`, group `generateTickLabels`: the `int` index and the
  functions of another type.
- `test/port/core/core.animation_test.dart`: an `Interpolator` gets `from`, `to` and the factor, and another value
  stops a debug build.
- The specs, the reference tests, the fixtures and the oracle O1.
