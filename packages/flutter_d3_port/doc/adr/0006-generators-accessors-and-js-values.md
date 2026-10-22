# D3 ADR 0006: Generators, accessors and JS values

- Status: proposed
- Date: 2026-10-20
- Gate: D3 phase 1. The pilot needs the callable classes (the formats of d3-format), the
  `arguments.length` overloads (d3-array `range`), `instanceof` (d3-path) and the errors. The
  accessors and the `Function.length` overloads get wide use from phase 2.
- Related: [Chart.js ADR 0006](../../../flutter_chartjs_port/doc/adr/0006-options-representation-and-resolver.md)
  (the `undefined` sentinel and the three states),
  [Chart.js ADR 0032](../../../flutter_chartjs_port/doc/adr/0032-js-numeric-semantics.md) (§1: `jsCall`
  and `JsFunction`),
  [Chart.js ADR 0020](../../../flutter_chartjs_port/doc/adr/0020-registry-and-component-classes.md)
  (proposed: class values), [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)
  (the shared runtime `js_semantics`), [D3 ADR 0002](0002-file-naming-and-layout.md) (names, split
  classes and underscore members), [D3 ADR 0003](0003-number-to-string.md) (numbers),
  [D3 ADR 0004](0004-spec-harness.md) (the assert stand-in), [D3 ADR 0005](0005-path-context.md)
  (the `context` accessor), [porting-flow.md](../porting-flow.md) §1.1, §2.9 and §2.11,
  [prior art](../prior-art/d3-packages.md)

## Context

The counts are at the pins of [D3 ADR 0001](0001-upstream-sources.md), over the `src/` files with
the comments removed.

**Functions with methods.** Most D3 generators are closures with methods, not classes.
- `line()` returns the function `line` with the methods `x`, `y`, `defined`, `curve` and `context`
  (`d3-shape src/line.js:7-58`).
- A method reads its value with no argument. It sets the value with one argument and returns the
  generator: `return arguments.length ? (x = typeof _ === "function" ? _ : constant(+_), line) : x;`
  (`:37-39`). Thus JavaScript chains the calls: `d3.line().x(f).y(g)`.
- Many other D3 values have the same form. Examples are the scales, the projections, the result of
  `format(specifier)`, `curveBundle`, `easePolyIn`, `interpolateRgb` and `randomNormal`.
- The sources read `arguments.length` 288 times in 89 files. 235 reads are the accessor form
  `arguments.length ? … : …`. 23 reads are the form `if (!arguments.length) return …`. Two reads
  are `switch (arguments.length)` (`d3-scale src/init.js:2`, `:11`).
- 112 sites choose between a function and a constant with `typeof <name> === "function" ?`.
- The getter returns the stored value: `assert.strictEqual(line(x).x(), x)`
  (`d3-shape test/line-test.js:17`). A default value is callable: `l.x()([42, 34])` is 42 (`:7`).

**Classes and prototypes.** The sources have 12 `class` declarations, for example d3-path `Path`
and d3-delaunay `Delaunay`. 11 lines give a factory function the prototype of a constructor, for
`instanceof`. An example is `path.prototype = Path.prototype;` (`d3-path src/path.js:152`). One
of the 11 lines is the `define` helper of d3-color (`src/define.js:2`), with 6 calls. The tests
use `instanceof` in 37 files, for example `assert(p instanceof path)`
(`d3-path test/path-test.js:7`).

**User functions.** A generator calls an accessor with `(d, i, data)` (`d3-shape src/line.js:27`,
`:31`). A user function can declare fewer parameters. JavaScript then drops the extra arguments. A
spec function can read the arguments without parameters:
`function() { actual.push([].slice.call(arguments)); }` (`d3-shape test/line-test.js:25`).

**`this`.** The sources forward `this` with `.apply(this, arguments)` 68 times in 28 files, and
with `.call(this, …)` 12 times in 8 files. For example, `arc` calls
`innerRadius.apply(this, arguments)` (`d3-shape src/arc.js:91-94`). The spec
`arc().innerRadius(f)(…) propagates the context and arguments to the specified function f` calls
the generator with a `this` (`d3-shape test/arc-test.js:5-10`). d3-selection gives the DOM node as
`this` to the callbacks (phase 7).

