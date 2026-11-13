// Original code, not ported from Chart.js: the tooltip positioner.

/// The position of a tooltip and the object that finds it (row
/// `adapt-tooltip-positioner-objects`).
///
/// The option `position` of the tooltip holds a [TooltipPositioner]. The two
/// positioners of upstream are classes of `plugin.tooltip.dart`
/// (`AverageTooltipPositioner`, `NearestTooltipPositioner`). The base class
/// and its result are here, because the option cell of `opt.dart` reads the
/// type of the option, and `plugin.tooltip.dart` is not a pure layer.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/typed_record.dart';
import 'package:flutter_chartjs_port/src/types/align.dart'
    show TooltipXAlign, TooltipYAlign;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// A tooltip positioner: the value of the option `position` of the tooltip.
/// It finds the position of the tooltip for its active items.
///
/// Upstream holds the name of a positioner in the option and calls the
/// function `positioners[options.position]` with the tooltip as `this`
/// (plugin.tooltip.js:651, :1012, :1218). The port holds the positioner
/// itself: the tooltip calls [positionOf] of the value of the option, and
/// reads no table. A program gives its own positioner as a subclass, with
/// no registration:
///
/// ```dart
/// final class TopLeftPositioner extends TooltipPositioner {
///   const TopLeftPositioner();
///
///   @override
///   TooltipPosition? positionOf(
///     TooltipModel tooltip,
///     List<ActiveElement> items,
///     Object? eventPosition,
///   ) {
///     if (items.isEmpty) return null;
///     final area = tooltip.chart.chartArea!;
///     return TooltipPosition()
///       ..x = area.left
///       ..y = area.top;
///   }
/// }
/// ```
@immutable
abstract class const TooltipPositioner() {
  /// A positioner.
  this;

  /// The position of [tooltip] for the active [items], or Dart `null` for no
  /// position, the `false` of an upstream positioner (plugin.tooltip.js:23,
  /// :59). [tooltip] is the `this` of the upstream function.
  /// [eventPosition] is the position of the event of the tooltip: a
  /// [TooltipPosition] or a `Point`, or the value that a program gave to
  /// `setActiveElements`.
  TooltipPosition? positionOf(
    types.TooltipModel tooltip,
    List<types.ActiveElement> items,
    Object? eventPosition,
  );

  /// The positioner of [value], the value of an option `position`, or Dart
  /// `null` for a value that is not a positioner. A positioner name of
  /// Chart.js is not a positioner: a debug build stops on it.
  static TooltipPositioner? of(Object? value) {
    assert(
      value is! String,
      'The option position of the tooltip takes a TooltipPositioner, not '
      'the name "$value".',
    );
    return value is TooltipPositioner ? value : null;
  }
}

/// `TooltipPosition` (`index.d.ts`): the position `{x, y}` of a built-in
/// positioner (plugin.tooltip.js:53, :90) and the event position `{x, y}`
/// of `handleEvent` (:1173), with the optional `xAlign` and `yAlign` of a
/// position. `x` and `y` hold any JS value; `xAlign` and `yAlign` hold a
/// [TooltipXAlign] and a [TooltipYAlign] (row `adapt-tooltip-align-enums`).
/// A write by name of another value keeps it in the foreign slot.
final class TooltipPosition() extends TypedRecord {
  /// An object without own keys.
  this;

  static const List<String> _fieldNames = ['x', 'y', 'xAlign', 'yAlign'];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'x' => 0,
    'y' => 1,
    'xAlign' => 2,
    'yAlign' => 3,
    _ => -1,
  };

  Object? _x;

  Object? _y;

  TooltipXAlign? _xAlign;

  TooltipYAlign? _yAlign;

  /// `x`, or [undefined] when absent.
  Object? get x => hasSlot(0) ? _x : undefined;

  set x(Object? value) {
    _x = value;
    touchSlot(0);
  }

  /// `y`, or [undefined] when absent.
  Object? get y => hasSlot(1) ? _y : undefined;

  set y(Object? value) {
    _y = value;
    touchSlot(1);
  }

  /// `xAlign`, or Dart `null` when absent.
  TooltipXAlign? get xAlign => _xAlign;

  set xAlign(TooltipXAlign? value) {
    _xAlign = value;
    touchSlot(2);
  }

  /// `yAlign`, or Dart `null` when absent.
  TooltipYAlign? get yAlign => _yAlign;

  set yAlign(TooltipYAlign? value) {
    _yAlign = value;
    touchSlot(3);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _x,
    1 => _y,
    2 => _xAlign,
    _ => _yAlign,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _x = value;
      case 1:
        _y = value;
      case 2:
        if (value is! TooltipXAlign?) {
          _xAlign = null;
          return false;
        }
        _xAlign = value;
      default:
        if (value is! TooltipYAlign?) {
          _yAlign = null;
          return false;
        }
        _yAlign = value;
    }
    return true;
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _x = null;
      case 1:
        _y = null;
      case 2:
        _xAlign = null;
      default:
        _yAlign = null;
    }
  }
}
