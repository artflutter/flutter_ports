// Original code, not ported from Chart.js: the typed element options.

/// The typed resolved options of the four element types (Chart.js ADR 0054
/// §9, in place of Chart.js ADR 0018).
///
/// The classes come from `lib/src/options/`: [ElementOptions] and
/// [GenericElementOptions] (`element_options_base.dart`), and the generated
/// [PointOptions], [LineOptions], [BarOptions] and [ArcOptions]
/// (`resolved.g.dart`, from the kinds of `tool/options_schema.yaml`). Each
/// known key is a typed field with a foreign slot (Chart.js ADR 0054 §6);
/// the Map protocol of the scaffolding (§5) gives the raw value of each key
/// in the key order of Chart.js ADR 0018 §3.
///
/// The producers of the resolver use the classes (Chart.js ADR 0021):
/// - [createElementOptions] gives the new, empty options object of an
///   element type id. `_resolveElementOptions` passes it to
///   `resolveNamedOptions` (core.datasetController.js:821).
/// - [copyOptions] is `Object.assign({}, options)`. The copy of an
///   [ElementOptions] is its [ElementOptions.clone], of the same class.
/// - An [ElementOptions] is a `JsFreezable`. `Object.freeze` of the cached
///   options (core.datasetController.js:831) sets its frozen state.
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/options/element_options_base.dart';
import 'package:flutter_chartjs_port/src/options/resolved.g.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';

export 'package:flutter_chartjs_port/src/options/element_options_base.dart'
    show ElementOptions, GenericElementOptions;
export 'package:flutter_chartjs_port/src/options/resolved.g.dart';

/// The new, empty options object of the element type [elementType] (Chart.js
/// ADR 0021, section 1).
///
/// `_resolveElementOptions` passes it to `resolveNamedOptions` as `into`
/// (core.datasetController.js:821), where upstream makes the object literal
/// `{$shared: true}` (core.config.js:352). The ids `'point'`, `'line'`,
/// `'bar'` and `'arc'` of the four element classes (element.point.ts:22,
/// element.line.js:245, element.bar.js:143, element.arc.ts:375) give their
/// typed classes. Another value gives a [GenericElementOptions]. The result
/// is not frozen.
// DIVERGES(chartjs): adapt-typed-element-options, the class of the id.
ElementOptions createElementOptions(Object? elementType) =>
    switch (elementType) {
      'point' => PointOptions(),
      'line' => LineOptions(),
      'bar' => BarOptions(),
      'arc' => ArcOptions(),
      _ => GenericElementOptions(),
    };

/// `Object.assign({}, options)` for an options object (Chart.js ADR 0021,
/// section 3): `cloneIfNotShared` (core.datasetController.js:230),
/// `getSharedOptions` (:871), `resolveTargetOptions` (core.animations.js:159)
/// and the bubble controller (controller.bubble.js:157).
///
/// An [ElementOptions] gives its [ElementOptions.clone], of the same class.
/// Another Map gives a new plain Map with the keys of [jsObjectKeys], in that
/// order, and the values of `options[key]`. Thus a resolver gives the values
/// of its `get` trap. The copy is not frozen.
// DIVERGES(chartjs): adapt-typed-element-options, the copy keeps the class.
AnyObject copyOptions(AnyObject options) => options is ElementOptions
    ? options.clone()
    : {for (final key in jsObjectKeys(options)) key: options[key]};
