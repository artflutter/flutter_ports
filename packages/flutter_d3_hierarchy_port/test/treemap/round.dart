// Ported from d3-hierarchy v3.1.2 test/treemap/round.js (ISC, Mike Bostock).

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';

/// Rounded rectangle record used by treemap spec tests.
typedef RoundedRect = ({double x0, double y0, double x1, double y1});

double _r(double x) => (x * 100).roundToDouble() / 100;

/// Rounds the rectangular bounds of [d] to 2 decimal places.
RoundedRect roundRect<T>(HierarchyRectangularNode<T> d) =>
    (x0: _r(d.x0), y0: _r(d.y0), x1: _r(d.x1), y1: _r(d.y1));