**`Function.length`.** d3-array reads the parameter count of a user function at 8 sites in 8
files: `src/bisector.js:12`, `src/sort.js:8`, `src/least.js:6`, `src/leastIndex.js:5`,
`src/greatest.js:6`, `src/greatestIndex.js:5`, `src/rank.js:8` and `src/groupSort.js:6`. A function
with 2 parameters is a comparator. Another function is an accessor. Thus the count changes the
result. `src/sort.js:8-10` also counts its rest parameter `...F`.

**Rest parameters.** 19 functions in 7 files have a rest parameter. 13 of them are in 6 files of
d3-array: `cross.js`, `difference.js`, `group.js`, `intersection.js`, `sort.js` and `union.js`.
The other 6 are in `d3-zoom src/zoom.js`.

**`undefined` and `null`.**
- The sources compare with `== null` or `!= null` 238 times. These comparisons treat `null` and
  `undefined` alike.
- The sources compare with `undefined` 69 times (`===`, `!==`, `==` and `!=`). Most of these sites
  are defaults of arguments, for example `x === undefined ? pointX : constant(x)`
  (`d3-shape src/line.js:14`). There, `line(null)` and `line(undefined)` give different
  accessors.
- `+null` is 0. `+undefined` is NaN.
- The specs call `assert.strictEqual(…, undefined)` 224 times and `assert.strictEqual(…, null)`
  250 times.

**Errors.** The sources throw `new Error` 42 times, `new TypeError` 11 times and `new RangeError`
13 times. The specs test the class 20 times: `TypeError` 17 times and `RangeError` 3 times. Some of
these `TypeError` cases need an engine error, for example `d3.filter({}, () => true)` iterates a
value that is not iterable (`d3-array test/filter-test.js:22`). Other specs test the message, for
example `/invalid format: foo/` (d3-format).

**Module state.** `export var` and `export let` occur 128 times. Most of these variables never
change. d3-format and d3-time-format assign their exported default formats again
(`d3-format src/defaultLocale.js:13-18`). An importer then sees the new value, because an ES module
export is a live binding.

**The runtime.** `js_function.dart` of the Chart.js port gives `jsCall`, `jsCall1`, `jsIsFunction`
and `JsFunction` (Chart.js ADR 0032 §1). `jsCall` reads the parameter count of a Dart closure with
function-type tests, up to `jsMaxArity` (8). It drops the extra arguments. It pads the absent
arguments with the `undefined` sentinel of `js_undefined.dart`. A `JsFunction` wraps a closure
whose first parameter is `this`. An object with a `call` method is not a function value for
`jsCall`. [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) copies these
files to `js_semantics`. New D3 runtime code goes into new files of that package (item 6).

**Lints.** very_good_analysis 10.3.0 enables `avoid_setters_without_getters`,
`cascade_invocations`, `unnecessary_getters_setters`, `use_setters_to_change_properties`,
`one_member_abstracts` and `only_throw_errors`.

