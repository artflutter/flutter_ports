// Original code, not ported from Chart.js: the theme switch of ChartView.

/// The runtime theme switch of `ChartView` (Chart.js ADR 0050, "Runtime
/// switch"; theming.md §3.7).
///
/// The widget runs the switch in its post-frame update callback (Chart.js
/// ADR 0049, section 4). Not a pure layer: the file imports the theme data,
/// which imports Flutter. Ported files never import it (Chart.js ADR 0042,
/// invariant 4).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/theme/theme_data.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// The value of an absent key in the records of [ChartThemeSwitch].
const Object _absent = _Absent();

/// The type of [_absent].
final class _Absent {
  const _Absent();
}

/// The two dataset keys that the colors plugin writes
/// (plugin.colors.ts:36-37, 43, 49).
const String _borderColor = 'borderColor';

/// See [_borderColor].
const String _backgroundColor = 'backgroundColor';

/// The value of [key] in [dataset], or [_absent].
Object? _read(AnyObject dataset, String key) {
  final value = dataset[key];
  if (value != null || dataset.containsKey(key)) return value;
  return _absent;
}

/// One palette key of a dataset that the colors plugin wrote: the value
/// before the first write and the value of the last write.
final class _Write {
  _Write(this.original, this.written);

  /// The value before the first write, or [_absent].
  final Object? original;

  /// The value of the last write.
  Object? written;
}

/// The theme state of the chart of one `ChartView` (Chart.js ADR 0050,
/// "Runtime switch"). The widget and, later, the frameless benchmark use it.
///
/// It keeps the effective theme of the last switch, the user `scales` object
/// of the options (step 3) and the records of the palette keys that the
/// colors plugin wrote (step 4). The inline plugin of the widget feeds the
/// records in each update (`chart_view_plugin.dart`).
@internal
final class ChartThemeSwitch {
  /// The effective theme of the start or of the last switch.
  ChartThemeData? _applied;

  /// The user `scales` object of the options, or [_absent].
  Object? _scales = _absent;

  /// The values of the palette keys at `beforeUpdate`: the dataset, then
  /// its `borderColor` and its `backgroundColor`, for each dataset Map.
  final List<Object?> _before = [];

  /// The palette keys that the colors plugin wrote, by dataset Map.
  final Expando<Map<String, _Write>> _written = Expando<Map<String, _Write>>(
    'ChartThemeSwitch',
  );

  /// The effective theme of the start or of the last switch, or Dart `null`.
  ChartThemeData? get applied => _applied;

  /// The theme of the root config of a new chart, before `new Chart`:
  /// records [theme] as the applied theme and writes its compiled map under
  /// `$theme` of [root], or removes the key when it compiles to Dart `null`.
  void start(AnyObject root, ChartThemeData? theme) {
    _applied = theme;
    _writeTheme(root, compileThemeData(theme));
  }

  /// Records the user `scales` object of [options] (the identity, or
  /// absent). The widget calls it before `new Chart` and for each new
  /// options object (step 3). `initOptions` then replaces the object in the
  /// options with its merged copy (core.config.js:115-120).
  void recordUserScales(Object? options) {
    _scales = options is AnyObject ? _read(options, 'scales') : _absent;
  }

  /// Steps 1 to 4 of the switch to [theme] on [chart], whose raw config is
  /// [root]. Gives the update mode of step 5, or Dart `null` when the theme
  /// needs no update.
  ///
  /// 1. A theme that is `==` to the applied theme gives Dart `null`. When
  ///    both compile to Dart `null`, the call records [theme] and gives
  ///    Dart `null`.
  /// 2. The compiled map goes under `$theme` of [root], or the key goes.
  /// 3. The recorded user `scales` object goes back into the options, or
  ///    the key goes when the app had none (#11910: `mergeScaleConfig`
  ///    merged the old theme into the copy).
  /// 4. Each palette key that still holds the value that the colors plugin
  ///    wrote goes back to its value before the first write, or goes when
  ///    it was absent. An app edit stays. The records of the datasets go.
  /// 5. The mode: `'default'` when the new theme compiles to Dart `null`,
  ///    else `'themeFrame'` with [reducedMotion], else `'theme'`. Never
  ///    `'none'` or `'resize'`.
  String? apply(
    types.Chart chart,
    AnyObject root,
    ChartThemeData? theme, {
    required bool reducedMotion,
  }) {
    final old = _applied;
    if (theme == old) return null;
    _applied = theme;
    final compiled = compileThemeData(theme);
    if (compiled == null && compileThemeData(old) == null) return null;
    _writeTheme(root, compiled);
    final options = root['options'];
    if (options is AnyObject) {
      final scales = _scales;
      if (identical(scales, _absent)) {
        options.remove('scales');
      } else {
        options['scales'] = scales;
      }
    }
    _restorePalette(chart);
    if (compiled == null) return 'default';
    return reducedMotion ? 'themeFrame' : 'theme';
  }

  /// The `beforeUpdate` hook of the widget plugin: the values of the two
  /// palette keys of each dataset Map before the colors plugin runs.
  void beforeUpdate(types.Chart chart) {
    final before = _before..clear();
    final datasets = jsGet(chart.data, 'datasets');
    if (datasets is! List) return;
    for (final dataset in datasets) {
      if (dataset is! AnyObject) continue;
      before
        ..add(dataset)
        ..add(_read(dataset, _borderColor))
        ..add(_read(dataset, _backgroundColor));
    }
  }

  /// The `beforeLayout` hook of the widget plugin, after the `beforeLayout`
  /// of the registered colors plugin (core.plugins.js:124-144): each
  /// palette key that changed in this update gets a record, with its value
  /// before the first write. A key that changed again from its last written
  /// value keeps the first value (`forceOverride` writes in each update).
  void afterColorize(types.Chart chart) {
    final before = _before;
    for (var i = 0; i < before.length; i += 3) {
      final dataset = before[i]! as AnyObject;
      _record(dataset, _borderColor, before[i + 1]);
      _record(dataset, _backgroundColor, before[i + 2]);
    }
    before.clear();
  }

  /// Records the write of [key] into [dataset] when its value is not
  /// [previous], the value at `beforeUpdate`.
  void _record(AnyObject dataset, String key, Object? previous) {
    final current = _read(dataset, key);
    if (identical(current, previous)) return;
    final written = _written[dataset] ??= <String, _Write>{};
    final record = written[key];
    if (record != null && identical(previous, record.written)) {
      record.written = current;
    } else {
      written[key] = _Write(previous, current);
    }
  }

  /// Step 4: the palette keys of the datasets of [chart] that still hold the
  /// written value go back to their values before the first write.
  void _restorePalette(types.Chart chart) {
    final datasets = jsGet(chart.data, 'datasets');
    if (datasets is! List) return;
    for (final dataset in datasets) {
      if (dataset is! AnyObject) continue;
      final written = _written[dataset];
      if (written == null) continue;
      _written[dataset] = null;
      for (final MapEntry(:key, :value) in written.entries) {
        if (!identical(_read(dataset, key), value.written)) continue;
        final original = value.original;
        if (identical(original, _absent)) {
          dataset.remove(key);
        } else {
          dataset[key] = original;
        }
      }
    }
  }

  /// Writes [compiled] under `$theme` of [root], or removes the key.
  static void _writeTheme(AnyObject root, AnyObject? compiled) {
    if (compiled == null) {
      root.remove(themeConfigKey);
    } else {
      root[themeConfigKey] = compiled;
    }
  }
}
