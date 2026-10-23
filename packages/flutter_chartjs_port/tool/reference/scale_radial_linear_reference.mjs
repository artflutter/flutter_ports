// Original code, not ported from Chart.js: radial linear scale reference generator.
//
// It writes test/port/scales/scale_radial_linear_reference.dart, the data of
// test/port/scales/scale.radialLinear_test.dart: real charts with the radial
// linear scale of a build of the pinned Chart.js (see the header of
// tool/reference/scale_chart_common.mjs for the method, the usage and the
// limits).
//
// The charts use the radial test controller `radialTest`
// (RadialTestController of scale_chart_common.mjs): the radial linear scale
// on the axis r and the aspect ratio 1. It gives the parsed value r to
// getPointPositionForValue unchanged, as upstream does. Its Dart
// counterpart, radialLinearTestController of scale_chart_harness.dart, also
// gives the parsed value unchanged (Chart.js ADR 0025, section 9). Thus a
// null, undefined or NaN data value, which parses to null, gives a point at
// NaN, not at the value 0.
//
// For each case, the script records the chart area, the scale (type, min,
// max, ticks, box, label rotation, paddings, the pixel mapping of the base
// class), the points and the calls of one draw. The observations also have
// the members of the radial scale (radialObservations): the center, the
// drawing area, the value range of LinearScaleBase, the tick limit, the
// labels, the point labels and their items, the point label positions and
// contexts, and the results of getIndexAngle, getDistanceFromCenterForValue,
// getValueForDistanceFromCenter, getPointPosition, getPointPositionForValue
// and getBasePosition for fixed arguments.
//
// A case with hidden data indices calls chart.toggleDataVisibility in the
// hook beforeInit of an inline plugin: the first update reads the hidden
// indices through getDataVisibility (scale.radialLinear.js:463).
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   node tool/reference/scale_radial_linear_reference.mjs \
//     <build>/dist/chart.js
//
// or with the environment variable CHARTJS_DIST.

import {fileURLToPath} from 'node:url';

import {
  RadialTestController,
  loadChartJs,
  named,
  registerBuiltins,
  runCase,
  writeReference,
} from './scale_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/scales/scale_radial_linear_reference.dart', import.meta.url),
);

const C = await loadChartJs();

registerBuiltins(C, RadialTestController);

/**
 * The observations of a radial linear scale [s], after the observations of
 * `observe`. The Dart test gives the same keys with the same calls.
 *
 * - `xCenter`, `yCenter`, `drawingArea`; `startValue`, `endValue` and
 *   `valueRange` (`_startValue`, `_endValue`, `_valueRange`); `tickLimit`
 *   (getTickLimit()).
 * - `labels`: a copy of getLabels(). `pointLabels`: a copy of
 *   `_pointLabels`.
 * - `pointLabelItems`: `[visible, x, y, textAlign, left, top, right,
 *   bottom]` of each item of `_pointLabelItems`.
 * - `pointLabelPositions`: getPointLabelPosition(i) of each item, as
 *   `[left, top, right, bottom]`.
 * - `pointLabelContexts`: getPointLabelContext of -1, 0, n - 1 and n (n
 *   point labels), as `[type, index, label]`, or 'undefined'.
 * - `indexAngles`: getIndexAngle of 0, 1, 2, 0.5, n and -1.
 * - `distances`: getDistanceFromCenterForValue of min, the middle, max,
 *   min - 10, 0, null, undefined, NaN, '5', true and Infinity.
 * - `valuesForDistances`: getValueForDistanceFromCenter of 0, the half of
 *   the drawing area, the drawing area, -10, null and undefined.
 * - `pointPositions`: getPointPositionForValue of (0, min), (1, the middle),
 *   (2.5, max), (0, null) and (n, '5'), as `[x, y, angle]`.
 * - `pointPosition`: getPointPosition(1, 50, 0.3).
 * - `basePositions`: getBasePosition of undefined, null, 0, 1, 2.5 and NaN.
 */
