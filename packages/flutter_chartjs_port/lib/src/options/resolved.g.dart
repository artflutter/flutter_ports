// Original code, not ported from Chart.js: generated from tool/options_schema.yaml by tool/options_gen.dart.
// Do not edit. Edit tool/options_schema.yaml and run
// `dart run melos run options:gen` (Chart.js ADR 0054 §2).

/// The resolved options of the element kinds (Chart.js ADR 0054 §9):
/// one class for each kind of `tool/options_schema.yaml` with
/// `resolved`. Each known key has a typed field (`double`, `bool`,
/// `String?` or `Object?`), a bit of `_present` and, for a value
/// outside the type of the field, a bit of `_foreign` and the raw value
/// in `_foreignRaw` (§6). The typed getter gives the JS conversion of
/// the Map read (Dart `null` for an absent key); `<key>Value` gives the
/// raw value, or `undefined` for an absent key. `ElementOptions` keeps
/// `$shared`, `$animations`, the extras, the frozen state and the
/// Map protocol.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show DrawPointOptions;
import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsToNumber, jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/element_options_base.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';

/// index.d.ts:2055 PointOptions and index.d.ts:2083 PointHoverOptions, the
/// options of a point element.
final class PointOptions extends ElementOptions implements DrawPointOptions {
  /// Options with the entries of [source], in its key order.
  PointOptions([super.source]);

  /// The copy of [source] for [clone].
  PointOptions._copy(PointOptions super.source)
    : _present = source._present,
      _foreign = source._foreign,
      _int = source._int,
      _foreignRaw = source._foreignRaw == null
          ? null
          : List<Object?>.of(source._foreignRaw!),
      _borderWidth = source._borderWidth,
      _hitRadius = source._hitRadius,
      _hoverBorderWidth = source._hoverBorderWidth,
      _hoverRadius = source._hoverRadius,
      _pointStyle = source._pointStyle,
      _radius = source._radius,
      _rotation = source._rotation,
      _backgroundColor = source._backgroundColor,
      _borderColor = source._borderColor,
      super.copyFrom();

  /// The known keys, in the key order of Chart.js ADR 0018 §3.
  static const List<String> knownKeys = [
    r'$shared',
    'borderWidth',
    'hitRadius',
    'hoverBorderWidth',
    'hoverRadius',
    'pointStyle',
    'radius',
    'rotation',
    'backgroundColor',
    'borderColor',
    r'$animations',
  ];

  @override
  List<String> get knownKeyList => knownKeys;

  /// `Object.assign({}, options)` in the same class.
  @override
  PointOptions clone() => PointOptions._copy(this);

  /// The bits of the present keys.
  int _present = 0;

  /// The bits of the foreign keys.
  int _foreign = 0;

  /// The raw values of the foreign keys, by slot.
  List<Object?>? _foreignRaw;

  /// The bits of the `double` keys whose raw value is a Dart `int`:
  /// the Map read gives the `int` back.
  int _int = 0;

  void _setForeign(int slot, int bit, Object? raw) {
    _foreign |= bit;
    (_foreignRaw ??= List<Object?>.filled(9, null))[slot] = raw;
  }

  void _clearForeign(int slot, int bit) {
    if (_foreign & bit != 0) {
      _foreign &= ~bit;
      _foreignRaw![slot] = null;
    }
  }

  double _borderWidth = 0;

  /// `borderWidth`: the JS conversion of the Map read of the key.
  double get borderWidth => _borderWidth;

  /// `borderWidth`: the raw value, or [undefined] for an absent key.
  Object? get borderWidthValue => _present & 1 == 0 ? undefined : _raw0();

  Object? _raw0() => _present & 1 == 0
      ? elementOptionAbsent
      : _foreign & 1 != 0
      ? _foreignRaw![0]
      : _int & 1 != 0
      ? _borderWidth.toInt()
      : _borderWidth;

