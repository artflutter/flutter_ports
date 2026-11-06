# Chart.js ADR 0099: A hidden legend waits with native indexed colors

- Status: accepted
- Date: 2026-11-06
- Related: Chart.js ADRs 0078, 0092, 0093; `differences.md` row `adapt-hidden-legend-items`.
- Measurements: performance.md §65.

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

**The proof.** An ordinary build writes the context of its first resolve early: `needContext` stops at
the first indexable List and calls `getContext(0, false, 'default')`. It reads the next keys of the arcs,
then `filter`, `sort` and `reverse`, after that write. So what the proof reads before the writes of the
mark must have no reader. `_indexedItemStyles` of `plugin.legend.dart` first asks the box: native scopes
behind the legend and label resolvers, `display` exactly `false`, falsy `filter` and `sort`, plain
`reverse`. It asks through `OptionResolver.peekKey`, which gives the raw value with no write to the cache
and no sub resolver. So a visible legend never takes this proof.

Then `Config.prepareIndexedArcStyles` reaches the resolver of the `default` mode through the steps of the
first `getStyle` of a build, in their order: `datasetElementScopeKeys`, `getOptionScopes`, `_getResolver`.
A cold resolver reads the three descriptors, the first reads of that resolve, and peeks at each own key of
`defaults.elements.arc`. A key with an object returns at once: the creation of its sub resolver can call a
function `_fallback` or read a custom Map, and the ordinary build does it at its own point, after the
context if the key comes after the first List. A function and a custom List also return at once. When
each key is a scalar or a native List, the resolver reads them: this runs no user code, and it fills the
cache that the first resolve fills. Then it qualifies the indexed plan of Chart.js ADR 0093 with its own
code (`resolveIndexedElementOptions`, with no result and no context). Last, `_IndexedElementPlan.covers`
checks the static fields and each entry that an index of a label reaches. The result,
`IndexedElementStyles`, holds the plan. The plan holds the raw values of its resolver, so a clear of the
Config caches does not end it.

**The writes.** After all guards of the mark hold, `_IndexedItemStyles.writeContexts` does the writes of
the skipped resolves in place of the build, at each mark, also in the layout: for each label below the
arcs, `getContext(i, false, 'default')` over the native arrays, in item order. So an active arc gets
`active: false` here, as upstream. `ScriptableContext.refresh` writes the six fields in one call
and keeps the object of an index that holds its value. An arc with no context takes the ordinary call,
which creates it. From the first index past the arcs, each ordinary call writes the same fields of the
dataset context, so one ordinary call stands for them. A label past the arcs and fewer labels than arcs
thus leave the state of the build. No other state differs: the resolve of an indexed plan writes no
entry into `_cachedDataOpts`, and the caches of the Config and the resolver hold what the first resolve
leaves in them.

**A read.** A build at a read must write no context, as the read of a snapshot writes none, and must
read no new resolver (Chart.js ADR 0092). So it takes the styles of the plan of its mark:
`DatasetController.legendStyles` holds them during that build, with the count of the arcs at the mark,
and `getStyle` answers from them with the index that the context of that item had at the mark: the index
of the item below that count, else the index of the dataset. A next update rebuilds the arcs before its
own mark, and a read in that window gives what the last `afterUpdate` built. A read checks that the
controller is the one of its mark, that the resolver still has the plan and that the entries still cover
its labels. The other guards of a read stay.

## Guards

The guards of Chart.js ADR 0092, except the cached entry, and all of these, each at its own mark:

- The exact chart (`nativePointChart`), the exact `Config`, `nativeDataUpdateRoot`, and native objects
  and Lists for the data, `datasets`, dataset 0 and its `data`.
- The native `arc` class (`nativeArcClass`), native arrays for the arcs and the parsed items, a native
  index of the dataset, and no route on `defaults.elements` or its `arc`, which is an exact
  `ArcOptionsScope`.
- Every scope of the resolver of the arcs, of the legend and of its labels is native
  (`nativeOptionScope`, `OptionResolver.scopesAreNative`), with no write or delete of a slot: a custom Map
  runs code at a read.
- `display` is exactly `false`, `filter` and `sort` are falsy and `reverse` is plain, each by a peek, before
  the proof of the arcs. An object there has a sub resolver, as on a key of the arcs.
- The descriptors of the resolver are the built-in predicates or booleans
  (`Defaults.nativeElementDescriptors`). No slot of the resolver is touched.
- Each key of the arc scopes is an `OptionKey`, with no leading `_`, and a scalar value or a native List by
  a peek. A function under any key, a key of user code, an object and a custom List return at once.
- A List is indexable by its descriptor. `borderDash` stays a raw reference, as in Chart.js ADR 0093.
- An entry that an index of a label reaches passes `_nativeIndexedValue`.
- Arc 0 is native (`nativeArcElement`) before the proof of the keys: a custom arc 0 reads its context
  inside the first resolve, and user code there can change a key that the resolve reads after it.
- Each arc is native, checked at its own write. A custom arc returns to the ordinary build, which runs
  from its first item. It writes the same values again before that arc, with no user code between.

## Fallback

A failed guard at a mark builds at once, at the upstream point, with the upstream order and count of each
call. No guard of this proof runs user code ahead of its point. The steps up to the resolver and the
descriptors are the first steps of that build, in its order. A peek has no effect. A read of an arc key
comes only when each key is plain in native scopes, so no reader sees its position.

## Difference

The items follow row `adapt-hidden-legend-items` and Chart.js ADR 0092, with these changes for a mark of
this proof:

- A read that the cached entry could not answer now runs, with the values and the arc count of its mark:
  in the dataset update, and in a hook of the next update before its layout. It gives what upstream built
  at that point.
- A read after an in-place change of a List with no update gives the new entries, as a read after any
  in-place change does, while each entry that an index of a label reaches is still native for its key.
- A read gives the last built items, and the build still waits, after any of these in-place changes with
  no update: an entry that an index of a label reaches is no longer native for its key (an object or a
  function on any key; a scalar of another type than the slot of the key, such as a String or `null` on a
  numeric key like `borderWidth`, or a number on `borderAlign`); a List of a varying key became empty; item
  0 of the raw `borderDash` List became an object. The same holds after a write through the resolver. These
  items can be older than the snapshot of upstream, from before the last update.

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
