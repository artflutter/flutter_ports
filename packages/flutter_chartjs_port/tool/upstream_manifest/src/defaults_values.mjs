// Original code, not ported from Chart.js: the defaults snapshot of the upstream manifest.
//
// After loadChart registers the controllers, scales, elements and plugins,
// `defaults`, `overrides` and `descriptors` of core.defaults.js hold every
// registered value. The snapshot flattens each of them into a map from a key
// path (`plugins.legend.labels.boxWidth`, `events[0]`) to a leaf:
// - a string, a boolean, null or a finite number: the value itself;
// - `{"number": "NaN"}` (or "Infinity", "-Infinity", "-0");
// - `{"undefined": true}`;
// - `{"function": "<hash>"}`: the first 12 hex digits of the sha256 of the
//   function source, with each run of white space as one space;
// - `{}` or `[]` for an empty object or array;
// - `{"route": <leaf>}`: a property that defaults.route made. The leaf is
//   the value that it resolves to now, or the flat map of that value when it
//   is an object;
// - `{"object": "<name>"}`: an object that is not plain, by constructor name;
// - `{"cycle": "<path>"}`: an object that one of its ancestors is.
// An array of strings, numbers, booleans and nulls is one leaf. The keys are
// sorted.

import {createHash} from 'node:crypto';

import {sortedMap} from './json_writer.mjs';

/** The flat map of `root`. The root itself can be a class instance. */
export function flatten(root) {
  const out = {};
  const ancestors = new Map();
  const visit = (value, path) => {
    const leaf = leafOf(value);
    if (leaf !== undefined) {
      out[path] = leaf;
      return;
    }
    if (ancestors.has(value)) {
      out[path] = {cycle: ancestors.get(value)};
      return;
    }
    const proto = Object.getPrototypeOf(value);
    const plain = path === '' || Array.isArray(value) || proto === null ||
      proto === Object.prototype || Object.getPrototypeOf(proto) === null;
    if (!plain) {
      out[path] = {object: proto?.constructor?.name ?? 'unknown'};
      return;
    }
    const keys = Object.keys(value);
    if (keys.length === 0) {
      out[path] = Array.isArray(value) ? [] : {};
      return;
    }
    ancestors.set(value, path);
    for (const key of keys) {
      const child = Array.isArray(value) ? `${path}[${key}]` : path ? `${path}.${key}` : key;
      const descriptor = Object.getOwnPropertyDescriptor(value, key);
      if (descriptor.get) {
        const resolved = descriptor.get.call(value);
        const inner = leafOf(resolved);
        out[child] = {route: inner === undefined ? flatten(resolved) : inner};
      } else {
        visit(descriptor.value, child);
      }
    }
    ancestors.delete(value);
  };
  visit(root, '');
  return sortedMap(out);
}

/** The leaf of `value`, or undefined for a non-empty object or array. */
function leafOf(value) {
  switch (typeof value) {
    case 'string':
    case 'boolean':
      return value;
    case 'number':
      if (Object.is(value, -0)) return {number: '-0'};
      return Number.isFinite(value) ? value : {number: String(value)};
    case 'undefined':
      return {undefined: true};
    case 'function':
      return {function: functionHash(value)};
    case 'object':
      if (value === null) return null;
      if (Array.isArray(value) && value.length > 0 &&
          value.every((v) => v === null || ['string', 'number', 'boolean'].includes(typeof v) &&
            (typeof v !== 'number' || (Number.isFinite(v) && !Object.is(v, -0))))) {
        return [...value];
      }
      return undefined;
    default:
      return {object: typeof value};
  }
}

/** The first 12 hex digits of the sha256 of the source of `fn`. */
export function functionHash(fn) {
  const source = Function.prototype.toString.call(fn).replace(/\s+/g, ' ');
  return createHash('sha256').update(source).digest('hex').slice(0, 12);
}
