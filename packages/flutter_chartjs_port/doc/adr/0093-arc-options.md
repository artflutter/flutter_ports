# Chart.js ADR 0093: Native arc options

- Date: 2026-11-06
- Status: proposed
- Related: ADRs 0054, 0062, 0076, 0078, 0079, 0081, 0083, 0087.
- Measurements: performance.md.

## Decision

Arcs take the native option paths of points and bars, and the pie, doughnut and
polar area loops stop resolving options that cannot differ. Upstream resolves the
options of each arc up to three times in each update: this keeps the observable
results and removes the repeated work. The port-only `core/arc_options.dart` has
the arc capabilities, and `core/arc_option_preparation.dart` the preparation.

### The resolver plans

`ArcOptionsScope` is a native key producer, `ArcOptions` is a native result, and
a third private frozen type token serves `resolveOwnedArcNamedOptions`. The
indexed and scriptable plans accept the arc keys by the store of their slot: a
number for a `double` slot, a string for a `String?` slot and a bool for a `bool`
slot, so that a store has no conversion. The two `undefined` defaults, `angle`
and `borderJoinStyle`, are allowed foreign values.

The descriptor guard admits the exact predicates of the arc and the doughnut by
identity. Their classes name them through `Defaults.nativeElementPredicate`,
because `core.defaults.dart` imports no element or controller. Any other function
keeps the ordinary path.

`borderDash` is not indexable for these predicates. Its non-indexable native list
stays a raw reference in the template. Its items stay live: unless item 0 is an
object, the ordinary read gives the same list, and that is checked after the
context call and after each callback. Another result continues on the ordinary
path, at the next original key. A non-indexable list in another key, and a custom
List, keep the ordinary path.

The scriptable plan now also asks the descriptor of each color callback. A
function under `_scriptable: false` stays a raw value, as upstream.

### The scans

`getMaxBorderWidth` and `getMaxOffset` end after a result that must repeat. They
ask for the first two items only, then run as upstream.

- A frozen cached entry, under an exact built-in controller and arc class (also of
  another dataset). Each later call is a hit that gives the same object. A hit has
  no effect, and `Math.max` of the same inputs repeats.
- A plan where only native colors vary. Each later call differs in the colors,
  which no scan reads, and in the context refresh of its arc. That refresh is left
  to `updateElements`, which writes each of these contexts again. This needs:
  mode `none`, inside `update` (a public call keeps each refresh); the controller
  of the scan is `this`; one dataset; the exact chart, Config and arcs; native
  arrays and sources; parsing on; and scalar raw values for the five dataset
  options read between the scans and the loop. Thus no user code runs in the
  window with the old contexts.

### The loops

Under the same native reads, in mode `none`:

- The doughnut reads the circumference once for a loop with shared options or a
  color plan.
- After two ordinary resolves, a doughnut or polar area loop with no shared
  options may take a loop-local color plan: `getContext` and a fresh copy of the
  template with the two colors. A custom or active arc ends it for good, before
  its first read. There is one attempt for each loop.
- An exact polar area reads the angle of a cache hit from the frozen entry, with no
  copy. With a color plan, the angle is static and is computed once, and the
  context refresh of `_computeAngle` goes: the second resolve writes each field,
  and between the two runs only the exact radial scale with a scalar `reverse`.

The spacing fix-ups of the polar area stay per item on the fresh result.

### Smaller items

- A clone of a generated options class shares the foreign slot list, and the first
  write copies it. The generator writes this; the file has no other change.
- The generated `storeKey` stores `$shared` directly. A frozen object still throws
  a `TypeError`, and a user subclass of `ElementOptions` keeps its `jsWrite`.
- `jsToString` tests for a `String` first. The miss path of
  `_resolveElementOptions` is its own method, so a hit allocates no closure context.
- `_IndexedElementPlan` uses integer modulo below 2^53, and the double form above.
- Config retains the last join of two owned prefixes, as it retains the scope key.

## Fallback

A user subclass of a controller, arc, scale, chart or Config class, a user
descriptor, a foreign value, an object, a custom list, a hover prefix, a mode other
than `none` where this needs it, a varying key other than a color, more than one
dataset for the plan stop, and a scriptable dataset option all keep the ordinary
path at its original observation point. A failed attempt keeps the one context
that it created. Every result stays a fresh object with `$shared: false`, the
original key order and independent mutable fields.

## Differences

One, in debug builds only, in row `adapt-arc-native-options`: the audit hook of the
foreign `undefined` of `angle` and `borderJoinStyle` runs at the template build and
not at each copy. A release build has no audit call, and the set of the reviewed
pairs of the oracle does not change.

`_scriptable: false` with a function color differed from upstream in the plan of
ADR 0083. It now matches upstream, on all native result classes.

## Tests

`test/port/controllers/arc_options_test.dart` compares the three chart types with
an ordinary Config, an ordinary controller and both, in the geometry, the full
options, the contexts and the user call traces, across update modes. Probe counts
of the context reads show that each native path runs and that each guard declines.
`test/port/core/arc_element_options_test.dart` has the resolver twins, and
`test/port/options/foreign_slots_test.dart` the slots of the generated classes.