function radialObservations(s) {
  if (!(s instanceof C.RadialLinearScale)) return {};
  const n = s._pointLabels.length;
  const mid = (s.min + s.max) / 2;
  const pos = (p) => [p.x, p.y, p.angle];
  const context = (i) => {
    const c = s.getPointLabelContext(i);
    return c === undefined ? 'undefined' : [c.type, c.index, c.label];
  };
  return {
    xCenter: s.xCenter,
    yCenter: s.yCenter,
    drawingArea: s.drawingArea,
    startValue: s._startValue,
    endValue: s._endValue,
    valueRange: s._valueRange,
    tickLimit: s.getTickLimit(),
    labels: [...s.getLabels()],
    pointLabels: [...s._pointLabels],
    pointLabelItems: s._pointLabelItems.map((it) => [
      it.visible,
      it.x,
      it.y,
      it.textAlign,
      it.left,
      it.top,
      it.right,
      it.bottom,
    ]),
    pointLabelPositions: s._pointLabelItems.map((_, i) => {
      const p = s.getPointLabelPosition(i);
      return [p.left, p.top, p.right, p.bottom];
    }),
    pointLabelContexts: [-1, 0, n - 1, n].map(context),
    indexAngles: [0, 1, 2, 0.5, n, -1].map((i) => s.getIndexAngle(i)),
    distances: [s.min, mid, s.max, s.min - 10, 0, null, undefined, NaN, '5', true, Infinity].map(
      (v) => s.getDistanceFromCenterForValue(v),
    ),
    valuesForDistances: [0, s.drawingArea / 2, s.drawingArea, -10, null, undefined].map((d) =>
      s.getValueForDistanceFromCenter(d),
    ),
    pointPositions: [
      [0, s.min],
      [1, mid],
      [2.5, s.max],
      [0, null],
      [n, '5'],
    ].map(([i, v]) => pos(s.getPointPositionForValue(i, v))),
    pointPosition: pos(s.getPointPosition(1, 50, 0.3)),
    basePositions: [undefined, null, 0, 1, 2.5, NaN].map((i) => pos(s.getBasePosition(i))),
  };
}

// ---------------------------------------------------------------------------
// The named functions. The Dart test has a function of each name.

/** A point label callback with a number, an empty string, null and lines. */
const pointLabelCallback = named('pointLabelCallback', (label, index) => {
  switch (index) {
    case 0:
      return 0;
    case 1:
      return '';
    case 2:
      return null;
    case 3:
      return [label, 'x' + index];
    default:
      return label + '!';
  }
});

/** A scriptable point label color: by the index of the context. */
const pointLabelColor = named('pointLabelColor', (ctx) => (ctx.index % 2 ? 'red' : 'blue'));

/** A scriptable angle line color: by the label of the context. */
const angleLineColor = named('angleLineColor', (ctx) => (ctx.label === 'B' ? 'green' : 'gray'));

/** A scriptable grid color: by the tick index of the context. */
const gridColor = named('gridColor', (ctx) => (ctx.index > 2 ? 'orange' : 'purple'));

/** A scriptable point label padding: by the index of the context. */
const pointLabelPadding = named('pointLabelPadding', (ctx) => 2 + 3 * ctx.index);

/** A scriptable angle line width: 0 for the index 0. */
const angleLineWidth = named('angleLineWidth', (ctx) => (ctx.index === 0 ? 0 : 1));

/** A scriptable angle line color: an empty string for the index 1. */
const angleLineEmptyColor = named('angleLineEmptyColor', (ctx) => (ctx.index === 1 ? '' : 'black'));

/** A tick callback with a unit. */
const tickUnit = named('tickUnit', (value) => value + ' u');

/** An inline plugin hook that hides the data indices 1 and 3. */
const hideOneAndThree = named('hideOneAndThree', (chart) => {
  chart.toggleDataVisibility(1);
  chart.toggleDataVisibility(3);
});

/** A tick callback with two lines: an array label. */
const tickLines = named('tickLines', (value) => [value, 'x']);

/** A scriptable point label font: the size by the index of the context. */
const pointLabelFontByIndex = named('pointLabelFontByIndex', (ctx) => ({size: 8 + ctx.index * 2}));

