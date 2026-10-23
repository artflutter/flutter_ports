// Original code, not ported from Chart.js: time scale reference generator.
//
// It writes test/port/scales/scale_time_reference.dart, the data of
// test/port/scales/scale.time_test.dart: real charts with the time scale of
// a build of the pinned Chart.js and the date adapter of the specs (see the
// headers of tool/reference/scale_chart_common.mjs and
// tool/reference/scale_time_common.mjs for the method, the usage and the
// limits).
//
// The cartesian test controller `timeTest` has the time scale on the index
// axis and the linear scale on the value axis. For each case, the script
// records the chart area, each scale (type, min, max, ticks, box, label
// rotation, paddings, the pixel mapping), the points and the calls of one
// draw. For a time scale, the observations also have the unit, the major
// unit, the offsets, the timestamp caches and the results of the value
// methods, of format and of parse (timeObservations). The case 'an adapter
// add that gives NaN' replaces `add` of the adapter during its chart; the
// Dart test does the same by the case name.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//   MOMENT_NODE_MODULES=<scratch>/node_modules \
//     node tool/reference/scale_time_reference.mjs

import {fileURLToPath} from 'node:url';

import {
  cartesianTestController,
  loadChartJs,
  named,
  registerBuiltins,
  runCase,
  writeReference,
} from './scale_chart_common.mjs';
import {appendAdapterInfo, loadMomentAdapter, timeObservations} from './scale_time_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/scales/scale_time_reference.dart', import.meta.url),
);

const C = await loadChartJs();
await loadMomentAdapter(C);

/** The cartesian test controller: time on the index axis. */
const TimeTestController = cartesianTestController('timeTest', {
  scales: {_index_: {type: 'time'}, _value_: {type: 'linear'}},
});

registerBuiltins(C, TimeTestController);

const extra = timeObservations(C);

const SECOND = 1000;
const MINUTE = 60 * SECOND;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

/** Monday 2021-01-04T00:00:00Z. */
const T0 = Date.UTC(2021, 0, 4);

/** The value of the point [i]: a fixed pattern from 0 to 10. */
const valueAt = (i) => (i * 37) % 11;

/** `{x, y}` points at the times [times]. */
const xy = (times) => times.map((x, i) => ({x, y: valueAt(i)}));

/** [n] times from [start], [step] ms apart. */
const range = (start, step, n) => Array.from({length: n}, (_, i) => start + i * step);

/** The ISO 8601 text of [t] in UTC, with the `Z` offset. */
const iso = (t) => new Date(t).toISOString();

/** A case of the time test controller with the time observations. */
const chartCase = (name, config, options = {}) =>
  runCase(name, {type: 'timeTest', ...config}, {options, extra});

/** The tick callback `tickIndex`: `'T'` and the index of the tick. */
const tickIndex = named('tickIndex', (value, index) => 'T' + index);

/**
 * The tick callback `hourOrEmpty`: the time of every other tick in the
 * format 'HH:mm' of the scale (`this`), else the empty string.
 */
const hourOrEmpty = named('hourOrEmpty', function (value, index) {
  return index % 2 ? '' : this.format(value, 'HH:mm');
});

/** The time parser `seconds`: a number of seconds to ms. */
const seconds = named('seconds', (value) => value * 1000);

/** The tick callback `valueString`: `String(value)` of the tick value. */
const valueString = named('valueString', (value) => String(value));

/** Data for an auto unit: 40 days of daily points. */
const days40 = xy(range(T0, DAY, 40));

