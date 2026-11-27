// Ported from d3-chord v3.0.1 src/ribbon.js (ISC, Mike Bostock).

/// Port of `src/ribbon.js` of d3-chord 3.0.1: [RibbonGenerator], [ribbon],
/// [ribbonArrow], [ribbonBy], and [ribbonArrowBy].
library;

import 'dart:math' as math;

import 'package:flutter_d3_chord_port/src/chord.dart';
import 'package:flutter_d3_chord_port/src/math.dart';
import 'package:flutter_d3_path_port/d3_path.dart';

/// Endpoint accessor extracting a subgroup [S] from a ribbon datum [T].
typedef RibbonEndpointAccessor<T, S> = S Function(T d);

/// Numeric accessor reading a radius or angle from a subgroup [S].
typedef RibbonSubgroupNumberAccessor<S> = double Function(S subgroup);

/// Numeric accessor reading a pad angle or arrowhead radius from a datum [T].
typedef RibbonNumberAccessor<T> = double Function(T d);

ChordSubgroup _defaultChordSource(Chord d) => d.source;
ChordSubgroup _defaultChordTarget(Chord d) => d.target;
double _defaultSubgroupStartAngle(ChordSubgroup s) => s.startAngle;
double _defaultSubgroupEndAngle(ChordSubgroup s) => s.endAngle;
double _defaultNanRadius<S>(S _) => double.nan;
double _defaultZeroAngle<S>(S _) => 0;
double _defaultPadAngle<T>(T _) => 0;
double _defaultArrowheadRadius<T>(T _) => 10;

