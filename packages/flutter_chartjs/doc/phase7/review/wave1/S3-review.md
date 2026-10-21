# S3 review: `stacksOf` and the List items (wave 1)

- Unit: S3 of `../../design/work-plan.md` §1. Report: `S3-report.md`. Spec: PD §4 and §7.2.
  ADR: Chart.js ADR 0027, section 3 item 3.
- Reviewer: the adversarial fidelity review of the unit.
- Files: `lib/src/core/core.datasetController.dart` (the S3 hunks: `_listStacks`, `stacksOf`,
  `_updateStacks`, `_clearStacks`, `applyStack`, `updateRangeFromParsed`),
  `test/port/core/core.datasetController_test.dart` and
  `test/port/core/core.datasetController_chart_test.dart` (the groups
  `js-semantics-resolver-objects`).
- Upstream: `third_party/Chart.js` at `7169e65147a47f3720957a6f156a33c838ab9f57`.
- Probes: `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/S3-review/`.
  - `stacks_items.mjs`: the pinned build in the x64 Node.js v24.12.0, a `DatasetController`
    subclass with point data elements, `parsing: false`, a stacked linear y scale.
  - `ws/`: a copy of `flutter_chartjs` and `chartjs_test_utils` (outside the repository) with
    the scratch tests `PROBE`, `PROBE2`, `PROBE3` and `PROBE4` at the end of
    `ws/packages/flutter_chartjs/test/port/core/core.datasetController_chart_test.dart`, and
    mutations of `ws/.../lib/src/core/core.datasetController.dart` (`ws/dc.orig` is the S3 file).

## Findings

| ID | Verdict | Severity | Short |
|---|---|---|---|
| S3-R1 | confirmed | medium (a throw, ADR 0009) | A `DateTime` or a `JsClass` data item throws at the `_stacks` write. Upstream writes the property. No row. |
| S3-R2 | confirmed | medium (test) | The two "primitive throws" tests pass also when the throw of DC:363 is removed. |
| S3-R3 | confirmed | low (test) | No test pins the `stacksOf` readers of `applyStack` and `updateRangeFromParsed` for a List item. |
| S3-R4 | confirmed | low (citation) | The test comment cites `:208-227` for the call of `clearStacks` at a stack change. The call is at `:416-419`. |

### S3-R1: a `DateTime` or a `JsClass` data item throws at the write of `_stacks`

- Code: `lib/src/core/core.datasetController.dart:356-364`. The `default` case of the switch
  throws a `TypeError` for each value that is not a Map or a List. Its comment says "a property
  write into a primitive".
- Upstream: `core.datasetController.js:165`
  `const itemStacks = item._stacks || (item._stacks = {});`. In strict code, the write throws only
  for a primitive (number, string, boolean). A `Date` and a function are objects. They take the
  property.
- The port: a `DateTime` is a JS `Date` (Chart.js ADR 0024). A `JsClass` is a JS function
  (Chart.js ADR 0020). Both go to `default` and throw.
- Probe (Node.js, `stacks_items.mjs`): `[new Date(0), new Date(1)]` and
  `[function a() {}, function b() {}]` give no throw. `Object.keys(item._stacks)` is `['y']`.
  `[1, 2]` and `['a', 'b']` throw `TypeError: Cannot create property '_stacks' on number '1'`.
- Probe (port, `PROBE`): `[DateTime.utc(1970), DateTime.utc(1971)]` with the same chart throws a
  `TypeError` at `_updateStacks (core.datasetController.dart:363:11)`.
- Origin: Chart.js ADR 0027, section 3 item 3, says "each other value throws the `TypeError` of a
  write into a primitive". The ADR does not name the object values that are not a Map or a List.
  S3 follows the ADR. The code before S3 had the same throw (`item is! Map`). Thus the defect is
  in the ADR text and in the code. The row `js-semantics-resolver-objects` names only the narrow
  Map.
- Fix (the phase lead decides, because the ADR wins over the unit):
  - Option 1: throw only for a JS primitive (`num`, `String`, `bool`), and put each other value
    into the Expando. `stacksOf` then reads the Expando for each value that is not a Map and not a
    primitive. An `Expando` cannot take a record. A record is not a JS value, so the record case
    can keep the throw.
  - Option 2: keep the throw and add the text to the row `js-semantics-resolver-objects`: "A data
    item that is a `DateTime` or a class value throws a `TypeError` at the write of `_stacks`.
    Upstream adds the property to the `Date` or the function." Also correct the comment of DC:362
    and the doc of `_updateStacks`.

### S3-R2: the "primitive throws" tests do not pin the throw of DC:363

- Tests: `core.datasetController_test.dart` `a primitive data item throws a TypeError` and
  `core.datasetController_chart_test.dart` `number data items throw a TypeError`. Both expect
  `throwsA(isA<TypeError>())`.
- Mutation: in `ws/`, the `default` case is `break;` in place of `throw TypeError();`. Both tests
  pass. The run gives `All tests passed!` for each of them.
