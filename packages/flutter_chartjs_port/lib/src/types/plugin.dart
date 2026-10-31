// Original code, not ported from Chart.js: the typed plugin objects.

/// The typed plugins of Chart.js ADR 0054 §12: [Plugin] (the name of
/// `index.d.ts:856`), the hook names ([PluginHook]), the argument classes of
/// the hooks and [MapPlugin], the reader of a plugin object that is a Map.
///
/// The plugin service (`core.plugins.dart`) reads the hook of a plugin at
/// each notify, as upstream reads `plugin[hook]`: the field of a [Plugin],
/// `map[hook]` of a Map plugin ([MapPlugin]), and the property by name of
/// another value. The built-in plugins stay Maps until lane L4 makes them
/// [Plugin] instances.
///
/// The argument classes are [TypedRecord]s: typed fields in the key order of
/// the upstream literals, extras for a key that a plugin writes, and the
/// face (Chart.js ADR 0054 §5). `args` passes through each hook by identity.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsArrayIndex;
import 'package:flutter_chartjs_port/src/js/js_function.dart'
    show jsCall, jsIsFunction;
import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsToNumber, jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/typed_record.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// A hook of the `Plugin` interface (U `index.d.ts:856-1240` and the hooks
/// of the tooltip plugin, `index.d.ts:2777-2786`), with its JS name.
enum PluginHook {
  /// `install`.
  install('install'),

  /// `start`.
  start('start'),

  /// `stop`.
  stop('stop'),

  /// `beforeInit`.
  beforeInit('beforeInit'),

  /// `afterInit`.
  afterInit('afterInit'),

  /// `beforeUpdate`.
  beforeUpdate('beforeUpdate'),

  /// `afterUpdate`.
  afterUpdate('afterUpdate'),

  /// `beforeElementsUpdate`.
  beforeElementsUpdate('beforeElementsUpdate'),

  /// `reset`.
  reset('reset'),

  /// `beforeDatasetsUpdate`.
  beforeDatasetsUpdate('beforeDatasetsUpdate'),

  /// `afterDatasetsUpdate`.
  afterDatasetsUpdate('afterDatasetsUpdate'),

  /// `beforeDatasetUpdate`.
  beforeDatasetUpdate('beforeDatasetUpdate'),

  /// `afterDatasetUpdate`.
  afterDatasetUpdate('afterDatasetUpdate'),

  /// `beforeLayout`.
  beforeLayout('beforeLayout'),

  /// `beforeDataLimits`.
  beforeDataLimits('beforeDataLimits'),

  /// `afterDataLimits`.
  afterDataLimits('afterDataLimits'),

  /// `beforeBuildTicks`.
  beforeBuildTicks('beforeBuildTicks'),

  /// `afterBuildTicks`.
  afterBuildTicks('afterBuildTicks'),

  /// `afterLayout`.
  afterLayout('afterLayout'),

  /// `beforeRender`.
  beforeRender('beforeRender'),

  /// `afterRender`.
  afterRender('afterRender'),

  /// `beforeDraw`.
  beforeDraw('beforeDraw'),

  /// `afterDraw`.
  afterDraw('afterDraw'),

  /// `beforeDatasetsDraw`.
  beforeDatasetsDraw('beforeDatasetsDraw'),

  /// `afterDatasetsDraw`.
  afterDatasetsDraw('afterDatasetsDraw'),

  /// `beforeDatasetDraw`.
  beforeDatasetDraw('beforeDatasetDraw'),

  /// `afterDatasetDraw`.
  afterDatasetDraw('afterDatasetDraw'),

  /// `beforeEvent`.
  beforeEvent('beforeEvent'),

  /// `afterEvent`.
  afterEvent('afterEvent'),

  /// `resize`.
  resize('resize'),

  /// `beforeDestroy`.
  beforeDestroy('beforeDestroy'),

  /// `afterDestroy`.
  afterDestroy('afterDestroy'),

  /// `uninstall`.
  uninstall('uninstall'),

  /// `beforeTooltipDraw`.
  beforeTooltipDraw('beforeTooltipDraw'),

  /// `afterTooltipDraw`.
  afterTooltipDraw('afterTooltipDraw');

  const PluginHook(this.jsName);

  /// The JS name of the hook.
  final String jsName;

