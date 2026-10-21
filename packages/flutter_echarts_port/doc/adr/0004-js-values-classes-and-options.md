# ECharts ADR 0004: JS values, classes and options

- Status: proposed
- Date: 2026-10-21
- Gate: ECharts phase 1 for the Dart form of the JS values (items 1-6 and 14-17). The pilot ports
  `zrender src/core/util.ts`, with `clone`, `merge`, `defaults`, `each` and `HashMap`. The class
  items (7-13) have gate 2. Phase 2 ports `util/clazz.ts`, `util/component.ts` and the model
  mixins. `Path.extend` of item 13 comes with `graphic/Path.ts` in phase 3. The element access of
  item 5 and the TS types of item 18 also have gate 2. Phase 2 ports `core/Transformable.ts` and
  `core/Eventful.ts`.
- Related:
  [Chart.js ADR 0006](../../../flutter_chartjs/doc/adr/0006-options-representation-and-resolver.md)
  (raw option Maps, the `undefined` sentinel, the three states),
  [Chart.js ADR 0020](../../../flutter_chartjs/doc/adr/0020-registry-and-component-classes.md)
  (`JsClass`, class values),
  [Chart.js ADR 0021](../../../flutter_chartjs/doc/adr/0021-typed-options-in-the-resolver.md)
  (typed options, kept for later),
  [Chart.js ADR 0022](../../../flutter_chartjs/doc/adr/0022-chart-test-harness.md) (section 5:
  fields that hold a function),
  [Chart.js ADR 0023](../../../flutter_chartjs/doc/adr/0023-underscore-member-collisions.md)
  (underscore members),
  [Chart.js ADR 0032](../../../flutter_chartjs/doc/adr/0032-js-numeric-semantics.md) (accepted
  2026-10-21: the runtime, `jsCall`, the reference engine),
  [Chart.js ADR 0034](../../../flutter_chartjs/doc/adr/0034-no-display-only-js-exactness.md)
  (accepted 2026-10-21: the protected behavior),
  [D3 ADR 0006](../../../flutter_d3_port/doc/adr/0006-generators-accessors-and-js-values.md)
  (`jsInvoke`, `absent`, `jsArgs`, `JsError`, the D3 form of `null` and `undefined`),
  [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (the shared runtime
  `js_semantics`, item 6), [ECharts ADR 0002](0002-file-naming-and-layout.md) (names,
  underscore members, port-only folders),
  [ECharts ADR 0003](0003-numbers-and-js-semantics.md) (numbers, typed arrays, `jsMathRandom`),
  [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) (the expect stand-in,
  `setUpSpecs()`, the reference generators),
  [ECharts ADR 0006](0006-renderer-and-canvas-layer.md) (the SVG DOM painter is n/a),
  [ECharts ADR 0007](0007-environment-host-and-input-events.md) (the handler proxy),
  [ECharts ADR 0008](0008-dates-locales-and-formatting.md) (dates),
  [porting-flow.md](../porting-flow.md) §1 and §2.6, [differences.md](../differences.md)

## Context

The pins are `echarts@6.1.0` (`c5a48f5f`) and `zrender@6.1.0` (`32b66867`)
([ECharts ADR 0001](0001-upstream-sources.md)). Paths without a repository name are in
`third_party/echarts/src/`. "E" is the ECharts count and "Z" the zrender count. The counts are
grep hits over `src/**/*.ts` with the comments included, unless the text says otherwise
(section Evidence).

### The two builds

- `tsconfig.json:3` of both repositories sets `"target": "ES3"`. The shipped `dist/echarts.js`
  thus has ES5 classes. tslib `__extends` makes them. The methods are enumerable prototype
  properties. A field without an initializer has no emitted code.
- The unit tests compile with `test/ut/tsconfig.json:3` `"target": "ES6"`. Their classes are
  native classes with methods that are not enumerable.
- Two places see the difference:
  - `isESClass` (`util/clazz.ts:131-134`) is true in the tests. It is false in the dist. It
    selects the branch of `enableClassExtend` (`util/clazz.ts:96-117`).
  - `mockMethods` (`core/Scheduler.ts:672-679`) copies each `for-in` key of a class prototype
    (`:674`). The dist mock has every method. The ES6 mock has only the prototype writes and the
    mixin methods. The mock serves legacy stage handlers of extensions
    (`core/Scheduler.ts:639-655`).
- Neither place reaches a chart result of the specs or of the curated reference charts.
- `build/config.js:54-62` writes `dist/echarts.js` with `process.env.NODE_ENV` set to
  `'development'`. `build/transform-dev.js:28,43` replaces `__DEV__` with
  `process.env.NODE_ENV !== 'production'`. Thus `__DEV__` is true in `dist/echarts.js`. It is false
  in `dist/echarts.min.js`. The jest config sets `'__DEV__': true` (`test/ut/jest.config.cjs:36`).

### Field initializers

- TypeScript with `useDefineForClassFields` off runs a subclass field initializer after the whole
  `super(...)` call. Dart runs it before the superclass constructor body.
- zrender `Element` calls the virtual `this._init(props)` from its constructor
  (`zrender@6.1.0 src/Element.ts:529-536`). `Displayable` and `Path` override `_init`
  (`zrender@6.1.0 src/graphic/Displayable.ts:219`, `src/graphic/Path.ts:209`).
- A field that `_init` writes and that a subclass initializes thus gets two different values. TS
  keeps the initializer value. Dart keeps the `_init` value. A field that `_init` reads is
  `undefined` in TS. In Dart, it already has its initializer value.
- A Dart probe confirmed the order (section Evidence).
- ECharts states the same hazard for `extend` in a comment (`model/Component.ts:55-63`). Its
  classes still use initializers, for example `type = LineSeriesModel.type;` and
  `hasSymbolVisual = true;` (`chart/line/LineSeries.ts:139`, `:145`).

### Feature counts

| Feature | E | Z | Sites |
|---|---:|---:|---|
| `class X extends` | 186 (162 files) | 40 (36 files) | plain TS inheritance |
| `enableClassExtend(` | 11 hits, 3 calls | 0 | `model/Model.ts:250`, `view/Chart.ts:267`, `view/Component.ts:139` |
| `enableClassManagement(` | 7 hits, 4 calls | 0 | `scale/Scale.ts:128`, `model/Component.ts:371`, `view/Chart.ts:268`, `view/Component.ts:140` |
| `enableClassCheck(` | 3 hits, 1 call | 0 | `model/Model.ts:251` |
| `mountExtend(` | 3 hits, 2 calls | 0 | `model/Component.ts:370`, `model/Series.ts:766` |
| `static type =` | 128 | 0 | `chart/line/LineSeries.ts:138` |
| `static defaultOption` | 57 | 0 | plus `inheritDefaultOption(` |
| `static protoInitialize` | 4 | 0 | `model/Component.ts:144`, `model/Series.ts:212`, `view/Chart.ts:132`, `data/helper/dataProvider.ts:98` |
| `static initDefaultProps` | 0 | 6 | `Element.ts:1738`, `core/PathProxy.ts:989`, `core/Transformable.ts:349`, `graphic/TSpan.ts:89`, `graphic/Displayable.ts:657`, `graphic/Path.ts:673` |
| `X.prototype.y =` | 9 | 23 | zrender shape `type` strings, `coord/polar/AngleAxis.ts:120-122` |
| `mixin(` | 20 (19 calls) | 2 | one instance mixin: `coord/radar/RadarModel.ts:179` |
| `registerSubTypeDefaulter(` | 8 | 0 | legend, dataZoom, visualMap, timeline, axis |
| `makeInner` declarations | 57 (50 files) | 0 | `util/model.ts:750-755` |
| ad hoc `__name` properties | 84 names | 40 names | `el.__t`, `model.__viewId` |
| `createHashMap(` | 36 | 1 | `zrender@6.1.0 src/core/util.ts:749-808` |
| `merge(` / `defaults(` / `clone(` | 58 / 61 / 114 | 6 / 10 / 20 | `zrender@6.1.0 src/core/util.ts:83-248` |
| `getShallow(` / `.get([` | 114 / 163 | 0 | `model/Model.ts:94-134` |
| `== null` / `!= null` | 876 (198 files) | 186 (43 files) | the null-or-undefined test |
| strict `undefined` tests in code | 2 | 4 | listed below |
| `Object.create` | 0 | 1 (4 callers) | `createObject` of `zrender@6.1.0 src/core/util.ts:822-839` |
| `this.constructor` of a class instance | 5 | 0 | listed in item 7 |
| `arguments.length` | 5 (1 in a comment) | 3 | listed in item 14 |
| `throw new Error` | 44 | 12 | |
| `__DEV__` code lines | 349 (109 files) | 0 | |

### Values and options

- Options are plain JSON trees. They also hold functions (formatters), `Date` values, typed
  arrays, gradient and pattern objects and images. The models change them in place.
  `Model.mergeOption` is `merge(this.option, option, true)` (`model/Model.ts:87-89`).
- `merge` (`zrender@6.1.0 src/core/util.ts:135-171`) recurses only into two objects that are not
  arrays, DOM nodes, builtins or "primitive" objects. Else it writes `clone(source[key])` when
  `overwrite || !(key in target)` (`:162`). Thus the presence of a key matters.
- `defaults` (`:236-248`) tests `target[key] == null`. Thus `null` and `undefined` act alike.
- `clone` (`:83-125`) copies arrays deep and copies typed arrays with their constructor. A plain
  object and an instance of a class become a plain object of their own enumerable keys
  (`:114-122`). Builtins (`:8-21`) and "primitive" objects stay the same reference.
- `setAsPrimitive` (`:679-689`) writes the own key `'__ec_primitive__'` into its argument. Its
  callers are `core/echarts.ts:616` (the chart instance), `model/OptionManager.ts:95` and `:98`
  (typed `series.data` and `dataset.source`) and `data/helper/sourceManager.ts:473` (a transform
  option).
- `each` (`:329-362`) has three branches: a native array, an array-like value with a numeric
  `length`, and an object through `for-in` with `hasOwnProperty`. `keys` (`:466-483`) is
  `Object.keys`.
- `HashMap` (`:749-802`) wraps the native `Map`. Its keys are strings and numbers with the
  SameValueZero rule. `'1'` and `1` are two keys.
- `Model.get` (`model/Model.ts:109-118`) parses a path and calls `_doGet` (`:216-242`). `_doGet`
  reads `obj[key]` while `obj && typeof obj === 'object'` (`:228-229`). It skips an empty path
  item (`:224`). It goes to the parent model when the result is `== null` (`:234-239`).
- `getShallow` (`:120-134`) reads `option[key]` also when `option` is a primitive. A raw data
  item `5` gives `(5)['value']`, thus `undefined`.
- ECharts tests `null` and `undefined` alike at 1,062 sites (876 ECharts, 186 zrender). Six code
  sites test `undefined` strictly:
  - `chart/themeRiver/ThemeRiverSeries.ts:172`: `dataItem[2] !== undefined` drops a data item
    without a third value. A third value `null` stays.
  - `chart/helper/EffectLine.ts:229`: `symbol.__lastT !== undefined`. The field is a number.
    Only `:245` writes it.
  - `zrender@6.1.0 src/svg/patch.ts:22`, `:26` and `:37`: the SVG DOM patch.
  - `zrender@6.1.0 src/core/event.ts:188`: `button !== undefined` of a DOM mouse event.
- The zrender specs assert `toBeUndefined` 3 times. The jest `toEqual` ignores a property whose
  value is `undefined` ([ECharts ADR 0005](0005-spec-harness-and-reference-tests.md)).

### Objects with a prototype

- zrender makes each style object with `createObject(DEFAULT_*_STYLE, obj)`, thus with
  `Object.create` (`zrender@6.1.0 src/core/util.ts:822-839`). The callers are
  `src/graphic/Displayable.ts:451`, `src/graphic/Path.ts:508`, `src/graphic/Image.ts:73` and
  `src/graphic/TSpan.ts:70`.
- A read of an absent key falls back to the default style. `useStyle` tests the hidden key
  `STYLE_MAGIC_KEY` of the prototype (`src/graphic/Displayable.ts:18`, `:52`, `:459-466`).
- `src/graphic/Path.ts:184-188` copies each `for-in` key of a style, the inherited keys
  included.

### Class values and registries

- `enableClassManagement` (`util/clazz.ts:227-351`) keeps a storage keyed by the main type. A
  type with a sub type (`'series.line'`) goes into a container object with the flag
  `IS_CONTAINER` (`:25`, `:343-350`). `parseClassType` (`:32-40`) splits the type. A regex
  examines it (`:45-50`).
- `registerClass` (`:242-275`) reads the static `type`, or else `prototype.type`. It writes the
  type into `prototype.type` (`:251-257`).
- `getDefaultOption` reads `this.constructor` (`model/Component.ts:252-283`). An ES class gives
  its static `defaultOption`. A static read follows the superclass chain. An `extend` class merges
  the `defaultOption` of each prototype along `superClass`.
- `enableSubTypeDefaulter` (`util/component.ts:54-78`) keeps one defaulter function for each main
  type.
- `enableClassCheck` (`util/clazz.ts:176-187`) writes a hidden prototype key with a random suffix
  (`:161`, `:177`). It mounts `isInstance`. No file of `src/` calls `isInstance`.
- `enableClassExtend` (`util/clazz.ts:77-129`) gives `extend(proto)`. It mounts `superCall` and
  `superApply` (`:195-201`). No file of `src/` outside `util/clazz.ts` calls them. The public
  API is `extendComponentModel`, `extendComponentView`, `extendSeriesModel` and
  `extendChartView` (`export/api.ts:82-104`).
- `zrender@6.1.0 src/graphic/Path.ts:624-671` is a separate `Path.extend`. It returns an ES
  subclass. Its `getDefaultStyle` and `getDefaultShape` clone the props. Its constructor calls
  `props.init`. It copies each function-valued prop onto the prototype (`:661-665`). The callers
  are the five shapes of `util/symbol.ts:43`, `:67`, `:92`, `:148` and `:272`, and the public
  `extendShape` (`util/graphic.ts:114-116`).

### Mixins, prototype writes and instance methods

- `mixin` (`zrender@6.1.0 src/core/util.ts:291-310`) copies each own property name of a prototype
  that is `== null` on the target. With `override`, it copies each source value that is not
  `== null`.
- 19 ECharts calls mix into a class. Examples: the style mixins into `Model`
  (`model/Model.ts:254-257`), `DataFormatMixin` and `PaletteMixin` into `SeriesModel`
  (`model/Series.ts:762-763`), `AxisModelCommonMixin` into four axis models, and
  `WhiskerBoxCommonMixin` with `override` (`chart/boxplot/BoxplotSeries.ts:142`).
- `data/Graph.ts:604-605` mixes a generated object of methods into `GraphNode` and `GraphEdge`.
  `createGraphDataProxyMixin` makes it (`:559-602`).
- `coord/radar/RadarModel.ts:179` mixes `AxisModelCommonMixin.prototype` into one `Model`
  instance.
- `mixinAxisModelCommonMethods` (`export/api/helper.ts:110-112`) is public. It mixes into a class
  that the caller gives.
- zrender mixes `Eventful` and `Transformable` into `Element`
  (`zrender@6.1.0 src/Element.ts:1821-1822`).
- Prototype defaults: the four `protoInitialize` blocks, the six `initDefaultProps` blocks and
  the `type` string of each zrender shape. `AngleAxis` and `RadiusAxis` alias methods of `Axis`
  (`coord/polar/AngleAxis.ts:120-122`, `coord/polar/RadiusAxis.ts:45-47`).
- `SeriesData.wrapMethod` (`data/SeriesData.ts:1365-1379`) replaces a method on one instance. The
  new method calls the old method, then the inject function. The callers wrap eight names:
  `getItemModel`, `cloneShallow`, `downSample`, `minmaxDownSample`, `lttbDownSample`, `map`,
  `filterSelf` and `selectRange` (`:258-261`). Twelve call sites wrap them, for example
  `model/Series.ts:814` and `data/helper/linkSeriesData.ts:81-91`. `transferProperties` copies
  the wrapped methods to a clone (`:1455-1465`).
- `makeInner` (`util/model.ts:750-755`) stores a record on a host under the key
  `'__ec_inner_' + n`. Most hosts are class instances. `view/Chart.ts:41-43` uses a `Payload`, a
  plain object.

### The runtime

- `js_semantics` holds the generic runtime of the Chart.js port
  ([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) item 3). It gives
  `undefined`, `jsGet`, `jsGetKey`, `jsGetIndex`, `jsObjectKeys`, `jsMapForEach`, `JsClass`,
  `jsConstruct`, `jsAssign`, `JsFunction`, `jsCall` and `JsProxyObject`.
- D3 ADR 0006 section 9 adds `JsCallable`, `jsIsCallable`, `jsInvoke`, `absent`, `jsArgs`,
  `JsError`, `JsTypeError` and `JsRangeError` in new files of `js_semantics`.
- `jsGet` gives `undefined` for an absent Map key and for a Dart object that is not a Map, a
  List, a String, a `JsProxyObject` or a `JsClass`.
- ADR 0008 item 6 puts new runtime code into new files. A change of a copied file needs the
  agreement of the Chart.js work.

## Decision

### 1. The Dart form of the JS values

- A JS value of an option tree, of a model and of the zrender API is one of these Dart values:
  - a plain object: an insertion-ordered `Map<String, Object?>` (the default `LinkedHashMap`)
  - an array: a `List<Object?>`
  - a number: a `num`. Ported code accepts an `int` from `jsonDecode` and from Dart literals. An
    `isNumber` port tests `is num`, never `is int` or `is double`.
  - a string, a boolean: `String`, `bool`
  - `null` and `undefined`: item 2
  - a function: a Dart `Function`, a `JsFunction` or a `JsCallable` (item 14)
  - a `Date`: a `DateTime` or a `JsDate` ([ECharts ADR 0008](0008-dates-locales-and-formatting.md))
  - a typed array: a list of `dart:typed_data`
    ([ECharts ADR 0003](0003-numbers-and-js-semantics.md))
  - a zrender value class: `LinearGradient`, `RadialGradient` or `Pattern`. These classes
    implement `JsObjectLike` of item 5.
  - an image: an image value of the Flutter layer. It is a builtin (item 3).
- Release 0.1.0 takes raw Map options, also the output of `jsonDecode`, as Chart.js ADR 0006
  does. A typed option API comes after 0.1.0 with its own ADR. It compiles to the same Maps.
  `util/types.ts` and the `*Option` interfaces give its shape.

### 2. `null`, `undefined` and absent

These rules adapt the three states of Chart.js ADR 0006 to ECharts:
- **Absent.** An absent key is a key that the Map does not contain. `containsKey` gives `in` and
  `hasOwnProperty`. Thus `!(key in target)` of `merge` stays exact.
- **Dart `null` for both.** Dart `null` stands for JS `null` and for JS `undefined` in the ECharts
  and zrender code. The 1,062 sites of `== null` and `!= null` become `== null` and `!= null`.
  This differs from Chart.js ADR 0006. Chart.js stores the sentinel in option scopes, because its
  resolver reads the difference. ECharts has no resolver and no `Proxy`.
- **The sentinel.** The const `undefined` of `js_semantics` appears only at these places:
  - a strict site where JS `null` can reach the value. Of the six sites, only
    `chart/themeRiver/ThemeRiverSeries.ts:172` qualifies. Its port reads the third item with
    `jsGetIndex` and compares with `identical(value, undefined)`.
  - a value that can be absent and that reaches ToNumber or ToString, where JS `null` can also
    reach it. `+undefined` is NaN. `+null` is 0. `'' + undefined` is `'undefined'`. The port
    reads such a value with `jsGetKey` or `jsGetIndex`. The review of each module lists these
    sites in the `///` line of the symbol.
  - a ported spec that asserts `undefined` on such a value
- **The other strict sites.**
  - `chart/helper/EffectLine.ts:229` becomes `__lastT != null`. JS `null` never reaches the
    field.
  - `zrender@6.1.0 src/svg/patch.ts` is n/a
    ([ECharts ADR 0006](0006-renderer-and-canvas-layer.md)).
  - `zrender@6.1.0 src/core/event.ts:188` follows the event rules of
    [ECharts ADR 0007](0007-environment-host-and-input-events.md).
- **Runtime reads.** `jsGet`, `jsGetKey` and `jsGetIndex` return the sentinel. Ported code that
  only tests `== null` maps the result with `jsNullish(value)`: `value == null` or
  `identical(value, undefined)`.
- **Specs.** A spec that asserts `undefined` on a value that the port gives as Dart `null`
  compares with `null`. This is the translation rule of D3 ADR 0006 section 6. The expect
  stand-in of [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) gives the `toEqual`
  rule for a Map key with a `null` value.

### 3. The port of `zrender src/core/util.ts`

The file ports line by line over items 1 and 2. These rules apply:
- `isObject(value)` is true for each value except `null`, the sentinel, `num`, `String` and
  `bool`. This is `typeof value === 'function' || (!!value && typeof value === 'object')`.
- `isBuiltInObject(value)` is true for the Dart forms of the eight builtins of `:8-21`: a
  `Function` or a `JsFunction`, a `RegExp`, a `DateTime` or a `JsDate`, a `JsError`, the gradient
  and pattern values of the Canvas 2D layer
  ([ECharts ADR 0006](0006-renderer-and-canvas-layer.md)), an image value and a canvas value.
  A zrender gradient class is not a builtin. It is a `JsObjectLike` value (item 5).
- `isTypedArray(value)` is true for the nine lists of `:23-36`: `Int8List`, `Uint8List`,
  `Uint8ClampedList`, `Int16List`, `Uint16List`, `Int32List`, `Uint32List`, `Float32List` and
  `Float64List`. It is false for the other `TypedData` classes.
- `isDom(value)` is true only for the container stand-in of
  [ECharts ADR 0007](0007-environment-host-and-input-events.md).
- `clone` keeps the four upstream branches. A typed list gives a new list of the same class. A
  `JsObjectLike` value gives a new `Map` of its own keys, as a class instance gives a plain object
  upstream. A builtin and a "primitive" value stay the same reference.
- `merge` keeps the `isObject`, `isArray`, `isDom`, `isBuiltInObject` and `isPrimitive` tests of
  `:148-157`. It writes into a `Map` and into a `JsObjectLike` value.
- `defaults` tests `target[key] == null`. `extend` is `Object.assign`: `jsAssign` for a Map, and
  the setter of `JsObjectLike` for an object-like value.
- `each` keeps its three branches. A `List` or a typed list takes the first branch. A `String` is
  array-like, as upstream. It takes the second branch. A `Map` and a `JsObjectLike` value take the
  third branch through `jsObjectKeys`. Thus the integer keys come first, as in `for-in`.
- `keys` is `jsObjectKeys`.
- `setAsPrimitive` writes the key `'__ec_primitive__'` into a `Map` host, as upstream. For each
  other host (a `List`, a typed list or a class instance), it sets an `Expando<bool>`. Dart cannot
  write a key into these values. `isPrimitive` reads both. Thus `getOption()` keeps the key in an
  object, as upstream.
- `logError` writes to the log sink of item 16.
- `assert` throws a `JsError` (item 15).

### 4. `HashMap`

- The port of `HashMap` keeps the insertion order and the SameValueZero keys of the native `Map`
  (`zrender@6.1.0 src/core/util.ts:739-756`).
- The port of `HashMap` wraps the `LinkedHashMap` of
  [ECharts ADR 0003](0003-numbers-and-js-semantics.md) §8 (`equals: jsSameValueZero`,
  `hashCode: jsSameValueZeroHash`). NaN is one key. `1` and `1.0` are one key. `'1'` and `1` are
  two keys.
- `set` writes −0 as +0, as `Map.prototype.set` does.
- `each` iterates through `jsMapForEach`. Thus a callback that changes the map sees the
  `Map.prototype.forEach` result.

### 5. Object-like classes and objects with a prototype

- `JsObjectLike` is an interface for a Dart class whose instances JS code reads as objects. It
  has these members:
  - `List<String> jsOwnKeys()`: the own enumerable keys in the order of the upstream constructor
    writes
  - `Object? operator [](String key)` and `void operator []=(String key, Object? value)`
  - `bool jsHasOwn(String key)`
- `LinearGradient`, `RadialGradient` and `Pattern` implement it
  (`zrender@6.1.0 src/graphic/Gradient.ts:24`, `src/graphic/Pattern.ts:49`).
  `isGradientObject` tests `colorStops != null`. Thus a clone of a gradient, a `Map`, still
  passes it, as upstream.
- `jsCreateObject(proto, [props])` is `Object.create(proto)` followed by `extend`. It gives a
  `Map` that implements `JsProxyObject`. A read of an absent key falls back to `proto`.
  `keys`, `containsKey` and `objectKeys()` see only the own keys. Thus the copied `jsGet` and
  `jsObjectKeys` read it with no change.
- `jsForIn(object)` gives the `for-in` keys: the own enumerable keys, then the enumerable keys of
  each prototype that no earlier key shadows. `Path.ts:184` uses it.
- The zrender style objects are such Maps. The port keeps `STYLE_MAGIC_KEY` on the default
  style, in its upstream form (item 12).
- `jsGetProperty(object, key)` is `jsGet` with one more case: a `JsObjectLike` value reads its
  `operator []`.
- These symbols go into new files of `js_semantics` (item 17). After stage 2 of ADR 0008, a
  change can merge `jsGetProperty` into `jsGet`.
- Phase 3 measures the reads of a style object with a prototype. A typed style class needs its
  own ADR, as Chart.js ADR 0021 did for the element options.
- **zrender elements (gate 2).** Ported code reads and writes the fields of a zrender element by
  name. Examples: `target[propName]` of the animator (`zrender@6.1.0 src/animation/Animator.ts:525`,
  `:533`, `:554`, `:572-575`), `attrKV` (`src/Element.ts:821`), the state code
  (`src/Element.ts:906`, `:1157`, `:1275`, `:1286`, `:1584`, `src/graphic/Displayable.ts:596`,
  `:601`), `copyTransform` over `TRANSFORMABLE_PROPS` (`src/core/Transformable.ts:372-382`) and
  `pathCopyParams` (`src/graphic/Path.ts:129`). The target is the element, its `shape` or its
  `style`. These rules apply:
  - `Transformable`, `Element` and their subclasses implement `JsObjectLike`.
  - `operator []` and `operator []=` give the fields of the upstream class by name. A `switch`
    over the field names follows the order of the upstream declarations.
  - An unknown name reads and writes an ad hoc map of the instance. The class makes the map at
    the first write. Item 12 still applies to a direct ad hoc write, for example
    `(el as any).__x = ...`.
  - `jsOwnKeys()` gives the field names that upstream assigns in the constructor.
  - The animator, `attr`, `useState`, `_applyStateObj`, `copyTransform` and `assignProps` read and
    write through these operators, as upstream does with `target[key]`.
  - `el.shape` is a `Map<String, Object?>`. `Path` takes the object of `getDefaultShape`
    (`src/graphic/Path.ts:213`).
  - `el.style` is a `Map<String, Object?>` that `createStyle` makes with `jsCreateObject` over
    `DEFAULT_COMMON_STYLE` or `DEFAULT_PATH_STYLE` (`src/graphic/Displayable.ts:450-451`,
    `src/graphic/Path.ts:507-508`).

### 6. `Model.get` and `getShallow`

- `Model.option` has the type `Object?`. It is a Map, a List or a primitive.
- `get(path)` takes `Object?`: a `String` that `parsePath` splits on `.`, or a `List<String>`.
- `_doGet` reads each step with `jsGetProperty` while `jsTruthy(obj)` and `obj` is not a `num`,
  a `String` or a `bool`. This is `obj && typeof obj === 'object'`. A step reads a `List` with a
  string index, as upstream. It maps an `undefined` result to Dart `null`. It skips an empty path
  item. It goes to the parent model on a `null` result.
- `getShallow(key)` reads `option[key]` through `jsGetProperty` also for a primitive option. A
  number gives Dart `null`. A `String` gives its `length` and its indices, as in JavaScript.
- `getModel` keeps the chain of parent models of `model/Model.ts:155-168`.

### 7. Class values and the registry

- A class that the registry stores, constructs or reads by name gets a static `jsClass`, a
  `JsClass` of Chart.js ADR 0020. Its superclass is the `jsClass` of the upstream superclass.
  Examples are `ComponentModel`, `SeriesModel`, `ComponentView`, `ChartView`, `Scale` and their
  registered subclasses.
- `statics` holds the upstream static members in their upstream order: `type`, `dependencies`,
  `defaultOption`, `layoutMode` and the others. A read follows the superclass chain, as a static
  read of an ES class does.
- `construct` maps the arguments to the Dart constructor:
  `(newTarget, args) => LineSeriesModel(args[0], args[1] as Model?, args[2] as GlobalModel?)`.
- **`this.constructor`.** Each class with a `jsClass` has the instance getter
  `JsClass get jsConstructor`. Each subclass overrides it with its own `jsClass`. Dart forbids a
  static member and an instance member with the same name (`conflicting_static_and_instance`).
  Thus the getter is not `jsClass`. The five sites:
  - `model/Component.ts:253` (`getDefaultOption`)
  - `model/Model.ts:181` (`clone`: `jsConstruct(jsConstructor, [clone(option)])`)
  - `util/layout.ts:648` (the static `layoutMode`)
  - `model/Global.ts:454` (an identity compare with a class value)
  - `chart/graph/GraphView.ts:399` (a new element of the class of an element). Thus the zrender
    element classes also get a `jsClass` and a `jsConstructor`.
- The `constructor` reads of a typed array (`data/DataStore.ts:125`, `:577`, `:1266`,
  `zrender@6.1.0 src/Element.ts:1920`) follow the typed-list rules of
  [ECharts ADR 0003](0003-numbers-and-js-semantics.md).
- **`enableClassManagement`** ports line by line over a storage `Map<String, Object>`. A value is
  a `JsClass` or a container `Map<String, JsClass>`. The `IS_CONTAINER` flag becomes the test
  `is Map`. The function returns a `ClassManager` with the six upstream members
  (`util/clazz.ts:242-350`). The target class gives static members that forward to it. Thus the
  call text `ComponentModel.registerClass(X)` stays.
- `registerClass` reads `clz['type']`. The write to `prototype.type` (`:257`) becomes the getter
  `type` of item 10.
- `parseClassType` and the regex of `checkClassType` port as they are.
- `registerSubTypeDefaulter` stores a `Map<String, SubTypeDefaulter>`.
  `typedef SubTypeDefaulter = String? Function(Object? option)`.
- **`isInstance`.** `Model.isInstance(value)` is `value is Model`. The hidden key of
  `enableClassCheck` has no Dart form. The upstream reason, a class from another JS realm, does
  not apply to Dart.

### 8. Field initializers

- A subclass field initializer moves into the constructor body after `super(...)` when a
  superclass constructor path writes or reads that field. The path includes each virtual method
  that the superclass constructor calls, for example `_init` of `Element`.
- The field then has a nullable type, or `late` when no read occurs before the write.
- The review examines each subclass field with an initializer whose name a base constructor path
  writes. Tool 2 of ADR 0008 can list these fields later. Until then, the review item of
  [porting-flow.md](../porting-flow.md) §1 holds the rule.

### 9. Mixins

- A class-level `mixin(Target, Source)` becomes `class Target ... with Source`. `Source` is a Dart
  `mixin`. Examples: `Model with LineStyleMixin, ItemStyleMixin, AreaStyleMixin, TextStyleMixin`,
  and `Element with Eventful, Transformable`.
- The upstream rule "copy only when the target slot is `== null`" holds. A Dart class member wins
  over a mixin member with the same name. Thus, where the target class declares the member, both
  forms keep the class member.
- `mixin(..., true)` (`override`) puts the mixin member over the class member. The Dart form is a
  class member that forwards to the mixin. Examples are `chart/boxplot/BoxplotSeries.ts:142` and
  `chart/candlestick/CandlestickSeries.ts:168`.
- The generated mixin of `data/Graph.ts:604-605` becomes a Dart mixin with an abstract getter for
  the data that it reads (`data` for `GraphNode`, `edgeData` for `GraphEdge`).
- **Row `adapt-instance-mixin`.** `coord/radar/RadarModel.ts:179` mixes into one instance. Dart
  cannot. The port makes the indicator model as a port-only subclass
  `RadarIndicatorModel extends Model with AxisModelCommonMixin`. The hunk carries
  `// DIVERGES(echarts): adapt-instance-mixin, ...`.
- `mixinAxisModelCommonMethods` (`export/api/helper.ts:110-112`) mixes into a class of the caller
  at run time. It falls under row `adapt-legacy-extend` (item 13).

### 10. Prototype defaults, aliases and accessors

- A prototype default of `protoInitialize` or `initDefaultProps` becomes a field initializer of
  the class that sets it. Item 8 applies to it.
- A per-class constant becomes a getter override. Examples: `type` of each zrender shape
  (`Rect.prototype.type = 'rect'`), and an initializer that repeats a static
  (`type = LineSeriesModel.type;`). Thus very_good_analysis gives no `overridden_fields`.
- The getter `type` of the registered base classes gives the static `type` of `jsConstructor`
  when the class declares one. Else it gives the base default. This replaces the write of
  `util/clazz.ts:257`.
- A method alias (`AngleAxis.prototype.dataToAngle = Axis.prototype.dataToCoord`) becomes a
  method that forwards to the aliased method.
- The legacy accessors `position`, `scale` and `origin` of `Element`
  (`zrender@6.1.0 src/Element.ts:1764-1818`) become getters. Each gives a `List` view whose index
  writes go to `x` and `y`.

### 11. Method slots

- `SeriesData` declares the eight wrappable methods as fields that hold a function, as Chart.js
  ADR 0022 section 5 did for `resize` and `eventHandler`. A call keeps its upstream text:
  `data.getItemModel(idx)`.
- `wrapMethod(name, inject)` selects the slot by name with a `switch` over the eight names.
  - For a name that is not a method of `SeriesData`, it returns, as upstream
    (`data/SeriesData.ts:1370-1372`).
  - For another method name, it throws an `ArgumentError`.
  - It stores a closure that calls the old slot. The closure then calls `inject` through `jsCall`,
    with the `SeriesData` as `this` and `[res, ...args]` as the arguments.
- `__wrappedMethods` stays a `List<String>`. `transferProperties` copies the slots of these names
  through the same `switch`. A slot that no call wrapped stays the class default, as a method
  that is not an own property upstream.

### 12. Hidden stores, ad hoc properties and hidden keys

- `makeInner<T, Host>()` becomes `Inner<T, Host>`. It holds an `Expando<T>` and a factory
  `T Function()`. `call(host)` returns the store of the host, or makes it. The `{}` literal of
  each declaration becomes a small Dart class with nullable fields. The port writes no key into
  the host. No upstream code enumerates or clones these keys.
- A declared TS field with a `__` name becomes a Dart field. Its name follows
  [ECharts ADR 0002](0002-file-naming-and-layout.md) item 4.
- An undeclared ad hoc property (`(el as any).__x = ...`) becomes an `Expando` of the module that
  writes it. When two modules share it, it becomes a field of the host class.
  `delete el.__x` writes `null`.
- The zrender `WeakMap` (`zrender@6.1.0 src/core/WeakMap.ts`) becomes a wrapper of an `Expando`.
- `makeCallOnlyOnce` (`util/model.ts:1309-1320`) also writes a hidden key into its host. Its
  port keeps an `Expando<bool>` in place of the key.
- These `Expando` forms are translation rules of this ADR. They carry no `DIVERGES` marker. A
  ported read that enumerates a host with such a key gets a row.
- **Random draws for hidden keys.** Six draws at module load make a key base or an id base:
  - `util/clazz.ts:161` (`enableClassCheck`)
  - `util/component.ts:27` (`getUID`)
  - `util/model.ts:756` and `:1321` (`makeInner`, `makeCallOnlyOnce`), through
    `getRandomIdBase` (`util/number.ts:794-796`)
  - `zrender@6.1.0 src/graphic/Displayable.ts:18` (`STYLE_MAGIC_KEY`)
  - `zrender@6.1.0 src/core/WeakMap.ts:1`

  In Node.js, these draws run when the dist loads. The generator installs its seeded source
  before the dist loads. It reseeds after the load. A Dart top-level variable runs its
  initializer at its first read, thus after the reseed. Thus these draws must not read the seeded
  `jsMathRandom` of [ECharts ADR 0003](0003-numbers-and-js-semantics.md).
  - The draws of `util/clazz.ts:161`, `util/model.ts:756`, `:1321` and `WeakMap.ts:1` go away
    with their hidden keys.
  - The draws of `util/component.ts:27` and `Displayable.ts:18` read a private `Random` of
    `dart:math`.
  - Each draw at run time reads `jsMathRandom`, also when its value only makes a ticket or an id.
    Examples: `getRandomIdBase` in `component/tooltip/tooltipMarkup.ts:521`,
    `component/tooltip/TooltipView.ts:649`, `:787` and `zrender@6.1.0 src/canvas/Painter.ts:380`.
  - Thus the seeded sequences of the port and of Node.js stay in step.

### 13. `extend`

- **`Path.extend` works.** It returns a `JsClass`. Its `construct` makes a port-only
  `ExtendedPath`, a subclass of `Path` that holds the props `Map`.
  - `getDefaultStyle` and `getDefaultShape` clone `props['style']` and `props['shape']`.
  - The constructor calls `props['init']` through `jsCall` with the path as `this`.
  - `buildPath`, `beforeBrush`, `afterBrush`, `getBoundingRect` and `calculateTextPosition` call
    the props function when it is present, else the `Path` method. This is the copy of
    `Path.ts:661-665`.
  - A props function that reads `this` is a `JsFunction` (D3 ADR 0006 section 3).
  - The five shapes of `util/symbol.ts` port as upstream calls of `Path.extend`. `extendShape`
    and `registerShape` work with the same class values.
- **Row `adapt-legacy-extend`.** `enableClassExtend`, the four public `extend*` functions of
  `export/api.ts:82-104`, `superCall`, `superApply` and `mixinAxisModelCommonMethods` wait until
  after 0.1.0. Until then, each throws an `UnsupportedError` with the upstream name. The status of
  `util/clazz.ts` is `partial: <symbols>`. `isExtendedClass` gives `false`. Thus
  `getDefaultOption` takes the ES class branch.
- A later ADR decides the form of `extend`. The candidate of the notes: a `JsClass` whose
  `construct` makes the Dart class of the nearest superclass, with a hook table of the `proto`
  methods (`init`, `render`, `getDefaultOption`) and `superCall` by name.

### 14. Callbacks, `this` and `arguments`

- D3 ADR 0006 sections 3, 5 and 6 apply. Ported code tests a function value with `jsIsCallable`.
  It calls it with `jsInvoke`. A user function that reads `this` is a `JsFunction`.
- The `context` parameter of `each`, `map`, `filter`, `reduce` and `find` stays in the port of
  `util.ts`, the public `zrUtil` API. It goes to `jsInvoke` as `thisArg`. Internal callers give
  Dart closures with lexical `this`.
- User callbacks are function values: formatters, `renderItem`, event handlers and the inject
  functions of item 11.
- `arguments.length` uses `absent` and `jsArgs`. The seven code sites:
  `util/quickSelect.ts:81`, `:83`, `chart/tree/layoutHelper.ts:150`,
  `component/toolbox/feature/DataView.ts:156`, `zrender@6.1.0 src/svg/SVGPathRebuilder.ts:132`,
  `zrender@6.1.0 src/core/PathProxy.ts:436`, `:442`.
- `fn.apply(this, arguments)` becomes an explicit argument list.

### 15. Errors

- `throw new Error(m)` becomes `throw JsError(m)` (D3 ADR 0006 section 8). This covers the 56
  sites, `zrUtil.assert` (`zrender@6.1.0 src/core/util.ts:657-661`) and `throwError`
  (`util/log.ts:128-130`).

### 16. `echartsDev` and the log sink

- `__DEV__` becomes the top-level variable `bool echartsDev` of the port-only file
  `lib/src/dev.dart`. Ported code reads `if (echartsDev)` at each upstream `if (__DEV__)`.
- Its default is `true` when asserts are on. Else it is `false`. Thus a debug build and the tests
  get the dev checks, as `dist/echarts.js` and jest do. A release build gets the behavior of
  `dist/echarts.min.js`.
- `setUpSpecs()` of [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) sets it to
  `true`. The reference generators run `dist/echarts.js`, thus with `__DEV__` true.
- The `__DEV__` blocks log warnings, cache messages (`util/log.ts:24`, `:32-37`) and throw
  through `assert`. Thus the switch changes behavior. A `const` cannot change in a test.
- `outputLog` of `util/log.ts:30-41` and `logError` of `zrender@6.1.0 src/core/util.ts:65-69` write
  to one replaceable sink: `void Function(String level, String message)`. The default sink prints
  the line with the prefix `[ECharts] `, as `console[type]` does. The harness replaces it for
  `console.error = jest.fn()` and restores it after each test.

### 17. Runtime symbols

These symbols go into new files of `js_semantics`
([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) item 6). They do not
change the copied Chart.js files.

| Symbol | Purpose | Item |
|---|---|---|
| `jsNullish(value)` | `value == null` for a value that can be the sentinel | 2 |
| `JsObjectLike` | A Dart class that JS code reads as an object | 5 |
| `jsCreateObject(proto, [props])` | `Object.create(proto)` with `extend` | 5 |
| `jsForIn(object)` | The `for-in` keys, inherited keys included | 5 |
| `jsGetProperty(object, key)` | `jsGet` with the `JsObjectLike` case | 5, 6 |

The port keeps these symbols in its own files: `Inner` (`lib/src/echarts/util/model.dart`),
`ClassManager` (`lib/src/echarts/util/clazz.dart`), `ExtendedPath`
(`lib/src/zrender/graphic/Path.dart`), `echartsDev` (`lib/src/dev.dart`) and the log sink. A
port-only class in a ported file has a `///` line that says so.
[ECharts ADR 0003](0003-numbers-and-js-semantics.md) lists the numeric symbols, `jsMathRandom`
included. Each symbol gets port-only tests on the VM, with dart2js and with dart2wasm.

### 18. TS types in Dart signatures (gate 2)

- A TS type parameter that only types an option goes away. Examples are `Opt` of `Model`,
  `ComponentModel` and `SeriesModel` (`echarts@6.1.0 src/model/Model.ts:48`,
  `src/model/Component.ts:53`, `src/model/Series.ts:149`). Other examples are `Props` of
  `Element`, `Displayable` and `Path` (`zrender@6.1.0 src/Element.ts:337`,
  `src/graphic/Displayable.ts:105`, `src/graphic/Path.ts:133`). The option is `Object?` or
  `Map<String, Object?>` (item 1).
- A TS type parameter that only types event names and handlers also goes away. `Eventful<EvtDef>`
  (`zrender@6.1.0 src/core/Eventful.ts:67`) becomes `Eventful`. The event names are `String`.
- Another TS type parameter stays a Dart type parameter, with the bound of the TS declaration. A
  union bound becomes `Object`. An example is `HashMap<T, KEY>`
  (`zrender@6.1.0 src/core/util.ts:749`).
- A TS overload set becomes one Dart method. Its parameter types are the types of the
  implementation signature. Examples are `Model.get` of item 6 (`src/model/Model.ts:94-109`) and
  `Element.attr` (`zrender@6.1.0 src/Element.ts:841-843`). An overload set that reads
  `arguments.length` follows item 14.
- A string-literal union becomes `String`. A union of classes becomes their nearest common Dart
  supertype, or `Object?`.
- A TS class type in a signature stays the Dart class. A class of a later phase comes through the
  `partial:` rule of [ECharts ADR 0002](0002-file-naming-and-layout.md) item 9.

## Alternatives considered

- **Three states everywhere,** as in the option scopes of Chart.js ADR 0006. Rejected. 1,062
  sites treat `null` and `undefined` alike. Only one live strict site needs the difference. A
  sentinel in each value makes each read a `jsNullish` test.
- **Dart `null` for both, with no sentinel.** Rejected. `ThemeRiverSeries.ts:172` keeps a
  third value `null` and drops an absent one. `+undefined` is NaN, `+null` is 0.
- **Typed option classes now** (Chart.js ADRs 0018 and 0021). Kept for later. ECharts declares
  its option types in `util/types.ts` and in each component and series file. The models read
  options by path. A typed layer needs the measured hot paths of phases 3 and 6 first.
- **A `const` for `__DEV__`.** Rejected. A spec cannot switch it. The specs need the dev
  messages (`model/componentMissing`). A `const false` drops the checks from debug builds.
- **No `extend` support.** Rejected for `Path.extend`. `util/symbol.ts` and `extendShape` use
  it. Without it, the five shapes become ordinary subclasses with a `DIVERGES` row. The public
  `extend*` API waits (row `adapt-legacy-extend`).
- **`jsClass` as the name of the instance getter.** Rejected. Dart gives
  `conflicting_static_and_instance` for a static `jsClass` and an instance `jsClass`.
- **An `Expando` for `setAsPrimitive` on each host.** Rejected for a `Map` host. `getOption()`
  is public. Upstream leaves the key in a transform object.
- **The ES6 test build as the reference.** Rejected. The shipped build is the ES3 dist. The two
  differences of the Context reach no result. ECharts ADR 0005 gives the generators.
- **A `Map` for the zrender value classes.** Rejected. A gradient is a class upstream. Its
  `clone` gives a plain object only through the class-instance branch.
- **Dart `noSuchMethod` for prototype reads.** Rejected. It needs `dynamic` calls.
  very_good_analysis flags `avoid_dynamic_calls`.

## Consequences

- Option code reads close to upstream: `model.get(['label', 'show'])`, `merge(option, theme)`.
- The review of each module lists the sentinel sites of item 2 and the moved initializers of
  item 8.
- `js_semantics` gets the five symbols of item 17 and their tests. ECharts becomes the third user
  of the package. ADR 0008 names only D3 and Chart.js. This ADR states the ECharts use.
- Each registered class carries a static `jsClass` and a `jsConstructor` override.
- Two rows come with the changes that port the hunks: `adapt-instance-mixin` (phase 8,
  `coord/radar/RadarModel.ts`) and `adapt-legacy-extend` (phase 2, `util/clazz.ts`).
- The expect stand-in of ECharts ADR 0005 needs a rule for a key with a Dart `null` value in
  `toEqual`. Under item 2, that value stands for JS `null` and for JS `undefined`.
- A later ADR decides the public `extend*` API and the typed option API.

## Evidence

- The counts: a grep over `src/**/*.ts` of both pins, with the comments included. Examples of
  the patterns: `class [A-Za-z_$]+(<[^>]*>)? extends`, `[!=]= null`, `\bmerge\(`,
  `\.prototype\.[A-Za-z_$]+ *=` and `throw new Error`. The call counts of the
  registry functions, of `mixin` and of `arguments.length` come from the hit lists, read by
  hand. The `__DEV__` count is lines without a comment marker. The `makeInner` count is the
  `makeInner<` and `makeInner()` hits outside `util/model.ts` and comments.
- The strict `undefined` sites: a grep of `=== undefined`, `!== undefined` and `=== void 0` in
  both `src/` trees, with the `typeof` environment probes left out. `util/log.ts:84` is a
  `=== void 0` in a message builder of `__DEV__` code.
- The Dart probes ran on Dart 3.12.2 (macOS arm64):
  - A `Map<Object, int>` with the key `double.nan` gave `null` for a read of `double.nan`. A
    second write added a second entry. A read of `-0.0` found the key `0.0`. The keys `1` and
    `1.0` gave one entry. The keys `'1'` and `1` gave two.
  - A class with a static `jsClass` and an instance getter `jsClass` gave the analyzer error
    `conflicting_static_and_instance`.
  - A base constructor called a virtual `init`. The subclass override printed the initializer
    value of a subclass field. The value of the `init` write stayed after the constructor.
- very_good_analysis 10.3.0 enables `overridden_fields` and `avoid_dynamic_calls`.
- The build facts: `tsconfig.json:3` of both repositories, `test/ut/tsconfig.json:3`,
  `test/ut/jest.config.cjs:36`, `build/config.js:41-80` and `build/transform-dev.js:23-50` at
  `echarts@6.1.0`.
