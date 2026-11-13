# Chart.js ADR 0142: The line option `segment` holds a `LineSegmentStyle`

- Status: accepted
- Date: 2026-11-13
- Related: Chart.js ADRs 0054, 0115, 0116, 0125, 0130, 0139.
- Supersedes: of Chart.js ADR 0054, the sentence of §11 "The classes are internal: `lib/helpers.dart`
  exports `ContextObject` only" for `ScriptableLineSegmentContext`, the typed record with the face
  of §9 for the style of a segment (`SegmentStyle`), and the scope kind `SegmentOptions` of the
  schema of §2.

## Context

Upstream, the line option `segment` is an object of scriptable options: `borderColor`,
`backgroundColor`, `borderWidth`, `borderDash`, `borderDashOffset`, `borderCapStyle` and
`borderJoinStyle` (`index.d.ts:2004`). The resolver gives a view of the object. For each part of
the line, from one point to the next, `doSplitByStyles` (`helpers.segment.js:279`) calls
`setContext` of the view with the context `{type: 'segment', p0, p1, p0DataIndex, p1DataIndex,
datasetIndex}`, and `readStyle` reads the seven keys of the new view. A function that gives
`undefined` keeps the style of the line. `styleChanged` compares the `JSON.stringify` text of two
styles, with a replacer that gives each gradient and pattern its index in a cache.

The port held the same form: the schema had the scope kind `SegmentOptions`, the typed API had no
parameter (an app wrote a Map in `extra`), each function read the context by name and gave
`Object?`, and `helpers.segment.dart` called `setContext` of the view or `jsCall` of a function of
user code. `styleChanged` was an emulation of `JSON.stringify`. The emulation wrote `{}` for each
value that is not a Map, a List, a number, a string or a paint. The values of `borderCapStyle` and
`borderJoinStyle` are the Flutter enums `StrokeCap` and `StrokeJoin` since the row
`adapt-flutter-stroke-enums`. Thus two styles that differ only in one of these keys compared as
equal, and the line did not split there. A test confirms it on the old code: a line with the cap
`round` for one part and `butt` for the others gave one part, and so did the join.

## Decision

1. `LineSegmentStyle` is a final immutable class of the core file
   `lib/src/types/line_segment_style.dart`, with a primary `const` constructor (ADR 0010). It has
   seven nullable fields, each a typed function of a `ScriptableLineSegmentContext`:
   `borderColor` and `backgroundColor` give a `ChartPaint?`, `borderWidth` and `borderDashOffset`
   a `double?`, `borderDash` a `List<double>?`, `borderCapStyle` a `StrokeCap?` and
   `borderJoinStyle` a `StrokeJoin?`. `merge(other)` gives a style with each field of `other` that
   is not null over the field of this style. `==` compares the functions by identity.

   ```dart
   LineDataset(
     data: values,
     segment: LineSegmentStyle(
       // Red where the line goes down; null keeps the line color.
       borderColor: (s) => values[s.p1DataIndex] < values[s.p0DataIndex]
           ? const ChartPaint.solid(Color(0xFFFF0000))
           : null,
     ),
   );
   ```

2. `ScriptableLineSegmentContext` has typed getters: `p0` and `p1` (the `PointElement`
   interface of `lib/src/types/index.dart`), and the `int`s `p0DataIndex`, `p1DataIndex` and
   `datasetIndex`. Its constructor `segment` writes the own keys in the order of the upstream
   literal, so the face (`JsObjectFace`) still reads them by name. `lib/chartjs.dart` exports it
   and `LineSegmentStyle`.
3. The schema has the typed atom `lineSegmentStyle`, the shape of `segment` in the four kinds that
   had `scope SegmentOptions`. The kind `SegmentOptions` goes. A Map is an object cell, and another
   value is foreign.
