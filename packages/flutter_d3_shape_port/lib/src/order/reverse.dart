// Ported from d3-shape v3.2.0 src/order/reverse.js (ISC, Mike Bostock).

/// Port of `src/order/reverse.js` of d3-shape 3.2.0: [stackOrderReverse].
library;

import 'package:flutter_d3_shape_port/src/order/none.dart';
import 'package:flutter_d3_shape_port/src/stack.dart';

/// `order/reverse.js:3` default export: returns the reverse of the input
/// series order `[n - 1, ..., 1, 0]`.
List<int> stackOrderReverse(List<StackSeries<Object?, Object?>> series) =>
    stackOrderNone(series).reversed.toList();