  /// The hook of the JS name [name], or Dart `null` for another name.
  static PluginHook? of(String name) => switch (name) {
    'install' => install,
    'start' => start,
    'stop' => stop,
    'beforeInit' => beforeInit,
    'afterInit' => afterInit,
    'beforeUpdate' => beforeUpdate,
    'afterUpdate' => afterUpdate,
    'beforeElementsUpdate' => beforeElementsUpdate,
    'reset' => reset,
    'beforeDatasetsUpdate' => beforeDatasetsUpdate,
    'afterDatasetsUpdate' => afterDatasetsUpdate,
    'beforeDatasetUpdate' => beforeDatasetUpdate,
    'afterDatasetUpdate' => afterDatasetUpdate,
    'beforeLayout' => beforeLayout,
    'beforeDataLimits' => beforeDataLimits,
    'afterDataLimits' => afterDataLimits,
    'beforeBuildTicks' => beforeBuildTicks,
    'afterBuildTicks' => afterBuildTicks,
    'afterLayout' => afterLayout,
    'beforeRender' => beforeRender,
    'afterRender' => afterRender,
    'beforeDraw' => beforeDraw,
    'afterDraw' => afterDraw,
    'beforeDatasetsDraw' => beforeDatasetsDraw,
    'afterDatasetsDraw' => afterDatasetsDraw,
    'beforeDatasetDraw' => beforeDatasetDraw,
    'afterDatasetDraw' => afterDatasetDraw,
    'beforeEvent' => beforeEvent,
    'afterEvent' => afterEvent,
    'resize' => resize,
    'beforeDestroy' => beforeDestroy,
    'afterDestroy' => afterDestroy,
    'uninstall' => uninstall,
    'beforeTooltipDraw' => beforeTooltipDraw,
    'afterTooltipDraw' => afterTooltipDraw,
    _ => null,
  };
}

/// The function of a hook: `hook(chart, args, options)`, with the argument
/// class [A] of the hook. The result is `false` to cancel a cancelable hook,
/// else any value.
///
/// [A] is the argument class of the hook (a typed record of this library),
/// or `AnyObject` for the hooks whose upstream arguments are an object
/// literal that the caller makes (`{scale}` of the scale hooks). The
/// options are the plugin options view (`OptionView`, Chart.js ADR 0054
/// §12).
typedef PluginHookFunction<A extends Object> = Object? Function(
  types.Chart chart,
  A args,
  Object options,
);

/// The arguments `{}` of a hook without arguments (`EmptyObject` of
/// `index.d.ts`), and the base of the argument classes.
base class PluginHookArgs extends TypedRecord {
  /// An object without own keys.
  PluginHookArgs();

  @override
  List<String> get fieldNames => const [];

  @override
  int slotOf(String name) => -1;

  @override
  Object? readSlot(int slot) => throw StateError('no field $slot');

  @override
  bool writeSlot(int slot, Object? value) => throw StateError('no field $slot');

  @override
  void clearSlot(int slot) => throw StateError('no field $slot');
}

/// `{mode, cancelable: true}` of `beforeUpdate` and `beforeDatasetsUpdate`,
/// and `{mode}` of `afterUpdate` and `afterDatasetsUpdate` (U
/// `core.controller.js:490`, `:524`, `:649`, `:661`).
final class UpdateHookArgs extends PluginHookArgs {
  /// The object with the given keys, in the key order of the upstream
  /// literal. A required key is always present.
  UpdateHookArgs({
    required Object? mode,
    bool? cancelable,
  }) {
    this.mode = mode;
    if (cancelable != null) this.cancelable = cancelable;
  }

  static const List<String> _fieldNames = [
    'mode',
    'cancelable',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'mode' => 0,
    'cancelable' => 1,
    _ => -1,
  };

  Object? _mode;

  bool _cancelable = false;

  /// `mode`, or [undefined] when absent.
  Object? get mode => hasSlot(0) ? _mode : undefined;

  set mode(Object? value) {
    _mode = value;
    touchSlot(0);
  }

  /// `cancelable`: false when absent.
  bool get cancelable => _cancelable;

  set cancelable(bool value) {
    _cancelable = value;
    touchSlot(1);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _mode,
    _ => _cancelable,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _mode = value;
        return true;
      default:
        _cancelable = value is bool ? value : jsTruthy(value);
        return value is bool;
    }
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _mode = null;
      default:
        _cancelable = false;
    }
  }
}

/// `{cancelable: true}` of `beforeLayout`, `beforeRender`, `beforeDraw` and
/// `beforeDatasetsDraw` (U `core.controller.js:612`, `:684`, `:712`, `:766`).
final class CancelableHookArgs extends PluginHookArgs {
  /// The object with the given keys, in the key order of the upstream
  /// literal. A required key is always present.
  CancelableHookArgs({
    bool? cancelable,
  }) {
    if (cancelable != null) this.cancelable = cancelable;
  }

  static const List<String> _fieldNames = [
    'cancelable',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'cancelable' => 0,
    _ => -1,
  };

  bool _cancelable = false;

  /// `cancelable`: false when absent.
  bool get cancelable => _cancelable;

  set cancelable(bool value) {
    _cancelable = value;
    touchSlot(0);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    _ => _cancelable,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      default:
        _cancelable = value is bool ? value : jsTruthy(value);
        return value is bool;
    }
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      default:
        _cancelable = false;
    }
  }
}

/// `{size}` of `resize` (U `core.controller.js:292`).
final class ResizeHookArgs extends PluginHookArgs {
  /// The object with the given keys, in the key order of the upstream
  /// literal. A required key is always present.
  ResizeHookArgs({
    required Object? size,
  }) {
    this.size = size;
  }

  static const List<String> _fieldNames = [
    'size',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'size' => 0,
    _ => -1,
  };

  Object? _size;

