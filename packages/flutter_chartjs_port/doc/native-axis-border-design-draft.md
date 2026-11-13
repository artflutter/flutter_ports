# Scale border — migration draft

The scale option `border`: the axis line of a cartesian axis, and the dash of the grid circles of a
radial axis. Today the typed API has no parameter for it, so an app writes it as a Map in `extra`
(14 uses in the docs app). The core reads it back key by key, with `jsTruthy` and `jsToNumber`.

## The classes

```dart
// lib/src/types/axis_border.dart: core classes, the values of the option.

// The type of the option border. It has no fields.
@immutable
abstract class const ScaleBorder() {
  // The scopes of a chart combine through this method, as fonts do.
  ScaleBorder merge(ScaleBorder? other);
}

// The axis line of a cartesian axis: category, linear, logarithmic, time, time series.
final class const AxisBorder({
  final bool? display,
  final ChartPaint? color,
  final double? width,
  final List<double>? dash,
  final double? dashOffset,
  final double? z,
}) extends ScaleBorder {
  // Another AxisBorder merges field by field: a field of other wins.
  // A border of another class replaces this one.
  @override
  ScaleBorder merge(ScaleBorder? other) => switch (other) {
    null => this,
    AxisBorder() => AxisBorder(
      display: other.display ?? display,
      color: other.color ?? color,
      width: other.width ?? width,
      dash: other.dash ?? dash,
      dashOffset: other.dashOffset ?? dashOffset,
      z: other.z ?? z,
    ),
    _ => other,
  };
}

// The dash of the grid circles of a radial axis. It has no axis line.
final class const RadialAxisBorder({
  final List<double>? dash,
  final double? dashOffset,
}) extends ScaleBorder {
  @override
  ScaleBorder merge(ScaleBorder? other) => switch (other) {
    null => this,
    RadialAxisBorder() => RadialAxisBorder(
      dash: other.dash ?? dash,
      dashOffset: other.dashOffset ?? dashOffset,
    ),
    _ => other,
  };
}
```

## Before and after

```dart
// Before
LinearAxis(extra: {'border': {'display': false}})
LinearAxis(extra: {'border': {'color': red, 'width': 2, 'dash': [4, 4]}})
RadialLinearAxis(extra: {'border': {'dash': [2, 2]}})

// After
LinearAxis(border: const AxisBorder(display: false))
LinearAxis(border: const AxisBorder(color: red, width: 2, dash: [4, 4]))
RadialLinearAxis(border: const RadialAxisBorder(dash: [2, 2]))

// A raw config holds the same objects.
'border': const AxisBorder(display: false),
```

The five cartesian axis classes of the typed API take an `AxisBorder`, and `RadialLinearAxis` takes
a `RadialAxisBorder`. Thus a radial axis cannot get a color, a width or a `display` that it ignores.

## How the object reaches the scale

```dart
// The defaults of all scales (core.scale.defaults.dart), one object.
..border = const AxisBorder(display: true, width: 1, dash: [], dashOffset: 0, z: 0)

// The defaults of the radial axis (scale.radialLinear.dart): its own class, with the values that
// it gets today. Thus the shared AxisBorder never reaches a radial axis.
..border = const RadialAxisBorder(dash: [], dashOffset: 0)

// The theme writes its color the same way.
t.border = AxisBorder(color: ChartPaint.solid(borderColor));

// The resolver merges the objects of the scopes, as it merges fonts (_mergeTextStyles).
// A cartesian scale reads one AxisBorder, and the radial scale one RadialAxisBorder.
final border = options.border as AxisBorder;
final color = border.color ?? chart.options.borderColor; // the route to borderColor
final width = border.display! ? border.width! : 0.0;
if (width == 0 || width.isNaN) return; // upstream `if (!axisWidth)`
```

- `ScaleBorder` is a typed atom of the schema: the shape of `border` is `scaleBorder`. The scope kind
  `BorderOptions`, its facade and the route `scale.border.color` go.
- The object that the app writes reaches the scale. The scale merges it with the theme and the
  defaults, field by field.
- Readers that change: `_computeGridLineItems`, `drawBorder` and `_layers` of `core.scale.dart`, and
  `drawGrid` and `_drawRadiusLine` of `scale.radialLinear.dart`. Their `jsTruthy`, `jsToNumber`,
  `canvasNumber`, `canvasStyle` and `canvasLineDash` go.
- The function form stays, for the whole object: `border` takes a `ScaleBorder` or a
  `ScaleBorder Function(ScriptableScaleContext context)`. The fixture
  `core.scale/grid/scriptable-borderDash` gives `dash` as a function of the tick context today: the
  dash of each grid line changes with the tick index. The scale calls the function for each tick
  context, as today, and the hand port returns
  `AxisBorder(dash: context.index.isEven ? [6, 3] : [])`.
- A Map `border` in a raw config stops a debug build. Cost: 26 test files with a Map `border`, the
  14 docs app uses, the theme compile, the typed names list. The scale reference data change only
  in the form of the border value.
