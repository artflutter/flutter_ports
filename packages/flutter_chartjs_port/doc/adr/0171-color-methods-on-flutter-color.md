# Chart.js ADR 0171: Color methods on the Flutter Color

- Status: accepted (2026-11-18): its code and the tests of section Tests pass.
- Date: 2026-11-18
- Supersedes: of [Chart.js ADR 0019](0019-animation.md), section 5, the item "Color cache", and of section 12,
  the item "Group `adapt-animation-color-cache`".
- Related: [Chart.js ADR 0057](0057-direct-typed-colors.md), [Chart.js ADR 0061](0061-native-flutter-colors.md)

## Context

The color port `flutter_kurkle_color_port` kept the class `Color` of `@kurkle/color`. Since Chart.js ADR 0057, the
class took only a Flutter `Color`, an `RGBA`, a `Map` or a `List`, and the Chart.js port gave it only Flutter colors.
Thus each use made a second color object from a Flutter color, ran one method and made a Flutter color again:

```dart
// helpers.color.dart, getHoverColor
final hovered = (color(value) as Color).saturate(0.5).darken(0.1);
final rgb = hovered.rgbaBytes!;
return ChartPaint.solid(ui.Color.fromRGBO(rgb.r.round(), rgb.g.round(), rgb.b.round(), rgb.a / 255));
```

The two classes had one name. The app library exported the color port with `hide Color, color`. The color animation
kept a cache object (`_ColorInterpolator`) that saved the parse of each color, and a Flutter color has no parse.

## Decision

1. **One color class.** The color port has no class `Color`. The methods of the upstream class are the extension
   `KurkleColor` on the Flutter `Color`. Each method returns a new color.

   ```dart
   final hover = (color(value) as ui.Color).saturate(0.5).darken(0.1);
   final step = to.mix(from, factor);
   ```

2. **The same bytes.** A method reads the RGBA bytes of the Flutter color as the old constructor stored them: `r`,
   `g` and `b` rounded to bytes, and the alpha as an unrounded byte. A non-finite channel and a `NaN` alpha stay as
   they are. The method runs the upstream arithmetic on the bytes. A method that does not change the alpha keeps the
   alpha of its input.

3. **The names.** `alpha(a)` is `withAlphaRatio(a)`, because `alpha` is a getter of the Flutter `Color`. `clone` and
   `valid` have no port: a Flutter color does not change, and it is always a color. `mix` and `interpolate` take a
   nullable color, as upstream takes `undefined`. `KurkleColor.of(input)` is the constructor for an object input,
   and `KurkleColor.fromRgbaBytes` makes a color of the bytes of a parse function. `color(input)` gives a `Color?`:
   Dart `null` is the color that is not valid.

4. **The Chart.js port.** `helpers.color` returns the Flutter color. The color animation calls `mix` directly and
   has no cache. The app library exports the color port with `hide color`.

5. **The rows.** The color port has the row `adapt-kurkle-color-extension`. The Chart.js row
   `adapt-animation-color-cache` goes away.

## Rejected

- Keep the class and add the extension: the name conflict and the second object stay.
- Keep the color cache: it saved a parse, and a Flutter color has none.

## Consequences

- The public API of the color port changes. Its version is 0.2.0, and the Chart.js port depends on `^0.2.0`.
- A wide channel of an object input, for example `[2147483647.9, 0, 0]`, becomes a byte. The `mix` cases with wide
  channels of the color port tests go away.
- The hover color of a chart keeps the alpha of its input exactly, in place of the round trip of the alpha byte.

## Tests

- `packages/flutter_kurkle_color_port/test/index_test.dart`, `test/port/color_test.dart`,
  `test/port/fast_paths_test.dart` and `test/port/index.esm_test.dart`
- `test/specs/helpers.color_test.dart`, `test/port/helpers/helpers.color_test.dart`,
  `test/port/core/core.animation_test.dart` (group `interpolators.color`) and
  `test/port/widgets/chart_theme_switch_test.dart`
- The full test list of AGENTS.md before a push.
