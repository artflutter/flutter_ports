// Original code, not ported from Chart.js: the deterministic JSON writer of the upstream manifest.
//
// The manifest is committed, and its diffs are reviewed. So the writer gives
// the same bytes for the same value: keys in insertion order (the builders
// insert them in a fixed order, and sort the keys of maps), two-space
// indentation and a trailing newline. A value is on one line when its compact
// form is short, or when it is flat: an array or object whose members are
// strings, numbers, booleans, null or arrays of these. So each case, fixture
// and site record is one line.

/** The longest compact form, without indentation, that stays on one line. */
const INLINE_WIDTH = 120;

/** `value` as JSON text with a trailing newline. */
export function stringify(value) {
  return `${write(value, '')}\n`;
}

function write(value, indent) {
  const compact = JSON.stringify(value);
  if (compact === undefined) {
    throw new TypeError(`not JSON: ${String(value)}`);
  }
  if (value === null || typeof value !== 'object' || compact.length <= INLINE_WIDTH ||
      isFlat(value)) {
    return compact;
  }
  const inner = `${indent}  `;
  if (Array.isArray(value)) {
    if (value.length === 0) return '[]';
    return `[\n${value.map((v) => inner + write(v, inner)).join(',\n')}\n${indent}]`;
  }
  const keys = Object.keys(value).filter((k) => value[k] !== undefined);
  if (keys.length === 0) return '{}';
  return `{\n${keys
    .map((k) => `${inner}${JSON.stringify(k)}: ${write(value[k], inner)}`)
    .join(',\n')}\n${indent}}`;
}

const isScalar = (v) => v === null || typeof v !== 'object';

/** Whether the members of `value` are scalars or arrays of scalars. */
function isFlat(value) {
  return Object.values(value).every((v) =>
    isScalar(v) || (Array.isArray(v) && v.every(isScalar)));
}

/** A copy of the map `object` with its keys in code-unit order. */
export function sortedMap(object) {
  const result = {};
  for (const key of Object.keys(object).sort(compareStrings)) {
    result[key] = object[key];
  }
  return result;
}

/** Code-unit order of strings, independent of the locale. */
export function compareStrings(a, b) {
  return a < b ? -1 : a > b ? 1 : 0;
}
