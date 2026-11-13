// Original code, not ported from Chart.js: the dataset option shadow.

/// The value of the port-only dataset option `shadow` (Chart.js ADRs 0107
/// and 0139).
library;

import 'dart:ui' show Color, Offset;

import 'package:meta/meta.dart' show immutable;

/// The shadow of a dataset: the value of the dataset option `shadow`
/// (Chart.js ADRs 0107 and 0139), the canvas shadow around the draw of the
/// dataset.
///
/// The values are those of the Canvas 2D shadow: [blur] is `shadowBlur`, so
/// the Gaussian sigma of the blur is `blur / 2`, and [offset] is in logical
/// pixels and does not follow the transform of the canvas.
///
/// ```dart
/// const shadow = ChartShadow(color: Color(0x40000000), blur: 8);
/// LineDataset(data: points, shadow: shadow);
/// <String, Object?>{'data': points, 'shadow': shadow};
/// ```
@immutable
class const ChartShadow({
  /// The color of the shadow: `shadowColor`. A transparent color draws no
  /// shadow.
  required final Color color,

  /// The blur of the shadow: `shadowBlur`. 0 gives a sharp shadow.
  final double blur = 0,

  /// The move of the shadow: `shadowOffsetX` and `shadowOffsetY`.
  final Offset offset = Offset.zero,
}) {
  /// A shadow of [color], blurred by [blur] and moved by [offset].
  this : assert(blur >= 0, 'The blur is not negative.');

  /// A copy of this shadow with the given values.
  ChartShadow copyWith({Color? color, double? blur, Offset? offset}) =>
      ChartShadow(
        color: color ?? this.color,
        blur: blur ?? this.blur,
        offset: offset ?? this.offset,
      );

  @override
  bool operator ==(Object other) =>
      other is ChartShadow &&
      other.color == color &&
      other.blur == blur &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(color, blur, offset);

  @override
  String toString() =>
      'ChartShadow(color: $color, blur: $blur, '
      'offset: $offset)';
}
