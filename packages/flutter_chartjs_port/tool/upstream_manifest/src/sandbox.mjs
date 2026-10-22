// Original code, not ported from Chart.js: the node:vm sandbox of the upstream manifest.
//
// The spec files and the fixture configs run in a node:vm context. Their
// globals are the real Chart object, a few named values, and "stubs": a stub
// is a function Proxy that returns a stub for every property read, call and
// construction. A global that the code reads and the sandbox does not have
// throws a ReferenceError. The caller then adds a stub of that name and runs
// the code again in a new context (see `runWithStubs`).

import vm from 'node:vm';

const STUB_LABEL = Symbol('stub label');

/** Records the stubs that a sandbox makes. */
export class StubRegistry {
  constructor() {
    this.stubs = new WeakSet();
    // The strings that the conversions of a stub gave: `valueOf`, `toString`
    // and `Symbol.toPrimitive` (see `text`).
    this.texts = new Set();
  }

  /**
   * The string `[stub <label>]` that a stub converts to. The registry records
   * it, so that `isStubText` finds a string made from a stub, for example
   * `moment(...).valueOf()` of a fixture config.
   */
  text(label) {
    const text = `[stub ${label}]`;
    this.texts.add(text);
    return text;
  }

  /** Whether the string `value` holds a string that a stub converted to. */
  isStubText(value) {
    if (typeof value !== 'string' || !value.includes('[stub ')) return false;
    for (const text of this.texts) {
      if (value.includes(text)) return true;
    }
    return false;
  }

  /** Whether `value` is a stub of this registry. */
  isStub(value) {
    return (typeof value === 'function' || typeof value === 'object') &&
      value !== null && this.stubs.has(value);
  }

  /**
   * A stub named `label`. A property in `fields` reads that value instead of
   * a stub.
   */
  make(label, fields = {}) {
    const children = new Map();
    const registry = this;
    const target = function stub() {};
    const proxy = new Proxy(target, {
      get(_, prop) {
        if (prop === STUB_LABEL) return label;
        if (Object.hasOwn(fields, prop)) return fields[prop];
        if (prop === Symbol.toPrimitive) return () => registry.text(label);
        if (prop === 'then' || typeof prop === 'symbol') return undefined;
        if (prop === 'toString' || prop === 'valueOf') {
          return () => registry.text(label);
        }
        if (!children.has(prop)) {
          children.set(prop, registry.make(`${label}.${prop}`));
        }
        return children.get(prop);
      },
      set(_, prop, value) {
        fields[prop] = value;
        return true;
      },
      has() {
        return true;
      },
      apply() {
        return registry.make(`${label}()`);
      },
      construct() {
        return registry.make(`new ${label}`);
      },
    });
    this.stubs.add(proxy);
    return proxy;
  }
}

/** The name in a "<name> is not defined" ReferenceError, or null. */
export function undefinedGlobal(error) {
  if (error?.name !== 'ReferenceError') return null;
  const match = /^(\S+) is not defined$/.exec(String(error.message));
  return match ? match[1] : null;
}

/**
 * Runs `run(context)` in a new node:vm context made from `globals()` plus one
 * stub for each name in the returned `stubbed` list. A ReferenceError for a
 * missing global adds a stub of that name and runs again, at most 50 times.
 * Returns `{result, stubbed}`, with the stub names sorted.
 */
export function runWithStubs(registry, globals, run) {
  const stubbed = [];
  for (let attempt = 0; attempt < 50; attempt++) {
    const sandbox = globals();
    for (const name of stubbed) sandbox[name] = registry.make(name);
    const context = vm.createContext(sandbox);
    try {
      return {result: run(context), stubbed: [...stubbed].sort()};
    } catch (error) {
      const name = undefinedGlobal(error?.cause ?? error);
      if (name === null || stubbed.includes(name)) throw error;
      stubbed.push(name);
    }
  }
  throw new Error(`too many missing globals: ${stubbed.join(', ')}`);
}
