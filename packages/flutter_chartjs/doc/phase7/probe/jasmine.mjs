// Original code, not ported from Chart.js: phase 7 probe harness.
//
// A small stand-in for Jasmine 3.99 (the jasmine-core of the Chart.js
// lockfile), for run_spec.mjs. It has describe/it and the hooks, done
// callbacks, spies, the built-in matchers that the Chart.js specs use, the
// asymmetric testers and addMatchers. Each expectation records
// {matcher, not, actual, expected, pass} with the serializer of this module.
// The deep equality is a port of MatchersUtil.eq_ of jasmine-core 3.99.1.
//
// Usage: import {createJasmine} from './jasmine.mjs'. run_spec.mjs installs
// the globals and calls run().

/** The time limit of one function of a case (jasmine.DEFAULT_TIMEOUT_INTERVAL). */
export const TIMEOUT_MS = 5000;

/** The current case, or null outside a case. */
let currentCase = null;

/** Returns the current case record, or null. */
export function current() {
  return currentCase;
}

/**
 * The error of a feature that the probe does not have (a real DOM, CSS,
 * a resize observer). The constructor marks the current case as
 * `unsupported`, also when spec code catches the error.
 */
export class Unsupported extends Error {
  constructor(reason) {
    super(`unsupported: ${reason}`);
    this.name = 'Unsupported';
    this.reason = reason;
    if (currentCase && !currentCase.unsupported) currentCase.unsupported = reason;
  }
}

/** Adds [note] to the current case once. */
export function note(text) {
  if (currentCase && !currentCase.notes.includes(text)) currentCase.notes.push(text);
}

// ---------------------------------------------------------------------------
// The serializer.

const DOM_TAGS = new Set([
  '[object HTMLCanvasElement]',
  '[object HTMLDivElement]',
  '[object HTMLBodyElement]',
  '[object HTMLDocument]',
  '[object CanvasRenderingContext2D]',
  '[object CSSStyleDeclaration]',
]);

/**
 * Returns a JSON value for [value]: cycles as '[Circular]', functions as
 * '[Function <name>]', Chart instances as '[Chart]', undefined as
 * '[undefined]', NaN, -0 and the infinities as strings, a depth limit of 6.
 * A Map gives {'[Map]': entries}, a Set {'[Set]': values}, a class instance
 * its own enumerable keys after '[class]'. A key that throws on read gives
 * '[Throws: <message>]'.
 */
export function makeSerializer(isChart) {
  function ser(v, depth, stack) {
    if (v === undefined) return '[undefined]';
    if (v === null) return null;
    switch (typeof v) {
      case 'number':
        if (Number.isNaN(v)) return 'NaN';
        if (v === Infinity) return 'Infinity';
        if (v === -Infinity) return '-Infinity';
        if (Object.is(v, -0)) return '-0';
        return v;
      case 'string':
      case 'boolean':
        return v;
      case 'bigint':
        return `${v}n`;
      case 'symbol':
        return `[${v.toString()}]`;
      case 'function':
        if (v.and && v.calls && v.isSpy) return `[Spy ${v.spyName}]`;
        return `[Function ${v.name || 'anonymous'}]`;
      default:
        break;
    }
    if (isChart(v)) return '[Chart]';
    if (stack.includes(v)) return '[Circular]';
    const tag = Object.prototype.toString.call(v);
    if (DOM_TAGS.has(tag)) return tag.replace('[object ', '[');
    if (v instanceof Date) return {'[Date]': Number.isNaN(+v) ? 'Invalid Date' : v.toISOString()};
    if (v instanceof RegExp) return {'[RegExp]': String(v)};
    if (v instanceof Error) return {'[Error]': `${v.name}: ${v.message}`};
    if (typeof v.asymmetricMatch === 'function' && v.jasmineToString) {
      return {'[Asymmetric]': v.jasmineToString(), sample: ser(v.sample, depth + 1, stack)};
    }
    if (depth >= 6) return Array.isArray(v) ? `[Array(${v.length})]` : '[Object]';
    stack.push(v);
    try {
      if (Array.isArray(v) || ArrayBuffer.isView(v)) {
        const out = [];
        for (let i = 0; i < v.length; i++) out.push(i in v ? ser(v[i], depth + 1, stack) : '[hole]');
        return out;
      }
      if (v instanceof Map) {
        return {'[Map]': [...v.entries()].map(([k, x]) => [ser(k, depth + 1, stack), ser(x, depth + 1, stack)])};
      }
      if (v instanceof Set) return {'[Set]': [...v].map((x) => ser(x, depth + 1, stack))};
      const out = {};
      const proto = Object.getPrototypeOf(v);
      if (proto !== null && proto !== Object.prototype) {
        const name = proto.constructor && proto.constructor.name;
        out['[class]'] = name || '?';
      }
      let keys;
      try {
        keys = Object.keys(v);
      } catch (e) {
        return {'[Throws]': String(e && e.message)};
      }
      for (const k of keys) {
        try {
          out[k] = ser(v[k], depth + 1, stack);
        } catch (e) {
          out[k] = `[Throws: ${e && e.message}]`;
        }
      }
      return out;
    } finally {
      stack.pop();
    }
  }
  const serialize = (v) => ser(v, 0, []);
  // The short form of [v] when it has one (a Chart, a DOM object, a
  // function), else an object.
  serialize.shallow = (v) => {
    if (typeof v === 'function' || isChart(v)) return ser(v, 0, []);
    const tag = Object.prototype.toString.call(v);
    if (DOM_TAGS.has(tag)) return tag.replace('[object ', '[');
    return {};
  };
  return serialize;
}

