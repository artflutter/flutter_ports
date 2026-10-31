// Original code, not ported from Chart.js: the typed element properties.

/// The property objects of the controllers (Chart.js ADR 0054 §9): the
/// objects that a controller gives to `updateElement(element, index,
/// properties, mode)` in place of an object literal. Each class has a typed
/// field for each key of the literals of upstream, in the key order of the
/// writes (a [TypedRecord]: the insertion order of JS), extras for another
/// key and the face (Chart.js ADR 0054 §5). `Animations.update` reads it by
/// its typed keys.
///
/// The names end in `Properties`, the name of the upstream variable:
/// `PointProps` (element.point.ts:18) and `ArcProps` (element.arc.ts:365)
/// are the property types of the element classes. [BorderSkipped] is the
/// `borderSkipped` object of a bar (`setBorderSkipped`).
///
/// A `double` field is NaN when absent, a `bool` field false; a getter of
/// an `Object?` field gives [undefined] when absent, and the getter of the
/// `options` field (an object: resolved options, a typed object with a face
/// or a Map) gives Dart `null`. A write by name of a value outside the type of
/// a field keeps it in the foreign slot (Chart.js ADR 0054 §6).
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsToNumber, jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/typed_record.dart';

/// Whether [value] is an options object for the `options` field: a typed
/// object with a face (resolved options, a view) or a Map.
bool _isOptionsObject(Object? value) =>
    value is JsObjectFace || value is Map<String, Object?>;

/// The properties of a point element that the line, scatter, bubble and
/// radar controllers give to `updateElement` (U `controller.line.js:91-111`,
/// `controller.scatter.js:127-140`, `controller.bubble.js:128-138`,
/// `controller.radar.js:93-99`).
final class PointProperties extends TypedRecord {
  /// An object without own keys.
  PointProperties();

  static const List<String> _fieldNames = [
    'x',
    'y',
    'skip',
    'stop',
    'parsed',
    'raw',
    'options',
    'angle',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'x' => 0,
    'y' => 1,
    'skip' => 2,
    'stop' => 3,
    'parsed' => 4,
    'raw' => 5,
    'options' => 6,
    'angle' => 7,
    _ => -1,
  };

  double _x = double.nan;

  double _y = double.nan;

  bool _skip = false;

  bool _stop = false;

  Object? _parsed;

  Object? _raw;

  Object? _options;

  double _angle = double.nan;

  /// `x`.
  double get x => _x;

  set x(double value) {
    _x = value;
    touchSlot(0);
  }

  /// `y`.
  double get y => _y;

  set y(double value) {
    _y = value;
    touchSlot(1);
  }

  /// `skip`.
  bool get skip => _skip;

  set skip(bool value) {
    _skip = value;
    touchSlot(2);
  }

  /// `stop`.
  bool get stop => _stop;

  set stop(bool value) {
    _stop = value;
    touchSlot(3);
  }

  /// `parsed`.
  Object? get parsed => hasSlot(4) ? _parsed : undefined;

  set parsed(Object? value) {
    _parsed = value;
    touchSlot(4);
  }

  /// `raw`.
  Object? get raw => hasSlot(5) ? _raw : undefined;

  set raw(Object? value) {
    _raw = value;
    touchSlot(5);
  }

  /// `options`.
  Object? get options => hasSlot(6) && !isForeignSlot(6) ? _options : null;

  set options(Object? value) {
    _options = value;
    touchSlot(6);
  }

  /// `angle`.
  double get angle => _angle;

  set angle(double value) {
    _angle = value;
    touchSlot(7);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _x,
    1 => _y,
    2 => _skip,
    3 => _stop,
    4 => _parsed,
    5 => _raw,
    6 => _options,
    _ => _angle,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _x = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 1:
        _y = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 2:
        _skip = value is bool ? value : jsTruthy(value);
        return value is bool;
      case 3:
        _stop = value is bool ? value : jsTruthy(value);
        return value is bool;
      case 4:
        _parsed = value;
        return true;
      case 5:
        _raw = value;
        return true;
      case 6:
        final object = _isOptionsObject(value);
        _options = object ? value : null;
        return object || value == null;
      default:
        _angle = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
    }
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _x = double.nan;
      case 1:
        _y = double.nan;
      case 2:
        _skip = false;
      case 3:
        _stop = false;
      case 4:
        _parsed = null;
      case 5:
        _raw = null;
      case 6:
        _options = null;
      default:
        _angle = double.nan;
    }
  }
}

/// The properties of a bar element that the bar controller gives to
/// `updateElement` (U `controller.bar.js:407-424`, `:183-255`).
final class BarProperties extends TypedRecord {
  /// An object without own keys.
  BarProperties();

  static const List<String> _fieldNames = [
    'horizontal',
    'base',
    'enableBorderRadius',
    'x',
    'y',
    'height',
    'width',
    'options',
    'borderSkipped',
    'inflateAmount',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'horizontal' => 0,
    'base' => 1,
    'enableBorderRadius' => 2,
    'x' => 3,
    'y' => 4,
    'height' => 5,
    'width' => 6,
    'options' => 7,
    'borderSkipped' => 8,
    'inflateAmount' => 9,
    _ => -1,
  };

