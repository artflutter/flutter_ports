// Ported from d3-hierarchy v3.1.2 src/treemap/sliceDice.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/treemap/sliceDice.js` of d3-hierarchy 3.1.2:
/// [treemapSliceDice].
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';
import 'package:flutter_d3_hierarchy_port/src/treemap/dice.dart';
import 'package:flutter_d3_hierarchy_port/src/treemap/slice.dart';

/// Alternates between [treemapSlice] for odd `parent.depth` and [treemapDice]
/// for even `parent.depth`.
void treemapSliceDice<T>(
  HierarchyRectangularNode<T> parent,
  double x0,
  double y0,
  double x1,
  double y1,
) {
  if ((parent.depth & 1) != 0) {
    treemapSlice(parent, x0, y0, x1, y1);
  } else {
    treemapDice(parent, x0, y0, x1, y1);
  }
}