/** A short text of [v] for failure messages. */
function pp(serialize, v) {
  let s;
  try {
    s = JSON.stringify(serialize(v));
  } catch {
    s = String(v);
  }
  return s && s.length > 300 ? s.slice(0, 300) + '...' : s;
}

// ---------------------------------------------------------------------------
// The asymmetric testers (jasmine-core 3.99.1).

class Any {
  constructor(expected) {
    if (expected === undefined) throw new TypeError('jasmine.any() expects to be passed a constructor function.');
    this.expectedObject = expected;
  }
  asymmetricMatch(other) {
    const e = this.expectedObject;
    if (e == String) return typeof other == 'string' || other instanceof String;
    if (e == Number) return typeof other == 'number' || other instanceof Number;
    if (e == Function) return typeof other == 'function' || other instanceof Function;
    if (e == Object) return other !== null && typeof other == 'object';
    if (e == Boolean) return typeof other == 'boolean';
    if (e == Symbol) return typeof other == 'symbol';
    return other instanceof e;
  }
  jasmineToString() {
    return `<jasmine.any(${this.expectedObject.name})>`;
  }
}

class Anything {
  asymmetricMatch(other) {
    return other !== undefined && other !== null;
  }
  jasmineToString() {
    return '<jasmine.anything>';
  }
}

function hasProperty(obj, property) {
  if (!obj || typeof obj !== 'object') return false;
  if (Object.prototype.hasOwnProperty.call(obj, property)) return true;
  return hasProperty(Object.getPrototypeOf(obj), property);
}

class ObjectContaining {
  constructor(sample) {
    this.sample = sample;
  }
  asymmetricMatch(other, util) {
    if (typeof this.sample !== 'object') throw new Error('You must provide an object to objectContaining.');
    if (typeof other !== 'object') return false;
    for (const property in this.sample) {
      if (!hasProperty(other, property) || !util.equals(this.sample[property], other[property])) return false;
    }
    return true;
  }
  jasmineToString() {
    return '<jasmine.objectContaining>';
  }
}

class ArrayContaining {
  constructor(sample) {
    this.sample = sample;
  }
  asymmetricMatch(other, util) {
    if (!Array.isArray(this.sample)) throw new Error('You must provide an array to arrayContaining.');
    if (!Array.isArray(other) && this.sample.length > 0) return false;
    return this.sample.every((item) => util.contains(other, item));
  }
  jasmineToString() {
    return '<jasmine.arrayContaining>';
  }
}

const isAsymmetric = (v) => !!v && typeof v.asymmetricMatch === 'function';

// ---------------------------------------------------------------------------
// MatchersUtil (eq_ of jasmine-core 3.99.1, without the diff builder).

const util = {
  equals(a, b) {
    return eq(a, b, [], []);
  },
  contains(haystack, needle) {
    if (!haystack) return false;
    if (haystack instanceof Set) return haystack.has(needle);
    if (Object.prototype.toString.apply(haystack) === '[object Array]' || !haystack.indexOf) {
      for (let i = 0; i < haystack.length; i++) if (util.equals(haystack[i], needle)) return true;
      return false;
    }
    return haystack.indexOf(needle) >= 0;
  },
};