/// `ribbon.js:34` `ribbon`: generates quadratic-Bézier chord ribbons (and
/// directional arrow ribbons) as SVG path strings or directly into a
/// [CanvasPath].
// DIVERGES(d3-chord): adapt-chord-typed-api, fully statically typed generic
// RibbonGenerator<T, S> with zero dynamic or Object? casts.
// DIVERGES(d3-chord): adapt-chord-fast-forms, unboxed constant-accessor fast
// paths, direct Chord/ChordSubgroup field reads, and reused start-point trig.
final class RibbonGenerator<T, S>({
  /// Source endpoint accessor.
  required RibbonEndpointAccessor<T, S> source,

  /// Target endpoint accessor.
  required RibbonEndpointAccessor<T, S> target,

  /// Source radius accessor.
  required RibbonSubgroupNumberAccessor<S> sourceRadius,

  /// Target radius accessor.
  required RibbonSubgroupNumberAccessor<S> targetRadius,

  /// Subgroup start angle accessor (radians, 0 at 12 o'clock, clockwise).
  required RibbonSubgroupNumberAccessor<S> startAngle,

  /// Subgroup end angle accessor (radians, 0 at 12 o'clock, clockwise).
  required RibbonSubgroupNumberAccessor<S> endAngle,

  /// Angular gap between adjacent ribbons in radians (defaults to `0`).
  RibbonNumberAccessor<T>? padAngle,

  /// Arrowhead radius accessor (`null` for plain ribbons; defaults to `10` for
  /// [ribbonArrow]).
  RibbonNumberAccessor<T>? headRadius,

  /// Rendering [CanvasPath] context (`null` emits an SVG path string).
  CanvasPath? context,
}) {
  /// Creates a [RibbonGenerator] with explicit typed accessors.
  this;

  RibbonEndpointAccessor<T, S> _source = source;
  RibbonEndpointAccessor<T, S> _target = target;
  RibbonSubgroupNumberAccessor<S> _sourceRadius = sourceRadius;
  RibbonSubgroupNumberAccessor<S> _targetRadius = targetRadius;
  RibbonSubgroupNumberAccessor<S> _startAngle = startAngle;
  RibbonSubgroupNumberAccessor<S> _endAngle = endAngle;
  RibbonNumberAccessor<T> _padAngle = padAngle ?? _defaultPadAngle;
  RibbonNumberAccessor<T>? _headRadius = headRadius;

  double? _sourceRadiusConst = identical(sourceRadius, _defaultNanRadius)
      ? double.nan
      : null;
  double? _targetRadiusConst = identical(targetRadius, _defaultNanRadius)
      ? double.nan
      : null;
  double? _startAngleConst = identical(startAngle, _defaultZeroAngle)
      ? 0
      : null;
  double? _endAngleConst = identical(endAngle, _defaultZeroAngle) ? 0 : null;
  double? _padAngleConst = padAngle == null ? 0 : null;
  double? _headRadiusConst = identical(headRadius, _defaultArrowheadRadius)
      ? 10
      : null;

  bool _defaultChordEndpoints =
      identical(source, _defaultChordSource) &&
      identical(target, _defaultChordTarget);
  bool _defaultSubgroupAngles =
      identical(startAngle, _defaultSubgroupStartAngle) &&
      identical(endAngle, _defaultSubgroupEndAngle);

  /// Rendering [CanvasPath] context (`null` emits an SVG path string).
  CanvasPath? context = context;

  /// Emits the ribbon geometry for [d] directly into [targetContext] without
  /// allocating an intermediate SVG string or mutating [context].
  void draw(T d, CanvasPath targetContext) {
    final double sr;
    final double tr;
    var sa0 = 0.0;
    var sa1 = 0.0;
    var ta0 = 0.0;
    var ta1 = 0.0;

    final srConst = _sourceRadiusConst;
    final trConst = _targetRadiusConst;

    if (_defaultChordEndpoints &&
        _defaultSubgroupAngles &&
        srConst != null &&
        trConst != null) {
      // Zero-closure fast path for Chord/ChordSubgroup with constant radii.
      final c = d as Chord;
      final cs = c.source;
      final ct = c.target;
      sr = srConst;
      tr = trConst;
      sa0 = cs.startAngle - chordHalfPi;
      sa1 = cs.endAngle - chordHalfPi;
      ta0 = ct.startAngle - chordHalfPi;
      ta1 = ct.endAngle - chordHalfPi;
    } else {
      final s = _source(d);
      final t = _target(d);
      sr = srConst ?? _sourceRadius(s);
      tr = trConst ?? _targetRadius(t);
      final sa0Const = _startAngleConst;
      final sa1Const = _endAngleConst;
      sa0 = (sa0Const ?? _startAngle(s)) - chordHalfPi;
      sa1 = (sa1Const ?? _endAngle(s)) - chordHalfPi;
      ta0 = (sa0Const ?? _startAngle(t)) - chordHalfPi;
      ta1 = (sa1Const ?? _endAngle(t)) - chordHalfPi;
    }

    final apConst = _padAngleConst;
    final ap = (apConst ?? _padAngle(d)) * 0.5;
    if (ap > chordEpsilon) {
      final ap2 = ap * 2 + chordEpsilon;
      if ((sa1 - sa0).abs() > ap2) {
        if (sa1 > sa0) {
          sa0 += ap;
          sa1 -= ap;
        } else {
          sa0 -= ap;
          sa1 += ap;
        }
      } else {
        sa0 = sa1 = (sa0 + sa1) * 0.5;
      }
      if ((ta1 - ta0).abs() > ap2) {
        if (ta1 > ta0) {
          ta0 += ap;
          ta1 -= ap;
        } else {
          ta0 -= ap;
          ta1 += ap;
        }
      } else {
        ta0 = ta1 = (ta0 + ta1) * 0.5;
      }
    }

    // Reuse start-point coordinates across moveTo and closing quadraticCurveTo.
    final sx0 = sr * math.cos(sa0);
    final sy0 = sr * math.sin(sa0);
    targetContext
      ..moveTo(sx0, sy0)
      ..arc(0, 0, sr, sa0, sa1);
    if (sa0 != ta0 || sa1 != ta1) {
      final hrFn = _headRadius;
      if (hrFn != null) {
        final hr = _headRadiusConst ?? hrFn(d);
        final tr2 = tr - hr;
        final ta2 = (ta0 + ta1) * 0.5;
        targetContext
          ..quadraticCurveTo(0, 0, tr2 * math.cos(ta0), tr2 * math.sin(ta0))
          ..lineTo(tr * math.cos(ta2), tr * math.sin(ta2))
          ..lineTo(tr2 * math.cos(ta1), tr2 * math.sin(ta1));
      } else {
        targetContext
          ..quadraticCurveTo(0, 0, tr * math.cos(ta0), tr * math.sin(ta0))
          ..arc(0, 0, tr, ta0, ta1);
      }
    }
    targetContext
      ..quadraticCurveTo(0, 0, sx0, sy0)
      ..closePath();
  }

  /// Generates the ribbon for [d]. Returns an SVG path string when [context]
  /// is `null`, or draws directly into [context] and returns `null`.
  String? call(T d) {
    final ctx = context;
    if (ctx != null) {
      draw(d, ctx);
      return null;
    }
    final buffer = path();
    draw(d, buffer);
    final result = buffer.toString();
    return result.isEmpty ? null : result;
  }

  /// Current source endpoint accessor.
  RibbonEndpointAccessor<T, S> get source => _source;

  /// Sets the source endpoint accessor.
  set source(RibbonEndpointAccessor<T, S> fn) {
    _source = fn;
    _defaultChordEndpoints =
        identical(_source, _defaultChordSource) &&
        identical(_target, _defaultChordTarget);
  }

  /// Current target endpoint accessor.
  RibbonEndpointAccessor<T, S> get target => _target;

  /// Sets the target endpoint accessor.
  set target(RibbonEndpointAccessor<T, S> fn) {
    _target = fn;
    _defaultChordEndpoints =
        identical(_source, _defaultChordSource) &&
        identical(_target, _defaultChordTarget);
  }

  /// Current source radius accessor (mirrors upstream `ribbon.radius()`).
  RibbonSubgroupNumberAccessor<S> get radius => _sourceRadius;

  /// Sets both [sourceRadius] and [targetRadius] to [fn].
  set radius(RibbonSubgroupNumberAccessor<S> fn) {
    _sourceRadius = _targetRadius = fn;
    _sourceRadiusConst = _targetRadiusConst = null;
  }

  /// Sets both [sourceRadius] and [targetRadius] to a constant [value].
  void radiusConst(double value) {
    double fn(S _) => value;
    _sourceRadius = _targetRadius = fn;
    _sourceRadiusConst = _targetRadiusConst = value;
  }

  /// Current source radius accessor.
  RibbonSubgroupNumberAccessor<S> get sourceRadius => _sourceRadius;

  /// Sets the source radius accessor.
  set sourceRadius(RibbonSubgroupNumberAccessor<S> fn) {
    _sourceRadius = fn;
    _sourceRadiusConst = null;
  }

  /// Sets the source radius to a constant [value].
  void sourceRadiusConst(double value) {
    _sourceRadius = (_) => value;
    _sourceRadiusConst = value;
  }

  /// Current target radius accessor.
  RibbonSubgroupNumberAccessor<S> get targetRadius => _targetRadius;

  /// Sets the target radius accessor.
  set targetRadius(RibbonSubgroupNumberAccessor<S> fn) {
    _targetRadius = fn;
    _targetRadiusConst = null;
  }

  /// Sets the target radius to a constant [value].
  void targetRadiusConst(double value) {
    _targetRadius = (_) => value;
    _targetRadiusConst = value;
  }

  /// Current start angle accessor.
  RibbonSubgroupNumberAccessor<S> get startAngle => _startAngle;

  /// Sets the start angle accessor.
  set startAngle(RibbonSubgroupNumberAccessor<S> fn) {
    _startAngle = fn;
    _startAngleConst = null;
    _defaultSubgroupAngles =
        identical(_startAngle, _defaultSubgroupStartAngle) &&
        identical(_endAngle, _defaultSubgroupEndAngle);
  }

  /// Sets the start angle to a constant [value].
  void startAngleConst(double value) {
    _startAngle = (_) => value;
    _startAngleConst = value;
    _defaultSubgroupAngles = false;
  }

  /// Current end angle accessor.
  RibbonSubgroupNumberAccessor<S> get endAngle => _endAngle;

  /// Sets the end angle accessor.
  set endAngle(RibbonSubgroupNumberAccessor<S> fn) {
    _endAngle = fn;
    _endAngleConst = null;
    _defaultSubgroupAngles =
        identical(_startAngle, _defaultSubgroupStartAngle) &&
        identical(_endAngle, _defaultSubgroupEndAngle);
  }

  /// Sets the end angle to a constant [value].
  void endAngleConst(double value) {
    _endAngle = (_) => value;
    _endAngleConst = value;
    _defaultSubgroupAngles = false;
  }

  /// Current pad angle accessor.
  RibbonNumberAccessor<T> get padAngle => _padAngle;

  /// Sets the pad angle accessor.
  set padAngle(RibbonNumberAccessor<T> fn) {
    _padAngle = fn;
    _padAngleConst = null;
  }

  /// Sets the pad angle to a constant [value].
  void padAngleConst(double value) {
    _padAngle = (_) => value;
    _padAngleConst = value;
  }

  /// Current arrowhead radius accessor (`null` for plain ribbons).
  RibbonNumberAccessor<T>? get headRadius => _headRadius;

  /// Sets the arrowhead radius accessor (`null` disables the arrowhead).
  set headRadius(RibbonNumberAccessor<T>? fn) {
    _headRadius = fn;
    _headRadiusConst = null;
  }

  /// Sets the arrowhead radius to a constant [value].
  void headRadiusConst(double value) {
    _headRadius = (_) => value;
    _headRadiusConst = value;
  }
}

