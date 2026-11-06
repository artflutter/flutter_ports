# Chart.js ADR 0099: A hidden legend waits with native indexed colors

- Status: proposed
- Date: 2026-11-06
- Related: Chart.js ADRs 0078, 0092, 0093; `differences.md` row `adapt-hidden-legend-items`.
- Measurements: performance.md.

## Context

Chart.js ADR 0092 makes the items of a hidden legend wait for a read, with one proof that a build runs
no user code: the cached `default` entry of the element options. Colors of `ChartValue.indexed` and raw
indexed Lists leave no entry, so a pie of 20k items with such colors still builds its 20k items three
times in each update.

A build is also a writer of state. `getStyle(i)` calls `getContext(i, false, 'default')` for an option
that needs a context. So the last build of an update, in `afterUpdate`, leaves `mode: 'default'` and
`active: false` in the context of each arc, and a build in the layout leaves the parsed and raw values
of this update in it, before the dataset update.

## Decision

A mark of a hidden legend has a second proof, for the options that leave no entry. This supersedes the
statement of Chart.js ADR 0092 that indexed colors stay eager. Its proof of the cached entry stays
first, and scriptable colors stay eager.

**The proof.** `_indexedItemStyles` of `plugin.legend.dart` asks `Config.prepareIndexedArcStyles`, which
reaches the resolver of the `default` mode through the steps of the first `getStyle` of a build:
`datasetElementScopeKeys`, `getOptionScopes`, `_getResolver`. A cold resolver then reads what the first
resolve reads, in its order: the three descriptors, then each own key of `defaults.elements.arc`. These
reads call no option. The first key that is no scalar or native List returns at once, and the ordinary
build goes on and finds these reads in the cache. Then the resolver qualifies the indexed plan of
Chart.js ADR 0093 with its own code (`resolveIndexedElementOptions`, with no result and no context).
Last, `_IndexedElementPlan.covers` checks the static fields and each entry that an index of a label
reaches. The result, `IndexedElementStyles`, holds the plan. The plan holds the raw values of its
resolver, so a clear of the Config caches does not end it.

**The writes.** After all guards of the mark hold, `_IndexedItemStyles.writeContexts` does the writes of
the skipped resolves in place of the build, at each mark, also in the layout: for each label below the
arcs, `getContext(i, false, 'default')` over the native arrays, in item order. So an active arc gets
`active: false` here, as upstream. `ScriptableContext.writeDataState` writes the six fields in one call
and keeps the object of an index that holds its value. An arc with no context takes the ordinary call,
which creates it. From the first index past the arcs, each ordinary call writes the same fields of the
dataset context, so one ordinary call stands for them. A label past the arcs and fewer labels than arcs
thus leave the state of the build. No other state differs: the resolve of an indexed plan writes no
entry into `_cachedDataOpts`, and the caches of the Config and the resolver hold what the first resolve
leaves in them.

**A read.** A build at a read must write no context, as the read of a snapshot writes none, and must
read no new resolver (Chart.js ADR 0092). So it takes the styles of the plan of its mark:
`DatasetController.legendStyles` holds them during that build, and `getStyle` answers from them with
the index of the context of that item. A read checks that the controller is the one of its mark, that
the resolver still has the plan and that the entries still cover its labels. The other guards of a read
stay.

## Guards

The guards of Chart.js ADR 0092, except the cached entry, and all of these, each at its own mark:

- The exact chart (`nativePointChart`), the exact `Config`, `nativeDataUpdateRoot`, and native objects
  and Lists for the data, `datasets`, dataset 0 and its `data`.
- The native `arc` class (`nativeArcClass`), native arrays for the arcs and the parsed items, a native
  index of the dataset, and no route on `defaults.elements` or its `arc`, which is an exact
  `ArcOptionsScope`.
- Every scope of the resolver is native (`nativeOptionScope`): a custom Map runs code at a read.
- The descriptors of the resolver are the built-in predicates or booleans
  (`Defaults.nativeElementDescriptors`). No slot of the resolver is touched.
- Each key of the arc scopes is an `OptionKey`, with a scalar value or a native List. A function under
  any key, a key of user code, an object and a custom List return at once.
- A List is indexable by its descriptor. `borderDash` stays a raw reference, as in Chart.js ADR 0093.
- An entry that an index of a label reaches passes `_nativeIndexedValue`.
- Each arc is native (`nativeArcElement`), checked at its own write. A custom arc returns to the
  ordinary build, which runs from its first item. It writes the same values again before that arc, with
  no user code between.

## Fallback

A failed guard at a mark builds at once, at the upstream point, with the upstream order and count of each
call. The guards read only what that build reads first, in its order.

## Difference

The items follow row `adapt-hidden-legend-items` and Chart.js ADR 0092, with these changes for a mark of
this proof:

- A read that the cached entry could not answer now runs, with the values of its mark: in the dataset
  update, and in a hook of the next update before its layout. It gives what upstream built at that point.
- A read after an in-place change of a color List with no update gives the new entries, as a read after
  any in-place change does.
- A read after an entry at an index of a label became an object or a function, or after a write through
  the resolver, gives the last built items, and the build still waits. This can be older than the snapshot
  of upstream.

The writes change nothing that a reader can see: hook order, callback order and count, contexts, options
and pixels stay. Twin tests compare each of them, also inside each hook. For this change, one run of the
727 observation configs with a hidden legend forced on each chart gave the same text through this proof
and through the ordinary build. The committed digests have no such run: most of those configs turn the
legend off.

## Alternatives

- **Skip the writes in the layout.** The dataset update writes each arc again, so only user code in that
  window sees them: a plugin hook, a scale callback, a scriptable option of a box. Proving that no such
  code exists needs a guard over all boxes, plugins and scale options, for a small cost of the loop.
- **Write the state at a read of the context.** A context that user code keeps from an earlier update has
  no such read, and each context read would pay for a check.
- **A typed item in place of the Map.** This lowers the cost of a build, and does not remove it.
