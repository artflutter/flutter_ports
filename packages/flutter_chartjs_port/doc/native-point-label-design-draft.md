# Point labels — migration draft

The difference row will be `adapt-native-point-labels`.

```dart
class RadialLinearScale extends LinearScaleBase {
  // The text at the end of each spoke, one entry for each visible item of
  // data.labels. Each entry is the lines of that text.
  List<List<String>> pointLabels = [];
}

// The option pointLabels.callback, in core.scale.dart next to TickCallback.
// It gets the scale, the lines of the item of data.labels and the index of
// that item, and gives the lines to draw.
typedef PointLabelCallback =
    List<String> Function(
      Scale scale,
      List<String> label,
      int index,
    );

class ScriptableScalePointLabelContext extends ContextObject {
  // Holds the lines of the point label. The getter stays Object? until the
  // contexts are typed.
  Object? get label;

  // The index in pointLabels: the visible labels only.
  int get index;
}
```

`pointLabels` replaces the `List<Object?>` of `scale.radialLinear.dart`. The callback replaces
`Object? Function(Object? label, int index)` of Chart.js ADR 0130.

```dart
// data.labels: ['Speed', ['Top', 'speed'], 3]
scale.pointLabels; // [['Speed'], ['Top', 'speed'], ['3']]

// Raw config: ['Speed'] gives ['SPEED'].
'pointLabels': <String, Object?>{
  'callback': (Scale scale, List<String> label, int index) => [
    for (final line in label) line.toUpperCase(),
  ],
},

// Typed API: ['Speed'] gives ['Speed', '#1'].
RadialLinearAxis(
  pointLabelsCallback: (scale, label, index) => [...label, '#${index + 1}'],
)
```

## The values of Chart.js and their native form

- Before the callback, each item of `data.labels` becomes lines: a string is one line, an array is its
  lines, and a number is the line of its string form.
- `['']` is one empty line: no text, the height of one line. `[]` is no line, with the height 0. A
  callback that hides a label returns `['']`, as Chart.js draws `''`.
- The default callback gives `label` as it is. A callback reads `scale.getLabels()[index]` for the value of
  the app.

## Differences from Chart.js

- A function of another type stops a debug build.

## Removed

- `_pointLabelOf`, the check of the callback result.
- The `label is! String` exit of the static draw plan of Chart.js ADR 0095. The plan exits at a label of
  more than one line.