  void _store0(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~1;
      _clearForeign(0, 1);
      _borderWidth = 0;
      return;
    }
    _present |= 1;
    if (raw is double) {
      _borderWidth = raw;
      _int &= ~1;
      _clearForeign(0, 1);
    } else if (raw is int) {
      _borderWidth = raw.toDouble();
      _int |= 1;
      _clearForeign(0, 1);
    } else {
      _borderWidth = jsToNumber(raw);
      _int &= ~1;
      _setForeign(0, 1, raw);
      assert(auditForeign('PointOptions', 'borderWidth', raw));
    }
  }

  double _hitRadius = 0;

  /// `hitRadius`: the JS conversion of the Map read of the key.
  double get hitRadius => _hitRadius;

  /// `hitRadius`: the raw value, or [undefined] for an absent key.
  Object? get hitRadiusValue => _present & 2 == 0 ? undefined : _raw1();

  Object? _raw1() => _present & 2 == 0
      ? elementOptionAbsent
      : _foreign & 2 != 0
      ? _foreignRaw![1]
      : _int & 2 != 0
      ? _hitRadius.toInt()
      : _hitRadius;

  void _store1(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~2;
      _clearForeign(1, 2);
      _hitRadius = 0;
      return;
    }
    _present |= 2;
    if (raw is double) {
      _hitRadius = raw;
      _int &= ~2;
      _clearForeign(1, 2);
    } else if (raw is int) {
      _hitRadius = raw.toDouble();
      _int |= 2;
      _clearForeign(1, 2);
    } else {
      _hitRadius = jsToNumber(raw);
      _int &= ~2;
      _setForeign(1, 2, raw);
      assert(auditForeign('PointOptions', 'hitRadius', raw));
    }
  }

  double _hoverBorderWidth = 0;

  /// `hoverBorderWidth`: the JS conversion of the Map read of the key.
  double get hoverBorderWidth => _hoverBorderWidth;

  /// `hoverBorderWidth`: the raw value, or [undefined] for an absent key.
  Object? get hoverBorderWidthValue => _present & 4 == 0 ? undefined : _raw2();

  Object? _raw2() => _present & 4 == 0
      ? elementOptionAbsent
      : _foreign & 4 != 0
      ? _foreignRaw![2]
      : _int & 4 != 0
      ? _hoverBorderWidth.toInt()
      : _hoverBorderWidth;

  void _store2(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~4;
      _clearForeign(2, 4);
      _hoverBorderWidth = 0;
      return;
    }
    _present |= 4;
    if (raw is double) {
      _hoverBorderWidth = raw;
      _int &= ~4;
      _clearForeign(2, 4);
    } else if (raw is int) {
      _hoverBorderWidth = raw.toDouble();
      _int |= 4;
      _clearForeign(2, 4);
    } else {
      _hoverBorderWidth = jsToNumber(raw);
      _int &= ~4;
      _setForeign(2, 4, raw);
      assert(auditForeign('PointOptions', 'hoverBorderWidth', raw));
    }
  }

  double _hoverRadius = 0;

  /// `hoverRadius`: the JS conversion of the Map read of the key.
  double get hoverRadius => _hoverRadius;

  /// `hoverRadius`: the raw value, or [undefined] for an absent key.
  Object? get hoverRadiusValue => _present & 8 == 0 ? undefined : _raw3();

  Object? _raw3() => _present & 8 == 0
      ? elementOptionAbsent
      : _foreign & 8 != 0
      ? _foreignRaw![3]
      : _int & 8 != 0
      ? _hoverRadius.toInt()
      : _hoverRadius;

  void _store3(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~8;
      _clearForeign(3, 8);
      _hoverRadius = 0;
      return;
    }
    _present |= 8;
    if (raw is double) {
      _hoverRadius = raw;
      _int &= ~8;
      _clearForeign(3, 8);
    } else if (raw is int) {
      _hoverRadius = raw.toDouble();
      _int |= 8;
      _clearForeign(3, 8);
    } else {
      _hoverRadius = jsToNumber(raw);
      _int &= ~8;
      _setForeign(3, 8, raw);
      assert(auditForeign('PointOptions', 'hoverRadius', raw));
    }
  }

  Object? _pointStyle = null;

  /// `pointStyle`: the JS conversion of the Map read of the key.
  Object? get pointStyle => _pointStyle;

  /// `pointStyle`: the raw value, or [undefined] for an absent key.
  Object? get pointStyleValue => _present & 16 == 0 ? undefined : _raw4();

  Object? _raw4() => _present & 16 == 0
      ? elementOptionAbsent
      : _foreign & 16 != 0
      ? _foreignRaw![4]
      : _pointStyle;

  void _store4(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~16;
      _clearForeign(4, 16);
      _pointStyle = null;
      return;
    }
    _present |= 16;
    _pointStyle = raw;
  }

  double _radius = 0;

  /// `radius`: the JS conversion of the Map read of the key.
  double get radius => _radius;

  /// `radius`: the raw value, or [undefined] for an absent key.
  Object? get radiusValue => _present & 32 == 0 ? undefined : _raw5();

  Object? _raw5() => _present & 32 == 0
      ? elementOptionAbsent
      : _foreign & 32 != 0
      ? _foreignRaw![5]
      : _int & 32 != 0
      ? _radius.toInt()
      : _radius;

  void _store5(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~32;
      _clearForeign(5, 32);
      _radius = 0;
      return;
    }
    _present |= 32;
    if (raw is double) {
      _radius = raw;
      _int &= ~32;
      _clearForeign(5, 32);
    } else if (raw is int) {
      _radius = raw.toDouble();
      _int |= 32;
      _clearForeign(5, 32);
    } else {
      _radius = jsToNumber(raw);
      _int &= ~32;
      _setForeign(5, 32, raw);
      assert(auditForeign('PointOptions', 'radius', raw));
    }
  }

  double _rotation = 0;

  /// `rotation`: the JS conversion of the Map read of the key.
  double get rotation => _rotation;

  /// `rotation`: the raw value, or [undefined] for an absent key.
  Object? get rotationValue => _present & 64 == 0 ? undefined : _raw6();

  Object? _raw6() => _present & 64 == 0
      ? elementOptionAbsent
      : _foreign & 64 != 0
      ? _foreignRaw![6]
      : _int & 64 != 0
      ? _rotation.toInt()
      : _rotation;

  void _store6(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~64;
      _clearForeign(6, 64);
      _rotation = 0;
      return;
    }
    _present |= 64;
    if (raw is double) {
      _rotation = raw;
      _int &= ~64;
      _clearForeign(6, 64);
    } else if (raw is int) {
      _rotation = raw.toDouble();
      _int |= 64;
      _clearForeign(6, 64);
    } else {
      _rotation = jsToNumber(raw);
      _int &= ~64;
      _setForeign(6, 64, raw);
      assert(auditForeign('PointOptions', 'rotation', raw));
    }
  }

  Object? _backgroundColor = null;

  /// `backgroundColor`: the JS conversion of the Map read of the key.
  Object? get backgroundColor => _backgroundColor;

  /// `backgroundColor`: the raw value, or [undefined] for an absent key.
  Object? get backgroundColorValue => _present & 128 == 0 ? undefined : _raw7();

  Object? _raw7() => _present & 128 == 0
      ? elementOptionAbsent
      : _foreign & 128 != 0
      ? _foreignRaw![7]
      : _backgroundColor;

  void _store7(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~128;
      _clearForeign(7, 128);
      _backgroundColor = null;
      return;
    }
    _present |= 128;
    _backgroundColor = raw;
  }

  Object? _borderColor = null;

  /// `borderColor`: the JS conversion of the Map read of the key.
  Object? get borderColor => _borderColor;

  /// `borderColor`: the raw value, or [undefined] for an absent key.
  Object? get borderColorValue => _present & 256 == 0 ? undefined : _raw8();

  Object? _raw8() => _present & 256 == 0
      ? elementOptionAbsent
      : _foreign & 256 != 0
      ? _foreignRaw![8]
      : _borderColor;

  void _store8(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~256;
      _clearForeign(8, 256);
      _borderColor = null;
      return;
    }
    _present |= 256;
    _borderColor = raw;
  }

  @override
  Object? rawOf(String key) => switch (key) {
    'borderWidth' => _raw0(),
    'hitRadius' => _raw1(),
    'hoverBorderWidth' => _raw2(),
    'hoverRadius' => _raw3(),
    'pointStyle' => _raw4(),
    'radius' => _raw5(),
    'rotation' => _raw6(),
    'backgroundColor' => _raw7(),
    'borderColor' => _raw8(),
    _ => super.rawOf(key),
  };

  @override
  bool storeRaw(String key, Object? raw) {
    switch (key) {
      case 'borderWidth':
        _store0(raw);
      case 'hitRadius':
        _store1(raw);
      case 'hoverBorderWidth':
        _store2(raw);
      case 'hoverRadius':
        _store3(raw);
      case 'pointStyle':
        _store4(raw);
      case 'radius':
        _store5(raw);
      case 'rotation':
        _store6(raw);
      case 'backgroundColor':
        _store7(raw);
      case 'borderColor':
        _store8(raw);
      default:
        return super.storeRaw(key, raw);
    }
    return true;
  }

  @override
  void storeKey(Object key, Object? raw) {
    if (key is OptionKey && !isFrozen) {
      switch (key) {
        case OptionKey.borderWidth:
          _store0(raw);
          return;
        case OptionKey.hitRadius:
          _store1(raw);
          return;
        case OptionKey.hoverBorderWidth:
          _store2(raw);
          return;
        case OptionKey.hoverRadius:
          _store3(raw);
          return;
        case OptionKey.pointStyle:
          _store4(raw);
          return;
        case OptionKey.radius:
          _store5(raw);
          return;
        case OptionKey.rotation:
          _store6(raw);
          return;
        case OptionKey.backgroundColor:
          _store7(raw);
          return;
        case OptionKey.borderColor:
          _store8(raw);
          return;
        default:
      }
    }
    super.storeKey(key, raw);
  }

  @override
  Object? valueOf(OptionKey key) => switch (key) {
    OptionKey.borderWidth => borderWidthValue,
    OptionKey.hitRadius => hitRadiusValue,
    OptionKey.hoverBorderWidth => hoverBorderWidthValue,
    OptionKey.hoverRadius => hoverRadiusValue,
    OptionKey.pointStyle => pointStyleValue,
    OptionKey.radius => radiusValue,
    OptionKey.rotation => rotationValue,
    OptionKey.backgroundColor => backgroundColorValue,
    OptionKey.borderColor => borderColorValue,
    _ => super.valueOf(key),
  };

  @override
  bool isPresent(OptionKey key) => switch (key) {
    OptionKey.borderWidth => _present & 1 != 0,
    OptionKey.hitRadius => _present & 2 != 0,
    OptionKey.hoverBorderWidth => _present & 4 != 0,
    OptionKey.hoverRadius => _present & 8 != 0,
    OptionKey.pointStyle => _present & 16 != 0,
    OptionKey.radius => _present & 32 != 0,
    OptionKey.rotation => _present & 64 != 0,
    OptionKey.backgroundColor => _present & 128 != 0,
    OptionKey.borderColor => _present & 256 != 0,
    _ => super.isPresent(key),
  };

  @override
  bool isForeign(OptionKey key) => switch (key) {
    OptionKey.borderWidth => _foreign & 1 != 0,
    OptionKey.hitRadius => _foreign & 2 != 0,
    OptionKey.hoverBorderWidth => _foreign & 4 != 0,
    OptionKey.hoverRadius => _foreign & 8 != 0,
    OptionKey.pointStyle => _foreign & 16 != 0,
    OptionKey.radius => _foreign & 32 != 0,
    OptionKey.rotation => _foreign & 64 != 0,
    OptionKey.backgroundColor => _foreign & 128 != 0,
    OptionKey.borderColor => _foreign & 256 != 0,
    _ => false,
  };

  @override
  Object? foreignOf(OptionKey key) => switch (key) {
    OptionKey.borderWidth => _foreign & 1 != 0 ? _foreignRaw![0] : null,
    OptionKey.hitRadius => _foreign & 2 != 0 ? _foreignRaw![1] : null,
    OptionKey.hoverBorderWidth => _foreign & 4 != 0 ? _foreignRaw![2] : null,
    OptionKey.hoverRadius => _foreign & 8 != 0 ? _foreignRaw![3] : null,
    OptionKey.pointStyle => _foreign & 16 != 0 ? _foreignRaw![4] : null,
    OptionKey.radius => _foreign & 32 != 0 ? _foreignRaw![5] : null,
    OptionKey.rotation => _foreign & 64 != 0 ? _foreignRaw![6] : null,
    OptionKey.backgroundColor => _foreign & 128 != 0 ? _foreignRaw![7] : null,
    OptionKey.borderColor => _foreign & 256 != 0 ? _foreignRaw![8] : null,
    _ => null,
  };
}

/// index.d.ts:1954 LineOptions and index.d.ts:2015 LineHoverOptions, the
/// options of a line element.
final class LineOptions extends ElementOptions {
  /// Options with the entries of [source], in its key order.
  LineOptions([super.source]);

  /// The copy of [source] for [clone].
  LineOptions._copy(LineOptions super.source)
    : _present = source._present,
      _foreign = source._foreign,
      _int = source._int,
      _foreignRaw = source._foreignRaw == null
          ? null
          : List<Object?>.of(source._foreignRaw!),
      _borderCapStyle = source._borderCapStyle,
      _borderDash = source._borderDash,
      _borderDashOffset = source._borderDashOffset,
      _borderJoinStyle = source._borderJoinStyle,
      _borderWidth = source._borderWidth,
      _capBezierPoints = source._capBezierPoints,
      _cubicInterpolationMode = source._cubicInterpolationMode,
      _fill = source._fill,
      _spanGaps = source._spanGaps,
      _stepped = source._stepped,
      _tension = source._tension,
      _backgroundColor = source._backgroundColor,
      _borderColor = source._borderColor,
      _segment = source._segment,
      super.copyFrom();

