// Original code, not ported from Chart.js: the fill of the reference data.
//
// The port holds the option `fill` as a FillTarget (Chart.js ADR 0140, row
// adapt-fill-target-objects). fillTargetCode gives the Dart expression of an
// upstream value: `false` is `FillTarget.none`, `true` and `'origin'` are
// `FillTarget.toOrigin`, a whole number is a dataset index, `'+n'` and `'-n'`
// are a relative index, `{value}` is a value, and an object with `target`,
// `above` or `below` is a split fill. This module has no side effects at its
// load.

/**
 * The Dart literal of a number of a `{value}` fill, a `double` parameter: an
 * int literal for a whole number (prefer_int_literals).
 */
function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  return String(v);
}

/** The FillTarget members of the fill keywords of upstream. */
const FILL_KEYWORDS = {
  origin: 'FillTarget.toOrigin',
  start: 'FillTarget.toStart',
  end: 'FillTarget.toEnd',
  stack: 'FillTarget.toStacked',
  shape: 'FillTarget.shape',
};

/**
 * The Dart expression of the FillTarget of the upstream fill value [v]
 * (Chart.js ADR 0140), or `null` for a value that is no fill target: an
 * absent or `null` fill, a function, a float, an array, a text that is no
 * keyword and no relative index. [paint] gives the Dart expression of a color
 * of a split fill.
 */
export function fillTargetCode(v, paint = null) {
  if (v === false) return 'FillTarget.none';
  if (v === true) return 'FillTarget.toOrigin';
  if (typeof v === 'number') {
    return Number.isInteger(v) ? `FillTarget.toDataset(${Object.is(v, -0) ? 0 : v})` : null;
  }
  if (typeof v === 'string') {
    if (Object.hasOwn(FILL_KEYWORDS, v)) return FILL_KEYWORDS[v];
    const m = /^([+-])(\d+)$/.exec(v);
    if (!m) return null;
    const offset = (m[1] === '-' ? -1 : 1) * Number(m[2]);
    if (offset === 1) return 'FillTarget.toNext';
    if (offset === -1) return 'FillTarget.toPrevious';
    return `FillTarget.toRelative(${Object.is(offset, -0) ? 0 : offset})`;
  }
  if (v === null || typeof v !== 'object' || Object.getPrototypeOf(v) !== Object.prototype) return null;
  const keys = Object.keys(v);
  if (keys.length === 1 && keys[0] === 'value' && typeof v.value === 'number') {
    return `FillTarget.toValue(${num(v.value)})`;
  }
  if (!('target' in v) && !('above' in v) && !('below' in v)) return null;
  // `valueOrDefault(fillOption.target, fillOption)` (filler.options.js:123):
  // an absent target takes the object itself, a `null` target no fill.
  let target;
  if (v.target === undefined) {
    const {above: _above, below: _below, ...rest} = v;
    target = fillTargetCode(rest, paint);
  } else {
    target = v.target === null ? 'FillTarget.none' : fillTargetCode(v.target, paint);
  }
  if (target === null) return null;
  const colors = [];
  for (const side of ['above', 'below']) {
    if (v[side] === undefined) continue;
    if (paint === null) throw new Error(`A split fill color without a paint writer: ${v[side]}`);
    colors.push(`${side}: ${paint(v[side])}`);
  }
  return `${target}.split(${colors.join(', ')})`;
}

/**
 * [code] with `const` before its FillTarget constructor call, for a place
 * outside a const literal (prefer_const_constructors): the receiver of a
 * split fill is const too.
 */
export function constFill(code) {
  return code.replace(/^(FillTarget\.to(?:Dataset|Relative|Value)\()/, 'const $1');
}
