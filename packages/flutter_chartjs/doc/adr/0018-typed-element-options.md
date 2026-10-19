# Chart.js ADR 0018: Typed element options

- Status: proposed
- Date: 2026-10-19
- Related: [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (options and the
  `undefined` sentinel), [Chart.js ADR 0017](0017-element-properties.md) (element properties),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [performance.md](../performance.md) §8

## Context

An element reads its resolved options in each draw and in each hit test. A point element reads
about 11 option values in each draw (`element.point.ts:62-106`).

[Chart.js ADR 0006](0006-options-representation-and-resolver.md) makes a JS plain object a
`Map<String, Object?>`. The resolved options of an element are such an object:
- `_resolveElementOptions` passes the names `Object.keys(defaults.elements[elementType])` to
  `resolveNamedOptions` (`core.datasetController.js:817`, `:821`).
- `resolveNamedOptions` makes `{$shared: true}` and then writes one key for each name, in the
  order of the names (`core.config.js:351-367`).

Each option read is thus a Map lookup with a `String` key. [performance.md](../performance.md)
§8.2 measured the cost at 20000 point elements: about 18 % of the samples on macOS, and 25.7 % of
the main thread on dart2wasm.

The options objects change after their creation:
- The animations write option values in place. `resolveTargetOptions` first copies a shared
  options object with `Object.assign({}, options, {$shared: false, $animations: {}})`
  (`core.animations.js:147-161`).
- `cloneIfNotShared` copies a cached options object for an element that does not share it
  (`core.datasetController.js:811`).
- `_resolveElementOptions` freezes the cached shared options (`core.datasetController.js:831`).
- The line controller writes `segment` into the resolved options of the line
  (`controller.line.js:66`).

Thus a cache of option values that is keyed by the identity of the Map is not safe. The values can
change while the identity stays the same.

## Decision

### 1. Classes

- The port-only file `lib/src/elements/element_options.dart` declares the abstract class
  `ElementOptions`, which extends `MapBase<String, Object?>`. It is a pure layer.
- Four final subclasses stand for the resolved options of the four element types: `PointOptions`,
  `LineOptions`, `BarOptions` and `ArcOptions`. These are the names of the option interfaces of
  `index.d.ts`. A file that also needs a type interface of the same name imports the type library
  with the prefix `types`.
- An instance is a Map. Thus [Chart.js ADR 0006](0006-options-representation-and-resolver.md)
  stays valid: the resolved options stay a Map, and every reader of a Map still works, also
  `jsGet`, the resolver and user code.

### 2. Known keys

- Each subclass has a fixed list of known keys, in this order: `$shared`, the keys of the
  `defaults` of its element class, the keys of its `defaultRoutes`, and the keys that upstream
  code writes into the options of that element type: `segment` of the line
  (`controller.line.js:66`, `controller.scatter.js:86`), and `$animations` of each type
  (`core.animations.js:71`, `:159`).
- Each known key has a field that holds the raw value. A private sentinel marks an absent key.
- Every other key goes to a Map of extra keys, which the instance creates at the first write of
  such a key.

### 3. Map protocol

- `operator []`, `operator []=`, `containsKey`, `remove`, `keys`, `length` and `clear` behave as
  the same operations on a `Map<String, Object?>` that holds the same entries. A read of an absent
  key gives Dart `null`. Thus `jsGet` gives `undefined` for it.
- `keys` gives the present known keys in the order of the list, and then the extra keys in their
  insertion order. `resolveNamedOptions` writes `$shared` first and then the names in the order of
  the list. Thus the key order of options that the resolver makes is the upstream insertion order.
- A write of known keys in another order gives another key order than JavaScript. The readers of
  the key order of element options are the `Object.assign` copies and the loop of
  `_createAnimations` (`core.animations.js`). The order changes only the creation order of the
  animations. This is not a `DIVERGES` hunk, because the class is port-only.

### 4. Typed reads

- Each subclass gives the raw value of each known key through a getter. The getter gives the
  `undefined` sentinel for an absent key, which is the result of `jsGet(options, key)`. The getter
  does no Map lookup.
- The element code reads each option through one small function for each option, for example
  `o is PointOptions ? o.radiusValue : jsGet(o, 'radius')`. Thus the element logic has one code
  path, and a plain Map still works at the speed of a Map. The specs construct elements with plain
  Maps.
- The conversions after the read do not change: `jsToNumber`, `jsOrZero`, `jsTruthy` and the
  WebIDL conversions of `lib/src/js/js_webidl.dart`.
- `PointOptions` also implements `DrawPointOptions` (`helpers.canvas`). Thus a point with typed
  options passes its options to `drawPoint` without an adapter.

### 5. Producers

- Phase 4: the gallery demos make typed options. A constructor of each subclass copies a Map in
  its key order, through `operator []=`.
- Phase 5: `resolveNamedOptions` makes the typed class of the element type when the names are the
  names of an element type. The copies of `cloneIfNotShared` and `resolveTargetOptions` copy into
  the same typed class. These are `adapt` hunks of phase 5 with their `differences.md` rows.

### 6. Tests and figures

- Each element test that compares with reference data runs twice: with plain Map options and with
  typed options. Both runs compare with the same reference data.
- A Map protocol test of each subclass compares it with a plain Map over the same sequence of
  writes, reads, removals and key lists.
- [performance.md](../performance.md) records the figures before and after
  ([porting-flow.md](../porting-flow.md) §1.1).

## Alternatives considered

- **Keep plain Maps.** The cost is measured above. Rejected.
- **A cache of typed values for each options Map.** The animations write into the options in
  place, so the cache can be stale. Rejected.
- **Convert a Map to the typed class when an element gets it.** The element then holds a copy.
  The animations of shared options would not reach the elements that share them. Rejected.
- **Typed classes that are not Maps.** Every generic reader of options (the resolver, `jsGet`, the
  plugins, scriptable options) would need a change, and Chart.js ADR 0006 would need a new ADR
  that supersedes it. Rejected.
- **Generated classes.** A code generator adds a build step for four classes. Rejected.

## Consequences

- The element files read options through small functions. A plain Map still works.
- Phase 5 must make typed options in `resolveNamedOptions` and keep the class in the two copies.
  Otherwise the elements fall back to Map reads.
- The four classes repeat the key lists of the element defaults. A test compares each list with
  the `defaults` and `defaultRoutes` of its element class.

## Open

- `Object.freeze` of the cached shared options (`core.datasetController.js:831`): whether the
  typed class gets a frozen state, in which a write throws a `TypeError` as JavaScript strict mode
  does. Phase 5 decides.
- The way in which `resolveNamedOptions` finds the typed class for a list of names (phase 5).