  /// The known keys, in the key order of Chart.js ADR 0018 §3.
  static const List<String> knownKeys = [
    r'$shared',
    'borderCapStyle',
    'borderDash',
    'borderDashOffset',
    'borderJoinStyle',
    'borderWidth',
    'capBezierPoints',
    'cubicInterpolationMode',
    'fill',
    'spanGaps',
    'stepped',
    'tension',
    'backgroundColor',
    'borderColor',
    'segment',
    r'$animations',
  ];

  @override
  List<String> get knownKeyList => knownKeys;

  /// `Object.assign({}, options)` in the same class.
  @override
  LineOptions clone() => LineOptions._copy(this);

  /// The bits of the present keys.
  int _present = 0;

  /// The bits of the foreign keys.
  int _foreign = 0;

  /// The raw values of the foreign keys, by slot.
  List<Object?>? _foreignRaw;

  /// The bits of the `double` keys whose raw value is a Dart `int`:
  /// the Map read gives the `int` back.
  int _int = 0;

  void _setForeign(int slot, int bit, Object? raw) {
    _foreign |= bit;
    (_foreignRaw ??= List<Object?>.filled(14, null))[slot] = raw;
  }

  void _clearForeign(int slot, int bit) {
    if (_foreign & bit != 0) {
      _foreign &= ~bit;
      _foreignRaw![slot] = null;
    }
  }

  String? _borderCapStyle = null;

  /// `borderCapStyle`: the JS conversion of the Map read of the key.
  String? get borderCapStyle => _borderCapStyle;

  /// `borderCapStyle`: the raw value, or [undefined] for an absent key.
  Object? get borderCapStyleValue => _present & 1 == 0 ? undefined : _raw0();

  Object? _raw0() => _present & 1 == 0
      ? elementOptionAbsent
      : _foreign & 1 != 0
      ? _foreignRaw![0]
      : _borderCapStyle;

