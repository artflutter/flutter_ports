// Ported from d3-shape v3.2.0 src/order/descending.js (ISC, Mike Bostock).

/// Port of `src/order/descending.js` of d3-shape 3.2.0: [stackOrderDescending].
library;

import 'package:flutter_d3_shape_port/src/order/ascending.dart';
import 'package:flutter_d3_shape_port/src/stack.dart';

/// `order/descending.js:3` default export: orders series so the largest sum is
/// at the bottom.
List<int> stackOrderDescending(List<StackSeries<Object?, Object?>> series) =>
    stackOrderAscending(series).reversed.toList();