  /// `size`, or [undefined] when absent.
  Object? get size => hasSlot(0) ? _size : undefined;

  set size(Object? value) {
    _size = value;
    touchSlot(0);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    _ => _size,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      default:
        _size = value;
        return true;
    }
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      default:
        _size = null;
    }
  }
}

/// `{meta, index, mode, cancelable}` of `beforeDatasetUpdate` and
/// `afterDatasetUpdate` (U `core.controller.js:670-680`).
final class DatasetUpdateHookArgs extends PluginHookArgs {
  /// The object with the given keys, in the key order of the upstream
  /// literal. A required key is always present.
  DatasetUpdateHookArgs({
    required types.ChartMeta? meta,
    required double index,
    required Object? mode,
    bool? cancelable,
  }) {
    this.meta = meta;
    this.index = index;
    this.mode = mode;
    if (cancelable != null) this.cancelable = cancelable;
  }

  static const List<String> _fieldNames = [
    'meta',
    'index',
    'mode',
    'cancelable',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'meta' => 0,
    'index' => 1,
    'mode' => 2,
    'cancelable' => 3,
    _ => -1,
  };

  types.ChartMeta? _meta;

  double _index = double.nan;

  Object? _mode;

  bool _cancelable = false;

  /// `meta`, or Dart `null`.
  types.ChartMeta? get meta => hasSlot(0) && !isForeignSlot(0) ? _meta : null;

  set meta(types.ChartMeta? value) {
    _meta = value;
    touchSlot(0);
  }

  /// `index`: NaN when absent.
  double get index => _index;

  set index(double value) {
    _index = value;
    touchSlot(1);
  }

  /// `mode`, or [undefined] when absent.
  Object? get mode => hasSlot(2) ? _mode : undefined;

  set mode(Object? value) {
    _mode = value;
    touchSlot(2);
  }

  /// `cancelable`: false when absent.
  bool get cancelable => _cancelable;

  set cancelable(bool value) {
    _cancelable = value;
    touchSlot(3);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _meta,
    1 => _index,
    2 => _mode,
    _ => _cancelable,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _meta = value is types.ChartMeta ? value : null;
        return value is types.ChartMeta?;
      case 1:
        _index = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      case 2:
        _mode = value;
        return true;
      default:
        _cancelable = value is bool ? value : jsTruthy(value);
        return value is bool;
    }
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _meta = null;
      case 1:
        _index = double.nan;
      case 2:
        _mode = null;
      default:
        _cancelable = false;
    }
  }
}

/// `{meta, index, cancelable}` of `beforeDatasetDraw` and
/// `afterDatasetDraw` (U `core.controller.js:786-808`).
final class DatasetDrawHookArgs extends PluginHookArgs {
  /// The object with the given keys, in the key order of the upstream
  /// literal. A required key is always present.
  DatasetDrawHookArgs({
    required types.ChartMeta? meta,
    required double index,
    bool? cancelable,
  }) {
    this.meta = meta;
    this.index = index;
    if (cancelable != null) this.cancelable = cancelable;
  }

  static const List<String> _fieldNames = [
    'meta',
    'index',
    'cancelable',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'meta' => 0,
    'index' => 1,
    'cancelable' => 2,
    _ => -1,
  };

  types.ChartMeta? _meta;

  double _index = double.nan;

  bool _cancelable = false;

  /// `meta`, or Dart `null`.
  types.ChartMeta? get meta => hasSlot(0) && !isForeignSlot(0) ? _meta : null;

  set meta(types.ChartMeta? value) {
    _meta = value;
    touchSlot(0);
  }

  /// `index`: NaN when absent.
  double get index => _index;

  set index(double value) {
    _index = value;
    touchSlot(1);
  }

  /// `cancelable`: false when absent.
  bool get cancelable => _cancelable;

  set cancelable(bool value) {
    _cancelable = value;
    touchSlot(2);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _meta,
    1 => _index,
    _ => _cancelable,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _meta = value is types.ChartMeta ? value : null;
        return value is types.ChartMeta?;
      case 1:
        _index = value is num ? value.toDouble() : jsToNumber(value);
        return value is num;
      default:
        _cancelable = value is bool ? value : jsTruthy(value);
        return value is bool;
    }
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _meta = null;
      case 1:
        _index = double.nan;
      default:
        _cancelable = false;
    }
  }
}

/// `{event, replay, cancelable, inChartArea}` of `beforeEvent` and
/// `afterEvent`, and the key `changed` that a plugin writes (U
/// `core.controller.js:1162-1179`).
final class EventHookArgs extends PluginHookArgs {
  /// The object with the given keys, in the key order of the upstream
  /// literal. A required key is always present.
  EventHookArgs({
    required types.ChartEvent? event,
    required Object? replay,
    bool? cancelable,
    bool? inChartArea,
    bool? changed,
  }) {
    this.event = event;
    this.replay = replay;
    if (cancelable != null) this.cancelable = cancelable;
    if (inChartArea != null) this.inChartArea = inChartArea;
    if (changed != null) this.changed = changed;
  }