function keysOf(obj, isArray) {
  const all = Object.keys(obj);
  if (!isArray) return all;
  return all.filter((k) => !/^[0-9]+$/.test(k));
}

function eq(a, b, aStack, bStack) {
  const asymA = isAsymmetric(a);
  const asymB = isAsymmetric(b);
  if (asymA !== asymB) return asymA ? a.asymmetricMatch(b, util) : b.asymmetricMatch(a, util);
  if (a instanceof Error && b instanceof Error) return a.message == b.message;
  if (a === b) return a !== 0 || 1 / a == 1 / b;
  if (a === null || b === null) return a === b;
  const className = Object.prototype.toString.call(a);
  if (className != Object.prototype.toString.call(b)) return false;
  switch (className) {
    case '[object String]':
      return a == String(b);
    case '[object Number]':
      return a != +a ? b != +b : a === 0 && b === 0 ? 1 / a == 1 / b : a == +b;
    case '[object Date]':
    case '[object Boolean]':
      return +a == +b;
    case '[object ArrayBuffer]':
      return eq(new Uint8Array(a), new Uint8Array(b), aStack, bStack);
    case '[object RegExp]':
      return a.source == b.source && a.global == b.global && a.multiline == b.multiline && a.ignoreCase == b.ignoreCase;
    default:
      break;
  }
  if (typeof a != 'object' || typeof b != 'object') return false;
  if (typeof a.then === 'function' && typeof b.then === 'function' && a instanceof Promise && b instanceof Promise) {
    return a === b;
  }
  let length = aStack.length;
  while (length--) {
    if (aStack[length] == a) return bStack[length] == b;
  }
  aStack.push(a);
  bStack.push(b);
  let result = true;
  if (className == '[object Array]') {
    if (a.length !== b.length) result = false;
    for (let i = 0; i < a.length || i < b.length; i++) {
      if (i >= b.length) {
        result = false;
      } else {
        result = eq(i < a.length ? a[i] : undefined, b[i], aStack, bStack) && result;
      }
    }
    if (!result) return false;
  } else if (a instanceof Map && b instanceof Map) {
    if (a.size != b.size) return false;
    const keysA = [...a.keys()];
    const keysB = [...b.keys()];
    const mapKeys = [keysA, keysB];
    const cmpKeys = [keysB, keysA];
    for (let i = 0; result && i < 2; i++) {
      for (let j = 0; result && j < mapKeys[i].length; j++) {
        const mapKey = mapKeys[i][j];
        const cmpKey = cmpKeys[i][j];
        const va = a.get(mapKey);
        const vb =
          isAsymmetric(mapKey) || (isAsymmetric(cmpKey) && eq(mapKey, cmpKey, aStack, bStack))
            ? b.get(cmpKey)
            : b.get(mapKey);
        result = eq(va, vb, aStack, bStack);
      }
    }
    if (!result) return false;
  } else if (a instanceof Set && b instanceof Set) {
    if (a.size != b.size) return false;
    const va = [...a];
    const vb = [...b];
    for (const [base, other] of [
      [va, vb],
      [vb, va],
    ]) {
      for (const x of base) {
        if (!other.some((y) => eq(x, y, [], []))) return false;
      }
    }
  } else if (a instanceof URL && b instanceof URL) {
    return a.toString() === b.toString();
  } else {
    const aCtor = a.constructor;
    const bCtor = b.constructor;
    if (
      aCtor !== bCtor &&
      typeof aCtor === 'function' &&
      typeof bCtor === 'function' &&
      a instanceof aCtor &&
      b instanceof bCtor &&
      !(aCtor instanceof aCtor && bCtor instanceof bCtor)
    ) {
      return false;
    }
  }
  const isArr = className == '[object Array]';
  const aKeys = keysOf(a, isArr);
  if (keysOf(b, isArr).length !== aKeys.length) return false;
  for (const key of aKeys) {
    if (!Object.prototype.hasOwnProperty.call(b, key)) {
      result = false;
      continue;
    }
    if (!eq(a[key], b[key], aStack, bStack)) result = false;
  }
  if (!result) return false;
  aStack.pop();
  bStack.pop();
  return result;
}

