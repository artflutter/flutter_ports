// Ported from d3-array v3.2.4 src/subset.js (ISC, Mike Bostock).

/// Port of `src/subset.js` of d3-array 3.2.4.
library;

import 'package:flutter_d3_array_port/src/superset.dart';

/// Returns `true` if [values] is a subset of [other] (every value in [values]
/// also appears in [other]).
bool subset<T>(Iterable<T> values, Iterable<T> other) =>
    superset<T>(other, values);
