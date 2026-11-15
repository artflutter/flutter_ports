// Original code, not ported from Chart.js: the update mode as a native type.

/// The update mode of `chart.update(mode)` (`UpdateMode` of
/// `index.d.ts:620`), as a native type (Chart.js ADR 0148).
///
/// A mode is its name. An add-on adds a mode as a constant, as
/// chartjs-plugin-zoom adds `zoom` to `UpdateModeEnum`. A transition of
/// `options.transitions` keeps its key by the name.
///
/// This library is a core layer.
library;

/// A mode of `chart.update(mode)`: an extension type over its name. It
/// implements `String`, so a mode goes where the core reads a mode name.
///
/// ```dart
/// chart.update(UpdateMode.none);
/// chart.update(const UpdateMode('zoom')); // options.transitions.zoom applies
/// ```
extension type const UpdateMode(String name) implements String {
  /// `resize`: an update after a resize.
  static const resize = UpdateMode('resize');

  /// `reset`: the elements go to their start state.
  static const reset = UpdateMode('reset');

  /// `none`: an update with no animation.
  static const none = UpdateMode('none');

  /// `hide`: a dataset hides.
  static const hide = UpdateMode('hide');

  /// `show`: a dataset shows again.
  static const show = UpdateMode('show');

  /// `default`: the mode of an update with no mode.
  static const defaultMode = UpdateMode('default');

  /// `active`: an element is active, for example the pointer is over it.
  static const active = UpdateMode('active');
}

/// The mode of each dataset of one update: the function form of
/// `chart.update((ctx) => mode)` (`index.d.ts:559`). Dart `null` is the
/// `undefined` of upstream: the dataset takes the default mode.
///
/// ```dart
/// chart.updateDatasets((i) => i == 2 ? UpdateMode.hide : null);
/// ```
typedef UpdateModeOf = UpdateMode? Function(int datasetIndex);
