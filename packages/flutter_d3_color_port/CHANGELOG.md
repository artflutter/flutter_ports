## 0.3.1

- `LICENSE`: keep only the upstream copyright notice.

## 0.3.0

- **Breaking:** Rename `Color.copy(...)` to `Color.copyWith(...)` across `Color`, `Rgb`, `Hsl`,
  `Lab`, `Hcl`, and `Cubehelix` to follow standard Dart/Flutter immutable value conventions.

## 0.2.0

- **Breaking:** `Color`, `Rgb`, `Hsl`, `Lab`, `Hcl`, and `Cubehelix` are now immutable value
  classes with `final` channel fields and `const` constructors (D3 ADR 0013). Derive modified
  colors with `copy(...)`.
- Zero-allocation reuse in `rgbConvert`, `hslConvert`, `labConvert`, `hclConvert`,
  `cubehelixConvert` (same-space conversions and `null` NaN colors), and named CSS color lookups
  (`parse.named` 1.13× faster in AOT, 1.09× in dart2js).

## 0.1.2

- Remove an ignore comment that pana reports as `unnecessary_ignore` in a version that is not breaking.

## 0.1.1

- pubspec: a shorter description (151 characters), in the 60 to 180 characters of pub.dev.

## 0.1.0

- A native Dart port of d3-color 3.1.0: `color`, `Rgb`, `Hsl`, `Lab`, `Hcl`, `Cubehelix`, `gray`
  and `lch`, with no JavaScript runtime (D3 ADRs 0007 and 0010).
- The Flutter layer: `toUiColor()` on a d3-color `Color` and `toD3Rgb()` on a Flutter `Color`.
