## 0.2.1

- `LICENSE`: keep only the upstream copyright notice.

## 0.2.0

- The methods of the upstream `Color` class are the extension `KurkleColor` on the Flutter `Color` (Chart.js ADR 0171). Each method returns a new color. The class `Color` is gone.
- `alpha(a)` is `withAlphaRatio(a)`. `clone` and `valid` have no port. `color(input)` gives a `Color?`, with Dart `null` for an input that is no color.
- `mix` and `interpolate` take a nullable color, as upstream takes `undefined`.

## 0.1.2

- pubspec: a shorter description (157 characters), in the 60 to 180 characters of pub.dev.
- `example/main.dart`: parse CSS colors, change a Flutter `Color`, and mix two colors.

## 0.1.1

- README: remove the title and the sections of the JavaScript library (Docs, Benchmarks, Size visualization, License).

## 0.1.0

- First release: a native Dart port of @kurkle/color 0.3.2, with its upstream tests.
