# flutter_d3_color_port

A native Dart port of d3-color 3.1.0, the color module of D3, for Dart and Flutter. Each color is
a Dart class with `double` channels. The package runs no JavaScript and uses no WebView. It
converts to and from the Flutter `Color`.

Even though Flutter understands a lot about colors, it doesn’t offer much help in manipulating
colors in other color spaces. The d3-color module therefore provides representations for various
color spaces, allowing specification, conversion and manipulation.

For example, take the color named “steelblue”:

```dart
final c = d3.color('steelblue'); // Rgb: r 70, g 130, b 180, opacity 1
```

Let’s try converting it to HSL:

```dart
final c = d3.Hsl.parse('steelblue'); // h 207.27…, s 0.44, l 0.4902…, opacity 1
```

Now rotate the hue by 90°, bump up the saturation, and format as a string for CSS:

```dart
c.h += 90;
c.s += 0.2;
c.toString(); // rgb(198, 45, 205)
```

To fade the color slightly:

```dart
c.opacity = 0.8;
c.toString(); // rgba(198, 45, 205, 0.8)
```

In addition to the ubiquitous and machine-friendly RGB and HSL color space, d3-color supports
color spaces that are designed for humans:

* CIELAB (*a.k.a.* “Lab”)
* CIELCh<sub>ab</sub> (*a.k.a.* “LCh” or “HCL”)
* Dave Green’s Cubehelix

Cubehelix features monotonic lightness, while CIELAB and its polar form CIELCh<sub>ab</sub> are
perceptually uniform.

## Installing

```sh
flutter pub add flutter_d3_color_port
```

```dart
import 'package:flutter_d3_color_port/flutter_d3_color_port.dart' as d3;
```

`package:flutter_d3_color_port/d3_color.dart` has the same API with no Flutter import, for code
that runs without the Flutter engine.

## API Reference

### d3.color(specifier)

Parses the specified CSS Color Module Level 3 *specifier* string, returning an RGB or HSL color,
along with CSS Color Module Level 4 hex *specifier* strings. If the specifier was not valid, null
is returned. Some examples:

* `rgb(255, 255, 255)`
* `rgb(10%, 20%, 30%)`
* `rgba(255, 255, 255, 0.4)`
* `rgba(10%, 20%, 30%, 0.4)`
* `hsl(120, 50%, 20%)`
* `hsla(120, 50%, 20%, 0.4)`
* `#ffeeaa`
* `#fea`
* `#ffeeaa22`
* `#fea2`
* `steelblue`

The list of supported named colors is specified by CSS.

`d3.Color` is the base class of each color: `x is d3.Color` tests if an object is a color
instance. The same is true of the color subclasses, for example `x is d3.Hsl`, allowing you to
test whether a color is in a particular color space.

### *color*.opacity

This color’s opacity, typically in the range [0, 1].

### *color*.rgb()

Returns the RGB equivalent of this color. For RGB colors, that’s `this`.

### *color*.copy({…})

Returns a copy of this color. Each channel that is given as a named argument replaces that channel
in the new returned color. For example, to derive a copy of a *color* with opacity 0.5, say

```dart
color.copy(opacity: 0.5)
```

### *color*.brighter([*k*])

Returns a brighter copy of this color. If *k* is specified, it controls how much brighter the
returned color should be. If *k* is not specified, it defaults to 1. The behavior of this method
is dependent on the implementing color space.

### *color*.darker([*k*])

Returns a darker copy of this color. If *k* is specified, it controls how much darker the returned
color should be. If *k* is not specified, it defaults to 1. The behavior of this method is
dependent on the implementing color space.

### *color*.displayable()

Returns true if and only if the color is displayable on standard hardware. For example, this
returns false for an RGB color if any channel value is less than zero or greater than 255 when
rounded, or if the opacity is not in the range [0, 1].

### *color*.formatHex()

Returns a hexadecimal string representing this color in RGB space, such as `#f7eaba`. If this
color is not displayable, a suitable displayable color is returned instead. For example, RGB
channel values greater than 255 are clamped to 255.

### *color*.formatHex8()

Returns a hexadecimal string representing this color in RGB space with its opacity, such as
`#f7eaba90`.

### *color*.formatHsl()

