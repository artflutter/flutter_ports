// Ported from d3-shape v3.2.0 src/path.js (ISC, Mike Bostock).

/// Port of `src/path.js` of d3-shape 3.2.0: default `Path` precision (`digits`)
/// support shared by all path-emitting shape generators.
library;

import 'package:flutter_d3_path_port/d3_path.dart';

/// `path.js:3` `withPath`: mixin providing `digits` (default `3`) and
/// [createShapePath] for path-emitting shape generators.
// DIVERGES(d3-shape): adapt-shape-typed-api, typed int? digits mixin.
mixin ShapePathMixin {
  int? _digits = 3;

  /// Maximum fractional digits for generated SVG path strings (`3` by default;
  /// `null` for full precision).
  int? get digits => _digits;

  /// Sets the maximum fractional digits for generated SVG path strings.
  ///
  /// Throws a [RangeError] if [value] is negative.
  set digits(int? value) {
    if (value == null) {
      _digits = null;
      return;
    }
    if (value < 0) {
      throw RangeError.value(value, 'digits', 'invalid digits: $value');
    }
    _digits = value;
  }

  /// Creates a fresh [Path] configured with the current [digits].
  @pragma('vm:prefer-inline')
  Path createShapePath() => Path(_digits);
}