- Cause: after the switch, `(itemStacks! as AnyObject)` casts `undefined` (the result of
  `stacksOf(1.0)`). The cast throws a Dart `_TypeError`, which `isA<TypeError>()` also matches.
  Thus the tests do not show that the port throws at the write, as upstream does.
- Probe `PROBE4` (S3 code): the number items throw the plain `TypeError` at
  `_updateStacks (core.datasetController.dart:363:11)`. The narrow Map throws a `_TypeError` at
  `_LinkedHashMapMixin.[]=`. Thus the two throw sites have different runtime types.
- Fix: for the primitive case, expect the plain type,
  `throwsA(predicate((e) => e.runtimeType == TypeError))`, or compare the first frame of the stack
  trace with `_updateStacks`. Also add a String item (upstream throws for `'a'` too).

### S3-R3: no test pins the `stacksOf` readers of `applyStack` and `updateRangeFromParsed`

- Code: DC:1208 (`applyStack`, dc.js:599) and DC:1229 (`updateRangeFromParsed`, dc.js:610) read
  `stacksOf(parsed)`.
- Mutation: in `ws/`, DC:1208 and DC:1229 go back to `jsGetKey(parsed, '_stacks')` (the step 2
  form), and DC:436 to `_parsedValue(parsed, '_stacks')`. The S3 tests, the other tests of the two
  port files and `test/specs/core.datasetController_test.dart` all pass. Only the scratch probes
  fail.
- Probe (Node.js): with the List items `[[0, 1], [1, 2]]`, `controller.applyStack(chart.scales.y,
  data[0])` gives `undefined`. `updateRangeFromParsed(range, y, data[0], {keys: [0], values:
  null})` gives the range `NaN`/`NaN` and no throw.
- Probe (port, `PROBE3`): with the S3 code, `applyStack(y, items[0])` gives `undefined`. With the
  mutation, it throws a `TypeError`.
- Note: no upstream path reaches these two readers with a List item. `getMinMax` skips the item
  (dc.js:633-636, `!isFinite(parsed[scale.axis])`). `controller.line.js:99-101` and
  `controller.scatter.js:130` call `applyStack` only when `parsed[vAxis]` is not null or
  undefined. `controller.bar.js:404` does the same before `_calculateBarValuePixels` (`:571`).
  Thus only a direct call of the protected methods shows the difference. The `_clearStacks`
  reader (DC:436) cannot show a difference for a List item: the dataset value in the stack is
  always `undefined`, and dc.js:219-220 skips the item.
- Fix: add a unit case in the group `js-semantics-resolver-objects`: after the stacked update,
  `applyStack(yScale, listItem)` gives `undefined`, and `updateRangeFromParsed` with a stack gives
  `NaN` with no throw.

### S3-R4: the citation of the stack change

- Test: `core.datasetController_test.dart:1334`, `a stack change moves a List item to the new
  stack`: "core.datasetController.js:208-227: a change of the dataset stack calls clearStacks".
- Upstream: `:208-227` is the body of `clearStacks`. The call at a stack change is
  `buildOrUpdateElements`, `:416-419` (`if (meta.stack !== dataset.stack) { ... clearStacks(meta);`).
- Fix: cite `:416-419` for the call and `:208-227` for `clearStacks`.

## Checks without a defect

- The `stacksOf` doc cites dc.js:165, :218, :599, :610 and bar.js:405, :615. Each line has the
  `_stacks` read (`grep -n _stacks`).
- `stacksOf` gives the value of `_parsedValue(item, '_stacks')` for each value that is not a
  List. For a `JsProxyObject` Map, `item['_stacks']` is the read of `jsGet` (`proxy[name]`).
- For a Map without `_stacks`, `stacksOf` gives Dart `null`, not `undefined`. Each reader tests
  the truthiness (DC:354, DC:437) or reads a property (`jsGetKey(null, axis)` throws a
  `TypeError`, as `undefined[axis]` does at dc.js:599 and :610). No behavior difference.
- The List results agree with the Node.js probe: `Object.keys(item._stacks)` is `['y']`; the stack
  keys are `['0', '_top', '_bottom', '_visualValues']`; after a stack change, the item keeps its
  `_stacks` object, the stack of the new key replaces `y`, the old stack keeps the key `'0'`, and
  `chart._stacks` has the keys of both stacks in that order.
- A number and a string data item throw a `TypeError` in both engines. A Dart `null` or
  `undefined` item throws at `jsGetKey` (dc.js:164 destructures `null` and throws).
- The marker `// DIVERGES(chartjs): js-semantics-resolver-objects, a narrow Map throws.` is above
  the `switch`, not in the Map case of PD §4.1. The report gives the reason (line length).
  `check:headers` passes.
- The measurement (PD §4.3): the two loops of the spec have no paired loss above 0.5 ns in each of
  the 6 processes on a platform (`summary1.txt` to `summary3.txt` of the S3 bed). The `fresh` loss
  of run 1 is outside the threshold of the spec. Decision D5 applies.
- Note: the comment at `core.datasetController_chart_test.dart:452-453` breaks the citation
  `core.datasetController.js:165` across two lines. A search for the citation does not find it.