Returns a string representing this color according to the CSS Color Module Level 3
specification, such as `hsl(257, 50%, 80%)` or `hsla(257, 50%, 80%, 0.2)`. If this color is not
displayable, a suitable displayable color is returned instead by clamping S and L channel values
to the interval [0, 100].

### *color*.formatRgb()

Returns a string representing this color according to the CSS Object Model specification, such
as `rgb(247, 234, 186)` or `rgba(247, 234, 186, 0.2)`. If this color is not displayable, a
suitable displayable color is returned instead by clamping RGB channel values to the interval
[0, 255].

### *color*.toString()

An alias for *color*.formatRgb.

### d3.Rgb(*r*, *g*, *b*[, *opacity*]), d3.Rgb.parse(*specifier*), d3.Rgb.from(*color*)

Constructs a new RGB color. The channel values are exposed as `r`, `g` and `b` properties on the
returned instance.

`d3.Rgb(r, g, b)` takes the channel values of the returned color; an *opacity* may also be
specified. `d3.Rgb.parse(specifier)` parses a CSS Color Module Level 3 *specifier* string and then
converts it to the RGB color space. See d3.color for examples. `d3.Rgb.from(color)` converts a
*color* instance to the RGB color space using *color*.rgb. Note that unlike *color*.rgb this
method *always* returns a new instance, even if *color* is already an RGB color.

### *rgb*.clamp()

Returns a new RGB color where the `r`, `g`, and `b` channels are clamped to the range [0, 255]
and rounded to the nearest integer value, and the `opacity` is clamped to the range [0, 1].

### d3.Hsl(*h*, *s*, *l*[, *opacity*]), d3.Hsl.parse(*specifier*), d3.Hsl.from(*color*)

Constructs a new HSL color. The channel values are exposed as `h`, `s` and `l` properties on the
returned instance.

`d3.Hsl(h, s, l)` takes the channel values of the returned color; an *opacity* may also be
specified. `d3.Hsl.parse(specifier)` parses a CSS Color Module Level 3 *specifier* string and then
converts it to the HSL color space. See d3.color for examples. `d3.Hsl.from(color)` converts a
*color* instance to the RGB color space using *color*.rgb and then to HSL. (Colors already in the
HSL color space skip the conversion to RGB.)

### *hsl*.clamp()

Returns a new HSL color where the `h` channel is clamped to the range [0, 360), and the `s`, `l`,
and `opacity` channels are clamped to the range [0, 1].

### d3.Lab(*l*, *a*, *b*[, *opacity*]), d3.Lab.parse(*specifier*), d3.Lab.from(*color*)

Constructs a new CIELAB color. The channel values are exposed as `l`, `a` and `b` properties on
the returned instance. The value of *l* is typically in the range [0, 100], while *a* and *b* are
typically in [-160, +160].

`d3.Lab(l, a, b)` takes the channel values of the returned color; an *opacity* may also be
specified. `d3.Lab.parse(specifier)` parses a CSS Color Module Level 3 *specifier* string and then
converts it to the CIELAB color space. See d3.color for examples. `d3.Lab.from(color)` converts a
*color* instance to the RGB color space using *color*.rgb and then to CIELAB. (Colors already in
the CIELAB color space skip the conversion to RGB, and colors in the HCL color space are converted
directly to CIELAB.)

### d3.gray(*l*[, *opacity*])

Constructs a new CIELAB color with the specified *l* value and *a* = *b* = 0.

### d3.Hcl(*h*, *c*, *l*[, *opacity*]), d3.Hcl.parse(*specifier*), d3.Hcl.from(*color*)

Equivalent to d3.lch, but with reversed argument order. `d3.Hcl.parse` and `d3.Hcl.from` are also
the forms of `d3.lch(specifier)` and `d3.lch(color)` of d3-color.

### d3.lch(*l*, *c*, *h*[, *opacity*])

Constructs a new CIELCh<sub>ab</sub> color. The channel values are exposed as `l`, `c` and `h`
properties on the returned instance. The value of *l* is typically in the range [0, 100], *c* is
typically in [0, 230], and *h* is typically in [0, 360).