  void _store0(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~1;
      _clearForeign(0, 1);
      _borderCapStyle = null;
      return;
    }
    _present |= 1;
    if (raw is String) {
      _borderCapStyle = raw;
      _clearForeign(0, 1);
    } else {
      _borderCapStyle = null;
      _setForeign(0, 1, raw);
      assert(auditForeign('LineOptions', 'borderCapStyle', raw));
    }
  }

  Object? _borderDash = null;

  /// `borderDash`: the JS conversion of the Map read of the key.
  Object? get borderDash => _borderDash;

  /// `borderDash`: the raw value, or [undefined] for an absent key.
  Object? get borderDashValue => _present & 2 == 0 ? undefined : _raw1();

  Object? _raw1() => _present & 2 == 0
      ? elementOptionAbsent
      : _foreign & 2 != 0
      ? _foreignRaw![1]
      : _borderDash;

  void _store1(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~2;
      _clearForeign(1, 2);
      _borderDash = null;
      return;
    }
    _present |= 2;
    _borderDash = raw;
  }

  double _borderDashOffset = 0;

  /// `borderDashOffset`: the JS conversion of the Map read of the key.
  double get borderDashOffset => _borderDashOffset;

  /// `borderDashOffset`: the raw value, or [undefined] for an absent key.
  Object? get borderDashOffsetValue => _present & 4 == 0 ? undefined : _raw2();

  Object? _raw2() => _present & 4 == 0
      ? elementOptionAbsent
      : _foreign & 4 != 0
      ? _foreignRaw![2]
      : _int & 4 != 0
      ? _borderDashOffset.toInt()
      : _borderDashOffset;

  void _store2(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~4;
      _clearForeign(2, 4);
      _borderDashOffset = 0;
      return;
    }
    _present |= 4;
    if (raw is double) {
      _borderDashOffset = raw;
      _int &= ~4;
      _clearForeign(2, 4);
    } else if (raw is int) {
      _borderDashOffset = raw.toDouble();
      _int |= 4;
      _clearForeign(2, 4);
    } else {
      _borderDashOffset = jsToNumber(raw);
      _int &= ~4;
      _setForeign(2, 4, raw);
      assert(auditForeign('LineOptions', 'borderDashOffset', raw));
    }
  }

  String? _borderJoinStyle = null;

  /// `borderJoinStyle`: the JS conversion of the Map read of the key.
  String? get borderJoinStyle => _borderJoinStyle;

  /// `borderJoinStyle`: the raw value, or [undefined] for an absent key.
  Object? get borderJoinStyleValue => _present & 8 == 0 ? undefined : _raw3();

  Object? _raw3() => _present & 8 == 0
      ? elementOptionAbsent
      : _foreign & 8 != 0
      ? _foreignRaw![3]
      : _borderJoinStyle;

  void _store3(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~8;
      _clearForeign(3, 8);
      _borderJoinStyle = null;
      return;
    }
    _present |= 8;
    if (raw is String) {
      _borderJoinStyle = raw;
      _clearForeign(3, 8);
    } else {
      _borderJoinStyle = null;
      _setForeign(3, 8, raw);
      assert(auditForeign('LineOptions', 'borderJoinStyle', raw));
    }
  }

  double _borderWidth = 0;

  /// `borderWidth`: the JS conversion of the Map read of the key.
  double get borderWidth => _borderWidth;

  /// `borderWidth`: the raw value, or [undefined] for an absent key.
  Object? get borderWidthValue => _present & 16 == 0 ? undefined : _raw4();

  Object? _raw4() => _present & 16 == 0
      ? elementOptionAbsent
      : _foreign & 16 != 0
      ? _foreignRaw![4]
      : _int & 16 != 0
      ? _borderWidth.toInt()
      : _borderWidth;

  void _store4(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~16;
      _clearForeign(4, 16);
      _borderWidth = 0;
      return;
    }
    _present |= 16;
    if (raw is double) {
      _borderWidth = raw;
      _int &= ~16;
      _clearForeign(4, 16);
    } else if (raw is int) {
      _borderWidth = raw.toDouble();
      _int |= 16;
      _clearForeign(4, 16);
    } else {
      _borderWidth = jsToNumber(raw);
      _int &= ~16;
      _setForeign(4, 16, raw);
      assert(auditForeign('LineOptions', 'borderWidth', raw));
    }
  }

  bool _capBezierPoints = false;

  /// `capBezierPoints`: the JS conversion of the Map read of the key.
  bool get capBezierPoints => _capBezierPoints;

  /// `capBezierPoints`: the raw value, or [undefined] for an absent key.
  Object? get capBezierPointsValue => _present & 32 == 0 ? undefined : _raw5();

  Object? _raw5() => _present & 32 == 0
      ? elementOptionAbsent
      : _foreign & 32 != 0
      ? _foreignRaw![5]
      : _capBezierPoints;

  void _store5(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~32;
      _clearForeign(5, 32);
      _capBezierPoints = false;
      return;
    }
    _present |= 32;
    if (raw is bool) {
      _capBezierPoints = raw;
      _clearForeign(5, 32);
    } else {
      _capBezierPoints = jsTruthy(raw);
      _setForeign(5, 32, raw);
      assert(auditForeign('LineOptions', 'capBezierPoints', raw));
    }
  }

  String? _cubicInterpolationMode = null;

  /// `cubicInterpolationMode`: the JS conversion of the Map read of the key.
  String? get cubicInterpolationMode => _cubicInterpolationMode;

  /// `cubicInterpolationMode`: the raw value, or [undefined] for an absent key.
  Object? get cubicInterpolationModeValue =>
      _present & 64 == 0 ? undefined : _raw6();

  Object? _raw6() => _present & 64 == 0
      ? elementOptionAbsent
      : _foreign & 64 != 0
      ? _foreignRaw![6]
      : _cubicInterpolationMode;

  void _store6(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~64;
      _clearForeign(6, 64);
      _cubicInterpolationMode = null;
      return;
    }
    _present |= 64;
    if (raw is String) {
      _cubicInterpolationMode = raw;
      _clearForeign(6, 64);
    } else {
      _cubicInterpolationMode = null;
      _setForeign(6, 64, raw);
      assert(auditForeign('LineOptions', 'cubicInterpolationMode', raw));
    }
  }

  Object? _fill = null;

  /// `fill`: the JS conversion of the Map read of the key.
  Object? get fill => _fill;

  /// `fill`: the raw value, or [undefined] for an absent key.
  Object? get fillValue => _present & 128 == 0 ? undefined : _raw7();

  Object? _raw7() => _present & 128 == 0
      ? elementOptionAbsent
      : _foreign & 128 != 0
      ? _foreignRaw![7]
      : _fill;

  void _store7(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~128;
      _clearForeign(7, 128);
      _fill = null;
      return;
    }
    _present |= 128;
    _fill = raw;
  }

  Object? _spanGaps = null;

  /// `spanGaps`: the JS conversion of the Map read of the key.
  Object? get spanGaps => _spanGaps;

  /// `spanGaps`: the raw value, or [undefined] for an absent key.
  Object? get spanGapsValue => _present & 256 == 0 ? undefined : _raw8();

  Object? _raw8() => _present & 256 == 0
      ? elementOptionAbsent
      : _foreign & 256 != 0
      ? _foreignRaw![8]
      : _spanGaps;

  void _store8(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~256;
      _clearForeign(8, 256);
      _spanGaps = null;
      return;
    }
    _present |= 256;
    _spanGaps = raw;
  }

  Object? _stepped = null;

  /// `stepped`: the JS conversion of the Map read of the key.
  Object? get stepped => _stepped;

  /// `stepped`: the raw value, or [undefined] for an absent key.
  Object? get steppedValue => _present & 512 == 0 ? undefined : _raw9();

  Object? _raw9() => _present & 512 == 0
      ? elementOptionAbsent
      : _foreign & 512 != 0
      ? _foreignRaw![9]
      : _stepped;

  void _store9(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~512;
      _clearForeign(9, 512);
      _stepped = null;
      return;
    }
    _present |= 512;
    _stepped = raw;
  }

  double _tension = 0;

  /// `tension`: the JS conversion of the Map read of the key.
  double get tension => _tension;

  /// `tension`: the raw value, or [undefined] for an absent key.
  Object? get tensionValue => _present & 1024 == 0 ? undefined : _raw10();

  Object? _raw10() => _present & 1024 == 0
      ? elementOptionAbsent
      : _foreign & 1024 != 0
      ? _foreignRaw![10]
      : _int & 1024 != 0
      ? _tension.toInt()
      : _tension;

  void _store10(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~1024;
      _clearForeign(10, 1024);
      _tension = 0;
      return;
    }
    _present |= 1024;
    if (raw is double) {
      _tension = raw;
      _int &= ~1024;
      _clearForeign(10, 1024);
    } else if (raw is int) {
      _tension = raw.toDouble();
      _int |= 1024;
      _clearForeign(10, 1024);
    } else {
      _tension = jsToNumber(raw);
      _int &= ~1024;
      _setForeign(10, 1024, raw);
      assert(auditForeign('LineOptions', 'tension', raw));
    }
  }

  Object? _backgroundColor = null;

  /// `backgroundColor`: the JS conversion of the Map read of the key.
  Object? get backgroundColor => _backgroundColor;

  /// `backgroundColor`: the raw value, or [undefined] for an absent key.
  Object? get backgroundColorValue =>
      _present & 2048 == 0 ? undefined : _raw11();

  Object? _raw11() => _present & 2048 == 0
      ? elementOptionAbsent
      : _foreign & 2048 != 0
      ? _foreignRaw![11]
      : _backgroundColor;

  void _store11(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~2048;
      _clearForeign(11, 2048);
      _backgroundColor = null;
      return;
    }
    _present |= 2048;
    _backgroundColor = raw;
  }

  Object? _borderColor = null;

  /// `borderColor`: the JS conversion of the Map read of the key.
  Object? get borderColor => _borderColor;

  /// `borderColor`: the raw value, or [undefined] for an absent key.
  Object? get borderColorValue => _present & 4096 == 0 ? undefined : _raw12();

  Object? _raw12() => _present & 4096 == 0
      ? elementOptionAbsent
      : _foreign & 4096 != 0
      ? _foreignRaw![12]
      : _borderColor;

  void _store12(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~4096;
      _clearForeign(12, 4096);
      _borderColor = null;
      return;
    }
    _present |= 4096;
    _borderColor = raw;
  }

  Object? _segment = null;

  /// `segment`: the JS conversion of the Map read of the key.
  Object? get segment => _segment;

  /// `segment`: the raw value, or [undefined] for an absent key.
  Object? get segmentValue => _present & 8192 == 0 ? undefined : _raw13();

  Object? _raw13() => _present & 8192 == 0
      ? elementOptionAbsent
      : _foreign & 8192 != 0
      ? _foreignRaw![13]
      : _segment;

  void _store13(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~8192;
      _clearForeign(13, 8192);
      _segment = null;
      return;
    }
    _present |= 8192;
    _segment = raw;
  }

  @override
  Object? rawOf(String key) => switch (key) {
    'borderCapStyle' => _raw0(),
    'borderDash' => _raw1(),
    'borderDashOffset' => _raw2(),
    'borderJoinStyle' => _raw3(),
    'borderWidth' => _raw4(),
    'capBezierPoints' => _raw5(),
    'cubicInterpolationMode' => _raw6(),
    'fill' => _raw7(),
    'spanGaps' => _raw8(),
    'stepped' => _raw9(),
    'tension' => _raw10(),
    'backgroundColor' => _raw11(),
    'borderColor' => _raw12(),
    'segment' => _raw13(),
    _ => super.rawOf(key),
  };

  @override
  bool storeRaw(String key, Object? raw) {
    switch (key) {
      case 'borderCapStyle':
        _store0(raw);
      case 'borderDash':
        _store1(raw);
      case 'borderDashOffset':
        _store2(raw);
      case 'borderJoinStyle':
        _store3(raw);
      case 'borderWidth':
        _store4(raw);
      case 'capBezierPoints':
        _store5(raw);
      case 'cubicInterpolationMode':
        _store6(raw);
      case 'fill':
        _store7(raw);
      case 'spanGaps':
        _store8(raw);
      case 'stepped':
        _store9(raw);
      case 'tension':
        _store10(raw);
      case 'backgroundColor':
        _store11(raw);
      case 'borderColor':
        _store12(raw);
      case 'segment':
        _store13(raw);
      default:
        return super.storeRaw(key, raw);
    }
    return true;
  }

  @override
  void storeKey(Object key, Object? raw) {
    if (key is OptionKey && !isFrozen) {
      switch (key) {
        case OptionKey.borderCapStyle:
          _store0(raw);
          return;
        case OptionKey.borderDash:
          _store1(raw);
          return;
        case OptionKey.borderDashOffset:
          _store2(raw);
          return;
        case OptionKey.borderJoinStyle:
          _store3(raw);
          return;
        case OptionKey.borderWidth:
          _store4(raw);
          return;
        case OptionKey.capBezierPoints:
          _store5(raw);
          return;
        case OptionKey.cubicInterpolationMode:
          _store6(raw);
          return;
        case OptionKey.fill:
          _store7(raw);
          return;
        case OptionKey.spanGaps:
          _store8(raw);
          return;
        case OptionKey.stepped:
          _store9(raw);
          return;
        case OptionKey.tension:
          _store10(raw);
          return;
        case OptionKey.backgroundColor:
          _store11(raw);
          return;
        case OptionKey.borderColor:
          _store12(raw);
          return;
        case OptionKey.segment:
          _store13(raw);
          return;
        default:
      }
    }
    super.storeKey(key, raw);
  }

  @override
  Object? valueOf(OptionKey key) => switch (key) {
    OptionKey.borderCapStyle => borderCapStyleValue,
    OptionKey.borderDash => borderDashValue,
    OptionKey.borderDashOffset => borderDashOffsetValue,
    OptionKey.borderJoinStyle => borderJoinStyleValue,
    OptionKey.borderWidth => borderWidthValue,
    OptionKey.capBezierPoints => capBezierPointsValue,
    OptionKey.cubicInterpolationMode => cubicInterpolationModeValue,
    OptionKey.fill => fillValue,
    OptionKey.spanGaps => spanGapsValue,
    OptionKey.stepped => steppedValue,
    OptionKey.tension => tensionValue,
    OptionKey.backgroundColor => backgroundColorValue,
    OptionKey.borderColor => borderColorValue,
    OptionKey.segment => segmentValue,
    _ => super.valueOf(key),
  };

  @override
  bool isPresent(OptionKey key) => switch (key) {
    OptionKey.borderCapStyle => _present & 1 != 0,
    OptionKey.borderDash => _present & 2 != 0,
    OptionKey.borderDashOffset => _present & 4 != 0,
    OptionKey.borderJoinStyle => _present & 8 != 0,
    OptionKey.borderWidth => _present & 16 != 0,
    OptionKey.capBezierPoints => _present & 32 != 0,
    OptionKey.cubicInterpolationMode => _present & 64 != 0,
    OptionKey.fill => _present & 128 != 0,
    OptionKey.spanGaps => _present & 256 != 0,
    OptionKey.stepped => _present & 512 != 0,
    OptionKey.tension => _present & 1024 != 0,
    OptionKey.backgroundColor => _present & 2048 != 0,
    OptionKey.borderColor => _present & 4096 != 0,
    OptionKey.segment => _present & 8192 != 0,
    _ => super.isPresent(key),
  };

  @override
  bool isForeign(OptionKey key) => switch (key) {
    OptionKey.borderCapStyle => _foreign & 1 != 0,
    OptionKey.borderDash => _foreign & 2 != 0,
    OptionKey.borderDashOffset => _foreign & 4 != 0,
    OptionKey.borderJoinStyle => _foreign & 8 != 0,
    OptionKey.borderWidth => _foreign & 16 != 0,
    OptionKey.capBezierPoints => _foreign & 32 != 0,
    OptionKey.cubicInterpolationMode => _foreign & 64 != 0,
    OptionKey.fill => _foreign & 128 != 0,
    OptionKey.spanGaps => _foreign & 256 != 0,
    OptionKey.stepped => _foreign & 512 != 0,
    OptionKey.tension => _foreign & 1024 != 0,
    OptionKey.backgroundColor => _foreign & 2048 != 0,
    OptionKey.borderColor => _foreign & 4096 != 0,
    OptionKey.segment => _foreign & 8192 != 0,
    _ => false,
  };

  @override
  Object? foreignOf(OptionKey key) => switch (key) {
    OptionKey.borderCapStyle => _foreign & 1 != 0 ? _foreignRaw![0] : null,
    OptionKey.borderDash => _foreign & 2 != 0 ? _foreignRaw![1] : null,
    OptionKey.borderDashOffset => _foreign & 4 != 0 ? _foreignRaw![2] : null,
    OptionKey.borderJoinStyle => _foreign & 8 != 0 ? _foreignRaw![3] : null,
    OptionKey.borderWidth => _foreign & 16 != 0 ? _foreignRaw![4] : null,
    OptionKey.capBezierPoints => _foreign & 32 != 0 ? _foreignRaw![5] : null,
    OptionKey.cubicInterpolationMode =>
      _foreign & 64 != 0 ? _foreignRaw![6] : null,
    OptionKey.fill => _foreign & 128 != 0 ? _foreignRaw![7] : null,
    OptionKey.spanGaps => _foreign & 256 != 0 ? _foreignRaw![8] : null,
    OptionKey.stepped => _foreign & 512 != 0 ? _foreignRaw![9] : null,
    OptionKey.tension => _foreign & 1024 != 0 ? _foreignRaw![10] : null,
    OptionKey.backgroundColor => _foreign & 2048 != 0 ? _foreignRaw![11] : null,
    OptionKey.borderColor => _foreign & 4096 != 0 ? _foreignRaw![12] : null,
    OptionKey.segment => _foreign & 8192 != 0 ? _foreignRaw![13] : null,
    _ => null,
  };
}

