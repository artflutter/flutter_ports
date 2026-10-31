# Chart.js ADR 0017: Element properties

- Status: accepted (2026-10-21)
- Superseded in part by: [Chart.js ADR 0054](0054-typed-internal-model.md) (2026-10-31), for §3, §4, §5 and §7
- Date: 2026-10-19
- Related: [Chart.js ADR 0003](0003-type-only-dependencies.md) (type-only dependencies),
  [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (options and the `undefined`
  sentinel), [Chart.js ADR 0010](0010-js-numeric-semantics.md) (JS numeric semantics),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (names), [Chart.js ADR 0013](0013-canvas-model.md)
  (canvas model), [porting-flow.md](../porting-flow.md) §5 (phase 4)

## Context

Phase 4 ports `src/core/core.element.ts` and the four elements of `src/elements/`. A Chart.js
element is an open JavaScript object:
- The constructors set the start values and then call `Object.assign(this, cfg)`
  (`element.point.ts:49-59`, `element.arc.ts:336-351`). Most start values are `undefined`. Some
  are not: `active = false` (`core.element.ts:13`), `pixelMargin = 0` and `fullCircles = 0`
  (`element.arc.ts:345-346`), and `animated = true`, `_decimated = false` and
  `_pointsUpdated = false` (`element.line.js:282`, `:290-291`).
- `getProps(props, final)` returns the element itself, or a new plain object with the final value
  of each animated property (`core.element.ts:33-44`). The callers destructure the result.
- Phase 5 writes properties by name. `core.animations.js:101` writes `target[prop] = value`.
  `core.datasetController.js:900` calls `Object.assign(element, properties)`. The controllers also
  add properties that `core.element.ts` does not declare, for example `$context`
  (`core.datasetController.js:767-768`).
- Other modules write properties that the element constructor does not set, and the element code
  reads them. `controller.bar.js` writes `borderSkipped` and `enableBorderRadius`
  (`controller.bar.js:207-231`, `:410`). `helpers.curve.ts` writes the control points `cp1x`,
  `cp1y`, `cp2x` and `cp2y` on the point elements (`helpers.curve.ts:105-111`, `:173-178`,
  `:212-215`). `controller.radar.js:96` writes `angle`.
- `core.animation.js:29-32` reads the current value with `target[prop]` and resolves the start
  value with `resolve([cfg.from, currentValue, to])`. An `undefined` current value gives the
  target value. A NaN current value gives NaN.
- `element.arc.ts:364` reads `valueOrDefault(circumference, endAngle - startAngle)`. An
  `undefined` circumference gives the difference. A NaN circumference gives NaN.
- `LineElement` has accessor properties: `set points` and `get points`
  (`element.line.js:308-317`), and `get segments` without a setter (`:319-321`).
- The classes carry static members: `id`, `defaults`, `defaultRoutes` and `descriptors`
  (`element.line.js:245-277`). The registry of phase 5 reads them.
- `index.d.ts:1816-1823` declares `VisualElement`, with `draw`, `inRange`, `inXRange`, `inYRange`,
  `getCenterPoint` and the optional `getRange`. Not every class has each method:
  `element.arc.ts` has no `inXRange` and no `inYRange`, and `element.line.js` has no `inRange`,
  `inXRange`, `inYRange` and `getCenterPoint`.
- Upstream assigns an option value to a canvas setter as it is, for example
  `ctx.lineWidth = options.borderWidth` (`element.point.ts:97`). The DOM converts the value with
  the WebIDL type of the setter.
- The upstream specs construct elements from object literals with integer numbers, for example
  `new Chart.elements.PointElement({options: {radius: 2, hitRadius: 3}, x: 10, y: 15})`
  (`element.point.tests.js:6-13`).

Dart has no open objects. The port needs typed members for the hot paths (`draw` and `inRange`
run for each element in each frame) and access by name for phase 5.

## Decision

### 1. Classes and methods

- `Element` in `lib/src/core/core.element.dart` is a concrete class, because
  `core.element.tests.js:4` constructs it. It implements `types.Element`.
- Each element class extends `Element`. It implements `types.VisualElement` and, where
  `lib/src/types/index.dart` declares one, its own interface: `PointElement` implements
  `types.RadialPointElement`, and `LineElement` implements `types.LineElement`.
- `types.Element` implements `Point`, because ported code passes an element where upstream
  expects a point (`_isPointInArea(this, …)`, `element.point.ts:92`).
- `types.PointElement` implements `SplinePoint` in the same way. `_updateBezierControlPoints`
  takes `SplinePoint[]` (`helpers.curve.ts:186-187`), and `updateControlPoints` passes the point
  elements of the line (`element.line.js:303`). TypeScript accepts them by structure. Thus
  `element.line.dart` passes its list of point elements to `helpers.curve`, `_bezierCurveTo` and
  `_bezierInterpolation` without a cast.
- An interface that an element file declares stays in that file. `element.arc.ts:292` declares
  `ArcProps`, and `index.d.ts:16` re-exports it. Thus `ArcProps` is an interface of
  `element.arc.dart`, and `ArcElement` implements it. In the same way, `PointProps`
  (`element.point.ts:18`) is a `typedef` of `element.point.dart`.
- `types.VisualElement` declares `draw`, `inRange`, `inXRange`, `inYRange` and `getCenterPoint`.
  `getRange` is optional in TypeScript. Dart has no optional member. Thus `getRange` stays out of
  the interface until a phase 5 caller needs it. The classes with an upstream `getRange` declare
  it:
  - `PointElement.getRange([String? axis])`. The upstream method takes no parameter
    (`element.point.ts:102`). `core.interaction.js:54` calls it with the axis. The optional
    parameter accepts the axis and has no effect, as JavaScript ignores an extra argument.
  - `BarElement.getRange(String axis)` (`element.bar.js:223`).
- `draw` takes the context and an optional `ChartArea?`. Each class names the second parameter
  `area`, as `types.VisualElement.draw` does, because the lint `avoid_renaming_method_parameters`
  forbids another name. The upstream name in `element.line.js:427` is `chartArea`. The upstream
  `draw` of `element.arc.ts:394` and `element.bar.js:179` takes only the context. These classes
  ignore `area`, as JavaScript ignores an extra argument. `LineElement.draw` also takes the
  optional `start` and `count`.
- An element class that does not have an upstream method that `types.VisualElement` declares
  still implements the method, with one of two results:
  - When the upstream caller tests for the method before it calls the method, the result is the
    result of that test for an absent method. `getAxisItems` calls `inXRange` and `inYRange` only
    after the test `element[rangeMethod] &&` (`core.interaction.js:233-234`). Thus
    `ArcElement.inXRange` and `ArcElement.inYRange` give false. A direct call gives false where
    JavaScript throws a `TypeError` (difference `adapt-arc-axis-range`).
  - Else the method throws a `NoSuchMethodError`, where JavaScript throws a `TypeError` for the
    call of `undefined`. Examples are `LineElement.inRange` and `LineElement.getCenterPoint`. A
    line element is the dataset element of its controller, not a data element
    (`controller.line.js:43`). The interaction code reaches only the data elements
    (`core.interaction.js:78-83`). Thus no upstream caller tests for a method of a line element,
    and `LineElement.inXRange` and `LineElement.inYRange` also throw.

### 2. Static members

- `id` is a `static const String`.
- `defaults`, `defaultRoutes` and `descriptors` are `static final` Maps (`AnyObject`) with the
  upstream contents, in the upstream key order. `Element.defaults` is an empty Map.
- `Element.defaultRoutes` is `static const Object defaultRoutes = undefined`
  (`core.element.ts:9`). Its value is the `undefined` sentinel, which is a constant. The lint
  `prefer_const_declarations` requires `const` for a field with a constant value.
- A function value of `descriptors`, for example `_indexable`, is a Dart closure
  ([Chart.js ADR 0006](0006-options-representation-and-resolver.md)).
- The registry of phase 5 decides how it reads the static members of a class.

### 3. Typed properties

- Each upstream instance property is a Dart member with the upstream name. An instance property
  is a property that the upstream constructor sets or that the upstream class declares. Numbers
  are `double` ([Chart.js ADR 0010](0010-js-numeric-semantics.md)).
- An `_`-prefixed property that another module reads or writes drops the underscore and carries
  `@internal` ([Chart.js ADR 0012](0012-dart-file-naming.md)). Examples are `_datasetIndex` →
  `datasetIndex` (`helpers.segment.js:282` reads it) and `_loop` → `loop`
  (`helpers.segment.js:247` and `filler.drawing.js:23` read it) of `LineElement`.
- A property that only its own file reads keeps the underscore. Examples are `_path`, `_points`,
  `_segments` and `_pointsUpdated` of `LineElement`. Only `element.line.js` reads and writes
  `_path` (`element.line.js:208-210`, `:311`, `:442`). Also, the name `path` is the method
  `path(ctx, start, count)` (`element.line.js:406`). Other code reads these properties by name,
  for example `line['_path']`.
- A class also declares a property that upstream does not set in the constructor, when the code
  of the element reads it or when a nominal type of the port needs it:
  - `BarElement.borderSkipped` and `BarElement.enableBorderRadius`. `controller.bar.js` writes
    them through `updateElement` (`controller.bar.js:207-231`, `:410`). `draw` reads them
    through `boundingRects` (`element.bar.js:43`, `:55`, `:59`).
  - `PointElement.cp1x`, `cp1y`, `cp2x` and `cp2y`. `helpers.curve.ts` writes them, and
    `_bezierCurveTo` and `_bezierInterpolation` read them. `types.PointElement` implements
    `SplinePoint` (section 1), which declares them (`geometric.d.ts:48-51`).
  - `PointElement.angle`. `controller.radar.js:96` writes it, and `helpers.segment.js` reads
    `point[property]` with the property `'angle'` (`helpers.segment.js:12`, `:47`, `:104`). The
    point element implements `types.RadialPointElement`, which declares it.
- `BarElement.inflateAmount` is an upstream instance property: the constructor sets it to
  `undefined` (`element.bar.js:172`). `controller.bar.js:252-256` writes the number, and `draw`
  reads it (`element.bar.js:180`).
- A boolean property with a defined start value that upstream never sets to `undefined` is a
  non-nullable `bool` field: `active` (`core.element.ts:13`), and `animated`, `_decimated`
  (`decimated`) and `_pointsUpdated` of `LineElement` (`element.line.js:282`, `:290-291`). Every
  upstream write gives a boolean: `element.active = active` (`core.datasetController.js:920`),
  where each caller passes `true` or `false` (`:930`, `:934`, `:944`, `:955`),
  `animated: !animationsDisabled` (`controller.line.js:68`),
  `line._decimated = !!_dataset._decimated` (`controller.line.js:59`), and the writes of
  `_pointsUpdated` in `element.line.js` (`:304`, `:312`, `:441`).

### 4. The `undefined` state

- Each numeric property has a nullable private field, also a property with a defined start value.
  `ArcElement.pixelMargin` and `ArcElement.fullCircles` start at 0, and their fields are
  `double?`. Thus a write by name of the `undefined` sentinel (section 5) works for every
  numeric property.
- Each other property that starts `undefined` also has a nullable private field with a public
  getter and setter. `options` and `$animations` of `Element` are the exceptions: they are
  public nullable fields. Thus their readers get the nullable type, as for each object property,
  and a Dart write of `null` also stores `undefined`. `_path`, `_points` and `_segments` of
  `LineElement` (section 3) are further exceptions: they are private nullable fields with no
  getter or setter of their own. Other code reads and writes them by name (section 5). `_points`
  is also the field of the upstream accessor `points`.
- Dart `null` in such a field stands for JS `undefined`
  ([Chart.js ADR 0006](0006-options-representation-and-resolver.md), "Values outside scopes").
  JS `null` never reaches these properties in Chart.js. The `///` line says so.
- The public getter of a numeric property returns `double`. It gives NaN for `undefined`, which
  is the `ToNumber` of `undefined`. Thus arithmetic and comparisons give the upstream result, and
  an element is a `Point` with the `Point` rules of `geometric.dart`.
- The public getter of a boolean or object property returns the nullable type. Readers apply the
  JS `ToBoolean` with `jsTruthy` or `== true`.
- The public setter takes the non-null type. Only access by name (section 5) stores `undefined`
  again.
- A reader that must tell `undefined` from NaN reads the property by name or through `getProps`.
  An example is `valueOrDefault(circumference, …)` (`element.arc.ts:364`). The port of each site
  that reads a NaN getter makes sure that NaN gives the upstream result for `undefined` there.
  Two sites compare the value of `undefined` with itself, where `undefined === undefined` is
  true and `NaN === NaN` is false:
  - `_boundSegment` (`helpers.segment.js:104-108`) skips a point whose value equals the previous
    value. It reads the `undefined` state of `x` and `y` through `types.ElementPropertyRead`, the
    read by name of `lib/src/types/index.dart`. Thus `helpers.segment.dart` does not import
    `core.element.dart` ([Chart.js ADR 0003](0003-type-only-dependencies.md)).
  - The fast path of the line (`element.line.js:128`, `:172`) tests `minY !== maxY`. It keeps an
    `undefined` first y of a group as Dart `null`.
- Three getters do not follow these rules, because an existing interface of
  `lib/src/types/index.dart` declares their type:
  - `PointElement.angle` returns `double?`, as `types.RadialPointElement.angle` declares. It gives
    Dart `null` in the `undefined` state. The extension `PointElementProperty` reads it as
    `point['angle']` and gives NaN for `null`.
  - `LineElement.datasetIndex` (`_datasetIndex`) returns `double?`, as
    `types.LineElement.datasetIndex` declares. `doSplitByStyles` copies the value into the
    segment context (`helpers.segment.js:282`, `:321`), where an own `undefined` key and an absent
    key are two states. The port copies `null` as the `undefined` sentinel.
  - `LineElement.points` returns the non-null `List<types.PointElement>`, as the port interface
    `types.LineElement.points` has declared since phase 2. Upstream declares `points: Point[]`
    (`index.d.ts:1981`). The port narrows the type on purpose, because `helpers.segment` reads
    `skip` and `stop` of each point, `helpers.curve` writes its control points, and the line
    reads them. A write of another list throws an `ArgumentError` (difference
    `adapt-line-points-elements`). The getter throws a `TypeError` in the `undefined` state.
    Each upstream reader dereferences the value, which throws a `TypeError` for `undefined`:
    `_computeSegments` (`helpers.segment.js:239-241`), `pathVars` (`element.line.js:41`) and
    `path` (`element.line.js:412`). `LineElement.draw` reads the field, as upstream reads
    `this.points || []` (`element.line.js:429`).

### 5. Access by name

- `Element` has `Object? operator [](String prop)` and `void operator []=(String prop, Object?
  value)`. They stand for the JS property read `element[prop]` and the write
  `element[prop] = value`. The names are the upstream JavaScript names, also for a member whose
  Dart name drops the underscore.
- The read gives the stored value. It gives the `undefined` sentinel for a property in the
  `undefined` state and for an unknown name.
- `Element` also implements `types.ElementPropertyRead` of `lib/src/types/index.dart`, the
  interface of the read. A ported helper that must tell `undefined` from NaN reads a point
  through it, without an import of `core.element.dart` (section 4).
- `Element` handles `x`, `y`, `active`, `options` and `$animations`. Each subclass handles its own
  names in a `switch`, and passes other names to `super`.
- A JS object accepts any property. Thus `Element` keeps a Map of extra properties, created at
  the first write of an unknown name. A read of an unknown name reads this Map.
- The write converts the value with a protected function of `Element`:
  - `toNumberProp`: a numeric property accepts a `num`, which becomes a `double`, or the
    `undefined` sentinel.
  - `toBoolProp`: a boolean property that can be `undefined` accepts a `bool` or `undefined`.
  - `toDefinedBoolProp`: a boolean property of section 3 that is never `undefined` accepts only
    a `bool`.
  - `toObjectProp`: an object property accepts its type or `undefined`. Examples are `options`,
    `$animations`, `PointElement.parsed`, `BarElement.borderSkipped` and the `_chart`, `_path`,
    `_points` and `_segments` of `LineElement`.
- Another value is outside the upstream type contract. The write throws an `ArgumentError`. This
  is not a `DIVERGES` hunk.
- One write throws for a value inside the upstream contract: a list of plain points for `points`
  or `_points` of `LineElement`. Upstream declares `Point[]`, and the port accepts only point
  elements (section 4, difference `adapt-line-points-elements`). No ported caller passes plain
  points before the filler of phase 8 (Open).
- An accessor property of upstream keeps its accessor behavior:
  - A write of `points` to a `LineElement` goes through the setter. It also drops the cached
    segments, the cached path and the control points state (`element.line.js:308-313`). A write
    of `_points` writes the field only. A read of `points` gives `_points`
    (`element.line.js:315-317`).
  - `segments` has only a getter (`element.line.js:319-321`). A read by name computes the
    segments, as the getter does. A write by name throws an `ArgumentError`, where JavaScript
    throws a `TypeError` in strict mode, the mode of an ES module.

### 6. Constructors

- `XElement([AnyObject? cfg])` sets the defined start values of section 3 and section 4 in the
  upstream order. Then it calls `assign(cfg)`, as upstream calls `Object.assign(this, cfg)`
  (`element.point.ts:57-59`, `element.arc.ts:348-350`, `element.bar.js:174-176`,
  `element.line.js:294-296`). Dart `null` for `cfg` stands for a falsy JS value.
- `Element.assign(AnyObject source)` is public. It is `Object.assign(this, source)`: it writes each
  key of `jsObjectKeys(source)` through `operator []=`, in the `Object.keys` order. A value
  outside the type of a declared property throws an `ArgumentError` after the writes of the keys
  before it. The constructors call it, and `updateElement` of phase 5 calls it with the new
  properties (`core.datasetController.js:900`).
- A spec object literal becomes a Dart Map literal. An integer becomes a `double` at the write.

### 7. `getProps`

- `ElementProps getProps(List<String> props, [bool? isFinal])`. `final` is a reserved word in
  Dart. Thus the parameter is `isFinal`.
- `ElementProps` is an interface of `core.element.dart` with `Object? operator [](String prop)`.
  `Element` implements it. Thus the branch that returns `this` allocates nothing.
- The other branch returns an `ElementProps` over a new Map, as upstream returns a new plain
  object.
- Callers read a number from the result with `jsToNumber`, which is the `ToNumber` that upstream
  arithmetic applies. They read a boolean with `jsTruthy`.
- `$animations` is a `Map<String, types.Animation>?`. Dart `null` stands for `undefined`.
  `lib/src/types/animation.dart` declares `Animation` with the members that `getProps` reads:
  `active()` and `to` (`_to`, [Chart.js ADR 0012](0012-dart-file-naming.md)).

### 8. Options and object values

- `options` is the resolved options object of the element, a `Map<String, Object?>?`
  ([Chart.js ADR 0006](0006-options-representation-and-resolver.md)). Dart `null` stands for the
  `undefined` start value.
- A read whose result differs for an absent key and for JS `null` uses `jsGet`. A typed Map read
  `options[key]` stays where both give the same result. `jsGet` also throws the `TypeError` of a
  property read of `undefined` when `options` is in the `undefined` state.
- A numeric option that upstream uses in arithmetic or a comparison is read with `jsToNumber`.
- The JS form `value || 0` before arithmetic is `jsOrZero(value)` of `lib/src/js/js_number.dart`.
  A falsy value gives 0. Another value gives its `ToNumber`. Examples are `options.radius || 0`
  (`element.point.ts:83-85`) and `options.offset || 0` (`element.arc.ts:396-397`).
- A helper that takes a typed options interface, for example `drawPoint` with
  `DrawPointOptions`, gets an adapter over the Map. The adapter is a class of the element file.
- An object-valued property other than `options` follows the same rules. `BarElement.borderSkipped`
  is a JS plain object, thus a `Map<String, Object?>?`. The bar reads its edges as property reads
  (`skip.top`, `element.bar.js:47-50`, `:66-69`) with `jsGet`, and tests them with `jsTruthy`.
  Thus `draw` throws a `TypeError` when `borderSkipped` is in the `undefined` state, as upstream
  does.
- The canvas interface ([Chart.js ADR 0013](0013-canvas-model.md)) takes typed values, and it
  ignores Dart `null`. The DOM setters take any value and convert it with their WebIDL type.
  Thus ported code converts an option value at the call with a function of the port-only
  `lib/src/js/js_webidl.dart`. Each function gives the value that the DOM uses, or Dart `null`
  where the DOM ignores the value:
  - `canvasStyle` for `fillStyle` and `strokeStyle`: the `undefined` sentinel gives Dart `null`.
    Another value passes as it is.
  - `canvasNumber` for an `unrestricted double`, for example `lineWidth` and `lineDashOffset`:
    the `undefined` sentinel gives Dart `null`, as the DOM ignores the NaN of `undefined`.
    Another value gives its `ToNumber`. Thus JS `null` gives 0, as in the DOM.
  - `canvasKeyword` for a `DOMString` keyword, for example `lineCap` and `lineJoin`: a `String`
    gives itself. JS `null` and the `undefined` sentinel give Dart `null`, as the DOM ignores
    `'null'` and `'undefined'`. Another value gives its `ToString`.
  - `canvasLineDash` for the `sequence<unrestricted double>` of `setLineDash`: a `List<double>`
    gives itself, and another `List` gives the `ToNumber` of each item. A value that is not a
    `List`, for example `undefined`, throws a `TypeError`, as the DOM does.
- These functions model the DOM, not `core.element.ts`. Thus they are in `lib/src/js/`. The
  dataset controllers of phase 5 and the plugins of phase 8 assign option values to the same
  setters, and they call these functions too.
- The mock context of chartjs-test-utils records the value that a setter gets. Thus it records
  Dart `null` where upstream records `undefined`. In the recorded calls, Dart `null` stands for
  JS `undefined`, as for an absent argument (the `differences.md` row
  `harness-mock-optional-args`).

### 9. Returned points

- `tooltipPosition` and `getCenterPoint` return an `ElementPoint`, a `Point` of
  `core.element.dart` with `x`, `y`, `==` and `hashCode`. It stands for the object literal
  `{x, y}`. Thus a spec compares it with `equals`.
- The coordinates are `double`. A copied `undefined`, for example the `x` of an element in the
  `undefined` state, becomes NaN, its `ToNumber`, as the `Point` rules of `geometric.dart` state.
- Two points are equal when their coordinates are equal. NaN equals NaN, as in the `toEqual` of a
  spec. 0 equals -0, as the Dart `==` of two numbers gives. `hashCode` gives one value for all NaN
  values and one value for 0 and -0.

### 10. Pure layers and tests

- `core.element.dart`, `lib/src/elements/` and `lib/src/js/js_webidl.dart` import only pure
  layers. Thus they are pure-layer roots of tool 1 (`tool/src/lib_imports.dart`).
- Their specs and port-only tests use `package:test`. They run on the VM, with dart2js and with
  dart2wasm.

### 11. `Path2D`

- `element.line.js:233` tests `typeof Path2D === 'function'`. The Dart `Path2D` of the canvas
  interface always exists. Thus the test is the constant `true`, as in every browser that
  Chart.js supports. The canvas layer keeps the converted path in `Path2D.cache`
  ([Chart.js ADR 0013](0013-canvas-model.md)).

## Alternatives considered

- **All properties in a Map.** Access by name is simple. But each typed read is a hash lookup and
  a cast, and `draw` and `inRange` read several properties for each element in each frame.
  Rejected.
- **NaN for `undefined` without a nullable field.** It loses the `undefined` state that
  `core.animation.js:29-32` and `element.arc.ts:364` read. A new element would animate from NaN
  on its first update and stay invisible during the animation. Rejected.
- **`dynamic` access or `noSuchMethod`.** No static types, slow calls on AOT, and no write by name
  of a field. Rejected.
- **A record type for each `getProps` result.** Dart cannot express `Pick<T, P>` for a list of
  names. Rejected.
- **Generated name access.** A code generator adds a build step for about 40 properties. Rejected.
- **The option conversions in `core.element.dart`.** They model the WebIDL conversions of the DOM,
  not a function of `core.element.ts`. The controllers and the plugins need them too. With this
  location, they import `core.element.dart` for a rule of the DOM. Rejected.
- **A cast of each point to `SplinePoint` in `element.line.dart`.** A cast view of a list
  (`List.cast`) checks the type at each access, in the hot path of `updateControlPoints`. A cast
  of each point adds a check for each line segment. Rejected.

## Consequences

- Phase 5 writes properties with `operator []=` and `assign`: the animations
  (`core.animations.js:101`) and the `Object.assign` of `updateElement`
  (`core.datasetController.js:900`). It reads them with `operator []` (`core.animation.js:29`).
- Properties that a controller adds and the class does not declare go to the Map of extra
  properties. A later phase declares a property when the code of the element reads it, when a
  nominal type needs it, or when a ported caller reads it often (section 3).
- Each element class carries one `switch` over its property names for the read and one for the
  write.
- A write of JS `null` or of a string to a numeric property throws.
- A fake of `types.PointElement` in a test implements the four control points of `SplinePoint`.
- The dataset controllers and the plugins import `lib/src/js/js_webidl.dart` for the option
  values that they assign to canvas setters.

## Open

- The form in which the registry of phase 5 reads `id`, `defaults`, `defaultRoutes`,
  `descriptors` and the constructor of a class.
- `getRange` in `types.VisualElement` (phase 5). `core.interaction.js:54` tests
  `typeof el.getRange === 'function'` before the call.
- The plain points of the filler (phase 8). `_createBoundaryLine` (`filler.helper.js:28-33`)
  passes the `{x, y}` objects of `_pointsFromSegments` (`filler.segment.js:65-82`) or the
  `{x, y, angle}` objects of `scale.getPointPositionForValue` (`filler.target.js:91-93`).
  `_buildStackLine` (`filler.target.stack.js:29`) passes the results of `LineElement.interpolate`
  (`:88`) that `addPointsBelow` collects (`:69-78`). They are `InterpolatedPoint`s in the port.
  The filler port either builds a `List<types.PointElement>` and wraps each point in a
  `PointElement` with the same `x`, `y` and `angle` (its `skip`, `stop` and control points stay
  `undefined`, as on the plain object), or widens `points` to `List<Point>` (difference
  `adapt-line-points-elements`).
