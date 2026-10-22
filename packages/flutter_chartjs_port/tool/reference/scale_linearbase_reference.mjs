// Original code, not ported from Chart.js: linear scale base reference generator.
//
// It writes test/port/scales/scale_linearbase_reference.dart, the data of
// test/port/scales/scale.linearbase_test.dart: real charts of a build
// of the pinned Chart.js with test scales that extend LinearScaleBase (see
// the header of tool/reference/scale_chart_common.mjs for the method, the
// usage and the limits).
//
// The dist does not export LinearScaleBase. The class is the prototype of
// LinearScale: Object.getPrototypeOf(C.LinearScale). The test scales are:
// - `testLinearBase`: the determineDataLimits, getPixelForValue and
//   getValueForPixel of the linear scale (scale.linear.js:20-50), the tick
//   callback `Ticks.formatters.numeric`, and computeTickLimit of
//   LinearScaleBase (Infinity).
// - `testLinearBaseLimit`: testLinearBase with the computeTickLimit of the
//   linear scale (scale.linear.js:34-41), a limit from the size of the axis.
// The cartesian test controller `linearBaseChart` puts testLinearBase on
// both axes. The Dart test has the same classes on
// lib/src/scales/scale.linearbase.dart.
//
// For each case, the script records the observations of `observe` and the
// calls of one draw, and for each scale: start, end, _startValue, _endValue,
// _valueRange, getTickLimit(), the labels of getLabelForValue for a few
// values, the results of parse for a list of JS values, and the warnings of
// console.warn that name the scale, each as the list of its words.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   node tool/reference/scale_linearbase_reference.mjs \
//     <build>/dist/chart.js
//
// or with the environment variable CHARTJS_DIST.

import {fileURLToPath} from 'node:url';

import {
  cartesianTestController,
  loadChartJs,
  named,
  registerPhase6,
  runCase,
  writeReference,
} from './scale_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/scales/scale_linearbase_reference.dart', import.meta.url),
);

const C = await loadChartJs();

/** LinearScaleBase of the dist: the dist does not export it. */
const LinearScaleBase = Object.getPrototypeOf(C.LinearScale);
if (LinearScaleBase.name !== 'LinearScaleBase') {
  throw new Error(`The prototype of LinearScale is ${LinearScaleBase.name}.`);
}

/**
 * The test scale `testLinearBase`: LinearScaleBase with the data limits and
 * the pixel mapping of the linear scale.
 */
class TestLinearBaseScale extends LinearScaleBase {
  static id = 'testLinearBase';
  static defaults = {ticks: {callback: C.Ticks.formatters.numeric}};

  determineDataLimits() {
    const {min, max} = this.getMinMax(true);
    this.min = Number.isFinite(min) ? min : 0;
    this.max = Number.isFinite(max) ? max : 1;
    this.handleTickRangeOptions();
  }

  getPixelForValue(value) {
    return value === null
      ? NaN
      : this.getPixelForDecimal((value - this._startValue) / this._valueRange);
  }

  getValueForPixel(pixel) {
    return this._startValue + this.getDecimalForPixel(pixel) * this._valueRange;
  }
}

/**
 * The test scale `testLinearBaseLimit`: testLinearBase with the
 * computeTickLimit of the linear scale.
 */
class TestLinearBaseLimitScale extends TestLinearBaseScale {
  static id = 'testLinearBaseLimit';
  static defaults = {};

  computeTickLimit() {
    const horizontal = this.isHorizontal();
    const length = horizontal ? this.width : this.height;
    const minRotation = this.options.ticks.minRotation * (Math.PI / 180);
    const ratio = (horizontal ? Math.sin(minRotation) : Math.cos(minRotation)) || 0.001;
    const tickFont = this._resolveTickFontOptions(0);
    return Math.ceil(length / Math.min(40, tickFont.lineHeight / ratio));
  }
}

/** The cartesian test controller with testLinearBase on both axes. */
const LinearBaseChartController = cartesianTestController('linearBaseChart', {
  scales: {_index_: {type: 'testLinearBase'}, _value_: {type: 'testLinearBase'}},
});

registerPhase6(C, TestLinearBaseScale, TestLinearBaseLimitScale, LinearBaseChartController);