/// index.d.ts:2148 BarOptions and index.d.ts:2187 BarHoverOptions, the options
/// of a bar element.
final class BarOptions extends ElementOptions {
  /// Options with the entries of [source], in its key order.
  BarOptions([super.source]);

  /// The copy of [source] for [clone].
  BarOptions._copy(BarOptions super.source)
    : _present = source._present,
      _foreign = source._foreign,
      _int = source._int,
      _foreignRaw = source._foreignRaw == null
          ? null
          : List<Object?>.of(source._foreignRaw!),
      _borderSkipped = source._borderSkipped,
      _borderWidth = source._borderWidth,
      _borderRadius = source._borderRadius,
      _inflateAmount = source._inflateAmount,
      _pointStyle = source._pointStyle,
      _backgroundColor = source._backgroundColor,
      _borderColor = source._borderColor,
      super.copyFrom();

  /// The known keys, in the key order of Chart.js ADR 0018 §3.
  static const List<String> knownKeys = [
    r'$shared',
    'borderSkipped',
    'borderWidth',
    'borderRadius',
    'inflateAmount',
    'pointStyle',
    'backgroundColor',
    'borderColor',
    r'$animations',
  ];

  @override
  List<String> get knownKeyList => knownKeys;

  /// `Object.assign({}, options)` in the same class.
  @override
  BarOptions clone() => BarOptions._copy(this);

  /// The bits of the present keys.
  int _present = 0;

  /// The bits of the foreign keys.
  int _foreign = 0;

  /// The raw values of the foreign keys, by slot.
  List<Object?>? _foreignRaw;

  /// The bits of the `double` keys whose raw value is a Dart `int`:
  /// the Map read gives the `int` back.
  int _int = 0;

  void _setForeign(int slot, int bit, Object? raw) {
    _foreign |= bit;
    (_foreignRaw ??= List<Object?>.filled(7, null))[slot] = raw;
  }

  void _clearForeign(int slot, int bit) {
    if (_foreign & bit != 0) {
      _foreign &= ~bit;
      _foreignRaw![slot] = null;
    }
  }

  Object? _borderSkipped = null;

  /// `borderSkipped`: the JS conversion of the Map read of the key.
  Object? get borderSkipped => _borderSkipped;

  /// `borderSkipped`: the raw value, or [undefined] for an absent key.
  Object? get borderSkippedValue => _present & 1 == 0 ? undefined : _raw0();

  Object? _raw0() => _present & 1 == 0
      ? elementOptionAbsent
      : _foreign & 1 != 0
      ? _foreignRaw![0]
      : _borderSkipped;