/**
 * A scriptable `grid.circular`: true for the even tick indices. The context
 * of the scale has no index: there it gives false.
 */
const circularEven = named('circularEven', (ctx) => ctx.index % 2 === 0);

// ---------------------------------------------------------------------------
// The cases.

const extra = radialObservations;

/** A radialTest chart with [labels], one dataset of [data] and [options]. */
function radar(labels, data, options = {}) {
  return {type: 'radialTest', data: {labels, datasets: [{data}]}, options};
}

/** The labels of the cases of 3 to 12 labels: different lengths. */
const NAMES = [
  'Eating',
  'Drinking',
  'Sleeping',
  'Designing',
  'Coding',
  'Cycling',
  'Running',
  'Swimming',
  'Reading',
  'Walking',
  'Cooking',
  'Writing',
];

const cases = [];

for (let n = 3; n <= 12; n++) {
  const labels = NAMES.slice(0, n);
  const data = labels.map((_, i) => ((i * 37 + n * 11) % 90) + 5);
  cases.push(runCase(`${n} labels`, radar(labels, data), {extra}));
}

const FIVE = ['January', 'February', 'March', 'April', 'May'];
const DATA = [65, 59, 90, 81, 56];

cases.push(
  runCase(
    'centerPointLabels with 6 labels',
    radar(NAMES.slice(0, 6), [10, 20, 30, 40, 50, 60], {
      scales: {r: {pointLabels: {centerPointLabels: true}}},
    }),
    {extra},
  ),
  runCase(
    'a point label backdrop with padding',
    radar(FIVE, DATA, {
      scales: {
        r: {pointLabels: {backdropColor: 'rgba(0, 0, 255, 0.5)', backdropPadding: 4}},
      },
    }),
    {extra},
  ),
  runCase(
    'a point label backdrop with a border radius',
    radar(FIVE, DATA, {
      scales: {
        r: {
          pointLabels: {
            backdropColor: 'yellow',
            backdropPadding: {top: 1, left: 2, right: 3, bottom: 4},
            borderRadius: 4,
          },
        },
      },
    }),
    {extra},
  ),
  runCase(
    'a point label backdrop with an object border radius',
    radar(FIVE, DATA, {
      scales: {
        r: {
          pointLabels: {
            backdropColor: 'yellow',
            borderRadius: {topLeft: 3, bottomRight: 6},
          },
        },
      },
    }),
    {extra},
  ),
  runCase(
    'multi-line labels',
    radar(
      [['Eating', 'Dinner'], ['Drinking', 'Water'], 'Sleeping', ['Designing', 'Graphics', 'Now'], 'Coding'],
      DATA,
    ),
    {extra},
  ),
  runCase(
    'display auto hides the labels that overlap',
    radar(
      Array.from({length: 16}, (_, i) => `Label number ${i + 1}`),
      Array.from({length: 16}, (_, i) => (i * 13) % 50),
      {scales: {r: {pointLabels: {display: 'auto', font: {size: 14}}}}},
    ),
    {options: {canvas: {width: 300, height: 300}}, extra},
  ),
  runCase(
    'display auto with centerPointLabels',
    radar(
      Array.from({length: 12}, (_, i) => `Long label ${i + 1}`),
      Array.from({length: 12}, (_, i) => i + 1),
      {scales: {r: {pointLabels: {display: 'auto', centerPointLabels: true}}}},
    ),
    {options: {canvas: {width: 250, height: 250}}, extra},
  ),
  runCase(
    'no point labels',
    radar(FIVE, DATA, {scales: {r: {pointLabels: {display: false}}}}),
    {extra},
  ),
  runCase('a scale without display', radar(FIVE, DATA, {scales: {r: {display: false}}}), {extra}),
  runCase(
    'angle lines with a dash',
    radar(FIVE, DATA, {
      scales: {
        r: {angleLines: {color: 'red', lineWidth: 2, borderDash: [5, 5], borderDashOffset: 2}},
      },
    }),
    {extra},
  ),
  runCase(
    'angle lines without display and without width',
    radar(['A', 'B', 'C', 'D'], [1, 2, 3, 4], {
      scales: {r: {angleLines: {display: false}, grid: {lineWidth: 0}}},
    }),
    {extra},
  ),
  runCase(
    'scriptable angle line, grid and point label options',
    radar(['A', 'B', 'C', 'D', 'E'], [10, 20, 30, 40, 50], {
      scales: {
        r: {
          angleLines: {color: angleLineColor},
          grid: {color: gridColor},
          pointLabels: {color: pointLabelColor, padding: pointLabelPadding},
        },
      },
    }),
    {extra},
  ),
  runCase(
    'angle lines without width or color and a grid without color',
    radar(['A', 'B', 'C', 'D'], [1, 2, 3, 4], {
      scales: {
        r: {angleLines: {lineWidth: angleLineWidth, color: angleLineEmptyColor}, grid: {color: ''}},
      },
    }),
    {extra},
  ),
  runCase(
    'a circular grid',
    radar(FIVE, DATA, {scales: {r: {grid: {circular: true, color: 'blue', lineWidth: 2}}}}),
    {extra},
  ),
  runCase(
    'a polygon grid with a border dash',
    radar(FIVE, DATA, {
      scales: {r: {grid: {color: 'red', lineWidth: 3}, border: {dash: [4, 2], dashOffset: 1}}},
    }),
    {extra},
  ),
  runCase(
    'a circular grid without point labels',
    radar([], [], {scales: {r: {grid: {circular: true}, min: 0, max: 10}}}),
    {extra},
  ),
  runCase('a grid without display', radar(FIVE, DATA, {scales: {r: {grid: {display: false}}}}), {
    extra,
  }),
  runCase(
    'a polygon background',
    radar(FIVE, DATA, {scales: {r: {backgroundColor: 'rgba(0, 255, 0, 0.25)'}}}),
    {extra},
  ),
  runCase(
    'a circular background with offset',
    radar(FIVE, DATA, {
      scales: {r: {backgroundColor: 'pink', offset: true, grid: {circular: true}}},
    }),
    {extra},
  ),
  runCase(
    'startAngle 45',
    radar(['A', 'B', 'C', 'D', 'E', 'F'], [1, 2, 3, 4, 5, 6], {scales: {r: {startAngle: 45}}}),
    {extra},
  ),
  runCase(
    'startAngle -100',
    {
      type: 'radialTest',
      data: {labels: ['A', 'B', 'C'], datasets: [{data: [3, 1, 2]}]},
      options: {scales: {r: {startAngle: -100}}},
    },
    {extra},
  ),
  runCase(
    'a string startAngle',
    radar(['A', 'B', 'C', 'D'], [3, 1, 2, 4], {scales: {r: {startAngle: '30'}}}),
    {extra},
  ),
  runCase('reverse', radar(FIVE, DATA, {scales: {r: {reverse: true}}}), {extra}),
  runCase(
    'reverse with negative data',
    radar(FIVE, [-20, 30, -10, 50, 0], {scales: {r: {reverse: true}}}),
    {extra},
  ),
  runCase('negative data', radar(FIVE, [-20, 30, -10, 50, 0]), {extra}),
  runCase('min and max', radar(FIVE, DATA, {scales: {r: {min: 20, max: 100}}}), {extra}),
  runCase(
    'beginAtZero with suggestedMax',
    radar(FIVE, DATA, {scales: {r: {beginAtZero: true, suggestedMax: 120}}}),
    {extra},
  ),
  runCase(
    'suggestedMin, grace and stepSize',
    radar(FIVE, DATA, {
      scales: {r: {suggestedMin: 10, grace: '10%', ticks: {stepSize: 15}}},
    }),
    {extra},
  ),
  runCase(
    'count, precision and maxTicksLimit',
    radar(FIVE, [0.5, 1.25, 2.75, 1.5, 2], {
      scales: {r: {ticks: {count: 4, precision: 1, maxTicksLimit: 3}}},
    }),
    {extra},
  ),
  runCase(
    'maxTicksLimit and includeBounds false',
    radar(FIVE, DATA, {scales: {r: {min: 3, max: 97, ticks: {maxTicksLimit: 4, includeBounds: false}}}}),
    {extra},
  ),
  runCase('equal data', radar(['A', 'B', 'C'], [7, 7, 7]), {extra}),
  runCase(
    'a tick backdrop and a text stroke',
    radar(FIVE, DATA, {
      scales: {
        r: {
          ticks: {
            backdropColor: 'yellow',
            backdropPadding: {x: 4, y: 1},
            color: 'blue',
            textStrokeColor: 'red',
            textStrokeWidth: 2,
            font: {size: 14, weight: 'bold'},
          },
        },
      },
    }),
    {extra},
  ),
  runCase(
    'no tick backdrop and a tick callback',
    radar(FIVE, DATA, {
      scales: {r: {ticks: {showLabelBackdrop: false, callback: tickUnit, font: {size: 9}}}},
    }),
    {extra},
  ),
  runCase('no ticks', radar(FIVE, DATA, {scales: {r: {ticks: {display: false}}}}), {extra}),
  runCase('a null tick font', radar(FIVE, DATA, {scales: {r: {ticks: {font: null}}}}), {extra}),
  runCase(
    'stepSize 1 on a small canvas',
    radar(FIVE, [3, 41, 17, 29, 8], {scales: {r: {ticks: {stepSize: 1}}}}),
    {options: {canvas: {width: 200, height: 200}}, extra},
  ),
  runCase(
    'stepSize 1 without autoSkip on a small canvas',
    radar(FIVE, [3, 21, 17, 9, 8], {scales: {r: {ticks: {stepSize: 1, autoSkip: false}}}}),
    {options: {canvas: {width: 200, height: 200}}, extra},
  ),
  runCase('bounds data', radar(FIVE, [3, 41, 17, 29, 8], {scales: {r: {bounds: 'data'}}}), {
    extra,
  }),
  runCase(
    'point label font, color and padding',
    radar(FIVE, DATA, {
      scales: {
        r: {pointLabels: {font: {size: 14, weight: 'bold'}, color: 'green', padding: 10}},
      },
    }),
    {extra},
  ),
  runCase(
    'a point label callback',
    radar(['Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta'], [1, 2, 3, 4, 5, 6], {
      scales: {r: {pointLabels: {callback: pointLabelCallback}}},
    }),
    {extra},
  ),
  runCase(
    'hidden data indices',
    {
      type: 'radialTest',
      data: {labels: FIVE, datasets: [{data: DATA}]},
      plugins: [{id: 'hideData', beforeInit: hideOneAndThree}],
    },
    {extra},
  ),
  runCase(
    'a hidden dataset',
    {
      type: 'radialTest',
      data: {
        labels: ['A', 'B', 'C', 'D'],
        datasets: [{hidden: true, data: [-500, 500, 0, 1000]}, {data: [3, 9, 6, 12]}],
      },
    },
    {extra},
  ),
  runCase('empty data', radar([], []), {extra}),
  runCase('labels without data', radar(['A', 'B', 'C'], []), {extra}),
  runCase(
    'null, undefined, NaN and string data',
    radar(['A', 'B', 'C', 'D', 'E', 'F'], [65, null, 90, NaN, undefined, '70']),
    {extra},
  ),
  runCase(
    'the labels option of the scale',
    {
      type: 'radialTest',
      data: {labels: ['a', 'b'], yLabels: ['y1', 'y2', 'y3'], datasets: [{data: [1, 2, 3, 4]}]},
      options: {scales: {r: {labels: ['P', 'Q', 'R', 'S']}}},
    },
    {extra},
  ),
  runCase(
    'the yLabels of the data',
    {
      type: 'radialTest',
      data: {labels: ['a', 'b'], yLabels: ['y1', 'y2', 'y3'], datasets: [{data: [1, 2, 3]}]},
    },
    {extra},
  ),
  runCase('a wide canvas', radar(FIVE, DATA), {
    options: {canvas: {width: 400, height: 250}},
    extra,
  }),
  runCase('a tall canvas', radar(NAMES.slice(0, 7), [1, 5, 2, 6, 3, 7, 4]), {
    options: {canvas: {width: 220, height: 400}},
    extra,
  }),
);