  static const List<String> _fieldNames = [
    'event',
    'replay',
    'cancelable',
    'inChartArea',
    'changed',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'event' => 0,
    'replay' => 1,
    'cancelable' => 2,
    'inChartArea' => 3,
    'changed' => 4,
    _ => -1,
  };

  types.ChartEvent? _event;

  Object? _replay;

  bool _cancelable = false;

  bool _inChartArea = false;

  bool _changed = false;

  /// `event`, or Dart `null`.
  types.ChartEvent? get event =>
      hasSlot(0) && !isForeignSlot(0) ? _event : null;

  set event(types.ChartEvent? value) {
    _event = value;
    touchSlot(0);
  }

  /// `replay`, or [undefined] when absent.
  Object? get replay => hasSlot(1) ? _replay : undefined;

  set replay(Object? value) {
    _replay = value;
    touchSlot(1);
  }

  /// `cancelable`: false when absent.
  bool get cancelable => _cancelable;

  set cancelable(bool value) {
    _cancelable = value;
    touchSlot(2);
  }

  /// `inChartArea`: false when absent.
  bool get inChartArea => _inChartArea;

  set inChartArea(bool value) {
    _inChartArea = value;
    touchSlot(3);
  }

  /// `changed`: false when absent.
  bool get changed => _changed;

  set changed(bool value) {
    _changed = value;
    touchSlot(4);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _event,
    1 => _replay,
    2 => _cancelable,
    3 => _inChartArea,
    _ => _changed,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _event = value is types.ChartEvent ? value : null;
        return value is types.ChartEvent?;
      case 1:
        _replay = value;
        return true;
      case 2:
        _cancelable = value is bool ? value : jsTruthy(value);
        return value is bool;
      case 3:
        _inChartArea = value is bool ? value : jsTruthy(value);
        return value is bool;
      default:
        _changed = value is bool ? value : jsTruthy(value);
        return value is bool;
    }
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _event = null;
      case 1:
        _replay = null;
      case 2:
        _cancelable = false;
      case 3:
        _inChartArea = false;
      default:
        _changed = false;
    }
  }
}

/// `{tooltip}` of `afterTooltipDraw` and `{...args, cancelable: true}` of
/// `beforeTooltipDraw` (U `plugin.tooltip.js:1250-1260`).
final class TooltipDrawHookArgs extends PluginHookArgs {
  /// The object with the given keys, in the key order of the upstream
  /// literal. A required key is always present.
  TooltipDrawHookArgs({
    required Object? tooltip,
    bool? cancelable,
  }) {
    this.tooltip = tooltip;
    if (cancelable != null) this.cancelable = cancelable;
  }

  static const List<String> _fieldNames = [
    'tooltip',
    'cancelable',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'tooltip' => 0,
    'cancelable' => 1,
    _ => -1,
  };

  Object? _tooltip;

  bool _cancelable = false;

  /// `tooltip`, or [undefined] when absent.
  Object? get tooltip => hasSlot(0) ? _tooltip : undefined;

  set tooltip(Object? value) {
    _tooltip = value;
    touchSlot(0);
  }

  /// `cancelable`: false when absent.
  bool get cancelable => _cancelable;

  set cancelable(bool value) {
    _cancelable = value;
    touchSlot(1);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _tooltip,
    _ => _cancelable,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _tooltip = value;
        return true;
      default:
        _cancelable = value is bool ? value : jsTruthy(value);
        return value is bool;
    }
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _tooltip = null;
      default:
        _cancelable = false;
    }
  }
}

/// `Plugin` (U `index.d.ts:856`): a plugin object with a field for `id`,
/// `events`, each hook, `defaults`, `defaultRoutes`, `descriptors` and
/// `additionalOptionScopes`.
///
/// A hook is a property that code reads and writes at run time (U
/// `test/specs/core.plugin.tests.js:3-16`): the field is that property. A
/// typed getter gives the function when it has the type of the hook
/// ([PluginHookFunction] of its argument class), else Dart `null`. A write
/// by name keeps any value: the plugin service reads it with [hookValue]
/// and calls a function of another type with JS arity, `this` the plugin.
/// The own-key order is the insertion order; another key is an extra. The
/// face reads and writes the fields by name. A plugin is not a `Map`.
final class Plugin implements JsObjectFace {
  /// A plugin without own keys.
  Plugin();

  /// The JS names of the fields, by slot.
  static const List<String> fieldNames = [
    'id',
    'events',
    'install',
    'start',
    'stop',
    'beforeInit',
    'afterInit',
    'beforeUpdate',
    'afterUpdate',
    'beforeElementsUpdate',
    'reset',
    'beforeDatasetsUpdate',
    'afterDatasetsUpdate',
    'beforeDatasetUpdate',
    'afterDatasetUpdate',
    'beforeLayout',
    'beforeDataLimits',
    'afterDataLimits',
    'beforeBuildTicks',
    'afterBuildTicks',
    'afterLayout',
    'beforeRender',
    'afterRender',
    'beforeDraw',
    'afterDraw',
    'beforeDatasetsDraw',
    'afterDatasetsDraw',
    'beforeDatasetDraw',
    'afterDatasetDraw',
    'beforeEvent',
    'afterEvent',
    'resize',
    'beforeDestroy',
    'afterDestroy',
    'uninstall',
    'defaults',
    'defaultRoutes',
    'descriptors',
    'additionalOptionScopes',
    'beforeTooltipDraw',
    'afterTooltipDraw',
  ];