  void _store0(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~1;
      _clearForeign(0, 1);
      _borderSkipped = null;
      return;
    }
    _present |= 1;
    _borderSkipped = raw;
  }

  Object? _borderWidth = null;

  /// `borderWidth`: the JS conversion of the Map read of the key.
  Object? get borderWidth => _borderWidth;

  /// `borderWidth`: the raw value, or [undefined] for an absent key.
  Object? get borderWidthValue => _present & 2 == 0 ? undefined : _raw1();

  Object? _raw1() => _present & 2 == 0
      ? elementOptionAbsent
      : _foreign & 2 != 0
      ? _foreignRaw![1]
      : _borderWidth;

  void _store1(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~2;
      _clearForeign(1, 2);
      _borderWidth = null;
      return;
    }
    _present |= 2;
    _borderWidth = raw;
  }

  Object? _borderRadius = null;

  /// `borderRadius`: the JS conversion of the Map read of the key.
  Object? get borderRadius => _borderRadius;

  /// `borderRadius`: the raw value, or [undefined] for an absent key.
  Object? get borderRadiusValue => _present & 4 == 0 ? undefined : _raw2();

  Object? _raw2() => _present & 4 == 0
      ? elementOptionAbsent
      : _foreign & 4 != 0
      ? _foreignRaw![2]
      : _borderRadius;

  void _store2(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~4;
      _clearForeign(2, 4);
      _borderRadius = null;
      return;
    }
    _present |= 4;
    _borderRadius = raw;
  }

  Object? _inflateAmount = null;

  /// `inflateAmount`: the JS conversion of the Map read of the key.
  Object? get inflateAmount => _inflateAmount;

  /// `inflateAmount`: the raw value, or [undefined] for an absent key.
  Object? get inflateAmountValue => _present & 8 == 0 ? undefined : _raw3();

  Object? _raw3() => _present & 8 == 0
      ? elementOptionAbsent
      : _foreign & 8 != 0
      ? _foreignRaw![3]
      : _inflateAmount;

  void _store3(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~8;
      _clearForeign(3, 8);
      _inflateAmount = null;
      return;
    }
    _present |= 8;
    _inflateAmount = raw;
  }

  Object? _pointStyle = null;

  /// `pointStyle`: the JS conversion of the Map read of the key.
  Object? get pointStyle => _pointStyle;

  /// `pointStyle`: the raw value, or [undefined] for an absent key.
  Object? get pointStyleValue => _present & 16 == 0 ? undefined : _raw4();

  Object? _raw4() => _present & 16 == 0
      ? elementOptionAbsent
      : _foreign & 16 != 0
      ? _foreignRaw![4]
      : _pointStyle;

  void _store4(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~16;
      _clearForeign(4, 16);
      _pointStyle = null;
      return;
    }
    _present |= 16;
    _pointStyle = raw;
  }

  Object? _backgroundColor = null;

  /// `backgroundColor`: the JS conversion of the Map read of the key.
  Object? get backgroundColor => _backgroundColor;

  /// `backgroundColor`: the raw value, or [undefined] for an absent key.
  Object? get backgroundColorValue => _present & 32 == 0 ? undefined : _raw5();

  Object? _raw5() => _present & 32 == 0
      ? elementOptionAbsent
      : _foreign & 32 != 0
      ? _foreignRaw![5]
      : _backgroundColor;

  void _store5(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~32;
      _clearForeign(5, 32);
      _backgroundColor = null;
      return;
    }
    _present |= 32;
    _backgroundColor = raw;
  }

  Object? _borderColor = null;

  /// `borderColor`: the JS conversion of the Map read of the key.
  Object? get borderColor => _borderColor;

  /// `borderColor`: the raw value, or [undefined] for an absent key.
  Object? get borderColorValue => _present & 64 == 0 ? undefined : _raw6();

  Object? _raw6() => _present & 64 == 0
      ? elementOptionAbsent
      : _foreign & 64 != 0
      ? _foreignRaw![6]
      : _borderColor;

  void _store6(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~64;
      _clearForeign(6, 64);
      _borderColor = null;
      return;
    }
    _present |= 64;
    _borderColor = raw;
  }

  @override
  Object? rawOf(String key) => switch (key) {
    'borderSkipped' => _raw0(),
    'borderWidth' => _raw1(),
    'borderRadius' => _raw2(),
    'inflateAmount' => _raw3(),
    'pointStyle' => _raw4(),
    'backgroundColor' => _raw5(),
    'borderColor' => _raw6(),
    _ => super.rawOf(key),
  };

  @override
  bool storeRaw(String key, Object? raw) {
    switch (key) {
      case 'borderSkipped':
        _store0(raw);
      case 'borderWidth':
        _store1(raw);
      case 'borderRadius':
        _store2(raw);
      case 'inflateAmount':
        _store3(raw);
      case 'pointStyle':
        _store4(raw);
      case 'backgroundColor':
        _store5(raw);
      case 'borderColor':
        _store6(raw);
      default:
        return super.storeRaw(key, raw);
    }
    return true;
  }

  @override
  void storeKey(Object key, Object? raw) {
    if (key is OptionKey && !isFrozen) {
      switch (key) {
        case OptionKey.borderSkipped:
          _store0(raw);
          return;
        case OptionKey.borderWidth:
          _store1(raw);
          return;
        case OptionKey.borderRadius:
          _store2(raw);
          return;
        case OptionKey.inflateAmount:
          _store3(raw);
          return;
        case OptionKey.pointStyle:
          _store4(raw);
          return;
        case OptionKey.backgroundColor:
          _store5(raw);
          return;
        case OptionKey.borderColor:
          _store6(raw);
          return;
        default:
      }
    }
    super.storeKey(key, raw);
  }

  @override
  Object? valueOf(OptionKey key) => switch (key) {
    OptionKey.borderSkipped => borderSkippedValue,
    OptionKey.borderWidth => borderWidthValue,
    OptionKey.borderRadius => borderRadiusValue,
    OptionKey.inflateAmount => inflateAmountValue,
    OptionKey.pointStyle => pointStyleValue,
    OptionKey.backgroundColor => backgroundColorValue,
    OptionKey.borderColor => borderColorValue,
    _ => super.valueOf(key),
  };

  @override
  bool isPresent(OptionKey key) => switch (key) {
    OptionKey.borderSkipped => _present & 1 != 0,
    OptionKey.borderWidth => _present & 2 != 0,
    OptionKey.borderRadius => _present & 4 != 0,
    OptionKey.inflateAmount => _present & 8 != 0,
    OptionKey.pointStyle => _present & 16 != 0,
    OptionKey.backgroundColor => _present & 32 != 0,
    OptionKey.borderColor => _present & 64 != 0,
    _ => super.isPresent(key),
  };

  @override
  bool isForeign(OptionKey key) => switch (key) {
    OptionKey.borderSkipped => _foreign & 1 != 0,
    OptionKey.borderWidth => _foreign & 2 != 0,
    OptionKey.borderRadius => _foreign & 4 != 0,
    OptionKey.inflateAmount => _foreign & 8 != 0,
    OptionKey.pointStyle => _foreign & 16 != 0,
    OptionKey.backgroundColor => _foreign & 32 != 0,
    OptionKey.borderColor => _foreign & 64 != 0,
    _ => false,
  };

  @override
  Object? foreignOf(OptionKey key) => switch (key) {
    OptionKey.borderSkipped => _foreign & 1 != 0 ? _foreignRaw![0] : null,
    OptionKey.borderWidth => _foreign & 2 != 0 ? _foreignRaw![1] : null,
    OptionKey.borderRadius => _foreign & 4 != 0 ? _foreignRaw![2] : null,
    OptionKey.inflateAmount => _foreign & 8 != 0 ? _foreignRaw![3] : null,
    OptionKey.pointStyle => _foreign & 16 != 0 ? _foreignRaw![4] : null,
    OptionKey.backgroundColor => _foreign & 32 != 0 ? _foreignRaw![5] : null,
    OptionKey.borderColor => _foreign & 64 != 0 ? _foreignRaw![6] : null,
    _ => null,
  };
}

/// index.d.ts:1882 ArcOptions and index.d.ts:1944 ArcHoverOptions, the options
/// of an arc element.
final class ArcOptions extends ElementOptions {
  /// Options with the entries of [source], in its key order.
  ArcOptions([super.source]);

  /// The copy of [source] for [clone].
  ArcOptions._copy(ArcOptions super.source)
    : _present = source._present,
      _foreign = source._foreign,
      _int = source._int,
      _foreignRaw = source._foreignRaw == null
          ? null
          : List<Object?>.of(source._foreignRaw!),
      _borderAlign = source._borderAlign,
      _borderColor = source._borderColor,
      _borderDash = source._borderDash,
      _borderDashOffset = source._borderDashOffset,
      _borderJoinStyle = source._borderJoinStyle,
      _borderRadius = source._borderRadius,
      _borderWidth = source._borderWidth,
      _offset = source._offset,
      _spacing = source._spacing,
      _spacingMode = source._spacingMode,
      _angle = source._angle,
      _circular = source._circular,
      _selfJoin = source._selfJoin,
      _backgroundColor = source._backgroundColor,
      super.copyFrom();

  /// The known keys, in the key order of Chart.js ADR 0018 §3.
  static const List<String> knownKeys = [
    r'$shared',
    'borderAlign',
    'borderColor',
    'borderDash',
    'borderDashOffset',
    'borderJoinStyle',
    'borderRadius',
    'borderWidth',
    'offset',
    'spacing',
    'spacingMode',
    'angle',
    'circular',
    'selfJoin',
    'backgroundColor',
    r'$animations',
  ];

  @override
  List<String> get knownKeyList => knownKeys;

  /// `Object.assign({}, options)` in the same class.
  @override
  ArcOptions clone() => ArcOptions._copy(this);

  /// The bits of the present keys.
  int _present = 0;

  /// The bits of the foreign keys.
  int _foreign = 0;

  /// The raw values of the foreign keys, by slot.
  List<Object?>? _foreignRaw;

  /// The bits of the `double` keys whose raw value is a Dart `int`:
  /// the Map read gives the `int` back.
  int _int = 0;

  void _setForeign(int slot, int bit, Object? raw) {
    _foreign |= bit;
    (_foreignRaw ??= List<Object?>.filled(14, null))[slot] = raw;
  }

  void _clearForeign(int slot, int bit) {
    if (_foreign & bit != 0) {
      _foreign &= ~bit;
      _foreignRaw![slot] = null;
    }
  }

  String? _borderAlign = null;

  /// `borderAlign`: the JS conversion of the Map read of the key.
  String? get borderAlign => _borderAlign;

  /// `borderAlign`: the raw value, or [undefined] for an absent key.
  Object? get borderAlignValue => _present & 1 == 0 ? undefined : _raw0();

  Object? _raw0() => _present & 1 == 0
      ? elementOptionAbsent
      : _foreign & 1 != 0
      ? _foreignRaw![0]
      : _borderAlign;

