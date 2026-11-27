// Original code, not ported from d3-array: the pure library of the package.

/// d3-array 3.2.4 in native, fully statically typed Dart with no Flutter
/// import (ADR 0011, D3 ADR 0017).
///
/// Exports every pure file of the port without `show`/`hide` combinators so it
/// compiles for the Dart VM, AOT, JavaScript, and WebAssembly with zero
/// runtime dependencies.
library;

export 'package:flutter_d3_array_port/src/array.dart';
export 'package:flutter_d3_array_port/src/ascending.dart';
export 'package:flutter_d3_array_port/src/bin.dart';
export 'package:flutter_d3_array_port/src/bisect.dart';
export 'package:flutter_d3_array_port/src/bisector.dart';
export 'package:flutter_d3_array_port/src/blur.dart';
export 'package:flutter_d3_array_port/src/constant.dart';
export 'package:flutter_d3_array_port/src/count.dart';
export 'package:flutter_d3_array_port/src/cross.dart';
export 'package:flutter_d3_array_port/src/cumsum.dart';
export 'package:flutter_d3_array_port/src/descending.dart';
export 'package:flutter_d3_array_port/src/deviation.dart';
export 'package:flutter_d3_array_port/src/difference.dart';
export 'package:flutter_d3_array_port/src/disjoint.dart';
export 'package:flutter_d3_array_port/src/every.dart';
export 'package:flutter_d3_array_port/src/extent.dart';
export 'package:flutter_d3_array_port/src/filter.dart';
export 'package:flutter_d3_array_port/src/fsum.dart';
export 'package:flutter_d3_array_port/src/greatest.dart';
export 'package:flutter_d3_array_port/src/greatestIndex.dart';
export 'package:flutter_d3_array_port/src/group.dart';
export 'package:flutter_d3_array_port/src/groupSort.dart';
export 'package:flutter_d3_array_port/src/identity.dart';
export 'package:flutter_d3_array_port/src/index.dart';
export 'package:flutter_d3_array_port/src/internmap.dart';
export 'package:flutter_d3_array_port/src/intersection.dart';
export 'package:flutter_d3_array_port/src/least.dart';
export 'package:flutter_d3_array_port/src/leastIndex.dart';
export 'package:flutter_d3_array_port/src/map.dart';
export 'package:flutter_d3_array_port/src/max.dart';
export 'package:flutter_d3_array_port/src/maxIndex.dart';
export 'package:flutter_d3_array_port/src/mean.dart';
export 'package:flutter_d3_array_port/src/median.dart';
export 'package:flutter_d3_array_port/src/merge.dart';
export 'package:flutter_d3_array_port/src/min.dart';
export 'package:flutter_d3_array_port/src/minIndex.dart';
export 'package:flutter_d3_array_port/src/mode.dart';
export 'package:flutter_d3_array_port/src/nice.dart';
export 'package:flutter_d3_array_port/src/number.dart';
export 'package:flutter_d3_array_port/src/pairs.dart';
export 'package:flutter_d3_array_port/src/permute.dart';
export 'package:flutter_d3_array_port/src/quantile.dart';
export 'package:flutter_d3_array_port/src/quickselect.dart';
export 'package:flutter_d3_array_port/src/range.dart';
export 'package:flutter_d3_array_port/src/rank.dart';
export 'package:flutter_d3_array_port/src/reduce.dart';
export 'package:flutter_d3_array_port/src/reverse.dart';
export 'package:flutter_d3_array_port/src/scan.dart';
export 'package:flutter_d3_array_port/src/shuffle.dart';
export 'package:flutter_d3_array_port/src/some.dart';
export 'package:flutter_d3_array_port/src/sort.dart';
export 'package:flutter_d3_array_port/src/subset.dart';
export 'package:flutter_d3_array_port/src/sum.dart';
export 'package:flutter_d3_array_port/src/superset.dart';
export 'package:flutter_d3_array_port/src/threshold/freedmanDiaconis.dart';
export 'package:flutter_d3_array_port/src/threshold/scott.dart';
export 'package:flutter_d3_array_port/src/threshold/sturges.dart';
export 'package:flutter_d3_array_port/src/ticks.dart';
export 'package:flutter_d3_array_port/src/transpose.dart';
export 'package:flutter_d3_array_port/src/union.dart';
export 'package:flutter_d3_array_port/src/upstream.dart';
export 'package:flutter_d3_array_port/src/variance.dart';
export 'package:flutter_d3_array_port/src/zip.dart';
