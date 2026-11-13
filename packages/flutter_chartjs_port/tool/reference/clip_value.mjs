// Original code, not ported from Chart.js: the dataset clip of the reference data.
//
// The port holds the dataset option `clip` as a ChartClip (row
// adapt-chart-clip-option). dartClip gives the Dart literal of an upstream
// value: a number is each side, `false` is `ChartClip.none`, and an object
// sets its sides. A side `false` has no clip, and `true` is 0. An absent side
// has no clip in the port, where upstream gives `undefined`, so the data give
// each side. This module has no side effects at its load.

/** The Dart literal of a side: an int literal for a whole number. */
function side(v) {
  if (!Number.isFinite(v)) throw new Error(`A clip side that is not finite: ${v}`);
  if (Object.is(v, -0)) return '-0.0';
  return String(v);
}

/** The Dart literal of the upstream `clip` value [value], a ChartClip. */
export function dartClip(value) {
  if (value === false) return 'ChartClip.none';
  if (value === true) return 'ChartClip.all(0)';
  if (typeof value === 'number') return `ChartClip.all(${side(value)})`;
  const sides = ['left', 'top', 'right', 'bottom'].flatMap((name) => {
    const v = value[name];
    if (v === undefined) throw new Error(`A clip object without ${name}`);
    if (v === false) return [];
    return [`${name}: ${side(v === true ? 0 : v)}`];
  });
  return `ChartClip(${sides.join(', ')})`;
}

/** Whether [value] is an upstream value of the dataset option `clip`. */
export function isClipValue(value) {
  return (
    typeof value === 'number' ||
    typeof value === 'boolean' ||
    (value !== null && typeof value === 'object' && value.constructor === Object)
  );
}