  /// The slot of the field [name], or -1.
  static int _slotOf(String name) => switch (name) {
    'id' => 0,
    'events' => 1,
    'install' => 2,
    'start' => 3,
    'stop' => 4,
    'beforeInit' => 5,
    'afterInit' => 6,
    'beforeUpdate' => 7,
    'afterUpdate' => 8,
    'beforeElementsUpdate' => 9,
    'reset' => 10,
    'beforeDatasetsUpdate' => 11,
    'afterDatasetsUpdate' => 12,
    'beforeDatasetUpdate' => 13,
    'afterDatasetUpdate' => 14,
    'beforeLayout' => 15,
    'beforeDataLimits' => 16,
    'afterDataLimits' => 17,
    'beforeBuildTicks' => 18,
    'afterBuildTicks' => 19,
    'afterLayout' => 20,
    'beforeRender' => 21,
    'afterRender' => 22,
    'beforeDraw' => 23,
    'afterDraw' => 24,
    'beforeDatasetsDraw' => 25,
    'afterDatasetsDraw' => 26,
    'beforeDatasetDraw' => 27,
    'afterDatasetDraw' => 28,
    'beforeEvent' => 29,
    'afterEvent' => 30,
    'resize' => 31,
    'beforeDestroy' => 32,
    'afterDestroy' => 33,
    'uninstall' => 34,
    'defaults' => 35,
    'defaultRoutes' => 36,
    'descriptors' => 37,
    'additionalOptionScopes' => 38,
    'beforeTooltipDraw' => 39,
    'afterTooltipDraw' => 40,
    _ => -1,
  };

  /// The value of each field, or [_absent].
  final List<Object?> _slots = List<Object?>.filled(fieldNames.length, _absent);

  /// The own keys in insertion order.
  final List<String> _order = <String>[];

  /// The extras, in insertion order.
  Map<String, Object?>? _extras;

  void _store(int slot, Object? value) {
    if (identical(_slots[slot], _absent)) _order.add(fieldNames[slot]);
    _slots[slot] = value;
  }

  Object? _member(int slot) {
    final value = _slots[slot];
    return identical(value, _absent) ? undefined : value;
  }

  /// `id`.
  Object? get id => _member(0);

  set id(Object? value) => _store(0, value);

  /// `events`.
  Object? get events => _member(1);

  set events(Object? value) => _store(1, value);

  /// `defaults`.
  Object? get defaults => _member(35);

  set defaults(Object? value) => _store(35, value);

  /// `defaultRoutes`.
  Object? get defaultRoutes => _member(36);

  set defaultRoutes(Object? value) => _store(36, value);

  /// `descriptors`.
  Object? get descriptors => _member(37);

  set descriptors(Object? value) => _store(37, value);

  /// `additionalOptionScopes`.
  Object? get additionalOptionScopes => _member(38);

  set additionalOptionScopes(Object? value) => _store(38, value);

  /// The value of the hook [hook]: the field value, or [undefined] when the
  /// plugin does not own it.
  Object? hookValue(PluginHook hook) => _member(_hookSlot(hook));

  /// The slot of the hook [hook].
  static int _hookSlot(PluginHook hook) =>
      hook.index < 33 ? hook.index + 2 : hook.index + 6;

  /// Calls the hook function [function] of [hook] with `(chart, args,
  /// options)`: a typed call when [function] has the type of the hook and
  /// [args] is of its argument class, else a call with JS arity, `this` the
  /// plugin. [args] passes by identity. A function that is typed for the
  /// argument class of [hook] throws a [TypeError] for an args object of
  /// another class (the narrow case of the row `adapt-typed-plugins`).
  Object? invokeHook(
    PluginHook hook,
    Object function,
    types.Chart chart,
    Object args,
    Object options,
  ) {
    switch (function) {
      case final PluginHookFunction<AnyObject> f when args is AnyObject:
        return f(chart, args, options);
      case final PluginHookFunction<CancelableHookArgs> f
          when args is CancelableHookArgs:
        return f(chart, args, options);
      case final PluginHookFunction<DatasetDrawHookArgs> f
          when args is DatasetDrawHookArgs:
        return f(chart, args, options);
      case final PluginHookFunction<DatasetUpdateHookArgs> f
          when args is DatasetUpdateHookArgs:
        return f(chart, args, options);
      case final PluginHookFunction<EventHookArgs> f when args is EventHookArgs:
        return f(chart, args, options);
      case final PluginHookFunction<PluginHookArgs> f
          when args is PluginHookArgs:
        return f(chart, args, options);
      case final PluginHookFunction<ResizeHookArgs> f
          when args is ResizeHookArgs:
        return f(chart, args, options);
      case final PluginHookFunction<TooltipDrawHookArgs> f
          when args is TooltipDrawHookArgs:
        return f(chart, args, options);
      case final PluginHookFunction<UpdateHookArgs> f
          when args is UpdateHookArgs:
        return f(chart, args, options);
    }
    return jsCall(function, [chart, args, options], thisArg: this);
  }