**Prior art.** d4 split the accessor names, for example `extent` and `extentBy`, and `max` and
`maxBy`. It gave JS `undefined` as `null` ([prior art](../prior-art/d3-packages.md), "How it
handles JavaScript semantics").

## Decision

### 1. Callable classes

- A D3 function with methods becomes a Dart class with a `call` method. The factory keeps the
  upstream name. For example, `line([x, y])` returns a `Line`. Then `line(data)` calls
  `Line.call`.
- The class name is the UpperCamelCase form of the public factory name, for example `Line`,
  `ScaleLinear`, `GeoPath` and `CurveBundle`. Where no public factory exists, the class takes the
  UpperCamelCase form of the inner function name. The pilot gives the names of d3-format.
- `call` keeps the upstream parameters, for example `Object? call(Object? data)`.
- Each such class implements `JsCallable` of section 9.
- An upstream `class` stays a class. A constructor with a prototype object, for example `Rgb` of
  d3-color with `define`, also becomes a Dart class.
- **`instanceof`.** `x instanceof f`, where upstream gives `f` the prototype of a constructor `C`,
  becomes `x is C`. For example, `p instanceof path` becomes `p is Path`. This is a translation
  rule.

### 2. Accessors

- An accessor with zero or one argument becomes a getter and a setter. `line.x()` becomes
  `line.x`. `line.x(f)` becomes `line.x = f`.
- A chain becomes a cascade: `d3.line().x(f).y(g)` becomes `d3.line()..x = f..y = g`. A chain that
  calls its result becomes `(d3.line()..x = f)(data)`.
- The getter returns the value that the setter stored. This value is the user function itself, or
  the constant function that the setter made. Thus `strictEqual(line(x).x, x)` holds.
- The setter keeps the upstream conversion. For example,
  `typeof _ === "function" ? _ : constant(+_)` becomes
  `jsIsCallable(_) ? _ : constant(jsToNumber(_))`.
- The setter takes the widest type that the upstream setter accepts, mostly `Object?`. The getter
  can have a narrower type. Dart accepts a getter whose type is a subtype of the type of its
  setter.
- In a class, an accessor whose setter only stores the value and whose getter only reads it
  becomes a public field, as `unnecessary_getters_setters` asks.
- An accessor of a split class is an extension getter and setter
  ([D3 ADR 0002](0002-file-naming-and-layout.md) section 5).
- **Keyed accessors and other overloads.** A method that upstream overloads on `arguments.length`
  with more than one parameter stays one method. Examples are `selection.attr(name[, value])`,
  `d3.range(start[, stop[, step]])` and the `initRange` of d3-scale. Its optional parameters are
  positional, with the default `absent` (section 6). Where upstream reads `arguments.length`, the
  port reads `jsArgs([...]).length`. The result is `Object?` where upstream returns either a value
  or the object.

### 3. Function values and arity

- A JS function value is one of these Dart values:
  - a Dart `Function`, for a function that does not read `this`
  - a `JsFunction` of the runtime, for a function that reads `this`
  - a `JsCallable`, for a callable class of section 1
- Ported code tests `typeof f === "function"` with `jsIsCallable(f)`.
- Ported code calls a function value through `jsInvoke(f, args, thisArg: t)`:
  - For a `Function` and a `JsFunction`, it applies the rules of `jsCall`. It drops the extra
    arguments. It pads the absent arguments with `undefined`. It gives `this` to a `JsFunction`.
  - For a `JsCallable`, it calls `jsApply(t, args)`.
  - For another value, it throws a `JsTypeError`.
- A generator can call its accessors through an adapter that its setter makes one time. The
  adapter is a closure of fixed arity. It calls the user function with the arguments that the
  function takes. The getter still returns the stored value. Phase 2 measures the adapter against
  `jsInvoke` on the accessors of d3-array, for example `bisector` and `bin`. The faster form wins
  ([porting-flow.md](../porting-flow.md) §1.1). The figures go into `doc/performance.md`.
- A Dart closure declares the parameters that it reads. A spec function that reads `arguments`
  becomes a closure with optional positional parameters with the default `absent`. Its length is 0,
  as in JavaScript. An example from `d3-shape test/line-test.js:25`:

  ```dart
  ([Object? d = absent, Object? i = absent, Object? data = absent]) =>
      actual.add(jsArgs([d, i, data]))
  ```
- A generic closure, for example `<T>(T x) => x`, is not a function value for the runtime.
  Instantiate it first, as the Chart.js runtime asks.

### 4. `Function.length`

- `f.length` of a function value is `jsFunctionLength(f)`:
  - For a Dart closure, it is the count of its required positional parameters. The runtime finds
    it with the function-type tests of `jsCall`.
  - For a `JsFunction`, it is that count less 1, because the first parameter is `this`.
  - For a `JsCallable`, it is `jsLength`.
- An optional Dart parameter is like a JS parameter with a default value. `Function.length` does
  not count either of them.
- Thus `bisector((Object? d) => …)` takes the accessor branch of `d3-array src/bisector.js:12`.
  `bisector((Object? a, Object? b) => …)` takes the comparator branch, as in JavaScript.
- The 8 sites of d3-array call `jsFunctionLength`.

### 5. `this`, `arguments` and rest parameters

- A user function that reads `this` is a `JsFunction`, by the convention of the runtime. Thus
  `callback.call(node, d, i, group)` becomes `jsInvoke(callback, [d, i, group], thisArg: node)`.
- A generator whose upstream function forwards `this` gets it through `JsCallable.jsApply`. Its
  `call` method gives `undefined` as `this`, as a strict-mode call without a receiver does. Thus
  the spec `arc().innerRadius(f).apply(that, args)` becomes this Dart call:
  `jsInvoke(arc()..innerRadius = f, args, thisArg: that)`.
- A function that forwards `arguments`, or that has a rest parameter, declares optional positional
  parameters with the default `absent`, up to `jsMaxArity` (8). `jsArgs` removes the `absent`
  values at the end of the list. Thus a call keeps the JS call shape, for example
  `d3.sort(data, f, g)`.

### 6. `undefined`, `null` and absent

These rules adapt the three states of Chart.js ADR 0006 to D3:
- **JS `null`** is Dart `null`.
- **JS `undefined`** is the `undefined` sentinel of `js_semantics` where the difference changes a
  result:
  - a value that upstream compares with `undefined` (the 69 sites) and that `null` can also
    reach. Its parameter default is the sentinel, for example
    `line([Object? x = undefined, Object? y = undefined])`.
  - a value that reaches ToNumber. `+undefined` is NaN. `+null` is 0. `jsToNumber` gives these
    results.
  - the result of a user function that returns nothing, where a caller converts or tests the
    result. By the convention of the runtime, a Dart closure that returns nothing returns Dart
    `null`. Dart `null` is JS `null`. Thus such a ported spec function returns the sentinel.
- **Dart `null` for JS `undefined`.** Elsewhere, Dart `null` can stand for JS `undefined`. This
  rule applies where upstream treats both alike (`== null`), or where JS `null` never reaches the
  value. The `///` line of the symbol says so, as Chart.js ADR 0006 asks for values outside
  option scopes. An example is the result of `max([])`. Then the ported spec compares with `null`
  where upstream compares with `undefined`. This is a translation rule.
- **Absent.** The const sentinel `absent` of the port-only class `Absent` in `js_semantics` stands
  for an argument that the caller does not give. It is the default of a parameter that upstream
  tests with `arguments.length`. It differs from `undefined`. For example,
  `d3.range(0, 5, undefined)` has 3 arguments, thus a NaN step (`d3-array src/range.js:2`). No
  `absent` value reaches user code or a result.
- **Parameter types.** A public parameter has the type `Object?` when the specs pass values of
  more than one Dart type to it. Else it has the Dart type of these values, for example `double`.
  A parameter that upstream converts with `+x` and that has the type `Object?` goes through
  `jsToNumber`. The gate 2 decision "Collections and iteration" gives the ToNumber of an object
  with `valueOf`, for example `test/OneTimeNumber.js` of d3-array
  ([porting-flow.md](../porting-flow.md) §2.9). The gate 3 decision gives the dates (§2.11).

### 7. Module-level variables

- An `export var` or `export let` that its module assigns again becomes a top-level variable. A
  reader in another library then sees each new value, as with an ES live binding. Examples are
  `format` and `formatPrefix` of d3-format.
- Another `export var` becomes a `final` or a `const` top-level declaration.

### 8. Errors

- `throw new Error(m)` becomes `throw JsError(m)`. `new TypeError(m)` becomes `JsTypeError(m)`.
  `new RangeError(m)` becomes `JsRangeError(m)`.
- `JsError` extends the Dart `Error`, as `only_throw_errors` asks. `JsTypeError` and `JsRangeError`
  extend `JsError`, as `TypeError.prototype` inherits from `Error.prototype`.
- Each class has `name` and `message`. `toString()` gives `<name>: <message>`, the result of
  `Error.prototype.toString`.
- Where JavaScript throws an engine `TypeError` and a spec tests it, the port throws a
  `JsTypeError` too. `jsInvoke` throws it for a value that is not a function. The iteration helpers
  of the gate 2 decision throw it for a value that is not iterable.
- [D3 ADR 0004](0004-spec-harness.md) section 2 gives the forms of `assert.throws` for these
  classes.

### 9. Runtime symbols

These port-only symbols go into new files of `js_semantics`
([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) item 6). They do not
change the files that ADR 0008 copies from the Chart.js port.

| Symbol | Purpose |
|---|---|
| `JsCallable` | The interface of a callable class: `Object? jsApply(Object? thisArg, List<Object?> args)` and `int get jsLength` |
| `jsIsCallable(value)` | `typeof value === "function"`: `jsIsFunction(value)`, or a `JsCallable` |
| `jsInvoke(f, args, {thisArg})` | The call of a function value (section 3) |
| `jsFunctionLength(f)` | `Function.length` (section 4) |
| `Absent`, `absent`, `jsArgs(values)` | An argument that the caller does not give, and the list `arguments` without it (section 6) |
| `JsError`, `JsTypeError`, `JsRangeError` | The JS errors (section 8) |

Each symbol gets port-only tests on the VM, with dart2js and with dart2wasm. After stage 2 of ADR
0008, a change can merge `jsIsCallable` and `jsInvoke` into `jsIsFunction` and `jsCall`.

## Alternatives considered

- **One method for each accessor, with an `absent` default.** `line.x()` reads. `line.x(f)` sets
  and returns the generator. Not chosen. The JS chain then stays as it is. But each read and each
  write has the type `Object?`. The lint `use_setters_to_change_properties` also asks for a
  setter. The keyed accessors keep this form, because a Dart setter takes one value.
- **Split names,** for example a getter `x` and a method `setX(f)`, or `extent` and `extentBy` as
  in d4. Rejected. The names then differ from the D3 docs. d4 also lost the index arguments of the
  d3-array accessors.
- **A wrapper in place of the user function.** The setter adapts the arity and stores the
  wrapper. Rejected. The getter then returns the wrapper. `strictEqual(line(x).x(), x)` fails.
- **Dart `null` for `null` and `undefined` everywhere.** Rejected. `+null` is 0 and `+undefined` is
  NaN. `line(null)` and `line(undefined)` give different accessors.
- **The three states everywhere,** as in the option scopes of Chart.js ADR 0006. Rejected. 238
  sites treat `null` and `undefined` alike. A sentinel in each value also makes each type
  `Object?`.
- **`undefined` as the default of the `arguments.length` parameters.** Rejected. Then
  `range(0, 5, undefined)` and `range(0, 5)` give the same result. In JavaScript, they differ.
- **A change of `jsIsFunction` and `jsCall` now.** Rejected. ADR 0008 item 6 asks for the agreement
  of the Chart.js work for a change of a copied file. New files need no such agreement.
- **Dart `Error` classes for the JS errors** (`StateError`, `ArgumentError`, `RangeError`).
  Rejected. Dart has no public `TypeError` with a message. The `toString()` of the Dart classes
  differs from `Error.prototype.toString`, for example `Bad state: …`.

## Consequences

- Dart code reads close to the D3 docs:
  `final line = d3.line()..x = (Object? d) => x(d)..y = (Object? d) => y(d);`.
- The specs port line by line. `l.x()([42, 34])` becomes `jsInvoke(l.x, [[42, 34]])`.
  `l.x(f)` becomes `l..x = f`.
- Each public type of a generator is a class. The API docs of phase 8 can add typed front ends over
  these classes. Such a front end needs its own ADR.
- The accessor calls cost a dynamic call or an adapter call for each point. Phase 2 measures the
  two forms (section 3).
- `js_semantics` gets the symbols of section 9 and their tests.
- A ported spec writes `null` where upstream expects `undefined` for a value that the port gives as
  Dart `null`. The `///` line of the symbol names the rule.

## Evidence

- The counts: a scan of the pinned `src/**/*.js` files with the comments removed. delaunator is at
  v5.1.0 and robust-predicates at v3.0.3. The patterns were `\barguments\.length\b`,
  `\barguments\.length\s*\?`, `if\s*\(\s*!\s*arguments\.length\s*\)`,
  `typeof\s+[\w$]+\s*===\s*"function"\s*\?`, `[!=]=\s*null\b`, `[!=]==?\s*undefined\b`,
  `\.apply\(\s*this\s*,\s*arguments\s*\)`, `\.call\(\s*this\b` and
  `throw new (Error|TypeError|RangeError)`.
- The `Function.length` sites: a search of `<name>.length` against a number in `src/`, read by
  hand. `F.length` of `src/sort.js:8-10` is the length of the rest array.
- The spec counts: a scan of `assert.strictEqual(…, undefined)`, `assert.strictEqual(…, null)`,
  `assert.throws(…, TypeError)` and `assert.throws(…, RangeError)` in the test files.
- The lint probe: a package used very_good_analysis 10.3.0 and Dart 3.12.2. It declared three
  forms: a callable class that implements a two-member `JsCallable`, a getter of a function type
  with an `Object?` setter, and a cascade. `dart analyze --fatal-infos` gave no issue for them. It gave
  `unnecessary_getters_setters` for a getter and a setter that only wrap a field (section 2).
