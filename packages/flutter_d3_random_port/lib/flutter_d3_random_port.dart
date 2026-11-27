// Original code, not ported from d3-random: package public library.

/// A native, fully statically typed pure-Dart port of
/// [d3-random](https://github.com/d3/d3-random) 3.0.1 for Dart and Flutter.
///
/// Re-exports `d3_random.dart` (`RandomSource`, `RandomGenerator`,
/// `RandomIntGenerator`, `randomLcg`, all 17 distribution factories with typed
/// `.source(RandomSource)`, typed `Float64List`/`Int32List` batch `fill`/
/// `sample` helpers, and `d3RandomVersion`).
library;

export 'package:flutter_d3_random_port/d3_random.dart';
