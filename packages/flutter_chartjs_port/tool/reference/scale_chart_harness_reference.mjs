// Original code, not ported from Chart.js: harness reference generator.
//
// It writes test/port/scales/scale_chart_harness_reference.dart, the data of
// test/port/scales/scale_chart_harness_test.dart: the self-test of the
// method of tool/reference/scale_chart_common.mjs (see its header for the
// method, the usage and the limits). No phase 6 scale is ported yet. Thus
// the charts use test scales, subclasses of Scale of the dist:
// `harnessLinear` on both axes of the cartesian test controller
// `harnessTest`, `harnessMeasure` (a measure with no font write, as in the
// time scale) and `harnessRadial` on the axis r of the radial test
// controller `harnessRadialTest`. The Dart test has the same scales on
// lib/src/core/core.scale.dart.
//
// For each case, the script records the chart area, each scale (type, min,
// max, ticks, box, label rotation, paddings, the pixel mapping), the points
// and the calls of one draw. It also records the width of each text that the
// mock measured, and of a few more texts in other fonts. The cases are
// fixed, so a rerun on the same Node.js and dist writes the same file.
//
// Usage, from packages/flutter_chartjs_port, with the darwin-arm64 build of
// Node.js v24.22.1 (Chart.js ADR 0045):
//
//   node tool/reference/scale_chart_harness_reference.mjs \
//     <build>/dist/chart.js
//
// or with the environment variable CHARTJS_DIST.

import {fileURLToPath} from 'node:url';

import {
  LiberationContext,
  cartesianTestController,
  loadChartJs,
  named,
  radialTestController,
  registerBuiltins,
  runCase,
  writeReference,
} from './scale_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/scales/scale_chart_harness_reference.dart', import.meta.url),
);

const C = await loadChartJs();

/**
 * The test scale `harnessLinear`: the range of the data (getMinMax), five
 * ticks at equal steps from min to max, and a linear mapping.
 */
class HarnessLinearScale extends C.Scale {
  static id = 'harnessLinear';
  static defaults = {};

  determineDataLimits() {
    const {min, max} = this.getMinMax(false);
    this.min = min;
    this.max = max;
  }

  buildTicks() {
    const ticks = [];
    for (let i = 0; i <= 4; i++) {
      ticks.push({value: this.min + ((this.max - this.min) * i) / 4});
    }
    return ticks;
  }

  getPixelForValue(value) {
    return this.getPixelForDecimal((value - this.min) / (this.max - this.min));
  }

  getValueForPixel(pixel) {
    return this.min + this.getDecimalForPixel(pixel) * (this.max - this.min);
  }
}

/**
 * The test scale `harnessMeasure`: harnessLinear, and in buildTicks a
 * measure of the text 'January' with no font write, as `_getLabelSize` of
 * the time scale (scale.time.js:591-593). The measure takes the current
 * font of the context: the first font of the canvas, or the last tick font
 * of the layout. Before the measure, a save, a font write and a restore
 * must leave that font. The observation `measures` gives the widths of the
 * measures, in order.
 */
class HarnessMeasureScale extends HarnessLinearScale {
  static id = 'harnessMeasure';
  static defaults = {};

  measures = [];

  buildTicks() {
    const ctx = this.ctx;
    ctx.save();
    ctx.font = 'normal bold 20px Arial';
    ctx.restore();
    this.measures.push(ctx.measureText('January').width);
    return super.buildTicks();
  }
}

/** The observation `measures` of a harnessMeasure scale. */
const measures = (scale) =>
  scale instanceof HarnessMeasureScale ? {measures: scale.measures} : {};

/**
 * The test scale `harnessRadial` for the axis r: the range of the data, the
 * ticks min and max, and a point position that depends on the box, the
 * index and the value. Its options have `display: false`: the base class
 * has no drawing for the position `chartArea`.
 */
class HarnessRadialScale extends C.Scale {
  static id = 'harnessRadial';
  static defaults = {display: false};

  determineDataLimits() {
    const {min, max} = this.getMinMax(false);
    this.min = min;
    this.max = max;
  }

  buildTicks() {
    return [{value: this.min}, {value: this.max}];
  }

  getPointPositionForValue(index, value) {
    return {x: this.left + value, y: this.top + 10 * index, angle: index / 2};
  }
}

/** The cartesian test controller with `harnessLinear` on both axes. */
const HarnessTestController = cartesianTestController('harnessTest', {
  scales: {_index_: {type: 'harnessLinear'}, _value_: {type: 'harnessLinear'}},
});