4. The resolver merges the `segment` values of the scopes with `LineSegmentStyle.merge`, as it
   merges two fonts with `TextStyle.merge` (Chart.js ADR 0116) and two sets of tooltip callbacks
   (Chart.js ADR 0125). One function of the resolver does it for each such kind
   (`_mergeNativeOptions`). `nativeMergeKind` and `mergeNativeOptionValues` of `helpers.core.dart`
   name the kinds and merge two values of one kind; `merge`, `mergeIf` and `Defaults.route` use
   them too. A new kind of such an option object is one line in each of the two functions.
5. `_doSplitByStyles` calls each function of the style that is not null with the typed context of
   each part, in the key order of `readStyle`. No resolver view, no `setContext` and no `jsCall`
   run. A null function or a null result puts `undefined` into the style of the part, as a key with
   no value and a function that gives `undefined` do upstream. The draw then takes the value of the
   line options (`setStyle` of element.line.js:202, the filler). Thus the parts and the draw calls
   stay those of upstream.
6. `SegmentStyle`, the style of a part, is an immutable class with `==` and `hashCode`: a gradient
   or a pattern compares by identity, as the cache index of the replacer of upstream does; a List
   compares item by item; NaN equals NaN, as `JSON.stringify` writes each NaN as `null`; any other
   value compares with `==`. `styleChanged` compares two styles with `==`. The emulation of
   `JSON.stringify` and its row `js-semantics-segment-style-json` go. Two styles that differ only in
   `borderCapStyle` or in `borderJoinStyle` now split the line, as the keywords do upstream.
7. A `LineSegmentStyle` with no function splits nothing, as an object without `setContext` does
   upstream. A `segment: {}` of upstream goes through the resolver and drops a part of one point;
   the port keeps it. Such a part draws nothing.
8. The line and scatter controllers read the option with `lineSegmentStyleOf` and pass the
   `LineSegmentStyle` to the options of the line. A falsy value is no segment style. A Map, a
   constant and another truthy value stop a debug build, and a release build takes no segment
   style. A style that is the same for each part is the line option itself.
9. `LineDataset`, `ScatterDataset`, `RadarDataset` and `LineElementStyle` have
   `final LineSegmentStyle? segment`. The lowering stores the object with no copy.
10. The upstream data fixture `controller.line/segments/single.js` holds the constant
    `borderColor: 'red'`. It gets a hand port with a function that gives the color for each part
    (Chart.js ADR 0115). The hand ports of the eight other segment fixtures give typed functions
    and `ChartPaint` values.
11. The reference data of the generators keep their `segment` Maps of `'fn:<name>'` texts. The test
    harness (`copyReference`) makes a `LineSegmentStyle` of the typed functions of the test file
    (`nativeSegmentStyle` of `test/support/segment_style.dart`). An observation of upstream reads
    the keys of the resolved segment view through the dataset context. The port has no such view,
    so both sides compare as the names of the keys that hold a function. No generator runs again.

## Consequences

- The typed API and a raw config hold the same object, and an app writes typed functions with
  typed context fields, not reads by name.
- The by-name reads of `helpers.segment.dart` (`setContext` by name, `jsCall`, the JSON object
  walk) go, and with them its baseline of `check:typed-reads`.
- The texts of the observation oracle change for the nine segment fixtures only: the dump of the
  resolved `segment` option, the calls of the oracle's own reads of that view with a dataset
  context, and, for `single.js`, the calls of its new function. The draw calls stay.
- A raw config with a `segment` Map stops a debug build. Version 0.1.0 is not released, so no app
  depends on the Map.

## Alternatives considered

- **Keep the Map and fix only `styleChanged`.** It keeps the reads by name, the `Object?` results
  and the untyped context. Rejected.
- **Put the value of the line options into the style for a null result.** The comparison would
  then join a part with an explicit value and a part with `undefined` where upstream splits them.
  The draw is the same, but the parts and the draw calls differ from upstream. Rejected.
- **Constant values beside the functions.** A style that is the same for each part is the line
  option itself; a function covers the rare constant of upstream. Rejected.