/** The messages of console.warn of the current case. */
const warnings = [];
console.warn = (...args) => {
  warnings.push(args.map(String).join(' '));
};

/** The values of the observation `labels` (getLabelForValue). */
// No undefined: package:intl writes the NaN of the percent style without the
// percent sign.
const labelValues = (s) => [s.min, s.max, 1234.5, -0.000125, 98765.4321, null, '7.5', true];

/** The values of the observation `parsed` (parse). */
const parseValues = [
  null,
  undefined,
  NaN,
  Infinity,
  -Infinity,
  12,
  -0,
  '12.5',
  ' 0x1A ',
  'Infinity',
  'abc',
  '',
  true,
  false,
  [7],
  {},
];

/** The observations of a test scale, after the layout. */
const extra = (s) => ({
  // Each warning as its words: a Dart line has at most 80 characters.
  warnings: warnings.filter((w) => w.startsWith(`scales.${s.id}.`)).map((w) => w.split(' ')),
  start: s.start,
  end: s.end,
  startValue: s._startValue,
  endValue: s._endValue,
  valueRange: s._valueRange,
  tickLimit: s.getTickLimit(),
  labels: labelValues(s).map((v) => s.getLabelForValue(v)),
  parsed: parseValues.map((v) => s.parse(v, 0)),
});

/** runCase with a new list of warnings and the observations of extra. */
function run(name, config, options) {
  warnings.length = 0;
  return runCase(name, config, {options, extra});
}

/** A chart of the test controller with the datasets [datasets]. */
const chart = (datasets, options, labels) => ({
  type: 'linearBaseChart',
  data: labels ? {labels, datasets} : {datasets},
  ...(options ? {options} : {}),
});

/** The points of [xs] and [ys]. */
const points = (xs, ys) => xs.map((x, i) => ({x, y: ys[i]}));

const data = [{data: points([-12.5, 40, 7.25], [3, 117, -20])}];

/** The tick callback `withUnit`: the value and the unit kg. */
const withUnit = named('withUnit', (value) => value + ' kg');

