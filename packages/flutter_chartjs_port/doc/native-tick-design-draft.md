# Tick — migration draft

The difference row is [`adapt-native-tick`](differences.md#adapt-native-tick).

## The class

```dart
class Tick({
  // A number of a linear or a logarithmic scale, the index of the label of a
  // category scale, or the time value of a time scale in milliseconds.
  required var double value,

  // The lines of the label. Null is the start value, and the scale removes a
  // tick whose callback gives null. An empty List keeps the tick and draws
  // no line.
  var List<String>? label,

  // The time and the logarithmic scales write it.
  var bool major = false,

  // Only the logarithmic scale writes it.
  var double? significand,
}) {
  // The scale makes the context at the first read.
  ScriptableScaleContext? $context;
}
```

`Tick` is in `lib/src/types/tick.dart`. It replaces the interface `types.Tick` and the `final` class
of `core.scale.dart`. The class is open: an app or a plugin can extend it, and the scale keeps the
identity of each tick.

```dart
class UnitTick({required super.value, required final String unit})
    extends Tick;
```

## The callback

```dart
typedef TickCallback =
    List<String>? Function(
      Scale scale,
      double value,
      int index,
      List<Tick> ticks,
    );
```

The option `ticks.callback` holds a `TickCallback`, in a raw config and in the typed API. The scale
is the first argument. Chart.js gives it as `this`.

```dart
// Typed API.
LinearAxis(
  ticks: AxisTicks(
    callback: (scale, value, index, ticks) => ['${value.round()} kg'],
  ),
)

// Raw config.
'ticks': <String, Object?>{
  'callback': (Scale scale, double value, int index, List<Tick> ticks) => [
    '${value.round()} kg',
  ],
},

// The label of a category tick.
AxisTicks(
  callback: (scale, value, index, ticks) => [
    '${scale.getLabelForValue(value)}'.toUpperCase(),
  ],
)

// Two lines, and no label for each second tick.
AxisTicks(
  callback: (scale, value, index, ticks) =>
      index.isOdd ? null : ['$value', 'units'],
)
```

## The values of Chart.js and their native form

- A string label is a List of one line. The sizes, the line count and the draw calls do not change.
- An array label is the List of its lines.
- `null` and `undefined` are null: the scale removes the tick.
- A number, the result of `value => value`, is the line of its string form. The callback makes the
  string.
- `major` absent is `false`. Each reader of Chart.js tests it for truthiness.
- `callback: false`, the default of a time scale, stays `false`: it is no callback, and the adapter
  formats the tick.

## The formatters

`formatters` of `core.ticks.dart` keeps its three keys. Each value is a function of the callback type.

```dart
final numeric = ticks['formatters']!['numeric']!;
final label = numeric(scale, 1500, 1, scale.ticks!); // ['1,500']
```

`values` gives the line of the number. `logarithmic` gives the line `''` for a tick that it hides.

## Differences from Chart.js

- A function of another type in `ticks.callback` stops a debug build. A release build makes no call.
- On a time scale, the callback gets NaN for the tick of a label that does not parse. Chart.js gives
  `null`.
- A null line in a label array of the app is not a line. Chart.js draws the text `null`.
- No label measures as the empty text in the label capacity of a time scale. Chart.js measures the
  text `undefined` or `null`.

## Removed

- `types.Tick`, the interface with `value` and `significand`.
- `AxisTicks.format` and `AxisTickInfo` of the typed API. `AxisTicks.callback` replaces them.
- The `JsFunction` values of the formatters and of the default callback of the category scale.