/// `ribbon.js:128` default export: creates a [RibbonGenerator] pre-wired for
/// [Chord] and [ChordSubgroup].
RibbonGenerator<Chord, ChordSubgroup> ribbon({
  double? radius,
  double? sourceRadius,
  double? targetRadius,
  double? startAngle,
  double? endAngle,
  double? padAngle,
  CanvasPath? context,
}) {
  final gen = RibbonGenerator<Chord, ChordSubgroup>(
    source: _defaultChordSource,
    target: _defaultChordTarget,
    sourceRadius: _defaultNanRadius,
    targetRadius: _defaultNanRadius,
    startAngle: _defaultSubgroupStartAngle,
    endAngle: _defaultSubgroupEndAngle,
    context: context,
  );
  if (radius != null) gen.radiusConst(radius);
  if (sourceRadius != null) gen.sourceRadiusConst(sourceRadius);
  if (targetRadius != null) gen.targetRadiusConst(targetRadius);
  if (startAngle != null) gen.startAngleConst(startAngle);
  if (endAngle != null) gen.endAngleConst(endAngle);
  if (padAngle != null) gen.padAngleConst(padAngle);
  return gen;
}

/// `ribbon.js:132` `ribbonArrow`: creates an arrow [RibbonGenerator] pre-wired
/// for [Chord] and [ChordSubgroup] (default `headRadius` is `10`).
RibbonGenerator<Chord, ChordSubgroup> ribbonArrow({
  double? radius,
  double? sourceRadius,
  double? targetRadius,
  double? startAngle,
  double? endAngle,
  double? padAngle,
  double? headRadius,
  CanvasPath? context,
}) {
  final gen = RibbonGenerator<Chord, ChordSubgroup>(
    source: _defaultChordSource,
    target: _defaultChordTarget,
    sourceRadius: _defaultNanRadius,
    targetRadius: _defaultNanRadius,
    startAngle: _defaultSubgroupStartAngle,
    endAngle: _defaultSubgroupEndAngle,
    headRadius: _defaultArrowheadRadius,
    context: context,
  );
  if (radius != null) gen.radiusConst(radius);
  if (sourceRadius != null) gen.sourceRadiusConst(sourceRadius);
  if (targetRadius != null) gen.targetRadiusConst(targetRadius);
  if (startAngle != null) gen.startAngleConst(startAngle);
  if (endAngle != null) gen.endAngleConst(endAngle);
  if (padAngle != null) gen.padAngleConst(padAngle);
  if (headRadius != null) gen.headRadiusConst(headRadius);
  return gen;
}