  /// `install`.
  PluginHookFunction<PluginHookArgs>? get install => switch (_slots[2]) {
    final PluginHookFunction<PluginHookArgs> f => f,
    _ => null,
  };

  set install(PluginHookFunction<PluginHookArgs>? value) => _store(2, value);

  /// `start`.
  PluginHookFunction<PluginHookArgs>? get start => switch (_slots[3]) {
    final PluginHookFunction<PluginHookArgs> f => f,
    _ => null,
  };

  set start(PluginHookFunction<PluginHookArgs>? value) => _store(3, value);

  /// `stop`.
  PluginHookFunction<PluginHookArgs>? get stop => switch (_slots[4]) {
    final PluginHookFunction<PluginHookArgs> f => f,
    _ => null,
  };

  set stop(PluginHookFunction<PluginHookArgs>? value) => _store(4, value);

  /// `beforeInit`.
  PluginHookFunction<PluginHookArgs>? get beforeInit => switch (_slots[5]) {
    final PluginHookFunction<PluginHookArgs> f => f,
    _ => null,
  };

  set beforeInit(PluginHookFunction<PluginHookArgs>? value) => _store(5, value);

  /// `afterInit`.
  PluginHookFunction<PluginHookArgs>? get afterInit => switch (_slots[6]) {
    final PluginHookFunction<PluginHookArgs> f => f,
    _ => null,
  };

  set afterInit(PluginHookFunction<PluginHookArgs>? value) => _store(6, value);

  /// `beforeUpdate`.
  PluginHookFunction<UpdateHookArgs>? get beforeUpdate => switch (_slots[7]) {
    final PluginHookFunction<UpdateHookArgs> f => f,
    _ => null,
  };

  set beforeUpdate(PluginHookFunction<UpdateHookArgs>? value) =>
      _store(7, value);

  /// `afterUpdate`.
  PluginHookFunction<UpdateHookArgs>? get afterUpdate => switch (_slots[8]) {
    final PluginHookFunction<UpdateHookArgs> f => f,
    _ => null,
  };

  set afterUpdate(PluginHookFunction<UpdateHookArgs>? value) =>
      _store(8, value);

  /// `beforeElementsUpdate`.
  PluginHookFunction<PluginHookArgs>? get beforeElementsUpdate =>
      switch (_slots[9]) {
        final PluginHookFunction<PluginHookArgs> f => f,
        _ => null,
      };

  set beforeElementsUpdate(PluginHookFunction<PluginHookArgs>? value) =>
      _store(9, value);

  /// `reset`.
  PluginHookFunction<PluginHookArgs>? get reset => switch (_slots[10]) {
    final PluginHookFunction<PluginHookArgs> f => f,
    _ => null,
  };

  set reset(PluginHookFunction<PluginHookArgs>? value) => _store(10, value);

  /// `beforeDatasetsUpdate`.
  PluginHookFunction<UpdateHookArgs>? get beforeDatasetsUpdate =>
      switch (_slots[11]) {
        final PluginHookFunction<UpdateHookArgs> f => f,
        _ => null,
      };

  set beforeDatasetsUpdate(PluginHookFunction<UpdateHookArgs>? value) =>
      _store(11, value);

  /// `afterDatasetsUpdate`.
  PluginHookFunction<UpdateHookArgs>? get afterDatasetsUpdate =>
      switch (_slots[12]) {
        final PluginHookFunction<UpdateHookArgs> f => f,
        _ => null,
      };

  set afterDatasetsUpdate(PluginHookFunction<UpdateHookArgs>? value) =>
      _store(12, value);

  /// `beforeDatasetUpdate`.
  PluginHookFunction<DatasetUpdateHookArgs>? get beforeDatasetUpdate =>
      switch (_slots[13]) {
        final PluginHookFunction<DatasetUpdateHookArgs> f => f,
        _ => null,
      };

  set beforeDatasetUpdate(PluginHookFunction<DatasetUpdateHookArgs>? value) =>
      _store(13, value);

  /// `afterDatasetUpdate`.
  PluginHookFunction<DatasetUpdateHookArgs>? get afterDatasetUpdate =>
      switch (_slots[14]) {
        final PluginHookFunction<DatasetUpdateHookArgs> f => f,
        _ => null,
      };

  set afterDatasetUpdate(PluginHookFunction<DatasetUpdateHookArgs>? value) =>
      _store(14, value);

  /// `beforeLayout`.
  PluginHookFunction<CancelableHookArgs>? get beforeLayout =>
      switch (_slots[15]) {
        final PluginHookFunction<CancelableHookArgs> f => f,
        _ => null,
      };

  set beforeLayout(PluginHookFunction<CancelableHookArgs>? value) =>
      _store(15, value);

