# Chart.js ADR 0151: Shared animation options of a bar update

- Status: proposed
- Date: 2026-11-17
- Supersedes: of [Chart.js ADR 0054](0054-typed-internal-model.md) §4, the sentence "No memo or cache of our own"
  and the words "the animations memo of Chart.js ADR 0053" for the one kept object of item 2; of
  [Chart.js ADR 0149](0149-bar-chart-small-costs.md), item 5, and the words "shared animation options" of "Not
  taken".
- Related: [Chart.js ADR 0053](0053-resolver-fast-paths.md), [Chart.js ADR 0019](0019-animation.md)
- Figures: [performance.md](../performance.md) §77

## Context

A bar chart animates by default, so each data change of an app is an animated update. Upstream resolves the
animation options again for each bar (core.datasetController.js:841-861 and :902): a resolver with a context is never
cacheable (helpers.config.ts:128). This resolution is most of the time of an animated update. The result is the same for each bar when no read of the resolution depends on the bar. Chart.js ADR 0053
proposed a memo of the animations across updates (C7), and the maintainer rejected it.

## Decision

1. **The count.** `optionCallEpoch` of `lib/src/core/option_call_epoch.dart` is an `int` that grows by one at three
   places: the call of a scriptable option (`_resolveScriptable`), the read of the item of an indexable option at
   the index of the context (`_resolveArray`), and `Animation.cancel()` of an active animation (its last tick can
   call an interpolator or a curve of the app). It keeps no value of a resolution.
2. **The kept object.** `BarController.update` makes a `SharedBarAnimations` plan for its loop, and clears it in a
   `finally` block. `DatasetController.updateElement` gives each bar to the plan. The plan keeps the `Animations`
   object of one ordinary resolution and gives it to the next bars. A bar with the kept object still calls
   `getContext(index, undefined, mode)` when the chart option `animation` is not `false`, as the resolution does,
   and `Animations.update(element, properties)`.
3. **The guard.** The plan applies only to an animated mode and to the exact built-in classes of the controller,
   the chart and both scales. A resolution becomes the kept object only when the count does not change during it and
   no kept value is an object. A next bar takes the kept object only while the count is the same and the bar is a
   built-in bar with no element options of its own. A bar that fails a test takes the ordinary resolution. The
   library doc of `lib/src/core/animation_share.dart` lists each test.
4. **The hover state.** `updateElement` gives the context `active: false` for each bar (core.datasetController.js:779),
   so the hover state of a bar is not an input of the resolution. `_setStyle` keeps its own resolution.
5. **The cache rule.** The only caches are the caches of upstream. No memo or cache of our own is allowed, with two
   exceptions: the easing table of Chart.js ADR 0149 item 3, which lives inside one `Animator.update` call, and the
   kept object of item 2, which lives inside one `BarController.update` call. Each exception tests its guard at each
   read and holds nothing after its call. The paints, the filter object and the tested colors of Chart.js ADR 0149
   items 1 and 4 are private objects of the port-only canvas layer, which has no upstream form.

## Rejected

- A memo of the animations across updates (Chart.js ADR 0053 C7): it keeps a result after the call.
- No `Animation` for a property with an equal value: it changes the `$animations` entries of an element.

## Consequences

- Three kinds of code of the app run without a count: a descriptor function `_scriptable` or `_indexable` (it gets
  only the key), a `_fallback` function (it gets the key and the value) and the `operator []` of a data List of the
  app. If such code changes the animation options during an update, the next bars of that update keep the old
  options. Upstream reads the new options at the next bar.
- A color for each bar, the mode `active` (its default hover colors are functions), a time or logarithmic scale and
  a subclass take the ordinary resolution for each bar.
- A new place that calls a function of the app with the context of an element during the animation resolution must
  add one to the count.

## Tests

`test/port/core/animation_share_test.dart`