// ---------------------------------------------------------------------------
// Spies.

// eslint-disable-next-line no-new-func
const SLOPPY_WRAPPER = new Function('impl', 'return function() { return impl(this, Array.prototype.slice.call(arguments)); };');

function createSpy(name, original) {
  const calls = [];
  let strategy = () => undefined;
  const impl = (self, args) => {
    calls.push({object: self, args, returnValue: undefined});
    const value = strategy.apply(self, args);
    calls[calls.length - 1].returnValue = value;
    return value;
  };
  // A sloppy-mode function, as the spy of jasmine.js: a call without a
  // receiver gets the global object as `this`.
  const spy = SLOPPY_WRAPPER(impl);
  spy.isSpy = true;
  spy.spyName = name || 'unknown';
  spy.and = {
    callThrough() {
      strategy = function(...args) {
        return original.apply(this, args);
      };
      return spy;
    },
    returnValue(v) {
      strategy = () => v;
      return spy;
    },
    returnValues(...vs) {
      strategy = () => vs.shift();
      return spy;
    },
    callFake(fn) {
      strategy = fn;
      return spy;
    },
    throwError(e) {
      strategy = () => {
        throw e instanceof Error ? e : new Error(e);
      };
      return spy;
    },
    stub() {
      strategy = () => undefined;
      return spy;
    },
  };
  spy.calls = {
    count: () => calls.length,
    any: () => calls.length > 0,
    first: () => calls[0],
    mostRecent: () => calls[calls.length - 1],
    argsFor: (i) => (calls[i] ? calls[i].args : []),
    allArgs: () => calls.map((c) => c.args),
    all: () => calls.slice(),
    reset: () => {
      calls.length = 0;
    },
  };
  return spy;
}

// ---------------------------------------------------------------------------
// The built-in matchers (jasmine-core 3.99.1). Each factory gives
// {compare(actual, ...expected)}; compare may return `recordActual`, the
// value that the record keeps in place of the actual value.

function threw(fn) {
  if (typeof fn !== 'function') throw new Error('Actual is not a Function');
  try {
    fn();
  } catch (e) {
    return {threw: true, error: e};
  }
  return {threw: false};
}

function thrownRecord(t) {
  return t.threw ? {threw: true, error: t.error instanceof Error ? `${t.error.name}: ${t.error.message}` : t.error} : {threw: false};
}

function spyRecord(spy) {
  return spy && spy.calls ? {'[Spy calls]': spy.calls.allArgs()} : spy;
}

