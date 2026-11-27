// Original code, not ported from d3-delaunay: Flutter dart:ui Path helpers.

/// Direct Flutter `dart:ui.Path` helpers for [Delaunay] and [Voronoi] via
/// [UiPathContext] from `flutter_d3_path_port` (D3 ADR 0022).
///
/// Draws Delaunay meshes, convex hulls, points, triangles, Voronoi meshes,
/// bounds, and individual clipped cells directly into a `dart:ui.Path` with
/// zero SVG string formatting or parsing.
library;

import 'dart:ui' as ui;

import 'package:flutter_d3_delaunay_port/d3_delaunay.dart';
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart';

/// Direct `dart:ui.Path` rendering helpers for [Delaunay].
extension DelaunayUiPath on Delaunay {
  /// Builds a [ui.Path] for all Delaunay triangulation edges.
  ///
  /// When [target] is provided, commands are appended into [target] (call
  /// `target.reset()` to reuse across frames).
  ui.Path toUiPath([UiPathContext? target]) {
    final ctx = target ?? UiPathContext();
    render(ctx);
    return ctx.path;
  }

  /// Builds a [ui.Path] for the closed convex hull.
  ui.Path hullToUiPath([UiPathContext? target]) {
    final ctx = target ?? UiPathContext();
    renderHull(ctx);
    return ctx.path;
  }

  /// Builds a [ui.Path] for all input points as circles of radius [r].
  ui.Path pointsToUiPath({double r = 2, UiPathContext? target}) {
    final ctx = target ?? UiPathContext();
    renderPoints(ctx, r);
    return ctx.path;
  }

  /// Builds a [ui.Path] for triangle [i].
  ui.Path triangleToUiPath(int i, [UiPathContext? target]) {
    final ctx = target ?? UiPathContext();
    renderTriangle(i, ctx);
    return ctx.path;
  }
}

/// Direct `dart:ui.Path` rendering helpers for [Voronoi].
extension VoronoiUiPath on Voronoi {
  /// Builds a [ui.Path] for the clipped Voronoi edge mesh.
  ///
  /// When [target] is provided, commands are appended into [target] (call
  /// `target.reset()` to reuse across frames).
  ui.Path toUiPath([UiPathContext? target]) {
    final ctx = target ?? UiPathContext();
    render(ctx);
    return ctx.path;
  }

  /// Builds a [ui.Path] for the Voronoi clipping bounds rectangle.
  ui.Path boundsToUiPath([UiPathContext? target]) {
    final ctx = target ?? UiPathContext();
    renderBounds(ctx);
    return ctx.path;
  }

  /// Builds a [ui.Path] for the clipped Voronoi cell [i].
  ui.Path cellToUiPath(int i, [UiPathContext? target]) {
    final ctx = target ?? UiPathContext();
    renderCell(i, ctx);
    return ctx.path;
  }
}
