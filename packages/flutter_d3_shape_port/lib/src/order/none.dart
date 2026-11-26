// Ported from d3-shape v3.2.0 src/order/none.js (ISC, Mike Bostock).

/// Port of `src/order/none.js` of d3-shape 3.2.0: [stackOrderNone].
library;

import 'package:flutter_d3_shape_port/src/stack.dart';

/// `order/none.js:1` default export: returns the identity series order
/// `[0, 1, ..., n - 1]`.
List<int> stackOrderNone(List<StackSeries<Object?, Object?>> series) =>
    List<int>.generate(series.length, (i) => i);