const BUILTIN = {
  toBe: () => ({compare: (a, e) => ({pass: a === e})}),
  toEqual: () => ({compare: (a, e) => ({pass: util.equals(a, e)})}),
  toBeCloseTo: () => ({
    compare(actual, expected, precision) {
      if (precision !== 0) precision = precision || 2;
      if (expected === null || actual === null) {
        throw new Error('Cannot use toBeCloseTo with null.');
      }
      if (expected === Infinity || expected === -Infinity) return {pass: actual === expected};
      const pow = Math.pow(10, precision + 1);
      const delta = Math.abs(expected - actual);
      const maxDelta = Math.pow(10, -precision) / 2;
      return {pass: Math.round(delta * pow) <= maxDelta * pow};
    },
  }),
  toBeTruthy: () => ({compare: (a) => ({pass: !!a})}),
  toBeFalsy: () => ({compare: (a) => ({pass: !a})}),
  toBeTrue: () => ({compare: (a) => ({pass: a === true})}),
  toBeFalse: () => ({compare: (a) => ({pass: a === false})}),
  toBeDefined: () => ({compare: (a) => ({pass: a !== undefined})}),
  toBeUndefined: () => ({compare: (a) => ({pass: a === undefined})}),
  toBeNull: () => ({compare: (a) => ({pass: a === null})}),
  toBeNaN: () => ({compare: (a) => ({pass: a !== a})}),
  toContain: () => ({compare: (a, e) => ({pass: util.contains(a, e)})}),
  toBeGreaterThan: () => ({compare: (a, e) => ({pass: a > e})}),
  toBeGreaterThanOrEqual: () => ({compare: (a, e) => ({pass: a >= e})}),
  toBeLessThan: () => ({compare: (a, e) => ({pass: a < e})}),
  toBeLessThanOrEqual: () => ({compare: (a, e) => ({pass: a <= e})}),
  toBeInstanceOf: () => ({
    compare(a, e) {
      const v = a === null || a === undefined ? a : Object(a);
      return {pass: v !== null && v !== undefined && v instanceof e};
    },
  }),
  toMatch: () => ({
    compare(a, e) {
      const re = e instanceof RegExp ? e : new RegExp(e);
      return {pass: re.test(a)};
    },
  }),
  toThrow: () => ({
    compare(fn, ...rest) {
      const t = threw(fn);
      if (!t.threw) return {pass: false, recordActual: thrownRecord(t)};
      if (rest.length === 0) return {pass: true, recordActual: thrownRecord(t)};
      return {pass: util.equals(t.error, rest[0]), recordActual: thrownRecord(t)};
    },
  }),
  toThrowError: () => ({
    compare(fn, ...rest) {
      const t = threw(fn);
      const rec = thrownRecord(t);
      if (!t.threw || !(t.error instanceof Error)) return {pass: false, recordActual: rec};
      let type = null;
      let message = null;
      if (typeof rest[0] === 'function') {
        type = rest[0];
        message = rest.length > 1 ? rest[1] : null;
      } else if (rest.length) {
        message = rest[0];
      }
      if (type && !(t.error instanceof type)) return {pass: false, recordActual: rec};
      if (message === null || message === undefined) return {pass: true, recordActual: rec};
      if (message instanceof RegExp) return {pass: message.test(t.error.message), recordActual: rec};
      return {pass: t.error.message == message, recordActual: rec};
    },
  }),
  toHaveBeenCalled: () => ({
    compare: (spy) => ({pass: spy.calls.count() > 0, recordActual: spyRecord(spy)}),
  }),
  toHaveBeenCalledTimes: () => ({
    compare: (spy, n) => ({pass: spy.calls.count() === n, recordActual: spyRecord(spy)}),
  }),
  toHaveBeenCalledWith: () => ({
    compare: (spy, ...args) => ({
      pass: spy.calls.allArgs().some((callArgs) => util.equals(callArgs, args)),
      recordActual: spyRecord(spy),
    }),
  }),
};

/** The matchers that test the identity, the type or the truthiness only. */
const REF_MATCHERS = new Set([
  'toBe',
  'toBeDefined',
  'toBeUndefined',
  'toBeNull',
  'toBeTruthy',
  'toBeFalsy',
  'toBeTrue',
  'toBeFalse',
  'toBeNaN',
  'toBeInstanceOf',
]);

// ---------------------------------------------------------------------------
// The suite tree and the runner.

function callerLine(filename) {
  const stack = new Error().stack || '';
  for (const line of stack.split('\n')) {
    if (line.includes(filename)) {
      const m = line.match(/:(\d+):\d+\)?$/);
      if (m) return +m[1];
    }
  }
  return null;
}

/**
 * Creates the stand-in. [specFile] is the file name of the spec script (for
 * the line of each `it`). [serialize] is the serializer of the records.
 * Returns {globals, run, addGlobalHooks}.
 */
