## 0.3.1

- `LICENSE`: keep only the upstream copyright notice.

## 0.3.0

- **Breaking:** Upgrade `flutter_d3_color_port` to `^0.3.0` (`Color.copyWith(...)`).

## 0.2.0

- **Breaking:** Upgrade `flutter_d3_color_port` to `^0.2.0` (immutable `const` color classes,
  D3 ADR 0013). Color interpolators now take and return immutable `Color` instances, avoiding
  defensive endpoint copies on creation (`create.rgb` 1.16× faster in AOT / 1.17× in dart2wasm,
  `create.valueColor` 1.14× faster in AOT / 1.20× in dart2wasm).

## 0.1.0

- A native Dart port of d3-interpolate 3.0.1, with no JavaScript runtime (D3 ADRs 0007, 0010
  and 0011).
- The Flutter layer: `toTransformParts()` on a `Matrix4` and `toMatrix4()` on a `TransformParts`.
- Faster forms with the results of d3-interpolate: typed loops for the number lists, the lists of
  numbers and the transforms, one class for the channels of a color, and the constants of a zoom at
  its creation. The README has the speed table.
