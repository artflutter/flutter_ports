# Chart.js ADR 0102: Direct typed writes of arcs and bubbles

- Status: proposed
- Date: 2026-11-06
- Related: Chart.js ADRs 0028, 0054, 0093, 0094; `differences.md` rows
  `adapt-direct-element-writes` and `adapt-polar-constant-options`.
- Measurements: performance.md.

## Context

Line, scatter and radar write a built-in element through its typed setters (Chart.js ADR 0054 §9). The
doughnut, pie, polar area and bubble controllers build an object for each element and give it to
`updateElement`. In a direct update, `updateElement` only assigns the object: the record appends each
key to its key order, and `Element.assign` reads each key back by its position. No reader sees that
object, and the assign writes the fields that the setters write. A live polar area chart also looks up
its frozen options entry twice for each arc, and stores the same two spacing values into each copy.

## Decision

### The writes

The exact controller, in the mode `none` or `reset`, writes a built-in element at the place of
`updateElement`, with no object. The writes keep the place of the upstream call: after the resolve of
the options, so a user callback in that resolve still reads the old properties of its element, and
after the two fix-ups of the polar area. The values stay locals from the upstream read, also where a
user callback runs after the read (`centerX + this.offsetX`).

| Controller | Keys of the literal, in order |
| --- | --- |
| Doughnut and pie | `x`, `y`, `startAngle`, `endAngle`, `circumference`, `outerRadius`, `innerRadius`, `options` |
| Polar area | `x`, `y`, `innerRadius`, `outerRadius`, `startAngle`, `endAngle`, `options` |
| Bubble | the index axis, the value axis, `skip`, `options` |

`Element.assign` writes these keys through the same setters, and an `Element` has no own-key order that
a reader can see (`jsObjectKeys` of an element gives no keys in this port). Thus the direct writes keep
each property, each `undefined` bit, `getProps`, `$animations` and each extra property of the element.

The port-only interface `types.ArcElementWrites` has the setters, as `types.PointElementWrites` has them
for a point, so that a controller imports no element module (Chart.js ADR 0028). `lib/chartjs.dart`
hides it, as the other two.

The guards are the narrowest that give the guarantee:

- The exact controller (`supportsDataUpdates`): a subclass can override `updateElement`.
- The mode `none` or `reset`: the two modes in which `updateElement` assigns. Another mode can animate.
- `typedWrites` of the element, read at its iteration: the exact-class rule. A user element keeps the
  writes by name, in the key order, so that its `operator []=` sees each write.
- A value that a setter does not take: the `undefined` center of a polar area before the first layout,
  and the `undefined` radii of a doughnut before the first update.
- A bubble axis other than `x` and `y`: it is a write by name.

The reads of the chart, of the Config and of the scales do not change, so none of their classes is a
guard here.

### The frozen entry of a polar area

A polar area loop in the mode `none` may take one more plan after its two ordinary resolves, when
the color plan of Chart.js ADR 0093 declines: the frozen entry of `arc-none`. Each later resolve of the
loop is then a hit, which writes no context and only copies the entry, and each later `_computeAngle`
reads one value of it. Thus the angle comes once, and each arc gets a fresh copy of a template.

The template is a copy of the entry with the spacing fix-ups. This supersedes one statement of Chart.js
ADR 0093, "The spacing fix-ups of the polar area stay per item on the fresh result": it still holds for
the color plan, and the frozen entry plan runs them once. Each later fix-up would read the same scalar
and store the same value.

The plan needs the prerequisites of the color plan of ADR 0093 (the exact controller, a native class and
radial scale, parsing on, `start` 0), and:

- the exact chart, whose `getDataVisibility` runs no user code;
- the arcs of the meta in a native List, and a native parsed List;
- no option sharing: a shared result is the frozen entry itself, and its fix-up throws, as upstream;
- scalar raw `spacing` and `spacingMode` in native scopes (`rawOptionsAreScalar`);
- an `angle` that is a number or `undefined`, whose `ToNumber` is no user code.

A custom or active arc ends the plan for good before its first read, as in ADR 0093.

### The reads of a draw

The option functions of `element.arc.dart` read the raw value of a key that is not a `double` through
the generated getter of `ArcOptions` (`borderColorValue` and the others). It has the same three states
as `rawOption`: `undefined` for an absent key, the foreign value, and the field. `rawOption` and
`plainOption` stay for the numeric keys, where the getter would box a `double`. `supportsNativeArcOptions`
reads the exact-class flag of the element once, not a `Type` compare at each read.

## Fallback

A user subclass of a controller or an element, an overridden `updateElement`, another mode, an
`undefined` value and a bubble axis of another name take `updateElement` with the record, at its upstream
place. For the frozen entry plan: a user chart or scale, a custom list, parsing off, a scriptable or
object `spacing` or `spacingMode`, a foreign `angle`, a varying option and an active arc take the
ordinary resolve of each arc.

## Differences

No result, order, count of a user call, thrown error or pixel changes. One difference in debug builds
only, as in row `adapt-arc-native-options`: with the frozen entry plan, the audit hook of a foreign
`spacing` or `spacingMode` runs at the template and not at each arc. A release build has no audit call,
and the set of the reviewed pairs does not change.

## Not done

- A pie, doughnut or bubble loop keeps the store of `options` for each element: it costs one field write.
- A doughnut loop keeps its two reads of a parsed item in `_circumference`.
- The numeric options of a draw (`offset`, `spacing` and `borderWidth`) keep their present and foreign
  tests: one mask test would need a generated member.

## Tests

`test/port/controllers/direct_element_writes_test.dart` compares each of the four types with a trivial
user subclass of its controller, in each mode, with hidden items, a NaN and a null value, growing and
shrinking data, active elements, a user callback that reads its element and a callback that throws: each
property by name, the keys and the key order of the options, `getProps`, the animation state, the context
and the pixels. Probes show that each direct path ran and that each guard falls back, and a test opt-in
that breaks the contract shows that the frozen entry plan ran. The observation test keeps its digests.
