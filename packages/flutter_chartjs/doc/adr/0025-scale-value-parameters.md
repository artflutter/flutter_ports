# Chart.js ADR 0025: Scale value parameters

- Status: accepted (2026-10-20)
- Superseded in part by: [Chart.js ADR 0033](0033-radial-scale-centers.md) (2026-10-21), for §5 `xCenter` and `yCenter`
- Date: 2026-10-20
- Related: [Chart.js ADR 0003](0003-type-only-dependencies.md) (type libraries, a member with its
  first caller, records for inline object types),
  [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (the `undefined` sentinel),
  [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0010](0010-js-numeric-semantics.md) (`ToNumber`, the reference engine),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (underscore members),
  [Chart.js ADR 0017](0017-element-properties.md) §5 (the read by name),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §9 and §13 (feature tests, a gain
  that only a microbenchmark measures),
  [Chart.js ADR 0023](0023-underscore-member-collisions.md) (names that collide),
  Chart.js ADR 0024 (dates, the parallel phase 6 decision),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [performance.md](../performance.md) §8.3 and §10.3,
  [differences.md](../differences.md) row `adapt-scale-position-value`

## Context

Phase 6 ports the six scales of `src/scales/`. Phase 5 left one decision open for them: the type
of the value parameter of `getPixelForValue`. `lib/src/types/index.dart:557-565` declares
`double getPixelForValue(double value, [double? index])` and says that phase 6 decides. The row
`adapt-scale-position-value` of `differences.md` waits for the same decision. The other value
methods of the scales have the same question. This ADR also decides four related points of the
phase 6 API: the interface members, the underscore names, `setMinAndMaxByKey` and the parsed read
of phase 7. The line numbers refer to Chart.js v4.5.1 (commit `9c5cf9fa`).

### Upstream bodies

`core.scale.js:881-890` documents `getPixelForValue(value, index)` with `@param {*} value`. The
base method returns NaN. `index.d.ts:1336` declares `value: number`. Each scale reads the value
with its JavaScript type:

| Scale | Method | Lines | A value that is not a number |
|---|---|---|---|
| category | `getPixelForValue` | `scale.category.js:133-139` | `typeof value !== 'number'` calls `this.parse(value)`. A `null` result gives NaN. `parse` (`:70-78`) gives the index of a label. It adds an unknown string to the labels (`:4-12`). |
| linear | `getPixelForValue` | `scale.linear.js:44-46` | `null` gives NaN. The `-` operator applies `ToNumber` to another value. |
| logarithmic | `getPixelForValue` | `scale.logarithmic.js:210-220` | `undefined` and `0` give `this.min`, the min pixel. `null` and `isNaN(value)` give NaN. Its `parse` gives `undefined` for a 0 (`:103-110`). |
| time | `getDecimalForValue`, `getPixelForValue` | `scale.time.js:562-564`, `:570-574` | `null` gives NaN. The `-` operator applies `ToNumber` to another value. `getPixelForValue` gives the value unchanged to `getDecimalForValue`. |
| timeseries | `getDecimalForValue` | `scale.timeseries.js:162-164`, `:12-32` | No test. The operators `>=`, `<=` and `-` of `interpolate` apply `ToNumber`. Thus `null` acts as 0. |
| radialLinear | `getDistanceFromCenterForValue`, `getValueForDistanceFromCenter` | `scale.radialLinear.js:489-509` | `isNullOrUndef` gives NaN. The `-` and `/` operators apply `ToNumber` to another value. |
| radialLinear | `getPointPositionForValue`, `getBasePosition` | `scale.radialLinear.js:529-535` | `getPointPositionForValue` gives the value unchanged to `getDistanceFromCenterForValue`. `getBasePosition` reads `index \|\| 0`. |
| all | `getLineWidthForValue` | `core.scale.js:1451-1463` | `t.value === value` (`:1457`), a strict compare. |

### Callers

- `core.scale.js:145`, `:156`, `:1064`, `:1077`, `:1182` and `:1191` pass the raw option value
  `position[positionAxisID]` of an object position.
- `core.scale.js:911` passes a tick value. `core.scale.js:944` passes `getBaseValue()`.
  `helpers.extras.ts:105` and `:121` pass the user bounds. These values are numbers.
- The controllers of phase 7 pass `parsed[axis]`: `controller.line.js:100-101`,
  `controller.scatter.js:129-130`, `controller.bubble.js:129-130`, `controller.bar.js:540` and
  `:655`, `controller.radar.js:88` and `controller.polarArea.js:180`.
- `controller.bar.js:590`, `:593`, `:619` and `:620` pass a stack sum and the `base` option.
  `actualBase` is `baseValue || 0` of the `base` option (`controller.bar.js:564-565`). Thus it is
  any user value.
- The value of `parsed[axis]` is one of these:
  - a number
  - `null`: the parse of `null` by a linear, logarithmic or radial scale
    (`scale.linearbase.js:170-179`), or by a category scale (`scale.category.js:71-73`)
  - `undefined`: the parse of 0 by a logarithmic scale, or an absent key with `parsing: false`
  - NaN: the category parse of a repeated label (`scale.category.js:19-23`)
  - any user value with `parsing: false`
- The filler of phase 8 passes the option value `fill.value` (`filler.options.js:88`,
  `filler.target.js:82-91`).
- `plugin.tooltip.js` and `core.interaction.js` call none of these methods.
- No file of `src/` calls `getValueForDistanceFromCenter` or `getBasePosition`. The radial spec
  passes only numbers to `getValueForDistanceFromCenter` (`scale.radialLinear.tests.js:497-507`).
- Two spec cases pass a string: `scale.category.tests.js:247` (`'tick1'`) and `:534`
  (`labels[i]`). Both cases acquire a chart: a `'line'` chart (`:223-224`) and a `'bar'` chart
  (`:519-520`).

### The port

- `types.Scale.getPixelForValue` and `Scale.getPixelForValue` take a `double`.
  `Scale.getLineWidthForValue` takes a `double` (`core.scale.dart:2444`).
- The six call sites of `core.scale.dart` (`:333`, `:348`, `:1987`, `:2005`, `:2144`, `:2156`)
  apply `jsToNumber` before the call. Each carries the marker of the row
  `adapt-scale-position-value`.
- `ChartMeta.parsed` is a `List<Object?>` of Maps. A Map keeps a parsed number as a boxed
  `double` ([performance.md](../performance.md) §10.3). `_parsedValue`
  (`core.datasetController.dart:565`, `core.interaction.dart:148`) gives Dart `null` for an
  absent key. Its current readers test with `isFinite`, `isNullOrUndef` or the truthiness. For
  them, `null` and `undefined` give the same result.
- Nine tracked test classes declare `double getPixelForValue(double value, [double? index])`: 8
  in `test/` and `tool/bench/bench_flutter_test.dart:35`. The root `analysis_options.yaml`
  examines `tool/`.
- `setMinAndMaxByKey` (`helpers.math.dart:135-148`) takes a `List<Map<String, Object?>>` and a
  `MinMax`. Its two upstream callers pass the ticks and the scale (`scale.linearbase.js:274`,
  `scale.logarithmic.js:172`). A tick of the port is the class `Tick`, and `Scale` does not
  implement `MinMax`.
- `types.Chart` has no `getDataVisibility`, and `types.DatasetController` has no
  `getAllParsedValues`. The concrete members exist (`core.controller.dart:1748`,
  `core.datasetController.dart:1312`). `scale.radialLinear.js:463`, `scale.time.js:638` and
  `:642` call them through the type interfaces.
- The gallery class `DemoChart` (`apps/chartjs_gallery/lib/demo/demo_chart.dart:40`) implements
  `types.Chart` without `noSuchMethod`. Each other class of the tests, of `chartjs_test_utils` and
  of the gallery that implements `types.Chart`, `types.Scale` or `types.DatasetController` has a
  `noSuchMethod` (scan E7).

### Probe P1: the raw value and its `ToNumber`

The probe calls each method of a real Chart.js 4.5.1 chart twice: with the raw value, and with
`Number(value)`. The second call gives the result of a `double` parameter after `jsToNumber`.
These rows differ:

| Scale and method | Value | Raw value | `ToNumber` first |
|---|---|---|---|
| linear `getPixelForValue` | `null` | NaN | 533.8 (the pixel of 0) |
| logarithmic `getPixelForValue` | `null` | NaN | 483.6 (the min pixel) |
| logarithmic `getPixelForValue` | `undefined` | 483.6 (the min pixel) | NaN |
| category `getPixelForValue` | `null` | NaN | 34 (the pixel of index 0) |
| category `getPixelForValue` | `'B'` | 269 (the pixel of `'B'`) | NaN |
| category `getPixelForValue` | `'1'` | 739, and `'1'` becomes label 3 | 269 (index 1) |
| time `getPixelForValue`, `getDecimalForValue` | `null` | NaN | -32768, -6087.3 |
| radialLinear `getDistanceFromCenterForValue`, `getPointPositionForValue`, `getValueForDistanceFromCenter` | `null` | NaN | the result of 0 |

The other 62 rows agree. Examples are `undefined`, NaN, `'5'`, `true` and a `Date` for the
linear and time scales, and every row of the timeseries scale.

A second probe (P5) gives the `null` case of the timeseries scale. With data from 1e12 ms,
`getDecimalForValue(null)`, `(0)` and `(false)` give -2314.8. `undefined` and NaN give NaN. A line
point with an invalid date has x = -32768 and `skip: false` on a `timeseries` axis. On a `time`
axis, it has x = NaN and `skip: true`.

### Probe P2: chart behavior

The probe builds charts with all registerables. It reads the elements and the hit test
(`getElementsAtEventForMode`). Probe P2b runs the same cases with a wrapper that applies
`Number()` to the value of `getPixelForValue` and `getDistanceFromCenterForValue` of each scale
class. The wrapper gives the result of a `double` parameter after `jsToNumber`:

| Case | Upstream (P2) | `ToNumber` first (P2b) |
|---|---|---|
| (a) Scatter, logarithmic x, a point at x = 0 | `parsed.x` is `undefined`. The point is at x = 44 (the min pixel), `skip` is false. The hit test at the point gives `0:0`. | x is NaN, `skip` is true, no hit. |
| (b) Scatter, linear x, a point with `x: null` | x is NaN, `skip` is true. The hit test at the pixel of 0 gives nothing. | The point is at 271.5 (the pixel of 0), `skip` is false. The hit test gives `0:0`. |
| (c) Radar, a `null` value | x and y are NaN, `skip` is true. The hit test (`point` mode) at the position of 0 gives nothing. | The point is at (256, 272), `skip` is false. The hit test gives `0:2`. |
| (d) A y axis at the position `{x: 'B'}` of a category x axis | The labels and the border are at 256, the pixel of `'B'`. `{x: null}` gives NaN. | `{x: 'B'}` gives NaN. `{x: null}` gives 8. |
| (e) Line, `parsing: false`, x values `'A'`, `'B'`, `'C'` on a category axis | The points are at 34, 269 and 504. | Each point is at NaN, with `skip` true. |
| (f) Polar area, a `null` value | `outerRadius` is NaN. | `outerRadius` is 0. |
| (h) Scatter, logarithmic x, `parsing: false`, an item without `x` | `parsed.x` is `undefined`. The point is at the min pixel, and `skip` is false. `getPixelForValue(null)` gives NaN. | x is NaN, `skip` is true. |

Cases (a), (b), (c) and (h) change the hit element. Cases (a), (b), (c), (e) and (h) change the
`skip` state of a point, and thus the drawn line. Case (h) also shows that a caller must keep JS
`undefined` and JS `null` as two values.

### Probe P4: a conversion at the call site

A `double` parameter allows two conversions at the call site. A1 is `ToNumber`. A2 is `ToNumber`
with `null` mapped to NaN. Probe P4 runs 10 chart cases with the upstream methods and with each
conversion:

| Case | Upstream element | A1 | A2 |
|---|---|---|---|
| line, category x, `x: null` | skipped | drawn at label 0 | same as upstream |
| scatter, linear x, `x: null` | skipped | drawn at x = -181 | same as upstream |
| scatter, logarithmic x, `x: 0` | drawn at `min` (44) | skipped | skipped |
| bubble, logarithmic y, `y: 0` | drawn at `min` (483.6) | skipped | skipped |
| line, time x, `x: null` | skipped | drawn at -33.4 | same as upstream |
| line, timeseries x, `x: null` | drawn at -40.7 | same as upstream | skipped |
| radar, `r: null` | skipped | drawn | same as upstream |
| polarArea, `r: null` | outer radius NaN | 0 | same as upstream |
| line, `parsing: false`, logarithmic x, no `x` | drawn at `min` (44) | skipped | skipped |
| y axis at `{x: 'b'}` on a category x | border at 256 | NaN | NaN |

A1 changes 9 of the 10 results. A2 changes 5 of them. No conversion before a `double` parameter
gives all ten results. Only the scale that receives the value can give them.

### Benchmarks

**The value parameter.** A scratch benchmark runs the hot path of `controller.line.js:89-118`.
For each of 20000 items, it reads `x` and `y` from a `Map<String, Object?>` item of a
`List<Object?>`. Then it calls `getPixelForValue` of the index scale and of the value scale. It
imports the real `jsToNumber` and `undefined` of `lib/src/js/`. Each family has four live
subclasses (linear, category, logarithmic, time), so each call is virtual. The forms:
- **A:** a `double` parameter. The caller applies `jsToNumber`.
- **B1:** an `Object?` parameter. The body translates the upstream lines literally.
- **BT:** an `Object?` parameter with `value is double ? value : jsToNumber(value)` at each
  `ToNumber`.
- **BF:** an `Object?` parameter. An early `if (value is double)` branch repeats the upstream
  expression for a number. Then the literal lines follow.

Bed: Apple M3 Max, macOS 26.5.1, Dart 3.12.2. AOT is `dart compile exe`. wasm is
`dart compile wasm -O2` in Node.js v24.12.0 (arm64), for times only. 5 warm-up batches, then 15
batches of 10 passes in an alternate order. A cell gives the lowest and the highest median of 6
processes (2 builds, 3 runs each), in ns. The `ctl` rows are for each item (two calls). The `tick`
and `base` rows are for each call:

| Loop | Platform | A | B1 | BT | BF |
|---|---|---|---|---|---|
| ctl, linear x, linear y | AOT | 24.2-24.6 | 24.1-25.7 | 23.6-24.8 | 23.0-23.8 |
| ctl, category x, logarithmic y | AOT | 30.2-31.4 | 34.7-35.7 | 32.2-32.9 | 29.4-29.8 |
| tick value (a boxed `double`) | AOT | 7.5-7.9 (a layout artifact) | 3.5-3.7 | 3.6-3.7 | 3.5-3.6 |
| `getBasePixel`, logarithmic | AOT | 3.3-3.4 | 4.7-5.0 | 3.3-3.5 | 3.3-3.4 |
| ctl, linear x, linear y | wasm | 29.5-31.5 | 31.9-34.5 | 29.4-31.0 | 28.7-30.1 |
| ctl, category x, logarithmic y | wasm | 51.4-52.4 | 56.4-58.4 | 55.1-56.3 | 49.9-51.4 |
| tick value (a boxed `double`) | wasm | 1.2-1.3 | 2.2-2.4 | 2.2-2.5 | 2.2-3.0 |
| `getBasePixel`, logarithmic | wasm | 3.0-3.2 | 11.9-12.6 | 10.9-11.8 | 4.6-4.9 |

- BF is at or below A in each `ctl` loop on both platforms. On the linear pair, BF is about
  0.6 ns for each item below BT, in each of the 6 processes.
- The logarithmic value axis separates the forms. B1 costs 4.0-6.5 ns more than A for each item:
  0.08-0.13 ms for each update of 20000 points. BT costs 1.8-2.4 ns more on AOT and 3.1-4.9 ns
  more on wasm. BF is 0.4-2.1 ns below A.
- A variant of BT with `value is num && value == x` for the strict compares of the logarithmic
  scale gives the figures of BT. Thus the `Object?` tests before the `ToNumber` cost the time, not
  the compare.
- The box at a caller that holds a `double` costs 0 ns on AOT and about 1 ns for each call on
  wasm. These callers run once for each tick or once for each update.

**The parsed read.** A second benchmark reads `x` and `y` of 20000 Map items, with 10 % `null`
values. In ns for each item, 3 processes:

| Read | AOT | wasm |
|---|---|---|
| `_parsedValue` (Dart `null` for an absent key) | 17.0-17.6 | 24.8-25.4 |
| Map read with `undefined` for an absent key | 17.7-17.9 | 26.7-27.8 |
| `jsGet` | 18.9-19.3 | 29.4-30.3 |

**The `{x, y, angle}` result.** A virtual `getPointPositionForValue` that returns a record costs
24.1-25.1 ns for each call on AOT and 32.6-34.0 ns on wasm. A class with three `final double`
fields costs 20.4-21.0 ns and 29.4-30.7 ns.

**`getDataVisibility`.** An interface call costs 6.3-6.5 ns on AOT and 8.7-9.1 ns on wasm. A cast
to the concrete class and a direct call cost 5.2-5.3 ns and 5.5-5.6 ns.

## Decision

### 1. The value parameters are `Object?`

A value parameter of a scale method has the type `Object?` in two cases:
- The upstream body tests the value for `null`, for `undefined` or for its type, or compares it
  strictly.
- An upstream caller passes a parsed value or an option value.

A parameter that the upstream body tests only with `isNullOrUndef` or `|| 0` has the type
`double?` when no upstream file and no spec gives it a value that is not a number (Chart.js
ADR 0003: `number | null` becomes `double?`). Dart `null` is then JS `null` and JS `undefined`.
Each other parameter keeps `double` or `int`.

Dart `null` is JS `null`. The `undefined` sentinel is JS `undefined` (Chart.js ADR 0006). An
override takes the type of the member that it overrides.

| Class | Member |
|---|---|
| `types.Scale`, `Scale` and each scale that overrides it | `double getPixelForValue(Object? value, [double? index])` |
| `Scale` | `double getLineWidthForValue(Object? value)` |
| `TimeScale`, `TimeSeriesScale` | `double getDecimalForValue(Object? value)` |
| `RadialLinearScale` | `double getDistanceFromCenterForValue(Object? value)` |
| `RadialLinearScale` | `({double x, double y, double angle}) getPointPositionForValue(double index, Object? value)` |
| `RadialLinearScale` | `double getValueForDistanceFromCenter(double? distance)` |
| `RadialLinearScale` | `({double x, double y, double angle}) getBasePosition([double? index])` |

These members keep their types: `getPixelForDecimal(double decimal)`,
`getDecimalForPixel(double pixel)`, `double? getValueForPixel(double pixel)`,
`double? getPixelForTick(int index)`, `getIndexAngle(double index)`,
`getPointPosition(double index, double distanceFromCenter, [double additionalAngle = 0])` and
`Tick.value`. Their upstream bodies only do arithmetic, and each upstream caller passes a number.
`getLabelForValue(Object? value)` and `parse(Object? raw, [double? index])` are already `Object?`.

- `getLineWidthForValue` takes `Object?`, because its caller passes `actualBase`, the raw `base`
  option (`controller.bar.js:565`, `:620`). A `double` parameter needs a `ToNumber` hunk at that
  caller. That hunk changes the strict compare `t.value === value` (`core.scale.js:1457`). The
  Dart compare `t.value == value` gives the upstream result: a `double` tick value equals a
  number of the same value and differs from a `String`.
- `{x, y, angle}` (`scale.radialLinear.js:522-526`) is a record, because ported code only reads
  it (Chart.js ADR 0003).

### 2. The callers pass the value unchanged

- The six call sites of `core.scale.dart` pass `jsGet(position, positionAxisID)` without
  `jsToNumber`. The port removes the six `DIVERGES` markers and the row
  `adapt-scale-position-value`.
- `getPixelForTick`, `getBasePixel` and `helpers.extras.dart:241` and `:262` pass their `double`.
  They do not change. Each call boxes the `double` (Benchmarks: 0 ns on AOT, about 1 ns on wasm).
- A ported caller passes the value of the upstream expression with its JS identity. A caller never
  applies `jsToNumber` to a value before a call of a member of section 1.

### 3. The form of the bodies

Each body translates its upstream lines one by one, with these forms:

| JavaScript | Dart |
|---|---|
| `value === null` | `value == null` |
| `value === undefined` | `identical(value, undefined)` |
| `isNullOrUndef(value)` | `isNullOrUndef(value)` |
| `typeof value !== 'number'` | `value is! num` (user data can hold an `int`) |
| `value === 0`, `value === this.min` | `value == 0`, `value == min` |
| `isNaN(value)` | `jsIsNaN(value)` |
| `value - x`, `value / x` | `jsToNumber(value) - x`, `jsToNumber(value) / x` |
| `index \|\| 0` | `jsOrZero(index)` |

A reassigned parameter carries `// ignore: parameter_assignments`, as `Scale.getPixelForDecimal`
does.

**The fast path.** Four bodies start with a port-only branch `if (value is double)`. The branch
holds the upstream expression for a number. The literal lines follow the branch. The four bodies
are `getPixelForValue` of `CategoryScale`, `LinearScale` and `LogarithmicScale`, and
`getDecimalForValue` of `TimeScale`. A cartesian controller calls them once for each point, and
the benchmark measured them. The branch carries a `//` line that names this section. It carries no
`DIVERGES` marker:
- The branch keeps the upstream structure. [porting-flow.md](../porting-flow.md) §1.1 names the
  number path of `toTRBL` (`helpers.options.dart:171-175`) as such a form. Thus the branch needs
  no row ([Chart.js ADR 0020](0020-registry-and-component-classes.md) §13).
- BF is the fastest form of the benchmark. It is the only `Object?` form that reaches A on a
  logarithmic value axis.
- On the VM and on dart2wasm, an `int` is not a `double`. Thus an `int` takes the literal lines.
  On dart2js, an `int` is a `double`, and it takes the branch. Both paths give the same result for
  a number.

```dart
// scale.linear.js:44-46
@override
double getPixelForValue(Object? value, [double? index]) {
  if (value is double) {
    // Port-only fast path for a number (Chart.js ADR 0025, section 3).
    return getPixelForDecimal((value - startValue) / valueRange);
  }
  return value == null
      ? double.nan
      : getPixelForDecimal((jsToNumber(value) - startValue) / valueRange);
}

// scale.category.js:133-139
@override
double getPixelForValue(Object? value, [double? index]) {
  if (value is double) {
    // Port-only fast path for a number (Chart.js ADR 0025, section 3).
    return getPixelForDecimal((value - _startValue) / _valueRange);
  }
  if (value is! num) {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    value = parse(value);
  }
  return value == null
      ? double.nan
      : getPixelForDecimal((jsToNumber(value) - _startValue) / _valueRange);
}

// scale.logarithmic.js:210-220
@override
double getPixelForValue(Object? value, [double? index]) {
  if (value is double) {
    // Port-only fast path for a number (Chart.js ADR 0025, section 3).
    final number = value == 0 ? min : value;
    if (number.isNaN) {
      return double.nan;
    }
    return getPixelForDecimal(
      number == min ? 0 : (log10(number) - _startValue) / _valueRange,
    );
  }
  if (identical(value, undefined) || value == 0) {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    value = min;
  }
  if (value == null || jsIsNaN(value)) {
    return double.nan;
  }
  return getPixelForDecimal(
    value == min ? 0 : (log10(jsToNumber(value)) - _startValue) / _valueRange,
  );
}

// scale.time.js:562-564
double getDecimalForValue(Object? value) {
  if (value is double) {
    // Port-only fast path for a number (Chart.js ADR 0025, section 3).
    return (value - min) / (max - min);
  }
  return value == null ? double.nan : (jsToNumber(value) - min) / (max - min);
}
```

The literal lines after the branch keep `value == 0` for a number that is not a `double`. A Dart
`int` 0, for example `{'y': 0}` with `parsing: false`, thus gives the min pixel, as
`scale.logarithmic.js:211-213` does.

The other bodies have no branch. No measurement shows a gain for them (Open):
- `TimeScale.getPixelForValue` gives the value unchanged to `getDecimalForValue`.
- `TimeSeriesScale.getDecimalForValue` applies one `jsToNumber` at the entry of `interpolate`.
  `interpolate` uses `val` only in compares and in arithmetic (`scale.timeseries.js:12-32`). Thus
  one `ToNumber` gives the result of the `ToNumber` of each operator (probe P1: every timeseries
  row agrees). This is a translation, not a `DIVERGES` hunk.
- The radial methods translate their lines literally.

```dart
// scale.timeseries.js:162-164
@override
double getDecimalForValue(Object? value) {
  return (_interpolate(_table, jsToNumber(value)) - _minPos) / _tableRange;
}

// scale.radialLinear.js:489-500
double getDistanceFromCenterForValue(Object? value) {
  if (isNullOrUndef(value)) {
    return double.nan;
  }
  final scalingFactor = drawingArea / (max - min);
  if (jsTruthy(options['reverse'])) {
    return (max - jsToNumber(value)) * scalingFactor;
  }
  return (jsToNumber(value) - min) * scalingFactor;
}
```

**The pin test.** A port-only test calls each of the four bodies with a list of numbers: 0, -0.0,
NaN, the infinities, `min`, `max` and values between them. It gives each number as a `double`, and
as an `int` when the number is an integer. It expects the same result for both forms. It also
calls the bodies with the values of probe P1 and expects the upstream results. The test runs on
the VM, where an `int` takes the literal lines. [performance.md](../performance.md) §8.3
records the same kind of test for `toTRBL`.

**The fallback.** If the maintainer reads the repeated expression as a change of the upstream
structure, the four bodies take the form BT. BT costs 0.04-0.10 ms more for each update of 20000
points, on a logarithmic value axis only.

### 4. Interface members of phase 6

Phase 6 changes or adds three interface members, because phase 6 files call them through the type
interfaces:

| Interface | Member | Upstream | Phase 6 caller |
|---|---|---|---|
| `types.Scale` | `double getPixelForValue(Object? value, [double? index])` | `index.d.ts:1336`, `core.scale.js:884-890` | the six positions of `core.scale.dart` |
| `types.Chart` | `bool getDataVisibility(double index)` | `index.d.ts:542`, `core.controller.js:885-887` | `scale.radialLinear.js:463` |
| `types.DatasetController` | `List<double> getAllParsedValues(Scale scale)` | `index.d.ts:610`, `core.datasetController.js:662-674` | `scale.time.js:638`, `:642` |

- `Chart.getDataVisibility` (`core.controller.dart:1748`) and
  `DatasetController.getAllParsedValues` (`core.datasetController.dart:1312`) get `@override`.
- `DemoChart` gets `bool getDataVisibility(double index) => true`. The demo chart hides no index
  (`core.controller.js:885-887` with empty `_hiddenIndices`).

### 5. Members of phase 7

Chart.js ADR 0003 adds a member with its first ported caller. No phase 6 file reads another
member through `types.Scale`. Thus phase 7 adds these members with its controllers. This ADR fixes
their Dart forms now. They are the forms of the concrete `Scale`:

| Member of `types.Scale` | Upstream | First reader |
|---|---|---|
| `List<Tick>? get ticks` | `index.d.ts:1291`, `core.scale.js:226`, `:410` | `controller.bar.js:47` |
| `double getPixelForDecimal(double decimal)` | `index.d.ts:1309` | `controller.bar.js:606-607`, `controller.bubble.js:129` |
| `double? getPixelForTick(int index)` | `index.d.ts:1316` | `controller.bar.js:48` |
| `double getLineWidthForValue(Object? value)` | `index.d.ts:1327` | `controller.bar.js:620` |
| `double? getValueForPixel(double pixel)` | `index.d.ts:1344` | `controller.bar.js:615` |
| `double getBaseValue()` | `index.d.ts:1346` | `filler.options.js:112` (phase 8) |
| `double getBasePixel()` | `index.d.ts:1352` | `controller.line.js:101`, `controller.bar.js:396` |
| `double get startPixel`, `double get endPixel` | `core.scale.js:237`, `:239` (`_startPixel`, `_endPixel`) | `controller.bar.js:549-550` |
| `Map<String, Object?> get cache` | `core.scale.js:247` (`_cache`) | `controller.bar.js:8-17` |

The type library drops the underscore of `_startPixel`, `_endPixel` and `_cache` without
`@internal` (Chart.js ADR 0012, type libraries).

The radial members do not go to `types.Scale`. Phase 7 adds the interface
`types.RadialLinearScale implements Scale` of `index.d.ts:3627-3639` with the members that its
callers read:
- `double get xCenter`, `double get yCenter` (`controller.polarArea.js:165-166`,
  `controller.radar.js:90-91`)
- `double getIndexAngle(double index)` (`controller.polarArea.js:167`)
- `double getDistanceFromCenterForValue(Object? value)` (`controller.polarArea.js:180`)
- `({double x, double y, double angle}) getPointPositionForValue(double index, Object? value)`
  (`controller.radar.js:88`)

`RadialLinearScale` implements it. The filler of phase 8 tests
`scale is types.RadialLinearScale` for `if (scale.getPointPositionForValue)`
(`filler.target.js:50`), as the port tests `types.VisualElementRange` for `getRange` (Chart.js
ADR 0020 §9).

### 6. Underscore members of the scales

[Chart.js ADR 0012](0012-dart-file-naming.md) applies: a `_` member that another module reads
drops the underscore and carries `@internal`. The port treats a spec as another module. The
precedents are `Chart.metasets`, `Chart.sortedMetasets` and `Chart.plugins`
(`core.controller.dart:740-799`, "The specs read it").

| Upstream member | Readers in another file | Dart member |
|---|---|---|
| `_startValue`, `_endValue`, `_valueRange` of `LinearScaleBase` (`scale.linearbase.js:164-167`) | `scale.linear.js:45`, `:49`, `scale.radialLinear.js:556` | `startValue`, `endValue`, `valueRange` |
| `_offsets` of `TimeScale` (`scale.time.js:261`, `:440`) | `scale.timeseries.js:171` | `offsets` |
| `_generate()` of `TimeScale` (`scale.time.js:448-450`, `@protected`) | the override at `scale.timeseries.js:119` | `generate()`, also `@protected` |
| `_unit` of `TimeScale` (`scale.time.js:258`, `:387`) | `scale.time.tests.js:115` | `unit` |
| `_adapter` of `TimeScale` (`scale.time.js:269`) | `scale.time.tests.js:448`, `:453` | `adapter` |
| `_pointLabels` of `RadialLinearScale` (`scale.radialLinear.js:422`) | `scale.radialLinear.tests.js:330`, `:355`, `:369`, `:385` | `pointLabels` |
| `_pointLabelItems` of `RadialLinearScale` (`scale.radialLinear.js:423`) | `scale.radialLinear.tests.js:630` | `pointLabelItems` |

- Each Dart member of the table carries `@internal`. Its `///` line names the upstream member.
- The other `_` members of the six files have readers only in their own file. They keep the
  underscore. Examples are `_startValue` and `_valueRange` of the category and logarithmic
  scales, `_zero`, `_addedLabels`, `_majorUnit`, `_table` and `_padding`.
- No new name collides with a member of the class or of a superclass. An analyzer probe declares
  the nine names on subclasses of the current `Scale` and passes `dart analyze`. Thus Chart.js
  ADR 0023 does not apply. No scale overrides `operator []` for these names.
- The upstream locals `const offsets = this._offsets` (`scale.time.js:571`, `:581`,
  `scale.timeseries.js:171`) become `final offsets = this.offsets`.
- A point-label item is a public class, because the spec reads its `x` and `y`
  (`scale.radialLinear.tests.js:651-652`). The port writes `visible`
  (`scale.radialLinear.js:194`). Thus the item is a class, not a record (Chart.js ADR 0003).
- Chart.js ADR 0024 decides the type of `adapter`. This ADR decides only its name.

### 7. `setMinAndMaxByKey` and `MinMax`

`scale.linearbase.js:274` and `scale.logarithmic.js:172` call
`_setMinAndMaxByKey(ticks, this, 'value')` (`helpers.math.ts:79-93`).

- The signature becomes
  `void setMinAndMaxByKey(List<Object?> array, MinMax target, String property)`.
- The read of `array[i][property]` gives `item.value` for a `types.Tick` and the key `'value'`.
  It gives `jsGet(item, property)` for other items. `jsGet` gives `undefined` for an absent key of
  a Map, and `isNaN(undefined)` is true. Thus the port drops the `containsKey` test, and the Map
  cases give the current results.
- The function has no throw. Upstream reads any key of any item (`helpers.math.ts:88`).
- `Scale` implements `MinMax`. Its fields `double min` and `double max` are the members of
  `MinMax`. Each scale can then pass `this`. `core.scale.dart` changes in this ADR in any case.

### 8. The parsed read of phase 7

A ported reader that passes `parsed[axis]` to a member of section 1 keeps `undefined` for an
absent key of a Map item, as `jsGet` does. `_parsedValue` gives Dart `null` for an absent key. The
logarithmic scale then gives NaN where upstream gives the min pixel (case (h)).
- The fastest form with the result of `jsGet` is the Map read
  `value == null && !item.containsKey(key) ? undefined : value`. It costs 0.3-0.9 ns (AOT) and
  1.7-2.5 ns (wasm) more than `_parsedValue` for each item (Benchmarks).
- `_parsedValue` stays for its readers that do not tell `null` from `undefined`.
- Phase 7 chooses the name and the file of the function.

### 9. Tests, rows and skip reasons

- The nine tracked overrides with `double value` fail with `invalid_override`. Each takes
  `Object? value` and applies `jsToNumber(value)` before its arithmetic. The reference scales of
  the `.mjs` generators apply the same `ToNumber` through their JavaScript operators.
- The test controllers that call `getPixelForValue(jsToNumber(jsGet(parsed, axis)), i)` pass
  `jsGet(parsed, axis)`, as their `.mjs` generators pass `parsed[axis]`. The reference values do
  not change.
- The group `adapt-scale-position-value` of `test/port/core/core.scale_test.dart` gets a new name.
  It expects the raw values `'B'`, `null`, `'7'` and `3`.
- Relation tests pin the rows of probes P1 and P5 for each scale. For example, category
  `getPixelForValue('B')` equals `getPixelForValue(1)`. A relation needs no generated reference
  values.
- The spec cases `scale.category.tests.js:222-248` and `:514-541` port with their string
  arguments. They skip as `'blocked: controller.line'` and `'blocked: controller.bar'` until
  phase 7. Then they run with their bodies.
- `differences.md` loses the row `adapt-scale-position-value`. This ADR adds no row, no
  `DIVERGES` marker and no skip reason.

## Alternatives considered

Each option has a score in the order of [porting-flow.md](../porting-flow.md) §1.1: behavior,
performance, structure, code.

**The three drafts.** A panel wrote three drafts. A judge scored them (0 to 10, higher is
better):

| Draft | Behavior | Performance | Structure | Less code | Evidence |
|---|---:|---:|---:|---:|---:|
| Fidelity (chosen, with grafts) | 9.5 | 6 | 8 | 6 | 9 |
| Performance | 7.5 | 7.5 | 5.5 | 5 | 6 |
| Simplicity | 7.5 | 8.5 | 7 | 9 | 6.5 |

- **Fidelity** has no defect of rank 1. Its probes P1, P2 and P2b give the evidence for rank 1.
  This ADR takes its decision with grafts from the other drafts: the fast path, the names without
  the underscore, `Scale implements MinMax`, `getValueForDistanceFromCenter(double?)`, probe P4,
  probe P5, the record and cast figures, and the scans. Fidelity rejected the fast path as a
  change of the structure. §1.1 classifies such a path as a form that keeps the structure.
- **Performance** adds all phase 7 members in phase 6, against Chart.js ADR 0003. Its class for
  `{x, y, angle}` conflicts with the record rule of Chart.js ADR 0003. Its
  `getLineWidthForValue(double)` rests on the false claim that `actualBase` is a number. It skips
  no category spec case, but these cases acquire line and bar charts. Its wasm cost of about
  0.2 ms for each update does not reproduce.
- **Simplicity** has the clearest call-site probe (P4) and the least code. Its logarithmic body
  loses `value === 0` for a Dart `int` 0, a defect of rank 1. Its `setMinAndMaxByKey` throws for
  a key other than `'value'`. Upstream has no throw.

**The parameter type:**

| Form | 1. Behavior | 2. Performance | 3. Structure | 4. Own code |
|---|---|---|---|---|
| A: `double`, the caller applies `jsToNumber` (phase 5) | Fails: 11 rows of P1, cases (a)-(f) and (h) of P2, 9 of 10 cases of P4, 2 spec cases | Reference | A `jsToNumber` at each caller that passes a parsed value or an option value, each a `DIVERGES` hunk | These hunks and their rows |
| A2: `double`, `ToNumber` with `null` mapped to NaN at the caller | Fails: 5 of 10 cases of P4 | As A | As A | As A |
| `double?`: Dart `null` for JS `null` and `undefined` | Fails: the logarithmic scale gives the min pixel for `undefined` and NaN for `null` (P1, P2 (a), (h)). Category labels fail (P2 (d), (e)). | As B, with a nullable box | A conversion at each caller | Hunks at each caller |
| B1: `Object?`, literal bodies | Passes | Logarithmic axis: 4.0-6.5 ns more than A for each item | Each upstream line once | Least |
| BT: `Object?`, `value is double ? value :` at each `ToNumber` | Passes | Logarithmic axis: 1.8-4.9 ns more than A for each item | Each upstream line once | Less |
| BF: `Object?`, an early `value is double` branch (this decision) | Passes | At or below A in each loop | A port-only branch, as the number path of `toTRBL` | More |
| B4: `Object?` and a typed second method, for example `getPixelForNumber(double)` | Passes | No measured gain: the box costs 0 ns on AOT | A method that upstream does not have, in each scale | More |

- **A** loses the hit element and the `skip` state of points. Chart.js ADR 0009 protects them.
  Rejected.
- **A2** and **`double?`** cannot give both results of the logarithmic scale for `undefined` and
  `null`, and they cannot carry a label string. A form that maps `undefined` to 0 changes
  `getMinMax`, because `isFinite(0)` is true. Rejected.
- **B1** and **BT** pass rank 1. Both are slower than BF on a logarithmic value axis. All three
  forms keep the upstream structure (§1.1). The faster form wins. Rejected.
- **B4** adds API that upstream does not have, for no measured gain. A user scale that extends a
  built-in scale and overrides only `getPixelForValue` loses its override for numbers. Rejected.

**Other points:**

- **A class for `{x, y, angle}`.** It is 3.5-4.5 ns faster for each call (reproduced on AOT). A
  radar or radial draw makes tens of such calls, so the gain is below 1 µs for each draw. The
  record rule of Chart.js ADR 0003 applies. The filler wraps the points into point elements in
  any case (`adapt-line-points-elements`). Rejected. Open.
- **The radial members on `types.Scale`.** `Scale` implements `types.Scale`. Thus each scale then
  implements the radial members, and the feature test of `filler.target.js:50` is true for each
  scale. `index.d.ts:3627` declares them on `RadialLinearScale`. Rejected.
- **All phase 7 members in phase 6**, with a full `types.RadialLinearScale` (`setCenterPoint`,
  `drawingArea`, `getPointLabelPosition`, `getBasePosition`). No ported caller reads them in
  phase 6. Chart.js ADR 0003 adds a member with its first caller. Rejected.
- **The underscore kept for the spec-only members**, with a read by name such as
  `scale['_unit']` ([Chart.js ADR 0017](0017-element-properties.md) §5). `TimeScale` and
  `RadialLinearScale` each need an override of `operator []` and `operator []=`. `line['_path']`
  needs the read by name only because `LineElement` has a member `path`, a collision of Chart.js
  ADR 0023. The spec-only precedent is `Chart.metasets`. Rejected: more code, against the
  precedent.
- **`setMinAndMaxByKey` for ticks only**, with a throw for another key. It adds a throw that
  upstream does not have, and it drops the generic read of `helpers.math.ts:88`. Rejected.
- **A second function for the ticks**, for example `setMinAndMaxByTicks`. Two functions for one
  upstream function. Rejected.
- **`implements MinMax` on `LinearScaleBase` and `LogarithmicScale` only.** Two declarations in
  place of one. `core.scale.dart` changes in this ADR in any case. Rejected.
- **`_parsedValue` for the phase 7 reads.** It gives NaN for case (h), where upstream gives the
  min pixel. Rejected.

## Consequences

- Each scale gives the upstream result for each JS value: `null`, `undefined`, NaN, a label string
  and a numeric string (probes P1, P2, P4 and P5).
- The port removes the row `adapt-scale-position-value` and its six markers. This ADR adds no
  row.
- On AOT and wasm, the controller loop with an `Object?` parameter is at or below the loop with a
  `double` parameter. A caller that holds a `double` pays one box for each call: 0 ns on AOT,
  about 1 ns on wasm.
- The category spec cases at `:247` and `:534` need no `'diverges: <row>'` skip. They skip as
  blocked until the phase 7 controllers exist.
- The controllers of phase 7 call `iScale.getPixelForValue(value, i)` with the read of section 8.
  They need no `jsToNumber` and no `DIVERGES` hunk for these calls.
- The nine test overrides, the four test controllers and the pin group of phase 5 change.
  `DemoChart` gets one member.
- A later scale or a custom scale of user code takes `Object? value`. A custom scale with
  `double value` fails with `invalid_override`.
- The four bodies of section 3 hold the upstream expression twice. A bump that changes one of
  these bodies changes both copies. The pin test of section 3 fails when the copies differ for a
  number.

## Open

1. **The fast path of the other bodies.** Phase 7 measures `TimeSeriesScale.getDecimalForValue`
   and the radial `getDistanceFromCenterForValue` in the stress mode `chart` with a `timeseries`
   axis and with a radar chart. A measured gain adds the branch of section 3 with its pin test and
   a record in `performance.md`. It needs no new ADR.
2. **The frame figures.** Phase 7 records the stress mode `chart` with a logarithmic value axis
   and `CALL=update` on the platforms of [performance.md](../performance.md) §6.
3. **`prefer-inline` on `jsToNumber`.** In the draft benchmark of Fidelity, B1 with a
   `prefer-inline` `jsToNumber` gave the AOT figures of BF. On wasm, it gave them for the linear
   pair only. The pragma changes each other call of `jsToNumber` in `lib/` (152 lines on
   2026-10-20) and the code size. No benchmark measured these effects. That change needs its own
   measurement.
4. **An interface call or a cast for `getDataVisibility`.** The bar, doughnut and polar area
   controllers call it for each element (`controller.bar.js:592`, `controller.polarArea.js:180`).
   A cast and a direct call are 1.0-3.5 ns faster than the interface call. Phase 7 decides with the
   performance rule.
5. **A record or a class for `{x, y, angle}`.** The class is 3.5-4.5 ns faster for each call. A
   change needs a new ADR that supersedes the record rule of Chart.js ADR 0003.
6. **String tick bounds.** `scale.linearbase.js:258-259` gives the raw `min` and `max` options to
   `generateTicks`, which pushes them as tick values (`:111`, `:138`). A string bound, for example
   `min: '5'`, gives a string tick value upstream. `Tick.value` stays `double` (`index.d.ts:1165`).
   The port of `scale.linearbase` decides the form of that hunk.
7. **The filler targets.** The filler of phase 8 wraps the records of `getPointPositionForValue`
   as point elements (`adapt-line-points-elements`).

## Evidence

All files are in the session scratchpad folder
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/ec6419b7-7aa8-4614-a4a2-aaaa926985fd/scratchpad/design/`
(below: `<design>`). The probes ran Chart.js 4.5.1 (npm dist) on an x64 build of Node.js v24.12.0
under Rosetta (Chart.js ADR 0010).

- **E1, upstream source** at v4.5.1, `src/`:
  - `core/core.scale.js:145`, `:156`, `:226`, `:237`, `:239`, `:247`, `:410`, `:881-912`,
    `:943-945`, `:1064`, `:1077`, `:1182`, `:1191`, `:1451-1463`
  - `core/core.controller.js:885-887`, `core/core.datasetController.js:662-674`
  - `scales/scale.category.js:4-23`, `:70-78`, `:133-153`
  - `scales/scale.linear.js:44-50`
  - `scales/scale.linearbase.js:111`, `:138`, `:164-179`, `:258-259`, `:274`
  - `scales/scale.logarithmic.js:95-110`, `:172`, `:210-225`
  - `scales/scale.time.js:258-269`, `:387`, `:440-450`, `:562-584`, `:638-642`
  - `scales/scale.timeseries.js:12-32`, `:119`, `:162-174`
  - `scales/scale.radialLinear.js:139-198`, `:422-423`, `:463`, `:489-535`, `:556`
  - `helpers/helpers.math.ts:79-93`, `helpers/helpers.extras.ts:105`, `:121`
  - `controllers/controller.line.js:100-101`, `controller.scatter.js:129-130`,
    `controller.bubble.js:129-130`, `controller.bar.js:8-17`, `:42-48`, `:396`, `:540`,
    `:549-550`, `:564-620`, `:655`, `controller.radar.js:82-91`, `controller.polarArea.js:164-180`
  - `plugins/plugin.filler/filler.options.js:80-114`, `filler.target.js:45-95`
  - `types/index.d.ts:542`, `:610`, `:1165`, `:1273-1360`, `:3627-3639`
- **E2, upstream specs** at v4.5.1: `scale.category.tests.js:222-248`, `:514-541`,
  `scale.radialLinear.tests.js:330-385`, `:461-507`, `:626-652`, `scale.time.tests.js:115`,
  `:448`, `:453`.
- **E3, probe P1:** `<design>/values-fidelity/probe_values.mjs`, output `probe_values.out`
  (11 rows differ, 62 rows agree).
- **E4, probes P2 and P2b:** `<design>/values-fidelity/probe_charts.mjs` and
  `probe_charts_tonumber.mjs`, outputs `probe_charts.out` and `probe_charts_tonumber.out`. The
  judge re-ran both: `<design>/values-judge/fid_charts.out` and `fid_charts_tn.out` are
  byte-identical.
- **E5, probe P4:** `<design>/values-simplicity/p4_option_a.mjs`, output `p4_option_a.out`. The
  judge re-run `<design>/values-judge/simp_p4.out` is byte-identical.
- **E6, probe P5:** `<design>/values-performance/probe/p2_timeseries_null.mjs`, output
  `p2_timeseries_null.out`.
- **E7, scans:**
  - The scale members that the controllers and the filler read:
    `grep -ohE "\b(iScale|vScale|rScale|xScale|yScale|scale)\??\.[_a-zA-Z]+" src/controllers/*.js`,
    and the same scan over `src/plugins/`.
  - The callers of the value methods:
    `grep -rnE "getPixelForValue|getDistanceFromCenterForValue|getPointPositionForValue|getDecimalForValue|getValueForDistanceFromCenter|getBasePosition" src`.
  - The `_` reads of the scale specs: `grep -noE "\._[a-zA-Z]+" test/specs/scale.*.tests.js`. It
    finds `_pointLabels`, `_pointLabelItems`, `_unit` and `_adapter`, and the `_adapters._date`
    of Chart.js ADR 0024.
  - The fakes: `<design>/values-simplicity/fakes.py`, output `fakes_scan.out`. Of the classes
    that implement `types.Chart`, `types.Scale` or `types.DatasetController` in the tests,
    `chartjs_test_utils` and the gallery, only `DemoChart` has no `noSuchMethod`. A second scan
    on 2026-10-20 over `packages/*/test`, `packages/*/tool` and `apps/*/lib` gave the same result.
  - The overrides: `grep -rn "getPixelForValue(double value"` over `packages` and `apps` gives 9
    tracked files outside `lib/src`, and one untracked file of another session.
- **E8, the value parameter benchmark:** `<design>/values-judge/bench/bin/bench.dart`, outputs
  `<design>/values-judge/bench/aot_{1,2,3}.out`, `aot2_{1,2,3}.out`, `wasm_{1,2,3}.out` and
  `wasm2_{1,2,3}.out`. The bench imports `lib/src/js/js_number.dart` and `js_undefined.dart`,
  copied unchanged. The draft benchmarks (`<design>/values-fidelity/bench/bench.dart`,
  `<design>/values-performance/bench/bin/bench.dart`,
  `<design>/values-simplicity/bench/bin/bench.dart`) gave figures in the same direction.
- **E9, the parsed read:** `<design>/values-fidelity/bench/bench3.dart`, outputs
  `<design>/values-fidelity/bench/run3_aot_{1,2,3}.out` and `run3_wasm_{1,2,3}.out`.
- **E10, record or class, interface or cast:** `<design>/values-performance/bench/bin/position.dart`
  (output `pos_run.txt`) and `visibility.dart` (output `vis_run.txt`). The judge re-ran
  `position.dart` on AOT: record 24.6-25.1 ns, class 20.5-21.0 ns.
- **E11, the analyzer probes** on Dart 3.12.2:
  - `<design>/values-simplicity/name_probe.dart`: subclasses of the current `Scale` with
    `startValue`, `endValue`, `valueRange`, `offsets`, `generate`, `unit`, `adapter`,
    `pointLabels` and `pointLabelItems`, and a `Scale` subclass with `implements MinMax` and no
    new member, pass `dart analyze`.
  - `<design>/values-simplicity/override_probe.dart` and
    `<design>/values-fidelity/dartprobe/lib/probe.dart`: an override with `double value` of a
    member with `Object? value` gives `invalid_override`. A field `List<Tick>? ticks` implements a
    getter `List<types.Tick>? get ticks`.
