// Original code, not ported from Chart.js: the defaults of a test plugin.

/// The defaults of a test plugin from the plain object of an upstream spec
/// (Chart.js ADR 0148).
///
/// A plugin gives its defaults as a typed scope or as its `PluginOptions`.
/// A spec plugin of upstream gives a plain object: [pluginDefaults] puts its
/// entries into a `GenericPluginOptionsScope`, which the resolver reads as
/// it reads the object.
library;

import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show GenericPluginOptionsScope;
import 'package:flutter_chartjs_port/src/types/plugin.dart' show PluginDefaults;

/// The defaults with the entries of [entries], in their order.
///
/// ```dart
/// final defaults = pluginDefaults({'x': 1.0});
/// final plugin = Plugin<Object?>(id: 'a', defaults: defaults);
/// ```
PluginDefaults pluginDefaults(Map<String, Object?> entries) {
  final scope = GenericPluginOptionsScope();
  for (final MapEntry(:key, :value) in entries.entries) {
    scope.jsWrite(key, value);
  }
  return scope;
}
