## 0.1.0

- A native Dart port of d3-interpolate 3.0.1, with no JavaScript runtime (D3 ADRs 0007, 0010
  and 0011).
- The Flutter layer: `toTransformParts()` on a `Matrix4` and `toMatrix4()` on a `TransformParts`.
- Faster forms with the results of d3-interpolate: typed loops for the number lists, the lists of
  numbers and the transforms, and the constants of a zoom at its creation. The README has the speed
  table.