/// Creates a custom-typed [RibbonGenerator<T, S>] with explicit accessors and
/// optional constant overrides.
// DIVERGES(d3-chord): adapt-chord-typed-api, generic ribbonBy<T, S> factory.
RibbonGenerator<T, S> ribbonBy<T, S>({
  required RibbonEndpointAccessor<T, S> source,
  required RibbonEndpointAccessor<T, S> target,
  RibbonSubgroupNumberAccessor<S>? radius,
  double? radiusConst,
  RibbonSubgroupNumberAccessor<S>? sourceRadius,
  double? sourceRadiusConst,
  RibbonSubgroupNumberAccessor<S>? targetRadius,
  double? targetRadiusConst,
  RibbonSubgroupNumberAccessor<S>? startAngle,
  double? startAngleConst,
  RibbonSubgroupNumberAccessor<S>? endAngle,
  double? endAngleConst,
  RibbonNumberAccessor<T>? padAngle,
  double? padAngleConst,
  CanvasPath? context,
}) {
  final gen = RibbonGenerator<T, S>(
    source: source,
    target: target,
    sourceRadius: sourceRadius ?? radius ?? _defaultNanRadius,
    targetRadius: targetRadius ?? radius ?? _defaultNanRadius,
    startAngle: startAngle ?? _defaultZeroAngle,
    endAngle: endAngle ?? _defaultZeroAngle,
    padAngle: padAngle,
    context: context,
  );
  if (radiusConst != null) gen.radiusConst(radiusConst);
  if (sourceRadiusConst != null) gen.sourceRadiusConst(sourceRadiusConst);
  if (targetRadiusConst != null) gen.targetRadiusConst(targetRadiusConst);
  if (startAngleConst != null) gen.startAngleConst(startAngleConst);
  if (endAngleConst != null) gen.endAngleConst(endAngleConst);
  if (padAngleConst != null) gen.padAngleConst(padAngleConst);
  return gen;
}