  void _store0(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~1;
      _clearForeign(0, 1);
      _borderAlign = null;
      return;
    }
    _present |= 1;
    if (raw is String) {
      _borderAlign = raw;
      _clearForeign(0, 1);
    } else {
      _borderAlign = null;
      _setForeign(0, 1, raw);
      assert(auditForeign('ArcOptions', 'borderAlign', raw));
    }
  }

  Object? _borderColor = null;

  /// `borderColor`: the JS conversion of the Map read of the key.
  Object? get borderColor => _borderColor;

  /// `borderColor`: the raw value, or [undefined] for an absent key.
  Object? get borderColorValue => _present & 2 == 0 ? undefined : _raw1();

  Object? _raw1() => _present & 2 == 0
      ? elementOptionAbsent
      : _foreign & 2 != 0
      ? _foreignRaw![1]
      : _borderColor;

  void _store1(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~2;
      _clearForeign(1, 2);
      _borderColor = null;
      return;
    }
    _present |= 2;
    _borderColor = raw;
  }

  Object? _borderDash = null;

  /// `borderDash`: the JS conversion of the Map read of the key.
  Object? get borderDash => _borderDash;

  /// `borderDash`: the raw value, or [undefined] for an absent key.
  Object? get borderDashValue => _present & 4 == 0 ? undefined : _raw2();

  Object? _raw2() => _present & 4 == 0
      ? elementOptionAbsent
      : _foreign & 4 != 0
      ? _foreignRaw![2]
      : _borderDash;

  void _store2(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~4;
      _clearForeign(2, 4);
      _borderDash = null;
      return;
    }
    _present |= 4;
    _borderDash = raw;
  }

  double _borderDashOffset = 0;

  /// `borderDashOffset`: the JS conversion of the Map read of the key.
  double get borderDashOffset => _borderDashOffset;

  /// `borderDashOffset`: the raw value, or [undefined] for an absent key.
  Object? get borderDashOffsetValue => _present & 8 == 0 ? undefined : _raw3();

  Object? _raw3() => _present & 8 == 0
      ? elementOptionAbsent
      : _foreign & 8 != 0
      ? _foreignRaw![3]
      : _int & 8 != 0
      ? _borderDashOffset.toInt()
      : _borderDashOffset;

  void _store3(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~8;
      _clearForeign(3, 8);
      _borderDashOffset = 0;
      return;
    }
    _present |= 8;
    if (raw is double) {
      _borderDashOffset = raw;
      _int &= ~8;
      _clearForeign(3, 8);
    } else if (raw is int) {
      _borderDashOffset = raw.toDouble();
      _int |= 8;
      _clearForeign(3, 8);
    } else {
      _borderDashOffset = jsToNumber(raw);
      _int &= ~8;
      _setForeign(3, 8, raw);
      assert(auditForeign('ArcOptions', 'borderDashOffset', raw));
    }
  }

  String? _borderJoinStyle = null;

  /// `borderJoinStyle`: the JS conversion of the Map read of the key.
  String? get borderJoinStyle => _borderJoinStyle;

  /// `borderJoinStyle`: the raw value, or [undefined] for an absent key.
  Object? get borderJoinStyleValue => _present & 16 == 0 ? undefined : _raw4();

  Object? _raw4() => _present & 16 == 0
      ? elementOptionAbsent
      : _foreign & 16 != 0
      ? _foreignRaw![4]
      : _borderJoinStyle;

  void _store4(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~16;
      _clearForeign(4, 16);
      _borderJoinStyle = null;
      return;
    }
    _present |= 16;
    if (raw is String) {
      _borderJoinStyle = raw;
      _clearForeign(4, 16);
    } else {
      _borderJoinStyle = null;
      _setForeign(4, 16, raw);
      assert(auditForeign('ArcOptions', 'borderJoinStyle', raw));
    }
  }

  Object? _borderRadius = null;

  /// `borderRadius`: the JS conversion of the Map read of the key.
  Object? get borderRadius => _borderRadius;

  /// `borderRadius`: the raw value, or [undefined] for an absent key.
  Object? get borderRadiusValue => _present & 32 == 0 ? undefined : _raw5();

  Object? _raw5() => _present & 32 == 0
      ? elementOptionAbsent
      : _foreign & 32 != 0
      ? _foreignRaw![5]
      : _borderRadius;

  void _store5(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~32;
      _clearForeign(5, 32);
      _borderRadius = null;
      return;
    }
    _present |= 32;
    _borderRadius = raw;
  }

  double _borderWidth = 0;

  /// `borderWidth`: the JS conversion of the Map read of the key.
  double get borderWidth => _borderWidth;

  /// `borderWidth`: the raw value, or [undefined] for an absent key.
  Object? get borderWidthValue => _present & 64 == 0 ? undefined : _raw6();

  Object? _raw6() => _present & 64 == 0
      ? elementOptionAbsent
      : _foreign & 64 != 0
      ? _foreignRaw![6]
      : _int & 64 != 0
      ? _borderWidth.toInt()
      : _borderWidth;

  void _store6(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~64;
      _clearForeign(6, 64);
      _borderWidth = 0;
      return;
    }
    _present |= 64;
    if (raw is double) {
      _borderWidth = raw;
      _int &= ~64;
      _clearForeign(6, 64);
    } else if (raw is int) {
      _borderWidth = raw.toDouble();
      _int |= 64;
      _clearForeign(6, 64);
    } else {
      _borderWidth = jsToNumber(raw);
      _int &= ~64;
      _setForeign(6, 64, raw);
      assert(auditForeign('ArcOptions', 'borderWidth', raw));
    }
  }

  double _offset = 0;

  /// `offset`: the JS conversion of the Map read of the key.
  double get offset => _offset;

  /// `offset`: the raw value, or [undefined] for an absent key.
  Object? get offsetValue => _present & 128 == 0 ? undefined : _raw7();

  Object? _raw7() => _present & 128 == 0
      ? elementOptionAbsent
      : _foreign & 128 != 0
      ? _foreignRaw![7]
      : _int & 128 != 0
      ? _offset.toInt()
      : _offset;

  void _store7(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~128;
      _clearForeign(7, 128);
      _offset = 0;
      return;
    }
    _present |= 128;
    if (raw is double) {
      _offset = raw;
      _int &= ~128;
      _clearForeign(7, 128);
    } else if (raw is int) {
      _offset = raw.toDouble();
      _int |= 128;
      _clearForeign(7, 128);
    } else {
      _offset = jsToNumber(raw);
      _int &= ~128;
      _setForeign(7, 128, raw);
      assert(auditForeign('ArcOptions', 'offset', raw));
    }
  }

  double _spacing = 0;

  /// `spacing`: the JS conversion of the Map read of the key.
  double get spacing => _spacing;

  /// `spacing`: the raw value, or [undefined] for an absent key.
  Object? get spacingValue => _present & 256 == 0 ? undefined : _raw8();

  Object? _raw8() => _present & 256 == 0
      ? elementOptionAbsent
      : _foreign & 256 != 0
      ? _foreignRaw![8]
      : _int & 256 != 0
      ? _spacing.toInt()
      : _spacing;

  void _store8(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~256;
      _clearForeign(8, 256);
      _spacing = 0;
      return;
    }
    _present |= 256;
    if (raw is double) {
      _spacing = raw;
      _int &= ~256;
      _clearForeign(8, 256);
    } else if (raw is int) {
      _spacing = raw.toDouble();
      _int |= 256;
      _clearForeign(8, 256);
    } else {
      _spacing = jsToNumber(raw);
      _int &= ~256;
      _setForeign(8, 256, raw);
      assert(auditForeign('ArcOptions', 'spacing', raw));
    }
  }

  String? _spacingMode = null;

  /// `spacingMode`: the JS conversion of the Map read of the key.
  String? get spacingMode => _spacingMode;

  /// `spacingMode`: the raw value, or [undefined] for an absent key.
  Object? get spacingModeValue => _present & 512 == 0 ? undefined : _raw9();

  Object? _raw9() => _present & 512 == 0
      ? elementOptionAbsent
      : _foreign & 512 != 0
      ? _foreignRaw![9]
      : _spacingMode;

  void _store9(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~512;
      _clearForeign(9, 512);
      _spacingMode = null;
      return;
    }
    _present |= 512;
    if (raw is String) {
      _spacingMode = raw;
      _clearForeign(9, 512);
    } else {
      _spacingMode = null;
      _setForeign(9, 512, raw);
      assert(auditForeign('ArcOptions', 'spacingMode', raw));
    }
  }

  double _angle = 0;

  /// `angle`: the JS conversion of the Map read of the key.
  double get angle => _angle;

  /// `angle`: the raw value, or [undefined] for an absent key.
  Object? get angleValue => _present & 1024 == 0 ? undefined : _raw10();

  Object? _raw10() => _present & 1024 == 0
      ? elementOptionAbsent
      : _foreign & 1024 != 0
      ? _foreignRaw![10]
      : _int & 1024 != 0
      ? _angle.toInt()
      : _angle;

  void _store10(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~1024;
      _clearForeign(10, 1024);
      _angle = 0;
      return;
    }
    _present |= 1024;
    if (raw is double) {
      _angle = raw;
      _int &= ~1024;
      _clearForeign(10, 1024);
    } else if (raw is int) {
      _angle = raw.toDouble();
      _int |= 1024;
      _clearForeign(10, 1024);
    } else {
      _angle = jsToNumber(raw);
      _int &= ~1024;
      _setForeign(10, 1024, raw);
      assert(auditForeign('ArcOptions', 'angle', raw));
    }
  }

  bool _circular = false;

  /// `circular`: the JS conversion of the Map read of the key.
  bool get circular => _circular;

  /// `circular`: the raw value, or [undefined] for an absent key.
  Object? get circularValue => _present & 2048 == 0 ? undefined : _raw11();

  Object? _raw11() => _present & 2048 == 0
      ? elementOptionAbsent
      : _foreign & 2048 != 0
      ? _foreignRaw![11]
      : _circular;

  void _store11(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~2048;
      _clearForeign(11, 2048);
      _circular = false;
      return;
    }
    _present |= 2048;
    if (raw is bool) {
      _circular = raw;
      _clearForeign(11, 2048);
    } else {
      _circular = jsTruthy(raw);
      _setForeign(11, 2048, raw);
      assert(auditForeign('ArcOptions', 'circular', raw));
    }
  }

  bool _selfJoin = false;

  /// `selfJoin`: the JS conversion of the Map read of the key.
  bool get selfJoin => _selfJoin;

  /// `selfJoin`: the raw value, or [undefined] for an absent key.
  Object? get selfJoinValue => _present & 4096 == 0 ? undefined : _raw12();

  Object? _raw12() => _present & 4096 == 0
      ? elementOptionAbsent
      : _foreign & 4096 != 0
      ? _foreignRaw![12]
      : _selfJoin;

  void _store12(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~4096;
      _clearForeign(12, 4096);
      _selfJoin = false;
      return;
    }
    _present |= 4096;
    if (raw is bool) {
      _selfJoin = raw;
      _clearForeign(12, 4096);
    } else {
      _selfJoin = jsTruthy(raw);
      _setForeign(12, 4096, raw);
      assert(auditForeign('ArcOptions', 'selfJoin', raw));
    }
  }

  Object? _backgroundColor = null;

  /// `backgroundColor`: the JS conversion of the Map read of the key.
  Object? get backgroundColor => _backgroundColor;

  /// `backgroundColor`: the raw value, or [undefined] for an absent key.
  Object? get backgroundColorValue =>
      _present & 8192 == 0 ? undefined : _raw13();

  Object? _raw13() => _present & 8192 == 0
      ? elementOptionAbsent
      : _foreign & 8192 != 0
      ? _foreignRaw![13]
      : _backgroundColor;

  void _store13(Object? raw) {
    if (identical(raw, elementOptionAbsent)) {
      _present &= ~8192;
      _clearForeign(13, 8192);
      _backgroundColor = null;
      return;
    }
    _present |= 8192;
    _backgroundColor = raw;
  }

  @override
  Object? rawOf(String key) => switch (key) {
    'borderAlign' => _raw0(),
    'borderColor' => _raw1(),
    'borderDash' => _raw2(),
    'borderDashOffset' => _raw3(),
    'borderJoinStyle' => _raw4(),
    'borderRadius' => _raw5(),
    'borderWidth' => _raw6(),
    'offset' => _raw7(),
    'spacing' => _raw8(),
    'spacingMode' => _raw9(),
    'angle' => _raw10(),
    'circular' => _raw11(),
    'selfJoin' => _raw12(),
    'backgroundColor' => _raw13(),
    _ => super.rawOf(key),
  };

  @override
  bool storeRaw(String key, Object? raw) {
    switch (key) {
      case 'borderAlign':
        _store0(raw);
      case 'borderColor':
        _store1(raw);
      case 'borderDash':
        _store2(raw);
      case 'borderDashOffset':
        _store3(raw);
      case 'borderJoinStyle':
        _store4(raw);
      case 'borderRadius':
        _store5(raw);
      case 'borderWidth':
        _store6(raw);
      case 'offset':
        _store7(raw);
      case 'spacing':
        _store8(raw);
      case 'spacingMode':
        _store9(raw);
      case 'angle':
        _store10(raw);
      case 'circular':
        _store11(raw);
      case 'selfJoin':
        _store12(raw);
      case 'backgroundColor':
        _store13(raw);
      default:
        return super.storeRaw(key, raw);
    }
    return true;
  }

  @override
  void storeKey(Object key, Object? raw) {
    if (key is OptionKey && !isFrozen) {
      switch (key) {
        case OptionKey.borderAlign:
          _store0(raw);
          return;
        case OptionKey.borderColor:
          _store1(raw);
          return;
        case OptionKey.borderDash:
          _store2(raw);
          return;
        case OptionKey.borderDashOffset:
          _store3(raw);
          return;
        case OptionKey.borderJoinStyle:
          _store4(raw);
          return;
        case OptionKey.borderRadius:
          _store5(raw);
          return;
        case OptionKey.borderWidth:
          _store6(raw);
          return;
        case OptionKey.offset:
          _store7(raw);
          return;
        case OptionKey.spacing:
          _store8(raw);
          return;
        case OptionKey.spacingMode:
          _store9(raw);
          return;
        case OptionKey.angle:
          _store10(raw);
          return;
        case OptionKey.circular:
          _store11(raw);
          return;
        case OptionKey.selfJoin:
          _store12(raw);
          return;
        case OptionKey.backgroundColor:
          _store13(raw);
          return;
        default:
      }
    }
    super.storeKey(key, raw);
  }

  @override
  Object? valueOf(OptionKey key) => switch (key) {
    OptionKey.borderAlign => borderAlignValue,
    OptionKey.borderColor => borderColorValue,
    OptionKey.borderDash => borderDashValue,
    OptionKey.borderDashOffset => borderDashOffsetValue,
    OptionKey.borderJoinStyle => borderJoinStyleValue,
    OptionKey.borderRadius => borderRadiusValue,
    OptionKey.borderWidth => borderWidthValue,
    OptionKey.offset => offsetValue,
    OptionKey.spacing => spacingValue,
    OptionKey.spacingMode => spacingModeValue,
    OptionKey.angle => angleValue,
    OptionKey.circular => circularValue,
    OptionKey.selfJoin => selfJoinValue,
    OptionKey.backgroundColor => backgroundColorValue,
    _ => super.valueOf(key),
  };

  @override
  bool isPresent(OptionKey key) => switch (key) {
    OptionKey.borderAlign => _present & 1 != 0,
    OptionKey.borderColor => _present & 2 != 0,
    OptionKey.borderDash => _present & 4 != 0,
    OptionKey.borderDashOffset => _present & 8 != 0,
    OptionKey.borderJoinStyle => _present & 16 != 0,
    OptionKey.borderRadius => _present & 32 != 0,
    OptionKey.borderWidth => _present & 64 != 0,
    OptionKey.offset => _present & 128 != 0,
    OptionKey.spacing => _present & 256 != 0,
    OptionKey.spacingMode => _present & 512 != 0,
    OptionKey.angle => _present & 1024 != 0,
    OptionKey.circular => _present & 2048 != 0,
    OptionKey.selfJoin => _present & 4096 != 0,
    OptionKey.backgroundColor => _present & 8192 != 0,
    _ => super.isPresent(key),
  };

  @override
  bool isForeign(OptionKey key) => switch (key) {
    OptionKey.borderAlign => _foreign & 1 != 0,
    OptionKey.borderColor => _foreign & 2 != 0,
    OptionKey.borderDash => _foreign & 4 != 0,
    OptionKey.borderDashOffset => _foreign & 8 != 0,
    OptionKey.borderJoinStyle => _foreign & 16 != 0,
    OptionKey.borderRadius => _foreign & 32 != 0,
    OptionKey.borderWidth => _foreign & 64 != 0,
    OptionKey.offset => _foreign & 128 != 0,
    OptionKey.spacing => _foreign & 256 != 0,
    OptionKey.spacingMode => _foreign & 512 != 0,
    OptionKey.angle => _foreign & 1024 != 0,
    OptionKey.circular => _foreign & 2048 != 0,
    OptionKey.selfJoin => _foreign & 4096 != 0,
    OptionKey.backgroundColor => _foreign & 8192 != 0,
    _ => false,
  };

  @override
  Object? foreignOf(OptionKey key) => switch (key) {
    OptionKey.borderAlign => _foreign & 1 != 0 ? _foreignRaw![0] : null,
    OptionKey.borderColor => _foreign & 2 != 0 ? _foreignRaw![1] : null,
    OptionKey.borderDash => _foreign & 4 != 0 ? _foreignRaw![2] : null,
    OptionKey.borderDashOffset => _foreign & 8 != 0 ? _foreignRaw![3] : null,
    OptionKey.borderJoinStyle => _foreign & 16 != 0 ? _foreignRaw![4] : null,
    OptionKey.borderRadius => _foreign & 32 != 0 ? _foreignRaw![5] : null,
    OptionKey.borderWidth => _foreign & 64 != 0 ? _foreignRaw![6] : null,
    OptionKey.offset => _foreign & 128 != 0 ? _foreignRaw![7] : null,
    OptionKey.spacing => _foreign & 256 != 0 ? _foreignRaw![8] : null,
    OptionKey.spacingMode => _foreign & 512 != 0 ? _foreignRaw![9] : null,
    OptionKey.angle => _foreign & 1024 != 0 ? _foreignRaw![10] : null,
    OptionKey.circular => _foreign & 2048 != 0 ? _foreignRaw![11] : null,
    OptionKey.selfJoin => _foreign & 4096 != 0 ? _foreignRaw![12] : null,
    OptionKey.backgroundColor => _foreign & 8192 != 0 ? _foreignRaw![13] : null,
    _ => null,
  };
}