  bool _horizontal = false;

  double _base = double.nan;

  bool _enableBorderRadius = false;

  double _x = double.nan;

  double _y = double.nan;

  double _height = double.nan;

  double _width = double.nan;

  Object? _options;

  Object? _borderSkipped;

  double _inflateAmount = double.nan;

  /// `horizontal`.
  bool get horizontal => _horizontal;

  set horizontal(bool value) {
    _horizontal = value;
    touchSlot(0);
  }

  /// `base`.
  double get base => _base;

  set base(double value) {
    _base = value;
    touchSlot(1);
  }

  /// `enableBorderRadius`.
  bool get enableBorderRadius => _enableBorderRadius;

  set enableBorderRadius(bool value) {
    _enableBorderRadius = value;
    touchSlot(2);
  }

  /// `x`.
  double get x => _x;

  set x(double value) {
    _x = value;
    touchSlot(3);
  }

  /// `y`.
  double get y => _y;

  set y(double value) {
    _y = value;
    touchSlot(4);
  }

  /// `height`.
  double get height => _height;

  set height(double value) {
    _height = value;
    touchSlot(5);
  }

  /// `width`.
  double get width => _width;

  set width(double value) {
    _width = value;
    touchSlot(6);
  }

  /// `options`.
  Object? get options => hasSlot(7) && !isForeignSlot(7) ? _options : null;

  set options(Object? value) {
    _options = value;
    touchSlot(7);
  }

  /// `borderSkipped`.
  Object? get borderSkipped => hasSlot(8) ? _borderSkipped : undefined;

  set borderSkipped(Object? value) {
    _borderSkipped = value;
    touchSlot(8);
  }

  /// `inflateAmount`.
  double get inflateAmount => _inflateAmount;

  set inflateAmount(double value) {
    _inflateAmount = value;
    touchSlot(9);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _horizontal,
    1 => _base,
    2 => _enableBorderRadius,
    3 => _x,
    4 => _y,
    5 => _height,
    6 => _width,
    7 => _options,
    8 => _borderSkipped,
    _ => _inflateAmount,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _horizontal = value is bool ? value : jsTruthy(value);
        return value is bool;
      case 1:
        _base = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 2:
        _enableBorderRadius = value is bool ? value : jsTruthy(value);
        return value is bool;
      case 3:
        _x = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 4:
        _y = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 5:
        _height = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 6:
        _width = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 7:
        final object = _isOptionsObject(value);
        _options = object ? value : null;
        return object || value == null;
      case 8:
        _borderSkipped = value;
        return true;
      default:
        _inflateAmount = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
    }
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _horizontal = false;
      case 1:
        _base = double.nan;
      case 2:
        _enableBorderRadius = false;
      case 3:
        _x = double.nan;
      case 4:
        _y = double.nan;
      case 5:
        _height = double.nan;
      case 6:
        _width = double.nan;
      case 7:
        _options = null;
      case 8:
        _borderSkipped = null;
      default:
        _inflateAmount = double.nan;
    }
  }
}

/// The properties of an arc element that the doughnut, pie and polar area
/// controllers give to `updateElement` (U `controller.doughnut.js:278-289`,
/// `controller.polarArea.js:194-203`).
final class ArcProperties extends TypedRecord {
  /// An object without own keys.
  ArcProperties();

  static const List<String> _fieldNames = [
    'x',
    'y',
    'startAngle',
    'endAngle',
    'circumference',
    'outerRadius',
    'innerRadius',
    'options',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'x' => 0,
    'y' => 1,
    'startAngle' => 2,
    'endAngle' => 3,
    'circumference' => 4,
    'outerRadius' => 5,
    'innerRadius' => 6,
    'options' => 7,
    _ => -1,
  };

  double _x = double.nan;

  double _y = double.nan;

  double _startAngle = double.nan;

  double _endAngle = double.nan;

  double _circumference = double.nan;

  double _outerRadius = double.nan;

  double _innerRadius = double.nan;

  Object? _options;

  /// `x`.
  double get x => _x;

  set x(double value) {
    _x = value;
    touchSlot(0);
  }

  /// `y`.
  double get y => _y;

  set y(double value) {
    _y = value;
    touchSlot(1);
  }

  /// `startAngle`.
  double get startAngle => _startAngle;

  set startAngle(double value) {
    _startAngle = value;
    touchSlot(2);
  }

  /// `endAngle`.
  double get endAngle => _endAngle;

  set endAngle(double value) {
    _endAngle = value;
    touchSlot(3);
  }

  /// `circumference`.
  double get circumference => _circumference;

  set circumference(double value) {
    _circumference = value;
    touchSlot(4);
  }

  /// `outerRadius`.
  double get outerRadius => _outerRadius;

  set outerRadius(double value) {
    _outerRadius = value;
    touchSlot(5);
  }

  /// `innerRadius`.
  double get innerRadius => _innerRadius;