A *color* instance is converted to the RGB color space using *color*.rgb and then to
CIELCh<sub>ab</sub>. (Colors already in CIELCh<sub>ab</sub> color space skip the conversion to
RGB, and colors in CIELAB color space are converted directly to CIELCh<sub>ab</sub>.)

### d3.Cubehelix(*h*, *s*, *l*[, *opacity*]), d3.Cubehelix.parse(*specifier*), d3.Cubehelix.from(*color*)

Constructs a new Cubehelix color. The channel values are exposed as `h`, `s` and `l` properties
on the returned instance.

`d3.Cubehelix(h, s, l)` takes the channel values of the returned color; an *opacity* may also be
specified. `d3.Cubehelix.parse(specifier)` parses a CSS Color Module Level 3 *specifier* string
and then converts it to the Cubehelix color space. See d3.color for examples.
`d3.Cubehelix.from(color)` converts a *color* instance to the RGB color space using *color*.rgb
and then to Cubehelix. (Colors already in the Cubehelix color space skip the conversion to RGB.)

## Flutter

`toUiColor()` gives the Flutter `Color` of a color, and `toD3Rgb()` gives the `d3.Rgb` of a
Flutter `Color`:

```dart
import 'package:flutter/painting.dart';
import 'package:flutter_d3_color_port/flutter_d3_color_port.dart' as d3;

final Color paint = d3.Hcl.parse('steelblue').brighter().toUiColor();
final d3.Rgb rgb = const Color(0xff4682b4).toD3Rgb();
```

`toUiColor()` clamps the channels to the sRGB range and keeps their fractions. An undefined (NaN)
channel is 0, and an undefined opacity is 1, as `formatRgb()` reads them.

## Differences from d3-color

- The d3-color factories `rgb`, `hsl`, `lab`, `hcl`, `lch` and `cubehelix` change with their
  argument count. In Dart, each form has its own constructor: `d3.Rgb(70, 130, 180)`,
  `d3.Rgb.parse('steelblue')` and `d3.Rgb.from(color)`.
- A channel is a `double`. A string channel, for example `rgb("12", "34", "56")`, does not
  compile. An omitted opacity is 1. NaN is an undefined channel, as in d3-color.
- `copy` takes named arguments: `color.copy(opacity: 0.5)`.
- The CIELAB and HCL conversions use `atan2`, `sin` and `cos` of `dart:math`. On a native
  platform, their last bit can differ from the browser. A channel exactly on a .5 boundary can
  then round to the other integer in `formatRgb()`.

## Performance

The figures are the time of one operation in nanoseconds, the mean of two runs. A lower number is
faster. The benchmark runs the same 26 cases on d3-color 3.1.0 and on this package, with the same
inputs. "AOT" is a compiled Dart executable or a release build of a Flutter app. "dart2js" and
"dart2wasm" are the JavaScript and WebAssembly builds of this package.

Apple M3 Max, macOS 27. d3-color, dart2js and dart2wasm run in Node.js v24.22.1.

| Case | d3-color in Node.js | Port, AOT | Port, dart2js | Port, dart2wasm |
|---|---:|---:|---:|---:|
| `parse.hex6` | 75 | 32 | 28 | 48 |
| `parse.hex3` | 65 | 25 | 25 | 37 |
| `parse.named` | 145 | 42 | 46 | 65 |
| `parse.rgb` | 147 | 47 | 71 | 78 |
| `parse.rgbaPercent` | 279 | 60 | 122 | 102 |
| `parse.hsl` | 221 | 44 | 76 | 71 |
| `parse.invalid` | 117 | 24 | 40 | 36 |
| `parse.mixed` | 173 | 45 | 76 | 72 |
| `rgb.parse` | 180 | 47 | 80 | 66 |
| `format.hex` | 45 | 13 | 16 | 31 |
| `format.hex8` | 59 | 20 | 23 | 40 |
| `format.rgb` | 54 | 25 | 33 | 31 |
| `format.hsl` | 200 | 97 | 105 | 115 |
| `format.rgbOfHsl` | 33 | 31 | 47 | 50 |
| `convert.rgbToHsl` | 20 | 10 | 25 | 9 |
| `convert.hslToRgb` | 20 | 11 | 23 | 18 |
| `convert.rgbToLab` | 88 | 79 | 88 | 64 |
| `convert.labToRgb` | 43 | 37 | 52 | 49 |
| `convert.rgbToHcl` | 129 | 108 | 122 | 115 |
| `convert.hclToRgb` | 72 | 55 | 78 | 75 |
| `convert.rgbToCubehelix` | 43 | 17 | 38 | 9 |
| `convert.cubehelixToRgb` | 38 | 20 | 41 | 32 |
| `op.brighterRgb` | 9 | 6 | 13 | 9 |
| `op.darkerHcl` | 9 | 6 | 13 | 9 |
| `pipe.hclTick` | 174 | 82 | 109 | 108 |
| `pipe.parseHex` | 220 | 61 | 84 | 97 |

