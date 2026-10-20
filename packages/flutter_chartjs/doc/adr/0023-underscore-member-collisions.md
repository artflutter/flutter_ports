# Chart.js ADR 0023: Underscore members with a colliding name

- Status: proposed
- Date: 2026-10-20
- Related: [Chart.js ADR 0012](0012-dart-file-naming.md) (names, underscore members),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) (component classes)

## Context

[Chart.js ADR 0012](0012-dart-file-naming.md) gives this rule: a `_`-prefixed member that another
module reads drops the underscore and carries `@internal`. A Dart library cannot read a private
member of another library. Thus the rule is necessary for each such member.

The rule fails when the class already has a member with the name without the underscore. Dart
forbids two members with one name in a class. The port must give a new name to the `_` member of
three such pairs: two pairs of `core.datasetController.js` and one pair of the meta of
`core.controller.js`. The line numbers refer to Chart.js v4.5.1.

- `_update(mode)` (`core.datasetController.js:701`) and `update(mode)` (`:710`).
  `core.controller.js:677` calls `meta.controller._update(mode)`. The dataset controllers of
  phase 7 override `update`.
- `_getSharedOptions(start, mode)` (`core.datasetController.js:885`) and
  `getSharedOptions(options)` (`:867`). The line, bar, bubble and doughnut controllers call
  `this._getSharedOptions(start, mode)` (`controller.line.js:79`, `controller.bar.js:399`,
  `controller.bubble.js:121`, `controller.doughnut.js:264`). Their files are other Dart
  libraries.
- `_dataset` (`core.controller.js:845`) and `dataset` (`:838`) of the meta, the object literal
  of `getDatasetMeta`. The port declares the meta as the class `ChartMeta` of
  `core.controller.dart`. The line and scatter controllers read `_dataset` by destructuring
  (`controller.line.js:43`, `:78`, `controller.scatter.js:77`, `:113`). The spec reads
  `metasets[i]._dataset` (`core.controller.tests.js:1973`). These files are other Dart libraries.

A survey of `src/` at v4.5.1 found 14 other pairs. Thirteen `_` members of these pairs have
readers only in their own file of `src/`. Examples are `_notify` and `notify` (`core.plugins.js`),
and `_draw` and `draw` (`plugin.legend.js`). These members keep the underscore under Chart.js ADR
0012. They need no new name. The spec `element.line.tests.js:28` reads `_path` of the line
element. The port gives that member by name, `line['_path']` ([Chart.js ADR
0017](0017-element-properties.md) §5). Thus `_path` also keeps its underscore. The last pair is
`_active` and `active()` of `core.animation.js`.
`core.animator.js:72` reads `item._active`. The method `active()` returns that field
(`core.animation.js:47-49`). Thus the port of `core.animator.js` calls `item.active()`, and the
field keeps its underscore.

The analyzer accepts a trailing underscore and a `$` prefix in a member name (probe on Dart 3.12.2
with very_good_analysis 10.3.0). The lint `non_constant_identifier_names` gives no info for
`update_`, `$update` or `update$`.

## Decision

- A `_`-prefixed member that another module reads drops the leading underscore (Chart.js ADR
  0012). When the class or a superclass already has a member with that name, the Dart name gets a
  trailing underscore instead. Examples are `_update` → `update_`, `_getSharedOptions` →
  `getSharedOptions_` and `_dataset` → `dataset_`.
- The member carries `@internal`, as Chart.js ADR 0012 asks.
- The `///` line names the upstream member and says why the name has the trailing underscore.
- The rule applies to the members of the port and to the members of the types libraries.
- A `_` member that only its own file reads keeps its name (Chart.js ADR 0012).
- The other rules of Chart.js ADR 0012 do not change.

## Alternatives considered

- **A descriptive name**, for example `updateWithClip` for `_update`. The name does not follow
  from the upstream name. Tool 2, the bump report and a reader cannot map it back. Rejected.
- **A `$` prefix**, for example `$update`. Chart.js uses the `$` prefix for properties that it keeps
  on an object for another module, for example `$context`, `$animations` and `$shared`. A `$`
  name for a method gives a second meaning to the prefix. Rejected.
- **A private member and an `@internal` function of the library**, for example a top-level
  `updateDatasetController(controller, mode)`. The call site of upstream is a method call. The
  function also cannot be a virtual member, so a subclass cannot override it. Rejected.
- **A rename of the public member.** The public member is the upstream API, for example
  `getSharedOptions` of `index.d.ts:633`. Rejected.

## Consequences

- The Dart name of each colliding member follows mechanically from the upstream name.
- The controllers of phase 7 call `getSharedOptions_(start, mode)`. `core.controller.dart` calls
  `controller.update_(mode)`.
- The meta of `core.controller.dart` has the field `ChartMeta.dataset_`. `core.controller.dart`
  reads it (`core.controller.js:409`, `:832`). The line and scatter controllers of phase 7 will
  read `meta.dataset_`. The `metasets` cases of `core.controller_test.dart` will read
  `metasets[i].dataset_` (`core.controller.tests.js:1973`). These cases skip as
  `'blocked: controller.line'`.
- A later upstream member that collides follows the same rule. Its port records no new decision.

## Evidence

- `core.datasetController.js:701`, `:710`, `:867` and `:885` at v4.5.1.
- `core.controller.js:677`, `controller.line.js:79`, `controller.bar.js:399`,
  `controller.bubble.js:121` and `controller.doughnut.js:264` at v4.5.1.
- `core.controller.js:838` and `:845`, `controller.line.js:43` and `:78`,
  `controller.scatter.js:77` and `:113`, and `test/specs/core.controller.tests.js:1973` at v4.5.1.
- The survey, scan 1: a scan of the method declarations and the `this.<name> =` writes of each
  file of `src/` for the names `_x` and `x`. It found 15 pairs in 8 files. Scan 1 did not examine
  the keys of object literals, the writes `<object>.<name> =` and the reads by destructuring.
  Thus it did not find the pair `_dataset` of the meta.
- The survey, scan 2: a scan of the keys of object literals, the writes `<object>.<name> =`, the
  property reads and the reads by destructuring. The scan records the receiver of each name. It
  found two more pairs. One pair is `_dataset` and `dataset` of the meta. The other pair is
  `_data` and `data` of a dataset object (`plugin.decimation.js:216`, `:253`). Only
  `plugin.decimation.js` reads that `_data`. The other names of scan 2 are on different objects.
  An example is the field `_padding` of the radial scale and the option `pointLabels.padding`
  (`scale.radialLinear.js:428`, `:393`).
- The result of the two scans: 17 pairs. Four pairs have a `_` member with readers in another
  file of `src/`: the two pairs of `core.datasetController.js`, the pair `_dataset` of the meta
  and the pair `_active` of `core.animation.js`. The specs read two `_` members of the pairs:
  `_dataset` (`core.controller.tests.js:1973`) and `_path` (`element.line.tests.js:28`).
- The probe: a class with the methods `update_`, `$update` and `update$` passed
  `dart analyze --fatal-infos` with the options of the repository.
