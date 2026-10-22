// Original code, not ported from Chart.js: timeseries scale reference generator.
//
// It writes test/port/scales/scale_timeseries_reference.dart, the data of
// test/port/scales/scale.timeseries_test.dart: real charts with the
// timeseries scale of a build of the pinned Chart.js and the date adapter of
// the specs (see the headers of tool/reference/scale_chart_common.mjs and
// tool/reference/scale_time_common.mjs for the method, the usage and the
// limits). Chart.js has no spec file for the timeseries scale.
//
// The cartesian test controller `timeseriesTest` has the timeseries scale
// on the index axis and the linear scale on the value axis. For each case,
// the script records the chart area, each scale (type, min, max, ticks,
// box, label rotation, paddings, the pixel mapping), the points and the
// calls of one draw. For a timeseries scale, the observations have the time
// observations of scale_time_common.mjs and the lookup table
// (timeseriesObservations).
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//   MOMENT_NODE_MODULES=<scratch>/node_modules \
//     node tool/reference/scale_timeseries_reference.mjs

import {fileURLToPath} from 'node:url';

import {
  cartesianTestController,
  loadChartJs,
  named,
  registerPhase6,
  runCase,
  writeReference,
} from './scale_chart_common.mjs';
import {appendAdapterInfo, loadMomentAdapter, timeObservations} from './scale_time_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/scales/scale_timeseries_reference.dart', import.meta.url),
);

const C = await loadChartJs();
await loadMomentAdapter(C);

/** The cartesian test controller: timeseries on the index axis. */
const TimeseriesTestController = cartesianTestController('timeseriesTest', {
  scales: {_index_: {type: 'timeseries'}, _value_: {type: 'linear'}},
});

registerPhase6(C, TimeseriesTestController);

const timeExtra = timeObservations(C);

/**
 * The observations of a timeseries scale [s], after the time observations.
 * The Dart test gives the same keys with the same calls. A scale of another
 * type gives none.
 *
 * - `dataTable`, `labelTable`: `[time, pos]` of each entry of
 *   buildLookupTable() of the data timestamps and of the label timestamps.
 *   `_table` stays private in the port (Chart.js ADR 0025, section 6).
 * - `decimalForData`: getDecimalForValue of each data timestamp.
 * - `valuesAlongAxis`: getValueForPixel at 0, 0.1, ..., 1 of the length of
 *   the axis.
 */
function timeseriesObservations(s) {
  if (!(s instanceof C.TimeSeriesScale)) return {};
  const horizontal = s.isHorizontal();
  const start = horizontal ? s.left : s.top;
  const end = horizontal ? s.right : s.bottom;
  const table = (timestamps) => s.buildLookupTable(timestamps).map((e) => [e.time, e.pos]);
  return {
    dataTable: table(s.getDataTimestamps()),
    labelTable: table(s.getLabelTimestamps()),
    decimalForData: s.getDataTimestamps().map((t) => s.getDecimalForValue(t)),
    valuesAlongAxis: Array.from({length: 11}, (_, i) =>
      s.getValueForPixel(start + (i / 10) * (end - start)),
    ),
  };
}

const extra = (s, chart) => ({...timeExtra(s, chart), ...timeseriesObservations(s)});

const HOUR = 3600000;
const DAY = 24 * HOUR;

/** Monday 2021-01-04T00:00:00Z. */
const T0 = Date.UTC(2021, 0, 4);

/** The value of the point [i]: a fixed pattern from 0 to 10. */
const valueAt = (i) => (i * 37) % 11;

/** `{x, y}` points at the times [times]. */
const xy = (times) => times.map((x, i) => ({x, y: valueAt(i)}));

/** [n] times from [start], [step] ms apart. */
const range = (start, step, n) => Array.from({length: n}, (_, i) => start + i * step);

/** Times with gaps of 1, 1, 7, 1, 30, 1 and 59 days. */
const irregular = [0, 1, 2, 9, 10, 40, 41, 100].map((d) => T0 + d * DAY);

/** 60 times with gaps of 1 to 9 days. */
const many = Array.from({length: 60}, (_, i) => T0 + (i * (i + 7)) % 9 * DAY + i * 3 * DAY);