const cases = [
  chartCase('ISO date labels and primitive data', {
    data: {
      labels: ['2021-01-04', '2021-01-11', '2021-01-18', '2021-01-25', '2021-02-01', '2021-02-08'],
      datasets: [{data: [3, 1, 4, 1, 5, 9]}],
    },
  }),
  chartCase('ISO strings in {x, y} data', {
    data: {
      datasets: [
        {
          data: [
            {x: '2021-01-04T06:00:00', y: 1},
            {x: '2021-01-05T18:30:00Z', y: 4},
            {x: '2021-01-07', y: 2},
            {x: '2021-01-09T12:00:00+02:00', y: 8},
          ],
        },
      ],
    },
  }),
  chartCase('timestamps over two days', {
    data: {datasets: [{data: xy(range(T0 + 3 * HOUR, 5 * HOUR, 10))}]},
  }),
  chartCase('ninety seconds', {
    data: {datasets: [{data: xy(range(T0 + 7 * SECOND, 10 * SECOND, 10))}]},
  }),
  chartCase('half a second', {
    data: {datasets: [{data: xy(range(T0 + 3, 50, 11))}]},
  }),
  chartCase('two hours of minutes', {
    data: {datasets: [{data: xy(range(T0 + 5 * MINUTE, 12 * MINUTE, 11))}]},
  }),
  chartCase('a year of months', {
    data: {datasets: [{data: xy(range(T0, 30 * DAY, 13))}]},
  }),
  chartCase('thirty years', {
    data: {
      datasets: [{data: xy([Date.UTC(2000, 5, 1), Date.UTC(2010, 0, 1), Date.UTC(2030, 11, 31)])}],
    },
  }),
  ...['millisecond', 'second', 'minute', 'hour', 'day', 'week', 'month', 'quarter', 'year'].map(
    (unit) => {
      const spans = {
        millisecond: [T0 + 5, 7, 12],
        second: [T0 + 900, 3 * SECOND, 12],
        minute: [T0 + 20 * SECOND, 3 * MINUTE, 12],
        hour: [T0 + 10 * MINUTE, 2 * HOUR, 12],
        day: [T0 + HOUR, 1.5 * DAY, 12],
        week: [T0 + 2 * DAY, 5 * DAY, 12],
        month: [T0 + 3 * DAY, 25 * DAY, 12],
        quarter: [T0 + 10 * DAY, 70 * DAY, 12],
        year: [T0 + 40 * DAY, 300 * DAY, 12],
      };
      const [start, step, n] = spans[unit];
      return chartCase(`the fixed unit ${unit}`, {
        data: {datasets: [{data: xy(range(start, step, n))}]},
        options: {scales: {x: {time: {unit}}}},
      });
    },
  ),
  chartCase('the unit week with isoWeekday true', {
    data: {datasets: [{data: xy(range(T0 + 2 * DAY, 5 * DAY, 12))}]},
    options: {scales: {x: {time: {unit: 'week', isoWeekday: true}}}},
  }),
  chartCase('the unit week with isoWeekday 3', {
    data: {datasets: [{data: xy(range(T0 + 2 * DAY, 5 * DAY, 12))}]},
    options: {scales: {x: {time: {unit: 'week', isoWeekday: 3}}}},
  }),
  chartCase('minUnit day on hours', {
    data: {datasets: [{data: xy(range(T0 + HOUR, 3 * HOUR, 12))}]},
    options: {scales: {x: {time: {minUnit: 'day'}}}},
  }),
  chartCase('round day', {
    data: {datasets: [{data: xy(range(T0 + 5 * HOUR, 17 * HOUR, 10))}]},
    options: {scales: {x: {time: {round: 'day'}}}},
  }),
  chartCase('round week with isoWeekday 1', {
    data: {datasets: [{data: xy(range(T0 + 3 * DAY, 4 * DAY, 10))}]},
    options: {scales: {x: {time: {round: 'week', isoWeekday: 1}}}},
  }),
  chartCase('bounds ticks', {
    data: {datasets: [{data: xy(range(T0 + 5 * HOUR, 2.5 * DAY, 10))}]},
    options: {scales: {x: {bounds: 'ticks'}}},
  }),
  chartCase('bounds ticks with a min', {
    data: {datasets: [{data: xy(range(T0 + 5 * HOUR, 2.5 * DAY, 10))}]},
    options: {scales: {x: {bounds: 'ticks', min: T0 + 30 * HOUR}}},
  }),
  chartCase('ticks source data without data', {
    data: {labels: ['2021-01-04', '2021-01-15'], datasets: []},
    options: {scales: {x: {ticks: {source: 'data'}}}},
  }),
  chartCase('ticks source data', {
    data: {datasets: [{data: xy([T0, T0 + DAY, T0 + 3 * DAY, T0 + 7 * DAY, T0 + 20 * DAY])}]},
    options: {scales: {x: {ticks: {source: 'data'}}}},
  }),
  chartCase('ticks source labels', {
    data: {
      labels: ['2021-01-04', '2021-01-06', '2021-01-15', '2021-02-01'],
      datasets: [{data: [1, 2, 3, 4]}],
    },
    options: {scales: {x: {ticks: {source: 'labels'}}}},
  }),
  chartCase('ticks source labels cut by min and max', {
    data: {
      labels: ['2021-01-04', '2021-01-06', '2021-01-15', '2021-02-01', '2021-02-03'],
      datasets: [{data: [1, 2, 3, 4, 5]}],
    },
    options: {scales: {x: {min: '2021-01-05', max: '2021-02-02', ticks: {source: 'labels'}}}},
  }),
  chartCase('ticks source labels, bounds ticks and reverse', {
    data: {
      labels: ['2021-01-04', '2021-01-06', '2021-01-15', '2021-02-01'],
      datasets: [{data: [1, 2, 3, 4]}],
    },
    options: {scales: {x: {bounds: 'ticks', reverse: true, ticks: {source: 'labels'}}}},
  }),
  chartCase('major ticks on days', {
    data: {datasets: [{data: xy(range(T0 + 10 * DAY, 6 * DAY, 14))}]},
    options: {scales: {x: {time: {unit: 'day'}, ticks: {major: {enabled: true}}}}},
  }),
  chartCase('major ticks on months', {
    data: {datasets: [{data: xy(range(T0, 45 * DAY, 20))}]},
    options: {scales: {x: {ticks: {major: {enabled: true}}}}},
  }),
  chartCase('major ticks on years', {
    data: {datasets: [{data: xy([Date.UTC(2000, 5, 1), Date.UTC(2030, 11, 31)])}]},
    options: {scales: {x: {ticks: {major: {enabled: true}}}}},
  }),
  chartCase('offset', {
    data: {datasets: [{data: xy(range(T0, DAY, 7))}]},
    options: {scales: {x: {offset: true, ticks: {source: 'data'}}}},
  }),
  chartCase('offset with one point', {
    data: {datasets: [{data: xy([T0 + 6 * HOUR])}]},
    options: {scales: {x: {offset: true, ticks: {source: 'data'}}}},
  }),
  chartCase('offset with two labels', {
    data: {labels: ['2021-01-04', '2021-01-09'], datasets: [{data: [1, 2]}]},
    options: {scales: {x: {offset: true, ticks: {source: 'labels'}}}},
  }),
  chartCase('offsetAfterAutoskip', {
    data: {datasets: [{data: xy(range(T0, DAY, 60))}]},
    options: {scales: {x: {offset: true, offsetAfterAutoskip: true, ticks: {source: 'data'}}}},
  }),
  chartCase('reverse', {
    data: {datasets: [{data: days40}]},
    options: {scales: {x: {reverse: true}}},
  }),
  chartCase('min and max as strings', {
    data: {datasets: [{data: days40}]},
    options: {scales: {x: {min: '2021-01-10', max: '2021-02-01T12:00:00'}}},
  }),
  chartCase('min and max as numbers', {
    data: {datasets: [{data: days40}]},
    options: {scales: {x: {min: T0 - 5 * DAY, max: T0 + 20 * DAY}}},
  }),
  chartCase('suggestedMin and suggestedMax', {
    data: {datasets: [{data: xy(range(T0 + 5 * DAY, DAY, 10))}]},
    options: {scales: {x: {suggestedMin: '2021-01-01', suggestedMax: T0 + 12 * DAY}}},
  }),
  chartCase('a parser function', {
    data: {
      datasets: [{data: xy(range(T0 / 1000, 3600, 12))}],
    },
    options: {scales: {x: {time: {parser: seconds}}}},
  }),
  chartCase('a parser format HH:mm', {
    data: {labels: ['09:00', '12:30', '17:45', '23:10'], datasets: [{data: [1, 2, 3, 4]}]},
    options: {scales: {x: {time: {parser: 'HH:mm'}}}},
  }),
  chartCase('ticks stepSize 2 with the unit day', {
    data: {datasets: [{data: xy(range(T0, DAY, 15))}]},
    options: {scales: {x: {time: {unit: 'day'}, ticks: {stepSize: 2}}}},
  }),
  chartCase('time stepSize has no effect', {
    data: {datasets: [{data: xy(range(T0, DAY, 15))}]},
    options: {scales: {x: {time: {unit: 'day', stepSize: 5}}}},
  }),
  chartCase('normalized data', {
    data: {
      datasets: [
        {data: xy(range(T0, 2 * DAY, 10))},
        {data: xy(range(T0 + 30 * DAY, DAY, 5))},
      ],
    },
    options: {normalized: true},
  }),
  chartCase('normalized labels', {
    data: {
      labels: ['2021-01-20', '2021-01-04', '2021-01-04', '2021-01-11'],
      datasets: [{data: [1, 2, 3, 4]}],
    },
    options: {normalized: true, scales: {x: {ticks: {source: 'labels'}}}},
  }),
  chartCase('a hidden dataset', {
    data: {
      datasets: [
        {data: xy(range(T0, DAY, 10))},
        {data: xy(range(T0 + 60 * DAY, DAY, 5)), hidden: true},
      ],
    },
  }),
  chartCase('no data', {data: {datasets: [{data: []}]}}),
  chartCase('no data with the unit month', {
    data: {datasets: []},
    options: {scales: {x: {time: {unit: 'month'}}}},
  }),
  chartCase('no data with a min', {
    data: {datasets: [{data: []}]},
    options: {scales: {x: {min: '2021-06-15T08:00:00'}}},
  }),
  chartCase('a narrow canvas', {data: {datasets: [{data: days40}]}}, {canvas: {width: 160, height: 200}}),
  chartCase('a wide canvas', {data: {datasets: [{data: days40}]}}, {canvas: {width: 1200, height: 300}}),
  chartCase('a vertical time axis on the right', {
    data: {datasets: [{data: xy(range(T0, 6 * HOUR, 20))}]},
    options: {indexAxis: 'y', scales: {y: {position: 'right'}}},
  }),
  chartCase('a time axis on top', {
    data: {datasets: [{data: days40}]},
    options: {scales: {x: {position: 'top'}}},
  }),
  chartCase('a tick callback', {
    data: {datasets: [{data: days40}]},
    options: {scales: {x: {ticks: {callback: tickIndex}}}},
  }),
  chartCase('a tick callback that reads this', {
    data: {datasets: [{data: xy(range(T0, 2 * HOUR, 13))}]},
    options: {scales: {x: {ticks: {callback: hourOrEmpty}}}},
  }),
  chartCase('autoSkip false', {
    data: {datasets: [{data: xy(range(T0, 2 * DAY, 12))}]},
    options: {scales: {x: {ticks: {autoSkip: false}}}},
  }),
  chartCase('autoSkip false with minUnit day on hour labels', {
    data: {labels: range(T0 + HOUR, 7 * HOUR, 5), datasets: [{data: [1, 2, 3, 4, 5]}]},
    options: {scales: {x: {time: {minUnit: 'day'}, ticks: {autoSkip: false, source: 'labels'}}}},
  }),
  chartCase(
    'label rotation without autoSkip',
    {
      data: {datasets: [{data: xy(range(T0, DAY, 20))}]},
      options: {scales: {x: {time: {unit: 'day'}, ticks: {autoSkip: false}}}},
    },
    {canvas: {width: 300, height: 300}},
  ),
  chartCase('maxTicksLimit 4', {
    data: {datasets: [{data: days40}]},
    options: {scales: {x: {ticks: {maxTicksLimit: 4}}}},
  }),
  chartCase('null and invalid x values', {
    data: {
      datasets: [
        {
          data: [
            {x: '2021-01-04', y: 1},
            {x: null, y: 2},
            {x: 'garbage', y: 3},
            {x: '2021-01-09', y: 4},
          ],
        },
      ],
    },
  }),
  chartCase('a label that does not parse', {
    data: {labels: ['2021-01-04', 'garbage', '2021-01-20'], datasets: [{data: [1, 2, 3]}]},
  }),
  // The tick of the label that does not parse has the value null
  // (differences.md row adapt-time-null-timestamp): the callback gets null.
  chartCase('ticks source labels and a label that does not parse', {
    data: {labels: ['2021-01-04', 'garbage', '2021-01-20'], datasets: [{data: [1, 2, 3]}]},
    options: {scales: {x: {ticks: {source: 'labels', callback: valueString}}}},
  }),
  // afterAutoSkip gives +null, 0, to initOffsets for the null tick.
  chartCase('offsetAfterAutoskip and a label that does not parse', {
    data: {labels: ['2021-01-04', 'garbage', '2021-01-20'], datasets: [{data: [1, 2, 3]}]},
    options: {scales: {x: {offset: true, offsetAfterAutoskip: true, ticks: {source: 'labels'}}}},
  }),
  chartCase('tooltipFormat and a display format', {
    data: {datasets: [{data: days40}]},
    options: {scales: {x: {time: {tooltipFormat: 'HH:mm', displayFormats: {day: 'MMM'}}}}},
  }),
  chartCase('grace, beginAtZero and adapters.date have no effect', {
    data: {datasets: [{data: days40}]},
    options: {
      scales: {x: {grace: '10%', beginAtZero: true, adapters: {date: {zone: 'Europe/Kyiv'}}}},
    },
  }),
  chartCase('count, precision, includeBounds and suggested bounds inside the data', {
    data: {datasets: [{data: days40}]},
    options: {
      scales: {
        x: {
          suggestedMin: T0 + 5 * DAY,
          suggestedMax: '2021-01-20',
          ticks: {count: 3, precision: 0, includeBounds: false},
        },
      },
    },
  }),
  chartCase('round week without isoWeekday', {
    data: {datasets: [{data: xy(range(T0 + 3 * DAY, 4 * DAY, 10))}]},
    options: {scales: {x: {time: {round: 'week'}}}},
  }),
  chartCase('round week with isoWeekday true', {
    data: {datasets: [{data: xy(range(T0 + 3 * DAY, 4 * DAY, 10))}]},
    options: {scales: {x: {time: {round: 'week', isoWeekday: true}}}},
  }),
  chartCase('the unit week with the isoWeekday string 3', {
    data: {datasets: [{data: xy(range(T0 + 2 * DAY, 5 * DAY, 12))}]},
    options: {scales: {x: {time: {unit: 'week', isoWeekday: '3'}}}},
  }),
  chartCase('ticks stepSize as a string', {
    data: {datasets: [{data: xy(range(T0, DAY, 15))}]},
    options: {scales: {x: {time: {unit: 'day'}, ticks: {stepSize: '3'}}}},
  }),
  chartCase('NaN and infinite x values', {
    data: {
      datasets: [
        {
          data: [
            {x: T0, y: 1},
            {x: NaN, y: 2},
            {x: Infinity, y: 3},
            {x: -Infinity, y: 4},
            {x: T0 + 6 * DAY, y: 5},
          ],
        },
      ],
    },
  }),
  chartCase('a vertical time axis on the left', {
    data: {datasets: [{data: xy(range(T0, 6 * HOUR, 20))}]},
    options: {indexAxis: 'y'},
  }),
  chartCase('a reversed vertical time axis with offset', {
    data: {datasets: [{data: xy(range(T0, 6 * HOUR, 20))}]},
    options: {indexAxis: 'y', scales: {y: {reverse: true, offset: true}}},
  }),
  chartCase('ticks source labels, reverse, offset and offsetAfterAutoskip', {
    data: {
      labels: ['2021-01-04', '2021-01-06', '2021-01-15', '2021-02-01'],
      datasets: [{data: [1, 2, 3, 4]}],
    },
    options: {
      scales: {
        x: {reverse: true, offset: true, offsetAfterAutoskip: true, ticks: {source: 'labels'}},
      },
    },
  }),
  chartCase('major ticks and reverse', {
    data: {datasets: [{data: xy(range(T0, 45 * DAY, 20))}]},
    options: {scales: {x: {reverse: true, ticks: {major: {enabled: true}}}}},
  }),
  chartCase('major ticks with an empty major display format', {
    data: {datasets: [{data: xy(range(T0 + 10 * DAY, 6 * DAY, 14))}]},
    options: {
      scales: {
        x: {
          time: {unit: 'day', displayFormats: {month: ''}},
          ticks: {major: {enabled: true}},
        },
      },
    },
  }),
  chartCase('bounds ticks with ticks source data', {
    data: {datasets: [{data: xy([T0 + 5 * HOUR, T0 + 2 * DAY, T0 + 9 * DAY + 7 * HOUR])}]},
    options: {scales: {x: {bounds: 'ticks', ticks: {source: 'data'}}}},
  }),
  chartCase('a range of one millisecond', {
    data: {datasets: [{data: xy([T0 + 7])}]},
  }),
  chartCase('normalized without datasets', {
    data: {labels: ['2021-01-04', '2021-01-11'], datasets: []},
    options: {normalized: true},
  }),
  chartCase('offset with irregular data: the start and end offsets differ', {
    data: {datasets: [{data: xy([T0, T0 + DAY, T0 + 10 * DAY, T0 + 12 * DAY])}]},
    options: {scales: {x: {offset: true, ticks: {source: 'data'}}}},
  }),
  chartCase('the unit days, an alias that is not a unit', {
    data: {datasets: [{data: xy(range(T0, DAY, 6))}]},
    options: {scales: {x: {time: {unit: 'days'}}}},
  }),
  chartCase('minUnit days with ticks source labels and autoSkip false', {
    data: {labels: ['2021-01-04', '2021-01-09'], datasets: [{data: [1, 2]}]},
    options: {scales: {x: {time: {minUnit: 'days'}, ticks: {source: 'labels', autoSkip: false}}}},
  }),
];

// The case 'an adapter add that gives NaN': `add` gives NaN, so the loop of
// _generate ends after one step (scale.time.js:479-485).
{
  const add = C._adapters._date.prototype.add;
  C._adapters._date.override({add: () => NaN});
  try {
    cases.push(
      chartCase('an adapter add that gives NaN', {
        data: {datasets: [{data: xy(range(T0 + HOUR, 7 * HOUR, 5))}]},
      }),
    );
  } finally {
    C._adapters._date.override({add});
  }
}

writeReference(OUT, 'scaleTime', cases, {title: 'time scale'});
appendAdapterInfo(OUT, 'scaleTime');
