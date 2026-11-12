// Original code, not ported from Chart.js: scalar radial loop positions.

import 'dart:math' as math;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show halfPi, normalizeAngle;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:meta/meta.dart';

/// A radial scale whose position methods have the built-in behavior.
// A runtime capability, not a standalone operation.
// ignore: one_member_abstracts
abstract interface class NativeRadialPositionScale {
  /// The current inputs of the position methods, or null for their ordinary
  /// calls. Unknown subclasses and an option that no ordinary read resolved yet
  /// give null, so that this call runs no user code.
  RadialPositions? prepareRadialPositions();
}

/// The inputs of `getIndexAngle`, `getDistanceFromCenterForValue` and
/// `getPointPosition` of the exact built-in scale (Chart.js ADR 0095).
///
/// They belong to one synchronous loop in which no user code runs. Nothing
/// keeps this object after that loop: a later loop reads the inputs again.
/// The arithmetic is the arithmetic of the methods, in their order, so each
/// result has the bits of the method result.
@internal
final class RadialPositions {
  /// The inputs at the current state of the scale.
  const RadialPositions({
    required this.angleStep,
    required this.startRadians,
    required this.xCenter,
    required this.yCenter,
    required this.min,
    required this.max,
    required this.scalingFactor,
    required this.reverse,
  });

  /// `TAU / (this._pointLabels.length || 1)`.
  final double angleStep;

  /// `toRadians(this.options.startAngle || 0)`.
  final double startRadians;

  /// `xCenter`, NaN for `undefined`.
  final double xCenter;

  /// `yCenter`, NaN for `undefined`.
  final double yCenter;

  /// `min`.
  final double min;

  /// `max`.
  final double max;

  /// `this.drawingArea / (this.max - this.min)`.
  final double scalingFactor;

  /// The truth of `this.options.reverse`.
  final bool reverse;

  /// `getIndexAngle(index)`.
  @pragma('vm:prefer-inline')
  double indexAngleAt(int index) =>
      normalizeAngle(index * angleStep + startRadians);

  /// `getDistanceFromCenterForValue(value)` of a number.
  @pragma('vm:prefer-inline')
  double distanceOf(double value) =>
      (reverse ? max - value : value - min) * scalingFactor;

  /// `getPointPosition(index, distance, additionalAngle)`. `Math.cos` and
  /// `Math.sin` are `dart:math` (Chart.js ADR 0122).
  @pragma('vm:prefer-inline')
  ({double x, double y, double angle}) positionAt(
    int index,
    double distance, [
    double additionalAngle = 0,
  ]) {
    final angle = indexAngleAt(index) - halfPi + additionalAngle;
    return (
      x: math.cos(angle) * distance + xCenter,
      y: math.sin(angle) * distance + yCenter,
      angle: angle,
    );
  }
}

/// A resolved option value that a contextual view gives unchanged for each
/// context: no function, array or object, and no color class of user code.
@internal
bool plainOptionValue(Object? value) =>
    value == null ||
    value is Undefined ||
    value is String ||
    value is num ||
    value is bool ||
    value.runtimeType == Color;