  /// `beforeDataLimits`.
  PluginHookFunction<AnyObject>? get beforeDataLimits => switch (_slots[16]) {
    final PluginHookFunction<AnyObject> f => f,
    _ => null,
  };

  set beforeDataLimits(PluginHookFunction<AnyObject>? value) =>
      _store(16, value);

  /// `afterDataLimits`.
  PluginHookFunction<AnyObject>? get afterDataLimits => switch (_slots[17]) {
    final PluginHookFunction<AnyObject> f => f,
    _ => null,
  };

  set afterDataLimits(PluginHookFunction<AnyObject>? value) =>
      _store(17, value);

  /// `beforeBuildTicks`.
  PluginHookFunction<AnyObject>? get beforeBuildTicks => switch (_slots[18]) {
    final PluginHookFunction<AnyObject> f => f,
    _ => null,
  };

  set beforeBuildTicks(PluginHookFunction<AnyObject>? value) =>
      _store(18, value);

  /// `afterBuildTicks`.
  PluginHookFunction<AnyObject>? get afterBuildTicks => switch (_slots[19]) {
    final PluginHookFunction<AnyObject> f => f,
    _ => null,
  };

  set afterBuildTicks(PluginHookFunction<AnyObject>? value) =>
      _store(19, value);

  /// `afterLayout`.
  PluginHookFunction<PluginHookArgs>? get afterLayout => switch (_slots[20]) {
    final PluginHookFunction<PluginHookArgs> f => f,
    _ => null,
  };

  set afterLayout(PluginHookFunction<PluginHookArgs>? value) =>
      _store(20, value);

  /// `beforeRender`.
  PluginHookFunction<CancelableHookArgs>? get beforeRender =>
      switch (_slots[21]) {
        final PluginHookFunction<CancelableHookArgs> f => f,
        _ => null,
      };

  set beforeRender(PluginHookFunction<CancelableHookArgs>? value) =>
      _store(21, value);

  /// `afterRender`.
  PluginHookFunction<PluginHookArgs>? get afterRender => switch (_slots[22]) {
    final PluginHookFunction<PluginHookArgs> f => f,
    _ => null,
  };

  set afterRender(PluginHookFunction<PluginHookArgs>? value) =>
      _store(22, value);

  /// `beforeDraw`.
  PluginHookFunction<CancelableHookArgs>? get beforeDraw =>
      switch (_slots[23]) {
        final PluginHookFunction<CancelableHookArgs> f => f,
        _ => null,
      };

  set beforeDraw(PluginHookFunction<CancelableHookArgs>? value) =>
      _store(23, value);

  /// `afterDraw`.
  PluginHookFunction<PluginHookArgs>? get afterDraw => switch (_slots[24]) {
    final PluginHookFunction<PluginHookArgs> f => f,
    _ => null,
  };

  set afterDraw(PluginHookFunction<PluginHookArgs>? value) => _store(24, value);

  /// `beforeDatasetsDraw`.
  PluginHookFunction<CancelableHookArgs>? get beforeDatasetsDraw =>
      switch (_slots[25]) {
        final PluginHookFunction<CancelableHookArgs> f => f,
        _ => null,
      };

  set beforeDatasetsDraw(PluginHookFunction<CancelableHookArgs>? value) =>
      _store(25, value);

  /// `afterDatasetsDraw`.
  PluginHookFunction<PluginHookArgs>? get afterDatasetsDraw =>
      switch (_slots[26]) {
        final PluginHookFunction<PluginHookArgs> f => f,
        _ => null,
      };

  set afterDatasetsDraw(PluginHookFunction<PluginHookArgs>? value) =>
      _store(26, value);

  /// `beforeDatasetDraw`.
  PluginHookFunction<DatasetDrawHookArgs>? get beforeDatasetDraw =>
      switch (_slots[27]) {
        final PluginHookFunction<DatasetDrawHookArgs> f => f,
        _ => null,
      };

  set beforeDatasetDraw(PluginHookFunction<DatasetDrawHookArgs>? value) =>
      _store(27, value);

  /// `afterDatasetDraw`.
  PluginHookFunction<DatasetDrawHookArgs>? get afterDatasetDraw =>
      switch (_slots[28]) {
        final PluginHookFunction<DatasetDrawHookArgs> f => f,
        _ => null,
      };

  set afterDatasetDraw(PluginHookFunction<DatasetDrawHookArgs>? value) =>
      _store(28, value);

  /// `beforeEvent`.
  PluginHookFunction<EventHookArgs>? get beforeEvent => switch (_slots[29]) {
    final PluginHookFunction<EventHookArgs> f => f,
    _ => null,
  };

  set beforeEvent(PluginHookFunction<EventHookArgs>? value) =>
      _store(29, value);

  /// `afterEvent`.
  PluginHookFunction<EventHookArgs>? get afterEvent => switch (_slots[30]) {
    final PluginHookFunction<EventHookArgs> f => f,
    _ => null,
  };

  set afterEvent(PluginHookFunction<EventHookArgs>? value) => _store(30, value);

