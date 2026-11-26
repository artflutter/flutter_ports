// Original code, not ported from d3-shape: direct Flutter dart:ui Path helpers.

/// Direct Flutter `dart:ui.Path` helpers for `d3-shape` generators via
/// [UiPathContext] from `flutter_d3_path_port` (D3 ADR 0015).
///
/// Draws arcs, lines, areas, radial shapes, links, and symbols directly into a
/// `dart:ui.Path` with zero SVG string formatting or parsing.
library;

import 'dart:ui' as ui;

import 'package:flutter_d3_path_port/flutter_d3_path_port.dart';
import 'package:flutter_d3_shape_port/d3_shape.dart';

/// Direct `dart:ui.Path` rendering helpers for [Arc].
extension ArcUiPath<T> on Arc<T> {
  /// Builds a [ui.Path] for [d] without formatting an SVG string.
  ///
  /// When [target] is provided, commands are appended into [target] (call
  /// `target.reset()` to reuse across frames).
  ui.Path toUiPath([T? d, UiPathContext? target]) {
    final prev = context;
    final ctx = target ?? UiPathContext();
    context = ctx;
    try {
      call(d);
    } finally {
      context = prev;
    }
    return ctx.path;
  }
}

/// Direct `dart:ui.Path` rendering helpers for [Line].
extension LineUiPath<T> on Line<T> {
  /// Builds a [ui.Path] for [data] without formatting an SVG string.
  ui.Path toUiPath(Iterable<T> data, [UiPathContext? target]) {
    final prev = context;
    final ctx = target ?? UiPathContext();
    context = ctx;
    try {
      call(data);
    } finally {
      context = prev;
    }
    return ctx.path;
  }
}

/// Direct `dart:ui.Path` rendering helpers for [LineRadial].
extension LineRadialUiPath<T> on LineRadial<T> {
  /// Builds a [ui.Path] for [data] without formatting an SVG string.
  ui.Path toUiPath(Iterable<T> data, [UiPathContext? target]) {
    final prev = context;
    final ctx = target ?? UiPathContext();
    context = ctx;
    try {
      call(data);
    } finally {
      context = prev;
    }
    return ctx.path;
  }
}

/// Direct `dart:ui.Path` rendering helpers for [Area].
extension AreaUiPath<T> on Area<T> {
  /// Builds a [ui.Path] for [data] without formatting an SVG string.
  ui.Path toUiPath(Iterable<T> data, [UiPathContext? target]) {
    final prev = context;
    final ctx = target ?? UiPathContext();
    context = ctx;
    try {
      call(data);
    } finally {
      context = prev;
    }
    return ctx.path;
  }
}

/// Direct `dart:ui.Path` rendering helpers for [AreaRadial].
extension AreaRadialUiPath<T> on AreaRadial<T> {
  /// Builds a [ui.Path] for [data] without formatting an SVG string.
  ui.Path toUiPath(Iterable<T> data, [UiPathContext? target]) {
    final prev = context;
    final ctx = target ?? UiPathContext();
    context = ctx;
    try {
      call(data);
    } finally {
      context = prev;
    }
    return ctx.path;
  }
}

/// Direct `dart:ui.Path` rendering helpers for [Link].
extension LinkUiPath<L, N> on Link<L, N> {
  /// Builds a [ui.Path] for [d] without formatting an SVG string.
  ui.Path toUiPath(L d, [UiPathContext? target]) {
    final prev = context;
    final ctx = target ?? UiPathContext();
    context = ctx;
    try {
      call(d);
    } finally {
      context = prev;
    }
    return ctx.path;
  }
}

/// Direct `dart:ui.Path` rendering helpers for [LinkRadial].
extension LinkRadialUiPath<L, N> on LinkRadial<L, N> {
  /// Builds a [ui.Path] for [d] without formatting an SVG string.
  ui.Path toUiPath(L d, [UiPathContext? target]) {
    final prev = context;
    final ctx = target ?? UiPathContext();
    context = ctx;
    try {
      call(d);
    } finally {
      context = prev;
    }
    return ctx.path;
  }
}

/// Direct `dart:ui.Path` rendering helpers for [ShapeSymbol].
extension SymbolUiPath<T> on ShapeSymbol<T> {
  /// Builds a [ui.Path] for [d] without formatting an SVG string.
  ui.Path toUiPath([T? d, UiPathContext? target]) {
    final prev = context;
    final ctx = target ?? UiPathContext();
    context = ctx;
    try {
      call(d);
    } finally {
      context = prev;
    }
    return ctx.path;
  }
}