// The cases of the fidelity review. The first three pin the JS `+` of a raw
// option value (scale.radialLinear.js:14, :95, :142): a string or an array
// joins the number as a string.
cases.push(
  runCase(
    'a string tick font size',
    radar(FIVE, DATA, {scales: {r: {ticks: {font: {size: '12'}}}}}),
    {extra},
  ),
  runCase(
    'an array tick font size',
    radar(FIVE, DATA, {scales: {r: {ticks: {font: {size: [12]}}}}}),
    {extra},
  ),
  runCase(
    'a string point label padding',
    radar(FIVE, DATA, {scales: {r: {pointLabels: {padding: '5'}}}}),
    {extra},
  ),
  runCase(
    'an indexable point label padding',
    radar(FIVE, DATA, {scales: {r: {pointLabels: {padding: [5, 15]}}}}),
    {extra},
  ),
  runCase(
    'a scriptable point label font',
    radar(FIVE, DATA, {scales: {r: {pointLabels: {font: pointLabelFontByIndex}}}}),
    {extra},
  ),
  runCase('two-line tick labels', radar(FIVE, DATA, {scales: {r: {ticks: {callback: tickLines}}}}), {
    extra,
  }),
  runCase(
    'a scriptable circular grid with a background',
    radar(FIVE, DATA, {scales: {r: {backgroundColor: 'pink', grid: {circular: circularEven}}}}),
    {extra},
  ),
  runCase(
    'a polygon background without labels',
    radar([], [], {scales: {r: {backgroundColor: 'pink', min: 0, max: 10}}}),
    {extra},
  ),
  runCase(
    'a negative drawing area with ticks',
    radar(FIVE, DATA, {scales: {r: {ticks: {stepSize: 10, autoSkip: false}}}}),
    {options: {canvas: {width: 12, height: 12}}, extra},
  ),
  runCase('display auto', radar(FIVE, DATA, {scales: {r: {display: 'auto'}}}), {extra}),
  runCase(
    'display auto with a hidden dataset',
    {
      type: 'radialTest',
      data: {labels: FIVE, datasets: [{hidden: true, data: DATA}]},
      options: {scales: {r: {display: 'auto'}}},
    },
    {extra},
  ),
  runCase(
    'falsy labels',
    radar([0, '', undefined, null, NaN, false], [10, 5, 0, 25, 78, 20]),
    {extra},
  ),
  runCase(
    'a null point label callback',
    radar(FIVE, DATA, {scales: {r: {pointLabels: {callback: null}}}}),
    {extra},
  ),
  runCase('one label', radar(['Only'], [5]), {extra}),
  runCase('two labels', radar(['Left', 'Right'], [5, 9]), {extra}),
  runCase(
    'startAngle just below 0',
    radar(['A', 'B', 'C', 'D'], [1, 2, 3, 4], {scales: {r: {startAngle: -0.0001}}}),
    {extra},
  ),
  runCase(
    'startAngle 750 without ticks',
    radar(FIVE, DATA, {scales: {r: {startAngle: 750, ticks: {display: false}}}}),
    {extra},
  ),
  runCase(
    'a startAngle that is not a number',
    radar(['A', 'B', 'C'], [1, 2, 3], {scales: {r: {startAngle: 'abc'}}}),
    {extra},
  ),
  runCase('position left', radar(FIVE, DATA, {scales: {r: {position: 'left'}}}), {extra}),
  runCase(
    'position bottom with xLabels',
    {
      type: 'radialTest',
      data: {
        labels: ['a', 'b', 'c'],
        xLabels: ['x1', 'x2', 'x3', 'x4'],
        datasets: [{data: [1, 2, 3, 4]}],
      },
      options: {scales: {r: {position: 'bottom'}}},
    },
    {extra},
  ),
  runCase(
    'a scale id rScale without datasets',
    {type: 'radialTest', data: {datasets: [], labels: []}, options: {scales: {rScale: {}}}},
    {extra},
  ),
);

writeReference(OUT, 'scaleRadialLinear', cases, {title: 'radial linear scale'});