  /// `resize`.
  PluginHookFunction<ResizeHookArgs>? get resize => switch (_slots[31]) {
    final PluginHookFunction<ResizeHookArgs> f => f,
    _ => null,
  };

  set resize(PluginHookFunction<ResizeHookArgs>? value) => _store(31, value);

  /// `beforeDestroy`.
  PluginHookFunction<PluginHookArgs>? get beforeDestroy => switch (_slots[32]) {
    final PluginHookFunction<PluginHookArgs> f => f,
    _ => null,
  };

  set beforeDestroy(PluginHookFunction<PluginHookArgs>? value) =>
      _store(32, value);

  /// `afterDestroy`.
  PluginHookFunction<PluginHookArgs>? get afterDestroy => switch (_slots[33]) {
    final PluginHookFunction<PluginHookArgs> f => f,
    _ => null,
  };

  set afterDestroy(PluginHookFunction<PluginHookArgs>? value) =>
      _store(33, value);

  /// `uninstall`.
  PluginHookFunction<PluginHookArgs>? get uninstall => switch (_slots[34]) {
    final PluginHookFunction<PluginHookArgs> f => f,
    _ => null,
  };

  set uninstall(PluginHookFunction<PluginHookArgs>? value) => _store(34, value);

  /// `beforeTooltipDraw`.
  PluginHookFunction<TooltipDrawHookArgs>? get beforeTooltipDraw =>
      switch (_slots[39]) {
        final PluginHookFunction<TooltipDrawHookArgs> f => f,
        _ => null,
      };

  set beforeTooltipDraw(PluginHookFunction<TooltipDrawHookArgs>? value) =>
      _store(39, value);

  /// `afterTooltipDraw`.
  PluginHookFunction<TooltipDrawHookArgs>? get afterTooltipDraw =>
      switch (_slots[40]) {
        final PluginHookFunction<TooltipDrawHookArgs> f => f,
        _ => null,
      };

  set afterTooltipDraw(PluginHookFunction<TooltipDrawHookArgs>? value) =>
      _store(40, value);

  /// Whether the plugin owns [name].
  bool _owns(String name) {
    final slot = _slotOf(name);
    if (slot >= 0) return !identical(_slots[slot], _absent);
    return _extras?.containsKey(name) ?? false;
  }

  // The face of Chart.js ADR 0054 §5.

  @override
  Object? jsRead(String name) {
    final slot = _slotOf(name);
    if (slot >= 0) return _member(slot);
    final extras = _extras;
    return extras != null && extras.containsKey(name)
        ? extras[name]
        : undefined;
  }

  @override
  void jsWrite(String name, Object? value) {
    final slot = _slotOf(name);
    if (slot >= 0) {
      _store(slot, value);
      return;
    }
    final extras = _extras ??= <String, Object?>{};
    if (!extras.containsKey(name)) _order.add(name);
    extras[name] = value;
  }

  @override
  Object? operator [](String name) => jsRead(name);

  @override
  void operator []=(String name, Object? value) => jsWrite(name, value);

  @override
  List<String> jsKeys() {
    if (!_order.any((name) => jsArrayIndex(name) != null)) {
      return List<String>.of(_order);
    }
    // The indices are distinct integers: an unstable sort gives one order.
    final indices =
        [
            for (final name in _order)
              if (jsArrayIndex(name) case final int index) (index, name),
          ]
          // js-ok: distinct keys, as jsObjectKeys sorts them
          ..sort((a, b) => a.$1.compareTo(b.$1));
    return [
      for (final (_, name) in indices) name,
      for (final name in _order)
        if (jsArrayIndex(name) == null) name,
    ];
  }

  @override
  bool jsHas(String name) => _owns(name);

  @override
  bool jsDelete(String name) {
    if (!_owns(name)) return false;
    final slot = _slotOf(name);
    if (slot >= 0) {
      _slots[slot] = _absent;
    } else {
      _extras!.remove(name);
    }
    _order.remove(name);
    return true;
  }
}

/// The value of a field that a [Plugin] does not own.
const Object _absent = _Absent();

/// The type of [_absent].
final class _Absent {
  const _Absent();
}

/// A plugin object that is a Map (an inline plugin of `config.plugins`, a
/// registered Map plugin, or a built-in plugin until lane L4): the hook is
/// `map[hook]`, read at each notify, and its call has JS arity with `this`
/// the Map, as upstream (U `core.plugins.js:59-71`).
extension type const MapPlugin(Map<dynamic, dynamic> map) {
  /// `map[hook]`: Dart `null` for an absent key, which is not a function,
  /// as `undefined` is not.
  Object? hookValue(String hook) => map[hook];

  /// Calls the hook function [function] with `(chart, args, options)`,
  /// `this` the Map.
  Object? invokeHook(
    Object function,
    types.Chart chart,
    Object args,
    Object options,
  ) => jsCall(function, [chart, args, options], thisArg: map);
}

/// Whether [value] is a function value of a hook.
bool isHookFunction(Object? value) => jsIsFunction(value);