/// Creates a custom-typed arrow [RibbonGenerator<T, S>] with explicit
/// accessors and optional constant overrides (default `headRadius` is `10`).
// DIVERGES(d3-chord): adapt-chord-typed-api, generic ribbonArrowBy<T, S>
// factory.
RibbonGenerator<T, S> ribbonArrowBy<T, S>({
  required RibbonEndpointAccessor<T, S> source,
  required RibbonEndpointAccessor<T, S> target,
  RibbonSubgroupNumberAccessor<S>? radius,
  double? radiusConst,
  RibbonSubgroupNumberAccessor<S>? sourceRadius,
  double? sourceRadiusConst,
  RibbonSubgroupNumberAccessor<S>? targetRadius,
  double? targetRadiusConst,
  RibbonSubgroupNumberAccessor<S>? startAngle,
  double? startAngleConst,
  RibbonSubgroupNumberAccessor<S>? endAngle,
  double? endAngleConst,
  RibbonNumberAccessor<T>? padAngle,
  double? padAngleConst,
  RibbonNumberAccessor<T>? headRadius,
  double? headRadiusConst,
  CanvasPath? context,
}) {
  final gen = RibbonGenerator<T, S>(
    source: source,
    target: target,
    sourceRadius: sourceRadius ?? radius ?? _defaultNanRadius,
    targetRadius: targetRadius ?? radius ?? _defaultNanRadius,
    startAngle: startAngle ?? _defaultZeroAngle,
    endAngle: endAngle ?? _defaultZeroAngle,
    padAngle: padAngle,
    headRadius: headRadius ?? _defaultArrowheadRadius,
    context: context,
  );
  if (radiusConst != null) gen.radiusConst(radiusConst);
  if (sourceRadiusConst != null) gen.sourceRadiusConst(sourceRadiusConst);
  if (targetRadiusConst != null) gen.targetRadiusConst(targetRadiusConst);
  if (startAngleConst != null) gen.startAngleConst(startAngleConst);
  if (endAngleConst != null) gen.endAngleConst(endAngleConst);
  if (padAngleConst != null) gen.padAngleConst(padAngleConst);
  if (headRadiusConst != null) gen.headRadiusConst(headRadiusConst);
  return gen;
}