/** The ISO date of [t]: YYYY-MM-DD. */
const isoDate = (t) => new Date(t).toISOString().slice(0, 10);

/** The tick callback `tickIndex`: `'T'` and the index of the tick. */
const tickIndex = named('tickIndex', (value, index) => 'T' + index);

/** A case of the timeseries test controller with the observations. */
const chartCase = (name, config, options = {}) =>
  runCase(name, {type: 'timeseriesTest', ...config}, {options, extra});

const cases = [
  chartCase('irregular data', {data: {datasets: [{data: xy(irregular)}]}}),
  chartCase('ISO date labels and primitive data', {
    data: {labels: irregular.map(isoDate), datasets: [{data: irregular.map((_, i) => valueAt(i))}]},
  }),
  chartCase('regular data', {data: {datasets: [{data: xy(range(T0, DAY, 10))}]}}),
  chartCase('offset', {
    data: {datasets: [{data: xy(irregular)}]},
    options: {scales: {x: {offset: true}}},
  }),
  chartCase('reverse', {
    data: {datasets: [{data: xy(irregular)}]},
    options: {scales: {x: {reverse: true}}},
  }),
  chartCase('ticks source data', {
    data: {datasets: [{data: xy(irregular)}]},
    options: {scales: {x: {ticks: {source: 'data'}}}},
  }),
  chartCase('ticks source labels', {
    data: {
      labels: ['2021-01-05', '2021-01-20', '2021-03-01'],
      datasets: [{data: xy(irregular)}],
    },
    options: {scales: {x: {ticks: {source: 'labels'}}}},
  }),
  chartCase('bounds ticks', {
    data: {datasets: [{data: xy(irregular.map((t) => t + 5 * HOUR))}]},
    options: {scales: {x: {bounds: 'ticks'}}},
  }),
  chartCase('min and max inside the data', {
    data: {datasets: [{data: xy(irregular)}]},
    options: {scales: {x: {min: T0 + 2 * DAY, max: '2021-02-14'}}},
  }),
  chartCase('min and max outside the data', {
    data: {datasets: [{data: xy(irregular)}]},
    options: {scales: {x: {min: '2020-12-01', max: T0 + 120 * DAY}}},
  }),
  chartCase('one data point', {data: {datasets: [{data: xy([T0 + 7 * HOUR])}]}}),
  chartCase('no data', {data: {datasets: [{data: []}]}}),
  chartCase('two datasets', {
    data: {
      datasets: [
        {data: xy(irregular)},
        {data: xy([T0 + 5 * DAY, T0 + 9 * DAY, T0 + 70 * DAY])},
      ],
    },
  }),
  chartCase('a hidden dataset', {
    data: {
      datasets: [
        {data: xy(irregular)},
        {data: xy([T0 + 5 * DAY, T0 + 70 * DAY, T0 + 200 * DAY]), hidden: true},
      ],
    },
  }),
  chartCase('the fixed unit day', {
    data: {datasets: [{data: xy(irregular)}]},
    options: {scales: {x: {time: {unit: 'day'}}}},
  }),
  chartCase('a narrow canvas with many points', {data: {datasets: [{data: xy(many)}]}}, {
    canvas: {width: 200, height: 240},
  }),
  chartCase('a vertical axis', {
    data: {datasets: [{data: xy(irregular)}]},
    options: {indexAxis: 'y'},
  }),
  chartCase('major ticks', {
    data: {datasets: [{data: xy(many)}]},
    options: {scales: {x: {ticks: {major: {enabled: true}}}}},
  }),
  chartCase('offset and offsetAfterAutoskip', {
    data: {datasets: [{data: xy(many)}]},
    options: {scales: {x: {offset: true, offsetAfterAutoskip: true}}},
  }),
  chartCase('normalized data', {
    data: {datasets: [{data: xy(irregular)}, {data: xy([T0 + 5 * DAY, T0 + 300 * DAY])}]},
    options: {normalized: true},
  }),
  chartCase('labels and data together', {
    data: {
      labels: ['2021-01-07', '2021-01-20'],
      datasets: [{data: xy(irregular)}],
    },
  }),
  chartCase('null and invalid x values', {
    data: {
      datasets: [
        {
          data: [
            {x: T0, y: 1},
            {x: null, y: 2},
            {x: 'garbage', y: 3},
            {x: T0 + 3 * DAY, y: 4},
            {x: T0 + 30 * DAY, y: 5},
          ],
        },
      ],
    },
  }),
  chartCase('labels only, reversed in place', {
    data: {labels: irregular.map(isoDate), datasets: []},
    options: {
      scales: {
        x: {
          bounds: 'ticks',
          offset: true,
          offsetAfterAutoskip: true,
          reverse: true,
          ticks: {source: 'labels'},
        },
      },
    },
  }),
  chartCase('a label that does not parse', {
    data: {labels: ['2021-01-04', 'garbage', '2021-01-20'], datasets: [{data: [1, 2, 3]}]},
  }),
  // The tick of the label that does not parse has the value null
  // (differences.md row adapt-time-null-timestamp). getDecimalForValue reads
  // null as 0: the pixel of the tick is finite, and so is the left padding.
  chartCase('ticks source labels and a label that does not parse', {
    data: {labels: ['2021-01-04', 'garbage', '2021-01-20'], datasets: [{data: [1, 2, 3]}]},
    options: {scales: {x: {ticks: {source: 'labels'}}}},
  }),
  chartCase('ticks source labels, {x, y} data and a label that does not parse', {
    data: {
      labels: ['2021-01-04', 'garbage', '2021-01-20'],
      datasets: [{data: xy([T0, T0 + 3 * DAY, T0 + 16 * DAY])}],
    },
    options: {scales: {x: {ticks: {source: 'labels'}}}},
  }),
  chartCase('bounds ticks with a min', {
    data: {datasets: [{data: xy(irregular.map((t) => t + 5 * HOUR))}]},
    options: {scales: {x: {bounds: 'ticks', min: T0 + 30 * HOUR}}},
  }),
  chartCase('reverse and offsetAfterAutoskip on the data cache', {
    data: {datasets: [{data: xy(irregular)}]},
    options: {scales: {x: {reverse: true, offset: true, offsetAfterAutoskip: true}}},
  }),
  chartCase('ticks source data, offset and labels', {
    data: {labels: ['2021-01-07', '2021-03-01'], datasets: [{data: xy(irregular)}]},
    options: {scales: {x: {offset: true, ticks: {source: 'data'}}}},
  }),
  chartCase('normalized labels with ticks source labels', {
    data: {
      labels: ['2021-01-20', '2021-01-04', '2021-01-04', '2021-01-11', '2021-03-01'],
      datasets: [{data: [1, 2, 3, 4, 5]}],
    },
    options: {normalized: true, scales: {x: {ticks: {source: 'labels'}}}},
  }),
  chartCase('a vertical axis on the right with reverse', {
    data: {datasets: [{data: xy(many)}]},
    options: {indexAxis: 'y', scales: {y: {position: 'right', reverse: true}}},
  }),
  chartCase('a time axis on top with a tick callback', {
    data: {datasets: [{data: xy(irregular)}]},
    options: {scales: {x: {position: 'top', ticks: {callback: tickIndex}}}},
  }),
  chartCase('suggestedMin and suggestedMax outside the data', {
    data: {datasets: [{data: xy(irregular)}]},
    options: {scales: {x: {suggestedMin: '2020-12-20', suggestedMax: T0 + 130 * DAY}}},
  }),
  chartCase('min and max between two data points', {
    data: {datasets: [{data: xy(irregular)}]},
    options: {scales: {x: {min: T0 + 5 * DAY, max: T0 + 6 * DAY}}},
  }),
  chartCase('offset with a min inside the data: the start and end offsets differ', {
    data: {datasets: [{data: xy(irregular)}]},
    options: {scales: {x: {offset: true, min: T0 + 5 * DAY}}},
  }),
  chartCase('NaN and null x values with primitive data on labels', {
    data: {
      labels: ['2021-01-04', '2021-01-05', '2021-01-09', '2021-02-01'],
      datasets: [{data: [1, null, NaN, 4]}],
    },
  }),
];

writeReference(OUT, 'scaleTimeseries', cases, {title: 'timeseries scale'});
appendAdapterInfo(OUT, 'scaleTimeseries');