/** The radial test controller with `harnessRadial` on the axis r. */
const HarnessRadialTestController = radialTestController('harnessRadialTest', {
  aspectRatio: 1,
  scales: {r: {type: 'harnessRadial'}},
});

registerBuiltins(
  C,
  HarnessLinearScale,
  HarnessMeasureScale,
  HarnessRadialScale,
  HarnessTestController,
  HarnessRadialTestController,
);

/** The tick callback `withUnit`: the value and the unit kg. */
const withUnit = named('withUnit', (value) => value + ' kg');

const cases = [
  runCase('short and long labels', {
    type: 'harnessTest',
    data: {
      datasets: [
        {
          data: [
            {x: -1234.5, y: 0.001},
            {x: 98765, y: 12.75},
            {x: 3, y: 7},
          ],
        },
      ],
    },
  }),
  runCase('a bold title and a bold tick font', {
    type: 'harnessTest',
    data: {
      datasets: [
        {
          data: [
            {x: 0, y: 11},
            {x: 50, y: 111},
          ],
        },
      ],
    },
    options: {
      scales: {
        x: {title: {display: true, text: 'Total revenue (USD)', font: {weight: 'bold'}}},
        y: {
          title: {display: true, text: 'Average', font: {size: 14}},
          ticks: {font: {weight: 'bold', size: 13}},
        },
      },
    },
  }),
  runCase(
    'rotated labels on a narrow canvas',
    {
      type: 'harnessTest',
      data: {
        datasets: [
          {
            data: [
              {x: 1000000.125, y: 1},
              {x: 9999999.5, y: 2},
            ],
          },
        ],
      },
      options: {scales: {x: {ticks: {autoSkip: false}}}},
    },
    {options: {canvas: {width: 200, height: 300}}},
  ),
  runCase('a reversed axis at the right and an axis at the top', {
    type: 'harnessTest',
    data: {
      datasets: [
        {
          data: [
            {x: 2, y: -40},
            {x: 18, y: 260},
          ],
        },
      ],
    },
    options: {
      scales: {
        x: {position: 'top', ticks: {font: {size: 15}}},
        y: {position: 'right', reverse: true},
      },
    },
  }),
  runCase('a hidden dataset', {
    type: 'harnessTest',
    data: {
      datasets: [
        {
          hidden: true,
          data: [
            {x: -5000, y: -5000},
            {x: 5000, y: 5000},
          ],
        },
        {
          data: [
            {x: 1, y: 10},
            {x: 4, y: 30},
          ],
        },
      ],
    },
  }),
  runCase('a tick callback with a unit', {
    type: 'harnessTest',
    data: {
      datasets: [
        {
          data: [
            {x: 0.5, y: 1.25},
            {x: 2.5, y: 6.25},
          ],
        },
      ],
    },
    options: {scales: {y: {ticks: {callback: withUnit}}}},
  }),
  runCase(
    'measures with no font write',
    {
      type: 'harnessTest',
      data: {
        datasets: [
          {
            data: [
              {x: 3, y: 8},
              {x: 7, y: 1250},
            ],
          },
        ],
      },
      options: {
        scales: {
          x: {type: 'harnessMeasure', ticks: {font: {size: 9}}},
          y: {type: 'harnessMeasure', ticks: {font: {weight: 'bold', size: 13}}},
        },
      },
    },
    {extra: measures},
  ),
  runCase('the radial test controller', {
    type: 'harnessRadialTest',
    data: {labels: ['a', 'b', 'c', 'd'], datasets: [{data: [65, 59, 90, 81]}]},
  }),
];

// More texts for the width group of the Dart test: kerned pairs, other
// sizes and weights (the faces of fontFace at the ends of their ranges),
// and the first font of a canvas.
const family = "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif";
const ctx = new LiberationContext();
ctx.measureText('AVAWAY Total revenue (USD)');
for (const font of [
  `normal 12px ${family}`,
  `normal bold 12px ${family}`,
  `normal 600 16px ${family}`,
  `normal 500 9px ${family}`,
  `normal 100 12px ${family}`,
  `normal 550 12px ${family}`,
  `normal 1000 12px ${family}`,
  `bold 20px Arial`,
  `13px 'Liberation Sans'`,
]) {
  ctx.font = font;
  for (const text of ['AVAWAY Total revenue (USD)', 'Te Yo LT P. F, 11 1111', 'January']) {
    ctx.measureText(text);
  }
}

writeReference(OUT, 'scaleChartHarness', cases, {title: 'scale chart harness'});