export function createJasmine({specFile, serialize}) {
  const root = {name: null, parent: null, children: [], beforeAll: [], afterAll: [], beforeEach: [], afterEach: []};
  let suite = root;
  let customMatchers = {};
  let spies = [];
  const declarationErrors = [];

  function describe(name, fn, x = false) {
    const child = {
      name,
      parent: suite,
      children: [],
      beforeAll: [],
      afterAll: [],
      beforeEach: [],
      afterEach: [],
      x: x || suite.x,
      kind: 'suite',
    };
    suite.children.push(child);
    const saved = suite;
    suite = child;
    try {
      fn.call({});
    } catch (e) {
      declarationErrors.push({suite: suitePath(child).join(' '), error: errorText(e)});
    } finally {
      suite = saved;
    }
  }

  function it(name, fn, timeout, x = false) {
    suite.children.push({
      kind: 'spec',
      name,
      fn,
      timeout: typeof timeout === 'number' ? timeout : TIMEOUT_MS,
      suite,
      x: x || suite.x || !fn,
      line: callerLine(specFile),
    });
  }

  function suitePath(s) {
    const path = [];
    for (let p = s; p && p.name !== null; p = p.parent) path.unshift(p.name);
    return path;
  }

  function errorText(e) {
    if (e instanceof Error) return `${e.name}: ${e.message}`;
    return String(e);
  }

  /**
   * The short record of an object for a matcher that tests the identity,
   * the type or the truthiness only: '[ref <class>]'. A change of the
   * contents of the object does not change what such a matcher asserts.
   */
  function ref(v) {
    if (v === null || (typeof v !== 'object' && typeof v !== 'function')) return serialize(v);
    const s = serialize.shallow(v);
    if (typeof s === 'string') return s;
    const proto = Object.getPrototypeOf(v);
    const name = Array.isArray(v) ? 'Array' : (proto && proto.constructor && proto.constructor.name) || 'Object';
    return `[ref ${name}]`;
  }

  /**
   * The actual value of a record. The identity, type and truthiness
   * matchers keep a ref. toEqual keeps only the keys of an
   * objectContaining sample, and a ref for jasmine.any and anything; the
   * rest is the full serialization.
   */
  function recordedActual(name, actual, expected) {
    if (REF_MATCHERS.has(name)) return ref(actual);
    if (name === 'toEqual' && expected.length === 1) return project(actual, expected[0], 0);
    return serialize(actual);
  }

  /**
   * [a] serialized along the structure of [e]: the same object in both
   * gives a ref (the deep equality is then true for any contents).
   */
  /** The expected value of a record, with the rules of recordedActual. */
  function recordedExpected(name, actual, e) {
    if (REF_MATCHERS.has(name)) return ref(e);
    if (name === 'toEqual') return project(e, actual, 0);
    return serialize(e);
  }

  function project(a, e, depth) {
    if (a === e && a && typeof a === 'object') return ref(a);
    if (depth > 6) return serialize(a);
    if (isAsymmetric(e)) {
      if (e instanceof ObjectContaining && a && typeof a === 'object') {
        const out = {};
        for (const k in e.sample) {
          let v;
          try {
            v = a[k];
          } catch (err) {
            out[k] = `[Throws: ${err && err.message}]`;
            continue;
          }
          out[k] = project(v, e.sample[k], depth + 1);
        }
        return {'[objectContaining]': out};
      }
      if (e instanceof Any || e instanceof Anything) return ref(a);
      return serialize(a);
    }
    if (!a || typeof a !== 'object' || !e || typeof e !== 'object') return serialize(a);
    if (Array.isArray(e) && Array.isArray(a)) {
      return a.map((x, i) => (i < e.length ? project(x, e[i], depth + 1) : serialize(x)));
    }
    const plain = (o) => [Object.prototype, null].includes(Object.getPrototypeOf(o));
    if (Array.isArray(a) || Array.isArray(e) || !plain(e) || !plain(a)) return serialize(a);
    const out = {};
    for (const k of Object.keys(a)) {
      out[k] = Object.prototype.hasOwnProperty.call(e, k) ? project(a[k], e[k], depth + 1) : serialize(a[k]);
    }
    return out;
  }

  function expect(actual) {
    return makeExpectation(actual, false, null);
  }

  function makeExpectation(actual, isNot, context) {
    const target = {};
    const all = {...BUILTIN, ...customMatchers};
    for (const [name, factory] of Object.entries(all)) {
      target[name] = (...expected) => runMatcher(name, factory, actual, expected, isNot, context);
    }
    if (!isNot) {
      Object.defineProperty(target, 'not', {get: () => makeExpectation(actual, true, context)});
    }
    target.withContext = (text) => makeExpectation(actual, isNot, text);
    return target;
  }

  function runMatcher(name, factory, actual, expected, isNot, context) {
    const kase = currentCase;
    const record = {matcher: name, not: isNot};
    if (context !== null) record.context = context;
    let result;
    try {
      const m = factory(util, []);
      if (isNot && m.negativeCompare) {
        result = m.negativeCompare(actual, ...expected);
      } else {
        result = m.compare(actual, ...expected);
        if (isNot) result = {...result, pass: !result.pass};
      }
    } catch (e) {
      record.actual = recordedActual(name, actual, expected);
      record.expected = expected.length === 1 ? serialize(expected[0]) : serialize(expected);
      record.pass = false;
      record.error = errorText(e);
      if (kase) {
        kase.values.push(record);
        kase.errors.push(`${name}: ${errorText(e)}`);
      }
      if (e instanceof Unsupported) throw e;
      return;
    }
    record.actual = 'recordActual' in result ? serialize(result.recordActual) : recordedActual(name, actual, expected);
    if (expected.length === 1) record.expected = recordedExpected(name, actual, expected[0]);
    else if (expected.length > 1) record.expected = serialize(expected);
    record.pass = !!result.pass;
    if (!kase) return;
    kase.values.push(record);
    if (!record.pass) {
      const msg =
        (typeof result.message === 'function' ? result.message() : result.message) ||
        `Expected ${pp(serialize, actual)}${isNot ? ' not' : ''} ${name.replace(/[A-Z]/g, (s) => ' ' + s.toLowerCase()).trim()}` +
          (expected.length ? ` ${expected.map((e) => pp(serialize, e)).join(', ')}` : '') +
          '.';
      kase.failures.push((context ? context + ': ' : '') + String(msg));
    }
  }

  function spyOn(obj, name) {
    if (!obj) throw new Error(`spyOn could not find an object to spy upon for ${name}()`);
    const original = obj[name];
    if (typeof original !== 'function') throw new Error(`${name}() method does not exist`);
    const had = Object.prototype.hasOwnProperty.call(obj, name);
    const spy = createSpy(name, original);
    obj[name] = spy;
    spies.push(() => {
      if (had) obj[name] = original;
      else delete obj[name];
    });
    return spy;
  }

  function fail(message) {
    if (currentCase) currentCase.failures.push(`Failed: ${message instanceof Error ? message.message : message}`);
  }

  function pending(message) {
    throw new Unsupported(`pending(${message ? JSON.stringify(message) : ''})`);
  }

  const jasmine = {
    any: (c) => new Any(c),
    anything: () => new Anything(),
    objectContaining: (s) => new ObjectContaining(s),
    arrayContaining: (s) => new ArrayContaining(s),
    createSpy: (name, fn) => createSpy(name, fn || function() {}),
    createSpyObj(baseName, methods) {
      const obj = {};
      const names = Array.isArray(methods) ? methods : Object.keys(methods);
      for (const n of names) {
        obj[n] = createSpy(`${baseName}.${n}`, () => {});
        if (!Array.isArray(methods)) obj[n].and.returnValue(methods[n]);
      }
      return obj;
    },
    addMatchers(matchers) {
      Object.assign(customMatchers, matchers);
    },
    matchersUtil: util,
    DEFAULT_TIMEOUT_INTERVAL: TIMEOUT_MS,
  };

  // The function runner: a `done` function, a promise, or a plain return.
  let abortCurrent = null;
  function runFn(fn, ctx, kase, timeout) {
    return new Promise((resolve) => {
      let finished = false;
      let timer = null;
      const finish = (err) => {
        if (finished) return;
        finished = true;
        clearTimeout(timer);
        abortCurrent = null;
        if (err !== undefined) recordError(kase, err);
        resolve();
      };
      abortCurrent = finish;
      timer = setTimeout(() => {
        kase.timedOut = true;
        kase.failures.push(`Timeout - Async function did not complete within ${timeout}ms`);
        finish();
      }, timeout);
      try {
        if (fn.length > 0) {
          const done = (err) => finish(err === undefined || err === null ? undefined : err);
          done.fail = (msg) => {
            kase.failures.push(`Failed: ${msg instanceof Error ? msg.message : msg}`);
            finish();
          };
          fn.call(ctx, done);
        } else {
          const r = fn.call(ctx);
          if (r && typeof r.then === 'function') {
            r.then(
              () => finish(),
              (e) => finish(e === undefined ? new Error('rejected with undefined') : e),
            );
          } else {
            finish();
          }
        }
      } catch (e) {
        finish(e);
      }
    });
  }

  function recordError(kase, err) {
    if (!kase) return;
    if (err instanceof Unsupported) {
      if (!kase.unsupported) kase.unsupported = err.reason;
      return;
    }
    kase.errors.push(errorText(err) + (err && err.stack ? `\n${String(err.stack).split('\n').slice(1, 4).join('\n')}` : ''));
  }

  /** An error outside the queue (an uncaught exception or rejection). */
  function globalError(err) {
    const kase = currentCase;
    if (kase) {
      recordError(kase, err);
      if (abortCurrent && !(err instanceof Unsupported)) abortCurrent();
      else if (abortCurrent && err instanceof Unsupported) abortCurrent();
    } else {
      orphanErrors.push(errorText(err));
    }
  }
  const orphanErrors = [];

  async function runSuite(s, cases, ctxProto) {
    const suiteCtx = Object.create(ctxProto);
    const pseudo = (label) => ({
      fullName: `${suitePath(s).join(' ')} [${label}]`,
      describe: suitePath(s),
      it: `[${label}]`,
      notes: [],
      values: [],
      failures: [],
      errors: [],
    });
    if (!s.x && s.beforeAll.length) {
      const k = pseudo('beforeAll');
      currentCase = k;
      for (const fn of s.beforeAll) await runFn(fn, suiteCtx, k, TIMEOUT_MS);
      currentCase = null;
      if (k.errors.length || k.failures.length || k.unsupported) cases.push(finishCase(k));
    }
    for (const child of s.children) {
      if (child.kind === 'suite') await runSuite(child, cases, suiteCtx);
      else cases.push(await runSpec(child, suiteCtx, cases.length));
    }
    if (!s.x && s.afterAll.length) {
      const k = pseudo('afterAll');
      currentCase = k;
      for (const fn of s.afterAll) await runFn(fn, suiteCtx, k, TIMEOUT_MS);
      currentCase = null;
      if (k.errors.length || k.failures.length || k.unsupported) cases.push(finishCase(k));
    }
  }

  function finishCase(k) {
    let status;
    if (k.skipped) status = 'skipped';
    else if (k.unsupported) status = 'unsupported';
    else if (k.errors.length) status = 'error';
    else if (k.failures.length) status = 'fail';
    else status = 'pass';
    const out = {
      index: k.index,
      fullName: k.fullName,
      describe: k.describe,
      it: k.it,
      line: k.line,
      status,
    };
    if (k.unsupported) out.reason = k.unsupported;
    out.error = [...k.errors, ...k.failures].join('\n') || null;
    out.notes = k.notes;
    out.values = k.values;
    return out;
  }

  async function runSpec(spec, suiteCtx, index) {
    const describePath = suitePath(spec.suite);
    const k = {
      index,
      fullName: [...describePath, spec.name].join(' '),
      describe: describePath,
      it: spec.name,
      line: spec.line,
      notes: [],
      values: [],
      failures: [],
      errors: [],
    };
    if (spec.x) {
      k.skipped = true;
      return finishCase(k);
    }
    customMatchers = {};
    spies = [];
    currentCase = k;
    const ctx = Object.create(suiteCtx);
    const chain = [];
    for (let p = spec.suite; p; p = p.parent) chain.unshift(p);
    try {
      for (const s of chain) for (const fn of s.beforeEach) await runFn(fn, ctx, k, TIMEOUT_MS);
      await runFn(spec.fn, ctx, k, spec.timeout);
      for (const s of chain.slice().reverse()) for (const fn of s.afterEach) await runFn(fn, ctx, k, TIMEOUT_MS);
    } finally {
      for (const restore of spies.reverse()) restore();
      spies = [];
      // Let the microtasks of the case settle before the next case.
      await new Promise((r) => setImmediate(r));
      currentCase = null;
    }
    return finishCase(k);
  }

  const globals = {
    describe: (n, f) => describe(n, f),
    xdescribe: (n, f) => describe(n, f, true),
    fdescribe: (n, f) => describe(n, f),
    it: (n, f, t) => it(n, f, t),
    xit: (n, f, t) => it(n, f, t, true),
    fit: (n, f, t) => it(n, f, t),
    beforeEach: (f) => suite.beforeEach.push(f),
    afterEach: (f) => suite.afterEach.unshift(f),
    beforeAll: (f) => suite.beforeAll.push(f),
    afterAll: (f) => suite.afterAll.unshift(f),
    expect,
    spyOn,
    fail,
    pending,
    jasmine,
  };

  /** Runs the tree in file order and returns the case records. */
  async function run(filter) {
    const cases = [];
    if (filter) prune(root, filter);
    await runSuite(root, cases, {});
    return {cases, declarationErrors, orphanErrors};
  }

  function prune(s, filter) {
    s.children = s.children.filter((c) => {
      if (c.kind === 'suite') {
        prune(c, filter);
        return c.children.length > 0;
      }
      return [...suitePath(c.suite), c.name].join(' ').includes(filter);
    });
  }

  return {globals, run, globalError};
}