Pixel 8a (Android 17) and iPhone 17 Pro (iOS 27). The browser builds run in Chrome 157 on the
Pixel.

| Case | Pixel 8a: d3-color in Chrome | Pixel 8a: port, AOT | Pixel 8a: port, dart2js in Chrome | Pixel 8a: port, dart2wasm in Chrome | iPhone 17 Pro: port, AOT |
|---|---:|---:|---:|---:|---:|
| `parse.hex6` | 112 | 48 | 44 | 56 | 19 |
| `parse.hex3` | 98 | 44 | 39 | 48 | 19 |
| `parse.named` | 122 | 65 | 53 | 95 | 29 |
| `parse.rgb` | 190 | 71 | 93 | 119 | 34 |
| `parse.rgbaPercent` | 418 | 90 | 160 | 166 | 43 |
| `parse.hsl` | 269 | 67 | 108 | 112 | 32 |
| `parse.invalid` | 122 | 36 | 51 | 56 | 17 |
| `parse.mixed` | 217 | 66 | 99 | 109 | 31 |
| `rgb.parse` | 226 | 69 | 105 | 107 | 33 |
| `format.hex` | 73 | 33 | 31 | 57 | 13 |
| `format.hex8` | 94 | 41 | 36 | 68 | 18 |
| `format.rgb` | 69 | 42 | 48 | 46 | 18 |
| `format.hsl` | 197 | 152 | 115 | 156 | 77 |
| `format.rgbOfHsl` | 46 | 56 | 63 | 69 | 22 |
| `convert.rgbToHsl` | 35 | 21 | 34 | 17 | 9 |
| `convert.hslToRgb` | 28 | 19 | 32 | 30 | 9 |
| `convert.rgbToLab` | 148 | 129 | 144 | 100 | 58 |
| `convert.labToRgb` | 70 | 65 | 79 | 80 | 29 |
| `convert.rgbToHcl` | 204 | 168 | 185 | 176 | 88 |
| `convert.hclToRgb` | 105 | 87 | 110 | 109 | 42 |
| `convert.rgbToCubehelix` | 74 | 51 | 68 | 19 | 15 |
| `convert.cubehelixToRgb` | 45 | 37 | 54 | 41 | 20 |
| `op.brighterRgb` | 19 | 14 | 22 | 16 | 8 |
| `op.darkerHcl` | 17 | 14 | 23 | 16 | 8 |
| `pipe.hclTick` | 247 | 128 | 146 | 154 | 54 |
| `pipe.parseHex` | 278 | 93 | 117 | 158 | 47 |

The cases:

- `parse.*`: `d3.color(text)` with hexadecimal texts of 6 and 3 digits, color names, `rgb()`,
  `rgba()` with percents, `hsl()`, texts that are not colors, and a mix of all of them.
- `rgb.parse`: `d3.Rgb.parse(text)` with the mix of texts.
- `format.*`: `formatHex()`, `formatHex8()`, `formatRgb()` and `formatHsl()`, and
  `toString()` of an HSL color (`format.rgbOfHsl`).
- `convert.*`: the conversions between RGB and HSL, CIELAB, HCL and Cubehelix.
- `op.*`: `brighter()` of an RGB color and `darker()` of an HCL color.
- `pipe.hclTick`: one step of an HCL color animation: a new hue, then `toString()`.
- `pipe.parseHex`: `d3.Rgb.parse(text).formatHex()`.

## License

ISC, the license of d3-color. The `LICENSE` file keeps the notice of Mike Bostock. This project is
not affiliated with the D3 project.