  set innerRadius(double value) {
    _innerRadius = value;
    touchSlot(6);
  }

  /// `options`.
  Object? get options => hasSlot(7) && !isForeignSlot(7) ? _options : null;

  set options(Object? value) {
    _options = value;
    touchSlot(7);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _x,
    1 => _y,
    2 => _startAngle,
    3 => _endAngle,
    4 => _circumference,
    5 => _outerRadius,
    6 => _innerRadius,
    _ => _options,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _x = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 1:
        _y = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 2:
        _startAngle = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 3:
        _endAngle = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 4:
        _circumference = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 5:
        _outerRadius = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 6:
        _innerRadius = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      default:
        final object = _isOptionsObject(value);
        _options = object ? value : null;
        return object || value == null;
    }
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _x = double.nan;
      case 1:
        _y = double.nan;
      case 2:
        _startAngle = double.nan;
      case 3:
        _endAngle = double.nan;
      case 4:
        _circumference = double.nan;
      case 5:
        _outerRadius = double.nan;
      case 6:
        _innerRadius = double.nan;
      default:
        _options = null;
    }
  }
}

/// The properties of a line element that the line, scatter and radar
/// controllers give to `updateElement` (U `controller.line.js:67-70`,
/// `controller.scatter.js:87-90`, `controller.radar.js:68-74`).
final class LineProperties extends TypedRecord {
  /// An object without own keys.
  LineProperties();

  static const List<String> _fieldNames = [
    'animated',
    'options',
    '_loop',
    '_fullLoop',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'animated' => 0,
    'options' => 1,
    '_loop' => 2,
    '_fullLoop' => 3,
    _ => -1,
  };

  bool _animated = false;

  Object? _options;

  bool _loop = false;

  bool _fullLoop = false;

  /// `animated`.
  bool get animated => _animated;

  set animated(bool value) {
    _animated = value;
    touchSlot(0);
  }

  /// `options`.
  Object? get options => hasSlot(1) && !isForeignSlot(1) ? _options : null;

  set options(Object? value) {
    _options = value;
    touchSlot(1);
  }

  /// `_loop`.
  bool get loop => _loop;

  set loop(bool value) {
    _loop = value;
    touchSlot(2);
  }

  /// `_fullLoop`.
  bool get fullLoop => _fullLoop;

  set fullLoop(bool value) {
    _fullLoop = value;
    touchSlot(3);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _animated,
    1 => _options,
    2 => _loop,
    _ => _fullLoop,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _animated = value is bool ? value : jsTruthy(value);
        return value is bool;
      case 1:
        final object = _isOptionsObject(value);
        _options = object ? value : null;
        return object || value == null;
      case 2:
        _loop = value is bool ? value : jsTruthy(value);
        return value is bool;
      default:
        _fullLoop = value is bool ? value : jsTruthy(value);
        return value is bool;
    }
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _animated = false;
      case 1:
        _options = null;
      case 2:
        _loop = false;
      default:
        _fullLoop = false;
    }
  }
}

/// The object `res` of `setBorderSkipped` (U `controller.bar.js:202-232`),
/// the `borderSkipped` of [BarProperties]: the skipped edges of a bar.
///
/// The edges `top`, `right`, `bottom` and `left` are `bool` fields (false
/// when absent). A write by name of another value keeps it in the foreign
/// slot, with its truthiness in the field. Another edge name (a user
/// `borderSkipped: 'foo'` gives `res.foo = true`) is an extra.
final class BorderSkipped extends TypedRecord {
  /// An object without own keys: the `{}` of upstream.
  BorderSkipped();

  /// `{top: true, right: true, bottom: true, left: true}` of
  /// `borderSkipped: true` (U `controller.bar.js:211-213`).
  BorderSkipped.all() {
    this
      ..top = true
      ..right = true
      ..bottom = true
      ..left = true;
  }

  static const List<String> _fieldNames = ['top', 'right', 'bottom', 'left'];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'top' => 0,
    'right' => 1,
    'bottom' => 2,
    'left' => 3,
    _ => -1,
  };

  bool _top = false;

  bool _right = false;

  bool _bottom = false;

  bool _left = false;

  /// `top`.
  bool get top => _top;

  set top(bool value) {
    _top = value;
    touchSlot(0);
  }

  /// `right`.
  bool get right => _right;

  set right(bool value) {
    _right = value;
    touchSlot(1);
  }

  /// `bottom`.
  bool get bottom => _bottom;

  set bottom(bool value) {
    _bottom = value;
    touchSlot(2);
  }

  /// `left`.
  bool get left => _left;

  set left(bool value) {
    _left = value;
    touchSlot(3);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _top,
    1 => _right,
    2 => _bottom,
    _ => _left,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    final flag = value is bool ? value : jsTruthy(value);
    switch (slot) {
      case 0:
        _top = flag;
      case 1:
        _right = flag;
      case 2:
        _bottom = flag;
      default:
        _left = flag;
    }
    return value is bool;
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _top = false;
      case 1:
        _right = false;
      case 2:
        _bottom = false;
      default:
        _left = false;
    }
  }
}