const cases = [
  // The data forms.
  run('objects', chart(data)),
  run('primitives and labels', chart([{data: [10, 20, 15]}], undefined, ['1', '2.5', '4'])),
  run('primitives without labels', chart([{data: [3, 9]}])),
  run('empty data', chart([{data: []}])),
  run(
    'null, NaN and string values',
    chart([
      {
        data: [
          {x: 1, y: null},
          {x: 2, y: NaN},
          {x: null, y: 4},
          {x: 3, y: 5},
          {x: 'abc', y: 6},
          {x: '7', y: '8.5'},
        ],
      },
    ]),
  ),
  run(
    'a hidden dataset',
    chart([
      {hidden: true, data: points([-5000, 5000], [-5000, 5000])},
      {data: points([1, 4], [10, 30])},
    ]),
  ),

  // The range options.
  run('min and max', chart(data, {scales: {x: {min: -5, max: 55}, y: {min: 0, max: 100}}})),
  run(
    'suggestedMin and suggestedMax',
    chart(data, {scales: {x: {suggestedMax: 41}, y: {suggestedMin: -60, suggestedMax: 300}}}),
  ),
  run('grace', chart(data, {scales: {x: {grace: 3}, y: {grace: '10%'}}})),
  run(
    'beginAtZero with positive and negative data',
    chart([{data: points([10, 30], [-50, -80])}], {
      scales: {x: {beginAtZero: true}, y: {beginAtZero: true}},
    }),
  ),
  run(
    'beginAtZero with mixed data and with a user min',
    chart([{data: points([-10, 30], [50, 80])}], {
      scales: {x: {beginAtZero: true}, y: {beginAtZero: true, min: 20}},
    }),
  ),
  run(
    'beginAtZero with a user max',
    chart([{data: points([10, 30], [-50, -80])}], {
      scales: {y: {beginAtZero: true, max: -20}},
    }),
  ),
  run('one value', chart([{data: points([0, 0], [5, 5])}])),
  run(
    'one value with beginAtZero',
    chart([{data: points([0, 0], [-3, -3])}], {
      scales: {x: {beginAtZero: true}, y: {beginAtZero: true}},
    }),
  ),
  run(
    'one value with a user min',
    chart([{data: points([4, 4], [5, 5])}], {scales: {x: {min: 4}, y: {max: 5}}}),
  ),
  run(
    'all values zero with beginAtZero',
    chart([{data: points([0, 0], [0, 0])}], {scales: {y: {beginAtZero: true}}}),
  ),
  run('min only and max only', chart(data, {scales: {x: {min: -11.7}, y: {max: 99.5}}})),
  run('min above max', chart(data, {scales: {y: {min: 100, max: 0}}})),
  // A NaN bound is defined for generateTicks (isNullOrUndef), and !== and
  // === never match it.
  run('NaN bounds', chart(data, {scales: {y: {min: NaN, max: NaN}}})),
  run(
    'truthy and falsy option values',
    chart([{data: points([10, 30], [50, 80])}], {
      scales: {
        x: {beginAtZero: ''},
        y: {beginAtZero: 'yes', max: 99.5, ticks: {includeBounds: 0, format: 'abc'}},
      },
    }),
  ),

  // The tick options.
  run('stepSize', chart(data, {scales: {y: {ticks: {stepSize: 7}}}})),
  run(
    'stepSize with min and max',
    chart(data, {
      scales: {
        x: {min: 0, max: 30, ticks: {stepSize: 5}},
        y: {min: 0, max: 31, ticks: {stepSize: 5}},
      },
    }),
  ),
  run(
    'stepSize with maxTicksLimit',
    chart(data, {scales: {y: {min: 0, max: 100, ticks: {stepSize: 2, maxTicksLimit: 6}}}}),
  ),
  run(
    'stepSize over 1000 ticks',
    chart(data, {scales: {y: {ticks: {stepSize: 0.001, count: 4}}}}),
  ),
  run(
    'stepSize with maxTicksLimit 0',
    chart(data, {scales: {y: {ticks: {stepSize: 10, maxTicksLimit: 0}}}}),
  ),
  run(
    'a string stepSize with min and max',
    chart(data, {scales: {y: {min: 0, max: 100, ticks: {stepSize: '25'}}}}),
  ),
  // The spacing and the factor become NaN.
  run(
    'a negative and a NaN stepSize',
    chart(data, {scales: {x: {ticks: {stepSize: 'abc'}}, y: {ticks: {stepSize: -5}}}}),
  ),
  run('count', chart(data, {scales: {x: {ticks: {count: 4}}, y: {ticks: {count: 7}}}})),
  run(
    'count with min and max',
    chart(data, {
      scales: {x: {min: 2.5, ticks: {count: 5}}, y: {min: -3, max: 17, ticks: {count: 6}}},
    }),
  ),
  // count 1 divides by 0 spaces, and count 0 by -1.
  run('count 1 and count 0', chart(data, {scales: {x: {ticks: {count: 0}}, y: {ticks: {count: 1}}}})),
  run(
    'precision',
    chart([{data: points([0, 3], [0, 0.37])}], {
      scales: {x: {ticks: {precision: 0}}, y: {ticks: {precision: 1}}},
    }),
  ),
  run(
    'precision with count and with min and max',
    chart([{data: points([0, 3], [0, 0.37])}], {
      scales: {
        x: {ticks: {precision: 2, count: 4}},
        y: {min: 0.01, max: 0.33, ticks: {precision: 2}},
      },
    }),
  ),
  run(
    'a negative precision',
    chart(data, {scales: {x: {ticks: {precision: -1, count: 3}}, y: {ticks: {precision: -1}}}}),
  ),
  run(
    'precision with stepSize, min and max',
    chart(data, {scales: {y: {min: 0, max: 1, ticks: {stepSize: 0.25, precision: 1}}}}),
  ),
  run(
    'maxTicksLimit',
    chart(data, {scales: {x: {ticks: {maxTicksLimit: 0}}, y: {ticks: {maxTicksLimit: 4}}}}),
  ),
  run(
    'string tick options',
    chart(data, {
      scales: {
        x: {ticks: {count: '4', precision: '1'}},
        y: {ticks: {stepSize: '25', maxTicksLimit: '5'}},
      },
    }),
  ),
  run(
    'includeBounds',
    chart(data, {scales: {x: {min: -11, max: 39.9}, y: {min: -19.5, max: 99.5}}}),
  ),
  run(
    'includeBounds false',
    chart(data, {
      scales: {
        x: {min: -11, max: 39.9, ticks: {includeBounds: false}},
        y: {min: 3, max: 97, ticks: {includeBounds: false}},
      },
    }),
  ),
  run(
    'includeBounds with close ticks',
    chart(data, {scales: {x: {min: 0.2, max: 49.8}, y: {min: -20.4, max: 120.4}}}),
  ),
  run(
    'bounds data',
    chart(data, {scales: {x: {bounds: 'data'}, y: {bounds: 'data', min: -21, ticks: {count: 3}}}}),
  ),
  run('offset', chart(data, {scales: {x: {offset: true}, y: {offset: true, min: -20, max: 120}}})),
  // One tick: Math.max(ticks.length - 1, 1) is 1.
  run(
    'offset with one tick',
    chart(data, {
      scales: {y: {min: 3.1, max: 3.9, offset: true, ticks: {includeBounds: false, maxTicksLimit: 3}}},
    }),
  ),
  // No tick: configure skips the offset.
  run(
    'offset without ticks',
    chart(data, {
      scales: {y: {min: 3.1, max: 3.9, offset: true, ticks: {includeBounds: false, maxTicksLimit: 2}}},
    }),
  ),
  run('reverse', chart(data, {scales: {x: {reverse: true}, y: {reverse: true, min: 0}}})),
  run(
    'reverse with offset and bounds data',
    chart(data, {
      scales: {x: {reverse: true, offset: true}, y: {reverse: true, offset: true, bounds: 'data'}},
    }),
  ),
  run(
    'positions top and right',
    chart(data, {scales: {x: {position: 'top'}, y: {position: 'right'}}}),
  ),
  run(
    'a tiny range',
    chart([{data: points([1, 1.000000000000001], [-100, -99.99999999999999])}]),
  ),
  // A user min: generateTicks does not stop at MIN_SPACING. The numeric
  // labels would need 16 fraction digits, and package:intl gives at most 15
  // (adapt-intl-number-format): the callback withUnit writes the labels.
  run(
    'a tiny range with a user min',
    chart([{data: points([1, 1.000000000000001], [1, 2])}], {
      scales: {x: {min: 1, ticks: {callback: withUnit}}},
    }),
  ),

  // The labels.
  run('a tick callback', chart(data, {scales: {y: {ticks: {callback: withUnit}}}})),
  run(
    'locale and format',
    chart([{data: points([-1234.5, 98765.25], [0.5, 2.75])}], {
      locale: 'de-DE',
      scales: {x: {ticks: {format: {maximumFractionDigits: 1}}}},
    }),
  ),
  run(
    'percent format',
    chart([{data: points([0, 1], [0.05, 0.95])}], {
      scales: {y: {ticks: {format: {style: 'percent'}}}},
    }),
  ),

  // The tick limit of the axis size, the rotation and the skip of labels.
  run(
    'the limit scale on a narrow canvas',
    chart([{data: points([1000000.125, 9999999.5], [1, 2])}], {
      scales: {x: {type: 'testLinearBaseLimit'}, y: {type: 'testLinearBaseLimit'}},
    }),
    {canvas: {width: 200, height: 300}},
  ),
  run(
    'minRotation with bounds',
    chart([{data: points([1000000.125, 9999999.5], [1, 2])}], {
      scales: {
        x: {type: 'testLinearBaseLimit', min: 999999, max: 10000001, ticks: {minRotation: 45}},
        y: {min: 0.95, max: 2.03, ticks: {minRotation: 30}},
      },
    }),
    {canvas: {width: 300, height: 200}},
  ),
  run(
    'rotation and autoskip without a limit',
    chart([{data: points([1000000.125, 9999999.5], [1, 2])}], {
      scales: {x: {ticks: {autoSkip: true, maxRotation: 90}}},
    }),
    {canvas: {width: 200, height: 300}},
  ),
];

writeReference(OUT, 'scaleLinearBase', cases, {title: 'linear scale base'});
