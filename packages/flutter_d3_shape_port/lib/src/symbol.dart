// Ported from d3-shape v3.2.0 src/symbol.js (ISC, Mike Bostock).

/// Port of `src/symbol.js` of d3-shape 3.2.0: [ShapeSymbol], [symbol],
/// [symbolsFill], and [symbolsStroke].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/path.dart';
import 'package:flutter_d3_shape_port/src/symbol/asterisk.dart';
import 'package:flutter_d3_shape_port/src/symbol/circle.dart';
import 'package:flutter_d3_shape_port/src/symbol/cross.dart';
import 'package:flutter_d3_shape_port/src/symbol/diamond.dart';
import 'package:flutter_d3_shape_port/src/symbol/diamond2.dart';
import 'package:flutter_d3_shape_port/src/symbol/plus.dart';
import 'package:flutter_d3_shape_port/src/symbol/square.dart';
import 'package:flutter_d3_shape_port/src/symbol/square2.dart';
import 'package:flutter_d3_shape_port/src/symbol/star.dart';
import 'package:flutter_d3_shape_port/src/symbol/times.dart';
import 'package:flutter_d3_shape_port/src/symbol/triangle.dart';
import 'package:flutter_d3_shape_port/src/symbol/triangle2.dart';
import 'package:flutter_d3_shape_port/src/symbol/wye.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

/// Symbol type accessor for [ShapeSymbol].
typedef SymbolTypeAccessor<T> = SymbolType Function(T d);

/// Symbol size (area in square pixels) accessor for [ShapeSymbol].
typedef SymbolSizeAccessor<T> = double Function(T d);

/// `symbol.js:18` `symbolsFill`: the seven built-in symbol types designed to
/// be filled.
const List<SymbolType> symbolsFill = [
  symbolCircle,
  symbolCross,
  symbolDiamond,
  symbolSquare,
  symbolStar,
  symbolTriangle,
  symbolWye,
];

/// `index.js:10` `symbols`: deprecated alias for [symbolsFill].
@Deprecated('Use symbolsFill.')
const List<SymbolType> symbols = symbolsFill;

/// `symbol.js:29` `symbolsStroke`: the seven built-in symbol types designed to
/// be stroked (1.5px stroke width with round caps).
const List<SymbolType> symbolsStroke = [
  symbolCircle,
  symbolPlus,
  symbolTimes,
  symbolTriangle2,
  symbolAsterisk,
  symbolSquare2,
  symbolDiamond2,
];

SymbolType _defaultSymbolType<T>(T d) => symbolCircle;
double _defaultSymbolSize<T>(T d) => 64;

/// `symbol.js:39` `Symbol`: symbol path generator. Named `ShapeSymbol` in Dart
/// to avoid colliding with `dart:core.Symbol` (D3 ADR 0015).
// DIVERGES(d3-shape): adapt-shape-typed-api, named ShapeSymbol<T>.
// DIVERGES(d3-shape): adapt-shape-fast-forms, constant type/size fast paths.
final class ShapeSymbol<T>([SymbolType? type, double? size])
    with ShapePathMixin {
  /// Creates a symbol generator with optional constant [type] (defaults to
  /// [symbolCircle]) and [size] in square pixels (defaults to `64`).
  this;

  SymbolTypeAccessor<T> _type = type != null ? (_) => type : _defaultSymbolType;
  SymbolType? _typeConst = type ?? symbolCircle;

  SymbolSizeAccessor<T> _size = size != null ? (_) => size : _defaultSymbolSize;
  double? _sizeConst = size ?? 64;

  /// Rendering [CanvasPath] context (`null` emits an SVG string).
  CanvasPath? context;

  /// Generates the symbol for [d]. Returns an SVG path string when [context]
  /// is `null`, or writes directly into [context] and returns `null`.
  String? call([T? d]) {
    final datum = d as T;
    Path? buffer;
    final ctx = context ?? (buffer = createShapePath());
    final symType = _typeConst ?? _type(datum);
    final symSize = _sizeConst ?? _size(datum);
    symType.draw(ctx, symSize);
    if (buffer != null) {
      final result = buffer.toString();
      return result.isEmpty ? null : result;
    }
    return null;
  }

  /// Current symbol type accessor.
  SymbolTypeAccessor<T> get type => _type;

  /// Sets the symbol type accessor.
  set type(SymbolTypeAccessor<T> fn) {
    _type = fn;
    _typeConst = null;
  }

  /// Sets a constant [SymbolType].
  void typeConst(SymbolType value) {
    _type = (_) => value;
    _typeConst = value;
  }

  /// Current symbol size accessor (area in square pixels).
  SymbolSizeAccessor<T> get size => _size;

  /// Sets the symbol size accessor.
  set size(SymbolSizeAccessor<T> fn) {
    _size = fn;
    _sizeConst = null;
  }

  /// Sets a constant symbol size (area in square pixels).
  void sizeConst(double value) {
    _size = (_) => value;
    _sizeConst = value;
  }
}

/// `symbol.js:39` default export: creates a new [ShapeSymbol] generator.
ShapeSymbol<T> symbol<T>([SymbolType? type, double? size]) =>
    ShapeSymbol<T>(type, size);
